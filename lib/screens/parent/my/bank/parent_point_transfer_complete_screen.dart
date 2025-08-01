import 'package:flutter/material.dart';
import '../../../../widgets/parent/bottom_navigation_bar.dart';
import '../my_page_screen.dart'; // 마이페이지 import 추가
import '../../../../services/payment_service.dart';
import '../../../../services/auth_service.dart';

class ParentPointTransferCompleteScreen extends StatelessWidget {
  final String receiverName;
  final String receiverPhone;
  final String amount;
  final int remainingPoints;

  const ParentPointTransferCompleteScreen({
    super.key,
    required this.receiverName,
    required this.receiverPhone,
    required this.amount,
    required this.remainingPoints,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: null,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // 상단 여백 추가
              SizedBox(height: 15),
              
              // 상단 이미지와 텍스트 영역
              SizedBox(
                width: screenWidth,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 이미지 영역
                    Container(
                      width: 140,
                      height: 150,
                      margin: EdgeInsets.only(top: 30, bottom: 25),
                      child: Icon(
                        Icons.check_circle,
                        size: 120,
                        color: const Color(0xFF5D9DFF),
                      ),
                    ),

                    // 텍스트 영역
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                '$receiverName님에게',
                                style: TextStyle(
                                  color: const Color(0xFF202020),
                                  fontSize: 13,
                                  fontFamily: 'Pretendard-Bold',
                                  letterSpacing: -0.5,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                '$amount포인트를 보냈어요!',
                                style: TextStyle(
                                  color: const Color(0xFF146AFF),
                                  fontSize: 18,
                                  fontFamily: 'Pretendard-Bold',
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 6),
                          Text(
                            '포인트를 보넀습니다!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: const Color(0xFF8490A3),
                              fontSize: 12,
                              fontFamily: 'Pretendard-Light',
                              letterSpacing: -0.24,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 40),

              // 포인트 전송 정보 영역
              Container(
                width: screenWidth * 0.9,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: ShapeDecoration(
                  color: const Color(0xFFEFF2F6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('받는 사람', receiverName),
                    SizedBox(height: 8),
                    _buildInfoRow('전화번호', receiverPhone),
                    SizedBox(height: 8),
                    _buildInfoRow('보낸 포인트', '${amount}원'),
                    SizedBox(height: 8),
                    _buildInfoRow(
                      '남은 내 포인트',
                      '${_formatCurrency(remainingPoints)}원',
                    ),
                  ],
                ),
              ),

              SizedBox(height: 20),

              // 확인 버튼
              SizedBox(
                width: screenWidth * 0.9,
                child: ElevatedButton(
                  onPressed: () async {
                    // 포인트 전송 완료 후 마이페이지로 이동
                    print('✅ 포인트 전송 완료, 마이페이지로 이동');
                    
                    // 포인트 정보 강제 새로고침 (여러 번 시도)
                    try {
                      print('💫 포인트 새로고침 시작 (1차)');
                      final userInfo1 = await AuthService.getUserInfo();
                      final points1 = userInfo1['point'] is int 
                          ? userInfo1['point'] 
                          : int.tryParse(userInfo1['point'].toString()) ?? 0;
                      
                      await Future.delayed(Duration(milliseconds: 500));
                      print('💫 포인트 새로고침 시작 (2차)');
                      final userInfo2 = await AuthService.getUserInfo();
                      final points2 = userInfo2['point'] is int 
                          ? userInfo2['point'] 
                          : int.tryParse(userInfo2['point'].toString()) ?? 0;
                      
                      await Future.delayed(Duration(milliseconds: 300));
                      print('💫 포인트 새로고침 시작 (3차)');
                      final userInfo3 = await AuthService.getUserInfo();
                      final points3 = userInfo3['point'] is int 
                          ? userInfo3['point'] 
                          : int.tryParse(userInfo3['point'].toString()) ?? 0;
                    } catch (e) {
                      print('❌ 포인트 새로고침 중 오류: $e');
                    }
                    
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ParentMyPageScreen(),
                      ),
                      (route) => false, // 모든 이전 화면 제거
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3A88F4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    '확인',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontFamily: 'Pretendard-Light',
                      letterSpacing: -0.28,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const ParentBottomNavigationBar(selectedIndex: 4),
    );
  }

  // 정보 행 위젯 생성 함수
  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: TextStyle(
              color: const Color(0xFF999999),
              fontSize: 12,
              fontFamily: 'Pretendard-Light',
              letterSpacing: -0.28,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: const Color(0xFF666666),
            fontSize: 12,
            fontFamily:
                label == '남은 내 포인트' || label == '보낸 포인트'
                    ? 'Pretendard-Medium'
                    : 'Pretendard-Light',
            letterSpacing: -0.28,
          ),
        ),
      ],
    );
  }

  // 금액 포맷 함수
  String _formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]},',
    );
  }
} 