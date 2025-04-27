import 'package:flutter/material.dart';

class NavigationService {
  static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  
  static NavigatorState? get navigator => navigatorKey.currentState;
  
  // 로그인 화면으로 이동 (모든 이전 화면 제거)
  static Future<dynamic> navigateToLogin() {
    return navigator!.pushNamedAndRemoveUntil('/login', (route) => false);
  }
  
  // 지정된 화면으로 이동
  static Future<dynamic> navigateTo(String routeName, {Object? arguments}) {
    return navigator!.pushNamed(routeName, arguments: arguments);
  }
  
  // 이전 화면으로 돌아가기
  static void goBack() {
    return navigator!.pop();
  }
  
  // 현재 화면을 지정된 화면으로 교체
  static Future<dynamic> replaceWith(String routeName, {Object? arguments}) {
    return navigator!.pushReplacementNamed(routeName, arguments: arguments);
  }
} 