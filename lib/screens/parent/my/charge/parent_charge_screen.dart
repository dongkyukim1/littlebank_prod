import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:portone_flutter/iamport_payment.dart';
import 'package:portone_flutter/model/payment_data.dart';
import 'dart:math';
import 'parent_charge_complete_screen.dart';
import '../bank/parent_account_link_screen.dart';
import '../bank/change/account_change_screen.dart';
import '../../../child/bank/charge/charge_confirm_screen.dart';
import '../../../child/bank/toss_payment_screen.dart';
import '../../../../services/payment_service.dart';
import '../../../../services/auth_service.dart';

// PG사 정보 모델
class PaymentProvider {
  final String id;
  final String name;
  final String logo;
  final String pgCode;
  final String accountNumber;
  final String type; // 'portone' 또는 'toss'

  const PaymentProvider({
    required this.id,
    required this.name,
    required this.logo,
    required this.pgCode,
    required this.accountNumber,
    required this.type,
  });
}

class ParentChargeScreen extends StatefulWidget {
  const ParentChargeScreen({super.key});

  @override
  State<ParentChargeScreen> createState() => _ParentChargeScreenState();
}

class _ParentChargeScreenState extends State<ParentChargeScreen> {
  // 충전할 금액
  String chargeAmount = '0';
  int _amount = 0; // 실제 결제 금액 (숫자)

  // 금액 입력 컨트롤러
  final TextEditingController _amountController = TextEditingController();
  final FocusNode _amountFocusNode = FocusNode();
  bool _isAmountFocused = false;

  // 현재 적립금 (충전 전)
  String _currentBalance = '0';
  int _currentPoints = 0;

  // 사용자 계좌 정보
  String _userBankAccount = '';
  String _userBankName = '';

  // 충전 후 예상 금액
  String get totalAmount {
    final current = int.tryParse(_currentBalance.replaceAll(',', '')) ?? 0;
    final charge = int.tryParse(chargeAmount.replaceAll(',', '')) ?? 0;
    return _formatCurrency(current + charge);
  }

  // 선택된 빠른 금액 버튼 인덱스
  int? selectedAmountIndex;

  // 빠른 충전 금액 옵션
  final List<String> quickAmounts = ['+1만원', '+3만원', '+5만원', '+10만원'];

  // 로딩 상태
  bool _isLoading = false;

  // 유의사항 접기/펼치기 상태
  bool _isNoticeExpanded = true;

  // 스크롤 컨트롤러와 하단 영역 상태
  late ScrollController _scrollController;
  bool _showButtons = true;

  // 사용 가능한 PG사 목록 (포트원 + 토스페이먼츠)
  final List<PaymentProvider> _paymentProviders = [
    PaymentProvider(
      id: 'kakaopay',
      name: '카카오페이로 결제',
      logo: 'assets/logos/kakaopay.png',
      pgCode: 'kakaopay',
      accountNumber: '969802-01-010101',
      type: 'portone',
    ),
    PaymentProvider(
      id: 'tosspay',
      name: '토스페이로 결제',
      logo: 'assets/logos/tosspay.png',
      pgCode: 'tosspay',
      accountNumber: '969802-01-010102',
      type: 'portone',
    ),
    PaymentProvider(
      id: 'toss',
      name: '토스페이먼츠로 결제',
      logo: 'assets/logos/toss.png',
      pgCode: 'toss',
      accountNumber: '969802-01-010103',
      type: 'toss',
    ),
  ];

  // 선택된 PG사 (기본값: 카카오페이)
  late PaymentProvider _selectedProvider;

