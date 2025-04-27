import 'package:flutter/material.dart';

class ActivityHistoryScreen extends StatefulWidget {
  const ActivityHistoryScreen({super.key});

  @override
  State<ActivityHistoryScreen> createState() => _ActivityHistoryScreenState();
}

class _ActivityHistoryScreenState extends State<ActivityHistoryScreen> with SingleTickerProviderStateMixin {
  // late TabController _tabController;
  TabController? _tabController;
  int _selectedIndex = 0;
  bool _isMissionInProgress = true;
  bool _isChallengeInProgress = true;
  bool _isGoalInProgress = true;
  
  @override
  void initState() {
    super.initState();
    // 안전하게 초기화
    _initTabController();
  }
  
  void _initTabController() {
    try {
      _tabController = TabController(length: 3, vsync: this);
      _tabController?.addListener(() {
        if (_tabController!.indexIsChanging) {
          setState(() {
            _selectedIndex = _tabController!.index;
          });
        }
      });
    } catch (e) {
      print('TabController 초기화 오류: $e');
    }
  }
  
  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    // TabController가 null인 경우를 대비한 안전 확인
    if (_tabController == null) {
      _initTabController();
    }
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          '활동 내역',
          style: TextStyle(
            color: Color(0xFF202020),
            fontSize: 15,
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 16),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Image.asset(
              'assets/images/home.png', 
              width: 20, 
              height: 20,
            ),
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ],
        bottom: null,
      ),
      body: Column(
        children: [
          // TabBar 직접 구현
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Colors.white,
            ),
            child: TabBar(
              controller: _tabController,
              dividerColor: Colors.transparent, // 탭바 하단 구분선 제거
              indicator: UnderlineTabIndicator(
                borderSide: BorderSide(width: 3.0, color: Colors.black),
                insets: EdgeInsets.zero, // 인디케이터 여백 제거
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Color(0xFF000000),
              unselectedLabelColor: Colors.grey,
              labelPadding: EdgeInsets.zero, // 라벨 패딩 제거
              tabAlignment: TabAlignment.fill, // 탭을 화면 너비에 맞게 균등하게 배치
              labelStyle: const TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
              unselectedLabelStyle: const TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 15,
                fontWeight: FontWeight.w400,
              ),
              tabs: const [
                Tab(text: '미션', height: 28),
                Tab(text: '챌린지', height: 28),
                Tab(text: '목표', height: 28),
              ],
            ),
          ),
          // 나머지 화면 내용
          Expanded(
            child: _tabController == null 
                ? const Center(child: CircularProgressIndicator())
                : Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      // 모든 테두리 제거
                    ),
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildMissionTab(),
                        _buildChallengeTab(),
                        _buildGoalTab(),
                      ],
                    ),
                  ),
          ),
          _selectedIndex == 0 ? _buildAnalyticsReportButton() : SizedBox(),
        ],
      ),
    );
  }

  // 분석 리포트 버튼
  Widget _buildAnalyticsReportButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(
        top: 24,
        left: 16,
        right: 16,
        bottom: 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x5B000000),
            blurRadius: 8,
            offset: Offset(0, -4),
            spreadRadius: 0,
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
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
                  '분석 리포트 보러가기',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.28,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 미션 탭 내용
  Widget _buildMissionTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 완료한 미션 알림 섹션
          _buildCompletedMissionSection(),
          
          const SizedBox(height: 0),
          
          // 미션 필터 섹션
          _buildFilterSection(_isMissionInProgress, (value) {
            setState(() {
              _isMissionInProgress = value;
            });
          }),
          
          const SizedBox(height: 6),
          
          // 미션 목록 섹션
          _buildMissionListSection(),
        ],
      ),
    );
  }
  
  // 챌린지 탭 내용
  Widget _buildChallengeTab() {
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
          _buildFilterSection(_isChallengeInProgress, (value) {
            setState(() {
              _isChallengeInProgress = value;
            });
          }),
          
          const SizedBox(height: 6),
          
          // 챌린지 목록 섹션
          _buildChallengeListSection(),
        ],
      ),
    );
  }
  
  // 목표 탭 내용
  Widget _buildGoalTab() {
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
          _buildFilterSection(_isGoalInProgress, (value) {
            setState(() {
              _isGoalInProgress = value;
            });
          }),
          
          const SizedBox(height: 6),
          
          // 목표 목록 섹션
          _buildGoalListSection(),
        ],
      ),
    );
  }

  // 완료한 미션 알림 섹션
  Widget _buildCompletedMissionSection() {
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
          const Text(
            '최근에 완료한 미션이 있네요!\n피드에 자랑해 볼까요?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
          
          const SizedBox(height: 12),
          
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        '이번 주 저녁 청소 담당',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Color(0xFF353535),
                          fontSize: 14,
                          fontFamily: 'Pretendard',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          '피드 작성하기',
                          style: TextStyle(
                            color: Color(0xFF001F55),
                            fontSize: 11,
                            fontFamily: 'Pretendard',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.edit_outlined,
                          size: 12,
                          color: Color(0xFF001F55),
                        ),
                      ],
                    ),
                  ],
                ),
                
                const SizedBox(height: 10),
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: Color(0xFFEEEEEE),
                ),
                const SizedBox(height: 10),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '3.20 - 3.27   97%',
                      style: TextStyle(
                        color: Color(0xFF999999),
                        fontSize: 12,
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '25,000',
                            style: TextStyle(
                              color: Color(0xFF146AFF),
                              fontSize: 13,
                              fontFamily: 'Pretendard',
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          TextSpan(
                            text: '원',
                            style: TextStyle(
                              color: Color(0xFF4A4A4A),
                              fontSize: 12,
                              fontFamily: 'Pretendard',
                              fontWeight: FontWeight.w500,
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
        ],
      ),
    );
  }
  
  // 완료한 챌린지 알림 섹션
  Widget _buildCompletedChallengeSection() {
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
          const Text(
            '최근에 완료한 챌린지가 없어요!\n시작하려 가볼까요?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
          
          const SizedBox(height: 12),
          
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        '이번 주 매일 공부 3시간',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontFamily: 'Pretendard',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          '참여하러 가기',
                          style: TextStyle(
                            color: Color(0xFF001F55),
                            fontSize: 11,
                            fontFamily: 'Pretendard',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.arrow_forward_ios,
                          size: 12,
                          color: Color(0xFF001F55),
                        ),
                      ],
                    ),
                  ],
                ),
                
                const SizedBox(height: 10),
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: Color(0xFFEEEEEE),
                ),
                const SizedBox(height: 10),
                
                // 참여 인원만 표시하고 보상금 제거
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '참여 인원 ',
                          style: TextStyle(
                            color: Color(0xFF999999),
                            fontSize: 12,
                            fontFamily: 'Pretendard',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextSpan(
                          text: '30',
                          style: TextStyle(
                            color: Color(0xFF89DA8D),
                            fontSize: 12,
                            fontFamily: 'Pretendard',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        TextSpan(
                          text: '/40',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 12,
                            fontFamily: 'Pretendard',
                            fontWeight: FontWeight.w700,
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
    );
  }
  
  // 완료한 목표 알림 섹션
  Widget _buildCompletedGoalSection() {
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
          const Text(
            '최근에 완료한 목표가 있네요!\n피드에 자랑해 볼까요?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
          
          const SizedBox(height: 12),
          
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        '이번 주 저녁 청소 담당',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Color(0xFF353535),
                          fontSize: 14,
                          fontFamily: 'Pretendard',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          '피드 작성하기',
                          style: TextStyle(
                            color: Color(0xFF001F55),
                            fontSize: 11,
                            fontFamily: 'Pretendard',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.edit_outlined,
                          size: 12,
                          color: Color(0xFF001F55),
                        ),
                      ],
                    ),
                  ],
                ),
                
                const SizedBox(height: 10),
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: Color(0xFFEEEEEE),
                ),
                const SizedBox(height: 10),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '3.20 - 3.27',
                      style: TextStyle(
                        color: Color(0xFF999999),
                        fontSize: 12,
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '25,000',
                            style: TextStyle(
                              color: Color(0xFF146AFF),
                              fontSize: 13,
                              fontFamily: 'Pretendard',
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          TextSpan(
                            text: '원',
                            style: TextStyle(
                              color: Color(0xFF4A4A4A),
                              fontSize: 12,
                              fontFamily: 'Pretendard',
                              fontWeight: FontWeight.w500,
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
        ],
      ),
    );
  }

  // 미션 목록 섹션
  Widget _buildMissionListSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMissionItemTag('미션', '3월 셋째주 미션', '가족 미션'),
          _buildMissionItem('이번 주 저녁 설거지 담당', '3.20 - 3.27', '38%', '25,000원'),
          const SizedBox(height: 2),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
          ),
          const SizedBox(height: 2),
          _buildMissionItemTag('미션', '3월 셋째주 미션', '가족 미션'),
          _buildMissionItem('이번 주 저녁 설거지 담당', '3.20 - 3.27', '38%', '25,000원'),
        ],
      ),
    );
  }
  
  // 챌린지 목록 섹션
  Widget _buildChallengeListSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildChallengeItemTags('챌린지', '요일별', '3.20 - 3.27'),
          _buildChallengeItem('이번 주 저녁 설거지 담당', '30/40', '25,000원'),
          const SizedBox(height: 6),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
          ),
          const SizedBox(height: 6),
          _buildChallengeItemTags('챌린지', '요일별', '3.20 - 3.27'),
          _buildChallengeItem('이번 주 저녁 설거지 담당', '30/40', '25,000원'),
        ],
      ),
    );
  }
  
  // 목표 목록 섹션
  Widget _buildGoalListSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGoalItemTags('목표', '습관 형성', '3.20 - 3.27'),
          _buildGoalItem('이번 주 저녁 청소 담당', '3.20 - 3.27', '25,000원'),
          const SizedBox(height: 6),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
          ),
          const SizedBox(height: 6),
          _buildGoalItemTags('목표', '학습 인증', '3.20 - 3.27'),
          _buildGoalItem('이번 주 저녁 청소 담당', '3.20 - 3.27', '25,000원'),
        ],
      ),
    );
  }
  
  // 미션 아이템 태그 위젯
  Widget _buildMissionItemTag(String tag1, String tag2, String tag3) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          _buildTagItem(tag1, const Color(0xFFFFD27F)),
          _buildTagItem(tag2, const Color(0xFF5D9EFF)),
          _buildTagItem(tag3, const Color(0xFF5D9EFF)),
        ],
      ),
    );
  }
  
  // 챌린지 아이템 태그 위젯
  Widget _buildChallengeItemTags(String tag1, String tag2, String tag3) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          _buildTagItem(tag1, const Color(0xFF5D9EFF)),
          _buildTagItem(tag2, const Color(0xFFFFD27F)),
          _buildTagItem(tag3, const Color(0xFF5D9EFF)),
        ],
      ),
    );
  }
  
  // 목표 아이템 태그 위젯
  Widget _buildGoalItemTags(String tag1, String tag2, String tag3) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          _buildTagItem(tag1, const Color(0xFFFFD27F)),
          _buildTagItem(tag2, const Color(0xFFFFD27F)),
          _buildTagItem(tag3, const Color(0xFF5D9EFF)),
        ],
      ),
    );
  }

  // 미션 아이템 위젯
  Widget _buildMissionItem(String title, String period, String progress, String reward) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 미션 제목
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF353535),
              fontSize: 16,
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w700,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // 미션 정보 영역
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    '기한',
                    style: const TextStyle(
                      color: Color(0xFF666666),
                      fontSize: 12,
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    period,
                    style: const TextStyle(
                      color: Color(0xFF4A4A4A),
                      fontSize: 12,
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Text(
                    '달성률',
                    style: const TextStyle(
                      color: Color(0xFF666666),
                      fontSize: 12,
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    progress,
                    style: const TextStyle(
                      color: Color(0xFF4A4A4A),
                      fontSize: 12,
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Text(
                    '보상금',
                    style: const TextStyle(
                      color: Color(0xFF666666),
                      fontSize: 12,
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '25,000',
                          style: TextStyle(
                            color: Color(0xFF146AFF),
                            fontSize: 12,
                            fontFamily: 'Pretendard',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        TextSpan(
                          text: '원',
                          style: TextStyle(
                            color: Color(0xFF4A4A4A),
                            fontSize: 11,
                            fontFamily: 'Pretendard',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  // 챌린지 아이템 위젯
  Widget _buildChallengeItem(String title, String participants, String reward) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 챌린지 제목
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF353535),
              fontSize: 16,
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w700,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // 챌린지 정보 영역 - 참여 인원과 보상금 표시
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    '참여 인원',
                    style: const TextStyle(
                      color: Color(0xFF666666),
                      fontSize: 12,
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    participants,
                    style: const TextStyle(
                      color: Color(0xFF4A4A4A),
                      fontSize: 12,
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Text(
                    '보상금',
                    style: const TextStyle(
                      color: Color(0xFF666666),
                      fontSize: 12,
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '25,000',
                          style: TextStyle(
                            color: Color(0xFF146AFF),
                            fontSize: 12,
                            fontFamily: 'Pretendard',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        TextSpan(
                          text: '원',
                          style: TextStyle(
                            color: Color(0xFF4A4A4A),
                            fontSize: 11,
                            fontFamily: 'Pretendard',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  // 목표 아이템 위젯
  Widget _buildGoalItem(String title, String period, String reward) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 목표 제목
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF353535),
              fontSize: 16,
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w700,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // 목표 정보 영역
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    '참여 인원',
                    style: const TextStyle(
                      color: Color(0xFF666666),
                      fontSize: 12,
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '30/40',
                    style: const TextStyle(
                      color: Color(0xFF4A4A4A),
                      fontSize: 12,
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Text(
                    '보상금',
                    style: const TextStyle(
                      color: Color(0xFF666666),
                      fontSize: 12,
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '25,000',
                          style: TextStyle(
                            color: Color(0xFF146AFF),
                            fontSize: 12,
                            fontFamily: 'Pretendard',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        TextSpan(
                          text: '원',
                          style: TextStyle(
                            color: Color(0xFF4A4A4A),
                            fontSize: 11,
                            fontFamily: 'Pretendard',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 태그 아이템 위젯
  Widget _buildTagItem(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: ShapeDecoration(
        color: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontFamily: 'Pretendard',
          fontWeight: FontWeight.w300,
        ),
      ),
    );
  }

  // 공통 필터 섹션 - 적립금 내역 디자인으로 변경
  Widget _buildFilterSection(bool isInProgress, Function(bool) onChanged) {
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
          // 진행중 버튼
          GestureDetector(
            onTap: () => onChanged(true),
            child: Container(
              height: 36,
              width: 70,
              decoration: BoxDecoration(
                color: isInProgress ? const Color(0xFF3A88F4) : const Color(0xFFDEDEDE),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isInProgress ? 0.15 : 0.1),
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
                  color: isInProgress ? Colors.white : const Color(0xFF999999),
                  fontSize: 14,
                  fontFamily: 'Pretendard',
                  fontWeight: isInProgress ? FontWeight.w500 : FontWeight.w300,
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 12), // 버튼 간 간격
          
          // 완료한 버튼
          GestureDetector(
            onTap: () => onChanged(false),
            child: Container(
              height: 36,
              width: 70,
              decoration: BoxDecoration(
                color: !isInProgress ? const Color(0xFF3A88F4) : const Color(0xFFDEDEDE),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(!isInProgress ? 0.15 : 0.1),
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
                  color: !isInProgress ? Colors.white : const Color(0xFF999999),
                  fontSize: 14,
                  fontFamily: 'Pretendard',
                  fontWeight: !isInProgress ? FontWeight.w500 : FontWeight.w300,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 