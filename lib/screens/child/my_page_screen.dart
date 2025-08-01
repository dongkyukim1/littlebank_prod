import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../widgets/common/bottom_navigation_bar.dart';
import 'my/point_history_screen.dart';
import 'my/total_point_history_screen.dart';
import '../../services/auth_service.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'my/activity_history_screen.dart';
import 'my/notice_screen.dart';
import '../common/logout_modal.dart';
import 'benefit/little_bank_benefits_screen.dart';
import 'my/settings_screen.dart';
import 'my/member_management_screen.dart';
import 'my/cs/customer_service_screen.dart';
import 'share_with_friend_screen.dart';
import '../child/edit_profile_screen.dart';
import 'bank/bank_withdrawal_screen.dart';
import 'bank/charge_screen.dart';
import 'my/family_management_screen.dart';
import 'my/post_history_screen.dart';
import '../../services/payment_service.dart';
import '../notice_kid/notice_kid.dart';
import '../notice_kid/child_screen_wrapper.dart';
import 'bank/account_link_screen.dart';
import '../../services/mission_service.dart';
import '../../services/subscription_service.dart';
import 'my/subscrition/subscription_on_screen.dart';
import '../../services/school_service.dart';
import 'my/school_search_modal.dart';

class MyPageScreen extends StatefulWidget {
  const MyPageScreen({super.key});

  @override
  State<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> {
  // 마이 탭 선택
  final int _selectedIndex = 4;

  // 적립금 카드 확장 여부
  bool _isPointCardExpanded = false;

  // 각 메뉴 섹션의 확장 상태 (기본값은 true - 펼쳐진 상태)
  final Map<String, bool> _expandedSections = {
    '용돈 내역': true,
    '계좌 관리': true,
    '활동 내역': true,
    '관리 지원': true,
    '고객 지원': true,
  };

  // 금액 포맷팅 (천 단위 콤마)
  String _formatCurrency(dynamic amount) {
    final int value =
        amount is int ? amount : int.tryParse(amount.toString()) ?? 0;
    return value.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  // 이름 길이에 따라 동적으로 폰트 크기 조정
  double _getDynamicFontSize(String name) {
    // 기본 폰트 크기
    double baseFontSize = 14.0;

    // 이름 + "님의 현재 보유 포인트" 문자열의 총 길이 계산
    String fullText = '${name}님의 현재 보유 포인트';

    // 길이에 따라 폰트 크기 조정
    if (fullText.length <= 12) {
      return baseFontSize; // 14
    } else if (fullText.length <= 15) {
      return baseFontSize - 1.0; // 13
    } else if (fullText.length <= 18) {
      return baseFontSize - 2.0; // 12
    } else {
      return baseFontSize - 3.0; // 11
    }
  }

  // 회원가입일부터 현재까지의 일수 계산
  int _calculateDaysSinceJoined() {
    if (_userInfo?['registeredAt'] == null) return 0;

    try {
      DateTime joinDate;
      final registeredAt = _userInfo!['registeredAt'];

      if (registeredAt is String) {
        joinDate = DateTime.parse(registeredAt);
      } else if (registeredAt is DateTime) {
        joinDate = registeredAt;
      } else {
        return 0;
      }

      final now = DateTime.now();
      final difference = now.difference(joinDate).inDays;
      return difference + 1; // 가입일 포함하여 계산
    } catch (e) {
      print('가입일 계산 오류: $e');
      return 0;
    }
  }

  // 총 미션 개수 로드
  Future<void> _loadTotalMissionCount() async {
    try {
      final missionData = await MissionService.getChildMissions(page: 0);
      if (missionData != null && mounted) {
        setState(() {
          _totalMissionCount = missionData['totalElement'] ?? 0;
        });
        print('총 미션 개수 로드 성공: $_totalMissionCount개');
      }
    } catch (e) {
      print('미션 개수 로딩 오류: $e');
      // 오류가 발생해도 기본값 0으로 유지
    }
  }

  // 사용자 정보를 저장할 변수 추가
  Map<String, dynamic>? _userInfo;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isAccountLinked = false; // 계좌 연동 여부 추가
  int _totalMissionCount = 0; // 총 미션 개수

  // 타이틀 텍스트에 스타일 적용하는 메서드
  Widget _applyTextStyle(
    String text,
    String styleType,
    double fontSize,
    Color color,
  ) {
    // Typography 확장 메서드 대신 직접 TextStyle 사용
    TextStyle style;
    switch (styleType) {
      case 'thin':
        style = TextStyle(
          fontFamily: 'Pretendard',
          fontSize: fontSize,
          fontWeight: FontWeight.w100,
          color: color,
        );
        break;
      case 'extraLight':
        style = TextStyle(
          fontFamily: 'Pretendard',
          fontSize: fontSize,
          fontWeight: FontWeight.w200,
          color: color,
        );
        break;
      case 'light':
        style = TextStyle(
          fontFamily: 'Pretendard',
          fontSize: fontSize,
          fontWeight: FontWeight.w300,
          color: color,
        );
        break;
      case 'regular':
        style = TextStyle(
          fontFamily: 'Pretendard',
          fontSize: fontSize,
          fontWeight: FontWeight.w400,
          color: color,
        );
        break;
      case 'medium':
        style = TextStyle(
          fontFamily: 'Pretendard',
          fontSize: fontSize,
          fontWeight: FontWeight.w500,
          color: color,
        );
        break;
      case 'semiBold':
        style = TextStyle(
          fontFamily: 'Pretendard',
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          color: color,
        );
        break;
      case 'bold':
        style = TextStyle(
          fontFamily: 'Pretendard',
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          color: color,
        );
        break;
      case 'extraBold':
        style = TextStyle(
          fontFamily: 'Pretendard',
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          color: color,
        );
        break;
      case 'black':
        style = TextStyle(
          fontFamily: 'Pretendard',
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
          color: color,
        );
        break;
      default:
        style = TextStyle(
          fontFamily: 'Pretendard',
          fontSize: fontSize,
          fontWeight: FontWeight.w400,
          color: color,
        );
    }
    return Text(text, style: style);
  }

  @override
  void initState() {
    super.initState();
    _loadUserInfo();

    // 상태 표시줄 색상 설정
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent, // 상태 표시줄 배경을 투명하게
        statusBarIconBrightness: Brightness.light, // 상태 표시줄 아이콘 색상
      ),
    );

    // 화면이 완전히 로드된 후 포인트 새로고침 (포인트 꺼내기 후 돌아온 경우 대비)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshUserInfo(withDelay: true);
      // 학교 정보 등록 모달 체크
      _checkAndShowSchoolRegistrationModal();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 화면이 다시 활성화될 때마다 사용자 정보 새로고침
    print('🔄 [아이단 마이페이지] didChangeDependencies 호출 - 포인트 새로고침');
    _refreshUserInfo(withDelay: false);
  }

