import 'package:flutter/material.dart';
import '../../../widgets/common/bottom_navigation_bar.dart';
import 'point_history_screen.dart';

class PointInformationScreen extends StatefulWidget {
  const PointInformationScreen({super.key});

  @override
  State<PointInformationScreen> createState() => _PointInformationScreenState();
}

class _PointInformationScreenState extends State<PointInformationScreen> {
  // 선택된 카테고리
  final String _selectedCategory = '전체';
  
  // 필터 관련 변수 추가
  final bool _isFilterVisible = false;
  final String _selectedSortOption = '최신순';
  final List<String> _sortOptions = ['최신순', '오래된순', '금액 높은순', '금액 낮은순'];
  
  // 날짜 범위 필터
  String _selectedDateRange = '전체 기간';
  final List<String> _dateRangeOptions = ['전체 기간', '1개월', '3개월', '6개월', '1년', '직접 입력'];
  
  // 포인트 유형 필터
  final List<String> _pointTypes = ['미션', '챌린지', '목표'];
  final List<bool> _selectedPointTypes = [true, true, true]; // 기본적으로 모두 선택됨

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
            color: Color(0xFF202020),
            fontSize: 16,
            fontFamily: 'Pretendard-Bold',
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
              // 홈으로 이동
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 적립금/포인트 탭 추가 - 고정 부분
          SizedBox(
            width: MediaQuery.of(context).size.width,
            height: 50, // 높이 증가
            child: Stack(
              children: [
                Row(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    // 적립금 탭 (클릭 시 이동)
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pushReplacement(
                            context, 
                            MaterialPageRoute(builder: (context) => const PointHistoryScreen())
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                width: 1.0,
                                color: Color(0xFFE5E5E5), // 회색 밑줄
                              ),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '적립금',
                              style: TextStyle(
                                color: Color(0xFFC4C4C4),
                                fontSize: 16, // 글씨 크기 증가
                                fontFamily: 'Pretendard-Light',
                                letterSpacing: -0.32,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    // 간격 추가
                    SizedBox(width: 20),
                    
                    // 포인트 탭 (현재 선택됨)
                    Expanded(
                      child: Container(
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              width: 2.0,
                              color: Color(0xFF202020), // 검은색 밑줄
                            ),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '포인트',
                            style: TextStyle(
                              color: Color(0xFF202020),
                              fontSize: 16, // 글씨 크기 증가
                              fontFamily: 'Pretendard-Bold',
                              letterSpacing: -0.32,
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
          
          // 나머지 부분은 스크롤 가능하게
          Expanded(
            child: CustomScrollView(
              slivers: [
                // 총 적립금 정보 카드
                SliverToBoxAdapter(
                  child: _buildTotalPointsCard(),
                ),
                
                // 도넛 차트 영역
                SliverToBoxAdapter(
                  child: _buildDonutChartSection(),
                ),
                
                // 구분선
                SliverToBoxAdapter(
                  child: Container(
                    width: double.infinity,
                    height: 6,
                    decoration: ShapeDecoration(
                      color: const Color(0xFFEFF2F6),
                      shape: RoundedRectangleBorder(
                        side: BorderSide(
                          width: 0.10,
                          color: const Color(0xFF8490A3),
                        ),
                      ),
                    ),
                  ),
                ),
                
                // 카테고리 필터링 버튼 - 스크롤 시 상단에 고정되도록
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _SliverCategoryButtonsDelegate(),
                ),
                
                // 전체 내역 수 및 검색 헤더
                SliverToBoxAdapter(
                  child: _buildHistoryHeader(),
                ),
                
                // 내역 리스트
                SliverToBoxAdapter(
                  child: _buildHistoryList(),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: const CommonBottomNavigationBar(selectedIndex: 4),
    );
  }

  // 총 포인트 정보 카드
  Widget _buildTotalPointsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.withOpacity(0.2), width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 설명 텍스트
          Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text(
              '오늘까지 모은 포인트가',
              style: TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontFamily: 'Pretendard-Regular',
                height: 1.0,
              ),
            ),
          ),

          // 총 금액
          Text(
            '35,000원',
            style: TextStyle(
              color: Colors.black,
              fontSize: 24,
              fontFamily: 'Pretendard-Bold',
              height: 1.0,
            ),
          ),

          const SizedBox(height: 12),

          // 전월 대비
          Row(
            children: [
              Text(
                '지난 달보다 ',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 13, 
                  fontFamily: 'Pretendard-Light',
                ),
              ),
              Text(
                '+ 13,000 포인트',
                style: TextStyle(
                  color: const Color(0xFF3A88F4),
                  fontSize: 14,
                  fontFamily: 'Pretendard-Medium',
                ),
              ),
              Text(
                '이 늘었어요!',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 13,
                  fontFamily: 'Pretendard-Light',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  // 도넛 차트 영역
  Widget _buildDonutChartSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFF0F6FF),  // 연한 하늘색 시작 (#F0F6FF)
            const Color(0xFF5D9EFF),  // 파란색으로 그라데이션 (#5D9EFF)
          ],
          begin: Alignment.topLeft,  // 왼쪽 위에서 시작
          end: Alignment.bottomRight,  // 오른쪽 아래로 끝
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: ShapeDecoration(
            gradient: LinearGradient(
              begin: Alignment(0.01, 0.03),
              end: Alignment(1.02, 0.97),
              colors: [
                Colors.white.withOpacity(0.4),
                Colors.white.withOpacity(0.55),
              ],
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 가로로 나란히 배치된 막대
              Row(
                children: [
                  // 미션 막대
                  Expanded(
                    flex: 3,
                    child: Container(
                      height: 14, // 약간 줄임
                      decoration: BoxDecoration(
                        color: const Color(0xFF146AFF),
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  // 챌린지 막대
                  Expanded(
                    flex: 3,
                    child: Container(
                      height: 14, // 약간 줄임
                      decoration: BoxDecoration(
                        color: const Color(0xFF10CB86),
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  // 목표 막대
                  Expanded(
                    flex: 2,
                    child: Container(
                      height: 14, // 약간 줄임
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD27F),
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // 아이콘과 텍스트 (한 줄로 간결하게)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // 미션
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: const Color(0xFF146AFF),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        '미션 31,000원',
                        style: TextStyle(
                          color: Color(0xFF353535),
                          fontSize: 10,
                          fontFamily: 'Pretendard-Medium',
                        ),
                      ),
                    ],
                  ),
                  
                  // 챌린지
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: const Color(0xFF10CB86),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        '챌린지 31,000원',
                        style: TextStyle(
                          color: Color(0xFF353535),
                          fontSize: 10,
                          fontFamily: 'Pretendard-Medium',
                        ),
                      ),
                    ],
                  ),
                  
                  // 목표
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD27F),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        '목표 31,000원',
                        style: TextStyle(
                          color: Color(0xFF353535),
                          fontSize: 10,
                          fontFamily: 'Pretendard-Medium',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 내역 헤더 (전체 내역 수 및 검색 아이콘)
  Widget _buildHistoryHeader() {
    return Column(
      children: [
        // 내역 수 및 검색
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
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

              // 정렬 아이콘 - 필터 모달 열기
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
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          alignment: Alignment.centerLeft,
          child: Image.asset(
            'assets/icons/my/검색.png',
            width: 24,
            height: 24,
          ),
        ),
      ],
    );
  }

  // 필터 바텀 시트 표시
  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isDismissible: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              width: MediaQuery.of(context).size.width,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.7,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                boxShadow: [
                  // BoxShadow(
                  //   color: Colors.black.withOpacity(0.15),
                  //   blurRadius: 8,
                  //   offset: Offset(0, -2),
                  // ),
                ],
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
                            '포인트 내역을 조회할 기간을 정해주세요',
                            style: TextStyle(
                              fontSize: 16,
                              fontFamily: 'Pretendard-Bold',
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF202020),
                            ),
                          ),
                          InkWell(
                            onTap: () => Navigator.pop(context),
                            child: Icon(Icons.close, size: 20),
                          ),
                        ],
                      ),

                      // 부가 설명
                      SizedBox(height: 4),
                      Text(
                        '원하는 기간별로 포인트 내역을 나눠볼 수 있어요',
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'Pretendard-Light',
                          fontWeight: FontWeight.w300,
                          color: Color(0xFF999999),
                        ),
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
                                setState(() {
                                  _selectedDateRange = '전체 기간';
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    _selectedDateRange == '전체 기간'
                                        ? Color(0xFF5D9EFF)
                                        : Colors.white,
                                foregroundColor:
                                    _selectedDateRange == '전체 기간'
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
                                  fontWeight: FontWeight.w500,
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
                                setState(() {
                                  _selectedDateRange = '1개월';
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    _selectedDateRange == '1개월'
                                        ? Color(0xFF5D9EFF)
                                        : Colors.white,
                                foregroundColor:
                                    _selectedDateRange == '1개월'
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
                                  fontWeight: FontWeight.w500,
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
                                final DateTime now = DateTime.now();
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: now.subtract(const Duration(days: 30)),
                                  firstDate: DateTime(2020),
                                  lastDate: now,
                                );
                                if (picked != null) {
                                  setState(() {
                                    _selectedDateRange = '직접 입력';
                                  });
                                }
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(4),
                                  color: Colors.white,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '${DateTime.now().subtract(const Duration(days: 30)).year}.${DateTime.now().subtract(const Duration(days: 30)).month.toString().padLeft(2, '0')}.${DateTime.now().subtract(const Duration(days: 30)).day.toString().padLeft(2, '0')}',
                                  style: TextStyle(fontSize: 14),
                                ),
                              ),
                            ),
                          ),

                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text('-', style: TextStyle(fontSize: 16)),
                          ),

                          Expanded(
                            child: GestureDetector(
                              onTap: () async {
                                final DateTime now = DateTime.now();
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: now,
                                  firstDate: now.subtract(const Duration(days: 365)),
                                  lastDate: now.add(const Duration(days: 1)),
                                );
                                if (picked != null) {
                                  setState(() {
                                    _selectedDateRange = '직접 입력';
                                  });
                                }
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(4),
                                  color: Colors.white,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '${DateTime.now().year}.${DateTime.now().month.toString().padLeft(2, '0')}.${DateTime.now().day.toString().padLeft(2, '0')}',
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
                              width: 167,
                              height: 49,
                              child: ElevatedButton(
                                onPressed: () => Navigator.pop(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey[200],
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: EdgeInsets.symmetric(horizontal: 10),
                                  elevation: 0,
                                ),
                                child: Text(
                                  '취소',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontFamily: 'Pretendard-Thin',
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: SizedBox(
                              width: 167,
                              height: 49,
                              child: ElevatedButton(
                                onPressed: () {
                                  // 필터 적용 로직 구현
                                  setState(() {
                                    // 여기서 적용된 필터로 데이터를 다시 로드할 수 있음
                                  });
                                  Navigator.pop(context);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFF5D9EFF),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: EdgeInsets.symmetric(horizontal: 10),
                                  elevation: 0,
                                ),
                                child: Text(
                                  '완료',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontFamily: 'Pretendard-Thin',
                                    color: Colors.white,
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

  // 내역 리스트
  Widget _buildHistoryList() {
    // 더미 데이터 - 날짜별로 그룹화
    final List<Map<String, dynamic>> dateSections = [
      {
        'date': '4월 15일 화요일',
        'items': [
          {
            'title': '3월 생애주기 가족 미션 이름',
            'amount': '+34,000원',
            'date': '금요일 · 13:30',
            'totalAmount': '415,000원',
          },
          {
            'title': '3월 생애주기 가족 미션 이름',
            'amount': '+34,000원',
            'date': '금요일 · 13:30',
            'totalAmount': '415,000원',
          },
        ],
      },
      {
        'date': '4월 14일 최신순',
        'items': [
          {
            'title': '3월 생애주기 가족 미션 이름',
            'amount': '+34,000원',
            'date': '금요일 · 13:30',
            'totalAmount': '415,000원',
          },
          {
            'title': '3월 생애주기 가족 미션 이름',
            'amount': '+34,000원',
            'date': '금요일 · 13:30',
            'totalAmount': '415,000원',
          },
          {
            'title': '3월 생애주기 가족 미션 이름',
            'amount': '+34,000원',
            'date': '금요일 · 13:30',
            'totalAmount': '415,000원',
          },
        ],
      },
    ];

    // 각 섹션을 미리 준비
    List<Widget> sectionWidgets = [];
    
    for (int sectionIndex = 0; sectionIndex < dateSections.length; sectionIndex++) {
      final section = dateSections[sectionIndex];
      
      // 날짜 헤더 추가
      sectionWidgets.add(
        Container(
          padding: EdgeInsets.fromLTRB(20, sectionIndex == 0 ? 10 : 24, 20, 4),
          alignment: Alignment.centerLeft,
          child: Text(
            section['date'],
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 12,
              fontFamily: 'Pretendard-Light',
            ),
          ),
        )
      );
      
      // 아이템 추가
      final List items = section['items'];
      for (int index = 0; index < items.length; index++) {
        final item = items[index];
        final isLast = index == items.length - 1 && sectionIndex == dateSections.length - 1;
        
        sectionWidgets.add(
          _buildHistoryItem(
            title: item['title'],
            amount: item['amount'],
            date: item['date'],
            totalAmount: item['totalAmount'],
          )
        );
      }
    }

    return Column(
      children: sectionWidgets,
    );
  }

  // 내역 아이템
  Widget _buildHistoryItem({
    required String title,
    required String amount,
    required String date,
    required String totalAmount,
  }) {
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
                  title,
                  style: TextStyle(
                    color: Color.fromRGBO(0, 31, 85, 1),
                    fontSize: 14,
                    fontFamily: 'Pretendard-Medium',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              Text(
                amount,
                style: TextStyle(
                  color: Color(0xFF3A88F4),
                  fontSize: 14,
                  fontFamily: 'Pretendard-Bold',
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          // 날짜 및 총액
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                date,
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 10,
                  fontFamily: 'Pretendard-Light',
                ),
              ),
              Text(
                totalAmount,
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 10,
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

// 카테고리 버튼을 위한 SliverPersistentHeaderDelegate 구현
class _SliverCategoryButtonsDelegate extends SliverPersistentHeaderDelegate {
  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          // BoxShadow(
          //   color: Colors.black.withOpacity(0.15),
          //   offset: Offset(0, 4),
          //   blurRadius: 10,
          //   spreadRadius: 0,
          // ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // 전체 버튼
          Container(
            height: 36, // 높이 감소
            width: 70, // 너비 감소
            decoration: BoxDecoration(
              color: const Color(0xFF3A88F4),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                // BoxShadow(
                //   color: Colors.black.withOpacity(0.15),
                //   offset: Offset(0, 2),
                //   blurRadius: 4,
                //   spreadRadius: 0,
                // ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              '전체',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14, // 글씨 크기 감소
                fontFamily: 'Pretendard-Medium',
              ),
            ),
          ),
          
          const SizedBox(width: 12), // 버튼 간 간격
          
          // 적립 버튼
          Container(
            height: 36, // 높이 감소
            width: 70, // 너비 감소
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF5D9EFF),
                width: 0.8,
              ),
              boxShadow: [
                // BoxShadow(
                //   color: Colors.black.withOpacity(0.1),
                //   offset: Offset(0, 2),
                //   blurRadius: 4,
                //   spreadRadius: 0,
                // ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              '적립',
              style: TextStyle(
                color: const Color(0xFF3A88F4),
                fontSize: 14, // 글씨 크기 감소
                fontFamily: 'Pretendard-Medium',
              ),
            ),
          ),
          
          const SizedBox(width: 12), // 버튼 간 간격
          
          // 사용 버튼
          Container(
            height: 36, // 높이 감소
            width: 70, // 너비 감소
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF5D9EFF),
                width: 0.8,
              ),
              boxShadow: [
                // BoxShadow(
                //   color: Colors.black.withOpacity(0.1),
                //   offset: Offset(0, 2),
                //   blurRadius: 4,
                //   spreadRadius: 0,
                // ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              '사용',
              style: TextStyle(
                color: const Color(0xFF3A88F4),
                fontSize: 14, // 글씨 크기 감소
                fontFamily: 'Pretendard-Medium',
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  double get maxExtent => 60.0; // 높이 설정

  @override
  double get minExtent => 60.0; // 최소 높이도 동일하게 설정

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
} 