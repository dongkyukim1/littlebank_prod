import 'package:flutter/material.dart';
import '../common/splash/splash_wrapper.dart';
import '../common/splash/splash_debug_helper.dart';
import 'home_screen.dart';

class ChildHomeWrapper extends StatelessWidget {
  final String userType;
  final String userId;
  final String? signupEmail; // 회원가입 후 자동 로그인용
  final String? signupPassword; // 회원가입 후 자동 로그인용

  const ChildHomeWrapper({
    super.key,
    this.userType = 'student',
    required this.userId,
    this.signupEmail,
    this.signupPassword,
  });

  @override
  Widget build(BuildContext context) {
    // 스플래시 상태 디버깅
    SplashDebugHelper.printSplashStatus();

    print('🎯 ChildHomeWrapper 빌드됨 - userType: $userType');

    return SplashWrapper(
      userId: userId,
      userRole: 'CHILD',
      signupEmail: signupEmail,
      signupPassword: signupPassword,
      child: HomeScreen(userType: userType),
    );
  }
}
