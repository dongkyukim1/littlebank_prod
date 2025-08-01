import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../widgets/parent/bottom_navigation_bar.dart';
import '../../../../services/auth_service.dart';
import '../../../../services/payment_service.dart';
import '../../../../services/relationship_service.dart';
import '../../../../services/family_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'modal/parent_bank_selection_modal.dart';
import 'modal/parent_phone_input_modal.dart';
import 'modal/parent_point_amount_input_modal.dart';
import 'transfer/transfer_guide_screen.dart';

class ParentBankTransferScreen extends StatefulWidget {
  const ParentBankTransferScreen({super.key});

  @override
  State<ParentBankTransferScreen> createState() =>
      _ParentBankTransferScreenState();
}

class _ParentBankTransferScreenState extends State<ParentBankTransferScreen> {
  // 선택된 은행/증권사 (아이단과 동일)
  String _selectedBank = '';
  bool _isBankTab = true; // 은행 탭 선택 여부
  final String _searchQuery = ''; // 검색어 상태 추가
  final TextEditingController _searchController = TextEditingController();

  // 검색 관련 변수들
  final TextEditingController _phoneController = TextEditingController();
  bool _isSearching = false;
  String? _searchError;
  Map<String, dynamic>? _searchedUser;

  // 현재 보유 포인트
  int _currentPoints = 0;
  bool _isLoadingPoints = true;

  // 은행/증권사 리스트 (아이단과 동일)
  final List<Map<String, String>> _banks = [
    {'name': 'KB국민은행', 'logo': 'assets/logos/kb_bank.png'},
    {'name': '신한은행', 'logo': 'assets/logos/shinhan_bank.png'},
    {'name': '우리은행', 'logo': 'assets/logos/woori_bank.png'},
    {'name': '하나은행', 'logo': 'assets/logos/hana_bank.png'},
    {'name': '카카오뱅크', 'logo': 'assets/logos/kakao_bank.png'},
    {'name': '토스뱅크', 'logo': 'assets/logos/toss.png'},
    {'name': '케이뱅크', 'logo': 'assets/logos/kbank.png'},
    {'name': '농협은행', 'logo': 'assets/logos/nh_bank.png'},
    {'name': '기업은행', 'logo': 'assets/logos/ibk_bank.png'},
    {'name': '수협은행', 'logo': 'assets/logos/suhyup_bank.png'},
    {'name': 'SC은행', 'logo': 'assets/logos/sc_bank.png'},
    {'name': '씨티은행', 'logo': 'assets/logos/citi_bank.png'},
    {'name': '대구은행', 'logo': 'assets/logos/daegu_bank.png'},
    {'name': '부산은행', 'logo': 'assets/logos/busan_bank.png'},
    {'name': '광주은행', 'logo': 'assets/logos/gwangju_bank.png'},
    {'name': '제주은행', 'logo': 'assets/logos/jeju_bank.png'},
    {'name': '전북은행', 'logo': 'assets/logos/jeonbuk_bank.png'},
    {'name': '경남은행', 'logo': 'assets/logos/kyongnam_bank.png'},
    {'name': '새마을금고', 'logo': 'assets/logos/saemaul.png'},
  ];

  final List<Map<String, String>> _securities = [
    {'name': '미래에셋증권', 'logo': 'assets/logos/mirae_asset.png'},
    {'name': '삼성증권', 'logo': 'assets/logos/samsung_securities.png'},
    {'name': '대신증권', 'logo': 'assets/logos/daishin.png'},
    {'name': '카카오페이증권', 'logo': 'assets/logos/kakaopay_securities.png'},
    {'name': '토스증권', 'logo': 'assets/logos/toss_securities.png'},
    {'name': '키움증권', 'logo': 'assets/logos/kiwoom.png'},
    {'name': 'KB증권', 'logo': 'assets/logos/kb_securities.png'},
    {'name': '신한투자증권', 'logo': 'assets/logos/shinhan_investment.png'},
    {'name': 'NH투자증권', 'logo': 'assets/logos/nh_investment.png'},
    {'name': '한국투자증권', 'logo': 'assets/logos/korea_investment.png'},
  ];

  // 최근 포인트 전송 목록 (API에서 가져온 데이터)
  List<Map<String, dynamic>> _recentTransfers = [];
  bool _isLoadingRecentTransfers = true;

  // 가족 구성원 정보 추가
  List<Map<String, dynamic>> _familyMembers = [];
  bool _isLoadingFamily = true;

