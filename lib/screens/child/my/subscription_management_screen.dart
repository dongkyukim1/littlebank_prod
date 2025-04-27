import 'package:flutter/material.dart';
import '../../../widgets/common/bottom_navigation_bar.dart';

class SubscriptionManagementScreen extends StatefulWidget {
  const SubscriptionManagementScreen({super.key});

  @override
  State<SubscriptionManagementScreen> createState() => _SubscriptionManagementScreenState();
}

class _SubscriptionManagementScreenState extends State<SubscriptionManagementScreen> {
  // 현재 선택된 탭 인덱스
  int _selectedTabIndex = 0;
  
  // 섹션별 GlobalKey 추가
  final GlobalKey _littleBankSectionKey = GlobalKey();
  final GlobalKey _benefitsSectionKey = GlobalKey();
  final GlobalKey _freeTierSectionKey = GlobalKey();
  
  // 스크롤 컨트롤러
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
  
  // 해당 섹션으로 스크롤
  void _scrollToSection(GlobalKey key) {
    final context = key.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
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
          '구독권 관리',
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
              // 홈으로 이동
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ],
      ),
      body: Container(
        color: const Color(0xFF146AFF),
        child: SingleChildScrollView(
          controller: _scrollController,
          child: Column(
            children: [
              // 상단 회색 배경 영역
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                decoration: const BoxDecoration(color: Color(0xFFEAEAEA)),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 흰색 정사각형 이미지
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            spreadRadius: 0,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      // 이미지 추가 (필요시 주석 해제)
                      // child: Image.asset('assets/images/subscription_image.png', fit: BoxFit.cover),
                    ),
                    const SizedBox(height: 30),
                    
                    // "무료 체험 기간에는 결제되지 않습니다" 텍스트
                    const Text(
                      '무료 체험 기간에는 결제되지 않습니다',
                      style: TextStyle(
                        color: Color(0xFF666666),
                        fontSize: 14,
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 5),
                    
                    // "2주 무료 체험으로 쉽게 시작해 보세요!" 텍스트
                    const Text(
                      '2주 무료 체험으로 쉽게 시작해 보세요!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF202020),
                        fontSize: 20,
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.80,
                      ),
                    ),
                  ],
                ),
              ),
              
              // 파란색 할인 배너
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: const BoxDecoration(
                  color: Color(0xFF5D9EFF),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text.rich(
                      TextSpan(
                        children: [
                          const TextSpan(
                            text: '3인 이상 구독 시, 최대 N%',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontFamily: 'Pretendard',
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.28,
                            ),
                          ),
                          const TextSpan(
                            text: '의 할인이 적용되었어요!',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontFamily: 'Pretendard',
                              fontWeight: FontWeight.w300,
                              letterSpacing: -0.28,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // 탭 메뉴 영역
              Container(
                width: double.infinity,
                height: 50,
                decoration: const BoxDecoration(
                  color: Color(0xFF202020),
                  border: Border(
                    bottom: BorderSide(
                      color: Color(0xFF333333),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // 리틀뱅크란 탭
                    _buildTabItem(0, '리틀뱅크란', _littleBankSectionKey),
                    
                    // 구독 혜택 탭
                    _buildTabItem(1, '구독 혜택', _benefitsSectionKey),
                    
                    // 무료 체험 탭
                    _buildTabItem(2, '무료 체험', _freeTierSectionKey),
                  ],
                ),
              ),
              
              // 리틀뱅크란 섹션
              Container(
                key: _littleBankSectionKey,
                width: double.infinity,
                color: const Color(0xFF202020),
                child: Image.asset(
                  'assets/poster/구독관리.png',
                  fit: BoxFit.fitWidth,
                  width: double.infinity,
                ),
              ),
              
              // 구독 혜택 섹션
              Container(
                key: _benefitsSectionKey,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment(0.50, -0.00),
                    end: Alignment(0.50, 1.00),
                    colors: [const Color(0xFF5086FF), const Color(0xFFA5AFFF)],
                  ),
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // 원형 그라데이션 배경
                    Positioned(
                      top: 50,
                      right: -120,
                      child: Container(
                        width: 390,
                        height: 390,
                        decoration: ShapeDecoration(
                          gradient: RadialGradient(
                            center: Alignment(0, 0),
                            radius: 0.8,
                            colors: [const Color(0xCC5086FF), const Color(0x7FA9B0FF), const Color(0x66A9B0FF), const Color(0x19C2D6F3)],
                            stops: [0.0, 0.3, 0.6, 1.0],
                          ),
                          shape: const OvalBorder(),
                        ),
                      ),
                    ),
                    
                    // 컨텐츠
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          // 반투명 흰색 컨테이너
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: ShapeDecoration(
                              color: Colors.white.withOpacity(0.4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // 상단 텍스트
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  child: Text.rich(
                                    TextSpan(
                                      children: [
                                        TextSpan(
                                          text: '리틀뱅크를 ',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontFamily: 'Pretendard',
                                            fontWeight: FontWeight.w700,
                                            height: 1.50,
                                            letterSpacing: -0.80,
                                          ),
                                        ),
                                        TextSpan(
                                          text: '구독하시는 모든 분들께\n',
                                          style: TextStyle(
                                            color: const Color(0xFF001F55),
                                            fontSize: 18,
                                            fontFamily: 'Pretendard',
                                            fontWeight: FontWeight.w800,
                                            height: 1.50,
                                            letterSpacing: -0.80,
                                          ),
                                        ),
                                        TextSpan(
                                          text: '이런 콘텐츠들을 제공해 드립니다',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontFamily: 'Pretendard',
                                            fontWeight: FontWeight.w700,
                                            height: 1.50,
                                            letterSpacing: -0.80,
                                          ),
                                        ),
                                      ],
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                // 혜택 리스트
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Column(
                                    children: [
                                      // 첫 번째 혜택
                                      Container(
                                        width: double.infinity,
                                        margin: const EdgeInsets.only(bottom: 8),
                                        child: Row(
                                          children: [
                                            Image.asset(
                                              'assets/icons/check_blue.png',
                                              width: 20,
                                              height: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text.rich(
                                                TextSpan(
                                                  children: [
                                                    TextSpan(
                                                      text: '꾸준한 미션 제공',
                                                      style: TextStyle(
                                                        color: const Color(0xFF202020),
                                                        fontSize: 14,
                                                        fontFamily: 'Pretendard',
                                                        fontWeight: FontWeight.w700,
                                                        letterSpacing: -0.32,
                                                      ),
                                                    ),
                                                    TextSpan(
                                                      text: '으로 효과적인 학습 동기부여 받기',
                                                      style: TextStyle(
                                                        color: const Color(0xFF202020),
                                                        fontSize: 13,
                                                        fontFamily: 'Pretendard',
                                                        fontWeight: FontWeight.w300,
                                                        letterSpacing: -0.32,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      
                                      // 두 번째 혜택
                                      Container(
                                        width: double.infinity,
                                        margin: const EdgeInsets.only(bottom: 8),
                                        child: Row(
                                          children: [
                                            Image.asset(
                                              'assets/icons/check_blue.png',
                                              width: 20,
                                              height: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text.rich(
                                                TextSpan(
                                                  children: [
                                                    TextSpan(
                                                      text: '혼자서도 챌린지 ',
                                                      style: TextStyle(
                                                        color: const Color(0xFF202020),
                                                        fontSize: 14,
                                                        fontFamily: 'Pretendard',
                                                        fontWeight: FontWeight.w700,
                                                        letterSpacing: -0.32,
                                                      ),
                                                    ),
                                                    TextSpan(
                                                      text: '참여하고 스스로 성장하기',
                                                      style: TextStyle(
                                                        color: const Color(0xFF202020),
                                                        fontSize: 14,
                                                        fontFamily: 'Pretendard',
                                                        fontWeight: FontWeight.w300,
                                                        letterSpacing: -0.32,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      
                                      // 세 번째 혜택
                                      SizedBox(
                                        width: double.infinity,
                                        child: Row(
                                          children: [
                                            Image.asset(
                                              'assets/icons/check_blue.png',
                                              width: 20,
                                              height: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text.rich(
                                                TextSpan(
                                                  children: [
                                                    TextSpan(
                                                      text: '친구들과의 소통',
                                                      style: TextStyle(
                                                        color: const Color(0xFF202020),
                                                        fontSize: 14,
                                                        fontFamily: 'Pretendard',
                                                        fontWeight: FontWeight.w700,
                                                        letterSpacing: -0.32,
                                                      ),
                                                    ),
                                                    TextSpan(
                                                      text: '으로 재밌게 경쟁하고 공유하기',
                                                      style: TextStyle(
                                                        color: const Color(0xFF202020),
                                                        fontSize: 14,
                                                        fontFamily: 'Pretendard',
                                                        fontWeight: FontWeight.w300,
                                                        letterSpacing: -0.32,
                                                      ),
                                                    ),
                                                  ],
                                                ),
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
                          
                          const SizedBox(height: 25),
                          // 구독권 가격 영역
                          _buildSubscriptionPriceCards(),
                          
                          // 영수증과 무료 체험 섹션 사이에 간격 추가 (10에서 150으로 증가)
                          const SizedBox(height: 550),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // 무료 체험 섹션 (구독 혜택 섹션과 연결)
              Transform.translate(
                offset: const Offset(0, -1),
                child: Container(
                  key: _freeTierSectionKey,
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment(0.50, -0.00),
                      end: Alignment(0.50, 0.70),
                      colors: [const Color(0xFFA5AFFF), const Color(0xFFA5AFFF)],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: '아직까지 고민이 된다면\n',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontFamily: 'Pretendard',
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.80,
                              ),
                            ),
                            TextSpan(
                              text: '2주 무료 체험 후 결정해 보세요!',
                              style: TextStyle(
                                color: const Color(0xFF001F55),
                                fontSize: 18,
                                fontFamily: 'Pretendard',
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.80,
                              ),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '2주 무료 체험 후, 한 번 더 물어볼게요!',
                        style: TextStyle(
                          color: const Color(0xFF001F55),
                          fontSize: 12,
                          fontFamily: 'Pretendard',
                          fontWeight: FontWeight.w300,
                          letterSpacing: -0.28,
                        ),
                      ),
                      const SizedBox(height: 70),
                      // 카드 이미지들
                      Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.center,
                        children: [
                          // 원형 그라데이션 배경
                          Positioned(
                            right: -150,
                            bottom: -300,
                            child: Container(
                              width: 390,
                              height: 390,
                              decoration: ShapeDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment(0.50, -0.00),
                                  end: Alignment(0.50, 1.02),
                                  colors: [const Color(0xFFA9B0FF), const Color(0xE5A9B0FF), const Color(0xA9A9B0FF), const Color(0x4CC2D6F3)],
                                ),
                                shape: OvalBorder(),
                              ),
                            ),
                          ),
                          // 회색 카드 (뒤에 위치)
                          Transform.translate(
                            offset: const Offset(30, 50),
                            child: Transform.rotate(
                              angle: 0.05,
                              child: Image.asset(
                                'assets/poster/2주구독권_grey.png',
                                width: 260,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          // 파란색 카드 (앞에 위치)
                          Transform.translate(
                            offset: const Offset(-15, 0),
                            child: Transform.rotate(
                              angle: -0.4,
                              child: Image.asset(
                                'assets/poster/2주구독권_blue.png',
                                width: 290,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // 탭 아이템 위젯 빌더
  Widget _buildTabItem(int index, String title, GlobalKey sectionKey) {
    bool isSelected = _selectedTabIndex == index;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTabIndex = index;
        });
        _scrollToSection(sectionKey);
      },
      child: Container(
        width: 120,
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 탭 텍스트
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF999999),
                  fontSize: 16,
                  fontFamily: 'Pretendard',
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w300,
                  letterSpacing: -0.32,
                ),
              ),
            ),
            
            // 인디케이터를 아래에 붙이기 위한 Spacer
            Spacer(),
            
            // 선택된 탭 하단에 표시되는 짧은 흰색 선 (박스 하단에 붙게)
            if (isSelected)
              Container(
                width: 80, // 탭 너비보다 좁게 설정하여 양쪽에 여백 추가
                height: 2,
                color: Colors.white,
              )
            else
              // 선택되지 않은 탭에는 투명한 공간 추가하여 높이 일정하게 유지
              Container(height: 2, color: Colors.transparent),
          ],
        ),
      ),
    );
  }
  
  // 구독권 가격 카드 위젯
  Widget _buildSubscriptionPriceCards() {
    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: MediaQuery.of(context).size.width,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 제목 섹션
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Column(
                children: [
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '같이 성장할수록 ',
                          style: TextStyle(
                            color: const Color(0xFF001F55),
                            fontSize: 16,
                            fontFamily: 'Pretendard',
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.88,
                          ),
                        ),
                        TextSpan(
                          text: '더 즐거운 리틀뱅크',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontFamily: 'Pretendard',
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.88,
                          ),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(
                    width: 158,
                    child: Text(
                      '같이 구독하고 더 큰 혜택 받기',
                      style: TextStyle(
                        color: const Color(0xFF001F55),
                        fontSize: 12,
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w300,
                        letterSpacing: -0.28,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // 간격 추가
            const SizedBox(height: 20),
            
            // Stack을 사용하여 흰색 박스가 회색 그라데이션 컨테이너의 수직 중앙을 통과하도록 배치
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.topCenter,
              children: [
                // 회색 그라데이션 컨테이너 
                Container(
                  width: 340, // 358에서 340으로 줄임
                  height: 24,
                  decoration: ShapeDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment(0.50, 0.00),
                      end: Alignment(0.50, 1.00),
                      colors: [Color(0xFFD9D9D9), Color(0xFF737373)],
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  // 회색 바 안에 내부 바 추가
                  child: Center(
                    child: Container(
                      width: 310,
                      height: 15,
                      decoration: ShapeDecoration(
                        color: const Color(0xFF737373),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                    ),
                  ),
                ),
                
                // 흰색 영수증 박스를 회색 바의 위치에 맞게 조정
                Positioned(
                  top: 12, // 회색 바 높이(24)의 절반만큼 내려서 수직 중앙에 위치하도록 함
                  child: Container(
                    width: 300, // 314에서 300으로 줄임
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: const Alignment(0.50, -0.00),
                        end: const Alignment(0.50, 1.00),
                        colors: [
                          Colors.white, 
                          Colors.white.withOpacity(0.9),
                          const Color(0xFFF5F6FF),
                          const Color(0xFFECF0FF),
                          const Color(0xFFE2EBFF).withOpacity(0.9),
                          const Color(0xFFD5E1FF).withOpacity(0.8),
                        ],
                        stops: const [0.0, 0.5, 0.65, 0.8, 0.9, 1.0],
                      ),
                      // 테두리 전체에 그림자 효과 적용
                      boxShadow: [
                        // 첫 번째 그림자 - 테두리 전체에 적용
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          spreadRadius: 1,
                          offset: const Offset(0, 0), // 오프셋을 0,0으로 하여 모든 방향으로 그림자 적용
                        ),
                        // 두 번째 그림자 - 입체감 강화
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 4,
                          spreadRadius: 1,
                          offset: const Offset(0, 1), // 약간 아래 방향으로
                        ),
                        // 세 번째 그림자 - 종이 영수증 느낌 강화
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 2,
                          spreadRadius: 0,
                          offset: const Offset(1, 1), // 약간 오른쪽 아래 방향으로
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 영수증 내부 상단 여백 추가
                        const SizedBox(height: 15),
                        
                        // 1인 구독권
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            // 카드 
                            Container(
                              width: 270, // 285에서 270으로 줄임
                              margin: const EdgeInsets.only(top: 12),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: ShapeDecoration(
                                color: const Color(0x66EFF2F6),
                                shape: RoundedRectangleBorder(
                                  side: const BorderSide(
                                    width: 1.40,
                                    color: Color(0xFF146AFF),
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // 텍스트 위에 간격 추가
                                  const SizedBox(height: 5),
                                  const Text(
                                    '혼자서도 동기부여를 받을 수 있어요!',
                                    style: TextStyle(
                                      color: Color(0xFF353535),
                                      fontSize: 12,
                                      fontFamily: 'Pretendard',
                                      fontWeight: FontWeight.w300,
                                      letterSpacing: -0.24,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Text(
                                        '₩ 3,500원',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Color(0xFF202020),
                                          fontSize: 20,
                                          fontFamily: 'Pretendard',
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: -0.64,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      const Text(
                                        '/ 월간',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Color(0xFF666666),
                                          fontSize: 16,
                                          fontFamily: 'Pretendard',
                                          fontWeight: FontWeight.w300,
                                          letterSpacing: -0.24,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            
                            // 라벨 (위에 겹쳐서 표시)
                            Positioned(
                              top: -10,
                              left: 10,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: ShapeDecoration(
                                  color: const Color(0xFFFFA63D),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text(
                                  '1인 구독권',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontFamily: 'Pretendard',
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.22,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        // 구독권 카드 사이 간격 증가
                        const SizedBox(height: 30),
                        
                        // 3인 구독권
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            // 카드
                            Container(
                              width: 270, // 285에서 270으로 줄임
                              margin: const EdgeInsets.only(top: 12),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: ShapeDecoration(
                                color: const Color(0x66EFF2F6),
                                shape: RoundedRectangleBorder(
                                  side: const BorderSide(
                                    width: 1.40,
                                    color: Color(0xFF146AFF),
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // 텍스트 위에 간격 추가
                                  const SizedBox(height: 5),
                                  const Text(
                                    '친구와 같이 기록을 공유할 수 있어요!',
                                    style: TextStyle(
                                      color: Color(0xFF353535),
                                      fontSize: 12,
                                      fontFamily: 'Pretendard',
                                      fontWeight: FontWeight.w300,
                                      letterSpacing: -0.24,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Text(
                                        '₩ 7,500원',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Color(0xFF202020),
                                          fontSize: 20,
                                          fontFamily: 'Pretendard',
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: -0.64,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      const Text(
                                        '/ 월간',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Color(0xFF666666),
                                          fontSize: 16,
                                          fontFamily: 'Pretendard',
                                          fontWeight: FontWeight.w300,
                                          letterSpacing: -0.24,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            
                            // 라벨 (위에 겹쳐서 표시)
                            Positioned(
                              top: -10,
                              left: 10,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: ShapeDecoration(
                                  color: const Color(0xFFFFA63D),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text(
                                  '3인 구독권',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontFamily: 'Pretendard',
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.22,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        // 구독권 카드 사이 간격 증가
                        const SizedBox(height: 30),
                        
                        // 5인 구독권
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            // 카드
                            Container(
                              width: 270, // 285에서 270으로 줄임
                              margin: const EdgeInsets.only(top: 12),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: ShapeDecoration(
                                color: const Color(0x66EFF2F6),
                                shape: RoundedRectangleBorder(
                                  side: const BorderSide(
                                    width: 1.40,
                                    color: Color(0xFF146AFF),
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // 텍스트 위에 간격 추가
                                  const SizedBox(height: 5),
                                  const Text(
                                    '친구와 함께 랭킹을 통해 경쟁해 보세요!',
                                    style: TextStyle(
                                      color: Color(0xFF353535),
                                      fontSize: 12,
                                      fontFamily: 'Pretendard',
                                      fontWeight: FontWeight.w300,
                                      letterSpacing: -0.24,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Text(
                                        '₩9,500원',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Color(0xFF202020),
                                          fontSize: 20,
                                          fontFamily: 'Pretendard',
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: -0.64,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      const Text(
                                        '/ 월간',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Color(0xFF666666),
                                          fontSize: 16,
                                          fontFamily: 'Pretendard',
                                          fontWeight: FontWeight.w300,
                                          letterSpacing: -0.24,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            
                            // 라벨 (위에 겹쳐서 표시)
                            Positioned(
                              top: -10,
                              left: 10,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: ShapeDecoration(
                                  color: const Color(0xFFFFA63D),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text(
                                  '5인 구독권',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontFamily: 'Pretendard',
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.22,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        // 하단 여백 증가
                        const SizedBox(height: 30),
                        
                        // 하단 점선 구분선 (5인 구독권 아래에만 존재)
                        Container(
                          width: 280,
                          height: 1,
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(1),
                          ),
                          child: const CustomPaint(
                            painter: DottedLinePainter(),
                          ),
                        ),
                        
                        const SizedBox(height: 14),
                        
                        // 하단 텍스트
                        Column(
                          children: [
                            const Text(
                              '이렇게 좋은 기능들을 함께 XXXX',
                              style: TextStyle(
                                color: Color(0xFF353535),
                                fontSize: 12,
                                fontFamily: 'Pretendard',
                                fontWeight: FontWeight.w300,
                                letterSpacing: -0.24,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              '나눌수록 커지는 XXX',
                              style: TextStyle(
                                color: Color(0xFF353535),
                                fontSize: 12,
                                fontFamily: 'Pretendard',
                                fontWeight: FontWeight.w300,
                                letterSpacing: -0.24,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// 점선 그리기 위한 CustomPainter
class DottedLinePainter extends CustomPainter {
  final Color color;
  
  const DottedLinePainter({this.color = const Color(0xFF999999)});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color // 파라미터로 받은 색상 사용
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;

    const double dashWidth = 3.0;
    const double dashSpace = 3.0;
    double startX = 0.0;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, 0),
        Offset(startX + dashWidth, 0),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
} 