import 'package:flutter/material.dart';

// LineChartPainter 클래스를 이 파일에 직접 정의합니다
class LineChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 데이터 포인트 (7개 일자의 공부 시간, 위치를 적절히 조정해야 함)
    final points = [
      Offset(size.width * 0.05, size.height * 0.8),    // 4.14 - 시작점
      Offset(size.width * 0.18, size.height * 0.4),    // 4.15 - 높은점
      Offset(size.width * 0.35, size.height * 0.6),    // 4.16 - 중간점
      Offset(size.width * 0.5, size.height * 0.7),     // 4.17 - 낮은점
      Offset(size.width * 0.65, size.height * 0.5),    // 4.18 - 중간점
      Offset(size.width * 0.82, size.height * 0.3),    // 4.19 - 5시간 달성 최고점
      Offset(size.width * 0.95, size.height * 0.6),    // 4.20 - 끝점
    ];

    // 수평 보조선 그리기
    final gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    // 보조선 두 개만 그리기 - 2번째 사진과 같은 위치로 조정
    final gridPositions = [0.05, 0.75];
    final graphStartX = size.width * 0.05;  // 그래프 시작점 x 좌표
    final graphEndX = size.width * 0.95;    // 그래프 끝점 x 좌표  
    for (final position in gridPositions) {
      final y = size.height * position;
      canvas.drawLine(
        Offset(graphStartX, y),
        Offset(graphEndX, y),
        gridPaint,
      );
    }

    // 선을 위한 페인트 정의 - 더 굵고 진한 색상으로 변경
    final linePaint = Paint()
      ..color = const Color(0xFF146AFF).withOpacity(0.8)  // 불투명도 증가
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5;  // 더 굵게

    // 아래 영역 채우기를 위한 페인트 - 그라데이션 강화
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF146AFF).withOpacity(0.7),  // 더 진하게
          const Color(0xFF146AFF).withOpacity(0.4),  // 중간 투명도
          const Color(0xFF146AFF).withOpacity(0.1),  // 약간 투명
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
        controlPoint1.dx, controlPoint1.dy,
        controlPoint2.dx, controlPoint2.dy,
        p1.dx, p1.dy
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

    // 데이터 포인트에 점 표시 (5시간 달성 지점에만 특별한 점 표시)
    for (int i = 0; i < points.length; i++) {
      if (i == 5) { // 5시간 달성 지점 (4.19)
        // 중앙 점
        final dotPaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill;
        
        // 테두리
        final outlinePaint = Paint()
          ..color = const Color(0xFF146AFF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;
        
        canvas.drawCircle(points[i], 6, dotPaint);  // 점 크기 키움
        canvas.drawCircle(points[i], 6, outlinePaint);
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class StudyHighlightCard extends StatelessWidget {
  const StudyHighlightCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: const Color(0x35000000),
            blurRadius: 8,
            offset: const Offset(3, 4),
            spreadRadius: 0,
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 상단 제목 영역
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(left: 20, right: 20, top: 12, bottom: 0),  // 상단 패딩 증가, 하단 패딩 제거
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,  // 중앙 정렬
              children: [
                Text(
                  '이번 달 우리 아이 공부 하이라이트',
                  style: TextStyle(
                    color: const Color(0xFF202020),
                    fontSize: 18,
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.72,
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down,
                  color: Colors.grey,
                  size: 24,
                ),
              ],
            ),
          ),
          
          // 시간 표시 영역
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(left: 20, right: 20, top: 4, bottom: 4),  // 하단 패딩 추가
            decoration: const BoxDecoration(color: Colors.white),
            child: Transform.translate(  // Transform 위젯 추가하여 시간 텍스트만 위로 이동
              offset: const Offset(0, -4),  // y축으로 -4px 이동
              child: Text(
                '3시간 30분',
                style: TextStyle(
                  color: const Color(0xFF146AFF),
                  fontSize: 28,
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w700,
                  letterSpacing: -1.12,
                ),
              ),
            ),
          ),
          
          // 탭 영역
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(left: 20, right: 20, top: 4, bottom: 4),  // 패딩 축소
            decoration: const BoxDecoration(color: Colors.white),
            child: Row(
              children: [
                _buildStudyTab('총 학습 시간', true),
                const SizedBox(width: 8),
                _buildStudyTab('총 달성률', false),
                const SizedBox(width: 8),
                _buildStudyTab('총 상승률', false),
              ],
            ),
          ),
          
          // 그래프 영역
          Stack(
            children: [
              Container(
                width: double.infinity,
                height: 200,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: const BoxDecoration(color: Colors.white),
                child: CustomPaint(
                  painter: LineChartPainter(), // line_chart_painter.dart 파일에서 가져온 클래스
                  size: Size(double.infinity, 170),
                ),
              ),
              
              // 달성 라벨 - 최고점(흰색 원) 위에 위치하도록 조정
              Positioned(
                right: 40,   
                top: 25,    
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: ShapeDecoration(
                    color: const Color(0xFFFFD27F),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(
                    '5시간 달성',
                    style: TextStyle(
                      color: const Color(0xFF001F55),
                      fontSize: 12,
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.24,
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          // 날짜 표시 영역
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
            decoration: const BoxDecoration(color: Colors.white),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildDateText('4.14'),
                _buildDateText('4.15'),
                _buildDateText('4.16'),
                _buildDateText('4.17'),
                _buildDateText('4.18'),
                _buildDateText('4.19'),
                _buildDateText('4.20'),
              ],
            ),
          ),
          
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
                color: const Color(0xFF146AFF),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Center(
                child: Text(
                  '칭찬 메시지 전송하기',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.28,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 학습 탭 위젯
  Widget _buildStudyTab(String text, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: ShapeDecoration(
        color: isSelected ? const Color(0xFF146AFF) : Colors.white,
        shape: RoundedRectangleBorder(
          side: BorderSide(
            width: 1,
            color: isSelected ? Colors.transparent : Colors.grey.withOpacity(0.3),
          ),
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.grey,
          fontSize: 12,
          fontFamily: 'Pretendard',
          fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
          letterSpacing: -0.24,
        ),
      ),
    );
  }

  // 날짜 텍스트 위젯
  Widget _buildDateText(String date) {
    return Text(
      date,
      style: TextStyle(
        color: const Color(0xFF999999),
        fontSize: 12,
        fontFamily: 'Pretendard',
        fontWeight: FontWeight.w300,
        letterSpacing: -0.24,
      ),
    );
  }
} 