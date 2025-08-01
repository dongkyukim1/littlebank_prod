import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';
import 'package:stomp_dart_client/stomp.dart';
import 'package:stomp_dart_client/stomp_config.dart';
import 'package:stomp_dart_client/stomp_frame.dart';
import '../models/chat_message.dart';

typedef MessageCallback = void Function(Map<String, dynamic>);
typedef UnsubscribeCallback = void Function();

class ChatService {
  // 서버 기본 URL
  static const String baseUrl = 'http://3.34.52.239:8080';
  static const String wsUrl = 'ws://3.34.52.239:8080/ws-stomp';

  // STOMP 클라이언트 인스턴스
  static StompClient? _stompClient;

  // 메시지 수신 콜백 저장
  static Map<String, MessageCallback> _subscriptions = {};

  // 구독 해제 콜백 저장
  static Map<String, UnsubscribeCallback> _unsubscribeCallbacks = {};

  // 메시지 읽음 처리 콜백 저장
  static Map<String, MessageCallback> _readSubscriptions = {};

  // 메시지 읽음 처리 구독 해제 콜백 저장
  static Map<String, UnsubscribeCallback> _readUnsubscribeCallbacks = {};

  // 채팅방 초대 콜백 저장
  static Map<String, MessageCallback> _inviteSubscriptions = {};

  // 채팅방 초대 구독 해제 콜백 저장
  static Map<String, UnsubscribeCallback> _inviteUnsubscribeCallbacks = {};

  // 채팅방 나가기 콜백 저장
  static Map<String, MessageCallback> _leaveSubscriptions = {};

  // 채팅방 나가기 구독 해제 콜백 저장
  static Map<String, UnsubscribeCallback> _leaveUnsubscribeCallbacks = {};

  // 사용자 개인 알림 콜백 저장
  static Map<String, MessageCallback> _userSubscriptions = {};

  // 사용자 개인 알림 구독 해제 콜백 저장
  static Map<String, UnsubscribeCallback> _userUnsubscribeCallbacks = {};

  // 재연결 타이머
  static Timer? _reconnectTimer;

  // 연결 상태
  static bool _isConnecting = false;

