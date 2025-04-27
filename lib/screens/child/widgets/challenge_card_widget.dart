import 'package:flutter/material.dart';

/// 챌린지 카드 위젯
/// 홈 화면과 미션 화면에서 공통으로 사용되는 챌린지 카드
class ChallengeCardWidget extends StatelessWidget {
  final Map<String, dynamic> challenge;

  const ChallengeCardWidget({
    super.key,
    required this.challenge,
  });

  @override
  Widget build(BuildContext context) {
    // 시간 값이 매일 3시간 또는 매일 30분이면 설정 가능으로 표시
    final String timeValue = challenge['time'] == '매일 3시간' || challenge['time'] == '매일 30분' 
        ? '설정 가능' 
        : challenge['time'];

    return Container(
      width: 210,
      height: 280,
      padding: const EdgeInsets.all(16),
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 타입 라벨
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: ShapeDecoration(
              color: const Color(0xFFEFF2F6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: Text(
              challenge['periodType'],
              style: const TextStyle(
                color: Color(0xFF5D9EFF),
                fontSize: 11,
                fontWeight: FontWeight.w300,
                letterSpacing: -0.24,
              ),
            ),
          ),
          const SizedBox(height: 8),
          
          // 제목 영역 - 높이 고정
          SizedBox(
            height: 44, // 높이 고정
            child: Text(
              challenge['title'],
              style: const TextStyle(
                color: Color(0xFF353535),
                fontSize: 17,
                fontWeight: FontWeight.w700,
                height: 1.2,
                letterSpacing: -0.5,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 10),
          
          // 정보 영역 - 일관된 간격
          // 참여 인원
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 65, // 레이블 너비 줄임
                child: Text(
                  '참여 인원',
                  style: TextStyle(
                    color: Color(0xFF999999),
                    fontSize: 14,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ),
              Flexible(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: challenge['participants'].split('/')[0] + '/',
                        style: const TextStyle(
                          color: Color(0xFF89DA8D),
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      TextSpan(
                        text: challenge['participants'].split('/')[1],
                        style: const TextStyle(
                          color: Color(0xFF4A4A4A),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6), // 간격 일관성
          
          // 기한
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 65, // 레이블 너비 일관성
                child: Text(
                  '기한',
                  style: TextStyle(
                    color: Color(0xFF999999),
                    fontSize: 14,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ),
              Flexible(
                child: Text(
                  challenge['period'],
                  style: const TextStyle(
                    color: Color(0xFF4A4A4A),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6), // 간격 일관성
          
          // 시간
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 65, // 레이블 너비 일관성
                child: Text(
                  '시간',
                  style: TextStyle(
                    color: Color(0xFF999999),
                    fontSize: 14,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ),
              Flexible(
                child: Text(
                  timeValue, // 설정 가능 또는 원래 시간값
                  style: const TextStyle(
                    color: Color(0xFF4A4A4A),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          
          const Spacer(), // 남은 공간 채우기
          
          // 참여하기 버튼
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: ShapeDecoration(
              color: const Color(0xFF5D9EFF),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: const Center(
              child: Text(
                '참여하기',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  letterSpacing: -0.28,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 