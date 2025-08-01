import 'package:flutter/material.dart';
import '../../../services/analysis_service.dart';
import '../../../services/auth_service.dart';
import '../../../services/family_service.dart';

// LineChartPainter 클래스를 이 파일에 직접 정의합니다
class LineChartPainter extends CustomPainter {
  final List<Offset> dataPoints;
  
  LineChartPainter({required this.dataPoints});

  @override
  void paint(Canvas canvas, Size size) {
    // 동적 데이터 포인트 사용, 없으면 기본값 사용
    final points = dataPoints.isNotEmpty ? dataPoints : [
      Offset(size.width * 0.05, size.height * 0.8), // 기본값
      Offset(size.width * 0.2, size.height * 0.4),
      Offset(size.width * 0.35, size.height * 0.6),
      Offset(size.width * 0.5, size.height * 0.7),
      Offset(size.width * 0.65, size.height * 0.5),
      Offset(size.width * 0.8, size.height * 0.3),
      Offset(size.width * 0.98, size.height * 0.6),
    ];

    // 수평 보조선 그리기 (1h, 2h, 3h, 4h, 5h)
    final gridPaint =
        Paint()
          ..color = Colors.grey.withOpacity(0.2)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8;

    // 점선을 위한 페인트
    final dashedGridPaint =
        Paint()
          ..color = Colors.grey.withOpacity(0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0;

    // 5개의 수평선 그리기 (2h부터 10h까지, 2시간 단위)
    final gridPositions = [0.76, 0.62, 0.48, 0.34, 0.20]; // 2h, 4h, 6h, 8h, 10h 위치
    final graphStartX = size.width * 0.1;
    final graphEndX = size.width;

    for (final position in gridPositions) {
      final y = size.height * position;
      // 점선으로 그리기
      _drawDashedLine(
        canvas,
        Offset(graphStartX, y),
        Offset(graphEndX, y),
        dashedGridPaint,
      );
    }

    // 선을 위한 페인트 정의 - 더 굵고 진한 색상으로 변경
    final linePaint =
        Paint()
          ..color = const Color(0xFF146AFF).withOpacity(0.8) // 불투명도 증가
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.5; // 더 굵게

    // 아래 영역 채우기를 위한 페인트 - 그라데이션 강화
    final fillPaint =
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF146AFF).withOpacity(0.7), // 더 진하게
              const Color(0xFF146AFF).withOpacity(0.4), // 중간 투명도
              const Color(0xFF146AFF).withOpacity(0.1), // 약간 투명
            ],
          ).createShader(Rect.fromLTRB(0, 0, size.width, size.height))
          ..style = PaintingStyle.fill;

    // 부드러운 곡선을 위한 경로 생성
    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);

    // 부드러운 곡선으로 점들을 연결
    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final controlPoint1 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p0.dy);
      final controlPoint2 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p1.dy);

      path.cubicTo(
        controlPoint1.dx,
        controlPoint1.dy,
        controlPoint2.dx,
        controlPoint2.dy,
        p1.dx,
        p1.dy,
      );
    }

    // 아래 영역 채우기를 위한 경로 생성
    final fillPath = Path.from(path);
    fillPath.lineTo(points.last.dx, size.height);
    fillPath.lineTo(points.first.dx, size.height);
    fillPath.close();

    // 아래 영역 채우기
    canvas.drawPath(fillPath, fillPaint);

    // 선으로 된 곡선 그리기
    canvas.drawPath(path, linePaint);
  }

  // 점선을 그리는 헬퍼 메서드
  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dashWidth = 5.0;
    const dashSpace = 3.0;
    final distance = (end - start).distance;
    final dashCount = (distance / (dashWidth + dashSpace)).floor();

    for (int i = 0; i < dashCount; i++) {
      final startOffset =
          start + (end - start) * (i * (dashWidth + dashSpace) / distance);
      final endOffset =
          start +
          (end - start) *
              ((i * (dashWidth + dashSpace) + dashWidth) / distance);
      canvas.drawLine(startOffset, endOffset, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

// 삼각형을 그리는 CustomPainter
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
    path.moveTo(size.width / 2, 0); // 위쪽 꼭짓점
    path.lineTo(0, size.height); // 왼쪽 아래
    path.lineTo(size.width, size.height); // 오른쪽 아래
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

// DottedLinePainter 클래스 추가
class DottedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.grey.withOpacity(0.3)
          ..strokeWidth = 1
          ..style = PaintingStyle.stroke;

    const dashWidth = 4.0;
    const dashSpace = 4.0;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class StudyHighlightCard extends StatefulWidget {
  const StudyHighlightCard({super.key});

  @override
  State<StudyHighlightCard> createState() => _StudyHighlightCardState();
}

class _StudyHighlightCardState extends State<StudyHighlightCard> {
  String selectedPeriod = '14일'; // 선택된 기간 상태
  int selectedTabIndex = 0; // 선택된 탭 인덱스 (0: 총 학습 시간, 1: 총 달성률, 2: 총 상승률)
  
  // 동적 데이터 상태
  List<Map<String, dynamic>> dailyStudyData = [];
  List<Offset> graphPoints = [];
  bool isLoadingData = true;
  String totalStudyTime = '3시간 30분'; // 기본값
  int? currentChildId; // 동적으로 결정될 자녀 ID
  
  // 달성률 및 상승률 데이터
  Map<String, dynamic> achievementData = {};
  Map<String, dynamic> growthRateData = {};
  Map<String, dynamic>? analysisReportData;

  @override
  void initState() {
    super.initState();
    _initializeChildId();
  }

  /// 자녀 ID 초기화 및 데이터 로드
  Future<void> _initializeChildId() async {
    setState(() {
      isLoadingData = true;
    });

    try {
      // 현재 로그인한 사용자 정보 확인
      final userInfo = await AuthService.getUserInfo();
      final userRole = userInfo['role'];
      
      if (userRole == 'PARENT') {
        // 부모인 경우 가족 정보에서 자녀 찾기
        final familyInfo = await FamilyService.getFamilyInfo();
        if (familyInfo != null) {
          final memberList = familyInfo['memberInfoList'] as List?;
          if (memberList != null) {
            for (final member in memberList) {
              if (member['role'] == 'CHILD') {
                currentChildId = member['userId'] as int;
                print('✅ 자녀 찾음: ${member['nickname']}, ID: $currentChildId');
                break;
              }
            }
          }
        }
      } else if (userRole == 'CHILD') {
        // 자녀인 경우 본인 ID 사용
        currentChildId = userInfo['userId'] as int;
        print('✅ 자녀 본인: ID: $currentChildId');
      }

      if (currentChildId != null) {
        await _loadStudyData();
      } else {
        print('❌ 자녀 ID를 찾을 수 없습니다.');
        setState(() {
          isLoadingData = false;
        });
      }
    } catch (e) {
      print('❌ 자녀 ID 초기화 오류: $e');
      setState(() {
        isLoadingData = false;
      });
    }
  }

  /// 학습 데이터 로드
  Future<void> _loadStudyData() async {
    setState(() {
      isLoadingData = true;
    });

    try {
      final period = _getPeriodFromString(selectedPeriod);
      
      // 자녀 ID 확인
      if (currentChildId == null) {
        print('❌ 자녀 ID가 없어서 데이터를 로드할 수 없습니다.');
        setState(() {
          isLoadingData = false;
        });
        return;
      }

      // 분석 리포트 데이터 가져오기
      try {
        analysisReportData = await AnalysisService.getAnalysisReport(currentChildId!, period);
        print('✅ 분석 리포트 데이터 로드 성공');
      } catch (e) {
        print('❌ 분석 리포트 로드 오류: $e');
        analysisReportData = null;
      }
      
      // 일별 학습 데이터 가져오기
      final data = await AnalysisService.getDailyStudyData(currentChildId!, period);
      
      if (data != null && data.isNotEmpty) {
        setState(() {
          dailyStudyData = data;
          _updateGraphPoints();
          _calculateTotalStudyTime();
          isLoadingData = false;
        });
        await _updateAchievementAndGrowthData(period);
      } else {
        // 데이터가 없을 경우 빈 데이터로 초기화
        setState(() {
          dailyStudyData = List.generate(period, (index) => {
            'date': DateTime.now().subtract(Duration(days: period - 1 - index)),
            'studyTime': 0,
          });
          _updateGraphPoints();
          _calculateTotalStudyTime();
          isLoadingData = false;
        });
        await _updateAchievementAndGrowthData(period);
      }
    } catch (e) {
      print('❌ 학습 데이터 로드 오류: $e');
      // 오류 발생 시 빈 데이터로 초기화
      final period = _getPeriodFromString(selectedPeriod);
      setState(() {
        dailyStudyData = List.generate(period, (index) => {
          'date': DateTime.now().subtract(Duration(days: period - 1 - index)),
          'studyTime': 0,
        });
        _updateGraphPoints();
        _calculateTotalStudyTime();
        isLoadingData = false;
      });
      await _updateAchievementAndGrowthData(period);
    }
  }

  /// 달성률 및 상승률 데이터 업데이트
  Future<void> _updateAchievementAndGrowthData(int period) async {
    try {
      if (currentChildId == null) {
        print('❌ 자녀 ID가 없어서 달성률/상승률을 계산할 수 없습니다.');
        return;
      }

      // 병렬로 달성률과 상승률 데이터 계산
      final results = await Future.wait([
        AnalysisService.calculateAchievementData(currentChildId!, period),
        AnalysisService.calculateGrowthRateData(currentChildId!, period),
      ]);
      
      achievementData = results[0];
      growthRateData = results[1];
      
      print('📊 달성률 데이터: $achievementData');
      print('📈 상승률 데이터: $growthRateData');
    } catch (e) {
      print('❌ 달성률/상승률 데이터 업데이트 오류: $e');
      // 오류 시 실제 0값 설정 (더미 데이터 사용하지 않음)
      final periodText = _getPeriodTextLocal(period);
      achievementData = {
        'prevRate': 0,
        'recentRate': 0,
        'prevLabel': periodText,
        'recentLabel': '오늘까지',
        'isImproved': false,
        'difference': 0,
      };
      growthRateData = {
        'prevRate': 0,
        'recentRate': 0,
        'prevLabel': periodText,
        'recentLabel': '오늘까지',
        'isImproved': false,
        'growthRate': 0,
        'difference': 0,
      };
    }
  }

  /// 그래프 포인트 업데이트
  void _updateGraphPoints() {
    if (dailyStudyData.isNotEmpty) {
      graphPoints = AnalysisService.calculateGraphPoints(
        dailyStudyData, 
        const Size(300, 170) // 기본 그래프 크기
      );
    }
  }

  /// 총 학습 시간 계산 (분석 API 기준)
  void _calculateTotalStudyTime() {
    if (analysisReportData != null) {
      // 분석 API의 thisMonthTotalStudyTime 사용
      final thisMonthStudyTime = analysisReportData!['thisMonthTotalStudyTime'] ?? 0;
      
      if (thisMonthStudyTime > 0) {
        setState(() {
          totalStudyTime = AnalysisService.formatStudyTime(thisMonthStudyTime);
        });
        print('📊 총 학습시간 (이번 달): ${AnalysisService.formatStudyTime(thisMonthStudyTime)}');
        return;
      }
    }
    
    // 분석 API 데이터가 없거나 0이면 일별 데이터로 계산
    if (dailyStudyData.isNotEmpty) {
      final totalMinutes = dailyStudyData
          .map((data) => data['studyTimeMinutes'] as int)
          .reduce((a, b) => a + b);
      
      setState(() {
        totalStudyTime = AnalysisService.formatStudyTime(totalMinutes);
      });
      
      print('📊 총 학습시간 (일별 합산): ${AnalysisService.formatStudyTime(totalMinutes)}');
    } else {
      // 마지막 fallback: 기본값
      setState(() {
        totalStudyTime = '0분';
      });
      print('⚠️ 학습 데이터가 없어 0분으로 설정');
    }
  }

  /// 문자열 기간을 숫자로 변환
  int _getPeriodFromString(String period) {
    switch (period) {
      case '14일': return 14;
      case '30일': return 30;
      case '60일': return 60;
      case '90일': return 90;
      default: return 14;
    }
  }

  /// 기간을 텍스트로 변환 (로컬)
  String _getPeriodTextLocal(int period) {
    switch (period) {
      case 7: return '지난주';
      case 14: return '지난 2주';
      case 30: return '지난 달';
      case 60: return '지난 2달';
      default: return '이전 기간';
    }
  }

  // 표시용 텍스트 변환 함수
  String getDisplayText(String period) {
    if (period == '30일') {
      return '이번달';
    }
    return period;
  }

  // 기간 선택 드롭다운 위젯
  Widget _buildPeriodDropdown() {
    return PopupMenuButton<String>(
      offset: const Offset(0, 8), // 드롭다운 위치 조정
      elevation: 4, // 그림자 줄임
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12), // 모서리 둥글게
      ),
      constraints: const BoxConstraints(
        minWidth: 120, // 최소 너비 설정
        maxWidth: 150, // 최대 너비 설정
      ),
      onSelected: (String value) {
        setState(() {
          selectedPeriod = value; // 선택된 기간 업데이트
        });
        _loadStudyData(); // 기간 변경 시 데이터 재로드
      },
      itemBuilder:
          (BuildContext context) => <PopupMenuEntry<String>>[
            PopupMenuItem<String>(
              value: '14일',
              height: 40, // 높이 줄임
              child: Text(
                '14일',
                style: TextStyle(
                  fontSize: 14,
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF202020),
                ),
              ),
            ),
            PopupMenuItem<String>(
              value: '30일',
              height: 40,
              child: Text(
                '30일',
                style: TextStyle(
                  fontSize: 14,
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF202020),
                ),
              ),
            ),
            PopupMenuItem<String>(
              value: '60일',
              height: 40,
              child: Text(
                '60일',
                style: TextStyle(
                  fontSize: 14,
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF202020),
                ),
              ),
            ),
            PopupMenuItem<String>(
              value: '90일',
              height: 40,
              child: Text(
                '90일',
                style: TextStyle(
                  fontSize: 14,
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF202020),
                ),
              ),
            ),
          ],
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 16,
            height: 16,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(),
            child: Image.asset(
              'assets/icons/parent/analysis/expand.png',
              width: 16,
              height: 16,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            getDisplayText(selectedPeriod), // 표시용 텍스트 사용
            style: TextStyle(
              color: const Color(0xFFFFA63D),
              fontSize: 14,
              fontFamily: 'Pretendard-Bold',
              letterSpacing: -0.32,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Color(0x35000000),
            blurRadius: 8,
            offset: Offset(3, 4),
            spreadRadius: 0,
          ),
        ],
        borderRadius: BorderRadius.circular(24),
      ),
      child: Container(
        width: double.infinity,
        decoration: ShapeDecoration(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상단 제목 영역
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(
                left: 20,
                right: 20,
                top: 12,
                bottom: 0,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Container(
                width: double.infinity,
                height: 24,
                child: Stack(
                  children: [
                    Positioned(
                      left: 0,
                      top: 0,
                      child:
                          selectedTabIndex == 0
                              ? Text(
                                '한 달 동안 우리 아이 공부 하이라이트',
                                style: TextStyle(
                                  color: const Color(0xFF202020),
                                  fontSize: 14,
                                  fontFamily: 'Pretendard-Bold',
                                  letterSpacing: -0.32,
                                ),
                              )
                              : Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  _buildPeriodDropdown(),
                                  const SizedBox(width: 4),
                                  Text(
                                    '동안 우리 아이 공부 하이라이트',
                                    style: TextStyle(
                                      color: const Color(0xFF202020),
                                      fontSize: 14,
                                      fontFamily: 'Pretendard-Bold',
                                      letterSpacing: -0.32,
                                    ),
                                  ),
                                ],
                              ),
                    ),
                  ],
                ),
              ),
            ),

            // 시간 표시 영역
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(
                left: 20,
                right: 20,
                top: 4,
                bottom: 4,
              ), // top 패딩 줄임 (12->4)
              decoration: const BoxDecoration(color: Colors.white),
              child: Transform.translate(
                // Transform 위젯 추가하여 시간 텍스트만 위로 이동
                offset: const Offset(0, -4), // y축으로 -4px 이동
                child: isLoadingData 
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            const Color(0xFF146AFF),
                          ),
                        ),
                      )
                    : Text(
                        totalStudyTime,
                        style: TextStyle(
                          color: const Color(0xFF146AFF),
                          fontSize: 20,
                          fontFamily: 'Pretendard-Bold',
                          letterSpacing: -0.32,
                        ),
                      ),
              ),
            ),

            // 탭 영역
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(
                left: 20,
                right: 20,
                top: 8,
                bottom: 8,
              ), // top, bottom 패딩 증가
              decoration: const BoxDecoration(color: Colors.white),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => selectedTabIndex = 0),
                      child: _buildStudyTab('총 학습 시간', selectedTabIndex == 0),
                    ),
                  ),
                  const SizedBox(width: 4), // 간격 줄임
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => selectedTabIndex = 1),
                      child: _buildStudyTab('총 달성률', selectedTabIndex == 1),
                    ),
                  ),
                  const SizedBox(width: 4), // 간격 줄임
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => selectedTabIndex = 2),
                      child: _buildStudyTab('총 상승률', selectedTabIndex == 2),
                    ),
                  ),
                ],
              ),
            ),

            // 컨텐츠 영역 (선택된 탭에 따라 다른 위젯 표시)
            if (selectedTabIndex == 0) ...[
              // 그래프 영역 (총 학습 시간)
              Container(
                width: double.infinity,
                height: 200,
                padding: const EdgeInsets.only(
                  left: 16,
                  right: 8,
                  top: 12,
                  bottom: 24,
                ),
                decoration: const BoxDecoration(color: Colors.white),
                child: Stack(
                  children: [
                    // 전체 영역에 점선 그리기
                    SizedBox(
                      width: double.infinity,
                      height: 170,
                      child: CustomPaint(
                        painter: LineChartPainter(dataPoints: graphPoints),
                        size: Size(double.infinity, 170),
                      ),
                    ),
                    // 위에 시간 라벨과 그래프 배치
                    Row(
                      children: [
                        // 시간 라벨 영역
                        SizedBox(
                          width: 24,
                          height: 170,
                          child: Stack(
                            children: [
                              // 10h - 상단에서 20% 위치
                              Positioned(
                                top: 170 * 0.20 - 7,
                                left: 0,
                                child: _buildTimeLabel('10h'),
                              ),
                              // 8h - 상단에서 34% 위치
                              Positioned(
                                top: 170 * 0.34 - 7,
                                left: 0,
                                child: _buildTimeLabel('8h'),
                              ),
                              // 6h - 상단에서 48% 위치
                              Positioned(
                                top: 170 * 0.48 - 7,
                                left: 0,
                                child: _buildTimeLabel('6h'),
                              ),
                              // 4h - 상단에서 62% 위치
                              Positioned(
                                top: 170 * 0.62 - 7,
                                left: 0,
                                child: _buildTimeLabel('4h'),
                              ),
                              // 2h - 상단에서 76% 위치
                              Positioned(
                                top: 170 * 0.76 - 7,
                                left: 0,
                                child: _buildTimeLabel('2h'),
                              ),
                              // 0h - 맨 아래 위치
                              Positioned(
                                top: 170 * 0.9 - 2,
                                left: 0,
                                child: _buildTimeLabel('0h'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        // 그래프 영역
                        Expanded(child: SizedBox(height: 170)),
                      ],
                    ),
                    // 하단 점선 추가 - 그래프 바닥에 위치하도록 수정
                    Positioned(
                      bottom: 0, // 그래프 바닥에 붙이도록 수정
                      left: 36,
                      right: 8,
                      child: Container(
                        height: 1,
                        child: CustomPaint(
                          painter: DottedLinePainter(),
                          size: Size.infinite,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 날짜 표시 영역 (동적)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(
                  left: 36, // 시간 라벨 영역과 동일하게 맞춤
                  right: 10,
                  top: 0,
                  bottom: 8,
                ),
                decoration: const BoxDecoration(color: Colors.white),
                child: isLoadingData 
                    ? const SizedBox.shrink()
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: dailyStudyData.map((data) {
                          final isToday = data['isToday'] ?? false;
                          return _buildDateColumn(
                            data['date'] ?? '', 
                            isToday ? '오늘' : (data['dayOfWeek'] ?? ''),
                          );
                        }).toList(),
                      ),
              ),
            ] else if (selectedTabIndex == 1) ...[
              // 달성률 비교 영역
              _buildAchievementComparison(),
            ] else ...[
              // 총 상승률 영역
              _buildGrowthRateComparison(),
            ],

            // 하단 버튼 영역
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: const ShapeDecoration(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
              ),
              child: Container(
                width: double.infinity,
                height: 48,
                decoration: ShapeDecoration(
                  color: const Color.fromARGB(255, 58, 136, 244),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Center(
                  child: Text(
                    '칭찬 메시지 보내러가기',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontFamily: 'Pretendard-Medium',
                      letterSpacing: -0.28,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 학습 탭 위젯
  Widget _buildStudyTab(String text, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 12,
      ), // horizontal 패딩 줄임
      decoration: ShapeDecoration(
        color:
            isSelected
                ? const Color(0xFF5D6A7F)
                : const Color.fromRGBO(250, 251, 253, 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Flexible(
            // Text에 Flexible 추가
            child: Text(
              text,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey,
                fontSize: 12, // 14에서 12로 2px 줄임
                fontFamily: 'Pretendard-Light', // Light로 변경
                letterSpacing: -0.28,
              ),
              overflow: TextOverflow.ellipsis, // 텍스트 오버플로우 처리
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  // 날짜 텍스트 위젯
  Widget _buildDateText(String date) {
    return Text(
      date,
      style: TextStyle(
        color: const Color(0xFF999999),
        fontSize: 10, // 12에서 10으로 2px 낮춤
        fontFamily: 'Pretendard-Light', // Light로 변경
        letterSpacing: -0.24,
      ),
    );
  }

  // 날짜와 요일을 세로로 배치하는 위젯
  Widget _buildDateColumn(String date, String day) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          date,
          style: TextStyle(
            color: const Color(0xFF999999),
            fontSize: 10, // 12에서 10으로 2px 낮춤
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w400,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 2), // 날짜와 요일 사이 간격
        Text(
          day,
          style: TextStyle(
            color: const Color(0xFF999999),
            fontSize: 10, // 12에서 10으로 2px 낮춤
            fontFamily: 'Pretendard-Light', // Light로 변경
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }

  // 시간 라벨 위젯
  Widget _buildTimeLabel(String time) {
    return Text(
      time,
      style: TextStyle(
        color: const Color(0xFF999999),
        fontSize: 10,
        fontFamily: 'Pretendard-Light', // Light로 변경
        letterSpacing: -0.2,
      ),
    );
  }

  // 달성률 비교 위젯 (동적)
  Widget _buildAchievementComparison() {
    if (isLoadingData || achievementData.isEmpty) {
      return Container(
        width: double.infinity,
        height: 200,
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(color: Colors.white),
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFF146AFF)),
          ),
        ),
      );
    }

    final prevRate = achievementData['prevRate'] ?? 0;
    final recentRate = achievementData['recentRate'] ?? 0;
    final prevLabel = achievementData['prevLabel'] ?? '이전 기간';
    final recentLabel = achievementData['recentLabel'] ?? '오늘까지';
    final isImproved = achievementData['isImproved'] ?? true;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(color: Colors.white),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 이전 기간 (작은 원)
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 108,
                height: 108,
                decoration: ShapeDecoration(
                  color: const Color(0xFFE7ECF6),
                  shape: OvalBorder(),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    prevLabel,
                    style: TextStyle(
                      color: const Color(0xFF5D9EFF),
                      fontSize: 11,
                      fontFamily: 'Pretendard-Light',
                      letterSpacing: -0.22,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // 말풍선 with 삼각형 (위쪽에 삼각형)
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 말풍선 삼각형 (위를 향함)
                      CustomPaint(
                        size: Size(8, 4),
                        painter: TrianglePainter(color: Colors.white),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        decoration: ShapeDecoration(
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              '${prevRate}%',
                              style: TextStyle(
                                color: const Color(0xFF5D9EFF),
                                fontSize: 14,
                                fontFamily: 'Pretendard',
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.28,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 32,
                    height: 32,
                    child: Image.asset(
                      isImproved 
                          ? 'assets/icons/parent/analysis/down.png'
                          : 'assets/icons/parent/analysis/up.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(width: 8),
          // 최근 기간 (큰 원)
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 140,
                  height: 140,
                  decoration: ShapeDecoration(
                    color: const Color(0xFF3A88F4),
                    shape: OvalBorder(),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 2),
                    Text(
                      recentLabel,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontFamily: 'Pretendard-Light',
                        letterSpacing: -0.28,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // 말풍선 with 삼각형 (위쪽에 삼각형)
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 말풍선 삼각형 (위를 향함)
                        CustomPaint(
                          size: Size(8, 4),
                          painter: TrianglePainter(color: Colors.white),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          decoration: ShapeDecoration(
                            color: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                '${recentRate}%',
                                style: TextStyle(
                                  color: const Color(0xFF3A88F4),
                                  fontSize: 18,
                                  fontFamily: 'Pretendard',
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.72,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 48,
                      height: 44,
                      child: Image.asset(
                        isImproved 
                            ? 'assets/icons/parent/analysis/up.png'
                            : 'assets/icons/parent/analysis/down.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 상승률 비교 위젯 (동적)
  Widget _buildGrowthRateComparison() {
    if (isLoadingData || growthRateData.isEmpty) {
      return Container(
        width: double.infinity,
        height: 200,
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(color: Colors.white),
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFF146AFF)),
          ),
        ),
      );
    }

    final prevRate = growthRateData['prevRate'] ?? 0;
    final recentRate = growthRateData['recentRate'] ?? 0;
    final prevLabel = growthRateData['prevLabel'] ?? '이전 기간';
    final recentLabel = growthRateData['recentLabel'] ?? '오늘까지';
    final isImproved = growthRateData['isImproved'] ?? true;
    final growthRate = growthRateData['growthRate'] ?? 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(color: Colors.white),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 이전 기간 (작은 원)
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 108,
                height: 108,
                decoration: ShapeDecoration(
                  color: const Color(0xFFE7ECF6),
                  shape: OvalBorder(),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    prevLabel,
                    style: TextStyle(
                      color: const Color(0xFF5D9EFF),
                      fontSize: 11,
                      fontFamily: 'Pretendard-Light',
                      letterSpacing: -0.22,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // 말풍선 with 삼각형 (위쪽에 삼각형)
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 말풍선 삼각형 (위를 향함)
                      CustomPaint(
                        size: Size(8, 4),
                        painter: TrianglePainter(color: Colors.white),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        decoration: ShapeDecoration(
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              '${prevRate}점',
                              style: TextStyle(
                                color: const Color(0xFF5D9EFF),
                                fontSize: 14,
                                fontFamily: 'Pretendard',
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.28,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 32,
                    height: 32,
                    child: Image.asset(
                      isImproved 
                          ? 'assets/icons/parent/analysis/down.png'
                          : 'assets/icons/parent/analysis/up.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(width: 8),

          // 최근 기간 (큰 원)
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 140,
                  height: 140,
                  decoration: ShapeDecoration(
                    color: const Color(0xFF3A88F4),
                    shape: OvalBorder(),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 2),
                    Text(
                      recentLabel,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontFamily: 'Pretendard-Light',
                        letterSpacing: -0.28,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // 말풍선 with 삼각형 (위쪽에 삼각형)
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 말풍선 삼각형 (위를 향함)
                        CustomPaint(
                          size: Size(8, 4),
                          painter: TrianglePainter(color: Colors.white),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          decoration: ShapeDecoration(
                            color: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${recentRate}점',
                                style: TextStyle(
                                  color: const Color(0xFF3A88F4),
                                  fontSize: 18,
                                  fontFamily: 'Pretendard',
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.72,
                                ),
                              ),
                              if (growthRate > 0) ...[
                                Text(
                                  '${isImproved ? '+' : '-'}${growthRate}%',
                                  style: TextStyle(
                                    color: isImproved ? Colors.green : Colors.red,
                                    fontSize: 10,
                                    fontFamily: 'Pretendard-Medium',
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 48,
                      height: 44,
                      child: Image.asset(
                        isImproved 
                            ? 'assets/icons/parent/analysis/up.png'
                            : 'assets/icons/parent/analysis/down.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}