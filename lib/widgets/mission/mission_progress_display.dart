import 'package:flutter/material.dart';
import '../../models/mission_data.dart';

/// 미션 진행 상황을 프로그레스바와 프로필로 표시하는 위젯
class MissionProgressDisplay extends StatelessWidget {
  final MissionData missionData;

  const MissionProgressDisplay({super.key, required this.missionData});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 70, // 높이 증가 (버튼 위한 공간 확보)
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 배경 바 (전체 길이의 프로그레스바, 회색으로 표시됨)
          Positioned(
            left: 0, // 가장 왼쪽으로 이동
            right: 80, // 오른쪽 여백 증가 (훔쳐보기 버튼과 간격 유지)
            top: 20, // 위치 조정
            child: Container(
              height: 12, // 두께 증가
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),

          // 진행 바 (0부터 김동규 위치까지만 그라데이션 색상으로 채워짐)
          Positioned(
            left: 0, // 가장 왼쪽으로 이동
            top: 20, // 위치 조정
            child: LayoutBuilder(
              builder: (context, constraints) {
                // 전체 너비 계산 (배경 바와 동일)
                final double fullWidth = MediaQuery.of(context).size.width - 80;

                // 사용자 위치 계산 (30% 지점)
                final double userPosition = fullWidth * 0.3;
                // 친구 위치 계산 (50% 지점으로 이동)
                final double friendPosition = fullWidth * 0.5;

                return SizedBox(
                  width: fullWidth, // 전체 너비
                  height: 12, // 두께
                  child: Stack(
                    children: [
                      // 0부터 김동규 위치(50%)까지만 그라데이션으로 표시
                      Positioned(
                        left: 0,
                        top: 0,
                        child: Container(
                          height: 12,
                          width: friendPosition, // 김동규 위치(50%)까지만 색상 표시
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Color(0xFFF0F6FF), // 시작 색상 - 매우 밝은 파란색
                                Color(0xFF5D9EFF), // 끝 색상 - 밝은 파란색
                              ],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),

                      // 사용자 위치 포인트
                      Positioned(
                        left: userPosition - 6,
                        top: -2,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Color(0xFF5D9EFF),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),

                      // 친구 위치 포인트
                      Positioned(
                        left: friendPosition - 6,
                        top: -2,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Color(0xFF5D9EFF),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // 내 프로필 - 위치 조정 (30% 지점에 배치)
          Positioned(
            left:
                (MediaQuery.of(context).size.width - 80) * 0.3 -
                20, // 왼쪽 기준으로 조정
            top: 0,
            child: _buildProfileButton(
              context,
              "나",
              onTap: () {
                _handleProfileTap(context, "나");
              },
            ),
          ),

          // 친구 프로필 - 위치 조정 (50% 지점에 배치)
          Positioned(
            left:
                (MediaQuery.of(context).size.width - 80) * 0.5 -
                20, // 왼쪽 기준으로 조정
            top: 0,
            child: _buildProfileButton(
              context,
              missionData.friends[0]['name'], // 첫번째 친구 이름
              width: 60,
              onTap: () {
                _handleProfileTap(context, missionData.friends[0]['name']);
              },
            ),
          ),

          // 훔쳐보기 버튼
          Positioned(
            right: 0,
            top: 5, // 프로필과 비슷한 높이로 조정
            child: Container(
              width: 75,
              height: 36,
              decoration: BoxDecoration(
                color: Color(0xFF89DA8D), // 밝은 녹색
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextButton(
                onPressed: () {
                  // 훔쳐보기 버튼 기능
                },
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  '훔쳐보기',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 프로필 버튼 생성 메서드
  Widget _buildProfileButton(
    BuildContext context,
    String name, {
    double width = 45,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 2,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/logos/search-sm.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          SizedBox(height: 5),
          Container(
            width: width,
            height: 25,
            decoration: BoxDecoration(
              border: Border.all(color: Color(0xFF89DA8D), width: 1),
              borderRadius: BorderRadius.circular(4),
            ),
            alignment: Alignment.center,
            child: Text(
              name,
              style: TextStyle(fontSize: 12, color: Color(0xFF89DA8D)),
            ),
          ),
        ],
      ),
    );
  }

  // 프로필 탭 핸들러
  void _handleProfileTap(BuildContext context, String name) {
    if (name == "나") {
      // 내 프로필 탭 시
      _updateMissionDataState(context, "나");
    } else {
      // 친구 프로필 탭 시
      _updateMissionDataState(context, name);
    }
  }

  // 미션 데이터 상태 업데이트
  void _updateMissionDataState(BuildContext context, String name) {
    // 상태 업데이트 함수가 필요함
    // 여기서는 StatelessWidget이므로 상위 위젯에서 처리해야 함
    // 임시적인 방법으로 StatefulBuilder와 같이 쓰거나 callback을 사용해야 함
  }
}
