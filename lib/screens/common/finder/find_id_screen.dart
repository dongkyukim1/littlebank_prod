import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/auth_service.dart';
import '../../../theme/app_theme.dart';

// 현재 활성 탭을 관리하는 provider
enum FinderTab { findId, findPassword }
final finderTabProvider = StateProvider<FinderTab>((ref) => FinderTab.findId);

// 아이디 찾기 관련 providers
enum FindIdStep {
  phoneInput,
  verificationInput,
  result,
}

final findIdStepProvider = StateProvider<FindIdStep>((ref) => FindIdStep.phoneInput);
final phoneNumberProvider = StateProvider<String>((ref) => '');
final verificationCodeProvider = StateProvider<String>((ref) => '');
final foundEmailProvider = StateProvider<String?>((ref) => null);
final timerSecondsProvider = StateProvider<int>((ref) => 0);

// 비밀번호 찾기 관련 providers
enum FindPasswordStep {
  emailInput,
  tempPasswordInput,
  newPasswordInput,
}

final findPasswordStepProvider = StateProvider<FindPasswordStep>((ref) => FindPasswordStep.emailInput);
final emailProvider = StateProvider<String>((ref) => '');
final tempPasswordProvider = StateProvider<String>((ref) => '');

// 공통 providers
final isLoadingProvider = StateProvider<bool>((ref) => false);
final errorMessageProvider = StateProvider<String?>((ref) => null);

// 비밀번호 가시성 관리
final isTempPasswordVisibleProvider = StateProvider<bool>((ref) => false);
final isNewPasswordVisibleProvider = StateProvider<bool>((ref) => false);
final isConfirmPasswordVisibleProvider = StateProvider<bool>((ref) => false);

class FindIdScreen extends ConsumerStatefulWidget {
  final FinderTab? initialTab;
  
  const FindIdScreen({super.key, this.initialTab});

  @override
  ConsumerState<FindIdScreen> createState() => _FindIdScreenState();
}

class _FindIdScreenState extends ConsumerState<FindIdScreen> {
  // 아이디 찾기용 컨트롤러
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _verificationController = TextEditingController();
  
  // 비밀번호 찾기용 컨트롤러
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _tempPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  
  late Stream<int> _timerStream;
  bool _hasInitialized = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _verificationController.dispose();
    _emailController.dispose();
    _tempPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Stream<int> _createTimerStream(int seconds) {
    return Stream.periodic(const Duration(seconds: 1), (i) => seconds - i - 1)
        .take(seconds)
        .takeWhile((value) => value >= 0);
  }

  // ============ 아이디 찾기 메서드들 ============
  Future<void> _sendVerificationCode() async {
    final phoneNumber = _phoneController.text.trim();
    
    if (phoneNumber.isEmpty) {
      ref.read(errorMessageProvider.notifier).state = '휴대폰 번호를 입력해주세요.';
      return;
    }

    if (phoneNumber.length != 11) {
      ref.read(errorMessageProvider.notifier).state = '휴대폰 번호 11자리를 정확히 입력해주세요.';
      return;
    }

    ref.read(isLoadingProvider.notifier).state = true;
    ref.read(errorMessageProvider.notifier).state = null;

    try {
      final result = await AuthService.sendSmsVerificationCode(phoneNumber: phoneNumber);
      
      if (result['success']) {
        ref.read(findIdStepProvider.notifier).state = FindIdStep.verificationInput;
        ref.read(phoneNumberProvider.notifier).state = phoneNumber;
        
        // 3분 타이머 시작
        ref.read(timerSecondsProvider.notifier).state = 180;
        _timerStream = _createTimerStream(180);
        _timerStream.listen((seconds) {
          if (mounted) {
            ref.read(timerSecondsProvider.notifier).state = seconds;
          }
        });
      } else {
        ref.read(errorMessageProvider.notifier).state = result['message'] ?? '인증번호 발송에 실패했습니다.';
      }
    } catch (e) {
      ref.read(errorMessageProvider.notifier).state = '네트워크 오류가 발생했습니다.';
    } finally {
      ref.read(isLoadingProvider.notifier).state = false;
    }
  }

