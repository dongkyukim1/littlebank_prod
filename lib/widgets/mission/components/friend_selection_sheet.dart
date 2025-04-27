import 'package:flutter/material.dart';
import '../../../models/mission_data.dart';
import 'comparison_components.dart';

/// 친구 선택 바텀시트 컴포넌트
class FriendSelectionSheet extends StatelessWidget {
  final MissionData missionData;
  final Function(String) onFriendSelected;

  const FriendSelectionSheet({
    super.key,
    required this.missionData,
    required this.onFriendSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '친구 선택',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(),
          // 친구 목록
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                for (var friend in missionData.friends)
                  if (friend['name'] != missionData.selectedProfile)
                    ComparisonComponents.buildFriendItem(
                      context: context,
                      friend: friend,
                      onTap: () {
                        // 바텀시트를 닫기 전에 친구 선택 콜백 호출
                        onFriendSelected(friend['name']);
                      },
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 바텀시트를 표시하는 정적 메서드
  static void show({
    required BuildContext context,
    required MissionData missionData,
    required Function(String) onFriendSelected,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => FriendSelectionSheet(
            missionData: missionData,
            onFriendSelected: (friendName) {
              // 바텀시트 닫기
              Navigator.pop(context);

              // 약간의 딜레이 후 콜백 호출하여 친구 선택 처리
              Future.microtask(() {
                onFriendSelected(friendName);
                // 확실한 상태 업데이트를 위해 직접 알림 트리거
                missionData.notifyListeners();
              });
            },
          ),
    );
  }
}
