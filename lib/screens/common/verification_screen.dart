import 'package:flutter/material.dart';
import 'agreement_screen.dart';

class VerificationScreen extends StatefulWidget {
  final String userId;
  final String password;

  const VerificationScreen({super.key, required this.userId, required this.password});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  // 사용자 입력 정보
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  // 통신사 관련 변수
  String _selectedCarrier = '통신사';

  // 인증번호 관련 변수
  final TextEditingController _verificationCodeController =
      TextEditingController();
  bool _isCodeSent = false;

  // 주민번호 컨트롤러
  final TextEditingController _frontIdController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _verificationCodeController.dispose();
    _frontIdController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // 이름 입력 컨트롤러에 리스너 추가
    _nameController.addListener(() {
      setState(() {}); // 텍스트 변경시 화면 갱신
    });
  }

  void _sendVerificationCode() {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('이름을 입력해주세요')));
      return;
    }

    if (_phoneController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('휴대폰 번호를 입력해주세요')));
      return;
    }

    if (_selectedCarrier == '통신사') {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('통신사를 선택해주세요')));
      return;
    }

    // 인증번호 전송 로직
    setState(() {
      _isCodeSent = true;
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('인증번호가 전송되었습니다')));
  }

  void _nextStep() {
    if (!_isCodeSent) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('인증번호를 먼저 발송해주세요')));
      return;
    }

    if (_verificationCodeController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('인증번호를 입력해주세요')));
      return;
    }

    // 주민번호 가져오기 (앞자리와 뒷자리 합치기)
    final frontId = _getFrontIdController().text;
    // 뒷자리는 보안상 마스킹 처리되므로 여기서는 "1234567" 등의 가상 값을 사용
    const backId = "1234567";
    final jumin = frontId + backId;

    // 다음 페이지로 이동 - 필요한 추가 정보 전달
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => AgreementScreen(
              userId: widget.userId,
              jumin: jumin, // 주민번호 전달
              password: widget.password, // 비밀번호 추가
              name: _nameController.text, // 이름 추가
              phone: _phoneController.text, // 전화번호 추가
            ),
      ),
    );
  }

  // 주민번호 앞자리 컨트롤러를 가져오는 함수
  TextEditingController _getFrontIdController() {
    return _frontIdController;
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

          // 중앙 영역 (점 + 프로그레스 바 + 점들)
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 🔵 현재 단계 점 (앞쪽)
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                ),

                // ▬▬ 프로그레스 바
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

                // ⚪ 남은 점들
                const SizedBox(width: 12),
                Row(
                  children: List.generate(2, (index) {
                    return Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        shape: BoxShape.circle,
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),

          // 우측 여백
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  // 통신사 선택 위젯
  Widget _buildCarrierDropdown() {
    return PopupMenuButton<String>(
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      itemBuilder:
          (BuildContext context) => [
            PopupMenuItem<String>(
              value: 'SKT',
              child: const Text(
                'SKT',
                style: TextStyle(fontSize: 14, color: Colors.black),
              ),
            ),
            PopupMenuItem<String>(
              value: 'KT',
              child: const Text(
                'KT',
                style: TextStyle(fontSize: 14, color: Colors.black),
              ),
            ),
            PopupMenuItem<String>(
              value: 'LG U+',
              child: const Text(
                'LG U+',
                style: TextStyle(fontSize: 14, color: Colors.black),
              ),
            ),
            PopupMenuItem<String>(
              value: '알뜰폰',
              child: const Text(
                '알뜰폰',
                style: TextStyle(fontSize: 14, color: Colors.black),
              ),
            ),
          ],
      onSelected: (String value) {
        setState(() {
          _selectedCarrier = value;
        });
      },
      child: TextField(
        enabled: false,
        decoration: InputDecoration(
          hintText: '통신사',
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
        controller: TextEditingController(
          text: _selectedCarrier == '통신사' ? '' : _selectedCarrier,
        ),
        style: TextStyle(
          color:
              _selectedCarrier == '통신사'
                  ? Colors.grey.shade600
                  : const Color(0xFF333333),
        ),
      ),
    );
  }

  // 휴대폰 번호 입력 부분 수정
  Widget _buildPhoneNumberSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          '휴대폰 번호',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 16,
            color: Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 16),

        // 통신사 선택과 전화번호 입력을 한 줄에 배치
        Row(
          children: [
            // 통신사 선택 (3.5)
            Expanded(
              flex: 35, // 3.5에 해당하는 비율
              child: _buildCarrierDropdown(),
            ),

            const SizedBox(width: 12), // 간격 추가
            // 전화번호 입력 (6.5)
            Expanded(
              flex: 65, // 6.5에 해당하는 비율
              child: TextField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  hintText: '숫자만 입력해 주세요',
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                    borderSide: BorderSide(color: Color(0xFFDDDDDD)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                    borderSide: BorderSide(color: Color(0xFFDDDDDD)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                    borderSide: BorderSide(color: Color(0xFF4F78FF)),
                  ),
                ),
                keyboardType: TextInputType.phone,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 이름 입력 부분 수정
  Widget _buildNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          '이름',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 16,
            color: Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _nameController,
          decoration: InputDecoration(
            hintText: '이름을 입력해 주세요',
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
            // 클리어 버튼 추가
            suffixIcon:
                _nameController.text.isNotEmpty
                    ? IconButton(
                      icon: const Icon(
                        Icons.cancel,
                        color: Color(0xFFCCCCCC),
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() {
                          _nameController.clear();
                        });
                      },
                    )
                    : null,
          ),
        ),
      ],
    );
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
                    '간단한 정보를 알려주세요',
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
                      // 이름 입력 필드를 새로운 위젯으로 교체
                      _buildNameField(),

                      const SizedBox(height: 32),

                      // 주민번호 입력
                      const Text(
                        '주민번호',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                          color: Color(0xFF333333),
                        ),
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _frontIdController,
                              decoration: const InputDecoration(
                                hintText: '주민번호 앞자리',
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
                              keyboardType: TextInputType.number,
                              maxLength: 6,
                              buildCounter:
                                  (
                                    context, {
                                    required currentLength,
                                    required isFocused,
                                    maxLength,
                                  }) => null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Container(
                            width: 100,
                            height: 56,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: const Color(0xFFDDDDDD),
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF999999),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF999999),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF999999),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF999999),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF999999),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF999999),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // 휴대폰 번호 섹션으로 교체
                      _buildPhoneNumberSection(),

                      const SizedBox(height: 16),

                      // 인증 문자 받기 버튼
                      ElevatedButton(
                        onPressed: _sendVerificationCode,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade300,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          '인증 문자 받기',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                      if (_isCodeSent) ...[
                        const SizedBox(height: 32),

                        // 인증번호 입력
                        const Text(
                          '인증번호',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                            color: Color(0xFF333333),
                          ),
                        ),
                        const SizedBox(height: 16),

                        TextField(
                          controller: _verificationCodeController,
                          decoration: const InputDecoration(
                            hintText: '인증번호 입력',
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(8),
                              ),
                              borderSide: BorderSide(color: Color(0xFFDDDDDD)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(8),
                              ),
                              borderSide: BorderSide(color: Color(0xFFDDDDDD)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(8),
                              ),
                              borderSide: BorderSide(color: Color(0xFF4F78FF)),
                            ),
                          ),
                          keyboardType: TextInputType.number,
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
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(24.0),
        child: ElevatedButton(
          onPressed: _nextStep,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4F78FF),
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
