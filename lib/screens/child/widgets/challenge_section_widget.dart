import 'package:flutter/material.dart';
import '../../child/challenge/all_challenges_screen.dart';
import '../../../widgets/challenge_card.dart';

/// 챌린지 섹션 위젯
/// 홈 화면과 미션 화면에서 공통으로 사용되는 챌린지 섹션
class ChallengeSectionWidget extends StatelessWidget {
  final List<Map<String, dynamic>> challenges;
  final VoidCallback? onViewAllTap;

  const ChallengeSectionWidget({
    super.key,
    required this.challenges,
    this.onViewAllTap,
  });

  @override
  Widget build(BuildContext context) {
    // 현재 화면 너비를 고려
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Transform.translate 제거하고 직접 Column 반환
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
                      fontFamily: 'Pretendard-Bold',
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
                      fontFamily: 'Pretendard-Regular',
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: GestureDetector(
                onTap:
                    onViewAllTap ??
                    () {
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
                    fontFamily: 'Pretendard-Medium',
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // 슬라이드 형식의 챌린지 카드 (왼쪽 패딩 제거)
        SizedBox(
          height: 280,
          child: ListView.builder(
            padding: EdgeInsets.zero, // 패딩 제거
            scrollDirection: Axis.horizontal,
            itemCount: challenges.length,
            itemBuilder: (context, index) {
              final challenge = challenges[index];
              
              // 날짜 파싱 - ISO 8601 형식에서 깔끔한 형식으로 변환
              String formattedPeriod = challenge['period'];
              
              // startDate와 endDate가 있는 경우 파싱 처리
              if (challenge.containsKey('startDate') && challenge.containsKey('endDate')) {
                try {
                  String startDate = challenge['startDate'];
                  String endDate = challenge['endDate'];
                  
                  // ISO 8601 형식에서 날짜 부분만 추출 (T 이전 부분)
                  String startDateOnly = startDate.split('T')[0];
                  String endDateOnly = endDate.split('T')[0];
                  
                  String startMonth = startDateOnly.split('-')[1].replaceFirst(RegExp('^0'), '');
                  String startDay = startDateOnly.split('-')[2].replaceFirst(RegExp('^0'), '');
                  String endMonth = endDateOnly.split('-')[1].replaceFirst(RegExp('^0'), '');
                  String endDay = endDateOnly.split('-')[2].replaceFirst(RegExp('^0'), '');
                  
                  formattedPeriod = '$startMonth.$startDay - $endMonth.$endDay';
                } catch (e) {
                  // 파싱 실패 시 원본 값 사용
                  print('날짜 파싱 오류: $e');
                }
              }
              
              return Padding(
                padding: EdgeInsets.only(right: 16),
                child: ChallengeCard(
                  id: challenge['id'] ?? 0,
                  periodType: challenge['periodType'],
                  title: challenge['title'],
                  participants: challenge['participants'],
                  period: formattedPeriod, // 파싱된 날짜 사용
                  time: challenge['time'],
                  startDate: challenge['startDate'],
                  endDate: challenge['endDate'],
                  startTime: challenge['startTime'],
                  totalStudyTime: challenge['totalStudyTime'],
                  reward: challenge['reward'],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
