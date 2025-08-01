import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../screens/child/goal_setting_screen.dart';
import '../screens/child/goal_edit_screen.dart';
import '../services/goal_service.dart';

class SharedWeeklyGoalWidget extends StatefulWidget {
  final Map<String, dynamic>? weeklyGoal;
  final Function(Map<String, dynamic>)? onGoalUpdated;
  final bool usePretendard;
  final Function(bool)? onToggleGoalStatus;

  const SharedWeeklyGoalWidget({
    super.key,
    this.weeklyGoal,
    this.onGoalUpdated,
    this.usePretendard = false,
    this.onToggleGoalStatus,
  });

  @override
  State<SharedWeeklyGoalWidget> createState() => _SharedWeeklyGoalWidgetState();
}

class _SharedWeeklyGoalWidgetState extends State<SharedWeeklyGoalWidget> {
  List<Map<String, dynamic>> _weeklyGoals = [];
  bool _isLoading = true;
  String? _error;
  
  // 각 목표의 도장 확인 데이터를 캐시하기 위한 맵
  Map<int, Map<String, dynamic>?> _goalCheckCache = {};

  @override
  void initState() {
    super.initState();
    _loadWeeklyGoals();
  }

  // 이번 주 목표 조회 (신청한 목표 포함)
  Future<void> _loadWeeklyGoals() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      print('===== 아이 이번 주 목표 조회 시작 (신청한 목표 포함) =====');

      // 모든 목표를 조회한 후 이번 주에 해당하는 목표들만 필터링
      final allGoals = await GoalService.getChildAllGoals();

      if (allGoals != null) {
        // 이번 주에 해당하는 목표들만 필터링
        final weeklyGoals = _filterThisWeekGoals(allGoals);
        
        // 각 목표의 도장 확인 데이터 미리 로드
        await _loadGoalCheckData(weeklyGoals);
        
        setState(() {
          _weeklyGoals = weeklyGoals;
          _isLoading = false;
        });

        print('아이 전체 목표 ${allGoals.length}개 조회 성공');
        print('이번 주 목표 ${weeklyGoals.length}개 필터링 완료');
        if (weeklyGoals.isNotEmpty) {
          print('첫 번째 이번 주 목표: ${weeklyGoals[0]}');
        }
      } else {
        setState(() {
          _weeklyGoals = [];
          _isLoading = false;
          _error = '목표를 불러올 수 없습니다';
        });
      }

