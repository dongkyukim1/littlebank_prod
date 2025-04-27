import 'package:flutter/material.dart';
import '../mission/shared_challenge_widgets.dart';

class PopularChallengesSection extends StatelessWidget {
  final List<Map<String, dynamic>> allChallenges;
  final List<Map<String, dynamic>> currentChallenges;
  final int refreshCount;
  final VoidCallback onRefresh;

  const PopularChallengesSection({
    super.key,
    required this.allChallenges,
    required this.currentChallenges,
    required this.refreshCount,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '많은 사람들이 보고있는 챌린지',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              InkWell(
                onTap: () {
                  // 챌린지 전체 보기 화면으로 이동 (더보기 버튼)
                  SharedChallengeWidgets.showAllChallenges(
                    context,
                    allChallenges,
                  );
                },
                child: Row(
                  children: [
                    Text(
                      '더보기 ',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 12,
                      color: Colors.grey[600],
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 8),

          Text(
            '34,000원 더 모을 수 있어요',
            style: TextStyle(fontSize: 15, color: Colors.grey[600]),
          ),

          SizedBox(height: 16),

          // 필터 버튼
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                SharedChallengeWidgets.buildChallengeTypeButton('전체', true),
                SizedBox(width: 8),
                SharedChallengeWidgets.buildChallengeTypeButton('요일별', false),
                SizedBox(width: 8),
                SharedChallengeWidgets.buildChallengeTypeButton('과목별', false),
              ],
            ),
          ),

          SizedBox(height: 16),

          // 챌린지 카드 목록
          Row(
            children: [
              Expanded(
                child:
                    currentChallenges.isNotEmpty
                        ? SharedChallengeWidgets.buildChallenge(
                          context: context,
                          type: currentChallenges[0]['periodType'],
                          title: currentChallenges[0]['title'],
                          participants: currentChallenges[0]['participants'],
                          period: currentChallenges[0]['period'],
                          time: currentChallenges[0]['time'],
                        )
                        : SharedChallengeWidgets.buildEmptyChallenge(),
              ),
              SizedBox(width: 12),
              Expanded(
                child:
                    currentChallenges.length > 1
                        ? SharedChallengeWidgets.buildChallenge(
                          context: context,
                          type: currentChallenges[1]['periodType'],
                          title: currentChallenges[1]['title'],
                          participants: currentChallenges[1]['participants'],
                          period: currentChallenges[1]['period'],
                          time: currentChallenges[1]['time'],
                        )
                        : SharedChallengeWidgets.buildEmptyChallenge(),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // 페이지 인디케이터와 다른 챌린지 버튼
          Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.7,
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (refreshCount < 3)
                    InkWell(
                      onTap: onRefresh,
                      child: Row(
                        children: [
                          Icon(
                            Icons.refresh,
                            size: 14,
                            color: Colors.grey[700],
                          ),
                          SizedBox(width: 4),
                          Text(
                            '다른 챌린지 더보기 $refreshCount/3',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (refreshCount >= 3)
                    Text(
                      '전체 챌린지를 보시려면 더보기 버튼을 눌러주세요',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
