import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../../theme/app_colors.dart';
import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import '../../services/chat_service.dart';
import '../../services/auth_service.dart';
import '../../services/chat_background_service.dart';
import '../../models/chat_message.dart';
import '../../widgets/chat/chat_message_item.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'chat/detail/chat_room_menu_screen.dart';

class ParentChatDetailScreen extends StatefulWidget {
  final String userName;
  final String avatar;
  final int roomId;
  final int userId;

  const ParentChatDetailScreen({
    super.key,
    required this.userName,
    required this.avatar,
    required this.roomId,
    required this.userId,
  });

  @override
  State<ParentChatDetailScreen> createState() => _ParentChatDetailScreenState();
}

class _ParentChatDetailScreenState extends State<ParentChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  final ImagePicker _picker = ImagePicker();
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _isLoading = false;
  int? _currentUserId;
  String? _backgroundImagePath;

  // 검색 관련 변수들
  bool _isSearching = false;
  String _searchQuery = '';
  List<int> _searchResults = [];
  int _currentSearchIndex = -1;

  // 채팅방 정보
  bool _isGroupChat = false;
  String _roomName = '';

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();

    // 채팅방 나가기 전 마지막 읽음 처리
    _performFinalReadProcessing();

    // WebSocket 구독 해제
    ChatService.unsubscribeFromChatRoom(widget.roomId);
    ChatService.unsubscribeFromMessageRead(widget.roomId);

    super.dispose();
  }

  // 채팅방 나가기 전 마지막 읽음 처리
  void _performFinalReadProcessing() {
    if (_currentUserId == null || _messages.isEmpty) {
      return;
    }

    try {
      // 현재 화면에 있는 모든 메시지 중 내가 보내지 않은 메시지들 찾기
      final unreadMessages =
          _messages.where((message) {
            return message.messageId != null &&
                message.senderUserId != _currentUserId &&
                message.senderUserId != 0;
          }).toList();

      if (unreadMessages.isNotEmpty) {
        final messageIds = unreadMessages.map((msg) => msg.messageId!).toList();

        // 비동기 읽음 처리
        ChatService.sendMessageRead(
          roomId: widget.roomId,
          messageIds: messageIds,
        );
      }
    } catch (e) {
      // dispose 중이므로 에러 무시
    }
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
        });
      }

      // 채팅방 배경 로드
      final backgroundPath =
          await ChatBackgroundService.getBackgroundImagePath();
      if (mounted) {
        setState(() {
          _backgroundImagePath = backgroundPath;
        });
      }

      // WebSocket 과부하 방지: 기존 구독들 정리
      ChatService.printSubscriptionStatus();
      ChatService.cleanupExcessiveSubscriptions(maxSubscriptions: 5);

      await ChatService.initializeWebSocket();
      await _loadChatRoomDetails();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('채팅을 초기화하는데 실패했습니다: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _loadChatRoomDetails({bool setupWebSocket = true}) async {
    try {
      // 서버에서 lastSendMessageId 받아오기
      final roomDetails = await ChatService.getChatRoomDetails(widget.roomId);
      int lastMessageId = 999999;

      // 채팅방 정보 먼저 업데이트 (메시지 로드 실패와 무관하게)
      if (roomDetails != null && mounted) {
        final roomRange = roomDetails['roomRange'];
        final participantCount = roomDetails['participantCount'] ?? 0;
        final participantNameList =
            roomDetails['participantNameList'] as List<dynamic>? ?? [];

        setState(() {
          // 참여자가 3명 이상이거나 roomRange가 GROUP인 경우 그룹 채팅으로 판단
          _isGroupChat =
              roomRange == 'GROUP' ||
              participantCount >= 3 ||
              participantNameList.length >= 3;
          _roomName = roomDetails['roomName'] ?? widget.userName;
        });
      }

      if (roomDetails != null && roomDetails['lastSendMessageId'] is int) {
        lastMessageId = roomDetails['lastSendMessageId'] + 1;
      }

      // 모든 메시지를 가져오기 위해 페이징 반복
      List<ChatMessage> allMessages = [];
      Set<int> addedMessageIds = {};
      int currentPage = 0;
      bool hasMoreMessages = true;

      while (hasMoreMessages) {
        final messages = await ChatService.getChatRoomMessages(
          widget.roomId,
          lastMessageId: lastMessageId,
          pageNumber: currentPage,
        );

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

          currentPage++;

          if (currentPage >= 50) {
            hasMoreMessages = false;
          }
        }
      }

      if (!mounted) return;

      // messageId 기준으로 오름차순 정렬
      allMessages.sort((a, b) {
        final aId = a.messageId ?? 0;
        final bId = b.messageId ?? 0;
        return aId.compareTo(bId);
      });

      // 메시지 업데이트를 한 번에 처리하여 렌더링 최적화
      _messages.clear();
      _messages.addAll(allMessages);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }

      if (setupWebSocket) {
        await _setupWebSocketSubscription();
        await _markUnreadMessagesAsRead();
      }

      // 메시지 로드 완료 후 맨 아래로 즉시 스크롤 (더 빠르게)
      if (_scrollController.hasClients && _messages.isNotEmpty) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    } catch (e, stackTrace) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('메시지를 불러오는데 실패했습니다: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _markUnreadMessagesAsRead() async {
    if (_currentUserId == null || _messages.isEmpty) {
      return;
    }

    try {
      final roomDetails = await ChatService.getChatRoomDetails(widget.roomId);
      if (roomDetails == null) {
        return;
      }

      final lastReadMessageId = roomDetails['lastReadMessageId'] as int? ?? 0;

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

        await ChatService.sendMessageRead(
          roomId: widget.roomId,
          messageIds: unreadMessageIds,
        );
      }
    } catch (e) {
      // 에러 무시
    }
  }

  Future<void> _setupWebSocketSubscription() async {
    try {
      final userInfo = await AuthService.getUserInfo();
      final userId = userInfo?['userId'];

      if (userId == null) {
        return;
      }

      // 채팅방 메시지 구독
      await ChatService.subscribeToChatRoom(
        widget.roomId,
        _handleMessageReceived,
      );

      // 메시지 읽음 처리 구독
      await ChatService.subscribeToMessageRead(
        widget.roomId,
        _handleMessageReadReceived,
      );
    } catch (e) {
      // 에러 무시
    }
  }

  void _handleMessageReceived(Map<String, dynamic> messageData) {
    if (!mounted) {
      return;
    }

    try {
      final message = ChatMessage.fromJson(messageData);

      // 중복 메시지 확인
      final isDuplicate = _messages.any(
        (existingMessage) => existingMessage.messageId == message.messageId,
      );

      if (isDuplicate) {
        return;
      }

      // 메시지 추가를 한 번에 처리하여 렌더링 최적화
      _messages.add(message);

      // 메시지 ID 기준으로 다시 정렬
      _messages.sort((a, b) {
        final aId = a.messageId ?? 0;
        final bId = b.messageId ?? 0;
        return aId.compareTo(bId);
      });

      if (mounted) {
        setState(() {
          // UI 업데이트만 트리거
        });
      }

      // 새로운 메시지 빠른 읽음 처리
      if (message.senderUserId != _currentUserId && message.messageId != null) {
        Future.delayed(const Duration(milliseconds: 100), () async {
          if (mounted) {
            await ChatService.sendMessageRead(
              roomId: widget.roomId,
              messageIds: [message.messageId!],
            );
          }
        });
      }

      // 스크롤을 맨 아래로 즉시 이동 (더 빠르게)
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    } catch (e) {
      // 에러 무시
    }
  }

  void _handleMessageReadReceived(Map<String, dynamic> readData) {
    try {
      final messageIds = readData['messageIds'] as List<dynamic>? ?? [];
      final readByUserId = readData['readByUserId'] as int?;

      if (messageIds.isNotEmpty && mounted) {
        setState(() {
          // 읽음 처리 UI 업데이트 로직 (필요시 구현)
        });
      }
    } catch (e) {
      // 에러 무시
    }
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
                    color: Color(0xFF146AFF),
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

  Widget _buildMessage(ChatMessage message, int index) {
    final isSystemMessage = message.senderUserId == 0;
    final isMe = !isSystemMessage && message.senderUserId == _currentUserId;
    final isHighlighted =
        _searchResults.contains(index) &&
        _currentSearchIndex >= 0 &&
        _currentSearchIndex < _searchResults.length &&
        _searchResults[_currentSearchIndex] == index;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration:
          isHighlighted
              ? BoxDecoration(
                color: Colors.yellow.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              )
              : null,
      child: Column(
        children: [
          // 시스템 메시지
          if (isSystemMessage)
            _buildSystemMessage(message)
          // 내 메시지
          else if (isMe)
            _buildMyMessage(message)
          // 다른 사람 메시지
          else
            _buildOtherMessage(message),
        ],
      ),
    );
  }

  // 시스템 메시지 위젯
  Widget _buildSystemMessage(ChatMessage message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF999999).withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            message.content,
            style: TextStyle(
              color: const Color(0xFF666666),
              fontSize: 12,
              fontFamily: 'Pretendard-Light',
              letterSpacing: -0.24,
            ),
            textAlign: TextAlign.center,
            softWrap: true,
          ),
        ),
      ),
    );
  }

  Widget _buildOtherMessage(ChatMessage message) {
    // 그룹채팅에서는 실제 발신자 이름 사용, 1:1채팅에서는 상대방 이름 사용
    final senderName = _isGroupChat ? (message.senderName ?? '알 수 없음') : widget.userName;
    final senderAvatar = _isGroupChat ? (message.senderProfileImageUrl ?? '') : widget.avatar;
    
    // 디버그 로그
    print('🔍 메시지 발신자 정보 (메시지 ID: ${message.messageId}):');
    print('  - _isGroupChat: $_isGroupChat');
    print('  - message.senderName: "${message.senderName}"');
    print('  - widget.userName: "${widget.userName}"');
    print('  - 최종 senderName: "$senderName"');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8),
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
                          ? Icon(
                            Icons.person,
                            color: Color(0xFF999999),
                            size: 20,
                          )
                          : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      senderName,
                      style: TextStyle(
                        color: const Color(0xFF202020),
                        fontSize: 14,
                        fontFamily: 'Pretendard-Bold',
                        letterSpacing: -0.28,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // 메시지 버블과 시간
          Padding(
            padding: const EdgeInsets.only(left: 48),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Flexible(
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.7,
                        minWidth: 60,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: ShapeDecoration(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(18),
                            bottomLeft: Radius.circular(18),
                            bottomRight: Radius.circular(18),
                          ),
                        ),
                      ),
                      child: Text(
                        message.content,
                        style: TextStyle(
                          color: const Color(0xFF4A4A4A),
                          fontSize: 14,
                          fontFamily: 'Pretendard-Regular',
                          letterSpacing: -0.28,
                          height: 1.4,
                        ),
                        softWrap: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      _formatMessageTime(message),
                      style: TextStyle(
                        color: const Color(0xFFC4C4C4),
                        fontSize: 10,
                        fontFamily: 'Pretendard-Light',
                        letterSpacing: -0.20,
                      ),
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

  Widget _buildMyMessage(ChatMessage message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: IntrinsicHeight(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                _formatMessageTime(message),
                style: TextStyle(
                  color: const Color(0xFFC4C4C4),
                  fontSize: 10,
                  fontFamily: 'Pretendard-Light',
                  letterSpacing: -0.20,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.7,
                  minWidth: 60,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: ShapeDecoration(
                  color: const Color(0xFF146AFF), // 부모단 테마 색상
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(18),
                      topRight: Radius.circular(18),
                      bottomLeft: Radius.circular(18),
                    ),
                  ),
                ),
                child: Text(
                  message.content,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontFamily: 'Pretendard-Regular',
                    letterSpacing: -0.28,
                    height: 1.4,
                  ),
                  softWrap: true,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 검색 기능
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
      if (_messages[i].content.toLowerCase().contains(query.toLowerCase())) {
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
        color: Colors.white.withOpacity(0.9),
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
                  hintText: '채팅 내용 검색 해주세요.',
                  fillColor: const Color(0xFFE7ECF6),
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
                ),
                onChanged: _performSearch,
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (_searchResults.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF146AFF),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFE7ECF6),
          image:
              _backgroundImagePath != null
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
              icon: Image.asset(
                'assets/icons/parent/뒤로가기.png',
                width: 24,
                height: 24,
                fit: BoxFit.contain,
                errorBuilder:
                    (context, error, stackTrace) => const Icon(
                      Icons.arrow_back_ios,
                      color: Color(0xFF202020),
                    ),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              _roomName.isNotEmpty ? _roomName : widget.userName,
              style: TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontFamily: 'Pretendard-Bold',
                letterSpacing: -0.32,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: Image.asset(
                  'assets/images/search.png',
                  width: 24,
                  height: 24,
                  color: const Color(0xFF202020),
                ),
                onPressed: _startSearch,
              ),
              IconButton(
                icon: Image.asset(
                  'assets/icons/Icon/chat/menu.png',
                  width: 24,
                  height: 24,
                  fit: BoxFit.contain,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ParentChatRoomMenuScreen(
                        userName: widget.userName,
                        avatar: widget.avatar,
                        roomId: widget.roomId,
                        userId: widget.userId,
                      ),
                    ),
                  ).then((result) {
                    // 채팅방 메뉴에서 돌아왔을 때 결과 처리
                    if (result != null && result['action'] == 'update_room_name') {
                      final newName = result['newName'] as String?;
                      final success = result['success'] as bool? ?? false;
                      
                                              if (success && newName != null) {
                          // 채팅방 이름이 변경되었을 때 상단 제목 업데이트
                          setState(() {
                            _roomName = newName;
                          });
                          print('✅ 부모단 채팅 상세 화면 제목 업데이트: $newName');
                        }
                        
                        // 채팅 목록으로 결과 전달
                        Navigator.pop(context, result);
                    }
                  });
                },
              ),
            ],
          ),
          body: Column(
            children: [
              if (_isSearching) _buildSearchBar(),
              if (!_isSearching)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    _getCurrentDate(),
                    style: TextStyle(
                      color: const Color(0xFFC4C4C4),
                      fontSize: 12,
                      fontFamily: 'Pretendard-Light',
                      letterSpacing: -0.24,
                    ),
                  ),
                ),
              Expanded(
                child:
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _messages.isEmpty
                        ? Center(
                          child: Text(
                            '새로운 메시지를 보내보세요!',
                            style: TextStyle(
                              color: const Color(0xFF999999),
                              fontSize: 14,
                              fontFamily: 'Pretendard-Light',
                            ),
                          ),
                        )
                        : ListView.builder(
                          controller: _scrollController,
                          itemCount: _messages.length,
                          physics: const ClampingScrollPhysics(), // 더 부드러운 스크롤
                          cacheExtent: 1000, // 렌더링 캐시 확장
                          addAutomaticKeepAlives: false, // 메모리 효율성
                          addRepaintBoundaries: false, // 리페인트 경계 제거로 성능 향상
                          itemBuilder: (context, index) {
                            return RepaintBoundary(
                              // 개별 메시지 리페인트 경계
                              child: _buildMessage(_messages[index], index),
                            );
                          },
                        ),
              ),
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
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
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
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                      fillColor: Colors.transparent,
                                      filled: false,
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
                                GestureDetector(
                                  onTap: () {
                                    if (_messageController.text
                                        .trim()
                                        .isNotEmpty) {
                                      _sendMessage();
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    child: Image.asset(
                                      'assets/icons/Icon/chat/send.png',
                                      width: 28,
                                      height: 28,
                                      fit: BoxFit.contain,
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
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMediaOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Container(
            width: MediaQuery.of(context).size.width,
            constraints: BoxConstraints(maxHeight: 200, minHeight: 164),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 상단 메시지 입력 영역
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(color: Colors.white),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              width: 28,
                              height: 28,
                              child: Icon(
                                Icons.close,
                                size: 24,
                                color: Color(0xFF999999),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              height: 38,
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
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 16),
                                  child: Text(
                                    '메시지를 입력해 주세요',
                                    style: TextStyle(
                                      color: const Color(0xFF999999),
                                      fontSize: 12,
                                      fontFamily: 'Pretendard',
                                      fontWeight: FontWeight.w300,
                                      letterSpacing: -0.24,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // 하단 옵션 영역
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(color: Colors.white),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          const SizedBox(width: 16),
                          // 촬영 옵션
                          GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                              _pickImageFromCamera();
                            },
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Image.asset(
                                  'assets/icons/Icon/chat/photo.png',
                                  width: 60,
                                  height: 60,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  '촬영',
                                  style: TextStyle(
                                    color: const Color(0xFF8490A3),
                                    fontSize: 12,
                                    fontFamily: 'Pretendard',
                                    fontWeight: FontWeight.w300,
                                    letterSpacing: -0.24,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 24),

                          // 앨범 옵션
                          GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                              _pickImage();
                            },
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Image.asset(
                                  'assets/icons/Icon/chat/gallery.png',
                                  width: 60,
                                  height: 60,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  '앨범',
                                  style: TextStyle(
                                    color: const Color(0xFF8490A3),
                                    fontSize: 12,
                                    fontFamily: 'Pretendard',
                                    fontWeight: FontWeight.w300,
                                    letterSpacing: -0.24,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
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
            child: Icon(icon, color: const Color(0xFF146AFF), size: 30),
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

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? pickedImage = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (pickedImage != null) {
        final result = await ChatService.sendMessage(
          roomId: widget.roomId,
          content: pickedImage.path,
          messageType: 'IMAGE',
        );

        if (result == null || result['success'] != true) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('카메라 이미지 전송에 실패했습니다.')));
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('카메라 이미지 촬영 중 오류가 발생했습니다: $e')));
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedImage = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (pickedImage != null) {
        final result = await ChatService.sendMessage(
          roomId: widget.roomId,
          content: pickedImage.path,
          messageType: 'IMAGE',
        );

        if (result == null || result['success'] != true) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('이미지 전송에 실패했습니다.')));
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('이미지 선택 중 오류가 발생했습니다: $e')));
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    try {
      // 입력창 먼저 비우기
      final originalText = text;
      _messageController.clear();

      // 전송 전 메시지 수 기록
      final messageCountBeforeSend = _messages.length;

      // 서버로 메시지 전송
      final result = await ChatService.sendMessage(
        roomId: widget.roomId,
        content: text,
        messageType: 'TEXT',
      );

      if (result != null && result['success'] == true) {
        // WebSocket 실시간 수신 대기 (1초)
        bool messageReceived = false;

        // 0.3초마다 메시지 수신 체크
        Timer.periodic(const Duration(milliseconds: 300), (timer) {
          if (mounted && _messages.length > messageCountBeforeSend) {
            messageReceived = true;
            timer.cancel();
          }
          if (timer.tick >= 4) {
            // 1.2초 대기
            timer.cancel();
          }
        });

        // 1초 후 타임아웃 처리
        Timer(const Duration(seconds: 1), () async {
          if (!messageReceived && mounted) {
            await _loadChatRoomDetails(setupWebSocket: false);

            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_scrollController.hasClients && _messages.isNotEmpty) {
                _scrollController.animateTo(
                  _scrollController.position.maxScrollExtent,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                );
              }
            });
          }
        });
      } else if (result != null && result['error'] == 'BLOCKED_USER') {
        // 입력창에 원래 텍스트 복원
        _messageController.text = originalText;
        _showErrorDialog('전송 불가', '차단된 사용자에게는 메시지를 전송할 수 없습니다.');
      } else {
        // 입력창에 원래 텍스트 복원
        _messageController.text = originalText;

        final errorMessage = result?['message'] ?? '메시지 전송에 실패했습니다.';
        _showErrorDialog('전송 실패', errorMessage);
      }
    } catch (e) {
      // 입력창에 원래 텍스트 복원
      _messageController.text = text;
      _showErrorDialog('오류', '메시지 전송 중 오류가 발생했습니다: $e');
    }
  }
}

// 비디오 플레이어 화면
class VideoPlayerScreen extends StatefulWidget {
  final String videoPath;

  const VideoPlayerScreen({super.key, required this.videoPath});

  @override
  _VideoPlayerScreenState createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initVideoPlayer();
  }

  Future<void> _initVideoPlayer() async {
    _controller = VideoPlayerController.file(File(widget.videoPath));
    try {
      await _controller.initialize();
      _controller.play();
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '비디오를 재생할 수 없습니다: $e',
            style: const TextStyle(
              fontFamily: 'Pretendard-Regular',
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child:
            _isInitialized
                ? AspectRatio(
                  aspectRatio: _controller.value.aspectRatio,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      VideoPlayer(_controller),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            if (_controller.value.isPlaying) {
                              _controller.pause();
                            } else {
                              _controller.play();
                            }
                          });
                        },
                        child: Container(
                          color: Colors.transparent,
                          child: Center(
                            child: Icon(
                              _controller.value.isPlaying
                                  ? Icons.pause
                                  : Icons.play_arrow,
                              size: 60.0,
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
                : const CircularProgressIndicator(),
      ),
    );
  }
}
