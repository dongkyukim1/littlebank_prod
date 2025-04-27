import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/child/mission_screen.dart';
import 'screens/child/chat_list_screen.dart';
import 'screens/child/feed_screen.dart';
import 'widgets/mission_card.dart';

class HomeScreen extends StatefulWidget {
  final String userType;

  const HomeScreen({super.key, this.userType = 'student'});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  late String _username;
  late double _allowance;
  bool _isMissionCardExpanded = false;

  @override
  void initState() {
    super.initState();

    // 사용자 유형에 따라 다른 데이터 설정
    if (widget.userType == 'student') {
      _username = "리틀뱅크";
      _allowance = 36000;
    } else if (widget.userType == 'parent') {
      _username = "리틀뱅크 부모님";
      _allowance = 50000;
    } else {
      // teacher
      _username = "리틀뱅크 선생님";
      _allowance = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(50.0),
        child: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, '홈', Icons.home, true),
              _buildNavItem(1, '채팅', Icons.chat_bubble_outline, false),
              _buildNavItem(2, '미션', Icons.flag_outlined, false),
              _buildNavItem(3, '피드', Icons.dynamic_feed, false),
              _buildNavItem(4, '마이', Icons.person_outline, false),
            ],
          ),
        ),
      ),
      body: _buildHomeTab(),
    );
  }

  Widget _buildNavItem(
    int index,
    String label,
    IconData icon,
    bool isSelected,
  ) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });

        // 네비게이션 처리
        if (index == 2) {
          // 미션 화면
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MissionScreen()),
          );
        } else if (index == 1) {
          // 채팅 화면
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const ChatListScreen()),
          );
        } else if (index == 3) {
          // 피드 화면
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const FeedScreen()),
          );
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? AppTheme.primaryColor : Colors.grey,
            size: 20,
          ),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? AppTheme.primaryColor : Colors.grey,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeTab() {
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAllowanceCard(),
              const SizedBox(height: 16),
              _buildGoalProgressCard(),
              const SizedBox(height: 16),
              _buildTopUsersCard(),
              const SizedBox(height: 16),
              _buildWeeklyGoalCard(),
              const SizedBox(height: 16),
              _buildChallengeSection(),
              if (_isMissionCardExpanded)
                SizedBox(height: MediaQuery.of(context).size.height * 0.4),
            ],
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: MissionCard(
            onExpandChanged: (isExpanded) {
              setState(() {
                _isMissionCardExpanded = isExpanded;
              });
            },
          ),
        ),
      ],
    );
  }

  // 각 섹션을 위한 메서드 스텁
  Widget _buildAllowanceCard() {
    return Card(
      elevation: 8,
      shadowColor: const Color(0x24000000),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 360,
        padding: const EdgeInsets.all(16),
        child: const Text('용돈 카드'),
      ),
    );
  }

  Widget _buildGoalProgressCard() {
    return Card(
      elevation: 8,
      shadowColor: const Color(0x24000000),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 360,
        padding: const EdgeInsets.all(16),
        child: const Text('목표 진행 상황 카드'),
      ),
    );
  }

  Widget _buildTopUsersCard() {
    return Card(
      elevation: 8,
      shadowColor: const Color(0x24000000),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 360,
        padding: const EdgeInsets.all(16),
        child: const Text('상위 사용자 카드'),
      ),
    );
  }

  Widget _buildWeeklyGoalCard() {
    return Card(
      elevation: 8,
      shadowColor: const Color(0x24000000),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 360,
        padding: const EdgeInsets.all(16),
        child: const Text('주간 목표 카드'),
      ),
    );
  }

  Widget _buildChallengeSection() {
    return Card(
      elevation: 8,
      shadowColor: const Color(0x24000000),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 360,
        padding: const EdgeInsets.all(16),
        child: const Text('챌린지 섹션'),
      ),
    );
  }
}
