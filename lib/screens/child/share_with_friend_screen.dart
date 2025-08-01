import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:async';
import 'home_screen.dart';
import '../../services/kakao_share_service.dart';
import '../../services/deep_link_service.dart';

class ShareWithFriendScreen extends StatefulWidget {
  const ShareWithFriendScreen({super.key});

  @override
  State<ShareWithFriendScreen> createState() => _ShareWithFriendScreenState();
}

class _ShareWithFriendScreenState extends State<ShareWithFriendScreen>
    with SingleTickerProviderStateMixin {
  // 슬라이드 애니메이션을 위한 컨트롤러
  AnimationController? _slideController;
  Animation<Offset>? _slideAnimation;

  Timer? _autoSlideTimer;
  double _translateX = 0.0; // Row 이동 거리

  final List<String> _imageList = [
    'assets/icons/mission_share.png',
    'assets/icons/mission_share_2.png',
  ];

  // 초대 코드 (실제로는 서버에서 생성하거나 사용자 ID 기반으로 생성)
  final String _inviteCode = 'littlebank';
  bool _isSharing = false;

  @override
  void initState() {
    super.initState();
    _setupAnimation();

    _startAutoSlide();
  }

  // 애니메이션 설정 분리
  void _setupAnimation() {
    try {
      _slideController = AnimationController(
        duration: const Duration(seconds: 10), // 매우 느린 애니메이션 (20초)
        vsync: this,
      );

      // 좌우로 매우 천천히 슬라이드하는 애니메이션
      _slideAnimation = Tween<Offset>(
        begin: const Offset(0, 25) / 100, // 시작 위치
        end: const Offset(-60, 25) / 100, // 종료 위치 (작은 범위로 줄임)
      ).animate(
        CurvedAnimation(
          parent: _slideController!,
          curve: Curves.linear, // 일정한 속도로 움직이게
        ),
      );

      // 애니메이션 시작 - 더 느리게
      _slideController!.forward();
      _slideController!.addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _slideController!.reverse();
        } else if (status == AnimationStatus.dismissed) {
          _slideController!.forward();
        }
      });
    } catch (e) {
      print('애니메이션 설정 오류: $e');
    }
  }

  // 자동 슬라이드 시작
  void _startAutoSlide() {
    _autoSlideTimer = Timer.periodic(const Duration(milliseconds: 20), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _translateX += 1.0; // 이동 속도 (픽셀 단위)

        double imageWidth =
            MediaQuery.of(context).size.width * 4.0; // 이미지 너비를 화면 너비의 4.0배로 조정
        double spacing = 20.0;
        // 하나의 완전한 슬라이드 사이클 너비: (첫 번째 이미지 + 간격) + (두 번째 이미지 + 간격)
        double cycleWidth =
            (imageWidth + spacing) *
            _imageList.length; // 이미지 개수(_imageList.length)는 2

        if (_translateX >= cycleWidth) {
          _translateX -= cycleWidth; // 한 사이클만큼 이동했으면 그만큼 빼서 처음처럼 보이게 함
        }
      });
    });
  }

  // 초대 메시지 공유 함수
  Future<void> _shareInviteMessage() async {
    if (_isSharing) return;

    setState(() {
      _isSharing = true;
    });

    try {
      // 공유 방식 선택 다이얼로그 표시
      await _showShareOptionsDialog();
    } catch (e) {
      print('공유 오류: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('공유 중 오류가 발생했습니다.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSharing = false;
        });
      }
    }
  }

  // 공유 방식 선택 다이얼로그
  Future<void> _showShareOptionsDialog() async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            '친구에게 공유하기',
            style: TextStyle(
              fontFamily: 'Pretendard-Bold',
              fontSize: 18,
              color: Color(0xFF202020),
            ),
          ),
          content: const Text(
            '어떤 방식으로 친구를 초대하시겠어요?',
            style: TextStyle(
              fontFamily: 'Pretendard-Regular',
              fontSize: 14,
              color: Color(0xFF666666),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                '취소',
                style: TextStyle(
                  fontFamily: 'Pretendard-Medium',
                  color: Colors.grey,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _shareViaKakaoTalk();
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/icons/Icon/kakao/kakao_login.png',
                    width: 20,
                    height: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    '카카오톡',
                    style: TextStyle(
                      fontFamily: 'Pretendard-Medium',
                      color: Color(0xFFFFE812),
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _shareViaSystem();
              },
              child: const Text(
                '다른 앱',
                style: TextStyle(
                  fontFamily: 'Pretendard-Medium',
                  color: Colors.blue,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // 카카오톡으로 공유
  Future<void> _shareViaKakaoTalk() async {
    try {
      await KakaoShareService.shareLittleBankInvite(
        inviteCode: _inviteCode,
        context: context,
      );
    } catch (e) {
      print('카카오톡 공유 오류: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('카카오톡 공유에 실패했습니다.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 시스템 공유
  Future<void> _shareViaSystem() async {
    try {
      final String message = '''
🏦✨ 리틀뱅크에서 함께 공부해요! ✨

친구야, 나와 함께 용돈 관리하고 
성적도 함께 올려보자! 📈

🎯 미션 완료하고 용돈 받기
📊 랭킹에서 친구들과 경쟁하기  
📝 피드에서 학습 기록 공유하기

📱 앱 다운로드: https://play.google.com/store/apps/details?id=com.worldcoin.pocketmoneymanagementz
🔑 초대 코드: $_inviteCode

#리틀뱅크 #경제교육 #용돈관리 #친구초대
      ''';

      // share_plus 패키지를 사용한 시스템 공유
      await Share.share(message, subject: '🏦 리틀뱅크 친구 초대');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('리틀뱅크 초대 메시지를 공유했습니다! 🎉'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('시스템 공유 오류: $e');
    }
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _slideController?.dispose(); // 기존 애니메이션 컨트롤러 해제
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Image.asset('assets/icons/my/뒤로가기.png', width: 20, height: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '친구에게 공유하기',
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontFamily: 'Pretendard-Bold',
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              Colors.white.withOpacity(0.8),
              Color(0xFF81FFD2).withOpacity(0.3),
            ],
          ),
        ),
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
                    const SizedBox(height: 24), // 12에서 24로 두 배 늘림
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
                        child: const Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              '01',
                              style: TextStyle(
                                color: Color(0xFF001F55),
                                fontSize: 14,
                                fontFamily: 'Pretendard-Bold',
                                letterSpacing: -0.32,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24), // 8에서 16으로 두 배 늘림
                    const Center(
                      child: Text(
                        '리틀뱅크에서 이렇게 다양한 경험이 가능해요!',
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
                          '미션, 챌린지를 통해 부모님께 보상받고\n피드에서 기록 공유를 통해\n학습에 대한 동기부여를 받을 수 있어요!',
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
                    // 동기부여 텍스트와 슬라이더 간격 최소화 - 네거티브 마진 사용
                    const SizedBox(height: 4), // 음수값을 양수로 변경
                  ],
                ),
              ),

              // 미션 카드 이미지 - 전체 화면 너비로 표시
              Container(
                height: 280,
                width: double.infinity, // 화면 전체 너비 사용
                margin: const EdgeInsets.symmetric(vertical: 20), // 위아래 간격 추가
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: OverflowBox(
                    // 자식의 크기가 부모보다 커도 보이도록 함
                    maxWidth: double.infinity,
                    alignment: Alignment.topLeft,
                    child: Transform.translate(
                      offset: Offset(-_translateX, 0),
                      child: Row(
                        children: [
                          // _imageList에 있는 두 이미지를 반복적으로 표시하여 무한 슬라이드 효과 구현
                          ...List.generate(_imageList.length * 2, (index) {
                            // _imageList의 2배만큼 반복
                            return Row(
                              children: [
                                Image.asset(
                                  _imageList[index %
                                      _imageList.length], // 이미지 리스트를 순환하며 사용
                                  width:
                                      screenWidth *
                                      2.5, // 각 이미지의 너비를 화면 너비의 3.2배로 조정 (4개 카드 표시)
                                  height: 280,
                                  fit: BoxFit.fitWidth, // 이미지가 잘리지 않고 너비에 맞춰지도록
                                ),
                                SizedBox(width: 20), // 이미지 간 간격
                              ],
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // 슬라이더와 02 섹션 사이 간격 최소화
              Padding(
                padding: const EdgeInsets.fromLTRB(20.0, 0.0, 20.0, 12.0),
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
                            fontSize: 14,
                            fontFamily: 'Pretendard-Bold',
                            letterSpacing: -0.32,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Center(
                      child: Text(
                        '친구와 함께 더 즐거운 여정을 시작해 보세요!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF202020),
                          fontSize: 16,
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
                          '피드 안 랭킹 카테고리에서는\n내 친구들뿐만 아니라 다른 학생들의 기록까지\n탐색하고 경쟁할 수 있어요',
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

                    // 초록색 버튼 추가 (랭킹)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 180,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 8,
                          ),
                          decoration: ShapeDecoration(
                            color: const Color(0xFF11CB86),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(48),
                            ),
                          ),
                          child: const Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '랭킹을 통한 친구와의 경쟁',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontFamily: 'Pretendard-Medium',
                                  letterSpacing: -0.28,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        // 랭킹 이미지 추가
                        Container(
                          width: double.infinity,
                          clipBehavior: Clip.none,
                          decoration: BoxDecoration(),
                          child:
                              _slideAnimation != null
                                  ? SlideTransition(
                                    position: _slideAnimation!,
                                    child: Transform.scale(
                                      scale: 1.4, // 정확히 2배 크기로
                                      alignment: Alignment.centerLeft,
                                      child: Image.asset(
                                        'assets/icons/ranking_share.png',
                                        width: screenWidth - 40,
                                        fit: BoxFit.fitWidth,
                                      ),
                                    ),
                                  )
                                  : Transform.translate(
                                    offset: Offset(-20, 25),
                                    child: Transform.scale(
                                      scale: 1.4,
                                      alignment: Alignment.centerLeft,
                                      child: Image.asset(
                                        'assets/icons/ranking_share.png',
                                        width: screenWidth - 40,
                                        fit: BoxFit.fitWidth,
                                      ),
                                    ),
                                  ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 90),

                    // 초록색 버튼 추가 (피드)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 180,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 8,
                          ),
                          decoration: ShapeDecoration(
                            color: const Color(0xFF11CB86),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(48),
                            ),
                          ),
                          child: const Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '피드를 통한 학습 정보 공유',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontFamily: 'Pretendard-Medium',
                                  letterSpacing: -0.28,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        // 피드 이미지 추가
                        Image.asset(
                          'assets/icons/feed_share.png',
                          width: screenWidth - 40,
                          fit: BoxFit.contain,
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),

                    // 03 섹션 추가
                    SizedBox(
                      width: double.infinity,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // 03 원형 버튼
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 8,
                            ),
                            decoration: ShapeDecoration(
                              color: const Color(0xFFEFF2F6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(48),
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: const [
                                Text(
                                  '03',
                                  style: TextStyle(
                                    color: Color(0xFF001F55),
                                    fontSize: 16,
                                    fontFamily: 'Pretendard-Bold',
                                    letterSpacing: -0.32,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // 공유 전 확인 섹션
                          SizedBox(
                            width: double.infinity,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // 제목
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: const [
                                      Text(
                                        '공유 전에 한 번 더 확인해 주세요!',
                                        style: TextStyle(
                                          color: Color(0xFF202020),
                                          fontSize: 16,
                                          fontFamily: 'Pretendard-Bold',
                                          letterSpacing: -0.80,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 12),

                                // 확인 단계 목록
                                SizedBox(
                                  width: screenWidth - 40,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // 1단계
                                      SizedBox(
                                        width: double.infinity,
                                        height: 48,
                                        child: Stack(
                                          children: const [
                                            Positioned(
                                              left: 0,
                                              top: 0,
                                              child: Text(
                                                '1',
                                                style: TextStyle(
                                                  color: Color(0xFF8490A3),
                                                  fontSize: 16,
                                                  fontFamily: 'Pretendard-Bold',
                                                  letterSpacing: -0.72,
                                                ),
                                              ),
                                            ),
                                            Positioned(
                                              left: 25,
                                              top: 5,
                                              child: SizedBox(
                                                width: 280,
                                                child: Text(
                                                  '리틀뱅크에서 친구와 함께 즐길 수 있는 콘텐츠를 끝까지 내리고 열심히 확인한다.',
                                                  style: TextStyle(
                                                    color: Color(0xFF666666),
                                                    fontSize: 12,
                                                    fontFamily:
                                                        'Pretendard-Light',
                                                    height: 1.50,
                                                    letterSpacing: -0.64,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      const SizedBox(height: 12),

                                      // 2단계
                                      SizedBox(
                                        width: double.infinity,
                                        height: 24,
                                        child: Stack(
                                          children: const [
                                            Positioned(
                                              left: 0,
                                              top: 1,
                                              child: Text(
                                                '2',
                                                style: TextStyle(
                                                  color: Color(0xFF8490A3),
                                                  fontSize: 16,
                                                  fontFamily: 'Pretendard-Bold',
                                                  letterSpacing: -0.72,
                                                ),
                                              ),
                                            ),
                                            Positioned(
                                              left: 27,
                                              top: 5,
                                              child: SizedBox(
                                                width: 280,
                                                child: Text(
                                                  '하단의 친구에게 소문내기 버튼을 누른다.',
                                                  style: TextStyle(
                                                    color: Color(0xFF666666),
                                                    fontSize: 12,
                                                    fontFamily:
                                                        'Pretendard-Light',
                                                    height: 1.50,
                                                    letterSpacing: -0.64,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      const SizedBox(height: 12),

                                      // 3단계
                                      SizedBox(
                                        width: double.infinity,
                                        height: 48,
                                        child: Stack(
                                          children: const [
                                            Positioned(
                                              left: 0,
                                              top: 0,
                                              child: Text(
                                                '3',
                                                style: TextStyle(
                                                  color: Color(0xFF8490A3),
                                                  fontSize: 16,
                                                  fontFamily: 'Pretendard-Bold',
                                                  letterSpacing: -0.72,
                                                ),
                                              ),
                                            ),
                                            Positioned(
                                              left: 25,
                                              top: 5,
                                              child: SizedBox(
                                                width: 280,
                                                child: Text(
                                                  '나머지는 리틀뱅크가 할게요! 문자로 앱 다운로드 링크를 보내드립니다.',
                                                  style: TextStyle(
                                                    color: Color(0xFF666666),
                                                    fontSize: 12,
                                                    fontFamily:
                                                        'Pretendard-Light',
                                                    height: 1.50,
                                                    letterSpacing: -0.64,
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

                                const SizedBox(height: 32),

                                // 초대하기 이미지 추가
                                Container(
                                  width: double.infinity,
                                  // alignment: Alignment.center, // 중앙 정렬 대신 패딩으로 조정
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                      left: 50.0,
                                    ), //
                                    child: Image.asset(
                                      'assets/icons/invite_share.png',
                                      width: screenWidth * 0.8, // 화면의 80%로 조정
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 60), // 간격 2배로 늘림
                                // 초대 코드 제목 - 왼쪽 정렬
                                Container(
                                  width: screenWidth - 40,
                                  padding: const EdgeInsets.only(left: 0),
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    '내 초대 코드',
                                    style: TextStyle(
                                      color: const Color(0xFF202020),
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
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  decoration: ShapeDecoration(
                                    color: const Color(0xFF146AFF),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        _inviteCode.toUpperCase(),
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontFamily: 'Pretendard-Bold',
                                          letterSpacing: -0.80,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      GestureDetector(
                                        onTap: () async {
                                          // 클립보드에 초대 코드 복사
                                          await Clipboard.setData(
                                            ClipboardData(text: _inviteCode),
                                          );
                                          if (mounted) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  '초대 코드가 복사되었습니다.',
                                                ),
                                                backgroundColor: Colors.green,
                                              ),
                                            );
                                          }
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
      bottomNavigationBar: Container(
        width: screenWidth,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
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
        child: GestureDetector(
          onTap: _isSharing ? null : _shareInviteMessage,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: _isSharing ? Colors.grey : Colors.black,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (_isSharing)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                else
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        '친구에게 소문내기',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontFamily: 'Pretendard-Bold',
                          letterSpacing: -0.72,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 10),
                SizedBox(
                  width: screenWidth - 40,
                  child: Text(
                    _isSharing ? '공유 중...' : '함께 경쟁하고 발전할 수 있어요!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: const Color(0xFFCCCCCC),
                      fontSize: 12,
                      fontFamily: 'Pretendard-Light',
                      letterSpacing: -0.24,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
