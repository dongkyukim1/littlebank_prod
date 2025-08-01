import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:async';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import '../../../../services/chat_service.dart';
import '../../../../services/auth_service.dart';
import '../../../../services/chat_background_service.dart';
import '../../../../models/chat_message.dart';
import '../friend_list_screen.dart';
import '../detail/chat_room_menu_screen.dart' as parent_menu;
import '../../../child/chat/detail/chat_room_menu_screen.dart' as child_menu;

class GroupChatScreen extends StatefulWidget {
  final String groupName;
  final List<Map<String, dynamic>> participants;
  final int roomId;

  const GroupChatScreen({
    super.key,
    required this.groupName,
    required this.participants,
    required this.roomId,
  });

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  int? _currentUserId;
  String? _backgroundImagePath;
  String? _userRole; // 사용자 역할 추가

  // 채팅방 정보
  String _roomName = '';
  int _participantCount = 0;

  // 검색 관련 변수들
  bool _isSearching = false;
  String _searchQuery = '';
  List<int> _searchResults = [];
  int _currentSearchIndex = -1;

  @override
  void initState() {
    super.initState();
    // 초기값 설정
    _roomName = widget.groupName;
    _participantCount = widget.participants.length;
    
    // 디버그: participants 데이터 확인
    print('=== 🔍 그룹 채팅 participants 데이터 확인 ===');
    print('그룹 이름: ${widget.groupName}');
    print('참여자 수: ${widget.participants.length}');
    for (int i = 0; i < widget.participants.length; i++) {
      final participant = widget.participants[i];
      print('참여자 $i - 전체 데이터: $participant');
      print('  - userId: ${participant['userId']}');
      print('  - name: ${participant['name']}');
      print('  - profileImageUrl: ${participant['profileImageUrl']}');
    }
    print('=========================================');
    
    _initializeChat();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _searchController.dispose();
    _scrollController.dispose();

    print('=== 🔌 그룹 채팅방 나가기 ===');
    print('채팅방 ID: ${widget.roomId}');
    ChatService.exitChatRoom(widget.roomId);

    super.dispose();
  }

  Future<void> _initializeChat() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      final userInfo = await AuthService.getUserInfo();
      if (!mounted) return;

      if (userInfo != null && userInfo['userId'] != null) {
        setState(() {
          _currentUserId = userInfo['userId'];
          _userRole = userInfo['role']; // 사용자 역할 저장
        });
        print('=== 🔍 그룹 채팅 초기화 ===');
        print('현재 사용자 ID: ${_currentUserId}');
        print('현재 사용자 역할: ${_userRole}');
        print('그룹 채팅방 ID: ${widget.roomId}');
      }

      // 채팅방 배경 로드
      final backgroundPath = await ChatBackgroundService.getBackgroundImagePath();
      if (mounted) {
        setState(() {
          _backgroundImagePath = backgroundPath;
        });
      }

      // WebSocket 초기화 먼저
      print('WebSocket 초기화 시작...');
      await ChatService.initializeWebSocket();

      if (!mounted) return;

      // 그룹 채팅방에서는 메시지를 직접 로드
      await _loadAllMessages();

      // WebSocket 구독만 설정 (메시지 로드는 별도로)
      print('그룹 채팅방 WebSocket 구독 시작...');
      ChatService.subscribeToChatRoom(widget.roomId, _handleMessageReceived);
      ChatService.subscribeToMessageRead(
        widget.roomId,
        _handleMessageReadReceived,
      );

