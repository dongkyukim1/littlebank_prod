import 'package:flutter/material.dart';
import 'chat_detail_screen.dart';
import '../../widgets/parent/bottom_navigation_bar.dart';
import '../../services/relationship_service.dart';
import '../../services/chat_service.dart';
import '../../services/auth_service.dart';
import 'chat/friend_list_screen.dart';
import 'chat/chat_settings_screen.dart';
import 'chat/modals/add_friend_modal.dart';
import 'chat/parent_chat_start_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../child/chat/modals/friend_selection_modal.dart';
import '../child/chat/modals/group_chat_modal.dart';
import '../child/chat/group/group_chat_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ParentChatListScreen extends StatefulWidget {
  const ParentChatListScreen({super.key});

  @override
  State<ParentChatListScreen> createState() => _ParentChatListScreenState();
}

class _ParentChatListScreenState extends State<ParentChatListScreen> {
  // 서버에서 가져올 채팅 목록 데이터
  List<ChatItem> _chatItems = [];
  bool _isLoading = true;

  // 서버에서 가져올 친구 목록 데이터
  List<Map<String, dynamic>> _friendProfiles = [];
  bool _isLoadingFriends = true;

  final int _currentIndex = 1; // 채팅 탭 선택
  bool _isGroupChat = false; // 채팅/그룹채팅 상태 추가
  String _selectedFilter = '최근 순'; // 필터 상태 추가

  // 검색 관련 변수들
  String _searchQuery = '';
  bool _isSearching = false;
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearchFocused = false;

  // 나간 채팅방 관리
  Set<int> _leftRoomIds = <int>{};

  // 검색된 채팅방 목록
  List<ChatItem> get _filteredChatItems {
    if (_searchQuery.isEmpty) {
      return _chatItems;
    }

    return _chatItems.where((item) {
      final nameMatch = item.name.toLowerCase().contains(
        _searchQuery.toLowerCase(),
      );

      if (item.isGroupChat && item.participants != null) {
        final participantMatch = item.participants!.any((participant) {
          final participantName = participant['name']?.toString() ?? '';
          return participantName.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          );
        });
        return nameMatch || participantMatch;
      }

      return nameMatch;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(() {
      setState(() {
        _isSearchFocused = _searchFocusNode.hasFocus;
      });
    });
    // 순서대로 초기화 (나간 채팅방 로드 → 채팅 목록 로드)
    _initializeApp();
  }

  // 앱 초기화 (순차적으로 처리)
  Future<void> _initializeApp() async {
    try {
      await _loadLeftRoomsList();
      _loadFriendList();
      await _loadChatList();
      // 채팅 목록 로드 완료 후 WebSocket 구독
      await _initializeWebSocketAndSubscriptions();
    } catch (e) {
      print('❌ 부모단 앱 초기화 중 오류: $e');
      _loadFriendList();
      await _loadChatList();
      await _initializeWebSocketAndSubscriptions();
    }
  }

  @override
  void dispose() {
    print('=== 🧹 부모단 채팅 목록 화면 정리 시작 ===');
    _searchFocusNode.dispose();
    print('✅ 부모단 채팅 목록 화면 정리 완료');
    super.dispose();
  }

  // 나간 채팅방 목록 로드
  Future<void> _loadLeftRoomsList() async {
    try {
      final userInfo = await AuthService.getUserInfo();
      final currentUserId = userInfo?['userId'];
      if (currentUserId == null) return;

      final prefs = await SharedPreferences.getInstance();
      final userSpecificKey = 'left_chat_rooms_user_$currentUserId';
      final leftRoomsStringList = prefs.getStringList(userSpecificKey) ?? [];
      _leftRoomIds =
          leftRoomsStringList
              .map((e) => int.tryParse(e) ?? 0)
              .where((id) => id > 0)
              .toSet();
      print('📥 사용자 $currentUserId의 나간 채팅방 목록 로드: $_leftRoomIds');
    } catch (e) {
      print('❌ 나간 채팅방 목록 로드 실패: $e');
    }
  }

  // 나간 채팅방 목록 저장
  Future<void> _saveLeftRoomsList() async {
    try {
      final userInfo = await AuthService.getUserInfo();
      final currentUserId = userInfo?['userId'];
      if (currentUserId == null) return;

      final prefs = await SharedPreferences.getInstance();
      final userSpecificKey = 'left_chat_rooms_user_$currentUserId';
      final leftRoomsStringList =
          _leftRoomIds.map((e) => e.toString()).toList();
      await prefs.setStringList(userSpecificKey, leftRoomsStringList);
      print('💾 사용자 $currentUserId의 나간 채팅방 목록 저장 완료: $leftRoomsStringList');
    } catch (e) {
      print('❌ 나간 채팅방 목록 저장 실패: $e');
    }
  }

  // 나간 채팅방 ID를 목록에 추가
  Future<void> _addToLeftRoomsList(int roomId) async {
    _leftRoomIds.add(roomId);
    await _saveLeftRoomsList();
  }

  // 채팅방이 나간 채팅방인지 확인
  bool _isLeftRoom(int roomId) {
    return _leftRoomIds.contains(roomId);
  }

  // 나간 채팅방 목록 초기화 (필요시)
  Future<void> _clearLeftRoomsList() async {
    _leftRoomIds.clear();
    await _saveLeftRoomsList();
  }

  // WebSocket 초기화
  Future<void> _initializeWebSocketAndSubscriptions() async {
    try {
      print('=== 🚀 부모단 채팅 목록 화면 WebSocket 초기화 시작 ===');
      await ChatService.initializeWebSocket();

      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        // 필터링된 채팅방 목록만 구독 (서버 전체 목록이 아닌)
        print('🔍 필터링된 채팅방만 구독 시작: ${_chatItems.length}개');
        await _subscribeToFilteredChatRooms();
        print('✅ 필터링된 채팅방 메시지 및 읽음 처리 구독 완료');
      }
    } catch (e) {
      print('❌ WebSocket 초기화 및 구독 중 오류: $e');
    }
  }

