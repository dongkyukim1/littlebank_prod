import 'package:flutter/material.dart';

/// Pretendard 폰트 전 Weight 사용 예시
/// AppTheme.pretendardThin, AppTheme.pretendardExtraLight, ..., AppTheme.pretendardBlack
class AppTheme {
  // Pretendard FontWeight별 TextStyle
  static const TextStyle pretendardThin = TextStyle(
    fontFamily: 'Pretendard',
    fontWeight: FontWeight.w100,
  );
  static const TextStyle pretendardExtraLight = TextStyle(
    fontFamily: 'Pretendard',
    fontWeight: FontWeight.w200,
  );
  static const TextStyle pretendardLight = TextStyle(
    fontFamily: 'Pretendard',
    fontWeight: FontWeight.w300,
  );
  static const TextStyle pretendardRegular = TextStyle(
    fontFamily: 'Pretendard',
    fontWeight: FontWeight.w400,
  );
  static const TextStyle pretendardMedium = TextStyle(
    fontFamily: 'Pretendard',
    fontWeight: FontWeight.w500,
  );
  static const TextStyle pretendardSemiBold = TextStyle(
    fontFamily: 'Pretendard',
    fontWeight: FontWeight.w600,
  );
  static const TextStyle pretendardBold = TextStyle(
    fontFamily: 'Pretendard',
    fontWeight: FontWeight.w700,
  );
  static const TextStyle pretendardExtraBold = TextStyle(
    fontFamily: 'Pretendard',
    fontWeight: FontWeight.w800,
  );
  static const TextStyle pretendardBlack = TextStyle(
    fontFamily: 'Pretendard',
    fontWeight: FontWeight.w900,
  );

  // 색상 정의 (피그마 디자인에 맞게 조정)
  static const Color primaryColor = Color(0xFF4760FF); // 메인 블루 색상
  static const Color secondaryColor = Color(0xFFFF9F45); // 오렌지 색상
  static const Color backgroundColor = Colors.white;
  static const Color surfaceColor = Colors.white;
  static const Color errorColor = Color(0xFFE53935);
  static const Color textColor = Color(0xFF333333);
  static const Color subtextColor = Color(0xFF757575);
  static const Color disabledColor = Color(0xFFE0E0E0);
  static const Color borderColor = Color(0xFFEEEEEE);
  static const Color iconColor = Color(0xFF757575);
  static const Color kakaoColor = Color(0xFFFEE500); // 카카오 노란색
  static const Color naverColor = Color(0xFF03C75A); // 네이버 녹색

  // 타이틀 스타일 (디자인 시스템에 맞게 조정)
  static const TextStyle title1 = TextStyle(
    fontFamily: 'Pretendard',
    fontSize: 32,
    fontWeight: FontWeight.w700, // Bold
    letterSpacing: -0.04 * 32, // -4%
    height: 1.3,
  );

  static const TextStyle title2 = TextStyle(
    fontFamily: 'Pretendard',
    fontSize: 28,
    fontWeight: FontWeight.w500, // Bold
    letterSpacing: -0.04 * 28, // -4%
    height: 1.3,
  );

  static const TextStyle title3 = TextStyle(
    fontFamily: 'Pretendard',
    fontSize: 24,
    fontWeight: FontWeight.w700, // Bold
    letterSpacing: -0.04 * 24, // -4%
    height: 1.3,
  );

  // 서브 타이틀 스타일
  static const TextStyle subTitle1 = TextStyle(
    fontFamily: 'Pretendard',
    fontSize: 22,
    fontWeight: FontWeight.w700, // Bold
    letterSpacing: -0.04 * 22, // -4%
    height: 1.3,
  );

  static const TextStyle subTitle2 = TextStyle(
    fontFamily: 'Pretendard',
    fontSize: 20,
    fontWeight: FontWeight.w700, // Bold
    letterSpacing: -0.04 * 20, // -4%
    height: 1.3,
  );

  static const TextStyle subTitle3 = TextStyle(
    fontFamily: 'Pretendard',
    fontSize: 20,
    fontWeight: FontWeight.w700, // Bold
    letterSpacing: -0.04 * 20, // -4%
    height: 1.3,
  );

  // 본문 스타일
  static const TextStyle body1 = TextStyle(
    fontFamily: 'Pretendard',
    fontSize: 16,
    fontWeight: FontWeight.w700, // Bold
    letterSpacing: -0.02 * 16, // -2%
    height: 1.5,
  );

