import 'package:flutter/material.dart';
import '../../../widgets/common/bottom_navigation_bar.dart';
import '../../../services/payment_service.dart';

class RefundHistoryScreen extends StatefulWidget {
  const RefundHistoryScreen({super.key});

  @override
  State<RefundHistoryScreen> createState() => _RefundHistoryScreenState();
}

class _RefundHistoryScreenState extends State<RefundHistoryScreen> {
  // 꺼낸 포인트 내역 데이터
  List<Map<String, dynamic>> _refundHistoryData = [];

  // 로딩 상태
  bool _isLoading = true;
  bool _isHistoryLoading = false;

  // 에러 메시지
  String? _errorMessage;
  String? _historyError;

  // 페이지네이션
  int _currentPage = 0;
  int _totalPages = 0;
  int _totalElements = 0;
  bool _hasMoreData = true;

  @override
  void initState() {
    super.initState();
    _loadRefundHistory();
  }

  // 포인트 꺼낸 내역 로딩
  Future<void> _loadRefundHistory({bool isRefresh = false}) async {
    try {
      setState(() {
        if (isRefresh) {
          _isLoading = true;
          _currentPage = 0;
          _refundHistoryData.clear();
        } else {
          _isHistoryLoading = true;
        }
        _historyError = null;
      });

      // PaymentService에서 포인트 꺼낸 내역 가져오기
      final historyResponse = await PaymentService.getRefundHistory(
        pageNumber: isRefresh ? 0 : _currentPage,
      );

      if (mounted) {
        setState(() {
          if (historyResponse.containsKey('data') &&
              historyResponse['data'] is List) {
            final List<Map<String, dynamic>> newData =
                List<Map<String, dynamic>>.from(historyResponse['data']);

            if (isRefresh) {
              _refundHistoryData = newData;
            } else {
              _refundHistoryData.addAll(newData);
            }

            _totalPages = historyResponse['totalPage'] ?? 0;
            _totalElements = historyResponse['totalElement'] ?? 0;
            _hasMoreData = _currentPage < (_totalPages - 1);
          } else {
            if (isRefresh) {
              _refundHistoryData = [];
            }
          }
          _isLoading = false;
          _isHistoryLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _historyError = e.toString();
          _isLoading = false;
          _isHistoryLoading = false;
        });
      }
      print('포인트 꺼낸 내역 로딩 오류: $e');
    }
  }

  // 더 많은 데이터 로드
  Future<void> _loadMoreData() async {
    if (!_hasMoreData || _isHistoryLoading) return;

    _currentPage++;
    await _loadRefundHistory();
  }

  // 새로고침
  Future<void> _onRefresh() async {
    await _loadRefundHistory(isRefresh: true);
  }