  // 필터링된 채팅방 목록만 구독
  Future<void> _subscribeToFilteredChatRooms() async {
    try {
      print('=== 📖 부모단 필터링된 채팅방 구독 시작 ===');
      
      for (final chatItem in _chatItems) {
        if (chatItem.roomId != null) {
          print('🔍 부모단 채팅방 ${chatItem.roomId} 구독 중...');
          
          // 메시지 구독
          await ChatService.subscribeToChatRoom(
            chatItem.roomId!,
            _handleMessageReceived,
          );
          
          // 읽음 처리 구독
          await ChatService.subscribeToMessageRead(
            chatItem.roomId!,
            _handleMessageReadReceived,
          );
          
          print('✅ 부모단 채팅방 ${chatItem.roomId} 구독 완료');
        }
      }

      print('🎉 부모단 총 ${_chatItems.length}개 필터링된 채팅방 구독 완료');
      print('=== 📖 부모단 필터링된 채팅방 구독 완료 ===');
    } catch (e) {
      print('❌ 부모단 필터링된 채팅방 구독 중 오류: $e');
    }
  }

  // 메시지 수신 핸들러
  void _handleMessageReceived(Map<String, dynamic> messageData) {
    if (!mounted) return;

    try {
      final roomId = messageData['roomId'] as int?;
      final senderUserId = messageData['senderUserId'] as int?;
      final content = messageData['content']?.toString() ?? '';

      if (roomId != null) {
        AuthService.getUserInfo().then((userInfo) {
          final currentUserId = userInfo?['userId'];

          if (senderUserId != null &&
              senderUserId != currentUserId &&
              senderUserId != 0) {
            setState(() {
              final chatItemIndex = _chatItems.indexWhere(
                (item) => item.roomId == roomId,
              );
              if (chatItemIndex != -1) {
                final currentItem = _chatItems[chatItemIndex];
                final newCount = (currentItem.count + 1).clamp(0, 999);

                _chatItems[chatItemIndex] = ChatItem(
                  name: currentItem.name,
                  avatar: currentItem.avatar,
                  message:
                      content.length > 30
                          ? '${content.substring(0, 30)}...'
                          : content,
                  time: '방금 전',
                  count: newCount,
                  userId: currentItem.userId,
                  roomId: currentItem.roomId,
                  isBlocked: currentItem.isBlocked,
                  profileImageUrl: currentItem.profileImageUrl,
                  isGroupChat: currentItem.isGroupChat,
                  participants: currentItem.participants,
                );

                _sortChatItemsByLatestMessage();
              }
            });
          }
        });
      }
    } catch (e) {
      print('❌ 메시지 수신 데이터 처리 중 오류: $e');
    }
  }

  // 메시지 읽음 처리 수신 핸들러
  void _handleMessageReadReceived(Map<String, dynamic> readData) {
    if (!mounted) return;

    try {
      final messageIds = readData['messageIds'] as List<dynamic>? ?? [];
      final roomId = readData['roomId'] as int?;
      final readByUserId = readData['readByUserId'] as int?;

      if (messageIds.isNotEmpty && roomId != null) {
        AuthService.getUserInfo().then((userInfo) {
          final currentUserId = userInfo?['userId'];

          if (readByUserId != null && readByUserId != currentUserId) {
            setState(() {
              final chatItemIndex = _chatItems.indexWhere(
                (item) => item.roomId == roomId,
              );
              if (chatItemIndex != -1) {
                final currentItem = _chatItems[chatItemIndex];
                final decreaseCount = messageIds.length;
                final newCount = (currentItem.count - decreaseCount).clamp(
                  0,
                  999,
                );

                _chatItems[chatItemIndex] = ChatItem(
                  name: currentItem.name,
                  avatar: currentItem.avatar,
                  message: currentItem.message,
                  time: currentItem.time,
                  count: newCount,
                  userId: currentItem.userId,
                  roomId: currentItem.roomId,
                  isBlocked: currentItem.isBlocked,
                  profileImageUrl: currentItem.profileImageUrl,
                  isGroupChat: currentItem.isGroupChat,
                  participants: currentItem.participants,
                );
              }
            });
          }
        });
      }
    } catch (e) {
      print('❌ 읽음 처리 데이터 처리 중 오류: $e');
    }
  }

