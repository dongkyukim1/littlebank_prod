import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../widgets/parent/bottom_navigation_bar.dart';
import 'widgets/mission_section.dart';
import '../../services/family_service.dart';
import '../../services/auth_service.dart';
import '../../services/mission_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'alert/notification_screen.dart';
import 'mission/weekly_goal_card.dart';
import 'mission/vote_card.dart';
import 'mission/parent_mission_list_screen.dart';
import 'my/my_page_screen.dart' as my_page; // prefix 추가
import '../../services/notification_service.dart';

class ParentMissionScreen extends StatefulWidget {
  const ParentMissionScreen({super.key});

  @override
  State<ParentMissionScreen> createState() => _ParentMissionScreenState();
}

class _ParentMissionScreenState extends State<ParentMissionScreen> {
  // 가족 정보 관련 변수들 추가
  List<dynamic>? _familyMembers;
  bool _isLoadingFamily = true;
  String? _familyError;

  // 사용자 정보 관련 변수들 추가
  Map<String, dynamic>? _userInfo;
  bool _isLoadingUser = true;
  String? _userError;

  // 선택된 자녀 정보 추가
  Map<String, dynamic>? _selectedChild;

  // 스크롤 관련 변수들 추가
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;

  // 미션 데이터 관련 변수들
  List<MissionResponse> _participatingMissions = [];
  bool _isLoadingMissions = true;
  String? _missionError;
  int _currentMissionIndex = 0;
  late PageController _pageController;

  // 알림 관련 변수들
  int _unreadNotificationCount = 0;
  bool _isLoadingNotifications = false;

