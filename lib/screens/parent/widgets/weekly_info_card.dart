import 'package:flutter/material.dart';
import '../../../services/auth_service.dart';
import '../../../services/mission_service.dart';
import '../../../services/challenge_service.dart';
import '../../../services/goal_service.dart';
import '../../../services/family_service.dart';
import '../../../services/payment_service.dart';
import '../mission/mission_evaluation_screen.dart';
import '../challenge/parent_challenge_score_modal.dart';
import '../mission/complete_modal/parent_mission_complete_modal.dart';

class WeeklyInfoCard extends StatefulWidget {
  final Map<String, dynamic>? selectedChild;

  const WeeklyInfoCard({Key? key, this.selectedChild}) : super(key: key);

  @override
  State<WeeklyInfoCard> createState() => _WeeklyInfoCardState();
}

class _WeeklyInfoCardState extends State<WeeklyInfoCard>
    with TickerProviderStateMixin {
  String _userName = '사용자';
  bool _isLoading = true;
  bool _isExpanded = false;
  AnimationController? _rotationController;
  Animation<double>? _rotationAnimation;

  // 실제 API에서 가져올 데이터
  List<Map<String, dynamic>> _rewardItems = [];

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _initializeAnimation();
    _loadRewardData();
  }

  @override
  void didUpdateWidget(WeeklyInfoCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedChild != oldWidget.selectedChild) {
      _loadRewardData();
    }
  }

  void _initializeAnimation() {
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(begin: 0.0, end: 0.5).animate(
      CurvedAnimation(parent: _rotationController!, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _rotationController?.dispose();
    super.dispose();
  }

  // 사용자 정보 로드
  Future<void> _loadUserInfo() async {
    try {
      final userInfo = await AuthService.getUserInfo();
      if (mounted) {
        setState(() {
          _userName = userInfo?['name'] ?? '사용자';
        });
      }
    } catch (e) {
      print('WeeklyInfoCard: 사용자 정보 로드 실패 - $e');
      if (mounted) {
        setState(() {
          _userName = '사용자';
        });
      }
    }
  }

  // 보상 데이터 로드
  Future<void> _loadRewardData() async {
    if (widget.selectedChild == null) {
      setState(() {
        _rewardItems = [];
        _isLoading = false;
      });
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      print('WeeklyInfoCard: 보상 데이터 로드 시작');

      final List<Map<String, dynamic>> allRewardItems = [];

      // 1. 미션 데이터 로드
      await _loadMissionRewards(allRewardItems);

      // 2. 챌린지 데이터 로드
      await _loadChallengeRewards(allRewardItems);

      // 3. 목표 데이터 로드
      await _loadGoalRewards(allRewardItems);

      // 날짜순으로 정렬 (최신 순)
      allRewardItems.sort((a, b) {
        final dateA = _parseDate(a['dateTag']);
        final dateB = _parseDate(b['dateTag']);
        return dateB.compareTo(dateA);
      });

      if (mounted) {
        setState(() {
          _rewardItems = allRewardItems;
          _isLoading = false;
        });
      }

      print('WeeklyInfoCard: 보상 데이터 로드 완료 - ${allRewardItems.length}개');
    } catch (e) {
      print('WeeklyInfoCard: 보상 데이터 로드 실패 - $e');
      if (mounted) {
        setState(() {
          _rewardItems = [];
          _isLoading = false;
        });
      }
    }
  }

  // 미션 보상 데이터 로드
  Future<void> _loadMissionRewards(
    List<Map<String, dynamic>> allRewardItems,
  ) async {
    try {
      final childId =
          widget.selectedChild!['userId'] ??
          widget.selectedChild!['familyMemberId'];
      if (childId == null) return;

      final missionsData = await MissionService.getParentChildMissions(
        childId: childId,
        page: 0,
      );

      if (missionsData != null && missionsData['data'] != null) {
        final List<dynamic> missionList = missionsData['data'];

        // 완료되었지만 보상이 지급되지 않은 미션 필터링
        final completedMissions =
            missionList.where((mission) {
              final status = mission['status'];
              final isRewarded = mission['isRewarded'] ?? false;
              final endDateStr = mission['endDate'];

              if (isRewarded) return false;

              if (status == 'ACHIEVEMENT') return true;

              if (status == 'ACCEPT' && endDateStr != null) {
                try {
                  final endDate = DateTime.parse(endDateStr);
                  return DateTime.now().isAfter(endDate);
                } catch (e) {
                  return false;
                }
              }

              return false;
            }).toList();

        for (final mission in completedMissions) {
          final missionType = mission['type'] ?? 'FAMILY';
          final typeLabel = missionType == 'FAMILY' ? '가족 미션' : '개인 미션';

          allRewardItems.add({
            'type': 'mission',
            'id': mission['missionId'],
            'tags': ['미션', typeLabel],
            'tagColors': [Color(0xFFFFD27F), Color(0xFF5D9EFF)],
            'dateTag': _formatDateRange(
              mission['startDate'],
              mission['endDate'],
            ),
            'title': mission['title'] ?? '미션',
            'reward': '${mission['reward'] ?? 0}원',
            'rawData': mission,
          });
        }
      }
    } catch (e) {
      print('WeeklyInfoCard: 미션 보상 데이터 로드 실패 - $e');
    }
  }

  // 챌린지 보상 데이터 로드
  Future<void> _loadChallengeRewards(
    List<Map<String, dynamic>> allRewardItems,
  ) async {
    try {
      final familyInfo = await FamilyService.getFamilyInfo();
      if (familyInfo == null) return;

      final familyId = familyInfo['familyId'];
      final childId = widget.selectedChild!['familyMemberId'];
      if (childId == null) return;

      final challengeResponse = await ChallengeService.getChildChallenges(
        familyId,
        childId,
        page: 0,
      );

      // 보상 대기 중인 완료된 챌린지 필터링
      final challengesToReward =
          challengeResponse.data.where((challenge) {
            final challengeData = challenge.toJson();
            return ChallengeService.shouldShowRewardModal(challengeData);
          }).toList();

      for (final challenge in challengesToReward) {
        final challengeStatus = challenge.challengeStatus;
        final typeLabel =
            challengeStatus == 'DAILY'
                ? '일일'
                : challengeStatus == 'WEEKLY'
                ? '주간'
                : '요일별';

        allRewardItems.add({
          'type': 'challenge',
          'id': challenge.participationId,
          'tags': ['챌린지', typeLabel],
          'tagColors': [Color(0xFFFFD27F), Color(0xFF5D9EFF)],
          'dateTag': _formatDateRange(challenge.startDate, challenge.endDate),
          'title': challenge.title,
          'reward': '${challenge.reward}원',
          'rawData': challenge.toJson(),
        });
      }
    } catch (e) {
      print('WeeklyInfoCard: 챌린지 보상 데이터 로드 실패 - $e');
    }
  }

  // 목표 보상 데이터 로드
  Future<void> _loadGoalRewards(
    List<Map<String, dynamic>> allRewardItems,
  ) async {
    try {
      final familyInfo = await FamilyService.getFamilyInfo();
      if (familyInfo == null) return;

      final familyId = familyInfo['familyId'];
      final selectedChildId = widget.selectedChild!['familyMemberId'];
      if (selectedChildId == null) return;

      final weeklyGoals = await GoalService.getParentWeeklyGoals(familyId);
      if (weeklyGoals == null || weeklyGoals.isEmpty) return;

      // 선택된 자녀의 ACCEPT 상태 목표만 필터링
      final childGoals =
          weeklyGoals
              .where(
                (goal) =>
                    goal['familyMemberId'] == selectedChildId &&
                    goal['status'] == 'ACCEPT',
              )
              .toList();

      // 완료된 목표 찾기 (7일 모두 도장을 찍은 목표)
      for (final goal in childGoals) {
        final goalId = goal['goalId'];
        if (goalId == null) continue;

        try {
          final checkData = await GoalService.getGoalCheck(goalId);
          if (checkData != null) {
            // 7일 모두 도장이 찍혔는지 확인
            bool allDaysChecked = true;
            for (int day = 1; day <= 7; day++) {
              if (!GoalService.isDayChecked(checkData, day)) {
                allDaysChecked = false;
                break;
              }
            }

            if (allDaysChecked) {
              final category = goal['category'] ?? 'LEARNING';
              final typeLabel = category == 'LEARNING' ? '학습 인증' : '습관 형성';

              allRewardItems.add({
                'type': 'goal',
                'id': goal['goalId'],
                'tags': ['목표', typeLabel],
                'tagColors': [Color(0xFFFFD27F), Color(0xFF5D9EFF)],
                'dateTag': _formatDateRange(goal['startDate'], goal['endDate']),
                'title': goal['title'] ?? '목표',
                'reward': '${goal['reward'] ?? 0}원',
                'rawData': goal,
              });
            }
          }
        } catch (e) {
          print('WeeklyInfoCard: 목표 ${goal['title']} 도장 확인 중 오류 - $e');
        }
      }
    } catch (e) {
      print('WeeklyInfoCard: 목표 보상 데이터 로드 실패 - $e');
    }
  }

  // 날짜 범위 포맷팅
  String _formatDateRange(String? startDate, String? endDate) {
    try {
      if (startDate == null || endDate == null) return '';

      final start = DateTime.parse(startDate);
      final end = DateTime.parse(endDate);

      final startFormatted =
          '${start.month.toString().padLeft(2, '0')}. ${start.day.toString().padLeft(2, '0')}';
      final endFormatted =
          '${end.month.toString().padLeft(2, '0')}. ${end.day.toString().padLeft(2, '0')}';

      return '$startFormatted - $endFormatted';
    } catch (e) {
      return '';
    }
  }

  // 날짜 파싱 (정렬용)
  DateTime _parseDate(String dateTag) {
    try {
      // "03. 25 - 03. 28" 형식에서 끝 날짜 추출
      final parts = dateTag.split(' - ');
      if (parts.length != 2) return DateTime.now();

      final endDatePart = parts[1];
      final dateParts = endDatePart.split('. ');
      if (dateParts.length != 2) return DateTime.now();

      final month = int.parse(dateParts[0]);
      final day = int.parse(dateParts[1]);
      final year = DateTime.now().year;

      return DateTime(year, month, day);
    } catch (e) {
      return DateTime.now();
    }
  }

  // 보상 지급 처리 (모달 표시)
  Future<void> _sendReward(Map<String, dynamic> item) async {
    final type = item['type'];
    final rawData = item['rawData'];

    print('WeeklyInfoCard: 보상 모달 표시 - $type');

    switch (type) {
      case 'mission':
        await _showMissionEvaluationModal(rawData);
        break;
      case 'challenge':
        await _showChallengeScoreModal(rawData);
        break;
      case 'goal':
        await _showGoalCompletionModal(rawData);
        break;
      default:
        print('알 수 없는 보상 타입: $type');
    }
  }

  // 미션 평가 모달 표시
  Future<void> _showMissionEvaluationModal(Map<String, dynamic> mission) async {
    if (widget.selectedChild == null) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => MissionEvaluationScreen(
              mission: mission,
              childInfo: widget.selectedChild,
            ),
      ),
    );

    // 평가 완료 후 데이터 새로고침
    if (result != null) {
      await _loadRewardData();
    }
  }

  // 챌린지 점수 입력 모달 표시
  Future<void> _showChallengeScoreModal(Map<String, dynamic> challenge) async {
    if (widget.selectedChild == null) return;

    final childName =
        widget.selectedChild!['nickname'] ??
        widget.selectedChild!['realName'] ??
        '자녀';

    final result = await ParentChallengeScoreModal.show(
      context,
      challenge: challenge,
      childName: childName,
      childInfo: widget.selectedChild,
    );

    if (result != null) {
      // 평가 완료 후 데이터 새로고침
      await _loadRewardData();
    }
  }

  // 목표 완료 모달 표시
  Future<void> _showGoalCompletionModal(Map<String, dynamic> goal) async {
    if (widget.selectedChild == null) return;

    final childName =
        widget.selectedChild!['nickname'] ??
        widget.selectedChild!['realName'] ??
        '자녀';

    final result = await _showGoalCompleteModal(goal, childName);

    if (result == true) {
      // 목표 완료 처리 후 데이터 새로고침
      await _loadRewardData();
    }
  }

  // 목표 완료 모달
  Future<bool?> _showGoalCompleteModal(
    Map<String, dynamic> goal,
    String childName,
  ) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('🎉', style: TextStyle(fontSize: 48)),
                SizedBox(height: 16),
                Text(
                  '목표 완료!',
                  style: TextStyle(
                    fontSize: 20,
                    fontFamily: 'Pretendard-Bold',
                    color: Color(0xFF202020),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '${childName}님이 이번 주 목표를 완료했어요!',
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: 'Pretendard-Medium',
                    color: Color(0xFF666666),
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 4),
                Text(
                  '「${goal['title']}」',
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'Pretendard-Bold',
                    color: Color(0xFF5D9EFF),
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: Text(
                          '나중에',
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: 'Pretendard-Medium',
                            color: Color(0xFF999999),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF5D9EFF),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          '보상하기',
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: 'Pretendard-Medium',
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _toggleExpansion() {
    setState(() {
      _isExpanded = !_isExpanded;
    });

    if (_isExpanded) {
      _rotationController?.forward();
    } else {
      _rotationController?.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: ShapeDecoration(
        color: _isExpanded ? Colors.white : Color.fromRGBO(32, 32, 32, 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        shadows: [
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
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더 부분
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: ShapeDecoration(
              color: _isExpanded ? Colors.white : Color.fromRGBO(32, 32, 32, 1),
              shape: RoundedRectangleBorder(
                borderRadius:
                    _isExpanded
                        ? BorderRadius.only(
                          topLeft: Radius.circular(24),
                          topRight: Radius.circular(24),
                        )
                        : BorderRadius.circular(24),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        _isLoading
                            ? '보상 데이터 로딩 중...'
                            : _rewardItems.isEmpty
                            ? '지급할 보상이 없어요!'
                            : '아직 보상을 지급하지 않았어요!',
                        style: TextStyle(
                          color:
                              _isExpanded
                                  ? const Color(0xFF202020)
                                  : Color.fromRGBO(255, 166, 61, 1),
                          fontSize: 15,
                          fontFamily: 'Pretendard',
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.32,
                        ),
                      ),
                    ),
                    // 확장 버튼 (데이터가 있을 때만)
                    if (!_isLoading && _rewardItems.isNotEmpty)
                      GestureDetector(
                        onTap: _toggleExpansion,
                        child:
                            _rotationAnimation != null
                                ? AnimatedBuilder(
                                  animation: _rotationAnimation!,
                                  builder: (context, child) {
                                    return Transform.rotate(
                                      angle:
                                          _rotationAnimation!.value *
                                          3.14159, // 180도 회전
                                      child: Image.asset(
                                        'assets/icons/parent/확장.png',
                                        width: 20,
                                        height: 20,
                                        fit: BoxFit.cover,
                                        color:
                                            _isExpanded ? null : Colors.white,
                                      ),
                                    );
                                  },
                                )
                                : Image.asset(
                                  'assets/icons/parent/확장.png',
                                  width: 20,
                                  height: 20,
                                  fit: BoxFit.cover,
                                  color: _isExpanded ? null : Colors.white,
                                ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                _isLoading
                    ? Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color:
                                _isExpanded
                                    ? const Color(0xFF146AFF)
                                    : Colors.white,
                            strokeWidth: 2,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '로딩 중...',
                          style: TextStyle(
                            color:
                                _isExpanded
                                    ? const Color(0xFF146AFF)
                                    : Colors.white,
                            fontSize: 14,
                            fontFamily: 'Pretendard',
                            fontWeight: FontWeight.w400,
                            letterSpacing: -0.28,
                          ),
                        ),
                      ],
                    )
                    : Text(
                      '총 ${_rewardItems.length}건',
                      style: TextStyle(
                        color:
                            _isExpanded
                                ? const Color(0xFF146AFF)
                                : Colors.white,
                        fontSize: 18,
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.80,
                      ),
                    ),
              ],
            ),
          ),

          // 확장된 경우에만 아이템들 표시
          if (_isExpanded) ...[
            // 아이템들
            ..._rewardItems.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isLast = index == _rewardItems.length - 1;

              return Column(
                children: [
                  _buildRewardItem(
                    tags: List<String>.from(item['tags']),
                    tagColors: List<Color>.from(item['tagColors']),
                    dateTag: item['dateTag'],
                    title: item['title'],
                    reward: item['reward'],
                    isLast: isLast,
                    itemData: item, // 전체 아이템 데이터 전달
                  ),
                  // 구분선 (마지막 아이템이 아닐 때만)
                  if (!isLast)
                    Container(
                      height: 0.5,
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      color: Colors.grey[200],
                    ),
                ],
              );
            }).toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildRewardItem({
    required List<String> tags,
    required List<Color> tagColors,
    required String dateTag,
    required String title,
    required String reward,
    bool isLast = false,
    required Map<String, dynamic> itemData,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius:
              isLast
                  ? BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  )
                  : BorderRadius.zero,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 태그들
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (int i = 0; i < tags.length; i++)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: ShapeDecoration(
                    color: tagColors[i],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: Text(
                    tags[i],
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w300,
                      letterSpacing: -0.20,
                    ),
                  ),
                ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: ShapeDecoration(
                  color: const Color(0xFFE7ECF6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: Text(
                  dateTag,
                  style: TextStyle(
                    color: const Color(0xFF8490A3),
                    fontSize: 10,
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w300,
                    letterSpacing: -0.20,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // 제목과 보상금, 버튼
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: const Color(0xFF202020),
                        fontSize: 14,
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.28,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          '신청한 보상금',
                          style: TextStyle(
                            color: const Color(0xFF666666),
                            fontSize: 11,
                            fontFamily: 'Pretendard',
                            fontWeight: FontWeight.w300,
                            letterSpacing: -0.22,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          reward,
                          style: TextStyle(
                            color: const Color(0xFF3A88F4),
                            fontSize: 13,
                            fontFamily: 'Pretendard',
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.26,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => _sendReward(itemData),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: ShapeDecoration(
                    color: const Color(0xFF3A88F4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text(
                    '보내기',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w300,
                      letterSpacing: -0.22,
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
}
