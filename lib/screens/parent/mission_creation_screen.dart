import 'package:flutter/material.dart';

// 미션 작성 화면 (별도의 라우트)
class MissionCreationScreen extends StatefulWidget {
  final List<String> selectedChildren;
  final String missionType;

  const MissionCreationScreen({
    super.key,
    required this.selectedChildren,
    required this.missionType,
  });

  @override
  State<MissionCreationScreen> createState() => _MissionCreationScreenState();
}

class _MissionCreationScreenState extends State<MissionCreationScreen> {
  // 선택된 미션 유형 (영어, 영어 단어, 영어 리스닝 등)
  final TextEditingController _missionController = TextEditingController();
  // 용돈 금액 컨트롤러
  final TextEditingController _allowanceController = TextEditingController();
  // 선택된 날짜 범위
  String _selectedDateRange = '2025년 4월 14일 (월) ~ 2025년 4월 21일 (월)';
  // 미션 설명
  String _missionDescription = '';

  // 현재 표시 중인 년월
  DateTime _currentMonth = DateTime(2025, 4);
  // 선택된 시작일
  DateTime _startDate = DateTime(2025, 4, 14);
  // 선택된 종료일
  DateTime _endDate = DateTime(2025, 4, 21);

  // 검색어
  String _searchText = '';
  // 드롭다운 표시 여부
  bool _showDropdown = false;
  // 직접 작성 모드
  final bool _isCustomMode = false;

  // 미션 유형 목록 - 자동 완성용 추천 목록
  final List<String> _missionSuggestions = [
    // 국어 관련 미션
    '국어 독서하기',
    '국어 일기 쓰기',
    '국어 한자 외우기',
    '국어 문장 요약하기',
    '국어 글짓기',
    // 영어 관련 미션
    '영어 단어 외우기',
    '영어 문장 읽기',
    '영어 듣기 연습하기',
    '영어 대화 연습하기',
    '영어 문법 공부하기',
    // 수학 관련 미션
    '수학 연산 문제 풀기',
    '수학 도형 공부하기',
    '수학 문제집 풀기',
    '수학 구구단 외우기',
    '수학 응용문제 풀기',
    // 기타 미션
    '방 청소하기',
    '설거지 하기',
    '식물 물주기',
    '운동하기',
    '악기 연습하기',
    '그림 그리기',
  ];

  // 필터링된 추천 목록
  List<String> get _filteredSuggestions {
    if (_searchText.isEmpty) {
      return [];
    }
    return _missionSuggestions
        .where(
          (suggestion) =>
              suggestion.toLowerCase().contains(_searchText.toLowerCase()),
        )
        .toList();
  }

