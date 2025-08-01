import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../../services/goal_service.dart';
import '../../services/family_service.dart';

class GoalSettingScreen extends StatefulWidget {
  final Map<String, dynamic>? initialGoal;
  const GoalSettingScreen({super.key, this.initialGoal});

  @override
  State<GoalSettingScreen> createState() => _GoalSettingScreenState();
}

class _GoalSettingScreenState extends State<GoalSettingScreen> {
  String _selectedGoalType = '학습 인증';
  String _goalTitle = '';
  DateTime _selectedDate = DateTime.now();
  String _rewardAmount = '';
  final List<DateTime> _selectedDates = []; // DateTime 객체로 변경
  bool _isLoading = false; // 로딩 상태
  bool _isCalendarExpanded = true; // 달력 확장 상태

  final TextEditingController _goalTitleController = TextEditingController();
  final TextEditingController _rewardAmountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    initializeDateFormatting();

    // 초기값 설정
    if (widget.initialGoal != null) {
      _selectedGoalType = widget.initialGoal!['type'] as String? ?? '학습 인증';
      _goalTitle = widget.initialGoal!['title'] as String? ?? '';
      _rewardAmount = widget.initialGoal!['reward'] as String? ?? '';

      if (widget.initialGoal!['startDate'] != null) {
        _selectedDate = widget.initialGoal!['startDate'] as DateTime;
      }
    }

