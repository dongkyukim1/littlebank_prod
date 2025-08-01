import 'package:flutter/material.dart';
import '../../../services/auth_service.dart';

class PasswordResetModal extends StatefulWidget {
  const PasswordResetModal({super.key});

  @override
  State<PasswordResetModal> createState() => _PasswordResetModalState();
}

class _PasswordResetModalState extends State<PasswordResetModal> {
  // 현재 단계 (0: 이메일 입력, 1: 임시 비밀번호 입력, 2: 새 비밀번호 설정)
  int currentStep = 0;
  bool isLoading = false;
  
  // 컨트롤러들
  final emailController = TextEditingController();
  final tempPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  
  // 비밀번호 가시성
  bool isTempPasswordVisible = false;
  bool isNewPasswordVisible = false;
  bool isConfirmPasswordVisible = false;
  
  // 에러 메시지
  String? errorMessage;
  String? emailError;
  String? passwordError;

  @override
  void dispose() {
    emailController.dispose();
    tempPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  // 이메일 유효성 검사
  bool isValidEmail(String email) {
    return RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email);
  }

  // 1단계: 임시 비밀번호 요청
  Future<void> _requestTemporaryPassword() async {
    if (emailController.text.trim().isEmpty) {
      setState(() {
        emailError = '이메일을 입력해주세요';
      });
      return;
    }

    if (!isValidEmail(emailController.text.trim())) {
      setState(() {
        emailError = '올바른 이메일 형식을 입력해주세요';
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
      emailError = null;
    });

    try {
      final result = await AuthService.requestTemporaryPassword(
        email: emailController.text.trim(),
      );

      if (result['success']) {
        setState(() {
          currentStep = 1;
          errorMessage = null;
        });
      } else {
        setState(() {
          errorMessage = result['message'] ?? '임시 비밀번호 발급에 실패했습니다.';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = '네트워크 오류가 발생했습니다. 다시 시도해주세요.';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // 2단계: 임시 비밀번호로 로그인
  Future<void> _loginWithTemporaryPassword() async {
    if (tempPasswordController.text.trim().isEmpty) {
      setState(() {
        passwordError = '임시 비밀번호를 입력해주세요';
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
      passwordError = null;
    });

    try {
      final result = await AuthService.login(
        email: emailController.text.trim(),
        password: tempPasswordController.text.trim(),
      );

      // 로그인 성공 시 다음 단계로
      setState(() {
        currentStep = 2;
        errorMessage = null;
      });
    } catch (e) {
      setState(() {
        errorMessage = '임시 비밀번호가 일치하지 않습니다. 이메일을 확인해주세요.';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // 3단계: 새 비밀번호 설정
  Future<void> _setNewPassword() async {
    if (newPasswordController.text.trim().isEmpty) {
      setState(() {
        passwordError = '새 비밀번호를 입력해주세요';
      });
      return;
    }

    if (newPasswordController.text.length < 8) {
      setState(() {
        passwordError = '비밀번호는 8자 이상 입력해주세요';
      });
      return;
    }

    if (newPasswordController.text != confirmPasswordController.text) {
      setState(() {
        passwordError = '비밀번호가 일치하지 않습니다';
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
      passwordError = null;
    });

    try {
      final result = await AuthService.resetPassword(
        currentPassword: tempPasswordController.text.trim(),
        newPassword: newPasswordController.text.trim(),
      );

      if (result['success']) {
        // 성공 시 모달 닫기
        Navigator.of(context).pop();
        _showSuccessSnackBar();
      } else {
        setState(() {
          errorMessage = result['message'] ?? '비밀번호 재설정에 실패했습니다.';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = '네트워크 오류가 발생했습니다. 다시 시도해주세요.';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showSuccessSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('비밀번호가 성공적으로 변경되었습니다.'),
        backgroundColor: const Color(0xFF10CB86),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          for (int i = 0; i < 3; i++) ...[
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i <= currentStep 
                    ? const Color(0xFF10CB86) 
                    : const Color(0xFFDADADA),
              ),
            ),
            if (i < 2) 
              Expanded(
                child: Container(
                  height: 2,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  color: i < currentStep 
                      ? const Color(0xFF10CB86) 
                      : const Color(0xFFDADADA),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmailStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 제목
        Text(
          '이메일을 입력해주세요',
          style: TextStyle(
            color: const Color(0xFF353535),
            fontSize: 16,
            fontFamily: 'Pretendard-Bold',
            letterSpacing: -0.72,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '가입하신 이메일로 임시 비밀번호를 발송해드릴게요',
          style: TextStyle(
            color: const Color(0xFF999999),
            fontSize: 12,
            fontFamily: 'Pretendard-Light',
            letterSpacing: -0.28,
          ),
        ),
        const SizedBox(height: 24),

        // 이메일 입력
        Text(
          '이메일',
          style: TextStyle(
            color: const Color(0xFFC4C4C4),
            fontSize: 12,
            fontFamily: 'Pretendard-Light',
            letterSpacing: -0.28,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 358,
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: ShapeDecoration(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              side: BorderSide(
                width: 0.80,
                color: emailError != null 
                    ? const Color(0xFFFF5C5C) 
                    : const Color(0xFFDADADA),
              ),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: TextField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              hintText: 'example@email.com',
              hintStyle: TextStyle(
                color: const Color(0xFF999999),
                fontSize: 12,
                fontFamily: 'Pretendard-Light',
                letterSpacing: -0.28,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
            ),
            onChanged: (value) {
              if (emailError != null) {
                setState(() {
                  emailError = null;
                });
              }
            },
          ),
        ),

        // 에러 메시지
        if (emailError != null) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  size: 12,
                  color: const Color(0xFFFF5C5C),
                ),
                const SizedBox(width: 6),
                Text(
                  emailError!,
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
        ],

        const SizedBox(height: 32),

        // 전송 버튼
        GestureDetector(
          onTap: isLoading ? null : _requestTemporaryPassword,
          child: Container(
            width: 358,
            height: 48,
            decoration: ShapeDecoration(
              color: isLoading 
                  ? const Color(0xFFDADADA) 
                  : const Color(0xFF10CB86),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Center(
              child: isLoading 
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      '임시 비밀번호 발송',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontFamily: 'Pretendard-Medium',
                        letterSpacing: -0.28,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTempPasswordStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 제목
        Text(
          '임시 비밀번호를 입력해주세요',
          style: TextStyle(
            color: const Color(0xFF353535),
            fontSize: 16,
            fontFamily: 'Pretendard-Bold',
            letterSpacing: -0.72,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '이메일로 발송된 임시 비밀번호를 입력해주세요',
          style: TextStyle(
            color: const Color(0xFF999999),
            fontSize: 12,
            fontFamily: 'Pretendard-Light',
            letterSpacing: -0.28,
          ),
        ),
        const SizedBox(height: 24),

        // 임시 비밀번호 입력
        Text(
          '임시 비밀번호',
          style: TextStyle(
            color: const Color(0xFFC4C4C4),
            fontSize: 12,
            fontFamily: 'Pretendard-Light',
            letterSpacing: -0.28,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 358,
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: ShapeDecoration(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              side: BorderSide(
                width: 0.80,
                color: passwordError != null 
                    ? const Color(0xFFFF5C5C) 
                    : const Color(0xFFDADADA),
              ),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: tempPasswordController,
                  obscureText: !isTempPasswordVisible,
                  decoration: InputDecoration(
                    hintText: '이메일로 받은 임시 비밀번호',
                    hintStyle: TextStyle(
                      color: const Color(0xFF999999),
                      fontSize: 12,
                      fontFamily: 'Pretendard-Light',
                      letterSpacing: -0.28,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                  onChanged: (value) {
                    if (passwordError != null) {
                      setState(() {
                        passwordError = null;
                      });
                    }
                  },
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    isTempPasswordVisible = !isTempPasswordVisible;
                  });
                },
                child: Icon(
                  isTempPasswordVisible 
                      ? Icons.visibility 
                      : Icons.visibility_off,
                  color: const Color(0xFF999999),
                  size: 24,
                ),
              ),
            ],
          ),
        ),

        // 에러 메시지
        if (passwordError != null) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  size: 12,
                  color: const Color(0xFFFF5C5C),
                ),
                const SizedBox(width: 6),
                Text(
                  passwordError!,
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
        ],

        const SizedBox(height: 32),

        // 로그인 버튼
        GestureDetector(
          onTap: isLoading ? null : _loginWithTemporaryPassword,
          child: Container(
            width: 358,
            height: 48,
            decoration: ShapeDecoration(
              color: isLoading 
                  ? const Color(0xFFDADADA) 
                  : const Color(0xFF10CB86),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Center(
              child: isLoading 
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      '로그인',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontFamily: 'Pretendard-Medium',
                        letterSpacing: -0.28,
                      ),
                    ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // 뒤로 가기 버튼
        GestureDetector(
          onTap: () {
            setState(() {
              currentStep = 0;
              errorMessage = null;
              passwordError = null;
            });
          },
          child: Container(
            width: 358,
            height: 48,
            decoration: ShapeDecoration(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                side: const BorderSide(
                  width: 0.80,
                  color: Color(0xFFDADADA),
                ),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Center(
              child: Text(
                '이전 단계',
                style: TextStyle(
                  color: const Color(0xFF999999),
                  fontSize: 14,
                  fontFamily: 'Pretendard-Medium',
                  letterSpacing: -0.28,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNewPasswordStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 제목
        Text(
          '새 비밀번호를 설정해주세요',
          style: TextStyle(
            color: const Color(0xFF353535),
            fontSize: 16,
            fontFamily: 'Pretendard-Bold',
            letterSpacing: -0.72,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '보안을 위해 8자 이상의 새로운 비밀번호를 설정해주세요',
          style: TextStyle(
            color: const Color(0xFF999999),
            fontSize: 12,
            fontFamily: 'Pretendard-Light',
            letterSpacing: -0.28,
          ),
        ),
        const SizedBox(height: 24),

        // 새 비밀번호 입력
        Text(
          '새 비밀번호',
          style: TextStyle(
            color: const Color(0xFFC4C4C4),
            fontSize: 12,
            fontFamily: 'Pretendard-Light',
            letterSpacing: -0.28,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 358,
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: ShapeDecoration(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              side: BorderSide(
                width: 0.80,
                color: passwordError != null 
                    ? const Color(0xFFFF5C5C) 
                    : const Color(0xFFDADADA),
              ),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: newPasswordController,
                  obscureText: !isNewPasswordVisible,
                  decoration: InputDecoration(
                    hintText: '8자 이상의 새 비밀번호',
                    hintStyle: TextStyle(
                      color: const Color(0xFF999999),
                      fontSize: 12,
                      fontFamily: 'Pretendard-Light',
                      letterSpacing: -0.28,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                  onChanged: (value) {
                    if (passwordError != null) {
                      setState(() {
                        passwordError = null;
                      });
                    }
                  },
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    isNewPasswordVisible = !isNewPasswordVisible;
                  });
                },
                child: Icon(
                  isNewPasswordVisible 
                      ? Icons.visibility 
                      : Icons.visibility_off,
                  color: const Color(0xFF999999),
                  size: 24,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // 비밀번호 확인 입력
        Text(
          '비밀번호 확인',
          style: TextStyle(
            color: const Color(0xFFC4C4C4),
            fontSize: 12,
            fontFamily: 'Pretendard-Light',
            letterSpacing: -0.28,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 358,
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: ShapeDecoration(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              side: BorderSide(
                width: 0.80,
                color: passwordError != null 
                    ? const Color(0xFFFF5C5C) 
                    : const Color(0xFFDADADA),
              ),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: confirmPasswordController,
                  obscureText: !isConfirmPasswordVisible,
                  decoration: InputDecoration(
                    hintText: '비밀번호를 다시 입력해주세요',
                    hintStyle: TextStyle(
                      color: const Color(0xFF999999),
                      fontSize: 12,
                      fontFamily: 'Pretendard-Light',
                      letterSpacing: -0.28,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                  onChanged: (value) {
                    if (passwordError != null) {
                      setState(() {
                        passwordError = null;
                      });
                    }
                  },
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    isConfirmPasswordVisible = !isConfirmPasswordVisible;
                  });
                },
                child: Icon(
                  isConfirmPasswordVisible 
                      ? Icons.visibility 
                      : Icons.visibility_off,
                  color: const Color(0xFF999999),
                  size: 24,
                ),
              ),
            ],
          ),
        ),

        // 에러 메시지
        if (passwordError != null) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  size: 12,
                  color: const Color(0xFFFF5C5C),
                ),
                const SizedBox(width: 6),
                Text(
                  passwordError!,
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
        ],

        const SizedBox(height: 32),

        // 완료 버튼
        GestureDetector(
          onTap: isLoading ? null : _setNewPassword,
          child: Container(
            width: 358,
            height: 48,
            decoration: ShapeDecoration(
              color: isLoading 
                  ? const Color(0xFFDADADA) 
                  : const Color(0xFF10CB86),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Center(
              child: isLoading 
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      '비밀번호 변경 완료',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontFamily: 'Pretendard-Medium',
                        letterSpacing: -0.28,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 390,
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 상단 핸들
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFE0E0E0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // 닫기 버튼
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.all(8),
                child: Icon(
                  Icons.close,
                  color: const Color(0xFF999999),
                  size: 24,
                ),
              ),
            ),
          ),

          // 단계 표시기
          _buildStepIndicator(),

          const SizedBox(height: 8),

          // 메인 컨텐츠
          Container(
            width: 390,
            padding: const EdgeInsets.all(16),
            child: currentStep == 0 
                ? _buildEmailStep()
                : currentStep == 1 
                    ? _buildTempPasswordStep()
                    : _buildNewPasswordStep(),
          ),

          // 전체 에러 메시지
          if (errorMessage != null) ...[
            Container(
              width: 358,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFF5C5C).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                errorMessage!,
                style: TextStyle(
                  color: const Color(0xFFFF5C5C),
                  fontSize: 12,
                  fontFamily: 'Pretendard-Light',
                  letterSpacing: -0.24,
                ),
              ),
            ),
          ],

          const SizedBox(height: 16),
        ],
      ),
    );
  }
} 