      print('===== 아이 이번 주 목표 조회 완료 =====');
    } catch (e) {
      print('아이 이번 주 목표 조회 중 오류: $e');
      setState(() {
        _weeklyGoals = [];
        _isLoading = false;
        _error = '목표 조회 중 오류가 발생했습니다';
      });
    }
  }

  // 각 목표의 도장 확인 데이터를 미리 로드
  Future<void> _loadGoalCheckData(List<Map<String, dynamic>> goals) async {
    print('===== 도장 확인 데이터 로드 시작 =====');
    _goalCheckCache.clear();
    
    for (var goal in goals) {
      final int? goalId = goal['goalId'];
      if (goalId != null) {
        try {
          final checkData = await GoalService.getGoalCheck(goalId);
          _goalCheckCache[goalId] = checkData;
          print('목표 ${goal['title']} (ID: $goalId)의 도장 확인 데이터 로드 완료: $checkData');
        } catch (e) {
          print('목표 ${goal['title']} (ID: $goalId)의 도장 확인 데이터 로드 실패: $e');
          _goalCheckCache[goalId] = null;
        }
      }
    }
    print('===== 도장 확인 데이터 로드 완료 =====');
  }

  // 오늘 날짜의 도장 여부 확인
  bool _isTodayChecked(int? goalId) {
    if (goalId == null) return false;
    
    final checkData = _goalCheckCache[goalId];
    if (checkData == null) return false;
    
    final now = DateTime.now();
    final todayDayNumber = now.weekday; // 1=월요일, 7=일요일
    
    final bool isChecked = GoalService.isDayChecked(checkData, todayDayNumber);
    print('목표 ID $goalId, 오늘(${todayDayNumber}요일) 도장 여부: $isChecked');
    
    return isChecked;
  }

  // 이번 주에 해당하는 목표들만 필터링하는 함수
  List<Map<String, dynamic>> _filterThisWeekGoals(List<Map<String, dynamic>> allGoals) {
    final now = DateTime.now();
    
    print('현재 날짜: ${now.toString().split(' ')[0]}');

    // 진행 중이거나 신청한 목표들만 필터링 (완료된 목표 제외)
    final filteredGoals = allGoals.where((goal) {
      try {
        final String status = goal['status'] ?? '';
        
        // 완료된 목표는 제외
        if (status == 'ACHIEVEMENT') {
          return false;
        }

        // REQUESTED 상태인 목표는 날짜에 관계없이 모두 포함
        if (status == 'REQUESTED') {
          print('신청 상태 목표 포함: ${goal['title']} (${status})');
          return true;
        }

        // ACCEPT 상태인 목표는 현재 진행 중인지 확인
        if (status == 'ACCEPT') {
          final String? startDateStr = goal['startDate'];
          final String? endDateStr = goal['endDate'];
          
          if (startDateStr == null || endDateStr == null) {
            print('날짜 정보가 없는 목표 제외: ${goal['title']}');
            return false;
          }

          try {
            final DateTime startDate = DateTime.parse(startDateStr.split('T')[0]);
            final DateTime endDate = DateTime.parse(endDateStr.split('T')[0]);
            
            // 현재 날짜가 목표 기간 내에 있거나, 목표 시작일이 1주일 이내인 경우 포함
            final bool isActive = (now.isAfter(startDate.subtract(Duration(days: 1))) && 
                                 now.isBefore(endDate.add(Duration(days: 1)))) ||
                                (startDate.difference(now).inDays <= 7 && startDate.difference(now).inDays >= 0);
            
            if (isActive) {
              print('진행 중 목표 포함: ${goal['title']} (${status}) - 기간: ${startDate.toString().split(' ')[0]} ~ ${endDate.toString().split(' ')[0]}');
            } else {
              print('기간이 지난 목표 제외: ${goal['title']} (${status}) - 기간: ${startDate.toString().split(' ')[0]} ~ ${endDate.toString().split(' ')[0]}');
            }
            
            return isActive;
          } catch (e) {
            print('날짜 파싱 오류: $e, 목표: ${goal['title']}');
            return false;
          }
        }

        // 기타 상태는 제외
        return false;
      } catch (e) {
        print('목표 필터링 오류: $e, 목표 데이터: $goal');
        return false;
      }
    }).toList();

    // 진행 중 > 요청 중 순서로 정렬
    filteredGoals.sort((a, b) {
      final String statusA = a['status'] ?? '';
      final String statusB = b['status'] ?? '';
      
      // 우선순위: ACCEPT (진행 중) > REQUESTED (요청 중)
      int priorityA = _getStatusPriority(statusA);
      int priorityB = _getStatusPriority(statusB);
      
      if (priorityA != priorityB) {
        return priorityA.compareTo(priorityB); // 낮은 숫자가 우선순위 높음
      }
      
      // 같은 상태이면 제목 순으로 정렬
      final String titleA = a['title'] ?? '';
      final String titleB = b['title'] ?? '';
      return titleA.compareTo(titleB);
    });

    print('필터링된 목표 ${filteredGoals.length}개:');
    for (var goal in filteredGoals) {
      final String status = goal['status'] ?? '';
      final String startDate = goal['startDate']?.toString().split('T')[0] ?? 'N/A';
      print('  - ${goal['title']} (${status}) - 시작일: $startDate');
    }

    return filteredGoals;
  }

  // 상태별 우선순위 반환 (낮은 숫자가 높은 우선순위)
  int _getStatusPriority(String status) {
    switch (status) {
      case 'ACCEPT':
        return 1; // 진행 중 (최우선)
      case 'REQUESTED':
        return 2; // 요청 중
      default:
        return 3; // 기타
    }
  }

  // 목표 아이템 위젯 생성
  Widget _buildGoalItem(Map<String, dynamic> goal, int index) {
    final String title = goal['title'] ?? '목표 없음';
    final String category = goal['category'] ?? 'LEARNING';
    final String status = goal['status'] ?? '';
    final int reward = goal['reward'] ?? 0;
    final int? goalId = goal['goalId'];
    
    // 상태에 따른 텍스트와 색상 결정
    final String statusText = GoalService.getGoalStatusText(goal);
    final Color statusColor = GoalService.getGoalStatusColor(goal);
    final String categoryText = GoalService.getCategoryText(category);
    
    // 상태에 따른 체크 아이콘 색상 (오늘 도장 여부 고려)
    Color? checkIconColor;
    if (status == 'REQUESTED') {
      checkIconColor = const Color(0xFFE5E5E5); // 비활성화
    } else if (status == 'ACCEPT') {
      // 오늘 도장을 받았는지 확인
      final bool todayChecked = _isTodayChecked(goalId);
      if (todayChecked) {
        checkIconColor = null; // 도장 받음 - 원본 색상
      } else {
        checkIconColor = const Color(0xFFE5E5E5); // 도장 안받음 - 회색
      }
    } else if (status == 'ACHIEVEMENT') {
      checkIconColor = const Color(0xFF4CAF50); // 완료 색상
    } else {
      checkIconColor = const Color(0xFFE5E5E5); // 기본 회색
    }

    return Column(
      children: [
        // 구분선 (첫 번째 아이템이 아닌 경우)
        if (index > 0)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Divider(
              height: 1,
              thickness: 1,
              color: Colors.grey.withOpacity(0.1),
            ),
          ),
        
        Container(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 상태 및 카테고리 태그
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontFamily: 'Pretendard-Light',
                          letterSpacing: -0.1,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD27F),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        categoryText,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontFamily: 'Pretendard-Light',
                          letterSpacing: -0.1,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // 목표 내용과 화살표
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Text(
                                  title,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: const Color(0xFF353535),
                                    fontFamily: 'Pretendard-Bold',
                                    letterSpacing: -0.2,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8), // 제목과 아이콘 간 간격
                              // 수정 아이콘 추가
                              if (status == 'REQUESTED') // 신청 상태일 때만 수정 아이콘 표시
                                GestureDetector(
                                  onTap: () => _showGoalActionMenu(context, goal),
                                  child: Icon(
                                    Icons.more_vert,
                                    size: 18,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              const SizedBox(width: 8), // 수정 아이콘과 화살표/체크 아이콘 간 간격
                              Image.asset(
                                'assets/icons/Icon/mission/목표_들어가기.png',
                                width: 24,
                                height: 24,
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '보상: ${reward.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}원',
                            style: TextStyle(
                              fontSize: 10,
                              color: const Color(0xFF666666),
                              fontFamily: 'Pretendard-Light',
                              letterSpacing: -0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    // 체크 아이콘 - 방향표와 같은 높이에 정렬
                    Padding(
                      padding: const EdgeInsets.only(top: 0), // 방향표와 같은 높이
                      child: GestureDetector(
                        onTap: () => _showGoalCheckModal(context, goal['goalId']),
                        child: Image.asset(
                          'assets/icons/Icon/mission/체크서클.png',
                          width: 24,
                          height: 24,
                          color: checkIconColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 목표가 하나만 있을 때 빈 칸 추가
  Widget _buildEmptyGoalSlot() {
    // 현재 없는 카테고리 찾기
    final Set<String> existingCategories = _weeklyGoals.map((goal) => goal['category'] as String? ?? '').toSet();
    
    String missingCategoryText = '';
    if (!existingCategories.contains('HABIT')) {
      missingCategoryText = '생활 습관 목표가 없습니다';
    } else if (!existingCategories.contains('LEARNING')) {
      missingCategoryText = '학습 인증 목표가 없습니다';
    } else {
      missingCategoryText = '목표를 세워주세요';
    }
    
    return Column(
      children: [
        // 구분선
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Divider(
            height: 1,
            thickness: 1,
            color: Colors.grey.withOpacity(0.1),
          ),
        ),
        
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: ShapeDecoration(
              color: const Color(0xFFE4ECF8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  child: Image.asset(
                    'assets/icons/parent/goal/half_goal.png',
                    width: 20,
                    height: 20,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(
                        Icons.assignment_outlined,
                        size: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Flexible(
                  child: Text(
                    missingCategoryText,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: const Color(0xFF666666),
                      fontSize: 10,
                      fontFamily: 'Pretendard-Medium',
                      letterSpacing: -0.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const GoalSettingScreen(),
                      ),
                    );
                    if (result != null) {
                      _loadWeeklyGoals(); // 목표 설정 후 새로고침
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: ShapeDecoration(
                      color: const Color(0xFF3A88F4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                    child: Text(
                      '목표 세우러가기',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontFamily: 'Pretendard-Light',
                        letterSpacing: -0.16,
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

  // 목표 확인 모달 표시 함수
  void _showGoalCheckModal(BuildContext context, [int? goalId]) async {
    Map<String, dynamic>? checkData;
    bool isLoading = true;
    
    // goalId가 있으면 도장 확인 API 호출
    if (goalId != null) {
      try {
        checkData = await GoalService.getGoalCheck(goalId);
        print('도장 확인 데이터: $checkData');
      } catch (e) {
        print('도장 확인 데이터 조회 실패: $e');
        // API 호출 실패 시에도 빈 데이터로 처리 (모든 날짜가 X로 표시됨)
        checkData = {
          'goalId': goalId,
          'mon': false,
          'tue': false,
          'wed': false,
          'thu': false,
          'fri': false,
          'sat': false,
          'sun': false,
        };
      }
    } else {
      // goalId가 없는 경우 기본 빈 데이터
      checkData = {
        'goalId': 0,
        'mon': false,
        'tue': false,
        'wed': false,
        'thu': false,
        'fri': false,
        'sat': false,
        'sun': false,
      };
    }
    
    isLoading = false;
    
    // 바텀시트 대신 다이얼로그로 표시
    showDialog(
      context: context,
      barrierColor: Colors.transparent, // 배경색 투명하게 설정
      builder: (context) {
        return Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            width: MediaQuery.of(context).size.width,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.3,
            ),
            margin: EdgeInsets.only(bottom: 80), // 네비게이션 바 공간 확보
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 상단 섹션 (헤더와 X 버튼)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 텍스트 부분 (왼쪽 정렬)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '이번 주 나의 목표 확인받기',
                              style: TextStyle(
                                color: const Color(0xFF202020),
                                fontSize: 14, // 폰트 크기 축소
                                fontFamily: 'Pretendard-Bold',
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _getCheckStatusMessage(checkData),
                              style: TextStyle(
                                color: const Color(0xFF999999),
                                fontSize: 12, // 폰트 크기 축소
                                fontFamily: 'Pretendard-Light',
                                letterSpacing: -0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // X 닫기 버튼 (배경색 제거)
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Icon(
                          Icons.close,
                          size: 20,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // 하단 섹션 (달력)
                Flexible(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 구분선 1 (요일 위)
                          Container(
                            height: 1,
                            color: const Color(0xFF8490A3).withOpacity(0.4),
                          ),
                          const SizedBox(height: 12),
                          
                          // 요일 표시 행 (월화수목금토일 순서)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildDayText('월'),
                              _buildDayText('화'),
                              _buildDayText('수'),
                              _buildDayText('목'),
                              _buildDayText('금'),
                              _buildDayText('토'),
                              _buildDayText('일', isRed: true),
                            ],
                          ),
                          const SizedBox(height: 12),
                          
                          // 구분선 2 (요일 아래)
                          Container(
                            height: 1,
                            color: const Color(0xFF8490A3).withOpacity(0.4),
                          ),
                          const SizedBox(height: 12),
                          
                          // 날짜 표시 행 (실제 도장 확인 데이터 반영)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildDateCircleWithCheck(1, checkData), // 월요일
                              _buildDateCircleWithCheck(2, checkData), // 화요일
                              _buildDateCircleWithCheck(3, checkData), // 수요일
                              _buildDateCircleWithCheck(4, checkData), // 목요일
                              _buildDateCircleWithCheck(5, checkData), // 금요일
                              _buildDateCircleWithCheck(6, checkData), // 토요일
                              _buildDateCircleWithCheck(7, checkData), // 일요일
                            ],
                          ),
                        ],
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

  // 도장 확인 상태 메시지 생성
  String _getCheckStatusMessage(Map<String, dynamic>? checkData) {
    if (checkData == null) {
      return '부모님 확인 대기 중';
    }
    
    // 체크된 날짜 개수 계산
    int checkedDays = 0;
    for (int i = 1; i <= 7; i++) {
      if (GoalService.isDayChecked(checkData, i)) {
        checkedDays++;
      }
    }
    
    if (checkedDays == 0) {
      return '부모님 확인 대기 중';
    } else if (checkedDays == 7) {
      return '부모님이 모든 날을 확인했어요';
    } else {
      return '부모님이 ${checkedDays}일 확인했어요';
    }
  }

  // 요일 표시 위젯
  Widget _buildDayText(String day, {bool isRed = false}) {
    return Text(
      day,
      style: TextStyle(
        color: isRed ? const Color(0xFFFF6062) : const Color(0xFF5C6B7F),
        fontSize: 14,
        fontFamily: 'Pretendard-Regular',
      ),
    );
  }

  // 날짜 원형 위젯
  Widget _buildDateCircle(String date, {bool isRed = false}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          date,
          style: TextStyle(
            color: isRed ? const Color(0xFFFF6062) : const Color(0xFF5C6B7F),
            fontSize: 12,
            fontFamily: 'Pretendard-Regular',
          ),
        ),
        const SizedBox(height: 4),
        Image.asset(
          'assets/icons/Icon/mission/체크서클.png',
          width: 24,
          height: 24,
        ),
      ],
    );
  }

  // 완료된 날짜 박스 위젯
  Widget _buildCompletedDateBox(String date) {
    return Container(
      width: 32,
      padding: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF2F6),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          width: 0.4,
          color: const Color(0xFF5D9EFF),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            date,
            style: TextStyle(
              color: const Color(0xFF5C6B7F),
              fontSize: 12,
              fontFamily: 'Pretendard-Regular',
            ),
          ),
          const SizedBox(height: 2),
          Stack(
            alignment: Alignment.center,
            children: [
              Image.asset(
                'assets/icons/Icon/mission/완료.png',
                width: 24,
                height: 24,
              ),
              Positioned(
                child: Text(
                  '완료',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontFamily: 'Pretendard-Light',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 도장 확인 데이터를 반영한 날짜 위젯
  Widget _buildDateCircleWithCheck(int dayNumber, Map<String, dynamic>? checkData) {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final targetDate = weekStart.add(Duration(days: dayNumber - 1));
    final dateString = targetDate.day.toString();
    
    // 도장이 찍혔는지 확인
    bool isChecked = false;
    if (checkData != null) {
      isChecked = GoalService.isDayChecked(checkData, dayNumber);
    }
    
    // 오늘 날짜인지 확인
    final bool isToday = targetDate.year == now.year && 
                        targetDate.month == now.month && 
                        targetDate.day == now.day;
    
    // 일요일인지 확인
    bool isRed = dayNumber == 7;
    
    // 체크 아이콘 색상 결정
    Color? checkIconColor;
    if (isChecked) {
      checkIconColor = null; // 체크되면 원본 색상
    } else if (isToday) {
      checkIconColor = const Color(0xFFE5E5E5); // 오늘인데 체크 안됨 - 회색
    } else {
      checkIconColor = const Color(0xFFE5E5E5); // 다른 날이고 체크 안됨 - 회색
    }
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          dateString,
          style: TextStyle(
            color: isRed ? const Color(0xFFFF6062) : const Color(0xFF5C6B7F),
            fontSize: 12,
            fontFamily: 'Pretendard-Regular',
          ),
        ),
        const SizedBox(height: 4),
        Image.asset(
          'assets/icons/Icon/mission/체크서클.png',
          width: 24,
          height: 24,
          color: checkIconColor,
        ),
      ],
    );
  }

  // 목표 수정/삭제 메뉴 표시 함수
  void _showGoalActionMenu(BuildContext context, Map<String, dynamic> goal) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 상단 헤더
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '목표 관리',
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: 'Pretendard-Bold',
                        color: Color(0xFF202020),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Icon(
                        Icons.close,
                        size: 20,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              
              // 구분선
              Divider(height: 1, color: Colors.grey[200]),
              
              // 수정하기 옵션
              ListTile(
                leading: Icon(
                  Icons.edit_outlined,
                  color: Color(0xFF5D9EFF),
                  size: 20,
                ),
                title: Text(
                  '수정하기',
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: 'Pretendard-Medium',
                    color: Color(0xFF202020),
                  ),
                ),
                onTap: () async {
                  Navigator.pop(context); // 바텀시트 닫기
                  
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => GoalEditScreen(initialGoalData: goal),
                    ),
                  );
                  
                  if (result == true && widget.onGoalUpdated != null) {
                    widget.onGoalUpdated!(goal);
                    _loadWeeklyGoals();
                  }
                },
              ),
              
              // 삭제하기 옵션
              ListTile(
                leading: Icon(
                  Icons.delete_outline,
                  color: Colors.red[400],
                  size: 20,
                ),
                title: Text(
                  '삭제하기',
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: 'Pretendard-Medium',
                    color: Colors.red[400],
                  ),
                ),
                onTap: () {
                  Navigator.pop(context); // 바텀시트 닫기
                  _showDeleteConfirmDialog(context, goal);
                },
              ),
              
              // 하단 여백
              SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  // 삭제 확인 다이얼로그 표시 함수
  void _showDeleteConfirmDialog(BuildContext context, Map<String, dynamic> goal) {
    final String title = goal['title'] ?? '목표';
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            '목표 삭제',
            style: TextStyle(
              fontSize: 16,
              fontFamily: 'Pretendard-Bold',
              color: Color(0xFF202020),
            ),
          ),
          content: Text(
            '"$title" 목표를 삭제하시겠습니까?\n\n삭제된 목표는 복구할 수 없습니다.',
            style: TextStyle(
              fontSize: 14,
              fontFamily: 'Pretendard-Medium',
              color: Color(0xFF666666),
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                '취소',
                style: TextStyle(
                  fontSize: 14,
                  fontFamily: 'Pretendard-Medium',
                  color: Colors.grey[600],
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context); // 다이얼로그 닫기
                await _deleteGoal(goal);
              },
              child: Text(
                '삭제',
                style: TextStyle(
                  fontSize: 14,
                  fontFamily: 'Pretendard-Medium',
                  color: Colors.red[400],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // 목표 삭제 실행 함수
  Future<void> _deleteGoal(Map<String, dynamic> goal) async {
    final int? goalId = goal['goalId'];
    final String title = goal['title'] ?? '목표';
    
    if (goalId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('목표 ID가 없습니다.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // 로딩 표시
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return Center(
            child: CircularProgressIndicator(
              color: Color(0xFF5D9EFF),
            ),
          );
        },
      );

      // 목표 삭제 API 호출
      final result = await GoalService.deleteGoal(goalId);
      
      // 로딩 다이얼로그 닫기
      Navigator.pop(context);

      if (result['success'] == true) {
        // 성공 메시지 표시
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"$title" 목표가 삭제되었습니다.'),
            backgroundColor: Colors.green,
          ),
        );
        
        // 목표 목록 새로고침
        _loadWeeklyGoals();
        
        // 부모 위젯에 변경 알림
        if (widget.onGoalUpdated != null) {
          widget.onGoalUpdated!(goal);
        }
      } else {
        throw Exception(result['message'] ?? '목표 삭제에 실패했습니다.');
      }
    } catch (e) {
      // 로딩 다이얼로그가 열려 있다면 닫기
      try {
        Navigator.pop(context);
      } catch (_) {}
      
      // 에러 메시지 표시
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 3,
      shadowColor: Colors.black54,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.all(0),
        width: MediaQuery.of(context).size.width - 16,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상단 헤더 부분
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '이번 주 나의 목표',
                    style: TextStyle(
                      fontSize: 16,
                      color: const Color(0xFF202020),
                      fontFamily: 'Pretendard-Bold',
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '단기적인 목표로 소소한 용돈 벌기',
                    style: TextStyle(
                      fontSize: 12,
                      color: const Color(0xFF999999),
                      fontFamily: 'Pretendard-Light',
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ),

            // 로딩 상태 처리
            if (_isLoading)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF5D9EFF),
                  ),
                ),
              )
            else if (_error != null)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Column(
                    children: [
                      Text(
                        _error!,
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 14,
                          fontFamily: 'Pretendard-Medium',
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _loadWeeklyGoals,
                        child: Text('다시 시도'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF5D9EFF),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if (_weeklyGoals.isNotEmpty)
              // 목표 목록 표시
              ...[
                ..._weeklyGoals.asMap().entries.map((entry) {
                  final index = entry.key;
                  final goal = entry.value;
                  return _buildGoalItem(goal, index);
                }).toList(),
                // 목표가 하나만 있을 때 빈 칸 추가
                if (_weeklyGoals.length == 1)
                  _buildEmptyGoalSlot(),
              ]
            else
              // 목표가 없을 때 표시할 UI
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Center(
                      child: Image.asset(
                        'assets/icons/Icon/mission/target.png',
                        width: 180,
                        height: 180,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Center(
                      child: GestureDetector(
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const GoalSettingScreen(),
                            ),
                          );
                          if (result != null) {
                            _loadWeeklyGoals(); // 목표 설정 후 새로고침
                          }
                        },
                        child: Container(
                          width: 318,
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                          decoration: ShapeDecoration(
                            color: const Color(0xFF3A88F4),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                '목표 세우러 가기',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontFamily: 'Pretendard-Light',
                                  letterSpacing: -0.28,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
