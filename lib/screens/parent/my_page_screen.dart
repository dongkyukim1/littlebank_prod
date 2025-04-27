import 'package:flutter/material.dart';
import '../../widgets/parent/bottom_navigation_bar.dart';
import 'my/point_history_screen.dart'; // 총 적립 내역 화면 import
import '../../services/auth_service.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'edit_profile_screen.dart';

class ParentMyPageScreen extends StatefulWidget {
  const ParentMyPageScreen({super.key});

  @override
  State<ParentMyPageScreen> createState() => _ParentMyPageScreenState();
}

class _ParentMyPageScreenState extends State<ParentMyPageScreen> {
  // 마이 탭 선택
  final int _selectedIndex = 3;

  // 적립금 카드 확장 여부
  final bool _isPointCardExpanded = false;

  // 각 메뉴 섹션의 확장 상태 (기본값은 true - 펼쳐진 상태)
  final Map<String, bool> _expandedSections = {
    '용돈 관리': true,
    '계좌 관리': true,
    '자녀 활동 관리': true,
    '가족 관리': true,
    '고객 지원': true,
  };

  // 사용자 정보를 저장할 변수 추가
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

      // 사용자 정보 상세 로깅
      print('사용자 정보 로드 성공: $userInfo');
      userInfo.forEach((key, value) {
        print('사용자 정보 키: $key, 값: $value');
      });

      // 역할 정보 확인
      if (userInfo.containsKey('role')) {
        print('사용자 역할(role): ${userInfo['role']}');
      }
      if (userInfo.containsKey('authority')) {
        print('사용자 권한(authority): ${userInfo['authority']}');
      }

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

