import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // 알림 설정 상태 관리
  bool _noticeNotification = true;
  bool _updateNotification = false;
  bool _likeNotification = true;
  bool _commentNotification = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          '앱 설정',
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w700,
            letterSpacing: -0.32,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 16),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Image.asset(
              'assets/icons/home.png',
              width: 24,
              height: 24,
            ),
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 앱 알림 섹션
            _buildSectionHeader('앱 알림'),
            
            // 공지사항 알림
            _buildNotificationItem(
              '공지사항 알림',
              '다양한 정보를 빠르게 만나실 수 있습니다.',
              _noticeNotification,
              (value) {
                setState(() {
                  _noticeNotification = value;
                });
              },
              showTopBorder: true,
            ),
            
            // 구분선
            const Divider(height: 1, thickness: 0.5, color: Color(0xFFEEEEEE)),
            
            // 업데이트 알림
            _buildNotificationItem(
              '업데이트 알림',
              '다양한 정보를 빠르게 만나실 수 있습니다.',
              _updateNotification,
              (value) {
                setState(() {
                  _updateNotification = value;
                });
              },
              showTopBorder: false,
            ),

            // 구분선
            _buildDivider(),

            // 활동 알림 섹션
            _buildSectionHeader('활동 알림'),
            
            // 좋아요 알림
            _buildNotificationItem(
              '작성글 반응 XXX',
              '작성글에 좋아요가 달리면 알려드릴게요',
              _likeNotification,
              (value) {
                setState(() {
                  _likeNotification = value;
                });
              },
              showTopBorder: true,
            ),
            
            // 구분선
            const Divider(height: 1, thickness: 0.5, color: Color(0xFFEEEEEE)),
            
            // 댓글 알림
            _buildNotificationItem(
              '작성글 반응 XXX',
              '작성글에 댓글이 달리면 알려드릴게요',
              _commentNotification,
              (value) {
                setState(() {
                  _commentNotification = value;
                });
              },
              showTopBorder: false,
            ),

            // 구분선
            _buildDivider(),

            // 앱 정보 섹션
            _buildSectionHeader('앱 정보'),
            
            // 앱 버전 정보
            _buildInfoItem(
              '앱 정보 v2. 21. 20',
              '최신 업데이트 버전입니다.',
            ),
            
            // 구분선
            const Divider(height: 1, thickness: 0.5, color: Color(0xFFEEEEEE)),
            
            // 이용약관 및 개인정보
            _buildLinkItem('이용약관 및 개인 정보'),

            // 회원 탈퇴 버튼
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 140, bottom: 40),
                child: GestureDetector(
                  onTap: () {
                    // 회원 탈퇴 기능 구현
                  },
                  child: const Text(
                    '회원 탈퇴하기',
                    style: TextStyle(
                      color: Color(0xFFCCCCCC),
                      fontSize: 14,
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w300,
                      letterSpacing: -0.28,
                      decoration: TextDecoration.underline,
                      decorationColor: Color(0xFFCCCCCC),
                      decorationThickness: 1,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 섹션 헤더 위젯
  Widget _buildSectionHeader(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF202020),
          fontSize: 18,
          fontFamily: 'Pretendard',
          fontWeight: FontWeight.w700,
          letterSpacing: -0.72,
        ),
      ),
    );
  }

  // 알림 아이템 위젯
  Widget _buildNotificationItem(
    String title,
    String description,
    bool value,
    Function(bool) onChanged, {
    bool showTopBorder = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.transparent),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF202020),
                      fontSize: 16,
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.32,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: const TextStyle(
                      color: Color(0xFF666666),
                      fontSize: 12,
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w300,
                      letterSpacing: -0.24,
                    ),
                  ),
                ],
              ),
            ),
            _buildToggleSwitch(value, onChanged),
          ],
        ),
      ),
    );
  }

  // 정보 아이템 위젯
  Widget _buildInfoItem(String title, String description) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.transparent),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF202020),
                fontSize: 16,
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w700,
                letterSpacing: -0.32,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: const TextStyle(
                color: Color(0xFF666666),
                fontSize: 12,
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w300,
                letterSpacing: -0.24,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 링크 아이템 위젯
  Widget _buildLinkItem(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: InkWell(
        onTap: () {
          // 이용약관 및 개인정보 화면으로 이동
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.transparent),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF202020),
                  fontSize: 16,
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.32,
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: Color(0xFFCCCCCC),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 토글 스위치 위젯
  Widget _buildToggleSwitch(bool value, Function(bool) onChanged) {
    return Container(
      width: 60,
      height: 32,
      child: Stack(
        children: [
          Container(
            width: 60,
            height: 32,
            decoration: ShapeDecoration(
              color: value ? const Color(0xFF10CB86) : const Color(0xFFDDDDDD),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              onChanged(!value);
            },
            child: Container(
              width: 60,
              height: 32,
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: ShapeDecoration(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      shadows: const [
                        BoxShadow(
                          color: Color(0x38000000),
                          blurRadius: 3,
                          offset: Offset(3, 3),
                          spreadRadius: 0,
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 구분선 위젯
  Widget _buildDivider() {
    return Container(
      width: double.infinity,
      height: 12,
      decoration: const BoxDecoration(
        color: Color(0xFFEFF2F6),
      ),
    );
  }
} 