  @override
  void initState() {
    super.initState();

    // 스크롤 리스너 추가
    _scrollController.addListener(_scrollListener);

    // 페이지 컨트롤러 초기화
    _pageController = PageController();

    _loadUserInfo();
    _loadFamilyMembers();
    _loadUnreadNotificationCount();
    // _loadMissionData()는 _loadFamilyMembers() 완료 후에 호출됩니다.
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  // 스크롤 리스너
  void _scrollListener() {
    if (_scrollController.offset > 50) {
      if (!_isScrolled) {
        setState(() {
          _isScrolled = true;
        });
      }
    } else {
      if (_isScrolled) {
        setState(() {
          _isScrolled = false;
        });
      }
    }
  }

  // 사용자 정보 불러오기
  Future<void> _loadUserInfo() async {
    try {
      if (mounted) {
        setState(() {
          _isLoadingUser = true;
          _userError = null;
        });
      }

      print('미션 화면: 사용자 정보 로드 시작');

      final userInfo = await AuthService.getUserInfo();

      if (mounted) {
        setState(() {
          _userInfo = userInfo;
          _isLoadingUser = false;
        });

        print('미션 화면: 사용자 정보 로드 성공 - ${userInfo['name']}');
      }
    } catch (e) {
      print('미션 화면: 사용자 정보 로드 중 예외 발생: $e');

      if (mounted) {
        setState(() {
          _userError = '사용자 정보를 불러올 수 없습니다';
          _isLoadingUser = false;
        });
      }
    }
  }

  // 가족 구성원 목록 불러오기
  Future<void> _loadFamilyMembers() async {
    try {
      if (mounted) {
        setState(() {
          _isLoadingFamily = true;
          _familyError = null;
        });
      }

      print('미션 화면: 가족 구성원 목록 로드 시작');

      final familyInfo = await FamilyService.getFamilyInfo();

      if (familyInfo != null) {
        final List<dynamic> memberList = familyInfo['memberInfoList'] ?? [];
        print('미션 화면: 가족 정보 로드 성공 - 멤버 ${memberList.length}명');

        // 자녀만 필터링
        final children =
            memberList.where((member) => member['role'] != 'PARENT').toList();

        if (mounted) {
          setState(() {
            _familyMembers = children;
            _selectedChild =
                children.isNotEmpty ? children[0] : null; // 첫 번째 자녀를 기본 선택
            _isLoadingFamily = false;
          });

          // 첫 번째 자녀가 선택되었으면 미션 데이터 로드
          if (_selectedChild != null) {
            _loadMissionData();
          }
        }
      } else {
        print('미션 화면: 가족 정보 조회 실패 또는 가족 정보 없음');

        if (mounted) {
          setState(() {
            _familyMembers = [];
            _selectedChild = null;
            _isLoadingFamily = false;
          });

          // 자녀가 없으면 빈 미션 데이터로 설정
          _loadMissionData();
        }
      }
    } catch (e) {
      print('미션 화면: 가족 구성원 목록 로드 중 예외 발생: $e');

      if (mounted) {
        setState(() {
          _familyError = '가족 정보를 불러올 수 없습니다';
          _isLoadingFamily = false;
          _familyMembers = [];
          _selectedChild = null;
        });

        // 에러 발생 시에도 빈 미션 데이터로 설정
        _loadMissionData();
      }
    }
  }

  // 안읽은 알림 개수 로드
  Future<void> _loadUnreadNotificationCount() async {
    if (!mounted) return;
    
    setState(() {
      _isLoadingNotifications = true;
    });

    try {
      final count = await NotificationService.getUnreadNotificationCount();
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

  // 미션 데이터 로드
  Future<void> _loadMissionData() async {
    if (_selectedChild == null) {
      print('선택된 자녀가 없어서 미션 데이터를 로드하지 않습니다.');
      setState(() {
        _participatingMissions = [];
        _isLoadingMissions = false;
      });
      return;
    }

    try {
      setState(() {
        _isLoadingMissions = true;
        _missionError = null;
      });

      // userId를 우선적으로 사용하고, 없으면 familyMemberId를 사용
      final childId =
          _selectedChild!['userId'] ?? _selectedChild!['familyMemberId'];

      if (childId == null) {
        throw Exception('자녀 ID를 찾을 수 없습니다');
      }

      print('미션 데이터 로드 시작 - 자녀 ID: $childId');

      final missionsData = await MissionService.getParentChildMissions(
        childId: childId,
        page: 0,
      );

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

        setState(() {
          _participatingMissions = inProgressMissions;
          _isLoadingMissions = false;
        });

        print('미션 데이터 로드 완료 - 진행 중: ${inProgressMissions.length}개');
      } else {
        print('미션 데이터가 없습니다.');
        setState(() {
          _participatingMissions = [];
          _isLoadingMissions = false;
        });
      }
    } catch (e) {
      print('미션 데이터 로드 실패: $e');
      setState(() {
        _missionError = '미션 정보를 불러오는데 실패했습니다.';
        _participatingMissions = [];
        _isLoadingMissions = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE7ECF6),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController, // ScrollController 추가
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      _buildMissionProgressCard(),
                      const SizedBox(height: 24),
                      ParentWeeklyGoalMissionCard(
                        selectedChild: _selectedChild,
                        onCheckHabit: () {},
                        onCheckStudy: () {},
                      ),
                      const SizedBox(height: 16),
                      ParentVoteCard(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: AnimatedContainer(
        duration: Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
        padding:
            _isScrolled
                ? EdgeInsets.zero
                : const EdgeInsets.only(
                  right: 1,
                  top: 8,
                  bottom: 8,
                ), // 처음 상태에서 오른쪽으로 12px 이동
        child: GestureDetector(
          onTap: _showMissionCreationModal,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(_isScrolled ? 28 : 24),
            child: AnimatedContainer(
              duration: Duration(milliseconds: 500),
              curve: Curves.easeInOutCubic,
              width: _isScrolled ? 56 : 140,
              height: _isScrolled ? 56 : 48,
              padding:
                  _isScrolled
                      ? EdgeInsets.zero
                      : const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
              decoration: ShapeDecoration(
                color: const Color(0xFF5D9EFF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(_isScrolled ? 28 : 24),
                ),
                shadows: [
                  BoxShadow(
                    color: const Color(0xFF5D9EFF).withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: AnimatedSwitcher(
                duration: Duration(milliseconds: 400),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(scale: animation, child: child),
                  );
                },
                child:
                    _isScrolled
                        ? Container(
                          key: ValueKey('icon'),
                          width: 24,
                          height: 24,
                          child: Image.asset(
                            'assets/icons/parent/mission/mission_create.png',
                            width: 24,
                            height: 24,
                            color: Colors.white,
                            errorBuilder:
                                (context, error, stackTrace) => Icon(
                                  Icons.add,
                                  color: Colors.white,
                                  size: 24,
                                ),
                          ),
                        )
                        : Row(
                          key: ValueKey('text'),
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 18,
                              height: 18,
                              margin: const EdgeInsets.only(right: 8),
                              child: Image.asset(
                                'assets/icons/parent/mission/생성.png',
                                width: 18,
                                height: 18,
                                color: Colors.white,
                                errorBuilder:
                                    (context, error, stackTrace) => Icon(
                                      Icons.add,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                              ),
                            ),
                            Flexible(
                              child: Text(
                                '미션 생성',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontFamily: 'Pretendard-Medium',
                                  letterSpacing: -0.56,
                                ),
                                overflow: TextOverflow.clip,
                              ),
                            ),
                          ],
                        ),
              ),
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: const ParentBottomNavigationBar(selectedIndex: 2),
    );
  }

  // 앱바 위젯 구현
  Widget _buildAppBar() {
    return Container(
      width: double.infinity,
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      color: const Color(0xFFE7ECF6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 왼쪽 로고
          Image.asset(
            'assets/logos/parent_logo.png',
            width: 28,
            height: 28,
            fit: BoxFit.contain,
          ),

          // 오른쪽 아이콘들 (자녀 프로필, 부모 프로필, 알림)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 자녀 프로필과 변경 버튼
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: ShapeDecoration(
                  color: const Color(0xFF5D9EFF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 자녀 프로필 이미지
                    Container(
                      width: 24,
                      height: 24,
                      decoration: ShapeDecoration(
                        shape: OvalBorder(
                          side: BorderSide(
                            width: 0.80,
                            color: const Color(0xFF146AFF),
                          ),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child:
                            _isLoadingFamily
                                ? Container(
                                  color: Colors.grey[300],
                                  child: Center(
                                    child: SizedBox(
                                      width: 12,
                                      height: 12,
                                      child: CircularProgressIndicator(
                                        color: Colors.grey[600],
                                        strokeWidth: 1,
                                      ),
                                    ),
                                  ),
                                )
                                : _selectedChild?['profileImagePath'] != null &&
                                    _selectedChild!['profileImagePath']!
                                        .isNotEmpty
                                ? CachedNetworkImage(
                                  imageUrl: AuthService.getFullProfileImageUrl(
                                    _selectedChild!['profileImagePath'],
                                  ),
                                  fit: BoxFit.cover,
                                  placeholder:
                                      (context, url) => Container(
                                        color: Colors.grey[300],
                                        child: Icon(
                                          Icons.person,
                                          color: Colors.grey[600],
                                          size: 12,
                                        ),
                                      ),
                                  errorWidget:
                                      (context, url, error) => Container(
                                        color: Colors.grey[300],
                                        child: Icon(
                                          Icons.person,
                                          color: Colors.grey[600],
                                          size: 12,
                                        ),
                                      ),
                                )
                                : Container(
                                  color: Colors.grey[300],
                                  child: Icon(
                                    Icons.person,
                                    color: Colors.grey[600],
                                    size: 12,
                                  ),
                                ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // 변경 버튼
                    GestureDetector(
                      onTap: _showChildSelectionModal,
                      child: Container(
                        width: 24,
                        height: 24,
                        child: Image.asset(
                          'assets/icons/parent/아이변경.png',
                          width: 24,
                          height: 24,
                          color: Colors.white,
                          errorBuilder:
                              (context, error, stackTrace) => Icon(
                                Icons.swap_horiz,
                                color: Colors.white,
                                size: 16,
                              ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // 부모 프로필 아이콘 - 실제 사용자 프로필 이미지로 변경
              Container(
                width: 32,
                height: 32,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child:
                      _isLoadingUser
                          ? Container(
                            color: const Color(0xFFFDC963),
                            child: const Center(
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                          )
                          : _userInfo?['profileImagePath'] != null &&
                              _userInfo!['profileImagePath']!.isNotEmpty
                          ? CachedNetworkImage(
                            imageUrl: AuthService.getFullProfileImageUrl(
                              _userInfo!['profileImagePath'],
                            ),
                            fit: BoxFit.cover,
                            placeholder:
                                (context, url) => Container(
                                  color: const Color(0xFFFDC963),
                                  child: const Center(
                                    child: Text(
                                      '부',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontFamily: 'Pretendard-Bold',
                                      ),
                                    ),
                                  ),
                                ),
                            errorWidget:
                                (context, url, error) => Container(
                                  color: const Color(0xFFFDC963),
                                  child: const Center(
                                    child: Text(
                                      '부',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontFamily: 'Pretendard-Bold',
                                      ),
                                    ),
                                  ),
                                ),
                          )
                          : Container(
                            color: const Color(0xFFFDC963),
                            child: const Center(
                              child: Text(
                                '부',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontFamily: 'Pretendard-Bold',
                                ),
                              ),
                            ),
                          ),
                ),
              ),

              // 알림 아이콘 - 지정된 이미지 파일로 변경
              GestureDetector(
                onTap: () {
                  // 알림 화면으로 이동
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ParentNotificationScreen(),
                    ),
                  );
                },
                child: Container(
                  width: 32,
                  height: 32,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Center(
                        child: Image.asset(
                          'assets/icons/parent/noti/alert.png',
                          width: 20,
                          height: 20,
                          color: Colors.black,
                          errorBuilder:
                              (context, error, stackTrace) => const Icon(
                                Icons.notifications_none_rounded,
                                color: Colors.black,
                                size: 20,
                              ),
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
                                NotificationService.formatUnreadCount(_unreadNotificationCount),
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
        ],
      ),
    );
  }

  // 자녀 변경 모달 표시
  void _showChildSelectionModal() {
    // 자녀(CHILD 역할)만 필터링
    final filteredChildren =
        _familyMembers?.where((child) {
          return child['role'] == 'CHILD';
        }).toList() ??
        [];

    if (filteredChildren.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('선택할 수 있는 자녀가 없습니다')));
      return;
    }

    // 현재 선택된 자녀의 인덱스 찾기
    int selectedIndex = 0;
    if (_selectedChild != null) {
      for (int i = 0; i < filteredChildren.length; i++) {
        final childName =
            filteredChildren[i]['nickname'] ??
            filteredChildren[i]['realName'] ??
            '';
        final selectedChildName =
            _selectedChild?['nickname'] ?? _selectedChild?['realName'] ?? '';
        if (childName == selectedChildName && childName.isNotEmpty) {
          selectedIndex = i;
          break;
        }
      }
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return my_page.ChildSelectionModal(
          children: filteredChildren,
          initialSelectedIndex: selectedIndex,
          onChildSelected: (selectedChild, selectedIndex) {
            setState(() {
              _selectedChild = selectedChild;
            });
            _loadMissionData(); // 자녀 변경 시 미션 데이터 다시 로드
          },
        );
      },
    );
  }

  // 미션 진행 상황 카드
  Widget _buildMissionProgressCard() {
    // 로딩 중일 때
    if (_isLoadingMissions) {
      return Container(
        width: double.infinity,
        height: 200,
        margin: const EdgeInsets.symmetric(horizontal: 0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Color(0x35000000),
              blurRadius: 8,
              offset: Offset(3, 4),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5D9EFF)),
          ),
        ),
      );
    }

    // 미션이 없을 때
    if (_participatingMissions.isEmpty) {
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Color(0x35000000),
              blurRadius: 8,
              offset: Offset(3, 4),
              spreadRadius: 0,
            )
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 상단 텍스트 섹션
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '아직 아이가 참여 중인 미션이 없어요',
                    style: TextStyle(
                      color: const Color(0xFF202020),
                      fontSize: 18,
                      fontFamily: 'Pretendard-Bold',
                      letterSpacing: -0.72,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '아이의 성장을 위해 미션을 보내보세요',
                    style: TextStyle(
                      color: const Color(0xFF999999),
                      fontSize: 14,
                      fontFamily: 'Pretendard-Light',
                      letterSpacing: -0.28,
                    ),
                  ),
                ],
              ),
            ),
            
            // 이미지 섹션
            Container(
              height: 240,
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Image.asset(
                  "assets/icons/parent/mission/non_misson.png",
                  width: 220,
                  height: 200,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 220,
                      height: 200,
                      color: Colors.grey[200],
                      child: Icon(
                        Icons.assignment_outlined,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                    );
                  },
                ),
              ),
            ),
            
            // 버튼 섹션
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              child: GestureDetector(
                onTap: () {
                  // 미션 생성 모달 표시
                  _showMissionCreationModal();
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                  decoration: ShapeDecoration(
                    color: const Color(0xFF3A88F4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '미션 생성하러 가기',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
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
      );
    }

    // 현재 미션 정보
    final currentMission = _participatingMissions[_currentMissionIndex];
    final now = DateTime.now();
    final totalDays =
        currentMission.endDate.difference(currentMission.startDate).inDays + 1;
    final passedDays = now.difference(currentMission.startDate).inDays;
    final remainingDays = currentMission.endDate.difference(now).inDays;
    final progress = passedDays / totalDays;
    final progressPercent = (progress * 100).clamp(0, 100).toInt();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Color(0x35000000),
            blurRadius: 8,
            offset: Offset(3, 4),
            spreadRadius: 0,
          ),
        ],
              ),
        child: Padding(
          padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상단 섹션
            Stack(
              children: [
                // 제목 섹션
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          '지금 아이가 참여 중인 미션',
                          style: TextStyle(
                            color: Color(0xFF202020),
                            fontSize: 16,
                            fontFamily: 'Pretendard-Bold',
                            letterSpacing: -0.72,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${_participatingMissions.length}',
                          style: const TextStyle(
                            color: Color(0xFF146AFF),
                            fontSize: 16,
                            fontFamily: 'Pretendard-Bold',
                            letterSpacing: -0.72,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      '가장 최근에 참여한 미션부터 보여드려요',
                      style: TextStyle(
                        color: Color(0xFF999999),
                        fontSize: 12,
                        fontFamily: 'Pretendard-Light',
                        letterSpacing: -0.24,
                      ),
                    ),
                  ],
                ),

                // 전체보기 버튼
                Positioned(
                  right: 0,
                  top: 0,
                  child: GestureDetector(
                    onTap: () {
                      // 전체보기 화면으로 이동
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => ParentMissionListScreen(
                                selectedChild: _selectedChild,
                              ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 9,
                      ),
                      decoration: ShapeDecoration(
                        color: const Color(0xFFEFF2F6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        '전체보기',
                        style: TextStyle(
                          color: Color(0xFF001F55),
                          fontSize: 10,
                          fontFamily: 'Pretendard-Light',
                          letterSpacing: -0.24,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 미션 내용 - PageView로 감싸기
            SizedBox(
              height: 150, // 고정 높이
              child: PageView.builder(
                controller: _pageController,
                itemCount: _participatingMissions.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentMissionIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  final mission = _participatingMissions[index];
                  final now = DateTime.now();
                  final totalDays =
                      mission.endDate.difference(mission.startDate).inDays + 1;
                  final passedDays = now.difference(mission.startDate).inDays;
                  final remainingDays = mission.endDate.difference(now).inDays;
                  final progress = passedDays / totalDays;
                  final progressPercent =
                      (progress * 100).clamp(0, 100).toInt();

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 태그 영역
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              // 미션 타입 태그
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: ShapeDecoration(
                                  color: const Color(0xFF5D9EFF),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text(
                                  MissionService.getTypeDisplayName(
                                    mission.type,
                                  ),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontFamily: 'Pretendard-Light',
                                    letterSpacing: -0.24,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),

                              // D-day 태그
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: ShapeDecoration(
                                  color: const Color(0xFFFFD27F),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text.rich(
                                  TextSpan(
                                    children: [
                                      const TextSpan(
                                        text: '완료까지 ',
                                        style: TextStyle(
                                          color: Color(0xFF001F55),
                                          fontSize: 10,
                                          fontFamily: 'Pretendard-Light',
                                          letterSpacing: -0.24,
                                        ),
                                      ),
                                      TextSpan(
                                        text:
                                            remainingDays >= 0
                                                ? 'D-$remainingDays'
                                                : '완료',
                                        style: const TextStyle(
                                          color: Color(0xFF001F55),
                                          fontSize: 10,
                                          fontFamily: 'Pretendard-Medium',
                                          letterSpacing: -0.24,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),

                        // 미션 제목
                        Text(
                          mission.title,
                          style: const TextStyle(
                            color: Color(0xFF202020),
                            fontSize: 14,
                            fontFamily: 'Pretendard-Bold',
                            letterSpacing: -0.32,
                          ),
                        ),
                       const SizedBox(height: 20),

                        // 프로그레스 바와 퍼센트 표시
                        SizedBox(
                          height: 60, // 말풍선 포함한 높이
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final progressBarWidth = constraints.maxWidth;
                              final progressRatio =
                                  (progress * 100).clamp(0, 100) / 100;

                              // 말풍선 위치 계산 - 최소값 보장
                              final balloonPosition = math.max(
                                0.0,
                                math.min(
                                  progressBarWidth - 48, // 말풍선 너비(48px) 고려
                                  8 +
                                      ((progressBarWidth - 16) *
                                          progressRatio) -
                                      24,
                                ),
                              );

                              return Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  // 진행률 말풍선 표시
                                  Positioned(
                                    left: balloonPosition,
                                    top: -10,
                                    child: Column(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF5D9EFF),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: Text(
                                            '$progressPercent%',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontFamily: 'Pretendard-Light',
                                            ),
                                          ),
                                        ),
                                        CustomPaint(
                                          size: const Size(14, 7),
                                          painter: TrianglePainter(
                                            color: const Color(0xFF5D9EFF),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // 프로그레스 바 배경
                                  Positioned(
                                    top: 30,
                                    left: 8,
                                    right: 8,
                                    child: Container(
                                      width: progressBarWidth - 16,
                                      height: 15,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE4E4E4),
                                        borderRadius: BorderRadius.circular(
                                          7.5,
                                        ),
                                      ),
                                    ),
                                  ),

                                  // 진행 프로그레스 바
                                  Positioned(
                                    top: 30,
                                    left: 8,
                                    child: Container(
                                      width:
                                          (progressBarWidth - 16) *
                                          progressRatio,
                                      height: 15,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          begin: Alignment.centerLeft,
                                          end: Alignment.centerRight,
                                          colors: [
                                            Color(0xFF10CB86),
                                            Color(0xFF5D9EFF),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          7.5,
                                        ),
                                      ),
                                    ),
                                  ),

                                  // 구분선들
                                  for (double ratio in [0.25, 0.5, 0.75])
                                    Positioned(
                                      left:
                                          8 +
                                          (progressBarWidth - 16) * ratio -
                                          1,
                                      top: 30,
                                      height: 15,
                                      child:
                                          progressRatio > ratio
                                              ? _buildEnhancedVerticalDashedLine()
                                              : _buildVerticalDashedLine(),
                                    ),

                                  // 완료 지점 아이콘
                                  Positioned(
                                    left: 5 + (progressBarWidth - 16) - 14,
                                    top: 22,
                                    child: Container(
                                      width: 28,
                                      height: 28,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF3A88F4),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Image.asset(
                                          'assets/icons/Icon/mission/달성.png',
                                          width: 18,
                                          height: 18,
                                          color: const Color(0xFFFFD27F),
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  const Icon(
                                                    Icons.flag,
                                                    size: 18,
                                                    color: Color(0xFFFFD27F),
                                                  ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 8),

            // 페이지 인디케이터
            if (_participatingMissions.length > 1)
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    _participatingMissions.length,
                    (index) => GestureDetector(
                      onTap: () {
                        _pageController.animateToPage(
                          index,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: Container(
                        width: index == _currentMissionIndex ? 28 : 4,
                        height: 4,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: ShapeDecoration(
                          color:
                              index == _currentMissionIndex
                                  ? const Color(0xFF5D9EFF)
                                  : const Color(0xFFB6B6B6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
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
  }

  // 세로 점선 위젯 (기본)
  Widget _buildVerticalDashedLine() {
    return SizedBox(
      width: 2, // 선 두께
      child: Column(
        children: [
          Container(width: 2, height: 3, color: Colors.white),
          const SizedBox(height: 2),
          Container(width: 2, height: 3, color: Colors.white),
          const SizedBox(height: 2),
          Container(width: 2, height: 3, color: Colors.white),
        ],
      ),
    );
  }

  // 향상된 세로 점선 위젯 (그라데이션에 가려지지 않도록)
  Widget _buildEnhancedVerticalDashedLine() {
    return SizedBox(
      width: 3, // 선 두께 증가
      child: Column(
        children: [
          Container(
            width: 3,
            height: 3,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.black12, width: 0.5),
              borderRadius: BorderRadius.circular(1.5),
            ),
          ),
          const SizedBox(height: 2),
          Container(
            width: 3,
            height: 3,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.black12, width: 0.5),
              borderRadius: BorderRadius.circular(1.5),
            ),
          ),
          const SizedBox(height: 2),
          Container(
            width: 3,
            height: 3,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.black12, width: 0.5),
              borderRadius: BorderRadius.circular(1.5),
            ),
          ),
        ],
      ),
    );
  }

  // 미션 생성 모달 표시
  void _showMissionCreationModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return const MissionCreationModal();
      },
    );
  }
}

// 삼각형 페인터 (말풍선 화살표용)
class TrianglePainter extends CustomPainter {
  final Color color;

  TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(size.width / 2 - 6, 0);
    path.lineTo(size.width / 2, size.height);
    path.lineTo(size.width / 2 + 6, 0);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
