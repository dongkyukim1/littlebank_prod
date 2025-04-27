import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:logging/logging.dart';
import 'package:flutter_naver_login/flutter_naver_login.dart';

class NaverAuthService {
  static final Logger _logger = Logger('NaverAuthService');
  
  // API 기본 URL
  static String get baseUrl => dotenv.env['API_BASE_URL'] ?? '';
  static const storage = FlutterSecureStorage();

  // 개발 환경에서만 로그를 출력하는 유틸리티 함수
  static void _log(String message) {
    if (kDebugMode) {
      _logger.info(message);
      print(message); // 디버그 콘솔에도 출력
    }
  }

  // 네이버 로그인 실행
  static Future<NaverLoginResult> signIn() async {
    try {
      _log('네이버 로그인 시작');
      
      // 이미 로그인된 상태면 로그아웃
      bool isLoggedIn = await FlutterNaverLogin.isLoggedIn;
      if (isLoggedIn) {
        await FlutterNaverLogin.logOut();
      }
      
      // 네이버 로그인 실행
      final NaverLoginResult result = await FlutterNaverLogin.logIn();
      _log('네이버 로그인 결과: ${result.status}');
      
      return result;
    } catch (e) {
      _log('네이버 로그인 오류: $e');
      throw Exception('네이버 로그인 실패: $e');
    }
  }

  // 네이버 로그인 후 회원가입/로그인 처리
  static Future<Map<String, dynamic>> signInWithNaver() async {
    try {
      // 네이버 SDK 로그인
      final loginResult = await signIn();
      
      if (loginResult.status != NaverLoginStatus.loggedIn) {
        throw Exception('네이버 로그인 취소 또는 실패');
      }
      
      // 사용자 계정 정보 가져오기
      _log('네이버 계정 정보 요청');
      final account = await FlutterNaverLogin.currentAccount();
      
      _log('네이버 계정 정보: 이름=${account.name}, 이메일=${account.email}, ID=${account.id}');
      
      // 네이버 API 토큰이 없어도 계정 정보를 사용하여 직접 로그인 시도
      try {
        // 임시 토큰 응답 - 추가 정보 입력 화면으로 이동
        final tempResponse = {
          'accessToken': 'temp_token_for_testing',
          'needsAdditionalInfo': true,
          'naverAccountId': account.id,
          'email': account.email,
          'name': account.name,
        };
        
        _log('임시 응답 생성: $tempResponse');
        return tempResponse;
      } catch (e) {
        _log('네이버 인증 처리 오류: $e');
        throw Exception('네이버 로그인 처리 실패: $e');
      }
    } catch (e) {
      _log('네이버 로그인 프로세스 오류: $e');
      throw Exception('네이버 로그인 프로세스 실패: $e');
    }
  }

  // 네이버 로그아웃
  static Future<void> signOut() async {
    try {
      await FlutterNaverLogin.logOut();
      _log('네이버 로그아웃 성공');
    } catch (e) {
      _log('네이버 로그아웃 오류: $e');
      throw Exception('네이버 로그아웃 중 오류가 발생했습니다: $e');
    }
  }

  // 네이버 프로필 정보 가져오기
  static Future<NaverAccountResult> getProfile() async {
    try {
      final NaverAccountResult profile = await FlutterNaverLogin.currentAccount();
      _log('네이버 프로필 정보: ${profile.email}, ${profile.name}');
      return profile;
    } catch (e) {
      _log('네이버 프로필 정보 가져오기 오류: $e');
      throw Exception('네이버 프로필 정보를 가져오는 중 오류가 발생했습니다: $e');
    }
  }
}
