import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../services/mission_service.dart';
import '../../../services/payment_service.dart';
import '../../../services/auth_service.dart';

class MissionEvaluationScreen extends StatefulWidget {
  final Map<String, dynamic> mission;
  final Map<String, dynamic>? childInfo;

  const MissionEvaluationScreen({
    super.key,
    required this.mission,
    this.childInfo,
  });

  @override
  State<MissionEvaluationScreen> createState() =>
      _MissionEvaluationScreenState();
}

class _MissionEvaluationScreenState extends State<MissionEvaluationScreen> {
  final TextEditingController _scoreController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _scoreController.dispose();
    super.dispose();
  }

  String get childName {
    return widget.childInfo?['nickname'] ??
        widget.childInfo?['realName'] ??
        '자녀';
  }

  String get missionTitle {
    return widget.mission['title'] ?? '미션';
  }

  String get missionType {
    final type = widget.mission['type'] ?? 'FAMILY';
    return type == 'FAMILY' ? '가족 미션' : '학원 미션';
  }

  String get missionCategory {
    final category = widget.mission['category'] ?? 'LEARNING';
    return category == 'LEARNING' ? '학습인증' : '습관형성';
  }

  String get missionDuration {
    try {
      final startDate = DateTime.parse(widget.mission['startDate']);
      final endDate = DateTime.parse(widget.mission['endDate']);
      final startFormatted = DateFormat('MM. dd').format(startDate);
      final endFormatted = DateFormat('MM. dd').format(endDate);
      return '$startFormatted - $endFormatted';
    } catch (e) {
      return '기간 미정';
    }
  }

  String get missionReward {
    final reward = widget.mission['reward'] ?? 0;
    return NumberFormat('#,###').format(reward);
  }

  // 점수 입력 후 미션 보상 포인트 전송
  Future<void> _submitScoreAndSendReward() async {
    print('🎯 미션 평가: _submitScoreAndSendReward 시작');
    print('🎯 미션 데이터: ${widget.mission}');

    final scoreText = _scoreController.text.trim();
    print('🎯 입력된 점수 텍스트: "$scoreText"');

    if (scoreText.isEmpty) {
      print('🎯 점수가 비어있음');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('점수를 입력해주세요'), backgroundColor: Colors.red),
      );
      return;
    }

    final score = int.tryParse(scoreText);
    print('🎯 파싱된 점수: $score');

    if (score == null || score < 0 || score > 100) {
      print('🎯 점수 범위 오류: $score');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('0~100 사이의 숫자를 입력해주세요'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final missionId = widget.mission['missionId'] ?? widget.mission['id'];
      final childId = widget.childInfo?['userId'] ?? widget.childInfo?['id'];
      final rewardAmount = widget.mission['reward'] ?? 0;

      print('🎯 추출된 미션 ID: $missionId');
      print('🎯 추출된 자녀 ID: $childId');
      print('🎯 보상 금액: $rewardAmount');

      if (missionId != null && childId != null) {
        // 1. 먼저 미션 점수 입력
        print('🎯 미션 점수 입력 API 호출 시작 - missionId: $missionId, score: $score');

        final scoreResult = await MissionService.submitMissionScore(
          missionId: missionId,
          score: score,
        );

        print('🎯 미션 점수 입력 API 응답: $scoreResult');

        // 2. 미션 보상 포인트 전송 (항상 실행)
        if (rewardAmount > 0) {
          print(
            '🎯 미션 보상 포인트 전송 시작 - 수신자: $childId, 금액: $rewardAmount, 미션ID: $missionId',
          );

          final transferResult = await PaymentService.transferPointsMission(
            receiverId: childId,
            pointAmount: rewardAmount,
            message: '${missionTitle} 미션 완료 보상',
            missionId: missionId,
            isRefused: false,
          );

          print('🎯 미션 보상 포인트 전송 완료: $transferResult');

          // 보상 전송 결과 확인
          final isRewardTransferSuccess = transferResult.containsKey(
            'historyId',
          );
          if (isRewardTransferSuccess) {
            print('🎯 보상 전송 성공 - historyId: ${transferResult['historyId']}');
          } else {
            print('🎯 보상 전송 실패 - 응답: $transferResult');
            throw Exception('보상 전송에 실패했습니다');
          }
        } else {
          print('🎯 보상 금액이 0원이므로 보상 전송을 건너뜁니다');
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('점수가 입력되고 보상이 전송되었습니다'),
              backgroundColor: Color(0xFF5D9EFF),
            ),
          );

          print('🎯 평가 화면 종료 - 평가 완료 신호 전송');
          // 평가 완료를 알리기 위해 업데이트된 미션 정보 반환
          final updatedMission = Map<String, dynamic>.from(widget.mission);
          updatedMission['isRewarded'] = true;
          updatedMission['finishScore'] = score;

          Navigator.pop(context, updatedMission);
        }
      } else {
        print('🎯 오류: 미션 ID 또는 자녀 ID가 null임');
        print('🎯 미션 ID: $missionId, 자녀 ID: $childId');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('미션 정보 또는 자녀 정보를 찾을 수 없습니다'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('🎯 점수 입력 또는 보상 전송 실패: $e');
      print('🎯 스택 트레이스: ${StackTrace.current}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('점수 입력 또는 보상 전송에 실패했습니다: $e'),
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
      print('🎯 미션 평가: _submitScoreAndSendReward 종료');
    }
  }

  // 점수만 입력하기 (보상 없이)
  Future<void> _submitScoreOnly() async {
    print('🎯 미션 점수만 입력: _submitScoreOnly 시작');
    print('🎯 미션 데이터: ${widget.mission}');

    final scoreText = _scoreController.text.trim();
    print('🎯 입력된 점수 텍스트: "$scoreText"');

    if (scoreText.isEmpty) {
      print('🎯 점수가 비어있음');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('점수를 입력해주세요'), backgroundColor: Colors.red),
      );
      return;
    }

    final score = int.tryParse(scoreText);
    print('🎯 파싱된 점수: $score');

    if (score == null || score < 0 || score > 100) {
      print('🎯 점수 범위 오류: $score');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('0~100 사이의 숫자를 입력해주세요'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final missionId = widget.mission['missionId'] ?? widget.mission['id'];
      final childId = widget.childInfo?['userId'] ?? widget.childInfo?['id'];
      final missionTitle = widget.mission['title'] ?? '미션';

      print('🎯 추출된 미션 ID: $missionId');
      print('🎯 추출된 자녀 ID: $childId');

      if (missionId != null && childId != null) {
        // 1. 먼저 미션 점수 입력
        print('🎯 미션 점수 입력 API 호출 시작 - missionId: $missionId, score: $score');

        final scoreResult = await MissionService.submitMissionScore(
          missionId: missionId,
          score: score,
        );

        print('🎯 미션 점수 입력 API 응답: $scoreResult');

        // 2. 0원 보상 포인트 전송으로 평가 완료 처리 (isRefused: true)
        print('🎯 평가 완료 처리를 위한 0원 보상 전송 시작 - 수신자: $childId, 미션ID: $missionId');

        final transferResult = await PaymentService.transferPointsMission(
          receiverId: childId,
          pointAmount: 0, // 0원으로 전송
          message: '${missionTitle} 미션 평가 완료',
          missionId: missionId,
          isRefused: true, // 거절로 처리하여 평가 완료 상태로 만들기
        );

        print('🎯 평가 완료 처리 (0원 전송) 완료: $transferResult');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('점수가 입력되었습니다'),
              backgroundColor: Color(0xFF5D9EFF),
            ),
          );

          print('🎯 점수만 입력 완료 - 화면 종료');
          // 점수만 입력 완료를 알리기 위해 업데이트된 미션 정보 반환
          final updatedMission = Map<String, dynamic>.from(widget.mission);
          updatedMission['finishScore'] = score;
          updatedMission['isRewarded'] = true; // 0원 전송으로 평가 완료 처리됨

          Navigator.pop(context, updatedMission);
        }
      } else {
        print('🎯 오류: 미션 ID 또는 자녀 ID가 null임');
        print('🎯 미션 ID: $missionId, 자녀 ID: $childId');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('미션 정보 또는 자녀 정보를 찾을 수 없습니다'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('🎯 점수 입력 실패: $e');
      print('🎯 스택 트레이스: ${StackTrace.current}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('점수 입력에 실패했습니다: $e'),
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
      print('🎯 미션 점수만 입력: _submitScoreOnly 종료');
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
                      _buildMissionInfoCard(),
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
              '활동 평가하기',
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
    return Text(
      '${childName}님이 이번 미션을 완료했습니다!\n열심히 달성한 아이에게 보상을 전해주세요!',
      style: TextStyle(
        color: const Color(0xFF202020),
        fontSize: 16,
        fontFamily: 'Pretendard-Bold',
        height: 1.50,
        letterSpacing: -0.80,
      ),
    );
  }

  Widget _buildMissionInfoCard() {
    return Column(
      children: [
        // 미션 이미지 영역
        Container(
          width: 358,
          height: 256,
          decoration: ShapeDecoration(
            color: const Color(0xFF5D9EFF),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          child: Center(
            child: Image.asset(
              'assets/icons/parent/mission/score.png',
              width: 280,
              height: 233,
              fit: BoxFit.contain,
              errorBuilder:
                  (context, error, stackTrace) => Icon(
                    Icons.assignment_turned_in,
                    size: 180,
                    color: Colors.white,
                  ),
            ),
          ),
        ),
        const SizedBox(height: 32),

        // 미션 정보 카드
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
                '${childName}님의 이번 활동 정보',
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
                  _buildTag('미션', const Color(0xFFFFD27F)),
                  _buildTag(missionType, const Color(0xFF5D9EFF)),
                  _buildTag(missionDuration, const Color(0xFF5D9EFF)),
                ],
              ),
              const SizedBox(height: 12),

              // 미션 제목
              Text(
                missionTitle,
                style: TextStyle(
                  color: const Color(0xFF353535),
                  fontSize: 18,
                  fontFamily: 'Pretendard-Bold',
                  letterSpacing: -0.72,
                ),
              ),
              const SizedBox(height: 16),

              // 진행 시간과 보상금
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem('진행 시간', '30시간'), // 임시 데이터
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: _buildInfoItem('보상금', '${missionReward}원')),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: ShapeDecoration(
        color: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontFamily: 'Pretendard-Light',
          letterSpacing: -0.24,
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '이번 미션에 대한 점수를 기입해 주세요!',
          style: TextStyle(
            color: const Color(0xFF202020),
            fontSize: 18,
            fontFamily: 'Pretendard-Bold',
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '우리 아이의 이번 활동이 어땠는지 떠올려 주세요',
          style: TextStyle(
            color: const Color(0xFF999999),
            fontSize: 14,
            fontFamily: 'Pretendard-Light',
            letterSpacing: -0.28,
          ),
        ),
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: ShapeDecoration(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              side: BorderSide(width: 0.80, color: const Color(0xFFDADADA)),
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          child: TextField(
            controller: _scoreController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: '0~100점 사이로 입력해 주세요',
              hintStyle: TextStyle(
                color: const Color(0xFF999999),
                fontSize: 14,
                fontFamily: 'Pretendard-Light',
                letterSpacing: -0.28,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
            style: TextStyle(
              color: const Color(0xFF202020),
              fontSize: 14,
              fontFamily: 'Pretendard-Medium',
              letterSpacing: -0.28,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSendButton() {
    return Column(
      children: [
        // 보상금 보내기 버튼
        Container(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _submitScoreAndSendReward,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF146AFF),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
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
        ),
        const SizedBox(height: 12),

        // 점수만 입력하기 버튼
        Container(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _isLoading ? null : _submitScoreOnly,
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.transparent,
              side: BorderSide(
                color:
                    _isLoading
                        ? const Color(0xFF999999)
                        : const Color(0xFF80B2FD),
                width: 1,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
            ),
            child: Text(
              '점수만 입력하기',
              style: TextStyle(
                color:
                    _isLoading
                        ? const Color(0xFF999999)
                        : const Color(0xFF80B2FD),
                fontSize: 14,
                fontFamily: 'Pretendard-Medium',
                letterSpacing: -0.28,
              ),
            ),
          ),
        ),
      ],
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
              Container(
                width: 16,
                height: 16,
                child: Image.asset(
                  'assets/icons/parent/my/inform.png',
                  width: 16,
                  height: 16,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.info_outline,
                      size: 16,
                      color: const Color(0xFF666666),
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '리틀뱅크에서는 일정 주기마다 분석 리포트를 제공하고 있어요',
                  style: TextStyle(
                    color: const Color(0xFF202020),
                    fontSize: 10,
                    fontFamily: 'Pretendard-Bold',
                    letterSpacing: -0.24,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '7일, 14일, 30일, 60일, 90일을 기준으로 자녀의 활동에 관한 총 분석 리포트를 제공하고 있어요. 다양한 활동 기록을 통해 성장한 자녀의 모습을 지켜보세요.',
            style: TextStyle(
              color: const Color(0xFF4A4A4A),
              fontSize: 10,
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
