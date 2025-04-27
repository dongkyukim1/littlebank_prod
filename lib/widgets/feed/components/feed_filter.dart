import 'package:flutter/material.dart';
import '../../../models/feed_data.dart';
import '../../../theme/feed_styles.dart';

class FeedFilter extends StatelessWidget {
  final FeedData feedData;
  final Function(int, int) onFilterChange;
  final Function(int) onGradeFilterChange;

  const FeedFilter({
    super.key,
    required this.feedData,
    required this.onFilterChange,
    required this.onGradeFilterChange,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.only(
        left: 15.0,
        right: 15.0,
        top: 8.0,
        bottom: 8.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8.0,
            children: [
              // 학년별 필터
              _buildGradeFilter(),
              // 과목별 필터
              _buildSubjectFilter(),
              // 미션 종류 필터
              _buildMissionTypeFilter(),
            ],
          ),
        ],
      ),
    );
  }

  // 학년별 필터 위젯
  Widget _buildGradeFilter() {
    return PopupMenuButton<int>(
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onSelected: (int index) {
        if (index == -1) {
          // '학년별' 선택 시 필터 비활성화
          onGradeFilterChange(-1);
        } else {
          onGradeFilterChange(index);
        }
      },
      itemBuilder: (context) {
        return [
          PopupMenuItem<int>(
            value: 0,
            child: Text(
              '초등학생',
              style: TextStyle(
                fontWeight:
                    feedData.selectedGradeFilter == 0 &&
                            feedData.isGradeFilterExpanded
                        ? FontWeight.bold
                        : FontWeight.normal,
              ),
            ),
          ),
          PopupMenuItem<int>(
            value: 1,
            child: Text(
              '중학생',
              style: TextStyle(
                fontWeight:
                    feedData.selectedGradeFilter == 1 &&
                            feedData.isGradeFilterExpanded
                        ? FontWeight.bold
                        : FontWeight.normal,
              ),
            ),
          ),
          PopupMenuItem<int>(
            value: 2,
            child: Text(
              '고등학생',
              style: TextStyle(
                fontWeight:
                    feedData.selectedGradeFilter == 2 &&
                            feedData.isGradeFilterExpanded
                        ? FontWeight.bold
                        : FontWeight.normal,
              ),
            ),
          ),
          PopupMenuItem<int>(
            value: -1,
            child: const Text(
              '학년별',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
            ),
          ),
        ];
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: FeedStyles.filterChipDecoration(
          isSelected: feedData.isGradeFilterExpanded,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              feedData.isGradeFilterExpanded
                  ? feedData.filterOptions[0][feedData.selectedGradeFilter]
                  : '학년별',
              style: FeedStyles.filterChipTextStyle(
                isSelected: feedData.isGradeFilterExpanded,
              ),
            ),
            const SizedBox(width: 5),
            Icon(
              Icons.keyboard_arrow_down,
              color:
                  feedData.isGradeFilterExpanded
                      ? Colors.white
                      : FeedStyles.textDarkColor,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  // 과목별 필터 위젯
  Widget _buildSubjectFilter() {
    return PopupMenuButton<int>(
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onSelected: (int index) {
        if (index == -1) {
          // '과목별' 선택 시 필터 비활성화
          onFilterChange(1, -1);
        } else {
          onFilterChange(1, index);
        }
      },
      itemBuilder: (context) {
        List<PopupMenuItem<int>> items = List.generate(
          feedData.filterOptions[1].length,
          (index) => PopupMenuItem<int>(
            value: index,
            child: Text(
              feedData.filterOptions[1][index],
              style: TextStyle(
                fontWeight:
                    feedData.selectedOptionIndex[1] == index &&
                            feedData.isFilterExpanded[1]
                        ? FontWeight.bold
                        : FontWeight.normal,
              ),
            ),
          ),
        );

        // 필터 비활성화 옵션 추가
        items.add(
          const PopupMenuItem<int>(
            value: -1,
            child: Text(
              '과목별',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
            ),
          ),
        );

        return items;
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: FeedStyles.filterChipDecoration(
          isSelected: feedData.isFilterExpanded[1],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              feedData.isFilterExpanded[1]
                  ? feedData.filterOptions[1][feedData.selectedOptionIndex[1]]
                  : '과목별',
              style: FeedStyles.filterChipTextStyle(
                isSelected: feedData.isFilterExpanded[1],
              ),
            ),
            const SizedBox(width: 5),
            Icon(
              Icons.keyboard_arrow_down,
              color:
                  feedData.isFilterExpanded[1]
                      ? Colors.white
                      : FeedStyles.textDarkColor,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  // 미션 종류 필터 위젯
  Widget _buildMissionTypeFilter() {
    return PopupMenuButton<int>(
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onSelected: (int index) {
        if (index == -1) {
          // '미션 종류' 선택 시 필터 비활성화
          onFilterChange(2, -1);
        } else {
          onFilterChange(2, index);
        }
      },
      itemBuilder: (context) {
        List<PopupMenuItem<int>> items = List.generate(
          feedData.filterOptions[2].length,
          (index) => PopupMenuItem<int>(
            value: index,
            child: Text(
              feedData.filterOptions[2][index],
              style: TextStyle(
                fontWeight:
                    feedData.selectedOptionIndex[2] == index &&
                            feedData.isFilterExpanded[2]
                        ? FontWeight.bold
                        : FontWeight.normal,
              ),
            ),
          ),
        );

        // 필터 비활성화 옵션 추가
        items.add(
          const PopupMenuItem<int>(
            value: -1,
            child: Text(
              '미션 종류',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
            ),
          ),
        );

        return items;
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: FeedStyles.filterChipDecoration(
          isSelected: feedData.isFilterExpanded[2],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              feedData.isFilterExpanded[2]
                  ? feedData.filterOptions[2][feedData.selectedOptionIndex[2]]
                  : '미션 종류',
              style: FeedStyles.filterChipTextStyle(
                isSelected: feedData.isFilterExpanded[2],
              ),
            ),
            const SizedBox(width: 5),
            Icon(
              Icons.keyboard_arrow_down,
              color:
                  feedData.isFilterExpanded[2]
                      ? Colors.white
                      : FeedStyles.textDarkColor,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
