import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/mission_data.dart';
import '../../services/mission_service.dart';
import '../../services/auth_service.dart';
import '../../services/payment_service.dart';
import 'compatition/loading_screen.dart';
import 'compatition/friends_ranking_screen.dart';
import 'bottomsheet/goal_amount_setting_bottom_sheet.dart';
import 'bottomsheet/subject_comparison_bottom_sheet.dart';
import 'bottomsheet/friend_selection_bottom_sheet.dart';

/// 나와 같은 목표를 가진 친구 훔쳐보기 섹션 위젯
class MissionComparisonSection extends StatefulWidget {
  final MissionData missionData;
  final ScrollController scrollController;

  const MissionComparisonSection({
    super.key,
    required this.missionData,
    required this.scrollController,
  });

  @override
  State<MissionComparisonSection> createState() =>
      _MissionComparisonSectionState();
}

class _MissionComparisonSectionState extends State<MissionComparisonSection> {
  bool _isLoading = false;
  int? _userTargetAmount; // 사용자의 현재 목표 금액
  bool _isCheckingTargetAmount = true;
  bool _isCompeting = false; // 경쟁 상태
  Map<String, dynamic>? _competingFriendData; // 경쟁 중인 친구 데이터

  // 사용자 정보
  String? _userProfileImageUrl;
  String _userName = '나';
  int _currentPoints = 0;
  int _completedMissions = 0; // 실제 미션 완료 개수
  int _totalMissions = 30; // 전체 미션 개수

  @override
  void initState() {
    super.initState();
    widget.missionData.addListener(_updateState);
    _loadUserData();
    
    // 목업 친구 데이터로 경쟁 상태 시작
    _setupMockCompetition();
  }

