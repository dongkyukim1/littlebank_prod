import 'package:flutter/material.dart';
import '../../../widgets/common/bottom_navigation_bar.dart';
import '../../../services/payment_service.dart';

class TransferCompleteScreen extends StatefulWidget {
  final String receiverName;
  final String receiverAccount;
  final String senderAccount;
  final String amount;
  final int remainingBalance;

  const TransferCompleteScreen({
    super.key,
    required this.receiverName,
    required this.receiverAccount,
    required this.senderAccount,
    required this.amount,
    required this.remainingBalance,
  });

  @override
  State<TransferCompleteScreen> createState() => _TransferCompleteScreenState();
}

class _TransferCompleteScreenState extends State<TransferCompleteScreen> {
  @override
  void initState() {
    super.initState();
    print('🔍 [COMPLETE DEBUG] TransferCompleteScreen initState 호출');
    print('🔍 [COMPLETE DEBUG] remainingBalance: ${widget.remainingBalance}');
    print(
      '🔍 [COMPLETE DEBUG] remainingBalance 타입: ${widget.remainingBalance.runtimeType}',
    );
  }

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
                      child: Image.asset(
                        'assets/icons/my/이체완료.png',
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
                                '${widget.receiverName}님에게',
                                style: TextStyle(
                                  color: const Color(0xFF202020),
                                  fontSize: 13,
                                  fontFamily: 'Pretendard-Bold',
                                  letterSpacing: -0.5,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                '${widget.amount}원을 꺼냈어요!',
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
                            '확인 후 ${widget.receiverName}님에게 직접 입금해드려요!\n3만원 이상 시 수수료가 대신내드려요.',
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

              // 이체 정보 영역
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
                    _buildInfoRow(
                      '받을 사람',
                      '${widget.receiverName} (${widget.receiverAccount})',
                    ),
                    SizedBox(height: 8),
                    _buildInfoRow('꺼낸 포인트', widget.amount),
                    SizedBox(height: 8),
                    _buildInfoRow(
                      '남은 내 포인트',
                      '${_formatCurrency(widget.remainingBalance)}원',
                    ),
                    SizedBox(height: 8),
                    _buildInfoRow('처리 상태', '확인 대기 중'),
                  ],
                ),
              ),

              SizedBox(height: 20),

              // 확인 버튼
              SizedBox(
                width: screenWidth * 0.9,
                child: ElevatedButton(
                  onPressed: () async {
                    print('🏠 [완료화면] 홈으로 돌아가기 - 포인트 강제 새로고침');
                    // 포인트 강제 새로고침 후 홈으로 이동
                    await PaymentService.getUserPoints(forceRefresh: true);
                    Navigator.popUntil(context, (route) => route.isFirst);
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
        Text(
          value,
          style: TextStyle(
            color: const Color(0xFF666666),
            fontSize: 12,
            fontFamily:
                label == '남은 내 적립금' || label == '수수료'
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
