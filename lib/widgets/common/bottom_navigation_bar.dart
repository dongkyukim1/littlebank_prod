import 'package:flutter/material.dart';
import '../../screens/child/home_screen.dart';
import '../../screens/child/chat_list_screen.dart';
import '../../screens/child/mission_screen.dart';
import '../../screens/child/feed_screen.dart';
import '../../screens/child/my_page_screen.dart';

class CommonBottomNavigationBar extends StatelessWidget {
  final int selectedIndex;

  const CommonBottomNavigationBar({
    super.key,
    required this.selectedIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1E1E1E),
      height: 80,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(context, '홈', 0),
          _buildNavItem(context, '채팅', 1),
          _buildNavItem(context, '미션', 2),
          _buildNavItem(context, '피드', 3),
          _buildNavItem(context, '마이', 4),
        ],
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, String label, int index) {
    final bool isSelected = index == selectedIndex;
    
    String iconName;
    if (label == '홈') {
      iconName = 'home';
    } else if (label == '채팅') {
      iconName = 'chat';
    } else if (label == '미션') {
      iconName = 'mission';
    } else if (label == '피드') {
      iconName = 'feed';
    } else { // 마이
      iconName = 'my';
    }
    
    String iconPath = 'assets/icons/$iconName.png';
    if (isSelected) {
      iconPath = 'assets/icons/fill_$iconName.png';
    }
    
    return InkWell(
      onTap: () {
        if (!isSelected) {
          _navigateToScreen(context, index);
        }
      },
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
              top: 15,
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
                    ),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: 60,
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isSelected ? const Color(0xFF10CB86) : Colors.white,
                        fontSize: 11,
                        fontFamily: 'Pretendard',
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

  void _navigateToScreen(BuildContext context, int index) {
    Widget screen;
    
    switch (index) {
      case 0:
        screen = const HomeScreen();
        break;
      case 1:
        screen = const ChatListScreen();
        break;
      case 2:
        screen = const MissionScreen();
        break;
      case 3:
        screen = const FeedScreen();
        break;
      case 4:
        screen = const MyPageScreen();
        break;
      default:
        screen = const HomeScreen();
    }
    
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }
} 