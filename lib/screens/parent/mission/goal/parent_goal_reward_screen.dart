import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../services/goal_service.dart';
import '../../../../services/payment_service.dart';
import '../../../../services/auth_service.dart';

class ParentGoalRewardScreen extends StatefulWidget {
  final Map<String, dynamic> goal;
  final String? childName;
  final int stampsCount;

  const ParentGoalRewardScreen({
    super.key,
    required this.goal,
    this.childName,
    required this.stampsCount,
  });

  @override
  State<ParentGoalRewardScreen> createState() => _ParentGoalRewardScreenState();
}

class _ParentGoalRewardScreenState extends State<ParentGoalRewardScreen> {
  bool _isLoading = false;
  late int _calculatedScore;

  @override
  void initState() {
    super.initState();
    // 도장 개수에 따른 점수 계산 (각 도장당 14.28% = 100/7)
    _calculatedScore = ((widget.stampsCount / 7) * 100).round();
  }

  String get displayChildName {
    return widget.childName ?? '자녀';
  }

  String get goalTitle {
    return widget.goal['title'] ?? '목표';
  }

  String get goalCategory {
    final category = widget.goal['category'] ?? 'LEARNING';
    return category == 'LEARNING' ? '학습 인증' : '습관 형성';
  }

  String get goalDuration {
    try {
      final startDate = DateTime.parse(widget.goal['startDate']);
      final endDate = DateTime.parse(widget.goal['endDate']);
      final startFormatted = DateFormat('MM. dd').format(startDate);
      final endFormatted = DateFormat('MM. dd').format(endDate);
      return '$startFormatted - $endFormatted';
    } catch (e) {
      return '기간 미정';
    }
  }

  String get goalReward {
    final reward = widget.goal['reward'] ?? 0;
    return NumberFormat('#,###').format(reward);
  }

