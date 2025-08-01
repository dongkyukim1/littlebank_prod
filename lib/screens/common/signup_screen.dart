import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'agreement_screen.dart';
import '../../services/email_verification_service.dart';
import 'package:flutter/foundation.dart' show kDebugMode;

class SignupScreen extends StatefulWidget {
  final String name;
  final String phone; 
  final String jumin;

  const SignupScreen({
    super.key,
    required this.name,
    required this.phone,
    required this.jumin,
  });

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  // 사용자 입력 정보
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _domainController = TextEditingController();
  final TextEditingController _passwordConfirmController =
      TextEditingController();
  bool _isPasswordVisible = false;
  bool _isPasswordConfirmVisible = false;

  // 선택된 도메인과 직접 입력 여부
  String _selectedDomain = '';
  bool _isDirectDomainInput = false;

  // 상태 변수 추가
  bool _isEmailVerificationLoading = false;
  bool _isEmailVerified = false;

  // 비밀번호 에러 메시지
  String? _passwordError;

  @override
  void dispose() {
    _idController.dispose();
    _passwordController.dispose();
    _domainController.dispose();
    _passwordConfirmController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
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
    _passwordConfirmController.addListener(_updateState);
  }

  void _updateState() {
    setState(() {}); // 입력값 변경시 화면 갱신
  }

