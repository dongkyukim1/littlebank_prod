import 'package:flutter/material.dart';

/// 피드 관련 스타일 정보를 모아둔 클래스
class FeedStyles {
  // 색상 상수
  static const Color primaryColor = Color(0xFF3A88F4);
  static const Color primaryLightColor = Color(0xFFEBF1FF);
  static const Color accentColor = Color(0xFFFF6B6B);
  static const Color textDarkColor = Color(0xFF333333);
  static const Color textMediumColor = Color(0xFF666666);
  static const Color textLightColor = Color(0xFF999999);
  static const Color dividerColor = Color(0xFFEEEEEE);
  static const Color backgroundColor = Color(0xFFF9F9F9);
  static const Color cardColor = Colors.white;

  // 그림자 스타일
  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.05),
      blurRadius: 4,
      offset: const Offset(0, 2),
      spreadRadius: 0,
    ),
  ];

  // 디자인 시스템 - 박스 장식
  static BoxDecoration cardDecoration = BoxDecoration(
    color: cardColor,
    borderRadius: BorderRadius.circular(12),
    boxShadow: cardShadow,
  );

  static BoxDecoration filterChipDecoration({bool isSelected = false}) =>
      BoxDecoration(
        color: isSelected ? primaryColor : Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      );

  static BoxDecoration tabDecoration({bool isSelected = false}) =>
      BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isSelected ? textDarkColor : Colors.transparent,
            width: 2,
          ),
        ),
      );

  static BoxDecoration writeButtonDecoration = BoxDecoration(
    color: primaryColor,
    borderRadius: BorderRadius.circular(20),
  );

  static BoxDecoration searchBarDecoration = BoxDecoration(
    color: cardColor,
    borderRadius: BorderRadius.circular(25),
    border: Border.all(color: dividerColor, width: 1),
  );

  static BoxDecoration tagDecoration = BoxDecoration(
    color: primaryLightColor,
    borderRadius: BorderRadius.circular(12),
  );

  // 텍스트 스타일
  static const TextStyle titleStyle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: textDarkColor,
  );

  static const TextStyle usernameStyle = TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 14,
  );

  static const TextStyle contentStyle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    height: 1.3,
  );

  static const TextStyle metaStyle = TextStyle(
    color: textLightColor,
    fontSize: 12,
  );

  static TextStyle tabTextStyle({bool isSelected = false}) => TextStyle(
    color: isSelected ? textDarkColor : textLightColor,
    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
  );

  static TextStyle filterChipTextStyle({bool isSelected = false}) => TextStyle(
    color: isSelected ? Colors.white : textDarkColor,
    fontSize: 13,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle buttonTextStyle = TextStyle(
    color: Colors.white,
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle tagTextStyle = TextStyle(
    color: primaryColor,
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle descriptionStyle = TextStyle(
    fontSize: 13,
    color: textMediumColor,
    height: 1.4,
  );

  static const TextStyle sortTypeStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );

  // 입력 장식
  static InputDecoration searchInputDecoration = InputDecoration(
    isCollapsed: true,
    hintText: '검색어를 입력해 주세요',
    hintStyle: TextStyle(color: textLightColor, fontSize: 14),
    prefixIcon: Padding(
      padding: const EdgeInsets.only(left: 15.0, right: 8.0),
      child: Icon(Icons.search, color: textLightColor, size: 18),
    ),
    prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
    border: InputBorder.none,
    contentPadding: const EdgeInsets.only(top: 2.0, right: 12.0),
    isDense: true,
  );

  // 여백 상수
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;

  // 반지름 상수
  static const double defaultRadius = 12.0;
  static const double smallRadius = 6.0;
  static const double largeRadius = 20.0;
}
