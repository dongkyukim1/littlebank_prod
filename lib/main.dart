import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'models/mission_data.dart';
import 'screens/common/login_screen.dart';
import 'theme/app_theme.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:logging/logging.dart';
import 'package:kakao_flutter_sdk_common/kakao_flutter_sdk_common.dart';
import 'services/dio_interceptor.dart';
import 'services/navigation_service.dart';

void main() async {
  // Logger 초기화
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
  });

  // 필수: Flutter 위젯 바인딩 초기화
  WidgetsFlutterBinding.ensureInitialized();

  // .env 파일 로드
  await dotenv.load(fileName: ".env");

  // Dio 클라이언트 초기화
  final dioClient = DioClient.instance;
  print('Dio 클라이언트가 초기화되었습니다.');

  // 카카오 SDK 초기화 (네이티브 앱 키 사용)
  String kakaoAppKey = dotenv.env['KAKAO_NATIVE_APP_KEY'] ?? '';
  String kakaoRestApiKey = dotenv.env['KAKAO_REST_API_KEY'] ?? '';

  // 카카오 SDK 초기화
  KakaoSdk.init(nativeAppKey: kakaoRestApiKey, loggingEnabled: true);

  // 키 해시 출력
  try {
    final String keyHash = await KakaoSdk.origin;
    print('Kakao Key Hash: $keyHash');
  } catch (e) {
    print('키 해시 가져오기 실패: $e');
  }

  // 네이버 로그인 관련 메시지 출력만 하고 실제 초기화는 하지 않음
  try {
    print('네이버 로그인 SDK 설정 확인 - 로그인은 앱 실행 후 로그인 버튼을 통해 진행됩니다');
    // 실제 로그인 시도는 여기서 하지 않음
  } catch (e) {
    print('네이버 로그인 SDK 설정 오류: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
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
          // 여기에 다른 화면에 대한 라우트를
        },
      ),
    );
  }
}
