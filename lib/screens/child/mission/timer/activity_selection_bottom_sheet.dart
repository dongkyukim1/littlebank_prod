import 'package:flutter/material.dart';
import '../../../../services/mission_service.dart';
import '../../../../services/challenge_service.dart';
import '../../../../services/goal_service.dart';

class ActivitySelectionBottomSheet extends StatefulWidget {
  const ActivitySelectionBottomSheet({super.key});

  @override
  State<ActivitySelectionBottomSheet> createState() =>
      _ActivitySelectionBottomSheetState();
}

class _ActivitySelectionBottomSheetState
    extends State<ActivitySelectionBottomSheet> {
  List<ActivityItem> activities = [];
  int? selectedActivityId;
  bool isLoading = true;
  PageController _pageController = PageController();
  int _currentPageIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadActivities();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadActivities() async {
    try {
      setState(() {
        isLoading = true;
      });

      List<ActivityItem> loadedActivities = [];

      // 진행중인 미션 가져오기
      try {
        final missionResponse = await MissionService.getChildMissions();
        if (missionResponse != null && missionResponse['data'] != null) {
          final missions =
              (missionResponse['data'] as List)
                  .map((json) => MissionResponse.fromJson(json))
                  .where(
                    (mission) => mission.status == MissionStatus.ACCEPT,
                  ) // 진행중인 미션만
                  .toList();

          for (final mission in missions) {
            loadedActivities.add(
              ActivityItem(
                id: mission.missionId,
                title: mission.title,
                type: ActivityType.mission,
                category: MissionService.getTypeDisplayName(mission.type),
                dateRange: _formatDateRange(mission.startDate, mission.endDate),
              ),
            );
          }
        }
      } catch (e) {
        print('미션 로드 실패: $e');
      }

      // 진행중인 챌린지 가져오기
      try {
        final challengeResponse = await ChallengeService.getMyChallenges(
          challengeStatus: ChallengeStatus.ONGOING,
        );

        for (final challenge in challengeResponse.data) {
          if (challenge.isAccepted) {
            loadedActivities.add(
              ActivityItem(
                id: challenge.participationId,
                title: challenge.title,
                type: ActivityType.challenge,
                category: '챌린지',
                dateRange: _formatDateRange(
                  DateTime.parse(challenge.startDate),
                  DateTime.parse(challenge.endDate),
                ),
              ),
            );
          }
        }
      } catch (e) {
        print('챌린지 로드 실패: $e');
      }

      // 샘플 데이터 추가 (실제 목표 API가 없는 경우)
      loadedActivities.addAll([
        ActivityItem(
          id: 9001,
          title: '매일 아침 스스로 일어나기',
          type: ActivityType.goal,
          category: '가족 미션',
          dateRange: '03. 25 - 03. 28',
        ),
        ActivityItem(
          id: 9002,
          title: '영어 리스닝 챕터 6까지 풀어가기',
          type: ActivityType.mission,
          category: '학원 미션',
          dateRange: '03. 25 - 03. 28',
        ),
      ]);

      setState(() {
        activities = loadedActivities;
        isLoading = false;
      });
    } catch (e) {
      print('활동 로드 중 오류: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  String _formatDateRange(DateTime start, DateTime end) {
    final startStr =
        '${start.month.toString().padLeft(2, '0')}. ${start.day.toString().padLeft(2, '0')}';
    final endStr =
        '${end.month.toString().padLeft(2, '0')}. ${end.day.toString().padLeft(2, '0')}';
    return '$startStr - $endStr';
  }

  int _getPageCount() {
    return (activities.length / 3).ceil();
  }

  List<Widget> _buildPageItems(int pageIndex, double maxWidth, bool isTablet) {
    final startIndex = pageIndex * 3;
    final endIndex =
        (startIndex + 3 < activities.length)
            ? startIndex + 3
            : activities.length;

    List<Widget> pageItems = [];

    for (int i = startIndex; i < endIndex; i++) {
      pageItems.add(_buildActivityItem(activities[i], maxWidth, isTablet));
    }

    return pageItems;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isTablet = screenWidth > 600;
    final maxWidth = isTablet ? 600.0 : screenWidth;

    // 동적 높이 계산 - 콤팩트하게 조정
    final itemHeight = 80.0; // 각 아이템 실제 높이
    final headerHeight = 90.0; // 헤더 실제 높이
    final buttonHeight = 56.0; // 버튼 영역 실제 높이
    final pageCount = activities.isEmpty ? 1 : (activities.length / 3).ceil();
    final indicatorHeight = pageCount > 1 ? 20.0 : 0.0; // 인디케이터 높이

    // 실제 표시될 아이템 수 (최대 3개)
    final itemsToShow =
        activities.isEmpty
            ? 1
            : (activities.length >= 3 ? 3 : activities.length);
    final dynamicHeight =
        headerHeight +
        (itemHeight * itemsToShow) +
        indicatorHeight +
        buttonHeight;

    return IntrinsicHeight(
      child: Container(
        width: maxWidth,
        constraints: BoxConstraints(maxHeight: screenHeight * 0.7),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 헤더
            Container(
              width: maxWidth,
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 32 : 20,
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '어떤 활동으로 기록할까요?',
                        style: TextStyle(
                          color: Color(0xFF202020),
                          fontSize: 18,
                          fontFamily: 'Pretendard-Bold',
                          letterSpacing: -0.72,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(),
                          child: const Icon(
                            Icons.close,
                            size: 20,
                            color: Color(0xFF999999),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '내 활약을 기록하고 자랑해 보세요',
                    style: TextStyle(
                      color: Color(0xFF999999),
                      fontSize: 14,
                      fontFamily: 'Pretendard-Light',
                      letterSpacing: -0.28,
                    ),
                  ),
                ],
              ),
            ),

            // 활동 목록
            Flexible(
              child:
                  isLoading
                      ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF146AFF),
                        ),
                      )
                      : activities.isEmpty
                      ? Container(
                        width: maxWidth,
                        padding: EdgeInsets.symmetric(
                          horizontal: isTablet ? 32 : 20,
                          vertical: 40,
                        ),
                        color: Colors.white,
                        child: const Center(
                          child: Text(
                            '진행 중인 활동이 없습니다',
                            style: TextStyle(
                              color: Color(0xFF999999),
                              fontSize: 16,
                              fontFamily: 'Pretendard-Regular',
                            ),
                          ),
                        ),
                      )
                      : Column(
                        children: [
                          // 페이지뷰
                          SizedBox(
                            height: 310.0, // 고정 높이 (오버플로우 해결을 위해 추가 여유)
                            child: PageView.builder(
                              controller: _pageController,
                              onPageChanged: (index) {
                                setState(() {
                                  _currentPageIndex = index;
                                });
                              },
                              itemCount: _getPageCount(),
                              itemBuilder: (context, pageIndex) {
                                return Container(
                                  color: Colors.white,
                                  child: Column(
                                    children: [
                                      ..._buildPageItems(
                                        pageIndex,
                                        maxWidth,
                                        isTablet,
                                      ),
                                      // 페이지 인디케이터를 각 페이지에 포함
                                      if (_getPageCount() > 1)
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.only(
                                            top: 12,
                                            bottom: 4,
                                            left: 32,
                                            right: 32,
                                          ),
                                          child: Center(
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: List.generate(_getPageCount(), (
                                                index,
                                              ) {
                                                final isCurrentPage =
                                                    _currentPageIndex == index;
                                                return Container(
                                                  margin: EdgeInsets.only(
                                                    right:
                                                        index <
                                                                _getPageCount() -
                                                                    1
                                                            ? 4
                                                            : 0,
                                                  ),
                                                  width: isCurrentPage ? 28 : 6,
                                                  height: 6,
                                                  decoration: ShapeDecoration(
                                                    color:
                                                        isCurrentPage
                                                            ? const Color(
                                                              0xFF5D9EFF,
                                                            )
                                                            : const Color(
                                                              0xFFDADADA,
                                                            ),
                                                    shape:
                                                        isCurrentPage
                                                            ? RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    4,
                                                                  ),
                                                            )
                                                            : const OvalBorder(),
                                                  ),
                                                );
                                              }),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
            ),

            // 선택 완료 버튼
            Container(
              width: maxWidth,
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 32 : 10,
                vertical: 12,
              ),
              color: Colors.white,
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed:
                      selectedActivityId != null ? _onCompleteSelection : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        selectedActivityId != null
                            ? const Color(0xFF146AFF)
                            : const Color(0xFFE0E0E0),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    '선택 완료',
                    style: TextStyle(
                      color:
                          selectedActivityId != null
                              ? Colors.white
                              : const Color(0xFF999999),
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
      ),
    );
  }

  Widget _buildActivityItem(
    ActivityItem activity,
    double maxWidth,
    bool isTablet,
  ) {
    final isSelected = selectedActivityId == activity.id;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedActivityId = isSelected ? null : activity.id;
        });
      },
      child: Container(
        width: maxWidth,
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 32 : 20,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF0F7FF) : Colors.white,
          border:
              isSelected
                  ? const Border(
                    left: BorderSide(color: Color(0xFF146AFF), width: 3),
                  )
                  : null,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
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
                          _getActivityTypeLabel(activity.type),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontFamily: 'Pretendard-Light',
                            letterSpacing: -0.24,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
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
                          activity.category,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontFamily: 'Pretendard-Light',
                            letterSpacing: -0.24,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: ShapeDecoration(
                          color: const Color(0xFFE7ECF6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          activity.dateRange,
                          style: const TextStyle(
                            color: Color(0xFF8490A3),
                            fontSize: 12,
                            fontFamily: 'Pretendard-Light',
                            letterSpacing: -0.24,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    activity.title,
                    style: const TextStyle(
                      color: Color(0xFF353535),
                      fontSize: 18,
                      fontFamily: 'Pretendard-Bold',
                      letterSpacing: -0.72,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Color(0xFF146AFF),
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  String _getActivityTypeLabel(ActivityType type) {
    switch (type) {
      case ActivityType.mission:
        return '미션';
      case ActivityType.challenge:
        return '챌린지';
      case ActivityType.goal:
        return '목표';
    }
  }

  void _onCompleteSelection() {
    if (selectedActivityId != null) {
      final selectedActivity = activities.firstWhere(
        (activity) => activity.id == selectedActivityId,
      );

      // 선택된 활동 정보를 반환하고 바텀 시트 닫기
      Navigator.of(context).pop(selectedActivity);
    }
  }
}

// 활동 아이템 모델
class ActivityItem {
  final int id;
  final String title;
  final ActivityType type;
  final String category;
  final String dateRange;

  ActivityItem({
    required this.id,
    required this.title,
    required this.type,
    required this.category,
    required this.dateRange,
  });
}

// 활동 타입 열거형
enum ActivityType { mission, challenge, goal }

// 활동 선택 바텀 시트를 보여주는 함수
Future<ActivityItem?> showActivitySelectionBottomSheet(BuildContext context) {
  return showModalBottomSheet<ActivityItem>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const ActivitySelectionBottomSheet(),
  );
}
