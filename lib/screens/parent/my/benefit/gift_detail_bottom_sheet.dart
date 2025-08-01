import 'package:flutter/material.dart';

class GiftDetailBottomSheet {
  static Future<void> show(
    BuildContext context,
    String title,
    String price,
    int persons,
    bool hasDiscount,
    Function(
      String title,
      String price,
      int persons,
      bool hasDiscount,
      bool includeMyself,
    )
    onNext,
  ) async {
    bool includeMyself = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Scaffold(
              backgroundColor: Colors.transparent,
              body: Stack(
                children: [
                  // 바텀시트 콘텐츠
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: double.infinity,
                      height: MediaQuery.of(context).size.height * 0.32,
                      child: Column(
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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Expanded(
                                      child: Text(
                                        '구독권의 옵션을 선택해 주세요',
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
                                      child: Container(
                                        width: 24,
                                        height: 24,
                                        child: const Icon(
                                          Icons.close,
                                          size: 24,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  '같이하고 싶은 구독권 옵션을 선택해 주세요',
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
                          Expanded(
                            child: Container(
                              width: double.infinity,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                              ),
                              child: SingleChildScrollView(
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                    top: 16,
                                    left: 16,
                                    right: 16,
                                    bottom: 16,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: double.infinity,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Text(
                                                  title,
                                                  style: const TextStyle(
                                                    color: Color(0xFF353535),
                                                    fontSize: 16,
                                                    fontFamily:
                                                        'Pretendard-Medium',
                                                    letterSpacing: -0.32,
                                                  ),
                                                ),
                                                if (hasDiscount) ...[
                                                  const SizedBox(width: 8),
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                          vertical: 4,
                                                        ),
                                                    decoration: ShapeDecoration(
                                                      color: const Color(
                                                        0xFFFFA63D,
                                                      ),
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              8,
                                                            ),
                                                      ),
                                                    ),
                                                    child: const Text(
                                                      '52% 할인!',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 10,
                                                        fontFamily:
                                                            'Pretendard-Bold',
                                                        letterSpacing: -0.20,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              price,
                                              style: const TextStyle(
                                                color: Color(0xFF3A88F4),
                                                fontSize: 16,
                                                fontFamily: 'Pretendard-Bold',
                                                letterSpacing: -0.32,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            includeMyself = !includeMyself;
                                          });
                                        },
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 20,
                                              height: 20,
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                  color:
                                                      includeMyself
                                                          ? const Color(
                                                            0xFF3A88F4,
                                                          )
                                                          : const Color(
                                                            0xFFCCCCCC,
                                                          ),
                                                  width: 2,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                                color:
                                                    includeMyself
                                                        ? const Color(
                                                          0xFF3A88F4,
                                                        )
                                                        : Colors.transparent,
                                              ),
                                              child:
                                                  includeMyself
                                                      ? const Icon(
                                                        Icons.check,
                                                        size: 14,
                                                        color: Colors.white,
                                                      )
                                                      : null,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              '나랑 함께 구독권을 이용할 거예요',
                                              style: TextStyle(
                                                color: const Color(0xFF666666),
                                                fontSize: 12,
                                                fontFamily: 'Pretendard-Light',
                                                letterSpacing: -0.24,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // 하단 고정 버튼 (전체 화면 하단)
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
                            onPressed: () {
                              Navigator.of(context).pop();
                              // 전화번호 입력 바텀시트로 이동
                              onNext(
                                title,
                                price,
                                persons,
                                hasDiscount,
                                includeMyself,
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.zero,
                              ),
                            ),
                            child: const Text(
                              '같이하기',
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