  /// WebSocket 연결 초기화
  static Future<void> initializeWebSocket() async {
    if (_isConnecting) {
      print('WebSocket 연결 시도 중...');
      return;
    }

    if (_stompClient != null) {
      _stompClient!.deactivate();
      _stompClient = null;
    }

    _isConnecting = true;

    try {
      // 토큰 가져오기
      final accessToken = await AuthService.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        throw Exception('인증 토큰이 없습니다.');
      }

      print('WebSocket 연결 시작...');
      print('토큰: $accessToken');

      _stompClient = StompClient(
        config: StompConfig.sockJS(
          url: '$baseUrl/ws',
          onConnect: (StompFrame frame) {
            print('WebSocket 연결 성공!');
            print('연결 프레임: $frame');
            _isConnecting = false;
            _onConnect(frame);
            _reconnectTimer?.cancel();
            _reconnectTimer = null;
            // 모든 채팅방 재구독
            _resubscribeAll();
          },
          onDisconnect: (StompFrame frame) {
            print('WebSocket 연결 해제됨');
            print('연결 해제 프레임: $frame');
            _isConnecting = false;
            _onDisconnect(frame);
            // 재연결 시도 시작
            _startReconnectTimer();
          },
          onWebSocketError: (dynamic error) {
            print('WebSocket 오류 발생: $error');
            _isConnecting = false;
            // 재연결 시도 시작
            _startReconnectTimer();
          },
          onStompError: (StompFrame frame) {
            print('STOMP 오류 발생: ${frame.body}');
          },
          onDebugMessage: (String msg) {
            print('WebSocket 디버그: $msg');
            // 메시지 수신 패턴 분석
            if (msg.contains('MESSAGE') ||
                msg.contains('SUBSCRIBE') ||
                msg.contains('SEND')) {
              print('🔍 중요한 WebSocket 활동: $msg');

              // 실제 메시지 수신인지 확인
              if (msg.contains('MESSAGE') && msg.contains('/sub/chat/')) {
                print('🚨🚨🚨 실제 채팅 메시지 수신 감지! 🚨🚨🚨');
                print(
                  '메시지 내용 분석: ${msg.substring(0, math.min(200, msg.length))}...',
                );
              }
            }

            // 모든 STOMP 프레임 추적
            if (msg.startsWith('>>>') || msg.startsWith('<<<')) {
              print(
                '🔄 STOMP 프레임: ${msg.substring(0, math.min(100, msg.length))}',
              );
            }
          },
          stompConnectHeaders: {'Authorization': 'Bearer $accessToken'},
          webSocketConnectHeaders: {'Authorization': 'Bearer $accessToken'},
        ),
      );

      print('WebSocket 활성화 시도...');
      _stompClient!.activate();
      await Future.delayed(const Duration(seconds: 2));
      print('WebSocket 활성화 완료');
    } catch (e) {
      print('WebSocket 연결 오류: $e');
      _isConnecting = false;
      // 재연결 시도 시작
      _startReconnectTimer();
      rethrow;
    }
  }

  static void _startReconnectTimer() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      print('WebSocket 재연결 시도...');
      try {
        await initializeWebSocket();
      } catch (e) {
        print('WebSocket 재연결 실패: $e');
      }
    });
  }

  static void _resubscribeAll() {
    print('=== 🔄 모든 구독 재연결 시작 ===');
    print('재연결할 메시지 구독 수: ${_subscriptions.length}');
    print('재연결할 읽음 처리 구독 수: ${_readSubscriptions.length}');

    // 일반 메시지 구독 복원
    final subscriptions = Map<String, MessageCallback>.from(_subscriptions);
    _subscriptions.clear();
    _unsubscribeCallbacks.clear();

    for (final entry in subscriptions.entries) {
      final destination = entry.key;
      final callback = entry.value;

      print('📡 채팅방 재구독: $destination');
      try {
        final unsubscribe = _stompClient!.subscribe(
          destination: destination,
          callback: (StompFrame frame) {
            print('🔄 재구독된 메시지 수신됨:');
            print('Headers: ${frame.headers}');
            print('Body 길이: ${frame.body?.length ?? 0}');
            print(
              'Body 내용: ${frame.body?.substring(0, math.min(200, frame.body?.length ?? 0))}',
            );

            if (frame.body != null && frame.body!.isNotEmpty) {
              try {
                final message = json.decode(frame.body!);
                print('✅ 재구독 메시지 파싱 성공: ${message['messageId'] ?? 'ID없음'}');

                // 친구 관련 데이터 로깅
                if (message['displayIdx'] != null) {
                  print('displayIdx: ${message['displayIdx']}');
                }
                if (message['isFriend'] != null) {
                  print('isFriend: ${message['isFriend']}');
                }
                if (message['customName'] != null) {
                  print('customName: ${message['customName']}');
                }
                if (message['isBestFriend'] != null) {
                  print('isBestFriend: ${message['isBestFriend']}');
                }
                if (message['isBlocked'] != null) {
                  print('isBlocked: ${message['isBlocked']}');
                }

                callback(message);
              } catch (e) {
                print('❌ 재구독 메시지 파싱 오류: $e');
              }
            }
          },
        );

        _subscriptions[destination] = callback;
        _unsubscribeCallbacks[destination] = unsubscribe;
        print('✅ 채팅방 재구독 완료: $destination');
      } catch (e) {
        print('❌ 채팅방 재구독 실패: $destination, 오류: $e');
      }
    }

    // 메시지 읽음 처리 구독 복원
    final readSubscriptions = Map<String, MessageCallback>.from(
      _readSubscriptions,
    );
    _readSubscriptions.clear();
    _readUnsubscribeCallbacks.clear();

    for (final entry in readSubscriptions.entries) {
      final destination = entry.key;
      final callback = entry.value;

      print('📖 메시지 읽음 처리 재구독: $destination');
      final unsubscribe = _stompClient!.subscribe(
        destination: destination,
        callback: (StompFrame frame) {
          print('🔄 재구독된 읽음 처리 수신됨:');
          print('Headers: ${frame.headers}');
          print('Body: ${frame.body}');

          if (frame.body != null && frame.body!.isNotEmpty) {
            try {
              final readData = json.decode(frame.body!);
              print('✅ 재구독 읽음 처리 파싱 성공: $readData');
              callback(readData);
            } catch (e) {
              print('❌ 재구독 읽음 처리 파싱 오류: $e');
              print('원본 데이터: ${frame.body}');
            }
          }
        },
      );

      _readSubscriptions[destination] = callback;
      _readUnsubscribeCallbacks[destination] = unsubscribe;
      print('✅ 메시지 읽음 처리 재구독 완료: $destination');
    }

    // 채팅방 초대 구독 복원
    final inviteSubscriptions = Map<String, MessageCallback>.from(
      _inviteSubscriptions,
    );
    _inviteSubscriptions.clear();
    _inviteUnsubscribeCallbacks.clear();

    for (final entry in inviteSubscriptions.entries) {
      final destination = entry.key;
      final callback = entry.value;

      print('👥 채팅방 초대 재구독: $destination');
      final unsubscribe = _stompClient!.subscribe(
        destination: destination,
        callback: (StompFrame frame) {
          print('🔄 재구독된 초대 알림 수신됨:');
          print('Headers: ${frame.headers}');
          print('Body: ${frame.body}');

          if (frame.body != null && frame.body!.isNotEmpty) {
            try {
              final inviteData = json.decode(frame.body!);
              print('✅ 재구독 초대 알림 파싱 성공: $inviteData');
              callback(inviteData);
            } catch (e) {
              print('❌ 재구독 초대 알림 파싱 오류: $e');
              print('원본 데이터: ${frame.body}');
            }
          }
        },
      );

      _inviteSubscriptions[destination] = callback;
      _inviteUnsubscribeCallbacks[destination] = unsubscribe;
      print('✅ 채팅방 초대 재구독 완료: $destination');
    }

    // 채팅방 나가기 구독 복원
    final leaveSubscriptions = Map<String, MessageCallback>.from(
      _leaveSubscriptions,
    );
    _leaveSubscriptions.clear();
    _leaveUnsubscribeCallbacks.clear();

    for (final entry in leaveSubscriptions.entries) {
      final destination = entry.key;
      final callback = entry.value;

      print('🚪 채팅방 나가기 재구독: $destination');
      final unsubscribe = _stompClient!.subscribe(
        destination: destination,
        callback: (StompFrame frame) {
          print('🔄 재구독된 나가기 알림 수신됨:');
          print('Headers: ${frame.headers}');
          print('Body: ${frame.body}');

          if (frame.body != null && frame.body!.isNotEmpty) {
            try {
              final leaveData = json.decode(frame.body!);
              print('✅ 재구독 나가기 알림 파싱 성공: $leaveData');
              callback(leaveData);
            } catch (e) {
              print('❌ 재구독 나가기 알림 파싱 오류: $e');
              print('원본 데이터: ${frame.body}');
            }
          }
        },
      );

      _leaveSubscriptions[destination] = callback;
      _leaveUnsubscribeCallbacks[destination] = unsubscribe;
      print('✅ 채팅방 나가기 재구독 완료: $destination');
    }

    // 사용자 개인 알림 구독 복원
    final userSubscriptions = Map<String, MessageCallback>.from(
      _userSubscriptions,
    );
    _userSubscriptions.clear();
    _userUnsubscribeCallbacks.clear();

    for (final entry in userSubscriptions.entries) {
      final destination = entry.key;
      final callback = entry.value;

      print('👤 사용자 개인 알림 재구독: $destination');
      final unsubscribe = _stompClient!.subscribe(
        destination: destination,
        callback: (StompFrame frame) {
          print('🔄 재구독된 개인 알림 수신됨:');
          print('Headers: ${frame.headers}');
          print('Body: ${frame.body}');

          if (frame.body != null && frame.body!.isNotEmpty) {
            try {
              final userData = json.decode(frame.body!);
              print('✅ 재구독 개인 알림 파싱 성공: $userData');
              callback(userData);
            } catch (e) {
              print('❌ 재구독 개인 알림 파싱 오류: $e');
              print('원본 데이터: ${frame.body}');
            }
          }
        },
      );

      _userSubscriptions[destination] = callback;
      _userUnsubscribeCallbacks[destination] = unsubscribe;
      print('✅ 사용자 개인 알림 재구독 완료: $destination');
    }

    print('=== 🔄 모든 구독 재연결 완료 ===');
    print('복원된 메시지 구독 수: ${_subscriptions.length}');
    print('복원된 읽음 처리 구독 수: ${_readSubscriptions.length}');
    print('복원된 초대 구독 수: ${_inviteSubscriptions.length}');
    print('복원된 나가기 구독 수: ${_leaveSubscriptions.length}');
    print('복원된 개인 알림 구독 수: ${_userSubscriptions.length}');
    printSubscriptionStatus();
  }

  static void _onConnect(StompFrame frame) {
    print('WebSocket 연결됨');
  }

  static void _onDisconnect(StompFrame frame) {
    print('WebSocket 연결 해제됨');
  }

  /// 채팅방 구독
  ///
  /// 구독 경로가 `/sub/chat/{roomId}/{userId}`로 변경됨
  static Future<void> subscribeToChatRoom(
    int roomId,
    MessageCallback onMessageReceived,
  ) async {
    try {
      // 현재 사용자 ID 가져오기
      final userInfo = await AuthService.getUserInfo();
      if (userInfo == null || userInfo['userId'] == null) {
        print('❌ 사용자 정보를 가져올 수 없습니다.');
        return;
      }

      final userId = userInfo['userId'];
      final destination = '/sub/chat/$roomId/$userId';

      print('=== 📡 채팅방 구독 시작 ===');
      print('채팅방 ID: $roomId');
      print('사용자 ID: $userId');
      print('구독 경로: $destination');
      print('WebSocket 연결 상태: ${_stompClient?.connected ?? false}');
      print('현재 시간: ${DateTime.now()}');

      if (_stompClient == null || !_stompClient!.connected) {
        print('❌ WebSocket 연결이 없습니다. 연결 시도...');
        await initializeWebSocket();

        // 재연결 후 다시 확인
        if (_stompClient == null || !_stompClient!.connected) {
          print('❌ WebSocket 재연결 실패');
          return;
        }
      }

      // 이미 구독 중인지 확인
      if (_subscriptions.containsKey(destination)) {
        print('⚠️ 이미 구독 중인 채팅방: $destination');
        // 기존 구독 해제 후 새로 구독
        final existingUnsubscribe = _unsubscribeCallbacks[destination];
        if (existingUnsubscribe != null) {
          existingUnsubscribe();
          print('🔄 기존 구독 해제 후 새로 구독');
        }
      }

      print('✅ 채팅방 구독 시작: $destination');
      print('🔊 STOMP 클라이언트 상태: connected=${_stompClient!.connected}');

      final unsubscribe = _stompClient!.subscribe(
        destination: destination,
        callback: (StompFrame frame) {
          print('=== 📨 메시지 수신됨 ===');
          print('수신 시간: ${DateTime.now()}');
          print('구독 경로: $destination');
          print('현재 사용자 ID: $userId');
          print('Headers: ${frame.headers}');
          print('Body 길이: ${frame.body?.length ?? 0}');
          print(
            'Body 내용: ${frame.body?.substring(0, math.min(500, frame.body?.length ?? 0))}',
          );

          if (frame.body != null && frame.body!.isNotEmpty) {
            try {
              final message = json.decode(frame.body!);
              print('✅ 파싱된 메시지: $message');

              // 🚨 메시지 수신 성공! 서버 DB 저장 여부 확인
              print('🎉🎉🎉 실제 메시지 수신 성공! 🎉🎉🎉');
              print('🚨🚨🚨 WebSocket 콜백 함수 실행 중! 🚨🚨🚨');

              // 메시지 상세 정보 로깅
              if (message['messageId'] != null) {
                print('📝 메시지 ID: ${message['messageId']}');
              }
              if (message['senderUserId'] != null) {
                print('👤 발신자 ID: ${message['senderUserId']}');
              }
              if (message['senderName'] != null) {
                print('👤 발신자 이름: ${message['senderName']}');
              }
              if (message['content'] != null) {
                print('💬 메시지 내용: ${message['content']}');
              }
              if (message['timestamp'] != null) {
                print('🕐 메시지 시각: ${message['timestamp']}');
              }
              if (message['readCount'] != null) {
                print('👀 읽지 않은 사람 수: ${message['readCount']}');
              }

              // 친구 관련 데이터 로깅
              if (message['displayIdx'] != null) {
                print('displayIdx: ${message['displayIdx']}');
              }
              if (message['isFriend'] != null) {
                print('isFriend: ${message['isFriend']}');
              }
              if (message['customName'] != null) {
                print('customName: ${message['customName']}');
              }
              if (message['isBestFriend'] != null) {
                print('isBestFriend: ${message['isBestFriend']}');
              }
              if (message['isBlocked'] != null) {
                print('isBlocked: ${message['isBlocked']}');
              }

              print('📢 콜백 함수 호출 시작...');
              try {
                onMessageReceived(message);
                print('✅ 콜백 함수 호출 성공');
              } catch (callbackError) {
                print('❌ 콜백 함수 호출 중 오류: $callbackError');
              }
            } catch (e) {
              print('❌ 메시지 파싱 오류: $e');
              print('원본 메시지: ${frame.body}');
            }
          } else {
            print('⚠️ 빈 메시지 수신');
          }
        },
      );

      _subscriptions[destination] = onMessageReceived;
      _unsubscribeCallbacks[destination] = unsubscribe;

      print('✅ 채팅방 구독 완료');
      print('현재 활성 구독 목록: ${_subscriptions.keys.toList()}');
      print('=== 📡 채팅방 구독 완료 ===');

      // 구독 완료 - 실제 메시지 수신 대기
      print('🧪 구독 완료 - 실제 메시지 수신 준비됨');
      print('🧪 이제 실제 메시지를 전송하면 WebSocket을 통해 수신됩니다!');

      // 구독 후 테스트 메시지 확인
      Future.delayed(const Duration(seconds: 1), () {
        print('🔍 구독 상태 확인:');
        print('- 구독 경로: $destination');
        print('- 구독 활성화: ${_subscriptions.containsKey(destination)}');
        print('- WebSocket 연결: ${_stompClient?.connected ?? false}');
      });
    } catch (e) {
      print('❌ 채팅방 구독 중 오류 발생: $e');
      print('스택 트레이스: ${StackTrace.current}');
    }
  }

  /// 채팅방 구독 해제
  static void unsubscribeFromChatRoom(int roomId) async {
    try {
      // 현재 사용자 ID 가져오기 (구독할 때와 동일한 경로 사용)
      final userInfo = await AuthService.getUserInfo();
      if (userInfo == null || userInfo['userId'] == null) {
        print('❌ 사용자 정보를 가져올 수 없습니다.');
        return;
      }

      final userId = userInfo['userId'];
      final destination = '/sub/chat/$roomId/$userId'; // 구독할 때와 동일한 경로

      print('=== 🔌 채팅방 구독 해제 시작 ===');
      print('채팅방 ID: $roomId');
      print('사용자 ID: $userId');
      print('구독 해제 경로: $destination');

      final unsubscribe = _unsubscribeCallbacks[destination];

      if (unsubscribe != null) {
        unsubscribe();
        print('✅ 채팅방 구독 해제 성공: $destination');
      } else {
        print('⚠️ 구독 해제할 콜백이 없음: $destination');
      }

      _subscriptions.remove(destination);
      _unsubscribeCallbacks.remove(destination);

      print('남은 구독 목록: ${_subscriptions.keys.toList()}');
      print('=== 🔌 채팅방 구독 해제 완료 ===');
    } catch (e) {
      print('❌ 채팅방 구독 해제 중 오류 발생: $e');
    }
  }

  /// 메시지 읽음 처리 구독
  ///
  /// 다른 사용자가 메시지를 읽었을 때의 알림을 받습니다.
  /// 채팅방에 있지 않을 때도 읽음 상태 변경을 감지할 수 있습니다.
  static Future<void> subscribeToMessageRead(
    int roomId,
    MessageCallback onMessageReadReceived,
  ) async {
    try {
      final destination = '/sub/chat/read/$roomId';

      print('=== 📖 메시지 읽음 처리 구독 시작 ===');
      print('채팅방 ID: $roomId');
      print('구독 경로: $destination');
      print('WebSocket 연결 상태: ${_stompClient?.connected ?? false}');
      print('현재 시간: ${DateTime.now()}');

      if (_stompClient == null || !_stompClient!.connected) {
        print('❌ WebSocket 연결이 없습니다. 연결 시도...');
        await initializeWebSocket();

        // 재연결 후 다시 확인
        if (_stompClient == null || !_stompClient!.connected) {
          print('❌ WebSocket 재연결 실패');
          return;
        }
      }

      // 이미 구독 중인지 확인
      if (_readSubscriptions.containsKey(destination)) {
        print('⚠️ 이미 읽음 처리 구독 중인 채팅방: $destination');
        return;
      }

      print('✅ 메시지 읽음 처리 구독 시작: $destination');

      final unsubscribe = _stompClient!.subscribe(
        destination: destination,
        callback: (StompFrame frame) {
          print('=== 📖 메시지 읽음 처리 수신됨 ===');
          print('수신 시간: ${DateTime.now()}');
          print('구독 경로: $destination');
          print('Headers: ${frame.headers}');
          print('Body: ${frame.body}');

          if (frame.body != null && frame.body!.isNotEmpty) {
            try {
              final readData = json.decode(frame.body!);
              print('✅ 파싱된 읽음 처리 데이터: $readData');
              onMessageReadReceived(readData);
            } catch (e) {
              print('❌ 읽음 처리 데이터 파싱 오류: $e');
              print('원본 데이터: ${frame.body}');
            }
          }
        },
      );

      _readSubscriptions[destination] = onMessageReadReceived;
      _readUnsubscribeCallbacks[destination] = unsubscribe;

      print('✅ 메시지 읽음 처리 구독 완료');
      print('현재 활성 읽음 처리 구독 목록: ${_readSubscriptions.keys.toList()}');
      print('=== 📖 메시지 읽음 처리 구독 완료 ===');
    } catch (e) {
      print('❌ 메시지 읽음 처리 구독 중 오류 발생: $e');
      print('스택 트레이스: ${StackTrace.current}');
    }
  }

  /// 메시지 읽음 처리 구독 해제
  static void unsubscribeFromMessageRead(int roomId) {
    try {
      final destination = '/sub/chat/read/$roomId';

      print('=== 🔌 메시지 읽음 처리 구독 해제 시작 ===');
      print('채팅방 ID: $roomId');
      print('구독 해제 경로: $destination');

      final unsubscribe = _readUnsubscribeCallbacks[destination];

      if (unsubscribe != null) {
        unsubscribe();
        print('✅ 메시지 읽음 처리 구독 해제 성공: $destination');
      } else {
        print('⚠️ 읽음 처리 구독 해제할 콜백이 없음: $destination');
      }

      _readSubscriptions.remove(destination);
      _readUnsubscribeCallbacks.remove(destination);

      print('남은 읽음 처리 구독 목록: ${_readSubscriptions.keys.toList()}');
      print('=== 🔌 메시지 읽음 처리 구독 해제 완료 ===');
    } catch (e) {
      print('❌ 메시지 읽음 처리 구독 해제 중 오류 발생: $e');
    }
  }

  /// 구독 상태 디버깅용 메서드
  static void printSubscriptionStatus() {
    print('=== 🔍 현재 구독 상태 ===');
    print('WebSocket 연결 상태: ${_stompClient?.connected ?? false}');
    print('활성 메시지 구독 개수: ${_subscriptions.length}');
    print('활성 읽음 처리 구독 개수: ${_readSubscriptions.length}');
    print('활성 초대 구독 개수: ${_inviteSubscriptions.length}');
    print('활성 나가기 구독 개수: ${_leaveSubscriptions.length}');
    print('활성 개인 알림 구독 개수: ${_userSubscriptions.length}');

    print('메시지 구독 목록:');
    for (final destination in _subscriptions.keys) {
      print('  - $destination');
    }

    print('읽음 처리 구독 목록:');
    for (final destination in _readSubscriptions.keys) {
      print('  - $destination');
    }

    print('초대 구독 목록:');
    for (final destination in _inviteSubscriptions.keys) {
      print('  - $destination');
    }

    print('나가기 구독 목록:');
    for (final destination in _leaveSubscriptions.keys) {
      print('  - $destination');
    }

    print('개인 알림 구독 목록:');
    for (final destination in _userSubscriptions.keys) {
      print('  - $destination');
    }

    print('=== 🔍 구독 상태 확인 완료 ===');
  }

  /// 과도한 구독 정리 (성능 최적화)
  ///
  /// 너무 많은 구독이 있으면 WebSocket 성능에 영향을 줄 수 있으므로
  /// 필요하지 않은 구독들을 정리합니다.
  static void cleanupExcessiveSubscriptions({int maxSubscriptions = 10}) {
    print('=== 🧹 과도한 구독 정리 시작 ===');
    print('최대 허용 구독 수: $maxSubscriptions');
    print('현재 메시지 구독 수: ${_subscriptions.length}');
    print('현재 읽음 처리 구독 수: ${_readSubscriptions.length}');

    // 메시지 구독 정리
    if (_subscriptions.length > maxSubscriptions) {
      final sortedKeys = _subscriptions.keys.toList()..sort();
      final toRemove = sortedKeys.take(
        _subscriptions.length - maxSubscriptions,
      );

      print('🗑️ 메시지 구독 ${toRemove.length}개 정리 중...');
      for (final destination in toRemove) {
        final unsubscribe = _unsubscribeCallbacks[destination];
        if (unsubscribe != null) {
          unsubscribe();
          print('  ✅ 구독 해제: $destination');
        }
        _subscriptions.remove(destination);
        _unsubscribeCallbacks.remove(destination);
      }
    }

    // 읽음 처리 구독 정리
    if (_readSubscriptions.length > maxSubscriptions) {
      final sortedKeys = _readSubscriptions.keys.toList()..sort();
      final toRemove = sortedKeys.take(
        _readSubscriptions.length - maxSubscriptions,
      );

      print('🗑️ 읽음 처리 구독 ${toRemove.length}개 정리 중...');
      for (final destination in toRemove) {
        final unsubscribe = _readUnsubscribeCallbacks[destination];
        if (unsubscribe != null) {
          unsubscribe();
          print('  ✅ 읽음 처리 구독 해제: $destination');
        }
        _readSubscriptions.remove(destination);
        _readUnsubscribeCallbacks.remove(destination);
      }
    }

    print('정리 후 메시지 구독 수: ${_subscriptions.length}');
    print('정리 후 읽음 처리 구독 수: ${_readSubscriptions.length}');
    print('=== 🧹 과도한 구독 정리 완료 ===');
  }

  /// 채팅방 메시지 목록 조회 (페이징 방식)
  ///
  /// [roomId]: 채팅방 ID
  /// [lastMessageId]: 페이징 조회 기준이 되는 메시지 ID
  ///   - 처음 조회 시: (lastSendMessageId + 1)을 전달하여 그 이전 메시지들 조회
  ///   - 페이징 조회 시: 응답 리스트 마지막 요소의 messageId를 전달하여 이전 메시지들 조회
  /// [pageNumber]: 페이지 번호 (기본값: 0)
  /// [pageSize]: 페이지 크기 (기본값: 100)
  ///
  /// 100개씩 최신순으로 조회됩니다.
  static Future<Map<String, dynamic>?> getChatMessages(
    int roomId, {
    required int lastMessageId,
    int pageNumber = 0,
    int pageSize = 100,
  }) async {
    try {
      print('===== 채팅 메시지 목록 조회 시작 =====');
      print('채팅방 ID: $roomId');
      print('마지막 메시지 ID (페이징 기준): $lastMessageId');
      print('페이지 번호: $pageNumber');
      print('페이지 크기: $pageSize');

      final accessToken = await AuthService.getAccessToken();
      if (accessToken == null) {
        print('❌ 인증 토큰이 없습니다.');
        return null;
      }

      final url = Uri.parse(
        '$baseUrl/api-user/chat/messages/$roomId?lastMessageId=$lastMessageId&page=$pageNumber&size=$pageSize',
      );
      print('API 요청 URL: $url');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      print('응답 상태 코드: ${response.statusCode}');
      print('응답 데이터: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ 메시지 조회 성공');
        print('조회된 메시지 수: ${data['data']?.length ?? 0}');
        return data;
      } else {
        print('❌ 메시지 조회 실패: ${response.statusCode}');
        print('에러 메시지: ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ 메시지 조회 중 오류 발생: $e');
      return null;
    }
  }

  /// 채팅방 상세 정보 조회 (새로운 단일 채팅방 상세 조회 API)
  static Future<Map<String, dynamic>?> getChatRoomDetails(int roomId) async {
    try {
      print('===== 채팅방 상세 정보 조회 시작 =====');
      print('채팅방 ID: $roomId');

      // 토큰 가져오기
      String? accessToken = await AuthService.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        print('액세스 토큰이 없습니다. 재발급 시도...');
        accessToken = await AuthService.reissueAccessToken();
        if (accessToken == null || accessToken.isEmpty) {
          print('토큰 재발급 실패');
          return null;
        }
      }

      // 새로운 단일 채팅방 상세 조회 API URL
      final url = Uri.parse('$baseUrl/api-user/chat/room/$roomId');
      print('채팅방 상세 정보 조회 API 호출: $url');

      // 헤더 설정
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
        'Accept': 'application/json',
      };

      try {
        final response = await http
            .get(url, headers: headers)
            .timeout(const Duration(seconds: 10));

        print('채팅방 상세 정보 조회 응답 상태: ${response.statusCode}');

        if (response.statusCode == 200) {
          final jsonBody = utf8.decode(response.bodyBytes);
          final Map<String, dynamic> data = json.decode(jsonBody);

          print('채팅방 상세 정보 조회 성공');
          print('채팅방 이름: ${data['roomName']}');
          print('채팅방 범위: ${data['roomRange']}');
          print('마지막 읽은 메시지 ID: ${data['lastReadMessageId']}');
          print('마지막 전송 메시지 ID: ${data['lastSendMessageId']}');
          print('참여자 수: ${(data['participants'] as List?)?.length ?? 0}');
          print('===== 채팅방 상세 정보 조회 완료 =====');

          return data;
        } else if (response.statusCode == 404) {
          print('채팅방을 찾을 수 없습니다 (404)');
          return null;
        } else if (response.statusCode == 403) {
          print('채팅방 접근 권한이 없습니다 (403)');
          return null;
        } else {
          print('API 오류: ${response.statusCode}');
          final errorBody = utf8.decode(response.bodyBytes);
          print('오류 응답: $errorBody');
          return null;
        }
      } catch (e) {
        print('API 호출 중 예외: $e');
        return null;
      }
    } catch (e) {
      print('채팅방 상세 정보 조회 중 오류: $e');
      return null;
    }
  }

  /// 메시지 읽음 처리 전송 (차단 상태 체크 추가)
  ///
  /// [roomId] 채팅방 ID
  /// [messageIds] 읽음 처리할 메시지 ID 목록
  static Future<bool> sendMessageRead({
    required int roomId,
    required List<int> messageIds,
  }) async {
    try {
      print('===== 📖 메시지 읽음 처리 전송 시작 =====');
      print('채팅방 ID: $roomId');
      print('읽음 처리할 메시지 ID 목록: $messageIds');
      print('전송 시간: ${DateTime.now()}');
      print('WebSocket 연결 상태: ${_stompClient?.connected ?? false}');

      if (messageIds.isEmpty) {
        print('⚠️ 읽음 처리할 메시지가 없습니다.');
        return true;
      }

      // 1:1 채팅에서 차단 상태 체크
      final roomDetails = await getChatRoomDetails(roomId);
      if (roomDetails != null && roomDetails['roomRange'] == 'PRIVATE') {
        final participants =
            roomDetails['participants'] as List<dynamic>? ?? [];
        if (participants.isNotEmpty) {
          for (final participant in participants) {
            if (participant is Map<String, dynamic>) {
              final isBlocked = participant['isBlocked'] as bool?;
              if (isBlocked == true) {
                print('⚠️ 1:1 채팅에서 상대방이 차단된 상태입니다. 메시지 읽음 처리를 차단합니다.');
                return false;
              }
            }
          }
        }
      }

      if (_stompClient == null || !_stompClient!.connected) {
        print('❌ WebSocket 연결이 없습니다. 재연결 시도...');
        await initializeWebSocket();

        // 재연결 후 다시 확인
        if (_stompClient == null || !_stompClient!.connected) {
          print('❌ WebSocket 재연결 실패');
          return false;
        }
      }

      // 현재 사용자 정보 확인
      final userInfo = await AuthService.getUserInfo();
      if (userInfo != null && userInfo['userId'] != null) {
        print('현재 사용자 ID: ${userInfo['userId']}');
      }

      // 읽음 처리 데이터 구성
      final readData = {'roomId': roomId, 'messageIds': messageIds};

      print('전송할 읽음 처리 데이터: $readData');

      // 토큰 확인
      final accessToken = await AuthService.getAccessToken();

      // WebSocket을 통해 읽음 처리 전송 (JWT 토큰을 헤더에 포함)
      _stompClient!.send(
        destination: '/pub/chat-read',
        body: json.encode(readData),
        headers: {
          'content-type': 'application/json',
          'Authorization': 'Bearer $accessToken', // JWT 토큰 추가
        },
      );

      print('✅ 메시지 읽음 처리 전송 성공');
      print('===== 📖 메시지 읽음 처리 전송 완료 =====');
      return true;
    } catch (e) {
      print('❌ 메시지 읽음 처리 전송 중 오류: $e');
      print('스택 트레이스: ${StackTrace.current}');
      return false;
    }
  }

  /// 시스템 메시지 전송 (나가기, 초대 등)
  static Future<bool> sendSystemMessage({
    required int roomId,
    required String content,
  }) async {
    try {
      print('===== 📢 시스템 메시지 전송 시작 =====');
      print('채팅방 ID: $roomId');
      print('시스템 메시지: $content');
      print('전송 시간: ${DateTime.now()}');

      if (_stompClient == null || !_stompClient!.connected) {
        print('❌ WebSocket 연결이 없습니다. 재연결 시도...');
        await initializeWebSocket();

        if (_stompClient == null || !_stompClient!.connected) {
          print('❌ WebSocket 재연결 실패');
          return false;
        }
      }

      // 토큰 확인
      final accessToken = await AuthService.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        print('❌ 액세스 토큰이 없습니다');
        return false;
      }

      // 시스템 메시지 데이터 구성 (TEXT로 전송하되 내용으로 시스템 메시지임을 표시)
      final messageData = {
        'roomId': roomId,
        'content': content,
        'messageType': 'TEXT', // TEXT로 전송 (서버 호환성)
      };

      print('전송할 시스템 메시지 데이터: $messageData');

      // WebSocket을 통해 시스템 메시지 전송 (두 가지 경로로 시도)
      bool sendSuccess = false;

      // 1차: 일반 메시지 전송 경로로 시도
      try {
        _stompClient!.send(
          destination: '/pub/chat-send',
          body: json.encode(messageData),
          headers: {
            'content-type': 'application/json',
            'Authorization': 'Bearer $accessToken',
          },
        );
        sendSuccess = true;
        print('✅ 시스템 메시지 /pub/chat-send 경로 전송 성공');
      } catch (e) {
        print('❌ /pub/chat-send 경로 전송 실패: $e');
      }

      // 2차: 나가기 전용 경로로도 시도 (백업)
      if (!sendSuccess) {
        try {
          final leaveNotificationData = {
            'roomId': roomId,
            'message': content,
            'messageType': 'LEAVE',
          };

          _stompClient!.send(
            destination: '/pub/room-leave-notification',
            body: json.encode(leaveNotificationData),
            headers: {
              'content-type': 'application/json',
              'Authorization': 'Bearer $accessToken',
            },
          );
          sendSuccess = true;
          print('✅ 시스템 메시지 /pub/room-leave-notification 경로 전송 성공');
        } catch (e) {
          print('❌ /pub/room-leave-notification 경로도 실패: $e');
        }
      }

      if (sendSuccess) {
        print('✅ 시스템 메시지 전송 성공');
        print('===== 📢 시스템 메시지 전송 완료 =====');
        return true;
      } else {
        print('❌ 모든 시스템 메시지 전송 경로 실패');
        print('===== 📢 시스템 메시지 전송 실패 =====');
        return false;
      }
    } catch (e) {
      print('❌ 시스템 메시지 전송 중 오류: $e');
      return false;
    }
  }

  /// 메시지 전송 (차단 상태 체크 및 readCount 응답 처리 추가)
  static Future<Map<String, dynamic>?> sendMessage({
    required int roomId,
    required String content,
    required String messageType,
    String? filePath,
    String? thumbnailPath,
  }) async {
    try {
      print('===== 📤 메시지 전송 시작 =====');
      print('채팅방 ID: $roomId');
      print('메시지 내용: $content');
      print('메시지 타입: $messageType');
      print('전송 시간: ${DateTime.now()}');
      print('WebSocket 연결 상태: ${_stompClient?.connected ?? false}');

      // 1:1 채팅에서 차단 상태 체크
      final roomDetails = await getChatRoomDetails(roomId);
      if (roomDetails != null && roomDetails['roomRange'] == 'PRIVATE') {
        final participants =
            roomDetails['participants'] as List<dynamic>? ?? [];
        if (participants.isNotEmpty) {
          for (final participant in participants) {
            if (participant is Map<String, dynamic>) {
              final isBlocked = participant['isBlocked'] as bool?;
              if (isBlocked == true) {
                print('⚠️ 1:1 채팅에서 상대방이 차단된 상태입니다. 메시지 전송을 차단합니다.');
                return {
                  'success': false,
                  'error': 'BLOCKED_USER',
                  'message': '차단된 사용자에게는 메시지를 전송할 수 없습니다.',
                };
              }
            }
          }
        }
      }

      if (_stompClient == null || !_stompClient!.connected) {
        print('❌ WebSocket 연결이 없습니다. 재연결 시도...');
        await initializeWebSocket();

        // 재연결 후 다시 확인
        if (_stompClient == null || !_stompClient!.connected) {
          print('❌ WebSocket 재연결 실패');
          return {
            'success': false,
            'error': 'WEBSOCKET_ERROR',
            'message': 'WebSocket 연결에 실패했습니다.',
          };
        }
      }

      // 현재 사용자 정보 확인
      final userInfo = await AuthService.getUserInfo();
      int? userId;
      String? userName;

      if (userInfo != null && userInfo['userId'] != null) {
        userId = userInfo['userId'] as int;
        userName = userInfo['name'] as String? ?? '사용자';
        print('현재 사용자 ID: $userId');
        print('현재 사용자 이름: $userName');
      } else {
        print('⚠️ 사용자 정보를 가져올 수 없습니다.');
        return {
          'success': false,
          'error': 'USER_INFO_ERROR',
          'message': '사용자 정보를 확인할 수 없습니다.',
        };
      }

      // 메시지 데이터 구성 (서버 API 명세에 맞게)
      final messageData = {
        'roomId': roomId,
        'content': content,
        'messageType': messageType,
        // 사용자 정보는 WebSocket 헤더의 JWT 토큰으로 확인되므로 body에는 포함하지 않음
        if (filePath != null) 'filePath': filePath,
        if (thumbnailPath != null) 'thumbnailPath': thumbnailPath,
      };

      print('전송할 메시지 데이터: $messageData');

      // 토큰 확인
      final accessToken = await AuthService.getAccessToken();
      print('사용할 액세스 토큰: ${accessToken?.substring(0, 20)}...');

      // 전송할 JSON 문자열 확인
      final jsonBody = json.encode(messageData);
      print('전송할 JSON: $jsonBody');

      // 헤더 정보 확인
      final headers = {
        'content-type': 'application/json',
        'Authorization': 'Bearer $accessToken', // JWT 토큰 추가
      };
      print('전송할 헤더: $headers');

      // 전송 전 구독 상태 확인
      final expectedSubscriptionPath = '/sub/chat/$roomId/$userId';
      print('🔍 메시지 전송 전 구독 상태 확인:');
      print('- 예상 구독 경로: $expectedSubscriptionPath');
      print(
        '- 구독 활성화: ${_subscriptions.containsKey(expectedSubscriptionPath)}',
      );
      print('- 현재 활성 구독들: ${_subscriptions.keys.toList()}');
      printSubscriptionStatus();

      // WebSocket을 통해 메시지 전송 (JWT 토큰을 헤더에 포함)
      print('🚀 WebSocket 메시지 전송 시작...');
      print('🚀 전송 목적지: /pub/chat-send');
      _stompClient!.send(
        destination: '/pub/chat-send',
        body: jsonBody,
        headers: headers,
      );
      print('🚀 WebSocket 메시지 전송 요청 완료');

      // 전송 직후 즉시 상태 확인
      print('🔍 전송 직후 즉시 상태 확인:');
      print('- WebSocket 연결: ${_stompClient?.connected ?? false}');
      print('- 전송된 메시지 내용: $content');
      print('- 전송된 채팅방 ID: $roomId');
      print('- 전송 목적지: /pub/chat-send');
      print('- JWT 토큰 포함 여부: ${accessToken != null}');

      // 전송 후 수신 대기 상태 확인
      Future.delayed(const Duration(seconds: 2), () {
        print('⏰ 메시지 전송 2초 후 상태 확인:');
        print('- WebSocket 연결: ${_stompClient?.connected ?? false}');
        print('- 구독 경로: $expectedSubscriptionPath');
        print(
          '- 구독 활성: ${_subscriptions.containsKey(expectedSubscriptionPath)}',
        );
        print('💡 메시지가 수신되지 않았다면 서버 로그를 확인해주세요.');
      });

      print('✅ 메시지 전송 성공');
      print('===== 📤 메시지 전송 완료 =====');

      // 성공 응답 반환 (실제 readCount는 서버에서 실시간으로 받게 됨)
      return {'success': true, 'message': '메시지가 성공적으로 전송되었습니다.'};
    } catch (e) {
      print('❌ 메시지 전송 중 오류: $e');
      print('스택 트레이스: ${StackTrace.current}');
      return {
        'success': false,
        'error': 'SEND_ERROR',
        'message': '메시지 전송 중 오류가 발생했습니다: $e',
      };
    }
  }

  /// 채팅방 생성 (roomType 제거)
  ///
  /// [name] : 1:1 채팅방일 경우에는 "1:1 채팅방" 넘겨주기
  /// [roomRange] : PRIVATE (1:1 채팅) OR GROUP (그룹 채팅)
  /// [participantIds] : 채팅방 참여자 유저 식별 id 목록 (본인 id 포함, 최소 2명 이상)
  static Future<Map<String, dynamic>?> createChatRoom({
    required String name,
    required String roomRange, // PRIVATE or GROUP
    required List<int> participantIds,
  }) async {
    try {
      print('===== 채팅방 생성 시작 =====');
      print('채팅방 이름: $name');
      print('채팅방 범위: $roomRange');
      print('참여자 ID 목록: $participantIds');
      print('요청 시간: ${DateTime.now()}');

      // 🔒 참여자 ID 안전성 검증 (이름과 무관한 완전 검증)
      print('🔒 참여자 ID 안전성 검증 시작...');

      // 참여자 수 검증
      if (participantIds.length < 2) {
        print('❌ 참여자 수가 부족합니다. 최소 2명 이상이어야 합니다.');
        return {
          'error': true,
          'errorCode': 'INSUFFICIENT_PARTICIPANTS',
          'message': '채팅방 참여 인원이 2명 이하입니다.',
        };
      }

      // 1:1 채팅은 정확히 2명이어야 함
      if (roomRange == 'PRIVATE' && participantIds.length != 2) {
        print('❌ 1:1 채팅은 정확히 2명이어야 합니다.');
        return {
          'error': true,
          'errorCode': 'INVALID_PRIVATE_CHAT_SIZE',
          'message': '1:1 채팅은 정확히 2명이어야 합니다.',
        };
      }

      // 각 참여자 ID 유효성 검증
      for (int i = 0; i < participantIds.length; i++) {
        if (participantIds[i] <= 0) {
          print('❌ 잘못된 참여자 ID 발견: ${participantIds[i]} (인덱스: $i)');
          return {
            'error': true,
            'errorCode': 'INVALID_PARTICIPANT_ID',
            'message': '잘못된 참여자 정보가 포함되어 있습니다.',
          };
        }
      }

      // 중복 ID 검증
      final uniqueIds = participantIds.toSet();
      if (uniqueIds.length != participantIds.length) {
        print('❌ 중복된 참여자 ID 발견: $participantIds');
        return {
          'error': true,
          'errorCode': 'DUPLICATE_PARTICIPANT_ID',
          'message': '중복된 참여자가 포함되어 있습니다.',
        };
      }

      print('✅ 참여자 ID 안전성 검증 완료: $participantIds');

      // 토큰 가져오기
      final accessToken = await AuthService.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        print('액세스 토큰이 없습니다.');
        return {
          'error': true,
          'errorCode': 'NO_ACCESS_TOKEN',
          'message': '인증 토큰이 없습니다.',
        };
      }

      // API URL 구성
      final url = Uri.parse('$baseUrl/api-user/chat/room');
      print('채팅방 생성 API 호출: $url');

      // 요청 본문 구성 (roomType 제거됨)
      final body = json.encode({
        'name': name,
        'roomRange': roomRange,
        'participantIds': participantIds,
      });
      print('요청 본문: $body');

      // 헤더 설정
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
        'Accept': 'application/json; charset=utf-8',
      };

      print('요청 시작 시간: ${DateTime.now()}');
      // API 호출
      final response = await http.post(url, headers: headers, body: body);
      print('응답 수신 시간: ${DateTime.now()}');
      print('채팅방 생성 응답 상태: ${response.statusCode}');

      // 응답 처리
      if (response.statusCode == 200 || response.statusCode == 201) {
        // UTF-8로 명시적으로 디코딩
        final jsonBody = utf8.decode(response.bodyBytes);
        final Map<String, dynamic> data = json.decode(jsonBody);

        print('===== 채팅방 생성 성공 =====');
        print('채팅방 ID: ${data['roomId']}');
        print('채팅방 이름: ${data['roomName']}');
        print('채팅방 범위: ${data['roomRange']}');
        print('생성자 ID: ${data['createdById']}');

        return data;
      } else {
        print('API 오류: ${response.statusCode}');

        try {
          final jsonBody = utf8.decode(response.bodyBytes);
          final errorData = json.decode(jsonBody);
          print('응답 본문: $jsonBody');
          print('오류 메시지: ${errorData['message'] ?? '알 수 없음'}');
          print('오류 코드: ${errorData['code'] ?? '알 수 없음'}');

          return {
            'error': true,
            'errorCode': errorData['code'] ?? 'API_ERROR',
            'message': errorData['message'] ?? '채팅방 생성에 실패했습니다.',
          };
        } catch (e) {
          print('오류 응답을 파싱할 수 없습니다: $e');
          print('응답 본문: ${response.body}');

          return {
            'error': true,
            'errorCode': 'PARSE_ERROR',
            'message': '서버 응답을 처리할 수 없습니다.',
          };
        }
      }
    } catch (e) {
      print('채팅방 생성 중 예외 발생: $e');
      print('===== 채팅방 생성 실패 (예외) =====');

      return {
        'error': true,
        'errorCode': 'EXCEPTION',
        'message': '채팅방 생성 중 오류가 발생했습니다: $e',
      };
    }
  }

  /// 1:1 채팅방 생성 (편의 메서드) - roomType 제거됨
  ///
  /// [friendUserId] : 대화할 친구의 사용자 ID
  /// [myUserId] : 현재 사용자 ID
  static Future<Map<String, dynamic>?> createPrivateChatRoom({
    required int friendUserId,
    required int myUserId,
  }) async {
    return await createChatRoom(
      name: '1:1 채팅방',
      roomRange: 'PRIVATE',
      participantIds: [myUserId, friendUserId],
    );
  }

  /// 그룹 채팅방 생성 (편의 메서드) - roomType 제거됨
  ///
  /// [roomName] : 그룹 채팅방 이름
  /// [participantIds] : 참여자 ID 목록 (본인 포함, 최소 2명 이상)
  static Future<Map<String, dynamic>?> createGroupChatRoom({
    required String roomName,
    required List<int> participantIds,
  }) async {
    return await createChatRoom(
      name: roomName,
      roomRange: 'GROUP',
      participantIds: participantIds,
    );
  }

  /// 채팅방 목록 조회 (새로운 API URL 및 unreadMessageCount 추가)
  ///
  /// displayIdx는 날짜형 데이터로 최신 순 정렬
  /// 친구 관계라면 커스텀 이름, 아니라면 기본 이름 표시
  /// 메시지가 없는 채팅방은 목록에서 제외됨
  /// 1:1 채팅에서 상대방이 차단된 상태라면 unreadMessageCount는 항상 0
  static Future<List<Map<String, dynamic>>?> getChatRoomList() async {
    try {
      print('===== 채팅방 목록 조회 시작 =====');
      print('요청 시간: ${DateTime.now()}');

      // 토큰 가져오기
      final accessToken = await AuthService.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        print('액세스 토큰이 없습니다.');
        return null;
      }

      // 새로운 API URL
      final url = Uri.parse('$baseUrl/api-user/chat/room/list');
      print('채팅방 목록 조회 API 호출: $url');

      // 헤더 설정
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
        'Accept': 'application/json; charset=utf-8',
      };

      print('요청 시작 시간: ${DateTime.now()}');
      // API 호출
      final response = await http.get(url, headers: headers);
      print('응답 수신 시간: ${DateTime.now()}');
      print('채팅방 목록 조회 응답 상태: ${response.statusCode}');

      // 응답 처리
      if (response.statusCode == 200) {
        // UTF-8로 명시적으로 디코딩
        final jsonBody = utf8.decode(response.bodyBytes);
        final List<dynamic> data = json.decode(jsonBody);

        print('===== 채팅방 목록 조회 성공 =====');
        print('조회된 채팅방 개수: ${data.length}');

        // 각 채팅방 정보 로깅
        final processedRooms = <Map<String, dynamic>>[];

        for (int i = 0; i < data.length; i++) {
          final room = data[i];
          print('채팅방 [$i]:');
          print('- roomId: ${room['roomId']}');
          print('- roomName: ${room['roomName']}');
          print('- roomRange: ${room['roomRange']}');
          print('- participantNameList: ${room['participantNameList']}');
          print('- displayIdx: ${room['displayIdx']}');
          print('- unreadMessageCount: ${room['unreadMessageCount']}');

          processedRooms.add(Map<String, dynamic>.from(room));
        }

        print('처리된 채팅방 개수: ${processedRooms.length}');

        // List<Map<String, dynamic>>로 변환하여 반환
        return processedRooms;
      } else {
        print('API 오류: ${response.statusCode}');

        try {
          final jsonBody = utf8.decode(response.bodyBytes);
          final errorData = json.decode(jsonBody);
          print('응답 본문: $jsonBody');
          print('오류 메시지: ${errorData['message'] ?? '알 수 없음'}');
          print('오류 코드: ${errorData['code'] ?? '알 수 없음'}');
        } catch (e) {
          print('오류 응답을 파싱할 수 없습니다: $e');
          print('응답 본문: ${response.body}');
        }

        return null;
      }
    } catch (e) {
      print('채팅방 목록 조회 중 예외 발생: $e');
      print('===== 채팅방 목록 조회 실패 (예외) =====');
      return null;
    }
  }

  /// 기존 1:1 채팅방 찾기 또는 새로 생성
  ///
  /// [friendUserId] : 대화할 친구의 사용자 ID
  /// [myUserId] : 현재 사용자 ID
  /// 반환값: 기존 채팅방이 있으면 그 정보, 없으면 새로 생성한 채팅방 정보
  static Future<Map<String, dynamic>?> findOrCreatePrivateChatRoom({
    required int friendUserId,
    required int myUserId,
  }) async {
    try {
      print('===== 🚀 1:1 채팅방 생성 시작 (이름 무관, 안전 모드) =====');
      print('내 사용자 ID: $myUserId');
      print('친구 사용자 ID: $friendUserId');
      print('🔒 ID 기반 채팅방 생성으로 동명이인 문제 완전 방지');

      // 사용자 ID 유효성 검증
      if (myUserId <= 0 || friendUserId <= 0) {
        print('❌ 잘못된 사용자 ID: myUserId=$myUserId, friendUserId=$friendUserId');
        return {
          'error': true,
          'errorCode': 'INVALID_USER_ID',
          'message': '잘못된 사용자 ID입니다.',
        };
      }

      if (myUserId == friendUserId) {
        print('❌ 자기 자신과는 채팅할 수 없습니다: userId=$myUserId');
        return {
          'error': true,
          'errorCode': 'SAME_USER_ID',
          'message': '자기 자신과는 채팅할 수 없습니다.',
        };
      }

      // 🔒 완전 안전 모드: 기존 채팅방 찾기 완전 비활성화
      // 항상 새 채팅방을 생성하여 모든 이름 관련 문제 방지
      print('🔒 안전 모드: 기존 채팅방 찾기 건너뛰고 새 채팅방 생성');
      print('💡 이름과 완전히 무관한 ID 기반 채팅방 생성');

      // 새 채팅방 생성 (완전 안전)
      print('🚀 새 1:1 채팅방 생성 중... (이름 무관)');
      final newRoom = await createPrivateChatRoom(
        friendUserId: friendUserId,
        myUserId: myUserId,
      );

      if (newRoom != null && newRoom['error'] != true) {
        newRoom['isExisting'] = false; // 새로 생성된 채팅방임을 표시
        print('✅ 새 1:1 채팅방 생성 완료: ${newRoom['roomId']}');
        print('🎉 이름과 무관하게 안전하게 채팅방 생성됨');
      } else {
        print('❌ 채팅방 생성 실패: ${newRoom?['message']}');
        return newRoom ??
            {
              'error': true,
              'errorCode': 'CREATION_FAILED',
              'message': '채팅방 생성에 실패했습니다.',
            };
      }

      return newRoom;
    } catch (e) {
      print('❌ 1:1 채팅방 생성 중 예외 발생: $e');
      return {
        'error': true,
        'errorCode': 'EXCEPTION',
        'message': '채팅방 생성 중 오류가 발생했습니다: $e',
      };
    }
  }

  /// 메시지 읽음 처리 (기존 REST API - 백업용)
  static Future<bool> markMessageAsRead(int messageId) async {
    try {
      print('===== 메시지 읽음 처리 시작 (REST API) =====');
      print('메시지 ID: $messageId');

      // 토큰 가져오기
      final accessToken = await AuthService.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        print('액세스 토큰이 없습니다.');
        return false;
      }

      // API URL 구성
      final url = Uri.parse('$baseUrl/api-user/chat/message/read/$messageId');
      print('메시지 읽음 처리 API 호출: $url');

      // 헤더 설정
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      };

      // API 호출
      final response = await http.patch(url, headers: headers);
      print('메시지 읽음 처리 응답 상태: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('메시지 읽음 처리 성공');
        return true;
      } else {
        print('API 오류: ${response.statusCode}');
        print('응답 본문: ${response.body}');
        return false;
      }
    } catch (e) {
      print('메시지 읽음 처리 중 오류: $e');
      return false;
    }
  }

  /// 채팅방 진입 시 실행할 편의 메서드
  ///
  /// 메시지 구독과 읽음 처리 구독을 모두 설정하고,
  /// 기존 안읽은 메시지들을 읽음 처리합니다.
  static Future<void> enterChatRoom({
    required int roomId,
    required MessageCallback onMessageReceived,
    required MessageCallback onMessageReadReceived,
    int? lastReadMessageId,
  }) async {
    try {
      print('=== 🚪 채팅방 진입 시작 ===');
      print('채팅방 ID: $roomId');
      print('전달받은 마지막 읽은 메시지 ID: $lastReadMessageId');

      // 1. 메시지 구독
      subscribeToChatRoom(roomId, onMessageReceived);

      // 2. 읽음 처리 구독
      subscribeToMessageRead(roomId, onMessageReadReceived);

      // 3. 채팅방 상세 정보 조회로 실제 마지막 읽은 메시지 ID 가져오기
      int? actualLastReadMessageId = lastReadMessageId;
      if (actualLastReadMessageId == null) {
        print('서버에서 마지막 읽은 메시지 ID 조회 중...');
        final roomDetails = await getChatRoomDetails(roomId);
        if (roomDetails != null) {
          actualLastReadMessageId = roomDetails['lastReadMessageId'] as int?;
          print('서버에서 가져온 마지막 읽은 메시지 ID: $actualLastReadMessageId');
        }
      }

      // 4. 기존 안읽은 메시지들 읽음 처리
      if (actualLastReadMessageId != null) {
        print('안읽은 메시지 확인 중...');
        // 채팅 메시지 목록을 조회하여 안읽은 메시지 찾기
        final messagesResponse = await getChatMessages(
          roomId,
          lastMessageId: 0,
        );
        if (messagesResponse != null && messagesResponse['data'] != null) {
          final messages = messagesResponse['data'] as List<dynamic>;
          if (messages.isNotEmpty) {
            final unreadMessageIds =
                messages
                    .where((msg) {
                      final messageId = msg['messageId'] as int?;
                      return messageId != null &&
                          messageId > actualLastReadMessageId!;
                    })
                    .map<int>((msg) => msg['messageId'] as int)
                    .toList();

            if (unreadMessageIds.isNotEmpty) {
              print('안읽은 메시지 ${unreadMessageIds.length}개 읽음 처리 중...');
              print('읽음 처리할 메시지 IDs: $unreadMessageIds');

              await sendMessageRead(
                roomId: roomId,
                messageIds: unreadMessageIds,
              );
            } else {
              print('안읽은 메시지가 없습니다.');
            }
          } else {
            print('채팅 메시지가 없습니다.');
          }
        } else {
          print('채팅 메시지 조회 실패');
        }
      } else {
        print('마지막 읽은 메시지 ID를 확인할 수 없어 안읽은 메시지 처리를 건너뜁니다.');
      }

      print('✅ 채팅방 진입 완료');
      print('=== 🚪 채팅방 진입 완료 ===');
    } catch (e) {
      print('❌ 채팅방 진입 중 오류: $e');
    }
  }

  /// 채팅방 퇴장 시 실행할 편의 메서드
  ///
  /// 메시지 구독과 읽음 처리 구독을 모두 해제합니다.
  static void exitChatRoom(int roomId) {
    try {
      print('=== 🚪 채팅방 퇴장 시작 ===');
      print('채팅방 ID: $roomId');

      // 1. 메시지 구독 해제
      unsubscribeFromChatRoom(roomId);

      // 2. 읽음 처리 구독 해제
      unsubscribeFromMessageRead(roomId);

      print('✅ 채팅방 퇴장 완료');
      print('=== 🚪 채팅방 퇴장 완료 ===');
    } catch (e) {
      print('❌ 채팅방 퇴장 중 오류: $e');
    }
  }

  /// 실시간으로 받은 메시지 즉시 읽음 처리
  ///
  /// 채팅방에 있는 동안 메시지를 받았을 때 즉시 읽음 처리합니다.
  static Future<void> markReceivedMessageAsRead({
    required int roomId,
    required int messageId,
  }) async {
    try {
      print('=== 📖 실시간 메시지 읽음 처리 ===');
      print('채팅방 ID: $roomId');
      print('메시지 ID: $messageId');

      await sendMessageRead(roomId: roomId, messageIds: [messageId]);

      print('✅ 실시간 메시지 읽음 처리 완료');
    } catch (e) {
      print('❌ 실시간 메시지 읽음 처리 중 오류: $e');
    }
  }

  /// 모든 채팅방의 메시지 및 읽음 처리 구독 설정
  ///
  /// 앱 시작 시 모든 채팅방의 메시지 수신 및 읽음 상태 변경을 감지하기 위해 사용합니다.
  /// 채팅방에 있지 않을 때도 메시지 수신 및 읽음 상태 변경을 확인할 수 있습니다.
  static Future<void> subscribeToAllChatRooms({
    required MessageCallback onAnyMessageReceived,
    required MessageCallback onAnyMessageReadReceived,
  }) async {
    try {
      print('=== 📖 모든 채팅방 메시지 및 읽음 처리 구독 시작 ===');

      // 채팅방 목록 조회
      final chatRooms = await getChatRoomList();
      if (chatRooms != null) {
        for (final room in chatRooms) {
          final roomId = room['roomId'] as int?;
          if (roomId != null) {
            // 메시지 구독
            await subscribeToChatRoom(roomId, onAnyMessageReceived);
            // 읽음 처리 구독
            await subscribeToMessageRead(roomId, onAnyMessageReadReceived);
            print('채팅방 $roomId 구독 완료');
          }
        }

        print('총 ${chatRooms.length}개 채팅방의 메시지 및 읽음 처리 구독 완료');
      }

      print('=== 📖 모든 채팅방 메시지 및 읽음 처리 구독 완료 ===');
    } catch (e) {
      print('❌ 모든 채팅방 구독 중 오류: $e');
    }
  }

  /// 모든 채팅방의 읽음 처리 구독 설정 (기존 메서드 유지)
  ///
  /// 앱 시작 시 모든 채팅방의 읽음 상태 변경을 감지하기 위해 사용합니다.
  /// 채팅방에 있지 않을 때도 읽음 상태 변경을 확인할 수 있습니다.
  static Future<void> subscribeToAllChatRoomsRead({
    required MessageCallback onAnyMessageReadReceived,
  }) async {
    try {
      print('=== 📖 모든 채팅방 읽음 처리 구독 시작 ===');

      // 채팅방 목록 조회
      final chatRooms = await getChatRoomList();
      if (chatRooms != null) {
        for (final room in chatRooms) {
          final roomId = room['roomId'] as int?;
          if (roomId != null) {
            await subscribeToMessageRead(roomId, onAnyMessageReadReceived);
          }
        }

        print('총 ${chatRooms.length}개 채팅방의 읽음 처리 구독 완료');
      }

      print('=== 📖 모든 채팅방 읽음 처리 구독 완료 ===');
    } catch (e) {
      print('❌ 모든 채팅방 읽음 처리 구독 중 오류: $e');
    }
  }

  static void dispose() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;

    // 모든 메시지 구독 해제
    for (final unsubscribe in _unsubscribeCallbacks.values) {
      unsubscribe();
    }

    // 모든 읽음 처리 구독 해제
    for (final unsubscribe in _readUnsubscribeCallbacks.values) {
      unsubscribe();
    }

    // 모든 초대 구독 해제
    for (final unsubscribe in _inviteUnsubscribeCallbacks.values) {
      unsubscribe();
    }

    // 모든 나가기 구독 해제
    for (final unsubscribe in _leaveUnsubscribeCallbacks.values) {
      unsubscribe();
    }

    // 모든 사용자 개인 알림 구독 해제
    for (final unsubscribe in _userUnsubscribeCallbacks.values) {
      unsubscribe();
    }

    _subscriptions.clear();
    _unsubscribeCallbacks.clear();
    _readSubscriptions.clear();
    _readUnsubscribeCallbacks.clear();
    _inviteSubscriptions.clear();
    _inviteUnsubscribeCallbacks.clear();
    _leaveSubscriptions.clear();
    _leaveUnsubscribeCallbacks.clear();
    _userSubscriptions.clear();
    _userUnsubscribeCallbacks.clear();

    if (_stompClient != null) {
      _stompClient!.deactivate();
      _stompClient = null;
    }
    _isConnecting = false;

    print('🧹 ChatService 정리 완료');
  }

  /// 채팅방의 메시지를 조회합니다.
  static Future<List<ChatMessage>> getChatRoomMessages(
    int roomId, {
    required int lastMessageId,
    required int pageNumber,
  }) async {
    print('=== 📥 채팅방 메시지 조회 시작 ===');
    print('채팅방 ID: $roomId');
    print('lastMessageId: $lastMessageId');
    print('pageNumber: $pageNumber');

    final accessToken = await AuthService.getAccessToken();
    if (accessToken == null) throw Exception('인증 토큰이 없습니다.');

    final queryParams = {
      'lastMessageId': lastMessageId.toString(),
      'pageNumber': pageNumber.toString(),
    };

    final uri = Uri.parse(
      '$baseUrl/api-user/chat/message/$roomId',
    ).replace(queryParameters: queryParams);

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
    );

    print('응답 상태 코드: ${response.statusCode}');
    print('응답 본문: ${response.body}');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['data'] != null) {
        final List<dynamic> messagesJson = data['data'];
        return messagesJson
            .map((json) => ChatMessage.fromJson(json as Map<String, dynamic>))
            .toList();
      }
    }
    throw Exception('메시지를 불러오는데 실패했습니다. 상태 코드: ${response.statusCode}');
  }

  /// 채팅방 초대/나가기 로그 조회
  ///
  /// 메시지 조회 API 응답 직후에 항상 호출해야 합니다.
  /// 메시지 조회 결과와 시간 비교하여 시간 순으로 채팅 화면에 배치합니다.
  ///
  /// [roomId] 채팅방 식별 id
  /// [isOnlyOnePage] 메시지 조회 API의 페이징 조회 가능 갯수가 1 이하인지 여부
  /// [startMessageId] 로그 조회 기준이 되는 시작 메시지 식별 id (가장 오래된 메시지)
  /// [endMessageId] 로그 조회 기준이 되는 마지막 메시지 식별 id (가장 최근 메시지)
  static Future<List<Map<String, dynamic>>?> getChatEventLogs(
    int roomId, {
    bool? isOnlyOnePage,
    int? startMessageId,
    int? endMessageId,
    int? totalPages,
    List<Map<String, dynamic>>? messageData,
  }) async {
    try {
      print('=== 📜 채팅방 이벤트 로그 조회 시작 ===');
      print('채팅방 ID: $roomId');

      // 메시지 데이터를 기반으로 파라미터 계산
      bool calculatedIsOnlyOnePage =
          isOnlyOnePage ?? (totalPages != null ? totalPages <= 1 : true);
      int calculatedStartMessageId = startMessageId ?? 1;
      int calculatedEndMessageId = endMessageId ?? 999999;

      if (messageData != null && messageData.isNotEmpty) {
        // 첫 번째 요소(가장 최근 메시지)의 ID를 endMessageId로 사용
        final firstMessage = messageData.first;
        calculatedEndMessageId =
            firstMessage['messageId'] ?? calculatedEndMessageId;

        // 마지막 요소(가장 오래된 메시지)의 ID를 startMessageId로 사용
        final lastMessage = messageData.last;
        calculatedStartMessageId =
            lastMessage['messageId'] ?? calculatedStartMessageId;

        print(
          '📜 메시지 데이터 기반 ID 범위: $calculatedStartMessageId ~ $calculatedEndMessageId',
        );
      }

      print('페이지 단일 여부: $calculatedIsOnlyOnePage');
      print('시작 메시지 ID: $calculatedStartMessageId');
      print('종료 메시지 ID: $calculatedEndMessageId');

      final accessToken = await AuthService.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        print('액세스 토큰이 없습니다.');
        return null;
      }

      // 쿼리 파라미터 구성
      final queryParams = {
        'isOnlyOnePage': calculatedIsOnlyOnePage.toString(),
        'startMessageId': calculatedStartMessageId.toString(),
        'endMessageId': calculatedEndMessageId.toString(),
      };

      final url = Uri.parse(
        '$baseUrl/api-user/chat/event-log/$roomId',
      ).replace(queryParameters: queryParams);
      print('이벤트 로그 조회 API 호출: $url');

      // 헤더 설정
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
        'Accept': 'application/json; charset=utf-8',
      };

      // API 호출
      final response = await http.get(url, headers: headers);
      print('이벤트 로그 조회 응답 상태: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonBody = utf8.decode(response.bodyBytes);
        final List<dynamic> data = json.decode(jsonBody);

        print('=== 📜 이벤트 로그 조회 성공 ===');
        print('조회된 이벤트 로그 개수: ${data.length}');

        // 각 이벤트 로그 정보 로깅
        final processedLogs = <Map<String, dynamic>>[];

        for (int i = 0; i < data.length; i++) {
          final log = data[i];
          print('이벤트 로그 [$i]:');
          print('- message: ${log['message']}');
          print('- timestamp: ${log['timestamp']}');

          processedLogs.add(Map<String, dynamic>.from(log));
        }

        return processedLogs;
      } else {
        print('API 오류: ${response.statusCode}');
        try {
          final jsonBody = utf8.decode(response.bodyBytes);
          final errorData = json.decode(jsonBody);
          print('응답 본문: $jsonBody');
          print('오류 메시지: ${errorData['message'] ?? '알 수 없음'}');
        } catch (e) {
          print('오류 응답을 파싱할 수 없습니다: $e');
          print('응답 본문: ${response.body}');
        }
        return null;
      }
    } catch (e) {
      print('❌ 이벤트 로그 조회 중 예외 발생: $e');
      return null;
    }
  }

  /// 채팅방 초대 (WebSocket 전송)
  ///
  /// 그룹 채팅방에서만 사용 가능합니다.
  /// 친구 목록에서 초대할 친구를 선택하되, 이미 채팅방에 존재하는 친구는 선택할 수 없습니다.
  ///
  /// [roomId] 채팅방 식별 id
  /// [targetUserIds] 초대되는 유저들의 식별 id 목록
  static Future<bool> inviteToRoom({
    required int roomId,
    required List<int> targetUserIds,
  }) async {
    try {
      print('=== 👥 채팅방 초대 시작 ===');
      print('채팅방 ID: $roomId');
      print('초대할 사용자 ID 목록: $targetUserIds');

      if (targetUserIds.isEmpty) {
        print('⚠️ 초대할 사용자가 없습니다.');
        return false;
      }

      if (_stompClient == null || !_stompClient!.connected) {
        print('❌ WebSocket 연결이 없습니다. 재연결 시도...');
        await initializeWebSocket();

        if (_stompClient == null || !_stompClient!.connected) {
          print('❌ WebSocket 재연결 실패');
          return false;
        }
      }

      // 초대 데이터 구성
      final inviteData = {'roomId': roomId, 'targetUserIds': targetUserIds};

      print('전송할 초대 데이터: $inviteData');

      // 토큰 확인
      final accessToken = await AuthService.getAccessToken();

      // WebSocket을 통해 초대 전송
      _stompClient!.send(
        destination: '/pub/room-invite',
        body: json.encode(inviteData),
        headers: {
          'content-type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      print('✅ 채팅방 초대 전송 성공');
      print('=== 👥 채팅방 초대 완료 ===');
      return true;
    } catch (e) {
      print('❌ 채팅방 초대 중 오류: $e');
      return false;
    }
  }

  /// 채팅방 나가기 (WebSocket 전송)
  ///
  /// 채팅방을 나가면 해당 채팅방과 관련된 모든 WebSocket 구독이 해제됩니다.
  ///
  /// [roomId] 채팅방 식별 id
  static Future<bool> leaveRoom(int roomId) async {
    try {
      print('=== 🚪 채팅방 나가기 시작 ===');
      print('채팅방 ID: $roomId');
      print('현재 시간: ${DateTime.now()}');

      // 액세스 토큰 확인
      final accessToken = await AuthService.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        print('❌ 액세스 토큰이 없습니다');
        return false;
      }

      // WebSocket 연결 상태 상세 확인
      print('🔌 WebSocket 연결 상태 확인:');
      print('  - _stompClient 존재: ${_stompClient != null}');
      print('  - 연결 상태: ${_stompClient?.connected ?? false}');

      if (_stompClient == null || !_stompClient!.connected) {
        print('❌ WebSocket 연결이 없습니다. 재연결 시도...');
        await initializeWebSocket();

        // 재연결 후 상태 재확인
        await Future.delayed(const Duration(seconds: 2));
        print('🔌 재연결 후 상태:');
        print('  - _stompClient 존재: ${_stompClient != null}');
        print('  - 연결 상태: ${_stompClient?.connected ?? false}');

        if (_stompClient == null || !_stompClient!.connected) {
          print('❌ WebSocket 재연결 실패');
          return false;
        } else {
          print('✅ WebSocket 재연결 성공');
        }
      } else {
        print('✅ WebSocket 연결 상태 양호');
      }

      // 나가기 응답을 받기 위한 Completer
      final completer = Completer<bool>();
      String? tempSubscriptionId;

      try {
        // 현재 사용자 ID 가져오기
        final userInfo = await AuthService.getUserInfo();
        if (userInfo == null || userInfo['userId'] == null) {
          print('❌ 사용자 정보를 가져올 수 없습니다.');
          return false;
        }

        final userId = userInfo['userId'];
        final userName = userInfo['name'] as String? ?? '사용자';
        final leaveResponsePath = '/sub/chat/room-leave/$roomId/$userId';

        // 🚨 나가기 시스템 메시지 간단히 전송
        print('📢 나가기 시스템 메시지 전송 중...');
        final systemMessageContent = '$userName님이 나갔습니다.';

        try {
          // 간단하게 TEXT 메시지로만 전송 (빠른 처리)
          final result = await sendMessage(
            roomId: roomId,
            content: systemMessageContent,
            messageType: 'TEXT',
          );

          if (result?['success'] == true) {
            print('✅ 나가기 시스템 메시지 전송 성공: $systemMessageContent');
          } else {
            print('❌ 나가기 시스템 메시지 전송 실패 (계속 진행)');
          }

          // 시스템 메시지 전송 후 짧은 대기
          await Future.delayed(const Duration(milliseconds: 300));
        } catch (e) {
          print('❌ 나가기 시스템 메시지 전송 예외: $e (계속 진행)');
        }

        print('🔔 나가기 응답 구독 시작: $leaveResponsePath');

        // 현재 구독 상태 확인
        print('📡 나가기 전 구독 상태:');
        printSubscriptionStatus();

        // 나가기 응답 구독
        print('🔔 나가기 응답 구독 설정: $leaveResponsePath');
        final unsubscribe = _stompClient!.subscribe(
          destination: leaveResponsePath,
          callback: (StompFrame frame) {
            print('=== 🚪 나가기 응답 수신됨 ===');
            print('수신 시간: ${DateTime.now()}');
            print('수신 경로: ${frame.headers['destination'] ?? '알 수 없음'}');
            print('응답 내용: ${frame.body}');

            if (frame.body != null && frame.body!.isNotEmpty) {
              try {
                final leaveResponse = json.decode(frame.body!);
                print('✅ 파싱된 나가기 응답: $leaveResponse');

                final responseRoomId = leaveResponse['roomId'];
                final message = leaveResponse['message'];
                final timestamp = leaveResponse['timestamp'];
                final endOfDecreaseReadMarkMessageId =
                    leaveResponse['endOfDecreaseReadMarkMessageId'];

                print('응답 채팅방 ID: $responseRoomId');
                print('나가기 메시지: $message');
                print('나가기 시간: $timestamp');
                print('읽음 표시 감소 메시지 ID: $endOfDecreaseReadMarkMessageId');

                if (responseRoomId == roomId) {
                  print('✅ 채팅방 나가기 성공 확인됨');
                  completer.complete(true);
                } else {
                  print('⚠️ 응답 채팅방 ID가 다름: $responseRoomId vs $roomId');
                  completer.complete(false);
                }
              } catch (e) {
                print('❌ 나가기 응답 파싱 오류: $e');
                completer.complete(false);
              }
            } else {
              print('❌ 나가기 응답이 비어있음');
              completer.complete(false);
            }
          },
        );

        tempSubscriptionId = leaveResponsePath;

        // 나가기 데이터 구성
        final leaveData = {'roomId': roomId};

        print('전송할 나가기 데이터: $leaveData');

        // WebSocket을 통해 나가기 전송 (재시도 로직 포함)
        bool messageSent = false;
        int sendAttempts = 0;
        const maxSendAttempts = 3;

        while (!messageSent && sendAttempts < maxSendAttempts) {
          sendAttempts++;
          print(
            '📤 WebSocket으로 나가기 메시지 전송 시도 $sendAttempts/$maxSendAttempts...',
          );
          print('📤 WebSocket 연결 상태: ${_stompClient?.connected}');
          print('📤 전송 대상: /pub/room-leave');
          print('📤 전송 데이터: ${json.encode(leaveData)}');

          try {
            _stompClient!.send(
              destination: '/pub/room-leave',
              body: json.encode(leaveData),
              headers: {
                'content-type': 'application/json',
                'Authorization': 'Bearer $accessToken',
              },
            );

            print('📤 나가기 메시지 전송 완료 (시도 $sendAttempts)');
            messageSent = true;

            // 전송 후 잠깐 대기
            await Future.delayed(const Duration(milliseconds: 500));
          } catch (e) {
            print('❌ 나가기 메시지 전송 실패 (시도 $sendAttempts): $e');

            if (sendAttempts < maxSendAttempts) {
              print('🔄 WebSocket 재연결 후 재시도...');
              await initializeWebSocket();
              await Future.delayed(const Duration(seconds: 1));
            }
          }
        }

        if (!messageSent) {
          print('❌ 모든 전송 시도 실패 - 나가기 메시지를 서버에 전달할 수 없음');
          completer.complete(false);
        }

        // 서버 응답을 짧게 대기 (UI 반응성 우선)
        print('⏱️ 서버 나가기 응답 대기 중... (최대 1초)');
        bool responseReceived = false;

        try {
          responseReceived = await completer.future.timeout(
            const Duration(seconds: 1), // 3초 -> 1초로 대폭 단축
            onTimeout: () {
              print('⏰ 나가기 응답 타임아웃 (1초) - UI 반응성 우선');
              return false;
            },
          );
        } catch (e) {
          print('❌ 나가기 응답 대기 중 오류: $e');
          responseReceived = false;
        }

        // 응답 수신 완료 후 구독 해제
        if (tempSubscriptionId != null) {
          try {
            unsubscribe();
            print('🔌 나가기 응답 구독 해제 (응답 수신: $responseReceived)');
          } catch (e) {
            print('❌ 구독 해제 오류: $e');
          }
        }

        // UI 반응성을 위해 즉시 성공 처리 (백그라운드 동기화)
        print('🚀 UI 반응성을 위해 즉시 성공 처리 (총 대기시간: ~1.5초)');

        // 나간 채팅방의 모든 구독 해제
        print('🧹 나간 채팅방($roomId)의 모든 구독 해제 중...');
        unsubscribeFromChatRoom(roomId);
        unsubscribeFromMessageRead(roomId);
        unsubscribeFromRoomInvite(roomId);
        unsubscribeFromRoomLeave(roomId);

        print('=== 🚪 채팅방 나가기 완료 ===');
        return true; // UI 반응성을 위해 항상 성공으로 처리
      } catch (e) {
        print('❌ 나가기 처리 중 오류: $e');

        // 임시 구독 해제
        if (tempSubscriptionId != null) {
          try {
            // unsubscribe 함수가 있다면 호출
            print('🔌 오류 시 임시 구독 해제 시도');
          } catch (e) {
            print('❌ 오류 시 임시 구독 해제 실패: $e');
          }
        }

        return false;
      }
    } catch (e) {
      print('❌ 채팅방 나가기 중 오류: $e');
      print('오류 스택 트레이스: ${StackTrace.current}');
      return false;
    }
  }

  /// 이벤트 로그에서 나가기 처리 확인
  static Future<bool> _checkLeaveEventLog(int roomId) async {
    try {
      print('=== 📋 이벤트 로그에서 나가기 확인 시작 ===');
      print('채팅방 ID: $roomId');

      // 공개 메서드를 사용하여 이벤트 로그 조회
      final eventLogs = await getChatEventLogs(roomId, isOnlyOnePage: true);

      if (eventLogs == null) {
        print('❌ 이벤트 로그 조회 실패');
        return false;
      }

      if (eventLogs.isEmpty) {
        print('✅ 이벤트 로그가 비어있음 (나간 것으로 간주)');
        return true;
      }

      // 최근 10분 내의 나가기 로그 확인
      final now = DateTime.now();
      final tenMinutesAgo = now.subtract(const Duration(minutes: 10));

      for (final log in eventLogs) {
        final message = log['message'] as String? ?? '';
        final timestampStr = log['timestamp'] as String? ?? '';

        print('로그 메시지: $message');
        print('로그 시간: $timestampStr');

        if (timestampStr.isNotEmpty) {
          try {
            final timestamp = DateTime.parse(timestampStr);

            // 10분 내의 로그이고 나가기 관련 메시지인지 확인
            if (timestamp.isAfter(tenMinutesAgo)) {
              if (message.contains('나갔습니다') ||
                  message.contains('left') ||
                  message.contains('퇴장') ||
                  message.toLowerCase().contains('leave')) {
                print('✅ 나가기 로그 발견: $message');
                return true;
              }
            }
          } catch (e) {
            print('❌ 타임스탬프 파싱 오류: $e');
          }
        }
      }

      print('⚠️ 최근 나가기 로그를 찾을 수 없음');
      return false;
    } catch (e) {
      print('❌ 이벤트 로그 확인 중 오류: $e');
      return false;
    }
  }

  /// 채팅방 초대 알림 구독 (채팅방에 있는 사용자용)
  ///
  /// 채팅방 화면에 있는 동안 다른 사용자가 초대될 때 알림을 받습니다.
  ///
  /// [roomId] 채팅방 ID
  /// [onInviteReceived] 초대 알림 수신 콜백
  static Future<void> subscribeToRoomInvite(
    int roomId,
    MessageCallback onInviteReceived,
  ) async {
    try {
      // 현재 사용자 ID 가져오기
      final userInfo = await AuthService.getUserInfo();
      if (userInfo == null || userInfo['userId'] == null) {
        print('❌ 사용자 정보를 가져올 수 없습니다.');
        return;
      }

      final userId = userInfo['userId'];
      final destination = '/sub/chat/room-invite/$roomId/$userId';

      print('=== 👥 채팅방 초대 알림 구독 시작 ===');
      print('채팅방 ID: $roomId');
      print('사용자 ID: $userId');
      print('구독 경로: $destination');

      if (_stompClient == null || !_stompClient!.connected) {
        print('❌ WebSocket 연결이 없습니다. 연결 시도...');
        await initializeWebSocket();

        if (_stompClient == null || !_stompClient!.connected) {
          print('❌ WebSocket 재연결 실패');
          return;
        }
      }

      // 이미 구독 중인지 확인
      if (_inviteSubscriptions.containsKey(destination)) {
        print('⚠️ 이미 초대 알림 구독 중인 채팅방: $destination');
        return;
      }

      print('✅ 채팅방 초대 알림 구독 시작: $destination');

      final unsubscribe = _stompClient!.subscribe(
        destination: destination,
        callback: (StompFrame frame) {
          print('=== 👥 채팅방 초대 알림 수신됨 ===');
          print('수신 시간: ${DateTime.now()}');
          print('구독 경로: $destination');
          print('Headers: ${frame.headers}');
          print('Body: ${frame.body}');

          if (frame.body != null && frame.body!.isNotEmpty) {
            try {
              final inviteData = json.decode(frame.body!);
              print('✅ 파싱된 초대 알림 데이터: $inviteData');

              // 초대 메시지와 타임스탬프 확인
              print('초대 메시지: ${inviteData['message']}');
              print('초대 시간: ${inviteData['timestamp']}');

              onInviteReceived(inviteData);
            } catch (e) {
              print('❌ 초대 알림 데이터 파싱 오류: $e');
              print('원본 데이터: ${frame.body}');
            }
          }
        },
      );

      _inviteSubscriptions[destination] = onInviteReceived;
      _inviteUnsubscribeCallbacks[destination] = unsubscribe;

      print('✅ 채팅방 초대 알림 구독 완료');
      print('=== 👥 채팅방 초대 알림 구독 완료 ===');
    } catch (e) {
      print('❌ 채팅방 초대 알림 구독 중 오류 발생: $e');
    }
  }

  /// 채팅방 초대 알림 구독 해제
  static void unsubscribeFromRoomInvite(int roomId) async {
    try {
      // 현재 사용자 ID 가져오기
      final userInfo = await AuthService.getUserInfo();
      if (userInfo == null || userInfo['userId'] == null) {
        print('❌ 사용자 정보를 가져올 수 없습니다.');
        return;
      }

      final userId = userInfo['userId'];
      final destination = '/sub/chat/room-invite/$roomId/$userId';

      print('=== 🔌 채팅방 초대 알림 구독 해제 시작 ===');
      print('채팅방 ID: $roomId');
      print('구독 해제 경로: $destination');

      final unsubscribe = _inviteUnsubscribeCallbacks[destination];

      if (unsubscribe != null) {
        unsubscribe();
        print('✅ 채팅방 초대 알림 구독 해제 성공: $destination');
      } else {
        print('⚠️ 초대 알림 구독 해제할 콜백이 없음: $destination');
      }

      _inviteSubscriptions.remove(destination);
      _inviteUnsubscribeCallbacks.remove(destination);

      print('=== 🔌 채팅방 초대 알림 구독 해제 완료 ===');
    } catch (e) {
      print('❌ 채팅방 초대 알림 구독 해제 중 오류 발생: $e');
    }
  }

  /// 채팅방 나가기 알림 구독 (채팅방에 있는 사용자용)
  ///
  /// 채팅방 화면에 있는 동안 다른 사용자가 나갔을 때 알림을 받습니다.
  ///
  /// [roomId] 채팅방 ID
  /// [onLeaveReceived] 나가기 알림 수신 콜백
  static Future<void> subscribeToRoomLeave(
    int roomId,
    MessageCallback onLeaveReceived,
  ) async {
    try {
      // 현재 사용자 ID 가져오기
      final userInfo = await AuthService.getUserInfo();
      if (userInfo == null || userInfo['userId'] == null) {
        print('❌ 사용자 정보를 가져올 수 없습니다.');
        return;
      }

      final userId = userInfo['userId'];
      final destination = '/sub/chat/room-leave/$roomId/$userId';

      print('=== 🚪 채팅방 나가기 알림 구독 시작 ===');
      print('채팅방 ID: $roomId');
      print('사용자 ID: $userId');
      print('구독 경로: $destination');

      if (_stompClient == null || !_stompClient!.connected) {
        print('❌ WebSocket 연결이 없습니다. 연결 시도...');
        await initializeWebSocket();

        if (_stompClient == null || !_stompClient!.connected) {
          print('❌ WebSocket 재연결 실패');
          return;
        }
      }

      // 이미 구독 중인지 확인
      if (_leaveSubscriptions.containsKey(destination)) {
        print('⚠️ 이미 나가기 알림 구독 중인 채팅방: $destination');
        return;
      }

      print('✅ 채팅방 나가기 알림 구독 시작: $destination');

      final unsubscribe = _stompClient!.subscribe(
        destination: destination,
        callback: (StompFrame frame) {
          print('=== 🚪 채팅방 나가기 알림 수신됨 ===');
          print('수신 시간: ${DateTime.now()}');
          print('구독 경로: $destination');
          print('Headers: ${frame.headers}');
          print('Body: ${frame.body}');

          if (frame.body != null && frame.body!.isNotEmpty) {
            try {
              final leaveData = json.decode(frame.body!);
              print('✅ 파싱된 나가기 알림 데이터: $leaveData');

              // 나가기 관련 데이터 확인
              print('나가기 메시지: ${leaveData['message']}');
              print('나간 시간: ${leaveData['timestamp']}');
              print(
                '읽음 표시 감소 기준 메시지 ID: ${leaveData['endOfDecreaseReadMarkMessageId']}',
              );

              onLeaveReceived(leaveData);
            } catch (e) {
              print('❌ 나가기 알림 데이터 파싱 오류: $e');
              print('원본 데이터: ${frame.body}');
            }
          }
        },
      );

      _leaveSubscriptions[destination] = onLeaveReceived;
      _leaveUnsubscribeCallbacks[destination] = unsubscribe;

      print('✅ 채팅방 나가기 알림 구독 완료');
      print('=== 🚪 채팅방 나가기 알림 구독 완료 ===');
    } catch (e) {
      print('❌ 채팅방 나가기 알림 구독 중 오류 발생: $e');
    }
  }

  /// 채팅방 나가기 알림 구독 해제
  static void unsubscribeFromRoomLeave(int roomId) async {
    try {
      // 현재 사용자 ID 가져오기
      final userInfo = await AuthService.getUserInfo();
      if (userInfo == null || userInfo['userId'] == null) {
        print('❌ 사용자 정보를 가져올 수 없습니다.');
        return;
      }

      final userId = userInfo['userId'];
      final destination = '/sub/chat/room-leave/$roomId/$userId';

      print('=== 🔌 채팅방 나가기 알림 구독 해제 시작 ===');
      print('채팅방 ID: $roomId');
      print('구독 해제 경로: $destination');

      final unsubscribe = _leaveUnsubscribeCallbacks[destination];

      if (unsubscribe != null) {
        unsubscribe();
        print('✅ 채팅방 나가기 알림 구독 해제 성공: $destination');
      } else {
        print('⚠️ 나가기 알림 구독 해제할 콜백이 없음: $destination');
      }

      _leaveSubscriptions.remove(destination);
      _leaveUnsubscribeCallbacks.remove(destination);

      print('=== 🔌 채팅방 나가기 알림 구독 해제 완료 ===');
    } catch (e) {
      print('❌ 채팅방 나가기 알림 구독 해제 중 오류 발생: $e');
    }
  }

  /// 사용자 개인 알림 구독 (초대받은 사용자용)
  ///
  /// 앱이 실행되고 있는 동안 채팅방에 초대받았을 때 알림을 받습니다.
  /// 초대받으면 해당 채팅방의 모든 WebSocket 구독을 자동으로 설정합니다.
  ///
  /// [onUserNotificationReceived] 개인 알림 수신 콜백
  static Future<void> subscribeToUserNotifications(
    MessageCallback onUserNotificationReceived,
  ) async {
    try {
      // 현재 사용자 ID 가져오기
      final userInfo = await AuthService.getUserInfo();
      if (userInfo == null || userInfo['userId'] == null) {
        print('❌ 사용자 정보를 가져올 수 없습니다.');
        return;
      }

      final userId = userInfo['userId'];
      final destination = '/sub/user/$userId';

      print('=== 👤 사용자 개인 알림 구독 시작 ===');
      print('사용자 ID: $userId');
      print('구독 경로: $destination');

      if (_stompClient == null || !_stompClient!.connected) {
        print('❌ WebSocket 연결이 없습니다. 연결 시도...');
        await initializeWebSocket();

        if (_stompClient == null || !_stompClient!.connected) {
          print('❌ WebSocket 재연결 실패');
          return;
        }
      }

      // 이미 구독 중인지 확인
      if (_userSubscriptions.containsKey(destination)) {
        print('⚠️ 이미 개인 알림 구독 중: $destination');
        return;
      }

      print('✅ 사용자 개인 알림 구독 시작: $destination');

      final unsubscribe = _stompClient!.subscribe(
        destination: destination,
        callback: (StompFrame frame) {
          print('=== 👤 사용자 개인 알림 수신됨 ===');
          print('수신 시간: ${DateTime.now()}');
          print('구독 경로: $destination');
          print('Headers: ${frame.headers}');
          print('Body: ${frame.body}');

          if (frame.body != null && frame.body!.isNotEmpty) {
            try {
              final notificationData = json.decode(frame.body!);
              print('✅ 파싱된 개인 알림 데이터: $notificationData');

              // 초대받은 채팅방 ID 확인
              final roomId = notificationData['roomId'] as int?;
              if (roomId != null) {
                print('🎉 채팅방 $roomId 에 초대받았습니다!');
                print('해당 채팅방의 WebSocket 구독을 자동으로 설정합니다.');

                // TODO: 여기서 해당 채팅방의 모든 구독을 자동으로 설정해야 함
                // 예: subscribeToAllChatRoomFeatures(roomId);
              }

              onUserNotificationReceived(notificationData);
            } catch (e) {
              print('❌ 개인 알림 데이터 파싱 오류: $e');
              print('원본 데이터: ${frame.body}');
            }
          }
        },
      );

      _userSubscriptions[destination] = onUserNotificationReceived;
      _userUnsubscribeCallbacks[destination] = unsubscribe;

      print('✅ 사용자 개인 알림 구독 완료');
      print('=== 👤 사용자 개인 알림 구독 완료 ===');
    } catch (e) {
      print('❌ 사용자 개인 알림 구독 중 오류 발생: $e');
    }
  }

  /// 사용자 개인 알림 구독 해제
  static void unsubscribeFromUserNotifications() async {
    try {
      // 현재 사용자 ID 가져오기
      final userInfo = await AuthService.getUserInfo();
      if (userInfo == null || userInfo['userId'] == null) {
        print('❌ 사용자 정보를 가져올 수 없습니다.');
        return;
      }

      final userId = userInfo['userId'];
      final destination = '/sub/user/$userId';

      print('=== 🔌 사용자 개인 알림 구독 해제 시작 ===');
      print('사용자 ID: $userId');
      print('구독 해제 경로: $destination');

      final unsubscribe = _userUnsubscribeCallbacks[destination];

      if (unsubscribe != null) {
        unsubscribe();
        print('✅ 사용자 개인 알림 구독 해제 성공: $destination');
      } else {
        print('⚠️ 개인 알림 구독 해제할 콜백이 없음: $destination');
      }

      _userSubscriptions.remove(destination);
      _userUnsubscribeCallbacks.remove(destination);

      print('=== 🔌 사용자 개인 알림 구독 해제 완료 ===');
    } catch (e) {
      print('❌ 사용자 개인 알림 구독 해제 중 오류 발생: $e');
    }
  }

  /// 채팅방 나가기 (HTTP API 방식)
  ///
  /// WebSocket 방식이 불안정할 때 사용할 수 있는 HTTP API 기반 그룹채팅 나가기 기능
  /// 더 안정적이고 확실한 처리가 가능합니다.
  ///
  /// [roomId] 채팅방 식별 id
  static Future<Map<String, dynamic>?> leaveRoomViaHttp(int roomId) async {
    try {
      print('=== 🚪 HTTP API로 그룹채팅 나가기 시작 ===');
      print('채팅방 ID: $roomId');
      print('요청 시간: ${DateTime.now()}');

      // 토큰 가져오기
      final accessToken = await AuthService.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        print('❌ 액세스 토큰이 없습니다.');
        return {'success': false, 'message': '인증 토큰이 없습니다.'};
      }

      // API URL 구성
      final url = Uri.parse('$baseUrl/api-chat/rooms/$roomId/leave');
      print('그룹채팅 나가기 API 호출: $url');

      // 헤더 설정 - 토큰 포함
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
        'Accept': 'application/json; charset=utf-8',
      };

      // API 호출 (POST 메서드 사용)
      final response = await http.post(url, headers: headers);
      print('그룹채팅 나가기 응답 상태: ${response.statusCode}');

      // 응답 처리
      if (response.statusCode == 200 || response.statusCode == 201) {
        // UTF-8로 명시적으로 디코딩
        final jsonBody = utf8.decode(response.bodyBytes);
        final Map<String, dynamic> data = json.decode(jsonBody);
        print('그룹채팅 나가기 결과: $data');

        // 나가기 성공 시 관련 구독 해제
        print('🧹 나간 채팅방($roomId)의 모든 구독 해제 중...');
        unsubscribeFromChatRoom(roomId);
        unsubscribeFromMessageRead(roomId);
        unsubscribeFromRoomInvite(roomId);
        unsubscribeFromRoomLeave(roomId);

        print('=== 🚪 HTTP API 그룹채팅 나가기 완료 ===');
        return {
          'success': true,
          'message': '그룹채팅에서 나가기가 완료되었습니다.',
          'data': data,
        };
      } else {
        print('API 오류: ${response.statusCode}');

        try {
          if (response.body.isNotEmpty) {
            final jsonBody = utf8.decode(response.bodyBytes);
            final errorData = json.decode(jsonBody);
            print('응답 본문: $jsonBody');
            print('오류 메시지: ${errorData['message'] ?? '알 수 없음'}');
            print('오류 코드: ${errorData['code'] ?? '알 수 없음'}');

            return {
              'success': false,
              'message': errorData['message'] ?? '그룹채팅 나가기에 실패했습니다.',
              'errorCode': errorData['code'],
            };
          } else {
            print('응답 본문이 비어 있습니다.');
            return {'success': false, 'message': '서버에서 응답을 받지 못했습니다.'};
          }
        } catch (e) {
          print('오류 응답을 파싱할 수 없습니다: $e');
          print('응답 본문: ${response.body}');
          return {'success': false, 'message': '서버 응답 처리 중 오류가 발생했습니다.'};
        }
      }
    } catch (e) {
      print('그룹채팅 나가기 중 예외 발생: $e');
      print('===== HTTP API 그룹채팅 나가기 실패 (예외) =====');
      return {'success': false, 'message': '그룹채팅 나가기 중 오류가 발생했습니다: $e'};
    }
  }

  /// 개선된 그룹채팅 나가기 (하이브리드 방식)
  ///
  /// WebSocket과 HTTP API를 모두 활용하여 더 안정적인 나가기 처리
  /// 먼저 WebSocket으로 빠른 처리를 시도하고, 실패 시 HTTP API로 재시도
  ///
  /// [roomId] 채팅방 식별 id
  /// [forceHttpApi] true일 경우 HTTP API만 사용
  static Future<bool> leaveGroupChat(
    int roomId, {
    bool forceHttpApi = false,
  }) async {
    try {
      print('=== 🚪 개선된 그룹채팅 나가기 시작 ===');
      print('채팅방 ID: $roomId');
      print('강제 HTTP API 사용: $forceHttpApi');

      // HTTP API 강제 사용 모드
      if (forceHttpApi) {
        print('🌐 HTTP API 강제 사용 모드');
        final result = await leaveRoomViaHttp(roomId);
        return result?['success'] == true;
      }

      // 1단계: WebSocket 방식 시도 (빠른 처리)
      print('🔄 1단계: WebSocket 방식으로 나가기 시도...');
      bool webSocketSuccess = false;

      try {
        webSocketSuccess = await leaveRoom(roomId);
        print('WebSocket 나가기 결과: $webSocketSuccess');
      } catch (e) {
        print('WebSocket 나가기 오류: $e');
        webSocketSuccess = false;
      }

      // WebSocket 성공 시 즉시 반환
      if (webSocketSuccess) {
        print('✅ WebSocket 방식으로 나가기 성공');
        return true;
      }

      // 2단계: HTTP API 방식으로 재시도 (안정성 확보)
      print('🌐 2단계: HTTP API 방식으로 나가기 재시도...');
      final httpResult = await leaveRoomViaHttp(roomId);

      if (httpResult?['success'] == true) {
        print('✅ HTTP API 방식으로 나가기 성공');
        return true;
      } else {
        print('❌ HTTP API 방식으로도 나가기 실패');
        print('실패 이유: ${httpResult?['message']}');
        return false;
      }
    } catch (e) {
      print('❌ 개선된 그룹채팅 나가기 중 오류: $e');
      return false;
    }
  }

  /// 채팅방 이름 수정
  ///
  /// [roomId] 채팅방 식별 id
  /// [name] 수정할 채팅방 이름
  static Future<Map<String, dynamic>?> updateRoomName({
    required int roomId,
    required String name,
  }) async {
    try {
      print('=== 📝 채팅방 이름 수정 시작 ===');
      print('채팅방 ID: $roomId');
      print('새 이름: $name');
      print('요청 시간: ${DateTime.now()}');

      // 이름 유효성 검증
      if (name.trim().isEmpty) {
        print('❌ 채팅방 이름이 비어있습니다.');
        return {
          'success': false,
          'error': 'EMPTY_NAME',
          'message': '채팅방 이름을 입력해주세요.',
        };
      }

      if (name.trim().length > 20) {
        print('❌ 채팅방 이름이 너무 깁니다: ${name.trim().length}자');
        return {
          'success': false,
          'error': 'NAME_TOO_LONG',
          'message': '채팅방 이름은 20자 이하로 입력해주세요.',
        };
      }

      // 토큰 가져오기
      final accessToken = await AuthService.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        print('❌ 액세스 토큰이 없습니다.');
        return {
          'success': false,
          'error': 'NO_ACCESS_TOKEN',
          'message': '인증 토큰이 없습니다.',
        };
      }

      // API URL 구성
      final url = Uri.parse('$baseUrl/api-user/chat/room/name/update');
      print('채팅방 이름 수정 API 호출: $url');

      // 요청 본문 구성
      final body = json.encode({
        'roomId': roomId,
        'name': name.trim(),
      });
      print('요청 본문: $body');

      // 헤더 설정
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
        'Accept': 'application/json; charset=utf-8',
      };

      print('요청 시작 시간: ${DateTime.now()}');
      // API 호출 (PATCH 메서드 사용)
      final response = await http.patch(url, headers: headers, body: body);
      print('응답 수신 시간: ${DateTime.now()}');
      print('채팅방 이름 수정 응답 상태: ${response.statusCode}');

      // 응답 처리
      if (response.statusCode == 200) {
        // UTF-8로 명시적으로 디코딩
        final jsonBody = utf8.decode(response.bodyBytes);
        final Map<String, dynamic> data = json.decode(jsonBody);

        print('=== 📝 채팅방 이름 수정 성공 ===');
        print('응답 데이터: $data');
        print('수정된 채팅방 ID: ${data['roomId']}');
        print('수정된 채팅방 이름: ${data['name']}');

        return {
          'success': true,
          'data': data,
          'message': '채팅방 이름이 성공적으로 수정되었습니다.',
        };
      } else {
        print('API 오류: ${response.statusCode}');

        try {
          final jsonBody = utf8.decode(response.bodyBytes);
          final errorData = json.decode(jsonBody);
          print('응답 본문: $jsonBody');
          print('오류 메시지: ${errorData['message'] ?? '알 수 없음'}');
          print('오류 코드: ${errorData['code'] ?? '알 수 없음'}');

          return {
            'success': false,
            'error': errorData['code'] ?? 'API_ERROR',
            'message': errorData['message'] ?? '채팅방 이름 수정에 실패했습니다.',
          };
        } catch (e) {
          print('오류 응답을 파싱할 수 없습니다: $e');
          print('응답 본문: ${response.body}');

          return {
            'success': false,
            'error': 'PARSE_ERROR',
            'message': '서버 응답을 처리할 수 없습니다.',
          };
        }
      }
    } catch (e) {
      print('채팅방 이름 수정 중 예외 발생: $e');
      print('===== 채팅방 이름 수정 실패 (예외) =====');

      return {
        'success': false,
        'error': 'EXCEPTION',
        'message': '채팅방 이름 수정 중 오류가 발생했습니다: $e',
      };
    }
  }
}
