import 'package:flutter/material.dart';

class ChallengeDetailScreen extends StatefulWidget {
  final String type;
  final String title;
  final String participants;
  final String period;
  final String time;

  const ChallengeDetailScreen({
    super.key,
    required this.type,
    required this.title,
    required this.participants,
    required this.period,
    required this.time,
  });

  @override
  State<ChallengeDetailScreen> createState() => _ChallengeDetailScreenState();
}

class _ChallengeDetailScreenState extends State<ChallengeDetailScreen> {
  DateTime _selectedDate = DateTime(2025, 3, 15); // 기본값 설정
  DateTime _endDate = DateTime(2025, 3, 15); // 종료 날짜 추가
  String _selectedDay = '토';
  String _endDay = '토'; // 종료 요일 추가
  int _selectedHour = 6;
  int _selectedMinute = 28;
  String _selectedDuration = "1h";
  final TextEditingController _totalTimeController = TextEditingController();
  bool _meridiem = true; // true = PM, false = AM
  bool _isSelectingEndDate = false; // 달력에서 종료일 선택 모드
  bool _showRewardWarning = false; // 포인트 경고 표시 여부

  @override
  void initState() {
    super.initState();
    // 포인트 입력 변경 리스너 추가
    _totalTimeController.addListener(_checkRewardInput);
  }

  @override
  void dispose() {
    _totalTimeController.removeListener(_checkRewardInput);
    _totalTimeController.dispose();
    super.dispose();
  }

  // 포인트 입력 확인
  void _checkRewardInput() {
    setState(() {
      _showRewardWarning = _totalTimeController.text.trim().isEmpty;
    });
  }

  // 날짜 선택 핸들러
  void _onDateSelected(DateTime date) {
    setState(() {
      if (_isSelectingEndDate) {
        // 종료일 선택 모드인 경우
        if (date.isBefore(_selectedDate)) {
          // 종료일이 시작일보다 이전이면 시작일=종료일로 설정
          _endDate = _selectedDate;
          _isSelectingEndDate = false;
        } else {
          _endDate = date;

          // 요일 계산
          final List<String> weekdays = ['일', '월', '화', '수', '목', '금', '토'];
          _endDay = weekdays[date.weekday % 7];

          _isSelectingEndDate = false; // 종료일 선택 완료
        }
      } else {
        // 시작일 선택 모드인 경우
        _selectedDate = date;
        _endDate = date; // 기본적으로 종료일도 같은 날짜로 설정

        // 요일 계산
        final List<String> weekdays = ['일', '월', '화', '수', '목', '금', '토'];
        _selectedDay = weekdays[date.weekday % 7];
        _endDay = _selectedDay;

        _isSelectingEndDate = true; // 다음 선택은 종료일
      }
    });
  }

  // 시간 선택 핸들러
  void _onTimeSelected(int hour, int minute) {
    setState(() {
      _selectedHour = hour;
      _selectedMinute = minute;
    });
  }

  // AM/PM 토글 핸들러
  void _toggleMeridiem() {
    setState(() {
      _meridiem = !_meridiem;
    });
  }

  // 공부 시간 선택 핸들러
  void _onDurationSelected(String duration) {
    setState(() {
      _selectedDuration = duration;
    });
  }

