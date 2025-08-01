import 'package:flutter/material.dart';
import '../../../../services/subscription_service.dart';

class ConfirmationBottomSheet {
  static Future<void> show(
    BuildContext context,
    String title,
    String price,
    int persons,
    bool hasDiscount,
    bool includeMyself,
    List<String> phoneNumbers,
    Function(String, String, int, bool, bool, List<String>) onConfirm, {
    bool isPurchaseMode = false,
  }) async {
    bool isChecked = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              height:
                  isPurchaseMode
                      ? MediaQuery.of(context).size.height * 0.5
                      : MediaQuery.of(context).size.height * 0.6,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Stack(
                children: [
                  // 메인 콘텐츠
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 헤더
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                '잠깐! 결제 전 확인해 주세요',
                                style: TextStyle(
                                  color: Color(0xFF202020),
                                  fontSize: 16,
                                  fontFamily: 'Pretendard-Bold',
                                  letterSpacing: -0.64,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.of(context).pop(),
                              child: const Icon(Icons.close, size: 24),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '구독권 구매 후에는 되돌릴 수 없습니다',
                          style: TextStyle(
                            color: Color(0xFF999999),
                            fontSize: 12,
                            fontFamily: 'Pretendard-Light',
                            letterSpacing: -0.24,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // 첫 번째 설명
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 20,
                              height: 20,
                              decoration: const ShapeDecoration(
                                color: Color(0xFFFFD27F),
                                shape: OvalBorder(),
                              ),
                              child: const Center(
                                child: Text(
                                  '1',
                                  style: TextStyle(
                                    color: Color(0xFF001F55),
                                    fontSize: 9,
                                    fontFamily: 'Pretendard-Bold',
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '타인에게만 공유했을 때, 함께 이용할 수 없어요',
                                    style: TextStyle(
                                      color: Color(0xFF4A4A4A),
                                      fontSize: 12,
                                      fontFamily: 'Pretendard-Medium',
                                      letterSpacing: -0.24,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    '이전 단계에서 나랑 함께 구독권 이용하기를 선택해야 함께 같은 구독권을 이용할 수 있어요',
                                    style: TextStyle(
                                      color: Color(0xFF999999),
                                      fontSize: 10,
                                      fontFamily: 'Pretendard-Light',
                                      height: 1.50,
                                      letterSpacing: -0.20,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // 두 번째 설명
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 20,
                              height: 20,
                              decoration: const ShapeDecoration(
                                color: Color(0xFFFFD27F),
                                shape: OvalBorder(),
                              ),
                              child: const Center(
                                child: Text(
                                  '2',
                                  style: TextStyle(
                                    color: Color(0xFF001F55),
                                    fontSize: 9,
                                    fontFamily: 'Pretendard-Bold',
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '결제 완료 시, 구독권 변경은 한 달 후 가능해요',
                                    style: TextStyle(
                                      color: Color(0xFF4A4A4A),
                                      fontSize: 12,
                                      fontFamily: 'Pretendard-Medium',
                                      letterSpacing: -0.24,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    '이미 결제 완료한 구독권의 경우, 함께 이용하는 멤버들이 있어 환불이 어려워요. 다음 단계로 이동하기 전에, 한 번 더 확인해 주세요',
                                    style: TextStyle(
                                      color: Color(0xFF999999),
                                      fontSize: 10,
                                      fontFamily: 'Pretendard-Light',
                                      height: 1.50,
                                      letterSpacing: -0.20,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // 세 번째 설명
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 20,
                              height: 20,
                              decoration: const ShapeDecoration(
                                color: Color(0xFFFFD27F),
                                shape: OvalBorder(),
                              ),
                              child: const Center(
                                child: Text(
                                  '3',
                                  style: TextStyle(
                                    color: Color(0xFF001F55),
                                    fontSize: 9,
                                    fontFamily: 'Pretendard-Bold',
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '이미 구독 중인 친구는 함께 이용할 수 없어요',
                                    style: TextStyle(
                                      color: Color(0xFF4A4A4A),
                                      fontSize: 12,
                                      fontFamily: 'Pretendard-Medium',
                                      letterSpacing: -0.24,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    '친구가 이미 리틀뱅크의 서비스를 구독 중이라면 아쉽지만 함께 멤버로 이용할 수 없어요. 구독 해지 후 멤버로 초대할 수 있습니다',
                                    style: TextStyle(
                                      color: Color(0xFF999999),
                                      fontSize: 10,
                                      fontFamily: 'Pretendard-Light',
                                      height: 1.50,
                                      letterSpacing: -0.20,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Spacer(),
                        // 체크박스, 같이하러 가기/구매하기 버튼: 항상 노출, 버튼 텍스트만 분기
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  isChecked = !isChecked;
                                });
                              },
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: Colors.transparent,
                                  border: Border.all(
                                    color: const Color(0xFF999999),
                                    width: 1,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child:
                                    isChecked
                                        ? Image.asset(
                                          'assets/icons/my/check_subs.png',
                                          width: 14,
                                          height: 14,
                                        )
                                        : null,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              '구독권에 대해 다 읽고 이해했어요',
                              style: TextStyle(
                                color: Color(0xFF999999),
                                fontSize: 12,
                                fontFamily: 'Pretendard-Light',
                                letterSpacing: -0.24,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: isPurchaseMode ? 4 : 16),
                        Center(
                          child: Text(
                            '언제든지 구독권 관리에서 확인할 수 있어요',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF8490A3),
                              fontSize: 10,
                              fontFamily: 'Pretendard-Light',
                              letterSpacing: -0.20,
                            ),
                          ),
                        ),
                        SizedBox(height: isPurchaseMode ? 40 : 60),
                      ],
                    ),
                  ),
                  // 하단 고정 버튼: 텍스트만 분기, 활성화 조건은 isChecked로 통일
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(color: Colors.black),
                      child: SafeArea(
                        child: SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed:
                                isChecked
                                    ? () async {
                                      Navigator.of(context).pop();
                                      onConfirm(
                                        title,
                                        price,
                                        persons,
                                        hasDiscount,
                                        includeMyself,
                                        phoneNumbers,
                                      );
                                    }
                                    : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.zero,
                              ),
                            ),
                            child: Text(
                              isPurchaseMode ? '구매하기' : '같이하기',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontFamily: 'Pretendard-Bold',
                                letterSpacing: -0.28,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // 카톡으로 구독권 같이하기
  static Future<void> _sendGiftToKakao(
    BuildContext context,
    String title,
    String price,
    int persons,
    bool hasDiscount,
    bool includeMyself,
    List<String> phoneNumbers,
    Function(String) showSuccessDialog,
    Function(String) showErrorDialog,
  ) async {
    try {
      print('===== 구독권 선물 시작 =====');
      print('구독권: $title');
      print('가격: $price');
      print('인원: $persons명');
      print('할인: $hasDiscount');
      print('본인 포함: $includeMyself');
      print('전화번호 목록: ${phoneNumbers.join(', ')}');

      // 로딩 표시
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // 구독권 생성
      final subscriptionResult = await SubscriptionService.createSubscription(
        persons,
      );

      if (subscriptionResult == null) {
        Navigator.of(context).pop(); // 로딩 닫기
        showErrorDialog('구독권 생성에 실패했습니다.');
        return;
      }

      print('구독권 생성 성공: $subscriptionResult');

      // 쿠폰코드 조회
      final inviteData = await SubscriptionService.getInviteCodes();

      if (inviteData == null || inviteData['inviteCodes'] == null) {
        Navigator.of(context).pop(); // 로딩 닫기
        showErrorDialog('쿠폰코드 생성에 실패했습니다.');
        return;
      }

      final inviteCodes = inviteData['inviteCodes'] as Map<String, dynamic>;
      print('쿠폰코드 조회 성공: $inviteCodes');

      Navigator.of(context).pop(); // 로딩 닫기

      // 각 전화번호에 대해 카톡 선물 시도
      bool hasSuccess = false;
      for (String phoneNumber in phoneNumbers) {
        // 첫 번째 사용 가능한 쿠폰코드 사용
        String? inviteCode;
        for (String code in inviteCodes.keys) {
          if (inviteCodes[code] == true) {
            // 사용 가능한 코드
            inviteCode = code;
            break;
          }
        }

        if (inviteCode != null) {
          print('$phoneNumber에게 쿠폰코드 $inviteCode 선물 시도');

          final success = await SubscriptionService.shareInviteCodeToKakao(
            inviteCode,
            persons,
          );
          if (success) {
            hasSuccess = true;
            print('$phoneNumber에게 카톡 선물 성공');
            // 성공한 코드는 사용됨으로 표시 (실제로는 서버에서 관리)
            inviteCodes[inviteCode] = false;
          } else {
            print('$phoneNumber에게 카톡 선물 실패');
          }
        } else {
          print('사용 가능한 쿠폰코드가 없습니다.');
          break;
        }
      }

      if (hasSuccess) {
        showSuccessDialog('구독권 선물이 완료되었습니다!');
      } else {
        showErrorDialog('구독권 선물에 실패했습니다. 다시 시도해주세요.');
      }
    } catch (e) {
      Navigator.of(context).pop(); // 로딩 닫기
      print('구독권 선물 중 오류 발생: $e');
      showErrorDialog('오류가 발생했습니다: $e');
    }
  }

  // 1인 구독권 선물하기 바텀시트
  static Future<void> showGiftBottomSheet(
    BuildContext context,
    Function(String, String, int, bool, bool, List<String>) onConfirm,
  ) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0x5B000000),
                blurRadius: 8,
                offset: Offset(0, -4),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 헤더 섹션
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '구매하기를 눌러 진행해 주세요',
                            style: TextStyle(
                              color: const Color(0xFF202020),
                              fontSize: 18,
                              fontFamily: 'Pretendard-Bold',
                              letterSpacing: -0.72,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '구매하고 싶은 구독권 옵션을 선택해 주세요',
                            style: TextStyle(
                              color: const Color(0xFF999999),
                              fontSize: 14,
                              fontFamily: 'Pretendard-Light',
                              letterSpacing: -0.28,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 24,
                        height: 24,
                        child: Icon(Icons.close, size: 24),
                      ),
                    ),
                  ],
                ),
              ),

              // 구독권 정보 섹션
              GestureDetector(
                onTap: () {
                  Navigator.of(context).pop();
                  // 확인 바텀시트 호출
                  show(
                    context,
                    '1인 구독권',
                    '3,500원',
                    1,
                    false,
                    true,
                    [],
                    onConfirm,
                    isPurchaseMode: true,
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(
                    left: 16,
                    right: 16,
                    bottom: 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '1인 구독권',
                        style: TextStyle(
                          color: const Color(0xFF202020),
                          fontSize: 16,
                          fontFamily: 'Pretendard-Bold',
                          letterSpacing: -0.32,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            '3,500원',
                            style: TextStyle(
                              color: const Color(0xFF666666),
                              fontSize: 12,
                              fontFamily: 'Pretendard-Light',
                              letterSpacing: -0.24,
                            ),
                          ),
                          Text(
                            ' · ',
                            style: TextStyle(
                              color: const Color(0xFF666666),
                              fontSize: 12,
                              fontFamily: 'Pretendard-Light',
                              letterSpacing: -0.24,
                            ),
                          ),
                          Text(
                            '월간',
                            style: TextStyle(
                              color: const Color(0xFF666666),
                              fontSize: 12,
                              fontFamily: 'Pretendard-Light',
                              letterSpacing: -0.24,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // 구매하기 버튼
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.black),
                child: SafeArea(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop();
                      // 확인 바텀시트 호출
                      show(
                        context,
                        '1인 구독권',
                        '3,500원',
                        1,
                        false,
                        true,
                        [],
                        onConfirm,
                        isPurchaseMode: true,
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      height: 22,
                      child: Center(
                        child: Text(
                          '구매하기',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontFamily: 'Pretendard-Bold',
                            letterSpacing: -0.72,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
