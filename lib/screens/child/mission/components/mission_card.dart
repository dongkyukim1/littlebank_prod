import 'package:flutter/material.dart';

class MissionCard extends StatelessWidget {
  final String type;
  final String title;
  final double progress;
  final String days;
  final String reward;
  final String dDay;
  final double width;

  const MissionCard({
    super.key,
    required this.type,
    required this.title,
    required this.progress,
    required this.days,
    required this.reward,
    required this.dDay,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    final progressBarWidth = 310.0;
    final progressWidth = progressBarWidth * progress;
    
    return Material(
      elevation: 3, // 2에서 3으로 증가
      shadowColor: Colors.black54, // black38에서 black54로 더 진하게
      borderRadius: BorderRadius.circular(24), // 모서리 둥글게
      child: Container(
        width: width,
        height: 225, // 높이 축소 (265 -> 210)
        child: Column(
          children: [
            // 미션 상단부 (타입, 제목)
            Container(
              width: width,
              padding: const EdgeInsets.all(12),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 미션 타입 태그
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: ShapeDecoration(
                      color: const Color(0xFF5D9EFF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      type,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontFamily: 'Pretendard-Light',
                        letterSpacing: -0.24,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8), // 간격 축소 (12 -> 8)
                  // 미션 제목
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF353535),
                      fontSize: 14,
                      fontFamily: 'Pretendard-Bold',
                      letterSpacing: -0.32,
                    ),
                    maxLines: 2, // 최대 2줄로 제한
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // 미션 하단부 (진행률, 정보)
            Container(
              width: width,
              padding: const EdgeInsets.symmetric(vertical: 8), // 패딩 축소 (10 -> 8)
              decoration: const ShapeDecoration(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 진행률 표시 섹션
                  Column(
                    children: [
                      // 퍼센트 표시 (말풍선 스타일)
                      Container(
                        width: progressBarWidth * 0.85,
                        height: 25, // 말풍선 높이 줄임 (35 -> 25)
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Positioned(
                              left: () {
                                // 말풍선 너비 (padding 포함 전체 너비)
                                const double balloonWidth = 48; // 예상 너비
                                const double halfBalloonWidth = balloonWidth / 2;
                                
                                // 프로그레스바의 실제 너비
                                final double barWidth = progressBarWidth * 0.85;
                                
                                // 진행률에 따른 위치 계산
                                double balloonCenterX = barWidth * progress;
                                
                                // 말풍선의 left 위치 계산 (중앙 기준으로 계산)
                                double balloonLeft = balloonCenterX - halfBalloonWidth;
                                
                                // 경계 체크
                                // 최소값: 말풍선이 화면 왼쪽 밖으로 나가지 않도록
                                if (balloonLeft < 0) {
                                  balloonLeft = 0;
                                }
                                
                                // 최대값: 말풍선이 화면 오른쪽 밖으로 나가지 않도록
                                final double maxLeft = barWidth - balloonWidth;
                                if (balloonLeft > maxLeft) {
                                  balloonLeft = maxLeft;
                                }
                                
                                return balloonLeft;
                              }(),
                              top: 0,
                              child: Column(
                                children: [
                                  // 말풍선 몸체
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: ShapeDecoration(
                                      color: const Color(0xFF5D9EFF),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                    child: Text(
                                      '${(progress * 100).toInt()}%',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontFamily: 'Pretendard-Medium',
                                        letterSpacing: -0.22,
                                      ),
                                    ),
                                  ),
                                  // 말풍선 삼각형
                                  CustomPaint(
                                    size: const Size(10, 5),
                                    painter: TrianglePainter(
                                      color: const Color(0xFF5D9EFF),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // const SizedBox(height: 3), // 간격 제거
                      
                      // 프로그레스 바 (배경)
                      SizedBox(
                        height: 32,
                        child: Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.centerLeft,
                          children: [
                            // 배경 프로그레스 바
                            Container(
                              width: progressBarWidth * 0.85,
                              height: 18, // 살짝 더 높게
                              decoration: ShapeDecoration(
                                color: const Color(0xFFE4ECF8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12), // 더 둥글게
                                ),
                                shadows: const [
                                  BoxShadow(
                                    color: Color(0x0F000000),
                                    blurRadius: 1,
                                    offset: Offset(0, 1),
                                    spreadRadius: 0,
                                  ),
                                ],
                              ),
                            ),
                            
                            // 진행률 프로그레스 바
                            Container(
                              width: progressWidth * 0.85,
                              height: 18, // 살짝 더 높게
                              decoration: ShapeDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.centerLeft, // 방향 변경
                                  end: Alignment.centerRight,
                                  colors: [Color(0xFF10CB86), Color(0xFF5D9EFF)], // 초록->파랑
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12), // 더 둥글게
                                ),
                                shadows: const [
                                  BoxShadow(
                                    color: Color(0x29000000),
                                    blurRadius: 2,
                                    offset: Offset(0, 1),
                                    spreadRadius: 0,
                                  ),
                                ],
                              ),
                            ),
                            
                            // 25% 지점 세로 점선
                            Positioned(
                              left: progressBarWidth * 0.85 * 0.25,
                              child: _buildVerticalDashedLine(),
                            ),
                            
                            // 50% 지점 세로 점선
                            Positioned(
                              left: progressBarWidth * 0.85 * 0.5,
                              child: _buildVerticalDashedLine(),
                            ),
                            
                            // 75% 지점 세로 점선
                            Positioned(
                              left: progressBarWidth * 0.85 * 0.75,
                              child: _buildVerticalDashedLine(),
                            ),
                            
                            // 완료 아이콘 - 위치 오른쪽 끝으로 조정
                            Positioned(
                              right: -3,
                              top: 3,
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF5D9EFF),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.emoji_events,
                                  color: Color(0xFFFFD27F),
                                  size: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  // 정보 영역과 프로그레스바 사이 간격 추가
                  const SizedBox(height: 16), // 간격 축소 (25 -> 16)

                  // 미션 정보 (시작일, 보상금, 보상 지급일)
                  Container(
                    width: progressBarWidth * 0.95,
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      children: [
                        // 시작한 지
                        Expanded(
                          flex: 3,
                          child: _buildInfoColumn('시작한 지', days),
                        ),
                        // 세로선 1
                        Container(
                          height: 35,
                          width: 1,
                          color: const Color(0xFFE0E0E0),
                        ),
                        // 보상금 - 더 넓은 공간 할당
                        Expanded(
                          flex: 4, // 다른 항목보다 더 많은 공간
                          child: _buildInfoColumn('보상금', reward),
                        ),
                        // 세로선 2
                        Container(
                          height: 35,
                          width: 1,
                          color: const Color(0xFFE0E0E0),
                        ),
                        // 보상 지급까지
                        Expanded(
                          flex: 3,
                          child: _buildInfoColumn('보상 지급까지', dDay),
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
    );
  }

  Widget _buildInfoColumn(String title, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF666666),
            fontSize: 11,
            fontFamily: 'Pretendard-Light',
            letterSpacing: -0.28,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF5D9EFF),
            fontSize: 15,
            fontFamily: 'Pretendard-Bold',
            letterSpacing: -0.32,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildVerticalDashedLine() {
    return CustomPaint(
      size: const Size(1, 16),
      painter: DashedLinePainter(),
    );
  }
}

// 삼각형 화살표 페인터 (말풍선용)
class TrianglePainter extends CustomPainter {
  final Color color;

  TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    // 삼각형 그리기: 윗변 중앙에서 시작해서 아래로 뾰족하게
    path.moveTo(size.width / 2, size.height);
    path.lineTo(0, 0);
    path.lineTo(size.width, 0);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

// 개선된 점선 페인터
class DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.5 // 두께 증가
      ..style = PaintingStyle.stroke;
    
    // 외곽선 추가를 위한 검은색 페인트
    final borderPaint = Paint()
      ..color = Colors.black12
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    const dashHeight = 2;
    const dashSpace = 2;
    double startY = 0;

    // 세로 방향 점선 그리기 (테두리 먼저 그리고 그 위에 흰색)
    while (startY < size.height) {
      // 테두리
      canvas.drawLine(
        Offset(0, startY),
        Offset(0, startY + dashHeight),
        borderPaint,
      );
      // 흰색 점선
      canvas.drawLine(
        Offset(0, startY),
        Offset(0, startY + dashHeight),
        paint,
      );
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
} 