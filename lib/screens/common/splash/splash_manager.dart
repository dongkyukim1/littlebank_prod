import 'package:shared_preferences/shared_preferences.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'splash_manager.g.dart';

enum OnboardingStep { initial, logo, splash, completed }

@riverpod
class OnboardingState extends _$OnboardingState {
  @override
  Future<OnboardingStep> build(String userId, String userRole) async {
    final hasShownSplash = await SplashManager.hasShownSplash(userId, userRole);

    if (hasShownSplash) {
      return OnboardingStep.completed;
    } else {
      // 로고 화면을 건너뛰고 바로 스플래시 화면으로 이동
      return OnboardingStep.splash;
    }
  }

  Future<void> completeLogoStep() async {
    await SplashManager.setLogoShown(userId);
    state = const AsyncValue.data(OnboardingStep.splash);
  }

  Future<void> completeSplashStep() async {
    await SplashManager.setSplashShown(userId, userRole);
    // 로고도 함께 완료 처리
    await SplashManager.setLogoShown(userId);
    state = const AsyncValue.data(OnboardingStep.completed);
  }
}

class SplashManager {
  // 사용자별 키 생성
  static String _getSplashKey(String userId, String userRole) =>
      'splash_shown_${userId}_$userRole';
  static String _getLogoKey(String userId) => 'logo_shown_$userId';

  /// 해당 사용자의 스플래시를 보여줬는지 확인
  static Future<bool> hasShownSplash(String userId, String userRole) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _getSplashKey(userId, userRole);
      final result = prefs.getBool(key) ?? false;
      print('🔍 스플래시 상태 확인 - 키: $key, 값: $result');
      return result;
    } catch (e) {
      print('❌ 스플래시 상태 확인 실패: $e');
      return false;
    }
  }

  /// 해당 사용자의 로고를 보여줬는지 확인
  static Future<bool> hasShownLogo(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _getLogoKey(userId);
      final result = prefs.getBool(key) ?? false;
      print('🔍 로고 상태 확인 - 키: $key, 값: $result');
      return result;
    } catch (e) {
      print('❌ 로고 상태 확인 실패: $e');
      return false;
    }
  }

  /// 스플래시 완료 표시
  static Future<void> setSplashShown(String userId, String userRole) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _getSplashKey(userId, userRole);
      await prefs.setBool(key, true);
      print('✅ 스플래시 상태 저장 완료 - 키: $key');
      await _printAllKeys(); // 저장 후 모든 키 출력
    } catch (e) {
      print('❌ 스플래시 상태 저장 실패: $e');
    }
  }

  /// 로고 완료 표시
  static Future<void> setLogoShown(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _getLogoKey(userId);
      await prefs.setBool(key, true);
      print('✅ 로고 상태 저장 완료 - 키: $key');
      await _printAllKeys(); // 저장 후 모든 키 출력
    } catch (e) {
      print('❌ 로고 상태 저장 실패: $e');
    }
  }

  /// 모든 상태 초기화 (앱 데이터 초기화 시에만 사용, 로그아웃 시에는 사용하지 않음)
  static Future<void> resetAllStatus() async {
    try {
      print('⚠️ 앱 데이터 초기화 시에만 사용해야 합니다. 로그아웃 시에는 사용하지 마세요.');
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where(
        (key) =>
            key.startsWith('splash_shown_') || key.startsWith('logo_shown_'),
      );
      for (final key in keys) {
        await prefs.remove(key);
      }
      print('✅ 모든 상태 초기화 완료');
      await _printAllKeys(); // 초기화 후 모든 키 출력
    } catch (e) {
      print('❌ 상태 초기화 실패: $e');
    }
  }

  /// 특정 사용자의 스플래시/로고를 보여야 하는지 확인
  static Future<bool> shouldShowOnboarding(
    String userId,
    String userRole,
  ) async {
    print('🔍 온보딩(스플래시/로고) 필요 여부 확인 - 사용자: $userId, 역할: $userRole');

    final hasShownSplashScreen = await hasShownSplash(userId, userRole);
    final hasShownLogoScreen = await hasShownLogo(userId);

    print('🔍 스플래시 표시 완료 여부: $hasShownSplashScreen');
    print('🔍 로고 표시 완료 여부: $hasShownLogoScreen');

    // 둘 다 보지 않은 경우에만 true 반환
    final shouldShow = !hasShownSplashScreen && !hasShownLogoScreen;
    print(shouldShow ? '✅ 온보딩 표시 필요' : '❌ 온보딩 이미 표시됨');

    return shouldShow;
  }

  /// 온보딩(스플래시/로고) 완료 처리
  static Future<void> completeOnboarding(String userId, String userRole) async {
    await setSplashShown(userId, userRole);
    await setLogoShown(userId);
    print('✅ 온보딩 완료 처리 - 사용자: $userId, 역할: $userRole');
  }

  /// 특정 사용자의 상태 초기화 (앱 데이터 초기화 시에만 사용, 로그아웃 시에는 사용하지 않음)
  static Future<void> resetUserStatus(String userId) async {
    try {
      print('⚠️ 앱 데이터 초기화 시에만 사용해야 합니다. 로그아웃 시에는 사용하지 마세요.');
      print('🔄 사용자 온보딩 상태 초기화 - 사용자: $userId');
      final prefs = await SharedPreferences.getInstance();

      final splashKey = _getSplashKey(userId, 'CHILD');
      final parentSplashKey = _getSplashKey(userId, 'PARENT');
      final logoKey = _getLogoKey(userId);

      await prefs.remove(splashKey);
      await prefs.remove(parentSplashKey);
      await prefs.remove(logoKey);

      print('✅ 사용자 온보딩 상태 초기화 완료');
      await _printAllKeys(); // 초기화 후 모든 키 출력
    } catch (e) {
      print('❌ 사용자 상태 초기화 실패: $e');
    }
  }

  /// 디버깅용: 모든 키 출력
  static Future<void> _printAllKeys() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys();
      print('\n📊 현재 저장된 모든 키:');
      for (final key in allKeys) {
        if (key.startsWith('splash_shown_') || key.startsWith('logo_shown_')) {
          final value = prefs.getBool(key);
          print('  $key: $value');
        }
      }
      print('');
    } catch (e) {
      print('❌ 키 출력 실패: $e');
    }
  }
}
