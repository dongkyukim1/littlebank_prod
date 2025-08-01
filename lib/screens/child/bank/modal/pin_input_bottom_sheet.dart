import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../services/auth_service.dart';
import '../../../../../services/payment_service.dart';
import '../transfer_complete_screen.dart';

class PinInputBottomSheet extends StatefulWidget {
  final String title;
  final Function(String pin) onPinConfirm;
  final VoidCallback? onCancel;
  // 출금 완료 화면으로 이동하기 위한 추가 파라미터들
  final String? selectedBank;
  final String? accountNumber;
  final String? amount;
  final int? fee;
  final int? netAmount;
  final String? receiverName;
  final String? receiverPhone;
  final String? senderName;
  final int? receiverId; // 받을 사람의 userId 추가

  const PinInputBottomSheet({
    Key? key,
    this.title = '결제 비밀번호를 입력해 주세요',
    required this.onPinConfirm,
    this.onCancel,
    this.selectedBank,
    this.accountNumber,
    this.amount,
    this.fee,
    this.netAmount,
    this.receiverName,
    this.receiverPhone,
    this.senderName,
    this.receiverId,
  }) : super(key: key);

  @override
  State<PinInputBottomSheet> createState() => _PinInputBottomSheetState();
}

class _PinInputBottomSheetState extends State<PinInputBottomSheet> {
  String _currentPin = '';
  bool _isProcessing = false;

  void _addDigit(String digit) {
    if (_currentPin.length < 6) {
      HapticFeedback.lightImpact();
      setState(() {
        _currentPin += digit;
      });
    }
  }

  void _deleteDigit() {
    if (_currentPin.isNotEmpty) {
      HapticFeedback.lightImpact();
      setState(() {
        _currentPin = _currentPin.substring(0, _currentPin.length - 1);
      });
    }
  }

  void _deleteAll() {
    if (_currentPin.isNotEmpty) {
      HapticFeedback.lightImpact();
      setState(() {
        _currentPin = '';
      });
    }
  }

