import 'package:flutter/material.dart';
import '../../../widgets/common/bottom_navigation_bar.dart';

class AccountBalanceScreen extends StatefulWidget {
  const AccountBalanceScreen({super.key});

  @override
  State<AccountBalanceScreen> createState() => _AccountBalanceScreenState();
}

class _AccountBalanceScreenState extends State<AccountBalanceScreen> {
  // 현재 선택된 탭 인덱스 (0: 들어온 돈, 1: 나간 돈)
  int _selectedTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          '내 계좌 잔액',
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Image.asset(
              'assets/images/home.png', 
              width: 24, 
              height: 24,
            ),
            onPressed: () {
              // 홈 화면으로 이동
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 계좌 정보 카드
            _buildAccountInfoCard(),
            
            // 계좌 내역 섹션
            _buildAccountHistorySection(),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        width: double.infinity,
        height: 83,
        padding: const EdgeInsets.only(
          top: 16,
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
            )
          ],
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          decoration: ShapeDecoration(
            gradient: LinearGradient(
              begin: Alignment(0.07, 0.08),
              end: Alignment(1.23, 1.20),
              colors: [const Color(0xFF89DA8D), const Color(0xFF5D9EFF)],
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_circle_outline, color: Colors.white, size: 16),
              SizedBox(width: 8),
              Text(
                '충전하기',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.28,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // 계좌 정보 카드 위젯
  Widget _buildAccountInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: ShapeDecoration(
        color: const Color(0xFFEFF2F6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
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
                            image: DecorationImage(
                              image: AssetImage('assets/logos/kb_bank.png'),
                              fit: BoxFit.cover,
                            ),
                            shape: OvalBorder(),
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
                                  '국민은행',
                                  style: TextStyle(
                                    color: const Color(0xFF666666),
                                    fontSize: 11,
                                    fontFamily: 'Pretendard',
                                    fontWeight: FontWeight.w300,
                                    letterSpacing: -0.22,
                                  ),
                                ),
                                Text(
                                  'KB Star*t 통장',
                                  style: TextStyle(
                                    color: const Color(0xFF666666),
                                    fontSize: 11,
                                    fontFamily: 'Pretendard',
                                    fontWeight: FontWeight.w300,
                                    letterSpacing: -0.22,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 4),
                            Text(
                              '969802-01-010101',
                              overflow: TextOverflow.visible,
                              softWrap: true,
                              style: TextStyle(
                                color: const Color(0xFF999999),
                                fontSize: 11,
                                fontFamily: 'Pretendard',
                                fontWeight: FontWeight.w300,
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
                                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                        '현재 리뱅님의 계좌 잔액은',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: const Color(0xFF202020),
                          fontSize: 12,
                          fontFamily: 'Pretendard',
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.28,
                        ),
                      ),
                      SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            '415,000원',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: const Color(0xFF202020),
                              fontSize: 16,
                              fontFamily: 'Pretendard',
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.80,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(
                            Icons.help_outline,
                            color: Colors.grey[400],
                            size: 20,
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
  
  // 계좌 내역 섹션 위젯
  Widget _buildAccountHistorySection() {
    // 가상 데이터 - 들어온 돈 내역
    final List<Map<String, dynamic>> incomingData = [
      {
        'date': '4월 15일 화요일',
        'items': [
          {
            'title': '3월 셋째주 가족 미션 이름',
            'type': '미션',
            'time': '김리틀・13:30',
            'amount': '+34,000원',
            'balance': '415,000원',
          },
          {
            'title': '3월 셋째주 가족 미션 이름',
            'type': '미션',
            'time': '김리틀・13:30',
            'amount': '+34,000원',
            'balance': '415,000원',
          },
        ]
      },
    ];

    // 가상 데이터 - 나간 돈 내역
    final List<Map<String, dynamic>> outgoingData = [
      {
        'date': '4월 14일 월요일',
        'items': [
          {
            'title': '문구점 구매',
            'type': '송금',
            'time': '김리틀・18:30',
            'amount': '-5,000원',
            'balance': '381,000원',
          },
          {
            'title': '편의점 구매',
            'type': '송금',
            'time': '김리틀・12:30',
            'amount': '-3,500원',
            'balance': '386,000원',
          },
        ]
      },
    ];

    // 현재 선택된 탭에 따른 데이터
    final historyData = _selectedTabIndex == 0 ? incomingData : outgoingData;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 들어온 돈 / 나간 돈 탭
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Colors.grey.withOpacity(0.3),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              // 들어온 돈 탭
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
                          color: _selectedTabIndex == 0 ? Colors.black : Colors.transparent,
                          width: 2.5,
                        ),
                      ),
                    ),
                    child: Text(
                      '들어온 돈',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _selectedTabIndex == 0 ? const Color(0xFF202020) : const Color(0xFFCCCCCC),
                        fontSize: 13,
                        fontFamily: 'Pretendard',
                        fontWeight: _selectedTabIndex == 0 ? FontWeight.w700 : FontWeight.w300,
                        letterSpacing: -0.30,
                      ),
                    ),
                  ),
                ),
              ),
              // 나간 돈 탭
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
                          color: _selectedTabIndex == 1 ? Colors.black : Colors.transparent,
                          width: 2.5,
                        ),
                      ),
                    ),
                    child: Text(
                      '나간 돈',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _selectedTabIndex == 1 ? const Color(0xFF202020) : const Color(0xFFCCCCCC),
                        fontSize: 13,
                        fontFamily: 'Pretendard',
                        fontWeight: _selectedTabIndex == 1 ? FontWeight.w700 : FontWeight.w300,
                        letterSpacing: -0.30,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // 전체 내역 및 개수
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    '전체 내역',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: const Color(0xFF4A4A4A),
                      fontSize: 14,
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.26,
                    ),
                  ),
                  
                  const SizedBox(width: 4),
                  
                  Text(
                    '80',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: const Color(0xFF5D9EFF),
                      fontSize: 12.8,
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.26,
                    ),
                  ),
                ],
              ),
              
              Icon(
                Icons.tune,
                color: Colors.grey[400],
                size: 16,
              ),
            ],
          ),
        ),
        
        // 구분선
        Divider(
          color: Colors.grey.withOpacity(0.2),
          height: 1,
          thickness: 1,
        ),
        
        // 검색 아이콘
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          alignment: Alignment.centerLeft,
          child: Icon(
            Icons.search,
            color: Colors.grey[400],
            size: 19,
          ),
        ),
        
        // 내역 리스트
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: historyData.length,
          itemBuilder: (context, sectionIndex) {
            final section = historyData[sectionIndex];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 날짜 헤더
                Padding(
                  padding: const EdgeInsets.only(left: 12, right: 12, top: 4, bottom: 6),
                  child: Text(
                    section['date'],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: const Color(0xFF999999),
                      fontSize: 13,
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
              ],
            );
          },
        ),
      ],
    );
  }
  
  // 내역 항목 위젯
  Widget _buildHistoryItem(Map<String, dynamic> item) {
    // 금액이 양수인지 확인
    bool isIncoming = item['amount'].toString().contains('+');
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
                // 제목
                Text(
                  item['title'],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: const Color(0xFF666666),
                    fontSize: 11.2,
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.22,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // 유형 및 시간
                Row(
                  children: [
                    Text(
                      item['type'],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: const Color(0xFF999999),
                        fontSize: 11.2,
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w300,
                        letterSpacing: -0.22,
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
                        fontSize: 11.2,
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w300,
                        letterSpacing: -0.22,
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
                // 금액
                Text(
                  item['amount'],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isIncoming ? const Color(0xFF3A88F4) : const Color(0xFFFF6B6B),
                    fontSize: 12.8,
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.26,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // 잔액
                Text(
                  item['balance'],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: const Color(0xFF999999),
                    fontSize: 9.6,
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w300,
                    letterSpacing: -0.19,
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
            padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '충전 계좌를 관리할 수 있어요',
                  style: TextStyle(
                    color: const Color(0xFF202020),
                    fontSize: 18,
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.72,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: Colors.grey[400], size: 24),
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                )
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
            }
          ),
          
          // 구분선 (양쪽 여백 있음)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Divider(color: Colors.grey.withOpacity(0.1), height: 1, thickness: 1),
          ),
          
          _buildMenuItem(
            context: context, 
            title: '계좌 이름 바꾸기', 
            icon: Icons.edit_outlined,
            onTap: () {
              print('계좌 이름 바꾸기');
              Navigator.pop(context);
            }
          ),
          
          // 구분선 (양쪽 여백 있음)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Divider(color: Colors.grey.withOpacity(0.1), height: 1, thickness: 1),
          ),
          
          _buildMenuItem(
            context: context, 
            title: '연결된 계좌 바꾸기', 
            icon: Icons.account_balance_outlined,
            onTap: () {
              print('연결된 계좌 바꾸기');
              Navigator.pop(context);
            }
          ),
          
          // 구분선 (양쪽 여백 있음)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Divider(color: Colors.grey.withOpacity(0.1), height: 1, thickness: 1),
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
    bool isLast = false,
    Color? textColor,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(icon, 
              color: textColor ?? const Color(0xFF666666), 
              size: 20
            ),
            SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                color: textColor ?? const Color(0xFF666666),
                fontSize: 14,
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w300,
                letterSpacing: -0.28,
              ),
            ),
            Spacer(),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey[300],
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
} 