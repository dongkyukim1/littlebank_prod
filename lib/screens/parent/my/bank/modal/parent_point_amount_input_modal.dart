import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'parent_point_confirm_send_modal.dart';

class ParentPointAmountInputModal extends StatefulWidget {
  final String selectedBank;
  final String phoneNumber;
  final String receiverName;
  final int availablePoints;
  final int? receiverId;
  final Function() onPrevious;

  const ParentPointAmountInputModal({
    super.key,
    required this.selectedBank,
    required this.phoneNumber,
    required this.receiverName,
    required this.availablePoints,
    this.receiverId,
    required this.onPrevious,
  });

  @override
  State<ParentPointAmountInputModal> createState() => _ParentPointAmountInputModalState();
}

class _ParentPointAmountInputModalState extends State<ParentPointAmountInputModal>
    with SingleTickerProviderStateMixin {
  String amount = '';
  final TextEditingController _textController = TextEditingController();
  int? _lastPressedKey;
  bool _isAmountExceeded = false; // 금액 초과 여부 상태

  @override
  void initState() {
    super.initState();
    _textController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    if (_textController.text != amount) {
      setState(() {
        amount = _textController.text;
        // 금액 변경 시 초과 여부 확인 리셋
        if (_isAmountExceeded) {
          _isAmountExceeded = false;
        }
      });
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _addDigit(String digit) {
    if (amount.length < 10) {
      // 금액 최대 길이 제한
      HapticFeedback.lightImpact(); // 햅틱 피드백
      setState(() {
        amount += digit;
        _textController.text = amount;
        _lastPressedKey = int.parse(digit);
        // 금액 추가 시 초과 여부 확인 리셋
        if (_isAmountExceeded) {
          _isAmountExceeded = false;
        }
      });
    }
  }

  void _deleteDigit() {
    if (amount.isNotEmpty) {
      HapticFeedback.lightImpact(); // 햅틱 피드백
      setState(() {
        amount = amount.substring(0, amount.length - 1);
        _textController.text = amount;
      });
    }
  }

  void _clearAmount() {
    setState(() {
      amount = '';
      _textController.text = '';
    });
  }

  void _addAmount(int value) {
    int currentAmount = amount.isEmpty ? 0 : int.parse(amount);
    currentAmount += value;

    if (currentAmount <= widget.availablePoints) {
      setState(() {
        amount = currentAmount.toString();
        _textController.text = amount;
      });
    }
  }

  void _setMaxAmount() {
    setState(() {
      amount = widget.availablePoints.toString();
      _textController.text = amount;
    });
  }

  // 금액 포맷 함수
  String _formatCurrency(String amount) {
    if (amount.isEmpty) return '0';
    final value = int.parse(amount);
    return value.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]},',
    );
  }

  // 확인 모달로 이동하는 함수
  void _navigateToConfirmModal() {
    if (amount.isEmpty) return;

    // 금액 초과 여부 확인
    int amountValue = int.parse(amount);
    if (amountValue > widget.availablePoints) {
      HapticFeedback.heavyImpact(); // 강한 햅틱 피드백
      setState(() {
        _isAmountExceeded = true;
      });
      return; // 금액 초과 시 다음 단계로 이동하지 않음
    }

    // 현재 모달 닫기
    Navigator.pop(context);

    // 확인 모달 열기
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => ParentPointConfirmSendModal(
            selectedBank: widget.selectedBank,
            phoneNumber: widget.phoneNumber,
            receiverName: widget.receiverName,
            receiverId: widget.receiverId,
            senderName: '김부모', // 실제로는 사용자 정보에서 가져와야 함
            amount: _formatCurrency(amount), // 입력된 금액을 포맷팅하여 전달
            onPrevious: () {
              // 확인 모달 닫기
              Navigator.pop(context);

              // 다시 금액 입력 모달 열기
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder:
                    (context) => ParentPointAmountInputModal(
                      selectedBank: widget.selectedBank,
                      phoneNumber: widget.phoneNumber,
                      receiverName: widget.receiverName,
                      availablePoints: widget.availablePoints,
                      receiverId: widget.receiverId,
                      onPrevious: widget.onPrevious,
                    ),
              );
            },
            onConfirm: () {
              // 포인트 전송 완료 처리
              Navigator.pop(context);
              // 추가적인 포인트 전송 완료 로직 구현
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 화면 크기 가져오기
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      height: MediaQuery.of(context).size.height * 0.65, // 높이를 더 줄임
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
          // 상단 타이틀
          Container(
            width: screenWidth,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
                Text(
                  '보내고 싶은 포인트를 입력해 주세요',
                  style: TextStyle(
                    color: const Color(0xFF202020),
                    fontSize: 15,
                    fontFamily: 'Pretendard-Bold',
                    letterSpacing: -0.5,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(Icons.close, size: 18, color: Colors.grey),
                ),
              ],
            ),
          ),

          SizedBox(height: 6), // 세로 간격 추가
          // 수신자 정보
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 35,
                  height: 35,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        spreadRadius: 1,
                        blurRadius: 2,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Container(
                      color: Colors.grey[300],
                      child: Icon(
                        Icons.person,
                        color: Colors.grey[600],
                        size: 20,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.receiverName,
                      style: TextStyle(
                        color: const Color(0xFF4A4A4A),
                        fontSize: 13,
                        fontFamily: 'Pretendard-Medium',
                        letterSpacing: -0.28,
                      ),
                    ),
                    Text(
                      widget.phoneNumber,
                      style: TextStyle(
                        color: const Color(0xFF999999),
                        fontSize: 11,
                        fontFamily: 'Pretendard-Light',
                        letterSpacing: -0.24,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(height: 8), // 세로 간격 추가
          // 포인트 정보
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF2F6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, // 전체 왼쪽 정렬
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start, // 왼쪽 정렬로 변경
                    children: [
                      Text(
                        '보낼 수 있는 포인트',
                        style: TextStyle(
                          color: const Color(0xFF8490A3),
                          fontSize: 11,
                          fontFamily: 'Pretendard-Light',
                          letterSpacing: -0.24,
                        ),
                      ),
                      SizedBox(width: 8), // 간격 추가
                      Text(
                        '${_formatCurrency(widget.availablePoints.toString())}원',
                        style: TextStyle(
                          color: const Color(0xFF8490A3),
                          fontSize: 11,
                          fontFamily: 'Pretendard-Medium',
                          letterSpacing: -0.24,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 8), // 세로 간격 추가
          // 금액 입력 영역 - 송금 정보와 금액 바로가기 버튼 사이로 이동
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween, // 양쪽 정렬로 변경
                  children: [
                    // 금액 텍스트 부분
                    Row(
                      children: [
                        Text(
                          amount.isEmpty ? '0' : _formatCurrency(amount),
                          style: TextStyle(
                            color: _isAmountExceeded 
                                ? const Color(0xFFFF3B30) // 빨간색으로 변경
                                : const Color(0xFF202020),
                            fontSize: 22,
                            fontFamily: 'Pretendard-Bold',
                            letterSpacing: -0.5,
                          ),
                        ),
                        SizedBox(width: 4),
                        Text(
                          '원',
                          style: TextStyle(
                            color: const Color(0xFF202020), // 원래 색상 유지
                            fontSize: 20, // 금액보다 2px 작게
                            fontFamily: 'Pretendard-Light', // 굵기 Light로 변경
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),

                    // 삭제 버튼 부분 - 오른쪽 정렬
                    if (amount.isNotEmpty)
                      GestureDetector(
                        onTap: _clearAmount,
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey[300],
                          ),
                          child: Center(
                            child: Icon(
                              Icons.close,
                              size: 12,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 4),
                Container(
                  height: 2,
                  width: double.infinity,
                  color: amount.isNotEmpty
                      ? const Color(0xFF3A88F4) // 원래 색상 유지
                      : const Color(0xFFEEEEEE),
                ),
                
                // 에러 메시지 추가
                if (_isAmountExceeded)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      '보유 포인트가 부족합니다',
                      style: TextStyle(
                        color: const Color(0xFFB6B6B6),
                        fontSize: 11,
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w300,
                        letterSpacing: -0.22,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          SizedBox(height: _isAmountExceeded ? 6 : 10), // 세로 간격 조정
          // 금액 바로가기 버튼들 - 스크롤 제거하고 크기 축소
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween, // 간격 균등 분배
              children: [
                _buildAmountButton('+5천원', 5000),
                _buildAmountButton('+1만원', 10000),
                _buildAmountButton('+3만원', 30000),
                _buildAmountButton('+5만원', 50000),
                _buildAmountButton('모든금액', 0, isMaxButton: true),
              ],
            ),
          ),

          SizedBox(height: 10), // 세로 간격 추가
          // 숫자 키패드
          Expanded(
            child: Container(
              width: screenWidth,
              color: Colors.white,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround, // spaceEvenly 대신 spaceAround 사용하여 오버플로우 해결
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
                              height: 38, // 높이를 약간 줄임
                              alignment: Alignment.center,
                              child: Icon(
                                Icons.backspace_outlined,
                                color: const Color(0xFFCCCCCC),
                                size: 22,
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

          // 하단 버튼
          Container(
            width: screenWidth,
            padding: const EdgeInsets.all(12), // 패딩 축소
            decoration: BoxDecoration(color: Colors.white),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: widget.onPrevious,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                      ), // 패딩 축소
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
                          fontSize: 13, // 폰트 크기 축소
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
                        amount.isEmpty
                            ? null
                            : _navigateToConfirmModal, // 확인 모달로 이동하는 함수 호출
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                      ), // 패딩 축소
                      decoration: ShapeDecoration(
                        color:
                            amount.isEmpty
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
                          fontSize: 13, // 폰트 크기 축소
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

  // 숫자 키 위젯 생성 함수
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
            height: 38, // 40에서 38로 높이 줄임
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

  // 금액 바로가기 버튼
  Widget _buildAmountButton(
    String label,
    int value, {
    bool isMaxButton = false,
  }) {
    return GestureDetector(
      onTap: () => isMaxButton ? _setMaxAmount() : _addAmount(value),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 7,
        ), // 크기 축소
        decoration: BoxDecoration(
          color: const Color(0xFFEFF2F6),
          borderRadius: BorderRadius.circular(6), // 약간 축소
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 2,
              spreadRadius: 0.5,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: const Color(0xFF001F55),
            fontSize: 11, // 폰트 크기 축소
            fontFamily: 'Pretendard-Medium',
            letterSpacing: -0.2,
          ),
        ),
      ),
    );
  }
} 