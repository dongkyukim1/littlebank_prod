import 'package:flutter/material.dart';
import '../../../services/challenge_service.dart';
import '../../../services/family_service.dart';

class ChallengeDetailScreen extends StatefulWidget {
  final int id;
  final String type;
  final String title;
  final String participants;
  final String period;
  final String time;
  final String startDate;
  final String endDate;
  final String startTime;
  final int totalStudyTime;
  final int reward;

  const ChallengeDetailScreen({
    super.key,
    required this.id,
    required this.type,
    required this.title,
    required this.participants,
    required this.period,
    required this.time,
    required this.startDate,
    required this.endDate,
    required this.startTime,
    required this.totalStudyTime,
    required this.reward,
  });

  @override
  State<ChallengeDetailScreen> createState() => _ChallengeDetailScreenState();
}

class _ChallengeDetailScreenState extends State<ChallengeDetailScreen> {
  late DateTime _selectedDate;
  late DateTime _endDate;
  late String _selectedDay;
  late String _endDay;
  DateTime _currentMonth = DateTime.now().copyWith(day: 1); // 현재 월의 1일로 바로 초기화
  int _selectedHour = 6;
  int _selectedMinute = 28;
  String _selectedDuration = "1h";
  final TextEditingController _totalTimeController = TextEditingController();
  bool _meridiem = true; // true = PM, false = AM
  bool _isSelectingEndDate = false; // 달력에서 종료일 선택 모드
  bool _showRewardWarning = false; // 포인트 경고 표시 여부
  bool _isExpandedChallengeInfo = true; // 기본적으로 펼쳐진 상태
  bool _isLoading = false; // API 호출 중 로딩 상태 추가
  
  // 챌린지 상세 정보
  Challenge? _challengeDetail;
  bool _isLoadingDetail = false; // 상세 정보 로딩 상태
  String? _detailError; // 상세 정보 로드 오류

