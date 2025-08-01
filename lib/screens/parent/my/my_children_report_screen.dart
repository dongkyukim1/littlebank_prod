import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../services/family_service.dart';
import '../../../services/auth_service.dart';
import '../../../services/pdf_service.dart';
import '../../../services/analysis_service.dart';

// 점선을 그리는 CustomPainter
class DashedLinePainter extends CustomPainter {
  final Color color;
  final double dashWidth;
  final double dashSpace;

  DashedLinePainter({
    required this.color,
    this.dashWidth = 4.0,
    this.dashSpace = 4.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
          ..strokeWidth = 1.0;

      double startX = 0;
      while (startX < size.width) {
        canvas.drawLine(
        Offset(startX, 0),
        Offset(startX + dashWidth, 0),
        paint,
        );
        startX += dashWidth + dashSpace;
      }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class MyChildrenReportScreen extends StatefulWidget {
  const MyChildrenReportScreen({super.key});

  @override
  State<MyChildrenReportScreen> createState() => _MyChildrenReportScreenState();
}

class _MyChildrenReportScreenState extends State<MyChildrenReportScreen>
    with TickerProviderStateMixin {
  // 가족 정보 관련 변수들
  List<dynamic>? _familyMembers;
  bool _isLoadingFamily = true;
  String? _familyError;
  int _selectedChildIndex = 0; // 선택된 자녀 인덱스
  
  // 분석 데이터 관련 변수들
  Map<String, dynamic>? _analysisData;
  bool _isLoadingAnalysis = true;
  String? _analysisError;
  List<Map<String, dynamic>>? _analysisCards;
  
  // 기간 선택 관련 변수들
  int _selectedPeriod = 14; // 기본값: 14일
  final List<int> _availablePeriods = [7, 14, 30, 60];
  bool _isPeriodExpanded = false; // 기간 선택 확장 상태
  late AnimationController _animationController;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.5,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _loadFamilyMembers();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // PDF 생성 함수
  Future<void> _generatePdfReport() async {
    if (_familyMembers == null ||
        _familyMembers!.isEmpty ||
        _selectedChildIndex >= _familyMembers!.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('선택된 자녀 정보를 찾을 수 없습니다.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // 로딩 표시
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
              child: Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Color(0xFF146AFF)),
                    SizedBox(height: 16),
                    Text(
                      'PDF 보고서를 생성하고 있습니다...',
                      style: TextStyle(
                        fontSize: 14,
                        fontFamily: 'Pretendard-Medium',
                      ),
                    ),
                  ],
                ),
              ),
            ),
      );

      final selectedChild = _familyMembers![_selectedChildIndex];

      // 분석 데이터가 없으면 오류 처리
      if (_analysisData == null) {
        throw Exception('분석 데이터를 불러오지 못했습니다. 다시 시도해주세요.');
      }

      // 로딩 다이얼로그 닫기
      Navigator.of(context).pop();

