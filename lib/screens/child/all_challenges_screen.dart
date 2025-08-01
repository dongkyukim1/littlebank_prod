import 'package:flutter/material.dart';
import 'challenge_detail_screen.dart';
import '../../widgets/common/bottom_navigation_bar.dart';

class AllChallengesScreen extends StatefulWidget {
  const AllChallengesScreen({super.key});

  @override
  State<AllChallengesScreen> createState() => _AllChallengesScreenState();
}

class _AllChallengesScreenState extends State<AllChallengesScreen> {
  String _selectedFilter = '전체';
  final List<String> _filters = ['전체', '요일별', '과목별', '주별', '월별'];
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // 전체 챌린지 목록
  final List<Map<String, dynamic>> _allChallenges = [
    {
      'periodType': '요일별',
      'title': '일주일동안 매일 공부 3시간',
      'participants': '30/40',
      'period': '3.20 - 3.27',
      'time': '매일 3시간',
    },
    {
      'periodType': '과목별',
      'title': '일주일동안 매일 공부',
      'participants': '25/50',
      'period': '3.1 - 3.31',
      'time': '매일 30분',
    },
    {
      'periodType': '주별',
      'title': '아침 6시 기상하기',
      'participants': '45/60',
      'period': '3.15 - 3.22',
      'time': '매일 오전 6시',
    },
    {
      'periodType': '월별',
      'title': '하루 30분 독서하기',
      'participants': '28/35',
      'period': '3.1 - 3.31',
      'time': '매일 30분',
    },
    {
      'periodType': '주별',
      'title': '주 3회 조깅하기',
      'participants': '20/30',
      'period': '3.18 - 3.25',
      'time': '주 3회',
    },
    {
      'periodType': '월별',
      'title': '하루 물 2리터 마시기',
      'participants': '15/30',
      'period': '3.1 - 3.31',
      'time': '매일',
    },
    {
      'periodType': '요일별',
      'title': '주말 영어 단어 50개 외우기',
      'participants': '22/35',
      'period': '3.15 - 4.15',
      'time': '주말 1시간',
    },
    {
      'periodType': '과목별',
      'title': '수학 문제집 하루 5페이지',
      'participants': '18/40',
      'period': '3.10 - 4.10',
      'time': '매일 30분',
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // 필터링된 챌린지 목록
  List<Map<String, dynamic>> get _filteredChallenges {
    if (_selectedFilter == '전체') {
      return _allChallenges;
    } else {
      return _allChallenges
          .where((challenge) => challenge['periodType'] == _selectedFilter)
          .toList();
    }
  }

  // 검색을 통해 필터링된 챌린지 목록
  List<Map<String, dynamic>> _searchChallenges(String query) {
    if (query.isEmpty) {
      return [];
    }

    return _allChallenges
        .where(
          (challenge) =>
              challenge['title'].toLowerCase().contains(query.toLowerCase()) ||
              challenge['periodType'].toLowerCase().contains(
                query.toLowerCase(),
              ) ||
              challenge['time'].toLowerCase().contains(query.toLowerCase()),
        )
        .toList();
  }

  // 챌린지 검색 모달 표시
  void _showSearchModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final searchResults = _searchChallenges(_searchQuery);

            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  // 모달 상단 핸들
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // 검색 헤더
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                    child: Row(
                      children: [
                        const Text(
                          '챌린지 검색',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Pretendard',
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.grey),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),

                  // 검색창
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F2F7),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: '챌린지 이름, 유형, 시간 등으로 검색',
                          hintStyle: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 14,
                            fontFamily: 'Pretendard',
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: Colors.grey[600],
                          ),
                          suffixIcon:
                              _searchQuery.isNotEmpty
                                  ? IconButton(
                                    icon: const Icon(
                                      Icons.clear,
                                      color: Colors.grey,
                                    ),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {
                                        _searchQuery = '';
                                      });
                                    },
                                  )
                                  : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                      ),
                    ),
                  ),

                  // 구분선
                  const Divider(height: 1),

                  // 검색 결과
                  Expanded(
                    child:
                        _searchQuery.isEmpty
                            ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.search,
                                    size: 48,
                                    color: Colors.grey[300],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    '관심있는 챌린지를 검색해보세요',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 16,
                                      fontFamily: 'Pretendard',
                                    ),
                                  ),
                                ],
                              ),
                            )
                            : searchResults.isEmpty
                            ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.search_off,
                                    size: 48,
                                    color: Colors.grey[300],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    '검색 결과가 없습니다',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 16,
                                      fontFamily: 'Pretendard',
                                    ),
                                  ),
                                ],
                              ),
                            )
                            : ListView.separated(
                              padding: const EdgeInsets.all(20),
                              itemCount: searchResults.length,
                              separatorBuilder:
                                  (context, index) => const Divider(height: 24),
                              itemBuilder: (context, index) {
                                final challenge = searchResults[index];
                                final timeValue =
                                    challenge['time'] == '매일 3시간' ||
                                            challenge['time'] == '매일 30분'
                                        ? '설정 가능'
                                        : challenge['time'];

                                return InkWell(
                                  onTap: () {
                                    Navigator.pop(context); // 모달 닫기
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) => ChallengeDetailScreen(
                                              type: challenge['periodType'],
                                              title: challenge['title'],
                                              participants:
                                                  challenge['participants'],
                                              period: challenge['period'],
                                              time: challenge['time'],
                                            ),
                                      ),
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // 유형 태그
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFEFF2F6),
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: Text(
                                            challenge['periodType'],
                                            style: const TextStyle(
                                              color: Color(0xFF5D9EFF),
                                              fontSize: 11,
                                              fontFamily: 'Pretendard',
                                              fontWeight: FontWeight.w300,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 8),

                                        // 제목
                                        Text(
                                          challenge['title'],
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'Pretendard',
                                          ),
                                        ),
                                        const SizedBox(height: 8),

                                        // 정보
                                        Row(
                                          children: [
                                            Text(
                                              '참여: ${challenge['participants']}',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFF666666),
                                                fontFamily: 'Pretendard',
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Text(
                                              '기간: ${challenge['period']}',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFF666666),
                                                fontFamily: 'Pretendard',
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Text(
                                              '시간: $timeValue',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFF666666),
                                                fontFamily: 'Pretendard',
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE7ECF6),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(50.0),
        child: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            '모든 챌린지',
            style: TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'Pretendard',
            ),
          ),
          centerTitle: true,
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
                onPressed: _showSearchModal,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // 필터 버튼 목록
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _filters.length,
              separatorBuilder: (context, index) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final isSelected = _selectedFilter == _filters[index];
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedFilter = _filters[index];
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? const Color(0xFF5D9EFF)
                              : const Color(0xFFF0F2F7),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow:
                          isSelected
                              ? [
                                BoxShadow(
                                  color: const Color(
                                    0xFF5D9EFF,
                                  ).withOpacity(0.2),
                                  spreadRadius: 1,
                                  blurRadius: 2,
                                  offset: const Offset(0, 1),
                                ),
                              ]
                              : null,
                    ),
                    child: Text(
                      _filters[index],
                      style: TextStyle(
                        color:
                            isSelected ? Colors.white : const Color(0xFF353535),
                        fontSize: 13,
                        fontWeight:
                            isSelected ? FontWeight.w500 : FontWeight.w400,
                        fontFamily: 'Pretendard',
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // 챌린지 목록
          Expanded(
            child:
                _filteredChallenges.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            'assets/images/empty_state.png',
                            width: 80,
                            height: 80,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '현재 진행 중인 챌린지가 없습니다',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                              fontFamily: 'Pretendard',
                            ),
                          ),
                        ],
                      ),
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredChallenges.length,
                      itemBuilder: (context, index) {
                        final challenge = _filteredChallenges[index];
                        // 시간 값이 매일 3시간 또는 매일 30분이면 설정 가능으로 표시
                        final String timeValue =
                            challenge['time'] == '매일 3시간' ||
                                    challenge['time'] == '매일 30분'
                                ? '설정 가능'
                                : challenge['time'];

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                spreadRadius: 0,
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => ChallengeDetailScreen(
                                          type: challenge['periodType'],
                                          title: challenge['title'],
                                          participants:
                                              challenge['participants'],
                                          period: challenge['period'],
                                          time: challenge['time'],
                                        ),
                                  ),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // 타입 라벨
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: ShapeDecoration(
                                        color: const Color(0xFFEFF2F6),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        challenge['periodType'],
                                        style: const TextStyle(
                                          color: Color(0xFF5D9EFF),
                                          fontSize: 11,
                                          fontFamily: 'Pretendard',
                                          fontWeight: FontWeight.w300,
                                          letterSpacing: -0.24,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),

                                    // 제목
                                    Text(
                                      challenge['title'],
                                      style: const TextStyle(
                                        color: Color(0xFF353535),
                                        fontSize: 17,
                                        fontFamily: 'Pretendard',
                                        fontWeight: FontWeight.w700,
                                        height: 1.2,
                                        letterSpacing: -0.5,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 16),

                                    // 정보 영역
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const SizedBox(
                                          width: 65,
                                          child: Text(
                                            '참여 인원',
                                            style: TextStyle(
                                              color: Color(0xFF999999),
                                              fontSize: 14,
                                              fontFamily: 'Pretendard',
                                              fontWeight: FontWeight.w300,
                                            ),
                                          ),
                                        ),
                                        Flexible(
                                          child: Text.rich(
                                            TextSpan(
                                              children: [
                                                TextSpan(
                                                  text:
                                                      challenge['participants']
                                                          .split('/')[0] +
                                                      '/',
                                                  style: const TextStyle(
                                                    color: Color(0xFF89DA8D),
                                                    fontSize: 14,
                                                    fontFamily: 'Pretendard',
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                                TextSpan(
                                                  text:
                                                      challenge['participants']
                                                          .split('/')[1],
                                                  style: const TextStyle(
                                                    color: Color(0xFF4A4A4A),
                                                    fontSize: 14,
                                                    fontFamily: 'Pretendard',
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),

                                    // 기한
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const SizedBox(
                                          width: 65,
                                          child: Text(
                                            '기한',
                                            style: TextStyle(
                                              color: Color(0xFF999999),
                                              fontSize: 14,
                                              fontFamily: 'Pretendard',
                                              fontWeight: FontWeight.w300,
                                            ),
                                          ),
                                        ),
                                        Flexible(
                                          child: Text(
                                            challenge['period'],
                                            style: const TextStyle(
                                              color: Color(0xFF4A4A4A),
                                              fontSize: 14,
                                              fontFamily: 'Pretendard',
                                              fontWeight: FontWeight.w500,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),

                                    // 시간
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const SizedBox(
                                          width: 65,
                                          child: Text(
                                            '시간',
                                            style: TextStyle(
                                              color: Color(0xFF999999),
                                              fontSize: 14,
                                              fontFamily: 'Pretendard',
                                              fontWeight: FontWeight.w300,
                                            ),
                                          ),
                                        ),
                                        Flexible(
                                          child: Text(
                                            timeValue,
                                            style: const TextStyle(
                                              color: Color(0xFF4A4A4A),
                                              fontSize: 14,
                                              fontFamily: 'Pretendard',
                                              fontWeight: FontWeight.w500,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 16),

                                    // 참여하기 버튼
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      decoration: ShapeDecoration(
                                        color: const Color(0xFF5D9EFF),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        shadows: [
                                          BoxShadow(
                                            color: const Color(
                                              0xFF5D9EFF,
                                            ).withOpacity(0.2),
                                            spreadRadius: 0,
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: const Center(
                                        child: Text(
                                          '참여하기',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontFamily: 'Pretendard',
                                            fontWeight: FontWeight.w400,
                                            letterSpacing: -0.28,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
      bottomNavigationBar: const CommonBottomNavigationBar(selectedIndex: 2),
    );
  }
}
