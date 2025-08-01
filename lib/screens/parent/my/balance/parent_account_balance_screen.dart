import 'package:flutter/material.dart';
import '../../../../widgets/parent/bottom_navigation_bar.dart';
import '../charge/parent_charge_screen.dart';
import '../../../../services/auth_service.dart';
import '../../../../services/payment_service.dart';

class ParentAccountBalanceScreen extends StatefulWidget {
  const ParentAccountBalanceScreen({super.key});

  @override
  State<ParentAccountBalanceScreen> createState() =>
      _ParentAccountBalanceScreenState();
}

class _ParentAccountBalanceScreenState
    extends State<ParentAccountBalanceScreen> {
  // 현재 선택된 탭 인덱스 (0: 충전 포인트, 1: 보낸 포인트, 2: 꺼낸 포인트)
  int _selectedTabIndex = 0;

  // 로딩 상태 관리
  bool _isLoading = true;
  String? _errorMessage;

  // 사용자 데이터
  Map<String, dynamic>? _userInfo;
  int _currentPoints = 0;
  int _totalPoints = 0;

  // 거래 내역 데이터
  List<Map<String, dynamic>> _chargeTransactions = []; // 충전 포인트 내역
  List<Map<String, dynamic>> _sentTransactions = []; // 보낸 포인트 내역
  List<Map<String, dynamic>> _withdrawnTransactions = <Map<String, dynamic>>[
    <String, dynamic>{
      'requestedAt': '2025-06-15T09:35:00.000Z',
      'requestedAmount': 20000,
      'processedAmount': 19600,
      'status': 'COMPLETED',
    },
    <String, dynamic>{
      'requestedAt': '2025-06-15T04:33:00.000Z',
      'requestedAmount': 35000,
      'processedAmount': 34300,
      'status': 'COMPLETED',
    },
  ]; // 꺼낸 포인트 내역

  // 꺼낸 포인트 내역 로딩 상태
  bool _isWithdrawnLoading = false;
  String? _withdrawnError;

  // 꺼낸 포인트 내역 데이터 (목업)
  final List<Map<String, dynamic>> _mockWithdrawnHistory = [
    {
      'requestedAt': '2025-06-15T09:35:00.000Z',
      'requestedAmount': 20000,
      'processedAmount': 19600,
      'status': 'COMPLETED',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // 사용자 데이터 로딩
  Future<void> _loadUserData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // 사용자 정보 가져오기
      final userInfo = await AuthService.getUserInfo();

      // 현재 포인트를 사용자 정보에서 직접 가져오기
      final currentPoints = userInfo['point'] ?? 0;

      // 총 누적 포인트는 기존 방식 유지 (충전 내역에서 계산)
      final totalPoints = await PaymentService.getTotalPoints();

      // 충전 내역 가져오기
      final chargeResponse = await PaymentService.getChargeHistory(
        pageNumber: 0,
      );
      print('충전 내역 응답: $chargeResponse'); // 디버깅용 로그 추가

      List<Map<String, dynamic>> chargeTransactions = [];
      if (chargeResponse.containsKey('data') &&
          chargeResponse['data'] is List) {
        chargeTransactions = List<Map<String, dynamic>>.from(
          chargeResponse['data'],
        );
      }

      // 보낸 포인트 내역 가져오기
      final sentResponse = await PaymentService.getSentPointHistory(
        pageNumber: 0,
      );
      List<Map<String, dynamic>> sentTransactions = [];
      if (sentResponse.containsKey('data') && sentResponse['data'] is List) {
        sentTransactions = List<Map<String, dynamic>>.from(
          sentResponse['data'],
        );
      }

      // 꺼낸 포인트 내역 가져오기
      final refundResponse = await PaymentService.getRefundHistory(
        pageNumber: 0,
      );
      List<Map<String, dynamic>> withdrawnTransactions = [];
      if (refundResponse.containsKey('data') &&
          refundResponse['data'] is List) {
        withdrawnTransactions = List<Map<String, dynamic>>.from(
          refundResponse['data'],
        );
      }

      if (mounted) {
        setState(() {
          _userInfo = userInfo;
          _currentPoints = currentPoints;
          _totalPoints = totalPoints;
          _chargeTransactions = chargeTransactions;
          _sentTransactions = sentTransactions;
          _withdrawnTransactions = withdrawnTransactions;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
      print('사용자 데이터 로딩 오류: $e');
    }
  }

  // 거래 내역 로딩
  Future<void> _loadTransactionHistory() async {
    try {
      setState(() {
        _isWithdrawnLoading = true;
        _withdrawnError = null;
      });

      // 꺼낸 포인트 내역 가져오기
      final refundResponse = await PaymentService.getRefundHistory(
        pageNumber: 0,
      );

      if (mounted) {
        setState(() {
          if (refundResponse.containsKey('data') &&
              refundResponse['data'] is List) {
            _withdrawnTransactions = List<Map<String, dynamic>>.from(
              refundResponse['data'],
            );
          } else {
            _withdrawnTransactions = [];
          }
          _isWithdrawnLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _withdrawnError = e.toString();
          _isWithdrawnLoading = false;
        });
      }
      print('거래 내역 로딩 오류: $e');
    }
  }

  // 금액 포맷팅 (천 단위 콤마)
  String _formatCurrency(dynamic amount) {
    final int value =
        amount is int ? amount : int.tryParse(amount.toString()) ?? 0;
    return value.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  // 날짜 포맷팅 (MM월 dd일 요일)
  String _formatDate(String isoDate) {
    try {
      final DateTime date = DateTime.parse(isoDate);
      final List<String> weekdays = ['월', '화', '수', '목', '금', '토', '일'];
      final String weekday = weekdays[date.weekday - 1];
      return '${date.month}월 ${date.day}일 ${weekday}요일';
    } catch (e) {
      return isoDate;
    }
  }

  // 시간 포맷팅 (HH:mm)
  String _formatTime(String isoDate) {
    try {
      final DateTime date = DateTime.parse(isoDate);
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return '';
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
        title: const Text(
          '총 포인트 내역',
          style: TextStyle(
            color: Colors.black,
            fontSize: 14,
            fontWeight: FontWeight.bold,
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
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 계좌 정보 카드
                  _buildAccountInfoCard(),

                  // 탭 바 (여백 없이)
                  _buildTabs(),

                  // 계좌 내역 섹션
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        // 내역 수 및 검색
                        _buildTransactionHistory(),

                        // 내역 리스트
                        if (_selectedTabIndex == 0)
                          _buildChargeHistoryList()
                        else if (_selectedTabIndex == 1)
                          _buildSentPointHistoryList()
                        else
                          _buildWithdrawnHistoryList(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Color(0x26000000),
              blurRadius: 8,
              offset: Offset(0, -4),
              spreadRadius: 0,
            ),
          ],
        ),
        child: GestureDetector(
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ParentChargeScreen(),
              ),
            );
            if (mounted && result != null) {
              _loadUserData();
            }
          },
          child: Container(
            width: double.infinity,
            height: 49,
            decoration: ShapeDecoration(
              gradient: LinearGradient(
                begin: Alignment(-0.99, -0.14),
                end: Alignment(0.99, 0.14),
                colors: [Color(0xFF89DA8D), Color(0xFF5D9EFF)],
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/icons/parent/my/balance/charge.png',
                    width: 20,
                    height: 20,
                    errorBuilder:
                        (context, error, stackTrace) => Icon(
                          Icons.add_circle_outline,
                          color: Colors.white,
                          size: 20,
                        ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    '충전하기',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontFamily: 'Pretendard-Light',
                      letterSpacing: -0.28,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 계좌 정보 카드 위젯
  Widget _buildAccountInfoCard() {
    // 꺼낸 포인트 탭일 때는 다른 디자인 사용
    if (_selectedTabIndex == 2) {
      return Container(
        width: MediaQuery.of(context).size.width,
        height: 120,
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(color: const Color(0xFF5D9EFF)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '오늘까지 총 포인트에서 꺼낸 금액이',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w700,
                height: 1.1,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '415,000원',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w700,
                letterSpacing: -0.8,
              ),
            ),
            const SizedBox(height: 6),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '꺼내기 요청한 금액은 ',
                    style: TextStyle(
                      color: const Color(0xFF001F55),
                      fontSize: 13,
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w300,
                      letterSpacing: -0.26,
                    ),
                  ),
                  TextSpan(
                    text: '+ 483,000원',
                    style: TextStyle(
                      color: const Color(0xFF001F55),
                      fontSize: 13,
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.26,
                    ),
                  ),
                  TextSpan(
                    text: '입니다',
                    style: TextStyle(
                      color: const Color(0xFF001F55),
                      fontSize: 13,
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w300,
                      letterSpacing: -0.26,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // 기존 계좌 정보 카드 디자인 (다른 탭들에서 사용)
    final bankName = _userInfo?['bankName'] ?? '은행 정보 없음';
    final bankAccount = _userInfo?['bankAccount'] ?? '계좌 정보 없음';

    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: ShapeDecoration(
        color: const Color(0xFFEFF2F6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                  height: 32,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        left: 0,
                        top: 0,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: ShapeDecoration(
                            color: Colors.white,
                            shape: OvalBorder(),
                          ),
                          child: ClipOval(
                            child: Builder(
                              builder: (context) {
                                final logoPath = _getBankLogo(bankName);
                                if (logoPath.isEmpty) {
                                  return Center(
                                    child: Text(
                                      bankName.substring(0, 1),
                                      style: TextStyle(
                                        color: Color(0xFF666666),
                                        fontSize: 14,
                                        fontFamily: 'Pretendard-Medium',
                                      ),
                                    ),
                                  );
                                }
                                return Image.asset(
                                  logoPath,
                                  width: 32,
                                  height: 32,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    print('Error loading bank logo: $error');
                                    return Center(
                                      child: Text(
                                        bankName.substring(0, 1),
                                        style: TextStyle(
                                          color: Color(0xFF666666),
                                          fontSize: 14,
                                          fontFamily: 'Pretendard-Medium',
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 48,
                        top: 0,
                        right: 50,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 4,
                              children: [
                                Text(
                                  bankName,
                                  style: TextStyle(
                                    color: const Color(0xFF666666),
                                    fontSize: 11,
                                    fontFamily: 'Pretendard-Light',
                                    letterSpacing: -0.22,
                                  ),
                                ),
                                Text(
                                  _getBankProductName(bankName),
                                  style: TextStyle(
                                    color: const Color(0xFF666666),
                                    fontSize: 11,
                                    fontFamily: 'Pretendard-Light',
                                    letterSpacing: -0.22,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 4),
                            Text(
                              _formatAccountNumber(bankAccount),
                              overflow: TextOverflow.visible,
                              softWrap: true,
                              style: TextStyle(
                                color: const Color(0xFF999999),
                                fontSize: 11,
                                fontFamily: 'Pretendard-Light',
                                letterSpacing: -0.22,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        right: 0,
                        top: 0,
                        child: GestureDetector(
                          onTap: () {
                            // 바텀 시트 열기
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(24),
                                ),
                              ),
                              builder: (context) => AccountManageBottomSheet(),
                            );
                          },
                          child: Icon(
                            Icons.more_vert,
                            color: Colors.grey[400],
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        '현재 용돈이 될 수 있는 포인트는',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: const Color(0xFF202020),
                          fontSize: 12,
                          fontFamily: 'Pretendard-Medium',
                          letterSpacing: -0.24,
                        ),
                      ),
                      SizedBox(height: 2),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            '${_formatCurrency(_currentPoints)}원',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: const Color(0xFF206AFF),
                              fontSize: 16,
                              fontFamily: 'Pretendard-Bold',
                              letterSpacing: -0.64,
                            ),
                          ),
                          SizedBox(width: 6),
                          Image.asset(
                            'assets/icons/parent/bank/qna.png',
                            width: 18,
                            height: 18,
                            errorBuilder:
                                (context, error, stackTrace) => Icon(
                                  Icons.help_outline,
                                  color: Colors.grey[400],
                                  size: 18,
                                ),
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
    );
  }

  // 은행 로고 이미지 경로 반환
  String _getBankLogo(String bankName) {
    // 은행 이름에 따른 로고 파일명 매핑
    Map<String, String> bankLogoMap = {
      '카카오뱅크': 'bankName=카카오뱅크_new',
      '국민은행': 'kb_bank',
      'KB국민': 'kb_bank',
      '신한은행': 'shinhan_bank',
      '우리은행': 'woori_bank',
      '하나은행': 'hana_bank',
      '토스뱅크': 'toss',
      '케이뱅크': 'kbank',
      '농협은행': 'nh_bank',
      'NH농협': 'nh_bank',
      '기업은행': 'ibk_bank',
      'IBK기업': 'ibk_bank',
      '수협은행': 'suhyup_bank',
      'SC은행': 'sc_bank',
      '씨티은행': 'citi_bank',
      '대구은행': 'daegu_bank',
      'DGB대구': 'daegu_bank',
      '부산은행': 'busan_bank',
      'BNK부산': 'busan_bank',
      '광주은행': 'gwangju_bank',
      '제주은행': 'bankName=제주',
      '전북은행': 'jeonbuk_bank',
      '경남은행': 'kyongnam_bank',
      '새마을금고': 'saemaul',
      'MG새마을': 'saemaul',
      '카카오페이': 'kakaopay',
      '토스페이': 'tosspay',
    };

    String logoFileName = bankLogoMap[bankName] ?? '';
    return logoFileName.isEmpty ? '' : 'assets/logos/$logoFileName.png';
  }

  // 은행 상품명 반환
  String _getBankProductName(String bankName) {
    switch (bankName) {
      case '국민은행':
        return 'KB Star*t 통장';
      case '신한은행':
        return '신한 S20 통장';
      case '우리은행':
        return '우리 위비 통장';
      default:
        return '일반 통장';
    }
  }

  // 계좌번호 포맷팅
  String _formatAccountNumber(String accountNumber) {
    if (accountNumber.length > 6) {
      return accountNumber.substring(0, 6) +
          '-' +
          accountNumber.substring(6, 8) +
          '-' +
          accountNumber.substring(8);
    }
    return accountNumber;
  }

  // 계좌 내역 섹션 위젯
  Widget _buildAccountHistorySection() {
    // 현재 선택된 탭에 따른 데이터
    final historyData =
        _selectedTabIndex == 0
            ? _chargeTransactions
            : _selectedTabIndex == 1
            ? _sentTransactions
            : _withdrawnTransactions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 회색 박스와 탭 사이 간격 줄임
        SizedBox(height: 12),

        // 들어온 돈 / 나간 돈 탭
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.grey.withOpacity(0.3), width: 1),
            ),
          ),
          child: Row(
            children: [
              // 충전 포인트 탭
              Expanded(
                flex: 1,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedTabIndex = 0;
                    });
                  },
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color:
                              _selectedTabIndex == 0
                                  ? Colors.black
                                  : Colors.transparent,
                          width: 2.5,
                        ),
                      ),
                    ),
                    child: Text(
                      '충전 포인트',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color:
                            _selectedTabIndex == 0
                                ? Colors.black
                                : const Color(0xFFCCCCCC),
                        fontSize: 13,
                        fontFamily:
                            _selectedTabIndex == 0
                                ? 'Pretendard-Bold'
                                : 'Pretendard-Light',
                        letterSpacing: -0.30,
                      ),
                    ),
                  ),
                ),
              ),
              // 보낸 포인트 탭
              Expanded(
                flex: 1,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedTabIndex = 1;
                    });
                  },
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color:
                              _selectedTabIndex == 1
                                  ? Colors.black
                                  : Colors.transparent,
                          width: 2.5,
                        ),
                      ),
                    ),
                    child: Text(
                      '보낸 포인트',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color:
                            _selectedTabIndex == 1
                                ? Colors.black
                                : const Color(0xFFCCCCCC),
                        fontSize: 13,
                        fontFamily:
                            _selectedTabIndex == 1
                                ? 'Pretendard-Bold'
                                : 'Pretendard-Light',
                        letterSpacing: -0.30,
                      ),
                    ),
                  ),
                ),
              ),
              // 꺼낸 포인트 탭
              Expanded(
                flex: 1,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedTabIndex = 2;
                    });
                  },
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color:
                              _selectedTabIndex == 2
                                  ? Colors.black
                                  : Colors.transparent,
                          width: 2.5,
                        ),
                      ),
                    ),
                    child: Text(
                      '꺼낸 포인트',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color:
                            _selectedTabIndex == 2
                                ? Colors.black
                                : const Color(0xFFCCCCCC),
                        fontSize: 13,
                        fontFamily:
                            _selectedTabIndex == 2
                                ? 'Pretendard-Bold'
                                : 'Pretendard-Light',
                        letterSpacing: -0.30,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // 거래 내역 섹션 빌드
        _buildTransactionHistory(),

        // 내역이 없을 때 표시
        if (_selectedTabIndex != 2 && historyData.isEmpty)
          Container(
            padding: EdgeInsets.all(40),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  SizedBox(height: 16),
                  Text(
                    _selectedTabIndex == 0
                        ? '충전 포인트 내역이 없습니다'
                        : _selectedTabIndex == 1
                        ? '보낸 포인트 내역이 없습니다'
                        : '꺼낸 포인트 내역이 없습니다',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                      fontFamily: 'Pretendard-Medium',
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    _selectedTabIndex == 0
                        ? '포인트를 충전하면 내역이 표시됩니다'
                        : _selectedTabIndex == 1
                        ? '포인트를 보내면 내역이 표시됩니다'
                        : '포인트를 꺼내면 내역이 표시됩니다',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                      fontFamily: 'Pretendard-Light',
                    ),
                  ),
                ],
              ),
            ),
          )
        else if (_selectedTabIndex == 2)
          // 꺼낸 포인트 내역 리스트
          _buildWithdrawnHistoryList(),
      ],
    );
  }

  // 거래 내역 섹션 빌드
  Widget _buildTransactionHistory() {
    // 현재 선택된 탭에 따른 데이터
    final historyData =
        _selectedTabIndex == 0
            ? _chargeTransactions
            : _selectedTabIndex == 1
            ? _sentTransactions
            : _withdrawnTransactions;

    // 전체 내역 수 계산
    final totalCount = historyData.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 전체 내역 및 개수
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(color: Colors.white),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 전체 내역 수
              Padding(
                padding: const EdgeInsets.only(left: 0),
                child: Row(
                  children: [
                    Text(
                      '전체 내역 ',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 14,
                        fontFamily: 'Pretendard-Medium',
                      ),
                    ),
                    Text(
                      '$totalCount',
                      style: TextStyle(
                        color: Color(0xFF3A88F4),
                        fontSize: 15,
                        fontFamily: 'Pretendard-SemiBold',
                      ),
                    ),
                  ],
                ),
              ),

              // 필터 아이콘
              GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                    ),
                    builder: (context) => FilterBottomSheet(),
                  );
                },
                child: Image.asset(
                  'assets/icons/my/필터.png',
                  width: 22,
                  height: 22,
                ),
              ),
            ],
          ),
        ),

        // 검색 아이콘
        Container(
          padding: const EdgeInsets.symmetric(vertical: 2),
          alignment: Alignment.centerLeft,
          child: Image.asset('assets/icons/my/검색.png', width: 24, height: 24),
        ),
      ],
    );
  }

  // 꺼낸 포인트 내역 섹션 빌드
  Widget _buildWithdrawnHistoryList() {
    if (_isLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: CircularProgressIndicator(color: Color(0xFF5D9DFF)),
        ),
      );
    }

    if (_withdrawnTransactions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(50.0),
          child: Column(
            children: [
              Icon(
                Icons.account_balance_wallet_outlined,
                size: 48,
                color: Colors.grey[400],
              ),
              SizedBox(height: 16),
              Text(
                '꺼낸 포인트 내역이 없습니다',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                  fontFamily: 'Pretendard-Medium',
                ),
              ),
              SizedBox(height: 8),
              Text(
                '포인트를 꺼내면 내역이 표시됩니다',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                  fontFamily: 'Pretendard-Light',
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 날짜별로 그룹화
    Map<String, List<Map<String, dynamic>>> groupedData = {};
    for (var item in _withdrawnTransactions) {
      final dateKey = _formatDate(item['requestedAt'] ?? '');
      if (!groupedData.containsKey(dateKey)) {
        groupedData[dateKey] = [];
      }
      groupedData[dateKey]!.add(item);
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: groupedData.keys.length,
      itemBuilder: (context, index) {
        final dateKey = groupedData.keys.elementAt(index);
        final items = groupedData[dateKey]!;

        return Container(
          width: double.infinity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 0),
                child: Text(
                  dateKey,
                  style: TextStyle(
                    color: const Color(0xFF8490A3),
                    fontSize: 12,
                    fontFamily: 'Pretendard-Light',
                    letterSpacing: -0.24,
                  ),
                ),
              ),
              SizedBox(height: 16),
              ...items.map((item) => _buildWithdrawnHistoryItem(item)).toList(),
            ],
          ),
        );
      },
    );
  }

  // 꺼낸 포인트 개별 아이템
  Widget _buildWithdrawnHistoryItem(Map<String, dynamic> item) {
    final requestedAmount = item['requestedAmount'] ?? 0;
    final processedAmount = item['processedAmount'] ?? 0;
    final feeAmount = requestedAmount - processedAmount;
    final feePercentage = '2'; // 수수료 2% 고정

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16, left: 20, right: 20),
      padding: const EdgeInsets.all(12),
      decoration: ShapeDecoration(
        color: const Color(0xFFE7ECF6),
        shape: RoundedRectangleBorder(
          side: BorderSide(width: 0.80, color: const Color(0xFF5D9EFF)),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Column(
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
                '실제 받은 금액',
                style: TextStyle(
                  color: const Color(0xFF8490A3),
                  fontSize: 12,
                  fontFamily: 'Pretendard-Light',
                  letterSpacing: -0.24,
                ),
              ),
              SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: const Color(0xFF3A88F4),
                          width: 1.0,
                        ),
                      ),
                    ),
                    child: Text(
                      '${_formatCurrency(processedAmount)}원',
                      style: TextStyle(
                        color: const Color(0xFF3A88F4),
                        fontSize: 18,
                        fontFamily: 'Pretendard-Bold',
                        letterSpacing: -0.72,
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '(',
                          style: TextStyle(
                            color: const Color(0xFF8490A3),
                            fontSize: 10,
                            fontFamily: 'Pretendard-Light',
                            letterSpacing: -0.20,
                          ),
                        ),
                        TextSpan(
                          text: '${feePercentage}%',
                          style: TextStyle(
                            color: const Color(0xFF8490A3),
                            fontSize: 10,
                            fontFamily: 'Pretendard-Medium',
                            letterSpacing: -0.20,
                          ),
                        ),
                        TextSpan(
                          text: '의 수수료 발생)',
                          style: TextStyle(
                            color: const Color(0xFF8490A3),
                            fontSize: 10,
                            fontFamily: 'Pretendard-Light',
                            letterSpacing: -0.20,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '꺼내기 요청일',
                    style: TextStyle(
                      color: const Color(0xFF8490A3),
                      fontSize: 12,
                      fontFamily: 'Pretendard-Light',
                      letterSpacing: -0.24,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '꺼내기 요청한 금액',
                    style: TextStyle(
                      color: const Color(0xFF8490A3),
                      fontSize: 12,
                      fontFamily: 'Pretendard-Light',
                      letterSpacing: -0.24,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '발생한 수수료',
                    style: TextStyle(
                      color: const Color(0xFF8490A3),
                      fontSize: 12,
                      fontFamily: 'Pretendard-Light',
                      letterSpacing: -0.24,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Text(
                        _formatDate(item['requestedAt'] ?? ''),
                        style: TextStyle(
                          color: const Color(0xFF001F55),
                          fontSize: 12,
                          fontFamily: 'Pretendard-Light',
                          letterSpacing: -0.24,
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        _formatTime(item['requestedAt'] ?? ''),
                        style: TextStyle(
                          color: const Color(0xFF999999),
                          fontSize: 10,
                          fontFamily: 'Pretendard-Light',
                          letterSpacing: -0.20,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    '${_formatCurrency(requestedAmount)}원',
                    style: TextStyle(
                      color: const Color(0xFF001F55),
                      fontSize: 12,
                      fontFamily: 'Pretendard-Light',
                      letterSpacing: -0.24,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '-${_formatCurrency(feeAmount)}원',
                    style: TextStyle(
                      color: const Color(0xFF3A88F4),
                      fontSize: 12,
                      fontFamily: 'Pretendard-Medium',
                      letterSpacing: -0.24,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 충전 내역 목록
  Widget _buildChargeHistoryList() {
    if (_isLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: CircularProgressIndicator(color: Color(0xFF5D9DFF)),
        ),
      );
    }

    if (_chargeTransactions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(50.0),
          child: Column(
            children: [
              Icon(Icons.receipt_long, size: 48, color: Colors.grey[400]),
              SizedBox(height: 16),
              Text(
                '충전 내역이 없습니다',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                  fontFamily: 'Pretendard-Medium',
                ),
              ),
              SizedBox(height: 8),
              Text(
                '포인트를 충전하면 내역이 표시됩니다',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                  fontFamily: 'Pretendard-Light',
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 날짜별로 그룹화
    Map<String, List<Map<String, dynamic>>> groupedData = {};
    for (var item in _chargeTransactions) {
      final dateKey = _formatDate(item['paidAt'] ?? '');
      if (!groupedData.containsKey(dateKey)) {
        groupedData[dateKey] = [];
      }
      groupedData[dateKey]!.add(item);
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: groupedData.keys.length,
      itemBuilder: (context, index) {
        final dateKey = groupedData.keys.elementAt(index);
        final items = groupedData[dateKey]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 날짜 헤더
            Container(
              padding: EdgeInsets.fromLTRB(0, 8, 0, 0),
              child: Text(
                dateKey,
                style: TextStyle(
                  color: Color(0xFF999999),
                  fontSize: 12,
                  fontFamily: 'Pretendard-Medium',
                ),
              ),
            ),

            // 해당 날짜의 충전 목록
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: items.length,
              itemBuilder: (context, itemIndex) {
                final item = items[itemIndex];

                return Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['name'] ?? item['pgProvider'] ?? '토스페이',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: const Color(0xFF001F55),
                                  fontSize: 16,
                                  fontFamily: 'Pretendard-Medium',
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: -0.72,
                                ),
                              ),
                              SizedBox(height: 8),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    '포인트 충전 • ${item['pgProvider'] ?? '토스페이'}',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: const Color(0xFF8490A3),
                                      fontSize: 12,
                                      fontFamily: 'Pretendard-Light',
                                      fontWeight: FontWeight.w300,
                                      letterSpacing: -0.28,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Container(
                                    width: 2,
                                    height: 2,
                                    decoration: ShapeDecoration(
                                      color: const Color(0xFF8490A3),
                                      shape: OvalBorder(),
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    _formatTime(item['paidAt'] ?? ''),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: const Color(0xFF8490A3),
                                      fontSize: 12,
                                      fontFamily: 'Pretendard-Light',
                                      fontWeight: FontWeight.w300,
                                      letterSpacing: -0.28,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Container(
                            width: 120,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '+${_formatCurrency(item['chargePoint'] ?? 0)}원',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: const Color(0xFF3A88F4),
                                    fontSize: 16,
                                    fontFamily: 'Pretendard-Bold',
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.72,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      '${_formatCurrency(item['remainingPoint'] ?? 0)}원',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: const Color(0xFF8490A3),
                                        fontSize: 12,
                                        fontFamily: 'Pretendard-Light',
                                        fontWeight: FontWeight.w300,
                                        letterSpacing: -0.28,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  // 탭 바 위젯
  Widget _buildTabs() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(width: 1, color: const Color(0xFFC4C4C4)),
        ),
      ),
      child: Row(
        children: [
          // 충전 포인트 탭
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTabIndex = 0;
                });
              },
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      width: 2,
                      color:
                          _selectedTabIndex == 0
                              ? Colors.black
                              : Colors.transparent,
                    ),
                  ),
                ),
                child: Text(
                  '충전 포인트',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color:
                        _selectedTabIndex == 0
                            ? Colors.black
                            : const Color(0xFFCCCCCC),
                    fontSize: 13,
                    fontFamily:
                        _selectedTabIndex == 0
                            ? 'Pretendard-Bold'
                            : 'Pretendard-Light',
                    letterSpacing: -0.30,
                  ),
                ),
              ),
            ),
          ),

          // 보낸 포인트 탭
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTabIndex = 1;
                });
              },
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      width: 2,
                      color:
                          _selectedTabIndex == 1
                              ? Colors.black
                              : Colors.transparent,
                    ),
                  ),
                ),
                child: Text(
                  '보낸 포인트',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color:
                        _selectedTabIndex == 1
                            ? Colors.black
                            : const Color(0xFFCCCCCC),
                    fontSize: 13,
                    fontFamily:
                        _selectedTabIndex == 1
                            ? 'Pretendard-Bold'
                            : 'Pretendard-Light',
                    letterSpacing: -0.30,
                  ),
                ),
              ),
            ),
          ),

          // 꺼낸 포인트 탭
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTabIndex = 2;
                });
              },
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      width: 2,
                      color:
                          _selectedTabIndex == 2
                              ? Colors.black
                              : Colors.transparent,
                    ),
                  ),
                ),
                child: Text(
                  '꺼낸 포인트',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color:
                        _selectedTabIndex == 2
                            ? Colors.black
                            : const Color(0xFFCCCCCC),
                    fontSize: 13,
                    fontFamily:
                        _selectedTabIndex == 2
                            ? 'Pretendard-Bold'
                            : 'Pretendard-Light',
                    letterSpacing: -0.30,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 보낸 포인트 내역 목록
  Widget _buildSentPointHistoryList() {
    if (_isLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: CircularProgressIndicator(color: Color(0xFF5D9DFF)),
        ),
      );
    }

    if (_sentTransactions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(50.0),
          child: Column(
            children: [
              Icon(Icons.swap_horiz, size: 48, color: Colors.grey[400]),
              SizedBox(height: 16),
              Text(
                '보낸 포인트 내역이 없습니다',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                  fontFamily: 'Pretendard-Medium',
                ),
              ),
              SizedBox(height: 8),
              Text(
                '포인트를 보내면 내역이 표시됩니다',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                  fontFamily: 'Pretendard-Light',
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 날짜별로 그룹화
    Map<String, List<Map<String, dynamic>>> groupedData = {};
    for (var item in _sentTransactions) {
      final dateKey = _formatDate(item['sentAt'] ?? '');
      if (!groupedData.containsKey(dateKey)) {
        groupedData[dateKey] = [];
      }
      groupedData[dateKey]!.add(item);
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: groupedData.keys.length,
      itemBuilder: (context, index) {
        final dateKey = groupedData.keys.elementAt(index);
        final items = groupedData[dateKey]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 날짜 헤더
            Container(
              padding: EdgeInsets.fromLTRB(0, 8, 0, 0),
              child: Text(
                dateKey,
                style: TextStyle(
                  color: Color(0xFF999999),
                  fontSize: 12,
                  fontFamily: 'Pretendard-Medium',
                ),
              ),
            ),

            // 해당 날짜의 보낸 포인트 목록
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: items.length,
              itemBuilder: (context, itemIndex) {
                final item = items[itemIndex];

                return Container(
                  padding: const EdgeInsets.fromLTRB(0, 12, 0, 12),
                  color: Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 제목 및 금액
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '포인트 보냄',
                                  style: TextStyle(
                                    color: Color(0xFF001F55),
                                    fontSize: 14,
                                    fontFamily: 'Pretendard-Medium',
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  '${item['receiverName'] ?? '알 수 없는 사용자'}님에게 보냄',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                    fontFamily: 'Pretendard-Light',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '-${_formatCurrency(item['pointAmount'] ?? 0)}원',
                            style: TextStyle(
                              color: const Color(0xFFFF6B6B),
                              fontSize: 14,
                              fontFamily: 'Pretendard-Bold',
                            ),
                          ),
                        ],
                      ),

                      // 메시지가 있으면 표시
                      if (item['message'] != null &&
                          item['message'].toString().isNotEmpty) ...[
                        SizedBox(height: 4),
                        Text(
                          '"${item['message']}"',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 11,
                            fontFamily: 'Pretendard-Light',
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],

                      const SizedBox(height: 6),

                      // 시간 및 잔액
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatTime(item['sentAt'] ?? ''),
                            style: TextStyle(
                              color: Color(0xFF8E8E8E),
                              fontSize: 12,
                              fontFamily: 'Pretendard-Light',
                            ),
                          ),
                          Text(
                            '${_formatCurrency(item['remainingPoint'] ?? 0)}원',
                            style: TextStyle(
                              color: Color(0xFF8E8E8E),
                              fontSize: 12,
                              fontFamily: 'Pretendard-Light',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  // 공통 필터 섹션 - 적립금 내역 디자인으로 변경
  Widget _buildFilterSection(bool isInProgress, Function(bool) onChanged) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: Colors.white),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // 진행중 버튼
          GestureDetector(
            onTap: () => onChanged(true),
            child: Container(
              height: 36,
              width: 70,
              decoration: BoxDecoration(
                color:
                    isInProgress
                        ? const Color(0xFF3A88F4)
                        : const Color(0xFFDEDEDE),
                borderRadius: BorderRadius.circular(20),
              ),
              alignment: Alignment.center,
              child: Text(
                '진행중',
                style: TextStyle(
                  color: isInProgress ? Colors.white : const Color(0xFF999999),
                  fontSize: 12,
                  fontFamily:
                      isInProgress
                          ? 'Pretendard-Light'
                          : 'Pretendard-ExtraLight',
                ),
              ),
            ),
          ),

          const SizedBox(width: 12), // 버튼 간 간격
          // 완료한 버튼
          GestureDetector(
            onTap: () => onChanged(false),
            child: Container(
              height: 36,
              width: 70,
              decoration: BoxDecoration(
                color:
                    !isInProgress
                        ? const Color(0xFF3A88F4)
                        : const Color(0xFFDEDEDE),
                borderRadius: BorderRadius.circular(20),
              ),
              alignment: Alignment.center,
              child: Text(
                '완료한',
                style: TextStyle(
                  color: !isInProgress ? Colors.white : const Color(0xFF999999),
                  fontSize: 12,
                  fontFamily:
                      !isInProgress
                          ? 'Pretendard-Light'
                          : 'Pretendard-ExtraLight',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AccountManageBottomSheet extends StatelessWidget {
  const AccountManageBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 제목 영역
          Padding(
            padding: const EdgeInsets.only(
              left: 20,
              right: 20,
              top: 16,
              bottom: 8,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '충전 계좌를 관리할 수 있어요',
                  style: TextStyle(
                    color: const Color(0xFF202020),
                    fontSize: 18,
                    fontFamily: 'Pretendard-Bold',
                    letterSpacing: -0.72,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: Colors.grey[400], size: 24),
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                ),
              ],
            ),
          ),

          // 메뉴 항목들
          _buildMenuItem(
            context: context,
            title: '입출금 알림 설정하기',
            icon: Icons.notifications_none,
            onTap: () {
              print('입출금 알림 설정');
              Navigator.pop(context);
            },
          ),

          _buildMenuItem(
            context: context,
            title: '계좌 이름 바꾸기',
            icon: Icons.edit_outlined,
            onTap: () {
              print('계좌 이름 바꾸기');
              Navigator.pop(context);
            },
          ),

          _buildMenuItem(
            context: context,
            title: '연결된 계좌 바꾸기',
            icon: Icons.account_balance_outlined,
            onTap: () {
              print('연결된 계좌 바꾸기');
              Navigator.pop(context);
            },
          ),

          _buildMenuItem(
            context: context,
            title: '계좌 삭제하기',
            icon: Icons.delete_outline,
            onTap: () {
              print('계좌 삭제하기');
              Navigator.pop(context);
            },
            textColor: Color(0xFFFF6B6B),
          ),

          SizedBox(height: 16), // 하단 여백
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Function() onTap,
    Color? textColor,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: textColor ?? const Color(0xFF666666), size: 20),
            SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                color: textColor ?? const Color(0xFF666666),
                fontSize: 14,
                fontFamily: 'Pretendard-Light',
                letterSpacing: -0.28,
              ),
            ),
            Spacer(),
            Icon(Icons.arrow_forward_ios, color: Colors.grey[300], size: 16),
          ],
        ),
      ),
    );
  }
}

