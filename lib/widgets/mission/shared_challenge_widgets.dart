import 'package:flutter/material.dart';
import '../../screens/child/challenge/challenge_detail_screen.dart';

/// 홈화면과 미션화면에서 공유하는 챌린지 관련 위젯들
class SharedChallengeWidgets {
  /// 챌린지 타입 버튼 (예: 전체, 요일별, 과목별)
  static Widget buildChallengeTypeButton(
    String text,
    bool isSelected, {
    bool usePretendard = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color:
            isSelected
                ? (usePretendard ? const Color(0xFF5D9EFF) : Colors.red)
                : (usePretendard ? const Color(0xFFF0F2F7) : Colors.grey[300]),
        borderRadius: BorderRadius.circular(usePretendard ? 8 : 20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color:
              isSelected
                  ? Colors.white
                  : (usePretendard ? Colors.black : Colors.grey[700]),
          fontSize: 13,
          fontWeight: FontWeight.w500,
          fontFamily: usePretendard ? 'Pretendard-Medium' : null,
        ),
      ),
    );
  }

  /// 챌린지 카드 생성
  static Widget buildChallenge({
    required BuildContext context,
    required String type,
    required String title,
    required String participants,
    required String period,
    required String time,
    bool usePretendard = false,
  }) {
    // 타입 텍스트 변환
    String displayType = type;
    if (type == '주별') displayType = '요일별';
    if (type == '월별') displayType = '과목별';

    return Container(
      height: 240, // 높이를 230px에서 240px로 늘림
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!), // 테두리 추가
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            spreadRadius: 0,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 타입 라벨
          Container(
            width: 45,
            margin: const EdgeInsets.only(top: 8, left: 12),
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
            decoration: BoxDecoration(
              color: type == '주별' ? Colors.blue : Colors.orange,
              borderRadius: BorderRadius.circular(4),
            ),
            alignment: Alignment.center,
            child: Text(
              displayType,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min, // 최소 크기로 설정
                children: [
                  // 제목 (클릭 가능)
                  InkWell(
                    onTap: () {
                      // 제목 클릭 시 간단한 모달 표시
                      showSimpleChallengeModal(
                        context,
                        title,
                        type,
                        participants,
                        period,
                        time,
                      );
                    },
                    child: SizedBox(
                      height: 45, // 타이틀 영역 높이 늘림
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2, // 3줄에서 2줄로 줄임
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),

                  const SizedBox(height: 8), // 간격 줄임
                  // 정보 행들
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min, // 최소 크기 설정
                    children: [
                      buildInfoRow('참여 인원', participants, false),
                      const SizedBox(height: 4), // 간격 줄임
                      buildInfoRow('기간', period, false),
                      const SizedBox(height: 4), // 간격 줄임
                      buildInfoRow('시간', time, false),
                    ],
                  ),

                  const Spacer(),
                  // 참여하기 버튼
                  SizedBox(
                    width: double.infinity,
                    height: 30,
                    child: ElevatedButton(
                      onPressed: () {
                        // 챌린지 상세 화면으로 이동
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => ChallengeDetailScreen(
                                  id: 0,
                                  type: type,
                                  title: title,
                                  participants: participants,
                                  period: period,
                                  time: time,
                                  startDate: '',
                                  endDate: '',
                                  startTime: '',
                                  totalStudyTime: 0,
                                  reward: 0,
                                ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
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
                          fontSize: 12, // 글자 크기 줄임
                          fontWeight: FontWeight.w500,
                        ),
                      ),
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

  /// 정보 행 (참여인원, 기간, 시간 등)
  static Widget buildInfoRow(String label, String value, bool usePretendard) {
    // 참여 인원인 경우 특별한 처리
    if (label == '참여 인원') {
      final parts = value.split('/');
      if (parts.length == 2) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$label: ',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: parts[0],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.green,
                    ),
                  ),
                  TextSpan(
                    text: '/${parts[1]}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        );
      }
    }

    // 기본 정보 행
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '$label: ',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  /// 빈 챌린지 카드
  static Widget buildEmptyChallenge({bool usePretendard = false}) {
    return Container(
      height: 240, // 높이 240px로 일치시키기
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            spreadRadius: 0,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 24, color: Colors.grey[400]),
          SizedBox(height: 8),
          Text(
            '챌린지 정보를 찾을 수 없습니다',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  /// 모든 챌린지 목록 보기 바텀시트
  static void showAllChallenges(
    BuildContext context,
    List<Map<String, dynamic>> allChallenges, {
    bool usePretendard = false,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.8,
            maxChildSize: 0.9,
            minChildSize: 0.5,
            builder:
                (_, controller) => Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(usePretendard ? 8 : 20),
                    ),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '모든 챌린지',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontFamily:
                                  usePretendard ? 'Pretendard-SemiBold' : null,
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        '참여 가능한 모든 챌린지를 확인해보세요',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontFamily:
                              usePretendard ? 'Pretendard-Regular' : null,
                        ),
                      ),
                      SizedBox(height: 16),
                      Expanded(
                        child: ListView.separated(
                          controller: controller,
                          itemCount: allChallenges.length,
                          separatorBuilder:
                              (context, index) => SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final challenge = allChallenges[index];
                            return InkWell(
                              onTap: () {
                                // 챌린지 상세 화면으로 이동
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => ChallengeDetailScreen(
                                          id: challenge['id'] ?? 0,
                                          type: challenge['periodType'],
                                          title: challenge['title'],
                                          participants:
                                              challenge['participants'],
                                          period: challenge['period'],
                                          time: challenge['time'],
                                          startDate: challenge['startDate'],
                                          endDate: challenge['endDate'],
                                          startTime: challenge['startTime'],
                                          totalStudyTime: challenge['totalStudyTime'],
                                          reward: challenge['reward'],
                                        ),
                                  ),
                                );
                              },
                              child: Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(
                                    usePretendard ? 8 : 12,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            usePretendard
                                                ? const Color(0xFF5D9EFF)
                                                : Colors.grey[200],
                                        borderRadius: BorderRadius.circular(
                                          usePretendard ? 8 : 12,
                                        ),
                                      ),
                                      child: Text(
                                        challenge['periodType'],
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color:
                                              usePretendard
                                                  ? Colors.white
                                                  : Colors.grey[800],
                                          fontFamily:
                                              usePretendard
                                                  ? 'Pretendard-Medium'
                                                  : null,
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      challenge['title'],
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        fontFamily:
                                            usePretendard
                                                ? 'Pretendard-SemiBold'
                                                : null,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '참여: ${challenge['participants']}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[700],
                                            fontFamily:
                                                usePretendard
                                                    ? 'Pretendard-Regular'
                                                    : null,
                                          ),
                                        ),
                                        Text(
                                          '기간: ${challenge['period']}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[700],
                                            fontFamily:
                                                usePretendard
                                                    ? 'Pretendard-Regular'
                                                    : null,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
          ),
    );
  }

  /// 간단한 챌린지 모달
  static void showSimpleChallengeModal(
    BuildContext context,
    String title,
    String type,
    String participants,
    String period,
    String time, {
    bool usePretendard = false,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(usePretendard ? 8 : 16),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            width:
                MediaQuery.of(context).size.width *
                (usePretendard ? 0.85 : 0.9),
            padding: EdgeInsets.all(usePretendard ? 20 : 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(usePretendard ? 8 : 16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 챌린지 타입 태그
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color:
                          usePretendard
                              ? const Color(0xFF5D9EFF)
                              : Colors.grey[200],
                      borderRadius: BorderRadius.circular(
                        usePretendard ? 8 : 12,
                      ),
                    ),
                    child: Text(
                      type,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: usePretendard ? Colors.white : Colors.grey[800],
                        fontFamily: usePretendard ? 'Pretendard-Medium' : null,
                      ),
                    ),
                  ),

                  SizedBox(height: usePretendard ? 16 : 12),

                  // 챌린지 제목
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: usePretendard ? 20 : 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  SizedBox(height: usePretendard ? 20 : 16),

                  // 참가자 정보
                  Row(
                    children: [
                      Icon(
                        Icons.people,
                        size: usePretendard ? 18 : 16,
                        color: Colors.grey[600],
                      ),
                      SizedBox(width: usePretendard ? 8 : 6),
                      Expanded(
                        child: Text(
                          '참여 인원: $participants',
                          style: TextStyle(
                            fontSize: usePretendard ? 14 : 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[700],
                            fontFamily:
                                usePretendard ? 'Pretendard-Medium' : null,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: usePretendard ? 8 : 6),

                  // 기간 정보
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: usePretendard ? 18 : 16,
                        color: Colors.grey[600],
                      ),
                      SizedBox(width: usePretendard ? 8 : 6),
                      Expanded(
                        child: Text(
                          '기간: $period',
                          style: TextStyle(
                            fontSize: usePretendard ? 14 : 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[700],
                            fontFamily:
                                usePretendard ? 'Pretendard-Medium' : null,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: usePretendard ? 20 : 16),

                  // 참여하기 버튼
                  SizedBox(
                    width: double.infinity,
                    height: usePretendard ? 45 : 40,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => ChallengeDetailScreen(
                                  id: 0,
                                  type: type,
                                  title: title,
                                  participants: participants,
                                  period: period,
                                  time: time,
                                  startDate: '',
                                  endDate: '',
                                  startTime: '',
                                  totalStudyTime: 0,
                                  reward: 0,
                                ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            usePretendard
                                ? const Color(0xFF5D9EFF)
                                : Colors.blue[500],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            usePretendard ? 8 : 10,
                          ),
                        ),
                        padding: EdgeInsets.zero,
                        elevation: 1,
                      ),
                      child: Text(
                        '참여하기',
                        style: TextStyle(
                          fontSize: usePretendard ? 16 : 15,
                          fontWeight: FontWeight.bold,
                          fontFamily:
                              usePretendard ? 'Pretendard-SemiBold' : null,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
