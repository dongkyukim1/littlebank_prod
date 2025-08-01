import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class PushNotificationService {
  static final PushNotificationService _instance = PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  
  String? _token;
  String? get token => _token;

  // 초기화 함수
  Future<void> init() async {
    // FCM 권한 요청
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    
    print('FCM 권한 상태: ${settings.authorizationStatus}');

    // FCM 토큰 가져오기
    _token = await _fcm.getToken();
    print('FCM 토큰: $_token');

    // 토큰을 안전한 저장소에 저장
    if (_token != null) {
      await AuthService.storage.write(key: 'fcmToken', value: _token!);
      // 저장된 fcmToken 확인
      String? storedToken = await AuthService.getFcmToken();
      print('저장된 FCM 토큰: $storedToken');
    }

    // 토큰이 있으면 서버에 등록
    if (_token != null) {
      await _registerTokenWithServer(_token!);
    }

    // 토큰 갱신 리스너
    _fcm.onTokenRefresh.listen((newToken) {
      _token = newToken;
      _registerTokenWithServer(newToken);
    });

    // 로컬 알림 초기화
    const AndroidInitializationSettings initializationSettingsAndroid = 
      AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // 알림 클릭 처리
        _handleNotificationClick(jsonDecode(response.payload ?? '{}'));
      },
    );

    // 포그라운드 메시지 처리
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showNotification(message);
    });

    // 백그라운드 메시지 클릭 처리
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationClick(message.data);
    });
  }

  // 서버에 FCM 토큰 등록
  Future<void> _registerTokenWithServer(String token) async {
    try {
      final userId = await AuthService.getCurrentUserId();
      if (userId == null) return;
      
      // 서버 API 엔드포인트
      final url = 'http://3.34.52.239:8080/api-user/users/fcm-token';
      
      // AuthService.getAuthHeaders() 대신 인증 토큰을 직접 가져오는 방식으로 변경
      final authToken = await AuthService.getAccessToken();
      if (authToken == null) {
        print('인증 토큰이 없습니다.');
        return;
      }
      
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken'
        },
        body: jsonEncode({
          'userId': userId,
          'fcmToken': token,
          'deviceType': 'ANDROID'
        }),
      );
      
      if (response.statusCode == 200) {
        print('FCM 토큰이 서버에 성공적으로 등록되었습니다.');
      } else {
        print('FCM 토큰 등록 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('FCM 토큰 등록 오류: $e');
    }
  }

  // 알림 표시
  Future<void> _showNotification(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      await _flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'littlebank_channel',
            '리틀뱅크 알림',
            channelDescription: '피드, 댓글, 좋아요 알림',
            importance: Importance.max,
            priority: Priority.high,
            showWhen: true,
          ),
        ),
        payload: jsonEncode(message.data),
      );
    }
  }

  // 알림 클릭 처리
  void _handleNotificationClick(Map<String, dynamic> data) {
    // 알림 타입에 따른 처리
    if (data.containsKey('type')) {
      String type = data['type'];
      
      if (type == 'FEED_LIKE') {
        // 좋아요 알림 처리
        int? feedId = int.tryParse(data['feedId'].toString());
        if (feedId != null) {
          // 피드 상세 화면으로 이동
          // NavigationService.navigateTo('/feed/detail/$feedId');
        }
      } else if (type == 'FEED_COMMENT') {
        // 댓글 알림 처리
        int? feedId = int.tryParse(data['feedId'].toString());
        if (feedId != null) {
          // 피드 상세 화면으로 이동하면서 댓글 위치로 스크롤
          // NavigationService.navigateTo('/feed/detail/$feedId', arguments: {'scrollToComments': true});
        }
      } else if (type == 'GOAL_APPLICATION') {
        // 목표 신청 알림 처리
        print('목표 신청 알림 클릭됨');
        print('알림 데이터: $data');
        
        // 목표 ID가 있으면 해당 목표로, 없으면 부모 알림 화면으로 이동
        int? goalId = int.tryParse(data['goalId']?.toString() ?? '');
        String? childName = data['childName'];
        String? goalTitle = data['goalTitle'];
        
        if (goalId != null) {
          // 특정 목표 상세 화면으로 이동 (구현되면)
          // NavigationService.navigateTo('/goal/detail/$goalId');
          print('목표 ID $goalId로 이동 예정');
        } else {
          // 부모 알림 화면으로 이동
          // NavigationService.navigateTo('/parent/notifications');
          print('부모 알림 화면으로 이동 예정');
        }
      }
    }
  }
}
