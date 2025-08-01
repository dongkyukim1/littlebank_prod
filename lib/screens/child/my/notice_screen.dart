import 'package:flutter/material.dart';

class NoticeScreen extends StatefulWidget {
  const NoticeScreen({super.key});

  @override
  State<NoticeScreen> createState() => _NoticeScreenState();
}

class _NoticeScreenState extends State<NoticeScreen> {
  int _selectedTabIndex = 0;
  final List<String> _tabNames = ['전체', '일반', '업데이트'];

  // 검색 기능을 위한 변수 추가
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          '공지사항',
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontFamily: 'Pretendard-Bold',
            letterSpacing: -0.32,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: Image.asset('assets/icons/my/뒤로가기.png', width: 20, height: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // 탭 영역
          const SizedBox(height: 16),
          _buildTabBar(),

          // 검색창
          const SizedBox(height: 24),
          _buildSearchBar(),
          const SizedBox(height: 16),

          // 공지사항 목록
          Expanded(child: _buildNoticeList()),
        ],
      ),
    );
  }

  // 탭 바 위젯
  Widget _buildTabBar() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 28,
          child: Row(
            children: List.generate(
              _tabNames.length,
              (index) => Expanded(child: _buildTabItem(index)),
            ),
          ),
        ),
        Container(
          width: double.infinity,
          height: 1,
          color: const Color(0xFFEEEEEE),
        ),
      ],
    );
  }

  // 탭 아이템 위젯
  Widget _buildTabItem(int index) {
    final bool isSelected = _selectedTabIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTabIndex = index;
        });
      },
      child: Column(
        children: [
          Expanded(
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Text(
                  _tabNames[index],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color:
                        isSelected
                            ? const Color(0xFF202020)
                            : const Color(0xFF999999),
                    fontSize: 14,
                    fontFamily:
                        isSelected ? 'Pretendard-Medium' : 'Pretendard-Light',
                    letterSpacing: -0.32,
                  ),
                ),
                Positioned(
                  left: -10,
                  top: 0,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: const Color(0xFF146AFF),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 선택된 탭 아래에 블랙 라인 표시
          Container(
            height: 2,
            color: isSelected ? Colors.black : Colors.transparent,
          ),
        ],
      ),
    );
  }

  // 검색창 위젯
  Widget _buildSearchBar() {
    return Container(
      width: double.infinity,
      height: 40,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: ShapeDecoration(
        shape: RoundedRectangleBorder(
          side: const BorderSide(width: 1, color: Color(0xFFDADADA)),
          borderRadius: BorderRadius.circular(32),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Center(
            child: Image.asset('assets/icons/my/검색.png', width: 24, height: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.trim().toLowerCase();
                });
              },
              textAlignVertical: TextAlignVertical.center,
              style: const TextStyle(
                color: Color(0xFF202020),
                fontSize: 14,
                fontFamily: 'Pretendard-Light',
                letterSpacing: -0.28,
              ),
              decoration: const InputDecoration(
                hintText: '찾고싶은 내용을 입력해 주세요',
                hintStyle: TextStyle(
                  color: Color(0xFF999999),
                  fontSize: 14,
                  fontFamily: 'Pretendard-ExtraLight',
                  letterSpacing: -0.28,
                ),
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 0),
                isDense: true,
                isCollapsed: true,
              ),
            ),
          ),
          // 검색어가 있을 때만 X 버튼 표시
          if (_searchQuery.isNotEmpty)
            GestureDetector(
              onTap: () {
                setState(() {
                  _searchController.clear();
                  _searchQuery = '';
                });
              },
              child: const Icon(
                Icons.close,
                color: Color(0xFF999999),
                size: 20,
              ),
            ),
        ],
      ),
    );
  }

  // 공지사항 목록 위젯
  Widget _buildNoticeList() {
    // 공지사항 데이터 (실제로는 API에서 가져오겠지만 예시로 하드코딩)
    final List<Map<String, String>> noticeData = [
      {
        'type': '혜택',
        'title': '하나보단 셋이서! 멤버들과 구독했을 때 커지는 혜택 알아보기',
        'date': '2025. 04. 15',
      },
      {
        'type': '공지',
        'title': '서비스 정기 점검에 따른 서비스 일시 중지 안내',
        'date': '2025. 04. 15',
      },
      {
        'type': '공지',
        'title': '서비스의 일시적인 오류에 따른 불편함을 드려 죄송합니다.',
        'date': '2025. 04. 15',
      },
      {
        'type': '공지',
        'title': '신규 기능 안내 - 내 친구들이 포인트를 모은 방법',
        'date': '2025. 04. 15',
      },
      {'type': '업데이트', 'title': 'v. 1. 25 업데이트 안내', 'date': '2025. 04. 15'},
    ];

    // 선택된 탭과 검색어에 따라 필터링
    List<Map<String, String>> filteredNotices =
        noticeData.where((notice) {
          bool matchesTab =
              _selectedTabIndex == 0 ||
              (_selectedTabIndex == 1 && notice['type'] != '업데이트') ||
              (_selectedTabIndex == 2 && notice['type'] == '업데이트');

          bool matchesSearch =
              _searchQuery.isEmpty ||
              notice['title']!.toLowerCase().contains(_searchQuery) ||
              notice['type']!.toLowerCase().contains(_searchQuery);

          return matchesTab && matchesSearch;
        }).toList();

    if (filteredNotices.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              '검색 결과가 없습니다',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 16,
                fontFamily: 'Pretendard-Regular',
                letterSpacing: -0.32,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: filteredNotices.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final notice = filteredNotices[index];
        return _buildNoticeItem(
          type: notice['type']!,
          title: notice['title']!,
          date: notice['date']!,
        );
      },
    );
  }

  // 공지사항 아이템 위젯
  Widget _buildNoticeItem({
    required String type,
    required String title,
    required String date,
  }) {
    return Container(
      constraints: const BoxConstraints(minHeight: 64),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 'N' 표시 원형 아이콘
          SizedBox(
            width: 18,
            height: 18,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 18,
                  height: 18,
                  decoration: const ShapeDecoration(
                    color: Color(0xFF5D9EFF),
                    shape: OvalBorder(),
                  ),
                ),
                const Positioned(
                  child: Text(
                    'N',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontFamily: 'Pretendard-Medium',
                      letterSpacing: -0.24,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // 공지사항 내용
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '[$type] ',
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 14,
                          fontFamily: 'Pretendard-Light',
                          height: 1.5,
                          letterSpacing: -0.28,
                        ),
                      ),
                      TextSpan(
                        text: title,
                        style: const TextStyle(
                          color: Color(0xFF202020),
                          fontSize: 14,
                          fontFamily: 'Pretendard-ExtraLight',
                          height: 1.5,
                          letterSpacing: -0.28,
                        ),
                      ),
                    ],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  date,
                  style: const TextStyle(
                    color: Color(0xBF999999),
                    fontSize: 12,
                    fontFamily: 'Pretendard-Light',
                    letterSpacing: -0.24,
                  ),
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),

          // 화살표 아이콘
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(
              Icons.chevron_right,
              color: Color(0xFFCCCCCC),
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}
