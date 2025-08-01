import 'package:flutter/material.dart';
import '../../../widgets/parent/bottom_navigation_bar.dart';
import '../widgets/study_highlight_card.dart';
import '../widgets/mission_section.dart';
import '../../../services/family_service.dart';
import '../../../services/auth_service.dart';
import '../../../services/mission_service.dart';
import '../../../services/challenge_service.dart';
import '../../../services/goal_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../alert/notification_screen.dart';
import '../my/my_page_screen.dart' as my_page; // prefix 추가

class ParentAnalysisScreen extends StatefulWidget {
  const ParentAnalysisScreen({super.key});

  @override
  State<ParentAnalysisScreen> createState() => _ParentAnalysisScreenState();
}

class _ParentAnalysisScreenState extends State<ParentAnalysisScreen> {
  // 가족 정보 관련 변수들 추가
  List<dynamic>? _familyMembers;
  bool _isLoadingFamily = true;
  String? _familyError;

  // 사용자 정보 관련 변수들 추가
  Map<String, dynamic>? _userInfo;
  bool _isLoadingUser = true;
  String? _userError;

  // 선택된 자녀 정보 추가
  Map<String, dynamic>? _selectedChild;

  // 탭 선택 상태 관리
  bool _isStudyInfoSelected = true; // true: 학습 정보, false: 생활 습관

  // 스크롤 관련 변수들 추가
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;

  // 주간 활동 데이터 관련 변수들 추가
  List<List<bool>> _weeklyActivityData = [];
  bool _isLoadingWeeklyData = true;
  String? _weeklyDataError;
  
  // 현재 주차의 날짜 배열 (일요일부터 토요일까지)
  List<int> _currentWeekDates = [];
  
  // 월별 활동 리포트 데이터
  List<Map<String, dynamic>> _monthlyActivityReport = [];
  bool _isLoadingMonthlyReport = true;
  String? _monthlyReportError;

  @override
  void initState() {
    super.initState();

    // 스크롤 리스너 추가
    _scrollController.addListener(_scrollListener);

    // 현재 주차의 날짜 배열 초기화
    _initializeCurrentWeekDates();

    _loadUserInfo();
    _loadFamilyMembers();
  }

