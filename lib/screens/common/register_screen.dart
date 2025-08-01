import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/email_verification_service.dart';
import 'package:flutter/foundation.dart' show kDebugMode;

class RegisterScreen extends StatefulWidget {
  final String userId; // 이메일
  final String jumin; // 생년월일 6자리

  const RegisterScreen({super.key, required this.userId, required this.jumin});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  // 컨트롤러
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _bankAccountController = TextEditingController();
  final _bankCodeController = TextEditingController();

  // 상태 변수
  bool _isLoading = false;
  String _role = 'PARENT'; // 기본값은 부모
  bool _isPasswordVisible = false;
  bool _isEmailVerificationLoading = false;
  bool _isEmailVerified = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _bankNameController.dispose();
    _bankAccountController.dispose();
    _bankCodeController.dispose();
    super.dispose();
  }

  // 이메일 확인 메일 발송
  Future<void> _sendVerificationEmail() async {
    if (kDebugMode) {
      print('이메일 확인 버튼 클릭됨 - 이메일: ${widget.userId}');
    }

    setState(() {
      _isEmailVerificationLoading = true;
    });

    try {
      final emailService = EmailVerificationService();
      if (kDebugMode) {
        print('이메일 서비스 인스턴스 생성 완료, API 호출 시작');
      }

      final result = await emailService.sendVerificationEmail(widget.userId);

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

  // 회원가입 API 호출
  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_isEmailVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이메일 확인이 필요합니다. 이메일 확인 버튼을 눌러주세요.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await AuthService.signup(
        email: widget.userId,
        password: _passwordController.text,
        name: _nameController.text,
        phone: _phoneController.text,
        rrn: widget.jumin,
        bankName: _bankNameController.text,
        bankAccount: _bankAccountController.text,
        bankCode: _bankCodeController.text,
        role: _role,
        agreedTermsOfService: true,
        agreedPrivacyCollection: true,
        agreedElectronicFinance: true,
        agreedMinorGuardian: _role == 'CHILD' ? true : null,
        agreedRewardGuardian: _role == 'CHILD' ? true : null,
        agreedThirdPartySharing: false,
        agreedDataProcessingDelegation: false,
        agreedMarketing: false,
      );

      // 성공 처리
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('회원가입이 완료되었습니다')));

        // 로그인 화면으로 이동
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('오류가 발생했습니다: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('회원가입', style: TextStyle(color: Colors.black)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '계정 정보를 입력해주세요',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 30),

                // 이메일 섹션 타이틀과 확인 버튼
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '이메일',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
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
                                  : const Color(0xFF4F78FF),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          minimumSize: const Size(70, 30),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 0,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        child:
                            _isEmailVerificationLoading
                                ? const SizedBox(
                                  width: 15,
                                  height: 15,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                                : Text(
                                  _isEmailVerified ? '확인완료' : '이메일 확인',
                                  style: const TextStyle(fontSize: 11),
                                ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // 이메일 (표시만)
                TextFormField(
                  initialValue: widget.userId,
                  enabled: false,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Color(0xFFF5F5F5),
                  ),
                ),
                const SizedBox(height: 16),

                // 비밀번호
                TextFormField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  decoration: InputDecoration(
                    labelText: '비밀번호',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
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
                    if (value.length < 8) {
                      return '비밀번호는 8자 이상이어야 합니다';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 이름
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: '이름',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '이름을 입력해주세요';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 전화번호
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: '전화번호',
                    border: OutlineInputBorder(),
                    hintText: '숫자만 입력 (01012345678)',
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '전화번호를 입력해주세요';
                    }
                    if (!RegExp(r'^01\d{8,9}$').hasMatch(value)) {
                      return '유효한 전화번호 형식이 아닙니다';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 은행 정보
                const Text(
                  '계좌 정보',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // 은행명
                TextFormField(
                  controller: _bankNameController,
                  decoration: const InputDecoration(
                    labelText: '은행명',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '은행명을 입력해주세요';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 계좌번호
                TextFormField(
                  controller: _bankAccountController,
                  decoration: const InputDecoration(
                    labelText: '계좌번호',
                    border: OutlineInputBorder(),
                    hintText: '숫자만 입력',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '계좌번호를 입력해주세요';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 은행 코드
                TextFormField(
                  controller: _bankCodeController,
                  decoration: const InputDecoration(
                    labelText: '은행 코드',
                    border: OutlineInputBorder(),
                    hintText: '예) 001',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '은행 코드를 입력해주세요';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // 역할 선택
                const Text(
                  '역할 선택',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),

                // 라디오 버튼으로 역할 선택
                ListTile(
                  title: const Text('부모'),
                  leading: Radio<String>(
                    value: 'PARENT',
                    groupValue: _role,
                    onChanged: (String? value) {
                      setState(() {
                        _role = value!;
                      });
                    },
                  ),
                ),
                ListTile(
                  title: const Text('자녀'),
                  leading: Radio<String>(
                    value: 'CHILD',
                    groupValue: _role,
                    onChanged: (String? value) {
                      setState(() {
                        _role = value!;
                      });
                    },
                  ),
                ),
                ListTile(
                  title: const Text('선생님'),
                  leading: Radio<String>(
                    value: 'TEACHER',
                    groupValue: _role,
                    onChanged: (String? value) {
                      setState(() {
                        _role = value!;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 30),

                // 회원가입 버튼
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F78FF),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child:
                        _isLoading
                            ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                            : const Text(
                              '회원가입',
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
        ),
      ),
    );
  }
}
