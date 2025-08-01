import 'package:flutter/material.dart';
import '../../../services/relationship_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'components/friend_item.dart';
import 'components/profile_item.dart';
import 'components/search_chip.dart';
import 'components/frequent_friend_item.dart';
import 'modals/add_friend_modal.dart';
import '../chat_detail_screen.dart';

class FriendListScreen extends StatefulWidget {
  const FriendListScreen({super.key});

  @override
  State<FriendListScreen> createState() => _FriendListScreenState();
}

class _FriendListScreenState extends State<FriendListScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _recentSearches = [];
  List<String> _filteredSearches = [];
  String _searchQuery = '';
  bool _showRecentSearch = false;
  bool _isSearching = false;
  final FocusNode _searchFocus = FocusNode();
  bool _isSearchFocused = false;

  // 초성 필터 관련
  String _selectedInitial = '';
  final List<String> _koreanInitials = [
    'ㄱ',
    'ㄴ',
    'ㄷ',
    'ㄹ',
    'ㅁ',
    'ㅂ',
    'ㅅ',
    'ㅇ',
    'ㅈ',
    'ㅎ',
  ];

  // 서버에서 받아온 친구 목록 데이터 관리
  List<dynamic> _friendData = [];
  List<Map<String, dynamic>> _filteredProfiles = [];
  bool _isLoading = false;
  bool _hasError = false;
  int _currentPage = 0;
  bool _hasMoreData = true;
  final ScrollController _scrollController = ScrollController();

  // 친구 데이터와 가족 멤버를 합친 목록
  List<dynamic> get _mergedFriendList {
    return _friendData;
  }

  // 친구 데이터를 분리
  List<dynamic> get _bestFriends =>
      _mergedFriendList
          .where((friend) => friend['isBestFriend'] == true)
          .toList();
  List<dynamic> get _normalFriends =>
      _mergedFriendList
          .where((friend) => friend['isBestFriend'] != true)
          .toList();

  // 초성으로 필터링된 친구 목록
  List<dynamic> get _filteredBestFriends {
    if (_selectedInitial.isEmpty) return _bestFriends;
    return _bestFriends.where((friend) {
      final userInfo = friend['userInfo'] ?? {};
      final name = friend['customName'] ?? userInfo['userName'] ?? '이름 없음';
      final initial = _getKoreanInitial(name);
      return initial == _selectedInitial;
    }).toList();
  }

  List<dynamic> get _filteredNormalFriends {
    if (_selectedInitial.isEmpty) return _normalFriends;
    return _normalFriends.where((friend) {
      final userInfo = friend['userInfo'] ?? {};
      final name = friend['customName'] ?? userInfo['userName'] ?? '이름 없음';
      final initial = _getKoreanInitial(name);
      return initial == _selectedInitial;
    }).toList();
  }

  // 검색어로 필터링된 친구 목록
  List<dynamic> get _filteredFriends {
    if (_searchQuery.isEmpty) {
      return [];
    }

    return _mergedFriendList.where((friendData) {
      final userInfo = friendData['userInfo'] ?? {};
      final name = friendData['customName'] ?? userInfo['userName'] ?? '이름 없음';
      return name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
    _initializeData();

    // 포커스 변경 리스너 추가
    _searchFocus.addListener(() {
      setState(() {
        _isSearchFocused = _searchFocus.hasFocus;
        if (!_searchFocus.hasFocus) {
          _showRecentSearch = false;
        } else {
          _showRecentSearch = true;
        }
      });
    });

    // 스크롤 리스너로 페이지네이션 처리
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !_isLoading &&
          _hasMoreData) {
        _fetchFriendList();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    _scrollController.dispose();
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

  // 검색어 불러오기
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
      _recentSearches.removeWhere((item) => item == query);
      _recentSearches.insert(0, query);
      if (_recentSearches.length > 20) {
        _recentSearches = _recentSearches.sublist(0, 20);
      }
    });

    _saveSearchesToPrefs();
  }

  // 검색어 삭제
  Future<void> _removeSearch(String query) async {
    setState(() {
      _recentSearches.removeWhere((item) => item == query);
    });
    _saveSearchesToPrefs();
  }

  // 모든 검색어 삭제
  Future<void> _clearAllSearches() async {
    setState(() {
      _recentSearches.clear();
    });
    _saveSearchesToPrefs();
  }

  // 한글 완성 여부 확인 함수
  bool _isKoreanComplete(String char) {
    if (char.isEmpty) return false;
    int code = char.codeUnitAt(0);
    return code >= 0xAC00 && code <= 0xD7A3;
  }

  // 한글 초성 추출 함수
  String _getKoreanInitial(String name) {
    if (name.isEmpty) return '';

    const initials = [
      'ㄱ',
      'ㄲ',
      'ㄴ',
      'ㄷ',
      'ㄸ',
      'ㄹ',
      'ㅁ',
      'ㅂ',
      'ㅃ',
      'ㅅ',
      'ㅆ',
      'ㅇ',
      'ㅈ',
      'ㅉ',
      'ㅊ',
      'ㅋ',
      'ㅌ',
      'ㅍ',
      'ㅎ',
    ];

    int code = name.codeUnitAt(0);
    if (code >= 0xAC00 && code <= 0xD7A3) {
      int initialIndex = ((code - 0xAC00) / 588).floor();
      return initials[initialIndex];
    }

    return name[0].toUpperCase();
  }

  // 검색어 필터링
  void _filterSearches(String query) {
    print('검색어 입력: $query');
    setState(() {
      _searchQuery = query;

      if (query.isEmpty) {
        _filteredSearches = [];
        _filteredProfiles = [];
        _isSearching = false;
        return;
      }

      if (query.length == 3 && _isKoreanComplete(query[2])) {
        _saveSearch(query);
        _showRecentSearch = false;
        _isSearching = true;
      } else {
        _isSearching = true;
      }

      _filteredSearches =
          _recentSearches
              .where((item) => item.toLowerCase().contains(query.toLowerCase()))
              .toList();

      // 친구 목록에서 검색
      _filteredProfiles =
          _mergedFriendList
              .map((friend) {
                final userInfo = friend['userInfo'] ?? {};
                final friendInfo = friend['friendInfo'] ?? {};
                final name =
                    friend['customName'] ??
                    friendInfo['customName'] ??
                    userInfo['realName'] ??
                    userInfo['userName'] ??
                    '이름 없음';
                final profileImagePath = userInfo['profileImagePath'] ?? '';
                final isBlocked =
                    friend['isBlocked'] ?? friendInfo['isBlocked'] ?? false;
                final isBestFriend =
                    friend['isBestFriend'] ??
                    friendInfo['isBestFriend'] ??
                    false;
                final friendId =
                    friend['friendId'] ?? friendInfo['friendId'] ?? 0;
                final userId = userInfo['userId'] ?? 0;
                final statusMessage = userInfo['statusMessage'] ?? '';

                String profileImageUrl = '';
                if (profileImagePath != null &&
                    profileImagePath.toString().isNotEmpty) {
                  if (profileImagePath.toString().startsWith('http')) {
                    profileImageUrl = profileImagePath.toString();
                  } else if (profileImagePath.toString().startsWith(
                    'images/',
                  )) {
                    profileImageUrl =
                        'https://littlebank-dev.s3.ap-northeast-2.amazonaws.com/$profileImagePath';
                  }
                }

                return {
                  'name': name,
                  'description':
                      isBlocked
                          ? '차단됨'
                          : (statusMessage != null && statusMessage.isNotEmpty
                              ? statusMessage
                              : (isBestFriend ? '친한 친구' : '')),
                  'friendId': friendId,
                  'userId': userId,
                  'profileImageUrl': profileImageUrl,
                  'isBlocked': isBlocked,
                  'isBestFriend': isBestFriend,
                };
              })
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

  // 서버에서 친구 목록 조회
  Future<void> _fetchFriendList({bool refresh = false}) async {
    if (_isLoading || (!_hasMoreData && !refresh)) return;

    setState(() {
      _isLoading = true;
      if (refresh) {
        _currentPage = 0;
        _friendData = [];
        _hasMoreData = true;
      }
    });

    try {
      final result = await RelationshipService.getFriendList();

      if (result != null) {
        setState(() {
          final List<dynamic> newFriends = result;

          print('===== 친구 목록 데이터 구조 확인 =====');
          print('응답 데이터: $result');
          for (var friend in newFriends) {
            print('친구 데이터: $friend');
            print('friendId: ${friend['friendId']}');
            print('userInfo: ${friend['userInfo']}');
            if (friend['userInfo'] != null) {
              print('userId: ${friend['userInfo']['userId']}');
            }
            print('-----------------------');
          }

          if (refresh) {
            _friendData = newFriends;
          } else {
            _friendData.addAll(newFriends);
          }

          // 전체 조회이므로 더 불러올 데이터 없음
          _hasMoreData = false;

          _isLoading = false;
          _hasError = false;
        });

        print('가족 정보가 없습니다. 친구 목록만 표시합니다.');
      } else {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    } catch (e) {
      print('친구 목록 로딩 중 오류 발생: $e');
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  // 데이터 초기화 함수
  Future<void> _initializeData() async {
    try {
      await _fetchFriendList(refresh: true);
    } catch (e) {
      print('데이터 초기화 중 오류 발생: $e');
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_hasError || _friendData.isEmpty) {
          return true;
        }
        Navigator.of(context).pop({'friendListUpdated': true});
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 40),
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => ParentChatDetailScreen(
                        roomId: 0,
                        userId: 0,
                        userName: '새 채팅',
                        avatar: '💬',
                      ),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: ShapeDecoration(
                color: const Color(0xFF146AFF), // 부모단 테마 색상
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/icons/chat_floating.png',
                    width: 18,
                    height: 18,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '채팅하기',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontFamily: 'Pretendard-Light',
                      letterSpacing: -0.56,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  // 상단 헤더 - 내 친구 목록 (검색 중이 아닐 때만 표시)
                  if (!_isSearching && !_showRecentSearch)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      color: Colors.white,
                      child: Stack(
                        children: [
                          // 뒤로가기 버튼 (왼쪽)
                          Positioned(
                            left: 0,
                            top: 0,
                            bottom: 0,
                            child: GestureDetector(
                              onTap: () {
                                Navigator.of(
                                  context,
                                ).pop({'friendListUpdated': true});
                              },
                              child: Container(
                                width: 24,
                                height: 24,
                                child: Image.asset(
                                  'assets/icons/parent/뒤로가기.png',
                                  width: 24,
                                  height: 24,
                                ),
                              ),
                            ),
                          ),
                          // 제목 (가운데)
                          Center(
                            child: const Text(
                              '내 친구 목록',
                              style: TextStyle(
                                color: Color(0xFF202020),
                                fontSize: 16,
                                fontFamily: 'Pretendard-Bold',
                                letterSpacing: -0.64,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // 검색 바
                  Container(
                    padding: EdgeInsets.all(16),
                    color: Colors.white,
                    child: Row(
                      children: [
                        // 검색 중일 때 뒤로가기 버튼
                        if (_isSearching || _showRecentSearch) ...[
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _searchController.clear();
                                _searchQuery = '';
                                _isSearching = false;
                                _showRecentSearch = false;
                                _filteredSearches = [];
                                _searchFocus.unfocus();
                              });
                            },
                            child: Container(
                              width: 24,
                              height: 24,
                              child: Image.asset(
                                'assets/icons/parent/뒤로가기.png',
                                width: 24,
                                height: 24,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                        ],
                        // 검색창
                        Expanded(
                          child: Container(
                            height: 44,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: ShapeDecoration(
                              color: const Color(0xFFE7ECF6),
                              shape: RoundedRectangleBorder(
                                side: BorderSide(
                                  width: _isSearchFocused ? 1.2 : 0.60,
                                  color:
                                      _isSearchFocused ||
                                              _searchQuery.isNotEmpty
                                          ? const Color(0xFF146AFF) // 부모단 테마 색상
                                          : const Color(0xFF5D6A7F),
                                ),
                                borderRadius: BorderRadius.circular(32),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  child: Image.asset(
                                    'assets/icons/Icon/검색/Regular.png',
                                    width: 24,
                                    height: 24,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    controller: _searchController,
                                    focusNode: _searchFocus,
                                    onChanged: _filterSearches,
                                    textAlign: TextAlign.left,
                                    textAlignVertical: TextAlignVertical.center,
                                    style: const TextStyle(
                                      color: Color(0xFF202020),
                                      fontSize: 12,
                                      fontFamily: 'Pretendard-Light',
                                      letterSpacing: -0.48,
                                    ),
                                    decoration: const InputDecoration(
                                      hintText: '찿고싶은 채팅 상대를 검색해 주세요',
                                      hintStyle: TextStyle(
                                        color: Color(0xFF999999),
                                        fontSize: 12,
                                        fontFamily: 'Pretendard-Light',
                                        letterSpacing: -0.48,
                                      ),
                                      filled: true,
                                      fillColor: Color(0xFFE7ECF6),
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
                                    onTap: () {
                                      setState(() {
                                        _showRecentSearch = true;
                                        _isSearching = false;
                                      });
                                    },
                                  ),
                                ),
                                if (_searchController.text.isNotEmpty)
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _searchController.clear();
                                        _searchQuery = '';
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

                  // 최근 검색 헤더
                  if (_showRecentSearch && !_isSearching)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      color: Colors.white,
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
                          TextButton(
                            onPressed: () => _clearAllSearches(),
                            child: const Text(
                              '전체 삭제',
                              style: TextStyle(
                                color: Color(0xFF8490A3),
                                fontSize: 12,
                                fontFamily: 'Pretendard-Light',
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // 검색어 칩 표시 (최근 검색 모드일 때)
                  if (_showRecentSearch && !_isSearching)
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),

                            if (_recentSearches.isNotEmpty) ...[
                              Container(
                                width: double.infinity,
                                alignment: Alignment.centerLeft,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: Wrap(
                                  alignment: WrapAlignment.start,
                                  crossAxisAlignment: WrapCrossAlignment.start,
                                  spacing: 4,
                                  runSpacing: 4,
                                  children:
                                      _recentSearches
                                          .take(10)
                                          .map(
                                            (search) => SearchChip(
                                              label: search,
                                              onTap: () {
                                                _searchController.text = search;
                                                _saveSearch(search);
                                                _filterSearches(search);
                                                setState(() {
                                                  _isSearching = true;
                                                });
                                              },
                                              onRemove:
                                                  () => _removeSearch(search),
                                            ),
                                          )
                                          .toList(),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                  // 일반 친구 목록 표시 (검색 중이 아니고 최근 검색 모드가 아닐 때)
                  if (!_isSearching && !_showRecentSearch)
                    Expanded(
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 친한 친구 섹션
                            if (_filteredBestFriends.isNotEmpty) ...[
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          const Text(
                                            '친한 친구',
                                            style: TextStyle(
                                              color: Color(0xFF202020),
                                              fontSize: 16,
                                              fontFamily: 'Pretendard-Bold',
                                              letterSpacing: -0.64,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            '${_filteredBestFriends.length}',
                                            style: const TextStyle(
                                              color: Color(
                                                0xFF146AFF,
                                              ), // 부모단 테마 색상
                                              fontSize: 16,
                                              fontFamily: 'Pretendard-Bold',
                                              letterSpacing: -0.64,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 8),

                              // 친한 친구 목록
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: Column(
                                  children: [
                                    ...List.generate(
                                      _filteredBestFriends.length,
                                      (index) => FriendItem(
                                        friend: _filteredBestFriends[index],
                                        onFriendUpdated: (result) {
                                          _fetchFriendList(refresh: true);
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 24),
                            ],

                            // 모든 친구 헤더
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                child: Row(
                                  children: [
                                    const Text(
                                      '모든 친구',
                                      style: TextStyle(
                                        color: Color(0xFF202020),
                                        fontSize: 16,
                                        fontFamily: 'Pretendard-Bold',
                                        letterSpacing: -0.64,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${_filteredNormalFriends.length}',
                                      style: const TextStyle(
                                        color: Color(0xFF146AFF), // 부모단 테마 색상
                                        fontSize: 16,
                                        fontFamily: 'Pretendard-Bold',
                                        letterSpacing: -0.64,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 8),

                            // 로딩 및 에러 상태 처리
                            if (_isLoading && _friendData.isEmpty)
                              const Center(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 100),
                                  child: CircularProgressIndicator(
                                    color: Color(0xFF146AFF), // 부모단 테마 색상
                                  ),
                                ),
                              )
                            else if (_hasError && _friendData.isEmpty)
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 100,
                                  ),
                                  child: Column(
                                    children: [
                                      const Icon(
                                        Icons.error_outline,
                                        color: Colors.red,
                                        size: 48,
                                      ),
                                      const SizedBox(height: 16),
                                      const Text(
                                        '친구 목록을 불러오는 중 오류가 발생했습니다',
                                        style: TextStyle(
                                          color: Color(0xFF666666),
                                          fontSize: 14,
                                          fontFamily: 'Pretendard-Regular',
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      ElevatedButton(
                                        onPressed:
                                            () =>
                                                _fetchFriendList(refresh: true),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(
                                            0xFF146AFF,
                                          ), // 부모단 테마 색상
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                        ),
                                        child: const Text('다시 시도'),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else if (_friendData.isEmpty)
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 100,
                                  ),
                                  child: Column(
                                    children: [
                                      const Icon(
                                        Icons.person_outline,
                                        color: Color(0xFFCCCCCC),
                                        size: 48,
                                      ),
                                      const SizedBox(height: 16),
                                      const Text(
                                        '아직 친구가 없습니다',
                                        style: TextStyle(
                                          color: Color(0xFF666666),
                                          fontSize: 14,
                                          fontFamily: 'Pretendard-Regular',
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      const Text(
                                        '우측 하단의 + 버튼을 눌러 친구를 추가해보세요',
                                        style: TextStyle(
                                          color: Color(0xFF999999),
                                          fontSize: 12,
                                          fontFamily: 'Pretendard-Light',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else
                              // 일반 친구 목록
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: Column(
                                  children: [
                                    ...List.generate(
                                      _filteredNormalFriends.length,
                                      (index) => FriendItem(
                                        friend: _filteredNormalFriends[index],
                                        onFriendUpdated: (result) {
                                          _fetchFriendList(refresh: true);
                                        },
                                      ),
                                    ),
                                    // 로딩 인디케이터
                                    if (_isLoading && _hasMoreData)
                                      const Padding(
                                        padding: EdgeInsets.all(8.0),
                                        child: Center(
                                          child: SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              color: Color(
                                                0xFF146AFF,
                                              ), // 부모단 테마 색상
                                              strokeWidth: 2,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),

                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),

                  // 검색 결과 표시
                  if (_isSearching)
                    Expanded(
                      child:
                          _filteredProfiles.isEmpty && _searchQuery.length >= 3
                              ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 193,
                                      height: 108,
                                      decoration: BoxDecoration(
                                        image: DecorationImage(
                                          image: AssetImage(
                                            "assets/icons/search_none.png",
                                          ),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                      ),
                                      child: Column(
                                        children: [
                                          Text(
                                            _searchQuery.isNotEmpty
                                                ? '\'$_searchQuery\'이라는 검색 결과가 없습니다!'
                                                : '검색 결과가 없습니다!',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: const Color(0xFF202020),
                                              fontSize: 18,
                                              fontFamily: 'Pretendard-Bold',
                                              height: 1.50,
                                              letterSpacing: -0.72,
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            '입력하신 단어의 철자가 맞는지 확인해 주세요',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: const Color(0xFF999999),
                                              fontSize: 14,
                                              fontFamily: 'Pretendard-Light',
                                              letterSpacing: -0.28,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              )
                              : SingleChildScrollView(
                                child: Column(
                                  children: [
                                    // 최근 검색어 표시
                                    if (_recentSearches.isNotEmpty &&
                                        !(_searchQuery.length >= 3 &&
                                            _isKoreanComplete(
                                              _searchQuery[2],
                                            ))) ...[
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                        color: Colors.white,
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
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
                                            TextButton(
                                              onPressed:
                                                  () => _clearAllSearches(),
                                              child: const Text(
                                                '전체 삭제',
                                                style: TextStyle(
                                                  color: Color(0xFF8490A3),
                                                  fontSize: 12,
                                                  fontFamily:
                                                      'Pretendard-Light',
                                                  fontWeight: FontWeight.w300,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        width: double.infinity,
                                        alignment: Alignment.centerLeft,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                        ),
                                        child: Wrap(
                                          alignment: WrapAlignment.start,
                                          crossAxisAlignment:
                                              WrapCrossAlignment.start,
                                          spacing: 4,
                                          runSpacing: 4,
                                          children:
                                              _recentSearches
                                                  .take(10)
                                                  .map(
                                                    (search) => SearchChip(
                                                      label: search,
                                                      onTap: () {
                                                        _searchController.text =
                                                            search;
                                                        _saveSearch(search);
                                                        _filterSearches(search);
                                                      },
                                                      onRemove:
                                                          () => _removeSearch(
                                                            search,
                                                          ),
                                                    ),
                                                  )
                                                  .toList(),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                    ],

                                    // 구분선
                                    Container(
                                      width: double.infinity,
                                      height: 6,
                                      decoration: ShapeDecoration(
                                        color: const Color(0xFFE7ECF6),
                                        shape: RoundedRectangleBorder(
                                          side: BorderSide(
                                            width: 0.10,
                                            color: const Color(0xFF8490A3),
                                          ),
                                        ),
                                      ),
                                    ),

                                    // 검색된 친구 목록
                                    if (_filteredProfiles.isNotEmpty) ...[
                                      Container(
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                        ),
                                        child: Column(
                                          children: [
                                            Container(
                                              width: double.infinity,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                    vertical: 12,
                                                  ),
                                              child: Row(
                                                children: [
                                                  Text(
                                                    '내 친구들',
                                                    style: TextStyle(
                                                      color: const Color(
                                                        0xFF202020,
                                                      ),
                                                      fontSize: 18,
                                                      fontFamily:
                                                          'Pretendard-Bold',
                                                      letterSpacing: -0.72,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    '${_filteredProfiles.length}',
                                                    style: TextStyle(
                                                      color: const Color(
                                                        0xFF146AFF,
                                                      ), // 부모단 테마 색상
                                                      fontSize: 18,
                                                      fontFamily:
                                                          'Pretendard-Bold',
                                                      letterSpacing: -0.72,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Container(
                                              width: double.infinity,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                    vertical: 12,
                                                  ),
                                              child: SingleChildScrollView(
                                                scrollDirection:
                                                    Axis.horizontal,
                                                child: Row(
                                                  children: [
                                                    ..._filteredProfiles
                                                        .take(5)
                                                        .map(
                                                          (profile) => Padding(
                                                            padding:
                                                                const EdgeInsets.only(
                                                                  right: 18,
                                                                ),
                                                            child: Column(
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .min,
                                                              children: [
                                                                Container(
                                                                  width: 40,
                                                                  height: 40,
                                                                  decoration: ShapeDecoration(
                                                                    image:
                                                                        profile['profileImageUrl'] !=
                                                                                    null &&
                                                                                profile['profileImageUrl'].toString().isNotEmpty
                                                                            ? DecorationImage(
                                                                              image: NetworkImage(
                                                                                profile['profileImageUrl'],
                                                                              ),
                                                                              fit:
                                                                                  BoxFit.cover,
                                                                            )
                                                                            : null,
                                                                    shape: OvalBorder(
                                                                      side: BorderSide(
                                                                        width:
                                                                            0.80,
                                                                        color: const Color(
                                                                          0xFF146AFF,
                                                                        ), // 부모단 테마 색상
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  child:
                                                                      profile['profileImageUrl'] ==
                                                                                  null ||
                                                                              profile['profileImageUrl'].toString().isEmpty
                                                                          ? Center(
                                                                            child: Text(
                                                                              profile['name'].toString().isNotEmpty
                                                                                  ? profile['name'].toString().substring(
                                                                                    0,
                                                                                    1,
                                                                                  )
                                                                                  : '?',
                                                                              style: const TextStyle(
                                                                                fontSize:
                                                                                    16,
                                                                              ),
                                                                            ),
                                                                          )
                                                                          : null,
                                                                ),
                                                                const SizedBox(
                                                                  height: 8,
                                                                ),
                                                                Text(
                                                                  profile['name'],
                                                                  style: TextStyle(
                                                                    color: const Color(
                                                                      0xFF353535,
                                                                    ),
                                                                    fontSize:
                                                                        11,
                                                                    fontFamily:
                                                                        'Pretendard-Light',
                                                                    letterSpacing:
                                                                        -0.22,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        )
                                                        .toList(),
                                                    if (_filteredProfiles
                                                            .length >
                                                        5)
                                                      Column(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          Container(
                                                            width: 40,
                                                            height: 40,
                                                            decoration: ShapeDecoration(
                                                              color:
                                                                  const Color(
                                                                    0xFFFFD27F,
                                                                  ),
                                                              shape:
                                                                  OvalBorder(),
                                                            ),
                                                            child: Center(
                                                              child: Text(
                                                                '+${_filteredProfiles.length - 5}',
                                                                style: TextStyle(
                                                                  color: const Color(
                                                                    0xFF001F55,
                                                                  ),
                                                                  fontSize: 12,
                                                                  fontFamily:
                                                                      'Pretendard-Medium',
                                                                  letterSpacing:
                                                                      -0.24,
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            height: 8,
                                                          ),
                                                          Text(
                                                            '전체보기',
                                                            style: TextStyle(
                                                              color:
                                                                  const Color(
                                                                    0xFF353535,
                                                                  ),
                                                              fontSize: 11,
                                                              fontFamily:
                                                                  'Pretendard-Light',
                                                              letterSpacing:
                                                                  -0.22,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                    ),
                ],
              ),

              // 초성 필터 (오른쪽 플로팅)
              if (!_isSearching && !_showRecentSearch)
                Positioned(
                  right: 16,
                  top: 160,
                  child: Container(
                    width: 16,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children:
                          _koreanInitials.map((initial) {
                            bool isSelected = _selectedInitial == initial;
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedInitial = isSelected ? '' : initial;
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: SizedBox(
                                  width: 16,
                                  height: 20,
                                  child: Center(
                                    child: Text(
                                      initial,
                                      style: TextStyle(
                                        color:
                                            isSelected
                                                ? const Color(0xFF001F55)
                                                : const Color(0xFF8490A3),
                                        fontSize: 14,
                                        fontFamily:
                                            isSelected
                                                ? 'Pretendard-Bold'
                                                : 'Pretendard-Light',
                                        letterSpacing: -0.28,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // 친구 추가 모달 표시
  void _showAddFriendModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return AddFriendModalContent(
          onFriendAdded: () {
            _fetchFriendList(refresh: true);
          },
        );
      },
    );
  }
}
