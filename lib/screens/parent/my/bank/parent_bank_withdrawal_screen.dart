import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../widgets/parent/bottom_navigation_bar.dart';
import 'withdrawal/amount_input_sheet.dart';
import '../../../../services/auth_service.dart';
import '../../../../services/payment_service.dart';
import 'withdrawal/transfer_guide_screen.dart';

class ParentBankWithdrawalScreen extends StatefulWidget {
  const ParentBankWithdrawalScreen({super.key});

  @override
  State<ParentBankWithdrawalScreen> createState() =>
      _ParentBankWithdrawalScreenState();
}

class _ParentBankWithdrawalScreenState
    extends State<ParentBankWithdrawalScreen> {
  // 선택된 은행 (부모용 - 연동된 계좌의 은행)
  String _selectedBank = '';

  // 연동된 계좌 정보
  Map<String, String?>? _linkedAccount;
  bool _isLoading = true;

  // 은행/증권사 리스트 (은행 코드 포함)
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
    {'name': '산업은행', 'logo': 'assets/logos/kdb_bank.png', 'code': '002'},
    {'name': '외환은행', 'logo': 'assets/logos/exchange_bank.png', 'code': '005'},
    {'name': '축협', 'logo': 'assets/logos/livestock_bank.png', 'code': '012'},
    {'name': '신협', 'logo': 'assets/logos/cu_bank.png', 'code': '048'},
    {'name': '우체국', 'logo': 'assets/logos/post_bank.png', 'code': '071'},
  ];

  final List<Map<String, String>> _securities = [
    {
      'name': '유안타증권',
      'logo': 'assets/logos/yuanta_securities.png',
      'code': '209',
    },
    {
      'name': '현대증권',
      'logo': 'assets/logos/hyundai_securities.png',
      'code': '218',
    },
    {'name': '미래에셋증권', 'logo': 'assets/logos/mirae_asset.png', 'code': '230'},
    {
      'name': '대우증권',
      'logo': 'assets/logos/daewoo_securities.png',
      'code': '238',
    },
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
    {
      'name': '우리투자증권',
      'logo': 'assets/logos/woori_investment.png',
      'code': '247',
    },
    {
      'name': '교보증권',
      'logo': 'assets/logos/kyobo_securities.png',
      'code': '261',
    },
    {'name': '하이투자증권', 'logo': 'assets/logos/hi_investment.png', 'code': '262'},
    {
      'name': '에이치엠씨투자증권',
      'logo': 'assets/logos/hmc_investment.png',
      'code': '263',
    },
    {'name': '키움증권', 'logo': 'assets/logos/kiwoom.png', 'code': '264'},
    {
      'name': '이트레이드증권',
      'logo': 'assets/logos/etrade_securities.png',
      'code': '265',
    },
    {'name': '에스케이증권', 'logo': 'assets/logos/sk_securities.png', 'code': '266'},
    {'name': '대신증권', 'logo': 'assets/logos/daishin.png', 'code': '267'},
    {
      'name': '솔로몬투자증권',
      'logo': 'assets/logos/solomon_investment.png',
      'code': '268',
    },
    {
      'name': '한화증권',
      'logo': 'assets/logos/hanwha_securities.png',
      'code': '269',
    },
    {'name': '하나대투증권', 'logo': 'assets/logos/hana_daetoo.png', 'code': '270'},
    {
      'name': '굿모닝신한증권',
      'logo': 'assets/logos/goodmorning_shinhan.png',
      'code': '278',
    },
    {
      'name': '동부증권',
      'logo': 'assets/logos/dongbu_securities.png',
      'code': '279',
    },
    {
      'name': '유진투자증권',
      'logo': 'assets/logos/eugene_investment.png',
      'code': '280',
    },
    {
      'name': '메리츠증권',
      'logo': 'assets/logos/meritz_securities.png',
      'code': '287',
    },
    {
      'name': '엔에이치투자증권',
      'logo': 'assets/logos/nh_investment.png',
      'code': '289',
    },
    {
      'name': '부국증권',
      'logo': 'assets/logos/bookook_securities.png',
      'code': '290',
    },
  ];

  final List<Map<String, dynamic>> _recentAccounts = [
    {
      'name': '박뱅뱅',
      'account': '969802-01-010101',
      'bank': 'KB국민은행',
      'logo': 'assets/logos/kb_bank.png',
    },
    {
      'name': '박리뱅',
      'account': '110-123-456789',
      'bank': '신한은행',
      'logo': 'assets/logos/shinhan_bank.png',
    },
    {
      'name': '박리틀',
      'account': '1234-56-7890123',
      'bank': '우리은행',
      'logo': 'assets/logos/woori_bank.png',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadLinkedAccount();
  }

  @override
  void dispose() {
    super.dispose();
  }

  // 연동된 계좌 정보 불러오기
  Future<void> _loadLinkedAccount() async {
    try {
      // 서버에서 최신 사용자 정보 가져오기
      final serverUserInfo = await AuthService.getUserInfo();

      print('부모 계좌 연결 확인 - 사용자 정보: $serverUserInfo');

      // 은행 정보가 있는지 확인 (bankName과 bankAccount만 있으면 연결된 것으로 처리)
      final bankName = serverUserInfo['bankName']?.toString();
      final bankAccount = serverUserInfo['bankAccount']?.toString();
      final accountHolder =
          serverUserInfo['accountHolder']?.toString() ??
          serverUserInfo['name']?.toString();

      bool isAccountConnected =
          bankName != null &&
          bankName.isNotEmpty &&
          bankAccount != null &&
          bankAccount.isNotEmpty;

      print(
        '부모 계좌 연결 상태: $isAccountConnected (은행: $bankName, 계좌: $bankAccount)',
      );

      // 서버 정보를 Map<String, String?> 형태로 변환
      final accountInfo = <String, String?>{
        'bankName': bankName,
        'bankCode': serverUserInfo['bankCode']?.toString(),
        'bankAccount': bankAccount,
        'accountHolder': accountHolder,
        'isVerified': isAccountConnected ? 'true' : 'false',
      };

      setState(() {
        _linkedAccount = accountInfo;
        _isLoading = false;
      });

      print('부모 계좌 정보 설정 완료: $_linkedAccount');
    } catch (e) {
      print('부모 계좌 정보 로드 실패: $e');
      setState(() {
        _linkedAccount = null;
        _isLoading = false;
      });
    }
  }

  // 내 계좌 목록 생성 (연동된 계좌가 있는 경우에만)
  List<Map<String, dynamic>> _getMyAccounts() {
    if (_linkedAccount?['isVerified'] == 'true') {
      final bankName = _linkedAccount?['bankName'] ?? '';
      final accountNumber = _linkedAccount?['bankAccount'] ?? '';
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

      return [
        {
          'name': accountHolder,
          'account': accountNumber,
          'bank': bankName,
          'logo': logoPath,
        },
      ];
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          '포인트 꺼내기',
          style: TextStyle(
            color: Colors.black,
            fontSize: 14,
            fontFamily: 'Pretendard-Bold',
          ),
        ),
        leading: IconButton(
          icon: Image.asset(
            'assets/icons/parent/my/point/back.png',
            width: 20,
            height: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Image.asset('assets/images/home.png', width: 24, height: 24),
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ],
      ),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : SafeArea(
                child: Column(
                  children: [
                    // 이체 안내 버튼
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => const TransferGuideScreen(),
                                ),
                              );
                            },
                            child: Text(
                              '이체 안내',
                              style: TextStyle(
                                color: const Color(0xFF8590A3),
                                fontSize: 13,
                                fontFamily: 'Pretendard-Medium',
                                letterSpacing: -0.28,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const HeaderComponent(
                      title: '포인트를 꺼낼까요?',
                      subtitle: '현금으로 포인트를 꺼내려면 다음 단계로 이동하세요',
                    ),
                    Expanded(
                      child: AccountListComponent(
                        myAccounts: _getMyAccounts(),
                        recentAccounts: _recentAccounts,
                        linkedAccount: _linkedAccount,

                        onNext:
                            _getMyAccounts().isNotEmpty
                                ? () {
                                  // 연동된 계좌가 있으면 바로 금액 입력으로 이동
                                  final myAccount = _getMyAccounts().first;
                                  setState(() {
                                    _selectedBank = myAccount['bank'];
                                  });
                                  _showAmountInputSheet();
                                }
                                : null,
                      ),
                    ),
                  ],
                ),
              ),
      bottomNavigationBar: const ParentBottomNavigationBar(selectedIndex: 4),
    );
  }

  // 금액 입력 바텀 시트 표시
  void _showAmountInputSheet() async {
    // 내 포인트 정보 로드
    String availablePoints = '0원';
    String myName = '사용자';
    String myPhone = '';
    String myProfileImage = '';

    try {
      final userInfo = await AuthService.getUserInfo();

      // 사용 가능한 포인트 가져오기
      final points =
          userInfo['point'] is int
              ? userInfo['point']
              : int.tryParse(userInfo['point'].toString()) ?? 0;
      availablePoints =
          '${points.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (match) => '${match[1]},')}원';

      // 내 정보 가져오기
      myName = userInfo['name'] ?? '사용자';
      myPhone = userInfo['phone'] ?? '';
      myProfileImage = userInfo['profileImagePath']?.toString() ?? '';
    } catch (e) {
      print('사용자 정보 로드 실패: $e');
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return AmountInputSheet(
          userName: myName, // 자기 자신의 이름
          phoneNumber: myPhone, // 자기 자신의 전화번호
          userProfileImage: myProfileImage, // 자기 자신의 프로필 이미지
          availablePoints: availablePoints,
          selectedBank: _selectedBank,
          accountNumber: _linkedAccount?['bankAccount'] ?? '', // 연동된 계좌번호
          isWithdrawal: true, // 출금 모드임을 표시
          onNext: () {
            Navigator.pop(context);
            // TODO: 출금 완료 화면으로 이동하거나 실제 출금 처리
          },
          onPrevious: () {
            Navigator.pop(context);
          },
        );
      },
    );
  }
}

