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
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String _selectedDay = '월';
  int _selectedHour = 0;
  int _selectedMinute = 0;
  String _selectedDuration = "3h";
  final TextEditingController _totalTimeController = TextEditingController(
    text: '30,000원',
  );
  bool _saveButtonEnabled = false;

  // 날짜 선택 관련 변수 추가
  DateTime? _tempSelectedDate;
  bool _isSelectingNewDate = false;

  // 요일 선택
  final List<String> days = ['월', '화', '수', '목', '금', '토', '일'];
  // 기간 선택 옵션
  final List<String> durations = ['1h', '2h', '3h', '4h', '+'];

  // 달력 월 선택을 위한 변수
  int _currentMonth = DateTime.now().month;
  int _currentYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    // 기본값 설정
    _selectedHour = 18; // 6 PM (18시)
    _selectedMinute = 28; // 28분을 기본으로 선택
    _selectedDuration = "3h"; // 3시간을 기본으로 선택

    // 오늘 날짜로부터 하루 뒤를 기본으로 선택
    _selectedDate = DateTime.now().add(const Duration(days: 1));
    _selectedDay = days[_selectedDate.weekday - 1];

    // 월과 연도 초기화
    _currentYear = _selectedDate.year;
    _currentMonth = _selectedDate.month;

    _checkSaveButtonStatus();
  }

  void _checkSaveButtonStatus() {
    setState(() {
      // 버튼 활성화 조건 간소화 - 항상 활성화되도록 수정
      _saveButtonEnabled = true;

      // 이전 조건: _saveButtonEnabled =
      //    (_selectedHour > 0 || _selectedMinute > 0) &&
      //    _selectedDate.isAfter(DateTime.now()) &&
      //    _totalTimeController.text.isNotEmpty;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '챌린지 참여 신청하기',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 챌린지 정보 요약
              _buildChallengeSummary(),

              SizedBox(height: 24),

              // 날짜 선택 섹션
              Text(
                '원하는 요일을 선택해주세요',
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              ),
              SizedBox(height: 12),
              _buildDaySelector(),

              SizedBox(height: 24),

              // 시간 선택 섹션
              Text(
                '원하는 챌린지 시작 시간을 선택해주세요',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 12),
              _buildTimeSelector(),

              SizedBox(height: 24),

              // 기간 선택 섹션
              Text(
                '도전과제 금액',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              _buildAmountInput(),

              SizedBox(height: 40),

              // 하단 버튼
              _buildSaveButton(),

              SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChallengeSummary() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  widget.type,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
              ),
              Spacer(),
              Text(
                '참여인원: ${widget.participants}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            widget.title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '기간: ${widget.period}',
            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
          ),
          Text(
            '기본 시간: ${widget.time}',
            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }

  Widget _buildDaySelector() {
    // 현재 날짜 정보
    final now = DateTime.now();

    // 선택한 월의 첫 번째 날
    final firstDayOfMonth = DateTime(_currentYear, _currentMonth, 1);

    // 선택한 월의 마지막 날
    final lastDayOfMonth = DateTime(_currentYear, _currentMonth + 1, 0);

    // 첫 번째 날이 무슨 요일인지 (0: 월요일, 1: 화요일, ..., 6: 일요일)
    int firstWeekday = firstDayOfMonth.weekday - 1;
    if (firstWeekday < 0) firstWeekday = 6; // 일요일인 경우

    // 해당 월의 총 일수
    final daysInMonth = lastDayOfMonth.day;

    // 달력에 표시할 총 셀 수 (최대 6주 = 42칸)
    final totalCells = ((firstWeekday + daysInMonth) / 7).ceil() * 7;

    // 챌린지 종료 날짜 계산
    final DateTime endDate = _calculateEndDate();

    return Column(
      children: [
        // 선택된 날짜 정보 표시 (더 눈에 띄게 개선)
        Container(
          margin: EdgeInsets.symmetric(vertical: 10),
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.amber[50],
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.amber[300]!, width: 1.5),
          ),
          child: Column(
            children: [
              // 선택된 날짜 표시
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    color: Colors.amber[700],
                    size: 16,
                  ),
                  SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      '${_selectedDate.year}년 ${_selectedDate.month}월 ${_selectedDate.day}일 ($_selectedDay)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber[800],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 6),
              // 챌린지 기간 표시
              Row(
                children: [
                  Icon(Icons.date_range, color: Colors.blue[700], size: 14),
                  SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      '챌린지 기간: ${_selectedDate.month}월 ${_selectedDate.day}일 ~ ${endDate.month}월 ${endDate.day}일',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.blue[700],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        SizedBox(height: 12),

        // 달력 헤더 (월 선택 기능 포함)
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          decoration: BoxDecoration(
            color: Colors.blue[100],
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 1,
                blurRadius: 2,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 이전 달 버튼
              InkWell(
                onTap: () {
                  setState(() {
                    if (_currentMonth == 1) {
                      _currentMonth = 12;
                      _currentYear--;
                    } else {
                      _currentMonth--;
                    }
                  });
                },
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.chevron_left,
                    color: Colors.blue[700],
                    size: 20,
                  ),
                ),
              ),
              // 현재 월 표시
              Text(
                '$_currentYear년 $_currentMonth월',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.blue[800],
                ),
              ),
              // 다음 달 버튼
              InkWell(
                onTap: () {
                  setState(() {
                    if (_currentMonth == 12) {
                      _currentMonth = 1;
                      _currentYear++;
                    } else {
                      _currentMonth++;
                    }
                  });
                },
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.chevron_right,
                    color: Colors.blue[700],
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),

        // 요일 헤더
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[200],
            border: Border(
              bottom: BorderSide(color: Colors.grey[300]!, width: 1),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(7, (index) {
              return Container(
                width: 40,
                padding: EdgeInsets.symmetric(vertical: 10),
                alignment: Alignment.center,
                child: Text(
                  days[index],
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w100,
                    fontFamily: 'Pretendard-Thin',
                    color:
                        (index == 6) // 일요일만 빨간색으로 변경
                            ? Colors.red[700]
                            : Colors.grey[800],
                  ),
                ),
              );
            }),
          ),
        ),

        // 달력 그리드
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
            border: Border.all(color: Colors.grey[300]!),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 6,
                spreadRadius: 1.5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            padding: EdgeInsets.all(4),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1.0,
              mainAxisSpacing: 2,
              crossAxisSpacing: 2,
            ),
            itemCount: totalCells,
            itemBuilder: (context, index) {
              // 날짜 계산
              final day = index - firstWeekday + 1;

              // 이번 달의 날짜인지 확인
              final isCurrentMonth = day > 0 && day <= daysInMonth;

              if (!isCurrentMonth) {
                return Container(); // 이번 달이 아닌 셀은 빈 컨테이너로 표시
              }

              // 현재 날짜 객체 생성
              final date = DateTime(_currentYear, _currentMonth, day);

              // 오늘 날짜인지 확인
              final isToday =
                  date.year == now.year &&
                  date.month == now.month &&
                  date.day == now.day;

              // 선택된 날짜인지 확인
              final isSelected =
                  date.year == _selectedDate.year &&
                  date.month == _selectedDate.month &&
                  date.day == _selectedDate.day;

              // 챌린지 종료일인지 확인
              final isEndDate =
                  date.year == endDate.year &&
                  date.month == endDate.month &&
                  date.day == endDate.day;

              // 일요일인지 확인 (일요일: 7)
              final isSunday = date.weekday == 7;

              // 현재 날짜보다 이전 날짜인지 확인
              final isPastDate = date.isBefore(
                DateTime(now.year, now.month, now.day),
              );

              // 챌린지 시작날짜와 종료날짜 사이인지 확인
              final isInChallengePeriod =
                  (date.isAfter(_selectedDate) ||
                      date.isAtSameMomentAs(_selectedDate)) &&
                  (date.isBefore(endDate) || date.isAtSameMomentAs(endDate));

              return InkWell(
                onTap: () {
                  if (!isPastDate) {
                    // 과거 날짜는 선택할 수 없음
                    setState(() {
                      // 이미 선택된 날짜를 다시 클릭한 경우
                      if (isSelected) {
                        _isSelectingNewDate = true;
                        _tempSelectedDate = _selectedDate;
                        // 시각적 피드백을 위해 여기서는 아무것도 변경하지 않음
                      }
                      // 새 날짜를 선택 중이고 임시 저장된 날짜가 있는 경우
                      else if (_isSelectingNewDate &&
                          _tempSelectedDate != null) {
                        _selectedDate = date;
                        final weekdayIndex = date.weekday - 1;
                        _selectedDay =
                            days[weekdayIndex >= 0 ? weekdayIndex : 6];

                        // 선택 모드 초기화
                        _isSelectingNewDate = false;
                        _tempSelectedDate = null;
                        _checkSaveButtonStatus();
                      }
                      // 일반적인 날짜 선택
                      else {
                        _selectedDate = date;
                        final weekdayIndex = date.weekday - 1;
                        _selectedDay =
                            days[weekdayIndex >= 0 ? weekdayIndex : 6];
                        _checkSaveButtonStatus();
                      }
                    });
                  }
                },
                child: Container(
                  margin: EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color:
                        isSelected
                            ? _isSelectingNewDate
                                ? Colors.amber[400]
                                : Colors.blue[600]
                            : isEndDate
                            ? Colors.blue[400]
                            : isInChallengePeriod
                            ? Colors.blue.withOpacity(0.1)
                            : isToday
                            ? Colors.transparent
                            : Colors.transparent,
                    // 시작일과 종료일은 원형, 챌린지 기간 날짜는 배경색만 적용, 오늘 날짜는 테두리만 적용
                    borderRadius: BorderRadius.circular(
                      isSelected || isEndDate ? 20 : 0,
                    ),
                    border:
                        isToday &&
                                !isSelected &&
                                !isInChallengePeriod &&
                                !isEndDate
                            ? null // 오늘 날짜 테두리 제거
                            : _isSelectingNewDate && isSelected
                            ? Border.all(color: Colors.amber[700]!, width: 2.5)
                            : null,
                    boxShadow:
                        isSelected || isEndDate
                            ? [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 6,
                                spreadRadius: 1.5,
                                offset: const Offset(0, 3),
                              ),
                            ]
                            : null,
                  ),
                  alignment: Alignment.center,
                  child: Stack(
                    children: [
                      // 날짜 텍스트
                      Center(
                        child: Text(
                          '$day',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight:
                                isSelected || isEndDate || isToday
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                            color:
                                isPastDate
                                    ? Colors.grey.withOpacity(0.5)
                                    : isSelected || isEndDate
                                    ? Colors.white
                                    : isSunday // 일요일만 빨간색으로 변경
                                    ? Colors.red
                                    : Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSelector() {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              // 안내 메시지
              SizedBox(height: 28),

              // 시간/분/AM-PM 선택
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 시간 선택
                  SizedBox(
                    height: 120,
                    width: 45,
                    child: ListWheelScrollView.useDelegate(
                      itemExtent: 40,
                      diameterRatio: 1.5,
                      perspective: 0.005,
                      physics: FixedExtentScrollPhysics(),
                      onSelectedItemChanged: (index) {
                        setState(() {
                          // 12시간제로 변환 (0-11)
                          if (_selectedHour >= 12) {
                            _selectedHour = index + 12; // PM
                          } else {
                            _selectedHour = index; // AM
                          }
                          _checkSaveButtonStatus();
                        });
                      },
                      childDelegate: ListWheelChildBuilderDelegate(
                        childCount: 12,
                        builder: (context, index) {
                          // 0 -> 12, 1-11 -> 1-11
                          int displayHour = index == 0 ? 12 : index;
                          bool isSelected = (_selectedHour % 12) == index;

                          return Center(
                            child: Text(
                              displayHour < 10
                                  ? '0$displayHour'
                                  : '$displayHour',
                              style: TextStyle(
                                fontSize: isSelected ? 24 : 18,
                                fontWeight:
                                    isSelected
                                        ? FontWeight.bold
                                        : FontWeight.w400,
                                color:
                                    isSelected
                                        ? Colors.black
                                        : Colors.grey[300],
                              ),
                            ),
                          );
                        },
                      ),
                      controller: FixedExtentScrollController(
                        initialItem: (_selectedHour % 12),
                      ),
                    ),
                  ),

                  // 구분선
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: SizedBox(
                      height: 120,
                      child: Center(
                        child: Text(
                          ':',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[400],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // 분 선택
                  SizedBox(
                    height: 120,
                    width: 45,
                    child: ListWheelScrollView.useDelegate(
                      itemExtent: 40,
                      diameterRatio: 1.5,
                      perspective: 0.005,
                      physics: FixedExtentScrollPhysics(),
                      onSelectedItemChanged: (index) {
                        setState(() {
                          _selectedMinute = index;
                          _checkSaveButtonStatus();
                        });
                      },
                      childDelegate: ListWheelChildBuilderDelegate(
                        childCount: 60,
                        builder: (context, index) {
                          bool isSelected = _selectedMinute == index;

                          return Center(
                            child: Text(
                              index < 10 ? '0$index' : '$index',
                              style: TextStyle(
                                fontSize: isSelected ? 24 : 18,
                                fontWeight:
                                    isSelected
                                        ? FontWeight.bold
                                        : FontWeight.w400,
                                color:
                                    isSelected
                                        ? Colors.black
                                        : Colors.grey[300],
                              ),
                            ),
                          );
                        },
                      ),
                      controller: FixedExtentScrollController(
                        initialItem: _selectedMinute,
                      ),
                    ),
                  ),

                  SizedBox(width: 8),

                  // AM/PM 선택
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: 16),

                      // PM 옵션
                      InkWell(
                        onTap: () {
                          setState(() {
                            if (_selectedHour < 12) {
                              _selectedHour += 12;
                            }
                            _checkSaveButtonStatus();
                          });
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            vertical: 6,
                            horizontal: 6,
                          ),
                          child: Text(
                            'PM',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color:
                                  _selectedHour >= 12
                                      ? Colors.black
                                      : Colors.grey[300],
                            ),
                          ),
                        ),
                      ),

                      // 구분선
                      Container(
                        height: 1,
                        width: 36,
                        color: Colors.grey[300],
                        margin: EdgeInsets.symmetric(vertical: 6),
                      ),

                      // AM 옵션
                      InkWell(
                        onTap: () {
                          setState(() {
                            if (_selectedHour >= 12) {
                              _selectedHour -= 12;
                            }
                            _checkSaveButtonStatus();
                          });
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            vertical: 6,
                            horizontal: 6,
                          ),
                          child: Text(
                            'AM',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight:
                                  _selectedHour < 12
                                      ? FontWeight.bold
                                      : FontWeight.w400,
                              color:
                                  _selectedHour < 12
                                      ? Colors.black
                                      : Colors.grey[300],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),

        SizedBox(height: 16),

        // 공부 시간 설정 텍스트
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(left: 0, bottom: 13.0),
            child: Text(
              '추가할 시간을 선택해주세요',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
        ),

        // 기간 선택 버튼들
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.start,
          children:
              durations.map((duration) {
                return _buildTimeButton(
                  duration,
                  duration == _selectedDuration,
                );
              }).toList(),
        ),
      ],
    );
  }

  Widget _buildTimeControlButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 80,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(18),
        ),
        alignment: Alignment.center,
        child: Icon(icon, color: Colors.black),
      ),
    );
  }

  Widget _buildTimeButton(String text, bool isSelected) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedDuration = text;
          if (text != '+') {
            // + 버튼이 아닌 경우에만 금액 업데이트
            int hours = int.parse(text.replaceAll('h', ''));
            int amount = hours * 10000; // 1시간당 10,000원
            _totalTimeController.text =
                '${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}원';
          } else {
            // + 버튼을 누른 경우 커스텀 시간 입력 다이얼로그 표시
            _showCustomDurationDialog();
          }
          _checkSaveButtonStatus();
        });
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.grey[300],
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }

  // 커스텀 시간 입력 다이얼로그
  void _showCustomDurationDialog() {
    final TextEditingController customHoursController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('원하는 챌린지 시작 시간을 선택해주세요'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('원하는 시간을 입력하세요 (시간 단위)', style: TextStyle(fontSize: 14)),
              SizedBox(height: 16),
              TextField(
                controller: customHoursController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: '시간 입력 (예: 5)',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // 다이얼로그 닫기
              },
              child: Text('취소'),
            ),
            TextButton(
              onPressed: () {
                // 입력한 시간 값 처리
                if (customHoursController.text.isNotEmpty) {
                  int hours = int.tryParse(customHoursController.text) ?? 0;
                  if (hours > 0) {
                    setState(() {
                      // 금액만 업데이트하고 선택된 시간은 "+"로 유지
                      _selectedDuration = "+";

                      // 금액 계산
                      int amount = hours * 10000; // 1시간당 10,000원
                      _totalTimeController.text =
                          '${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}원';
                    });
                  }
                }
                Navigator.of(context).pop(); // 다이얼로그 닫기
              },
              child: Text('확인'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAmountInput() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: _totalTimeController,
        keyboardType: TextInputType.number,
        style: TextStyle(fontSize: 16),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: '금액 입력',
          hintStyle: TextStyle(color: Colors.grey[400]),
        ),
        onChanged: (value) {
          _checkSaveButtonStatus();
        },
      ),
    );
  }

  Widget _buildSaveButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap:
            _saveButtonEnabled
                ? () {
                  // 확인 모달 표시
                  _showConfirmationModal();
                }
                : null,
        splashColor: Colors.white.withOpacity(0.3),
        highlightColor: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        child: Ink(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: _saveButtonEnabled ? Color(0xFFFF3B30) : Colors.grey[300],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              '챌린지 참여 신청하기',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 확인 모달
  void _showConfirmationModal() {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: EdgeInsets.symmetric(horizontal: 20),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 헤더
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '신청한 요일별 챌린지 정보를 확인할게요',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w100,
                            color: Colors.black,
                          ),
                        ),
                        InkWell(
                          onTap: () => Navigator.pop(context),
                          child: Icon(
                            Icons.close,
                            size: 18,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 파란색 정보 컨테이너
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF91BFFF), Color(0xFFC1DDFF)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 신청 보상금
                              Container(
                                width: double.infinity,
                                padding: EdgeInsets.symmetric(
                                  vertical: 10,
                                  horizontal: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          '신청 보상금',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w100,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                        SizedBox(width: 4),
                                        Icon(
                                          Icons.info_outline,
                                          size: 16,
                                          color: Colors.grey[400],
                                        ),
                                      ],
                                    ),
                                    Text(
                                      '55,000원',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w300,
                                        fontFamily: 'Pretendard-Thin',
                                        color: Color(0xFF146AFF),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              SizedBox(height: 15),

                              // 요일별
                              Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '요일별',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w100,
                                        fontFamily: 'Pretendard-Thin',
                                        color: Color(0xFF5D9EFF),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 6),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '3.20 ~ 27',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w100,
                                        fontFamily: 'Pretendard-Thin',
                                        color: Color(0xFF5D9EFF),
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              SizedBox(height: 14),

                              // 참여 인원
                              Text(
                                '참여 인원 30/40',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w100,
                                ),
                              ),

                              SizedBox(height: 10),

                              // 기간
                              Text(
                                '기간 3.20 - 3.27',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w100,
                                ),
                              ),

                              SizedBox(height: 10),

                              // 시간
                              Text(
                                '시간 설정 가능',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w100,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // 오른쪽 원형 구멍
                        Positioned(
                          right: -10,
                          top: 0,
                          bottom: 0,
                          child: Center(
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 버튼
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context).pop(); // 모달 닫기

                        // 성공 메시지 표시
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('신청 내용이 부모님께 전송되었습니다.'),
                            backgroundColor: Colors.green,
                            duration: Duration(seconds: 3),
                          ),
                        );

                        // 이전 화면으로 돌아가기
                        Navigator.pop(context, true);
                      },
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: Color(0xFF0066FF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '이대로 부모님께 전송하기',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w100,
                            fontFamily: 'Pretendard-Thin',
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // 챌린지 완료 날짜 계산
  DateTime _calculateEndDate() {
    // 챌린지 기간에 따라 다르게 계산
    // 이 예시에서는 1주일로 가정
    return _selectedDate.add(const Duration(days: 6)); // 시작일 포함 7일
  }
}
