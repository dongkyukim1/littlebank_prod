import 'package:flutter/material.dart';
import '../../../services/auth_service.dart';
import 'package:cached_network_image/cached_network_image.dart';

class FamilyMemberManagementScreen extends StatefulWidget {
  const FamilyMemberManagementScreen({super.key});

  @override
  State<FamilyMemberManagementScreen> createState() => _FamilyMemberManagementScreenState();
}

class _FamilyMemberManagementScreenState extends State<FamilyMemberManagementScreen> {
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
            fontSize: 16,
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w700,
            letterSpacing: -0.32,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Image.asset(
              'assets/images/home.png', 
              width: 24, 
              height: 24,
            ),
            onPressed: () {
              // 홈 화면으로 이동 로직 추가
            },
          ),
        ],
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 내 계정 섹션
                      _buildMyAccountSection(),
                      
                      const SizedBox(height: 24),
                      
                      // 함께 이용하는 멤버 섹션
                      _buildMembersSection(),
                      
                      const SizedBox(height: 24),
                      
                      // 안내 메시지 섹션
                      _buildInfoSection(),
                    ],
                  ),
                ),
    );
  }
  
  // 내 계정 섹션
  Widget _buildMyAccountSection() {
    // 사용자 정보에서 필요한 데이터 추출
    final userName = _userInfo?['name'] ?? '사용자';
    final userRole = _userInfo?['role'] ?? 'CHILD';

    // 사용자 권한에 따라 다른 색상과 텍스트 표시
    final Color badgeColor = (userRole == 'CHILD')
        ? const Color(0xFF89DA8D)
        : const Color(0xFF146AFF);
    final String badgeText = (userRole == 'CHILD') ? '자녀' : '부모';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 내 계정 헤더
        Padding(
          padding: const EdgeInsets.only(left: 16, top: 16, bottom: 8),
          child: Text(
            '내 계정',
            style: TextStyle(
              color: const Color(0xFF202020),
              fontSize: 18,
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
        ),
        
        // 내 계정 카드
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(16),
          decoration: ShapeDecoration(
            color: const Color(0xFFF5F6F8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Row(
            children: [
              // 프로필 이미지
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(35),
                ),
                child: _userInfo?['profileImagePath'] != null &&
                       _userInfo!['profileImagePath']!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(35),
                      child: CachedNetworkImage(
                        imageUrl: AuthService.getFullProfileImageUrl(
                          _userInfo!['profileImagePath'],
                        ),
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                        errorWidget: (context, url, error) => Image.asset(
                          'assets/images/kid.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(35),
                      child: Image.asset(
                        'assets/images/kid.png',
                        fit: BoxFit.cover,
                      ),
                    ),
              ),
              
              const SizedBox(width: 16),
              
              // 사용자 정보
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 역할 뱃지
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: ShapeDecoration(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          side: BorderSide(
                            width: 0.35,
                            color: badgeColor,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        badgeText,
                        style: TextStyle(
                          color: badgeColor,
                          fontSize: 12,
                          fontFamily: 'Pretendard',
                          fontWeight: FontWeight.w300,
                          letterSpacing: -0.24,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 10),
                    
                    // 사용자 이름
                    Text(
                      userName,
                      style: TextStyle(
                        color: const Color(0xFF202020),
                        fontSize: 16,
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.32,
                      ),
                    ),
                  ],
                ),
              ),
              
              // 체크 아이콘
              Container(
                width: 24,
                height: 24,
                child: Image.asset(
                  'assets/icons/check_subs.png',
                  width: 24,
                  height: 24,
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
        // 헤더 섹션 (제목과 멤버 추가하기 버튼)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 제목과 설명
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '함께 이용하는 멤버들이예요',
                    style: TextStyle(
                      color: const Color(0xFF202020),
                      fontSize: 18,
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                  
                  const SizedBox(height: 6),
                  
                  Text(
                    '3인 구독권을 함께 이용 중이예요',
                    style: TextStyle(
                      color: const Color(0xFF999999),
                      fontSize: 14,
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w300,
                      letterSpacing: -0.28,
                    ),
                  ),
                ],
              ),
              
              // 멤버 추가하기 버튼
              GestureDetector(
                onTap: () {
                  // 멤버 추가 관련 로직
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('구독권 관리 화면으로 이동합니다.')),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: ShapeDecoration(
                    color: const Color(0xFFF5F6F8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    '멤버 추가하기',
                    style: TextStyle(
                      color: const Color(0xFF001F55),
                      fontSize: 12,
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.24,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // 멤버 카드 그리드
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 첫 번째 멤버 카드
              _buildMemberCard('강뱅뱅', 'CHILD'),
              
              // 두 번째 멤버 카드
              _buildMemberCard('강뱅뱅', 'CHILD'),
            ],
          ),
        ),
        
        // 안내문 섹션 위 여백 추가
        const SizedBox(height: 80),
      ],
    );
  }
  
  // 멤버 카드 위젯
  Widget _buildMemberCard(String name, String role) {
    final Color badgeColor = (role == 'CHILD')
        ? const Color(0xFF89DA8D)
        : const Color(0xFF146AFF);
    final String badgeText = (role == 'CHILD') ? '자녀' : '부모';
    
    return Container(
      width: MediaQuery.of(context).size.width * 0.44, // 화면 너비의 44%
      padding: const EdgeInsets.all(16),
      decoration: ShapeDecoration(
        color: const Color(0xFFF5F6F8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 프로필 이미지
          ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: Image.asset(
              'assets/images/kid.png',
              width: 60,
              height: 60,
              fit: BoxFit.cover,
            ),
          ),
          
          const SizedBox(width: 12),
          
          // 텍스트 정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 역할 뱃지
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: ShapeDecoration(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      side: BorderSide(
                        width: 0.35,
                        color: badgeColor,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(
                      color: badgeColor,
                      fontSize: 12,
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w300,
                      letterSpacing: -0.24,
                    ),
                  ),
                ),
                
                const SizedBox(height: 6),
                
                // 멤버 이름
                Text(
                  name,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: const Color(0xFF202020),
                    fontSize: 14,
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w700,
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
  
  // 안내 메시지 섹션
  Widget _buildInfoSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // 첫 번째 안내 카드
          _buildInfoCard(
            '새 멤버 추가는 구독권 변경 후에 가능합니다.',
            '기존 멤버 외 추가하고 싶은 멤버가 있다면, 멤버 추가하기 버튼 선택 후 구독권 관리에서 멤버를 추가할 수 있습니다.',
          ),
          
          const SizedBox(height: 12),
          
          // 두 번째 안내 카드
          _buildInfoCard(
            '현재 화면에서는 함께 구독 중인 멤버들을 볼 수 있습니다.',
            '추가는 구독권 관리 화면에서 가능하며, 현재 멤버 삭제 기능은 제공 중이지 않습니다. 해당 멤버를 삭제하고 싶을 시, 구독권 해지를 통해 가능합니다.',
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
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
                child: Icon(
                  Icons.info_outline,
                  color: Colors.grey,
                  size: 14,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: const Color(0xFF666666),
                    fontSize: 11,
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w500,
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
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w300,
                height: 1.4,
                letterSpacing: -0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
} 