import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:io';
import 'dart:math';
import 'package:path/path.dart' as path;
import 'package:mime/mime.dart';
import 'dart:async';
import 'package:path_provider/path_provider.dart';

class AuthService {
  // API 기본 URL
  static String get baseUrl => dotenv.env['API_BASE_URL'] ?? '';
  static const storage = FlutterSecureStorage();

  // 토큰 관련 키
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String firstLoginKey = 'first_login';
  static const String profileImagePathKey = 'profile_image_path';
  
  // 토큰 재발급 중 여부를 체크하는 플래그
  static bool _isRefreshing = false;
  // 토큰 재발급 중 대기하는 요청을 위한 Completer
  static Completer<String>? _refreshTokenCompleter;

  // 회원가입 API
  static Future<Map<String, dynamic>> signup({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String rrn,
    required String bankName,
    required String bankAccount,
    required String bankCode,
    String? profileImageUrl,
    required String role,
  }) async {
    if (baseUrl.isEmpty) {
      throw Exception('API_BASE_URL가 설정되지 않았습니다. .env 파일을 확인하세요.');
    }

    final url = Uri.parse('$baseUrl/api-user/user/public/signup');

    // 요청 바디 구성
    final Map<String, dynamic> body = {
      'email': email,
      'password': password,
      'name': name,
      'phone': phone,
      'rrn': rrn,
      'bankName': bankName,
      'bankAccount': bankAccount,
      'bankCode': bankCode,
      'role': role,
    };

    // 프로필 이미지 URL이 있는 경우에만 추가
    if (profileImageUrl != null && profileImageUrl.isNotEmpty) {
      body['profileImageUrl'] = profileImageUrl;
    }

    print('API 요청 URL: $url');
    print('API 요청 바디: ${jsonEncode(body)}');

    try {
      // POST 요청 보내기
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      // 응답 로깅
      print('API 응답 상태 코드: ${response.statusCode}');
      print('API 응답 바디: ${response.body}');

      // 응답 확인
      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        // 에러 응답을 파싱하려고 시도
        try {
          final errorBody = jsonDecode(response.body);
          throw Exception(
            '회원가입 실패: ${response.statusCode}, ${errorBody['message'] ?? errorBody.toString()}',
          );
        } catch (e) {
          throw Exception('회원가입 실패: ${response.statusCode}, ${response.body}');
        }
      }
    } catch (e) {
      print('API 호출 예외: $e');
      throw Exception('회원가입 API 요청 중 오류: $e');
    }
  }

  // 로그인 API
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    if (baseUrl.isEmpty) {
      throw Exception('API_BASE_URL가 설정되지 않았습니다. .env 파일을 확인하세요.');
    }

    final url = Uri.parse('$baseUrl/api-user/auth/public/login');

    // 요청 바디 구성
    final Map<String, dynamic> body = {'email': email, 'password': password};

    print('로그인 API 요청 URL: $url');
    print('로그인 API 요청 바디: ${jsonEncode(body)}');

    try {
      // POST 요청 보내기
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      // 응답 로깅
      print('로그인 API 응답 상태 코드: ${response.statusCode}');
      print('로그인 API 응답 헤더: ${response.headers}');
      print('로그인 API 응답 바디: ${response.body}');

      // 응답 헤더 상세 로깅
      print('=== 응답 헤더 상세 정보 ===');
      print('헤더 키 목록: ${response.headers.keys.join(", ")}');
      
      // 쿠키 검사
      if (response.headers.containsKey('set-cookie')) {
        print('쿠키 헤더: ${response.headers['set-cookie']}');
        // 쿠키에서 리프레시 토큰 검색
        final cookies = response.headers['set-cookie']!.split(';');
        for (final cookie in cookies) {
          if (cookie.trim().toLowerCase().startsWith('refreshtoken=') || 
              cookie.trim().toLowerCase().startsWith('refresh_token=') ||
              cookie.trim().toLowerCase().startsWith('refresh-token=')) {
            print('쿠키에서 리프레시 토큰 발견: $cookie');
            
            // 토큰 값 추출
            final tokenValue = cookie.split('=')[1].trim();
            if (tokenValue.isNotEmpty) {
              await storage.write(key: 'refresh_token', value: tokenValue);
              print('쿠키에서 리프레시 토큰 저장됨: ${tokenValue.substring(0, tokenValue.length > 10 ? 10 : tokenValue.length)}...');
            }
          }
        }
      }

      // 응답 확인
      if (response.statusCode == 200) {
        // 응답 본문 디코딩
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        print('로그인 응답 데이터: $responseData');

        // 액세스 토큰 찾기 (다양한 필드 이름 시도)
        String? accessToken;
        if (responseData.containsKey('accessToken')) {
          accessToken = responseData['accessToken'];
        } else if (responseData.containsKey('access_token')) {
          accessToken = responseData['access_token'];
        } else if (responseData.containsKey('token')) {
          accessToken = responseData['token'];
        } else if (responseData.containsKey('data') &&
            responseData['data'] is Map) {
          final dataMap = responseData['data'] as Map<String, dynamic>;
          if (dataMap.containsKey('accessToken')) {
            accessToken = dataMap['accessToken'];
          } else if (dataMap.containsKey('access_token')) {
            accessToken = dataMap['access_token'];
          } else if (dataMap.containsKey('token')) {
            accessToken = dataMap['token'];
          }
        }

        if (accessToken != null && accessToken.isNotEmpty) {
          // 액세스 토큰 저장
          await storage.write(key: 'access_token', value: accessToken);
          print(
            '액세스 토큰이 저장되었습니다: ${accessToken.substring(0, accessToken.length > 10 ? 10 : accessToken.length)}...',
          );
        } else {
          print('경고: 액세스 토큰이 응답에 없습니다');
        }

        print('로그인 성공: 첫 로그인 상태 확인');
        final isFirst = await storage.read(key: 'first_login');
        if (isFirst == null) {
          print('첫 로그인 상태를 true로 설정합니다');
          await storage.write(key: 'first_login', value: 'true');
        } else {
          print('현재 first_login 값: $isFirst');
          // 로그인 성공 시에는 first_login을 true로 설정 (테스트용)
          await storage.write(key: 'first_login', value: 'true');
          print('first_login 값을 true로 재설정했습니다');
        }

        return responseData;
      } else if (response.statusCode == 401) {
        // 로그인 실패 - 인증 오류
        throw Exception('아이디 또는 비밀번호가 일치하지 않습니다.');
      } else if (response.statusCode == 404) {
        // 계정 없음
        throw Exception('등록되지 않은 계정입니다.');
      } else {
        // 기타 오류
        try {
          final errorBody = jsonDecode(response.body);
          final errorMessage =
              errorBody['message'] ?? errorBody['error'] ?? '로그인에 실패했습니다.';
          throw Exception('로그인 실패: $errorMessage');
        } catch (e) {
          throw Exception('로그인 실패: ${response.statusCode}, ${response.body}');
        }
      }
    } catch (e) {
      print('로그인 API 호출 예외: $e');

      // 네트워크 오류인지 확인
      if (e.toString().toLowerCase().contains('connection') ||
          e.toString().toLowerCase().contains('network') ||
          e.toString().toLowerCase().contains('socket')) {
        throw Exception('네트워크 연결을 확인해주세요.');
      }

      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // 파일 업로드를 위한 Pre-signed URL 발급 API
  static Future<List<Map<String, String>>> getUploadUrls({
    required String mimeType,
    required String type,
    required String imageUploadTarget,
    int num = 1,
  }) async {
    if (baseUrl.isEmpty) {
      throw Exception('API_BASE_URL가 설정되지 않았습니다. .env 파일을 확인하세요.');
    }

    // 액세스 토큰 가져오기(인증 필요한 API)
    String? accessToken = await getAccessToken();

    // 액세스 토큰이 없으면 오류 발생 (인증 필요)
    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('인증이 필요합니다. 로그인을 다시 시도해주세요.');
    }

    // URL 구성 with query parameters
    final uri = Uri.parse('$baseUrl/api-user/file/upload').replace(
      queryParameters: {
        'mimeType': mimeType,
        'type': type,
        'imageUploadTarget': imageUploadTarget,
        'num': num.toString(),
      },
    );

    print('Pre-signed URL 요청: $uri');

    try {
      // GET 요청으로 Pre-signed URL 발급
      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      print('Pre-signed URL 응답 상태 코드: ${response.statusCode}');
      print('Pre-signed URL 응답 본문: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data
            .map(
              (item) => {
                'path': item['path'] as String,
                'url': item['url'] as String,
              },
            )
            .toList();
      } else {
        throw Exception(
          'Pre-signed URL 발급 실패: ${response.statusCode}, ${response.body}',
        );
      }
    } catch (e) {
      print('Pre-signed URL 발급 오류: $e');
      throw Exception('업로드 URL 발급 중 오류가 발생했습니다: $e');
    }
  }

  // 파일 업로드 처리
  static Future<String> uploadFile(File file, String uploadUrl) async {
    try {
      // MIME 타입 추정
      final mimeType = lookupMimeType(file.path) ?? 'application/octet-stream';

      // 파일 바이트 읽기
      final fileBytes = await file.readAsBytes();

      print('파일 업로드 URL: $uploadUrl');
      print('파일 크기: ${fileBytes.length} bytes');
      print('MIME 타입: $mimeType');

      // PUT 요청으로 파일 업로드
      final response = await http.put(
        Uri.parse(uploadUrl),
        headers: {
          'Content-Type': mimeType,
          'Content-Length': fileBytes.length.toString(),
        },
        body: fileBytes,
      );

      print('파일 업로드 응답 상태 코드: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return uploadUrl;
      } else {
        throw Exception(
          '파일 업로드 실패: ${response.statusCode}, ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      print('파일 업로드 중 오류: $e');
      throw Exception('파일 업로드 중 오류가 발생했습니다: $e');
    }
  }

  // 프로필 이미지 업로드(URL 발급 및 업로드 처리)
  static Future<String> uploadProfileImage(File imageFile) async {
    try {
      // 파일 확장자 확인
      final extension = path.extension(imageFile.path).toLowerCase();
      String mimeType;

      // MIME 타입 결정
      switch (extension) {
        case '.jpg':
        case '.jpeg':
          mimeType = 'image/jpeg';
          break;
        case '.png':
          mimeType = 'image/png';
          break;
        case '.gif':
          mimeType = 'image/gif';
          break;
        default:
          mimeType = lookupMimeType(imageFile.path) ?? 'image/jpeg';
      }

      // Pre-signed URL 발급
      final urlData = await getUploadUrls(
        mimeType: mimeType,
        type: 'image',
        imageUploadTarget: 'profile',
      );

      if (urlData.isEmpty) {
        throw Exception('업로드 URL을 발급받지 못했습니다');
      }

      // 첫번째 URL로 업로드
      final uploadUrl = urlData[0]['url'] ?? '';
      final imagePath = urlData[0]['path'] ?? '';

      if (uploadUrl.isEmpty || imagePath.isEmpty) {
        throw Exception('유효하지 않은 업로드 URL 또는 경로입니다');
      }

      // 파일 업로드
      await uploadFile(imageFile, uploadUrl);

      // 이미지 경로 반환 (DB에 저장할 값)
      return imagePath;
    } catch (e) {
      print('프로필 이미지 업로드 오류: $e');
      throw Exception('프로필 이미지 업로드 중 오류가 발생했습니다: $e');
    }
  }

  // 토큰 가져오기
  static Future<String?> getAccessToken() async {
    return await storage.read(key: 'access_token');
  }

  static Future<String?> getRefreshToken() async {
    return await storage.read(key: 'refresh_token');
  }

  // 로그아웃 (토큰 삭제)
  static Future<Map<String, dynamic>> logout() async {
    try {
      // 액세스 토큰과 리프레시 토큰 가져오기
      String? accessToken = await getAccessToken();
      String? refreshToken = await getRefreshToken();
      
      // 토큰 없으면 로컬만 삭제
      if (accessToken == null || accessToken.isEmpty) {
        await clearAllAuthData();
        print('로그아웃: 토큰 없음 - 로컬 데이터만 삭제됨');
        return {'success': true, 'message': '로그아웃되었습니다.'};
      }
      
      final url = Uri.parse('$baseUrl/api-user/auth/logout');
      
      // 요청 헤더 구성
      final Map<String, String> headers = {
        'Authorization': accessToken.startsWith('Bearer ') ? accessToken : 'Bearer $accessToken',
        'Content-Type': 'application/json',
      };
      
      // 리프레시 토큰이 있으면 쿠키 형태로 헤더에 추가
      if (refreshToken != null && refreshToken.isNotEmpty) {
        headers['Cookie'] = 'refreshToken=$refreshToken';
      }
      
      try {
        // POST 요청 보내기 (빈 바디)
        final response = await http.post(url, headers: headers);
        
        // 로컬 데이터 삭제 (응답 상태와 관계없이)
        await clearAllAuthData();
        
        // 204 No Content가 성공 응답
        if (response.statusCode == 204 || (response.statusCode >= 200 && response.statusCode < 300)) {
          print('로그아웃 성공: 서버에서 정상 응답');
          return {'success': true, 'message': '로그아웃되었습니다.'};
        } else {
          print('로그아웃: 서버 오류(${response.statusCode}) - 로컬 데이터만 삭제됨');
          return {'success': true, 'message': '로컬에서 로그아웃되었습니다.'};
        }
      } catch (e) {
        print('로그아웃 API 호출 실패: $e');
        await clearAllAuthData();
        return {'success': true, 'message': '로컬에서 로그아웃되었습니다.'};
      }
    } catch (e) {
      print('로그아웃 처리 예외: $e');
      await clearAllAuthData();
      return {'success': true, 'message': '로컬에서 로그아웃되었습니다.'};
    }
  }

  // 첫 로그인 상태 확인 및 관리
  static Future<bool> isFirstLogin() async {
    return await storage.read(key: 'first_login') != 'false';
  }

  static Future<void> setFirstLoginCompleted() async {
    await storage.write(key: 'first_login', value: 'false');
  }

  // 사용자 프로필 이미지 경로 저장
  static Future<void> saveProfileImagePath(String path) async {
    await storage.write(key: 'profile_image_path', value: path);
  }

  // 사용자 프로필 이미지 경로 가져오기
  static Future<String?> getProfileImagePath() async {
    return await storage.read(key: 'profile_image_path');
  }

  // 프로필 이미지 전체 URL 구성 - S3 직접 접근
  static String getFullProfileImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return '';
    }

    // 이미 http로 시작하는 경우 URL 그대로 반환
    if (imagePath.startsWith('http')) {
      return imagePath;
    }

    // S3 URL 직접 구성
    return 'https://littlebank-dev.s3.ap-northeast-2.amazonaws.com/$imagePath';
  }

  // 기존 파일에 대한 pre-signed URL 가져오기
  static Future<List<Map<String, String>>> getUploadUrlsForExisting({
    required String mimeType,
    required String path,
  }) async {
    try {
      if (baseUrl.isEmpty) {
        throw Exception('API_BASE_URL가 설정되지 않았습니다. .env 파일을 확인하세요.');
      }

      // 액세스 토큰 가져오기(인증 필요한 API)
      String? accessToken = await getAccessToken();

      // 액세스 토큰이 없으면 오류 발생 (인증 필요)
      if (accessToken == null || accessToken.isEmpty) {
        throw Exception('인증이 필요합니다. 로그인을 다시 시도해주세요.');
      }

      // URL 구성 with query parameters
      final uri = Uri.parse(
        '$baseUrl/api-user/file/get-url',
      ).replace(queryParameters: {'mimeType': mimeType, 'path': path});

      print('기존 파일 URL 요청: $uri');

      try {
        // GET 요청으로 Pre-signed URL 발급
        final response = await http.get(
          uri,
          headers: {'Authorization': 'Bearer $accessToken'},
        );

        print('URL 응답 상태 코드: ${response.statusCode}');

        if (response.statusCode == 200) {
          final body = utf8.decode(response.bodyBytes);
          print('URL 응답 본문: $body');
          final data = jsonDecode(body);

          if (data is Map && data.containsKey('url')) {
            return [
              {'path': path, 'url': data['url']},
            ];
          } else if (data is List) {
            return data
                .map(
                  (item) => {
                    'path': item['path'] as String,
                    'url': item['url'] as String,
                  },
                )
                .toList();
          }
        }

        // 기본적으로 아래 업로드 API 호출
        return await getUploadUrls(
          mimeType: mimeType,
          type: 'image',
          imageUploadTarget: 'profile',
        );
      } catch (e) {
        print('URL 발급 호출 예외: $e');
        // 실패 시 아래 메서드로 호출
        return await getUploadUrls(
          mimeType: mimeType,
          type: 'image',
          imageUploadTarget: 'profile',
        );
      }
    } catch (e) {
      print('URL 발급 호출 예외: $e');
      return [];
    }
  }

  // 인증 토큰을 포함한 이미지 URL 헤더 반환 (API 서버에만 사용)
  static Future<Map<String, String>> getImageHeaders() async {
    String? token = await getAccessToken();
    if (token == null || token.isEmpty) {
      return {};
    }

    // Accept 헤더 추가 및 명시적인 Content-Type 지정
    return {
      'Authorization': 'Bearer $token',
      'Accept': 'image/*, */*',
      'Cache-Control': 'no-cache',
    };
  }

  // S3 URL인지 확인하는 헬퍼 함수
  static bool isS3Url(String url) {
    return url.contains('s3.ap-northeast-2.amazonaws.com') ||
        url.contains('amazonaws.com');
  }

  // 사용자 정보 업데이트 (프로필 이미지 등)
  static Future<Map<String, dynamic>> updateUserProfile(
    String imagePath,
  ) async {
    try {
      if (baseUrl.isEmpty) {
        throw Exception('API_BASE_URL가 설정되지 않았습니다. .env 파일을 확인하세요.');
      }

      // 액세스 토큰 가져오기(인증 필요한 API)
      String? accessToken = await getAccessToken();

      if (accessToken == null || accessToken.isEmpty) {
        throw Exception('인증이 필요합니다. 로그인을 다시 시도해주세요.');
      }

      // 이미지 경로가 전체 URL이 아닌 경우 전체 URL로 변환
      final String fullImageUrl;
      if (imagePath.startsWith('http')) {
        fullImageUrl = imagePath;
      } else {
        fullImageUrl =
            'https://littlebank-dev.s3.ap-northeast-2.amazonaws.com/$imagePath';
      }

      final url = Uri.parse('$baseUrl/api-user/user/profile-image');

      // 요청 바디 구성 - 전체 URL로 사용
      final Map<String, dynamic> body = {'profileImagePath': fullImageUrl};

      print('프로필 업데이트 API 요청 URL: $url');
      print('프로필 업데이트 API 요청 바디: ${jsonEncode(body)}');

      // 이미지 경로는 어떤 경우에도 먼저 로컬에 저장(서버 오류가 발생해도 유지)
      // 전체 URL 형식으로 저장
      await saveProfileImagePath(fullImageUrl);

      print('프로필 이미지 전체 URL: $fullImageUrl');

      // PATCH 요청 보내기
      final response = await http.patch(
        url,
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Accept': 'application/json; charset=utf-8',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(body),
      );

      // 응답 로깅
      print('프로필 업데이트 API 응답 상태 코드: ${response.statusCode}');
      print('프로필 업데이트 API 응답 바디: ${response.body}');

      // 응답 확인 (500 오류가 발생해도 처리 가능하도록)
      if (response.statusCode == 200) {
        // UTF-8로 디코딩하여 처리
        final decodedBody = utf8.decode(response.bodyBytes);
        return jsonDecode(decodedBody);
      } else if (response.statusCode == 500 && response.body.contains("C004")) {
        // C004 서버 오류 발생 시 경고만 출력하고 실패로 처리하지 않음
        print('경고: 서버 오류(C004)가 발생했으나 이미지가 성공적으로 업로드되었습니다.');
        return {"success": true, "message": "이미지 업로드 완료"};
      } else {
        throw Exception(
          '프로필 업데이트 실패: ${response.statusCode}, ${utf8.decode(response.bodyBytes)}',
        );
      }
    } catch (e) {
      print('프로필 업데이트 API 호출 예외: $e');
      throw Exception('프로필 업데이트 중 오류가 발생했습니다: $e');
    }
  }

  // 사용자 정보 조회 API
  static Future<Map<String, dynamic>> getUserInfo() async {
    try {
      if (baseUrl.isEmpty) {
        throw Exception('API_BASE_URL가 설정되지 않았습니다. .env 파일을 확인하세요.');
      }

      // 액세스 토큰 가져오기(인증 필요한 API)
      String? accessToken = await getAccessToken();

      if (accessToken == null || accessToken.isEmpty) {
        throw Exception('인증이 필요합니다. 로그인을 다시 시도해주세요.');
      }

      final url = Uri.parse('$baseUrl/api-user/user/info');

      print('유저 정보 조회 API 요청 URL: $url');

      // GET 요청 보내기
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Accept': 'application/json; charset=utf-8',
          'Content-Type': 'application/json; charset=utf-8',
        },
      );

      // 응답 로깅
      print('유저 정보 조회 API 응답 상태 코드: ${response.statusCode}');
      print('유저 정보 조회 API 응답 바디: ${response.body}');

      // 토큰 만료 확인 (C007 오류)
      if (response.statusCode == 401) {
        final responseBody = utf8.decode(response.bodyBytes);
        final errorData = jsonDecode(responseBody);
        
        if (errorData is Map && errorData.containsKey('code') && errorData['code'] == 'C007') {
          print('액세스 토큰 만료 감지. 토큰 재발급 시도 중...');
          
          // 리프레시 토큰으로 액세스 토큰 재발급 시도
          final newAccessToken = await reissueAccessToken();
          
          if (newAccessToken != null) {
            print('토큰 재발급 성공. 요청 재시도 중...');
            
            // 새 액세스 토큰으로 요청 재시도
            final retryResponse = await http.get(
              url,
              headers: {
                'Authorization': 'Bearer $newAccessToken',
                'Accept': 'application/json; charset=utf-8',
                'Content-Type': 'application/json; charset=utf-8',
              },
            );
            
            print('재시도 요청 응답 상태 코드: ${retryResponse.statusCode}');
            
            if (retryResponse.statusCode == 200) {
              // UTF-8로 디코딩하여 처리
              final decodedBody = utf8.decode(retryResponse.bodyBytes);
              final userData = jsonDecode(decodedBody);
              
              // 프로필 이미지 경로 저장 로직 (기존과 동일)
              if (userData.containsKey('profileImagePath') && userData['profileImagePath'] != null && userData['profileImagePath'].toString().isNotEmpty) {
                print('API에서 프로필 이미지 경로 발견: ${userData["profileImagePath"]}');
                await storage.write(key: 'profile_image_path', value: userData['profileImagePath']);
                print('프로필 이미지 경로를 로컬에 저장함');
              }
              
              print('사용자 정보: role=${userData['role']}, authority=${userData['authority']}');
              
              return userData;
            } else {
              // 재시도 실패
              throw Exception('정보 조회 재시도 실패: ${retryResponse.statusCode}, ${utf8.decode(retryResponse.bodyBytes)}');
            }
          } else {
            print('토큰 재발급 실패. 로그인 필요.');
            // 모든 인증 데이터 삭제
            await clearAllAuthData();
            throw Exception('세션이 만료되었습니다. 다시 로그인해주세요.');
          }
        }
      }

      if (response.statusCode == 200) {
        // UTF-8로 디코딩하여 처리
        final decodedBody = utf8.decode(response.bodyBytes);
        final userData = jsonDecode(decodedBody);

        // 프로필 이미지 경로가 있으면 로컬 저장소에 저장
        if (userData.containsKey('profileImagePath') && userData['profileImagePath'] != null && userData['profileImagePath'].toString().isNotEmpty) {
          print('API에서 프로필 이미지 경로 발견: ${userData["profileImagePath"]}');
          await storage.write(key: 'profile_image_path', value: userData['profileImagePath']);
          print('프로필 이미지 경로를 로컬에 저장함');
        }

        // 사용자 역할 로깅 (디버깅용)
        print(
          '사용자 정보: role=${userData['role']}, authority=${userData['authority']}',
        );

        return userData;
      } else {
        throw Exception(
          '정보 조회 실패: ${response.statusCode}, ${utf8.decode(response.bodyBytes)}',
        );
      }
    } catch (e) {
      print('정보 조회 API 호출 예외: $e');
      throw Exception('정보 조회 중 오류가 발생했습니다: $e');
    }
  }

  // 사용자 정보 수정 API
  static Future<Map<String, dynamic>> updateUserInfo({
    String? email,
    String? name,
    String? bankName,
    String? bankAccount,
    String? bankCode,
  }) async {
    try {
      if (baseUrl.isEmpty) {
        throw Exception('API_BASE_URL가 설정되지 않았습니다. .env 파일을 확인하세요.');
      }

      // 액세스 토큰 가져오기(인증 필요한 API)
      String? accessToken = await getAccessToken();

      if (accessToken == null || accessToken.isEmpty) {
        throw Exception('인증이 필요합니다. 로그인을 다시 시도해주세요.');
      }

      final url = Uri.parse('$baseUrl/api-user/user/info');

      // 요청 바디 구성 (null이 아닌 값만 포함)
      final Map<String, dynamic> body = {};
      if (email != null) body['email'] = email;
      if (name != null) body['name'] = name;
      if (bankName != null) body['bankName'] = bankName;
      if (bankAccount != null) body['bankAccount'] = bankAccount;
      if (bankCode != null) body['bankCode'] = bankCode;

      print('사용자 정보 수정 API 요청 URL: $url');
      print('사용자 정보 수정 API 요청 바디: ${jsonEncode(body)}');

      // PUT 요청 보내기
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Accept': 'application/json; charset=utf-8',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(body),
      );

      // 응답 로깅
      print('사용자 정보 수정 API 응답 상태 코드: ${response.statusCode}');
      print('사용자 정보 수정 API 응답 바디: ${response.body}');

      if (response.statusCode == 200) {
        // UTF-8로 디코딩하여 처리
        final decodedBody = utf8.decode(response.bodyBytes);
        return jsonDecode(decodedBody);
      } else {
        throw Exception(
          '사용자 정보 수정 실패: ${response.statusCode}, ${utf8.decode(response.bodyBytes)}',
        );
      }
    } catch (e) {
      print('사용자 정보 수정 API 호출 예외: $e');
      throw Exception('사용자 정보 수정 중 오류가 발생했습니다: $e');
    }
  }

  // 모든 인증 정보 삭제
  static Future<void> clearAllAuthData() async {
    const storage = FlutterSecureStorage();
    await storage.delete(key: 'access_token');
    await storage.delete(key: 'refresh_token');
    await storage.delete(key: 'social_type');
    await storage.delete(key: 'naver_account_id');
    await storage.delete(key: 'email');
    await storage.delete(key: 'name');
    await storage.delete(key: 'profile_image_path');
    await storage.delete(key: 'first_login');
    print('모든 인증 정보가 삭제되었습니다');
  }

  // 소셜 로그인 타입 가져오기 (네이버인지 카카오인지)
  static Future<String?> getSocialType() async {
    return await storage.read(key: 'social_type');
  }
  
  // 소셜 로그인 타입 저장
  static Future<void> setSocialType(String type) async {
    await storage.write(key: 'social_type', value: type);
  }
  
  // 네이버 계정 ID 가져오기
  static Future<String?> getNaverAccountId() async {
    return await storage.read(key: 'naver_account_id');
  }
  
  // 네이버 계정 ID 저장
  static Future<void> setNaverAccountId(String id) async {
    await storage.write(key: 'naver_account_id', value: id);
  }
  
  // 이메일 가져오기
  static Future<String?> getEmail() async {
    return await storage.read(key: 'email');
  }
  
  // 이메일 저장
  static Future<void> setEmail(String email) async {
    await storage.write(key: 'email', value: email);
  }
  
  // 이름 가져오기
  static Future<String?> getName() async {
    return await storage.read(key: 'name');
  }
  
  // 이름 저장
  static Future<void> setName(String name) async {
    await storage.write(key: 'name', value: name);
  }

  // 회원탈퇴 API 호출
  static Future<bool> deleteAccount() async {
    try {
      final url = Uri.parse('$baseUrl/api-user/user');
      final token = await storage.read(key: 'token');
      
      final response = await http.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      print('회원탈퇴 응답: ${response.statusCode}, ${response.body}');
      
      if (response.statusCode == 200) {
        // 토큰 삭제
        await storage.delete(key: 'token');
        return true;
      } else {
        final errorBody = json.decode(response.body);
        final errorMessage = errorBody['message'] ?? '탈퇴 처리 중 오류가 발생했습니다.';
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('회원탈퇴 오류: $e');
      throw Exception('회원탈퇴 처리 중 오류가 발생했습니다.');
    }
  }

  // 리프레시 토큰 확인용 테스트 함수
  static Future<String> testRefreshToken() async {
    // 저장된 리프레시 토큰 가져오기
    String? refreshToken = await getRefreshToken();
    
    // 모든 저장된 키 확인
    final allValues = await storage.readAll();
    
    String result = '리프레시 토큰 확인 결과:\n';
    result += '- 리프레시 토큰: ${refreshToken ?? "없음"}\n';
    result += '- 저장된 모든 키와 값:\n';
    
    allValues.forEach((key, value) {
      // 토큰 값은 일부만 표시
      if (key == 'access_token' || key == 'refresh_token') {
        final truncatedValue = value.isNotEmpty 
            ? (value.length > 10 ? '${value.substring(0, 10)}...' : value) 
            : '(빈 문자열)';
        result += '  - $key: $truncatedValue\n';
      } else {
        result += '  - $key: $value\n';
      }
    });
    
    print(result);
    return result;
  }

  // 액세스 토큰 재발급 메서드
  static Future<String?> reissueAccessToken() async {
    try {
      if (baseUrl.isEmpty) {
        throw Exception('API_BASE_URL가 설정되지 않았습니다. .env 파일을 확인하세요.');
      }

      // 리프레시 토큰 가져오기
      String? refreshToken = await getRefreshToken();
      
      // 리프레시 토큰이 없으면 null 반환
      if (refreshToken == null || refreshToken.isEmpty) {
        print('리프레시 토큰이 없어 토큰 재발급을 진행할 수 없습니다.');
        return null;
      }
      
      final url = Uri.parse('$baseUrl/api-user/auth/public/reissue');
      
      print('토큰 재발급 API 요청 URL: $url');
      print('토큰 재발급 요청 리프레시 토큰: ${refreshToken.substring(0, refreshToken.length > 10 ? 10 : refreshToken.length)}...');
      
      // 요청 바디 구성
      final Map<String, String> body = {'refreshToken': refreshToken};
      
      // POST 요청 보내기
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      
      // 응답 로깅
      print('토큰 재발급 API 응답 상태 코드: ${response.statusCode}');
      print('토큰 재발급 API 응답 헤더: ${response.headers}');
      print('토큰 재발급 API 응답 바디 길이: ${response.body.length}');
      if (response.body.length < 100) {
        print('토큰 재발급 API 응답 바디 원본: "${response.body}"');
      }

      if (response.statusCode == 200) {
        String? newAccessToken;
        
        // 1. 응답 본문에서 토큰 확인
        if (response.body.isNotEmpty) {
          try {
            final Map<String, dynamic> responseData = jsonDecode(response.body);
            if (responseData.containsKey('accessToken')) {
              newAccessToken = responseData['accessToken'];
            } else if (responseData.containsKey('access_token')) {
              newAccessToken = responseData['access_token'];
            } else if (responseData.containsKey('token')) {
              newAccessToken = responseData['token'];
            }
          } catch (e) {
            print('토큰 재발급 응답 파싱 예외: $e');
          }
        }
        
        // 2. 응답 헤더에서 토큰 확인 (본문에서 찾지 못한 경우)
        if (newAccessToken == null) {
          print('응답 본문에서 토큰을 찾지 못했습니다. 헤더 확인 중...');
          
          // 헤더에서 다양한 키 이름으로 검색
          final headers = response.headers;
          if (headers.containsKey('Authorization')) {
            newAccessToken = headers['Authorization'];
            if (newAccessToken?.startsWith('Bearer ') == true) {
              newAccessToken = newAccessToken?.substring(7);
            }
          } else if (headers.containsKey('authorization')) {
            newAccessToken = headers['authorization'];
            if (newAccessToken?.startsWith('Bearer ') == true) {
              newAccessToken = newAccessToken?.substring(7);
            }
          } else if (headers.containsKey('access-token') || headers.containsKey('accessToken')) {
            newAccessToken = headers['access-token'] ?? headers['accessToken'];
          }
          
          // 3. 빈 성공 응답이고 토큰이 없다면, 다른 API를 호출하여 유효성 테스트
          if (newAccessToken == null && response.statusCode == 200) {
            print('빈 응답 본문으로 토큰 재발급 성공했을 수 있습니다. 기존 토큰 유효성 테스트 중...');
            try {
              // 기존 토큰 가져오기
              final existingToken = await getAccessToken();
              if (existingToken != null && existingToken.isNotEmpty) {
                // 간단한 API 호출로 토큰 유효성 테스트
                final testUrl = Uri.parse('$baseUrl/api-user/user/info');
                final testResponse = await http.get(
                  testUrl,
                  headers: {'Authorization': 'Bearer $existingToken'},
                );
                
                // 유효한 토큰이면 계속 사용
                if (testResponse.statusCode == 200) {
                  print('기존 토큰이 여전히 유효합니다. 재사용합니다.');
                  return existingToken;
                }
              }
            } catch (e) {
              print('토큰 유효성 테스트 실패: $e');
            }
          }
        }
        
        // 새 토큰이 있다면 저장하고 반환
        if (newAccessToken != null && newAccessToken.isNotEmpty) {
          await storage.write(key: 'access_token', value: newAccessToken);
          print('새 액세스 토큰이 저장되었습니다: ${newAccessToken.substring(0, newAccessToken.length > 10 ? 10 : newAccessToken.length)}...');
          return newAccessToken;
        } else {
          print('응답에서 액세스 토큰을 찾을 수 없습니다. 헤더와 본문 모두 확인했습니다.');
          return null;
        }
      } else {
        // 리프레시 토큰도 만료되었거나 유효하지 않은 경우
        print('토큰 재발급 실패: ${response.statusCode}, ${response.body}');
        
        // 만료된 리프레시 토큰은 삭제하고 로그인 화면으로 리디렉션하도록
        if (response.statusCode == 401) {
          await storage.delete(key: 'refresh_token');
          print('만료된 리프레시 토큰을 삭제했습니다.');
        }
        
        return null;
      }
    } catch (e) {
      print('토큰 재발급 API 호출 예외: $e');
      return null;
    }
  }
}

