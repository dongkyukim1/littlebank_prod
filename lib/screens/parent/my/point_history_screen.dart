import 'package:flutter/material.dart';

class PointHistoryScreen extends StatefulWidget {
  const PointHistoryScreen({super.key});

  @override
  State<PointHistoryScreen> createState() => _PointHistoryScreenState();
}

class _PointHistoryScreenState extends State<PointHistoryScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          '총 적립 내역',
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.home_outlined,
              color: Colors.black,
              size: 24,
            ),
            onPressed: () {
              // 홈으로 이동
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 총 적립금 정보 카드
          _buildTotalPointsCard(),

          // 내역 리스트
          Expanded(child: _buildHistoryList()),
        ],
      ),
    );
  }

  // 총 적립금 정보 카드
  Widget _buildTotalPointsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.withOpacity(0.2), width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 설명 텍스트
          Text(
            '오늘까지 총 목돈 적립금',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),

          const SizedBox(height: 4),

          // 총 금액
          Text(
            '415,000원',
            style: TextStyle(
              color: Colors.black,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 4),

          // 전월 대비
          Row(
            children: [
              Text(
                '지난 달보다 ',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
              Text(
                '+ 113,000원',
                style: TextStyle(
                  color: Colors.blue,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 내역 리스트
  Widget _buildHistoryList() {
    // 더미 데이터 - 날짜별로 그룹화
    final List<Map<String, dynamic>> dateSections = [
      {
        'date': '4월 15일 최신순',
        'items': [
          {
            'title': '3월 생애주기 가족 미션 이름',
            'amount': '+34,000원',
            'date': '금요일 · 13:30',
            'totalAmount': '415,000원',
          },
          {
            'title': '3월 생애주기 가족 미션 이름',
            'amount': '+34,000원',
            'date': '금요일 · 13:30',
            'totalAmount': '415,000원',
          },
        ],
      },
      {
        'date': '4월 14일 최신순',
        'items': [
          {
            'title': '3월 생애주기 가족 미션 이름',
            'amount': '+34,000원',
            'date': '금요일 · 13:30',
            'totalAmount': '415,000원',
          },
          {
            'title': '3월 생애주기 가족 미션 이름',
            'amount': '+34,000원',
            'date': '금요일 · 13:30',
            'totalAmount': '415,000원',
          },
          {
            'title': '3월 생애주기 가족 미션 이름',
            'amount': '+34,000원',
            'date': '금요일 · 13:30',
            'totalAmount': '415,000원',
          },
        ],
      },
    ];

    return Column(
      children: [
        // 내역 수 및 검색
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: Colors.grey.withOpacity(0.1), width: 1),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 전체 내역 수
              Row(
                children: [
                  Text(
                    '전체 내역 ',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '80',
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),

              // 정렬 아이콘
              Icon(Icons.tune, color: Colors.grey[500], size: 22),
            ],
          ),
        ),

        // 내역 리스트 (날짜별 그룹)
        Expanded(
          child: ListView.builder(
            itemCount: dateSections.length,
            itemBuilder: (context, sectionIndex) {
              final section = dateSections[sectionIndex];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 날짜 헤더
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
                    child: Row(
                      children: [
                        // 검색 아이콘 (첫 번째 섹션에만)
                        if (sectionIndex == 0)
                          Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: Icon(
                              Icons.search,
                              color: Colors.grey[400],
                              size: 20,
                            ),
                          ),

                        Text(
                          section['date'],
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 섹션 내 항목들
                  ...List.generate(section['items'].length, (index) {
                    final item = section['items'][index];
                    final isLast =
                        index == section['items'].length - 1 &&
                        sectionIndex == dateSections.length - 1;

                    return Column(
                      children: [
                        _buildHistoryItem(
                          title: item['title'],
                          amount: item['amount'],
                          date: item['date'],
                          totalAmount: item['totalAmount'],
                        ),
                        if (!isLast)
                          Divider(
                            height: 1,
                            color: Colors.grey.withOpacity(0.1),
                            indent: 20,
                            endIndent: 20,
                          ),
                      ],
                    );
                  }),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  // 내역 아이템
  Widget _buildHistoryItem({
    required String title,
    required String amount,
    required String date,
    required String totalAmount,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 제목 및 금액
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                amount,
                style: TextStyle(
                  color: Colors.blue,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          // 날짜 및 총액
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                date,
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
              Text(
                totalAmount,
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
