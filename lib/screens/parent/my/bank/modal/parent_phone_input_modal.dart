import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ParentPhoneInputModal extends StatefulWidget {
  final String selectedBank;
  final Function() onPrevious;
  final Function(String phoneNumber) onNext;

  const ParentPhoneInputModal({
    super.key,
    required this.selectedBank,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  State<ParentPhoneInputModal> createState() => _ParentPhoneInputModalState();
}

class _ParentPhoneInputModalState extends State<ParentPhoneInputModal>
    with SingleTickerProviderStateMixin {
  String phoneNumber = '';
  final TextEditingController _phoneController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _animation;
  int? _lastPressedKey;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _animation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _phoneController.addListener(_onPhoneChanged);
  }

  void _onPhoneChanged() {
    if (_phoneController.text != phoneNumber) {
      setState(() {
        phoneNumber = _phoneController.text;
      });
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _addDigit(String digit) {
    if (phoneNumber.length < 13) {
      HapticFeedback.lightImpact();

      String newPhone = phoneNumber + digit;

      // 자동 하이픈 추가
      if (newPhone.length == 3 && !newPhone.contains('-')) {
        newPhone = '$newPhone-';
      } else if (newPhone.length == 7 && newPhone.split('-').length == 2) {
        // 10자리 번호: 010-123-4567 형식
        newPhone = '$newPhone-';
      } else if (newPhone.length == 8 && newPhone.split('-').length == 2) {
        // 11자리 번호: 010-1234-5678 형식
        newPhone = '$newPhone-';
      }

      setState(() {
        phoneNumber = newPhone;
        _phoneController.text = phoneNumber;
        _lastPressedKey = int.parse(digit);
      });

      _animationController.reset();
      _animationController.forward();
    }
  }

  void _deleteDigit() {
    if (phoneNumber.isNotEmpty) {
      HapticFeedback.lightImpact();
      setState(() {
        phoneNumber = phoneNumber.substring(0, phoneNumber.length - 1);
        _phoneController.text = phoneNumber;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: screenWidth,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 24,
                        child: Stack(
                          children: [
                            Positioned(
                              left: 0,
                              top: 1,
                              child: Text(
                                '포인트를 받을 사람의 전화번호를 입력해 주세요',
                                style: TextStyle(
                                  color: const Color(0xFF202020),
                                  fontSize: 16,
                                  fontFamily: 'Pretendard-Bold',
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ),
                            Positioned(
                              right: 0,
                              top: 0,
                              child: GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: Icon(
                                  Icons.close,
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
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(color: Colors.white),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: screenWidth,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(color: Colors.white),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: widget.onPrevious,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              widget.selectedBank,
                              style: TextStyle(
                                color: const Color(0xFF4A4A4A),
                                fontSize: 16,
                                fontFamily: 'Pretendard-Light',
                                letterSpacing: -0.5,
                              ),
                            ),
                            Icon(
                              Icons.keyboard_arrow_down,
                              color: const Color(0xFF8096BA),
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 8),
                      Container(height: 1, color: const Color(0xFFEEEEEE)),
                      SizedBox(height: 16),

                      AnimatedBuilder(
                        animation: _animationController,
                        builder: (context, child) {
                          return Transform.scale(
                            scale:
                                phoneNumber.isNotEmpty ? _animation.value : 1.0,
                            child: TextField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              showCursor: false,
                              readOnly: true,
                              decoration: InputDecoration(
                                hintText: '전화번호를 입력해 주세요 (10-11자리)',
                                hintStyle: TextStyle(
                                  color: const Color(0xFFCCCCCC),
                                  fontSize: 16,
                                  fontFamily: 'Pretendard-Light',
                                  letterSpacing: -0.5,
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                              ),
                              style: TextStyle(
                                color: const Color(0xFF202020),
                                fontSize: 16,
                                fontFamily: 'Pretendard-Light',
                                letterSpacing: -0.5,
                              ),
                            ),
                          );
                        },
                      ),

                      SizedBox(height: 8),

                      // 전화번호 입력 시 사용자 검색됨을 안내
                      if (phoneNumber.isNotEmpty)
                        Text(
                          '전화번호 입력 완료 시 사용자를 자동으로 검색합니다',
                          style: TextStyle(
                            color: const Color(0xFF8490A3),
                            fontSize: 12,
                            fontFamily: 'Pretendard-Light',
                            letterSpacing: -0.24,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: Container(
              width: screenWidth,
              decoration: BoxDecoration(color: Colors.white),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildNumberKey('1'),
                      _buildNumberKey('2'),
                      _buildNumberKey('3'),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildNumberKey('4'),
                      _buildNumberKey('5'),
                      _buildNumberKey('6'),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildNumberKey('7'),
                      _buildNumberKey('8'),
                      _buildNumberKey('9'),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(child: Container()),
                      _buildNumberKey('0'),
                      Expanded(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _deleteDigit,
                            borderRadius: BorderRadius.circular(25),
                            splashColor: const Color(0xFFE0E0E0),
                            highlightColor: const Color(0xFFEEEEEE),
                            child: Container(
                              height: 50,
                              alignment: Alignment.center,
                              child: Icon(
                                Icons.backspace_outlined,
                                color: const Color(0xFFCCCCCC),
                                size: 24,
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

          Container(
            width: screenWidth,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(color: Colors.white),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: widget.onPrevious,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: ShapeDecoration(
                        color: const Color(0xFFE1E1E1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '이전',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontFamily: 'Pretendard-Light',
                          letterSpacing: -0.28,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: GestureDetector(
                    onTap:
                        phoneNumber.isEmpty ||
                                (phoneNumber.length != 12 &&
                                    phoneNumber.length != 13)
                            ? null
                            : () {
                              widget.onNext(phoneNumber);
                            },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: ShapeDecoration(
                        color:
                            phoneNumber.isEmpty ||
                                    (phoneNumber.length != 12 &&
                                        phoneNumber.length != 13)
                                ? const Color(0xFFE1E1E1)
                                : const Color(0xFF5D9EFF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '다음',
                        style: TextStyle(
                          color: Colors.white,
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
      ),
    );
  }

  Widget _buildNumberKey(String digit) {
    final isPressed = _lastPressedKey == int.parse(digit);

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _addDigit(digit),
          borderRadius: BorderRadius.circular(25),
          splashColor: const Color(0xFFE0E0E0),
          highlightColor: const Color(0xFFEEEEEE),
          child: Container(
            height: 40,
            alignment: Alignment.center,
            child: Text(
              digit,
              textAlign: TextAlign.center,
              style: TextStyle(
                color:
                    isPressed
                        ? const Color(0xFF146AFF)
                        : const Color(0xFFCCCCCC),
                fontSize: 20,
                fontFamily: 'Pretendard-Light',
                letterSpacing: -0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
