import 'package:flutter/material.dart';
import 'dart:math';
import '../../../../services/challenge_service.dart';
import '../../challenge/all_challenges_screen.dart';

class ChallengeHistoryTab extends StatefulWidget {
  const ChallengeHistoryTab({Key? key}) : super(key: key);

  @override
  State<ChallengeHistoryTab> createState() => _ChallengeHistoryTabState();
}

class _ChallengeHistoryTabState extends State<ChallengeHistoryTab> {
  bool _isChallengeInProgress = true;
  
  // 챌린지 데이터 관련 상태
  List<ChallengeParticipation> _challengeList = [];
  bool _isChallengeLoading = false;
  String? _challengeError;
  
  // 전체 데이터 확인을 위한 상태
  bool _hasOngoingChallenges = false;
  bool _hasCompletedChallenges = false;
  bool _hasCheckedAllData = false;
  
  // 추천 챌린지 관련 상태
  Challenge? _recommendedChallenge;
  bool _isRecommendedChallengeLoading = false;
  String? _recommendedChallengeError;

  @override
  void initState() {
    super.initState();
    _loadChallengeData();
    _loadRecommendedChallenge();
  }

  // 챌린지 데이터 로드
  Future<void> _loadChallengeData() async {
    setState(() {
      _isChallengeLoading = true;
      _challengeError = null;
    });

    try {
      final challengeStatus = _isChallengeInProgress 
          ? ChallengeStatus.ONGOING
          : ChallengeStatus.COMPLETED;
      
      final response = await ChallengeService.getMyChallenges(
        challengeStatus: challengeStatus,
        page: 0,
      );
      
      setState(() {
        _challengeList = response.data;
        _isChallengeLoading = false;
      });
      
      // 전체 데이터 확인을 위해 양쪽 상태 체크
      await _checkAllChallengeData();
    } catch (e) {
      setState(() {
        _challengeError = e.toString();
        _isChallengeLoading = false;
      });
    }
  }

  // 전체 챌린지 데이터 확인
  Future<void> _checkAllChallengeData() async {
    if (_hasCheckedAllData) return;
    
    try {
      // 진행중 챌린지 확인
      final ongoingResponse = await ChallengeService.getMyChallenges(
        challengeStatus: ChallengeStatus.ONGOING,
        page: 0,
      );
      
      // 완료한 챌린지 확인
      final completedResponse = await ChallengeService.getMyChallenges(
        challengeStatus: ChallengeStatus.COMPLETED,
        page: 0,
      );
      
      setState(() {
        _hasOngoingChallenges = ongoingResponse.data.isNotEmpty;
        _hasCompletedChallenges = completedResponse.data.isNotEmpty;
        _hasCheckedAllData = true;
      });
    } catch (e) {
      // 에러 발생 시 데이터가 있다고 가정
      setState(() {
        _hasOngoingChallenges = true;
        _hasCompletedChallenges = true;
        _hasCheckedAllData = true;
      });
    }
  }

