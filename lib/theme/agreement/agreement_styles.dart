import 'package:flutter/material.dart';
import '../app_theme.dart';

/// 약관 관련 스타일 정보를 모아둔 클래스
class AgreementStyles {
  // 색상 상수
  static const Color primaryColor = AppTheme.primaryColor;
  static const Color secondaryColor = Color(0xFF6C757D);
  static const Color successColor = Color(0xFF28A745);
  static const Color warningColor = Color(0xFFFFC107);
  static const Color dangerColor = Color(0xFFDC3545);
  static const Color infoColor = Color(0xFF17A2B8);
  static const Color lightColor = Color(0xFFF8F9FA);
  static const Color darkColor = Color(0xFF343A40);
  static const Color backgroundColor = Colors.white;
  static const Color textColor = Color(0xFF212529);
  static const Color textMutedColor = Color(0xFF6C757D);

  // 그림자 스타일
  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.1),
      blurRadius: 10,
      spreadRadius: 0,
      offset: const Offset(0, 2),
    ),
  ];

  // 컨테이너 스타일
  static BoxDecoration cardDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(8),
    boxShadow: cardShadow,
  );

  static BoxDecoration termItemDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: const Color(0xFFE8E8E8)),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.03),
        blurRadius: 6,
        spreadRadius: 0,
        offset: const Offset(0, 3),
      ),
    ],
  );

  static BoxDecoration bottomSheetDecoration = const BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
  );

  static BoxDecoration checkboxDecoration({bool isChecked = false}) =>
      BoxDecoration(
        color: isChecked ? primaryColor : Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isChecked ? primaryColor : const Color(0xFFCCCCCC),
          width: 1.5,
        ),
      );

  static BoxDecoration highlightDecoration = BoxDecoration(
    color: Colors.grey[100],
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: Colors.grey[300]!),
  );

  static BoxDecoration handleDecoration = BoxDecoration(
    color: Colors.grey[300],
    borderRadius: BorderRadius.circular(2),
  );

  static BoxDecoration closeButtonDecoration = BoxDecoration(
    color: Colors.grey[100],
    shape: BoxShape.circle,
  );

  static BoxDecoration buttonDecoration({bool isEnabled = true}) =>
      BoxDecoration(
        color: isEnabled ? primaryColor : Colors.grey[300],
        borderRadius: BorderRadius.circular(8),
      );

  // 텍스트 스타일
  static const TextStyle titleStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: textColor,
  );

  static const TextStyle termTitleStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: textColor,
  );

  static const TextStyle termDescriptionStyle = TextStyle(
    fontSize: 14,
    color: textMutedColor,
    height: 1.4,
  );

  static TextStyle checkboxLabelStyle({bool isChecked = false}) => TextStyle(
    fontSize: 14,
    fontWeight: isChecked ? FontWeight.bold : FontWeight.normal,
    color: isChecked ? primaryColor : textColor,
  );

  static const TextStyle buttonTextStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  static const TextStyle sectionTitleStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: primaryColor,
  );

  static const TextStyle contentTextStyle = TextStyle(
    fontSize: 15,
    color: textColor,
    height: 1.6,
  );

  static const TextStyle contentHeadingStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: textColor,
    height: 1.6,
  );

  // 버튼 스타일
  static final ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: primaryColor,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(vertical: 16),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    elevation: 0,
  );

  static const double defaultPadding = 20.0;
  static const double smallPadding = 12.0;
  static const double largePadding = 24.0;
}
