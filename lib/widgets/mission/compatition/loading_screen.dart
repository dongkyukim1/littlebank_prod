import 'package:flutter/material.dart';
import 'dart:async';

/// 친구 찾기 로딩 화면
class LoadingScreen extends StatefulWidget {
  final int targetAmount;
  final Function(Map<String, dynamic>) onLoadingComplete;

  const LoadingScreen({
    super.key,
    required this.targetAmount,
    required this.onLoadingComplete,
  });

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startLoading();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startLoading() {
    // 3초 후 로딩 완료 (실제로는 API 호출 결과를 기다림)
    _timer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        // 더미 데이터로 완료 처리 (실제로는 API 응답 데이터)
        final mockData = {
          'userId': 12345,
          'name': '진리틀',
          'targetAmount': 260000,
          'entireCompleted': 18,
          'profileImageUrl': 'https://placehold.co/40x40',
        };
        widget.onLoadingComplete(mockData);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // 화면 크기에 따른 반응형 디자인
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFF3A88F4),
      body: SafeArea(
        child: Container(
          width: screenWidth,
          height: screenHeight,
          child: Stack(
            children: [
              // 상단 상태바 영역
              Positioned(
                left: 0,
                top: 0,
                child: Container(
                  width: screenWidth,
                  height: 44,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 19, top: 17),
                    child: Text(
                      '9:41',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 15,
                        fontFamily: 'Pretendard-SemiBold',
                        height: 1.33,
                        letterSpacing: -0.50,
                      ),
                    ),
                  ),
                ),
              ),
              
              // 메인 콘텐츠 - 가운데에 GIF만 표시
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // GIF 이미지만 간단하게 표시
                    Image.asset(
                      'assets/icons/Icon/mission/loading.gif',
                      width: screenWidth > 600 ? 150 : 120,
                      height: screenWidth > 600 ? 150 : 120,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        // GIF 로딩 실패 시 기본 로딩 인디케이터 표시
                        return SizedBox(
                          width: screenWidth > 600 ? 150 : 120,
                          height: screenWidth > 600 ? 150 : 120,
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          ),
                        );
                      },
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // 텍스트 영역
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          // 제목
                          Text(
                            '지금 친구를 찾고 있어요',
                            style: TextStyle(
                              color: const Color(0xFF202020),
                              fontSize: screenWidth > 600 ? 26 : 22,
                              fontFamily: 'Pretendard-Bold',
                              letterSpacing: -0.88,
                            ),
                          ),
                          
                          const SizedBox(height: 12),
                          
                          // 부제목
                          Text(
                            '나와 같은 목표를 가진 친구를 찾는 중이예요',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: screenWidth > 600 ? 18 : 16,
                              fontFamily: 'Pretendard-Light',
                              letterSpacing: -0.32,
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
      ),
    );
  }
} 