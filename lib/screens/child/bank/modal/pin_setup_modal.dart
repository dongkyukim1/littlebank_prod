import 'package:flutter/material.dart';
import '../../../../services/auth_service.dart';
import 'dart:math';

class PinSetupModal extends StatefulWidget {
  final Function(String) onPinSet;
  final VoidCallback? onCancel;

  const PinSetupModal({super.key, required this.onPinSet, this.onCancel});

  @override
  State<PinSetupModal> createState() => _PinSetupModalState();
}

class _PinSetupModalState extends State<PinSetupModal> {
  String _firstPin = '';
  String _confirmPin = '';
  bool _isConfirmStep = false;
  bool _isLoading = false;
  final int _pinLength = 6;
  List<String> _randomNumbers = [];

  @override
  void initState() {
    super.initState();
    _generateRandomNumbers();
  }

  void _generateRandomNumbers() {
    List<String> numbers = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    numbers.shuffle(Random());
    _randomNumbers = numbers;
  }

  void _onNumberPressed(String number) {
    if (_isConfirmStep) {
      if (_confirmPin.length < _pinLength) {
        setState(() {
          _confirmPin += number;
        });

        if (_confirmPin.length == _pinLength) {
          _checkPinMatch();
        }
      }
    } else {
      if (_firstPin.length < _pinLength) {
        setState(() {
          _firstPin += number;
        });

        if (_firstPin.length == _pinLength) {
          setState(() {
            _isConfirmStep = true;
          });
        }
      }
    }
  }

  void _onDeletePressed() {
    if (_isConfirmStep) {
      if (_confirmPin.isNotEmpty) {
        setState(() {
          _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
        });
      }
    } else {
      if (_firstPin.isNotEmpty) {
        setState(() {
          _firstPin = _firstPin.substring(0, _firstPin.length - 1);
        });
      }
    }
  }

  void _checkPinMatch() {
    if (_firstPin == _confirmPin) {
      _savePinToServer();
    } else {
      _showErrorAndReset('비밀번호가 일치하지 않습니다.\n다시 설정해주세요.');
    }
  }

  Future<void> _savePinToServer() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 현재 사용자 정보를 먼저 가져오기
      final currentUserInfo = await AuthService.getUserInfo();

      // 모든 사용자 정보 + PIN을 함께 업데이트
      await AuthService.updateUserInfo(
        // 기존 사용자 정보 모두 포함
        name: currentUserInfo['name'],
        email: currentUserInfo['email'],
        phone: currentUserInfo['phone'],
        rrn: currentUserInfo['rrn'],
        statusMessage: currentUserInfo['statusMessage'],
        profileImagePath: currentUserInfo['profileImagePath'],
        role: currentUserInfo['role'],
        authority: currentUserInfo['authority'],
        subscribe: currentUserInfo['subscribe'],
        bankName: currentUserInfo['bankName'],
        bankCode: currentUserInfo['bankCode'],
        bankAccount: currentUserInfo['bankAccount'],
        // PIN만 새로 설정
        accountPin: _firstPin,
      );

      // 성공 시 콜백 호출
      widget.onPinSet(_firstPin);

