import 'package:flutter/material.dart';
import '../../widgets/shared_goal_data.dart';
import '../../models/mission_data.dart';
import '../../widgets/mission/mission_comparison_section.dart';
import '../../widgets/mission/mission_weekly_goal_section.dart';
import '../../widgets/common/bottom_navigation_bar.dart';
import '../../widgets/mission/participating_mission_section.dart';
import '../../widgets/mission/empty_mission_section.dart';
import 'widgets/challenge_section_widget.dart';
import '../../services/auth_service.dart';
import '../../services/challenge_service.dart';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'challenge/challenge_detail_screen.dart';
import '../notice_kid/notice_kid.dart';
import '../notice_kid/child_screen_wrapper.dart';
import 'mission/timer/timer_setting_screen.dart';
import 'notification_screen.dart';
import '../../services/notification_service.dart' as notification;

class MissionScreen extends StatefulWidget {
  const MissionScreen({super.key});
 
  @override
  State<MissionScreen> createState() => _MissionScreenState();
}

class _MissionScreenState extends State<MissionScreen> {
  bool _showMissions = true; // 미션 보여줄지 여부를 제어하는 변수
  bool _showGoalStatus = true; // 목표 상태를 보여줄지 여부를 제어하는 변수
  final MissionData missionData = MissionData();
  final ScrollController _scrollController = ScrollController();
  Map<String, dynamic>? _userInfo;
  bool _isLoading = true;

  // 챌린지 관련 변수 수정
  List<Map<String, dynamic>> _allChallenges = [];
  bool _isLoadingChallenges = true;
  String? _challengeError;

  // 알림 관련 변수들
  int _unreadNotificationCount = 0;
  bool _isLoadingNotifications = false;

