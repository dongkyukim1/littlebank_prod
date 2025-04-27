import 'package:flutter/material.dart';
import '../../widgets/common/bottom_navigation_bar.dart';
import 'home_screen.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final bool _isMissionCardExpanded = false;
  int _selectedTabIndex = 0;

  // 필터 탭 목록
  final List<String> _tabs = ['전체', '활동내역', '리워드', '선물함'];

  // 샘플 알림 데이터
  final List<Map<String, dynamic>> _notifications = [
    {
      'id': 1,
      'category': '미션',
      'title': '[긴급] 오늘 방 청소 미션 마감 임박!',
      'content': '오늘 8시까지 방 청소 미션을 완료하면 500원을 받을 수 있어요.',
      'badge': '미션',
      'time': '10분 전',
      'isToday': true,
      'isRead': false,
      'icon': '🧹',
    },
    {
      'id': 2,
      'category': '용돈',
      'title': '용돈 2,000원이 지급되었어요!',
      'content': '수학 문제 10개 풀기 미션 완료로 용돈이 지급되었어요.',
      'time': '2시간 전',
      'isToday': true,
      'isRead': true,
      'icon': '💰',
    },
    {
      'id': 3,
      'category': '미션',
      'title': '새로운 미션이 등록되었어요.',
      'content': '엄마가 설거지 도와주기 미션을 등록했어요. 완료하면 1,000원!',
      'time': '8시간 전',
      'isToday': true,
      'isRead': false,
      'icon': '✨',
    },
    {
      'id': 4,
      'category': '용돈',
      'title': '저금 목표의 50%를 달성했어요!',
      'content': '게임기 구매 목표 금액의 절반을 모았어요. 조금만 더 화이팅!',
      'time': '10시간 전',
      'isToday': true,
      'isRead': true,
      'icon': '🎮',
    },
    {
      'id': 5,
      'category': '학습',
      'title': '영어 단어 외우기 미션이 승인되었어요!',
      'content': '아빠가 영어 단어 외우기 미션을 승인했어요. 용돈 1,500원이 지급되었어요.',
      'time': '15시간 전',
      'isToday': true,
      'isRead': false,
      'icon': '📚',
    },
    {
      'id': 6,
      'category': '학습',
      'title': '수학 퀴즈에서 100점을 받았어요!',
      'content': '오늘의 수학 퀴즈에서 만점을 받았어요. 대단해요!',
      'time': '2023-06-11',
      'isToday': false,
      'isRead': true,
      'icon': '🔢',
    },
    {
      'id': 7,
      'category': '미션',
      'title': '쓰레기 분리수거 미션 완료!',
      'content': '쓰레기 분리수거 미션을 잘 완료했어요. 엄마의 확인을 기다려요.',
      'time': '2023-06-11',
      'isToday': false,
      'isRead': true,
      'icon': '♻️',
    },
    {
      'id': 8,
      'category': '용돈',
      'title': '용돈을 성공적으로 저금했어요',
      'content': '오늘 받은 용돈 1,000원 중 500원을 저금했어요. 현명한 선택이에요!',
      'time': '2023-06-10',
      'isToday': false,
      'isRead': true,
      'icon': '🏦',
    },
    {
      'id': 9,
      'category': '학습',
      'title': '이번 주 학습 목표를 달성했어요!',
      'content': '이번 주 목표였던 영어 단어 50개 외우기를 완료했어요. 특별 보상 1,000원이 지급되었어요!',
      'time': '2023-04-23',
      'isToday': false,
      'isRead': true,
      'icon': '🎯',
    },
  ];

  @override
  Widget build(BuildContext context) {
    // 현재 선택된 탭에 해당하는 알림만 필터링
    final List<Map<String, dynamic>> filteredNotifications =
        _selectedTabIndex == 0
            ? _notifications
            : _notifications.where((notification) {
              if (_selectedTabIndex == 1) {
                return notification['category'] == '미션' ||
                    notification['category'] == '학습';
              } else if (_selectedTabIndex == 2) {
                return notification['category'] == '리워드';
              } else if (_selectedTabIndex == 3) {
                return notification['category'] == '용돈';
              }
              return false;
            }).toList();

    // 읽지 않은 알림과 읽은 알림으로 분류
    final unreadNotifications =
        filteredNotifications
            .where((notification) => !notification['isRead'])
            .toList();

    final readNotifications =
        filteredNotifications
            .where((notification) => notification['isRead'])
            .toList();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed:
              () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
              ),
        ),
        title: const Text(
          '알림',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'Pretendard',
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.settings_outlined,
              color: Colors.black,
              size: 24,
            ),
            onPressed: () {
              // 알림 설정 화면 이동
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 필터 탭 바
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(
                  _tabs.length,
                  (index) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: _buildFilterTab(index),
                  ),
                ),
              ),
            ),
          ),

          // 알림 목록
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // 활동 내역 섹션
                if (unreadNotifications.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    alignment: Alignment.centerLeft,
                    child: const Text(
                      '읽지 않음',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  ...unreadNotifications.map(
                    (notification) => _buildNotificationItem(notification),
                  ),
                ],

                // 선물함 섹션
                if (readNotifications.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    alignment: Alignment.centerLeft,
                    child: const Text(
                      '읽음',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  ...readNotifications.map(
                    (notification) => _buildNotificationItem(notification),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: const CommonBottomNavigationBar(selectedIndex: 0),
    );
  }

  Widget _buildFilterTab(int index) {
    final bool isSelected = _selectedTabIndex == index;
    final String tabText = _tabs[index];

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTabIndex = index;
        });
      },
      child: Container(
        width: 100,
        height: 41,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF3A88F4) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border:
              isSelected
                  ? null
                  : Border.all(width: 0.7, color: const Color(0xFF5D9EFF)),
        ),
        child: Center(
          child: Text(
            _tabs[index],
            style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF3A88F4),
              fontWeight: isSelected ? FontWeight.w500 : FontWeight.w300,
              fontSize: 14,
              fontFamily: 'Pretendard',
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationItem(Map<String, dynamic> notification) {
    return GestureDetector(
      onTap: () {
        // 알림을 읽음 상태로 변경
        setState(() {
          notification['isRead'] = true;
        });

        // 여기에 알림 상세 페이지로 이동하는 코드를 추가할 수 있습니다
        // Navigator.push(context, MaterialPageRoute(...));
      },
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 아이콘
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        notification['icon'],
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // 내용
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (notification.containsKey('badge')) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  notification['badge'],
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                            ],
                            Expanded(
                              child: Text(
                                notification['title'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.black,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          notification['content'],
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          notification['time'],
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // 구분선
            Divider(height: 1, thickness: 1, color: Colors.grey[200]),
          ],
        ),
      ),
    );
  }
}
