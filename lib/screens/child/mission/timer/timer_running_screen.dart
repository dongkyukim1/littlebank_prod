import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'activity_selection_bottom_sheet.dart';
import 'mission_share_screen.dart';

class TimerRunningScreen extends StatefulWidget {
  final int totalMinutes;

  const TimerRunningScreen({super.key, required this.totalMinutes});

  @override
  State<TimerRunningScreen> createState() => _TimerRunningScreenState();
}

class _TimerRunningScreenState extends State<TimerRunningScreen> {
  late Timer _timer;
  late int _remainingSeconds;
  bool _isRunning = true;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.totalMinutes * 60;
    _startTimer();

    // 상태바를 보이게 설정
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF146AFF),
        statusBarIconBrightness: Brightness.light,
      ),
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    // 상태바를 원래대로 복원
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        _timer.cancel();
        _onTimerComplete();
      }
    });
  }

  void _stopTimer() {
    if (_timer.isActive) {
      _timer.cancel();
    }
    setState(() {
      _isRunning = false;
    });
  }

  void _onTimerComplete() {
    setState(() {
      _isRunning = false;
    });

    // 타이머 완료 후 바로 활동 선택 바텀 시트 표시
    _showActivitySelectionBottomSheet();
  }

  Future<void> _showActivitySelectionBottomSheet() async {
    final selectedActivity = await showActivitySelectionBottomSheet(context);

    if (selectedActivity != null) {
      // 선택된 활동으로 공유 화면으로 이동
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder:
                (context) => MissionShareScreen(
                  selectedActivity: selectedActivity,
                  totalMinutes: widget.totalMinutes,
                ),
          ),
        );
      }
    } else {
      // 취소된 경우 타이머 화면 닫기
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  String _formatTime() {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isTablet = screenWidth > 600;

    return Scaffold(
      backgroundColor: const Color(0xFF146AFF),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/icons/Icon/mission/timer_backgroud.png'),
            fit: BoxFit.scaleDown,
            alignment: Alignment(0.0, 1),
            onError: (exception, stackTrace) {
              print('배경 이미지 로드 실패: $exception');
            },
          ),
        ),
        child: Stack(
          children: [
            // 메인 콘텐츠 영역
            Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: isTablet ? 32 : 16,
                      vertical: 16,
                    ),
                    child: Column(
                      children: [
                        // 상단 25% 지점까지의 여백
                        SizedBox(height: screenHeight * 0.2),

                        // 타이머 텍스트 (상단 25% 가운데)
                        Align(
                          alignment: Alignment(-0.1, 0.0),
                          child: Text(
                            _formatTime(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 80,
                              fontFamily: 'Archivo Black',
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),

                        const SizedBox(height: 400),

                        // 타이머 끄기 버튼 (타이머 시작하기와 같은 위치)
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: isTablet ? 32 : 16,
                          ),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                _showStopConfirmDialog();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF3A88F4),
                                padding: const EdgeInsets.all(16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 0,
                              ),
                              child: Text(
                                '타이머 끄기',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontFamily: 'Pretendard-Light',
                                  letterSpacing: -0.28,
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getCurrentTime() {
    final now = DateTime.now();
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  void _showStopConfirmDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            title: const Text(
              '타이머를 종료하시겠습니까?',
              style: TextStyle(fontFamily: 'Pretendard-Bold', fontSize: 16),
            ),
            content: const Text(
              '진행 중인 타이머가 중단됩니다.',
              style: TextStyle(
                fontFamily: 'Pretendard-Regular',
                fontSize: 14,
                color: Color(0xFF666666),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  '취소',
                  style: TextStyle(
                    color: Color(0xFF999999),
                    fontFamily: 'Pretendard-Medium',
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // 다이얼로그 닫기
                  _stopTimer();
                  Navigator.of(context).pop(); // 타이머 화면 닫기
                },
                child: const Text(
                  '종료',
                  style: TextStyle(
                    color: Color(0xFF146AFF),
                    fontFamily: 'Pretendard-Medium',
                  ),
                ),
              ),
            ],
          ),
    );
  }
}
