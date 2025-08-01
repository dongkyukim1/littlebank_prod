import 'package:flutter/material.dart';
import '../screens/child/goal_setting_screen.dart';

class SharedWeeklyGoalEmptyWidget extends StatelessWidget {
  final Function(Map<String, dynamic>)? onGoalSet;
  final Function(bool)? onToggleGoalStatus;

  const SharedWeeklyGoalEmptyWidget({
    super.key,
    this.onGoalSet,
    this.onToggleGoalStatus,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 3,
      shadowColor: Colors.black54,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: MediaQuery.of(context).size.width - 16,
        margin: const EdgeInsets.all(0),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상단 헤더 부분
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '이번 주 나의 목표',
                    style: TextStyle(
                      fontSize: 16,
                      color: const Color(0xFF202020),
                      fontFamily: 'Pretendard-Bold',
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '단기적인 목표로 소소한 용돈 벌기',
                    style: TextStyle(
                      fontSize: 12,
                      color: const Color(0xFF999999),
                      fontFamily: 'Pretendard-Regular',
                      letterSpacing: -0.24,
                    ),
                  ),
                ],
              ),
            ),
            
            // 중앙 내용 및 버튼 영역
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 30),
              child: Column(
                children: [
                  // 저금통 일러스트
                  Container(
                    height: 180,
                    child: Image.asset(
                      'assets/icons/Icon/mission/target.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 30),
                  
                  // 목표 세우러 가기 버튼
                  GestureDetector(
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const GoalSettingScreen(),
                        ),
                      );

                      if (result != null && result is Map<String, dynamic> && onGoalSet != null) {
                        onGoalSet!(result);
                      }
                    },
                    child: Container(
                      width: 318,
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                      decoration: ShapeDecoration(
                        color: const Color(0xFF3A88F4),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            '목표 세우러 가기',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontFamily: 'Pretendard-Light',
                              letterSpacing: -0.28,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // "목표가 있어요" 버튼 영역
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
              child: InkWell(
                onTap: () {
                  if (onToggleGoalStatus != null) {
                    onToggleGoalStatus!(true);
                  }
                },
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '목표가 있어요',
                    style: TextStyle(
                      fontSize: 8,
                      color: Colors.grey[600],
                      fontFamily: 'Pretendard-Regular',
                      decoration: TextDecoration.underline,
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
}