class HeaderComponent extends StatelessWidget {
  final String title;
  final String subtitle;

  const HeaderComponent({
    Key? key,
    this.title = '어디로 포인트를 꺼낼까요?',
    this.subtitle = '포인트를 현금으로 꺼낼 대상을 선택해 주세요',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: const Color(0xFF202020),
                  fontSize: 22,
                  fontFamily: 'Pretendard-Bold',
                  letterSpacing: -0.96,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: const Color(0xFF8590A3),
                  fontSize: 14,
                  fontFamily: 'Pretendard-Light',
                  letterSpacing: -0.32,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class AccountListComponent extends StatelessWidget {
  final List<Map<String, dynamic>> myAccounts;
  final List<Map<String, dynamic>> recentAccounts;
  final Map<String, String?>? linkedAccount;
  final VoidCallback? onNext;

  const AccountListComponent({
    Key? key,
    required this.myAccounts,
    required this.recentAccounts,
    this.linkedAccount,
    this.onNext,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 28), // 헤더와 계좌 섹션 사이 간격
            // Connected Account Section
            if (myAccounts.isNotEmpty) ...[
              _buildSectionHeader('내 계좌로 연결됐어요'),
              ...myAccounts.map(
                (account) => _buildAccountItem(
                  name: account['name'],
                  bank: account['bank'],
                  account: account['account'],
                  isMyAccount: true,
                ),
              ),
              const SizedBox(height: 28),
            ],

            // No Account Connected
            if (myAccounts.isEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 48,
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.account_balance,
                      size: 48,
                      color: Color(0xFF999999),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '연동된 계좌가 없어요',
                      style: TextStyle(
                        color: Color(0xFF666666),
                        fontSize: 14,
                        fontFamily: 'Pretendard-Bold',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '포인트를 꺼내려면 먼저 계좌를 연결해주세요',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF999999),
                        fontSize: 12,
                        fontFamily: 'Pretendard-Light',
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // 다음 버튼
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ButtonComponent(
                text: '다음',
                isEnabled: myAccounts.isNotEmpty,
                onPressed: onNext,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(color: Colors.white),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF202020),
          fontSize: 18,
          fontFamily: 'Pretendard-Bold',
          letterSpacing: -0.8,
        ),
      ),
    );
  }

  Widget _buildAccountItem({
    required String name,
    required String bank,
    required String account,
    required bool isMyAccount,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          // Profile Image
          FutureBuilder<String?>(
            future: _getUserProfileImage(name, account, isMyAccount),
            builder: (context, snapshot) {
              return Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(shape: BoxShape.circle),
                child: ClipOval(
                  child:
                      snapshot.hasData && snapshot.data!.isNotEmpty
                          ? Image.network(
                            snapshot.data!,
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return _buildDefaultAvatar(name);
                            },
                          )
                          : _buildDefaultAvatar(name),
                ),
              );
            },
          ),
          const SizedBox(width: 16),
          // Account Info
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  color: Color(0xFF4A4A4A),
                  fontSize: 12,
                  fontFamily: 'Pretendard-Light',
                  letterSpacing: -0.28,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    bank,
                    style: const TextStyle(
                      color: Color(0xFF89DA8D),
                      fontSize: 10,
                      fontFamily: 'Pretendard-Light',
                      letterSpacing: -0.24,
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 0.4,
                    height: 8,
                    color: Color(0xFF8590A3),
                  ),
                  Text(
                    account,
                    style: const TextStyle(
                      color: Color(0xFF999999),
                      fontSize: 10,
                      fontFamily: 'Pretendard-Light',
                      letterSpacing: -0.24,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 사용자 프로필 이미지 가져오기
  Future<String?> _getUserProfileImage(
    String name,
    String account,
    bool isMyAccount,
  ) async {
    try {
      if (isMyAccount) {
        // 내 계좌인 경우 현재 사용자 프로필 이미지 사용
        if (linkedAccount?['bankAccount'] == account) {
          final userInfo = await AuthService.getUserInfo();
          final profileImagePath = userInfo['profileImagePath'];
          if (profileImagePath != null &&
              profileImagePath.toString().isNotEmpty) {
            return AuthService.getFullProfileImageUrl(profileImagePath);
          }
        }
      } else {
        // 목업 데이터의 경우 기본 프로필 이미지 사용
        return null;
      }
      return null;
    } catch (e) {
      print('프로필 이미지 조회 실패: $e');
      return null;
    }
  }

  // 기본 아바타 위젯
  Widget _buildDefaultAvatar(String name) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        image: DecorationImage(
          image: AssetImage('assets/icons/my/default_profile.png'),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  // 최근 대상 아이템 위젯 (프로필 사진 포함)
  Widget _buildRecentTargetItem(Map<String, dynamic> target) {
    // ✅ PaymentService에서 포인트 꺼내기 내역을 통해 실제 받을 대상 정보를 가져옴
    // userId는 이제 실제 받을 대상의 ID이고, userName은 받을 대상의 이름임
    final userName = target['userName'] ?? '알 수 없음';
    final bankName = target['bankName'] ?? '';
    final bankAccount = target['bankAccount'] ?? '';
    final userId = target['userId'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          // Profile Image - userId로 프로필 이미지 조회
          FutureBuilder<String?>(
            future: _getTargetUserProfileImage(userId, target),
            builder: (context, snapshot) {
              return Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(shape: BoxShape.circle),
                child: ClipOval(
                  child:
                      snapshot.hasData && snapshot.data!.isNotEmpty
                          ? Image.network(
                            snapshot.data!,
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return _buildDefaultAvatar(userName);
                            },
                          )
                          : _buildDefaultAvatar(userName),
                ),
              );
            },
          ),
          const SizedBox(width: 16),
          // Account Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName,
                  style: const TextStyle(
                    color: Color(0xFF4A4A4A),
                    fontSize: 12,
                    fontFamily: 'Pretendard-Light',
                    letterSpacing: -0.28,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      bankName,
                      style: const TextStyle(
                        color: Color(0xFF89DA8D),
                        fontSize: 10,
                        fontFamily: 'Pretendard-Light',
                        letterSpacing: -0.24,
                      ),
                    ),
                    if (bankName.isNotEmpty && bankAccount.isNotEmpty) ...[
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 0.4,
                        height: 8,
                        color: Color(0xFF8590A3),
                      ),
                      Text(
                        bankAccount,
                        style: const TextStyle(
                          color: Color(0xFF999999),
                          fontSize: 10,
                          fontFamily: 'Pretendard-Light',
                          letterSpacing: -0.24,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // 날짜 표시
          if (target['requestedDate'] != null) ...[
            Text(
              _formatDate(target['requestedDate']),
              style: const TextStyle(
                color: Color(0xFF999999),
                fontSize: 10,
                fontFamily: 'Pretendard-Light',
                letterSpacing: -0.24,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // 대상 사용자 프로필 이미지 가져오기
  Future<String?> _getTargetUserProfileImage(
    int? userId,
    Map<String, dynamic> target,
  ) async {
    if (userId == null) return null;

    try {
      // PaymentService에서 이미 프로필 이미지 URL을 가져왔는지 확인
      if (target.containsKey('profileImageUrl') &&
          target['profileImageUrl'] != null &&
          target['profileImageUrl'].toString().isNotEmpty) {
        return target['profileImageUrl'];
      }

      // PaymentService를 통해 사용자 프로필 조회
      final userProfile = await PaymentService.getUserProfile(userId);
      if (userProfile != null && userProfile['profileImagePath'] != null) {
        return AuthService.getFullProfileImageUrl(
          userProfile['profileImagePath'],
        );
      }

      return null;
    } catch (e) {
      print('대상 사용자 프로필 이미지 조회 실패: $e');
      return null;
    }
  }

  // 날짜 포맷팅
  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.month}.${date.day}';
    } catch (e) {
      return '';
    }
  }
}

class ButtonComponent extends StatelessWidget {
  final VoidCallback? onPressed;
  final String text;
  final bool isEnabled;

  const ButtonComponent({
    Key? key,
    this.onPressed,
    this.text = '다음',
    this.isEnabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          width: double.infinity, // Full width
          height: 45,
          child: ElevatedButton(
            onPressed: isEnabled ? onPressed : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF146AFF),
              disabledBackgroundColor: Colors.grey,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              elevation: 0,
            ),
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontFamily: 'Pretendard-Medium',
                letterSpacing: -0.24,
              ),
            ),
          ),
        );
      },
    );
  }
}
