import 'package:flutter/material.dart';
import '../../screens/child/home_screen.dart';
import '../../screens/child/chat_list_screen.dart';
import '../../screens/child/feed_screen.dart';
import '../../screens/child/my_page_screen.dart';

class BottomNavigationWidget extends StatelessWidget {
  final int selectedIndex;

  const BottomNavigationWidget({super.key, required this.selectedIndex});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1E1E1E), // 어두운 회색 배경
      height: 80,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildBottomNavItem(context, '홈', selectedIndex == 0),
          _buildBottomNavItem(context, '채팅', selectedIndex == 1),
          _buildBottomNavItem(context, '미션', selectedIndex == 2),
          _buildBottomNavItem(context, '피드', selectedIndex == 3),
          _buildBottomNavItem(context, '마이', selectedIndex == 4),
        ],
      ),
    );
  }

  Widget _buildBottomNavItem(
    BuildContext context,
    String label,
    bool isSelected,
  ) {
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
        if (label == '홈' && !isSelected) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        } else if (label == '채팅' && !isSelected) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const ChatListScreen()),
          );
        } else if (label == '피드' && !isSelected) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const FeedScreen()),
          );
        } else if (label == '마이' && !isSelected) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MyPageScreen()),
          );
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
                    ),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: 60, // 텍스트 너비 축소
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
}
