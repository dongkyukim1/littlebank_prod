import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../services/auth_service.dart';
import '../../../../../mixins/pin_modal_mixin.dart';
import 'parent_pin_setup_modal.dart';
import '../../my_page_screen.dart';

class AccountVerificationModal extends StatefulWidget {
  final String selectedBank;
  final String selectedBankCode;
  final VoidCallback onPrevious;
  final VoidCallback onComplete;
  final String? userType; // 'parent' or 'child'

  const AccountVerificationModal({
    super.key,
    required this.selectedBank,
    required this.selectedBankCode,
    required this.onPrevious,
    required this.onComplete,
    this.userType = 'parent', // 부모단용으로 기본값 변경
  });

  @override
  State<AccountVerificationModal> createState() =>
      _AccountVerificationModalState();
}

class _AccountVerificationModalState extends State<AccountVerificationModal> {
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
        // 사용자 이름을 저장만 하고 자동 입력하지 않음
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

  // 계좌 검증
  Future<void> _verifyAccount() async {
    if (!_isAccountValid || !_isHolderNameValid || _isVerifying) return;

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    try {
      // 실제 계좌 검증 API 호출 (검증만 하고 저장은 하지 않음)
      final result = await AuthService.verifyAccountHolder(
        bankCode: widget.selectedBankCode,
        bankNumber: _accountController.text.replaceAll('-', ''),
        holderName: _holderNameController.text.trim(),
      );

      if (result['success'] == true) {
        // 검증 성공 - PIN 설정에서 저장할 예정
        setState(() {
          _isVerified = true;
          _isVerifying = false;
        });
      } else {
        final errorCode = result['errorCode'] ?? '';
        String errorMessage = result['message'] ?? '계좌 검증에 실패했습니다.';

        // 서버 에러(C004) 시 특별 처리
        if (errorCode == 'C004') {
          setState(() {
            _errorMessage = null;
            _isVerifying = false;
          });

          // 재시도 다이얼로그 표시
          _showRetryDialog();
        } else {
          setState(() {
            _errorMessage = errorMessage;
            _isVerifying = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = '네트워크 오류가 발생했습니다. 다시 시도해주세요.';
        _isVerifying = false;
      });
    }
  }

  // 재시도 다이얼로그 표시
  void _showRetryDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            '서버 일시 오류',
            style: TextStyle(fontSize: 16, fontFamily: 'Pretendard-Bold'),
            textAlign: TextAlign.center,
          ),
          content: Text(
            '서버에서 일시적인 오류가 발생했습니다.\n잠시 후 다시 시도하시겠습니까?',
            style: TextStyle(fontSize: 14, fontFamily: 'Pretendard-Light'),
            textAlign: TextAlign.center,
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      '취소',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                        fontFamily: 'Pretendard-Medium',
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      // 2초 후 재시도
                      Future.delayed(Duration(seconds: 2), () {
                        _verifyAccount();
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF146AFF),
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      '재시도',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontFamily: 'Pretendard-Medium',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          contentPadding: EdgeInsets.fromLTRB(24, 20, 24, 8),
          actionsPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        );
      },
    );
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
                        '선택하신 은행의 정보를 둘 다 입력해 주세요',
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

