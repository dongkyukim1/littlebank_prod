import 'package:flutter/material.dart';
import '../../../../widgets/parent/bottom_navigation_bar.dart';
import '../my_page_screen.dart';
import '../../../../services/auth_service.dart';

class ParentWithdrawalCompleteScreen extends StatefulWidget {
  final String selectedBank;
  final String accountNumber;
  final String amount;
  final int fee;
  final int netAmount;
  final String? receiverName;
  final String? receiverPhone;
  final String? senderName;
  final int? remainingPoint; // API에서 받은 남은 포인트

  const ParentWithdrawalCompleteScreen({
    super.key,
    required this.selectedBank,
    required this.accountNumber,
    required this.amount,
    required this.fee,
    required this.netAmount,
    this.receiverName,
    this.receiverPhone,
    this.senderName,
    this.remainingPoint,
  });

  @override
  State<ParentWithdrawalCompleteScreen> createState() =>
      _ParentWithdrawalCompleteScreenState();
}

class _ParentWithdrawalCompleteScreenState
    extends State<ParentWithdrawalCompleteScreen> {
  int? _currentUserPoints;

  String _formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  @override
  void initState() {
    super.initState();
    _loadCurrentUserPoints();
  }

  // 현재 사용자 포인트 로드
  Future<void> _loadCurrentUserPoints() async {
    try {
      final userInfo = await AuthService.getUserInfo();
      if (mounted) {
        setState(() {
          _currentUserPoints = userInfo['point'] ?? 0;
        });
      }
    } catch (e) {
      print('사용자 포인트 로드 오류: $e');
      if (mounted) {
        setState(() {
          _currentUserPoints = 0;
        });
      }
    }
  }

  // 자기 자신에게 출금인지 확인
  bool _isWithdrawalToSelf() {
    // receiverPhone이 없거나 빈 문자열이면 자기 자신 출금으로 판단
    return widget.receiverPhone == null || widget.receiverPhone!.isEmpty;
  }

  String _formatReceiverInfo() {
    if (_isWithdrawalToSelf()) {
      // 자기 자신 출금인 경우
      return '${widget.senderName ?? "본인"} (본인 계좌)';
    }

    if (widget.receiverName != null && widget.receiverPhone != null) {
      // 전화번호를 010-0000-0000 형태로 포맷팅
      String formattedPhone = widget.receiverPhone!;

      // 하이픈이 없는 11자리 번호인 경우 포맷팅
      if (widget.receiverPhone!.length == 11 &&
          widget.receiverPhone!.startsWith('010')) {
        formattedPhone =
            '${widget.receiverPhone!.substring(0, 3)}-${widget.receiverPhone!.substring(3, 7)}-${widget.receiverPhone!.substring(7)}';
      }
      // 이미 하이픈이 있는 경우는 그대로 사용
      else if (widget.receiverPhone!.contains('-')) {
        formattedPhone = widget.receiverPhone!;
      }

      return '${widget.receiverName} ($formattedPhone)';
    }
    return '받는 사람 정보 없음'; // fallback
  }

  // 실제 출금한 금액 계산 (수수료 제외한 순 금액)
  int _getRealWithdrawnAmount() {
    return widget.netAmount; // netAmount가 이미 수수료를 제외한 실제 출금 금액
  }

  // 남은 포인트 반환 (API에서 받은 값 우선 사용)
  int _getRemainingPoints() {
    // API에서 받은 remainingPoint가 있으면 그 값을 사용
    if (widget.remainingPoint != null) {
      return widget.remainingPoint!;
    }

    // fallback: 현재 사용자 포인트에서 출금 금액을 뺀 값
    final withdrawnAmount =
        int.tryParse(widget.amount.replaceAll(',', '')) ?? 0;
    final currentPoints = _currentUserPoints ?? 0;

    return currentPoints - withdrawnAmount;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            width: screenWidth,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 120),

                // 완료 아이콘
                Container(
                  width: 108,
                  height: 109,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage(
                        "assets/icons/parent/bank/complete_withdraw.png",
                      ),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

                SizedBox(height: 28),

                // 완료 메시지
                Column(
                  children: [
                    Text(
                      '${widget.senderName ?? "사용자"}님이',
                      style: TextStyle(
                        color: const Color(0xFF202020),
                        fontSize: 18,
                        fontFamily: 'Pretendard-Bold',
                        letterSpacing: -0.72,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '${_formatCurrency(widget.netAmount)}원을 꺼냈어요!',
                      style: TextStyle(
                        color: const Color(0xFF146AFF),
                        fontSize: 20,
                        fontFamily: 'Pretendard-Bold',
                        letterSpacing: -0.88,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      _isWithdrawalToSelf()
                          ? '확인 후, 연동된 계좌에 직접 입금해 드려요!\n3만원 이상 출금시, 리틀뱅크가 수수료를 대신 내드려요'
                          : '확인 후, ${widget.receiverName ?? "받는 사람"}님에게 직접 입금해 드려요!\n3만원 이상 보낼시, 리틀뱅크가 수수료를 대신 내드려요',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: const Color(0xFF8490A3),
                        fontSize: 12,
                        fontFamily: 'Pretendard-Light',
                        letterSpacing: -0.28,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 24),

                // 출금 상세 정보 카드
                Container(
                  width: double.infinity,
                  constraints: BoxConstraints(maxWidth: 358),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: ShapeDecoration(
                    color: const Color(0xFFE7ECF6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildLeftAlignedInfoRow('받는 사람', _formatReceiverInfo()),
                      SizedBox(height: 16),
                      _buildLeftAlignedInfoRow(
                        '꺼낸 포인트',
                        '${_formatCurrency(_getRealWithdrawnAmount())}원',
                      ),
                      SizedBox(height: 16),
                      _buildLeftAlignedInfoRow(
                        '남은 포인트',
                        '${_formatCurrency(_getRemainingPoints())}원',
                      ),
                      SizedBox(height: 16),
                      _buildLeftAlignedInfoRow(
                        '수수료',
                        widget.fee == 0 ? '무료' : '${widget.fee}원',
                      ),
                      SizedBox(height: 16),
                      _buildLeftAlignedInfoRow('처리상태', '대기 중'),
                    ],
                  ),
                ),

                SizedBox(height: 28),

                // 확인 버튼
                GestureDetector(
                  onTap: () async {
                    // 마이페이지로 이동하면서 포인트 새로고침 신호 전달
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ParentMyPageScreen(),
                      ),
                      (route) => false,
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    constraints: BoxConstraints(maxWidth: 358),
                    padding: const EdgeInsets.all(16),
                    decoration: ShapeDecoration(
                      color: const Color(0xFF3A88F4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '확인',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontFamily: 'Pretendard-Light',
                          letterSpacing: -0.28,
                        ),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 100), // 하단 여백 추가
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: const ParentBottomNavigationBar(selectedIndex: 4),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    bool isHighlighted = false,
  }) {
    return Container(
      height: 24,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 3,
            child: Container(
              alignment: Alignment.centerLeft,
              child: Text(
                label,
                style: TextStyle(
                  color:
                      isHighlighted
                          ? const Color(0xFF146AFF)
                          : const Color(0xFF999999),
                  fontSize: 12,
                  fontFamily: 'Pretendard-Light',
                  letterSpacing: -0.24,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Container(
              alignment: Alignment.center,
              child: Text(
                value,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color:
                      isHighlighted
                          ? const Color(0xFF146AFF)
                          : const Color(0xFF666666),
                  fontSize: 12,
                  fontFamily:
                      isHighlighted ? 'Pretendard-Medium' : 'Pretendard-Light',
                  letterSpacing: -0.24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeftAlignedInfoRow(
    String label,
    String value, {
    bool isHighlighted = false,
  }) {
    return Container(
      height: 24,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                color:
                    isHighlighted
                        ? const Color(0xFF146AFF)
                        : const Color(0xFF999999),
                fontSize: 12,
                fontFamily: 'Pretendard-Light',
                letterSpacing: -0.24,
              ),
            ),
          ),
          SizedBox(width: 40), // 고정 간격
          Text(
            value,
            style: TextStyle(
              color:
                  isHighlighted
                      ? const Color(0xFF146AFF)
                      : const Color(0xFF666666),
              fontSize: 12,
              fontFamily:
                  isHighlighted ? 'Pretendard-Medium' : 'Pretendard-Light',
              letterSpacing: -0.24,
            ),
          ),
        ],
      ),
    );
  }
}