  Future<void> _confirmPin() async {
    if (_currentPin.length != 6 || _isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final verifyResult = await AuthService.verifyPin(pin: _currentPin);
      if (verifyResult['success'] != true) {
        throw Exception(verifyResult['message'] ?? 'PIN 번호가 올바르지 않습니다');
      }

      // PIN 검증 성공 시 아이단 포인트 꺼내기 처리 및 완료 화면으로 이동
      if (widget.selectedBank != null &&
          widget.accountNumber != null &&
          widget.amount != null &&
          widget.fee != null &&
          widget.netAmount != null) {
        print('PIN 검증 성공 - 아이단 포인트 꺼내기 API 호출 시작');
        print('API 호출 파라미터 확인:');
        print('- exchangeAmount: ${widget.netAmount}');
        print('- depositTargetUserId (receiverId): ${widget.receiverId}');
        print('- receiverName: ${widget.receiverName}');
        print('- receiverPhone: ${widget.receiverPhone}');

        // 아이단용 포인트 꺼내기 API 호출
        final response = await PaymentService.refundPointsChild(
          depositTargetUserId: widget.receiverId!,
          exchangeAmount: widget.netAmount!,
        );

        print('🎯 [실제 파일 수정] 아이단 포인트 꺼내기 API 성공: $response');

        // API 응답에서 남은 포인트 가져오기
        int remainingPoint = response['remainingPoint'] ?? 0;
        print('🎯 [실제 파일 수정] remainingPoint: $remainingPoint');

        // 포인트 업데이트를 위해 getUserPoints 호출 (1회만)
        await Future.delayed(Duration(milliseconds: 300)); // 서버 업데이트 대기
        await PaymentService.getUserPoints(forceRefresh: true);

        // 바텀시트 닫기
        Navigator.pop(context);
        // 출금 완료 화면으로 이동
        print(
          '🎯 [실제 파일 수정] TransferCompleteScreen으로 이동 - remainingPoint: $remainingPoint',
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (context) => TransferCompleteScreen(
                  receiverName: widget.receiverName ?? '받는 사람',
                  receiverAccount: widget.accountNumber!,
                  senderAccount: widget.senderName ?? '보내는 사람',
                  amount: widget.amount!,
                  remainingBalance: remainingPoint, // API 응답값 사용
                ),
          ),
        );
      } else {
        // 기존 로직 유지 (출금이 아닌 다른 용도로 사용될 때)
        widget.onPinConfirm(_currentPin);
      }
    } catch (e) {
      print('PIN 검증 또는 출금 처리 오류: $e');

      if (mounted) {
        setState(() {
          _isProcessing = false;
          _currentPin = '';
        });

        // 오류 메시지 결정
        String errorMessage = '결제 비밀번호가 틀립니다';
        String errorTitle = '알림';

        // API 관련 오류인지 확인
        if (e.toString().contains('부족') ||
            e.toString().contains('refund') ||
            e.toString().contains('포인트') ||
            e.toString().contains('출금')) {
          errorTitle = '출금 실패';
          errorMessage = e.toString().replaceFirst('Exception: ', '');
        }

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              title: Text(
                errorTitle,
                style: const TextStyle(
                  fontSize: 16,
                  fontFamily: 'Pretendard-Bold',
                  color: Colors.black,
                ),
              ),
              content: Text(
                errorMessage,
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
                      color: Color(0xFF3A88F4),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return Container(
      height: screenHeight * 0.47,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        children: [
          _HeaderComponent(title: widget.title, onCancel: widget.onCancel),
          _buildPinInput(),
          Expanded(child: _buildNumberPad()),
          _ActionButtonsComponent(
            onDelete: _deleteAll,
            onConfirm: _confirmPin,
            isEnabled: _currentPin.length == 6 && !_isProcessing,
            isProcessing: _isProcessing,
          ),
        ],
      ),
    );
  }

  Widget _buildPinInput() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 20.0),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          6,
          (index) => Container(
            margin: const EdgeInsets.symmetric(horizontal: 12.0),
            width: 24.0,
            height: 24.0,
            decoration: BoxDecoration(
              color:
                  index < _currentPin.length
                      ? const Color(0xFF5D9EFF)
                      : Colors.grey[300],
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNumberPad() {
    return Container(
      color: const Color(0xFF5D6A7F),
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children:
                ['1', '3', '7', '6'].map((v) => _buildNumberButton(v)).toList(),
          ),
          const SizedBox(height: 8),
          Row(
            children:
                ['0', '2', '4', '9'].map((v) => _buildNumberButton(v)).toList(),
          ),
          const SizedBox(height: 8),
          Row(
            children:
                ['5', '8', '←', ''].map((v) => _buildNumberButton(v)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberButton(String value) {
    if (value.isEmpty) return const Expanded(child: SizedBox());
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () {
              if (value == '←') {
                _deleteDigit();
              } else {
                _addDigit(value);
              }
            },
            child: Container(
              height: 48,
              alignment: Alignment.center,
              child:
                  value == '←'
                      ? Image.asset(
                        'assets/icons/parent/bank/cancel.png',
                        width: 28,
                        height: 28,
                        color: Colors.white,
                      )
                      : Text(
                        value,
                        style: const TextStyle(
                          fontFamily: 'Pretendard-Light',
                          fontSize: 22,
                          color: Colors.white,
                          letterSpacing: -0.8,
                        ),
                      ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderComponent extends StatelessWidget {
  final String title;
  final VoidCallback? onCancel;
  const _HeaderComponent({required this.title, this.onCancel});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48.0,
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Pretendard-Bold',
              fontSize: 16.0,
              color: Color(0xFF202020),
              letterSpacing: -0.72,
            ),
          ),
          GestureDetector(
            onTap: () {
              onCancel?.call();
              Navigator.pop(context);
            },
            child: const Icon(Icons.close, size: 24, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _ActionButtonsComponent extends StatelessWidget {
  final VoidCallback onDelete;
  final VoidCallback onConfirm;
  final bool isEnabled;
  final bool isProcessing;
  const _ActionButtonsComponent({
    required this.onDelete,
    required this.onConfirm,
    required this.isEnabled,
    required this.isProcessing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 97,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
      color: const Color(0xFF5D6A7F),
      child: Row(
        children: [
          Expanded(
            child: _buildButton(
              text: '삭제',
              backgroundColor: const Color(0xFFDCDCDC),
              textColor: const Color(0xFFB6B6B6),
              onPressed: onDelete,
              enabled: true,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildButton(
              text: isProcessing ? '확인 중...' : '확인',
              backgroundColor:
                  isEnabled ? const Color(0xFF5D9EFF) : const Color(0xFFDCDCDC),
              textColor: isEnabled ? Colors.white : const Color(0xFFB6B6B6),
              onPressed: isEnabled ? onConfirm : null,
              enabled: isEnabled,
              isProcessing: isProcessing,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton({
    required String text,
    required Color backgroundColor,
    required Color textColor,
    required VoidCallback? onPressed,
    bool enabled = true,
    bool isProcessing = false,
  }) {
    return SizedBox(
      width: 150,
      child: ElevatedButton(
        onPressed: enabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          padding: const EdgeInsets.all(16.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          elevation: 0,
        ),
        child:
            isProcessing
                ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                : Text(
                  text,
                  style: TextStyle(
                    fontFamily: 'Pretendard-Light',
                    fontSize: 14.0,
                    letterSpacing: -0.28,
                    color: textColor,
                  ),
                ),
      ),
    );
  }
}
