import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:mime/mime.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'push_notification_service.dart';
import 'token_service.dart';

class AuthService {
  // API 기본 URL
  static String get baseUrl => dotenv.env['API_BASE_URL'] ?? '';
  static final storage = FlutterSecureStorage();

  // 토큰 관련 키
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String firstLoginKey = 'first_login';
  static const String profileImagePathKey = 'profile_image_path';
  static const String socialTypeKey = 'social_type';
  static const String naverAccountIdKey = 'naver_account_id';
  static const String emailKey = 'email';
  static const String nameKey = 'name';

  // 토큰 재발급 중 여부를 체크하는 플래그
  static final bool _isRefreshing = false;
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
    String? accountPin,
    String? profileImageUrl,
    required String role,
    // 약관 동의 필드들 추가
    required bool agreedTermsOfService,
    required bool agreedPrivacyCollection,
    bool? agreedMinorGuardian,
    required bool agreedElectronicFinance,
    bool? agreedRewardGuardian,
    bool agreedThirdPartySharing = false,
    bool agreedDataProcessingDelegation = false,
    bool agreedMarketing = false,
  }) async {
    if (baseUrl.isEmpty) {
      throw Exception('API_BASE_URL가 설정되지 않았습니다. .env 파일을 확인하세요.');
    }

    // 입력값 검증
    _validateSignupInput(
      email: email,
      password: password,
      name: name,
      phone: phone,
      rrn: rrn,
      accountPin: accountPin,
    );

    final url = Uri.parse('$baseUrl/api-user/user/public/signup');

    // 요청 바디 구성
    final Map<String, dynamic> body = {
      'email': email.trim(),
      'password': password,
      'name': name.trim(),
      'phone': phone.replaceAll('-', ''), // 하이픈 제거
      'rrn': rrn,
      'role': role,
      // 약관 동의 필드들 추가
      'agreedTermsOfService': agreedTermsOfService,
      'agreedPrivacyCollection': agreedPrivacyCollection,
      'agreedElectronicFinance': agreedElectronicFinance,
      'agreedThirdPartySharing': agreedThirdPartySharing,
      'agreedDataProcessingDelegation': agreedDataProcessingDelegation,
      'agreedMarketing': agreedMarketing,
    };

    // 부모인 경우 agreedMinorGuardian, agreedRewardGuardian는 null로 전달
    if (role == 'PARENT') {
      // 부모는 해당 약관이 필요 없으므로 null로 설정하거나 생략
      body['agreedMinorGuardian'] = null;
      body['agreedRewardGuardian'] = null;
    } else {
      // 자녀인 경우 필수 동의
      body['agreedMinorGuardian'] = agreedMinorGuardian ?? true;
      body['agreedRewardGuardian'] = agreedRewardGuardian ?? true;
    }

    // 은행 정보가 있는 경우에만 추가
    if (bankName.isNotEmpty) {
      body['bankName'] = bankName;
    }
    if (bankAccount.isNotEmpty) {
      body['bankAccount'] = bankAccount;
    }
    if (bankCode.isNotEmpty) {
      body['bankCode'] = bankCode;
    }

    // 프로필 이미지 URL이 있는 경우에만 추가
    if (profileImageUrl != null && profileImageUrl.isNotEmpty) {
      body['profileImageUrl'] = profileImageUrl;
    }

    // accountPin이 있는 경우에만 추가
    if (accountPin != null && accountPin.isNotEmpty) {
      body['accountPin'] = accountPin;
    }

    print('[AuthService.signup] ============ 회원가입 요청 ============');
    print('요청 URL: $url');
    print('요청 바디: ${jsonEncode(body)}');
    print('==================================================');

    try {
      // POST 요청 보내기
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
      );

      print('[AuthService.signup] ============ 서버 응답 ============');
      print('응답 상태 코드: ${response.statusCode}');
      print('응답 헤더: ${response.headers}');
      print('응답 본문: ${response.body}');
      print('===============================================');

      // 응답 확인
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        print('[AuthService.signup] 회원가입 성공: $responseData');
        return responseData;
      } else {
        // 에러 응답을 파싱하려고 시도
        try {
          final errorBody = jsonDecode(response.body);
          final errorMessage = errorBody['message'] ?? errorBody.toString();
          print('[AuthService.signup] 회원가입 실패 - 에러: $errorMessage');

          // 특정 에러에 대한 한국어 메시지 처리
          String koreanMessage = _getKoreanErrorMessage(
            errorMessage,
            response.statusCode,
          );

          throw Exception(koreanMessage);
        } catch (e) {
          if (e.toString().contains('Exception:')) {
            rethrow; // 이미 처리된 예외는 그대로 전달
          }
          print('[AuthService.signup] 에러 응답 파싱 실패: $e');
          throw Exception('회원가입 실패: ${response.statusCode}, ${response.body}');
        }
      }
    } catch (e) {
      if (e.toString().contains('Exception:')) {
        rethrow; // 이미 처리된 예외는 그대로 전달
      }
      print('[AuthService.signup] 예외 발생: $e');

      // 네트워크 오류 확인
      if (e.toString().toLowerCase().contains('connection') ||
          e.toString().toLowerCase().contains('network') ||
          e.toString().toLowerCase().contains('socket') ||
          e.toString().toLowerCase().contains('timeout')) {
        throw Exception('네트워크 연결을 확인해주세요.');
      }

      throw Exception('회원가입 처리 중 오류가 발생했습니다.');
    }
  }

  // 회원가입 입력값 검증
  static void _validateSignupInput({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String rrn,
    String? accountPin,
  }) {
    // 이메일 검증 (최대 50자)
    if (email.trim().isEmpty) {
      throw Exception('이메일을 입력해주세요.');
    }
    if (email.trim().length > 50) {
      throw Exception('이메일은 최대 50자까지 입력 가능합니다.');
    }
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email.trim())) {
      throw Exception('올바른 이메일 형식을 입력해주세요.');
    }

    // 비밀번호 검증 (8자 이상)
    if (password.isEmpty) {
      throw Exception('비밀번호를 입력해주세요.');
    }
    if (password.length < 8) {
      throw Exception('비밀번호는 8자 이상 입력해주세요.');
    }

    // 이름 검증 (최대 20자)
    if (name.trim().isEmpty) {
      throw Exception('이름을 입력해주세요.');
    }
    if (name.trim().length > 20) {
      throw Exception('이름은 최대 20자까지 입력 가능합니다.');
    }

    // 전화번호 검증 (하이픈 제외 10자리 또는 11자리)
    final cleanPhone = phone.replaceAll('-', '');
    if (cleanPhone.isEmpty) {
      throw Exception('전화번호를 입력해주세요.');
    }
    if (cleanPhone.length != 10 && cleanPhone.length != 11) {
      throw Exception('전화번호는 10자리 또는 11자리를 입력해주세요.');
    }
    if (!RegExp(r'^[0-9]+$').hasMatch(cleanPhone)) {
      throw Exception('전화번호는 숫자만 입력 가능합니다.');
    }

    // 주민등록번호 앞자리 검증 (6자리)
    if (rrn.isEmpty) {
      throw Exception('생년월일 6자리를 입력해주세요.');
    }
    if (rrn.length != 6) {
      throw Exception('생년월일은 6자리를 입력해주세요. (예: 950101)');
    }
    if (!RegExp(r'^[0-9]+$').hasMatch(rrn)) {
      throw Exception('생년월일은 숫자만 입력 가능합니다.');
    }

    // 계좌 PIN 검증 (있는 경우에만)
    if (accountPin != null && accountPin.isNotEmpty) {
      if (accountPin.length != 6) {
        throw Exception('계좌 PIN은 6자리를 입력해주세요.');
      }
      if (!RegExp(r'^[0-9]+$').hasMatch(accountPin)) {
        throw Exception('계좌 PIN은 숫자만 입력 가능합니다.');
      }
    }
  }

  // 에러 메시지를 한국어로 변환
  static String _getKoreanErrorMessage(String errorMessage, int statusCode) {
    // 이메일 중복 에러
    if (errorMessage.toLowerCase().contains('email') &&
        (errorMessage.toLowerCase().contains('duplicate') ||
            errorMessage.toLowerCase().contains('already') ||
            errorMessage.toLowerCase().contains('exist'))) {
      return '이미 사용 중인 이메일입니다.';
    }

    // 비밀번호 길이 에러
    if (errorMessage.toLowerCase().contains('password') &&
        errorMessage.toLowerCase().contains('length')) {
      return '비밀번호는 8자 이상 입력해주세요.';
    }

    // 400 에러의 경우
    if (statusCode == 400) {
      return '입력 정보를 다시 확인해주세요.';
    }

    // 409 에러의 경우 (중복)
    if (statusCode == 409) {
      return '이미 사용 중인 정보입니다.';
    }

    // 500 에러의 경우
    if (statusCode == 500) {
      return '서버 오류가 발생했습니다. 잠시 후 다시 시도해주세요.';
    }

    // 기본값
    return '회원가입 중 오류가 발생했습니다: $errorMessage';
  }

  // 로그인 API
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    String? fcmToken,
  }) async {
    if (baseUrl.isEmpty) {
      throw Exception('API_BASE_URL가 설정되지 않았습니다. .env 파일을 확인하세요.');
    }

    final url = Uri.parse('$baseUrl/api-user/auth/public/login');

    // 요청 바디 구성 - FCM 토큰 추가
    final Map<String, dynamic> body = {
      'email': email,
      'password': password,
      'fcmToken': fcmToken ?? await _getFcmToken(), // FCM 토큰 추가
    };

    try {
      // POST 요청 보내기
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      // 쿠키 검사
      if (response.headers.containsKey('set-cookie')) {
        final cookies = response.headers['set-cookie']!.split(';');
        for (final cookie in cookies) {
          if (cookie.trim().toLowerCase().startsWith('refreshtoken=') ||
              cookie.trim().toLowerCase().startsWith('refresh_token=') ||
              cookie.trim().toLowerCase().startsWith('refresh-token=')) {
            // 토큰 값 추출
            final tokenValue = cookie.split('=')[1].trim();
            if (tokenValue.isNotEmpty) {
              await storage.write(key: refreshTokenKey, value: tokenValue);
            }
          }
        }
      }

      // 응답 확인
      if (response.statusCode == 200) {
        // 응답 본문 디코딩
        final Map<String, dynamic> responseData = jsonDecode(response.body);

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
          await storage.write(key: accessTokenKey, value: accessToken);
        }

        // 첫 로그인 상태 확인
        final isFirst = await storage.read(key: firstLoginKey);
        if (isFirst == null) {
          await storage.write(key: firstLoginKey, value: 'true');
        } else {
          // 로그인 성공 시에는 first_login을 true로 설정
          await storage.write(key: firstLoginKey, value: 'true');
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
      // 네트워크 오류인지 확인
      if (e.toString().toLowerCase().contains('connection') ||
          e.toString().toLowerCase().contains('network') ||
          e.toString().toLowerCase().contains('socket')) {
        throw Exception('네트워크 연결을 확인해주세요.');
      }

      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // FCM 토큰 가져오기 헬퍼 함수
  static Future<String> _getFcmToken() async {
    try {
      // PushNotificationService에서 토큰 가져오기 시도
      final pushService = PushNotificationService();
      await pushService.init(); // 초기화되지 않았을 경우를 대비

      // 토큰이 없으면 빈 문자열 반환
      return pushService.token ?? '';
    } catch (e) {
      print('FCM 토큰 가져오기 실패: $e');
      return '';
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

    try {
      // GET 요청으로 Pre-signed URL 발급
      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $accessToken'},
      );

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

      // PUT 요청으로 파일 업로드
      final response = await http.put(
        Uri.parse(uploadUrl),
        headers: {
          'Content-Type': mimeType,
          'Content-Length': fileBytes.length.toString(),
        },
        body: fileBytes,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return uploadUrl;
      } else {
        throw Exception(
          '파일 업로드 실패: ${response.statusCode}, ${response.reasonPhrase}',
        );
      }
    } catch (e) {
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
      throw Exception('프로필 이미지 업로드 중 오류가 발생했습니다: $e');
    }
  }

  // 토큰 가져오기
  static Future<String?> getAccessToken() async {
    return await storage.read(key: accessTokenKey);
  }

  // 리프레시 토큰 가져오기
  static Future<String?> getRefreshToken() async {
    try {
      return await storage.read(key: refreshTokenKey);
    } catch (e) {
      return null;
    }
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
        return {'success': true, 'message': '로그아웃되었습니다.'};
      }

      final url = Uri.parse('$baseUrl/api-user/auth/logout');

      // 요청 헤더 구성
      final Map<String, String> headers = {
        'Authorization':
            accessToken.startsWith('Bearer ')
                ? accessToken
                : 'Bearer $accessToken',
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
        if (response.statusCode == 204 ||
            (response.statusCode >= 200 && response.statusCode < 300)) {
          return {'success': true, 'message': '로그아웃되었습니다.'};
        } else {
          return {'success': true, 'message': '로컬에서 로그아웃되었습니다.'};
        }
      } catch (e) {
        await clearAllAuthData();
        return {'success': true, 'message': '로컬에서 로그아웃되었습니다.'};
      }
    } catch (e) {
      await clearAllAuthData();
      return {'success': true, 'message': '로컬에서 로그아웃되었습니다.'};
    }
  }

  // 첫 로그인 상태 확인 및 관리
  static Future<bool> isFirstLogin() async {
    return await storage.read(key: firstLoginKey) != 'false';
  }

  static Future<void> setFirstLoginCompleted() async {
    await storage.write(key: firstLoginKey, value: 'false');
  }

  // 사용자 프로필 이미지 경로 저장
  static Future<void> saveProfileImagePath(String path) async {
    await storage.write(key: profileImagePathKey, value: path);
  }

  // 사용자 프로필 이미지 경로 가져오기
  static Future<String?> getProfileImagePath() async {
    return await storage.read(key: profileImagePathKey);
  }

  // 프로필 이미지 전체 URL 구성 - S3 직접 접근
  static String getFullProfileImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return '';
    }

    // 이미 http로 시작하는 경우 URL 그대로 반환 (카카오 CDN 등 외부 URL 포함)
    if (imagePath.startsWith('http')) {
      return imagePath;
    }

    // S3 URL 직접 구성
    return 'https://littlebank-dev.s3.ap-northeast-2.amazonaws.com/$imagePath';
  }

  // 소셜 로그인 타입 저장
  static Future<void> setSocialType(String type) async {
    await storage.write(key: socialTypeKey, value: type);
  }

  // 소셜 로그인 타입 가져오기 (네이버인지 카카오인지)
  static Future<String?> getSocialType() async {
    return await storage.read(key: socialTypeKey);
  }

  // 네이버 계정 ID 저장
  static Future<void> setNaverAccountId(String id) async {
    await storage.write(key: naverAccountIdKey, value: id);
  }

  // 네이버 계정 ID 가져오기
  static Future<String?> getNaverAccountId() async {
    return await storage.read(key: naverAccountIdKey);
  }

  // 이메일 저장
  static Future<void> setEmail(String email) async {
    await storage.write(key: emailKey, value: email);
  }

  // 이메일 가져오기
  static Future<String?> getEmail() async {
    return await storage.read(key: emailKey);
  }

  // 이름 저장
  static Future<void> setName(String name) async {
    await storage.write(key: nameKey, value: name);
  }

  // 이름 가져오기
  static Future<String?> getName() async {
    return await storage.read(key: nameKey);
  }

  // 모든 인증 데이터 삭제
  static Future<void> clearAllAuthData() async {
    try {
      await storage.delete(key: accessTokenKey);
      await storage.delete(key: refreshTokenKey);
      await storage.delete(key: socialTypeKey);
      await storage.delete(key: naverAccountIdKey);
      await storage.delete(key: emailKey);
      await storage.delete(key: nameKey);
      await storage.delete(key: profileImagePathKey);
      // firstLoginKey는 유지 - 다음 로그인에서 재설정됨
      // 로고/스플래시 상태는 유지 - 디바이스에 한 번 보여주면 다시 보여주지 않음
      print('✅ 인증 데이터 삭제 완료');
    } catch (e) {
      print('❌ 인증 데이터 삭제 실패: $e');
      rethrow;
    }
  }

  // 회원탈퇴 API 호출
  static Future<bool> deleteAccount({String? reason}) async {
    try {
      final url = Uri.parse('$baseUrl/api-user/user');
      final token = await storage.read(key: accessTokenKey);

      // 요청 바디 구성
      final Map<String, dynamic> body = {};
      if (reason != null && reason.trim().isNotEmpty) {
        body['reason'] = reason.trim();
      }

      print('[AuthService.deleteAccount] ============ 회원탈퇴 요청 ============');
      print('요청 URL: $url');
      print('탈퇴 사유: $reason');
      print('요청 바디: ${jsonEncode(body)}');
      print('=========================================================');

      final response = await http.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: body.isNotEmpty ? jsonEncode(body) : null,
      );

      print('[AuthService.deleteAccount] ============ 서버 응답 ============');
      print('응답 상태 코드: ${response.statusCode}');
      print('응답 본문: ${response.body}');
      print('======================================================');

      // 200 (OK) 또는 204 (No Content) 모두 성공으로 처리
      if (response.statusCode == 200 || response.statusCode == 204) {
        // 토큰 삭제
        await clearAllAuthData();
        return true;
      } else {
        // 에러 응답 처리 - 빈 응답 본문 고려
        String errorMessage = '탈퇴 처리 중 오류가 발생했습니다.';
        String? errorCode;

        if (response.body.isNotEmpty) {
          try {
            final errorBody = json.decode(response.body);
            errorCode = errorBody['code'];
            errorMessage = errorBody['message'] ?? errorMessage;

            // C004 에러 코드에 대한 특별 처리
            if (errorCode == 'C004') {
              errorMessage =
                  '탈퇴 처리 중 서버 오류가 발생했습니다.\n\n다음 사항을 확인해주세요:\n• 남은 포인트가 있다면 미리 출금해주세요\n• 진행 중인 미션이나 챌린지가 있는지 확인해주세요\n• 가족 구성원이 연결되어 있다면 관리자 권한을 이양해주세요\n\n문제가 지속되면 고객센터로 문의해주세요.';
            }

            print(
              '[AuthService.deleteAccount] 에러 상세 정보 - 코드: $errorCode, 메시지: $errorMessage',
            );
          } catch (e) {
            // JSON 파싱 실패 시 기본 메시지 사용
            print('[AuthService.deleteAccount] 에러 응답 파싱 실패: $e');
          }
        }

        throw Exception(errorMessage);
      }
    } catch (e) {
      print('[AuthService.deleteAccount] 예외 발생: $e');
      throw Exception('회원탈퇴 처리 중 오류가 발생했습니다.');
    }
  }

  // 토큰 재발급
  static Future<String?> reissueAccessToken() async {
    try {
      final refreshToken = await getRefreshToken();

      if (refreshToken == null || refreshToken.isEmpty) {
        return null;
      }

      final url = Uri.parse('$baseUrl/api-user/auth/reissue');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Cookie': 'refreshToken=$refreshToken',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        String? newToken;

        if (responseData.containsKey('accessToken')) {
          newToken = responseData['accessToken'];
        } else if (responseData.containsKey('access_token')) {
          newToken = responseData['access_token'];
        } else if (responseData.containsKey('token')) {
          newToken = responseData['token'];
        }

        if (newToken != null && newToken.isNotEmpty) {
          await storage.write(key: accessTokenKey, value: newToken);
          return newToken;
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  // 현재 로그인한 사용자의 ID 가져오기
  static Future<String?> getCurrentUserId() async {
    try {
      // 저장된 사용자 정보에서 ID 가져오기
      final userInfo = await getLocalUserInfo();
      return userInfo?['id']?.toString();
    } catch (e) {
      print('사용자 ID 가져오기 오류: $e');
      return null;
    }
  }

  // 현재 로그인한 사용자의 이름 가져오기
  static Future<String?> getCurrentUserName() async {
    try {
      // 저장된 사용자 정보에서 이름 가져오기
      final userInfo = await getLocalUserInfo();
      return userInfo?['name']?.toString();
    } catch (e) {
      print('사용자 이름 가져오기 오류: $e');
      return null;
    }
  }

  // 로컬에 저장된 사용자 정보 가져오기
  static Future<Map<String, dynamic>?> getLocalUserInfo() async {
    try {
      // 토큰에서 정보 파싱 또는 저장된 사용자 정보 가져오기
      // 실제 구현은 기존 인증 방식에 따라 다를 수 있음
      final prefs = await SharedPreferences.getInstance();
      final userInfoStr = prefs.getString('user_info');

      if (userInfoStr != null && userInfoStr.isNotEmpty) {
        return json.decode(userInfoStr);
      }

      return null;
    } catch (e) {
      print('로컬 사용자 정보 가져오기 오류: $e');
      return null;
    }
  }

  // 서버에서 사용자 정보 조회 API
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

      print('[AuthService.getUserInfo] ============ 내 정보 조회 요청 ============');
      print('요청 URL: $url');
      print('=====================================================');

      // GET 요청 보내기
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Accept': 'application/json; charset=utf-8',
          'Content-Type': 'application/json; charset=utf-8',
        },
      );

      print('[AuthService.getUserInfo] ============ 서버 응답 ============');
      print('응답 상태 코드: ${response.statusCode}');
      print('====================================================');

      // 토큰 만료 확인 (C007 오류)
      if (response.statusCode == 401) {
        final responseBody = utf8.decode(response.bodyBytes);
        final errorData = jsonDecode(responseBody);

        if (errorData is Map &&
            errorData.containsKey('code') &&
            errorData['code'] == 'C007') {
          // 리프레시 토큰으로 액세스 토큰 재발급 시도
          final newAccessToken = await reissueAccessToken();

          if (newAccessToken != null) {
            // 새 액세스 토큰으로 요청 재시도
            final retryResponse = await http.get(
              url,
              headers: {
                'Authorization': 'Bearer $newAccessToken',
                'Accept': 'application/json; charset=utf-8',
                'Content-Type': 'application/json; charset=utf-8',
              },
            );

            if (retryResponse.statusCode == 200) {
              // UTF-8로 디코딩하여 처리
              final decodedBody = utf8.decode(retryResponse.bodyBytes);
              final userData = jsonDecode(decodedBody);

              print('[AuthService.getUserInfo] 재시도 성공 - 사용자 정보:');
              print('- 사용자 ID: ${userData['userId']}');
              print('- 이메일: ${userData['email']}');
              print('- 이름: ${userData['name']}');
              print('- 상태 메시지: ${userData['statusMessage'] ?? '없음'}');
              print('- 전화번호: ${userData['phone'] ?? '없음'}');
              print('- 은행명: ${userData['bankName'] ?? '없음'}');
              print('- 계좌번호: ${userData['bankAccount'] ?? '없음'}');
              print('- 포인트: ${userData['point'] ?? 0}');
              print('- 누적 포인트: ${userData['accumulatedPoint'] ?? 0}');
              print('- 목표 금액: ${userData['targetAmount'] ?? 0}');
              print('- 학교명: ${userData['schoolName'] ?? '없음'}');
              print('- 학교 유형: ${userData['schoolType'] ?? '없음'}');
              print('- 지역: ${userData['region'] ?? '없음'}');
              print('- 주소: ${userData['address'] ?? '없음'}');
              print('- 역할: ${userData['role'] ?? '없음'}');
              print('- 권한: ${userData['authority'] ?? '없음'}');
              print('- 구독 여부: ${userData['subscribe'] ?? false}');

              // 프로필 이미지 경로가 있으면 로컬 저장소에 저장
              if (userData.containsKey('profileImagePath') &&
                  userData['profileImagePath'] != null &&
                  userData['profileImagePath'].toString().isNotEmpty) {
                await storage.write(
                  key: profileImagePathKey,
                  value: userData['profileImagePath'],
                );
              }

              return userData;
            } else {
              // 재시도 실패
              throw Exception(
                '정보 조회 재시도 실패: ${retryResponse.statusCode}, ${utf8.decode(retryResponse.bodyBytes)}',
              );
            }
          } else {
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

        print('[AuthService.getUserInfo] 조회 성공 - 사용자 정보:');
        print('- 사용자 ID: ${userData['userId']}');
        print('- 이메일: ${userData['email']}');
        print('- 이름: ${userData['name']}');
        print('- 상태 메시지: ${userData['statusMessage'] ?? '없음'}');
        print('- 전화번호: ${userData['phone'] ?? '없음'}');
        print('- 주민등록번호: ${userData['rrn'] ?? '없음'}');
        print('- 은행명: ${userData['bankName'] ?? '없음'}');
        print('- 은행 코드: ${userData['bankCode'] ?? '없음'}');
        print('- 계좌번호: ${userData['bankAccount'] ?? '없음'}');
        print('- 프로필 이미지: ${userData['profileImagePath'] ?? '없음'}');
        print('- 포인트: ${userData['point'] ?? 0}');
        print('- 누적 포인트: ${userData['accumulatedPoint'] ?? 0}');
        print('- 목표 금액: ${userData['targetAmount'] ?? 0}');
        print('- 학교명: ${userData['schoolName'] ?? '없음'}');
        print('- 학교 유형: ${userData['schoolType'] ?? '없음'}');
        print('- 지역: ${userData['region'] ?? '없음'}');
        print('- 주소: ${userData['address'] ?? '없음'}');
        print('- 역할: ${userData['role'] ?? '없음'}');
        print('- 권한: ${userData['authority'] ?? '없음'}');
        print('- 마지막 로그인: ${userData['lastLoginAt'] ?? '없음'}');
        print('- 등록일: ${userData['registeredAt'] ?? '없음'}');
        print('- 구독 여부: ${userData['subscribe'] ?? false}');

        // 프로필 이미지 경로가 있으면 로컬 저장소에 저장
        if (userData.containsKey('profileImagePath') &&
            userData['profileImagePath'] != null &&
            userData['profileImagePath'].toString().isNotEmpty) {
          await storage.write(
            key: profileImagePathKey,
            value: userData['profileImagePath'],
          );
        }

        return userData;
      } else {
        throw Exception(
          '정보 조회 실패: ${response.statusCode}, ${utf8.decode(response.bodyBytes)}',
        );
      }
    } catch (e) {
      print('[AuthService.getUserInfo] 예외 발생: $e');
      throw Exception('정보 조회 중 오류가 발생했습니다: $e');
    }
  }

  // 프로필 이미지 업데이트
  static Future<Map<String, dynamic>> updateUserProfile(
    String imagePath,
  ) async {
    if (baseUrl.isEmpty) {
      throw Exception('API_BASE_URL가 설정되지 않았습니다. .env 파일을 확인하세요.');
    }

    String? accessToken = await getAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('인증이 필요합니다. 로그인을 다시 시도해주세요.');
    }

    final url = Uri.parse('$baseUrl/api-user/user/profile-image');
    final body = {'profileImagePath': imagePath};

    final response = await http.patch(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final decodedBody = utf8.decode(response.bodyBytes);
      return jsonDecode(decodedBody);
    } else {
      throw Exception('프로필 이미지 업데이트 실패: ${response.statusCode}');
    }
  }

  // 사용자 정보 업데이트 (API 스펙에 맞춰 최적화)
  static Future<Map<String, dynamic>> updateUserInfo({
    String? name,
    String? email,
    String? bankName,
    String? bankCode,
    String? bankAccount,
    String? accountPin,
    // 추가 필드들 (필요시에만 사용)
    String? phone,
    String? rrn,
    String? statusMessage,
    String? profileImagePath,
    String? role,
    String? authority,
    bool? subscribe,
  }) async {
    if (baseUrl.isEmpty) {
      throw Exception('API_BASE_URL가 설정되지 않았습니다. .env 파일을 확인하세요.');
    }

    String? accessToken = await getAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('인증이 필요합니다. 로그인을 다시 시도해주세요.');
    }

    final url = Uri.parse('$baseUrl/api-user/user/info');
    final body = <String, dynamic>{};

    // API 스펙에 맞는 필수 필드들만 추가
    if (name != null) body['name'] = name;
    if (email != null) body['email'] = email;
    if (bankName != null) body['bankName'] = bankName;
    if (bankCode != null) body['bankCode'] = bankCode;
    if (bankAccount != null) body['bankAccount'] = bankAccount;
    if (accountPin != null) body['accountPin'] = accountPin;

    // 선택적 필드들 (서버에서 지원하는 경우에만)
    if (phone != null) body['phone'] = phone;
    if (rrn != null) body['rrn'] = rrn;
    if (statusMessage != null) body['statusMessage'] = statusMessage;
    if (profileImagePath != null) body['profileImagePath'] = profileImagePath;
    if (role != null) body['role'] = role;
    if (authority != null) body['authority'] = authority;
    if (subscribe != null) body['subscribe'] = subscribe;

    print(
      '[AuthService.updateUserInfo] ============ 사용자 정보 업데이트 요청 ============',
    );
    print('요청 URL: $url');
    print('전송할 데이터: ${jsonEncode(body)}');
    print('액세스 토큰: ${accessToken.substring(0, 20)}...');
    print('===============================================================');

    try {
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(body),
      );

      print('[AuthService.updateUserInfo] ============ 서버 응답 ============');
      print('응답 상태 코드: ${response.statusCode}');
      print('응답 헤더: ${response.headers}');
      print('응답 본문: ${response.body}');
      print('========================================================');

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        return jsonDecode(decodedBody);
      } else {
        // 에러 응답 상세 처리
        try {
          final errorBody = jsonDecode(response.body);
          print('[AuthService.updateUserInfo] 에러 상세: $errorBody');
          throw Exception(
            '사용자 정보 업데이트 실패: ${response.statusCode} - ${errorBody['message'] ?? errorBody.toString()}',
          );
        } catch (e) {
          print('[AuthService.updateUserInfo] 에러 응답 파싱 실패: $e');
          throw Exception('사용자 정보 업데이트 실패: ${response.statusCode}');
        }
      }
    } catch (e) {
      print('[AuthService.updateUserInfo] 예외 발생: $e');
      throw Exception('사용자 정보 업데이트 중 네트워크 오류: $e');
    }
  }

  // 외부 URL인지 확인하는 헬퍼 함수 (인증 헤더가 필요하지 않은 URL들)
  static bool isS3Url(String url) {
    return url.contains('s3.ap-northeast-2.amazonaws.com') ||
        url.contains('amazonaws.com') ||
        url.contains('kakaocdn.net') || // 카카오 CDN
        url.contains('profile-image.kakaocdn.net') || // 카카오 프로필 이미지 CDN
        url.contains('k.kakaocdn.net') || // 카카오 CDN
        url.contains('googleusercontent.com') || // 구글 프로필 이미지
        url.contains('graph.facebook.com') || // 페이스북 프로필 이미지
        url.contains('phinf.pstatic.net') || // 네이버 프로필 이미지
        url.contains('ssl.pstatic.net'); // 네이버 프로필 이미지
  }

  // 인증 토큰을 포함한 이미지 URL 헤더 반환
  static Future<Map<String, String>> getImageHeaders() async {
    String? token = await getAccessToken();
    if (token == null || token.isEmpty) {
      return {};
    }

    return {
      'Authorization': 'Bearer $token',
      'Accept': 'image/*, */*',
      'Cache-Control': 'no-cache',
    };
  }

  // fcmToken을 가져오는 메서드 추가
  static Future<String> getFcmToken() async {
    return await storage.read(key: 'fcmToken') ?? '';
  }

  // PIN 설정/재설정 API
  static Future<Map<String, dynamic>> setAccountPin({
    required String pin,
  }) async {
    if (baseUrl.isEmpty) {
      throw Exception('API_BASE_URL가 설정되지 않았습니다. .env 파일을 확인하세요.');
    }

    String? accessToken = await getAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('인증이 필요합니다. 로그인을 다시 시도해주세요.');
    }

    final url = Uri.parse('$baseUrl/api-user/user/account/pin/reset');
    final body = {'pin': pin};

    print('[AuthService.setAccountPin] ============ PIN 설정 요청 ============');
    print('요청 URL: $url');
    print('전송할 데이터: ${jsonEncode(body)}');
    print('액세스 토큰: ${accessToken.substring(0, 20)}...');
    print('===============================================================');

    try {
      final response = await http.patch(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(body),
      );

      print('[AuthService.setAccountPin] ============ 서버 응답 ============');
      print('응답 상태 코드: ${response.statusCode}');
      print('응답 헤더: ${response.headers}');
      print('응답 본문: ${response.body}');
      print('========================================================');

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        return jsonDecode(decodedBody);
      } else {
        // 에러 응답 상세 처리
        try {
          final errorBody = jsonDecode(response.body);
          print('[AuthService.setAccountPin] 에러 상세: $errorBody');
          throw Exception(
            'PIN 설정 실패: ${response.statusCode} - ${errorBody['message'] ?? errorBody.toString()}',
          );
        } catch (e) {
          print('[AuthService.setAccountPin] 에러 응답 파싱 실패: $e');
          throw Exception('PIN 설정 실패: ${response.statusCode}');
        }
      }
    } catch (e) {
      print('[AuthService.setAccountPin] 예외 발생: $e');
      throw Exception('PIN 설정 중 네트워크 오류: $e');
    }
  }

  // 계좌 검증 API
  static Future<Map<String, dynamic>> verifyAccountHolder({
    required String bankCode,
    required String bankNumber,
    required String holderName,
  }) async {
    if (baseUrl.isEmpty) {
      throw Exception('API_BASE_URL가 설정되지 않았습니다. .env 파일을 확인하세요.');
    }

    final url = Uri.parse(
      '$baseUrl/api-user/auth/public/account/holder/verify',
    );

    // 요청 바디 구성
    final Map<String, dynamic> body = {
      'bankCode': bankCode,
      'bankNumber': bankNumber,
      'holderName': holderName,
    };

    print(
      '[AuthService.verifyAccountHolder] ============ 계좌 검증 요청 ============',
    );
    print('요청 URL: $url');
    print('은행 코드: $bankCode (${bankCode.runtimeType})');
    print('계좌 번호: $bankNumber (${bankNumber.runtimeType})');
    print('예금주명: $holderName (${holderName.runtimeType})');
    print('요청 바디: ${jsonEncode(body)}');
    print('====================================================');

    try {
      // POST 요청 보내기 (public API이므로 토큰 불필요)
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
      );

      print(
        '[AuthService.verifyAccountHolder] ============ 서버 응답 ============',
      );
      print('응답 상태 코드: ${response.statusCode}');
      print('응답 헤더: ${response.headers}');
      print('응답 본문: ${response.body}');
      print('====================================================');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        // 응답에서 예금주명 확인
        final accountHolder = responseData['accountHolder'] ?? '';

        print(
          '[AuthService.verifyAccountHolder] 검증 결과 - 서버 예금주: $accountHolder, 입력 예금주: $holderName',
        );

        // 예금주명이 일치하는지 확인
        if (accountHolder == holderName) {
          return {
            'success': true,
            'accountHolder': accountHolder,
            'message': '계좌 인증이 완료되었습니다.',
          };
        } else {
          return {
            'success': false,
            'accountHolder': accountHolder,
            'message': '입력하신 예금주명과 일치하지 않습니다.',
          };
        }
      } else {
        // 에러 응답 처리
        try {
          final errorBody = jsonDecode(response.body);
          final errorCode = errorBody['code'] ?? '';
          String errorMessage = errorBody['message'] ?? '계좌 검증에 실패했습니다.';

          print('[AuthService.verifyAccountHolder] 에러 코드: $errorCode');

          // 에러 코드별 처리
          switch (errorCode) {
            case 'C004':
              errorMessage = '서버에서 계좌 검증 처리 중 오류가 발생했습니다.\n잠시 후 다시 시도해주세요.';
              break;
            case 'C001':
              errorMessage = '잘못된 요청입니다. 입력 정보를 확인해주세요.';
              break;
            case 'C002':
              errorMessage = '계좌 정보를 찾을 수 없습니다.';
              break;
            case 'C003':
              errorMessage = '예금주명이 일치하지 않습니다.';
              break;
            default:
              // 기본 에러 메시지 처리
              if (errorMessage.contains('조회하지 못한')) {
                errorMessage = '계좌 정보를 조회할 수 없습니다. 계좌번호를 다시 확인해주세요.';
              } else if (errorMessage.contains('일치하지 않')) {
                errorMessage = '예금주명이 일치하지 않습니다.';
              } else if (errorMessage == 'Server Error') {
                errorMessage = '서버 오류가 발생했습니다. 잠시 후 다시 시도해주세요.';
              }
              break;
          }

          return {
            'success': false,
            'message': errorMessage,
            'errorCode': errorCode,
          };
        } catch (e) {
          print('[AuthService.verifyAccountHolder] 에러 응답 파싱 실패: $e');
          return {
            'success': false,
            'message': '계좌 검증 실패: ${response.statusCode}',
          };
        }
      }
    } catch (e) {
      print('[AuthService.verifyAccountHolder] 예외 발생: $e');
      print('[AuthService.verifyAccountHolder] 예외 타입: ${e.runtimeType}');

      // 네트워크 오류 확인
      if (e.toString().toLowerCase().contains('connection') ||
          e.toString().toLowerCase().contains('network') ||
          e.toString().toLowerCase().contains('socket') ||
          e.toString().toLowerCase().contains('timeout')) {
        return {'success': false, 'message': '네트워크 연결을 확인해주세요.'};
      }

      return {'success': false, 'message': '계좌 검증 중 오류가 발생했습니다.'};
    }
  }

  // 핸드폰번호로 사용자 검색 API
  static Future<Map<String, dynamic>> searchUserByPhone({
    required String phone,
  }) async {
    if (baseUrl.isEmpty) {
      throw Exception('API_BASE_URL가 설정되지 않았습니다. .env 파일을 확인하세요.');
    }

    // 액세스 토큰 가져오기 (인증 필요한 API)
    String? accessToken = await getAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('인증이 필요합니다. 로그인 후 다시 시도해주세요.');
    }

    // 핸드폰번호에서 하이픈 제거
    final cleanPhone = phone.replaceAll('-', '');

    final url = Uri.parse('$baseUrl/api-user/user/search?phone=$cleanPhone');

    print(
      '[AuthService.searchUserByPhone] ============ 사용자 검색 요청 ============',
    );
    print('요청 URL: $url');
    print('검색할 핸드폰번호: $cleanPhone');
    print('============================================================');

    try {
      // GET 요청 보내기
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      print('[AuthService.searchUserByPhone] ============ 서버 응답 ============');
      print('응답 상태 코드: ${response.statusCode}');
      print('응답 본문: ${response.body}');
      print('=====================================================');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {'success': true, 'data': responseData};
      } else if (response.statusCode == 404) {
        return {'success': false, 'message': '해당 핸드폰번호로 등록된 사용자를 찾을 수 없습니다.'};
      } else {
        // 에러 응답 처리
        try {
          final errorBody = jsonDecode(response.body);
          final errorMessage = errorBody['message'] ?? '사용자 검색에 실패했습니다.';
          return {'success': false, 'message': errorMessage};
        } catch (e) {
          return {
            'success': false,
            'message': '사용자 검색 실패: ${response.statusCode}',
          };
        }
      }
    } catch (e) {
      print('[AuthService.searchUserByPhone] 예외 발생: $e');

      // 네트워크 오류 확인
      if (e.toString().toLowerCase().contains('connection') ||
          e.toString().toLowerCase().contains('network') ||
          e.toString().toLowerCase().contains('socket') ||
          e.toString().toLowerCase().contains('timeout')) {
        return {'success': false, 'message': '네트워크 연결을 확인해주세요.'};
      }

      return {'success': false, 'message': '사용자 검색 중 오류가 발생했습니다.'};
    }
  }

  // 계좌정보로 유저 조회 API
  static Future<Map<String, dynamic>?> searchUserByAccount({
    required String bankCode,
    required String account,
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

      // URL 파라미터 구성
      final url = Uri.parse(
        '$baseUrl/api-user/user/search/by-account?bankCode=${Uri.encodeComponent(bankCode)}&account=${Uri.encodeComponent(account)}',
      );

      print(
        '[AuthService.searchUserByAccount] ============ 계좌정보로 유저 조회 요청 ============',
      );
      print('요청 URL: $url');
      print('은행 코드: $bankCode');
      print('계좌 번호: $account');
      print(
        '==================================================================',
      );

      // GET 요청 보내기
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Accept': 'application/json; charset=utf-8',
          'Content-Type': 'application/json; charset=utf-8',
        },
      );

      print(
        '[AuthService.searchUserByAccount] ============ 서버 응답 ============',
      );
      print('응답 상태 코드: ${response.statusCode}');
      print('=======================================================');

      if (response.statusCode == 200) {
        // UTF-8로 디코딩하여 처리
        final decodedBody = utf8.decode(response.bodyBytes);
        final userData = jsonDecode(decodedBody);

        print('[AuthService.searchUserByAccount] 조회 성공 - 사용자 정보:');
        print('- 사용자 ID: ${userData['userId']}');
        print('- 실제 이름: ${userData['realName']}');
        print('- 주민등록번호: ${userData['rrn'] ?? '없음'}');
        print('- 전화번호: ${userData['phone'] ?? '없음'}');
        print('- 상태 메시지: ${userData['statusMessage'] ?? '없음'}');
        print('- 은행명: ${userData['backName'] ?? '없음'}');
        print('- 은행 코드: ${userData['backCode'] ?? '없음'}');
        print('- 계좌번호: ${userData['backAccount'] ?? '없음'}');
        print('- 프로필 이미지: ${userData['profileImagePath'] ?? '없음'}');
        print('- 목표 금액: ${userData['targetAmount'] ?? 0}');
        print('- 학교명: ${userData['schoolName'] ?? '없음'}');
        print('- 학교 유형: ${userData['schoolType'] ?? '없음'}');
        print('- 지역: ${userData['region'] ?? '없음'}');
        print('- 주소: ${userData['address'] ?? '없음'}');
        print('- 역할: ${userData['role'] ?? '없음'}');

        return userData;
      } else if (response.statusCode == 404) {
        print('[AuthService.searchUserByAccount] 해당 계좌 정보로 등록된 사용자가 없습니다.');
        return null;
      } else {
        print(
          '[AuthService.searchUserByAccount] 오류 응답: ${utf8.decode(response.bodyBytes)}',
        );
        throw Exception(
          '계좌 정보로 사용자 조회 실패: ${response.statusCode}, ${utf8.decode(response.bodyBytes)}',
        );
      }
    } catch (e) {
      print('[AuthService.searchUserByAccount] 예외 발생: $e');
      throw Exception('계좌 정보로 사용자 조회 중 오류가 발생했습니다: $e');
    }
  }

  // PIN 설정 여부 확인 API
  static Future<bool> hasPinSet() async {
    try {
      // 사용자 정보 조회를 통해 PIN 설정 여부 확인
      final userInfo = await getUserInfo();

      // accountPin 필드가 존재하고 null이 아니며 빈 문자열이 아닌 경우 PIN이 설정된 것으로 판단
      final accountPin = userInfo['accountPin'];
      return accountPin != null && accountPin.toString().isNotEmpty;
    } catch (e) {
      print('[AuthService.hasPinSet] PIN 설정 여부 확인 오류: $e');
      return false;
    }
  }

  // PIN 검증 API
  static Future<Map<String, dynamic>> verifyPin({required String pin}) async {
    if (baseUrl.isEmpty) {
      return {'success': false, 'message': 'API_BASE_URL가 설정되지 않았습니다.'};
    }

    // 액세스 토큰 가져오기 (인증 필요한 API)
    String? accessToken = await getAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      return {'success': false, 'message': '인증이 필요합니다. 로그인 후 다시 시도해주세요.'};
    }

    final url = Uri.parse('$baseUrl/api-user/auth/account/pin/verify');

    // 요청 바디 구성
    final Map<String, dynamic> body = {'pin': pin};

    print('[AuthService.verifyPin] ============ PIN 검증 요청 ============');
    print('요청 URL: $url');
    print('요청 바디: ${jsonEncode(body)}');
    print('=======================================================');

    try {
      // POST 요청 보내기
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(body),
      );

      print('[AuthService.verifyPin] ============ 서버 응답 ============');
      print('응답 상태 코드: ${response.statusCode}');
      print('응답 본문: ${response.body}');
      print('==================================================');

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'PIN 인증이 완료되었습니다.'};
      } else if (response.statusCode == 400 || response.statusCode == 401) {
        return {'success': false, 'message': 'PIN 번호가 일치하지 않습니다.'};
      } else {
        // 에러 응답 처리
        try {
          final errorBody = jsonDecode(response.body);
          final errorMessage = errorBody['message'] ?? 'PIN 검증에 실패했습니다.';
          return {'success': false, 'message': errorMessage};
        } catch (e) {
          return {
            'success': false,
            'message': 'PIN 검증 실패: ${response.statusCode}',
          };
        }
      }
    } catch (e) {
      print('[AuthService.verifyPin] 예외 발생: $e');

      // 네트워크 오류 확인
      if (e.toString().toLowerCase().contains('connection') ||
          e.toString().toLowerCase().contains('network') ||
          e.toString().toLowerCase().contains('socket') ||
          e.toString().toLowerCase().contains('timeout')) {
        return {'success': false, 'message': '네트워크 연결을 확인해주세요.'};
      }

      return {'success': false, 'message': 'PIN 검증 중 오류가 발생했습니다.'};
    }
  }

  static Future<Map<String, String>> getHeaders() async {
    final accessToken = await getAccessToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $accessToken',
    };
  }

  // 저장된 토큰 가져오기
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // 학교 정보 저장 API
  static Future<Map<String, dynamic>> saveSchoolInfo({
    required String schoolName,
    required String schoolType,
    required int region,
    required String address,
  }) async {
    if (baseUrl.isEmpty) {
      throw Exception('API_BASE_URL가 설정되지 않았습니다. .env 파일을 확인하세요.');
    }

    String? accessToken = await getAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('인증이 필요합니다. 로그인을 다시 시도해주세요.');
    }

    final url = Uri.parse('$baseUrl/api-user/user/school/my');
    final body = {
      'schoolName': schoolName,
      'schoolType': schoolType,
      'region': region,
      'address': address,
    };

    print(
      '[AuthService.saveSchoolInfo] ============ 학교 정보 저장 요청 ============',
    );
    print('요청 URL: $url');
    print('전송할 데이터: ${jsonEncode(body)}');
    print('액세스 토큰: ${accessToken.substring(0, 20)}...');
    print('================================================================');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(body),
      );

      print('[AuthService.saveSchoolInfo] ============ 서버 응답 ============');
      print('응답 상태 코드: ${response.statusCode}');
      print('응답 헤더: ${response.headers}');
      print('응답 본문: ${response.body}');
      print('=========================================================');

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        final responseData = jsonDecode(decodedBody);
        
        print('[AuthService.saveSchoolInfo] 학교 정보 저장 성공:');
        print('- 학교명: ${responseData['schoolName']}');
        print('- 학교 유형: ${responseData['schoolType']}');
        print('- 지역: ${responseData['region']}');
        print('- 주소: ${responseData['address']}');
        
        return responseData;
      } else {
        // 에러 응답 상세 처리
        try {
          final errorBody = jsonDecode(response.body);
          print('[AuthService.saveSchoolInfo] 에러 상세: $errorBody');
          throw Exception(
            '학교 정보 저장 실패: ${response.statusCode} - ${errorBody['message'] ?? errorBody.toString()}',
          );
        } catch (e) {
          print('[AuthService.saveSchoolInfo] 에러 응답 파싱 실패: $e');
          throw Exception('학교 정보 저장 실패: ${response.statusCode}');
        }
      }
    } catch (e) {
      print('[AuthService.saveSchoolInfo] 예외 발생: $e');
      throw Exception('학교 정보 저장 중 네트워크 오류: $e');
    }
  }

  // 학교 정보 저장 API
  static Future<Map<String, dynamic>> updateSchoolInfo({
    required String schoolName,
    String? schoolGubun,
    String? schoolType,
    String? region,
    String? address,
    String? estType,
  }) async {
    if (baseUrl.isEmpty) {
      throw Exception('API_BASE_URL가 설정되지 않았습니다. .env 파일을 확인하세요.');
    }

    String? accessToken = await getAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('인증이 필요합니다. 로그인을 다시 시도해주세요.');
    }

    final url = Uri.parse('$baseUrl/api-user/user/school-info');
    final body = <String, dynamic>{'schoolName': schoolName};

    // 선택적 필드들 추가
    if (schoolGubun != null && schoolGubun.isNotEmpty) {
      body['schoolGubun'] = schoolGubun;
    }
    if (schoolType != null && schoolType.isNotEmpty) {
      body['schoolType'] = schoolType;
    }
    if (region != null && region.isNotEmpty) {
      body['region'] = region;
    }
    if (address != null && address.isNotEmpty) {
      body['address'] = address;
    }
    if (estType != null && estType.isNotEmpty) {
      body['estType'] = estType;
    }

    print(
      '[AuthService.updateSchoolInfo] ============ 학교 정보 저장 요청 ============',
    );
    print('요청 URL: $url');
    print('전송할 데이터: ${jsonEncode(body)}');
    print('액세스 토큰: ${accessToken.substring(0, 20)}...');
    print('================================================================');

    try {
      final response = await http.patch(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(body),
      );

      print('[AuthService.updateSchoolInfo] ============ 서버 응답 ============');
      print('응답 상태 코드: ${response.statusCode}');
      print('응답 헤더: ${response.headers}');
      print('응답 본문: ${response.body}');
      print('=========================================================');

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        return jsonDecode(decodedBody);
      } else {
        // 에러 응답 상세 처리
        try {
          final errorBody = jsonDecode(response.body);
          print('[AuthService.updateSchoolInfo] 에러 상세: $errorBody');
          throw Exception(
            '학교 정보 저장 실패: ${response.statusCode} - ${errorBody['message'] ?? errorBody.toString()}',
          );
        } catch (e) {
          print('[AuthService.updateSchoolInfo] 에러 응답 파싱 실패: $e');
          throw Exception('학교 정보 저장 실패: ${response.statusCode}');
        }
      }
    } catch (e) {
      print('[AuthService.updateSchoolInfo] 예외 발생: $e');
      throw Exception('학교 정보 저장 중 네트워크 오류: $e');
    }
  }

  // 학교별 유저 조회 API
  static Future<List<Map<String, dynamic>>> getSameSchoolStudents({
    int page = 0,
    int size = 20,
  }) async {
    if (baseUrl.isEmpty) {
      throw Exception('API_BASE_URL가 설정되지 않았습니다. .env 파일을 확인하세요.');
    }

    String? accessToken = await getAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('인증이 필요합니다. 로그인을 다시 시도해주세요.');
    }

    try {
      print('[AuthService.getSameSchoolStudents] ============ 같은 학교 학생 조회 시작 ============');
      
      // 1. 먼저 현재 사용자 정보를 가져와서 학교명 확인
      final currentUser = await getUserInfo();
      if (currentUser == null) {
        print('[AuthService.getSameSchoolStudents] 현재 사용자 정보를 가져올 수 없습니다.');
        return [];
      }

      final mySchoolName = currentUser['schoolName']?.toString();
      if (mySchoolName == null || mySchoolName.isEmpty) {
        print('[AuthService.getSameSchoolStudents] 현재 사용자의 학교 정보가 없습니다.');
        return [];
      }

      print('[AuthService.getSameSchoolStudents] 내 학교명: $mySchoolName');

      // 2. 새로운 학교별 유저 조회 API 사용
      final url = Uri.parse('$baseUrl/api-user/user/get-schoolUser?schoolName=${Uri.encodeComponent(mySchoolName)}');
      
      print('[AuthService.getSameSchoolStudents] 요청 URL: $url');
      
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Accept': 'application/json; charset=utf-8',
          'Content-Type': 'application/json; charset=utf-8',
        },
      );

      print('[AuthService.getSameSchoolStudents] 응답 상태 코드: ${response.statusCode}');
      print('[AuthService.getSameSchoolStudents] 응답 본문: ${response.body}');

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        final responseData = jsonDecode(decodedBody);
        
        List<Map<String, dynamic>> sameSchoolStudents = [];
        
        if (responseData is List) {
          for (var userData in responseData) {
            // 본인 제외
            if (userData['userId'] != currentUser['userId']) {
              sameSchoolStudents.add({
                'userId': userData['userId'],
                'name': userData['realName'] ?? '',
                'realName': userData['realName'] ?? '',
                'profileImagePath': userData['profileImagePath'],
                'schoolName': userData['schoolName'],
                'schoolType': userData['schoolType'],
                'statusMessage': userData['statusMessage'],
                'role': userData['role'],
                'region': userData['region'],
                'address': userData['address'],
                'isFriend': false, // 친구 여부는 별도로 체크 필요
              });
            }
          }
        }
        
        print('[AuthService.getSameSchoolStudents] 같은 학교 학생 ${sameSchoolStudents.length}명 발견');
        
        // 페이징 처리 (클라이언트 사이드)
        final startIndex = page * size;
        final endIndex = startIndex + size;
        final paginatedStudents = sameSchoolStudents.sublist(
          startIndex,
          endIndex > sameSchoolStudents.length ? sameSchoolStudents.length : endIndex,
        );
        
        return paginatedStudents;
      } else {
        print('[AuthService.getSameSchoolStudents] 학교별 유저 조회 API 호출 실패: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('[AuthService.getSameSchoolStudents] 예외 발생: $e');
      return [];
    }
  }

  // SMS 인증번호 발송 API
  static Future<Map<String, dynamic>> sendSmsVerificationCode({
    required String phoneNumber,
  }) async {
    if (baseUrl.isEmpty) {
      throw Exception('API_BASE_URL가 설정되지 않았습니다. .env 파일을 확인하세요.');
    }

    final url = Uri.parse('$baseUrl/api-user/sms/public/certification-code/send');

    // 요청 바디 구성 - 하이픈 제거한 전화번호
    final Map<String, dynamic> body = {
      'toNumber': phoneNumber.replaceAll('-', ''),
    };

    print('[AuthService.sendSmsVerificationCode] ============ SMS 인증번호 발송 요청 ============');
    print('요청 URL: $url');
    print('전화번호: ${body['toNumber']}');
    print('요청 바디: ${jsonEncode(body)}');
    print('=================================================================');

    try {
      // POST 요청 보내기 (public API이므로 토큰 불필요)
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
      );

      print('[AuthService.sendSmsVerificationCode] ============ 서버 응답 ============');
      print('응답 상태 코드: ${response.statusCode}');
      print('응답 헤더: ${response.headers}');
      print('응답 본문: ${response.body}');
      print('=====================================================');

      if (response.statusCode == 200) {
        // 응답이 JSON인지 체크하고 처리
        try {
          final responseData = jsonDecode(response.body);
          return {
            'success': true,
            'message': responseData['message'] ?? '인증번호가 발송되었습니다.',
            'data': responseData,
          };
        } catch (e) {
          // JSON 파싱 실패시 (서버가 단순 문자열 응답을 보낸 경우)
          print('[AuthService.sendSmsVerificationCode] JSON 파싱 실패, 문자열 응답 처리: ${response.body}');
          return {
            'success': true,
            'message': response.body.contains('완료') ? '인증번호가 발송되었습니다.' : response.body,
            'data': {'message': response.body},
          };
        }
      } else {
        // 에러 응답 처리
        try {
          final errorBody = jsonDecode(response.body);
          final errorMessage = errorBody['message'] ?? 'SMS 발송에 실패했습니다.';
          return {
            'success': false,
            'message': errorMessage,
          };
        } catch (e) {
          // JSON 파싱 실패시 응답 본문 그대로 사용
          return {
            'success': false,
            'message': response.body.isNotEmpty ? response.body : 'SMS 발송 실패: ${response.statusCode}',
          };
        }
      }
    } catch (e) {
      print('[AuthService.sendSmsVerificationCode] 예외 발생: $e');

      // 네트워크 오류 확인
      if (e.toString().toLowerCase().contains('connection') ||
          e.toString().toLowerCase().contains('network') ||
          e.toString().toLowerCase().contains('socket') ||
          e.toString().toLowerCase().contains('timeout')) {
        return {'success': false, 'message': '네트워크 연결을 확인해주세요.'};
      }

      return {'success': false, 'message': 'SMS 발송 중 오류가 발생했습니다.'};
    }
  }

  // SMS 인증번호 검증 API
  static Future<Map<String, dynamic>> verifySmsCode({
    required String phoneNumber,
    required String code,
  }) async {
    if (baseUrl.isEmpty) {
      throw Exception('API_BASE_URL가 설정되지 않았습니다. .env 파일을 확인하세요.');
    }

    final url = Uri.parse('$baseUrl/api-user/auth/public/certification-code/verify');

    // 요청 바디 구성 - 하이픈 제거한 전화번호
    final Map<String, dynamic> body = {
      'toNumber': phoneNumber.replaceAll('-', ''),
      'code': code,
    };

    print('[AuthService.verifySmsCode] ============ SMS 인증번호 검증 요청 ============');
    print('요청 URL: $url');
    print('전화번호: ${body['toNumber']}');
    print('인증번호: ${body['code']}');
    print('요청 바디: ${jsonEncode(body)}');
    print('=================================================================');

    try {
      // POST 요청 보내기 (public API이므로 토큰 불필요)
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
      );

      print('[AuthService.verifySmsCode] ============ 서버 응답 ============');
      print('응답 상태 코드: ${response.statusCode}');
      print('응답 헤더: ${response.headers}');
      print('응답 본문: ${response.body}');
      print('====================================================');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'message': responseData['message'] ?? '인증코드가 일치합니다.',
          'data': responseData,
        };
      } else if (response.statusCode == 400) {
        // 인증번호 불일치
        try {
          final errorBody = jsonDecode(response.body);
          final errorMessage = errorBody['message'] ?? '인증코드가 일치하지 않습니다.';
          return {
            'success': false,
            'message': errorMessage,
          };
        } catch (e) {
          return {
            'success': false,
            'message': '인증코드가 일치하지 않습니다.',
          };
        }
      } else {
        // 기타 에러 응답 처리
        try {
          final errorBody = jsonDecode(response.body);
          final errorMessage = errorBody['message'] ?? 'SMS 인증에 실패했습니다.';
          return {
            'success': false,
            'message': errorMessage,
          };
        } catch (e) {
          return {
            'success': false,
            'message': 'SMS 인증 실패: ${response.statusCode}',
          };
        }
      }
    } catch (e) {
      print('[AuthService.verifySmsCode] 예외 발생: $e');

      // 네트워크 오류 확인
      if (e.toString().toLowerCase().contains('connection') ||
          e.toString().toLowerCase().contains('network') ||
          e.toString().toLowerCase().contains('socket') ||
          e.toString().toLowerCase().contains('timeout')) {
        return {'success': false, 'message': '네트워크 연결을 확인해주세요.'};
      }

      return {'success': false, 'message': 'SMS 인증 중 오류가 발생했습니다.'};
    }
  }

  // 임시 비밀번호 발급 API
  static Future<Map<String, dynamic>> requestTemporaryPassword({
    required String email,
  }) async {
    if (baseUrl.isEmpty) {
      throw Exception('API_BASE_URL가 설정되지 않았습니다. .env 파일을 확인하세요.');
    }

    final url = Uri.parse('$baseUrl/api-user/user/public/password/reissue');

    // 요청 바디 구성
    final Map<String, dynamic> body = {
      'email': email.trim(),
    };

    print('[AuthService.requestTemporaryPassword] ============ 임시 비밀번호 발급 요청 ============');
    print('요청 URL: $url');
    print('이메일: ${body['email']}');
    print('요청 바디: ${jsonEncode(body)}');
    print('================================================================');

    try {
      // POST 요청 보내기 (public API이므로 토큰 불필요)
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
      );

      print('[AuthService.requestTemporaryPassword] ============ 서버 응답 ============');
      print('응답 상태 코드: ${response.statusCode}');
      print('응답 헤더: ${response.headers}');
      print('응답 본문: ${response.body}');
      print('==================================================');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'message': '임시 비밀번호가 이메일로 발송되었습니다.',
          'email': responseData['email'] ?? email,
        };
      } else if (response.statusCode == 404) {
        // 사용자 없음
        return {
          'success': false,
          'message': '입력한 이메일에 해당하는 계정이 존재하지 않습니다.',
        };
      } else {
        // 기타 에러 응답 처리
        try {
          final errorBody = jsonDecode(response.body);
          final errorMessage = errorBody['message'] ?? '임시 비밀번호 발급에 실패했습니다.';
          return {
            'success': false,
            'message': errorMessage,
          };
        } catch (e) {
          return {
            'success': false,
            'message': '임시 비밀번호 발급 실패: ${response.statusCode}',
          };
        }
      }
    } catch (e) {
      print('[AuthService.requestTemporaryPassword] 예외 발생: $e');

      // 네트워크 오류 확인
      if (e.toString().toLowerCase().contains('connection') ||
          e.toString().toLowerCase().contains('network') ||
          e.toString().toLowerCase().contains('socket') ||
          e.toString().toLowerCase().contains('timeout')) {
        return {'success': false, 'message': '네트워크 연결을 확인해주세요.'};
      }

      return {'success': false, 'message': '임시 비밀번호 발급 중 오류가 발생했습니다.'};
    }
  }

  // 비밀번호 재설정 API
  static Future<Map<String, dynamic>> resetPassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (baseUrl.isEmpty) {
      throw Exception('API_BASE_URL가 설정되지 않았습니다. .env 파일을 확인하세요.');
    }

    // 액세스 토큰 가져오기 (인증 필요한 API)
    String? accessToken = await getAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      return {'success': false, 'message': '인증이 필요합니다. 로그인 후 다시 시도해주세요.'};
    }

    final url = Uri.parse('$baseUrl/api-user/user/password/reset');

    // 요청 바디 구성
    final Map<String, dynamic> body = {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    };

    print('[AuthService.resetPassword] ============ 비밀번호 재설정 요청 ============');
    print('요청 URL: $url');
    print('요청 바디: ${jsonEncode(body)}');
    print('액세스 토큰: ${accessToken.substring(0, 20)}...');
    print('================================================================');

    try {
      // PATCH 요청 보내기
      final response = await http.patch(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
      );

      print('[AuthService.resetPassword] ============ 서버 응답 ============');
      print('응답 상태 코드: ${response.statusCode}');
      print('응답 헤더: ${response.headers}');
      print('응답 본문: ${response.body}');
      print('===============================================');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'message': responseData['message'] ?? '비밀번호를 재설정 하였습니다.',
          'code': responseData['code'] ?? 200,
        };
      } else if (response.statusCode == 400) {
        // 현재 비밀번호 불일치
        try {
          final errorBody = jsonDecode(response.body);
          final errorMessage = errorBody['message'] ?? '패스워드가 일치하지 않습니다.';
          return {
            'success': false,
            'message': errorMessage,
          };
        } catch (e) {
          return {
            'success': false,
            'message': '현재 비밀번호가 일치하지 않습니다.',
          };
        }
      } else if (response.statusCode == 401) {
        // 인증 오류 - 토큰 재발급 시도
        final newAccessToken = await reissueAccessToken();
        if (newAccessToken != null) {
          // 새 토큰으로 재시도
          final retryResponse = await http.patch(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $newAccessToken',
              'Accept': 'application/json',
            },
            body: jsonEncode(body),
          );

          if (retryResponse.statusCode == 200) {
            final responseData = jsonDecode(retryResponse.body);
            return {
              'success': true,
              'message': responseData['message'] ?? '비밀번호를 재설정 하였습니다.',
              'code': responseData['code'] ?? 200,
            };
          }
        }
        
        // 토큰 재발급 실패 또는 재시도 실패
        await clearAllAuthData();
        return {'success': false, 'message': '세션이 만료되었습니다. 다시 로그인해주세요.'};
      } else {
        // 기타 에러 응답 처리
        try {
          final errorBody = jsonDecode(response.body);
          final errorMessage = errorBody['message'] ?? '비밀번호 재설정에 실패했습니다.';
          return {
            'success': false,
            'message': errorMessage,
          };
        } catch (e) {
          return {
            'success': false,
            'message': '비밀번호 재설정 실패: ${response.statusCode}',
          };
        }
      }
    } catch (e) {
      print('[AuthService.resetPassword] 예외 발생: $e');

      // 네트워크 오류 확인
      if (e.toString().toLowerCase().contains('connection') ||
          e.toString().toLowerCase().contains('network') ||
          e.toString().toLowerCase().contains('socket') ||
          e.toString().toLowerCase().contains('timeout')) {
        return {'success': false, 'message': '네트워크 연결을 확인해주세요.'};
      }

      return {'success': false, 'message': '비밀번호 재설정 중 오류가 발생했습니다.'};
    }
  }

  // 상태 메시지 업데이트 API
  static Future<Map<String, dynamic>> updateStatusMessage({
    required String statusMessage,
  }) async {
    if (baseUrl.isEmpty) {
      throw Exception('API_BASE_URL가 설정되지 않았습니다. .env 파일을 확인하세요.');
    }

    String? accessToken = await getAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('인증이 필요합니다. 로그인을 다시 시도해주세요.');
    }

    final url = Uri.parse('$baseUrl/api-user/user/status-message');
    final body = {'statusMessage': statusMessage};

    print(
      '[AuthService.updateStatusMessage] ============ 상태 메시지 업데이트 요청 ============',
    );
    print('요청 URL: $url');
    print('전송할 데이터: ${jsonEncode(body)}');
    print('액세스 토큰: ${accessToken.substring(0, 20)}...');
    print('================================================================');

    try {
      final response = await http.patch(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(body),
      );

      print(
        '[AuthService.updateStatusMessage] ============ 서버 응답 ============',
      );
      print('응답 상태 코드: ${response.statusCode}');
      print('응답 헤더: ${response.headers}');
      print('응답 본문: ${response.body}');
      print('=======================================================');

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        return jsonDecode(decodedBody);
      } else if (response.statusCode == 401) {
        // 토큰 만료 확인 - 리프레시 토큰으로 액세스 토큰 재발급 시도
        final newAccessToken = await reissueAccessToken();

        if (newAccessToken != null) {
          // 새 액세스 토큰으로 요청 재시도
          final retryResponse = await http.patch(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $newAccessToken',
            },
            body: jsonEncode(body),
          );

          if (retryResponse.statusCode == 200) {
            final decodedBody = utf8.decode(retryResponse.bodyBytes);
            return jsonDecode(decodedBody);
          } else {
            throw Exception(
              '상태 메시지 업데이트 재시도 실패: ${retryResponse.statusCode}',
            );
          }
        } else {
          // 모든 인증 데이터 삭제
          await clearAllAuthData();
          throw Exception('세션이 만료되었습니다. 다시 로그인해주세요.');
        }
      } else {
        // 에러 응답 상세 처리
        try {
          final errorBody = jsonDecode(response.body);
          print('[AuthService.updateStatusMessage] 에러 상세: $errorBody');
          throw Exception(
            '상태 메시지 업데이트 실패: ${response.statusCode} - ${errorBody['message'] ?? errorBody.toString()}',
          );
        } catch (e) {
          print('[AuthService.updateStatusMessage] 에러 응답 파싱 실패: $e');
          throw Exception('상태 메시지 업데이트 실패: ${response.statusCode}');
        }
      }
    } catch (e) {
      print('[AuthService.updateStatusMessage] 예외 발생: $e');
      throw Exception('상태 메시지 업데이트 중 네트워크 오류: $e');
    }
  }
}
