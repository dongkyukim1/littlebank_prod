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

class TransferGuideModal extends StatefulWidget {
  const TransferGuideModal({super.key});

  @override
  State<TransferGuideModal> createState() => _TransferGuideModalState();
}

class _TransferGuideModalState extends State<TransferGuideModal> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarBrightness: Brightness.light,
          statusBarIconBrightness: Brightness.dark,
        ),

        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        // 제목
        title: Text(
          '꺼내기 안내',
          style: TextStyle(
            color: Colors.black,
            fontSize: 14,
            fontFamily: getPretendardFontFamily(FontWeight.w700),
            fontWeight: FontWeight.w700,
            letterSpacing: -0.32,
          ),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              // 헤더 섹션 (기존 코드와 동일)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                color: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '리틀뱅크의 꺼내기 서비스 이용하기 팁',
                      style: TextStyle(
                        color: const Color(0xFF202020),
                        fontSize: 16,
                        fontFamily: getPretendardFontFamily(FontWeight.w700),
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
                        fontFamily: getPretendardFontFamily(FontWeight.w300),
                        fontWeight: FontWeight.w300,
                        letterSpacing: -0.32,
                      ),
                    ),
                  ],
                ),
              ),

              // 메인 콘텐츠 섹션들 (기존 코드와 거의 동일)
              const SizedBox(height: 24), // 헤더와 첫 섹션 사이 간격 추가
              _buildSection('01', '포인트 꺼내기란 무엇일까요?', [
                '리틀뱅크와 함께 하다보면 가장 자주 이용하게 되는 서비스 중\n하나는 꺼내기 서비스일텐데요. 포인트 꺼내기라는 단어 자체가 생소하실 것 같아요.',
                '포인트 꺼내기란 충전이나 활동을 통해 열심히 모은 포인트를 현금으로 바꿔서 꺼내는 것을 말해요.',
                '모두에게 쉽고 간편한 꺼내기 서비스를 만들기 위해 노력했어요. 지금부터 리틀뱅크의 꺼내기 서비스에 대해 알아볼게요.',
              ], isFirst: true),
              const SizedBox(height: 32),
              _buildSection('02', '포인트 꺼내기는 어떻게 할 수 있나요?', [
                '꺼내기 전, 본인 명의의 계좌 연결 및 인증이 필수적이예요.',
                '최소 1,000원부터 꺼낼 수 있어요.',
                '현재 충전이나 리워드를 통해 누적된 포인트가 충분하다면, 포인트를 연결된 계좌로 현금처럼 꺼내서 사용할 수 있어요.',
                '사용자님이 입력하신 전화번호에 오류가 있을 경우, 꺼내기 실패에 대한 책임은 사용자님에게 있어요. 정확한 정보를 입력하고 꼭 확인해 주세요.',
                '계정 탈퇴 시, 보유 중인 포인트는 소멸돼요. 그 전에 다른 계좌로 보내거나 꺼내기를 통해 사용해 주세요.',
              ]),
              const SizedBox(height: 32),
              _buildSection('03', '수수료는 어떻게 되나요?', [
                '3만원 이상은 수수료가 무료예요.',
                '3만원 미만은 수수료 2%가 발생해요.',
                '모든 수수료는 꺼내는 금액에서 자동으로 차감돼요.',
              ]),
              const SizedBox(height: 32),
              _buildSection('04', '입금은 언제 되나요?', [
                '평일 오후 3시 이전에 신청하면, 당일에 입금해 드려요.',
                '평일 오후 3시 이후에 신청하면, 다음 영업일에 입금해 드려요.',
              ]),
              const SizedBox(height: 32),
            ],
          ),
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
                          text: '포인트 꺼내기란 충전이나 활동을 통해 ',
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
                          text: '열심히 모은 포인트를 현금으로 바꿔서 꺼내는 것',
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
