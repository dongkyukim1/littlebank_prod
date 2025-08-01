import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../services/auth_service.dart';

class PinSetupBottomSheet extends StatefulWidget {
  final String selectedBank;
  final String selectedBankCode;
  final String accountNumber;
  final String accountHolder;
  final VoidCallback onPrevious;
  final VoidCallback onComplete;

  const PinSetupBottomSheet({
    Key? key,
    required this.selectedBank,
    required this.selectedBankCode,
    required this.accountNumber,
    required this.accountHolder,
    required this.onPrevious,
    required this.onComplete,
  }) : super(key: key);

  @override
  State<PinSetupBottomSheet> createState() => _PinSetupBottomSheetState();
}

class _PinSetupBottomSheetState extends State<PinSetupBottomSheet> {
  String _currentPin = '';
  String _confirmPin = '';
  bool _isConfirmMode = false;
  bool _isProcessing = false;

  void _addDigit(String digit) {
    if (!_isConfirmMode && _currentPin.length < 6) {
      HapticFeedback.lightImpact();
      setState(() {
        _currentPin += digit;
      });

      if (_currentPin.length == 6) {
        // 첫 번째 PIN 입력 완료, 확인 모드로 전환
        setState(() {
          _isConfirmMode = true;
        });
      }
    } else if (_isConfirmMode && _confirmPin.length < 6) {
      HapticFeedback.lightImpact();
      setState(() {
        _confirmPin += digit;
      });

      if (_confirmPin.length == 6) {
        _validateAndSetPin();
      }
    }
  }

  void _deleteDigit() {
    HapticFeedback.lightImpact();
    if (!_isConfirmMode && _currentPin.isNotEmpty) {
      setState(() {
        _currentPin = _currentPin.substring(0, _currentPin.length - 1);
      });
    } else if (_isConfirmMode && _confirmPin.isNotEmpty) {
      setState(() {
        _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
      });
    }
  }

  void _deleteAll() {
    HapticFeedback.lightImpact();
    if (!_isConfirmMode) {
      setState(() {
        _currentPin = '';
      });
    } else {
      setState(() {
        _confirmPin = '';
      });
    }
  }

  void _goBackToFirstPin() {
    setState(() {
      _isConfirmMode = false;
      _confirmPin = '';
    });
  }

  Future<void> _validateAndSetPin() async {
    if (_currentPin != _confirmPin) {
      // PIN이 일치하지 않음
      _showErrorDialog('비밀번호가 일치하지 않습니다', '다시 입력해 주세요');
      setState(() {
        _isConfirmMode = false;
        _currentPin = '';
        _confirmPin = '';
      });
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // 먼저 현재 사용자 정보를 가져오기
      final currentUserInfo = await AuthService.getUserInfo();

      // 계좌 변경 API 호출 (기존 사용자 정보 + 새로운 계좌 정보)
      final result = await AuthService.updateUserInfo(
        name: currentUserInfo['name'], // 기존 이름 정보 포함
        email: currentUserInfo['email'], // 기존 이메일 정보 포함
        bankName: widget.selectedBank,
        bankCode: widget.selectedBankCode,
        bankAccount: widget.accountNumber,
        accountPin: _currentPin,
      );

      // updateUserInfo가 성공하면 사용자 정보가 반환됨
      if (result != null) {
        widget.onComplete();
      } else {
        throw Exception('계좌 변경에 실패했습니다');
      }
    } catch (e) {
      print('계좌 변경 실패: $e');
      _showErrorDialog(
        '계좌 변경 실패',
        e.toString().replaceFirst('Exception: ', ''),
      );
      setState(() {
        _isConfirmMode = false;
        _currentPin = '';
        _confirmPin = '';
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontFamily: 'Pretendard-Bold',
              color: Colors.black,
            ),
          ),
          content: Text(
            message,
            style: const TextStyle(
              fontSize: 14,
              fontFamily: 'Pretendard-Light',
              color: Colors.black,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                '확인',
                style: TextStyle(
                  fontSize: 14,
                  fontFamily: 'Pretendard-Medium',
                  color: Color(0xFF146AFF),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 상단 텍스트 영역
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(
              top: 0,
              left: 16,
              right: 16,
              bottom: 16,
            ),
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
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 12),
                Text(
                  _isConfirmMode ? '비밀번호를 다시 입력해 주세요' : '결제 비밀번호 6자리를 설정해 주세요',
                  style: TextStyle(
                    color: const Color(0xFF353535),
                    fontSize: 16,
                    fontFamily: 'Pretendard-Bold',
                    letterSpacing: -0.32,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  _isConfirmMode
                      ? '설정한 비밀번호와 동일하게 입력해 주세요'
                      : '안전한 서비스 이용을 위해 결제 비밀번호를 설정해 주세요',
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
          // PIN 인디케이터 영역
          Container(
            width: 390,
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(color: Colors.white),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(6, (index) {
                final currentPinLength =
                    _isConfirmMode ? _confirmPin.length : _currentPin.length;
                return Container(
                  margin:
                      index < 5 ? EdgeInsets.only(right: 24) : EdgeInsets.zero,
                  width: 24,
                  height: 24,
                  decoration: ShapeDecoration(
                    color:
                        index < currentPinLength
                            ? const Color(0xFF5D9EFF)
                            : const Color(0xFFDCDCDC),
                    shape: OvalBorder(),
                  ),
                );
              }),
            ),
          ),
          // 숫자 키패드 영역
          Container(
            width: 390,
            decoration: BoxDecoration(color: Colors.white),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(color: const Color(0xFF5D6A7F)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildNumberButton('1'),
                      _buildNumberButton('3'),
                      _buildNumberButton('7'),
                      _buildNumberButton('6'),
                    ],
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(color: const Color(0xFF5D6A7F)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildNumberButton('0'),
                      _buildNumberButton('2'),
                      _buildNumberButton('4'),
                      _buildNumberButton('9'),
                    ],
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(color: const Color(0xFF5D6A7F)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildNumberButton('5'),
                      _buildNumberButton('8'),
                      _buildDeleteButton(),
                      SizedBox(width: 60),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // 하단 완료 버튼 영역
          Container(
            width: 390,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            decoration: BoxDecoration(color: const Color(0xFF5D6A7F)),
            child: Center(
              child: Container(
                width: 358,
                height: 49,
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 16,
                ),
                decoration: ShapeDecoration(
                  color: const Color(0xFFDCDCDC),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Center(
                  child:
                      _isProcessing
                          ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              color: const Color(0xFFB6B6B6),
                              strokeWidth: 2,
                            ),
                          )
                          : Text(
                            _isProcessing ? '설정 중...' : '선택 완료',
                            style: TextStyle(
                              color: const Color(0xFFB6B6B6),
                              fontSize: 10,
                              fontFamily: 'Pretendard-Medium',
                              letterSpacing: -0.20,
                            ),
                          ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberButton(String value) {
    return GestureDetector(
      onTap: () => _addDigit(value),
      child: Container(
        width: 60,
        height: 60,
        alignment: Alignment.center,
        child: Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontFamily: 'Pretendard-Light',
            letterSpacing: -0.88,
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteButton() {
    return GestureDetector(
      onTap: _deleteDigit,
      child: Container(
        width: 60,
        height: 60,
        alignment: Alignment.center,
        child: Image.asset('assets/icons/delete.png', width: 32, height: 32),
      ),
    );
  }
}