      // 그룹 채팅방 초대/나가기 이벤트 구독 (중복 제거)
      ChatService.subscribeToRoomInvite(widget.roomId, _handleInviteReceived);
      ChatService.subscribeToRoomLeave(widget.roomId, _handleLeaveReceived);

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('그룹 채팅 초기화 중 오류 발생: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorDialog('오류', '그룹 채팅을 초기화하는 중 오류가 발생했습니다.');
      }
    }
  }

  Future<void> _loadAllMessages() async {
    try {
      print('🔍 그룹 채팅방 메시지 로드 시작');

      // 채팅방 상세 정보 조회
      final roomDetails = await ChatService.getChatRoomDetails(widget.roomId);
      int lastMessageId = 999999;

      if (roomDetails != null && roomDetails['lastSendMessageId'] is int) {
        lastMessageId = roomDetails['lastSendMessageId'] + 1;
        print(
          '🔍 서버에서 받은 lastSendMessageId: ${roomDetails['lastSendMessageId']}',
        );

        // 채팅방 상세 정보 업데이트
        if (mounted) {
          setState(() {
            // 서버에서 받은 실제 채팅방 이름으로 업데이트
            _roomName = roomDetails['roomName'] ?? _roomName;
            
            // 참여자 수 업데이트
            final participants = roomDetails['participants'] as List<dynamic>?;
            if (participants != null) {
              _participantCount = participants.length;
              print('🔍 참여자 정보 업데이트: $_participantCount명');
            }
          });
        }
      }

      List<ChatMessage> allMessages = [];
      Set<int> addedMessageIds = {};
      int currentPage = 0;
      bool hasMoreMessages = true;

      while (hasMoreMessages && currentPage < 50) {
        try {
          final messages = await ChatService.getChatRoomMessages(
            widget.roomId,
            lastMessageId: lastMessageId,
            pageNumber: currentPage,
          );

          print('🔍 그룹 채팅방 페이지 $currentPage 조회 완료 - 메시지 수: ${messages.length}');

          if (messages.isEmpty) {
            hasMoreMessages = false;
          } else {
            int addedInThisPage = 0;
            for (final message in messages) {
              final messageId = message.messageId;
              if (messageId != null && !addedMessageIds.contains(messageId)) {
                allMessages.add(message);
                addedMessageIds.add(messageId);
                addedInThisPage++;
              }
            }

            print('🔍 그룹 채팅방 페이지 $currentPage에서 새로 추가된 메시지: $addedInThisPage개');

            if (addedInThisPage == 0) {
              hasMoreMessages = false;
            } else {
              currentPage++;
            }
          }
        } catch (e) {
          print('❌ 그룹 채팅방 페이지 $currentPage 메시지 로드 실패: $e');
          hasMoreMessages = false;
        }
      }

      if (!mounted) return;

      // messageId 기준으로 오름차순 정렬 (오래된 메시지가 위, 최신 메시지가 아래)
      allMessages.sort((a, b) {
        final aId = a.messageId ?? 0;
        final bId = b.messageId ?? 0;
        return aId.compareTo(bId);
      });

      setState(() {
        _messages.clear();
        _messages.addAll(allMessages);
      });

      print('✅ 그룹 채팅방 전체 메시지 로드 완료: ${allMessages.length}개');
      
      // 로드된 메시지의 발신자 정보 확인
      print('🔍 로드된 메시지들의 발신자 정보:');
      for (final message in allMessages) {
        print('📝 메시지 ${message.messageId}: "${message.content}"');
        print('   - 발신자 ID: ${message.senderUserId}');
        print('   - 발신자 이름: "${message.senderName}"');
        print('   - 메시지 타입: ${message.messageType}');
      }
      print('🔍 현재 _roomName: "$_roomName"');

      // 맨 아래로 스크롤
      _scrollToBottom();

      // 안읽은 메시지 읽음 처리
      await _markUnreadMessagesAsRead();
    } catch (e) {
      print('❌ 그룹 채팅방 메시지 로드 중 오류: $e');
      // 메시지 로드 실패해도 WebSocket 구독은 유지
    }
  }

  Future<void> _markUnreadMessagesAsRead() async {
    try {
      print('📖 그룹 채팅방 안읽은 메시지 읽음 처리 시작');

      final roomDetails = await ChatService.getChatRoomDetails(widget.roomId);
      if (roomDetails == null) return;

      final lastReadMessageId = roomDetails['lastReadMessageId'] as int? ?? 0;
      print('📖 마지막 읽은 메시지 ID: $lastReadMessageId');

      final unreadMessages =
          _messages.where((message) {
            return message.messageId != null &&
                message.messageId! > lastReadMessageId &&
                message.senderUserId != _currentUserId &&
                message.senderUserId != 0;
          }).toList();

      if (unreadMessages.isNotEmpty) {
        final unreadMessageIds =
            unreadMessages.map((msg) => msg.messageId!).toList();
        print('📖 그룹 채팅방 읽음 처리할 메시지 IDs: $unreadMessageIds');

        await ChatService.sendMessageRead(
          roomId: widget.roomId,
          messageIds: unreadMessageIds,
        );

        print('✅ 그룹 채팅방 안읽은 메시지 ${unreadMessageIds.length}개 읽음 처리 완료');
      } else {
        print('📖 그룹 채팅방에 읽을 안읽은 메시지가 없음');
      }
    } catch (e) {
      print('❌ 그룹 채팅방 안읽은 메시지 읽음 처리 중 오류: $e');
    }
  }

  void _handleMessageReceived(Map<String, dynamic> messageData) {
    print('📨 그룹 메시지 수신: $messageData');

    try {
      final message = ChatMessage.fromJson(messageData);
      if (mounted) {
        print('📨 파싱된 메시지 정보:');
        print('   - messageId: ${message.messageId}');
        print('   - content: ${message.content}');
        print('   - senderUserId: ${message.senderUserId}');
        print('   - senderName: ${message.senderName}');
        
        // 중복 메시지 방지 (동일한 messageId가 있는지 확인)
        final isDuplicate = _messages.any(
          (existingMessage) => existingMessage.messageId == message.messageId,
        );

        if (!isDuplicate) {
          setState(() {
            _messages.add(message);
          });
          _scrollToBottom();
          print('✅ 새 그룹 메시지 추가됨: ${message.content} (발신자: ${message.senderName})');
        } else {
          print('⚠️ 중복 그룹 메시지 무시됨: ${message.content} (ID: ${message.messageId})');
        }

        // 실시간 메시지 즉시 읽음 처리 (내가 보낸 메시지가 아닌 경우에만)
        if (message.messageId != null &&
            message.senderUserId != _currentUserId) {
          ChatService.markReceivedMessageAsRead(
            roomId: widget.roomId,
            messageId: message.messageId!,
          );
        }
      }
    } catch (e) {
      print('그룹 메시지 처리 중 오류 발생: $e');
    }
  }

  void _handleMessageReadReceived(Map<String, dynamic> readData) {
    print('그룹 채팅 메시지 읽음 처리 수신: $readData');

    try {
      final messageIds = readData['messageIds'] as List<dynamic>?;
      if (messageIds != null && mounted) {
        // 읽음 처리된 메시지들에 대한 UI 업데이트
        // 필요시 읽음 상태 표시 로직 추가
        print('읽음 처리된 메시지 IDs: $messageIds');
      }
    } catch (e) {
      print('메시지 읽음 처리 중 오류 발생: $e');
    }
  }

  void _handleInviteReceived(Map<String, dynamic> inviteData) {
    print('=== 👥 그룹 채팅방 초대 알림 수신 ===');
    print('초대 데이터: $inviteData');

    try {
      final roomId = inviteData['roomId'] as int?;
      final message = inviteData['message']?.toString() ?? '';
      final timestamp =
          inviteData['timestamp']?.toString() ??
          inviteData['timeStamp']?.toString() ??
          '';

      print('👥 초대된 채팅방 ID: $roomId');
      print('👥 현재 채팅방 ID: ${widget.roomId}');
      print('👥 초대 메시지: $message');

      if (message.isNotEmpty && mounted) {
        // 현재 채팅방의 초대인지, 다른 채팅방의 초대인지 확인
        bool isCurrentRoom = (roomId == widget.roomId);

        print('👥 초대 시스템 메시지: $message');
        print('👥 현재 채팅방 초대 여부: $isCurrentRoom');

        // 메시지에서 실제 초대 내용 추출
        String displayMessage = message;

        // 현재 채팅방이 아닌 경우, 메시지를 현재 채팅방 맥락에 맞게 조정
        if (!isCurrentRoom && message.contains('초대하였습니다')) {
          // 다른 채팅방에서 초대되었다는 메시지일 수 있으므로, 현재 채팅방 참여자 확인
          displayMessage = message; // 일단 원본 메시지 사용
        }

        // 시스템 메시지로 초대 알림을 채팅창에 추가
        final systemMessage = ChatMessage(
          messageId: DateTime.now().millisecondsSinceEpoch, // 임시 ID
          roomId: widget.roomId,
          content: displayMessage,
          senderUserId: 0, // 시스템 메시지는 senderUserId를 0으로
          senderName: 'System',
          time: _formatTimestamp(timestamp),
          messageType: MessageType.system,
        );

        setState(() {
          _messages.add(systemMessage);
        });

        // 최신 메시지로 스크롤
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });

        print('✅ 초대 알림이 채팅방에 표시됨');

        // 채팅방 정보 새로고침 (참여자 수 업데이트)
        Future.delayed(Duration(milliseconds: 500), () async {
          await _refreshChatRoom();
        });
      }
    } catch (e) {
      print('❌ 초대 알림 처리 중 오류 발생: $e');
      print('오류 스택 트레이스: ${StackTrace.current}');
    }
  }

  // timestamp를 "시간:분" 형식으로 변환하는 헬퍼 함수
  String _formatTimestamp(String? timestamp) {
    if (timestamp == null || timestamp.isEmpty) {
      return _getCurrentTime();
    }

    try {
      // ISO 8601 형식 파싱
      if (timestamp.contains('T')) {
        final dateTime = DateTime.parse(timestamp);
        return "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
      }

      // 이미 시간 형식인 경우
      if (RegExp(r'^\d{1,2}:\d{2}$').hasMatch(timestamp)) {
        return timestamp;
      }

      return _getCurrentTime();
    } catch (e) {
      print('⏰ timestamp 파싱 오류: $e, 원본: $timestamp');
      return _getCurrentTime();
    }
  }

  void _handleLeaveReceived(Map<String, dynamic> leaveData) {
    try {
      print('=== 🚪 그룹 채팅방 나가기 알림 수신 ===');
      if (!mounted) return;

      print('🚪 나가기 알림 데이터: $leaveData');

      final roomId = leaveData['roomId'] as int?;
      final leaverName = leaveData['leaverName'] as String? ?? '사용자';
      final leaverUserId = leaveData['leaverUserId'] as int?;
      final timestamp = leaveData['timestamp'] as String?;
      final participantCount = leaveData['participantCount'] as int?;

      print('🚪 나간 사용자: $leaverName (ID: $leaverUserId)');
      print('🚪 채팅방 ID: $roomId');
      print('🚪 현재 참여자 수: $participantCount');

      // 현재 채팅방의 나가기 알림인지 확인
      if (roomId == widget.roomId) {
        print('✅ 현재 그룹채팅방의 나가기 알림 확인됨');

        // 시스템 메시지로 나가기 알림을 채팅창에 추가
        final leaveMessage = ChatMessage(
          messageId: DateTime.now().millisecondsSinceEpoch,
          roomId: widget.roomId,
          content: '$leaverName님이 나갔습니다.',
          senderUserId: 0, // 시스템 메시지는 senderUserId를 0으로 설정
          senderName: 'System',
          time: _getCurrentTime(),
          messageType: MessageType.system,
        );

        setState(() {
          // 메시지 목록에 나가기 알림 추가
          _messages.add(leaveMessage);

          // 참여자 수 업데이트 (서버에서 제공된 경우)
          if (participantCount != null && participantCount > 0) {
            _participantCount = participantCount;
            print('🔄 참여자 수 업데이트: $_participantCount명');
          } else {
            // 서버에서 참여자 수를 제공하지 않으면 직접 계산
            if (_participantCount > 1) {
              _participantCount--;
              print('🔄 참여자 수 감소: $_participantCount명');
            }
          }
        });

        // 최신 메시지로 스크롤
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });

        // AppBar 제목도 즉시 업데이트 (참여자 수 반영)
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              // AppBar 제목 강제 업데이트
            });
          }
        });

        print('✅ 나가기 알림이 채팅방에 표시되고 참여자 수가 업데이트됨');

        // 선택사항: 채팅방 상세 정보를 서버에서 다시 가져와서 동기화
        Future.delayed(Duration(milliseconds: 500), () async {
          await _refreshChatRoom();
        });
      } else {
        print('⚠️ 다른 채팅방의 나가기 알림: $roomId (현재: ${widget.roomId})');
      }
    } catch (e) {
      print('❌ 나가기 알림 처리 중 오류 발생: $e');
      print('오류 스택 트레이스: ${StackTrace.current}');
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              title,
              style: const TextStyle(
                fontFamily: 'Pretendard-Bold',
                fontWeight: FontWeight.w700,
              ),
            ),
            content: Text(
              message,
              style: const TextStyle(
                fontFamily: 'Pretendard-Regular',
                fontWeight: FontWeight.w400,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  '확인',
                  style: TextStyle(
                    fontFamily: 'Pretendard-Medium',
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF4A80F0),
                  ),
                ),
              ),
            ],
          ),
    );
  }

  String _getCurrentTime() {
    final now = DateTime.now();
    return "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
  }

  String _getCurrentDate() {
    final now = DateTime.now();
    return "${now.year}. ${now.month.toString().padLeft(2, '0')}. ${now.day.toString().padLeft(2, '0')}";
  }

  // 메시지 시간을 파싱하여 "시간:분" 형식으로 변환
  String _formatMessageTime(ChatMessage message) {
    try {
      // 1. time 필드가 ISO 8601 timestamp 형식인지 확인 (서버에서 오는 주 형식)
      if (message.time != null && message.time!.isNotEmpty) {
        // ISO 8601 형식 체크 (예: "2025-06-23T22:53:11.677326" 또는 "2025-06-23T22:53:11Z")
        if (message.time!.contains('T') &&
            (message.time!.contains('-') || message.time!.contains(':'))) {
          try {
            final dateTime = DateTime.parse(message.time!);
            return "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
          } catch (e) {
            print('⏰ ISO 8601 파싱 실패: ${message.time}, 오류: $e');
          }
        }

        // 이미 "HH:MM" 형식인지 확인
        if (RegExp(r'^\d{1,2}:\d{2}$').hasMatch(message.time!)) {
          return message.time!;
        }
      }

      // 2. createdAt 필드 사용 (백업)
      if (message.createdAt != null && message.createdAt!.isNotEmpty) {
        try {
          final dateTime = DateTime.parse(message.createdAt!);
          return "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
        } catch (e) {
          print('⏰ createdAt 파싱 실패: ${message.createdAt}, 오류: $e');
        }
      }

      // 3. 모든 방법이 실패하면 현재 시간 반환
      print('⏰ 메시지 시간 파싱 실패 - 현재 시간 사용 (messageId: ${message.messageId})');
      return _getCurrentTime();
    } catch (e) {
      print('⏰ 메시지 시간 파싱 중 예외: $e');
      print('   - time: ${message.time}');
      print('   - createdAt: ${message.createdAt}');
      print('   - messageId: ${message.messageId}');
      return _getCurrentTime();
    }
  }

  // 발신자 정보 찾기 (아이단과 동일하게 단순화)
  Map<String, dynamic>? _getSenderInfo(int? senderUserId) {
    if (senderUserId == null) {
      print('🔍 _getSenderInfo: senderUserId가 null입니다');
      return null;
    }
    
    print('🔍 _getSenderInfo 호출됨:');
    print('  - 찾고 있는 senderUserId: $senderUserId');
    print('  - 현재 participants 데이터:');
    for (int i = 0; i < widget.participants.length; i++) {
      final participant = widget.participants[i];
      print('    참여자 $i: userId=${participant['userId']}, name=${participant['name']}');
    }
    
    final result = widget.participants.firstWhere(
      (participant) => participant['userId'] == senderUserId,
      orElse: () => {},
    );
    
    print('  - 찾은 결과: $result');
    return result.isEmpty ? null : result;
  }

  Widget _buildMessage(ChatMessage message, int index) {
    final isHighlighted =
        _searchResults.contains(index) &&
        _searchResults[_currentSearchIndex] == index;

    // 시스템 메시지인 경우 별도 처리
    if (message.messageType == MessageType.system) {
      return _buildSystemMessage(message, isHighlighted);
    }

    final isMe = message.senderUserId == _currentUserId;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration:
          isHighlighted
              ? BoxDecoration(
                color: Colors.yellow.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              )
              : null,
      child: Column(
        children: [
          if (isMe) _buildMyMessage(message) else _buildOtherMessage(message),
        ],
      ),
    );
  }

  Widget _buildSystemMessage(ChatMessage message, bool isHighlighted) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration:
          isHighlighted
              ? BoxDecoration(
                color: Colors.yellow.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              )
              : null,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
          ),
          child: Text(
            message.content,
            style: const TextStyle(
              color: Color(0xFF666666),
              fontSize: 12,
              fontFamily: 'Pretendard-Regular',
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildOtherMessage(ChatMessage message) {
    // 아이단과 동일한 방식으로 발신자 정보 처리
    final senderInfo = _getSenderInfo(message.senderUserId);
    final senderName = senderInfo?['name'] ?? message.senderName ?? '알 수 없음';
    final senderAvatar = senderInfo?['profileImageUrl'] ?? '';

    // 디버그 로그 추가
    print('🔍 메시지 발신자 정보 (메시지 ID: ${message.messageId}):');
    print('  - senderUserId: ${message.senderUserId}');
    print('  - message.senderName: "${message.senderName}"');
    print('  - senderInfo: $senderInfo');
    print('  - 최종 senderName: "$senderName"');

    return Container(
      width: 334,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 프로필과 이름
          Container(
            height: 36,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: ShapeDecoration(
                    image:
                        senderAvatar.isNotEmpty
                            ? DecorationImage(
                              image: CachedNetworkImageProvider(
                                senderAvatar.startsWith('http')
                                    ? senderAvatar
                                    : 'https://littlebank-dev.s3.ap-northeast-2.amazonaws.com/$senderAvatar',
                              ),
                              fit: BoxFit.cover,
                            )
                            : null,
                    shape: OvalBorder(),
                  ),
                  child:
                      senderAvatar.isEmpty
                          ? Center(
                            child: Text(
                              senderName.isNotEmpty ? senderName[0] : '?',
                              style: const TextStyle(
                                fontSize: 14,
                                fontFamily: 'Pretendard-Medium',
                              ),
                            ),
                          )
                          : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      senderName,
                      style: TextStyle(
                        color: const Color(0xFF202020),
                        fontSize: 16,
                        fontFamily: 'Pretendard-Bold',
                        letterSpacing: -0.32,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // 메시지 버블과 시간
          Padding(
            padding: const EdgeInsets.only(left: 52),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Flexible(
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.6,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: ShapeDecoration(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(24),
                          bottomLeft: Radius.circular(24),
                          bottomRight: Radius.circular(24),
                        ),
                      ),
                    ),
                    child: Text(
                      message.content ?? '',
                      style: TextStyle(
                        color: const Color(0xFF4A4A4A),
                        fontSize: 14,
                        fontFamily: 'Pretendard-Light',
                        letterSpacing: -0.28,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _formatMessageTime(message),
                  style: TextStyle(
                    color: const Color(0xFFC4C4C4),
                    fontSize: 11,
                    fontFamily: 'Pretendard-Light',
                    letterSpacing: -0.22,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyMessage(ChatMessage message) {
    return Container(
      width: double.infinity,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            _formatMessageTime(message),
            style: TextStyle(
              color: const Color(0xFFC4C4C4),
              fontSize: 11,
              fontFamily: 'Pretendard-Light',
              letterSpacing: -0.22,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.6,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: ShapeDecoration(
                color: const Color(0xFF89DA8D),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                    bottomLeft: Radius.circular(24),
                  ),
                ),
              ),
              child: Text(
                message.content ?? '',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontFamily: 'Pretendard-Light',
                  letterSpacing: -0.28,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 검색 기능 (1:1 채팅과 동일)
  void _startSearch() {
    setState(() {
      _isSearching = true;
    });
  }

  void _stopSearch() {
    setState(() {
      _isSearching = false;
      _searchQuery = '';
      _searchResults.clear();
      _currentSearchIndex = -1;
    });
    _searchController.clear();
  }



  // 채팅방 정보 새로고침 (초대 후 인원수 업데이트)
  Future<void> _refreshChatRoom() async {
    try {
      print('🔄 채팅방 정보 새로고침 시작');

      // 1. 채팅방 상세 정보 다시 조회
      final roomDetails = await ChatService.getChatRoomDetails(widget.roomId);
      if (roomDetails != null && mounted) {
        final newParticipantCount =
            roomDetails['participantCount'] ?? _participantCount;
        final newRoomName = roomDetails['roomName'] ?? _roomName;

        print('🔄 업데이트된 참여자 수: $newParticipantCount (이전: $_participantCount)');
        print('🔄 업데이트된 채팅방 이름: $newRoomName');

        // 2. AppBar 제목 업데이트 (메시지는 재로드하지 않음)
        setState(() {
          _participantCount = newParticipantCount;
          _roomName = newRoomName;
        });

        print('✅ 채팅방 정보 새로고침 완료 - 현재 인원: $_participantCount명');
      }
    } catch (e) {
      print('❌ 채팅방 정보 새로고침 중 오류: $e');
    }
  }

  void _performSearch(String query) {
    if (query.isEmpty) {
      setState(() {
        _searchResults.clear();
        _currentSearchIndex = -1;
      });
      return;
    }

    final results = <int>[];
    for (int i = 0; i < _messages.length; i++) {
      if (_messages[i].content?.toLowerCase().contains(query.toLowerCase()) ==
          true) {
        results.add(i);
      }
    }

    setState(() {
      _searchQuery = query;
      _searchResults = results;
      _currentSearchIndex = results.isNotEmpty ? 0 : -1;
    });

    if (results.isNotEmpty) {
      _scrollToSearchResult(0);
    }
  }

  void _scrollToSearchResult(int resultIndex) {
    if (resultIndex < 0 || resultIndex >= _searchResults.length) return;

    final messageIndex = _searchResults[resultIndex];
    final itemExtent = 120.0;
    final offset = messageIndex * itemExtent;

    _scrollController.animateTo(
      offset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _nextSearchResult() {
    if (_searchResults.isEmpty) return;

    final nextIndex = (_currentSearchIndex + 1) % _searchResults.length;
    setState(() {
      _currentSearchIndex = nextIndex;
    });
    _scrollToSearchResult(nextIndex);
  }

  void _previousSearchResult() {
    if (_searchResults.isEmpty) return;

    final prevIndex =
        _currentSearchIndex <= 0
            ? _searchResults.length - 1
            : _currentSearchIndex - 1;
    setState(() {
      _currentSearchIndex = prevIndex;
    });
    _scrollToSearchResult(prevIndex);
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFE7ECF6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFE7ECF6),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFDADADA), width: 0.8),
              ),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(
                  fontSize: 14,
                  fontFamily: 'Pretendard-Regular',
                ),
                decoration: InputDecoration(
                  hintText: '채팅 내용 검색...',
                  hintStyle: TextStyle(
                    color: const Color(0xFF999999),
                    fontSize: 12,
                    fontFamily: 'Pretendard-Light',
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  filled: false,
                  fillColor: Colors.transparent,
                ),
                onChanged: _performSearch,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // 검색 결과 네비게이션
          if (_searchResults.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF4A80F0),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_currentSearchIndex + 1}/${_searchResults.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontFamily: 'Pretendard-Medium',
                ),
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.keyboard_arrow_up, size: 20),
              onPressed: _previousSearchResult,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
            IconButton(
              icon: const Icon(Icons.keyboard_arrow_down, size: 20),
              onPressed: _nextSearchResult,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ],
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: _stopSearch,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }

  // 메뉴 화면으로 이동하는 함수 추가
  void _navigateToMenu() {
    if (_userRole == 'PARENT') {
      // 부모단 메뉴 화면으로 이동
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => parent_menu.ParentChatRoomMenuScreen(
            userName: _roomName,
            avatar: '',
            roomId: widget.roomId,
            userId: _currentUserId ?? 0,
          ),
        ),
      ).then((result) {
        // 메뉴에서 돌아왔을 때 처리
        if (result != null && result is Map<String, dynamic>) {
          final action = result['action'];
          if (action == 'leave_room') {
            // 나가기 처리 완료 시 이전 화면으로 돌아가기
            Navigator.pop(context, result);
          }
        }
      });
    } else {
      // 아이단 메뉴 화면으로 이동
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => child_menu.ChatRoomMenuScreen(
            userName: _roomName,
            avatar: '',
            roomId: widget.roomId,
            userId: _currentUserId ?? 0,
          ),
        ),
      ).then((result) {
        // 메뉴에서 돌아왔을 때 처리
        if (result != null && result is Map<String, dynamic>) {
          final action = result['action'];
          if (action == 'leave_room') {
            // 나가기 처리 완료 시 이전 화면으로 돌아가기
            Navigator.pop(context, result);
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 390,
      height: MediaQuery.of(context).size.height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFFE7ECF6),
        image: _backgroundImagePath != null
            ? DecorationImage(
                image: AssetImage(_backgroundImagePath!),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF202020)),
            onPressed: () => Navigator.pop(context),
          ),
          title: Center(
            child: Text(
              '$_roomName ($_participantCount명)',
              style: TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontFamily: 'Pretendard-Bold',
                letterSpacing: -0.32,
              ),
            ),
          ),
          centerTitle: true,
          actions: [
            // 검색 버튼
            IconButton(
              icon: Image.asset(
                'assets/images/search.png',
                width: 24,
                height: 24,
                color: const Color(0xFF202020),
              ),
              onPressed: _startSearch,
            ),
            // 메뉴 버튼
            IconButton(
              icon: const Icon(
                Icons.menu,
                color: Color(0xFF202020),
                size: 24,
              ),
              onPressed: _navigateToMenu,
            ),
          ],
        ),
        body: Column(
          children: [
            // 검색바 (검색 중일 때만 표시)
            if (_isSearching) _buildSearchBar(),

            // 날짜 표시 (검색 중이 아닐 때만)
            if (!_isSearching)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  _getCurrentDate(),
                  style: TextStyle(
                    color: const Color(0xFFC4C4C4),
                    fontSize: 14,
                    fontFamily: 'Pretendard-Light',
                    letterSpacing: -0.28,
                  ),
                ),
              ),

            // 메시지 목록
            Expanded(
              child:
                  _isLoading
                      ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF4A80F0),
                        ),
                      )
                      : ListView.builder(
                        controller: _scrollController,
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          return _buildMessage(_messages[index], index);
                        },
                      ),
            ),

            // 메시지 입력 영역
            if (!_isSearching)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(color: Colors.white),
                child: SafeArea(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // 파일 추가 버튼
                      GestureDetector(
                        onTap: _showMediaOptions,
                        child: Container(
                          width: 28,
                          height: 28,
                          child: Image.asset(
                            'assets/icons/add_file.png',
                            width: 28,
                            height: 28,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // 메시지 입력 컨테이너 (실제 TextField)
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 2,
                          ),
                          decoration: ShapeDecoration(
                            color: const Color(0xFFF0F0F0),
                            shape: RoundedRectangleBorder(
                              side: BorderSide(
                                width: 0.80,
                                color: const Color(0xFFDADADA),
                              ),
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          child: TextField(
                            controller: _messageController,
                            decoration: InputDecoration(
                              hintText: '메시지를 입력해 주세요',
                              hintStyle: TextStyle(
                                color: const Color(0xFF999999),
                                fontSize: 12,
                                fontFamily: 'Pretendard',
                                fontWeight: FontWeight.w300,
                                letterSpacing: -0.24,
                              ),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              errorBorder: InputBorder.none,
                              disabledBorder: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(vertical: 4),
                              fillColor: const Color(0xFFF0F0F0),
                              filled: true,
                            ),
                            style: TextStyle(
                              color: const Color(0xFF202020),
                              fontSize: 12,
                              fontFamily: 'Pretendard',
                              fontWeight: FontWeight.w400,
                              letterSpacing: -0.24,
                            ),
                            maxLines: null,
                            keyboardType: TextInputType.multiline,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (value) {
                              if (value.trim().isNotEmpty) {
                                _sendMessage();
                              }
                            },
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
    );
  }

  void _showMediaOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "미디어 첨부",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Pretendard-Bold',
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildMediaOption(
                      icon: Icons.photo,
                      label: "사진",
                      onTap: () {
                        Navigator.pop(context);
                        _pickImage();
                      },
                    ),
                    const SizedBox(width: 40),
                    _buildMediaOption(
                      icon: Icons.videocam,
                      label: "동영상",
                      onTap: () {
                        Navigator.pop(context);
                        _pickVideo();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMediaOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFFE9F1FF),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Icon(icon, color: const Color(0xFF3A88F4), size: 30),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontFamily: 'Pretendard-Regular',
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedImage = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (pickedImage != null) {
        print('=== 📷 그룹 이미지 메시지 전송 ===');
        print('이미지 경로: ${pickedImage.path}');

        // TODO: 파일 업로드 API 호출 후 URL 받아서 WebSocket으로 전송
        // 현재는 로컬 경로를 직접 전송 (임시)
        final result = await ChatService.sendMessage(
          roomId: widget.roomId,
          content: pickedImage.path,
          messageType: 'IMAGE',
        );

        if (result != null && result['success'] == true) {
          print('✅ 그룹 이미지 메시지 전송 성공 - WebSocket을 통해 수신될 예정');
        } else {
          print('❌ 그룹 이미지 메시지 전송 실패');
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('이미지 전송에 실패했습니다.')));
        }
      }
    } catch (e) {
      print('❌ 그룹 이미지 선택/전송 중 오류: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('이미지 선택 중 오류가 발생했습니다: $e')));
    }
  }

  Future<void> _pickVideo() async {
    try {
      final XFile? pickedVideo = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 5),
      );

      if (pickedVideo != null) {
        print('=== 📹 그룹 비디오 메시지 전송 ===');
        print('비디오 경로: ${pickedVideo.path}');

        // TODO: 파일 업로드 API 호출 후 URL 받아서 WebSocket으로 전송
        // 현재는 로컬 경로를 직접 전송 (임시)
        final result = await ChatService.sendMessage(
          roomId: widget.roomId,
          content: pickedVideo.path,
          messageType: 'VIDEO',
        );

        if (result != null && result['success'] == true) {
          print('✅ 그룹 비디오 메시지 전송 성공 - WebSocket을 통해 수신될 예정');
        } else {
          print('❌ 그룹 비디오 메시지 전송 실패');
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('비디오 전송에 실패했습니다.')));
        }
      }
    } catch (e) {
      print('❌ 그룹 비디오 선택/전송 중 오류: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('비디오 선택 중 오류가 발생했습니다: $e')));
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    try {
      print('=== 📤 그룹 메시지 전송 시작 ===');
      print('메시지 내용: $text');

      final result = await ChatService.sendMessage(
        roomId: widget.roomId,
        content: text,
        messageType: 'TEXT',
      );

      if (result != null && result['success'] == true) {
        print('✅ 그룹 메시지 전송 성공 - 즉시 화면에 표시');

        // 즉시 화면에 메시지 추가 (WebSocket 수신 대기하지 않음)
        if (mounted) {
          final myMessage = ChatMessage(
            messageId: DateTime.now().millisecondsSinceEpoch, // 임시 ID
            roomId: widget.roomId,
            content: text,
            senderUserId: _currentUserId ?? 0,
            senderName: '나', // 현재 사용자
            time: _getCurrentTime(),
            messageType: MessageType.text,
            createdAt: DateTime.now().toIso8601String(),
          );

          setState(() {
            _messages.add(myMessage);
            _messageController.clear();
          });

          _scrollToBottom();
        }

        print('그룹 메시지가 즉시 화면에 표시되었습니다.');
      } else {
        print('❌ 그룹 메시지 전송 실패');
        _showErrorDialog('오류', '메시지 전송에 실패했습니다.');
      }
    } catch (e) {
      print('❌ 그룹 메시지 전송 중 오류 발생: $e');
      _showErrorDialog('오류', '메시지 전송 중 오류가 발생했습니다.');
    }
  }


}
