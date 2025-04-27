import 'package:flutter/material.dart';
import '../../../widgets/common/bottom_navigation_bar.dart';

class ChargeTransferHistoryScreen extends StatefulWidget {
  const ChargeTransferHistoryScreen({super.key});

  @override
  State<ChargeTransferHistoryScreen> createState() => _ChargeTransferHistoryScreenState();
}

class _ChargeTransferHistoryScreenState extends State<ChargeTransferHistoryScreen> {
  // 선택된 카테고리
  final String _selectedCategory = '전체';
  
  // 현재 표시 중인 년월 상태 추가
  DateTime _currentMonth = DateTime(2025, 4);
  
  // 현재 선택된 탭 (0: 충전, 1: 이체)
  int _selectedTabIndex = 0;
  
  // 모달 표시 여부
  bool _showTransferModal = false;
  
  // 물음표 아이콘 위치 추적용 키
  final GlobalKey _helpIconKey = GlobalKey();

  // 가상 데이터 - 날짜별 그룹화
  final List<Map<String, dynamic>> _historyData = [
    {
      'date': '4월 15일 화요일',
      'items': [
        {
          'title': '리틀뱅크 → 김리틀 (토스 뱅크)',
          'type': '송금',
          'time': '13:30',
          'amount': '-34,000원',
          'balance': '415,000원',
        },
        {
          'title': '리틀뱅크 → 김리틀 (토스 뱅크)',
          'type': '송금',
          'time': '13:30',
          'amount': '-34,000원',
          'balance': '415,000원',
        },
      ]
    },
    {
      'date': '3월 14일 화요일',
      'items': [
        {
          'title': '리틀뱅크 → 김리틀 (토스 뱅크)',
          'type': '송금',
          'time': '13:30',
          'amount': '-34,000원',
          'balance': '415,000원',
        },
        {
          'title': '리틀뱅크 → 김리틀 (토스 뱅크)',
          'type': '송금',
          'time': '13:30',
          'amount': '-34,000원',
          'balance': '415,000원',
        },
      ]
    },
    {
      'date': '3월 10일 금요일',
      'items': [
        {
          'title': '리틀뱅크 → 김리틀 (토스 뱅크)',
          'type': '송금',
          'time': '13:30',
          'amount': '-34,000원',
          'balance': '415,000원',
        },
        {
          'title': '리틀뱅크 → 김리틀 (토스 뱅크)',
          'type': '송금',
          'time': '13:30',
          'amount': '-34,000원',
          'balance': '415,000원',
        },
      ]
    },
    {
      'date': '3월 5일 일요일',
      'items': [
        {
          'title': '리틀뱅크 → 김리틀 (토스 뱅크)',
          'type': '송금',
          'time': '13:30',
          'amount': '-34,000원',
          'balance': '415,000원',
        },
        {
          'title': '리틀뱅크 → 김리틀 (토스 뱅크)',
          'type': '송금',
          'time': '13:30',
          'amount': '-34,000원',
          'balance': '415,000원',
        },
      ]
    },
    {
      'date': '2월 20일 월요일',
      'items': [
        {
          'title': '리틀뱅크 → 김리틀 (토스 뱅크)',
          'type': '송금',
          'time': '13:30',
          'amount': '-34,000원',
          'balance': '415,000원',
        },
        {
          'title': '리틀뱅크 → 김리틀 (토스 뱅크)',
          'type': '송금',
          'time': '13:30',
          'amount': '-34,000원',
          'balance': '415,000원',
        },
      ]
    },
  ];

  // 이전 달로 이동
  void _goToPreviousMonth() {
    setState(() {
      _currentMonth = DateTime(
        _currentMonth.year,
        _currentMonth.month - 1,
      );
    });
  }

  // 다음 달로 이동
  void _goToNextMonth() {
    setState(() {
      _currentMonth = DateTime(
        _currentMonth.year,
        _currentMonth.month + 1,
      );
    });
  }

