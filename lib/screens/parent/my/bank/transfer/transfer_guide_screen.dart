import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

String getPretendardFontFamily(FontWeight fontWeight) {
  switch (fontWeight) {
    case FontWeight.w100:
      return 'Pretendard-Thin';
    case FontWeight.w200:
      return 'Pretendard-ExtraLight';
    case FontWeight.w300:
      return 'Pretendard-Light';
    case FontWeight.w400:
      return 'Pretendard-Regular';
    case FontWeight.w500:
      return 'Pretendard-Medium';
    case FontWeight.w600:
      return 'Pretendard-SemiBold';
    case FontWeight.w700:
      return 'Pretendard-Bold';
    case FontWeight.w800:
      return 'Pretendard-ExtraBold';
    case FontWeight.w900:
      return 'Pretendard-Black';
    default:
      return 'Pretendard-Regular';
  }
}

class TransferGuideScreen extends StatefulWidget {
  const TransferGuideScreen({super.key});

  @override
  State<TransferGuideScreen> createState() => _TransferGuideScreenState();
}

class _TransferGuideScreenState extends State<TransferGuideScreen> {
  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarBrightness: Brightness.light,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.white,
        child: Column(
          children: [
            // 상태바 + 커스텀 헤더
            Container(
              width: double.infinity,
              height: MediaQuery.of(context).padding.top + 56,
              color: Colors.white,
              padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
              child: Stack(
                children: [
                  // 뒤로가기 버튼
                  Positioned(
                    left: 16,
                    top: 16,
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 24,
                        height: 24,
                        child: Icon(
                          Icons.arrow_back_ios,
                          size: 20,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                  // 제목
                  Positioned(
                    top: 16,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Text(
                        '보내기 안내',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 14,
                          fontFamily: getPretendardFontFamily(FontWeight.w700),
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.32,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 나머지 콘텐츠
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    // 헤더 섹션
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      color: Colors.white,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '리틀뱅크의 보내기 서비스 이용하기 팁',
                            style: TextStyle(
                              color: const Color(0xFF202020),
                              fontSize: 16,
                              fontFamily: getPretendardFontFamily(
                                FontWeight.w700,
                              ),
                              fontWeight: FontWeight.w700,
                              height: 1.50,
                              letterSpacing: -0.72,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '이것만 알면 쉽게 이용할 수 있어요',
                            style: TextStyle(
                              color: const Color(0xFF999999),
                              fontSize: 14,
                              fontFamily: getPretendardFontFamily(
                                FontWeight.w300,
                              ),
                              fontWeight: FontWeight.w300,
                              letterSpacing: -0.32,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 메인 콘텐츠 섹션들
                    const SizedBox(height: 24),
                    _buildSection('01', '포인트 보내기란 무엇일까요?', [
                      '리틀뱅크와 함께 하다보면 가장 자주 이용하게 되는 서비스 중\n하나는 보내기 서비스일텐데요. 번거롭게 매번 계좌번호를 외워서 입력해야 한다거나, 이체할 때마다 수수료를 내야한다는\n부담스러움이 있으셨을 거 같아요.',
                      '포인트 이체란 현재 보유 중인 포인트를 리틀뱅크를 이용 중인 다른 사용자에게 보내는 행동을 말해요.',
                      '모두에게 쉽고 간편한 이체 서비스를 만들기 위해 노력했어요.\n지금부터 리틀뱅크의 이체 서비스에 대해 알아볼게요.',
                    ], isFirst: true),
                    const SizedBox(height: 32),
                    _buildSection('02', '포인트 보내기는 어떻게 할 수 있나요?', [
                      '보내기 전, 본인 명의의 계좌 연결 및 인증이 필수적이예요.',
                      '상대방의 핸드폰 번호만 알고있으면 바로 보낼 수 있어요',
                      '최소 1,000원부터 최대 100,000원까지 한 번에 보낼 수 있어요.',
                      '현재 충전이나 리워드를 통해 누적된 포인트가 충분하다면, 포인트를 상대방의 계좌로 보낼 수 있어요.',
                      '사용자님이 입력하신 전화번호에 오류가 있을 경우, 보내기 실패에 대한 책임은 사용자님에게 있어요. 정확한 정보를 입력하고 꼭 확인해 주세요.',
                      '계정 탈퇴 시, 보유 중인 포인트는 소멸돼요. 그 전에 다른 계좌로 보내거나 꺼내기를 통해 현금화해 주세요.',
                    ]),
                    const SizedBox(height: 32),
                    _buildSection('03', '수수료는 어떻게 되나요?', [
                      '포인트 보내기는 수수료가 무료예요.',
                    ]),
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

  Widget _buildSection(
    String number,
    String title,
    List<String> items, {
    bool isFirst = false,
  }) {
    return Container(
      width: double.infinity,
      child: Column(
        children: [
          // 섹션 번호
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            decoration: ShapeDecoration(
              color: const Color(0xFFE7ECF6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(48),
              ),
            ),
            child: Text(
              number,
              style: TextStyle(
                color: const Color(0xFF001F55),
                fontSize: 14,
                fontFamily: getPretendardFontFamily(FontWeight.w700),
                fontWeight: FontWeight.w700,
                letterSpacing: -0.32,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 섹션 제목
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(
              top: 12,
              left: 16,
              right: 16,
              bottom: 24,
            ),
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: const Color(0xFF202020),
                fontSize: 18,
                fontFamily: getPretendardFontFamily(FontWeight.w700),
                fontWeight: FontWeight.w700,
                height: 1.50,
                letterSpacing: -0.80,
              ),
            ),
          ),

          // 섹션 내용
          if (isFirst) ...[
            // 첫 번째 섹션은 중앙 정렬된 텍스트들
            ...items.asMap().entries.map((entry) {
              String content = entry.value;
              if (entry.key == 1) {
                // 두 번째 항목은 Text.rich 사용
                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '포인트 보내기란 현재 보유 중인 포인트를 ',
                          style: TextStyle(
                            color: const Color(0xFF4A4A4A),
                            fontSize: 12,
                            fontFamily: getPretendardFontFamily(
                              FontWeight.w300,
                            ),
                            fontWeight: FontWeight.w300,
                            height: 1.50,
                            letterSpacing: -0.28,
                          ),
                        ),
                        TextSpan(
                          text: '리틀뱅크를 이용 중인 다른 사용자에게 보내는 행동',
                          style: TextStyle(
                            color: const Color(0xFF4A4A4A),
                            fontSize: 12,
                            fontFamily: getPretendardFontFamily(
                              FontWeight.w700,
                            ),
                            fontWeight: FontWeight.w700,
                            height: 1.50,
                            letterSpacing: -0.28,
                          ),
                        ),
                        TextSpan(
                          text: '을 말해요.',
                          style: TextStyle(
                            color: const Color(0xFF4A4A4A),
                            fontSize: 12,
                            fontFamily: getPretendardFontFamily(
                              FontWeight.w300,
                            ),
                            fontWeight: FontWeight.w300,
                            height: 1.50,
                            letterSpacing: -0.28,
                          ),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                );
              } else {
                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    content,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: const Color(0xFF4A4A4A),
                      fontSize: 12,
                      fontFamily: getPretendardFontFamily(FontWeight.w300),
                      fontWeight: FontWeight.w300,
                      height: 1.50,
                      letterSpacing: -0.28,
                    ),
                  ),
                );
              }
            }).toList(),
          ] else ...[
            // 나머지 섹션들은 번호 매겨진 리스트
            ...items.asMap().entries.map((entry) {
              int index = entry.key;
              String content = entry.value;
              return Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 노란색 원 안에 숫자
                    Container(
                      width: 20,
                      height: 20,
                      decoration: ShapeDecoration(
                        color: const Color(0xFFFFD27F),
                        shape: OvalBorder(),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: const Color(0xFF001F55),
                            fontSize: 11,
                            fontFamily: getPretendardFontFamily(
                              FontWeight.w700,
                            ),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        content,
                        style: TextStyle(
                          color: const Color(0xFF4A4A4A),
                          fontSize: 12,
                          fontFamily: getPretendardFontFamily(FontWeight.w300),
                          fontWeight: FontWeight.w300,
                          height: 1.50,
                          letterSpacing: -0.28,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ],
      ),
    );
  }
}
