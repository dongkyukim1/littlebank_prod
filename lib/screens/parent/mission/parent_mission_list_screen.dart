import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../services/mission_service.dart';
import '../../../services/auth_service.dart';
import '../../../theme/app_colors.dart';

class ParentMissionListScreen extends StatefulWidget {
  final Map<String, dynamic>? selectedChild;

  const ParentMissionListScreen({super.key, this.selectedChild});

  @override
  State<ParentMissionListScreen> createState() =>
      _ParentMissionListScreenState();
}

class _ParentMissionListScreenState extends State<ParentMissionListScreen> {
  String selectedFilter = '전체';
  String selectedSort = '보상금이 높은 순';

  // API에서 가져온 미션 데이터
  List<MissionResponse> _allMissions = [];
  List<MissionResponse> missions = [];
  bool _isLoading = true;
  Map<String, dynamic>? _selectedChild;

  @override
  void initState() {
    super.initState();
    _selectedChild = widget.selectedChild;
    _loadParentMissions();
  }

  Future<void> _loadParentMissions() async {
    if (_selectedChild == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      final childId =
          _selectedChild!['userId'] ?? _selectedChild!['familyMemberId'];

      if (childId == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final result = await MissionService.getParentChildMissions(
        childId: childId,
        page: 0,
      );

      if (result != null) {
        final List<dynamic> missionData = result['data'] ?? [];

        // 참여중인 미션들 필터링 (ACCEPT 상태만 - 승인된 미션만 표시)
        final List<MissionResponse> acceptedMissions =
            missionData
                .map((json) => MissionResponse.fromJson(json))
                .where((mission) => mission.status == MissionStatus.ACCEPT)
                .toList();

        setState(() {
          _allMissions = acceptedMissions;
          missions = List.from(_allMissions);
          _isLoading = false;
        });

        // 초기 필터 및 정렬 적용
        _filterMissions();
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('부모 미션 로딩 중 오류: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // D-Day 계산
  int _calculateDDay(DateTime endDate) {
    final now = DateTime.now();
    final difference = endDate.difference(now).inDays;
    return difference < 0 ? 0 : difference;
  }

  // 미션 시작일로부터 경과일 계산
  int _calculateElapsedDays(DateTime startDate) {
    final now = DateTime.now();
    final difference = now.difference(startDate).inDays;
    return difference < 0 ? 0 : difference + 1; // 시작일도 포함하므로 +1
  }

  // 진행률 계산
  double _calculateProgress(DateTime startDate, DateTime endDate) {
    final now = DateTime.now();
    final totalDays = endDate.difference(startDate).inDays;
    final elapsedDays = now.difference(startDate).inDays;

    if (totalDays <= 0) return 0.0;
    if (elapsedDays <= 0) return 0.0;
    if (elapsedDays >= totalDays) return 1.0;

    return elapsedDays / totalDays;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE7ECF6),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = constraints.maxWidth;
          final screenHeight = constraints.maxHeight;
          final isTablet = screenWidth > 600;

          return SafeArea(
            child: Column(
              children: [
                // 상단 헤더
                _buildHeader(context, screenWidth, isTablet),

                // 스크롤 가능한 메인 콘텐츠
                Expanded(
                  child:
                      _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : _buildMainContent(
                            screenWidth,
                            screenHeight,
                            isTablet,
                          ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, double screenWidth, bool isTablet) {
    return Container(
      width: double.infinity,
      height: isTablet ? 70 : 56,
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Image.asset(
              'assets/icons/parent/뒤로가기.png',
              width: isTablet ? 28 : 24,
              height: isTablet ? 28 : 24,
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                '참여 중인 미션',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: isTablet ? 18 : 14,
                  fontFamily: 'Pretendard-Bold',
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.32,
                ),
              ),
            ),
          ),
          SizedBox(width: isTablet ? 28 : 24),
        ],
      ),
    );
  }

  Widget _buildMainContent(
    double screenWidth,
    double screenHeight,
    bool isTablet,
  ) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.04,
        vertical: 6,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 탭 필터 (전체, 가족 미션, 학원 미션)
          _buildFilterTabs(screenWidth, isTablet),

          SizedBox(height: screenHeight * 0.005),

          // 정렬 옵션 (보상금이 높은 순, 최신순, 종료일이 가까운)
          _buildSortingOptions(screenWidth, isTablet),

          SizedBox(height: screenHeight * 0.01),

          // 참여 중인 미션 수 표시
          _buildMissionCount(screenWidth, isTablet),

          SizedBox(height: screenHeight * 0.015),

          // 미션 카드 리스트
          _buildMissionList(screenWidth, screenHeight, isTablet),
        ],
      ),
    );
  }

