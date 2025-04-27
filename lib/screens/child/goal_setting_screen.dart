import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

class GoalSettingScreen extends StatefulWidget {
  final Map<String, dynamic>? initialGoal;
  const GoalSettingScreen({super.key, this.initialGoal});

  @override
  State<GoalSettingScreen> createState() => _GoalSettingScreenState();
}

class _GoalSettingScreenState extends State<GoalSettingScreen> {
  String _selectedGoalType = '성실한 습관 형성을 원해요';
  String _goalTitle = '';
  DateTime _startDate = DateTime(2025, 4, 22);
  DateTime _endDate = DateTime(2025, 4, 22); // 기본값은 시작일과 같게 설정
  bool _isSelectingStartDate = true;
  bool _isCalendarExpanded = true;
  bool _isSingleDayMode = false; // 기본값은 기간 선택 모드
  
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _rewardController = TextEditingController(text: '30,000원');

  @override
  void initState() {
    super.initState();
    initializeDateFormatting();
    
    if (widget.initialGoal != null) {
      _selectedGoalType = widget.initialGoal!['type'] as String? ?? '성실한 습관 형성을 원해요';
      _goalTitle = widget.initialGoal!['title'] as String? ?? '';

      if (widget.initialGoal!['startDate'] != null) {
        _startDate = widget.initialGoal!['startDate'] as DateTime;
      }
      if (widget.initialGoal!['endDate'] != null) {
        _endDate = widget.initialGoal!['endDate'] as DateTime;
        _isSingleDayMode = false;
      } else {
        _endDate = _startDate; // 종료일이 없으면 시작일과 같게 설정
        _isSingleDayMode = true;
      }

      _titleController.text = _goalTitle;
      if (widget.initialGoal!['reward'] != null) {
        _rewardController.text = widget.initialGoal!['reward'] as String? ?? '30,000원';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.black, size: 16),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '목표 설정하기',
          style: TextStyle(
            color: Color(0xFF202020),
            fontSize: 16,
            fontFamily: 'Spoqa Han Sans Neo',
            fontWeight: FontWeight.w700,
            height: 1.3,
            letterSpacing: -0.2,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.close, color: Colors.black, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. 목표 유형 선택
              _buildNumberedSection(
                number: '1',
                title: '원하는 목표 유형을 알려주세요!',
                content: _buildGoalTypeSelection(),
              ),
              
              const SizedBox(height: 32),
              
              // 2. 목표 이름 입력
              _buildNumberedSection(
                number: '2',
                title: '어떤 이름의 목표를 설정해 볼까요?',
                subtitle: '부모님과 나의 목표에 노출돼요 XXXX',
                content: _buildTitleInput(),
              ),
              
              const SizedBox(height: 32),
              
              // 3. 기간 선택
              _buildNumberedSection(
                number: '3',
                title: '원하는 기간을 선택해 주세요',
                content: _buildDateSelection(),
              ),

              const SizedBox(height: 32),
              
              // 4. 보상금 입력
              _buildNumberedSection(
                number: '4',
                title: '원하는 보상금을 기입해 주세요',
                content: _buildRewardInput(),
              ),
              
              const SizedBox(height: 40),

              // 신청 완료 버튼
              Container(
                width: double.infinity,
                height: 48,
                decoration: ShapeDecoration(
                  color: const Color(0xFF999999),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
                child: const Center(
                  child: Text(
                    '신청 완료',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontFamily: 'Spoqa Han Sans Neo',
                      fontWeight: FontWeight.w400,
                      height: 1.4,
                      letterSpacing: -0.2,
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

  // 번호가 있는 섹션 위젯
  Widget _buildNumberedSection({
    required String number,
    required String title,
    String? subtitle,
    required Widget content,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 번호 및 제목 - 세로로 배치
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // 원 안의 번호
            Container(
              width: 32,
              height: 32,
              decoration: const ShapeDecoration(
                color: Color(0xFFF2F2F2),
                shape: OvalBorder(),
              ),
              child: Center(
                child: Text(
                  number,
                style: const TextStyle(
                    color: Color(0xFF212124),
                  fontSize: 16,
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w500,
                  ),
                ),
                ),
              ),
              const SizedBox(height: 8),
            // 제목
                    Text(
              title,
                      style: const TextStyle(
                color: Color(0xFF202020),
                fontSize: 16,
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w700,
              ),
            ),
            if (subtitle != null) 
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF888888),
                    fontSize: 12,
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        const SizedBox(height: 16),
        content,
      ],
    );
  }

  // 1. 목표 유형 선택 위젯
  Widget _buildGoalTypeSelection() {
    return Column(
      children: [
        // 학습 인증 카드
        _buildGoalTypeCard(
          title: '꾸준한 학습 인증을 원해요',
          subtitle: '이번 주 주말 3시간 공부 도전',
          isSelected: _selectedGoalType == '꾸준한 학습 인증을 원해요',
          onTap: () {
            setState(() {
              _selectedGoalType = '꾸준한 학습 인증을 원해요';
            });
          },
        ),

        const SizedBox(height: 16),

        // 습관 형성 카드
        _buildGoalTypeCard(
          title: '성실한 습관 형성을 원해요',
          subtitle: '이번 주 설거지 담당, 깨우지 않아도 일어나기',
          isSelected: _selectedGoalType == '성실한 습관 형성을 원해요',
          onTap: () {
                setState(() {
              _selectedGoalType = '성실한 습관 형성을 원해요';
                });
              },
        ),
      ],
    );
  }

  // 목표 유형 카드 위젯
  Widget _buildGoalTypeCard({
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: ShapeDecoration(
          color: isSelected ? const Color(0xFFFFC8C9) : Colors.white,
          shape: RoundedRectangleBorder(
            side: BorderSide(
              width: isSelected ? 1.3 : 1.0,
              color: isSelected ? const Color(0xFFFF6062) : const Color(0xFFC4C4C4),
            ),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 15,
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF888888),
                      fontSize: 13,
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                width: 24,
                height: 24,
                decoration: const ShapeDecoration(
                  color: Color(0xFFFF6062),
                  shape: OvalBorder(),
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 16),
              ),
          ],
        ),
      ),
    );
  }

  // 2. 목표 이름 입력 위젯
  Widget _buildTitleInput() {
    return TextField(
      controller: _titleController,
      style: const TextStyle(
        fontSize: 15,
        fontFamily: 'Pretendard',
        fontWeight: FontWeight.w400,
      ),
      decoration: InputDecoration(
        hintText: '제목을 입력해 주세요',
        hintStyle: const TextStyle(
          color: Color(0xFF999999),
          fontSize: 15,
          fontFamily: 'Pretendard',
          fontWeight: FontWeight.w400,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            width: 1,
            color: Color(0xFFDDDDDD),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            width: 1,
            color: Color(0xFFDDDDDD),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            width: 1,
            color: Color(0xFFDDDDDD),
          ),
        ),
        // X 버튼 추가
        suffixIcon: _titleController.text.isNotEmpty ? 
          GestureDetector(
            onTap: () {
              _titleController.clear();
              setState(() {
                _goalTitle = '';
              });
            },
            child: Container(
              width: 20,
              height: 20,
              margin: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFFEEEEEE),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                size: 14,
                color: Color(0xFF666666),
              ),
            ),
          ) : null,
      ),
      onChanged: (value) {
        setState(() {
          _goalTitle = value;
        });
      },
    );
  }
  
  // 날짜 표시 포맷
  String _formatSelectedDate() {
    if (_startDate.day == _endDate.day) {
      return '2025년 4월 ${_startDate.day}일 (${_getKoreanWeekday(_startDate)})';
    } else {
      return '2025년 4월 ${_startDate.day}일 ~ ${_endDate.day}일';
    }
  }
  
  // 요일을 한글로 반환하는 함수
  String _getKoreanWeekday(DateTime date) {
    final weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    return weekdays[(date.weekday - 1) % 7];
  }

  // 3. 날짜 선택 위젯
  Widget _buildDateSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 날짜 선택 헤더
        Row(
          children: [
            const Text(
              '날짜 선택',
              style: TextStyle(
                color: Colors.black,
                fontSize: 15,
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              _formatSelectedDate(),
              style: const TextStyle(
                color: Color(0xFFFF6062),
                fontSize: 15,
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w400,
              ),
            ),
            const Spacer(),
            // 확장 버튼
            GestureDetector(
              onTap: () {
                setState(() {
                  _isCalendarExpanded = !_isCalendarExpanded;
                });
              },
              child: Icon(
                _isCalendarExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                color: Colors.black,
                size: 22,
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),
        
        // 달력 부분
        Container(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. 요일 헤더 (일, 월, 화, 수, 목, 금, 토)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
                  DayHeader('일', isRed: true),
                  DayHeader('월'),
                  DayHeader('화'),
                  DayHeader('수'),
                  DayHeader('목'),
                  DayHeader('금'),
                  DayHeader('토'),
                ],
              ),
              
              // 2. 구분선
              Divider(
                color: const Color(0xFFDDDDDD),
                height: 20,
                thickness: 1,
              ),
              
              // 3. 2025년 4월 표시
              Padding(
                padding: const EdgeInsets.only(top: 6, bottom: 16),
                child: Text(
                  '2025년 4월',
                  style: const TextStyle(
                    color: Color(0xFF202020),
                    fontSize: 14,
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              
              // 4. 날짜 표시 - 확장 여부에 따라 달라짐
              _isCalendarExpanded 
                ? _buildMonthCalendar() // 펼쳤을 때 월 전체 표시
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: _buildWeekCells(), // 접었을 때 일주일만 표시
              ),
            ],
          ),
          ),
      ],
    );
  }

  // 달력 월 전체 표시 위젯
  Widget _buildMonthCalendar() {
    // 2025년 4월 1일
    final firstDayOfMonth = DateTime(2025, 4, 1);
    
    // 4월의 첫날이 무슨 요일인지 (0: 일요일, 1: 월요일, ..., 6: 토요일)
    final int firstWeekdayOfMonth = firstDayOfMonth.weekday % 7;
    
    // 4월의 마지막 날짜
    final lastDayOfMonth = DateTime(2025, 5, 0).day; // 5월 0일은 4월의 마지막 날
    
    // 달력에 표시할 주 수 계산
    final int weeksInMonth = ((firstWeekdayOfMonth + lastDayOfMonth) / 7).ceil();
    
    List<Widget> weeks = [];
    
    int day = 1;
    
    // 각 주마다 행 생성
    for (int week = 0; week < weeksInMonth; week++) {
      List<Widget> daysInWeek = [];
      
      // 각 주의 7일(일~토) 생성
      for (int weekday = 0; weekday < 7; weekday++) {
        // 첫 주에서 1일 이전의 빈 셀
        if (week == 0 && weekday < firstWeekdayOfMonth) {
          daysInWeek.add(const SizedBox(width: 40, height: 40));
          continue;
        }
        
        // 마지막 날짜 이후의 빈 셀
        if (day > lastDayOfMonth) {
          daysInWeek.add(const SizedBox(width: 40, height: 40));
          continue;
        }
        
        // 현재 날짜
        final currentDate = DateTime(2025, 4, day);
        
        // 선택 상태 확인
        bool isStartDate = currentDate.day == _startDate.day;
        bool isEndDate = currentDate.day == _endDate.day;
        bool isInRange = currentDate.isAfter(_startDate.subtract(const Duration(days: 1))) && 
                         currentDate.isBefore(_endDate.add(const Duration(days: 1)));
        
        // 날짜 셀 추가
        daysInWeek.add(
          DateCell(
            date: day.toString(),
            isSelected: isStartDate || isEndDate,
            isInRange: isInRange && !isStartDate && !isEndDate,
            onTap: () {
              setState(() {
                if (_isSelectingStartDate) {
                  // 시작일 선택
                  _startDate = currentDate;
                  _endDate = currentDate; // 초기에는 동일하게 설정
                  _isSelectingStartDate = false;
                } else {
                  // 종료일 선택
                  if (currentDate.isBefore(_startDate)) {
                    // 종료일이 시작일보다 이전이면 시작일과 종료일을 교체
                    _endDate = _startDate;
                    _startDate = currentDate;
                  } else {
                    _endDate = currentDate;
                  }
                  _isSelectingStartDate = true;
                }
              });
            },
          ),
        );
        
        day++;
      }
      
      // 주 행 추가
      weeks.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: daysInWeek,
          ),
        ),
      );
    }
    
    return Column(children: weeks);
  }
  
  // 주간 달력 셀 생성 (접었을 때 표시)
  List<Widget> _buildWeekCells() {
    final List<Widget> cells = [];
    
    // 현재 선택된 날짜가 포함된 주의 날짜들 계산
    int weekStart = _startDate.day - _startDate.weekday + 1;
    if (weekStart < 1) weekStart = 1;
    
    for (int i = 0; i < 7; i++) {
      int day = weekStart + i;
      if (day > 30) break; // 4월은 30일까지
      
      // 현재 날짜
      final currentDate = DateTime(2025, 4, day);
      
      // 선택 상태 확인
      bool isStartDate = currentDate.day == _startDate.day;
      bool isEndDate = currentDate.day == _endDate.day;
      bool isInRange = currentDate.isAfter(_startDate.subtract(const Duration(days: 1))) && 
                       currentDate.isBefore(_endDate.add(const Duration(days: 1)));
      
      cells.add(
        DateCell(
          date: day.toString(),
          isSelected: isStartDate || isEndDate,
          isInRange: isInRange && !isStartDate && !isEndDate,
          onTap: () {
    setState(() {
              if (_isSelectingStartDate) {
                // 시작일 선택
                _startDate = currentDate;
                _endDate = currentDate; // 초기에는 동일하게 설정
                _isSelectingStartDate = false;
      } else {
                // 종료일 선택
                if (currentDate.isBefore(_startDate)) {
                  // 종료일이 시작일보다 이전이면 시작일과 종료일을 교체
          _endDate = _startDate;
                  _startDate = currentDate;
        } else {
                  _endDate = currentDate;
                }
                _isSelectingStartDate = true;
              }
            });
          },
        ),
      );
    }
    
    return cells;
  }
  
  // 4. 보상금 입력 위젯
  Widget _buildRewardInput() {
    return TextField(
      controller: _rewardController,
      style: const TextStyle(
        fontSize: 15,
        fontFamily: 'Pretendard',
        fontWeight: FontWeight.w400,
      ),
      decoration: InputDecoration(
        hintText: '30,000원',
        hintStyle: const TextStyle(
          color: Color(0xFF999999),
          fontSize: 15,
          fontFamily: 'Pretendard',
          fontWeight: FontWeight.w400,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            width: 1,
            color: Color(0xFFDDDDDD),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            width: 1,
            color: Color(0xFFDDDDDD),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            width: 1,
            color: Color(0xFFDDDDDD),
          ),
        ),
        // X 버튼 추가
        suffixIcon: _rewardController.text.isNotEmpty ? 
          GestureDetector(
            onTap: () {
              _rewardController.clear();
              setState(() {});
            },
            child: Container(
              width: 20,
              height: 20,
              margin: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFFEEEEEE),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                size: 14,
                color: Color(0xFF666666),
              ),
            ),
          ) : null,
      ),
      keyboardType: TextInputType.number,
    );
  }
}

// 요일 헤더 위젯 (일, 월, 화 등)
class DayHeader extends StatelessWidget {
  final String dayName;
  final bool isRed;
  
  const DayHeader(this.dayName, {super.key, this.isRed = false});
  
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      child: Text(
        dayName,
        textAlign: TextAlign.center,
          style: TextStyle(
          color: isRed ? const Color(0xFFFF6062) : const Color(0xFF4C5869),
          fontSize: 13,
          fontFamily: 'Pretendard',
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// 날짜 셀 위젯 (9, 10, 11 등)
class DateCell extends StatelessWidget {
  final String date;
  final bool isSelected;
  final bool isInRange;
  final VoidCallback onTap;
  
  const DateCell({
    super.key,
    required this.date,
    this.isSelected = false,
    this.isInRange = false,
    required this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isSelected 
                ? const Color(0xFFFF6464) 
                : (isInRange ? const Color(0xFFFFE8E8) : Colors.transparent),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            date,
            style: TextStyle(
              color: isSelected 
                    ? Colors.white 
                    : (isInRange ? const Color(0xFFFF6464) : const Color(0xFF4C5869)),
              fontSize: 15,
              fontFamily: 'Pretendard',
              fontWeight: isSelected || isInRange ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}