  // 목표 보상 전송
  Future<void> _sendGoalReward() async {
    print('🎯 목표 보상: _sendGoalReward 시작');
    print('🎯 목표 데이터: ${widget.goal}');

    setState(() {
      _isLoading = true;
    });

    try {
      final goalId = widget.goal['goalId'];
      final childId = widget.goal['childId'];
      final rewardAmount = widget.goal['reward'] ?? 0;

      print('🎯 추출된 목표 ID: $goalId');
      print('🎯 추출된 자녀 ID: $childId');
      print('🎯 보상 금액: $rewardAmount');

      if (goalId == null || childId == null) {
        throw Exception('목표 정보가 올바르지 않습니다.');
      }

      if (rewardAmount <= 0) {
        throw Exception('보상 금액이 설정되지 않았습니다.');
      }

      // PaymentService의 transferPointsGoal 함수 사용
      print(
        '🎯 목표 보상 포인트 전송 시작 - 수신자: $childId, 금액: $rewardAmount, 목표ID: $goalId',
      );

      final transferResult = await PaymentService.transferPointsGoal(
        receiverId: childId,
        pointAmount: rewardAmount,
        message:
            '목표 달성 보상! ${widget.stampsCount}개의 칭찬 스탬프로 목표를 완료했습니다. (달성도: ${_calculatedScore}점)',
        goalId: goalId,
      );

      print('🎯 목표 보상 포인트 전송 완료: $transferResult');

      // 보상 전송 결과 확인
      final isRewardTransferSuccess = transferResult.containsKey('historyId');
      if (isRewardTransferSuccess) {
        print('🎯 보상 전송 성공 - historyId: ${transferResult['historyId']}');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('목표 보상 ${rewardAmount}원이 성공적으로 지급되었습니다!'),
              backgroundColor: const Color(0xFF4CAF50),
              duration: Duration(seconds: 2),
            ),
          );

          print('🎯 보상 화면 종료 - 보상 완료 신호 전송');
          // 보상 완료를 알리기 위해 업데이트된 목표 정보 반환
          final updatedGoal = Map<String, dynamic>.from(widget.goal);
          updatedGoal['isRewarded'] = true;
          updatedGoal['achievementScore'] = _calculatedScore;

          Navigator.pop(context, updatedGoal);
        }
      } else {
        print('🎯 보상 전송 실패 - 응답: $transferResult');
        throw Exception('보상 전송에 실패했습니다');
      }
    } catch (e) {
      print('🎯 목표 보상 전송 실패: $e');
      print('🎯 스택 트레이스: ${StackTrace.current}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('목표 보상 전송에 실패했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      print('🎯 목표 보상: _sendGoalReward 종료');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Scaffold(
      backgroundColor: const Color(0xFFE7ECF6),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      _buildTitle(),
                      const SizedBox(height: 24),
                      _buildGoalInfoCard(),
                      const SizedBox(height: 24),
                      _buildScoreSection(),
                      const SizedBox(height: 32),
                      _buildSendButton(),
                      const SizedBox(height: 24),
                      _buildInfoCard(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      width: double.infinity,
      height: 56,
      child: Stack(
        children: [
          Positioned(
            left: 16,
            top: 16,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 24,
                height: 24,
                child: Image.asset(
                  'assets/icons/parent/뒤로가기.png',
                  width: 24,
                  height: 24,
                  fit: BoxFit.contain,
                  errorBuilder:
                      (context, error, stackTrace) =>
                          Icon(Icons.arrow_back, color: Colors.black, size: 24),
                ),
              ),
            ),
          ),
          Center(
            child: Text(
              '목표 보상 해주기',
              style: TextStyle(
                color: const Color(0xFF202020),
                fontSize: 16,
                fontFamily: 'Pretendard-Bold',
                letterSpacing: -0.32,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${displayChildName}님이 이번 목표를 완료했습니다!',
          style: TextStyle(
            color: const Color(0xFF202020),
            fontSize: 16,
            fontFamily: 'Pretendard-Bold',
            height: 1.50,
            letterSpacing: -0.80,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '열심히 달성한 아이에게 보상을 전해주세요!',
          style: TextStyle(
            color: const Color(0xFF202020),
            fontSize: 16,
            fontFamily: 'Pretendard-Bold',
            height: 1.50,
            letterSpacing: -0.64,
          ),
        ),
      ],
    );
  }

  Widget _buildGoalInfoCard() {
    return Column(
      children: [
        // 목표 완료 이미지 영역
        Image.asset(
          'assets/icons/parent/goal/complete.png',
          width: 358,
          height: 256,
          fit: BoxFit.contain,
          errorBuilder:
              (context, error, stackTrace) => Container(
                width: 358,
                height: 256,
                decoration: ShapeDecoration(
                  color: const Color(0xFF4CAF50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: Center(
                  child: Icon(Icons.stars, size: 80, color: Colors.white),
                ),
              ),
        ),
        const SizedBox(height: 32),

        // 목표 정보 카드
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: ShapeDecoration(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            shadows: [
              BoxShadow(
                color: Color(0x4C000000),
                blurRadius: 12,
                offset: Offset(3, 4),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${displayChildName}님의 이번 목표 정보',
                style: TextStyle(
                  color: const Color(0xFF202020),
                  fontSize: 18,
                  fontFamily: 'Pretendard-Bold',
                  letterSpacing: -0.72,
                ),
              ),
              const SizedBox(height: 19),

              // 태그들
              Wrap(
                spacing: 12,
                children: [
                  _buildTag('목표', const Color(0xFFFFD27F)),
                  _buildTag(goalCategory, const Color(0xFF5D9EFF)),
                  _buildTag(goalDuration, const Color(0xFF5D9EFF)),
                ],
              ),
              const SizedBox(height: 12),

              // 목표 제목
              Text(
                goalTitle,
                style: TextStyle(
                  color: const Color(0xFF353535),
                  fontSize: 18,
                  fontFamily: 'Pretendard-Bold',
                  letterSpacing: -0.72,
                ),
              ),
              const SizedBox(height: 16),

              // 칭찬 스탬프와 보상금
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      '획득한 칭찬 스탬프',
                      '${widget.stampsCount}/7개',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: _buildInfoItem('보상금', '${goalReward}원')),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTag(String text, Color color) {
    // 날짜 태그인지 확인 (MM. dd - MM. dd 형식)
    bool isDateTag = text.contains(' - ') && text.contains('.');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: ShapeDecoration(
        color: isDateTag ? const Color(0xFFE7ECF6) : color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: isDateTag ? const Color(0xFF8590A3) : Colors.white,
          fontSize: 12,
          fontFamily: 'Pretendard-Light',
          letterSpacing: -0.24,
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    // "획득한 칭찬 스탬프" 항목의 경우 특별한 디자인 적용
    if (label == '획득한 칭찬 스탬프') {
      return Container(
        width: double.infinity,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              '획득한 칭찬 스탬프',
              style: TextStyle(
                color: const Color(0xFF666666),
                fontSize: 14,
                fontFamily: 'Pretendard-Light',
                letterSpacing: -0.28,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  '${widget.stampsCount}',
                  style: TextStyle(
                    color: const Color(0xFF5D9EFF),
                    fontSize: 16,
                    fontFamily: 'Pretendard-Bold',
                    letterSpacing: -0.32,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '/7개',
                  style: TextStyle(
                    color: const Color(0xFFB6B6B6),
                    fontSize: 16,
                    fontFamily: 'Pretendard-Medium',
                    letterSpacing: -0.32,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // 기존 디자인 (보상금 등 다른 항목들)
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: const Color(0xFF666666),
            fontSize: 14,
            fontFamily: 'Pretendard-Light',
            letterSpacing: -0.28,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: const Color(0xFF5D9EFF),
            fontSize: 16,
            fontFamily: 'Pretendard-Bold',
            letterSpacing: -0.32,
          ),
        ),
      ],
    );
  }

  Widget _buildScoreSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        shadows: [
          BoxShadow(
            color: Color(0x4C000000),
            blurRadius: 12,
            offset: Offset(3, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${displayChildName}님의 이번 활동 달성률',
            style: TextStyle(
              color: const Color(0xFF202020),
              fontSize: 18,
              fontFamily: 'Pretendard-Bold',
              letterSpacing: -0.72,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '칭찬 스탬프를 기준으로 자동으로 달성률을 계산했어요',
            style: TextStyle(
              color: const Color(0xFF8590A3),
              fontSize: 12,
              fontFamily: 'Pretendard-Light',
              letterSpacing: -0.24,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: ShapeDecoration(
              color: const Color(0xFF146AFF),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(40),
              ),
            ),
            child: Text(
              '${_calculatedScore}점',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontFamily: 'Pretendard-Bold',
                letterSpacing: -0.80,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSendButton() {
    return Container(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _sendGoalReward,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF146AFF),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
          disabledBackgroundColor: const Color(0xFF999999),
        ),
        child:
            _isLoading
                ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                : Text(
                  '보상금 보내기',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontFamily: 'Pretendard-Medium',
                    letterSpacing: -0.28,
                  ),
                ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: ShapeDecoration(
        color: const Color(0xFFF0F0F0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: const Color(0xFF666666),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '목표 달성 시 자녀에게 포인트가 지급됩니다',
                  style: TextStyle(
                    color: const Color(0xFF666666),
                    fontSize: 12,
                    fontFamily: 'Pretendard-Medium',
                    letterSpacing: -0.24,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '일주일 동안의 칭찬 스탬프 달성도에 따라 설정된 보상 금액이 자녀의 계좌로 전송됩니다. 새로운 목표를 설정하여 아이의 지속적인 성장을 도와주세요.',
            style: TextStyle(
              color: const Color(0xFF999999),
              fontSize: 11,
              fontFamily: 'Pretendard-Light',
              height: 1.45,
              letterSpacing: -0.22,
            ),
          ),
        ],
      ),
    );
  }
}