  static const TextStyle body2 = TextStyle(
    fontFamily: 'Pretendard',
    fontSize: 16,
    fontWeight: FontWeight.w500, // Medium
    letterSpacing: -0.02 * 16, // -2%
    height: 1.5,
  );

  static const TextStyle body3 = TextStyle(
    fontFamily: 'Pretendard',
    fontSize: 16,
    fontWeight: FontWeight.w300, // Light
    letterSpacing: -0.02 * 16, // -2%
    height: 1.5,
  );

  static const TextStyle body4 = TextStyle(
    fontFamily: 'Pretendard',
    fontSize: 14,
    fontWeight: FontWeight.w500, // Medium
    letterSpacing: -0.02 * 14, // -2%
    height: 1.5,
  );

  static const TextStyle body5 = TextStyle(
    fontFamily: 'Pretendard',
    fontSize: 14,
    fontWeight: FontWeight.w300, // Light
    letterSpacing: -0.02 * 14, // -2%
    height: 1.5,
  );

  static const TextStyle body6 = TextStyle(
    fontFamily: 'Pretendard',
    fontSize: 12,
    fontWeight: FontWeight.w500, // Medium
    letterSpacing: -0.02 * 12, // -2%
    height: 1.5,
  );

  static const TextStyle body7 = TextStyle(
    fontFamily: 'Pretendard',
    fontSize: 12,
    fontWeight: FontWeight.w300, // Light
    letterSpacing: -0.02 * 12, // -2%
    height: 1.5,
  );

  // 캡션 스타일
  static const TextStyle caption1 = TextStyle(
    fontFamily: 'Pretendard',
    fontSize: 12,
    fontWeight: FontWeight.w700, // Bold
    letterSpacing: -0.02 * 12, // -2%
    height: 1.3,
  );

  static const TextStyle caption2 = TextStyle(
    fontFamily: 'Pretendard',
    fontSize: 12,
    fontWeight: FontWeight.w500, // Medium
    letterSpacing: -0.02 * 12, // -2%
    height: 1.3,
  );

  // 이전 스타일들은 참조용으로 남겨두고 대신 새 스타일 사용
  static const TextStyle bodyLarge = body1;
  static const TextStyle bodyMedium = body5;
  static const TextStyle bodySmall = body7;
  static const TextStyle labelLarge = body5;
  static const TextStyle labelMedium = body6;
  static const TextStyle labelSmall = body7;