  // 프로필 이미지 업로드 처리
  Future<void> _updateProfileImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedImage = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedImage != null) {
        // 로딩 상태 설정
        if (mounted) {
          setState(() {
            _isLoading = true;
          });
        }

        // 이미지 업로드 처리
        final imagePath = await AuthService.uploadProfileImage(
          File(pickedImage.path),
        );

        print('업로드된 이미지 경로: $imagePath');

        // 프로필 업데이트 API 호출 (profileImagePath만 업데이트)
        await AuthService.updateUserProfile(imagePath);

        // 사용자 정보 다시 로드 (mounted 체크 추가)
        if (mounted) {
          await _loadUserInfo();
        }
      }
    } catch (e) {
      // 오류 처리 (mounted 체크 추가)
      if (mounted) {
        setState(() {
          _errorMessage = '프로필 이미지 업데이트 중 오류가 발생했습니다: $e';
          _isLoading = false;
        });
      }
      print('프로필 이미지 업데이트 오류: $e');
    }
  }

  // 메뉴 섹션 토글 기능
  void _toggleSection(String title) {
    setState(() {
      _expandedSections[title] = !(_expandedSections[title] ?? true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE7ECF6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          '마이페이지',
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.black87, size: 24),
            onPressed: () {
              // 설정 화면으로 이동
            },
          ),
        ],
      ),
      body:
          _isLoading
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
                        fontWeight: FontWeight.bold,
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
                  children: [
                    // 통합된 프로필 및 적립금 카드
                    _buildProfileAndPointsCard(),

                    // 파란색 박스와 메뉴 사이 간격 추가
                    const SizedBox(height: 24),

                    // 메뉴 리스트
                    _buildMenuList(),
                  ],
                ),
              ),
      bottomNavigationBar: const ParentBottomNavigationBar(selectedIndex: 3),
    );
  }

  // 통합된 프로필 및 적립금 카드 위젯
  Widget _buildProfileAndPointsCard() {
    // 사용자 정보에서 필요한 데이터 추출
    final userName = _userInfo?['name'] ?? '사용자';
    final userEmail = _userInfo?['email'] ?? 'user@example.com';
    final profileImagePath = _userInfo?['profileImagePath'];
    final userRole = _userInfo?['role'] ?? 'PARENT';
    final firstLetter = userName.isNotEmpty ? userName.substring(0, 1) : '?';

    return Container(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: ShapeDecoration(
        color: const Color(0xFF146AFF), // 부모용 더 진한 파란색
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(40),
            bottomRight: Radius.circular(40),
          ),
        ),
      ),
      child: Column(
        children: [
          // 프로필 카드 부분
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: ShapeDecoration(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 프로필 정보 행
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 왼쪽: 프로필 이미지와 정보
                    Flexible(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 프로필 이미지 (부모용)
                          GestureDetector(
                            onTap: _updateProfileImage,
                            child: Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: const Color(0xFF146AFF), // 부모용 색상
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 1.5,
                                ),
                              ),
                              child:
                                  profileImagePath == null ||
                                          profileImagePath.isEmpty
                                      ? Center(
                                        child: Text(
                                          firstLetter,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      )
                                      : ClipOval(
                                        child: _buildProfileImageWidget(
                                          AuthService.getFullProfileImageUrl(
                                            profileImagePath,
                                          ),
                                          firstLetter,
                                        ),
                                      ),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // 프로필 텍스트 정보
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 부모 뱃지
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: ShapeDecoration(
                                    color: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      side: BorderSide(
                                        width: 0.35,
                                        color: const Color(0xFF146AFF),
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        '부모',
                                        style: TextStyle(
                                          color: const Color(0xFF146AFF),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w300,
                                          letterSpacing: -0.24,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),

                                // 이름
                                Text(
                                  userName,
                                  style: const TextStyle(
                                    color: Color(0xFF202020),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.32,
                                  ),
                                ),
                                const SizedBox(height: 4),

                                // 이메일
                                Text(
                                  userEmail,
                                  style: const TextStyle(
                                    color: Color(0xFF999999),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w300,
                                    letterSpacing: -0.22,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 수정하기 버튼
                    GestureDetector(
                      onTap: () async {
                        // 회원 정보 수정 화면으로 이동
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) =>
                                    EditProfileScreen(userInfo: _userInfo!),
                          ),
                        );

                        // 수정된 정보가 있으면 화면 갱신
                        if (result != null && mounted) {
                          setState(() {
                            _userInfo = result;
                          });
                        }
                      },
                      child: SizedBox(
                        width: 62,
                        height: 29,
                        child: Stack(
                          children: [
                            Positioned(
                              left: 0,
                              top: 0,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: ShapeDecoration(
                                  color: const Color(0xFFF5F6F8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text(
                                  '수정하기',
                                  style: TextStyle(
                                    color: Color(0xFF999999),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w300,
                                    letterSpacing: -0.22,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // 사용 정보 카드 (부모용)
                Container(
                  width: double.infinity,
                  decoration: ShapeDecoration(
                    color: const Color(0xFFF7F7F7),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    decoration: const ShapeDecoration(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // 함께한 일수
                        Expanded(
                          child: Center(
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 4),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const Text(
                                    '자녀와 함께한 지',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Color(0xFF353535),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w300,
                                      letterSpacing: -0.22,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    '총 283일째',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Color(0xFF146AFF),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.28,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // 구분선
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Container(
                            height: 40,
                            width: 1,
                            color: Colors.grey.withOpacity(0.3),
                          ),
                        ),

                        // 자녀 미션 수
                        Expanded(
                          child: Center(
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 4),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const Text(
                                    '자녀 완료 미션',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Color(0xFF353535),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w300,
                                      letterSpacing: -0.22,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    '총 8개',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Color(0xFF146AFF),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.28,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // 버튼 행 (부모용)
                Row(
                  children: [
                    // 자녀에게 이체 버튼
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: ShapeDecoration(
                          color: const Color(0xFFEFF2F6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            '자녀에게 이체',
                            style: TextStyle(
                              color: Color(0xFF001F55),
                              fontSize: 14,
                              fontWeight: FontWeight.w300,
                              letterSpacing: -0.28,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    // 계좌 충전 버튼
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: ShapeDecoration(
                          color: const Color(0xFF146AFF),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            '계좌 충전',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w300,
                              letterSpacing: -0.28,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12), // 두 박스 사이 간격 추가
          // 적립금 정보 카드 부분
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: ShapeDecoration(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 왼쪽 텍스트 - Flexible 추가
                Expanded(
                  flex: 3,
                  child: Container(
                    padding: EdgeInsets.only(left: 10), // 왼쪽 패딩 추가
                    child: Text(
                      '$userName님의 보유 적립금',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.26,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),

                // 금액 표시 부분
                Expanded(
                  flex: 2,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '23,000',
                        style: TextStyle(
                          color: const Color(0xFF146AFF),
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.32,
                        ),
                      ),
                      Text(
                        '원',
                        style: TextStyle(
                          color: const Color(0xFF146AFF),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          letterSpacing: -0.24,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.grey,
                        size: 24,
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

  // 프로필 이미지 위젯을 생성하는 헬퍼 메서드
  Widget _buildProfileImageWidget(String imageUrl, String fallbackText) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      width: 60,
      height: 60,
      placeholder:
          (context, url) => const Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
          ),
      errorWidget: (context, url, error) {
        print('이미지 로딩 오류: $error, URL: $url');
        return Center(
          child: Text(
            fallbackText,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      },
    );
  }

  // 메뉴 리스트
  Widget _buildMenuList() {
    // 사용자 권한에 따라 다른 메뉴 표시
    final userRole = _userInfo?['role'] ?? 'PARENT';
    print('마이페이지 메뉴 구성 - 현재 역할: $userRole');

    return Column(
      children: [
        // 첫 번째 섹션 (용돈 내역)
        _buildMenuSection(
          icon: Icons.account_balance_wallet,
          title: '용돈 관리',
          items: ['총 적립 내역', '자녀 이체 내역', '포인트 적립 내역'],
        ),

        const SizedBox(height: 16),

        // 두 번째 섹션 (계좌 관리)
        _buildMenuSection(
          icon: Icons.account_balance,
          title: '계좌 관리',
          items: ['충전 계좌 관리', '내 계좌 잔액', '자녀 계좌 연결'],
        ),

        const SizedBox(height: 16),

        // 세 번째 섹션 (자녀 활동 내역)
        _buildMenuSection(
          icon: Icons.assignment,
          title: '자녀 활동 관리',
          items: ['미션 관리/생성', '챌린지 관리', '목표 설정 지원', '자녀 리포트'],
        ),

        const SizedBox(height: 16),

        // 네 번째 섹션 (가족 관리)
        _buildMenuSection(
          icon: Icons.people,
          title: '가족 관리',
          items: ['가족 멤버 관리', '자녀 계정 설정', '가족 채팅', '알림 설정'],
        ),

        const SizedBox(height: 16),

        // 다섯 번째 섹션 (고객 지원)
        _buildMenuSection(
          icon: Icons.headset_mic,
          title: '고객 지원',
          items: ['고객센터', '공지사항', '약관 및 서비스 이용동의'],
        ),

        // 하단 네비게이션 바와의 간격
        const SizedBox(height: 40),
      ],
    );
  }

  // 메뉴 섹션 위젯
  Widget _buildMenuSection({
    required IconData icon,
    required String title,
    required List<String> items,
  }) {
    // 현재 섹션의 확장 상태 확인 (기본값은 true - 펼쳐진 상태)
    final bool isExpanded = _expandedSections[title] ?? true;

    return Container(
      width: 358,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 8,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // 타이틀 부분 - 클릭시 토글
          InkWell(
            onTap: () => _toggleSection(title),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F6F8),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Icon(icon, color: Color(0xFF146AFF), size: 20),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        title,
                        style: TextStyle(
                          color: Color(0xFF353535),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  // 화살표 아이콘 변경 (위/아래)
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_down
                        : Icons.keyboard_arrow_up,
                    color: Color(0xFF999999),
                    size: 24,
                  ),
                ],
              ),
            ),
          ),

          // 구분선
          Divider(height: 1, thickness: 1, color: Colors.grey.withOpacity(0.1)),

          // 아이템 리스트 - 확장 상태일 때만 표시
          if (isExpanded)
            ...items.asMap().entries.map((entry) {
              final int index = entry.key;
              final String item = entry.value;
              final bool isLast = index == items.length - 1;

              return Column(
                children: [
                  // 메뉴 아이템
                  _buildMenuItemRow(item),

                  // 다음 아이템이 있으면 구분선 추가
                  if (!isLast)
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: Colors.grey.withOpacity(0.1),
                    ),
                ],
              );
            }),
        ],
      ),
    );
  }

  // 메뉴 아이템 행
  Widget _buildMenuItemRow(String title) {
    return InkWell(
      onTap: () {
        // 메뉴 항목에 따라 다른 화면으로 이동
        if (title == '총 적립 내역') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PointHistoryScreen()),
          );
        }
        // 다른 메뉴 항목들에 대한 처리는 추후 추가
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        color: Colors.white,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                color: const Color(0xFF353535),
                fontSize: 15,
                fontWeight: FontWeight.w400,
              ),
            ),
            Icon(Icons.chevron_right, color: const Color(0xFFCCCCCC), size: 20),
          ],
        ),
      ),
    );
  }
}
