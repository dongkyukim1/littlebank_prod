import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'chat_start_screen.dart';

class SearchHistoryScreen extends StatefulWidget {
  const SearchHistoryScreen({super.key});

  @override
  State<SearchHistoryScreen> createState() => _SearchHistoryScreenState();
}

class _SearchHistoryScreenState extends State<SearchHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<String> _recentSearches = [];
  List<String> _filteredSearches = [];
  List<Map<String, dynamic>> _filteredProfiles = [];
  bool _isSearching = false;
  bool _isSearchFocused = false;

  // 서버에서 가져올 친구 목록 데이터 (목업 데이터 제거)
  List<Map<String, dynamic>> _friendProfiles = [];
  List<Map<String, dynamic>> _otherProfiles = [];

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(() {
      setState(() {
        _isSearchFocused = _searchFocusNode.hasFocus;
      });
    });
    // 기존 검색 기록 모두 삭제 후 새로 시작
    _clearAllSearchesFromStorage();
    _loadRecentSearches();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  // 검색어 저장 (shared_preferences에)
  Future<void> _saveSearchesToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('recentSearches', _recentSearches);
      print('검색어 저장됨: $_recentSearches');
    } catch (e) {
      print('검색어 저장 실패: $e');
    }
  }

  // 저장된 모든 검색어 완전히 삭제 (SharedPreferences 초기화)
  Future<void> _clearAllSearchesFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('recentSearches');
      _recentSearches = [];
      print('모든 검색 기록이 삭제되었습니다.');
    } catch (e) {
      print('검색어 삭제 실패: $e');
    }
  }

  // 검색어 불러오기 (로컬용)
  Future<void> _loadRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _recentSearches = prefs.getStringList('recentSearches') ?? [];
      });
      print('검색어 불러옴: $_recentSearches');
    } catch (e) {
      print('검색어 로드 실패: $e');
      setState(() {
        _recentSearches = [];
      });
    }
  }

  // 검색어 저장하기
  Future<void> _saveSearch(String query) async {
    if (query.isEmpty) return;

    setState(() {
      // 중복 검색어 제거
      _recentSearches.removeWhere((item) => item == query);

      // 최근 검색어 목록 맨 앞에 추가
      _recentSearches.insert(0, query);

      // 검색어 개수 제한 (최대 20개)
      if (_recentSearches.length > 20) {
        _recentSearches = _recentSearches.sublist(0, 20);
      }
    });

    // 검색어 저장
    _saveSearchesToPrefs();
  }

  // 검색어 삭제
  Future<void> _removeSearch(String query) async {
    setState(() {
      _recentSearches.removeWhere((item) => item == query);
    });

    // 검색어 저장
    _saveSearchesToPrefs();
  }

  // 모든 검색어 삭제
  Future<void> _clearAllSearches() async {
    setState(() {
      _recentSearches.clear();
    });

    // 검색어 저장
    _saveSearchesToPrefs();
  }

  // 검색어 필터링
  void _filterSearches(String query) {
    print('검색어 입력: $query');

    if (query.isEmpty) {
      setState(() {
        _filteredSearches = [];
        _filteredProfiles = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;

      // 대소문자 구분 없이 검색어 기록 필터링
      _filteredSearches =
          _recentSearches
              .where((item) => item.toLowerCase().contains(query.toLowerCase()))
              .toList();

      // 친구 목록에서도 검색 (이름으로 검색)
      _filteredProfiles =
          [..._friendProfiles, ..._otherProfiles]
              .where(
                (profile) => profile['name'].toString().toLowerCase().contains(
                  query.toLowerCase(),
                ),
              )
              .toList();

      print('검색 결과: $_filteredSearches');
      print('검색된 친구: ${_filteredProfiles.map((p) => p['name']).toList()}');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // 검색 바
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Row(
                children: [
                  // 뒤로 가기 버튼
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 28,
                      height: 28,
                      margin: const EdgeInsets.only(right: 12),
                      child: const Icon(
                        Icons.arrow_back_ios,
                        color: Color(0xFF202020),
                        size: 20,
                      ),
                    ),
                  ),
                  // 검색창
                  Expanded(
                    child: Container(
                      height: 44, // 고정 높이 설정
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 0,
                      ),
                      decoration: ShapeDecoration(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          side: BorderSide(
                            width: _isSearchFocused ? 1.2 : 0.60,
                            color: _isSearchFocused ? const Color(0xFF146AFF) : const Color(0xFF8490A3),
                          ),
                          borderRadius: BorderRadius.circular(32),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.search,
                            color: Color(0xFF8490A3),
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Center(
                              child: TextField(
                                controller: _searchController,
                                focusNode: _searchFocusNode,
                                onChanged: _filterSearches,
                                textAlign: TextAlign.left,
                                textAlignVertical: TextAlignVertical.center,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontFamily: 'Pretendard-Regular',
                                ),
                                decoration: const InputDecoration(
                                  hintText: '채팅 상대,채팅방 이름을 검색해 주세요',
                                  hintStyle: TextStyle(
                                    color: Color(0xFF4A4A4A),
                                    fontSize: 12,
                                    fontFamily: 'Pretendard-Light',
                                    letterSpacing: -0.24,
                                  ),
                                  isCollapsed: true,
                                  contentPadding: EdgeInsets.zero,
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                ),
                                onSubmitted: (value) {
                                  if (value.isNotEmpty) {
                                    _saveSearch(value);
                                    setState(() {
                                      _isSearching = false;
                                    });
                                  }
                                },
                              ),
                            ),
                          ),
                          if (_searchController.text.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _searchController.clear();
                                  _isSearching = false;
                                  _filteredSearches = [];
                                });
                              },
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFFCCCCCC),
                                ),
                                child: const Icon(
                                  Icons.close,
                                  size: 18,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 검색 결과가 없을 때 최근 검색어 표시
            if (!_isSearching)
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 최근 검색 헤더
                      if (_recentSearches.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                '최근 검색했어요',
                                style: TextStyle(
                                  color: Color(0xFF202020),
                                  fontSize: 16,
                                  fontFamily: 'Pretendard-Bold',
                                  letterSpacing: -0.72,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => _clearAllSearches(),
                                child: const Text(
                                  '전체 삭제',
                                  style: TextStyle(
                                    color: Color(0xFFCCCCCC),
                                    fontSize: 12,
                                    fontFamily: 'Pretendard-Light',
                                    letterSpacing: -0.24,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // 검색어 칩 목록
                      if (_recentSearches.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 10,
                            children:
                                _recentSearches
                                    .map((search) => _buildSearchChip(search))
                                    .toList(),
                          ),
                        ),

                      const SizedBox(height: 16),

                      // 내 친구 헤더
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: const [
                                  Text(
                                    '내 친구',
                                    style: TextStyle(
                                      color: Color(0xFF202020),
                                      fontSize: 18,
                                      fontFamily: 'Pretendard-Bold',
                                      letterSpacing: -0.72,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    '12',
                                    style: TextStyle(
                                      color: Color(0xFF3A88F4),
                                      fontSize: 18,
                                      fontFamily: 'Pretendard-Bold',
                                      letterSpacing: -0.72,
                                    ),
                                  ),
                                ],
                              ),
                              const Text(
                                '전체 보기',
                                style: TextStyle(
                                  color: Color(0xFFCCCCCC),
                                  fontSize: 12,
                                  fontFamily: 'Pretendard-Light',
                                  letterSpacing: -0.24,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // 친구 목록 1 (3개만 표시)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: ShapeDecoration(
                            color: const Color(0xFFEFF2F6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Column(
                            children: [
                              // 친구 프로필 목록 표시 (3개)
                              ..._friendProfiles
                                  .take(3)
                                  .map((profile) => _buildFriendItem(profile)),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // 구분선
                      Container(
                        width: double.infinity,
                        height: 6,
                        decoration: const ShapeDecoration(
                          color: Color(0xFFEFF2F6),
                          shape: RoundedRectangleBorder(
                            side: BorderSide(
                              width: 0.10,
                              color: Color(0xFF8490A3),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // 프로필 더 보기 헤더
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    '프로필 더 보기',
                                    style: TextStyle(
                                      color: Color(0xFF202020),
                                      fontSize: 18,
                                      fontFamily: 'Pretendard-Bold',
                                      letterSpacing: -0.72,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: const Icon(
                                      Icons.help_outline,
                                      size: 18,
                                      color: Color(0xFF8490A3),
                                    ),
                                  ),
                                ],
                              ),
                              const Text(
                                '전체 보기',
                                style: TextStyle(
                                  color: Color(0xFFCCCCCC),
                                  fontSize: 12,
                                  fontFamily: 'Pretendard-Light',
                                  letterSpacing: -0.24,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // 친구 목록 2
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: ShapeDecoration(
                            color: const Color(0xFFEFF2F6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Column(
                            children: [
                              // 다른 친구 프로필 목록 표시
                              ..._otherProfiles.map(
                                (profile) => _buildFriendItem(profile),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),
                    ],
                  ),
                ),
              ),

            // 검색 중일 때 필터링된 결과 표시
            if (_isSearching)
              Expanded(
                child:
                    _filteredSearches.isEmpty && _filteredProfiles.isEmpty
                        ? const Center(
                          child: Text(
                            '검색 결과가 없습니다',
                            style: TextStyle(
                              color: Color(0xFF999999),
                              fontSize: 14,
                              fontFamily: 'Pretendard-Regular',
                            ),
                          ),
                        )
                        : SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 최근 검색어 결과
                              if (_filteredSearches.isNotEmpty) ...[
                                const Padding(
                                  padding: EdgeInsets.only(bottom: 8),
                                  child: Text(
                                    '최근 검색어',
                                    style: TextStyle(
                                      color: Color(0xFF202020),
                                      fontSize: 16,
                                      fontFamily: 'Pretendard-Bold',
                                    ),
                                  ),
                                ),
                                ...List.generate(_filteredSearches.length, (
                                  index,
                                ) {
                                  final search = _filteredSearches[index];
                                  return Container(
                                    decoration: const BoxDecoration(
                                      border: Border(
                                        bottom: BorderSide(
                                          color: Color(0xFFEEEEEE),
                                          width: 1,
                                        ),
                                      ),
                                    ),
                                    child: ListTile(
                                      leading: const Icon(
                                        Icons.history,
                                        color: Color(0xFF8490A3),
                                        size: 20,
                                      ),
                                      title: Text(
                                        search,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontFamily: 'Pretendard-Regular',
                                        ),
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            vertical: 4,
                                          ),
                                      dense: true,
                                      onTap: () {
                                        _searchController.text = search;
                                        _saveSearch(search);
                                        FocusScope.of(
                                          context,
                                        ).unfocus(); // 키보드 닫기
                                        setState(() {
                                          _isSearching = false;
                                        });
                                      },
                                    ),
                                  );
                                }),
                              ],

                              // 친구 검색 결과
                              if (_filteredProfiles.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                const Padding(
                                  padding: EdgeInsets.only(bottom: 8),
                                  child: Text(
                                    '검색된 친구',
                                    style: TextStyle(
                                      color: Color(0xFF202020),
                                      fontSize: 16,
                                      fontFamily: 'Pretendard-Bold',
                                    ),
                                  ),
                                ),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  decoration: ShapeDecoration(
                                    color: const Color(0xFFEFF2F6),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: Column(
                                    children:
                                        _filteredProfiles
                                            .map(
                                              (profile) =>
                                                  _buildFriendItem(profile),
                                            )
                                            .toList(),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
              ),
          ],
        ),
      ),
    );
  }

  // 검색 칩 위젯
  Widget _buildSearchChip(String label) {
    return Container(
      height: 44,
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          // 검색어 선택 시 실행
          _searchController.text = label;
          _saveSearch(label);
          _filterSearches(label); // 필터링 실행
          setState(() {
            _isSearching = true;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: ShapeDecoration(
            color: const Color(0xFFEFF2F6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF202020),
                  fontSize: 14,
                  fontFamily: 'Pretendard-Regular',
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _removeSearch(label),
                child: const Icon(
                  Icons.close,
                  size: 16,
                  color: Color(0xFF8490A3),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 친구 항목 위젯
  Widget _buildFriendItem(Map<String, dynamic> profile) {
    return GestureDetector(
      onTap: () {
        // 프로필 화면으로 바로 이동
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => ChatStartScreen(
                  userId: profile['name'],
                  userName: profile['name'],
                  userDescription:
                      profile['description'].isNotEmpty
                          ? profile['description']
                          : '',
                ),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        height: 78, // 76px에서 78px로 높이 증가
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ), // 12px에서 10px로 패딩 감소
        decoration: ShapeDecoration(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center, // 중앙 정렬
          children: [
            // 프로필 이미지
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: const DecorationImage(
                  // 모든 프로필에 동일한 이미지 사용
                  image: AssetImage('assets/icons/Icon/chat/profile.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 20),

            // 이름 및 상태 메시지
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    profile['name'],
                    style: const TextStyle(
                      color: Color(0xFF202020),
                      fontSize: 15, // 16px에서 15px로 폰트 크기 감소
                      fontFamily: 'Pretendard-Bold',
                      letterSpacing: -0.32,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  if (profile['description'].isNotEmpty)
                    const SizedBox(height: 2), // 4px에서 2px로 여백 축소
                  if (profile['description'].isNotEmpty)
                    Text(
                      profile['description'],
                      style: const TextStyle(
                        color: Color(0xFF999999),
                        fontSize: 13, // 14px에서 13px로 폰트 크기 감소
                        fontFamily: 'Pretendard-Light',
                        letterSpacing: -0.28,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
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
