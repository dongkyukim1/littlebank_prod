import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'activity_selection_bottom_sheet.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'dart:io';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

class MissionShareScreen extends StatefulWidget {
  final ActivityItem selectedActivity;
  final int totalMinutes;

  const MissionShareScreen({
    super.key,
    required this.selectedActivity,
    required this.totalMinutes,
  });

  @override
  State<MissionShareScreen> createState() => _MissionShareScreenState();
}

class _MissionShareScreenState extends State<MissionShareScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey _globalKey = GlobalKey();
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  bool _isButtonVisible = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<double>(
      begin: 1.0, // 완전히 아래에서 시작
      end: 0.0, // 원래 위치로
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // 화면이 로드된 후 애니메이션 시작
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleButton() {
    if (_isButtonVisible) {
      // 사라질 때: 먼저 애니메이션 실행, 완료 후 상태 변경
      _animationController.reverse().then((_) {
        setState(() {
          _isButtonVisible = false;
        });
      });
    } else {
      // 나타날 때: 먼저 상태 변경, 그 후 애니메이션 실행
      setState(() {
        _isButtonVisible = true;
      });
      _animationController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isTablet = screenWidth > 600;

    // 위치 조절 변수들 (화면 크기 기반 비율)
    final double yearMonthTop = screenHeight * 0.185; // 년월 상하 위치
    final double yearMonthLeft = screenWidth * 0.059; // 년월 좌우 위치
    final double dayOfWeekTop = screenHeight * 0.245; // 요일 상하 위치
    final double dayOfWeekLeft = screenWidth * 0.102; // 요일 좌우 위치
    final double dayOfMonthTop = screenHeight * 0.275; // 날짜 상하 위치
    final double dayOfMonthLeft = screenWidth * 0.088; // 날짜 좌우 위치
    final double missionTitleTop = screenHeight * 0.292; // 미션 타이틀 상하 위치
    final double missionTitleLeft = screenWidth * 0.292; // 미션 타이틀 좌우 위치
    final double timerTop = screenHeight * 0.545; // 타이머 시간 상하 위치
    final double timerLeft = screenWidth * 0.365; // 타이머 시간 좌우 위치
    final double timerMinutesTop = screenHeight * 0.898; // 타이머 분 표시 상하 위치
    final double timerMinutesLeft = screenWidth * 0.860; // 타이머 분 표시 좌우 위치

    // 폰트 크기 (화면 크기 기반 비율)
    final double yearMonthFontSize = screenWidth * 0.067; // 26/390
    final double dayOfWeekFontSize = screenWidth * 0.051; // 20/390
    final double dayOfMonthFontSize = screenWidth * 0.123; // 48/390
    final double missionTitleFontSize = screenWidth * 0.036; // 14/390
    final double timerFontSize = screenWidth * 0.087; // 34/390
    final double timerMinutesFontSize = screenWidth * 0.051; // 20/390

    return Scaffold(
      body: GestureDetector(
        onTap: () {
          if (_isButtonVisible) {
            _toggleButton();
          } else {
            // 버튼이 숨겨져 있을 때 탭하면 다시 나타남
            setState(() {
              _isButtonVisible = true;
            });
            _animationController.forward();
          }
        },
        child: Stack(
          children: [
            // 스크린샷 영역 (RepaintBoundary) - 전체 화면
            RepaintBoundary(
              key: _globalKey,
              child: Stack(
                children: [
                  // 배경 이미지
                  Image.asset(
                    'assets/icons/Icon/mission/complementation_share.png',
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: double.infinity,
                        height: double.infinity,
                        color: const Color(0xFF146AFF),
                        child: const Center(
                          child: Text(
                            '배경 이미지를 불러올 수 없습니다',
                            style: TextStyle(
                              color: Colors.white,
                              fontFamily: 'Pretendard-Regular',
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  // 년월 오버레이
                  Positioned(
                    top: yearMonthTop,
                    left: yearMonthLeft,
                    child: Text(
                      _getCurrentYearMonth(),
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: yearMonthFontSize,
                        fontFamily: 'Pretendard-Bold',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),

                  // 요일 오버레이
                  Positioned(
                    top: dayOfWeekTop,
                    left: dayOfWeekLeft,
                    child: Text(
                      _getCurrentDayOfWeek(),
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: dayOfWeekFontSize,
                        fontFamily: 'Pretendard-Light',
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.40,
                      ),
                    ),
                  ),

                  // 날짜 오버레이
                  Positioned(
                    top: dayOfMonthTop,
                    left: dayOfMonthLeft,
                    child: Text(
                      _getCurrentDayOfMonth(),
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: dayOfMonthFontSize,
                        fontFamily: 'Pretendard-Bold',
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.96,
                      ),
                    ),
                  ),

                  // 미션 타이틀 오버레이
                  Positioned(
                    top: missionTitleTop,
                    left: missionTitleLeft,
                    child: SizedBox(
                      width: screenWidth * 0.595, // 232/390를 반응형으로
                      child: Text(
                        widget.selectedActivity.title,
                        style: TextStyle(
                          color: const Color(0xFF202020),
                          fontSize: missionTitleFontSize,
                          fontFamily: 'Pretendard-Thin',
                          height: 1.50,
                        ),
                      ),
                    ),
                  ),

                  // 타이머 시간 오버레이
                  Positioned(
                    top: timerTop,
                    left: timerLeft,
                    child: Text(
                      _formatTimerTime(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: timerFontSize,
                        fontFamily: 'Pretendard-Bold',
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.64,
                      ),
                    ),
                  ),

                  // 타이머 분 단위 오버레이 (타이머 아래)
                  Positioned(
                    top: timerMinutesTop,
                    left: timerMinutesLeft,
                    child: Text(
                      _formatTimerMinutes(),
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: timerMinutesFontSize,
                        fontFamily: 'Pretendard-Thin',
                        letterSpacing: -0.40,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 공유하기 버튼 (애니메이션, 스크린샷에 포함되지 않음)
            if (_isButtonVisible)
              AnimatedBuilder(
                animation: _slideAnimation,
                builder: (context, child) {
                  return Positioned(
                    bottom: -100 * _slideAnimation.value, // 아래에서 위로 슬라이드
                    left: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () {
                        // 버튼 영역 클릭 시 이벤트 전파 중단
                      },
                      child: Container(
                        width: screenWidth,
                        padding: EdgeInsets.all(screenWidth * 0.041), // 16/390
                        decoration: const BoxDecoration(
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
                          children: [
                            GestureDetector(
                              onTap: () => _saveToGallery(context),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '공유하기',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: screenWidth * 0.046, // 18/390
                                      fontFamily: 'Pretendard-Bold',
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.72,
                                    ),
                                  ),
                                  SizedBox(
                                    height: screenHeight * 0.012,
                                  ), // 10px 정도
                                  SizedBox(
                                    width: screenWidth * 0.918, // 358/390
                                    child: Text(
                                      '스크린샷을 찍고 원하는 방법으로 공유해 보세요',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: const Color(0xFFC4C4C4),
                                        fontSize: screenWidth * 0.031, // 12/390
                                        fontFamily: 'Pretendard-Light',
                                        fontWeight: FontWeight.w300,
                                        letterSpacing: -0.24,
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
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  String _getCurrentDateFormatted() {
    final now = DateTime.now();
    return '${now.year}.${now.month.toString().padLeft(2, '0')}';
  }

  String _getCurrentYearMonth() {
    final now = DateTime.now();
    return '${now.year}.${now.month.toString().padLeft(2, '0')}';
  }

  String _getCurrentDayOfWeek() {
    final now = DateTime.now();
    // DateTime.weekday: 1=Monday, 2=Tuesday, ..., 7=Sunday
    const days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    return days[now.weekday - 1];
  }

  String _getCurrentDayOfMonth() {
    final now = DateTime.now();
    return now.day.toString().padLeft(2, '0');
  }

  String _formatTimerTime() {
    final hours = widget.totalMinutes ~/ 60;
    final minutes = widget.totalMinutes % 60;

    if (hours > 0) {
      return '${hours}:${minutes.toString().padLeft(2, '0')}';
    } else {
      return '${minutes}:00';
    }
  }

  String _formatTimerMinutes() {
    return '${widget.totalMinutes}분';
  }

  String _formatTotalTime() {
    final hours = widget.totalMinutes ~/ 60;
    final minutes = widget.totalMinutes % 60;

    if (hours > 0) {
      return '${hours}:${minutes.toString().padLeft(2, '0')}';
    } else {
      return '${minutes}:00';
    }
  }

  Future<void> _shareImage(BuildContext context) async {
    try {
      // RepaintBoundary로 캡처
      final RenderRepaintBoundary boundary =
          _globalKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;

      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      final Uint8List pngBytes = byteData!.buffer.asUint8List();

      // 임시 디렉토리에 파일 저장
      final Directory tempDir = await getTemporaryDirectory();
      final File file = File(
        '${tempDir.path}/mission_share_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(pngBytes);

      // 공유하기
      await Share.shareXFiles(
        [XFile(file.path)],
        text:
            '미션을 완료했어요! 총 ${widget.totalMinutes}분 동안 "${widget.selectedActivity.title}"를 수행했습니다.',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '공유 중 오류가 발생했습니다: $e',
              style: const TextStyle(fontFamily: 'Pretendard-Regular'),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveToGallery(BuildContext context) async {
    try {
      // RepaintBoundary로 캡처
      final RenderRepaintBoundary boundary =
          _globalKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;

      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      final Uint8List pngBytes = byteData!.buffer.asUint8List();

      // 다운로드 디렉토리에 저장 (안드로이드)
      Directory? directory;
      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      final File file = File(
        '${directory.path}/mission_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(pngBytes);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '이미지가 저장되었습니다: ${file.path}',
              style: const TextStyle(fontFamily: 'Pretendard-Regular'),
            ),
            backgroundColor: const Color(0xFF5EBE76),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '저장 중 오류가 발생했습니다: $e',
              style: const TextStyle(fontFamily: 'Pretendard-Regular'),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
