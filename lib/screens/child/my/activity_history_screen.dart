import 'package:flutter/material.dart';
import 'history/mission_history_tab.dart';
import 'history/challenge_history_tab.dart';
import 'history/goal_history_tab.dart';

class ActivityHistoryScreen extends StatefulWidget {
  final int initialTabIndex;

  const ActivityHistoryScreen({Key? key, this.initialTabIndex = 0})
    : super(key: key);

  @override
  State<ActivityHistoryScreen> createState() => _ActivityHistoryScreenState();
}

class _ActivityHistoryScreenState extends State<ActivityHistoryScreen>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;
  int _selectedIndex = 0;
  bool _isMissionEmpty = false; // 미션 탭이 빈 상태인지 추적

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
    _selectedIndex = widget.initialTabIndex;

    _tabController?.addListener(() {
      if (_tabController!.indexIsChanging) {
        setState(() {
          _selectedIndex = _tabController!.index;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_tabController == null) {
      _tabController = TabController(
        length: 3,
        vsync: this,
        initialIndex: widget.initialTabIndex,
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          '활동 내역',
          style: TextStyle(
            color: Color(0xFF202020),
            fontSize: 15,
            fontFamily: 'Pretendard-Bold',
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: Image.asset('assets/icons/my/뒤로가기.png', width: 20, height: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // TabBar
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(color: Colors.white),
            child: TabBar(
              controller: _tabController,
              dividerColor: Colors.transparent,
              indicator: UnderlineTabIndicator(
                borderSide: BorderSide(width: 3.0, color: Colors.black),
                insets: EdgeInsets.zero,
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Color(0xFF000000),
              unselectedLabelColor: Colors.grey,
              labelPadding: EdgeInsets.zero,
              tabAlignment: TabAlignment.fill,
              labelStyle: const TextStyle(
                fontFamily: 'Pretendard-Black',
                fontSize: 13,
              ),
              unselectedLabelStyle: const TextStyle(
                fontFamily: 'Pretendard-Regular',
                fontSize: 13,
              ),
              tabs: const [
                Tab(text: '미션', height: 28),
                Tab(text: '챌린지', height: 28),
                Tab(text: '목표', height: 28),
              ],
            ),
          ),
          // TabBarView
          Expanded(
            child:
                _tabController == null
                    ? const Center(child: CircularProgressIndicator())
                    : Container(
                      decoration: BoxDecoration(color: Colors.white),
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          MissionHistoryTab(
                            onEmptyStateChanged: (isEmpty) {
                              setState(() {
                                _isMissionEmpty = isEmpty;
                              });
                            },
                          ),
                          ChallengeHistoryTab(),
                          GoalHistoryTab(),
                        ],
                      ),
                    ),
          ),
          // 분석 리포트 버튼 (미션 탭이면서 빈 상태가 아닐 때만 표시)
          (_selectedIndex == 0 && !_isMissionEmpty)
              ? _buildAnalyticsReportButton()
              : SizedBox(),
        ],
      ),
    );
  }

  // 분석 리포트 버튼
  Widget _buildAnalyticsReportButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 24, left: 16, right: 16, bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x5B000000),
            blurRadius: 8,
            offset: Offset(0, -4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
            decoration: ShapeDecoration(
              color: const Color(0xFF3A88F4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '분석 리포트 보러가기',
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
        ],
      ),
    );
  }
}
