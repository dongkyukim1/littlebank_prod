import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/sns_service.dart';
import '../../services/auth_service.dart';
import '../../services/email_verification_service.dart';
import '../parent/parent_home_wrapper.dart';
import '../child/child_home_wrapper.dart';
import 'additional_info_verification_screen.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'dart:convert';

class AdditionalInfoScreen extends StatefulWidget {
  const AdditionalInfoScreen({super.key});

  @override
  State<AdditionalInfoScreen> createState() => _AdditionalInfoScreenState();
}

class _AdditionalInfoScreenState extends State<AdditionalInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _birthdateController = TextEditingController();
  final TextEditingController _bankNameController = TextEditingController();
  final TextEditingController _bankAccountController = TextEditingController();
  final TextEditingController _bankCodeController = TextEditingController();
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _domainController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  String _selectedRole = 'PARENT';
  bool _isLoading = false;
  String? _errorMessage;
  String? _birthdateError;
  String? _passwordError;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  String _socialType = 'UNKNOWN';
  bool? _isAdult; // null: 아직 판단 못함, true: 성인, false: 미성년자
  bool _isEmailVerificationLoading = false;
  bool _isEmailVerified = false;

  // 선택된 도메인과 직접 입력 여부
  String _selectedDomain = '';
  bool _isDirectDomainInput = false;

  @override
  void initState() {
    super.initState();
    _initSocialTypeInfo();
    _loadUserInfo();
    // 각 컨트롤러에 리스너 추가
    _idController.addListener(_updateState);
    _passwordController.addListener(() {
      setState(() {
        if (_passwordController.text.isEmpty) {
          _passwordError = null;
        } else if (_passwordController.text.length < 8) {
          _passwordError = '8자 이상으로 입력해 주세요!';
        } else {
          _passwordError = null;
        }
      });
    });
    _domainController.addListener(_updateState);
    _confirmPasswordController.addListener(_updateState);
  }

  void _updateState() {
    setState(() {}); // 입력값 변경시 화면 갱신
  }

  @override
  void dispose() {
    _birthdateController.dispose();
    _bankNameController.dispose();
    _bankAccountController.dispose();
    _bankCodeController.dispose();
    _idController.dispose();
    _domainController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadUserInfo() async {
    final email = await AuthService.getEmail();
    if (email != null && email.isNotEmpty && email.contains('@')) {
      final parts = email.split('@');
      if (parts.length == 2) {
        _idController.text = parts[0];
        _domainController.text = parts[1];
      }
    }
  }

  Future<void> _initSocialTypeInfo() async {
    final socialType = await AuthService.getSocialType();
    print('소셜 로그인 타입: $socialType');
    if (mounted) {
      setState(() {
        _socialType = socialType ?? 'UNKNOWN';
      });

      // 소셜 로그인 사용자인 경우 바로 다음 화면으로 이동
      if (_socialType == 'NAVER' || _socialType == 'KAKAO') {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          await _navigateToNextScreen();
        });
      }
    }
  }

  // JWT 토큰에서 이메일 추출
  String? _extractEmailFromJWT(String? token) {
    if (token == null || token.isEmpty) return null;

    try {
      // JWT는 header.payload.signature 형태
      final parts = token.split('.');
      if (parts.length != 3) return null;

      // payload 부분 디코딩
      String payload = parts[1];

      // Base64 패딩 추가 (필요한 경우)
      while (payload.length % 4 != 0) {
        payload += '=';
      }

      // Base64 디코딩
      final decoded = utf8.decode(base64Decode(payload));
      final Map<String, dynamic> payloadMap = jsonDecode(decoded);

      print('JWT payload 디코딩 결과: $payloadMap');

      return payloadMap['email'] as String?;
    } catch (e) {
      print('JWT 토큰 디코딩 오류: $e');
      return null;
    }
  }

  // 다음 화면으로 이동하는 메서드 분리
  Future<void> _navigateToNextScreen() async {
    String email = '';
    String password = '';

    if (_socialType == 'NAVER' || _socialType == 'KAKAO') {
      // 소셜 로그인 사용자는 저장된 이메일 사용
      final savedEmail = await AuthService.getEmail();
      print('저장된 이메일: $savedEmail');

      if (savedEmail != null && savedEmail.isNotEmpty) {
        email = savedEmail;
        print('저장된 이메일 사용: $email');
      } else {
        // 저장된 이메일이 없으면 JWT 토큰에서 추출
        final token = await AuthService.getAccessToken();
        final extractedEmail = _extractEmailFromJWT(token);

        if (extractedEmail != null && extractedEmail.isNotEmpty) {
          email = extractedEmail;
          print('JWT에서 추출한 이메일 사용: $email');
          // 추출한 이메일을 저장
          await AuthService.setEmail(email);
        } else {
          print('이메일을 가져올 수 없음 - 빈 문자열 사용');
          email = '';
        }
      }

      // 소셜 로그인용 비밀번호 생성
      if (_socialType == 'NAVER') {
        // 네이버 계정 ID 가져오기
        final naverAccountId = await AuthService.getNaverAccountId();
        if (naverAccountId != null && naverAccountId.isNotEmpty) {
          password = 'NAVER_LOGIN_$naverAccountId';
          print('네이버 소셜 로그인용 비밀번호 생성: $password');
        } else {
          // 네이버 계정 ID가 없으면 이메일 기반으로 생성
          final emailId = email.split('@')[0];
          password = 'NAVER_LOGIN_$emailId';
          print('이메일 기반 네이버 소셜 로그인용 비밀번호 생성: $password');
        }
      } else if (_socialType == 'KAKAO') {
        // 카카오는 이메일 기반으로 생성 (카카오 ID를 저장하지 않으므로)
        final emailId = email.split('@')[0];
        password = 'KAKAO_LOGIN_$emailId';
        print('카카오 소셜 로그인용 비밀번호 생성: $password');
      }
    } else {
      // 일반 사용자는 입력된 이메일 사용
      email = "${_idController.text}@${_domainController.text}";
      password = _passwordController.text;
    }

    print('최종 전달할 이메일: $email');
    print('최종 전달할 비밀번호: ${password.isNotEmpty ? "생성됨" : "빈 문자열"}');

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder:
            (context) => AdditionalInfoVerificationScreen(
              email: email,
              password: password,
            ),
      ),
    );
  }

  void _showDomainSelect() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder:
          (context) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('gmail.com'),
                onTap: () {
                  setState(() {
                    _selectedDomain = 'gmail.com';
                    _domainController.text = _selectedDomain;
                    _isDirectDomainInput = false;
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('naver.com'),
                onTap: () {
                  setState(() {
                    _selectedDomain = 'naver.com';
                    _domainController.text = _selectedDomain;
                    _isDirectDomainInput = false;
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('daum.net'),
                onTap: () {
                  setState(() {
                    _selectedDomain = 'daum.net';
                    _domainController.text = _selectedDomain;
                    _isDirectDomainInput = false;
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('직접 입력'),
                onTap: () {
                  setState(() {
                    _isDirectDomainInput = true;
                    _domainController.text = '';
                  });
                  Navigator.pop(context);
                },
              ),
            ],
          ),
    );
  }

  // 이메일 확인 메일 발송
  Future<void> _sendVerificationEmail() async {
    if (_idController.text.isEmpty || _domainController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('이메일을 먼저 입력해주세요')));
      return;
    }

    final email = "${_idController.text}@${_domainController.text}";
    if (kDebugMode) {
      print('이메일 확인 버튼 클릭됨 - 이메일: $email');
    }

    setState(() {
      _isEmailVerificationLoading = true;
    });

    try {
      final emailService = EmailVerificationService();
      if (kDebugMode) {
        print('이메일 서비스 인스턴스 생성 완료, API 호출 시작');
      }

      final result = await emailService.sendVerificationEmail(email);

      if (kDebugMode) {
        print('이메일 인증 API 호출 결과: $result');
      }

      setState(() {
        _isEmailVerificationLoading = false;
        _isEmailVerified = result['success'] == true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? '이메일 확인 메일이 발송되었습니다. 메일을 확인해주세요.'),
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        print('이메일 인증 에러 발생: $e');
      }

      setState(() {
        _isEmailVerificationLoading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('이메일 확인 메일 발송 실패: $e')));
    }
  }

  // 생년월일로 성인 여부 판단
  void _checkAdultStatus(String birthdate) {
    if (birthdate.length != 6) {
      setState(() {
        _isAdult = null;
      });
      return;
    }

    try {
      // 생년월일 파싱
      int year = int.parse(birthdate.substring(0, 2));
      int month = int.parse(birthdate.substring(2, 4));
      int day = int.parse(birthdate.substring(4, 6));

      // 00~23년은 2000년대, 24~99년은 1900년대
      if (year >= 0 && year <= 23) {
        year += 2000;
      } else {
        year += 1900;
      }

      // 현재 날짜
      final now = DateTime.now();
      final currentYear = now.year;
      final currentMonth = now.month;
      final currentDay = now.day;

      // 나이 계산
      int age = currentYear - year;
      if (currentMonth < month || (currentMonth == month && currentDay < day)) {
        age--;
      }

      // 성인 여부 판단 (만 19세 이상)
      setState(() {
        _isAdult = age >= 19;

        // 성인 여부에 따라 역할 자동 설정
        if (_isAdult == true) {
          if (_selectedRole == 'CHILD') {
            _selectedRole = 'PARENT';
          }
        } else {
          _selectedRole = 'CHILD';
        }
      });

      print('생년월일: $birthdate, 만 나이: $age, 성인 여부: $_isAdult');
    } catch (e) {
      setState(() {
        _isAdult = null;
      });
      print('생년월일 파싱 오류: $e');
    }
  }

  Future<void> _saveAdditionalInfo() async {
    // 소셜 로그인 사용자가 아닌 경우에만 이메일 확인 검증
    if (_socialType != 'NAVER' && _socialType != 'KAKAO') {
      if ((_idController.text.isNotEmpty ||
              _domainController.text.isNotEmpty) &&
          !_isEmailVerified) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('이메일 확인이 필요합니다. 이메일 확인 버튼을 눌러주세요.')),
        );
        return;
      }

      // 비밀번호 유효성 검사
      if (_passwordController.text.isEmpty) {
        setState(() {
          _passwordError = '비밀번호를 입력해주세요';
        });
        return;
      }

      if (_passwordController.text.length < 8) {
        setState(() {
          _passwordError = '비밀번호는 최소 8자리 이상이어야 합니다';
        });
        return;
      }

      if (_passwordController.text != _confirmPasswordController.text) {
        setState(() {
          _passwordError = '비밀번호가 일치하지 않습니다';
        });
        return;
      }
    }

    // 다음 화면으로 이동
    await _navigateToNextScreen();
  }

  // 모든 필드가 채워졌는지 확인하는 getter 수정
  bool get _isFormValid {
    // 소셜 로그인 사용자의 경우 이메일/비밀번호 검증 생략
    if (_socialType == 'NAVER' || _socialType == 'KAKAO') {
      return true; // 소셜 로그인 사용자는 바로 다음 단계로
    }

    return _idController.text.isNotEmpty &&
        _domainController.text.isNotEmpty &&
        _passwordController.text.length >= 8 &&
        _confirmPasswordController.text == _passwordController.text &&
        _isEmailVerified;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 상단 앱바
                Container(
                  width: double.infinity,
                  height: 56,
                  child: Stack(
                    children: [
                      Positioned(
                        left: 0,
                        top: 16,
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 24,
                            height: 24,
                            child: Image.asset(
                              'assets/icons/my/뒤로가기.png',
                              width: 24,
                              height: 24,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        top: 19,
                        child: Center(
                          child: Text(
                            '추가정보 입력',
                            style: TextStyle(
                              color: const Color(0xFF202020),
                              fontSize: 16,
                              fontFamily: 'Pretendard-Bold',
                              letterSpacing: -0.32,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 타이틀
                Text(
                  '서비스의 원활한 이용을 위해\n추가 정보를 입력해 주세요!',
                  style: TextStyle(
                    color: const Color(0xFF202020),
                    fontSize: 20,
                    fontFamily: 'Pretendard-Bold',
                    height: 1.50,
                    letterSpacing: -0.88,
                  ),
                ),

                const SizedBox(height: 20),

                // 이메일 입력 섹션 - 소셜 로그인 사용자가 아닌 경우에만 표시
                if (_socialType != 'NAVER' && _socialType != 'KAKAO')
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '이메일',
                            style: TextStyle(
                              color: const Color(0xFF666666),
                              fontSize: 12,
                              fontFamily: 'Pretendard-Light',
                              letterSpacing: -0.24,
                            ),
                          ),
                          // 이메일 확인 버튼
                          GestureDetector(
                            onTap:
                                _isEmailVerificationLoading
                                    ? null
                                    : _sendVerificationEmail,
                            child:
                                _isEmailVerificationLoading
                                    ? const SizedBox(
                                      width: 12,
                                      height: 12,
                                      child: CircularProgressIndicator(
                                        color: Color(0xFF999999),
                                        strokeWidth: 1.5,
                                      ),
                                    )
                                    : Text(
                                      _isEmailVerified ? '확인완료' : '이메일 확인하기',
                                      style: TextStyle(
                                        color:
                                            _isEmailVerified
                                                ? Colors.green
                                                : const Color(0xFF999999),
                                        fontSize: 12,
                                        fontFamily: 'Pretendard',
                                        fontWeight: FontWeight.w300,
                                        decoration:
                                            _isEmailVerified
                                                ? TextDecoration.none
                                                : TextDecoration.underline,
                                        letterSpacing: -0.24,
                                      ),
                                    ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // 이메일 입력 (두 개 필드)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Container(
                              height: 48,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              decoration: ShapeDecoration(
                                color: Colors.white,
                                shape: RoundedRectangleBorder(
                                  side: BorderSide(
                                    width: 0.80,
                                    color: const Color(0xFFDADADA),
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              alignment: Alignment.center,
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
                                  contentPadding: EdgeInsets.zero,
                                  isDense: true,
                                ),
                                textAlignVertical: TextAlignVertical.center,
                              ),
                            ),
                          ),

                          const SizedBox(width: 12.5),

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

                          const SizedBox(width: 12.5),

                          Expanded(
                            child: GestureDetector(
                              onTap:
                                  _isDirectDomainInput
                                      ? null
                                      : _showDomainSelect,
                              child: Container(
                                height: 48,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                decoration: ShapeDecoration(
                                  color: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    side: BorderSide(
                                      width: 0.80,
                                      color: const Color(0xFFDADADA),
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: AbsorbPointer(
                                        absorbing: !_isDirectDomainInput,
                                        child: TextFormField(
                                          controller: _domainController,
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
                                            contentPadding: EdgeInsets.zero,
                                            isDense: true,
                                          ),
                                          textAlignVertical:
                                              TextAlignVertical.center,
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
                                            _isDirectDomainInput = false;
                                            _domainController.text = '';
                                          });
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

                      const SizedBox(height: 8),

                      // 이메일 안내 메시지
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 12,
                            color: const Color(0xFF8490A3),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '입력한 이메일은 다음 로그인 시 사용됩니다',
                            style: TextStyle(
                              color: const Color(0xFF8490A3),
                              fontSize: 11,
                              fontFamily: 'Pretendard-Light',
                              letterSpacing: -0.22,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),
                    ],
                  ),

                // 비밀번호 입력 섹션 - 소셜 로그인 사용자가 아닌 경우에만 표시
                if (_socialType != 'NAVER' && _socialType != 'KAKAO')
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '비밀번호',
                        style: TextStyle(
                          color: const Color(0xFF666666),
                          fontSize: 12,
                          fontFamily: 'Pretendard-Light',
                          letterSpacing: -0.24,
                        ),
                      ),
                      const SizedBox(height: 8),

                      Container(
                        height: 48,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: ShapeDecoration(
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            side: BorderSide(
                              width: 0.80,
                              color: const Color(0xFFDADADA),
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        alignment: Alignment.center,
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
                                  contentPadding: EdgeInsets.zero,
                                  isDense: true,
                                ),
                                textAlignVertical: TextAlignVertical.center,
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

                      const SizedBox(height: 8),

                      // 비밀번호 안내 메시지
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 12,
                            color: const Color(0xFF8490A3),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '입력한 비밀번호는 다음 로그인 시 사용됩니다',
                            style: TextStyle(
                              color: const Color(0xFF8490A3),
                              fontSize: 11,
                              fontFamily: 'Pretendard-Light',
                              letterSpacing: -0.22,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),
                    ],
                  ),

                // 비밀번호 확인 입력 섹션 - 소셜 로그인 사용자가 아닌 경우에만 표시
                if (_socialType != 'NAVER' && _socialType != 'KAKAO')
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '비밀번호 확인',
                        style: TextStyle(
                          color: const Color(0xFF666666),
                          fontSize: 12,
                          fontFamily: 'Pretendard-Light',
                          letterSpacing: -0.24,
                        ),
                      ),
                      const SizedBox(height: 8),

                      Container(
                        height: 48,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: ShapeDecoration(
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            side: BorderSide(
                              width: 0.80,
                              color: const Color(0xFFDADADA),
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _confirmPasswordController,
                                obscureText: !_isConfirmPasswordVisible,
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
                                  contentPadding: EdgeInsets.zero,
                                  isDense: true,
                                ),
                                textAlignVertical: TextAlignVertical.center,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _isConfirmPasswordVisible =
                                      !_isConfirmPasswordVisible;
                                });
                              },
                              child: Icon(
                                _isConfirmPasswordVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: const Color(0xFF999999),
                                size: 24,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),
                    ],
                  ),

                // 소셜 로그인 사용자를 위한 안내 메시지
                if (_socialType == 'NAVER' || _socialType == 'KAKAO')
                  Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        decoration: ShapeDecoration(
                          color: const Color(0xFFF0F8FF),
                          shape: RoundedRectangleBorder(
                            side: BorderSide(
                              width: 1,
                              color: const Color(0xFF146AFF).withOpacity(0.3),
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 16,
                                  color: const Color(0xFF146AFF),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _socialType == 'NAVER'
                                      ? '네이버 계정으로 로그인 중'
                                      : '카카오 계정으로 로그인 중',
                                  style: TextStyle(
                                    color: const Color(0xFF146AFF),
                                    fontSize: 14,
                                    fontFamily: 'Pretendard-Medium',
                                    letterSpacing: -0.28,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '소셜 계정으로 로그인하시므로\n별도의 이메일과 비밀번호 설정이 불필요합니다.',
                              style: TextStyle(
                                color: const Color(0xFF666666),
                                fontSize: 12,
                                fontFamily: 'Pretendard-Light',
                                height: 1.5,
                                letterSpacing: -0.24,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),

                const SizedBox(height: 60),

                // 다음 버튼
                GestureDetector(
                  onTap: _isFormValid ? _saveAdditionalInfo : null,
                  child: Container(
                    width: 358,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 16,
                    ),
                    decoration: ShapeDecoration(
                      color:
                          _isFormValid
                              ? const Color(0xFF146AFF)
                              : const Color(0xFFDCDCDC),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _isLoading
                            ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                            : Text(
                              '다음',
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

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
