import 'package:flutter/material.dart';
import 'notification_service.dart';
import 'feed_comment_notification.dart';
import 'cs_comment_notification.dart';
import 'mission_reward_notification.dart';

class NotificationOverlay extends StatefulWidget {
  final Widget child;

  const NotificationOverlay({
    super.key,
    required this.child,
  });

  @override
  State<NotificationOverlay> createState() => _NotificationOverlayState();
}

class _NotificationOverlayState extends State<NotificationOverlay> {
  final NotificationService _notificationService = NotificationService();
  late final ValueNotifier<List<NotificationData>> _notificationNotifier;

  @override
  void initState() {
    super.initState();
    _notificationNotifier = _notificationService.notificationNotifier;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 기본 화면 내용
          widget.child,
          
          // 알림 오버레이
          ValueListenableBuilder<List<NotificationData>>(
            valueListenable: _notificationNotifier,
            builder: (context, notifications, child) {
              if (notifications.isEmpty) {
                return const SizedBox.shrink();
              }

              return Positioned(
                left: 0,
                right: 0,
                bottom: 130, // 100에서 130으로 변경 (30px 위로)
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8), // 16에서 8로 줄여서 더 넓게
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: notifications.map((notification) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _buildNotificationWidget(notification),
                      );
                    }).toList(),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationWidget(NotificationData notification) {
    switch (notification.type) {
      case NotificationType.feedComment:
        return FeedCommentNotification(
          message: notification.message,
          onTap: () {
            // 피드 화면으로 이동
            if (notification.onTap != null) {
              notification.onTap!();
            }
            // 알림 제거
            _notificationService.dismissNotification(notification.id);
          },
          onDismiss: () {
            _notificationService.dismissNotification(notification.id);
          },
        );
      
      case NotificationType.csComment:
        return CsCommentNotification(
          message: notification.message,
          onTap: () {
            // CS 문의 화면으로 이동
            if (notification.onTap != null) {
              notification.onTap!();
            }
            // 알림 제거
            _notificationService.dismissNotification(notification.id);
          },
          onDismiss: () {
            _notificationService.dismissNotification(notification.id);
          },
        );
      
      case NotificationType.missionReward:
        return MissionRewardNotification(
          message: notification.message,
          onTap: () {
            // 미션 화면으로 이동
            if (notification.onTap != null) {
              notification.onTap!();
            }
            // 알림 제거
            _notificationService.dismissNotification(notification.id);
          },
          onDismiss: () {
            _notificationService.dismissNotification(notification.id);
          },
        );
      
      case NotificationType.goalApproval:
        // 추후 목표 승인 알림 위젯 추가
        return _buildDefaultNotification(notification);
      
      case NotificationType.challengeUpdate:
        // 추후 챌린지 업데이트 알림 위젯 추가
        return _buildDefaultNotification(notification);
      
      case NotificationType.rewardEarned:
        // 추후 리워드 획득 알림 위젯 추가
        return _buildDefaultNotification(notification);
      
      default:
        return _buildDefaultNotification(notification);
    }
  }

  Widget _buildDefaultNotification(NotificationData notification) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: ShapeDecoration(
        color: const Color(0xCC5D6A7F),
        shape: RoundedRectangleBorder(
          side: BorderSide(
            width: 1,
            color: const Color(0xFF146AFF),
          ),
          borderRadius: BorderRadius.circular(48),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(),
            child: Icon(
              Icons.notifications,
              size: 16,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              notification.message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontFamily: 'Pretendard-Light',
                fontWeight: FontWeight.w300,
                letterSpacing: -0.24,
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              if (notification.onTap != null) {
                notification.onTap!();
              }
              _notificationService.dismissNotification(notification.id);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: ShapeDecoration(
                color: const Color(0xFF5D6A7F),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: const Text(
                '확인',
                style: TextStyle(
                  color: Color(0xFFC4C4C4),
                  fontSize: 9,
                  fontFamily: 'Pretendard-Light',
                  fontWeight: FontWeight.w300,
                  letterSpacing: -0.18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 