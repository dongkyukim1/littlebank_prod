import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'timer_running_screen.dart';

// 삼각형 말풍선 꼬리를 그리는 CustomPainter
class TrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = const Color(0xFF5D9EFF)
          ..style = PaintingStyle.fill;

    final path = Path();

    // 둥근 삼각형 그리기
    path.moveTo(size.width / 2, 0); // 위쪽 끝점

    // 왼쪽 모서리 (둥글게)
    path.quadraticBezierTo(
      size.width * 0.1,
      size.height * 0.7, // 제어점
      0,
      size.height, // 끝점
    );

    // 하단 (둥글게)
    path.quadraticBezierTo(
      size.width / 2,
      size.height * 0.9, // 제어점
      size.width,
      size.height, // 끝점
    );

    // 오른쪽 모서리 (둥글게)
    path.quadraticBezierTo(
      size.width * 0.9,
      size.height * 0.7, // 제어점
      size.width / 2,
      0, // 끝점
    );

    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

class TimerSettingScreen extends StatefulWidget {
  const TimerSettingScreen({super.key});

  @override
  State<TimerSettingScreen> createState() => _TimerSettingScreenState();
}

class _TimerSettingScreenState extends State<TimerSettingScreen> {
  int? selectedHours; // null로 초기화 (플레이스홀더)
  int? selectedMinutes; // null로 초기화 (플레이스홀더)
  bool isTimeSet = false; // 초기에는 비활성화

