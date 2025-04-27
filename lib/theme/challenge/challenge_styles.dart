import 'package:flutter/material.dart';

/// 챌린지 관련 스타일 정보를 모아둔 클래스
class ChallengeStyles {
  // 색상 상수
  static const Color primaryColor = Color(0xFF3179FF);
  static const Color secondaryColor = Color(0xFFAA8B2F);
  static const Color accentColor = Color(0xFFFFC107);
  static const Color backgroundLightColor = Color(0xFFF5F5F5);
  static const Color backgroundDarkColor = Color(0xFFE0E0E0);
  static const Color textDarkColor = Color(0xFF333333);
  static const Color textMediumColor = Color(0xFF666666);
  static const Color textLightColor = Color(0xFF999999);
  static const Color borderColor = Color(0xFFE0E0E0);
  static const Color calendarHeaderColor = Color(0xFFE3F2FD);
  static const Color selectedDateColor = Color(0xFFFFF8E1);
  static const Color selectedDateBorderColor = Color(0xFFFFD54F);
  static const Color dateTextColor = Color(0xFF1565C0);

  // 그림자 스타일
  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.1),
      blurRadius: 4,
      offset: const Offset(0, 2),
      spreadRadius: 0,
    ),
  ];

  // 스타일 - 박스 장식
  static BoxDecoration summaryBoxDecoration = BoxDecoration(
    color: backgroundLightColor,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: borderColor),
  );

  static BoxDecoration selectedDateBoxDecoration = BoxDecoration(
    color: selectedDateColor,
    borderRadius: BorderRadius.circular(10),
    border: Border.all(color: selectedDateBorderColor, width: 1.5),
  );

  static BoxDecoration calendarHeaderDecoration = BoxDecoration(
    color: calendarHeaderColor,
    borderRadius: const BorderRadius.only(
      topLeft: Radius.circular(12),
      topRight: Radius.circular(12),
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.grey.withOpacity(0.2),
        spreadRadius: 1,
        blurRadius: 2,
        offset: const Offset(0, 1),
      ),
    ],
  );

  static BoxDecoration monthButtonDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
  );

  static BoxDecoration dayRowDecoration = BoxDecoration(
    color: backgroundDarkColor,
    border: Border(bottom: BorderSide(color: borderColor, width: 1)),
  );

  static BoxDecoration dayHeaderDecoration({bool isSelected = false}) =>
      BoxDecoration(
        color: isSelected ? primaryColor : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      );

  static BoxDecoration calendarCellDecoration({
    bool isSelected = false,
    bool isToday = false,
  }) => BoxDecoration(
    color:
        isSelected ? primaryColor : (isToday ? Colors.blue[50] : Colors.white),
    border: Border.all(
      color:
          isSelected
              ? Colors.blue
              : (isToday ? Colors.blue[200]! : Colors.grey[300]!),
      width: isSelected || isToday ? 1.5 : 1,
    ),
    borderRadius: BorderRadius.circular(8),
  );

  static BoxDecoration timePickerBoxDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: borderColor),
  );

  static BoxDecoration durationChipDecoration({bool isSelected = false}) =>
      BoxDecoration(
        color: isSelected ? primaryColor : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isSelected ? primaryColor : borderColor),
      );

  static BoxDecoration inputBoxDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: borderColor),
  );

  static BoxDecoration saveButtonDecoration({bool isEnabled = true}) =>
      BoxDecoration(
        color: isEnabled ? primaryColor : Colors.grey[400],
        borderRadius: BorderRadius.circular(50),
      );

  // 텍스트 스타일
  static const TextStyle titleStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: textDarkColor,
  );

  static const TextStyle subTitleStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: textDarkColor,
  );

  static const TextStyle labelStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.bold,
    color: textMediumColor,
  );

  static const TextStyle descriptionStyle = TextStyle(
    fontSize: 14,
    color: textMediumColor,
  );

  static const TextStyle tagStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.bold,
    color: textMediumColor,
  );

  static const TextStyle metaTextStyle = TextStyle(
    fontSize: 12,
    color: textLightColor,
  );

  static TextStyle monthTextStyle = const TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 16,
    color: dateTextColor,
  );

  static TextStyle dayHeaderTextStyle = const TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );

  static TextStyle selectedDateTextStyle = const TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.bold,
    color: Color(0xFFB0741E),
  );

  static TextStyle dateRangeTextStyle = const TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: Color(0xFF1565C0),
  );

  static TextStyle calendarCellTextStyle({
    bool isSelected = false,
    bool isCurrentMonth = true,
  }) => TextStyle(
    fontSize: 14,
    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
    color:
        isSelected
            ? Colors.white
            : (isCurrentMonth ? textDarkColor : textLightColor),
  );

  static TextStyle durationChipTextStyle({bool isSelected = false}) =>
      TextStyle(
        fontSize: 14,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? Colors.white : textDarkColor,
      );

  static const TextStyle saveButtonTextStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  // 여백 상수
  static const double defaultPadding = 20.0;
  static const double smallPadding = 12.0;
  static const double largePadding = 24.0;
}
