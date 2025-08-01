import 'package:flutter/material.dart';
import '../../../../widgets/parent/bottom_navigation_bar.dart';
import '../../../../services/payment_service.dart';

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

class ParentAllowanceHistoryScreen extends StatefulWidget {
  final int initialTabIndex;

  const ParentAllowanceHistoryScreen({super.key, this.initialTabIndex = 0});

  @override
  State<ParentAllowanceHistoryScreen> createState() =>
      _ParentAllowanceHistoryScreenState();
}

class _ParentAllowanceHistoryScreenState
    extends State<ParentAllowanceHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // 추가: 친구들 비교 섹션 확장 여부
  final bool _isRankingExpanded = false;

  // 최근 포인트를 보낸 계좌 데이터
  List<Map<String, dynamic>> _latestAccountsData = [];

  // 최근 계좌 로딩 상태
  bool _isLatestAccountsLoading = true;

  // 최근 계좌 에러 메시지
  String? _latestAccountsError;

  // 필터링을 위한 상태 추가
  String? _selectedReceiverId;
  String? _selectedActivityType;
  List<Map<String, dynamic>> _uniqueReceivers = [];
  bool _isChildDropdownVisible = false;
  bool _isActivityDropdownVisible = false;

  // 활동 유형 목록
  final List<Map<String, String>> _activityTypes = [
    {'id': 'all', 'name': '전체'},
    {'id': 'mission', 'name': '미션'},
    {'id': 'challenge', 'name': '챌린지'},
    {'id': 'goal', 'name': '목표'},
  ];

  // 드롭다운 버튼의 GlobalKey 추가
  final GlobalKey _childButtonKey = GlobalKey();
  final GlobalKey _activityButtonKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
    _loadSentHistory();
  }

  // 날짜 범위 상태 변수 추가
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 365));
  DateTime _endDate = DateTime.now();
  bool _isAllPeriod = true; // 전체 기간 선택 여부

  // 필터링 카테고리 상태
  final String _selectedCategory = '전체'; // 기본값은 '전체'

  // 받는 사람 목록 추출
  void _updateUniqueReceivers() {
    final Set<String> receiverIds = {};
    _uniqueReceivers =
        _latestAccountsData
            .where((item) {
              final receiverId = item['receiverId']?.toString() ?? '';
              if (receiverIds.contains(receiverId)) return false;
              receiverIds.add(receiverId);
              return true;
            })
            .map((item) {
              return {
                'receiverId': item['receiverId']?.toString() ?? '',
                'receiverName': item['receiverName'] ?? '알 수 없는 사용자',
              };
            })
            .toList();
  }

  // 필터링된 내역 가져오기
  List<Map<String, dynamic>> get filteredHistory {
    if (_selectedReceiverId == null) return _latestAccountsData;
    return _latestAccountsData.where((item) {
      return item['receiverId']?.toString() == _selectedReceiverId;
    }).toList();
  }

  // 총액 계산 - 필터링된 내역 기준
  int get totalPoints {
    int total = 0;
    for (var item in filteredHistory) {
      try {
        if (item['pointAmount'] != null) {
          total += int.parse(item['pointAmount'].toString());
        }
      } catch (e) {
        print('금액 변환 오류: $e');
      }
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          title: const Text(
            '용돈 지급 내역',
            style: TextStyle(
              color: Colors.black,
              fontSize: 14,
              fontFamily: 'Pretendard-Bold',
            ),
          ),
          leading: IconButton(
            icon: Image.asset(
              'assets/icons/parent/뒤로가기.png',
              width: 20,
              height: 20,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Stack(
          children: [
            Column(
              children: [
                // 총 포인트 정보 카드
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(color: Colors.white),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedReceiverId == null
                            ? '오늘까지 보낸 총 포인트가'
                            : '${_uniqueReceivers.firstWhere((r) => r['receiverId'] == _selectedReceiverId, orElse: () => {'receiverName': ''})['receiverName']}님에게 보낸 총 포인트가',
                        style: TextStyle(
                          color: const Color(0xFF202020),
                          fontSize: 14,
                          fontFamily: 'Pretendard-Regular',
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '${_formatCurrency(totalPoints)}원',
                        style: TextStyle(
                          color: const Color(0xFF202020),
                          fontSize: 24,
                          fontFamily: 'Pretendard-Bold',
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '지난 달보다 + 113,000원을 더 보냈어요!',
                        style: TextStyle(
                          color: const Color(0xFF999999),
                          fontSize: 12,
                          fontFamily: 'Pretendard-Light',
                        ),
                      ),
                    ],
                  ),
                ),

                // 프로그레스바 섹션
                _buildProgressBarsSection(),

                // 전체 내역 수 및 검색 헤더
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            '전체 내역 ',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 13,
                              fontFamily: 'Pretendard-Medium',
                            ),
                          ),
                          Text(
                            '${filteredHistory.length}',
                            style: TextStyle(
                              color: const Color(0xFF3A88F4),
                              fontSize: 13,
                              fontFamily: 'Pretendard-SemiBold',
                            ),
                          ),
                        ],
                      ),
                      Image.asset(
                        'assets/icons/my/필터.png',
                        width: 20,
                        height: 20,
                      ),
                    ],
                  ),
                ),

                // 필터 버튼들
                Container(
                  width: double.infinity,
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      // 모든 자녀 버튼
                      PopupMenuButton<String>(
                        onSelected: (String value) {
                          setState(() {
                            _selectedReceiverId = value == 'all' ? null : value;
                          });
                        },
                        offset: Offset(0, 40),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        itemBuilder:
                            (BuildContext context) => <PopupMenuEntry<String>>[
                              PopupMenuItem<String>(
                                value: 'all',
                                height: 36,
                                child: Text(
                                  '모든 자녀',
                                  style: TextStyle(
                                    color:
                                        _selectedReceiverId == null
                                            ? Color(0xFF3A88F4)
                                            : Color(0xFF202020),
                                    fontSize: 12,
                                    fontFamily: 'Pretendard-Medium',
                                  ),
                                ),
                              ),
                              ..._uniqueReceivers.map((receiver) {
                                return PopupMenuItem<String>(
                                  value: receiver['receiverId'].toString(),
                                  height: 36,
                                  child: Text(
                                    receiver['receiverName'],
                                    style: TextStyle(
                                      color:
                                          _selectedReceiverId ==
                                                  receiver['receiverId']
                                                      .toString()
                                              ? Color(0xFF3A88F4)
                                              : Color(0xFF202020),
                                      fontSize: 12,
                                      fontFamily: 'Pretendard-Medium',
                                    ),
                                  ),
                                );
                              }).toList(),
                            ],
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: ShapeDecoration(
                            color: const Color(0xFF5C697E),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _selectedReceiverId == null
                                    ? '모든 자녀'
                                    : _uniqueReceivers.firstWhere(
                                      (r) =>
                                          r['receiverId'].toString() ==
                                          _selectedReceiverId,
                                      orElse: () => {'receiverName': '모든 자녀'},
                                    )['receiverName'],
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontFamily: 'Pretendard-Light',
                                  letterSpacing: -0.22,
                                ),
                              ),
                              SizedBox(width: 6),
                              Image.asset(
                                'assets/icons/parent/my/point/expand_button.png',
                                width: 10,
                                height: 10,
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      // 활동별 버튼
                      PopupMenuButton<String>(
                        onSelected: (String value) {
                          setState(() {
                            _selectedActivityType =
                                value == 'all' ? null : value;
                          });
                        },
                        offset: Offset(0, 40),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        itemBuilder:
                            (BuildContext context) => <PopupMenuEntry<String>>[
                              ..._activityTypes.map((type) {
                                return PopupMenuItem<String>(
                                  value: type['id'],
                                  height: 36,
                                  child: Text(
                                    type['name']!,
                                    style: TextStyle(
                                      color:
                                          _selectedActivityType == type['id']
                                              ? Color(0xFF3A88F4)
                                              : Color(0xFF202020),
                                      fontSize: 12,
                                      fontFamily: 'Pretendard-Medium',
                                    ),
                                  ),
                                );
                              }).toList(),
                            ],
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: ShapeDecoration(
                            color: const Color(0xFF5C697E),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _selectedActivityType == null
                                    ? '활동별'
                                    : _activityTypes.firstWhere(
                                      (t) => t['id'] == _selectedActivityType,
                                      orElse: () => {'name': '활동별'},
                                    )['name']!,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontFamily: 'Pretendard-Light',
                                  letterSpacing: -0.22,
                                ),
                              ),
                              SizedBox(width: 6),
                              Image.asset(
                                'assets/icons/parent/my/point/expand_button.png',
                                width: 10,
                                height: 10,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 내역 리스트
                Expanded(
                  child:
                      _isLatestAccountsLoading
                          ? const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF5D9EFF),
                            ),
                          )
                          : _latestAccountsError != null
                          ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '내역을 불러오지 못했습니다',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 14,
                                    fontFamily: 'Pretendard-Medium',
                                  ),
                                ),
                                SizedBox(height: 8),
                                ElevatedButton(
                                  onPressed: _loadSentHistory,
                                  child: Text('다시 시도'),
                                ),
                              ],
                            ),
                          )
                          : filteredHistory.isEmpty
                          ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '보낸 포인트 내역이 없습니다',
                                  style: TextStyle(
                                    color: Color(0xFF999999),
                                    fontSize: 14,
                                    fontFamily: 'Pretendard-Medium',
                                  ),
                                ),
                              ],
                            ),
                          )
                          : ListView.builder(
                            itemCount: filteredHistory.length,
                            itemBuilder: (context, index) {
                              final item = filteredHistory[index];

                              // 날짜 처리
                              DateTime? date;
                              try {
                                date = DateTime.parse(item['sentAt'] ?? '');
                              } catch (e) {
                                print('날짜 변환 오류: $e');
                                date = DateTime.now();
                              }

                              final formattedDate =
                                  '${date.month}월 ${date.day}일 ${_getWeekday(date.weekday)}요일';

                              if (index == 0 || _shouldShowDateHeader(index)) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildDateHeader(formattedDate),
                                    _buildHistoryItem(
                                      title:
                                          item['receiverName'] ?? '알 수 없는 사용자',
                                      amount:
                                          '-${_formatCurrency(int.parse(item['pointAmount']?.toString() ?? '0'))}원',
                                      date:
                                          '${item['message'] ?? ''} · ${_formatTime(date)}',
                                      totalAmount:
                                          '${_formatCurrency(int.parse(item['remainingPoint']?.toString() ?? '0'))}원',
                                    ),
                                  ],
                                );
                              }

                              return _buildHistoryItem(
                                title: item['receiverName'] ?? '알 수 없는 사용자',
                                amount:
                                    '-${_formatCurrency(int.parse(item['pointAmount']?.toString() ?? '0'))}원',
                                date:
                                    '${item['message'] ?? ''} · ${_formatTime(date)}',
                                totalAmount:
                                    '${_formatCurrency(int.parse(item['remainingPoint']?.toString() ?? '0'))}원',
                              );
                            },
                          ),
                ),
              ],
            ),
          ],
        ),
        bottomNavigationBar: const ParentBottomNavigationBar(selectedIndex: 4),
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

  // 시간 포맷팅 (HH:mm)
  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  // 금액 포맷팅 (천 단위 콤마)
  String _formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  // 내역 아이템 수정
  Widget _buildHistoryItem({
    required String title,
    required String amount,
    required String date,
    required String totalAmount,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 제목 및 금액
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: Color(0xFF001F55),
                    fontSize: 13,
                    fontFamily: 'Pretendard-Regular',
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                amount,
                style: TextStyle(
                  color: Color(0xFFFF6B6B),
                  fontSize: 13,
                  fontFamily: 'Pretendard-Medium',
                ),
              ),
            ],
          ),

          const SizedBox(height: 4),

          // 날짜 및 총액
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                date,
                style: TextStyle(
                  color: Color(0xFF8490A3),
                  fontSize: 11,
                  fontFamily: 'Pretendard-Light',
                ),
              ),
              Text(
                totalAmount,
                style: TextStyle(
                  color: Color(0xFF8490A3),
                  fontSize: 11,
                  fontFamily: 'Pretendard-Light',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 날짜 헤더 수정
  Widget _buildDateHeader(String date) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 8, 20, 4),
      alignment: Alignment.centerLeft,
      child: Text(
        date,
        style: TextStyle(
          color: Color(0xFF8490A3),
          fontSize: 11,
          fontFamily: 'Pretendard-Light',
        ),
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
                      // 미션 프로그레스바 (40%)
                      Expanded(
                        flex: 40,
                        child: Container(
                          height: 12,
                          decoration: BoxDecoration(
                            color: const Color(0xFF146AFF),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),

                      // 여백 추가
                      SizedBox(width: 2),

                      // 챌린지 프로그레스바 (35%)
                      Expanded(
                        flex: 35,
                        child: Container(
                          height: 12,
                          decoration: BoxDecoration(
                            color: const Color(0xFF10CB86),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),

                      // 여백 추가
                      SizedBox(width: 2),

                      // 목표 프로그레스바 (25%)
                      Expanded(
                        flex: 25,
                        child: Container(
                          height: 12,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD27F),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 16),

                  // 범례 - 미션 보상, 챌린지 보상, 목표 달성 보상을 균등하게 배치
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
                                '미션 50,000원',
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
                                '챌린지 43,750원',
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
                                '목표 31,250원',
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

  // 보낸 포인트 내역 로드
  Future<void> _loadSentHistory() async {
    try {
      setState(() {
        _isLatestAccountsLoading = true;
        _latestAccountsError = null;
      });

      final response = await PaymentService.getSentPointHistory(pageNumber: 0);

      print('보낸 포인트 내역 API 응답: $response');

      if (mounted) {
        setState(() {
          if (response.containsKey('data') && response['data'] is List) {
            _latestAccountsData = List<Map<String, dynamic>>.from(
              response['data'],
            );
            print('변환된 데이터: $_latestAccountsData');
          } else {
            _latestAccountsData = [];
          }
          _isLatestAccountsLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _latestAccountsError = e.toString();
          _isLatestAccountsLoading = false;
          _latestAccountsData = [];
        });
      }
      print('보낸 포인트 내역 로딩 오류: $e');
    }
  }

  // 요일 반환 함수
  String _getWeekday(int weekday) {
    const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    return weekdays[weekday - 1];
  }

  // 날짜 헤더 표시 여부 확인
  bool _shouldShowDateHeader(int index) {
    if (index == 0) return true;

    try {
      final currentDate = DateTime.parse(
        _latestAccountsData[index]['sentAt'] ?? '',
      );
      final previousDate = DateTime.parse(
        _latestAccountsData[index - 1]['sentAt'] ?? '',
      );

      return currentDate.year != previousDate.year ||
          currentDate.month != previousDate.month ||
          currentDate.day != previousDate.day;
    } catch (e) {
      print('날짜 비교 오류: $e');
      return false;
    }
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
