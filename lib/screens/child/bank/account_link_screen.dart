import 'package:flutter/material.dart';
import '../../../widgets/common/bottom_navigation_bar.dart';
import 'change/child_bank_selection_modal.dart';
import 'change/child_account_verification_modal.dart';
import '../../../services/auth_service.dart';
import '../../../mixins/pin_modal_mixin.dart';

class AccountLinkScreen extends StatefulWidget {
  const AccountLinkScreen({super.key});

  @override
  State<AccountLinkScreen> createState() => _AccountLinkScreenState();
}

class _AccountLinkScreenState extends State<AccountLinkScreen>
    with PinModalMixin {
  // 선택된 은행/증권사
  String _selectedBank = '';
  String _selectedBankCode = '';
  bool _isBankTab = true; // 은행 탭 선택 여부
  final TextEditingController _searchController = TextEditingController();

  // 페이지 컨트롤러 추가
  late PageController _pageController;
  int _currentPage = 0;

  // 검색어 관리
  String _searchQuery = '';

  // 은행/증권사 리스트 (은행 코드 포함) - 실제 존재하는 로고 파일들로 매핑
  final List<Map<String, String>> _banks = [
    {'name': 'KB국민은행', 'logo': 'assets/logos/kb_bank.png', 'code': '004'},
    {'name': '신한은행', 'logo': 'assets/logos/shinhan_bank.png', 'code': '088'},
    {'name': '우리은행', 'logo': 'assets/logos/woori_bank.png', 'code': '020'},
    {'name': '하나은행', 'logo': 'assets/logos/hana_bank.png', 'code': '081'},
    {'name': '카카오뱅크', 'logo': 'assets/logos/kakao_bank.png', 'code': '090'},
    {'name': '농협', 'logo': 'assets/logos/nh_bank.png', 'code': '011'},
    {'name': '기업은행', 'logo': 'assets/logos/ibk_bank.png', 'code': '003'},
    {'name': '수협', 'logo': 'assets/logos/suhyup_bank.png', 'code': '007'},
    {'name': 'SC제일은행', 'logo': 'assets/logos/sc_bank.png', 'code': '023'},
    {'name': '한국씨티은행', 'logo': 'assets/logos/citi_bank.png', 'code': '027'},
    {'name': '대구은행', 'logo': 'assets/logos/daegu_bank.png', 'code': '031'},
    {'name': '부산은행', 'logo': 'assets/logos/busan_bank.png', 'code': '032'},
    {'name': '광주은행', 'logo': 'assets/logos/gwangju_bank.png', 'code': '034'},
    {'name': '제주은행', 'logo': 'assets/logos/jeju_bank.png', 'code': '035'},
    {'name': '전북은행', 'logo': 'assets/logos/jeonbuk_bank.png', 'code': '037'},
    {'name': '경남은행', 'logo': 'assets/logos/kyongnam_bank.png', 'code': '039'},
    {'name': 'K뱅크', 'logo': 'assets/logos/kbank.png', 'code': '089'},
    {'name': '산업은행', 'logo': 'assets/logos/KBD_BANK.png', 'code': '002'},
    {'name': '외환은행', 'logo': 'assets/logos/keb_bank.png', 'code': '005'},
    {'name': '축협', 'logo': 'assets/logos/축협_bank.png', 'code': '012'},
    {'name': '신협', 'logo': 'assets/logos/shinhyup.png', 'code': '048'},
    {'name': '우체국', 'logo': 'assets/logos/우체국_bank.png', 'code': '071'},
    {'name': '토스뱅크', 'logo': 'assets/logos/toss.png', 'code': '092'},
    {'name': '새마을금고', 'logo': 'assets/logos/saemaul.png', 'code': '045'},
  ];

  final List<Map<String, String>> _securities = [
    {'name': '미래에셋증권', 'logo': 'assets/logos/mirae_asset.png', 'code': '230'},
    {
      'name': '삼성증권',
      'logo': 'assets/logos/samsung_securities.png',
      'code': '240',
    },
    {
      'name': '한국투자증권',
      'logo': 'assets/logos/korea_investment.png',
      'code': '243',
    },
    {'name': '키움증권', 'logo': 'assets/logos/kiwoom.png', 'code': '264'},
    {'name': '대신증권', 'logo': 'assets/logos/daishin.png', 'code': '267'},
    {'name': 'NH투자증권', 'logo': 'assets/logos/nh_investment.png', 'code': '289'},
    {
      'name': '신한투자증권',
      'logo': 'assets/logos/shinhan_investment.png',
      'code': '278',
    },
    {'name': 'KB증권', 'logo': 'assets/logos/kb_securities.png', 'code': '218'},
    {'name': '토스증권', 'logo': 'assets/logos/toss_securities.png', 'code': '271'},
    {
      'name': '카카오페이증권',
      'logo': 'assets/logos/kakaopay_securities.png',
      'code': '288',
    },
    {'name': '나무증권', 'logo': 'assets/logos/namoo.jpg', 'code': '299'},
  ];

  // 연동된 계좌 정보
  Map<String, String?>? _linkedAccount;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _searchController.addListener(_updateSearchQuery);
    _loadLinkedAccount();
  }

  @override
  void dispose() {
    _searchController.removeListener(_updateSearchQuery);
    _searchController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _updateSearchQuery() {
    setState(() {
      _searchQuery = _searchController.text;
    });
  }

  // 연동된 계좌 정보 불러오기
  Future<void> _loadLinkedAccount() async {
    try {
      // 서버에서 최신 사용자 정보 가져오기
      final serverUserInfo = await AuthService.getUserInfo();

      // 서버 정보를 Map<String, String?> 형태로 변환
      final accountInfo = <String, String?>{
        'bankName': serverUserInfo['bankName']?.toString(),
        'bankCode': serverUserInfo['bankCode']?.toString(),
        'bankAccount': serverUserInfo['bankAccount']?.toString(),
        'accountHolder':
            serverUserInfo['accountHolder']?.toString() ??
            serverUserInfo['name']?.toString(),
        'isVerified':
            (serverUserInfo['bankName'] != null &&
                    serverUserInfo['bankName'].toString().isNotEmpty &&
                    serverUserInfo['bankAccount'] != null &&
                    serverUserInfo['bankAccount'].toString().isNotEmpty &&
                    serverUserInfo['bankCode'] != null &&
                    serverUserInfo['bankCode'].toString().isNotEmpty)
                ? 'true'
                : 'false',
      };

      setState(() {
        _linkedAccount = accountInfo;
        _isLoading = false;
      });
    } catch (e) {
      print('계좌 정보 로드 실패: $e');
      setState(() {
        _linkedAccount = null;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFB),
        elevation: 0,
        title: Text(
          _linkedAccount?['isVerified'] == 'true' ? '계좌변경' : '계좌 연결',
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontFamily: 'Pretendard-Bold',
            letterSpacing: -0.36,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.black, size: 16),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body:
          _isLoading
              ? Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF5D9EFF),
                  strokeWidth: 2,
                ),
              )
              : _linkedAccount?['isVerified'] == 'true'
              ? _buildLinkedAccountScreen()
              : _buildAccountSetupSection(),
      bottomNavigationBar: const CommonBottomNavigationBar(selectedIndex: 4),
    );
  }

  // 연동된 계좌 정보 표시
  Widget _buildLinkedAccountInfo() {
    final bankName = _linkedAccount?['bankName'] ?? '';
    final bankAccount = _linkedAccount?['bankAccount'] ?? '';
    final accountHolder = _linkedAccount?['accountHolder'] ?? '';

    // 은행 로고 찾기
    String logoPath = 'assets/logos/default_bank.png';
    final bank = _banks.firstWhere(
      (b) => b['name'] == bankName,
      orElse:
          () => _securities.firstWhere(
            (s) => s['name'] == bankName,
            orElse: () => {'logo': logoPath},
          ),
    );
    logoPath = bank['logo'] ?? logoPath;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5D9EFF).withOpacity(0.08),
            blurRadius: 16,
            offset: Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          // 상단 그라데이션 헤더
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFF5D9EFF), const Color(0xFF89DA8D)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                // 은행 로고
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  padding: EdgeInsets.all(6),
                  child: ClipOval(
                    child: Image.asset(
                      logoPath,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bankName,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontFamily: 'Pretendard-Bold',
                          letterSpacing: -0.36,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        bankAccount,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 15,
                          fontFamily: 'Pretendard-Medium',
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // 하단 정보 영역
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // 예금주 정보
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '예금주',
                      style: TextStyle(
                        color: const Color(0xFF8490A3),
                        fontSize: 14,
                        fontFamily: 'Pretendard-Light',
                        letterSpacing: -0.28,
                      ),
                    ),
                    Text(
                      accountHolder,
                      style: TextStyle(
                        color: const Color(0xFF202020),
                        fontSize: 16,
                        fontFamily: 'Pretendard-Bold',
                        letterSpacing: -0.32,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Divider(height: 1, color: const Color(0xFFE8EDF7)),
                const SizedBox(height: 16),
                // 연동일 정보
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '연동일',
                      style: TextStyle(
                        color: const Color(0xFF8490A3),
                        fontSize: 14,
                        fontFamily: 'Pretendard-Light',
                        letterSpacing: -0.28,
                      ),
                    ),
                    Text(
                      DateTime.now().toString().substring(0, 10),
                      style: TextStyle(
                        color: const Color(0xFF666666),
                        fontSize: 14,
                        fontFamily: 'Pretendard-Medium',
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
    );
  }

  // 계좌 설정 섹션 (계좌가 없을 때)
  Widget _buildAccountSetupSection() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),

            // 메인 타이틀
            Text(
              '계좌를 연결하면\n더 많은 서비스를 이용할 수 있어요',
              style: TextStyle(
                color: const Color(0xFF202020),
                fontSize: 22,
                fontFamily: 'Pretendard-Bold',
                letterSpacing: -0.44,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 12),

            // 설명 텍스트
            Text(
              '14살 미만 회원의 경우, 본인 명의가 아닌 계좌도 등록 가능해요.\n타인의 계좌를 등록하여 이용할 때는, 신뢰할 수 있는 사람의 계좌를 등록해 주세요. (선택사항)',
              style: TextStyle(
                color: const Color(0xFF8490A3),
                fontSize: 13,
                fontFamily: 'Pretendard-Light',
                letterSpacing: -0.26,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 60),

            // 계좌 연결 버튼
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _showBankSelectionSheet,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5D9EFF),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  '계좌 연결하기',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontFamily: 'Pretendard-Medium',
                    letterSpacing: -0.32,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // 계좌 연결 섹션 (기존)
  Widget _buildAccountLinkSection() {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Column(
      children: [
        // 스크롤 가능한 콘텐츠
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                          '14살 미만 회원의 경우, 본인 명의가 아닌 계좌도 등록 가능해요.타인의 계좌를 등록하여 이용할 때는 , 신뢰할 수 있는 사람의 계좌를 등록해 주세요. (선택사항)',
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
                              _isBankTab = true;
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
                                  _isBankTab
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
                                    _isBankTab
                                        ? Colors.white
                                        : const Color(0xFF5D9EFF),
                                fontSize: 12,
                                fontFamily:
                                    _isBankTab
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
                              _isBankTab = false;
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
                                  !_isBankTab
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
                                    !_isBankTab
                                        ? Colors.white
                                        : const Color(0xFF5D9EFF),
                                fontSize: 12,
                                fontFamily:
                                    !_isBankTab
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
      ],
    );
  }

  // 계좌 변경 버튼 클릭 시 PIN 인증 후 진행
  void _onAccountChangePressed() {
    // 계좌가 이미 등록된 사용자는 PIN이 무조건 설정되어 있으므로 바로 PIN 입력 모달 표시
    showPinInputModalOnly(
      title: '변경을 위해 결제 비밀번호를 입력해 주세요',
      onPinVerified: (pin) {
        print('[AccountLinkScreen] PIN 인증 완료, 계좌 변경 진행');
        // PIN 인증 성공 시 은행 선택 모달 표시
        _showBankSelectionSheet();
      },
      onCancel: () {
        print('[AccountLinkScreen] PIN 인증 취소됨');
      },
    );
  }

  // 은행 선택 바텀시트 표시
  void _showBankSelectionSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return ChildBankSelectionModal(
          isBankTab: _isBankTab,
          onTabChanged: (isBank) {
            setState(() {
              _isBankTab = isBank;
            });
          },
          banks: _banks,
          securities: _securities,
          onBankSelected: (bankName) {
            // 선택된 은행의 코드 찾기
            final selectedItem =
                _isBankTab
                    ? _banks.firstWhere((b) => b['name'] == bankName)
                    : _securities.firstWhere((s) => s['name'] == bankName);

            setState(() {
              _selectedBank = bankName;
              _selectedBankCode = selectedItem['code'] ?? '';
            });
            Navigator.pop(context);

            // 바로 계좌 검증 모달 표시
            _showAccountVerificationModal();
          },
        );
      },
    );
  }

  // 계좌 검증 모달 표시
  void _showAccountVerificationModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      builder: (context) {
        return ChildAccountVerificationModal(
          selectedBank: _selectedBank,
          selectedBankCode: _selectedBankCode,
          onPrevious: () {
            Navigator.pop(context);
            _showBankSelectionSheet();
          },
          onComplete: () {
            // 계좌 연동 완료 후 서버에서 최신 정보 다시 로드
            _loadLinkedAccount();
            Navigator.pop(context);

            // 성공 메시지 표시
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('계좌 연동이 완료되었습니다'),
                backgroundColor: const Color(0xFF5D9DFF),
              ),
            );
          },
        );
      },
    );
  }

  // 연동된 계좌 화면
  Widget _buildLinkedAccountScreen() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // 상단 헤더 영역
          Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(20, 32, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF5D9EFF),
                            const Color(0xFF89DA8D),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.account_balance_wallet,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '계좌변경',
                            style: TextStyle(
                              color: const Color(0xFF202020),
                              fontSize: 22,
                              fontFamily: 'Pretendard-Bold',
                              letterSpacing: -0.44,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '다른 계좌로 변경할 수 있어요',
                            style: TextStyle(
                              color: const Color(0xFF8490A3),
                              fontSize: 14,
                              fontFamily: 'Pretendard-Light',
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

          const SizedBox(height: 12),

          // 계좌 정보 카드
          _buildLinkedAccountInfo(),

          const SizedBox(height: 20),

          // 버튼 영역
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                // 계좌 변경 버튼
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _onAccountChangePressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: const Color(0xFF5D9EFF),
                          width: 1.5,
                        ),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    child: Container(
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.edit_outlined,
                            size: 18,
                            color: const Color(0xFF5D9EFF),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '계좌 변경하기',
                            style: TextStyle(
                              color: const Color(0xFF5D9EFF),
                              fontSize: 16,
                              fontFamily: 'Pretendard-Medium',
                              letterSpacing: -0.32,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // 안내사항
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFE8EDF7),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: const Color(0xFF8490A3),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '안내사항',
                            style: TextStyle(
                              color: const Color(0xFF202020),
                              fontSize: 14,
                              fontFamily: 'Pretendard-Medium',
                              letterSpacing: -0.28,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '• 포인트 출금 시 연동된 계좌로 입금됩니다\n• 계좌 변경은 언제든지 가능합니다\n• 출금 신청 후 영업일 기준 1-2일 소요됩니다',
                        style: TextStyle(
                          color: const Color(0xFF8490A3),
                          fontSize: 13,
                          fontFamily: 'Pretendard-Light',
                          letterSpacing: -0.26,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // 검색 결과를 반환하는 메서드
  List<Map<String, String>> _getFilteredFinancialInstitutions() {
    final query = _searchQuery.toLowerCase();
    final currentList = _isBankTab ? _banks : _securities;

    if (query.isEmpty) {
      return currentList;
    }

    return currentList.where((item) {
      // 이름에 검색어가 포함된 경우
      if (item['name']!.toLowerCase().contains(query)) {
        return true;
      }

      // 초성 검색 처리
      String name = item['name']!;
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

  void _selectFinancialInstitution(Map<String, String> institution) {
    setState(() {
      _selectedBank = institution['name']!;
      _selectedBankCode = institution['code']!;
      _searchController.clear();
      _searchQuery = '';
    });

    // 바로 계좌 검증 모달 표시
    _showAccountVerificationModal();
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

  // 은행 그리드 뷰 (3x4 형태)
  Widget _buildBankGridView() {
    final filteredList = _getFilteredFinancialInstitutions();
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    if (filteredList.isEmpty) {
      return const Center(
        child: Text('검색 결과가 없습니다', style: TextStyle(color: Colors.grey)),
      );
    }

    // 12개씩 보이도록 (4행 3열)
    final pageCount = (filteredList.length / 12).ceil();

    // 적절한 높이 계산 (화면 크기에 따라 동적 조정)
    double gridHeight = screenHeight * 0.45; // 화면 높이의 45%로 증가
    if (gridHeight < 380) gridHeight = 380; // 최소 높이 증가
    if (gridHeight > 500) gridHeight = 500; // 최대 높이 증가

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
          final startIndex = pageIndex * 12;
          final endIndex =
              (startIndex + 12) < filteredList.length
                  ? startIndex + 12
                  : filteredList.length;

          final pageItems = filteredList.sublist(startIndex, endIndex);

          return Padding(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.01),
            child: Column(
              children: [
                for (int row = 0; row < 4; row++)
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

  Widget _buildBankItem(Map<String, String>? institution) {
    if (institution == null) {
      return const SizedBox();
    }

    bool isSelected = institution['name'] == _selectedBank;

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
                      _isBankTab
                          ? const ShapeDecoration(shape: OvalBorder())
                          : null,
                  child:
                      _isBankTab
                          ? ClipOval(
                            child: Image.asset(
                              institution['logo']!,
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
                            institution['logo']!,
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
                    institution['name']!,
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
}
