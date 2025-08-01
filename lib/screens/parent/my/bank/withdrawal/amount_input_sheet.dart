import 'package:flutter/material.dart';
import 'confirm_send_bottom_sheet.dart';
import '../../../../../widgets/profile_image.dart';
import '../../../../../services/auth_service.dart';

class AmountInputSheet extends StatefulWidget {
  final String userName;
  final String phoneNumber;
  final String userProfileImage;
  final String availablePoints;
  final VoidCallback? onNext;
  final VoidCallback? onPrevious;
  // 출금 관련 정보 추가
  final String? selectedBank;
  final String? accountNumber;
  final int? receiverId; // 받을 사람의 userId 추가
  final bool isWithdrawal; // 출금 모드 여부

  const AmountInputSheet({
    Key? key,
    required this.userName,
    required this.phoneNumber,
    this.userProfileImage = '',
    this.availablePoints = '35,000원',
    this.onNext,
    this.onPrevious,
    this.selectedBank,
    this.accountNumber,
    this.receiverId,
    this.isWithdrawal = false,
  }) : super(key: key);

  @override
  State<AmountInputSheet> createState() => _AmountInputSheetState();
}

class _AmountInputSheetState extends State<AmountInputSheet> {
  String _inputAmount = '';
  final List<String> _quickAmounts = ['+5천원', '+1만원', '+3만원', '+5만원', '전액'];

  // 수수료 계산 함수
  int _getFee() {
    if (_inputAmount.isEmpty) return 0;
    int amountValue = int.parse(_inputAmount);
    return amountValue < 30000 ? 200 : 0;
  }

  // 실제 수령 금액 계산 함수
  int _getNetAmount() {
    if (_inputAmount.isEmpty) return 0;
    int amountValue = int.parse(_inputAmount);
    return amountValue - _getFee();
  }

  // 포인트 초과 여부 확인 함수
  bool _isAmountExceeded() {
    if (_inputAmount.isEmpty) return false;
    int amountValue = int.tryParse(_inputAmount) ?? 0;
    int availablePoints =
        int.tryParse(
          widget.availablePoints.replaceAll(RegExp(r'[^0-9]'), ''),
        ) ??
        35000;
    return amountValue > availablePoints;
  }

  void _onKeyPressed(String value) {
    setState(() {
      if (value == 'backspace') {
        if (_inputAmount.isNotEmpty) {
          _inputAmount = _inputAmount.substring(0, _inputAmount.length - 1);
        }
      } else {
        _inputAmount += value;
      }
    });
  }

  void _onQuickAmountPressed(String amount) {
    setState(() {
      switch (amount) {
        case '+5천원':
          _addAmount(5000);
          break;
        case '+1만원':
          _addAmount(10000);
          break;
        case '+3만원':
          _addAmount(30000);
          break;
        case '+5만원':
          _addAmount(50000);
          break;
        case '전액':
          _inputAmount = '35000'; // 임시로 전액을 35000원으로 설정
          break;
      }
    });
  }

  void _addAmount(int amount) {
    int currentAmount = int.tryParse(_inputAmount) ?? 0;
    _inputAmount = (currentAmount + amount).toString();
  }

  String get _formattedAmount {
    if (_inputAmount.isEmpty) return '';
    try {
      int amount = int.parse(_inputAmount);
      return '${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}원';
    } catch (e) {
      return _inputAmount;
    }
  }

