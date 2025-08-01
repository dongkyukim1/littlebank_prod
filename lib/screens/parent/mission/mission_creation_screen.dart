import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart'; // initializeDateFormatting 때문에 필요
import '../../../services/mission_service.dart';
import '../../../services/family_service.dart';



// 미션 작성 화면 (별도의 라우트)
class MissionCreationScreen extends StatefulWidget {
  final List<Map<String, dynamic>> selectedChildrenData;
  final String missionType;
  final String? missionCategory;
  final String? missionSubject;

  const MissionCreationScreen({
    super.key,
    required this.selectedChildrenData,
    required this.missionType,
    this.missionCategory,
    this.missionSubject,
  });

  @override
  State<MissionCreationScreen> createState() => _MissionCreationScreenState();
}

class _MissionCreationScreenState extends State<MissionCreationScreen> {
  // 선택된 미션 유형 (영어, 영어 단어, 영어 리스닝 등)
  final TextEditingController _missionController = TextEditingController();
  final FocusNode _missionFocusNode = FocusNode();
  // 용돈 금액 컨트롤러
  final TextEditingController _allowanceController = TextEditingController();
  // 미션 설명
  String _missionDescription = '';
  // 미션 생성 중 여부
  bool _isCreatingMission = false;
  bool _isMissionFocused = false;

  // 최근 보상 내역 관련 변수 추가
  int? _recentReward;
  bool _isLoadingRecentReward = false;
  String? _recentSubjectText;

  DateTime _currentCalendarMonth =
      DateTime.now(); // 달력 표시 기준 월 (GoalSettingScreen의 _selectedDate 역할)
  List<DateTime> _selectedDates = []; // 선택된 날짜들 (GoalSettingScreen과 동일)

  // 검색어
  String _searchText = '';
  // 드롭다운 표시 여부
  bool _showDropdown = false;
  // 직접 작성 모드
  final bool _isCustomMode = false;

  // 미션 유형 목록 - 자동 완성용 추천 목록
  final List<String> _missionSuggestions = [
    // 일반적인 학습 활동
    '문제풀이',
    '복습',
    '예습',
    '과제',
    '정리',
    '암기',
    // 국어 관련
    '독서',
    '쓰기',
    '읽기',
    // 영어 관련
    '단어암기',
    '듣기',
    '말하기',
    '회화',
    // 수학 관련
    '연산',
    '계산',
    // 과학 관련
    '실험',
    '관찰',
    // 사회 관련
    '조사',
    '탐구',
  ];

  // 선택된 미션들을 저장하는 Set
  final Set<String> _selectedMissions = {};

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
    initializeDateFormatting(); // GoalSettingScreen처럼 초기화

    // 용돈 초기값 설정
    _allowanceController.text = '16,000원';

    _missionController.addListener(() {
      setState(() {
        _searchText = _missionController.text;
        _showDropdown = _searchText.isNotEmpty;
      });
    });

    // 미션 제목 포커스 리스너 추가
    _missionFocusNode.addListener(() {
      setState(() {
        _isMissionFocused = _missionFocusNode.hasFocus;
      });
    });

    // 초기 날짜 선택 없음 (사용자가 직접 선택하도록)
    _selectedDates.clear();

    // 실제 API 사용 (테스트 데이터 제거)

