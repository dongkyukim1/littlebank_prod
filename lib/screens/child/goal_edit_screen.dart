import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../../services/goal_service.dart';
import '../../services/family_service.dart';

class GoalEditScreen extends StatefulWidget {
  final Map<String, dynamic> initialGoalData; // 수정할 목표의 전체 데이터

  const GoalEditScreen({super.key, required this.initialGoalData});

  @override
  State<GoalEditScreen> createState() => _GoalEditScreenState();
}

class _GoalEditScreenState extends State<GoalEditScreen> {
  String _selectedGoalType = '학습 인증';
  String _goalTitle = '';
  DateTime _selectedCalendarMonth = DateTime.now(); // 달력 표시용 월
  String _rewardAmount = '';
  List<DateTime> _selectedDates = []; 
  bool _isLoading = false;
  bool _isCalendarExpanded = true;
  late int _goalIdToEdit;

  final TextEditingController _goalTitleController = TextEditingController();
  final TextEditingController _rewardAmountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    initializeDateFormatting();
    _initializeGoalData();
  }

  void _initializeGoalData() {
    final goal = widget.initialGoalData;
    _goalIdToEdit = goal['goalId'] as int;
    _selectedGoalType = GoalService.getCategoryText(goal['category'] as String? ?? 'LEARNING');
    _goalTitleController.text = goal['title'] as String? ?? '';
    _rewardAmountController.text = (goal['reward'] as int? ?? 0).toString();

    if (goal['startDate'] != null) {
      try {
        DateTime startDate = DateTime.parse(goal['startDate'] as String);
        _selectedCalendarMonth = DateTime(startDate.year, startDate.month, 1);
        _selectWeekFromMonday(startDate);
      } catch (e) {
        print("Error parsing startDate: $e");
        _selectedCalendarMonth = DateTime.now();
      }
    } else {
      _selectedCalendarMonth = DateTime.now();
    }
  }

  @override
  void dispose() {
    _goalTitleController.dispose();
    _rewardAmountController.dispose();
    super.dispose();
  }

  void _selectWeekFromMonday(DateTime monday) {
    // 월요일이 아니면 해당 주의 월요일로 변경
    DateTime startOfWeek = monday.subtract(Duration(days: monday.weekday - 1));
    setState(() {
      _selectedDates.clear();
      for (int i = 0; i < 7; i++) {
        _selectedDates.add(startOfWeek.add(Duration(days: i)));
      }
    });
  }

  bool _isDateInSelectedWeek(DateTime date) {
    if (_selectedDates.isEmpty) return false;
    final monday = _selectedDates.first;
    final sunday = _selectedDates.last;
    return date.isAfter(monday.subtract(const Duration(days: 1))) && 
           date.isBefore(sunday.add(const Duration(days: 1)));
  }

  bool _isMonday(DateTime date) {
    return date.weekday == DateTime.monday;
  }

  Future<void> _submitGoalUpdate() async {
    if (_goalTitleController.text.trim().isEmpty) {
      _showErrorDialog('목표 제목을 입력해주세요.');
      return;
    }
    if (_selectedDates.isEmpty) {
      _showErrorDialog('목표를 수행할 주를 선택해주세요.');
      return;
    }
    if (_rewardAmountController.text.trim().isEmpty) {
      _showErrorDialog('보상금을 입력해주세요.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final startDate = _selectedDates.first;
      final endDate = _selectedDates.last;
      final category = GoalService.convertGoalTypeToCategory(_selectedGoalType);
      final rewardAmount = GoalService.parseRewardAmount(_rewardAmountController.text);

      final result = await GoalService.updateGoal(
        goalId: _goalIdToEdit,
        title: _goalTitleController.text.trim(),
        category: category,
        reward: rewardAmount,
        startDate: startDate,
        endDate: endDate,
      );

      if (result['success'] == true) {
        Navigator.pop(context, true); // true를 반환하여 목록 새로고침 유도
        _showSuccessDialog(result['message'] ?? '목표가 성공적으로 수정되었습니다!');
      } else {
        _showErrorDialog(result['message'] ?? '목표 수정에 실패했습니다.');
      }
    } catch (e) {
      _showErrorDialog(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('오류', style: TextStyle(fontFamily: 'Pretendard-Bold', fontSize: 16)),
          content: Text(message, style: const TextStyle(fontFamily: 'Pretendard-Regular', fontSize: 14)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('확인', style: TextStyle(fontFamily: 'Pretendard-Medium', color: Color(0xFF5D9EFF))),
            ),
          ],
        );
      },
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('성공', style: TextStyle(fontFamily: 'Pretendard-Bold', fontSize: 16)),
          content: Text(message, style: const TextStyle(fontFamily: 'Pretendard-Regular', fontSize: 14)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(), // 현재 다이얼로그만 닫음
              child: const Text('확인', style: TextStyle(fontFamily: 'Pretendard-Medium', color: Color(0xFF5D9EFF))),
            ),
          ],
        );
      },
    );
  }

  // UI 빌드 메서드들은 GoalSettingScreen과 거의 동일 (제목, 버튼 텍스트 등만 변경)
  // ... (GoalSettingScreen의 _buildSection, _buildGoalTypeCards, _buildTitleInput, _buildDateSelection, _buildRewardInput, _buildCalendarGrid, _buildMonthCalendar, _buildCalendarDay 메서드들을 복사하여 붙여넣고 필요에 따라 수정)
  // 예: 신청하기 버튼 -> 수정하기 버튼

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFF2F6),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          '목표 수정하기', // 화면 제목 변경
          style: TextStyle(
            color: Color(0xFF202020),
            fontSize: 14,
            fontFamily: 'Pretendard-Bold',
            letterSpacing: -0.32,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Container(
          width: MediaQuery.of(context).size.width,
          clipBehavior: Clip.antiAlias,
          decoration: const BoxDecoration(
            color: Color(0xFFEFF2F6),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              _buildSection(
                number: '1',
                title: '원하는 목표 유형을 알려주세요',
                subtitle: '한 번에 하나만 선택할 수 있어요!',
                content: _buildGoalTypeCards(),
              ),
              _buildSection(
                number: '2',
                title: '어떤 제목의 목표를 설정해 볼까요?',
                subtitle: '부모님과 나의 목표에 노출돼요!',
                content: _buildTitleInput(),
              ),
              _buildSection(
                number: '3',
                title: '원하는 기간을 선택해 주세요',
                subtitle: '유형 선택을 통해 쉽게 XXX',
                content: _buildDateSelection(),
              ),
              _buildSection(
                number: '4',
                title: '원하는 보상금을 입력해 주세요',
                subtitle: '부모님에게 원하는 보상금을 대신 전해드릴게요!',
                content: _buildRewardInput(),
              ),
              GestureDetector(
                onTap: _isLoading ? null : _submitGoalUpdate, // 수정 함수 호출
                child: Container(
                  width: MediaQuery.of(context).size.width - 32,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  margin: const EdgeInsets.only(bottom: 30, top: 20),
                  decoration: ShapeDecoration(
                    color: _isLoading 
                        ? const Color(0xFF146AFF).withOpacity(0.6)
                        : const Color(0xFF146AFF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Center(
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            '이대로 수정하기', // 버튼 텍스트 변경
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontFamily: 'Pretendard-Medium',
                              letterSpacing: -0.24,
                            ),
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

  Widget _buildSection({ required String number, required String title, String? subtitle, required Widget content}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      margin: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: const ShapeDecoration(color: Color(0xFFFFD27F), shape: OvalBorder()),
            child: Center(child: Text(number, style: const TextStyle(color: Color(0xFF001F55), fontSize: 14, fontFamily: 'Pretendard-Bold'))),
          ),
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(color: Color(0xFF202020), fontSize: 14, fontFamily: 'Pretendard-Bold')),
              if (subtitle != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(subtitle, style: const TextStyle(color: Color(0xFF999999), fontSize: 10, fontFamily: 'Pretendard-Light', letterSpacing: -0.28))),
            ]),
          ),
          Container(margin: const EdgeInsets.only(top: 20), child: content),
        ],
      ),
    );
  }

  Widget _buildGoalTypeCards() {
     return Column(
      children: [
        GestureDetector(
          onTap: () => setState(() => _selectedGoalType = '학습 인증'),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: ShapeDecoration(
              color: _selectedGoalType == '학습 인증' ? const Color(0xFFFFD27F) : const Color(0xFFDFE4F1),
              shape: RoundedRectangleBorder(side: BorderSide(width: 0.7, color: _selectedGoalType == '학습 인증' ? const Color(0xFFFFA63D) : const Color(0xFFDADADA)), borderRadius: BorderRadius.circular(12)),
            ),
            child: Stack(children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                Text('학습 인증', style: TextStyle(color: Color(0xFF202020), fontSize: 14, fontFamily: 'Pretendard-Bold', letterSpacing: -0.32)),
                SizedBox(height: 8),
                Text('이번 주 주말 3시간 공부 도전, 매일 아침 영어 리스닝', style: TextStyle(color: Color(0xFF666666), fontSize: 10, fontFamily: 'Pretendard-Light', letterSpacing: -0.24)),
              ]),
              Positioned(right: 0, top: 10.5, child: _buildRadioIndicator(_selectedGoalType == '학습 인증')),
            ]),
          ),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () => setState(() => _selectedGoalType = '습관 형성'), // API에 맞는 값으로 변경
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: ShapeDecoration(
              color: _selectedGoalType == '습관 형성' ? const Color(0xFFFFD27F) : const Color(0xFFDFE4F1),
              shape: RoundedRectangleBorder(side: BorderSide(width: 0.7, color: _selectedGoalType == '습관 형성' ? const Color(0xFFFFA63D) : const Color(0xFFDADADA)), borderRadius: BorderRadius.circular(12)),
            ),
            child: Stack(children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                Text('성실한 습관 형성을 원해요', style: TextStyle(color: Color(0xFF202020), fontSize: 14, fontFamily: 'Pretendard-Bold', letterSpacing: -0.32)),
                SizedBox(height: 8),
                Text('이번 주 설거지 담당, 강아지 산책 담당', style: TextStyle(color: Color(0xFF999999), fontSize: 10, fontFamily: 'Pretendard-Light', letterSpacing: -0.24)),
              ]),
              Positioned(right: 0, top: 10.5, child: _buildRadioIndicator(_selectedGoalType == '습관 형성')),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildRadioIndicator(bool isSelected) {
    return Container(
      width: 20, height: 20,
      decoration: ShapeDecoration(
        color: isSelected ? const Color(0xFFFFD27F) : Colors.white,
        shape: OvalBorder(side: BorderSide(width: 0.75, color: isSelected ? const Color(0xFFFFA63D) : const Color(0xFFDADADA))),
      ),
      child: isSelected ? Center(child: Container(width: 12, height: 12, decoration: ShapeDecoration(color: Color(0xFFFFA63D), shape: OvalBorder()))) : null,
    );
  }

  Widget _buildTitleInput() {
    return Container(
      width: double.infinity, height: 40,
      decoration: ShapeDecoration(color: const Color(0xFFEFF2F6), shape: RoundedRectangleBorder(side: const BorderSide(width: 1.4, color: Color(0xFF5D9EFF)), borderRadius: BorderRadius.circular(24))),
      padding: const EdgeInsets.only(left: 16, right: 8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Expanded(child: Container(height: 40, alignment: Alignment.center, child: TextField(
          controller: _goalTitleController,
          decoration: const InputDecoration(hintText: 'ex)이번 주 저녁 설거지 담당', hintStyle: TextStyle(color: Color(0xFF666666), fontSize: 12, fontFamily: 'Pretendard-Medium', letterSpacing: -0.28), border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none, disabledBorder: InputBorder.none, errorBorder: InputBorder.none, focusedErrorBorder: InputBorder.none, contentPadding: EdgeInsets.zero, filled: true, fillColor: Color(0xFFEFF2F6), isDense: true),
          textAlignVertical: TextAlignVertical.center, style: const TextStyle(color: Color(0xFF666666), fontSize: 12, fontFamily: 'Pretendard-Medium', letterSpacing: -0.28),
          onChanged: (value) => setState(() {}),
        ))),
        if (_goalTitleController.text.isNotEmpty) GestureDetector(onTap: () => setState(() => _goalTitleController.clear()), child: const Icon(Icons.close, size: 20, color: Color(0xFF666666))),
      ]),
    );
  }
  
  Widget _buildDateSelection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Text('주간 선택', style: TextStyle(color: Color(0xFF202020), fontSize: 14, fontFamily: 'Pretendard-Bold', letterSpacing: -0.32)),
        const SizedBox(width: 12),
        Text(_selectedDates.isEmpty ? '월요일을 선택해주세요' : '${_selectedDates.first.month}/${_selectedDates.first.day} ~ ${_selectedDates.last.month}/${_selectedDates.last.day} (7일)', style: TextStyle(color: _selectedDates.isEmpty ? Color(0xFF999999) : Color(0xFF5D9EFF), fontSize: 12, fontFamily: 'Pretendard-Regular')),
        const Spacer(),
        IconButton(icon: Icon(_isCalendarExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: Colors.black, size: 20), onPressed: () => setState(() => _isCalendarExpanded = !_isCalendarExpanded)),
      ]),
      if (_isCalendarExpanded) _buildCalendarGrid(),
    ]);
  }

  Widget _buildCalendarGrid() {
    return Column(children: [
      const SizedBox(height: 16),
      Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: const [Text('일', style: TextStyle(color: Color(0xFFFF6062), fontSize: 14, fontFamily: 'Pretendard-Regular')), Text('월', style: TextStyle(color: Color(0xFF5C6B7F), fontSize: 14, fontFamily: 'Pretendard-Regular')), Text('화', style: TextStyle(color: Color(0xFF5C6B7F), fontSize: 14, fontFamily: 'Pretendard-Regular')), Text('수', style: TextStyle(color: Color(0xFF5C6B7F), fontSize: 14, fontFamily: 'Pretendard-Regular')), Text('목', style: TextStyle(color: Color(0xFF5C6B7F), fontSize: 14, fontFamily: 'Pretendard-Regular')), Text('금', style: TextStyle(color: Color(0xFF5C6B7F), fontSize: 14, fontFamily: 'Pretendard-Regular')), Text('토', style: TextStyle(color: Color(0xFF5C6B7F), fontSize: 14, fontFamily: 'Pretendard-Regular'))]),
      const Divider(color: Color(0xFF8490A3), height: 20, thickness: 0.4),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        IconButton(icon: const Icon(Icons.chevron_left, color: Color(0xFF666666)), onPressed: () => setState(() { _selectedCalendarMonth = DateTime(_selectedCalendarMonth.year, _selectedCalendarMonth.month - 1, 1); _selectedDates.clear(); })),
        Text('${_selectedCalendarMonth.year}년 ${_selectedCalendarMonth.month}월', style: const TextStyle(color: Color(0xFF666666), fontSize: 12, fontFamily: 'Pretendard-Light', letterSpacing: -0.24)),
        IconButton(icon: const Icon(Icons.chevron_right, color: Color(0xFF666666)), onPressed: () => setState(() { _selectedCalendarMonth = DateTime(_selectedCalendarMonth.year, _selectedCalendarMonth.month + 1, 1); _selectedDates.clear(); })),
      ]),
      _buildMonthCalendar(),
    ]);
  }

  Widget _buildMonthCalendar() {
    final firstDayOfMonth = DateTime(_selectedCalendarMonth.year, _selectedCalendarMonth.month, 1);
    final lastDayOfMonth = DateTime(_selectedCalendarMonth.year, _selectedCalendarMonth.month + 1, 0);
    final firstWeekday = firstDayOfMonth.weekday == 7 ? 0 : firstDayOfMonth.weekday;
    final daysInMonth = lastDayOfMonth.day;
    final prevMonth = DateTime(_selectedCalendarMonth.year, _selectedCalendarMonth.month - 1, 0);
    final prevMonthDays = prevMonth.day;
    List<Widget> calendarDays = [];
    for (int i = firstWeekday - 1; i >= 0; i--) calendarDays.add(_buildCalendarDay((prevMonthDays - i).toString(), false, true, DateTime(_selectedCalendarMonth.year, _selectedCalendarMonth.month - 1, prevMonthDays - i)));
    for (int day = 1; day <= daysInMonth; day++) calendarDays.add(_buildCalendarDay(day.toString(), true, false, DateTime(_selectedCalendarMonth.year, _selectedCalendarMonth.month, day)));
    final remainingDays = 42 - calendarDays.length;
    for (int day = 1; day <= remainingDays; day++) calendarDays.add(_buildCalendarDay(day.toString(), false, false, DateTime(_selectedCalendarMonth.year, _selectedCalendarMonth.month + 1, day)));
    return GridView.count(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisCount: 7, childAspectRatio: 1.0, crossAxisSpacing: 4, mainAxisSpacing: 4, children: calendarDays);
  }

  Widget _buildCalendarDay(String day, bool isCurrentMonth, bool isPrevMonth, DateTime actualDate) {
    final isMonday = _isMonday(actualDate);
    final isInSelectedWeek = _isDateInSelectedWeek(actualDate);
    final today = DateTime.now();
    final isToday = actualDate.year == today.year && actualDate.month == today.month && actualDate.day == today.day;
    return GestureDetector(
      onTap: isMonday ? () => _selectWeekFromMonday(actualDate) : null,
      child: Container(
        width: 32, height: 32,
        decoration: isInSelectedWeek ? ShapeDecoration(color: isMonday ? const Color(0xFF146AFF) : const Color(0xFFE3F2FD), shape: OvalBorder(side: BorderSide(width: 1, color: isMonday ? const Color(0xFF5D9EFF) : const Color(0xFFBBDEFB)))) : isToday ? const ShapeDecoration(color: Color(0xFFFFD27F), shape: OvalBorder()) : null,
        child: Center(child: Text(day, style: TextStyle(color: isInSelectedWeek ? (isMonday ? Colors.white : const Color(0xFF146AFF)) : isToday ? const Color(0xFF001F55) : isCurrentMonth ? const Color(0xFF5C6B7F) : const Color(0xFFB6B6B6), fontSize: 12, fontFamily: isInSelectedWeek || isToday ? 'Pretendard-SemiBold' : 'Pretendard-Regular', height: 1.75))),
      ),
    );
  }
  
  Widget _buildRewardInput() {
     return Container(
      width: double.infinity, height: 40,
      decoration: ShapeDecoration(color: const Color(0xFFEFF2F6), shape: RoundedRectangleBorder(side: const BorderSide(width: 1.4, color: Color(0xFF5D9EFF)), borderRadius: BorderRadius.circular(24))),
      padding: const EdgeInsets.only(left: 16, right: 8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Expanded(child: Container(height: 40, alignment: Alignment.center, child: TextField(
          controller: _rewardAmountController,
          decoration: const InputDecoration(hintText: '30,000원', hintStyle: TextStyle(color: Color(0xFF666666), fontSize: 12, fontFamily: 'Pretendard-Medium', letterSpacing: -0.28), border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none, disabledBorder: InputBorder.none, errorBorder: InputBorder.none, focusedErrorBorder: InputBorder.none, contentPadding: EdgeInsets.zero, filled: true, fillColor: Color(0xFFEFF2F6), isDense: true),
          textAlignVertical: TextAlignVertical.center, style: const TextStyle(color: Color(0xFF666666), fontSize: 12, fontFamily: 'Pretendard-Medium', letterSpacing: -0.28),
          onChanged: (value) => setState(() {}),
        ))),
        if (_rewardAmountController.text.isNotEmpty) GestureDetector(onTap: () => setState(() => _rewardAmountController.clear()), child: const Icon(Icons.close, size: 20, color: Color(0xFF666666))),
      ]),
    );
  }
} 