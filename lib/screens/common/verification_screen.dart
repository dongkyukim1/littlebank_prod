import 'dart:async';
import 'package:flutter/material.dart';
import 'signup_screen.dart';
import '../../services/auth_service.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({
    super.key,
  });

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
  bool _isCodeVerified = false; // 인증번호 검증 완료 여부

  // 타이머 관련 변수
  Timer? _timer;
  int _remainingSeconds = 210; // 3분 30초 = 210초
  bool _isTimerExpired = false;

  // 로딩 상태 변수
  bool _isSendingCode = false;
  bool _isVerifyingCode = false;

  // 생년월일 컨트롤러
  final TextEditingController _frontIdController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _verificationCodeController.dispose();
    _frontIdController.dispose();
    _timer?.cancel(); // 타이머 정리
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // 모든 입력 컨트롤러에 리스너 추가
    _nameController.addListener(() {
      print('이름: "${_nameController.text}"');
      setState(() {}); // 텍스트 변경시 화면 갱신
    });
    _phoneController.addListener(() {
      print('전화번호: "${_phoneController.text}"');
      setState(() {}); // 텍스트 변경시 화면 갱신
    });
    _frontIdController.addListener(() {
      print('생년월일: "${_frontIdController.text}" (길이: ${_frontIdController.text.length})');
      setState(() {}); // 텍스트 변경시 화면 갱신
    });
    _verificationCodeController.addListener(() {
      setState(() {}); // 텍스트 변경시 화면 갱신
    });
  }

  // 전송 버튼 활성화 조건 확인 메서드
  bool get _canSendCode {
    final result = _nameController.text.isNotEmpty &&
        _frontIdController.text.length == 6 &&
        _phoneController.text.isNotEmpty &&
        _selectedCarrier != '통신사';
    
    print('전송 버튼 활성화 조건 체크:');
    print('- 이름: ${_nameController.text.isNotEmpty} ("${_nameController.text}")');
    print('- 생년월일: ${_frontIdController.text.length == 6} ("${_frontIdController.text}", 길이: ${_frontIdController.text.length})');
    print('- 전화번호: ${_phoneController.text.isNotEmpty} ("${_phoneController.text}")');
    print('- 통신사: ${_selectedCarrier != '통신사'} ("$_selectedCarrier")');
    print('- 최종 결과: $result');
    
    return result;
  }

  // SMS 인증번호 발송
  void _sendVerificationCode() async {
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

    // 생년월일 체크 추가
    if (_frontIdController.text.length != 6) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('생년월일 6자리를 입력해주세요')));
      return;
    }

    // 로딩 시작
    setState(() {
      _isSendingCode = true;
    });

    try {
      // 실제 SMS 인증번호 발송 API 호출
      final result = await AuthService.sendSmsVerificationCode(
        phoneNumber: _phoneController.text,
      );

      if (result['success'] == true) {
        // 인증번호 전송 성공
        setState(() {
          _isCodeSent = true;
          _remainingSeconds = 210; // 타이머 초기화
          _isTimerExpired = false;
          _isCodeVerified = false; // 재전송시 인증 상태 초기화
          _verificationCodeController.clear(); // 인증번호 입력 필드 초기화
        });

        _startTimer(); // 타이머 시작

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? '인증번호가 전송되었습니다')),
        );
      } else {
        // 인증번호 전송 실패
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'SMS 발송에 실패했습니다')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('SMS 발송 중 오류가 발생했습니다: $e')),
      );
    } finally {
      // 로딩 종료
      setState(() {
        _isSendingCode = false;
      });
    }
  }

  // SMS 인증번호 검증
  void _verifyCode() async {
    if (_verificationCodeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('인증번호를 입력해주세요')),
      );
      return;
    }

    if (_isTimerExpired) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('인증 시간이 만료되었습니다. 인증번호를 다시 요청해주세요')),
      );
      return;
    }

    // 로딩 시작
    setState(() {
      _isVerifyingCode = true;
    });

    try {
      // 실제 SMS 인증번호 검증 API 호출
      final result = await AuthService.verifySmsCode(
        phoneNumber: _phoneController.text,
        code: _verificationCodeController.text,
      );

      if (result['success'] == true) {
        // 인증 성공
        setState(() {
          _isCodeVerified = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? '인증이 완료되었습니다')),
        );

        // 타이머 정지
        _timer?.cancel();
      } else {
        // 인증 실패
        setState(() {
          _isCodeVerified = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? '인증번호가 일치하지 않습니다')),
        );
      }
    } catch (e) {
      setState(() {
        _isCodeVerified = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('인증 중 오류가 발생했습니다: $e')),
      );
    } finally {
      // 로딩 종료
      setState(() {
        _isVerifyingCode = false;
      });
    }
  }

  // 타이머 시작
  void _startTimer() {
    _timer?.cancel(); // 기존 타이머가 있으면 취소
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _isTimerExpired = true;
          timer.cancel();
        }
      });
    });
  }

  // 시간 포맷 (분:초)
  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
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

    // 인증번호 검증 완료 여부 확인
    if (!_isCodeVerified) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('인증번호 확인을 완료해주세요')));
      return;
    }

    // 생년월일 가져오기 (6자리만 사용)
    final frontId = _getFrontIdController().text;

    // 생년월일 유효성 검사
    if (frontId.length != 6) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('생년월일은 6자리를 입력해주세요.')));
      return;
    }

    // 다음 페이지로 이동 - SignupScreen으로 필요한 정보 전달
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => SignupScreen(
              name: _nameController.text, // 이름 전달
              phone: _phoneController.text, // 전화번호 전달
              jumin: frontId, // 6자리 생년월일 전달
            ),
      ),
    );
  }

  // 생년월일 컨트롤러를 가져오는 함수
  TextEditingController _getFrontIdController() {
    return _frontIdController;
  }

  // 통신사 선택 바텀시트
  void _showCarrierSelect() {
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
                alignment: Alignment.centerLeft,
                child: const Text(
                  '통신사 선택',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    fontFamily: 'Pretendard-Bold',
                  ),
                ),
              ),
              ListTile(
                title: const Text('SKT', style: TextStyle(fontSize: 12)),
                onTap: () {
                  setState(() {
                    _selectedCarrier = 'SKT';
                    print('통신사 선택: SKT');
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('KT', style: TextStyle(fontSize: 12)),
                onTap: () {
                  setState(() {
                    _selectedCarrier = 'KT';
                    print('통신사 선택: KT');
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('LG U+', style: TextStyle(fontSize: 12)),
                onTap: () {
                  setState(() {
                    _selectedCarrier = 'LG U+';
                    print('통신사 선택: LG U+');
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('알뜰폰', style: TextStyle(fontSize: 12)),
                onTap: () {
                  setState(() {
                    _selectedCarrier = '알뜰폰';
                    print('통신사 선택: 알뜰폰');
                  });
                  Navigator.pop(context);
                },
              ),
            ],
          ),
    );
  }

  // 단계 네비게이션 위젯
  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.only(top: 16.0, bottom: 16.0),
      child: Center(
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
            Container(width: 12, height: 2, color: const Color(0xFF3A88F4)),
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
            Container(width: 12, height: 2, color: const Color(0xFFE4ECF8)),
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
            Container(width: 12, height: 2, color: const Color(0xFFE4ECF8)),
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
            Container(width: 12, height: 2, color: const Color(0xFFE4ECF8)),
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
                            '회원정보 입력',
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
                        fontSize: 10, // 12 -> 10
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
                            color:
                                _nameController.text.isNotEmpty
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
                                  fontSize: 12, // 14 -> 12
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
                                fontSize: 12, // 14 -> 12
                                fontFamily: 'Pretendard-Light',
                                letterSpacing: -0.28,
                              ),
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
                              fontSize: 9, // 11 -> 9
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
                        fontSize: 10, // 12 -> 10
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
                                  color:
                                      _frontIdController.text.isNotEmpty
                                          ? const Color(0xFF5D9EFF)
                                          : const Color(0xFFDADADA),
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: TextFormField(
                              controller: _frontIdController,
                              decoration: InputDecoration(
                                hintText: 'YYMMDD',
                                hintStyle: TextStyle(
                                  color: const Color(0xFF999999),
                                  fontSize: 12, // 14 -> 12
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
                              buildCounter:
                                  (
                                    context, {
                                    required currentLength,
                                    required isFocused,
                                    maxLength,
                                  }) => null,
                              style: TextStyle(
                                color: const Color(0xFF353535),
                                fontSize: 12, // 14 -> 12
                                fontFamily: 'Pretendard-Light',
                                letterSpacing: -0.28,
                              ),
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
                        fontSize: 10, // 12 -> 10
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
                            color:
                                _selectedCarrier != '통신사'
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
                                color:
                                    _selectedCarrier == '통신사'
                                        ? const Color(0xFF999999)
                                        : const Color(0xFF353535),
                                fontSize: 12, // 14 -> 12
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
                                  color:
                                      _phoneController.text.isNotEmpty
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
                                fontSize: 12, // 14 -> 12
                                fontFamily: 'Pretendard-Light',
                                letterSpacing: -0.28,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 24),
                        Container(
                          width: 164,
                          height: 48,
                          child: ElevatedButton(
                            onPressed:
                                _isSendingCode
                                    ? null
                                    : _canSendCode
                                    ? _sendVerificationCode
                                    : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  _isSendingCode
                                      ? const Color(0xFFDADADA)
                                      : _canSendCode
                                      ? const Color(0xFF3A88F4)
                                      : const Color(0xFFDADADA),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: _isSendingCode
                                ? Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '전송중...',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontFamily: 'Pretendard-Light',
                                          letterSpacing: -0.28,
                                        ),
                                      ),
                                    ],
                                  )
                                : Text(
                                    _isCodeSent ? '재전송' : '인증번호 전송',
                                    style: TextStyle(
                                      fontSize: 12, // 14 -> 12
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
                                    color:
                                        _verificationCodeController
                                                .text
                                                .isNotEmpty
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
                                          fontSize: 12, // 14 -> 12
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
                                        fontSize: 12, // 14 -> 12
                                        fontFamily: 'Pretendard-Light',
                                        letterSpacing: -0.28,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    _isTimerExpired
                                        ? '만료됨'
                                        : _formatTime(_remainingSeconds),
                                    style: TextStyle(
                                      color:
                                          _isTimerExpired
                                              ? const Color(0xFFFF4444)
                                              : const Color(0xFF3A88F4),
                                      fontSize: 12, // 14 -> 12
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
                              onPressed:
                                  (_isTimerExpired || _isVerifyingCode || _isCodeVerified)
                                      ? null
                                      : _verifyCode,
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    _isCodeVerified
                                        ? const Color(0xFF4CAF50) // 초록색 (성공)
                                        : _isTimerExpired
                                        ? const Color(0xFFDADADA)
                                        : _isVerifyingCode
                                        ? const Color(0xFFDADADA)
                                        : const Color(0xFF5D9EFF),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: _isVerifyingCode
                                  ? Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '확인중...',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontFamily: 'Pretendard-Light',
                                            letterSpacing: -0.28,
                                          ),
                                        ),
                                      ],
                                    )
                                  : Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        if (_isCodeVerified)
                                          Icon(
                                            Icons.check,
                                            size: 16,
                                            color: Colors.white,
                                          ),
                                        if (_isCodeVerified) const SizedBox(width: 4),
                                        Text(
                                          _isCodeVerified
                                              ? '인증완료'
                                              : _isTimerExpired
                                              ? '시간 만료'
                                              : '인증번호 확인',
                                          style: TextStyle(
                                            fontSize: 12, // 14 -> 12
                                            fontFamily: 'Pretendard-Light',
                                            letterSpacing: -0.28,
                                          ),
                                        ),
                                      ],
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
                                fontSize: 9, // 11 -> 9
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
                  onTap: (_nameController.text.isNotEmpty &&
                          _frontIdController.text.length == 6 &&
                          _phoneController.text.isNotEmpty &&
                          _selectedCarrier != '통신사' &&
                          _isCodeVerified)
                      ? _nextStep
                      : null,
                  child: Container(
                    width: 358,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 16,
                    ),
                    decoration: ShapeDecoration(
                      color: (_nameController.text.isNotEmpty &&
                              _frontIdController.text.length == 6 &&
                              _phoneController.text.isNotEmpty &&
                              _selectedCarrier != '통신사' &&
                              _isCodeVerified)
                          ? const Color(0xFF146AFF)
                          : const Color(0xFFDADADA),
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
