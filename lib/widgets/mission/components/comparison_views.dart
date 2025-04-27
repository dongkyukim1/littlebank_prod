import 'package:flutter/material.dart';
import '../../../theme/mission_styles.dart';
import '../../../models/mission_data.dart';
import 'comparison_components.dart';
import 'friend_selection_sheet.dart';

/// 미션 비교 뷰 컴포넌트들
class ComparisonViews {
  /// 간략 비교 뷰
  static Widget buildSimpleView({
    required BuildContext context,
    required MissionData missionData,
    required Map<String, dynamic> selectedFriend,
  }) {
    final bool isWin =
        missionData.myInfo['missions'] >= selectedFriend['missions'];

    return Column(
      children: [
        const SizedBox(height: 16),

        // 미션 결과 표시
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          decoration: BoxDecoration(
            color:
                isWin
                    ? Colors.blue.withOpacity(0.1)
                    : Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isWin ? Icons.emoji_events : Icons.sentiment_dissatisfied,
                color: isWin ? Colors.blue : Colors.orange,
                size: 18,
              ),
              const SizedBox(width: 9),
              Text(
                isWin
                    ? '${missionData.myInfo['name']}님이 ${(missionData.myInfo['missions'] - selectedFriend['missions']).abs()}개 미션을 더 수행했어요!'
                    : '${missionData.selectedProfile}님이 ${(missionData.myInfo['missions'] - selectedFriend['missions']).abs()}개 미션을 더 수행했어요!',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isWin ? Colors.blue : Colors.orange,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // 다른 친구와 비교하기 버튼 추가
        buildCompareWithOtherFriendButton(
          context,
          missionData,
          onNewFriendSelected: (friendName) {
            // 직접 missionData 업데이트
            missionData.selectedFriendName = friendName;
            missionData.selectedProfile = friendName;
          },
        ),
      ],
    );
  }

  /// 상세 비교 뷰
  static Widget buildDetailedView({
    required BuildContext context,
    required MissionData missionData,
    required Map<String, dynamic> selectedFriend,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        const Text(
          '미션 카테고리별 현황',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // 카테고리별 미션 현황
        ComparisonComponents.buildCategoryComparisonItem(
          context: context,
          category: '공부',
          myCount: 6,
          myTotal: 10, // 내 미션
          friendCount: 8,
          friendTotal: 12, // 친구 미션
          myInitial: missionData.myInfo['name'].substring(0, 1),
          friendInitial: missionData.selectedProfile.substring(0, 1),
          myColor: Colors.blue,
          friendColor: Colors.red,
        ),
        const SizedBox(height: 20),

        ComparisonComponents.buildCategoryComparisonItem(
          context: context,
          category: '운동',
          myCount: 4,
          myTotal: 6, // 내 미션
          friendCount: 5,
          friendTotal: 8, // 친구 미션
          myInitial: missionData.myInfo['name'].substring(0, 1),
          friendInitial: missionData.selectedProfile.substring(0, 1),
          myColor: Colors.blue,
          friendColor: Colors.red,
        ),
        const SizedBox(height: 20),

        ComparisonComponents.buildCategoryComparisonItem(
          context: context,
          category: '독서',
          myCount: 2,
          myTotal: 4, // 내 미션
          friendCount: 3,
          friendTotal: 5, // 친구 미션
          myInitial: missionData.myInfo['name'].substring(0, 1),
          friendInitial: missionData.selectedProfile.substring(0, 1),
          myColor: Colors.blue,
          friendColor: Colors.red,
        ),

        const SizedBox(height: 24),

        // 순위 정보
        Row(
          children: [
            // 내 순위 정보
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.emoji_events, color: Colors.blue, size: 16),
                        const SizedBox(width: 4),
                        const Text(
                          '상위 32%',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      missionData.myInfo['name'],
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 12),

            // 친구 순위 정보
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.emoji_events,
                          color: Colors.orange,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          '상위 28%',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      missionData.selectedProfile,
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // 다른 친구와 비교하기 버튼 추가
        buildCompareWithOtherFriendButton(
          context,
          missionData,
          onNewFriendSelected: (friendName) {
            // 직접 missionData 업데이트
            missionData.selectedFriendName = friendName;
            missionData.selectedProfile = friendName;
          },
        ),
      ],
    );
  }

  /// 접힌 상태의 간략한 결과 뷰
  static Widget buildCollapsedResultView({
    required BuildContext context,
    required MissionData missionData,
    required Map<String, dynamic> selectedFriend,
    required Function() onExpand,
    required Function() onSelectNewFriend,
  }) {
    final bool isWin =
        missionData.myInfo['missions'] >= selectedFriend['missions'];

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        children: [
          // 간략한 결과 표시
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color:
                  isWin
                      ? Colors.blue.withOpacity(0.1)
                      : Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              boxShadow: MissionStyles.lightShadow,
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isWin ? Icons.emoji_events : Icons.sentiment_dissatisfied,
                      color: isWin ? Colors.blue : Colors.orange,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      isWin
                          ? '${missionData.myInfo['name']}님이 ${(missionData.myInfo['missions'] - selectedFriend['missions']).abs()}개 미션을 더 수행했어요!'
                          : '${missionData.selectedProfile}님이 ${(selectedFriend['missions'] - missionData.myInfo['missions']).abs()}개 미션을 더 수행했어요!',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isWin ? Colors.blue : Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: onExpand,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color:
                            isWin
                                ? Colors.blue.withOpacity(0.5)
                                : Colors.orange.withOpacity(0.5),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.expand_more,
                          size: 18,
                          color: isWin ? Colors.blue : Colors.orange,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '자세히 보기',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isWin ? Colors.blue : Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // 다른 친구와 비교 버튼
          InkWell(
            onTap: onSelectNewFriend,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: MissionStyles.lightShadow,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people,
                    size: 20,
                    color: MissionStyles.primaryBlue,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '다른 친구와 비교하기',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: MissionStyles.primaryBlue,
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

  // 다른 친구와 비교하기 버튼 구현
  static Widget buildCompareWithOtherFriendButton(
    BuildContext context,
    MissionData missionData, {
    required Function(String) onNewFriendSelected,
  }) {
    return InkWell(
      onTap: () {
        // 친구 선택 UI 표시
        FriendSelectionSheet.show(
          context: context,
          missionData: missionData,
          onFriendSelected: (friendName) {
            // 선택된 친구 정보로 데이터 업데이트
            missionData.selectedProfile = friendName;
            missionData.selectedFriendName = friendName;

            // 콜백 호출하여 상위 위젯의 상태 업데이트
            onNewFriendSelected(friendName);

            // 확실한 상태 업데이트를 위해 추가 알림
            Future.microtask(() {
              missionData.notifyListeners();
            });
          },
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: MissionStyles.primaryBlue.withOpacity(0.5)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people, size: 16, color: MissionStyles.primaryBlue),
            const SizedBox(width: 6),
            Text(
              '다른 친구와 비교하기',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: MissionStyles.primaryBlue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
