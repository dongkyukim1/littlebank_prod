import 'package:flutter/material.dart';
import '../../screens/child/mission/participating_missions_list_screen.dart';
import '../../services/mission_service.dart';

class ParticipatingMissionSection extends StatefulWidget {
  final bool showMissions;
  final Function(bool) onToggleChanged;

  const ParticipatingMissionSection({
    super.key,
    required this.showMissions,
    required this.onToggleChanged,
  });

  @override
  State<ParticipatingMissionSection> createState() => _ParticipatingMissionSectionState();
}

class _ParticipatingMissionSectionState extends State<ParticipatingMissionSection> {
  List<MissionResponse> _participatingMissions = [];
  bool _isLoading = true;
  int _currentMissionIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadParticipatingMissions();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadParticipatingMissions() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final result = await MissionService.getChildMissions(page: 0);
      
      if (result != null) {
        final List<dynamic> missionData = result['data'] ?? [];
        
        // 참여중인 미션들 필터링 (ACCEPT 상태만 - 승인된 미션만 표시)
        final List<MissionResponse> participatingMissions = missionData
            .map((json) => MissionResponse.fromJson(json))
            .where((mission) => mission.status == MissionStatus.ACCEPT)
            .toList();

        setState(() {
          _participatingMissions = participatingMissions;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('참여중인 미션 로딩 중 오류: $e');
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

  // 진행률 계산 (임시로 날짜 기준으로 계산)
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
    double screenWidth = MediaQuery.of(context).size.width;
    double cardWidth = screenWidth - 32; // 좌우 마진 16씩
    double progressBarWidth = cardWidth - 40; // 좌우 패딩 20씩

    if (_isLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Material(
          elevation: 3,
          shadowColor: Colors.black54,
          borderRadius: const BorderRadius.all(Radius.circular(24)),
          child: Container(
            width: cardWidth,
            height: 270,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(24)),
            ),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
        ),
      );
    }

    if (_participatingMissions.isEmpty) {
      // 참여중인 미션이 없을 때 EmptyMissionSection으로 전환
      widget.onToggleChanged(false);
      return const SizedBox.shrink();
    }



    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        elevation: 3, 
        shadowColor: Colors.black54, 
        borderRadius: const BorderRadius.all(Radius.circular(24)),
        child: Container(
          width: cardWidth,
          height: 270, // 높이 증가
          margin: const EdgeInsets.all(0), // margin 제거 - Material 안에 있기 때문
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.all(Radius.circular(24)),
            // boxShadow 제거 - Material에서 그림자 처리
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 상단 섹션
              Container(
                width: cardWidth,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Stack(
                  children: [
                    // 제목 섹션
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              '지금 내가 참여 중인 미션',
                              style: TextStyle(
                                color: Color(0xFF202020),
                                fontSize: 16,
                                fontFamily: 'Pretendard-Bold',
                                letterSpacing: -0.72,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${_participatingMissions.length}',
                              style: const TextStyle(
                                color: Color(0xFF146AFF),
                                fontSize: 16,
                                fontFamily: 'Pretendard-Bold',
                                letterSpacing: -0.72,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          '최근 순으로 보여집니다.',
                          style: TextStyle(
                            color: Color(0xFF999999),
                            fontSize: 12,
                            fontFamily: 'Pretendard-Light',
                            letterSpacing: -0.24,
                          ),
                        ),
                      ],
                    ),

                    // 전체보기 버튼
                    Positioned(
                      right: 0,
                      top: 0,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const ParticipatingMissionsListScreen(),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: ShapeDecoration(
                            color: const Color(0xFFEFF2F6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            '전체보기',
                            style: TextStyle(
                              color: Color(0xFF001F55),
                              fontSize: 12,
                              fontFamily: 'Pretendard-Medium',
                              letterSpacing: -0.24,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // PageView로 미션 내용과 프로그레스를 감싸기
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _participatingMissions.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentMissionIndex = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    final currentMission = _participatingMissions[index];
                    final dDay = _calculateDDay(currentMission.endDate);
                    final progress = _calculateProgress(currentMission.startDate, currentMission.endDate);
                    final progressPercent = (progress * 100).toInt();

                    return Column(
                      children: [
                        // 미션 내용 섹션
                        Container(
                          width: cardWidth,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 태그 영역
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    // 미션 타입 태그
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: ShapeDecoration(
                                        color: const Color(0xFF5D9EFF),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: Text(
                                        MissionService.getTypeDisplayName(currentMission.type),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontFamily: 'Pretendard-Light',
                                          letterSpacing: -0.24,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),

                                    // 카테고리 태그
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: ShapeDecoration(
                                        color: const Color(0xFF5D9EFF),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: Text(
                                        currentMission.category == MissionCategory.LEARNING ? '학습' : '습관',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontFamily: 'Pretendard-Light',
                                          letterSpacing: -0.24,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),

                                    // 과목 태그 (학습인증일 경우)
                                    if (currentMission.category == MissionCategory.LEARNING && currentMission.subject != null) ...[
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: ShapeDecoration(
                                          color: const Color(0xFF5D9EFF),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                        child: Text(
                                          MissionService.getSubjectDisplayName(
                                            MissionSubject.values.firstWhere(
                                              (e) => e.name == currentMission.subject,
                                              orElse: () => MissionSubject.KOREAN,
                                            ),
                                          ),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontFamily: 'Pretendard-Light',
                                            letterSpacing: -0.24,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                    ],

                                    // D-day 태그
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: ShapeDecoration(
                                        color: const Color(0xFFFFD27F),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: Text.rich(
                                        TextSpan(
                                          children: [
                                            const TextSpan(
                                              text: '완료까지 ',
                                              style: TextStyle(
                                                color: Color(0xFF001F55),
                                                fontSize: 10,
                                                fontFamily: 'Pretendard-Light',
                                                letterSpacing: -0.24,
                                              ),
                                            ),
                                            TextSpan(
                                              text: 'D-$dDay',
                                              style: const TextStyle(
                                                color: Color(0xFF001F55),
                                                fontSize: 10,
                                                fontFamily: 'Pretendard-Medium',
                                                letterSpacing: -0.24,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),

                              // 미션 제목
                              Text(
                                currentMission.title,
                                style: const TextStyle(
                                  color: Color(0xFF202020),
                                  fontSize: 16,
                                  fontFamily: 'Pretendard-Bold',
                                  letterSpacing: -0.32,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),

                        // 하단 프로그레스 섹션
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const SizedBox(height: 10),

                              // 프로그레스 바와 퍼센트 표시
                              SizedBox(
                                width: progressBarWidth,
                                height: 70, // 말풍선 포함한 높이
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    // 퍼센트 말풍선 표시
                                    Positioned(
                                      left: () {
                                        const double balloonWidth = 48;
                                        const double halfBalloonWidth = balloonWidth / 2;
                                        const double barStartX = 8;
                                        final double barWidth = progressBarWidth - 16;
                                        double balloonCenterX = barStartX + (barWidth * progress);
                                        double balloonLeft = balloonCenterX - halfBalloonWidth;
                                        
                                        if (balloonLeft < 0) balloonLeft = 0;
                                        final double maxLeft = progressBarWidth - balloonWidth;
                                        if (balloonLeft > maxLeft) balloonLeft = maxLeft;
                                        
                                        return balloonLeft;
                                      }(),
                                      top: -10,
                                      child: Column(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF5D9EFF),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              '$progressPercent%',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontFamily: 'Pretendard-Light',
                                              ),
                                            ),
                                          ),
                                          CustomPaint(
                                            size: const Size(14, 7),
                                            painter: TrianglePainter(
                                              color: const Color(0xFF5D9EFF),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // 프로그레스 바 배경
                                    Positioned(
                                      top: 30,
                                      left: 8,
                                      right: 8,
                                      child: Container(
                                        width: progressBarWidth - 16,
                                        height: 15,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE4E4E4),
                                          borderRadius: BorderRadius.circular(7.5),
                                        ),
                                      ),
                                    ),

                                    // 진행 프로그레스 바
                                    Positioned(
                                      top: 30,
                                      left: 8,
                                      child: Container(
                                        width: (progressBarWidth - 16) * progress,
                                        height: 15,
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            begin: Alignment.centerLeft,
                                            end: Alignment.centerRight,
                                            colors: [
                                              Color(0xFF10CB86),
                                              Color(0xFF5D9EFF),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(7.5),
                                        ),
                                      ),
                                    ),

                                    // 점선들
                                    Positioned(
                                      left: 8 + (progressBarWidth - 16) * 0.25 - 1,
                                      top: 30,
                                      height: 15,
                                      child: _buildEnhancedVerticalDashedLine(),
                                    ),
                                    Positioned(
                                      left: 8 + (progressBarWidth - 16) * 0.5 - 1,
                                      top: 30,
                                      height: 15,
                                      child: _buildEnhancedVerticalDashedLine(),
                                    ),
                                    Positioned(
                                      left: 8 + (progressBarWidth - 16) * 0.75 - 1,
                                      top: 30,
                                      height: 15,
                                      child: _buildVerticalDashedLine(),
                                    ),

                                    // 완료 아이콘
                                    Positioned(
                                      left: 8 + (progressBarWidth - 16) - 12,
                                      top: 26,
                                      child: Container(
                                        width: 24,
                                        height: 24,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF3A88F4),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Image.asset(
                                            'assets/icons/Icon/mission/달성.png',
                                            width: 14,
                                            height: 14,
                                            color: Color(0xFFFFD27F),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 10),

                              // 페이지 인디케이터
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ..._participatingMissions.asMap().entries.map((entry) {
                                    final entryIndex = entry.key;
                                    final isActive = entryIndex == _currentMissionIndex;
                                    
                                    return GestureDetector(
                                      onTap: () {
                                        _pageController.animateToPage(
                                          entryIndex,
                                          duration: const Duration(milliseconds: 300),
                                          curve: Curves.easeInOut,
                                        );
                                      },
                                      child: Container(
                                        margin: EdgeInsets.only(right: entryIndex < _participatingMissions.length - 1 ? 4 : 0),
                                        width: isActive ? 28 : 4,
                                        height: 4,
                                        decoration: ShapeDecoration(
                                          color: isActive ? const Color(0xFF5D9EFF) : const Color(0xFFB6B6B6),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
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

  // 세로 점선 위젯 (기본)
  Widget _buildVerticalDashedLine() {
    return SizedBox(
      width: 2, // 선 두께
      child: Column(
        children: [
          Container(width: 2, height: 3, color: Colors.white),
          const SizedBox(height: 2),
          Container(width: 2, height: 3, color: Colors.white),
          const SizedBox(height: 2),
          Container(width: 2, height: 3, color: Colors.white),
        ],
      ),
    );
  }

  // 향상된 세로 점선 위젯 (그라데이션에 가려지지 않도록)
  Widget _buildEnhancedVerticalDashedLine() {
    return SizedBox(
      width: 3, // 선 두께 증가
      child: Column(
        children: [
          Container(
            width: 3,
            height: 3,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.black12, width: 0.5),
              borderRadius: BorderRadius.circular(1.5),
            ),
          ),
          const SizedBox(height: 2),
          Container(
            width: 3,
            height: 3,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.black12, width: 0.5),
              borderRadius: BorderRadius.circular(1.5),
            ),
          ),
          const SizedBox(height: 2),
          Container(
            width: 3,
            height: 3,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.black12, width: 0.5),
              borderRadius: BorderRadius.circular(1.5),
            ),
          ),
        ],
      ),
    );
  }
}

// 삼각형 페인터 (말풍선 화살표용)
class TrianglePainter extends CustomPainter {
  final Color color;

  TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(size.width / 2 - 7, 0);
    path.lineTo(size.width / 2, size.height);
    path.lineTo(size.width / 2 + 7, 0);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
