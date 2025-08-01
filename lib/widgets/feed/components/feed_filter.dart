import 'package:flutter/material.dart';
import '../../../models/feed_data.dart';

class FeedFilter extends StatefulWidget {
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
  State<FeedFilter> createState() => _FeedFilterState();
}

class _FeedFilterState extends State<FeedFilter> {
  // 각 버튼에 대한 GlobalKey
  final GlobalKey _gradeButtonKey = GlobalKey();
  final GlobalKey _subjectButtonKey = GlobalKey();
  final GlobalKey _typeButtonKey = GlobalKey();

  // 학년 필터 매핑 (String -> int)
  Map<String, int> gradeMapping = {
    'ALL': 3,
    'ELEMENTARY': 0,
    'MIDDLE': 1,
    'HIGH': 2,
  };

  // int -> String 변환
  Map<int, String> gradeReverseMapping = {
    0: 'ELEMENTARY',
    1: 'MIDDLE',
    2: 'HIGH',
    3: 'ALL',
  };

  @override
  Widget build(BuildContext context) {
    // 화면 너비에 따라 버튼 크기 조정 (크기 키우기)
    final double buttonScale = 0.8; // 이전 2/3에서 증가
    final double horizontalPadding = 24 * buttonScale;
    final double verticalPadding = 12 * buttonScale;
    final double screenWidth = MediaQuery.of(context).size.width;

    // 버튼 사이의 간격 계산
    final double buttonSpacing = 16;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: const Color(0xFFF0F2F7), // 배경색을 #F0F2F7로 변경
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 일정한 간격으로 버튼 배치
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 학년군 필터
              _buildFilterButton(
                _gradeButtonKey,
                '학년군',
                widget.feedData.isGradeFilterExpanded,
                horizontalPadding,
                verticalPadding,
                () => _showGradeFilterPopup(_gradeButtonKey),
              ),

              SizedBox(width: buttonSpacing),

              // 과목별 필터
              _buildFilterButton(
                _subjectButtonKey,
                '과목별',
                widget.feedData.isFilterExpanded[1],
                horizontalPadding,
                verticalPadding,
                () => _showSubjectFilterPopup(_subjectButtonKey),
              ),

              SizedBox(width: buttonSpacing),

              // 유형별 필터 (이전 미션 종류)
              _buildFilterButton(
                _typeButtonKey,
                '유형별',
                widget.feedData.isFilterExpanded[2],
                horizontalPadding,
                verticalPadding,
                () => _showMissionTypeFilterPopup(_typeButtonKey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 새로운 필터 버튼 위젯
  Widget _buildFilterButton(
    GlobalKey key,
    String label,
    bool isSelected,
    double horizontalPadding,
    double verticalPadding,
    VoidCallback onTap,
  ) {
    return InkWell(
      key: key,
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: verticalPadding,
        ),
        decoration: ShapeDecoration(
          color: const Color(0xFF5C697E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 필터 라벨 (선택된 경우 선택된 값 표시)
                Text(
                  _getButtonLabel(label, isSelected),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12, // 폰트 크기 14px에서 12px로 줄임
                    fontFamily: 'Pretendard-Light',
                    letterSpacing: -0.28,
                  ),
                ),
                const SizedBox(width: 8),
                // 드롭다운 아이콘
                Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 12),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 학년군 필터 팝업
  void _showGradeFilterPopup(GlobalKey buttonKey) {
    // 버튼 정보 가져오기
    final RenderBox? button =
        buttonKey.currentContext?.findRenderObject() as RenderBox?;
    if (button == null) return;

    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;

    // 버튼의 위치와 크기 정보
    final buttonPosition = button.localToGlobal(Offset.zero, ancestor: overlay);
    final buttonSize = button.size;

    // 팝업 메뉴 위치 설정 - 버튼 바로 아래에 나타나도록
    final RelativeRect position = RelativeRect.fromLTRB(
      buttonPosition.dx, // 왼쪽
      buttonPosition.dy + buttonSize.height, // 위쪽 (버튼 아래)
      buttonPosition.dx + buttonSize.width, // 오른쪽
      buttonPosition.dy + buttonSize.height + 200, // 아래쪽 (충분한 공간)
    );

    // 업데이트된 필터 옵션
    final List<String> gradeOptions = ['초등학교', '중학교', '고등학교', '전체'];

    showMenu<int>(
      context: context,
      position: position,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      items: [
        // 초등학교
        PopupMenuItem<int>(
          value: 0,
          child: Text(
            gradeOptions[0],
            style: TextStyle(
              fontWeight:
                  widget.feedData.selectedGradeFilter == 'ELEMENTARY' &&
                          widget.feedData.isGradeFilterExpanded
                      ? FontWeight.bold
                      : FontWeight.normal,
            ),
          ),
        ),
        // 중학교
        PopupMenuItem<int>(
          value: 1,
          child: Text(
            gradeOptions[1],
            style: TextStyle(
              fontWeight:
                  widget.feedData.selectedGradeFilter == 'MIDDLE' &&
                          widget.feedData.isGradeFilterExpanded
                      ? FontWeight.bold
                      : FontWeight.normal,
            ),
          ),
        ),
        // 고등학교
        PopupMenuItem<int>(
          value: 2,
          child: Text(
            gradeOptions[2],
            style: TextStyle(
              fontWeight:
                  widget.feedData.selectedGradeFilter == 'HIGH' &&
                          widget.feedData.isGradeFilterExpanded
                      ? FontWeight.bold
                      : FontWeight.normal,
            ),
          ),
        ),
        // 전체
        PopupMenuItem<int>(
          value: 3,
          child: Text(
            gradeOptions[3],
            style: TextStyle(
              fontWeight:
                  widget.feedData.selectedGradeFilter == 'ALL' &&
                          widget.feedData.isGradeFilterExpanded
                      ? FontWeight.bold
                      : FontWeight.normal,
            ),
          ),
        ),
      ],
    ).then((value) {
      if (value != null) {
        widget.onGradeFilterChange(value);
      }
    });
  }

  // 과목별 필터 팝업
  void _showSubjectFilterPopup(GlobalKey buttonKey) {
    // 버튼 정보 가져오기
    final RenderBox? button =
        buttonKey.currentContext?.findRenderObject() as RenderBox?;
    if (button == null) return;

    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;

    // 버튼의 위치와 크기 정보
    final buttonPosition = button.localToGlobal(Offset.zero, ancestor: overlay);
    final buttonSize = button.size;

    // 팝업 메뉴 위치 설정 - 버튼 바로 아래에 나타나도록
    final RelativeRect position = RelativeRect.fromLTRB(
      buttonPosition.dx, // 왼쪽
      buttonPosition.dy + buttonSize.height, // 위쪽 (버튼 아래)
      buttonPosition.dx + buttonSize.width, // 오른쪽
      buttonPosition.dy + buttonSize.height + 200, // 아래쪽 (충분한 공간)
    );

    // 업데이트된 필터 옵션
    final List<String> subjectOptions = ['국어', '수학', '영어', '사회', '과학', '전체'];

    // 팝업 메뉴 아이템 생성
    List<PopupMenuItem<int>> items = [];

    for (int i = 0; i < subjectOptions.length; i++) {
      items.add(
        PopupMenuItem<int>(
          value: i,
          child: Text(
            subjectOptions[i],
            style: TextStyle(
              fontWeight:
                  widget.feedData.selectedOptionIndex[1] == i &&
                          widget.feedData.isFilterExpanded[1]
                      ? FontWeight.bold
                      : FontWeight.normal,
            ),
          ),
        ),
      );
    }

    showMenu<int>(
      context: context,
      position: position,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      items: items,
    ).then((value) {
      if (value != null) {
        widget.onFilterChange(1, value);
      }
    });
  }

  // 미션 종류 필터 팝업
  void _showMissionTypeFilterPopup(GlobalKey buttonKey) {
    // 버튼 정보 가져오기
    final RenderBox? button =
        buttonKey.currentContext?.findRenderObject() as RenderBox?;
    if (button == null) return;

    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;

    // 버튼의 위치와 크기 정보
    final buttonPosition = button.localToGlobal(Offset.zero, ancestor: overlay);
    final buttonSize = button.size;

    // 팝업 메뉴 위치 설정 - 버튼 바로 아래에 나타나도록
    final RelativeRect position = RelativeRect.fromLTRB(
      buttonPosition.dx, // 왼쪽
      buttonPosition.dy + buttonSize.height, // 위쪽 (버튼 아래)
      buttonPosition.dx + buttonSize.width, // 오른쪽
      buttonPosition.dy + buttonSize.height + 200, // 아래쪽 (충분한 공간)
    );

    // 업데이트된 필터 옵션
    final List<String> typeOptions = ['학습인증', '습관형성', '전체'];

    // 팝업 메뉴 아이템 생성
    List<PopupMenuItem<int>> items = [];

    for (int i = 0; i < typeOptions.length; i++) {
      items.add(
        PopupMenuItem<int>(
          value: i,
          child: Text(
            typeOptions[i],
            style: TextStyle(
              fontWeight:
                  widget.feedData.selectedOptionIndex[2] == i &&
                          widget.feedData.isFilterExpanded[2]
                      ? FontWeight.bold
                      : FontWeight.normal,
            ),
          ),
        ),
      );
    }

    showMenu<int>(
      context: context,
      position: position,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      items: items,
    ).then((value) {
      if (value != null) {
        widget.onFilterChange(2, value);
      }
    });
  }

  // 버튼 라벨 텍스트 가져오기
  String _getButtonLabel(String defaultLabel, bool isSelected) {
    if (defaultLabel == '학년군' && isSelected) {
      // 학년군 선택 라벨
      final List<String> gradeOptions = ['초등학교', '중학교', '고등학교', '전체'];

      // String 타입인 selectedGradeFilter에서 int 인덱스로 변환
      int? index = gradeMapping[widget.feedData.selectedGradeFilter];
      if (index != null && index >= 0 && index < gradeOptions.length) {
        return gradeOptions[index];
      }
      return defaultLabel;
    } else if (defaultLabel == '과목별' && isSelected) {
      // 과목별 선택 라벨
      final List<String> subjectOptions = ['국어', '수학', '영어', '사회', '과학', '전체'];
      int index = widget.feedData.selectedOptionIndex[1];
      if (index >= 0 && index < subjectOptions.length) {
        return subjectOptions[index];
      }
      return defaultLabel;
    } else if (defaultLabel == '유형별' && isSelected) {
      // 유형별 선택 라벨
      final List<String> typeOptions = ['학습인증', '습관형성', '전체'];
      int index = widget.feedData.selectedOptionIndex[2];
      if (index >= 0 && index < typeOptions.length) {
        return typeOptions[index];
      }
      return defaultLabel;
    }
    return defaultLabel;
  }
}