  // 년월 표시 형식 (YYYY. MM)
  String _getFormattedYearMonth() {
    return '${_currentMonth.year}. ${_currentMonth.month.toString().padLeft(2, '0')}';
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
          icon: Icon(Icons.arrow_back_ios, color: Colors.black, size: 16),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '충전 및 이체 내역',
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w700,
            letterSpacing: -0.32,
          ),
        ),
        actions: [
          IconButton(
            icon: Image.asset(
              'assets/images/home.png', 
              width: 24, 
              height: 24,
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
          Column(
            children: [
              // 총 거래 내역 카드
              _buildTotalTransactionCard(),
              
              // 충전/이체 탭 추가
              _buildTabs(),
              
              // 내역 수 및 검색
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.withOpacity(0.1), width: 1),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 전체 내역 수
                    Row(
                      children: [
                        Text(
                          '전체 내역 ',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '80',
                          style: TextStyle(
                            color: Colors.blue,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),

                    // 정렬 아이콘
                    Icon(Icons.tune, color: Colors.grey[500], size: 22),
                  ],
                ),
              ),
              
              // 검색 아이콘
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                alignment: Alignment.centerLeft,
                child: Icon(
                  Icons.search,
                  color: Colors.grey[400],
                  size: 19,
                ),
              ),
              
              // 내역 목록
              Expanded(
                child: _buildHistoryList(),
              ),
            ],
          ),
          
          // 모달 팝업 (물음표 위에 표시)
          if (_showTransferModal)
            _buildTooltipModal(),
        ],
      ),
      bottomNavigationBar: const CommonBottomNavigationBar(selectedIndex: 4),
    );
  }
  
  // 이체 정보 툴팁 모달 위젯
  Widget _buildTooltipModal() {
    // 물음표 아이콘의 위치와 크기 가져오기
    final RenderBox? renderBox = _helpIconKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return Container();
    
    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;
    
    // 고정된 위치 사용
    return Stack(
      children: [
        // 배경 오버레이 (투명 - 탭 감지용)
        Positioned.fill(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _showTransferModal = false;
              });
            },
            child: Container(
              color: Colors.transparent,
            ),
          ),
        ),
        
        // 툴팁 컨텐츠 - 말풍선 형태 (위치 고정)
        Positioned(
          left: 110, // 왼쪽에 위치
          top: 125, // 물음표 바로 아래에 고정 위치
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // 말풍선 화살표 (위쪽 방향)
              Positioned(
                top: -6,
                left: 35, // "3만" 텍스트 위에 정확히 위치
                child: Container(
                  width: 12,
                  height: 12,
                  transform: Matrix4.rotationZ(0.785),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8490A3),
                  ),
                ),
              ),
              
              // 말풍선 메인 컨테이너
              Container(
                width: 210,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: ShapeDecoration(
                  color: const Color(0xFF8490A3),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 제목 행
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '3만 포인트부터 이체할 수 있어요! 💸',
                          style: TextStyle(
                            color: const Color(0xFF89DA8D),
                            fontSize: 10,
                            fontFamily: 'Pretendard',
                            fontWeight: FontWeight.w300,
                            letterSpacing: -0.22,
                          ),
                        ),
                        
                        // 닫기 버튼 - X 아이콘
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _showTransferModal = false;
                            });
                          },
                          child: Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: 8),
                    
                    // 내용
                    Text(
                      '리틀뱅크에서는 3만 포인트 이상부터\n무료로 이체할 수 있어요!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w300,
                        height: 1.45,
                        letterSpacing: -0.22,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  // 충전/이체 탭 위젯
  Widget _buildTabs() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              width: 1,
              color: const Color(0xFFC4C4C4),
            ),
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
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        width: 2,
                        color: _selectedTabIndex == 0 ? const Color(0xFF202020) : Colors.transparent,
                      ),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '충전',
                      style: TextStyle(
                        color: _selectedTabIndex == 0 ? const Color(0xFF202020) : const Color(0xFFCCCCCC),
                        fontSize: 16,
                        fontFamily: 'Pretendard',
                        fontWeight: _selectedTabIndex == 0 ? FontWeight.w700 : FontWeight.w300,
                        letterSpacing: -0.32,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            
            // 이체 탭
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedTabIndex = 1;
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        width: 2,
                        color: _selectedTabIndex == 1 ? const Color(0xFF202020) : Colors.transparent,
                      ),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '이체',
                      style: TextStyle(
                        color: _selectedTabIndex == 1 ? const Color(0xFF202020) : const Color(0xFFCCCCCC),
                        fontSize: 16,
                        fontFamily: 'Pretendard',
                        fontWeight: _selectedTabIndex == 1 ? FontWeight.w700 : FontWeight.w300,
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
  
  // 총 거래 내역 카드 위젯
  Widget _buildTotalTransactionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment(0.00, 0.00),
          end: Alignment(1.00, 1.00),
          colors: [const Color(0xFFF0F6FF), const Color(0xFF5D9EFF)],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: ShapeDecoration(
              gradient: LinearGradient(
                begin: Alignment(-0.01, 0.02),
                end: Alignment(1.01, 1.00),
                colors: [
                  Colors.white.withOpacity(0.4), 
                  Colors.white.withOpacity(0.55)
                ],
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 총 거래 내역 헤더
                Text(
                  '총 거래 내역',
                  style: TextStyle(
                    color: const Color(0xFF202020),
                    fontSize: 16,
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.32,
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // 충전한 총 적립금
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '충전한 총 적립금',
                      style: TextStyle(
                        color: const Color(0xFF001F55),
                        fontSize: 14,
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w300,
                        letterSpacing: -0.28,
                      ),
                    ),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '+133,000',
                            style: TextStyle(
                              color: const Color(0xFF146AFF),
                              fontSize: 14,
                              fontFamily: 'Pretendard',
                              fontWeight: FontWeight.w500,
                              letterSpacing: -0.28,
                            ),
                          ),
                          TextSpan(
                            text: '원',
                            style: TextStyle(
                              color: const Color(0xFF353535),
                              fontSize: 14,
                              fontFamily: 'Pretendard',
                              fontWeight: FontWeight.w500,
                              letterSpacing: -0.28,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                // 이체한 총 적립금
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          '이체한 총 적립금',
                          style: TextStyle(
                            color: const Color(0xFF001F55),
                            fontSize: 14,
                            fontFamily: 'Pretendard',
                            fontWeight: FontWeight.w300,
                            letterSpacing: -0.28,
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          key: _helpIconKey,
                          onTap: () {
                            setState(() {
                              _showTransferModal = true;
                            });
                          },
                          child: Icon(
                            Icons.help_outline,
                            color: Colors.grey[400],
                            size: 16,
                          ),
                        ),
                      ],
                    ),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '-23,000',
                            style: TextStyle(
                              color: const Color(0xFF146AFF),
                              fontSize: 14,
                              fontFamily: 'Pretendard',
                              fontWeight: FontWeight.w500,
                              letterSpacing: -0.28,
                            ),
                          ),
                          TextSpan(
                            text: '원',
                            style: TextStyle(
                              color: const Color(0xFF353535),
                              fontSize: 14,
                              fontFamily: 'Pretendard',
                              fontWeight: FontWeight.w500,
                              letterSpacing: -0.28,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                // 짙은 색 구분선 추가
                Container(
                  width: double.infinity,
                  height: 1,
                  color: const Color(0xFF001F55),
                ),
                
                const SizedBox(height: 8),
                
                // 이번 달에 총 충전한 적립금
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '이번 달에 총 충전한 적립금',
                      style: TextStyle(
                        color: const Color(0xFF001F55),
                        fontSize: 14,
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w300,
                        letterSpacing: -0.28,
                      ),
                    ),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '23,000',
                            style: TextStyle(
                              color: const Color(0xFF146AFF),
                              fontSize: 14,
                              fontFamily: 'Pretendard',
                              fontWeight: FontWeight.w500,
                              letterSpacing: -0.28,
                            ),
                          ),
                          TextSpan(
                            text: '원',
                            style: TextStyle(
                              color: const Color(0xFF353535),
                              fontSize: 14,
                              fontFamily: 'Pretendard',
                              fontWeight: FontWeight.w500,
                              letterSpacing: -0.28,
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
        ],
      ),
    );
  }
  
  // 내역 목록 위젯
  Widget _buildHistoryList() {
    return ListView.builder(
      itemCount: _historyData.length,
      itemBuilder: (context, sectionIndex) {
        final section = _historyData[sectionIndex];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 날짜 헤더
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Text(
                section['date'],
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: const Color(0xFF999999),
                  fontSize: 9.6,
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w300,
                  letterSpacing: -0.19,
                ),
              ),
            ),
            
            // 해당 날짜의 내역 항목들
            ...List.generate(
              section['items'].length,
              (index) => _buildHistoryItem(section['items'][index]),
            ),
            
            // 마지막 항목이 아니면 구분 공간 추가
            if (sectionIndex < _historyData.length - 1)
              const SizedBox(height: 8),
          ],
        );
      },
    );
  }
  
  // 내역 항목 위젯 - 폰트 크기 20% 축소
  Widget _buildHistoryItem(Map<String, dynamic> item) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.only(bottom: 1),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.withOpacity(0.2),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 왼쪽: 제목 및 상세 정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 이체 정보
                Text(
                  item['title'],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: const Color(0xFF666666),
                    fontSize: 11.2, // 14 * 0.8 = 11.2
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.22, // -0.28 * 0.8 = -0.224
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // 이체 유형 및 시간
                Row(
                  children: [
                    Text(
                      item['type'],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: const Color(0xFF999999),
                        fontSize: 11.2, // 14 * 0.8 = 11.2
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w300,
                        letterSpacing: -0.22, // -0.28 * 0.8 = -0.224
                      ),
                    ),
                    
                    const SizedBox(width: 8),
                    
                    Container(
                      width: 2,
                      height: 2,
                      decoration: ShapeDecoration(
                        color: const Color(0xFF999999),
                        shape: OvalBorder(),
                      ),
                    ),
                    
                    const SizedBox(width: 8),
                    
                    Text(
                      item['time'],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: const Color(0xFF999999),
                        fontSize: 11.2, // 14 * 0.8 = 11.2
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w300,
                        letterSpacing: -0.22, // -0.28 * 0.8 = -0.224
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // 오른쪽: 금액 및 잔액
          SizedBox(
            width: 120,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // 이체 금액
                Text(
                  item['amount'],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: const Color(0xFF3A88F4),
                    fontSize: 12.8, // 16 * 0.8 = 12.8
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.26, // -0.32 * 0.8 = -0.256
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // 잔액
                Text(
                  item['balance'],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: const Color(0xFF999999),
                    fontSize: 9.6, // 12 * 0.8 = 9.6
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w300,
                    letterSpacing: -0.19, // -0.24 * 0.8 = -0.192
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