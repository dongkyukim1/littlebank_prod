import 'package:flutter/material.dart';
import '../../models/mission_data.dart';
import '../../theme/mission_styles.dart';
import 'components/comparison_components.dart';
import 'components/comparison_views.dart';
import 'components/friend_selection_sheet.dart';

/// 두 프로필 간의 미션 비교 패널 위젯
class ProfileComparisonPanel extends StatefulWidget {
  final MissionData missionData;
  final Function()? onClose; // 닫기 콜백 추가

  const ProfileComparisonPanel({
    super.key,
    required this.missionData,
    this.onClose,
  });

  @override
  State<ProfileComparisonPanel> createState() => _ProfileComparisonPanelState();
}

class _ProfileComparisonPanelState extends State<ProfileComparisonPanel> {
  @override
  void initState() {
    super.initState();
    widget.missionData.addListener(_updateState);
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

  @override
  Widget build(BuildContext context) {
    final selectedFriend = widget.missionData.friends.firstWhere(
      (f) => f['name'] == widget.missionData.selectedProfile,
      orElse: () => widget.missionData.friends[0],
    );

    // 패널이 닫혀있으면 간략한 결과와 다른 친구와 비교 버튼만 표시
    if (widget.missionData.isComparisonCollapsed) {
      return ComparisonViews.buildCollapsedResultView(
        context: context,
        missionData: widget.missionData,
        selectedFriend: selectedFriend,
        onExpand: widget.onClose ?? () {},
        onSelectNewFriend: () {
          FriendSelectionSheet.show(
            context: context,
            missionData: widget.missionData,
            onFriendSelected: (friendName) {
              // 친구 선택 처리
              setState(() {
                widget.missionData.selectedProfile = friendName;
                widget.missionData.selectedFriendName = friendName;
              });
            },
          );
        },
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 15),

        // 선택된 프로필 비교 패널
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
            boxShadow: MissionStyles.lightShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 비교 패널 헤더
              _buildPanelHeader(context),
              const SizedBox(height: 16),

              // 프로필 비교 정보
              Row(
                children: [
                  // 내 프로필 정보
                  ComparisonComponents.buildProfileInfo(
                    name: widget.missionData.myInfo['name'],
                    missions: widget.missionData.myInfo['missions'],
                    totalMissions: widget.missionData.myInfo['totalMissions'],
                    color: Colors.blue,
                    imagePath: 'assets/logos/search-sm.png',
                  ),

                  // vs 구분선
                  ComparisonComponents.buildVsDivider(),

                  // 선택된 친구 프로필 정보
                  ComparisonComponents.buildProfileInfo(
                    name: widget.missionData.selectedProfile,
                    missions: selectedFriend['missions'],
                    totalMissions: selectedFriend['totalMissions'],
                    color: Colors.orange,
                    imagePath: 'assets/logos/search-sm.png',
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // 미션 수행 비교 프로그레스 바
              _buildComparisonProgressBar(context, selectedFriend),

              // 간략 비교 뷰 (기본)
              if (!widget.missionData.detailedComparisonView)
                ComparisonViews.buildSimpleView(
                  context: context,
                  missionData: widget.missionData,
                  selectedFriend: selectedFriend,
                ),

              // 상세 비교 뷰
              if (widget.missionData.detailedComparisonView)
                ComparisonViews.buildDetailedView(
                  context: context,
                  missionData: widget.missionData,
                  selectedFriend: selectedFriend,
                ),
            ],
          ),
        ),

        const SizedBox(height: 20), // 다음 섹션과의 간격 추가
      ],
    );
  }

  Widget _buildPanelHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          '주간 미션 수행 비교',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Row(
          children: [
            // 자세히 버튼
            TextButton(
              onPressed: () {
                // 상세 보기 토글
                setState(() {
                  if (widget.missionData.detailedComparisonView) {
                    widget.missionData.detailedComparisonView = false;
                  } else {
                    widget.missionData.detailedComparisonView = true;
                  }
                });
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
              ),
              child: Text(
                widget.missionData.detailedComparisonView ? '간략히' : '자세히',
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // 닫기 버튼
            GestureDetector(
              onTap: widget.onClose, // 닫기 콜백 사용
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.close, size: 16, color: Colors.grey[600]),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildComparisonProgressBar(
    BuildContext context,
    Map<String, dynamic> selectedFriend,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: MissionStyles.progressCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 미션 차이 표시
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '미션 수행 차이: ',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              Text(
                '${(widget.missionData.myInfo['missions'] - selectedFriend['missions']).abs()} 개',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color:
                      widget.missionData.myInfo['missions'] >=
                              selectedFriend['missions']
                          ? Colors.blue
                          : Colors.orange,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // 미션 수행률 비교 프로그레스 바
          _buildProgressBar(context, selectedFriend),

          const SizedBox(height: 20),

          // 차이 설명 텍스트
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color:
                    selectedFriend['missions'] >
                            widget.missionData.myInfo['missions']
                        ? Colors.orange.withOpacity(0.1)
                        : Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                selectedFriend['missions'] >
                        widget.missionData.myInfo['missions']
                    ? '${widget.missionData.selectedProfile}님이 ${(selectedFriend['missions'] - widget.missionData.myInfo['missions']).abs()}개 더 많은 미션을 달성했어요'
                    : selectedFriend['missions'] <
                        widget.missionData.myInfo['missions']
                    ? '김동규님이 ${(widget.missionData.myInfo['missions'] - selectedFriend['missions']).abs()}개 더 많은 미션을 달성했어요'
                    : '두 분이 같은 수의 미션을 달성했어요',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color:
                      selectedFriend['missions'] >
                              widget.missionData.myInfo['missions']
                          ? Colors.orange
                          : Colors.blue,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(
    BuildContext context,
    Map<String, dynamic> selectedFriend,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final barWidth = constraints.maxWidth;
        final myPosition = barWidth * 0.3; // 기준점 위치

        // 차이값 계산 - 1개 차이도 크게 표시하도록 수정
        final diff =
            selectedFriend['missions'] - widget.missionData.myInfo['missions'];
        // 최소 10% ~ 최대 40%의 차이를 주도록 조정
        final scaledDiff =
            diff == 0 ? 0 : (diff.sign * (10 + (diff.abs() * 3)));
        final diffPercent = scaledDiff / 100.0;

        // 친구 위치 계산
        final friendPosition = myPosition + (barWidth * diffPercent);

        return ComparisonComponents.buildProgressBarWithProfiles(
          context: context,
          myPosition: myPosition,
          friendPosition: friendPosition,
          myInitial: widget.missionData.myInfo['name'].substring(0, 1),
          friendInitial: widget.missionData.selectedProfile.substring(0, 1),
          myMissions: widget.missionData.myInfo['missions'],
          friendMissions: selectedFriend['missions'],
        );
      },
    );
  }
}