  // 채팅 목록 로드
  Future<void> _loadChatList() async {
    if (!mounted) return;

    print('===== 📋 부모단 채팅 목록 로드 시작 =====');

    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final userInfo = await AuthService.getUserInfo();
      final currentUserName = userInfo['name'];

      if (!mounted) return;

      final chatRooms = await ChatService.getChatRoomList();

      if (!mounted) return;

      if (chatRooms != null) {
        // API 응답을 ChatItem으로 변환
        final List<ChatItem> chatItems = chatRooms
            .map((room) {
              try {
                final roomRange = room['roomRange']?.toString() ?? 'PRIVATE';
                final roomName = room['roomName']?.toString() ?? '알 수 없음';
                final participantNames =
                    room['participantNameList'] as List<dynamic>? ?? [];

                String displayName = '알 수 없음';
                String? profileImageUrl;
                int? otherUserId;

                if (roomRange == 'GROUP') {
                  // 그룹 채팅인 경우 - roomName이 있으면 우선 사용, 없으면 참여자 이름들로 표시
                  if (roomName.isNotEmpty && roomName != '그룹채팅' && roomName != '알 수 없음') {
                    // 서버에서 설정된 채팅방 이름이 있으면 그것을 사용
                    displayName = roomName;
                  } else if (participantNames.isNotEmpty && currentUserName != null) {
                    // 채팅방 이름이 없으면 참여자 이름들로 조합
                    final otherParticipants = participantNames
                        .where((name) => name.toString() != currentUserName)
                        .toList();
                    
                    if (otherParticipants.isNotEmpty) {
                      displayName = otherParticipants.join(', ');
                    } else {
                      // 모든 참여자가 나간 경우
                      displayName = roomName.isNotEmpty ? roomName : '빈 그룹채팅';
                    }
                  } else {
                    // currentUserName이 없거나 참여자가 없는 경우
                    displayName = roomName.isNotEmpty ? roomName : '그룹채팅';
                  }
                  profileImageUrl = null;
                  otherUserId = 0;
                } else {
                  // 1:1 채팅인 경우 - roomName이 있으면 우선 사용, 없으면 참여자 이름 사용
                  
                  // 먼저 roomName이 유효한 커스텀 이름인지 확인
                  bool hasCustomRoomName = roomName.isNotEmpty && 
                      roomName != '알 수 없음' && 
                      roomName != currentUserName &&
                      !participantNames.contains(roomName); // 참여자 이름과 다른 경우만 커스텀 이름으로 인정

                  if (hasCustomRoomName) {
                    // 커스텀 채팅방 이름이 있으면 그것을 사용
                    displayName = roomName;
                  } else if (participantNames.isNotEmpty) {
                    if (currentUserName != null) {
                      final otherParticipants = participantNames
                          .where((name) => name.toString() != currentUserName)
                          .toList();

                      if (otherParticipants.isNotEmpty) {
                        displayName = otherParticipants.first.toString();
                      } else {
                        return null; // 나 혼자만 있는 경우 제외
                      }
                    } else {
                      displayName = participantNames.first.toString();
                    }
                  }

                  // 친구 목록에서 프로필 이미지 찾기
                  for (final friendProfile in _friendProfiles) {
                    final friendName = friendProfile['name']?.toString() ?? '';
                    if (friendName == displayName) {
                      profileImageUrl =
                          friendProfile['profileImageUrl']?.toString();
                      otherUserId = friendProfile['userId'];
                      break;
                    }
                  }
                }

                String timeText = '방금 전';
                final displayIdx = room['displayIdx'];
                if (displayIdx != null) {
                  try {
                    final utcDateTime =
                        DateTime.parse(displayIdx.toString()).toUtc();
                    final kstDateTime = utcDateTime.add(Duration(hours: 9));
                    final now = DateTime.now();
                    final difference = now.difference(kstDateTime);

                    if (difference.inDays > 0) {
                      timeText = '${difference.inDays}일 전';
                    } else if (difference.inHours > 0) {
                      timeText = '${difference.inHours}시간 전';
                    } else if (difference.inMinutes > 0) {
                      timeText = '${difference.inMinutes}분 전';
                    } else {
                      timeText = '방금 전';
                    }
                  } catch (e) {
                    timeText = '방금 전';
                  }
                }

                String avatar = '?';
                if (displayName.isNotEmpty) {
                  avatar = displayName.substring(0, 1);
                }

                int unreadCount = room['unreadMessageCount'] as int? ?? 0;

                List<Map<String, dynamic>>? participantsList;
                if (roomRange == 'GROUP') {
                  participantsList = participantNames.map((name) {
                    Map<String, dynamic>? friendInfo;
                    try {
                      friendInfo = _friendProfiles.firstWhere(
                        (friend) =>
                            friend['name']?.toString() == name.toString(),
                      );
                    } catch (e) {
                      friendInfo = null;
                    }

                    return {
                      'name':
                          friendInfo?['name']?.toString() ?? name.toString(),
                      'userId': friendInfo?['userId'] ?? 0,
                      'profileImageUrl':
                          friendInfo?['profileImageUrl']?.toString() ?? '',
                    };
                  }).toList();
                }

                String recentMessage = roomRange == 'GROUP'
                    ? '그룹 채팅방이 생성되었습니다.'
                    : '새로운 채팅방이 생성되었습니다.';

                final roomId = room['roomId'] ?? 0;

                final chatItem = ChatItem(
                  name: displayName,
                  avatar: avatar,
                  message: recentMessage,
                  time: timeText,
                  count: unreadCount,
                  userId: otherUserId ?? 0,
                  roomId: roomId,
                  isBlocked: false,
                  profileImageUrl: profileImageUrl,
                  isGroupChat: roomRange == 'GROUP',
                  participants: participantsList,
                );

                print('✅ 부모단 채팅방 변환 완료:');
                print('  - roomId: ${chatItem.roomId}');
                print('  - 타입: ${chatItem.isGroupChat ? "그룹" : "1:1"}');
                print('  - 표시 이름: "${chatItem.name}"');

                return chatItem;
              } catch (e) {
                print('❌ 채팅방 처리 중 오류: $e');
                return null;
              }
            })
            .where((item) => item != null) // null 항목 제거
            .where((item) {
              if (item == null) return false;

              print('🔍 부모단 채팅방 ${item.roomId}(${item.name}) 필터링 검사 중...');
              final isLeft = _isLeftRoom(item.roomId ?? 0);
              print('🔍 부모단 필터링 결과: ${isLeft ? "제외됨" : "포함됨"}');

              if (isLeft) {
                print('🚫 부모단 나간 채팅방 필터링됨: roomId=${item.roomId}, 이름=${item.name}');
              }
              return !isLeft; // 나간 채팅방 제외
            })
            .cast<ChatItem>() // List<ChatItem?>을 List<ChatItem>으로 변환
            .toList();

        _sortChatItemsByLatestMessage(chatItems);

        if (mounted) {
          setState(() {
            _chatItems = chatItems;
            _isLoading = false;
          });
        }

        print('✅ 부모단 채팅 목록 로드 완료: ${chatItems.length}개');
        print('🚪 부모단 현재 나간 채팅방 목록: $_leftRoomIds');
        if (_leftRoomIds.isNotEmpty) {
          print('🚪 부모단 나간 채팅방 ${_leftRoomIds.length}개가 목록에서 제외됨');
        }
        print('📊 부모단 필터링 결과: 총 채팅방에서 ${chatItems.length}개만 표시됨');

        // 각 채팅방 정보 출력
        print('📋 부모단 최종 표시될 채팅방 목록:');
        for (int i = 0; i < chatItems.length; i++) {
          final item = chatItems[i];
          print(
            '  [$i] ${item.isGroupChat ? "그룹" : "1:1"} - ${item.name} (roomId: ${item.roomId})',
          );
        }
      } else {
        if (mounted) {
          setState(() {
            _chatItems = [];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('❌ 부모단 채팅 목록 로드 중 오류: $e');
      if (mounted) {
        setState(() {
          _chatItems = [];
          _isLoading = false;
        });
      }
    }

    print('===== 📋 부모단 채팅 목록 로드 종료 =====');
  }

  // 친구 목록 로드
  Future<void> _loadFriendList() async {
    if (!mounted) return;

    print('===== 👥 부모단 친구 목록 로드 시작 =====');

    setState(() {
      _isLoadingFriends = true;
    });

    try {
      final result = await RelationshipService.getFriendList();

      if (!mounted) return;

      if (result != null) {
        final List<dynamic> friends = result;

        final profiles =
            friends.map((friend) {
              final userInfo = friend['userInfo'] ?? {};
              int userId = 0;
              int friendId = friend['friendId'] ?? 0;

              if (userInfo.containsKey('userId') &&
                  userInfo['userId'] != null) {
                userId = userInfo['userId'];
              } else {
                userId = friendId;
              }

              final profileImagePath = userInfo['profileImagePath'];
              String profileImageUrl = '';

              if (profileImagePath != null &&
                  profileImagePath.toString().isNotEmpty) {
                if (profileImagePath.toString().startsWith('http')) {
                  profileImageUrl = profileImagePath.toString();
                } else if (profileImagePath.toString().startsWith('images/')) {
                  profileImageUrl =
                      'https://littlebank-dev.s3.ap-northeast-2.amazonaws.com/$profileImagePath';
                }
              }

              return {
                'name': friend['customName'] ?? userInfo['userName'] ?? '이름 없음',
                'avatar':
                    friend['customName']?.isNotEmpty
                        ? friend['customName'][0]
                        : '?',
                'userId': userId,
                'friendId': friendId,
                'profileImageUrl': profileImageUrl,
                'phone': userInfo['phone']?.toString() ?? '',
              };
            }).toList();

        setState(() {
          _friendProfiles = profiles;
          _isLoadingFriends = false;
        });
        print('✅ 친구 목록 로드 완료: ${friends.length}명');
      } else {
        setState(() {
          _friendProfiles = [];
          _isLoadingFriends = false;
        });
      }
    } catch (e) {
      print('❌ 친구 목록 로드 중 오류: $e');
      if (mounted) {
        setState(() {
          _friendProfiles = [];
          _isLoadingFriends = false;
        });
      }
    }
  }

  // 채팅방 목록 정렬
  void _sortChatItemsByLatestMessage([List<ChatItem>? items]) {
    final listToSort = items ?? _chatItems;

    listToSort.sort((a, b) {
      if (a.count > 0 && b.count == 0) return -1;
      if (a.count == 0 && b.count > 0) return 1;

      if (a.time == '방금 전' && b.time != '방금 전') return -1;
      if (a.time != '방금 전' && b.time == '방금 전') return 1;

      final aMinutes = _parseTimeToMinutes(a.time);
      final bMinutes = _parseTimeToMinutes(b.time);

      return aMinutes.compareTo(bMinutes);
    });
  }

  // 시간 텍스트를 분 단위로 변환
  int _parseTimeToMinutes(String timeText) {
    if (timeText == '방금 전') return 0;

    final regExp = RegExp(r'(\d+)');
    final match = regExp.firstMatch(timeText);
    if (match != null) {
      final number = int.tryParse(match.group(1) ?? '0') ?? 0;

      if (timeText.contains('분 전')) {
        return number;
      } else if (timeText.contains('시간 전')) {
        return number * 60;
      } else if (timeText.contains('일 전')) {
        return number * 60 * 24;
      }
    }

    return 999999;
  }

  // 검색 기능
  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query.trim();
      _isSearching = _searchQuery.isNotEmpty;
    });
  }