// 필터 바텀시트 위젯 추가
class FilterBottomSheet extends StatelessWidget {
  const FilterBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 260, // 구분선 추가로 높이 약간 증가
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 제목 영역
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  '충전 계좌를 관리할 수 있어요',
                  style: TextStyle(
                    color: const Color(0xFF202020),
                    fontSize: 16,
                    fontFamily: 'Pretendard-Bold',
                    letterSpacing: -0.64,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: Icon(
                      Icons.close,
                      size: 24,
                      color: Color(0xFF333333),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 메뉴 항목들
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
            decoration: BoxDecoration(color: Colors.white),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 입출금 알림 설정하기
                _buildFilterItem(
                  context: context,
                  title: '입출금 알림 설정하기',
                  onTap: () {
                    print('입출금 알림 설정');
                    Navigator.pop(context);
                  },
                ),
                _buildDivider(),

                // 계좌 이름 바꾸기
                _buildFilterItem(
                  context: context,
                  title: '계좌 이름 바꾸기',
                  onTap: () {
                    print('계좌 이름 바꾸기');
                    Navigator.pop(context);
                  },
                ),
                _buildDivider(),

                // 연결된 계좌 바꾸기
                _buildFilterItem(
                  context: context,
                  title: '연결된 계좌 바꾸기',
                  onTap: () {
                    print('연결된 계좌 바꾸기');
                    Navigator.pop(context);
                  },
                ),
                _buildDivider(),

                // 계좌 삭제하기
                _buildFilterItem(
                  context: context,
                  title: '계좌 삭제하기',
                  onTap: () {
                    print('계좌 삭제하기');
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 메뉴 항목 위젯
  Widget _buildFilterItem({
    required BuildContext context,
    required String title,
    required Function() onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          title,
          style: TextStyle(
            color: const Color(0xFF666666),
            fontSize: 13,
            fontFamily: 'Pretendard-Light',
            letterSpacing: -0.28,
          ),
        ),
      ),
    );
  }

  // 구분선 위젯
  Widget _buildDivider() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      height: 1,
      color: Color(0xFFEAEAEA),
    );
  }
}
