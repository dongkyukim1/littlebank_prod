import 'package:flutter/material.dart';
import '../../widgets/mission_card.dart';
import '../../widgets/shared_goal_data.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/mission/shared_challenge_widgets.dart';
import '../../widgets/shared_weekly_goal_widget.dart';
import '../../widgets/common/bottom_navigation_bar.dart';
import '../../services/auth_service.dart';
import '../../widgets/profile_image_upload_dialog.dart';
import 'widgets/challenge_section_widget.dart';
import 'notification_screen.dart';
import 'dart:io';
import 'all_challenges_screen.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

class HomeScreen extends StatefulWidget {
  final String userType;

  const HomeScreen({super.key, this.userType = 'student'});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final int _selectedIndex = 0;
  late String _username;
  late double _allowance;
  bool _isMissionCardExpanded = false;
  bool _isAllowanceCardExpanded = true;
  final bool _isFirstLogin = false;

  // 사용자 정보를 저장할 변수 추가
  Map<String, dynamic>? _userInfo;
  bool _isLoading = true;
  String? _errorMessage;

  // 챌린지 관련 변수 추가
  int _refreshCount = 0; // 새로고침 횟수 (3회로 제한)
  final int _currentChallengeIndex = 0; // 현재 표시되는 챌린지 인덱스

  // 전체 챌린지 목록
  final List<Map<String, dynamic>> _allChallenges = [
    {
      'periodType': '요일별',
      'title': '일주일동안 매일 공부 3시간',
      'participants': '30/40',
      'period': '3.20 - 3.27',
      'time': '매일 3시간',
    },
    {
      'periodType': '과목별',
      'title': '일주일동안 매일 공부',
      'participants': '25/50',
      'period': '3.1 - 3.31',
      'time': '매일 30분',
    },
    {
      'periodType': '주별',
      'title': '아침 6시 기상하기',
      'participants': '45/60',
      'period': '3.15 - 3.22',
      'time': '매일 오전 6시',
    },
    {
      'periodType': '월별',
      'title': '하루 30분 독서하기',
      'participants': '28/35',
      'period': '3.1 - 3.31',
      'time': '매일 30분',
    },
    {
      'periodType': '주별',
      'title': '주 3회 조깅하기',
      'participants': '20/30',
      'period': '3.18 - 3.25',
      'time': '주 3회',
    },
    {
      'periodType': '월별',
      'title': '하루 물 2리터 마시기',
      'participants': '15/30',
      'period': '3.1 - 3.31',
      'time': '매일',
    },
  ];

  // 현재 표시할 챌린지 (랜덤하게 2개 선택)
  List<Map<String, dynamic>> _currentChallenges = [];

  // 주간 목표 데이터 저장 변수 추가
  Map<String, dynamic>? _weeklyGoal;

  final AuthService authService = AuthService();
  File? _selectedImage;
  final bool _isUploading = false;
  String? _profileImagePath;

  @override
  void initState() {
    super.initState();

    // 사용자 정보 로드
    _loadUserInfo();

    // 랜덤하게 챌린지 2개 선택
    _refreshChallenges();

    // 저장된 목표 데이터 로드
    _loadWeeklyGoal();

    // 첫 로그인 여부 확인 (즉시 실행)
    _checkFirstLogin();
  }

  // 사용자 정보 불러오기
  Future<void> _loadUserInfo() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final userInfo = await AuthService.getUserInfo();

