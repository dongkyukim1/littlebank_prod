import 'package:flutter/material.dart';
import 'dart:async';
import '../../../services/friend_search_service.dart';
import '../../../services/relationship_service.dart';
import 'chat_start_screen.dart';

class SearchHistoryScreen extends StatefulWidget {
  const SearchHistoryScreen({super.key});

  @override
  State<SearchHistoryScreen> createState() => _SearchHistoryScreenState();
}

class _SearchHistoryScreenState extends State<SearchHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<Map<String, dynamic>> _recentSearches = []; // 서버에서 가져온 검색 기록
  List<Map<String, dynamic>> _filteredSearches = [];
  List<Map<String, dynamic>> _filteredProfiles = []; // 서버에서 검색된 친구 목록
  List<Map<String, dynamic>> _friendList = []; // 내 친구 목록
  bool _isSearching = false;
  bool _isLoading = false;
  bool _isSearchFocused = false;
  Timer? _debounceTimer; // 디바운싱을 위한 타이머

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(() {
      setState(() {
        _isSearchFocused = _searchFocusNode.hasFocus;
      });
    });
    _loadRecentSearches();
    _loadFriendList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  // 서버에서 최근 검색어 불러오기
  Future<void> _loadRecentSearches() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final searchHistory = await FriendSearchService.getSearchHistory();
      
      if (mounted) {
        setState(() {
          _recentSearches = searchHistory;
          _isLoading = false;
        });
        print('서버에서 최근 검색어 불러옴: ${_recentSearches.length}개');
      }
    } catch (e) {
      print('최근 검색어 로드 실패: $e');
      if (mounted) {
        setState(() {
          _recentSearches = [];
          _isLoading = false;
        });
      }
    }
  }

  // 검색어 기록 삭제 (서버)
  Future<void> _removeSearch(int searchHistoryId) async {
    try {
      final success = await FriendSearchService.deleteSearchHistory([searchHistoryId]);
      
      if (success && mounted) {
        setState(() {
          _recentSearches.removeWhere((item) => item['searchHistoryId'] == searchHistoryId);
        });
        print('검색 기록 삭제 성공: $searchHistoryId');
      }
    } catch (e) {
      print('검색 기록 삭제 실패: $e');
    }
  }

  // 모든 검색어 삭제 (서버)
  Future<void> _clearAllSearches() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final success = await FriendSearchService.clearAllSearchHistory();
      
      if (success && mounted) {
        setState(() {
          _recentSearches.clear();
        });
        print('모든 검색 기록 삭제 성공');
      }
    } catch (e) {
      print('전체 검색 기록 삭제 실패: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // 친구 검색 (디바운싱 적용)
  void _searchFriends(String query) {
    print('검색어 입력: $query');

    // 이전 타이머 취소
    _debounceTimer?.cancel();

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
      _isLoading = true;
    });

    // 최근 검색어에서 키워드 필터링 (로컬)
    _filteredSearches = _recentSearches
        .where((item) => item['keyword'].toString().toLowerCase().contains(query.toLowerCase()))
        .toList();

    // 디바운싱: 500ms 후에 서버 API 호출
    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      try {
        final searchResults = await FriendSearchService.searchFriends(query);
        
        if (mounted) {
          setState(() {
            _filteredProfiles = searchResults;
            _isLoading = false;
          });
          print('친구 검색 결과: ${_filteredProfiles.length}개');
        }
      } catch (e) {
        print('친구 검색 실패: $e');
        if (mounted) {
          setState(() {
            _filteredProfiles = [];
            _isLoading = false;
          });
        }
      }
    });
  }

  // 검색 기록 저장 (서버) - 친구 프로필 선택 시
  Future<void> _saveSearchHistory(int friendId) async {
    try {
      final result = await FriendSearchService.saveSearchHistory(friendId);
      
      if (result != null) {
        print('검색 기록 저장 성공: ${result['friendSearchHistoryId']}');
        // 검색 기록 다시 로드
        _loadRecentSearches();
      }
    } catch (e) {
      print('검색 기록 저장 실패: $e');
    }
  }

  // 친구 목록 로드
  Future<void> _loadFriendList() async {
    try {
      print('===== 친구 목록 조회 시작 =====');
      
      final friendList = await RelationshipService.getFriendList();
      
      if (mounted && friendList != null) {
        setState(() {
          _friendList = friendList.cast<Map<String, dynamic>>();
        });
        print('친구 목록 불러옴: ${_friendList.length}개');
      }
    } catch (e) {
      print('친구 목록 로드 실패: $e');
      if (mounted) {
        setState(() {
          _friendList = [];
        });
      }
    }
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
                      height: 44,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 0,
                      ),
                      decoration: ShapeDecoration(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          side: BorderSide(
                            width: _isSearchFocused ? 1.2 : 0.60,
                            color: _isSearchFocused 
                                ? const Color(0xFF146AFF)
                                : const Color(0xFF8490A3),
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
                                onChanged: _searchFriends,
                                textAlign: TextAlign.left,
                                textAlignVertical: TextAlignVertical.center,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontFamily: 'Pretendard-Regular',
                                ),
                                decoration: const InputDecoration(
                                  hintText: '친구 이름을 검색해 주세요',
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
                                  _filteredProfiles = [];
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

            // 로딩 상태
            if (_isLoading)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF3A88F4),
                  ),
                ),
              ),

            // 검색 결과가 없을 때 최근 검색어 표시
            if (!_isSearching && !_isLoading)
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
                            children: _recentSearches
                                .map((search) => _buildSearchChip(search))
                                .toList(),
                          ),
                        ),

                      const SizedBox(height: 32),

                      // 내 친구 섹션
                      if (_friendList.isNotEmpty) ...[
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
                                      '내 친구',
                                      style: TextStyle(
                                        color: Color(0xFF202020),
                                        fontSize: 18,
                                        fontFamily: 'Pretendard-Bold',
                                        letterSpacing: -0.72,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${_friendList.length}',
                                      style: const TextStyle(
                                        color: Color(0xFF3A88F4),
                                        fontSize: 18,
                                        fontFamily: 'Pretendard-Bold',
                                        letterSpacing: -0.72,
                                      ),
                                    ),
                                  ],
                                ),
                                GestureDetector(
                                  onTap: () {
                                    // 전체 친구 목록 화면으로 이동하는 기능 추가 가능
                                    print('전체 친구 목록 보기 클릭');
                                  },
                                  child: const Text(
                                    '전체 보기',
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
                        ),

                        const SizedBox(height: 8),

                        // 친구 목록 (처음 3명만 표시)
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
                              children: _friendList
                                  .take(3)
                                  .map((friend) => _buildMyFriendItem(friend))
                                  .toList(),
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),
                      ],

                      // 검색어가 없을 때 안내 메시지
                      if (_recentSearches.isEmpty && _friendList.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.search,
                                  size: 48,
                                  color: Color(0xFFCCCCCC),
                                ),
                                SizedBox(height: 16),
                                Text(
                                  '친구 이름으로 검색해보세요',
                                  style: TextStyle(
                                    color: Color(0xFF999999),
                                    fontSize: 16,
                                    fontFamily: 'Pretendard-Regular',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

            // 검색 중일 때 필터링된 결과 표시
            if (_isSearching && !_isLoading)
              Expanded(
                child: _filteredSearches.isEmpty && _filteredProfiles.isEmpty
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
                              ...List.generate(_filteredSearches.length, (index) {
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
                                      search['keyword'],
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontFamily: 'Pretendard-Regular',
                                      ),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(vertical: 4),
                                    dense: true,
                                    onTap: () {
                                      _searchController.text = search['keyword'];
                                      _searchFriends(search['keyword']);
                                      FocusScope.of(context).unfocus();
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
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: ShapeDecoration(
                                  color: const Color(0xFFEFF2F6),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: Column(
                                  children: _filteredProfiles
                                      .map((profile) => _buildFriendItem(profile))
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
  Widget _buildSearchChip(Map<String, dynamic> searchData) {
    final keyword = searchData['keyword'] ?? '';
    final searchHistoryId = searchData['searchHistoryId'];

    return Container(
      height: 44,
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          _searchController.text = keyword;
          _searchFriends(keyword);
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
                keyword,
                style: const TextStyle(
                  color: Color(0xFF202020),
                  fontSize: 14,
                  fontFamily: 'Pretendard-Regular',
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _removeSearch(searchHistoryId),
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
  Widget _buildFriendItem(Map<String, dynamic> friendData) {
    final userInfo = friendData['userInfo'] ?? {};
    final friendInfo = friendData['friendInfo'] ?? {};
    
    final userId = userInfo['userId'] ?? 0;
    final realName = userInfo['realName'] ?? '알 수 없음';
    final statusMessage = userInfo['statusMessage'] ?? '';
    final profileImagePath = userInfo['profileImagePath'];
    final friendId = friendInfo['friendId'];

    return GestureDetector(
      onTap: () {
        // 검색 기록 저장 (friendId가 있는 경우)
        if (friendId != null) {
          _saveSearchHistory(friendId);
        }

        // 프로필 화면으로 이동
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatStartScreen(
              userId: userId,
              userName: realName,
              userDescription: statusMessage.isNotEmpty ? statusMessage : '',
              friendId: friendId,
              isBlocked: friendInfo['isBlocked'] ?? false,
              isBestFriend: friendInfo['isBestFriend'] ?? false,
              initialProfileImageUrl: profileImagePath,
            ),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        height: 78,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: ShapeDecoration(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 프로필 이미지
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: const Color(0xFFEFF2F6),
              ),
              child: profileImagePath != null && profileImagePath.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        profileImagePath.startsWith('http')
                            ? profileImagePath
                            : 'https://littlebank-dev.s3.ap-northeast-2.amazonaws.com/$profileImagePath',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => _buildDefaultProfileImage(realName),
                      ),
                    )
                  : _buildDefaultProfileImage(realName),
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
                    realName,
                    style: const TextStyle(
                      color: Color(0xFF202020),
                      fontSize: 15,
                      fontFamily: 'Pretendard-Bold',
                      letterSpacing: -0.32,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  if (statusMessage.isNotEmpty) const SizedBox(height: 2),
                  if (statusMessage.isNotEmpty)
                    Text(
                      statusMessage,
                      style: const TextStyle(
                        color: Color(0xFF999999),
                        fontSize: 13,
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

  // 내 친구 아이템 위젯
  Widget _buildMyFriendItem(Map<String, dynamic> friendData) {
    // 친구 데이터 파싱
    final userInfo = friendData['userInfo'] ?? {};
    final relationshipInfo = friendData['relationshipInfo'] ?? {};
    
    final userId = userInfo['userId'] ?? 0;
    final realName = userInfo['realName'] ?? '알 수 없음';
    final statusMessage = userInfo['statusMessage'] ?? '';
    final profileImagePath = userInfo['profileImagePath'];
    final friendId = relationshipInfo['relationshipId'];
    final isBlocked = relationshipInfo['isBlocked'] ?? false;
    final isBestFriend = relationshipInfo['isBestFriend'] ?? false;

    // 커스텀 이름이 있으면 사용, 없으면 실제 이름 사용
    final customName = relationshipInfo['customName'];
    final displayName = (customName != null && customName.isNotEmpty) ? customName : realName;

    return GestureDetector(
      onTap: () {
        // 검색 기록 저장 (friendId가 있는 경우)
        if (friendId != null) {
          _saveSearchHistory(friendId);
        }

        // 프로필 화면으로 이동
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatStartScreen(
              userId: userId,
              userName: displayName,
              userDescription: statusMessage.isNotEmpty ? statusMessage : '',
              friendId: friendId,
              isBlocked: isBlocked,
              isBestFriend: isBestFriend,
              initialProfileImageUrl: profileImagePath,
            ),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        height: 78,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: ShapeDecoration(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 프로필 이미지
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: const Color(0xFFEFF2F6),
              ),
              child: profileImagePath != null && profileImagePath.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        profileImagePath.startsWith('http')
                            ? profileImagePath
                            : 'https://littlebank-dev.s3.ap-northeast-2.amazonaws.com/$profileImagePath',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => _buildDefaultProfileImage(displayName),
                      ),
                    )
                  : _buildDefaultProfileImage(displayName),
            ),
            const SizedBox(width: 20),

            // 이름 및 상태 메시지
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          displayName,
                          style: const TextStyle(
                            color: Color(0xFF202020),
                            fontSize: 15,
                            fontFamily: 'Pretendard-Bold',
                            letterSpacing: -0.32,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      // 친한 친구 아이콘
                      if (isBestFriend)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          child: const Icon(
                            Icons.favorite,
                            size: 16,
                            color: Color(0xFFFF6B9D),
                          ),
                        ),
                      // 차단 상태 아이콘
                      if (isBlocked)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          child: const Icon(
                            Icons.block,
                            size: 16,
                            color: Color(0xFF999999),
                          ),
                        ),
                    ],
                  ),
                  if (statusMessage.isNotEmpty) const SizedBox(height: 2),
                  if (statusMessage.isNotEmpty)
                    Text(
                      statusMessage,
                      style: const TextStyle(
                        color: Color(0xFF999999),
                        fontSize: 13,
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

  // 기본 프로필 이미지
  Widget _buildDefaultProfileImage(String name) {
    return Center(
      child: Text(
        name.isNotEmpty ? name[0] : '?',
        style: const TextStyle(
          fontSize: 24,
          fontFamily: 'Pretendard-Bold',
          color: Color(0xFF3A88F4),
        ),
      ),
    );
  }
}
