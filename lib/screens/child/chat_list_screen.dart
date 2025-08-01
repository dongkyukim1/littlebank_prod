import 'package:flutter/material.dart';
import 'chat_detail_screen.dart';
import 'mission_screen.dart';
import '../../widgets/common/bottom_navigation_bar.dart';
import 'chat/friend_list_screen.dart';
import 'chat/chat_start_screen.dart';
import 'chat/chat_settings_screen.dart';
import 'chat/search_history_screen.dart';
import 'chat/modals/add_friend_modal.dart';
import '../../services/relationship_service.dart';
import '../../services/chat_service.dart';
import '../../services/auth_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'chat/modals/friend_selection_modal.dart';
import 'chat/modals/group_chat_modal.dart';
import 'chat/group/group_chat_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  // 서버에서 가져올 채팅 목록 데이터
  List<ChatItem> _chatItems = [];
  bool _isLoading = true;

  // 서버에서 가져올 친구 목록 데이터
  List<Map<String, dynamic>> _friendProfiles = [];
  bool _isLoadingFriends = true;

  // 나간 채팅방 ID 목록 (서버 지연 대응용)
  Set<int> _leftRoomIds = {};

  final int _currentIndex = 1; // 채팅 탭 선택
  bool _isGroupChat = false; // 채팅/그룹채팅 상태 추가
  String _selectedFilter = '최근 순'; // 필터 상태 추가
  bool _isSearchPressed = false; // 검색바 눌림 상태
  
  // 검색 관련 상태
  bool _isSearchMode = false; // 검색 모드 활성화 여부
  String _searchQuery = ''; // 현재 검색어
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<ChatItem> _filteredChatItems = []; // 필터링된 채팅 목록

  @override
  void initState() {
    super.initState();
    // 순서대로 초기화 (nagged 채팅방 로드 → 채팅 목록 로드)
    _initializeApp();
  }

  // 앱 초기화 (순차적으로 처리)
  Future<void> _initializeApp() async {
    try {
      await _loadLeftRoomsList();
      _loadFriendList();
      await _loadChatList();
      _initializeWebSocketAndSubscriptions();
    } catch (e) {
      _loadFriendList();
      _loadChatList();
      _initializeWebSocketAndSubscriptions();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  // SharedPreferences에서 나간 채팅방 목록 로드 (사용자별)
  Future<void> _loadLeftRoomsList() async {
    try {
      print('📋 SharedPreferences 로드 시작...');
      final prefs = await SharedPreferences.getInstance();

      // 현재 사용자 ID 가져오기
      final userInfo = await AuthService.getUserInfo();
      final currentUserId = userInfo?['userId']?.toString() ?? '0';

      // 사용자별 키로 나간 채팅방 목록 로드
      final userSpecificKey = 'left_chat_rooms_user_$currentUserId';
      final leftRoomsStringList = prefs.getStringList(userSpecificKey) ?? [];
      print(
        '📋 사용자 $currentUserId의 SharedPreferences에서 읽은 데이터: $leftRoomsStringList',
      );

      _leftRoomIds = leftRoomsStringList.map((id) => int.parse(id)).toSet();
      print(
        '📋 로드 완료 - 사용자 $currentUserId의 나간 채팅방 목록: $_leftRoomIds (${_leftRoomIds.length}개)',
      );
    } catch (e) {
      print('❌ SharedPreferences 로드 실패: $e');
      print('❌ 기존 데이터 유지: $_leftRoomIds');
      // _leftRoomIds.clear(); // 오류 시에도 기존 데이터 유지
    }
  }

  // SharedPreferences에 나간 채팅방 목록 저장 (사용자별)
  Future<void> _saveLeftRoomsList() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 현재 사용자 ID 가져오기
      final userInfo = await AuthService.getUserInfo();
      final currentUserId = userInfo?['userId']?.toString() ?? '0';

      // 사용자별 키로 나간 채팅방 목록 저장
      final userSpecificKey = 'left_chat_rooms_user_$currentUserId';
      final leftRoomsStringList =
          _leftRoomIds.map((id) => id.toString()).toList();
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

  // 자동으로 나간 채팅방 감지 및 추가 (현재 비활성화됨)
  Future<void> _autoDetectLeftRooms() async {
    // 자동 감지 기능 비활성화 - 수동으로 나간 채팅방만 처리
    // participantNameList 기반 감지가 부정확하여 정상 채팅방도 잘못 제거할 수 있음
  }

  // 특정 채팅방 정보 새로고침 (나가기 알림 수신 시)
  Future<void> _refreshSpecificChatRoom(int roomId) async {
    try {
      print('🔄 채팅방 $roomId 정보 새로고침 시작');

      // 서버에서 최신 채팅방 목록을 다시 가져와서 해당 채팅방 정보 업데이트
      final chatRooms = await ChatService.getChatRoomList();
      if (chatRooms != null && mounted) {
        // 해당 채팅방 찾기
        final updatedRoom = chatRooms.firstWhere(
          (room) => room['roomId'] == roomId,
          orElse: () => <String, dynamic>{},
        );

        if (updatedRoom.isNotEmpty) {
          print(
            '🔄 채팅방 $roomId 서버 정보 업데이트됨: ${updatedRoom['roomName']} (참여자: ${updatedRoom['participantNameList']})',
          );

          // 기존 ChatItem 찾아서 업데이트
          setState(() {
            final chatItemIndex = _chatItems.indexWhere(
              (item) => item.roomId == roomId,
            );
            if (chatItemIndex != -1) {
              final currentItem = _chatItems[chatItemIndex];

              // 참여자 목록 및 채팅방 이름 업데이트
              final participantList =
                  updatedRoom['participantNameList'] as List<dynamic>? ?? [];
              final participantNames =
                  participantList.map((e) => e.toString()).toList();
              final isGroup = updatedRoom['roomRange'] == 'GROUP';

              // participants를 올바른 형식으로 변환
              final participantsData =
                  participantNames.map((name) => {'name': name}).toList();

              String displayName;
              if (isGroup) {
                // 그룹 채팅인 경우 참여자들의 이름 조합 (현재 사용자 제외)
                displayName = participantNames.join(', ');
              } else {
                // 1:1 채팅방은 현재 사용자 제외한 상대방 이름만
                displayName = updatedRoom['roomName'] ?? '';
              }

              _chatItems[chatItemIndex] = ChatItem(
                name: displayName,
                avatar: currentItem.avatar,
                message: currentItem.message,
                time: currentItem.time,
                count: currentItem.count,
                userId: currentItem.userId,
                roomId: currentItem.roomId,
                isBlocked: currentItem.isBlocked,
                profileImageUrl: currentItem.profileImageUrl,
                isGroupChat: isGroup,
                participants: participantsData,
              );

              print('✅ 채팅방 $roomId UI 업데이트 완료: $displayName');
            } else {
              print('⚠️ 채팅방 $roomId을 UI 목록에서 찾을 수 없음');
            }
          });
        } else {
          print('⚠️ 서버에서 채팅방 $roomId을 찾을 수 없음 - 나간 것으로 추정');
        }
      }
    } catch (e) {
      print('❌ 채팅방 $roomId 정보 새로고침 실패: $e');
    }
  }

  // 나가기 후 백그라운드 서버 동기화
  Future<void> _backgroundSyncAfterLeave(int leftRoomId) async {
    try {
      print('🔄 백그라운드 서버 동기화 시작 - 채팅방 ID: $leftRoomId');

      // 5초 후에 서버 상태 확인
      await Future.delayed(const Duration(seconds: 5));

      if (!mounted) return;

      // 서버에서 실제로 제거되었는지 확인
      final chatRooms = await ChatService.getChatRoomList();
      if (chatRooms != null) {
        final roomExists = chatRooms.any(
          (room) => room['roomId'] == leftRoomId,
        );
        if (roomExists) {
          print('⚠️ 서버에서 아직 채팅방이 존재함 - 추가 확인 필요');
          // 10초 더 기다린 후 다시 확인
          await Future.delayed(const Duration(seconds: 10));
          if (!mounted) return;

          final chatRoomsSecond = await ChatService.getChatRoomList();
          if (chatRoomsSecond != null) {
            final roomExistsSecond = chatRoomsSecond.any(
              (room) => room['roomId'] == leftRoomId,
            );
            if (!roomExistsSecond) {
              print('✅ 백그라운드 동기화 확인 - 서버에서 채팅방 제거됨');
            } else {
              print('⚠️ 백그라운드 동기화 실패 - 서버에서 여전히 채팅방 존재');
            }
          }
        } else {
          print('✅ 백그라운드 동기화 확인 - 서버에서 채팅방 제거됨');
        }
      }
    } catch (e) {
      print('❌ 백그라운드 서버 동기화 중 오류: $e');
    }
  }

  // WebSocket 초기화 및 모든 채팅방 읽음 처리 구독
  Future<void> _initializeWebSocketAndSubscriptions() async {
    try {
      print('=== 🚀 채팅 목록 화면 WebSocket 초기화 시작 ===');

      // WebSocket 연결 초기화
      await ChatService.initializeWebSocket();

      // 잠시 대기 후 모든 채팅방의 읽음 처리 상태 구독
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        await ChatService.subscribeToAllChatRooms(
          onAnyMessageReceived: _handleMessageReceived,
          onAnyMessageReadReceived: _handleMessageReadReceived,
        );

        print('✅ 모든 채팅방 메시지 및 읽음 처리 구독 완료');

        // 채팅방 나가기 알림 구독 (모든 채팅방에 대해)
        await _subscribeToRoomLeaveNotifications();
      }
    } catch (e) {
      print('❌ WebSocket 초기화 및 구독 중 오류: $e');
    }
  }

  // 메시지 수신 핸들러 (채팅방 밖에서 수신)
  void _handleMessageReceived(Map<String, dynamic> messageData) {
    print('=== 📨 채팅 목록에서 메시지 수신 ===');
    print('메시지 데이터: $messageData');

    try {
      final roomId = messageData['roomId'] as int?;
      final senderUserId = messageData['senderUserId'] as int?;
      final content = messageData['content']?.toString() ?? '';
      final displayIdx = messageData['displayIdx']?.toString();
      final messageId = messageData['messageId'] as int?;

      if (roomId != null && mounted) {
        print('📨 채팅방 $roomId에서 새 메시지 수신 (ID: $messageId, 발신자: $senderUserId)');

        // 현재 사용자 정보 확인
        AuthService.getUserInfo().then((userInfo) {
          final currentUserId = userInfo?['userId'];

          // 내가 보낸 메시지가 아닌 경우에만 읽지 않은 메시지 수 증가
          if (senderUserId != null &&
              senderUserId != currentUserId &&
              senderUserId != 0) {
            setState(() {
              // 해당 채팅방의 읽지 않은 메시지 수 증가
              final chatItemIndex = _chatItems.indexWhere(
                (item) => item.roomId == roomId,
              );
              if (chatItemIndex != -1) {
                final currentItem = _chatItems[chatItemIndex];
                final newCount = (currentItem.count + 1).clamp(0, 999);

                // 메시지 내용 표시용 텍스트 생성 (메시지 타입에 따라)
                String displayMessage = '';
                final messageType =
                    messageData['messageType']?.toString().toUpperCase() ??
                    'TEXT';

                switch (messageType) {
                  case 'TEXT':
                    displayMessage = content;
                    break;
                  case 'IMAGE':
                    displayMessage = '📷 사진을 보냈습니다';
                    break;
                  case 'VIDEO':
                    displayMessage = '🎥 동영상을 보냈습니다';
                    break;
                  case 'FILE':
                    displayMessage = '📎 파일을 보냈습니다';
                    break;
                  case 'MISSION_CARD':
                    displayMessage = '🎯 미션 카드를 보냈습니다';
                    break;
                  default:
                    displayMessage = content;
                }

                // 시스템 메시지인 경우 (senderUserId가 0)
                if (senderUserId == 0) {
                  displayMessage = content;
                }

                // 메시지가 너무 길면 자르기
                if (displayMessage.length > 30) {
                  displayMessage = '${displayMessage.substring(0, 30)}...';
                }

                // 시간 업데이트
                String timeText = '방금 전';
                if (displayIdx != null) {
                  try {
                    final utcDateTime = DateTime.parse(displayIdx).toUtc();
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

                print(
                  '📨 채팅방 $roomId 읽지 않은 메시지 수: ${currentItem.count} → $newCount',
                );
                print('📨 최신 메시지: $displayMessage');

                // ChatItem 업데이트 (정렬 함수에서 순서를 결정)
                _chatItems[chatItemIndex] = ChatItem(
                  name: currentItem.name,
                  avatar: currentItem.avatar,
                  message:
                      displayMessage.isNotEmpty
                          ? displayMessage
                          : currentItem.message,
                  time: timeText,
                  count: newCount,
                  userId: currentItem.userId,
                  roomId: currentItem.roomId,
                  isBlocked: currentItem.isBlocked,
                  profileImageUrl: currentItem.profileImageUrl,
                  isGroupChat: currentItem.isGroupChat,
                  participants: currentItem.participants,
                );

                print('✅ 채팅방 $roomId 새 메시지로 목록 업데이트 완료 - 읽지 않은 수: $newCount');

                // 실시간 메시지 수신 후 목록 다시 정렬 (최신 메시지가 맨 위로)
                _sortChatItemsByLatestMessage();
              } else {
                print('⚠️ 채팅방 $roomId을 목록에서 찾을 수 없음 - 전체 목록 새로고침');
                _loadChatList();
              }
            });
          } else {
            print('📨 내가 보낸 메시지이거나 시스템 메시지이므로 읽지 않은 수 증가 생략');

            // 내가 보낸 메시지라도 최신 메시지 내용과 시간은 업데이트
            setState(() {
              final chatItemIndex = _chatItems.indexWhere(
                (item) => item.roomId == roomId,
              );
              if (chatItemIndex != -1) {
                final currentItem = _chatItems[chatItemIndex];

                // 내가 보낸 메시지도 메시지 타입에 따라 표시
                String displayMessage = '';
                final messageType =
                    messageData['messageType']?.toString().toUpperCase() ??
                    'TEXT';

                switch (messageType) {
                  case 'TEXT':
                    displayMessage = content;
                    break;
                  case 'IMAGE':
                    displayMessage = '📷 사진을 보냈습니다';
                    break;
                  case 'VIDEO':
                    displayMessage = '🎥 동영상을 보냈습니다';
                    break;
                  case 'FILE':
                    displayMessage = '📎 파일을 보냈습니다';
                    break;
                  case 'MISSION_CARD':
                    displayMessage = '🎯 미션 카드를 보냈습니다';
                    break;
                  default:
                    displayMessage = content;
                }

                // 시스템 메시지인 경우 (senderUserId가 0)
                if (senderUserId == 0) {
                  displayMessage = content;
                }

                // 메시지가 너무 길면 자르기
                if (displayMessage.length > 30) {
                  displayMessage = '${displayMessage.substring(0, 30)}...';
                }

                String timeText = '방금 전';
                if (displayIdx != null) {
                  try {
                    final utcDateTime = DateTime.parse(displayIdx).toUtc();
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

                // ChatItem 업데이트 (정렬 함수에서 순서를 결정)
                _chatItems[chatItemIndex] = ChatItem(
                  name: currentItem.name,
                  avatar: currentItem.avatar,
                  message:
                      displayMessage.isNotEmpty
                          ? displayMessage
                          : currentItem.message,
                  time: timeText,
                  count: currentItem.count, // 읽지 않은 수는 그대로
                  userId: currentItem.userId,
                  roomId: currentItem.roomId,
                  isBlocked: currentItem.isBlocked,
                  profileImageUrl: currentItem.profileImageUrl,
                  isGroupChat: currentItem.isGroupChat,
                  participants: currentItem.participants,
                );

                print('✅ 내 메시지로 채팅방 $roomId 최신 내용 업데이트 완료');

                // 내 메시지로 업데이트 후에도 목록 다시 정렬
                _sortChatItemsByLatestMessage();
              }
            });
          }
        });
      } else {
        print('⚠️ 메시지 수신 데이터 불완전: roomId=$roomId');
      }
    } catch (e) {
      print('❌ 메시지 수신 데이터 처리 중 오류: $e');
      // 오류 발생 시 전체 목록 새로고침
      _loadChatList();
    }
  }

  // 메시지 읽음 처리 수신 핸들러
  void _handleMessageReadReceived(Map<String, dynamic> readData) {
    print('=== 📖 채팅 목록에서 읽음 처리 수신 ===');
    print('읽음 처리 데이터: $readData');

    try {
      final messageIds = readData['messageIds'] as List<dynamic>? ?? [];
      final roomId = readData['roomId'] as int?;
      final readByUserId = readData['readByUserId'] as int?;

      if (messageIds.isNotEmpty && roomId != null && mounted) {
        print(
          '📖 채팅방 $roomId에서 ${messageIds.length}개 메시지 읽음 처리 by User $readByUserId',
        );

        // 현재 사용자 정보 확인
        AuthService.getUserInfo().then((userInfo) {
          final currentUserId = userInfo?['userId'];

          // 다른 사용자가 읽음 처리한 경우에만 내 읽지 않은 메시지 수 감소
          if (readByUserId != null && readByUserId != currentUserId) {
            setState(() {
              // 해당 채팅방의 읽지 않은 메시지 수 감소
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

                print(
                  '📖 채팅방 $roomId 읽지 않은 메시지 수: ${currentItem.count} → $newCount',
                );

                // ChatItem 업데이트
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

                print('✅ 채팅방 $roomId 읽지 않은 메시지 수 업데이트 완료: $newCount');
              } else {
                print('⚠️ 채팅방 $roomId을 목록에서 찾을 수 없음');
              }
            });
          } else {
            print('📖 내가 읽음 처리한 경우이므로 목록 업데이트 생략');
          }
        });
      } else {
        print(
          '⚠️ 읽음 처리 데이터 불완전: messageIds=${messageIds.length}, roomId=$roomId',
        );
      }
    } catch (e) {
      print('❌ 읽음 처리 데이터 처리 중 오류: $e');
      // 오류 발생 시에만 전체 목록 새로고침
      _loadChatList();
    }
  }

  // 채팅방 나가기 알림 수신 핸들러
  void _handleRoomLeaveReceived(Map<String, dynamic> leaveData) {
    print('=== 🚪 채팅 목록에서 나가기 알림 수신 ===');
    print('나가기 알림 데이터: $leaveData');

    try {
      final roomId = leaveData['roomId'] as int?;
      final leaverUserId = leaveData['leaverUserId'] as int?;
      final leaverName = leaveData['leaverName'] as String? ?? '사용자';
      final message =
          leaveData['message']?.toString() ?? '$leaverName님이 나갔습니다.';
      final timestamp = leaveData['timestamp']?.toString();

      if (roomId != null && mounted) {
        print('🚪 채팅방 $roomId에서 나가기 알림 수신: $message');
        print('🚪 나간 사용자 ID: $leaverUserId, 이름: $leaverName');

        // 현재 사용자 정보 가져오기
        AuthService.getUserInfo().then((userInfo) {
          final currentUserId = userInfo?['userId'] as int?;
          final currentUserName = userInfo?['name'] as String?;

          print('🚪 현재 사용자 ID: $currentUserId, 이름: $currentUserName');

          // 내가 나간 경우인지 확인 (userId 우선, 이름으로 보조 확인)
          bool isMyLeave = false;

          if (leaverUserId != null && currentUserId != null) {
            isMyLeave = (leaverUserId == currentUserId);
            print(
              '🚪 사용자 ID 비교: $leaverUserId == $currentUserId => $isMyLeave',
            );
          } else if (currentUserName != null) {
            isMyLeave =
                (leaverName == currentUserName) ||
                message.contains('$currentUserName님이') &&
                    message.contains('나갔습니다');
            print(
              '🚪 사용자 이름 비교: $leaverName == $currentUserName => $isMyLeave',
            );
          }

          if (isMyLeave) {
            print('✅ 내가 채팅방 $roomId를 나감 - 목록에서 즉시 제거');
            setState(() {
              final beforeCount = _chatItems.length;
              _chatItems.removeWhere((item) => item.roomId == roomId);
              final afterCount = _chatItems.length;
              print('✅ 채팅방 $roomId 목록에서 제거 완료: $beforeCount -> $afterCount');
            });

            // 성공 메시지 표시
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '그룹채팅에서 나갔습니다.',
                    style: TextStyle(
                      fontFamily: 'Pretendard-Light',
                      color: Colors.white,
                    ),
                  ),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 2),
                ),
              );
            }
          } else {
            print('🚪 다른 사용자($leaverName)가 나감 - 목록 유지하고 메시지 업데이트');

            // 다른 사용자가 나간 경우: 최신 메시지로 업데이트 + 참여자 수 새로고침
            setState(() {
              final chatItemIndex = _chatItems.indexWhere(
                (item) => item.roomId == roomId,
              );
              if (chatItemIndex != -1) {
                final currentItem = _chatItems[chatItemIndex];

                // 시간 업데이트
                String timeText = '방금 전';
                if (timestamp != null) {
                  try {
                    final utcDateTime = DateTime.parse(timestamp).toUtc();
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

                // ChatItem 업데이트
                _chatItems[chatItemIndex] = ChatItem(
                  name: currentItem.name,
                  avatar: currentItem.avatar,
                  message: message,
                  time: timeText,
                  count: currentItem.count,
                  userId: currentItem.userId,
                  roomId: currentItem.roomId,
                  isBlocked: currentItem.isBlocked,
                  profileImageUrl: currentItem.profileImageUrl,
                  isGroupChat: currentItem.isGroupChat,
                  participants: currentItem.participants,
                );

                print('✅ 채팅방 $roomId 나가기 메시지로 업데이트 완료');

                // 최신 메시지로 업데이트 후 목록 다시 정렬
                _sortChatItemsByLatestMessage();
              }
            });

            // 채팅방 상세 정보 새로고침 (참여자 수 업데이트)
            _refreshSpecificChatRoom(roomId);
          }
        });
      } else {
        print('⚠️ 나가기 알림 데이터 불완전: roomId=$roomId');
      }
    } catch (e) {
      print('❌ 나가기 알림 데이터 처리 중 오류: $e');
      // 오류 발생 시 전체 목록 새로고침
      _loadChatList();
    }
  }

  // 채팅방 이벤트 로그 확인 (나가기 여부 체크)
  Future<void> _checkRoomEventLogs(ChatItem chatItem) async {
    try {
      print('📋 채팅방 ${chatItem.roomId} 이벤트 로그 조회 시작');
      print(
        '📋 채팅방 정보: name="${chatItem.name}", isGroup=${chatItem.isGroupChat}',
      );

      // 이벤트 로그 조회 - 최근 메시지 기준으로 확인
      final eventLogs = await ChatService.getChatEventLogs(
        chatItem.roomId,
        isOnlyOnePage: true,
      );

      print(
        '📋 채팅방 ${chatItem.roomId} 이벤트 로그 조회 결과: ${eventLogs?.length ?? 0}개',
      );

      if (eventLogs != null && eventLogs.isNotEmpty) {
        print('📋 채팅방 ${chatItem.roomId} 이벤트 로그 내용:');
        for (int i = 0; i < eventLogs.length; i++) {
          final log = eventLogs[i];
          print('  [$i] ${log['message']} (${log['timestamp']})');
        }

        // 현재 사용자 이름으로 나가기 이벤트 확인
        final userInfo = await AuthService.getUserInfo();
        final currentUserName = userInfo?['name'];
        print('📋 현재 사용자 이름: $currentUserName');

        if (currentUserName != null) {
          // 각 로그를 하나씩 확인
          bool hasMyLeaveEvent = false;
          for (final log in eventLogs) {
            final message = log['message']?.toString() ?? '';
            print('📋 로그 메시지 확인: "$message"');

            // 나가기 패턴 확인
            final patterns = [
              '$currentUserName님이 나갔습니다',
              '$currentUserName님이 채팅방을 나갔습니다',
              '$currentUserName left',
              '$currentUserName 퇴장',
            ];

            for (final pattern in patterns) {
              if (message.contains(pattern)) {
                print('🚪 나가기 패턴 발견: "$pattern" in "$message"');
                hasMyLeaveEvent = true;
                break;
              }
            }

            if (hasMyLeaveEvent) break;
          }

          if (hasMyLeaveEvent) {
            print('🚪 채팅방 ${chatItem.roomId}에서 내가 나간 이벤트 발견 - 목록에서 제거');
            if (mounted) {
              setState(() {
                final beforeCount = _chatItems.length;
                _chatItems.removeWhere(
                  (item) => item.roomId == chatItem.roomId,
                );
                final afterCount = _chatItems.length;
                print('🚪 목록에서 제거 완료: $beforeCount -> $afterCount');
              });
            }
            return; // 이미 나간 채팅방이므로 더 이상 처리하지 않음
          } else {
            print('📋 채팅방 ${chatItem.roomId}에서 나가기 이벤트 없음 - 목록 유지');
          }
        } else {
          print('❌ 현재 사용자 이름을 가져올 수 없음');
        }
      } else {
        print('📋 채팅방 ${chatItem.roomId}에 이벤트 로그 없음');
      }
    } catch (e) {
      print('❌ 채팅방 ${chatItem.roomId} 이벤트 로그 조회 오류: $e');
      print('❌ 오류 상세: ${e.toString()}');

      // 403/404 오류인 경우 (접근 권한 없음) 나간 것으로 간주
      if (e.toString().contains('403') || e.toString().contains('404')) {
        print('🚪 채팅방 ${chatItem.roomId} 접근 불가 (나간 것으로 추정) - 목록에서 제거');
        if (mounted) {
          setState(() {
            final beforeCount = _chatItems.length;
            _chatItems.removeWhere((item) => item.roomId == chatItem.roomId);
            final afterCount = _chatItems.length;
            print('🚪 권한 없음으로 목록에서 제거 완료: $beforeCount -> $afterCount');
          });
        }
      }
    }
  }

  // 서버 채팅방 목록과 비교하여 나간 채팅방 제거 (이벤트 로그 활용)
  Future<void> _checkAllRoomEventLogs() async {
    try {
      print('🔍 서버 채팅방 목록과 이벤트 로그 기반 검사 시작');

      // 현재 로컬 채팅방 ID 목록
      final localRoomIds = _chatItems.map((item) => item.roomId).toSet();
      print('🔍 로컬 채팅방 ID: $localRoomIds');

      // 서버에서 최신 채팅방 목록 가져오기
      final serverChatRooms = await ChatService.getChatRoomList();

      if (serverChatRooms != null) {
        // 서버 채팅방 ID 목록
        final serverRoomIds =
            serverChatRooms.map((room) => room['roomId'] as int).toSet();
        print('🔍 서버 채팅방 ID: $serverRoomIds');

        // 1차: 서버에 없는 채팅방 감지
        final removedByServer = localRoomIds.difference(serverRoomIds);
        print('🚪 서버에서 제거된 채팅방 ID: $removedByServer');

        // 2차: 이벤트 로그로 나가기 이벤트 확인
        final removedByEventLog = <int>{};

        print('📜 각 채팅방의 이벤트 로그 확인 시작...');
        for (final roomId in localRoomIds) {
          try {
            print('📜 채팅방 $roomId 이벤트 로그 조회 중...');

            // 이벤트 로그 조회 (최근 50개 이벤트 확인)
            final eventLogs = await ChatService.getChatEventLogs(
              roomId,
              isOnlyOnePage: true,
            );

            if (eventLogs != null && eventLogs.isNotEmpty) {
              print('📜 채팅방 $roomId 이벤트 로그 ${eventLogs.length}개 조회됨');

              // 현재 사용자 정보 가져오기
              final userInfo = await AuthService.getUserInfo();
              final currentUserName = userInfo?['name'] ?? '';

              // 나가기 이벤트 패턴 확인
              for (final log in eventLogs) {
                final message = log['message']?.toString() ?? '';
                final timestamp = log['timestamp']?.toString() ?? '';

                print('📜 이벤트 로그: "$message" at $timestamp');

                // 나가기 패턴 감지 (다양한 패턴 지원)
                final leavePatterns = [
                  '${currentUserName}님이 나갔습니다',
                  '${currentUserName}님이 채팅방을 나갔습니다',
                  '${currentUserName} left',
                  '${currentUserName} 나갔습니다',
                  '나갔습니다',
                  'left the room',
                  '퇴장',
                  '떠났습니다',
                ];

                bool isLeaveEvent = false;
                for (final pattern in leavePatterns) {
                  if (message.toLowerCase().contains(pattern.toLowerCase())) {
                    isLeaveEvent = true;
                    print('✅ 나가기 이벤트 감지됨: "$message" (패턴: "$pattern")');
                    break;
                  }
                }

                if (isLeaveEvent) {
                  removedByEventLog.add(roomId);
                  print('🚪 이벤트 로그로 나간 채팅방 감지: $roomId');
                  break; // 해당 채팅방에서 나가기 이벤트 발견하면 더 확인할 필요 없음
                }
              }
            } else {
              print('📜 채팅방 $roomId 이벤트 로그 없음 또는 조회 실패');
            }
          } catch (e) {
            print('❌ 채팅방 $roomId 이벤트 로그 조회 중 오류: $e');

            // 403/404 오류는 접근 권한이 없다는 뜻이므로 나간 것으로 간주
            if (e.toString().contains('403') || e.toString().contains('404')) {
              print('🚪 HTTP 오류로 나간 채팅방 감지: $roomId (오류: $e)');
              removedByEventLog.add(roomId);
            }
          }

          // API 과부하 방지를 위한 짧은 지연
          await Future.delayed(const Duration(milliseconds: 200));
        }

        // 최종 제거할 채팅방 = 서버에서 제거된 것 + 이벤트 로그로 감지된 것
        final totalRemovedRoomIds = removedByServer.union(removedByEventLog);
        print('🚪 최종 나간 채팅방 ID: $totalRemovedRoomIds');
        print('  - 서버에서 제거: $removedByServer');
        print('  - 이벤트 로그로 감지: $removedByEventLog');

        if (totalRemovedRoomIds.isNotEmpty && mounted) {
          setState(() {
            final beforeCount = _chatItems.length;
            _chatItems.removeWhere(
              (item) => totalRemovedRoomIds.contains(item.roomId),
            );
            final afterCount = _chatItems.length;
            print('🚪 나간 채팅방 제거 완료: $beforeCount -> $afterCount');
            print('🚪 제거된 채팅방: $totalRemovedRoomIds');

            // 성공 메시지 표시
            if (totalRemovedRoomIds.isNotEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '나간 채팅방 ${totalRemovedRoomIds.length}개가 목록에서 제거되었습니다.',
                  ),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 2),
                ),
              );
            }
          });
        } else {
          print('📋 제거할 채팅방 없음 - 목록 유지');
        }
      } else {
        print('❌ 서버 채팅방 목록 조회 실패');
      }

      print('📋 서버 채팅방 목록 및 이벤트 로그 비교 완료');
    } catch (e) {
      print('❌ 서버 채팅방 목록 비교 중 오류: $e');
      print('❌ 오류 스택 트레이스: ${e.toString()}');
    }
  }

  // 채팅방 나가기 알림 구독
  Future<void> _subscribeToRoomLeaveNotifications() async {
    try {
      print('=== 🚪 채팅방 나가기 알림 구독 시작 ===');

      // 현재 로드된 모든 채팅방에 대해 나가기 알림 구독
      for (final chatItem in _chatItems) {
        await ChatService.subscribeToRoomLeave(
          chatItem.roomId,
          _handleRoomLeaveReceived,
        );
        print('🚪 채팅방 ${chatItem.roomId} 나가기 알림 구독 완료');
      }

      print('✅ 모든 채팅방 나가기 알림 구독 완료: ${_chatItems.length}개');
    } catch (e) {
      print('❌ 채팅방 나가기 알림 구독 중 오류: $e');
    }
  }

  // 채팅 목록 로드 (mounted 체크 강화)
  Future<void> _loadChatList() async {
    if (!mounted) {
      return;
    }

    await _loadLeftRoomsList();
    await _autoDetectLeftRooms();

    // 로딩 상태 시작
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      // 현재 사용자 정보 가져오기
      String? currentUserName;
      try {
        final userInfo = await AuthService.getUserInfo();
        currentUserName = userInfo['name'];
      } catch (e) {
        currentUserName = null;
      }

      if (!mounted) {
        return;
      }

      final chatRooms = await ChatService.getChatRoomList();

      if (!mounted) {
        return;
      }

      if (chatRooms != null) {
        // API 응답을 ChatItem으로 변환
        final List<ChatItem> chatItems =
            chatRooms
                .map((room) {
                  // 채팅방 범위 확인
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
                  } else if (participantNames.isNotEmpty && currentUserName != null) {
                    // 커스텀 이름이 없으면 참여자 이름 로직 사용
                    final otherParticipants = participantNames
                        .where((name) => name.toString() != currentUserName)
                        .toList();

                    if (otherParticipants.isNotEmpty) {
                      // 다른 참여자가 있으면 그 이름 사용
                      displayName = otherParticipants.first.toString();
                    } else {
                      // 혼자만 있는 경우 - roomName 또는 기본 이름 사용
                      displayName = roomName.isNotEmpty ? roomName : '나간 채팅방';
                    }
                  } else if (participantNames.isEmpty) {
                    // 참여자가 없는 경우
                    displayName = roomName.isNotEmpty ? roomName : '나간 채팅방';
                  } else {
                    // participantNames가 있지만 currentUserName이 null인 경우
                    displayName = roomName.isNotEmpty ? roomName : '알 수 없는 채팅방';
                  }

                    // 1:1 채팅의 경우 친구 목록에서 프로필 이미지 찾기
                    bool friendFound = false;
                    for (final friendProfile in _friendProfiles) {
                      final friendName =
                          friendProfile['name']?.toString() ?? '';

                      if (friendName == displayName) {
                        profileImageUrl =
                            friendProfile['profileImageUrl']?.toString();
                        otherUserId = friendProfile['userId'];
                        friendFound = true;
                        break;
                      }
                    }

                    if (!friendFound) {
                      otherUserId = 0;
                    }
                  }

                  // 기본 프로필 이미지 설정 (1:1 채팅이고 프로필 이미지가 없는 경우)
                  if (roomRange == 'PRIVATE' &&
                      (profileImageUrl == null || profileImageUrl.isEmpty)) {
                    print('프로필 이미지를 찾을 수 없음: $displayName');
                    // 기본 이미지 URL 설정
                    profileImageUrl =
                        'https://littlebank-dev.s3.ap-northeast-2.amazonaws.com/images/origin/defailt/%E1%84%80%E1%85%B5%E1%84%87%E1%85%A9%E1%86%AB%E1%84%8B%E1%85%B5%E1%84%86%E1%85%B5%E1%84%8C%E1%85%B5.png';
                  }

                  // displayIdx를 시간 형식으로 변환
                  String timeText = '방금 전';
                  final displayIdx = room['displayIdx'];
                  if (displayIdx != null) {
                    try {
                      // UTC 시간을 파싱하고 한국 시간(KST)으로 변환
                      final utcDateTime =
                          DateTime.parse(displayIdx.toString()).toUtc();
                      final kstDateTime = utcDateTime.add(
                        Duration(hours: 9),
                      ); // UTC + 9시간 = KST
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
                      print('날짜 파싱 오류: $e');
                      timeText = '방금 전';
                    }
                  }

                  // 아바타는 프로필 이미지가 있으면 URL, 없으면 이름의 첫 글자
                  String avatar = '?';
                  if (displayName.isNotEmpty) {
                    avatar = displayName.substring(0, 1);
                  }

                  // 읽지 않은 메시지 수 처리 (새로운 API 명세 적용)
                  int unreadCount = room['unreadMessageCount'] as int? ?? 0;

                  // 1:1 채팅에서 차단된 상태라면 unreadMessageCount는 항상 0
                  if (roomRange == 'PRIVATE') {
                    // 친구 목록에서 차단 상태 확인
                    for (final friendProfile in _friendProfiles) {
                      final friendName =
                          friendProfile['name']?.toString() ?? '';
                      if (friendName == displayName) {
                        // 차단 상태 확인 (추후 친구 API에서 차단 정보 제공 시 사용)
                        // 현재는 서버에서 이미 차단된 경우 0으로 응답해주므로 그대로 사용
                        break;
                      }
                    }
                  }

                  print(
                    '채팅방 읽지 않은 메시지 수: $unreadCount (원본: ${room['unreadMessageCount']})',
                  );

                  // 그룹 채팅의 경우 참여자 정보 구성
                  List<Map<String, dynamic>>? participantsList;
                  if (roomRange == 'GROUP') {
                    participantsList =
                        participantNames.map((name) {
                          // 친구 목록에서 참여자 정보 찾기
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
                                friendInfo?['name']?.toString() ??
                                name.toString(),
                            'userId': friendInfo?['userId'] ?? 0,
                            'profileImageUrl':
                                friendInfo?['profileImageUrl']?.toString() ??
                                '',
                          };
                        }).toList();
                  }

                  // 최근 메시지 가져오기 (비동기 처리를 위해 임시로 기본값 설정)
                  String recentMessage =
                      roomRange == 'GROUP'
                          ? '그룹 채팅방이 생성되었습니다.'
                          : '새로운 채팅방이 생성되었습니다.';

                  // Future로 최근 메시지를 가져오고 나중에 업데이트할 예정
                  // 일단 기본 ChatItem을 생성하고, 이후에 최근 메시지로 업데이트
                  final chatItem = ChatItem(
                    name: displayName,
                    avatar: avatar,
                    message: recentMessage,
                    time: timeText,
                    count: unreadCount, // 실제 읽지 않은 메시지 수 사용
                    userId: otherUserId ?? 0,
                    roomId: room['roomId'] ?? 0,
                    isBlocked: false,
                    profileImageUrl: profileImageUrl,
                    isGroupChat: roomRange == 'GROUP',
                    participants: participantsList,
                  );

                  // 최근 메시지 비동기로 가져오기
                  _loadRecentMessage(chatItem);

                  print('✅ 채팅방 변환 완료:');
                  print('  - roomId: ${chatItem.roomId}');
                  print('  - 타입: ${chatItem.isGroupChat ? "그룹" : "1:1"}');
                  print('  - 표시 이름: "${chatItem.name}"');
                  print('  - 상대방 ID: ${chatItem.userId}');
                  print('  - 읽지 않은 수: ${chatItem.count}');

                  return chatItem;
                })
                .where((item) => item != null) // null 항목 제거
                .where((item) {
                  if (item == null) return false;

                  print('🔍 채팅방 ${item.roomId}(${item.name}) 필터링 검사 중...');
                  final isLeft = _isLeftRoom(item.roomId);
                  print('🔍 필터링 결과: ${isLeft ? "제외됨" : "포함됨"}');

                  if (isLeft) {
                    print('🚫 채팅방 ${item.roomId}(${item.name})는 나간 채팅방으로 필터링됨');
                  }
                  return !isLeft;
                }) // 나간 채팅방 제외 (실제 나간 roomId 기반)
                .cast<ChatItem>() // List<ChatItem?>을 List<ChatItem>으로 변환
                .toList();

        // 채팅방을 최신 메시지 순으로 정렬 (실시간 업데이트를 위해 클라이언트에서 정렬)
        // 나중에 _loadRecentMessage에서 업데이트되면 다시 정렬될 것임

        if (mounted) {
          setState(() {
            _chatItems = chatItems;
            _isLoading = false;
          });

          // 초기 로드 완료 후 정렬 (최근 메시지 로드 전 기본 정렬)
          _sortChatItemsByLatestMessage();

          print('✅ 채팅 목록 로드 완료: ${chatItems.length}개');
          print('🚪 현재 나간 채팅방 목록: $_leftRoomIds');
          if (_leftRoomIds.isNotEmpty) {
            print('🚪 나간 채팅방 ${_leftRoomIds.length}개가 목록에서 제외됨');
          }
          print('📊 필터링 결과: 총 채팅방에서 ${chatItems.length}개만 표시됨');

          // 각 채팅방 정보 출력
          print('📋 최종 표시될 채팅방 목록:');
          for (int i = 0; i < chatItems.length; i++) {
            final item = chatItems[i];
            print(
              '  [$i] ${item.isGroupChat ? "그룹" : "1:1"} - ${item.name} (roomId: ${item.roomId})',
            );
          }

          // 서버에서 나가기가 반영되었는지 확인하기 위해 이벤트 로그 체크
          print('📋 서버 채팅방 목록 비교 시작... (총 ${chatItems.length}개)');
          _checkAllRoomEventLogs();
        } else {
          print('❌ setState 호출 전 위젯 dispose됨');
        }
      } else {
        print('채팅방 목록이 null임');
        if (mounted) {
          setState(() {
            _chatItems = [];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('채팅 목록 로드 중 오류 발생: $e');
      if (mounted) {
        setState(() {
          _chatItems = [];
          _isLoading = false;
        });
      }
    }

    print('===== 채팅 목록 로드 종료 =====');
  }

  // 검색 모드 활성화
  void _activateSearchMode() {
    setState(() {
      _isSearchMode = true;
      _filteredChatItems = List.from(_chatItems);
    });
    
    // 검색 필드에 포커스
    Future.delayed(const Duration(milliseconds: 100), () {
      _searchFocusNode.requestFocus();
    });
  }

  // 검색 취소
  void _cancelSearch() {
    setState(() {
      _isSearchMode = false;
      _searchQuery = '';
      _searchController.clear();
      _filteredChatItems.clear();
    });
    _searchFocusNode.unfocus();
  }

  // 채팅 목록 필터링
  void _filterChatItems(String query) {
    setState(() {
      _searchQuery = query;
      
      if (query.isEmpty) {
        _filteredChatItems = List.from(_chatItems);
      } else {
        _filteredChatItems = _chatItems.where((item) {
          // 채팅방 이름으로 검색
          final nameMatch = item.name.toLowerCase().contains(query.toLowerCase());
          
          // 그룹 채팅인 경우 참여자 이름으로도 검색
          bool participantMatch = false;
          if (item.isGroupChat && item.participants != null) {
            participantMatch = item.participants!.any((participant) {
              final participantName = participant['name']?.toString() ?? '';
              return participantName.toLowerCase().contains(query.toLowerCase());
            });
          }
          
          // 최근 메시지 내용으로도 검색
          final messageMatch = item.message.toLowerCase().contains(query.toLowerCase());
          
          return nameMatch || participantMatch || messageMatch;
        }).toList();
      }
    });
  }

  // 최근 메시지 로드 (각 채팅방별로 비동기 처리)
  Future<void> _loadRecentMessage(ChatItem chatItem) async {
    try {
      print('📥 채팅방 ${chatItem.roomId}의 최신 메시지 조회 시작');

      // 해당 채팅방의 최근 메시지를 가져오기 (더 큰 lastMessageId 사용)
      final messages = await ChatService.getChatRoomMessages(
        chatItem.roomId,
        lastMessageId: 999999999, // 더 큰 값으로 최신 메시지부터 가져오기
        pageNumber: 0,
      );

      if (messages.isNotEmpty && mounted) {
        // messageId 기준으로 내림차순 정렬하여 진짜 최신 메시지 찾기
        messages.sort((a, b) {
          final aId = a.messageId ?? 0;
          final bId = b.messageId ?? 0;
          return bId.compareTo(aId); // 내림차순 (최신이 맨 앞)
        });

        final recentMessage = messages.first; // 정렬 후 첫 번째가 가장 최신
        print(
          '📥 채팅방 ${chatItem.roomId} 최신 메시지: ID=${recentMessage.messageId}, 내용="${recentMessage.content}", 타입=${recentMessage.messageType}',
        );

        String displayMessage = '';

        // 메시지 타입에 따른 표시 텍스트 설정
        final messageTypeString =
            recentMessage.messageType?.toString() ?? 'TEXT';

        switch (messageTypeString.toUpperCase()) {
          case 'TEXT':
            displayMessage = recentMessage.content ?? '';
            break;
          case 'IMAGE':
            displayMessage = '📷 사진을 보냈습니다';
            break;
          case 'VIDEO':
            displayMessage = '🎥 동영상을 보냈습니다';
            break;
          case 'FILE':
            displayMessage = '📎 파일을 보냈습니다';
            break;
          case 'MISSION_CARD':
            displayMessage = '🎯 미션 카드를 보냈습니다';
            break;
          default:
            displayMessage = recentMessage.content ?? '';
        }

        // 시스템 메시지인 경우 (senderUserId가 0)
        if (recentMessage.senderUserId == 0) {
          displayMessage = recentMessage.content ?? '';
        }

        // 빈 메시지인 경우 기본 메시지 사용
        if (displayMessage.trim().isEmpty) {
          displayMessage =
              chatItem.isGroupChat ? '그룹 채팅방이 생성되었습니다.' : '새로운 채팅방이 생성되었습니다.';
        }

        // 메시지가 너무 길면 자르기
        if (displayMessage.length > 30) {
          displayMessage = '${displayMessage.substring(0, 30)}...';
        }

        print('📥 채팅방 ${chatItem.roomId} 표시할 메시지: "$displayMessage"');

        // 해당 채팅방 아이템 찾아서 메시지 업데이트
        if (mounted) {
          setState(() {
            final index = _chatItems.indexWhere(
              (item) => item.roomId == chatItem.roomId,
            );
            if (index != -1) {
              _chatItems[index] = ChatItem(
                name: _chatItems[index].name,
                avatar: _chatItems[index].avatar,
                message: displayMessage,
                time: _chatItems[index].time,
                count: _chatItems[index].count,
                userId: _chatItems[index].userId,
                roomId: _chatItems[index].roomId,
                isBlocked: _chatItems[index].isBlocked,
                profileImageUrl: _chatItems[index].profileImageUrl,
                isGroupChat: _chatItems[index].isGroupChat,
                participants: _chatItems[index].participants,
              );
              print('✅ 채팅방 ${chatItem.roomId} 목록 업데이트 완료: "$displayMessage"');
            }

            // 최신 메시지로 업데이트 후 목록 다시 정렬
            _sortChatItemsByLatestMessage();
          });
        }
      } else {
        print('📥 채팅방 ${chatItem.roomId}에 메시지가 없음');
      }
    } catch (e) {
      print('❌ 최근 메시지 로드 실패 (채팅방 ID: ${chatItem.roomId}): $e');
      // 실패해도 기본 메시지 유지
    }
  }

  // 검색 기능은 SearchHistoryScreen으로 이동됨

  // 채팅방 목록을 최신 메시지 순으로 정렬
  void _sortChatItemsByLatestMessage() {
    if (_chatItems.isEmpty) return;

    _chatItems.sort((a, b) {
      // 1. 읽지 않은 메시지가 있는 채팅방을 우선
      if (a.count > 0 && b.count == 0) return -1;
      if (a.count == 0 && b.count > 0) return 1;

      // 2. 시간 텍스트로 비교 (방금 전이 가장 우선)
      if (a.time == '방금 전' && b.time != '방금 전') return -1;
      if (a.time != '방금 전' && b.time == '방금 전') return 1;

      // 3. 분 단위 비교
      final aMinutes = _parseTimeToMinutes(a.time);
      final bMinutes = _parseTimeToMinutes(b.time);

      return aMinutes.compareTo(bMinutes);
    });
  }

  // 시간 텍스트를 분 단위로 변환 (정렬용)
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

    return 999999; // 파싱 실패 시 가장 뒤로
  }

  // 친구 목록 로드
  Future<void> _loadFriendList() async {
    print('=== 👫 친구 목록 로드 시작 ===');
    setState(() {
      _isLoadingFriends = true;
    });

    try {
      // 친구 목록 조회 API 호출
      final result = await RelationshipService.getFriendList();
      print('👫 친구 목록 API 응답: $result');

      if (result != null && mounted) {
        final List<dynamic> friends = result;
        print('👫 조회된 친구 수: ${friends.length}개');

        // 친구 프로필 변환
        final profiles =
            friends.map((friend) {
              final userInfo = friend['userInfo'] ?? {};
              int userId = 0;
              int friendId = friend['friendId'] ?? 0;

              // 서버 응답에서는 userId가 userInfo 안에 있고, friendId는 별도로 있음
              // 사용자 ID는 항상 userInfo의 userId를 우선적으로 사용
              if (userInfo.containsKey('userId') &&
                  userInfo['userId'] != null) {
                userId = userInfo['userId']; // 이것이 실제 사용자 ID
              } else {
                userId = friendId; // 차선책으로 friendId 사용
              }

              final customName =
                  friend['customName'] ?? userInfo['userName'] ?? '이름 없음';

              print('👫 친구 정보 변환:');
              print('  - customName: ${friend['customName']}');
              print('  - userName: ${userInfo['userName']}');
              print('  - 최종 이름: $customName');
              print('  - userId: $userId');
              print('  - friendId: $friendId');
              print('  - profileImagePath: ${userInfo['profileImagePath']}');

              final profileImagePath = userInfo['profileImagePath'];
              String profileImageUrl = '';

              if (profileImagePath != null &&
                  profileImagePath.toString().isNotEmpty) {
                if (profileImagePath.toString().startsWith('http')) {
                  // 이미 완전한 URL(카카오 등)인 경우 그대로 사용
                  profileImageUrl = profileImagePath.toString();
                } else if (profileImagePath.toString().startsWith('images/')) {
                  // 서버 이미지 경로인 경우 S3 URL로 변환
                  profileImageUrl =
                      'https://littlebank-dev.s3.ap-northeast-2.amazonaws.com/$profileImagePath';
                }
              }

              print('  - 변환된 프로필 이미지 URL: $profileImageUrl');

              return {
                'name': customName,
                'avatar': customName.isNotEmpty ? customName[0] : '?',
                'userId': userId,
                'friendId': friendId,
                'profileImageUrl': profileImageUrl,
                'phone': userInfo['phone']?.toString() ?? '',
              };
            }).toList();

        print('👫 최종 친구 프로필 목록:');
        for (int i = 0; i < profiles.length; i++) {
          final profile = profiles[i];
          print('  [$i] "${profile['name']}" (ID: ${profile['userId']})');
        }

        setState(() {
          _friendProfiles = profiles;
          _isLoadingFriends = false;
        });

        print('✅ 친구 목록 로드 완료: ${profiles.length}개');
      } else {
        print('⚠️ 친구 목록 API 응답이 null이거나 위젯이 dispose됨');
        setState(() {
          _friendProfiles = [];
          _isLoadingFriends = false;
        });
      }
    } catch (e) {
      print('❌ 친구 목록 로드 중 오류 발생: $e');
      setState(() {
        _friendProfiles = [];
        _isLoadingFriends = false;
      });
    }

    print('=== 👫 친구 목록 로드 종료 ===');
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
            maxHeight: screenHeight * 0.4, // 화면 높이의 40%로 줄임
            minHeight: 250, // 최소 높이 줄임
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 헤더 섹션
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12), // 16 -> 12
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
                    // 제목과 닫기 버튼
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '누구에게 채팅을 보낼까요?',
                          style: TextStyle(
                            color: const Color(0xFF202020),
                            fontSize: 16, // 18 -> 16
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
                    const SizedBox(height: 6), // 8 -> 6
                    Text(
                      '인원 수에 따라 채팅 전송 유형을 선택할 수 있어요',
                      style: TextStyle(
                        color: const Color(0xFF999999),
                        fontSize: 12, // 14 -> 12
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
                  padding: const EdgeInsets.all(12), // 16 -> 12
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
                          ), // 20->16, 16->12
                          decoration: ShapeDecoration(
                            color: const Color(0xFFFFD27F),
                            shape: RoundedRectangleBorder(
                              side: BorderSide(
                                width: 0.70,
                                color: const Color(0xFFFFA63D),
                              ),
                              borderRadius: BorderRadius.circular(
                                10,
                              ), // 12 -> 10
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
                                        fontSize: 14, // 16 -> 14
                                        fontFamily: 'Pretendard-Bold',
                                        letterSpacing: -0.28,
                                      ),
                                    ),
                                    const SizedBox(height: 6), // 8 -> 6
                                    Text(
                                      '상대와 나의 개인 채팅창을 통해 대화할 수 있어요!',
                                      style: TextStyle(
                                        color: const Color(0xFF666666),
                                        fontSize: 10, // 12 -> 10
                                        fontFamily: 'Pretendard-Light',
                                        letterSpacing: -0.20,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: 18, // 20 -> 18
                                height: 18,
                                decoration: ShapeDecoration(
                                  color: const Color(0xFFFFD27F),
                                  shape: OvalBorder(
                                    side: BorderSide(
                                      width: 0.75,
                                      color: const Color(0xFFFFA63D),
                                    ),
                                  ),
                                ),
                                child: Center(
                                  child: Container(
                                    width: 10, // 12 -> 10
                                    height: 10,
                                    decoration: ShapeDecoration(
                                      color: const Color(0xFFFFA63D),
                                      shape: OvalBorder(),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 12), // 16 -> 12
                      // 그룹 채팅 옵션
                      GestureDetector(
                        onTap: _showGroupChatCreation,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ), // 20->16, 16->12
                          decoration: ShapeDecoration(
                            color: const Color(0xFFE4ECF8),
                            shape: RoundedRectangleBorder(
                              side: BorderSide(
                                width: 0.70,
                                color: const Color(0xFFDADADA),
                              ),
                              borderRadius: BorderRadius.circular(
                                10,
                              ), // 12 -> 10
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
                                        fontSize: 14, // 16 -> 14
                                        fontFamily: 'Pretendard-Bold',
                                        letterSpacing: -0.28,
                                      ),
                                    ),
                                    const SizedBox(height: 6), // 8 -> 6
                                    Text(
                                      '여러 명에게 한 번에 빠르게 채팅을 전송할 수 있어요!',
                                      style: TextStyle(
                                        color: const Color(0xFF999999),
                                        fontSize: 10, // 12 -> 10
                                        fontFamily: 'Pretendard-Light',
                                        letterSpacing: -0.20,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: 18, // 20 -> 18
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

                      const SizedBox(height: 16), // 24 -> 16
                      // 완료 버튼
                      GestureDetector(
                        onTap: _showFriendSelectionForPrivateChat,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12), // 16 -> 12
                          decoration: ShapeDecoration(
                            color: const Color(0xFF5D9EFF),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '완료',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12, // 14 -> 12
                                fontFamily: 'Pretendard-Light',
                                letterSpacing: -0.24,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // 하단 여백 (안전 영역)
                      SizedBox(
                        height: MediaQuery.of(context).padding.bottom + 12,
                      ), // 16 -> 12
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

  // 1:1 채팅을 위한 친구 선택 (간단하게 수정)
  void _showFriendSelectionForPrivateChat() {
    Navigator.pop(context); // 현재 다이얼로그 닫기

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

  // 그룹 채팅 생성 (새로운 모달 호출)
  void _showGroupChatCreation() {
    Navigator.pop(context); // 현재 다이얼로그 닫기

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

  // 그룹 채팅방 생성 실행 (새로운 화면으로 이동)
  Future<void> _createGroupChatRoom(List<int> selectedUserIds) async {
    print('===== 그룹 채팅방 생성 시작 =====');
    print('선택된 친구 사용자 IDs: $selectedUserIds');

    if (!mounted) return;

    try {
      // 로딩 표시
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => const Center(
              child: CircularProgressIndicator(color: Color(0xFF4A80F0)),
            ),
      );

      // 현재 사용자 ID 가져오기
      final userInfo = await AuthService.getUserInfo();
      final myUserId = userInfo['userId'] as int;

      // 선택된 친구들 정보 가져오기
      final selectedFriends =
          _friendProfiles.where((friend) {
            return selectedUserIds.contains(friend['userId']);
          }).toList();

      // 그룹 이름 생성 (참여자 이름들로)
      final groupName = selectedFriends
          .map((friend) => friend['name'])
          .join(', ');

      // 참여자 목록 (나 + 선택된 친구들)
      final participants = <Map<String, dynamic>>[];

      // 내 정보 추가
      participants.add({
        'userId': myUserId,
        'name': userInfo['name'] ?? '나',
        'profileImageUrl': userInfo['profileImagePath'] ?? '',
      });

      // 선택된 친구들 정보 추가
      participants.addAll(selectedFriends);

      // 실제 그룹 채팅방 생성 API 호출
      print('그룹 채팅방 생성 API 호출 시작...');
      print('그룹 이름: $groupName');
      print('참여자 ID 목록: ${[myUserId, ...selectedUserIds]}');

      final result = await ChatService.createGroupChatRoom(
        roomName: groupName,
        participantIds: [myUserId, ...selectedUserIds],
      );

      if (!mounted) return;

      // 안전하게 로딩 다이얼로그 닫기
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      // API 호출 결과 상세 로그
      print('📝 그룹 채팅방 생성 API 응답: $result');

      // API 호출 결과 확인
      if (result == null || result['error'] == true) {
        print('❌ 그룹 채팅방 생성 실패: ${result?['message']}');
        if (mounted) {
          // 실패해도 목록 새로고침 시도
          print('🔄 실패 후에도 목록 새로고침 시도');
          _loadChatList();
          _showErrorDialog('오류', result?['message'] ?? '그룹 채팅방 생성에 실패했습니다.');
        }
        return;
      }

      final roomId = result['roomId'];
      print('✅ 그룹 채팅방 생성 성공: $roomId');

      // 즉시 채팅 목록 새로고침 (생성 직후)
      print('🔄 채팅방 생성 직후 목록 새로고침');
      if (mounted) {
        await _loadChatList();
        // 서버 동기화를 위한 짧은 대기
        await Future.delayed(const Duration(milliseconds: 500));
      }

      // 그룹 채팅 화면으로 이동
      await Navigator.push(
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

      // 그룹 채팅에서 돌아온 후 채팅 목록 새로고침 (추가 보장)
      print('🔄 그룹 채팅에서 돌아옴 - 목록 재새로고침');
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

  // 1:1 채팅방 생성 실행 (뒤로가기 후 목록 새로고침 추가)
  Future<void> _createPrivateChatRoom(int friendUserId) async {
    print('===== 1:1 채팅방 찾기/생성 시작 =====');
    print('선택된 친구 사용자 ID: $friendUserId');

    // 친구 정보 미리 찾기
    final selectedFriend = _friendProfiles.firstWhere(
      (friend) => friend['userId'] == friendUserId,
      orElse: () => {},
    );

    // 안전하게 모달 닫기
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }

    if (!mounted) return;

    try {
      // 로딩 표시
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => const Center(
              child: CircularProgressIndicator(color: Color(0xFF4A80F0)),
            ),
      );

      // 현재 사용자 ID 가져오기
      final userInfo = await AuthService.getUserInfo();
      final myUserId = userInfo['userId'] as int;

      // 🔒 사용자 ID 안전성 검증 (이름과 무관한 ID 기반 처리)
      print('🔒 사용자 ID 검증: myUserId=$myUserId, friendUserId=$friendUserId');

      if (myUserId <= 0 || friendUserId <= 0) {
        print('❌ 잘못된 사용자 ID 감지');
        if (mounted && Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        if (mounted) {
          _showErrorDialog('오류', '잘못된 사용자 정보입니다.');
        }
        return;
      }

      if (myUserId == friendUserId) {
        print('❌ 자기 자신과 채팅 시도 감지');
        if (mounted && Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        if (mounted) {
          _showErrorDialog('알림', '자기 자신과는 채팅할 수 없습니다.');
        }
        return;
      }

      print('✅ 사용자 ID 검증 완료 - 안전하게 진행');

      // 🔒 이름과 무관한 ID 기반 채팅방 생성
      final result = await ChatService.findOrCreatePrivateChatRoom(
        friendUserId: friendUserId,
        myUserId: myUserId,
      );

      if (!mounted) return;

      // 안전하게 로딩 다이얼로그 닫기
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      // API 호출 결과 상세 로그
      print('📝 1:1 채팅방 처리 API 응답: $result');

      if (result != null && result['error'] != true) {
        final roomId = result['roomId'];
        print('✅ 채팅방 처리 완료: $roomId');

        // 즉시 채팅 목록 새로고침 (생성/찾기 직후)
        print('🔄 채팅방 처리 직후 목록 새로고침');
        if (mounted) {
          await _loadChatList();
          // 서버 동기화를 위한 짧은 대기
          await Future.delayed(const Duration(milliseconds: 500));
        }

        // 채팅방으로 이동하고 돌아올 때까지 기다림
        if (mounted && selectedFriend.isNotEmpty) {
          final result = await Navigator.push<Map<String, dynamic>>(
            context,
            MaterialPageRoute(
              builder:
                  (context) => ChatDetailScreen(
                    userName: selectedFriend['name'] ?? '채팅',
                    avatar: selectedFriend['profileImageUrl'] ?? '',
                    roomId: roomId,
                    userId: friendUserId,
                  ),
            ),
          );

          print('🔄 채팅방에서 돌아온 결과: $result');

          // ✅ 나가기 결과 처리: 즉시 SharedPreferences에 저장
          if (result != null && result['action'] == 'leave_room') {
            final leftRoomId = result['roomId'] as int;
            print('🚪 나가기 감지됨 - roomId: $leftRoomId');

            // 즉시 나간 채팅방으로 기록
            await _addToLeftRoomsList(leftRoomId);
            print('✅ 나간 채팅방으로 즉시 기록 완료');
          }

          // 채팅방에서 돌아온 후 채팅 목록 새로고침 (추가 보장)
          print('🔄 채팅방에서 돌아옴 - 목록 재새로고침');
          if (mounted) {
            await _loadChatList();
          }
        }
      } else {
        print('❌ 채팅방 찾기/생성 실패: ${result?['message']}');
        if (mounted) {
          // 실패해도 목록 새로고침 시도
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
                    color: Color(0xFF4A80F0),
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
                    color: Color(0xFF4A80F0),
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
            // 친구 추가 성공 시 친구 목록 새로고침
            _loadFriendList();
          },
        );
      },
    );
  }

  // 검색 결과 빌드
  Widget _buildSearchResults() {
    if (_searchQuery.isEmpty) {
      return ListView.builder(
        itemCount: _chatItems.length,
        itemBuilder: (context, index) {
          return _buildNewChatItem(_chatItems[index]);
        },
      );
    }

    if (_filteredChatItems.isEmpty) {
      return ListView(
        children: [
          Container(
            height: 200,
            child: Center(
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
                    '검색 결과가 없습니다',
                    style: TextStyle(
                      color: const Color(0xFF999999),
                      fontSize: 14,
                      fontFamily: 'Pretendard-Regular',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '"$_searchQuery"와 일치하는 채팅방을 찾을 수 없습니다',
                    style: TextStyle(
                      color: const Color(0xFFCCCCCC),
                      fontSize: 12,
                      fontFamily: 'Pretendard-Light',
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      itemCount: _filteredChatItems.length,
      itemBuilder: (context, index) {
        return _buildNewChatItem(_filteredChatItems[index]);
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
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                decoration: ShapeDecoration(
                  color: const Color(0xffffffff),
                  shape: RoundedRectangleBorder(
                    side: BorderSide(
                      width: _isSearchMode ? 1.40 : 0.80,
                      color: _isSearchMode 
                          ? const Color(0xFF5D9EFF)
                          : const Color(0xFF5D6A7F),
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
                    const SizedBox(width: 6),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        decoration: InputDecoration(
                          hintText: '찾고싶은 채팅 상대를 검색해 주세요',
                          hintStyle: TextStyle(
                            color: const Color(0xFF999999),
                            fontSize: 12,
                            fontFamily: 'Pretendard-Light',
                            letterSpacing: -0.20,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 6),
                        ),
                        style: TextStyle(
                          color: const Color(0xFF202020),
                          fontSize: 13,
                          fontFamily: 'Pretendard-Light',
                          letterSpacing: -0.20,
                        ),
                        onTap: () {
                          if (!_isSearchMode) {
                            _activateSearchMode();
                          }
                        },
                        onChanged: _filterChatItems,
                      ),
                    ),
                    if (_isSearchMode && _searchQuery.isNotEmpty)
                      GestureDetector(
                        onTap: _cancelSearch,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            Icons.close,
                            size: 20,
                            color: const Color(0xFF999999),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // 최근 연락한 친구들 섹션
            ...[
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
                            color: Color(0xFF3A88F4),
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

            // 필터 섹션
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Align(
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

            // 채팅 목록 섹션 (당겨서 새로고침 지원)
            Expanded(
              child: RefreshIndicator(
                color: const Color(0xFF4A80F0),
                onRefresh: () async {
                  print('🔄 수동 새로고침 시작');
                  await _loadChatList();
                  print('✅ 수동 새로고침 완료');
                },
                child:
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _isSearchMode
                        ? _buildSearchResults()
                        : _chatItems.isEmpty
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
                          itemCount: _chatItems.length,
                          itemBuilder: (context, index) {
                            return _buildNewChatItem(_chatItems[index]);
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
              color: const Color(0xFF5D9EFF),
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
      bottomNavigationBar: const CommonBottomNavigationBar(selectedIndex: 1),
    );
  }

  // 새로운 디자인의 채팅 아이템 위젯
  Widget _buildNewChatItem(ChatItem item) {
    return InkWell(
      onTap: () {
        if (item.isGroupChat) {
          // 그룹 채팅인 경우 GroupChatScreen으로 이동
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => GroupChatScreen(
                    groupName: item.name,
                    participants: item.participants ?? [],
                    roomId: item.roomId,
                  ),
            ),
          ).then((result) async {
            // 그룹 채팅에서 돌아왔을 때 처리
            print('🔄 그룹 채팅에서 돌아옴 - 결과: $result');

            // 채팅방 이름 변경 결과 처리
            if (result is Map<String, dynamic> &&
                result['action'] == 'update_room_name') {
              final roomId = result['roomId'] as int?;
              final newName = result['newName'] as String?;
              final success = result['success'] as bool? ?? false;

              if (success && roomId != null && newName != null) {
                print('✅ 채팅방 $roomId 이름 변경됨: $newName');
                
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
                    print('✅ 채팅 목록에서 채팅방 $roomId 이름 업데이트 완료: $newName');
                  }
                });
                return; // 이름 변경인 경우 추가 새로고침 생략
              }
            }

            // 나가기 결과 처리
            if (result is Map<String, dynamic> &&
                result['action'] == 'leave_room') {
              final leftRoomId = result['roomId'] as int?;
              final success = result['success'] as bool? ?? false;
              final error = result['error'] as String?;

              if (leftRoomId != null) {
                print('🚪 채팅방 $leftRoomId 나가기 처리 완료 - 성공: $success');

                // 나간 채팅방 ID를 영구 저장 (성공/실패 관계없이)
                await _addToLeftRoomsList(leftRoomId);

                // UI에서 즉시 제거
                setState(() {
                  _chatItems.removeWhere(
                    (chatItem) => chatItem.roomId == leftRoomId,
                  );
                });

                // 사용자에게 결과 알림
                if (success) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('채팅방을 나갔습니다.'),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '나가기 요청을 전송했습니다. ${error != null ? '(오류: $error)' : ''}',
                        ),
                        backgroundColor: Colors.orange,
                        duration: Duration(seconds: 3),
                      ),
                    );
                  }
                }

                print('✅ 채팅방 $leftRoomId 목록에서 제거 및 나간 목록에 영구 저장');
                print('🚪 현재 나간 채팅방 목록: $_leftRoomIds');

                // 백그라운드에서 서버 동기화 확인
                _backgroundSyncAfterLeave(leftRoomId);

                // 나가기 처리된 경우 추가 새로고침은 하지 않음
                return;
              }
            }

            // 일반적인 경우에만 목록 새로고침 (읽음 처리 반영)
            print('🔄 그룹 채팅에서 돌아옴 - 목록 새로고침 (읽음 처리 반영)');
            _loadChatList();
          });
        } else {
          // 1:1 채팅인 경우 ChatDetailScreen으로 이동
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => ChatDetailScreen(
                    userName: item.name,
                    avatar: item.profileImageUrl ?? '',
                    roomId: item.roomId,
                    userId: item.userId,
                  ),
            ),
          ).then((result) async {
            // 채팅방에서 돌아왔을 때 처리
            print('🔄 채팅방에서 돌아옴 - 결과: $result');

            // 채팅방 이름 변경 결과 처리
            if (result is Map<String, dynamic> &&
                result['action'] == 'update_room_name') {
              final roomId = result['roomId'] as int?;
              final newName = result['newName'] as String?;
              final success = result['success'] as bool? ?? false;

              if (success && roomId != null && newName != null) {
                print('✅ 1:1 채팅방 $roomId 이름 변경됨: $newName');
                
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
                    print('✅ 채팅 목록에서 1:1 채팅방 $roomId 이름 업데이트 완료: $newName');
                  }
                });
                return; // 이름 변경인 경우 추가 새로고침 생략
              }
            }

            // 나가기 결과가 있는 경우 처리
            if (result is Map<String, dynamic> &&
                result['action'] == 'leave_room') {
              final leftRoomId = result['roomId'] as int?;
              final success = result['success'] as bool? ?? false;

              if (leftRoomId != null) {
                print('🚪 1:1 채팅방 $leftRoomId 나가기 처리 - 성공: $success');

                // ✅ SharedPreferences에 즉시 기록
                await _addToLeftRoomsList(leftRoomId);

                // 성공/실패 관계없이 UI에서 즉시 제거 (UX 개선)
                setState(() {
                  _chatItems.removeWhere(
                    (chatItem) => chatItem.roomId == leftRoomId,
                  );
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success ? '채팅방을 나갔습니다.' : '채팅방을 나갔습니다. (서버 동기화 중)',
                    ),
                    backgroundColor: success ? Colors.green : Colors.orange,
                    duration: Duration(seconds: 2),
                  ),
                );

                print('✅ 1:1 채팅방 $leftRoomId SharedPreferences 저장 + UI 제거 완료');

                // 백그라운드에서 서버 동기화 (UI 블로킹 방지)
                if (!success) {
                  _backgroundSyncAfterLeave(leftRoomId);
                }

                // 나가기 처리된 경우 추가 새로고침은 하지 않음
                return;
              }
            }

            // 일반적인 경우에만 목록 새로고침 (읽음 처리 반영 등)
            print('🔄 채팅방에서 돌아옴 - 목록 새로고침 (읽음 처리 반영)');
            _loadChatList();
          });
        }
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
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => ChatStartScreen(
                          userName: item.name,
                          userDescription: '',
                          userId: item.userId,
                          isBlocked: item.isBlocked,
                          initialProfileImageUrl: item.profileImageUrl,
                        ),
                  ),
                ).then((_) {
                  // 프로필에서 돌아왔을 때 목록 새로고침
                  print('🔄 프로필에서 돌아옴 - 목록 새로고침');
                  _loadChatList();
                });
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
                          color: const Color(0xFF4A80F0),
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
                          // 시간 표시
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

                          // 읽지 않은 메시지 수 표시 (시간 아래)
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
                                color: const Color(0xFFFFA63D),
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

  // 최근 연락한 친구 아바타 (새 디자인)
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
                (context) => ChatStartScreen(
                  userName: name,
                  userDescription: '',
                  userId: userId,
                  initialProfileImageUrl: profileImageUrl,
                ),
          ),
        ).then((_) {
          // 채팅 프로필에서 돌아왔을 때 목록 새로고침
          print('🔄 채팅 프로필에서 돌아옴 - 목록 새로고침');
          _loadChatList();
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
}

class ChatItem {
  final String name;
  final String message;
  final int count;
  final String avatar;
  final String time;
  final int userId;
  final int roomId;
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
    required this.userId,
    required this.roomId,
    this.isBlocked = false,
    this.profileImageUrl,
    this.isGroupChat = false,
    this.participants,
  });
}
