import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'dart:math';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../models/feed_data.dart';
import '../../../services/auth_service.dart';
import '../../../services/kakao_share_service.dart';

class FeedShareScreen extends StatefulWidget {
  final FeedItem feedItem;

  const FeedShareScreen({
    super.key,
    required this.feedItem,
  });

  @override
  State<FeedShareScreen> createState() => _FeedShareScreenState();
}

class _FeedShareScreenState extends State<FeedShareScreen> {
  int _selectedCardIndex = 0; // 선택된 공유 카드 인덱스 (0: card1, 1: card2)
  final GlobalKey _repaintBoundaryKey = GlobalKey(); // 스크린샷 캡처용 키

  @override
  void initState() {
    super.initState();
    // 랜덤으로 카드 선택 (0 또는 1)
    _selectedCardIndex = Random().nextInt(2);
  }

  // 피드 딥링크 URL 생성
  String _generateFeedUrl() {
    // 실제 앱의 딥링크 스키마에 맞게 수정 필요
    // 예: littlebank://feed/12345
    return 'http://3.34.52.239:8080/feed/${widget.feedItem.feedId}';
  }

  @override
  Widget build(BuildContext context) {
    // 화면 크기 정보
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    // 배경 이미지 선택 (첫 번째 이미지 우선, 없으면 기본 배경)
    final backgroundImageUrl = widget.feedItem.imageUrls.isNotEmpty 
        ? widget.feedItem.imageUrls[0] 
        : null;

    return Scaffold(
      body: GestureDetector(
        onTap: () => Navigator.of(context).pop(), // 화면 터치 시 뒤로가기
        child: RepaintBoundary(
          key: _repaintBoundaryKey,
          child: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: backgroundImageUrl != null
                ? BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage(backgroundImageUrl),
                      fit: BoxFit.cover,
                    ),
                  )
                : BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/icons/Icon/feed/default.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
            child: Stack(
              children: [
                // 블러 오버레이
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      color: Colors.black.withOpacity(0.3),
                    ),
                  ),
                ),
                
                // 메인 컨텐츠 (상단부터 시작)
                _buildShareCardPreview(),
                
                // QR 코드 플로팅 위젯
                _buildFloatingQRCode(screenWidth, screenHeight),
                
                // 피드 제목 플로팅 위젯
                _buildFloatingFeedTitle(screenWidth, screenHeight),
                
                // 피드 내용 플로팅 위젯
                _buildFloatingFeedContent(screenWidth, screenHeight),
                
                // 작성자 이름 플로팅 위젯
                _buildFloatingAuthorName(screenWidth, screenHeight),
                
                // 공유 아이콘 플로팅 위젯
                _buildFloatingShareIcon(screenWidth, screenHeight),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 공유 카드 미리보기 위젯
  Widget _buildShareCardPreview() {
    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        width: double.infinity, // 화면 전체 너비 사용
        padding: const EdgeInsets.only(bottom: 100), // 아래쪽에 80px 여백 추가
        child: Image.asset(
          _selectedCardIndex == 0 
              ? 'assets/icons/Icon/feed/share_card1.png'
              : 'assets/icons/Icon/feed/share_card2.png',
          fit: BoxFit.fitWidth, // 너비에 맞춰서 비율 유지
        ),
      ),
    );
  }

  // 플로팅 QR 코드 위젯
  Widget _buildFloatingQRCode(double screenWidth, double screenHeight) {
    // 화면 크기에 비례하여 위치와 크기 계산
    final qrPositionX = screenWidth * 0.10; // 화면 너비의 10% 위치
    final qrPositionY = screenHeight * 0.70; // 화면 높이의 75% 위치
    final qrSize = screenWidth * 0.18; // 화면 너비의 15% 크기
    
    return Positioned(
      left: qrPositionX,
      top: qrPositionY,
      child: QrImageView(
        data: _generateFeedUrl(),
        version: QrVersions.auto,
        size: qrSize,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        errorCorrectionLevel: QrErrorCorrectLevel.M,
      ),
    );
  }

  // 피드 제목 플로팅 위젯
  Widget _buildFloatingFeedTitle(double screenWidth, double screenHeight) {
    // 화면 크기에 비례하여 위치와 크기 계산
    final titlePositionX = screenWidth * 0.1; // 화면 너비의 10% 위치
    final titlePositionY = screenHeight * 0.45; // 화면 높이의 48% 위치
    final titleWidth = screenWidth * 0.8; // 화면 너비의 80%
    final titleFontSize = screenWidth * 0.06 + 8; // 화면 너비의 6%
    
    return Positioned(
      left: titlePositionX,
      top: titlePositionY,
      child: Container(
        width: titleWidth,
        child: Text(
          widget.feedItem.title,
          style: TextStyle(
            color: Colors.white,
            fontSize: titleFontSize,
            fontFamily: 'Pretendard-SemiBold',
            letterSpacing: -0.24,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  // 피드 내용 플로팅 위젯
  Widget _buildFloatingFeedContent(double screenWidth, double screenHeight) {
    // 피드 내용이 없으면 빈 Container 반환
    if (widget.feedItem.content == null || widget.feedItem.content!.isEmpty) {
      return Container();
    }
    
    // 화면 크기에 비례하여 위치와 크기 계산
    final contentPositionX = screenWidth * 0.1; // 화면 너비의 10% 위치
    final contentPositionY = screenHeight * 0.52; // 화면 높이의 57% 위치
    final contentWidth = screenWidth * 0.8; // 화면 너비의 80%
    final contentFontSize = screenWidth * 0.03; // 화면 너비의 3%
    
    return Positioned(
      left: contentPositionX,
      top: contentPositionY,
      child: Container(
        width: contentWidth,
        child: Text(
          widget.feedItem.content!,
          style: TextStyle(
            color: Colors.white,
            fontSize: contentFontSize,
            fontFamily: 'Pretendard-Thin',
            letterSpacing: -0.12,
          ),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  // 작성자 이름 플로팅 위젯
  Widget _buildFloatingAuthorName(double screenWidth, double screenHeight) {
    // 화면 크기에 비례하여 위치와 크기 계산
    final authorPositionX = screenWidth * 0.1; // 화면 너비의 10% 위치
    final authorPositionY = screenHeight * 0.59; // 화면 높이의 63% 위치
    final authorFontSize = screenWidth * 0.11 + 8; // 화면 너비의 11% + 2px
    
    return Positioned(
      left: authorPositionX,
      top: authorPositionY,
      child: Stack(
        children: [
          // 검은색 테두리 (뒤쪽)
          Text(
            widget.feedItem.writerName ?? 'pretend-boal',
            style: TextStyle(
              fontSize: authorFontSize,
              fontFamily: 'Pretendard-Medium',
              letterSpacing: -0.24,
              foreground: Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = 2
                ..color = Colors.black,
            ),
          ),
          // 흰색 글씨 (앞쪽)
          Text(
            widget.feedItem.writerName ?? 'pretend-boal',
            style: TextStyle(
              color: Colors.white,
              fontSize: authorFontSize,
              fontFamily: 'Pretendard-Medium',
              letterSpacing: -0.24,
            ),
          ),
        ],
      ),
    );
  }

  // 공유 아이콘 플로팅 위젯
  Widget _buildFloatingShareIcon(double screenWidth, double screenHeight) {
    return Positioned(
      left: (screenWidth / 2) - 25, // 화면 중앙에서 아이콘 크기의 절반만큼 왼쪽으로
      bottom: 10, // 화면 아래에서 150px 위
      child: GestureDetector(
        onTap: () => _shareScreenshot(),
        child: Image.asset(
          'assets/icons/Icon/feed/share_phone.png',
          width: 70,
          height: 70,
        ),
      ),
    );
  }

  // 스크린샷 캡처 및 공유 기능
  Future<void> _shareScreenshot() async {
    try {
      print('🖼️ 피드 스크린샷 공유 시작');
      
      // 스크린샷 캡처 및 카카오톡 공유
      final success = await KakaoShareService.shareFeedScreenshot(
        repaintBoundaryKey: _repaintBoundaryKey,
        feedTitle: widget.feedItem.title,
        feedUrl: _generateFeedUrl(),
        context: context,
      );
      
      if (success) {
        print('✅ 피드 스크린샷 공유 성공');
      } else {
        print('❌ 피드 스크린샷 공유 실패');
      }
    } catch (e) {
      print('❌ 피드 스크린샷 공유 오류: $e');
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('공유 중 오류가 발생했습니다.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

} 