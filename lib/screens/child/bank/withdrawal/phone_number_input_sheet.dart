import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../services/auth_service.dart';

class PhoneNumberInputSheet extends StatefulWidget {
  final Function(
    String phoneNumber,
    String userName,
    int userId,
    String? profileImage,
  )?
  onNext;
  final VoidCallback? onPrevious;

  const PhoneNumberInputSheet({Key? key, this.onNext, this.onPrevious})
    : super(key: key);

  @override
  State<PhoneNumberInputSheet> createState() => _PhoneNumberInputSheetState();
}

class _PhoneNumberInputSheetState extends State<PhoneNumberInputSheet> {
  final TextEditingController _phoneController = TextEditingController();
  String _inputText = '';
  int? _lastPressedKey;
  String? _foundUserName;
  String? _foundUserLastDigits;
  int? _foundUserId;
  String? _foundUserProfileImage;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(_onPhoneChanged);
  }

  void _onPhoneChanged() {
    if (_phoneController.text != _inputText) {
      setState(() {
        _inputText = _phoneController.text;
      });
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  // 사용자 검색 함수 (실제 API 호출)
  Future<void> _searchUser(String phoneNumber) async {
    setState(() {
      _isSearching = true;
      _foundUserName = null;
      _foundUserLastDigits = null;
      _foundUserId = null;
      _foundUserProfileImage = null;
    });

    try {
      // 실제 API 호출
      final result = await AuthService.searchUserByPhone(
        phone: phoneNumber.replaceAll('-', ''),
      );

      if (result != null &&
          result['success'] == true &&
          result['data'] != null) {
        // 전화번호에서 마지막 4자리 추출
        final cleanPhone = phoneNumber.replaceAll('-', '');
        final lastFourDigits =
            cleanPhone.length >= 4
                ? cleanPhone.substring(cleanPhone.length - 4)
                : cleanPhone;

        setState(() {
          _foundUserName = result['data']['name']; // API에서 받은 실제 사용자명
          _foundUserLastDigits = lastFourDigits;
          _foundUserId = result['data']['searchUserId']; // API에서 받은 사용자 ID

          // 프로필 이미지 처리 - 경로만 저장 (ProfileImage 위젯에서 내부 처리)
          final profileImagePath = result['data']['profileImagePath'];
          if (profileImagePath != null &&
              profileImagePath.toString().isNotEmpty) {
            _foundUserProfileImage = profileImagePath.toString();
          } else {
            _foundUserProfileImage = null;
          }

          _isSearching = false;
        });
      } else {
        // 사용자를 찾지 못한 경우
        setState(() {
          _isSearching = false;
          _foundUserName = null;
          _foundUserLastDigits = null;
          _foundUserId = null;
          _foundUserProfileImage = null;
        });
      }
    } catch (e) {
      setState(() {
        _isSearching = false;
        _foundUserName = null;
        _foundUserLastDigits = null;
        _foundUserId = null;
      });
      print('사용자 검색 실패: $e');
    }
  }

  void _onKeyPressed(String value) {
    if (value == 'backspace') {
      _deleteDigit();
    } else {
      _addDigit(value);
    }
  }

  void _addDigit(String digit) {
    if (_inputText.length < 13) {
      HapticFeedback.lightImpact();

      String newPhone = _inputText + digit;

      // 자동 하이픈 추가
      if (newPhone.length == 3 && !newPhone.contains('-')) {
        // 첫 번째 하이픈: 010-
        newPhone = '$newPhone-';
      } else if (newPhone.length == 8 && newPhone.split('-').length == 2) {
        // 두 번째 하이픈: 010-1234- 또는 010-123-
        newPhone = '$newPhone-';
      }

      setState(() {
        _inputText = newPhone;
        _phoneController.text = _inputText;
        _lastPressedKey = int.parse(digit);
      });

      // 전화번호 입력 완료 시 사용자 검색
      if (newPhone.length == 12 || newPhone.length == 13) {
        _searchUser(newPhone);
      }
    }
  }

  void _deleteDigit() {
    if (_inputText.isNotEmpty) {
      HapticFeedback.lightImpact();
      setState(() {
        _inputText = _inputText.substring(0, _inputText.length - 1);
        _phoneController.text = _inputText;

        // 전화번호가 완성되지 않으면 검색 결과 초기화
        if (_inputText.length < 12) {
          _foundUserName = null;
          _foundUserLastDigits = null;
          _foundUserId = null;
          _foundUserProfileImage = null;
          _isSearching = false;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 전화번호가 완성되었는지 확인
    bool isPhoneComplete = _inputText.length == 12 || _inputText.length == 13;

    // 말풍선이 표시될 때 (사용자 찾음, 검색 중, 사용자 못 찾음) 높이 조정
    double sheetHeight = MediaQuery.of(context).size.height * 0.48;
    if (isPhoneComplete &&
        (_foundUserName != null ||
            _isSearching ||
            (!_isSearching && _foundUserName == null))) {
      sheetHeight = MediaQuery.of(context).size.height * 0.52;
    }

    return Container(
      height: sheetHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          HeaderComponent(onClose: () => Navigator.pop(context)),
          InputFieldComponent(
            controller: _phoneController,
            inputText: _inputText,
            isSearching: _isSearching,
            foundUserName: _foundUserName,
            foundUserLastDigits: _foundUserLastDigits,
          ),
          Expanded(
            child: Transform.translate(
              offset: Offset(0, -12),
              child: KeypadComponent(
                onKeyPressed: _onKeyPressed,
                lastPressedKey: _lastPressedKey,
              ),
            ),
          ),
          Transform.translate(
            offset: Offset(0, -8),
            child: ActionButtonsComponent(
              onNext:
                  _inputText.isEmpty ||
                          (_inputText.length != 12 &&
                              _inputText.length != 13) ||
                          _foundUserName == null
                      ? null
                      : () {
                        // 실제 검색된 사용자 데이터 전달 (프로필 이미지 포함)
                        widget.onNext?.call(
                          _inputText,
                          _foundUserName!,
                          _foundUserId!,
                          _foundUserProfileImage,
                        );
                      },
              onPrevious: widget.onPrevious ?? () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}

class HeaderComponent extends StatelessWidget {
  final String title;
  final VoidCallback onClose;

  const HeaderComponent({
    Key? key,
    this.title = '받는 사람의 전화번호를 입력해 주세요',
    required this.onClose,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Flexible(
            child: Text(
              title,
              style: const TextStyle(
                fontFamily: 'Pretendard-Bold',
                fontSize: 16,
                letterSpacing: -0.72,
                color: Color(0xFF202020),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          GestureDetector(
            onTap: onClose,
            child: Icon(Icons.close, size: 20, color: Color(0xFF999999)),
          ),
        ],
      ),
    );
  }
}

class InputFieldComponent extends StatelessWidget {
  final TextEditingController? controller;
  final String inputText;
  final bool isSearching;
  final String? foundUserName;
  final String? foundUserLastDigits;

  const InputFieldComponent({
    Key? key,
    this.controller,
    required this.inputText,
    this.isSearching = false,
    this.foundUserName,
    this.foundUserLastDigits,
  }) : super(key: key);

  // 전화번호가 완성되었는지 확인
  bool get isPhoneComplete => inputText.length == 12 || inputText.length == 13;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, 4, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: controller,
            readOnly: true,
            showCursor: false,
            style: TextStyle(
              fontFamily: 'Pretendard-Bold',
              fontSize: 16,
              letterSpacing: -1.12,
              color: Color(0xFF202020),
            ),
            decoration: InputDecoration(
              hintText: '전화번호를 입력해 주세요',
              hintStyle: TextStyle(
                fontFamily: 'Pretendard-Light',
                fontSize: 14,
                letterSpacing: -0.72,
                color: Color(0xFFD5D5D5),
              ),
              border: UnderlineInputBorder(
                borderSide: BorderSide(
                  color:
                      foundUserName != null
                          ? Color(0xFF5D9EFF)
                          : Color(0xFFD5D5D5),
                  width: 0.8,
                ),
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color:
                      foundUserName != null
                          ? Color(0xFF5D9EFF)
                          : Color(0xFFD5D5D5),
                  width: 0.8,
                ),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color:
                      foundUserName != null
                          ? Color(0xFF5D9EFF)
                          : Color(0xFFD5D5D5),
                  width: 0.8,
                ),
              ),
              contentPadding: EdgeInsets.only(bottom: 4),
            ),
            keyboardType: TextInputType.phone,
          ),
          SizedBox(height: 12),
          // 전화번호 입력 완료 시 유저 정보 표시 (가운데 정렬, 말풍선 형태)
          if (isPhoneComplete)
            Center(
              child: Column(
                children: [
                  if (isSearching)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '사용자를 검색 중입니다...',
                        style: const TextStyle(
                          color: Color(0xFF666666),
                          fontSize: 11,
                          fontFamily: 'Pretendard-Light',
                          letterSpacing: -0.22,
                        ),
                      ),
                    )
                  else if (foundUserName != null && foundUserLastDigits != null)
                    Container(
                      constraints: BoxConstraints(minWidth: 180),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // 말풍선 꼬리 (위쪽)
                          Positioned(
                            top: -6,
                            left: 0,
                            right: 0,
                            child: Transform.translate(
                              offset: Offset(-35, 0), // 중앙에서 약간 왼쪽으로
                              child: Center(
                                child: CustomPaint(
                                  size: Size(12, 6),
                                  painter: _BubbleTailPainter(),
                                ),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF5D9EFF),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$foundUserName님 ($foundUserLastDigits)을 찾았습니다!',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontFamily: 'Pretendard-Light',
                                letterSpacing: -0.22,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEBEE),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '사용자를 찾을 수 없습니다',
                        style: const TextStyle(
                          color: Color(0xFFE57373),
                          fontSize: 11,
                          fontFamily: 'Pretendard-Light',
                          letterSpacing: -0.22,
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
}

// 말풍선 꼬리를 그리는 CustomPainter (위쪽을 향함)
class _BubbleTailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = const Color(0xFF5D9EFF)
          ..style = PaintingStyle.fill;

    final path =
        Path()
          ..moveTo(size.width / 2 - 6, size.height)
          ..lineTo(size.width / 2, 0)
          ..lineTo(size.width / 2 + 6, size.height)
          ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class KeypadComponent extends StatelessWidget {
  final Function(String)? onKeyPressed;
  final int? lastPressedKey;

  const KeypadComponent({Key? key, this.onKeyPressed, this.lastPressedKey})
    : super(key: key);

  Widget _buildKeypadButton(String text, {Widget? child}) {
    final isPressed = lastPressedKey == int.tryParse(text);

    return Expanded(
      child: Container(
        height: 44,
        margin: EdgeInsets.all(4.0),
        child: TextButton(
          onPressed: () => onKeyPressed?.call(text),
          child:
              child ??
              Text(
                text,
                style: TextStyle(
                  fontFamily: 'Pretendard-Light',
                  fontSize: 20,
                  color: isPressed ? Color(0xFF146AFF) : Color(0xFFC4C4C4),
                  letterSpacing: -1.12,
                ),
              ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Row(
            children: [
              _buildKeypadButton('1'),
              _buildKeypadButton('2'),
              _buildKeypadButton('3'),
            ],
          ),
          Row(
            children: [
              _buildKeypadButton('4'),
              _buildKeypadButton('5'),
              _buildKeypadButton('6'),
            ],
          ),
          Row(
            children: [
              _buildKeypadButton('7'),
              _buildKeypadButton('8'),
              _buildKeypadButton('9'),
            ],
          ),
          Row(
            children: [
              Spacer(),
              _buildKeypadButton('0'),
              _buildKeypadButton(
                'backspace',
                child: Container(
                  width: 44,
                  height: 44,
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: Image.asset(
                        'assets/icons/parent/bank/cancel.png',
                        color: Color(0xFFC4C4C4),
                        fit: BoxFit.fill,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ActionButtonsComponent extends StatelessWidget {
  final VoidCallback? onNext;
  final VoidCallback? onPrevious;

  const ActionButtonsComponent({Key? key, this.onNext, this.onPrevious})
    : super(key: key);

  Widget _buildButton({
    required String text,
    required Color backgroundColor,
    required Color textColor,
    VoidCallback? onPressed,
  }) {
    return Expanded(
      child: Container(
        height: 48,
        margin: EdgeInsets.symmetric(horizontal: 4),
        child: TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            backgroundColor: backgroundColor,
            padding: EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            text,
            style: TextStyle(
              fontFamily: 'Pretendard-Light',
              fontSize: 12,
              letterSpacing: -0.28,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(0, -8),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            _buildButton(
              text: '이전',
              backgroundColor: Color(0xFFDCDCDC),
              textColor: Color(0xFFB6B6B6),
              onPressed: onPrevious,
            ),
            SizedBox(width: 8),
            _buildButton(
              text: '다음',
              backgroundColor:
                  onNext != null ? Color(0xFF5D9EFF) : Color(0xFFDCDCDC),
              textColor: onNext != null ? Colors.white : Color(0xFFB6B6B6),
              onPressed: onNext,
            ),
          ],
        ),
      ),
    );
  }
}
