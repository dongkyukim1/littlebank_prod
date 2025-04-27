import 'package:flutter/material.dart';

/// 미션 관련 스타일 정보를 모아둔 클래스
class MissionStyles {
  // 색상 상수
  static const Color primaryBlue = Color(0xFF146AFF);
  static const Color secondaryBlue = Color(0xFF5D9EFF);
  static const Color lightBlue = Color(0xFFF0F6FF);
  static const Color deepBlue = Color(0xFF146AFF);
  static const Color profileBlue = Color(0xFF3179FF);
  static const Color orangeColor = Color(0xFFFF5C00);
  static const Color redColor = Color(0xFFE53935);
  static const Color lightOrangeBackground = Color(0xFFFFD27F);
  static const Color darkTextColor = Color(0xFF353535);
  static const Color comparisonBackgroundColor = Color(0xFFF7F7F7);
  static const Color progressBarBgColor = Color(0xFFE0E0E0);
  static const Color profileBorderBlue = Color(0xFF146AFF);
  static const Color profileBorderOrange = Color(0xFFFF5C00);
  static const Color profileBorderRed = Color(0xFFE53935);

  // 그림자 스타일
  static List<BoxShadow> defaultShadow = [
    BoxShadow(
      color: const Color(0x24000000),
      blurRadius: 8,
      offset: const Offset(0, 2),
      spreadRadius: 0,
    ),
  ];

  static List<BoxShadow> lightShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.1),
      blurRadius: 4,
      spreadRadius: 0,
      offset: const Offset(0, 2),
    ),
  ];

  // 디자인 시스템 - 박스 장식
  static BoxDecoration cardDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    boxShadow: defaultShadow,
  );

  static BoxDecoration progressCardDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: Colors.grey[300]!),
    boxShadow: lightShadow,
  );

  static BoxDecoration badgeDecoration(Color color) =>
      BoxDecoration(color: color, borderRadius: BorderRadius.circular(6));

  static BoxDecoration roundButtonDecoration({
    required Color backgroundColor,
    required Color borderColor,
    double borderRadius = 20,
  }) => BoxDecoration(
    color: backgroundColor,
    borderRadius: BorderRadius.circular(borderRadius),
    border: Border.all(color: borderColor),
  );

  // 텍스트 스타일
  static const TextStyle titleStyle = TextStyle(
    color: darkTextColor,
    fontSize: 16,
    fontFamily: 'Pretendard',
    fontWeight: FontWeight.w700,
  );

  static const TextStyle badgeTextStyle = TextStyle(
    color: Colors.white,
    fontSize: 11,
    fontFamily: 'Pretendard',
    fontWeight: FontWeight.w500,
  );

  static const TextStyle buttonTextStyle = TextStyle(
    color: Colors.white,
    fontSize: 12,
    fontFamily: 'Pretendard',
    fontWeight: FontWeight.w500,
  );

  static TextStyle comparisonTextStyle({required Color color}) =>
      TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color);

  // 공통 그라데이션
  static const LinearGradient blueGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      Color(0xFF146AFF),
      Color(0xFF5D9EFF),
    ],
  );

  static const LinearGradient orangeGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      Color(0xFFFF5C00),
      Color(0xFFFF9E5A),
    ],
  );

  static const LinearGradient redGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      Color(0xFFE53935),
      Color(0xFFFF7B7B),
    ],
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment(0.00, 0.50),
    end: Alignment(1.00, 0.50),
    colors: [Color(0xFFF0F2F7), Color(0xFFF2FFF3)],
  );
}
