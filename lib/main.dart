import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart' as provider;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'models/mission_data.dart';
import 'screens/common/login_screen.dart';
import 'theme/app_theme.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:logging/logging.dart';
import 'package:kakao_flutter_sdk_common/kakao_flutter_sdk_common.dart';
import 'services/dio_interceptor.dart';
import 'services/navigation_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/push_notification_service.dart';
import 'package:flutter_naver_login/flutter_naver_login.dart';
import 'services/billing_service.dart';
import 'services/deep_link_service.dart';
import 'screens/parent/my/benefit/little_bank_benefits_screen.dart';
import 'screens/child/child_home_wrapper.dart';
import 'home_screen.dart';
import 'services/auth_service.dart';

void main() async {
  // Logger 초기화
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
  });

  // 필수: Flutter 위젯 바인딩 초기화
  WidgetsFlutterBinding.ensureInitialized();

  // 안드로이드 시스템 내비게이션 바 완전히 숨기기 (홈, 뒤로가기, 메뉴 버튼)
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.immersiveSticky, // 몰입형 모드 - 스와이프해도 잠시만 나타남
  );

  // 시스템 UI 오버레이 스타일 설정
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
      systemNavigationBarDividerColor: Colors.transparent,
    ),
  );

  // 추가 설정: 시스템 UI가 다시 나타나는 것을 방지
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // .env 파일 로드
  await dotenv.load(fileName: ".env");

  // Dio 클라이언트 초기화
  final dioClient = DioClient.instance;
  print('Dio 클라이언트가 초기화되었습니다.');

  // 카카오 SDK 초기화
  const kakaoAppKey = 'daf99b63927c19ded77784a8b960b182';
  KakaoSdk.init(nativeAppKey: kakaoAppKey, loggingEnabled: true);

  // 네이버 로그인 SDK는 FlutterNaverLoginPlugin의 onAttachedToEngine에서
  // AndroidManifest.xml의 메타데이터를 통해 자동으로 초기화됩니다.
  print('네이버 로그인 SDK 자동 초기화 (플러그인 자체 로직 의존)');

  // 키 해시 출력
  try {
    final String keyHash = await KakaoSdk.origin;
    print('Kakao Key Hash: $keyHash');
  } catch (e) {
    print('키 해시 가져오기 실패: $e');
  }

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // FCM 서비스 초기화
  await PushNotificationService().init();

  // Google Play Billing 서비스 초기화
  try {
    await BillingService().initialize();
    print('✅ BillingService 초기화 완료');
  } catch (e) {
    print('❌ BillingService 초기화 실패: $e');
  }

  // 딥링크 서비스 초기화
  try {
    await DeepLinkService().initialize();
    print('✅ DeepLinkService 초기화 완료');
  } catch (e) {
    print('❌ DeepLinkService 초기화 실패: $e');
  }

  runApp(ProviderScope(child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 앱 빌드 시에도 시스템 UI 숨김 상태 유지
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    
    return provider.ChangeNotifierProvider(
      create: (context) => MissionData(),
      child: MaterialApp(
        title: 'LittleBang',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,

        // 전역 네비게이션 키 설정
        navigatorKey: NavigationService.navigatorKey,

        // 초기 라우트 설정
        initialRoute: '/',

        // 라우트 정의
        routes: {
          '/': (context) => const LoginScreen(),
          '/login': (context) => const LoginScreen(),
          '/parent/little-bank-benefits': (context) => const ParentLittleBankBenefitsScreen(),
          '/home': (context) => const HomeScreen(),
        },

        // 동적 라우트 생성 (userId가 필요한 경우)
        onGenerateRoute: (settings) {
          if (settings.name == '/child/home') {
            return MaterialPageRoute(
              builder: (context) => FutureBuilder<String?>(
                future: _getUserId(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Scaffold(
                      body: Center(child: CircularProgressIndicator()),
                    );
                  }
                  
                  if (snapshot.hasError || !snapshot.hasData) {
                    // userId를 가져오지 못한 경우 로그인 화면으로 이동
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      Navigator.of(context).pushReplacementNamed('/login');
                    });
                    return const Scaffold(
                      body: Center(child: CircularProgressIndicator()),
                    );
                  }
                  
                  return ChildHomeWrapper(
                    userId: snapshot.data!,
                    userType: 'student',
                  );
                },
              ),
            );
          }
          return null;
        },

        // 앱이 빌드된 후 딥링크 서비스에 컨텍스트 설정
        builder: (context, child) {
          // 딥링크 서비스에 컨텍스트 설정
          DeepLinkService().setContext(context);
          return child!;
        },
      ),
    );
  }

  // 사용자 ID 가져오기
  Future<String?> _getUserId() async {
    try {
      final userInfo = await AuthService.getUserInfo();
      return userInfo['id']?.toString();
    } catch (e) {
      print('사용자 ID 가져오기 실패: $e');
      return null;
    }
  }
}
