import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../services/goal_service.dart';
import '../../widgets/goal_selection_modal.dart';

class ParentGoalCheckWidget extends StatefulWidget {
  final Map<String, dynamic> goal;
  final Function()? onCheckUpdated;

  const ParentGoalCheckWidget({
    super.key,
    required this.goal,
    this.onCheckUpdated,
  });

  @override
  State<ParentGoalCheckWidget> createState() => _ParentGoalCheckWidgetState();
}

class _ParentGoalCheckWidgetState extends State<ParentGoalCheckWidget> {
  Map<String, dynamic>? _checkData;
  bool _isLoading = false;
  // 도장 찍기 상태를 즉시 반영하기 위한 로컬 상태
  Map<int, bool> _localCheckState = {};

  @override
  void initState() {
    super.initState();
    
    // 하단 네비게이션 바 숨기기 설정
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [SystemUiOverlay.top],
    );
    
    _loadCheckData();
  }

  // 도장 확인 데이터 로드
  Future<void> _loadCheckData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final goalId = widget.goal['goalId'];
      if (goalId != null) {
        final checkData = await GoalService.getGoalCheck(goalId);
        print('🔄 서버 데이터 로드: $checkData');
        
        setState(() {
          _checkData = checkData;
          _isLoading = false;
          // 서버 데이터로 로컬 상태 초기화 (기존 로컬 상태 보존)
          if (checkData != null) {
            print('📊 로컬 상태 업데이트 전: $_localCheckState');
            for (int i = 1; i <= 7; i++) {
              final serverState = GoalService.isDayChecked(checkData, i);
              // 로컬에서 true로 설정된 상태는 유지 (서버 동기화 지연 대응)
              if (!_localCheckState.containsKey(i) || !_localCheckState[i]!) {
                _localCheckState[i] = serverState;
              }
            }
            print('📊 로컬 상태 업데이트 후: $_localCheckState');
          }
        });
      }
    } catch (e) {
      print('도장 확인 데이터 로드 실패: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 도장 찍기
  Future<void> _stampCheck(int dayNumber) async {
    try {
      final goalId = widget.goal['goalId'];
      if (goalId == null) return;

      print('도장 찍기 시도 - goalId: $goalId, day: $dayNumber');

      setState(() {
        _isLoading = true;
      });

      final result = await GoalService.stampGoalCheck(goalId, dayNumber);
      
      if (result['success'] == true) {
        print('✅ 도장 찍기 성공!');
        print('🔄 로컬 상태 업데이트: day $dayNumber = true');
        
        // 로컬 상태 즉시 업데이트
        setState(() {
          _localCheckState[dayNumber] = true;
          _isLoading = false;
        });
        
        print('📱 현재 로컬 상태: $_localCheckState');
        
        // 서버 동기화는 잠시 후에 실행 (로컬 상태 우선)
        Future.delayed(Duration(seconds: 1), () {
          if (mounted) {
            _loadCheckData();
          }
        });
        
        if (widget.onCheckUpdated != null) {
          widget.onCheckUpdated!();
        }

        // 성공 메시지 표시
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${GoalService.convertNumberToDay(dayNumber)}요일 도장을 찍었습니다!',
                style: TextStyle(
                  fontFamily: 'Pretendard-Medium',
                ),
              ),
              backgroundColor: Color(0xFF4CAF50),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        throw Exception(result['message'] ?? '도장 찍기에 실패했습니다.');
      }
    } catch (e) {
      print('❌ 도장 찍기 실패: $e');
      
      setState(() {
        _isLoading = false;
      });
      
      // 에러 메시지 표시
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '도장 찍기에 실패했습니다: ${e.toString().replaceAll('Exception: ', '')}',
              style: TextStyle(
                fontFamily: 'Pretendard-Medium',
              ),
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // 요일별 도장 위젯 생성
  Widget _buildDayCheckWidget(int dayNumber) {
    final dayName = GoalService.convertNumberToDay(dayNumber);
    // 로컬 상태를 우선 확인하고, 없으면 서버 데이터 확인
    final isChecked = _localCheckState.containsKey(dayNumber) 
        ? _localCheckState[dayNumber]! 
        : (_checkData != null ? GoalService.isDayChecked(_checkData!, dayNumber) : false);
    final isRed = dayNumber == 7; // 일요일
    final isToday = GoalService.getCurrentDayNumber() == dayNumber;
    final isSunday = dayNumber == 7; // 일요일
    
    // 디버깅용 로그
    if (dayNumber == 2 || dayNumber == 3) {
      print('🎯 $dayName 위젯 빌드: isChecked=$isChecked, 로컬=${_localCheckState[dayNumber]}, 서버=${_checkData != null ? GoalService.isDayChecked(_checkData!, dayNumber) : 'null'}');
    }

    return GestureDetector(
      onTap: _isLoading ? null : () => _stampCheck(dayNumber),
      child: Container(
        width: 50,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              dayName,
              style: TextStyle(
                color: isRed ? Color(0xFFE74C3C) : dayNumber == 6 ? Color(0xFF3498DB) : Color(0xFF666666),
                fontSize: 12,
                fontFamily: 'Pretendard-Medium',
                letterSpacing: -0.24,
              ),
            ),
            SizedBox(height: 8),
            Container(
              width: 68,
              height: 68,
              child: Center(
                child: isSunday
                    ? Image.asset(
                        'assets/icons/parent/goal/tropy.png',
                        width: 68,
                        height: 68,
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
                            errorBuilder: (context, error, stackTrace) => Container(
                              width: 68,
                              height: 68,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFFDEE1E7),
                                border: Border.all(color: const Color(0xFF8490A3), width: 1),
                              ),
                            ),
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final goalTitle = widget.goal['title'] ?? '목표';
    final childName = widget.goal['childNickname'] ?? widget.goal['childName'] ?? '자녀';
    final screenWidth = MediaQuery.of(context).size.width;
    final modalWidth = screenWidth - 24; // 화면 너비에서 좌우 12px씩 제외 
    final maxWidth = 500.0; // 최대 너비 제한 증가
    final finalWidth = modalWidth > maxWidth ? maxWidth : modalWidth;

    return Container(
      width: finalWidth,
      constraints: BoxConstraints(
        minHeight: 300,
        maxHeight: MediaQuery.of(context).size.height * 0.7, // 화면 높이의 70% 제한
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 헤더 섹션
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${childName}님의 칭찬 스탬프를 찍어주세요!',
                        style: TextStyle(
                          color: const Color(0xFF202020),
                          fontSize: 16,
                          fontFamily: 'Pretendard-Bold',
                          letterSpacing: -0.64,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 20,
                        height: 20,
                        child: Icon(
                          Icons.close,
                          color: Colors.grey,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  '우리 아이의 목표 달성을 위해 칭찬이 필요해요',
                  style: TextStyle(
                    color: const Color(0xFF999999),
                    fontSize: 12,
                    fontFamily: 'Pretendard-Light',
                    letterSpacing: -0.24,
                  ),
                ),
              ],
            ),
          ),
          
          // 이미지 섹션
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            decoration: BoxDecoration(color: Colors.white),
            child: Center(
              child: Container(
                width: 140,
                height: 140,
                child: Image.asset(
                  'assets/icons/parent/goal/check_none.png',
                  width: 140,
                  height: 140,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFDEE1E7),
                      border: Border.all(color: const Color(0xFF8490A3), width: 1),
                    ),
                    child: Icon(
                      Icons.add,
                      color: const Color(0xFF8490A3),
                      size: 60,
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // 버튼 섹션
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
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
              onTap: _isLoading ? null : () {
                Navigator.of(context).pop();
                _navigateToGoalSelectionModal();
              },
              child: Container(
                width: double.infinity,
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
                    if (_isLoading)
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    else
                      Text(
                        '칭찬 스탬프 찍으러 가기',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontFamily: 'Pretendard-Medium',
                          letterSpacing: -0.24,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // GoalSelectionModal로 이동
  void _navigateToGoalSelectionModal() async {
    try {
      // 현재 목표만 배열로 만들어서 전달
      final goals = [widget.goal];
      
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => GoalSelectionModal(
            goals: goals,
            onCheckUpdated: widget.onCheckUpdated,
          ),
        ),
      );
    } catch (e) {
      print('GoalSelectionModal 이동 중 오류: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '화면 이동 중 오류가 발생했습니다',
            style: TextStyle(fontFamily: 'Pretendard-Medium'),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // 상세 도장 찍기 위젯 표시
  void _showDetailedGoalCheckWidget() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
              maxWidth: MediaQuery.of(context).size.width * 0.9,
            ),
            child: DetailedGoalCheckWidget(
              goal: widget.goal,
              onCheckUpdated: widget.onCheckUpdated,
            ),
          ),
        );
      },
    );
  }
}

// 상세 도장 찍기 위젯 클래스
class DetailedGoalCheckWidget extends StatefulWidget {
  final Map<String, dynamic> goal;
  final Function()? onCheckUpdated;

  const DetailedGoalCheckWidget({
    super.key,
    required this.goal,
    this.onCheckUpdated,
  });

  @override
  State<DetailedGoalCheckWidget> createState() => _DetailedGoalCheckWidgetState();
}

class _DetailedGoalCheckWidgetState extends State<DetailedGoalCheckWidget> {
  Map<String, dynamic>? _checkData;
  bool _isLoading = false;
  Map<int, bool> _localCheckState = {};

  @override
  void initState() {
    super.initState();
    _loadCheckData();
  }

  // 도장 확인 데이터 로드
  Future<void> _loadCheckData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final goalId = widget.goal['goalId'];
      if (goalId != null) {
        final checkData = await GoalService.getGoalCheck(goalId);
        
        setState(() {
          _checkData = checkData;
          _isLoading = false;
          if (checkData != null) {
            for (int i = 1; i <= 7; i++) {
              final serverState = GoalService.isDayChecked(checkData, i);
              if (!_localCheckState.containsKey(i) || !_localCheckState[i]!) {
                _localCheckState[i] = serverState;
              }
            }
          }
        });
      }
    } catch (e) {
      print('도장 확인 데이터 로드 실패: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 도장 찍기
  Future<void> _stampCheck(int dayNumber) async {
    try {
      final goalId = widget.goal['goalId'];
      if (goalId == null) return;

      setState(() {
        _isLoading = true;
      });

      final result = await GoalService.stampGoalCheck(goalId, dayNumber);
      
      if (result['success'] == true) {
        setState(() {
          _localCheckState[dayNumber] = true;
          _isLoading = false;
        });
        
        Future.delayed(Duration(seconds: 1), () {
          if (mounted) {
            _loadCheckData();
          }
        });
        
        if (widget.onCheckUpdated != null) {
          widget.onCheckUpdated!();
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${GoalService.convertNumberToDay(dayNumber)}요일 도장을 찍었습니다!',
                style: TextStyle(
                  fontFamily: 'Pretendard-Medium',
                ),
              ),
              backgroundColor: Color(0xFF4CAF50),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        throw Exception(result['message'] ?? '도장 찍기에 실패했습니다.');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '도장 찍기에 실패했습니다: ${e.toString().replaceAll('Exception: ', '')}',
              style: TextStyle(
                fontFamily: 'Pretendard-Medium',
              ),
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // 요일별 도장 위젯 생성
  Widget _buildDayCheckWidget(int dayNumber) {
    final dayName = GoalService.convertNumberToDay(dayNumber);
    final isChecked = _localCheckState.containsKey(dayNumber) 
        ? _localCheckState[dayNumber]! 
        : (_checkData != null ? GoalService.isDayChecked(_checkData!, dayNumber) : false);
    final isRed = dayNumber == 7;
    final isSunday = dayNumber == 7;

    return GestureDetector(
      onTap: _isLoading ? null : () => _stampCheck(dayNumber),
      child: Container(
        width: 50,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              dayName,
              style: TextStyle(
                color: isRed ? Color(0xFFE74C3C) : dayNumber == 6 ? Color(0xFF3498DB) : Color(0xFF666666),
                fontSize: 12,
                fontFamily: 'Pretendard-Medium',
                letterSpacing: -0.24,
              ),
            ),
            SizedBox(height: 8),
            Container(
              width: 68,
              height: 68,
              child: Center(
                child: isSunday
                    ? Image.asset(
                        'assets/icons/parent/goal/tropy.png',
                        width: 68,
                        height: 68,
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
                            errorBuilder: (context, error, stackTrace) => Container(
                              width: 68,
                              height: 68,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFFDEE1E7),
                                border: Border.all(color: const Color(0xFF8490A3), width: 1),
                              ),
                            ),
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final goalTitle = widget.goal['title'] ?? '목표';
    final childName = widget.goal['childNickname'] ?? widget.goal['childName'] ?? '자녀';

    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$childName의 목표',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF999999),
                        fontFamily: 'Pretendard-Light',
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      goalTitle,
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF202020),
                        fontFamily: 'Pretendard-Bold',
                      ),
                    ),
                  ],
                ),
              ),
              if (_isLoading)
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF5D9EFF),
                  ),
                ),
            ],
          ),
          
          SizedBox(height: 20),
          
          // 요일별 도장 찍기
          Column(
            children: [
              // 첫 번째 줄 (월화수목 - 4개)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildDayCheckWidget(1), // 월
                    _buildDayCheckWidget(2), // 화
                    _buildDayCheckWidget(3), // 수
                    _buildDayCheckWidget(4), // 목
                  ],
                ),
              ),
              SizedBox(height: 16),
              // 두 번째 줄 (금토일 - 3개, 2번째 원과 정렬)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  children: [
                    // 첫 번째 원 크기만큼 + 간격의 절반
                    SizedBox(width: 68 + 34), // 68(원크기) + 34(간격절반)
                    _buildDayCheckWidget(5), // 금
                    SizedBox(width: 68), // 원 크기만큼 간격
                    _buildDayCheckWidget(6), // 토
                    SizedBox(width: 68), // 원 크기만큼 간격
                    _buildDayCheckWidget(7), // 일 (트로피)
                  ],
                ),
              ),
            ],
          ),
          
          SizedBox(height: 16),
          
          // 안내 텍스트
          Center(
            child: Text(
              '아이가 목표를 달성한 날에 도장을 찍어주세요',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF999999),
                fontFamily: 'Pretendard-Light',
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
} 