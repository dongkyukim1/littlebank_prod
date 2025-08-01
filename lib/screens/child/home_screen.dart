import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:visibility_detector/visibility_detector.dart';
import '../../widgets/shared_goal_data.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_weekly_goal_widget.dart';
import '../../widgets/common/bottom_navigation_bar.dart';
import '../../services/auth_service.dart';
import '../../services/challenge_service.dart';
import '../../services/notification_service.dart' as notification;
import '../../services/payment_service.dart';
import '../../services/game_service.dart';
import '../../services/goal_service.dart';
import '../../services/mission_service.dart';
import '../../widgets/balance_game_card.dart';
import '../../widgets/profile_image_upload_dialog.dart';
import 'widgets/challenge_section_widget.dart';
import 'notification_screen.dart';
import 'my/activity_history_screen.dart';
import 'dart:io';
import 'dart:math' as math;
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'challenge/challenge_detail_screen.dart';
import 'my/total_point_history_screen.dart';
import 'bank/charge_screen.dart';
import 'bank/account_link_screen.dart';
import '../notice_kid/notice_kid.dart';
import '../notice_kid/child_screen_wrapper.dart';
import '../notice_kid/notification_service.dart';
import 'notice_modal/none_goal_modal.dart';
import 'goal_setting_screen.dart';
import './notice_modal/gift_subscription_modal.dart';
import './notice_modal/analysis_report_modal.dart';
import './notice_modal/mission_complete_modal.dart';
import './notice_modal/mission_reward_approved_modal.dart';
import '../common/splash/splash_wrapper.dart';
import '../common/splash/splash_debug_helper.dart';
import '../../services/global_notification_service.dart';

class HomeScreen extends StatefulWidget {
  final String userType;

  const HomeScreen({super.key, this.userType = 'student'});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final int _selectedIndex = 0;
  late String _username;
  late double _allowance;
  bool _isMissionCardExpanded = false;
  bool _isAllowanceCardExpanded = true;
  final bool _isFirstLogin = false;

  // 슬라이드 카드 관련
  final PageController _pageController = PageController();
  int _currentPageIndex = 0;

  Map<String, dynamic>? _userInfo;
  bool _isLoadingUserInfo = true;
  String? _userInfoError;

  List<Map<String, dynamic>> _allChallenges = [];
  bool _isLoadingChallenges = true;
  String? _challengeError;
  List<Map<String, dynamic>> _currentChallenges = [];

  Map<String, dynamic>? _weeklyGoal;

  int _inProgressChallengeCount = 0;
  int _finishedChallengeCount = 0;
  int _totalChallengeCount = 0;
  bool _isLoadingChallengeCount = false;

  int _totalGoalCount = 0;
  bool _isLoadingGoalCount = false;

  int _totalMissionCount = 0;
  bool _isLoadingMissionCount = false;

  List<Map<String, dynamic>> _balanceGames = [];
  bool _isLoadingGames = true;
  String? _gameError;

  final AuthService authService = AuthService();
  File? _selectedImage;
  final bool _isUploading = false;
  String? _profileImagePath;

  // 밸런스 게임 자동 뒤집기 관련
  bool _hasBalanceGameVisible = false;

  // 미션 관련 데이터 추가
  List<MissionResponse> _inProgressMissions = [];
  bool _isLoadingMissions = false;
  String? _missionError;
  int _pendingReward = 0;

  // 알림 관련 변수들
  int _unreadNotificationCount = 0;
  bool _isLoadingNotifications = false;



  @override
  void initState() {
    super.initState();
    // 시스템 UI 오버레이 설정 (하단 네비게이션 바 숨기기)
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
    );

    // 🔔 앱 시작 시 알림 폴링 시작 (한 번만 실행) - 임시로 중지
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   final notificationService = NotificationService();
    //   notificationService.startNotificationPolling();
    //   print('🏠 홈화면에서 알림 폴링 시작');
    // });

    _loadAllData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    await _loadUserInfo();
    await _loadChallenges();
    await _loadChallengeCount();
    await _loadGoalCount();
    await _loadMissionCount();
    await _loadMissionData();
    _loadWeeklyGoal();
    await _loadBalanceGames();
    await _loadUnreadNotificationCount();
    _checkFirstLogin();
    