  Widget _buildFilterTabs(double screenWidth, bool isTablet) {
    return Container(
      width: double.infinity,
      child: Row(
        children: [
          Flexible(child: _buildFilterTab('전체', screenWidth / 3, isTablet)),
          Flexible(child: _buildFilterTab('가족 미션', screenWidth / 3, isTablet)),
          Flexible(child: _buildFilterTab('학원 미션', screenWidth / 3, isTablet)),
        ],
      ),
    );
  }

  Widget _buildSortingOptions(double screenWidth, bool isTablet) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.04,
        vertical: isTablet ? 16 : 12,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSortOption('보상금이 높은 순', isTablet),
            SizedBox(width: screenWidth * 0.03),
            _buildSortOption('최신순', isTablet),
            SizedBox(width: screenWidth * 0.03),
            _buildSortOption('종료일이 가까운', isTablet),
          ],
        ),
      ),
    );
  }

  Widget _buildMissionCount(double screenWidth, bool isTablet) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
      child: RichText(
        text: TextSpan(
          text: '지금 ${_selectedChild?['name'] ?? '자녀'}가 참여 중인 미션은 ',
          style: TextStyle(
            color: const Color(0xFF202020),
            fontSize: isTablet ? 20 : 16,
            fontFamily: 'Pretendard-Bold',
            fontWeight: FontWeight.w700,
            height: 1.50,
            letterSpacing: -0.72,
          ),
          children: [
            TextSpan(
              text: '총 ${missions.length}개',
              style: TextStyle(
                color: const Color(0xFF5D9EFF),
                fontSize: isTablet ? 20 : 16,
                fontFamily: 'Pretendard-Bold',
                fontWeight: FontWeight.w700,
                height: 1.50,
                letterSpacing: -0.72,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMissionList(
    double screenWidth,
    double screenHeight,
    bool isTablet,
  ) {
    if (missions.isEmpty) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(isTablet ? 64 : 48),
        child: Column(
          children: [
            Icon(
              Icons.assignment_outlined,
              size: isTablet ? 80 : 64,
              color: const Color(0xFFCCCCCC),
            ),
            SizedBox(height: isTablet ? 20 : 16),
            Text(
              '참여 중인 미션이 없습니다',
              style: TextStyle(
                color: const Color(0xFF666666),
                fontSize: isTablet ? 16 : 14,
                fontFamily: 'Pretendard-Light',
                letterSpacing: -0.32,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: missions.length,
      itemBuilder: (context, index) {
        final mission = missions[index];
        return _buildMissionCard(mission, screenWidth, screenHeight, isTablet);
      },
    );
  }

  Widget _buildFilterTab(String title, double width, bool isTablet) {
    final isSelected = selectedFilter == title;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedFilter = title;
        });
        _filterMissions();
      },
      child: Container(
        width: width,
        padding: EdgeInsets.symmetric(vertical: isTablet ? 18 : 14),
        decoration: BoxDecoration(
          color: Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: isSelected ? Colors.black : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.black : const Color(0xFF999999),
            fontSize: isTablet ? 16 : 14,
            fontFamily: isSelected ? 'Pretendard-Bold' : 'Pretendard-Light',
            letterSpacing: -0.32,
          ),
        ),
      ),
    );
  }

  Widget _buildSortOption(String title, bool isTablet) {
    final isSelected = selectedSort == title;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedSort = title;
        });
        _sortMissions();
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: isTablet ? 8 : 6,
            height: isTablet ? 8 : 6,
            decoration: BoxDecoration(
              color:
                  isSelected
                      ? const Color(0xFF5D9EFF)
                      : const Color(0xFFB6B6B6),
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: isTablet ? 8 : 6),
          Text(
            title,
            style: TextStyle(
              color:
                  isSelected
                      ? const Color(0xFF001F55)
                      : const Color(0xFFB6B6B6),
              fontSize: isTablet ? 14 : 12,
              fontFamily: isSelected ? 'Pretendard-Medium' : 'Pretendard-Light',
              fontWeight: isSelected ? FontWeight.w500 : FontWeight.w300,
              letterSpacing: -0.28,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissionCard(
    MissionResponse mission,
    double screenWidth,
    double screenHeight,
    bool isTablet,
  ) {
    final dDay = _calculateDDay(mission.endDate);
    final progress = _calculateProgress(mission.startDate, mission.endDate);
    final progressPercent = (progress * 100).toInt();
    final elapsedDays = _calculateElapsedDays(mission.startDate);

    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(
        horizontal: 0,
        vertical: screenHeight * 0.01,
      ),
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: const Color(0x35000000),
            blurRadius: 8,
            offset: const Offset(3, 4),
            spreadRadius: 0,
          ),
        ],
        borderRadius: BorderRadius.circular(24),
      ),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(isTablet ? 16 : 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 12 : 8,
                vertical: isTablet ? 6 : 4,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF5D9EFF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                MissionService.getTypeDisplayName(mission.type),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isTablet ? 12 : 10,
                  fontFamily: 'Pretendard-Light',
                  fontWeight: FontWeight.w300,
                  letterSpacing: -0.24,
                ),
              ),
            ),
            SizedBox(height: isTablet ? 16 : 12),
            Text(
              mission.title,
              style: TextStyle(
                color: const Color(0xFF353535),
                fontSize: isTablet ? 18 : 14,
                fontFamily: 'Pretendard-Bold',
                fontWeight: FontWeight.w700,
                letterSpacing: -0.32,
              ),
            ),

            SizedBox(height: isTablet ? 16 : 12),

            // 개선된 프로그레스바 (퍼센트 말풍선 포함)
            _buildProgressBarWithPercentage(
              progress,
              progressPercent,
              screenWidth,
              isTablet,
            ),

            SizedBox(height: isTablet ? 16 : 12),

            // 통계 정보
            Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.02),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatItem('시작한 지', '${elapsedDays}일째', isTablet),
                  Container(
                    width: 1,
                    height: isTablet ? 40 : 32,
                    color: const Color(0xFFE7ECF6),
                  ),
                  _buildStatItem('보상금', '${mission.reward}원', isTablet),
                  Container(
                    width: 1,
                    height: isTablet ? 40 : 32,
                    color: const Color(0xFFE7ECF6),
                  ),
                  _buildStatItem(
                    '보상 지급까지',
                    dDay > 0 ? 'D-$dDay' : '완료',
                    isTablet,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBarWithPercentage(
    double progress,
    int progressPercent,
    double screenWidth,
    bool isTablet,
  ) {
    final progressBarWidth = screenWidth * 0.8; // 가로길이 늘림
    final progressBarHeight = isTablet ? 16.0 : 16.0; // 굵기 2분의1로 줄임
    final progressWidth = progressBarWidth * progress;

    return Column(
      children: [
        // 퍼센트 말풍선을 진행률에 맞는 위치에
        Container(
          width: progressBarWidth,
          height: isTablet ? 40 : 35,
          child: Stack(
            children: [
              // 퍼센트 말풍선
              Positioned(
                left: (progressWidth - (isTablet ? 25 : 20)).clamp(
                  0.0,
                  progressBarWidth - (isTablet ? 50 : 40),
                ),
                top: 0,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isTablet ? 12 : 8,
                        vertical: isTablet ? 4 : 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF5D9EFF),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '$progressPercent%',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isTablet ? 11 : 9,
                          fontFamily: 'Pretendard-Medium',
                          fontWeight: FontWeight.w500,
                          letterSpacing: -0.22,
                        ),
                      ),
                    ),
                    // 아래 향하는 삼각형
                    CustomPaint(
                      size: Size(isTablet ? 12 : 10, isTablet ? 6 : 5),
                      painter: TrianglePainter(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: isTablet ? 4 : 3),

        // 프로그레스바
        Container(
          width: progressBarWidth,
          height: progressBarHeight * 1.5,
          child: Stack(
            children: [
              // 배경 프로그레스바
              Positioned(
                top: (progressBarHeight * 1.5 - progressBarHeight) / 2,
                child: Container(
                  width: progressBarWidth,
                  height: progressBarHeight,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE4ECF8),
                    borderRadius: BorderRadius.circular(progressBarHeight / 2),
                  ),
                ),
              ),

              // 진행률 프로그레스바 (그라데이션)
              Positioned(
                top: (progressBarHeight * 1.5 - progressBarHeight) / 2,
                child: Container(
                  width: progressWidth,
                  height: progressBarHeight,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment(1.04, 1.00),
                      end: Alignment(-0.43, -0.31),
                      colors: [Color(0xFF5D9EFF), Color(0xFF10CB86)],
                    ),
                    borderRadius: BorderRadius.circular(progressBarHeight / 2),
                  ),
                ),
              ),

              // 트로피 이미지 (항상 오른쪽 끝에 위치, 중앙 정렬)
              Positioned(
                right: 0,
                top: 0,
                child: Image.asset(
                  'assets/icons/parent/mission/tropy.png',
                  width: progressBarHeight * 1.5,
                  height: progressBarHeight * 1.5,
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar(double progress, double screenWidth, bool isTablet) {
    final progressBarWidth = screenWidth * 0.8; // 가로길이 늘림
    final progressBarHeight = isTablet ? 16.0 : 16.0; // 굵기 2분의1로 줄임
    final progressWidth = progressBarWidth * progress;

    return Container(
      width: progressBarWidth,
      height: progressBarHeight * 1.5,
      child: Stack(
        children: [
          // 배경 프로그레스바
          Positioned(
            top: (progressBarHeight * 1.5 - progressBarHeight) / 2,
            child: Container(
              width: progressBarWidth,
              height: progressBarHeight,
              decoration: BoxDecoration(
                color: const Color(0xFFE4ECF8),
                borderRadius: BorderRadius.circular(progressBarHeight / 2),
              ),
            ),
          ),

          // 진행률 프로그레스바 (그라데이션)
          Positioned(
            top: (progressBarHeight * 1.5 - progressBarHeight) / 2,
            child: Container(
              width: progressWidth,
              height: progressBarHeight,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment(1.04, 1.00),
                  end: Alignment(-0.43, -0.31),
                  colors: [Color(0xFF5D9EFF), Color(0xFF10CB86)],
                ),
                borderRadius: BorderRadius.circular(progressBarHeight / 2),
              ),
            ),
          ),

          // 트로피 이미지 (항상 오른쪽 끝에 위치, 중앙 정렬)
          Positioned(
            right: 0,
            top: 0,
            child: Image.asset(
              'assets/icons/parent/mission/tropy.png',
              width: progressBarHeight * 1.5,
              height: progressBarHeight * 1.5,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, bool isTablet) {
    return Flexible(
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: const Color(0xFF666666),
              fontSize: isTablet ? 14 : 12,
              fontFamily: 'Pretendard-Light',
              fontWeight: FontWeight.w300,
              letterSpacing: -0.28,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isTablet ? 10 : 8),
          Text(
            value,
            style: TextStyle(
              color: const Color(0xFF5D9EFF),
              fontSize: isTablet ? 18 : 14,
              fontFamily: 'Pretendard-Bold',
              fontWeight: FontWeight.w700,
              letterSpacing: -0.32,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _filterMissions() {
    List<MissionResponse> filteredMissions = List.from(_allMissions);

    if (selectedFilter != '전체') {
      if (selectedFilter == '가족 미션') {
        filteredMissions =
            filteredMissions
                .where((mission) => mission.type == MissionType.FAMILY)
                .toList();
      } else if (selectedFilter == '학원 미션') {
        filteredMissions =
            filteredMissions
                .where((mission) => mission.type == MissionType.ACADEMY)
                .toList();
      }
    }

    setState(() {
      missions = filteredMissions;
    });

    _sortMissions();
  }

  void _sortMissions() {
    if (selectedSort == '보상금이 높은 순') {
      missions.sort((a, b) => b.reward.compareTo(a.reward));
    } else if (selectedSort == '최신순') {
      missions.sort((a, b) => b.startDate.compareTo(a.startDate));
    } else if (selectedSort == '종료일이 가까운') {
      missions.sort((a, b) => a.endDate.compareTo(b.endDate));
    }

    setState(() {});
  }
}

class TrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint =
        Paint()
          ..color = const Color(0xFF5D9EFF)
          ..style = PaintingStyle.fill;

    final Path path = Path();
    path.moveTo(size.width / 2, size.height); // 아래 중앙
    path.lineTo(0, 0); // 왼쪽 위
    path.lineTo(size.width, 0); // 오른쪽 위
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
