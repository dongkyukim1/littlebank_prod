import 'package:flutter/material.dart';
import 'profile_selection_screen.dart';
import 'login_screen.dart';
import '../../services/auth_service.dart';
import 'modal/account_input_modal.dart';

class FinalScreen extends StatefulWidget {
  final String userId;
  final bool marketingAgreed;
  final String jumin;
  final String? password;
  final String? name;
  final String? phone;
  final bool? agreedTermsOfService;
  final bool? agreedPrivacyCollection;
  final bool? agreedMinorGuardian;
  final bool? agreedElectronicFinance;
  final bool? agreedRewardGuardian;
  final bool? agreedThirdPartySharing;
  final bool? agreedDataProcessingDelegation;

  const FinalScreen({
    super.key,
    required this.userId,
    required this.marketingAgreed,
    required this.jumin,
    this.password,
    this.name,
    this.phone,
    this.agreedTermsOfService,
    this.agreedPrivacyCollection,
    this.agreedMinorGuardian,
    this.agreedElectronicFinance,
    this.agreedRewardGuardian,
    this.agreedThirdPartySharing,
    this.agreedDataProcessingDelegation,
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
    {'name': 'KB국민', 'image': 'assets/logos/kb_bank.png'},
    {'name': '신한', 'image': 'assets/logos/shinhan_bank.png'},
    {'name': '농협', 'image': 'assets/logos/nh_bank.png'},
    {'name': '하나', 'image': 'assets/logos/hana_bank.png'},
    {'name': '우리', 'image': 'assets/logos/woori_bank.png'},
    {'name': '카카오뱅크', 'image': 'assets/logos/kakao_bank.png'},
    {'name': '부산', 'image': 'assets/logos/busan_bank.png'},
    {'name': '토스뱅크', 'image': 'assets/logos/toss.png'},
    {'name': 'IBK기업', 'image': 'assets/logos/ibk_bank.png'},
    {'name': '경남', 'image': 'assets/logos/kyongnam_bank.png'},
    {'name': '전북', 'image': 'assets/logos/jeonbuk_bank.png'},
    {'name': '수협', 'image': 'assets/logos/suhyup_bank.png'},
    {'name': '제주', 'image': 'assets/logos/jeju_bank.png'},
    {'name': '대구', 'image': 'assets/logos/daegu_bank.png'},
    {'name': '광주', 'image': 'assets/logos/gwangju_bank.png'},
    {'name': 'SC제일', 'image': 'assets/logos/sc_bank.png'},
    {'name': '씨티은행', 'image': 'assets/logos/citi_bank.png'},
    {'name': '케이뱅크', 'image': 'assets/logos/k_bank.png'},
    {'name': '신협', 'image': 'assets/logos/shinhyup.png'},
    {'name': '우체국', 'image': 'assets/logos/우체국_bank.png'},
    {'name': '축협', 'image': 'assets/logos/축협_bank.png'},
  ];

  // 증권사 목록 관리
  final List<Map<String, dynamic>> _allSecurities = [
    {'name': '키움', 'image': 'assets/logos/kiwoom.png'},
    {'name': '미래에셋', 'image': 'assets/logos/mirae_asset.png'},
    {'name': '삼성', 'image': 'assets/logos/samsung_securities.png'},
    {'name': 'NH투자', 'image': 'assets/logos/nh_investment.png'},
    {'name': '한국투자', 'image': 'assets/logos/korea_investment.png'},
    {'name': 'KB', 'image': 'assets/logos/kb_securities.png'},
    {'name': '신한투자', 'image': 'assets/logos/shinhan_investment.png'},
    {'name': '나무', 'image': 'assets/logos/namoo.jpg'},
    {'name': '토스', 'image': 'assets/logos/toss_securities.png'},
  ];

  // 선택된 금융기관 정보
  String _selectedFinancialInstitutionImage = 'assets/logos/kakao_bank.png';
  String _selectedBankName = '';

  // 계좌번호 입력 관련
  final TextEditingController _accountNumberController =
      TextEditingController();
  bool _isAccountNumberEntered = false;
  bool _isAccountRegistrationComplete = false;

  // 계좌검증 관련 추가
  final TextEditingController _accountHolderController =
      TextEditingController();
  bool _isAccountVerified = false;
  bool _isVerifying = false;
  String? _verificationMessage;

  // PIN 번호 입력 관련 추가
  final TextEditingController _pinController = TextEditingController();
  bool _isPinEntered = false;
  String _enteredPin = '';

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
    _accountHolderController.dispose();
    _pinController.dispose();
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
      // 이미 선택된 은행을 다시 누르면 선택 해제
      if (_selectedBankName == institution['name']) {
        _selectedBankName = '';
        _selectedFinancialInstitutionImage = '';
      } else {
        _selectedFinancialInstitutionImage = institution['image'];
        _selectedBankName = institution['name'];
        // 계좌 정보 입력 모달 표시
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder:
              (context) => AccountInputModal(
                institution: institution,
                getBankCode: _getBankCode,
                userId: widget.userId,
                jumin: widget.jumin,
                password: widget.password,
                name: widget.name,
                phone: widget.phone,
                marketingAgreed: widget.marketingAgreed,
                agreedTermsOfService: widget.agreedTermsOfService,
                agreedPrivacyCollection: widget.agreedPrivacyCollection,
                agreedMinorGuardian: widget.agreedMinorGuardian,
                agreedElectronicFinance: widget.agreedElectronicFinance,
                agreedRewardGuardian: widget.agreedRewardGuardian,
                agreedThirdPartySharing: widget.agreedThirdPartySharing,
                agreedDataProcessingDelegation: widget.agreedDataProcessingDelegation,
              ),
        );
      }
      _searchController.clear();
      _searchQuery = '';
    });
  }

  // 검색창 영역
  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            child: Icon(Icons.search, color: Colors.grey[400], size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '연결하고 싶은 은행을 검색해 주세요',
                hintStyle: const TextStyle(
                  color: Color(0xFF999999),
                  fontSize: 12,
                  fontFamily: 'Pretendard-Light',
                  letterSpacing: -0.24,
                ),
                filled: false,
                contentPadding: const EdgeInsets.symmetric(vertical: 6),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 은행 그리드 뷰 (3x3 형태)
  Widget _buildBankGridView() {
    final filteredList = _getFilteredFinancialInstitutions();
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    if (filteredList.isEmpty) {
      return const Center(
        child: Text('검색 결과가 없습니다', style: TextStyle(color: Colors.grey)),
      );
    }

    // 9개씩 보이도록 (3행 3열)
    final pageCount = (filteredList.length / 9).ceil();

    // 적절한 높이 계산 (화면 크기에 따라 동적 조정)
    double gridHeight = screenHeight * 0.35; // 화면 높이의 35%
    if (gridHeight < 300) gridHeight = 300; // 최소 높이
    if (gridHeight > 400) gridHeight = 400; // 최대 높이

    return SizedBox(
      height: gridHeight,
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

          final pageItems = filteredList.sublist(startIndex, endIndex);

          return Padding(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.01),
            child: Column(
              children: [
                for (int row = 0; row < 3; row++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 0.5),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          for (int col = 0; col < 3; col++)
                            Expanded(
                              child: Center(
                                child:
                                    pageItems.length > (row * 3 + col)
                                        ? _buildBankItem(
                                          pageItems[row * 3 + col],
                                        )
                                        : const SizedBox(width: 100),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBankItem(Map<String, dynamic>? institution) {
    if (institution == null) {
      return const SizedBox();
    }

    bool isSelected = institution['name'] == _selectedBankName;

    return GestureDetector(
      onTap: () => _selectFinancialInstitution(institution),
      child: Container(
        width: 100,
        margin: const EdgeInsets.all(2.0),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: ShapeDecoration(
          color: isSelected ? const Color(0xFF146AFF) : const Color(0xFFE4ECF8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Stack(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration:
                      _selectedTabIndex == 0
                          ? const ShapeDecoration(shape: OvalBorder())
                          : null,
                  child:
                      _selectedTabIndex == 0
                          ? ClipOval(
                            child: Image.asset(
                              institution['image'],
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[300],
                                  child: const Icon(
                                    Icons.account_balance,
                                    size: 18,
                                    color: Colors.grey,
                                  ),
                                );
                              },
                            ),
                          )
                          : Image.asset(
                            institution['image'],
                            width: 36,
                            height: 36,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 36,
                                height: 36,
                                color: Colors.grey[300],
                                child: const Icon(
                                  Icons.business,
                                  size: 18,
                                  color: Colors.grey,
                                ),
                              );
                            },
                          ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: 84,
                  alignment: Alignment.center,
                  child: Text(
                    institution['name'],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color:
                          isSelected ? Colors.white : const Color(0xFF202020),
                      fontSize: 10,
                      fontFamily: 'Pretendard-Light',
                      letterSpacing: -0.24,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            // 선택 시 가운데 체크 아이콘
            if (isSelected)
              Positioned.fill(
                child: Center(
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: const ShapeDecoration(
                      color: Color(0xFF5D9EFF),
                      shape: OvalBorder(),
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // 계좌 등록 초기화 메서드
  void _resetAccountRegistration() {
    setState(() {
      _isAccountNumberEntered = false;
      _isAccountRegistrationComplete = false;
      _isAccountVerified = false;
      _isPinEntered = false;
      _enteredPin = '';
      _verificationMessage = null;
    });
    _accountNumberController.clear();
    _accountHolderController.clear();
    _pinController.clear();
  }

  // PIN 설정 완료
  void _completePinSetup() {
    setState(() {
      _isPinEntered = true;
      _isAccountRegistrationComplete = true;
    });
  }

  // PIN 설정 건너뛰기
  void _skipPinSetup() {
    setState(() {
      _isPinEntered = false;
      _enteredPin = '';
      _pinController.clear();
      _isAccountRegistrationComplete = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: SafeArea(
        child: Column(
          children: [
            // 상단 앱바
            Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
              child: Container(
                width: double.infinity,
                height: 56,
                child: Stack(
                  children: [
                    Positioned(
                      left: 0,
                      top: 16,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 24,
                          height: 24,
                          child: const Icon(
                            Icons.arrow_back_ios,
                            color: Colors.black,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 19,
                      child: Center(
                        child: Text(
                          '계좌 연결',
                          style: TextStyle(
                            color: const Color(0xFF202020),
                            fontSize: 16,
                            fontFamily: 'Pretendard-Bold',
                            letterSpacing: -0.32,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 스크롤 가능한 콘텐츠
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 스텝 인디케이터
                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: ShapeDecoration(
                                color: const Color(0xFF3A88F4),
                                shape: OvalBorder(),
                              ),
                              child: Center(
                                child: Text(
                                  '1',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontFamily: 'Pretendard-Bold',
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Container(
                              width: 12,
                              height: 2,
                              color: const Color(0xFFE4ECF8),
                            ),
                            const SizedBox(width: 4),
                            Container(
                              width: 28,
                              height: 28,
                              decoration: ShapeDecoration(
                                color: const Color(0xFF3A88F4),
                                shape: OvalBorder(),
                              ),
                              child: Center(
                                child: Text(
                                  '2',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontFamily: 'Pretendard-Bold',
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Container(
                              width: 12,
                              height: 2,
                              color: const Color(0xFFE4ECF8),
                            ),
                            const SizedBox(width: 4),
                            Container(
                              width: 28,
                              height: 28,
                              decoration: ShapeDecoration(
                                color: const Color(0xFF3A88F4),
                                shape: OvalBorder(),
                              ),
                              child: Center(
                                child: Text(
                                  '3',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontFamily: 'Pretendard-Bold',
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Container(
                              width: 12,
                              height: 2,
                              color: const Color(0xFFE4ECF8),
                            ),
                            const SizedBox(width: 4),
                            Container(
                              width: 28,
                              height: 28,
                              decoration: ShapeDecoration(
                                color: const Color(0xFF3A88F4),
                                shape: OvalBorder(),
                              ),
                              child: Center(
                                child: Text(
                                  '4',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontFamily: 'Pretendard-Bold',
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Container(
                              width: 12,
                              height: 2,
                              color: const Color(0xFFE4ECF8),
                            ),
                            const SizedBox(width: 4),
                            Container(
                              width: 28,
                              height: 28,
                              decoration: ShapeDecoration(
                                color: const Color(0xFFE4ECF8),
                                shape: OvalBorder(),
                              ),
                              child: Center(
                                child: Text(
                                  '5',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontFamily: 'Pretendard-Bold',
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // 타이틀 영역
                      Container(
                        width: double.infinity,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '계좌를 연결하면\n더 많은 서비스를 이용할 수 있어요',
                              textAlign: TextAlign.left,
                              style: TextStyle(
                                color: Color(0xFF202020),
                                fontSize: 20,
                                fontFamily: 'Pretendard-Bold',
                                height: 1.50,
                                letterSpacing: -0.88,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '출금 시 예금주 명과 회원 정보의 이름이 동일해야 하기 때문에본인 명의의 계좌 연동만 가능해요. (선택사항)',
                              textAlign: TextAlign.left,
                              style: TextStyle(
                                color: Color(0xFF8490A3),
                                fontSize: 10,
                                fontFamily: 'Pretendard-Light',
                                letterSpacing: -0.28,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 40),

                      // 계좌/증권 탭 영역
                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedTabIndex = 0;
                                  _pageController.jumpToPage(0);
                                  _currentPage = 0;
                                });
                              },
                              child: Container(
                                width: 89,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                decoration: ShapeDecoration(
                                  color:
                                      _selectedTabIndex == 0
                                          ? const Color(0xFF3A88F4)
                                          : const Color(0xFFE7ECF6),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                child: Text(
                                  '계좌',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color:
                                        _selectedTabIndex == 0
                                            ? Colors.white
                                            : const Color(0xFF5D9EFF),
                                    fontSize: 12,
                                    fontFamily:
                                        _selectedTabIndex == 0
                                            ? 'Pretendard-Medium'
                                            : 'Pretendard-Light',
                                    letterSpacing: -0.24,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 26),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedTabIndex = 1;
                                  _pageController.jumpToPage(0);
                                  _currentPage = 0;
                                });
                              },
                              child: Container(
                                width: 89,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                decoration: ShapeDecoration(
                                  color:
                                      _selectedTabIndex == 1
                                          ? const Color(0xFF3A88F4)
                                          : const Color(0xFFE7ECF6),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                child: Text(
                                  '증권',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color:
                                        _selectedTabIndex == 1
                                            ? Colors.white
                                            : const Color(0xFF5D9EFF),
                                    fontSize: 12,
                                    fontFamily:
                                        _selectedTabIndex == 1
                                            ? 'Pretendard-Medium'
                                            : 'Pretendard-Light',
                                    letterSpacing: -0.24,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 28),

                      // 검색창 영역
                      _buildSearchBar(),

                      const SizedBox(height: 24),

                      // 은행 선택 그리드
                      _buildBankGridView(),

                      SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),

            // 하단 버튼 영역
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(
                screenWidth * 0.04,
                12,
                screenWidth * 0.04,
                12 + bottomPadding,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x1A000000),
                    blurRadius: 8,
                    offset: Offset(0, -4),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        // 프로필 선택 화면으로 이동 (계좌 정보 없이)
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
                                  // 계좌 정보는 전달하지 않음 (나중에 연결하기)
                                  bankName: null,
                                  bankCode: null,
                                  bankAccount: null,
                                  accountPin: null,
                                ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF146AFF),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                      ),
                      child: Text(
                        '다음에 연결하기',
                        style: TextStyle(
                          fontSize: 14,
                          fontFamily: 'Pretendard-Light',
                          letterSpacing: -0.24,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '지금 하지않아도 마이페이지에서 연결할 수 있어요',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: const Color(0xFF8490A3),
                      fontSize: 10,
                      fontFamily: 'Pretendard-Light',
                      letterSpacing: -0.24,
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

  // 계좌번호 형식화 (예: 1234-56-7890)
  String _formatAccountNumber(String accountNumber) {
    if (accountNumber.length <= 4) return accountNumber;

    final middle =
        accountNumber.length > 6
            ? accountNumber.substring(4, 6)
            : accountNumber.substring(4);

    final last = accountNumber.length > 6 ? accountNumber.substring(6) : '';

    return '${accountNumber.substring(0, 4)}-$middle${last.isNotEmpty ? '-$last' : ''}';
  }

  // 은행 코드 매핑 함수
  String _getBankCode(String bankName) {
    final Map<String, String> bankCodes = {
      'KB국민': '004',
      '신한': '088',
      '농협': '011',
      '하나': '081',
      '우리': '020',
      '카카오뱅크': '090',
      '부산': '032',
      '토스뱅크': '092',
      'IBK기업': '003',
      '경남': '039',
      '전북': '037',
      '수협': '007',
      '제주': '035',
      '대구': '031',
      '광주': '034',
      'SC제일': '023',
      '씨티은행': '027',
      '케이뱅크': '089',
      '신협': '048',
      '우체국': '071',
      '축협': '012',
    };
    return bankCodes[bankName] ?? '004';
  }
}