  @override
  void initState() {
    super.initState();
    // 용돈 초기값 설정
    _allowanceController.text = '10,000원';

    // 필드 변경 감지를 위한 리스너
    _missionController.addListener(() {
      setState(() {
        _searchText = _missionController.text;
        // 사용자가 입력한 검색어에 따라 관련 버튼 표시
        _showDropdown = _searchText.isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    _missionController.dispose();
    _allowanceController.dispose();
    super.dispose();
  }

  // 날짜 범위 문자열 업데이트
  void _updateDateRangeText() {
    final startWeekday = _getWeekdayString(_startDate.weekday);
    final endWeekday = _getWeekdayString(_endDate.weekday);

    setState(() {
      _selectedDateRange =
          '${_startDate.month}월 ${_startDate.day}일 ($startWeekday) ~ '
          '${_endDate.month}월 ${_endDate.day}일 ($endWeekday)';
    });
  }

  // 요일 문자열 반환
  String _getWeekdayString(int weekday) {
    switch (weekday) {
      case 1:
        return '월';
      case 2:
        return '화';
      case 3:
        return '수';
      case 4:
        return '목';
      case 5:
        return '금';
      case 6:
        return '토';
      case 7:
        return '일';
      default:
        return '';
    }
  }

  // 날짜 선택 처리
  void _selectDate(DateTime date) {
    setState(() {
      // 시작일이 선택되지 않았거나, 이미 시작일과 종료일이 같은 경우
      if (_isSameDay(_startDate, _endDate)) {
        // 시작일보다 이전 날짜 선택한 경우
        if (date.isBefore(_startDate)) {
          _startDate = date;
        }
        // 시작일보다 이후 날짜 선택한 경우
        else if (date.isAfter(_startDate)) {
          _endDate = date;
        }
        // 이미 선택된 날짜를 다시 선택한 경우 - 선택 취소
        else if (_isSameDay(date, _startDate)) {
          // 이전 상태 유지
        }
      }
      // 이미 범위가 선택된 경우 - 새로운 범위 시작
      else {
        _startDate = date;
        _endDate = date;
      }

      _updateDateRangeText();
    });
  }

  // 이전 달로 이동
  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    });
  }

  // 다음 달로 이동
  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '미션 작성',
          style: TextStyle(
            color: const Color(0xFF202020),
            fontSize: 18,
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: SizedBox(
          width: double.infinity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 섹션 1: 미션 내용
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 숫자 원형 배지
                    Container(
                      width: 28,
                      height: 28,
                      decoration: ShapeDecoration(
                        color: const Color(0xFFFFA63D),
                        shape: OvalBorder(),
                      ),
                      child: Center(
                        child: Text(
                          '1',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontFamily: 'Pretendard',
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.32,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 12),
                    // 타이틀
                    Text(
                      '${widget.selectedChildren.isNotEmpty ? widget.selectedChildren.first : "리뱅"}님에게 전송하고 싶은 미션을 알려주세요!',
                      style: TextStyle(
                        color: const Color(0xFF202020),
                        fontSize: 18,
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.72,
                      ),
                    ),
                    SizedBox(height: 16),
                    // 미션 입력 필드
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: ShapeDecoration(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          side: BorderSide(
                            width: 1.40,
                            color:
                                _missionController.text.isNotEmpty
                                    ? const Color(0xFF3A88F4) // 입력 있으면 파란색
                                    : const Color(0xFFDADADA), // 입력 없으면 회색
                          ),
                          borderRadius: BorderRadius.circular(32),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _missionController,
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: '미션 내용을 자유롭게 입력하세요',
                                hintStyle: TextStyle(
                                  color: const Color(0xFFAAAAAA),
                                  fontSize: 14,
                                  fontFamily: 'Pretendard',
                                  fontWeight: FontWeight.w300,
                                ),
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                                disabledBorder: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                errorBorder: InputBorder.none,
                                focusedErrorBorder: InputBorder.none,
                              ),
                              style: TextStyle(
                                color: const Color(0xFF4A4A4A),
                                fontSize: 14,
                                fontFamily: 'Pretendard',
                                fontWeight: FontWeight.w300,
                              ),
                              textInputAction: TextInputAction.done,
                              onEditingComplete: () {
                                FocusScope.of(context).unfocus();
                              },
                            ),
                          ),
                          if (_missionController.text.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _missionController.clear();
                                  _searchText = '';
                                });
                              },
                              child: Icon(
                                Icons.close,
                                color: Colors.grey,
                                size: 20,
                              ),
                            ),
                        ],
                      ),
                    ),

                    // 입력한 검색어에 따른 추천 미션 버튼들
                    if (_searchText.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 12.0),
                        child: Wrap(
                          spacing: 8.0,
                          runSpacing: 8.0,
                          children: _getFilteredMissionButtons(),
                        ),
                      ),

                    SizedBox(height: 16),
                  ],
                ),
              ),

              // 섹션 2: 메시지 작성
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 숫자 원형 배지
                    Container(
                      width: 28,
                      height: 28,
                      decoration: ShapeDecoration(
                        color: const Color(0xFFFFA63D),
                        shape: OvalBorder(),
                      ),
                      child: Center(
                        child: Text(
                          '2',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontFamily: 'Pretendard',
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.32,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 12),
                    // 타이틀
                    Text(
                      '남기고 싶은 메시지를 작성해 주세요.',
                      style: TextStyle(
                        color: const Color(0xFF202020),
                        fontSize: 18,
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.72,
                      ),
                    ),
                    SizedBox(height: 16),
                    // 메시지 입력 영역 - 자연스럽게 개선
                    Container(
                      width: double.infinity,
                      height: 80,
                      padding: const EdgeInsets.all(12),
                      decoration: ShapeDecoration(
                        color: const Color(0xFFF7F7F7),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              _missionDescription.isEmpty
                                  ? '(선택) 미션과 관련된 상세한 설명을 해주세요'
                                  : _missionDescription,
                              style: TextStyle(
                                color:
                                    _missionDescription.isEmpty
                                        ? const Color(0xFFAAAAAA)
                                        : const Color(0xFF4A4A4A),
                                fontSize: 14,
                                fontFamily: 'Pretendard',
                                fontWeight: FontWeight.w300,
                                letterSpacing: -0.28,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // 설명 입력용 실제 입력필드 (숨겨진 상태)
                    GestureDetector(
                      onTap: () {
                        _showDescriptionInputDialog(context);
                      },
                      child: Container(
                        margin: EdgeInsets.only(top: 8),
                        padding: EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: const Color(0xFFDADADA),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '설명 입력하기',
                              style: TextStyle(
                                color: const Color(0xFF3A88F4),
                                fontSize: 12,
                                fontFamily: 'Pretendard',
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(
                              Icons.edit,
                              size: 12,
                              color: const Color(0xFF3A88F4),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 섹션 3: 기간 선택
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 숫자 원형 배지
                    Container(
                      width: 28,
                      height: 28,
                      decoration: ShapeDecoration(
                        color: const Color(0xFFFFA63D),
                        shape: OvalBorder(),
                      ),
                      child: Center(
                        child: Text(
                          '3',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontFamily: 'Pretendard',
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.32,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 12),
                    // 타이틀
                    Text(
                      '원하는 기간을 선택해 주세요!',
                      style: TextStyle(
                        color: const Color(0xFF202020),
                        fontSize: 18,
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.72,
                      ),
                    ),
                    SizedBox(height: 16),
                    // 날짜 선택 표시
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Text(
                              "날짜 선택 : ",
                              style: TextStyle(
                                color: const Color(0xFF4A4A4A),
                                fontSize: 12,
                                fontFamily: 'Pretendard',
                                fontWeight: FontWeight.w500,
                                letterSpacing: -0.24,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                _selectedDateRange,
                                style: TextStyle(
                                  color: const Color(0xFF999999),
                                  fontSize: 12,
                                  fontFamily: 'Pretendard',
                                  fontWeight: FontWeight.w300,
                                  letterSpacing: -0.24,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(
                              Icons.keyboard_arrow_down,
                              color: const Color(0xFF999999),
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 8),
                    // 날짜 선택 헤더
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: Icon(Icons.chevron_left, color: Colors.grey),
                          onPressed: _previousMonth,
                          iconSize: 20,
                          padding: EdgeInsets.zero,
                          constraints: BoxConstraints(),
                        ),
                        SizedBox(width: 16),
                        Text(
                          '${_currentMonth.year}. ${_currentMonth.month.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            color: const Color(0xFF353535),
                            fontSize: 16,
                            fontFamily: 'Pretendard',
                            fontWeight: FontWeight.w500,
                            letterSpacing: -0.32,
                          ),
                        ),
                        SizedBox(width: 16),
                        IconButton(
                          icon: Icon(Icons.chevron_right, color: Colors.grey),
                          onPressed: _nextMonth,
                          iconSize: 20,
                          padding: EdgeInsets.zero,
                          constraints: BoxConstraints(),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    // 요일 표시
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children:
                          ['일', '월', '화', '수', '목', '금', '토']
                              .map(
                                (day) => Text(
                                  day,
                                  style: TextStyle(
                                    color: const Color(0xFF999999),
                                    fontSize: 12,
                                    fontFamily: 'Pretendard',
                                    fontWeight: FontWeight.w300,
                                    letterSpacing: -0.24,
                                  ),
                                ),
                              )
                              .toList(),
                    ),
                    SizedBox(height: 12),
                    // 달력 위젯
                    _buildCalendar(),
                  ],
                ),
              ),

              // 섹션 4: 용돈 설정
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 숫자 원형 배지
                    Container(
                      width: 28,
                      height: 28,
                      decoration: ShapeDecoration(
                        color: const Color(0xFFFFA63D),
                        shape: OvalBorder(),
                      ),
                      child: Center(
                        child: Text(
                          '4',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontFamily: 'Pretendard',
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.32,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 12),
                    // 타이틀
                    Text(
                      '${widget.selectedChildren.isNotEmpty ? widget.selectedChildren.first : "리뱅"}님에게 지급할 용돈을 알려주세요!',
                      style: TextStyle(
                        color: const Color(0xFF202020),
                        fontSize: 18,
                        fontFamily: 'Pretendard-Bold',
                        letterSpacing: -0.72,
                      ),
                    ),
                    SizedBox(height: 16),
                    // 금액 입력 필드 - 자유롭게 입력 가능하도록 수정
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: ShapeDecoration(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          side: BorderSide(
                            width: 1.40,
                            color:
                                _allowanceController.text.isNotEmpty
                                    ? const Color(0xFF3A88F4) // 입력 있으면 파란색
                                    : const Color(0xFFDADADA), // 입력 없으면 회색
                          ),
                          borderRadius: BorderRadius.circular(32),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: TextField(
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: '금액을 자유롭게 입력하세요 (예: 15,000원)',
                                hintStyle: TextStyle(
                                  color: const Color(0xFFAAAAAA),
                                  fontSize: 14,
                                  fontFamily: 'Pretendard',
                                  fontWeight: FontWeight.w300,
                                ),
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                                disabledBorder: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                errorBorder: InputBorder.none,
                                focusedErrorBorder: InputBorder.none,
                              ),
                              style: TextStyle(
                                color: const Color(0xFF4A4A4A),
                                fontSize: 14,
                                fontFamily: 'Pretendard',
                                fontWeight: FontWeight.w300,
                                letterSpacing: -0.28,
                              ),
                              controller: _allowanceController,
                              onChanged: (value) {
                                setState(() {
                                  // 상태 업데이트를 위한 setState 호출
                                });
                              },
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          // 삭제 버튼 추가
                          _allowanceController.text.isNotEmpty
                              ? GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _allowanceController.clear();
                                  });
                                },
                                child: Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Icon(
                                      Icons.close,
                                      size: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              )
                              : Container(),
                        ],
                      ),
                    ),
                    SizedBox(height: 12),
                    // 이전 미션 금액 표시
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: ShapeDecoration(
                        color: const Color(0xFFF7F7F7),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: '저번에는 설거지 미션에 ',
                              style: TextStyle(
                                color: const Color(0xFF666666),
                                fontSize: 12,
                                fontFamily: 'Pretendard',
                                fontWeight: FontWeight.w300,
                                letterSpacing: -0.24,
                              ),
                            ),
                            TextSpan(
                              text: '15,000원',
                              style: TextStyle(
                                color: const Color(0xFF666666),
                                fontSize: 12,
                                fontFamily: 'Pretendard',
                                fontWeight: FontWeight.w500,
                                letterSpacing: -0.24,
                              ),
                            ),
                            TextSpan(
                              text: '을 지급했어요!',
                              style: TextStyle(
                                color: const Color(0xFF666666),
                                fontSize: 12,
                                fontFamily: 'Pretendard',
                                fontWeight: FontWeight.w300,
                                letterSpacing: -0.24,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    // 안내 메시지
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      decoration: ShapeDecoration(
                        color: const Color(0xFFEFF2F6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 16,
                                color: Colors.grey,
                              ),
                              SizedBox(width: 8),
                              Text(
                                '다음에도 동일한 미션을 선택 시, 자동 기입됩니다',
                                style: TextStyle(
                                  color: const Color(0xFF666666),
                                  fontSize: 12,
                                  fontFamily: 'Pretendard',
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: -0.24,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(
                            '현재 선택한 미션을 다음에도 선택 시, 기간을 제외한 모든 정보가 자동적으로 기입되어 간편하게 전송할 수 있어요!',
                            style: TextStyle(
                              color: const Color(0xFF999999),
                              fontSize: 11,
                              fontFamily: 'Pretendard',
                              fontWeight: FontWeight.w300,
                              height: 1.45,
                              letterSpacing: -0.22,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 하단 버튼
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: () {
                    // 미션 생성 완료 처리
                    Navigator.pop(context);
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('미션이 생성되었습니다')));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3A88F4),
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    '신청 완료',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 달력 위젯
  Widget _buildCalendar() {
    // 달력의 첫 번째 날 (현재 월의 1일)
    final firstDayOfMonth = DateTime(
      _currentMonth.year,
      _currentMonth.month,
      1,
    );
    // 달력의 시작 위치 (첫 번째 날의 요일에 따라 조정)
    final startingDayOffset = firstDayOfMonth.weekday % 7;
    // 현재 월의 마지막 날
    final lastDayOfMonth = DateTime(
      _currentMonth.year,
      _currentMonth.month + 1,
      0,
    );
    // 총 일수
    final daysInMonth = lastDayOfMonth.day;

    // 이전 달의 마지막 날짜
    final lastDayOfPreviousMonth =
        DateTime(_currentMonth.year, _currentMonth.month, 0).day;

    // 다음 달의 표시 일수 계산
    int nextMonthDays = 42 - (startingDayOffset + daysInMonth);
    if (nextMonthDays > 7) nextMonthDays -= 7; // 6주 이상 표시되지 않도록 조정

    List<Widget> calendarCells = [];

    // 이전 달의 날짜 추가
    for (int i = 0; i < startingDayOffset; i++) {
      final day = lastDayOfPreviousMonth - startingDayOffset + i + 1;
      calendarCells.add(
        Center(
          child: Text(
            '$day',
            style: TextStyle(
              color: const Color(0xFFCCCCCC),
              fontSize: 16,
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w300,
              letterSpacing: -0.32,
            ),
          ),
        ),
      );
    }

    // 현재 달의 날짜 추가
    for (int i = 1; i <= daysInMonth; i++) {
      final currentDate = DateTime(_currentMonth.year, _currentMonth.month, i);
      final isStartDate = _isSameDay(currentDate, _startDate);
      final isEndDate = _isSameDay(currentDate, _endDate);

      // 범위 내의 날짜 확인 (시작일과 종료일 사이)
      final isInRange =
          currentDate.isAfter(_startDate.subtract(Duration(days: 1))) &&
          currentDate.isBefore(_endDate.add(Duration(days: 1))) &&
          !isStartDate &&
          !isEndDate;

      calendarCells.add(
        GestureDetector(
          onTap: () => _selectDate(currentDate),
          child: Center(
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color:
                    isStartDate || isEndDate
                        ? const Color(0xFF89DA8D)
                        : isInRange
                        ? const Color(0xFFE0F5E1)
                        : // 범위 내 날짜는 연한 초록색
                        Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '$i',
                  style:
                      (isStartDate || isEndDate || isInRange)
                          ? TextStyle(
                            color: const Color(0xFF001F55),
                            fontSize: 16,
                            fontFamily: 'Pretendard',
                            fontWeight: FontWeight.w300,
                            letterSpacing: -0.32,
                          )
                          : TextStyle(
                            color: const Color(0xFF666666),
                            fontSize: 16,
                            fontFamily: 'Pretendard',
                            fontWeight: FontWeight.w300,
                            letterSpacing: -0.32,
                          ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    // 다음 달의 날짜 추가
    for (int i = 1; i <= nextMonthDays; i++) {
      calendarCells.add(
        Center(
          child: Text(
            '$i',
            style: TextStyle(
              color: const Color(0xFFCCCCCC),
              fontSize: 16,
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w300,
              letterSpacing: -0.32,
            ),
          ),
        ),
      );
    }

    // 달력 그리드 생성
    return Container(
      padding: EdgeInsets.all(8),
      child: GridView.count(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        crossAxisCount: 7,
        mainAxisSpacing: 16,
        crossAxisSpacing: 8,
        children: calendarCells,
      ),
    );
  }

  // 같은 날짜인지 확인
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  // 검색어에 따른 미션 버튼 목록 생성
  List<Widget> _getFilteredMissionButtons() {
    // 검색어가 없으면 빈 리스트 반환
    if (_searchText.isEmpty) return [];

    // 검색어와 관련된 미션 찾기
    String searchLower = _searchText.toLowerCase();

    // 과목별 미션 리스트
    Map<String, List<String>> missionsByCategory = {
      '국어': ['국어 독서', '국어 일기', '국어 한자', '국어 문법'],
      '영어': ['영어 단어', '영어 리스닝', '영어 회화', '영어 문법'],
      '수학': ['수학 연산', '수학 도형', '수학 문제집', '수학 특강'],
      '과학': ['과학 실험', '화학', '물리', '생물'],
      '기타': ['방 청소', '설거지', '운동', '식물 물주기'],
    };

    List<Widget> buttons = [];

    // 첫 번째 버튼은 검색어 자체로 하늘색 배경 적용
    buttons.add(_buildMissionButton(_searchText, isHighlighted: true));

    // 검색어와 관련된 미션 버튼 추가
    String categoryKey = '';

    // 검색어와 일치하는 카테고리 찾기
    for (var key in missionsByCategory.keys) {
      if (key.toLowerCase().contains(searchLower)) {
        categoryKey = key;
      }
    }

    if (categoryKey.isNotEmpty) {
      // 카테고리와 일치하면 해당 카테고리의 미션 추가
      for (var mission in missionsByCategory[categoryKey]!) {
        if (mission.toLowerCase() != searchLower) {
          buttons.add(_buildMissionButton(mission));
        }
      }
    } else {
      // 카테고리와 일치하지 않으면 검색어를 포함하는 모든 미션 추가
      missionsByCategory.forEach((category, missions) {
        for (var mission in missions) {
          if (mission.toLowerCase().contains(searchLower) &&
              mission.toLowerCase() != searchLower) {
            buttons.add(_buildMissionButton(mission));
          }
        }
      });
    }

    // 최대 3개만 표시
    if (buttons.length > 3) {
      return buttons.sublist(0, 3);
    }

    return buttons;
  }

  // 미션 버튼 위젯
  Widget _buildMissionButton(String mission, {bool isHighlighted = false}) {
    return GestureDetector(
      onTap: () {
        setState(() {
          // 버튼 클릭 시 텍스트 필드에 자동 입력
          _missionController.text = mission;
          FocusScope.of(context).unfocus();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isHighlighted ? const Color(0xFF3A88F4) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            width: 1,
            color:
                isHighlighted
                    ? const Color(0xFF3A88F4)
                    : const Color(0xFFDADADA),
          ),
        ),
        child: Text(
          mission,
          style: TextStyle(
            color: isHighlighted ? Colors.white : const Color(0xFF3A88F4),
            fontSize: 14,
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }

  // 설명 입력 다이얼로그 표시
  void _showDescriptionInputDialog(BuildContext context) {
    final TextEditingController controller = TextEditingController(
      text: _missionDescription,
    );

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              '미션 설명 입력',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                fontFamily: 'Pretendard',
              ),
            ),
            content: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: '미션과 관련된 상세한 설명을 입력하세요',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
              minLines: 3,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('취소'),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _missionDescription = controller.text;
                  });
                  Navigator.pop(context);
                },
                child: Text('확인'),
              ),
            ],
          ),
    );
  }
}