  // 연동된 계좌 정보
  Map<String, String?>? _linkedAccount;
  bool _isLoadingLinkedAccount = true;

  // 입력된 전화번호 저장
  String _inputtedPhoneNumber = '';

  @override
  void initState() {
    super.initState();
    _loadCurrentPoints();
    _loadRecentTransfers();
    _loadLinkedAccount();
    _loadFamilyMembers(); // 가족 구성원 로드 추가
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // 현재 보유 포인트 로드
  Future<void> _loadCurrentPoints() async {
    try {
      setState(() {
        _isLoadingPoints = true;
      });

      final userInfo = await AuthService.getUserInfo();

      // 사용자 정보에서 포인트 가져오기
      final points =
          userInfo['point'] is int
              ? userInfo['point']
              : int.tryParse(userInfo['point'].toString()) ?? 0;

      if (mounted) {
        setState(() {
          _currentPoints = points;
          _isLoadingPoints = false;
        });
      }
    } catch (e) {
      print('포인트 조회 오류: $e');
      if (mounted) {
        setState(() {
          _currentPoints = 0;
          _isLoadingPoints = false;
        });
      }
    }
  }

  // 은행명으로 로고 경로 찾기
  String _getBankLogo(String bankName) {
    print('은행 로고 매칭 시도: "$bankName"');

    final String lowerBankName = bankName.toLowerCase();

    if (lowerBankName.contains('카카오') || lowerBankName.contains('kakao')) {
      print('카카오뱅크 로고 선택됨');
      return 'assets/logos/kakao_bank.png';
    } else if (lowerBankName.contains('국민') || lowerBankName.contains('kb')) {
      print('KB국민은행 로고 선택됨');
      return 'assets/logos/kb_bank.png';
    } else if (lowerBankName.contains('신한')) {
      print('신한은행 로고 선택됨');
      return 'assets/logos/shinhan_bank.png';
    } else if (lowerBankName.contains('우리')) {
      print('우리은행 로고 선택됨');
      return 'assets/logos/woori_bank.png';
    } else if (lowerBankName.contains('하나')) {
      print('하나은행 로고 선택됨');
      return 'assets/logos/hana_bank.png';
    } else if (lowerBankName.contains('토스')) {
      print('토스뱅크 로고 선택됨');
      return 'assets/logos/toss.png';
    } else if (lowerBankName.contains('케이') || lowerBankName.contains('k뱅크')) {
      print('케이뱅크 로고 선택됨');
      return 'assets/logos/kbank.png';
    } else if (lowerBankName.contains('농협') || lowerBankName.contains('nh')) {
      print('농협은행 로고 선택됨');
      return 'assets/logos/nh_bank.png';
    } else if (lowerBankName.contains('기업') || lowerBankName.contains('ibk')) {
      print('기업은행 로고 선택됨');
      return 'assets/logos/ibk_bank.png';
    } else if (lowerBankName.contains('수협')) {
      print('수협은행 로고 선택됨');
      return 'assets/logos/suhyup_bank.png';
    } else if (lowerBankName.contains('sc')) {
      print('SC은행 로고 선택됨');
      return 'assets/logos/sc_bank.png';
    } else if (lowerBankName.contains('씨티') || lowerBankName.contains('citi')) {
      print('씨티은행 로고 선택됨');
      return 'assets/logos/citi_bank.png';
    } else if (lowerBankName.contains('대구')) {
      print('대구은행 로고 선택됨');
      return 'assets/logos/daegu_bank.png';
    } else if (lowerBankName.contains('부산')) {
      print('부산은행 로고 선택됨');
      return 'assets/logos/busan_bank.png';
    } else if (lowerBankName.contains('광주')) {
      print('광주은행 로고 선택됨');
      return 'assets/logos/gwangju_bank.png';
    } else if (lowerBankName.contains('제주')) {
      print('제주은행 로고 선택됨');
      return 'assets/logos/jeju_bank.png';
    } else if (lowerBankName.contains('전북')) {
      print('전북은행 로고 선택됨');
      return 'assets/logos/jeonbuk_bank.png';
    } else if (lowerBankName.contains('경남')) {
      print('경남은행 로고 선택됨');
      return 'assets/logos/kyongnam_bank.png';
    } else if (lowerBankName.contains('새마을')) {
      print('새마을금고 로고 선택됨');
      return 'assets/logos/saemaul.png';
    } else {
      print('기본 은행 로고 선택됨 (매칭되지 않은 은행: "$bankName")');
      return 'assets/logos/kakao_bank.png'; // 기본을 카카오뱅크로 변경
    }
  }

  // 연동된 계좌 정보 불러오기
  Future<void> _loadLinkedAccount() async {
    try {
      setState(() {
        _isLoadingLinkedAccount = true;
      });

      print('계좌 정보 로드 시작...');

      // 서버에서 최신 사용자 정보 가져오기
      final serverUserInfo = await AuthService.getUserInfo();
      print('서버에서 가져온 사용자 정보: $serverUserInfo');

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
                    serverUserInfo['bankAccount'] != null &&
                    serverUserInfo['bankCode'] != null &&
                    serverUserInfo['bankName'].toString().trim().isNotEmpty &&
                    serverUserInfo['bankAccount'].toString().trim().isNotEmpty)
                ? 'true'
                : 'false',
      };

      print('변환된 계좌 정보: $accountInfo');
      print('계좌 인증 상태: ${accountInfo['isVerified']}');

      if (mounted) {
        setState(() {
          _linkedAccount = accountInfo;
          _isLoadingLinkedAccount = false;
        });
      }
    } catch (e) {
      print('계좌 정보 로드 실패: $e');
      if (mounted) {
        setState(() {
          _linkedAccount = null;
          _isLoadingLinkedAccount = false;
        });
      }
    }
  }

  // 내 계좌 목록 생성 (연동된 계좌가 있는 경우에만)
  List<Map<String, dynamic>> _getMyAccounts() {
    print('내 계좌 목록 생성 시도...');
    print('현재 계좌 정보: $_linkedAccount');

    if (_linkedAccount?['isVerified'] == 'true') {
      final bankName = _linkedAccount?['bankName'] ?? '';
      final accountNumber = _linkedAccount?['bankAccount'] ?? '';
      final accountHolder = _linkedAccount?['accountHolder'] ?? '';

      print('계좌 정보 - 은행: $bankName, 계좌: $accountNumber, 예금주: $accountHolder');

      // 은행 로고 찾기
      String logoPath = _getBankLogo(bankName);
      print('선택된 로고 경로: $logoPath');

      final myAccount = [
        {
          'name': accountHolder,
          'account': accountNumber,
          'bank': bankName,
          'logo': logoPath,
          'userId': null, // 내 계좌이므로 userId는 null
          'bankCode': _linkedAccount?['bankCode'] ?? '',
        },
      ];

      print('생성된 내 계좌 목록: $myAccount');
      return myAccount;
    } else {
      print('계좌 인증 실패 또는 계좌 정보 없음');
      return [];
    }
  }

  // 최근 포인트 전송 계좌 목록 로드
  Future<void> _loadRecentTransfers() async {
    try {
      setState(() {
        _isLoadingRecentTransfers = true;
      });

      final response = await PaymentService.getLatestTransferAccounts(
        pageNumber: 0,
      );

      if (mounted && response['data'] != null) {
        final List<dynamic> transferData = response['data'];

        List<Map<String, dynamic>> transfers =
            transferData.map((transfer) {
              // 은행 로고 찾기
              String logoPath = _getBankLogo(transfer['bankName'] ?? '');

              return {
                'name': transfer['userName'] ?? '사용자',
                'account': transfer['bankAccount'] ?? '', // 실제 은행 계좌번호
                'bank': transfer['bankName'] ?? '은행',
                'logo': logoPath,
                'userId': transfer['userId'], // 포인트 전송 시 필요한 사용자 ID
                'bankCode': transfer['bankCode'] ?? '',
              };
            }).toList();

        setState(() {
          _recentTransfers = transfers;
          _isLoadingRecentTransfers = false;
        });
      }
    } catch (e) {
      print('최근 전송 계좌 조회 오류: $e');
      if (mounted) {
        setState(() {
          _recentTransfers = [];
          _isLoadingRecentTransfers = false;
        });
      }
    }
  }

  // 가족 구성원 목록 로드
  Future<void> _loadFamilyMembers() async {
    try {
      setState(() {
        _isLoadingFamily = true;
      });

      print('가족 구성원 목록 로드 시작');

      final familyInfo = await FamilyService.getFamilyInfo();

      if (mounted && familyInfo != null) {
        final List<dynamic> memberList = familyInfo['memberInfoList'] ?? [];
        print('가족 정보 로드 성공 - 멤버 ${memberList.length}명');

        // 자녀만 필터링하고 포인트 전송용 데이터로 변환
        final List<Map<String, dynamic>> children =
            memberList.where((member) => member['role'] == 'CHILD').map((
              member,
            ) {
              // 은행 로고 찾기
              String logoPath = _getBankLogo(member['bankName'] ?? '');

              print('가족 구성원 정보: ${member}');
              print('가족 구성원 userId: ${member['userId']}');

              return {
                'name': member['nickname'] ?? member['realName'] ?? '자녀',
                'account': member['bankAccount'] ?? '', // 은행 계좌번호
                'bank': member['bankName'] ?? '은행',
                'logo': logoPath,
                'userId': member['userId'], // 포인트 전송에 필요한 사용자 ID
                'bankCode': member['bankCode'] ?? '',
                'phone': member['phone'] ?? '', // 전화번호도 저장
              };
            }).toList();

        setState(() {
          _familyMembers = children;
          _isLoadingFamily = false;
        });

        print('필터링된 자녀 수: ${children.length}');
      } else {
        print('가족 정보 조회 실패 또는 가족 정보 없음');
        if (mounted) {
          setState(() {
            _familyMembers = [];
            _isLoadingFamily = false;
          });
        }
      }
    } catch (e) {
      print('가족 구성원 목록 로드 중 오류: $e');
      if (mounted) {
        setState(() {
          _isLoadingFamily = false;
          _familyMembers = [];
        });
      }
    }
  }

  // 전화번호로 사용자 검색
  Future<void> _searchUser(String phoneNumber) async {
    if (phoneNumber.trim().isEmpty) {
      setState(() {
        _searchError = '전화번호를 입력해주세요';
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _searchError = null;
      _searchedUser = null;
    });

    try {
      final result = await RelationshipService.searchUserByPhone(
        phoneNumber.trim(),
      );

      print('전화번호 검색 결과: $result');

      if (mounted) {
        setState(() {
          _isSearching = false;
          if (result != null) {
            // 검색 결과에서 올바른 필드 추출
            _searchedUser = {
              'id': result['userId'] ?? result['id'], // userId 또는 id 필드 확인
              'name':
                  result['name'] ??
                  result['nickname'] ??
                  result['realName'] ??
                  '사용자',
              'bankName': result['bankName'] ?? '',
              'bankAccount': result['bankAccount'] ?? '',
              'phone': result['phone'] ?? phoneNumber,
            };
            _searchError = null;

            print('검색된 사용자 정보 설정됨: ${_searchedUser}');
            print('검색된 사용자 ID: ${_searchedUser!['id']}');

            // 검색 성공 시 바로 금액 입력 다이얼로그 표시
            _showAmountInputDialog();
          } else {
            _searchError = '해당 전화번호로 등록된 사용자를 찾을 수 없습니다';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSearching = false;
          _searchError = '사용자 검색 중 오류가 발생했습니다';
        });
      }
      print('사용자 검색 오류: $e');
    }
  }

  // 사용자 선택 초기화
  void _clearSelection() {
    setState(() {
      _searchedUser = null;
      _searchError = null;
      _phoneController.clear();
      _inputtedPhoneNumber = '';
    });
  }

  // 최근 이체한 사용자 선택
  void _selectRecentUser(Map<String, dynamic> user) {
    // 최근 사용자 선택 시 해당 사용자 정보를 바로 설정
    setState(() {
      _searchedUser = {
        'id': user['userId'],
        'name': user['name'],
        'bankName': user['bank'],
        'bankAccount': user['account'],
      };
      _inputtedPhoneNumber = user['account']; // 임시로 계좌번호 저장
    });

    print('최근 사용자 선택됨: ${_searchedUser}');
    print('선택된 사용자 ID: ${_searchedUser!['id']}');

    // 바로 금액 입력 화면으로 이동
    _showAmountInputDialog();
  }

  // 전화번호 입력 모달 표시 (바텀 시트 형태로 변경)
  void _showPhoneInputModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return ParentPhoneInputModal(
          selectedBank: _selectedBank,
          onPrevious: () {
            Navigator.pop(context);
            _showBankSelectionSheet();
          },
          onNext: (phoneNumber) {
            setState(() {
              _inputtedPhoneNumber = phoneNumber;
            });
            Navigator.pop(context);
            _searchUser(phoneNumber);
          },
        );
      },
    );
  }

  // 포인트 이체 처리
  void _showAmountInputDialog() {
    if (_searchedUser == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('먼저 사용자를 검색해주세요')));
      return;
    }

    print('금액 입력 모달 표시');
    print('전달할 사용자 정보: ${_searchedUser}');
    print('전달할 사용자 ID: ${_searchedUser!['id']}');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => ParentPointAmountInputModal(
            selectedBank: _selectedBank,
            phoneNumber: _inputtedPhoneNumber,
            receiverName: _searchedUser!['name'] ?? '사용자',
            availablePoints: _currentPoints,
            receiverId: _searchedUser!['id'], // 사용자 ID 전달
            onPrevious: () {
              Navigator.pop(context);
              _showPhoneInputModal();
            },
          ),
    );
  }

  // 은행 선택 바텀 시트 표시 (아이단과 동일)
  void _showBankSelectionSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return ParentBankSelectionModal(
          isBankTab: _isBankTab,
          onTabChanged: (isBank) {
            setState(() {
              _isBankTab = isBank;
            });
          },
          banks: _banks,
          securities: _securities,
          onBankSelected: (bankName) {
            setState(() {
              _selectedBank = bankName;
            });
            Navigator.pop(context);

            // 은행 선택 후 전화번호 입력으로 포커스
            // 여기서는 별도 모달 대신 현재 화면의 전화번호 입력 필드로 포커스
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: null,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TransferGuideScreen(),
                  ),
                );
              },
              child: Center(
                child: Text(
                  '보내기 안내',
                  style: TextStyle(
                    color: const Color(0xFF8490A3),
                    fontSize: 13,
                    fontFamily: 'Pretendard-Light',
                    letterSpacing: -0.28,
                  ),
                ),
              ),
            ),
          ),
        ],
        leadingWidth: 0,
        leading: SizedBox.shrink(),
        automaticallyImplyLeading: false,
      ),
      body:
          _isLoadingPoints
              ? Center(child: CircularProgressIndicator())
              : Container(
                width: screenWidth,
                color: Colors.white,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // 상단 제목 부분
                      Container(
                        width: screenWidth,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: const BoxDecoration(color: Colors.white),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: double.infinity,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '어디로 포인트를 보낼까요?',
                                          style: TextStyle(
                                            color: const Color(0xFF202020),
                                            fontSize: 22,
                                            fontFamily: 'Pretendard-Bold',
                                            letterSpacing: -0.80,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      SizedBox(
                                        child: Text(
                                          '보유 포인트: ',
                                          style: TextStyle(
                                            color: const Color(0xFF8490A3),
                                            fontSize: 14,
                                            fontFamily: 'Pretendard-Light',
                                            letterSpacing: -0.28,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        '${_formatCurrency(_currentPoints)}원',
                                        style: TextStyle(
                                          color: const Color(0xFF146AFF),
                                          fontSize: 14,
                                          fontFamily: 'Pretendard-Bold',
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
                      ),

                      const SizedBox(height: 24),

                      // 은행 선택 섹션 (아이단과 동일)
                      SizedBox(
                        width: screenWidth,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // 은행/증권사 선택 드롭다운 (아이단과 동일)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                    child: Container(
                                      width: double.infinity,
                                      height: 46,
                                      decoration: ShapeDecoration(
                                        shape: RoundedRectangleBorder(
                                          side: BorderSide(
                                            width: 0.80,
                                            color: const Color(0xFF7F96B9),
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                      child: InkWell(
                                        onTap: () {
                                          _showBankSelectionSheet();
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                _selectedBank.isEmpty
                                                    ? '은행 또는 증권사를 선택할게요'
                                                    : _selectedBank,
                                                style: TextStyle(
                                                  color:
                                                      _selectedBank.isEmpty
                                                          ? const Color(
                                                            0xFF999999,
                                                          )
                                                          : Colors.black,
                                                  fontSize: 13,
                                                  fontFamily:
                                                      'Pretendard-Light',
                                                  letterSpacing: -0.28,
                                                ),
                                              ),
                                              Icon(
                                                Icons.arrow_drop_down,
                                                color: const Color(0xFF999999),
                                                size: 20,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 32),

                                  // 최근 포인트 전송 목록 섹션 (아이단과 유사하게)
                                  SizedBox(
                                    width: double.infinity,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        // 내 계좌 섹션 (연동된 계좌가 있는 경우에만)
                                        if (!_isLoadingLinkedAccount &&
                                            _getMyAccounts().isNotEmpty) ...[
                                          _buildMyAccountSection(),
                                          const SizedBox(height: 28),
                                        ],

                                        // 최근 전송 섹션
                                        _buildRecentTransferSection(),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 32),

                                  // 다음 버튼 (아이단과 동일)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                    child: SizedBox(
                                      width: double.infinity,
                                      height: 45,
                                      child: ElevatedButton(
                                        onPressed: () {
                                          if (_selectedBank.isNotEmpty) {
                                            _showPhoneInputModal();
                                          } else {
                                            _showBankSelectionSheet();
                                          }
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(
                                            0xFF146AFF,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 12,
                                          ),
                                        ),
                                        child: Text(
                                          '다음',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontFamily: 'Pretendard-Medium',
                                            letterSpacing: -0.24,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  // 하단 여백 추가
                                  const SizedBox(height: 40),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      bottomNavigationBar: const ParentBottomNavigationBar(selectedIndex: 4),
    );
  }

  // 최근 전송 섹션 위젯 (로딩 상태 포함)
  Widget _buildRecentTransferSection() {
    return SizedBox(
      width: double.infinity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 섹션 타이틀
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: const BoxDecoration(color: Colors.white),
            child: Text(
              '최근 내가 포인트를 보낸 사람이에요',
              style: TextStyle(
                color: const Color(0xFF202020),
                fontSize: 16,
                fontFamily: 'Pretendard-Bold',
                letterSpacing: -0.60,
              ),
            ),
          ),

          // 계좌 목록 또는 로딩 상태
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child:
                _isLoadingRecentTransfers
                    ? Container(
                      height: 80,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: const Color(0xFF146AFF),
                          strokeWidth: 2,
                        ),
                      ),
                    )
                    : _recentTransfers.isEmpty
                    ? Container(
                      height: 80,
                      child: Center(
                        child: Text(
                          '최근 포인트를 보낸 사람이 없습니다',
                          style: TextStyle(
                            color: const Color(0xFF8490A3),
                            fontSize: 12,
                            fontFamily: 'Pretendard-Light',
                            letterSpacing: -0.24,
                          ),
                        ),
                      ),
                    )
                    : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children:
                          _recentTransfers
                              .map(
                                (account) => _buildAccountItem(
                                  name: account['name'],
                                  accountNumber: account['account'], // 은행 계좌번호
                                  bank: account['bank'],
                                  logoPath: account['logo'],
                                  onTap: () => _selectRecentUser(account),
                                ),
                              )
                              .toList(),
                    ),
          ),
        ],
      ),
    );
  }

  // 계좌 아이템 위젯 (아이단과 동일)
  Widget _buildAccountItem({
    required String name,
    required String accountNumber,
    required String bank,
    required String logoPath,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 16),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 은행 로고
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    spreadRadius: 1,
                    blurRadius: 2,
                  ),
                ],
              ),
              padding: EdgeInsets.all(4),
              child: Image.asset(logoPath, width: 26, height: 26),
            ),
            const SizedBox(width: 12),
            // 계좌 정보
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      color: const Color(0xFF4A4A4A),
                      fontSize: 13,
                      fontFamily: 'Pretendard-Light',
                      letterSpacing: -0.26,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        bank,
                        style: TextStyle(
                          color: Color(0xFF146AFF),
                          fontSize: 11,
                          fontFamily: 'Pretendard-Light',
                          letterSpacing: -0.22,
                        ),
                      ),
                      Text(
                        ' • ',
                        style: TextStyle(
                          color: const Color(0xFF999999),
                          fontSize: 11,
                          fontFamily: 'Pretendard-Light',
                        ),
                      ),
                      Text(
                        accountNumber,
                        style: TextStyle(
                          color: const Color(0xFF999999),
                          fontSize: 11,
                          fontFamily: 'Pretendard-Light',
                          letterSpacing: -0.22,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 금액 포맷팅 (천 단위 콤마)
  String _formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  // 내 계좌 섹션 위젯
  Widget _buildMyAccountSection() {
    return SizedBox(
      width: double.infinity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: const BoxDecoration(color: Colors.white),
            child: Text(
              '내 계좌로 연결됬어요',
              style: TextStyle(
                color: const Color(0xFF202020),
                fontSize: 16,
                fontFamily: 'Pretendard-Bold',
                letterSpacing: -0.60,
              ),
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children:
                  _getMyAccounts()
                      .map(
                        (account) => _buildAccountItem(
                          name: account['name'],
                          accountNumber: account['account'],
                          bank: account['bank'],
                          logoPath: account['logo'],
                          onTap: () => _selectRecentUser(account),
                        ),
                      )
                      .toList(),
            ),
          ),
        ],
      ),
    );
  }
}
