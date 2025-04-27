import 'package:flutter/material.dart';
import '../../widgets/parent/bottom_navigation_bar.dart';
import 'widgets/mission_section.dart';

class ParentMissionScreen extends StatefulWidget {
  const ParentMissionScreen({super.key});

  @override
  State<ParentMissionScreen> createState() => _ParentMissionScreenState();
}

class _ParentMissionScreenState extends State<ParentMissionScreen> {
  final List<MissionItem> _recentMissions = [
    MissionItem(
      type: '개인 미션',
      title: '수학 5단원까지 풀어오기',
      reward: '30,000원',
      status: '완료',
      date: '03.20 - 03.27',
    ),
    MissionItem(
      type: '가족 미션',
      title: '3시간 동안 수학 공부',
      reward: '53,000원',
      status: '진행중',
      date: '04.05 - 04.12',
    ),
    MissionItem(
      type: '학원 미션',
      title: '영어 단어 100개 암기',
      reward: '42,000원',
      status: '대기중',
      date: '04.15 - 04.22',
    ),
  ];
  
  final List<MissionItem> _completedMissions = [
    MissionItem(
      type: '개인 미션',
      title: '수학 5단원까지 풀어오기',
      reward: '30,000원',
      status: '완료',
      date: '03.20 - 03.27',
    ),
    MissionItem(
      type: '학원 미션',
      title: '영어 시험 90점 이상 받기',
      reward: '25,000원',
      status: '완료',
      date: '03.10 - 03.17',
    ),
  ];