  @override
  void initState() {
    super.initState();
    missionData.init();
    _loadUserInfo();
    _loadChallenges();
    _loadUnreadNotificationCount();
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

  // API로부터 챌린지 데이터 불러오기
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
          });
        }
        return;
      }

      // API 응답을 프론트엔드 형식으로 변환
      final formattedChallenges =
          challenges.map((challenge) {
            // 카테고리를 한글로 변환
            String periodType = '전체';
            if (challenge.category == 'WEEK') {
              periodType = '요일별';
            } else if (challenge.category == 'SUBJECT') {
              periodType = '과목별';
            }

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

            // 전체 데이터 형식화
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
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingChallenges = false;
          _challengeError = '챌린지 데이터를 불러오는 중 오류가 발생했습니다.';
          print('챌린지 데이터 로딩 오류: $e');
        });
      }
    }
  }

  // 사용자 정보 불러오기
  Future<void> _loadUserInfo() async {
    try {
      if (mounted) {
        setState(() {
          _isLoading = true;
        });
      }

      final userInfo = await AuthService.getUserInfo();

      if (mounted) {
        setState(() {
          _userInfo = userInfo;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      print('사용자 정보 로딩 오류: $e');
    }
  }

  // 프로필 이미지 콘텐츠를 구성하는 메서드
  Widget _buildProfileImageContent() {
    final String s3BaseUrl =
        "https://littlebank-dev.s3.ap-northeast-2.amazonaws.com/"; // S3 기본 URL

    if (_userInfo?['profileImagePath'] != null &&
        _userInfo!['profileImagePath'].toString().isNotEmpty) {
      final String imagePath = _userInfo!['profileImagePath'].toString();

      // 이미 http로 시작하는 완전한 URL인 경우
      if (imagePath.startsWith('http')) {
        return CachedNetworkImage(
          imageUrl: imagePath,
          fit: BoxFit.cover,
          placeholder:
              (context, url) => CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
          errorWidget:
              (context, url, error) =>
                  Icon(Icons.person, color: Colors.white, size: 20),
        );
      }
      // 서버의 상대 경로인 경우 (images/로 시작)
      else if (imagePath.startsWith('images/')) {
        // 직접 S3에서 이미지 가져오기 (서버 우회)
        final s3Url = s3BaseUrl + imagePath;
        return Image.network(
          s3Url,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2,
              value:
                  loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
            );
          },
          errorBuilder:
              (context, error, stackTrace) =>
                  Icon(Icons.person, color: Colors.white, size: 20),
        );
      }
      // 실제 로컬 파일인 경우 (/ 또는 절대 경로로 시작하는 경우만)
      else if (imagePath.startsWith('/') && File(imagePath).existsSync()) {
        return Image.file(
          File(imagePath),
          fit: BoxFit.cover,
          errorBuilder:
              (context, error, stackTrace) =>
                  Icon(Icons.person, color: Colors.white, size: 20),
        );
      }
    }

    // 이미지가 없거나 모든 시도가 실패한 경우
    return Icon(Icons.person, color: Colors.white, size: 20);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // 화면 크기에 따른 패딩 계산
  EdgeInsets _getResponsivePadding(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth > 600) {
      final horizontalPadding = screenWidth * 0.1; // 10% of screen width
      return EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: 16.0,
      );
    } else {
      return const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0);
    }
  }

  // 반응형 폰트 크기 계산
  double _getResponsiveFontSize(BuildContext context, double baseSize) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth > 600) {
      return baseSize * 1.2; // 큰 화면에서 20% 더 큰 폰트
    } else if (screenWidth < 360) {
      return baseSize * 0.9; // 작은 화면에서 10% 더 작은 폰트
    }
    return baseSize;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return ChildScreenWrapper(
      child: Scaffold(
        backgroundColor: const Color(0xFFF0F2F7),
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(isTablet ? 60.0 : 50.0),
          child: AppBar(
            backgroundColor: const Color(0xFFF0F2F7),
            elevation: 0,
            automaticallyImplyLeading: false,
            title: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                children: [
                  // 로고 이미지
                  Image.asset(
                    'assets/images/app_logo.png',
                    width: 32,
                    height: 32,
                    fit: BoxFit.contain,
                  ),

                  const Spacer(),

                  // 타이머 아이콘
                  IconButton(
                    icon: Image.asset(
                      'assets/icons/Icon/mission/timer.png',
                      width: 28,
                      height: 28,
                      fit: BoxFit.contain,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TimerSettingScreen(),
                        ),
                      );
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),

                  const SizedBox(width: 8),

                  // 프로필 이미지 (원형) - 동적으로 변경
                  Container(
                    width: 35,
                    height: 35,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFD9D9D9),
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child:
                          _isLoading
                              ? const Center(
                                child: SizedBox(
                                  width: 15,
                                  height: 15,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                              : _buildProfileImageContent(),
                    ),
                  ),

                  const SizedBox(width: 8), // 아이콘 사이 간격 추가
                  // 알림 아이콘 - 위치 변경
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotificationScreen(),
                        ),
                      );
                    },
                    child: Container(
                      width: 28,
                      height: 28,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Center(
                            child: Image.asset(
                              'assets/icons/Icon/알림/Regular.png',
                              width: 24,
                              height: 24,
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
                ],
              ),
            ),
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.only(bottom: 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20), // 앱바와 첫 번째 섹션 사이 간격 추가
                    // 친구와 미션 비교 섹션
                    MissionComparisonSection(
                      missionData: missionData,
                      scrollController: _scrollController,
                    ),

                    const SizedBox(height: 12), // 섹션 간 간격 축소
                    // 미션 섹션 (토글 기능 추가)
                    _showMissions
                        ? ParticipatingMissionSection(
                          showMissions: _showMissions,
                          onToggleChanged: (value) {
                            // build 완료 후 setState 실행
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted) {
                                setState(() {
                                  _showMissions = value;
                                });
                              }
                            });
                          },
                        )
                        : EmptyMissionSection(
                          showMissions: _showMissions,
                          onToggleChanged: (value) {
                            // build 완료 후 setState 실행
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted) {
                                setState(() {
                                  _showMissions = value;
                                });
                              }
                            });
                          },
                        ),

                    const SizedBox(height: 12), // 섹션 간 간격 축소
                    // 이번 주 나의 목표
                    MissionWeeklyGoalSection(
                      weeklyGoal: missionData.weeklyGoal,
                      onGoalUpdated: (goal) {
                        // build 완료 후 setState 실행
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) {
                            setState(() {
                              missionData.weeklyGoal = goal;
                              SharedGoalData.weeklyGoal = goal;
                            });
                          }
                        });
                      },
                      showGoalStatus: _showGoalStatus,
                      onToggleGoalStatus: (value) {
                        // build 완료 후 setState 실행
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) {
                            setState(() {
                              _showGoalStatus = value;
                            });
                          }
                        });
                      },
                    ),

                    const SizedBox(height: 24), // 섹션 간 간격 추가
                    // 많은 사람들이 보고있는 챌린지 (홈화면 스타일로)
                    _buildChallengeSection(),
                  ],
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: CommonBottomNavigationBar(selectedIndex: 2),
      ),
    );
  }

  Widget _buildChallengeSection() {
    final isTablet = MediaQuery.of(context).size.width > 600;

    if (_isLoadingChallenges) {
      return Padding(
        padding:
            isTablet ? const EdgeInsets.all(24.0) : const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '많은 사람들이 보고있는 챌린지',
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: 'Pretendard-Bold',
                        color: Color(0xFF353535),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      '현재 가장 많이 참여 중이에요',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF999999),
                        fontFamily: 'Pretendard-Regular',
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  decoration: ShapeDecoration(
                    color: const Color(0xFFEFF2F6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    '전체보기',
                    style: TextStyle(
                      color: Color(0xFF001F55),
                      fontSize: 12,
                      fontFamily: 'Pretendard-Medium',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 48),
            const Center(
              child: CircularProgressIndicator(color: Color(0xFF5D9EFF)),
            ),
          ],
        ),
      );
    }

    if (_challengeError != null) {
      return Padding(
        padding:
            isTablet ? const EdgeInsets.all(24.0) : const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '많은 사람들이 보고있는 챌린지',
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: 'Pretendard-Bold',
                        color: Color(0xFF353535),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      '현재 가장 많이 참여 중이에요',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF999999),
                        fontFamily: 'Pretendard-Regular',
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            Center(
              child: Column(
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Color(0xFF999999),
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _challengeError!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF999999),
                      fontFamily: 'Pretendard-Medium',
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      _loadChallenges();
                    },
                    child: const Text(
                      '다시 시도',
                      style: TextStyle(
                        color: Color(0xFF5D9EFF),
                        fontSize: 14,
                        fontFamily: 'Pretendard-Medium',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (_allChallenges.isEmpty) {
      return Padding(
        padding:
            isTablet ? const EdgeInsets.all(24.0) : const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '많은 사람들이 보고있는 챌린지',
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: 'Pretendard-Bold',
                        color: Color(0xFF353535),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      '현재 가장 많이 참여 중이에요',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF999999),
                        fontFamily: 'Pretendard-Regular',
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Text(
                  '현재 참여 가능한 챌린지가 없습니다.',
                  style: TextStyle(
                    color: Color(0xFF999999),
                    fontSize: 14,
                    fontFamily: 'Pretendard-Light',
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding:
          isTablet ? const EdgeInsets.all(24.0) : const EdgeInsets.all(16.0),
      child: ChallengeSectionWidget(challenges: _allChallenges),
    );
  }
}
