import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TossPaymentFailureScreen extends StatefulWidget {
  final String errorMessage;
  final String orderId;
  final String? errorCode;

  const TossPaymentFailureScreen({
    super.key,
    required this.errorMessage,
    required this.orderId,
    this.errorCode,
  });

  @override
  State<TossPaymentFailureScreen> createState() => _TossPaymentFailureScreenState();
}

class _TossPaymentFailureScreenState extends State<TossPaymentFailureScreen> {
  
  // 뒤로 가기
  void _goBack() {
    Navigator.of(context).pop();
  }

  // 홈으로 이동
  void _goToHome() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  // 다시 시도
  void _retryPayment() {
    // 현재 결제 화면을 닫고 이전 화면으로 돌아가기
    Navigator.of(context).pop();
  }

  // 주문번호 복사
  void _copyOrderId() {
    Clipboard.setData(ClipboardData(text: widget.orderId));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('주문번호가 복사되었습니다.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  // 고객센터 문의
  void _contactCustomerService() {
    // 고객센터 문의 기능 구현 (전화, 채팅, 이메일 등)
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          '고객센터 문의',
          style: TextStyle(
            fontFamily: 'Pretendard-Bold',
            fontSize: 18,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '결제 문의사항이 있으시면 고객센터로 연락 주세요.',
              style: TextStyle(
                fontFamily: 'Pretendard-Medium',
                fontSize: 14,
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.phone, color: Colors.grey[600], size: 16),
                SizedBox(width: 8),
                Text(
                  '02-575-1071',
                  style: TextStyle(
                    fontFamily: 'Pretendard-Medium',
                    fontSize: 14,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.schedule, color: Colors.grey[600], size: 16),
                SizedBox(width: 8),
                Text(
                  '평일 9:00~18:00',
                  style: TextStyle(
                    fontFamily: 'Pretendard-Light',
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              '확인',
              style: TextStyle(
                fontFamily: 'Pretendard-Medium',
                color: const Color(0xFF5D9EFF),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: const Text(
          '결제 실패',
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontFamily: 'Pretendard-Bold',
            letterSpacing: -0.32,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.home, color: Colors.black, size: 24),
            onPressed: _goToHome,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 40),

            // 실패 아이콘
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFE57373),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close,
                color: Colors.white,
                size: 48,
              ),
            ),

            SizedBox(height: 24),

            // 실패 메시지
            Text(
              '결제에 실패했습니다',
              style: TextStyle(
                fontSize: 24,
                fontFamily: 'Pretendard-Bold',
                color: Colors.black,
              ),
            ),

            SizedBox(height: 8),

            Text(
              '결제 처리 중 문제가 발생했습니다.',
              style: TextStyle(
                fontSize: 16,
                fontFamily: 'Pretendard-Medium',
                color: Colors.grey[600],
              ),
            ),

            SizedBox(height: 40),

            // 오류 정보 카드
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFFFCC80),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '오류 정보',
                    style: TextStyle(
                      fontSize: 18,
                      fontFamily: 'Pretendard-Bold',
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 16),

                  // 오류 메시지
                  _buildInfoRow(
                    '오류 내용',
                    widget.errorMessage,
                  ),

                  // 오류 코드 (있는 경우)
                  if (widget.errorCode != null)
                    _buildInfoRow(
                      '오류 코드',
                      widget.errorCode!,
                    ),

                  // 주문번호
                  _buildInfoRow(
                    '주문번호',
                    widget.orderId,
                    showCopyButton: true,
                  ),

                  // 발생 시간
                  _buildInfoRow(
                    '발생 시간',
                    _formatDateTime(DateTime.now()),
                  ),
                ],
              ),
            ),

            SizedBox(height: 40),

            // 해결 방법 안내
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        color: const Color(0xFF1976D2),
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        '해결 방법',
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: 'Pretendard-Bold',
                          color: const Color(0xFF1976D2),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Text(
                    '• 결제 정보를 다시 확인해주세요.\n• 카드 한도나 잔액을 확인해주세요.\n• 네트워크 연결 상태를 확인해주세요.\n• 문제가 지속되면 고객센터에 문의해주세요.',
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: 'Pretendard-Medium',
                      color: const Color(0xFF1976D2),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 40),

            // 액션 버튼들
            Column(
              children: [
                // 다시 시도 버튼
                Container(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _retryPayment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF89DA8D),
                            const Color(0xFF5D9EFF),
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Container(
                        alignment: Alignment.center,
                        child: Text(
                          '다시 시도',
                          style: TextStyle(
                            fontSize: 16,
                            fontFamily: 'Pretendard-Bold',
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 12),

                // 고객센터 문의 버튼
                Container(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton(
                    onPressed: _contactCustomerService,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF5D9EFF),
                      side: BorderSide(
                        color: const Color(0xFF5D9EFF),
                        width: 1,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      '고객센터 문의',
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: 'Pretendard-Bold',
                        color: const Color(0xFF5D9EFF),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 12),

                // 홈으로 이동 버튼
                Container(
                  width: double.infinity,
                  height: 56,
                  child: TextButton(
                    onPressed: _goToHome,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey[600],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      '홈으로 이동',
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: 'Pretendard-Medium',
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 정보 행 위젯
  Widget _buildInfoRow(String label, String value, {bool showCopyButton = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontFamily: 'Pretendard-Medium',
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: 'Pretendard-Medium',
                    color: Colors.black,
                  ),
                ),
              ),
              if (showCopyButton)
                IconButton(
                  icon: Icon(
                    Icons.copy,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  onPressed: _copyOrderId,
                  constraints: BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // 날짜 포맷팅
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
} 