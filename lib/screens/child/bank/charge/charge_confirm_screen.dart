import 'package:flutter/material.dart';
import '../../../../widgets/common/bottom_navigation_bar.dart';
import '../../../../services/payment_service.dart';
import 'package:intl/intl.dart';

class ChargeConfirmScreen extends StatefulWidget {
  final String amount;
  final String bankName;
  final int currentBalance;

  const ChargeConfirmScreen({
    super.key,
    required this.amount,
    required this.bankName,
    required this.currentBalance,
  });

  @override
  State<ChargeConfirmScreen> createState() => _ChargeConfirmScreenState();
}

class _ChargeConfirmScreenState extends State<ChargeConfirmScreen> {
  @override
  void initState() {
    super.initState();
    print('🔍 [CONFIRM DEBUG] ChargeConfirmScreen initState 호출');
    print('🔍 [CONFIRM DEBUG] currentBalance: ${widget.currentBalance}');
    print(
      '🔍 [CONFIRM DEBUG] currentBalance 타입: ${widget.currentBalance.runtimeType}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
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
                      child: Image.asset(
                        'assets/icons/parent/bank/complete_withdraw.png',
                        fit: BoxFit.contain,
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
                                '${widget.bankName}에서',
                                style: TextStyle(
                                  color: const Color(0xFF202020),
                                  fontSize: 13,
                                  fontFamily: 'Pretendard-Bold',
                                  letterSpacing: -0.5,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                '${widget.amount}원을 충전했어요!',
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
                            '충전한 포인트는 앱 내에서만 사용 가능해요.\n포인트 내역에서 충전 내역을 확인하실 수 있습니다.',
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

              // 충전 정보 영역
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
                    _buildInfoRow('충전 일시', formattedDate),
                    SizedBox(height: 8),
                    _buildInfoRow('충전 금액', '${widget.amount}원'),
                    SizedBox(height: 8),
                    _buildInfoRow(
                      '현재 보유 포인트',
                      '${_formatCurrency(widget.currentBalance)}원',
                    ),
                    SizedBox(height: 8),
                    _buildInfoRow(
                      '충전 후 나의 포인트',
                      '${_formatCurrency(widget.currentBalance + int.parse(widget.amount.replaceAll(',', '')))}원',
                    ),
                    SizedBox(height: 8),
                    _buildInfoRow('수수료', '무료'),
                  ],
                ),
              ),

              SizedBox(height: 20),

              // 확인 버튼
              SizedBox(
                width: screenWidth * 0.9,
                child: ElevatedButton(
                  onPressed: () async {
                    print('🔒 [확인화면] 결제 진행 확인');
                    Navigator.pop(context, {'confirmed': true});
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

              SizedBox(height: 10),

              // 홈으로 가기 버튼
              SizedBox(
                width: screenWidth * 0.9,
                child: TextButton(
                  onPressed: () {
                    print('🏠 [확인화면] 홈으로 이동');
                    Navigator.pop(context, {'confirmed': false});
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    '홈으로 가기',
                    style: TextStyle(
                      color: const Color(0xFF8490A3),
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
      bottomNavigationBar: const CommonBottomNavigationBar(selectedIndex: 0),
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
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: const Color(0xFF666666),
              fontSize: 12,
              fontFamily:
                  label.contains('포인트') || label == '수수료'
                      ? 'Pretendard-Medium'
                      : 'Pretendard-Light',
              letterSpacing: -0.28,
            ),
          ),
        ),
      ],
    );
  }

  // 금액 포맷 함수
  String _formatCurrency(int amount) {
    print('🔍 [FORMAT DEBUG] _formatCurrency 호출됨');
    print('🔍 [FORMAT DEBUG] 입력 amount: $amount');
    print('🔍 [FORMAT DEBUG] amount 타입: ${amount.runtimeType}');

    final formatted = amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]},',
    );

    print('🔍 [FORMAT DEBUG] 포맷된 결과: $formatted');
    return formatted;
  }
}
