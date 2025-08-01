import 'package:flutter/material.dart';
import '../../../../services/goal_service.dart';
import '../../create_post_screen.dart';
import '../../goal_setting_screen.dart';

class GoalHistoryTab extends StatefulWidget {
  const GoalHistoryTab({Key? key}) : super(key: key);

  @override
  State<GoalHistoryTab> createState() => _GoalHistoryTabState();
}

class _GoalHistoryTabState extends State<GoalHistoryTab> {
  bool _isGoalInProgress = true;
  
  // 목표 데이터 관련 상태
  List<Map<String, dynamic>> _goalList = [];
  bool _isGoalLoading = false;
  String? _goalError;
  
  // 전체 데이터 확인을 위한 상태
  bool _hasOngoingGoals = false;
  bool _hasCompletedGoals = false;
  bool _hasCheckedAllData = false;

  @override
  void initState() {
    super.initState();
    _loadGoalData();
  }

  // 목표 데이터 로드
  Future<void> _loadGoalData() async {
    setState(() {
      _isGoalLoading = true;
      _goalError = null;
    });

    try {
      final weeklyGoals = await GoalService.getChildWeeklyGoals();
      
      if (weeklyGoals != null) {
        List<Map<String, dynamic>> filteredGoals;
        
        if (_isGoalInProgress) {
          filteredGoals = weeklyGoals.where((goal) => 
            goal['status'] == 'ACCEPT'
          ).toList();
        } else {
          filteredGoals = weeklyGoals.where((goal) => 
            goal['status'] == 'ACHIEVEMENT'
          ).toList();
        }
        
        // 각 목표에 대해 도장 정보도 함께 가져오기
        for (var goal in filteredGoals) {
          final goalId = goal['goalId'];
          if (goalId != null) {
            try {
              final checkData = await GoalService.getGoalCheck(goalId);
              if (checkData != null) {
                goal['goalCheck'] = checkData;
              }
            } catch (e) {
              print('목표 $goalId의 도장 데이터 로드 실패: $e');
            }
          }
        }
        
        setState(() {
          _goalList = filteredGoals;
          _isGoalLoading = false;
        });
        
        // 전체 데이터 확인
        _checkAllGoalData(weeklyGoals);
      } else {
        setState(() {
          _goalList = [];
          _isGoalLoading = false;
          _hasOngoingGoals = false;
          _hasCompletedGoals = false;
          _hasCheckedAllData = true;
        });
      }
    } catch (e) {
      setState(() {
        _goalError = e.toString();
        _isGoalLoading = false;
      });
    }
  }

  // 전체 목표 데이터 확인
  void _checkAllGoalData(List<Map<String, dynamic>> allGoals) {
    if (_hasCheckedAllData) return;
    
    final ongoingGoals = allGoals.where((goal) => goal['status'] == 'ACCEPT').toList();
    final completedGoals = allGoals.where((goal) => goal['status'] == 'ACHIEVEMENT').toList();
    
    setState(() {
      _hasOngoingGoals = ongoingGoals.isNotEmpty;
      _hasCompletedGoals = completedGoals.isNotEmpty;
      _hasCheckedAllData = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 전체 데이터가 없는 경우 빈 상태 화면만 표시
    if (_hasCheckedAllData && !_hasOngoingGoals && !_hasCompletedGoals) {
      return SingleChildScrollView(
        padding: EdgeInsets.zero,
        child: _buildEmptyGoalState(),
      );
    }
    
    // 데이터가 있거나 로딩 중이거나 에러가 있을 때는 전체 레이아웃 표시
    return SingleChildScrollView(
      padding: EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 완료한 목표 알림 섹션
          _buildCompletedGoalSection(),
          
          const SizedBox(height: 0),
          
          // 목표 필터 섹션
          _buildFilterSection(),
          
          const SizedBox(height: 6),
          
          // 목표 목록 섹션
          _buildGoalListSection(),
        ],
      ),
    );
  }