  // 현재 주차의 날짜 배열 초기화
  void _initializeCurrentWeekDates() {
    final now = DateTime.now();
    final currentWeekday = now.weekday; // 1(월) ~ 7(일)
    final daysFromSunday = currentWeekday == 7 ? 0 : currentWeekday; // 일요일로부터 며칠 지났는지
    final weekStart = now.subtract(Duration(days: daysFromSunday));
    
    // 일요일부터 토요일까지의 날짜 계산
    _currentWeekDates = [];
    for (int i = 0; i < 7; i++) {
      final date = weekStart.add(Duration(days: i));
      _currentWeekDates.add(date.day);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  // 스크롤 리스너
  void _scrollListener() {
    if (_scrollController.offset > 50) {
      if (!_isScrolled) {
        setState(() {
          _isScrolled = true;
        });
      }
    } else {
      if (_isScrolled) {
        setState(() {
          _isScrolled = false;
        });
      }
    }
  }

  // 사용자 정보 불러오기
  Future<void> _loadUserInfo() async {
    try {
      if (mounted) {
        setState(() {
          _isLoadingUser = true;
          _userError = null;
        });
      }

      print('분석화면: 사용자 정보 로드 시작');

      final userInfo = await AuthService.getUserInfo();

      if (mounted) {
        setState(() {
          _userInfo = userInfo;
          _isLoadingUser = false;
        });

        print('분석화면: 사용자 정보 로드 성공 - ${userInfo['name']}');
      }
    } catch (e) {
      print('분석화면: 사용자 정보 로드 중 예외 발생: $e');

      if (mounted) {
        setState(() {
          _userError = '사용자 정보를 불러올 수 없습니다';
          _isLoadingUser = false;
        });
      }
    }
  }

  // 가족 구성원 목록 불러오기
  Future<void> _loadFamilyMembers() async {
    try {
      if (mounted) {
        setState(() {
          _isLoadingFamily = true;
          _familyError = null;
        });
      }

      print('분석화면: 가족 구성원 목록 로드 시작');

      final familyInfo = await FamilyService.getFamilyInfo();

      if (familyInfo != null) {
        final List<dynamic> memberList = familyInfo['memberInfoList'] ?? [];
        print('분석화면: 가족 정보 로드 성공 - 멤버 ${memberList.length}명');

        // 자녀만 필터링
        final children =
            memberList.where((member) => member['role'] != 'PARENT').toList();

        if (mounted) {
          setState(() {
            _familyMembers = children;
            _selectedChild =
                children.isNotEmpty ? children[0] : null; // 첫 번째 자녀를 기본 선택
            _isLoadingFamily = false;
          });

                // 자녀가 선택된 후 주간 활동 데이터 로드
      if (_selectedChild != null) {
        _loadWeeklyActivityData();
        _loadMonthlyActivityReport();
      }
        }
      } else {
        print('분석화면: 가족 정보 조회 실패 또는 가족 정보 없음');

        if (mounted) {
          setState(() {
            _familyMembers = [];
            _selectedChild = null;
            _isLoadingFamily = false;
          });
        }
      }
    } catch (e) {
      print('분석화면: 가족 구성원 목록 로드 중 예외 발생: $e');

      if (mounted) {
        setState(() {
          _familyError = '가족 정보를 불러올 수 없습니다';
          _isLoadingFamily = false;
          _familyMembers = [];
          _selectedChild = null;
        });
      }
    }
  }

  // 주간 활동 데이터 로드
  Future<void> _loadWeeklyActivityData() async {
    if (_selectedChild == null) return;

    try {
      if (mounted) {
        setState(() {
          _isLoadingWeeklyData = true;
          _weeklyDataError = null;
        });
      }

      print('분석화면: 주간 활동 데이터 로드 시작 - 자녀 ID: ${_selectedChild!['userId']}');

      // 현재 주차의 날짜 배열 다시 계산 (새로고침 시 최신 날짜 반영)
      _initializeCurrentWeekDates();

      final weekData = await _getWeeklyActivityData(_selectedChild!['userId']);

      if (mounted) {
        setState(() {
          _weeklyActivityData = weekData;
          _isLoadingWeeklyData = false;
        });

        print('분석화면: 주간 활동 데이터 로드 성공');
      }
    } catch (e) {
      print('분석화면: 주간 활동 데이터 로드 중 예외 발생: $e');

      if (mounted) {
        setState(() {
          _weeklyDataError = '주간 활동 데이터를 불러올 수 없습니다';
          _isLoadingWeeklyData = false;
          // 오류 발생 시 기본값 설정
          _weeklyActivityData = [
            [false, false, false, false, false, false, false], // 미션
            [false, false, false, false, false, false, false], // 챌린지
            [false, false, false, false, false, false, false], // 목표
          ];
        });
      }
    }
  }

  // 월별 활동 리포트 데이터 로드
  Future<void> _loadMonthlyActivityReport() async {
    if (_selectedChild == null) return;

    try {
      if (mounted) {
        setState(() {
          _isLoadingMonthlyReport = true;
          _monthlyReportError = null;
        });
      }

      print('분석화면: 월별 활동 리포트 로드 시작 - 자녀 ID: ${_selectedChild!['userId']}');

      final reportData = await _getMonthlyActivityReport(_selectedChild!['userId']);

      if (mounted) {
        setState(() {
          _monthlyActivityReport = reportData;
          _isLoadingMonthlyReport = false;
        });

        print('분석화면: 월별 활동 리포트 로드 성공');
      }
    } catch (e) {
      print('분석화면: 월별 활동 리포트 로드 중 예외 발생: $e');

      if (mounted) {
        setState(() {
          _monthlyReportError = '월별 활동 리포트를 불러올 수 없습니다';
          _isLoadingMonthlyReport = false;
          // 오류 발생 시 기본값 설정
          _monthlyActivityReport = [];
        });
      }
    }
  }

  // 월별 활동 리포트 데이터 가져오기 (실제 API 호출)
  Future<List<Map<String, dynamic>>> _getMonthlyActivityReport(int childId) async {
    print('===== 월별 활동 리포트 데이터 조회 시작 =====');

    // 현재 월의 시작일과 종료일 계산
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0);

    print('현재 월: ${monthStart.toString().split(' ')[0]} ~ ${monthEnd.toString().split(' ')[0]}');

    try {
      // 1. 미션 데이터 조회
      print('1. 미션 데이터 조회 중...');
      final missionData = await MissionService.getParentChildMissions(childId: childId);
      
      Map<String, int> learningSubjects = {}; // 과목별 완료 횟수 (학습 정보)
      Map<String, int> habitMissions = {}; // 미션명별 완료 횟수 (생활 습관)
      
      if (missionData != null && missionData['data'] != null) {
        final missions = missionData['data'] as List<dynamic>;
        
        for (var mission in missions) {
          final status = mission['status'] ?? '';
          final category = mission['category'] ?? '';
          final subject = mission['subject'] ?? '';
          final title = mission['title'] ?? '';
          final endDateStr = mission['endDate'] ?? '';
          
          // 완료된 미션만 체크 (ACHIEVEMENT 상태 또는 기간 종료)
          bool isCompleted = false;
          if (status == 'ACHIEVEMENT') {
            isCompleted = true;
          } else if (status == 'ACCEPT' && endDateStr.isNotEmpty) {
            try {
              final endDate = DateTime.parse(endDateStr);
              isCompleted = now.isAfter(endDate);
            } catch (e) {
              // 날짜 파싱 오류 시 무시
            }
          }
          
          if (isCompleted) {
            // 이번 달에 완료된 미션인지 확인
            if (endDateStr.isNotEmpty) {
              try {
                final endDate = DateTime.parse(endDateStr);
                if (endDate.year == now.year && endDate.month == now.month) {
                  if (category == 'LEARNING' && subject.isNotEmpty) {
                    // 학습 정보 - 과목별 집계
                    final subjectName = _getSubjectDisplayName(subject);
                    learningSubjects[subjectName] = (learningSubjects[subjectName] ?? 0) + 1;
                  } else if (category == 'HABIT' && title.isNotEmpty) {
                    // 생활 습관 - 미션명별 집계
                    habitMissions[title] = (habitMissions[title] ?? 0) + 1;
                  }
                }
              } catch (e) {
                print('미션 날짜 파싱 오류: $e');
              }
            }
          }
        }
      }
      
      // 2. 챌린지 데이터 조회 (TODO: 구조 확인 후 구현)
      print('2. 챌린지 데이터 조회 중...');
      // 임시로 주석 처리 - 나중에 ChallengeParticipationResponse 구조 확인 후 구현
      /*
      final familyInfo = await FamilyService.getFamilyInfo();
      if (familyInfo != null && familyInfo['familyId'] != null) {
        final familyId = familyInfo['familyId'];
        final challengeResponse = await ChallengeService.getChildChallenges(familyId, childId);
        // 구조 확인 필요
      }
      */
      
      // 3. 데이터 정렬 및 반환
      List<Map<String, dynamic>> reportData = [];
      
      // 현재 탭에 따라 다른 데이터 반환
      if (_isStudyInfoSelected) {
        // 학습 정보 - 과목별 순위
        final sortedSubjects = learningSubjects.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        
        for (int i = 0; i < sortedSubjects.length && i < 3; i++) {
          final entry = sortedSubjects[i];
          reportData.add({
            'rank': i + 1,
            'subject': entry.key,
            'count': entry.value,
            'displayText': '${entry.value}회',
          });
        }
      } else {
        // 생활 습관 - 미션명별 순위
        final sortedHabits = habitMissions.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        
        for (int i = 0; i < sortedHabits.length && i < 3; i++) {
          final entry = sortedHabits[i];
          reportData.add({
            'rank': i + 1,
            'subject': entry.key,
            'count': entry.value,
            'displayText': '${entry.value}회',
          });
        }
      }
      
      print('===== 월별 활동 리포트 데이터 조회 완료 =====');
      return reportData;
      
    } catch (e) {
      print('월별 활동 리포트 데이터 조회 중 오류: $e');
      return [];
    }
  }

  // 과목 코드를 한글 이름으로 변환
  String _getSubjectDisplayName(String subject) {
    switch (subject) {
      case 'KOREAN':
        return '국어';
      case 'ENGLISH':
        return '영어';
      case 'MATH':
        return '수학';
      case 'SOCIAL':
        return '사회';
      case 'SCIENCE':
        return '과학';
      default:
        return subject;
    }
  }

  // 주간 활동 데이터 가져오기 (실제 API 호출)
  Future<List<List<bool>>> _getWeeklyActivityData(int childId) async {
    print('===== 주간 활동 데이터 조회 시작 =====');

    // 현재 주의 시작일과 종료일 계산 (일요일 시작)
    final now = DateTime.now();
    final currentWeekday = now.weekday; // 1(월) ~ 7(일)
    final daysFromSunday = currentWeekday == 7 ? 0 : currentWeekday; // 일요일로부터 며칠 지났는지
    final weekStart = now.subtract(Duration(days: daysFromSunday));
    final weekEnd = weekStart.add(Duration(days: 6));

    print('현재 주: ${weekStart.toString().split(' ')[0]} ~ ${weekEnd.toString().split(' ')[0]}');

    // 현재 주차의 날짜 배열 계산 (일요일부터 토요일까지)
    _currentWeekDates = [];
    for (int i = 0; i < 7; i++) {
      final date = weekStart.add(Duration(days: i));
      _currentWeekDates.add(date.day);
    }

    // 결과 배열 초기화 (일, 월, 화, 수, 목, 금, 토 순서)
    List<List<bool>> weekData = [
      [false, false, false, false, false, false, false], // 미션
      [false, false, false, false, false, false, false], // 챌린지
      [false, false, false, false, false, false, false], // 목표
    ];

    try {
      // 1. 미션 데이터 조회
      print('1. 미션 데이터 조회 중...');
      final missionData = await MissionService.getParentChildMissions(childId: childId);
      if (missionData != null && missionData['data'] != null) {
        final missions = missionData['data'] as List<dynamic>;
        print('미션 ${missions.length}개 조회됨');
        
        for (var mission in missions) {
          final status = mission['status'] ?? '';
          final startDateStr = mission['startDate'] ?? '';
          final endDateStr = mission['endDate'] ?? '';
          
          // 진행 중이거나 완료된 미션만 체크
          if ((status == 'ACCEPT' || status == 'ACHIEVEMENT') && 
              startDateStr.isNotEmpty && endDateStr.isNotEmpty) {
            try {
              final startDate = DateTime.parse(startDateStr);
              final endDate = DateTime.parse(endDateStr);
              
              // 해당 주와 겹치는 기간이 있는지 확인
              _markActivityDays(weekData[0], weekStart, weekEnd, startDate, endDate);
            } catch (e) {
              print('미션 날짜 파싱 오류: $e');
            }
          }
        }
      }

      // 2. 챌린지 데이터 조회
      print('2. 챌린지 데이터 조회 중...');
      final familyInfo = await FamilyService.getFamilyInfo();
      if (familyInfo != null) {
        final familyId = familyInfo['familyId'];
        final challengeData = await ChallengeService.getChildChallenges(familyId, childId);
        final challenges = challengeData.data;
        print('챌린지 ${challenges.length}개 조회됨');
        
        for (var challenge in challenges) {
          final status = challenge.challengeStatus;
          final startDateStr = challenge.startDate;
          final endDateStr = challenge.endDate;
          
          // 진행 중이거나 완료된 챌린지만 체크
          if ((status == 'ACCEPT' || status == 'ACHIEVEMENT') && 
              startDateStr.isNotEmpty && endDateStr.isNotEmpty) {
            try {
              final startDate = DateTime.parse(startDateStr);
              final endDate = DateTime.parse(endDateStr);
              
              // 해당 주와 겹치는 기간이 있는지 확인
              _markActivityDays(weekData[1], weekStart, weekEnd, startDate, endDate);
            } catch (e) {
              print('챌린지 날짜 파싱 오류: $e');
            }
          }
        }
      }

      // 3. 목표 데이터 조회 - 실제 도장 찍힌 날만 표시
      print('3. 목표 데이터 조회 중...');
      if (familyInfo != null) {
        final familyId = familyInfo['familyId'];
        
        // 1차: 주간 목표 조회
        var goalData = await GoalService.getParentWeeklyGoals(familyId);
        
        // 2차: 주간 목표 조회 실패 시 전체 목표 조회
        if (goalData == null || goalData.isEmpty) {
          print('주간 목표 조회 실패, 전체 목표 조회 시도...');
          goalData = await GoalService.getParentAllGoals(familyId);
        }
        
        if (goalData != null && goalData.isNotEmpty) {
          // 선택된 자녀의 목표만 필터링
          final childGoals = goalData.where((goal) {
            final goalChildId = goal['familyMemberId'] ?? goal['childId'] ?? goal['userId'];
            return goalChildId == childId;
          }).toList();
          
          print('선택된 자녀의 목표 ${childGoals.length}개 조회됨');
          
          for (var goal in childGoals) {
            final status = goal['status'] ?? '';
            final startDateStr = goal['startDate'] ?? '';
            final endDateStr = goal['endDate'] ?? '';
            final goalId = goal['goalId'];
            
            // 진행 중이거나 완료된 목표만 체크
            if ((status == 'ACCEPT' || status == 'ACHIEVEMENT') && 
                startDateStr.isNotEmpty && endDateStr.isNotEmpty && goalId != null) {
              try {
                final startDate = DateTime.parse(startDateStr);
                final endDate = DateTime.parse(endDateStr);
                
                // 해당 주와 목표 기간이 겹치는지 먼저 확인
                if (!(endDate.isBefore(weekStart) || startDate.isAfter(weekEnd))) {
                  print('목표 ID $goalId의 체크 정보 조회 중...');
                  
                  // 목표 체크 정보 조회 (도장 찍힌 날 확인)
                  final checkData = await GoalService.getGoalCheck(goalId);
                  
                  if (checkData != null) {
                    print('목표 ID $goalId 체크 정보: $checkData');
                    
                                         // 요일별 체크 정보 확인 (월~일)
                     final dayChecks = <int, bool>{
                       1: (checkData['mon'] as bool?) ?? false, // 월요일
                       2: (checkData['tue'] as bool?) ?? false, // 화요일  
                       3: (checkData['wed'] as bool?) ?? false, // 수요일
                       4: (checkData['thu'] as bool?) ?? false, // 목요일
                       5: (checkData['fri'] as bool?) ?? false, // 금요일
                       6: (checkData['sat'] as bool?) ?? false, // 토요일
                       7: (checkData['sun'] as bool?) ?? false, // 일요일
                     };
                    
                    // 도장이 찍힌 날들을 주간 활동 데이터에 표시
                    _markGoalAchievementDays(weekData[2], weekStart, weekEnd, startDate, endDate, dayChecks);
                  } else {
                    print('목표 ID $goalId의 체크 정보를 가져올 수 없음');
                  }
                }
              } catch (e) {
                print('목표 날짜 파싱 또는 체크 정보 조회 오류: $e');
              }
            }
          }
        } else {
          print('목표 데이터 조회 실패 또는 데이터 없음');
        }
      }

      print('===== 주간 활동 데이터 조회 완료 =====');
      print('미션: ${weekData[0]}');
      print('챌린지: ${weekData[1]}');
      print('목표: ${weekData[2]}');

      return weekData;
    } catch (e) {
      print('주간 활동 데이터 조회 중 오류: $e');
      // 오류 발생 시 기본값 반환
      return [
        [false, false, false, false, false, false, false], // 미션
        [false, false, false, false, false, false, false], // 챌린지
        [false, false, false, false, false, false, false], // 목표
      ];
    }
  }

  // 활동 기간과 해당 주가 겹치는 날들을 표시
  void _markActivityDays(List<bool> activityWeek, DateTime weekStart, DateTime weekEnd, 
                        DateTime activityStart, DateTime activityEnd) {
    // 활동 기간과 해당 주가 겹치는지 확인
    if (activityEnd.isBefore(weekStart) || activityStart.isAfter(weekEnd)) {
      return; // 겹치지 않음
    }

    // 겹치는 기간의 시작과 종료 계산
    final overlapStart = activityStart.isAfter(weekStart) ? activityStart : weekStart;
    final overlapEnd = activityEnd.isBefore(weekEnd) ? activityEnd : weekEnd;

    // 겹치는 기간의 각 날짜에 대해 표시
    for (var date = overlapStart; date.isBefore(overlapEnd.add(Duration(days: 1))); date = date.add(Duration(days: 1))) {
      final dayIndex = date.difference(weekStart).inDays;
      if (dayIndex >= 0 && dayIndex < 7) {
        activityWeek[dayIndex] = true;
      }
    }
  }

  // 목표 달성 날들을 표시 (도장 찍힌 날만)
  void _markGoalAchievementDays(List<bool> activityWeek, DateTime weekStart, DateTime weekEnd, 
                               DateTime goalStart, DateTime goalEnd, Map<int, bool> dayChecks) {
    print('===== 목표 달성 날 표시 시작 =====');
    print('주간 시작: ${weekStart.toString().split(' ')[0]}');
    print('주간 종료: ${weekEnd.toString().split(' ')[0]}');
    print('목표 시작: ${goalStart.toString().split(' ')[0]}');
    print('목표 종료: ${goalEnd.toString().split(' ')[0]}');
    print('요일별 체크: $dayChecks');

    // 목표 기간과 해당 주가 겹치는지 확인
    if (goalEnd.isBefore(weekStart) || goalStart.isAfter(weekEnd)) {
      print('목표 기간과 해당 주가 겹치지 않음');
      return;
    }

    // 해당 주의 각 날짜에 대해 확인
    for (int i = 0; i < 7; i++) {
      final currentDate = weekStart.add(Duration(days: i));
      
      // 현재 날짜가 목표 기간 내에 있는지 확인
      if (currentDate.isAfter(goalStart.subtract(Duration(days: 1))) && 
          currentDate.isBefore(goalEnd.add(Duration(days: 1)))) {
        
        // 현재 날짜의 요일 계산 (1: 월요일, 2: 화요일, ..., 7: 일요일)
        final dayOfWeek = currentDate.weekday;
        
        // 해당 요일에 도장이 찍혔는지 확인
        final isChecked = dayChecks[dayOfWeek] ?? false;
        
        if (isChecked) {
          activityWeek[i] = true;
          print('날짜 ${currentDate.toString().split(' ')[0]} (${_getDayName(dayOfWeek)}) - 도장 찍힘');
        } else {
          print('날짜 ${currentDate.toString().split(' ')[0]} (${_getDayName(dayOfWeek)}) - 도장 없음');
        }
      }
    }
    
    print('최종 활동 주간 데이터: $activityWeek');
    print('===== 목표 달성 날 표시 완료 =====');
  }

  // 요일 번호를 한글 이름으로 변환
  String _getDayName(int dayOfWeek) {
    switch (dayOfWeek) {
      case 1: return '월요일';
      case 2: return '화요일';
      case 3: return '수요일';
      case 4: return '목요일';
      case 5: return '금요일';
      case 6: return '토요일';
      case 7: return '일요일';
      default: return '알 수 없음';
    }
  }

  // 자녀 변경 모달 표시
  void _showChildSelectionModal() {
    // 자녀(CHILD 역할)만 필터링
    final filteredChildren =
        _familyMembers?.where((child) {
          return child['role'] == 'CHILD';
        }).toList() ??
        [];

    if (filteredChildren.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('선택할 수 있는 자녀가 없습니다')));
      return;
    }

