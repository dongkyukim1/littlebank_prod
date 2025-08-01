import 'package:flutter/material.dart';
import 'delete/delete_account_screen.dart';

class ParentSettingsScreen extends StatefulWidget {
  const ParentSettingsScreen({super.key});

  @override
  State<ParentSettingsScreen> createState() => _ParentSettingsScreenState();
}

class _ParentSettingsScreenState extends State<ParentSettingsScreen> {
  // 알림 설정 상태 관리
  bool _noticeNotification = true;
  bool _updateNotification = false;
  bool _childActivityNotification = true;
  bool _missionNotification = true;
  bool _doNotDisturbNotification = true;

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
            fontFamily: 'Pretendard-Bold',
            letterSpacing: -0.32,
          ),
        ),
        leading: IconButton(
          icon: Image.asset(
            'assets/icons/parent/뒤로가기.png',
            width: 20,
            height: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 앱 알림 섹션
            _buildSectionHeader('앱 알림'),

            // 구분선
            const Divider(
              height: 1,
              thickness: 0.5,
              color: Color(0xFF333333),
              indent: 16,
              endIndent: 16,
            ),

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
            const Divider(
              height: 1,
              thickness: 0.5,
              color: Color(0xFF8490A3),
              indent: 16,
              endIndent: 16,
            ),

            // 방해금지 시간 설정
            _buildNotificationItem(
              '방해금지 시간 설정',
              '다양한 정보를 빠르게 만나실 수 있습니다.',
              _doNotDisturbNotification,
              (value) {
                setState(() {
                  _doNotDisturbNotification = value;
                });
              },
              showTopBorder: false,
            ),

            // 구분선
            const Divider(
              height: 1,
              thickness: 0.5,
              color: Color(0xFF8490A3),
              indent: 16,
              endIndent: 16,
            ),

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

            // 구분선 (테두리 없는 회색 배경)
            Container(
              width: double.infinity,
              height: 12,
              color: Color(0xFFEFF2F6),
            ),

            // 자녀 활동 알림 섹션
            _buildSectionHeader('자녀 활동 알림'),

            // 구분선
            const Divider(
              height: 1,
              thickness: 0.5,
              color: Color(0xFF333333),
              indent: 16,
              endIndent: 16,
            ),

            // 자녀 활동 알림
            _buildNotificationItem(
              '자녀 활동 알림',
              '자녀의 목표 달성 및 미션 완료를 알려드릴게요',
              _childActivityNotification,
              (value) {
                setState(() {
                  _childActivityNotification = value;
                });
              },
              showTopBorder: true,
            ),

            // 구분선
            const Divider(
              height: 1,
              thickness: 0.5,
              color: Color(0xFF8490A3),
              indent: 16,
              endIndent: 16,
            ),

            // 미션 완료 알림
            _buildNotificationItem(
              '미션 완료 알림',
              '자녀가 미션을 완료하면 알려드릴게요',
              _missionNotification,
              (value) {
                setState(() {
                  _missionNotification = value;
                });
              },
              showTopBorder: false,
            ),

            // 구분선 (테두리 없는 회색 배경)
            Container(
              width: double.infinity,
              height: 12,
              color: Color(0xFFEFF2F6),
            ),

            // 앱 정보 섹션
            _buildSectionHeader('앱 정보'),

            // 구분선
            const Divider(
              height: 1,
              thickness: 0.5,
              color: Color(0xFF333333),
              indent: 16,
              endIndent: 16,
            ),

            // 앱 버전 정보
            _buildInfoItem('앱 정보 v2. 21. 20', '최신 업데이트 버전입니다.'),

            // 구분선
            const Divider(
              height: 1,
              thickness: 0.5,
              color: Color(0xFF8490A3),
              indent: 16,
              endIndent: 16,
            ),

            // 이용약관 및 개인정보
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: InkWell(
                onTap: () {
                  // 이용약관 및 개인정보 화면으로 이동
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 20,
                    horizontal: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.transparent),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        '이용약관 및 개인 정보',
                        style: const TextStyle(
                          color: Color(0xFF202020),
                          fontSize: 14,
                          fontFamily: 'Pretendard-Bold',
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
            ),

            // 여백
            Container(
              width: double.infinity,
              height: 12,
              color: Color(0xFFEFF2F6),
            ),

            // 회원 탈퇴 버튼
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 40, bottom: 40),
                child: GestureDetector(
                  onTap: () {
                    // 부모 회원 탈퇴 화면으로 이동
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ParentDeleteAccountScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    '회원 탈퇴하기',
                    style: TextStyle(
                      color: Color(0xFFCCCCCC),
                      fontSize: 12,
                      fontFamily: 'Pretendard-Light',
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
          fontSize: 16,
          fontFamily: 'Pretendard-Bold',
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
        decoration: BoxDecoration(color: Colors.white),
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
                      fontSize: 14,
                      fontFamily: 'Pretendard-Bold',
                      letterSpacing: -0.32,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: const TextStyle(
                      color: Color(0xFF666666),
                      fontSize: 10,
                      fontFamily: 'Pretendard-Light',
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
        decoration: BoxDecoration(color: Colors.white),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF202020),
                fontSize: 14,
                fontFamily: 'Pretendard-Bold',
                letterSpacing: -0.32,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: const TextStyle(
                color: Color(0xFF666666),
                fontSize: 10,
                fontFamily: 'Pretendard-Light',
                letterSpacing: -0.24,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 토글 스위치 위젯
  Widget _buildToggleSwitch(bool value, Function(bool) onChanged) {
    return SizedBox(
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
            child: SizedBox(
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
                        ),
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
}
