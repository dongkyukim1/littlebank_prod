import 'package:flutter/material.dart';
import '../../models/feed_data.dart';
import '../../theme/feed_styles.dart';
import '../../widgets/feed/components/feed_filter.dart';
import '../../widgets/feed/components/feed_list.dart' as feed_components;
import '../../widgets/feed/components/feed_tab_bar.dart';
import '../../widgets/feed/components/feed_ranking_list.dart';
import '../../widgets/mission_card.dart';
import 'create_post_screen.dart';
import 'home_screen.dart';
import 'chat_list_screen.dart';
import 'mission_screen.dart';
import 'my_page_screen.dart';

class FeedScreen extends StatefulWidget {
  final int initialTab; // 초기 탭 인덱스 (0: 피드, 1: 랭킹)

  const FeedScreen({super.key, this.initialTab = 0});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FeedData _feedData = FeedData();
  bool _isMissionCardExpanded = false;

  @override
  void initState() {
    super.initState();
    _feedData.selectedTabIndex = widget.initialTab; // 초기 탭 설정
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FeedStyles.backgroundColor,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // 고정 영역 시작 - 피드/랭킹 탭 선택 바
          FeedTabBar(
            selectedTabIndex: _feedData.selectedTabIndex,
            onTabChanged: _handleTabChange,
          ),

          // 고정 영역 - 검색 바
          feed_components.SearchBar(
            controller: _searchController,
            onSearch: _handleSearch,
          ),

          // 고정 영역 - 필터 버튼
          FeedFilter(
            feedData: _feedData,
            onFilterChange: _handleFilterChange,
            onGradeFilterChange: _handleGradeFilterChange,
          ),
          
          // 고정 영역 - 피드 정렬 타입 선택 (최신순/추천순)
          feed_components.SortTypeSelector(
            sortType: _feedData.sortType,
            onSortTypeChanged: _handleSortTypeChange,
          ),
          // 고정 영역 끝

          // 스크롤 영역 시작 - Expanded를 사용하여 남은 공간을 모두 차지하게 함
          Expanded(
            child: _feedData.selectedTabIndex == 0
              ? ListView(
                  children: [
                    // 글 작성 영역 (스크롤 영역에 포함)
                    feed_components.WritePostSection(
                      onWriteButtonPressed: _navigateToCreatePost,
                    ),
                    
                    // 피드 목록
                    feed_components.FeedList(
                      feedData: _feedData,
                      onToggleDescription: _handleToggleDescription,
                      onToggleLike: _handleToggleLike,
                    ),
                  ],
                )
              : const RankingList(),
          ),
          // 스크롤 영역 끝
        ],
      ),
      // 하단 네비게이션 바
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 미션 카드
          MissionCard(
            onExpandChanged: (isExpanded) {
              setState(() {
                _isMissionCardExpanded = isExpanded;
              });
            },
          ),

          // 하단 네비게이션 바
          Container(
            color: const Color(0xFF1E1E1E), // 어두운 회색 배경
            height: 80,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem('홈', false),
                _buildNavItem('채팅', false),
                _buildNavItem('미션', false),
                _buildNavItem('피드', true),
                _buildNavItem('마이', false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      title: const Text(
        '피드',
        style: TextStyle(
          color: Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          fontFamily: 'Pretendard',
        ),
      ),
      leading: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Image.asset('assets/images/app_logo.png', fit: BoxFit.contain),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: IconButton(
            icon: Image.asset(
              'assets/icons/Icon/검색/Regular.png',
              width: 24,
              height: 24,
              color: Colors.black,
            ),
            onPressed: () {},
          ),
        ),
        IconButton(
          icon: Image.asset(
            'assets/icons/Icon/알림/Regular.png',
            width: 24,
            height: 24,
            color: Colors.black,
          ),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildNavItem(String label, bool isSelected) {
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
        if (label == '홈') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        } else if (label == '채팅') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const ChatListScreen()),
          );
        } else if (label == '미션') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MissionScreen()),
          );
        } else if (label == '마이') {
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

  // 이벤트 핸들러 메서드들
  void _handleTabChange(int index) {
    setState(() {
      _feedData.changeTab(index);
    });
  }

  void _handleSortTypeChange(int type) {
    setState(() {
      _feedData.changeSortType(type);
    });
  }

  void _handleGradeFilterChange(int grade) {
    setState(() {
      if (grade == -1) {
        _feedData.isGradeFilterExpanded = false;
      } else {
        _feedData.toggleGradeFilter(grade);
      }
    });
  }

  void _handleFilterChange(int filterIndex, int optionIndex) {
    setState(() {
      if (optionIndex == -1) {
        _feedData.isFilterExpanded[filterIndex] = false;
      } else {
        _feedData.toggleFilter(filterIndex, optionIndex);
      }
    });
  }

  void _handleToggleDescription(int index) {
    setState(() {
      _feedData.toggleDescriptionExpanded(index);
    });
  }

  void _handleToggleLike(int index) {
    setState(() {
      _feedData.toggleLike(index);
    });
  }

  void _handleSearch(String query) {
    // 검색 기능 구현 (예: 피드 내용 필터링)
    print('검색어: $query');
  }

  void _navigateToCreatePost() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreatePostScreen()),
    );
  }
}
