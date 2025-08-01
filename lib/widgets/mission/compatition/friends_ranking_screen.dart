import 'package:flutter/material.dart';

/// 친구 랭킹 결과 화면
class FriendsRankingScreen extends StatefulWidget {
  final Map<String, dynamic> friendData;
  final int targetAmount;
  final Function(Map<String, dynamic>)? onStartCompetition; // 경쟁 시작 콜백

  const FriendsRankingScreen({
    super.key,
    required this.friendData,
    required this.targetAmount,
    this.onStartCompetition, // 선택적 파라미터
  });

  @override
  State<FriendsRankingScreen> createState() => _FriendsRankingScreenState();
}

class _FriendsRankingScreenState extends State<FriendsRankingScreen> {
  void _startCompetition() {
    // 경쟁 시작 콜백 호출
    if (widget.onStartCompetition != null) {
      widget.onStartCompetition!(widget.friendData);
      // 화면 닫기
      Navigator.of(context).pop();
    } else {
      // 기존 로직 (콜백이 없는 경우)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${widget.friendData['name']}님과 경쟁이 시작되었습니다!',
            style: const TextStyle(
              fontFamily: 'Pretendard-Regular',
            ),
          ),
          backgroundColor: const Color(0xFF146AFF),
          duration: const Duration(seconds: 2),
        ),
      );
      
      // 화면 닫기
      Navigator.of(context).pop();
    }
  }

  void _findAnotherFriend() {
    // 다른 친구 찾기 처리
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          '다른 친구를 찾고 있습니다...',
          style: TextStyle(
            fontFamily: 'Pretendard-Regular',
          ),
        ),
        backgroundColor: const Color(0xFF5D9EFF),
        duration: const Duration(seconds: 2),
      ),
    );
    
    // TODO: 다른 친구 찾기 로직 구현
  }

  @override
  Widget build(BuildContext context) {
    // 화면 크기에 따른 반응형 디자인
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFE7ECF6),
      body: SafeArea(
        child: Column(
          children: [
            // 상단 앱바 영역
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Image.asset(
                      'assets/icons/my/close.png',
                      width: 20,
                      height: 20,
                      color: const Color(0xFF202020),
                    ),
                  ),
                ],
              ),
            ),
            
            // 메인 콘텐츠
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 120),
                    
                    // 상단 텍스트 영역
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 제목 텍스트
                        SizedBox(
                          width: double.infinity,
                          child: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: '리틀뱅크에서 ',
                                  style: TextStyle(
                                    color: const Color(0xFF202020),
                                    fontSize: screenWidth > 600 ? 20 : 18,
                                    fontFamily: 'Pretendard-Bold',
                                    height: 1.50,
                                    letterSpacing: -0.80,
                                  ),
                                ),
                                TextSpan(
                                  text: '딱 맞는 친구 1명',
                                  style: TextStyle(
                                    color: const Color(0xFF3A88F4),
                                    fontSize: screenWidth > 600 ? 20 : 18,
                                    fontFamily: 'Pretendard-Bold',
                                    height: 1.50,
                                    letterSpacing: -0.80,
                                  ),
                                ),
                                TextSpan(
                                  text: '\n을 찾아드렸어요! \n이 친구와 경쟁을 시작해 보세요!',
                                  style: TextStyle(
                                    color: const Color(0xFF202020),
                                    fontSize: screenWidth > 600 ? 20 : 18,
                                    fontFamily: 'Pretendard-Bold',
                                    height: 1.50,
                                    letterSpacing: -0.80,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 8),
                        
                        // 부제목
                        SizedBox(
                          width: double.infinity,
                          child: Text(
                            '내 목표보다 5만원이 적거나, 많은 친구들 중에서 찾았어요',
                            style: TextStyle(
                              color: const Color(0xFF999999),
                              fontSize: screenWidth > 600 ? 14 : 12,
                              fontFamily: 'Pretendard-Light',
                              letterSpacing: -0.28,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 56),
                    
                    // 친구 정보 카드
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0x3F146AFF),
                            blurRadius: 10,
                            offset: const Offset(3, 4),
                            spreadRadius: 0,
                          ),
                          BoxShadow(
                            color: const Color(0x3F146AFF),
                            blurRadius: 10,
                            offset: const Offset(-3, -4),
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: ShapeDecoration(
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 친구 정보
                            Expanded(
                              child: Row(
                                children: [
                                  // 프로필 이미지
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: ShapeDecoration(
                                      image: DecorationImage(
                                        image: NetworkImage(
                                          widget.friendData['profileImageUrl'] ?? 
                                          'https://placehold.co/40x40',
                                        ),
                                        fit: BoxFit.cover,
                                      ),
                                      shape: const OvalBorder(
                                        side: BorderSide(
                                          width: 0.80,
                                          color: Color(0xFF146AFF),
                                        ),
                                      ),
                                    ),
                                  ),
                                  
                                  const SizedBox(width: 16),
                                  
                                  // 이름과 목표 금액
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          widget.friendData['name'] ?? '친구',
                                          style: TextStyle(
                                            color: const Color(0xFF001F55),
                                            fontSize: screenWidth > 600 ? 16 : 14,
                                            fontFamily: 'Pretendard-Bold',
                                            letterSpacing: -0.28,
                                          ),
                                        ),
                                        
                                        const SizedBox(height: 4),
                                        
                                        Wrap(
                                          children: [
                                            Text(
                                              '현재 목표 금액 ',
                                              style: TextStyle(
                                                color: const Color(0xFF999999),
                                                fontSize: screenWidth > 600 ? 16 : 14,
                                                fontFamily: 'Pretendard-Light',
                                                letterSpacing: -0.28,
                                              ),
                                            ),
                                            Text(
                                              '${widget.friendData['targetAmount']?.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}원',
                                              style: TextStyle(
                                                color: const Color(0xFF146AFF),
                                                fontSize: screenWidth > 600 ? 18 : 16,
                                                fontFamily: 'Pretendard-Bold',
                                                letterSpacing: -0.32,
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
                            
                            // 달성 배지
                            Container(
                              height: 29,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: ShapeDecoration(
                                color: const Color(0xFFFFD27F),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text: '${widget.friendData['entireCompleted']}개',
                                      style: TextStyle(
                                        color: const Color(0xFF001F55),
                                        fontSize: screenWidth > 600 ? 14 : 12,
                                        fontFamily: 'Pretendard-Medium',
                                        letterSpacing: -0.24,
                                      ),
                                    ),
                                    TextSpan(
                                      text: ' 달성',
                                      style: TextStyle(
                                        color: const Color(0xFF001F55),
                                        fontSize: screenWidth > 600 ? 14 : 12,
                                        fontFamily: 'Pretendard-Light',
                                        letterSpacing: -0.24,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 48),
                    
                    // 버튼 영역
                    Column(
                      children: [
                        // 경쟁 시작 버튼
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _startCompetition,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF146AFF),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Text(
                              '이 친구와 경쟁하기',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: screenWidth > 600 ? 16 : 14,
                                fontFamily: 'Pretendard-Medium',
                                letterSpacing: -0.28,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // 다른 친구 찾기 버튼
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: OutlinedButton(
                            onPressed: _findAnotherFriend,
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                width: 0.70,
                                color: Color(0xFF5D9EFF),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              backgroundColor: const Color(0xFFE7ECF6),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.refresh,
                                  color: const Color(0xFF5D9EFF),
                                  size: screenWidth > 600 ? 22 : 20,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  '다른 친구로 추천받기',
                                  style: TextStyle(
                                    color: const Color(0xFF5D9EFF),
                                    fontSize: screenWidth > 600 ? 16 : 14,
                                    fontFamily: 'Pretendard-Light',
                                    letterSpacing: -0.28,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    // 하단 여백
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 