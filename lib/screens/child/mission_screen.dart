import 'package:flutter/material.dart';
import '../../widgets/mission_card.dart';
import '../../widgets/shared_goal_data.dart';
import '../../models/mission_data.dart';
import '../../widgets/mission/shared_challenge_widgets.dart';
import '../../widgets/mission/mission_comparison_section.dart';
import '../../widgets/mission/mission_weekly_goal_section.dart';
import '../../widgets/mission/bottom_navigation.dart';
import 'widgets/challenge_section_widget.dart';
import 'all_challenges_screen.dart';

class MissionScreen extends StatefulWidget {
  const MissionScreen({super.key});

  @override
  State<MissionScreen> createState() => _MissionScreenState();
}

class _MissionScreenState extends State<MissionScreen> {
  bool _isMissionCardExpanded = false;
  final MissionData missionData = MissionData();
  final ScrollController _scrollController = ScrollController();
  
  // 챌린지 관련 변수 추가
  final List<Map<String, dynamic>> _allChallenges = [
    {
      'periodType': '요일별',
      'title': '일주일동안 매일 공부 3시간',
      'participants': '30/40',
      'period': '3.20 - 3.27',
      'time': '매일 3시간',
    },
    {
      'periodType': '과목별',
      'title': '일주일동안 매일 공부',
      'participants': '25/50',
      'period': '3.1 - 3.31',
      'time': '매일 30분',
    },
    {
      'periodType': '주별',
      'title': '아침 6시 기상하기',
      'participants': '45/60',
      'period': '3.15 - 3.22',
      'time': '매일 오전 6시',
    },
    {
      'periodType': '월별',
      'title': '하루 30분 독서하기',
      'participants': '28/35',
      'period': '3.1 - 3.31',
      'time': '매일 30분',
    },
    {
      'periodType': '주별',
      'title': '주 3회 조깅하기',
      'participants': '20/30',
      'period': '3.18 - 3.25',
      'time': '주 3회',
    },
    {
      'periodType': '월별',
      'title': '하루 물 2리터 마시기',
      'participants': '15/30',
      'period': '3.1 - 3.31',
      'time': '매일',
    },
  ];

  @override
  void initState() {
    super.initState();
    missionData.init();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(50.0),
        child: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Image.asset(
              'assets/images/app_logo.png',
              fit: BoxFit.contain,
            ),
          ),
          title: const Text(
            '나의 미션',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: IconButton(
                icon: Image.asset(
                  'assets/icons/Icon/검색/Regular.png',
                  width: 24,
                  height: 24,
                  color: Colors.black,
                ),
                onPressed: () {},
              ),
            ),
            IconButton(
              icon: Image.asset(
                'assets/icons/Icon/알림/Regular.png',
                width: 24,
                height: 24,
                color: Colors.black,
              ),
              onPressed: () {},
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.only(bottom: 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 친구와 미션 비교 섹션
                  MissionComparisonSection(
                    missionData: missionData,
                    scrollController: _scrollController,
                  ),

                  // 이번 주 나의 목표
                  MissionWeeklyGoalSection(
                    weeklyGoal: missionData.weeklyGoal,
                    onGoalUpdated: (goal) {
                      setState(() {
                        missionData.weeklyGoal = goal;
                        SharedGoalData.weeklyGoal = goal;
                      });
                    },
                  ),

                  // 많은 사람들이 보고있는 챌린지 (홈화면 스타일로)
                  _buildChallengeSection(),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 미션 카드
          MissionCard(
            onExpandChanged: (isExpanded) {
              setState(() {
                _isMissionCardExpanded = isExpanded;
              });
            },
          ),

          // 하단 네비게이션 바
          BottomNavigationWidget(selectedIndex: 2),
        ],
      ),
    );
  }

  Widget _buildChallengeSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ChallengeSectionWidget(challenges: _allChallenges),
    );
  }

  // 챌린지 카드 위젯
  Widget _buildChallengeCard(Map<String, dynamic> challenge) {
    // 시간 값이 매일 3시간 또는 매일 30분이면 설정 가능으로 표시
    final String timeValue = challenge['time'] == '매일 3시간' || challenge['time'] == '매일 30분' ? 
      '설정 가능' : challenge['time'];

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
              style: TextStyle(
                color: const Color(0xFF5D9EFF),
                fontSize: 11,
                fontFamily: 'Pretendard',
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
              style: TextStyle(
                color: const Color(0xFF353535),
                fontSize: 17,
                fontFamily: 'Pretendard',
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
              SizedBox(
                width: 65, // 레이블 너비 줄임
                child: Text(
                  '참여 인원',
                  style: TextStyle(
                    color: const Color(0xFF999999),
                    fontSize: 14,
                    fontFamily: 'Pretendard',
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
                        style: TextStyle(
                          color: const Color(0xFF89DA8D),
                          fontSize: 14,
                          fontFamily: 'Pretendard',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      TextSpan(
                        text: challenge['participants'].split('/')[1],
                        style: TextStyle(
                          color: const Color(0xFF4A4A4A),
                          fontSize: 14,
                          fontFamily: 'Pretendard',
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
              SizedBox(
                width: 65, // 레이블 너비 일관성
                child: Text(
                  '기한',
                  style: TextStyle(
                    color: const Color(0xFF999999),
                    fontSize: 14,
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ),
              Flexible(
                child: Text(
                  challenge['period'],
                  style: TextStyle(
                    color: const Color(0xFF4A4A4A),
                    fontSize: 14,
                    fontFamily: 'Pretendard',
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
              SizedBox(
                width: 65, // 레이블 너비 일관성
                child: Text(
                  '시간',
                  style: TextStyle(
                    color: const Color(0xFF999999),
                    fontSize: 14,
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ),
              Flexible(
                child: Text(
                  timeValue, // 설정 가능 또는 원래 시간값
                  style: TextStyle(
                    color: const Color(0xFF4A4A4A),
                    fontSize: 14,
                    fontFamily: 'Pretendard',
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
            child: Center(
              child: Text(
                '참여하기',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontFamily: 'Pretendard',
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
