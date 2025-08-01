import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../services/auth_service.dart';

class AccountInputBottomSheet extends StatefulWidget {
  final String selectedBank;
  final String selectedBankCode;
  final VoidCallback onPrevious;
  final Function(String accountNumber, String accountHolder) onNext;

  const AccountInputBottomSheet({
    Key? key,
    required this.selectedBank,
    required this.selectedBankCode,
    required this.onPrevious,
    required this.onNext,
  }) : super(key: key);

  @override
  State<AccountInputBottomSheet> createState() =>
      _AccountInputBottomSheetState();
}

class _AccountInputBottomSheetState extends State<AccountInputBottomSheet> {
  final TextEditingController _accountController = TextEditingController();
  final TextEditingController _holderController = TextEditingController();
  final FocusNode _accountFocusNode = FocusNode();
  final FocusNode _holderFocusNode = FocusNode();

  bool _isVerified = false;
  bool _isVerifying = false;
  String? _verificationMessage;

  @override
  void dispose() {
    _accountController.dispose();
    _holderController.dispose();
    _accountFocusNode.dispose();
    _holderFocusNode.dispose();
    super.dispose();
  }

  bool get _canProceed =>
      _accountController.text.isNotEmpty &&
      _holderController.text.isNotEmpty &&
      _isVerified;

