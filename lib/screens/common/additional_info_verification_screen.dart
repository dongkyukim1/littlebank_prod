import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/sns_service.dart';
import '../../services/auth_service.dart';
import '../parent/parent_home_wrapper.dart';
import '../child/child_home_wrapper.dart';
import 'agreement_screen.dart';

class AdditionalInfoVerificationScreen extends StatefulWidget {
  final String email;
  final String password;

  const AdditionalInfoVerificationScreen({
    super.key,
    required this.email,
    required this.password,
  });

  @override
  State<AdditionalInfoVerificationScreen> createState() => _AdditionalInfoVerificationScreenState();
}

class _AdditionalInfoVerificationScreenState extends State<AdditionalInfoVerificationScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _birthdateController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _verificationCodeController = TextEditingController();

  String _selectedCarrier = '통신사';
  String? _birthdateError;

  bool _isCodeSent = false;
  Timer? _timer;
  int _remainingTime = 210; // 3분 30초
  bool _isTimerExpired = false;

  @override
  void dispose() {
    _nameController.dispose();
    _birthdateController.dispose();
    _phoneController.dispose();
    _verificationCodeController.dispose();
    _timer?.cancel();
    super.dispose();
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

    setState(() {
      _isCodeSent = true;
      _remainingTime = 210;
      _isTimerExpired = false;
    });

    _startTimer();

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('인증번호가 전송되었습니다')));
  }

  void _startTimer() {
    _timer?.cancel(); // 기존 타이머가 있으면 취소
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingTime > 0) {
          _remainingTime--;
        } else {
          _isTimerExpired = true;
          timer.cancel();
        }
      });
    });
  }

  // 통신사 선택 바텀시트
  void _showCarrierSelect() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            alignment: Alignment.center,
            child: const Text(
              '통신사 선택',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          ListTile(
            title: const Text('SKT', style: TextStyle(fontSize: 12)),
            onTap: () {
              setState(() {
                _selectedCarrier = 'SKT';
              });
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: const Text('KT', style: TextStyle(fontSize: 12)),
            onTap: () {
              setState(() {
                _selectedCarrier = 'KT';
              });
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: const Text('LG U+', style: TextStyle(fontSize: 12)),
            onTap: () {
              setState(() {
                _selectedCarrier = 'LG U+';
              });
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: const Text('알뜰폰', style: TextStyle(fontSize: 12)),
            onTap: () {
              setState(() {
                _selectedCarrier = '알뜰폰';
              });
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _saveAdditionalInfo() {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('이름을 입력해주세요')));
      return;
    }

    if (_birthdateController.text.length != 6) {
      setState(() {
        _birthdateError = '생년월일은 6자리로 입력해주세요';
      });
      return;
    }

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

    // 약관동의 화면으로 이동 (일반 회원가입과 동일한 플로우)
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AgreementScreen(
          userId: widget.email,
          jumin: _birthdateController.text,
          password: widget.password,
          name: _nameController.text,
          phone: _phoneController.text,
        ),
      ),
    );
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
                            '추가회원 정보입력',
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
                  '성장을 위한 고민은 끝\n회원가입을 진행할게요',
                  style: TextStyle(
                    color: const Color(0xFF202020),
                    fontSize: 22,
                    fontFamily: 'Pretendard-Bold',
                    height: 1.50,
                    letterSpacing: -0.88,
                  ),
                ),

                const SizedBox(height: 40),

                // 이름 입력 섹션
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '이름',
                      style: TextStyle(
                        color: const Color(0xFF666666),
                        fontSize: 10,
                        fontFamily: 'Pretendard-Light',
                        letterSpacing: -0.20,
                      ),
                    ),
                    const SizedBox(height: 12),

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
                            width: 1.40,
                            color: _nameController.text.isNotEmpty
                                ? const Color(0xFF5D9EFF)
                                : const Color(0xFFDADADA),
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _nameController,
                              decoration: InputDecoration(
                                hintText: '이름을 입력해 주세요',
                                hintStyle: TextStyle(
                                  color: const Color(0xFF999999),
                                  fontSize: 12,
                                  fontFamily: 'Pretendard-Light',
                                  letterSpacing: -0.24,
                                ),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                contentPadding: EdgeInsets.only(
                                  top: 16,
                                  bottom: 12,
                                ),
                              ),
                              style: TextStyle(
                                color: const Color(0xFF353535),
                                fontSize: 12,
                                fontFamily: 'Pretendard-Light',
                                letterSpacing: -0.28,
                              ),
                              onChanged: (value) {
                                setState(() {}); // 텍스트 변경시 테두리 색상 업데이트
                              },
                            ),
                          ),
                          if (_nameController.text.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _nameController.clear();
                                });
                              },
                              child: Icon(
                                Icons.cancel,
                                color: const Color(0xFFCCCCCC),
                                size: 20,
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    // 이름 안내 메시지
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 12,
                          color: const Color(0xFF8490A3),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '결과 리포트, 보호자 계정 연결을 위해 사용됩니다. 외부에는 노출되지 않아요.',
                            style: TextStyle(
                              color: const Color(0xFF8490A3),
                              fontSize: 9,
                              fontFamily: 'Pretendard-Light',
                              letterSpacing: -0.18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // 생년월일 입력 섹션
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '생년월일',
                      style: TextStyle(
                        color: const Color(0xFF666666),
                        fontSize: 10,
                        fontFamily: 'Pretendard-Light',
                        letterSpacing: -0.20,
                      ),
                    ),
                    const SizedBox(height: 12),

                    Row(
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
                                  width: 1.40,
                                  color: _birthdateController.text.isNotEmpty
                                      ? const Color(0xFF5D9EFF)
                                      : const Color(0xFFDADADA),
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: TextFormField(
                              controller: _birthdateController,
                              decoration: InputDecoration(
                                hintText: 'YYMMDD',
                                hintStyle: TextStyle(
                                  color: const Color(0xFF999999),
                                  fontSize: 12,
                                  fontFamily: 'Pretendard-Light',
                                  letterSpacing: -0.24,
                                ),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                contentPadding: EdgeInsets.only(
                                  top: 16,
                                  bottom: 12,
                                ),
                              ),
                              keyboardType: TextInputType.number,
                              maxLength: 6,
                              buildCounter: (
                                context, {
                                required currentLength,
                                required isFocused,
                                maxLength,
                              }) => null,
                              style: TextStyle(
                                color: const Color(0xFF353535),
                                fontSize: 12,
                                fontFamily: 'Pretendard-Light',
                                letterSpacing: -0.28,
                              ),
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              onChanged: (value) {
                                setState(() {
                                  _birthdateError =
                                      value.length != 6
                                          ? '생년월일은 6자리로 입력해주세요'
                                          : null;
                                });
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 20,
                          height: 2,
                          color: const Color(0xFFC4C4C4),
                        ),
                        const SizedBox(width: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(7, (index) {
                            return Container(
                              width: 16,
                              height: 16,
                              margin: EdgeInsets.symmetric(horizontal: 4),
                              decoration: ShapeDecoration(
                                color: const Color(0xFF5D6A7F),
                                shape: OvalBorder(),
                              ),
                            );
                          }),
                        ),
                      ],
                    ),

                    if (_birthdateError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          _birthdateError!,
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 9,
                            fontFamily: 'Pretendard-Light',
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 32),

                // 휴대폰 번호 입력 섹션
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '휴대폰 번호',
                      style: TextStyle(
                        color: const Color(0xFF666666),
                        fontSize: 10,
                        fontFamily: 'Pretendard-Light',
                        letterSpacing: -0.20,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // 통신사 선택
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
                            width: 1.40,
                            color: _selectedCarrier != '통신사'
                                ? const Color(0xFF5D9EFF)
                                : const Color(0xFFDADADA),
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _selectedCarrier == '통신사'
                                  ? '통신사를 선택해 주세요'
                                  : _selectedCarrier,
                              style: TextStyle(
                                color: _selectedCarrier == '통신사'
                                    ? const Color(0xFF999999)
                                    : const Color(0xFF353535),
                                fontSize: 12,
                                fontFamily: 'Pretendard-Light',
                                letterSpacing: -0.28,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _showCarrierSelect(),
                            child: Icon(
                              Icons.arrow_drop_down,
                              color: const Color(0xFF999999),
                              size: 16,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 전화번호 입력과 인증번호 전송 버튼
                    Row(
                      children: [
                        Expanded(
                          flex: 65,
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
                                  width: 1.40,
                                  color: _phoneController.text.isNotEmpty
                                      ? const Color(0xFF5D9EFF)
                                      : const Color(0xFFDADADA),
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: TextFormField(
                              controller: _phoneController,
                              decoration: InputDecoration(
                                hintText: '숫자만 입력해 주세요',
                                hintStyle: TextStyle(
                                  color: const Color(0xFF999999),
                                  fontSize: 10,
                                  fontFamily: 'Pretendard-Light',
                                  letterSpacing: -0.24,
                                ),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                              textAlignVertical: TextAlignVertical.center,
                              keyboardType: TextInputType.phone,
                              style: TextStyle(
                                color: const Color(0xFF353535),
                                fontSize: 12,
                                fontFamily: 'Pretendard-Light',
                                letterSpacing: -0.28,
                              ),
                              onChanged: (value) {
                                setState(() {}); // 텍스트 변경시 테두리 색상 업데이트
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 24),
                        Container(
                          width: 164,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _isCodeSent ? null : _sendVerificationCode,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isCodeSent
                                  ? const Color(0xFFDADADA)
                                  : (_nameController.text.isNotEmpty &&
                                      _birthdateController.text.isNotEmpty &&
                                      _phoneController.text.isNotEmpty &&
                                      _selectedCarrier != '통신사')
                                  ? const Color(0xFF3A88F4)
                                  : const Color(0xFFDADADA),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              _isCodeSent ? '전송완료' : '인증번호 전송',
                              style: TextStyle(
                                fontSize: 12,
                                fontFamily: 'Pretendard-Light',
                                letterSpacing: -0.28,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    if (_isCodeSent) ...[
                      const SizedBox(height: 16),

                      // 인증번호 입력과 확인 버튼
                      Row(
                        children: [
                          Expanded(
                            flex: 65,
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
                                    width: 1.40,
                                    color: _verificationCodeController.text.isNotEmpty
                                        ? const Color(0xFF5D9EFF)
                                        : const Color(0xFFDADADA),
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _verificationCodeController,
                                      decoration: InputDecoration(
                                        hintText: '인증번호 입력',
                                        hintStyle: TextStyle(
                                          color: const Color(0xFF999999),
                                          fontSize: 12,
                                          fontFamily: 'Pretendard-Light',
                                          letterSpacing: -0.24,
                                        ),
                                        border: InputBorder.none,
                                        enabledBorder: InputBorder.none,
                                        focusedBorder: InputBorder.none,
                                        contentPadding: EdgeInsets.only(
                                          top: 18,
                                          bottom: 10,
                                        ),
                                      ),
                                      keyboardType: TextInputType.number,
                                      style: TextStyle(
                                        color: const Color(0xFF353535),
                                        fontSize: 12,
                                        fontFamily: 'Pretendard-Light',
                                        letterSpacing: -0.28,
                                      ),
                                      onChanged: (value) {
                                        setState(() {}); // 텍스트 변경시 테두리 색상 업데이트
                                      },
                                    ),
                                  ),
                                  Text(
                                    _isTimerExpired
                                        ? '만료됨'
                                        : _formatTime(_remainingTime),
                                    style: TextStyle(
                                      color: _isTimerExpired
                                          ? const Color(0xFFFF4444)
                                          : const Color(0xFF3A88F4),
                                      fontSize: 12,
                                      fontFamily: 'Pretendard-Light',
                                      letterSpacing: -0.28,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 24),
                          Container(
                            width: 164,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: _isTimerExpired
                                  ? null
                                  : () {
                                    // 인증번호 확인 로직
                                    if (_verificationCodeController.text.length == 6) {
                                      // 인증 성공 처리
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text('인증이 완료되었습니다'),
                                        ),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text('올바른 인증번호를 입력해주세요'),
                                        ),
                                      );
                                    }
                                  },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _isTimerExpired
                                    ? const Color(0xFFDADADA)
                                    : const Color(0xFF5D9EFF),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                _isTimerExpired ? '시간 만료' : '인증번호 확인',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontFamily: 'Pretendard-Light',
                                  letterSpacing: -0.28,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // 인증 안내 메시지
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 12,
                            color: const Color(0xFF8490A3),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '인증 문자가 도착하지 않으면 메시지 설정에서 차단 번호를 확인해 주세요',
                              style: TextStyle(
                                color: const Color(0xFF8490A3),
                                fontSize: 9,
                                fontFamily: 'Pretendard-Light',
                                letterSpacing: -0.18,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 60),

                // 다음 버튼
                GestureDetector(
                  onTap: _saveAdditionalInfo,
                  child: Container(
                    width: 358,
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
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '다음',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontFamily: 'Pretendard-Medium',
                            letterSpacing: -0.24,
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