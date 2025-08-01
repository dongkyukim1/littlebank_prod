import 'package:flutter/material.dart';
import '../screens/child/challenge/challenge_detail_screen.dart';

class ChallengeCard extends StatelessWidget {
  final int id;
  final String periodType;
  final String title;
  final String participants;
  final String period;
  final String time;
  final String? startDate;
  final String? endDate;
  final String? startTime;
  final int? totalStudyTime;
  final int? reward;
  final VoidCallback? onTap;

  const ChallengeCard({
    super.key,
    this.id = 0,
    required this.periodType,
    required this.title,
    required this.participants,
    required this.period,
    required this.time,
    this.startDate,
    this.endDate,
    this.startTime,
    this.totalStudyTime,
    this.reward,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // 시간 값이 매일 3시간 또는 매일 30분이면 설정 가능으로 표시
    final String timeValue =
        time == '매일 3시간' || time == '매일 30분' ? '설정 가능' : time;

    return Container(
      width: 210,
      padding: const EdgeInsets.all(16),
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 타입 라벨
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: ShapeDecoration(
              color: const Color(0xFFEFF2F6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Text(
              periodType,
              style: const TextStyle(
                color: Color(0xFF5D9EFF),
                fontSize: 11,
                fontFamily: 'Pretendard-Light',
                letterSpacing: -0.24,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // 제목 영역 - 한 줄로 제한, 위치 조정
          SizedBox(
            height: 30,
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF353535),
                  fontSize: 17, // 15px에서 17px로 2px 키움
                  fontFamily: 'Pretendard-Bold',
                  height: 1.2,
                  letterSpacing: -0.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const SizedBox(height: 30), // 20px에서 30px로 간격 더 늘림

          // 정보 영역 - 일관된 간격으로 수정
          // 참여 인원
          Row(
            mainAxisSize: MainAxisSize.max, // min에서 max로 변경
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const SizedBox(
                width: 65,
                child: Text(
                  '참여 인원',
                  style: TextStyle(
                    color: Color(0xFF999999),
                    fontSize: 14,
                    fontFamily: 'Pretendard-Light',
                  ),
                ),
              ),
              const SizedBox(width: 12), // 일관된 간격 추가
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '${participants.split('/')[0]}/',
                        style: const TextStyle(
                          color: Color(0xFF89DA8D),
                          fontSize: 14,
                          fontFamily: 'Pretendard-Medium',
                        ),
                      ),
                      TextSpan(
                        text: participants.split('/')[1],
                        style: const TextStyle(
                          color: Color(0xFF4A4A4A),
                          fontSize: 14,
                          fontFamily: 'Pretendard-Medium',
                        ),
                      ),
                    ],
                  ),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.left,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // 기한
          Row(
            mainAxisSize: MainAxisSize.max, // min에서 max로 변경
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const SizedBox(
                width: 65,
                child: Text(
                  '기한',
                  style: TextStyle(
                    color: Color(0xFF999999),
                    fontSize: 14,
                    fontFamily: 'Pretendard-Light',
                  ),
                ),
              ),
              const SizedBox(width: 12), // 일관된 간격 추가
              Expanded(
                child: Text(
                  period,
                  style: const TextStyle(
                    color: Color(0xFF4A4A4A),
                    fontSize: 14,
                    fontFamily: 'Pretendard-Medium',
                  ),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.left,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // 시간
          Row(
            mainAxisSize: MainAxisSize.max, // min에서 max로 변경
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const SizedBox(
                width: 65,
                child: Text(
                  '시간',
                  style: TextStyle(
                    color: Color(0xFF999999),
                    fontSize: 14,
                    fontFamily: 'Pretendard-Light',
                  ),
                ),
              ),
              const SizedBox(width: 12), // 일관된 간격 추가
              Expanded(
                child: Text(
                  timeValue,
                  style: const TextStyle(
                    color: Color(0xFF4A4A4A),
                    fontSize: 14,
                    fontFamily: 'Pretendard-Medium',
                  ),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.left,
                ),
              ),
            ],
          ),

          const Spacer(), // 남은 공간 채우기
          // 참여하기 버튼
          SizedBox(
            width: double.infinity,
            height: 40,
            child: ElevatedButton(
              onPressed: () {
                // 챌린지 상세 화면으로 이동
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChallengeDetailScreen(
                      id: id,
                      type: periodType,
                      title: title,
                      participants: participants,
                      period: period,
                      time: time,
                      startDate: startDate ?? '',
                      endDate: endDate ?? '',
                      startTime: startTime ?? '09:00:00',
                      totalStudyTime: totalStudyTime ?? 0,
                      reward: reward ?? 0,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5D9EFF),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: EdgeInsets.zero,
              ),
              child: const Text(
                '참여하기',
                style: TextStyle(
                  fontSize: 12,
                  fontFamily: 'Pretendard-Medium',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
