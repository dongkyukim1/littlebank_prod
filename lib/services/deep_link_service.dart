import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:app_links/app_links.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'navigation_service.dart';
import 'auth_service.dart';

class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;
  BuildContext? _context;

  // BuildContext 설정 (앱 시작 시 호출)
  void setContext(BuildContext context) {
    _context = context;
  }

  // 앱이 설치되었는지 확인
  static Future<bool> isAppInstalled() async {
    try {
      final Uri testUri = Uri.parse('littlebank://invite');
      return await canLaunchUrl(testUri);
    } catch (e) {
      return false;
    }
  }

  // 플레이스토어로 리다이렉션
  static Future<void> redirectToPlayStore() async {
    const String packageName = 'com.worldcoin.pocketmoneymanagementz';
    const String playStoreUrl = 'https://play.google.com/store/apps/details?id=$packageName';
    const String appStoreUrl = 'https://apps.apple.com/app/id123456789'; // iOS 앱스토어 ID (있을 경우 변경하세요)
    
    try {
      if (Platform.isAndroid) {
        final Uri playStoreUri = Uri.parse(playStoreUrl);
        if (await canLaunchUrl(playStoreUri)) {
          await launchUrl(playStoreUri, mode: LaunchMode.externalApplication);
        }
      } else if (Platform.isIOS) {
        final Uri appStoreUri = Uri.parse(appStoreUrl);
        if (await canLaunchUrl(appStoreUri)) {
          await launchUrl(appStoreUri, mode: LaunchMode.externalApplication);
        }
      }
    } catch (e) {
      print('플레이스토어 리다이렉션 오류: $e');
    }
  }

  // 딥링크 초기화
  Future<void> initialize() async {
    try {
      // 앱이 종료된 상태에서 링크로 시작된 경우
      final Uri? initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _handleDeepLink(initialUri);
      }

      // 앱이 실행 중일 때 링크를 받는 경우
      _linkSubscription = _appLinks.uriLinkStream.listen(
        _handleDeepLink,
        onError: (err) {
          print('딥링크 오류: $err');
        },
      );
    } catch (e) {
      print('딥링크 초기화 오류: $e');
    }
  }

  // 딥링크 처리 (수정된 버전)
  void _handleDeepLink(Uri uri) async {
    print('딥링크 수신: $uri');
    
    // 앱이 설치되어 있는지 확인 (이미 실행 중이므로 설치되어 있음)
    print('✅ 앱이 설치되어 있음');
    
    // 로그인 상태 확인
    final bool isLoggedIn = await _checkLoginStatus();
    
    if (isLoggedIn) {
      print('✅ 사용자가 로그인되어 있음');
      
      // 사용자 역할에 따라 화면 분기
      await _navigateBasedOnUserRole(uri);
    } else {
      print('❌ 사용자가 로그인되어 있지 않음');
      
      // 로그인 화면으로 이동
      _navigateToLogin(uri);
    }
  }

  // 로그인 상태 확인
  Future<bool> _checkLoginStatus() async {
    try {
      final String? accessToken = await AuthService.getAccessToken();
      return accessToken != null && accessToken.isNotEmpty;
    } catch (e) {
      print('로그인 상태 확인 오류: $e');
      return false;
    }
  }

  // 사용자 역할에 따른 화면 분기
  Future<void> _navigateBasedOnUserRole(Uri uri) async {
    try {
      final Map<String, dynamic> userInfo = await AuthService.getUserInfo();
      final String? role = userInfo['role'];
      
      print('사용자 역할: $role');
      
      if (role == 'PARENT') {
        // 부모인 경우 - 리틀뱅크 헤택 화면으로 이동
        _navigateToLittleBankBenefits(uri);
      } else if (role == 'CHILD') {
        // 자녀인 경우 - 자녀 홈 화면으로 이동
        _navigateToChildHome(uri);
      } else {
        // 역할이 명확하지 않은 경우 - 홈 화면으로 이동
        _navigateToHome(uri);
      }
    } catch (e) {
      print('사용자 정보 확인 오류: $e');
      // 오류 발생 시 홈 화면으로 이동
      _navigateToHome(uri);
    }
  }

  // 부모용 리틀뱅크 헤택 화면으로 이동
  void _navigateToLittleBankBenefits(Uri uri) {
    print('📱 부모용 리틀뱅크 헤택 화면으로 이동');
    
    if (_context != null) {
      // 초대 코드가 있는 경우 전달
      final String? inviteCode = uri.queryParameters['code'];
      
      if (inviteCode != null) {
        // 초대 코드와 함께 리틀뱅크 헤택 화면으로 이동
        Navigator.of(_context!).pushNamedAndRemoveUntil(
          '/parent/little-bank-benefits',
          (route) => false,
          arguments: {'inviteCode': inviteCode},
        );
      } else {
        // 일반적인 리틀뱅크 헤택 화면으로 이동
        Navigator.of(_context!).pushNamedAndRemoveUntil(
          '/parent/little-bank-benefits',
          (route) => false,
        );
      }
    }
  }

  // 자녀 홈 화면으로 이동
  void _navigateToChildHome(Uri uri) {
    print('📱 자녀 홈 화면으로 이동');
    
    if (_context != null) {
      // 초대 코드가 있는 경우 처리
      final String? inviteCode = uri.queryParameters['code'];
      
      if (inviteCode != null) {
        // 초대 코드 처리 후 자녀 홈으로 이동
        _processInviteCodeForChild(inviteCode);
      } else {
        // 일반적인 자녀 홈 화면으로 이동
        Navigator.of(_context!).pushNamedAndRemoveUntil(
          '/child/home',
          (route) => false,
        );
      }
    }
  }

  // 홈 화면으로 이동 (기본)
  void _navigateToHome(Uri uri) {
    print('📱 홈 화면으로 이동');
    
    if (_context != null) {
      Navigator.of(_context!).pushNamedAndRemoveUntil(
        '/home',
        (route) => false,
      );
    }
  }

  // 로그인 화면으로 이동
  void _navigateToLogin(Uri uri) {
    print('📱 로그인 화면으로 이동');
    
    if (_context != null) {
      // 초대 코드가 있는 경우 로그인 후 처리하도록 저장
      final String? inviteCode = uri.queryParameters['code'];
      
      if (inviteCode != null) {
        Navigator.of(_context!).pushNamedAndRemoveUntil(
          '/login',
          (route) => false,
          arguments: {'pendingInviteCode': inviteCode},
        );
      } else {
        Navigator.of(_context!).pushNamedAndRemoveUntil(
          '/login',
          (route) => false,
        );
      }
    }
  }

  // 자녀용 초대 코드 처리
  void _processInviteCodeForChild(String inviteCode) async {
    print('🔗 자녀용 초대 코드 처리 시작: $inviteCode');
    
    try {
      // 백엔드 API 호출하여 초대 코드 검증 및 친구 추가
      final result = await _sendInviteCodeToBackend(inviteCode);
      
      if (result['success'] == true) {
        print('✅ 친구 추가 성공: ${result['message']}');
        
        // 성공 후 자녀 홈으로 이동
        if (_context != null) {
          Navigator.of(_context!).pushNamedAndRemoveUntil(
            '/child/home',
            (route) => false,
          );
          
          // 성공 메시지 표시
          ScaffoldMessenger.of(_context!).showSnackBar(
            SnackBar(
              content: Text('친구 추가가 완료되었습니다! 🎉'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        print('❌ 친구 추가 실패: ${result['error']}');
        _showErrorAndNavigateToChildHome(result['error'] ?? '초대 코드가 유효하지 않습니다.');
      }
    } catch (e) {
      print('❌ 초대 코드 처리 오류: $e');
      _showErrorAndNavigateToChildHome('네트워크 오류가 발생했습니다. 다시 시도해주세요.');
    }
  }

  // 에러 표시 후 자녀 홈으로 이동
  void _showErrorAndNavigateToChildHome(String message) {
    if (_context != null) {
      Navigator.of(_context!).pushNamedAndRemoveUntil(
        '/child/home',
        (route) => false,
      );
      
      // 에러 메시지 표시
      ScaffoldMessenger.of(_context!).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // 초대 코드 처리
  void _processInviteCode(String inviteCode) async {
    print('🔗 초대 코드로 친구 추가 시작: $inviteCode');
    
    try {
      // 백엔드 API 호출하여 초대 코드 검증 및 친구 추가
      final result = await _sendInviteCodeToBackend(inviteCode);
      
      if (result['success'] == true) {
        print('✅ 친구 추가 성공: ${result['message']}');
        // 성공 시 특정 화면으로 이동
        _navigateToFriendAddedScreen(inviteCode, result);
      } else {
        print('❌ 친구 추가 실패: ${result['error']}');
        _showErrorMessage(result['error'] ?? '초대 코드가 유효하지 않습니다.');
      }
    } catch (e) {
      print('❌ 초대 코드 처리 오류: $e');
      _showErrorMessage('네트워크 오류가 발생했습니다. 다시 시도해주세요.');
    }
  }

  // 백엔드에 초대 코드 전송
  Future<Map<String, dynamic>> _sendInviteCodeToBackend(String inviteCode) async {
    try {
      // HTTP 요청을 위한 import 추가 필요
      final response = await _makeHttpRequest(
        'POST',
        'http://3.34.52.239:8080/api/invite/accept',
        {
          'inviteCode': inviteCode,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
      
      return response;
    } catch (e) {
      return {
        'success': false,
        'error': '서버 연결에 실패했습니다.',
      };
    }
  }

  // HTTP 요청 헬퍼 메소드
  Future<Map<String, dynamic>> _makeHttpRequest(
    String method,
    String url,
    Map<String, dynamic> data,
  ) async {
    try {
      final uri = Uri.parse(url);
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      
      http.Response response;
      
      if (method.toUpperCase() == 'POST') {
        response = await http.post(
          uri,
          headers: headers,
          body: json.encode(data),
        ).timeout(const Duration(seconds: 10));
      } else {
        response = await http.get(uri, headers: headers)
            .timeout(const Duration(seconds: 10));
      }
      
      print('🌐 HTTP ${response.statusCode}: ${response.body}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        return {
          'success': true,
          'data': responseData,
          'message': responseData['message'] ?? '성공적으로 처리되었습니다.',
        };
      } else {
        return {
          'success': false,
          'error': 'HTTP ${response.statusCode}: ${response.body}',
        };
      }
    } on TimeoutException {
      return {
        'success': false,
        'error': '요청 시간이 초과되었습니다.',
      };
    } catch (e) {
      return {
        'success': false,
        'error': '네트워크 오류: $e',
      };
    }
  }

  // 친구 추가 성공 화면으로 이동
  void _navigateToFriendAddedScreen(String inviteCode, Map<String, dynamic> result) {
    print('📱 친구 추가 성공 화면으로 이동');
    
    if (_context != null) {
      // 성공 메시지와 함께 적절한 홈 화면으로 이동
      ScaffoldMessenger.of(_context!).showSnackBar(
        SnackBar(
          content: Text('친구 추가가 완료되었습니다! 🎉'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
      
      // 홈 화면으로 이동
      Navigator.of(_context!).pushNamedAndRemoveUntil(
        '/home',
        (route) => false,
      );
    }
  }

  // 에러 메시지 표시
  void _showErrorMessage(String message) {
    print('⚠️ 에러 메시지: $message');
    
    if (_context != null) {
      ScaffoldMessenger.of(_context!).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
      
      // 에러 발생 시 홈 화면으로 이동
      Navigator.of(_context!).pushNamedAndRemoveUntil(
        '/home',
        (route) => false,
      );
    }
  }

  // 딥링크 URL 생성
  static String generateInviteLink(String inviteCode) {
    return 'littlebank://invite?code=$inviteCode';
  }

  // 웹 대체 URL 생성 (앱이 설치되지 않은 경우)
  static String generateWebFallbackUrl(String inviteCode) {
    const String packageName = 'com.worldcoin.pocketmoneymanagementz';
    
    if (Platform.isAndroid) {
      return 'https://play.google.com/store/apps/details?id=$packageName&referrer=invite_code%3D$inviteCode';
    } else if (Platform.isIOS) {
      return 'https://apps.apple.com/app/id123456789?invite_code=$inviteCode'; // iOS 앱스토어 ID (있을 경우 변경하세요)
    }
    
    return 'https://play.google.com/store/apps/details?id=$packageName&referrer=invite_code%3D$inviteCode'; // 웹 대체 URL
  }

  // 리소스 정리
  void dispose() {
    _linkSubscription?.cancel();
  }
} 