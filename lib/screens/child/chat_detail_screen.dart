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
import '../../services/relationship_service.dart';
import '../../services/chat_background_service.dart';
import '../../models/chat_message.dart';
import '../../widgets/chat/chat_message_item.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'chat/friend_list_screen.dart';
import 'chat/detail/chat_room_menu_screen.dart';

class ChatDetailScreen extends StatefulWidget {
  final String userName;
  final String avatar;
  final int roomId;
  final int userId;

  const ChatDetailScreen({
    super.key,
    required this.userName,
    required this.avatar,
    required this.roomId,
    required this.userId,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _showQuickReplies = false;
  String _selectedQuickReply = "";
  final ImagePicker _picker = ImagePicker();
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  Timer? _timer;
  Duration _timeRemaining = const Duration(hours: 7, minutes: 9, seconds: 39);
  String _timerText = '수락까지 07:09:39';
  bool _isLoading = false;
  int? _currentUserId;
  String? _backgroundImagePath;

  // 검색 관련 변수들
  bool _isSearching = false;
  String _searchQuery = '';
  List<int> _searchResults = [];
  int _currentSearchIndex = -1;

  // 디버그 로그 (제거됨)
  List<String> _debugLogs = [];

  // 채팅방 정보
  String _roomName = '';

  @override
  void initState() {
    super.initState();
    print('🚀🚀🚀🚀🚀 [ChatDetailScreen] initState 실행됨! 🚀🚀🚀🚀🚀');
    print('🚀🚀🚀🚀🚀 채팅방 ID: ${widget.roomId} 🚀🚀🚀🚀🚀');
    print('🚀🚀🚀🚀🚀 _initializeChat() 호출 직전 🚀🚀🚀🚀🚀');
    _initializeChat();
    _startTimer();
    print('🚀🚀🚀🚀🚀 initState 완료! 🚀🚀🚀🚀🚀');
  }

  @override
  void dispose() {
    _timer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();

    print('=== 🔌 채팅방 나가기 시작 ===');
    print('채팅방 ID: ${widget.roomId}');

    // 채팅방 나가기 전 마지막 읽음 처리 시도
    _performFinalReadProcessing();

    // WebSocket 구독 해제
    ChatService.unsubscribeFromChatRoom(widget.roomId);
    ChatService.unsubscribeFromMessageRead(widget.roomId);

    print('구독 해제 후 상태:');
    ChatService.printSubscriptionStatus();

    super.dispose();
  }

  // WebSocket 우선, 실패 시 REST API로 읽음 처리 시도
  Future<bool> _sendReadWithFallback(List<int> messageIds) async {
    if (messageIds.isEmpty) return true;

    try {
      print('📖 WebSocket을 통한 읽음 처리 시도...');

      // 1차: WebSocket을 통한 읽음 처리 시도
      final webSocketSuccess = await ChatService.sendMessageRead(
        roomId: widget.roomId,
        messageIds: messageIds,
      );

      if (webSocketSuccess) {
        print('✅ WebSocket 읽음 처리 성공');
        return true;
      }

      print('⚠️ WebSocket 읽음 처리 실패 - REST API로 개별 처리 시도');

      // 2차: REST API를 통한 개별 읽음 처리 시도
      int successCount = 0;
      for (final messageId in messageIds) {
        try {
          final success = await ChatService.markMessageAsRead(messageId);
          if (success) {
            successCount++;
            print('✅ REST API 개별 읽음 처리 성공: messageId $messageId');
          } else {
            print('❌ REST API 개별 읽음 처리 실패: messageId $messageId');
          }

          // 과도한 API 호출 방지를 위한 짧은 대기
          await Future.delayed(const Duration(milliseconds: 100));
        } catch (e) {
          print('❌ REST API 개별 읽음 처리 중 오류: messageId $messageId, 오류: $e');
        }
      }

      final allSuccess = successCount == messageIds.length;
      print('📖 REST API 읽음 처리 결과: $successCount/${messageIds.length} 성공');

      if (successCount > 0) {
        print('✅ 부분적 읽음 처리 성공 (${successCount}개)');
        return true; // 일부라도 성공하면 true 반환
      }

      return false;
    } catch (e) {
      print('❌ 읽음 처리 대체 방법 중 오류: $e');
      return false;
    }
  }

  // 채팅방 나가기 전 마지막 읽음 처리
  void _performFinalReadProcessing() {
    if (_currentUserId == null || _messages.isEmpty) {
      print('⚠️ 마지막 읽음 처리 건너뜀 - 사용자 ID 없음 또는 메시지 없음');
      return;
    }

    try {
      print('=== 📖 채팅방 나가기 전 마지막 읽음 처리 시작 ===');

      // 현재 화면에 있는 모든 메시지 중 내가 보내지 않은 메시지들 찾기
      final unreadMessages =
          _messages.where((message) {
            return message.messageId != null &&
                message.senderUserId != _currentUserId && // 내가 보낸 메시지 제외
                message.senderUserId != 0; // 시스템 메시지 제외
          }).toList();

      if (unreadMessages.isNotEmpty) {
        final messageIds = unreadMessages.map((msg) => msg.messageId!).toList();
        print('📖 마지막 읽음 처리할 메시지 IDs: $messageIds');

        // 비동기 읽음 처리 (dispose 중이므로 await 하지 않음)
        ChatService.sendMessageRead(
              roomId: widget.roomId,
              messageIds: messageIds,
            )
            .then((success) {
              if (success) {
                print('✅ 채팅방 나가기 전 마지막 읽음 처리 성공: ${messageIds.length}개');
              } else {
                print('❌ 채팅방 나가기 전 마지막 읽음 처리 실패');
              }
            })
            .catchError((error) {
              print('❌ 채팅방 나가기 전 읽음 처리 중 오류: $error');
            });
      } else {
        print('📖 마지막 읽음 처리할 메시지가 없음');
      }

      print('=== 📖 채팅방 나가기 전 마지막 읽음 처리 완료 ===');
    } catch (e) {
      print('❌ 마지막 읽음 처리 중 오류: $e');
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_timeRemaining.inSeconds > 0) {
            _timeRemaining = _timeRemaining - const Duration(seconds: 1);
            _updateTimerText();
          } else {
            _timer?.cancel();
          }
        });
      }
    });
  }

  void _updateTimerText() {
    final hours = _timeRemaining.inHours;
    final minutes = _timeRemaining.inMinutes.remainder(60);
    final seconds = _timeRemaining.inSeconds.remainder(60);

    _timerText =
        '수락까지 ${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    for (var message in _messages) {
      if (message.messageType == MessageType.missionCard &&
          message.missionData != null) {
        final missionData = Map<String, dynamic>.from(message.missionData!);
        missionData['timeRecorded'] = _timerText;
        message = message.copyWith(missionData: missionData);
      }
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
        print('=== 🔍 채팅 초기화 디버그 ===');
        print('현재 사용자 ID: ${_currentUserId}');
        print('채팅방 ID: ${widget.roomId}');
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
      print('🧹 WebSocket 구독 정리 시작...');
      ChatService.printSubscriptionStatus(); // 현재 상태 확인

      // 과도한 구독 정리 (최대 5개까지만 유지)
      ChatService.cleanupExcessiveSubscriptions(maxSubscriptions: 5);

      print('🧹 구독 정리 완료');
      ChatService.printSubscriptionStatus(); // 정리 후 상태 확인

      print('WebSocket 초기화 시작...');
      await ChatService.initializeWebSocket();

      // 이전 메시지 먼저 로드 (WebSocket 구독은 _loadChatRoomDetails에서 처리)
      print('💡💡💡 [하이브리드] 이전 메시지 로드 시작 💡💡💡');
      print('💡💡💡 채팅방 ID: ${widget.roomId} 💡💡💡');

      await _loadChatRoomDetails();
    } catch (e) {
      print('❌ 채팅 초기화 실패: $e');
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _debugLogs.add('초기화 실패: $e');
        if (_debugLogs.length > 10) {
          _debugLogs.removeAt(0);
        }
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
    print('📥 채팅방 상세 정보 로드 시작');
    try {
      // 서버에서 lastSendMessageId 받아오기
      final roomDetails = await ChatService.getChatRoomDetails(widget.roomId);
      int lastMessageId = 999999; // 기본값을 더 큰 값으로 설정

      // 채팅방 정보 먼저 업데이트 (메시지 로드 실패와 무관하게)
      if (roomDetails != null && mounted) {
        final roomRange = roomDetails['roomRange'];
        final participantCount = roomDetails['participantCount'] ?? 0;
        final participantNameList =
            roomDetails['participantNameList'] as List<dynamic>? ?? [];

        setState(() {
          _roomName = roomDetails['roomName'] ?? widget.userName;
        });

        print('🔍 채팅방 roomRange: $roomRange');
        print('🔍 채팅방 참여자 수: $participantCount');
        print(
          '🔍 채팅방 참여자 이름 목록: $participantNameList (${participantNameList.length}명)',
        );
        print('🔍 채팅방 이름: $_roomName');
      }

      if (roomDetails != null && roomDetails['lastSendMessageId'] is int) {
        lastMessageId =
            roomDetails['lastSendMessageId'] + 1; // +1을 추가해서 최신 메시지까지 포함
        print(
          '🔍 서버에서 받은 lastSendMessageId: ${roomDetails['lastSendMessageId']}',
        );
        print('🔍 조회에 사용할 lastMessageId: $lastMessageId');
      }

      print('🔍 모든 메시지 로드 시작 - lastMessageId: $lastMessageId');

      // 모든 메시지를 가져오기 위해 페이징 반복
      List<ChatMessage> allMessages = [];
      Set<int> addedMessageIds = {}; // 중복 방지를 위한 Set
      int currentPage = 0;
      bool hasMoreMessages = true;
      int? startMessageId;
      int? endMessageId;
      int totalPages = 0;
      bool messageLoadFailed = false;

      while (hasMoreMessages) {
        try {
          final messages = await ChatService.getChatRoomMessages(
            widget.roomId,
            lastMessageId: lastMessageId,
            pageNumber: currentPage,
          );

          print('🔍 페이지 $currentPage 조회 완료 - 메시지 수: ${messages.length}');

          if (messages.isEmpty) {
            hasMoreMessages = false;
          } else {
            // 서버에서 중복 데이터가 올 수 있으므로 messageId로 중복 제거
            int addedInThisPage = 0;
            for (final message in messages) {
              final messageId = message.messageId;
              if (messageId != null && !addedMessageIds.contains(messageId)) {
                allMessages.add(message);
                addedMessageIds.add(messageId);
                addedInThisPage++;
                print('✅ 메시지 추가: ID=$messageId, 내용="${message.content}"');
              } else if (messageId != null) {
                print('⚠️ 중복 메시지 제거: ID=$messageId, 내용="${message.content}"');
              } else {
                print('⚠️ messageId가 null인 메시지 제거: 내용="${message.content}"');
              }
            }

            print('🔍 페이지 $currentPage - 실제 추가된 메시지: $addedInThisPage개');

            // 이벤트 로그 조회를 위한 정보 저장
            if (currentPage == 0) {
              totalPages = currentPage + 1; // 첫 페이지는 최소 1
            } else {
              totalPages = currentPage + 1;
            }

            currentPage++;

            // 안전장치: 너무 많은 페이지 방지 (최대 50페이지)
            if (currentPage >= 50) {
              print('⚠️ 최대 페이지 수 도달로 로드 중단');
              hasMoreMessages = false;
            }
          }
        } catch (e) {
          print('❌ 메시지 조회 실패 (페이지 $currentPage): $e');
          messageLoadFailed = true;
          hasMoreMessages = false;

          // 메시지 로드 실패해도 채팅방 정보는 유지하고 빈 상태로 처리
          if (mounted) {
            setState(() {
              _isLoading = false;
              _debugLogs.add('메시지 조회 실패: $e');
              if (_debugLogs.length > 10) {
                _debugLogs.removeAt(0);
              }
            });

            // 사용자에게 메시지 로드 실패 알림
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('메시지를 불러오는데 실패했습니다. 새로고침해주세요.'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 3),
              ),
            );
          }
        }
      }

      print('🔍 전체 메시지 로드 완료 - 총 메시지 수: ${allMessages.length}');

      if (!mounted) return;

      // messageId 기준으로 오름차순 정렬 (오래된 메시지가 앞, 최신 메시지가 뒤)
      allMessages.sort((a, b) {
        final aId = a.messageId ?? 0;
        final bId = b.messageId ?? 0;
        return aId.compareTo(bId);
      });

      print('🔄 메시지 ID 기준 정렬 완료');
      if (allMessages.isNotEmpty) {
        print('정렬 후 첫 번째 메시지 ID: ${allMessages.first.messageId}');
        print('정렬 후 마지막 메시지 ID: ${allMessages.last.messageId}');

        // 이벤트 로그 조회를 위한 파라미터 설정
        startMessageId = allMessages.first.messageId ?? 0; // 가장 오래된 메시지
        endMessageId = allMessages.last.messageId ?? 0; // 가장 최근 메시지
      }

      // 📜 채팅방 이벤트 로그 조회 (메시지 조회 직후)
      List<Map<String, dynamic>> eventLogs = [];
      if (allMessages.isNotEmpty) {
        print('📜 채팅방 이벤트 로그 조회 시작...');

        // 메시지 데이터를 Map 형태로 변환
        final messageDataForLog =
            allMessages
                .map(
                  (msg) => {
                    'messageId': msg.messageId,
                    'content': msg.content,
                    'timestamp': msg.time,
                  },
                )
                .toList();

        final logs = await ChatService.getChatEventLogs(
          widget.roomId,
          totalPages: totalPages,
          messageData: messageDataForLog,
        );

        if (logs != null) {
          eventLogs = logs;
          print('📜 이벤트 로그 ${eventLogs.length}개 조회 완료');

          // 이벤트 로그를 시스템 메시지로 변환하여 메시지 목록에 추가
          for (final log in eventLogs) {
            final eventMessage = ChatMessage(
              messageId: null, // 시스템 메시지는 ID 없음
              content: log['message'] ?? '시스템 메시지',
              messageType: MessageType.text,
              time: log['timestamp'] ?? DateTime.now().toIso8601String(),
              readCount: 0,
              senderUserId: 0, // 시스템 메시지
              senderName: '시스템',
              senderProfileImageUrl: null,
              isFriend: false,
              customName: null,
              isBestFriend: false,
              isBlocked: false,
            );

            // 시간 순으로 적절한 위치에 삽입
            final eventTime = DateTime.tryParse(eventMessage.time);
            if (eventTime != null) {
              int insertIndex = allMessages.indexWhere((msg) {
                final msgTime = DateTime.tryParse(msg.time);
                return msgTime != null && msgTime.isAfter(eventTime);
              });
              if (insertIndex == -1) {
                allMessages.add(eventMessage); // 맨 뒤에 추가
              } else {
                allMessages.insert(insertIndex, eventMessage); // 시간순 위치에 삽입
              }
            }
          }
        } else {
          print('📜 이벤트 로그 조회 실패');
        }
      }

      // 메시지 업데이트를 한 번에 처리하여 렌더링 최적화
      _messages.clear(); // 기존 메시지 초기화
      _messages.addAll(allMessages); // 오래된 메시지가 위, 최신 메시지가 아래로 정순 정렬

      // 디버깅용 로그
      _debugLogs.add('전체 메시지 ${allMessages.length}개 로드됨 (${totalPages}페이지)');
      _debugLogs.add('이벤트 로그 ${eventLogs.length}개 조회됨');
      if (messageLoadFailed) {
        _debugLogs.add('⚠️ 메시지 조회 중 서버 오류 발생');
      }
      if (_debugLogs.length > 10) {
        _debugLogs.removeAt(0);
      }

      print('📥 전체 메시지 로드 완료: ${allMessages.length}개');
      if (allMessages.isNotEmpty) {
        print('첫 번째 메시지 ID: ${allMessages.first.messageId}');
        print('마지막 메시지 ID: ${allMessages.last.messageId}');
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }

      // WebSocket 구독 설정이 필요한 경우에만 실행
      if (setupWebSocket) {
        print('💡💡💡 [하이브리드] 메시지 로드 완료 후 WebSocket 구독 시작 💡💡💡');
        await _setupWebSocketSubscription();
      } else {
        print('💡💡💡 [하이브리드] 메시지만 다시 로드됨 (WebSocket 구독 유지) 💡💡💡');
      }

      // 채팅방 진입 시 안읽은 메시지들 읽음 처리
      if (setupWebSocket && !messageLoadFailed) {
        await _markUnreadMessagesAsRead();
      }

      // 메시지 로드 완료 후 맨 아래로 즉시 스크롤 (더 빠르게)
      if (_scrollController.hasClients && _messages.isNotEmpty) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    } catch (e, stackTrace) {
      print('❌ 채팅방 상세 정보 로드 실패: $e');
      print('❌ 스택 트레이스: $stackTrace');
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _debugLogs.add('로드 실패: $e');
        if (_debugLogs.length > 10) {
          _debugLogs.removeAt(0);
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('메시지를 불러오는데 실패했습니다: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // 채팅방 진입 시 안읽은 메시지들 읽음 처리
  Future<void> _markUnreadMessagesAsRead() async {
    if (_currentUserId == null || _messages.isEmpty) {
      print('⚠️ 읽음 처리 건너뜀 - 사용자 ID 없음 또는 메시지 없음');
      return;
    }

    try {
      print('=== 📖 채팅방 진입 시 안읽은 메시지 읽음 처리 시작 ===');

      // 채팅방 상세 정보에서 마지막 읽은 메시지 ID 가져오기
      final roomDetails = await ChatService.getChatRoomDetails(widget.roomId);
      if (roomDetails == null) {
        print('❌ 채팅방 상세 정보 조회 실패');
        return;
      }

      final lastReadMessageId = roomDetails['lastReadMessageId'] as int? ?? 0;
      print('📖 마지막 읽은 메시지 ID: $lastReadMessageId');

      // 마지막 읽은 메시지 이후의 안읽은 메시지들 찾기 (내가 보낸 메시지 제외)
      final unreadMessages =
          _messages.where((message) {
            return message.messageId != null &&
                message.messageId! > lastReadMessageId &&
                message.senderUserId != _currentUserId && // 내가 보낸 메시지 제외
                message.senderUserId != 0; // 시스템 메시지 제외
          }).toList();

      if (unreadMessages.isNotEmpty) {
        final unreadMessageIds =
            unreadMessages.map((msg) => msg.messageId!).toList();
        print('📖 읽음 처리할 안읽은 메시지 IDs: $unreadMessageIds');

        // WebSocket 읽음 처리 API 호출
        final success = await ChatService.sendMessageRead(
          roomId: widget.roomId,
          messageIds: unreadMessageIds,
        );

        if (success) {
          print('✅ 채팅방 진입 시 안읽은 메시지 ${unreadMessageIds.length}개 읽음 처리 완료');

          if (mounted) {
            setState(() {
              _debugLogs.add('진입 시 읽음 처리: ${unreadMessageIds.length}개 메시지');
              if (_debugLogs.length > 10) {
                _debugLogs.removeAt(0);
              }
            });
          }
        } else {
          print('❌ 채팅방 진입 시 안읽은 메시지 읽음 처리 실패 (WebSocket 문제일 수 있음)');

          if (mounted) {
            setState(() {
              _debugLogs.add('읽음 처리 실패: WebSocket 연결 문제');
              if (_debugLogs.length > 10) {
                _debugLogs.removeAt(0);
              }
            });
          }
        }
      } else {
        print('📖 읽을 안읽은 메시지가 없음');
      }

      print('=== 📖 채팅방 진입 시 안읽은 메시지 읽음 처리 완료 ===');
    } catch (e) {
      print('❌ 안읽은 메시지 읽음 처리 중 오류: $e');

      if (mounted) {
        setState(() {
          _debugLogs.add('읽음 처리 오류: $e');
          if (_debugLogs.length > 10) {
            _debugLogs.removeAt(0);
          }
        });
      }
    }
  }

  Future<void> _setupWebSocketSubscription() async {
    try {
      print('🔌 WebSocket 구독 설정 시작');

      // 현재 사용자 정보 확인
      final userInfo = await AuthService.getUserInfo();
      final userId = userInfo?['userId'];
      print('현재 사용자 ID: $userId');
      print('채팅방 ID: ${widget.roomId}');
      print('위젯에서 받은 userId: ${widget.userId}');

      if (userId == null) {
        print('❌ 사용자 ID를 가져올 수 없습니다.');
        return;
      }

      // 구독 경로 확인
      final expectedMessagePath = '/sub/chat/${widget.roomId}/$userId';
      final expectedReadPath = '/sub/chat/read/${widget.roomId}';
      print('예상 메시지 구독 경로: $expectedMessagePath');
      print('예상 읽음 처리 구독 경로: $expectedReadPath');

      // 사용자 ID와 위젯 userId 비교
      if (userId != widget.userId) {
        print('⚠️ 사용자 ID 불일치: AuthService=$userId, Widget=${widget.userId}');
      }

      // 구독 전 상태 확인
      print('구독 전 WebSocket 상태:');
      ChatService.printSubscriptionStatus();

      // 채팅방 메시지 구독
      print('📡 메시지 구독 시작...');
      await ChatService.subscribeToChatRoom(
        widget.roomId,
        _handleMessageReceived,
      );

      // 메시지 읽음 처리 구독
      print('📖 읽음 처리 구독 시작...');
      await ChatService.subscribeToMessageRead(
        widget.roomId,
        _handleMessageReadReceived,
      );

      // 채팅방 초대 알림 구독
      print('👥 초대 알림 구독 시작...');
      await ChatService.subscribeToRoomInvite(
        widget.roomId,
        _handleRoomInviteReceived,
      );

      // 채팅방 나가기 알림 구독
      print('🚪 나가기 알림 구독 시작...');
      print('🚪 나가기 알림 구독 경로: /sub/chat/room-leave/${widget.roomId}/$userId');
      print('🚪 나가기 알림이 수신되면 _handleRoomLeaveReceived 호출됨');
      await ChatService.subscribeToRoomLeave(
        widget.roomId,
        _handleRoomLeaveReceived,
      );
      print('🚪 나가기 알림 구독 완료');

      // 구독 후 상태 확인
      print('구독 후 WebSocket 상태:');
      ChatService.printSubscriptionStatus();

      print('✅ WebSocket 구독 설정 완료');

      if (mounted) {
        setState(() {
          _debugLogs.add('WebSocket 구독 완료 - 경로: $expectedMessagePath');
          if (_debugLogs.length > 10) {
            _debugLogs.removeAt(0);
          }
        });
      }

      // 테스트 메시지 확인을 위한 추가 로깅
      print('🧪 WebSocket 테스트 - 이제 메시지를 보내면 실시간으로 수신되어야 합니다.');
      print('🧪 구독된 경로: $expectedMessagePath, $expectedReadPath');

      // 구독 후 1초 뒤에 상태 재확인
      Future.delayed(const Duration(seconds: 1), () {
        print('🔍 1초 후 구독 상태 재확인:');
        ChatService.printSubscriptionStatus();
      });
    } catch (e) {
      print('❌ WebSocket 구독 설정 실패: $e');

      if (mounted) {
        setState(() {
          _debugLogs.add('WebSocket 구독 실패: $e');
          if (_debugLogs.length > 10) {
            _debugLogs.removeAt(0);
          }
        });
      }
    }
  }

  void _handleMessageReceived(Map<String, dynamic> messageData) {
    print('📩 메시지 수신됨: $messageData');

    if (!mounted) {
      print('❌ 위젯이 마운트되지 않은 상태에서 메시지 수신');
      return;
    }

    try {
      // 시간 포맷팅을 위해 JSON 데이터 수정
      final modifiedMessageData = Map<String, dynamic>.from(messageData);
      if (modifiedMessageData.containsKey('timestamp')) {
        modifiedMessageData['timestamp'] = _formatTime(
          modifiedMessageData['timestamp'],
        );
      }

      final message = ChatMessage.fromJson(modifiedMessageData);
      print('✅ 메시지 파싱 성공: ${message.toString()}');

      // 중복 메시지 확인 - messageId로 중복 체크
      final isDuplicate = _messages.any(
        (existingMessage) => existingMessage.messageId == message.messageId,
      );

      if (isDuplicate) {
        print('⚠️ 중복 메시지 감지됨 - messageId: ${message.messageId}');
        _debugLogs.add('중복 메시지 무시됨: ${message.messageId}');
        return;
      }

      // 메시지 추가를 한 번에 처리하여 렌더링 최적화
      _messages.add(message); // 최신 메시지를 맨 아래에 추가
      _debugLogs.add('새 메시지 추가됨: ${message.messageId}');

      // 디버그 로그가 10개를 넘으면 제거
      if (_debugLogs.length > 10) {
        _debugLogs.removeAt(0);
      }

      // 메시지 ID 기준으로 다시 정렬 (안전장치)
      _messages.sort((a, b) {
        final aId = a.messageId ?? 0;
        final bId = b.messageId ?? 0;
        return aId.compareTo(bId);
      });

      // 디버깅용 로그
      print('현재 메시지 수: ${_messages.length}');
      print('새로 추가된 메시지 ID: ${message.messageId}');
      if (_messages.isNotEmpty) {
        print('정렬 후 마지막 메시지 ID: ${_messages.last.messageId}');
      }

      if (mounted) {
        setState(() {
          // UI 업데이트만 트리거
        });
      }

      // 새로운 메시지 즉시 읽음 처리 (내가 보낸 메시지가 아닌 경우만)
      if (message.senderUserId != _currentUserId && message.messageId != null) {
        print('📖 새 메시지 즉시 읽음 처리 시작 - messageId: ${message.messageId}');

        Future.delayed(const Duration(milliseconds: 500), () async {
          if (mounted) {
            final success = await ChatService.sendMessageRead(
              roomId: widget.roomId,
              messageIds: [message.messageId!],
            );

            if (success) {
              print('✅ 새 메시지 읽음 처리 완료 - messageId: ${message.messageId}');

              setState(() {
                _debugLogs.add('새 메시지 읽음 처리: ${message.messageId}');
                if (_debugLogs.length > 10) {
                  _debugLogs.removeAt(0);
                }
              });
            } else {
              print(
                '❌ 새 메시지 읽음 처리 실패 - messageId: ${message.messageId} (WebSocket 문제)',
              );

              setState(() {
                _debugLogs.add('새 메시지 읽음 처리 실패: ${message.messageId}');
                if (_debugLogs.length > 10) {
                  _debugLogs.removeAt(0);
                }
              });
            }
          }
        });
      }

      // 스크롤을 맨 아래로 즉시 이동 (더 빠르게)
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    } catch (e) {
      print('❌ 메시지 처리 중 오류 발생: $e');
      _debugLogs.add('메시지 처리 오류: $e');
      if (_debugLogs.length > 10) {
        _debugLogs.removeAt(0);
      }
    }
  }

  // 메시지 읽음 처리 수신 핸들러
  void _handleMessageReadReceived(Map<String, dynamic> readData) {
    print('=== 📖 채팅 상세에서 읽음 처리 수신 ===');
    print('읽음 처리 데이터: $readData');

    try {
      final messageIds = readData['messageIds'] as List<dynamic>? ?? [];
      final readByUserId = readData['readByUserId'] as int?;

      if (messageIds.isNotEmpty && mounted) {
        print('📖 읽음 처리된 메시지 IDs: $messageIds');
        print('📖 읽음 처리한 사용자 ID: $readByUserId');

        setState(() {
          _debugLogs.add(
            '읽음 처리 수신: ${messageIds.length}개 메시지 by User $readByUserId',
          );
          if (_debugLogs.length > 10) {
            _debugLogs.removeAt(0);
          }

          // 읽음 처리된 메시지들 표시 (디버깅용)
          for (final messageId in messageIds) {
            final intMessageId =
                messageId is int
                    ? messageId
                    : int.tryParse(messageId.toString());
            if (intMessageId != null) {
              print('✅ 메시지 ID $intMessageId 읽음 처리됨 by User $readByUserId');

              // 해당 메시지 찾기 및 읽음 상태 업데이트
              final messageIndex = _messages.indexWhere(
                (msg) => msg.messageId == intMessageId,
              );
              if (messageIndex != -1) {
                print('📱 UI에서 메시지 ID $intMessageId 읽음 상태 업데이트');
                // TODO: ChatMessage 모델에 readCount 필드가 있다면 여기서 업데이트
                // _messages[messageIndex] = _messages[messageIndex].copyWith(readCount: newReadCount);
              }
            }
          }
        });

        // 읽음 처리 완료 로그
        print('✅ 총 ${messageIds.length}개 메시지의 읽음 처리가 UI에 반영됨');
      }
    } catch (e) {
      print('❌ 읽음 처리 데이터 처리 중 오류: $e');
      setState(() {
        _debugLogs.add('읽음 처리 오류: $e');
        if (_debugLogs.length > 10) {
          _debugLogs.removeAt(0);
        }
      });
    }
  }

  // 채팅방 초대 알림 수신 핸들러
  void _handleRoomInviteReceived(Map<String, dynamic> inviteData) {
    print('=== 👥 채팅방 초대 알림 수신 ===');
    print('초대 알림 데이터: $inviteData');

    try {
      final message = inviteData['message'] as String?;
      final timestamp = inviteData['timestamp'] as String?;
      final roomId = inviteData['roomId'] as int?;

      if (message != null && timestamp != null && mounted) {
        print('👥 초대 메시지: $message');
        print('👥 초대 시간: $timestamp');
        print('👥 채팅방 ID: $roomId');

        // 초대 메시지를 채팅방 화면에 표시
        final inviteMessage = ChatMessage(
          messageId: null, // 시스템 메시지는 ID가 없을 수 있음
          content: message,
          senderUserId: 0, // 시스템 메시지
          senderName: 'System',
          messageType: MessageType.text,
          time: _formatTime(timestamp),
        );

        setState(() {
          _messages.add(inviteMessage);
          _debugLogs.add('초대 알림 수신: $message');
          if (_debugLogs.length > 10) {
            _debugLogs.removeAt(0);
          }
        });

        // 스크롤을 맨 아래로 즉시 이동 (더 빠르게)
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }

        print('✅ 초대 알림이 채팅방에 표시됨');
      }
    } catch (e) {
      print('❌ 초대 알림 데이터 처리 중 오류: $e');
      setState(() {
        _debugLogs.add('초대 알림 오류: $e');
        if (_debugLogs.length > 10) {
          _debugLogs.removeAt(0);
        }
      });
    }
  }

  // 채팅방 나가기 알림 수신 핸들러
  void _handleRoomLeaveReceived(Map<String, dynamic> leaveData) {
    print('=== 🚪 1:1 채팅방 나가기 알림 수신 ===');
    print('🚪 수신 시간: ${DateTime.now()}');
    print('🚪 채팅방 ID: ${widget.roomId}');
    print('🚪 나가기 알림 데이터: $leaveData');
    print('🚪 현재 마운트 상태: $mounted');
    print('🚪 현재 메시지 수: ${_messages.length}');

    try {
      final message = leaveData['message'] as String?;
      final timestamp = leaveData['timestamp'] as String?;
      final roomId = leaveData['roomId'] as int?;
      final endOfDecreaseReadMarkMessageId =
          leaveData['endOfDecreaseReadMarkMessageId'] as int?;

      if (message != null && timestamp != null && mounted) {
        print('🚪 나가기 메시지: $message');
        print('🚪 나간 시간: $timestamp');
        print('🚪 채팅방 ID: $roomId');
        print('🚪 읽음 표시 감소 기준 메시지 ID: $endOfDecreaseReadMarkMessageId');

        // 나가기 메시지를 채팅방 화면에 표시
        final leaveMessage = ChatMessage(
          messageId: DateTime.now().millisecondsSinceEpoch, // 임시 ID로 현재 시간 사용
          content: message,
          senderUserId: 0, // 시스템 메시지
          senderName: 'System',
          messageType: MessageType.system, // 시스템 메시지로 설정
          time: _formatTime(timestamp),
        );

        setState(() {
          _messages.add(leaveMessage);
          _debugLogs.add('나가기 알림 수신: $message');
          if (_debugLogs.length > 10) {
            _debugLogs.removeAt(0);
          }

          // 읽음 표시 감소 처리
          // timestamp 이전에 왔으면서 endOfDecreaseReadMarkMessageId 보다 큰 메시지들의 읽음 표시를 -1
          if (endOfDecreaseReadMarkMessageId != null) {
            print('📖 읽음 표시 감소 처리 시작...');
            final leaveTime = DateTime.tryParse(timestamp);

            if (leaveTime != null) {
              int processedCount = 0;

              for (int i = 0; i < _messages.length; i++) {
                final msg = _messages[i];

                // 조건 확인:
                // 1. timestamp 이전에 온 메시지
                // 2. endOfDecreaseReadMarkMessageId 보다 큰 메시지 ID
                final msgTime = DateTime.tryParse(msg.time);
                if (msgTime != null &&
                    msgTime.isBefore(leaveTime) &&
                    msg.messageId != null &&
                    msg.messageId! > endOfDecreaseReadMarkMessageId &&
                    msg.readCount > 0) {
                  // readCount를 1 감소시킴
                  final updatedMessage = msg.copyWith(
                    readCount: msg.readCount - 1,
                  );

                  _messages[i] = updatedMessage;
                  processedCount++;

                  print(
                    '📖 메시지 ${msg.messageId} 읽음 표시 감소: ${msg.readCount} -> ${updatedMessage.readCount}',
                  );
                }
              }

              print('📖 읽음 표시 감소 처리 완료 - 총 $processedCount개 메시지 처리됨');
            } else {
              print('❌ 나간 시간 파싱 실패: $timestamp');
            }
          }
        });

        // 스크롤을 맨 아래로 즉시 이동 (더 빠르게)
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }

        print('✅ 나가기 알림이 채팅방에 표시됨');
      }
    } catch (e) {
      print('❌ 나가기 알림 데이터 처리 중 오류: $e');
      setState(() {
        _debugLogs.add('나가기 알림 오류: $e');
        if (_debugLogs.length > 10) {
          _debugLogs.removeAt(0);
        }
      });
    }
  }

  // 시간 포맷팅 헬퍼 메서드 (로그 최소화)
  String _formatTime(String? timestamp) {
    if (timestamp == null || timestamp.isEmpty) return _getCurrentTime();

    try {
      // 이미 HH:MM 형식인지 확인
      if (RegExp(r'^\d{1,2}:\d{2}$').hasMatch(timestamp)) {
        return timestamp;
      }

      // ISO 8601 형식 시도 (가장 일반적)
      try {
        final dateTime = DateTime.parse(timestamp);
        final formatted =
            "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
        return formatted;
      } catch (e) {
        // ISO 8601 파싱 실패 시 정규식으로 시간 추출
        if (timestamp.contains(':')) {
          final timeMatch = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(timestamp);
          if (timeMatch != null) {
            final hour = timeMatch.group(1)!.padLeft(2, '0');
            final minute = timeMatch.group(2)!;
            return "$hour:$minute";
          }
        }
      }

      // 모든 파싱 실패 시 현재 시간 반환
      return _getCurrentTime();
    } catch (e) {
      return _getCurrentTime();
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

  Widget _buildMessage(ChatMessage message, int index) {
    // 시스템 메시지 처리 (senderUserId가 0인 경우)
    final isSystemMessage = message.senderUserId == 0;
    final isMe = !isSystemMessage && message.senderUserId == _currentUserId;
    final isHighlighted =
        _searchResults.contains(index) &&
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
            message.content ?? '',
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

  bool _shouldShowDate(int index) {
    // 날짜 표시 로직 비활성화
    return false;
  }

  Widget _buildOtherMessage(ChatMessage message) {
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
                        widget.avatar.isNotEmpty
                            ? DecorationImage(
                              image: CachedNetworkImageProvider(
                                widget.avatar.startsWith('http')
                                    ? widget.avatar
                                    : 'https://littlebank-dev.s3.ap-northeast-2.amazonaws.com/${widget.avatar}',
                              ),
                              fit: BoxFit.cover,
                            )
                            : null,
                    shape: OvalBorder(),
                  ),
                  child:
                      widget.avatar.isEmpty
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
                      widget.userName,
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

          // 메시지 버블과 시간 (오버플로우 해결)
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
                        message.content ?? '',
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
                      _formatTime(message.time),
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
                _formatTime(message.time),
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
                  color: const Color(0xFF89DA8D),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(18),
                      topRight: Radius.circular(18),
                      bottomLeft: Radius.circular(18),
                    ),
                  ),
                ),
                child: Text(
                  message.content ?? '',
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
    final itemExtent = 120.0; // 메시지 아이템의 대략적인 높이
    // reverse가 false이므로 정상적인 인덱스 계산
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
                'assets/icons/my/뒤로가기.png',
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
                      builder: (context) => ChatRoomMenuScreen(
                        userName: widget.userName,
                        avatar: widget.avatar,
                        roomId: widget.roomId,
                        userId: widget.userId,
                      ),
                    ),
                  ).then((result) {
                    if (result != null && result is Map<String, dynamic>) {
                      final action = result['action'];
                      if (action == 'leave_room') {
                        Navigator.pop(context, result);
                      } else if (action == 'update_room_name') {
                        final newName = result['newName'] as String?;
                        final success = result['success'] as bool? ?? false;
                        
                        if (success && newName != null) {
                          // 채팅방 이름이 변경되었을 때 상단 제목 업데이트
                          setState(() {
                            _roomName = newName;
                          });
                          print('✅ 아이단 채팅 상세 화면 제목 업데이트: $newName');
                        }
                        
                        // 채팅 목록으로 결과 전달
                        Navigator.pop(context, result);
                      }
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

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? pickedImage = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (pickedImage != null) {
        print('=== 📷 카메라 이미지 메시지 전송 (WebSocket 전용) ===');
        print('이미지 경로: ${pickedImage.path}');

        final result = await ChatService.sendMessage(
          roomId: widget.roomId,
          content: pickedImage.path,
          messageType: 'IMAGE',
        );

        if (result != null && result['success'] == true) {
          print('✅ 카메라 이미지 메시지 전송 성공 - WebSocket을 통해 수신될 예정');
        } else {
          print('❌ 카메라 이미지 메시지 전송 실패');
        }
      }
    } catch (e) {
      print('❌ 카메라 이미지 촬영/전송 중 오류: $e');
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
        print('=== 📷 이미지 메시지 전송 (WebSocket 전용) ===');
        print('이미지 경로: ${pickedImage.path}');

        // TODO: 파일 업로드 API 호출 후 URL 받아서 WebSocket으로 전송
        // 현재는 로컬 경로를 직접 전송 (임시)
        final result = await ChatService.sendMessage(
          roomId: widget.roomId,
          content: pickedImage.path,
          messageType: 'IMAGE',
        );

        if (result != null && result['success'] == true) {
          print('✅ 이미지 메시지 전송 성공 - WebSocket을 통해 수신될 예정');
        } else {
          print('❌ 이미지 메시지 전송 실패');
        }
      }
    } catch (e) {
      print('❌ 이미지 선택/전송 중 오류: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('이미지 선택 중 오류가 발생했습니다: $e')));
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    try {
      print('=== 📤 메시지 전송 시작 (WebSocket 전용) ===');
      print('메시지 내용: $text');

      // 화면용 디버그 로그 추가
      if (mounted) {
        setState(() {
          _debugLogs.add('[${DateTime.now()}] 📤 전송 시도: $text');
          if (_debugLogs.length > 10) {
            _debugLogs.removeAt(0);
          }
        });
      }

      // 입력창 먼저 비우기
      final originalText = text;
      _messageController.clear();

      // 전송 전 메시지 수 기록
      final messageCountBeforeSend = _messages.length;
      print('🔍 전송 전 메시지 수: $messageCountBeforeSend');

      // 서버로 메시지 전송 (WebSocket으로만 수신)
      final result = await ChatService.sendMessage(
        roomId: widget.roomId,
        content: text,
        messageType: 'TEXT',
      );

      if (result != null && result['success'] == true) {
        print('✅ 메시지 전송 성공 - 서버 저장 상태 확인 중...');

        // 화면용 디버그 로그 추가
        if (mounted) {
          setState(() {
            _debugLogs.add('[${DateTime.now()}] ✅ 전송 성공 - WebSocket 수신 대기 중');
            if (_debugLogs.length > 10) {
              _debugLogs.removeAt(0);
            }
          });
        }

        // WebSocket 실시간 수신 대기 (3초)
        bool messageReceived = false;
        Timer? timeoutTimer;

        // 메시지 수신 체크용 콜백
        void checkMessageReceived() {
          if (mounted && _messages.length > messageCountBeforeSend) {
            messageReceived = true;
            timeoutTimer?.cancel();
            print('🎉 WebSocket으로 메시지 실시간 수신 성공!');

            setState(() {
              _debugLogs.add('[${DateTime.now()}] 🎉 WebSocket 실시간 수신 성공');
              if (_debugLogs.length > 10) {
                _debugLogs.removeAt(0);
              }
            });
          }
        }

        // 0.3초마다 메시지 수신 체크 (더 자주 체크)
        Timer.periodic(const Duration(milliseconds: 300), (timer) {
          checkMessageReceived();
          if (messageReceived || timer.tick >= 4) {
            // 1.2초 대기 (0.3 * 4)
            timer.cancel();
          }
        });

        // 1초 후 타임아웃 처리 (더 빠른 새로고침)
        timeoutTimer = Timer(const Duration(seconds: 1), () async {
          if (!messageReceived && mounted) {
            print('⚠️ WebSocket 실시간 수신 타임아웃 - 강제 메시지 다시 로드');

            setState(() {
              _debugLogs.add('[${DateTime.now()}] ⚠️ WebSocket 타임아웃 - 강제 새로고침');
              if (_debugLogs.length > 10) {
                _debugLogs.removeAt(0);
              }
            });

            // 강제로 메시지 목록 다시 로드
            await _loadChatRoomDetails(setupWebSocket: false);

            // 스크롤을 맨 아래로 이동
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_scrollController.hasClients && _messages.isNotEmpty) {
                _scrollController.animateTo(
                  _scrollController.position.maxScrollExtent,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                );
              }
            });

            print('🔄 강제 새로고침 완료 - 새 메시지가 표시되어야 함');

            setState(() {
              _debugLogs.add(
                '[${DateTime.now()}] 🔄 강제 새로고침 완료 - 메시지 수: ${_messages.length}',
              );
              if (_debugLogs.length > 10) {
                _debugLogs.removeAt(0);
              }
            });
          }
        });

        // 메시지 전송 3초 후 서버 상태 확인
        Future.delayed(const Duration(seconds: 3), () async {
          try {
            print('🔍 메시지 저장 상태 확인: 채팅방 상세 정보 재조회');
            final roomDetails = await ChatService.getChatRoomDetails(
              widget.roomId,
            );

            if (roomDetails != null) {
              final lastSendMessageId =
                  roomDetails['lastSendMessageId'] as int?;
              print('🔍 재조회된 lastSendMessageId: $lastSendMessageId');

              if (lastSendMessageId != null && lastSendMessageId > 0) {
                print('✅ 메시지가 서버에 정상 저장됨: ID=$lastSendMessageId');

                if (mounted) {
                  setState(() {
                    _debugLogs.add(
                      '[${DateTime.now()}] ✅ 서버 저장 확인: ID=$lastSendMessageId',
                    );
                    if (_debugLogs.length > 10) {
                      _debugLogs.removeAt(0);
                    }
                  });
                }
              } else {
                print('❌ 메시지가 서버에 저장되지 않았음 - lastSendMessageId 여전히 0');

                if (mounted) {
                  setState(() {
                    _debugLogs.add(
                      '[${DateTime.now()}] ❌ 서버 저장 실패 - lastSendMessageId 여전히 0',
                    );
                    if (_debugLogs.length > 10) {
                      _debugLogs.removeAt(0);
                    }
                  });
                }
              }
            } else {
              print('❌ 채팅방 상세 정보 조회 실패 - roomDetails가 null');

              if (mounted) {
                setState(() {
                  _debugLogs.add('[${DateTime.now()}] ❌ 채팅방 상세 정보 조회 실패');
                  if (_debugLogs.length > 10) {
                    _debugLogs.removeAt(0);
                  }
                });
              }
            }
          } catch (e) {
            print('❌ 서버 상태 확인 중 오류: $e');

            if (mounted) {
              setState(() {
                _debugLogs.add('[${DateTime.now()}] ❌ 서버 상태 확인 오류: $e');
                if (_debugLogs.length > 10) {
                  _debugLogs.removeAt(0);
                }
              });
            }
          }
        });
      } else if (result != null && result['error'] == 'BLOCKED_USER') {
        print('⚠️ 차단된 사용자에게 메시지 전송 시도');

        // 입력창에 원래 텍스트 복원
        _messageController.text = originalText;
        _showErrorDialog('전송 불가', '차단된 사용자에게는 메시지를 전송할 수 없습니다.');
      } else {
        print('❌ 메시지 전송 실패');

        // 입력창에 원래 텍스트 복원
        _messageController.text = originalText;

        final errorMessage = result?['message'] ?? '메시지 전송에 실패했습니다.';
        _showErrorDialog('전송 실패', errorMessage);
      }
    } catch (e) {
      print('❌ 메시지 전송 중 예외 발생: $e');

      // 입력창에 원래 텍스트 복원
      _messageController.text = text;
      _showErrorDialog('오류', '메시지 전송 중 오류가 발생했습니다: $e');
    }
  }
}

// TODO: 기존 _InviteFriendsDialog 클래스 제거됨 - 새로운 친구 목록 화면 사용

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
      print('비디오 플레이어 초기화 오류: $e');
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
                      // 비디오 플레이어
                      VideoPlayer(_controller),

                      // 재생/일시정지 컨트롤
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
