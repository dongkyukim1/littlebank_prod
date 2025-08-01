import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/survey_service.dart';
import '../../../models/survey.dart';

class ParentVoteCard extends ConsumerStatefulWidget {
  const ParentVoteCard({super.key});

  @override
  ConsumerState<ParentVoteCard> createState() => _ParentVoteCardState();
}

class _ParentVoteCardState extends ConsumerState<ParentVoteCard> {
  int? _selectedIndex;
  bool _showBars = false;
  bool _animateBars = false;

  // 타이머 관련 변수
  Timer? _timer;
  Duration _remainingTime = Duration.zero;

  @override
  void initState() {
    super.initState();
    // 애니메이션 효과: 카드 렌더 후 막대가 채워지도록
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _showBars = true);
    });

    // 현재 남은 시간 계산
    _updateRemainingTime();

    // 타이머 시작
    _startTimer();

    // 설문 데이터 로드
    Future.microtask(() {
      ref.read(surveyNotifierProvider.notifier).loadCurrentSurvey();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateRemainingTime() {
    final now = DateTime.now();
    // 오늘 자정 시간 계산 (다음날 00:00:00)
    final midnight = DateTime(now.year, now.month, now.day + 1);

    // 현재 시간부터 자정까지 남은 시간 계산
    final difference = midnight.difference(now);

    if (difference.isNegative) {
      _remainingTime = Duration.zero;
    } else {
      _remainingTime = difference;
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _updateRemainingTime();
          // 자정이 지나면 타이머를 리셋하고 설문 데이터 다시 로드
          if (_remainingTime.inSeconds <= 0) {
            _updateRemainingTime();
            ref.read(surveyNotifierProvider.notifier).loadCurrentSurvey();
          }
        });
      }
    });
  }

  String _formatTime(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String hours = twoDigits(duration.inHours);
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
  }

  // 선택 옵션을 A, B, C로 변환
  String _getChoiceFromIndex(int index) {
    switch (index) {
      case 0:
        return 'A';
      case 1:
        return 'B';
      case 2:
        return 'C';
      default:
        return 'A';
    }
  }

  // 설문에 참여
  Future<void> _joinSurvey(Survey survey, int index) async {
    final choice = _getChoiceFromIndex(index);

    try {
      await ref
          .read(surveyNotifierProvider.notifier)
          .joinSurvey(survey.surveyId, choice);

      setState(() {
        _selectedIndex = index;
        _animateBars = false; // 먼저 리셋
      });

      // 약간의 딜레이 후 애니메이션 시작
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) setState(() => _animateBars = true);
      });
    } catch (e) {
      // 에러 처리
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('투표 참여 중 오류가 발생했습니다.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final surveyState = ref.watch(surveyNotifierProvider);

    return surveyState.when(
      data: (survey) {
        if (survey == null) {
          return _buildEmptySurveyCard();
        }

        // 이미 선택한 항목이 있으면 설정
        if (survey.choice != null && _selectedIndex == null) {
          switch (survey.choice) {
            case 'A':
              _selectedIndex = 0;
              break;
            case 'B':
              _selectedIndex = 1;
              break;
            case 'C':
              _selectedIndex = 2;
              break;
          }
          // 이미 투표한 경우 애니메이션 시작
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) setState(() => _animateBars = true);
          });
        }

        // 1등 index 구하기
        int firstIdx = 0;
        int maxPercent = survey.percentA;

        if (survey.percentB > maxPercent) {
          maxPercent = survey.percentB;
          firstIdx = 1;
        }
        if (survey.percentC > maxPercent) {
          maxPercent = survey.percentC;
          firstIdx = 2;
        }

        final totalVotes = survey.voteA + survey.voteB + survey.voteC;

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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 상단 파란 헤더
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: ShapeDecoration(
                    color: const Color(0xFF146AFF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: const ShapeDecoration(
                              color: Colors.white,
                              shape: OvalBorder(),
                            ),
                            child: Center(
                              child: Image.asset(
                                'assets/icons/parent/mission/투표.png',
                                width: 14,
                                height: 14,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '진행 중인 투표',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontFamily: 'Pretendard-Bold',
                              letterSpacing: -0.32,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        width: 135, // 타이머 텍스트가 충분히 표시될 수 있는 너비
                        decoration: ShapeDecoration(
                          color: const Color(0xFFE4ECF8),
                          shape: RoundedRectangleBorder(
                            side: BorderSide(width: 0.40, color: Colors.white),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              '⏰ ${_formatTime(_remainingTime)} 뒤에 끝나요',
                              style: TextStyle(
                                color: const Color(0xFF8490A3),
                                fontSize: 9,
                                fontFamily: 'Pretendard-Light',
                                letterSpacing: -0.22,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // 투표 정보 및 질문
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  color: Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 안내문구
                      Text(
                        '간단한 투표에 참여해 보세요!',
                        style: TextStyle(
                          color: const Color(0xFF202020),
                          fontSize: 16,
                          fontFamily: 'Pretendard-Bold',
                          letterSpacing: -0.72,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '결과를 확인하고 싶다면 투표에 참여해 보세요!',
                        style: TextStyle(
                          color: const Color(0xFF999999),
                          fontSize: 12,
                          fontFamily: 'Pretendard-Light',
                          letterSpacing: -0.28,
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                  ),
                ),
                // 투표 옵션/진행률
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 질문
                      Text(
                        'Q. ${survey.question}',
                        style: TextStyle(
                          color: const Color(0xFF202020),
                          fontSize: 14,
                          fontFamily: 'Pretendard-Light',
                          letterSpacing: -0.72,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // 참여자 수와 복수 선택 불가 안내 - 붙여서 배치
                      Row(
                        children: [
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: '${totalVotes.toString()}명',
                                  style: TextStyle(
                                    color: const Color(0xFF999999),
                                    fontSize: 9,
                                    fontFamily: 'Pretendard-Light',
                                    letterSpacing: -0.22,
                                  ),
                                ),
                                TextSpan(
                                  text: '이 참여 중',
                                  style: TextStyle(
                                    color: const Color(0xFFC4C4C4),
                                    fontSize: 9,
                                    fontFamily: 'Pretendard-Light',
                                    letterSpacing: -0.22,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8), // 간격 줄임
                          Text(
                            '·',
                            style: TextStyle(
                              color: const Color(0xFFC4C4C4),
                              fontSize: 9,
                              fontFamily: 'Pretendard-Light',
                              letterSpacing: -0.22,
                            ),
                          ),
                          const SizedBox(width: 8), // 간격 줄임
                          Text(
                            '복수 선택 불가',
                            style: TextStyle(
                              color: const Color(0xFFC4C4C4),
                              fontSize: 9,
                              fontFamily: 'Pretendard-Light',
                              letterSpacing: -0.22,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16), // 참여자 정보와 투표 선택지 사이 간격
                      // 투표 선택지들
                      _buildVoteOptionItem(
                        context: context,
                        survey: survey,
                        index: 0,
                        text: survey.optionA,
                        emoji: _getEmojiForOption(0),
                        percent: survey.percentA,
                        isFirst: firstIdx == 0,
                      ),
                      const SizedBox(height: 8),
                      _buildVoteOptionItem(
                        context: context,
                        survey: survey,
                        index: 1,
                        text: survey.optionB,
                        emoji: _getEmojiForOption(1),
                        percent: survey.percentB,
                        isFirst: firstIdx == 1,
                      ),
                      const SizedBox(height: 8),
                      _buildVoteOptionItem(
                        context: context,
                        survey: survey,
                        index: 2,
                        text: survey.optionC,
                        emoji: _getEmojiForOption(2),
                        percent: survey.percentC,
                        isFirst: firstIdx == 2,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => _buildLoadingCard(),
      error: (error, stackTrace) => _buildErrorCard(error.toString()),
    );
  }

  // 각 옵션에 대한 이모지 반환 (하드코딩)
  String _getEmojiForOption(int index) {
    switch (index) {
      case 0:
        return '💵';
      case 1:
        return '🎁';
      case 2:
        return '🕹️';
      default:
        return '📊';
    }
  }

  Widget _buildVoteOptionItem({
    required BuildContext context,
    required Survey survey,
    required int index,
    required String text,
    required String emoji,
    required int percent,
    required bool isFirst,
  }) {
    final isSelected = _selectedIndex == index;
    final hasVoted = _selectedIndex != null;

    return GestureDetector(
      onTap: hasVoted ? null : () => _joinSurvey(survey, index),
      child: _buildVoteOption(
        context,
        text: text,
        emoji: emoji,
        percent: percent,
        isSelected: isSelected,
        isFirst: isFirst,
        hasVoted: hasVoted,
      ),
    );
  }

  Widget _buildVoteOption(
    BuildContext context, {
    required String text,
    required String emoji,
    required int percent,
    required bool isSelected,
    required bool isFirst,
    required bool hasVoted,
  }) {
    // 애니메이션을 위한 막대 너비 계산
    final double screenWidth = MediaQuery.of(context).size.width;
    final double availableWidth = screenWidth - 40; // 좌우 padding 20씩
    final double barWidth =
        (hasVoted && _animateBars) ? (availableWidth * percent / 100) : 0;
    final Color boxBgColor = const Color(0xFFE4EDF8);

    return Column(
      children: [
        Stack(
          alignment: Alignment.centerLeft,
          children: [
            // 선택 후 모든 옵션에 배경색 막대
            if (hasVoted) // 투표 후에만 막대 표시
              AnimatedContainer(
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
                width: barWidth,
                height: 49,
                decoration: ShapeDecoration(
                  color:
                      isFirst
                          ? const Color(0xFF78ADFE)
                          : const Color(0xFFC4C4C4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            // 옵션 텍스트/체크 Row (항상 위)
            Container(
              width: double.infinity,
              height: 49,
              decoration: ShapeDecoration(
                color:
                    hasVoted ? Colors.transparent : boxBgColor, // 투표 후에는 투명하게
                shape: RoundedRectangleBorder(
                  side: BorderSide(width: 0.7, color: Color(0xFFDADADA)),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  // 라디오 버튼 (항상 표시)
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 16,
                      right: 12,
                    ), // 왼쪽 여백 증가
                    child:
                        isSelected
                            ? Image.asset(
                              'assets/icons/parent/mission/체크서클.png',
                              width: 20,
                              height: 20,
                              fit: BoxFit.contain,
                            )
                            : Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFFC4C4C4),
                                  width: 2,
                                ),
                                color: Colors.white,
                              ),
                            ),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            text,
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 12,
                              fontFamily:
                                  isSelected
                                      ? 'Pretendard-Bold'
                                      : 'Pretendard-Medium',
                              letterSpacing: -0.28,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8), // 이모지와의 간격 증가
                        Text(
                          emoji,
                          style: TextStyle(color: Colors.black, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  // 퍼센트는 투표 후에만 표시
                  if (hasVoted)
                    Padding(
                      padding: const EdgeInsets.only(right: 20), // 오른쪽 여백 증가
                      child: Text(
                        '$percent%',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 10,
                          fontFamily: 'Pretendard-Bold',
                          letterSpacing: -0.24,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        // 마지막 옵션이고 투표가 완료된 경우에만 메시지 표시
        if (hasVoted && emoji == '🕹️') // 마지막 옵션(C)의 이모지로 체크
          Container(
            margin: const EdgeInsets.only(top: 24), // 위쪽 여백 추가
            width: double.infinity,
            height: 49, // 선택 박스와 동일한 높이
            decoration: ShapeDecoration(
              color: const Color(0xFFDCDCDC),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12), // 선택 박스와 동일한 radius
              ),
            ),
            child: Center(
              child: Text(
                '내일 다시 만나요!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontFamily: 'Pretendard-Light',
                  letterSpacing: -0.24,
                ),
              ),
            ),
          ),
      ],
    );
  }

  // 빈 설문 카드
  Widget _buildEmptySurveyCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
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
      child: Center(
        child: Text(
          '진행 중인 투표가 없습니다.',
          style: TextStyle(
            color: const Color(0xFF999999),
            fontSize: 14,
            fontFamily: 'Pretendard-Regular',
          ),
        ),
      ),
    );
  }

  // 로딩 카드
  Widget _buildLoadingCard() {
    return Container(
      width: double.infinity,
      height: 300,
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
      child: Center(child: CircularProgressIndicator()),
    );
  }

  // 에러 카드
  Widget _buildErrorCard(String error) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
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
          Text(
            '설문을 불러올 수 없습니다.',
            style: TextStyle(
              color: const Color(0xFF999999),
              fontSize: 14,
              fontFamily: 'Pretendard-Regular',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(
              color: Colors.red,
              fontSize: 12,
              fontFamily: 'Pretendard-Regular',
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _VoteOption {
  final String text;
  final String emoji;
  final int percent;
  _VoteOption({required this.text, required this.emoji, required this.percent});
}
