import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../screens/child/goal_setting_screen.dart';

class SharedWeeklyGoalWidget extends StatelessWidget {
  final Map<String, dynamic>? weeklyGoal;
  final Function(Map<String, dynamic>)? onGoalUpdated;
  final bool usePretendard;

  const SharedWeeklyGoalWidget({
    super.key,
    this.weeklyGoal,
    this.onGoalUpdated,
    this.usePretendard = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '이번 주 나의 목표',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                            fontFamily: 'Pretendard',
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '짧은 목표로 소소하게 용돈 벌기',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.secondaryColor,
                            fontFamily: 'Pretendard',
                            fontWeight: FontWeight.w300,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 10, left: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: ShapeDecoration(
                      color: const Color(0xFFEFF2F6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: InkWell(
                      onTap: () async {
                        // 목표 설정 화면으로 이동
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const GoalSettingScreen(),
                          ),
                        );

                        // 결과가 있으면 상태 업데이트
                        if (result != null &&
                            result is Map<String, dynamic> &&
                            onGoalUpdated != null) {
                          onGoalUpdated!(result);
                        }
                      },
                      child: Text(
                        '수정하기',
                        style: TextStyle(
                          color: const Color(0xFF001F55),
                          fontSize: 13,
                          fontFamily: 'Pretendard',
                          fontWeight: FontWeight.w500,
                          letterSpacing: -0.24,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),

              // 습관형성 태그
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD27F),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '습관 형성',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w100,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // 목표 내용
              Text(
                '이번 주 저녁 설거지 담당',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  fontFamily: 'Pretendard',
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '이번 주 저녁 먹고 바로 설거지를 시작하는 습관을 들여보자',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w300,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),

              // 부가 설명/피드백
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F2F7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            '어제도 깨끗하게 설거지 해줘서 고마워~',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.secondaryColor,
                              fontFamily: 'Pretendard',
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 18,
                      color: Colors.grey[500],
                      weight: 600,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
