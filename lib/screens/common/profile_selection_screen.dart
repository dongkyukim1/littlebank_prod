import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';

class ProfileSelectionScreen extends StatefulWidget {
  final String userId;
  final String jumin; // 주민번호
  final String? password;
  final String? name;
  final String? phone;
  final bool? marketingAgreed;

  const ProfileSelectionScreen({
    super.key,
    required this.userId,
    required this.jumin,
    this.password,
    this.name,
    this.phone,
    this.marketingAgreed,
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
      builder:
          (BuildContext dialogContext) => AlertDialog(
            title: const Text('프로필 선택 확인'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '선택하신 프로필로 계정이 생성됩니다.',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  '프로필은 추후 변경이 불가능하므로 신중하게 선택해주세요.',
                  style: TextStyle(fontSize: 14, color: Color(0xFF666666)),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFEEEEEE)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _selectedProfile == 'student'
                            ? Icons.school
                            : _selectedProfile == 'parent'
                            ? Icons.family_restroom
                            : Icons.assignment_ind,
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _selectedProfile == 'student'
                            ? '학생'
                            : _selectedProfile == 'parent'
                            ? '부모님'
                            : '선생님',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext); // 다이얼로그 닫기
                },
                child: const Text('다시 선택하기'),
              ),
              ElevatedButton(
                onPressed: () {
                  // 다이얼로그 닫고
                  Navigator.pop(dialogContext);

                  // 로딩 표시 (선택사항)
                  _showLoadingDialog();

                  // 회원가입 진행
                  _processSignup(role);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                ),
                child: const Text('확인'),
              ),
            ],
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

  // 회원가입 처리 로직을 별도 메서드로 분리
  Future<void> _processSignup(String role) async {
    // 회원가입 API 호출
    if (widget.password != null &&
        widget.name != null &&
        widget.phone != null) {
      try {
        _updateLoadingMessage('회원가입 요청 처리 중...');
        print(
          '회원가입 API 요청: 이메일=${widget.userId}, 이름=${widget.name}, 전화번호=${widget.phone}, 역할=$role',
        );

        // API 호출
        final result = await AuthService.signup(
          email: widget.userId,
          password: widget.password!,
          name: widget.name!,
          phone: widget.phone!,
          rrn: widget.jumin.substring(0, 6),
          bankName: "",
          bankAccount: "",
          bankCode: "",
          profileImageUrl: "", // 프로필 이미지는 로그인 후 설정
          role: role,
        );

        print('회원가입 성공: $result');

        if (!mounted) return;

        // 로딩 다이얼로그가 표시된 경우 닫기
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }

        // 회원가입 완료 다이얼로그 표시
        _showSignupSuccessDialog();
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
          print('201 응답은 성공입니다. 회원가입 완료 메시지 표시');

          // 회원가입 완료 다이얼로그 표시
          _showSignupSuccessDialog();
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
                      const Text(
                        '회원가입이 완료되었습니다.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${widget.userId} 계정으로 로그인해주세요.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        '로그인 후 프로필 사진을 등록할 수 있습니다.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue,
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

  // 단계 네비게이션 위젯
  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.only(top: 16.0, bottom: 16.0),
      child: Row(
        children: [
          // 뒤로가기 버튼
          Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 4.0),
            child: IconButton(
              icon: const Icon(
                Icons.chevron_left,
                color: Colors.grey,
                size: 32,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),

          // 중앙 영역 (프로그레스 바 + 점)
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 프로그레스 바
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.2,
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),

                // 점 3개
                const SizedBox(width: 12),
                Row(
                  children: List.generate(
                    3,
                    (index) => Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 우측 여백을 위한 빈 공간
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  // 프로필 선택 카드
  Widget _buildProfileCard(
    String type,
    String title,
    String description,
    IconData icon,
  ) {
    final bool isSelected = _selectedProfile == type;

    return InkWell(
      onTap: () {
        _showProfileSelectionWarning(type);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? AppTheme.primaryColor.withOpacity(0.1)
                  : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : const Color(0xFFEEEEEE),
            width: isSelected ? 2 : 1,
          ),
          boxShadow:
              isSelected
                  ? [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                  : null,
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color:
                    isSelected
                        ? AppTheme.primaryColor
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
                      fontWeight: FontWeight.bold,
                      color:
                          isSelected
                              ? AppTheme.primaryColor
                              : const Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color:
                          isSelected
                              ? AppTheme.primaryColor.withOpacity(0.8)
                              : const Color(0xFF666666),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: AppTheme.primaryColor, size: 24),
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
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '선택하신 프로필은 추후 변경이 불가능합니다.',
                  style: TextStyle(fontSize: 16, color: Color(0xFF333333)),
                ),
                const SizedBox(height: 16),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF666666),
                    ),
                    children: [
                      const TextSpan(text: '선택하신 '),
                      TextSpan(
                        text:
                            type == 'student'
                                ? '학생'
                                : (type == 'parent' ? '부모님' : '선생님'),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const TextSpan(
                        text: ' 프로필로 서비스가 제공되며, 프로필 변경이 필요한 경우 고객센터로 문의해 주세요.',
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // 다이얼로그 닫기
                },
                child: const Text(
                  '다시 선택하기',
                  style: TextStyle(color: Color(0xFF666666)),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // 다이얼로그 닫기
                  // 선택 확정 처리
                  setState(() {
                    _selectedProfile = type;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('확인 및 계속하기'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 주민번호 기반으로 학생 여부 확인
    final bool isStudent = _isStudent();

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          '프로필 선택',
          style: TextStyle(
            color: Color(0xFF333333),
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        automaticallyImplyLeading: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: _buildStepIndicator(),
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '프로필을 선택해주세요',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF333333),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        isStudent
                            ? '입력하신 정보에 따라 학생으로 확인되었습니다'
                            : '입력하신 정보에 따라 아래 프로필 중 선택해주세요',
                        style: const TextStyle(
                          fontSize: 15,
                          color: Color(0xFF666666),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // 학생인 경우 학생 프로필만 표시
                      if (isStudent)
                        _buildProfileCard(
                          'student',
                          '학생',
                          '학생 전용 서비스 및 혜택을 이용할 수 있습니다',
                          Icons.school,
                        )
                      // 학생이 아닌 경우 부모와 선생님 프로필 표시
                      else ...[
                        _buildProfileCard(
                          'parent',
                          '부모님',
                          '자녀의 활동을 관리하고 지원할 수 있습니다',
                          Icons.family_restroom,
                        ),
                        _buildProfileCard(
                          'teacher',
                          '선생님',
                          '학생들을 관리하고 교육 자료를 제공할 수 있습니다',
                          Icons.assignment_ind,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _selectedProfile.isNotEmpty ? _goToNextStep : null,
          style: ElevatedButton.styleFrom(
            backgroundColor:
                _selectedProfile.isNotEmpty
                    ? AppTheme.primaryColor
                    : Colors.grey.shade300,
            foregroundColor:
                _selectedProfile.isNotEmpty
                    ? Colors.white
                    : Colors.grey.shade700,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 0,
          ),
          child: const Text(
            '다음',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}