  @override
  void dispose() {
    // 화면 종료시 상태 표시줄 초기화 (옵션)
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    super.dispose();
  }

  // 사용자 정보 불러오기
  Future<void> _loadUserInfo() async {
    try {
      if (mounted) {
        setState(() {
          _isLoading = true;
          _errorMessage = null;
        });
      }

      final userInfo = await AuthService.getUserInfo();

      // 총 누적 포인트 가져오기
      final totalPoints = await PaymentService.getTotalPoints();
      userInfo['totalPoint'] = totalPoints;

      // 계좌 연동 상태 확인 (서버 데이터 기반)
      final isLinked =
          userInfo['bankName'] != null &&
          userInfo['bankName'].toString().isNotEmpty &&
          userInfo['bankAccount'] != null &&
          userInfo['bankAccount'].toString().isNotEmpty &&
          userInfo['bankCode'] != null &&
          userInfo['bankCode'].toString().isNotEmpty;

      // 사용자 정보 상세 로깅
      print('사용자 정보 로드 성공: $userInfo');
      print('포인트 정보: ${userInfo['point']}');
      print('계좌 연동 상태: $isLinked');
      userInfo.forEach((key, value) {
        print('사용자 정보 키: $key, 값: $value');
      });

      // 역할 정보 확인
      if (userInfo.containsKey('role')) {
        print('사용자 역할(role): ${userInfo['role']}');
      }
      if (userInfo.containsKey('authority')) {
        print('사용자 권한(authority): ${userInfo['authority']}');
      }

      if (mounted) {
        setState(() {
          _userInfo = userInfo;
          _isAccountLinked = isLinked;
          _isLoading = false;
        });

        // 미션 개수 로드
        _loadTotalMissionCount();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
      print('사용자 정보 로딩 오류: $e');
    }
  }

  // 사용자 정보 새로고침 (포인트 꺼내기 후 돌아왔을 때 호출)
  Future<void> _refreshUserInfo({bool withDelay = false}) async {
    try {
      print('🔄 [아이단 마이페이지] 사용자 정보 새로고침 시작 (withDelay: $withDelay)');

      if (withDelay) {
        // 지연 후 새로고침 (다른 화면에서 돌아온 직후)
        await Future.delayed(Duration(milliseconds: 500));
        print('🔄 [아이단 마이페이지] 지연 후 새로고침 실행');
      }

      // 현재 보유 포인트 조회 (강제 새로고침)
      final userInfo = await AuthService.getUserInfo();
      print('🔄 [아이단 마이페이지] 새로운 포인트: ${userInfo['point']}');

      // 총 누적 포인트 가져오기
      final totalPoints = await PaymentService.getTotalPoints();
      userInfo['totalPoint'] = totalPoints;

      // 계좌 연동 상태 확인
      final isLinked =
          userInfo['bankName'] != null &&
          userInfo['bankName'].toString().isNotEmpty &&
          userInfo['bankAccount'] != null &&
          userInfo['bankAccount'].toString().isNotEmpty &&
          userInfo['bankCode'] != null &&
          userInfo['bankCode'].toString().isNotEmpty;

      if (mounted) {
        setState(() {
          _userInfo = userInfo;
          _isAccountLinked = isLinked;
        });
        print('🔄 [아이단 마이페이지] UI 업데이트 완료 - 포인트: ${userInfo['point']}');
      }
    } catch (e) {
      print('🔄 [아이단 마이페이지] 사용자 정보 새로고침 오류: $e');
    }
  }

  // 프로필 이미지 업로드 처리
  Future<void> _updateProfileImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedImage = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedImage != null) {
        // 로딩 상태 설정
        if (mounted) {
          setState(() {
            _isLoading = true;
          });
        }

        // 이미지 업로드 처리
        final imagePath = await AuthService.uploadProfileImage(
          File(pickedImage.path),
        );

        print('업로드된 이미지 경로: $imagePath');

        // 프로필 업데이트 API 호출 (profileImagePath만 업데이트)
        await AuthService.updateUserProfile(imagePath);

        // 사용자 정보 다시 로드 (mounted 체크 추가)
        if (mounted) {
          await _loadUserInfo();
        }
      }
    } catch (e) {
      // 오류 처리 (mounted 체크 추가)
      if (mounted) {
        setState(() {
          _errorMessage = '프로필 이미지 업데이트 중 오류가 발생했습니다: $e';
          _isLoading = false;
        });
      }
      print('프로필 이미지 업데이트 오류: $e');
    }
  }

  // 프로필 이미지 변경 옵션을 보여주는 바텀 시트
  void _showProfileImageOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxHeight:
            MediaQuery.of(context).size.height * 0.66, // 전체 화면 높이의 2/3로 제한
      ),
      builder: (BuildContext context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height;

        return Container(
          width: screenWidth,
          decoration: BoxDecoration(
            color: Color(0xFFFFFFFF),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 안내 텍스트 추가
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 사용자 이름 및 메인 타이틀
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${_userInfo?['name'] ?? '회원'}님 프로필 이미지를 변경해 보세요!',
                          style: TextStyle(
                            fontSize: screenWidth * 0.04, // 반응형 폰트 크기
                            fontFamily: 'Pretendard-Bold',
                            color: Color(0xFF202020),
                          ),
                          textAlign: TextAlign.left,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: Container(
                          width: 24,
                          height: 24,
                          child: Center(
                            child: Image.asset(
                              'assets/icons/my/close.png',
                              width: 24,
                              height: 24,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  // 서브 타이틀
                  Text(
                    '아이콘을 선택하거나, 직접 촬영할 수 있어요',
                    style: TextStyle(
                      fontSize: screenWidth * 0.035, // 반응형 폰트 크기
                      fontFamily: 'Pretendard-Light',
                      color: Color(0xFF999999),
                    ),
                    textAlign: TextAlign.left,
                  ),
                ],
              ),

              // 현재 프로필 이미지 추가
              SizedBox(height: 16),
              Center(
                child: Container(
                  width: screenWidth * 0.2, // 화면 너비의 20%로 조정
                  height: screenWidth * 0.2, // 정사각형 유지
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Color(0xFFE0E5F2), width: 2),
                  ),
                  child: ClipOval(child: _buildProfileImageContent()),
                ),
              ),

              // 옵션 버튼들
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // 카메라 옵션
                  _buildProfileOptionButtonWithImage(
                    imagePath: 'assets/icons/my/촬영.png',
                    label: '카메라',
                    size: screenWidth * 0.13, // 화면 너비에 비례하여 조정
                    fontSize: screenWidth * 0.03,
                    onTap: () {
                      Navigator.pop(context);
                      _updateProfileImage(ImageSource.camera);
                    },
                  ),

                  // 갤러리 옵션
                  _buildProfileOptionButtonWithImage(
                    imagePath: 'assets/icons/my/앨범.png',
                    label: '갤러리',
                    size: screenWidth * 0.13,
                    fontSize: screenWidth * 0.03,
                    onTap: () {
                      Navigator.pop(context);
                      _updateProfileImage(ImageSource.gallery);
                    },
                  ),

                  // 기본 이미지로 변경 버튼
                  _buildProfileOptionButtonWithImage(
                    imagePath: 'assets/icons/my/default_profile.png',
                    label: '기본 이미지',
                    size: screenWidth * 0.13,
                    fontSize: screenWidth * 0.03,
                    isHighlighted: false,
                    onTap: () async {
                      Navigator.pop(context);
                      await _setDefaultProfileImage();
                    },
                  ),
                ],
              ),

              // 하단의 파란색 확인 버튼 추가
              SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: screenHeight * 0.055, // 화면 높이에 비례
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF5D9DFF),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.zero,
                  ),
                  child: Text(
                    '저장하기',
                    style: TextStyle(
                      fontFamily: 'Pretendard-Light',
                      fontSize: screenWidth * 0.04,
                    ),
                  ),
                ),
              ),

              // 하단 여백
              SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  // 이미지를 사용하는 프로필 변경 옵션 버튼
  Widget _buildProfileOptionButtonWithImage({
    required String imagePath,
    required String label,
    required VoidCallback onTap,
    double size = 58.0,
    double fontSize = 12.0,
    bool isHighlighted = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 이미지 원형 버튼
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isHighlighted ? Color(0xFFFFC266) : Color(0xFFF0F2F7),
            ),
            child: Center(
              child: Image.asset(
                imagePath,
                width:
                    imagePath.contains('default_profile')
                        ? size * 0.9
                        : size * 0.5,
                height:
                    imagePath.contains('default_profile')
                        ? size * 0.9
                        : size * 0.5,
                color:
                    isHighlighted
                        ? Colors.white
                        : (imagePath.contains('default_profile')
                            ? null
                            : Color(0xFF999999)),
              ),
            ),
          ),
          SizedBox(height: 4),
          // 라벨
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Pretendard-Light',
              fontSize: fontSize,
              color: isHighlighted ? Color(0xFFFFA000) : Color(0xFF999999),
            ),
          ),
        ],
      ),
    );
  }

  // 프로필 변경 옵션 버튼
  Widget _buildProfileOptionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    double size = 58.0,
    double fontSize = 12.0,
    bool isHighlighted = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 아이콘 원형 버튼
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isHighlighted ? Color(0xFFFFC266) : Color(0xFFF0F2F7),
            ),
            child: Icon(
              icon,
              color: isHighlighted ? Colors.white : Color(0xFF999999),
              size: size * 0.4,
            ),
          ),
          SizedBox(height: 4),
          // 라벨
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Pretendard-Light',
              fontSize: fontSize,
              color: isHighlighted ? Color(0xFFFFA000) : Color(0xFF999999),
            ),
          ),
        ],
      ),
    );
  }

  // 메뉴 섹션 토글 기능
  void _toggleSection(String title) {
    setState(() {
      _expandedSections[title] = !(_expandedSections[title] ?? true);
    });
  }

  @override
  Widget build(BuildContext context) {
    // 화면 크기 가져오기
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // 상태 표시줄 투명화 설정
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: ChildScreenWrapper(
        child: Scaffold(
          backgroundColor: const Color(0xFFE7ECF6), // 배경색 변경
          extendBodyBehindAppBar: true,
          body:
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                  ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '오류가 발생했습니다',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          _errorMessage!,
                          style: TextStyle(fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadUserInfo,
                          child: Text('다시 시도'),
                        ),
                      ],
                    ),
                  )
                  : SingleChildScrollView(
                    child: Column(
                      children: [
                        // 상단 파란색 영역
                        Container(
                          decoration: ShapeDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF91B9FF),
                                const Color(0xFF5D9EFF),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(40),
                                bottomRight: Radius.circular(40),
                              ),
                            ),
                          ),
                          child: SafeArea(
                            child: Column(
                              children: [
                                // 상단 아이콘 부분
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.fromLTRB(
                                    20,
                                    20,
                                    20,
                                    10,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      // 왼쪽 로고
                                      Image.asset(
                                        'assets/icons/sub_logo.png',
                                        width: 32,
                                        height: 32,
                                      ),
                                      // 오른쪽 아이콘들
                                      Row(
                                        children: [
                                          // 로그아웃 아이콘
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              right: 16,
                                            ),
                                            child: GestureDetector(
                                              onTap: () {
                                                LogoutModal.show(context);
                                              },
                                              child: Image.asset(
                                                'assets/images/logout.png',
                                                width: 24,
                                                height: 24,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                          // 설정 아이콘
                                          GestureDetector(
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder:
                                                      (context) =>
                                                          const SettingsScreen(),
                                                ),
                                              );
                                            },
                                            child: Image.asset(
                                              'assets/images/settings.png',
                                              width: 24,
                                              height: 24,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                // 프로필 카드
                                _buildProfileCard(),

                                const SizedBox(height: 24),

                                // 적립금 정보 카드
                                _buildPointsCard(),

                                const SizedBox(height: 30),
                              ],
                            ),
                          ),
                        ),

                        // 메뉴 리스트
                        const SizedBox(height: 24),
                        _buildMenuList(),

                        // 하단 여백 추가
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
          bottomNavigationBar: const CommonBottomNavigationBar(
            selectedIndex: 4,
          ),
        ),
      ),
    );
  }

  // 프로필 카드 (프로필부터 충전하기까지)
  Widget _buildProfileCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.fromRGBO(145, 185, 255, 1),
            Color.fromRGBO(93, 158, 255, 1),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          // 주요 그림자 - 아래쪽
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 12,
            spreadRadius: 1,
            offset: Offset(0, 6),
          ),
          // 흐릿한 외부 그림자
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 15,
            spreadRadius: 3,
            offset: Offset(0, 4),
          ),
          // 위쪽 하이라이트
          BoxShadow(
            color: Colors.white.withOpacity(0.15),
            blurRadius: 8,
            spreadRadius: -1,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          // 프로필 정보 부분
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 프로필 이미지
              Container(
                padding: EdgeInsets.only(top: 4),
                child: Stack(
                  children: [
                    GestureDetector(
                      onTap: _showProfileImageOptions,
                      child: Container(
                        width: 68,
                        height: 68,
                        margin: EdgeInsets.only(left: 4, right: 4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          color: Color.fromRGBO(156, 193, 255, 1),
                        ),
                        child: ClipOval(child: _buildProfileImageContent()),
                      ),
                    ),
                    // 편집 아이콘 (오른쪽 아래에 위치)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Transform.translate(
                        offset: Offset(8, 8),
                        child: GestureDetector(
                          onTap: _showProfileImageOptions,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              shape: BoxShape.circle,
                            ),
                            child: Image.asset(
                              'assets/icons/my/profile_pen.png',
                              width: 40,
                              height: 40,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // 사용자 정보 및 수정하기 버튼 행
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 자녀 태그와 수정하기 버튼을 가로로 배치
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // 자녀 태그
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: ShapeDecoration(
                            color: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            '자녀',
                            style: TextStyle(
                              color: Color(0xFF89DA8D),
                              fontSize: 11,
                              fontFamily: 'Pretendard-Light',
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),

                        // 수정하기 버튼
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => EditProfileScreen(
                                      userInfo: _userInfo ?? {},
                                    ),
                              ),
                            ).then((_) {
                              _loadUserInfo();
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            margin: EdgeInsets.only(right: 4),
                            decoration: BoxDecoration(
                              color: Color.fromRGBO(240, 242, 247, 1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              '수정하기',
                              style: TextStyle(
                                color: Color(0xFF999999),
                                fontSize: 11,
                                fontFamily: 'Pretendard-ExtraLight',
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 3),
                    Text(
                      _userInfo?['name'] ?? '이름',
                      style: const TextStyle(
                        fontSize: 16,
                        fontFamily: 'Pretendard-Bold',
                        color: Colors.black,
                        letterSpacing: -0.32,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      _userInfo?['email'] ?? '이메일',
                      style: TextStyle(
                        fontSize: 11,
                        fontFamily: 'Pretendard-Light',
                        color: Colors.white,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // 사용 정보 카드
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: Color.fromRGBO(224, 229, 242, 1),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  spreadRadius: 0,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 함께한 일수
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '리틀뱅크와 함께 한 지',
                        style: TextStyle(
                          color: Colors.black.withOpacity(0.7),
                          fontSize: 10,
                          fontFamily: 'Pretendard-Light',
                          letterSpacing: -0.22,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '총 ${_calculateDaysSinceJoined()}일째',
                        style: TextStyle(
                          color: Color.fromRGBO(93, 158, 255, 1),
                          fontSize: 14,
                          fontFamily: 'Pretendard-SemiBold',
                          letterSpacing: -0.28,
                        ),
                      ),
                    ],
                  ),
                ),

                // 구분선
                Container(
                  height: 36,
                  width: 1,
                  color: Colors.black.withOpacity(0.1),
                ),

                // 미션 수
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '리틀뱅크와 함께 한 미션이',
                        style: TextStyle(
                          color: Colors.black.withOpacity(0.7),
                          fontSize: 10,
                          fontFamily: 'Pretendard-Light',
                          letterSpacing: -0.22,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '총 ${_totalMissionCount}개',
                        style: TextStyle(
                          color: Color.fromRGBO(93, 158, 255, 1),
                          fontSize: 14,
                          fontFamily: 'Pretendard-SemiBold',
                          letterSpacing: -0.28,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // 하단 버튼 영역
          // 계좌 연동 여부에 따라 버튼 위젯을 조건부로 렌더링
          _isAccountLinked
              ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 포인트 꺼내기 버튼
                  SizedBox(
                    width: 130,
                    child: GestureDetector(
                      onTap: () {
                        // 계좌가 연동된 경우 - 포인트 꺼내기 화면으로
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => const ChildBankWithdrawalScreen(),
                          ),
                        );
                      },
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            '포인트 꺼내기',
                            style: TextStyle(
                              color: Color.fromRGBO(0, 31, 85, 1),
                              fontSize: 12,
                              fontFamily: 'Pretendard-ExtraLight',
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  // 충전하기 버튼
                  SizedBox(
                    width: 130,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ChargeScreen(),
                          ),
                        ).then((_) {
                          _loadUserInfo();
                        });
                      },
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: Color.fromRGBO(93, 158, 255, 1),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            '충전하기',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontFamily: 'Pretendard-ExtraLight',
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              )
              : GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AccountLinkScreen(),
                    ),
                  ).then((_) {
                    _loadUserInfo();
                  });
                },
                child: Container(
                  width:
                      MediaQuery.of(context).size.width -
                      32, // 화면 너비에서 카드 마진 제외한 값
                  height: 41,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ), // 텍스트 잘림 방지를 위해 패딩 조정
                  decoration: ShapeDecoration(
                    color: const Color(0xFF3A88F4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '계좌 연결하기',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontFamily: 'Pretendard-Light',
                        letterSpacing: -0.28,
                      ),
                    ),
                  ),
                ),
              ),
        ],
      ),
    );
  }

  // 포인트 정보 카드 (별도 박스)
  Widget _buildPointsCard() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 포인트 카드 (상단과 확장 영역 통합)
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Color.fromRGBO(143, 187, 255, 1),
                Color.fromRGBO(112, 169, 255, 1),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 12,
                spreadRadius: 1,
                offset: Offset(0, 6),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 15,
                spreadRadius: 3,
                offset: Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.white.withOpacity(0.15),
                blurRadius: 8,
                spreadRadius: -1,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            children: [
              // 상단 부분 (항상 표시)
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _isPointCardExpanded = !_isPointCardExpanded;
                    });
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // 왼쪽 텍스트 - Expanded로 감싸서 유연하게 만들기
                        Expanded(
                          child: Text(
                            _userInfo?['name']?.isNotEmpty == true
                                ? '${_userInfo!['name']}님의 현재 보유 포인트'
                                : '리뱅님의 현재 보유 포인트',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: _getDynamicFontSize(
                                _userInfo?['name'] ?? '리뱅',
                              ),
                              fontFamily: 'Pretendard-ExtraBold',
                              letterSpacing: -0.32,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),

                        const SizedBox(width: 8), // 간격 추가
                        // 금액 표시 부분
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _userInfo?['point'] != null
                                  ? _formatCurrency(_userInfo!['point'])
                                  : '0',
                              style: TextStyle(
                                color: const Color(0xFF146AFF),
                                fontSize: 14,
                                fontFamily: 'Pretendard-ExtraBold',
                                letterSpacing: -0.80,
                              ),
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '원',
                              style: TextStyle(
                                color: const Color(0xFF146AFF),
                                fontSize: 14,
                                fontFamily: 'Pretendard-ExtraBold',
                                letterSpacing: -0.32,
                              ),
                            ),
                            const SizedBox(width: 4),
                            AnimatedRotation(
                              turns: _isPointCardExpanded ? 0.5 : 0.0,
                              duration: const Duration(milliseconds: 200),
                              child: Icon(
                                Icons.keyboard_arrow_down,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // 확장 영역 (펼쳤을 때만 표시)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: _isPointCardExpanded ? 70 : 0,
                width: double.infinity,
                child:
                    _isPointCardExpanded
                        ? Row(
                          children: [
                            // 현재 보유 포인트
                            Expanded(
                              child: Align(
                                alignment: Alignment.center,
                                child: Text.rich(
                                  TextSpan(
                                    children: [
                                      TextSpan(
                                        text: '현재 보유 포인트\n',
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 12,
                                          fontFamily: 'Pretendard-Regular',
                                        ),
                                      ),
                                      TextSpan(
                                        text:
                                            _userInfo?['point'] != null
                                                ? '${_formatCurrency(_userInfo!['point'])}원'
                                                : '0원',
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 16,
                                          fontFamily: 'Pretendard-Bold',
                                        ),
                                      ),
                                    ],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),

                            // 세로 구분선
                            Container(
                              height: 30,
                              width: 1,
                              color: Colors.black.withOpacity(0.2),
                            ),

                            // 총 누적 포인트
                            Expanded(
                              child: Align(
                                alignment: Alignment.center,
                                child: Text.rich(
                                  TextSpan(
                                    children: [
                                      TextSpan(
                                        text: '총 누적 포인트\n',
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 12,
                                          fontFamily: 'Pretendard-Regular',
                                        ),
                                      ),
                                      TextSpan(
                                        text:
                                            _userInfo?['totalPoint'] != null
                                                ? '${_formatCurrency(_userInfo!['totalPoint'])}원'
                                                : '0원',
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 16,
                                          fontFamily: 'Pretendard-Bold',
                                        ),
                                      ),
                                    ],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ],
                        )
                        : null,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 메뉴 리스트
  Widget _buildMenuList() {
    return Column(
      children: [
        // 첫 번째 섹션 (용돈 내역)
        _buildMenuSection(
          iconAsset: 'assets/icons/my/총적립내역.png',
          title: '용돈 내역',
          items: ['총 포인트 적립 내역', '충전 및 보낸 포인트 내역'],
          titleFontSize: 16.0,
        ),

        const SizedBox(height: 14),

        // 세 번째 섹션 (활동 내역)
        _buildMenuSection(
          iconAsset: 'assets/icons/my/활동내역.png',
          title: '활동 내역',
          items: ['활동 내역', '작성글 내역'],
          titleFontSize: 16.0,
        ),

        const SizedBox(height: 14),

        // 네 번째 섹션 (관리 지원)
        _buildMenuSection(
          iconAsset: 'assets/icons/my/구독권관리.png',
          title: '관리 지원',
          items: ['멤버 관리', '가족 관리', '구독권 관리'],
          titleFontSize: 16.0,
        ),

        const SizedBox(height: 14),

        // 다섯 번째 섹션 (고객 지원)
        _buildMenuSection(
          iconAsset: 'assets/icons/my/고객지원.png',
          title: '고객 지원',
          items: ['공지사항', '친구에게 공유하기', '리틀뱅크혜택', '고객센터'],
          titleFontSize: 16.0,
        ),
      ],
    );
  }

  // 메뉴 섹션 위젯
  Widget _buildMenuSection({
    required String iconAsset,
    required String title,
    required List<String> items,
    required double titleFontSize,
  }) {
    // 현재 섹션의 확장 상태 확인 (기본값은 true - 펼쳐진 상태)
    final bool isExpanded = _expandedSections[title] ?? true;

    // 색상은 모두 동일하게 유지
    const Color titleColor = Color(0xFF8590A3); // 색상 변경
    const Color backgroundColor = Colors.white;
    const Color borderColor = Color(0xFFEEEEEE);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 358,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // 타이틀 부분 - 클릭시 토글 (아이콘 제거)
          GestureDetector(
            onTap: () => _toggleSection(title),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 방식2로 직접 폰트 패밀리 지정
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13.0,
                      fontFamily: 'Pretendard-Light',
                      color: titleColor,
                    ),
                  ),
                  // 화살표 아이콘 변경 (위/아래)
                  AnimatedRotation(
                    turns: isExpanded ? 0.0 : 0.5,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: Color(0xFF999999),
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 구분선
          Container(
            height: 1,
            width: double.infinity,
            margin: EdgeInsets.symmetric(horizontal: 12),
            color: Color(0xFFEEEEEE),
          ),

          // 아이템 리스트 - 확장 상태일 때만 표시
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: SizedBox(
              height: isExpanded ? null : 0, // null이면 자식의 크기에 맞춤, 0이면 숨김
              child:
                  isExpanded
                      ? Column(
                        children:
                            items.asMap().entries.map((entry) {
                              final int index = entry.key;
                              final String item = entry.value;
                              final bool isLast = index == items.length - 1;

                              return Column(
                                children: [
                                  // 메뉴 아이템
                                  _buildMenuItemRow(item, isLast: isLast),

                                  // 다음 아이템이 있으면 구분선 추가
                                  if (!isLast)
                                    Container(
                                      height: 1,
                                      width: double.infinity,
                                      margin: EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ),
                                      color: Color(0xFFEEEEEE),
                                    ),
                                ],
                              );
                            }).toList(),
                      )
                      : SizedBox(),
            ),
          ),

          // 마지막에 약간의 패딩 추가하여 둥근 모서리가 잘 보이도록 함
          if (isExpanded) const SizedBox(height: 8),
        ],
      ),
    );
  }

  // 메뉴 아이템 행
  Widget _buildMenuItemRow(String title, {bool isLast = false}) {
    // 항목별 아이콘 매핑
    String iconAsset = '';
    if (title == '총 포인트 적립 내역') {
      iconAsset = 'assets/icons/my/총적립내역.png';
    } else if (title == '충전 및 보낸 포인트 내역') {
      iconAsset = 'assets/icons/my/충전및이체.png';
    } else if (title == '활동 내역') {
      iconAsset = 'assets/icons/my/활동내역.png';
    } else if (title == '작성글 내역') {
      iconAsset = 'assets/icons/my/작성글내역.png';
    } else if (title == '멤버 관리') {
      iconAsset = 'assets/icons/my/멤버관리.png';
    } else if (title == '가족 관리') {
      iconAsset = 'assets/icons/my/가족멤버관리.png';
    } else if (title == '구독권 관리') {
      iconAsset = 'assets/icons/my/구독권관리.png';
    } else if (title == '공지사항') {
      iconAsset = 'assets/icons/my/공지사항.png';
    } else if (title == '친구에게 공유하기') {
      iconAsset = 'assets/icons/my/초대.png';
    } else if (title == '고객센터') {
      iconAsset = 'assets/icons/my/고객지원.png';
    } else if (title == '리틀뱅크혜택') {
      iconAsset = 'assets/icons/my/리틀뱅크혜택.png';
    }

    // 텍스트 색상 정의
    Color textColor = const Color(0xFF353535);

    return GestureDetector(
      onTap: () {
        // 메뉴 항목에 따라 다른 화면으로 이동
        if (title == '총 포인트 적립 내역') {
          // 총 적립 내역에서 포인트 탭으로 분기
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => const PointHistoryScreen(initialTabIndex: 0),
            ),
          );
        } else if (title == '충전 및 보낸 포인트 내역') {
          // 총 포인트 내역 화면으로 이동 (충전/보낸 포인트 통합)
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => TotalPointHistoryScreen()),
          );
        } else if (title == '활동 내역') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ActivityHistoryScreen(),
            ),
          );
        } else if (title == '작성글 내역') {
          // 작성글 내역 화면으로 이동
          _navigateToPostHistory();
        } else if (title == '멤버 관리') {
          // 멤버 관리 화면으로 이동
          _navigateToFamilyMemberManagement();
        } else if (title == '가족 관리') {
          // 가족 관리 화면으로 이동
          _navigateToFamilyManagement();
        } else if (title == '구독권 관리') {
          // 구독권 관리 화면으로 이동
          _navigateToSubscriptionManagement();
        } else if (title == '리틀뱅크혜택') {
          // 리틀뱅크 혜택 화면으로 이동
          _navigateToLittleBankBenefits();
        } else if (title == '공지사항') {
          // 공지사항 화면으로 이동
          _navigateToNotices();
        } else if (title == '친구에게 공유하기') {
          // 친구에게 공유하기 화면으로 이동
          _navigateToShareWithFriend();
        } else if (title == '고객센터') {
          // 고객센터 화면으로 이동
          _navigateToCustomerService();
        }
      },
      child: Container(
        padding: EdgeInsets.fromLTRB(20, 16, 20, isLast ? 20 : 16),
        color: Colors.white,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                // 항목 아이콘 추가
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Image.asset(iconAsset, width: 20, height: 20),
                ),
                const SizedBox(width: 12),
                // 방식2로 직접 폰트 패밀리 지정하여 표시
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Pretendard-ExtraLight', // 방식2로 직접 지정 (서브 메뉴용)
                    fontSize: 13,
                    color: textColor,
                  ),
                ),
              ],
            ),
            Image.asset(
              'assets/icons/go.png',
              width: 20,
              height: 20,
              errorBuilder: (context, error, stackTrace) => Icon(
                Icons.chevron_right,
                color: const Color(0xFFCCCCCC),
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 작성글 내역 화면으로 이동
  void _navigateToPostHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PostHistoryScreen()),
    );
  }

  // 멤버 관리 화면으로 이동
  void _navigateToFamilyMemberManagement() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MemberManagementScreen()),
    );
  }

  // 가족 관리 화면으로 이동
  void _navigateToFamilyManagement() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FamilyManagementScreen()),
    );
  }

  // 구독권 관리 화면으로 이동
  void _navigateToSubscriptionManagement() async {
    try {
      print('===== 구독권 관리 네비게이션 시작 =====');

      // 현재 활성 구독권 조회 (유료/무료 통합)
      final activeSubscription =
          await SubscriptionService.getCurrentActiveSubscription();

      print('활성 구독권 조회 결과: $activeSubscription');

      if (activeSubscription != null) {
        // 구독권이 있는 경우 (유료 또는 무료) 구독권 관리 화면으로 이동
        final subscriptionType = activeSubscription['type'] as String;
        print('구독권 타입: $subscriptionType, 구독권 관리 화면으로 이동');

        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SubscriptionOnScreen()),
        );
      } else {
        // 구독권이 없는 경우 리틀뱅크혜택 화면으로 이동
        print('활성 구독권이 없음, 리틀뱅크혜택 화면으로 이동');
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const LittleBankBenefitsScreen(),
          ),
        );
      }
    } catch (e) {
      print('구독 정보 조회 오류: $e');
      // 오류 발생시 기본적으로 리틀뱅크혜택 화면으로 이동
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const LittleBankBenefitsScreen(),
        ),
      );
    }
  }

  // 리틀뱅크 혜택 화면으로 이동
  void _navigateToLittleBankBenefits() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LittleBankBenefitsScreen()),
    );
  }

  // 공지사항 화면으로 이동
  void _navigateToNotices() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NoticeScreen()),
    );
  }

  // 친구에게 공유하기 화면으로 이동
  void _navigateToShareWithFriend() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ShareWithFriendScreen()),
    );
  }

  // 고객센터 화면으로 이동
  void _navigateToCustomerService() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CustomerServiceScreen()),
    );
  }

  // 프로필 이미지 콘텐츠를 구성하는 메서드
  Widget _buildProfileImageContent() {
    final String baseUrl = "http://3.34.52.239:8080/"; // 서버 기본 URL
    final String s3BaseUrl =
        "https://littlebank-dev.s3.ap-northeast-2.amazonaws.com/"; // S3 기본 URL

    if (_userInfo?['profileImagePath'] != null &&
        _userInfo!['profileImagePath'].toString().isNotEmpty) {
      final String imagePath = _userInfo!['profileImagePath'].toString();

      // 로컬 asset 이미지인 경우 (assets/로 시작)
      if (imagePath.startsWith('assets/')) {
        return Image.asset(
          imagePath,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            print('Asset 이미지 로드 오류: $error');
            return Icon(Icons.person, color: Colors.white);
          },
        );
      }
      // 기본 이미지인 경우 특별 처리 (한글명 또는 URL 인코딩된 형태)
      else if (imagePath.contains('기본이미지.png') ||
          imagePath.contains('defailt') ||
          imagePath.contains(
            '%E1%84%80%E1%85%B5%E1%84%87%E1%85%A9%E1%86%AB%E1%84%8B%E1%85%B5%E1%84%86%E1%85%B5%E1%84%8C%E1%85%B5.png',
          )) {
        final s3Url = s3BaseUrl + imagePath;
        print('기본 이미지 S3 URL: $s3Url');

        return Image.network(
          s3Url,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return CircularProgressIndicator(
              color: Colors.white,
              value:
                  loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
            );
          },
          errorBuilder: (context, error, stackTrace) {
            print('기본 이미지 로드 오류: $error');
            return Icon(Icons.person, color: Colors.white);
          },
        );
      }
      // 이미 http로 시작하는 완전한 URL인 경우
      else if (imagePath.startsWith('http')) {
        return FutureBuilder<Map<String, String>>(
          future: AuthService.getImageHeaders(),
          builder: (context, snapshot) {
            return CachedNetworkImage(
              imageUrl: imagePath,
              fit: BoxFit.cover,
              httpHeaders: snapshot.data ?? {},
              placeholder:
                  (context, url) =>
                      CircularProgressIndicator(color: Colors.white),
              errorWidget: (context, url, error) {
                print('이미지 로드 오류 (완전 URL): $error');
                return Icon(Icons.person, color: Colors.white);
              },
            );
          },
        );
      }
      // 서버의 상대 경로인 경우 (images/로 시작)
      else if (imagePath.startsWith('images/')) {
        // 직접 S3에서 이미지 가져오기 (서버 우회)
        final s3Url = s3BaseUrl + imagePath;
        print('S3 직접 이미지 URL: $s3Url');

        return Image.network(
          s3Url,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return CircularProgressIndicator(
              color: Colors.white,
              value:
                  loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
            );
          },
          errorBuilder: (context, error, stackTrace) {
            print('S3 이미지 로드 오류: $error');
            return Icon(Icons.person, color: Colors.white);
          },
        );
      }
      // 실제 로컬 파일인 경우 (/ 또는 절대 경로로 시작하는 경우만)
      else if (imagePath.startsWith('/') && File(imagePath).existsSync()) {
        return Image.file(
          File(imagePath),
          fit: BoxFit.cover,
          errorBuilder:
              (context, error, stackTrace) =>
                  Icon(Icons.person, color: Colors.white),
        );
      }
    }

    // 이미지가 없거나 모든 시도가 실패한 경우
    return Icon(Icons.person, color: Colors.white, size: 32);
  }

  // 학교 검색 모달 표시
  void _showSchoolSearchModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return SchoolSearchModal(
          onSchoolSelected: (school) {
            _updateSchoolInfo(school);
          },
          userInfo: _userInfo, // 사용자 정보 전달
        );
      },
    );
  }

  // 학교 정보 등록 모달 체크
  Future<void> _checkAndShowSchoolRegistrationModal() async {
    await Future.delayed(Duration(milliseconds: 1000)); // 화면이 완전히 로드된 후

    if (mounted && (_userInfo?['schoolName']?.isEmpty != false)) {
      _showSchoolRegistrationModal();
    }
  }

  // 학교 정보 등록 모달 표시
  void _showSchoolRegistrationModal() {
    showDialog(
      context: context,
      barrierDismissible: false, // 배경 터치로 닫기 방지
      builder: (BuildContext context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height;
        final isTablet = screenWidth > 600;

        // 화면 크기에 맞춘 모달 크기 계산 (더 안전한 크기)
        final modalWidth =
            isTablet
                ? (screenWidth * 0.65).clamp(300.0, 400.0)
                : (screenWidth * 0.85).clamp(280.0, 350.0);
        final modalHeight =
            isTablet
                ? (screenHeight * 0.5).clamp(280.0, 380.0)
                : (screenHeight * 0.45).clamp(250.0, 320.0);

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 50),
          child: Container(
            width: modalWidth,
            height: modalHeight,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 상단 헤더
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 12,
                    bottom: 6, // 헤더 하단 패딩 축소
                  ),
                  decoration: const ShapeDecoration(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '학교 정보를 등록해 주세요!',
                              style: TextStyle(
                                color: const Color(0xFF202020),
                                fontSize: isTablet ? 18 : 16,
                                fontFamily: 'Pretendard-Bold',
                                letterSpacing: -0.72,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
                            child: Container(
                              width: 20,
                              height: 20,
                              child: const Icon(
                                Icons.close,
                                size: 18,
                                color: Color(0xFF999999),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '학교 정보를 등록하고 친한 친구를 찾아볼까요?',
                        style: TextStyle(
                          color: const Color(0xFF999999),
                          fontSize: isTablet ? 14 : 12,
                          fontFamily: 'Pretendard-Light',
                          letterSpacing: -0.28,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // 이미지 영역 (Flexible로 감싸서 오버플로우 방지)
                Flexible(
                  flex: 3,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                    ), // 이미지 영역 상하 패딩 최소화
                    decoration: const BoxDecoration(color: Colors.white),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: modalWidth * 0.6, // 0.9 → 0.6으로 줄임
                          maxHeight: modalHeight * 0.4, // 0.55 → 0.4로 줄임
                        ),
                        child: Image.asset(
                          'assets/icons/my/school.png',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0F2F7),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.school_outlined,
                                size: 60,
                                color: const Color(0xFF999999),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),

                // 하단 버튼 영역
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(
                    left: 16,
                    right: 16,
                    bottom: 16,
                    top: 8, // 버튼 상단 패딩 축소
                  ),
                  decoration: const ShapeDecoration(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(24),
                        bottomRight: Radius.circular(24),
                      ),
                    ),
                  ),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop();
                      _showSchoolSearchModal();
                    },
                    child: Container(
                      width: double.infinity,
                      height: 48,
                      decoration: ShapeDecoration(
                        color: const Color(0xFF146AFF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '학교 검색하기',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isTablet ? 15 : 14,
                            fontFamily: 'Pretendard-Medium',
                            letterSpacing: -0.28,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 학교 정보 업데이트
  Future<void> _updateSchoolInfo(Map<String, dynamic> school) async {
    try {
      if (mounted) {
        setState(() {
          _isLoading = true;
        });
      }

      // 이미 저장된 학교 정보인지 확인 (중복 API 호출 방지)
      final alreadySaved = school['_alreadySaved'] == true;
      
      if (!alreadySaved) {
        // 서버에 학교 정보 저장
        await AuthService.updateSchoolInfo(
          schoolName: school['schoolName']?.toString() ?? '',
          schoolGubun: school['schoolGubun']?.toString(),
          schoolType: school['schoolType']?.toString(),
          region: school['region']?.toString(),
          address: school['adres']?.toString() ?? school['address']?.toString(),
          estType: school['estType']?.toString(),
        );
        
        print('🏫 학교 정보 API 호출 완료');
      } else {
        print('🏫 이미 저장된 학교 정보로 API 호출 건너뜀');
      }

      // 로컬 상태 업데이트
      if (mounted) {
        setState(() {
          _userInfo?['schoolName'] = school['schoolName'];
          _userInfo?['schoolGubun'] = school['schoolGubun'];
          _userInfo?['schoolType'] = school['schoolType'];
          _userInfo?['region'] = school['region'];
          _userInfo?['address'] = school['adres'] ?? school['address'];
          _userInfo?['estType'] = school['estType'];
          _isLoading = false;
        });

        // 중복 성공 메시지 방지
        if (!alreadySaved) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('학교 정보가 성공적으로 저장되었습니다'),
              backgroundColor: Color(0xFF5D9DFF),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '학교 정보 저장에 실패했습니다: ${e.toString().replaceAll('Exception: ', '')}',
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
      print('학교 정보 업데이트 오류: $e');
    }
  }

  // 기본 프로필 이미지 설정 함수
  Future<void> _setDefaultProfileImage() async {
    try {
      // 로딩 상태 설정
      if (mounted) {
        setState(() {
          _isLoading = true;
        });
      }

      // 서버의 기본 이미지 경로로 API 호출 (URL 인코딩된 형태)
      const String defaultImagePath =
          'images/origin/defailt/%E1%84%80%E1%85%B5%E1%84%87%E1%85%A9%E1%86%AB%E1%84%8B%E1%85%B5%E1%84%86%E1%85%B5%E1%84%8C%E1%85%B5.png';
      print('기본 이미지 설정 시작 - 경로: $defaultImagePath');

      final result = await AuthService.updateUserProfile(defaultImagePath);
      print('기본 이미지 API 호출 결과: $result');

      // 성공 메시지 표시
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('기본 프로필 이미지로 변경되었습니다'),
            duration: Duration(seconds: 2),
          ),
        );

        // 사용자 정보 다시 로드
        await _loadUserInfo();
      }
    } catch (e) {
      // 오류 처리
      if (mounted) {
        setState(() {
          _errorMessage = '기본 프로필 이미지 설정 중 오류가 발생했습니다: $e';
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('기본 프로필 이미지 설정에 실패했습니다'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
      print('기본 프로필 이미지 설정 오류: $e');
    }
  }
}
