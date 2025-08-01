import 'package:flutter/material.dart';

class PurchaseOptionBottomSheet {
  static Future<void> show(
    BuildContext context,
    Function(String title, String price, int persons, bool hasDiscount)
    onOptionSelected,
  ) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          width: double.infinity,
          height: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Text(
                            '구매하고 싶은 구독권의 옵션을 선택해 주세요',
                            style: TextStyle(
                              color: Color(0xFF202020),
                              fontSize: 14,
                              fontFamily: 'Pretendard-Bold',
                              letterSpacing: -0.28,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            width: 24,
                            height: 24,
                            child: const Icon(Icons.close, size: 24),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '구매하고 싶은 구독권 옵션을 선택해 주세요',
                      style: TextStyle(
                        color: Color(0xFF999999),
                        fontSize: 12,
                        fontFamily: 'Pretendard-Light',
                        letterSpacing: -0.24,
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(color: Colors.white),
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.only(
                        top: 8,
                        left: 16,
                        right: 16,
                        bottom: 8,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildPurchaseOption(
                            context,
                            '1인 구독권',
                            '₩3,500원',
                            '월간',
                            false,
                            onOptionSelected,
                          ),
                          Container(
                            width: double.infinity,
                            height: 1,
                            color: const Color(0xFFE5E5E5),
                          ),
                          _buildPurchaseOption(
                            context,
                            '3인 구독권',
                            '₩7,500원',
                            '월간',
                            false,
                            onOptionSelected,
                          ),
                          Container(
                            width: double.infinity,
                            height: 1,
                            color: const Color(0xFFE5E5E5),
                          ),
                          _buildPurchaseOption(
                            context,
                            '5인 구독권',
                            '₩9,500원',
                            '월간',
                            true,
                            onOptionSelected,
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(color: Colors.white),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      // 직접 구매하기가 아닌 옵션 선택 필요 메시지
                      print('위의 옵션 중 하나를 선택해주세요');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                    ),
                    child: const Text(
                      '구매하기',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontFamily: 'Pretendard-Bold',
                        letterSpacing: -0.32,
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

  static Widget _buildPurchaseOption(
    BuildContext context,
    String title,
    String price,
    String period,
    bool hasDiscount,
    Function(String title, String price, int persons, bool hasDiscount)
    onOptionSelected,
  ) {
    return GestureDetector(
      onTap: () {
        // 구독권 타입에서 인원수 추출
        int persons = 1;
        if (title.contains('3인'))
          persons = 3;
        else if (title.contains('5인'))
          persons = 5;

        Navigator.of(context).pop(); // 현재 모달 닫기
        onOptionSelected(title, price, persons, hasDiscount); // 바로 결제확인 모달 열기
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF202020),
                    fontSize: 16,
                    fontFamily: 'Pretendard-Bold',
                    letterSpacing: -0.32,
                  ),
                ),
                if (hasDiscount) ...[
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: ShapeDecoration(
                      color: const Color(0xFFFFA63D),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      '52% 할인!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontFamily: 'Pretendard-Bold',
                        letterSpacing: -0.20,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  price,
                  style: const TextStyle(
                    color: Color(0xFF666666),
                    fontSize: 12,
                    fontFamily: 'Pretendard-Regular',
                    letterSpacing: -0.24,
                  ),
                ),
                const Text(
                  ' · ',
                  style: TextStyle(
                    color: Color(0xFF666666),
                    fontSize: 12,
                    fontFamily: 'Pretendard-Regular',
                    letterSpacing: -0.24,
                  ),
                ),
                Text(
                  period,
                  style: const TextStyle(
                    color: Color(0xFF666666),
                    fontSize: 12,
                    fontFamily: 'Pretendard-Regular',
                    letterSpacing: -0.24,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