          // 입력 필드 영역
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 계좌번호 입력
                Text(
                  '계좌번호',
                  style: TextStyle(
                    color: const Color(0xFFC4C4C4),
                    fontSize: 12,
                    fontFamily: 'Pretendard-Light',
                    letterSpacing: -0.28,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 358,
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: ShapeDecoration(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      side: BorderSide(
                        width: 0.80,
                        color:
                            _isAccountValid
                                ? const Color(0xFF5D9EFF)
                                : const Color(0xFFE8EDF7),
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: TextField(
                      controller: _accountController,
                      focusNode: _accountFocusNode,
                      keyboardType: TextInputType.number,
                      textAlignVertical: TextAlignVertical.center,
                      onChanged: (value) {
                        setState(() {});
                      },
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        hintText: '계좌번호를 입력하세요',
                        hintStyle: TextStyle(
                          color: const Color(0xFF999999),
                          fontSize: 12,
                          fontFamily: 'Pretendard-Light',
                          letterSpacing: -0.28,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                        suffixIcon: GestureDetector(
                          onTap:
                              _accountController.text.isNotEmpty
                                  ? () {
                                    _accountController.clear();
                                  }
                                  : null,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 2),
                            child: Opacity(
                              opacity:
                                  _accountController.text.isNotEmpty
                                      ? 1.0
                                      : 0.0,
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: Image.asset(
                                  'assets/icons/my/삭제.png',
                                  width: 24,
                                  height: 24,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                        ),
                        suffixIconConstraints: BoxConstraints(
                          minWidth: 24,
                          minHeight: 16,
                        ),
                      ),
                      style: TextStyle(
                        color: const Color(0xFF353535),
                        fontSize: 12,
                        fontFamily: 'Pretendard-Light',
                        letterSpacing: -0.28,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 예금주명 입력
                Text(
                  '예금주명',
                  style: TextStyle(
                    color: const Color(0xFFC4C4C4),
                    fontSize: 12,
                    fontFamily: 'Pretendard-Light',
                    letterSpacing: -0.28,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 358,
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: ShapeDecoration(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      side: BorderSide(
                        width: 0.80,
                        color:
                            _isHolderNameValid
                                ? const Color(0xFF5D9EFF)
                                : const Color(0xFFE8EDF7),
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: TextField(
                      controller: _holderNameController,
                      focusNode: _holderNameFocusNode,
                      textAlignVertical: TextAlignVertical.center,
                      onChanged: (value) {
                        setState(() {});
                      },
                      decoration: InputDecoration(
                        hintText: '예금주명을 입력하세요',
                        hintStyle: TextStyle(
                          color: const Color(0xFF999999),
                          fontSize: 12,
                          fontFamily: 'Pretendard-Light',
                          letterSpacing: -0.28,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                        suffixIcon: GestureDetector(
                          onTap:
                              _holderNameController.text.isNotEmpty
                                  ? () {
                                    _holderNameController.clear();
                                  }
                                  : null,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 2),
                            child: Opacity(
                              opacity:
                                  _holderNameController.text.isNotEmpty
                                      ? 1.0
                                      : 0.0,
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: Image.asset(
                                  'assets/icons/my/삭제.png',
                                  width: 24,
                                  height: 24,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                        ),
                        suffixIconConstraints: BoxConstraints(
                          minWidth: 24,
                          minHeight: 16,
                        ),
                      ),
                      style: TextStyle(
                        color: const Color(0xFF353535),
                        fontSize: 12,
                        fontFamily: 'Pretendard-Light',
                        letterSpacing: -0.28,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '본인 명의의 계좌만 입력해주세요',
                  style: TextStyle(
                    color: const Color(0xFF8490A3),
                    fontSize: 10,
                    fontFamily: 'Pretendard-Light',
                    letterSpacing: -0.24,
                  ),
                ),
              ],
            ),
          ),

          // 에러 메시지
          if (_errorMessage != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                _errorMessage!,
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                  fontFamily: 'Pretendard-Light',
                ),
              ),
            ),

          // 버튼 영역
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
            child: Column(
              children: [
                // 인증 완료 박스 (검증 완료 후 표시)
                if (_isVerified)
                  Container(
                    width: 358,
                    height: 50,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCDCDC),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(
                            color: Color(0xFF5D9EFF),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '인증이 완료되었어요!',
                          style: TextStyle(
                            color: const Color(0xFF8490A3),
                            fontSize: 12,
                            fontFamily: 'Pretendard-Medium',
                            letterSpacing: -0.24,
                          ),
                        ),
                      ],
                    ),
                  ),

                // 인증하기 버튼 (인증 완료 전에만 표시)
                if (!_isVerified) ...[
                  Container(
                    width: 358,
                    height: 52,
                    child: ElevatedButton(
                      onPressed:
                          (_isAccountValid &&
                                  _isHolderNameValid &&
                                  !_isVerifying)
                              ? _verifyAccount
                              : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            (_isAccountValid &&
                                    _isHolderNameValid &&
                                    !_isVerifying)
                                ? const Color(0xFF146AFF)
                                : const Color(0xFFE0E5F2),
                        disabledBackgroundColor: const Color(0xFFE0E5F2),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child:
                          _isVerifying
                              ? CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              )
                              : Text(
                                '인증하기',
                                style: TextStyle(
                                  color:
                                      (_isAccountValid &&
                                              _isHolderNameValid &&
                                              !_isVerifying)
                                          ? Colors.white
                                          : const Color(0xFF999999),
                                  fontSize: 12,
                                  fontFamily: 'Pretendard-Medium',
                                  letterSpacing: -0.24,
                                ),
                              ),
                    ),
                  ),

                  const SizedBox(height: 12),
                ],

                // 다음 버튼
                Container(
                  width: 358,
                  height: 52,
                  child: ElevatedButton(
                    onPressed:
                        _isVerified
                            ? () {
                              Navigator.pop(context);
                              // PIN 설정 모달로 이동
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder:
                                    (context) => ParentPinSetupModal(
                                      institution: {
                                        'name': widget.selectedBank,
                                        'code': widget.selectedBankCode,
                                      },
                                      accountNumber: _accountController.text,
                                      holderName: _holderNameController.text,
                                      onComplete: () async {
                                        // 계좌 연동 완료 처리
                                        if (mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                '계좌 연동이 완료되었습니다!',
                                                style: TextStyle(
                                                  fontFamily:
                                                      'Pretendard-Medium',
                                                ),
                                              ),
                                              backgroundColor: Color(
                                                0xFF146AFF,
                                              ),
                                            ),
                                          );
                                        }

                                        // 잠시 후 마이페이지로 이동 (메시지 표시 시간 확보)
                                        await Future.delayed(
                                          Duration(milliseconds: 500),
                                        );

                                        // 사용자 타입에 따라 적절한 마이페이지로 이동
                                        if (widget.userType == 'parent' &&
                                            mounted) {
                                          Navigator.of(
                                            context,
                                          ).pushAndRemoveUntil(
                                            MaterialPageRoute(
                                              builder:
                                                  (context) =>
                                                      const ParentMyPageScreen(),
                                            ),
                                            (route) => false,
                                          );
                                        } else if (widget.userType == 'child' &&
                                            mounted) {
                                          Navigator.of(
                                            context,
                                          ).pushNamedAndRemoveUntil(
                                            '/child/my',
                                            (route) => false,
                                          );
                                        } else {
                                          // 기본 완료 처리
                                          widget.onComplete();
                                        }
                                      },
                                    ),
                              );
                            }
                            : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _isVerified
                              ? const Color(0xFF146AFF)
                              : const Color(0xFFE0E5F2),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      '다음',
                      style: TextStyle(
                        color:
                            _isVerified
                                ? Colors.white
                                : const Color(0xFF999999),
                        fontSize: 12,
                        fontFamily: 'Pretendard-Medium',
                        letterSpacing: -0.24,
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