      // 사용자 정보 설정
      setState(() {
        _userInfo = userInfo;
        _username = _userInfo?['name'] ?? '사용자';
        _allowance = double.tryParse(_userInfo?['balance']?.toString() ?? '0') ?? 0;
        _profileImagePath = _userInfo?['profileImagePath'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
        
        // 오류 발생 시 기본값 설정
        _username = "리틀뱅크";
        _allowance = 36000;
      });
      print('사용자 정보 로딩 오류: $e');
    }
  }

  // 프로필 이미지 경로 가져오기
  Future<void> _loadProfileImage() async {
    _profileImagePath = await AuthService.getProfileImagePath();
    if (mounted) {
      setState(() {});
    }
  }

  // 첫 로그인 여부를 확인하는 메서드
  Future<void> _checkFirstLogin() async {
    final isFirstLogin = await AuthService.isFirstLogin();
    if (isFirstLogin && mounted) {
      // 프로필 이미지 경로 확인
      final profileImagePath = await AuthService.getProfileImagePath();
      
      // 프로필 이미지가 없는 경우에만 모달 표시
      if (profileImagePath == null || profileImagePath.isEmpty) {
        _showProfileImageModal();
      }
    }
  }

  // 프로필 이미지 등록 모달 표시
  void _showProfileImageModal() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ProfileImageUploadDialog(
        onCompleted: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('프로필 이미지가 설정되었습니다'),
              duration: Duration(seconds: 2),
            ),
          );
        },
      ),
    );
  }

  // 새로운 챌린지를 랜덤하게 선택하는 메서드
  void _refreshChallenges() {
    // _allChallenges를 복사하고 섞어서 랜덤한 순서로 만듦
    final List<Map<String, dynamic>> shuffled = List.from(_allChallenges)
      ..shuffle();

    // 첫 2개 아이템 선택
    setState(() {
      _currentChallenges = shuffled.take(2).toList();
    });
  }

  // 목표 데이터를 로드하는 메서드
  void _loadWeeklyGoal() {
    // 공유 데이터에서 목표 정보 로드
    if (SharedGoalData.weeklyGoal != null) {
      setState(() {
        _weeklyGoal = SharedGoalData.weeklyGoal;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE7ECF6),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(50.0),
        child: AppBar(
          backgroundColor: const Color(0xFFE7ECF6),
          elevation: 0,
          centerTitle: false,
          title: Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: Image.asset(
              'assets/images/app_logo.png',
              fit: BoxFit.contain,
              height: 32,
            ),
          ),
          titleSpacing: 0,
          leading: null,
          automaticallyImplyLeading: false,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: GestureDetector(
                onTap: () {
                  // 마이페이지로 이동하기
                  Navigator.pushNamed(context, '/my-page');
                },
                child: CircleAvatar(
                  backgroundColor: Colors.grey[300],
                  radius: 14,
                  child: _profileImagePath != null && _profileImagePath!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: CachedNetworkImage(
                          imageUrl: AuthService.getFullProfileImageUrl(_profileImagePath!),
                          fit: BoxFit.cover,
                          width: 28,
                          height: 28,
                          placeholder: (context, url) => CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                          errorWidget: (context, url, error) => Icon(
                            Icons.person,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      )
                    : Icon(Icons.person, size: 14, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: Image.asset(
                'assets/icons/Icon/알림/Regular.png',
                width: 22,
                height: 22,
                color: Colors.black,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationScreen(),
                  ),
                );
              },
            ),
            const SizedBox(width: 16),
          ],
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '오류가 발생했습니다',
                        style: AppTheme.body2.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        _errorMessage!,
                        style: AppTheme.body5,
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadUserInfo,
                        child: Text('다시 시도', style: AppTheme.body1),
                      ),
                    ],
                  ),
                )
              : _buildHomeTab(),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 미션 카드
          MissionCard(
            onExpandChanged: (isExpanded) {
              setState(() {
                _isMissionCardExpanded = isExpanded;
              });
            },
          ),

          // 하단 네비게이션 바
          const CommonBottomNavigationBar(selectedIndex: 0),
        ],
      ),
    );
  }

  Widget _buildHomeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAllowanceCard(),
          const SizedBox(height: 16),
          
          // 첫 번째 페이지 인디케이터 추가
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: ShapeDecoration(
                    color: const Color(0xFF5D9EFF),
                    shape: OvalBorder(),
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  width: 6,
                  height: 6,
                  decoration: ShapeDecoration(
                    color: const Color(0xFFDDDDDD),
                    shape: OvalBorder(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          _buildTopUsersCard(),
          const SizedBox(height: 16),
          _buildWeeklyGoalSection(),
          const SizedBox(height: 16),
          
          // 두 번째 페이지 인디케이터 추가
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: ShapeDecoration(
                    color: const Color(0xFF5D9EFF),
                    shape: OvalBorder(),
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  width: 6,
                  height: 6,
                  decoration: ShapeDecoration(
                    color: const Color(0xFFDDDDDD),
                    shape: OvalBorder(),
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  width: 6,
                  height: 6,
                  decoration: ShapeDecoration(
                    color: const Color(0xFFDDDDDD),
                    shape: OvalBorder(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          _buildChallengeSection(),
          const SizedBox(height: 70), // 하단에 여백 추가
        ],
      ),
    );
  }

  Widget _buildAllowanceCard() {
    // 미션 데이터 목록
    final List<Map<String, dynamic>> missions = [
      {'title': '3시간 동안 수학 공부', 'badge': '가족 미션', 'amount': '53,000'},
      {'title': '영어 단어 100개 암기', 'badge': '학원 미션', 'amount': '142,000'},
      {'title': '영어 단어 100개 암기', 'badge': '학원 미션', 'amount': '41,000'},
    ];

    // 사용자 이름과 적립금 정보 (API에서 가져온 데이터 사용)
    final userName = _userInfo?['name'] ?? '장태현';
    final formattedBalance = _userInfo?['balance'] != null 
        ? NumberFormat('#,###').format(double.tryParse(_userInfo!['balance'].toString()) ?? 0)
        : '113,000';

    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: () {
                setState(() {
                  _isAllowanceCardExpanded = !_isAllowanceCardExpanded;
                });
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      '${userName}님이 현재 보유 중인 적립금',
                      style: AppTheme.subTitle2.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    _isAllowanceCardExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.grey[600],
                    size: 22,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${formattedBalance}원',
              style: AppTheme.title2.copyWith(
                color: const Color(0xFF146AFF),
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            
            if (_isAllowanceCardExpanded) ...[
              const SizedBox(height: 12),
              // 계좌 연결/내역 보기 버튼
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 70,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF5FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF5D9EFF),
                          width: 1,
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {},
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '계좌 연결',
                                      style: AppTheme.body2.copyWith(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(width: 2),
                                    Icon(
                                      Icons.chevron_right,
                                      color: Colors.grey,
                                      size: 14,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  alignment: Alignment.center,
                                  width: double.infinity,
                                  child: Text(
                                    '충전 계좌를\n연결하고 이체해 봐요',
                                    style: AppTheme.body7.copyWith(
                                      height: 1.1,
                                      letterSpacing: -0.2,
                                      fontSize: 9,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w200,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.left,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      height: 70,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF5FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF5D9EFF),
                          width: 1,
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {},
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '내역 보기',
                                      style: AppTheme.body2.copyWith(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(width: 2),
                                    Icon(
                                      Icons.chevron_right,
                                      color: Colors.grey,
                                      size: 14,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  alignment: Alignment.center,
                                  width: double.infinity,
                                  child: Text(
                                    '최근 입출금 내역을\n쉽게 확인해 봐요',
                                    style: AppTheme.body7.copyWith(
                                      height: 1.1,
                                      letterSpacing: -0.2,
                                      fontSize: 9,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w200,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.left,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // 미션 금액 정보
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '진행 중인 미션으로 ',
                          style: AppTheme.body6.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        TextSpan(
                          text: '총 246,000원',
                          style: AppTheme.body2.copyWith(
                            color: const Color(0xFF001F55),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        TextSpan(
                          text: '을 얻을 수 있어요!',
                          style: AppTheme.body6.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.left,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '오후 13:00 기준',
                    style: AppTheme.body7.copyWith(
                      color: const Color(0xFFCCCCCC),
                      fontSize: 10,
                    ),
                    textAlign: TextAlign.left,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // 미션 목록
              ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: missions.length,
                separatorBuilder:
                    (context, index) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF5D9EFF),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            missions[index]['badge'],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            missions[index]['title'],
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          height: 20,
                          width: 1,
                          color: Colors.grey[300],
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: missions[index]['amount'],
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF146AFF),
                                ),
                              ),
                              TextSpan(
                                text: '원',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTopUsersCard() {
    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '내 주위 리뱅인 TOP 5',
              style: AppTheme.subTitle2.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF353535),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '이번 주 가장 많은 달성률을 올린 순입니다',
              style: AppTheme.body5.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF73777F),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                CircleAvatar(backgroundColor: Colors.yellow[200], radius: 28),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD27F),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'n개째 미션 달성 중',
                          style: AppTheme.caption2.copyWith(
                            color: AppColors.secondaryColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            'assets/images/Polygon 2.png',
                            width: 12,
                            height: 12,
                            color: Colors.red,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '1',
                            style: AppTheme.subTitle1.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              '강뱅뱅',
                              style: AppTheme.subTitle1.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyGoalSection() {
    return SharedWeeklyGoalWidget(
      weeklyGoal: _weeklyGoal,
      onGoalUpdated: (goal) {
        setState(() {
          _weeklyGoal = goal;
          // 상태를 저장합니다 (앱 재시작 시에도 유지되도록)
          SharedGoalData.weeklyGoal = goal;
        });
      },
      usePretendard: true,
    );
  }

  Widget _buildChallengeSection() {
    return ChallengeSectionWidget(challenges: _allChallenges);
  }
}
