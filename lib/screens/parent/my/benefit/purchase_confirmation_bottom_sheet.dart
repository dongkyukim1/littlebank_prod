import 'package:flutter/material.dart';

class PurchaseConfirmationBottomSheet {
  static Future<void> show(
    BuildContext context,
    String title,
    String price,
    int persons,
    bool hasDiscount,
    List<String> phoneNumbers,
    Function(
      String title,
      String price,
      int persons,
      bool hasDiscount,
      List<String> phoneNumbers,
    )
    onConfirm,
  ) async {
    bool isChecked = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.55,
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
                  SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
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
                                    '구매 완료 후 즉시 구독권이 활성화됩니다',
                                    style: TextStyle(
                                      color: Color(0xFF4A4A4A),
                                      fontSize: 12,
                                      fontFamily: 'Pretendard-Medium',
                                      letterSpacing: -0.24,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    '구매 완료와 동시에 구독권이 바로 활성화되어 리틀뱅크의 모든 서비스를 이용할 수 있습니다',
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
                                    '결제 완료 후 카카오톡으로 쿠폰코드를 전송해드려요',
                                    style: TextStyle(
                                      color: Color(0xFF4A4A4A),
                                      fontSize: 12,
                                      fontFamily: 'Pretendard-Medium',
                                      letterSpacing: -0.24,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '하나의 쿠폰코드로 ${persons}명이 모두 이용할 수 있어요. 친구들과 쿠폰코드를 공유하면 함께 구독권을 사용할 수 있습니다',
                                    style: const TextStyle(
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
                        const SizedBox(height: 24),
                        // 체크박스
                        Row(
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
                                  color:
                                      isChecked
                                          ? const Color(0xFF146AFF)
                                          : Colors.transparent,
                                  border: Border.all(
                                    color:
                                        isChecked
                                            ? const Color(0xFF146AFF)
                                            : const Color(0xFF999999),
                                    width: 1,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child:
                                    isChecked
                                        ? const Icon(
                                          Icons.check,
                                          size: 14,
                                          color: Colors.white,
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
                        const SizedBox(height: 16),
                        // 구독권 구매하러 가기 버튼
                        SizedBox(
                          width: double.infinity,
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
                                        phoneNumbers,
                                      );
                                    }
                                    : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  isChecked
                                      ? const Color(0xFF146AFF)
                                      : const Color(0xFFE5E5E5),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 40,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              '구독권 구매하러 가기',
                              style: TextStyle(
                                color:
                                    isChecked
                                        ? Colors.white
                                        : const Color(0xFF999999),
                                fontSize: 12,
                                fontFamily: 'Pretendard-Medium',
                                letterSpacing: -0.24,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
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
                      ],
                    ),
                  ),
                  // 하단 고정 구매하기 버튼
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
                                        phoneNumbers,
                                      );
                                    }
                                    : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  isChecked
                                      ? Colors.black
                                      : const Color(0xFF666666),
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.zero,
                              ),
                            ),
                            child: const Text(
                              '구매하기',
                              style: TextStyle(
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
}
