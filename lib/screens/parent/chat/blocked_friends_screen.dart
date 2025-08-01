import 'package:flutter/material.dart';
import '../../../services/relationship_service.dart';

class BlockedFriendsScreen extends StatefulWidget {
  const BlockedFriendsScreen({super.key});

  @override
  State<BlockedFriendsScreen> createState() => _BlockedFriendsScreenState();
}

class _BlockedFriendsScreenState extends State<BlockedFriendsScreen> {
  final TextEditingController _searchController = TextEditingController();
  
  // 차단한 친구 목록 (동적 데이터)
  List<Map<String, dynamic>> _blockedFriends = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadBlockedFriends();
  }

  // 차단한 친구 목록 로드
  Future<void> _loadBlockedFriends() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final friends = await RelationshipService.getFriendList();
      
      if (friends != null) {
        // 차단된 친구들만 필터링
        final blockedFriends = friends.where((friend) {
          final isBlocked = friend['isBlocked'] ?? false;
          return isBlocked == true;
        }).toList();

        // 데이터 변환
        final transformedFriends = blockedFriends.map((friend) {
          final userInfo = friend['userInfo'] ?? {};
          return {
            'name': userInfo['realName'] ?? '알 수 없음',
            'profileImage': userInfo['profileImagePath'] ?? 'https://placehold.co/48x48',
            'isLittleBank': userInfo['role'] == 'CHILD', // 역할이 CHILD인 경우 리틀뱅크 사용자
            'friendId': friend['friendId'],
            'userId': userInfo['userId'],
          };
        }).toList();

        setState(() {
          _blockedFriends = transformedFriends;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = '차단한 친구 목록을 불러오는데 실패했습니다';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '차단한 친구 목록을 불러오는데 실패했습니다';
        _isLoading = false;
      });
      print('차단한 친구 목록 로딩 오류: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          '차단한 친구 관리',
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontFamily: 'Pretendard-Bold',
            letterSpacing: -0.32,
          ),
        ),
        leading: IconButton(
          icon: Image.asset(
            'assets/images/뒤로가기.png',
            width: 24,
            height: 24,
            errorBuilder: (context, error, stackTrace) {
              return Icon(
                Icons.arrow_back,
                size: 24,
                color: Colors.black,
              );
            },
          ),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          SizedBox(height: 12),
          // 검색 영역
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: ShapeDecoration(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  side: BorderSide(
                    width: 0.80,
                    color: const Color(0xFFDADADA),
                  ),
                  borderRadius: BorderRadius.circular(32),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    child: Image.asset(
                      'assets/images/search.png',
                      width: 20,
                      height: 20,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.search,
                          size: 20,
                          color: Color(0xFF999999),
                        );
                      },
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: '찾고싶은 채팅 상대를 검색해 주세요',
                        hintStyle: TextStyle(
                          color: const Color(0xFF999999),
                          fontSize: 12,
                          fontFamily: 'Pretendard-Light',
                          letterSpacing: -0.24,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                      ),
                      style: TextStyle(
                        color: const Color(0xFF202020),
                        fontSize: 12,
                        fontFamily: 'Pretendard-Regular',
                        letterSpacing: -0.24,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // 차단한 친구 목록
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF3A88F4),
                    ),
                  )
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _errorMessage!,
                              style: TextStyle(
                                color: Color(0xFF666666),
                                fontSize: 16,
                                fontFamily: 'Pretendard-Regular',
                              ),
                            ),
                            SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadBlockedFriends,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF3A88F4),
                              ),
                              child: Text(
                                '다시 시도',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'Pretendard-Regular',
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : Container(
                        decoration: BoxDecoration(color: Colors.white),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 타이틀 영역
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Row(
                                children: [
                                  Text(
                                    '차단한 친구',
                                    style: TextStyle(
                                      color: const Color(0xFF202020),
                                      fontSize: 18,
                                      fontFamily: 'Pretendard-Bold',
                                      letterSpacing: -0.72,
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    '${_blockedFriends.length}',
                                    style: TextStyle(
                                      color: const Color(0xFF3A88F4),
                                      fontSize: 18,
                                      fontFamily: 'Pretendard-Bold',
                                      letterSpacing: -0.72,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            // 친구 목록
                            Expanded(
                              child: _blockedFriends.isEmpty
                                  ? Center(
                                      child: Text(
                                        '차단한 친구가 없습니다.',
                                        style: TextStyle(
                                          color: Color(0xFF666666),
                                          fontSize: 16,
                                          fontFamily: 'Pretendard-Regular',
                                        ),
                                      ),
                                    )
                                  : ListView.builder(
                                      itemCount: _blockedFriends.length,
                                      itemBuilder: (context, index) {
                                        final friend = _blockedFriends[index];
                                        return _buildFriendItem(friend, index);
                                      },
                                    ),
                            ),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendItem(Map<String, dynamic> friend, int index) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // 프로필 이미지
          Container(
            width: 48,
            height: 48,
            decoration: ShapeDecoration(
              image: DecorationImage(
                image: friend['profileImage'] != null && friend['profileImage'] != 'https://placehold.co/48x48'
                    ? NetworkImage(friend['profileImage'])
                    : AssetImage('assets/images/default_profile.png') as ImageProvider,
                fit: BoxFit.cover,
              ),
              shape: OvalBorder(
                side: friend['isLittleBank'] == true
                    ? BorderSide(
                        width: 0.80,
                        color: const Color(0xFF146AFF),
                      )
                    : BorderSide.none,
              ),
            ),
          ),
          
          SizedBox(width: 24),
          
          // 친구 이름
          Expanded(
            child: Text(
              friend['name'] ?? '알 수 없음',
              style: TextStyle(
                color: const Color(0xFF202020),
                fontSize: 16,
                fontFamily: 'Pretendard-Bold',
                letterSpacing: -0.32,
              ),
            ),
          ),
          
          // 해제 버튼
          GestureDetector(
            onTap: () => _unblockFriend(index),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: ShapeDecoration(
                color: const Color(0xFFE7ECF6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(
                '해제',
                style: TextStyle(
                  color: const Color(0xFF8490A3),
                  fontSize: 11,
                  fontFamily: 'Pretendard-Light',
                  letterSpacing: -0.22,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _unblockFriend(int index) {
    final friend = _blockedFriends[index];
    final friendId = friend['friendId'];
    
    if (friendId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '친구 정보를 찾을 수 없습니다.',
            style: TextStyle(
              fontFamily: 'Pretendard-Regular',
              color: Colors.white,
            ),
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            '차단 해제',
            style: TextStyle(
              fontFamily: 'Pretendard-Bold',
              fontSize: 16,
            ),
          ),
          content: Text(
            '${friend['name']}님의 차단을 해제하시겠습니까?',
            style: TextStyle(
              fontFamily: 'Pretendard-Regular',
              fontSize: 14,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                '취소',
                style: TextStyle(
                  color: Color(0xFF8490A3),
                  fontFamily: 'Pretendard-Regular',
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                
                // 로딩 표시
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF3A88F4),
                    ),
                  ),
                );

                try {
                  final result = await RelationshipService.unblockFriend(friendId);
                  Navigator.pop(context); // 로딩 다이얼로그 닫기
                  
                  if (result != null) {
                    // 성공 시 목록에서 제거
                    setState(() {
                      _blockedFriends.removeAt(index);
                    });
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '차단이 해제되었습니다.',
                          style: TextStyle(
                            fontFamily: 'Pretendard-Regular',
                            color: Colors.white,
                          ),
                        ),
                        backgroundColor: Color(0xFF146AFF),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '차단 해제에 실패했습니다.',
                          style: TextStyle(
                            fontFamily: 'Pretendard-Regular',
                            color: Colors.white,
                          ),
                        ),
                        backgroundColor: Colors.red,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                } catch (e) {
                  Navigator.pop(context); // 로딩 다이얼로그 닫기
                  print('차단 해제 중 오류: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '차단 해제 중 오류가 발생했습니다.',
                        style: TextStyle(
                          fontFamily: 'Pretendard-Regular',
                          color: Colors.white,
                        ),
                      ),
                      backgroundColor: Colors.red,
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
              child: Text(
                '해제',
                style: TextStyle(
                  color: Color(0xFF3A88F4),
                  fontFamily: 'Pretendard-Bold',
                ),
              ),
            ),
          ],
        );
      },
    );
  }
} 