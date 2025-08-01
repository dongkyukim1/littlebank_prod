import 'package:flutter/material.dart';
import '../common/splash/splash_wrapper.dart';
import 'home_screen.dart';

class ParentHomeWrapper extends StatelessWidget {
  final String initialRole;
  final String userId;
  final String? signupEmail; // 회원가입 후 자동 로그인용
  final String? signupPassword; // 회원가입 후 자동 로그인용

  const ParentHomeWrapper({
    super.key,
    this.initialRole = 'PARENT',
    required this.userId,
    this.signupEmail,
    this.signupPassword,
  });

  @override
  Widget build(BuildContext context) {
    return SplashWrapper(
      userId: userId,
      userRole: 'PARENT',
      signupEmail: signupEmail,
      signupPassword: signupPassword,
      child: ParentHomeScreen(initialRole: initialRole),
    );
  }
}