  // 금액 포맷팅 (천 단위 콤마)
  String _formatCurrency(dynamic amount) {
    final int value =
        amount is int ? amount : int.tryParse(amount.toString()) ?? 0;
    return value.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  // 날짜 포맷팅 (MM월 dd일 요일)
  String _formatDate(String isoDate) {
    try {
      final DateTime date = DateTime.parse(isoDate);
      final List<String> weekdays = ['월', '화', '수', '목', '금', '토', '일'];
      final String weekday = weekdays[date.weekday - 1];
      return '${date.month}월 ${date.day}일 ${weekday}요일';
    } catch (e) {
      return isoDate;
    }
  }

  // 시간 포맷팅 (HH:mm)
  String _formatTime(String isoDate) {
    try {
      final DateTime date = DateTime.parse(isoDate);
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return '';
    }
  }

  // 상태 텍스트 변환
  String _getStatusText(String status) {
    switch (status) {
      case 'WAIT':
        return ''; // 대기 중 상태는 표시하지 않음
      case 'COMPLETE':
        return '완료';
      case 'REJECT':
        return '거절';
      default:
        return status;
    }
  }

  // 상태 색상 가져오기
  Color _getStatusColor(String status) {
    switch (status) {
      case 'WAIT':
        return const Color(0xFFFFA500); // 주황색
      case 'COMPLETE':
        return const Color(0xFF10CB86); // 초록색
      case 'REJECT':
        return const Color(0xFFFF4444); // 빨간색
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          '총 포인트 꺼낸 내역',
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontFamily: 'Pretendard-Bold',
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Image.asset('assets/images/home.png', width: 24, height: 24),
            onPressed: () {
              // 홈으로 이동
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: Column(
          children: [
            // 총 꺼낸 내역 정보 카드
            _buildTotalRefundCard(),

            // 구분선
            Container(
              width: double.infinity,
              height: 6,
              decoration: ShapeDecoration(
                color: const Color(0xFFE7ECF6),
                shape: RoundedRectangleBorder(
                  side: BorderSide(width: 0.10, color: const Color(0xFF8490A3)),
                ),
              ),
            ),

            // 전체 내역 수 및 검색 헤더
            _buildHistoryHeader(),

            // 내역 리스트
            Expanded(child: _buildHistoryList()),
          ],
        ),
      ),
      bottomNavigationBar: const CommonBottomNavigationBar(selectedIndex: 4),
    );
  }

  // 총 꺼낸 포인트 정보 카드
  Widget _buildTotalRefundCard() {
    // 총 요청 금액 계산
    int totalRequestedAmount = 0;
    int totalProcessedAmount = 0;

    for (var item in _refundHistoryData) {
      totalRequestedAmount += (item['requestedAmount'] ?? 0) as int;
      totalProcessedAmount += (item['processedAmount'] ?? 0) as int;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment(-0.00, 0.20),
          end: Alignment(1.00, 0.99),
          colors: [
            Color.fromRGBO(180, 215, 255, 1),
            Color.fromRGBO(93, 158, 255, 1),
          ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '총 포인트 꺼낸 금액이',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontFamily: 'Pretendard-Bold',
              height: 1.3,
              letterSpacing: -0.72,
            ),
          ),
          SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '${_formatCurrency(totalProcessedAmount)}원',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontFamily: 'Pretendard-Bold',
                  letterSpacing: -1.12,
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '요청 금액은 ',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                    fontFamily: 'Pretendard-Light',
                    letterSpacing: -0.32,
                  ),
                ),
                TextSpan(
                  text: '${_formatCurrency(totalRequestedAmount)}원',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontFamily: 'Pretendard-Bold',
                    letterSpacing: -0.32,
                  ),
                ),
                TextSpan(
                  text: '입니다',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                    fontFamily: 'Pretendard-Light',
                    letterSpacing: -0.32,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 내역 헤더 (전체 내역 수)
  Widget _buildHistoryHeader() {
    return Column(
      children: [
        SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    '전체 내역 ',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontFamily: 'Pretendard-Medium',
                    ),
                  ),
                  Text(
                    '$_totalElements',
                    style: TextStyle(
                      color: const Color(0xFF5D9EFF),
                      fontSize: 16,
                      fontFamily: 'Pretendard-SemiBold',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: 6),
      ],
    );
  }

  // 내역 리스트
  Widget _buildHistoryList() {
    if (_isLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: CircularProgressIndicator(color: Color(0xFF5D9DFF)),
        ),
      );
    }

    if (_historyError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '포인트 꺼낸 내역을 불러오지 못했습니다',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 14,
                  fontFamily: 'Pretendard-Medium',
                ),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => _loadRefundHistory(isRefresh: true),
                child: Text('다시 시도'),
              ),
            ],
          ),
        ),
      );
    }

    if (_refundHistoryData.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(50.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.account_balance_wallet_outlined,
                size: 48,
                color: Colors.grey[400],
              ),
              SizedBox(height: 16),
              Text(
                '포인트 꺼낸 내역이 없습니다',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                  fontFamily: 'Pretendard-Medium',
                ),
              ),
              SizedBox(height: 8),
              Text(
                '포인트를 꺼내면 내역이 표시됩니다',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                  fontFamily: 'Pretendard-Light',
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 날짜별로 그룹화
    Map<String, List<Map<String, dynamic>>> groupedData = {};
    for (var item in _refundHistoryData) {
      final dateKey = _formatDate(item['requestedAt'] ?? '');
      if (!groupedData.containsKey(dateKey)) {
        groupedData[dateKey] = [];
      }
      groupedData[dateKey]!.add(item);
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        if (scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent &&
            _hasMoreData &&
            !_isHistoryLoading) {
          _loadMoreData();
        }
        return false;
      },
      child: ListView.builder(
        itemCount: groupedData.length + (_hasMoreData ? 1 : 0),
        itemBuilder: (context, index) {
          // 로딩 인디케이터 표시
          if (index == groupedData.length) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: CircularProgressIndicator(color: Color(0xFF5D9DFF)),
              ),
            );
          }

          final entry = groupedData.entries.elementAt(index);
          final dateKey = entry.key;
          final items = entry.value;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 날짜 헤더
              Container(
                padding: EdgeInsets.fromLTRB(20, index == 0 ? 10 : 24, 20, 4),
                alignment: Alignment.centerLeft,
                child: Text(
                  dateKey,
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                    fontFamily: 'Pretendard-Light',
                  ),
                ),
              ),

              // 아이템들
              ...items
                  .map(
                    (item) => _buildHistoryItem(
                      requestedAmount: item['requestedAmount'] ?? 0,
                      processedAmount: item['processedAmount'] ?? 0,
                      status: item['status'] ?? 'WAIT',
                      time: _formatTime(item['requestedAt'] ?? ''),
                      refundId: item['refundId'] ?? 0,
                    ),
                  )
                  .toList(),
            ],
          );
        },
      ),
    );
  }

  // 내역 아이템
  Widget _buildHistoryItem({
    required int requestedAmount,
    required int processedAmount,
    required String status,
    required String time,
    required int refundId,
  }) {
    final statusText = _getStatusText(status);
    final statusColor = _getStatusColor(status);
    final feeAmount = requestedAmount - processedAmount;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 제목 및 상태
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '포인트 꺼내기',
                      style: TextStyle(
                        color: Color.fromRGBO(0, 31, 85, 1),
                        fontSize: 14,
                        fontFamily: 'Pretendard-Medium',
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      '신청 ID: $refundId',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                        fontFamily: 'Pretendard-Light',
                      ),
                    ),
                  ],
                ),
              ),
              if (statusText.isNotEmpty) // 상태 텍스트가 있을 때만 표시
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontFamily: 'Pretendard-Medium',
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 8),

          // 금액 정보
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              children: [
                // 요청 금액
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '요청 금액',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 12,
                        fontFamily: 'Pretendard-Light',
                      ),
                    ),
                    Text(
                      '${_formatCurrency(requestedAmount)}원',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 12,
                        fontFamily: 'Pretendard-Medium',
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 4),

                // 수수료
                if (feeAmount > 0) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '수수료',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 12,
                          fontFamily: 'Pretendard-Light',
                        ),
                      ),
                      Text(
                        '-${_formatCurrency(feeAmount)}원',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                          fontFamily: 'Pretendard-Medium',
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 4),

                  Divider(height: 1, color: Colors.grey[300]),

                  SizedBox(height: 4),
                ],

                // 실제 환전 금액
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '실제 환전 금액',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 13,
                        fontFamily: 'Pretendard-Medium',
                      ),
                    ),
                    Text(
                      '${_formatCurrency(processedAmount)}원',
                      style: TextStyle(
                        color: Color(0xFF3A88F4),
                        fontSize: 14,
                        fontFamily: 'Pretendard-Bold',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // 시간
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                time,
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                  fontFamily: 'Pretendard-Light',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