  Future<void> _verifyCode() async {
    final verificationCode = _verificationController.text.trim();
    final phoneNumber = ref.read(phoneNumberProvider);
    
    if (verificationCode.isEmpty) {
      ref.read(errorMessageProvider.notifier).state = '인증번호를 입력해주세요.';
      return;
    }

    ref.read(isLoadingProvider.notifier).state = true;
    ref.read(errorMessageProvider.notifier).state = null;

    try {
      final result = await AuthService.verifySmsCode(
        phoneNumber: phoneNumber,
        code: verificationCode,
      );
      
      if (result['success']) {
        // 인증 성공 후 아이디 검색
        final searchResult = await AuthService.searchUserByPhone(phone: phoneNumber);
        
        if (searchResult['success'] && searchResult['email'] != null) {
          ref.read(foundEmailProvider.notifier).state = searchResult['email'];
          ref.read(findIdStepProvider.notifier).state = FindIdStep.result;
        } else {
          ref.read(errorMessageProvider.notifier).state = '해당 휴대폰 번호로 가입된 계정을 찾을 수 없습니다.';
        }
      } else {
        ref.read(errorMessageProvider.notifier).state = result['message'] ?? '인증번호가 일치하지 않습니다.';
      }
    } catch (e) {
      ref.read(errorMessageProvider.notifier).state = '네트워크 오류가 발생했습니다.';
    } finally {
      ref.read(isLoadingProvider.notifier).state = false;
    }
  }

  // ============ 비밀번호 찾기 메서드들 ============
  Future<void> _requestTemporaryPassword() async {
    final email = _emailController.text.trim();
    
    if (email.isEmpty) {
      ref.read(errorMessageProvider.notifier).state = '이메일을 입력해주세요.';
      return;
    }

    // 이메일 유효성 검사
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
      ref.read(errorMessageProvider.notifier).state = '올바른 이메일 형식을 입력해주세요.';
      return;
    }

    ref.read(isLoadingProvider.notifier).state = true;
    ref.read(errorMessageProvider.notifier).state = null;

