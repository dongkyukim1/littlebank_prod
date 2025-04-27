import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'auth_service.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:logging/logging.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';

class SNSService {
  static final Logger _logger = Logger('SNSService');

  // API 기본 URL
  static String get baseUrl => dotenv.env['API_BASE_URL'] ?? '';
  static String get kakaoRestApiKey => dotenv.env['KAKAO_REST_API_KEY'] ?? '';
  static const storage = FlutterSecureStorage();

  // 개발 환경에서만 로그를 출력하는 유틸리티 함수
  static void _log(String message) {
    if (kDebugMode) {
      _logger.info(message);
    }
  }

  // 카카오 로그인 API
  static Future<Map<String, dynamic>> loginWithKakao(String accessToken) async {
    if (baseUrl.isEmpty) {
      throw Exception('API_BASE_URL가 설정되지 않았습니다. .env 파일을 확인하세요.');
    }

    // 소셜 타입 저장
    await AuthService.setSocialType('KAKAO');

    final url = Uri.parse('$baseUrl/api-user/auth/public/kakao/login');

    // 요청 바디 생성
    final Map<String, dynamic> body = {'accessToken': accessToken};

    _log('카카오 로그인 API 요청 URL: $url');
    _log('카카오 로그인 API 요청 바디: ${jsonEncode(body)}');

    try {
      // POST 요청 보내기
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      // 응답 로깅
      _log('카카오 로그인 API 응답 상태 코드: ${response.statusCode}');
      _log('카카오 로그인 API 응답 헤더: ${response.headers}');
      _log('카카오 로그인 API 응답 바디: ${response.body}');

      // 응답 확인
      if (response.statusCode == 200) {
        // 리프레시 토큰을 응답 헤더에서 추출
        String? refreshToken;
        if (response.headers.containsKey('refresh-token')) {
          refreshToken = response.headers['refresh-token'];
        } else if (response.headers.containsKey('Refresh-Token')) {
          refreshToken = response.headers['Refresh-Token'];
        } else {
          // 헤더 키 대소문자 무시하고 검색
          refreshToken =
              response.headers.entries
                  .firstWhere(
                    (entry) => entry.key.toLowerCase() == 'refresh-token',
                    orElse: () => const MapEntry<String, String>('', ''),
                  )
                  .value;
        }

        if (refreshToken != null && refreshToken.isNotEmpty) {
          // 리프레시 토큰을 안전하게 저장
          await storage.write(key: 'refresh_token', value: refreshToken);

          // 안전하게 토큰의 일부만 로그로 출력
          final truncatedToken =
              refreshToken.length > 10
                  ? refreshToken.substring(0, 10)
                  : refreshToken;

          _log('리프레시 토큰이 저장되었습니다: $truncatedToken...');
        } else {
          _log('경고: 리프레시 토큰이 응답에 없습니다');
        }

        // 응답 본문 디코딩
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        _log('카카오 로그인 응답 데이터: $responseData');

        // 액세스 토큰 찾기 (다양한 키 이름 시도)
        String? jwtToken;
        if (responseData.containsKey('accessToken')) {
          jwtToken = responseData['accessToken'];
        } else if (responseData.containsKey('access_token')) {
          jwtToken = responseData['access_token'];
        } else if (responseData.containsKey('token')) {
          jwtToken = responseData['token'];
        } else if (responseData.containsKey('data') &&
            responseData['data'] is Map) {
          final dataMap = responseData['data'] as Map<String, dynamic>;
          if (dataMap.containsKey('accessToken')) {
            jwtToken = dataMap['accessToken'];
          } else if (dataMap.containsKey('access_token')) {
            jwtToken = dataMap['access_token'];
          } else if (dataMap.containsKey('token')) {
            jwtToken = dataMap['token'];
          }
        }

        if (jwtToken != null && jwtToken.isNotEmpty) {
          // 액세스 토큰 저장
          await storage.write(key: 'access_token', value: jwtToken);

          // 안전하게 토큰의 일부만 로그로 출력
          final truncatedToken =
              jwtToken.length > 10 ? jwtToken.substring(0, 10) : jwtToken;

          _log('액세스 토큰이 저장되었습니다: $truncatedToken...');
        } else {
          _log('경고: 액세스 토큰이 응답에 없습니다');
        }

        // 추가 정보 설정 필요한지 확인
        bool needsAdditionalInfo = false;

        try {
          // 사용자 정보 조회
          final userInfo = await AuthService.getUserInfo();

          // 중요: userInfo에서 역할 정보 확인 (null이 아닌지)
          _log('사용자 정보: ${userInfo.toString()}');

          // role 값이 존재하고 비어있지 않으면 추가 정보 입력 불필요
          needsAdditionalInfo =
              userInfo['role'] == null || userInfo['role'].toString().isEmpty;

          _log(
            '추가 정보 설정 필요 여부: $needsAdditionalInfo (userId=${userInfo['userId']}, role=${userInfo['role']})',
          );
        } catch (e) {
          _log('사용자 정보 조회 실패: $e');
          // 오류 발생시 추가 정보 필요하다고 가정
          needsAdditionalInfo = true;
        }

        // 응답에 추가 정보 설정 필요 여부 추가
        responseData['needsAdditionalInfo'] = needsAdditionalInfo;

        return responseData;
      } else if (response.statusCode == 500 && response.body.contains('C004')) {
        // C004 에러 발생 시 회원가입 API 직접 호출 시도
        _log('서버 오류 C004 발생 - 카카오 계정으로 회원가입 시도');
        
        // 카카오 계정 정보 가져오기
        User user = await UserApi.instance.me();
        
        // 네이버 로직처럼 회원가입 시도
        return await _signupWithKakao(
          user: user,
          accessToken: accessToken,
        );
      } else if (response.statusCode == 401) {
        throw Exception('인증에 실패했습니다. 유효하지 않은 카카오 토큰입니다.');
      } else {
        // 기타 오류
        try {
          final errorBody = jsonDecode(response.body);
          final errorMessage =
              errorBody['message'] ?? errorBody['error'] ?? '카카오 로그인에 실패했습니다.';
          throw Exception('카카오 로그인 실패: $errorMessage');
        } catch (e) {
          throw Exception(
            '카카오 로그인 실패: ${response.statusCode}, ${response.body}',
          );
        }
      }
    } catch (e) {
      _log('카카오 로그인 API 호출 예외: $e');

      // 네트워크 오류인지 확인
      if (e.toString().toLowerCase().contains('connection') ||
          e.toString().toLowerCase().contains('network') ||
          e.toString().toLowerCase().contains('socket')) {
        throw Exception('네트워크 연결을 확인해주세요.');
      }

      // 마지막 대안으로 회원가입 시도
      try {
        User user = await UserApi.instance.me();
        return await _signupWithKakao(
          user: user,
          accessToken: accessToken,
        );
      } catch (signupError) {
        _log('카카오 회원가입 시도 실패: $signupError');
        throw Exception(e.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  // 카카오 계정으로 회원가입 메서드 추가 (네이버 _signupWithNaver 참고)
  static Future<Map<String, dynamic>> _signupWithKakao({
    required User user,
    required String accessToken,
  }) async {
    final url = Uri.parse('$baseUrl/api-user/user/public/signup');
    
    // 회원가입 요청 바디
    final Map<String, dynamic> body = {
      'email': user.kakaoAccount?.email ?? 'kakao${user.id}@example.com',
      'password': 'KAKAO_LOGIN_${user.id}',
      'name': user.kakaoAccount?.profile?.nickname ?? '카카오 사용자',
      'phone': '01000000000', // 임시값
      'rrn': '2000-01-01', // 임시값, 추후 수정 필요
      'role': 'CHILD', // 기본 역할, 추후 변경 가능
      'socialType': 'KAKAO',
      'socialId': user.id.toString(),
    };
    
    _log('카카오 회원가입 API 요청 URL: $url');
    _log('카카오 회원가입 API 요청 바디: ${jsonEncode(body)}');
    
    try {
      // POST 요청 - 회원가입 API
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Accept': 'application/json; charset=utf-8',
        },
        body: jsonEncode(body),
      );
      
      _log('카카오 회원가입 API 응답 상태 코드: ${response.statusCode}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        // 성공
        final decodedBody = utf8.decode(response.bodyBytes);
        final result = jsonDecode(decodedBody);
        
        _log('카카오 회원가입 API 성공: $result');
        
        // 액세스 토큰이 있으면 저장
        if (result.containsKey('accessToken') && result['accessToken'] != null) {
          await storage.write(key: 'access_token', value: result['accessToken']);
        }
        
        // 현재 토큰이 만료될 수 있으므로 사용자 정보를 다시 조회
        try {
          final updatedUserInfo = await AuthService.getUserInfo();
          _log('정보 업데이트 후 사용자 정보: $updatedUserInfo');
          return updatedUserInfo;
        } catch (e) {
          _log('사용자 정보 조회 실패, 회원가입 결과 반환: $e');
          return {'role': 'CHILD', ...result};
        }
      } else if (response.statusCode == 400) {
        // 이미 가입된 이메일 등의 오류 - 로그인 시도
        final errorBody = utf8.decode(response.bodyBytes);
        _log('카카오 회원가입 API 오류 (400): $errorBody');
        
        // 기존 사용자로 간주하고 처리
        return {
          'role': 'CHILD',
          'needsAdditionalInfo': true
        };
      } else {
        // 기타 오류
        final errorBody = utf8.decode(response.bodyBytes);
        _log('카카오 회원가입 API 오류: ${response.statusCode}, $errorBody');
        throw Exception('카카오 회원가입 실패: ${response.statusCode}');
      }
    } catch (e) {
      _log('카카오 회원가입 API 호출 예외: $e');
      
      // 마지막 대안: 임시 응답 반환
      return {
        'role': 'CHILD',
        'needsAdditionalInfo': true
      };
    }
  }

  // 카카오 사용자 정보 설정 (생년월일, 역할 등)
  static Future<Map<String, dynamic>> setKakaoUserInfo({
    required String birthdate,
    required String role,
    String? name,
    String? phone,
    String? bankName,
    String? bankAccount,
    String? bankCode,
  }) async {
    if (baseUrl.isEmpty) {
      throw Exception('API_BASE_URL가 설정되지 않았습니다. .env 파일을 확인하세요.');
    }

    // 액세스 토큰 가져오기 (인증 필요한 API)
    String? accessToken = await AuthService.getAccessToken();

    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('인증이 필요합니다. 로그인 후 다시 시도해주세요.');
    }

    // 디버깅: 토큰 값 출력
    if (accessToken.length > 10) {
      _log('사용 중인 액세스 토큰: ${accessToken.substring(0, 10)}...');
    }

    // 카카오 사용자 정보 가져오기
    User user;
    try {
      user = await UserApi.instance.me();
      _log(
        '카카오 사용자 정보: ID=${user.id}, 이메일=${user.kakaoAccount?.email}, 닉네임=${user.kakaoAccount?.profile?.nickname}',
      );
    } catch (e) {
      _log('카카오 사용자 정보 요청 실패: $e');
      throw Exception('카카오 계정 정보를 가져오는데 실패했습니다.');
    }

    // 첫 단계: 현재 사용자 상태 확인 (이미 존재하는지, 역할이 설정되어 있는지)
    try {
      final userInfo = await AuthService.getUserInfo();
      
      // 사용자 정보에 role이 이미 있다면
      if (userInfo.containsKey('role') && 
          userInfo['role'] != null && 
          userInfo['role'].toString().isNotEmpty) {
        
        _log('사용자 역할이 이미 설정되어 있습니다: ${userInfo['role']}');
        
        // 추가적인 정보 업데이트가 필요한 경우에만 처리
        if ((phone != null && phone.isNotEmpty) || 
            (bankName != null && bankName.isNotEmpty) || 
            (bankAccount != null && bankAccount.isNotEmpty) || 
            (bankCode != null && bankCode.isNotEmpty)) {
          
          try {
            await _updateAdditionalUserInfo(
              accessToken: accessToken,
              phone: phone,
              bankName: bankName,
              bankAccount: bankAccount,
              bankCode: bankCode,
            );
          } catch (e) {
            _log('추가 정보 업데이트 실패 (무시됨): $e');
          }
        }
        
        // 이미 완료된 사용자이므로 그냥 기존 정보 반환
        return userInfo;
      }
      
      _log('사용자 존재하지만 역할 설정이 필요합니다.');
    } catch (e) {
      _log('사용자 정보 확인 중 오류 (신규 사용자로 간주): $e');
    }

    // 액세스 토큰 유효성 확인
    try {
      bool isTokenValid = await _checkTokenValidity(accessToken);
      if (!isTokenValid) {
        throw Exception('액세스 토큰이 유효하지 않습니다.');
      }
    } catch (e) {
      _log('토큰 검증 실패: $e');
      throw Exception('인증 세션이 만료되었습니다. 다시 로그인해주세요.');
    }

    // 우회 방법: 회원가입 API 바로 사용
    _log('소셜 로그인 추가 정보 API 대신 회원가입 API 사용 시도');
    
    // 회원가입 API URL
    final url = Uri.parse('$baseUrl/api-user/user/public/signup');
    
    // 필수 필드 설정
    final Map<String, dynamic> body = {
      'email': user.kakaoAccount?.email ?? 'kakao${user.id}@example.com',
      'password': 'KAKAO_LOGIN_${user.id}', // 소셜 로그인용 특수 패스워드
      'name': name ?? user.kakaoAccount?.profile?.nickname ?? '사용자',
      'phone': phone ?? '',
      'rrn': birthdate,
      'role': role,
      'socialType': 'KAKAO', // 소셜 로그인 타입 표시
      'socialId': user.id.toString(), // 카카오 계정 ID
    };
    
    // 선택적 필드 추가
    if (bankName != null && bankName.isNotEmpty) body['bankName'] = bankName;
    if (bankAccount != null && bankAccount.isNotEmpty) body['bankAccount'] = bankAccount;
    if (bankCode != null && bankCode.isNotEmpty) body['bankCode'] = bankCode;
    
    _log('회원가입 API 요청 URL: $url');
    _log('회원가입 API 요청 바디: ${jsonEncode(body)}');
    
    try {
      // POST 요청 - 회원가입 API
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Accept': 'application/json; charset=utf-8',
        },
        body: jsonEncode(body),
      );
      
      _log('회원가입 API 응답 상태 코드: ${response.statusCode}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        // 성공
        final decodedBody = utf8.decode(response.bodyBytes);
        final result = jsonDecode(decodedBody);
        
        _log('회원가입 API 성공: $result');
        
        // 현재 토큰이 만료될 수 있으므로 사용자 정보를 다시 조회
        try {
          final updatedUserInfo = await AuthService.getUserInfo();
          _log('정보 업데이트 후 사용자 정보: $updatedUserInfo');
          return updatedUserInfo;
        } catch (e) {
          _log('사용자 정보 조회 실패, 회원가입 결과 반환: $e');
          return result;
        }
      } else if (response.statusCode == 400) {
        // 이미 가입된 이메일 등의 오류
        final errorBody = utf8.decode(response.bodyBytes);
        _log('회원가입 API 오류 (400): $errorBody');
        
        // PUT 방식으로 정보 업데이트 시도
        return _updateExistingUser(
          accessToken: accessToken,
          user: user,
          birthdate: birthdate,
          role: role,
          name: name,
          phone: phone,
          bankName: bankName,
          bankAccount: bankAccount,
          bankCode: bankCode,
        );
      } else {
        // 기타 오류
        final errorBody = utf8.decode(response.bodyBytes);
        _log('회원가입 API 오류: ${response.statusCode}, $errorBody');
        throw Exception('회원가입 또는 정보 업데이트 실패: ${response.statusCode}');
      }
    } catch (e) {
      _log('회원가입 API 호출 예외: $e');
      
      // 마지막 시도: 이미 존재하는 사용자로 가정하고 정보 업데이트
      try {
        return _updateExistingUser(
          accessToken: accessToken,
          user: user,
          birthdate: birthdate,
          role: role,
          name: name,
          phone: phone,
          bankName: bankName,
          bankAccount: bankAccount,
          bankCode: bankCode,
        );
      } catch (updateError) {
        _log('정보 업데이트 실패: $updateError');
        throw Exception('카카오 로그인 사용자 정보 설정 실패: $e');
      }
    }
  }
  
  // 기존 사용자 정보 업데이트
  static Future<Map<String, dynamic>> _updateExistingUser({
    required String accessToken,
    required User user,
    required String birthdate,
    required String role,
    String? name,
    String? phone,
    String? bankName,
    String? bankAccount,
    String? bankCode,
  }) async {
    _log('기존 사용자 정보 업데이트 시도');
    
    final url = Uri.parse('$baseUrl/api-user/user/info');
    
    // 업데이트 요청 바디
    final Map<String, dynamic> body = {
      'rrn': birthdate,
      'role': role,
    };
    
    // 선택적 필드 추가
    if (name != null && name.isNotEmpty) {
      body['name'] = name;
    } else if (user.kakaoAccount?.profile?.nickname != null && user.kakaoAccount!.profile!.nickname!.isNotEmpty) {
      body['name'] = user.kakaoAccount!.profile!.nickname!;
    }
    
    if (user.kakaoAccount?.email != null && user.kakaoAccount!.email!.isNotEmpty) {
      body['email'] = user.kakaoAccount!.email!;
    }
    
    if (phone != null && phone.isNotEmpty) body['phone'] = phone;
    if (bankName != null && bankName.isNotEmpty) body['bankName'] = bankName;
    if (bankAccount != null && bankAccount.isNotEmpty) body['bankAccount'] = bankAccount;
    if (bankCode != null && bankCode.isNotEmpty) body['bankCode'] = bankCode;
    
    _log('사용자 정보 업데이트 API 요청 URL: $url');
    _log('사용자 정보 업데이트 API 요청 바디: ${jsonEncode(body)}');
    
    // PUT 요청 - 사용자 정보 업데이트
    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json; charset=utf-8',
        'Accept': 'application/json; charset=utf-8',
        'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode(body),
    );
    
    _log('사용자 정보 업데이트 API 응답 상태 코드: ${response.statusCode}');
    
    if (response.statusCode == 200) {
      final decodedBody = utf8.decode(response.bodyBytes);
      Map<String, dynamic> result = jsonDecode(decodedBody);
      
      // 역할이 설정되었는지 확인
      if (result['role'] == null || result['role'].toString().isEmpty) {
        _log('역할이 설정되지 않았습니다. 목업 데이터로 대체합니다.');
        // 서버에서 역할을 반환하지 않으면 요청한 값으로 대체
        result['role'] = role;
      }
      
      return result;
    } else {
      final errorBody = utf8.decode(response.bodyBytes);
      throw Exception('기존 사용자 정보 업데이트 실패: ${response.statusCode}, $errorBody');
    }
  }

  // 토큰 유효성 확인
  static Future<bool> _checkTokenValidity(String accessToken) async {
    try {
      // API 호출로 토큰 유효성 확인 (실제로는 사용자 정보 조회)
      await AuthService.getUserInfo();
      return true;
    } catch (e) {
      _log('토큰 유효성 검사 실패: $e');
      return false;
    }
  }

  // 추가 사용자 정보 업데이트 - 은행 정보, 전화번호 등
  static Future<void> _updateAdditionalUserInfo({
    required String accessToken,
    String? phone,
    String? bankName,
    String? bankAccount,
    String? bankCode,
  }) async {
    if (![phone, bankName, bankAccount, bankCode].any((field) => field != null && field.isNotEmpty)) {
      return; // 업데이트할 필드가 없음
    }

    final url = Uri.parse('$baseUrl/api-user/user/info');
    final additionalInfo = <String, dynamic>{};
    
    if (phone != null && phone.isNotEmpty) additionalInfo['phone'] = phone;
    if (bankName != null && bankName.isNotEmpty) additionalInfo['bankName'] = bankName;
    if (bankAccount != null && bankAccount.isNotEmpty) additionalInfo['bankAccount'] = bankAccount;
    if (bankCode != null && bankCode.isNotEmpty) additionalInfo['bankCode'] = bankCode;
    
    _log('추가 정보 업데이트 API 요청 URL: $url');
    _log('추가 정보 업데이트 API 요청 바디: ${jsonEncode(additionalInfo)}');
    
    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json; charset=utf-8',
        'Accept': 'application/json; charset=utf-8',
        'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode(additionalInfo),
    );
    
    _log('추가 정보 업데이트 API 응답 상태 코드: ${response.statusCode}');
    
    if (response.statusCode != 200) {
      throw Exception('추가 정보 업데이트 실패: ${response.statusCode}');
    }
  }

  // 최초 소셜 로그인 추가 정보 저장 API 호출
  static Future<Map<String, dynamic>> updateSocialAdditionalInfo({
    required String birthdate,
    required String role,
    String? phone,
    String? bankName,
    String? bankAccount,
    String? bankCode,
    String socialType = 'KAKAO', // 기본값은 카카오
  }) async {
    if (baseUrl.isEmpty) {
      throw Exception('API_BASE_URL가 설정되지 않았습니다. .env 파일을 확인하세요.');
    }

    // 소셜 타입 저장
    await AuthService.setSocialType(socialType);

    // 액세스 토큰 가져오기 (인증 필요한 API)
    String? accessToken = await AuthService.getAccessToken();

    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('인증이 필요합니다. 로그인 후 다시 시도해주세요.');
    }

    // 디버깅: 토큰 값 출력
    if (accessToken.length > 10) {
      _log('사용 중인 액세스 토큰: ${accessToken.substring(0, 10)}...');
    }

    final url = Uri.parse('$baseUrl/api-user/user/social/additional-info');
    
    // API 스펙에 맞게 요청 바디 구성
    final Map<String, dynamic> body = {
      'rrn': birthdate,
      'role': role,
    };
    
    // 전화번호가 있으면 추가
    if (phone != null && phone.isNotEmpty) {
      body['phone'] = phone;
    }
    
    _log('소셜 로그인 추가 정보 API 요청 URL: $url');
    _log('소셜 로그인 추가 정보 API 요청 바디: ${jsonEncode(body)}');
    
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
    
    _log('소셜 로그인 추가 정보 API 응답 상태 코드: ${response.statusCode}');
    
    if (response.statusCode == 200) {
      final decodedBody = utf8.decode(response.bodyBytes);
      Map<String, dynamic> result = jsonDecode(decodedBody);
      
      // 역할이 설정되었는지 확인
      if (result['role'] == null || result['role'].toString().isEmpty) {
        _log('역할이 설정되지 않았습니다. 요청한 값으로 대체합니다.');
        // 서버에서 역할을 반환하지 않으면 요청한 값으로 대체
        result['role'] = role;
      }
      
      return result;
    } else {
      final errorBody = utf8.decode(response.bodyBytes);
      _log('소셜 로그인 추가 정보 API 오류: ${response.statusCode}, $errorBody');
      throw Exception('소셜 로그인 추가 정보 설정 실패: ${response.statusCode}');
    }
  }

  // 프로필 이미지 경로 업데이트 API
  static Future<Map<String, dynamic>> updateProfileImagePath({
    required String profileImagePath,
  }) async {
    if (baseUrl.isEmpty) {
      throw Exception('API_BASE_URL가 설정되지 않았습니다. .env 파일을 확인하세요.');
    }

    // 액세스 토큰 가져오기 (인증 필요한 API)
    String? accessToken = await AuthService.getAccessToken();

    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('인증이 필요합니다. 로그인 후 다시 시도해주세요.');
    }

    // 디버깅: 토큰 값 출력
    if (accessToken.length > 10) {
      _log('사용 중인 액세스 토큰: ${accessToken.substring(0, 10)}...');
    }

    final url = Uri.parse('$baseUrl/api-user/user/profile-image');
    
    // API 스펙에 맞게 요청 바디 구성
    final Map<String, dynamic> body = {
      'profileImagePath': profileImagePath,
    };
    
    _log('프로필 이미지 업데이트 API 요청 URL: $url');
    _log('프로필 이미지 업데이트 API 요청 바디: ${jsonEncode(body)}');
    
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
    
    _log('프로필 이미지 업데이트 API 응답 상태 코드: ${response.statusCode}');
    
    if (response.statusCode == 200) {
      final decodedBody = utf8.decode(response.bodyBytes);
      Map<String, dynamic> result = jsonDecode(decodedBody);
      
      _log('프로필 이미지 업데이트 성공: $result');
      return result;
    } else {
      final errorBody = utf8.decode(response.bodyBytes);
      _log('프로필 이미지 업데이트 API 오류: ${response.statusCode}, $errorBody');
      throw Exception('프로필 이미지 업데이트 실패: ${response.statusCode}');
    }
  }

  // 네이버 사용자 정보 설정 (생년월일, 역할 등)
  static Future<Map<String, dynamic>> setNaverUserInfo({
    required String birthdate,
    required String role,
    String? phone,
    String? bankName,
    String? bankAccount,
    String? bankCode,
    String? naverAccountId,
    String? email,
    String? name,
  }) async {
    if (baseUrl.isEmpty) {
      throw Exception('API_BASE_URL가 설정되지 않았습니다. .env 파일을 확인하세요.');
    }

    // 액세스 토큰 가져오기 (인증 필요한 API)
    String? accessToken = await AuthService.getAccessToken();

    if (accessToken == null || accessToken.isEmpty) {
      // 토큰이 없으면 회원가입 API를 호출하여 계정 생성
      _log('토큰이 없습니다. 회원가입 API를 호출하여 계정을 생성합니다.');
      return await _signupWithNaver(
        birthdate: birthdate,
        role: role,
        phone: phone,
        email: email,
        name: name,
        naverAccountId: naverAccountId,
        bankName: bankName,
        bankAccount: bankAccount,
        bankCode: bankCode,
      );
    }

    // 토큰이 있는 경우 사용자 정보 업데이트 API 호출
    try {
      _log('소셜 로그인 추가 정보 API 호출');
      
      final url = Uri.parse('$baseUrl/api-user/user/social/additional-info');
      
      // API 스펙에 맞게 요청 바디 구성
      final Map<String, dynamic> body = {
        'rrn': birthdate,
        'role': role,
      };
      
      // 전화번호가 있으면 추가
      if (phone != null && phone.isNotEmpty) {
        body['phone'] = phone;
      }
      
      _log('소셜 로그인 추가 정보 API 요청 URL: $url');
      _log('소셜 로그인 추가 정보 API 요청 바디: ${jsonEncode(body)}');
      
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
      
      _log('소셜 로그인 추가 정보 API 응답 상태 코드: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        Map<String, dynamic> result = jsonDecode(decodedBody);
        
        // 역할이 설정되었는지 확인
        if (result['role'] == null || result['role'].toString().isEmpty) {
          _log('역할이 설정되지 않았습니다. 요청한 값으로 대체합니다.');
          // 서버에서 역할을 반환하지 않으면 요청한 값으로 대체
          result['role'] = role;
        }
        
        return result;
      } else {
        final errorBody = utf8.decode(response.bodyBytes);
        _log('소셜 로그인 추가 정보 API 오류: ${response.statusCode}, $errorBody');
        
        if (response.statusCode == 500 && errorBody.contains('C004')) {
          _log('서버 오류 C004 발생 - 회원가입 API 호출');
          return await _signupWithNaver(
            birthdate: birthdate,
            role: role,
            phone: phone,
            email: email,
            name: name,
            naverAccountId: naverAccountId,
            bankName: bankName,
            bankAccount: bankAccount,
            bankCode: bankCode,
          );
        }
        
        throw Exception('소셜 로그인 추가 정보 설정 실패: ${response.statusCode}');
      }
    } catch (e) {
      _log('네이버 사용자 정보 설정 오류: $e');
      
      // 오류 발생 시 회원가입 API 호출
      try {
        return await _signupWithNaver(
          birthdate: birthdate,
          role: role,
          phone: phone,
          email: email,
          name: name,
          naverAccountId: naverAccountId,
          bankName: bankName,
          bankAccount: bankAccount,
          bankCode: bankCode,
        );
      } catch (signupError) {
        throw Exception('네이버 사용자 정보 설정 중 오류가 발생했습니다: $e');
      }
    }
  }
  
  // 네이버 계정으로 회원가입
  static Future<Map<String, dynamic>> _signupWithNaver({
    required String birthdate,
    required String role,
    required String? naverAccountId,
    required String? email,
    required String? name,
    String? phone,
    String? bankName,
    String? bankAccount,
    String? bankCode,
  }) async {
    _log('네이버 계정으로 회원가입 시도');
    
    // 계정 정보 유효성 검사
    if (naverAccountId == null || naverAccountId.isEmpty) {
      throw Exception('네이버 계정 ID가 필요합니다');
    }
    
    if (email == null || email.isEmpty) {
      email = 'naver$naverAccountId@example.com';
    }
    
    if (name == null || name.isEmpty) {
      name = '네이버 사용자';
    }
    
    final url = Uri.parse('$baseUrl/api-user/user/public/signup');
    
    // 회원가입용 임시 전화번호 생성
    final String userPhone = phone ?? '01000000000';
    
    // 요청 바디 생성
    final Map<String, dynamic> body = {
      'email': email,
      'password': 'NAVER_LOGIN_$naverAccountId', // 소셜 로그인용 특수 패스워드
      'name': name,
      'phone': userPhone,
      'rrn': birthdate,
      'role': role,
      'socialType': 'NAVER',
      'socialId': naverAccountId,
    };
    
    // 선택적 필드 추가
    if (bankName != null && bankName.isNotEmpty) body['bankName'] = bankName;
    if (bankAccount != null && bankAccount.isNotEmpty) body['bankAccount'] = bankAccount;
    if (bankCode != null && bankCode.isNotEmpty) body['bankCode'] = bankCode;
    
    _log('네이버 회원가입 API 요청 URL: $url');
    _log('네이버 회원가입 API 요청 바디: ${jsonEncode(body)}');
    
    try {
      // POST 요청 - 회원가입 API
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Accept': 'application/json; charset=utf-8',
        },
        body: jsonEncode(body),
      );
      
      _log('네이버 회원가입 API 응답 상태 코드: ${response.statusCode}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        // 성공
        final decodedBody = utf8.decode(response.bodyBytes);
        final result = jsonDecode(decodedBody);
        
        _log('네이버 회원가입 API 성공: $result');
        
        // 액세스 토큰이 있으면 저장
        if (result.containsKey('accessToken') && result['accessToken'] != null) {
          await storage.write(key: 'access_token', value: result['accessToken']);
        }
        
        // 현재 토큰이 만료될 수 있으므로 사용자 정보를 다시 조회
        try {
          final updatedUserInfo = await AuthService.getUserInfo();
          _log('정보 업데이트 후 사용자 정보: $updatedUserInfo');
          return updatedUserInfo;
        } catch (e) {
          _log('사용자 정보 조회 실패, 회원가입 결과 반환: $e');
          return {'role': role, ...result};
        }
      } else if (response.statusCode == 400) {
        // 이미 가입된 이메일 등의 오류 - 로그인 시도
        final errorBody = utf8.decode(response.bodyBytes);
        _log('네이버 회원가입 API 오류 (400): $errorBody');
        
        // 로그인 API 호출
        return await _loginWithNaverAccount(
          email: email,
          naverAccountId: naverAccountId,
        );
      } else {
        // 기타 오류
        final errorBody = utf8.decode(response.bodyBytes);
        _log('네이버 회원가입 API 오류: ${response.statusCode}, $errorBody');
        throw Exception('네이버 회원가입 실패: ${response.statusCode}');
      }
    } catch (e) {
      _log('네이버 회원가입 API 호출 예외: $e');
      
      // 마지막 시도: 이미 존재하는 사용자로 가정하고 로그인 시도
      try {
        return await _loginWithNaverAccount(
          email: email,
          naverAccountId: naverAccountId,
        );
      } catch (loginError) {
        _log('네이버 계정 로그인 실패: $loginError');
        
        // 최후의 수단: 임시 응답 반환
        return {
          'role': role,
          'needsAdditionalInfo': false
        };
      }
    }
  }
  
  // 네이버 계정으로 로그인
  static Future<Map<String, dynamic>> _loginWithNaverAccount({
    required String email,
    required String naverAccountId,
  }) async {
    _log('네이버 계정으로 로그인 시도');
    
    final url = Uri.parse('$baseUrl/api-user/auth/public/login');
    
    // 로그인 요청 바디
    final Map<String, dynamic> body = {
      'email': email,
      'password': 'NAVER_LOGIN_$naverAccountId',
    };
    
    _log('네이버 로그인 API 요청 URL: $url');
    _log('네이버 로그인 API 요청 바디: ${jsonEncode(body)}');
    
    try {
      // POST 요청 - 로그인 API
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Accept': 'application/json; charset=utf-8',
        },
        body: jsonEncode(body),
      );
      
      _log('네이버 로그인 API 응답 상태 코드: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        final result = jsonDecode(decodedBody);
        
        _log('네이버 로그인 API 성공: $result');
        
        // 액세스 토큰 저장
        if (result.containsKey('accessToken') && result['accessToken'] != null) {
          await storage.write(key: 'access_token', value: result['accessToken']);
        }
        
        // 리프레시 토큰 처리
        if (response.headers.containsKey('refresh-token')) {
          await storage.write(key: 'refresh_token', value: response.headers['refresh-token']!);
        }
        
        // 사용자 정보 조회로 역할 확인
        try {
          final userInfo = await AuthService.getUserInfo();
          _log('사용자 정보 조회 성공: $userInfo');
          
          // 추가 정보 필요 여부 확인
          final bool needsAdditionalInfo = userInfo['role'] == null || userInfo['role'].toString().isEmpty;
          
          return {
            ...userInfo,
            'needsAdditionalInfo': needsAdditionalInfo
          };
        } catch (e) {
          _log('사용자 정보 조회 실패: $e');
          return {
            ...result,
            'needsAdditionalInfo': true
          };
        }
      } else {
        final errorBody = utf8.decode(response.bodyBytes);
        _log('네이버 로그인 API 오류: ${response.statusCode}, $errorBody');
        throw Exception('네이버 로그인 실패: ${response.statusCode}');
      }
    } catch (e) {
      _log('네이버 로그인 API 호출 예외: $e');
      throw Exception('네이버 로그인 중 오류가 발생했습니다: $e');
    }
  }
}
