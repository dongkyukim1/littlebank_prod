import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../services/auth_service.dart';
import '../../../services/mission_service.dart';

/// 아래 방향 삼각형을 그리는 CustomPainter
class TrianglePainter extends CustomPainter {
  final Color color;

  TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(size.width / 2, size.height); // 아래 중앙 (꼭짓점)
    path.lineTo(0, 0); // 왼쪽 위
    path.lineTo(size.width, 0); // 오른쪽 위
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 프로그래스 바의 점선 구분선을 그리는 CustomPainter
class ProgressBarDividerPainter extends CustomPainter {
  final Color color;
  final List<double> percentages; // 구분선 위치 (0.0 ~ 1.0)

  ProgressBarDividerPainter({
    required this.color,
    required this.percentages,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    for (double percentage in percentages) {
      final x = size.width * percentage;
      
      // 점선 그리기
      final dashHeight = 3.0;
      final dashSpace = 2.0;
      double startY = 0;
      
      while (startY < size.height) {
        canvas.drawLine(
          Offset(x, startY),
          Offset(x, (startY + dashHeight).clamp(0, size.height)),
          paint,
        );
        startY += dashHeight + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 과목별 미션 비교 바텀시트
class SubjectComparisonBottomSheet extends StatefulWidget {
  final Map<String, dynamic> friendData;

  const SubjectComparisonBottomSheet({super.key, required this.friendData});

  @override
  State<SubjectComparisonBottomSheet> createState() =>
      _SubjectComparisonBottomSheetState();
}

class _SubjectComparisonBottomSheetState
    extends State<SubjectComparisonBottomSheet> {
  int _selectedTabIndex = 0; // 0: 학습 인증, 1: 습관 형성
  String _selectedSubject = '국어'; // 선택된 과목
  Map<String, dynamic>? _userInfo;
  List<MissionResponse> _missions = []; // 전체 미션 리스트
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // 사용자 정보와 미션 데이터를 병렬로 로딩
      final results = await Future.wait([
        AuthService.getUserInfo(),
        MissionService.getChildMissions(page: 0),
      ]);

      if (mounted) {
        final userInfo = results[0] as Map<String, dynamic>;
        final missionData = results[1] as Map<String, dynamic>?;

        setState(() {
          _userInfo = userInfo;
          if (missionData != null && missionData['data'] != null) {
            final List<dynamic> missionList = missionData['data'];
            _missions =
                missionList
                    .map((mission) => MissionResponse.fromJson(mission))
                    .toList();
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      print('데이터 로딩 오류: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // 과목명을 영어로 변환 (API에서 사용하는 형식)
  String _getSubjectApiName(String koreanSubject) {
    switch (koreanSubject) {
      case '국어':
        return 'KOREAN';
      case '수학':
        return 'MATH';
      case '영어':
        return 'ENGLISH';
      default:
        return 'KOREAN';
    }
  }

  // 선택된 탭과 과목에 따른 미션 필터링
  List<MissionResponse> _getFilteredMissions() {
    final category =
        _selectedTabIndex == 0
            ? MissionCategory.LEARNING
            : MissionCategory.HABIT;
    final subjectApiName = _getSubjectApiName(_selectedSubject);

    return _missions.where((mission) {
      // 카테고리 필터링
      if (mission.category != category) return false;

      // 학습 인증의 경우 과목도 필터링
      if (category == MissionCategory.LEARNING) {
        return mission.subject == subjectApiName;
      }

      // 습관 형성의 경우 과목 무관
      return true;
    }).toList();
  }

  // 완료된 미션 개수 계산
  int _getCompletedMissionCount(List<MissionResponse> missions) {
    final now = DateTime.now();
    return missions.where((mission) {
      return mission.status == MissionStatus.ACHIEVEMENT ||
          (mission.status == MissionStatus.ACCEPT &&
              now.isAfter(mission.endDate));
    }).length;
  }

  // 미션 참여 상태 확인
  bool _hasActiveMissions(List<MissionResponse> missions) {
    return missions
        .where(
          (mission) =>
              mission.status == MissionStatus.ACCEPT ||
              mission.status == MissionStatus.ACHIEVEMENT,
        )
        .isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isTablet = screenWidth > 600;

    // 반응형 값들
    final horizontalPadding = isTablet ? 24.0 : 16.0;
    final titleFontSize = isTablet ? 20.0 : 18.0;
    final subtitleFontSize = isTablet ? 16.0 : 14.0;
    final tabFontSize = isTablet ? 18.0 : 16.0;
    final subjectFontSize = isTablet ? 16.0 : 14.0;
    final profileSize = isTablet ? 40.0 : 32.0;
    final maxHeight = screenHeight * 0.85; // 화면 높이의 85%로 제한

    // 현재 선택된 조건에 따른 미션 데이터
    final filteredMissions = _getFilteredMissions();
    final completedCount = _getCompletedMissionCount(filteredMissions);
    final totalCount = filteredMissions.length;
    final hasActiveMissions = _hasActiveMissions(filteredMissions);

    print('🎯 과목별 미션 데이터:');
    print('   - 선택된 탭: ${_selectedTabIndex == 0 ? "학습인증" : "습관형성"}');
    print('   - 선택된 과목: $_selectedSubject');
    print('   - 필터된 미션 수: ${filteredMissions.length}');
    print('   - 완료된 미션 수: $completedCount');
    print('   - 활성 미션 있음: $hasActiveMissions');

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight, maxWidth: screenWidth),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(horizontalPadding),
              decoration: const ShapeDecoration(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 2), // 6px → 2px로 감소
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${widget.friendData['name'] ?? '친구'}님과 미션 현황 비교',
                          style: TextStyle(
                            color: const Color(0xFF202020),
                            fontSize: titleFontSize - 2,
                            fontFamily: 'Pretendard-Bold',
                            letterSpacing: -0.72,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 24,
                          height: 24,
                          child: const Icon(
                            Icons.close,
                            size: 20,
                            color: Color(0xFF999999),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3), // 6px → 3px로 감소
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '이번 주 미션 현황을 과목별로 비교해 보세요',
                      style: TextStyle(
                        color: const Color(0xFF999999),
                        fontSize: subtitleFontSize,
                        fontFamily: 'Pretendard-Light',
                        letterSpacing: -0.28,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ),
                ],
              ),
            ),

            // 탭 (학습 인증 / 습관 형성)
            Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.only(
                    top: 4, // 8px → 4px로 감소
                  ),
                  decoration: const BoxDecoration(color: Colors.white),
                  child: Row(
                    children: [
                      // 학습 인증 탭
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedTabIndex = 0;
                            });
                          },
                          child: Container(
                            height: 36, // 44px → 36px로 감소
                            child: Center(
                              child: Text(
                                '학습 인증',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color:
                                      _selectedTabIndex == 0
                                          ? const Color(0xFF202020)
                                          : const Color(0xFF999999),
                                  fontSize: tabFontSize - 2,
                                  fontFamily:
                                      _selectedTabIndex == 0
                                          ? 'Pretendard-Bold'
                                          : 'Pretendard-Medium',
                                  letterSpacing: -0.32,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // 습관 형성 탭
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedTabIndex = 1;
                            });
                          },
                          child: Container(
                            height: 36, // 44px → 36px로 감소
                            child: Center(
                              child: Text(
                                '습관 형성',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color:
                                      _selectedTabIndex == 1
                                          ? const Color(0xFF202020)
                                          : const Color(0xFF999999),
                                  fontSize: tabFontSize - 2,
                                  fontFamily:
                                      _selectedTabIndex == 1
                                          ? 'Pretendard-Bold'
                                          : 'Pretendard-Medium',
                                  letterSpacing: -0.32,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // 구분선을 가로 100%로 사용하여 탭과 완벽 정렬
                Container(
                  width: double.infinity,
                  height: 3,
                  decoration: const BoxDecoration(color: Colors.white),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 3,
                          color: _selectedTabIndex == 0 
                              ? const Color(0xFF202020) 
                              : Colors.transparent,
                        ),
                      ),
                      Expanded(
                        child: Container(
                          height: 3,
                          color: _selectedTabIndex == 1 
                              ? const Color(0xFF202020) 
                              : Colors.transparent,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // 과목 선택
            Container(
              width: double.infinity,
              padding: EdgeInsets.only(
                left: horizontalPadding,
                right: horizontalPadding,
                top: 12, // 16px → 12px로 감소
                bottom: 6, // 8px → 6px로 감소
              ),
              decoration: const BoxDecoration(color: Colors.white),
              child: Wrap(
                spacing: isTablet ? 16 : 12,
                runSpacing: 8,
                children:
                    ['국어', '수학', '영어'].map((subject) {
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedSubject = subject;
                          });
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isTablet ? 19 : 16,
                            vertical: isTablet ? 8 : 7,
                          ),
                          decoration: ShapeDecoration(
                            color:
                                _selectedSubject == subject
                                    ? const Color(0xFF3A88F4)
                                    : const Color(0xFFE7ECF6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                          ),
                          child: Text(
                            subject,
                            style: TextStyle(
                              color:
                                  _selectedSubject == subject
                                      ? Colors.white
                                      : const Color(0xFF8490A3),
                              fontSize: subjectFontSize,
                              fontFamily:
                                  _selectedSubject == subject
                                      ? 'Pretendard-Medium'
                                      : 'Pretendard-Light',
                              letterSpacing: -0.28,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
              ),
            ),

            // 비교 내용
            Container(
              width: double.infinity,
              padding: EdgeInsets.only(
                top: 4, // 8px → 4px로 감소
                left: horizontalPadding,
                right: horizontalPadding,
                bottom: 12, // 16px → 12px로 감소
              ),
              decoration: const ShapeDecoration(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(0),
                    bottomRight: Radius.circular(0),
                  ),
                ),
              ),
                              child: Column(
                children: [
                  const SizedBox(height: 8), // 12px → 8px로 감소
                  // 내 정보
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 프로필 섹션 (고정 너비)
                      SizedBox(
                        width: isTablet ? 90 : 70, // 고정 너비 설정
                        child: Column(
                        children: [
                          Container(
                            width: profileSize,
                            height: profileSize,
                            decoration: const ShapeDecoration(
                              shape: OvalBorder(
                                side: BorderSide(
                                  width: 0.80,
                                  color: Color(0xFF146AFF),
                                ),
                              ),
                            ),
                            child: ClipOval(
                              child:
                                  _userInfo != null &&
                                          _userInfo!['profileImagePath'] != null
                                      ? CachedNetworkImage(
                                        imageUrl:
                                            AuthService.getFullProfileImageUrl(
                                              _userInfo!['profileImagePath'],
                                            ),
                                        fit: BoxFit.cover,
                                        width: profileSize,
                                        height: profileSize,
                                        placeholder:
                                            (context, url) => Container(
                                              width: profileSize,
                                              height: profileSize,
                                              color: const Color(0xFFE0E0E0),
                                              child: Icon(
                                                Icons.person,
                                                size: profileSize * 0.6,
                                                color: const Color(0xFF999999),
                                              ),
                                            ),
                                        errorWidget:
                                            (context, url, error) => Container(
                                              width: profileSize,
                                              height: profileSize,
                                              color: const Color(0xFFE0E0E0),
                                              child: Icon(
                                                Icons.person,
                                                size: profileSize * 0.6,
                                                color: const Color(0xFF999999),
                                              ),
                                            ),
                                      )
                                      : Container(
                                        width: profileSize,
                                        height: profileSize,
                                        color: const Color(0xFFE0E0E0),
                                        child: Icon(
                                          Icons.person,
                                          size: profileSize * 0.6,
                                          color: const Color(0xFF999999),
                                        ),
                                      ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: profileSize + 20,
                            child: Text(
                              _userInfo?['name'] ?? '나',
                              style: TextStyle(
                                color: const Color(0xFF202020),
                                fontSize: isTablet ? 14 : 12,
                                fontFamily: 'Pretendard-Bold',
                                letterSpacing: -0.24,
                              ),
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isTablet ? 14 : 12,
                              vertical: isTablet ? 6 : 4,
                            ),
                            decoration: ShapeDecoration(
                              color: const Color(0xFFFFD27F),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child:
                                _isLoading
                                    ? SizedBox(
                                      width: 40,
                                      height: isTablet ? 16 : 14,
                                      child: Center(
                                        child: SizedBox(
                                          width: 12,
                                          height: 12,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 1.5,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  Color(0xFF001F55),
                                                ),
                                          ),
                                        ),
                                      ),
                                    )
                                    : Text.rich(
                                      TextSpan(
                                        children: [
                                          TextSpan(
                                            text: '$completedCount/',
                                            style: TextStyle(
                                              color: const Color(0xFF001F55),
                                                fontSize: isTablet ? 12 : 10, // 2px 감소
                                              fontFamily: 'Pretendard-Bold',
                                              letterSpacing: -0.24,
                                            ),
                                          ),
                                          TextSpan(
                                            text: '${totalCount}개',
                                            style: TextStyle(
                                              color: const Color(0xFF001F55),
                                                fontSize: isTablet ? 12 : 10, // 2px 감소
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
                      const SizedBox(width: 12),
                      // 미션 상태 - 0%일 때와 진행중일 때 구분
                      Expanded(
                                                    child: _isLoading
                                ? Container(
                          constraints: BoxConstraints(
                                      minHeight: isTablet ? 60 : 50, // 높이 감소로 오버플로우 방지
                          ),
                          padding: EdgeInsets.symmetric(
                                      vertical: isTablet ? 8 : 6, // 패딩 감소
                                      horizontal: isTablet ? 12 : 8, // 패딩 감소
                          ),
                          decoration: ShapeDecoration(
                            color: const Color(0xFFE4ECF8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                                    child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(
                                          width: isTablet ? 18 : 16, // 크기 감소
                                          height: isTablet ? 18 : 16, // 크기 감소
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(
                                                Color(0xFF999999),
                                              ),
                                        ),
                                      ),
                                        const SizedBox(height: 6), // 간격 감소
                                      Text(
                                        '데이터 로딩 중...',
                                        style: TextStyle(
                                          color: const Color(0xFF999999),
                                            fontSize: isTablet ? 10 : 8, // 폰트 크기 감소
                                          fontFamily: 'Pretendard-Light',
                                        ),
                                      ),
                                    ],
                                    ),
                                  )
                            : (totalCount == 0 || completedCount == 0)
                                ? Container(
                                                                        constraints: BoxConstraints(
                                      minHeight: isTablet ? 80 : 65, // 높이 증가 (60→80, 50→65)
                                    ),
                                    padding: EdgeInsets.symmetric(
                                      vertical: isTablet ? 12 : 10, // 패딩 증가 (8→12, 6→10)
                                      horizontal: isTablet ? 12 : 8,
                                    ),
                                    decoration: ShapeDecoration(
                                      color: const Color(0xFFE4ECF8),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                        // 미션이 없는 경우
                                        Text(
                                            _selectedTabIndex == 0
                                              ? '아직 참여중인 미션이 없어요'
                                                : '아직 참여중인 미션이  미션이 없어요',
                                            style: TextStyle(
                                              color: const Color(0xFF999999),
                                            fontSize: isTablet ? 11 : 9, // 폰트 크기 감소
                                              fontFamily: 'Pretendard-Light',
                                              letterSpacing: -0.22,
                                            ),
                                            textAlign: TextAlign.center,
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 2,
                                          ),
                                        SizedBox(height: isTablet ? 6 : 4), // 간격 감소
                                        Container(
                                            constraints: const BoxConstraints(
                                              maxWidth: double.infinity,
                                            ),
                                            padding: EdgeInsets.symmetric(
                                            horizontal: isTablet ? 16 : 12, // 패딩 감소
                                            vertical: isTablet ? 6 : 4, // 패딩 감소
                                            ),
                                            decoration: ShapeDecoration(
                                              color: const Color(0xFF3A88F4),
                                              shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                              ),
                                            ),
                                            child: Text(
                                              '미션 조르러 가기',
                                              style: TextStyle(
                                                color: Colors.white,
                                              fontSize: isTablet ? 11 : 9, // 폰트 크기 감소
                                                fontFamily: 'Pretendard-Medium',
                                                letterSpacing: -0.24,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                      ],
                                    ),
                                  )
                                                                : Container(
                                    constraints: BoxConstraints(
                                      minHeight: isTablet ? 60 : 50, // 최소 높이로 오버플로우 방지
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        // 퍼센티지 박스
                                        SizedBox(
                                          height: isTablet ? 26 : 20, // 퍼센티지 박스 영역 높이 감소
                                          child: LayoutBuilder(
                                            builder: (context, constraints) {
                                              final progress = totalCount > 0 ? (completedCount / totalCount).clamp(0.0, 1.0) : 0.0;
                                              // 실제 프로그래스 바 너비 계산 (전체 너비에서 트로피 아이콘과 간격 제외)
                                              final progressBarWidth = constraints.maxWidth - profileSize - 8;
                                              final progressPosition = progressBarWidth * progress;
                                              final boxWidth = isTablet ? 36.0 : 28.0;
                                              final leftPosition = (progressPosition - boxWidth / 2).clamp(0.0, progressBarWidth - boxWidth);
                                              
                                              return Stack(
                                                children: [
                                                  Positioned(
                                                    left: leftPosition,
                                                    bottom: 0,
                                                    child: Column(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        // 퍼센티지 박스
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                                            horizontal: isTablet ? 5 : 3,
                                                            vertical: 1,
                                          ),
                                          decoration: ShapeDecoration(
                                                            color: const Color(0xFF5D9EFF),
                                            shape: RoundedRectangleBorder(
                                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                          ),
                                          child: Text(
                                                            '${(progress * 100).round()}%',
                                            style: TextStyle(
                                              color: Colors.white,
                                                              fontSize: isTablet ? 12 : 10,
                                                              fontFamily: 'Pretendard-Medium',
                                                              letterSpacing: -0.22,
                                            ),
                                          ),
                                        ),
                                                        // 아래 방향 삼각형
                                                        CustomPaint(
                                                          size: Size(isTablet ? 6 : 4, isTablet ? 3 : 2),
                                                          painter: TrianglePainter(
                                                            color: const Color(0xFF5D9EFF),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              );
                                            },
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        // 프로그레스바와 트로피 아이콘
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                            // 진행률 바
                                            Expanded(
                                              child: Container(
                                                height: isTablet ? 18 : 16,
                                                child: Stack(
                                                  children: [
                                                    // 프로그래스 바 배경
                                                    Container(
                                                      width: double.infinity,
                                                      height: double.infinity,
                                                      decoration: ShapeDecoration(
                                                        color: const Color(0xFFE4ECF8),
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius: BorderRadius.circular(8),
                                                        ),
                                                      ),
                                                    ),
                                                    // 프로그래스 바 채우기
                                                    ClipRRect(
                                                      borderRadius: BorderRadius.circular(8),
                                                      child: LayoutBuilder(
                                                        builder: (context, constraints) {
                                                          final progress = totalCount > 0 ? (completedCount / totalCount).clamp(0.0, 1.0) : 0.0;
                                                          return Align(
                                                            alignment: Alignment.centerLeft,
                                                            child: Container(
                                                              width: constraints.maxWidth * progress,
                                                              height: double.infinity,
                                                              decoration: const ShapeDecoration(
                                                                gradient: LinearGradient(
                                                                  begin: Alignment(1.04, 1.00),
                                                                  end: Alignment(-0.43, -0.31),
                                                                  colors: [
                                                                    Color(0xFF5D9EFF),
                                                                    Color(0xFF10CB86),
                                                                  ],
                                                                ),
                                                                shape: RoundedRectangleBorder(
                                                                  borderRadius: BorderRadius.all(
                                                                    Radius.circular(8),
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                          );
                                                        },
                                                      ),
                                                    ),
                                                    // 점선 구분선
                                                    ClipRRect(
                                                      borderRadius: BorderRadius.circular(8),
                                                      child: CustomPaint(
                                                        size: Size(double.infinity, double.infinity),
                                                        painter: ProgressBarDividerPainter(
                                                          color: Colors.white.withOpacity(0.7),
                                                          percentages: [0.3, 0.6, 0.9], // 30%, 60%, 90%
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            // 트로피 아이콘
                                            Transform.translate(
                                              offset: const Offset(-6, 0), // 
                                              child: Container(
                                                width: profileSize,
                                                height: profileSize,
                                                decoration: ShapeDecoration(
                                                  color: const Color(0xFF3A88F4),
                                                  shape: const OvalBorder(),
                                                  shadows: [
                                                    BoxShadow(
                                                      color: Colors.black.withOpacity(0.15),
                                                      spreadRadius: 0,
                                                      blurRadius: 8,
                                                      offset: const Offset(0, 2), // floating 효과
                                                    ),
                                                  ],
                                                ),
                                                child: Image.asset(
                                                  'assets/icons/Icon/mission/tropy.png',
                                                  width: profileSize * 0.6,
                                                  height: profileSize * 0.6,
                                                  fit: BoxFit.contain,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8), // 12px → 8px로 감소
                  // 친구 정보
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 친구 프로필 (고정 너비)
                      SizedBox(
                        width: isTablet ? 90 : 70, // 고정 너비 설정 (사용자와 동일)
                        child: Column(
                        children: [
                          Container(
                            width: profileSize,
                            height: profileSize,
                            decoration: const ShapeDecoration(
                              shape: OvalBorder(
                                side: BorderSide(
                                  width: 0.80,
                                  color: Color(0xFF146AFF),
                                ),
                              ),
                            ),
                            child: ClipOval(
                              child: CachedNetworkImage(
                                imageUrl:
                                    widget.friendData['profileImageUrl'] ??
                                    "https://via.placeholder.com/40x40/CCCCCC/FFFFFF?text=👤",
                                fit: BoxFit.cover,
                                width: profileSize,
                                height: profileSize,
                                placeholder:
                                    (context, url) => Container(
                                      width: profileSize,
                                      height: profileSize,
                                      color: const Color(0xFFE0E0E0),
                                      child: Icon(
                                        Icons.person,
                                        size: profileSize * 0.6,
                                        color: const Color(0xFF999999),
                                      ),
                                    ),
                                errorWidget:
                                    (context, url, error) => Container(
                                      width: profileSize,
                                      height: profileSize,
                                      color: const Color(0xFFE0E0E0),
                                      child: Icon(
                                        Icons.person,
                                        size: profileSize * 0.6,
                                        color: const Color(0xFF999999),
                                      ),
                                    ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: profileSize + 20,
                            child: Text(
                              widget.friendData['name'] ?? '친구',
                              style: TextStyle(
                                color: const Color(0xFF202020),
                                fontSize: isTablet ? 14 : 12,
                                fontFamily: 'Pretendard-Bold',
                                letterSpacing: -0.24,
                              ),
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isTablet ? 14 : 12,
                              vertical: isTablet ? 6 : 4,
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
                                  TextSpan(
                                    text:
                                        '${widget.friendData['entireCompleted'] ?? 12}/',
                                    style: TextStyle(
                                      color: const Color(0xFF001F55),
                                        fontSize: isTablet ? 12 : 10, // 2px 감소
                                      fontFamily: 'Pretendard-Bold',
                                      letterSpacing: -0.24,
                                    ),
                                  ),
                                  TextSpan(
                                    text: '30개',
                                    style: TextStyle(
                                      color: const Color(0xFF001F55),
                                        fontSize: isTablet ? 12 : 10, // 2px 감소
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
                      const SizedBox(width: 12),
                      // 친구의 프로그레스바와 퍼센티지 박스
                      Expanded(
                        child: Container(
                          constraints: BoxConstraints(
                            minHeight: isTablet ? 60 : 50, // 최소 높이로 오버플로우 방지
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // 친구 퍼센티지 박스
                              SizedBox(
                                height: isTablet ? 26 : 20, // 퍼센티지 박스 영역 높이 감소
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    const friendProgress = 0.75; // 친구 진행률 75%
                                    // 실제 프로그래스 바 너비 계산 (전체 너비에서 트로피 아이콘과 간격 제외)
                                    final progressBarWidth = constraints.maxWidth - profileSize - 8;
                                    final progressPosition = progressBarWidth * friendProgress;
                                    final boxWidth = isTablet ? 36.0 : 28.0;
                                    final leftPosition = (progressPosition - boxWidth / 2).clamp(0.0, progressBarWidth - boxWidth);
                                    
                                    return Stack(
                                      children: [
                                        Positioned(
                                          left: leftPosition,
                                          bottom: 0,
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              // 친구 퍼센티지 박스
                      Container(
                        padding: EdgeInsets.symmetric(
                                                  horizontal: isTablet ? 5 : 3,
                                                  vertical: 1,
                        ),
                        decoration: ShapeDecoration(
                          color: const Color(0xFF5D9EFF),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        child: Text(
                                                  '${(friendProgress * 100).round()}%',
                          style: TextStyle(
                            color: Colors.white,
                                                    fontSize: isTablet ? 12 : 10,
                            fontFamily: 'Pretendard-Medium',
                            letterSpacing: -0.22,
                          ),
                        ),
                      ),
                                              // 아래 방향 삼각형
                                              CustomPaint(
                                                size: Size(isTablet ? 6 : 4, isTablet ? 3 : 2),
                                                painter: TrianglePainter(
                                                  color: const Color(0xFF5D9EFF),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 2),
                              // 친구 프로그레스바와 트로피 아이콘
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // 친구 진행률 바
                      Expanded(
                        child: Container(
                          height: isTablet ? 18 : 16,
                                      child: Stack(
                                        children: [
                                          // 프로그래스 바 배경
                                          Container(
                                            width: double.infinity,
                                            height: double.infinity,
                          decoration: ShapeDecoration(
                            color: const Color(0xFFE4ECF8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                                          ),
                                          // 프로그래스 바 채우기
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: LayoutBuilder(
                                              builder: (context, constraints) {
                                                const friendProgress = 0.75; // 친구 진행률 75%
                                                return Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                                                    width: constraints.maxWidth * friendProgress,
                                                    height: double.infinity,
                              decoration: const ShapeDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment(1.04, 1.00),
                                  end: Alignment(-0.43, -0.31),
                                  colors: [
                                    Color(0xFF5D9EFF),
                                    Color(0xFF10CB86),
                                  ],
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                                                );
                                              },
                                            ),
                                          ),
                                          // 점선 구분선
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: CustomPaint(
                                              size: Size(double.infinity, double.infinity),
                                              painter: ProgressBarDividerPainter(
                                                color: Colors.white.withOpacity(0.7),
                                                percentages: [0.3, 0.6, 0.9], // 30%, 60%, 90%
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                                                    // 친구 트로피 아이콘
                                  Transform.translate(
                                    offset: const Offset(-6, 0), // 왼쪽으로 4px 이동
                                    child: Container(
                                      width: profileSize,
                                      height: profileSize,
                                      decoration: ShapeDecoration(
                                        color: const Color(0xFF3A88F4),
                                        shape: const OvalBorder(),
                                        shadows: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.15),
                                            spreadRadius: 0,
                                            blurRadius: 8,
                                            offset: const Offset(0, 2), // floating 효과
                                          ),
                                        ],
                                      ),
                                      child: Image.asset(
                                        'assets/icons/Icon/mission/tropy.png',
                                        width: profileSize * 0.6,
                                        height: profileSize * 0.6,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                    ],
                  ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8), // 12px → 8px로 감소
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 과목별 비교 바텀시트 표시 함수
Future<void> showSubjectComparisonBottomSheet(
  BuildContext context,
  Map<String, dynamic> friendData,
) async {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    useSafeArea: true, // 안전 영역 사용으로 하단 네비게이션 바 위에 표시
    builder: (BuildContext context) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: kBottomNavigationBarHeight + 16, // 하단 네비게이션 바 높이 + 추가 여백
        ),
        child: SubjectComparisonBottomSheet(friendData: friendData),
      );
    },
  );
}