    try {
      final result = await AuthService.requestTemporaryPassword(email: email);
      
      if (result['success']) {
        ref.read(emailProvider.notifier).state = email;
        ref.read(findPasswordStepProvider.notifier).state = FindPasswordStep.tempPasswordInput;
        ref.read(errorMessageProvider.notifier).state = null;
      } else {
        ref.read(errorMessageProvider.notifier).state = result['message'] ?? '임시 비밀번호 발급에 실패했습니다.';
      }
    } catch (e) {
      ref.read(errorMessageProvider.notifier).state = '네트워크 오류가 발생했습니다.';
    } finally {
      ref.read(isLoadingProvider.notifier).state = false;
    }
  }

  Future<void> _loginWithTemporaryPassword() async {
    final tempPassword = _tempPasswordController.text.trim();
    final email = ref.read(emailProvider);
    
    if (tempPassword.isEmpty) {
      ref.read(errorMessageProvider.notifier).state = '임시 비밀번호를 입력해주세요.';
      return;
    }

    ref.read(isLoadingProvider.notifier).state = true;
    ref.read(errorMessageProvider.notifier).state = null;

    try {
      final result = await AuthService.login(
        email: email,
        password: tempPassword,
      );

      ref.read(tempPasswordProvider.notifier).state = tempPassword;
      ref.read(findPasswordStepProvider.notifier).state = FindPasswordStep.newPasswordInput;
      ref.read(errorMessageProvider.notifier).state = null;
    } catch (e) {
      ref.read(errorMessageProvider.notifier).state = '임시 비밀번호가 일치하지 않습니다. 이메일을 확인해주세요.';
    } finally {
      ref.read(isLoadingProvider.notifier).state = false;
    }
  }

  Future<void> _setNewPassword() async {
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();
    final tempPassword = ref.read(tempPasswordProvider);
    
    if (newPassword.isEmpty) {
      ref.read(errorMessageProvider.notifier).state = '새 비밀번호를 입력해주세요.';
      return;
    }

    if (newPassword.length < 8) {
      ref.read(errorMessageProvider.notifier).state = '비밀번호는 8자 이상 입력해주세요.';
      return;
    }

    if (newPassword != confirmPassword) {
      ref.read(errorMessageProvider.notifier).state = '비밀번호가 일치하지 않습니다.';
      return;
    }

    ref.read(isLoadingProvider.notifier).state = true;
    ref.read(errorMessageProvider.notifier).state = null;

    try {
      final result = await AuthService.resetPassword(
        currentPassword: tempPassword,
        newPassword: newPassword,
      );

      if (result['success']) {
        // 성공 시 로그인 화면으로 이동
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '비밀번호가 성공적으로 변경되었습니다.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontFamily: 'Pretendard-Medium',
                  fontWeight: FontWeight.w500,
                ),
              ),
              backgroundColor: const Color(0xFF10CB86),
              duration: const Duration(seconds: 3),
            ),
          );
                     Navigator.pop(context);
        }
      } else {
        ref.read(errorMessageProvider.notifier).state = result['message'] ?? '비밀번호 재설정에 실패했습니다.';
      }
    } catch (e) {
      ref.read(errorMessageProvider.notifier).state = '네트워크 오류가 발생했습니다.';
    } finally {
      ref.read(isLoadingProvider.notifier).state = false;
    }
  }

  void _onTabChanged(FinderTab tab) {
    ref.read(finderTabProvider.notifier).state = tab;
    ref.read(errorMessageProvider.notifier).state = null;
    
    // 탭 변경 시 단계 초기화
    if (tab == FinderTab.findId) {
      ref.read(findIdStepProvider.notifier).state = FindIdStep.phoneInput;
    } else {
      ref.read(findPasswordStepProvider.notifier).state = FindPasswordStep.emailInput;
    }
  }

  Widget _buildTabHeader() {
    final currentTab = ref.watch(finderTabProvider);
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            height: 28,
            child: Row(
              children: [
                // 아이디 찾기 탭
                Expanded(
                  child: GestureDetector(
                    onTap: () => _onTabChanged(FinderTab.findId),
                    child: Container(
                      height: 28,
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            width: 2,
                            color: currentTab == FinderTab.findId 
                                ? const Color(0xFF202020)
                                : const Color(0xFFC4C4C4),
                          ),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '아이디 찾기',
                          style: TextStyle(
                            color: currentTab == FinderTab.findId 
                                ? const Color(0xFF202020)
                                : const Color(0xFF999999),
                            fontSize: 14,
                            fontFamily: currentTab == FinderTab.findId 
                                ? 'Pretendard-Bold'
                                : 'Pretendard-Light',
                            fontWeight: currentTab == FinderTab.findId 
                                ? FontWeight.w700
                                : FontWeight.w300,
                            letterSpacing: -0.32,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // 비밀번호 찾기 탭
                Expanded(
                  child: GestureDetector(
                    onTap: () => _onTabChanged(FinderTab.findPassword),
                    child: Container(
                      height: 28,
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            width: 2,
                            color: currentTab == FinderTab.findPassword 
                                ? const Color(0xFF202020)
                                : const Color(0xFFC4C4C4),
                          ),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '비밀번호 찾기',
                          style: TextStyle(
                            color: currentTab == FinderTab.findPassword 
                                ? const Color(0xFF202020)
                                : const Color(0xFF999999),
                            fontSize: 14,
                            fontFamily: currentTab == FinderTab.findPassword 
                                ? 'Pretendard-Bold'
                                : 'Pretendard-Light',
                            fontWeight: currentTab == FinderTab.findPassword 
                                ? FontWeight.w700
                                : FontWeight.w300,
                            letterSpacing: -0.32,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 초기 탭 설정 (한 번만 실행)
    if (!_hasInitialized && widget.initialTab != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(finderTabProvider.notifier).state = widget.initialTab!;
      });
      _hasInitialized = true;
    }
    
    final currentTab = ref.watch(finderTabProvider);
    
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F7F7),
        elevation: 0,
               leading: IconButton(
          icon: Image.asset(
            'assets/icons/parent/뒤로가기.png',
            width: 24,
            height: 24,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '아이디/비밀번호 찾기',
          style: TextStyle(
            color: const Color(0xFF202020),
            fontSize: 16,
            fontFamily: 'Pretendard-Bold',
            fontWeight: FontWeight.w700,
            letterSpacing: -0.32,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildTabHeader(),
          Expanded(
            child: currentTab == FinderTab.findId 
                ? _buildFindIdContent()
                : _buildFindPasswordContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildFindIdContent() {
    final currentStep = ref.watch(findIdStepProvider);
    final errorMessage = ref.watch(errorMessageProvider);
    
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 메인 컨텐츠
          switch (currentStep) {
            FindIdStep.phoneInput => _buildPhoneInputStep(),
            FindIdStep.verificationInput => _buildVerificationInputStep(),
            FindIdStep.result => _buildResultStep(),
          },
          
          // 에러 메시지
          if (errorMessage != null && currentStep != FindIdStep.result) ...[
            const SizedBox(height: 16),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: MediaQuery.of(context).size.width > 600
                    ? (MediaQuery.of(context).size.width - 400) / 2
                    : 16,
              ),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        errorMessage,
                        style: TextStyle(
                          color: Colors.red.shade900,
                          fontSize: 12,
                          fontFamily: 'Pretendard-Light',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 40),

          // 고객센터 안내
          if (currentStep != FindIdStep.result)
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: MediaQuery.of(context).size.width > 600
                    ? (MediaQuery.of(context).size.width - 400) / 2
                    : 16,
              ),
              child: Container(
                width: double.infinity,
                child: Text(
                  '아이디 찾기가 어려우시면, 고객센터를 통해 문의해 주세요.',
                  style: TextStyle(
                    color: const Color(0xFF999999),
                    fontSize: 12,
                    fontFamily: 'Pretendard-Light',
                    letterSpacing: -0.24,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.visible,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFindPasswordContent() {
    final currentStep = ref.watch(findPasswordStepProvider);
    final errorMessage = ref.watch(errorMessageProvider);
    
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 메인 컨텐츠
          switch (currentStep) {
            FindPasswordStep.emailInput => _buildEmailInputStep(),
            FindPasswordStep.tempPasswordInput => _buildTempPasswordInputStep(),
            FindPasswordStep.newPasswordInput => _buildNewPasswordInputStep(),
          },
          
          // 에러 메시지
          if (errorMessage != null) ...[
            const SizedBox(height: 16),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: MediaQuery.of(context).size.width > 600
                    ? (MediaQuery.of(context).size.width - 400) / 2
                    : 16,
              ),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        errorMessage,
                        style: TextStyle(
                          color: Colors.red.shade900,
                          fontSize: 12,
                          fontFamily: 'Pretendard-Light',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 40),

          // 고객센터 안내
          if (currentStep != FindPasswordStep.newPasswordInput)
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: MediaQuery.of(context).size.width > 600
                    ? (MediaQuery.of(context).size.width - 400) / 2
                    : 16,
              ),
              child: Container(
                width: double.infinity,
                child: Text(
                  '비밀번호 재설정이 어려우시면, 고객센터를 통해 문의해 주세요.',
                  style: TextStyle(
                    color: const Color(0xFF999999),
                    fontSize: 11,
                    fontFamily: 'Pretendard-Light',
                    letterSpacing: -0.24,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.visible,
                ),
              ),
            ),
        ],
      ),
    );
  }



  Widget _buildPhoneInputStep() {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width > 600
            ? (MediaQuery.of(context).size.width - 400) / 2
            : 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 60),
          
          Text(
            '회원가입 시 입력한 정보로\n아이디를 확인할 수 있어요',
            style: TextStyle(
              color: const Color(0xFF202020),
              fontSize: 20,
              fontFamily: 'Pretendard-Light',
              height: 1.50,
              letterSpacing: -0.80,
            ),
          ),

          const SizedBox(height: 80),

          // 휴대폰 번호 입력
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '휴대폰 번호',
                style: TextStyle(
                  color: const Color(0xFF353535),
                  fontSize: 16,
                  fontFamily: 'Pretendard-Light',
                  letterSpacing: -0.32,
                ),
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: ShapeDecoration(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          side: BorderSide(
                            width: _phoneController.text.isNotEmpty ? 1.40 : 0.80,
                            color: _phoneController.text.isNotEmpty 
                                ? const Color(0xFF5D9EFF)
                                : const Color(0xFFDADADA),
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        maxLength: 11,
                        decoration: InputDecoration(
                          hintText: '숫자만 입력해 주세요',
                          hintStyle: TextStyle(
                            color: const Color(0xFF999999),
                            fontSize: 14,
                            fontFamily: 'Pretendard-Light',
                            letterSpacing: -0.28,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          counterText: '',
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        style: TextStyle(
                          color: const Color(0xFF353535),
                          fontSize: 14,
                          fontFamily: 'Pretendard-Light',
                          letterSpacing: -0.28,
                        ),
                        onChanged: (value) {
                          // 숫자만 입력되도록 필터링
                          final numericValue = value.replaceAll(RegExp(r'[^0-9]'), '');
                          if (numericValue != value) {
                            _phoneController.text = numericValue;
                            _phoneController.selection = TextSelection.fromPosition(
                              TextPosition(offset: numericValue.length),
                            );
                          }
                          
                          // 에러 메시지 초기화
                          ref.read(errorMessageProvider.notifier).state = null;
                          setState(() {}); // 버튼 색상 및 테두리 색상 업데이트
                        },
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  Expanded(
                    flex: 2,
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: ShapeDecoration(
                        color: _phoneController.text.length >= 10 && !ref.watch(isLoadingProvider)
                            ? const Color(0xFF10CB86)
                            : const Color(0xFFDADADA),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: MaterialButton(
                        onPressed: _phoneController.text.length >= 10 && !ref.watch(isLoadingProvider)
                            ? _sendVerificationCode
                            : null,
                        padding: EdgeInsets.zero,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: ref.watch(isLoadingProvider)
                              ? SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  '인증번호\n전송',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontFamily: 'Pretendard-Light',
                                    letterSpacing: -0.24,
                                    height: 1.2,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationInputStep() {
    final phoneNumber = ref.watch(phoneNumberProvider);
    
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width > 600
            ? (MediaQuery.of(context).size.width - 400) / 2
            : 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 60),
          
          Text(
            '회원가입 시 입력한 정보로\n아이디를 확인할 수 있어요',
            style: TextStyle(
              color: const Color(0xFF202020),
              fontSize: 20,
              fontFamily: 'Pretendard-Light',
              height: 1.50,
              letterSpacing: -0.80,
            ),
          ),

          const SizedBox(height: 80),

          // 휴대폰 번호 (입력된 상태로 표시)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '휴대폰 번호',
                style: TextStyle(
                  color: const Color(0xFF353535),
                  fontSize: 16,
                  fontFamily: 'Pretendard-Light',
                  letterSpacing: -0.32,
                ),
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: ShapeDecoration(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          side: BorderSide(
                            width: 1.40,
                            color: const Color(0xFF5D9EFF),
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          phoneNumber,
                          style: TextStyle(
                            color: const Color(0xFF353535),
                            fontSize: 14,
                            fontFamily: 'Pretendard-Light',
                            letterSpacing: -0.28,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  Expanded(
                    flex: 2,
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: ShapeDecoration(
                        color: const Color(0xFFDADADA),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            '인증번호\n전송',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontFamily: 'Pretendard-Light',
                              letterSpacing: -0.24,
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // 인증번호 입력
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Container(
                      height: 48,
                      decoration: ShapeDecoration(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          side: BorderSide(
                            width: _verificationController.text.isNotEmpty ? 1.40 : 0.80,
                            color: _verificationController.text.isNotEmpty 
                                ? const Color(0xFF5D9EFF)
                                : const Color(0xFFDADADA),
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: TextField(
                                controller: _verificationController,
                                keyboardType: TextInputType.number,
                                maxLength: 6,
                                decoration: InputDecoration(
                                  hintText: '인증번호 입력',
                                  hintStyle: TextStyle(
                                    color: const Color(0xFF999999),
                                    fontSize: 14,
                                    fontFamily: 'Pretendard-Light',
                                    letterSpacing: -0.28,
                                  ),
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  counterText: '',
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                style: TextStyle(
                                  color: const Color(0xFF353535),
                                  fontSize: 14,
                                  fontFamily: 'Pretendard-Light',
                                  letterSpacing: -0.28,
                                ),
                                onChanged: (value) {
                                  // 숫자만 입력되도록 필터링
                                  final numericValue = value.replaceAll(RegExp(r'[^0-9]'), '');
                                  if (numericValue != value) {
                                    _verificationController.text = numericValue;
                                    _verificationController.selection = TextSelection.fromPosition(
                                      TextPosition(offset: numericValue.length),
                                    );
                                  }
                                  
                                  // 에러 메시지 초기화
                                  ref.read(errorMessageProvider.notifier).state = null;
                                  setState(() {}); // 버튼 색상 및 테두리 색상 업데이트
                                },
                              ),
                            ),
                          ),
                          if (ref.watch(timerSecondsProvider) > 0)
                            Padding(
                              padding: const EdgeInsets.only(right: 16),
                              child: Text(
                                _formatTime(ref.watch(timerSecondsProvider)),
                                style: TextStyle(
                                  color: const Color(0xFF3A88F4),
                                  fontSize: 12,
                                  fontFamily: 'Pretendard-Light',
                                  letterSpacing: -0.24,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  Expanded(
                    flex: 2,
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: ShapeDecoration(
                        color: _verificationController.text.length == 6 && !ref.watch(isLoadingProvider)
                            ? const Color(0xFF5D9EFF)
                            : const Color(0xFFDADADA),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: MaterialButton(
                        onPressed: _verificationController.text.length == 6 && !ref.watch(isLoadingProvider)
                            ? _verifyCode
                            : null,
                        padding: EdgeInsets.zero,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: ref.watch(isLoadingProvider)
                              ? SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  '인증번호\n확인',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontFamily: 'Pretendard-Light',
                                    letterSpacing: -0.24,
                                    height: 1.2,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // 안내 메시지
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(
                      Icons.info_outline,
                      size: 12,
                      color: const Color(0xFF8490A3),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '인증 문자가 도착하지 않으면 메시지 설정에서 차단 번호를 확인해 주세요',
                      style: TextStyle(
                        color: const Color(0xFF8490A3),
                        fontSize: 11,
                        fontFamily: 'Pretendard-Light',
                        letterSpacing: -0.22,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.visible,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 80),

          // 확인 버튼
          Container(
            width: double.infinity,
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
            decoration: ShapeDecoration(
              color: _verificationController.text.length == 6
                  ? const Color(0xFF10CB86)
                  : const Color(0xFFDCDCDC),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: MaterialButton(
              onPressed: _verificationController.text.length == 6 ? _verifyCode : null,
              padding: EdgeInsets.zero,
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '확인',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontFamily: 'Pretendard-Medium',
                      letterSpacing: -0.28,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultStep() {
    final foundEmail = ref.watch(foundEmailProvider);
    
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width > 600
            ? (MediaQuery.of(context).size.width - 400) / 2
            : 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 60),
          
          Container(
            width: double.infinity,
            child: Text(
              '이메일로 가입한 계정이 있어요!',
              style: TextStyle(
                color: const Color(0xFF202020),
                fontSize: 20,
                fontFamily: 'Pretendard-Light',
                height: 1.50,
                letterSpacing: -0.80,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.visible,
            ),
          ),

          const SizedBox(height: 80),

          Column(
            children: [
              Container(
                width: double.infinity,
                child: Text(
                  '가입한 계정',
                  style: TextStyle(
                    color: const Color(0xFF202020),
                    fontSize: 20,
                    fontFamily: 'Pretendard-Bold',
                    letterSpacing: -0.80,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              const SizedBox(height: 40),

              // 찾은 이메일 표시
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                decoration: ShapeDecoration(
                  color: const Color(0xFFF0F0F0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Center(
                  child: Text(
                    foundEmail ?? '',
                    style: TextStyle(
                      color: const Color(0xFF202020),
                      fontSize: 18,
                      fontFamily: 'Pretendard-Light',
                      letterSpacing: -0.72,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // 로그인하러 가기 버튼
              Container(
                width: double.infinity,
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                decoration: ShapeDecoration(
                  color: const Color(0xFF10CB86),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: MaterialButton(
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '로그인하러 가기',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontFamily: 'Pretendard-Medium',
                          letterSpacing: -0.28,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmailInputStep() {
    final isLoading = ref.watch(isLoadingProvider);
    
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width > 600
            ? (MediaQuery.of(context).size.width - 400) / 2
            : 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 60),
          
          // 제목
          Text(
            '가입한 이메일 아이디를 알려주시면\n비밀번호 재설정을 도와드릴게요',
            style: TextStyle(
              color: const Color(0xFF202020),
              fontSize: 20,
              fontFamily: 'Pretendard-Light',
              height: 1.50,
              letterSpacing: -0.80,
            ),
          ),

          const SizedBox(height: 80),

          // 이메일 라벨
          Text(
            '이메일',
            style: TextStyle(
              color: const Color(0xFF353535),
              fontSize: 16,
              fontFamily: 'Pretendard-Light',
              letterSpacing: -0.32,
            ),
          ),

          const SizedBox(height: 16),

          // 이메일 입력 필드
          Container(
            width: double.infinity,
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: ShapeDecoration(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                side: BorderSide(
                  width: _emailController.text.isNotEmpty ? 1.40 : 0.80,
                  color: _emailController.text.isNotEmpty 
                      ? const Color(0xFF5D9EFF)
                      : const Color(0xFFDADADA),
                ),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: '이메일 주소를 입력해 주세요',
                hintStyle: TextStyle(
                  color: const Color(0xFF999999),
                  fontSize: 14,
                  fontFamily: 'Pretendard-Light',
                  letterSpacing: -0.28,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                counterText: '',
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              style: TextStyle(
                color: const Color(0xFF353535),
                fontSize: 14,
                fontFamily: 'Pretendard-Light',
                letterSpacing: -0.28,
              ),
              onChanged: (value) {
                ref.read(errorMessageProvider.notifier).state = null;
                setState(() {}); // 버튼 색상 및 테두리 색상 업데이트
              },
            ),
          ),

          const SizedBox(height: 40),

          // 임시 비밀번호 발송 버튼
          Container(
            width: double.infinity,
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
            decoration: ShapeDecoration(
              color: _emailController.text.isNotEmpty && !isLoading
                  ? const Color(0xFF10CB86)
                  : const Color(0xFFDCDCDC),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: MaterialButton(
              onPressed: _emailController.text.isNotEmpty && !isLoading
                  ? _requestTemporaryPassword
                  : null,
              padding: EdgeInsets.zero,
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: isLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          '확인',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontFamily: 'Pretendard-Bold',
                            letterSpacing: -0.36,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTempPasswordInputStep() {
    final isLoading = ref.watch(isLoadingProvider);
    
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width > 600
            ? (MediaQuery.of(context).size.width - 400) / 2
            : 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 60),
          
          // 제목
          Text(
            '이메일로 발송된 임시 비밀번호를\n 입력해 주세요',
            style: TextStyle(
              color: const Color(0xFF202020),
              fontSize: 20,
              fontFamily: 'Pretendard-Light',
              height: 1.50,
              letterSpacing: -0.80,
            ),
          ),

          const SizedBox(height: 60),

          // 임시 비밀번호 라벨
          Text(
            '임시비밀번호',
            style: TextStyle(
              color: const Color(0xFF353535),
              fontSize: 16,
              fontFamily: 'Pretendard-Light',
              letterSpacing: -0.32,
            ),
          ),

          const SizedBox(height: 16),

          // 임시 비밀번호 입력 필드
          Container(
            width: double.infinity,
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: ShapeDecoration(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                side: BorderSide(
                  width: _tempPasswordController.text.isNotEmpty ? 1.40 : 0.80,
                  color: _tempPasswordController.text.isNotEmpty 
                      ? const Color(0xFF5D9EFF)
                      : const Color(0xFFDADADA),
                ),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _tempPasswordController,
                    keyboardType: TextInputType.visiblePassword,
                    obscureText: !ref.watch(isTempPasswordVisibleProvider),
                    decoration: InputDecoration(
                      hintText: '비밀번호를 입력해 주세요',
                      hintStyle: TextStyle(
                        color: const Color(0xFF999999),
                        fontSize: 14,
                        fontFamily: 'Pretendard-Light',
                        letterSpacing: -0.28,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      counterText: '',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    style: TextStyle(
                      color: const Color(0xFF353535),
                      fontSize: 14,
                      fontFamily: 'Pretendard-Light',
                      letterSpacing: -0.28,
                    ),
                    onChanged: (value) {
                      ref.read(errorMessageProvider.notifier).state = null;
                      setState(() {}); // 버튼 색상 및 테두리 색상 업데이트
                    },
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    ref.read(isTempPasswordVisibleProvider.notifier).state =
                        !ref.watch(isTempPasswordVisibleProvider);
                  },
                  child: Icon(
                    ref.watch(isTempPasswordVisibleProvider) 
                        ? Icons.visibility_off
                        : Icons.visibility,
                    color: const Color(0xFF999999),
                    size: 20,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),

          // 확인 버튼
          Container(
            width: double.infinity,
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
            decoration: ShapeDecoration(
              color: _tempPasswordController.text.isNotEmpty && !isLoading
                  ? const Color(0xFF10CB86)
                  : const Color(0xFFDCDCDC),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: MaterialButton(
              onPressed: _tempPasswordController.text.isNotEmpty && !isLoading
                  ? _loginWithTemporaryPassword
                  : null,
              padding: EdgeInsets.zero,
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: isLoading
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          '확인',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontFamily: 'Pretendard-Medium',
                            letterSpacing: -0.28,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewPasswordInputStep() {
    final isLoading = ref.watch(isLoadingProvider);
    
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width > 600
            ? (MediaQuery.of(context).size.width - 400) / 2
            : 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 60),
          
          // 제목
          Text(
            '새 비밀번호를 설정해 주세요',
            style: TextStyle(
              color: const Color(0xFF202020),
              fontSize: 20,
              fontFamily: 'Pretendard-Light',
              height: 1.50,
              letterSpacing: -0.80,
            ),
          ),

          const SizedBox(height: 80),

          // 새 비밀번호 설정 라벨
          Text(
            '새 비밀번호 설정',
            style: TextStyle(
              color: const Color(0xFF353535),
              fontSize: 16,
              fontFamily: 'Pretendard-Light',
              letterSpacing: -0.32,
            ),
          ),

          const SizedBox(height: 16),

          // 새 비밀번호 입력 (라벨)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: double.infinity,
                child: Text(
                  '비밀번호',
                  style: TextStyle(
                    color: const Color(0xFF666666),
                    fontSize: 12,
                    fontFamily: 'Pretendard-Light',
                    letterSpacing: -0.24,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: ShapeDecoration(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(
                      width: _newPasswordController.text.isNotEmpty ? 1.40 : 0.80,
                      color: _newPasswordController.text.isNotEmpty 
                          ? const Color(0xFF5D9EFF)
                          : const Color(0xFFDADADA),
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                                                  controller: _newPasswordController,
                          keyboardType: TextInputType.visiblePassword,
                          obscureText: !ref.watch(isNewPasswordVisibleProvider),
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
                            counterText: '',
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          style: TextStyle(
                            color: const Color(0xFF353535),
                            fontSize: 14,
                            fontFamily: 'Pretendard-Light',
                            letterSpacing: -0.28,
                          ),
                          onChanged: (value) {
                            ref.read(errorMessageProvider.notifier).state = null;
                            setState(() {}); // 버튼 색상 및 테두리 색상 업데이트
                          },
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        ref.read(isNewPasswordVisibleProvider.notifier).state =
                            !ref.watch(isNewPasswordVisibleProvider);
                      },
                      child: Icon(
                        ref.watch(isNewPasswordVisibleProvider) 
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: const Color(0xFF999999),
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    child: Icon(
                      Icons.info_outline,
                      size: 12,
                      color: const Color(0xFF8490A3),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '8자 이상으로 입력하지 않을 시, 비밀번호 설정이 불가능합니다',
                    style: TextStyle(
                      color: const Color(0xFF8490A3),
                      fontSize: 11,
                      fontFamily: 'Pretendard-Light',
                      letterSpacing: -0.22,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 비밀번호 확인 입력
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: double.infinity,
                child: Text(
                  '비밀번호 확인',
                  style: TextStyle(
                    color: const Color(0xFF666666),
                    fontSize: 12,
                    fontFamily: 'Pretendard-Light',
                    letterSpacing: -0.24,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: ShapeDecoration(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(
                      width: _confirmPasswordController.text.isNotEmpty ? 1.40 : 0.80,
                      color: _confirmPasswordController.text.isNotEmpty 
                          ? const Color(0xFF5D9EFF)
                          : const Color(0xFFDADADA),
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                                                  controller: _confirmPasswordController,
                          keyboardType: TextInputType.visiblePassword,
                          obscureText: !ref.watch(isConfirmPasswordVisibleProvider),
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
                            counterText: '',
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          style: TextStyle(
                            color: const Color(0xFF353535),
                            fontSize: 14,
                            fontFamily: 'Pretendard-Light',
                            letterSpacing: -0.28,
                          ),
                          onChanged: (value) {
                            ref.read(errorMessageProvider.notifier).state = null;
                            setState(() {}); // 버튼 색상 및 테두리 색상 업데이트
                          },
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        ref.read(isConfirmPasswordVisibleProvider.notifier).state =
                            !ref.watch(isConfirmPasswordVisibleProvider);
                      },
                      child: Icon(
                        ref.watch(isConfirmPasswordVisibleProvider) 
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: const Color(0xFF999999),
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 80),

          // 확인 버튼
          Container(
            width: double.infinity,
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
            decoration: ShapeDecoration(
              color: _newPasswordController.text.isNotEmpty && 
                     _confirmPasswordController.text.isNotEmpty && 
                     !isLoading
                  ? const Color(0xFF10CB86)
                  : const Color(0xFFDCDCDC),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: MaterialButton(
              onPressed: _newPasswordController.text.isNotEmpty && 
                         _confirmPasswordController.text.isNotEmpty && 
                         !isLoading
                  ? _setNewPassword
                  : null,
              padding: EdgeInsets.zero,
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: isLoading
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          '확인',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontFamily: 'Pretendard-Medium',
                            letterSpacing: -0.28,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}