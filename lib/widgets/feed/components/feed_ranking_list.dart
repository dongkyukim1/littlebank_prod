import 'package:flutter/material.dart';

class RankingList extends StatefulWidget {
  final int totalUsers;

  const RankingList({super.key, this.totalUsers = 20});

  @override
  State<RankingList> createState() => _RankingListState();
}

class _RankingListState extends State<RankingList> {
  int _selectedTab = 0; // 0: 전체, 1: 친한 친구

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 랭킹 탭 메뉴
        Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade300, width: 1.0),
            ),
          ),
          child: Row(
            children: [
              // 전체 탭
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _selectedTab = 0),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color:
                              _selectedTab == 0
                                  ? Colors.black
                                  : Colors.transparent,
                          width: 2.0,
                        ),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '전체',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _selectedTab == 0 ? Colors.black : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // 친한 친구 탭
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _selectedTab = 1),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color:
                              _selectedTab == 1
                                  ? Colors.black
                                  : Colors.transparent,
                          width: 2.0,
                        ),
                      ),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '친한 친구',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color:
                                  _selectedTab == 1
                                      ? Colors.black
                                      : Colors.grey,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(
                            Icons.arrow_drop_down,
                            size: 16,
                            color:
                                _selectedTab == 1 ? Colors.black : Colors.grey,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // 랭킹 목록
        Expanded(child: _buildRankingList()),
      ],
    );
  }

  Widget _buildRankingList() {
    // 상위 3명과 나머지 분리
    return CustomScrollView(
      slivers: [
        // 상위 3명 (가로 배치)
        SliverToBoxAdapter(
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (int i = 0; i < 3; i++)
                  if (i < widget.totalUsers) _buildTopRankingItem(i + 1),
              ],
            ),
          ),
        ),

        // 나머지 랭킹 (세로 리스트)
        SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final rank = index + 4; // 4위부터 시작
            if (rank > widget.totalUsers) return null;

            return _buildNormalRankingItem(rank);
          }, childCount: widget.totalUsers - 3),
        ),
      ],
    );
  }

  Widget _buildTopRankingItem(int rank) {
    final medalColors = {
      1: Colors.yellow.shade700, // 금메달
      2: Colors.grey.shade400, // 은메달
      3: Colors.brown.shade300, // 동메달
    };

    return Expanded(
      child: Column(
        children: [
          // 순위 표시
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: medalColors[rank],
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$rank',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          SizedBox(height: 4),
          // 프로필 이미지
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white,
            child: ClipOval(
              child: Image.asset(
                'assets/logos/search-sm.png',
                width: 50,
                height: 50,
                fit: BoxFit.cover,
              ),
            ),
          ),
          SizedBox(height: 8),
          // 이름
          Text(
            '사용자 $rank',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          // 미션 수
          Container(
            margin: EdgeInsets.only(top: 4),
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.yellow.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${widget.totalUsers - rank + 1}/${widget.totalUsers}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.orange.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNormalRankingItem(int rank) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      margin: EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          // 순위
          Container(
            width: 24,
            alignment: Alignment.center,
            child: Text(
              '$rank',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(width: 16),
          // 프로필 이미지
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.white,
            child: ClipOval(
              child: Image.asset(
                'assets/logos/search-sm.png',
                width: 32,
                height: 32,
                fit: BoxFit.cover,
              ),
            ),
          ),
          SizedBox(width: 12),
          // 이름과 미션 정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '사용자 $rank',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${widget.totalUsers - rank + 1}/${widget.totalUsers} 미션',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          // 관찰 버튼
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '관찰',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
          ),
        ],
      ),
    );
  }
}
