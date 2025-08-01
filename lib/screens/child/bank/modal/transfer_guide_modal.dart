import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../../services/payment_service.dart';
import '../../../../../services/auth_service.dart';

class TransferGuideModal extends StatefulWidget {
  const TransferGuideModal({super.key});

  @override
  State<TransferGuideModal> createState() => _TransferGuideModalState();
}

class _TransferGuideModalState extends State<TransferGuideModal> {
  // 불필요한 API 호출 제거 - 안내 모달에서는 API 호출할 필요 없음

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 헤더
            Container(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F4FF),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Icon(
                      Icons.info_outline_rounded,
                      size: 24,
                      color: const Color(0xFF146AFF),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '포인트 꺼내기 안내',
                          style: TextStyle(
                            fontSize: 20,
                            fontFamily: 'Pretendard-Bold',
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF202020),
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '포인트를 현금으로 꺼내는 방법을 안내해드려요',
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: 'Pretendard-Regular',
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF666666),
                            letterSpacing: -0.28,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close_rounded,
                      size: 24,
                      color: Color(0xFF999999),
                    ),
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                ],
              ),
            ),

            // 내용
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 포인트 꺼내기 방법
                    _buildGuideSection('💰', '포인트 꺼내기 방법', [
                      '1. 연결된 계좌로 포인트를 현금으로 꺼낼 수 있어요',
                      '2. 최소 1,000원부터 꺼낼 수 있어요',
                      '3. 꺼낸 현금은 영업일 기준 다음날에 입금돼요',
                    ]),

                    const SizedBox(height: 24),

                    // 수수료 안내
                    _buildGuideSection('💸', '수수료 안내', [
                      '3만원 이상: 수수료 무료',
                      '3만원 미만: 수수료 2%',
                      '수수료는 꺼낼 금액에서 자동 차감돼요',
                    ]),

                    const SizedBox(height: 24),

                    // 입금 일정 안내 추가
                    _buildGuideSection('📅', '입금 일정', [
                      '평일 오후 3시 이전 신청: 당일 처리',
                      '평일 오후 3시 이후 신청: 다음 영업일 처리',
                      '주말/공휴일 신청: 다음 영업일 처리',
                    ]),

                    const SizedBox(height: 24),

                    // 주의사항
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF5F5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFFFE0E0),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                size: 20,
                                color: Color(0xFFFF6B6B),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '주의사항',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontFamily: 'Pretendard-Bold',
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFFFF6B6B),
                                  letterSpacing: -0.28,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '• 포인트 꺼내기는 취소할 수 없어요\n• 계좌 정보를 정확히 확인해주세요\n• 꺼낸 포인트는 복구할 수 없어요',
                            style: TextStyle(
                              fontSize: 12,
                              fontFamily: 'Pretendard-Regular',
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFF666666),
                              letterSpacing: -0.24,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 하단 버튼
            Container(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF146AFF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    '확인했어요',
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'Pretendard-Medium',
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.32,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuideSection(String emoji, String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(emoji, style: TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontFamily: 'Pretendard-Bold',
                fontWeight: FontWeight.w700,
                color: const Color(0xFF202020),
                letterSpacing: -0.32,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(left: 28, bottom: 8),
            child: Text(
              item,
              style: TextStyle(
                fontSize: 14,
                fontFamily: 'Pretendard-Regular',
                fontWeight: FontWeight.w400,
                color: const Color(0xFF666666),
                letterSpacing: -0.28,
                height: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentTargetItem(Map<String, dynamic> target) {
    final userName = target['userName'] ?? '알 수 없음';
    final bankName = target['bankName'] ?? '';
    final bankAccount = target['bankAccount'] ?? '';
    final requestedDate = target['requestedDate'] ?? '';

    // 날짜 포맷팅
    String formattedDate = '';
    if (requestedDate.isNotEmpty) {
      try {
        final date = DateTime.parse(requestedDate);
        formattedDate = '${date.month}.${date.day}';
      } catch (e) {
        formattedDate = '';
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE9ECEF), width: 1),
      ),
      child: Row(
        children: [
          // 프로필 이미지
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFE8F4FF),
            ),
            child: Icon(
              Icons.person_rounded,
              size: 20,
              color: const Color(0xFF146AFF),
            ),
          ),
          const SizedBox(width: 12),
          // 정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName,
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: 'Pretendard-Medium',
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF202020),
                    letterSpacing: -0.28,
                  ),
                ),
                if (bankName.isNotEmpty && bankAccount.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    '$bankName • $bankAccount',
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: 'Pretendard-Light',
                      fontWeight: FontWeight.w300,
                      color: const Color(0xFF999999),
                      letterSpacing: -0.24,
                    ),
                  ),
                ],
              ],
            ),
          ),
          // 날짜
          if (formattedDate.isNotEmpty)
            Text(
              formattedDate,
              style: TextStyle(
                fontSize: 12,
                fontFamily: 'Pretendard-Light',
                fontWeight: FontWeight.w300,
                color: const Color(0xFF999999),
                letterSpacing: -0.24,
              ),
            ),
        ],
      ),
    );
  }
}