  // 다음 단계로 이동 (확인 바텀시트 띄우기)
  void _goToConfirmStep() async {
    if (_inputAmount.isEmpty ||
        int.tryParse(_inputAmount) == null ||
        int.parse(_inputAmount) <= 0) {
      return;
    }

    // 현재 사용자 정보 가져오기
    String senderName = '출금자';
    try {
      final userInfo = await AuthService.getUserInfo();
      senderName = userInfo['name'] ?? '출금자';
    } catch (e) {
      print('사용자 정보 로드 실패: $e');
    }

    // 현재 바텀시트 닫기
    Navigator.pop(context);

    // 확인 바텀시트 띄우기
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => ConfirmSendBottomSheet(
            senderName: senderName,
            receiverName:
                widget.isWithdrawal
                    ? senderName
                    : widget.userName, // 출금일 때는 자기 자신
            receiverPhone:
                widget.isWithdrawal
                    ? ''
                    : widget.phoneNumber, // 출금일 때는 전화번호 표시 안함
            amount: _inputAmount.toString().replaceAllMapped(
              RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
              (Match m) => '${m[1]},',
            ),
            userProfileImage: widget.userProfileImage,
            selectedBank: widget.selectedBank,
            accountNumber: widget.accountNumber,
            receiverId:
                widget.isWithdrawal ? null : widget.receiverId, // 출금일 때는 null
            fee: _getFee(),
            netAmount: _getNetAmount(),
            isWithdrawal: widget.isWithdrawal, // 출금 모드 전달
            onConfirm: () {
              // 확인 버튼 눌렀을 때 로직
              Navigator.pop(context);
              // 출금 확인 로직
              print('${widget.isWithdrawal ? "출금" : "송금"} 확인됨: $_inputAmount원');
            },
            onClose: () {
              Navigator.pop(context);
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(24),
        topRight: Radius.circular(24),
      ),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(color: Colors.white),
        child: Column(
          children: [
            HeaderComponent(
              title:
                  widget.isWithdrawal
                      ? '출금할 포인트를 입력해 주세요'
                      : '보내고 싶은 포인트를 입력해 주세요',
              onClose: () => Navigator.pop(context),
            ),
            Expanded(
              child: Column(
                children: [
                  UserInfoComponent(
                    userName: widget.userName,
                    phoneNumber: widget.phoneNumber,
                    userProfileImage: widget.userProfileImage,
                    points: widget.availablePoints,
                    inputAmount:
                        _formattedAmount.isEmpty
                            ? (widget.isWithdrawal
                                ? '얼마를 보내시겠어요?'
                                : '얼마를 보내시겠어요?')
                            : _formattedAmount,
                    fee: _getFee(),
                    netAmount: _getNetAmount(),
                    hasAmount: _inputAmount.isNotEmpty,
                    isAmountExceeded: _isAmountExceeded(),
                    isWithdrawal: widget.isWithdrawal,
                  ),
                  SizedBox(height: 8),
                  QuickAmountButtonsComponent(
                    amounts: _quickAmounts,
                    onAmountPressed: _onQuickAmountPressed,
                  ),
                  Expanded(
                    child: NumericKeypadComponent(onKeyPressed: _onKeyPressed),
                  ),
                ],
              ),
            ),
            Transform.translate(
              offset: Offset(0, -8),
              child: ActionButtonsComponent(
                onNext:
                    _inputAmount.isNotEmpty &&
                            int.tryParse(_inputAmount) != null &&
                            int.parse(_inputAmount) > 0
                        ? _goToConfirmStep
                        : null,
                onPrevious: widget.onPrevious ?? () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HeaderComponent extends StatelessWidget {
  final String title;
  final VoidCallback onClose;

  const HeaderComponent({
    Key? key,
    this.title = '보내고 싶은 포인트를 입력해 주세요',
    required this.onClose,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: 40),
      decoration: const BoxDecoration(color: Colors.white),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontFamily: 'Pretendard-Bold',
                color: Color(0xFF202020),
                letterSpacing: -0.72,
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

class UserInfoComponent extends StatelessWidget {
  final String userName;
  final String phoneNumber;
  final String userProfileImage;
  final String points;
  final String inputAmount;
  final int fee;
  final int netAmount;
  final bool hasAmount;
  final bool isAmountExceeded;
  final bool isWithdrawal;

  const UserInfoComponent({
    Key? key,
    this.userName = '김리뱅',
    this.phoneNumber = '010-9999-8282',
    this.userProfileImage = '',
    this.points = '35,000원',
    this.inputAmount = '얼마를 보내시겠어요?',
    this.fee = 0,
    this.netAmount = 0,
    this.hasAmount = false,
    this.isAmountExceeded = false,
    this.isWithdrawal = false,
  }) : super(key: key);

  // 전화번호 포맷팅 함수 (하이픈 추가)
  String _formatPhoneNumber(String phone) {
    // 빈 문자열인 경우 빈 문자열 반환
    if (phone.isEmpty) return '';

    // 숫자만 추출
    String cleanedPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');

    if (cleanedPhone.length == 11) {
      // 010-1234-5678 형식
      return '${cleanedPhone.substring(0, 3)}-${cleanedPhone.substring(3, 7)}-${cleanedPhone.substring(7)}';
    } else if (cleanedPhone.length == 10) {
      // 02-1234-5678 또는 031-123-4567 형식
      if (cleanedPhone.startsWith('02')) {
        return '${cleanedPhone.substring(0, 2)}-${cleanedPhone.substring(2, 6)}-${cleanedPhone.substring(6)}';
      } else {
        return '${cleanedPhone.substring(0, 3)}-${cleanedPhone.substring(3, 6)}-${cleanedPhone.substring(6)}';
      }
    }

    // 포맷팅할 수 없는 경우 원본 반환
    return phone;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    ProfileImage(
                      imagePath:
                          userProfileImage.isNotEmpty ? userProfileImage : null,
                      size: 56,
                      borderRadius: 28,
                    ),
                    const SizedBox(height: 12),
                    Column(
                      children: [
                        Text(
                          userName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontFamily: 'Pretendard-Medium',
                            color: Color(0xFF4A4A4A),
                            letterSpacing: -0.28,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (phoneNumber.isNotEmpty)
                          Text(
                            _formatPhoneNumber(phoneNumber),
                            style: TextStyle(
                              fontSize: 12,
                              fontFamily: 'Pretendard-Light',
                              color: Colors.grey[600],
                              letterSpacing: -0.24,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFE7ECF6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      isWithdrawal ? '출금 가능한 포인트' : '보낼 수 있는 포인트',
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'Pretendard-Light',
                        color: Color(0xFF8590A3),
                        letterSpacing: -0.24,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      points,
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'Pretendard-Medium',
                        color: Color(0xFF001F55),
                        letterSpacing: -0.24,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text(
                      '수수료',
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'Pretendard-Light',
                        color: Color(0xFF8590A3),
                        letterSpacing: -0.24,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${fee}원',
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'Pretendard-Medium',
                        color: Color(0xFF001F55),
                        letterSpacing: -0.24,
                      ),
                    ),
                  ],
                ),
                if (hasAmount) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        isWithdrawal ? '실제 수령 금액' : '실제 수령 금액',
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'Pretendard-Medium',
                          color: Color(0xFF5D9EFF),
                          letterSpacing: -0.24,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${netAmount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}원',
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'Pretendard-Bold',
                          color: Color(0xFF5D9EFF),
                          letterSpacing: -0.24,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (inputAmount == '얼마를 보내시겠어요?' || inputAmount == '얼마를 출금하시겠어요?')
                Text(
                  inputAmount,
                  style: TextStyle(
                    fontSize: 18,
                    fontFamily: 'Pretendard-Light',
                    color: Color(0xFFD5D5D5),
                    letterSpacing: -0.72,
                  ),
                )
              else
                Row(
                  children: [
                    Text(
                      inputAmount.replaceAll('원', ''),
                      style: TextStyle(
                        fontSize: 18,
                        fontFamily: 'Pretendard-Bold',
                        color:
                            isAmountExceeded
                                ? Color.fromRGBO(255, 115, 115, 1.0)
                                : Color(0xFF202020),
                        letterSpacing: -0.72,
                      ),
                    ),
                    Text(
                      '원',
                      style: TextStyle(
                        fontSize: 18,
                        fontFamily: 'Pretendard-Light',
                        color: Color(0xFF202020),
                        letterSpacing: -0.72,
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                height: 0.8,
                color: hasAmount ? const Color(0xFF5D9EFF) : const Color(0xFFD5D5D5),
              ),
              if (isAmountExceeded) ...[
                const SizedBox(height: 8),
                Text(
                  '출금 계좌의 잔액이 부족합니다',
                  style: TextStyle(
                    color: const Color(0xFFB6B6B6),
                    fontSize: 10,
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w300,
                    letterSpacing: -0.24,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class QuickAmountButtonsComponent extends StatelessWidget {
  final List<String> amounts;
  final Function(String)? onAmountPressed;

  const QuickAmountButtonsComponent({
    Key? key,
    this.amounts = const ['+5천원', '+1만원', '+3만원', '+5만원', '전액'],
    this.onAmountPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children:
            amounts.asMap().entries.map((entry) {
              int index = entry.key;
              String amount = entry.value;
              return Row(
                children: [
                  _buildAmountButton(amount),
                  if (index < amounts.length - 1) SizedBox(width: 12),
                ],
              );
            }).toList(),
      ),
    );
  }

  Widget _buildAmountButton(String text) {
    return Material(
      color: const Color(0xFFF1F1F1),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: () => onAmountPressed?.call(text),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF4A4A4A),
              fontSize: 10,
              fontFamily: 'Pretendard-Light',
              letterSpacing: -0.24,
            ),
          ),
        ),
      ),
    );
  }
}

class NumericKeypadComponent extends StatelessWidget {
  final Function(String)? onKeyPressed;

  const NumericKeypadComponent({Key? key, this.onKeyPressed}) : super(key: key);

  Widget _buildKeypadButton(String text, {Widget? child}) {
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
                  color: Color(0xFFC4C4C4),
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
    return Container(
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
    );
  }
}
