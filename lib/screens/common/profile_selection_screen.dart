import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../child/child_home_wrapper.dart';
import '../parent/parent_home_wrapper.dart';
import 'splash/splash_manager.dart';

class ProfileSelectionScreen extends StatefulWidget {
  final String userId;
  final String jumin; // 생년월일 6자리
  final String? password;
  final String? name;
  final String? phone;
  final bool? marketingAgreed;

  // 계좌 정보 (선택적)
  final String? bankName;
  final String? bankCode;
  final String? bankAccount;
  final String? accountPin;

  // 약관 동의 필드들 추가
  final bool? agreedTermsOfService;
  final bool? agreedPrivacyCollection;
  final bool? agreedMinorGuardian;
  final bool? agreedElectronicFinance;
  final bool? agreedRewardGuardian;
  final bool? agreedThirdPartySharing;
  final bool? agreedDataProcessingDelegation;

  const ProfileSelectionScreen({
    super.key,
    required this.userId,
    required this.jumin,
    this.password,
    this.name,
    this.phone,
    this.marketingAgreed,
    this.bankName,
    this.bankCode,
    this.bankAccount,
    this.accountPin,
    // 약관 동의 필드들 추가
    this.agreedTermsOfService,
    this.agreedPrivacyCollection,
    this.agreedMinorGuardian,
    this.agreedElectronicFinance,
    this.agreedRewardGuardian,
    this.agreedThirdPartySharing,
    this.agreedDataProcessingDelegation,
  });

  @override
  State<ProfileSelectionScreen> createState() => _ProfileSelectionScreenState();
}

class _ProfileSelectionScreenState extends State<ProfileSelectionScreen> {
  // 안정적인 context 접근을 위한 key 추가
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // 프로필 선택 상태 변수
  String _selectedProfile = ''; // 'student', 'parent', 'teacher'

  // 학생 여부 확인 함수
  bool _isStudent() {
    if (widget.jumin.isNotEmpty) {
      int birthYear = int.tryParse(widget.jumin.substring(0, 2)) ?? 0;
      int currentYear = DateTime.now().year % 100;

      // 주석과 코드 일치시키기: 현재 2023년 기준으로
      // 00~23년생은 2000년대, 24~99년생은 1900년대로 판단
      if (birthYear > currentYear) {
        // 93은 23보다 크므로 이 조건에 해당 → 1900을 더해 1993년으로 계산
        birthYear += 1900;
      } else {
        // 05는 23보다 작으므로 이 조건에 해당 → 2000을 더해 2005년으로 계산
        birthYear += 2000;
      }

      int age = DateTime.now().year - birthYear;
      return age >= 8 && age <= 20; // 8~20세를 학생으로 간주
    }
    return false;
  }