  // 이메일 확인 메일 발송
  Future<void> _sendVerificationEmail() async {
    // 이메일 유효성 확인
    if (_idController.text.isEmpty || _domainController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('이메일을 먼저 입력해주세요')));
      return;
    }

    if (kDebugMode) {
      print(
        '이메일 확인 버튼 클릭됨 - 이메일: ${_idController.text}@${_domainController.text}',
      );
    }

    setState(() {
      _isEmailVerificationLoading = true;
    });

    try {
      final emailService = EmailVerificationService();
      if (kDebugMode) {
        print('이메일 서비스 인스턴스 생성 완료, API 호출 시작');
      }

      final result = await emailService.sendVerificationEmail(
        "${_idController.text}@${_domainController.text}",
      );

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
              Container(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                alignment: Alignment.centerLeft,
                child: const Text(
                  '도메인 선택',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    fontFamily: 'Pretendard-Bold',
                  ),
                ),
              ),
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

  void _nextStep() {
    // 회원가입 다음 단계로 이동하는 로직
    if (_idController.text.isEmpty || _domainController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('아이디와 도메인을 입력해주세요')));
      return;
    }

    if (_passwordController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('비밀번호를 입력해주세요')));
      return;
    }

    if (_passwordController.text != _passwordConfirmController.text) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('비밀번호가 일치하지 않습니다')));
      return;
    }

    if (!_isEmailVerified) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('이메일 확인이 필요합니다')));
      return;
    }

    // 다음 페이지로 이동 - AgreementScreen으로 모든 정보 전달
    final String userId = "${_idController.text}@${_domainController.text}";
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => AgreementScreen(
              userId: userId,
              password: _passwordController.text, // 비밀번호 전달
              name: widget.name, // 이전 화면에서 받은 이름
              phone: widget.phone, // 이전 화면에서 받은 전화번호
              jumin: widget.jumin, // 이전 화면에서 받은 생년월일
            ),
      ),
    );
  }

  // 모든 필드가 채워졌는지 확인하는 getter 추가
  bool get _isFormValid {
    return _idController.text.isNotEmpty &&
        _domainController.text.isNotEmpty &&
        _passwordController.text.length >= 8 &&
        _passwordConfirmController.text == _passwordController.text &&
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
                            '회원가입',
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

                // 스텝 인디케이터
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: ShapeDecoration(
                          color: const Color(0xFF3A88F4),
                          shape: OvalBorder(),
                        ),
                        child: Center(
                          child: Text(
                            '1',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontFamily: 'Pretendard-Bold',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        width: 12,
                        height: 2,
                        color: const Color(0xFF3A88F4),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        width: 28,
                        height: 28,
                        decoration: ShapeDecoration(
                          color: const Color(0xFF3A88F4),
                          shape: OvalBorder(),
                        ),
                        child: Center(
                          child: Text(
                            '2',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontFamily: 'Pretendard-Bold',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        width: 12,
                        height: 2,
                        color: const Color(0xFFE4ECF8),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        width: 28,
                        height: 28,
                        decoration: ShapeDecoration(
                          color: const Color(0xFFE4ECF8),
                          shape: OvalBorder(),
                        ),
                        child: Center(
                          child: Text(
                            '3',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontFamily: 'Pretendard-Bold',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        width: 12,
                        height: 2,
                        color: const Color(0xFFE4ECF8),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        width: 28,
                        height: 28,
                        decoration: ShapeDecoration(
                          color: const Color(0xFFE4ECF8),
                          shape: OvalBorder(),
                        ),
                        child: Center(
                          child: Text(
                            '4',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontFamily: 'Pretendard-Bold',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        width: 12,
                        height: 2,
                        color: const Color(0xFFE4ECF8),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        width: 28,
                        height: 28,
                        decoration: ShapeDecoration(
                          color: const Color(0xFFE4ECF8),
                          shape: OvalBorder(),
                        ),
                        child: Center(
                          child: Text(
                            '5',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontFamily: 'Pretendard-Bold',
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
                  '성장을 위한 고민은 끝\n회원가입을 진행할게요',
                  style: TextStyle(
                    color: const Color(0xFF202020),
                    fontSize: 22, // 24 -> 22
                    fontFamily: 'Pretendard-Bold',
                    height: 1.50,
                    letterSpacing: -0.88, // -0.96 -> -0.88
                  ),
                ),

                const SizedBox(height: 40),

                // 이메일 입력 섹션
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
                            fontSize: 10, // 12 -> 10
                            fontFamily: 'Pretendard-Light',
                            letterSpacing: -0.20, // -0.24 -> -0.20
                          ),
                        ),
                        // 이메일 확인 버튼 (작게)
                        SizedBox(
                          height: 30,
                          child: ElevatedButton(
                            onPressed:
                                _isEmailVerificationLoading
                                    ? null
                                    : _sendVerificationEmail,
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  _isEmailVerified
                                      ? Colors.green
                                      : const Color(0xFF146AFF),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              minimumSize: const Size(70, 30),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 0,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child:
                                _isEmailVerificationLoading
                                    ? const SizedBox(
                                      width: 12,
                                      height: 12,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 1.5,
                                      ),
                                    )
                                    : Text(
                                      _isEmailVerified ? '확인완료' : '이메일 확인',
                                      style: const TextStyle(
                                        fontSize: 9,
                                        fontFamily: 'Pretendard-Medium',
                                      ),
                                    ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // 이메일 입력 (두 개 필드)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Container(
                            height: 48,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 2,
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
                            child: TextFormField(
                              controller: _idController,
                              decoration: InputDecoration(
                                hintText: '이메일',
                                hintStyle: TextStyle(
                                  color: const Color(0xFF999999),
                                  fontSize: 12, // 14 -> 12
                                  fontFamily: 'Pretendard-Light',
                                  letterSpacing: -0.24, // -0.28 -> -0.24
                                ),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                              textAlignVertical: TextAlignVertical.center,
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
                        ),

                        const SizedBox(width: 8),

                        SizedBox(
                          width: 13,
                          child: Text(
                            '@',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: const Color(0xFF999999),
                              fontSize: 12, // 14 -> 12
                              fontFamily: 'Pretendard-Light',
                              letterSpacing: -0.24, // -0.28 -> -0.24
                            ),
                          ),
                        ),

                        const SizedBox(width: 8),

                        Expanded(
                          child: GestureDetector(
                            onTap:
                                _isDirectDomainInput ? null : _showDomainSelect,
                            child: Container(
                              height: 48,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 2,
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
                                            fontSize: 12, // 14 -> 12
                                            fontFamily: 'Pretendard-Light',
                                            letterSpacing:
                                                -0.24, // -0.28 -> -0.24
                                          ),
                                          border: InputBorder.none,
                                          enabledBorder: InputBorder.none,
                                          focusedBorder: InputBorder.none,
                                          contentPadding: EdgeInsets.symmetric(
                                            vertical: 14,
                                          ),
                                        ),
                                        textAlignVertical:
                                            TextAlignVertical.center,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return '도메인을 입력해주세요';
                                          }
                                          if (_isDirectDomainInput &&
                                              !value.contains('.')) {
                                            return '유효한 도메인 형식이 아닙니다';
                                          }
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
                          '이메일은 비밀번호 찾기 등에 사용되므로 정확하게 입력해 주세요',
                          style: TextStyle(
                            color: const Color(0xFF8490A3),
                            fontSize: 9, // 11 -> 9
                            fontFamily: 'Pretendard-Light',
                            letterSpacing: -0.18, // -0.22 -> -0.18
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // 비밀번호 입력 섹션
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '비밀번호',
                      style: TextStyle(
                        color: const Color(0xFF666666),
                        fontSize: 10, // 12 -> 10
                        fontFamily: 'Pretendard-Light',
                        letterSpacing: -0.20, // -0.24 -> -0.20
                      ),
                    ),
                    const SizedBox(height: 8),

                    Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 2,
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
                                  fontSize: 12, // 14 -> 12
                                  fontFamily: 'Pretendard-Light',
                                  letterSpacing: -0.24, // -0.28 -> -0.24
                                ),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                              textAlignVertical: TextAlignVertical.center,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return '비밀번호를 입력해주세요';
                                }
                                if (value.length < 8) {
                                  return '8자 이상으로 입력해 주세요!';
                                }
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
                              size: 20, // 24 -> 20
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
                          '8자 이상으로 입력하지 않을 시, 비밀번호 설정이 불가능합니다',
                          style: TextStyle(
                            color: const Color(0xFF8490A3),
                            fontSize: 9, // 11 -> 9
                            fontFamily: 'Pretendard-Light',
                            letterSpacing: -0.18, // -0.22 -> -0.18
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // 비밀번호 확인 입력 섹션
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '비밀번호 확인',
                      style: TextStyle(
                        color: const Color(0xFF666666),
                        fontSize: 10, // 12 -> 10
                        fontFamily: 'Pretendard-Light',
                        letterSpacing: -0.20, // -0.24 -> -0.20
                      ),
                    ),
                    const SizedBox(height: 8),

                    Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 2,
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
                      child: Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _passwordConfirmController,
                              obscureText: !_isPasswordConfirmVisible,
                              decoration: InputDecoration(
                                hintText: '8자 이상의 비밀번호',
                                hintStyle: TextStyle(
                                  color: const Color(0xFF999999),
                                  fontSize: 12, // 14 -> 12
                                  fontFamily: 'Pretendard-Light',
                                  letterSpacing: -0.24, // -0.28 -> -0.24
                                ),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                              textAlignVertical: TextAlignVertical.center,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return '비밀번호 확인을 입력해주세요';
                                }
                                if (value != _passwordController.text) {
                                  return '비밀번호가 일치하지 않습니다';
                                }
                                return null;
                              },
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _isPasswordConfirmVisible =
                                    !_isPasswordConfirmVisible;
                              });
                            },
                            child: Icon(
                              _isPasswordConfirmVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: const Color(0xFF999999),
                              size: 20, // 24 -> 20
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 60),

                // 다음 버튼
                GestureDetector(
                  onTap: _isFormValid ? _nextStep : null,
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
                        Text(
                          '다음',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12, // 14 -> 12
                            fontFamily: 'Pretendard-Medium',
                            letterSpacing: -0.24, // -0.28 -> -0.24
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