  void _clearSearch() {
    setState(() {
      _searchQuery = '';
      _isSearching = false;
    });
  }

  // 채팅방 생성 다이얼로그 표시
  void _showCreateChatRoomDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height;

        return Container(
          width: screenWidth,
          constraints: BoxConstraints(
            maxHeight: screenHeight * 0.45, // 0.4 -> 0.45로 높이 증가
            minHeight: 280, // 250 -> 280으로 최소 높이 증가
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 헤더 섹션
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: ShapeDecoration(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                ),
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
                            fontSize: 16,
                            fontFamily: 'Pretendard-Bold',
                            letterSpacing: -0.64,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 20,
                            height: 20,
                            child: Image.asset(
                              'assets/icons/Icon/chat/close.png',
                              width: 18,
                              height: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '인원 수에 따라 채팅 전송 유형을 선택할 수 있어요',
                      style: TextStyle(
                        color: const Color(0xFF999999),
                        fontSize: 12,
                        fontFamily: 'Pretendard-Light',
                        letterSpacing: -0.24,
                      ),
                    ),
                  ],
                ),
              ),

              // 컨텐츠 섹션
              Flexible(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ), // 상하 패딩 줄임
                  decoration: BoxDecoration(color: Colors.white),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 1:1 채팅 옵션
                      GestureDetector(
                        onTap: _showFriendSelectionForPrivateChat,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: ShapeDecoration(
                            color: const Color(0xFFE6F1FF), // 부모단 테마 색상
                            shape: RoundedRectangleBorder(
                              side: BorderSide(
                                width: 0.70,
                                color: const Color(0xFF146AFF), // 부모단 테마 색상
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '1:1 채팅',
                                      style: TextStyle(
                                        color: const Color(0xFF202020),
                                        fontSize: 14,
                                        fontFamily: 'Pretendard-Bold',
                                        letterSpacing: -0.28,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      '상대와 나의 개인 채팅창을 통해 대화할 수 있어요!',
                                      style: TextStyle(
                                        color: const Color(0xFF666666),
                                        fontSize: 10,
                                        fontFamily: 'Pretendard-Light',
                                        letterSpacing: -0.20,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: 18,
                                height: 18,
                                decoration: ShapeDecoration(
                                  color: const Color(0xFFE6F1FF), // 부모단 테마 색상
                                  shape: OvalBorder(
                                    side: BorderSide(
                                      width: 0.75,
                                      color: const Color(
                                        0xFF146AFF,
                                      ), // 부모단 테마 색상
                                    ),
                                  ),
                                ),
                                child: Center(
                                  child: Container(
                                    width: 10,
                                    height: 10,
                                    decoration: ShapeDecoration(
                                      color: const Color(
                                        0xFF146AFF,
                                      ), // 부모단 테마 색상
                                      shape: OvalBorder(),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 8), // 12 -> 8로 줄임
                      // 그룹 채팅 옵션
                      GestureDetector(
                        onTap: _showGroupChatCreation,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: ShapeDecoration(
                            color: const Color(0xFFE4ECF8),
                            shape: RoundedRectangleBorder(
                              side: BorderSide(
                                width: 0.70,
                                color: const Color(0xFFDADADA),
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '그룹 채팅',
                                      style: TextStyle(
                                        color: const Color(0xFF202020),
                                        fontSize: 14,
                                        fontFamily: 'Pretendard-Bold',
                                        letterSpacing: -0.28,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      '여러 명에게 한 번에 빠르게 채팅을 전송할 수 있어요!',
                                      style: TextStyle(
                                        color: const Color(0xFF999999),
                                        fontSize: 10,
                                        fontFamily: 'Pretendard-Light',
                                        letterSpacing: -0.20,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: 18,
                                height: 18,
                                decoration: ShapeDecoration(
                                  color: Colors.white,
                                  shape: OvalBorder(
                                    side: BorderSide(
                                      width: 0.75,
                                      color: const Color(0xFFDADADA),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 10), // 16 -> 10으로 줄임
                      // 완료 버튼
                      GestureDetector(
                        onTap: _showFriendSelectionForPrivateChat,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: ShapeDecoration(
                            color: const Color(0xFF146AFF), // 부모단 테마 색상
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '완료',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontFamily: 'Pretendard-Light',
                                letterSpacing: -0.24,
                              ),
                            ),
                          ),
                        ),
                      ),

                      SizedBox(
                        height:
                            MediaQuery.of(context).padding.bottom +
                            8, // 12 -> 8로 줄임
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 1:1 채팅을 위한 친구 선택
  void _showFriendSelectionForPrivateChat() {
    Navigator.pop(context);

    if (_friendProfiles.isEmpty) {
      _showErrorDialog('친구가 없습니다', '먼저 친구를 추가해주세요.');
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      builder: (BuildContext context) {
        return FriendSelectionModal(
          friendProfiles: _friendProfiles,
          onFriendSelected: (int userId) {
            _createPrivateChatRoom(userId);
          },
        );
      },
    );
  }

  // 그룹 채팅 생성
  void _showGroupChatCreation() {
    Navigator.pop(context);

    if (_friendProfiles.isEmpty) {
      _showErrorDialog('친구가 없습니다', '먼저 친구를 추가해주세요.');
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      builder: (BuildContext context) {
        return GroupChatModal(
          friendProfiles: _friendProfiles,
          onGroupCreated: (List<int> selectedUserIds) {
            _createGroupChatRoom(selectedUserIds);
          },
        );
      },
    );
  }

  // 그룹 채팅방 생성 실행
  Future<void> _createGroupChatRoom(List<int> selectedUserIds) async {
    print('===== 그룹 채팅방 생성 시작 =====');
    print('선택된 친구 사용자 IDs: $selectedUserIds');

    if (!mounted) return;

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF146AFF),
              ), // 부모단 테마 색상
            ),
      );

      final userInfo = await AuthService.getUserInfo();
      final myUserId = userInfo['userId'] as int;

      final selectedFriends =
          _friendProfiles.where((friend) {
            return selectedUserIds.contains(friend['userId']);
          }).toList();

      final groupName = selectedFriends
          .map((friend) => friend['name'])
          .join(', ');

      final participants = <Map<String, dynamic>>[];

      participants.add({
        'userId': myUserId,
        'name': userInfo['name'] ?? '나',
        'profileImageUrl': userInfo['profileImagePath'] ?? '',
      });

      participants.addAll(selectedFriends);

      print('그룹 채팅방 생성 API 호출 시작...');
      print('그룹 이름: $groupName');
      print('참여자 ID 목록: ${[myUserId, ...selectedUserIds]}');

      final result = await ChatService.createGroupChatRoom(
        roomName: groupName,
        participantIds: [myUserId, ...selectedUserIds],
      );

      if (!mounted) return;

      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      print('📝 그룹 채팅방 생성 API 응답: $result');

      if (result == null || result['error'] == true) {
        print('❌ 그룹 채팅방 생성 실패: ${result?['message']}');
        if (mounted) {
          print('🔄 실패 후에도 목록 새로고침 시도');
          _loadChatList();
          _showErrorDialog('오류', result?['message'] ?? '그룹 채팅방 생성에 실패했습니다.');
        }
        return;
      }

      final roomId = result['roomId'];
      print('✅ 그룹 채팅방 생성 성공: $roomId');

      print('🔄 채팅방 생성 직후 목록 새로고침');
      if (mounted) {
        await _loadChatList();
        await Future.delayed(const Duration(milliseconds: 500));
      }

      final groupResult = await Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => GroupChatScreen(
                groupName: groupName,
                participants: participants,
                roomId: roomId,
              ),
        ),
      );

      print('🔄 부모단 그룹 채팅에서 돌아온 결과: $groupResult');

      // ✅ 나가기 결과 처리: 즉시 SharedPreferences에 저장
      if (groupResult != null && groupResult['action'] == 'leave_room') {
        final leftRoomId = groupResult['roomId'] as int;
        final success = groupResult['success'] ?? false;
        print('🚪 부모단 그룹 채팅 나가기 감지됨 - roomId: $leftRoomId, 성공: $success');

        // 성공 여부와 관계없이 UI에서 제거 (아이단과 동일)
        await _addToLeftRoomsList(leftRoomId);
        print('✅ 부모단 나간 채팅방으로 즉시 기록 완료');

        // 성공 메시지 표시
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('그룹 채팅방을 나갔습니다.'),
              duration: Duration(seconds: 2),
              backgroundColor: Color(0xFF146AFF),
            ),
          );
        }
      }

      print('🔄 부모단 그룹 채팅에서 돌아옴 - 목록 재새로고침');
      if (mounted) {
        await _loadChatList();
      }
    } catch (e) {
      print('❌ 그룹 채팅방 생성 중 예외 발생: $e');
      if (mounted) {
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        _showErrorDialog('오류', '그룹 채팅방 생성 중 오류가 발생했습니다.');
      }
    }
  }

  // 1:1 채팅방 생성 실행
  Future<void> _createPrivateChatRoom(int friendUserId) async {
    print('===== 1:1 채팅방 찾기/생성 시작 =====');
    print('선택된 친구 사용자 ID: $friendUserId');

    final selectedFriend = _friendProfiles.firstWhere(
      (friend) => friend['userId'] == friendUserId,
      orElse: () => {},
    );

    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }

    if (!mounted) return;

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF146AFF),
              ), // 부모단 테마 색상
            ),
      );

      final userInfo = await AuthService.getUserInfo();
      final myUserId = userInfo['userId'] as int;

      final result = await ChatService.findOrCreatePrivateChatRoom(
        friendUserId: friendUserId,
        myUserId: myUserId,
      );

      if (!mounted) return;

      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      print('📝 1:1 채팅방 처리 API 응답: $result');

      if (result != null && result['error'] != true) {
        final roomId = result['roomId'];
        print('✅ 채팅방 처리 완료: $roomId');

        print('🔄 채팅방 처리 직후 목록 새로고침');
        if (mounted) {
          await _loadChatList();
          await Future.delayed(const Duration(milliseconds: 500));
        }

        if (mounted && selectedFriend.isNotEmpty) {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => ParentChatDetailScreen(
                    // 부모단 채팅 화면 사용
                    roomId: roomId,
                    userId: friendUserId,
                    userName: selectedFriend['name'] ?? '채팅',
                    avatar: selectedFriend['profileImageUrl'] ?? '',
                  ),
            ),
          );

          print('🔄 부모단 1:1 채팅방에서 돌아온 결과: $result');

          // ✅ 나가기 결과 처리: 즉시 SharedPreferences에 저장
          if (result != null && result['action'] == 'leave_room') {
            final leftRoomId = result['roomId'] as int;
            final success = result['success'] ?? false;
            print('🚪 부모단 1:1 채팅 나가기 감지됨 - roomId: $leftRoomId, 성공: $success');

            // 성공 여부와 관계없이 UI에서 제거 (아이단과 동일)
            await _addToLeftRoomsList(leftRoomId);
            print('✅ 부모단 나간 채팅방으로 즉시 기록 완료');

            // 성공 메시지 표시
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('채팅방을 나갔습니다.'),
                  duration: Duration(seconds: 2),
                  backgroundColor: Color(0xFF146AFF),
                ),
              );
            }
          }

          print('🔄 부모단 채팅방에서 돌아옴 - 목록 재새로고침');
          if (mounted) {
            await _loadChatList();
          }
        }
      } else {
        print('❌ 채팅방 찾기/생성 실패: ${result?['message']}');
        if (mounted) {
          print('🔄 실패 후에도 목록 새로고침 시도');
          _loadChatList();
          _showErrorDialog('오류', result?['message'] ?? '채팅방 처리에 실패했습니다.');
        }
      }
    } catch (e) {
      print('❌ 채팅방 처리 중 예외 발생: $e');
      if (mounted) {
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        _showErrorDialog('오류', '채팅방 처리 중 오류가 발생했습니다.');
      }
    }
  }

  // 오류 다이얼로그 표시
  void _showErrorDialog(String title, String message) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(title, style: TextStyle(fontFamily: 'Pretendard-Bold')),
            content: Text(
              message,
              style: TextStyle(fontFamily: 'Pretendard-Regular'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  '확인',
                  style: TextStyle(
                    fontFamily: 'Pretendard-Medium',
                    color: Color(0xFF146AFF), // 부모단 테마 색상
                  ),
                ),
              ),
            ],
          ),
    );
  }

  // 성공 다이얼로그 표시
  void _showSuccessDialog(String title, String message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(title, style: TextStyle(fontFamily: 'Pretendard-Bold')),
            content: Text(
              message,
              style: TextStyle(fontFamily: 'Pretendard-Regular'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  '확인',
                  style: TextStyle(
                    fontFamily: 'Pretendard-Medium',
                    color: Color(0xFF146AFF), // 부모단 테마 색상
                  ),
                ),
              ),
            ],
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
            _loadFriendList();
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // 헤더 섹션
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onLongPress: () async {
                      // 디버그용: 나간 채팅방 목록 초기화 (사용자별)
                      await _clearLeftRoomsList();

                      // 기존 공통 데이터도 삭제 (한 번만)
                      try {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.remove('left_chat_rooms');
                        print('🧹 기존 공통 나간 채팅방 데이터 삭제 완료');
                      } catch (e) {
                        print('❌ 기존 데이터 삭제 실패: $e');
                      }

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('현재 사용자의 나간 채팅방 목록이 초기화되었습니다.'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                      // 목록 새로고침
                      _loadChatList();
                    },
                    child: Text(
                      '채팅',
                      style: TextStyle(
                        color: const Color(0xFF202020),
                        fontSize: 22,
                        fontFamily: 'Pretendard-Bold',
                        letterSpacing: -0.88,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => _showAddFriendModal(context),
                        child: Image.asset(
                          'assets/icons/add_friend.png',
                          width: 24,
                          height: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ChatSettingsScreen(),
                            ),
                          );
                        },
                        child: Image.asset(
                          'assets/icons/setting.png',
                          width: 24,
                          height: 24,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 검색바 섹션
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: ShapeDecoration(
                  color: const Color(0xFFE7ECF6),
                  shape: RoundedRectangleBorder(
                    side: BorderSide(
                      width: _isSearchFocused ? 1.2 : 0.60,
                      color: _isSearchFocused ? const Color(0xFF146AFF) : const Color(0xFF5D6A7F),
                    ),
                    borderRadius: BorderRadius.circular(32),
                  ),
                ),
                child: Row(
                  children: [
                    Image.asset(
                      'assets/icons/Icon/검색/Regular.png',
                      width: 24,
                      height: 24,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        focusNode: _searchFocusNode,
                        onChanged: _onSearchChanged,
                        textAlignVertical: TextAlignVertical.center,
                        decoration: InputDecoration(
                          hintText: '채팅방 이름을 검색해 주세요',
                          hintStyle: TextStyle(
                            color: const Color(0xFF999999),
                            fontSize: 10,
                            fontFamily: 'Pretendard-Light',
                            letterSpacing: -0.20,
                            height: 1.0,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 14),
                          isDense: true,
                          fillColor: Colors.transparent,
                          filled: true,
                          suffixIcon:
                              _searchQuery.isNotEmpty
                                  ? IconButton(
                                    icon: Icon(
                                      Icons.clear,
                                      color: Color(0xFF999999),
                                      size: 18,
                                    ),
                                    onPressed: _clearSearch,
                                    padding: EdgeInsets.zero,
                                    constraints: BoxConstraints(
                                      minWidth: 24,
                                      minHeight: 24,
                                    ),
                                  )
                                  : null,
                        ),
                        style: TextStyle(
                          color: const Color(0xFF202020),
                          fontSize: 12,
                          fontFamily: 'Pretendard-Regular',
                          letterSpacing: -0.24,
                          height: 1.0,
                        ),
                        maxLines: 1,
                        textInputAction: TextInputAction.search,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 최근 연락한 친구들 섹션
            if (!_isSearching) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Stack(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '최근에 연락한 친구들',
                          style: TextStyle(
                            color: const Color(0xFF202020),
                            fontSize: 14,
                            fontFamily: 'Pretendard-Bold',
                            letterSpacing: -0.64,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '최근에 연락한 순서로 노출돼요',
                          style: TextStyle(
                            color: const Color(0xFF999999),
                            fontSize: 12,
                            fontFamily: 'Pretendard-Light',
                            letterSpacing: -0.28,
                          ),
                        ),
                      ],
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const FriendListScreen(),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: ShapeDecoration(
                            color: const Color(0xFFE7ECF6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            '전체보기',
                            style: TextStyle(
                              color: const Color(0xFF001F55),
                              fontSize: 12,
                              fontFamily: 'Pretendard-Light',
                              letterSpacing: -0.20,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 친구 아바타 리스트
              Container(
                height: 90,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child:
                    _isLoadingFriends
                        ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF146AFF),
                            strokeWidth: 2.0,
                          ),
                        )
                        : ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            ..._friendProfiles.take(4).map((friend) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 27),
                                child: _buildRecentContactAvatar(
                                  friend['name'],
                                  friend['avatar'],
                                  friend['userId'],
                                  friend['profileImageUrl'] ?? '',
                                ),
                              );
                            }).toList(),
                          ],
                        ),
              ),
            ],

            // 검색 결과 또는 필터 섹션
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child:
                  _isSearching
                      ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _filteredChatItems.isNotEmpty
                                ? '\'$_searchQuery\' 에 대한 검색결과 ${_filteredChatItems.length}개'
                                : '\'$_searchQuery\' 에 대한 검색결과가 없습니다',
                            style: TextStyle(
                              color: const Color(0xFF202020),
                              fontSize: 16,
                              fontFamily: 'Pretendard-Bold',
                              letterSpacing: -0.32,
                            ),
                          ),
                        ],
                      )
                      : Align(
                        alignment: Alignment.centerLeft,
                        child: PopupMenuButton<String>(
                          offset: const Offset(0, 40),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          onSelected: (String value) {
                            setState(() {
                              _selectedFilter = value;
                            });
                          },
                          itemBuilder:
                              (BuildContext context) =>
                                  <PopupMenuEntry<String>>[
                                    PopupMenuItem<String>(
                                      value: '최근 순',
                                      child: Text(
                                        '최근 순',
                                        style: TextStyle(
                                          fontFamily: 'Pretendard-Regular',
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    PopupMenuItem<String>(
                                      value: '보낸 사람',
                                      child: Text(
                                        '보낸 사람',
                                        style: TextStyle(
                                          fontFamily: 'Pretendard-Regular',
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    PopupMenuItem<String>(
                                      value: '읽지 않은 메시지만',
                                      child: Text(
                                        '읽지 않은 메시지만',
                                        style: TextStyle(
                                          fontFamily: 'Pretendard-Regular',
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            decoration: ShapeDecoration(
                              color: const Color(0xFF5C697E),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _selectedFilter,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontFamily: 'Pretendard-Light',
                                    letterSpacing: -0.24,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.keyboard_arrow_down,
                                  color: Colors.white,
                                  size: 12,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
            ),

            // 채팅 목록 섹션
            Expanded(
              child: RefreshIndicator(
                color: const Color(0xFF146AFF),
                onRefresh: () async {
                  await _loadChatList();
                  await _loadFriendList();
                },
                child:
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _filteredChatItems.isEmpty && _isSearching
                        ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 48,
                                color: Color(0xFFCCCCCC),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                '\'$_searchQuery\'에 대한 검색결과가 없습니다',
                                style: TextStyle(
                                  color: const Color(0xFF999999),
                                  fontSize: 14,
                                  fontFamily: 'Pretendard-Regular',
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '다른 검색어로 시도해보세요',
                                style: TextStyle(
                                  color: const Color(0xFFCCCCCC),
                                  fontSize: 12,
                                  fontFamily: 'Pretendard-Light',
                                ),
                              ),
                            ],
                          ),
                        )
                        : _filteredChatItems.isEmpty
                        ? ListView(
                          children: [
                            Container(
                              height: 200,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.chat_bubble_outline,
                                      size: 48,
                                      color: Color(0xFFCCCCCC),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      '아직 채팅방이 없습니다',
                                      style: TextStyle(
                                        color: const Color(0xFF999999),
                                        fontSize: 14,
                                        fontFamily: 'Pretendard-Regular',
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '친구와 대화를 시작해보세요!',
                                      style: TextStyle(
                                        color: const Color(0xFFCCCCCC),
                                        fontSize: 12,
                                        fontFamily: 'Pretendard-Light',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        )
                        : ListView.builder(
                          itemCount: _filteredChatItems.length,
                          itemBuilder: (context, index) {
                            return _buildNewChatItem(_filteredChatItems[index]);
                          },
                        ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 40),
        child: GestureDetector(
          onTap: _showCreateChatRoomDialog,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            decoration: ShapeDecoration(
              color: const Color(0xFF146AFF),
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
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: const ParentBottomNavigationBar(selectedIndex: 1),
    );
  }

  // 최근 연락한 친구 아바타 위젯
  Widget _buildRecentContactAvatar(
    String name,
    String avatar,
    int userId,
    String profileImageUrl,
  ) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => ParentChatStartScreen(
                  userName: name,
                  userId: userId,
                  initialProfileImageUrl: profileImageUrl,
                  userDescription: '친구와 함께하는 미션',
                  postsCount: 0, // 임시값
                  missionsCount: 0, // 임시값
                  friendsCount: 0, // 임시값
                ),
          ),
        ).then((result) {
          // 프로필 화면에서 돌아왔을 때 친구 목록과 채팅 목록 새로고침
          if (result != null && result['success'] == true) {
            _loadFriendList();
            _loadChatList();
          }
        });
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 50,
            height: 50,
            decoration: ShapeDecoration(
              image:
                  profileImageUrl.isNotEmpty
                      ? DecorationImage(
                        image: CachedNetworkImageProvider(profileImageUrl),
                        fit: BoxFit.cover,
                      )
                      : null,
              shape: OvalBorder(
                side: BorderSide(width: 0.80, color: const Color(0xFF146AFF)),
              ),
            ),
            child:
                profileImageUrl.isEmpty
                    ? Center(
                      child: Text(
                        name.isNotEmpty ? name[0] : '?',
                        style: const TextStyle(fontSize: 18),
                      ),
                    )
                    : null,
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: TextStyle(
              color: const Color(0xFF353535),
              fontSize: 12,
              fontFamily: 'Pretendard-Light',
              letterSpacing: -0.24,
            ),
          ),
        ],
      ),
    );
  }

  // 새로운 디자인의 채팅 아이템 위젯
  Widget _buildNewChatItem(ChatItem item) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => ParentChatDetailScreen(
                  roomId: item.roomId ?? 0,
                  userId: item.userId ?? 0,
                  userName: item.name,
                  avatar: item.profileImageUrl ?? '',
                ),
          ),
        ).then((result) async {
          print('🔄 부모단 채팅방 목록에서 돌아온 결과: $result');

          // 채팅방 이름 변경 결과 처리
          if (result != null && result['action'] == 'update_room_name') {
            final roomId = result['roomId'] as int?;
            final newName = result['newName'] as String?;
            final success = result['success'] as bool? ?? false;

            if (success && roomId != null && newName != null) {
              print('✅ 부모단 채팅방 $roomId 이름 변경됨: $newName');
              
              // 채팅 목록에서 해당 채팅방의 이름 즉시 업데이트
              setState(() {
                final index = _chatItems.indexWhere((item) => item.roomId == roomId);
                if (index != -1) {
                  final currentItem = _chatItems[index];
                  _chatItems[index] = ChatItem(
                    name: newName,
                    avatar: currentItem.avatar,
                    message: currentItem.message,
                    time: currentItem.time,
                    count: currentItem.count,
                    userId: currentItem.userId,
                    roomId: currentItem.roomId,
                    isBlocked: currentItem.isBlocked,
                    profileImageUrl: currentItem.profileImageUrl,
                    isGroupChat: currentItem.isGroupChat,
                    participants: currentItem.participants,
                  );
                  print('✅ 부모단 채팅 목록에서 채팅방 $roomId 이름 업데이트 완료: $newName');
                }
              });
              return; // 이름 변경인 경우 추가 새로고침 생략
            }
          }

          // ✅ 나가기 결과 처리: 즉시 SharedPreferences에 저장
          if (result != null && result['action'] == 'leave_room') {
            final leftRoomId = result['roomId'] as int;
            final success = result['success'] ?? false;
            print(
              '🚪 부모단 채팅방 목록에서 나가기 감지됨 - roomId: $leftRoomId, 성공: $success',
            );

            // 성공 여부와 관계없이 UI에서 제거 (아이단과 동일)
            await _addToLeftRoomsList(leftRoomId);
            print('✅ 부모단 나간 채팅방으로 즉시 기록 완료');

            // 성공 메시지 표시
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('채팅방을 나갔습니다.'),
                  duration: Duration(seconds: 2),
                  backgroundColor: Color(0xFF146AFF),
                ),
              );
            }
          }

          _loadChatList();
        });
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            bottom: BorderSide(width: 0.40, color: const Color(0xFFCCCCCC)),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                // 그룹 채팅이 아닌 개인 채팅에서만 프로필 화면으로 이동
                if (!item.isGroupChat && item.userId != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => ParentChatStartScreen(
                            userName: item.name,
                            userId: item.userId!,
                            initialProfileImageUrl: item.profileImageUrl ?? '',
                            userDescription: '친구와 함께하는 미션',
                            postsCount: 0, // 임시값
                            missionsCount: 0, // 임시값
                            friendsCount: 0, // 임시값
                          ),
                    ),
                  ).then((result) {
                    // 프로필 화면에서 돌아왔을 때 채팅 목록 새로고침
                    if (result != null && result['success'] == true) {
                      _loadChatList();
                    }
                  });
                }
              },
              child: Container(
                width: 56,
                height: 56,
                decoration: ShapeDecoration(
                  image:
                      !item.isGroupChat &&
                              item.profileImageUrl != null &&
                              item.profileImageUrl!.isNotEmpty
                          ? DecorationImage(
                            image: CachedNetworkImageProvider(
                              item.profileImageUrl!,
                            ),
                            fit: BoxFit.cover,
                          )
                          : null,
                  color: item.isGroupChat ? const Color(0xFFE7ECF6) : null,
                  shape: OvalBorder(),
                ),
                child:
                    item.isGroupChat
                        ? Icon(
                          Icons.group,
                          size: 28,
                          color: const Color(0xFF146AFF),
                        )
                        : (item.profileImageUrl == null ||
                            item.profileImageUrl!.isEmpty)
                        ? Center(
                          child: Text(
                            item.avatar,
                            style: const TextStyle(fontSize: 20),
                          ),
                        )
                        : null,
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Container(
                height: 56,
                child: Stack(
                  children: [
                    Positioned(
                      left: 0,
                      top: 7,
                      child: Text(
                        item.isGroupChat && item.participants != null
                            ? '${item.name} (${item.participants!.length}명)'
                            : item.name,
                        style: TextStyle(
                          color: const Color(0xFF202020),
                          fontSize: 14,
                          fontFamily: 'Pretendard-Bold',
                          letterSpacing: -0.28,
                        ),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      top: 35,
                      child: Text(
                        item.message,
                        style: TextStyle(
                          color: const Color(0xFF666666),
                          fontSize: 10,
                          fontFamily: 'Pretendard-Light',
                          letterSpacing: -0.20,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Positioned(
                      right: 0,
                      top: 7,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            item.time,
                            style: TextStyle(
                              color: const Color(0xFFC4C4C4),
                              fontSize: 9,
                              fontFamily: 'Pretendard-Light',
                              letterSpacing: -0.18,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (item.count > 0)
                            Container(
                              constraints: BoxConstraints(
                                minWidth: 20,
                                minHeight: 20,
                              ),
                              padding: EdgeInsets.symmetric(
                                horizontal: item.count > 99 ? 6 : 0,
                                vertical: 2,
                              ),
                              decoration: ShapeDecoration(
                                color: const Color(0xFF146AFF),
                                shape:
                                    item.count > 99
                                        ? RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        )
                                        : OvalBorder(),
                              ),
                              child: Center(
                                child: Text(
                                  item.count > 99
                                      ? '99+'
                                      : item.count.toString(),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontFamily: 'Pretendard-Bold',
                                    letterSpacing: -0.20,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatItem {
  final String name;
  final String message;
  final int count;
  final String avatar;
  final String time;
  final int? userId;
  final int? roomId;
  final bool isBlocked;
  final String? profileImageUrl;
  final bool isGroupChat;
  final List<Map<String, dynamic>>? participants;

  ChatItem({
    required this.name,
    required this.message,
    required this.count,
    required this.avatar,
    required this.time,
    this.userId,
    this.roomId,
    this.isBlocked = false,
    this.profileImageUrl,
    this.isGroupChat = false,
    this.participants,
  });
}
