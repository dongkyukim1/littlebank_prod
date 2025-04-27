import 'package:flutter/material.dart';
import '../../screens/parent/home_screen.dart';
import '../../screens/parent/chat_list_screen.dart';
import '../../screens/parent/mission_screen.dart';
import '../../screens/parent/my_page_screen.dart';
import '../../theme/app_colors.dart';

class ParentBottomNavigationBar extends StatelessWidget {
  final int selectedIndex;

  const ParentBottomNavigationBar({
    super.key,
    required this.selectedIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Colors.black,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 7,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(context, 0, '홈'),
          _buildNavItem(context, 1, '채팅'),
          _buildNavItem(context, 2, '미션'),
          _buildNavItem(context, 3, '마이'),
        ],
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, int index, String label) {
    bool isSelected = selectedIndex == index;
    IconData iconData;

    switch (index) {
      case 0:
        iconData = Icons.home;
        break;
      case 1:
        iconData = Icons.chat;
        break;
      case 2:
        iconData = Icons.assignment;
        break;
      case 3:
        iconData = Icons.person;
        break;
      default:
        iconData = Icons.circle;
    }

    return GestureDetector(
      onTap: () => _navigateToScreen(context, index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              iconData,
              size: 24,
              color: isSelected ? AppColors.primaryColor : Colors.grey,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? AppColors.primaryColor : Colors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToScreen(BuildContext context, int index) {
    if (selectedIndex == index) return;

    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ParentHomeScreen()),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ParentChatListScreen()),
        );
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ParentMissionScreen()),
        );
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ParentMyPageScreen()),
        );
        break;
    }
  }

  void showNotImplementedMessage(BuildContext context, String screenName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$screenName 화면은 아직 구현되지 않았습니다.'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
} 