  // 목업 경쟁 데이터 설정
  void _setupMockCompetition() {
    // 5만원 목표금액을 가진 랜덤 친구 목업 데이터
    final mockFriendData = {
      'id': 'mock_friend_001',
      'name': '김친구',
      'profileImageUrl': 'https://picsum.photos/200/200?random=1',
      'targetAmount': 50000,
      'currentAmount': 35000,
      'entireCompleted': 18,
      'totalMissions': 30,
      'completionRate': 60.0,
      'rank': 2, // 친구가 2등 (사용자가 1등)
    };

    // 경쟁 상태로 설정
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _isCompeting = true;
          _competingFriendData = mockFriendData;
        });
        print('🎯 목업 경쟁 데이터 설정 완료: $mockFriendData');
      }
    });
  }

  @override
  void dispose() {
    widget.missionData.removeListener(_updateState);
    super.dispose();
  }

  void _updateState() {
    if (mounted) {
      setState(() {});
    }
  }

  // 사용자 데이터 로드
  Future<void> _loadUserData() async {
    try {
      // 사용자 정보 가져오기
      final userInfo = await AuthService.getUserInfo();

      // 현재 포인트 가져오기 (userInfo의 point 필드 또는 PaymentService 사용)
      int currentPoints = 0;
      if (userInfo.containsKey('point') && userInfo['point'] != null) {
        currentPoints = userInfo['point'] is int ? userInfo['point'] : 0;
      } else {
        // userInfo에 point가 없거나 null인 경우 PaymentService 사용
        currentPoints = await PaymentService.getUserPoints();
      }

      // 미션 완료 개수와 전체 미션 개수 가져오기
      final completedCount = await MissionService.getCompletedMissionCount();
      final totalCount = await MissionService.getTotalMissionCount();

      if (mounted) {
        setState(() {
          _userTargetAmount =
              userInfo['targetAmount'] is int ? userInfo['targetAmount'] : null;
          _userProfileImageUrl = AuthService.getFullProfileImageUrl(
            userInfo['profileImagePath'],
          );
          _userName = userInfo['name'] ?? '나';
          _currentPoints = currentPoints;
          _completedMissions = completedCount;
          _totalMissions = totalCount > 0 ? totalCount : 30; // 기본값 30개
          _isCheckingTargetAmount = false;
        });

        print('🎯 _loadUserData 완료:');
        print('   - targetAmount from API: ${userInfo['targetAmount']}');
        print('   - _userTargetAmount: $_userTargetAmount');
        print(
          '   - profileImagePath from API: ${userInfo['profileImagePath']}',
        );
        print('   - _userProfileImageUrl: $_userProfileImageUrl');
        print(
          '   - AuthService.getFullProfileImageUrl 결과: ${AuthService.getFullProfileImageUrl(userInfo['profileImagePath'])}',
        );
        print('   - _userName: $_userName');
        print('   - _currentPoints: $_currentPoints');
        print('   - _completedMissions: $_completedMissions');
        print('   - _totalMissions: $_totalMissions');
      }
    } catch (e) {
      print('사용자 데이터 로드 오류: $e');
      if (mounted) {
        setState(() {
          _userTargetAmount = null;
          _userProfileImageUrl = null;
          _userName = '나';
          _currentPoints = 0;
          _completedMissions = 0;
          _totalMissions = 30;
          _isCheckingTargetAmount = false;
        });
      }
    }
  }

  // 경쟁 시작 콜백
  void _startCompetition(Map<String, dynamic> friendData) {
    print('🎯 _startCompetition 호출됨');
    print('   - _userTargetAmount: $_userTargetAmount');
    print('   - friendData: $friendData');

    // 목표 금액이 설정되어 있는지 확인
    if (_userTargetAmount == null || _userTargetAmount! <= 0) {
      print('   - 목표 금액이 설정되지 않아서 경쟁 시작 안함');
      // 목표 금액이 설정되지 않았으면 경쟁 화면으로 가지 않고 목표 금액대 설정하기 섹션 유지
      return;
    }

    print('   - 경쟁 화면으로 전환 시도');
    if (mounted) {
      setState(() {
        _isCompeting = true;
        _competingFriendData = friendData;
      });
      print('   - 경쟁 화면 상태 설정 완료: _isCompeting=$_isCompeting');
    }
  }

  // 경쟁 종료 (뒤로가기)
  void _stopCompetition() {
    if (mounted) {
      setState(() {
        _isCompeting = false;
        _competingFriendData = null;
      });
    }
  }

  void _handleFindFriends(int amount) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // 로딩 화면으로 이동
      Navigator.of(context).push(
        MaterialPageRoute(
          builder:
              (context) => LoadingScreen(
                targetAmount: amount,
                onLoadingComplete: (friendData) async {
                  // 로딩 완료 시 결과 화면으로 이동
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder:
                          (context) => FriendsRankingScreen(
                            friendData: friendData,
                            targetAmount: amount,
                            onStartCompetition: _startCompetition, // 콜백 전달
                          ),
                    ),
                  );
                },
              ),
        ),
      );

      // 실제 API 호출 (백그라운드에서 실행)
      try {
        // 목표 금액대 설정 API 호출 (새로 설정하는 경우에만)
        if (_userTargetAmount == null || _userTargetAmount != amount) {
          final response = await MissionService.setTargetAmount(
            targetAmount: amount,
          );
          print('🎯 목표 금액 설정 응답: $response');

          // API 응답에서 바로 목표 금액 업데이트
          if (response != null && response.containsKey('targetAmount')) {
            setState(() {
              _userTargetAmount = response['targetAmount'];
            });
            print('🎯 목표 금액 업데이트 완료: $_userTargetAmount');
          } else {
            // 사용자 데이터 새로고침
            await _loadUserData();
          }
        }

        // 현재 사용자 정보 가져오기
        final userInfo = await AuthService.getUserInfo();
        final userId = userInfo['id'];

        if (userId != null) {
          // 현재 월 (yyyy-MM 형식)
          final now = DateTime.now();
          final currentMonth =
              '${now.year}-${now.month.toString().padLeft(2, '0')}';

          // 친구 비교 랭킹 조회 API 호출
          final rankingData = await MissionService.getFriendsRanking(
            targetId: userId,
            month: currentMonth,
          );

          print('실제 랭킹 데이터: $rankingData');
          // TODO: 실제 API 응답 데이터로 화면 업데이트
        }
      } catch (e) {
        print('API 호출 오류: $e');
        // 실제 API 오류는 로그만 남기고 더미 데이터로 진행
      }
    } catch (e) {
      if (mounted) {
        // 에러 메시지 표시
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '친구 찾기 중 오류가 발생했습니다: ${e.toString()}',
              style: const TextStyle(fontFamily: 'Pretendard-Regular'),
            ),
            backgroundColor: const Color(0xFFFF6B6B),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // 상세 비교 기능
  void _showDetailComparison() {
    if (_competingFriendData != null) {
      showSubjectComparisonBottomSheet(context, _competingFriendData!);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '비교할 친구 데이터가 없습니다.',
            style: TextStyle(fontFamily: 'Pretendard-Regular'),
          ),
          backgroundColor: Color(0xFFFF6B6B),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  // 친구 선택 기능
  void _showFriendSelection() {
    showFriendSelectionBottomSheet(
      context,
      onFriendSelected: (selectedFriend) {
        print('선택된 친구: $selectedFriend');
        
        // 선택된 친구와 경쟁 시작
        if (mounted) {
          setState(() {
            _isCompeting = true;
            _competingFriendData = selectedFriend;
          });
        }
        
        // 성공 메시지 표시
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${selectedFriend['name']}님과 경쟁이 시작되었습니다!',
              style: const TextStyle(
                fontFamily: 'Pretendard-Regular',
              ),
            ),
            backgroundColor: const Color(0xFF146AFF),
            duration: const Duration(seconds: 2),
          ),
        );
      },
    );
  }

  // 경쟁 상태 메시지 반환
  String _getCompetitionStatusMessage() {
    if (_competingFriendData == null) {
      return '경쟁 중...';
    }

    final friendCompletedMissions = _competingFriendData!['entireCompleted'] ?? 0;
    final friendTargetAmount = _competingFriendData!['targetAmount'] ?? 50000;
    final friendCurrentAmount = _competingFriendData!['currentAmount'] ?? 35000;
    
    // 미션 완료율 계산
    final userCompletionRate = _totalMissions > 0 ? (_completedMissions / _totalMissions) : 0.0;
    final friendCompletionRate = _totalMissions > 0 ? (friendCompletedMissions / _totalMissions) : 0.0;
    
    // 목표 달성률 계산
    final userTargetRate = _userTargetAmount != null && _userTargetAmount! > 0 
        ? (_currentPoints / _userTargetAmount!) : 0.0;
    final friendTargetRate = friendTargetAmount > 0 
        ? (friendCurrentAmount / friendTargetAmount) : 0.0;

    // 종합 점수 계산 (미션 완료율 50% + 목표 달성률 50%)
    final userScore = (userCompletionRate * 0.5) + (userTargetRate * 0.5);
    final friendScore = (friendCompletionRate * 0.5) + (friendTargetRate * 0.5);

    if (userScore > friendScore) {
      return '지금 내가 이기고 있어요! 💪';
    } else if (userScore < friendScore) {
      return '친구가 앞서가고 있어요! 화이팅! 🔥';
    } else {
      return '박빙승부! 막상막하예요! ⚡';
    }
  }

  // 경쟁 상태 색상 반환
  Color _getCompetitionStatusColor() {
    if (_competingFriendData == null) {
      return const Color(0xFF5D9EFF);
    }

    final friendCompletedMissions = _competingFriendData!['entireCompleted'] ?? 0;
    final friendTargetAmount = _competingFriendData!['targetAmount'] ?? 50000;
    final friendCurrentAmount = _competingFriendData!['currentAmount'] ?? 35000;
    
    // 미션 완료율 계산
    final userCompletionRate = _totalMissions > 0 ? (_completedMissions / _totalMissions) : 0.0;
    final friendCompletionRate = _totalMissions > 0 ? (friendCompletedMissions / _totalMissions) : 0.0;
    
    // 목표 달성률 계산
    final userTargetRate = _userTargetAmount != null && _userTargetAmount! > 0 
        ? (_currentPoints / _userTargetAmount!) : 0.0;
    final friendTargetRate = friendTargetAmount > 0 
        ? (friendCurrentAmount / friendTargetAmount) : 0.0;

    // 종합 점수 계산 (미션 완료율 50% + 목표 달성률 50%)
    final userScore = (userCompletionRate * 0.5) + (userTargetRate * 0.5);
    final friendScore = (friendCompletionRate * 0.5) + (friendTargetRate * 0.5);

    if (userScore > friendScore) {
      return const Color(0xFF5D9EFF); // 파란색 - 승리
    } else if (userScore < friendScore) {
      return const Color(0xFFFF6B6B); // 빨간색 - 뒤쳐짐
    } else {
      return const Color(0xFFFFB74D); // 주황색 - 동점
    }
  }

  // 경쟁 화면 위젯
  Widget _buildCompetitionView(
    double screenWidth,
    double containerWidth,
    double horizontalPadding,
  ) {
    return FutureBuilder<Map<String, dynamic>>(
      future: AuthService.getUserInfo(),
      builder: (context, snapshot) {
        String? correctProfileImageUrl;
        if (snapshot.hasData && snapshot.data != null) {
          correctProfileImageUrl = AuthService.getFullProfileImageUrl(
            snapshot.data!['profileImagePath'],
          );
          print('🖼️ 경쟁 화면에서 사용할 프로필 이미지 URL: $correctProfileImageUrl');
          print('🖼️ 기존 _userProfileImageUrl: $_userProfileImageUrl');
          print(
            '🖼️ 원본 profileImagePath: ${snapshot.data!['profileImagePath']}',
          );
        } else {
          correctProfileImageUrl = _userProfileImageUrl;
        }

        return _buildCompetitionContent(
          screenWidth,
          containerWidth,
          horizontalPadding,
          correctProfileImageUrl,
        );
      },
    );
  }

  // 경쟁 화면 내용 위젯
  Widget _buildCompetitionContent(
    double screenWidth,
    double containerWidth,
    double horizontalPadding,
    String? profileImageUrl,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Container(
        width: containerWidth,
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: const Color(0x35000000),
              blurRadius: 8,
              offset: const Offset(3, 4),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더 섹션
            Container(
              width: double.infinity,
              height: 71,
              child: Stack(
                children: [
                  Positioned(
                    left: 0,
                    top: 0,
                    child: Container(
                      width: containerWidth,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
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
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: double.infinity,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 8),
                                Container(
                                  width: double.infinity,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        '나와 같은 목표를 가진 친구 훔쳐보기',
                                        style: TextStyle(
                                          color: const Color(0xFF202020),
                                          fontSize: screenWidth > 600 ? 18 : 16,
                                          fontFamily: 'Pretendard-Bold',
                                          letterSpacing: -0.72,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  width: double.infinity,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        '같은 목표를 가진 친구의 진행 상황을 훔쳐보세요',
                                        style: TextStyle(
                                          color: const Color(0xFF999999),
                                          fontSize: screenWidth > 600 ? 14 : 12,
                                          fontFamily: 'Pretendard-Light',
                                          letterSpacing: -0.28,
                                        ),
                                      ),
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
                ],
              ),
            ),

            // 경쟁 내용 섹션
            Container(
              width: containerWidth,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: const BoxDecoration(color: Colors.white),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 8),

                        // 내 정보 카드
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: ShapeDecoration(
                            color: const Color(0xFFE4ECF8),
                            shape: RoundedRectangleBorder(
                              side: const BorderSide(
                                width: 0.40,
                                color: Color(0xFF5D9EFF),
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  const SizedBox(
                                    width: 30,
                                  ), // 프로필을 오른쪽으로 이동 (8에서 24로)
                                  // 프로필 섹션 (세로 정렬) - 오른쪽으로 이동
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width:
                                            screenWidth > 600
                                                ? 48
                                                : 40, // 크기 증가 (40→48, 32→40)
                                        height:
                                            screenWidth > 600
                                                ? 48
                                                : 40, // 크기 증가 (40→48, 32→40)
                                        decoration: const ShapeDecoration(
                                          shape: OvalBorder(
                                            side: BorderSide(
                                              width: 0.80,
                                              color: Color(0xFF146AFF),
                                            ),
                                          ),
                                        ),
                                        child: ClipOval(
                                          child:
                                              profileImageUrl != null &&
                                                      profileImageUrl!
                                                          .isNotEmpty
                                                  ? CachedNetworkImage(
                                                    imageUrl: profileImageUrl!,
                                                    fit: BoxFit.cover,
                                                    width:
                                                        screenWidth > 600
                                                            ? 48
                                                            : 40,
                                                    height:
                                                        screenWidth > 600
                                                            ? 48
                                                            : 40,
                                                    placeholder:
                                                        (
                                                          context,
                                                          url,
                                                        ) => Container(
                                                          width:
                                                              screenWidth > 600
                                                                  ? 48
                                                                  : 40,
                                                          height:
                                                              screenWidth > 600
                                                                  ? 48
                                                                  : 40,
                                                          color: const Color(
                                                            0xFFE0E0E0,
                                                          ),
                                                          child: const Center(
                                                            child: CircularProgressIndicator(
                                                              strokeWidth: 2,
                                                              valueColor:
                                                                  AlwaysStoppedAnimation<
                                                                    Color
                                                                  >(
                                                                    Color(
                                                                      0xFF146AFF,
                                                                    ),
                                                                  ),
                                                            ),
                                                          ),
                                                        ),
                                                    errorWidget: (
                                                      context,
                                                      url,
                                                      error,
                                                    ) {
                                                      print(
                                                        '🖼️ 프로필 이미지 로드 실패: $error',
                                                      );
                                                      print(
                                                        '🖼️ 이미지 URL: $url',
                                                      );
                                                      return Container(
                                                        width:
                                                            screenWidth > 600
                                                                ? 48
                                                                : 40,
                                                        height:
                                                            screenWidth > 600
                                                                ? 48
                                                                : 40,
                                                        color: const Color(
                                                          0xFFE0E0E0,
                                                        ),
                                                        child: Icon(
                                                          Icons.person,
                                                          size:
                                                              screenWidth > 600
                                                                  ? 28
                                                                  : 24,
                                                          color: const Color(
                                                            0xFF999999,
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                  )
                                                  : Container(
                                                    width:
                                                        screenWidth > 600
                                                            ? 48
                                                            : 40,
                                                    height:
                                                        screenWidth > 600
                                                            ? 48
                                                            : 40,
                                                    color: const Color(
                                                      0xFFE0E0E0,
                                                    ),
                                                    child: Icon(
                                                      Icons.person,
                                                      size:
                                                          screenWidth > 600
                                                              ? 28
                                                              : 24,
                                                      color: const Color(
                                                        0xFF999999,
                                                      ),
                                                    ),
                                                  ),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _userName,
                                        style: TextStyle(
                                          color: const Color(0xFF202020),
                                          fontSize:
                                              screenWidth > 600
                                                  ? 16
                                                  : 14, // 크기 증가 (12→16, 10→14)
                                          fontFamily:
                                              'Pretendard-Medium', // 폰트 굵기 증가
                                          letterSpacing: -0.24,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(
                                    width: 16,
                                  ), // 프로필과 미션박스 간격 조정 (12→16)
                                  // 진행률과 금액 섹션
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start, // 왼쪽 정렬로 변경
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        // 진행률 박스
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal:
                                                screenWidth > 600 ? 12 : 8,
                                            vertical: screenWidth > 600 ? 6 : 4,
                                          ),
                                          decoration: ShapeDecoration(
                                            color: const Color(0xFF3A88F4),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                          child: Text.rich(
                                            TextSpan(
                                              children: [
                                                TextSpan(
                                                  text: '$_completedMissions/',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize:
                                                        screenWidth > 600
                                                            ? 12
                                                            : 10,
                                                    fontFamily:
                                                        'Pretendard-Bold',
                                                    letterSpacing: -0.24,
                                                  ),
                                                ),
                                                TextSpan(
                                                  text: '${_totalMissions}개',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize:
                                                        screenWidth > 600
                                                            ? 12
                                                            : 10,
                                                    fontFamily:
                                                        'Pretendard-Light',
                                                    letterSpacing: -0.24,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(
                                          height: 10,
                                        ), // 간격 증가 (6→10)
                                        // 금액 (아래)
                                        Text.rich(
                                          TextSpan(
                                            children: [
                                              TextSpan(
                                                text:
                                                    '${_currentPoints.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}원',
                                                style: TextStyle(
                                                  color: const Color(
                                                    0xFF001F55,
                                                  ),
                                                  fontSize:
                                                      screenWidth > 600
                                                          ? 18
                                                          : 16, // 2px 증가 (16→18, 14→16)
                                                  fontFamily: 'Pretendard-Bold',
                                                  letterSpacing: -0.80,
                                                ),
                                              ),
                                              TextSpan(
                                                text:
                                                    _userTargetAmount != null
                                                        ? ' / ${_userTargetAmount!.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}원'
                                                        : '',
                                                style: TextStyle(
                                                  color: const Color(
                                                    0xFF999999,
                                                  ),
                                                  fontSize:
                                                      screenWidth > 600
                                                          ? 14
                                                          : 12, // 2px 증가 (12→14, 10→12)
                                                  fontFamily:
                                                      'Pretendard-Light',
                                                  letterSpacing: -0.28,
                                                ),
                                              ),
                                            ],
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                          textAlign:
                                              TextAlign.left, // 왼쪽 정렬로 변경
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                              ),
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // 승리 메시지
                        Container(
                          margin: EdgeInsets.symmetric(
                            horizontal: screenWidth > 600 ? 16 : 12,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // 경쟁 아이콘
                              Container(
                                width: screenWidth > 600 ? 32 : 28,
                                height: screenWidth > 600 ? 32 : 28,
                                decoration: const BoxDecoration(
                                  image: DecorationImage(
                                    image: AssetImage(
                                      "assets/icons/Icon/mission/compatiton.png",
                                    ),
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              // 승리 메시지 박스
                              Flexible(
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: screenWidth > 600 ? 16 : 12,
                                    vertical: screenWidth > 600 ? 10 : 8,
                                  ),
                                  decoration: ShapeDecoration(
                                    color: _getCompetitionStatusColor(),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    _getCompetitionStatusMessage(),
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: screenWidth > 600 ? 12 : 11,
                                      fontFamily: 'Pretendard-Medium',
                                      height: 1.3,
                                      letterSpacing: -0.22,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // 친구 정보 카드
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: ShapeDecoration(
                            color: const Color(0xFFE4ECF8),
                            shape: RoundedRectangleBorder(
                              side: const BorderSide(
                                width: 0.40,
                                color: Color(0xFF5D9EFF),
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  const SizedBox(
                                    width: 30,
                                  ), // 프로필을 오른쪽으로 이동 (8에서 24로)
                                  // 친구 프로필 섹션 (세로 정렬) - 오른쪽으로 이동
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width:
                                            screenWidth > 600
                                                ? 48
                                                : 40, // 크기 증가 (40→48, 32→40)
                                        height:
                                            screenWidth > 600
                                                ? 48
                                                : 40, // 크기 증가 (40→48, 32→40)
                                        decoration: const ShapeDecoration(
                                          shape: OvalBorder(
                                            side: BorderSide(
                                              width: 0.80,
                                              color: Color(0xFF146AFF),
                                            ),
                                          ),
                                        ),
                                        child: ClipOval(
                                          child: CachedNetworkImage(
                                            imageUrl: _competingFriendData?['profileImageUrl'] ??
                                                'https://picsum.photos/200/200?random=1',
                                            fit: BoxFit.cover,
                                            width: screenWidth > 600 ? 48 : 40,
                                            height: screenWidth > 600 ? 48 : 40,
                                            placeholder: (context, url) => Container(
                                              width: screenWidth > 600 ? 48 : 40,
                                              height: screenWidth > 600 ? 48 : 40,
                                              color: const Color(0xFFE0E0E0),
                                              child: const Center(
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor: AlwaysStoppedAnimation<Color>(
                                                    Color(0xFF146AFF),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            errorWidget: (context, url, error) {
                                              print('🖼️ 친구 프로필 이미지 로드 실패: $error');
                                              return Container(
                                                width: screenWidth > 600 ? 48 : 40,
                                                height: screenWidth > 600 ? 48 : 40,
                                                color: const Color(0xFFE0E0E0),
                                                child: Icon(
                                                  Icons.person,
                                                  size: screenWidth > 600 ? 28 : 24,
                                                  color: const Color(0xFF999999),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _competingFriendData?['name'] ?? '친구',
                                        style: TextStyle(
                                          color: const Color(0xFF202020),
                                          fontSize:
                                              screenWidth > 600
                                                  ? 16
                                                  : 14, // 크기 증가 (12→16, 10→14)
                                          fontFamily:
                                              'Pretendard-Medium', // 폰트 굵기 증가
                                          letterSpacing: -0.24,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(
                                    width: 16,
                                  ), // 프로필과 미션박스 간격 조정 (12→16)
                                  // 진행률과 금액 섹션
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start, // 왼쪽 정렬로 변경
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        // 진행률 박스
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal:
                                                screenWidth > 600 ? 12 : 8,
                                            vertical: screenWidth > 600 ? 6 : 4,
                                          ),
                                          decoration: ShapeDecoration(
                                            color: const Color(0xFF3A88F4),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                          child: Text.rich(
                                            TextSpan(
                                              children: [
                                                TextSpan(
                                                  text:
                                                      '${_competingFriendData?['entireCompleted'] ?? 12}/',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize:
                                                        screenWidth > 600
                                                            ? 12
                                                            : 10,
                                                    fontFamily:
                                                        'Pretendard-Bold',
                                                    letterSpacing: -0.24,
                                                  ),
                                                ),
                                                TextSpan(
                                                  text:
                                                      '${_competingFriendData?['totalMissions'] ?? _totalMissions}개',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize:
                                                        screenWidth > 600
                                                            ? 12
                                                            : 10,
                                                    fontFamily:
                                                        'Pretendard-Light',
                                                    letterSpacing: -0.24,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(
                                          height: 10,
                                        ), // 간격 증가 (6→10)
                                        // 금액 (아래)
                                        Text.rich(
                                          TextSpan(
                                            children: [
                                              TextSpan(
                                                text: '${(_competingFriendData?['currentAmount'] ?? 35000).toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}원',
                                                style: TextStyle(
                                                  color: const Color(
                                                    0xFF001F55,
                                                  ),
                                                  fontSize:
                                                      screenWidth > 600
                                                          ? 18
                                                          : 16, // 2px 증가 (16→18, 14→16)
                                                  fontFamily: 'Pretendard-Bold',
                                                  letterSpacing: -0.80,
                                                ),
                                              ),
                                              TextSpan(
                                                text:
                                                    ' / ${_competingFriendData?['targetAmount']?.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}원',
                                                style: TextStyle(
                                                  color: const Color(
                                                    0xFF999999,
                                                  ),
                                                  fontSize:
                                                      screenWidth > 600
                                                          ? 14
                                                          : 12, // 2px 증가 (12→14, 10→12)
                                                  fontFamily:
                                                      'Pretendard-Light',
                                                  letterSpacing: -0.28,
                                                ),
                                              ),
                                            ],
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                          textAlign:
                                              TextAlign.left, // 왼쪽 정렬로 변경
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                              ),
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 하단 버튼 섹션
            Container(
              width: containerWidth,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              decoration: const ShapeDecoration(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      // 친구 선택 버튼 (검색 아이콘)
                      GestureDetector(
                        onTap: _showFriendSelection,
                        child: Container(
                          width: 48,
                          height: 40,
                          decoration: ShapeDecoration(
                            color: const Color(0xFFE7ECF6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Center(
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: const BoxDecoration(
                                image: DecorationImage(
                                  image: AssetImage(
                                    "assets/icons/Icon/mission/search.png",
                                  ),
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // 상세 비교하기 버튼
                      Expanded(
                        child: GestureDetector(
                          onTap: _showDetailComparison,
                          child: Container(
                            height: 40,
                            decoration: ShapeDecoration(
                              color: const Color(0xFF3A88F4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '상세 비교하기',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: screenWidth > 600 ? 14 : 12,
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 화면 크기에 따른 반응형 너비 계산
    double screenWidth = MediaQuery.of(context).size.width;

    // 로딩 중이면 로딩 인디케이터 표시
    if (_isCheckingTargetAmount) {
      return LayoutBuilder(
        builder: (context, constraints) {
          double containerWidth;
          double horizontalPadding;

          if (screenWidth <= 600) {
            containerWidth = screenWidth - 32;
            horizontalPadding = 16;
          } else if (screenWidth <= 1024) {
            containerWidth = 600;
            horizontalPadding = (screenWidth - containerWidth) / 2;
          } else {
            containerWidth = 800;
            horizontalPadding = (screenWidth - containerWidth) / 2;
          }

          return Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Container(
              width: containerWidth,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0x35000000),
                    blurRadius: 8,
                    offset: const Offset(3, 4),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: const Center(
                child: CircularProgressIndicator(color: Color(0xFF3A88F4)),
              ),
            ),
          );
        },
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // 반응형 너비 계산
        double containerWidth;
        double horizontalPadding;

        if (screenWidth <= 600) {
          // 모바일: 전체 너비 사용
          containerWidth = screenWidth - 32;
          horizontalPadding = 16;
        } else if (screenWidth <= 1024) {
          // 태블릿: 최대 너비 제한
          containerWidth = 600;
          horizontalPadding = (screenWidth - containerWidth) / 2;
        } else {
          // 데스크톱: 더 큰 최대 너비
          containerWidth = 800;
          horizontalPadding = (screenWidth - containerWidth) / 2;
        }

        // 경쟁 상태이고 목표 금액이 설정되어 있으면 경쟁 화면 표시
        print('🎯 경쟁 화면 조건 체크:');
        print('   - _isCompeting: $_isCompeting');
        print(
          '   - _competingFriendData != null: ${_competingFriendData != null}',
        );
        print('   - _userTargetAmount: $_userTargetAmount');
        print(
          '   - _userTargetAmount! > 0: ${_userTargetAmount != null ? _userTargetAmount! > 0 : false}',
        );

        if (_isCompeting &&
            _competingFriendData != null &&
            _userTargetAmount != null &&
            _userTargetAmount! > 0) {
          print('🎯 경쟁 화면 표시!');
          return _buildCompetitionView(
            screenWidth,
            containerWidth,
            horizontalPadding,
          );
        } else {
          print('🎯 기본 섹션 표시');
        }

        // 기본 상태 - 원래 섹션
        // 목표 금액 설정 여부에 따른 버튼 텍스트 결정
        final bool hasTargetAmount =
            _userTargetAmount != null && _userTargetAmount! > 0;
        final String buttonText =
            hasTargetAmount ? '같은 목표를 가진 친구랑 비교하기' : '목표 금액대 설정하기';

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Container(
            width: containerWidth,
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: const Color(0x35000000),
                  blurRadius: 8,
                  offset: const Offset(3, 4),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 헤더 섹션
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
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
                      Text(
                        '나와 같은 목표를 가진 친구 훔쳐보기',
                        style: TextStyle(
                          color: const Color(0xFF202020),
                          fontSize: screenWidth > 600 ? 18 : 16,
                          fontFamily: 'Pretendard-Bold',
                          letterSpacing: -0.72,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        hasTargetAmount
                            ? '현재 목표 금액: ${_userTargetAmount!.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}원'
                            : '목표 금액대를 설정하고 친구와 경쟁해 보세요',
                        style: TextStyle(
                          color:
                              hasTargetAmount
                                  ? const Color(0xFF146AFF)
                                  : const Color(0xFF999999),
                          fontSize: screenWidth > 600 ? 14 : 12,
                          fontFamily:
                              hasTargetAmount
                                  ? 'Pretendard-Medium'
                                  : 'Pretendard-Light',
                          letterSpacing: -0.28,
                        ),
                      ),
                    ],
                  ),
                ),

                // 이미지 섹션
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(color: Colors.white),
                  child: Center(
                    child: Image.asset(
                      'assets/icons/my/mission_friend.png',
                      width: screenWidth > 600 ? 200 : 180,
                      height: screenWidth > 600 ? 200 : 180,
                      fit: BoxFit.contain,
                      errorBuilder:
                          (context, error, stackTrace) => Container(
                            width: screenWidth > 600 ? 200 : 180,
                            height: screenWidth > 600 ? 200 : 180,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.image,
                              size: 50,
                              color: Colors.grey[600],
                            ),
                          ),
                    ),
                  ),
                ),

                // 버튼 섹션
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 24,
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
                  child: SizedBox(
                    width: double.infinity,
                    child: InkWell(
                      onTap:
                          _isLoading
                              ? null
                              : () async {
                                if (hasTargetAmount) {
                                  // 이미 목표 금액이 설정된 경우 바로 친구 찾기
                                  _handleFindFriends(_userTargetAmount!);
                                } else {
                                  // 목표 금액이 설정되지 않은 경우 바텀 시트 표시
                                  final amount =
                                      await showGoalAmountSettingBottomSheet(
                                        context,
                                      );

                                  if (amount != null && mounted) {
                                    // 목표 금액 설정 API 호출
                                    final response =
                                        await MissionService.setTargetAmount(
                                          targetAmount: amount,
                                        );
                                    print('🎯 바텀시트 목표 금액 설정 응답: $response');

                                    // API 응답에서 바로 목표 금액 업데이트
                                    if (response != null &&
                                        response.containsKey('targetAmount')) {
                                      setState(() {
                                        _userTargetAmount =
                                            response['targetAmount'];
                                      });
                                      print(
                                        '🎯 바텀시트 목표 금액 업데이트 완료: $_userTargetAmount',
                                      );
                                    } else {
                                      // 사용자 데이터 새로고침
                                      await _loadUserData();
                                    }

                                    _handleFindFriends(amount);
                                  }
                                }
                              },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 12,
                        ),
                        decoration: ShapeDecoration(
                          color:
                              _isLoading
                                  ? const Color(0xFF9E9E9E)
                                  : const Color(0xFF3A88F4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Center(
                          child:
                              _isLoading
                                  ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : Text(
                                    buttonText,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: screenWidth > 600 ? 16 : 14,
                                      fontFamily: 'Pretendard-Light',
                                      letterSpacing: -0.28,
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
      },
    );
  }
}