    // 현재 선택된 자녀의 인덱스 찾기
    int selectedIndex = 0;
    if (_selectedChild != null) {
      for (int i = 0; i < filteredChildren.length; i++) {
        final childName =
            filteredChildren[i]['nickname'] ??
            filteredChildren[i]['realName'] ??
            '';
        final selectedChildName =
            _selectedChild?['nickname'] ?? _selectedChild?['realName'] ?? '';
        if (childName == selectedChildName && childName.isNotEmpty) {
          selectedIndex = i;
          break;
        }
      }
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return my_page.ChildSelectionModal(
          children: filteredChildren,
          initialSelectedIndex: selectedIndex,
          onChildSelected: (selectedChild, selectedIndex) {
            setState(() {
              _selectedChild = selectedChild;
            });
            // 자녀 변경 시 주간 활동 데이터 다시 로드
            _initializeCurrentWeekDates(); // 현재 주차의 날짜 배열 다시 계산
            _loadWeeklyActivityData();
            _loadMonthlyActivityReport();
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE7ECF6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE7ECF6),
        elevation: 0,
        centerTitle: false,
        title: null,
        leading: null,
        automaticallyImplyLeading: false,
        toolbarHeight: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),
                      // 공부 하이라이트 카드
                      const StudyHighlightCard(),
                      const SizedBox(height: 24),
                      // 활동 리포트 카드
                      _buildActivityReportCard(),
                      const SizedBox(height: 24),
                      // 주간 활동 카드
                      _buildWeeklyActivityCard(),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: AnimatedContainer(
        duration: Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
        padding:
            _isScrolled
                ? EdgeInsets.zero
                : const EdgeInsets.only(right: 3, top: 8, bottom: 8),
        child: GestureDetector(
          onTap: _showMissionCreationModal,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(_isScrolled ? 28 : 24),
            child: AnimatedContainer(
              duration: Duration(milliseconds: 500),
              curve: Curves.easeInOutCubic,
              width: _isScrolled ? 56 : 140,
              height: _isScrolled ? 56 : 48,
              padding:
                  _isScrolled
                      ? EdgeInsets.zero
                      : const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
              decoration: ShapeDecoration(
                color: const Color(0xFF5D9EFF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(_isScrolled ? 28 : 24),
                ),
                shadows: [
                  BoxShadow(
                    color: const Color(0xFF5D9EFF).withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: AnimatedSwitcher(
                duration: Duration(milliseconds: 400),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(scale: animation, child: child),
                  );
                },
                child:
                    _isScrolled
                        ? Container(
                          key: ValueKey('icon'),
                          width: 24,
                          height: 24,
                          child: Image.asset(
                            'assets/icons/parent/mission/mission_create.png',
                            width: 24,
                            height: 24,
                            color: Colors.white,
                            errorBuilder:
                                (context, error, stackTrace) => Icon(
                                  Icons.add,
                                  color: Colors.white,
                                  size: 24,
                                ),
                          ),
                        )
                        : Row(
                          key: ValueKey('text'),
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 18,
                              height: 18,
                              margin: const EdgeInsets.only(right: 8),
                              child: Image.asset(
                                'assets/icons/parent/mission/생성.png',
                                width: 18,
                                height: 18,
                                color: Colors.white,
                                errorBuilder:
                                    (context, error, stackTrace) => Icon(
                                      Icons.add,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                              ),
                            ),
                            Flexible(
                              child: Text(
                                '미션 생성',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontFamily: 'Pretendard-Medium',
                                  letterSpacing: -0.56,
                                ),
                                overflow: TextOverflow.clip,
                              ),
                            ),
                          ],
                        ),
              ),
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: const ParentBottomNavigationBar(selectedIndex: 3),
    );
  }

  // 앱바 위젯 구현
  Widget _buildAppBar() {
    return Container(
      width: double.infinity,
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      color: const Color(0xFFE7ECF6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 왼쪽 로고
          Image.asset(
            'assets/logos/parent_logo.png',
            width: 28,
            height: 28,
            fit: BoxFit.contain,
          ),

          // 오른쪽 아이콘들 (자녀 프로필, 부모 프로필, 알림)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 자녀 프로필과 변경 버튼
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: ShapeDecoration(
                  color: const Color(0xFF5D9EFF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 자녀 프로필 이미지
                    Container(
                      width: 24,
                      height: 24,
                      decoration: ShapeDecoration(
                        shape: OvalBorder(
                          side: BorderSide(
                            width: 0.80,
                            color: const Color(0xFF146AFF),
                          ),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child:
                            _isLoadingFamily
                                ? Container(
                                  color: Colors.grey[300],
                                  child: Center(
                                    child: SizedBox(
                                      width: 12,
                                      height: 12,
                                      child: CircularProgressIndicator(
                                        color: Colors.grey[600],
                                        strokeWidth: 1,
                                      ),
                                    ),
                                  ),
                                )
                                : _selectedChild?['profileImagePath'] != null &&
                                    _selectedChild!['profileImagePath']!
                                        .isNotEmpty
                                ? CachedNetworkImage(
                                  imageUrl: AuthService.getFullProfileImageUrl(
                                    _selectedChild!['profileImagePath'],
                                  ),
                                  fit: BoxFit.cover,
                                  placeholder:
                                      (context, url) => Container(
                                        color: Colors.grey[300],
                                        child: Icon(
                                          Icons.person,
                                          color: Colors.grey[600],
                                          size: 12,
                                        ),
                                      ),
                                  errorWidget:
                                      (context, url, error) => Container(
                                        color: Colors.grey[300],
                                        child: Icon(
                                          Icons.person,
                                          color: Colors.grey[600],
                                          size: 12,
                                        ),
                                      ),
                                )
                                : Container(
                                  color: Colors.grey[300],
                                  child: Icon(
                                    Icons.person,
                                    color: Colors.grey[600],
                                    size: 12,
                                  ),
                                ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // 변경 버튼
                    GestureDetector(
                      onTap: _showChildSelectionModal,
                      child: Container(
                        width: 24,
                        height: 24,
                        child: Image.asset(
                          'assets/icons/parent/아이변경.png',
                          width: 24,
                          height: 24,
                          color: Colors.white,
                          errorBuilder:
                              (context, error, stackTrace) => Icon(
                                Icons.swap_horiz,
                                color: Colors.white,
                                size: 16,
                              ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // 부모 프로필 아이콘 - 실제 사용자 프로필 이미지로 변경
              Container(
                width: 32,
                height: 32,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child:
                      _isLoadingUser
                          ? Container(
                            color: const Color(0xFFFDC963),
                            child: const Center(
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                          )
                          : _userInfo?['profileImagePath'] != null &&
                              _userInfo!['profileImagePath']!.isNotEmpty
                          ? CachedNetworkImage(
                            imageUrl: AuthService.getFullProfileImageUrl(
                              _userInfo!['profileImagePath'],
                            ),
                            fit: BoxFit.cover,
                            placeholder:
                                (context, url) => Container(
                                  color: const Color(0xFFFDC963),
                                  child: const Center(
                                    child: Text(
                                      '부',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontFamily: 'Pretendard-Bold',
                                      ),
                                    ),
                                  ),
                                ),
                            errorWidget:
                                (context, url, error) => Container(
                                  color: const Color(0xFFFDC963),
                                  child: const Center(
                                    child: Text(
                                      '부',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontFamily: 'Pretendard-Bold',
                                      ),
                                    ),
                                  ),
                                ),
                          )
                          : Container(
                            color: const Color(0xFFFDC963),
                            child: const Center(
                              child: Text(
                                '부',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontFamily: 'Pretendard-Bold',
                                ),
                              ),
                            ),
                          ),
                ),
              ),

              // 알림 아이콘 - 지정된 이미지 파일로 변경
              GestureDetector(
                onTap: () {
                  // 알림 화면으로 이동
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ParentNotificationScreen(),
                    ),
                  );
                },
                child: Container(
                  width: 32,
                  height: 32,
                  child: Center(
                    child: Image.asset(
                      'assets/icons/parent/noti/alert.png',
                      width: 20,
                      height: 20,
                      color: Colors.black,
                      errorBuilder:
                          (context, error, stackTrace) => const Icon(
                            Icons.notifications_none_rounded,
                            color: Colors.black,
                            size: 20,
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
  }

  // 활동 리포트 카드 위젯
  Widget _buildActivityReportCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Color(0x35000000),
            blurRadius: 8,
            offset: Offset(3, 4),
            spreadRadius: 0,
          ),
        ],
        borderRadius: BorderRadius.circular(24),
      ),
      child: Container(
        width: double.infinity,
        decoration: ShapeDecoration(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상단 헤더
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: ShapeDecoration(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                '이번 달 아이의 총 활동 리포트',
                                style: TextStyle(
                                  color: const Color(0xFF202020),
                                  fontSize: 16,
                                  fontFamily: 'Pretendard-Bold',
                                  letterSpacing: -0.72,
                                ),
                              ),
                            ),
                            // 새로고침 버튼
                            if (_monthlyReportError != null)
                              GestureDetector(
                                onTap: _loadMonthlyActivityReport,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  child: Icon(
                                    Icons.refresh,
                                    color: const Color(0xFF5D9EFF),
                                    size: 20,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          child: Text(
                            _isStudyInfoSelected 
                                ? '우리 아이가 가장 많이 참여했던 과목을 알아보세요'
                                : '우리 아이가 가장 많이 실천한 생활 습관을 알아보세요',
                            style: TextStyle(
                              color: const Color(0xFF999999),
                              fontSize: 13,
                              fontFamily: 'Pretendard-Light',
                              letterSpacing: -0.28,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 탭 버튼 영역
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(color: Colors.white),
              child: Center(
                child: Container(
                  width: 160,
                  height: 44,
                  child: Stack(
                    children: [
                      // 배경 컨테이너
                      Positioned(
                        left: 0,
                        top: 0,
                        child: Container(
                          width: 160,
                          height: 44,
                          decoration: ShapeDecoration(
                            color: const Color(0xFF5D6A7F),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              // 학습 정보 탭
                              Expanded(
                                child: GestureDetector(
                                                        onTap: () {
                        setState(() {
                          _isStudyInfoSelected = true;
                        });
                        // 탭 변경 시 월별 활동 리포트 다시 로드
                        _loadMonthlyActivityReport();
                      },
                                  child: Container(
                                    height: 44,
                                    child: Center(
                                      child: Text(
                                        '학습 정보',
                                        style: TextStyle(
                                          color:
                                              _isStudyInfoSelected
                                                  ? const Color(0xFF5D9EFF)
                                                  : const Color(0xFFB6B6B6),
                                          fontSize: 12,
                                          fontFamily: 'Pretendard-Light',
                                          letterSpacing: -0.24,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              // 생활 습관 탭
                              Expanded(
                                child: GestureDetector(
                                                        onTap: () {
                        setState(() {
                          _isStudyInfoSelected = false;
                        });
                        // 탭 변경 시 월별 활동 리포트 다시 로드
                        _loadMonthlyActivityReport();
                      },
                                  child: Container(
                                    height: 44,
                                    child: Center(
                                      child: Text(
                                        '생활 습관',
                                        style: TextStyle(
                                          color:
                                              !_isStudyInfoSelected
                                                  ? const Color(0xFF5D9EFF)
                                                  : const Color(0xFFB6B6B6),
                                          fontSize: 12,
                                          fontFamily: 'Pretendard-Light',
                                          letterSpacing: -0.24,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // 선택된 탭의 흰색 배경과 텍스트
                      AnimatedPositioned(
                        duration: Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        left: _isStudyInfoSelected ? 4 : 84,
                        top: 4,
                        child: Container(
                          width: 72,
                          height: 36,
                          decoration: ShapeDecoration(
                            color: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              _isStudyInfoSelected ? '학습 정보' : '생활 습관',
                              style: TextStyle(
                                color: Color.fromARGB(255, 93, 158, 255),
                                fontSize: 12,
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
            ),

            // 순위 목록 영역
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: ShapeDecoration(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
              ),
              child: _buildRankingList(),
            ),
          ],
        ),
      ),
    );
  }

  // 순위 목록 위젯
  Widget _buildRankingList() {
    if (_isLoadingMonthlyReport) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < 3; i++) ...[
            Container(
              height: 60,
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            const Color(0xFF5D9EFF),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 100,
                          height: 16,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: 60,
                          height: 12,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (i < 2) const SizedBox(height: 16),
          ],
        ],
      );
    }

    if (_monthlyReportError != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Icon(
                  Icons.error_outline,
                  color: const Color(0xFFFF6B6B),
                  size: 48,
                ),
                const SizedBox(height: 12),
                Text(
                  _monthlyReportError!,
                  style: TextStyle(
                    color: const Color(0xFFFF6B6B),
                    fontSize: 14,
                    fontFamily: 'Pretendard-Medium',
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: _loadMonthlyActivityReport,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF5D9EFF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '다시 시도',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontFamily: 'Pretendard-Medium',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    if (_monthlyActivityReport.isEmpty) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Icon(
                  Icons.bar_chart_outlined,
                  color: const Color(0xFF999999),
                  size: 48,
                ),
                const SizedBox(height: 12),
                Text(
                  _isStudyInfoSelected 
                      ? '이번 달 완료한 학습 미션이 없습니다.'
                      : '이번 달 완료한 생활 습관 미션이 없습니다.',
                  style: TextStyle(
                    color: const Color(0xFF999999),
                    fontSize: 14,
                    fontFamily: 'Pretendard-Medium',
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      );
    }

    // 메달 경로와 색상 정보
    final medalInfo = [
      {
        'path': 'assets/icons/parent/analysis/gold_medal.png',
        'color': const Color(0xFFFFD27F),
      },
      {
        'path': 'assets/icons/parent/analysis/silver_medal.png',
        'color': const Color(0xFFCEDAEB),
      },
      {
        'path': 'assets/icons/parent/analysis/bronze_medal.png',
        'color': const Color(0xFFEEBA7D),
      },
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < _monthlyActivityReport.length; i++) ...[
          _buildRankingItem(
            rank: _monthlyActivityReport[i]['rank'].toString(),
            subject: _monthlyActivityReport[i]['subject'],
            count: _monthlyActivityReport[i]['displayText'],
            medalPath: medalInfo[i]['path'] as String,
            fallbackColor: medalInfo[i]['color'] as Color,
          ),
          if (i < _monthlyActivityReport.length - 1) const SizedBox(height: 16),
        ],
      ],
    );
  }

  // 순위 아이템 위젯
  Widget _buildRankingItem({
    required String rank,
    required String subject,
    required String count,
    required String medalPath,
    required Color fallbackColor,
  }) {
    return Container(
      width: double.infinity,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 메달 아이콘
              Container(
                width: 28,
                height: 28,
                margin: const EdgeInsets.only(right: 12),
                child: Image.asset(
                  medalPath,
                  width: 28,
                  height: 28,
                  fit: BoxFit.contain,
                  errorBuilder:
                      (context, error, stackTrace) => Container(
                        width: 28,
                        height: 28,
                        decoration: ShapeDecoration(
                          color: fallbackColor,
                          shape: OvalBorder(),
                        ),
                        child: Center(
                          child: Text(
                            rank,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontFamily: 'Pretendard-Bold',
                            ),
                          ),
                        ),
                      ),
                ),
              ),
              // 과목명
              Text(
                subject,
                style: TextStyle(
                  color: const Color(0xFF8490A3),
                  fontSize: 14,
                  fontFamily: 'Pretendard-Light',
                  letterSpacing: -0.28,
                ),
              ),
            ],
          ),
          // 횟수
          Text(
            count,
            style: TextStyle(
              color: const Color(0xFF5D9EFF),
              fontSize: 16,
              fontFamily: 'Pretendard-Bold',
              letterSpacing: -0.32,
            ),
          ),
        ],
      ),
    );
  }

  // 주간 활동 카드 위젯
  Widget _buildWeeklyActivityCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Color(0x35000000),
            blurRadius: 8,
            offset: Offset(3, 4),
            spreadRadius: 0,
          ),
        ],
        borderRadius: BorderRadius.circular(24),
      ),
      child: Container(
        width: double.infinity,
        decoration: ShapeDecoration(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상단 헤더
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: ShapeDecoration(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '이번 주 우리 아이가 열심히 했던 날',
                          style: TextStyle(
                            color: const Color(0xFF202020),
                            fontSize: 16,
                            fontFamily: 'Pretendard-Bold',
                            letterSpacing: -0.72,
                          ),
                        ),
                      ),
                      // 새로고침 버튼
                      if (_weeklyDataError != null)
                        GestureDetector(
                          onTap: _loadWeeklyActivityData,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              Icons.refresh,
                              color: const Color(0xFF5D9EFF),
                              size: 20,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    child: Text(
                      _weeklyDataError ?? '우리 아이가 참여했던 날들을 한눈에 알아봐요',
                      style: TextStyle(
                        color: _weeklyDataError != null 
                            ? const Color(0xFFFF6B6B)
                            : const Color(0xFF999999),
                        fontSize: 13,
                        fontFamily: 'Pretendard-Light',
                        letterSpacing: -0.28,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 주간 활동 영역
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: ShapeDecoration(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
              ),
              child: Column(
                children: [
                  // 요일 헤더
                  Row(
                    children: [
                      Container(width: 40), // 왼쪽 여백 (카테고리 라벨 공간)
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildDayHeader('일', true),
                            _buildDayHeader('월', false),
                            _buildDayHeader('화', false),
                            _buildDayHeader('수', false),
                            _buildDayHeader('목', false),
                            _buildDayHeader('금', false),
                            _buildDayHeader('토', true),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // 날짜 헤더
                  Row(
                    children: [
                      Container(width: 40), // 왼쪽 여백
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: _currentWeekDates.isNotEmpty
                              ? _currentWeekDates.asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final date = entry.value;
                                  final isWeekend = index == 0 || index == 6; // 일요일 또는 토요일
                                  return _buildDateHeader(date.toString(), isWeekend);
                                }).toList()
                              : [
                                  _buildDateHeader('-', true),
                                  _buildDateHeader('-', false),
                                  _buildDateHeader('-', false),
                                  _buildDateHeader('-', false),
                                  _buildDateHeader('-', false),
                                  _buildDateHeader('-', false),
                                  _buildDateHeader('-', true),
                                ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 활동 그리드
                  _buildActivityGrid(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 카테고리 텍스트 스타일
  TextStyle _getCategoryTextStyle() {
    return TextStyle(
      color: const Color(0xFF8490A3),
      fontSize: 12,
      fontFamily: 'Pretendard-Light',
      letterSpacing: -0.24,
    );
  }

  // 요일 헤더 위젯
  Widget _buildDayHeader(String day, bool isWeekend) {
    return Text(
      day,
      style: TextStyle(
        color: isWeekend ? const Color(0xFFFF6062) : const Color(0xFF5C6B7F),
        fontSize: 14,
        fontFamily: 'Pretendard-Regular',
        height: 1.50,
      ),
    );
  }

  // 날짜 헤더 위젯
  Widget _buildDateHeader(String date, bool isWeekend) {
    return Text(
      date,
      style: TextStyle(
        color: isWeekend ? const Color(0xFFFF6062) : const Color(0xFF5C6B7F),
        fontSize: 12,
        fontFamily: 'Pretendard-Regular',
        height: 1.75,
      ),
    );
  }

  // 활동 그리드 위젯
  Widget _buildActivityGrid() {
    final categories = ['미션', '챌린지', '목표'];

    // 로딩 중인 경우
    if (_isLoadingWeeklyData) {
      return Column(
        children: List.generate(3, (rowIndex) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                // 왼쪽 카테고리 라벨
                Container(
                  width: 40,
                  child: Text(
                    categories[rowIndex],
                    style: _getCategoryTextStyle(),
                  ),
                ),
                // 로딩 상태 표시
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(7, (colIndex) {
                      return Container(
                        width: 16,
                        height: 16,
                        decoration: ShapeDecoration(
                          color: const Color(0xFFE0E0E0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        child: Center(
                          child: SizedBox(
                            width: 8,
                            height: 8,
                            child: CircularProgressIndicator(
                              strokeWidth: 1,
                              color: const Color(0xFF999999),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          );
        }),
      );
    }

    // 에러 발생한 경우
    if (_weeklyDataError != null) {
      return Column(
        children: List.generate(3, (rowIndex) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                // 왼쪽 카테고리 라벨
                Container(
                  width: 40,
                  child: Text(
                    categories[rowIndex],
                    style: _getCategoryTextStyle(),
                  ),
                ),
                // 에러 상태 표시
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(7, (colIndex) {
                      return Container(
                        width: 16,
                        height: 16,
                        decoration: ShapeDecoration(
                          color: const Color(0xFFF0F0F0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.error_outline,
                            size: 8,
                            color: const Color(0xFFFF6B6B),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          );
        }),
      );
    }

    // 정상 데이터가 있는 경우
    final weekData = _weeklyActivityData.isNotEmpty ? _weeklyActivityData : [
      [false, false, false, false, false, false, false], // 미션
      [false, false, false, false, false, false, false], // 챌린지
      [false, false, false, false, false, false, false], // 목표
    ];

    return Column(
      children: List.generate(3, (rowIndex) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            children: [
              // 왼쪽 카테고리 라벨
              Container(
                width: 40,
                child: Text(
                  categories[rowIndex],
                  style: _getCategoryTextStyle(),
                ),
              ),
              // 활동 상태 박스들
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(7, (colIndex) {
                    return Container(
                      width: 16,
                      height: 16,
                      decoration: ShapeDecoration(
                        color:
                            weekData[rowIndex][colIndex]
                                ? const Color(0xFF10CB86)
                                : const Color(0xFFC3C3C3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  void _showMissionCreationModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return const MissionCreationModal();
      },
    );
  }
}
