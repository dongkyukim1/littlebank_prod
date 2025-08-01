import 'package:flutter/material.dart';
import '../../../../services/subscription_service.dart';
import '../../../../services/billing_service.dart';
import 'gift_option_bottom_sheet.dart';
import 'confirmation_bottom_sheet.dart';
import 'purchase_option_bottom_sheet.dart';
import 'purchase_confirmation_bottom_sheet.dart';

class ParentLittleBankBenefitsScreen extends StatefulWidget {
  const ParentLittleBankBenefitsScreen({Key? key}) : super(key: key);

  @override
  State<ParentLittleBankBenefitsScreen> createState() =>
      _ParentLittleBankBenefitsScreenState();
}

class _ParentLittleBankBenefitsScreenState
    extends State<ParentLittleBankBenefitsScreen> {
  // 현재 선택된 탭 인덱스
  int _selectedTabIndex = 0;
  // 구독 처리 중 상태
  bool _isSubscribing = false;

  // 섹션별 GlobalKey 추가
  final GlobalKey _littleBankSectionKey = GlobalKey();
  final GlobalKey _benefitsSectionKey = GlobalKey();
  final GlobalKey _freeTierSectionKey = GlobalKey();

  // 스크롤 컨트롤러r
  final ScrollController _scrollController = ScrollController();

  bool _isChecked = false;

  // 쿠폰코드 입력 관련 추가
  final TextEditingController _couponCodeController = TextEditingController();
  bool _isCouponSubmitting = false;

  @override
  void initState() {
    super.initState();
    // 딥링크로 전달받은 초대 코드 처리
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleDeepLinkInviteCode();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _couponCodeController.dispose();
    super.dispose();
  }

  // 딥링크로 전달받은 초대 코드 처리
  void _handleDeepLinkInviteCode() {
    final Map<String, dynamic>? arguments =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (arguments != null && arguments['inviteCode'] != null) {
      final String inviteCode = arguments['inviteCode'];
      print('🔗 딥링크를 통해 초대 코드 수신: $inviteCode');

      // 쿠폰코드 입력란에 자동 입력
      _couponCodeController.text = inviteCode;

      // 잠시 후 자동으로 쿠폰코드 등록 시도
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _submitCouponCode();
        }
      });
    }
  }

  // 쿠폰코드 등록 처리
  Future<void> _submitCouponCode() async {
    if (_couponCodeController.text.trim().isEmpty) {
      _showErrorDialog('쿠폰코드를 입력해주세요.');
      return;
    }

    if (_isCouponSubmitting) return;

    setState(() {
      _isCouponSubmitting = true;
    });

    try {
      final couponCode = _couponCodeController.text.trim();
      print('쿠폰코드 등록 시도: $couponCode');

      // 로딩 표시
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    '쿠폰코드를 확인 중입니다...',
                    style: TextStyle(
                      color: Color(0xFF666666),
                      fontSize: 14,
                      fontFamily: 'Pretendard-Regular',
                    ),
                  ),
                ],
              ),
            ),
      );

      // 쿠폰코드 상태 및 현재 구독권 확인
      print('🔍 쿠폰코드 등록 전 상태 확인');
      try {
        final currentSub = await SubscriptionService.getCurrentSubscription();
        final freeSub = await SubscriptionService.getFreeSubscription();
        final inviteCodes = await SubscriptionService.getInviteCodes();

        print('📋 현재 일반 구독권: $currentSub');
        print('📋 현재 무료 구독권: $freeSub');
        print('📋 사용 가능한 쿠폰코드: $inviteCodes');

        // 입력한 쿠폰코드가 현재 사용 가능한 코드인지 확인
        if (inviteCodes != null && inviteCodes['inviteCodes'] != null) {
          final codes = inviteCodes['inviteCodes'] as Map<String, dynamic>;
          if (codes.containsKey(couponCode)) {
            final codeStatus = codes[couponCode];
            print('🔍 입력한 쿠폰코드 상태: $couponCode → $codeStatus');
            if (codeStatus != null) {
              print('⚠️  이 쿠폰코드는 이미 사용된 것 같습니다 (사용자: $codeStatus)');
            } else {
              print('✅ 이 쿠폰코드는 아직 사용되지 않았습니다');
            }
          } else {
            print('❓ 입력한 쿠폰코드가 현재 사용 가능한 쿠폰코드 목록에 없습니다');
          }
        }
      } catch (e) {
        print('🔍 상태 확인 중 오류: $e');
      }

      // 쿠폰코드 등록 API 호출 (일반 구독권과 무료 구독 모두 시도)
      Map<String, dynamic>? result;
      String? firstErrorMessage;

      // 먼저 일반 구독권 등록 시도
      print('🔹 일반 구독권 등록 시도: $couponCode');
      result = await SubscriptionService.redeemInviteCode(couponCode);
      print('🔹 일반 구독권 등록 결과: $result');

      // 일반 구독권 등록이 실패하면 무료 구독 시도
      if (result == null || result['error'] == true) {
        firstErrorMessage = result?['message']; // 첫 번째 에러 메시지 저장
        print('🔹 일반 구독권 등록 실패, 무료 구독 시도: $couponCode');
        result = await SubscriptionService.startFreeTrial(couponCode);
        print('🔹 무료 구독 시도 결과: $result');
      }

      Navigator.of(context).pop(); // 로딩 닫기

      if (result != null && result['error'] != true) {
        // 성공 처리 - 새로운 구독권 등록 성공 모달 표시
        _showSubscriptionSuccessModal();
        _couponCodeController.clear();
      } else {
        // 실패 처리 - 더 친절한 에러 메시지 제공
        String errorMessage = result?['message'] ?? '쿠폰코드 등록에 실패했습니다.';

        // 특정 에러 메시지에 대한 개선된 안내
        if (errorMessage.contains('구독을 찾을 수 없습니다')) {
          errorMessage =
              '쿠폰코드를 찾을 수 없습니다.\n\n'
              '• 쿠폰코드가 이미 사용되었을 수 있습니다\n'
              '• 쿠폰코드 입력을 다시 확인해주세요\n'
              '• 쿠폰코드가 만료되었을 수 있습니다\n'
              '• 다른 계정에서 이미 사용했을 수 있습니다';
        } else if (errorMessage.contains('이미 무료구독을 사용했습니다') ||
            errorMessage.contains('무료 체험') ||
            errorMessage.contains('이미 사용')) {
          errorMessage =
              '이미 무료 체험을 사용하신 계정입니다.\n\n'
              '• 무료 체험은 계정당 1회만 이용 가능합니다\n'
              '• 일반 구독권 쿠폰코드를 사용해보세요\n'
              '• 새 계정으로 가입하시면 무료 체험이 가능합니다';
        } else if (errorMessage.contains('무료구독코드가 아니') ||
            errorMessage.contains('잘못된 코드') ||
            errorMessage.contains('유효하지 않은')) {
          errorMessage =
              '올바르지 않은 쿠폰코드입니다.\n\n'
              '• 쿠폰코드를 다시 확인해주세요\n'
              '• 대소문자와 숫자를 정확히 입력해주세요\n'
              '• 쿠폰코드가 만료되었을 수 있습니다';
        }

        _showErrorDialog(errorMessage);
      }
    } catch (e) {
      Navigator.of(context).pop(); // 로딩 닫기
      print('쿠폰코드 등록 중 오류 발생: $e');
      _showErrorDialog('쿠폰코드 등록 중 오류가 발생했습니다: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isCouponSubmitting = false;
        });
      }
    }
  }

  // 쿠폰코드 입력 위젯
  Widget _buildCouponCodeInput() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E5E5), width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 제목 텍스트
          Text.rich(
            TextSpan(
              children: [
                const TextSpan(
                  text: '잠깐! 받은 구독권 선물을 등록하고 ',
                  style: TextStyle(
                    color: Color(0xFF202020),
                    fontSize: 16,
                    fontFamily: 'Pretendard-Bold',
                    height: 1.50,
                    letterSpacing: -0.64,
                  ),
                ),
                const TextSpan(
                  text: '2주 무료',
                  style: TextStyle(
                    color: Color(0xFF3A88F4),
                    fontSize: 16,
                    fontFamily: 'Pretendard-Bold',
                    height: 1.50,
                    letterSpacing: -0.64,
                  ),
                ),
                const TextSpan(
                  text: '로 이용해 보세요',
                  style: TextStyle(
                    color: Color(0xFF202020),
                    fontSize: 16,
                    fontFamily: 'Pretendard-Bold',
                    height: 1.50,
                    letterSpacing: -0.64,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '무료 체험 기간에는 결제되지 않아요!',
            style: TextStyle(
              color: Color(0xFF666666),
              fontSize: 14,
              fontFamily: 'Pretendard-Light',
              letterSpacing: -0.28,
            ),
          ),
          const SizedBox(height: 16),

          // 쿠폰코드 입력란
          Container(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '쿠폰코드 입력',
                  style: TextStyle(
                    color: Color(0xFF202020),
                    fontSize: 14,
                    fontFamily: 'Pretendard-Medium',
                    letterSpacing: -0.28,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    // 입력 필드
                    Expanded(
                      child: Container(
                        height: 48,
                        child: TextField(
                          controller: _couponCodeController,
                          enabled: !_isCouponSubmitting,
                          textInputAction: TextInputAction.done,
                          keyboardType: TextInputType.text,
                          textCapitalization: TextCapitalization.characters,
                          onSubmitted: (_) => _submitCouponCode(),
                          decoration: InputDecoration(
                            hintText: '쿠폰코드를 입력해 주세요',
                            hintStyle: const TextStyle(
                              color: Color(0xFFC4C4C4),
                              fontSize: 14,
                              fontFamily: 'Pretendard-Light',
                              letterSpacing: -0.28,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: Color(0xFFE5E5E5),
                                width: 1,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: Color(0xFFE5E5E5),
                                width: 1,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: Color(0xFF3A88F4),
                                width: 2,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          style: const TextStyle(
                            color: Color(0xFF202020),
                            fontSize: 14,
                            fontFamily: 'Pretendard-Regular',
                            letterSpacing: -0.28,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // 등록 버튼
                    Container(
                      height: 48,
                      child: ElevatedButton(
                        onPressed:
                            _isCouponSubmitting ? null : _submitCouponCode,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              _isCouponSubmitting
                                  ? const Color(0xFFE5E5E5)
                                  : const Color(0xFF3A88F4),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child:
                            _isCouponSubmitting
                                ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    color: Color(0xFF999999),
                                    strokeWidth: 2,
                                  ),
                                )
                                : const Text(
                                  '등록',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontFamily: 'Pretendard-Medium',
                                    letterSpacing: -0.28,
                                  ),
                                ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 해당 섹션으로 스크롤
  void _scrollToSection(GlobalKey key) {
    final context = key.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  // 구독하기 기능
  Future<void> _startSubscription() async {
    if (_isSubscribing) return;

    setState(() {
      _isSubscribing = true;
    });

    try {
      // 구독권 좌석 선택 다이얼로그 표시
      final selectedSeat = await _showSeatSelectionDialog();

      if (selectedSeat == null) {
        setState(() {
          _isSubscribing = false;
        });
        return;
      }

      // 구독권 생성 API 호출
      final result = await SubscriptionService.createSubscription(selectedSeat);

      if (result != null) {
        // 성공 시 메시지 표시
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '🎉 ${selectedSeat}인용 구독권이 성공적으로 생성되었습니다!',
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'Pretendard-Medium',
                ),
              ),
              backgroundColor: const Color(0xFF5D9EFF),
              duration: const Duration(seconds: 3),
            ),
          );

          // 이전 화면으로 돌아가기
          Navigator.of(context).pop();
        }
      } else {
        // 실패 시 에러 메시지 표시
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                '구독권 생성에 실패했습니다. 다시 시도해주세요.',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Pretendard-Medium',
                ),
              ),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      print('구독 생성 중 오류: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '네트워크 오류가 발생했습니다. 다시 시도해주세요.',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Pretendard-Medium',
              ),
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubscribing = false;
        });
      }
    }
  }

  // 구독권 좌석 선택 다이얼로그
  Future<int?> _showSeatSelectionDialog() async {
    return showDialog<int>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            '구독권 선택',
            style: TextStyle(
              fontSize: 18,
              fontFamily: 'Pretendard-Bold',
              color: Colors.black,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '몇 명이 함께 사용할 구독권을 선택해주세요',
                style: TextStyle(
                  fontSize: 14,
                  fontFamily: 'Pretendard-Regular',
                  color: Color(0xFF666666),
                ),
              ),
              const SizedBox(height: 20),
              ...[1, 2, 3, 4, 5].map((seat) => _buildSeatOption(seat)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                '취소',
                style: TextStyle(
                  fontSize: 14,
                  fontFamily: 'Pretendard-Medium',
                  color: Color(0xFF999999),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // 좌석 옵션 위젯
  Widget _buildSeatOption(int seat) {
    String discountText = '';
    if (seat >= 3) discountText = ' (${(seat - 1) * 10}% 할인)';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      child: ElevatedButton(
        onPressed: () => Navigator.of(context).pop(seat),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF5D9EFF),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(
          '${seat}인용$discountText',
          style: const TextStyle(fontSize: 16, fontFamily: 'Pretendard-Medium'),
        ),
      ),
    );
  }

  // 전화번호 입력 바텀시트
  Future<void> _showPhoneInputBottomSheet(
    String title,
    String price,
    int persons,
    bool hasDiscount,
    bool includeMyself,
  ) async {
    List<String> phoneNumbers = [];
    String currentInput = '';
    int targetCount = includeMyself ? persons - 1 : persons;
    Set<String> pressedNumbers = {}; // 눌린 숫자들을 추적

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Scaffold(
              backgroundColor: Colors.transparent,
              body: Stack(
                children: [
                  // 바텀시트 콘텐츠
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: double.infinity,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 헤더
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            decoration: const ShapeDecoration(
                              color: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(24),
                                  topRight: Radius.circular(24),
                                ),
                              ),
                            ),
                            child: Container(
                              width: double.infinity,
                              height: 24,
                              child: Stack(
                                children: [
                                  const Positioned(
                                    left: 0,
                                    top: 1,
                                    child: Text(
                                      '초대할 사람의 전화번호를 입력해 주세요',
                                      style: TextStyle(
                                        color: Color(0xFF202020),
                                        fontSize: 16,
                                        fontFamily: 'Pretendard-Bold',
                                        letterSpacing: -0.64,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    right: 0,
                                    top: 0,
                                    child: GestureDetector(
                                      onTap: () => Navigator.of(context).pop(),
                                      child: Container(
                                        width: 24,
                                        height: 24,
                                        child: const Icon(
                                          Icons.close,
                                          size: 24,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // 전화번호 입력 및 태그 표시 영역
                          Container(
                            decoration: const BoxDecoration(
                              color: Colors.white,
                            ),
                            child: Column(
                              children: [
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: double.infinity,
                                        child: Text(
                                          currentInput.isEmpty
                                              ? '전화번호를 입력해 주세요'
                                              : currentInput,
                                          style: TextStyle(
                                            color:
                                                currentInput.isEmpty
                                                    ? const Color(0xFFC4C4C4)
                                                    : const Color(0xFF202020),
                                            fontSize: 16,
                                            fontFamily: 'Pretendard-Light',
                                            letterSpacing: -0.64,
                                          ),
                                        ),
                                      ),
                                      if (phoneNumbers.isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        Wrap(
                                          spacing: 12,
                                          runSpacing: 8,
                                          children:
                                              phoneNumbers
                                                  .map(
                                                    (phone) => Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 12,
                                                            vertical: 8,
                                                          ),
                                                      decoration: ShapeDecoration(
                                                        color: const Color(
                                                          0xFF10CB86,
                                                        ),
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                36,
                                                              ),
                                                        ),
                                                      ),
                                                      child: Row(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          Text(
                                                            phone,
                                                            style: const TextStyle(
                                                              color:
                                                                  Colors.white,
                                                              fontSize: 10,
                                                              fontFamily:
                                                                  'Pretendard-Light',
                                                              letterSpacing:
                                                                  -0.20,
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            width: 4,
                                                          ),
                                                          GestureDetector(
                                                            onTap: () {
                                                              setState(() {
                                                                phoneNumbers
                                                                    .remove(
                                                                      phone,
                                                                    );
                                                              });
                                                            },
                                                            child: const Icon(
                                                              Icons.close,
                                                              size: 16,
                                                              color:
                                                                  Colors.white,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  )
                                                  .toList(),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                // 구분선 (전화번호 입력 영역 아래)
                                Container(
                                  width: double.infinity,
                                  height: 1,
                                  color: const Color(0xFFF0F0F0),
                                ),
                              ],
                            ),
                          ),
                          // 키패드
                          Container(
                            width: double.infinity,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                            ),
                            child: Column(
                              children: [
                                // 첫 번째 행: 1, 2, 3
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 8,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      _buildKeypadButton(
                                        '1',
                                        setState,
                                        pressedNumbers,
                                        (value) {
                                          currentInput += value;
                                        },
                                      ),
                                      _buildKeypadButton(
                                        '2',
                                        setState,
                                        pressedNumbers,
                                        (value) {
                                          currentInput += value;
                                        },
                                      ),
                                      _buildKeypadButton(
                                        '3',
                                        setState,
                                        pressedNumbers,
                                        (value) {
                                          currentInput += value;
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                // 두 번째 행: 4, 5, 6
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 8,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      _buildKeypadButton(
                                        '4',
                                        setState,
                                        pressedNumbers,
                                        (value) {
                                          currentInput += value;
                                        },
                                      ),
                                      _buildKeypadButton(
                                        '5',
                                        setState,
                                        pressedNumbers,
                                        (value) {
                                          currentInput += value;
                                        },
                                      ),
                                      _buildKeypadButton(
                                        '6',
                                        setState,
                                        pressedNumbers,
                                        (value) {
                                          currentInput += value;
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                // 세 번째 행: 7, 8, 9
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 8,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      _buildKeypadButton(
                                        '7',
                                        setState,
                                        pressedNumbers,
                                        (value) {
                                          currentInput += value;
                                        },
                                      ),
                                      _buildKeypadButton(
                                        '8',
                                        setState,
                                        pressedNumbers,
                                        (value) {
                                          currentInput += value;
                                        },
                                      ),
                                      _buildKeypadButton(
                                        '9',
                                        setState,
                                        pressedNumbers,
                                        (value) {
                                          currentInput += value;
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                // 네 번째 행: 빈 공간, 0, 백스페이스
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 8,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      const SizedBox(width: 80), // 빈 공간 (7 아래)
                                      _buildKeypadButton(
                                        '0',
                                        setState,
                                        pressedNumbers,
                                        (value) {
                                          currentInput += value;
                                        },
                                      ), // 0 (8 아래)
                                      GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            if (currentInput.isNotEmpty) {
                                              currentInput = currentInput
                                                  .substring(
                                                    0,
                                                    currentInput.length - 1,
                                                  );
                                            }
                                          });
                                        },
                                        child: Container(
                                          width: 80, // 터치 영역 확대
                                          height: 80, // 터치 영역 확대
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              40,
                                            ),
                                          ),
                                          child: Image.asset(
                                            'assets/poster/behind.png',
                                            width: 24,
                                            height: 24,
                                            fit: BoxFit.contain,
                                          ),
                                        ),
                                      ), // 지우기 버튼 (9 아래)
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // 입력 완료 버튼
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 20,
                            ),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                            ),
                            child: Container(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed:
                                    currentInput.length >= 10
                                        ? () {
                                          setState(() {
                                            String formattedPhone =
                                                _formatPhoneNumber(
                                                  currentInput,
                                                );
                                            if (!phoneNumbers.contains(
                                              formattedPhone,
                                            )) {
                                              phoneNumbers.add(formattedPhone);
                                            }
                                            currentInput = '';
                                          });
                                        }
                                        : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      currentInput.length >= 10
                                          ? const Color(0xFF5D9EFF)
                                          : const Color(0xFFE5E5E5),
                                  padding: const EdgeInsets.all(16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text(
                                  '입력 완료',
                                  style: TextStyle(
                                    color:
                                        currentInput.length >= 10
                                            ? Colors.white
                                            : const Color(0xFF999999),
                                    fontSize: 12,
                                    fontFamily: 'Pretendard-Light',
                                    letterSpacing: -0.24,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // 바텀시트 높이 확보를 위한 여백
                          const SizedBox(height: 60),
                        ],
                      ),
                    ),
                  ),
                  // 하단 고정 같이하기 버튼
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(color: Colors.black),
                      child: SafeArea(
                        child: SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed:
                                phoneNumbers.length == targetCount
                                    ? () {
                                      print('===== 같이하기 버튼 클릭됨 =====');
                                      print(
                                        '전화번호 개수: ${phoneNumbers.length}/$targetCount',
                                      );
                                      print('전화번호 목록: $phoneNumbers');
                                      print(
                                        '구독권 정보: $title, $price, ${persons}인, 할인: $hasDiscount, 본인포함: $includeMyself',
                                      );

                                      Navigator.of(context).pop();
                                      // 확인 바텀시트 표시
                                      _showConfirmationBottomSheet(
                                        title,
                                        price,
                                        persons,
                                        hasDiscount,
                                        includeMyself,
                                        phoneNumbers,
                                      );
                                    }
                                    : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  phoneNumbers.length == targetCount
                                      ? Colors.black
                                      : const Color(0xFF666666),
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.zero,
                              ),
                            ),
                            child: Text(
                              '같이하기 (${phoneNumbers.length}/$targetCount)',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontFamily: 'Pretendard-Bold',
                                letterSpacing: -0.28,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // 키패드 버튼 생성 (터치 영역 개선)
  Widget _buildKeypadButton(
    String number,
    StateSetter setState,
    Set<String> pressedNumbers,
    Function(String) onTap,
  ) {
    bool isPressed = pressedNumbers.contains(number);

    return GestureDetector(
      onTapDown: (_) {
        setState(() {
          pressedNumbers.add(number);
        });
      },
      onTapUp: (_) {
        setState(() {
          pressedNumbers.remove(number);
          onTap(number);
        });
      },
      onTapCancel: () {
        setState(() {
          pressedNumbers.remove(number);
        });
      },
      child: Container(
        width: 80, // 터치 영역 확대
        height: 80, // 터치 영역 확대
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isPressed ? const Color(0xFFF0F0F0) : Colors.transparent,
          borderRadius: BorderRadius.circular(40),
        ),
        child: Text(
          number,
          textAlign: TextAlign.center,
          style: TextStyle(
            color:
                isPressed ? const Color(0xFF202020) : const Color(0xFFC4C4C4),
            fontSize: 24,
            fontFamily: 'Pretendard-Light',
            letterSpacing: -0.96,
          ),
        ),
      ),
    );
  }

  // 같이하기 바텀시트 (첫 번째 단계)
  Future<void> _showGiftBottomSheet() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          width: double.infinity,
          height: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: const ShapeDecoration(
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Text(
                            '같이하고 싶은 구독권의 옵션을 선택해 주세요',
                            style: TextStyle(
                              color: Color(0xFF202020),
                              fontSize: 14,
                              fontFamily: 'Pretendard-Bold',
                              letterSpacing: -0.28,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            width: 24,
                            height: 24,
                            child: const Icon(Icons.close, size: 24),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '같이하고 싶은 구독권 옵션을 선택해 주세요',
                      style: TextStyle(
                        color: Color(0xFF999999),
                        fontSize: 12,
                        fontFamily: 'Pretendard-Light',
                        letterSpacing: -0.24,
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(color: Colors.white),
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.only(
                        top: 8,
                        left: 16,
                        right: 16,
                        bottom: 8,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildGiftOption('1인 구독권', '₩3,500원', '월간', false),
                          Container(
                            width: double.infinity,
                            height: 1,
                            color: const Color(0xFFE5E5E5),
                          ),
                          _buildGiftOption('3인 구독권', '₩7,500원', '월간', false),
                          Container(
                            width: double.infinity,
                            height: 1,
                            color: const Color(0xFFE5E5E5),
                          ),
                          _buildGiftOption('5인 구독권', '₩9,500원', '월간', true),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(color: Colors.white),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      // 직접 같이하기가 아닌 옵션 선택 필요 메시지
                      print('위의 옵션 중 하나를 선택해주세요');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                    ),
                    child: const Text(
                      '같이하기',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontFamily: 'Pretendard-Bold',
                        letterSpacing: -0.32,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 선물 옵션 위젯 (수정된 버전)
  Widget _buildGiftOption(
    String title,
    String price,
    String period,
    bool hasDiscount,
  ) {
    return GestureDetector(
      onTap: () {
        // 구독권 타입에서 인원수 추출
        int persons = 1;
        if (title.contains('3인'))
          persons = 3;
        else if (title.contains('5인'))
          persons = 5;

        Navigator.of(context).pop(); // 현재 모달 닫기
        _showGiftDetailModal(title, price, persons, hasDiscount); // 다음 단계 모달 열기
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF202020),
                    fontSize: 16,
                    fontFamily: 'Pretendard-Bold',
                    letterSpacing: -0.32,
                  ),
                ),
                if (hasDiscount) ...[
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: ShapeDecoration(
                      color: const Color(0xFFFFA63D),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      '52% 할인!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontFamily: 'Pretendard-Bold',
                        letterSpacing: -0.20,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  price,
                  style: const TextStyle(
                    color: Color(0xFF666666),
                    fontSize: 12,
                    fontFamily: 'Pretendard-Regular',
                    letterSpacing: -0.24,
                  ),
                ),
                const Text(
                  ' · ',
                  style: TextStyle(
                    color: Color(0xFF666666),
                    fontSize: 12,
                    fontFamily: 'Pretendard-Regular',
                    letterSpacing: -0.24,
                  ),
                ),
                Text(
                  period,
                  style: const TextStyle(
                    color: Color(0xFF666666),
                    fontSize: 12,
                    fontFamily: 'Pretendard-Regular',
                    letterSpacing: -0.24,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 같이하기 옵션 선택 후 다음 단계 모달 (수정)
  Future<void> _showGiftDetailModal(
    String title,
    String price,
    int persons,
    bool hasDiscount,
  ) async {
    bool includeMyself = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Scaffold(
              backgroundColor: Colors.transparent,
              body: Stack(
                children: [
                  // 바텀시트 콘텐츠
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: double.infinity,
                      height: MediaQuery.of(context).size.height * 0.32,
                      child: Column(
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: const ShapeDecoration(
                              color: Colors.white,
                              shape: RoundedRectangleBorder(
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
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Expanded(
                                      child: Text(
                                        '구독권의 옵션을 선택해 주세요',
                                        style: TextStyle(
                                          color: Color(0xFF202020),
                                          fontSize: 16,
                                          fontFamily: 'Pretendard-Bold',
                                          letterSpacing: -0.64,
                                        ),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () => Navigator.of(context).pop(),
                                      child: Container(
                                        width: 24,
                                        height: 24,
                                        child: const Icon(
                                          Icons.close,
                                          size: 24,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  '같이하고 싶은 구독권 옵션을 선택해 주세요',
                                  style: TextStyle(
                                    color: Color(0xFF999999),
                                    fontSize: 12,
                                    fontFamily: 'Pretendard-Light',
                                    letterSpacing: -0.24,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Container(
                              width: double.infinity,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                              ),
                              child: SingleChildScrollView(
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                    top: 16,
                                    left: 16,
                                    right: 16,
                                    bottom: 16,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: double.infinity,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Text(
                                                  title,
                                                  style: const TextStyle(
                                                    color: Color(0xFF353535),
                                                    fontSize: 16,
                                                    fontFamily:
                                                        'Pretendard-Medium',
                                                    letterSpacing: -0.32,
                                                  ),
                                                ),
                                                if (hasDiscount) ...[
                                                  const SizedBox(width: 8),
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                          vertical: 4,
                                                        ),
                                                    decoration: ShapeDecoration(
                                                      color: const Color(
                                                        0xFFFFA63D,
                                                      ),
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              8,
                                                            ),
                                                      ),
                                                    ),
                                                    child: const Text(
                                                      '52% 할인!',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 10,
                                                        fontFamily:
                                                            'Pretendard-Bold',
                                                        letterSpacing: -0.20,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              price,
                                              style: const TextStyle(
                                                color: Color(0xFF3A88F4),
                                                fontSize: 16,
                                                fontFamily: 'Pretendard-Bold',
                                                letterSpacing: -0.32,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            includeMyself = !includeMyself;
                                          });
                                        },
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 20,
                                              height: 20,
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                  color:
                                                      includeMyself
                                                          ? const Color(
                                                            0xFF3A88F4,
                                                          )
                                                          : const Color(
                                                            0xFFCCCCCC,
                                                          ),
                                                  width: 2,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                                color:
                                                    includeMyself
                                                        ? const Color(
                                                          0xFF3A88F4,
                                                        )
                                                        : Colors.transparent,
                                              ),
                                              child:
                                                  includeMyself
                                                      ? const Icon(
                                                        Icons.check,
                                                        size: 14,
                                                        color: Colors.white,
                                                      )
                                                      : null,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              '나랑 함께 구독권을 이용할 거예요',
                                              style: TextStyle(
                                                color: const Color(0xFF666666),
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
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // 하단 고정 버튼 (전체 화면 하단)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(color: Colors.black),
                      child: SafeArea(
                        child: SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              // 전화번호 입력 바텀시트로 이동
                              _showPhoneInputBottomSheet(
                                title,
                                price,
                                persons,
                                hasDiscount,
                                includeMyself,
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.zero,
                              ),
                            ),
                            child: const Text(
                              '같이하기',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontFamily: 'Pretendard-Bold',
                                letterSpacing: -0.32,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // 전화번호 포맷팅
  String _formatPhoneNumber(String input) {
    if (input.length >= 11) {
      return '${input.substring(0, 3)}-${input.substring(3, 7)}-${input.substring(7, 11)}';
    } else if (input.length >= 7) {
      return '${input.substring(0, 3)}-${input.substring(3, 7)}-${input.substring(7)}';
    } else if (input.length >= 3) {
      return '${input.substring(0, 3)}-${input.substring(3)}';
    }
    return input;
  }

  // 확인 바텀시트 (같이하기 전 최종 확인)
  Future<void> _showConfirmationBottomSheet(
    String title,
    String price,
    int persons,
    bool hasDiscount,
    bool includeMyself,
    List<String> phoneNumbers,
  ) async {
    bool isChecked = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.55,
              child: Stack(
                children: [
                  // 메인 콘텐츠
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                    ),
                    child: Column(
                      children: [
                        // 헤더
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Expanded(
                                    child: Text(
                                      '잠깐! 결제 전 확인해 주세요',
                                      style: TextStyle(
                                        color: Color(0xFF202020),
                                        fontSize: 16,
                                        fontFamily: 'Pretendard-Bold',
                                        letterSpacing: -0.64,
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => Navigator.of(context).pop(),
                                    child: const Icon(Icons.close, size: 24),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                '구독권 구매 후에는 되돌릴 수 없습니다',
                                style: TextStyle(
                                  color: Color(0xFF999999),
                                  fontSize: 12,
                                  fontFamily: 'Pretendard-Light',
                                  letterSpacing: -0.24,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // 스크롤 가능한 내용
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 첫 번째 설명
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 20,
                                      height: 20,
                                      decoration: const ShapeDecoration(
                                        color: Color(0xFFFFD27F),
                                        shape: OvalBorder(),
                                      ),
                                      child: const Center(
                                        child: Text(
                                          '1',
                                          style: TextStyle(
                                            color: Color(0xFF001F55),
                                            fontSize: 9,
                                            fontFamily: 'Pretendard-Bold',
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            '타인에게만 공유했을 때, 함께 이용할 수 없어요',
                                            style: TextStyle(
                                              color: Color(0xFF4A4A4A),
                                              fontSize: 12,
                                              fontFamily: 'Pretendard-Medium',
                                              letterSpacing: -0.24,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          const Text(
                                            '이전 단계에서 나랑 함께 구독권 이용하기를 선택해야 함께 같은 구독권을 이용할 수 있어요',
                                            style: TextStyle(
                                              color: Color(0xFF999999),
                                              fontSize: 10,
                                              fontFamily: 'Pretendard-Light',
                                              height: 1.50,
                                              letterSpacing: -0.20,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                // 두 번째 설명
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 20,
                                      height: 20,
                                      decoration: const ShapeDecoration(
                                        color: Color(0xFFFFD27F),
                                        shape: OvalBorder(),
                                      ),
                                      child: const Center(
                                        child: Text(
                                          '2',
                                          style: TextStyle(
                                            color: Color(0xFF001F55),
                                            fontSize: 9,
                                            fontFamily: 'Pretendard-Bold',
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            '결제 완료 시, 구독권 변경은 한 달 후 가능해요',
                                            style: TextStyle(
                                              color: Color(0xFF4A4A4A),
                                              fontSize: 12,
                                              fontFamily: 'Pretendard-Medium',
                                              letterSpacing: -0.24,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          const Text(
                                            '이미 결제 완료한 구독권의 경우, 함께 이용하는 멤버들이 있어 환불이 어려워요. 다음 단계로 이동하기 전에, 한 번 더 확인해 주세요',
                                            style: TextStyle(
                                              color: Color(0xFF999999),
                                              fontSize: 10,
                                              fontFamily: 'Pretendard-Light',
                                              height: 1.50,
                                              letterSpacing: -0.20,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                // 세 번째 설명
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 20,
                                      height: 20,
                                      decoration: const ShapeDecoration(
                                        color: Color(0xFFFFD27F),
                                        shape: OvalBorder(),
                                      ),
                                      child: const Center(
                                        child: Text(
                                          '3',
                                          style: TextStyle(
                                            color: Color(0xFF001F55),
                                            fontSize: 9,
                                            fontFamily: 'Pretendard-Bold',
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            '이미 구독 중인 친구는 함께 이용할 수 없어요',
                                            style: TextStyle(
                                              color: Color(0xFF4A4A4A),
                                              fontSize: 12,
                                              fontFamily: 'Pretendard-Medium',
                                              letterSpacing: -0.24,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          const Text(
                                            '친구가 이미 리틀뱅크의 서비스를 구독 중이라면 아쉽지만 함께 멤버로 이용할 수 없어요. 구독 해지 후 멤버로 초대할 수 있습니다',
                                            style: TextStyle(
                                              color: Color(0xFF999999),
                                              fontSize: 10,
                                              fontFamily: 'Pretendard-Light',
                                              height: 1.50,
                                              letterSpacing: -0.20,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                // 체크박스
                                Row(
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          isChecked = !isChecked;
                                        });
                                      },
                                      child: Container(
                                        width: 20,
                                        height: 20,
                                        decoration: BoxDecoration(
                                          color:
                                              isChecked
                                                  ? const Color(0xFF146AFF)
                                                  : Colors.transparent,
                                          border: Border.all(
                                            color:
                                                isChecked
                                                    ? const Color(0xFF146AFF)
                                                    : const Color(0xFF999999),
                                            width: 1,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child:
                                            isChecked
                                                ? const Icon(
                                                  Icons.check,
                                                  size: 14,
                                                  color: Colors.white,
                                                )
                                                : null,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      '구독권에 대해 다 읽고 이해했어요',
                                      style: TextStyle(
                                        color: Color(0xFF999999),
                                        fontSize: 12,
                                        fontFamily: 'Pretendard-Light',
                                        letterSpacing: -0.24,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                // 구독권 선물하러 가기 버튼
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed:
                                        isChecked
                                            ? () async {
                                              Navigator.of(context).pop();

                                              // 구독권 생성 및 카톡 선물
                                              await _sendGiftToKakao(
                                                title,
                                                price,
                                                persons,
                                                hasDiscount,
                                                includeMyself,
                                                phoneNumbers,
                                              );
                                            }
                                            : null,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          isChecked
                                              ? const Color(0xFF146AFF)
                                              : const Color(0xFFE5E5E5),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 40,
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: Text(
                                      '구독권 선물하러 가기',
                                      style: TextStyle(
                                        color:
                                            isChecked
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
                                Center(
                                  child: Text(
                                    '언제든지 구독권 관리에서 확인할 수 있어요',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Color(0xFF8490A3),
                                      fontSize: 10,
                                      fontFamily: 'Pretendard-Light',
                                      letterSpacing: -0.20,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 60), // 하단 고정 버튼 공간
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 하단 고정 같이하기 버튼
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(color: Colors.black),
                      child: SafeArea(
                        child: SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed:
                                isChecked
                                    ? () async {
                                      Navigator.of(context).pop();

                                      // 구독권 생성 및 카톡 선물
                                      await _sendGiftToKakao(
                                        title,
                                        price,
                                        persons,
                                        hasDiscount,
                                        includeMyself,
                                        phoneNumbers,
                                      );
                                    }
                                    : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  isChecked
                                      ? Colors.black
                                      : const Color(0xFF666666),
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.zero,
                              ),
                            ),
                            child: const Text(
                              '같이하기',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontFamily: 'Pretendard-Bold',
                                letterSpacing: -0.28,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // 구독권 구매 처리
  Future<void> _processPurchase(
    String title,
    String price,
    int persons,
    bool hasDiscount,
    List<String> phoneNumbers,
  ) async {
    try {
      print('===== Google Play Billing 구독권 구매 시작 =====');
      print('구독권: $title');
      print('가격: $price');
      print('인원: $persons명');
      print('할인: $hasDiscount');
      print('전화번호 목록: ${phoneNumbers.join(', ')}');

      // Google Play Billing 사용 가능 여부 확인
      final billingService = BillingService();

      if (!billingService.isAvailable) {
        _showErrorDialog('Google Play 스토어를 사용할 수 없습니다.\n인터넷 연결을 확인해주세요.');
        return;
      }

      // 상품 ID 가져오기
      final productId = BillingService.getProductIdByPersons(persons);
      print('구매할 상품 ID: $productId');

      // 로딩 표시
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => AlertDialog(
              backgroundColor: Colors.white,
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  const Text(
                    'Google Play에서 결제를 진행하고 있습니다...',
                    style: TextStyle(
                      color: Color(0xFF666666),
                      fontSize: 14,
                      fontFamily: 'Pretendard-Regular',
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
      );

      // Google Play Billing으로 구매 진행
      await billingService.purchaseWithCallback(productId, (
        success,
        error,
      ) async {
        Navigator.of(context).pop(); // 로딩 닫기

        if (success) {
          print('✅ Google Play 결제 성공');

          // 서버에 구매 정보 전송 및 구독권 활성화
          try {
            // 로딩 다시 표시
            showDialog(
              context: context,
              barrierDismissible: false,
              builder:
                  (context) => const Center(child: CircularProgressIndicator()),
            );

            // 구글 인앱결제 구매 검증 API 사용
            final purchaseToken = billingService.lastPurchaseToken;
            if (purchaseToken == null) {
              Navigator.of(context).pop(); // 로딩 닫기
              _showErrorDialog('구매 토큰을 찾을 수 없습니다.');
              return;
            }

            // Google Play 서버 처리 대기 (2초)
            print('🔄 Google Play 서버 처리 대기 중...');
            await Future.delayed(const Duration(seconds: 2));

            var subscriptionResult =
                await SubscriptionService.validateGooglePlayPurchase(
                  packageName: "com.littlebank.littlebank",
                  productId: productId,
                  purchaseToken: purchaseToken,
                  includeOwner:
                      persons == 1
                          ? null
                          : false, // 1인 구독권은 null, 다인 구독권은 false (부모용 - 초대만)
                );

            if (subscriptionResult == null ||
                subscriptionResult['error'] == true) {
              Navigator.of(context).pop(); // 로딩 닫기
              final errorMessage =
                  subscriptionResult?['message'] ?? '구독권 활성화에 실패했습니다.';
              final errorCode = subscriptionResult?['code'] ?? '';

              // SS009 에러인 경우 기존 API로 fallback 시도
              if (errorCode == 'SS009') {
                print('💡 내부 테스트 환경 감지 - 기존 API로 대체 시도');

                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder:
                      (context) => AlertDialog(
                        backgroundColor: Colors.white,
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(height: 16),
                            const Text(
                              '내부 테스트 환경 감지\n기존 방식으로 구독권을 생성 중입니다...',
                              style: TextStyle(
                                color: Color(0xFF666666),
                                fontSize: 14,
                                fontFamily: 'Pretendard-Regular',
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                );

                try {
                  final fallbackResult =
                      await SubscriptionService.createSubscriptionWithPurchase(
                        seat: persons,
                        purchaseToken: purchaseToken,
                        includeOwner: true,
                      );
                  Navigator.of(context).pop(); // 로딩 닫기

                  if (fallbackResult != null) {
                    print('✅ 기존 API로 구독권 생성 성공');
                    subscriptionResult = fallbackResult;
                  } else {
                    _showErrorDialog('구독권 생성에 실패했습니다. 고객센터에 문의해주세요.');
                    return;
                  }
                } catch (e) {
                  Navigator.of(context).pop(); // 로딩 닫기
                  print('❌ 기존 API도 실패: $e');
                  _showErrorDialog('구독권 생성에 실패했습니다. 고객센터에 문의해주세요.');
                  return;
                }
              } else {
                _showErrorDialog(errorMessage);
                return;
              }
            }

            // 쿠폰코드 조회
            final inviteData = await SubscriptionService.getInviteCodes();
            Navigator.of(context).pop(); // 로딩 닫기

            if (inviteData != null && inviteData['inviteCodes'] != null) {
              final inviteCodes =
                  inviteData['inviteCodes'] as Map<String, dynamic>;

              // 사용 가능한 쿠폰코드 수집
              List<String> availableInviteCodes = [];
              for (String code in inviteCodes.keys) {
                if (inviteCodes[code] == null) {
                  availableInviteCodes.add(code);
                }
              }

              if (availableInviteCodes.isNotEmpty) {
                String sharedInviteCode = availableInviteCodes.first;

                // 카카오톡 전송 시도
                final shareSuccess =
                    await SubscriptionService.shareInviteCodeToKakao(
                      sharedInviteCode,
                      persons,
                    );

                // 실제 구매 가격 표시
                final product = billingService.getProduct(productId);
                final realPrice = product?.price ?? price;

                _showPurchaseCompletionDialog(
                  title: title,
                  price: realPrice,
                  originalPrice: _getOriginalPrice(persons),
                  discount: _getDiscountText(persons),
                  inviteCode: sharedInviteCode,
                  persons: persons,
                  isSuccess: shareSuccess,
                );
              } else {
                _showSuccessDialog('구독권 구매가 완료되었습니다!\n구독권이 즉시 활성화됩니다.');
              }
            } else {
              _showSuccessDialog('구독권 구매가 완료되었습니다!\n구독권이 즉시 활성화됩니다.');
            }
          } catch (e) {
            Navigator.of(context).pop(); // 로딩 닫기
            print('구독권 활성화 중 오류: $e');
            _showErrorDialog('구독권 활성화 중 오류가 발생했습니다: $e');
          }
        } else {
          print('❌ Google Play 결제 실패: $error');
          _showErrorDialog(error ?? '결제가 취소되거나 실패했습니다.');
        }
      });
    } catch (e) {
      Navigator.of(context).pop(); // 로딩 닫기
      print('❌ 구독권 구매 중 오류 발생: $e');
      _showErrorDialog('오류가 발생했습니다: $e');
    }
  }

  // 인원수에 따른 원래 가격 반환
  String _getOriginalPrice(int persons) {
    switch (persons) {
      case 1:
        return '₩3,500';
      case 3:
        return '₩10,500';
      case 5:
        return '₩17,500';
      default:
        return '₩3,500';
    }
  }

  // 인원수에 따른 할인 텍스트 반환
  String _getDiscountText(int persons) {
    switch (persons) {
      case 3:
        return '총 3,000원 할인 받았어요';
      case 5:
        return '총 8,000원 할인 받았어요';
      default:
        return '';
    }
  }

  // 선물하기: Google Play Billing으로 구매 후 카카오톡 공유
  Future<void> _giftPurchaseAndShare(
    String title,
    String price,
    int persons,
    bool hasDiscount,
    bool includeMyself,
    List<String> phoneNumbers,
  ) async {
    try {
      print('===== 구독권 선물 구매 시작 =====');
      print('구독권: $title');
      print('가격: $price');
      print('인원: $persons명');
      print('할인: $hasDiscount');
      print('본인 포함: $includeMyself');
      print('전화번호 목록: ${phoneNumbers.join(', ')}');

      // Google Play Billing 사용 가능 여부 확인
      final billingService = BillingService();

      if (!billingService.isAvailable) {
        _showErrorDialog('Google Play 스토어를 사용할 수 없습니다.\n인터넷 연결을 확인해주세요.');
        return;
      }

      // 상품 ID 가져오기
      final productId = BillingService.getProductIdByPersons(persons);
      print('구매할 상품 ID: $productId');

      // 로딩 표시
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => AlertDialog(
              backgroundColor: Colors.white,
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  const Text(
                    'Google Play에서 결제를 진행하고 있습니다...',
                    style: TextStyle(
                      color: Color(0xFF666666),
                      fontSize: 14,
                      fontFamily: 'Pretendard-Regular',
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
      );

      // Google Play Billing으로 구매 진행
      await billingService.purchaseWithCallback(productId, (
        success,
        error,
      ) async {
        Navigator.of(context).pop(); // 로딩 닫기

        if (success) {
          print('✅ Google Play 결제 성공');

          try {
            // 로딩 다시 표시
            showDialog(
              context: context,
              barrierDismissible: false,
              builder:
                  (context) => const Center(child: CircularProgressIndicator()),
            );

            // 구글 인앱결제 구매 검증 API 사용
            print('🔄 구독권 생성 중... (${persons}인 구독권, 본인포함: $includeMyself)');

            final purchaseToken = billingService.lastPurchaseToken;
            if (purchaseToken == null) {
              Navigator.of(context).pop(); // 로딩 닫기
              _showErrorDialog('구매 토큰을 찾을 수 없습니다.');
              return;
            }

            // Google Play 서버 처리 대기 (2초)
            print('🔄 Google Play 서버 처리 대기 중...');
            await Future.delayed(const Duration(seconds: 2));

            var subscriptionResult =
                await SubscriptionService.validateGooglePlayPurchase(
                  packageName: "com.littlebank.littlebank",
                  productId: productId,
                  purchaseToken: purchaseToken,
                  includeOwner: includeMyself, // 부모용은 false (초대만)
                );

            // 구독권 생성 결과 확인
            if (subscriptionResult == null ||
                (subscriptionResult['error'] == true)) {
              Navigator.of(context).pop(); // 로딩 닫기

              final errorMessage =
                  subscriptionResult?['message'] ?? '구독권 생성에 실패했습니다.';
              print('❌ 구독권 생성 실패: $errorMessage');
              _showErrorDialog(errorMessage);
              return;
            }

            print('구독권 생성 성공: $subscriptionResult');

            // 쿠폰코드 조회
            final inviteData = await SubscriptionService.getInviteCodes();
            Navigator.of(context).pop(); // 로딩 닫기

            if (inviteData != null && inviteData['inviteCodes'] != null) {
              final inviteCodes =
                  inviteData['inviteCodes'] as Map<String, dynamic>;

              // 사용 가능한 쿠폰코드 수집
              List<String> availableInviteCodes = [];
              for (String code in inviteCodes.keys) {
                if (inviteCodes[code] == null) {
                  availableInviteCodes.add(code);
                }
              }

              if (availableInviteCodes.isNotEmpty) {
                String sharedInviteCode = availableInviteCodes.first;

                // 카카오톡 전송 시도
                final shareSuccess =
                    await SubscriptionService.shareInviteCodeToKakao(
                      sharedInviteCode,
                      persons,
                    );

                // 실제 구매 가격 표시
                final product = billingService.getProduct(productId);
                final realPrice = product?.price ?? price;

                _showPurchaseCompletionDialog(
                  title: title,
                  price: realPrice,
                  originalPrice: _getOriginalPrice(persons),
                  discount: _getDiscountText(persons),
                  inviteCode: sharedInviteCode,
                  persons: persons,
                  isSuccess: shareSuccess,
                );
              } else {
                _showSuccessDialog('구독권 구매가 완료되었습니다!\n구독권이 즉시 활성화됩니다.');
              }
            } else {
              _showSuccessDialog('구독권 구매가 완료되었습니다!\n구독권이 즉시 활성화됩니다.');
            }
          } catch (e) {
            Navigator.of(context).pop(); // 로딩 닫기
            print('구독권 활성화 중 오류: $e');
            _showErrorDialog('구독권 활성화 중 오류가 발생했습니다: $e');
          }
        } else {
          print('❌ Google Play 결제 실패: $error');
          _showErrorDialog(error ?? '결제가 취소되거나 실패했습니다.');
        }
      });
    } catch (e) {
      Navigator.of(context).pop(); // 로딩 닫기 (안전장치)
      print('❌ 구독권 선물 구매 중 오류 발생: $e');
      _showErrorDialog('오류가 발생했습니다: $e');
    }
  }

  // 카톡으로 구독권 같이하기 (기존 메서드 - 이미 구독권이 있는 경우)
  Future<void> _sendGiftToKakao(
    String title,
    String price,
    int persons,
    bool hasDiscount,
    bool includeMyself,
    List<String> phoneNumbers,
  ) async {
    try {
      print('===== 구독권 같이하기 시작 =====');
      print('구독권: $title');
      print('가격: $price');
      print('인원: $persons명');
      print('할인: $hasDiscount');
      print('본인 포함: $includeMyself');
      print('전화번호 목록: ${phoneNumbers.join(', ')}');

      // 로딩 표시
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // 구독권 생성
      final subscriptionResult = await SubscriptionService.createSubscription(
        persons,
      );

      if (subscriptionResult == null) {
        Navigator.of(context).pop(); // 로딩 닫기
        _showErrorDialog('구독권 생성에 실패했습니다.');
        return;
      }

      print('구독권 생성 성공: $subscriptionResult');

      // 쿠폰코드 조회
      final inviteData = await SubscriptionService.getInviteCodes();

      if (inviteData == null || inviteData['inviteCodes'] == null) {
        Navigator.of(context).pop(); // 로딩 닫기
        _showErrorDialog('쿠폰코드 생성에 실패했습니다.');
        return;
      }

      final inviteCodes = inviteData['inviteCodes'] as Map<String, dynamic>;
      print('쿠폰코드 조회 성공: $inviteCodes');

      Navigator.of(context).pop(); // 로딩 닫기

      // 사용 가능한 모든 쿠폰코드 수집
      List<String> availableInviteCodes = [];
      for (String code in inviteCodes.keys) {
        if (inviteCodes[code] == null) {
          // null이면 사용 가능
          availableInviteCodes.add(code);
        }
      }

      if (availableInviteCodes.isNotEmpty) {
        print(
          '사용 가능한 쿠폰코드 ${availableInviteCodes.length}개: $availableInviteCodes',
        );

        // 전화번호 개수와 코드 개수 비교
        if (availableInviteCodes.length < phoneNumbers.length) {
          _showErrorDialog('초대코드가 부족합니다. 관리자에게 문의해주세요.');
          return;
        }

        // 1:1 매칭하여 각각 카카오톡 공유
        for (int i = 0; i < phoneNumbers.length; i++) {
          final code = availableInviteCodes[i];
          await SubscriptionService.shareInviteCodeToKakao(code, persons);
        }

        // 완료 안내
        _showSuccessDialog('초대코드가 모두 카카오톡으로 전송되었습니다!');
      } else {
        print('사용 가능한 쿠폰코드가 없습니다.');
        _showErrorDialog('사용 가능한 쿠폰코드가 없습니다.');
      }
    } catch (e) {
      Navigator.of(context).pop(); // 로딩 닫기
      print('구독권 같이하기 중 오류 발생: $e');
      _showErrorDialog('오류가 발생했습니다: $e');
    }
  }

  // 구독권 등록 성공 모달
  void _showSubscriptionSuccessModal() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              width: 358,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 358,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: const ShapeDecoration(
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
                        Container(
                          width: double.infinity,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: double.infinity,
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Expanded(
                                      child: Text(
                                        '구독권 등록이 완료됐어요!',
                                        style: TextStyle(
                                          color: Color(0xFF202020),
                                          fontSize: 16,
                                          fontFamily: 'Pretendard-Bold',
                                          letterSpacing: -0.64,
                                          height: 1.2,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    GestureDetector(
                                      onTap: () => Navigator.of(context).pop(),
                                      child: Container(
                                        width: 24,
                                        height: 24,
                                        child: const Icon(
                                          Icons.close,
                                          size: 18,
                                          color: Color(0xFF999999),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                '지금 바로 리틀뱅크의 혜택을 누려보세요',
                                style: TextStyle(
                                  color: Color(0xFF999999),
                                  fontSize: 14,
                                  fontFamily: 'Pretendard-Light',
                                  letterSpacing: -0.28,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 358,
                    height: 260,
                    padding: const EdgeInsets.all(15),
                    decoration: const ShapeDecoration(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(24),
                          bottomRight: Radius.circular(24),
                        ),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 230,
                          height: 230,
                          decoration: const BoxDecoration(
                            image: DecorationImage(
                              image: AssetImage(
                                "assets/icons/my/comple_subs.png",
                              ),
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  // 성공 다이얼로그 (새 디자인)
  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 24,
            ),
            child: SingleChildScrollView(
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 358),
                decoration: const ShapeDecoration(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(24)),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 상단 헤더
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Expanded(
                                child: Text(
                                  '구독권 결제가 완료되었어요!',
                                  style: TextStyle(
                                    color: Color(0xFF202020),
                                    fontSize: 18,
                                    fontFamily: 'Pretendard-Bold',
                                    letterSpacing: -0.72,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () => Navigator.of(context).pop(),
                                child: const Icon(Icons.close, size: 20),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '리틀뱅크의 더 많은 서비스를 이용해 보세요',
                            style: TextStyle(
                              color: Color(0xFF999999),
                              fontSize: 14,
                              fontFamily: 'Pretendard-Light',
                              letterSpacing: -0.28,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // 구분선
                    Container(
                      height: 1,
                      width: double.infinity,
                      color: const Color(0xFFF5F5F5),
                    ),
                    // 하단 상세 정보
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '결제 정보',
                            style: TextStyle(
                              color: Color(0xFF666666),
                              fontSize: 12,
                              fontFamily: 'Pretendard-Light',
                              letterSpacing: -0.24,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            '1인 구독권',
                            style: TextStyle(
                              color: Color(0xFF4A4A4A),
                              fontSize: 16,
                              fontFamily: 'Pretendard-Light',
                              letterSpacing: -0.32,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '3,500원',
                            style: TextStyle(
                              color: Color(0xFF146AFF),
                              fontSize: 20,
                              fontFamily: 'Pretendard-Bold',
                              letterSpacing: -0.80,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  // 에러 다이얼로그
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('오류'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('확인'),
              ),
            ],
          ),
    );
  }

  // 완료 다이얼로그 (더 상세한 정보 표시)
  void _showCompletionDialog(String title, String message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontFamily: 'Pretendard-Bold',
                color: Colors.black,
              ),
            ),
            content: Text(
              message,
              style: const TextStyle(
                fontSize: 14,
                fontFamily: 'Pretendard-Regular',
                color: Color(0xFF666666),
                height: 1.5,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFF146AFF),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  '확인',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontFamily: 'Pretendard-Medium',
                  ),
                ),
              ),
            ],
          ),
    );
  }

  // 구매/선물 완료 다이얼로그 (새 디자인)
  void _showPurchaseCompletionDialog({
    required String title,
    required String price,
    required String originalPrice,
    required String discount,
    required String inviteCode,
    required int persons,
    required bool isSuccess,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 24,
            ),
            child: SingleChildScrollView(
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 358),
                decoration: const ShapeDecoration(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(24)),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 상단 헤더
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Flexible(
                                child: Text(
                                  '구독권 결제가 완료되었어요!',
                                  style: TextStyle(
                                    color: Color(0xFF202020),
                                    fontSize: 18,
                                    fontFamily: 'Pretendard-Bold',
                                    letterSpacing: -0.72,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () => Navigator.of(context).pop(),
                                child: const Icon(Icons.close, size: 20),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isSuccess
                                ? '쿠폰코드가 카카오톡으로 전송되었습니다'
                                : '쿠폰코드를 친구들에게 공유해주세요',
                            style: const TextStyle(
                              color: Color(0xFF999999),
                              fontSize: 14,
                              fontFamily: 'Pretendard-Light',
                              letterSpacing: -0.28,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // 구분선
                    Container(
                      height: 1,
                      width: double.infinity,
                      color: const Color(0xFFF5F5F5),
                    ),
                    // 하단 상세 정보
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '결제 정보',
                            style: TextStyle(
                              color: Color(0xFF666666),
                              fontSize: 12,
                              fontFamily: 'Pretendard-Light',
                              letterSpacing: -0.24,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            title,
                            style: const TextStyle(
                              color: Color(0xFF4A4A4A),
                              fontSize: 16,
                              fontFamily: 'Pretendard-Light',
                              letterSpacing: -0.32,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Text(
                                price,
                                style: const TextStyle(
                                  color: Color(0xFF146AFF),
                                  fontSize: 20,
                                  fontFamily: 'Pretendard-Bold',
                                  letterSpacing: -0.80,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                originalPrice,
                                style: const TextStyle(
                                  color: Color(0xFF8490A3),
                                  fontSize: 16,
                                  fontFamily: 'Pretendard-Light',
                                  letterSpacing: -0.32,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: ShapeDecoration(
                              color: const Color(0xFFE7ECF6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFD9D9D9),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  discount,
                                  style: const TextStyle(
                                    color: Color(0xFF5D9EFF),
                                    fontSize: 12,
                                    fontFamily: 'Pretendard-Light',
                                    letterSpacing: -0.24,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!isSuccess) ...[
                            const SizedBox(height: 16),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: ShapeDecoration(
                                color: const Color(0xFFFFF4E6),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '쿠폰코드 (친구들과 공유하세요)',
                                    style: TextStyle(
                                      color: Color(0xFF666666),
                                      fontSize: 12,
                                      fontFamily: 'Pretendard-Light',
                                      letterSpacing: -0.20,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: ShapeDecoration(
                                      color: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        side: const BorderSide(
                                          color: Color(0xFF146AFF),
                                          width: 1,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      inviteCode,
                                      style: const TextStyle(
                                        color: Color(0xFF146AFF),
                                        fontSize: 16,
                                        fontFamily: 'Pretendard-Bold',
                                        letterSpacing: -0.32,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          '리틀뱅크혜택',
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontFamily: 'Pretendard-Bold',
            letterSpacing: -0.32,
          ),
        ),
        leading: IconButton(
          icon: Image.asset(
            'assets/icons/parent/뒤로가기.png',
            width: 20,
            height: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          children: [
            // 통합된 그라데이션 영역 - 로고, 설명글, 쿠폰코드 입력
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment(0.50, -0.00),
                  end: Alignment(0.50, 3.12),
                  colors: [Colors.white, Color(0xFF80FFD1)],
                ),
              ),
              child: Column(
                children: [
                  // 로고 영역
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 5),
                    child: Center(
                      child: Column(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  spreadRadius: 0,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Image.asset(
                              'assets/icons/sub_logo.png',
                              width: 60,
                              height: 60,
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),

                  // 프로필과 텍스트 사이 간격
                  const SizedBox(height: 20),

                  // 무료 체험 관련 텍스트
                  Column(
                    children: [
                      Text.rich(
                        TextSpan(
                          children: [
                            const TextSpan(
                              text: '잠깐! 받은 구독권 선물을 등록하고\n',
                              style: TextStyle(
                                color: Color(0xFF202020),
                                fontSize: 14,
                                fontFamily: 'Pretendard-Bold',
                                letterSpacing: -0.80,
                              ),
                            ),
                            const TextSpan(
                              text: '2주 무료',
                              style: TextStyle(
                                color: Color(0xFF3A88F4),
                                fontSize: 14,
                                fontFamily: 'Pretendard-Bold',
                                letterSpacing: -0.80,
                              ),
                            ),
                            const TextSpan(
                              text: '로 이용해 보세요',
                              style: TextStyle(
                                color: Color(0xFF202020),
                                fontSize: 14,
                                fontFamily: 'Pretendard-Bold',
                                letterSpacing: -0.80,
                              ),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        '무료 체험 기간에는 결제되지 않습니다',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF666666),
                          fontSize: 12,
                          fontFamily: 'Pretendard-Light',
                        ),
                      ),

                      // 쿠폰코드 입력 영역
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 20,
                        ),
                        child: Row(
                          children: [
                            // 입력 필드
                            Expanded(
                              child: Container(
                                height: 40,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: ShapeDecoration(
                                  color: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    side: const BorderSide(
                                      width: 0.80,
                                      color: Color(0xFFDADADA),
                                    ),
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                ),
                                child: TextField(
                                  controller: _couponCodeController,
                                  enabled: !_isCouponSubmitting,
                                  textInputAction: TextInputAction.done,
                                  keyboardType: TextInputType.text,
                                  textCapitalization:
                                      TextCapitalization.characters,
                                  onSubmitted: (_) => _submitCouponCode(),
                                  decoration: const InputDecoration(
                                    hintText: '쿠폰 코드를 입력해 주세요',
                                    hintStyle: TextStyle(
                                      color: Color(0xFF999999),
                                      fontSize: 14,
                                      fontFamily: 'Pretendard-Light',
                                      letterSpacing: -0.28,
                                    ),
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    disabledBorder: InputBorder.none,
                                    errorBorder: InputBorder.none,
                                    focusedErrorBorder: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                    isDense: false,
                                  ),
                                  textAlign: TextAlign.left,
                                  textAlignVertical: TextAlignVertical.center,
                                  style: const TextStyle(
                                    color: Color(0xFF202020),
                                    fontSize: 14,
                                    fontFamily: 'Pretendard-Regular',
                                    letterSpacing: -0.28,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // 입력완료 버튼
                            GestureDetector(
                              onTap:
                                  _isCouponSubmitting
                                      ? null
                                      : _submitCouponCode,
                              child: Container(
                                height: 40,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: ShapeDecoration(
                                  color:
                                      _isCouponSubmitting
                                          ? const Color(0xFFE5E5E5)
                                          : const Color(0xFF3A88F4),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                ),
                                child: Center(
                                  child:
                                      _isCouponSubmitting
                                          ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              color: Color(0xFF999999),
                                              strokeWidth: 2,
                                            ),
                                          )
                                          : const Text(
                                            '입력 완료',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontFamily: 'Pretendard-Light',
                                              letterSpacing: -0.24,
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
                ],
              ),
            ),

            // 할인 배너
            Container(
              width: double.infinity,
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: const BoxDecoration(color: Color(0xFF5D9EFF)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    child: Image.asset(
                      'assets/poster/sale.png',
                      width: 20,
                      height: 20,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          const TextSpan(
                            text: '3인 이상 구독 시, 최대 36%',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontFamily: 'Pretendard-Bold',
                              letterSpacing: -0.24,
                            ),
                          ),
                          const TextSpan(
                            text: '의 할인이 적용되었어요!',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontFamily: 'Pretendard-Light',
                              letterSpacing: -0.24,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 탭 메뉴 영역
            Container(
              width: double.infinity,
              height: 50,
              decoration: const BoxDecoration(
                color: Color(0xFF202020),
                border: Border(
                  bottom: BorderSide(color: Color(0xFF333333), width: 1),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildTabItem(0, '리틀뱅크란', _littleBankSectionKey),
                  _buildTabItem(1, '구독 혜택', _benefitsSectionKey),
                  _buildTabItem(2, '무료 체험', _freeTierSectionKey),
                ],
              ),
            ),

            // 구독관리.png 이미지와 스크롤 포인트
            Stack(
              children: [
                Image.asset(
                  'assets/poster/구독관리.png',
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    key: _littleBankSectionKey,
                    height: 5,
                    color: Colors.transparent,
                  ),
                ),
                Positioned(
                  top: MediaQuery.of(context).size.height * 0.5,
                  left: 0,
                  right: 0,
                  child: Container(
                    key: _benefitsSectionKey,
                    height: 5,
                    color: Colors.transparent,
                  ),
                ),
                Positioned(
                  top: MediaQuery.of(context).size.height * 1.1,
                  left: 0,
                  right: 0,
                  child: Container(
                    key: _freeTierSectionKey,
                    height: 5,
                    color: Colors.transparent,
                  ),
                ),
              ],
            ),

            // 하단 여백 제거 (이미지와 버튼 사이 공간 없애기)
          ],
        ),
      ),
      // 하단 고정 구독 버튼
      bottomNavigationBar: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.black,
          boxShadow: [
            BoxShadow(
              color: Color(0x5B000000),
              blurRadius: 8,
              offset: Offset(0, -4),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Row(
          children: [
            // 구매하기 버튼 (1인 구독권만)
            Expanded(
              child: GestureDetector(
                onTap:
                    _isSubscribing
                        ? null
                        : () {
                          ConfirmationBottomSheet.showGiftBottomSheet(context, (
                            title,
                            price,
                            persons,
                            hasDiscount,
                            includeMyself,
                            phoneNumbers,
                          ) {
                            _processPurchase(
                              title,
                              price,
                              persons,
                              hasDiscount,
                              phoneNumbers,
                            );
                          });
                        },
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color:
                        _isSubscribing ? const Color(0xFF666666) : Colors.black,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child:
                        _isSubscribing
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                            : const Text(
                              '구매하기',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontFamily: 'Pretendard-Bold',
                                letterSpacing: -0.32,
                              ),
                            ),
                  ),
                ),
              ),
            ),

            // 가운데 구분선
            Container(
              width: 1,
              height: 24,
              color: const Color(0xFF333333),
              margin: const EdgeInsets.symmetric(horizontal: 16),
            ),

            // 같이하기 버튼 (모든 옵션)
            Expanded(
              child: GestureDetector(
                onTap:
                    _isSubscribing
                        ? null
                        : () {
                          GiftOptionBottomSheet.show(context, (
                            title,
                            price,
                            persons,
                            hasDiscount,
                          ) {
                            // 바로 구매 확인 모달 표시
                            PurchaseConfirmationBottomSheet.show(
                              context,
                              title,
                              price,
                              persons,
                              hasDiscount,
                              [], // 빈 배열로 전달
                              (
                                title,
                                price,
                                persons,
                                hasDiscount,
                                phoneNumbers,
                              ) {
                                _giftPurchaseAndShare(
                                  title,
                                  price,
                                  persons,
                                  hasDiscount,
                                  false, // includeOwner는 false로 고정 (부모용 - 초대만)
                                  phoneNumbers,
                                );
                              },
                            );
                          });
                        },
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color:
                        _isSubscribing ? const Color(0xFF666666) : Colors.black,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '같이하기',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontFamily: 'Pretendard-Bold',
                        letterSpacing: -0.32,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 탭 아이템 위젯 빌더
  Widget _buildTabItem(int index, String title, GlobalKey sectionKey) {
    bool isSelected = _selectedTabIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTabIndex = index;
        });
        _scrollToSection(sectionKey);
      },
      child: Container(
        width: 120,
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF999999),
                  fontSize: 16,
                  fontFamily:
                      isSelected ? 'Pretendard-Bold' : 'Pretendard-Light',
                  letterSpacing: -0.32,
                ),
              ),
            ),
            Spacer(),
            if (isSelected)
              Container(width: 80, height: 2, color: Colors.white)
            else
              Container(height: 2, color: Colors.transparent),
          ],
        ),
      ),
    );
  }
}

// 점선 그리기 위한 CustomPainter
class DottedLinePainter extends CustomPainter {
  final Color color;

  const DottedLinePainter({this.color = const Color(0xFF999999)});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint =
        Paint()
          ..color = color
          ..strokeWidth = 1.0
          ..strokeCap = StrokeCap.round;

    const double dashWidth = 3.0;
    const double dashSpace = 3.0;
    double startX = 0.0;

    while (startX < size.width) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