      if (mounted) {
        Navigator.pop(context);
        _showSuccessDialog();
      }
    } catch (e) {
      print('PIN 설정 오류: $e');
      _showErrorAndReset('결제 비밀번호 설정에 실패했습니다.\n다시 시도해주세요.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorAndReset(String message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('설정 실패'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _resetPin();
                },
                child: Text('확인'),
              ),
            ],
          ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('설정 완료'),
            content: Text('결제 비밀번호가 설정되었습니다.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('확인'),
              ),
            ],
          ),
    );
  }

  void _resetPin() {
    setState(() {
      _firstPin = '';
      _confirmPin = '';
      _isConfirmStep = false;
    });
  }

  Widget _buildPinDot(int index) {
    String currentPin = _isConfirmStep ? _confirmPin : _firstPin;
    bool isFilled = index < currentPin.length;
    return Container(
      width: 24,
      height: 24,
      decoration: ShapeDecoration(
        color: isFilled ? const Color(0xFF3A88F4) : const Color(0xFFDCDCDC),
        shape: OvalBorder(),
      ),
    );
  }

  Widget _buildNumberButton(String number) {
    return Expanded(
      child: GestureDetector(
        onTap: _isLoading ? null : () => _onNumberPressed(number),
        child: Container(
          height: 60,
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            number,
            style: TextStyle(
              color: _isLoading ? Colors.grey : Colors.white,
              fontSize: 24,
              fontFamily: 'Pretendard-Light',
              letterSpacing: -0.96,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 헤더
        Container(
          width: 390,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: ShapeDecoration(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              side: BorderSide(width: 1.20, color: const Color(0xFFF0F0F0)),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '결제 비밀번호 설정',
                    style: TextStyle(
                      color: const Color(0xFF202020),
                      fontSize: 18,
                      fontFamily: 'Pretendard-Bold',
                      letterSpacing: -0.72,
                    ),
                  ),
                  GestureDetector(
                    onTap: widget.onCancel ?? () => Navigator.pop(context),
                    child: Container(
                      width: 24,
                      height: 24,
                      child: Icon(Icons.close, size: 20, color: Colors.grey),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                _isConfirmStep ? '비밀번호를 다시 한 번 입력해주세요' : '6자리 숫자로 설정해주세요',
                style: TextStyle(
                  color: const Color(0xFF666666),
                  fontSize: 14,
                  fontFamily: 'Pretendard-Regular',
                  letterSpacing: -0.28,
                ),
              ),
            ],
          ),
        ),

        // PIN 입력 표시
        Container(
          width: 390,
          padding: const EdgeInsets.symmetric(vertical: 36),
          decoration: BoxDecoration(color: Colors.white),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _pinLength,
                  (index) => Padding(
                    padding: EdgeInsets.only(
                      right: index < _pinLength - 1 ? 24 : 0,
                    ),
                    child: _buildPinDot(index),
                  ),
                ),
              ),
              if (_isLoading) ...[
                SizedBox(height: 20),
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3A88F4)),
                ),
              ],
            ],
          ),
        ),

        // 숫자 키패드
        Container(
          width: 390,
          decoration: BoxDecoration(color: const Color(0xFF5D6A7F)),
          child: Column(
            children: [
              // 첫 번째 줄
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    _buildNumberButton(_randomNumbers[0]),
                    _buildNumberButton(_randomNumbers[1]),
                    _buildNumberButton(_randomNumbers[2]),
                    _buildNumberButton(_randomNumbers[3]),
                  ],
                ),
              ),
              // 두 번째 줄
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    _buildNumberButton(_randomNumbers[4]),
                    _buildNumberButton(_randomNumbers[5]),
                    _buildNumberButton(_randomNumbers[6]),
                    _buildNumberButton(_randomNumbers[7]),
                  ],
                ),
              ),
              // 세 번째 줄
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    _buildNumberButton(_randomNumbers[8]),
                    _buildNumberButton(_randomNumbers[9]),
                    // 삭제 버튼
                    Expanded(
                      child: GestureDetector(
                        onTap: _isLoading ? null : _onDeletePressed,
                        child: Container(
                          height: 60,
                          margin: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.backspace_outlined,
                            color: _isLoading ? Colors.grey : Colors.white,
                            size: 24,
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

        // 하단 안내 텍스트
        Container(
          width: 390,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          decoration: BoxDecoration(color: const Color(0xFF5D6A7F)),
          child: Text(
            '안전한 거래를 위해 결제 비밀번호를 설정해주세요.\n다른 사람이 알기 어려운 번호로 설정하시기 바랍니다.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontFamily: 'Pretendard-Light',
              letterSpacing: -0.24,
            ),
          ),
        ),
      ],
    );
  }
}
