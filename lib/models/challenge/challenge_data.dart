class ChallengeData {
  final String type;
  final String title;
  final String participants;
  final String period;
  final String time;

  DateTime selectedDate;
  String selectedDay;
  int selectedHour;
  int selectedMinute;
  String selectedDuration;
  String totalAmount;
  bool saveButtonEnabled;

  // 날짜 선택 관련 변수
  DateTime? tempSelectedDate;
  bool isSelectingNewDate;

  // 월 선택을 위한 변수
  int currentMonth;
  int currentYear;

  // 요일 목록
  final List<String> days = ['월', '화', '수', '목', '금', '토', '일'];

  // 기간 선택 옵션
  final List<String> durations = ['1h', '2h', '3h', '4h', '+'];

  ChallengeData({
    required this.type,
    required this.title,
    required this.participants,
    required this.period,
    required this.time,
  }) : // 기본값 설정
       selectedDate = DateTime.now().add(const Duration(days: 1)),
       selectedDay = '월',
       selectedHour = 18, // 6 PM
       selectedMinute = 28,
       selectedDuration = '3h',
       totalAmount = '30,000원',
       saveButtonEnabled = true,
       isSelectingNewDate = false,
       tempSelectedDate = null,
       currentMonth = DateTime.now().month,
       currentYear = DateTime.now().year {
    // 요일 계산
    selectedDay = days[selectedDate.weekday - 1];
  }

  // 챌린지 종료 날짜 계산
  DateTime calculateEndDate() {
    // 기본적으로 4주(28일) 후로 설정
    return selectedDate.add(const Duration(days: 28));
  }

  // 버튼 활성화 상태 확인
  void checkSaveButtonStatus() {
    saveButtonEnabled = true;
    // 필요에 따라 추가 조건 구현 가능
    // saveButtonEnabled = (selectedHour > 0 || selectedMinute > 0) &&
    //    selectedDate.isAfter(DateTime.now()) &&
    //    totalAmount.isNotEmpty;
  }

  // 날짜 업데이트
  void updateSelectedDate(DateTime date) {
    selectedDate = date;
    selectedDay = days[date.weekday - 1];
    checkSaveButtonStatus();
  }

  // 시간 업데이트
  void updateSelectedTime(int hour, int minute) {
    selectedHour = hour;
    selectedMinute = minute;
    checkSaveButtonStatus();
  }

  // 금액 업데이트
  void updateTotalAmount(String amount) {
    totalAmount = amount;
    checkSaveButtonStatus();
  }

  // 기간 업데이트
  void updateSelectedDuration(String duration) {
    selectedDuration = duration;
    checkSaveButtonStatus();
  }

  // 월 변경
  void changeMonth(int change) {
    if (change > 0) {
      // 다음 달
      if (currentMonth == 12) {
        currentMonth = 1;
        currentYear++;
      } else {
        currentMonth++;
      }
    } else {
      // 이전 달
      if (currentMonth == 1) {
        currentMonth = 12;
        currentYear--;
      } else {
        currentMonth--;
      }
    }
  }
}
