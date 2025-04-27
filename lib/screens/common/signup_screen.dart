import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'verification_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

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
  final bool _isAutoLogin = false;
  final bool _isSaveId = false;

  // 선택된 도메인
  String _selectedDomain = '';

  @override
  void dispose() {
    _idController.dispose();
    _passwordController.dispose();
    _domainController.dispose();
    _passwordConfirmController.dispose();
    super.dispose();
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
                padding: const EdgeInsets.all(16),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                child: const Text(
                  '도메인 선택',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              ListTile(
                title: const Text('선택'),
                onTap: () {
                  setState(() {
                    _selectedDomain = '';
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('gmail.com'),
                onTap: () {
                  setState(() {
                    _selectedDomain = 'gmail.com';
                    _domainController.text = _selectedDomain;
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

    // 다음 페이지로 이동
    final String userId = "${_idController.text}@${_domainController.text}";
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VerificationScreen(
          userId: userId,
          password: _passwordController.text, // 비밀번호 전달
        ),
      ),
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
                    height: 8,
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
          const SizedBox(width: 48), // 이전 버튼과 동일한 크기의 여백
        ],
      ),
    );
  }

  // 도메인 선택 위젯
  Widget _buildDomainDropdown() {
    return PopupMenuButton<String>(
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      itemBuilder:
          (BuildContext context) => [
            PopupMenuItem<String>(
              value: 'gmail.com',
              child: const Text(
                'gmail.com',
                style: TextStyle(fontSize: 14, color: Colors.black),
              ),
            ),
            PopupMenuItem<String>(
              value: 'naver.com',
              child: const Text(
                'naver.com',
                style: TextStyle(fontSize: 14, color: Colors.black),
              ),
            ),
            PopupMenuItem<String>(
              value: 'daum.net',
              child: const Text(
                'daum.net',
                style: TextStyle(fontSize: 14, color: Colors.black),
              ),
            ),
          ],
      onSelected: (String value) {
        setState(() {
          _selectedDomain = value;
          _domainController.text = value;
        });
      },
      child: TextField(
        controller: _domainController,
        enabled: false,
        style: TextStyle(
          color:
              _domainController.text.isEmpty
                  ? Colors
                      .grey
                      .shade600 // 선택 전 힌트 텍스트 색상
                  : const Color(0xFF333333), // 선택 후 텍스트 색상 (타이틀보다 덜 진한 검정)
        ),
        decoration: InputDecoration(
          hintText: '선택',
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
          ),
          suffixIcon: Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
        ),
      ),
    );
  }

  // 비밀번호 유효성 체크
  bool get _isPasswordValid => _passwordController.text.length >= 8;

  // 모든 필드가 채워졌는지 확인하는 getter 추가
  bool get _isFormValid {
    return _idController.text.isNotEmpty &&
        _domainController.text.isNotEmpty &&
        _passwordController.text.length >= 8 &&
        _passwordConfirmController.text == _passwordController.text;
  }

  // 비밀번호 입력 필드 변경 감지
  @override
  void initState() {
    super.initState();
    _passwordController.addListener(() {
      setState(() {}); // 비밀번호 변경 시 화면 갱신
    });
    // 각 컨트롤러에 리스너 추가
    _idController.addListener(_updateState);
    _passwordController.addListener(_updateState);
    _domainController.addListener(_updateState);
    _passwordConfirmController.addListener(_updateState);
  }

  void _updateState() {
    setState(() {}); // 입력값 변경시 화면 갱신
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: null,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            _buildStepIndicator(),

            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 타이틀
                  const Text(
                    '오늘도 리틀뱅크와 함께\n전화걸도 한 걸음부터',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 이메일 입력
                      const Text(
                        '이메일',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                          color: Color(0xFF333333),
                        ),
                      ),
                      const SizedBox(height: 16),

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 5,
                            child: TextField(
                              controller: _idController,
                              decoration: const InputDecoration(
                                hintText: '이메일',
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(8),
                                  ),
                                  borderSide: BorderSide(
                                    color: Color(0xFFDDDDDD),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(8),
                                  ),
                                  borderSide: BorderSide(
                                    color: Color(0xFFDDDDDD),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(8),
                                  ),
                                  borderSide: BorderSide(
                                    color: Color(0xFF4F78FF),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.only(top: 16),
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            child: const Text(
                              '@',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                          Expanded(flex: 5, child: _buildDomainDropdown()),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // 비밀번호 입력
                      const Text(
                        '비밀번호',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                          color: Color(0xFF333333),
                        ),
                      ),
                      const SizedBox(height: 16),

                      TextField(
                        controller: _passwordController,
                        obscureText: !_isPasswordVisible,
                        decoration: InputDecoration(
                          hintText: '비밀번호를 입력해주세요',
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          border: const OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(8)),
                            borderSide: BorderSide(color: Color(0xFFDDDDDD)),
                          ),
                          enabledBorder: const OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(8)),
                            borderSide: BorderSide(color: Color(0xFFDDDDDD)),
                          ),
                          focusedBorder: const OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(8)),
                            borderSide: BorderSide(color: Color(0xFF4F78FF)),
                          ),
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
                      ),

                      const SizedBox(height: 16),

                      // 비밀번호 요구사항
                      Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            // 비밀번호가 8자 이상이면 앱 테마 색상, 아니면 회색
                            color:
                                _isPasswordValid
                                    ? AppTheme.primaryColor
                                    : Colors.grey.shade400,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            '8자 이상으로 입력해주세요',
                            style: TextStyle(
                              color: Color(0xFF666666),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // 비밀번호 확인
                      const Text(
                        '비밀번호 확인',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                          color: Color(0xFF333333),
                        ),
                      ),
                      const SizedBox(height: 16),

                      TextField(
                        controller: _passwordConfirmController,
                        obscureText: !_isPasswordVisible,
                        decoration: InputDecoration(
                          hintText: '비밀번호를 한 번 더 입력해주세요',
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          border: const OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(8)),
                            borderSide: BorderSide(color: Color(0xFFDDDDDD)),
                          ),
                          enabledBorder: const OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(8)),
                            borderSide: BorderSide(color: Color(0xFFDDDDDD)),
                          ),
                          focusedBorder: const OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(8)),
                            borderSide: BorderSide(color: Color(0xFF4F78FF)),
                          ),
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
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(24.0),
        child: ElevatedButton(
          onPressed: _nextStep,
          style: ElevatedButton.styleFrom(
            backgroundColor:
                _isFormValid
                    ? const Color(0xFF4F78FF) // 모든 값이 입력되었을 때 하늘색
                    : Colors.grey.shade400, // 입력값이 부족할 때 회색
            foregroundColor: Colors.white,
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