  // 스와이프 관련 변수들
  double _startY = 0;
  double _totalDeltaY = 0;
  bool _isLeftSide = false;
  double _lastChangedAt = 0; // 마지막으로 값이 변경된 위치

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF0F2F7),
        elevation: 0,
        leading: IconButton(
          icon: Image.asset(
            'assets/icons/Icon/뒤로 가기/Regular.png',
            width: 24,
            height: 24,
            color: Colors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '타이머 설정',
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontFamily: 'Pretendard-Bold',
            letterSpacing: -0.32,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 32 : 16,
                vertical: 16,
              ),
              child: Column(
                children: [
                  const SizedBox(height: 60),

                  // 로고 이미지
                  Image.asset(
                    'assets/icons/Icon/mission/black_logo.png',
                    width: 100,
                    height: 100,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.timer,
                          size: 50,
                          color: Colors.grey,
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  // 설명 텍스트 (말풍선 스타일)
                  Column(
                    children: [
                      // 위쪽 삼각형 (말풍선 꼬리)
                      Transform.translate(
                        offset: const Offset(0, 5),
                        child: CustomPaint(
                          size: const Size(20, 12),
                          painter: TrianglePainter(),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF5D9EFF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          '타이머를 시작하고 내가 집중한 시간을 체크해 보세요!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontFamily: 'Pretendard-Light',
                            height: 1.45,
                            letterSpacing: -0.22,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 60),

                  // 시간 설정 위젯
                  _buildTimePickerWidget(),

                  const SizedBox(height: 60),

                  // 타이머 시작하기 버튼
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isTablet ? 32 : 16,
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isTimeSet ? _startTimer : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isTimeSet
                                  ? const Color(0xFF3A88F4)
                                  : Colors.grey[400],
                          padding: const EdgeInsets.all(16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          '타이머 시작하기',
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
    );
  }

  Widget _buildTimePickerWidget() {
    return Container(
      width: 290,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0x4C5D9EFF),
            blurRadius: 12,
            offset: const Offset(3, 4),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: const Color(0x4C5D9EFF),
            blurRadius: 12,
            offset: const Offset(-3, 0),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          // 헤더 (시간, 분)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
            child: Row(
              children: [
                // 시간 영역 (50%)
                Expanded(
                  child: Text(
                    '시간',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: const Color(0xFF8490A3),
                      fontSize: 14,
                      fontFamily: 'Pretendard-Light',
                      letterSpacing: -0.28,
                    ),
                  ),
                ),
                // 분 영역 (50%)
                Expanded(
                  child: Text(
                    '분',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: const Color(0xFF8490A3),
                      fontSize: 14,
                      fontFamily: 'Pretendard-Light',
                      letterSpacing: -0.28,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 4),

          // 현재 설정된 시간 표시 (이전/다음 옵션과 함께)
          _buildTimePreviousOption(),
          _buildCurrentTimeDisplay(),
          _buildTimeNextOption(),
        ],
      ),
    );
  }

  Widget _buildTimePreviousOption() {
    final prevHours = (selectedHours ?? 1) > 0 ? (selectedHours ?? 1) - 1 : 23;
    final prevMinutes =
        (selectedMinutes ?? 5) > 0 ? (selectedMinutes ?? 5) - 5 : 55;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          // 시간 영역 (50%)
          Expanded(
            child: Text(
              selectedHours == null
                  ? '00'
                  : prevHours.toString().padLeft(2, '0'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFFC4C4C4),
                fontSize: 20,
                fontFamily: 'Pretendard-Light',
              ),
            ),
          ),
          // 분 영역 (50%)
          Expanded(
            child: Text(
              selectedMinutes == null
                  ? '00'
                  : prevMinutes.toString().padLeft(2, '0'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFFC4C4C4),
                fontSize: 20,
                fontFamily: 'Pretendard-Light',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentTimeDisplay() {
    return GestureDetector(
      onPanStart: (details) {
        // 스와이프 시작 위치 기록
        _startY = details.localPosition.dy;
        _totalDeltaY = 0;
        _lastChangedAt = 0;
        final containerWidth = 290.0; // 컨테이너 너비
        _isLeftSide = details.localPosition.dx < containerWidth / 2;
      },
      onPanUpdate: (details) {
        // 누적 이동 거리 계산
        _totalDeltaY += details.delta.dy;

        // 연속 스와이프 지원 - 30픽셀마다 값 변경
        const double continuousThreshold = 30.0;
        final double distanceFromLastChange =
            (_totalDeltaY - _lastChangedAt).abs();

        if (distanceFromLastChange > continuousThreshold) {
          // 햅틱 피드백
          HapticFeedback.selectionClick();

          setState(() {
            if (_totalDeltaY < _lastChangedAt) {
              // 위로 스와이프
              if (_isLeftSide) {
                selectedHours = ((selectedHours ?? 0) + 1).clamp(0, 23);
              } else {
                selectedMinutes = ((selectedMinutes ?? 0) + 5).clamp(0, 59);
              }
            } else {
              // 아래로 스와이프
              if (_isLeftSide) {
                selectedHours = ((selectedHours ?? 1) - 1).clamp(0, 23);
              } else {
                selectedMinutes = ((selectedMinutes ?? 5) - 5).clamp(0, 59);
              }
            }
            _updateTimeSetStatus();
          });

          // 마지막 변경 위치 업데이트
          _lastChangedAt = _totalDeltaY;
        }
      },
      onPanEnd: (details) {
        // 연속 스와이프에서 변경되지 않은 작은 스와이프 처리
        const double threshold = 20.0; // 최소 이동 거리 (픽셀)

        if (_totalDeltaY.abs() > threshold && _lastChangedAt == 0) {
          // 연속 스와이프가 발생하지 않은 경우에만 단일 변경
          HapticFeedback.lightImpact();

          setState(() {
            if (_totalDeltaY < 0) {
              // 위로 스와이프
              if (_isLeftSide) {
                selectedHours = ((selectedHours ?? 0) + 1).clamp(0, 23);
              } else {
                selectedMinutes = ((selectedMinutes ?? 0) + 5).clamp(0, 59);
              }
            } else {
              // 아래로 스와이프
              if (_isLeftSide) {
                selectedHours = ((selectedHours ?? 1) - 1).clamp(0, 23);
              } else {
                selectedMinutes = ((selectedMinutes ?? 5) - 5).clamp(0, 59);
              }
            }
            _updateTimeSetStatus();
          });
        }

        // 변수 초기화
        _totalDeltaY = 0;
        _lastChangedAt = 0;
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(width: 0.2, color: const Color(0xFF8590A3)),
            bottom: BorderSide(width: 0.2, color: const Color(0xFF8590A3)),
          ),
        ),
        child: Stack(
          children: [
            Row(
              children: [
                // 시간 영역 (50%)
                Expanded(
                  child: Text(
                    selectedHours == null
                        ? '시간'
                        : selectedHours.toString().padLeft(2, '0'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color:
                          selectedHours == null
                              ? const Color(0xFFC4C4C4)
                              : const Color(0xFF146AFF),
                      fontSize: selectedHours == null ? 20 : 24,
                      fontFamily:
                          selectedHours == null
                              ? 'Pretendard-Light'
                              : 'Pretendard-Bold',
                    ),
                  ),
                ),
                // 분 영역 (50%)
                Expanded(
                  child: Text(
                    selectedMinutes == null
                        ? '분'
                        : selectedMinutes.toString().padLeft(2, '0'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color:
                          selectedMinutes == null
                              ? const Color(0xFFC4C4C4)
                              : const Color(0xFF146AFF),
                      fontSize: selectedMinutes == null ? 20 : 24,
                      fontFamily:
                          selectedMinutes == null
                              ? 'Pretendard-Light'
                              : 'Pretendard-Bold',
                    ),
                  ),
                ),
              ],
            ),
            // 콜론을 중앙에 오버레이
            Positioned.fill(
              child: Center(
                child: Text(
                  ':',
                  style: TextStyle(
                    color:
                        (selectedHours != null || selectedMinutes != null)
                            ? const Color(0xFF146AFF)
                            : const Color(0xFFC4C4C4),
                    fontSize:
                        (selectedHours != null || selectedMinutes != null)
                            ? 24
                            : 20,
                    fontFamily: 'Pretendard-Medium',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeNextOption() {
    final nextHours = (selectedHours ?? 0) < 23 ? (selectedHours ?? 0) + 1 : 0;
    final nextMinutes =
        (selectedMinutes ?? 0) < 55 ? (selectedMinutes ?? 0) + 5 : 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          // 시간 영역 (50%)
          Expanded(
            child: Text(
              selectedHours == null
                  ? '01'
                  : nextHours.toString().padLeft(2, '0'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFFC4C4C4),
                fontSize: 20,
                fontFamily: 'Pretendard-Light',
              ),
            ),
          ),
          // 분 영역 (50%)
          Expanded(
            child: Text(
              selectedMinutes == null
                  ? '05'
                  : nextMinutes.toString().padLeft(2, '0'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFFC4C4C4),
                fontSize: 20,
                fontFamily: 'Pretendard-Light',
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _updateTimeSetStatus() {
    setState(() {
      isTimeSet =
          (selectedHours != null && selectedHours! > 0) ||
          (selectedMinutes != null && selectedMinutes! > 0);
    });
  }

  void _startTimer() {
    final totalMinutes = ((selectedHours ?? 0) * 60) + (selectedMinutes ?? 0);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TimerRunningScreen(totalMinutes: totalMinutes),
      ),
    );
  }
}
