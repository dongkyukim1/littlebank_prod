import 'package:flutter/material.dart';
import 'profile_selection_screen.dart';
import 'login_screen.dart';

class FinalScreen extends StatefulWidget {
  final String userId;
  final bool marketingAgreed;
  final String jumin;
  final String? password;
  final String? name;
  final String? phone;

  const FinalScreen({
    super.key,
    required this.userId,
    required this.marketingAgreed,
    required this.jumin,
    this.password,
    this.name,
    this.phone,
  });

  @override
  State<FinalScreen> createState() => _FinalScreenState();
}

class _FinalScreenState extends State<FinalScreen> {
  // 탭 인덱스 (계좌/증권)
  int _selectedTabIndex = 0;

  // 페이지 컨트롤러 추가
  late PageController _pageController;
  int _currentPage = 0;

  // 검색어 관리
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // 은행 목록 관리
  final List<Map<String, dynamic>> _allBanks = [
    {'name': '카카오뱅크', 'image': 'assets/logos/kakao_bank.png'},
    {'name': 'KB국민', 'image': 'assets/logos/kb_bank.png'},
    {'name': '씨티은행', 'image': 'assets/logos/citi_bank.png'},
    {'name': '신한', 'image': 'assets/logos/shinhan_bank.png'},
    {'name': '우리', 'image': 'assets/logos/woori_bank.png'},
    {'name': '하나', 'image': 'assets/logos/hana_bank.png'},
    {'name': '토스뱅크', 'image': 'assets/logos/toss.png'},
    {'name': '농협', 'image': 'assets/logos/nh_bank.png'},
    {'name': 'IBK기업', 'image': 'assets/logos/ibk_bank.png'},
    {'name': 'SC제일', 'image': 'assets/logos/sc_bank.png'},
    {'name': '부산', 'image': 'assets/logos/busan_bank.png'},
    {'name': '대구', 'image': 'assets/logos/daegu_bank.png'},
    {'name': '경남', 'image': 'assets/logos/kyongnam_bank.png'},
    {'name': '수협', 'image': 'assets/logos/suhyup_bank.png'},
    {'name': '광주', 'image': 'assets/logos/gwangju_bank.png'},
    {'name': '전북', 'image': 'assets/logos/jeonbuk_bank.png'},
    {'name': '제주', 'image': 'assets/logos/jeju_bank.png'},
    {'name': '케이뱅크', 'image': 'assets/logos/kbank.png'},
    {'name': '새마을금고', 'image': 'assets/logos/saemaul.png'},
    {'name': '신협', 'image': 'assets/logos/shinhyup.png'},
  ];

  // 증권사 목록 관리
  final List<Map<String, dynamic>> _allSecurities = [
    {'name': '키움증권', 'image': 'assets/logos/kiwoom.png'},
    {'name': '미래에셋증권', 'image': 'assets/logos/mirae_asset.png'},
    {'name': '삼성증권', 'image': 'assets/logos/samsung_securities.png'},
    {'name': 'NH투자증권', 'image': 'assets/logos/nh_investment.png'},
    {'name': '한국투자증권', 'image': 'assets/logos/korea_investment.png'},
    {'name': 'KB증권', 'image': 'assets/logos/kb_securities.png'},
    {'name': '신한투자증권', 'image': 'assets/logos/shinhan_investment.png'},
    {'name': '대신증권', 'image': 'assets/logos/daishin.png'},
    {'name': '카카오페이증권', 'image': 'assets/logos/kakaopay_securities.png'},
    {'name': '토스증권', 'image': 'assets/logos/toss_securities.png'},
  ];

  // 선택된 금융기관 정보
  String _selectedFinancialInstitutionImage = 'assets/logos/kakao_bank.png';
  String _selectedBankName = '카카오뱅크';

