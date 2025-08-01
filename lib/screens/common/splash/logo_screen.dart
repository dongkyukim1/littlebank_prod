import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class LogoScreen extends HookConsumerWidget {
  final Function() onComplete;
  final Duration duration;

  const LogoScreen({
    super.key,
    required this.onComplete,
    this.duration = const Duration(milliseconds: 2500),
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final animationController = useAnimationController(
      duration: const Duration(milliseconds: 800),
    );

    final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: animationController, curve: Curves.easeInOut),
    );

    useEffect(() {
      animationController.forward();
      Future.delayed(duration, () {
        if (context.mounted) {
          onComplete();
        }
      });
      return null;
    }, const []);

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFF155FB8),
      body: SizedBox(
        width: screenWidth,
        height: screenHeight,
        child: AnimatedBuilder(
          animation: fadeAnimation,
          builder: (context, child) {
            return Opacity(
              opacity: fadeAnimation.value,
              child: Image.asset(
                'assets/poster/logo.png',
                fit: BoxFit.contain,
                width: screenWidth,
                height: screenHeight,
                errorBuilder: (context, error, stackTrace) {
                  print('❌ 로고 이미지 로드 실패: $error');
                  return Container(
                    width: screenWidth,
                    height: screenHeight,
                    color: Colors.white,
                    child: Center(
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          color: const Color(0xFF146AFF),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.account_balance,
                              size: 80,
                              color: Colors.white,
                            ),
                            SizedBox(height: 16),
                            Text(
                              '리틀뱅크',
                              style: TextStyle(
                                fontSize: 24,
                                fontFamily: 'Pretendard-Bold',
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