  @override
  void initState() {
    super.initState();
    // 현재 날짜로 초기화
    final now = DateTime.now();
    _selectedDate = now;
    _endDate = now;
    
    // 요일 계산
    final List<String> weekdays = ['일', '월', '화', '수', '목', '금', '토'];
    _selectedDay = weekdays[now.weekday % 7];
    _endDay = _selectedDay;
    
    // 포인트 입력 변경 리스너 추가
    _totalTimeController.addListener(_checkRewardInput);
    
    // 챌린지 상세 정보 로드
    _loadChallengeDetail();
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

  // 챌린지 상세 정보를 로드하는 함수
  Future<void> _loadChallengeDetail() async {
    if (widget.id <= 0) {
      setState(() {
        _detailError = '유효하지 않은 챌린지 ID입니다.';
      });
      return;
    }
    
    setState(() {
      _isLoadingDetail = true;
      _detailError = null;
    });
    
    try {
      // 전체 챌린지에서 해당 ID로 찾기
      final challengeResponse = await ChallengeService.getChallenges();
      final detail = challengeResponse.data.firstWhere(
        (challenge) => challenge.id == widget.id,
        orElse: () => throw Exception('챌린지를 찾을 수 없습니다.'),
      );
      
      setState(() {
        _challengeDetail = detail;
        _isLoadingDetail = false;
        
        // 챌린지 정보에서 기본 날짜 설정
        if (detail.startDate.isNotEmpty && detail.endDate.isNotEmpty) {
          try {
            final startDate = DateTime.parse(detail.startDate);
            final endDate = DateTime.parse(detail.endDate);
            
            // 시작일이 오늘 이후인 경우에만 적용
            if (startDate.isAfter(DateTime.now())) {
              _selectedDate = startDate;
              _endDate = endDate;
              
              // 요일 계산
              final List<String> weekdays = ['일', '월', '화', '수', '목', '금', '토'];
              _selectedDay = weekdays[startDate.weekday % 7];
              _endDay = weekdays[endDate.weekday % 7];
            }
          } catch (e) {
            print('날짜 파싱 오류: $e');
          }
        }
      });
    } catch (e) {
      setState(() {
        _isLoadingDetail = false;
        _detailError = e.toString();
      });
      print('챌린지 상세 정보 로드 오류: $e');
    }
  }

  // 신청하기 버튼 클릭 핸들러
  void _handleSubmit() async {
    // 포인트 입력 확인
    if (_totalTimeController.text.trim().isEmpty) {
      setState(() {
        _showRewardWarning = true;
      });
      return;
    }
    
    // 확인 모달 표시
    _showConfirmationModal(context);
  }
  
  // 실제 API 호출 메서드
  void _submitChallenge() async {
    // 챌린지 ID 확인
    if (widget.id <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('유효하지 않은 챌린지입니다. 다시 시도해주세요.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // 챌린지 상세 정보 확인
    if (_challengeDetail == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('챌린지 정보를 불러올 수 없습니다. 다시 시도해주세요.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // 가족 멤버 확인
    setState(() {
      _isLoading = true;
    });
    
    try {
      // 가족 정보 조회
      final familyInfo = await FamilyService.getFamilyInfo();
      
      if (familyInfo == null || familyInfo['memberInfoList'] == null || familyInfo['memberInfoList'].isEmpty) {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('가족 구성원이 없습니다. 먼저 가족을 등록해주세요.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      
      // 부모님이 있는지 확인
      final memberList = familyInfo['memberInfoList'] as List;
      final hasParent = memberList.any((member) => member['role'] == 'PARENT');
      
      if (!hasParent) {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('부모님이 가족에 등록되어 있지 않습니다. 부모님을 먼저 초대해주세요.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      
      print('가족 구성원 확인 완료: ${memberList.length}명, 부모님 존재: $hasParent');
      
      // 중복 참여 확인 - 신청된 챌린지와 승인된 챌린지 확인
      try {
        // 신청된 챌린지 확인
        final requestedChallenges = await ChallengeService.getMyChallenges(
          challengeStatus: ChallengeStatus.ONGOING,
        );
        
        final isAlreadyRequested = requestedChallenges.data.any((challenge) => 
          challenge.title == _challengeDetail?.title
        );
        
        if (isAlreadyRequested) {
          setState(() {
            _isLoading = false;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('이미 신청한 동일한 챌린지가 있습니다.'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }

        print('중복 참여 확인 완료: 참여 가능');
        
      } catch (e) {
        print('중복 참여 확인 중 오류: $e');
        // 오류가 발생해도 진행 - 중복 참여 확인은 선택적
      }
      
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('가족 정보 확인 중 오류가 발생했습니다: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // 포인트 값 추출 (원 단위 제거 및 콤마 제거)
    String rewardStr = _totalTimeController.text.replaceAll('원', '').replaceAll(',', '').trim();
    int reward = int.tryParse(rewardStr) ?? 0;
    
    // 시간 형식으로 변환 - ISO DateTime 형식으로 수정
    int hour24 = _meridiem ? 
      (_selectedHour == 12 ? 12 : _selectedHour + 12) : 
      (_selectedHour == 12 ? 0 : _selectedHour);
    
    // 날짜 형식 변환 (ISO 8601) - 사용자가 선택한 날짜 사용
    String startDate;
    String endDate;
    
    // 사용자가 달력에서 선택한 날짜를 우선 사용
    startDate = "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}";
    endDate = "${_endDate.year}-${_endDate.month.toString().padLeft(2, '0')}-${_endDate.day.toString().padLeft(2, '0')}";
    
    print('사용자 선택 날짜 사용');
    print('시작 날짜: $startDate (선택: ${_selectedDate.year}-${_selectedDate.month}-${_selectedDate.day})');
    print('종료 날짜: $endDate (선택: ${_endDate.year}-${_endDate.month}-${_endDate.day})');
    
    // 선택한 날짜가 챌린지 기간 내에 있는지 확인
    if (_challengeDetail != null && 
        _challengeDetail!.startDate.isNotEmpty && 
        _challengeDetail!.endDate.isNotEmpty) {
      try {
        final challengeStartDate = DateTime.parse(_challengeDetail!.startDate.split('T')[0]);
        final challengeEndDate = DateTime.parse(_challengeDetail!.endDate.split('T')[0]);
        final selectedStartDate = DateTime.parse(startDate);
        final selectedEndDate = DateTime.parse(endDate);
        
        print('=== 날짜 유효성 검사 ===');
        print('챌린지 허용 기간: ${challengeStartDate.toString().split(' ')[0]} ~ ${challengeEndDate.toString().split(' ')[0]}');
        print('사용자 선택 기간: ${selectedStartDate.toString().split(' ')[0]} ~ ${selectedEndDate.toString().split(' ')[0]}');
        print('현재 날짜: ${DateTime.now().toString().split(' ')[0]}');
        
        // 선택한 날짜가 챌린지 기간을 벗어나면 경고
        if (selectedStartDate.isBefore(challengeStartDate) || selectedEndDate.isAfter(challengeEndDate)) {
          print('❌ 오류: 선택한 날짜가 챌린지 기간을 벗어났습니다!');
          
          // 사용자에게 알림
          setState(() {
            _isLoading = false;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('선택한 날짜가 챌린지 기간(${challengeStartDate.toString().split(' ')[0]} ~ ${challengeEndDate.toString().split(' ')[0]})을 벗어났습니다.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 4),
            ),
          );
          return;
        }
        
        // 미래 날짜가 너무 먼지 확인 (30일 후까지만 허용)
        final maxFutureDate = DateTime.now().add(Duration(days: 30));
        if (selectedStartDate.isAfter(maxFutureDate)) {
          print('❌ 오류: 선택한 시작 날짜가 너무 먼 미래입니다!');
          
          setState(() {
            _isLoading = false;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('시작 날짜가 너무 먼 미래입니다. 30일 이내의 날짜를 선택해주세요.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 4),
            ),
          );
          return;
        }
        
        print('✅ 날짜 유효성 검사 통과');
        
      } catch (e) {
        print('챌린지 날짜 검증 중 오류: $e');
      }
    }
    
    // startTime을 사용자가 선택한 시작 날짜 기준으로 수정
    String startTime = "${startDate}T${hour24.toString().padLeft(2, '0')}:${_selectedMinute.toString().padLeft(2, '0')}:00";
    
    print('=== 날짜 계산 디버깅 ===');
    print('전송할 시작 날짜: $startDate');
    print('전송할 종료 날짜: $endDate');
    print('전송할 시작 시간: $startTime');
    print('선택한 시각: ${_selectedHour}:${_selectedMinute} ${_meridiem ? 'PM' : 'AM'}');
    print('24시간 형식: ${hour24}:${_selectedMinute}');
    print('=== 디버깅 종료 ===');
    
    print('계산된 날짜 - 시작: $startDate, 종료: $endDate');
    
    // 공부 시간 계산 (사용자가 선택한 시간 사용)
    int dailyStudyTime = 1; // 기본값
    if (_selectedDuration == "1h") {
      dailyStudyTime = 1;
    } else if (_selectedDuration == "2h") {
      dailyStudyTime = 2;
    } else if (_selectedDuration == "3h") {
      dailyStudyTime = 3;
    } else if (_selectedDuration == "4h") {
      dailyStudyTime = 4;
    } else if (_selectedDuration == "30m") {
      dailyStudyTime = 1; // 30분은 1시간으로 처리 (최소값)
    } else if (_selectedDuration == "더 많이") {
      dailyStudyTime = 5; // 더 많이는 5시간으로 처리
    }
    
    // 사용자가 선택한 공부시간을 사용 (챌린지 기본값 무시)
    int totalStudyTime = dailyStudyTime;
    
    // 유효성 검사: 최소 1시간 보장
    if (totalStudyTime <= 0) {
      totalStudyTime = 1;
      print('⚠️ 공부시간이 0 이하여서 1시간으로 보정');
    }
    
    print('챌린지 요구 총 공부시간: ${_challengeDetail?.totalStudyTime}시간 (무시됨)');
    print('사용자 선택 일일 공부시간: $dailyStudyTime시간');
    print('전송할 총 공부시간: $totalStudyTime시간');
    
    print('챌린지 ID: ${widget.id}');
    print('실제 챌린지 ID: ${_challengeDetail?.id}');
    print('챌린지 제목: ${_challengeDetail?.title}');
    print('챌린지 카테고리: ${_challengeDetail?.category}');
    print('챌린지 상태: ${_challengeDetail?.challengeStatus}');
    print('챌린지 현재 참여자: ${_challengeDetail?.currentParticipants}');
    print('챌린지 최대 참여자: ${_challengeDetail?.totalParticipants}');
    print('시작 날짜: $startDate');
    print('종료 날짜: $endDate');
    print('시작 시간: $startTime');
    print('공부 시간: $totalStudyTime시간');
    print('포인트: $reward');
    print('subject: ${_challengeDetail?.subject}');
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // API 호출 - subject 파라미터 제거
      final response = await ChallengeService.joinChallenge(
        challengeId: _challengeDetail?.id ?? widget.id, // 실제 챌린지 ID 사용
        startDate: startDate,
        endDate: endDate,
        startTime: startTime,
        totalStudyTime: totalStudyTime,
        reward: reward,
      );
      
      print('=== 챌린지 참여 성공 응답 ===');
      print('participationId: ${response.participationId}');
      print('challengeId: ${response.challengeId}');
      print('title: ${response.title}');
      print('challengeStatus: ${response.challengeStatus}');  // ← 이게 핵심!
      print('accepted: ${response.accepted}');
      print('startDate: ${response.startDate}');
      print('endDate: ${response.endDate}');
      print('startTime: ${response.startTime}');
      print('totalStudyTime: ${response.totalStudyTime}');
      print('reward: ${response.reward}');
      print('subject: ${response.subject}');
      print('=== 응답 데이터 끝 ===');
      
      // 상태가 REQUESTED인지 ACCEPT인지 확인
      if (response.challengeStatus == 'REQUESTED') {
        print('✅ 올바르게 REQUESTED 상태로 저장됨 - 부모 승인 필요');
      } else if (response.challengeStatus == 'ACCEPT') {
        print('🚨 자동으로 ACCEPT 상태로 저장됨 - 부모 승인 불필요!');
      } else {
        print('❓ 예상치 못한 상태: ${response.challengeStatus}');
      }
      
      setState(() {
        _isLoading = false;
      });
      
      // 성공 모달 표시
      _showCompletionModal(context);
      
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      // 오류 처리
      print('챌린지 참여 오류: $e');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('챌린지 참여 신청에 실패했습니다: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _toggleChallengeInfo() {
        setState(() {
      _isExpandedChallengeInfo = !_isExpandedChallengeInfo;
    });
  }

  // 이전 달로 이동
  void _goToPreviousMonth() {
    setState(() {
      _currentMonth = DateTime(
        _currentMonth.year,
        _currentMonth.month - 1,
        1,
      );
    });
  }

  // 다음 달로 이동
  void _goToNextMonth() {
    setState(() {
      _currentMonth = DateTime(
        _currentMonth.year,
        _currentMonth.month + 1,
        1,
      );
    });
  }

  // 달의 마지막 날짜 구하기
  int _getLastDayOfMonth(DateTime month) {
    // 다음 달의 첫날에서 하루를 빼면 현재 달의 마지막 날
    final nextMonth = DateTime(month.year, month.month + 1, 1);
    final lastDay = nextMonth.subtract(const Duration(days: 1)).day;
    return lastDay;
  }

  // 달의 첫날 요일 구하기 (0: 일요일, 6: 토요일)
  int _getFirstDayOffset(DateTime month) {
    final firstDay = DateTime(month.year, month.month, 1);
    return firstDay.weekday % 7;
  }

  @override
  Widget build(BuildContext context) {
    // 반응형 크기 계산
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // 패딩, 폰트 크기 등을 화면 크기에 비례하여 계산
    final horizontalPadding = screenWidth * 0.04;
    final verticalPadding = screenHeight * 0.015;

    // 챌린지 상세 정보 로딩 중이면 로딩 표시
    if (_isLoadingDetail) {
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
                  child: Image.asset(
                    'assets/images/뒤로가기.png',
                    width: 24,
                    height: 24,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.arrow_back_ios,
                        size: 20,
                        color: Colors.black,
                      );
                    },
                  ),
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
              // 닫기 버튼
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.centerRight,
                  child: Image.asset(
                    'assets/icons/my/close.png',
                    width: 24,
                    height: 24,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.close,
                        size: 20,
                        color: Colors.black,
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF5D9EFF),
          ),
        ),
      );
    }
    
    // 챌린지 상세 정보 로드 실패 시 오류 표시
    if (_detailError != null) {
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
                  child: Image.asset(
                    'assets/images/뒤로가기.png',
                    width: 24,
                    height: 24,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.arrow_back_ios,
                        size: 20,
                        color: Colors.black,
                      );
                    },
                  ),
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
              // 닫기 버튼
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.centerRight,
                  child: Image.asset(
                    'assets/icons/my/close.png',
                    width: 24,
                    height: 24,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.close,
                        size: 20,
                        color: Colors.black,
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red[300],
              ),
              SizedBox(height: 16),
              Text(
                '챌린지 정보를 불러올 수 없습니다',
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'Pretendard-Medium',
                  color: Color(0xFF666666),
                ),
              ),
              SizedBox(height: 8),
              Text(
                '다시 시도해 주세요',
                style: TextStyle(
                  fontSize: 14,
                  fontFamily: 'Pretendard-Light',
                  color: Color(0xFF999999),
                ),
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  _loadChallengeDetail();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF5D9EFF),
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  '다시 시도',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontFamily: 'Pretendard-Medium',
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 기존 UI 반환
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
                child: Image.asset(
                  'assets/images/뒤로가기.png',
                  width: 24,
                  height: 24,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.arrow_back_ios,
                      size: 20,
                      color: Colors.black,
                    );
                  },
                ),
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
            // 닫기 버튼
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 24,
                height: 24,
                alignment: Alignment.centerRight,
                child: Image.asset(
                  'assets/icons/my/close.png',
                  width: 24,
                  height: 24,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.close,
                      size: 20,
                      color: Colors.black,
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.only(top: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 챌린지 정보 카드 추가
                  _buildChallengeInfoCard(screenWidth),
                  
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
                    title: "원하는 공부 시간을 선택해 주세요",
                    subtitle: "수행한 총 공부 시간을 확인할 수 있어요",
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
                      onPressed: _isLoading ? null : _handleSubmit,
                      child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
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
            
            // 로딩 오버레이
            if (_isLoading)
              Container(
                color: Colors.black.withOpacity(0.3),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF5D9EFF),
                  ),
                ),
              ),
          ],
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
          SizedBox(
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
    // 현재 표시중인 월의 연/월 문자열
    String monthYearText = '${_currentMonth.year}년 ${_currentMonth.month}월';
    
    // 날짜 범위 문자열 생성
    String dateRangeText = '';
    if (_selectedDate == _endDate) {
      dateRangeText =
          '${_selectedDate.year}년 ${_selectedDate.month}월 ${_selectedDate.day}일($_selectedDay)';
    } else {
      dateRangeText =
          '${_selectedDate.month}월 ${_selectedDate.day}일($_selectedDay) ~ ${_endDate.month}월 ${_endDate.day}일($_endDay)';
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
            // 월 이동 컨트롤 추가
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, color: Color(0xFF5C6B7F)),
                  onPressed: _goToPreviousMonth,
                ),
                Text(
                  monthYearText,
                  style: const TextStyle(
                    color: Color(0xFF202020),
                    fontSize: 16,
                    fontFamily: 'Pretendard-Medium',
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right, color: Color(0xFF5C6B7F)),
                  onPressed: _goToNextMonth,
                ),
              ],
            ),
            
            // 요일 헤더 (가로선 추가)
            Container(
              decoration: const BoxDecoration(
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

            // 달력 그리드 - 동적으로 현재 월에 맞게 계산
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1.0,
                mainAxisSpacing: 8,
                crossAxisSpacing: 0,
              ),
              itemCount: 42, // 최대 6주 표시
              itemBuilder: (context, index) {
                final int firstDayOffset = _getFirstDayOffset(_currentMonth);
                final int lastDay = _getLastDayOfMonth(_currentMonth);

                // 날짜 계산
                int dayNumber;
                bool isCurrentMonth = true;
                late DateTime currentDate; // null이 될 수 없도록 수정

                if (index < firstDayOffset) {
                  // 이전 달의 날짜들
                  final DateTime prevMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
                  final int prevMonthLastDay = _getLastDayOfMonth(prevMonth);
                  dayNumber = prevMonthLastDay - (firstDayOffset - index - 1);
                  isCurrentMonth = false;
                  currentDate = DateTime(prevMonth.year, prevMonth.month, dayNumber);
                } else if (index >= firstDayOffset + lastDay) {
                  // 다음 달의 날짜들
                  dayNumber = index - (firstDayOffset + lastDay) + 1;
                  isCurrentMonth = false;
                  final DateTime nextMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
                  currentDate = DateTime(nextMonth.year, nextMonth.month, dayNumber);
                } else {
                  // 현재 달의 날짜들
                  dayNumber = index - firstDayOffset + 1;
                  currentDate = DateTime(_currentMonth.year, _currentMonth.month, dayNumber);
                }

                if (index >= 35 && index < firstDayOffset + lastDay) {
                  // 6번째 주가 필요한 경우만 표시
                  // 5주차면 마지막 줄은 표시하지 않음
                } else if (index >= 35) {
                  return Container(); // 빈 셀
                }

                // 현재 날짜의 요일
                final int weekday = index % 7;
                final bool isSunday = (weekday == 0);

                // 날짜가 선택 범위 내에 있는지 확인
                final bool isStartDate = 
                    currentDate.year == _selectedDate.year && 
                    currentDate.month == _selectedDate.month && 
                    currentDate.day == _selectedDate.day;

                final bool isEndDate = 
                    currentDate.year == _endDate.year && 
                    currentDate.month == _endDate.month && 
                    currentDate.day == _endDate.day;

                final bool isInRange =
                    !isStartDate &&
                    !isEndDate &&
                    currentDate.isAfter(_selectedDate) &&
                    currentDate.isBefore(_endDate);

                // 날짜 버튼 생성
                return GestureDetector(
                  onTap: () {
                    // 모든 월의 날짜 선택 가능
                    _onDateSelected(currentDate);
                  },
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
        margin: const EdgeInsets.only(right: 16),
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
      periodText = '${_selectedDate.month}.${_selectedDate.day} ~ ${_endDate.month}.${_endDate.day}';
    }

    // 공부 시간을 형식에 맞게 변환
    String studyTimeText = '';
    if (_selectedDuration == '1h') {
      studyTimeText = '매일 1시간';
    } else if (_selectedDuration == '2h') {
      studyTimeText = '매일 2시간';
    } else if (_selectedDuration == '3h') {
      studyTimeText = '매일 3시간';
    } else if (_selectedDuration == '4h') {
      studyTimeText = '매일 4시간';
    } else if (_selectedDuration == '30m') {
      studyTimeText = '매일 30분';
    } else {
      studyTimeText = '매일 $_selectedDuration';
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: EdgeInsets.symmetric(horizontal: 16),
          backgroundColor: Colors.transparent,
          child: Container(
            width: 358,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Color(0x35000000),
                  blurRadius: 8,
                  offset: Offset(3, 4),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 상단 헤더
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 12), // 하단 패딩 줄임
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
                            child: Container(
                              width: 20,
                              height: 20,
                              child: Icon(
                                Icons.close,
                                size: 20,
                                color: Color(0xFF999999),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6), // 간격 줄임
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
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), // 패딩 줄임
                  decoration: BoxDecoration(color: Colors.white),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), // 패딩 줄임
                            decoration: ShapeDecoration(
                              color: const Color(0xFF5D9EFF),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: Text(
                              widget.type,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontFamily: 'Pretendard-Light',
                                letterSpacing: -0.24,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8), // 간격 줄임
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), // 패딩 줄임
                            decoration: ShapeDecoration(
                              color: const Color(0xFFFFD27F),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: Text(
                              periodText,
                              style: TextStyle(
                                color: const Color(0xFF001F55),
                                fontSize: 10,
                                fontFamily: 'Pretendard-Light',
                                letterSpacing: -0.24,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6), // 간격 줄임
                      Text(
                        widget.title,
                        style: TextStyle(
                          color: const Color(0xFF202020),
                          fontSize: 16,
                          fontFamily: 'Pretendard-Bold',
                          letterSpacing: -0.72,
                        ),
                      ),
                    ],
                  ),
                ),

                // 상세 정보
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(left: 20, right: 20, bottom: 16, top: 0), // 상단 패딩 제거, 하단 패딩 조정
                  decoration: BoxDecoration(color: Colors.white),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10), // 패딩 줄임
                    decoration: ShapeDecoration(
                      color: const Color(0xFFE7ECF6),
                      shape: RoundedRectangleBorder(
                        side: BorderSide(
                          width: 0.80,
                          color: const Color(0xFF5D9EFF),
                        ),
                        borderRadius: BorderRadius.circular(12),
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
                            const SizedBox(width: 16), // 간격 통일
                            Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: '${widget.participants.split('/')[0]}/',
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
                                      color: const Color(0xFF4A4A4A),
                                      fontSize: 12,
                                      fontFamily: 'Pretendard-Medium',
                                      letterSpacing: -0.28,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6), // 간격 줄임

                        // 공부 시간
                        Row(
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
                            const SizedBox(width: 16), // 간격 통일
                            Text(
                              studyTimeText,
                              style: TextStyle(
                                color: const Color(0xFF4A4A4A),
                                fontSize: 12,
                                fontFamily: 'Pretendard-Medium',
                                letterSpacing: -0.28,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6), // 간격 줄임

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
                            const SizedBox(width: 16), // 간격 통일
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
                  padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20, top: 0), // 상단 패딩 제거
                  decoration: ShapeDecoration(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(24),
                        bottomRight: Radius.circular(24),
                      ),
                    ),
                  ),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      // 실제 API 호출
                      _submitChallenge();
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14), // 패딩 조정
                      decoration: ShapeDecoration(
                        color: const Color(0xFF5D9EFF),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(
                        '이대로 부모님에게 전송하기',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontFamily: 'Pretendard-Light',
                          letterSpacing: -0.28,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 신청 완료 모달
  void _showCompletionModal(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: EdgeInsets.symmetric(horizontal: 16),
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            width: screenWidth * 0.9,
            constraints: BoxConstraints(
              maxWidth: 400,
              maxHeight: screenHeight * 0.4,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 상단 부분
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '챌린지 신청이 완료되었어요!',
                            style: TextStyle(
                              color: const Color(0xFF202020),
                              fontSize: 16,
                              fontFamily: 'Pretendard-Bold',
                              letterSpacing: -0.72,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.pop(context, true);
                            },
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
                        '부모님에게 대신 전송해 드릴게요!',
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
                
                // 하단 이미지 부분
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(24),
                        bottomRight: Radius.circular(24),
                      ),
                    ),
                    child: Center(
                      child: Image.asset(
                        "assets/icons/Icon/mission/phone.png",
                        height: screenHeight * 0.3,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildChallengeInfoCard(double screenWidth) {
    return Container(
      width: screenWidth - 32,
      margin: const EdgeInsets.only(bottom: 24),
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        shadows: const [
          BoxShadow(
            color: Color(0x4C000000),
            blurRadius: 12,
            offset: Offset(3, 4),
            spreadRadius: 0,
          )
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 타이틀과 확장/축소 버튼
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '신청한 챌린지 정보',
                style: TextStyle(
                  color: const Color(0xFF202020),
                  fontSize: 16,
                  fontFamily: 'Pretendard-Bold',
                  letterSpacing: -0.72,
                ),
              ),
              GestureDetector(
                onTap: _toggleChallengeInfo,
                child: AnimatedRotation(
                  turns: _isExpandedChallengeInfo ? 0.0 : 0.5,
                  duration: Duration(milliseconds: 300),
                  child: Icon(
                    Icons.keyboard_arrow_up,
                    size: 24,
                    color: Color(0xFF666666),
                  ),
                ),
              ),
            ],
          ),
          
          // 부드러운 확장/축소 효과를 위한 애니메이션
          AnimatedCrossFade(
            firstChild: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 19),
                
                // 챌린지 타입 태그
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: ShapeDecoration(
                    color: const Color(0xFFEFF2F6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(
                    widget.type,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontFamily: 'Pretendard-Light',
                      letterSpacing: -0.24,
                    ),
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // 챌린지 제목
                Text(
                  widget.title,
                  style: TextStyle(
                    color: const Color(0xFF353535),
                    fontSize: 18,
                    fontFamily: 'Pretendard-Bold',
                    letterSpacing: -0.80,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // 챌린지 정보 (한 줄에 표시)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // 참여 인원
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '참여 인원',
                          style: TextStyle(
                            color: const Color(0xFF999999),
                            fontSize: 12,
                            fontFamily: 'Pretendard-Light',
                            letterSpacing: -0.28,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text:
                                    '${widget.participants.split('/')[0]}/',
                                style: TextStyle(
                                  color: const Color(0xFF5D9EFF),
                                  fontSize: 14,
                                  fontFamily: 'Pretendard-Bold',
                                  letterSpacing: -0.28,
                                ),
                              ),
                              TextSpan(
                                text: widget.participants.split('/')[1],
                                style: TextStyle(
                                  color: const Color(0xFF666666),
                                  fontSize: 14,
                                  fontFamily: 'Pretendard-Light',
                                  letterSpacing: -0.28,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    // 기한
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '기한',
                          style: TextStyle(
                            color: const Color(0xFF999999),
                            fontSize: 12,
                            fontFamily: 'Pretendard-Light',
                            letterSpacing: -0.28,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.period,
                          style: TextStyle(
                            color: const Color(0xFF4A4A4A),
                            fontSize: 12,
                            fontFamily: 'Pretendard-Medium',
                            letterSpacing: -0.28,
                          ),
                        ),
                      ],
                    ),
                    
                    // 시간
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '시간',
                          style: TextStyle(
                            color: const Color(0xFF999999),
                            fontSize: 12,
                            fontFamily: 'Pretendard-Light',
                            letterSpacing: -0.28,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.time,
                          style: TextStyle(
                            color: const Color(0xFF4A4A4A),
                            fontSize: 12,
                            fontFamily: 'Pretendard-Medium',
                            letterSpacing: -0.28,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            secondChild: SizedBox(), // 접혔을 때는 빈 위젯
            crossFadeState: _isExpandedChallengeInfo 
              ? CrossFadeState.showFirst 
              : CrossFadeState.showSecond,
            duration: Duration(milliseconds: 300),
          ),
        ],
      ),
    );
  }
}
