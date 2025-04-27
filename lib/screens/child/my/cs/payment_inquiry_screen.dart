import 'package:flutter/material.dart';

class PaymentInquiryScreen extends StatefulWidget {
  const PaymentInquiryScreen({super.key});

  @override
  State<PaymentInquiryScreen> createState() => _PaymentInquiryScreenState();
}

class _PaymentInquiryScreenState extends State<PaymentInquiryScreen> {
  // 현재 선택된 카테고리 (0: 결제/구독권, 1: 적립금, 2: 포인트)
  int _selectedCategory = 0;

  // 카테고리 목록
  final List<String> _categories = ['결제 / 구독권', '적립금', '포인트'];

  // 검색 기능을 위한 변수 추가
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // 자주 묻는 질문 목록
  final List<Map<String, String>> _faqs = [
    {
      'category': '결제 / 구독권',
      'question': '구독권 자동 결제를 해지하고 싶어요',
    },
    {
      'category': '결제 / 구독권',
      'question': '멤버 추가를 어떻게 하나요?',
    },
    {
      'category': '결제 / 구독권',
      'question': '구독권 정지가 가능하나요?',
    },
    {
      'category': '적립금',
      'question': '이체가 안돼요',
    },
    {
      'category': '포인트',
      'question': '포인트는 어디에 사용할 수 있나요?',
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false, // 키보드가 올라와도 화면 레이아웃이 변경되지 않도록 설정
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          '결제 문의',
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w700,
            letterSpacing: -0.32,
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
              // 홈 화면으로 이동 로직
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // 스크롤 가능한 메인 컨텐츠
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 검색창 영역
                _buildSearchBar(),
                
                // 자주 묻는 질문 섹션
                _buildFaqSection(),
                
                // 1:1 상담 섹션을 위한 여백
                SizedBox(height: MediaQuery.of(context).size.height * 0.5),
              ],
            ),
          ),
          
          // 하단에 고정된 1:1 상담 섹션
          Positioned(
            left: 0,
            right: 0,
            bottom: 20,
            child: Container(
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1:1 상담 섹션
                  _buildConsultationSection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // 검색창 위젯
  Widget _buildSearchBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Container(
        width: 358,
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: ShapeDecoration(
          shape: RoundedRectangleBorder(
            side: BorderSide(
              width: 1,
              color: const Color(0xFFDADADA),
            ),
            borderRadius: BorderRadius.circular(32),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center, // 정확한 세로 중앙 정렬
          children: [
            Icon(
              Icons.search,
              color: const Color(0xFF999999),
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.trim().toLowerCase();
                    
                    // 검색어가 있고 결과가 있는 경우 자동으로 첫 번째 결과의 카테고리 탭으로 이동
                    if (_searchQuery.isNotEmpty) {
                      // 현재 검색어에 매칭되는 결과 찾기
                      final searchResults = _faqs.where((faq) =>
                        faq['question']!.toLowerCase().contains(_searchQuery) ||
                        faq['category']!.toLowerCase().contains(_searchQuery)
                      ).toList();
                      
                      // 검색 결과가 있으면
                      if (searchResults.isNotEmpty) {
                        // 첫 번째 검색 결과의 카테고리
                        final firstResultCategory = searchResults.first['category'];
                        // 해당 카테고리의 인덱스 찾기
                        final categoryIndex = _categories.indexOf(firstResultCategory!);
                        // 카테고리 인덱스가 유효하면 해당 탭으로 이동
                        if (categoryIndex != -1 && categoryIndex != _selectedCategory) {
                          _selectedCategory = categoryIndex;
                        }
                      }
                    }
                  });
                },
                textAlignVertical: TextAlignVertical.center,
                style: const TextStyle(
                  color: Color(0xFF202020),
                  fontSize: 14,
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w300,
                  letterSpacing: -0.28,
                  height: 1.0, // 행간 줄임
                ),
                decoration: const InputDecoration(
                  hintText: '궁금한 내용을 입력해 주세요',
                  hintStyle: TextStyle(
                    color: Color(0xFF999999),
                    fontSize: 14,
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w300,
                    letterSpacing: -0.28,
                  ),
                  border: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  contentPadding: EdgeInsets.only(bottom: 1), // 세로 위치 미세 조정
                  isDense: true,
                  isCollapsed: true, // 텍스트필드 크기를 텍스트에 맞게 조정
                ),
              ),
            ),
            // 검색어가 있을 때만 X 버튼 표시
            if (_searchQuery.isNotEmpty)
              GestureDetector(
                onTap: () {
                  setState(() {
                    _searchController.clear();
                    _searchQuery = '';
                  });
                },
                child: const Icon(
                  Icons.close,
                  color: Color(0xFF999999),
                  size: 20,
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  // 자주 묻는 질문 섹션
  Widget _buildFaqSection() {
    // 검색어가 있으면 카테고리 구분 없이 모든 항목에서 검색
    // 검색어가 없으면 선택된 카테고리만 표시
    final filteredFaqs = _faqs
        .where((faq) {
          // 검색어가 있는 경우 카테고리 상관없이 검색
          if (_searchQuery.isNotEmpty) {
            return faq['question']!.toLowerCase().contains(_searchQuery) ||
                   faq['category']!.toLowerCase().contains(_searchQuery);
          }
          
          // 검색어가 없는 경우 선택된 카테고리만 표시
          return faq['category'] == _categories[_selectedCategory];
        })
        .toList();
      
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 섹션 헤더
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '자주 묻는 질문',
                style: TextStyle(
                  color: const Color(0xFF202020),
                  fontSize: 18,
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.72,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '다른 고객들이 많이 물어본 질문이예요',
                style: TextStyle(
                  color: const Color(0xFF999999),
                  fontSize: 12,
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w300,
                  letterSpacing: -0.24,
                ),
              ),
            ],
          ),
        ),
        
        // 카테고리 탭 영역
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(_categories.length, (index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: _buildCategoryButton(index),
                );
              }),
            ),
          ),
        ),
        
        // FAQ 목록 - 필터링된 목록 사용
        Container(
          width: 358,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: filteredFaqs.isEmpty
                ? [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: Text(
                          '해당 카테고리에 질문이 없습니다.',
                          style: TextStyle(
                            color: const Color(0xFF999999),
                            fontSize: 12,
                            fontFamily: 'Pretendard',
                            fontWeight: FontWeight.w300,
                            letterSpacing: -0.24,
                          ),
                        ),
                      ),
                    )
                  ]
                : List.generate(filteredFaqs.length, (index) {
                    return _buildFaqItem(filteredFaqs[index]);
                  }),
          ),
        ),
        
        // 구분선 추가 - FAQ 섹션과 1:1 상담 섹션 사이
        Container(
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
      ],
    );
  }
  
  // 카테고리 버튼 위젯
  Widget _buildCategoryButton(int index) {
    final bool isSelected = _selectedCategory == index;
    
    // 카테고리에 따라 다른 패딩 적용
    double horizontalPadding = 18;
    if (_categories[index] == '결제 / 구독권') {
      horizontalPadding = 24; // 결제/구독권에 더 넓은 패딩 적용
    }
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = index;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 8),
        constraints: BoxConstraints(minWidth: 80), // 최소 너비 설정
        decoration: ShapeDecoration(
          color: isSelected 
              ? const Color(0xFF3A88F4) 
              : const Color(0xFFEFF2F6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        child: Text(
          _categories[index],
          textAlign: TextAlign.center, // 텍스트 중앙 정렬
          style: TextStyle(
            color: isSelected 
                ? Colors.white 
                : const Color(0xFF8490A3),
            fontSize: 13,
            fontFamily: 'Pretendard',
            fontWeight: isSelected ? FontWeight.w500 : FontWeight.w300,
            letterSpacing: -0.24,
          ),
        ),
      ),
    );
  }
  
  // FAQ 항목 위젯
  Widget _buildFaqItem(Map<String, String> faq) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 37,
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 카테고리 텍스트
                    Container(
                      width: 85, // 카테고리 너비 확장 (70 → 85)
                      child: Text(
                        '[${faq['category']}]',
                        overflow: TextOverflow.visible, // 텍스트 오버플로우 허용
                        softWrap: false, // 줄바꿈 방지
                        style: TextStyle(
                          color: const Color(0xFF353535),
                          fontSize: 12,
                          fontFamily: 'Pretendard',
                          fontWeight: FontWeight.w500,
                          height: 1.45,
                          letterSpacing: -0.24,
                        ),
                      ),
                    ),
                    
                    // 질문 내용 텍스트
                    Expanded(
                      child: Text(
                        faq['question'] ?? '',
                        style: TextStyle(
                          color: const Color(0xFF666666),
                          fontSize: 12,
                          fontFamily: 'Pretendard',
                          fontWeight: FontWeight.w300,
                          height: 1.45,
                          letterSpacing: -0.24,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // 아래 방향 화살표 아이콘
              Icon(
                Icons.keyboard_arrow_down,
                color: const Color(0xFFCCCCCC),
                size: 20,
              ),
            ],
          ),
        ),
        // 구분선 추가
        Divider(
          height: 1,
          thickness: 1,
          color: const Color(0xFFEEEEEE),
        ),
      ],
    );
  }
  
  // 1:1 상담 섹션
  Widget _buildConsultationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 섹션 헤더
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '1:1 상담',
                style: TextStyle(
                  color: const Color(0xFF202020),
                  fontSize: 18,
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.72,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '전화로 빠르게 문의를 해결할 수 있어요.',
                style: TextStyle(
                  color: const Color(0xFF999999),
                  fontSize: 12,
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w300,
                  letterSpacing: -0.24,
                ),
              ),
            ],
          ),
        ),
        
        // 전화 상담 카드
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Container(
            width: 358,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: ShapeDecoration(
              color: const Color(0xFFEFF2F6),
              shape: RoundedRectangleBorder(
                side: BorderSide(
                  width: 1,
                  color: const Color(0xFF5D9EFF),
                ),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '전화 상담',
                  style: TextStyle(
                    color: const Color(0xFF202020),
                    fontSize: 14,
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.32,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '09:00 - 18:00 / 점심 시간 오후 12:00 - 13:00 / 토, 일, 공휴일 휴무',
                  style: TextStyle(
                    color: const Color(0xFF666666),
                    fontSize: 10,
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w300,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // 페이지 하단 여백
        const SizedBox(height: 40),
      ],
    );
  }
} 