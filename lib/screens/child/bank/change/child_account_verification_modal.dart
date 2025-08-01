import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../services/auth_service.dart';
import '../../../../mixins/pin_modal_mixin.dart';
import '../modal/pin_setup_modal.dart';

class ChildAccountVerificationModal extends StatefulWidget {
  final String selectedBank;
  final String selectedBankCode;
  final VoidCallback onPrevious;
  final VoidCallback onComplete;

  const ChildAccountVerificationModal({
    super.key,
    required this.selectedBank,
    required this.selectedBankCode,
    required this.onPrevious,
    required this.onComplete,
  });

  @override
  State<ChildAccountVerificationModal> createState() =>
      _ChildAccountVerificationModalState();
}

class _ChildAccountVerificationModalState
    extends State<ChildAccountVerificationModal>
    with PinModalMixin {
  final TextEditingController _accountController = TextEditingController();
  final TextEditingController _holderNameController = TextEditingController();
  final FocusNode _accountFocusNode = FocusNode();
  final FocusNode _holderNameFocusNode = FocusNode();

  bool _isAccountValid = false;
  bool _isHolderNameValid = false;
  bool _isVerifying = false;
  bool _isVerified = false;
  String? _errorMessage;

  // 사용자 정보
  String _userName = '';

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _accountController.addListener(_validateAccount);
    _holderNameController.addListener(_validateHolderName);
    // 초기 포커스 설정
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _accountFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _accountController.dispose();
    _holderNameController.dispose();
    _accountFocusNode.dispose();
    _holderNameFocusNode.dispose();
    super.dispose();
  }

  // 사용자 이름 불러오기
  Future<void> _loadUserName() async {
    try {
      final userInfo = await AuthService.getUserInfo();
      setState(() {
        _userName = userInfo['name'] ?? '';
        // 아이의 경우 부모 이름이 아닌 본인 또는 타인 계좌 가능
      });
    } catch (e) {
      print('사용자 정보 로드 실패: $e');
    }
  }

  // 계좌번호 유효성 검증
  void _validateAccount() {
    final account = _accountController.text.replaceAll('-', '');
    setState(() {
      _isAccountValid = account.length >= 8 && account.length <= 20;
      _errorMessage = null;
    });
  }

  // 예금주명 유효성 검증
  void _validateHolderName() {
    final name = _holderNameController.text.trim();
    setState(() {
      _isHolderNameValid = name.length >= 2;
      _errorMessage = null;
    });
  }

  // 계좌번호 형식화 (예: 1234-56-7890)
  String _formatAccountNumber(String accountNumber) {
    if (accountNumber.length <= 4) return accountNumber;

    final middle =
        accountNumber.length > 6
            ? accountNumber.substring(4, 6)
            : accountNumber.substring(4);

    final last = accountNumber.length > 6 ? accountNumber.substring(6) : '';

    return '${accountNumber.substring(0, 4)}-$middle${last.isNotEmpty ? '-$last' : ''}';
  }

  // 계좌 검증 및 PIN 설정
  Future<void> _verifyAccountAndSetPin() async {
    if (!_isAccountValid || !_isHolderNameValid || _isVerifying) return;

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    try {
      // 계좌 검증 로직 (간단히 성공으로 처리)
      await Future.delayed(Duration(seconds: 1));

      setState(() {
        _isVerified = true;
        _isVerifying = false;
      });

      // 계좌 검증 성공 후 PIN 설정 모달 표시
      _showPinSetupModal();
    } catch (e) {
      setState(() {
        _errorMessage = '계좌 검증에 실패했습니다. 다시 시도해주세요.';
        _isVerifying = false;
      });
    }
  }

  // PIN 설정 모달 표시
  void _showPinSetupModal() {
    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      builder:
          (context) => PinSetupModal(
            onPinSet: (pin) async {
              Navigator.pop(context);
              // PIN 설정 및 계좌 정보 저장
              await _saveAccountInfo(pin);
            },
            onCancel: () {
              Navigator.pop(context);
              // PIN 설정 취소 시 이전 단계로
              setState(() {
                _isVerified = false;
              });
            },
          ),
    );
  }

  // 계좌 정보 저장
  Future<void> _saveAccountInfo(String pin) async {
    try {
      final accountData = {
        'bankName': widget.selectedBank,
        'bankCode': widget.selectedBankCode,
        'bankAccount': _accountController.text.replaceAll('-', ''),
        'accountHolder': _holderNameController.text.trim(),
        'pin': pin,
      };

      final result = await AuthService.updateUserInfo(
        bankName: accountData['bankName'],
        bankCode: accountData['bankCode'],
        bankAccount: accountData['bankAccount'],
      );
      final success = result['success'] == true;

      if (success) {
        widget.onComplete();
      } else {
        setState(() {
          _errorMessage = '계좌 연동에 실패했습니다. 다시 시도해주세요.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '계좌 연동에 실패했습니다. 다시 시도해주세요.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 390,
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 상단 제목 영역
          Container(
            width: 390,
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '계좌번호를 입력해 주세요',
                        style: TextStyle(
                          color: const Color(0xFF353535),
                          fontSize: 16,
                          fontFamily: 'Pretendard-Bold',
                          letterSpacing: -0.72,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '선택하신 ${widget.selectedBank}의 정보를 둘 다 입력해 주세요',
                        style: TextStyle(
                          color: const Color(0xFF999999),
                          fontSize: 12,
                          fontFamily: 'Pretendard-Light',
                          letterSpacing: -0.28,
                        ),
                      ),
                    ],
                  ),
                ),
                // X 닫기 버튼
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 16,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 계좌번호 입력 필드
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '계좌번호',
                  style: TextStyle(
                    color: const Color(0xFF353535),
                    fontSize: 14,
                    fontFamily: 'Pretendard-Medium',
                    letterSpacing: -0.28,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 48,
                  decoration: ShapeDecoration(
                    shape: RoundedRectangleBorder(
                      side: BorderSide(
                        width: 1,
                        color:
                            _accountFocusNode.hasFocus
                                ? const Color(0xFF5D9EFF)
                                : const Color(0xFFE8EDF7),
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: TextField(
                    controller: _accountController,
                    focusNode: _accountFocusNode,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(20),
                    ],
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                      ),
                      hintText: '계좌번호를 입력해 주세요',
                      hintStyle: TextStyle(
                        color: const Color(0xFF999999),
                        fontSize: 14,
                        fontFamily: 'Pretendard-Light',
                        letterSpacing: -0.28,
                      ),
                    ),
                    style: TextStyle(
                      color: const Color(0xFF353535),
                      fontSize: 14,
                      fontFamily: 'Pretendard-Medium',
                      letterSpacing: -0.28,
                    ),
                    onSubmitted: (_) {
                      _holderNameFocusNode.requestFocus();
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 예금주명 입력 필드
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '예금주명',
                  style: TextStyle(
                    color: const Color(0xFF353535),
                    fontSize: 14,
                    fontFamily: 'Pretendard-Medium',
                    letterSpacing: -0.28,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 48,
                  decoration: ShapeDecoration(
                    shape: RoundedRectangleBorder(
                      side: BorderSide(
                        width: 1,
                        color:
                            _holderNameFocusNode.hasFocus
                                ? const Color(0xFF5D9EFF)
                                : const Color(0xFFE8EDF7),
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: TextField(
                    controller: _holderNameController,
                    focusNode: _holderNameFocusNode,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                      ),
                      hintText: '예금주명을 입력해 주세요',
                      hintStyle: TextStyle(
                        color: const Color(0xFF999999),
                        fontSize: 14,
                        fontFamily: 'Pretendard-Light',
                        letterSpacing: -0.28,
                      ),
                    ),
                    style: TextStyle(
                      color: const Color(0xFF353535),
                      fontSize: 14,
                      fontFamily: 'Pretendard-Medium',
                      letterSpacing: -0.28,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '14살 미만 회원의 경우, 본인 명의가 아닌 계좌도 등록 가능해요',
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

          // 에러 메시지
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                _errorMessage!,
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                  fontFamily: 'Pretendard-Light',
                  letterSpacing: -0.24,
                ),
              ),
            ),
          ],

          const SizedBox(height: 32),

          // 하단 버튼 영역
          Container(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            child: Row(
              children: [
                // 이전 버튼
                Expanded(
                  flex: 1,
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: widget.onPrevious,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: const Color(0xFFE8EDF7),
                            width: 1,
                          ),
                        ),
                      ),
                      child: Text(
                        '이전',
                        style: TextStyle(
                          color: const Color(0xFF8490A3),
                          fontSize: 16,
                          fontFamily: 'Pretendard-Medium',
                          letterSpacing: -0.32,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // 다음 버튼
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed:
                          (_isAccountValid &&
                                  _isHolderNameValid &&
                                  !_isVerifying)
                              ? _verifyAccountAndSetPin
                              : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            (_isAccountValid &&
                                    _isHolderNameValid &&
                                    !_isVerifying)
                                ? const Color(0xFF5D9EFF)
                                : const Color(0xFFE8EDF7),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child:
                          _isVerifying
                              ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                              : Text(
                                '다음',
                                style: TextStyle(
                                  color:
                                      (_isAccountValid &&
                                              _isHolderNameValid &&
                                              !_isVerifying)
                                          ? Colors.white
                                          : const Color(0xFF8490A3),
                                  fontSize: 16,
                                  fontFamily: 'Pretendard-Medium',
                                  letterSpacing: -0.32,
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
}
