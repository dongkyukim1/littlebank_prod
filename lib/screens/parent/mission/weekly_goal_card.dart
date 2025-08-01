import 'package:flutter/material.dart';
import '../../../services/goal_service.dart';
import '../../../services/family_service.dart';
import '../chat_detail_screen.dart';

class ParentWeeklyGoalMissionCard extends StatefulWidget {
  final Map<String, dynamic>? selectedChild;
  final VoidCallback? onCheckHabit;
  final VoidCallback? onCheckStudy;

  const ParentWeeklyGoalMissionCard({
    super.key,
    this.selectedChild,
    this.onCheckHabit,
    this.onCheckStudy,
  });

  @override
  State<ParentWeeklyGoalMissionCard> createState() =>
      _ParentWeeklyGoalMissionCardState();
}

class _ParentWeeklyGoalMissionCardState
    extends State<ParentWeeklyGoalMissionCard> {
  List<Map<String, dynamic>> _weeklyGoals = [];
  bool _isLoading = true;
  String? _error;
  // 각 목표의 도장 체크 상태를 캐시
  Map<int, Map<String, dynamic>?> _goalCheckCache = {};

  @override
  void initState() {
    super.initState();
    _loadWeeklyGoals();
  }

  @override
  void didUpdateWidget(ParentWeeklyGoalMissionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 선택된 자녀가 변경되면 목표를 다시 로드
    if (oldWidget.selectedChild != widget.selectedChild) {
      _goalCheckCache.clear(); // 캐시 초기화
      _loadWeeklyGoals();
    }
  }

  // 이번 주 목표 조회
  Future<void> _loadWeeklyGoals() async {
    if (widget.selectedChild == null) {
      setState(() {
        _weeklyGoals = [];
        _isLoading = false;
        _error = null;
      });
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // 캐시 초기화
      _goalCheckCache.clear();

      print('===== 부모 미션화면: 자녀 이번 주 목표 조회 시작 =====');

      final familyInfo = await FamilyService.getFamilyInfo();
      if (familyInfo == null) {
        throw Exception('가족 정보를 가져올 수 없습니다');
      }

      final familyId = familyInfo['familyId'];
      final goals = await GoalService.getParentWeeklyGoals(familyId);

      if (goals != null) {
        // 선택된 자녀의 목표만 필터링
        final selectedChildId = widget.selectedChild!['familyMemberId'];
        final childGoals =
            goals
                .where((goal) => goal['familyMemberId'] == selectedChildId)
                .toList();

        setState(() {
          _weeklyGoals = childGoals;
          _isLoading = false;
        });

        print('부모 미션화면: 자녀 이번 주 목표 ${childGoals.length}개 조회 성공');
      } else {
        setState(() {
          _weeklyGoals = [];
          _isLoading = false;
        });
      }

      print('===== 부모 미션화면: 자녀 이번 주 목표 조회 완료 =====');
    } catch (e) {
      print('부모 미션화면: 자녀 이번 주 목표 조회 중 오류: $e');
      setState(() {
        _weeklyGoals = [];
        _isLoading = false;
        _error = '목표 조회 중 오류가 발생했습니다';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final childName =
        widget.selectedChild?['nickname'] ??
        widget.selectedChild?['realName'] ??
        '자녀';

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
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 상단 헤더 부분
          Padding(
            padding: const EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: 12,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '이번 주 ${childName}님의 목표 ',
                      style: TextStyle(
                        fontSize: 16,
                        color: const Color(0xFF202020),
                        fontFamily: 'Pretendard-Bold',
                        letterSpacing: -0.4,
                      ),
                    ),
                    Text(
                      '${_weeklyGoals.length}',
                      style: TextStyle(
                        fontSize: 16,
                        color: const Color(0xFF146AFF),
                        fontFamily: 'Pretendard-Bold',
                        letterSpacing: -0.4,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '매일 달성하기 위해 칭찬 스탬프를 찍어주세요',
                  style: TextStyle(
                    fontSize: 12,
                    color: const Color(0xFF999999),
                    fontFamily: 'Pretendard-Light',
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),

          // 로딩 상태 처리
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: CircularProgressIndicator(color: Color(0xFF5D9EFF)),
              ),
            )
          else if (_error != null)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Text(
                      _error!,
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 14,
                        fontFamily: 'Pretendard-Medium',
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _loadWeeklyGoals,
                      child: Text('다시 시도'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF5D9EFF),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (_weeklyGoals.isNotEmpty)
          // 목표 목록 표시
          ...[
            ..._weeklyGoals.asMap().entries.map((entry) {
              final index = entry.key;
              final goal = entry.value;
              return _buildGoalItem(goal, index);
            }).toList(),
            // 목표가 하나만 있을 때 빈 칸 추가
            if (_weeklyGoals.length == 1) _buildEmptyGoalSlot(),
          ] else
            // 목표가 없을 때 표시할 UI
            _buildEmptyGoalSlot(),
        ],
      ),
    );
  }

  // 목표 아이템 위젯 생성
  Widget _buildGoalItem(Map<String, dynamic> goal, int index) {
    final String title = goal['title'] ?? '목표 없음';
    final String category = goal['category'] ?? 'LEARNING';
    final String status = goal['status'] ?? '';
    final int reward = goal['reward'] ?? 0;
    final int goalId = goal['goalId'] ?? 0;

    // 상태에 따른 텍스트와 색상 결정
    final String statusText = GoalService.getGoalStatusText(goal);
    final Color statusColor = GoalService.getGoalStatusColor(goal);
    final String categoryText = GoalService.getCategoryText(category);

    return Column(
      children: [
        // 구분선 (첫 번째 아이템이 아닌 경우)
        if (index > 0)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Divider(
              height: 1,
              thickness: 1,
              color: Colors.grey.withOpacity(0.1),
            ),
          ),

        InkWell(
          onTap: () {}, // 상세화면 이동 등
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 카테고리 태그만 표시
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD27F),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        categoryText,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontFamily: 'Pretendard-Light',
                          letterSpacing: -0.1,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 목표 내용과 아이콘들
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              style: TextStyle(
                                fontSize: 14,
                                color: const Color(0xFF353535),
                                fontFamily: 'Pretendard-Bold',
                                letterSpacing: -0.2,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // 도장을 안찍었을 때만 "new" 태그 표시
                          if (_shouldShowNewTag(goal))
                            Container(
                              margin: const EdgeInsets.only(left: 6),
                              padding: const EdgeInsets.only(
                                top: 2,
                                left: 12,
                                right: 12,
                                bottom: 4,
                              ),
                              decoration: ShapeDecoration(
                                color: const Color(0xFF146AFF),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                              ),
                              child: Text(
                                'new',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontFamily: 'Pretendard',
                                  fontWeight: FontWeight.w300,
                                  letterSpacing: -0.22,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    // 방향표 아이콘
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 18,
                      color: Color(0xFFB6B6B6),
                    ),
                    const SizedBox(width: 10),
                    // 체크 아이콘
                    _buildCheckIcon(goal),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 체크 아이콘 위젯 생성 (오늘 날짜 도장 체크 여부에 따라)
  Widget _buildCheckIcon(Map<String, dynamic> goal) {
    final String status = goal['status'] ?? '';
    final int goalId = goal['goalId'] ?? 0;

    if (status == 'REQUESTED') {
      // 신청 중인 경우 - 비활성화된 체크 아이콘
      return Icon(Icons.check_circle, color: const Color(0xFFE5E5E5), size: 28);
    } else if (status == 'ACHIEVEMENT') {
      // 완료된 경우 - 초록색 체크 아이콘
      return Icon(Icons.check_circle, color: const Color(0xFF4CAF50), size: 28);
    } else if (status == 'ACCEPT') {
      // 수락된 경우 - 캐시된 데이터 또는 API 호출
      final cachedData = _goalCheckCache[goalId];

      if (cachedData != null) {
        // 캐시된 데이터 사용
        final currentDayNumber = GoalService.getCurrentDayNumber();
        final isTodayChecked = GoalService.isDayChecked(
          cachedData,
          currentDayNumber,
        );

        return GestureDetector(
          onTap: () => _handleStampGoal(goalId),
          child:
              isTodayChecked
                  ? Icon(Icons.check_circle, color: Color(0xFF5D9EFF), size: 28)
                  : Image.asset(
                    'assets/icons/parent/mission/non_check.png',
                    width: 28,
                    height: 28,
                    errorBuilder:
                        (context, error, stackTrace) => Icon(
                          Icons.radio_button_unchecked,
                          color: Color(0xFFE5E5E5),
                          size: 28,
                        ),
                  ),
        );
      } else {
        // 캐시가 없으면 API 호출
        return FutureBuilder<Map<String, dynamic>?>(
          future: goalId > 0 ? _loadGoalCheck(goalId) : null,
          builder: (context, snapshot) {
            bool isTodayChecked = false;

            if (snapshot.hasData && snapshot.data != null) {
              final currentDayNumber = GoalService.getCurrentDayNumber();
              isTodayChecked = GoalService.isDayChecked(
                snapshot.data!,
                currentDayNumber,
              );
            }

            return GestureDetector(
              onTap: () => _handleStampGoal(goalId),
              child:
                  isTodayChecked
                      ? Icon(
                        Icons.check_circle,
                        color: Color(0xFF5D9EFF),
                        size: 28,
                      )
                      : Image.asset(
                        'assets/icons/parent/mission/non_check.png',
                        width: 28,
                        height: 28,
                        errorBuilder:
                            (context, error, stackTrace) => Icon(
                              Icons.radio_button_unchecked,
                              color: Color(0xFFE5E5E5),
                              size: 28,
                            ),
                      ),
            );
          },
        );
      }
    }

    // 기본값
    return Icon(Icons.check_circle, color: Color(0xFF5D9EFF), size: 28);
  }

  // 도장 체크 데이터 로드 및 캐시
  Future<Map<String, dynamic>?> _loadGoalCheck(int goalId) async {
    try {
      final checkData = await GoalService.getGoalCheck(goalId);
      if (checkData != null) {
        _goalCheckCache[goalId] = checkData;
      }
      return checkData;
    } catch (e) {
      print('도장 체크 데이터 로드 실패: $e');
      return null;
    }
  }

  // 도장 찍기 처리
  Future<void> _handleStampGoal(int goalId) async {
    try {
      final currentDayNumber = GoalService.getCurrentDayNumber();
      print('도장 찍기 시도 - goalId: $goalId, day: $currentDayNumber');

      final result = await GoalService.stampGoalCheck(goalId, currentDayNumber);

      if (result['success'] == true) {
        print('✅ 도장 찍기 성공!');

        // 캐시 업데이트 - 오늘 날짜를 true로 설정
        final currentCache = _goalCheckCache[goalId] ?? {};
        final updatedCache = Map<String, dynamic>.from(currentCache);

        // 현재 요일에 해당하는 필드를 true로 업데이트
        switch (currentDayNumber) {
          case 1:
            updatedCache['mon'] = true;
            break;
          case 2:
            updatedCache['tue'] = true;
            break;
          case 3:
            updatedCache['wed'] = true;
            break;
          case 4:
            updatedCache['thu'] = true;
            break;
          case 5:
            updatedCache['fri'] = true;
            break;
          case 6:
            updatedCache['sat'] = true;
            break;
          case 7:
            updatedCache['sun'] = true;
            break;
        }

        _goalCheckCache[goalId] = updatedCache;

        // UI 즉시 업데이트
        setState(() {});

        // 성공 메시지 표시
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${GoalService.convertNumberToDay(currentDayNumber)}요일 도장을 찍었습니다!',
              ),
              backgroundColor: Color(0xFF4CAF50),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        throw Exception(result['message'] ?? '도장 찍기에 실패했습니다.');
      }
    } catch (e) {
      print('❌ 도장 찍기 실패: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '도장 찍기에 실패했습니다: ${e.toString().replaceAll('Exception: ', '')}',
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // 도장을 안찍었을 때만 "new" 태그 표시
  bool _shouldShowNewTag(Map<String, dynamic> goal) {
    final String status = goal['status'] ?? '';
    final int goalId = goal['goalId'] ?? 0;

    // ACCEPT 상태인 목표만 확인
    if (status != 'ACCEPT') {
      return false;
    }

    // 캐시된 도장 체크 데이터 확인
    final cachedData = _goalCheckCache[goalId];
    if (cachedData != null) {
      final currentDayNumber = GoalService.getCurrentDayNumber();
      final isTodayChecked = GoalService.isDayChecked(
        cachedData,
        currentDayNumber,
      );
      return !isTodayChecked; // 도장을 안찍었으면 true (new 표시)
    }

    // 캐시가 없으면 기본적으로 new 표시
    return true;
  }

  // 채팅 화면으로 이동
  void _navigateToChat() {
    if (widget.selectedChild == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '선택된 자녀가 없습니다',
            style: TextStyle(fontFamily: 'Pretendard-Medium'),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final childName = widget.selectedChild!['nickname'] ?? 
                     widget.selectedChild!['realName'] ?? '자녀';
    final childUserId = widget.selectedChild!['userId'] ?? 0;
    final profileImagePath = widget.selectedChild!['profileImagePath'] ?? '';

    // 임시 roomId (실제로는 채팅 서비스에서 자녀와의 채팅방을 찾거나 생성해야 함)
    final tempRoomId = childUserId; 

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ParentChatDetailScreen(
          userName: childName,
          avatar: profileImagePath,
          roomId: tempRoomId,
          userId: childUserId,
        ),
      ),
    );
  }

  // 목표가 하나만 있을 때 빈 칸 추가
  Widget _buildEmptyGoalSlot() {
    // 목표가 하나라도 있는 경우 기존 UI 유지
    if (_weeklyGoals.isNotEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: ShapeDecoration(
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
            Container(
              width: double.infinity,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                    child: Text(
                      '습관 형성',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w300,
                        letterSpacing: -0.24,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: ShapeDecoration(
                      color: const Color(0xFFE4ECF8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          child: Image.asset(
                            'assets/icons/parent/goal/half_goal.png',
                            width: 24,
                            height: 24,
                            fit: BoxFit.contain,
                            errorBuilder:
                                (context, error, stackTrace) => Icon(
                                  Icons.assignment_outlined,
                                  size: 24,
                                  color: const Color(0xFF999999),
                                ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '생활 습관 목표가 없습니다!',
                          style: TextStyle(
                            color: const Color(0xFF999999),
                            fontSize: 11,
                            fontFamily: 'Pretendard',
                            fontWeight: FontWeight.w300,
                            letterSpacing: -0.22,
                          ),
                        ),
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: () => _navigateToChat(),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: ShapeDecoration(
                              color: const Color(0xFF3A88F4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            child: Text(
                              '채팅으로 응원하기',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontFamily: 'Pretendard',
                                fontWeight: FontWeight.w300,
                                letterSpacing: -0.2,
                              ),
                            ),
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
      );
    }

    // 목표가 하나도 없는 경우 새로운 UI
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          Image.asset(
            'assets/icons/parent/mission/non_goal.png',
            width: 139,
            height: 198,
            fit: BoxFit.contain,
            errorBuilder:
                (context, error, stackTrace) => Container(
                  width: 139,
                  height: 198,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE4ECF8),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.image_not_supported,
                    size: 48,
                    color: const Color(0xFF999999),
                  ),
                ),
          ),
          const SizedBox(height: 40),
          FractionallySizedBox(
            widthFactor: 0.9,
            child: GestureDetector(
              onTap: () => _navigateToChat(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: ShapeDecoration(
                  color: const Color(0xFF3A88F4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Center(
                  child: Text(
                    '채팅으로 응원하기',
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
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