  // 실제 계좌 인증 API 호출
  Future<void> _verifyAccount() async {
    if (_accountController.text.isEmpty || _holderController.text.isEmpty) {
      return;
    }

    setState(() {
      _isVerifying = true;
      _verificationMessage = null;
    });

    try {
      // AuthService의 계좌 검증 API 호출
      final result = await AuthService.verifyAccountHolder(
        bankCode: widget.selectedBankCode,
        bankNumber: _accountController.text.trim(),
        holderName: _holderController.text.trim(),
      );

      setState(() {
        _isVerifying = false;
        _isVerified = result['success'] == true;
        _verificationMessage = result['message'];
      });

      // 인증 실패 시 에러 메시지 표시
      if (!_isVerified && _verificationMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_verificationMessage!),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isVerifying = false;
        _isVerified = false;
        _verificationMessage = '계좌 인증 중 오류가 발생했습니다.';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('계좌 인증 중 오류가 발생했습니다: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      transform: Matrix4.translationValues(0, -keyboardHeight * 0.5, 0),
      child: Container(
        width: 390,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 헤더 영역
              Container(
                width: 390,
                padding: const EdgeInsets.all(16),
                decoration: ShapeDecoration(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '계좌번호를 입력해 주세요',
                      style: TextStyle(
                        color: const Color(0xFF353535),
                        fontSize: 16,
                        fontFamily: 'Pretendard-Bold',
                        letterSpacing: -0.28,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '선택하신 은행의 정보를 둘 다 입력해 주세요',
                      style: TextStyle(
                        color: const Color(0xFF999999),
                        fontSize: 12,
                        fontFamily: 'Pretendard-Light',
                        letterSpacing: -0.24,
                      ),
                    ),
                  ],
                ),
              ),
              // 입력 필드 영역
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(color: Colors.white),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 계좌번호 입력
                    Text(
                      '계좌번호',
                      style: TextStyle(
                        color: const Color(0xFFC4C4C4),
                        fontSize: 12,
                        fontFamily: 'Pretendard-Light',
                        letterSpacing: -0.24,
                      ),
                    ),
                    SizedBox(height: 8),
                    Container(
                      width: 358,
                      height: 48,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: ShapeDecoration(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          side: BorderSide(
                            width: 1.40,
                            color:
                                _accountFocusNode.hasFocus
                                    ? const Color(0xFF5D9EFF)
                                    : const Color(0xFFE8EDF7),
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _accountController,
                              focusNode: _accountFocusNode,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _isVerified = false;
                                  _verificationMessage = null;
                                });
                              },
                              decoration: InputDecoration(
                                hintText: '계좌번호를 입력하세요',
                                hintStyle: TextStyle(
                                  color: const Color(0xFF999999),
                                  fontSize: 12,
                                  fontFamily: 'Pretendard-Light',
                                  letterSpacing: -0.24,
                                ),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                                isDense: true,
                              ),
                              style: TextStyle(
                                color: const Color(0xFF353535),
                                fontSize: 14,
                                fontFamily: 'Pretendard-Light',
                                letterSpacing: -0.28,
                              ),
                            ),
                          ),
                          if (_accountController.text.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                _accountController.clear();
                                setState(() {
                                  _isVerified = false;
                                  _verificationMessage = null;
                                });
                              },
                              child: Container(
                                width: 24,
                                height: 24,
                                child: Icon(
                                  Icons.cancel,
                                  size: 20,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16),
                    // 예금주명 입력
                    Text(
                      '예금주명',
                      style: TextStyle(
                        color: const Color(0xFFC4C4C4),
                        fontSize: 12,
                        fontFamily: 'Pretendard-Light',
                        letterSpacing: -0.24,
                      ),
                    ),
                    SizedBox(height: 8),
                    Container(
                      width: 358,
                      height: 48,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: ShapeDecoration(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          side: BorderSide(
                            width: 1.40,
                            color:
                                _holderFocusNode.hasFocus
                                    ? const Color(0xFF5D9EFF)
                                    : const Color(0xFFE8EDF7),
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _holderController,
                              focusNode: _holderFocusNode,
                              onChanged: (value) {
                                setState(() {
                                  _isVerified = false;
                                  _verificationMessage = null;
                                });
                              },
                              decoration: InputDecoration(
                                hintText: '예금주명을 입력하세요',
                                hintStyle: TextStyle(
                                  color: const Color(0xFF999999),
                                  fontSize: 12,
                                  fontFamily: 'Pretendard-Light',
                                  letterSpacing: -0.24,
                                ),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                                isDense: true,
                              ),
                              style: TextStyle(
                                color: const Color(0xFF353535),
                                fontSize: 14,
                                fontFamily: 'Pretendard-Light',
                                letterSpacing: -0.28,
                              ),
                            ),
                          ),
                          if (_holderController.text.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                _holderController.clear();
                                setState(() {
                                  _isVerified = false;
                                  _verificationMessage = null;
                                });
                              },
                              child: Container(
                                width: 24,
                                height: 24,
                                child: Icon(
                                  Icons.cancel,
                                  size: 20,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // 버튼 영역
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                decoration: BoxDecoration(color: Colors.white),
                child: Column(
                  children: [
                    // 인증 버튼
                    Container(
                      width: 358,
                      height: 50,
                      child: ElevatedButton(
                        onPressed:
                            (_accountController.text.isNotEmpty &&
                                    _holderController.text.isNotEmpty &&
                                    !_isVerified &&
                                    !_isVerifying)
                                ? _verifyAccount
                                : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              _isVerified
                                  ? const Color(0xFFDCDCDC)
                                  : (_accountController.text.isNotEmpty &&
                                      _holderController.text.isNotEmpty)
                                  ? const Color(0xFF5D9EFF)
                                  : const Color(0xFFDCDCDC),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child:
                            _isVerifying
                                ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      '인증 중...',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontFamily: 'Pretendard-Medium',
                                        letterSpacing: -0.24,
                                      ),
                                    ),
                                  ],
                                )
                                : _isVerified
                                ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Image.asset(
                                      'assets/icons/check_blue.png',
                                      width: 20,
                                      height: 20,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      '인증이 완료되었어요!',
                                      style: TextStyle(
                                        color: const Color(0xFF8590A3),
                                        fontSize: 12,
                                        fontFamily: 'Pretendard-Medium',
                                        letterSpacing: -0.24,
                                      ),
                                    ),
                                  ],
                                )
                                : Text(
                                  '계좌 인증하기',
                                  style: TextStyle(
                                    color:
                                        (_accountController.text.isNotEmpty &&
                                                _holderController
                                                    .text
                                                    .isNotEmpty)
                                            ? Colors.white
                                            : const Color(0xFF8490A3),
                                    fontSize: 12,
                                    fontFamily: 'Pretendard-Medium',
                                    letterSpacing: -0.24,
                                  ),
                                ),
                      ),
                    ),
                    SizedBox(height: 12),
                    // 다음 버튼
                    Container(
                      width: 358,
                      height: 50,
                      child: ElevatedButton(
                        onPressed:
                            _canProceed
                                ? () {
                                  widget.onNext(
                                    _accountController.text,
                                    _holderController.text,
                                  );
                                }
                                : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              _canProceed
                                  ? const Color(0xFF146AFF)
                                  : const Color(0xFFDCDCDC),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          '다음',
                          style: TextStyle(
                            color:
                                _canProceed
                                    ? Colors.white
                                    : const Color(0xFF8490A3),
                            fontSize: 12,
                            fontFamily: 'Pretendard-Medium',
                            letterSpacing: -0.24,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
