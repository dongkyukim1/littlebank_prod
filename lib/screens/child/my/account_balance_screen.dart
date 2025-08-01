import 'package:flutter/material.dart';

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
            icon: Image.asset('assets/images/home.png', width: 24, height: 24),
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
            ),
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/icons/my/충전하기.png',
                width: 24,
                height: 24,
                color: Colors.white,
              ),
              SizedBox(width: 15),
              Text(
                '충전하기',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontFamily: 'Pretendard-Medium',
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
                                    fontFamily: 'Pretendard-Light',
                                    letterSpacing: -0.22,
                                  ),
                                ),
                                Text(
                                  'KB Star*t 통장',
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
                              '969802-01-010101',
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
                        '현재 리뱅님의 계좌 잔액은',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: const Color(0xFF202020),
                          fontSize: 14,
                          fontFamily: 'Pretendard-Medium',
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
        ],
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
        ],
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
              bottom: BorderSide(color: Colors.grey.withOpacity(0.3), width: 1),
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
                          color:
                              _selectedTabIndex == 0
                                  ? Colors.black
                                  : Colors.transparent,
                          width: 2.5,
                        ),
                      ),
                    ),
                    child: Text(
                      '들어온 돈',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color:
                            _selectedTabIndex == 0
                                ? const Color(0xFF202020)
                                : const Color(0xFFCCCCCC),
                        fontSize: 13,
                        fontFamily:
                            _selectedTabIndex == 0
                                ? 'Pretendard-Medium'
                                : 'Pretendard-Light',
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
                          color:
                              _selectedTabIndex == 1
                                  ? Colors.black
                                  : Colors.transparent,
                          width: 2.5,
                        ),
                      ),
                    ),
                    child: Text(
                      '나간 돈',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color:
                            _selectedTabIndex == 1
                                ? const Color(0xFF202020)
                                : const Color(0xFFCCCCCC),
                        fontSize: 13,
                        fontFamily:
                            _selectedTabIndex == 1
                                ? 'Pretendard-Medium'
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
                Container(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    sectionIndex == 0 ? 10 : 24,
                    20,
                    4,
                  ),
                  alignment: Alignment.centerLeft,
                  child: Text(
                    section['date'],
                    style: TextStyle(
                      color: Color(0xFF8E8E8E),
                      fontSize: 12,
                      fontFamily: 'Pretendard-Light',
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

  // 거래 내역 섹션 빌드
  Widget _buildTransactionHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 전체 내역 및 개수
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(color: Colors.white),
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
                      fontSize: 14,
                      fontFamily: 'Pretendard-Medium',
                    ),
                  ),
                  Text(
                    '80',
                    style: TextStyle(
                      color: Color(0xFF3A88F4),
                      fontSize: 15,
                      fontFamily: 'Pretendard-SemiBold',
                    ),
                  ),
                ],
              ),

              // 정렬 아이콘
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
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          alignment: Alignment.centerLeft,
          child: Image.asset('assets/icons/my/검색.png', width: 24, height: 24),
        ),
      ],
    );
  }

  // 내역 항목 위젯
  Widget _buildHistoryItem(Map<String, dynamic> item) {
    // 금액이 양수인지 확인
    bool isIncoming = item['amount'].toString().contains('+');

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
                child: Text(
                  item['title'],
                  style: TextStyle(
                    color: Color(0xFF001F55),
                    fontSize: 14,
                    fontFamily: 'Pretendard-Medium',
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                item['amount'],
                style: TextStyle(
                  color:
                      isIncoming
                          ? const Color(0xFF3A88F4)
                          : const Color(0xFFFF6B6B),
                  fontSize: 14,
                  fontFamily: 'Pretendard-Bold',
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          // 날짜 및 잔액
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                item['time'],
                style: TextStyle(
                  color: Color(0xFF8E8E8E),
                  fontSize: 12,
                  fontFamily: 'Pretendard-Light',
                ),
              ),
              Text(
                item['balance'],
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