  void _goToNextStep() async {
    // 프로필 선택 확인
    if (_selectedProfile.isEmpty) {
      _showErrorModal('알림', '프로필을 선택해주세요');
      return;
    }

    // role 매핑 미리 준비
    String role = "";
    if (_selectedProfile == 'student') {
      role = "CHILD";
    } else if (_selectedProfile == 'parent')
      role = "PARENT";
    else if (_selectedProfile == 'teacher')
      role = "TEACHER";

    // 최종 확인 다이얼로그
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (BuildContext dialogContext) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 0,
            backgroundColor: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(24),
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
                  // 프로필 아이콘
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFF3A88F4).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _selectedProfile == 'student'
                          ? Icons.school
                          : _selectedProfile == 'parent'
                          ? Icons.family_restroom
                          : Icons.assignment_ind,
                      color: const Color(0xFF3A88F4),
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 제목
                  Text(
                    '프로필 선택 확인',
                    style: TextStyle(
                      fontSize: 20,
                      fontFamily: 'Pretendard-Bold',
                      color: const Color(0xFF202020),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 선택된 프로필 정보
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE4ECF8),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF3A88F4),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          _selectedProfile == 'student'
                              ? '학생 프로필'
                              : _selectedProfile == 'parent'
                              ? '부모님 프로필'
                              : '선생님 프로필',
                          style: TextStyle(
                            fontSize: 16,
                            fontFamily: 'Pretendard-Bold',
                            color: const Color(0xFF3A88F4),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '선택하신 프로필로 계정이 생성됩니다.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: 'Pretendard-Light',
                            color: const Color(0xFF8490A3),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 경고 메시지
                  Text(
                    '프로필은 추후 변경이 불가능하므로\n신중하게 선택해주세요.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: 'Pretendard-Light',
                      color: const Color(0xFF8490A3),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 버튼들
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 48,
                          child: TextButton(
                            onPressed: () {
                              Navigator.pop(dialogContext);
                            },
                            style: TextButton.styleFrom(
                              backgroundColor: const Color(0xFFF5F5F5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              '다시 선택',
                              style: TextStyle(
                                fontSize: 14,
                                fontFamily: 'Pretendard-Medium',
                                color: const Color(0xFF8490A3),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(dialogContext);
                              _showLoadingDialog();
                              _processSignup(role);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF3A88F4),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              '확인',
                              style: TextStyle(
                                fontSize: 14,
                                fontFamily: 'Pretendard-Medium',
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    );
  }

  // 로딩 다이얼로그 표시
  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 20),
                Text(
                  '처리 중입니다...',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 로딩 메시지 업데이트
  void _updateLoadingMessage(String message) {
    if (!mounted) return;

    // 이미 로딩 다이얼로그가 표시되어 있을 경우 닫고 새로 표시
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 20),
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 회원가입 완료 모달 표시
  void _showSignupCompleteModal() {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 성공 아이콘 - 애니메이션 효과가 있는 체크 아이콘
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF4CAF50),
                        const Color(0xFF66BB6A),
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4CAF50).withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 40),
                ),
                const SizedBox(height: 24),

                // 메인 제목
                const Text(
                  '회원가입이 완료되었습니다!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Pretendard-Bold',
                    color: Color(0xFF1A1A1A),
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // 서브 메시지
                const Text(
                  '설명서를 보고\n2주 무료 코드를 받아가세요',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    fontFamily: 'Pretendard-Regular',
                    color: Color(0xFF666666),
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // 코드 박스
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 20,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFE0E0E0),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.card_giftcard,
                        color: const Color(0xFF4CAF50),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'littlebank',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Pretendard-SemiBold',
                          color: Color(0xFF4CAF50),
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 안내 텍스트
                const Text(
                  '잠시 후 자동으로 이동됩니다',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    fontFamily: 'Pretendard-Regular',
                    color: Color(0xFF999999),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 회원가입 처리 로직을 별도 메서드로 분리
  Future<void> _processSignup(String role) async {
    // 회원가입 API 호출
    if (widget.password != null &&
        widget.name != null &&
        widget.phone != null) {
      try {
        _updateLoadingMessage('회원가입 요청 처리 중...');
        print(
          '회원가입 API 요청: 이메일=${widget.userId}, 이름=${widget.name}, 전화번호=${widget.phone}, 생년월일=${widget.jumin}, 역할=$role',
        );

        // API 호출
        final result = await AuthService.signup(
          email: widget.userId,
          password: widget.password!,
          name: widget.name!,
          phone: widget.phone!,
          rrn: widget.jumin.substring(0, 6),
          bankName: widget.bankName ?? "",
          bankAccount: widget.bankAccount ?? "",
          bankCode: widget.bankCode ?? "",
          accountPin:
              widget.accountPin != null && widget.accountPin!.isNotEmpty
                  ? widget.accountPin
                  : null,
          role: role,
          // 약관 동의 정보 추가
          agreedTermsOfService: widget.agreedTermsOfService ?? true,
          agreedPrivacyCollection: widget.agreedPrivacyCollection ?? true,
          agreedMinorGuardian: widget.agreedMinorGuardian,
          agreedElectronicFinance: widget.agreedElectronicFinance ?? true,
          agreedRewardGuardian: widget.agreedRewardGuardian,
          agreedThirdPartySharing: widget.agreedThirdPartySharing ?? false,
          agreedDataProcessingDelegation: widget.agreedDataProcessingDelegation ?? false,
          agreedMarketing: widget.marketingAgreed ?? false,
        );

        print('회원가입 성공: $result');

        if (!mounted) return;

        // 회원가입 성공 후 바로 스플래시로 이동 (자동 로그인은 스플래시 후에)
        await _navigateToSplash(role);
      } catch (error) {
        print('회원가입 오류 발생: $error');

        if (!mounted) return;

        // 로딩 다이얼로그가 표시된 경우 닫기
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }

        // 오류 메시지 확인
        String errorMsg = error.toString().toLowerCase();

        // 201 응답은 실제로 성공이므로 처리
        if (errorMsg.contains("201") &&
            (errorMsg.contains("userid") || errorMsg.contains("email"))) {
          print('201 응답은 성공입니다. 회원가입 완료 후 스플래시 이동');

          // 회원가입 성공 후 바로 스플래시로 이동 (자동 로그인은 스플래시 후에)
          await _navigateToSplash(role);
        }
        // 이메일 중복 오류 처리
        else if (errorMsg.contains("u001") ||
            errorMsg.contains("u002") ||
            errorMsg.contains("중복") ||
            errorMsg.contains("존재") ||
            errorMsg.contains("duplicate") ||
            errorMsg.contains("email")) {
          // 이메일 중복 오류인 경우
          _showDuplicateEmailDialog();
        }
        // 서버 오류
        else if (errorMsg.contains("500") || errorMsg.contains("server")) {
          _showErrorModal('서버 오류', '서버에 일시적인 문제가 발생했습니다.\n잠시 후 다시 시도해주세요.');
        }
        // 네트워크 오류
        else if (errorMsg.contains("network") ||
            errorMsg.contains("connection") ||
            errorMsg.contains("timeout") ||
            errorMsg.contains("socket")) {
          _showErrorModal('네트워크 오류', '인터넷 연결을 확인해주세요.\n네트워크 상태가 불안정합니다.');
        }
        // 기타 오류
        else {
          _showErrorModal('회원가입 실패', '회원가입 처리 중 오류가 발생했습니다.\n잠시 후 다시 시도해주세요.');
        }
      }
    } else {
      // 필요한 정보가 없는 경우 에러 메시지
      if (!mounted) return;

      // 로딩 다이얼로그가 표시된 경우 닫기
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      _showErrorModal('정보 부족', '회원가입에 필요한 정보가 부족합니다.\n이전 단계부터 다시 진행해주세요.');
    }
  }

  // 회원가입 성공 후 바로 스플래시로 이동
  Future<void> _navigateToSplash(String role) async {
    try {
      print('🚀 회원가입 완료 후 스플래시 이동 시작 - 역할: $role');
      print('🔍 현재 mounted 상태: $mounted');
      print('🔍 현재 context valid: ${context.mounted}');

      // 먼저 해당 역할의 스플래시 상태를 초기화 (회원가입 후 반드시 스플래시 보여주기)
      await SplashManager.resetUserStatus(widget.userId);
      print('🔄 스플래시 상태 초기화 완료');

      _showSignupCompleteModal();
      print('📱 회원가입 완료 모달 표시 완료');

      // 잠시 대기 (사용자에게 완료 메시지 보여주기)
      await Future.delayed(const Duration(milliseconds: 3000));
      print('⏰ 1.5초 대기 완료');

      if (!mounted) {
        print('❌ mounted가 false가 되어 중단됨');
        return;
      }

      // 로딩 다이얼로그 닫기
      if (Navigator.of(context).canPop()) {
        print('🔄 로딩 다이얼로그 닫기');
        Navigator.of(context).pop();
      }

      print('🎬 스플래시 화면으로 이동 준비 - 역할: $role');

      // 역할에 따라 적절한 스플래시 화면으로 이동 (회원가입 정보 포함)
      Widget homeScreen;
      if (role == 'CHILD') {
        homeScreen = ChildHomeWrapper(
          userId: widget.userId,
          signupEmail: widget.userId,
          signupPassword: widget.password,
        );
        print('👶 아이용 스플래시 화면 위젯 생성 완료');
      } else {
        homeScreen = ParentHomeWrapper(
          userId: widget.userId,
          signupEmail: widget.userId,
          signupPassword: widget.password,
        );
        print('👨‍👩‍👧‍👦 부모용 스플래시 화면 위젯 생성 완료');
      }

      print('🚪 네비게이션 시작 - 모든 이전 화면 제거');

      // 모든 화면 스택을 정리하고 스플래시 화면으로 이동
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) {
            print('🏗️ MaterialPageRoute builder 호출됨');
            return homeScreen;
          },
        ),
        (route) {
          print('🗑️ 기존 route 제거 중: ${route.settings.name}');
          return false;
        },
      );

      print('✅ 스플래시 화면으로 네비게이션 완료');
    } catch (e, stackTrace) {
      print('❌ 스플래시 이동 실패: $e');
      print('📊 스택 트레이스: $stackTrace');

      if (!mounted) {
        print('❌ 예외 처리 중 mounted가 false');
        return;
      }

      // 로딩 다이얼로그 닫기
      if (Navigator.of(context).canPop()) {
        print('🔄 예외 처리 중 로딩 다이얼로그 닫기');
        Navigator.of(context).pop();
      }

      // 오류 시 성공 다이얼로그 표시
      print('🔄 오류로 인한 수동 로그인 안내 다이얼로그 표시');
      _showSignupSuccessDialog();
    }
  }

  // 회원가입 성공 다이얼로그
  void _showSignupSuccessDialog() {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (BuildContext dialogContext) => Dialog(
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
                  // 성공 아이콘
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 50,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 제목
                  const Text(
                    '회원가입 완료!',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),

                  // 메시지
                  Column(
                    children: [
                      Text(
                        widget.bankName != null && widget.bankName!.isNotEmpty
                            ? '계좌 연결과 함께\n회원가입이 완료되었습니다!'
                            : '회원가입이 완료되었습니다!',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '자동 로그인 처리 중 문제가 발생했습니다.\n로그인 화면에서 직접 로그인해주세요.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: Colors.black54),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.bankName != null && widget.bankName!.isNotEmpty
                            ? '연결된 계좌: ${widget.bankName}'
                            : '로그인 후 스플래시 화면을 보실 수 있습니다.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color:
                              widget.bankName != null &&
                                      widget.bankName!.isNotEmpty
                                  ? Colors.green
                                  : Colors.blue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),

                  // 확인 버튼
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // 모든 화면 스택을 정리하고 처음 화면(로그인)으로 돌아감
                        Navigator.of(
                          dialogContext,
                        ).popUntil((route) => route.isFirst);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        '로그인하기',
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
    );
  }

  // 이메일 중복 다이얼로그
  void _showDuplicateEmailDialog() {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (BuildContext dialogContext) => Dialog(
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
                  // 정보 아이콘
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.info, color: Colors.blue, size: 40),
                  ),
                  const SizedBox(height: 15),

                  // 제목
                  const Text(
                    '이미 가입된 이메일',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),

                  // 메시지
                  Text(
                    '${widget.userId} 계정은 이미 가입되어 있습니다.\n로그인 화면으로 이동하여 로그인해주세요.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                  const SizedBox(height: 25),

                  // 확인 버튼
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // 로그인 화면으로 이동
                        Navigator.of(
                          dialogContext,
                        ).popUntil((route) => route.isFirst);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        '로그인 화면으로',
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
    );
  }

  // 에러 모달 표시 함수
  void _showErrorModal(String title, String message) {
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

  @override
  Widget build(BuildContext context) {
    // 생년월일 기반으로 학생 여부 확인
    final bool isStudent = _isStudent();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: Container(
        width: 390,
        height: 885,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(color: const Color(0xFFF7F7F7)),
        child: Stack(
          children: [
            // 상단 앱바
            Positioned(
              left: 0,
              top: 44,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
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
                            '프로필 선택',
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
              ),
            ),

            // 제목과 설명
            Positioned(
              left: 16,
              top: 160,
              right: 16,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '프로필을 선택해 주세요',
                    style: TextStyle(
                      color: const Color(0xFF202020),
                      fontSize: 20,
                      fontFamily: 'Pretendard-Bold',
                      height: 1.50,
                      letterSpacing: -0.88,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isStudent
                        ? '앞서 선택한 정보들을 통해 학생이신 걸 확인했어요!\n홈 화면으로 이동 시, 프로필 사진을 설정할 수 있어요'
                        : '입력하신 정보에 따라 아래 프로필 중 선택해주세요\n프로필은 추후 변경이 불가능하니 신중하게 선택해주세요',
                    style: TextStyle(
                      color: const Color(0xFF8490A3),
                      fontSize: 12,
                      fontFamily: 'Pretendard-Light',
                      height: 1.50,
                      letterSpacing: -0.28,
                    ),
                  ),
                ],
              ),
            ),

            // 메인 컨텐츠 - 학생용
            if (isStudent)
              Positioned(
                left: 16,
                top: 350,
                right: 16,
                bottom: 100,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // 프로필 이미지
                      Container(
                        width: 160,
                        height: 90,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage(
                              "assets/icons/select_profile.png",
                            ),
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 학생 프로필 설명 박스
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        decoration: ShapeDecoration(
                          color: const Color(0xFFE4ECF8),
                          shape: RoundedRectangleBorder(
                            side: BorderSide(
                              width: 0.70,
                              color: const Color(0xFF3A88F4),
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '학생 프로필이란?',
                              style: TextStyle(
                                color: const Color(0xFF202020),
                                fontSize: 14,
                                fontFamily: 'Pretendard-Bold',
                                letterSpacing: -0.32,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '부모님에게 다양한 미션을 제시받고, 직접 챌린지와 목표에 참여하여 달성하고 보상금을 받을 수 있어요!',
                              style: TextStyle(
                                color: const Color(0xFF8490A3),
                                fontSize: 12,
                                fontFamily: 'Pretendard-Light',
                                height: 1.50,
                                letterSpacing: -0.24,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 확인 버튼
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 16,
                        ),
                        decoration: ShapeDecoration(
                          color: const Color(0xFF146AFF),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: GestureDetector(
                          onTap: () {
                            // 학생 프로필로 회원가입 진행
                            setState(() {
                              _selectedProfile = 'student';
                            });
                            _goToNextStep();
                          },
                          child: Text(
                            '리틀뱅크와 성장하러 가기',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontFamily: 'Pretendard-Light',
                              letterSpacing: -0.28,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // 메인 컨텐츠 - 부모/선생님용
            if (!isStudent)
              Positioned(
                left: 16,
                top: 280,
                right: 16,
                bottom: 100,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 부모 프로필 카드
                      _buildProfileCard(
                        'parent',
                        '부모님',
                        '자녀의 활동을 관리하고 지원할 수 있습니다',
                        Icons.family_restroom,
                      ),
                      const SizedBox(height: 16),
                      // 선생님 프로필 카드
                      _buildProfileCard(
                        'teacher',
                        '선생님',
                        '학생들을 관리하고 교육 자료를 제공할 수 있습니다',
                        Icons.assignment_ind,
                      ),
                      const SizedBox(height: 32),
                      // 다음 버튼
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 16,
                        ),
                        decoration: ShapeDecoration(
                          color:
                              _selectedProfile.isNotEmpty
                                  ? const Color(0xFF146AFF)
                                  : const Color(0xFFDCDCDC),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: GestureDetector(
                          onTap:
                              _selectedProfile.isNotEmpty
                                  ? _goToNextStep
                                  : null,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                '다음',
                                style: TextStyle(
                                  color:
                                      _selectedProfile.isNotEmpty
                                          ? Colors.white
                                          : const Color(0xFF8490A3),
                                  fontSize: 14,
                                  fontFamily: 'Pretendard-Medium',
                                  letterSpacing: -0.28,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 40), // 하단 여백 추가
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // 프로필 선택 카드 (부모/선생님용)
  Widget _buildProfileCard(
    String type,
    String title,
    String description,
    IconData icon,
  ) {
    final bool isSelected = _selectedProfile == type;

    return GestureDetector(
      onTap: () {
        _showProfileSelectionWarning(type);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE4ECF8) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                isSelected ? const Color(0xFF3A88F4) : const Color(0xFFEEEEEE),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color:
                    isSelected
                        ? const Color(0xFF3A88F4)
                        : const Color(0xFFF8F9FA),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey.shade600,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontFamily: 'Pretendard-Bold',
                      color:
                          isSelected
                              ? const Color(0xFF3A88F4)
                              : const Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: 'Pretendard-Light',
                      color:
                          isSelected
                              ? const Color(0xFF3A88F4)
                              : const Color(0xFF666666),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: const Color(0xFF3A88F4),
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  // 프로필 선택 전 경고 다이얼로그 표시 함수
  void _showProfileSelectionWarning(String type) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text(
              '프로필 선택 확인',
              style: TextStyle(fontSize: 18, fontFamily: 'Pretendard-Bold'),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '선택하신 프로필은 추후 변경이 불가능합니다.',
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'Pretendard-Medium',
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '선택하신 ${type == 'parent' ? '부모님' : '선생님'} 프로필로 서비스가 제공되며, 프로필 변경이 필요한 경우 고객센터로 문의해 주세요.',
                  style: const TextStyle(
                    fontSize: 14,
                    fontFamily: 'Pretendard-Light',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text(
                  '다시 선택하기',
                  style: TextStyle(fontFamily: 'Pretendard-Medium'),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    _selectedProfile = type;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3A88F4),
                  foregroundColor: Colors.white,
                ),
                child: const Text(
                  '확인 및 계속하기',
                  style: TextStyle(fontFamily: 'Pretendard-Medium'),
                ),
              ),
            ],
          ),
    );
  }
}