  @override
  void initState() {
    super.initState();
    _selectedProvider = _paymentProviders[0]; // 기본값: 카카오페이
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _fetchUserPoints();
    
    // 금액 입력 포커스 리스너 추가
    _amountFocusNode.addListener(() {
      setState(() {
        _isAmountFocused = _amountFocusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _amountController.dispose();
    _amountFocusNode.dispose();
    super.dispose();
  }

  void _onScroll() {
    // 스크롤 위치에 따라 하단 영역 내용 변경
    _updateButtonVisibility();
  }

  void _updateButtonVisibility() {
    // 스크롤을 맨 끝까지 내렸을 때만 사업자 정보 표시 (버튼 숨김)
    final shouldShowBusinessInfo =
        _scrollController.hasClients &&
        _scrollController.offset >= _scrollController.position.maxScrollExtent;

    if (shouldShowBusinessInfo && _showButtons) {
      setState(() {
        _showButtons = false;
      });
    } else if (!shouldShowBusinessInfo && !_showButtons) {
      setState(() {
        _showButtons = true;
      });
    }
  }

  // 사용자 포인트 조회
  Future<void> _fetchUserPoints() async {
    try {
      final userInfo = await AuthService.getUserInfo();
      final points = userInfo['point'] ?? 0;
      final bankAccount = userInfo['bankAccount'] ?? '';
      final bankName = userInfo['bankName'] ?? '';

      setState(() {
        _currentPoints = points;
        _currentBalance = _formatCurrency(points);
        _userBankAccount = bankAccount;
        _userBankName = bankName;
      });

      print('현재 사용자 포인트: $points');
      print('사용자 계좌: $bankName $bankAccount');
    } catch (e) {
      print('포인트 조회 실패: $e');
    }
  }

  // 금액 포맷팅 (천 단위 콤마)
  String _formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  // 계좌번호 포맷팅 (하이픈 추가)
  String _formatAccountNumber(String accountNumber) {
    // 숫자만 추출
    String numbersOnly = accountNumber.replaceAll(RegExp(r'[^0-9]'), '');

    if (numbersOnly.length >= 7) {
      // 4-2-나머지 형태로 포맷팅
      return '${numbersOnly.substring(0, 4)}-${numbersOnly.substring(4, 6)}-${numbersOnly.substring(6)}';
    }

    // 짧은 경우 원본 반환
    return accountNumber;
  }


  // PG사 선택 모달 표시
  void _showPaymentProviderSelectionModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 헤더
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '충전수단 선택',
                    style: TextStyle(
                      fontSize: 18,
                      fontFamily: 'Pretendard-Bold',
                      color: Colors.black,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(Icons.close, size: 24, color: Colors.grey),
                  ),
                ],
              ),

              SizedBox(height: 20),

              // PG사 목록
              ...List.generate(_paymentProviders.length, (index) {
                final provider = _paymentProviders[index];
                final isSelected = _selectedProvider.id == provider.id;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedProvider = provider;
                    });
                    Navigator.pop(context);
                  },
                  child: Container(
                    margin: EdgeInsets.only(bottom: 12),
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected ? Color(0xFFE7ECF6) : Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            isSelected ? Color(0xFF5D9EFF) : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        // PG사 로고
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              provider.logo,
                              width: 48,
                              height: 48,
                              fit: provider.id == 'kakaopay'
                                  ? BoxFit.cover
                                  : BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                // 로고 이미지가 없는 경우 기본 아이콘 표시
                                return Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.grey[200],
                                  ),
                                  child: Icon(
                                    Icons.payment,
                                    size: 24,
                                    color: Colors.grey,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),

                        SizedBox(width: 16),

                        // PG사 정보
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                provider.name,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontFamily: 'Pretendard-Medium',
                                  color: Colors.black,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                _formatAccountNumber(
                                  _userBankAccount.isNotEmpty
                                      ? _userBankAccount
                                      : provider.accountNumber,
                                ),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontFamily: 'Pretendard-Light',
                                  color: Colors.grey,
                                ),
                              ),
                              // 결제 방식 표시
                              SizedBox(height: 4),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: provider.type == 'toss'
                                      ? Colors.blue.withOpacity(0.1)
                                      : Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  provider.type == 'toss' ? '토스페이먼츠' : '포트원',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontFamily: 'Pretendard-Medium',
                                    color: provider.type == 'toss'
                                        ? Colors.blue
                                        : Colors.green,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // 선택 표시
                        if (isSelected)
                          Icon(
                            Icons.check_circle,
                            color: Color(0xFF5D9EFF),
                            size: 24,
                          ),
                      ],
                    ),
                  ),
                );
              }),

              SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  // 결제 처리 (토스페이먼츠 또는 포트원)
  Future<void> _processPayment() async {
    if (_selectedProvider.type == 'toss') {
      // 토스페이먼츠 결제
      await _processTossPayment();
    } else {
      // 포트원 결제
      await _processPortonePayment();
    }
  }

  // 토스페이먼츠 결제 처리
  Future<void> _processTossPayment() async {
    try {
      // 사용자 정보 가져오기
      final userInfo = await AuthService.getUserInfo();
      final email = userInfo['email'] ?? '';
      final name = userInfo['name'] ?? '사용자';
      final phone = userInfo['phone'] ?? '';

      // 금액에서 콤마 제거하고 숫자로 변환
      final int amount = int.parse(chargeAmount.replaceAll(',', ''));

      // 토스페이먼츠 결제 화면으로 이동
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TossPaymentScreen(
            amount: amount,
            customerName: name,
            customerEmail: email,
            customerMobilePhone: phone,
          ),
        ),
      );
    } catch (e) {
      print('토스페이먼츠 결제 오류: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('결제 처리 중 오류가 발생했습니다: $e')));
    }
  }

  // 포트원 결제 처리
  Future<void> _processPortonePayment() async {
    // 로딩 상태 시작
    setState(() {
      _isLoading = true;
    });

    try {
      // 사용자 정보 가져오기
      final userInfo = await AuthService.getUserInfo();
      final email = userInfo['email'] ?? '';
      final name = userInfo['name'] ?? '사용자';
      final phone = userInfo['phone'] ?? '';

      // 결제 고유 ID 생성 (주문번호)
      final String merchantUid =
          'order_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(100)}';

      // 금액에서 콤마 제거하고 숫자로 변환
      final int amount = int.parse(chargeAmount.replaceAll(',', ''));

      // 포트원 결제 페이지로 이동
      final paymentResult = await Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => IamportPayment(
                appBar: AppBar(
                  title: Text('포인트 충전'),
                  backgroundColor: Colors.white,
                  elevation: 0,
                  centerTitle: true,
                  leading: IconButton(
                    icon: Image.asset(
                      'assets/icons/parent/my/point/back.png',
                      width: 24,
                      height: 24,
                      errorBuilder:
                          (context, error, stackTrace) => Icon(
                            Icons.arrow_back_ios,
                            color: Colors.black,
                            size: 16,
                          ),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                initialChild: Container(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('결제 페이지로 이동 중입니다...'),
                      ],
                    ),
                  ),
                ),
                userCode: 'imp82563843', // 실제 가맹점 식별코드
                data: PaymentData(
                  pg: _selectedProvider.pgCode, // 선택된 PG사
                  payMethod: 'card', // 결제 방법
                  name: '포인트 충전', // 주문명
                  merchantUid: merchantUid, // 주문번호
                  amount: amount, // 결제금액 (정수형으로 변환)
                  buyerEmail: email, // 구매자 이메일
                  buyerName: name, // 구매자 이름
                  buyerTel: phone, // 구매자 연락처
                  appScheme: 'example', // 앱 스킴 (필요시 앱 스킴으로 설정)
                ),
                callback: (Map<String, String> result) {
                  Navigator.pop(context, result);
                },
              ),
        ),
      );

      // 로딩 상태 종료
      setState(() {
        _isLoading = false;
      });

      if (paymentResult == null) {
        // 결제 취소됨
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('결제가 취소되었습니다.')));
        return;
      }

      // 결제 결과 확인
      final impSuccess = paymentResult['imp_success'] == 'true';
      final impUid = paymentResult['imp_uid'] ?? '';

      if (impSuccess && impUid.isNotEmpty) {
        // 서버에 결제 정보 저장
        await PaymentService.savePayment(impUid);

        // 포인트 정보 갱신
        await _fetchUserPoints();

        // 충전확인 화면으로 이동 (결제 완료 후)
        final confirmResult = await Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => ChargeConfirmScreen(
                  amount: chargeAmount,
                  bankName: _selectedProvider.name.replaceAll('로 결제', ''),
                  currentBalance: _currentPoints,
                ),
          ),
        );

        // 충전확인 화면 완료 후 홈으로 이동
        Navigator.popUntil(context, (route) => route.isFirst);
      } else {
        // 결제 실패
        final errorMsg = paymentResult['error_msg'] ?? '결제에 실패했습니다.';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorMsg)));
      }
    } catch (e) {
      // 로딩 상태 종료
      setState(() {
        _isLoading = false;
      });

      // 오류 메시지 표시
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('결제 처리 중 오류가 발생했습니다: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Image.asset(
            'assets/icons/parent/my/point/back.png',
            width: 24,
            height: 24,
            errorBuilder:
                (context, error, stackTrace) =>
                    Icon(Icons.arrow_back_ios, color: Colors.black, size: 16),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '충전하기',
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontFamily: 'Pretendard-Bold',
            letterSpacing: -0.32,
          ),
        ),
        actions: [
          IconButton(
            icon: Image.asset(
              'assets/icons/parent/my/home.png',
              width: 24,
              height: 24,
              errorBuilder:
                  (context, error, stackTrace) =>
                      Icon(Icons.home, color: Colors.black, size: 24),
            ),
            onPressed: () {
              // 홈으로 이동
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // 메인 컨텐츠 (스크롤 가능)
          SingleChildScrollView(
            controller: _scrollController,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 24),

                  // 계좌 정보 섹션
                  Container(
                    width: 358,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    decoration: ShapeDecoration(
                      color: const Color(0xFFE7ECF6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              padding:
                                  _selectedProvider.id == 'kakaopay'
                                      ? EdgeInsets.zero
                                      : EdgeInsets.all(2),
                              decoration: ShapeDecoration(
                                color: Colors.white,
                                shape: OvalBorder(),
                              ),
                              child: Container(
                                decoration: ShapeDecoration(
                                  image: DecorationImage(
                                    image: AssetImage(_selectedProvider.logo),
                                    fit:
                                        _selectedProvider.id == 'kakaopay'
                                            ? BoxFit.cover
                                            : BoxFit.contain,
                                  ),
                                  shape: OvalBorder(),
                                ),
                              ),
                            ),
                            SizedBox(width: 16),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _selectedProvider.name,
                                      style: TextStyle(
                                        color: const Color(0xFF4A4A4A),
                                        fontSize: 14,
                                        fontFamily: 'Pretendard-Light',
                                        letterSpacing: -0.28,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      _formatAccountNumber(
                                        _userBankAccount.isNotEmpty
                                            ? _userBankAccount
                                            : _selectedProvider.accountNumber,
                                      ),
                                      style: TextStyle(
                                        color: const Color(0xFF999999),
                                        fontSize: 12,
                                        fontFamily: 'Pretendard-Light',
                                        letterSpacing: -0.24,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 16),
                                GestureDetector(
                                  onTap: _showPaymentProviderSelectionModal,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    decoration: ShapeDecoration(
                                      color: const Color(0xFF5D9EFF),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Text(
                                          '충전수단 변경',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontFamily: 'Pretendard-Light',
                                            letterSpacing: -0.22,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: ShapeDecoration(
                            color: const Color(0xFFFFD27F),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                '내 계좌',
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
                      ],
                    ),
                  ),

                  SizedBox(height: 24),

                  // 충전 후 현재 내 적립금
                  Row(
                    children: [
                      Text(
                        '충전 후 나의 포인트',
                        style: TextStyle(
                          color: const Color(0xFF001F55),
                          fontSize: 14,
                          fontFamily: 'Pretendard-Light',
                          letterSpacing: -0.28,
                        ),
                      ),
                      SizedBox(width: 4),
                      Text(
                        '$totalAmount원',
                        style: TextStyle(
                          color: const Color(0xFF001F55),
                          fontSize: 16,
                          fontFamily: 'Pretendard-Bold',
                          letterSpacing: -0.32,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 20),

                  // 금액 입력 영역
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _amountController,
                                focusNode: _amountFocusNode,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  TextInputFormatter.withFunction((
                                    oldValue,
                                    newValue,
                                  ) {
                                    if (newValue.text.isEmpty) {
                                      return newValue;
                                    }

                                    // 숫자만 추출
                                    final number =
                                        int.tryParse(
                                          newValue.text.replaceAll(',', ''),
                                        ) ??
                                        0;

                                    // 최대 금액 제한 (1,000,000원)
                                    if (number > 1000000) {
                                      return oldValue;
                                    }

                                    // 천 단위 콤마 추가
                                    final formatted = number
                                        .toString()
                                        .replaceAllMapped(
                                          RegExp(
                                            r'(\d{1,3})(?=(\d{3})+(?!\d))',
                                          ),
                                          (Match m) => '${m[1]},',
                                        );

                                    return TextEditingValue(
                                      text: formatted,
                                      selection: TextSelection.collapsed(
                                        offset: formatted.length,
                                      ),
                                    );
                                  }),
                                ],
                                style: TextStyle(
                                  color: const Color(0xFF202020),
                                  fontSize: 28,
                                  fontFamily: 'Pretendard-Bold',
                                  letterSpacing: -1.12,
                                ),
                                decoration: InputDecoration(
                                  hintText: '금액을 입력해주세요',
                                  hintStyle: TextStyle(
                                    color: const Color(0xFFAAAAAA),
                                    fontSize: 20,
                                    fontFamily: 'Pretendard-Light',
                                    letterSpacing: -0.8,
                                  ),
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                onChanged: (value) {
                                  setState(() {
                                    if (value.isEmpty) {
                                      chargeAmount = '0';
                                      _amount = 0;
                                      selectedAmountIndex = null;
                                    } else {
                                      chargeAmount = value;
                                      _amount =
                                          int.tryParse(
                                            value.replaceAll(',', ''),
                                          ) ??
                                          0;
                                      selectedAmountIndex =
                                          null; // 직접 입력 시 빠른 선택 해제
                                    }
                                    _updateButtonVisibility();
                                  });
                                },
                              ),
                            ),
                            if (_amount > 0) ...[
                              SizedBox(width: 4),
                              Text(
                                '원',
                                style: TextStyle(
                                  color: const Color(0xFF202020),
                                  fontSize: 24,
                                  fontFamily: 'Pretendard-Light',
                                  letterSpacing: -0.96,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      // X 버튼 추가 (금액이 입력된 경우만 표시)
                      if (_amount > 0) ...[
                        SizedBox(width: 16),
                        InkWell(
                          onTap: () {
                            setState(() {
                              _amountController.clear();
                              chargeAmount = '0';
                              _amount = 0;
                              selectedAmountIndex = null;
                              _updateButtonVisibility();
                            });
                          },
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: const Color(0xFFAAAAAA),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),

                  SizedBox(height: 8),

                  // 구분선
                  Container(
                    height: 1,
                    color:
                        (_isAmountFocused || _amount > 0)
                            ? const Color(0xFF5D9EFF)
                            : const Color(0xFFDDDDDD),
                  ),

                  SizedBox(height: 16),

                  // 빠른 금액 선택 버튼
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: List.generate(
                        quickAmounts.length,
                        (index) => _buildQuickAmountButton(index),
                      ),
                    ),
                  ),

                  SizedBox(height: 24),

                  // 충전 안내 내역
                  Container(
                    width: double.infinity,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 헤더
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _isNoticeExpanded = !_isNoticeExpanded;
                              });
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  '충전 시 유의사항',
                                  style: TextStyle(
                                    color: const Color(0xFF202020),
                                    fontSize: 14,
                                    fontFamily: 'Pretendard-Bold',
                                    letterSpacing: -0.32,
                                  ),
                                ),
                                Container(
                                  width: 24,
                                  height: 24,
                                  clipBehavior: Clip.antiAlias,
                                  decoration: BoxDecoration(),
                                  child: Image.asset(
                                    'assets/icons/open.png',
                                    width: 24,
                                    height: 24,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // 간격 추가
                        SizedBox(height: 16),

                        // 안내 박스들 (조건부 렌더링)
                        if (_isNoticeExpanded)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // PG사 연결 안내
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 12,
                                  ),
                                  margin: const EdgeInsets.only(bottom: 20),
                                  decoration: ShapeDecoration(
                                    color: const Color(0xFFF0F0F0),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Column(
                                              mainAxisSize: MainAxisSize.min,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.start,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.center,
                                                  children: [
                                                    Image.asset(
                                                      'assets/icons/Fill_inform.png',
                                                      width: 16,
                                                      height: 16,
                                                    ),
                                                    SizedBox(width: 4),
                                                    Text(
                                                      'PG사 연결 안내',
                                                      style: TextStyle(
                                                        color: const Color(
                                                          0xFF202020,
                                                        ),
                                                        fontSize: 12,
                                                        fontFamily:
                                                            'Pretendard-Bold',
                                                        letterSpacing: -0.24,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                SizedBox(height: 12),
                                                Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.start,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'PG사 연결을 완료하셔야 충전이 정상적으로 진행됩니다. 연결은 최초 1회만 필요하며, 이후에는 별도의 절차 없이 자동으로 진행됩니다.',
                                                      style: TextStyle(
                                                        color: const Color(
                                                          0xFF4A4A4A,
                                                        ),
                                                        fontSize: 11,
                                                        fontFamily:
                                                            'Pretendard-Light',
                                                        height: 1.45,
                                                        letterSpacing: -0.22,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // 최소 충전 금액 및 충전 한도 안내
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 12,
                                  ),
                                  margin: const EdgeInsets.only(bottom: 20),
                                  decoration: ShapeDecoration(
                                    color: const Color(0xFFF0F0F0),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Column(
                                              mainAxisSize: MainAxisSize.min,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.start,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.center,
                                                  children: [
                                                    Image.asset(
                                                      'assets/icons/Fill_inform.png',
                                                      width: 16,
                                                      height: 16,
                                                    ),
                                                    SizedBox(width: 4),
                                                    Expanded(
                                                      child: Text(
                                                        '최소 충전 금액 및 충전 한도 안내',
                                                        style: TextStyle(
                                                          color: const Color(
                                                            0xFF202020,
                                                          ),
                                                          fontSize: 12,
                                                          fontFamily:
                                                              'Pretendard-Bold',
                                                          letterSpacing: -0.24,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                SizedBox(height: 12),
                                                Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.start,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      '1회 최소 충전 금액은 1,000원이며, 최대 10만원까지 한 번에 충전할 수 있습니다.\n충전 완료 후, 포인트는 즉시 반영됩니다.',
                                                      style: TextStyle(
                                                        color: const Color(
                                                          0xFF4A4A4A,
                                                        ),
                                                        fontSize: 11,
                                                        fontFamily:
                                                            'Pretendard-Light',
                                                        height: 1.45,
                                                        letterSpacing: -0.22,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // 충전 실패 시 고객센터 문의 안내
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 12,
                                  ),
                                  margin: const EdgeInsets.only(bottom: 20),
                                  decoration: ShapeDecoration(
                                    color: const Color(0xFFF0F0F0),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Column(
                                              mainAxisSize: MainAxisSize.min,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.start,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.center,
                                                  children: [
                                                    Image.asset(
                                                      'assets/icons/Fill_inform.png',
                                                      width: 16,
                                                      height: 16,
                                                    ),
                                                    SizedBox(width: 4),
                                                    Expanded(
                                                      child: Text(
                                                        '충전 실패 시, 고객센터로 문의 바랍니다.',
                                                        style: TextStyle(
                                                          color: const Color(
                                                            0xFF202020,
                                                          ),
                                                          fontSize: 12,
                                                          fontFamily:
                                                              'Pretendard-Bold',
                                                          letterSpacing: -0.24,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                SizedBox(height: 12),
                                                Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.start,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      '계좌 오류 및 부정확한 정보 입력으로 인한 충전 실패 시, 별도 재지급 요청을 하셔야 합니다. 자세한 사항은 이용 약관 및 고객센터를 통해 확인해 주세요.',
                                                      style: TextStyle(
                                                        color: const Color(
                                                          0xFF4A4A4A,
                                                        ),
                                                        fontSize: 11,
                                                        fontFamily:
                                                            'Pretendard-Light',
                                                        height: 1.45,
                                                        letterSpacing: -0.22,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // 계좌 변경 안내
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 12,
                                  ),
                                  decoration: ShapeDecoration(
                                    color: const Color(0xFFF0F0F0),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Column(
                                              mainAxisSize: MainAxisSize.min,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.start,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.center,
                                                  children: [
                                                    Image.asset(
                                                      'assets/icons/Fill_inform.png',
                                                      width: 16,
                                                      height: 16,
                                                    ),
                                                    SizedBox(width: 4),
                                                    Expanded(
                                                      child: Text(
                                                        '다른 충전 수단을 이용하고 싶다면 계좌 변경을 선택해 주세요',
                                                        style: TextStyle(
                                                          color: const Color(
                                                            0xFF202020,
                                                          ),
                                                          fontSize: 12,
                                                          fontFamily:
                                                              'Pretendard-Bold',
                                                          letterSpacing: -0.24,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                SizedBox(height: 12),
                                                Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.start,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      '하나의 계좌만 연결 가능하므로, 다른 계좌로 변경을 원하신다면 하단의 계좌 변경 버튼을 선택하여 원하는 계좌로 변경해 주세요.',
                                                      style: TextStyle(
                                                        color: const Color(
                                                          0xFF4A4A4A,
                                                        ),
                                                        fontSize: 11,
                                                        fontFamily:
                                                            'Pretendard-Light',
                                                        height: 1.45,
                                                        letterSpacing: -0.22,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
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
                      ],
                    ),
                  ),

                  // 하단 버튼 위치 확보
                  SizedBox(height: 200),
                ],
              ),
            ),
          ),

          // 로딩 인디케이터
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(child: CircularProgressIndicator()),
            ),

          // 하단 고정 영역 (조건부)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(
                    color:
                        _showButtons
                            ? const Color(0xFFF1F1F1)
                            : const Color(0xFF666666),
                    width: 0.40,
                  ),
                ),
              ),
              child:
                  _showButtons
                      ?
                      // 기본 상태: 계좌변경/충전하기 버튼
                      Row(
                        children: [
                          // 계좌 변경 버튼
                          Expanded(
                            flex: 2,
                            child: Container(
                              height: 49,
                              margin: EdgeInsets.only(right: 12),
                              child: ElevatedButton(
                                onPressed: () {
                                  // 계좌 변경 - 계좌 변경 화면으로 이동
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => AccountChangeScreen(),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: const Color(0xFF89DA8D),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    side: BorderSide.none,
                                  ),
                                  padding: EdgeInsets.zero,
                                ),
                                child: Ink(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        const Color(0xFF89DA8D),
                                        const Color(0xFF5D9EFF),
                                      ],
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(7),
                                    ),
                                    margin: EdgeInsets.all(1.5),
                                    alignment: Alignment.center,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Image.asset(
                                          'assets/icons/my/변경.png',
                                          width: 20,
                                          height: 20,
                                        ),
                                        SizedBox(width: 6),
                                        Text(
                                          '계좌변경',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontFamily: 'Pretendard-Light',
                                            letterSpacing: -0.28,
                                            color: const Color(0xFF89DA8D),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // 충전하기 버튼
                          Expanded(
                            flex: 3,
                            child: SizedBox(
                              height: 49,
                              child: ElevatedButton(
                                onPressed:
                                    (_isLoading || _amount <= 0)
                                        ? null
                                        : _processPayment,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  foregroundColor: Colors.white,
                                  disabledForegroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: EdgeInsets.zero,
                                ),
                                child: Ink(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors:
                                          (_isLoading || _amount <= 0)
                                              ? [
                                                const Color(
                                                  0xFF89DA8D,
                                                ).withOpacity(0.5),
                                                const Color(
                                                  0xFF5D9EFF,
                                                ).withOpacity(0.5),
                                              ]
                                              : [
                                                const Color(0xFF89DA8D),
                                                const Color(0xFF5D9EFF),
                                              ],
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Container(
                                    alignment: Alignment.center,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.add_circle_outline,
                                          size: 20,
                                          color: Colors.white,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          '충전하기',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontFamily: 'Pretendard-Light',
                                            letterSpacing: -0.28,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                      :
                      // 스크롤 시: 사업자 정보
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // 상단 링크들
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 4,
                            children: [
                              Text(
                                '고객센터',
                                style: TextStyle(
                                  color: const Color(0xFF999999),
                                  fontSize: 11,
                                  fontFamily: 'Pretendard-Light',
                                  height: 1.45,
                                  letterSpacing: -0.22,
                                ),
                              ),
                              Text(
                                '|',
                                style: TextStyle(
                                  color: const Color(0xFFCCCCCC),
                                  fontSize: 11,
                                  fontFamily: 'Pretendard-Light',
                                  height: 1.45,
                                  letterSpacing: -0.22,
                                ),
                              ),
                              Text(
                                '이용약관',
                                style: TextStyle(
                                  color: const Color(0xFF999999),
                                  fontSize: 11,
                                  fontFamily: 'Pretendard-Light',
                                  height: 1.45,
                                  letterSpacing: -0.22,
                                ),
                              ),
                              Text(
                                '|',
                                style: TextStyle(
                                  color: const Color(0xFFCCCCCC),
                                  fontSize: 11,
                                  fontFamily: 'Pretendard-Light',
                                  height: 1.45,
                                  letterSpacing: -0.22,
                                ),
                              ),
                              Text(
                                '개인정보처리방침',
                                style: TextStyle(
                                  color: const Color(0xFF999999),
                                  fontSize: 11,
                                  fontFamily: 'Pretendard-Light',
                                  height: 1.45,
                                  letterSpacing: -0.22,
                                ),
                              ),
                              Text(
                                '|',
                                style: TextStyle(
                                  color: const Color(0xFFCCCCCC),
                                  fontSize: 11,
                                  fontFamily: 'Pretendard-Light',
                                  height: 1.45,
                                  letterSpacing: -0.22,
                                ),
                              ),
                              Text(
                                '전자금융거래약관',
                                style: TextStyle(
                                  color: const Color(0xFF999999),
                                  fontSize: 11,
                                  fontFamily: 'Pretendard-Light',
                                  height: 1.45,
                                  letterSpacing: -0.22,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          // 사업자 정보
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 4,
                            runSpacing: 4,
                            children: [
                              Text(
                                '상호명',
                                style: TextStyle(
                                  color: const Color(0xFFC4C4C4),
                                  fontSize: 11,
                                  fontFamily: 'Pretendard-Light',
                                  height: 1.45,
                                  letterSpacing: -0.22,
                                ),
                              ),
                              Text(
                                '시원팍팍',
                                style: TextStyle(
                                  color: const Color(0xFF999999),
                                  fontSize: 11,
                                  fontFamily: 'Pretendard-Light',
                                  height: 1.45,
                                  letterSpacing: -0.22,
                                ),
                              ),
                              Text(
                                '|',
                                style: TextStyle(
                                  color: const Color(0xFFCCCCCC),
                                  fontSize: 11,
                                  fontFamily: 'Pretendard-Light',
                                  height: 1.45,
                                  letterSpacing: -0.22,
                                ),
                              ),
                              Text(
                                '사업자 등록 번호',
                                style: TextStyle(
                                  color: const Color(0xFFC4C4C4),
                                  fontSize: 11,
                                  fontFamily: 'Pretendard-Light',
                                  height: 1.45,
                                  letterSpacing: -0.22,
                                ),
                              ),
                              Text(
                                '215-24-34845',
                                style: TextStyle(
                                  color: const Color(0xFF999999),
                                  fontSize: 11,
                                  fontFamily: 'Pretendard-Light',
                                  height: 1.45,
                                  letterSpacing: -0.22,
                                ),
                              ),
                              Text(
                                '|',
                                style: TextStyle(
                                  color: const Color(0xFFCCCCCC),
                                  fontSize: 11,
                                  fontFamily: 'Pretendard-Light',
                                  height: 1.45,
                                  letterSpacing: -0.22,
                                ),
                              ),
                              Text(
                                '대표',
                                style: TextStyle(
                                  color: const Color(0xFFC4C4C4),
                                  fontSize: 11,
                                  fontFamily: 'Pretendard-Light',
                                  height: 1.45,
                                  letterSpacing: -0.22,
                                ),
                              ),
                              Text(
                                '정순',
                                style: TextStyle(
                                  color: const Color(0xFF999999),
                                  fontSize: 11,
                                  fontFamily: 'Pretendard-Light',
                                  height: 1.45,
                                  letterSpacing: -0.22,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 4),
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 4,
                            children: [
                              Text(
                                '주소',
                                style: TextStyle(
                                  color: const Color(0xFFC4C4C4),
                                  fontSize: 11,
                                  fontFamily: 'Pretendard-Light',
                                  height: 1.45,
                                  letterSpacing: -0.22,
                                ),
                              ),
                              Text(
                                '서울특별시 송파구 백제고분로 12길 7-5, 601 (잠실동)',
                                style: TextStyle(
                                  color: const Color(0xFF999999),
                                  fontSize: 11,
                                  fontFamily: 'Pretendard-Light',
                                  height: 1.45,
                                  letterSpacing: -0.22,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 4),
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 4,
                            children: [
                              Text(
                                '번호',
                                style: TextStyle(
                                  color: const Color(0xFFC4C4C4),
                                  fontSize: 11,
                                  fontFamily: 'Pretendard-Light',
                                  height: 1.45,
                                  letterSpacing: -0.22,
                                ),
                              ),
                              Text(
                                '02-575-1071',
                                style: TextStyle(
                                  color: const Color(0xFF999999),
                                  fontSize: 11,
                                  fontFamily: 'Pretendard-Light',
                                  height: 1.45,
                                  letterSpacing: -0.22,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
            ),
          ),
        ],
      ),
    );
  }

  // 빠른 금액 선택 버튼 위젯
  Widget _buildQuickAmountButton(int index) {
    final bool isSelected = selectedAmountIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedAmountIndex = index;

          // 금액 업데이트 로직
          final amount = quickAmounts[index];
          if (amount == '+1만원') {
            chargeAmount = '10,000';
            _amount = 10000;
          } else if (amount == '+3만원') {
            chargeAmount = '30,000';
            _amount = 30000;
          } else if (amount == '+5만원') {
            chargeAmount = '50,000';
            _amount = 50000;
          } else if (amount == '+10만원') {
            chargeAmount = '100,000';
            _amount = 100000;
          }

          // TextField 업데이트
          _amountController.text = chargeAmount;

          // 버튼 표시 상태 업데이트
          _updateButtonVisibility();
        });
      },
      child: Container(
        margin: EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: ShapeDecoration(
          color:
              isSelected
                  ? const Color(0xFF5D9EFF).withOpacity(0.1)
                  : const Color(0xFFEFF2F6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
            side:
                isSelected
                    ? BorderSide(color: const Color(0xFF5D9EFF), width: 1)
                    : BorderSide.none,
          ),
        ),
        child: Text(
          quickAmounts[index],
          style: TextStyle(
            color:
                isSelected ? const Color(0xFF5D9EFF) : const Color(0xFF001F55),
            fontSize: 11,
            fontFamily: 'Pretendard-Medium',
            letterSpacing: -0.22,
          ),
        ),
      ),
    );
  }
}
