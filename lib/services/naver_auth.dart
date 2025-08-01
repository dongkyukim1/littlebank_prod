import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_naver_login/flutter_naver_login.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import 'push_notification_service.dart';
import 'package:flutter/services.dart';

class NaverAuthService {
  // API 기본 URL
  static String get baseUrl => dotenv.env['API_BASE_URL'] ?? '';
  static const storage = FlutterSecureStorage();

  // 네이티브 플랫폼 채널 추가
  static const platform = MethodChannel('flutter_naver_login');

  // 네이버 로그인 실행
  static Future<dynamic> signIn() async {
    try {
      // 네이버 SDK 상태 확인을 위한 로그
      print('=== 네이버 로그인 시작 ===');

      // 이미 로그인된 상태면 로그아웃
      try {
        await FlutterNaverLogin.logOut();
        print('기존 로그인 상태 로그아웃 완료');
      } catch (e) {
        // 로그아웃 실패는 무시 (이미 로그아웃 상태일 수 있음)
        print('로그아웃 시도 중 오류 (무시): $e');
      }

      // 네이버 로그인 실행
      print('네이버 로그인 시작...');
      final dynamic result = await FlutterNaverLogin.logIn();
      print('네이버 로그인 결과: $result');
      print('네이버 로그인 상태: ${result?.status}');

      return result;
    } catch (e) {
      print('네이버 로그인 실패: $e');
      throw Exception('네이버 로그인 실패: $e');
    }
  }

  // 네이버 로그인 후 회원가입/로그인 처리
  static Future<Map<String, dynamic>> signInWithNaver() async {
    try {
      // 네이버 SDK 로그인
      final loginResult = await signIn();

      if (loginResult.status.toString() != 'NaverLoginStatus.loggedIn') {
        throw Exception('네이버 로그인 취소 또는 실패');
      }

      print('네이버 로그인 성공: ${loginResult.status}');

      // 토큰과 계정 정보를 가져오기 전에 잠시 대기
      print('토큰 로딩을 위해 2초 대기...');
      await Future.delayed(const Duration(seconds: 2));

      // 사용자 계정 정보 가져오기 (여러 번 시도)
      dynamic account;
      for (int i = 0; i < 3; i++) {
        try {
          account = await FlutterNaverLogin.getCurrentAccount();
          print('네이버 계정 정보 시도 ${i + 1}: $account');
          if (account != null) break;
        } catch (e) {
          print('계정 정보 가져오기 시도 ${i + 1} 실패: $e');
          if (i < 2) await Future.delayed(const Duration(seconds: 1));
        }
      }

      if (account != null) {
        try {
          print('계정 정보 세부사항:');
          print('- account.id: ${account.id}');
          print('- account.email: ${account.email}');
          print('- account.name: ${account.name}');
          print('- account.nickname: ${account.nickname}');
          print('- account.profileImage: ${account.profileImage}');
        } catch (e) {
          print('계정 정보 접근 오류: $e');
        }
      }

      // 네이버 액세스 토큰 가져오기 (여러 번 시도)
      String naverAccessToken = '';

      for (int i = 0; i < 5; i++) {
        try {
          print('플랫폼 채널 통해 토큰 가져오기 시도 ${i + 1}...');
          // 플랫폼 채널을 직접 호출하여 토큰 정보 가져오기
          final dynamic tokenMap = await platform.invokeMethod(
            'getCurrentAccessToken',
          );

          print('플랫폼 채널 응답 타입: ${tokenMap.runtimeType}');
          print('플랫폼 채널 응답 전체: $tokenMap');

          if (tokenMap != null && tokenMap is Map) {
            final accessToken = tokenMap['accessToken'];
            print('Map에서 가져온 토큰: [$accessToken]');
            if (accessToken != null && accessToken.toString().isNotEmpty) {
              naverAccessToken = accessToken.toString();
              // 추가적으로 다른 토큰 정보도 로깅 또는 저장 가능
              print('RefreshToken from platform: ${tokenMap['refreshToken']}');
              print('ExpiresAt from platform: ${tokenMap['expiresAt']}');
              print('TokenType from platform: ${tokenMap['tokenType']}');
              break;
            }
          }
        } catch (e) {
          print('플랫폼 채널 토큰 가져오기 시도 ${i + 1} 중 오류: $e');
        }

        if (i < 4) {
          print('${i + 1}초 후 재시도...');
          await Future.delayed(Duration(seconds: i + 1));
        }
      }

      print('최종 네이버 액세스 토큰: [$naverAccessToken]');
      print('토큰 길이: ${naverAccessToken.length}');
      print('토큰 비어있음 여부: ${naverAccessToken.isEmpty}');

      // 토큰이 없거나 계정 정보가 없는 경우 임시 응답 반환
      if (naverAccessToken.isEmpty || account == null) {
        print('네이버 토큰 또는 계정 정보 부족, 임시 응답 반환');

        // 계정 정보만으로 임시 저장
        if (account != null) {
          await AuthService.setNaverAccountId(account.id?.toString() ?? '');
          await AuthService.setEmail(account.email?.toString() ?? '');
          await AuthService.setName(account.name?.toString() ?? '');
          await AuthService.setSocialType('NAVER');
        }

        return {
          'accessToken': '',
          'needsAdditionalInfo': true,
          'naverAccountId': account?.id?.toString(),
          'email': account?.email?.toString(),
          'name': account?.name?.toString(),
        };
      }

      // 서버에 네이버 토큰 전송하여 자체 JWT 발급 시도
      final serverLoginResult = await _loginWithNaverToken(
        naverAccessToken,
        account,
      );

      // 서버 로그인 성공 시
      if (serverLoginResult != null) {
        print('서버 로그인 성공 (NaverAuthService): $serverLoginResult');

        // accessToken 저장
        if (serverLoginResult.containsKey('accessToken') &&
            serverLoginResult['accessToken'] != null &&
            serverLoginResult['accessToken'].toString().isNotEmpty) {
          await storage.write(
            key: AuthService.accessTokenKey,
            value: serverLoginResult['accessToken'].toString(),
          );
        }

        return {
          'accessToken': serverLoginResult['accessToken']?.toString() ?? '',
          'needsAdditionalInfo': true,
          'naverAccountId': account.id?.toString(),
          'email': account.email?.toString(),
          'name': account.name?.toString(),
        };
      } else {
        // 서버 로그인 실패 시 임시 응답
        print('서버 로그인 실패 후 임시 응답 사용 (NaverAuthService)');

        // 네이버 계정 정보 저장
        await AuthService.setNaverAccountId(account.id?.toString() ?? '');
        await AuthService.setEmail(account.email?.toString() ?? '');
        await AuthService.setName(account.name?.toString() ?? '');
        await AuthService.setSocialType('NAVER');

        return {
          'accessToken': '',
          'needsAdditionalInfo': true,
          'naverAccountId': account.id?.toString(),
          'email': account.email?.toString(),
          'name': account.name?.toString(),
        };
      }
    } catch (e) {
      print('네이버 로그인 프로세스 실패 (NaverAuthService): $e');

      // 예외 발생 시에도 항상 Map 반환
      return {
        'accessToken': '',
        'needsAdditionalInfo': true,
        'naverAccountId': null,
        'email': null,
        'name': null,
        'error': e.toString(),
      };
    }
  }