  // 계좌번호 입력 관련
  final TextEditingController _accountNumberController =
      TextEditingController();
  bool _isAccountNumberEntered = false;
  bool _isAccountRegistrationComplete = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _searchController.addListener(_updateSearchQuery);
  }

  @override
  void dispose() {
    _searchController.removeListener(_updateSearchQuery);
    _searchController.dispose();
    _accountNumberController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _updateSearchQuery() {
    setState(() {
      _searchQuery = _searchController.text;
    });
  }

  // 검색 결과를 반환하는 메서드
  List<Map<String, dynamic>> _getFilteredFinancialInstitutions() {
    final query = _searchQuery.toLowerCase();
    if (query.isEmpty) {
      return _selectedTabIndex == 0 ? _allBanks : _allSecurities;
    }

    return (_selectedTabIndex == 0 ? _allBanks : _allSecurities).where((item) {
      // 이름에 검색어가 포함된 경우
      if (item['name'].toLowerCase().contains(query)) {
        return true;
      }

      // 초성 검색 처리
      String name = item['name'];
      String initialConsonants = _extractInitialConsonants(name);
      return initialConsonants.contains(query);
    }).toList();
  }

  // 한글 초성 추출 메서드
  String _extractInitialConsonants(String text) {
    String result = '';
    for (int i = 0; i < text.length; i++) {
      int charCode = text.codeUnitAt(i);
      // 한글 범위 내 (가-힣)
      if (charCode >= 44032 && charCode <= 55203) {
        // 한글 초성 추출 공식
        int initialIndex = ((charCode - 44032) ~/ 588);
        // 초성 목록
        List<String> initialConsonants = [
          'ㄱ',
          'ㄲ',
          'ㄴ',
          'ㄷ',
          'ㄸ',
          'ㄹ',
          'ㅁ',
          'ㅂ',
          'ㅃ',
          'ㅅ',
          'ㅆ',
          'ㅇ',
          'ㅈ',
          'ㅉ',
          'ㅊ',
          'ㅋ',
          'ㅌ',
          'ㅍ',
          'ㅎ',
        ];
        result += initialConsonants[initialIndex];
      } else {
        // 한글이 아닌 경우 그대로 추가
        result += text[i].toLowerCase();
      }
    }
    return result;
  }

  void _selectFinancialInstitution(Map<String, dynamic> institution) {
    setState(() {
      _selectedFinancialInstitutionImage = institution['image'];
      _selectedBankName = institution['name'];
      _searchController.clear();
      _searchQuery = '';
    });

    // 금융기관 선택 시 바로 계좌번호 입력 화면을 띄움
    _showAccountNumberInputSheet();
  }

  // 검색창 영역
  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            spreadRadius: 1.5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Icon(Icons.search, color: Colors.grey[400], size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '찾으시는 은행/증권사를 검색하세요',
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                filled: false,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFF0047AB),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: const Icon(Icons.search, color: Colors.white, size: 20),
              onPressed: () {
                // 검색 기능 구현
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
          ),
        ],
      ),
    );
  }

  // 은행 그리드 뷰 (이미지와 일치하는 디자인)
  Widget _buildBankGridView() {
    final filteredList = _getFilteredFinancialInstitutions();

    if (filteredList.isEmpty) {
      return const Center(
        child: Text('검색 결과가 없습니다', style: TextStyle(color: Colors.grey)),
      );
    }

    final pageCount = (filteredList.length / 9).ceil();

    return Column(
      children: [
        // 그리드 뷰 (페이지 슬라이드 방식)
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemCount: pageCount,
            onPageChanged: (page) {
              setState(() {
                _currentPage = page;
              });
            },
            itemBuilder: (context, pageIndex) {
              final startIndex = pageIndex * 9;
              final endIndex =
                  (startIndex + 9) < filteredList.length
                      ? startIndex + 9
                      : filteredList.length;

              // 현재 페이지에 표시할 아이템 목록
              final pageItems = filteredList.sublist(startIndex, endIndex);

              // 9개가 되도록 빈 항목 추가 (3x3 그리드를 채우기 위함)
              while (pageItems.length < 9) {
                pageItems.add({'name': '', 'image': ''});
              }

              return Column(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          // 레이아웃 제약 조건을 기반으로 계산
                          final availableWidth = constraints.maxWidth;
                          final itemWidth =
                              (availableWidth - 24) / 3; // 3열에 간격 고려

                          return Wrap(
                            spacing: 12, // 가로 간격
                            runSpacing: 12, // 세로 간격
                            children: List.generate(9, (index) {
                              final institution = pageItems[index];

                              // 빈 항목인 경우 빈 공간 반환
                              if (institution['name'] == '') {
                                return SizedBox(
                                  width: itemWidth,
                                  height: itemWidth,
                                );
                              }

                              bool isSelected =
                                  institution['name'] == _selectedBankName;

                              return GestureDetector(
                                onTap:
                                    () => _selectFinancialInstitution(
                                      institution,
                                    ),
                                child: SizedBox(
                                  width: itemWidth,
                                  height: itemWidth,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 45,
                                        height: 45,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.white,
                                            border: Border.all(
                                              color:
                                                  isSelected
                                                      ? const Color(0xFF0047AB)
                                                      : Colors.white,
                                              width: isSelected ? 2.0 : 0,
                                            ),
                                            boxShadow:
                                                isSelected
                                                    ? [
                                                      BoxShadow(
                                                        color: const Color(
                                                          0xFF0047AB,
                                                        ).withOpacity(0.3),
                                                        blurRadius: 4,
                                                        spreadRadius: 0,
                                                        offset: const Offset(
                                                          0,
                                                          1,
                                                        ),
                                                      ),
                                                    ]
                                                    : [
                                                      BoxShadow(
                                                        color: Colors.black.withOpacity(0.1),
                                                        blurRadius: 6,
                                                        spreadRadius: 1.5,
                                                        offset: const Offset(0, 3),
                                                      ),
                                                    ],
                                          ),
                                          padding: const EdgeInsets.all(8),
                                          child: Image.asset(
                                            institution['image'],
                                            fit: BoxFit.contain,
                                            errorBuilder: (
                                              context,
                                              error,
                                              stackTrace,
                                            ) {
                                              return const Icon(
                                                Icons.account_balance,
                                                size: 16,
                                                color: Colors.grey,
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Flexible(
                                        child: Text(
                                          institution['name'],
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight:
                                                isSelected
                                                    ? FontWeight.bold
                                                    : FontWeight.w500,
                                            color:
                                                isSelected
                                                    ? const Color(0xFF0047AB)
                                                    : Colors.black,
                                            height: 1.0,
                                          ),
                                          textAlign: TextAlign.center,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),

        // 페이지 인디케이터 (작게 표시)
        if (pageCount > 1)
          Container(
            height: 6,
            margin: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                pageCount,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: _currentPage == index ? 24 : 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    color:
                        _currentPage == index
                            ? const Color(0xFF0047AB)
                            : Colors.grey[300],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // 계좌번호 입력 시트를 표시하는 메소드
  void _showAccountNumberInputSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 상단 헤더
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$_selectedBankName 계좌번호를 입력해주세요',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                      ),
                    ),
                  ],
                ),
              ),

              // 계좌번호 입력 필드
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: TextField(
                    controller: _accountNumberController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      hintText: '숫자만 입력해주세요',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      filled: false,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // 완료 버튼
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      _enterAccountNumber();
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[500],
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      '완료',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _enterAccountNumber() {
    if (_accountNumberController.text.isNotEmpty) {
      setState(() {
        _isAccountNumberEntered = true;
        _isAccountRegistrationComplete = true;
      });
    }
  }

  void _completeRegistration() {
    // 계좌 정보 등록 완료 후 프로필 선택 화면으로 이동
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => ProfileSelectionScreen(
              userId: widget.userId,
              jumin: widget.jumin,
              password: widget.password,
              name: widget.name,
              phone: widget.phone,
              marketingAgreed: widget.marketingAgreed,
            ),
      ),
    );
  }

  // 수정 버튼 클릭 시 계좌 등록 완료 상태 초기화
  void _resetAccountRegistration() {
    setState(() {
      _isAccountNumberEntered = false;
      _isAccountRegistrationComplete = false;
      _accountNumberController.clear();
    });
  }

  // 계좌 등록 완료 버튼 클릭 시 호출되는 메서드
  void _completeAccountRegistration() {
    setState(() {
      _isAccountRegistrationComplete = true;
    });

    // 회원가입 완료 다이얼로그 표시
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            '회원가입 완료',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle,
                color: Color(0xFF4F78FF),
                size: 60,
              ),
              const SizedBox(height: 16),
              const Text(
                '회원가입이 성공적으로 완료되었습니다!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.normal,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '가입하신 계정(${widget.userId})으로\n로그인해주세요.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          actions: [
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F78FF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop(); // 다이얼로그 닫기
                  // 로그인 화면으로 이동
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (route) => false, // 모든 이전 화면 제거
                  );
                },
                child: const Text('로그인 화면으로 이동'),
              ),
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          actionsPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        );
      },
    );
  }

  // 계좌등록 건너뛰기 버튼 클릭 시 호출되는 메서드
  void _skipAccountRegistration() {
    // 회원가입 완료 다이얼로그 표시
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            '회원가입 완료',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle,
                color: Color(0xFF4F78FF),
                size: 60,
              ),
              const SizedBox(height: 16),
              const Text(
                '회원가입이 성공적으로 완료되었습니다!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.normal,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '가입하신 계정(${widget.userId})으로\n로그인해주세요.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          actions: [
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F78FF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop(); // 다이얼로그 닫기
                  // 로그인 화면으로 이동
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (route) => false, // 모든 이전 화면 제거
                  );
                },
                child: const Text('로그인 화면으로 이동'),
              ),
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          actionsPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80), // 앱바 높이 증가
        child: AppBar(
          elevation: 0,
          backgroundColor: const Color(0xFFF8F9FA),
          automaticallyImplyLeading: false,
          flexibleSpace: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end, // 하단 정렬
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: IconButton(
                          icon: const Icon(
                            Icons.arrow_back_ios,
                            color: Colors.black,
                            size: 20,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.blue,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.blue,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 80,
                              height: 8,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 타이틀 영역
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '계좌 연결 시 리틀뱅크의\n더 많은 서비스를 이용할 수 있어요',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),

            // 계좌/증권 탭 영역
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _selectedTabIndex = 0;
                          _pageController.jumpToPage(0); // 페이지 리셋
                          _currentPage = 0; // 현재 페이지도 리셋
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _selectedTabIndex == 0
                                ? const Color(0xFF0047AB)
                                : Colors.grey[200],
                        foregroundColor:
                            _selectedTabIndex == 0
                                ? Colors.white
                                : Colors.black,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        '계좌',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _selectedTabIndex = 1;
                          _pageController.jumpToPage(0); // 페이지 리셋
                          _currentPage = 0; // 현재 페이지도 리셋
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _selectedTabIndex == 1
                                ? const Color(0xFF0047AB)
                                : Colors.grey[200],
                        foregroundColor:
                            _selectedTabIndex == 1
                                ? Colors.white
                                : Colors.black,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        '증권',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 검색창 영역
            _buildSearchBar(),

            const SizedBox(height: 16),

            // 은행 선택 그리드 (이미지와 일치하도록 조정)
            Expanded(
              child:
                  _isAccountNumberEntered
                      ? _buildSelectedAccountInfo()
                      : Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[200]!),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 6,
                                spreadRadius: 1.5,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: _buildBankGridView(),
                        ),
                      ),
            ),

            // 하단 버튼
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed:
                          _isAccountRegistrationComplete
                              ? _completeAccountRegistration
                              : null, // 계좌 등록 완료 시에만 활성화
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _isAccountRegistrationComplete
                                ? const Color(0xFF0047AB)
                                : Colors.grey[300],
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        '다음',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: TextButton(
                      onPressed: () {
                        // 계좌 연결 없이 바로 프로필 선택 화면으로 이동
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => ProfileSelectionScreen(
                                  userId: widget.userId,
                                  jumin: widget.jumin,
                                  password: widget.password,
                                  name: widget.name,
                                  phone: widget.phone,
                                  marketingAgreed: widget.marketingAgreed,
                                ),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey[700],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: Colors.grey[300]!),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        '나중에 하기',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 선택된 금융기관과 계좌번호 정보를 표시하는 위젯
  Widget _buildSelectedAccountInfo() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 6,
                    spreadRadius: 1.5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(color: Colors.blue, width: 2.0),
                    ),
                    padding: const EdgeInsets.all(10),
                    child: Image.asset(
                      _selectedFinancialInstitutionImage,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedBankName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF333333),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _formatAccountNumber(_accountNumberController.text),
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      _resetAccountRegistration(); // 수정 버튼 클릭 시 초기화 메서드 호출
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.edit_outlined,
                            size: 16,
                            color: Colors.amber[800],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '수정',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.amber[800],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: Text(
                '계좌 등록이 완료되었습니다.\n하단의 다음 버튼을 눌러 프로필 선택으로 진행해주세요.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 계좌번호 형식화 (예: 1234-56-7890)
  String _formatAccountNumber(String accountNumber) {
    // 간단한 예시
    if (accountNumber.length <= 4) return accountNumber;

    final middle =
        accountNumber.length > 6
            ? accountNumber.substring(4, 6)
            : accountNumber.substring(4);

    final last = accountNumber.length > 6 ? accountNumber.substring(6) : '';

    return '${accountNumber.substring(0, 4)}-$middle${last.isNotEmpty ? '-$last' : ''}';
  }
}
