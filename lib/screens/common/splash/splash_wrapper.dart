import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'splash_screen.dart';
import 'splash_manager.dart';
import 'logo_screen.dart';
import '../../../services/auth_service.dart';
import '../../../services/token_service.dart';

class SplashWrapper extends HookConsumerWidget {
  final String userRole;
  final String userId;
  final Widget child;
  final String? signupEmail;
  final String? signupPassword;

  const SplashWrapper({
    super.key,
    required this.userRole,
    required this.userId,
    required this.child,
    this.signupEmail,
    this.signupPassword,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboardingState = ref.watch(
      onboardingStateProvider(userId, userRole),
    );

    return onboardingState.when(
      data: (step) {
        switch (step) {
          case OnboardingStep.logo:
            // 로고 화면을 건너뛰고 바로 스플래시로 이동
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ref
                  .read(onboardingStateProvider(userId, userRole).notifier)
                  .completeLogoStep();
            });
            return const Scaffold(
              backgroundColor: Color(0xFF146AFF),
              body: Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            );
          case OnboardingStep.splash:
            return SplashScreen(
              userRole: userRole,
              onComplete: () async {
                // 회원가입 후 자동 로그인 수행
                if (signupEmail != null && signupPassword != null) {
                  try {
                    print('🔐 스플래시 완료 후 자동 로그인 시작 - 이메일: $signupEmail');
                    final loginResult = await AuthService.login(
                      email: signupEmail!,
                      password: signupPassword!,
                    );

                    // 토큰 저장
                    if (loginResult != null &&
                        loginResult['accessToken'] != null &&
                        loginResult['refreshToken'] != null) {
                      await TokenService.saveTokens(
                        accessToken: loginResult['accessToken'],
                        refreshToken: loginResult['refreshToken'],
                      );
                      print('✅ 토큰 저장 완료: $loginResult');
                    } else {
                      print('❌ 로그인 응답에 토큰이 없습니다: $loginResult');
                    }
                  } catch (e) {
                    print('❌ 자동 로그인 실패: $e');
                  }
                }

                await ref
                    .read(onboardingStateProvider(userId, userRole).notifier)
                    .completeSplashStep();
              },
            );
          case OnboardingStep.completed:
            return child;
          case OnboardingStep.initial:
            return const Scaffold(
              backgroundColor: Colors.white,
              body: Center(
                child: CircularProgressIndicator(color: Color(0xFF4A80F0)),
              ),
            );
        }
      },
      loading:
          () => const Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF4A80F0)),
            ),
          ),
      error:
          (error, stack) => Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: SelectableText.rich(
                TextSpan(
                  text: '오류가 발생했습니다\n',
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 16,
                    fontFamily: 'Pretendard-Medium',
                  ),
                  children: [
                    TextSpan(
                      text: error.toString(),
                      style: const TextStyle(
                        fontSize: 14,
                        fontFamily: 'Pretendard-Regular',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }
}
