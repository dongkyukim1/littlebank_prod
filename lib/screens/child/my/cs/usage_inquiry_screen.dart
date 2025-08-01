import 'package:flutter/material.dart';

class UsageInquiryScreen extends StatefulWidget {
  const UsageInquiryScreen({super.key});

  @override
  State<UsageInquiryScreen> createState() => _UsageInquiryScreenState();
}

class _UsageInquiryScreenState extends State<UsageInquiryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _selectedCategory = 0;
  final Set<int> _expandedFaqs = <int>{}; // 확장된 FAQ의 인덱스를 저장

  final List<String> _categories = ['기능 문의', '계정 관리', '기록 관리', '오류'];

  final List<Map<String, dynamic>> _faqs = [
    {
      'category': '기능 문의',
      'question': '미션과 챌린지는 어떻게 다른가요?',
      'answers': [
        {
          'title': '미션과 챌린지의 차이점',
          'content': '미션은 부모님이 직접 생성해 주는 것이고, 챌린지는 저희가 직접 제공해 드리는 목록 중 아이가 직접 선택하여 정할 수 있는 활동이예요.',
        },
        {
          'title': '목표 설정과 활용 방법',
          'content': '목표는 자녀가 주에 최대 2개를 직접 설정할 수 있는 것으로, 부모님이 미션을 제공하지 않는다면 채팅을 통해 조르거나, 저희가 제공하는 챌린지를 직접 탐색하고 목표를 통해 요청해 보세요.',
        },
      ],
    },
    {
      'category': '기능 문의',
      'question': '학습 인증의 경우 어떤 방식으로 인증하나요?',
      'answers': [
        {
          'title': '활동 인증 방식 안내',
          'content': '미션과 챌린지의 경우, 기본적인 진행률은 시간이 흐름에 따라 늘어나지만, 주마다 최대 2개로 설정할 수 있는 목표의 경우에는 매일 목표 확인 스탬프를 찍을 수 있도록 알려드리고 있어요.',
        },
        {
          'title': '사진 인증과 타이머 기능',
          'content': 'AI 기술을 활용한 동영상 촬영 인증 방식은 적용되지 않고 있으며 채팅 내 사진 전송을 통한 자율 확인 방식으로 진행하고 있어요. 이외에도 자녀가 타이머 기능을 통해 직접 목표 달성까지 노력한 시간을 측정할 수 있도록 지원하고 있어요.',
        },
      ],
    },
    {
      'category': '기능 문의',
      'question': '미션 제출 후 수정할 수 있나요?',
      'answers': [
        {
          'title': '미션 수정 불가 안내',
          'content': '부모님이 아이에게 미션 제공 후에는 수정할 수 없어요. 미션 생성 시, 신중하게 진행해 주세요.',
        },
      ],
    },
    {
      'category': '기능 문의',
      'question': '다른 앱의 채팅 기능과 다른 점이 있나요?',
      'answers': [
        {
          'title': '리틀뱅크 채팅 기능의 특징',
          'content': '일상적인 메시지를 주고받는 것도 가능하지만, 미션 전달과 같은 활동 관련 알림과 보상금 이체 관련 알림 등을 확인하고 바로 이동할 수 있어요.',
        },
      ],
    },
    {
      'category': '계정 관리',
      'question': '회원가입 시 꼭 계좌를 등록해야 하나요?',
      'answers': [
        {
          'title': '계좌 등록의 필요성',
          'content': '계좌 등록은 회원 가입 시 필수적인 사항은 아니예요. 하지만 미션, 챌린지 등 활동을 통한 보상금을 주고 누적된 보상금을 꺼낼 때 계좌 등록이 필수적이므로, 마이페이지 내 계좌 연결하기를 통해 꼭 연결해 주세요.',
        },
      ],
    },
    {
      'category': '계정 관리',
      'question': '부모님 계정 없이 아이만 가입할 수 있나요?',
      'answers': [
        {
          'title': '아이 단독 가입 가능',
          'content': '리틀뱅크는 부모님과 아이의 계정이 따로 구분되어 있어 아이 혼자서도 가입하여 이용할 수 있어요.',
        },
      ],
    },
    {
      'category': '계정 관리',
      'question': '부모님 계정으로 아이 계정의 정보도 볼 수 있나요?',
      'answers': [
        {
          'title': '계정 분리와 활동 내역 확인',
          'content': '부모님과 아이의 계정은 분리되어 있기 때문에 서로의 계정으로 로그인하지 않는 이상 볼 수 없어요.',
        },
        {
          'title': '자녀 활동 내역 확인 방법',
          'content': '자녀가 활동한 내역은 부모님 계정의 홈 화면과 미션 화면을 통해 확인해 주세요.',
        },
      ],
    },
    {
      'category': '계정 관리',
      'question': '회원 탈퇴 시 포인트는 어떻게 되나요?',
      'answers': [
        {
          'title': '탈퇴 시 포인트 처리',
          'content': '회원 탈퇴 시, 포인트 및 모든 활동 기록은 사라지게 되어있어요. 남은 포인트는 자동으로 등록된 계좌로 환불되지 않기 때문에, 다른 계좌로 미리 잔액을 보내주세요.',
        },
      ],
    },
    {
      'category': '기록 관리',
      'question': '포인트 충전, 적립 및 이체 내역은 언제까지 볼 수 있나요?',
      'answers': [
        {
          'title': '포인트 내역 조회 기간',
          'content': '포인트의 출입금 및 환전 내역은 금융 활동이 처음 시작된 시점부터 계속 확인하실 수 있어요.',
        },
      ],
    },
    {
      'category': '기록 관리',
      'question': '포인트 충전, 적립 내역은 부모님과 공유가 되나요?',
      'answers': [
        {
          'title': '포인트 내역 공유 여부',
          'content': '아이의 포인트 적립 및 충전 내역은 부모님의 계정과 자동으로 공유되지 않아요.',
        },
      ],
    },
    {
      'category': '기록 관리',
      'question': '채팅창 기록은 언제까지 볼 수 있나요? 데이터 보관 기간이 정해져 있나요?',
      'answers': [
        {
          'title': '채팅 기록 보관 기간',
          'content': '최근 6개월 동안의 대화 기록만 조회할 수 있어요.',
        },
      ],
    },
    {
      'category': '기록 관리',
      'question': '활동 기록을 정리하거나 숨길 수 있나요?',
      'answers': [
        {
          'title': '활동 기록 관리',
          'content': '현재 활동 기록을 숨기는 기능은 제공하고 있지 않아요. 참여한 활동 기록은 아이와, 부모 계정에서 둘 다 조회할 수 있어요.',
        },
        {
          'title': '피드 작성글 관리',
          'content': '아이의 경우 마이페이지 작성글 내역 화면에서 피드 내역 조회 및 삭제, 수정이 가능해요.',
        },
      ],
    },
    {
      'category': '오류',
      'question': '푸시 알림이 오지 않아요',
      'answers': [
        {
          'title': '알림 권한 확인',
          'content': '기기 설정에서 리틀뱅크 앱의 알림 권한이 허용되어 있는지 확인해 주세요.',
        },
        {
          'title': '백그라운드 실행 확인',
          'content': '앱이 백그라운드에서 실행 중인지, 또는 절전 모드 등으로 알림이 차단되지 않았는지 확인해 주세요.',
        },
        {
          'title': '앱 재설치',
          'content': '앱을 삭제 후 재설치하면 알림 설정이 초기화되어 문제가 해결될 수 있어요.',
        },
        {
          'title': '알림 설정 확인',
          'content': '부모님 계정과 아이 계정에 따라 알림 수신 항목이 다를 수 있으니, 앱 내 [설정 > 알림 항목]도 함께 확인해 주세요. 위 방법으로도 해결되지 않을 경우, 고객센터(soon12500@naver.com)로 문의해 주시면 빠르게 도움드릴게요.',
        },
      ],
    },
    {
      'category': '오류',
      'question': '사진이 업로드 되지 않아요',
      'answers': [
        {
          'title': '네트워크 상태 확인',
          'content': '인터넷 연결 상태가 불안정할 경우, 업로드에 실패할 수 있어요. 안정적인 네트워크 환경에서 다시 시도해 주세요.',
        },
        {
          'title': '사진 접근 권한 확인',
          'content': '기기 설정에서 앱의 사진 접근 권한이 허용되어 있는지 확인해 주세요.',
        },
        {
          'title': '파일 용량 확인',
          'content': '사진 파일의 용량이 너무 큰 경우 업로드가 지연될 수 있어요. 가능하면 저용량 사진을 선택해 주세요.',
        },
        {
          'title': '문제 해결 방법',
          'content': '문제가 계속된다면 앱을 재실행하거나 기기를 재부팅해 보세요. 위 방법으로도 해결되지 않을 경우, 고객센터(soon12500@naver.com)로 문의해 주시면 빠르게 도움드릴게요.',
        },
      ],
    },
    {
      'category': '오류',
      'question': '누적된 포인트가 다른 것 같아요',
      'answers': [
        {
          'title': '포인트 출금 확인',
          'content': '마이페이지 내 총 포인트 내역 내에서 포인트 꺼내기를 통해 출금한 적이 있는지 확인해 주세요.',
        },
        {
          'title': '고객센터 문의',
          'content': '위 방법으로도 해결되지 않을 경우, 고객센터(soon12500@naver.com)로 문의해 주시면 빠르게 도움드릴게요.',
        },
      ],
    },
    {
      'category': '오류',
      'question': '구독권 결제에 실패했어요',
      'answers': [
        {
          'title': '결제 수단 확인',
          'content': '플레이 스토어에 등록된 결제 수단이 유효한지 확인해 주세요.',
        },
        {
          'title': '네트워크 상태 확인',
          'content': '인터넷 연결 상태가 불안정할 경우, 결제가 실패할 수 있어요. 안정적인 네트워크 환경에서 다시 시도해 주세요.',
        },
        {
          'title': '앱 업데이트 확인',
          'content': '앱이 최신 버전인지 확인한 후, 최신 버전으로 업데이트한 뒤 다시 시도해 주세요.',
        },
        {
          'title': '문제 해결 방법',
          'content': '결제 오류가 계속된다면, 스토어 내 \'구독\' 메뉴를 확인하거나 고객센터(soon12500@naver.com)로 문의해 주세요.',
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
              '이용 문의',
              style: TextStyle(
                color: const Color(0xFF202020),
                fontSize: 16,
                fontFamily: 'Pretendard-Bold',
                letterSpacing: -0.72,
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
      offset: const Offset(0, 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
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
    final categoryName = _categories[index];
    final displayName = categoryName;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = index;
        });
      },
      child: Container(
        height: 35, // 25에서 35로 높이 증가
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              width: isSelected ? 2.0 : 0.5,
              color:
                  isSelected
                      ? const Color(0xFF202020)
                      : const Color(0xFFCCCCCC),
            ),
          ),
        ),
        child: Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.only(top: 4), // 텍스트를 위로 올림
            child: Text(
              displayName,
              textAlign: TextAlign.center,
              style: TextStyle(
                color:
                    isSelected
                        ? const Color(0xFF202020)
                        : const Color(0xFF999999),
                fontSize: 13,
                fontFamily: isSelected ? 'Pretendard-Bold' : 'Pretendard-Light',
                letterSpacing: -0.26,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // FAQ 항목 위젯
  Widget _buildFaqItem(Map<String, dynamic> faq) {
    // FAQ의 고유 인덱스 생성 (질문 기반)
    final faqIndex = _faqs.indexOf(faq);
    final isExpanded = _expandedFaqs.contains(faqIndex);

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
                  _expandedFaqs.remove(faqIndex);
                } else {
                  _expandedFaqs.add(faqIndex);
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
                              fontSize: 12,
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
          if (isExpanded) ...[
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
                children: List.generate((faq['answers'] as List).length, (
                  index,
                ) {
                  final answer = (faq['answers'] as List)[index];
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom:
                          index < (faq['answers'] as List).length - 1 ? 12 : 0,
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
                }),
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
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '1:1 전화 상담',
                style: TextStyle(
                  color: const Color(0xFF202020),
                  fontSize: 18,
                  fontFamily: 'Pretendard-Bold',
                  letterSpacing: -0.72,
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
