import 'package:flutter/material.dart';
import '../chat_detail_screen.dart';
import '../../../services/relationship_service.dart';
import '../../../services/feed_service.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ParentChatStartScreen extends StatefulWidget {
  final String userName;
  final String userDescription;
  final int userId; // 사용자 ID 추가
  final int postsCount;
  final int missionsCount;
  final int friendsCount;
  final String? initialProfileImageUrl; // 초기 프로필 이미지 URL
  final int? friendId; // 친구 관계 ID 추가
  final bool isBlocked; // 차단 상태 추가
  final bool isBestFriend; // 친한 친구 상태 추가

  const ParentChatStartScreen({
    super.key,
    required this.userName,
    this.userDescription = '',
    required this.userId, // 필수 파라미터로 변경
    this.postsCount = 0,
    this.missionsCount = 0,
    this.friendsCount = 0,
    this.initialProfileImageUrl,
    this.friendId, // 친구 관계 ID 옵션 추가
    this.isBlocked = false, // 차단 상태 기본값 추가
    this.isBestFriend = false, // 친한 친구 상태 기본값 추가
  });

  @override
  State<ParentChatStartScreen> createState() => _ParentChatStartScreenState();
}

// 프로필 카드의 그라데이션을 변수로 추출
const LinearGradient profileCardGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  stops: [
    0.0, // 시작
    0.06, // 첫 번째 전환
    0.17, // 두 번째 전환
    0.42, // 중간
    0.81, // 네 번째 전환
    1.0, // 끝
  ],
  colors: [
    Color(0xB3FFFFFF), // 시작: 흰색 (70% 불투명)
    Color(0x66FFFFFF), // 흰색 (40% 불투명)
    Color(0x995D9EFF), // 파란색 (60% 불투명)
    Color(0xCC5D9EFF), // 진한 파란색 (80% 불투명)
    Color(0x669747FF), // 보라색 (40% 불투명)
    Color(0xCCBAD5FF), // 연한 파란색 (80% 불투명)
  ],
);

class _ParentChatStartScreenState extends State<ParentChatStartScreen> {
  bool _isLoading = true;
  bool _hasError = false;
  Map<String, dynamic>? _userInfo;
  int? _directFriendId; // 직접 사용할 friendId
  bool _isBestFriend = false; // 친한 친구 여부 상태 추가

  // 사용자 정보 상태
  String _displayName = '';
  String _email = '';
  String _statusMessage = ''; // 상태메시지 상태 변수 추가
  String? _profileImageUrl;
  bool _isBlocked = false; // 차단 여부 상태 추가

  // 임시 친구 ID 변수 추가
  int? _tempFriendId;
  
  // 실제 피드 개수 상태 변수
  int _actualPostsCount = 0;

  @override
  void initState() {
    super.initState();
    _displayName = widget.userName;
    _statusMessage = widget.userDescription; // 기본 상태메시지 설정
    _profileImageUrl = widget.initialProfileImageUrl;

    // 위젯에서 전달된 친구 ID는 일단 임시 저장만 하고, 실제 서버 응답 확인 후 결정
    _tempFriendId = widget.friendId;
    _isBlocked = widget.isBlocked;
    _isBestFriend = widget.isBestFriend;

    print(
      '초기화 - 사용자 ID: ${widget.userId}, 임시 친구 ID: $_tempFriendId, 차단 상태: $_isBlocked, 친한 친구 상태: $_isBestFriend',
    );

    // 사용자 상세 정보 조회
    _fetchUserInfo();
  }

  // 사용자 상세 정보 조회
  Future<void> _fetchUserInfo() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      print('===== 사용자 상세 정보 조회 시작 =====');
      print('조회할 사용자 ID: ${widget.userId}');
      print('전달받은 임시 친구 ID: $_tempFriendId');
      print('전달받은 차단 상태: $_isBlocked');
      print('전달받은 친한 친구 상태: $_isBestFriend');
      print('전달받은 이름: ${widget.userName}');

      // 첫 화면 로딩 시 위젯에서 전달받은 이름과 기본 상태메시지를 바로 표시
      setState(() {
        _displayName = widget.userName;
        _statusMessage = widget.userDescription; // 기본 상태메시지 설정
      });

      final result = await RelationshipService.getUserInfo(widget.userId);

