import 'package:flutter/material.dart';
import '../../../widgets/common/bottom_navigation_bar.dart';
import '../../../services/payment_service.dart';
import '../../../services/auth_service.dart';
import '../bank/charge_screen.dart';

class TotalPointHistoryScreen extends StatefulWidget {
  const TotalPointHistoryScreen({super.key});

  @override
  State<TotalPointHistoryScreen> createState() =>
      _TotalPointHistoryScreenState();
}

class _TotalPointHistoryScreenState extends State<TotalPointHistoryScreen> {
  // 현재 선택된 탭 (0: 충전, 1: 보낸 포인트, 2: 꺼낸 포인트)
  int _selectedTabIndex = 0;

  // 데이터 상태 변수들
  int _currentPoints = 0;
  List<Map<String, dynamic>> _chargeHistoryData = [];
  List<Map<String, dynamic>> _sentPointHistory = [];
  List<Map<String, dynamic>> _refundHistoryData = [];
  Map<String, dynamic>? _userInfo;

  // 로딩 상태
  bool _isLoading = true;
  bool _isHistoryLoading = false;

  // 에러 메시지
  String? _errorMessage;
  String? _historyError;

  // 날짜 필터링 상태 변수 추가
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 365));
  DateTime _endDate = DateTime.now();
  bool _isAllPeriod = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // 전체 데이터 로딩
  Future<void> _loadData() async {
    await Future.wait([_loadUserInfo(), _loadPointHistory()]);
  }

  // 사용자 정보 및 포인트 로딩
  Future<void> _loadUserInfo() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final userInfo = await AuthService.getUserInfo();

      // 사용자 정보에서 포인트 가져오기
      final points =
          userInfo['point'] is int
              ? userInfo['point']
              : int.tryParse(userInfo['point'].toString()) ?? 0;

      if (mounted) {
        setState(() {
          _userInfo = userInfo;
          _currentPoints = points;
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
      print('사용자 정보 로딩 오류: $e');
    }
  }

  // 포인트 내역 로딩
  Future<void> _loadPointHistory() async {
    try {
      setState(() {
        _isHistoryLoading = true;
        _historyError = null;
      });

      // 날짜 필터링을 위한 시작일과 종료일 설정
      String? startDateStr;
      String? endDateStr;

      if (!_isAllPeriod) {
        // 시작일은 해당 일의 00:00:00
        final startDate = DateTime(
          _startDate.year,
          _startDate.month,
          _startDate.day,
        );
        // 종료일은 해당 일의 23:59:59
        final endDate = DateTime(
          _endDate.year,
          _endDate.month,
          _endDate.day,
          23,
          59,
          59,
        );

        startDateStr = startDate.toIso8601String();
        endDateStr = endDate.toIso8601String();
      }

      // 선택된 탭에 따라 해당하는 API만 호출
      switch (_selectedTabIndex) {
        case 0: // 충전 포인트
          final chargeResponse = await PaymentService.getChargeHistory(
            pageNumber: 0,
            startDate: startDateStr,
            endDate: endDateStr,
          );
          if (mounted) {
            setState(() {
              if (chargeResponse.containsKey('data') &&
                  chargeResponse['data'] is List) {
                _chargeHistoryData = List<Map<String, dynamic>>.from(
                  chargeResponse['data'],
                );
              } else {
                _chargeHistoryData = [];
              }
            });
          }
          break;

        case 1: // 보낸 포인트
          final sentResponse = await PaymentService.getSentPointHistory(
            pageNumber: 0,
            startDate: startDateStr,
            endDate: endDateStr,
          );
          if (mounted) {
            setState(() {
              if (sentResponse.containsKey('data') &&
                  sentResponse['data'] is List) {
                _sentPointHistory = List<Map<String, dynamic>>.from(
                  sentResponse['data'],
                );
              } else {
                _sentPointHistory = [];
              }
            });
          }
          break;

        case 2: // 꺼낸 포인트
          final refundResponse = await PaymentService.getRefundHistory(
            pageNumber: 0,
            startDate: startDateStr,
            endDate: endDateStr,
          );
          if (mounted) {
            setState(() {
              if (refundResponse.containsKey('data') &&
                  refundResponse['data'] is List) {
                _refundHistoryData = List<Map<String, dynamic>>.from(
                  refundResponse['data'],
                );
              } else {
                _refundHistoryData = [];
              }
            });
          }
          break;
      }

      if (mounted) {
        setState(() {
          _isHistoryLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _historyError = e.toString();
          _isHistoryLoading = false;
        });
      }
      print('포인트 내역 로딩 오류: $e');
    }
  }

  // 데이터에서 날짜 범위 업데이트
  void _updateDateRangeFromData(
    List<Map<String, dynamic>> data,
    String dateField,
  ) {
    if (data.isEmpty || !_isAllPeriod) return; // 전체 기간이 아닐 경우 날짜 범위 업데이트하지 않음

    DateTime? oldestDate;
    DateTime? latestDate;

    for (var item in data) {
      if (item[dateField] != null) {
        try {
          final date = DateTime.parse(item[dateField]);
          if (oldestDate == null || date.isBefore(oldestDate)) {
            oldestDate = date;
          }
          if (latestDate == null || date.isAfter(latestDate)) {
            latestDate = date;
          }
        } catch (e) {
          print('날짜 파싱 오류: $e');
        }
      }
    }

    if (oldestDate != null && latestDate != null && _isAllPeriod) {
      // 전체 기간일 때만 날짜 범위 업데이트
      _startDate = DateTime(oldestDate.year, oldestDate.month, oldestDate.day);
      _endDate = DateTime(latestDate.year, latestDate.month, latestDate.day);
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

  // 날짜 포맷팅 (YYYY.MM.dd)
  String _formatDateCompact(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }

  // 은행 로고 이미지 경로 반환
  String _getBankLogo(String? bankName) {
    if (bankName == null || bankName.isEmpty) return '';

    // 은행 이름에서 특수문자 및 공백 제거
    String cleanBankName =
        bankName.replaceAll(RegExp(r'[^\w\s가-힣]'), '').trim();

    // 정리 후에도 빈 문자열이면 빈 경로 반환
    if (cleanBankName.isEmpty) return '';

    // 은행 이름 매핑
    Map<String, String> bankMapping = {
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

    String bankCode = bankMapping[cleanBankName] ?? '';
    return bankCode.isEmpty ? '' : 'assets/logos/$bankCode.png';
  }

  // 계좌번호 포맷팅 (6글자-2글자-6글자)
  String _formatAccountNumber(String? accountNumber) {
    if (accountNumber == null || accountNumber.isEmpty) {
      return '계좌번호';
    }

    // 숫자만 추출
    String numbers = accountNumber.replaceAll(RegExp(r'[^0-9]'), '');

    // 숫자가 없으면 기본값 반환
    if (numbers.isEmpty) {
      return '계좌번호';
    }

    if (numbers.length >= 14) {
      // 6글자-2글자-6글자 형태로 포맷팅
      return '${numbers.substring(0, 6)}-${numbers.substring(6, 8)}-${numbers.substring(8, 14)}';
    } else if (numbers.length >= 8) {
      // 길이가 부족하면 가능한 만큼만 포맷팅
      return '${numbers.substring(0, 6)}-${numbers.substring(6, 8)}-${numbers.substring(8)}';
    } else if (numbers.length >= 6) {
      return '${numbers.substring(0, 6)}-${numbers.substring(6)}';
    } else {
      return numbers.isEmpty ? '계좌번호' : numbers;
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
          icon: Image.asset('assets/icons/my/뒤로가기.png', width: 20, height: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '총 포인트 내역',
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontFamily: 'Pretendard-Bold',
            letterSpacing: -0.32,
          ),
        ),
      ),
      body: Column(
        children: [
          // 메인 콘텐츠
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // 현재 포인트 정보 카드
                  _buildCurrentPointCard(),

                  // 충전/보낸 포인트/꺼낸 포인트 탭
                  _buildTabs(),

                  // 내역 수 및 검색
                  _buildHistoryHeader(),

                  // 내역 리스트 (탭에 따라 다른 내용 표시)
                  if (_selectedTabIndex == 0)
                    _buildChargeHistoryList()
                  else if (_selectedTabIndex == 1)
                    _buildSentPointHistoryList()
                  else
                    _buildRefundHistoryList(),
                ],
              ),
            ),
          ),

          // 하단 고정 버튼 영역
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 충전하기 버튼
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(
                  top: 24,
                  left: 16,
                  right: 16,
                  bottom: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x5B000000),
                      blurRadius: 8,
                      offset: Offset(0, -4),
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: GestureDetector(
                  onTap: () {
                    // 충전하기 페이지로 이동
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ChargeScreen(),
                      ),
                    ).then((_) {
                      // 충전 완료 후 데이터 다시 로딩
                      _loadData();
                    });
                  },
                  child: Container(
                    width: double.infinity,
                    height: 49,
                    decoration: ShapeDecoration(
                      gradient: LinearGradient(
                        begin: Alignment(0.07, 0.08),
                        end: Alignment(1.23, 1.20),
                        colors: [
                          const Color(0xFF89DA8D),
                          const Color(0xFF5D9EFF),
                        ],
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_circle_outline,
                            color: Colors.white,
                            size: 20,
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

              // 하단 네비게이션 바
              const CommonBottomNavigationBar(selectedIndex: 4),
            ],
          ),
        ],
      ),
    );
  }

  // 현재 포인트 정보 카드
  Widget _buildCurrentPointCard() {
    // 꺼낸 포인트 탭인 경우 다른 UI 표시
    if (_selectedTabIndex == 2) {
      return _buildRefundSummaryCard();
    }

    // 계좌 정보가 있는지 확인
    bool hasAccountInfo =
        _userInfo != null &&
        _userInfo!['bankName'] != null &&
        _userInfo!['bankAccount'] != null;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(20),
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
          if (hasAccountInfo) ...[
            // 계좌 정보가 있는 경우
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
                            child: Builder(
                              builder: (context) {
                                final bankName =
                                    _userInfo!['bankName'] as String?;
                                final logoPath = _getBankLogo(bankName);

                                if (logoPath.isEmpty) {
                                  return Center(
                                    child: Text(
                                      (bankName != null && bankName.isNotEmpty)
                                          ? bankName.substring(0, 1)
                                          : '?',
                                      style: TextStyle(
                                        color: Color(0xFF666666),
                                        fontSize: 14,
                                        fontFamily: 'Pretendard-Medium',
                                      ),
                                    ),
                                  );
                                }

                                return ClipOval(
                                  child: Image.asset(
                                    logoPath,
                                    width: 32,
                                    height: 32,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      print('Error loading bank logo: $error');
                                      return Center(
                                        child: Text(
                                          (bankName != null &&
                                                  bankName.isNotEmpty)
                                              ? bankName.substring(0, 1)
                                              : '?',
                                          style: TextStyle(
                                            color: Color(0xFF666666),
                                            fontSize: 14,
                                            fontFamily: 'Pretendard-Medium',
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
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
                              Text(
                                _userInfo!['bankName'] ?? '은행명',
                                style: TextStyle(
                                  color: const Color(0xFF89DA8D),
                                  fontSize: 11,
                                  fontFamily: 'Pretendard-Light',
                                  letterSpacing: -0.22,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                _formatAccountNumber(_userInfo!['bankAccount']),
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
                        // 세로 점 메뉴 추가
                        Positioned(
                          right: 0,
                          top: 0,
                          child: GestureDetector(
                            onTap: _showAccountManagementBottomSheet,
                            child: Icon(
                              Icons.more_vert,
                              color: Color(0xFF666666),
                              size: 24,
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
                            fontSize: 14,
                            fontFamily: 'Pretendard-Medium',
                            letterSpacing: -0.28,
                          ),
                        ),
                        SizedBox(height: 12),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            if (_isLoading)
                              CircularProgressIndicator(
                                color: Color(0xFF206AFF),
                                strokeWidth: 2,
                              )
                            else
                              Text(
                                '${_formatCurrency(_currentPoints)}원',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: const Color(0xFF206AFF),
                                  fontSize: 16,
                                  fontFamily: 'Pretendard-Bold',
                                  letterSpacing: -0.80,
                                ),
                              ),
                            SizedBox(width: 8),
                            Image.asset(
                              'assets/icons/my/help.png',
                              width: 20,
                              height: 20,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            // 계좌 정보가 없는 경우
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.account_balance,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  SizedBox(height: 12),
                  Text(
                    '계좌를 연결해주세요',
                    style: TextStyle(
                      color: const Color(0xFF666666),
                      fontSize: 16,
                      fontFamily: 'Pretendard-Medium',
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '포인트를 실제 용돈으로 받기 위해\n계좌 연결이 필요합니다',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                      fontFamily: 'Pretendard-Light',
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // 꺼낸 포인트 요약 카드
  Widget _buildRefundSummaryCard() {
    // 꺼낸 포인트 총액 계산
    int totalRefunded = 0;
    int totalRequested = 0;

    for (var item in _refundHistoryData) {
      totalRefunded += (item['processedAmount'] as int? ?? 0);
      totalRequested += (item['requestedAmount'] as int? ?? 0);
    }

    return Container(
      width: double.infinity,
      height: 140,
      margin: const EdgeInsets.only(top: 20, bottom: 20),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(color: const Color(0xFF5D9EFF)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '오늘까지 총 포인트에서 꺼낸 금액이',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontFamily: 'Pretendard-Bold',
                          height: 1.30,
                          letterSpacing: -0.64,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            '${_formatCurrency(totalRefunded)}원',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontFamily: 'Pretendard-Bold',
                              letterSpacing: -0.96,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 12),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '꺼내기 요청한 금액은 ',
                            style: TextStyle(
                              color: const Color(0xFF001F55),
                              fontSize: 14,
                              fontFamily: 'Pretendard-Light',
                              letterSpacing: -0.28,
                            ),
                          ),
                          TextSpan(
                            text: '+ ${_formatCurrency(totalRequested)}원',
                            style: TextStyle(
                              color: const Color(0xFF001F55),
                              fontSize: 14,
                              fontFamily: 'Pretendard-Bold',
                              letterSpacing: -0.28,
                            ),
                          ),
                          TextSpan(
                            text: '입니다',
                            style: TextStyle(
                              color: const Color(0xFF001F55),
                              fontSize: 14,
                              fontFamily: 'Pretendard-Light',
                              letterSpacing: -0.28,
                            ),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
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

  // 충전/보낸 포인트/꺼낸 포인트 탭
  Widget _buildTabs() {
    return Container(
      width: double.infinity,
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(width: 1, color: const Color(0xFFC4C4C4)),
          ),
        ),
        child: Row(
          children: [
            // 충전 탭
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedTabIndex = 0;
                    _isAllPeriod = true;
                  });
                  _loadPointHistory();
                },
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        width: 2,
                        color:
                            _selectedTabIndex == 0
                                ? const Color(0xFF202020)
                                : Colors.transparent,
                      ),
                    ),
                  ),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        '충전 포인트',
                        style: TextStyle(
                          color:
                              _selectedTabIndex == 0
                                  ? const Color(0xFF202020)
                                  : const Color(0xFFCCCCCC),
                          fontSize: 14,
                          fontFamily:
                              _selectedTabIndex == 0
                                  ? 'Pretendard-Bold'
                                  : 'Pretendard-Light',
                          letterSpacing: -0.32,
                        ),
                      ),
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
                    _isAllPeriod = true;
                  });
                  _loadPointHistory();
                },
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        width: 2,
                        color:
                            _selectedTabIndex == 1
                                ? const Color(0xFF202020)
                                : Colors.transparent,
                      ),
                    ),
                  ),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        '보낸 포인트',
                        style: TextStyle(
                          color:
                              _selectedTabIndex == 1
                                  ? const Color(0xFF202020)
                                  : const Color(0xFFCCCCCC),
                          fontSize: 14,
                          fontFamily:
                              _selectedTabIndex == 1
                                  ? 'Pretendard-Bold'
                                  : 'Pretendard-Light',
                          letterSpacing: -0.32,
                        ),
                      ),
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
                    _isAllPeriod = true;
                  });
                  _loadPointHistory();
                },
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        width: 2,
                        color:
                            _selectedTabIndex == 2
                                ? const Color(0xFF202020)
                                : Colors.transparent,
                      ),
                    ),
                  ),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        '꺼낸 포인트',
                        style: TextStyle(
                          color:
                              _selectedTabIndex == 2
                                  ? const Color(0xFF202020)
                                  : const Color(0xFFCCCCCC),
                          fontSize: 14,
                          fontFamily:
                              _selectedTabIndex == 2
                                  ? 'Pretendard-Bold'
                                  : 'Pretendard-Light',
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
      ),
    );
  }

  // 내역 헤더 (개수 및 필터)
  Widget _buildHistoryHeader() {
    List<Map<String, dynamic>> historyData;
    String dateField;

    switch (_selectedTabIndex) {
      case 0:
        historyData = _chargeHistoryData;
        dateField = 'paidAt';
        break;
      case 1:
        historyData = _sentPointHistory;
        dateField = 'sentAt';
        break;
      case 2:
        historyData = _refundHistoryData;
        dateField = 'requestedAt';
        break;
      default:
        historyData = _chargeHistoryData;
        dateField = 'paidAt';
    }

    // 날짜 필터링 적용
    if (!_isAllPeriod) {
      historyData =
          historyData.where((item) {
            if (item[dateField] == null) return false;
            try {
              final itemDate = DateTime.parse(item[dateField]);
              return itemDate.isAfter(
                    _startDate.subtract(Duration(seconds: 1)),
                  ) &&
                  itemDate.isBefore(_endDate.add(Duration(days: 1)));
            } catch (e) {
              return false;
            }
          }).toList();
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(color: Colors.white),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 전체 내역 수
              Row(
                children: [
                  Text(
                    _isAllPeriod
                        ? '전체 내역 '
                        : '${_formatDateCompact(_startDate)} ~ ${_formatDateCompact(_endDate)} ',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontFamily: 'Pretendard-Medium',
                    ),
                  ),
                  Text(
                    '${historyData.length}',
                    style: TextStyle(
                      color: Color(0xFF3A88F4),
                      fontSize: 16,
                      fontFamily: 'Pretendard-SemiBold',
                    ),
                  ),
                ],
              ),

              // 필터 아이콘
              GestureDetector(
                onTap: _showFilterBottomSheet,
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
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
          alignment: Alignment.centerLeft,
          child: Image.asset(
            'assets/icons/my/검색.png',
            width: 24,
            height: 24,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  // 충전 내역 목록
  Widget _buildChargeHistoryList() {
    if (_isHistoryLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: CircularProgressIndicator(color: Color(0xFF5D9DFF)),
        ),
      );
    }

    if (_historyError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            children: [
              Text(
                '충전 내역을 불러오지 못했습니다',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 14,
                  fontFamily: 'Pretendard-Medium',
                ),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: _loadPointHistory,
                child: Text('다시 시도'),
              ),
            ],
          ),
        ),
      );
    }

    // 날짜 필터링 적용
    List<Map<String, dynamic>> filteredData = _chargeHistoryData;
    if (!_isAllPeriod) {
      filteredData =
          _chargeHistoryData.where((item) {
            if (item['paidAt'] == null) return false;
            try {
              final itemDate = DateTime.parse(item['paidAt']);
              // 시작일의 00:00:00부터 종료일의 23:59:59까지 포함
              final startDateTime = DateTime(
                _startDate.year,
                _startDate.month,
                _startDate.day,
              );
              final endDateTime = DateTime(
                _endDate.year,
                _endDate.month,
                _endDate.day,
                23,
                59,
                59,
              );
              return itemDate.isAfter(
                    startDateTime.subtract(Duration(seconds: 1)),
                  ) &&
                  itemDate.isBefore(endDateTime.add(Duration(seconds: 1)));
            } catch (e) {
              print('날짜 파싱 오류: $e');
              return false;
            }
          }).toList();
    }

    if (filteredData.isEmpty) {
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
    for (var item in filteredData) {
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
              padding: EdgeInsets.fromLTRB(20, 8, 20, 0),
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
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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

  // 보낸 포인트 내역 목록
  Widget _buildSentPointHistoryList() {
    if (_isHistoryLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: CircularProgressIndicator(color: Color(0xFF5D9DFF)),
        ),
      );
    }

    if (_historyError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            children: [
              Text(
                '보낸 포인트 내역을 불러오지 못했습니다',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 14,
                  fontFamily: 'Pretendard-Medium',
                ),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: _loadPointHistory,
                child: Text('다시 시도'),
              ),
            ],
          ),
        ),
      );
    }

    // 날짜 필터링 적용
    List<Map<String, dynamic>> filteredData = _sentPointHistory;
    if (!_isAllPeriod) {
      filteredData =
          _sentPointHistory.where((item) {
            if (item['sentAt'] == null) return false;
            try {
              final itemDate = DateTime.parse(item['sentAt']);
              // 시작일의 00:00:00부터 종료일의 23:59:59까지 포함
              final startDateTime = DateTime(
                _startDate.year,
                _startDate.month,
                _startDate.day,
              );
              final endDateTime = DateTime(
                _endDate.year,
                _endDate.month,
                _endDate.day,
                23,
                59,
                59,
              );
              return itemDate.isAfter(
                    startDateTime.subtract(Duration(seconds: 1)),
                  ) &&
                  itemDate.isBefore(endDateTime.add(Duration(seconds: 1)));
            } catch (e) {
              print('날짜 파싱 오류: $e');
              return false;
            }
          }).toList();
    }

    if (filteredData.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(50.0),
          child: Column(
            children: [
              Icon(Icons.send, size: 48, color: Colors.grey[400]),
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
    for (var item in filteredData) {
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
              padding: EdgeInsets.fromLTRB(20, 8, 20, 0),
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
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
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

  // 꺼낸 포인트 내역 목록
  Widget _buildRefundHistoryList() {
    if (_isHistoryLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: CircularProgressIndicator(color: Color(0xFF5D9DFF)),
        ),
      );
    }

    if (_historyError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            children: [
              Text(
                '꺼낸 포인트 내역을 불러오지 못했습니다',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 14,
                  fontFamily: 'Pretendard-Medium',
                ),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: _loadPointHistory,
                child: Text('다시 시도'),
              ),
            ],
          ),
        ),
      );
    }

    // 날짜 필터링 적용
    List<Map<String, dynamic>> filteredData = _refundHistoryData;
    if (!_isAllPeriod) {
      filteredData =
          _refundHistoryData.where((item) {
            if (item['requestedAt'] == null) return false;
            try {
              final itemDate = DateTime.parse(item['requestedAt']);
              // 시작일의 00:00:00부터 종료일의 23:59:59까지 포함
              final startDateTime = DateTime(
                _startDate.year,
                _startDate.month,
                _startDate.day,
              );
              final endDateTime = DateTime(
                _endDate.year,
                _endDate.month,
                _endDate.day,
                23,
                59,
                59,
              );
              return itemDate.isAfter(
                    startDateTime.subtract(Duration(seconds: 1)),
                  ) &&
                  itemDate.isBefore(endDateTime.add(Duration(seconds: 1)));
            } catch (e) {
              print('날짜 파싱 오류: $e');
              return false;
            }
          }).toList();
    }

    if (filteredData.isEmpty) {
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
    for (var item in filteredData) {
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
                padding: const EdgeInsets.symmetric(horizontal: 20),
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
              ...items.map((item) => _buildRefundHistoryItem(item)).toList(),
            ],
          ),
        );
      },
    );
  }

  // 꺼낸 포인트 개별 아이템
  Widget _buildRefundHistoryItem(Map<String, dynamic> item) {
    final requestedAmount = item['requestedAmount'] ?? 0;
    final processedAmount = item['processedAmount'] ?? 0;
    final feeAmount = requestedAmount - processedAmount;
    final feePercentage = '2'; // 수수료 2% 고정

    // 날짜 포맷팅 (yyyy. MM. dd)
    String formatDateForDisplay(String isoDate) {
      try {
        final DateTime date = DateTime.parse(isoDate);
        return '${date.year}. ${date.month.toString().padLeft(2, '0')}. ${date.day.toString().padLeft(2, '0')}.';
      } catch (e) {
        return '';
      }
    }

    return Container(
      width: 320,
      margin: const EdgeInsets.only(bottom: 16, left: 20, right: 20),
      padding: const EdgeInsets.all(12),
      decoration: ShapeDecoration(
        color: Colors.transparent,
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
            children: [
              Container(
                width: 120,
                height: 67,
                child: Stack(
                  children: [
                    Positioned(
                      left: 0,
                      top: 0,
                      child: Text(
                        '꺼내기 요청일',
                        style: TextStyle(
                          color: const Color(0xFF8490A3),
                          fontSize: 12,
                          fontFamily: 'Pretendard-Light',
                          letterSpacing: -0.24,
                        ),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      top: 25,
                      child: Text(
                        '꺼내기 요청한 금액',
                        style: TextStyle(
                          color: const Color(0xFF8490A3),
                          fontSize: 12,
                          fontFamily: 'Pretendard-Light',
                          letterSpacing: -0.24,
                        ),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      top: 50,
                      child: Text(
                        '발생한 수수료',
                        style: TextStyle(
                          color: const Color(0xFF8490A3),
                          fontSize: 12,
                          fontFamily: 'Pretendard-Light',
                          letterSpacing: -0.24,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8),
              Container(
                width: 140,
                height: 67,
                child: Stack(
                  children: [
                    Positioned(
                      left: 20,
                      top: 0,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            formatDateForDisplay(item['requestedAt'] ?? ''),
                            style: TextStyle(
                              color: const Color(0xFF001F55),
                              fontSize: 12,
                              fontFamily: 'Pretendard-Light',
                              letterSpacing: -0.24,
                            ),
                          ),
                          SizedBox(width: 12),
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
                    ),
                    Positioned(
                      left: 20,
                      top: 25,
                      child: Text(
                        '${_formatCurrency(requestedAmount)}원',
                        style: TextStyle(
                          color: const Color(0xFF001F55),
                          fontSize: 12,
                          fontFamily: 'Pretendard-Light',
                          letterSpacing: -0.24,
                        ),
                      ),
                    ),
                    Positioned(
                      left: 20,
                      top: 50,
                      child: Text(
                        '-${_formatCurrency(feeAmount)}원',
                        style: TextStyle(
                          color: const Color(0xFF3A88F4),
                          fontSize: 12,
                          fontFamily: 'Pretendard-Medium',
                          letterSpacing: -0.24,
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
    );
  }

  // 계좌 관리 바텀시트 표시
  void _showAccountManagementBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
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
                SizedBox(height: 24),
                GestureDetector(
                  onTap: () {
                    // 입출금 알림 설정 처리
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      '입출금 알림 설정하기',
                      style: TextStyle(
                        color: const Color(0xFF666666),
                        fontSize: 12,
                        fontFamily: 'Pretendard-Light',
                        letterSpacing: -0.24,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                GestureDetector(
                  onTap: () {
                    // 계좌 이름 변경 처리
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      '계좌 이름 바꾸기',
                      style: TextStyle(
                        color: const Color(0xFF666666),
                        fontSize: 12,
                        fontFamily: 'Pretendard-Light',
                        letterSpacing: -0.24,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                GestureDetector(
                  onTap: () {
                    // 계좌 변경 처리
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      '연결된 계좌 바꾸기',
                      style: TextStyle(
                        color: const Color(0xFF666666),
                        fontSize: 12,
                        fontFamily: 'Pretendard-Light',
                        letterSpacing: -0.24,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                GestureDetector(
                  onTap: () {
                    // 계좌 삭제 처리
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      '계좌 삭제하기',
                      style: TextStyle(
                        color: const Color(0xFF666666),
                        fontSize: 12,
                        fontFamily: 'Pretendard-Light',
                        letterSpacing: -0.24,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 필터 바텀시트 수정
  void _showFilterBottomSheet() {
    // 현재 선택된 탭의 데이터에서 날짜 범위 가져오기
    List<Map<String, dynamic>> currentData;
    String dateField;
    switch (_selectedTabIndex) {
      case 0:
        currentData = _chargeHistoryData;
        dateField = 'paidAt';
        break;
      case 1:
        currentData = _sentPointHistory;
        dateField = 'sentAt';
        break;
      case 2:
        currentData = _refundHistoryData;
        dateField = 'requestedAt';
        break;
      default:
        currentData = _chargeHistoryData;
        dateField = 'paidAt';
    }

    // 데이터에서 날짜 범위 찾기
    DateTime? oldestDate;
    DateTime? latestDate;
    for (var item in currentData) {
      if (item[dateField] != null) {
        try {
          final date = DateTime.parse(item[dateField]);
          if (oldestDate == null || date.isBefore(oldestDate)) {
            oldestDate = date;
          }
          if (latestDate == null || date.isAfter(latestDate)) {
            latestDate = date;
          }
        } catch (e) {
          print('날짜 파싱 오류: $e');
        }
      }
    }

    // 날짜 범위 설정
    if (oldestDate != null && latestDate != null) {
      _startDate = DateTime(oldestDate.year, oldestDate.month, oldestDate.day);
      _endDate = DateTime(latestDate.year, latestDate.month, latestDate.day);
    }

    showModalBottomSheet(
      context: context,
      isDismissible: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateBottomSheet) {
            // 선택된 탭에 따라 제목 변경
            String title = '';
            switch (_selectedTabIndex) {
              case 0:
                title = '충전내역을 조회할 기간을 정해주세요';
                break;
              case 1:
                title = '보낸내역을 조회할 기간을 정해주세요';
                break;
              case 2:
                title = '꺼낸내역을 조회할 기간을 정해주세요';
                break;
            }

            return Container(
              width: MediaQuery.of(context).size.width,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.7,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 타이틀과 닫기 버튼
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 16,
                              fontFamily: 'Pretendard-Bold',
                              color: Color(0xFF202020),
                            ),
                          ),
                          InkWell(
                            onTap: () => Navigator.pop(context),
                            child: Icon(Icons.close, size: 20),
                          ),
                        ],
                      ),

                      SizedBox(height: 16),

                      // 기간 선택 버튼
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 70,
                            height: 36,
                            child: ElevatedButton(
                              onPressed: () {
                                setStateBottomSheet(() {
                                  _isAllPeriod = true;
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    _isAllPeriod
                                        ? Color(0xFF5D9EFF)
                                        : Colors.white,
                                foregroundColor:
                                    _isAllPeriod
                                        ? Colors.white
                                        : Color(0xFF5D9EFF),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  side: BorderSide(color: Color(0xFF5D9EFF)),
                                ),
                                padding: EdgeInsets.zero,
                                elevation: 0,
                              ),
                              child: Text(
                                '전체',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontFamily: 'Pretendard-Medium',
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 10),
                          SizedBox(
                            width: 70,
                            height: 36,
                            child: ElevatedButton(
                              onPressed: () {
                                setStateBottomSheet(() {
                                  _isAllPeriod = false;
                                  if (latestDate != null) {
                                    _endDate = DateTime(
                                      latestDate.year,
                                      latestDate.month,
                                      latestDate.day,
                                    );
                                    _startDate = _endDate.subtract(
                                      Duration(days: 30),
                                    );
                                    if (oldestDate != null &&
                                        _startDate.isBefore(oldestDate)) {
                                      _startDate = DateTime(
                                        oldestDate.year,
                                        oldestDate.month,
                                        oldestDate.day,
                                      );
                                    }
                                  }
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    !_isAllPeriod
                                        ? Color(0xFF5D9EFF)
                                        : Colors.white,
                                foregroundColor:
                                    !_isAllPeriod
                                        ? Colors.white
                                        : Color(0xFF5D9EFF),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  side: BorderSide(color: Color(0xFF5D9EFF)),
                                ),
                                padding: EdgeInsets.zero,
                                elevation: 0,
                              ),
                              child: Text(
                                '1개월',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontFamily: 'Pretendard-Medium',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 16),

                      // 날짜 선택 필드
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _startDate,
                                  firstDate: oldestDate ?? DateTime(2000),
                                  lastDate: DateTime.now().add(
                                    Duration(days: 365),
                                  ),
                                );
                                if (picked != null) {
                                  setStateBottomSheet(() {
                                    _startDate = picked;
                                    if (_startDate.isAfter(_endDate)) {
                                      _endDate = _startDate;
                                    }
                                    _isAllPeriod = false;
                                  });
                                }
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  _formatDateCompact(_startDate),
                                  style: TextStyle(fontSize: 14),
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text('-'),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _endDate,
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime.now().add(
                                    Duration(days: 365),
                                  ),
                                );
                                if (picked != null) {
                                  setStateBottomSheet(() {
                                    _endDate = picked;
                                    if (_endDate.isBefore(_startDate)) {
                                      _startDate = _endDate;
                                    }
                                    _isAllPeriod = false;
                                  });
                                }
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  _formatDateCompact(_endDate),
                                  style: TextStyle(fontSize: 14),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 20),

                      // 버튼 행
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 49,
                              child: ElevatedButton(
                                onPressed: () => Navigator.pop(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey[200],
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text(
                                  '취소',
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 14,
                                    fontFamily: 'Pretendard-Medium',
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: SizedBox(
                              height: 49,
                              child: ElevatedButton(
                                onPressed: () {
                                  _loadPointHistory();
                                  Navigator.pop(context);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFF5D9EFF),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text(
                                  '완료',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontFamily: 'Pretendard-ExtraLight',
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
            );
          },
        );
      },
    );
  }
}