    // 알림 확인은 ChildScreenWrapper에서 전역적으로 처리됨
  }

  // 안읽은 알림 개수 로드
  Future<void> _loadUnreadNotificationCount() async {
    if (!mounted) return;
    
    setState(() {
      _isLoadingNotifications = true;
    });

    try {
      final count = await notification.NotificationService.getUnreadNotificationCount();
      if (mounted) {
        setState(() {
          _unreadNotificationCount = count;
          _isLoadingNotifications = false;
        });
      }
    } catch (e) {
      print('안읽은 알림 개수 로드 중 오류: $e');
      if (mounted) {
        setState(() {
          _unreadNotificationCount = 0;
          _isLoadingNotifications = false;
        });
      }
    }
  }

  Future<void> _loadBalanceGames() async {
    try {
      if (mounted) {
        setState(() {
          _isLoadingGames = true;
          _gameError = null;
        });
      }
      final games = await GameService.getGames();
      if (mounted) {
        setState(() {
          _balanceGames = games;
          _isLoadingGames = false;
          _hasBalanceGameVisible = false; // 새 게임 로드 시 visibility 상태 리셋
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingGames = false;
          _gameError = '밸런스 게임 정보를 가져오는데 실패했습니다.';
        });
      }
      print('밸런스 게임 로딩 오류: $e');
    }
  }

  Future<void> _handleGameVote(int gameId, String choice) async {
    try {
      final result = await GameService.voteGame(gameId, choice);

      // 투표 후 밸런스 게임 데이터 새로고침
      await _loadBalanceGames();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '투표 완료! 나의 선택: $choice',
            style: TextStyle(fontFamily: 'Pretendard-Medium'),
          ),
          backgroundColor: Color(0xFF146AFF),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('투표 실패: ${e.toString().replaceAll("Exception: ", "")}'),
          backgroundColor: Colors.red,
        ),
      );
      print('게임 투표 오류: $e');
    }
  }

  Future<void> _loadUserInfo() async {
    try {
      if (mounted) {
        setState(() {
          _isLoadingUserInfo = true;
          _userInfoError = null;
        });
      }

      final userInfo = await AuthService.getUserInfo();

      // API 응답에 point 필드가 포함되어 있으므로 별도 조회 불필요
      final points = userInfo['point'] ?? 0;

      if (mounted) {
        setState(() {
          _userInfo = userInfo;
          _username = _userInfo?['name'] ?? '사용자';
          _allowance = points.toDouble();
          _profileImagePath = _userInfo?['profileImagePath'];
          _isLoadingUserInfo = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _userInfoError = e.toString();
          _isLoadingUserInfo = false;
          _username = "사용자";
          _allowance = 0;
        });
      }
      print('홈화면 사용자 정보 로딩 오류: $e');
    }
  }

  Future<void> _loadChallenges() async {
    try {
      if (mounted) {
        setState(() {
          _isLoadingChallenges = true;
          _challengeError = null;
        });
      }

      final challengeResponse = await ChallengeService.getChallenges();
      final challenges = challengeResponse.data;

      if (challenges.isEmpty) {
        if (mounted) {
          setState(() {
            _isLoadingChallenges = false;
            _allChallenges = [];
            _currentChallenges = [];
          });
        }
        return;
      }

      final formattedChallenges =
          challenges.map((challenge) {
            String periodType = '전체';
            if (challenge.category == 'WEEK') periodType = '요일별';
            if (challenge.category == 'SUBJECT') periodType = '과목별';

            // 시작 날짜와 종료 날짜를 형식화 - ISO 8601 형식에서 날짜 부분만 추출
            String startDateOnly = challenge.startDate.split('T')[0];
            String endDateOnly = challenge.endDate.split('T')[0];

            String startMonth = startDateOnly
                .split('-')[1]
                .replaceFirst(RegExp('^0'), '');
            String startDay = startDateOnly
                .split('-')[2]
                .replaceFirst(RegExp('^0'), '');
            String endMonth = endDateOnly
                .split('-')[1]
                .replaceFirst(RegExp('^0'), '');
            String endDay = endDateOnly
                .split('-')[2]
                .replaceFirst(RegExp('^0'), '');
            String period = '$startMonth.$startDay - $endMonth.$endDay';

            return {
              'id': challenge.id,
              'periodType': periodType,
              'title': challenge.title,
              'participants':
                  '${challenge.currentParticipants}/${challenge.totalParticipants}',
              'period': period,
              'time': '매일 ${challenge.totalStudyTime}시간',
            };
          }).toList();

      if (mounted) {
        setState(() {
          _allChallenges = formattedChallenges;
          _isLoadingChallenges = false;
          _refreshChallenges();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingChallenges = false;
          _challengeError = '챌린지 데이터를 불러오는 중 오류가 발생했습니다.';
        });
      }
      print('챌린지 데이터 로딩 오류: $e');
    }
  }

  Future<void> _checkFirstLogin() async {
    final isFirstLogin = await AuthService.isFirstLogin();
    if (isFirstLogin && mounted) {
      final profileImagePath = await AuthService.getProfileImagePath();
      if (profileImagePath == null || profileImagePath.isEmpty) {
        _showProfileImageModal();
      }
    }
  }

  void _showProfileImageModal() {
    ProfileImageUploadDialog.show(context).then((selectedImage) {
      if (selectedImage != null) {
        // 이미지가 선택되었을 때
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('프로필 이미지가 설정되었습니다'),
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        // 기본 프로필이 선택되었거나 다음에 하기를 선택했을 때
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('프로필 설정이 완료되었습니다'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      _loadUserInfo();
    });
  }

  void _refreshChallenges() {
    if (_allChallenges.isEmpty) return;
    final List<Map<String, dynamic>> shuffled = List.from(_allChallenges)
      ..shuffle();
    if (mounted) {
      setState(() {
        _currentChallenges = shuffled; // 전체 챌린지를 가로 슬라이드로 표시
      });
    }
  }

  // 목표 없음 모달 표시
  void _showNoneGoalModal() {
    if (!mounted) return;

    NoneGoalModal.show(context)
        .then((result) {
          if (result == true) {
            // 목표 설정하기 버튼을 눌렀을 때
            print('🎯 목표 설정 화면으로 이동');
            _navigateToGoalSetting();
          } else {
            // 나중에 하기 버튼을 눌렀을 때
            print('⏰ 목표 설정을 나중에 하기로 함');
            // 특별한 처리 없이 모달만 닫기
          }
        })
        .catchError((error) {
          print('목표 없음 모달 오류: $error');
        });
  }

  // 목표 설정 화면으로 이동
  void _navigateToGoalSetting() async {
    try {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const GoalSettingScreen()),
      );

      // 목표 설정이 완료되었을 때
      if (result != null) {
        // 목표 데이터 다시 로드
        await _loadGoalCount();
        _loadWeeklyGoal();

        // 성공 메시지 표시
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('목표가 성공적으로 설정되었습니다!'),
              duration: Duration(seconds: 2),
              backgroundColor: Color(0xFF5D9EFF),
            ),
          );
        }
      }
    } catch (e) {
      // 오류 처리
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('목표 설정 중 오류가 발생했습니다: ${e.toString()}'),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
      }
      print('목표 설정 네비게이션 오류: $e');
    }
  }

  void _loadWeeklyGoal() {
    if (SharedGoalData.weeklyGoal != null) {
      if (mounted) {
        setState(() {
          _weeklyGoal = SharedGoalData.weeklyGoal;
        });
      }
    }
  }

  Future<void> _loadChallengeCount() async {
    try {
      if (mounted) {
        setState(() => _isLoadingChallengeCount = true);
      }
      final inProgressResponse = await ChallengeService.getMyChallenges(
        challengeStatus: ChallengeStatus.ONGOING,
        page: 0,
      );
      final finishedResponse = await ChallengeService.getMyChallenges(
        challengeStatus: ChallengeStatus.COMPLETED,
        page: 0,
      );
      if (mounted) {
        setState(() {
          _inProgressChallengeCount = inProgressResponse.data.length;
          _finishedChallengeCount = finishedResponse.data.length;
          _totalChallengeCount =
              _inProgressChallengeCount + _finishedChallengeCount;
          _isLoadingChallengeCount = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingChallengeCount = false;
          _totalChallengeCount = 0;
        });
      }
      print('챌린지 개수 로딩 오류: $e');
    }
  }

  Future<void> _loadGoalCount() async {
    try {
      if (mounted) {
        setState(() => _isLoadingGoalCount = true);
      }

      final weeklyGoals = await GoalService.getChildWeeklyGoals();

      if (weeklyGoals != null) {
        print('===== 목표 개수 확인 =====');
        print('전체 목표 개수: ${weeklyGoals.length}');

        // 각 목표의 상태를 확인
        for (var goal in weeklyGoals) {
          print('목표: ${goal['title']}, 상태: ${goal['status']}');
        }

        // 승인된 목표와 달성한 목표만 참여한 목표로 계산
        final participatedGoals =
            weeklyGoals
                .where(
                  (goal) =>
                      goal['status'] == 'ACCEPT' ||
                      goal['status'] == 'ACHIEVEMENT',
                )
                .toList();

        print('참여한 목표 개수: ${participatedGoals.length}');
        print('=========================');

        if (mounted) {
          setState(() {
            _totalGoalCount = participatedGoals.length;
            _isLoadingGoalCount = false;
          });
        }

        // 🎯 목표가 없을 때 모달 표시
        if (weeklyGoals.isEmpty && mounted) {
          // 잠시 후에 모달 표시 (UI가 완전히 로드된 후)
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showNoneGoalModal();
          });
        }
      } else {
        print('주간 목표 데이터가 null입니다.');
        if (mounted) {
          setState(() {
            _totalGoalCount = 0;
            _isLoadingGoalCount = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingGoalCount = false;
          _totalGoalCount = 0;
        });
      }
      print('목표 개수 로딩 오류: $e');
    }
  }

  Future<void> _loadMissionCount() async {
    try {
      if (mounted) {
        setState(() => _isLoadingMissionCount = true);
      }

      final missionResponse = await MissionService.getChildMissions(page: 0);

      if (missionResponse != null) {
        print('===== 미션 개수 확인 =====');
        print('전체 미션 개수: ${missionResponse['totalElement']}');

        final missions = missionResponse['data'] as List<dynamic>;

        // 각 미션의 상태를 확인
        for (var missionData in missions) {
          print('미션: ${missionData['title']}, 상태: ${missionData['status']}');
        }

        // 승인된 미션과 달성한 미션만 참여한 미션으로 계산
        final participatedMissions =
            missions
                .where(
                  (mission) =>
                      mission['status'] == 'ACCEPT' ||
                      mission['status'] == 'ACHIEVEMENT',
                )
                .toList();

        print('참여한 미션 개수: ${participatedMissions.length}');
        print('=========================');

        if (mounted) {
          setState(() {
            _totalMissionCount = participatedMissions.length;
            _isLoadingMissionCount = false;
          });
        }
      } else {
        print('미션 데이터가 null입니다.');
        if (mounted) {
          setState(() {
            _totalMissionCount = 0;
            _isLoadingMissionCount = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingMissionCount = false;
          _totalMissionCount = 0;
        });
      }
      print('미션 개수 로딩 오류: $e');
    }
  }

  // 진행 중인 미션 데이터 로드
  Future<void> _loadMissionData() async {
    try {
      setState(() {
        _isLoadingMissions = true;
        _missionError = null;
      });

      print('🎯 진행 중인 미션 데이터 로드 시작');

      final missionsData = await MissionService.getChildMissions(page: 0);

      if (missionsData != null && missionsData['data'] != null) {
        final List<dynamic> missionList = missionsData['data'];

        // 미션 응답 객체로 변환하고 진행 중인 미션만 필터링
        final List<MissionResponse> allMissions =
            missionList
                .map((missionJson) => MissionResponse.fromJson(missionJson))
                .toList();

        // 진행 중인 미션 (ACCEPT 상태)만 필터링
        final inProgressMissions =
            allMissions
                .where((mission) => mission.status == MissionStatus.ACCEPT)
                .toList();

        // 최신순으로 정렬 (시작일 기준)
        inProgressMissions.sort((a, b) => b.startDate.compareTo(a.startDate));

        // 대기 중인 보상금 계산 (전체 미션 기준)
        final pendingReward = inProgressMissions.fold<int>(
          0,
          (sum, mission) => sum + mission.reward,
        );

        // 홈 화면에서는 최신순으로 3개만 표시
        final displayMissions = inProgressMissions.take(3).toList();

        setState(() {
          _inProgressMissions = displayMissions;
          _pendingReward = pendingReward;
          _isLoadingMissions = false;
        });

        print(
          '🎯 미션 데이터 로드 완료 - 전체: ${allMissions.length}개, 진행 중: ${inProgressMissions.length}개, 대기 보상: ${pendingReward}원',
        );
      } else {
        print('🎯 미션 데이터가 없습니다.');
        setState(() {
          _inProgressMissions = [];
          _pendingReward = 0;
          _isLoadingMissions = false;
        });
      }
    } catch (e) {
      print('🎯 미션 데이터 로드 실패: $e');
      setState(() {
        _missionError = '미션 정보를 불러오는데 실패했습니다.';
        _inProgressMissions = [];
        _pendingReward = 0;
        _isLoadingMissions = false;
      });
    }
  }

  EdgeInsets _getResponsivePadding(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > 600) {
      final horizontalPadding = screenWidth * 0.1;
      return EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: 16.0,
      );
    }
    return const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0);
  }

  double _getResponsiveFontSize(BuildContext context, double baseSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > 600) return baseSize * 1.2;
    if (screenWidth < 360) return baseSize * 0.9;
    return baseSize;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return ChildScreenWrapper(
      child: Scaffold(
        backgroundColor: const Color(0xFFE7ECF6),
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(isTablet ? 60.0 : 50.0),
          child: AppBar(
            backgroundColor: const Color(0xFFE7ECF6),
            elevation: 0,
            centerTitle: false,
            title: Padding(
              padding: EdgeInsets.only(left: isTablet ? 24.0 : 16.0),
              child: Image.asset(
                'assets/images/app_logo.png',
                fit: BoxFit.contain,
                height: isTablet ? 40 : 32,
              ),
            ),
            titleSpacing: 0,
            leading: null,
            automaticallyImplyLeading: false,
            actions: [
              Padding(
                padding: EdgeInsets.only(right: isTablet ? 12.0 : 8.0),
                child: GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/my-page'),
                  child: CircleAvatar(
                    backgroundColor: Colors.grey[300],
                    radius: isTablet ? 18 : 14,
                    child:
                        _profileImagePath != null &&
                                _profileImagePath!.isNotEmpty
                            ? ClipRRect(
                              borderRadius: BorderRadius.circular(
                                isTablet ? 18 : 14,
                              ),
                              child: CachedNetworkImage(
                                imageUrl: AuthService.getFullProfileImageUrl(
                                  _profileImagePath!,
                                ),
                                fit: BoxFit.cover,
                                width: isTablet ? 36 : 28,
                                height: isTablet ? 36 : 28,
                                placeholder:
                                    (context, url) => CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                errorWidget:
                                    (context, url, error) => Icon(
                                      Icons.person,
                                      size: isTablet ? 18 : 14,
                                      color: Colors.white,
                                    ),
                              ),
                            )
                            : Icon(
                              Icons.person,
                              size: isTablet ? 18 : 14,
                              color: Colors.white,
                            ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationScreen(),
                  ),
                ),
                child: Container(
                  width: isTablet ? 32 : 28,
                  height: isTablet ? 32 : 28,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Center(
                        child: Image.asset(
                          'assets/icons/Icon/알림/Regular.png',
                          width: isTablet ? 28 : 22,
                          height: isTablet ? 28 : 22,
                          color: Colors.black,
                        ),
                      ),
                      // 알림 배지
                      if (_unreadNotificationCount > 0)
                        Positioned(
                          right: 1,
                          top: -3,
                          child: Container(
                            width: 22,
                            height: 15,
                            decoration: BoxDecoration(
                              color: Color(0xFF11CB86),
                              borderRadius: BorderRadius.all(Radius.elliptical(7, 4)),
                            ),
                            child: Center(
                              child: Text(
                                notification.NotificationService.formatUnreadCount(_unreadNotificationCount),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontFamily: 'Pretendard-Bold',
                                  height: 1.0,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: isTablet ? 24 : 16),
            ],
          ),
        ),
        body:
            _isLoadingUserInfo ||
                    _isLoadingChallenges ||
                    _isLoadingGames ||
                    _isLoadingMissions
                ? Center(child: CircularProgressIndicator())
                : _userInfoError != null ||
                    _challengeError != null ||
                    _gameError != null ||
                    _missionError != null
                ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '오류가 발생했습니다',
                        style: AppTheme.body2.copyWith(
                          fontSize: _getResponsiveFontSize(context, 16),
                          fontFamily: 'Pretendard-Bold',
                          color: Colors.red,
                        ),
                      ),
                      SizedBox(height: 8),
                      if (_userInfoError != null)
                        Text(
                          _userInfoError!,
                          style: AppTheme.body5,
                          textAlign: TextAlign.center,
                        ),
                      if (_challengeError != null)
                        Text(
                          _challengeError!,
                          style: AppTheme.body5,
                          textAlign: TextAlign.center,
                        ),
                      if (_gameError != null)
                        Text(
                          _gameError!,
                          style: AppTheme.body5,
                          textAlign: TextAlign.center,
                        ),
                      if (_missionError != null)
                        Text(
                          _missionError!,
                          style: AppTheme.body5,
                          textAlign: TextAlign.center,
                        ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadAllData,
                        child: Text('다시 시도', style: AppTheme.body1),
                      ),
                    ],
                  ),
                )
                : _buildHomeTab(),

        bottomNavigationBar: const CommonBottomNavigationBar(selectedIndex: 0),
      ),
    );
  }

  Widget _buildHomeTab() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isDesktop = screenWidth > 1200;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: _getResponsivePadding(context),
          child:
              isDesktop
                  ? _buildDesktopLayout()
                  : isTablet
                  ? _buildTabletLayout()
                  : _buildMobileLayout(),
        );
      },
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAllowanceCard(),
        const SizedBox(height: 20),
        _buildTopUsersCard(),
        const SizedBox(height: 24),
        _buildChallengeSection(),
        const SizedBox(height: 28),
        _buildBalanceGameSection(),
        const SizedBox(height: 60),
      ],
    );
  }

  Widget _buildTabletLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAllowanceCard(),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 1, child: _buildTopUsersCard()),
            const SizedBox(width: 24),
            Expanded(flex: 1, child: _buildChallengeSection()),
          ],
        ),
        const SizedBox(height: 32),
        _buildBalanceGameSection(),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 2, child: _buildAllowanceCard()),
            const SizedBox(width: 28),
            Expanded(flex: 1, child: _buildTopUsersCard()),
          ],
        ),
        const SizedBox(height: 28),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 1, child: _buildChallengeSection()),
            const SizedBox(width: 28),
            Expanded(flex: 1, child: _buildBalanceGameSection()),
          ],
        ),
        const SizedBox(height: 90),
      ],
    );
  }

  Widget _buildAllowanceCard() {
    return _buildCurrentPointsCard();
  }

  // 현재 보유 포인트 카드 (첫 번째 페이지)
  Widget _buildCurrentPointsCard() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final userName = _userInfo?['name'] ?? '사용자';
    final formattedBalance =
        _userInfo?['point'] != null
            ? NumberFormat('#,###').format(_userInfo!['point'])
            : '0';
    final formattedPendingReward =
        _pendingReward > 0 ? NumberFormat('#,###').format(_pendingReward) : '0';

    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 24.0 : 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap:
                  () => setState(
                    () => _isAllowanceCardExpanded = !_isAllowanceCardExpanded,
                  ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      '$userName님이 현재 보유 중인 포인트',
                      style: AppTheme.subTitle2.copyWith(
                        fontSize: _getResponsiveFontSize(context, 16),
                        fontFamily: 'Pretendard-Medium',
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    _isAllowanceCardExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.grey[600],
                    size: isTablet ? 26 : 22,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '$formattedBalance원',
              style: AppTheme.title2.copyWith(
                color: const Color(0xFF146AFF),
                fontSize: _getResponsiveFontSize(context, 22),
                fontFamily: 'Pretendard-Bold',
              ),
            ),
            if (_isAllowanceCardExpanded) ...[
              SizedBox(height: isTablet ? 16 : 12),
              _buildAccountSection(),
              SizedBox(height: isTablet ? 16 : 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '진행 중인 미션으로 ',
                          style: AppTheme.body6.copyWith(
                            fontSize: _getResponsiveFontSize(context, 12),
                            fontFamily: 'Pretendard-Regular',
                          ),
                        ),
                        TextSpan(
                          text: '총 $formattedPendingReward원',
                          style: AppTheme.body2.copyWith(
                            color: const Color(0xFF001F55),
                            fontSize: _getResponsiveFontSize(context, 12),
                            fontFamily: 'Pretendard-SemiBold',
                          ),
                        ),
                        TextSpan(
                          text: '을 얻을 수 있어요!',
                          style: AppTheme.body6.copyWith(
                            fontSize: _getResponsiveFontSize(context, 12),
                            fontFamily: 'Pretendard-Regular',
                          ),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.left,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')} ',
                    style: AppTheme.body7.copyWith(
                      color: const Color(0xFFCCCCCC),
                      fontSize: _getResponsiveFontSize(context, 10),
                      fontFamily: 'Pretendard-Regular',
                    ),
                    textAlign: TextAlign.left,
                  ),
                ],
              ),
              SizedBox(height: isTablet ? 16 : 12),
              _buildMissionContainer(isTablet),
            ],
          ],
        ),
      ),
    );
  }

  // 월간 미션 리스트 (실제 완료된 미션만 표시)
  Widget _buildMonthlyMissionList(bool isTablet) {
    // 미션이 없으면 빈 상태 표시
    return Container(
      padding: EdgeInsets.all(isTablet ? 24 : 16),
      child: Center(
        child: Text(
          '이번 달 완료한 미션이 없습니다.',
          style: TextStyle(
            color: const Color(0xFF999999),
            fontSize: _getResponsiveFontSize(context, 12),
            fontFamily: 'Pretendard-Light',
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  // 계좌 정보 유무 확인
  bool _checkHasAccountInfo() {
    if (_userInfo == null) return false;

    // 계좌 정보 필드들이 모두 존재하고 비어있지 않은지 확인
    final bankName = _userInfo!['bankName'];
    final bankAccount = _userInfo!['bankAccount'];
    final bankCode = _userInfo!['bankCode'];

    return bankName != null &&
        bankName.toString().isNotEmpty &&
        bankAccount != null &&
        bankAccount.toString().isNotEmpty &&
        bankCode != null &&
        bankCode.toString().isNotEmpty;
  }

  // 계좌 섹션 (계좌 정보 유무에 따라 다른 UI 표시)
  Widget _buildAccountSection() {
    final isTablet = MediaQuery.of(context).size.width > 600;
    final bool hasAccountInfo = _checkHasAccountInfo(); // 실제 계좌 정보 확인

    print('🏦 계좌 정보 확인 - hasAccountInfo: $hasAccountInfo');
    if (_userInfo != null) {
      print(
        '🏦 사용자 정보: bankName=${_userInfo!['bankName']}, bankAccount=${_userInfo!['bankAccount']}, bankCode=${_userInfo!['bankCode']}',
      );
    }

    if (hasAccountInfo) {
      print('🏦 계좌 정보 있음 - 충전/내역 버튼 표시');
      // 계좌 정보가 있을 때: 기존 2개 버튼
      return Row(
        children: [
          Expanded(
            child: _buildAccountActionButton(
              '계좌 충전',
              '미리 금액을\n충전하고 바로이용해 봐요',
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ChargeScreen()),
              ),
            ),
          ),
          SizedBox(width: isTablet ? 16 : 10),
          Expanded(
            child: _buildAccountActionButton(
              '내역 보기',
              '최근 입출금 내역을\n쉽게 꺼내봐요',
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TotalPointHistoryScreen(),
                ),
              ),
            ),
          ),
        ],
      );
    } else {
      print('🏦 계좌 정보 없음 - 계좌 연결 안내 표시');
      // 계좌 정보가 없을 때: 계좌 연결 안내
      return _buildAccountConnectPrompt();
    }
  }

  // 계좌 연결 안내 위젯
  Widget _buildAccountConnectPrompt() {
    print('🏦 _buildAccountConnectPrompt() 호출됨 - 계좌 연결 안내 UI 구성');
    return Container(
      width: double.infinity,
      decoration: ShapeDecoration(
        color: const Color(0xFFE4ECF8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            print('🏦 계좌 연결 안내 버튼 클릭됨 - AccountLinkScreen으로 이동');
            // 계좌 연결 화면으로 이동
            Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AccountLinkScreen(),
                  ),
                )
                .then((result) {
                  print('🏦 AccountLinkScreen에서 돌아옴: $result');
                })
                .catchError((error) {
                  print('🏦 AccountLinkScreen 네비게이션 오류: $error');
                });
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '계좌 연결',
                        style: TextStyle(
                          color: const Color(0xFF001F55),
                          fontSize: _getResponsiveFontSize(context, 14),
                          fontFamily: 'Pretendard-Bold',
                          letterSpacing: -0.28,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '충전 계좌를 연결하면 간편하게 이용할 수 있어요',
                        style: TextStyle(
                          color: const Color(0xFF8490A3),
                          fontSize: _getResponsiveFontSize(context, 12),
                          fontFamily: 'Pretendard-Light',
                          height: 1.50,
                          letterSpacing: -0.24,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.grey, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAccountActionButton(
    String title,
    String subtitle,
    VoidCallback onPressed,
  ) {
    final isTablet = MediaQuery.of(context).size.width > 600;
    return Container(
      height: 80, // 고정 높이
      decoration: BoxDecoration(
        color: const Color(0xFFEFF5FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF5D9EFF), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 16 : 12,
              vertical: 8,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: AppTheme.body2.copyWith(
                        fontSize: _getResponsiveFontSize(context, 14),
                        fontFamily: 'Pretendard-Bold',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: Colors.grey,
                      size: isTablet ? 20 : 16,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppTheme.body7.copyWith(
                    height: 1.3,
                    fontSize: _getResponsiveFontSize(context, 10),
                    color: Colors.grey[600],
                    fontFamily: 'Pretendard-Light',
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.left,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMissionContainer(bool isTablet) {
    if (_isLoadingMissions) {
      return Container(
        padding: EdgeInsets.all(isTablet ? 24 : 16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  color: Color(0xFF5D9EFF),
                  strokeWidth: 2,
                ),
              ),
              SizedBox(width: 8),
              Text(
                '미션 데이터를 불러오는 중...',
                style: TextStyle(
                  color: const Color(0xFF999999),
                  fontSize: _getResponsiveFontSize(context, 12),
                  fontFamily: 'Pretendard-Light',
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_missionError != null) {
      return Container(
        padding: EdgeInsets.all(isTablet ? 24 : 16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _missionError!,
                style: TextStyle(
                  color: Colors.red,
                  fontSize: _getResponsiveFontSize(context, 12),
                  fontFamily: 'Pretendard-Light',
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              GestureDetector(
                onTap: _loadMissionData,
                child: Text(
                  '다시 시도',
                  style: TextStyle(
                    color: Color(0xFF5D9EFF),
                    fontSize: _getResponsiveFontSize(context, 12),
                    fontFamily: 'Pretendard-Medium',
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_inProgressMissions.isEmpty) {
      return Container(
        padding: EdgeInsets.all(isTablet ? 24 : 16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            '현재 진행 중인 미션이 없습니다.',
            style: TextStyle(
              color: const Color(0xFF999999),
              fontSize: _getResponsiveFontSize(context, 12),
              fontFamily: 'Pretendard-Light',
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemCount: _inProgressMissions.length,
        separatorBuilder:
            (context, index) => SizedBox(height: isTablet ? 14 : 10),
        itemBuilder: (context, index) {
          final mission = _inProgressMissions[index];
          return _buildMissionItem({
            'title': mission.title,
            'badge': MissionService.getTypeDisplayName(mission.type),
            'amount': NumberFormat('#,###').format(mission.reward),
          });
        },
      ),
    );
  }

  Widget _buildMissionItem(Map<String, dynamic> mission) {
    final isTablet = MediaQuery.of(context).size.width > 600;
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: isTablet ? 16 : 12,
        horizontal: isTablet ? 20 : 16,
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 12 : 10,
              vertical: isTablet ? 6 : 5,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF5D9EFF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              mission['badge'],
              style: TextStyle(
                color: Colors.white,
                fontSize: _getResponsiveFontSize(context, 10) - 2,
                fontFamily: 'Pretendard-Bold',
              ),
            ),
          ),
          SizedBox(width: isTablet ? 16 : 12),
          Expanded(
            flex: 3,
            child: Text(
              mission['title'],
              style: TextStyle(
                fontSize: _getResponsiveFontSize(context, 11),
                fontFamily: 'Pretendard-Bold',
                color: const Color(0xFF001F55),
              ),
              overflow: TextOverflow.ellipsis,
              softWrap: false,
              maxLines: 1,
            ),
          ),

          SizedBox(
            width: isTablet ? 105 : 90,
            child: RichText(
              textAlign: TextAlign.end,
              text: TextSpan(
                children: [
                  TextSpan(
                    text: mission['amount'],
                    style: TextStyle(
                      fontSize: _getResponsiveFontSize(context, 18) - 2,
                      color: Color(0xFF146AFF),
                      fontFamily: 'Pretendard-Bold',
                    ),
                  ),
                  TextSpan(
                    text: '원',
                    style: TextStyle(
                      fontSize: _getResponsiveFontSize(context, 16) - 2,
                      color: Colors.black,
                      fontFamily: 'Pretendard-Bold',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopUsersCard() {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth > 600 ? 358.0 : (screenWidth - 32);
    final userName = _userInfo?['name'] ?? '사용자';

    return Container(
      width: cardWidth,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x35000000),
            blurRadius: 8,
            offset: Offset(3, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: cardWidth,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                Text(
                  '$userName님의 총 활동 리포트',
                  style: const TextStyle(
                    color: Color(0xFF202020),
                    fontSize: 16,
                    fontFamily: 'Pretendard-Bold',
                    letterSpacing: -0.72,
                  ),
                ),
                const SizedBox(height: 0),
                Text(
                  '리틀뱅크에서의 활동 현황을 확인해보세요',
                  style: const TextStyle(
                    color: Color(0xFF999999),
                    fontSize: 12,
                    fontFamily: 'Pretendard-Light',
                    letterSpacing: -0.28,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: cardWidth,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: const ShapeDecoration(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: _buildActivityItem(
                    '참여한 미션',
                    _isLoadingMissionCount
                        ? '-'
                        : _totalMissionCount.toString(),
                  ),
                ),
                Container(
                  height: 40,
                  width: 1,
                  color: const Color(0xFFEEEEEE),
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                ),
                Expanded(
                  child: InkWell(
                    onTap:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) =>
                                    ActivityHistoryScreen(initialTabIndex: 1),
                          ),
                        ),
                    child: _buildActivityItem(
                      '참여한 챌린지',
                      _isLoadingChallengeCount
                          ? '-'
                          : _totalChallengeCount.toString(),
                    ),
                  ),
                ),
                Container(
                  height: 40,
                  width: 1,
                  color: const Color(0xFFEEEEEE),
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                ),
                Expanded(
                  child: _buildActivityItem(
                    '참여한 목표',
                    _isLoadingGoalCount ? '-' : _totalGoalCount.toString(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(String label, String count) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF666666),
            fontSize: 12,
            fontFamily: 'Pretendard-Light',
            letterSpacing: -0.28,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          count,
          style: const TextStyle(
            color: Color(0xFF5D9EFF),
            fontSize: 16,
            fontFamily: 'Pretendard-Bold',
            letterSpacing: -0.32,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildChallengeSection() {
    if (_isLoadingChallenges) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_challengeError != null) {
      return Center(child: Text(_challengeError!));
    }
    if (_currentChallenges.isEmpty && _allChallenges.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _refreshChallenges());
    }
    if (_currentChallenges.isEmpty) {
      return const Center(child: Text('표시할 챌린지가 없습니다.'));
    }
    return ChallengeSectionWidget(challenges: _currentChallenges);
  }

  Widget _buildBalanceGameSection() {
    if (_isLoadingGames) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_gameError != null) {
      return Center(child: Text(_gameError!));
    }
    if (_balanceGames.isEmpty) {
      return const Center(child: Text('오늘의 밸런스 게임 정보를 불러올 수 없습니다.'));
    }

    final game1Data = _balanceGames[0];
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return VisibilityDetector(
      key: const Key('balance-game-section'),
      onVisibilityChanged: (VisibilityInfo info) {
        // 영역이 50% 이상 보일 때 자동 뒤집기 시작
        if (info.visibleFraction > 0.5 && !_hasBalanceGameVisible) {
          print('🎮 밸런스 게임 영역이 화면에 나타남 - 자동 뒤집기 시작!');
          setState(() {
            _hasBalanceGameVisible = true;
          });
        }
      },
      child: Container(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '매일 달라지는 밸런스 게임',
              style: TextStyle(
                color: Color(0xFF202020),
                fontSize: _getResponsiveFontSize(context, 16),
                fontFamily: 'Pretendard-Bold',
                letterSpacing: -0.72,
              ),
            ),
            SizedBox(height: 4),
            Text(
              '카드를 뒤집고 지금의 나를 선택해 보세요',
              style: TextStyle(
                color: const Color(0xFF999999),
                fontSize: _getResponsiveFontSize(context, 12),
                fontFamily: 'Pretendard-Light',
                letterSpacing: -0.28,
              ),
            ),
            SizedBox(height: isTablet ? 32 : 24),
            // 새로운 밸런스 게임 카드 사용
            Row(
              children: [
                Expanded(
                  child: BalanceGameCard(
                    gameData: game1Data,
                    choiceType: 'A',
                    onVote: _handleGameVote,
                    autoFlip: _hasBalanceGameVisible,
                  ),
                ),
                SizedBox(width: isTablet ? 24 : 16),
                Expanded(
                  child: BalanceGameCard(
                    gameData: game1Data,
                    choiceType: 'B',
                    onVote: _handleGameVote,
                    autoFlip: _hasBalanceGameVisible,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