      if (result != null) {
        setState(() {
          _userInfo = result;
          _isLoading = false;
          _actualPostsCount = widget.postsCount; // 우선 기본값 사용

          // 사용자를 찾지 못한 경우 처리
          if (result['notFound'] == true) {
            _displayName = widget.userName;
            _email = '';
            _statusMessage = widget.userDescription; // 기본 상태메시지 유지
            _profileImageUrl = widget.initialProfileImageUrl;
            print('사용자를 찾을 수 없어 기본 정보를 사용합니다. ID: ${widget.userId}');
          } else {
            // 사용자 정보 업데이트
            _displayName = result['customName'] ?? widget.userName;
            _email = result['email'] ?? '';
            
            // 서버에서 조회한 상태메시지 사용
            _statusMessage = result['statusMessage'] ?? widget.userDescription;
            print('서버에서 가져온 상태메시지: ${result['statusMessage']}');
            print('최종 상태메시지: $_statusMessage');

            // 프로필 이미지 URL 설정
            final profileImagePath = result['profileImagePath'];
            if (profileImagePath != null &&
                profileImagePath.toString().isNotEmpty) {
              if (profileImagePath.toString().startsWith('http')) {
                // 이미 완전한 URL(카카오 등)인 경우 그대로 사용
                _profileImageUrl = profileImagePath.toString();
              } else if (profileImagePath.toString().startsWith('images/')) {
                // 서버 이미지 경로인 경우 S3 URL로 변환
                _profileImageUrl =
                    'https://littlebank-dev.s3.ap-northeast-2.amazonaws.com/$profileImagePath';
              } else {
                _profileImageUrl = widget.initialProfileImageUrl;
              }
            } else {
              _profileImageUrl = widget.initialProfileImageUrl;
            }

            // 차단 상태 확인
            bool serverBlockStatus = _checkBlockStatus();
            if (!_isBlocked) {
              _isBlocked = serverBlockStatus;
            }
            print(
              '최종 차단 상태: $_isBlocked (로컬: ${widget.isBlocked}, 서버: $serverBlockStatus)',
            );

            // 친한 친구 상태 확인
            bool serverBestFriendStatus = _checkBestFriendStatus();
            if (widget.isBestFriend) {
              _isBestFriend = true;
            } else {
              _isBestFriend = serverBestFriendStatus;
            }
            print(
              '친한 친구 상태: $_isBestFriend (위젯: ${widget.isBestFriend}, 서버: $serverBestFriendStatus)',
            );

            // 서버에서 가져온 친구 관계 ID 확인
            final friendId = _findFriendIdFromUserInfo();
            if (friendId != null) {
              print('✅ 서버에서 유효한 친구 관계 ID 발견: $friendId');
              _directFriendId = friendId;
            } else {
              print('⚠️ 서버에서 친구 관계 ID를 찾을 수 없습니다. 친구 관계가 아닙니다.');
              _directFriendId = null;
            }
          }
        });

        // 사용자 정보 로드 완료 후 피드 개수 조회 (모든 케이스에서 실행)
        print('🚀 _loadUserFeedCount() 호출 시작 (성공 케이스)');
        _loadUserFeedCount();
      } else {
        setState(() {
          _isLoading = false;
          _hasError = false;
          _displayName = widget.userName;
          _email = '';
          _profileImageUrl = widget.initialProfileImageUrl;
          _actualPostsCount = widget.postsCount; // 기본값 사용
          print('사용자 정보를 가져올 수 없어 기본 정보를 사용합니다. ID: ${widget.userId}');
        });
        
        // 사용자 정보 로드 실패 시에도 피드 개수 조회 시도
        print('🚀 _loadUserFeedCount() 호출 시작 (실패 케이스)');
        _loadUserFeedCount();
      }
    } catch (e) {
      print('사용자 정보 조회 중 오류 발생: $e');
      
      // 기본 정보 설정
      setState(() {
        _isLoading = false;
        _hasError = false;
        _displayName = widget.userName;
        _email = '';
        _profileImageUrl = widget.initialProfileImageUrl;
        _actualPostsCount = widget.postsCount; // 기본값 사용
      });
      
      // 오류 발생 시에도 피드 개수 조회 시도
      print('🚀 _loadUserFeedCount() 호출 시작 (오류 케이스)');
      _loadUserFeedCount();
    }
  }

  // 사용자 피드 개수 조회 (writerId로 정확한 식별)
  Future<void> _loadUserFeedCount() async {
    try {
      print('===== 사용자 피드 개수 조회 시작 =====');
      print('사용자 ID: ${widget.userId}');
      print('사용자 이름: "$_displayName"');
      
      // writerId를 사용한 정확한 매칭 (동명이인 문제 해결)
      print('🎯 writerId 기반 정확한 매칭 - API 호출 시작');
      final feedCount = await FeedService.getUserFeedCountById(widget.userId);
      
      if (mounted) {
        setState(() {
          _actualPostsCount = feedCount;
        });
        print('피드 개수 업데이트 완료: $feedCount개 (writerId 정확 매칭)');
      }
    } catch (e) {
      print('피드 개수 조회 중 오류 발생: $e');
      
      // 오류 발생 시 fallback으로 이름 기반 조회 시도
      try {
        if (_displayName.isNotEmpty) {
          print('⚠️ writerId 조회 실패 - 이름 기반 조회로 fallback');
          final feedCount = await FeedService.getUserFeedCountByName(_displayName);
          
          if (mounted) {
            setState(() {
              _actualPostsCount = feedCount;
            });
            print('피드 개수 업데이트 완료 (fallback): $feedCount개 (이름 매칭)');
          }
        }
      } catch (fallbackError) {
        print('fallback 조회도 실패: $fallbackError');
        // 최종적으로 실패하면 기본값 유지
      }
    }
  }

  // 차단 상태 확인 (서버 정보 기반)
  bool _checkBlockStatus() {
    if (_userInfo == null) {
      print('⚠️ 차단 상태 확인 - 사용자 정보가 없습니다!');
      return _isBlocked;
    }

    // 새로운 API 응답 구조: friendInfo 객체 확인
    final friendInfo = _userInfo!['friendInfo'];
    if (friendInfo != null) {
      // friendInfo가 있으면 이미 친구 관계가 있는 것
      bool serverIsBlocked = friendInfo['isBlocked'] == true;
      print('친구 정보 확인: 서버의 차단 여부 = $serverIsBlocked');

      // friendId 확인 및 저장
      final friendId = friendInfo['friendId'];
      if (friendId != null) {
        print('친구 ID 발견: $friendId');
        _directFriendId = friendId;
      }

      return serverIsBlocked;
    }

    // 이전 버전 호환성: relation 배열 확인
    if (_userInfo!.containsKey('relation')) {
      final relations = _userInfo!['relation'] as List<dynamic>?;
      if (relations != null && relations.isNotEmpty) {
        print('차단 상태 확인 - 관계 목록 (이전 버전 API):');
        for (final relation in relations) {
          print(
            '- 관계 유형: ${relation['relationshipType']}, 상태: ${relation['relationshipStatus']}',
          );

          if (relation['relationshipType'] == 'FRIEND' &&
              relation['relationshipStatus'] == 'CONNECTED') {
            bool serverIsBlocked = relation['isBlocked'] == true;
            print('친구 관계 확인: 서버의 차단 여부 = $serverIsBlocked');

            // 친구 ID 로깅 추가
            if (relation.containsKey('relationshipId')) {
              print('친구 관계 ID: ${relation['relationshipId']}');
              // 관계 ID 저장
              _directFriendId = relation['relationshipId'];
            } else {
              print('⚠️ 관계에 relationshipId가 없습니다!');
            }

            return serverIsBlocked;
          }
        }
      } else {
        print('⚠️ 차단 상태 확인 - 관계 목록이 비어 있습니다!');
      }
    } else {
      print('⚠️ 차단 상태 확인 - 사용자 정보에 관계 정보가 없습니다!');
    }

    // 서버 정보에서 차단 상태를 찾지 못했을 때는 현재 상태 유지
    return _isBlocked;
  }

  // 친한 친구 상태 확인 (서버 정보 기반)
  bool _checkBestFriendStatus() {
    if (_userInfo == null) {
      print('⚠️ 친한 친구 상태 확인 - 사용자 정보가 없습니다!');
      return false;
    }

    // 새로운 API 응답 구조: friendInfo 객체 확인
    final friendInfo = _userInfo!['friendInfo'];
    if (friendInfo != null) {
      // friendInfo가 있으면 이미 친구 관계가 있는 것
      bool serverIsBestFriend = friendInfo['isBestFriend'] == true;
      print('친구 정보 확인: 서버의 친한 친구 여부 = $serverIsBestFriend');
      return serverIsBestFriend;
    }

    // 이전 버전 호환성: relation 배열 확인
    if (_userInfo!.containsKey('relation')) {
      final relations = _userInfo!['relation'] as List<dynamic>?;
      if (relations != null && relations.isNotEmpty) {
        print('친한 친구 상태 확인 - 관계 목록:');
        for (final relation in relations) {
          print(
            '- 관계 유형: ${relation['relationshipType']}, 상태: ${relation['relationshipStatus']}',
          );

          if (relation['relationshipType'] == 'FRIEND' &&
              relation['relationshipStatus'] == 'CONNECTED') {
            // isBestFriend 필드가 있는 경우 해당 값 사용, 없으면 기본값 false
            bool serverIsBestFriend = relation['isBestFriend'] == true;
            print('친구 관계 확인: 서버의 친한 친구 여부 = $serverIsBestFriend');
            return serverIsBestFriend;
          }
        }
      } else {
        print('⚠️ 친한 친구 상태 확인 - 관계 목록이 비어 있습니다!');
      }
    } else {
      print('⚠️ 친한 친구 상태 확인 - 사용자 정보에 관계 정보가 없습니다!');
    }

    // 서버 정보에서 친한 친구 상태를 찾지 못했을 때는 false 반환
    return false;
  }

  // 사용자 정보에서 친구 ID 찾기
  int? _findFriendIdFromUserInfo() {
    // 서버 응답에서 friendInfo 객체의 friendId 먼저 확인
    if (_userInfo != null && _userInfo!.containsKey('friendInfo')) {
      final friendInfo = _userInfo!['friendInfo'];
      if (friendInfo != null && friendInfo['friendId'] != null) {
        print('✅ 친구 정보 객체에서 유효한 friendId 발견: ${friendInfo['friendId']}');
        return friendInfo['friendId'];
      } else {
        print('❌ 친구 정보 객체는 있지만 friendId가 null 또는 객체가 비어있음');
      }
    }

    // 이전 버전 호환성: relation 배열에서 친구 ID 찾기
    if (_userInfo != null && _userInfo!.containsKey('relation')) {
      final relations = _userInfo!['relation'] as List<dynamic>?;
      if (relations != null && relations.isNotEmpty) {
        print('사용자 관계 정보 분석:');
        for (final relation in relations) {
          print('- 관계 유형: ${relation['relationshipType']}');
          print('- 관계 상태: ${relation['relationshipStatus']}');
          print('- 관계 ID: ${relation['relationshipId']}');

          // FRIEND 관계이고 CONNECTED 상태인 경우에만 친구 ID 사용
          if (relation['relationshipType'] == 'FRIEND' &&
              relation['relationshipStatus'] == 'CONNECTED') {
            final relationshipId = relation['relationshipId'] as int?;
            if (relationshipId != null) {
              print('★ 발견된 친구 관계 ID: $relationshipId');
              return relationshipId;
            }
          }
        }
        print('⚠️ 관계 목록에서 유효한 친구 관계를 찾지 못했습니다!');
      } else {
        print('⚠️ 관계 목록이 비어 있습니다!');
      }
    }

    print('💡 서버에서 유효한 친구 관계 ID를 찾지 못했습니다.');
    return null; // 친구 관계 ID가 없음
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Container(
        width: screenWidth,
        height: screenHeight,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF5D9EFF), Color(0xFF8069FF), Color(0xFFBAD5FF)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 앱바
              Container(
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (_operationResult != null) {
                          Navigator.pop(context, _operationResult);
                        } else if (_directFriendId != null) {
                          Navigator.pop(context, {
                            'action': 'refresh',
                            'friendId': _directFriendId,
                            'success': true,
                          });
                        } else {
                          Navigator.pop(context);
                        }
                      },
                      child: Image.asset(
                        'assets/icons/Icon/profile/behind.png',
                        width: 24,
                        height: 24,
                      ),
                    ),
                    const Text(
                      '프로필',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontFamily: 'Pretendard-Bold',
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.32,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _showMoreMenu(context),
                      child: const Icon(
                        Icons.more_horiz,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),

              if (_isLoading)
                const Expanded(
                  child: Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                )
              else if (_hasError)
                const Expanded(child: Center(child: Text('오류가 발생했습니다')))
              else
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.15,
                          ), // 화면 높이의 15% 만큼 상단 여백
                          // 프로필 카드
                          _buildProfileCard(context),
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.15,
                          ), // 화면 높이의 15% 만큼 하단 여백
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Center(
      child: Container(
        width: screenWidth * 0.9,
        padding: const EdgeInsets.all(24),
        decoration: ShapeDecoration(
          gradient: profileCardGradient,
          shape: RoundedRectangleBorder(
            side: const BorderSide(width: 0.60, color: Colors.white),
            borderRadius: BorderRadius.circular(32),
          ),
          shadows: const [
            BoxShadow(
              color: Color(0x35000000),
              blurRadius: 8,
              offset: Offset(3, 4),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // 프로필 이미지
                    Center(
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF146AFF),
                            width: 1,
                          ),
                        ),
                        child: ClipOval(
                          child:
                              _profileImageUrl != null &&
                                      _profileImageUrl!.isNotEmpty
                                  ? CachedNetworkImage(
                                    imageUrl: _profileImageUrl!,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Center(
                                      child: CircularProgressIndicator(
                                        color: Color(0xFF5D9EFF),
                                        strokeWidth: 2.0,
                                      ),
                                    ),
                                    errorWidget: (context, url, error) =>
                                        _buildDefaultProfileImage(),
                                  )
                                  : _buildDefaultProfileImage(),
                        ),
                      ),
                    ),
                    // 친한 친구 버튼
                    Positioned(
                      right: -8,
                      top: -8,
                      child: GestureDetector(
                        onTap: _toggleBestFriend,
                        child: Image.asset(
                          _isBestFriend
                              ? 'assets/icons/Icon/profile/like_after.png'
                              : 'assets/icons/Icon/profile/like_before.png',
                          width: 36,
                          height: 36,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // 이름
                Text(
                  _displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontFamily: 'Pretendard-Bold',
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.88,
                  ),
                ),
                const SizedBox(height: 4),
                // 상태 메시지
                Text(
                  widget.userDescription,
                  style: const TextStyle(
                    color: Color(0xFF001F55), // 진한 네이비 블루
                    fontSize: 14,
                    fontFamily: 'Pretendard-Light',
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 24),
                // 통계
                _buildStatistics(),
                const SizedBox(height: 24),
                // 버튼
                _buildActionButtons(context),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatistics() {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 16,
        horizontal: 8, // 좌우 패딩 감소
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        mainAxisSize: MainAxisSize.min, // Row의 크기를 내용물에 맞게 조정
        children: [
          Expanded(
            child: _buildStatItem('작성글 수', _actualPostsCount.toString()),
          ),
          Expanded(
            child: _buildStatItem('미션 수', widget.missionsCount.toString()),
          ),
          Expanded(
            child: _buildStatItem('친구 수', widget.friendsCount.toString()),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return SizedBox(
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontFamily: 'Pretendard-Light',
              letterSpacing: -0.32,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis, // 텍스트가 넘칠 경우 처리
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF001F55),
              fontSize: 22,
              fontFamily: 'Pretendard-Bold',
              letterSpacing: -0.96,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildActionButton('친구추가', true, () => _addFriend(context)),
        const SizedBox(width: 12),
        _buildActionButton('채팅하기', false, () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => ParentChatDetailScreen(
                    userName: _displayName,
                    avatar: '👦',
                    roomId: _directFriendId ?? 0,
                    userId: widget.userId,
                  ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildActionButton(String text, bool isPrimary, VoidCallback onTap) {
    bool isAlreadyFriend = _directFriendId != null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color:
              isPrimary
                  ? (isAlreadyFriend ? Colors.white : const Color(0xFF5D9EFF))
                  : Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              isPrimary
                  ? (isAlreadyFriend
                      ? 'assets/icons/Icon/profile/already_friend.png'
                      : 'assets/icons/Icon/profile/friend.png')
                  : 'assets/icons/Icon/profile/chat.png',
              width: 20,
              height: 20,
            ),
            const SizedBox(width: 8),
            Text(
              isPrimary ? (isAlreadyFriend ? '내 친구' : '친구추가') : text,
              style: TextStyle(
                color:
                    isPrimary
                        ? (isAlreadyFriend
                            ? const Color(0xFFB6B6B6)
                            : Colors.white)
                        : const Color(0xFF5D9EFF),
                fontSize: 14,
                fontFamily: 'Pretendard-Bold',
                letterSpacing: -0.32,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 작업 결과 저장 메서드 (화면 종료 시 결과 반환용)
  Map<String, dynamic>? _operationResult;

  void _updateResult(Map<String, dynamic> result) {
    _operationResult = result;
  }

  @override
  void dispose() {
    // 화면 종료 시 작업 결과 반환
    if (_operationResult != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pop(_operationResult);
      });
    }
    super.dispose();
  }

  // 기본 프로필 이미지 위젯
  Widget _buildDefaultProfileImage() {
    return Center(
      child: Text(
        _displayName.isNotEmpty ? _displayName[0] : '?',
        style: const TextStyle(
          fontSize: 48,
          fontFamily: 'Pretendard-Bold',
          color: Colors.white,
        ),
      ),
    );
  }

  // 더보기 메뉴 모달 (하단에서 올라오는 형태)
  void _showMoreMenu(BuildContext context) {
    int? friendId = _findFriendIdFromUserInfo();
    bool canBlock = friendId != null;

    print(
      '더보기 메뉴 표시: friendId=$friendId, 차단 상태=$_isBlocked (전달받은 상태: ${widget.isBlocked})',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            width: MediaQuery.of(context).size.width,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        height: 24,
                        child: Stack(
                          children: [
                            const Positioned(
                              left: 0,
                              top: 1,
                              child: Text(
                                '선택해 주세요',
                                style: TextStyle(
                                  color: Color(0xFF202020),
                                  fontSize: 16,
                                  fontFamily: 'Pretendard-Bold',
                                  letterSpacing: -0.72,
                                ),
                              ),
                            ),
                            Positioned(
                              right: 0,
                              top: 0,
                              child: GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: const Icon(
                                  Icons.close,
                                  color: Color(0xFF202020),
                                  size: 24,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (canBlock)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                            if (_isBlocked) {
                              _showUnblockFriendDialog(context);
                            } else {
                              _showBlockFriendDialog(context);
                            }
                          },
                          child: Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 16),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _isBlocked ? '친구 차단 해제하기' : '친구 차단하기',
                                  style: const TextStyle(
                                    color: Color(0xFF202020),
                                    fontSize: 16,
                                    fontFamily: 'Pretendard-Bold',
                                    letterSpacing: -0.72,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _isBlocked
                                      ? '다시 친구의 메시지를 받을 수 있어요'
                                      : '더 이상 친구의 메시지를 받을 수 없어요',
                                  style: const TextStyle(
                                    color: Color(0xFF666666),
                                    fontSize: 14,
                                    fontFamily: 'Pretendard-Light',
                                    letterSpacing: -0.32,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                            _showDeleteFriendDialog(context);
                          },
                          child: Container(
                            width: double.infinity,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '친구 삭제하기',
                                  style: TextStyle(
                                    color: Color(0xFF202020),
                                    fontSize: 16,
                                    fontFamily: 'Pretendard-Bold',
                                    letterSpacing: -0.72,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  '목록에서 친구가 보이지 않아요',
                                  style: TextStyle(
                                    color: Color(0xFF666666),
                                    fontSize: 14,
                                    fontFamily: 'Pretendard-Light',
                                    letterSpacing: -0.32,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: double.infinity,
                      height: 44,
                      decoration: ShapeDecoration(
                        color: const Color(0xFFDCDCDC),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          '닫기',
                          style: TextStyle(
                            color: Color(0xFFB6B6B6),
                            fontSize: 12,
                            fontFamily: 'Pretendard-Medium',
                            letterSpacing: -0.24,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 친구 추가 요청 처리
  Future<void> _addFriend(BuildContext context) async {
    try {
      // 로딩 상태 표시
      setState(() {
        _isLoading = true;
      });

      print('===== 친구 추가 요청 시작 =====');
      print('추가할 사용자 ID: ${widget.userId}');
      print('사용자 이름: $_displayName');
      print('요청 시간: ${DateTime.now()}');

      // 친구 추가 API 호출
      final result = await RelationshipService.sendRelationshipRequest(
        widget.userId,
        'FRIEND', // 관계 유형: 친구
      );

      if (mounted) {
        if (result != null && !result.containsKey('error')) {
          // 성공 메시지
          print('친구 추가 성공 - UI 업데이트');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$_displayName님에게 친구 요청을 보냈습니다.'),
              backgroundColor: const Color(0xFF3A88F4),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );

          // UI 상태 업데이트 (친구 요청 중으로 표시)
          setState(() {
            // 필요하다면 상태 업데이트
            _fetchUserInfo(); // 최신 정보로 다시 조회
          });

          // 결과 저장
          _updateResult({
            'action': 'sendFriendRequest',
            'userId': widget.userId,
            'success': true,
          });
        } else if (result != null && result.containsKey('error')) {
          // 이미 친구거나 요청이 있는 경우
          String message = result['message'] ?? '이미 관계가 있는 사용자입니다.';
          print('친구 추가 실패: $message');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        } else {
          // 요청 실패
          print('친구 추가 실패 - API 오류');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('친구 요청에 실패했습니다. 다시 시도해주세요.'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      }
    } catch (e) {
      print('친구 추가 중 오류 발생: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('오류가 발생했습니다. 다시 시도해주세요.'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      // 마운트 상태 확인 후 로딩 상태 업데이트
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // 친한 친구 토글 기능
  Future<void> _toggleBestFriend() async {
    int? friendId = _findFriendIdFromUserInfo();

    if (friendId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('친한 친구로 등록할 수 없습니다.\n친구 관계가 없거나 아직 등록되지 않았습니다.'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
      return;
    }

    try {
      // 로딩 상태 표시
      setState(() {
        _isLoading = true;
      });

      print('===== 친한 친구 ${_isBestFriend ? "취소" : "등록"} 시작 =====');
      print('친구 ID: $friendId');
      print('사용자 이름: $_displayName');
      print('현재 친한 친구 상태: $_isBestFriend');
      print('요청 시간: ${DateTime.now()}');

      Map<String, dynamic>? result;

      // 현재 상태에 따라 적절한 API 호출
      if (_isBestFriend) {
        // 이미 친한 친구면 취소
        result = await RelationshipService.unmarkAsBestFriend(friendId);
      } else {
        // 친한 친구가 아니면 등록
        result = await RelationshipService.markAsBestFriend(friendId);
      }

      print('API 응답 결과: $result');

      if (mounted && result != null) {
        // 서버 응답의 친한 친구 상태 가져오기
        bool newIsBestFriend = result['isBestFriend'] == true;

        // 성공 메시지
        String actionText = newIsBestFriend ? '등록' : '취소';
        print('친한 친구 $actionText 성공 - UI 업데이트 중');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$_displayName님을 친한 친구에서 $actionText했습니다.'),
            backgroundColor: const Color(0xFF3A88F4),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );

        // 즉시 UI 상태 업데이트
        setState(() {
          _isBestFriend = newIsBestFriend;
          print('친한 친구 상태 업데이트: _isBestFriend = $_isBestFriend');
        });
        print('===== 친한 친구 $actionText 완료 =====');

        // 화면을 유지하고 결과값만 저장
        _updateResult({
          'action': newIsBestFriend ? 'markBestFriend' : 'unmarkBestFriend',
          'friendId': friendId,
          'success': true,
          'isBestFriend': newIsBestFriend,
        });
      } else if (mounted) {
        // 실패 메시지
        print('친한 친구 등록/취소 실패 - API 응답: $result');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('처리에 실패했습니다. 다시 시도해주세요.'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      print('친한 친구 등록/취소 중 오류 발생: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('오류가 발생했습니다. 다시 시도해주세요.'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      // 마운트 상태 확인 후 로딩 상태 업데이트
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // 친구 삭제 확인 다이얼로그
  void _showDeleteFriendDialog(BuildContext context) {
    int? friendId = _findFriendIdFromUserInfo();

    if (friendId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('삭제할 수 없는 사용자입니다.\n친구 관계가 없거나 이미 삭제되었습니다.'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    print('삭제 다이얼로그 표시: friendId = $friendId');

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text(
              '친구 삭제',
              style: TextStyle(fontFamily: 'Pretendard-Bold', fontSize: 18),
            ),
            content: Text(
              _displayName + '님을 친구 목록에서 삭제하시겠습니까?',
              style: const TextStyle(
                fontFamily: 'Pretendard-Regular',
                fontSize: 14,
                color: Color(0xFF444444),
              ),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
            actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF666666),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  '취소',
                  style: TextStyle(
                    color: Color(0xFF666666),
                    fontFamily: 'Pretendard-Medium',
                    fontSize: 14,
                  ),
                ),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await _deleteFriend(friendId);
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                  backgroundColor: const Color(0xFFFFEBEE),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  '삭제',
                  style: TextStyle(
                    color: Colors.red,
                    fontFamily: 'Pretendard-Medium',
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  // 친구 차단 확인 다이얼로그
  void _showBlockFriendDialog(BuildContext context) {
    int? friendId = _findFriendIdFromUserInfo();

    if (friendId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('차단할 수 없는 사용자입니다.\n친구 관계가 없거나 이미 삭제되었습니다.'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    print('차단 다이얼로그 표시: friendId = $friendId');

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text(
              '친구 차단',
              style: TextStyle(fontFamily: 'Pretendard-Bold', fontSize: 18),
            ),
            content: Text(
              _displayName + '님을 차단하시겠습니까?\n차단하면 상대방은 나에게 메시지를 보낼 수 없습니다.',
              style: const TextStyle(
                fontFamily: 'Pretendard-Regular',
                fontSize: 14,
                color: Color(0xFF444444),
              ),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
            actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF666666),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  '취소',
                  style: TextStyle(
                    color: Color(0xFF666666),
                    fontFamily: 'Pretendard-Medium',
                    fontSize: 14,
                  ),
                ),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context); // 다이얼로그 닫기
                  await _blockFriend(friendId);
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                  backgroundColor: const Color(0xFFFFEBEE),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  '차단',
                  style: TextStyle(
                    color: Colors.red,
                    fontFamily: 'Pretendard-Medium',
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  // 친구 차단 해제 확인 다이얼로그
  void _showUnblockFriendDialog(BuildContext context) {
    int? friendId = _findFriendIdFromUserInfo();

    if (friendId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('차단 해제할 수 없는 사용자입니다.\n친구 관계가 없거나 이미 삭제되었습니다.'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    print('차단 해제 다이얼로그 표시: friendId = $friendId');

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text(
              '차단 해제',
              style: TextStyle(fontFamily: 'Pretendard-Bold', fontSize: 18),
            ),
            content: Text(
              _displayName + '님의 차단을 해제하시겠습니까?',
              style: const TextStyle(
                fontFamily: 'Pretendard-Regular',
                fontSize: 14,
                color: Color(0xFF444444),
              ),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
            actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF666666),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  '취소',
                  style: TextStyle(
                    color: Color(0xFF666666),
                    fontFamily: 'Pretendard-Medium',
                    fontSize: 14,
                  ),
                ),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context); // 다이얼로그 닫기
                  await _unblockFriend(friendId);
                },
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF4CAF50),
                  backgroundColor: const Color(0xFFE8F5E9),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  '해제',
                  style: TextStyle(
                    color: Color(0xFF4CAF50),
                    fontFamily: 'Pretendard-Medium',
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  // 친구 삭제 실행
  Future<void> _deleteFriend(int friendId) async {
    if (friendId <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('유효하지 않은 친구 ID: $friendId'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
      return;
    }

    try {
      // 로딩 상태 표시
      setState(() {
        _isLoading = true;
      });

      print('===== 프로필 화면에서 친구 삭제 시작 =====');
      print('삭제할 친구 ID: $friendId');
      print('사용자 이름: $_displayName');
      print('요청 시간: ${DateTime.now()}');

      // 친구 삭제 API 호출
      final result = await RelationshipService.deleteFriend(friendId);

      print('API 응답 결과: $result');

      if (mounted && result) {
        // 성공 메시지
        print('삭제 성공 - UI 업데이트 중');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$_displayName님을 친구 목록에서 삭제했습니다.'),
            backgroundColor: const Color(0xFF3A88F4),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );

        print('===== 친구 삭제 완료 =====');

        // 친구 삭제 성공 시에만 즉시 화면 종료 (다른 경우보다 특수 케이스)
        Navigator.pop(context, {
          'action': 'delete',
          'friendId': friendId,
          'success': true,
        });
      } else if (mounted) {
        // 실패 메시지
        print('삭제 실패 - API 응답: $result');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('친구 삭제에 실패했습니다. 다시 시도해주세요.'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      print('친구 삭제 중 오류 발생: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('오류가 발생했습니다. 다시 시도해주세요.'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      // 마운트 상태 확인 후 로딩 상태 업데이트
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // 친구 차단 실행
  Future<void> _blockFriend(int friendId) async {
    if (friendId <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('유효하지 않은 친구 ID: $friendId'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
      return;
    }

    try {
      // 로딩 상태 표시
      setState(() {
        _isLoading = true;
      });

      print('===== 프로필 화면에서 친구 차단 시작 =====');
      print('차단할 친구 ID: $friendId');
      print('사용자 이름: $_displayName');
      print('요청 시간: ${DateTime.now()}');

      // 친구 차단 API 호출
      final result = await RelationshipService.blockFriend(friendId);

      print('API 응답 결과: $result');

      if (mounted && result != null) {
        // 성공 메시지
        print('차단 성공 - UI 업데이트 중');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$_displayName님을 차단했습니다.'),
            backgroundColor: const Color(0xFF3A88F4),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );

        // 즉시 UI 상태 업데이트
        setState(() {
          _isBlocked = true;
          print('차단 상태 업데이트: isBlocked = $_isBlocked');
        });
        print('===== 친구 차단 완료 =====');

        // 화면을 유지하고 결과값만 저장
        _updateResult({
          'action': 'block',
          'friendId': friendId,
          'success': true,
        });
      } else if (mounted) {
        // 실패 메시지
        print('차단 실패 - API 응답: $result');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('차단에 실패했습니다. 다시 시도해주세요.'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      print('친구 차단 중 오류 발생: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('오류가 발생했습니다. 다시 시도해주세요.'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      // 마운트 상태 확인 후 로딩 상태 업데이트
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // 친구 차단 해제 실행
  Future<void> _unblockFriend(int friendId) async {
    if (friendId <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('유효하지 않은 친구 ID: $friendId'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
      return;
    }

    try {
      // 로딩 상태 표시
      setState(() {
        _isLoading = true;
      });

      print('===== 프로필 화면에서 친구 차단 해제 시작 =====');
      print('차단 해제할 친구 ID: $friendId');
      print('사용자 이름: $_displayName');
      print('요청 시간: ${DateTime.now()}');

      // 친구 차단 해제 API 호출
      final result = await RelationshipService.unblockFriend(friendId);

      print('API 응답 결과: $result');

      if (mounted && result != null) {
        // 성공 메시지
        print('차단 해제 성공 - UI 업데이트 중');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$_displayName님의 차단을 해제했습니다.'),
            backgroundColor: const Color(0xFF3A88F4),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );

        // 즉시 UI 상태 업데이트
        setState(() {
          _isBlocked = false;
          print('차단 상태 업데이트: isBlocked = $_isBlocked');
        });
        print('===== 친구 차단 해제 완료 =====');

        // 화면을 유지하고 결과값만 저장
        _updateResult({
          'action': 'unblock',
          'friendId': friendId,
          'success': true,
        });
      } else if (mounted) {
        // 실패 메시지
        print('차단 해제 실패 - API 응답: $result');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('차단 해제에 실패했습니다. 다시 시도해주세요.'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      print('친구 차단 해제 중 오류 발생: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('오류가 발생했습니다. 다시 시도해주세요.'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      // 마운트 상태 확인 후 로딩 상태 업데이트
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
} 