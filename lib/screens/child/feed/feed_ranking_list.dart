import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../services/auth_service.dart';
import '../../../services/mission_service.dart';
import '../../../services/relationship_service.dart';
import 'package:intl/intl.dart';

// 랭킹 데이터 모델
class RankingUser {
  final int friendUserId;
  final int? friendId;
  final String friendName;
  final int totalMissionCount;
  final int completedMissionCount;
  final double completionRate;
  final List<LearningStats> learningStats;
  final int habitMissionCount;
  final int habitCompletedCount;
  final double habitCompletionRate;
  final int learningMissionCount;
  final int learningCompletedCount;
  final double learningCompletionRate;
  final bool bestFriend;
  final bool isCurrentUser;
  final String? profileImagePath;
  final String? userRole; // 사용자 역할 추가

  RankingUser({
    required this.friendUserId,
    this.friendId,
    required this.friendName,
    required this.totalMissionCount,
    required this.completedMissionCount,
    required this.completionRate,
    required this.learningStats,
    required this.habitMissionCount,
    required this.habitCompletedCount,
    required this.habitCompletionRate,
    required this.learningMissionCount,
    required this.learningCompletedCount,
    required this.learningCompletionRate,
    required this.bestFriend,
    this.isCurrentUser = false,
    this.profileImagePath,
    this.userRole, // 사용자 역할 추가
  });

  factory RankingUser.fromJson(Map<String, dynamic> json) {
    return RankingUser(
      friendUserId: json['friendUserId'] ?? 0,
      friendId: json['friendId'],
      friendName: json['friendName'] ?? '',
      totalMissionCount: json['totalMissionCount'] ?? 0,
      completedMissionCount: json['completedMissionCount'] ?? 0,
      completionRate: (json['completionRate'] ?? 0.0).toDouble(),
      learningStats:
          (json['learningStats'] as List<dynamic>? ?? [])
              .map((stats) => LearningStats.fromJson(stats))
              .toList(),
      habitMissionCount: json['habitMissionCount'] ?? 0,
      habitCompletedCount: json['habitCompletedCount'] ?? 0,
      habitCompletionRate: (json['habitCompletionRate'] ?? 0.0).toDouble(),
      learningMissionCount: json['learningMissionCount'] ?? 0,
      learningCompletedCount: json['learningCompletedCount'] ?? 0,
      learningCompletionRate:
          (json['learningCompletionRate'] ?? 0.0).toDouble(),
      bestFriend: json['bestFriend'] ?? false,
      isCurrentUser: json['friendId'] == null, // friendId가 null이면 현재 사용자
      profileImagePath: json['profileImagePath'],
      userRole: json['userRole'] ?? json['role'], // 사용자 역할 추가
    );
  }

  // 아이 역할인지 확인하는 메서드
  bool get isChild => userRole == 'CHILD' || userRole == null; // null인 경우 기본적으로 아이로 간주
  
  // 부모 역할인지 확인하는 메서드  
  bool get isParent => userRole == 'PARENT';
}

class LearningStats {
  final String subject;
  final int totalSubjectMissionCount;
  final int completedSubjectMissionCount;
  final double subjectCompletionRate;

  LearningStats({
    required this.subject,
    required this.totalSubjectMissionCount,
    required this.completedSubjectMissionCount,
    required this.subjectCompletionRate,
  });

  factory LearningStats.fromJson(Map<String, dynamic> json) {
    return LearningStats(
      subject: json['subject'] ?? '',
      totalSubjectMissionCount: json['totalSubjectMissionCount'] ?? 0,
      completedSubjectMissionCount: json['completedSubjectMissionCount'] ?? 0,
      subjectCompletionRate: (json['subjectCompletionRate'] ?? 0.0).toDouble(),
    );
  }
}

class RankingList extends StatefulWidget {
  final int totalUsers;
  final bool hideFloatingButton;

  const RankingList({
    super.key,
    this.totalUsers = 20,
    this.hideFloatingButton = true,
  });

  @override
  State<RankingList> createState() => _RankingListState();
}

