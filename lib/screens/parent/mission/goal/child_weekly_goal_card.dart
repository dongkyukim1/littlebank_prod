import 'package:flutter/material.dart';
import '../../../../services/goal_service.dart';
import '../../../../services/family_service.dart';

class ChildWeeklyGoalCard extends StatefulWidget {
  final Map<String, dynamic>? selectedChild;

  const ChildWeeklyGoalCard({Key? key, this.selectedChild}) : super(key: key);

  @override
  State<ChildWeeklyGoalCard> createState() => _ChildWeeklyGoalCardState();
}

class _ChildWeeklyGoalCardState extends State<ChildWeeklyGoalCard> {
  List<Map<String, dynamic>> _weeklyGoals = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadWeeklyGoals();
  }

  @override
  void didUpdateWidget(ChildWeeklyGoalCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 선택된 자녀가 변경되면 목표를 다시 로드
    if (oldWidget.selectedChild != widget.selectedChild) {
      _loadWeeklyGoals();
    }
  }

  // 이번 주 목표 조회
  Future<void> _loadWeeklyGoals() async {
    if (widget.selectedChild == null) {
      setState(() {
        _weeklyGoals = [];
        _isLoading = false;
        _error = null;
      });
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      print('===== 부모 홈화면: 자녀 이번 주 목표 조회 시작 =====');

      final familyInfo = await FamilyService.getFamilyInfo();
      if (familyInfo == null) {
        throw Exception('가족 정보를 가져올 수 없습니다');
      }

      final familyId = familyInfo['familyId'];
      final goals = await GoalService.getParentWeeklyGoals(familyId);

      if (goals != null) {
        // 선택된 자녀의 목표만 필터링
        final selectedChildId = widget.selectedChild!['familyMemberId'];
        final childGoals = goals.where((goal) => 
          goal['familyMemberId'] == selectedChildId
        ).toList();

        setState(() {
          _weeklyGoals = childGoals;
          _isLoading = false;
        });

        print('부모 홈화면: 자녀 이번 주 목표 ${childGoals.length}개 조회 성공');
      } else {
        setState(() {
          _weeklyGoals = [];
          _isLoading = false;
        });
      }

      print('===== 부모 홈화면: 자녀 이번 주 목표 조회 완료 =====');
    } catch (e) {
      print('부모 홈화면: 자녀 이번 주 목표 조회 중 오류: $e');
      setState(() {
        _weeklyGoals = [];
        _isLoading = false;
        _error = '목표 조회 중 오류가 발생했습니다';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final childName = widget.selectedChild?['nickname'] ?? 
                     widget.selectedChild?['realName'] ?? '자녀';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Color(0x35000000),
            blurRadius: 8,
            offset: Offset(3, 4),
            spreadRadius: 0,
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 상단 헤더 부분
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '이번 주 ${childName}님의 목표 ',
                      style: TextStyle(
                        color: const Color(0xFF202020),
                        fontSize: 16,
                        fontFamily: 'Pretendard-Bold',
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.36,
                      ),
                    ),
                    Text(
                      '${_weeklyGoals.length}',
                      style: TextStyle(
                        color: const Color(0xFF146AFF),
                        fontSize: 16,
                        fontFamily: 'Pretendard-Bold',
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.36,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '자녀의 목표 달성을 도와주세요',
                  style: TextStyle(
                    color: const Color(0xFF999999),
                    fontSize: 12,
                    fontFamily: 'Pretendard-Light',
                    fontWeight: FontWeight.w300,
                    letterSpacing: -0.28,
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          
          // 컨텐츠 부분
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return Container(
        height: 120,
        child: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF5D9EFF),
          ),
        ),
      );
    }

    if (_error != null) {
      return Container(
        height: 120,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _error!,
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 14,
                  fontFamily: 'Pretendard-Medium',
                ),
                textAlign: TextAlign.center,
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
      );
    }

    if (_weeklyGoals.isEmpty) {
      return Container(
        height: 120,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.assignment_outlined,
                size: 48,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 12),
              Text(
                '이번 주 목표가 없습니다',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                  fontFamily: 'Pretendard-Medium',
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: _weeklyGoals.asMap().entries.map((entry) {
        final index = entry.key;
        final goal = entry.value;
        return Column(
          children: [
            if (index > 0) const SizedBox(height: 16),
            _buildGoalItem(goal),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildGoalItem(Map<String, dynamic> goal) {
    final title = goal['title'] ?? '목표';
    final category = GoalService.getCategoryText(goal['category'] ?? 'LEARNING');
    final status = goal['status'] ?? '';
    final reward = goal['reward'] ?? 0;
    
    // 상태에 따른 텍스트와 색상
    final statusText = GoalService.getGoalStatusText(goal);
    final statusColor = GoalService.getGoalStatusColor(goal);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 상태 및 카테고리 태그
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD27F),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  category,
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
          
          // 목표 제목
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: const Color(0xFF202020),
              fontFamily: 'Pretendard-Bold',
              letterSpacing: -0.2,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          
          // 보상 정보
          Text(
            '보상: ${reward.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}원',
            style: TextStyle(
              fontSize: 12,
              color: const Color(0xFF666666),
              fontFamily: 'Pretendard-Light',
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
} 