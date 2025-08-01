import 'package:flutter/material.dart';
import 'child_screen_wrapper.dart';
import 'notification_service.dart';

class TestNotificationScreen extends StatelessWidget {
  const TestNotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notificationService = NotificationService();
    
    return ChildScreenWrapper(
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text(
            '피드 댓글 알림 테스트',
            style: TextStyle(
              fontSize: 16,
              fontFamily: 'Pretendard-Bold',
              color: Colors.black,
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '🔔 피드 댓글 알림 시스템 테스트',
                style: TextStyle(
                  fontSize: 20,
                  fontFamily: 'Pretendard-Bold',
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              
              const Text(
                '아래 버튼들을 눌러서 다양한 알림을 테스트해보세요!',
                style: TextStyle(
                  fontSize: 14,
                  fontFamily: 'Pretendard-Regular',
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              
              // 피드 댓글 알림 버튼
              ElevatedButton.icon(
                onPressed: () {
                  notificationService.showFeedCommentNotification(
                    message: '내 피드에 댓글이 달렸어요!',
                    feedId: 'test_feed_123',
                    commentAuthor: '친구',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('피드로 이동합니다! 📱'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  );
                },
                icon: const Icon(Icons.comment, color: Colors.white),
                label: const Text(
                  '피드 댓글 알림 표시',
                  style: TextStyle(
                    fontFamily: 'Pretendard-Medium',
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5D9EFF),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // 커스텀 메시지 알림 버튼
              ElevatedButton.icon(
                onPressed: () {
                  notificationService.showFeedCommentNotification(
                    message: '좋아요 10개를 받았어요! 🎉',
                    feedId: 'test_feed_456',
                    commentAuthor: '여러 친구들',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('좋아요 목록을 확인합니다! ❤️'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  );
                },
                icon: const Icon(Icons.favorite, color: Colors.white),
                label: const Text(
                  '좋아요 알림 표시',
                  style: TextStyle(
                    fontFamily: 'Pretendard-Medium',
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B6B),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // 목표 승인 알림 버튼 (직접 NotificationData 생성)
              ElevatedButton.icon(
                onPressed: () {
                  final notification = NotificationData(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    type: NotificationType.goalApproval,
                    message: '목표가 승인되었어요! 💪',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('목표 화면으로 이동합니다! 🎯'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    timestamp: DateTime.now(),
                  );
                  
                  notificationService.notificationNotifier.value = [
                    ...notificationService.notificationNotifier.value,
                    notification,
                  ];
                },
                icon: const Icon(Icons.check_circle, color: Colors.white),
                label: const Text(
                  '목표 승인 알림 표시',
                  style: TextStyle(
                    fontFamily: 'Pretendard-Medium',
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // CS 문의 댓글 알림 버튼
              ElevatedButton.icon(
                onPressed: () {
                  notificationService.showCsCommentNotification(
                    message: '내 문의 내역에 댓글이 달렸어요!',
                    csId: 'cs_inquiry_123',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('CS 문의 화면으로 이동합니다! 💬'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  );
                },
                icon: const Icon(Icons.help_outline, color: Colors.white),
                label: const Text(
                  'CS 댓글 알림 표시',
                  style: TextStyle(
                    fontFamily: 'Pretendard-Medium',
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9C27B0),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // 미션 보상 알림 버튼
              ElevatedButton.icon(
                onPressed: () {
                  notificationService.showMissionRewardNotification(
                    message: '이번 주 미션의 보상금을 받았어요!',
                    missionId: 'mission_week_456',
                    rewardAmount: 50000,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('미션 화면으로 이동합니다! 💰'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  );
                },
                icon: const Icon(Icons.monetization_on, color: Colors.white),
                label: const Text(
                  '미션 보상 알림 표시',
                  style: TextStyle(
                    fontFamily: 'Pretendard-Medium',
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF9800),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              
              // 모든 알림 제거 버튼
              OutlinedButton.icon(
                onPressed: () {
                  notificationService.clearAllNotifications();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('모든 알림이 제거되었습니다'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                icon: const Icon(Icons.clear_all, color: Colors.grey),
                label: const Text(
                  '모든 알림 제거',
                  style: TextStyle(
                    fontFamily: 'Pretendard-Medium',
                    color: Colors.grey,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: const BorderSide(color: Colors.grey),
                ),
              ),
              
              const Spacer(),
              
              const Text(
                '💡 알림은 5초 후 자동으로 사라지거나\n"확인하기" 버튼을 눌러서 제거할 수 있습니다.',
                style: TextStyle(
                  fontSize: 12,
                  fontFamily: 'Pretendard-Light',
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
} 