  // 추천 챌린지 데이터 로드
  Future<void> _loadRecommendedChallenge() async {
    setState(() {
      _isRecommendedChallengeLoading = true;
      _recommendedChallengeError = null;
    });

    try {
      final response = await ChallengeService.getChallenges(
        category: ChallengeCategory.ALL,
        page: 0,
      );
      
      if (response.data.isNotEmpty) {
        final random = Random();
        final randomIndex = random.nextInt(response.data.length);
        setState(() {
          _recommendedChallenge = response.data[randomIndex];
          _isRecommendedChallengeLoading = false;
        });
      } else {
        setState(() {
          _recommendedChallengeError = '추천할 챌린지가 없습니다.';
          _isRecommendedChallengeLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _recommendedChallengeError = e.toString();
        _isRecommendedChallengeLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 전체 데이터가 없는 경우 빈 상태 화면만 표시
    if (_hasCheckedAllData && !_hasOngoingChallenges && !_hasCompletedChallenges) {
      return SingleChildScrollView(
        padding: EdgeInsets.zero,
        child: _buildEmptyChallengeState(),
      );
    }
    
    // 데이터가 있거나 로딩 중이거나 에러가 있을 때는 전체 레이아웃 표시
    return SingleChildScrollView(
      padding: EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 완료한 챌린지 알림 섹션
          _buildCompletedChallengeSection(),
          
          const SizedBox(height: 0),
          
          // 챌린지 필터 섹션
          _buildFilterSection(),
          
          const SizedBox(height: 6),
          
          // 챌린지 목록 섹션
          _buildChallengeListSection(),
        ],
      ),
    );
  }

  // 완료한 챌린지 알림 섹션
  Widget _buildCompletedChallengeSection() {
    final hasCompletedChallenge = !_isChallengeInProgress && _challengeList.isNotEmpty;
    
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
            hasCompletedChallenge 
                ? '최근에 완료한 챌린지가 있네요!\n피드에 자랑해 볼까요?'
                : '최근에 완료한 챌린지가 없어요!\n새로운 챌린지를 시작해볼까요?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontFamily: 'Pretendard-Bold',
              height: 1.3,
            ),
          ),
          
          const SizedBox(height: 12),
          
          if (_isRecommendedChallengeLoading && !hasCompletedChallenge)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
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
              child: Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF3A88F4),
                  strokeWidth: 2,
                ),
              ),
            )
          else
            Container(
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
                            _getDisplayTitle(hasCompletedChallenge),
                            style: TextStyle(
                              color: const Color(0xFF353535),
                              fontSize: 14,
                              fontFamily: 'Pretendard-Bold',
                              letterSpacing: -0.32,
                            ),
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              hasCompletedChallenge ? '피드 작성하기' : '참여하러 가기',
                              style: TextStyle(
                                color: const Color(0xFF666666),
                                fontSize: 10,
                                fontFamily: 'Pretendard-Light',
                                letterSpacing: -0.24,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(
                              hasCompletedChallenge ? Icons.edit_outlined : Icons.arrow_forward_ios,
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
                        Expanded(
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  hasCompletedChallenge ? '기간 ' : '참여 인원 ',
                                  style: TextStyle(
                                    color: const Color(0xFF4A4A4A),
                                    fontSize: 12,
                                    fontFamily: 'Pretendard-Light',
                                    letterSpacing: -0.28,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                              SizedBox(width: hasCompletedChallenge ? 8 : 16),
                              Flexible(
                                child: Text(
                                  _getDisplayInfo(hasCompletedChallenge),
                                  style: TextStyle(
                                    color: const Color(0xFF4A4A4A),
                                    fontSize: 12,
                                    fontFamily: 'Pretendard-Medium',
                                    letterSpacing: -0.28,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Flexible(
                          child: _buildRewardInfo(hasCompletedChallenge),
                        ),
                      ],
                    ),
                  ),
                ],
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
                _isChallengeInProgress = true;
              });
              _loadChallengeData();
            },
            child: Container(
              height: 36,
              width: 70,
              decoration: BoxDecoration(
                color: _isChallengeInProgress ? const Color(0xFF3A88F4) : const Color(0xFFDEDEDE),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(_isChallengeInProgress ? 0.15 : 0.1),
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
                  color: _isChallengeInProgress ? Colors.white : const Color(0xFF999999),
                  fontSize: 12,
                  fontFamily: _isChallengeInProgress ? 'Pretendard-Light' : 'Pretendard-ExtraLight',
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          GestureDetector(
            onTap: () {
              setState(() {
                _isChallengeInProgress = false;
              });
              _loadChallengeData();
            },
            child: Container(
              height: 36,
              width: 70,
              decoration: BoxDecoration(
                color: !_isChallengeInProgress ? const Color(0xFF3A88F4) : const Color(0xFFDEDEDE),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(!_isChallengeInProgress ? 0.15 : 0.1),
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
                  color: !_isChallengeInProgress ? Colors.white : const Color(0xFF999999),
                  fontSize: 12,
                  fontFamily: !_isChallengeInProgress ? 'Pretendard-Light' : 'Pretendard-ExtraLight',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 챌린지 목록 섹션
  Widget _buildChallengeListSection() {
    if (_isChallengeLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF3A88F4),
          ),
        ),
      );
    }
    
    if (_challengeError != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
        child: Center(
          child: Column(
            children: [
              Text(
                '챌린지를 불러오는 중 오류가 발생했습니다.',
                style: TextStyle(
                  color: Color(0xFF999999),
                  fontSize: 14,
                  fontFamily: 'Pretendard-Light',
                ),
              ),
              SizedBox(height: 8),
              ElevatedButton(
                onPressed: _loadChallengeData,
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
    if (_challengeList.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 16),
        child: Center(
          child: Text(
            _isChallengeInProgress ? '진행중인 챌린지가 없습니다.' : '완료한 챌린지가 없습니다.',
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
          ...List.generate(_challengeList.length, (index) {
            final challenge = _challengeList[index];
            
            return Column(
              children: [
                _buildChallengeItem(challenge),
                if (index < _challengeList.length - 1)
                  const SizedBox(height: 24),
              ],
            );
          }),
        ],
      ),
    );
  }

  // 챌린지가 없을 때 안내 화면
  Widget _buildEmptyChallengeState() {
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
                            '조회할 수 있는 챌린지가 없습니다!',
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
                            '챌린지에 참여하고 성취감을 느껴보세요!',
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
                            builder: (context) => AllChallengesScreen(),
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
                              '모든 챌린지 보기',
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

  // 챌린지 아이템 위젯
  Widget _buildChallengeItem(ChallengeParticipation challenge) {
    final String titleText = (challenge.subject != null && challenge.subject != "null" && challenge.subject!.isNotEmpty) 
        ? challenge.subject! 
        : challenge.title;
    final String categoryDisplayNameText = challenge.subject != null ? '과목별' : '요일별';
    final String periodText = _formatDatePeriod(challenge.startDate, challenge.endDate);
    
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: ShapeDecoration(
                    color: const Color(0xFFFFD27F),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(
                    '챌린지',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontFamily: 'Pretendard-Light',
                      letterSpacing: -0.24,
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: ShapeDecoration(
                    color: const Color(0xFF5D9EFF),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(
                    categoryDisplayNameText,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontFamily: 'Pretendard-Light',
                      letterSpacing: -0.24,
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: ShapeDecoration(
                    color: const Color(0xFF5D9EFF),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(
                    periodText,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontFamily: 'Pretendard-Light',
                      letterSpacing: -0.24,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(height: 12),
          
          // 제목
          Text(
            titleText,
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
                      _calculateChallengeDDay(challenge),
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
                      '진행 시간',
                      style: TextStyle(
                        color: const Color(0xFF666666),
                        fontSize: 12,
                        fontFamily: 'Pretendard-Light',
                        letterSpacing: -0.28,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      _calculateProgressTime(challenge),
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
                      challenge.reward != null ? '${_formatNumber(challenge.reward!)}원' : '미정',
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
  String _getDisplayTitle(bool hasCompletedChallenge) {
    if (hasCompletedChallenge && _challengeList.isNotEmpty) {
      return _challengeList.first.title;
    } else if (!hasCompletedChallenge && _recommendedChallenge != null) {
      return _recommendedChallenge!.title;
    } else {
      return '추천 챌린지 로딩 중...';
    }
  }

  String _getDisplayInfo(bool hasCompletedChallenge) {
    if (hasCompletedChallenge && _challengeList.isNotEmpty) {
      return '${_challengeList.first.startDate} - ${_challengeList.first.endDate}';
    } else if (!hasCompletedChallenge && _recommendedChallenge != null) {
      return '${_recommendedChallenge!.currentParticipants}/${_recommendedChallenge!.totalParticipants}';
    } else {
      return '로딩 중...';
    }
  }

  Widget _buildRewardInfo(bool hasCompletedChallenge) {
    if (hasCompletedChallenge && _challengeList.isNotEmpty) {
      return Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '${_calculateTotalStudyTime(_challengeList.first)}',
              style: TextStyle(
                color: const Color(0xFF146AFF),
                fontSize: 14,
                fontFamily: 'Pretendard-Bold',
                letterSpacing: -0.32,
              ),
            ),
            TextSpan(
              text: '시간',
              style: TextStyle(
                color: const Color(0xFF000000),
                fontSize: 14,
                fontFamily: 'Pretendard-Medium',
                letterSpacing: -0.32,
              ),
            ),
          ],
        ),
        textAlign: TextAlign.end,
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      );
    } else if (!hasCompletedChallenge && _recommendedChallenge != null) {
      return Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '${_recommendedChallenge!.totalStudyTime}',
              style: TextStyle(
                color: const Color(0xFF146AFF),
                fontSize: 14,
                fontFamily: 'Pretendard-Bold',
                letterSpacing: -0.32,
              ),
            ),
            TextSpan(
              text: '시간',
              style: TextStyle(
                color: const Color(0xFF000000),
                fontSize: 14,
                fontFamily: 'Pretendard-Medium',
                letterSpacing: -0.32,
              ),
            ),
          ],
        ),
        textAlign: TextAlign.end,
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      );
    }
    return SizedBox.shrink();
  }

  String _formatDatePeriod(String startDate, String endDate) {
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

  String _calculateChallengeDDay(ChallengeParticipation challenge) {
    try {
      final endDate = DateTime.parse(challenge.endDate);
      final now = DateTime.now();
      
      final endDateOnly = DateTime(endDate.year, endDate.month, endDate.day);
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

  String _calculateProgressTime(ChallengeParticipation challenge) {
    try {
      final startDate = DateTime.parse(challenge.startDate);
      final now = DateTime.now();
      final endDate = DateTime.parse(challenge.endDate);
      
      if (now.isBefore(startDate)) {
        return '0시간 0분';
      }
      
      if (now.isAfter(endDate)) {
        final totalHours = _calculateTotalStudyTime(challenge);
        return '${totalHours}시간 0분';
      }
      
      final elapsedDays = now.difference(startDate).inDays + 1;
      final dailyTarget = challenge.totalStudyTime;
      
      final progressRatio = 0.7;
      final expectedHours = (elapsedDays * dailyTarget * progressRatio).round();
      
      final hours = expectedHours;
      final minutes = ((elapsedDays * dailyTarget * progressRatio - expectedHours) * 60).round();
      
      if (hours > 0) {
        return '${hours}시간 ${minutes}분';
      } else {
        return '${minutes}분';
      }
    } catch (e) {
      return '0시간 0분';
    }
  }

  int _calculateTotalStudyTime(ChallengeParticipation challenge) {
    try {
      final startDate = DateTime.parse(challenge.startDate);
      final endDate = DateTime.parse(challenge.endDate);
      
      final duration = endDate.difference(startDate).inDays + 1;
      
      return challenge.totalStudyTime * duration;
    } catch (e) {
      return challenge.totalStudyTime;
    }
  }

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }
} 