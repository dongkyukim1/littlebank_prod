import 'package:flutter/material.dart';
import '../../screens/parent/home_screen.dart';
import '../../screens/parent/chat_list_screen.dart';
import '../../screens/parent/mission_screen.dart';
import '../../screens/parent/analysis/analysis_screen.dart';
import '../../screens/parent/my/my_page_screen.dart';

class ParentBottomNavigationBar extends StatelessWidget {
  final int selectedIndex;

  const ParentBottomNavigationBar({super.key, required this.selectedIndex});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1E1E1E), // 어두운 회색 배경
      height: 80,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(context, '홈', 0),
          _buildNavItem(context, '채팅', 1),
          _buildNavItem(context, '미션', 2),
          _buildNavItem(context, '분석', 3),
          _buildNavItem(context, '마이', 4),
        ],
      ),
    );
  }

  // 네비게이션 아이템 위젯 생성
  Widget _buildNavItem(BuildContext context, String label, int index) {
    bool isSelected = selectedIndex == index;

    // 아이콘 이름 결정
    String iconPath;
    if (label == '홈') {
      iconPath = 'assets/icons/parent/nav/home${isSelected ? "_blue" : ""}.png';
    } else if (label == '채팅') {
      iconPath = 'assets/icons/parent/nav/chat${isSelected ? "_blue" : ""}.png';
    } else if (label == '미션') {
      iconPath =
          isSelected
              ? 'assets/icons/fill_mission.png'
              : 'assets/icons/parent/nav/mission.png';
    } else if (label == '분석') {
      iconPath =
          'assets/icons/parent/nav/analysis${isSelected ? "_blue" : ""}.png';
    } else {
      // 마이
      iconPath = 'assets/icons/parent/nav/my${isSelected ? "_blue" : ""}.png';
    }

    return InkWell(
      onTap: () => _navigateToScreen(context, label, isSelected),
      child: SizedBox(
        width: 68,
        height: 80,
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            // 배경 및 그라데이션
            if (isSelected)
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment(0.50, -0.00),
                      end: Alignment(0.50, 1.00),
                      colors: [Color(0x1910CB86), Color(0x0011CB86)],
                    ),
                  ),
                ),
              ),

            // 인디케이터 (선택된 경우만)
            if (isSelected)
              Positioned(
                top: 0,
                child: Container(
                  width: 60,
                  height: 3,
                  decoration: const BoxDecoration(
                    color: Color(0xFF11CB86),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(2),
                      bottomRight: Radius.circular(2),
                    ),
                  ),
                ),
              ),

            // 아이콘과 텍스트
            Positioned(
              top: 15, // 상단 여백 조정
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Image.asset(
                      iconPath,
                      width: 24,
                      height: 24,
                      fit: BoxFit.contain,
                      errorBuilder:
                          (context, error, stackTrace) => Icon(
                            _getIconData(label),
                            size: 24,
                            color: Colors.white,
                          ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: 60, // 텍스트 너비 축소
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontFamily: 'Pretendard-Medium',
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.22,
                      ),
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

  // 아이콘 데이터 가져오기 (이미지 로드 실패시 대체용)
  IconData _getIconData(String label) {
    switch (label) {
      case '홈':
        return Icons.home;
      case '채팅':
        return Icons.chat;
      case '분석':
        return Icons.analytics;
      case '마이':
        return Icons.person;
      default:
        return Icons.help;
    }
  }

  // 화면 이동 처리
  void _navigateToScreen(BuildContext context, String label, bool isSelected) {
    if (isSelected) return;

    // 부드러운 페이드 애니메이션으로 화면 전환
    Widget targetScreen;

    if (label == '홈') {
      targetScreen = const ParentHomeScreen();
    } else if (label == '채팅') {
      targetScreen = const ParentChatListScreen();
    } else if (label == '미션') {
      targetScreen = const ParentMissionScreen();
    } else if (label == '분석') {
      targetScreen = const ParentAnalysisScreen();
    } else if (label == '마이') {
      targetScreen = const ParentMyPageScreen();
    } else {
      return;
    }

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => targetScreen,
        transitionDuration: const Duration(milliseconds: 200), // 빠른 전환
        reverseTransitionDuration: const Duration(milliseconds: 150),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // 부드러운 페이드 인/아웃 애니메이션
          return FadeTransition(
            opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOut, // 자연스러운 곡선
              ),
            ),
            child: child,
          );
        },
      ),
    );
  }

  void _showNotImplementedMessage(BuildContext context, String screenName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$screenName 화면은 아직 구현되지 않았습니다.'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
