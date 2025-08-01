import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class GroupChatModal extends StatefulWidget {
  final List<Map<String, dynamic>> friendProfiles;
  final Function(List<int> selectedUserIds) onGroupCreated;

  const GroupChatModal({
    super.key,
    required this.friendProfiles,
    required this.onGroupCreated,
  });

  @override
  State<GroupChatModal> createState() => _GroupChatModalState();
}

class _GroupChatModalState extends State<GroupChatModal> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<int> _selectedUserIds = [];
  String _searchQuery = '';
  bool _isSearchFocused = false;

  List<Map<String, dynamic>> get _filteredFriends {
    if (_searchQuery.isEmpty) {
      return widget.friendProfiles;
    }
    return widget.friendProfiles.where((friend) {
      final name = friend['name']?.toString().toLowerCase() ?? '';
      return name.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  List<Map<String, dynamic>> get _selectedFriends {
    return widget.friendProfiles.where((friend) {
      return _selectedUserIds.contains(friend['userId']);
    }).toList();
  }

  // 전화번호 포맷팅 함수 (목업 데이터)
  String _formatPhoneNumber(String? phone) {
    if (phone == null || phone.isEmpty) {
      return '010-1234-5678'; // 목업 데이터
    }

    // 숫자만 추출
    String numbersOnly = phone.replaceAll(RegExp(r'[^0-9]'), '');

    // 11자리 한국 휴대폰 번호 포맷팅
    if (numbersOnly.length == 11) {
      return '${numbersOnly.substring(0, 3)}-${numbersOnly.substring(3, 7)}-${numbersOnly.substring(7, 11)}';
    }

    // 원본 반환 또는 목업 데이터
    return phone.isNotEmpty ? phone : '010-1234-5678';
  }

  void _toggleFriendSelection(int userId) {
    setState(() {
      if (_selectedUserIds.contains(userId)) {
        _selectedUserIds.remove(userId);
      } else {
        _selectedUserIds.add(userId);
      }
    });
  }

  void _removeSelectedFriend(int userId) {
    setState(() {
      _selectedUserIds.remove(userId);
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(() {
      setState(() {
        _isSearchFocused = _searchFocusNode.hasFocus;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;

    // 동적 높이 계산
    final double headerHeight = 80; // 헤더 + 부제목
    final double searchBarHeight = 60; // 검색바
    final double selectedFriendsHeight =
        _selectedFriends.isNotEmpty ? 70 : 0; // 선택된 친구들
    final double friendItemHeight = 54; // 각 친구 아이템 높이
    final double buttonHeight = 70; // 하단 버튼
    final double padding = 40; // 여백
    
    // 친구 목록 높이 계산
    double friendListHeight;
    if (_filteredFriends.isEmpty) {
      friendListHeight = 150; // 친구가 없을 때 최소 높이
    } else {
      // 친구 수에 맞는 높이 (최대 8명까지만 스크롤 없이 표시)
      final int maxVisibleFriends = 8;
      final int visibleFriends = _filteredFriends.length > maxVisibleFriends 
          ? maxVisibleFriends 
          : _filteredFriends.length;
      friendListHeight = visibleFriends * friendItemHeight;
    }

    // 모달의 전체 높이 계산
    final double calculatedHeight = headerHeight + 
        searchBarHeight + 
        selectedFriendsHeight + 
        friendListHeight + 
        buttonHeight + 
        padding;

    // 화면 높이의 90%를 넘지 않도록 제한
    final double maxHeight = screenHeight * 0.9;
    final double finalHeight = calculatedHeight > maxHeight ? maxHeight : calculatedHeight;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: EdgeInsets.only(bottom: keyboardHeight),
      child: Container(
        height: finalHeight,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
          ),
        ),
        child: Column(
          children: [
            // 헤더
            Container(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '누구에게 채팅을 보낼까요?',
                        style: TextStyle(
                          color: const Color(0xFF202020),
                          fontSize: 14,
                          fontFamily: 'Pretendard-Bold',
                          letterSpacing: -0.56,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Image.asset(
                          'assets/icons/Icon/chat/close.png',
                          width: 15,
                          height: 15,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '그룹 채팅방을 생성할 상대를 선택해주세요',
                    style: TextStyle(
                      color: const Color(0xFF999999),
                      fontSize: 11,
                      fontFamily: 'Pretendard-Light',
                      letterSpacing: -0.22,
                    ),
                  ),
                ],
              ),
            ),

            // 검색바
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFE7ECF6),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color:
                      _isSearchFocused || _searchQuery.isNotEmpty
                          ? const Color(0xFF146AFF)
                          : const Color(0xFF5D6A7F),
                  width: _isSearchFocused ? 1.2 : 0.6,
                ),
              ),
              child: Row(
                children: [
                  Image.asset(
                    'assets/icons/Icon/검색/Regular.png',
                    width: 18,
                    height: 18,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      style: const TextStyle(
                        fontSize: 9,
                        fontFamily: 'Pretendard-Regular',
                      ),
                      decoration: InputDecoration(
                        hintText: '찾고싶은 채팅 상대를 검색해 주세요',
                        hintStyle: TextStyle(
                          color: const Color(0xFF999999),
                          fontSize: 9,
                          fontFamily: 'Pretendard-Light',
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        filled: true,
                        fillColor: const Color(0xFFE7ECF6),
                      ),
                      onChanged: _onSearchChanged,
                    ),
                  ),
                  if (_searchQuery.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _searchController.clear();
                        _onSearchChanged('');
                      },
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFFC3C3C3),
                        ),
                        child: Icon(Icons.close, size: 10, color: Colors.white),
                      ),
                    ),
                ],
              ),
            ),

            // 선택된 친구들 표시
            if (_selectedFriends.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '선택된 친구들 (${_selectedFriends.length}명)',
                      style: TextStyle(
                        color: const Color(0xFF202020),
                        fontSize: 12,
                        fontFamily: 'Pretendard-Medium',
                      ),
                    ),
                    const SizedBox(height: 9),
                    Container(
                      height: 30,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _selectedFriends.length,
                        itemBuilder: (context, index) {
                          final friend = _selectedFriends[index];
                          return Container(
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF11CB86),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  friend['name'] ?? '',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontFamily: 'Pretendard-Medium',
                                  ),
                                ),
                                const SizedBox(width: 6),
                                GestureDetector(
                                  onTap:
                                      () => _removeSelectedFriend(
                                        friend['userId'],
                                      ),
                                  child: Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 12,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),

            // 친구 목록 (친구 수에 맞는 동적 높이)
            Expanded(
              child: _filteredFriends.isEmpty
                  ? Container(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 40,
                            color: Color(0xFFCCCCCC),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _searchQuery.isNotEmpty
                                ? '\'$_searchQuery\'에 대한 검색 결과가 없습니다'
                                : '친구가 없습니다',
                            style: TextStyle(
                              color: const Color(0xFF666666),
                              fontSize: 11,
                              fontFamily: 'Pretendard-Regular',
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: _filteredFriends.length,
                      itemBuilder: (context, index) {
                        final friend = _filteredFriends[index];
                        final isSelected = _selectedUserIds.contains(
                          friend['userId'],
                        );

                        return Container(
                          margin: const EdgeInsets.only(bottom: 9),
                          child: GestureDetector(
                            onTap: () => _toggleFriendSelection(friend['userId']),
                            child: Container(
                              padding: const EdgeInsets.all(9),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: Row(
                                children: [
                                  // 프로필 이미지
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: ShapeDecoration(
                                      image: friend['profileImageUrl'] != null &&
                                              friend['profileImageUrl']
                                                  .toString()
                                                  .isNotEmpty
                                          ? DecorationImage(
                                              image: CachedNetworkImageProvider(
                                                friend['profileImageUrl']
                                                        .toString()
                                                        .startsWith('http')
                                                    ? friend['profileImageUrl']
                                                    : 'https://littlebank-dev.s3.ap-northeast-2.amazonaws.com/${friend['profileImageUrl']}',
                                              ),
                                              fit: BoxFit.cover,
                                            )
                                          : null,
                                      shape: OvalBorder(),
                                    ),
                                    child: friend['profileImageUrl'] == null ||
                                            friend['profileImageUrl']
                                                .toString()
                                                .isEmpty
                                        ? Center(
                                            child: Text(
                                              friend['name']
                                                          ?.toString()
                                                          .isNotEmpty ==
                                                      true
                                                  ? friend['name']
                                                      .toString()[0]
                                                  : '?',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontFamily: 'Pretendard-Medium',
                                              ),
                                            ),
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 9),

                                  // 이름과 전화번호
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          friend['name'] ?? '',
                                          style: TextStyle(
                                            color: const Color(0xFF202020),
                                            fontSize: 12,
                                            fontFamily: 'Pretendard-Bold',
                                          ),
                                        ),
                                        Text(
                                          _formatPhoneNumber(
                                            friend['phone']?.toString(),
                                          ),
                                          style: TextStyle(
                                            color: const Color(0xFF666666),
                                            fontSize: 9,
                                            fontFamily: 'Pretendard-Light',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // 체크박스
                                  Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isSelected
                                          ? const Color(0xFF11CB86)
                                          : Colors.transparent,
                                      border: Border.all(
                                        color: isSelected
                                            ? const Color(0xFF11CB86)
                                            : const Color(0xFFCCCCCC),
                                        width: 2,
                                      ),
                                    ),
                                    child: isSelected
                                        ? Icon(
                                            Icons.check,
                                            color: Colors.white,
                                            size: 12,
                                          )
                                        : null,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),

            // 하단 버튼
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              child: SafeArea(
                child: ElevatedButton(
                  onPressed:
                      _selectedUserIds.length >= 1
                          ? () {
                            Navigator.pop(context);
                            widget.onGroupCreated(_selectedUserIds);
                          }
                          : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF146AFF),
                    disabledBackgroundColor: const Color(0xFFCCCCCC),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9),
                    ),
                  ),
                  child: Text(
                    _selectedUserIds.isEmpty
                        ? '선택 완료'
                        : '선택 완료 (${_selectedUserIds.length}명)',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontFamily: 'Pretendard-Medium',
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }
}