class _RankingListState extends State<RankingList>
    with TickerProviderStateMixin {
  bool _isWeeklyRanking = true; // true: 주별 랭킹, false: 일별 랭킹
  bool _isFilterFriends = true; // true: 친한 친구, false: 전체
  bool _isHelpVisible = false; // 도움말 말풍선 표시 여부
  bool _showMyRank = false; // 내 랭킹 상세 표시 여부
  Map<String, dynamic>? _userInfo; // 로그인한 사용자 정보
  ScrollController _scrollController = ScrollController();

  // 랭킹 데이터
  List<RankingUser> _rankingUsers = [];
  RankingUser? _currentUser;
  bool _isLoading = true;
  String? _errorMessage;

  // 프로필 이미지 캐시 (사용자 ID별로 저장)
  Map<int, String?> _profileImageCache = {};

  // 현재 주차 정보 가져오기
  String get _currentWeekInfo {
    final now = DateTime.now();
    final month = DateFormat('M').format(now); // 현재 월

    // 현재 날짜가 몇 주차인지 계산
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final weekDay = firstDayOfMonth.weekday;
    final weekOfMonth = ((now.day + weekDay - 2) ~/ 7) + 1;

    return '$month월 ${weekOfMonth}주차 랭킹';
  }

  @override
  void initState() {
    super.initState();
    // 상단 상태바 스타일 설정 (투명하게)
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    _loadUserInfo(); // 유저 정보 로드
    _loadRankingData(); // 랭킹 데이터 로드
  }

  // 사용자 정보 로드 (아이 역할 확인)
  Future<void> _loadUserInfo() async {
    try {
      final userInfo = await AuthService.getUserInfo();
      
      // 🔒 현재 사용자가 아이 역할인지 확인
      final userRole = userInfo?['role'] as String?;
      if (userRole == 'PARENT') {
        print('🚫 부모 역할 사용자는 랭킹 화면에 접근할 수 없습니다.');
        setState(() {
          _errorMessage = '랭킹은 아이들만 이용할 수 있는 기능입니다.';
        });
        return;
      }
      
      setState(() {
        _userInfo = userInfo;
      });
      print('✅ 현재 로그인 사용자 (아이): ${_userInfo?['name'] ?? '정보 없음'} (role: ${userRole ?? 'null'})');
    } catch (e) {
      print('❌ 사용자 정보 로드 실패: $e');
      setState(() {
        _errorMessage = '사용자 정보를 불러올 수 없습니다.';
      });
    }
  }

  // 랭킹 데이터 로드
  Future<void> _loadRankingData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // 프로필 이미지 캐시 초기화 (새로운 데이터 로드 시)
    _profileImageCache.clear();

    try {
      final rankingData = await MissionService.getRanking(
        pageNumber: 0,
        range: _isWeeklyRanking ? 'WEEK' : 'TWO_WEEKS', // 일별은 TWO_WEEKS로 임시 설정
      );

      if (rankingData != null) {
        await _processRankingData(rankingData);
      } else {
        setState(() {
          _errorMessage = '랭킹 데이터를 불러올 수 없습니다.';
        });
      }
    } catch (e) {
      print('랭킹 데이터 로드 실패: $e');
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 랭킹 데이터 처리 (부모 역할 사용자 제외)
  Future<void> _processRankingData(Map<String, dynamic> rankingData) async {
    List<RankingUser> users = [];
    RankingUser? currentUser;

    // 기간별 데이터에서 사용자 목록 추출 (WEEK 데이터 우선 사용)
    String period = _isWeeklyRanking ? 'WEEK' : 'TWO_WEEKS';

    // 사용 가능한 기간 데이터 중 첫 번째 사용
    String? availablePeriod;
    for (String key in rankingData.keys) {
      if (rankingData[key] is List && (rankingData[key] as List).isNotEmpty) {
        availablePeriod = key;
        break;
      }
    }

    if (availablePeriod != null) {
      final userList = rankingData[availablePeriod] as List<dynamic>;
      int totalUsers = userList.length;
      int filteredParents = 0;

      print('🎯 랭킹 데이터 처리 시작: $availablePeriod, 총 ${userList.length}명');

      for (var userData in userList) {
        final user = RankingUser.fromJson(userData);
        
        // 🔒 개별 사용자 역할 확인을 위한 추가 API 호출
        String? actualUserRole;
        try {
          final userInfo = await RelationshipService.getUserInfo(user.friendUserId);
          actualUserRole = userInfo?['role'] as String?;
          print('🔍 사용자 ${user.friendName} (ID: ${user.friendUserId}) 실제 역할: $actualUserRole');
        } catch (e) {
          print('⚠️ 사용자 ${user.friendUserId} 역할 확인 실패: $e');
          actualUserRole = user.userRole; // 기본값 사용
        }

        // 🚫 부모 역할 사용자는 랭킹에서 제외 (실제 역할 기준)
        if (actualUserRole == 'PARENT') {
          filteredParents++;
          print('❌ 부모 역할 사용자 제외: ${user.friendName} (userId: ${user.friendUserId}, 실제역할: $actualUserRole)');
          continue;
        }

        // 💰 실제 보상받은 미션 개수 계산 (현재 사용자인 경우)
        int actualRewardedMissionCount = user.completedMissionCount; // 기본값
        if (user.isCurrentUser) {
          try {
            actualRewardedMissionCount = await _getRewardedMissionCount(user.friendUserId);
            print('💰 현재 사용자 ${user.friendName} 보상받은 미션: $actualRewardedMissionCount개');
          } catch (e) {
            print('⚠️ 현재 사용자 보상받은 미션 개수 계산 실패: $e');
          }
                 } else {
           // 다른 사용자들도 보상받은 미션 개수 계산
           try {
             actualRewardedMissionCount = await _getRewardedMissionCountForUser(
               user.friendUserId, 
               user.completedMissionCount, // 서버에서 제공한 기본값 사용
             );
             print('💰 사용자 ${user.friendName} 보상받은 미션: $actualRewardedMissionCount개');
           } catch (e) {
             print('⚠️ 사용자 ${user.friendUserId} 보상받은 미션 개수 계산 실패: $e');
             // 실패 시 기본값 유지
           }
         }

        // ✅ 아이 역할 사용자만 랭킹에 포함
        print('✅ 아이 역할 사용자 포함: ${user.friendName} (userId: ${user.friendUserId}, 실제역할: $actualUserRole, 보상받은미션: $actualRewardedMissionCount개)');
        
        // 실제 역할과 보상받은 미션 개수로 업데이트된 사용자 객체 생성
        final updatedUser = RankingUser(
          friendUserId: user.friendUserId,
          friendId: user.friendId,
          friendName: user.friendName,
          totalMissionCount: user.totalMissionCount,
          completedMissionCount: actualRewardedMissionCount, // 🎯 보상받은 미션 개수로 업데이트
          completionRate: user.totalMissionCount > 0 
              ? (actualRewardedMissionCount / user.totalMissionCount * 100).clamp(0.0, 100.0)
              : 0.0, // 완료율도 재계산
          learningStats: user.learningStats,
          habitMissionCount: user.habitMissionCount,
          habitCompletedCount: user.habitCompletedCount,
          habitCompletionRate: user.habitCompletionRate,
          learningMissionCount: user.learningMissionCount,
          learningCompletedCount: user.learningCompletedCount,
          learningCompletionRate: user.learningCompletionRate,
          bestFriend: user.bestFriend,
          isCurrentUser: user.isCurrentUser,
          profileImagePath: user.profileImagePath,
          userRole: actualUserRole, // 실제 확인된 역할 사용
        );
        
        users.add(updatedUser);

        if (updatedUser.isCurrentUser) {
          currentUser = updatedUser;
          print('👤 현재 사용자 확인: ${updatedUser.friendName}');
        }

        // 친구들의 프로필 이미지 개별 로드 (현재 사용자가 아닌 경우만)
        if (!updatedUser.isCurrentUser) {
          _fetchUserProfileImage(updatedUser.friendUserId);
        }
      }

      // 필터링 결과 로깅
      print('🎯 랭킹 필터링 완료 (실제 역할 기준):');
      print('   - 전체 수신 데이터: $totalUsers명');
      print('   - 제외된 부모 사용자: $filteredParents명');
      print('   - 최종 랭킹 참여자: ${users.length}명 (아이들만)');

      // 🏆 보상받은 미션 개수를 기준으로 내림차순 정렬
      users.sort((a, b) {
        // 1순위: 보상받은 미션 개수 (completedMissionCount) 내림차순
        int missionComparison = b.completedMissionCount.compareTo(a.completedMissionCount);
        if (missionComparison != 0) {
          return missionComparison;
        }
        
        // 2순위: 완료율 내림차순
        int rateComparison = b.completionRate.compareTo(a.completionRate);
        if (rateComparison != 0) {
          return rateComparison;
        }
        
        // 3순위: 이름 오름차순 (동점자 처리)
        return a.friendName.compareTo(b.friendName);
      });

      print('🏆 랭킹 정렬 완료:');
      for (int i = 0; i < users.length && i < 5; i++) {
        print('   ${i + 1}위: ${users[i].friendName} (보상받은미션: ${users[i].completedMissionCount}개, 완료율: ${users[i].completionRate.toStringAsFixed(1)}%)');
      }
    }

    setState(() {
      _rankingUsers = users;
      _currentUser = currentUser;
    });

    print(
      '✅ 랭킹 데이터 처리 완료: ${users.length}명 (아이들만), 내 정보: ${currentUser?.friendName ?? '없음'}',
    );
  }

  // 개별 사용자 프로필 이미지 가져오기 (부모 역할 사용자 제외)
  Future<void> _fetchUserProfileImage(int userId) async {
    // 이미 캐시에 있으면 건너뛰기
    if (_profileImageCache.containsKey(userId)) {
      return;
    }

    try {
      print('👤 사용자 $userId 프로필 이미지 조회 중...');

      final result = await RelationshipService.getUserInfo(userId);

      if (result != null && !result.containsKey('notFound')) {
        // 🔒 사용자 역할 확인 - 부모인 경우 프로필 이미지 로드 생략
        final userRole = result['role'] as String?;
        if (userRole == 'PARENT') {
          print('🚫 부모 역할 사용자 프로필 이미지 로드 생략: userId $userId');
          _profileImageCache[userId] = null;
          return;
        }

        // ✅ 아이 역할 사용자의 프로필 이미지만 로드
        String? profileImagePath = result['profileImagePath'];

        // 캐시에 저장
        _profileImageCache[userId] = profileImagePath;

        // UI 업데이트 (mounted 체크)
        if (mounted) {
          setState(() {
            // 상태 업데이트로 이미지 다시 로드
          });
        }

        print(
          '✅ 아이 사용자 $userId 프로필 이미지 ${profileImagePath != null ? "로드 성공" : "없음"} (role: ${userRole ?? 'null'})',
        );
      } else {
        // 캐시에 null로 저장하여 다시 시도하지 않도록 함
        _profileImageCache[userId] = null;
        print('❌ 사용자 $userId 정보 없음');
      }
    } catch (e) {
      print('❌ 사용자 $userId 프로필 이미지 조회 실패: $e');
      // 오류 발생 시에도 null로 저장
      _profileImageCache[userId] = null;
    }
  }

  // 현재 사용자의 보상받은 미션 개수 계산
  Future<int> _getRewardedMissionCount(int userId) async {
    try {
      print('💰 현재 사용자(ID: $userId) 보상받은 미션 개수 계산 시작');
      
      // 현재 사용자의 모든 미션 조회
      final missionData = await MissionService.getChildMissions(page: 0);
      if (missionData == null || !missionData.containsKey('data')) {
        print('💰 미션 데이터를 가져올 수 없음');
        return 0;
      }

      final List<dynamic> missions = missionData['data'] ?? [];
      int rewardedCount = 0;

      for (final missionJson in missions) {
        if (missionJson is Map<String, dynamic>) {
          final isRewarded = missionJson['isRewarded'] ?? false;
          final status = missionJson['status'] ?? '';
          final missionTitle = missionJson['title'] ?? '제목없음';

          // 보상받은 미션만 카운트 (ACHIEVEMENT 상태이면서 isRewarded가 true인 경우)
          if (isRewarded && (status == 'ACHIEVEMENT' || status == 'ACCEPT')) {
            rewardedCount++;
            print('💰 보상받은 미션 발견: $missionTitle (상태: $status)');
          }
        }
      }

      print('💰 현재 사용자 보상받은 미션 총 개수: $rewardedCount개 (전체 미션: ${missions.length}개)');
      return rewardedCount;
    } catch (e) {
      print('💰 보상받은 미션 개수 계산 실패: $e');
      return 0;
    }
  }

  // 다른 사용자의 보상받은 미션 개수 계산 (제한적)
  Future<int> _getRewardedMissionCountForUser(int userId, int defaultCount) async {
    try {
      print('💰 다른 사용자(ID: $userId) 보상받은 미션 개수 계산 시작');
      
      // 다른 사용자의 미션 데이터는 직접 접근할 수 없으므로 
      // 일단 서버에서 제공한 기본값을 사용 (추후 서버 API 개선 필요)
      print('💰 다른 사용자의 미션 데이터는 접근 불가 - 서버 제공 값 사용: $defaultCount개');
      return defaultCount;
      
      // TODO: 추후 서버에서 다른 사용자의 보상받은 미션 개수를 제공하는 API가 추가되면 구현
    } catch (e) {
      print('💰 다른 사용자 보상받은 미션 개수 계산 실패: $e');
      return defaultCount; // 실패 시에도 기본값 반환
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _profileImageCache.clear(); // 프로필 이미지 캐시 정리
    super.dispose();
  }

  // 탭 전환 함수
  void _toggleRankingType(bool isWeekly) {
    if (isWeekly == _isWeeklyRanking) return;

    setState(() {
      _isWeeklyRanking = isWeekly;
    });

    _loadRankingData(); // 데이터 다시 로드
  }

  // 내 랭킹으로 이동
  void _scrollToMyRank() {
    // 내 랭킹 화면으로 전환
    setState(() {
      _showMyRank = true;
    });
  }

  // 원래 화면으로 돌아가기
  void _returnToFullRanking() {
    setState(() {
      _showMyRank = false;
    });
  }

  // 내 랭킹 찾기 (아이들 중에서만)
  int _getMyRankPosition() {
    if (_currentUser == null) return -1;

    // 🔒 아이 역할 사용자들만 필터링해서 랭킹 계산
    final childOnlyUsers = _rankingUsers
        .where((user) => user.isChild)
        .toList();

    for (int i = 0; i < childOnlyUsers.length; i++) {
      if (childOnlyUsers[i].isCurrentUser) {
        print('👤 내 랭킹 위치: ${i + 1}위 (아이들 중 ${childOnlyUsers.length}명 중)');
        return i + 1; // 1부터 시작하는 순위
      }
    }
    
    print('❌ 내 랭킹 위치를 찾을 수 없습니다.');
    return -1;
  }

  // 상위 3명 가져오기 (아이들만)
  List<RankingUser> _getTopThreeUsers() {
    return _rankingUsers
        .where((user) => user.isChild) // 🔒 아이 역할만 필터링
        .take(3)
        .toList();
  }

  // 4등부터의 사용자 가져오기 (아이들만)
  List<RankingUser> _getOtherUsers() {
    final childOnlyUsers = _rankingUsers
        .where((user) => user.isChild) // 🔒 아이 역할만 필터링
        .toList();
        
    if (childOnlyUsers.length <= 3) return [];
    return childOnlyUsers.skip(3).toList();
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    final double statusBarHeight = MediaQuery.of(context).viewPadding.top;

    return Scaffold(
      // 배경색 설정 - 파란색으로 변경
      backgroundColor: const Color(0xFF5D9EFF),
      // 앱바 비활성화
      appBar: null,
      // 상태바 영역까지 확장
      extendBodyBehindAppBar: true,
      // 하단 네비게이션 바 비활성화 (FeedScreen에서 처리)
      bottomNavigationBar: null,
      // 전체 레이아웃을 Stack으로 구성
      body:
          _isLoading
              ? _buildLoadingWidget()
              : _errorMessage != null
              ? _buildErrorWidget()
              : _buildMainContent(screenWidth, screenHeight),
    );
  }

  // 로딩 위젯
  Widget _buildLoadingWidget() {
    return Container(
      color: const Color(0xFF5D9EFF),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            SizedBox(height: 16),
            Text(
              '랭킹 데이터를 불러오는 중...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontFamily: 'Pretendard-Medium',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 오류 위젯
  Widget _buildErrorWidget() {
    return Container(
      color: const Color(0xFF5D9EFF),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.white, size: 48),
            SizedBox(height: 16),
            Text(
              _errorMessage ?? '오류가 발생했습니다.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontFamily: 'Pretendard-Medium',
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadRankingData,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF5D9EFF),
              ),
              child: Text(
                '다시 시도',
                style: TextStyle(fontFamily: 'Pretendard-Medium'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 메인 콘텐츠
  Widget _buildMainContent(double screenWidth, double screenHeight) {
    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.none,
      children: [
        // 배경 레이어
        Transform.translate(
          offset: Offset(0, -8),
          child: Container(
            width: double.infinity,
            height: screenHeight + 14,
            color: const Color(0xFF5D9EFF),
          ),
        ),

        // 상단 콘텐츠 영역 (고정 영역)
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 주별 랭킹 정보 표시
              Container(
                width: double.infinity,
                margin: EdgeInsets.only(top: 0, bottom: 0, left: 24, right: 16),
                padding: EdgeInsets.only(top: 4),
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      _currentWeekInfo,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontFamily: 'Pretendard-Bold',
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),

                    SizedBox(width: 8),

                    // 도움말 버튼
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isHelpVisible = !_isHelpVisible;
                        });
                      },
                      child: Image.asset(
                        "assets/icons/Icon/feed/랭킹_도움말.png",
                        width: 20,
                        height: 20,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                ),
              ),

              // 내 랭킹 상세보기 상태에 따라 다른 UI 표시
              if (_showMyRank) ...[
                // 내 랭킹 카드만 표시
                Padding(
                  padding: EdgeInsets.only(top: 20),
                  child: _buildMyRankCard(),
                ),
                const SizedBox(height: 20),
              ] else ...[
                // 메달리스트 영역 (1위, 2위, 3위) - 가로 정렬
                Container(
                  margin: EdgeInsets.only(top: 15, bottom: 4),
                  height: 180,
                  child: _buildTopRankers(),
                ),

                // 경쟁 중인 친구들 정보 컨테이너
                _buildFriendsInfoContainer(),
                const SizedBox(height: 8),
              ],
            ],
          ),
        ),

        // 도움말 말풍선 - 스택 위에 표시하도록 추가
        if (_isHelpVisible) _buildHelpBubble(),

        // 랭킹 리스트 컨테이너
        Positioned(
          top: _showMyRank ? screenHeight * 0.23 : screenHeight * 0.34,
          left: 0,
          right: 0,
          bottom: -200,
          child: Material(
            color: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFB3D2FF),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
              ),
              child: Column(
                children: [
                  // 친한 친구만 보기 체크박스
                  Padding(
                    padding: EdgeInsets.only(left: 16, top: 8),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Transform.scale(
                            scale: 0.9,
                            child: Checkbox(
                              value: _isFilterFriends,
                              onChanged: (value) {
                                setState(() {
                                  _isFilterFriends = value ?? true;
                                });
                              },
                              activeColor: const Color(0xFF5D9EFF),
                              checkColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                          Text(
                            '친한 친구만 보기',
                            style: TextStyle(
                              color: const Color(0xFF5D9EFF),
                              fontSize: 12,
                              fontFamily: 'Pretendard-Light',
                              fontWeight: FontWeight.w300,
                              letterSpacing: -0.24,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 랭킹 목록
                  Expanded(child: _buildRankingList()),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // 상위 랭커들 위젯
  Widget _buildTopRankers() {
    final topUsers = _getTopThreeUsers();

    if (topUsers.isEmpty) {
      return Center(
        child: Text(
          '랭킹 데이터가 없습니다.',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontFamily: 'Pretendard-Medium',
          ),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 1위
        if (topUsers.length > 0)
          _buildTopRankCard(
            rank: 1,
            user: topUsers[0],
            medalImage: "assets/icons/Icon/feed/gold_medal.png",
            height: 170,
          ),

        if (topUsers.length > 1) SizedBox(width: 6),

        // 2위
        if (topUsers.length > 1)
          _buildTopRankCard(
            rank: 2,
            user: topUsers[1],
            medalImage: "assets/icons/Icon/feed/silver_medal.png",
            height: 170,
          ),

        if (topUsers.length > 2) SizedBox(width: 6),

        // 3위
        if (topUsers.length > 2)
          _buildTopRankCard(
            rank: 3,
            user: topUsers[2],
            medalImage: "assets/icons/Icon/feed/bronze_medal.png",
            height: 170,
          ),
      ],
    );
  }

  // 친구들 정보 컨테이너 (아이들만)
  Widget _buildFriendsInfoContainer() {
    final totalFriends = _rankingUsers
        .where((user) => !user.isCurrentUser && user.isChild) // 🔒 아이 역할이면서 현재 사용자가 아닌 경우만
        .length;

    return Container(
      width: 350,
      height: 52,
      margin: EdgeInsets.only(bottom: 2, top: 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      clipBehavior: Clip.antiAlias,
      decoration: ShapeDecoration(
        color: Colors.white.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          side: BorderSide(width: 0.80, color: Colors.white),
          borderRadius: BorderRadius.circular(40),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 왼쪽: 프로필 이미지와 텍스트
          Row(
            children: [
              // 겹치는 프로필 이미지
              SizedBox(
                width: 48,
                height: 24,
                child: Stack(children: _buildOverlappingProfiles()),
              ),

              SizedBox(width: 8),

              // 텍스트
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '${totalFriends}명의 친구들',
                      style: TextStyle(
                        color: const Color(0xFF001F55),
                        fontSize: 12,
                        fontFamily: 'Pretendard-Medium',
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.24,
                      ),
                    ),
                    TextSpan(
                      text: ' 사이 내 랭킹은?',
                      style: TextStyle(
                        color: const Color(0xFF4A4A4A),
                        fontSize: 11,
                        fontFamily: 'Pretendard-Light',
                        fontWeight: FontWeight.w300,
                        letterSpacing: -0.24,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // 오른쪽: 바로가기 버튼
          GestureDetector(
            onTap: _scrollToMyRank,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '바로 가기',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontFamily: 'Pretendard-Light',
                    fontWeight: FontWeight.w300,
                    letterSpacing: -0.24,
                  ),
                ),
                SizedBox(width: 2),
                Icon(Icons.arrow_forward_ios, color: Colors.white, size: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 겹치는 프로필 이미지들
  List<Widget> _buildOverlappingProfiles() {
    final topUsers = _getTopThreeUsers();
    List<Widget> profiles = [];

    for (int i = 0; i < 3 && i < topUsers.length; i++) {
      profiles.add(
        Positioned(
          left: i * 12.0,
          child: Container(
            width: 24,
            height: 24,
            decoration: ShapeDecoration(
              image: DecorationImage(
                image: _getProfileImageFromUser(topUsers[i]),
                fit: BoxFit.cover,
              ),
              shape: OvalBorder(
                side: BorderSide(width: 0.80, color: const Color(0xFF146AFF)),
              ),
            ),
          ),
        ),
      );
    }

    return profiles;
  }

  // 랭킹 리스트 (아이들만 표시)
  Widget _buildRankingList() {
    final otherUsers = _getOtherUsers();
    
    // 🔒 부모 역할 사용자를 한 번 더 필터링 (이중 안전장치)
    final childOnlyUsers = otherUsers.where((user) => user.isChild).toList();
    
    final filteredUsers =
        _isFilterFriends
            ? childOnlyUsers
                .where((user) => user.bestFriend || user.isCurrentUser)
                .toList()
            : childOnlyUsers;

    print('🎯 랭킹 리스트 빌드:');
    print('   - 전체 사용자: ${otherUsers.length}명');
    print('   - 아이만 필터링: ${childOnlyUsers.length}명');
    print('   - 최종 표시: ${filteredUsers.length}명 (친구 필터: $_isFilterFriends)');

    if (filteredUsers.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            _isFilterFriends ? '친한 친구가 없습니다.' : '랭킹 데이터가 없습니다.',
            style: TextStyle(
              color: const Color(0xFF5D9EFF),
              fontSize: 16,
              fontFamily: 'Pretendard-Medium',
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.only(top: 0, bottom: 200),
      physics: const BouncingScrollPhysics(),
      itemCount:
          _showMyRank ? (_currentUser != null ? 1 : 0) : filteredUsers.length,
      itemBuilder: (context, index) {
        if (_showMyRank) {
          if (_currentUser != null) {
            final myRank = _getMyRankPosition();
            return _buildRankingItem(
              _currentUser!,
              myRank,
              isHighlighted: true,
            );
          }
          return SizedBox.shrink();
        }

        final user = filteredUsers[index];
        final rank = _rankingUsers.indexOf(user) + 1;
        
        // 🔒 마지막 안전장치: 부모 역할 사용자는 렌더링하지 않음
        if (user.isParent) {
          print('🚫 부모 역할 사용자 렌더링 차단: ${user.friendName}');
          return SizedBox.shrink();
        }
        
        return _buildRankingItem(user, rank, isHighlighted: user.isCurrentUser);
      },
    );
  }

  // 상위 랭킹 카드 위젯 (1,2,3등)
  Widget _buildTopRankCard({
    required int rank,
    required RankingUser user,
    required String medalImage,
    double height = 110,
  }) {
    return SizedBox(
      width: 105, // 너비 키움
      height: height, // 전달받은 높이 사용
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 105, // 너비 키움
          height: height - 10, // 내부 컨테이너 높이 조정
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          decoration: ShapeDecoration(
            color: Colors.white.withOpacity(0.3),
            shape: RoundedRectangleBorder(
              side: BorderSide(width: 0.60, color: Colors.white),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly, // 균등하게 배치
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 프로필 이미지
              Container(
                width: 44, // 크기 키움 (38 -> 60)
                height: 44, // 크기 키움 (38 -> 60)
                decoration: ShapeDecoration(
                  image: DecorationImage(
                    image: _getProfileImageFromUser(user),
                    fit: BoxFit.cover,
                  ),
                  shape: OvalBorder(
                    side: BorderSide(
                      width: 1.5, // 테두리 두께 키움
                      color: const Color(0xFF146AFF),
                    ),
                  ),
                ),
              ),

              // 메달 이미지
              SizedBox(
                width: 30, // 크기 키움 (24 -> 30)
                height: 30, // 크기 키움 (24 -> 30)
                child: Image.asset(medalImage, fit: BoxFit.contain),
              ),

              // 학년과 이름
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 학년 표시
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 2,
                      vertical: 1,
                    ),
                    decoration: ShapeDecoration(
                      color: const Color(0xFFEFF2F6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          "assets/icons/Icon/feed/순위.png",
                          width: 7, // 크기 조정
                          height: 7, // 크기 조정
                        ),
                        SizedBox(width: 1),
                        Text(
                          user.isCurrentUser ? '1' : '8', // 내 학년
                          style: TextStyle(
                            color: const Color(0xFF3A88F4),
                            fontSize: 9, // 폰트 크기 조정
                            fontFamily: 'Pretendard-Medium',
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 2),
                  // 이름
                  Text(
                    user.friendName,
                    style: TextStyle(
                      color: const Color(0xFF202020),
                      fontSize: 10, // 폰트 크기 조정
                      fontFamily: 'Pretendard-Bold',
                      overflow: TextOverflow.ellipsis,
                    ),
                    maxLines: 1,
                  ),
                ],
              ),

              // 달성 정보
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: ShapeDecoration(
                  color: const Color(0xFFFFD27F),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: Text(
                  '${user.completedMissionCount}개 달성',
                  style: TextStyle(
                    color: const Color(0xFF001F55),
                    fontSize: 9, // 폰트 크기 조정
                    fontFamily: 'Pretendard-Medium',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 랭킹 아이템 빌드 메서드 수정
  Widget _buildRankingItem(
    RankingUser user,
    int rank, {
    bool isHighlighted = false,
  }) {
    // 현재 사용자 여부
    bool isCurrentUser = user.isCurrentUser;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
      margin: EdgeInsets.symmetric(vertical: 3, horizontal: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color:
            (isCurrentUser || isHighlighted) ? const Color(0xFFE5EDFF) : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1. 왼쪽 숫자
          Container(
            width: 24,
            margin: EdgeInsets.only(right: 8),
            child: Text(
              '$rank',
              style: TextStyle(
                color: const Color(0xFF146AFF),
                fontSize: 14,
                fontFamily: 'Pretendard-Bold',
              ),
            ),
          ),

          // 2. 프로필 이미지
          Container(
            width: 40,
            height: 40,
            margin: EdgeInsets.only(right: 8),
            decoration: ShapeDecoration(
              image: DecorationImage(
                image: _getProfileImageFromUser(user),
                fit: BoxFit.cover,
              ),
              shape: OvalBorder(
                side: BorderSide(
                  width: 1.2,
                  color:
                      (isCurrentUser || isHighlighted)
                          ? const Color(0xFF5D9EFF)
                          : const Color(0xFF146AFF).withOpacity(0.3),
                ),
              ),
            ),
          ),

          // 3. 학년 표시와 이름 - Expanded로 공간 확보
          Expanded(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 학년 표시
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  margin: EdgeInsets.only(right: 4),
                  decoration: ShapeDecoration(
                    color: const Color(0xFFEFF2F6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        "assets/icons/Icon/feed/순위.png",
                        width: 7,
                        height: 7,
                      ),
                      SizedBox(width: 2),
                      Text(
                        isCurrentUser ? '1' : '8', // 임시 학년 데이터
                        style: TextStyle(
                          color: const Color(0xFF3A88F4),
                          fontSize: 10,
                          fontFamily: 'Pretendard-Medium',
                        ),
                      ),
                    ],
                  ),
                ),
                // 이름 - Expanded로 공간 확보
                Expanded(
                  child: Text(
                    user.friendName,
                    style: TextStyle(
                      color: const Color(0xFF202020),
                      fontSize: 12,
                      fontFamily:
                          isCurrentUser || isHighlighted
                              ? 'Pretendard-Bold'
                              : 'Pretendard-Medium',
                      overflow: TextOverflow.ellipsis,
                    ),
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),

          // 오른쪽 버튼들을 따로 Row로 묶어 공간 관리
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 4. 달성 정보 (노란색 버튼)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                margin: EdgeInsets.only(right: 8),
                decoration: ShapeDecoration(
                  color: const Color(0xFFFFD27F),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '${user.completedMissionCount}',
                        style: TextStyle(
                          color: const Color(0xFF001F55),
                          fontSize: 10,
                          fontFamily: 'Pretendard-Medium',
                        ),
                      ),
                      TextSpan(
                        text: '개 달성',
                        style: TextStyle(
                          color: const Color(0xFF001F55),
                          fontSize: 10,
                          fontFamily: 'Pretendard-Medium',
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 5. 친한 친구 맺기 버튼 대신 채팅하기 버튼 - 내 계정일 경우 표시 안함
              if (!(isCurrentUser || isHighlighted))
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: ShapeDecoration(
                    color: const Color(0xFF5D9EFF),
                    shape: RoundedRectangleBorder(
                      side: BorderSide(
                        width: 0.55,
                        color: const Color(0xFF5D9EFF),
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/icons/Icon/feed/채팅하기.png',
                        width: 12,
                        height: 12,
                        fit: BoxFit.contain,
                      ),
                      SizedBox(width: 3),
                      Text(
                        '채팅하기',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontFamily: 'Pretendard-Light',
                          fontWeight: FontWeight.w300,
                          letterSpacing: -0.24,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // 프로필 이미지를 가져오는 헬퍼 메서드
  ImageProvider _getProfileImageFromUser(RankingUser user) {
    // 현재 사용자인 경우 - AuthService에서 가져온 사용자 정보 우선 사용
    if (user.isCurrentUser &&
        _userInfo != null &&
        _userInfo!['profileImagePath'] != null) {
      final profileImagePath = _userInfo!['profileImagePath'];
      if (profileImagePath != null && profileImagePath.isNotEmpty) {
        final fullUrl = AuthService.getFullProfileImageUrl(profileImagePath);
        if (fullUrl.isNotEmpty) {
          return NetworkImage(fullUrl);
        }
      }
    }

    // 친구들의 경우 - 캐시에서 프로필 이미지 정보 확인
    if (!user.isCurrentUser &&
        _profileImageCache.containsKey(user.friendUserId)) {
      final cachedProfilePath = _profileImageCache[user.friendUserId];
      if (cachedProfilePath != null && cachedProfilePath.isNotEmpty) {
        final fullUrl = AuthService.getFullProfileImageUrl(cachedProfilePath);
        if (fullUrl.isNotEmpty) {
          return NetworkImage(fullUrl);
        }
      }
    } else if (!user.isCurrentUser) {
      // 캐시에 없으면 다시 로드 시도
      _fetchUserProfileImage(user.friendUserId);
    }

    // API에서 받은 프로필 이미지 경로 사용 (기존 방식 - 백업용)
    if (user.profileImagePath != null && user.profileImagePath!.isNotEmpty) {
      final fullUrl = AuthService.getFullProfileImageUrl(
        user.profileImagePath!,
      );
      if (fullUrl.isNotEmpty) {
        return NetworkImage(fullUrl);
      }
    }

    // 기본 이미지 사용 (프로필 이미지가 없거나 로드 실패한 경우)
    final defaultImage = AssetImage(
      user.isCurrentUser
          ? "assets/icons/Icon/feed/profile1.png" // 내 프로필 기본 이미지
          : "assets/icons/Icon/feed/profile${(user.friendUserId % 4) + 1}.png",
    ); // 친구 프로필 기본 이미지

    return defaultImage;
  }

  // 내 랭킹 카드 위젯 (상세 정보) 수정
  Widget _buildMyRankCard() {
    if (_currentUser == null) {
      return Container(
        width: 358,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: ShapeDecoration(
          color: Colors.white.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            side: BorderSide(width: 0.80, color: Colors.white),
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: Center(
          child: Text(
            '내 랭킹 정보를 불러올 수 없습니다.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontFamily: 'Pretendard-Medium',
            ),
          ),
        ),
      );
    }

    final myRank = _getMyRankPosition();

    return Container(
      width: 358,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: ShapeDecoration(
        color: Colors.white.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          side: BorderSide(width: 0.80, color: Colors.white),
          borderRadius: BorderRadius.circular(20),
        ),
        shadows: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 상단 프로필 정보
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 프로필 이미지
              Container(
                width: 42,
                height: 42,
                decoration: ShapeDecoration(
                  image: DecorationImage(
                    image: _getProfileImageFromUser(_currentUser!),
                    fit: BoxFit.cover,
                  ),
                  shape: OvalBorder(
                    side: BorderSide(
                      width: 1.2,
                      color: const Color(0xFF146AFF),
                    ),
                  ),
                ),
              ),

              SizedBox(width: 14),

              // 이름과 랭킹 정보
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentUser!.friendName,
                      style: TextStyle(
                        color: const Color(0xFF001F55),
                        fontSize: 13,
                        fontFamily: 'Pretendard-Bold',
                        letterSpacing: -0.22,
                      ),
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          _isFilterFriends ? '친한 친구들 사이' : '전체 친구들 사이',
                          style: TextStyle(
                            color: const Color(0xFF3A88F4),
                            fontSize: 12,
                            fontFamily: 'Pretendard-Bold',
                            letterSpacing: -0.22,
                          ),
                        ),
                        SizedBox(width: 4),
                        Text(
                          '${myRank}위',
                          style: TextStyle(
                            color: const Color(0xFF146AFF),
                            fontSize: 14,
                            fontFamily: 'Pretendard-Bold',
                            letterSpacing: -0.22,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 달성 정보 - 우측 배치
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
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
                      TextSpan(
                        text: '${_currentUser!.completedMissionCount}개',
                        style: TextStyle(
                          color: const Color(0xFF001F55),
                          fontSize: 12,
                          fontFamily: 'Pretendard-Bold',
                          letterSpacing: -0.22,
                        ),
                      ),
                      TextSpan(
                        text: ' 달성',
                        style: TextStyle(
                          color: const Color(0xFF001F55),
                          fontSize: 11,
                          fontFamily: 'Pretendard-Medium',
                          letterSpacing: -0.22,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 12),

          // 하단 정보 (지난 주보다, 다음 랭킹까지)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 왼쪽 버튼들은 Flexible로 감싸서 너비 제한
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 완료율 정보
                    Flexible(
                      child: Container(
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
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                '완료율',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontFamily: 'Pretendard-ExtraLight',
                                  letterSpacing: -0.22,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(width: 6),
                            Text(
                              '${_currentUser!.completionRate.toStringAsFixed(1)}%',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontFamily: 'Pretendard-Bold',
                                letterSpacing: -0.22,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(width: 10),

                    // 전체 미션 수 정보
                    Flexible(
                      child: Container(
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
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                '전체 미션',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontFamily: 'Pretendard-ExtraLight',
                                  letterSpacing: -0.22,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(width: 3),
                            Text(
                              '${_currentUser!.totalMissionCount}개',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontFamily: 'Pretendard-Bold',
                                letterSpacing: -0.22,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(width: 6),

              // 돌아가기 버튼 - 뱃지 대신 텍스트+화살표로 변경
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: EdgeInsets.only(right: 10),
                  child: GestureDetector(
                    onTap: _returnToFullRanking,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '돌아가기',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontFamily: 'Pretendard-ExtraLight',
                            letterSpacing: -0.22,
                          ),
                        ),
                        SizedBox(width: 5),
                        Text(
                          '>',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontFamily: 'Pretendard-ExtraLight',
                            letterSpacing: -0.22,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 도움말 말풍선
  Widget _buildHelpBubble() {
    return Positioned(
      top: 50, // 상단에서 50px 위치에 표시
      left: 0,
      right: 0,
      child: Align(
        alignment: Alignment.centerLeft, // 중앙 대신 왼쪽 중앙으로 정렬
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // 말풍선 본체 먼저 배치
            Container(
              margin: EdgeInsets.only(left: 24), // 왼쪽 여백 추가
              width:
                  MediaQuery.of(context).size.width *
                  0.6, // 화면 너비의 0.75에서 0.7로 줄임
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: ShapeDecoration(
                color: const Color(0xFF8490A3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 헤더 부분 (제목과 X 버튼)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '랭킹은 어떻게 정해지나요?',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12, // 타이틀 폰트 크기 2px 줄임 (14 -> 12)
                          fontFamily: 'Pretendard-Medium',
                          letterSpacing: -0.24,
                        ),
                        textAlign: TextAlign.left,
                      ),
                      // X 버튼
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _isHelpVisible = false;
                          });
                        },
                        child: Icon(Icons.close, color: Colors.white, size: 16),
                      ),
                    ],
                  ),
                  SizedBox(height: 10), // 간격 키움 (6 -> 10)
                  // 첫 번째 질문 내용
                  Text(
                    '완료한 미션, 챌린지의 총 갯수와 미션의 난이도에 따라 주별, 일별로 사용자 간 랭킹이 변동됩니다.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10, // 내용 폰트 크기 2px 줄임 (12 -> 10)
                      fontFamily: 'Pretendard-ExtraLight',
                      height: 1.4,
                      letterSpacing: -0.22,
                    ),
                    textAlign: TextAlign.left,
                  ),
                  SizedBox(height: 16),

                  // 두 번째 질문
                  Text(
                    '랭킹은 어떻게 올릴 수 있나요?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12, // 타이틀 폰트 크기 2px 줄임 (14 -> 12)
                      fontFamily: 'Pretendard-Medium',
                      letterSpacing: -0.24,
                    ),
                    textAlign: TextAlign.left,
                  ),
                  SizedBox(height: 10), // 간격 키움 (6 -> 10)
                  // 두 번째 질문 내용
                  Text(
                    '부모님과 선생님에게 받은 미션과, 직접 참여를 신청한 챌린지를 성공적으로 완료 시, 내 랭킹이 한 단계씩 올라갈 수 있어요',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10, // 내용 폰트 크기 2px 줄임 (12 -> 10)
                      fontFamily: 'Pretendard-ExtraLight',
                      height: 1.4,
                      letterSpacing: -0.22,
                    ),
                    textAlign: TextAlign.left,
                  ),
                ],
              ),
            ),
            // 삼각형 화살표 (위쪽 방향)
            Positioned(
              top: -10, // 말풍선 위로 배치
              left: 140, // 위치 조정
              child: CustomPaint(
                size: Size(16, 12), // 삼각형 크기 조정
                painter: TrianglePainter(
                  color: const Color(0xFF8490A3),
                  isUpward: false,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 삼각형을 그리는 CustomPainter 클래스 수정
class TrianglePainter extends CustomPainter {
  final Color color;
  final bool isUpward;

  TrianglePainter({required this.color, this.isUpward = false});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint =
        Paint()
          ..color = color
          ..style = PaintingStyle.fill;

    final Path path = Path();

    if (isUpward) {
      // 위쪽을 가리키는 삼각형
      path.moveTo(size.width / 2, 0); // 상단 중앙
      path.lineTo(0, size.height); // 왼쪽 하단
      path.lineTo(size.width, size.height); // 오른쪽 하단
    } else {
      // 아래쪽을 가리키는 삼각형 (이것이 말풍선에서 위로 나오는 것)
      path.moveTo(size.width / 2, 0); // 상단 중앙 (삼각형 꼭지점)
      path.lineTo(0, size.height); // 왼쪽 하단
      path.lineTo(size.width, size.height); // 오른쪽 하단
    }

    path.close(); // 삼각형 닫기

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
