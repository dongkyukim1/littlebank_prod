import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class FriendSelectionModal extends StatefulWidget {
  final List<Map<String, dynamic>> friendProfiles;
  final Function(int userId) onFriendSelected;

  const FriendSelectionModal({
    super.key,
    required this.friendProfiles,
    required this.onFriendSelected,
  });

  @override
  State<FriendSelectionModal> createState() => _FriendSelectionModalState();
}

class _FriendSelectionModalState extends State<FriendSelectionModal> {
  String searchText = '';

  List<Map<String, dynamic>> get filteredFriends {
    if (searchText.isEmpty) {
      return widget.friendProfiles.take(5).toList();
    }
    return widget.friendProfiles
        .where((friend) {
          final name = friend['name']?.toString().toLowerCase() ?? '';
          return name.contains(searchText.toLowerCase());
        })
        .take(5)
        .toList();
  }

  // 전화번호 포맷팅 함수 추가
  String _formatPhoneNumber(String? phone) {
    if (phone == null || phone.isEmpty) {
      return '전화번호 없음';
    }

    // 숫자만 추출
    String numbersOnly = phone.replaceAll(RegExp(r'[^0-9]'), '');

    // 11자리 한국 휴대폰 번호 포맷팅
    if (numbersOnly.length == 11) {
      return '${numbersOnly.substring(0, 3)}-${numbersOnly.substring(3, 7)}-${numbersOnly.substring(7, 11)}';
    }

    // 원본 반환
    return phone;
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: EdgeInsets.only(bottom: keyboardHeight),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
                    '채팅을 보내고싶은 상대를 선택해 주세요',
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
                      searchText.isNotEmpty
                          ? const Color(0xFF146AFF)
                          : const Color(0xFF5D6A7F),
                  width: 0.6,
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
                      style: const TextStyle(
                        fontSize: 9,
                        fontFamily: 'Pretendard-Regular',
                      ),
                      onChanged: (value) {
                        setState(() {
                          searchText = value;
                        });
                      },
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
                    ),
                  ),
                  if (searchText.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          searchText = '';
                        });
                      },
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFFCCCCCC),
                        ),
                        child: Icon(Icons.close, size: 10, color: Colors.white),
                      ),
                    ),
                ],
              ),
            ),

            // 친구 목록
            Flexible(
              child:
                  filteredFriends.isEmpty
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
                              searchText.isNotEmpty
                                  ? '\'$searchText\'에 대한 검색 결과가 없습니다'
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
                        shrinkWrap: true,
                        itemCount: filteredFriends.length,
                        itemBuilder: (context, index) {
                          final friend = filteredFriends[index];
                          final friendName =
                              friend['name']?.toString() ?? '이름 없음';

                          print('친구 표시: $friendName'); // 디버그용

                          return ListTile(
                            onTap: () {
                              print(
                                '친구 선택: $friendName, userId: ${friend['userId']}',
                              );
                              Navigator.pop(context);
                              widget.onFriendSelected(friend['userId']);
                            },
                            leading: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                image:
                                    friend['profileImageUrl'] != null &&
                                            friend['profileImageUrl']
                                                .toString()
                                                .isNotEmpty
                                        ? DecorationImage(
                                          image: CachedNetworkImageProvider(
                                            friend['profileImageUrl']
                                                .toString(),
                                          ),
                                          fit: BoxFit.cover,
                                        )
                                        : null,
                              ),
                              child:
                                  friend['profileImageUrl'] == null ||
                                          friend['profileImageUrl']
                                              .toString()
                                              .isEmpty
                                      ? Center(
                                        child: Text(
                                          friendName.isNotEmpty
                                              ? friendName[0]
                                              : '?',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontFamily: 'Pretendard-Medium',
                                          ),
                                        ),
                                      )
                                      : null,
                            ),
                            title: Text(
                              friendName,
                              style: TextStyle(
                                color: const Color(0xFF202020),
                                fontSize: 12,
                                fontFamily: 'Pretendard-Bold',
                              ),
                            ),
                            subtitle: Text(
                              _formatPhoneNumber(
                                friend['phone']?.toString(),
                              ), // 포맷팅된 전화번호
                              style: TextStyle(
                                color: const Color(0xFF666666),
                                fontSize: 9,
                                fontFamily: 'Pretendard-Light',
                              ),
                            ),
                          );
                        },
                      ),
            ),

            // 하단 여백
            SizedBox(height: bottomPadding > 0 ? bottomPadding + 12 : 24),
          ],
        ),
      ),
    );
  }
}
