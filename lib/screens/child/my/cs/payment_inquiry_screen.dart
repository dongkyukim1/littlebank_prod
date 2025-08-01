import 'package:flutter/material.dart';

class PaymentInquiryScreen extends StatefulWidget {
  const PaymentInquiryScreen({super.key});

  @override
  State<PaymentInquiryScreen> createState() => _PaymentInquiryScreenState();
}

class _PaymentInquiryScreenState extends State<PaymentInquiryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _selectedCategory = 0;
  final Set<int> _expandedFaqs = <int>{}; // 확장된 FAQ의 인덱스를 저장

  final List<String> _categories = ['구독', '결제', '포인트'];

  final List<Map<String, dynamic>> _faqs = [
    {
      'category': '구독',
      'question': '구독은 자동 갱신되나요?',
      'answers': [
        {
          'title': '자동 갱신 안내',
          'content': '리틀뱅크의 구독 서비스는 최초 결제 후 매달 자동으로 갱신되어 구독권 멤버 내 대표가 결제하게 돼요.',
        },
        {
          'title': '자동 결제 조건',
          'content': '다음 결제일 전에 직접 해지하지 않으면, 동일한 조건으로 자동 결제가 진행돼요.',
        },
        {
          'title': '구독 관리 방법',
          'content': '자동 갱신 여부는 플레이스토어의 구독 관리 메뉴에서 확인하거나 변경할 수 있어요. 구독 해지를 원하실 경우, 다음 결제일 최소 24시간 전에 직접 해지해 주세요.',
        },
        {
          'title': '주의사항',
          'content': '앱 내에서는 자동 해지 설정이 불가능하므로 반드시 스토어에서 관리해 주세요.',
        },
      ],
    },
    {
      'category': '구독',
      'question': '구독 관련 정보는 어디서 확인하나요?',
      'answers': [
        {
          'title': '구독 정보 확인',
          'content': '마이페이지 내 구독권 관리 화면에서 구독권 관련 기한 정보와, 함께 이용 중인 멤버, 다른 구독권의 가격 정보를 찾아볼 수 있어요.',
        },
      ],
    },
    {
      'category': '구독',
      'question': '구독을 중단하고 싶어요',
      'answers': [
        {
          'title': '구독 중단 안내',
          'content': '구독 중단(해지)은 사용 중인 앱스토어에서 직접 진행하셔야 해요. 아래 항목을 확인해 보세요.',
        },
        {
          'title': '플레이스토어 해지 절차',
          'content': '플레이스토어 앱을 실행해 주세요.\n오른쪽 상단의 프로필 아이콘을 터치해 주세요.\n[결제 및 정기 결제] > [정기 결제] 메뉴로 이동해 주세요.\n리틀뱅크 항목을 선택한 후, [구독 취소]를 진행해 주세요.',
        },
      ],
    },
    {
      'category': '구독',
      'question': '하나의 구독권으로 여러 명이 이용 가능한가요?',
      'answers': [
        {
          'title': '구독권 종류',
          'content': '리틀뱅크의 구독권은 1인용 / 3인용/ 5인용 이렇게 구성되어 있으며, 초대를 통해 3인용, 5인용 구독권을 함께 이용하실 수 있어요.',
        },
        {
          'title': '초대 방법',
          'content': '초대하고 싶으신 경우, 마이페이지 내 멤버 관리 화면에서 연락처로 초대하기를 선택해 주세요.',
        },
      ],
    },
    {
      'category': '결제',
      'question': '정기 구독을 위한 결제는 어디서 할 수 있나요?',
      'answers': [
        {
          'title': '결제 진행 방법',
          'content': '결제는 마이페이지 내 구독권 혜택 화면에서 진행하실 수 있어요.',
        },
      ],
    },
    {
      'category': '결제',
      'question': '결제를 잘못했는데, 환불할 수 있나요?',
      'answers': [
        {
          'title': '환불 진행 방법',
          'content': '환불을 진행하고 싶으신 경우, 아래 항목을 확인해 보세요.',
        },
        {
          'title': '플레이 스토어 환불 절차',
          'content': '플레이 스토어 앱을 실행해 주세요.\n오른쪽 상단의 프로필 아이콘을 터치해 주세요.\n[결제 및 정기 결제] > [예산 및 주문 내역] 메뉴로 이동해 주세요.\n환불하려는 구독권에서 문제 신고를 선택해 주세요.\n환불 사유에 해당하는 옵션을 선택하여 제출해 주세요.',
        },
      ],
    },
    {
      'category': '결제',
      'question': '결제 내역은 어디서 확인하나요?',
      'answers': [
        {
          'title': '결제 내역 확인 방법',
          'content': '정기 결제 내역을 확인하고 싶으신 경우, 아래 항목을 확인해 보세요.',
        },
        {
          'title': '플레이 스토어 결제 내역',
          'content': '플레이 스토어 앱을 실행해 주세요.\n오른쪽 상단의 프로필 아이콘을 터치해 주세요.\n[결제 및 정기 결제] > [정기 결제] 메뉴로 이동해 주세요.\n현재 활성화된 구독과 이전에 사용한 구독 내역을 확인할 수 있어요.',
        },
      ],
    },
    {
      'category': '결제',
      'question': '결제 후 기능이 안 열려요',
      'answers': [
        {
          'title': '앱 재실행',
          'content': '앱을 완전히 종료 후 다시 실행해 보세요. 로그아웃 후 다시 로그인하면 결제 내역이 정상 반영될 수 있어요.',
        },
        {
          'title': '앱 업데이트 확인',
          'content': '앱이 최신 버전인지 확인하고, 필요한 경우 업데이트해 주세요.',
        },
        {
          'title': '고객센터 문의',
          'content': '문제가 계속되면 결제 정보를 첨부해 고객센터(soon12500@naver.com)에 문의해 주세요. 신속히 확인해 드릴게요.',
        },
      ],
    },
    {
      'category': '포인트',
      'question': '리틀뱅크 앱에서 포인트는 어떤 의미인가요?',
      'answers': [
        {
          'title': '포인트의 의미',
          'content': '리틀뱅크에서 포인트는 현금과 동일한 교환 기능을 갖고 있으며 앱 내 활동에 대한 보상금 지급을 원활하게 하기 위해서 부모님이 충전을 통해 현금을 포인트로 전환하여 사용할 수 있어요.',
        },
        {
          'title': '포인트 전환',
          'content': '포인트 전환은 충전을 통해 수수료 없이 가능해요.',
        },
      ],
    },
    {
      'category': '포인트',
      'question': '포인트 이용과 관련된 용어가 어려워요',
      'answers': [
        {
          'title': '포인트 용어 설명',
          'content': '포인트 관련 용어는 포인트 충전/ 포인트 보내기/ 포인트 꺼내기가 있어요.',
        },
        {
          'title': '포인트 충전',
          'content': '결제 기능을 통해 현금을 앱 내 포인트로 바꾸는 것을 의미해요.',
        },
        {
          'title': '포인트 보내기',
          'content': '앱 내에서 부모님이 자녀에게 보상금을 지급하는 것과 같은 포인트 이동을 의미해요.',
        },
        {
          'title': '포인트 꺼내기',
          'content': '충전 및 적립으로 누적된 포인트를 앱에서 계좌로 현금화 하는 경우를 의미해요.',
        },
      ],
    },
    {
      'category': '포인트',
      'question': '포인트는 어떻게 얻을 수 있나요?',
      'answers': [
        {
          'title': '포인트 획득 방법',
          'content': '미션, 챌린지, 목표를 완료하면 보상금으로 승인 받은 금액을 부모님이 포인트로 지급할 거예요.',
        },
      ],
    },
    {
      'category': '포인트',
      'question': '친구에게 포인트를 보낼 수 있나요?',
      'answers': [
        {
          'title': '포인트 전송 기능',
          'content': '리틀뱅크에서 현재 포인트를 친구에게 직접 보내는 기능은 없어요.',
        },
        {
          'title': '현재 제공 기능',
          'content': '부모님이 아이에게 보상금을 지급하는 기능만 제공 중이며, 향후 서비스에서 검토하겠습니다.',
        },
      ],
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
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),

                  // 검색 섹션
                  _buildSearchSection(),

                  // FAQ 섹션
                  _buildFaqSection(),

                  // 1:1 상담 섹션
                  _buildConsultationSection(),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 상단 앱바
  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(48),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 16),
          child: AppBar(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            elevation: 0,
            toolbarHeight: 32,
            titleSpacing: 0,
            leading: Padding(
              padding: const EdgeInsets.only(left: 16),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: Image.asset(
                    'assets/icons/my/뒤로가기.png',
                    width: 24,
                    height: 24,
                  ),
                ),
              ),
            ),
            leadingWidth: 56,
            title: Text(
              '결제 문의',
              style: TextStyle(
                color: const Color(0xFF202020),
                fontSize: 16,
                fontFamily: 'Pretendard-Bold',
                letterSpacing: -0.64,
              ),
            ),
            centerTitle: true,
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: GestureDetector(
                  onTap: () {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/home',
                      (route) => false,
                    );
                  },
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: Image.asset(
                      'assets/icons/my/home.png',
                      width: 24,
                      height: 24,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 검색 섹션
  Widget _buildSearchSection() {
    return Transform.translate(
      offset: const Offset(0, -18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFEAEAEA),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: const Color(0xFFDADADA), width: 0.8),
          ),
          child: Row(
            children: [
              Image.asset(
                'assets/icons/my/검색.png',
                width: 24,
                height: 24,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                      if (_searchQuery.isNotEmpty) {
                        // 현재 검색어에 매칭되는 결과 찾기
                        final searchResults =
                            _faqs
                                .where(
                                  (faq) =>
                                      faq['question']!.toLowerCase().contains(
                                        _searchQuery,
                                      ) ||
                                      faq['category']!.toLowerCase().contains(
                                        _searchQuery,
                                      ),
                                )
                                .toList();

                        // 검색 결과가 있으면
                        if (searchResults.isNotEmpty) {
                          // 첫 번째 검색 결과의 카테고리
                          final firstResultCategory =
                              searchResults.first['category'];
                          // 해당 카테고리의 인덱스 찾기
                          final categoryIndex = _categories.indexOf(
                            firstResultCategory!,
                          );
                          // 카테고리 인덱스가 유효하면 해당 탭으로 이동
                          if (categoryIndex != -1 &&
                              categoryIndex != _selectedCategory) {
                            _selectedCategory = categoryIndex;
                          }
                        }
                      }
                    });
                  },
                  style: const TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 12,
                    fontWeight: FontWeight.w300,
                    letterSpacing: -0.24,
                    color: Color(0xFF202020),
                  ),
                  decoration: const InputDecoration(
                    hintText: '궁금한 내용을 입력해 주세요',
                    hintStyle: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 12,
                      fontWeight: FontWeight.w300,
                      letterSpacing: -0.24,
                      color: Color(0xFF999999),
                    ),
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    fillColor: Color(0xFFEAEAEA),
                    filled: true,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 자주 묻는 질문 섹션
  Widget _buildFaqSection() {
    // 검색어가 있으면 카테고리 구분 없이 모든 항목에서 검색
    // 검색어가 없으면 선택된 카테고리만 표시
    final filteredFaqs =
        _faqs.where((faq) {
          // 검색어가 있는 경우 카테고리 상관없이 검색
          if (_searchQuery.isNotEmpty) {
            return faq['question']!.toLowerCase().contains(_searchQuery) ||
                faq['category']!.toLowerCase().contains(_searchQuery);
          }

          // 검색어가 없는 경우 선택된 카테고리만 표시
          return faq['category'] == _categories[_selectedCategory];
        }).toList();

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
                  fontSize: 16,
                  fontFamily: 'Pretendard-Bold',
                  letterSpacing: -0.64,
                ),
              ),
              Text(
                '다른 고객들이 많이 물어본 질문이예요',
                style: TextStyle(
                  color: const Color(0xFF999999),
                  fontSize: 12,
                  fontFamily: 'Pretendard-Light',
                  letterSpacing: -0.24,
                ),
              ),
            ],
          ),
        ),

        // 카테고리 탭 영역
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(_categories.length, (index) {
                    return Expanded(child: _buildCategoryButton(index));
                  }),
                ),
              ),
            ],
          ),
        ),

        // FAQ 목록 - 필터링된 목록 사용
        Container(
          width: 358,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children:
                filteredFaqs.isEmpty
                    ? [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child: Text(
                            '해당 카테고리에 질문이 없습니다.',
                            style: TextStyle(
                              color: const Color(0xFF999999),
                              fontSize: 12,
                              fontFamily: 'Pretendard-Light',
                              letterSpacing: -0.24,
                            ),
                          ),
                        ),
                      ),
                    ]
                    : List.generate(filteredFaqs.length, (index) {
                      return _buildFaqItem(filteredFaqs[index], index);
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
              side: BorderSide(width: 0.10, color: const Color(0xFF8490A3)),
            ),
          ),
        ),
      ],
    );
  }

  // 카테고리 버튼 위젯
  Widget _buildCategoryButton(int index) {
    final bool isSelected = _selectedCategory == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = index;
        });
      },
      child: Container(
        width: double.infinity,
        height: 35,
        margin: EdgeInsets.only(right: index < _categories.length - 1 ? 8 : 0),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? Colors.black : const Color(0xFFE0E0E0),
              width: isSelected ? 2.0 : 0.5,
            ),
          ),
        ),
        child: Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              _categories[index],
              style: TextStyle(
                color: isSelected ? Colors.black : const Color(0xFF999999),
                fontSize: 12,
                fontFamily: isSelected ? 'Pretendard-Bold' : 'Pretendard-Light',
                letterSpacing: -0.24,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // FAQ 항목 위젯
  Widget _buildFaqItem(Map<String, dynamic> faq, int index) {
    // 전체 FAQ 목록에서의 실제 인덱스를 찾기
    final int actualIndex = _faqs.indexOf(faq);
    final bool isExpanded = _expandedFaqs.contains(actualIndex);

    // 현재 필터링된 FAQ 목록에서의 인덱스 찾기
    final filteredFaqs =
        _faqs.where((faq) {
          // 검색어가 있는 경우 카테고리 상관없이 검색
          if (_searchQuery.isNotEmpty) {
            return faq['question']!.toLowerCase().contains(_searchQuery) ||
                faq['category']!.toLowerCase().contains(_searchQuery);
          }

          // 검색어가 없는 경우 선택된 카테고리만 표시
          return faq['category'] == _categories[_selectedCategory];
        }).toList();

    final currentItemIndex = filteredFaqs.indexOf(faq);
    final isLastItem = currentItemIndex == filteredFaqs.length - 1;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 질문 헤더
          GestureDetector(
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedFaqs.remove(actualIndex);
                } else {
                  _expandedFaqs.add(actualIndex);
                }
              });
            },
            child: Container(
              width: double.infinity,
              height: 37,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Q 아이콘 (파란 글씨)
                        Text(
                          'Q',
                          style: TextStyle(
                            color: const Color(0xFF3A88F4),
                            fontSize: 12,
                            fontFamily: 'Pretendard-Bold',
                          ),
                        ),
                        const SizedBox(width: 8),

                        // 질문 내용 텍스트
                        Expanded(
                          child: Text(
                            faq['question'] ?? '',
                            style: TextStyle(
                              color: const Color(0xFF202020),
                              fontSize: 12, // 11에서 12로 증가
                              fontFamily: 'Pretendard-Light',
                              letterSpacing: -0.22,
                            ),
                            overflow: TextOverflow.ellipsis, // 말줄임표 처리 추가
                            maxLines: 1, // 한 줄로 제한
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 방향 화살표 아이콘 (확장 상태에 따라 변경)
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: const Color(0xFFCCCCCC),
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          // 답변 컨테이너 (확장된 경우에만 표시)
          if (isExpanded &&
              faq['answers'] != null &&
              (faq['answers'] as List).isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: ShapeDecoration(
                color: const Color(0xFFF0F0F0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(
                  (faq['answers'] as List?)?.length ?? 0,
                  (answerIndex) {
                    final answers = faq['answers'] as List?;
                    if (answers == null || answers.isEmpty) return Container();
                    final answer = answers[answerIndex];
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: answerIndex < answers.length - 1 ? 12 : 0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 답변 제목
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Image.asset(
                                'assets/icons/parent/my/cs_service/check.png',
                                width: 14,
                                height: 14,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  answer['title'] ?? '',
                                  style: TextStyle(
                                    color: const Color(0xFF202020),
                                    fontSize: 10,
                                    fontFamily: 'Pretendard-Bold',
                                    letterSpacing: -0.20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),

                          // 답변 내용
                          Padding(
                            padding: const EdgeInsets.only(left: 18),
                            child: Text(
                              answer['content'] ?? '',
                              style: TextStyle(
                                color: const Color(0xFF4A4A4A),
                                fontSize: 9,
                                fontFamily: 'Pretendard-Light',
                                height: 1.45,
                                letterSpacing: -0.18,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],

          const SizedBox(height: 8),

          // 구분선 - 펼쳐진 상태이거나 마지막 항목이면 구분선 제거
          if (!isExpanded && !isLastItem)
            Divider(height: 1, thickness: 1, color: const Color(0xFFEEEEEE)),
        ],
      ),
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
                '1:1 전화 상담',
                style: TextStyle(
                  color: const Color(0xFF202020),
                  fontSize: 16,
                  fontFamily: 'Pretendard-Bold',
                  letterSpacing: -0.64,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '09:00 - 18:00 / 점심 시간 오후 12:00 - 13:00 / 토, 일, 공휴일 휴무',
                style: TextStyle(
                  color: const Color(0xFF999999),
                  fontSize: 10,
                  fontFamily: 'Pretendard-Light',
                  letterSpacing: -0.24,
                ),
              ),
            ],
          ),
        ),

        // 고객센터 안내사항 카드
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Container(
            width: 358,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: ShapeDecoration(
              color: const Color(0xFFE7ECF6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '고객센터 안내사항',
                  style: TextStyle(
                    color: const Color.fromRGBO(0, 31, 85, 1),
                    fontSize: 14,
                    fontFamily: 'Pretendard-Bold',
                    letterSpacing: -0.32,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '• ',
                      style: TextStyle(
                        color: const Color(0xFF666666),
                        fontSize: 10,
                        fontFamily: 'Pretendard-Light',
                        letterSpacing: -0.24,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '자주 묻는 질문을 통해 빠르게 답변을 확인하실 수 있습니다.',
                        style: TextStyle(
                          color: const Color(0xFF666666),
                          fontSize: 10,
                          fontFamily: 'Pretendard-Light',
                          letterSpacing: -0.24,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '• ',
                      style: TextStyle(
                        color: const Color(0xFF666666),
                        fontSize: 10,
                        fontFamily: 'Pretendard-Light',
                        letterSpacing: -0.24,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '1:1 상담 운영 시간, 평일 09:00 - 18:00',
                        style: TextStyle(
                          color: const Color(0xFF666666),
                          fontSize: 10,
                          fontFamily: 'Pretendard-Light',
                          letterSpacing: -0.24,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
