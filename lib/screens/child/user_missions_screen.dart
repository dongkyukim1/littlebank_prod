import 'package:flutter/material.dart';
import '../../widgets/mission_card.dart';
import '../../widgets/common/bottom_navigation_bar.dart';
import 'home_screen.dart';

class UserMissionsScreen extends StatefulWidget {
  const UserMissionsScreen({super.key});

  @override
  State<UserMissionsScreen> createState() => _UserMissionsScreenState();
}

class _UserMissionsScreenState extends State<UserMissionsScreen> {
  bool _isMissionCardExpanded = false;
  
  // 사용자가 참여 중인 미션 목록
  final List<Map<String, dynamic>> userMissions = [
    {
      'type': 'progress',
      'title': '영어 단어 100개 암기',
      'missionType': '학원 미션',
      'progress': 0.6, // 60% 진행
      'deadline': 'D-6',
      'description': '영어 단어 300개 외워오기 · 3월 30일까지',
      'amount': '200,000원',
    },
    {
      'type': 'progress',
      'title': '수학 연습 문제 50개 풀기',
      'missionType': '학원 미션',
      'progress': 0.3, // 30% 진행
      'deadline': 'D-4',
      'description': '수학 연습 문제 풀기 · 3월 28일까지',
      'amount': '150,000원',
    },
    {
      'type': 'family',
      'title': '주 3회 설거지 담당',
      'missionType': '가족 미션',
      'progress': 0.75, // 75% 진행
      'deadline': 'D-3',
      'description': '가족 규칙 지키기 · 내 친구 XX이 참여',
      'amount': '50,000원',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Image.asset(
            'assets/icons/Icon/뒤로 가기/Regular.png',
            width: 24,
            height: 24,
            color: Colors.black,
          ),
          onPressed: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          ),
        ),
        title: const Text(
          '참여 중인 미션',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'Pretendard',
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: userMissions.length,
              itemBuilder: (context, index) {
                return _buildMissionCard(userMissions[index]);
              },
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
          const CommonBottomNavigationBar(selectedIndex: 2),
        ],
      ),
    );
  }

  Widget _buildMissionCard(Map<String, dynamic> mission) {
    // 미션 타입에 따른 색상 설정
    final Color missionColor = mission['missionType'] == '가족 미션' 
        ? const Color(0xFF89DA8D)  // 가족 미션은 초록색
        : const Color(0xFF5D9EFF); // 학원 미션은 파란색
    
    // 미션 타입에 따른 진행률 색상 설정
    final Color progressColor = mission['missionType'] == '가족 미션'
        ? const Color(0xFF89DA8D)  // 가족 미션은 초록색
        : const Color(0xFF5D9EFF); // 학원 미션은 파란색
    
    // 미션 타입에 따른 금액 색상 설정
    final Color amountColor = mission['missionType'] == '가족 미션'
        ? const Color(0xFF2AAA35)  // 가족 미션은 진한 초록색
        : const Color(0xFF146AFF); // 학원 미션은 파란색
        
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            spreadRadius: 1.5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 미션 타입 및 데드라인
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: missionColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    mission['missionType'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: mission['missionType'] == '가족 미션'
                        ? const Color(0xFFB8F4BC)  // 가족 미션은 연한 초록색
                        : const Color(0xFFFFD27F), // 학원 미션은 노란색
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    mission['deadline'],
                    style: TextStyle(
                      color: mission['missionType'] == '가족 미션'
                          ? const Color(0xFF00550A)  // 가족 미션은 진한 초록색 텍스트
                          : const Color(0xFF001F55), // 학원 미션은 진한 파란색 텍스트
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // 미션 제목
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              mission['title'],
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF353535),
              ),
            ),
          ),
          
          // 미션 설명
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              mission['description'],
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ),
          
          // 프로그레스 바
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: mission['progress'],
                      backgroundColor: Colors.grey[300],
                      color: progressColor,
                      minHeight: 8,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${(mission['progress'] * 100).toInt()}%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: progressColor,
                  ),
                ),
              ],
            ),
          ),
          
          // 금액
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '보상 금액',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  mission['amount'],
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: amountColor,
                  ),
                ),
              ],
            ),
          ),
          
          // 버튼
          Padding(
            padding: const EdgeInsets.all(16),
            child: InkWell(
              onTap: () {
                // 미션 상세로 이동
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: missionColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: const Text(
                  '미션 진행하기',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
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