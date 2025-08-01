import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';

class PinInputModal extends StatefulWidget {
  final String title;
  final Function(String) onPinEntered;
  final VoidCallback? onCancel;

  const PinInputModal({
    super.key,
    this.title = '비밀번호를 입력해 주세요',
    required this.onPinEntered,
    this.onCancel,
  });

  @override
  State<PinInputModal> createState() => _PinInputModalState();
}

class _PinInputModalState extends State<PinInputModal> {
  String _pin = '';
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
    if (_pin.length < _pinLength) {
      setState(() {
        _pin += number;
      });

      // 6자리가 모두 입력되면 자동으로 처리
      if (_pin.length == _pinLength) {
        widget.onPinEntered(_pin);
      }
    }
  }

  void _onDeletePressed() {
    if (_pin.isNotEmpty) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
      });
    }
  }

  void _onConfirmPressed() {
    if (_pin.length == _pinLength) {
      widget.onPinEntered(_pin);
    }
  }

  Widget _buildPinDot(int index) {
    bool isFilled = index < _pin.length;
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
        onTap: () => _onNumberPressed(number),
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
              color: Colors.white,
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
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          decoration: ShapeDecoration(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  widget.title,
                  style: TextStyle(
                    color: const Color(0xFF202020),
                    fontSize: 16,
                    fontFamily: 'Pretendard-Bold',
                    letterSpacing: -0.64,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: 8),
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
        ),

        // PIN 입력 표시
        Container(
          width: 390,
          padding: const EdgeInsets.symmetric(vertical: 36),
          decoration: BoxDecoration(color: Colors.white),
          child: Row(
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
                        onTap: _onDeletePressed,
                        child: Container(
                          height: 60,
                          margin: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: Image.asset(
                            'assets/icons/my/password_cancel.png',
                            width: 32,
                            height: 32,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    // 빈 공간 (정렬 맞추기 용)
                    Expanded(
                      child: Container(
                        height: 60,
                        margin: const EdgeInsets.all(4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // 하단 버튼
        Container(
          width: 390,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          decoration: BoxDecoration(color: const Color(0xFF5D6A7F)),
          child: Row(
            children: [
              // 삭제 버튼
              Expanded(
                child: GestureDetector(
                  onTap: _onDeletePressed,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: ShapeDecoration(
                      color: const Color(0xFFDCDCDC),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      '삭제',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: const Color(0xFFB6B6B6),
                        fontSize: 14,
                        fontFamily: 'Pretendard-Light',
                        letterSpacing: -0.28,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 24),
              // 확인 버튼
              Expanded(
                child: GestureDetector(
                  onTap: _pin.length == _pinLength ? _onConfirmPressed : null,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: ShapeDecoration(
                      color:
                          _pin.length == _pinLength
                              ? const Color(0xFF5D9EFF)
                              : const Color(0xFFDCDCDC),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      '확인',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color:
                            _pin.length == _pinLength
                                ? Colors.white
                                : const Color(0xFFB6B6B6),
                        fontSize: 14,
                        fontFamily: 'Pretendard-Light',
                        letterSpacing: -0.28,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
