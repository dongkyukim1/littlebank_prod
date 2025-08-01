// 🔔 피드 댓글 알림 시스템
// 아이단 모든 화면에서 하단 알림을 표시할 수 있는 시스템

export 'feed_comment_notification.dart';
export 'cs_comment_notification.dart';
export 'mission_reward_notification.dart';
export 'notification_service.dart';
export 'notification_overlay.dart';
export 'child_screen_wrapper.dart';
export 'test_notification_screen.dart';

// 사용법:
// 1. 아이 화면을 ChildScreenWrapper로 감싸기:
//    return ChildScreenWrapper(
//      child: YourChildScreen(),
//    );
//
// 2. 다양한 알림 표시:
//    final notificationService = NotificationService();
//    
//    // 피드 댓글 알림
//    notificationService.showFeedCommentNotification(
//      message: '내 피드에 댓글이 달렸어요!',
//      onTap: () => Navigator.pushNamed(context, '/feed'),
//    );
//
//    // CS 문의 댓글 알림
//    notificationService.showCsCommentNotification(
//      message: '내 문의 내역에 댓글이 달렸어요!',
//      onTap: () => Navigator.pushNamed(context, '/cs'),
//    );
//
//    // 미션 보상 알림
//    notificationService.showMissionRewardNotification(
//      message: '이번 주 미션의 보상금을 받았어요!',
//      onTap: () => Navigator.pushNamed(context, '/mission'),
//    );
//
// 3. 모든 알림 제거:
//    NotificationService().clearAllNotifications();
//
// 4. 테스트 화면으로 이동하여 기능 확인:
//    Navigator.push(context, MaterialPageRoute(
//      builder: (context) => TestNotificationScreen(),
//    )); 