      // PDF 생성 및 카카오톡 공유
      await PdfService.saveAndSharePdf(
        analysisData: _analysisData!,
        familyMemberData: selectedChild,
        selectedPeriod: _selectedPeriod,
        context: context,
      );
    } catch (e) {
      // 로딩 다이얼로그 닫기
      Navigator.of(context).pop();

      // 오류 메시지
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF 생성 중 오류가 발생했습니다: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // 가족 구성원 목록 불러오기
  Future<void> _loadFamilyMembers() async {
    print('🔍 [분석화면] _loadFamilyMembers() 시작');
    try {
      if (mounted) {
        setState(() {
          _isLoadingFamily = true;
          _familyError = null;
        });
      }
      print('⏳ [분석화면] 가족 정보 API 호출 시작');

      final familyInfo = await FamilyService.getFamilyInfo();
      print('👪 [분석화면] 가족 정보 API 응답: $familyInfo');

      if (familyInfo != null) {
        final List<dynamic> memberList = familyInfo['memberInfoList'] ?? [];
        print('📝 [분석화면] 전체 가족 구성원 수: ${memberList.length}');
        
        final List<dynamic> children = memberList.where((member) => member['role'] != 'PARENT').toList();
        print('👶 [분석화면] 자녀 수: ${children.length}');
        print('👶 [분석화면] 자녀 목록: $children');

        if (mounted) {
          setState(() {
            _familyMembers = children;
            _isLoadingFamily = false;
          });
          print('✅ [분석화면] 가족 정보 로드 완료');
          
          // 가족 정보 로드 완료 후 분석 데이터 로드
          if (children.isNotEmpty) {
            print('🔄 [분석화면] 자녀가 있으므로 분석 데이터 로드 시작');
            _loadAnalysisData();
          } else {
            print('❌ [분석화면] 자녀가 없습니다');
          }
        }
      } else {
        print('❌ [분석화면] 가족 정보가 null입니다');
        if (mounted) {
          setState(() {
            _familyMembers = [];
            _isLoadingFamily = false;
          });
        }
      }
    } catch (e) {
      print('❌ [분석화면] 가족 정보 로드 오류: $e');
      if (mounted) {
        setState(() {
          _familyError = '가족 정보를 불러올 수 없습니다: $e';
          _isLoadingFamily = false;
          _familyMembers = [];
        });
      }
    }
  }

  // 분석 데이터 불러오기
  Future<void> _loadAnalysisData() async {
    print('🔍 [분석화면] _loadAnalysisData() 시작');
    print('👪 [분석화면] 가족 구성원 수: ${_familyMembers?.length ?? 0}');
    
    if (_familyMembers == null || _familyMembers!.isEmpty) {
      print('❌ [분석화면] 가족 구성원 정보가 없습니다.');
      return;
    }

    try {
      if (mounted) {
        setState(() {
          _isLoadingAnalysis = true;
          _analysisError = null;
        });
      }
      print('⏳ [분석화면] 분석 데이터 로딩 시작');

      final selectedChild = _familyMembers![_selectedChildIndex];
      print('👶 [분석화면] 선택된 자녀 정보: $selectedChild');
      
      // API 응답 구조에 맞게 familyMemberId와 userId 모두 시도
      final familyMemberId = selectedChild['familyMemberId'];
      final userId = selectedChild['userId'];
      
      print('🆔 [분석화면] familyMemberId: $familyMemberId');
      print('🆔 [분석화면] userId: $userId');
      
      // 먼저 familyMemberId로 시도
      int? memberId = familyMemberId;
      if (memberId != null) {
        print('📡 [분석화면] 첫 번째 시도: familyMemberId로 분석 API 호출 (memberId: $memberId, period: $_selectedPeriod)');
        try {
          final analysisData = await AnalysisService.getAnalysisReport(memberId, _selectedPeriod);
          print('📊 [분석화면] familyMemberId로 분석 API 응답 성공: $analysisData');
          
          if (analysisData != null && mounted) {
            final analysisCards = AnalysisService.generateAnalysisCards(analysisData);
            print('📋 [분석화면] 생성된 분석 카드 수: ${analysisCards.length}');
            
            setState(() {
              _analysisData = analysisData;
              _analysisCards = analysisCards;
              _isLoadingAnalysis = false;
            });
            print('✅ [분석화면] familyMemberId로 분석 데이터 로드 완료');
            return; // 성공하면 종료
          }
        } catch (e) {
          print('❌ [분석화면] familyMemberId로 분석 API 호출 실패: $e');
          // userId로 재시도
        }
      }
      
      // familyMemberId 실패 시 userId로 재시도
      if (userId != null) {
        print('📡 [분석화면] 두 번째 시도: userId로 분석 API 호출 (memberId: $userId, period: $_selectedPeriod)');
        try {
          final analysisData = await AnalysisService.getAnalysisReport(userId, _selectedPeriod);
          print('📊 [분석화면] userId로 분석 API 응답 성공: $analysisData');
          
          if (analysisData != null && mounted) {
            final analysisCards = AnalysisService.generateAnalysisCards(analysisData);
            print('📋 [분석화면] 생성된 분석 카드 수: ${analysisCards.length}');
            
            setState(() {
              _analysisData = analysisData;
              _analysisCards = analysisCards;
              _isLoadingAnalysis = false;
            });
            print('✅ [분석화면] userId로 분석 데이터 로드 완료');
            return; // 성공하면 종료
          }
        } catch (e) {
          print('❌ [분석화면] userId로도 분석 API 호출 실패: $e');
        }
      }
      
      // 모든 시도 실패
      print('❌ [분석화면] familyMemberId와 userId 모두로 시도했지만 실패');
      if (mounted) {
        setState(() {
          _analysisError = '분석 데이터를 받을 수 없습니다 (familyMemberId: $familyMemberId, userId: $userId)';
          _isLoadingAnalysis = false;
        });
      }
    } catch (e) {
      print('❌ [분석화면] 분석 데이터 로드 전체 오류: $e');
      if (mounted) {
        setState(() {
          _analysisError = '분석 데이터를 불러올 수 없습니다: $e';
          _isLoadingAnalysis = false;
        });
      }
    }
  }

  // 기간 변경 시 분석 데이터 재로드
  Future<void> _onPeriodChanged(int newPeriod) async {
    print('📅 [분석화면] 기간 변경: $newPeriod일');
    if (mounted) {
      setState(() {
        _selectedPeriod = newPeriod;
      });
      await _loadAnalysisData();
    }
  }

  // 기간 텍스트 반환
  String _getPeriodText() {
    return '${_selectedPeriod}일 동안';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
      body: Container(
              width: double.infinity,
        height: double.infinity,
                                    clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(0.50, 0.00),
            end: Alignment(0.50, 1.00),
            colors: [
              const Color(0xFF10CB86),
              const Color(0xFFA9B0FF),
              const Color(0xFF146AFF)
            ],
                        ),
                      ),
                      child: Stack(
                        children: [
            // 상단 헤더
                          Positioned(
                            left: 0,
                            top: 0,
                            right: 0,
                            child: Container(
                height: MediaQuery.of(context).padding.top + 56,
                              child: Column(
                                children: [
                    SizedBox(height: MediaQuery.of(context).padding.top),
                    Container(
                      width: double.infinity,
                      height: 56,
                      child: Stack(
                                    children: [
                          Positioned(
                            left: 16,
                            top: 16,
                            child: GestureDetector(
                              onTap: () => Navigator.of(context).pop(),
                              child: Container(
                                width: 24,
                                height: 24,
                                child: Icon(
                                  Icons.arrow_back_ios,
                                  color: Colors.white,
                                  size: 20,
                                          ),
                                        ),
                                      ),
                          ),
                          Positioned(
                            left: MediaQuery.of(context).size.width / 2 - 50,
                            top: 18.50,
                            child: Text(
                              '총 분석 리포트',
                                    style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                      fontFamily: 'Pretendard-Bold',
                                letterSpacing: -0.32,
                              ),
                                          ),
                                        ),
                          // 새로고침 버튼 (디버깅용)
                          Positioned(
                            right: 16,
                            top: 16,
                            child: GestureDetector(
                              onTap: () {
                                print('🔄 [분석화면] 수동 새로고침 시작');
                                _loadFamilyMembers();
                              },
                              child: Container(
                                width: 24,
                                height: 24,
                                child: Icon(
                                  Icons.refresh,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
            // 메인 컨텐츠
                          Positioned(
                            left: 0,
              top: MediaQuery.of(context).padding.top + 36 + 6,
                            right: 0,
                            bottom: 0,
              child: SingleChildScrollView(
                physics: ClampingScrollPhysics(),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                                                children: [
                    // 메인 리포트 카드
                                            Container(
                      width: MediaQuery.of(context).size.width - 32,
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [

                                    // top.png 이미지 with 플로팅 텍스트
          Transform.translate(
            offset: Offset(0, MediaQuery.of(context).size.height * 0.035), // 화면 높이의 1% 아래로 이동r
            child: Stack(
              children: [
                // 배경 이미지
                Container(
                  width: double.infinity,
                  child: Image.asset(
                    'assets/icons/parent/analysis/top.png',
                    width: double.infinity,
                    fit: BoxFit.fitWidth,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 100,
                        color: Colors.grey[300],
                        child: Icon(Icons.insert_drive_file, color: Colors.grey[600]),
                      );
                    },
                  ),
                ),
                // 플로팅 텍스트들
                Positioned(
                  left: 0,
                  right: 0,
                  top: MediaQuery.of(context).size.height * 0.305, // 화면 높이의 30.5% 위치 (아주 조금만 올림)
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 자녀 이름
                    Stack(
                      children: [
                        // 테두리 텍스트
                        Text(
                          _familyMembers != null && _familyMembers!.isNotEmpty
                              ? _familyMembers![_selectedChildIndex]['nickname'] ??
                                  _familyMembers![_selectedChildIndex]['realName'] ??
                                  '자녀'
                              : '자녀',
                          style: TextStyle(
                            fontSize: MediaQuery.of(context).size.width * 0.1, // 화면 너비의 10%
                            fontFamily: 'Pretendard-Black',
                            fontWeight: FontWeight.w900,
                            foreground: Paint()
                              ..style = PaintingStyle.stroke
                              ..strokeWidth = 2
                              ..color = Colors.white,
                          ),
                        ),
                        // 메인 텍스트
                        Text(
                          _familyMembers != null && _familyMembers!.isNotEmpty
                              ? _familyMembers![_selectedChildIndex]['nickname'] ??
                                  _familyMembers![_selectedChildIndex]['realName'] ??
                                  '자녀'
                              : '자녀',
                          style: TextStyle(
                            color: const Color(0xFF3A88F4),
                            fontSize: MediaQuery.of(context).size.width * 0.1, // 화면 너비의 10%
                            fontFamily: 'Pretendard-Black',
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.006), // 화면 높이의 0.6%
                    // 시간 정보
                    Container(
                      width: MediaQuery.of(context).size.width * 0.5, // 화면 너비의 40%
                      padding: EdgeInsets.symmetric(
                        horizontal: MediaQuery.of(context).size.width * 0.005, // 화면 너비의 2%
                        vertical: MediaQuery.of(context).size.height * 0.005, // 화면 높이의 0.5%
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE7ECF6),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    '지난 달보다',
                                    style: TextStyle(
                                      color: const Color(0xFF3A88F4),
                                      fontSize: MediaQuery.of(context).size.width * 0.03, // 화면 너비의 3%
                                      fontFamily: 'Pretendard',
                                      fontWeight: FontWeight.w300,
                                      letterSpacing: -0.24,
                                    ),
                                  ),
                                  SizedBox(width: MediaQuery.of(context).size.width * 0.01), // 화면 너비의 1%
                                  _buildTrendIcon(),
                                  SizedBox(width: MediaQuery.of(context).size.width * 0.005), // 화면 너비의 0.5%
                                  Text(
                                    _getMonthlyComparisonText(),
                                    style: TextStyle(
                                      color: const Color(0xFF3A88F4),
                                      fontSize: MediaQuery.of(context).size.width * 0.03, // 화면 너비의 3%
                                      fontFamily: 'Pretendard',
                                      fontWeight: FontWeight.w500,
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
                  ],
                ),
              ),
            ],
            ),
          ),
          SizedBox(height: MediaQuery.of(context).size.height * 0.08), // 화면 높이의 8% (조금 올림)
          // 총 학습 시간 박스
                              Container(
                                width: double.infinity,
                            child: Container(
                              width: 358.50,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              decoration: ShapeDecoration(
                                color: const Color(0x99E7ECF6),
                                shape: RoundedRectangleBorder(
                                  side: BorderSide(width: 0.80, color: Colors.white),
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                    '리틀뱅크에서 총 학습한 시간은?',
                                      style: TextStyle(
                                      color: const Color(0xFF202020),
                                        fontSize: 18,
                                      fontFamily: 'Pretendard',
                                      fontWeight: FontWeight.w700,
                                      height: 1.50,
                                        letterSpacing: -0.72,
                                      ),
                                    ),
                                  SizedBox(height: 8),
                                        Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          decoration: ShapeDecoration(
                                      color: const Color(0xFF146AFF),
                                            shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(40),
                                      ),
                                    ),
                                    child: _isLoadingAnalysis
                                        ? SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                            ),
                                          )
                                        : Text(
                                            _getTotalStudyTimeText(),
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 24,
                                              fontFamily: 'Pretendard',
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: -0.96,
                                            ),
                                          ),
                                                        ),
                                                        SizedBox(height: 12),
                                                        Text(
                                                          _getMonthlyComparisonDescription(),
                                                          style: TextStyle(
                                                            color: const Color(0xFF8590A3),
                                                            fontSize: 16,
                                                            fontFamily: 'Pretendard',
                                                            fontWeight: FontWeight.w300,
                                                            letterSpacing: -0.32,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                            ),
                          ),
                          SizedBox(height: 24),
                          // "N일 동안 우리아이는" 섹션
                          Column(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                width: double.infinity,
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                    // 애니메이션 아이콘
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _isPeriodExpanded = !_isPeriodExpanded;
                                          if (_isPeriodExpanded) {
                                            _animationController.forward();
                                          } else {
                                            _animationController.reverse();
                                          }
                                        });
                                      },
                                      child: AnimatedBuilder(
                                        animation: _rotationAnimation,
                                        builder: (context, child) {
                                          return Transform.rotate(
                                            angle: _rotationAnimation.value * 3.14159,
                                            child: Container(
                                              width: 24,
                                              height: 24,
                                              child: Image.asset(
                                                'assets/icons/parent/analysis/expand_white.png',
                                                width: 24,
                                                height: 24,
                                                errorBuilder: (context, error, stackTrace) {
                                                  return Icon(Icons.expand_more, color: Colors.white, size: 24);
                                                },
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // 기간 선택 영역
                                          GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                _isPeriodExpanded = !_isPeriodExpanded;
                                                if (_isPeriodExpanded) {
                                                  _animationController.forward();
                                                } else {
                                                  _animationController.reverse();
                                                }
                                              });
                                            },
                                                                                          child: Container(
                                                child: Row(
                                                  crossAxisAlignment: CrossAxisAlignment.baseline,
                                                  textBaseline: TextBaseline.alphabetic,
                                                  children: [
                                                    Container(
                                                      decoration: BoxDecoration(
                                                        border: Border(
                                                          bottom: BorderSide(
                                                            color: Colors.white,
                                                            width: 1.0,
                                                          ),
                                                        ),
                                                      ),
                                                      child: Text(
                                                        '${_selectedPeriod}일 동안',
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 18,
                                                          fontFamily: 'Pretendard',
                                                          fontWeight: FontWeight.w700,
                                                          letterSpacing: -0.36,
                                                        ),
                                                      ),
                                                    ),
                                                    Text(
                                                      ' 우리아이는',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 18,
                                                        fontFamily: 'Pretendard',
                                                        fontWeight: FontWeight.w700,
                                                        letterSpacing: -0.36,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                          ),
                                          // 확장 옵션들
                                          if (_isPeriodExpanded) ...[
                                            SizedBox(height: 4),
                                            ..._availablePeriods.where((period) => period != _selectedPeriod).map((period) {
                                              return GestureDetector(
                                                onTap: () {
                                                  _onPeriodChanged(period);
                                                  setState(() {
                                                    _isPeriodExpanded = false;
                                                    _animationController.reverse();
                                                  });
                                                },
                                                child: Container(
                                                  margin: EdgeInsets.only(top: 4),
                                                  child: Row(
                                                    children: [
                                                      Container(
                                                        decoration: BoxDecoration(
                                                          border: Border(
                                                            bottom: BorderSide(
                                                              color: Colors.white.withOpacity(0.7),
                                                              width: 1.0,
                                                            ),
                                                          ),
                                                        ),
                                                        padding: EdgeInsets.only(bottom: 2),
                                                        child: Text(
                                                          '${period}일',
                                                          style: TextStyle(
                                                            color: Colors.white.withOpacity(0.8),
                                                            fontSize: 18,
                                                            fontFamily: 'Pretendard',
                                                            fontWeight: FontWeight.w500,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 8),
                              // 오류 표시
                              if (_familyError != null)
                                Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.all(16),
                                  margin: EdgeInsets.only(bottom: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '가족 정보 로드 오류',
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontSize: 14,
                                          fontFamily: 'Pretendard-Bold',
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        _familyError!,
                                        style: TextStyle(
                                          color: Colors.red.shade700,
                                          fontSize: 12,
                                          fontFamily: 'Pretendard-Regular',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              if (_analysisError != null)
                                Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.all(16),
                                  margin: EdgeInsets.only(bottom: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '분석 데이터 로드 오류',
                                        style: TextStyle(
                                          color: Colors.orange.shade800,
                                          fontSize: 14,
                                          fontFamily: 'Pretendard-Bold',
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        _analysisError!,
                                        style: TextStyle(
                                          color: Colors.orange.shade700,
                                          fontSize: 12,
                                          fontFamily: 'Pretendard-Regular',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              // 분석 카드들
                              ...List.generate(4, (index) => _buildAnalysisCard(index)),
                            ],
                          ),
                          SizedBox(height: 150), // 하단 여백 늘림 - PDF 버튼 고려
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
            ),
            // 하단 PDF 저장 버튼
                                        Positioned(
              left: 0,
              bottom: 0,
              right: 0,
              child: SafeArea(
                                          child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                    color: Colors.black,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x5B000000),
                        blurRadius: 8,
                        offset: Offset(0, -4),
                        spreadRadius: 0,
                      ),
                    ],
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: double.infinity,
                        child: Column(
                                        mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                            GestureDetector(
                              onTap: _generatePdfReport,
                              child: Container(
                                width: double.infinity,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Colors.black,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                            child: Text(
                                    'PDF로 공유하기',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 18,
                                                fontFamily: 'Pretendard-Bold',
                                                letterSpacing: -0.72,
                                              ),
                                            ),
                                          ),
                              ),
                            ),
                            SizedBox(height: 6),
                                                        Text(
                              'PDF로 쉽게 공유하고 출력해서 확인할 수 있어요',
                              textAlign: TextAlign.center,
                                                          style: TextStyle(
                                color: const Color(0xFFC4C4C4),
                                                                  fontSize: 12,
                                fontFamily: 'Pretendard-Light',
                                letterSpacing: -0.24,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
    );
  }

  Widget _buildAnalysisCard(int index) {
    // 동적 분석 카드 데이터 사용 또는 기본값
    final List<Map<String, dynamic>> cardData = _analysisCards ?? [
      {
        'title': '분석 데이터를 로드하고 있습니다...',
        'data1': '-',
        'data2': '-',
        'description': '잠시만 기다려주세요.',
      },
      {
        'title': '분석 데이터를 로드하고 있습니다...',
        'data1': '-',
        'data2': '-',
        'description': '잠시만 기다려주세요.',
      },
      {
        'title': '분석 데이터를 로드하고 있습니다...',
        'data1': '-',
        'data2': '-',
        'description': '잠시만 기다려주세요.',
      },
      {
        'title': '분석 데이터를 로드하고 있습니다...',
        'data1': '-',
        'data2': '-',
        'description': '잠시만 기다려주세요.',
      },
    ];

    // 인덱스 범위 체크
    if (index >= cardData.length) {
      return Container();
    }

    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: index == 3 ? 0 : 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 타이틀 위 흰색 실선
                                                    Container(
                                                      width: double.infinity,
            height: 1,
            color: Colors.white,
          ),
          SizedBox(height: 16),
          // 타이틀
          SizedBox(
            width: double.infinity,
            child: Text(
              cardData[index]['title'],
              style: TextStyle(
                                                        color: Colors.white,
                fontSize: 14,
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w700,
                letterSpacing: -0.28,
                                                              ),
                                                        ),
                                                      ),
                                                          SizedBox(height: 16),
          // 타이틀 아래 흰색 점선
          CustomPaint(
            size: Size(double.infinity, 1),
            painter: DashedLinePainter(color: Colors.white),
          ),
          SizedBox(height: 12),
          // 데이터 표시
                                                          Container(
            width: double.infinity,
                                                            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
                                                              children: [
                                                                Text(
                  cardData[index]['data1'],
                                                                  style: TextStyle(
                    color: const Color(0xFF146AFF),
                    fontSize: 22,
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.44,
                    shadows: [
                      Shadow(
                        offset: Offset(-1.0, -1.0),
                        color: Colors.white,
                      ),
                      Shadow(
                        offset: Offset(1.0, -1.0),
                        color: Colors.white,
                      ),
                      Shadow(
                        offset: Offset(1.0, 1.0),
                        color: Colors.white,
                      ),
                      Shadow(
                        offset: Offset(-1.0, 1.0),
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 12),
                if (cardData[index]['isVs'] == true)
                                                                Text(
                    'vs',
                                                                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.44,
                    ),
                  )
                else
                                                              Text(
                    '→',
                                                                style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.44,
                    ),
                  ),
                SizedBox(width: 12),
                                                              Text(
                  cardData[index]['data2'],
                                                                style: TextStyle(
                    color: const Color(0xFF146AFF),
                    fontSize: 22,
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.44,
                    shadows: [
                      Shadow(
                        offset: Offset(-1.0, -1.0),
                        color: Colors.white,
                      ),
                      Shadow(
                        offset: Offset(1.0, -1.0),
                        color: Colors.white,
                      ),
                      Shadow(
                        offset: Offset(1.0, 1.0),
                        color: Colors.white,
                      ),
                      Shadow(
                        offset: Offset(-1.0, 1.0),
                        color: Colors.white,
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
          SizedBox(height: 12),
          // 데이터 아래 흰색 실선
              Container(
                width: double.infinity,
            height: 1,
          color: Colors.white,
          ),
          SizedBox(height: 12),
          SizedBox(
                width: double.infinity,
                child: Text(
              cardData[index]['description'],
                  style: TextStyle(
                    color: Colors.white,
                fontSize: 14,
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w300,
                height: 1.50,
                letterSpacing: -0.28,
                  ),
                ),
              ),
          SizedBox(height: 16),
          // 내용 아래 흰색 실선
          Container(
            width: double.infinity,
            height: 1,
            color: Colors.white,
          ),
        ],
      ),
    );
  }

  // 자녀 프로필 이미지 위젯
  Widget _buildChildProfileImage(Map<String, dynamic> child) {
    final String? profileImagePath = child['profileImagePath'];

    if (profileImagePath != null && profileImagePath.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: AuthService.getFullProfileImageUrl(profileImagePath),
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
              color: Colors.grey[300],
              child: Icon(Icons.person, color: Colors.grey[600]),
            ),
        errorWidget: (context, url, error) => Container(
              color: Colors.grey[300],
              child: Icon(Icons.person, color: Colors.grey[600]),
            ),
      );
    } else {
      final String displayName = child['nickname'] ?? child['realName'] ?? '?';
      final String firstLetter = displayName.isNotEmpty ? displayName.substring(0, 1) : '?';

      return Container(
        color: const Color(0xFF5D9EFF),
        child: Center(
          child: Text(
            firstLetter,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontFamily: 'Pretendard-Bold',
            ),
          ),
        ),
      );
    }
  }

  // 총 학습 시간 텍스트 반환 (이번 달 기준)
  String _getTotalStudyTimeText() {
    if (_analysisData != null) {
      final thisMonthStudyTime = _analysisData!['thisMonthTotalStudyTime'] ?? 0;
      return AnalysisService.formatStudyTime(thisMonthStudyTime);
    }
    return '로딩 중...';
  }

  // 월별 비교 텍스트 반환
  String _getMonthlyComparisonText() {
    if (_analysisData != null) {
      final thisMonthTime = _analysisData!['thisMonthTotalStudyTime'] ?? 0;
      final lastMonthTime = _analysisData!['lastMonthTotalStudyTime'] ?? 0;
      final timeDiff = thisMonthTime - lastMonthTime;
      
      if (timeDiff > 0) {
        return '총 ${AnalysisService.formatStudyTime(timeDiff)}';
      } else if (timeDiff < 0) {
        return '총 ${AnalysisService.formatStudyTime(timeDiff.abs())} 감소';
      } else {
        return '변화 없음';
      }
    }
    return '로딩 중...';
  }

  // 트렌드 아이콘 반환
  Widget _buildTrendIcon() {
    if (_analysisData != null) {
      final thisMonthTime = _analysisData!['thisMonthTotalStudyTime'] ?? 0;
      final lastMonthTime = _analysisData!['lastMonthTotalStudyTime'] ?? 0;
      final timeDiff = thisMonthTime - lastMonthTime;
      
      if (timeDiff > 0) {
        return Image.asset(
          'assets/icons/parent/analysis/score_up.png',
          width: MediaQuery.of(context).size.width * 0.03,
          height: MediaQuery.of(context).size.width * 0.03,
          errorBuilder: (context, error, stackTrace) {
            return Icon(
              Icons.trending_up,
              size: MediaQuery.of(context).size.width * 0.03,
              color: const Color(0xFF3A88F4),
            );
          },
        );
      } else if (timeDiff < 0) {
        return Icon(
          Icons.trending_down,
          size: MediaQuery.of(context).size.width * 0.03,
          color: const Color(0xFF3A88F4),
        );
      } else {
        return Icon(
          Icons.trending_flat,
          size: MediaQuery.of(context).size.width * 0.03,
          color: const Color(0xFF3A88F4),
        );
      }
    }
    
         return SizedBox(
       width: MediaQuery.of(context).size.width * 0.03,
       height: MediaQuery.of(context).size.width * 0.03,
       child: CircularProgressIndicator(
         strokeWidth: 2,
         valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFF3A88F4)),
       ),
     );
   }

  // 월별 비교 설명 텍스트 반환
  String _getMonthlyComparisonDescription() {
    if (_analysisData != null) {
      final thisMonthTime = _analysisData!['thisMonthTotalStudyTime'] ?? 0;
      final lastMonthTime = _analysisData!['lastMonthTotalStudyTime'] ?? 0;
      final timeDiff = thisMonthTime - lastMonthTime;
      
      if (timeDiff > 0) {
        return '지난 달보다 ${AnalysisService.formatStudyTime(timeDiff)}이 늘었어요!';
      } else if (timeDiff < 0) {
        return '지난 달보다 ${AnalysisService.formatStudyTime(timeDiff.abs())}이 줄었어요.';
      } else {
        return '지난 달과 동일한 시간 동안 학습했어요.';
      }
    }
    return '데이터를 로딩하고 있습니다...';
  }
}