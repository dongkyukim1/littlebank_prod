import 'package:flutter/material.dart';
import 'chat_detail_screen.dart';
import '../../widgets/parent/bottom_navigation_bar.dart';

class ParentChatListScreen extends StatefulWidget {
  const ParentChatListScreen({super.key});

  @override
  State<ParentChatListScreen> createState() => _ParentChatListScreenState();
}

class _ParentChatListScreenState extends State<ParentChatListScreen> {
  final List<ChatItem> _chatItems = [
    ChatItem(
      name: '박뱅뱅',
      message: '엄마 오늘 수학 시험 만점 받았어요!',
      count: 1,
      avatar: '👦',
      time: '어제',
    ),
    ChatItem(
      name: '방방샘',
      message: '방학숙제 관련 안내사항 확인해주세요.',
      count: 2,
      avatar: '👨‍🏫',
      time: '월요일',
    ),
    ChatItem(
      name: '리틀팸',
      message: '부모님들 모임 참석 여부 알려주세요.',
      count: 1,
      avatar: '👨‍👩‍👧‍👦',
      time: '11/15',
    ),
    ChatItem(
      name: '알림',
      message: '자녀의 미션 수행이 완료되었습니다!',
      count: 3,
      avatar: '🔔',
      time: '15:42',
    ),
    ChatItem(
      name: '스티븐샘',
      message: '영어 학습 진도가 매우 좋습니다.',
      count: 0,
      avatar: '👨',
      time: '11/12',
    ),
  ];

  final int _currentIndex = 1; // 채팅 탭 선택
  bool _isGroupChat = false; // 채팅/그룹채팅 상태 추가
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // 새로운 상단 헤더
            Container(
              width: 390,
              height: 54,
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      _buildHeaderTab("채팅", !_isGroupChat),
                      const SizedBox(width: 8),
                      _buildHeaderTab("그룹 채팅", _isGroupChat),
                    ],
                  ),
                ],
              ),
            ),

            // 프로필 아바타 가로 스크롤
            _buildHorizontalContacts(),

            const Divider(height: 1, thickness: 1, color: Color(0xFFF2F2F2)),

            // 채팅 목록
            Expanded(
              child: ListView.separated(
                itemCount: _chatItems.length,
                separatorBuilder:
                    (context, index) => const Divider(
                      height: 1,
                      thickness: 1,
                      color: Color(0xFFF2F2F2),
                      indent: 70,
                    ),
                itemBuilder: (context, index) {
                  return _buildChatItem(_chatItems[index]);
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF146AFF), // 부모 앱 테마 색상으로 변경
        onPressed: () {
          // 새 채팅 시작
        },
        child: const Icon(Icons.chat, color: Colors.white),
      ),
      bottomNavigationBar: const ParentBottomNavigationBar(selectedIndex: 1),
    );
  }

  // 가로 스크롤 연락처 위젯
  Widget _buildHorizontalContacts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 제목 추가
        Padding(
          padding: const EdgeInsets.only(left: 24, top: 12, bottom: 3),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: const Text(
                  "최근 대화한 사람들",
                  style: TextStyle(
                    fontSize: 18,
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF202020),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 24, left: 8),
                child: Container(
                  width: 85,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F2F7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: InkWell(
                    onTap: () {
                      // 전체보기 기능
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                      child: Center(
                        child: Text(
                          "전체보기",
                          style: TextStyle(
                            fontSize: 12,
                            fontFamily: 'Pretendard',
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF001F55),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // 안내 메시지 추가
        Padding(
          padding: const EdgeInsets.only(left: 24, right: 24, bottom: 0),
          child: Text(
            "자녀 및 선생님과 빠르게 소통하세요",
            style: TextStyle(
              fontSize: 12,
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w400,
              color: Color(0xFF666666),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),

        // 여백 추가
        SizedBox(height: 8),

        // 컨테이너 숨김 처리 해제
        Container(
          height: 90,
          color: const Color(0xFFFAFAFA),
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              _buildAddContactButton(),
              _buildContactAvatar('박뱅뱅', '👦'),
              _buildContactAvatar('방방샘', '👨‍🏫'),
              _buildContactAvatar('리틀팸', '👨‍👩‍👧‍👦'),
              _buildContactAvatar('김샘', '👩‍🏫'),
              _buildContactAvatar('이샘', '👨‍🏫'),
            ],
          ),
        ),
      ],
    );
  }

  // 새 연락처 추가 버튼
  Widget _buildAddContactButton() {
    return Container(
      width: 76,
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  spreadRadius: 0,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.person_add_alt_rounded,
              color: const Color(0xFF146AFF), // 부모 앱 테마 색상으로 변경
              size: 22,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '새 대화',
            style: TextStyle(
              color: const Color(0xFF146AFF), // 부모 앱 테마 색상으로 변경
              fontSize: 11,
              fontWeight: FontWeight.w500,
              fontFamily: 'Pretendard',
            ),
          ),
        ],
      ),
    );
  }

  // 대화 목록 아이템
  Widget _buildChatItem(ChatItem item) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) =>
                    ParentChatDetailScreen(userName: item.name, avatar: item.avatar),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        child: Row(
          children: [
            // 프로필 이미지 (배지 제거)
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: const Color(0xFFF0F6FF),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE6EFFE), width: 1),
              ),
              child: Center(
                child: Text(item.avatar, style: const TextStyle(fontSize: 26)),
              ),
            ),
            const SizedBox(width: 16),

            // 메시지 내용
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFF262626),
                            fontFamily: 'Pretendard',
                          ),
                        ),
                      ),
                      Text(
                        item.time,
                        style: const TextStyle(
                          color: Color(0xFFAAAAAA),
                          fontSize: 12,
                          fontFamily: 'Pretendard',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.message,
                          style: const TextStyle(
                            color: Color(0xFF666666),
                            fontSize: 14,
                            fontFamily: 'Pretendard',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (item.count > 0)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(
                            color: Color(0xFF146AFF), // 부모 앱 테마 색상으로 변경
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              item.count.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 연락처 아바타 위젯
  Widget _buildContactAvatar(
    String name,
    String avatar) {
    return Container(
      width: 76,
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  spreadRadius: 0,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(avatar, style: const TextStyle(fontSize: 24)),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            name,
            style: const TextStyle(
              color: Color(0xFF666666),
              fontSize: 11,
              fontFamily: 'Pretendard',
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
    );
  }

  // 헤더 탭 위젯 추가
  Widget _buildHeaderTab(String title, bool isActive) {
    return InkWell(
      onTap: () {
        setState(() {
          _isGroupChat = title == "그룹 채팅";
        });
      },
      child: SizedBox(
        width: 72,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontFamily: 'SpoqaHanSansNeo',
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? Color(0xFF000000) : Color(0xFF888888),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            // 활성화된 탭에 밑줄 추가
            if (isActive)
              Container(
                width: 52,
                height: 2,
                margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(color: Color(0xFF000000)),
              ),
          ],
        ),
      ),
    );
  }
}

class ChatItem {
  final String name;
  final String message;
  final int count;
  final String avatar;
  final String time;

  ChatItem({
    required this.name,
    required this.message,
    required this.count,
    required this.avatar,
    required this.time,
  });
} 