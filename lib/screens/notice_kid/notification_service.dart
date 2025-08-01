import 'package:flutter/material.dart';
import '../../services/feed_service.dart';
import 'dart:async';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // 현재 활성화된 알림들을 관리
  final List<NotificationData> _activeNotifications = [];
  
  // 알림 상태 변경을 위한 ValueNotifier
  final ValueNotifier<List<NotificationData>> notificationNotifier = 
      ValueNotifier<List<NotificationData>>([]);

  // 폴링 타이머
  Timer? _pollingTimer;
  bool _isPollingActive = false;
  
  // 마지막으로 확인한 알림 ID들
  final Set<int> _lastSeenNotificationIds = <int>{};

  // 알림 폴링 시작
  void startNotificationPolling() {
    if (_isPollingActive) return;
    
    _isPollingActive = true;
    print('🔔 알림 폴링 시작');
    
    // 즉시 한번 확인
    _checkForNewNotifications();
    
    // 10초마다 새로운 알림 확인
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _checkForNewNotifications();
    });
  }

  // 알림 폴링 중지
  void stopNotificationPolling() {
    _isPollingActive = false;
    _pollingTimer?.cancel();
    _pollingTimer = null;
    print('🛑 알림 폴링 중지');
  }

  // 새로운 알림 확인
  Future<void> _checkForNewNotifications() async {
    try {
      print('🔍 새로운 알림 확인 중...');
      
      final result = await FeedService.getFeedNotifications(
        page: 0,
        size: 20,
        sort: ['createdDate,desc'],
      );

      if (result != null && result['content'] is List) {
        final List<dynamic> notifications = result['content'];
        
        for (final notification in notifications) {
          final id = notification['id'] as int?;
          final type = notification['type'] as String?;
          final message = notification['message'] as String?;
          final read = notification['read'] as bool?;

          // 새로운 읽지 않은 알림인 경우
          if (id != null && read == false && !_lastSeenNotificationIds.contains(id)) {
            _lastSeenNotificationIds.add(id);
            
            print('🆕 새로운 알림 발견: $message (ID: $id, 타입: $type)');
            
            // 알림 타입에 따라 적절한 알림 표시
            _showNotificationByType(type, message, id, notification);
          }
        }
      }
    } catch (e) {
      print('⚠️ 알림 확인 중 오류: $e');
    }
  }

  // 타입별 알림 표시
  void _showNotificationByType(String? type, String? message, int id, Map<String, dynamic> notification) {
    switch (type) {
      case 'FEED_COMMENT':
        showFeedCommentNotification(
          message: message ?? '내 피드에 댓글이 달렸어요!',
          feedId: notification['feedId']?.toString(),
          commentAuthor: notification['senderName']?.toString() ?? '사용자',
          onTap: () {
            print('💬 피드 댓글 알림 탭: 피드로 이동');
            // 알림을 읽음 처리
            FeedService.markNotificationAsRead(id);
          },
        );
        break;
        
      case 'FEED_LIKE':
        showFeedCommentNotification(
          message: message ?? '내 피드에 좋아요가 눌렸어요! ❤️',
          feedId: notification['feedId']?.toString(),
          commentAuthor: notification['senderName']?.toString() ?? '사용자',
          onTap: () {
            print('❤️ 좋아요 알림 탭: 피드로 이동');
            // 알림을 읽음 처리
            FeedService.markNotificationAsRead(id);
          },
        );
        break;
        
      case 'CS_COMMENT':
        showCsCommentNotification(
          message: message ?? '내 문의 내역에 댓글이 달렸어요!',
          csId: notification['csId']?.toString(),
          onTap: () {
            print('💬 CS 댓글 알림 탭: CS 화면으로 이동');
            // 알림을 읽음 처리
            FeedService.markNotificationAsRead(id);
          },
        );
        break;
        
      case 'MISSION_REWARD':
        showMissionRewardNotification(
          message: message ?? '이번 주 미션의 보상금을 받았어요!',
          missionId: notification['missionId']?.toString(),
          onTap: () {
            print('💰 미션 보상 알림 탭: 미션 화면으로 이동');
            // 알림을 읽음 처리
            FeedService.markNotificationAsRead(id);
          },
        );
        break;
        
      default:
        // 기본 알림 표시
        showFeedCommentNotification(
          message: message ?? '새로운 알림이 있어요!',
          onTap: () {
            print('🔔 기본 알림 탭');
            // 알림을 읽음 처리
            FeedService.markNotificationAsRead(id);
          },
        );
        break;
    }
  }

  // 피드 댓글 알림 표시
  void showFeedCommentNotification({
    String? message,
    String? feedId,
    String? commentAuthor,
    VoidCallback? onTap,
  }) {
    final notification = NotificationData(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: NotificationType.feedComment,
      message: message ?? '내 피드에 댓글이 달렸어요!',
      feedId: feedId,
      commentAuthor: commentAuthor,
      onTap: onTap,
      timestamp: DateTime.now(),
    );

    _activeNotifications.add(notification);
    notificationNotifier.value = List.from(_activeNotifications);

    print('📢 피드 댓글 알림 표시: ${notification.message}');
  }

  // CS 문의 댓글 알림 표시
  void showCsCommentNotification({
    String? message,
    String? csId,
    VoidCallback? onTap,
  }) {
    final notification = NotificationData(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: NotificationType.csComment,
      message: message ?? '내 문의 내역에 댓글이 달렸어요!',
      feedId: csId, // feedId 대신 csId를 저장
      onTap: onTap,
      timestamp: DateTime.now(),
    );

    _activeNotifications.add(notification);
    notificationNotifier.value = List.from(_activeNotifications);

    print('📢 CS 댓글 알림 표시: ${notification.message}');
  }

  // 미션 보상 알림 표시
  void showMissionRewardNotification({
    String? message,
    String? missionId,
    int? rewardAmount,
    VoidCallback? onTap,
  }) {
    final notification = NotificationData(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: NotificationType.missionReward,
      message: message ?? '이번 주 미션의 보상금을 받았어요!',
      feedId: missionId, // feedId 대신 missionId를 저장
      onTap: onTap,
      timestamp: DateTime.now(),
    );

    _activeNotifications.add(notification);
    notificationNotifier.value = List.from(_activeNotifications);

    print('📢 미션 보상 알림 표시: ${notification.message}');
  }

  // 알림 제거
  void dismissNotification(String notificationId) {
    _activeNotifications.removeWhere((notification) => 
        notification.id == notificationId);
    notificationNotifier.value = List.from(_activeNotifications);
    
    print('🗑️ 알림 제거: $notificationId');
  }

  // 모든 알림 제거
  void clearAllNotifications() {
    _activeNotifications.clear();
    notificationNotifier.value = [];
    
    print('🗑️ 모든 알림 제거');
  }

  // 특정 타입의 알림만 제거
  void clearNotificationsByType(NotificationType type) {
    _activeNotifications.removeWhere((notification) => 
        notification.type == type);
    notificationNotifier.value = List.from(_activeNotifications);
    
    print('🗑️ ${type.name} 타입 알림 제거');
  }

  // 현재 활성 알림 개수
  int get activeNotificationCount => _activeNotifications.length;

  // 특정 타입의 알림이 있는지 확인
  bool hasNotificationType(NotificationType type) {
    return _activeNotifications.any((notification) => 
        notification.type == type);
  }

  // 서비스 정리
  void dispose() {
    stopNotificationPolling();
    _activeNotifications.clear();
    notificationNotifier.dispose();
  }
}

// 알림 타입 열거형
enum NotificationType {
  feedComment,
  goalApproval,
  challengeUpdate,
  rewardEarned,
  csComment,
  missionReward,
}

// 알림 데이터 클래스
class NotificationData {
  final String id;
  final NotificationType type;
  final String message;
  final String? feedId;
  final String? commentAuthor;
  final VoidCallback? onTap;
  final DateTime timestamp;
  final Duration? autoHideDuration;

  NotificationData({
    required this.id,
    required this.type,
    required this.message,
    this.feedId,
    this.commentAuthor,
    this.onTap,
    required this.timestamp,
    this.autoHideDuration = const Duration(seconds: 5),
  });

  @override
  String toString() {
    return 'NotificationData{id: $id, type: $type, message: $message}';
  }
} 