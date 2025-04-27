import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'signup_screen.dart';
import '../child/home_screen.dart';
import '../parent/home_screen.dart';
import '../../services/auth_service.dart';
import '../../services/sns_service.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'additional_info_screen.dart';
import '../../services/naver_auth.dart';

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
  bool _isAutoLogin = false;
  bool _isSaveId = false;
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isDirectDomainInput = false; // 직접 입력 모드 상태
  String? _errorMessage;

  // 선택된 도메인
  final String _selectedDomain = '';

  @override
  void initState() {
    super.initState();
    // 카카오 SDK 초기화
    _initKakaoSDK();
  }

  // 카카오 SDK 초기화
  void _initKakaoSDK() {
    // 네이티브 앱 키 사용
    KakaoSdk.init(nativeAppKey: 'daf99b63927c19ded77784a8b960b182');
  }

  @override
  void dispose() {
    _idController.dispose();
    _passwordController.dispose();
    _domainController.dispose();
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
                    _domainController.text = 'gmail.com';
                    _isDirectDomainInput = false;
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('naver.com'),
                onTap: () {
                  setState(() {
                    _domainController.text = 'naver.com';
                    _isDirectDomainInput = false;
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('daum.net'),
                onTap: () {
                  setState(() {
                    _domainController.text = 'daum.net';
                    _isDirectDomainInput = false;
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('직접 입력'),
                onTap: () {
                  setState(() {
                    _domainController.text = '';
                    _isDirectDomainInput = true;
                  });
                  Navigator.pop(context);
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
      print('카카오 로그인 시작');

      OAuthToken token;

      try {
        // 카카오톡 설치 여부 확인
        bool installed = await isKakaoTalkInstalled();
        print('카카오톡 설치 여부: $installed');

        // 카카오톡 설치 여부에 따라 로그인 방식 분기
        if (installed) {
          // 카카오톡으로 로그인
          try {
            token = await UserApi.instance.loginWithKakaoTalk();
            print('카카오톡으로 로그인 성공: ${token.accessToken}');
          } catch (error) {
            // 카카오톡 로그인 실패 시 카카오 계정으로 로그인 시도
            print('카카오톡 로그인 실패: $error');
            token = await UserApi.instance.loginWithKakaoAccount();
            print('카카오 계정으로 로그인 성공: ${token.accessToken}');
          }
        } else {
          // 카카오톡이 설치되어 있지 않으면 카카오 계정으로 로그인
          token = await UserApi.instance.loginWithKakaoAccount();
          print('카카오 계정으로 로그인 성공: ${token.accessToken}');
        }
      } catch (e) {
        // 카카오톡 설치 확인 또는 로그인 시도 실패 시 카카오 계정으로 로그인
        print('카카오톡 설치 확인 또는 로그인 시도 실패: $e');
        token = await UserApi.instance.loginWithKakaoAccount();
        print('카카오 계정으로 로그인 성공: ${token.accessToken}');
      }

      // 사용자 정보 요청
      try {
        User user = await UserApi.instance.me();
        print('카카오 사용자 정보: ${user.id}, ${user.kakaoAccount?.email}');
        
        // 소셜 타입을 명시적으로 설정
        await AuthService.setSocialType('KAKAO');
      } catch (e) {
        print('카카오 사용자 정보 요청 실패: $e');
      }

      // 서버에 카카오 토큰 전송하여 자체 JWT 발급
      final response = await SNSService.loginWithKakao(token.accessToken);
      print('서버 응답: $response');

      // 카카오 로그인 후에는 항상 추가 정보 입력 화면으로 이동
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AdditionalInfoScreen()),
      );
    } catch (e) {
      print('카카오 로그인 실패: $e');

      // 사용자 친화적인 에러 메시지 표시
      _showErrorDialog(
        '카카오 로그인 실패',
        '로그인 중 오류가 발생했습니다.\n${e.toString().replaceAll('Exception: ', '')}',
      );
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
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print('네이버 로그인 UI 버튼 클릭: 로그인 시작');
      print('패키지명: com.example.android_design_preview');
      print('네이버 클라이언트 ID: xDoTbCTjZYNhgSkEK1K7');
      
      // NaverAuthService를 사용하여 네이버 로그인 호출
      print('NaverAuthService.signInWithNaver() 호출 전');
      final result = await NaverAuthService.signInWithNaver();
      print('NaverAuthService.signInWithNaver() 호출 후: $result');
      
      // 소셜 로그인 타입을 네이버로 저장
      await AuthService.setSocialType('NAVER');
      
      // 네이버 계정 정보 저장
      if (result.containsKey('naverAccountId') && result['naverAccountId'] != null) {
        await AuthService.setNaverAccountId(result['naverAccountId']);
      }
      
      if (result.containsKey('email') && result['email'] != null) {
        await AuthService.setEmail(result['email']);
      }
      
      if (result.containsKey('name') && result['name'] != null) {
        await AuthService.setName(result['name']);
      }
      
      // 필요한 경우 추가 정보 입력 화면으로 이동
      if (result.containsKey('needsAdditionalInfo') && result['needsAdditionalInfo'] == true) {
        print('추가 정보 입력 필요: AdditionalInfoScreen으로 이동');
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AdditionalInfoScreen()),
        );
      } else {
        print('추가 정보 입력 필요 없음: 사용자 역할에 따른 화면으로 이동');
        // 로그인 성공 후 사용자 역할에 따른 화면 이동
        await _navigateBasedOnUserRole();
      }
    } catch (e) {
      print('네이버 로그인 실패 - 상세 오류: $e');
      print('오류 발생 위치: ${StackTrace.current}');
      
      // 사용자 친화적인 에러 메시지 표시
      _showErrorDialog(
        '네이버 로그인 실패',
        '로그인 중 오류가 발생했습니다.\n${e.toString().replaceAll('Exception: ', '')}',
      );
    } finally {
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
      print('사용자 정보: $userInfo');

      final String role = userInfo['role']?.toString().toUpperCase() ?? '';

      if (!mounted) return;

      if (role == 'PARENT') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ParentHomeScreen()),
        );
      } else if (role == 'CHILD') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else {
        // 기본값으로 부모 홈 화면으로 이동
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ParentHomeScreen()),
        );
      }
    } catch (e) {
      print('사용자 정보 조회 실패: $e');

      // 오류 발생 시 기본값으로 부모 홈 화면으로 이동
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ParentHomeScreen()),
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

  Future<void> _login() async {
    if (_formKey.currentState?.validate() ?? false) {
      // 이메일 생성
      String email = "${_idController.text}@${_domainController.text}";

      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        // API 서비스를 통해 로그인 요청
        final response = await AuthService.login(
          email: email,
          password: _passwordController.text,
        );

        // 자동 로그인 설정 저장
        if (_isAutoLogin) {
          // 자동 로그인 설정 저장 로직 구현
        }

        // 아이디 저장 설정
        if (_isSaveId) {
          // 아이디 저장 로직 구현
        }

        print('로그인 성공: 전체 응답 데이터 = $response');

        // 로그인 성공 후 사용자 정보 API 호출
        try {
          final userInfoResponse = await AuthService.getUserInfo();
          print('사용자 정보 응답: $userInfoResponse');

          if (!mounted) return;

          // 테스트 계정 특별 처리
          if (email.trim().toLowerCase() == 'test123@naver.com') {
            print('테스트 계정 특별 처리: $email - 부모님 홈 화면으로 이동합니다.');
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const ParentHomeScreen()),
            );
            return;
          }

          // 사용자 정보 API 응답에서 역할 확인
          final String role = userInfoResponse['role']?.toString() ?? '';

          print('사용자 역할: $role');

          // role 값만 기준으로 화면 전환 (authority 무시)
          if (role.toUpperCase() == 'PARENT') {
            print('부모님 역할 감지: $role - 부모님 홈 화면으로 이동합니다.');
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const ParentHomeScreen()),
            );
          } else if (role.toUpperCase() == 'CHILD') {
            print('자녀 역할 감지: $role - 자녀 홈 화면으로 이동합니다.');
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
          } else if (role.toUpperCase() == 'TEACHER') {
            print('선생님 역할 감지: $role - 현재는 자녀 홈 화면으로 이동합니다.');
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
          } else {
            print('알 수 없는 역할: $role - 기본적으로 부모님 홈 화면으로 이동합니다.');
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const ParentHomeScreen()),
            );
          }
          return;
        } catch (userInfoError) {
          print('사용자 정보 조회 실패: $userInfoError');
          // 사용자 정보 API 호출 실패 시 기존 로직으로 백업
        }

        // 사용자 정보 API가 실패한 경우 기존 토큰 기반 로직 사용
        String roleStr = '';

        // JWT 토큰에서 역할 확인
        if (response.containsKey('accessToken')) {
          print('액세스 토큰 발견: ${response['accessToken']}');

          try {
            // JWT 토큰에서 페이로드 추출
            final tokenParts = response['accessToken'].toString().split('.');
            if (tokenParts.length > 1) {
              // Base64 디코딩 및 UTF-8 변환
              String normalizedPayload = base64Url.normalize(tokenParts[1]);
              Uint8List payloadBytes = base64Url.decode(normalizedPayload);
              String payload = utf8.decode(payloadBytes);

              print('토큰 페이로드: $payload');
              // JSON 파싱
              final decodedData = jsonDecode(payload);

              // 이메일 정보 추출
              final userEmail = decodedData['email'];
              print('추출된 이메일: $userEmail');

              // 유저 권한 정보 확인
              if (decodedData.containsKey('authority')) {
                final authority = decodedData['authority'];
                print('추출된 권한: $authority');

                // authority 값이 'ROLE_USER'인 경우 부모 화면으로 이동
                if (authority == 'ROLE_USER') {
                  print('ROLE_USER 권한 감지: 부모님 홈 화면으로 이동합니다.');
                  if (mounted) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ParentHomeScreen(),
                      ),
                    );
                  }
                  return;
                }

                roleStr = authority;
              }
            }
          } catch (e) {
            print('JWT 토큰 파싱 오류: $e');
          }
        }
        // 다른 방법으로 역할 확인 시도
        else if (response.containsKey('role')) {
          roleStr = response['role'].toString();
        } else if (response.containsKey('userRole')) {
          roleStr = response['userRole'].toString();
        } else if (response.containsKey('data') &&
            response['data'] is Map &&
            (response['data'] as Map).containsKey('role')) {
          roleStr = response['data']['role'].toString();
        } else if (response.containsKey('user') &&
            response['user'] is Map &&
            ((response['user'] as Map).containsKey('role') ||
                (response['user'] as Map).containsKey('userRole'))) {
          roleStr =
              (response['user'] as Map).containsKey('role')
                  ? response['user']['role'].toString()
                  : response['user']['userRole'].toString();
        } else {
          // 이메일로 역할 추론
          print('API 응답에서 역할 정보를 찾을 수 없습니다. 이메일로 임시 추론합니다.');
          if (email.toLowerCase().contains('parent') ||
              email.toLowerCase().contains('mom') ||
              email.toLowerCase().contains('dad') ||
              email.toLowerCase() == 'test123@naver.com') {
            roleStr = 'PARENT';
          } else {
            roleStr = 'CHILD';
          }
        }

        print('최종 결정된 역할: $roleStr');

        // 로그인 성공 후 적절한 홈 화면으로 이동
        if (!mounted) return;

        // 역할에 따른 화면 이동
        String normalizedRole = roleStr.toUpperCase().replaceAll('ROLE_', '');
        print('정규화된 역할: $normalizedRole');

        if (normalizedRole == 'USER' ||
            normalizedRole.contains('PARENT') ||
            normalizedRole.contains('ADMIN')) {
          print('부모님 역할 감지: $normalizedRole - 부모님 홈 화면으로 이동합니다.');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const ParentHomeScreen()),
          );
        } else if (normalizedRole.contains('CHILD')) {
          print('자녀 역할 감지: $normalizedRole - 자녀 홈 화면으로 이동합니다.');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        } else if (normalizedRole.contains('TEACHER')) {
          print('선생님 역할 감지: $normalizedRole - 현재는 자녀 홈 화면으로 이동합니다.');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        } else {
          print('알 수 없는 역할: $normalizedRole - 기본적으로 부모님 홈 화면으로 이동합니다.');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const ParentHomeScreen()),
          );
        }
      } catch (e) {
        // 로그인 실패 시 모달 대화상자 표시
        if (mounted) {
          // 개발 디버깅용 로그 (실제 앱에서는 보이지 않음)
          print('로그인 실패 원인: $e');

          // 사용자 친화적인 에러 메시지 생성
          String errorMessage = '아이디 또는 비밀번호가 올바르지 않습니다.';

          // 특정 에러 유형에 따른 메시지 커스터마이징
          String errorString = e.toString().toLowerCase();
          if (errorString.contains('network') ||
              errorString.contains('connection')) {
            errorMessage = '네트워크 연결을 확인해 주세요.';
          } else if (errorString.contains('timeout')) {
            errorMessage = '서버 응답이 지연되고 있습니다.\n잠시 후 다시 시도해 주세요.';
          } else if (errorString.contains('not found') ||
              errorString.contains('404')) {
            errorMessage = '사용자 정보를 찾을 수 없습니다.';
          }

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
                      const Text(
                        '로그인 실패',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 15),

                      // 메시지
                      Text(
                        errorMessage,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                        ),
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
    // 아이디 찾기 기능 구현
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('아이디 찾기 기능 준비 중입니다')));
  }

  void _findPassword() {
    // 비밀번호 찾기 기능 구현
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('비밀번호 찾기 기능 준비 중입니다')));
  }

  void _signUp() {
    // 회원가입 화면으로 이동
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SignupScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 80),
                  // 타이틀
                  Text('오늘도 리틀뱅크와 함께\n천릿길도 한 걸음부터', style: AppTheme.title3),

                  const SizedBox(height: 60),

                  // 아이디 입력
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        flex: 9,
                        child: TextFormField(
                          controller: _idController,
                          decoration: const InputDecoration(
                            hintText: '이메일',
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return '이메일을 입력해주세요';
                            }
                            if (value.contains('@')) {
                              return '@ 없이 입력해주세요';
                            }
                            return null;
                          },
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: const Text(
                          '@',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ),
                      Expanded(
                        flex: 11,
                        child: GestureDetector(
                          onTap: _isDirectDomainInput ? null : _showDomainSelect,
                          child: AbsorbPointer(
                            absorbing: !_isDirectDomainInput,
                            child: TextFormField(
                              controller: _domainController,
                              decoration: InputDecoration(
                                hintText: _isDirectDomainInput ? '직접 입력' : '선택',
                                suffixIcon: _isDirectDomainInput
                                    ? IconButton(
                                        icon: Icon(Icons.close, color: Colors.grey[400]),
                                        onPressed: () {
                                          setState(() {
                                            _isDirectDomainInput = false;
                                            _domainController.text = '';
                                          });
                                        },
                                      )
                                    : Icon(
                                        Icons.arrow_drop_down,
                                        color: Colors.grey[400],
                                      ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return '도메인을 입력해주세요';
                                }
                                if (_isDirectDomainInput && !value.contains('.')) {
                                  return '유효한 도메인 형식이 아닙니다';
                                }
                                return null;
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // 비밀번호 입력
                  TextFormField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    decoration: InputDecoration(
                      hintText: '비밀번호를 입력해주세요',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '비밀번호를 입력해주세요';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 24),

                  // 체크박스 옵션
                  Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: Checkbox(
                          value: _isAutoLogin,
                          activeColor: AppTheme.primaryColor,
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
                      const SizedBox(width: 6),
                      Text('자동 로그인', style: AppTheme.labelLarge),
                      const SizedBox(width: 16),
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: Checkbox(
                          value: _isSaveId,
                          activeColor: AppTheme.primaryColor,
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
                      const SizedBox(width: 6),
                      Text('아이디 저장', style: AppTheme.labelLarge),
                    ],
                  ),

                  const SizedBox(height: 40),

                  // 로그인 버튼
                  ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      disabledBackgroundColor: AppTheme.primaryColor
                          .withOpacity(0.5),
                    ),
                    child:
                        _isLoading
                            ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                            : Text(
                              '로그인',
                              style: AppTheme.bodyLarge.copyWith(
                                color: Colors.white,
                              ),
                            ),
                  ),

                  const SizedBox(height: 24),

                  // 아이디/비밀번호 찾기, 회원가입
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: _findId,
                        child: Text(
                          '아이디 찾기',
                          style: AppTheme.labelLarge.copyWith(
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 12),
                        width: 1,
                        height: 12,
                        color: Colors.grey.shade300,
                      ),
                      GestureDetector(
                        onTap: _findPassword,
                        child: Text(
                          '비밀번호 찾기',
                          style: AppTheme.labelLarge.copyWith(
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 12),
                        width: 1,
                        height: 12,
                        color: Colors.grey.shade300,
                      ),
                      GestureDetector(
                        onTap: _signUp,
                        child: Text(
                          '회원가입',
                          style: AppTheme.labelLarge.copyWith(
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),

                  // SNS 로그인 섹션
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Container(
                            height: 1,
                            color: Colors.grey.shade300,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'SNS로 간편하게 로그인하기',
                            style: AppTheme.labelSmall.copyWith(
                              color: Colors.grey,
                            ),
                          ),
                        ),
                        Flexible(
                          child: Container(
                            height: 1,
                            color: Colors.grey.shade300,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 카카오 로그인 버튼
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : _loginWithKakao,
                      style: OutlinedButton.styleFrom(
                        backgroundColor: AppTheme.kakaoColor,
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: EdgeInsets.zero, // 패딩 제거
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/icons/Icon/kakao/kakao_login.png',
                            height: 30,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '카카오로 로그인',
                            style: AppTheme.bodyMedium.copyWith(
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 네이버 로그인 버튼
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : _loginWithNaver,
                      style: OutlinedButton.styleFrom(
                        backgroundColor: const Color(0xFF03EA66),
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: EdgeInsets.zero, // 패딩 제거
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/logos/naver_logo.png',
                            height: 24,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '네이버로 로그인',
                            style: AppTheme.bodyMedium.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 인증 정보 초기화 버튼 추가
                  TextButton(
                    onPressed: () async {
                      await AuthService.clearAllAuthData();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('인증 정보가 초기화되었습니다. 다시 로그인해주세요.'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    },
                    child: const Text(
                      '인증 정보 초기화',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),

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