  // 완료된 미션 표시 여부를 제어하는 변수 추가
  bool _showCompletedMissions = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE7ECF6),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      _buildMissionHeader(),
                      const SizedBox(height: 16),
                      _buildMissionProgressCard(),
                      const SizedBox(height: 16),
                      _buildRecentMissionsSection(),
                      const SizedBox(height: 16),
                      _buildCompletedMissionsSection(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showMissionCreationModal,
        backgroundColor: const Color(0xFF146AFF),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: const ParentBottomNavigationBar(selectedIndex: 2),
    );
  }
  
  // 앱바 위젯 구현
  Widget _buildAppBar() {
    return Container(
      width: double.infinity,
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      color: const Color(0xFFE7ECF6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 왼쪽 로고
          Image.asset(
            'assets/logos/parent_logo.png',
            width: 28,
            height: 28,
            fit: BoxFit.contain,
          ),
          
          // 오른쪽 아이콘들 (프로필 및 알림)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 알림 아이콘
              SizedBox(
                width: 24,
                height: 24,
                child: Icon(
                  Icons.notifications_none_rounded,
                  color: Colors.black,
                  size: 25,
                ),
              ),
              
              // 프로필 아이콘
              Container(
                width: 32,
                height: 32,
                margin: const EdgeInsets.only(left: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDC963),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 1.5,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: const Center(
                    child: Text(
                      '부',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  // 미션 헤더 위젯
  Widget _buildMissionHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 0,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '미션 관리',
            style: TextStyle(
              color: const Color(0xFF202020),
              fontSize: 20,
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '자녀에게 미션을 만들고 보상을 설정해보세요',
            style: TextStyle(
              color: const Color(0xFF666666),
              fontSize: 14,
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _showMissionCreationModal,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF146AFF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '새 미션 만들기',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontFamily: 'Pretendard',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  // 미션 진행 상황 카드
  Widget _buildMissionProgressCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 0,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 상단 헤더 영역
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 왼쪽 제목 영역
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              '우리 아이가 참여 중인 미션 ',
                              style: TextStyle(
                                color: const Color(0xFF202020),
                                fontSize: 16,
                                fontFamily: 'Pretendard',
                                fontWeight: FontWeight.w700,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '3',
                            style: TextStyle(
                              color: const Color(0xFF146AFF),
                              fontSize: 16,
                              fontFamily: 'Pretendard',
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Text(
                        '가장 최근에 참여한 미션부터 보여드려요',
                        style: TextStyle(
                          color: const Color(0xFF999999),
                          fontSize: 12,
                          fontFamily: 'Pretendard',
                          fontWeight: FontWeight.w300,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                
                // 오른쪽 버튼 영역
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: ShapeDecoration(
                      color: const Color(0xFFF5F6F8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(
                      '전체보기',
                      style: TextStyle(
                        color: const Color(0xFF001F55),
                        fontSize: 12,
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // 미션 내용 영역
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 미션 태그 영역
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // 3월 셋째주 미션 태그
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: ShapeDecoration(
                          color: const Color(0xFF5D9EFF),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                        ),
                        child: Text(
                          '3월 셋째주 미션',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontFamily: 'Pretendard',
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                      
                      const SizedBox(width: 8),
                      
                      // 학원 미션 태그
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: ShapeDecoration(
                          color: const Color(0xFF5D9EFF),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                        ),
                        child: Text(
                          '학원 미션',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontFamily: 'Pretendard',
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                      
                      const SizedBox(width: 8),
                      
                      // D-5 태그
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: ShapeDecoration(
                          color: const Color(0xFFF5F6F8), // Grayscale/Background Gray 1
                          shape: RoundedRectangleBorder(
                            side: BorderSide(
                              width: 0.5,
                              color: const Color(0xFF89DA8D),
                            ),
                            borderRadius: BorderRadius.circular(50),
                          ),
                        ),
                        child: Text(
                          'D-5',
                          style: TextStyle(
                            color: const Color(0xFF89DA8D),
                            fontSize: 12,
                            fontFamily: 'Pretendard',
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // 미션 제목
                Text(
                  '수학 5단원까지 풀어오기',
                  style: TextStyle(
                    color: const Color(0xFF353535),
                    fontSize: 18,
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w700,
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // 프로그레스바 및 체크포인트 영역
                SizedBox(
                  height: 80,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final barWidth = constraints.maxWidth;
                      // 60% 지점의 x 좌표 계산
                      final position60Percent = barWidth * 0.6;
                      
                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // 배경바
                          Positioned(
                            top: 36,
                            left: 18, // 첫 번째 원의 반지름만큼 이동
                            child: Container(
                              width: barWidth - 36, // 양쪽 원의 크기만큼 줄임
                              height: 6,
                              decoration: BoxDecoration(
                                color: const Color(0xFFDDDDDD),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                          
                          // 진행바 (60%)
                          Positioned(
                            top: 36,
                            left: 18, // 첫 번째 원의 반지름만큼 이동
                            child: Container(
                              width: (barWidth - 36) * 0.6, // 축소된 프로그레스바의 60%
                              height: 6,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  colors: [
                                    const Color(0xFF5D9EFF),
                                    const Color(0xFF5D9EFF).withOpacity(0.6),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                          
                          // 60% 달성 중 표시 - 60% 지점 위에 정확히 배치
                          Positioned(
                            left: 18 + (barWidth - 36) * 0.6 - 30, // 조정된 60% 위치
                            top: -15,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: ShapeDecoration(
                                color: const Color(0xFFFFD27F),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                              ),
                              child: Text(
                                '60% 달성 중',
                                style: TextStyle(
                                  color: const Color(0xFF001F55),
                                  fontSize: 10,
                                  fontFamily: 'Pretendard',
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                          
                          // 0% 포인트
                          Positioned(
                            left: 0, // 0% 위치에 정확히 배치
                            top: 18,
                            child: _buildProgressPoint(true),
                          ),
                          
                          // 25% 포인트
                          Positioned(
                            left: 18 + (barWidth - 36) * 0.25 - 18, // 조정된 25% 위치
                            top: 18,
                            child: _buildProgressPoint(true),
                          ),
                          
                          // 50% 포인트
                          Positioned(
                            left: 18 + (barWidth - 36) * 0.5 - 18, // 조정된 50% 위치
                            top: 18,
                            child: _buildProgressPoint(true),
                          ),
                          
                          // 75% 포인트
                          Positioned(
                            left: 18 + (barWidth - 36) * 0.75 - 18, // 조정된 75% 위치
                            top: 18,
                            child: _buildProgressPoint(false),
                          ),
                          
                          // 100% 포인트
                          Positioned(
                            left: barWidth - 36, // 100% 위치에 정확히 배치
                            top: 18,
                            child: _buildProgressPoint(false),
                          ),
                          
                          // 200,000원 텍스트 - 우측 하단에 배치
                          Positioned(
                            right: -10,
                            bottom: 0,
                            child: Text(
                              '200,000원',
                              style: TextStyle(
                                color: const Color(0xFF001F55),
                                fontSize: 12,
                                fontFamily: 'Pretendard',
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // 페이지 인디케이터
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: ShapeDecoration(
                          color: const Color(0xFF5D9EFF),
                          shape: OvalBorder(),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: ShapeDecoration(
                          color: const Color(0xFFDDDDDD),
                          shape: OvalBorder(),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: ShapeDecoration(
                          color: const Color(0xFFDDDDDD),
                          shape: OvalBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  // 진행 체크포인트 위젯
  Widget _buildProgressPoint(bool isCompleted) {
    final Color outerColor = isCompleted ? const Color(0xFF5D9EFF).withOpacity(0.3) : const Color(0xFFDDDDDD).withOpacity(0.3);
    final Color innerColor = isCompleted ? const Color(0xFF5D9EFF) : const Color(0xFFDDDDDD);
    
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: outerColor,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 내부 원
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: innerColor,
                shape: BoxShape.circle,
              ),
            ),
            
            // 깃발 이미지
            Image.asset(
              'assets/images/flag_parent.png',
              width: 14,
              height: 14,
              color: Colors.white,
              fit: BoxFit.contain,
            ),
          ],
        ),
      ),
    );
  }
  
  // 최근 미션 섹션
  Widget _buildRecentMissionsSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 0,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더 영역
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 최근 미션 제목과 개수
              Row(
                children: [
                  Text(
                    '최근 미션 ',
                    style: TextStyle(
                      color: const Color(0xFF202020),
                      fontSize: 18,
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '${_recentMissions.length}',
                    style: TextStyle(
                      color: const Color(0xFF146AFF),
                      fontSize: 18,
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              // 전체보기 버튼
              Text(
                '전체보기',
                style: TextStyle(
                  color: const Color(0xFF666666),
                  fontSize: 14,
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w400,
                  decoration: TextDecoration.underline,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          ..._recentMissions.map((mission) => _buildMissionItem(mission)),
        ],
      ),
    );
  }
  
  // 완료된 미션 섹션
  Widget _buildCompletedMissionsSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 0,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더 영역
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 완료된 미션 제목과 개수
              Row(
                children: [
                  Text(
                    '완료된 미션 ',
                    style: TextStyle(
                      color: const Color(0xFF202020),
                      fontSize: 18,
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '${_completedMissions.length}',
                    style: TextStyle(
                      color: const Color(0xFF146AFF),
                      fontSize: 18,
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              // 전체보기 버튼
              GestureDetector(
                onTap: () {
                  setState(() {
                    _showCompletedMissions = !_showCompletedMissions;
                  });
                },
                child: Text(
                  _showCompletedMissions ? '접기' : '전체보기',
                  style: TextStyle(
                    color: const Color(0xFF666666),
                    fontSize: 14,
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w400,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
          
          // 미션 목록 (전체보기 클릭 시에만 표시)
          if (_showCompletedMissions) ...[
            const SizedBox(height: 16),
            ..._completedMissions.map((mission) => _buildMissionItem(mission)),
          ],
        ],
      ),
    );
  }
  
  // 미션 아이템 위젯
  Widget _buildMissionItem(MissionItem mission) {
    Color statusColor;
    Color statusBackgroundColor;
    
    switch (mission.status) {
      case '완료':
        statusColor = const Color(0xFF146AFF);
        statusBackgroundColor = const Color(0xFFE6F0FF);
        break;
      case '진행중':
        statusColor = const Color(0xFF00A86B);
        statusBackgroundColor = const Color(0xFFE6F8F1);
        break;
      case '대기중':
        statusColor = const Color(0xFFFFA63D);
        statusBackgroundColor = const Color(0xFFFFF5E9);
        break;
      default:
        statusColor = const Color(0xFF666666);
        statusBackgroundColor = const Color(0xFFF2F2F2);
    }
    
    Color typeColor;
    switch (mission.type) {
      case '개인 미션':
        typeColor = const Color(0xFF5D9EFF);
        break;
      case '가족 미션':
        typeColor = const Color(0xFFFF9E5D);
        break;
      case '학원 미션':
        typeColor = const Color(0xFF9E5DFF);
        break;
      default:
        typeColor = const Color(0xFF5D9EFF);
    }
    
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 0,
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: typeColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  mission.type,
                  style: TextStyle(
                    color: typeColor,
                    fontSize: 12,
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBackgroundColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  mission.status,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            mission.title,
            style: TextStyle(
              color: const Color(0xFF202020),
              fontSize: 16,
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '기간: ${mission.date}',
                style: TextStyle(
                  color: const Color(0xFF666666),
                  fontSize: 14,
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w400,
                ),
              ),
              Row(
                children: [
                  Text(
                    '보상: ',
                    style: TextStyle(
                      color: const Color(0xFF666666),
                      fontSize: 14,
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  Text(
                    mission.reward,
                    style: TextStyle(
                      color: const Color(0xFF146AFF),
                      fontSize: 14,
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  // 미션 생성 모달 표시
  void _showMissionCreationModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return const MissionCreationModal();
      },
    );
  }
}

class MissionItem {
  final String type;
  final String title;
  final String reward;
  final String status;
  final String date;

  MissionItem({
    required this.type,
    required this.title,
    required this.reward,
    required this.status,
    required this.date,
  });
} 