  // 서버 로그인 API 호출
  static Future<Map<String, dynamic>?> _loginWithNaverToken(
    String naverToken,
    dynamic account,
  ) async {
    try {
      if (baseUrl.isEmpty) {
        throw Exception('API_BASE_URL가 설정되지 않았습니다.');
      }

      final url = Uri.parse('$baseUrl/api-user/auth/public/naver/login');

      // FCM 토큰 가져오기
      String? fcmToken;
      try {
        // PushNotificationService에서 토큰 가져오기
        final pushService = PushNotificationService();
        await pushService.init(); // FCM 토큰 초기화
        fcmToken = pushService.token;

        // 토큰이 없으면 AuthService에서도 확인
        if (fcmToken == null || fcmToken.isEmpty) {
          fcmToken = await AuthService.getFcmToken();
        }
      } catch (e) {
        print('FCM 토큰 가져오기 실패: $e');
      }

      // 요청 바디 생성 - FCM 토큰 포함
      final Map<String, dynamic> body = {
        'accessToken': naverToken,
        'fcmToken': fcmToken ?? 'temp_token', // 토큰이 없을 경우 임시값 사용
      };

      print('네이버 서버 로그인 요청: $body');

      // POST 요청 보내기
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw Exception('로그인 요청 타임아웃'),
          );

      print('네이버 서버 로그인 응답 상태: ${response.statusCode}');

      if (response.statusCode == 200) {
        // 응답 본문 디코딩
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        // 리프레시 토큰 저장
        if (response.headers.containsKey('refresh-token')) {
          await AuthService.storage.write(
            key: AuthService.refreshTokenKey,
            value: response.headers['refresh-token'],
          );
        }

        return responseData;
      } else {
        print('네이버 서버 로그인 실패: ${response.statusCode}, ${response.body}');
        return null; // 실패 시 null 반환
      }
    } catch (e) {
      print('서버 로그인 API 호출 중 오류: $e');
      return null; // 예외 발생 시 null 반환
    }
  }

  // 네이버 로그아웃
  static Future<void> signOut() async {
    try {
      await FlutterNaverLogin.logOut();
    } catch (e) {
      throw Exception('네이버 로그아웃 중 오류가 발생했습니다: $e');
    }
  }

  // 네이버 프로필 정보 가져오기
  static Future<dynamic> getProfile() async {
    try {
      final dynamic profile = await FlutterNaverLogin.getCurrentAccount();
      return profile;
    } catch (e) {
      throw Exception('네이버 프로필 정보를 가져오는 중 오류가 발생했습니다: $e');
    }
  }
}
