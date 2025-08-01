import 'package:flutter/material.dart';
import '../screens/child/my/activity_history_screen.dart';

class MissionProgressCard extends StatelessWidget {
  final String title; // 미션 제목
  final String missionType; // 학원 미션 등 분류
  final String description; // 영어 단어 등 설명
  final double progress; // 진행률 (0.0~1.0)
  final String amount; // 보상 금액
  final Function()? onViewMore; // 더보기 버튼 액션

  const MissionProgressCard({
    super.key,
    required this.title,
    required this.missionType,
    required this.description,
    required this.progress,
    required this.amount,
    this.onViewMore,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상단 헤더 (리틀님의 에어팟이 배송되기 직전)
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF262626),
              ),
            ),

            const SizedBox(height: 20),

            // 미션 타입 태그 (학원 미션)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF3179FF),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                missionType,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 미션 설명 (영어 단어 100개 암기)
            Text(
              description,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF444444),
              ),
            ),

            const SizedBox(height: 20),

            // 보상 금액 (200,000원)과 달성률 (60% 달성 중)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD487),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${(progress * 100).toInt()}% 달성 중',
                    style: const TextStyle(
                      color: Color(0xFF444444),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFC248),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    amount,
                    style: const TextStyle(
                      color: Color(0xFF444444),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // 프로그레스 바
            _buildProgressBar(progress),

            const SizedBox(height: 32),

            // 하단 버튼
            _buildActionButton('참여 중인 모든 미션 보러가기', () {
              // 활동내역 화면의 미션 탭(인덱스 0)으로 이동
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ActivityHistoryScreen(initialTabIndex: 0),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // 프로그레스 바 위젯
  Widget _buildProgressBar(double progress) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double barWidth = constraints.maxWidth;

        return SizedBox(
          width: barWidth,
          height: 54,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // 프로그레스 바 배경
              Positioned(
                top: 18,
                left: 0,
                right: 0,
                child: Container(
                  width: barWidth,
                  height: 6,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0E0E0),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),

              // 진행 바
              Positioned(
                top: 18,
                left: 0,
                child: Container(
                  width: barWidth * progress,
                  height: 6,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3179FF),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),

              // 진행 포인트들 (이미지에서 5개의 원형 포인트)
              ...List.generate(5, (index) {
                final pointPosition = index / 4.0; // 0, 0.25, 0.5, 0.75, 1.0
                final isActive = progress >= pointPosition;

                return Positioned(
                  top: 12,
                  left: barWidth * pointPosition - 9,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: isActive ? const Color(0xFF3179FF) : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color:
                            isActive ? Colors.white : const Color(0xFFD0D0D0),
                        width: 3,
                      ),
                    ),
                  ),
                );
              }),

              // 포인트 라벨(F, P, P, P, F)
              Positioned(
                top: 35,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildProgressPointLabel('F'),
                    _buildProgressPointLabel('P'),
                    _buildProgressPointLabel('P'),
                    _buildProgressPointLabel('P'),
                    _buildProgressPointLabel('F'),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 프로그레스 포인트 라벨
  Widget _buildProgressPointLabel(String label) {
    return Container(
      width: 24,
      height: 24,
      decoration: const BoxDecoration(
        color: Color(0xFFF0F0F0),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            color: Color(0xFF3179FF),
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // 액션 버튼
  Widget _buildActionButton(String text, Function() onTap) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF3179FF),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
