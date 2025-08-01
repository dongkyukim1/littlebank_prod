import 'package:flutter/material.dart';
import '../shared_weekly_goal_widget.dart';
import '../shared_weekly_goal_empty_widget.dart';

/// 주간 목표를 표시하는 섹션 위젯
class MissionWeeklyGoalSection extends StatelessWidget {
  final Map<String, dynamic>? weeklyGoal;
  final Function(Map<String, dynamic>)? onGoalUpdated;
  final bool showGoalStatus;
  final Function(bool)? onToggleGoalStatus;

  const MissionWeeklyGoalSection({
    super.key,
    this.weeklyGoal,
    this.onGoalUpdated,
    this.showGoalStatus = true,
    this.onToggleGoalStatus,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child:
          showGoalStatus
              ? SharedWeeklyGoalWidget(
                weeklyGoal: weeklyGoal,
                onGoalUpdated: onGoalUpdated,
                usePretendard: true,
                onToggleGoalStatus: onToggleGoalStatus,
              )
              : SharedWeeklyGoalEmptyWidget(
                onGoalSet: (goal) {
                  if (onGoalUpdated != null) {
                    onGoalUpdated!(goal);
                    onToggleGoalStatus?.call(true);
                  }
                },
                onToggleGoalStatus: onToggleGoalStatus,
              ),
    );
  }
}
