import 'package:flutter/material.dart';
import '../../../../widgets/parent/bottom_navigation_bar.dart';
import 'package:intl/intl.dart';
import '../../../../services/auth_service.dart';
import '../../../../services/payment_service.dart';

class ParentChargeCompleteScreen extends StatefulWidget {
  final String amount;
  final String bankName;
  final String totalBalance;

  const ParentChargeCompleteScreen({
    super.key,
    required this.amount,
    required this.bankName,
    required this.totalBalance,
  });

  @override
  State<ParentChargeCompleteScreen> createState() => _ParentChargeCompleteScreenState();
}

class _ParentChargeCompleteScreenState extends State<ParentChargeCompleteScreen> {
  String _currentBalance = '0';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentBalance();
  }

  // 현재 포인트 잔액 가져오기
  Future<void> _loadCurrentBalance() async {
    try {
      final userInfo = await AuthService.getUserInfo();
    final points = userInfo['point'] is int 
        ? userInfo['point'] 
        : int.tryParse(userInfo['point'].toString()) ?? 0;
      if (mounted) {
        setState(() {
          _currentBalance = _formatNumber(points);
          _isLoading = false;
        });
      }
    } catch (e) {
      print('포인트 조회 오류: $e');
      if (mounted) {
        setState(() {
          _currentBalance = widget.totalBalance;
          _isLoading = false;
        });
      }
    }
  }

  // 숫자 포맷팅 (천 단위 콤마)
  String _formatNumber(dynamic number) {
    final formatter = NumberFormat('#,###');
    final value = number is int ? number : int.tryParse(number.toString()) ?? 0;
    return formatter.format(value);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // 현재 날짜 및 시간 포맷팅
    final now = DateTime.now();
    final formattedDate = DateFormat('yyyy. MM. dd HH:mm').format(now);

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
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SizedBox(height: MediaQuery.of(context).size.height * 0.08),
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
                      width: screenWidth * 0.33, // 약 1/3 크기
                      height: screenWidth * 0.35,
                      margin: EdgeInsets.only(top: 19, bottom: 11),
                      child: Image.asset(
                        'assets/icons/parent/my/charge/complete.png',
                        fit: BoxFit.contain,
                      ),
                    ),

                    // 텍스트 영역
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 9,
                      ),
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
                                '${widget.bankName} 계좌에서',
                                style: TextStyle(
                                  color: const Color(0xFF202020),
                                  fontSize:
                                      MediaQuery.of(context).textScaleFactor *
                                      14,
                                  fontFamily: 'Pretendard-Bold',
                                  letterSpacing: -0.54,
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                '${widget.amount}원을 충전했어요!',
                                style: TextStyle(
                                  color: const Color(0xFF146AFF),
                                  fontSize:
                                      MediaQuery.of(context).textScaleFactor *
                                      17,
                                  fontFamily: 'Pretendard-Bold',
                                  letterSpacing: -0.66,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 6),
                          Text(
                            '충전한 포인트는 앱 내에서만 사용 가능해요',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: const Color(0xFF8490A3),
                              fontSize:
                                  MediaQuery.of(context).textScaleFactor * 11,
                              fontFamily: 'Pretendard-Light',
                              letterSpacing: -0.21,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 21),

              // 충전 정보 영역
              Container(
                width: screenWidth * 0.9,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 9,
                ),
                decoration: ShapeDecoration(
                  color: const Color(0xFFEFF2F6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('충전 일자', formattedDate, context),
                    SizedBox(height: 12),
                    _buildInfoRow('현재 내 적립금', _currentBalance, context),
                    SizedBox(height: 12),
                    _buildInfoRow('수수료', '무료', context),
                  ],
                ),
              ),

              SizedBox(height: 21),

              // 확인 버튼
              SizedBox(
                width: screenWidth * 0.9,
                child: ElevatedButton(
                  onPressed: () {
                    // 부모님 마이페이지로 돌아가기
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3A88F4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    '확인',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: MediaQuery.of(context).textScaleFactor * 12,
                      fontFamily: 'Pretendard-Light',
                      letterSpacing: -0.21,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 정보 행 위젯 생성 함수
  Widget _buildInfoRow(String label, String value, BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(
              color: const Color(0xFF999999),
              fontSize: MediaQuery.of(context).textScaleFactor * 12,
              fontFamily: 'Pretendard-Light',
              letterSpacing: -0.24,
            ),
          ),
        ),
        SizedBox(width: 8),
        label == '현재 내 적립금' && _isLoading
            ? SizedBox(
                width: 15,
                height: 15,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF666666)),
                ),
              )
            : Text(
                value,
                style: TextStyle(
                  color: const Color(0xFF666666),
                  fontSize: MediaQuery.of(context).textScaleFactor * 12,
                  fontFamily:
                      label == '현재 내 적립금' || label == '수수료'
                          ? 'Pretendard-Medium'
                          : 'Pretendard-Light',
                  letterSpacing: -0.24,
                ),
              ),
      ],
    );
  }
} 