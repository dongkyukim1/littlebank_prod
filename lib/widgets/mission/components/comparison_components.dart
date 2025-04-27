import 'package:flutter/material.dart';
import '../../../theme/mission_styles.dart';

/// 미션 비교 관련 공통 컴포넌트들
class ComparisonComponents {
  /// VS 구분선 위젯
  static Widget buildVsDivider() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Container(width: 2, height: 40, color: Colors.grey[300]),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'VS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),
          Container(width: 2, height: 40, color: Colors.grey[300]),
        ],
      ),
    );
  }

  /// 프로필 정보 위젯
  static Widget buildProfileInfo({
    required String name,
    required int missions,
    required int totalMissions,
    required Color color,
    String? imagePath,
  }) {
    return Expanded(
      child: Column(
        children: [
          // 프로필 이미지
          CircleAvatar(
            radius: 25,
            backgroundColor: color.withOpacity(0.1),
            child: ClipOval(
              child: Image.asset(
                'assets/logos/search-sm.png',
                width: 40,
                height: 40,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 8),
          // 이름
          Text(
            name,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          // 미션 현황
          Text(
            '$missions/$totalMissions',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            '미션 완료',
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  /// 카테고리별 비교 항목 위젯
  static Widget buildCategoryComparisonItem({
    required BuildContext context,
    required String category,
    required int myCount,
    required int myTotal,
    required int friendCount,
    required int friendTotal,
    required String myInitial,
    required String friendInitial,
    required Color myColor,
    required Color friendColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 카테고리 제목
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              // 카테고리 라벨 (공부, 운동, 독서 등)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  category,
                  style: const TextStyle(
                    fontSize: 13, 
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),

        // 내 현황
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 내 이름 표시 (프로그레스바 위에)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: myColor.withOpacity(0.2),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: MissionStyles.profileBorderBlue,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          myInitial,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: myColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '김동규',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: myColor,
                      ),
                    ),
                  ],
                ),
              ),
              
              // 프로그레스바와 수치
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 내 미션 수행 정보
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return Stack(
                          children: [
                            // 배경바
                            Container(
                              height: 10,
                              width: constraints.maxWidth,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                            // 진행바
                            Container(
                              height: 10,
                              width: (myCount / myTotal) * constraints.maxWidth,
                              decoration: BoxDecoration(
                                gradient: MissionStyles.blueGradient,
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  
                  // 미션 수행 수치
                  Container(
                    margin: const EdgeInsets.only(left: 12),
                    child: Text(
                      '$myCount/$myTotal',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: myColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // 친구 현황
        Container(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 친구 이름 표시 (프로그레스바 위에)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: friendColor.withOpacity(0.2),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: MissionStyles.profileBorderRed,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          friendInitial,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: friendColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      friendInitial == 'ㄱ' ? '김도연' : friendInitial == '김' ? '김도연' : friendInitial,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: friendColor,
                      ),
                    ),
                  ],
                ),
              ),
              
              // 프로그레스바와 수치
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 친구 미션 수행 정보
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return Stack(
                          children: [
                            // 배경바
                            Container(
                              height: 10,
                              width: constraints.maxWidth,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                            // 진행바
                            Container(
                              height: 10,
                              width: (friendCount / friendTotal) * constraints.maxWidth,
                              decoration: BoxDecoration(
                                gradient: MissionStyles.redGradient,
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  
                  // 미션 수행 수치
                  Container(
                    margin: const EdgeInsets.only(left: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$friendCount/$friendTotal',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: friendColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 프로그레스 바 위젯
  static Widget buildProgressBarWithProfiles({
    required BuildContext context,
    required double myPosition,
    required double friendPosition,
    required String myInitial,
    required String friendInitial,
    required int myMissions,
    required int friendMissions,
  }) {
    return SizedBox(
      height: 90,
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 배경 바
          Positioned(
            left: 0,
            right: 0,
            top: 35,
            child: Container(
              height: 10,
              decoration: BoxDecoration(
                color: MissionStyles.progressBarBgColor,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ),

          // 진행바 (그라데이션 추가)
          Positioned(
            left: 0,
            top: 35,
            child: Container(
              width: myPosition > friendPosition ? myPosition : friendPosition,
              height: 10,
              decoration: BoxDecoration(
                gradient: MissionStyles.blueGradient,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ),

          // 내 프로필
          _buildProfileCircle(
            left: myPosition - 20,
            top: 10,
            initial: myInitial,
            missions: myMissions,
            isMe: true,
          ),

          // 친구 프로필
          _buildProfileCircle(
            left: friendPosition - 20,
            top: 10,
            initial: friendInitial,
            missions: friendMissions,
            isMe: false,
          ),
        ],
      ),
    );
  }

  /// 프로필 원형 아이콘
  static Widget _buildProfileCircle({
    required double left,
    required double top,
    required String initial,
    required int missions,
    required bool isMe,
  }) {
    final Color mainColor =
        isMe ? MissionStyles.primaryBlue : MissionStyles.orangeColor;
    final Color borderColor =
        isMe
            ? MissionStyles.profileBorderBlue
            : MissionStyles.profileBorderOrange;

    return Positioned(
      left: left,
      top: top,
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: borderColor, width: 4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  spreadRadius: 0,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: mainColor,
                ),
                child: Center(
                  child: Text(
                    initial,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$missions',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: mainColor,
            ),
          ),
        ],
      ),
    );
  }

  /// 친구 선택 아이템 위젯
  static Widget buildFriendItem({
    required BuildContext context,
    required Map<String, dynamic> friend,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            // 프로필 이미지
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.blue.withOpacity(0.1),
              child: ClipOval(
                child: Image.asset(
                  'assets/logos/search-sm.png',
                  width: 32,
                  height: 32,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 16),
            // 이름과 미션 정보
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  friend['name'],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '미션 완료: ${friend['missions']}/${friend['totalMissions']}',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
            const Spacer(),
            // 선택 버튼
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: MissionStyles.primaryBlue,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                '비교하기',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
