import 'package:shared_preferences/shared_preferences.dart';
import 'splash_manager.dart';
import 'package:flutter/material.dart';

class SplashDebugHelper extends StatelessWidget {
  const SplashDebugHelper({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ElevatedButton(
          onPressed: () async {
            print('🔄 스플래시 상태 초기화');
            await SplashManager.resetAllStatus();
            print('✅ 스플래시 상태 초기화 완료');
          },
          child: const Text('스플래시 상태 초기화'),
        ),
      ],
    );
  }

  /// 현재 스플래시 상태를 출력합니다
  static Future<void> printSplashStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final allKeys = prefs.getKeys();

    print('\n📊 현재 스플래시/로고 상태:');
    for (final key in allKeys) {
      if (key.startsWith('splash_') || key.startsWith('logo_')) {
        final value = prefs.getBool(key);
        print('  $key: $value');
      }
    }
    if (allKeys.isEmpty ||
        !allKeys.any(
          (key) => key.startsWith('splash_') || key.startsWith('logo_'),
        )) {
      print('  저장된 상태 없음 (초기 상태)');
    }
    print(''); // 빈 줄 출력
  }

  /// 스플래시 상태를 강제로 초기화합니다 (테스트용)
  static Future<void> resetForTesting() async {
    await SplashManager.resetAllStatus();
    print('🔄 스플래시 상태가 초기화되었습니다 (테스트용)');
    await printSplashStatus();
  }

  /// 모든 스플래시 상태를 초기화합니다
  static Future<void> resetSplashStatus() async {
    await SplashManager.resetAllStatus();
    print('🔄 모든 스플래시 상태가 초기화되었습니다');
    await printSplashStatus();
  }

  /// 특정 역할의 스플래시만 초기화합니다
  static Future<void> resetSplashForRole(String userId, String userRole) async {
    await SplashManager.resetUserStatus(userId);
    print('🔄 사용자($userId)의 스플래시 상태가 초기화되었습니다');
    await printSplashStatus();
  }
}