  // 라이트 테마
  static final ThemeData lightTheme = ThemeData(
    fontFamily: 'Pretendard', // Set Pretendard as the default font

    useMaterial3: true,
    colorScheme: const ColorScheme.light(
      primary: primaryColor,
      secondary: secondaryColor,
      surface: surfaceColor,
      error: errorColor,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: textColor,
      onError: Colors.white,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: backgroundColor,
    textTheme: TextTheme(
      displayLarge: const TextStyle(
        fontFamily: 'Pretendard',
        fontWeight: FontWeight.w900,
      ), // Black
      displayMedium: const TextStyle(
        fontFamily: 'Pretendard',
        fontWeight: FontWeight.w800,
      ), // ExtraBold
      displaySmall: const TextStyle(
        fontFamily: 'Pretendard',
        fontWeight: FontWeight.w700,
      ), // Bold
      headlineLarge: const TextStyle(
        fontFamily: 'Pretendard',
        fontWeight: FontWeight.w600,
      ), // SemiBold
      headlineMedium: const TextStyle(
        fontFamily: 'Pretendard',
        fontWeight: FontWeight.w500,
      ), // Medium
      headlineSmall: const TextStyle(
        fontFamily: 'Pretendard',
        fontWeight: FontWeight.w400,
      ), // Regular
      titleLarge: const TextStyle(
        fontFamily: 'Pretendard',
        fontWeight: FontWeight.w300,
      ), // Light
      titleMedium: const TextStyle(
        fontFamily: 'Pretendard',
        fontWeight: FontWeight.w200,
      ), // ExtraLight
      titleSmall: const TextStyle(
        fontFamily: 'Pretendard',
        fontWeight: FontWeight.w100,
      ), // Thin
      bodyLarge: const TextStyle(
        fontFamily: 'Pretendard',
        fontWeight: FontWeight.w400,
      ),
      bodyMedium: const TextStyle(
        fontFamily: 'Pretendard',
        fontWeight: FontWeight.w300,
      ),
      bodySmall: const TextStyle(
        fontFamily: 'Pretendard',
        fontWeight: FontWeight.w200,
      ),
      labelLarge: const TextStyle(
        fontFamily: 'Pretendard',
        fontWeight: FontWeight.w900,
      ),
      labelMedium: const TextStyle(
        fontFamily: 'Pretendard',
        fontWeight: FontWeight.w700,
      ),
      labelSmall: const TextStyle(
        fontFamily: 'Pretendard',
        fontWeight: FontWeight.w500,
      ),
    ),
    appBarTheme: const AppBarTheme(
      elevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: Color(0xFF333333),
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: Color(0xFF333333),
        fontSize: 18,
        fontWeight: FontWeight.bold,
        fontFamily: 'Pretendard',
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          fontFamily: 'Pretendard',
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: textColor,
        side: const BorderSide(color: borderColor, width: 1),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: borderColor),
      ),
      enabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
      ),
      focusedBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: errorColor, width: 1),
      ),
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
      labelStyle: labelLarge,
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.selected)) {
          return primaryColor;
        }
        return Colors.white;
      }),
      side: BorderSide(color: Colors.grey.shade400),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Colors.grey.shade200,
      disabledColor: disabledColor,
      selectedColor: primaryColor.withOpacity(0.2),
      secondarySelectedColor: primaryColor,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      labelStyle: labelMedium,
      secondaryLabelStyle: const TextStyle(fontSize: 12, color: Colors.white),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      color: Colors.white,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: primaryColor,
      unselectedItemColor: iconColor,
      selectedLabelStyle: TextStyle(fontSize: 12),
      unselectedLabelStyle: TextStyle(fontSize: 12),
      elevation: 8,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: borderColor,
      thickness: 1,
      space: 1,
    ),
    tabBarTheme: const TabBarThemeData(
      labelColor: primaryColor,
      unselectedLabelColor: subtextColor,
      indicatorColor: primaryColor,
    ),
  );

  // 다크 테마
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.dark(
      primary: primaryColor,
      primaryContainer: primaryColor,
      secondary: secondaryColor,
      secondaryContainer: secondaryColor,
      surface: const Color(0xFF212121),
      error: errorColor,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.white,
      onError: Colors.white,
      brightness: Brightness.dark,
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontFamily: 'Pretendard',
        fontWeight: FontWeight.w900,
      ), // Black
      displayMedium: TextStyle(
        fontFamily: 'Pretendard',
        fontWeight: FontWeight.w800,
      ), // ExtraBold
      displaySmall: TextStyle(
        fontFamily: 'Pretendard',
        fontWeight: FontWeight.w700,
      ), // Bold
      headlineLarge: TextStyle(
        fontFamily: 'Pretendard',
        fontWeight: FontWeight.w600,
      ), // SemiBold
      headlineMedium: TextStyle(
        fontFamily: 'Pretendard',
        fontWeight: FontWeight.w500,
      ), // Medium
      headlineSmall: TextStyle(
        fontFamily: 'Pretendard',
        fontWeight: FontWeight.w400,
      ), // Regular
      titleLarge: TextStyle(
        fontFamily: 'Pretendard',
        fontWeight: FontWeight.w300,
      ), // Light
      titleMedium: TextStyle(
        fontFamily: 'Pretendard',
        fontWeight: FontWeight.w200,
      ), // ExtraLight
      titleSmall: TextStyle(
        fontFamily: 'Pretendard',
        fontWeight: FontWeight.w100,
      ), // Thin
      bodyLarge: TextStyle(
        fontFamily: 'Pretendard',
        fontWeight: FontWeight.w400,
      ),
      bodyMedium: TextStyle(
        fontFamily: 'Pretendard',
        fontWeight: FontWeight.w300,
      ),
      bodySmall: TextStyle(
        fontFamily: 'Pretendard',
        fontWeight: FontWeight.w200,
      ),
      labelLarge: TextStyle(
        fontFamily: 'Pretendard',
        fontWeight: FontWeight.w900,
      ),
      labelMedium: TextStyle(
        fontFamily: 'Pretendard',
        fontWeight: FontWeight.w700,
      ),
      labelSmall: TextStyle(
        fontFamily: 'Pretendard',
        fontWeight: FontWeight.w500,
      ),
    ),
    appBarTheme: AppBarTheme(
      elevation: 0,
      backgroundColor: Colors.grey[900],
      foregroundColor: Colors.white,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF333333),
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color(0xFFFF9F45),
      foregroundColor: Colors.white,
      elevation: 6,
    ),
    cardTheme: const CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(10)),
      ),
      color: Colors.white,
    ),
    dividerTheme: const DividerThemeData(
      space: 1,
      thickness: 1,
      color: Color(0xFFEEEEEE),
    ),
  );
}
