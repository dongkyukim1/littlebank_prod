import 'package:flutter/material.dart';
import '../../widgets/parent/bottom_navigation_bar.dart';
import 'widgets/allowance_card.dart';
import 'widgets/mission_section.dart';
import 'widgets/study_highlight_card.dart';

// 선 그래프 그리기 위한 CustomPainter
class LineChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 데이터 포인트 (7개 일자의 공부 시간, 위치를 적절히 조정해야 함)
    final points = [
      Offset(size.width * 0.05, size.height * 0.8), // 4.14 - 시작점
      Offset(size.width * 0.18, size.height * 0.4), // 4.15 - 높은점
      Offset(size.width * 0.35, size.height * 0.6), // 4.16 - 중간점
      Offset(size.width * 0.5, size.height * 0.7), // 4.17 - 낮은점
      Offset(size.width * 0.65, size.height * 0.5), // 4.18 - 중간점
      Offset(size.width * 0.82, size.height * 0.3), // 4.19 - 5시간 달성 최고점
      Offset(size.width * 0.95, size.height * 0.6), // 4.20 - 끝점
    ];

    // 수평 보조선 그리기
    final gridPaint =
        Paint()
          ..color = Colors.grey.withOpacity(0.2)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8;

    // 보조선 두 개만 그리기 - 2번째 사진과 같은 위치로 조정
    final gridPositions = [0.08, 0.75];
    final graphStartX = size.width * 0.05; // 그래프 시작점 x 좌표
    final graphEndX = size.width * 0.95; // 그래프 끝점 x 좌표
    for (final position in gridPositions) {
      final y = size.height * position;
      canvas.drawLine(Offset(graphStartX, y), Offset(graphEndX, y), gridPaint);
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

    // 데이터 포인트에 점 표시 (5시간 달성 지점에만 특별한 점 표시)
    for (int i = 0; i < points.length; i++) {
      if (i == 5) {
        // 5시간 달성 지점 (4.19)
        // 중앙 점
        final dotPaint =
            Paint()
              ..color = Colors.white
              ..style = PaintingStyle.fill;

        // 테두리
        final outlinePaint =
            Paint()
              ..color = const Color(0xFF146AFF)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.5;

        canvas.drawCircle(points[i], 6, dotPaint); // 점 크기 키움
        canvas.drawCircle(points[i], 6, outlinePaint);
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class ParentHomeScreen extends StatefulWidget {
  final String initialRole;

  const ParentHomeScreen({super.key, this.initialRole = 'PARENT'});

  @override
  State<ParentHomeScreen> createState() => _ParentHomeScreenState();
}

class _ParentHomeScreenState extends State<ParentHomeScreen> {
  final int _selectedIndex = 0; // 홈 탭 선택

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE7ECF6),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      const AllowanceCard(),
                      const SizedBox(height: 16),
                      WeeklyGoalSection(
                        showMissionCreationModal: _showMissionCreationModal,
                      ),
                      const SizedBox(height: 16),
                      const StudyHighlightCard(),
                      const SizedBox(height: 16), // 여백 축소
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: ParentBottomNavigationBar(selectedIndex: 0),
    );
  }

  // 앱바 위젯 구현
  Widget _buildAppBar() {
    return Container(
      width: double.infinity,
      height: 60, // 높이 증가
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 8,
      ), // 상하 패딩 감소
      color: const Color(0xFFE7ECF6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 왼쪽 로고
          Image.asset(
            'assets/logos/parent_logo.png',
            width: 28,
            height: 28,
            fit: BoxFit.contain,
          ),

          // 오른쪽 아이콘들 (프로필 및 알림)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 프로필 아이콘
              Container(
                width: 32,
                height: 32,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDC963),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: const Center(
                    child: Text(
                      '부',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),

              // 알림 아이콘
              SizedBox(
                width: 24,
                height: 24,
                child: Icon(
                  Icons.notifications_none_rounded,
                  color: Colors.black,
                  size: 25,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 미션 생성 모달 표시
  void _showMissionCreationModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return const MissionCreationModal();
      },
    );
  }
}
