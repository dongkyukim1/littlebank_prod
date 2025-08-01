import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import 'family_service.dart';
import 'feed_service.dart';
import 'mission_service.dart';
import 'relationship_service.dart';
import '../models/mission_notification.dart';

class NotificationService {
  static const String baseUrl = 'http://3.34.52.239:8080';

  /// 안읽은 알림 전체 개수 가져오기
  static Future<int> getUnreadNotificationCount() async {
    try {
      int totalCount = 0;

      // 가족 초대 안읽은 개수
      final familyInvites = await _getFamilyInvites();
      totalCount += familyInvites.where((invite) => !(invite['read'] ?? false)).length;

      // 미션 알림 안읽은 개수 (모든 미션 알림은 기본적으로 안읽음으로 처리)
      final missionNotifications = await MissionService.getMissionNotifications();
      totalCount += missionNotifications?.length ?? 0;

      // 친구 요청 안읽은 개수
      final relationshipRequests = await _getRelationshipRequests();
      totalCount += relationshipRequests.where((request) => !(request['read'] ?? false)).length;

      // 피드 알림 안읽은 개수
      final feedNotifications = await _getFeedNotifications();
      totalCount += feedNotifications.where((notification) => !(notification['read'] ?? false)).length;

      return totalCount;
    } catch (e) {
      print('안읽은 알림 개수 조회 중 오류: $e');
      return 0;
    }
  }

  /// 가족 초대 목록 가져오기
  static Future<List<Map<String, dynamic>>> _getFamilyInvites() async {
    try {
      final familyInvites = await FamilyService.getReceivedInvites();
      if (familyInvites != null) {
        return List<Map<String, dynamic>>.from(familyInvites);
      }
      return [];
    } catch (e) {
      print('가족 초대 목록 조회 중 오류: $e');
      return [];
    }
  }

  /// 친구 요청 목록 가져오기
  static Future<List<Map<String, dynamic>>> _getRelationshipRequests() async {
    try {
      final relationshipRequests = await RelationshipService.getRelationshipInbox();
      if (relationshipRequests != null) {
        return List<Map<String, dynamic>>.from(relationshipRequests);
      }
      return [];
    } catch (e) {
      print('친구 요청 목록 조회 중 오류: $e');
      return [];
    }
  }

  /// 피드 알림 목록 가져오기
  static Future<List<Map<String, dynamic>>> _getFeedNotifications() async {
    try {
      // 모든 알림을 가져오기 위해 size를 크게 설정
      final feedNotifications = await FeedService.getFeedNotifications(
        page: 0,
        size: 1000, // 충분히 큰 값으로 설정
        sort: ['createdDate,desc'],
      );
      if (feedNotifications?['content'] != null) {
        return List<Map<String, dynamic>>.from(feedNotifications!['content']);
      }
      return [];
    } catch (e) {
      print('피드 알림 목록 조회 중 오류: $e');
      return [];
    }
  }

  /// 안읽은 알림 개수를 문자열로 포맷 (10+ 형태)
  static String formatUnreadCount(int count) {
    if (count >= 10) {
      return '10+';
    } else if (count > 0) {
      return count.toString();
    } else {
      return '';
    }
  }
} 