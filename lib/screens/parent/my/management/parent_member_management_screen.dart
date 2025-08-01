// @dart=2.19
import 'package:flutter/material.dart';
import '../../../../widgets/parent/bottom_navigation_bar.dart';
import '../../../../services/auth_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../edit_profile_screen.dart';

class ParentMemberManagementScreen extends StatefulWidget {
  const ParentMemberManagementScreen({super.key});

  @override
  State<ParentMemberManagementScreen> createState() =>
      _ParentMemberManagementScreenState();
}

class _ParentMemberManagementScreenState
    extends State<ParentMemberManagementScreen> {
  // 사용자 정보 및 로딩 상태
  Map<String, dynamic>? _userInfo;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  // 사용자 정보 불러오기
  Future<void> _loadUserInfo() async {
    try {
      if (mounted) {
        setState(() {
          _isLoading = true;
          _errorMessage = null;
        });
      }

      final userInfo = await AuthService.getUserInfo();

      if (mounted) {
        setState(() {
          _userInfo = userInfo;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
      print('사용자 정보 로딩 오류: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          '멤버 관리',
          style: TextStyle(
            color: Colors.black,
            fontSize: 14,
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '오류가 발생했습니다',
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: 'Pretendard-Bold',
                          color: Colors.red,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        _errorMessage!,
                        style: TextStyle(fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadUserInfo,
                        child: Text('다시 시도'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 내 계정 섹션
                      _buildMyAccountSection(),

                      const SizedBox(height: 32),

                      // 함께 이용하는 멤버 섹션
                      _buildMembersSection(),

                      const SizedBox(height: 12),

                      // 안내 메시지 섹션
                      _buildInfoSection(),
                    ],
                  ),
                ),
      bottomNavigationBar: const ParentBottomNavigationBar(selectedIndex: 4),
    );
  }

  // 내 계정 섹션
  Widget _buildMyAccountSection() {
    // 사용자 정보에서 필요한 데이터 추출
    final userName = _userInfo?['name'] ?? '사용자';
    final userRole = _userInfo?['role'] ?? 'PARENT';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 내 계정 헤더
        Padding(
          padding: const EdgeInsets.only(left: 16, top: 14, bottom: 14),
          child: Text(
            '내 계정',
            style: TextStyle(
              color: const Color(0xFF202020),
              fontSize: 16,
              fontFamily: 'Pretendard-Bold',
              letterSpacing: -0.4,
            ),
          ),
        ),

        // 내 계정 카드
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          width: 358,
          height: 76,
          decoration: ShapeDecoration(
            color: const Color(0xFF10CB86),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Stack(
            children: [
              // 사용자 정보
              Positioned(
                left: 12,
                top: 0,
                bottom: 0,
                child: Row(
                  children: [
                    // 프로필 이미지
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: _userInfo?['profileImagePath'] != null &&
                                _userInfo!['profileImagePath']!.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: AuthService.getFullProfileImageUrl(
                                  _userInfo!['profileImagePath'],
                                ),
                                fit: BoxFit.cover,
                                placeholder: (context, url) => const Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                  ),
                                ),
                                errorWidget: (context, url, error) =>
                                    Image.asset(
                                  'assets/images/kid.png',
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Image.asset(
                                'assets/images/kid.png',
                                fit: BoxFit.cover,
                              ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // 사용자 정보
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // 역할 뱃지
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: ShapeDecoration(
                            color: const Color(0xFFFFD27F),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          child: Text(
                            '부모',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontFamily: 'Pretendard-Light',
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),

                        // 사용자 이름
                        Text(
                          userName,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontFamily: 'Pretendard-Medium',
                            letterSpacing: -0.28,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 로고 이미지 (오른쪽 아래)
              Positioned(
                right: 10,
                bottom: -5,
                child: Image.asset(
                  'assets/icons/my/my_logo.png',
                  width: 84,
                  height: 84,
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 함께 이용하는 멤버 섹션
  Widget _buildMembersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 헤더 섹션
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 제목
              Text(
                '함께 이용하는 멤버들이에요',
                style: TextStyle(
                  color: const Color(0xFF202020),
                  fontSize: 16,
                  fontFamily: 'Pretendard-Bold',
                  letterSpacing: -0.5,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                '멤버 추가하기를 통해 가족멤버로 추가해보세요',
                style: TextStyle(
                  color: const Color(0xFF999999),
                  fontSize: 12,
                  fontFamily: 'Pretendard-Light',
                  letterSpacing: -0.28,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // 멤버 카드 그리드
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 16),
            physics: BouncingScrollPhysics(),
            itemCount: 2, // 임시로 2개의 카드만 표시
            itemBuilder: (context, index) {
              // 화면 너비에 따라 카드 너비 계산
              double screenWidth = MediaQuery.of(context).size.width;
              double cardWidth = (screenWidth - (32 + 12)) / 2; // 패딩과 간격 고려

              return Container(
                width: cardWidth,
                margin: EdgeInsets.only(
                  right: index != 1 ? 12 : 0,
                ),
                child: _buildMemberCard('강뱅뱅', 'CHILD'),
              );
            },
          ),
        ),

        const SizedBox(height: 16),

        // 연락처로 초대하기 버튼
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GestureDetector(
            onTap: () {
              _showAddFamilyModal(context);
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: ShapeDecoration(
                color: const Color(0xFF146AFF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Center(
                child: Text(
                  '연락처로 초대하기',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontFamily: 'Pretendard-Medium',
                    letterSpacing: -0.28,
                  ),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 40), // 간격을 80에서 20으로 줄임
      ],
    );
  }

  // 멤버 카드 위젯
  Widget _buildMemberCard(String name, String role) {
    final Color badgeColor =
        (role == 'CHILD') ? const Color(0xFF89DA8D) : const Color(0xFF146AFF);
    final String badgeText = (role == 'CHILD') ? '자녀' : '부모';

    return GestureDetector(
      onTap: () {
        // 해당 유저의 프로필 화면으로 이동
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EditProfileScreen(
              userInfo: {
                'name': name,
                'role': role,
                // TODO: 실제 사용자 정보 전달
              },
            ),
          ),
        );
      },
      child: Stack(
        children: [
          // 배경 이미지 (카드)
          Image.asset(
            'assets/icons/my/sub_card.png',
            width: double.infinity,
            fit: BoxFit.fill,
          ),

          // 프로필 보기 아이콘 (오른쪽 상단)
          Positioned(
            top: 10,
            right: 10,
            child: Image.asset(
              'assets/icons/parent/my/go_profile.png',
              width: 24,
              height: 24,
            ),
          ),

          // 프로필 정보 카드 (하단)
          Positioned(
            bottom: 32,
            left: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Color(0xFF146AFF), width: 1),
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/kid.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: badgeColor, width: 0.5),
                          ),
                          child: Text(
                            badgeText,
                            style: TextStyle(
                              color: badgeColor,
                              fontSize: 9,
                              fontFamily: 'Pretendard-Light',
                            ),
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          name,
                          style: TextStyle(
                            color: Color(0xFF202020),
                            fontSize: 12,
                            fontFamily: 'Pretendard-Bold',
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 안내 메시지 섹션
  Widget _buildInfoSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // 첫 번째 안내 카드
          _buildInfoCard(
            '현재 화면에서는 함께 구독 중인 멤버들을 볼 수 있습니다.',
            '추가는 구독권 관리 화면에서 가능하며, 현재 멤버 삭제 기능은 제공 중이지 않습니다. 해당 멤버를 삭제하고 싶을 시, 구독권 해지를 통해 가능합니다.',
          ),

          const SizedBox(height: 12),

          // 두 번째 안내 카드
          _buildInfoCard(
            '새 멤버 추가는 구독권 변경 후에 가능합니다.',
            '기존 멤버 외 추가하고 싶은 멤버가 있다면, 멤버 추가하기 버튼 선택 후 구독권 관리에서 멤버를 추가할 수 있습니다.',
          ),
        ],
      ),
    );
  }

  // 안내 카드 위젯
  Widget _buildInfoCard(String title, String description) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: ShapeDecoration(
        color: const Color(0xFFF5F6F8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 제목 행
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 2),
                child: Image.asset(
                  'assets/icons/my/Fill_inform.png',
                  width: 14,
                  height: 14,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: const Color(0xFF666666),
                    fontSize: 11,
                    fontFamily: 'Pretendard-Medium',
                    letterSpacing: -0.22,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          // 설명 텍스트
          Padding(
            padding: const EdgeInsets.only(left: 22),
            child: Text(
              description,
              style: TextStyle(
                color: const Color(0xFF999999),
                fontSize: 10,
                fontFamily: 'Pretendard-Light',
                height: 1.4,
                letterSpacing: -0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 가족 멤버 설정 모달 대화상자
  void _showFamilyMemberModal(BuildContext context, String memberName) {
    // 해당 유저의 프로필 화면으로 이동
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(
          userInfo: {
            'name': memberName,
            // TODO: 실제 사용자 정보 전달
          },
        ),
      ),
    );
  }

  // 구독권 변경 모달 대화상자 제거
  void _showSubscriptionChangeModal(BuildContext context) {
    _showAddFamilyModal(context);
  }

  // 가족 멤버 추가 모달 대화상자
  void _showAddFamilyModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: EdgeInsets.symmetric(horizontal: 21),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.95,
            padding: EdgeInsets.zero,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: 452),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 메인 헤더 부분
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                    decoration: const ShapeDecoration(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(24),
                          topRight: Radius.circular(24),
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '가족 멤버를 추가해보세요',
                          style: TextStyle(
                            color: const Color(0xFF202020),
                            fontSize: 15.5,
                            fontFamily: 'Pretendard-Bold',
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '가족 멤버 사이에는 용돈을 주고받을 수 있어요',
                          style: TextStyle(
                            color: const Color(0xFF999999),
                            fontSize: 12,
                            fontFamily: 'Pretendard-Light',
                            letterSpacing: -0.28,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 구독권 옵션 부분
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    color: Colors.white,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 3인 구독권
                        GestureDetector(
                          onTap: () {
                            // 3인 구독권 선택 로직
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: ShapeDecoration(
                              color: Colors.white,
                              shape: RoundedRectangleBorder(
                                side: BorderSide(
                                  width: 1.0,
                                  color: const Color(0xFF146AFF),
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '3인 구독권',
                                        style: TextStyle(
                                          color: const Color(0xFF353535),
                                          fontSize: 12,
                                          fontFamily: 'Pretendard-Light',
                                          letterSpacing: -0.24,
                                        ),
                                      ),
                                      SizedBox(height: 6),
                                      Text.rich(
                                        TextSpan(
                                          children: [
                                            TextSpan(
                                              text: '₩7,500원',
                                              style: TextStyle(
                                                color: const Color(
                                                  0xFF202020,
                                                ),
                                                fontSize: 16,
                                                fontFamily: 'Pretendard-Bold',
                                                letterSpacing: -0.64,
                                              ),
                                            ),
                                            TextSpan(
                                              text: ' / 월간',
                                              style: TextStyle(
                                                color: const Color(
                                                  0xFF666666,
                                                ),
                                                fontSize: 13,
                                                fontFamily: 'Pretendard-Medium',
                                                letterSpacing: -0.26,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // 5인 구독권
                        GestureDetector(
                          onTap: () {
                            // 5인 구독권 선택 로직
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: ShapeDecoration(
                              color: Colors.white,
                              shape: RoundedRectangleBorder(
                                side: BorderSide(
                                  width: 1.0,
                                  color: const Color(0xFF146AFF),
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '5인 구독권',
                                        style: TextStyle(
                                          color: const Color(0xFF353535),
                                          fontSize: 12,
                                          fontFamily: 'Pretendard-Light',
                                          letterSpacing: -0.24,
                                        ),
                                      ),
                                      SizedBox(height: 6),
                                      Text.rich(
                                        TextSpan(
                                          children: [
                                            TextSpan(
                                              text: '₩9,500원',
                                              style: TextStyle(
                                                color: const Color(
                                                  0xFF202020,
                                                ),
                                                fontSize: 16,
                                                fontFamily: 'Pretendard-Bold',
                                                letterSpacing: -0.64,
                                              ),
                                            ),
                                            TextSpan(
                                              text: ' / 월간',
                                              style: TextStyle(
                                                color: const Color(
                                                  0xFF666666,
                                                ),
                                                fontSize: 13,
                                                fontFamily: 'Pretendard-Medium',
                                                letterSpacing: -0.26,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 버튼 부분
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: const ShapeDecoration(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(24),
                          bottomRight: Radius.circular(24),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        // 취소 버튼
                        Expanded(
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              height: 48,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: ShapeDecoration(
                                color: const Color(0xFFDDDDDD),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  '다음에 하기',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontFamily: 'Pretendard-ExtraLight',
                                    letterSpacing: -0.28,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        // 확인 버튼
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                              // 구독권 변경 로직
                              // 선택된 구독권에 따라 로직 추가
                            },
                            child: Container(
                              height: 48,
                              margin: const EdgeInsets.only(left: 8),
                              decoration: ShapeDecoration(
                                color: const Color(0xFF5D9EFF),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  '완료',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontFamily: 'Pretendard-ExtraLight',
                                    letterSpacing: -0.28,
                                  ),
                                ),
                              ),
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
      },
    );
  }

  // 가족 멤버 관리 옵션 바텀시트
  void _showManageOptionsBottomSheet(
    BuildContext context,
    String displayName,
    int? familyMemberId,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return Container(
          width: MediaQuery.of(context).size.width,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: const ShapeDecoration(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                ),
                child: Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    Text(
                      '멤버 정보',
                      style: TextStyle(
                        color: const Color(0xFF202020),
                        fontSize: 18,
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.72,
                      ),
                    ),
                    Positioned(
                      right: 0,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Image.asset(
                          'assets/icons/my/close.png',
                          width: 24,
                          height: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                color: Colors.white,
                child: Text(
                  '현재 구독 중인 멤버입니다.',
                  style: TextStyle(
                    color: const Color(0xFF666666),
                    fontSize: 14,
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w300,
                    letterSpacing: -0.28,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
