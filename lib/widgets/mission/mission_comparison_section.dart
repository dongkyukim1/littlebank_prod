import 'package:flutter/material.dart';
import '../../models/mission_data.dart';
import 'profile_comparison_panel.dart';
import 'friend_profile_item.dart';
import 'mission_progress_display.dart';

/// 친구와 미션 비교하는 섹션 위젯
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
    // 선택된 친구 정보 가져오기
    final selectedFriend = widget.missionData.friends.firstWhere(
      (friend) => friend['name'] == widget.missionData.selectedFriendName,
      orElse: () => widget.missionData.friends[0], // 기본값
    );

    // 미션 수행 비교 결과를 계산하는 로직
    final int myMissions = widget.missionData.myInfo['missions'];
    final int friendMissions = selectedFriend['missions'];
    final int difference = (friendMissions - myMissions).abs();
    final bool isWin = myMissions > friendMissions;

    return Container(
      key: widget.missionData.missionComparisonKey,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(isWin),
          SizedBox(height: 24),

          // 친구 선택 UI (친구가 선택되지 않았을 때)
          if (!widget.missionData.isFriendSelected) _buildFriendSelectionUI(),

          // 친구가 선택되었고 비교 섹션이 확장되었을 때 (덮어지는 대신 추가됨)
          if (widget.missionData.isComparisonExpanded)
            SingleChildScrollView(
              child: ProfileComparisonPanel(
                missionData: widget.missionData,
                onClose: () {
                  setState(() {
                    // 모든 관련 상태를 초기화
                    widget.missionData.isComparisonExpanded = false;
                    widget.missionData.isComparisonCollapsed = false;
                    widget.missionData.isFriendSelected = false;
                    widget.missionData.showComparisonPanel = false;
                  });
                },
              ),
            ),

          // 친구가 선택되었을 때만 (접힌 상태가 아닐 때만 상세 컨텐츠 표시)
          if (widget.missionData.isFriendSelected &&
              !widget.missionData.isComparisonCollapsed)
            _buildDetailedComparisonSection(
              selectedFriend,
              myMissions,
              friendMissions,
              difference,
              isWin,
            ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(bool isWin) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '친구와 미션 수행 비교',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 4),
              Text(
                '이번 주 미션 수행 현황을 친구와 비교해보세요',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ],
          ),
        ),

        // 접는 버튼 추가
        if (widget.missionData.isFriendSelected)
          Row(
            children: [
              // 접는/펼치는 버튼
              IconButton(
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(),
                onPressed: () {
                  setState(() {
                    widget.missionData.isComparisonCollapsed =
                        !widget.missionData.isComparisonCollapsed;
                    widget.missionData.isComparisonExpanded =
                        false; // 확장 상태 초기화
                  });
                },
                icon: Icon(
                  widget.missionData.isComparisonCollapsed
                      ? Icons.keyboard_arrow_down
                      : Icons.keyboard_arrow_up,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(width: 8),

              // 승패 결과 버튼
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isWin ? Colors.blue[50] : Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isWin ? Icons.emoji_events : Icons.sentiment_dissatisfied,
                      color: isWin ? Colors.blue : Colors.red,
                      size: 16,
                    ),
                    SizedBox(width: 4),
                    Text(
                      isWin ? '승리' : '패배',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isWin ? Colors.blue : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildFriendSelectionUI() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '친구를 선택해서 미션 비교하기',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 10),

        // 친구 목록 가로 스크롤
        SizedBox(
          height: 100,
          width: double.infinity,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.start,
            children:
                widget.missionData.friends.map((friend) {
                  return FriendProfileItem(
                    friend: friend,
                    onTap: () => _selectFriend(friend['name']),
                  );
                }).toList(),
          ),
        ),

        SizedBox(height: 20),

        // 프로그레스바 안에 프로필 이미지
        MissionProgressDisplay(missionData: widget.missionData),
      ],
    );
  }

  Widget _buildDetailedComparisonSection(
    Map<String, dynamic> selectedFriend,
    int myMissions,
    int friendMissions,
    int difference,
    bool isWin,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 선택된 친구 정보
        Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white,
              child: ClipOval(
                child: Image.asset(
                  'assets/logos/search-sm.png',
                  width: 30,
                  height: 30,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.missionData.selectedFriendName,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${difference.toString()}개 미션 차이',
                    style: TextStyle(
                      fontSize: 12,
                      color: isWin ? Colors.blue : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Spacer(),
            InkWell(
              onTap: () {
                // 다른 친구 선택
                setState(() {
                  widget.missionData.isFriendSelected = false;
                });
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Text('다른 친구', style: TextStyle(fontSize: 13)),
                    SizedBox(width: 4),
                    Icon(Icons.swap_horiz, size: 16),
                  ],
                ),
              ),
            ),
          ],
        ),

        // 상세 정보 표시 부분
        SizedBox(height: 30),
        Text(
          '주간 미션 수행 비교',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 16),

        // 나의 미션 프로그레스 바
        _buildProgressBar(
          '나',
          myMissions,
          widget.missionData.myInfo['totalMissions'],
          Colors.blue,
        ),
        SizedBox(height: 20),

        // 친구 미션 프로그레스 바
        _buildProgressBar(
          widget.missionData.selectedFriendName,
          friendMissions,
          selectedFriend['totalMissions'],
          Colors.red,
        ),
        SizedBox(height: 16),

        // 미션 카테고리별 비교
        Text(
          '카테고리별 비교',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 16),

        // 공부 카테고리
        _buildCategoryComparison('공부', 8, 10, 7, 10),
        SizedBox(height: 12),

        // 운동 카테고리
        _buildCategoryComparison('운동', 2, 5, 5, 5),
        SizedBox(height: 12),

        // 독서 카테고리
        _buildCategoryComparison('독서', 2, 5, 3, 5),

        SizedBox(height: 20),

        // 하단 결과 버튼
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isWin ? Colors.blue[50] : Colors.red[50],
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isWin ? Icons.emoji_events : Icons.sentiment_dissatisfied,
                color: isWin ? Colors.blue : Colors.red,
                size: 18,
              ),
              SizedBox(width: 8),
              Text(
                isWin
                    ? '${widget.missionData.selectedFriendName}와의 비교: 승리 ($difference미션 차이)'
                    : '${widget.missionData.selectedFriendName}와의 비교: 패배 ($difference미션 차이)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isWin ? Colors.blue : Colors.red,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar(
    String name,
    int missions,
    int totalMissions,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: Colors.blue.withOpacity(0.1),
              child: ClipOval(
                child: Image.asset(
                  'assets/logos/search-sm.png',
                  width: 22,
                  height: 22,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SizedBox(width: 8),
            Text(
              name,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            Spacer(),
            Text(
              '$missions/$totalMissions 미션',
              style: TextStyle(
                fontSize: 14,
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Stack(
          children: [
            // 배경 바
            Container(
              height: 10,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            // 진행 바
            Container(
              height: 10,
              width:
                  (missions / totalMissions) *
                  MediaQuery.of(context).size.width *
                  0.77,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryComparison(
    String category,
    int myCount,
    int myTotal,
    int friendCount,
    int friendTotal,
  ) {
    final bool isWin = myCount > friendCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 카테고리 제목
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              // 카테고리 라벨 (공부, 운동, 독서 등)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  category,
                  style: const TextStyle(
                    fontSize: 13, 
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),

        // 내 현황 (김동규)
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 내 이름 표시 (프로그레스바 위에)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: Colors.blue.withOpacity(0.2),
                      child: Text(
                        '김',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      '김동규',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
              
              // 내 프로그레스바와 수치
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 내 미션 수행 정보
                  Expanded(
                    child: Stack(
                      children: [
                        // 배경 바
                        Container(
                          height: 10,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                        // 진행 바
                        Container(
                          height: 10,
                          width: (myCount / myTotal) * 
                                MediaQuery.of(context).size.width * 0.77,
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // 미션 수행 수치
                  Container(
                    margin: const EdgeInsets.only(left: 12),
                    child: Text(
                      '$myCount/$myTotal',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // 친구 현황
        Container(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 친구 이름 표시 (프로그레스바 위에)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: Colors.red.withOpacity(0.2),
                      child: Text(
                        widget.missionData.selectedFriendName.substring(0, 1),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      widget.missionData.selectedFriendName,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
              
              // 친구 프로그레스바와 수치
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 친구 미션 수행 정보
                  Expanded(
                    child: Stack(
                      children: [
                        // 배경 바
                        Container(
                          height: 10,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                        // 진행 바
                        Container(
                          height: 10,
                          width: (friendCount / friendTotal) * 
                                MediaQuery.of(context).size.width * 0.77,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // 미션 수행 수치
                  Container(
                    margin: const EdgeInsets.only(left: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$friendCount/$friendTotal',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _selectFriend(String name) {
    setState(() {
      widget.missionData.selectedFriendName = name;
      widget.missionData.isFriendSelected = true;
      widget.missionData.isComparisonCollapsed = false;
      widget.missionData.isComparisonExpanded = true; // VS 카드를 표시하기 위해 true로 변경
      widget.missionData.showComparisonPanel = true;
      widget.missionData.selectedProfile = name;
      widget.missionData.detailedComparisonView = false;
    });

    // 미션 비교 섹션으로 스크롤
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.missionData.missionComparisonKey.currentContext != null) {
        Scrollable.ensureVisible(
          widget.missionData.missionComparisonKey.currentContext!,
          duration: Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }
}
