import 'package:flutter/material.dart';
import '../screens/child/user_missions_screen.dart';

class MissionCard extends StatefulWidget {
  final Function(bool) onExpandChanged;
  final int initialCardIndex;
  final Function(int)? onCardChanged;

  const MissionCard({
    super.key,
    required this.onExpandChanged,
    this.initialCardIndex = 0,
    this.onCardChanged,
  });

  @override
  State<MissionCard> createState() => _MissionCardState();
}

class _MissionCardState extends State<MissionCard>
    with AutomaticKeepAliveClientMixin {
  bool _isExpanded = false;
  late PageController cardController;
  late ValueNotifier<int> currentCardIndex;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    cardController = PageController(initialPage: widget.initialCardIndex);
    currentCardIndex = ValueNotifier<int>(widget.initialCardIndex);
  }

  @override
  void didUpdateWidget(MissionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialCardIndex != widget.initialCardIndex &&
        mounted &&
        widget.initialCardIndex >= 0 &&
        widget.initialCardIndex < cards.length) {
      try {
        // 외부에서 인덱스가 변경되면 PageController도 해당 페이지로 이동
        print(
          '미션 카드 인덱스 변경: ${widget.initialCardIndex} - ${cards[widget.initialCardIndex]['title']}',
        );

        cardController.jumpToPage(widget.initialCardIndex);
        currentCardIndex.value = widget.initialCardIndex;

        // 페이지 전환 후 상태 갱신
        setState(() {});
      } catch (e) {
        // 화면 전환 중 오류 발생 방지
        print('카드 전환 중 오류: $e');
      }
    }
  }

  @override
  void dispose() {
    // 리소스 해제
    try {
      cardController.dispose();
      currentCardIndex.dispose();
    } catch (e) {
      print('리소스 해제 중 오류: $e');
    }
    super.dispose();
  }

  // 카드 타입 (3개의 카드)
  final List<Map<String, dynamic>> cards = [
    {
      'type': 'progress',
      'title': '태현이의 아이폰을 위하여! (영어 단어 100개 암기)',
      'missionType': '학원 미션',
      'deadline': 'D-6',
      'description': '영어 단어 300개 외워오기 · 3월 30일까지',
      'amount': '300,000원',
    },
    {
      'type': 'school',
      'title': '태현이의 아이폰을 위하여!  (수학 5단원 문제집 풀기)',
      'missionType': '학원 미션',
      'deadline': 'D-4',
      'description': '수학 5단원 문제집 완료하기 · 3월 25일까지',
      'amount': '250,000원',
    },
    {
      'type': 'family',
      'title': '태현이의 아이폰을 위하여!  (가족 미션)',
      'missionType': '가족 미션',
      'deadline': 'D-3',
      'description': '이번 주 설거지 담당 · 내 친구 XX이 참여',
    },
  ];

  @override
  Widget build(BuildContext context) {
    super.build(context); // AutomaticKeepAliveClientMixin 사용 시 필요
    const double progressValue = 0.4;
    // 높이를 화면의 40%로 줄임
    final modalHeight = MediaQuery.of(context).size.height * 0.4;
    final screenWidth = MediaQuery.of(context).size.width;

    // 현재 카드 인덱스 확인 출력
    final int index = currentCardIndex.value;
    print('현재 카드 인덱스: $index - ${cards[index]['title']}');

    return AnimatedContainer(
      width: screenWidth,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      height: _isExpanded ? modalHeight : 50,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment(0.00, 0.50),
          end: Alignment(1.00, 0.50),
          colors: [Color(0xFFF0F2F7), Color(0xFFF2FFF3)],
        ),
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(16),
          bottom: Radius.zero,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 항상 보이는 헤더 부분 (접힌 상태에서 이것만 보임)
          SizedBox(
            height: 50, // 헤더의 고정 높이
            width: screenWidth,
            child: PageView.builder(
              controller: cardController,
              itemCount: cards.length,
              onPageChanged: (newIndex) {
                // 페이지 변경 시 인덱스 업데이트
                print('헤더 PageView 변경됨 - 인덱스: $newIndex');
                currentCardIndex.value = newIndex;
                // 외부로 변경된 인덱스 전달 (존재하는 경우)
                widget.onCardChanged?.call(newIndex);
                if (mounted) {
                  setState(() {
                    // 상태 갱신으로 강제 리빌드
                  });
                }
              },
              itemBuilder: (context, idx) {
                // 현재 인덱스에 해당하는 카드를 표시
                return InkWell(
                  onTap: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                      widget.onExpandChanged(_isExpanded);
                    });
                  },
                  child: Container(
                    width: screenWidth,
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(
                            cards[idx]['title'],
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF262626),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          width: 28,
                          height: 28,
                          decoration: const BoxDecoration(
                            color: Color(0xFF146AFF),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _isExpanded
                                ? Icons.keyboard_arrow_down
                                : Icons.keyboard_arrow_up,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // 확장된 내용 (접힌 상태에서는 표시 안됨)
          if (_isExpanded)
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: IndexedStack(
                      index: currentCardIndex.value,
                      children: List.generate(cards.length, (i) {
                        final card = cards[i];
                        final cardType = card['type'];

                        print('빌드 중인 카드: $i - $cardType - ${card['title']}');

                        if (cardType == 'progress') {
                          return _buildProgressCard(card, 0.6);
                        } else if (cardType == 'school') {
                          return _buildSchoolCard(card);
                        } else {
                          return _buildFamilyCard(card);
                        }
                      }),
                    ),
                  ),

                  // 페이지 인디케이터 (확장 상태에서만 표시)
                  Container(
                    height: 10,
                    padding: const EdgeInsets.only(bottom: 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        cards.length,
                        (i) => Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            color:
                                currentCardIndex.value == i
                                    ? const Color(0xFF3179FF)
                                    : Colors.grey.withOpacity(0.4),
                            shape: BoxShape.circle,
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
    );
  }

  Widget _buildProgressCard(Map<String, dynamic> card, double progressValue) {
    return SingleChildScrollView(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(0.00, 0.50),
            end: Alignment(1.00, 0.50),
            colors: [Color(0xFFF0F2F7), Color(0xFFF2FFF3)],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: ShapeDecoration(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                shadows: [
                  BoxShadow(
                    color: const Color(0x24000000),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 학원 미션 태그
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: ShapeDecoration(
                      color: const Color(0xFF5D9EFF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: Text(
                      card['missionType'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // 영어 단어 100개 암기 타이틀
                  Text(
                    card['title'],
                    style: const TextStyle(
                      color: Color(0xFF353535),
                      fontSize: 16,
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  // 설명 추가
                  const SizedBox(height: 8),
                  Text(
                    card['description'],
                    style: const TextStyle(
                      color: Color(0xFF666666),
                      fontSize: 12,
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w400,
                    ),
                  ),

                  // 라벨과 프로그레스바 영역
                  Container(
                    margin: const EdgeInsets.only(top: 20),
                    height: 40,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final barWidth = constraints.maxWidth;
                        // 60% 지점의 x 좌표 계산
                        final position60Percent = barWidth * 0.6;

                        return Stack(
                          clipBehavior: Clip.none,
                          children: [
                            // 배경바
                            Positioned(
                              top: 16,
                              left: 0,
                              child: Container(
                                width: barWidth,
                                height: 8,
                                decoration: ShapeDecoration(
                                  color: const Color(0xFFDDDDDD),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            ),

                            // 진행바
                            Positioned(
                              top: 16,
                              left: 0,
                              child: Container(
                                width: position60Percent,
                                height: 8,
                                decoration: ShapeDecoration(
                                  gradient: const LinearGradient(
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                    colors: [
                                      Color(0xFF5D9EFF),
                                      Color(0xFFF0F6FF),
                                    ],
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            ),

                            // 포인트들 (프로그레스바 위에 겹치도록)
                            for (int i = 0; i < 5; i++)
                              Positioned(
                                left:
                                    i == 0
                                        ? 0
                                        : i == 4
                                        ? barWidth - 24
                                        : barWidth * (i / 4.0) - 12,
                                top: 8,
                                child: Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color:
                                        i <= 2
                                            ? const Color(0xFF5D9EFF)
                                            : const Color(0xFFCCCCCC),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color(0xFFC2D6F3),
                                      width: 4,
                                    ),
                                  ),
                                  child: Center(
                                    child: Image.asset(
                                      'assets/images/flag.png',
                                      width: 12,
                                      height: 12,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),

                            // 60% 달성 중 표시 - 60% 지점 위에 정확히 배치
                            Positioned(
                              left: position60Percent - 35, // 정확히 60% 위치에 중앙 정렬
                              top: -20,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: ShapeDecoration(
                                  color: const Color(0xFFFFD27F),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: const Text(
                                  '60% 달성 중',
                                  style: TextStyle(
                                    color: Color(0xFF001F55),
                                    fontSize: 10,
                                    fontFamily: 'Pretendard',
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),

                            // 금액 표시 (우측 상단에 배치)
                            Positioned(
                              right: 0,
                              top: -20,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: ShapeDecoration(
                                  color: const Color(0xFFFFD27F),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: Text(
                                  card['amount'] ?? '200,000원',
                                  style: const TextStyle(
                                    color: Color(0xFF001F55),
                                    fontSize: 10,
                                    fontFamily: 'Pretendard',
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // 버튼
            InkWell(
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const UserMissionsScreen(),
                  ),
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: ShapeDecoration(
                  color: const Color(0xFF146AFF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  shadows: [
                    BoxShadow(
                      color: const Color(0x24000000),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text(
                      '참여 중인 모든 미션 보러가기',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white,
                      size: 10,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSchoolCard(Map<String, dynamic> card) {
    return SingleChildScrollView(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(0.00, 0.50),
            end: Alignment(1.00, 0.50),
            colors: [Color(0xFFF0F2F7), Color(0xFFF2FFF3)],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: ShapeDecoration(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                shadows: [
                  BoxShadow(
                    color: const Color(0x24000000),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 학원 미션 태그
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: ShapeDecoration(
                      color: const Color(0xFF5D9EFF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: Text(
                      card['missionType'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // 영어 단어 300개 외워오기 타이틀
                  Text(
                    card['title'],
                    style: const TextStyle(
                      color: Color(0xFF353535),
                      fontSize: 16,
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  // 설명 추가
                  const SizedBox(height: 8),
                  Text(
                    card['description'],
                    style: const TextStyle(
                      color: Color(0xFF666666),
                      fontSize: 12,
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w400,
                    ),
                  ),

                  // 라벨과 프로그레스바 영역
                  Container(
                    margin: const EdgeInsets.only(top: 20),
                    height: 40,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final barWidth = constraints.maxWidth;
                        // 45% 지점의 x 좌표 계산
                        final positionPercent = barWidth * 0.45;

                        return Stack(
                          clipBehavior: Clip.none,
                          children: [
                            // 배경바
                            Positioned(
                              top: 16,
                              left: 0,
                              child: Container(
                                width: barWidth,
                                height: 8,
                                decoration: ShapeDecoration(
                                  color: const Color(0xFFDDDDDD),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            ),

                            // 진행바
                            Positioned(
                              top: 16,
                              left: 0,
                              child: Container(
                                width: positionPercent,
                                height: 8,
                                decoration: ShapeDecoration(
                                  gradient: const LinearGradient(
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                    colors: [
                                      Color(0xFF5D9EFF),
                                      Color(0xFFF0F6FF),
                                    ],
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            ),

                            // 포인트들 (프로그레스바 위에 겹치도록)
                            for (int i = 0; i < 5; i++)
                              Positioned(
                                left:
                                    i == 0
                                        ? 0
                                        : i == 4
                                        ? barWidth - 24
                                        : barWidth * (i / 4.0) - 12,
                                top: 8,
                                child: Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color:
                                        i <= 1
                                            ? const Color(0xFF5D9EFF)
                                            : const Color(0xFFCCCCCC),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color(0xFFC2D6F3),
                                      width: 4,
                                    ),
                                  ),
                                  child: Center(
                                    child: Image.asset(
                                      'assets/images/flag.png',
                                      width: 12,
                                      height: 12,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),

                            // 45% 달성 중 표시
                            Positioned(
                              left: positionPercent - 35,
                              top: -20,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: ShapeDecoration(
                                  color: const Color(0xFFFFD27F),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: const Text(
                                  '45% 달성 중',
                                  style: TextStyle(
                                    color: Color(0xFF001F55),
                                    fontSize: 10,
                                    fontFamily: 'Pretendard',
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),

                            // 금액 표시 (우측 상단에 배치)
                            Positioned(
                              right: 0,
                              top: -20,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: ShapeDecoration(
                                  color: const Color(0xFFFFD27F),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: const Text(
                                  '250,000원',
                                  style: TextStyle(
                                    color: Color(0xFF001F55),
                                    fontSize: 10,
                                    fontFamily: 'Pretendard',
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // 버튼
            InkWell(
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const UserMissionsScreen(),
                  ),
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: ShapeDecoration(
                  color: const Color(0xFF146AFF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  shadows: [
                    BoxShadow(
                      color: const Color(0x24000000),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text(
                      '참여 가능한 모든 미션 보러가기',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white,
                      size: 10,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFamilyCard(Map<String, dynamic> card) {
    return SingleChildScrollView(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(0.00, 0.50),
            end: Alignment(1.00, 0.50),
            colors: [Color(0xFFF0F2F7), Color(0xFFF2FFF3)],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: ShapeDecoration(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                shadows: [
                  BoxShadow(
                    color: const Color(0x24000000),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 가족 미션 태그
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: ShapeDecoration(
                      color: const Color(0xFF89DA8D), // 가족 미션은 초록색 계열로 변경
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: Text(
                      card['missionType'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // 가족 미션 타이틀
                  Text(
                    card['title'],
                    style: const TextStyle(
                      color: Color(0xFF353535),
                      fontSize: 16,
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  // 설명 추가
                  const SizedBox(height: 8),
                  Text(
                    card['description'],
                    style: const TextStyle(
                      color: Color(0xFF666666),
                      fontSize: 12,
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w400,
                    ),
                  ),

                  // 라벨과 프로그레스바 영역
                  Container(
                    margin: const EdgeInsets.only(top: 20),
                    height: 40,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final barWidth = constraints.maxWidth;
                        // 25% 지점의 x 좌표 계산
                        final positionPercent = barWidth * 0.25;

                        return Stack(
                          clipBehavior: Clip.none,
                          children: [
                            // 배경바
                            Positioned(
                              top: 16,
                              left: 0,
                              child: Container(
                                width: barWidth,
                                height: 8,
                                decoration: ShapeDecoration(
                                  color: const Color(0xFFDDDDDD),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            ),

                            // 진행바
                            Positioned(
                              top: 16,
                              left: 0,
                              child: Container(
                                width: positionPercent,
                                height: 8,
                                decoration: ShapeDecoration(
                                  gradient: const LinearGradient(
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                    colors: [
                                      Color(0xFF89DA8D), // 가족 미션은 초록색 계열로 변경
                                      Color(0xFFE7F9E8),
                                    ],
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            ),

                            // 포인트들 (프로그레스바 위에 겹치도록)
                            for (int i = 0; i < 5; i++)
                              Positioned(
                                left:
                                    i == 0
                                        ? 0
                                        : i == 4
                                        ? barWidth - 24
                                        : barWidth * (i / 4.0) - 12,
                                top: 8,
                                child: Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color:
                                        i <= 0
                                            ? const Color(
                                              0xFF89DA8D,
                                            ) // 가족 미션은 초록색 계열로 변경
                                            : const Color(0xFFCCCCCC),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color(
                                        0xFFCBEECD,
                                      ), // 가족 미션은 초록색 계열로 변경
                                      width: 4,
                                    ),
                                  ),
                                  child: Center(
                                    child: Image.asset(
                                      'assets/images/flag.png',
                                      width: 12,
                                      height: 12,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),

                            // 25% 달성 중 표시
                            Positioned(
                              left: positionPercent - 35,
                              top: -20,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: ShapeDecoration(
                                  color: const Color(
                                    0xFFB8F4BC,
                                  ), // 가족 미션은 초록색 계열로 변경
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: const Text(
                                  '25% 달성 중',
                                  style: TextStyle(
                                    color: Color(
                                      0xFF00550A,
                                    ), // 가족 미션은 초록색 계열로 변경
                                    fontSize: 10,
                                    fontFamily: 'Pretendard',
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),

                            // 금액 표시 (우측 상단에 배치)
                            Positioned(
                              right: 0,
                              top: -20,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: ShapeDecoration(
                                  color: const Color(
                                    0xFFB8F4BC,
                                  ), // 가족 미션은 초록색 계열로 변경
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: const Text(
                                  '50,000원',
                                  style: TextStyle(
                                    color: Color(
                                      0xFF00550A,
                                    ), // 가족 미션은 초록색 계열로 변경
                                    fontSize: 10,
                                    fontFamily: 'Pretendard',
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // 버튼
            InkWell(
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const UserMissionsScreen(),
                  ),
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: ShapeDecoration(
                  color: const Color(0xFF89DA8D), // 가족 미션은 초록색 계열로 변경
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  shadows: [
                    BoxShadow(
                      color: const Color(0x24000000),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text(
                      '참여 가능한 모든 미션 보러가기',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white,
                      size: 10,
                    ),
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
