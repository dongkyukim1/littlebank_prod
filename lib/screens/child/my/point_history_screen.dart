import 'package:flutter/material.dart';
import '../../../widgets/common/bottom_navigation_bar.dart';
import '../../../services/payment_service.dart'; // PaymentService import 추가
import '../../../services/auth_service.dart'; // AuthService import 추가

class ArcPainter extends CustomPainter {
  final Color color;
  final double startAngle;
  final double sweepAngle;

  ArcPainter({
    required this.color,
    required this.startAngle,
    required this.sweepAngle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final rect = Rect.fromCenter(
      center: center,
      width: size.width,
      height: size.height,
    );

    final paint =
        Paint()
          ..color = color
          ..style = PaintingStyle.fill; // 채우기 스타일로 변경

    // 외부 원
    canvas.drawArc(
      rect,
      startAngle,
      sweepAngle,
      true, // true로 변경하여 부채꼴 형태로 채우기
      paint,
    );

    // 내부 원을 잘라내어 도넛 모양 만들기
    final innerCircle =
        Path()..addOval(
          Rect.fromCenter(
            center: center,
            width: size.width * 0.6, // 내부 원 크기 조정
            height: size.height * 0.6,
          ),
        );

    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addArc(rect, startAngle, sweepAngle),
        innerCircle,
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class PointHistoryScreen extends StatefulWidget {
  final int initialTabIndex;

  const PointHistoryScreen({super.key, this.initialTabIndex = 0});

  @override
  State<PointHistoryScreen> createState() => _PointHistoryScreenState();
}

class _PointHistoryScreenState extends State<PointHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // 추가: 친구들 비교 섹션 확장 여부
  final bool _isRankingExpanded = false;

  // 총 포인트 정보
  int _totalPoints = 0;
  int _currentPoints = 0;

  // 들어온 포인트 내역 데이터
  List<Map<String, dynamic>> _receivedPointHistoryData = [];

  // 로딩 상태
  bool _isLoading = true;
  bool _isHistoryLoading = false;

  // 에러 메시지
  String? _errorMessage;
  String? _historyError;

  // 날짜 범위 상태 변수 수정
  late DateTime _startDate;
  late DateTime _endDate;
  bool _isAllPeriod = true;
  bool _isInitialized = false; // 초기화 여부 체크를 위한 플래그 추가

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
    // Initialize _startDate and _endDate with default values
    _startDate = DateTime.now().subtract(
      const Duration(days: 30),
    ); // 기본값: 1개월 전
    _endDate = DateTime.now(); // 기본값: 오늘
    _isInitialized =
        false; // Reset _isInitialized as it's set in _loadReceivedPointHistory

    _loadPointInfo();
    _loadReceivedPointHistory();
  }

  // 포인트 정보 로딩
  Future<void> _loadPointInfo() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // 현재 포인트는 유저 정보에서 가져오기
      final userInfo = await AuthService.getUserInfo();
      final currentPoints = userInfo['point'] ?? 0;

      // 총 포인트는 받은 포인트와 충전한 포인트 합산으로 계산
      final totalPoints = await _calculateTotalAccumulatedPoints();

      if (mounted) {
        setState(() {
          _currentPoints = currentPoints;
          _totalPoints = totalPoints > 0 ? totalPoints : currentPoints;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
      print('포인트 정보 로딩 오류: $e');
    }
  }

  // 총 누적 포인트 계산 (받은 포인트 + 충전한 포인트)
  Future<int> _calculateTotalAccumulatedPoints() async {
    try {
      int totalReceived = 0;
      int totalCharged = 0;

      // 1. 받은 포인트 총합 계산
      int receivedPage = 0;
      bool hasMoreReceivedData = true;

      while (hasMoreReceivedData) {
        final receivedHistory = await PaymentService.getReceivedPointHistory(
          pageNumber: receivedPage,
        );

        if (receivedHistory.containsKey('data') &&
            receivedHistory['data'] is List) {
          final List<dynamic> receivedList = receivedHistory['data'];

          if (receivedList.isEmpty) {
            hasMoreReceivedData = false;
            break;
          }

          // 각 받은 포인트의 pointAmount를 누적
          for (final received in receivedList) {
            if (received.containsKey('pointAmount')) {
              final pointAmount = received['pointAmount'] ?? 0;
              totalReceived += pointAmount as int;
            }
          }

          // 다음 페이지가 있는지 확인
          final totalPage = receivedHistory['totalPage'] ?? 1;
          if (receivedPage >= totalPage - 1) {
            hasMoreReceivedData = false;
          } else {
            receivedPage++;
          }
        } else {
          hasMoreReceivedData = false;
        }
      }

      // 2. 충전한 포인트 총합 계산
      int chargePage = 0;
      bool hasMoreChargeData = true;

      while (hasMoreChargeData) {
        final chargeHistory = await PaymentService.getChargeHistory(
          pageNumber: chargePage,
        );

        if (chargeHistory.containsKey('data') &&
            chargeHistory['data'] is List) {
          final List<dynamic> chargeList = chargeHistory['data'];

          if (chargeList.isEmpty) {
            hasMoreChargeData = false;
            break;
          }

          // 각 충전 내역의 pointAmount를 누적
          for (final charge in chargeList) {
            if (charge.containsKey('pointAmount')) {
              final pointAmount = charge['pointAmount'] ?? 0;
              totalCharged += pointAmount as int;
            }
          }

          // 다음 페이지가 있는지 확인
          final totalPage = chargeHistory['totalPage'] ?? 1;
          if (chargePage >= totalPage - 1) {
            hasMoreChargeData = false;
          } else {
            chargePage++;
          }
        } else {
          hasMoreChargeData = false;
        }
      }

      final totalAccumulated = totalReceived + totalCharged;
      print('받은 포인트 총합: $totalReceived');
      print('충전한 포인트 총합: $totalCharged');
      print('총 누적 포인트: $totalAccumulated');

      return totalAccumulated;
    } catch (e) {
      print('총 누적 포인트 계산 오류: $e');
      return 0;
    }
  }

  // 필터링된 포인트 내역 로딩
  Future<void> _loadReceivedPointHistory() async {
    try {
      setState(() {
        _isHistoryLoading = true;
        _historyError = null;
      });

      // PaymentService에서 들어온 포인트 내역 가져오기
      final historyResponse = await PaymentService.getReceivedPointHistory(
        pageNumber: 0,
      );

      if (mounted) {
        setState(() {
          if (historyResponse.containsKey('data') &&
              historyResponse['data'] is List) {
            final allData = List<Map<String, dynamic>>.from(
              historyResponse['data'],
            );

            // 서버의 가장 오래된 날짜와 최신 날짜 찾기
            DateTime? oldestDate;
            DateTime? latestDate;
            for (var item in allData) {
              if (item['receivedAt'] != null) {
                try {
                  final date = DateTime.parse(item['receivedAt']);
                  if (oldestDate == null || date.isBefore(oldestDate)) {
                    oldestDate = date;
                  }
                  if (latestDate == null || date.isAfter(latestDate)) {
                    latestDate = date;
                  }
                } catch (e) {
                  print('날짜 파싱 오류: $e');
                }
              }
            }

            // 처음 로드할 때만 날짜 범위 설정
            if (!_isInitialized) {
              if (oldestDate != null && latestDate != null) {
                _startDate = oldestDate;
                _endDate = latestDate;
              } else {
                // API에서 유효한 날짜를 가져오지 못한 경우, 기본값으로 설정
                // initState에서도 초기화하지만, 여기서 한 번 더 보장합니다.
                _startDate = DateTime.now().subtract(const Duration(days: 30));
                _endDate = DateTime.now();
              }
              _isInitialized = true;
            }

            print('가장 오래된 날짜: $oldestDate');
            print('가장 최근 날짜: $latestDate');
            print('선택된 시작일: $_startDate');
            print('선택된 종료일: $_endDate');
            print('전체 기간 모드: $_isAllPeriod');

            // 날짜 필터 적용
            if (_isAllPeriod) {
              _receivedPointHistoryData = allData;
            } else {
              // 시작일의 00:00:00부터 종료일의 23:59:59까지 포함
              final startDateTime = DateTime(
                _startDate.year,
                _startDate.month,
                _startDate.day,
                0,
                0,
                0,
              );
              final endDateTime = DateTime(
                _endDate.year,
                _endDate.month,
                _endDate.day,
                23,
                59,
                59,
              );

              print('필터링 시작일시: $startDateTime');
              print('필터링 종료일시: $endDateTime');

              _receivedPointHistoryData =
                  allData.where((item) {
                    if (item['receivedAt'] == null) return false;
                    try {
                      // UTC 시간을 파싱
                      final itemDate = DateTime.parse(item['receivedAt']);
                      print('아이템 날짜: $itemDate');

                      // 년, 월, 일만 비교
                      final itemYMD = DateTime(
                        itemDate.year,
                        itemDate.month,
                        itemDate.day,
                      );
                      final startYMD = DateTime(
                        startDateTime.year,
                        startDateTime.month,
                        startDateTime.day,
                      );
                      final endYMD = DateTime(
                        endDateTime.year,
                        endDateTime.month,
                        endDateTime.day,
                      );

                      // 날짜 비교 (같은 날짜도 포함)
                      final isInRange =
                          itemYMD.compareTo(startYMD) >= 0 &&
                          itemYMD.compareTo(endYMD) <= 0;

                      print('날짜 비교 - 아이템: $itemYMD');
                      print('시작일: $startYMD');
                      print('종료일: $endYMD');
                      print('범위 내 포함 여부: $isInRange');

                      return isInRange;
                    } catch (e) {
                      print('날짜 파싱 오류: $e');
                      return false;
                    }
                  }).toList();

              print('필터링된 데이터 수: ${_receivedPointHistoryData.length}');
            }
          } else {
            _receivedPointHistoryData = [];
          }
          _isHistoryLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _historyError = e.toString();
          _isHistoryLoading = false;
        });
      }
      print('들어온 포인트 내역 로딩 오류: $e');
    }
  }

  // 필터 바텀 시트 표시
  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isDismissible: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateBottomSheet) {
            return Container(
              width: MediaQuery.of(context).size.width,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.7,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x5C000000),
                    blurRadius: 8,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 타이틀과 닫기 버튼
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '적립 내역을 조회할 기간을 정해주세요',
                            style: TextStyle(
                              fontSize: 16,
                              fontFamily: 'Pretendard-Bold',
                              color: Color(0xFF202020),
                            ),
                          ),
                          InkWell(
                            onTap: () => Navigator.pop(context),
                            child: Icon(Icons.close, size: 20),
                          ),
                        ],
                      ),

                      // 부가 설명
                      SizedBox(height: 4),
                      Text(
                        '원하는 기간별로 적립 내역을 나눠볼 수 있어요',
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'Pretendard-Light',
                          color: Color(0xFF999999),
                        ),
                      ),

                      SizedBox(height: 16),

                      // 기간 선택 버튼
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 70,
                            height: 36,
                            child: ElevatedButton(
                              onPressed: () {
                                setStateBottomSheet(() {
                                  _isAllPeriod = true;
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    _isAllPeriod
                                        ? Color(0xFF5D9EFF)
                                        : Colors.white,
                                foregroundColor:
                                    _isAllPeriod
                                        ? Colors.white
                                        : Color(0xFF5D9EFF),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  side: BorderSide(color: Color(0xFF5D9EFF)),
                                ),
                                padding: EdgeInsets.zero,
                                elevation: 0,
                              ),
                              child: Text(
                                '전체',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontFamily: 'Pretendard-Medium',
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 10),
                          SizedBox(
                            width: 70,
                            height: 36,
                            child: ElevatedButton(
                              onPressed: () {
                                setStateBottomSheet(() {
                                  _isAllPeriod = false;
                                  _startDate = DateTime.now().subtract(
                                    const Duration(days: 30),
                                  );
                                  _endDate = DateTime.now();
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    !_isAllPeriod
                                        ? Color(0xFF5D9EFF)
                                        : Colors.white,
                                foregroundColor:
                                    !_isAllPeriod
                                        ? Colors.white
                                        : Color(0xFF5D9EFF),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  side: BorderSide(color: Color(0xFF5D9EFF)),
                                ),
                                padding: EdgeInsets.zero,
                                elevation: 0,
                              ),
                              child: Text(
                                '1개월',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontFamily: 'Pretendard-Medium',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 16),

                      // 날짜 선택 필드
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _startDate,
                                  firstDate: _startDate.subtract(
                                    Duration(days: 365 * 5),
                                  ), // 5년 전까지
                                  lastDate: _endDate,
                                );
                                if (picked != null) {
                                  setStateBottomSheet(() {
                                    _startDate = picked;
                                    _isAllPeriod = false;
                                  });
                                }
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(4),
                                  color: Colors.white,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '${_startDate.year}.${_startDate.month.toString().padLeft(2, '0')}.${_startDate.day.toString().padLeft(2, '0')}',
                                  style: TextStyle(fontSize: 14),
                                ),
                              ),
                            ),
                          ),

                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text('-', style: TextStyle(fontSize: 16)),
                          ),

                          Expanded(
                            child: GestureDetector(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _endDate,
                                  firstDate: _startDate,
                                  lastDate: _endDate.add(
                                    Duration(days: 365),
                                  ), // 1년 후까지
                                );
                                if (picked != null) {
                                  setStateBottomSheet(() {
                                    _endDate = picked;
                                    _isAllPeriod = false;
                                  });
                                }
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(4),
                                  color: Colors.white,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '${_endDate.year}.${_endDate.month.toString().padLeft(2, '0')}.${_endDate.day.toString().padLeft(2, '0')}',
                                  style: TextStyle(fontSize: 14),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 20),

                      // 버튼 행
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              width: 167,
                              height: 49,
                              child: ElevatedButton(
                                onPressed: () => Navigator.pop(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey[200],
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: EdgeInsets.symmetric(horizontal: 10),
                                  elevation: 0,
                                ),
                                child: Text(
                                  '취소',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontFamily: 'Pretendard-Medium',
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: SizedBox(
                              width: 167,
                              height: 49,
                              child: ElevatedButton(
                                onPressed: () {
                                  _loadReceivedPointHistory();
                                  Navigator.pop(context);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFF5D9EFF),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: EdgeInsets.symmetric(horizontal: 10),
                                  elevation: 0,
                                ),
                                child: Text(
                                  '완료',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontFamily: 'Pretendard-ExtraLight',
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // 내역 헤더 (전체 내역 수 및 검색 아이콘)
  Widget _buildHistoryHeader() {
    return Column(
      children: [
        // 상단 여백 추가
        SizedBox(height: 16),

        // 전체 내역 수 + 필터 아이콘 (실제 데이터 기반)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        _isAllPeriod
                            ? '전체'
                            : '${_formatDateCompact(_startDate)} ~ ${_formatDateCompact(_endDate)}',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontFamily: 'Pretendard-Medium',
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      ' ${_receivedPointHistoryData.length}',
                      style: TextStyle(
                        color: const Color(0xFF5D9EFF),
                        fontSize: 16,
                        fontFamily: 'Pretendard-SemiBold',
                      ),
                    ),
                  ],
                ),
              ),
              // 필터 아이콘
              GestureDetector(
                onTap: _showFilterBottomSheet,
                child: Image.asset(
                  'assets/icons/my/필터.png',
                  width: 22,
                  height: 22,
                  color: Color.fromRGBO(166, 169, 174, 1.0),
                ),
              ),
            ],
          ),
        ),

        // 내역 목록과의 간격
        SizedBox(height: 6),
      ],
    );
  }

  // 내역 리스트 (실제 API 데이터 사용)
  Widget _buildHistoryList() {
    if (_isHistoryLoading) {
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
            children: [
              Text(
                '포인트 내역을 불러오지 못했습니다',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 14,
                  fontFamily: 'Pretendard-Medium',
                ),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: _loadReceivedPointHistory,
                child: Text('다시 시도'),
              ),
            ],
          ),
        ),
      );
    }

    if (_receivedPointHistoryData.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(50.0),
          child: Column(
            children: [
              Icon(
                Icons.account_balance_wallet,
                size: 48,
                color: Colors.grey[400],
              ),
              SizedBox(height: 16),
              Text(
                '아직 받은 포인트가 없습니다',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                  fontFamily: 'Pretendard-Medium',
                ),
              ),
              SizedBox(height: 8),
              Text(
                '미션과 챌린지를 해서 포인트를 받아보세요!',
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

    // 날짜별로 그룹화 (최신순 정렬)
    Map<String, List<Map<String, dynamic>>> groupedData = {};
    for (var item in _receivedPointHistoryData) {
      final dateKey = _formatDate(item['receivedAt'] ?? '');
      if (!groupedData.containsKey(dateKey)) {
        groupedData[dateKey] = [];
      }
      groupedData[dateKey]!.add(item);
    }

    // 날짜별로 정렬 (최신순)
    final sortedDates =
        groupedData.keys.toList()..sort((a, b) {
          try {
            final aDate = DateTime.parse(
              a.replaceAll(RegExp(r'[월일요]'), '').trim(),
            );
            final bDate = DateTime.parse(
              b.replaceAll(RegExp(r'[월일요]'), '').trim(),
            );
            return bDate.compareTo(aDate); // 최신순 정렬
          } catch (_) {
            return 0;
          }
        });

    List<Widget> sectionWidgets = [];

    int sectionIndex = 0;
    for (final dateKey in sortedDates) {
      final items = groupedData[dateKey]!;

      // 날짜 헤더 추가
      sectionWidgets.add(
        Container(
          padding: EdgeInsets.fromLTRB(20, sectionIndex == 0 ? 10 : 24, 20, 4),
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
      );

      // 아이템 추가 (시간순 정렬)
      items.sort((a, b) {
        final aTime = a['receivedAt'] ?? '';
        final bTime = b['receivedAt'] ?? '';
        return bTime.compareTo(aTime); // 최신순 정렬
      });

      for (final item in items) {
        sectionWidgets.add(
          _buildHistoryItem(
            title: '포인트 받음',
            senderName: item['senderName'] ?? '알 수 없는 사용자',
            amount: '+${_formatCurrency(item['pointAmount'] ?? 0)}원',
            time: _formatTime(item['receivedAt'] ?? ''),
            totalAmount: '${_formatCurrency(item['remainingPoint'] ?? 0)}원',
            message: item['message'],
          ),
        );
      }

      sectionIndex++;
    }

    return Column(children: sectionWidgets);
  }

  // 내역 아이템 (실제 데이터 기반)
  Widget _buildHistoryItem({
    required String title,
    required String senderName,
    required String amount,
    required String time,
    required String totalAmount,
    String? message,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 왼쪽 정보 (제목, 메시지, 보낸사람)
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 제목
                    Text(
                      title,
                      style: TextStyle(
                        color: const Color(0xFF001F55),
                        fontSize: 16,
                        fontFamily: 'Pretendard-Medium',
                        letterSpacing: -0.64,
                      ),
                    ),
                    SizedBox(height: 4),

                    // 메시지 (있는 경우)
                    if (message != null && message.isNotEmpty) ...[
                      Text(
                        '"$message"',
                        style: TextStyle(
                          color: const Color(0xFF8490A3),
                          fontSize: 12,
                          fontFamily: 'Pretendard-Light',
                          letterSpacing: -0.24,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                    ],

                    // 보낸사람과 시간
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          '$senderName님이 보냄',
                          style: TextStyle(
                            color: const Color(0xFF8490A3),
                            fontSize: 12,
                            fontFamily: 'Pretendard-Light',
                            letterSpacing: -0.24,
                          ),
                        ),
                        Container(
                          width: 2,
                          height: 2,
                          margin: EdgeInsets.symmetric(horizontal: 8),
                          decoration: ShapeDecoration(
                            color: const Color(0xFF8490A3),
                            shape: OvalBorder(),
                          ),
                        ),
                        Text(
                          time,
                          style: TextStyle(
                            color: const Color(0xFF8490A3),
                            fontSize: 12,
                            fontFamily: 'Pretendard-Light',
                            letterSpacing: -0.24,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 오른쪽 금액 정보
              Container(
                width: 120,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      amount,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: const Color(0xFF3A88F4),
                        fontSize: 16,
                        fontFamily: 'Pretendard-Bold',
                        letterSpacing: -0.64,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      totalAmount,
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
        ],
      ),
    );
  }

  // 총 포인트 정보 카드 (실제 데이터 사용)
  Widget _buildTotalPointsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(color: Colors.white),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '오늘까지 모은 총 포인트가',
                style: TextStyle(
                  color: const Color(0xFF202020),
                  fontSize: 16,
                  fontFamily: 'Pretendard-Bold',
                  height: 1.3,
                  letterSpacing: -0.72,
                ),
              ),
              SizedBox(height: 1),
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    '${_formatCurrency(_totalPoints)}원',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: const Color(0xFF202020),
                      fontSize: 26,
                      fontFamily: 'Pretendard-Bold',
                      letterSpacing: -1.12,
                    ),
                  ),
                  SizedBox(width: 6),
                  Container(
                    width: 20,
                    height: 20,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(),
                  ),
                ],
              ),
              SizedBox(height: 4),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '현재 보유 포인트는 ',
                      style: TextStyle(
                        color: const Color(0xFF999999),
                        fontSize: 14,
                        fontFamily: 'Pretendard-Light',
                        letterSpacing: -0.32,
                      ),
                    ),
                    TextSpan(
                      text: '${_formatCurrency(_currentPoints)}원',
                      style: TextStyle(
                        color: const Color(0xFF3A88F4),
                        fontSize: 14,
                        fontFamily: 'Pretendard-Bold',
                        letterSpacing: -0.32,
                      ),
                    ),
                    TextSpan(
                      text: '입니다!',
                      style: TextStyle(
                        color: const Color(0xFF999999),
                        fontSize: 14,
                        fontFamily: 'Pretendard-Light',
                        letterSpacing: -0.32,
                      ),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 프로그레스바 섹션
  Widget _buildProgressBarsSection() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment(-0.00, 0.20),
          end: Alignment(1.00, 0.99),
          colors: [
            Color.fromRGBO(180, 215, 255, 1), // 더 진한 파란색으로 시작
            Color.fromRGBO(93, 158, 255, 1), // rgba(93, 158, 255, 1)
          ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              decoration: ShapeDecoration(
                gradient: LinearGradient(
                  begin: Alignment(0.01, 0.03),
                  end: Alignment(1.02, 0.97),
                  colors: [
                    Colors.white.withOpacity(0.4),
                    Colors.white.withOpacity(0.55),
                  ],
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 프로그레스바 - 일렬로 배치
                  Row(
                    children: [
                      // 미션 프로그레스바 (33%)
                      Expanded(
                        flex: 33,
                        child: Container(
                          height: 12,
                          decoration: BoxDecoration(
                            color: const Color(0xFF146AFF),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(4),
                              bottomLeft: Radius.circular(4),
                            ),
                          ),
                        ),
                      ),

                      // 여백 추가
                      SizedBox(width: 2),

                      // 챌린지 프로그레스바 (33%)
                      Expanded(
                        flex: 33,
                        child: Container(
                          height: 12,
                          decoration: BoxDecoration(
                            color: const Color(0xFF10CB86),
                          ),
                        ),
                      ),

                      // 여백 추가
                      SizedBox(width: 2),

                      // 목표 프로그레스바 (33%)
                      Expanded(
                        flex: 34,
                        child: Container(
                          height: 12,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD27F),
                            borderRadius: BorderRadius.only(
                              topRight: Radius.circular(4),
                              bottomRight: Radius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 16),

                  // 범례 - 미션, 챌린지, 목표를 균등하게 배치
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // 미션
                      Expanded(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: const Color(0xFF146AFF),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            SizedBox(width: 2),
                            Flexible(
                              child: Text(
                                '미션 31,000원',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: const Color(0xFF353535),
                                  fontSize: 10.5,
                                  fontFamily: 'Pretendard-Medium',
                                  letterSpacing: -0.24,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(width: 4),

                      // 챌린지
                      Expanded(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: const Color(0xFF10CB86),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            SizedBox(width: 2),
                            Flexible(
                              child: Text(
                                '챌린지 31,000원',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: const Color(0xFF353535),
                                  fontSize: 10.5,
                                  fontFamily: 'Pretendard-Medium',
                                  letterSpacing: -0.24,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(width: 4),

                      // 목표
                      Expanded(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFD27F),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            SizedBox(width: 2),
                            Flexible(
                              child: Text(
                                '목표 31,000원',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: const Color(0xFF353535),
                                  fontSize: 10.5,
                                  fontFamily: 'Pretendard-Medium',
                                  letterSpacing: -0.24,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
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

  // 날짜 포맷팅 (YYYY.MM.dd)
  String _formatDateCompact(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
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

  // 금액 포맷팅 (천 단위 콤마)
  String _formatCurrency(dynamic amount) {
    final int value =
        amount is int ? amount : int.tryParse(amount.toString()) ?? 0;
    return value.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
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
        title: const Text(
          '총 포인트 적립 내역',
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Image.asset('assets/icons/my/뒤로가기.png', width: 20, height: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // 나머지 부분은 스크롤 가능하게
          Expanded(
            child: CustomScrollView(
              slivers: [
                // 총 포인트 정보 카드
                SliverToBoxAdapter(child: _buildTotalPointsCard()),

                // 프로그레스바 섹션 추가
                SliverToBoxAdapter(child: _buildProgressBarsSection()),

                // 구분선
                SliverToBoxAdapter(
                  child: Container(
                    width: double.infinity,
                    height: 6,
                    decoration: ShapeDecoration(
                      color: const Color(0xFFE7ECF6),
                      shape: RoundedRectangleBorder(
                        side: BorderSide(
                          width: 0.10,
                          color: const Color(0xFF8490A3),
                        ),
                      ),
                    ),
                  ),
                ),

                // 필터 버튼 추가 (구분선 아래로 이동)
                SliverToBoxAdapter(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // 대상 버튼
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  decoration: ShapeDecoration(
                                    color: const Color(0xFF5C697E),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        '대상',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontFamily: 'Pretendard-Medium',
                                          letterSpacing: -0.28,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Image.asset(
                                        'assets/icons/my/droddown.png',
                                        width: 16,
                                        height: 16,
                                        color: Colors.white,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(width: 8),
                              // 과목별 버튼
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  decoration: ShapeDecoration(
                                    color: const Color(0xFF5C697E),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        '과목별',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontFamily: 'Pretendard-Medium',
                                          letterSpacing: -0.28,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Image.asset(
                                        'assets/icons/my/droddown.png',
                                        width: 16,
                                        height: 16,
                                        color: Colors.white,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(width: 8),
                              // 활동별 버튼
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  decoration: ShapeDecoration(
                                    color: const Color(0xFF5C697E),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        '활동별',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontFamily: 'Pretendard-Medium',
                                          letterSpacing: -0.28,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Image.asset(
                                        'assets/icons/my/droddown.png',
                                        width: 16,
                                        height: 16,
                                        color: Colors.white,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 전체 내역 수 및 검색 헤더
                SliverToBoxAdapter(child: _buildHistoryHeader()),

                // 내역 리스트
                SliverToBoxAdapter(child: _buildHistoryList()),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: const CommonBottomNavigationBar(selectedIndex: 4),
    );
  }
}

// 클래스 추가
class DoughnutClipper extends CustomClipper<Path> {
  final double startAngle;
  final double sweepAngle;

  DoughnutClipper({required this.startAngle, required this.sweepAngle});

  @override
  Path getClip(Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final rect = Rect.fromCenter(
      center: center,
      width: size.width,
      height: size.height,
    );

    final path =
        Path()
          ..moveTo(center.dx, center.dy)
          ..addArc(rect, startAngle, sweepAngle)
          ..lineTo(center.dx, center.dy)
          ..close();

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) {
    return true;
  }
}
