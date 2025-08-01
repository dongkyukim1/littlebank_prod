import 'package:shared_preferences/shared_preferences.dart';

class ChatBackgroundService {
  static const String _backgroundKey = 'chat_background';
  
  // 현재 설정된 배경 가져오기
  static Future<String> getCurrentBackground() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_backgroundKey) ?? 'default';
    } catch (e) {
      print('배경 설정 로드 오류: $e');
      return 'default';
    }
  }
  
  // 배경 설정 저장하기
  static Future<bool> saveBackground(String backgroundId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(_backgroundKey, backgroundId);
    } catch (e) {
      print('배경 설정 저장 오류: $e');
      return false;
    }
  }
  
  // 배경 이미지 경로 가져오기
  static Future<String?> getBackgroundImagePath() async {
    final backgroundId = await getCurrentBackground();
    
    switch (backgroundId) {
      case 'background_1':
        return 'assets/icons/background_chat/background_1.png';
      case 'background_2':
        return 'assets/icons/background_chat/background_2.png';
      case 'default':
      default:
        return null; // 기본 배경은 null 반환
    }
  }
  
  // 사용 가능한 배경 목록
  static List<Map<String, String>> getAvailableBackgrounds() {
    return [
      {
        'id': 'default',
        'name': '기본 배경',
        'path': '',
        'preview': 'assets/icons/background_chat/background_1.png',
      },
      {
        'id': 'background_1',
        'name': '배경 1',
        'path': 'assets/icons/background_chat/background_1.png',
        'preview': 'assets/icons/background_chat/background_1.png',
      },
      {
        'id': 'background_2',
        'name': '배경 2',
        'path': 'assets/icons/background_chat/background_2.png',
        'preview': 'assets/icons/background_chat/background_2.png',
      },
    ];
  }
} 