    // 최근 보상 내역 조회
    _loadRecentReward();
  }

  @override
  void dispose() {
    _missionController.dispose();
    _missionFocusNode.dispose();
    _allowanceController.dispose();
    super.dispose();
  }

  // 자유로운 날짜 선택 로직
  void _selectDate(DateTime date) {
    setState(() {
      if (_selectedDates.isEmpty) {
        // 첫 번째 날짜 선택 - 시작일
        _selectedDates.add(date);
      } else if (_selectedDates.length == 1) {
        // 두 번째 날짜 선택 - 종료일
        final startDate = _selectedDates.first;
        if (date.isBefore(startDate)) {
          // 선택한 날짜가 시작일보다 이전이면 시작일을 새로 선택한 날짜로 변경
          _selectedDates.clear();
          _selectedDates.add(date);
        } else {
          // 정상적으로 종료일 추가
          _selectedDates.add(date);
        }
      } else {
        // 이미 범위가 선택되어 있으면 새로 시작
        _selectedDates.clear();
        _selectedDates.add(date);
      }
    });
  }

  bool _isDateInSelectedRange(DateTime date) {
    if (_selectedDates.isEmpty) return false;
    if (_selectedDates.length == 1) {
      // 시작일만 선택된 경우
      return _isSameDay(date, _selectedDates.first);
    } else if (_selectedDates.length >= 2) {
      // 시작일과 종료일이 모두 선택된 경우
      final startDate = _selectedDates.first;
      final endDate = _selectedDates.last;
      return (date.isAfter(startDate.subtract(Duration(days: 1))) &&
          date.isBefore(endDate.add(Duration(days: 1))));
    }
    return false;
  }

  bool _isStartDate(DateTime date) {
    return _selectedDates.isNotEmpty && _isSameDay(date, _selectedDates.first);
  }

  bool _isEndDate(DateTime date) {
    return _selectedDates.length >= 2 && _isSameDay(date, _selectedDates.last);
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  // 날짜 범위 텍스트 (종료 날짜만 표시)
  String get _selectedDateRangeText {
    if (_selectedDates.isEmpty) {
      return '날짜를 선택해주세요';
    } else if (_selectedDates.length == 1) {
      final date = _selectedDates.first;
      final weekdays = ['일', '월', '화', '수', '목', '금', '토'];
      final weekday = weekdays[date.weekday % 7];
      return '${date.year}년 ${date.month}월 ${date.day}일($weekday)';
    } else {
      // 종료 날짜만 표시
      final endDate = _selectedDates.last;
      final weekdays = ['일', '월', '화', '수', '목', '금', '토'];
      final endWeekday = weekdays[endDate.weekday % 7];
      return '${endDate.year}년 ${endDate.month}월 ${endDate.day}일($endWeekday)';
    }
  }

  void _previousMonth() {
    setState(() {
      _currentCalendarMonth = DateTime(
        _currentCalendarMonth.year,
        _currentCalendarMonth.month - 1,
        1,
      );
    });
  }

  void _nextMonth() {
    setState(() {
      _currentCalendarMonth = DateTime(
        _currentCalendarMonth.year,
        _currentCalendarMonth.month + 1,
        1,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '미션 생성하기',
          style: TextStyle(
            color: const Color(0xFF202020),
            fontSize: 16,
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          icon: Image.asset(
            'assets/icons/parent/뒤로가기.png',
            width: 24,
            height: 24,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Image.asset(
              'assets/icons/parent/mission/취소하기.png',
              width: 24,
              height: 24,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ],
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
                        color: const Color(0xFFFFD27F),
                        shape: OvalBorder(),
                      ),
                      child: Center(
                        child: Text(
                          '1',
                          style: TextStyle(
                            color: const Color(0xFF001F55),
                            fontSize: 16,
                            fontFamily: 'Pretendard',
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.32,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 8),
                    // 타이틀
                    Text(
                      '미션 제목을 알려주세요',
                      style: TextStyle(
                        color: const Color(0xFF202020),
                        fontSize: 18,
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.72,
                      ),
                    ),
                    SizedBox(height: 4),
                    // 서브타이틀
                    Text(
                      '키워드 입력 시, 최근 전송한 미션이 자동으로 노출돼요',
                      style: TextStyle(
                        color: const Color(0xFF999999),
                        fontSize: 12,
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w300,
                        letterSpacing: -0.28,
                      ),
                    ),
                    SizedBox(height: 20),
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
                            width: (_isMissionFocused || _missionController.text.isNotEmpty) ? 1.40 : 1.40,
                            color:
                                (_isMissionFocused || _missionController.text.isNotEmpty)
                                    ? const Color(0xFF3A88F4) // 포커스 또는 입력 있으면 파란색
                                    : const Color(0xFFDADADA), // 그렇지 않으면 회색
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
                              focusNode: _missionFocusNode,
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: '제목을 입력해 주세요',
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

                    // 과목 선택에 따른 미션 추천 버튼들 (입력했을 때만 표시)
                    if (widget.missionSubject != null && _missionController.text.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 12.0),
                        child: _buildSubjectMissionSuggestions(),
                      ),

                    // 입력한 검색어에 따른 추천 미션 버튼들
                    if (_searchText.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
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

              SizedBox(height: 24), // 섹션 1과 2 사이 간격
              // 섹션 2: 기간 선택
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
                    Container(
                      width: 28,
                      height: 28,
                      decoration: ShapeDecoration(
                        color: const Color(0xFFFFD27F),
                        shape: OvalBorder(),
                      ),
                      child: Center(
                        child: Text(
                          '2',
                          style: TextStyle(
                            color: const Color(0xFF001F55),
                            fontSize: 16,
                            fontFamily: 'Pretendard',
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.32,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 8),
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
                    SizedBox(height: 4),
                    // 서브타이틀
                    Text(
                      '아이가 미션을 수행할 기간을 선택해 주세요',
                      style: TextStyle(
                        color: const Color(0xFF999999),
                        fontSize: 12,
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w300,
                        letterSpacing: -0.28,
                      ),
                    ),
                    SizedBox(height: 20),
                    _buildCalendarSection(), // 수정된 달력 섹션 호출
                  ],
                ),
              ),

              SizedBox(height: 40), // 섹션 2와 3 사이 간격
              // 섹션 3: 용돈 설정
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
                        color: const Color(0xFFFFD27F),
                        shape: OvalBorder(),
                      ),
                      child: Center(
                        child: Text(
                          '3',
                          style: TextStyle(
                            color: const Color(0xFF001F55),
                            fontSize: 16,
                            fontFamily: 'Pretendard',
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.32,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 8),
                    // 타이틀
                    Text(
                      '${widget.selectedChildrenData.isNotEmpty ? (widget.selectedChildrenData.first['nickname'] ?? widget.selectedChildrenData.first['realName'] ?? "리뱅") : "리뱅"}님에게 지급할 용돈을 알려주세요!',
                      style: TextStyle(
                        color: const Color(0xFF202020),
                        fontSize: 18,
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.72,
                      ),
                    ),
                    SizedBox(height: 4),
                    // 서브타이틀
                    Text(
                      '미션 입력 시, 지난 미션에서 지급한 용돈 금액대를 알려드려요',
                      style: TextStyle(
                        color: const Color(0xFF999999),
                        fontSize: 12,
                        fontFamily: 'Pretendard-Light',
                        letterSpacing: -0.28,
                      ),
                    ),
                    SizedBox(height: 20),
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
                                hintText: '보상금을 입력해 주세요!',
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
                    SizedBox(height: 8),
                  ],
                ),
              ),

              // 말풍선 조건 확인 (로그만)
              Builder(
                builder: (context) {
                  if (_recentReward != null && _recentReward! > 0) {
                    print('💰 말풍선 표시: $_recentReward원 ($_recentSubjectText)');
                  } else {
                    print('💰 말풍선 표시 안함: $_recentReward');
                  }
                  return const SizedBox.shrink();
                },
              ),
              
              // 간단한 말풍선 (조건부) - RenderBox 에러 방지
              if (_recentReward != null && _recentReward! > 0)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8490A3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _isLoadingRecentReward
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(
                              '로딩 중...',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        )
                      : Text(
                          '지난 ${_recentSubjectText ?? '미션'}에서는 ${_recentReward?.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}원을 지급했어요!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontFamily: 'Pretendard',
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                ),

              // 하단 버튼
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: _isCreatingMission ? null : _handleMissionCreate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3A88F4),
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child:
                      _isCreatingMission
                          ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              ),
                              SizedBox(width: 8),
                              Text(
                                '미션 생성중...',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontFamily: 'Pretendard-Medium',
                                ),
                              ),
                            ],
                          )
                          : Text(
                            '이대로 전송하기',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontFamily: 'Pretendard-Medium',
                            ),
                          ),
                ),
              ),

              // 안내 메시지
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  decoration: ShapeDecoration(
                    color: const Color(0xFFF1F1F1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Image.asset(
                            'assets/icons/parent/mission/inform.png',
                            width: 16,
                            height: 16,
                          ),
                          SizedBox(width: 8),
                          Text(
                            '다음에도 동일한 미션을 선택 시, 자동 기입됩니다',
                            style: TextStyle(
                              color: const Color(0xFF000000),
                              fontSize: 13,
                              fontFamily: 'Pretendard',
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.24,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
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
              ),

              // 하단 여백
              SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  // 달력 UI 빌드 함수 (challenge_detail_screen.dart 스타일로 개선)
  Widget _buildCalendarSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              '날짜 선택',
              style: TextStyle(
                color: Color(0xFF202020),
                fontSize: 14,
                fontFamily: 'Pretendard-Bold',
                letterSpacing: -0.32,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _selectedDateRangeText,
                style: TextStyle(
                  color:
                      _selectedDates.isEmpty
                          ? Color(0xFF999999)
                          : Color(0xFF5D9EFF),
                  fontSize: 12,
                  fontFamily: 'Pretendard-Regular',
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // 월 이동 컨트롤
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: _previousMonth,
              icon: Icon(
                Icons.arrow_back_ios,
                size: 18,
                color: Color(0xFF5C6B7F),
              ),
            ),
            Text(
              '${_currentCalendarMonth.year}년 ${_currentCalendarMonth.month}월',
              style: TextStyle(
                color: Color(0xFF202020),
                fontSize: 16,
                fontFamily: 'Pretendard-SemiBold',
              ),
            ),
            IconButton(
              onPressed: _nextMonth,
              icon: Icon(
                Icons.arrow_forward_ios,
                size: 18,
                color: Color(0xFF5C6B7F),
              ),
            ),
          ],
        ),

        const SizedBox(height: 4),

        // 요일 헤더 (가로선 추가)
        Container(
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(width: 0.5, color: Color(0xFFDDDDDD)),
              bottom: BorderSide(width: 0.5, color: Color(0xFFDDDDDD)),
            ),
          ),
          padding: EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildDayLabel('일', isRed: true),
              _buildDayLabel('월'),
              _buildDayLabel('화'),
              _buildDayLabel('수'),
              _buildDayLabel('목'),
              _buildDayLabel('금'),
              _buildDayLabel('토'),
            ],
          ),
        ),

        const SizedBox(height: 4),

        _buildMonthView(),
      ],
    );
  }

  Widget _buildDayLabel(String day, {bool isRed = false}) {
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

  Widget _buildMonthView() {
    final firstDayOfMonth = DateTime(
      _currentCalendarMonth.year,
      _currentCalendarMonth.month,
      1,
    );
    final lastDayOfMonth = DateTime(
      _currentCalendarMonth.year,
      _currentCalendarMonth.month + 1,
      0,
    );
    final firstWeekday =
        firstDayOfMonth.weekday == 7 ? 0 : firstDayOfMonth.weekday; // 일요일을 0으로
    final daysInMonth = lastDayOfMonth.day;
    final prevMonth = DateTime(
      _currentCalendarMonth.year,
      _currentCalendarMonth.month - 1,
      0,
    );
    final prevMonthDays = prevMonth.day;
    List<Widget> calendarDays = [];

    for (int i = firstWeekday - 1; i >= 0; i--) {
      final day = prevMonthDays - i;
      calendarDays.add(
        _buildCalendarDayCell(
          DateTime(
            _currentCalendarMonth.year,
            _currentCalendarMonth.month - 1,
            day,
          ),
          isCurrentMonth: false,
        ),
      );
    }
    for (int day = 1; day <= daysInMonth; day++) {
      calendarDays.add(
        _buildCalendarDayCell(
          DateTime(
            _currentCalendarMonth.year,
            _currentCalendarMonth.month,
            day,
          ),
        ),
      );
    }
    final remainingDays = 42 - calendarDays.length;
    for (int day = 1; day <= remainingDays; day++) {
      calendarDays.add(
        _buildCalendarDayCell(
          DateTime(
            _currentCalendarMonth.year,
            _currentCalendarMonth.month + 1,
            day,
          ),
          isCurrentMonth: false,
        ),
      );
    }
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 7,
      childAspectRatio: 1.0, // 셀 비율
      crossAxisSpacing: 4, // 좌우 간격
      mainAxisSpacing: 4, // 상하 간격
      children: calendarDays,
    );
  }

  Widget _buildCalendarDayCell(DateTime date, {bool isCurrentMonth = true}) {
    final isInSelectedRange = _isDateInSelectedRange(date);
    final isStartDate = _isStartDate(date);
    final isEndDate = _isEndDate(date);
    final today = DateTime.now();
    final isToday =
        date.year == today.year &&
        date.month == today.month &&
        date.day == today.day;

    Color textColor =
        isCurrentMonth ? const Color(0xFF5C6B7F) : const Color(0xFFB6B6B6);
    Color backgroundColor = Colors.transparent;
    BorderSide? borderSide;

    if (isStartDate || isEndDate) {
      backgroundColor = const Color(0xFF146AFF);
      textColor = Colors.white;
      borderSide = BorderSide(width: 1, color: const Color(0xFF5D9EFF));
    } else if (isInSelectedRange) {
      backgroundColor = const Color(0xFFE3F2FD);
      textColor = const Color(0xFF146AFF);
      borderSide = BorderSide(width: 1, color: const Color(0xFFBBDEFB));
    } else if (isToday && isCurrentMonth) {
      backgroundColor = const Color(0xFF146AFF);
      textColor = Colors.white;
    }

    return GestureDetector(
      onTap: isCurrentMonth ? () => _selectDate(date) : null,
      child: Container(
        width: 28,
        height: 28,
        decoration: ShapeDecoration(
          color: backgroundColor,
          shape: OvalBorder(side: borderSide ?? BorderSide.none),
        ),
        child: Center(
          child: Text(
            date.day.toString(),
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontFamily:
                  (isStartDate ||
                          isEndDate ||
                          isInSelectedRange ||
                          (isToday && isCurrentMonth))
                      ? 'Pretendard-SemiBold'
                      : 'Pretendard-Regular',
              height: 1.75,
            ),
          ),
        ),
      ),
    );
  }

  // 검색어에 따른 미션 버튼 목록 생성
  List<Widget> _getFilteredMissionButtons() {
    if (_searchText.isEmpty) return [];

    String searchLower = _searchText.toLowerCase();
    Map<String, List<String>> missionsByCategory = {
      '국어': ['독서', '일기', '한자', '문법'],
      '영어': ['단어', '리스닝', '회화', '문법'],
      '수학': ['연산', '도형', '문제집', '특강'],
      '과학': ['실험', '화학', '물리', '생물'],
      '기타': ['방 청소', '설거지', '운동', '식물 물주기'],
    };

    // 검색어와 정확히 일치하는 미션이 있는지 확인
    bool hasExactMatch = false;
    for (var missions in missionsByCategory.values) {
      if (missions.any((mission) => mission.toLowerCase() == searchLower)) {
        hasExactMatch = true;
        break;
      }
    }

    // 정확히 일치하는 미션이 있으면 추천 목록을 표시하지 않음
    if (hasExactMatch) {
      return [];
    }

    List<Widget> buttons = [];

    // 검색어와 일치하는 카테고리 찾기
    String categoryKey = '';
    for (var key in missionsByCategory.keys) {
      if (key.toLowerCase().contains(searchLower)) {
        categoryKey = key;
        break;
      }
    }

    if (categoryKey.isNotEmpty) {
      // 카테고리와 일치하면 해당 카테고리의 미션 추가
      for (var mission in missionsByCategory[categoryKey]!) {
        buttons.add(_buildMissionButton(mission));
      }
    } else {
      // 카테고리와 일치하지 않으면 검색어를 포함하는 모든 미션 추가
      missionsByCategory.forEach((category, missions) {
        for (var mission in missions) {
          if (mission.toLowerCase().contains(searchLower)) {
            buttons.add(_buildMissionButton(mission));
          }
        }
      });
    }

    // 최대 5개만 표시
    if (buttons.length > 5) {
      return buttons.sublist(0, 5);
    }

    return buttons;
  }

  // 미션 버튼 위젯
  Widget _buildMissionButton(String mission) {
    // 현재 미션이 선택되었는지 확인
    bool isSelected = _selectedMissions.contains(mission);

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            // 이미 선택된 경우 제거
            _selectedMissions.remove(mission);
          } else {
            // 새로 선택하는 경우 추가
            _selectedMissions.add(mission);
          }

          // 선택된 모든 미션을 텍스트 필드에 표시
          if (_selectedMissions.isEmpty) {
            _missionController.text = '';
          } else {
            _missionController.text = _selectedMissions.join(', ');
          }

          // 포커스 해제
          FocusScope.of(context).unfocus();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF3A88F4) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            width: 1,
            color:
                isSelected ? const Color(0xFF3A88F4) : const Color(0xFFDADADA),
          ),
        ),
        child: Text(
          mission,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF3A88F4),
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

  // 과목 선택에 따른 미션 추천 버튼들
  Widget _buildSubjectMissionSuggestions() {
    if (widget.missionSubject == null) return Container();

    // 과목별 미션 목록
    Map<String, List<String>> subjectMissions = {
      '국어': ['문제풀이', '복습', '예습', '독서', '쓰기', '암기'],
      '영어': ['문제풀이', '복습', '예습', '단어암기', '듣기', '말하기'],
      '수학': ['문제풀이', '복습', '예습', '연산', '정리', '과제'],
      '사회': ['문제풀이', '복습', '예습', '암기', '정리', '조사'],
      '과학': ['문제풀이', '복습', '예습', '실험', '관찰', '정리'],
    };

    List<String> missions = subjectMissions[widget.missionSubject] ?? [];
    if (missions.isEmpty) return Container();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children:
                missions.map((mission) {
                  // 현재 입력된 텍스트와 일치하는지 확인
                  bool isSelected = _missionController.text.contains(mission);

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _missionController.text = mission;
                        FocusScope.of(context).unfocus();
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: ShapeDecoration(
                        color:
                            isSelected
                                ? const Color(0xFF3A88F4)
                                : const Color(0xFFF0F0F0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text(
                        mission,
                        style: TextStyle(
                          color:
                              isSelected
                                  ? Colors.white
                                  : const Color(0xFFB6B6B6),
                          fontSize: 12,
                          fontFamily: 'Pretendard',
                          fontWeight:
                              isSelected ? FontWeight.w500 : FontWeight.w300,
                          letterSpacing: -0.24,
                        ),
                      ),
                    ),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }

  // 실제 미션 생성 API 호출
  Future<void> _handleMissionCreate() async {
    // 입력 검증
    if (_missionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '미션 내용을 입력해주세요',
            style: TextStyle(fontFamily: 'Pretendard-Medium'),
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_selectedDates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '미션 기간을 선택해주세요',
            style: TextStyle(fontFamily: 'Pretendard-Medium'),
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_allowanceController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '보상금을 입력해주세요',
            style: TextStyle(fontFamily: 'Pretendard-Medium'),
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isCreatingMission = true;
    });

    try {
      // 보상금에서 숫자만 추출
      final rewardText = _allowanceController.text.replaceAll(
        RegExp(r'[^0-9]'),
        '',
      );
      final reward = int.tryParse(rewardText) ?? 0;

      if (reward <= 0) {
        throw Exception('올바른 보상금을 입력해주세요');
      }

      // 미션 기간 설정
      final startDate = _selectedDates.first;
      final endDate =
          _selectedDates.length > 1
              ? _selectedDates.last
              : _selectedDates.first;

      // 미션 카테고리 변환
      MissionCategory category;
      if (widget.missionCategory == 'LEARNING') {
        category = MissionCategory.LEARNING;
      } else {
        category = MissionCategory.HABIT;
      }

      // 미션 과목 설정 (학습인증인 경우에만)
      String? subject;
      if (category == MissionCategory.LEARNING &&
          widget.missionSubject != null) {
        // 한국어를 영어로 변환
        switch (widget.missionSubject) {
          case '국어':
            subject = 'KOREAN';
            break;
          case '영어':
            subject = 'ENGLISH';
            break;
          case '수학':
            subject = 'MATH';
            break;
          case '사회':
            subject = 'SOCIAL';
            break;
          case '과학':
            subject = 'SCIENCE';
            break;
        }
      }

      // 선택된 자녀 ID 목록 생성
      final childIds =
          widget.selectedChildrenData
              .map((child) => child['familyMemberId'] as int)
              .toList();

      // 미션 생성 요청 객체 생성
      final request = CreateMissionRequest(
        title: _missionController.text.trim(),
        subject: subject,
        category: category,
        type: MissionType.FAMILY,
        reward: reward,
        startDate: DateTime(
          startDate.year,
          startDate.month,
          startDate.day,
          0,
          0,
          0,
        ),
        endDate: DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59),
        childs: childIds,
      );

      print('미션 생성 요청: ${request.toJson()}');

      // 미션 생성 API 호출
      final missions = await MissionService.createMission(request: request);

      print('미션 생성 성공: ${missions.length}개의 미션이 생성되었습니다');

      // 성공 시 화면 닫기
      if (mounted) {
        Navigator.pop(context);

        final childNames = widget.selectedChildrenData
            .map((child) => child['nickname'] ?? child['realName'] ?? '자녀')
            .join(', ');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${childNames}님에게 미션이 생성되었습니다!',
              style: TextStyle(fontFamily: 'Pretendard-Medium'),
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('미션 생성 실패: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().replaceAll('Exception: ', ''),
              style: TextStyle(fontFamily: 'Pretendard-Medium'),
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingMission = false;
        });
      }
    }
  }

  // 최근 보상 내역 로드
  Future<void> _loadRecentReward() async {
    print('🎯 최근 보상 내역 로드 시작');
    print('🎯 선택된 자녀 데이터: ${widget.selectedChildrenData}');
    
    if (widget.selectedChildrenData.isEmpty) {
      print('🎯 선택된 자녀 데이터가 비어있음');
      return;
    }

    setState(() {
      _isLoadingRecentReward = true;
    });

    try {
      // 첫 번째 자녀의 ID 가져오기
      final childId = widget.selectedChildrenData.first['userId'] ?? 0;

      print('💰 추출된 자녀 ID: $childId');
      if (childId == 0) {
        print('💰 자녀 ID를 찾을 수 없습니다');
        return;
      }

      print('💰 최근 보상 내역 조회 - LEARNING 카테고리 전체 과목');
      
      final result = await MissionService.getRecentReward(
        childId: childId,
        category: 'LEARNING', // LEARNING 카테고리
        subject: null,        // 모든 과목 (과목 구분 없음)
      );

      print('💰 API 응답 결과: $result');

      if (result != null && mounted) {
        final rewardAmount = result['recentReward'] ?? 0;
        print('💰 API 응답 성공 - 보상 금액: $rewardAmount원');

        if (mounted) {
          setState(() {
            _recentReward = rewardAmount;
            _recentSubjectText = '미션'; // 과목 구분 없이 통일된 텍스트 사용
          });
          
          print('💰 최종 설정: _recentReward=${_recentReward}원, _recentSubjectText=${_recentSubjectText}');
        }
      } else {
        print('💰 API 결과가 null이거나 위젯이 unmounted됨 - 말풍선 표시 안함');
      }
    } catch (e) {
      print('💰 최근 보상 내역 로드 중 오류: $e');
      print('💰 오류로 인해 말풍선 표시 안함');
      // 오류 시에는 말풍선을 표시하지 않음 (_recentReward = null 유지)
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingRecentReward = false;
        });
      }
      print('💰 최근 보상 내역 로드 완료');
    }
  }
}
