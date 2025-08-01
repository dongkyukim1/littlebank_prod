import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'verification_screen.dart';
import '../child/child_home_wrapper.dart';
import '../parent/parent_home_wrapper.dart';
import '../../services/auth_service.dart';
import '../../services/sns_service.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'additional_info_screen.dart';
import '../../services/naver_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'modal/password_reset_modal.dart';
import 'finder/find_id_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _domainController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final FocusNode _domainFocusNode = FocusNode(); // 도메인 필드 포커스 노드
  bool _isAutoLogin = false;
  bool _isSaveId = false;
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isDirectDomainInput = false; // 직접 입력 모드 상태
  String? _errorMessage;
  String? _passwordError; // 비밀번호 에러 메시지
  String? _emailError; // 이메일 에러 메시지
  String? _domainError; // 도메인 에러 메시지
  String? _lastLoginMethod; // 최근 로그인 방법
  bool _hasUserInteracted = false; // 사용자가 입력을 시작했는지 여부

  // 선택된 도메인
  final String _selectedDomain = '';

  @override
  void initState() {
    super.initState();
    // 카카오 SDK 초기화만 하고 자동 로그인 시도하지 않음
    _initKakaoSDK();
    _loadLastLoginMethod();

    // 로딩 상태가 기본적으로 true로 설정되어 있는지 확인하고 false로 설정
    setState(() {
      _isLoading = false;
      _emailError = null;
      _domainError = null;
      _passwordError = null;
    });
  }

  // 카카오 SDK 초기화
  void _initKakaoSDK() {
    // 네이티브 앱 키 직접 설정
    const kakaoAppKey = 'daf99b63927c19ded77784a8b960b182';
    print('카카오 앱 키: $kakaoAppKey'); // 디버깅용
    // 네이티브 앱 키 사용
    KakaoSdk.init(nativeAppKey: kakaoAppKey);
  }

  // 최근 로그인 방법 불러오기
  Future<void> _loadLastLoginMethod() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _lastLoginMethod = prefs.getString('last_login_method');
    });
  }

  // 최근 로그인 방법 저장
  Future<void> _saveLastLoginMethod(String method) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_login_method', method);
    setState(() {
      _lastLoginMethod = method;
    });
  }

  // 로그인 버튼 활성화 여부 확인
  bool get _isLoginButtonEnabled {
    return _idController.text.isNotEmpty ||
           _domainController.text.isNotEmpty ||
           _passwordController.text.isNotEmpty;
  }

  @override
  void dispose() {
    _idController.dispose();
    _passwordController.dispose();
    _domainController.dispose();
    _domainFocusNode.dispose();
    super.dispose();
  }

  void _showDomainSelect() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('gmail.com'),
                onTap: () {
                  setState(() {
                    _hasUserInteracted = true;
                    _domainController.text = 'gmail.com';
                    _isDirectDomainInput = false;
                    _domainError = null;
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('naver.com'),
                onTap: () {
                  setState(() {
                    _hasUserInteracted = true;
                    _domainController.text = 'naver.com';
                    _isDirectDomainInput = false;
                    _domainError = null;
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('daum.net'),
                onTap: () {
                  setState(() {
                    _hasUserInteracted = true;
                    _domainController.text = 'daum.net';
                    _isDirectDomainInput = false;
                    _domainError = null;
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('직접 입력'),
                onTap: () {
                  setState(() {
                    _hasUserInteracted = true;
                    _domainController.text = '';
                    _isDirectDomainInput = true;
                    _domainError = null;
                  });
                  Navigator.pop(context);
                  // 직접 입력 모드로 변경 후 도메인 필드에 포커스
                  Future.delayed(const Duration(milliseconds: 100), () {
                    _domainFocusNode.requestFocus();
                  });
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // 카카오 로그인 처리
  Future<void> _loginWithKakao() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      OAuthToken token;
      bool installed = false;

      try {
        // 카카오톡 설치 여부 확인
        installed = await isKakaoTalkInstalled();
        print('카카오톡 설치 여부: $installed');
      } catch (e) {
        print('카카오톡 설치 여부 확인 실패: $e');
        installed = false;
      }

      try {
        if (installed) {
          // 카카오톡으로 로그인
          print('카카오톡으로 로그인 시도');
          token = await UserApi.instance.loginWithKakaoTalk();
        } else {
          // 카카오 계정으로 로그인
          print('카카오 계정으로 로그인 시도');
          token = await UserApi.instance.loginWithKakaoAccount();
        }
      } catch (error) {
        print('첫 번째 로그인 시도 실패: $error');
        // 카카오톡 로그인 실패 시 카카오 계정으로 로그인 시도
        print('카카오 계정으로 다시 시도');
        token = await UserApi.instance.loginWithKakaoAccount();
      }

      print('로그인 성공, 토큰: ${token.accessToken}');

      // 사용자 정보 요청
      try {
        User user = await UserApi.instance.me();
        print('사용자 정보 조회 성공: ${user.id}');
        // 소셜 타입을 명시적으로 설정
        await AuthService.setSocialType('KAKAO');
      } catch (e) {
        print('사용자 정보 요청 실패: $e');
      }

      // 서버에 카카오 토큰 전송하여 자체 JWT 발급
      final response = await SNSService.loginWithKakao(token.accessToken);
      print('서버 응답: $response');

      // 카카오 로그인 성공 시 최근 로그인 방법 저장
      await _saveLastLoginMethod('KAKAO');

      // 추가 정보 필요 여부 확인
      bool needsAdditionalInfo = response['needsAdditionalInfo'] ?? false;

      // role 값 확인
      String? role;
      try {
        final userInfo = await AuthService.getUserInfo();
        role = userInfo['role'];
        print('사용자 역할: $role');
        if (role != null && role.isNotEmpty) {
          needsAdditionalInfo = false;
        }
      } catch (e) {
        print('사용자 정보 조회 실패: $e');
      }

      if (!mounted) return;

      if (needsAdditionalInfo) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AdditionalInfoScreen()),
        );
      } else {
        await _navigateBasedOnUserRole();
      }
    } catch (e) {
      print('카카오 로그인 최종 실패: $e');
      _showErrorDialog('카카오 로그인 실패', '로그인 중 오류가 발생했습니다.\n잠시 후 다시 시도해주세요.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // 네이버 로그인 처리
  Future<void> _loginWithNaver() async {
    print('=== 네이버 로그인 버튼 클릭됨 ===');

    // 상태 초기화: 로딩 시작, 에러 메시지 초기화
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // NaverAuthService를 사용하여 네이버 로그인 시도
      print('NaverAuthService.signInWithNaver() 호출 시작');
      final Map<String, dynamic> result =
          await NaverAuthService.signInWithNaver();
      print('네이버 로그인 응답 (LoginScreen): $result');

      // 서버 로그인 API 호출에서 오류가 발생했는지 확인
      if (result.containsKey('error')) {
        throw Exception(result['error']); // 오류가 있다면 즉시 throw
      }

      // 소셜 로그인 타입을 네이버로 저장
      await AuthService.setSocialType('NAVER');

      // 네이버 로그인 성공 시 최근 로그인 방법 저장
      await _saveLastLoginMethod('NAVER');

      // 추가 정보 필요 여부 확인 - 기본값을 true로 설정
      bool needsAdditionalInfo = true;

      // role 값 확인
      try {
        final userInfo = await AuthService.getUserInfo();
        final role = userInfo['role'];
        print('사용자 역할 (LoginScreen): $role');

        // role이 있고 비어있지 않으면 추가 정보가 필요 없음
        if (role != null && role.toString().isNotEmpty) {
          needsAdditionalInfo = false;
          print('역할이 존재하여 추가 정보 입력 건너뛰기: $role');
        } else {
          needsAdditionalInfo = true;
          print('역할이 없어서 추가 정보 입력 필요');
        }
      } catch (e) {
        print('사용자 정보 조회 실패 (LoginScreen): $e');
        // 오류가 발생하면 추가 정보 입력 필요
        needsAdditionalInfo = true;
      }

      // 마운트 상태 확인 (비동기 작업 도중 화면이 언마운트되었을 수 있음)
      if (!mounted) return;

      // 추가 정보 필요 여부에 따라 다른 화면으로 이동
      if (needsAdditionalInfo) {
        // 추가 정보 입력 화면으로 이동
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AdditionalInfoScreen()),
        );
      } else {
        // 로그인 성공 후 역할에 따른 화면으로 이동
        await _navigateBasedOnUserRole();
      }
    } catch (e) {
      print('네이버 로그인 최종 실패 (LoginScreen): $e');

      // 마운트 상태 확인
      if (!mounted) return;

      // 사용자 친화적인 에러 메시지 표시
      _showErrorDialog('네이버 로그인 실패', '로그인 중 오류가 발생했습니다.\n잠시 후 다시 시도해주세요.');
    } finally {
      // 마운트 상태 확인 후 로딩 상태 해제
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // 사용자 역할에 따라 적절한 홈 화면으로 이동
  Future<void> _navigateBasedOnUserRole() async {
    try {
      final userInfo = await AuthService.getUserInfo();
      final String role = userInfo['role']?.toString().toUpperCase() ?? '';
      final String userId = userInfo['userId']?.toString() ?? '';

      if (!mounted) return;

      if (role == 'PARENT') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ParentHomeWrapper(userId: userId),
          ),
        );
      } else if (role == 'CHILD') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ChildHomeWrapper(userId: userId),
          ),
        );
      } else {
        // 기본값으로 부모 홈 화면으로 이동
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ParentHomeWrapper(userId: userId),
          ),
        );
      }
    } catch (e) {
      print('사용자 정보 조회 실패: $e');
      // 오류 발생 시 기본값으로 부모 홈 화면으로 이동
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ParentHomeWrapper(userId: '')),
      );
    }
  }

  // 오류 다이얼로그 표시
  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 경고 아이콘
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 15),

                // 제목
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 15),

                // 메시지
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                ),
                const SizedBox(height: 25),

                // 확인 버튼
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      '확인',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 일반 로그인 처리
  Future<void> _login() async {
    // 수동 검증
    bool hasErrors = false;

    setState(() {
      _hasUserInteracted = true;
      
      // 이메일 검증
      if (_idController.text.isEmpty) {
        _emailError = '이메일을 입력해주세요';
        hasErrors = true;
      } else if (_idController.text.contains('@')) {
        _emailError = '@ 없이 입력해주세요';
        hasErrors = true;
      } else {
        _emailError = null;
      }

      // 도메인 검증
      if (_domainController.text.isEmpty) {
        _domainError = '도메인을 입력해주세요';
        hasErrors = true;
      } else if (_isDirectDomainInput &&
          !_domainController.text.contains('.')) {
        _domainError = '유효한 도메인 형식이 아닙니다';
        hasErrors = true;
      } else {
        _domainError = null;
      }

      // 비밀번호 검증
      if (_passwordController.text.isEmpty) {
        _passwordError = '비밀번호를 입력해주세요';
        hasErrors = true;
      } else if (_passwordController.text.length < 8) {
        _passwordError = '8자 이상으로 입력해 주세요!';
        hasErrors = true;
      } else {
        _passwordError = null;
      }
    });

    // 에러가 있으면 로그인 진행하지 않고 에러만 표시
    if (hasErrors) {
      return;
    }

    if (!hasErrors) {
      // 이메일 생성
      String email = "${_idController.text}@${_domainController.text}";

      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        // 소셜 로그인 여부 확인 (소셜 로그인이어도 무시하고 진행)
        print('로그인 시도: $email');

        // API 서비스를 통해 로그인 요청
        final response = await AuthService.login(
          email: email,
          password: _passwordController.text,
        );

        print('로그인 응답: $response');

        // 자동 로그인 설정 저장
        if (_isAutoLogin) {
          // 자동 로그인 설정 저장 로직 구현
        }

        // 아이디 저장 설정
        if (_isSaveId) {
          // 아이디 저장 로직 구현
        }

        // 일반 로그인 성공 시 최근 로그인 방법 저장
        await _saveLastLoginMethod('EMAIL');

        // 로그인 성공 후 사용자 정보 API 호출
        try {
          final userInfoResponse = await AuthService.getUserInfo();
          print('사용자 정보: $userInfoResponse');

          if (!mounted) return;

          // 테스트 계정 특별 처리
          if (email.trim().toLowerCase() == 'test123@naver.com') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder:
                    (context) => ParentHomeWrapper(
                      userId: userInfoResponse['userId']?.toString() ?? '',
                    ),
              ),
            );
            return;
          }

          // 사용자 정보 API 응답에서 역할 확인
          final String role = userInfoResponse['role']?.toString() ?? '';
          final String userId = userInfoResponse['userId']?.toString() ?? '';

          // role 값만 기준으로 화면 전환 (authority 무시)
          if (role.toUpperCase() == 'PARENT') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => ParentHomeWrapper(userId: userId),
              ),
            );
          } else if (role.toUpperCase() == 'CHILD') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => ChildHomeWrapper(userId: userId),
              ),
            );
          } else if (role.toUpperCase() == 'TEACHER') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => ChildHomeWrapper(userId: userId),
              ),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => ParentHomeWrapper(userId: userId),
              ),
            );
          }
          return;
        } catch (userInfoError) {
          // 사용자 정보 API 호출 실패 시 기존 로직으로 백업
          print('사용자 정보 조회 실패, 토큰 기반 로직으로 대체: $userInfoError');
        }

        // 사용자 정보 API가 실패한 경우 기존 토큰 기반 로직 사용
        String roleStr = '';
        String userId = '';

        // JWT 토큰에서 역할 확인
        if (response.containsKey('accessToken')) {
          try {
            // JWT 토큰에서 페이로드 추출
            final tokenParts = response['accessToken'].toString().split('.');
            if (tokenParts.length > 1) {
              // Base64 디코딩 및 UTF-8 변환
              String normalizedPayload = base64Url.normalize(tokenParts[1]);
              Uint8List payloadBytes = base64Url.decode(normalizedPayload);
              String payload = utf8.decode(payloadBytes);

              // JSON 파싱
              final decodedData = jsonDecode(payload);

              // 이메일 정보 추출
              final userEmail = decodedData['email'];
              userId = decodedData['userId']?.toString() ?? userEmail ?? '';

              // 유저 권한 정보 확인
              if (decodedData.containsKey('authority')) {
                final authority = decodedData['authority'];

                // authority 값이 'ROLE_USER'인 경우 부모 화면으로 이동
                if (authority == 'ROLE_USER') {
                  if (!mounted) return;
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ParentHomeWrapper(userId: userId),
                    ),
                  );
                  return;
                }
              } else if (decodedData.containsKey('role')) {
                roleStr = decodedData['role'].toString();
              }
            }
          } catch (e) {
            // 토큰 디코딩 실패 처리
            print('토큰 디코딩 실패: $e');
          }
        }
        // 다른 방법으로 역할 확인 시도
        else if (response.containsKey('role')) {
          roleStr = response['role'].toString();
          userId = response['userId']?.toString() ?? email;
        } else if (response.containsKey('userRole')) {
          roleStr = response['userRole'].toString();
          userId = response['userId']?.toString() ?? email;
        } else if (response.containsKey('data') &&
            response['data'] is Map &&
            (response['data'] as Map).containsKey('role')) {
          roleStr = response['data']['role'].toString();
          userId = response['data']['userId']?.toString() ?? email;
        } else if (response.containsKey('user') &&
            response['user'] is Map &&
            ((response['user'] as Map).containsKey('role') ||
                (response['user'] as Map).containsKey('userRole'))) {
          roleStr =
              (response['user'] as Map).containsKey('role')
                  ? response['user']['role'].toString()
                  : response['user']['userRole'].toString();
          userId = response['user']['userId']?.toString() ?? email;
        } else {
          // 이메일로 역할 추론
          if (email.toLowerCase().contains('parent') ||
              email.toLowerCase().contains('mom') ||
              email.toLowerCase().contains('dad') ||
              email.toLowerCase() == 'test123@naver.com') {
            roleStr = 'PARENT';
          } else {
            roleStr = 'CHILD';
          }
          userId = email;
        }

        // 로그인 성공 후 적절한 홈 화면으로 이동
        if (!mounted) return;

        // 역할에 따른 화면 이동
        String normalizedRole = roleStr.toUpperCase().replaceAll('ROLE_', '');

        if (normalizedRole == 'USER' ||
            normalizedRole.contains('PARENT') ||
            normalizedRole.contains('ADMIN')) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ParentHomeWrapper(userId: userId),
            ),
          );
        } else if (normalizedRole.contains('CHILD')) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ChildHomeWrapper(userId: userId),
            ),
          );
        } else if (normalizedRole.contains('TEACHER')) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ChildHomeWrapper(userId: userId),
            ),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ParentHomeWrapper(userId: userId),
            ),
          );
        }
              } catch (e) {
          // 로그인 실패 시 필드 에러 상태 설정
          setState(() {
            _hasUserInteracted = true;
            _emailError = '로그인 정보를 확인해주세요';
            _passwordError = '로그인 정보를 확인해주세요';
            _domainError = '로그인 정보를 확인해주세요';
          });

          print('로그인 실패: $e');
        } finally {
        // 로딩 상태 해제
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  void _findId() {
    // 아이디 찾기 화면으로 이동
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FindIdScreen()),
    );
  }

  void _findPassword() {
    // 비밀번호 찾기 화면으로 이동 (비밀번호 탭 활성화)
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const FindIdScreen(initialTab: FinderTab.findPassword),
      ),
    );
  }

  void _signUp() {
    // 회원가입 화면으로 이동
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const VerificationScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal:
                  MediaQuery.of(context).size.width > 600
                      ? (MediaQuery.of(context).size.width - 400) / 2
                      : 16,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),

                  // 타이틀
                  Text(
                    '오늘의 미션, 내일의 성공!\n함께할 때 더 재밌는\n 앱 리틀뱅크입니다.',
                    style: TextStyle(
                      color: const Color(0xFF202020),
                      fontSize: 20,
                      fontFamily: 'Pretendard-Bold',
                      height: 1.50,
                      letterSpacing: -2.4,
                    ),
                  ),

                  const SizedBox(height: 68),

                  // 이메일 입력 (두 개 필드)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                                              Expanded(
                        child: Container(
                          height: 56,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: ShapeDecoration(
                            color: Colors.white,
                            shape: RoundedRectangleBorder(
                              side: BorderSide(
                                width: _emailError != null 
                                    ? 0.80 
                                    : (_idController.text.isNotEmpty ? 1.40 : 0.80),
                                color: _emailError != null
                                    ? const Color(0xFFFF5C5C)
                                    : (_idController.text.isNotEmpty 
                                        ? const Color(0xFF5D9EFF)
                                        : const Color(0xFFDADADA)),
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: TextFormField(
                            controller: _idController,
                            decoration: InputDecoration(
                              hintText: '이메일',
                              hintStyle: TextStyle(
                                color: const Color(0xFF999999),
                                fontSize: 14,
                                fontFamily: 'Pretendard-Light',
                                letterSpacing: -0.28,
                              ),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                vertical: 16,
                              ),
                            ),
                            textAlignVertical: TextAlignVertical.center,
                            onChanged: (value) {
                              setState(() {
                                _hasUserInteracted = true;
                                if (value.contains('@')) {
                                  _emailError = '@ 없이 입력해주세요';
                                } else if (_emailError == '로그인 정보를 확인해주세요') {
                                  _emailError = null; // 로그인 실패 에러 메시지 지우기
                                } else {
                                  _emailError = null;
                                }
                              });
                            },
                            validator: (value) {
                              // 실제 검증은 onChanged에서 하고, validator는 null 반환
                              return null;
                            },
                          ),
                        ),
                      ),

                      const SizedBox(width: 8),

                      SizedBox(
                        width: 13,
                        child: Text(
                          '@',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: const Color(0xFF999999),
                            fontSize: 14,
                            fontFamily: 'Pretendard-Light',
                            letterSpacing: -0.28,
                          ),
                        ),
                      ),

                      const SizedBox(width: 8),

                                              Expanded(
                        child: GestureDetector(
                          onTap:
                              _isDirectDomainInput ? null : _showDomainSelect,
                          child: Container(
                            height: 56,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: ShapeDecoration(
                              color: Colors.white,
                              shape: RoundedRectangleBorder(
                                side: BorderSide(
                                  width: _domainError != null 
                                      ? 0.80 
                                      : (_domainController.text.isNotEmpty ? 1.40 : 0.80),
                                  color: _domainError != null
                                      ? const Color(0xFFFF5C5C)
                                      : (_domainController.text.isNotEmpty 
                                          ? const Color(0xFF5D9EFF)
                                          : const Color(0xFFDADADA)),
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: AbsorbPointer(
                                    absorbing: !_isDirectDomainInput,
                                    child: TextFormField(
                                      controller: _domainController,
                                      focusNode: _domainFocusNode,
                                      decoration: InputDecoration(
                                        hintText:
                                            _isDirectDomainInput
                                                ? '직접 입력'
                                                : '선택',
                                        hintStyle: TextStyle(
                                          color: const Color(0xFF999999),
                                          fontSize: 14,
                                          fontFamily: 'Pretendard-Light',
                                          letterSpacing: -0.28,
                                        ),
                                        border: InputBorder.none,
                                        enabledBorder: InputBorder.none,
                                        focusedBorder: InputBorder.none,
                                        contentPadding: EdgeInsets.symmetric(
                                          vertical: 16,
                                        ),
                                      ),
                                      textAlignVertical:
                                          TextAlignVertical.center,
                                      onChanged: (value) {
                                        setState(() {
                                          _hasUserInteracted = true;
                                          if (_isDirectDomainInput &&
                                              value.isNotEmpty &&
                                              !value.contains('.')) {
                                            _domainError = '유효한 도메인 형식이 아닙니다';
                                          } else if (_domainError == '로그인 정보를 확인해주세요') {
                                            _domainError = null; // 로그인 실패 에러 메시지 지우기
                                          } else {
                                            _domainError = null;
                                          }
                                        });
                                      },
                                      validator: (value) {
                                        // 실제 검증은 onChanged에서 하고, validator는 null 반환
                                        return null;
                                      },
                                    ),
                                  ),
                                ),
                                if (!_isDirectDomainInput)
                                  Icon(
                                    Icons.arrow_drop_down,
                                    color: const Color(0xFF999999),
                                    size: 16,
                                  ),
                                if (_isDirectDomainInput)
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _hasUserInteracted = true;
                                        _isDirectDomainInput = false;
                                        _domainController.text = '';
                                        _domainError = null;
                                      });
                                      // 직접 입력 모드 해제 시 포커스 해제
                                      _domainFocusNode.unfocus();
                                    },
                                    child: Icon(
                                      Icons.close,
                                      color: const Color(0xFF999999),
                                      size: 16,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // 이메일/도메인 에러 메시지 (동적 높이)
                  if (_hasUserInteracted && (_emailError != null || _domainError != null)) ...[
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: Row(
                        children: [
                          Image.asset(
                            'assets/icons/password.png',
                            width: 12,
                            height: 12,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _emailError ?? _domainError ?? '',
                            style: TextStyle(
                              color: const Color(0xFFFF5C5C),
                              fontSize: 11,
                              fontFamily: 'Pretendard-Light',
                              letterSpacing: -0.22,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],

                  const SizedBox(height: 20),

                  // 비밀번호 입력
                  Container(
                    height: 56,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: ShapeDecoration(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        side: BorderSide(
                          width: _passwordError != null 
                              ? 0.80 
                              : (_passwordController.text.isNotEmpty ? 1.40 : 0.80),
                          color: _passwordError != null
                              ? const Color(0xFFFF5C5C)
                              : (_passwordController.text.isNotEmpty 
                                  ? const Color(0xFF5D9EFF)
                                  : const Color(0xFFDADADA)),
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _passwordController,
                            obscureText: !_isPasswordVisible,
                            decoration: InputDecoration(
                              hintText: '8자 이상의 비밀번호',
                              hintStyle: TextStyle(
                                color: const Color(0xFF999999),
                                fontSize: 14,
                                fontFamily: 'Pretendard-Light',
                                letterSpacing: -0.28,
                              ),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                vertical: 16,
                              ),
                            ),
                            textAlignVertical: TextAlignVertical.center,
                            onChanged: (value) {
                              setState(() {
                                _hasUserInteracted = true;
                                // 입력 중에는 에러 표시하지 않음 (로그인 시에만 검증)
                                if (_passwordError == '로그인 정보를 확인해주세요') {
                                  _passwordError = null; // 로그인 실패 에러 메시지 지우기
                                } else {
                                  _passwordError = null;
                                }
                              });
                            },
                            validator: (value) {
                              // 실제 검증은 onChanged에서 하고, validator는 null 반환
                              return null;
                            },
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                          child: Icon(
                            _isPasswordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: const Color(0xFF999999),
                            size: 24,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 비밀번호 에러 메시지 (동적 높이)
                  if (_hasUserInteracted && _passwordError != null) ...[
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: Row(
                        children: [
                          Image.asset(
                            'assets/icons/password.png',
                            width: 12,
                            height: 12,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _passwordError!,
                            style: TextStyle(
                              color: const Color(0xFFFF5C5C),
                              fontSize: 11,
                              fontFamily: 'Pretendard-Light',
                              letterSpacing: -0.22,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],

                  const SizedBox(height: 16),

                  // 체크박스 옵션
                  Row(
                    children: [
                      Row(
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: Checkbox(
                              value: _isAutoLogin,
                              activeColor: const Color(0xFF10CB86),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              onChanged: (value) {
                                setState(() {
                                  _isAutoLogin = value ?? false;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '자동 로그인',
                            style: TextStyle(
                              color: const Color(0xFF999999),
                              fontSize: 12,
                              fontFamily: 'Pretendard-Light',
                              letterSpacing: -0.24,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Row(
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: Checkbox(
                              value: _isSaveId,
                              activeColor: const Color(0xFF10CB86),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              onChanged: (value) {
                                setState(() {
                                  _isSaveId = value ?? false;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '아이디 저장',
                            style: TextStyle(
                              color: const Color(0xFF999999),
                              fontSize: 12,
                              fontFamily: 'Pretendard-Light',
                              letterSpacing: -0.24,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),

                  // 로그인 버튼
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 16,
                    ),
                    decoration: ShapeDecoration(
                      color: _isLoginButtonEnabled 
                          ? const Color(0xFF10CB86) 
                          : const Color(0xFFDADADA),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: GestureDetector(
                      onTap: (_isLoading || !_isLoginButtonEnabled) ? null : _login,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_isLoading)
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          else
                            Text(
                              '로그인',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontFamily: 'Pretendard-Medium',
                                letterSpacing: -0.28,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 48),

                  // 아이디/비밀번호 찾기, 회원가입
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // 왼쪽: 아이디 찾기, 비밀번호 찾기
                      Row(
                        children: [
                          GestureDetector(
                            onTap: _findId,
                            child: Text(
                              '아이디 찾기',
                              style: TextStyle(
                                color: const Color(0xFF999999),
                                fontSize: 12,
                                fontFamily: 'Pretendard-Light',
                                letterSpacing: -0.24,
                              ),
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 12),
                            width: 1,
                            height: 10,
                            color: const Color(0xFF999999),
                          ),
                          GestureDetector(
                            onTap: _findPassword,
                            child: Text(
                              '비밀번호 찾기',
                              style: TextStyle(
                                color: const Color(0xFF999999),
                                fontSize: 12,
                                fontFamily: 'Pretendard-Light',
                                letterSpacing: -0.24,
                              ),
                            ),
                          ),
                        ],
                      ),

                      // 오른쪽: 회원가입
                      GestureDetector(
                        onTap: _signUp,
                        child: Text(
                          '회원가입',
                          style: TextStyle(
                            color: const Color(0xFF999999),
                            fontSize: 12,
                            fontFamily: 'Pretendard-Light',
                            letterSpacing: -0.24,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 60),

                  // SNS 로그인 섹션 타이틀
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 1,
                          color: const Color(0xFFC4C4C4),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'SNS로 간편하게 로그인하기',
                          style: TextStyle(
                            color: const Color(0xFFC4C4C4),
                            fontSize: 12,
                            fontFamily: 'Pretendard-Light',
                            letterSpacing: -0.24,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          height: 1,
                          color: const Color(0xFFC4C4C4),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // 카카오 로그인 버튼
                  Container(
                    width: double.infinity,
                    height: 45,
                    decoration: ShapeDecoration(
                      color: const Color(0xFFFEE500),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: MaterialButton(
                      onPressed: _isLoading ? null : _loginWithKakao,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/icons/Icon/kakao/kakao_login.png',
                            width: 18,
                            height: 18,
                          ),
                          const SizedBox(width: 16),
                          Text(
                            '카카오 로그인',
                            style: TextStyle(
                              color: Colors.black.withOpacity(0.85),
                              fontSize: 14,
                              fontFamily: 'Apple SD Gothic Neo',
                              fontWeight: FontWeight.w600,
                              height: 1,
                            ),
                          ),
                          if (_lastLoginMethod == 'KAKAO') ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: ShapeDecoration(
                                color: Colors.black.withOpacity(0.1),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                              ),
                              child: Text(
                                '최근 로그인',
                                style: TextStyle(
                                  color: Colors.black.withOpacity(0.85),
                                  fontSize: 10,
                                  fontFamily: 'Pretendard-Light',
                                  letterSpacing: -0.20,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 네이버 로그인 버튼
                  Container(
                    width: double.infinity,
                    height: 45,
                    decoration: ShapeDecoration(
                      color: const Color(0xFF03C75A),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    child: MaterialButton(
                      onPressed:
                          _isLoading
                              ? null
                              : () {
                                print('네이버 버튼 클릭됨!!!!!');
                                _loginWithNaver();
                              },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/logos/naver_logo.png',
                            width: 14,
                            height: 14,
                          ),
                          const SizedBox(width: 16),
                          Text(
                            '네이버 로그인',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontFamily: 'Apple SD Gothic Neo',
                              fontWeight: FontWeight.w500,
                              height: 1,
                            ),
                          ),
                          if (_lastLoginMethod == 'NAVER') ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: ShapeDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                              ),
                              child: Text(
                                '최근 로그인',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontFamily: 'Pretendard-Light',
                                  letterSpacing: -0.20,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(top: 10),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red.shade900),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
