import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../../../services/subscription_service.dart';

class SplashScreen extends HookConsumerWidget {
  final String userRole; // 'CHILD' 또는 'PARENT'
  final VoidCallback onComplete;

  const SplashScreen({
    super.key,
    required this.userRole,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pageController = usePageController();
    final currentPage = useState(0);
    final showInviteBottomSheet = useState(false);
    final inviteCodeController = useTextEditingController();
    final isLoading = useState(false);
    final showClearButton = useState(false);

    // 첫 번째 로고 페이지에서 자동으로 다음 페이지로 이동
    useEffect(() {
      if (currentPage.value == 0) {
        final timer = Future.delayed(const Duration(seconds: 2), () {
          if (pageController.hasClients && currentPage.value == 0) {
            pageController.nextPage(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }
        });
        return () => timer.ignore();
      }
      return null;
    }, [currentPage.value]);

    final splashImages = useMemoized(() {
      if (userRole == 'CHILD') {
        return [
          'assets/poster/splach_kid_1.png',
          'assets/poster/splach_kid_2.png',
          'assets/poster/splach_kid_3.png',
          'assets/poster/splach_kid_4.png',
        ];
      } else {
        return [
          'assets/poster/splach_adult_1.png',
          'assets/poster/splach_adult_2.png',
          'assets/poster/splach_adult_3.png',
        ];
      }
    }, [userRole]);

    // 전체 페이지 수 (로고 페이지 + 스플래시 이미지들)
    final totalPages = splashImages.length + 1;

    void nextPage() {
      if (currentPage.value < totalPages - 1) {
        pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        onComplete();
      }
    }

    void skipToEnd() {
      onComplete();
    }

    void showInviteCodeBottomSheet() {
      showInviteBottomSheet.value = true;
    }

    void hideInviteCodeBottomSheet() {
      showInviteBottomSheet.value = false;
      inviteCodeController.clear();
    }

    Future<void> startFreeTrial() async {
      isLoading.value = true;

      try {
        final result = await SubscriptionService.startFreeTrial('littlebank');

        if (result != null && result['error'] != true) {
          // 무료 구독 시작 성공
          hideInviteCodeBottomSheet();
          onComplete();
        } else {
          // 이미 사용했거나 실패한 경우에도 앱 시작
          hideInviteCodeBottomSheet();
          onComplete();
        }
      } catch (e) {
        // 오류 발생해도 앱 시작
        hideInviteCodeBottomSheet();
        onComplete();
      } finally {
        isLoading.value = false;
      }
    }

    Future<void> handleSubmitInviteCode() async {
      if (isLoading.value) return;

      final code = inviteCodeController.text.trim();
      if (code.isEmpty) {
        // 빈 코드일 경우 기본 무료 구독 시작
        await startFreeTrial();
        return;
      }

      isLoading.value = true;

      try {
        // 쿠폰코드로 구독권 참여 시도
        final result = await SubscriptionService.redeemInviteCode(code);

        if (result != null && result['error'] != true) {
          // 성공
          hideInviteCodeBottomSheet();
          onComplete();
        } else {
          // 실패 - 무료 구독으로 시작
          await startFreeTrial();
        }
      } catch (e) {
        // 오류 발생 - 무료 구독으로 시작
        await startFreeTrial();
      } finally {
        isLoading.value = false;
      }
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isLastPage = currentPage.value == totalPages - 1;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 전체 화면 배경 이미지 PageView
          PageView.builder(
            controller: pageController,
            onPageChanged: (int page) {
              currentPage.value = page;
            },
            itemCount: totalPages,
            itemBuilder: (context, index) {
              // 첫 번째 페이지는 로고 화면
              if (index == 0) {
                return Container(
                  width: screenWidth,
                  height: screenHeight,
                  clipBehavior: Clip.antiAlias,
                  decoration: const BoxDecoration(color: Color(0xFF146AFF)),
                  child: Stack(
                    children: [
                      // 상태바 영역 (시간 표시 등)
                      Positioned(
                        left: 0,
                        top: 0,
                        child: Container(
                          width: screenWidth,
                          height: MediaQuery.of(context).padding.top + 44,
                          clipBehavior: Clip.antiAlias,
                          decoration: const BoxDecoration(),
                        ),
                      ),
                      // 중앙 로고와 텍스트 - 완전한 가운데 정렬
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 140,
                              height: 140,
                              decoration: const BoxDecoration(
                                image: DecorationImage(
                                  image: AssetImage('assets/poster/logo.png'),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text:
                                        '${userRole == 'CHILD' ? '나' : '아이'}를 위한',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontFamily: 'Pretendard-Bold',
                                      fontWeight: FontWeight.w700,
                                      height: 1.50,
                                      letterSpacing: -0.80,
                                    ),
                                  ),
                                  TextSpan(
                                    text:
                                        ' ${userRole == 'CHILD' ? '성장' : '교육'} 앱, 리틀뱅크',
                                    style: const TextStyle(
                                      color: Color(0xFF001F55),
                                      fontSize: 20,
                                      fontFamily: 'Pretendard-Bold',
                                      fontWeight: FontWeight.w700,
                                      height: 1.50,
                                      letterSpacing: -0.80,
                                    ),
                                  ),
                                ],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }

              // 나머지 페이지들은 기존 스플래시 이미지
              return Image.asset(
                splashImages[index - 1],
                width: screenWidth,
                height: screenHeight,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: screenWidth,
                    height: screenHeight,
                    color: const Color(0xFFF5F5F5),
                    child: const Center(
                      child: Text(
                        '이미지를 불러올 수 없습니다',
                        style: TextStyle(
                          color: Color(0xFF999999),
                          fontSize: 14,
                          fontFamily: 'Pretendard-Regular',
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),

          // 상단 건너뛰기 버튼과 슬라이드 인디케이터
          Positioned(
            top: MediaQuery.of(context).padding.top + 40,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 왼쪽 빈 공간 (균형을 위해)
                const SizedBox(width: 60),

                // 가운데 슬라이드 인디케이터 (첫 번째 로고 페이지에서는 숨김)
                if (currentPage.value > 0)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      splashImages.length,
                      (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color:
                              currentPage.value == index + 1
                                  ? Colors.white
                                  : const Color(0xFF999999),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),

                // 오른쪽 건너뛰기 버튼 (첫 번째 로고 페이지에서는 숨김)
                if (currentPage.value > 0)
                  GestureDetector(
                    onTap: skipToEnd,
                    child: const Text(
                      '건너뛰기',
                      style: TextStyle(
                        color: Color(0xFFC4C4C4),
                        fontSize: 12,
                        fontFamily: 'Pretendard-Light',
                        decoration: TextDecoration.underline,
                        decorationColor: Color(0xFFC4C4C4),
                        letterSpacing: -0.24,
                      ),
                    ),
                  )
                else
                  const SizedBox(width: 60), // 균형을 위한 빈 공간
              ],
            ),
          ),

          // 마지막 페이지에서만 보이는 바텀시트
          if (isLastPage)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 0,
                  bottom: 16,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x1A000000),
                      blurRadius: 10,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Transform.translate(
                        offset: const Offset(0, -10),
                        child: const SizedBox(
                          width: double.infinity,
                          child: Text(
                            '지금 시작하고 2주 무료 혜택 받기!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF8490A3),
                              fontSize: 12,
                              fontFamily: 'Pretendard-Light',
                              letterSpacing: -0.24,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: showInviteCodeBottomSheet,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 16,
                          ),
                          decoration: ShapeDecoration(
                            color: const Color(0xFF146AFF),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            '시작하기',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontFamily: 'Pretendard-Medium',
                              letterSpacing: -0.28,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // 쿠폰코드 입력 화면 배경 (파란색 + 로고)
          if (showInviteBottomSheet.value)
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(color: Color(0xFF146AFF)),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 140,
                      height: 140,
                      decoration: const BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage('assets/poster/logo.png'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '${userRole == 'CHILD' ? '아이' : '부모'}를 위한',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontFamily: 'Pretendard-Bold',
                              fontWeight: FontWeight.w700,
                              height: 1.50,
                              letterSpacing: -0.80,
                            ),
                          ),
                          const TextSpan(
                            text: ' 교육 앱, 리틀뱅크',
                            style: TextStyle(
                              color: Color(0xFF001F55),
                              fontSize: 20,
                              fontFamily: 'Pretendard-Bold',
                              fontWeight: FontWeight.w700,
                              height: 1.50,
                              letterSpacing: -0.80,
                            ),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

          // 쿠폰코드 입력 바텀시트
          if (showInviteBottomSheet.value)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                width: double.infinity,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: double.infinity,
                      decoration: const ShapeDecoration(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(24),
                            topRight: Radius.circular(24),
                          ),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Column(
                              children: [
                                Container(
                                  width: 70,
                                  height: 70,
                                  decoration: const BoxDecoration(
                                    image: DecorationImage(
                                      image: AssetImage(
                                        'assets/poster/logo.png',
                                      ),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 6,
                                  ),
                                  child: Column(
                                    children: [
                                      Text.rich(
                                        TextSpan(
                                          children: [
                                            const TextSpan(
                                              text: '친구에게 받은 초대 코드를 입력하고\n',
                                              style: TextStyle(
                                                color: Color(0xFF202020),
                                                fontSize: 18,
                                                fontFamily: 'Pretendard-Bold',
                                                fontWeight: FontWeight.w700,
                                                height: 1.40,
                                                letterSpacing: -0.72,
                                              ),
                                            ),
                                            const TextSpan(
                                              text: '2주 무료 이용 혜택',
                                              style: TextStyle(
                                                color: Color(0xFF3A88F4),
                                                fontSize: 18,
                                                fontFamily: 'Pretendard-Bold',
                                                fontWeight: FontWeight.w700,
                                                height: 1.40,
                                                letterSpacing: -0.72,
                                              ),
                                            ),
                                            const TextSpan(
                                              text: ' 받아가세요!',
                                              style: TextStyle(
                                                color: Color(0xFF202020),
                                                fontSize: 18,
                                                fontFamily: 'Pretendard-Bold',
                                                fontWeight: FontWeight.w700,
                                                height: 1.40,
                                                letterSpacing: -0.72,
                                              ),
                                            ),
                                          ],
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 6),
                                      const Text(
                                        '가입하신 회원님에게는 2주 무료의 혜택이 주어집니다',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Color(0xFF999999),
                                          fontSize: 10,
                                          fontFamily: 'Pretendard-Light',
                                          fontWeight: FontWeight.w300,
                                          letterSpacing: -0.20,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: ShapeDecoration(
                                color: Colors.white,
                                shape: RoundedRectangleBorder(
                                  side: const BorderSide(
                                    width: 1.4,
                                    color: Color(0xFF5D9EFF),
                                  ),
                                  borderRadius: BorderRadius.circular(24),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: inviteCodeController,
                                      onChanged: (value) {
                                        showClearButton.value =
                                            value.isNotEmpty;
                                      },
                                      decoration: const InputDecoration(
                                        hintText: '쿠폰코드를 입력하세요',
                                        hintStyle: TextStyle(
                                          color: Color(0xFF666666),
                                          fontSize: 12,
                                          fontFamily: 'Pretendard-Medium',
                                          fontWeight: FontWeight.w500,
                                          letterSpacing: -0.24,
                                        ),
                                        border: InputBorder.none,
                                        enabledBorder: InputBorder.none,
                                        focusedBorder: InputBorder.none,
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                      style: const TextStyle(
                                        color: Color(0xFF666666),
                                        fontSize: 12,
                                        fontFamily: 'Pretendard-Medium',
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: -0.24,
                                      ),
                                      textCapitalization:
                                          TextCapitalization.characters,
                                    ),
                                  ),
                                  if (showClearButton.value)
                                    GestureDetector(
                                      onTap: () {
                                        inviteCodeController.clear();
                                        showClearButton.value = false;
                                      },
                                      child: Container(
                                        width: 24,
                                        height: 24,
                                        child: Image.asset(
                                          'assets/poster/close.png',
                                          width: 24,
                                          height: 24,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      decoration: const BoxDecoration(color: Colors.white),
                      child: GestureDetector(
                        onTap: isLoading.value ? null : handleSubmitInviteCode,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 16,
                          ),
                          decoration: ShapeDecoration(
                            color: const Color(0xFF146AFF),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            isLoading.value ? '처리중...' : '입력 완료',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontFamily: 'Pretendard-Medium',
                              fontWeight: FontWeight.w500,
                              letterSpacing: -0.24,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: MediaQuery.of(context).padding.bottom),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
