import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ParentAccountInputModal extends StatefulWidget {
  final String selectedBank;
  final Function() onPrevious;
  final Function(String accountNumber, String receiverName) onNext;

  const ParentAccountInputModal({
    super.key,
    required this.selectedBank,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  State<ParentAccountInputModal> createState() => _ParentAccountInputModalState();
}

class _ParentAccountInputModalState extends State<ParentAccountInputModal>
    with SingleTickerProviderStateMixin {
  String accountNumber = '';
  final TextEditingController _accountController = TextEditingController();
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
    _accountController.addListener(_onAccountChanged);
  }

  void _onAccountChanged() {
    if (_accountController.text != accountNumber) {
      setState(() {
        accountNumber = _accountController.text;
      });
    }
  }

  @override
  void dispose() {
    _accountController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _addDigit(String digit) {
    if (accountNumber.length < 20) {
      HapticFeedback.lightImpact();
      setState(() {
        accountNumber += digit;
        _accountController.text = accountNumber;
        _lastPressedKey = int.parse(digit);
      });

      _animationController.reset();
      _animationController.forward();
    }
  }

  void _deleteDigit() {
    if (accountNumber.isNotEmpty) {
      HapticFeedback.lightImpact();
      setState(() {
        accountNumber = accountNumber.substring(0, accountNumber.length - 1);
        _accountController.text = accountNumber;
      });
    }
  }

  // 계좌번호로 수취인 이름 조회 (실제로는 API 연동 필요)
  String _getReceiverNameFromAccount(String accountNumber) {
    // 실제 서비스에서는 API를 사용하여 계좌번호로 수취인 이름을 조회
    // 여기서는 예시로 가상의 수취인 이름을 반환
    return "김예금";
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
                                '포인트를 보낼 계좌번호를 입력해주세요',
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
                                accountNumber.isNotEmpty
                                    ? _animation.value
                                    : 1.0,
                            child: TextField(
                              controller: _accountController,
                              keyboardType: TextInputType.number,
                              showCursor: false,
                              readOnly: true,
                              decoration: InputDecoration(
                                hintText: '계좌번호를 입력해주세요',
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

                      // 계좌번호 입력 시 자동으로 수취인 이름이 표시됨을 안내
                      if (accountNumber.isNotEmpty)
                        Text(
                          '계좌번호 입력 시 수취인 정보가 자동으로 조회됩니다',
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
                        accountNumber.isEmpty
                            ? null
                            : () {
                              // 계좌번호가 입력되면 자동으로 수취인 이름을 API로 조회해서 전달 (여기서는 간단히 함수 호출)
                              String receiverName = _getReceiverNameFromAccount(
                                accountNumber,
                              );
                              widget.onNext(accountNumber, receiverName);
                            },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: ShapeDecoration(
                        color:
                            accountNumber.isEmpty
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