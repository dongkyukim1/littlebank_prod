import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenService {
  static final _storage = FlutterSecureStorage();
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';

  // 토큰 저장
  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    try {
      print('💾 토큰 저장 시작');
      await _storage.write(key: _accessTokenKey, value: accessToken);
      await _storage.write(key: _refreshTokenKey, value: refreshToken);
      print('✅ 토큰 저장 완료');
    } catch (e) {
      print('❌ 토큰 저장 실패: $e');
      rethrow;
    }
  }

  // 액세스 토큰 가져오기
  static Future<String?> getAccessToken() async {
    try {
      return await _storage.read(key: _accessTokenKey);
    } catch (e) {
      print('❌ 액세스 토큰 조회 실패: $e');
      return null;
    }
  }

  // 리프레시 토큰 가져오기
  static Future<String?> getRefreshToken() async {
    try {
      return await _storage.read(key: _refreshTokenKey);
    } catch (e) {
      print('❌ 리프레시 토큰 조회 실패: $e');
      return null;
    }
  }

  // 토큰 삭제 (로그아웃 시 사용)
  static Future<void> clearTokens() async {
    try {
      print('🗑️ 토큰 삭제 시작');
      await _storage.delete(key: _accessTokenKey);
      await _storage.delete(key: _refreshTokenKey);
      print('✅ 토큰 삭제 완료');
    } catch (e) {
      print('❌ 토큰 삭제 실패: $e');
      rethrow;
    }
  }

  // 토큰 존재 여부 확인
  static Future<bool> hasValidTokens() async {
    try {
      final accessToken = await getAccessToken();
      final refreshToken = await getRefreshToken();
      return accessToken != null && refreshToken != null;
    } catch (e) {
      print('❌ 토큰 유효성 검사 실패: $e');
      return false;
    }
  }
}
