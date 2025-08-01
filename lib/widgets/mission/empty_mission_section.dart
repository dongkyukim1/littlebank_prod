import 'package:flutter/material.dart';

class EmptyMissionSection extends StatelessWidget {
  final bool showMissions;
  final Function(bool) onToggleChanged;

  const EmptyMissionSection({
    super.key,
    required this.showMissions,
    required this.onToggleChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width - 32,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Color(0x35000000),
            blurRadius: 8,
            offset: Offset(3, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '미션에 도전하고 보상 받아보세요',
                  style: TextStyle(
                    color: const Color(0xFF202020),
                    fontSize: 16,
                    fontFamily: 'Pretendard-Bold',
                    letterSpacing: -0.72,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  '부모님께 미션을 조르고 용돈 벌기',
                  style: TextStyle(
                    color: const Color(0xFF999999),
                    fontSize: 12,
                    fontFamily: 'Pretendard-Light',
                    letterSpacing: -0.24,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 0),
            child: Center(
              child: Image.asset(
                'assets/icons/Icon/mission/reward.png',
                width: 180,
                height: 180,
                fit: BoxFit.contain,
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20,40, 20, 20),
            child: SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  onToggleChanged(true);
                },
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFF3A88F4),
                  padding: EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              
                child: Text(
                  '미션 조르러 가기',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontFamily: 'Pretendard-Light',
                    letterSpacing: -0.28,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
