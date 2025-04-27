import 'package:flutter/material.dart';
import 'challenge_card_widget.dart';
import '../../child/all_challenges_screen.dart';

/// 챌린지 섹션 위젯
/// 홈 화면과 미션 화면에서 공통으로 사용되는 챌린지 섹션
class ChallengeSectionWidget extends StatelessWidget {
  final List<Map<String, dynamic>> challenges;

  const ChallengeSectionWidget({
    super.key,
    required this.challenges,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
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
                  const Text(
                    '많은 사람들이 보고있는 챌린지',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF353535),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '현재 가장 많이 참여 중이에요',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w400,
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AllChallengesScreen(),
                    ),
                  );
                },
                child: const Text(
                  '전체보기',
                  style: TextStyle(
                    color: Color(0xFF001F55),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // 슬라이드 형식의 챌린지 카드
        SizedBox(
          height: 280,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: challenges.length,
            itemBuilder: (context, index) {
              final challenge = challenges[index];
              return Padding(
                padding: EdgeInsets.only(right: 16),
                child: ChallengeCardWidget(challenge: challenge),
              );
            },
          ),
        ),
      ],
    );
  }
} 