import 'package:flutter/material.dart';
import 'notification_overlay.dart';
import 'notification_service.dart';
import '../../services/global_notification_service.dart';

class ChildScreenWrapper extends StatefulWidget {
  final Widget child;
  final bool enableNotifications;

  const ChildScreenWrapper({
    super.key,
    required this.child,
    this.enableNotifications = true,
  });

  @override
  State<ChildScreenWrapper> createState() => _ChildScreenWrapperState();
}

class _ChildScreenWrapperState extends State<ChildScreenWrapper> with WidgetsBindingObserver {
  final NotificationService _notificationService = NotificationService();
  final GlobalNotificationService _globalNotificationService = GlobalNotificationService.instance;

  @override
  void initState() {
    super.initState();
    
    // 앱 생명주기 관찰자 등록
    WidgetsBinding.instance.addObserver(this);
    
    // 폴링 시작/중지를 여기서 하지 않음
    // 대신 앱 전체에서 한 번만 시작하도록 함
    print('🖼️ ChildScreenWrapper 초기화: ${widget.runtimeType}');
    
    // 초기 알림 확인 (화면 로드 후)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkGlobalNotifications();
    });
  }

  @override
  void dispose() {
    // 앱 생명주기 관찰자 해제
    WidgetsBinding.instance.removeObserver(this);
    
    // 폴링 중지도 하지 않음 - 다른 화면에서도 계속 작동해야 함
    print('🖼️ ChildScreenWrapper 해제: ${widget.runtimeType}');
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // 앱이 포그라운드로 올 때 알림 확인
    if (state == AppLifecycleState.resumed) {
      print('📱 앱이 포그라운드로 돌아옴 - 알림 확인');
      _checkGlobalNotifications();
    }
  }

  // 글로벌 알림 확인
  Future<void> _checkGlobalNotifications() async {
    if (!mounted || !widget.enableNotifications) return;
    
    try {
      await _globalNotificationService.checkAndShowAllNotifications(context);
    } catch (e) {
      print('글로벌 알림 확인 중 오류: $e');
    }
  }

  // 새로운 알림 확인 (실제 앱에서는 서버나 로컬 DB에서 확인)
  void _checkForNewNotifications() {
    // TODO: 실제 구현에서는 서버 API 호출 또는 로컬 DB 확인
    // 예시: 5초 후 테스트 알림 표시
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _showTestNotification();
      }
    });
  }

  // 테스트용 알림 표시 (실제 앱에서는 제거)
  void _showTestNotification() {
    _notificationService.showFeedCommentNotification(
      message: '내 피드에 댓글이 달렸어요!',
      feedId: 'test_feed_123',
      commentAuthor: '친구',
      onTap: () {
        print('🔔 피드 댓글 알림 클릭됨');
        // TODO: 피드 상세 화면으로 이동
        _navigateToFeed();
      },
    );
  }

  // 피드 화면으로 이동 (실제 구현 필요)
  void _navigateToFeed() {
    // TODO: 실제 피드 상세 화면으로 네비게이션
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('피드 화면으로 이동 (구현 예정)'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enableNotifications) {
      return widget.child;
    }

    return NotificationOverlay(
      child: widget.child,
    );
  }
}

// 편의를 위한 정적 메서드들
extension ChildScreenWrapperExtension on ChildScreenWrapper {
  // 피드 댓글 알림 표시
  static void showFeedCommentNotification({
    required String message,
    String? feedId,
    String? commentAuthor,
    VoidCallback? onTap,
  }) {
    NotificationService().showFeedCommentNotification(
      message: message,
      feedId: feedId,
      commentAuthor: commentAuthor,
      onTap: onTap,
    );
  }

  // 목표 승인 알림 표시
  static void showGoalApprovalNotification({
    required String message,
    VoidCallback? onTap,
  }) {
    final notification = NotificationData(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: NotificationType.goalApproval,
      message: message,
      onTap: onTap,
      timestamp: DateTime.now(),
    );

    NotificationService().notificationNotifier.value = [
      ...NotificationService().notificationNotifier.value,
      notification,
    ];
  }

  // 모든 알림 제거
  static void clearAllNotifications() {
    NotificationService().clearAllNotifications();
  }
} 