    _goalTitleController.text = _goalTitle;
    _rewardAmountController.text = _rewardAmount;
  }

  @override
  void dispose() {
    _goalTitleController.dispose();
    _rewardAmountController.dispose();
    super.dispose();
  }

  // 선택한 날짜부터 해당 주의 일요일까지의 날짜를 선택하는 로직
  void _selectDaysUntilSunday(DateTime selectedDate) {
    setState(() {
      _selectedDates.clear();

      // 선택된 날짜부터 시작
      DateTime currentDate = selectedDate;

      // 선택된 날짜를 추가
      _selectedDates.add(currentDate);

      // 해당 주의 일요일까지 날짜 추가
      while (currentDate.weekday != DateTime.sunday) {
        currentDate = currentDate.add(const Duration(days: 1));
        _selectedDates.add(currentDate);
      }

      // 날짜를 오름차순으로 정렬
      _selectedDates.sort((a, b) => a.compareTo(b));
    });
  }

  // 날짜가 선택된 날짜들에 포함되는지 확인
  bool _isDateSelected(DateTime date) {
    return _selectedDates.any(
      (selectedDate) =>
          selectedDate.year == date.year &&
          selectedDate.month == date.month &&
          selectedDate.day == date.day,
    );
  }

  // 목표 신청 처리
  Future<void> _submitGoal() async {
    // 유효성 검사
    if (_goalTitleController.text.trim().isEmpty) {
      _showErrorDialog('목표 제목을 입력해주세요.');
      return;
    }

    if (_selectedDates.isEmpty) {
      _showErrorDialog('목표를 수행할 날짜를 선택해주세요.');
      return;
    }

    if (_rewardAmountController.text.trim().isEmpty) {
      _showErrorDialog('보상금을 입력해주세요.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final familyInfo = await FamilyService.getFamilyInfo();
      if (familyInfo == null || familyInfo['familyId'] == null) {
        _showErrorDialog('가족 정보를 불러올 수 없습니다. 가족에 먼저 가입해주세요.');
        if (mounted) setState(() => _isLoading = false);
        return;
      }
      final int familyId = familyInfo['familyId'];

      // 선택된 날짜들 정렬
      _selectedDates.sort((a, b) => a.compareTo(b));

      // startDate는 선택된 첫 날짜의 시작 (00:00:00)
      DateTime startDate = _selectedDates.first;
      startDate = DateTime(startDate.year, startDate.month, startDate.day);

      // endDate는 선택된 마지막 날짜의 끝 (23:59:59)
      DateTime endDate = _selectedDates.last;
      endDate = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);

      final category = GoalService.convertGoalTypeToCategory(_selectedGoalType);
      final rewardAmount = GoalService.parseRewardAmount(
        _rewardAmountController.text,
      );

      print('목표 신청 API 호출 준비:');
      print('  title: ${_goalTitleController.text.trim()}');
      print('  category: $category');
      print('  reward: $rewardAmount');
      print('  startDate: ${startDate.toIso8601String()}');
      print('  endDate: ${endDate.toIso8601String()}');
      print('  familyId: $familyId');

      final result = await GoalService.applyGoal(
        title: _goalTitleController.text.trim(),
        category: category,
        reward: rewardAmount,
        startDate: startDate,
        endDate: endDate,
        familyId: familyId,
      );

      if (result['success'] == true) {
        // 성공 시 모달 표시
        await _showSuccessDialog('목표가 성공적으로 신청되었습니다!');

        // 모달이 닫힌 후에 결과 반환하고 화면 닫기
        if (mounted) {
          Navigator.pop(context, {
            'title': _goalTitleController.text.trim(),
            'type': _selectedGoalType,
            'reward': _rewardAmountController.text,
            'startDate': startDate,
            'endDate': endDate,
            'goalId': result['data']['goalId'],
            'status': result['data']['status'],
          });
        }
      }
    } catch (e) {
      _showErrorDialog(e.toString().replaceAll('Exception: ', ''));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 에러 다이얼로그 표시
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            '오류',
            style: TextStyle(fontFamily: 'Pretendard-Bold', fontSize: 16),
          ),
          content: Text(
            message,
            style: const TextStyle(
              fontFamily: 'Pretendard-Regular',
              fontSize: 14,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                '확인',
                style: TextStyle(
                  fontFamily: 'Pretendard-Medium',
                  color: Color(0xFF5D9EFF),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // 성공 다이얼로그 표시
  Future<void> _showSuccessDialog(String message) async {
    return showDialog(
      context: context,
      barrierDismissible: false, // 바깥 영역 터치로 닫히지 않도록 설정
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Text(
            '성공',
            style: TextStyle(
              color: Color(0xFF202020),
              fontSize: 16,
              fontFamily: 'Pretendard-Bold',
            ),
          ),
          content: Text(
            message,
            style: const TextStyle(
              color: Color(0xFF666666),
              fontSize: 14,
              fontFamily: 'Pretendard-Regular',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                '확인',
                style: TextStyle(
                  color: Color(0xFF5D9EFF),
                  fontSize: 14,
                  fontFamily: 'Pretendard-Medium',
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFF2F6),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          '목표 설정하기',
          style: TextStyle(
            color: Color(0xFF202020),
            fontSize: 14,
            fontFamily: 'Pretendard-Bold',
            letterSpacing: -0.32,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Image.asset('assets/icons/my/뒤로가기.png', width: 24, height: 24),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Container(
          width: MediaQuery.of(context).size.width,
          clipBehavior: Clip.antiAlias,
          decoration: const BoxDecoration(color: Color(0xFFEFF2F6)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),

              // 1. 원하는 목표 유형 섹션
              _buildSection(
                number: '1',
                title: '원하는 목표 유형을 알려주세요',
                subtitle: '한 번에 하나만 선택할 수 있어요!',
                content: _buildGoalTypeCards(),
              ),

              // 2. 어떤 제목의 목표 섹션
              _buildSection(
                number: '2',
                title: '어떤 제목의 목표를 설정해 볼까요?',
                subtitle: '부모님과 나의 목표에 노출돼요!',
                content: _buildTitleInput(),
              ),

              // 3. 원하는 기간 선택 섹션
              _buildSection(
                number: '3',
                title: '원하는 기간을 선택해 주세요',
                subtitle: '목표 시작 날짜를 선택해 주세요!',
                content: _buildDateSelection(),
              ),

              // 4. 원하는 보상금 입력 섹션
              _buildSection(
                number: '4',
                title: '원하는 보상금을 입력해 주세요',
                subtitle: '부모님에게 원하는 보상금을 대신 전해드릴게요!',
                content: _buildRewardInput(),
              ),

              // 신청 버튼
              GestureDetector(
                onTap: _isLoading ? null : _submitGoal,
                child: Container(
                  width: MediaQuery.of(context).size.width - 32,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 16,
                  ),
                  margin: const EdgeInsets.only(bottom: 30, top: 20),
                  decoration: ShapeDecoration(
                    color:
                        _isLoading
                            ? const Color(0xFF146AFF).withOpacity(0.6)
                            : const Color(0xFF146AFF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Center(
                    child:
                        _isLoading
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                            : const Text(
                              '이대로 신청하기',
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

  // 섹션 위젯 (번호, 제목, 부제목, 내용)
  Widget _buildSection({
    required String number,
    required String title,
    String? subtitle,
    required Widget content,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      margin: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 번호와 원
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

          // 제목 및 부제목
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF202020),
                    fontSize: 14,
                    fontFamily: 'Pretendard-Bold',
                  ),
                ),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF999999),
                        fontSize: 10,
                        fontFamily: 'Pretendard-Light',
                        letterSpacing: -0.28,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // 내용
          Container(margin: const EdgeInsets.only(top: 20), child: content),
        ],
      ),
    );
  }

  // 1. 목표 유형 선택 카드들
  Widget _buildGoalTypeCards() {
    return Column(
      children: [
        // 학습 인증 카드
        GestureDetector(
          onTap: () {
            setState(() {
              _selectedGoalType = '학습 인증';
            });
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: ShapeDecoration(
              color:
                  _selectedGoalType == '학습 인증'
                      ? const Color(0xFFFFD27F)
                      : const Color(0xFFDFE4F1),
              shape: RoundedRectangleBorder(
                side: BorderSide(
                  width: 0.7,
                  color:
                      _selectedGoalType == '학습 인증'
                          ? const Color(0xFFFFA63D)
                          : const Color(0xFFDADADA),
                ),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '학습 인증',
                      style: TextStyle(
                        color: Color(0xFF202020),
                        fontSize: 14,
                        fontFamily: 'Pretendard-Bold',
                        letterSpacing: -0.32,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '이번 주 주말 3시간 공부 도전, 매일 아침 영어 리스닝',
                      style: TextStyle(
                        color: Color(0xFF666666),
                        fontSize: 10,
                        fontFamily: 'Pretendard-Light',
                        letterSpacing: -0.24,
                      ),
                    ),
                  ],
                ),
                Positioned(
                  right: 0,
                  top: 10.5,
                  child:
                      _selectedGoalType == '학습 인증'
                          ? Container(
                            width: 20,
                            height: 20,
                            decoration: ShapeDecoration(
                              color: const Color(0xFFFFD27F),
                              shape: OvalBorder(
                                side: const BorderSide(
                                  width: 0.75,
                                  color: Color(0xFFFFA63D),
                                ),
                              ),
                            ),
                            child: Center(
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: ShapeDecoration(
                                  color: Color(0xFFFFA63D),
                                  shape: OvalBorder(),
                                ),
                              ),
                            ),
                          )
                          : Container(
                            width: 20,
                            height: 20,
                            decoration: ShapeDecoration(
                              color: Colors.white,
                              shape: OvalBorder(
                                side: const BorderSide(
                                  width: 0.75,
                                  color: Color(0xFFDADADA),
                                ),
                              ),
                            ),
                          ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // 습관 형성 카드
        GestureDetector(
          onTap: () {
            setState(() {
              _selectedGoalType = '성실한 습관 형성을 원해요';
            });
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: ShapeDecoration(
              color:
                  _selectedGoalType == '성실한 습관 형성을 원해요'
                      ? const Color(0xFFFFD27F)
                      : const Color(0xFFDFE4F1),
              shape: RoundedRectangleBorder(
                side: BorderSide(
                  width: 0.7,
                  color:
                      _selectedGoalType == '성실한 습관 형성을 원해요'
                          ? const Color(0xFFFFA63D)
                          : const Color(0xFFDADADA),
                ),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '성실한 습관 형성을 원해요',
                      style: TextStyle(
                        color: Color(0xFF202020),
                        fontSize: 14,
                        fontFamily: 'Pretendard-Bold',
                        letterSpacing: -0.32,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '이번 주 설거지 담당, 강아지 산책 담당',
                      style: TextStyle(
                        color: Color(0xFF999999),
                        fontSize: 10,
                        fontFamily: 'Pretendard-Light',
                        letterSpacing: -0.24,
                      ),
                    ),
                  ],
                ),
                Positioned(
                  right: 0,
                  top: 10.5,
                  child:
                      _selectedGoalType == '성실한 습관 형성을 원해요'
                          ? Container(
                            width: 20,
                            height: 20,
                            decoration: ShapeDecoration(
                              color: const Color(0xFFFFD27F),
                              shape: OvalBorder(
                                side: const BorderSide(
                                  width: 0.75,
                                  color: Color(0xFFFFA63D),
                                ),
                              ),
                            ),
                            child: Center(
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: ShapeDecoration(
                                  color: Color(0xFFFFA63D),
                                  shape: OvalBorder(),
                                ),
                              ),
                            ),
                          )
                          : Container(
                            width: 20,
                            height: 20,
                            decoration: ShapeDecoration(
                              color: Colors.white,
                              shape: OvalBorder(
                                side: const BorderSide(
                                  width: 0.75,
                                  color: Color(0xFFDADADA),
                                ),
                              ),
                            ),
                          ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 목표 유형에 따른 플레이스홀더 텍스트 반환
  String _getPlaceholderText() {
    switch (_selectedGoalType) {
      case '학습 인증':
        return 'ex) 매일 1시간 영어 공부하기';
      case '성실한 습관 형성을 원해요':
        return 'ex) 이번 주 저녁 설거지 담당';
      default:
        return 'ex) 목표 제목을 입력해주세요';
    }
  }

  // 2. 목표 제목 입력
  Widget _buildTitleInput() {
    return Container(
      width: double.infinity,
      height: 40,
      decoration: ShapeDecoration(
        color: const Color(0xFFEFF2F6),
        shape: RoundedRectangleBorder(
          side: const BorderSide(width: 1.4, color: Color(0xFF5D9EFF)),
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      padding: const EdgeInsets.only(left: 16, right: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Container(
              height: 40,
              alignment: Alignment.center,
              child: TextField(
                controller: _goalTitleController,
                decoration: InputDecoration(
                  hintText: _getPlaceholderText(),
                  hintStyle: const TextStyle(
                    color: Color(0xFF666666),
                    fontSize: 12,
                    fontFamily: 'Pretendard-Medium',
                    letterSpacing: -0.28,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  filled: true,
                  fillColor: Color(0xFFEFF2F6),
                  isDense: true,
                ),
                textAlignVertical: TextAlignVertical.center,
                style: const TextStyle(
                  color: Color(0xFF666666),
                  fontSize: 12,
                  fontFamily: 'Pretendard-Medium',
                  letterSpacing: -0.28,
                ),
                onChanged: (value) {
                  setState(() {});
                },
              ),
            ),
          ),
          if (_goalTitleController.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                setState(() {
                  _goalTitleController.clear();
                });
              },
              child: const Icon(
                Icons.close,
                size: 20,
                color: Color(0xFF666666),
              ),
            ),
        ],
      ),
    );
  }

  // 3. 날짜 선택
  Widget _buildDateSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 날짜 선택 헤더
        Row(
          children: [
            const Text(
              '주간 선택',
              style: TextStyle(
                color: Color(0xFF202020),
                fontSize: 14,
                fontFamily: 'Pretendard-Bold',
                letterSpacing: -0.32,
              ),
            ),
            const SizedBox(width: 12),
            if (_selectedDates.isNotEmpty)
              Text(
                '${_selectedDates.first.month}/${_selectedDates.first.day} ~ ${_selectedDates.last.month}/${_selectedDates.last.day} (7일)',
                style: TextStyle(
                  color: Color(0xFF5D9EFF),
                  fontSize: 12,
                  fontFamily: 'Pretendard-Regular',
                ),
              ),
            const Spacer(),
            IconButton(
              icon: Icon(
                _isCalendarExpanded
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
                color: Colors.black,
                size: 20,
              ),
              onPressed: () {
                setState(() {
                  _isCalendarExpanded = !_isCalendarExpanded;
                });
              },
            ),
          ],
        ),

        if (_isCalendarExpanded) _buildCalendarGrid(),
      ],
    );
  }

  // 달력 그리드
  Widget _buildCalendarGrid() {
    return Column(
      children: [
        const SizedBox(height: 16),

        // 달력 요일 헤더
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: const [
            Text(
              '일',
              style: TextStyle(
                color: Color(0xFFFF6062),
                fontSize: 14,
                fontFamily: 'Pretendard-Regular',
              ),
            ),
            Text(
              '월',
              style: TextStyle(
                color: Color(0xFF5C6B7F),
                fontSize: 14,
                fontFamily: 'Pretendard-Regular',
              ),
            ),
            Text(
              '화',
              style: TextStyle(
                color: Color(0xFF5C6B7F),
                fontSize: 14,
                fontFamily: 'Pretendard-Regular',
              ),
            ),
            Text(
              '수',
              style: TextStyle(
                color: Color(0xFF5C6B7F),
                fontSize: 14,
                fontFamily: 'Pretendard-Regular',
              ),
            ),
            Text(
              '목',
              style: TextStyle(
                color: Color(0xFF5C6B7F),
                fontSize: 14,
                fontFamily: 'Pretendard-Regular',
              ),
            ),
            Text(
              '금',
              style: TextStyle(
                color: Color(0xFF5C6B7F),
                fontSize: 14,
                fontFamily: 'Pretendard-Regular',
              ),
            ),
            Text(
              '토',
              style: TextStyle(
                color: Color(0xFF5C6B7F),
                fontSize: 14,
                fontFamily: 'Pretendard-Regular',
              ),
            ),
          ],
        ),

        const Divider(color: Color(0xFF8490A3), height: 20, thickness: 0.4),

        // 월 네비게이션
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left, color: Color(0xFF666666)),
              onPressed: () {
                setState(() {
                  _selectedDate = DateTime(
                    _selectedDate.year,
                    _selectedDate.month - 1,
                    1,
                  );
                  _selectedDates.clear(); // 월이 바뀌면 선택된 날짜 초기화
                });
              },
            ),
            Text(
              '${_selectedDate.year}년 ${_selectedDate.month}월',
              style: const TextStyle(
                color: Color(0xFF666666),
                fontSize: 12,
                fontFamily: 'Pretendard-Light',
                letterSpacing: -0.24,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right, color: Color(0xFF666666)),
              onPressed: () {
                setState(() {
                  _selectedDate = DateTime(
                    _selectedDate.year,
                    _selectedDate.month + 1,
                    1,
                  );
                  _selectedDates.clear(); // 월이 바뀌면 선택된 날짜 초기화
                });
              },
            ),
          ],
        ),

        // 달력 그리드
        _buildMonthCalendar(),
      ],
    );
  }

  // 월별 달력 생성
  Widget _buildMonthCalendar() {
    final firstDayOfMonth = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      1,
    );
    final lastDayOfMonth = DateTime(
      _selectedDate.year,
      _selectedDate.month + 1,
      0,
    );

    // DateTime.weekday: 월요일=1, 화요일=2, ..., 일요일=7
    // 우리가 원하는 형태: 일요일=0, 월요일=1, ..., 토요일=6
    final firstWeekday =
        firstDayOfMonth.weekday == 7 ? 0 : firstDayOfMonth.weekday;
    final daysInMonth = lastDayOfMonth.day;

    // 이전 달의 마지막 날들
    final prevMonth = DateTime(_selectedDate.year, _selectedDate.month - 1, 0);
    final prevMonthDays = prevMonth.day;

    List<Widget> calendarDays = [];

    // 이전 달의 날짜들 (회색으로 표시)
    for (int i = firstWeekday - 1; i >= 0; i--) {
      final day = prevMonthDays - i;
      final prevMonthDate = DateTime(
        _selectedDate.year,
        _selectedDate.month - 1,
        day,
      );
      calendarDays.add(
        _buildCalendarDay(day.toString(), false, true, prevMonthDate),
      );
    }

    // 현재 달의 날짜들
    for (int day = 1; day <= daysInMonth; day++) {
      final currentDate = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        day,
      );
      calendarDays.add(
        _buildCalendarDay(day.toString(), true, false, currentDate),
      );
    }

    // 다음 달의 날짜들 (6주 완성을 위해)
    final remainingDays = 42 - calendarDays.length; // 6주 * 7일 = 42일
    for (int day = 1; day <= remainingDays; day++) {
      final nextMonthDate = DateTime(
        _selectedDate.year,
        _selectedDate.month + 1,
        day,
      );
      calendarDays.add(
        _buildCalendarDay(day.toString(), false, false, nextMonthDate),
      );
    }

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 7,
      childAspectRatio: 1.0,
      crossAxisSpacing: 4,
      mainAxisSpacing: 4,
      children: calendarDays,
    );
  }

  // 개별 달력 날짜 위젯
  Widget _buildCalendarDay(
    String day,
    bool isCurrentMonth,
    bool isPrevMonth,
    DateTime actualDate,
  ) {
    final isSelected = _isDateSelected(actualDate);
    final today = DateTime.now();
    final isToday =
        actualDate.year == today.year &&
        actualDate.month == today.month &&
        actualDate.day == today.day;

    return GestureDetector(
      onTap: () {
        _selectDaysUntilSunday(actualDate);
      },
      child: Container(
        width: 32,
        height: 32,
        decoration:
            isSelected
                ? ShapeDecoration(
                  color:
                      _selectedDates.first.year == actualDate.year &&
                              _selectedDates.first.month == actualDate.month &&
                              _selectedDates.first.day == actualDate.day
                          ? const Color(0xFF146AFF)
                          : const Color(0xFFE3F2FD),
                  shape: OvalBorder(
                    side: BorderSide(
                      width: 1,
                      color:
                          _selectedDates.first.year == actualDate.year &&
                                  _selectedDates.first.month ==
                                      actualDate.month &&
                                  _selectedDates.first.day == actualDate.day
                              ? const Color(0xFF5D9EFF)
                              : const Color(0xFFBBDEFB),
                    ),
                  ),
                )
                : isToday
                ? const ShapeDecoration(
                  color: Color(0xFFFFD27F),
                  shape: OvalBorder(),
                )
                : null,
        child: Center(
          child: Text(
            day,
            style: TextStyle(
              color:
                  isSelected
                      ? (_selectedDates.first.year == actualDate.year &&
                              _selectedDates.first.month == actualDate.month &&
                              _selectedDates.first.day == actualDate.day
                          ? Colors.white
                          : const Color(0xFF146AFF))
                      : isToday
                      ? const Color(0xFF001F55)
                      : isCurrentMonth
                      ? const Color(0xFF5C6B7F)
                      : const Color(0xFFB6B6B6),
              fontSize: 12,
              fontFamily:
                  isSelected || isToday
                      ? 'Pretendard-SemiBold'
                      : 'Pretendard-Regular',
              height: 1.75,
            ),
          ),
        ),
      ),
    );
  }

  // 4. 보상금 입력
  Widget _buildRewardInput() {
    return Container(
      width: double.infinity,
      height: 40,
      decoration: ShapeDecoration(
        color: const Color(0xFFEFF2F6),
        shape: RoundedRectangleBorder(
          side: const BorderSide(width: 1.4, color: Color(0xFF5D9EFF)),
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      padding: const EdgeInsets.only(left: 16, right: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Container(
              height: 40,
              alignment: Alignment.center,
              child: TextField(
                controller: _rewardAmountController,
                decoration: const InputDecoration(
                  hintText: 'ex) 받고싶은 보상금을 입력해주세요.',
                  hintStyle: TextStyle(
                    color: Color(0xFF666666),
                    fontSize: 12,
                    fontFamily: 'Pretendard-Medium',
                    letterSpacing: -0.28,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  filled: true,
                  fillColor: Color(0xFFEFF2F6),
                  isDense: true,
                ),
                textAlignVertical: TextAlignVertical.center,
                style: const TextStyle(
                  color: Color(0xFF666666),
                  fontSize: 12,
                  fontFamily: 'Pretendard-Medium',
                  letterSpacing: -0.28,
                ),
                onChanged: (value) {
                  setState(() {});
                },
              ),
            ),
          ),
          if (_rewardAmountController.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                setState(() {
                  _rewardAmountController.clear();
                });
              },
              child: const Icon(
                Icons.close,
                size: 20,
                color: Color(0xFF666666),
              ),
            ),
        ],
      ),
    );
  }
}
