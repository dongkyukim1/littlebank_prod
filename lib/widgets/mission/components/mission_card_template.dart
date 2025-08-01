import 'package:flutter/material.dart';

/// 미션 카드의 공통 템플릿
/// 다양한 미션 카드에서 재사용 가능한 UI 템플릿을 제공합니다.
class MissionCardTemplate extends StatelessWidget {
  final String title;
  final String missionType;
  final String description;
  final String? amount;
  final Color tagColor;
  final double progressValue;
  final int completedSteps;
  final Widget? button;

  const MissionCardTemplate({
    super.key,
    required this.title,
    required this.missionType,
    required this.description,
    this.amount,
    this.tagColor = const Color(0xFF5D9EFF),
    required this.progressValue,
    required this.completedSteps,
    this.button,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(0.00, 0.50),
            end: Alignment(1.00, 0.50),
            colors: [Color(0xFFF0F2F7), Color(0xFFF2FFF3)],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 카드 컨테이너
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: ShapeDecoration(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                shadows: [
                  BoxShadow(
                    color: const Color(0x24000000),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 미션 유형 태그
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: ShapeDecoration(
                      color: tagColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: Text(
                      missionType,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // 미션 제목
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF353535),
                      fontSize: 16,
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  // 설명
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: const TextStyle(
                      color: Color(0xFF666666),
                      fontSize: 12,
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w400,
                    ),
                  ),

                  // 프로그레스 바 영역
                  Container(
                    margin: const EdgeInsets.only(top: 20),
                    height: 40,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final barWidth = constraints.maxWidth;
                        final positionPercent = barWidth * progressValue;
                        final percentText =
                            '${(progressValue * 100).toInt()}% 달성 중';

                        return Stack(
                          clipBehavior: Clip.none,
                          children: [
                            // 배경바
                            Positioned(
                              top: 16,
                              left: 0,
                              child: Container(
                                width: barWidth,
                                height: 8,
                                decoration: ShapeDecoration(
                                  color: const Color(0xFFDDDDDD),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            ),

                            // 진행바
                            Positioned(
                              top: 16,
                              left: 0,
                              child: Container(
                                width: positionPercent,
                                height: 8,
                                decoration: ShapeDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                    colors: [
                                      tagColor,
                                      tagColor.withOpacity(0.3),
                                    ],
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            ),

                            // 단계별 포인트들
                            for (int i = 0; i < 5; i++)
                              Positioned(
                                left:
                                    i == 0
                                        ? 0
                                        : i == 4
                                        ? barWidth - 24
                                        : barWidth * (i / 4.0) - 12,
                                top: 8,
                                child: Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color:
                                        i < completedSteps
                                            ? tagColor
                                            : const Color(0xFFCCCCCC),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color(0xFFC2D6F3),
                                      width: 4,
                                    ),
                                  ),
                                  child: Center(
                                    child: Image.asset(
                                      'assets/images/flag.png',
                                      width: 12,
                                      height: 12,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),

                            // 진행률 표시
                            Positioned(
                              left: positionPercent - 35,
                              top: -20,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: ShapeDecoration(
                                  color: const Color(0xFFFFD27F),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: Text(
                                  percentText,
                                  style: const TextStyle(
                                    color: Color(0xFF001F55),
                                    fontSize: 10,
                                    fontFamily: 'Pretendard',
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),

                            // 금액 표시 (있을 경우에만)
                            if (amount != null)
                              Positioned(
                                right: 0,
                                top: -20,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: ShapeDecoration(
                                    color: const Color(0xFFFFD27F),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: Text(
                                    amount!,
                                    style: const TextStyle(
                                      color: Color(0xFF001F55),
                                      fontSize: 10,
                                      fontFamily: 'Pretendard',
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // 버튼 (있을 경우에만)
            if (button != null)
              Container(margin: const EdgeInsets.only(top: 12), child: button!),
          ],
        ),
      ),
    );
  }
}