  // 신청하기 버튼 클릭 핸들러
  void _handleSubmit() {
    // 포인트 입력 확인
    if (_totalTimeController.text.trim().isEmpty) {
      setState(() {
        _showRewardWarning = true;
      });
    } else {
      // 경고 없을 경우 모달 표시
      _showConfirmationModal(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 반응형 크기 계산
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // 패딩, 폰트 크기 등을 화면 크기에 비례하여 계산
    final horizontalPadding = screenWidth * 0.04;
    final verticalPadding = screenHeight * 0.015;

    return Scaffold(
      backgroundColor: const Color(0xFFEFF2F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFEFF2F6),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // 뒤로가기 버튼
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 24,
                height: 24,
                alignment: Alignment.centerLeft,
                child: const Icon(Icons.arrow_back_ios, size: 20),
              ),
            ),
            // 타이틀
            const Text(
              '챌린지 참여하기',
              style: TextStyle(
                color: Color(0xFF202020),
                fontSize: 16,
                fontFamily: 'Pretendard-Bold',
              ),
            ),
            // 우측 공간 확보용 투명 위젯
            const SizedBox(width: 24),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(top: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1단계: 요일 선택
              _buildSection(
                number: "1",
                title: "원하는 요일을 선택해 주세요",
                subtitle: "요일별 챌린지 선택 시, 자동으로 날짜가 선택돼요",
                content: _buildDateSelector(screenWidth),
              ),

              const SizedBox(height: 32),

              // 2단계: 시작 시간 선택
              _buildSection(
                number: "2",
                title: "원하는 시작 시간을 선택해 주세요",
                subtitle: "설정된 시간부터 챌린지가 시작돼요!",
                content: _buildTimeSelector(screenWidth),
              ),

              const SizedBox(height: 32),

              // 3단계: 공부 시간 선택
              _buildSection(
                number: "3",
                title: "원하는 하루 공부 시간을 선택해 주세요",
                subtitle: "수행한 총 공부 시간을 확인할 수 있어요!",
                content: _buildDurationSelector(screenWidth),
              ),

              const SizedBox(height: 32),

              // 4단계: 포인트 입력
              _buildSection(
                number: "4",
                title: "원하는 포인트을 입력해 주세요",
                subtitle: "부모님에게 원하는 포인트을 대신 전해드릴게요!",
                content: _buildRewardInput(screenWidth),
              ),

              const SizedBox(height: 40),

              // 신청하기 버튼
              Container(
                width: screenWidth - 32,
                height: 50, // 높이 증가
                margin: const EdgeInsets.only(bottom: 30),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF146AFF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 10, // 패딩 감소
                    ),
                  ),
                  onPressed: _handleSubmit,
                  child: const Text(
                    '이대로 신청하기',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14, // 폰트 크기 약간 증가
                      fontFamily: 'Pretendard-Medium',
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

  // 각 섹션을 구성하는 위젯
  Widget _buildSection({
    required String number,
    required String title,
    required String subtitle,
    required Widget content,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 섹션 헤더
          Container(
            width: double.infinity,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 숫자 원형 표시
                Container(
                  width: 28,
                  height: 28,
                  decoration: const ShapeDecoration(
                    color: Color(0xFFFFD27F),
                    shape: OvalBorder(),
                  ),
                  child: Center(
                    child: Text(
                      number,
                      style: const TextStyle(
                        color: Color(0xFF001F55),
                        fontSize: 14,
                        fontFamily: 'Pretendard-Bold',
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // 타이틀과 서브타이틀
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFF202020),
                        fontSize: 16,
                        fontFamily: 'Pretendard-Bold',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF999999),
                        fontSize: 12,
                        fontFamily: 'Pretendard-Light',
                        letterSpacing: -0.28,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 섹션 콘텐츠
          content,
        ],
      ),
    );
  }

  // 날짜 선택 위젯
  Widget _buildDateSelector(double screenWidth) {
    // 날짜 범위 문자열 생성
    String dateRangeText = '';
    if (_selectedDate == _endDate) {
      dateRangeText =
          '${_selectedDate.year}년 ${_selectedDate.month}월 ${_selectedDate.day}일(${_selectedDay})';
    } else {
      dateRangeText =
          '${_selectedDate.month}월 ${_selectedDate.day}일(${_selectedDay}) ~ ${_endDate.month}월 ${_endDate.day}일(${_endDay})';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 선택된 날짜 표시
        Row(
          children: [
            const Text(
              '날짜 선택',
              style: TextStyle(
                color: Color(0xFF202020),
                fontSize: 16,
                fontFamily: 'Pretendard-Bold',
                letterSpacing: -0.32,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                dateRangeText,
                style: const TextStyle(
                  color: Color(0xFF5D9EFF),
                  fontSize: 14,
                  fontFamily: 'Pretendard-Regular',
                  height: 1.93,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),

        const SizedBox(height: 4),

        // 날짜 선택 모드 표시
        Text(
          _isSelectingEndDate
              ? '종료일을 선택해주세요'
              : _selectedDate == _endDate
              ? '날짜를 선택하면 기간을 설정할 수 있어요'
              : '선택된 기간: ${_endDate.difference(_selectedDate).inDays + 1}일',
          style: TextStyle(
            color: _isSelectingEndDate ? Colors.red : Color(0xFF999999),
            fontSize: 12,
            fontFamily: 'Pretendard-Light',
          ),
        ),

        const SizedBox(height: 20),

        // 달력 위젯 (배경 없음)
        Column(
          children: [
            // 요일 헤더 (가로선 추가)
            Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(width: 0.5, color: Color(0xFFDDDDDD)),
                  bottom: BorderSide(width: 0.5, color: Color(0xFFDDDDDD)),
                ),
              ),
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _dayLabel('일', isRed: true),
                  _dayLabel('월'),
                  _dayLabel('화'),
                  _dayLabel('수'),
                  _dayLabel('목'),
                  _dayLabel('금'),
                  _dayLabel('토'),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // 달력 그리드 - 범위 선택 가능하도록 업데이트
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1.0,
                mainAxisSpacing: 8,
                crossAxisSpacing: 0,
              ),
              itemCount: 35, // 5주 표시
              itemBuilder: (context, index) {
                final int firstDayOffset =
                    3; // 이번 달의 첫 날이 시작되는 인덱스 (0: 일요일, 6: 토요일)
                final int lastDay = 31; // 이번 달의 마지막 날짜

                // 날짜 계산
                int dayNumber;
                bool isCurrentMonth = true;

                if (index < firstDayOffset) {
                  // 이전 달의 날짜들
                  dayNumber = 31 - (firstDayOffset - index - 1);
                  isCurrentMonth = false;
                } else if (index >= firstDayOffset + lastDay) {
                  // 다음 달의 날짜들
                  dayNumber = index - (firstDayOffset + lastDay) + 1;
                  isCurrentMonth = false;
                } else {
                  // 현재 달의 날짜들
                  dayNumber = index - firstDayOffset + 1;
                }

                // 현재 날짜의 요일
                final int weekday = index % 7;
                final bool isSunday = (weekday == 0);

                // 현재 날짜 생성
                final currentDate = DateTime(2025, 3, dayNumber);

                // 날짜가 선택 범위 내에 있는지 확인
                final bool isStartDate =
                    isCurrentMonth &&
                    dayNumber == _selectedDate.day &&
                    _selectedDate.month == 3 &&
                    _selectedDate.year == 2025;

                final bool isEndDate =
                    isCurrentMonth &&
                    dayNumber == _endDate.day &&
                    _endDate.month == 3 &&
                    _endDate.year == 2025;

                final bool isInRange =
                    isCurrentMonth &&
                    !isStartDate &&
                    !isEndDate &&
                    currentDate.isAfter(_selectedDate) &&
                    currentDate.isBefore(_endDate);

                // 날짜 버튼 생성
                return GestureDetector(
                  onTap:
                      isCurrentMonth
                          ? () {
                            // 현재 달에 속한 날짜만 선택 가능
                            _onDateSelected(DateTime(2025, 3, dayNumber));
                          }
                          : null,
                  child: Container(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // 선택된 날짜는 파란색 원으로 표시 (시작일, 종료일, 중간 날짜 모두)
                        if (isStartDate || isEndDate || isInRange)
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: Color(0xFF146AFF),
                              shape: BoxShape.circle,
                            ),
                          ),

                        // 날짜 텍스트
                        Text(
                          dayNumber.toString(),
                          style: TextStyle(
                            color:
                                (isStartDate || isEndDate || isInRange)
                                    ? Colors.white
                                    : isSunday
                                    ? Color(0xFFFF6062)
                                    : isCurrentMonth
                                    ? Color(0xFF5C6B7F)
                                    : Color(0xFFCCCCCC),
                            fontSize: 12,
                            fontFamily:
                                (isStartDate || isEndDate || isInRange)
                                    ? 'Pretendard-SemiBold'
                                    : 'Pretendard-Regular',
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  // 요일 레이블 위젯
  Widget _dayLabel(String day, {bool isRed = false}) {
    return SizedBox(
      width: 30,
      child: Text(
        day,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: isRed ? const Color(0xFFFF6062) : const Color(0xFF5C6B7F),
          fontSize: 12,
          fontFamily: 'Pretendard-Regular',
        ),
      ),
    );
  }

  // 시간 선택 위젯
  Widget _buildTimeSelector(double screenWidth) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          width: screenWidth - 80, // 너비 줄임
          height: 260, // 높이 더 증가
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
          decoration: ShapeDecoration(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            shadows: [
              BoxShadow(
                color: Color(0x4C5D9EFF),
                blurRadius: 12,
                offset: Offset(3, 4),
                spreadRadius: 0,
              ),
              BoxShadow(
                color: Color(0x4C5D9EFF),
                blurRadius: 12,
                offset: Offset(-3, 0),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 가로선 - 선택된 영역에 하나로 이어진 선
              Positioned(
                top: (260 - 20 * 2) / 2 - 29, // 컨테이너 중앙에서 위로 이동
                left: 0,
                right: 0,
                child: Container(
                  height: 58, // 선택 영역 높이
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        width: 0.8,
                        color: const Color(0xFF8590A3),
                      ),
                      bottom: BorderSide(
                        width: 0.8,
                        color: const Color(0xFF8590A3),
                      ),
                    ),
                  ),
                ),
              ),

              // 시간 선택 영역
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 시간 휠 (1-12)
                  Expanded(
                    flex: 3,
                    child: ListWheelScrollView(
                      itemExtent: 58, // 항목 높이 더 증가
                      diameterRatio: 1.8,
                      squeeze: 0.9,
                      physics: FixedExtentScrollPhysics(),
                      onSelectedItemChanged: (index) {
                        _onTimeSelected(index + 1, _selectedMinute);
                      },
                      controller: FixedExtentScrollController(
                        initialItem: _selectedHour - 1,
                      ),
                      children: List.generate(12, (index) {
                        final hour = index + 1;
                        return Center(
                          child: Text(
                            hour.toString().padLeft(2, '0'),
                            style: TextStyle(
                              color:
                                  hour == _selectedHour
                                      ? const Color(0xFF5D9EFF)
                                      : const Color(0xFF999999),
                              fontSize: hour == _selectedHour ? 24 : 20,
                              fontFamily:
                                  hour == _selectedHour
                                      ? 'Pretendard-Bold'
                                      : 'Pretendard-Light',
                            ),
                          ),
                        );
                      }),
                    ),
                  ),

                  // 콜론 (:)
                  Container(
                    width: 20,
                    alignment: Alignment.center,
                    child: Text(
                      ':',
                      style: TextStyle(
                        color: const Color(0xFF5D9EFF),
                        fontSize: 24,
                        fontFamily: 'Pretendard-Bold',
                      ),
                    ),
                  ),

                  // 분 휠 (00-59)
                  Expanded(
                    flex: 3,
                    child: ListWheelScrollView(
                      itemExtent: 58, // 항목 높이 더 증가
                      diameterRatio: 1.8,
                      squeeze: 0.9,
                      physics: FixedExtentScrollPhysics(),
                      onSelectedItemChanged: (index) {
                        _onTimeSelected(_selectedHour, index);
                      },
                      controller: FixedExtentScrollController(
                        initialItem: _selectedMinute,
                      ),
                      children: List.generate(60, (index) {
                        return Center(
                          child: Text(
                            index.toString().padLeft(2, '0'),
                            style: TextStyle(
                              color:
                                  index == _selectedMinute
                                      ? const Color(0xFF5D9EFF)
                                      : const Color(0xFF999999),
                              fontSize: index == _selectedMinute ? 24 : 20,
                              fontFamily:
                                  index == _selectedMinute
                                      ? 'Pretendard-Bold'
                                      : 'Pretendard-Light',
                            ),
                          ),
                        );
                      }),
                    ),
                  ),

                  // AM/PM 휠
                  Expanded(
                    flex: 3,
                    child: ListWheelScrollView(
                      itemExtent: 58, // 항목 높이 더 증가
                      diameterRatio: 1.8,
                      squeeze: 0.9,
                      physics: FixedExtentScrollPhysics(),
                      onSelectedItemChanged: (index) {
                        setState(() {
                          _meridiem = index == 1; // 1=PM, 0=AM
                        });
                      },
                      controller: FixedExtentScrollController(
                        initialItem: _meridiem ? 1 : 0,
                      ),
                      children: [
                        Center(
                          child: Text(
                            'AM',
                            style: TextStyle(
                              color:
                                  !_meridiem
                                      ? const Color(0xFF5D9EFF)
                                      : const Color(0xFF999999),
                              fontSize: !_meridiem ? 24 : 20,
                              fontFamily:
                                  !_meridiem
                                      ? 'Pretendard-Bold'
                                      : 'Pretendard-Light',
                            ),
                          ),
                        ),
                        Center(
                          child: Text(
                            'PM',
                            style: TextStyle(
                              color:
                                  _meridiem
                                      ? const Color(0xFF5D9EFF)
                                      : const Color(0xFF999999),
                              fontSize: _meridiem ? 24 : 20,
                              fontFamily:
                                  _meridiem
                                      ? 'Pretendard-Bold'
                                      : 'Pretendard-Light',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 공부 시간 선택 위젯 (선택 가능하도록 수정)
  Widget _buildDurationSelector(double screenWidth) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildDurationButton('1h', _selectedDuration == '1h'),
            _buildDurationButton('2h', _selectedDuration == '2h'),
            _buildDurationButton('3h', _selectedDuration == '3h'),
            _buildDurationButton('4h', _selectedDuration == '4h'),
            _buildDurationButton('더 많이', _selectedDuration == '더 많이'),
          ],
        ),
      ),
    );
  }

  // 공부 시간 버튼 위젯 (선택 기능 추가)
  Widget _buildDurationButton(String text, bool isSelected) {
    return GestureDetector(
      onTap: () => _onDurationSelected(text),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF3A88F4) : Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFFB6B6B6),
            fontSize: 14,
            fontFamily: isSelected ? 'Pretendard-Medium' : 'Pretendard-Light',
            letterSpacing: -0.28,
          ),
        ),
      ),
    );
  }

  // 포인트 입력 위젯
  Widget _buildRewardInput(double screenWidth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Container(
            width: double.infinity,
            height: 49,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: ShapeDecoration(
              color: const Color(0xFFEFF2F6),
              shape: RoundedRectangleBorder(
                side: const BorderSide(width: 1.40, color: Color(0xFF5D9EFF)),
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center, // 수직 중앙 정렬
              children: [
                Expanded(
                  child: TextField(
                    controller: _totalTimeController,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      focusedErrorBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                      hintText: '원하는 포인트을 입력하세요',
                      hintStyle: TextStyle(
                        color: Color(0xFF999999),
                        fontSize: 14,
                        fontFamily: 'Pretendard-Light',
                      ),
                      fillColor: Color(0xFFEFF2F6),
                      filled: true,
                    ),
                    style: TextStyle(
                      color: Color(0xFF666666),
                      fontSize: 14,
                      fontFamily: 'Pretendard-Medium',
                      letterSpacing: -0.28,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _totalTimeController.clear(); // 입력 내용 삭제
                    });
                  },
                  child: Image.asset(
                    'assets/icons/Icon/feed/삭제_버튼형.png',
                    width: 24,
                    height: 24,
                  ),
                ),
              ],
            ),
          ),
        ),

        // 경고 메시지 - 포인트 미입력 시 표시
        if (_showRewardWarning)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: ShapeDecoration(
              color: const Color(0xFF4A4A4A),
              shape: RoundedRectangleBorder(
                side: const BorderSide(width: 0.30, color: Color(0xFF10CB86)),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  '🚨',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontFamily: 'Pretendard-Light',
                    letterSpacing: -0.24,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '입력하지 않으시면 신청하실 수 없어요!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontFamily: 'Pretendard-Light',
                    letterSpacing: -0.24,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // 확인 모달
  void _showConfirmationModal(BuildContext context) {
    // 선택한 날짜를 기간 형식으로 변환
    String periodText = '';
    if (_selectedDate == _endDate) {
      // 하루만 선택한 경우
      periodText = '${_selectedDate.month}.${_selectedDate.day}';
    } else {
      // 여러 날을 선택한 경우
      periodText =
          '${_selectedDate.month}.${_selectedDate.day} ~ ${_endDate.month}.${_endDate.day}';
    }

    // 공부 시간을 형식에 맞게 변환
    String studyTimeText = '';
    if (_selectedDuration == '1h') {
      studyTimeText = '매일 1시간씩';
    } else if (_selectedDuration == '2h') {
      studyTimeText = '매일 2시간씩';
    } else if (_selectedDuration == '3h') {
      studyTimeText = '매일 3시간씩';
    } else if (_selectedDuration == '4h') {
      studyTimeText = '매일 4시간씩';
    } else {
      studyTimeText = '매일 ${_selectedDuration}씩';
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: EdgeInsets.symmetric(horizontal: 20),
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: SingleChildScrollView(
            child: Container(
              width: MediaQuery.of(context).size.width - 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 헤더 부분
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                '신청한 챌린지 정보를 확인해 주세요!',
                                style: TextStyle(
                                  color: const Color(0xFF202020),
                                  fontSize: 16,
                                  fontFamily: 'Pretendard-Bold',
                                  letterSpacing: -0.72,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Icon(
                                Icons.close,
                                size: 20,
                                color: Color(0xFF666666),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          '부모님에게 전송하기 전 한 번 더 확인해 주세요',
                          style: TextStyle(
                            color: const Color(0xFF999999),
                            fontSize: 12,
                            fontFamily: 'Pretendard-Light',
                            letterSpacing: -0.28,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 챌린지 정보
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    color: Colors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: ShapeDecoration(
                                color: const Color(0xFF5D9EFF),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                widget.type,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontFamily: 'Pretendard-Light',
                                  letterSpacing: -0.24,
                                ),
                              ),
                            ),
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
                                periodText,
                                style: TextStyle(
                                  color: const Color(0xFF001F55),
                                  fontSize: 12,
                                  fontFamily: 'Pretendard-Light',
                                  letterSpacing: -0.24,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Text(
                          widget.title,
                          style: TextStyle(
                            color: const Color(0xFF202020),
                            fontSize: 16,
                            fontFamily: 'Pretendard-Bold',
                            letterSpacing: -0.32,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 상세 정보
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    color: Colors.white,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: ShapeDecoration(
                        color: const Color(0xFFEFF2F6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 참여 인원
                          Row(
                            children: [
                              Text(
                                '참여 인원',
                                style: TextStyle(
                                  color: const Color(0xFF666666),
                                  fontSize: 12,
                                  fontFamily: 'Pretendard-Light',
                                  letterSpacing: -0.28,
                                ),
                              ),
                              SizedBox(width: 12),
                              RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text:
                                          widget.participants.split('/')[0] +
                                          '/',
                                      style: TextStyle(
                                        color: const Color(0xFF5D9EFF),
                                        fontSize: 12,
                                        fontFamily: 'Pretendard-Medium',
                                        letterSpacing: -0.28,
                                      ),
                                    ),
                                    TextSpan(
                                      text: widget.participants.split('/')[1],
                                      style: TextStyle(
                                        color: const Color(0xFF666666),
                                        fontSize: 12,
                                        fontFamily: 'Pretendard-Light',
                                        letterSpacing: -0.28,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),

                          // 날짜
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '날짜',
                                style: TextStyle(
                                  color: const Color(0xFF666666),
                                  fontSize: 12,
                                  fontFamily: 'Pretendard-Light',
                                  letterSpacing: -0.28,
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _selectedDate == _endDate
                                      ? '${_selectedDate.year}년 ${_selectedDate.month}월 ${_selectedDate.day}일(${_selectedDay})'
                                      : '${_selectedDate.month}월 ${_selectedDate.day}일(${_selectedDay}) ~ ${_endDate.month}월 ${_endDate.day}일(${_endDay})',
                                  style: TextStyle(
                                    color: const Color(0xFF666666),
                                    fontSize: 12,
                                    fontFamily: 'Pretendard-Light',
                                    letterSpacing: -0.28,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),

                          // 공부 시간
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '공부 시간',
                                style: TextStyle(
                                  color: const Color(0xFF666666),
                                  fontSize: 12,
                                  fontFamily: 'Pretendard-Light',
                                  letterSpacing: -0.28,
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  studyTimeText,
                                  style: TextStyle(
                                    color: const Color(0xFF666666),
                                    fontSize: 12,
                                    fontFamily: 'Pretendard-Light',
                                    letterSpacing: -0.28,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),

                          // 신청한 포인트
                          Row(
                            children: [
                              Text(
                                '신청한 포인트',
                                style: TextStyle(
                                  color: const Color(0xFF666666),
                                  fontSize: 12,
                                  fontFamily: 'Pretendard-Light',
                                  letterSpacing: -0.28,
                                ),
                              ),
                              SizedBox(width: 12),
                              Text(
                                _totalTimeController.text,
                                style: TextStyle(
                                  color: const Color(0xFF3A88F4),
                                  fontSize: 14,
                                  fontFamily: 'Pretendard-Bold',
                                  letterSpacing: -0.32,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 버튼
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    child: TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        // 성공 메시지
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('신청 내용이 부모님께 전송되었습니다.'),
                            backgroundColor: Colors.green,
                          ),
                        );
                        // 이전 화면으로 돌아가기
                        Navigator.pop(context, true);
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0xFF5D9EFF),
                        padding: const EdgeInsets.all(16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        '이대로 부모님에게 전송하기',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontFamily: 'Pretendard-Light',
                          letterSpacing: -0.28,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
