import 'package:flutter/material.dart';
import '../../widgets/shared_weekly_goal_widget.dart';

/// 주간 목표를 표시하는 섹션 위젯
class MissionWeeklyGoalSection extends StatelessWidget {
  final Map<String, dynamic>? weeklyGoal;
  final Function(Map<String, dynamic>)? onGoalUpdated;

  const MissionWeeklyGoalSection({
    super.key,
    this.weeklyGoal,
    this.onGoalUpdated,
  });

  @override
  Widget build(BuildContext context) {
    // 홈 화면과 동일한 여백 적용
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SharedWeeklyGoalWidget(
        weeklyGoal: weeklyGoal,
        onGoalUpdated: onGoalUpdated,
      ),
    );
  }
}
