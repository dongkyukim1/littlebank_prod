import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ShareWithFriendScreen extends StatefulWidget {
  const ShareWithFriendScreen({super.key});

  @override
  State<ShareWithFriendScreen> createState() => _ShareWithFriendScreenState();
}

class _ShareWithFriendScreenState extends State<ShareWithFriendScreen> {
  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Image.asset(
            'assets/icons/parent/뒤로가기.png',
            width: 20,
            height: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '친구에게 공유하기',
          style: TextStyle(
            color: Colors.black,
            fontSize: 14,
            fontFamily: 'Pretendard-Bold',
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(0.00, -0.03),
            end: Alignment(1.00, 1.00),
            colors: [
              const Color(0xFFF0FFF8), // 연한 민트 화이트
              const Color(0xFF81FFD2),
              const Color(0xFF7AEED9),
              const Color(0xFF81FFD2).withOpacity(0.7), // 민트색으로 마무리
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // 상단 텍스트 부분
                Padding(
                  padding: const EdgeInsets.fromLTRB(20.0, 12.0, 20.0, 0.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '오늘의 미션, 내일의 성공!\n함께할 때 더 재밌는 앱 리틀뱅크입니다.',
                        style: TextStyle(
                          color: Color(0xFF202020),
                          fontSize: 16,
                          fontFamily: 'Pretendard-Bold',
                          height: 1.50,
                          letterSpacing: -0.80,
                        ),
                      ),
                      const SizedBox(height: 60),
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 6,
                          ),
                          decoration: ShapeDecoration(
                            color: const Color(0xFFEFF2F6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(48),
                            ),
                          ),
                          child: const Text(
                            '01',
                            style: TextStyle(
                              color: Color(0xFF001F55),
                              fontSize: 12,
                              fontFamily: 'Pretendard-Bold',
                              letterSpacing: -0.32,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Center(
                        child: Text(
                          '오늘도 내일도 리틀뱅크와 함께 재밌게\n자녀의 습관 형성을 도와요',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF202020),
                            fontSize: 16,
                            fontFamily: 'Pretendard-Bold',
                            letterSpacing: -0.32,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Container(
                          width: screenWidth - 40,
                          alignment: Alignment.center,
                          child: const Text(
                            '우리 아이에게 매일, 매주 미션을 제공하고\n미션과 챌린지 그리고 목표 달성 시 보상을 통해\n학습에 대한 동기부여와 꾸준한 습관 형성을 도울 수 있어요!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF666666),
                              fontSize: 12,
                              fontFamily: 'Pretendard-Light',
                              height: 1.50,
                              letterSpacing: -0.28,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),

                // 첫 번째 이미지 (01.png)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Image.asset(
                    'assets/icons/parent/my/recommend/01.png',
                    width: screenWidth - 40,
                    fit: BoxFit.contain,
                  ),
                ),

                // 02 섹션
                Padding(
                  padding: const EdgeInsets.fromLTRB(20.0, 24.0, 20.0, 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 6,
                          ),
                          decoration: ShapeDecoration(
                            color: const Color(0xFFEFF2F6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(48),
                            ),
                          ),
                          child: const Text(
                            '02',
                            style: TextStyle(
                              color: Color(0xFF001F55),
                              fontSize: 12,
                              fontFamily: 'Pretendard-Bold',
                              letterSpacing: -0.32,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Center(
                        child: Text(
                          '분석 보고서를 통해 자녀의 성장을 지켜봐요!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF202020),
                            fontSize: 14,
                            fontFamily: 'Pretendard-Bold',
                            letterSpacing: -0.80,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Container(
                          width: screenWidth - 40,
                          alignment: Alignment.center,
                          child: const Text(
                            '우리 아이의 학습 현황을 분석해서 보여드릴게요!\n편하게 읽기만 하시면 어쩌고',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF666666),
                              fontSize: 12,
                              fontFamily: 'Pretendard-Light',
                              height: 1.50,
                              letterSpacing: -0.28,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 부모 커뮤니티 버튼
                      Container(
                        width: 200,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 8,
                        ),
                        decoration: ShapeDecoration(
                          color: Color(0xFF146AFF),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(48),
                          ),
                        ),
                        child: const Text(
                          '미션을 통한 과목별 공부 시간 비교',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontFamily: 'Pretendard-Medium',
                            letterSpacing: -0.28,
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // 두 번째 이미지 (02.png)
                      Image.asset(
                        'assets/icons/parent/my/recommend/02.png',
                        width: screenWidth - 40,
                        fit: BoxFit.contain,
                      ),

                      const SizedBox(height: 40),

                      // 초대 코드 섹션
                      SizedBox(
                        width: double.infinity,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // 초대 코드 제목 - 왼쪽 정렬
                            Container(
                              width: screenWidth - 40,
                              padding: const EdgeInsets.only(left: 0),
                              alignment: Alignment.centerLeft,
                              child: const Text(
                                '내 초대 코드',
                                style: TextStyle(
                                  color: Color(0xFF202020),
                                  fontSize: 20,
                                  fontFamily: 'Pretendard-ExtraBold',
                                  letterSpacing: -0.80,
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            // 파란색 초대 코드 컨테이너
                            Container(
                              width: screenWidth - 20,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: ShapeDecoration(
                                color: const Color(0xFF146AFF),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const Text(
                                    'PARENT - 12345',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontFamily: 'Pretendard-Bold',
                                      letterSpacing: -0.80,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  GestureDetector(
                                    onTap: () {
                                      Clipboard.setData(
                                        ClipboardData(text: 'PARENT-12345'),
                                      );
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text('초대 코드가 복사되었습니다.'),
                                        ),
                                      );
                                    },
                                    child: SizedBox(
                                      width: 30,
                                      height: 30,
                                      child: Image.asset(
                                        'assets/icons/my/copy.png',
                                        width: 24,
                                        height: 24,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),
                          ],
                        ),
                      ),

                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        width: screenWidth,
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.black,
          boxShadow: [
            BoxShadow(
              color: Color(0x5B000000),
              blurRadius: 8,
              offset: Offset(0, -4),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: double.infinity,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    '부모님들께 소문내기',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontFamily: 'Pretendard-Bold',
                      letterSpacing: -0.72,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: screenWidth - 40,
                    child: const Text(
                      '함께 자녀의 성장을 응원해요!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFFCCCCCC),
                        fontSize: 12,
                        fontFamily: 'Pretendard-Light',
                        letterSpacing: -0.24,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
