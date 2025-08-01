import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../services/goal_service.dart';
import '../mission/goal/parent_goal_check_widget.dart';
import '../mission/goal/parent_goal_reward_screen.dart';

class GoalSelectionModal extends StatefulWidget {
  final List<Map<String, dynamic>> goals;
  final VoidCallback? onCheckUpdated;

  const GoalSelectionModal({
    Key? key,
    required this.goals,
    this.onCheckUpdated,
  }) : super(key: key);

  @override
  State<GoalSelectionModal> createState() => _GoalSelectionModalState();
}

class _GoalSelectionModalState extends State<GoalSelectionModal> {
  String selectedCategory = 'LEARNING'; // 기본값은 학습 인증
  Map<String, dynamic>? selectedGoal;
  bool isNotificationSet = false; // 알림 설정 상태 추가

  @override
  void initState() {
    super.initState();
    // 하단 네비게이션 바 숨기기 설정
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [SystemUiOverlay.top],
    );
    
    // 학습 인증 카테고리의 첫 번째 목표를 기본 선택
    final learningGoals = widget.goals.where((goal) => goal['category'] == 'LEARNING').toList();
    if (learningGoals.isNotEmpty) {
      selectedGoal = learningGoals.first;
    } else if (widget.goals.isNotEmpty) {
      selectedGoal = widget.goals.first;
      selectedCategory = selectedGoal!['category'] ?? 'LEARNING';
    }
  }

  @override
  void dispose() {
    // 하단 네비게이션 바 숨기기 설정으로 복원
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [SystemUiOverlay.top],
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final learningGoals = widget.goals.where((goal) => goal['category'] == 'LEARNING').toList();
    final habitGoals = widget.goals.where((goal) => goal['category'] == 'HABIT').toList();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            // 상단 앱바 (상태바 공간 포함)
            Container(
              width: double.infinity,
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: statusBarHeight + 8,
                bottom: 12,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
              ),
              child: Row(
                children: [
                  // 뒤로가기 버튼 (왼쪽 정렬)
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.centerLeft,
                      child: Icon(
                        Icons.arrow_back_ios,
                        color: Colors.black,
                        size: 20,
                      ),
                    ),
                  ),
                  
                  // 제목 (중앙 정렬)
                  Expanded(
                    child: Text(
                      '칭찬 스탬프 찍기',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 14,
                        fontFamily: 'Pretendard-Bold',
                        letterSpacing: -0.32,
                      ),
                    ),
                  ),
                  
                  // 오른쪽 공간 (균형을 위한 빈 공간)
                  SizedBox(width: 40),
                ],
              ),
            ),
            
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // 카테고리 탭
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // 학습 인증 탭
                          GestureDetector(
                            onTap: learningGoals.isNotEmpty ? () {
                              setState(() {
                                selectedCategory = 'LEARNING';
                                selectedGoal = learningGoals.first;
                              });
                            } : null,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              decoration: ShapeDecoration(
                                color: selectedCategory == 'LEARNING' 
                                    ? const Color(0xFF5D9EFF) 
                                    : const Color(0xFFF0F0F0),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(32),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    '학습 인증',
                                    style: TextStyle(
                                      color: selectedCategory == 'LEARNING' 
                                          ? Colors.white 
                                          : const Color(0xFFB6B6B6),
                                      fontSize: 12,
                                      fontFamily: 'Pretendard-Medium',
                                      letterSpacing: -0.28,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          
                          SizedBox(width: 16),
                          
                          // 습관 형성 탭
                          GestureDetector(
                            onTap: habitGoals.isNotEmpty ? () {
                              setState(() {
                                selectedCategory = 'HABIT';
                                selectedGoal = habitGoals.first;
                              });
                            } : null,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              decoration: ShapeDecoration(
                                color: selectedCategory == 'HABIT' 
                                    ? const Color(0xFF5D9EFF) 
                                    : const Color(0xFFF0F0F0),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(32),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    '습관 형성',
                                    style: TextStyle(
                                      color: selectedCategory == 'HABIT' 
                                          ? Colors.white 
                                          : const Color(0xFFB6B6B6),
                                      fontSize: 12,
                                      fontFamily: 'Pretendard-Medium',
                                      letterSpacing: -0.28,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // 메인 컨텐츠
                    if (selectedGoal != null) ...[
                      // 상단 컨텐츠
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(color: Colors.white),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 제목과 목표명
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '오늘도 ${selectedGoal!['childNickname'] ?? '자녀'}님의 칭찬 스탬프를 찍어볼까요?',
                                  style: TextStyle(
                                    color: const Color(0xFF202020),
                                    fontSize: 16,
                                    fontFamily: 'Pretendard-Bold',
                                    letterSpacing: -0.72,
                                  ),
                                ),
                                SizedBox(height: 12),
                                Text(
                                  selectedGoal!['title'] ?? '목표',
                                  style: TextStyle(
                                    color: const Color(0xFF666666),
                                    fontSize: 14,
                                    fontFamily: 'Pretendard-Light',
                                    letterSpacing: -0.32,
                                  ),
                                ),
                              ],
                            ),
                            
                            SizedBox(height: 6),
                            
                            // 진행률과 알림 설정
                            FutureBuilder<Map<String, dynamic>?>(
                              future: _getGoalCheckData(),
                              builder: (context, snapshot) {
                                final checkData = snapshot.data;
                                int checkedDays = 0;
                                
                                if (checkData != null) {
                                  for (int i = 1; i <= 7; i++) {
                                    if (GoalService.isDayChecked(checkData, i)) {
                                      checkedDays++;
                                    }
                                  }
                                }
                                
                                return Row(
                                  children: [
                                    Text(
                                      '${checkedDays}회차 성공 중',
                                      style: TextStyle(
                                        color: const Color(0xFF5D9EFF),
                                        fontSize: 22,
                                        fontFamily: 'Pretendard-Bold',
                                        letterSpacing: -0.96,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      '/ 7회차',
                                      style: TextStyle(
                                        color: const Color(0xFF8490A3),
                                        fontSize: 16,
                                        fontFamily: 'Pretendard-Light',
                                        letterSpacing: -0.72,
                                      ),
                                    ),
                                    Spacer(),
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          isNotificationSet = !isNotificationSet;
                                        });
                                      },
                                      child: isNotificationSet 
                                          ? Container(
                                              width: 80,
                                              height: 32,
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                              decoration: ShapeDecoration(
                                                color: const Color(0xFF353535),
                                                shape: RoundedRectangleBorder(
                                                  side: BorderSide(
                                                    width: 1,
                                                    color: const Color(0xFF89DA8D),
                                                  ),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                crossAxisAlignment: CrossAxisAlignment.center,
                                                children: [
                                                  Container(
                                                    width: 12,
                                                    height: 12,
                                                    clipBehavior: Clip.antiAlias,
                                                    decoration: BoxDecoration(),
                                                    child: Image.asset(
                                                      'assets/icons/parent/goal/alert_check.png',
                                                      width: 12,
                                                      height: 12,
                                                      fit: BoxFit.contain,
                                                    ),
                                                  ),
                                                  SizedBox(width: 4),
                                                  Text(
                                                    '설정 완료',
                                                    style: TextStyle(
                                                      color: const Color(0xFF89DA8D),
                                                      fontSize: 11,
                                                      fontFamily: 'Pretendard-Light',
                                                      letterSpacing: -0.22,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            )
                                          : Container(
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(8),
                                                gradient: LinearGradient(
                                                  colors: [
                                                    Color.fromRGBO(137, 218, 141, 1),
                                                    Color.fromRGBO(93, 158, 255, 1),
                                                  ],
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                ),
                                              ),
                                              child: Container(
                                                margin: EdgeInsets.all(1),
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius: BorderRadius.circular(7),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  crossAxisAlignment: CrossAxisAlignment.center,
                                                  children: [
                                                    Container(
                                                      width: 20,
                                                      height: 20,
                                                      clipBehavior: Clip.antiAlias,
                                                      decoration: BoxDecoration(),
                                                      child: Image.asset(
                                                        'assets/icons/parent/goal/alert.png',
                                                        width: 20,
                                                        height: 20,
                                                        fit: BoxFit.contain,
                                                      ),
                                                    ),
                                                    SizedBox(width: 4),
                                                    Text(
                                                      '알림 설정',
                                                      style: TextStyle(
                                                        color: const Color(0xFF89DA8D),
                                                        fontSize: 11,
                                                        fontFamily: 'Pretendard-Light',
                                                        letterSpacing: -0.22,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                    ),
                                  ],
                                );
                              },
                            ),
                            
                            SizedBox(height: 6),
                            
                            // 알림 메시지
                            Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: '매일 ',
                                    style: TextStyle(
                                      color: const Color(0xFF999999),
                                      fontSize: 12,
                                      fontFamily: 'Pretendard-Light',
                                      letterSpacing: -0.28,
                                    ),
                                  ),
                                  TextSpan(
                                    text: '저녁 6시',
                                    style: TextStyle(
                                      color: const Color(0xFF3A88F4),
                                      fontSize: 12,
                                      fontFamily: 'Pretendard-Medium',
                                      letterSpacing: -0.28,
                                    ),
                                  ),
                                  TextSpan(
                                    text: ' 잊지않게 알림을 드릴게요',
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
                          ],
                        ),
                      ),
                      
                      // 구분선
                      Container(
                        width: double.infinity,
                        height: 6,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE7ECF6),
                          border: Border.all(
                            width: 0.1,
                            color: const Color(0xFF8490A3),
                          ),
                        ),
                      ),
                      
                      // 도장 찍기 영역
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                        color: Colors.white,
                        child: Column(
                          children: [
                            // 도장 아이콘들 (요일 헤더 제거)
                            FutureBuilder<Map<String, dynamic>?>(
                              future: _getGoalCheckData(),
                              builder: (context, snapshot) {
                                final checkData = snapshot.data ?? {};
                                
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5),
                                  child: Column(
                                    children: [
                                      // 첫 번째 줄 (1일차, 2일차, 3일차, 4일차)
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          _buildStampWithLabel(1, checkData, '1일차'),
                                          _buildStampWithLabel(2, checkData, '2일차'),
                                          _buildStampWithLabel(3, checkData, '3일차'),
                                          _buildStampWithLabel(4, checkData, '4일차'),
                                        ],
                                      ),
                                      SizedBox(height: 20),
                                      // 두 번째 줄 (5일차, 6일차, 7일차, 빈공간)
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          _buildStampWithLabel(5, checkData, '5일차'),
                                          _buildStampWithLabel(6, checkData, '6일차'),
                                          _buildStampWithLabel(7, checkData, '7일차'),
                                          SizedBox(width: 68), // 빈 공간
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            
                            SizedBox(height: 24),
                            
                            // 칭찬 스탬프 찍기 버튼
                            FutureBuilder<Map<String, dynamic>?>(
                              future: _getGoalCheckData(),
                              builder: (context, snapshot) {
                                final checkData = snapshot.data ?? {};
                                final currentDay = GoalService.getCurrentDayNumber();
                                final isTodayStamped = GoalService.isDayChecked(checkData, currentDay);
                                
                                // 모든 도장 개수 계산
                                int totalStamps = 0;
                                for (int i = 1; i <= 7; i++) {
                                  if (GoalService.isDayChecked(checkData, i)) {
                                    totalStamps++;
                                  }
                                }
                                
                                // 일요일(7일차)이고 도장이 찍혔는지 확인
                                final isSunday = currentDay == 7;
                                final isSundayCompleted = isSunday && isTodayStamped;
                                
                                return GestureDetector(
                                  onTap: isSundayCompleted 
                                      ? () async {
                                          // 목표 보상 화면으로 이동
                                          final result = await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => ParentGoalRewardScreen(
                                                goal: selectedGoal!,
                                                childName: selectedGoal?['childNickname'],
                                                stampsCount: totalStamps,
                                              ),
                                            ),
                                          );
                                          
                                          if (result != null && widget.onCheckUpdated != null) {
                                            widget.onCheckUpdated!();
                                          }
                                        }
                                      : isTodayStamped 
                                          ? null // 일반 날짜에서 완료된 경우 클릭 불가
                                          : () async {  // 아직 찍지 않은 경우
                                              if (selectedGoal != null) {
                                                final currentDay = GoalService.getCurrentDayNumber();
                                                await _stampDay(currentDay);
                                              }
                                            },
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                                    decoration: BoxDecoration(
                                      color: isSundayCompleted
                                          ? const Color(0xFF4CAF50) // 일요일 완료 시 초록색
                                          : isTodayStamped 
                                              ? const Color(0xFFBBBBBB) // 일반 완료 시 회색
                                              : const Color(0xFF146AFF), // 미완료 시 파란색
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      isSundayCompleted
                                          ? '목표 보상 해주기!' // 일요일 완료 메시지
                                          : isTodayStamped 
                                              ? '오늘 칭찬 스탬프 완료!' // 일반 완료 메시지
                                              : '칭찬 스탬프 찍기', // 기본 메시지
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontFamily: 'Pretendard-Medium',
                                        letterSpacing: -0.28,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      
                      // 구분선
                      Container(
                        width: double.infinity,
                        height: 6,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE7ECF6),
                          border: Border.all(
                            width: 0.1,
                            color: const Color(0xFF8490A3),
                          ),
                        ),
                      ),
                      
                      // 설명 섹션
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        color: const Color(0xFFE4ECF8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '칭찬 스탬프는 왜 필요한가요?',
                              style: TextStyle(
                                color: const Color(0xFF202020),
                                fontSize: 12,
                                fontFamily: 'Pretendard-Medium',
                                letterSpacing: -0.28,
                              ),
                            ),
                            SizedBox(height: 12),
                            Text(
                              '리틀뱅크에서는 자녀가 매주 월요일마다 새로운 목표를 설정할 수 있도록 지원하고 있어요. 다른 미션과 챌린지와 달리, 목표는 부모님이 직접 칭찬 스탬프를 찍어 아이를 격려할 수 있도록 매일 저녁 알림을 드리고 있어요. 자녀의 꾸준한 습관 형성을 위해 부모님의 도움이 필요해요.',
                              style: TextStyle(
                                color: const Color(0xFF4A4A4A),
                                fontSize: 10,
                                fontFamily: 'Pretendard-Light',
                                height: 1.50,
                                letterSpacing: -0.24,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      // 목표가 없을 때
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(40),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.assignment_outlined,
                                size: 48,
                                color: Colors.grey[400],
                              ),
                              SizedBox(height: 16),
                              Text(
                                '선택된 카테고리에 목표가 없습니다',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                  fontFamily: 'Pretendard-Medium',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 도장 찍기 캘린더 위젯
  Widget _buildStampCalendar() {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _getGoalCheckData(),
      builder: (context, snapshot) {
        final checkData = snapshot.data ?? {};
        
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            children: [
              // 요일 헤더
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildDayHeader('월'),
                  _buildDayHeader('화'),
                  _buildDayHeader('수'),
                  _buildDayHeader('목'),
                  _buildDayHeader('금'),
                  _buildDayHeader('토'),
                  _buildDayHeader('일'),
                ],
              ),
              SizedBox(height: 16),
              
              // 도장 아이콘들
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStampIcon(1, checkData), // 월
                  _buildStampIcon(2, checkData), // 화
                  _buildStampIcon(3, checkData), // 수
                  _buildStampIcon(4, checkData), // 목
                  _buildStampIcon(5, checkData), // 금
                  _buildStampIcon(6, checkData), // 토
                  _buildStampIcon(7, checkData), // 일
                ],
              ),
              SizedBox(height: 20),
              
              Text(
                '아이가 목표를 달성한 날에 도장을 찍어주세요',
                style: TextStyle(
                  color: const Color(0xFF999999),
                  fontSize: 10,
                  fontFamily: 'Pretendard-Light',
                  letterSpacing: -0.24,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 요일 헤더
  Widget _buildDayHeader(String day) {
    Color textColor;
    if (day == '일') {
      textColor = const Color(0xFFE74C3C);
    } else if (day == '토') {
      textColor = const Color(0xFF3498DB);
    } else {
      textColor = const Color(0xFF666666);
    }
    
    return Container(
      width: 68,
      alignment: Alignment.center,
      child: Text(
        day,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontFamily: 'Pretendard-Medium',
          letterSpacing: -0.24,
        ),
      ),
    );
  }

  // 도장 아이콘
  Widget _buildStampIcon(int dayNumber, Map<String, dynamic> checkData) {
    final isChecked = GoalService.isDayChecked(checkData, dayNumber);
    final currentDay = GoalService.getCurrentDayNumber();
    final isToday = dayNumber == currentDay;
    final isSunday = dayNumber == 7; // 일요일
    final isFutureDay = dayNumber > currentDay; // 미래 날짜인지 확인
    
    return GestureDetector(
      onTap: isFutureDay ? null : () async {  // 미래 날짜면 클릭 불가
        if (selectedGoal != null) {
          await _stampDay(dayNumber);
        }
      },
      child: Container(
        width: 68,
        height: 68,
        child: Center(
          child: isSunday && isChecked
              ? Image.asset(
                  'assets/icons/parent/goal/check_fill.png',
                  width: 68,
                  height: 68,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 32,
                  ),
                )
              : isSunday
                  ? Image.asset(
                      'assets/icons/parent/goal/tropy.png',
                      width: 68,
                      height: 68,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.amber,
                        ),
                        child: Icon(Icons.emoji_events, color: Colors.white, size: 32),
                      ),
                    )
              : isChecked
                  ? Image.asset(
                      'assets/icons/parent/goal/check_fill.png',
                      width: 68,
                      height: 68,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 32,
                      ),
                    )
                  : Image.asset(
                      'assets/icons/parent/goal/check_none.png',
                      width: 68,
                      height: 68,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFDEE1E7),
                          border: Border.all(
                            color: const Color(0xFF8490A3), 
                            width: 1
                          ),
                        ),
                      ),
                    ),
        ),
      ),
    );
  }

  // 특정 날짜에 도장 찍기
  Future<void> _stampDay(int dayNumber) async {
    if (selectedGoal == null) return;
    
    try {
      final goalId = selectedGoal!['goalId'];
      if (goalId != null) {
        final result = await GoalService.stampGoalCheck(goalId, dayNumber);
        
        if (result['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${GoalService.convertNumberToDay(dayNumber)}요일 칭찬 스탬프를 찍었습니다!',
                style: TextStyle(fontFamily: 'Pretendard-Medium'),
              ),
              backgroundColor: const Color(0xFF4CAF50),
              duration: Duration(seconds: 2),
            ),
          );
          
          if (widget.onCheckUpdated != null) {
            widget.onCheckUpdated!();
          }
          
          setState(() {}); // UI 새로고침
        } else {
          throw Exception(result['message'] ?? '도장 찍기에 실패했습니다.');
        }
      }
    } catch (e) {
      print('도장 찍기 오류: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '도장 찍기 중 오류가 발생했습니다: ${e.toString().replaceAll('Exception: ', '')}',
            style: TextStyle(fontFamily: 'Pretendard-Medium'),
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  // 오늘 도장 찍기
  Future<void> _stampToday() async {
    if (selectedGoal == null) return;
    
    try {
      final goalId = selectedGoal!['goalId'];
      if (goalId != null) {
        final currentDay = GoalService.getCurrentDayNumber();
        await GoalService.stampGoalCheck(goalId, currentDay);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('칭찬 스탬프를 찍었습니다!'),
            backgroundColor: Colors.green,
          ),
        );
        
        if (widget.onCheckUpdated != null) {
          widget.onCheckUpdated!();
        }
        
        setState(() {}); // UI 새로고침
      }
    } catch (e) {
      print('도장 찍기 오류: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('도장 찍기 중 오류가 발생했습니다'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<Map<String, dynamic>?> _getGoalCheckData() async {
    if (selectedGoal == null) return null;
    
    try {
      final goalId = selectedGoal!['goalId'];
      if (goalId != null) {
        return await GoalService.getGoalCheck(goalId);
      }
    } catch (e) {
      print('목표 도장 데이터 조회 오류: $e');
    }
    return null;
  }

  // 라벨이 포함된 도장 아이콘
  Widget _buildStampWithLabel(int dayNumber, Map<String, dynamic> checkData, String label) {
    final isChecked = GoalService.isDayChecked(checkData, dayNumber);
    final currentDay = GoalService.getCurrentDayNumber();
    final isToday = dayNumber == currentDay;
    final isSunday = dayNumber == 7; // 일요일
    final isFutureDay = dayNumber > currentDay; // 미래 날짜인지 확인
    
    return GestureDetector(
      onTap: isFutureDay ? null : () async {  // 미래 날짜면 클릭 불가
        if (selectedGoal != null) {
          await _stampDay(dayNumber);
        }
      },
      child: Column(
        children: [
          Container(
            width: 68,
            height: 68,
            child: Center(
              child: isSunday && isChecked
                  ? Image.asset(
                      'assets/icons/parent/goal/check_fill.png',
                      width: 68,
                      height: 68,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 32,
                      ),
                    )
                  : isSunday
                      ? Image.asset(
                          'assets/icons/parent/goal/tropy.png',
                          width: 68,
                          height: 68,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            width: 68,
                            height: 68,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.amber,
                            ),
                            child: Icon(Icons.emoji_events, color: Colors.white, size: 32),
                          ),
                        )
                  : isChecked
                      ? Image.asset(
                          'assets/icons/parent/goal/check_fill.png',
                          width: 68,
                          height: 68,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 32,
                          ),
                        )
                      : Image.asset(
                          'assets/icons/parent/goal/check_none.png',
                          width: 68,
                          height: 68,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            width: 68,
                            height: 68,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFDEE1E7),
                              border: Border.all(
                                color: const Color(0xFF8490A3), 
                                width: 1
                              ),
                            ),
                          ),
                        ),
            ),
          ),
          SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: const Color(0xFF999999),
              fontSize: 11,
              fontFamily: 'Pretendard-Light',
              letterSpacing: -0.24,
            ),
          ),
        ],
      ),
    );
  }
} 