  // 완료한 목표 알림 섹션
  Widget _buildCompletedGoalSection() {
    final hasCompletedGoal = !_isGoalInProgress && _goalList.isNotEmpty;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF3A88F4), Color(0xFF11CB86)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            hasCompletedGoal
                ? '최근에 완료한 목표가 있네요!\n피드에 자랑해 볼까요?'
                : '진행 중인 목표가 있네요!\n열심히 달성해 보세요!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontFamily: 'Pretendard-Bold',
              height: 1.3,
            ),
          ),
          
          const SizedBox(height: 12),
          
          if (_goalList.isNotEmpty)
            GestureDetector(
              onTap: hasCompletedGoal ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CreatePostScreen(),
                  ),
                );
              } : null,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: ShapeDecoration(
                  gradient: LinearGradient(
                    begin: Alignment(0.03, 0.00),
                    end: Alignment(1.00, 1.00),
                    colors: [
                      Colors.white.withOpacity(0.6),
                      Colors.white.withOpacity(0.3),
                    ],
                  ),
                  shape: RoundedRectangleBorder(
                    side: BorderSide(width: 0.40, color: Colors.white),
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              _goalList.isNotEmpty ? _goalList.first['title'] : '목표 없음',
                              style: TextStyle(
                                color: const Color(0xFF353535),
                                fontSize: 14,
                                fontFamily: 'Pretendard-Bold',
                                letterSpacing: -0.32,
                              ),
                            ),
                          ),
                          if (hasCompletedGoal)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '피드 작성하기',
                                  style: TextStyle(
                                    color: const Color(0xFF666666),
                                    fontSize: 10,
                                    fontFamily: 'Pretendard-Light',
                                    letterSpacing: -0.24,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Icon(
                                  Icons.edit_outlined,
                                  size: 16,
                                  color: const Color(0xFF666666),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Divider(
                        height: 1,
                        thickness: 0.5,
                        color: Color.fromRGBO(160, 160, 160, 0.9),
                      ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _goalList.isNotEmpty 
                                    ? _formatGoalDatePeriod(_goalList.first['startDate'], _goalList.first['endDate'])
                                    : '날짜 정보 없음',
                                style: TextStyle(
                                  color: const Color(0xFF4A4A4A),
                                  fontSize: 12,
                                  fontFamily: 'Pretendard-Light',
                                  letterSpacing: -0.28,
                                ),
                              ),
                              SizedBox(width: 8),
                              Text(
                                _goalList.isNotEmpty 
                                    ? _calculateGoalAchievementRate(_goalList.first)
                                    : '0%',
                                style: TextStyle(
                                  color: const Color(0xFF4A4A4A),
                                  fontSize: 12,
                                  fontFamily: 'Pretendard-Light',
                                  letterSpacing: -0.28,
                                ),
                              ),
                            ],
                          ),
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: _goalList.isNotEmpty 
                                      ? _formatNumber(_goalList.first['reward'] ?? 0)
                                      : '0',
                                  style: TextStyle(
                                    color: const Color(0xFF146AFF),
                                    fontSize: 14,
                                    fontFamily: 'Pretendard-Bold',
                                    letterSpacing: -0.32,
                                  ),
                                ),
                                TextSpan(
                                  text: '원',
                                  style: TextStyle(
                                    color: const Color(0xFF000000),
                                    fontSize: 14,
                                    fontFamily: 'Pretendard-Medium',
                                    letterSpacing: -0.32,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // 필터 섹션
  Widget _buildFilterSection() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            offset: Offset(0, 4),
            blurRadius: 10,
            spreadRadius: 0,
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                _isGoalInProgress = true;
              });
              _loadGoalData();
            },
            child: Container(
              height: 36,
              width: 70,
              decoration: BoxDecoration(
                color: _isGoalInProgress ? const Color(0xFF3A88F4) : const Color(0xFFDEDEDE),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(_isGoalInProgress ? 0.15 : 0.1),
                    offset: Offset(0, 2),
                    blurRadius: 4,
                    spreadRadius: 0,
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                '진행중',
                style: TextStyle(
                  color: _isGoalInProgress ? Colors.white : const Color(0xFF999999),
                  fontSize: 12,
                  fontFamily: _isGoalInProgress ? 'Pretendard-Light' : 'Pretendard-ExtraLight',
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          GestureDetector(
            onTap: () {
              setState(() {
                _isGoalInProgress = false;
              });
              _loadGoalData();
            },
            child: Container(
              height: 36,
              width: 70,
              decoration: BoxDecoration(
                color: !_isGoalInProgress ? const Color(0xFF3A88F4) : const Color(0xFFDEDEDE),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(!_isGoalInProgress ? 0.15 : 0.1),
                    offset: Offset(0, 2),
                    blurRadius: 4,
                    spreadRadius: 0,
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                '완료한',
                style: TextStyle(
                  color: !_isGoalInProgress ? Colors.white : const Color(0xFF999999),
                  fontSize: 12,
                  fontFamily: !_isGoalInProgress ? 'Pretendard-Light' : 'Pretendard-ExtraLight',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 목표 목록 섹션
  Widget _buildGoalListSection() {
    if (_isGoalLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF3A88F4),
          ),
        ),
      );
    }
    
    if (_goalError != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
        child: Center(
          child: Column(
            children: [
              Text(
                '목표를 불러오는 중 오류가 발생했습니다.',
                style: TextStyle(
                  color: Color(0xFF999999),
                  fontSize: 14,
                  fontFamily: 'Pretendard-Light',
                ),
              ),
              SizedBox(height: 8),
              ElevatedButton(
                onPressed: _loadGoalData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF3A88F4),
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  '다시 시도',
                  style: TextStyle(
                    fontFamily: 'Pretendard-Light',
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 현재 필터에 해당하는 데이터가 없는 경우 간단한 메시지 표시
    if (_goalList.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 16),
        child: Center(
          child: Text(
            _isGoalInProgress ? '진행중인 목표가 없습니다.' : '완료한 목표가 없습니다.',
            style: TextStyle(
              color: const Color(0xFF999999),
              fontSize: 16,
              fontFamily: 'Pretendard-Medium',
              letterSpacing: -0.32,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...List.generate(_goalList.length, (index) {
            final goal = _goalList[index];
            
            final String title = goal['title'] ?? '제목 없음';
            final String category = goal['category'] ?? 'LEARNING';
            final String categoryText = GoalService.getCategoryText(category);
            final int reward = goal['reward'] ?? 0;
            final String rewardText = '${_formatNumber(reward)}원';
            
            final String? startDate = goal['startDate'];
            final String? endDate = goal['endDate'];
            final String period = _formatGoalDatePeriod(startDate, endDate);
            
            final String achievementRate = _calculateGoalAchievementRate(goal);
            final String dDay = _calculateGoalDDay(endDate);
            final List<String> tags = ['목표', categoryText, period];
            
            return Column(
              children: [
                _buildGoalItem(title, period, achievementRate, rewardText, dDay, tags),
                if (index < _goalList.length - 1)
                  const SizedBox(height: 24),
              ],
            );
          }),
        ],
      ),
    );
  }

  // 목표가 없을 때 안내 화면
  Widget _buildEmptyGoalState() {
    return Container(
      width: double.infinity,
      height: MediaQuery.of(context).size.height - 150, // 상단 탭 높이 고려
      child: Center(
        child: Container(
          width: 390,
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width - 32, // 좌우 여백 16씩
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 이미지
              Container(
                width: 159,
                height: 108,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage("assets/icons/my/empty_mission.png"),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // 텍스트 영역
              Container(
                width: double.infinity,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 텍스트 컨테이너
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            '조회할 수 있는 목표 내역이 없습니다!',
                            style: TextStyle(
                              color: const Color(0xFF202020),
                              fontSize: 18,
                              fontFamily: 'Pretendard-Bold',
                              height: 1.50,
                              letterSpacing: -0.72,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          
                          const SizedBox(height: 12),
                          
                          Text(
                            '목표를 세우고 보상을 받아보세요!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: const Color(0xFF999999),
                              fontSize: 14,
                              fontFamily: 'Pretendard-Light',
                              letterSpacing: -0.28,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 28),
                    
                    // 버튼 영역
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => GoalSettingScreen(),
                          ),
                        );
                      },
                      child: Container(
                        width: 358,
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width - 32, // 좌우 여백 고려
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                        decoration: ShapeDecoration(
                          color: const Color(0xFF146AFF),
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
            ],
          ),
        ),
      ),
    );
  }

  // 목표 아이템 위젯
  Widget _buildGoalItem(String title, String period, String achievementRate, String reward, String dDay, List<String> tags) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        shadows: [
          BoxShadow(
            color: Color(0x1C146AFF),
            blurRadius: 12,
            offset: Offset(-3, -4),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Color(0x1C146AFF),
            blurRadius: 12,
            offset: Offset(3, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 태그 영역
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                if (tags.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: ShapeDecoration(
                      color: const Color(0xFFFFD27F),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(
                      tags[0],
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontFamily: 'Pretendard-Light',
                        letterSpacing: -0.24,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                if (tags.length > 1) SizedBox(width: 12),
                if (tags.length > 1)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: ShapeDecoration(
                      color: const Color(0xFF5D9EFF),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(
                      tags[1],
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontFamily: 'Pretendard-Light',
                        letterSpacing: -0.24,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                if (tags.length > 2) SizedBox(width: 12),
                if (tags.length > 2)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: ShapeDecoration(
                      color: const Color(0xFF5D9EFF),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(
                      tags[2],
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontFamily: 'Pretendard-Light',
                        letterSpacing: -0.24,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
          
          SizedBox(height: 12),
          
          // 제목
          Text(
            title,
            style: TextStyle(
              color: const Color(0xFF353535),
              fontSize: 14,
              fontFamily: 'Pretendard-Bold',
              letterSpacing: -0.32,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          
          SizedBox(height: 12),
          
          // 정보 영역
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '보상 지급까지',
                      style: TextStyle(
                        color: const Color(0xFF666666),
                        fontSize: 12,
                        fontFamily: 'Pretendard-Light',
                        letterSpacing: -0.28,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      dDay,
                      style: TextStyle(
                        color: const Color(0xFF5D9EFF),
                        fontSize: 14,
                        fontFamily: 'Pretendard-Bold',
                        letterSpacing: -0.32,
                      ),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 40, color: Color.fromRGBO(231, 236, 246, 1)),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '달성률',
                      style: TextStyle(
                        color: const Color(0xFF666666),
                        fontSize: 12,
                        fontFamily: 'Pretendard-Light',
                        letterSpacing: -0.28,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      achievementRate,
                      style: TextStyle(
                        color: const Color(0xFF5D9EFF),
                        fontSize: 14,
                        fontFamily: 'Pretendard-Bold',
                        letterSpacing: -0.32,
                      ),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 40, color: Color.fromRGBO(231, 236, 246, 1)),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '보상금',
                      style: TextStyle(
                        color: const Color(0xFF666666),
                        fontSize: 12,
                        fontFamily: 'Pretendard-Light',
                        letterSpacing: -0.28,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      reward,
                      style: TextStyle(
                        color: const Color(0xFF5D9EFF),
                        fontSize: 14,
                        fontFamily: 'Pretendard-Bold',
                        letterSpacing: -0.32,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 헬퍼 메서드들
  String _formatGoalDatePeriod(String? startDate, String? endDate) {
    if (startDate == null || endDate == null) {
      return '날짜 정보 없음';
    }
    
    try {
      final start = DateTime.parse(startDate);
      final end = DateTime.parse(endDate);
      
      final startYear = start.year.toString().substring(2);
      final startMonth = start.month.toString().padLeft(2, '0');
      final startDay = start.day.toString().padLeft(2, '0');
      
      final endMonth = end.month.toString().padLeft(2, '0');
      final endDay = end.day.toString().padLeft(2, '0');
      
      if (start.year == end.year) {
        return '$startYear.$startMonth.$startDay - $endMonth.$endDay';
      } else {
        final endYear = end.year.toString().substring(2);
        return '$startYear.$startMonth.$startDay - $endYear.$endMonth.$endDay';
      }
    } catch (e) {
      return '$startDate - $endDate';
    }
  }

  String _calculateGoalAchievementRate(Map<String, dynamic> goal) {
    try {
      if (goal.containsKey('goalCheck') && goal['goalCheck'] != null) {
        final checkData = goal['goalCheck'];
        
        int checkedDays = 0;
        final dayFields = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
        for (String day in dayFields) {
          if (checkData.containsKey(day) && checkData[day] == true) {
            checkedDays++;
          }
        }
        
        final achievementRate = (checkedDays / 7 * 100).floor();
        return '$achievementRate%';
      }
      
      if (goal['status'] == 'ACHIEVEMENT') {
        return '100%';
      }
      
      return '0%';
    } catch (e) {
      return '0%';
    }
  }

  String _calculateGoalDDay(String? endDate) {
    if (endDate == null) {
      return 'D-?';
    }
    
    try {
      final end = DateTime.parse(endDate);
      final now = DateTime.now();
      
      final endDateOnly = DateTime(end.year, end.month, end.day);
      final nowDateOnly = DateTime(now.year, now.month, now.day);
      
      final difference = endDateOnly.difference(nowDateOnly).inDays;
      
      if (difference > 0) {
        return 'D-$difference';
      } else if (difference == 0) {
        return 'D-Day';
      } else {
        return '종료됨';
      }
    } catch (e) {
      return 'D-?';
    }
  }

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }
} 