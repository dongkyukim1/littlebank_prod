import 'package:flutter/material.dart';
import '../../../services/auth_service.dart';
import '../../../services/mission_service.dart';
import 'mission_section.dart';
import '../my/charge/parent_charge_screen.dart';
import '../my/balance/parent_account_balance_screen.dart';

class AllowanceCard extends StatefulWidget {
  final Map<String, dynamic>? selectedChild;

  const AllowanceCard({super.key, this.selectedChild});

  @override
  State<AllowanceCard> createState() => _AllowanceCardState();
}

class _AllowanceCardState extends State<AllowanceCard> {
  bool _isExpanded = true; // 기본 상태는 펼쳐짐

  // 사용자 정보 및 적립금 데이터
  Map<String, dynamic>? _userInfo;
  bool _isLoading = true;
  String _userName = '';
  int _currentBalance = 0; // 현재 적립금
  int _pendingReward = 0; // 대기 중인 보상금
  bool _hasAccountInfo = false; // 계좌 정보 연결 여부

  // 미션 관련 데이터
  List<MissionResponse> _inProgressMissions = [];
  bool _isLoadingMissions = false;
  String? _missionError;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void didUpdateWidget(AllowanceCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 선택된 자녀가 변경되면 미션 데이터 다시 로드
    if (widget.selectedChild != oldWidget.selectedChild) {
      _loadMissionData();
    }
  }

  // 사용자 데이터 로드
  Future<void> _loadUserData() async {
    try {
      final userInfo = await AuthService.getUserInfo();

      // dart 은행 정보가 있는지 확인하여 계좌 연결 상태 설정
      bool hasAccountInfo = false;
      if (userInfo != null) {
        final bankName = userInfo['bankName'];
        final bankAccount = userInfo['bankAccount'];
        final bankCode = userInfo['bankCode'];

        // 은행명, 계좌번호, 은행코드가 모두 있으면 계좌 연결된 것으로 판단
        hasAccountInfo =
            bankName != null &&
            bankName.toString().isNotEmpty &&
            bankAccount != null &&
            bankAccount.toString().isNotEmpty &&
            bankCode != null &&
            bankCode.toString().isNotEmpty;
      }

      // 사용자 적립금 정보 가져오기 - userInfo에서 point 값 직접 사용
      int currentBalance = 0;
      if (userInfo != null && userInfo['point'] != null) {
        currentBalance = userInfo['point'] ?? 0;
        print('사용자 현재 적립금 (userInfo에서): $currentBalance원');
      } else {
        print('userInfo에 point 정보가 없어서 0으로 설정');
      }

      setState(() {
        _userInfo = userInfo;
        _userName = userInfo?['name'] ?? '사용자';
        _hasAccountInfo = hasAccountInfo;
        _currentBalance = currentBalance;
        _isLoading = false;
      });

      print('사용자 정보 로드 완료: $_userName');
      print('계좌 연결 상태: $_hasAccountInfo');
      if (hasAccountInfo) {
        print('연결된 은행: ${userInfo!['bankName']}');
        print('계좌번호: ${userInfo['bankAccount']}');
      }
      print('현재 적립금: $_currentBalance원');

      // 사용자 정보 로드 후 미션 데이터도 로드
      await _loadMissionData();
    } catch (e) {
      print('사용자 정보 로드 실패: $e');
      setState(() {
        _userName = '사용자';
        _hasAccountInfo = false;
        _currentBalance = 0;
        _isLoading = false;
      });
    }
  }

  // 미션 데이터 로드
  Future<void> _loadMissionData() async {
    if (widget.selectedChild == null) {
      print('선택된 자녀가 없어서 미션 데이터를 로드하지 않습니다.');
      setState(() {
        _inProgressMissions = [];
        _pendingReward = 0;
        _isLoadingMissions = false;
      });
      return;
    }

    try {
      setState(() {
        _isLoadingMissions = true;
        _missionError = null;
      });

      // userId를 우선적으로 사용하고, 없으면 familyMemberId를 사용
      final childId =
          widget.selectedChild!['userId'] ??
          widget.selectedChild!['familyMemberId'];

      if (childId == null) {
        throw Exception('자녀 ID를 찾을 수 없습니다');
      }

      print('미션 데이터 로드 시작 - 자녀 ID: $childId (userId 우선)');

      final missionsData = await MissionService.getParentChildMissions(
        childId: childId,
        page: 0,
      );

      if (missionsData != null && missionsData['data'] != null) {
        final List<dynamic> missionList = missionsData['data'];

        // 미션 응답 객체로 변환하고 진행 중인 미션만 필터링
        final List<MissionResponse> allMissions =
            missionList
                .map((missionJson) => MissionResponse.fromJson(missionJson))
                .toList();

        // 진행 중인 미션 (ACCEPT 상태)만 필터링
        final inProgressMissions =
            allMissions
                .where((mission) => mission.status == MissionStatus.ACCEPT)
                .toList();

        // 최신순으로 정렬 (시작일 기준)
        inProgressMissions.sort((a, b) => b.startDate.compareTo(a.startDate));

        // 대기 중인 보상금 계산 (전체 진행 중인 미션 기준)
        final pendingReward = inProgressMissions.fold<int>(
          0,
          (sum, mission) => sum + mission.reward,
        );

        // 표시할 미션은 최신순 3개만
        final displayMissions = inProgressMissions.take(3).toList();

        setState(() {
          _inProgressMissions = displayMissions;
          _pendingReward = pendingReward;
          _isLoadingMissions = false;
        });

        print(
          '미션 데이터 로드 완료 - 전체: ${allMissions.length}개, 진행 중: ${inProgressMissions.length}개, 대기 보상: ${pendingReward}원',
        );
      } else {
        print('미션 데이터가 없습니다.');
        setState(() {
          _inProgressMissions = [];
          _pendingReward = 0;
          _isLoadingMissions = false;
        });
      }
    } catch (e) {
      print('미션 데이터 로드 실패: $e');
      setState(() {
        _missionError = '미션 정보를 불러오는데 실패했습니다.';
        _inProgressMissions = [];
        _pendingReward = 0;
        _isLoadingMissions = false;
      });
    }
  }

  // 적립금 데이터만 새로 고침
  Future<void> _refreshBalance() async {
    try {
      // 사용자 정보를 다시 가져와서 최신 포인트 확인
      final userInfo = await AuthService.getUserInfo();
      int currentBalance = 0;
      
      if (userInfo != null && userInfo['point'] != null) {
        currentBalance = userInfo['point'] ?? 0;
      }

      setState(() {
        _currentBalance = currentBalance;
        _userInfo = userInfo; // 사용자 정보도 업데이트
      });

      print('적립금 새로 고침 완료: $_currentBalance원');
    } catch (e) {
      print('적립금 새로 고침 실패: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // 로딩 중일 때 처리
    if (_isLoading) {
      return Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Color(0x35000000),
              blurRadius: 8,
              offset: Offset(3, 4),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5D9EFF)),
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Color(0x35000000),
            blurRadius: 8,
            offset: Offset(3, 4),
            spreadRadius: 0,
          ),
        ],
        borderRadius: BorderRadius.circular(24),
      ),
      child: Container(
        width: double.infinity,
        decoration: ShapeDecoration(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: const ShapeDecoration(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.7,
                        child: Text(
                          '${_userName}님의 현재 보유 중인 적립금',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: const Color(0xFF202020),
                            fontSize: 16,
                            fontFamily: 'Pretendard-Bold',
                            letterSpacing: -0.72,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _isExpanded = !_isExpanded;
                          });
                        },
                        child: Transform.rotate(
                          angle: _isExpanded ? 0 : 3.14159, // 180도 회전 (π 라디안)
                          child: Image.asset(
                            'assets/icons/parent/확장.png',
                            width: 24,
                            height: 24,
                            color: const Color(0xFF9B9B9B),
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        _currentBalance > 0
                            ? _currentBalance.toString().replaceAllMapped(
                              RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                              (Match m) => '${m[1]},',
                            )
                            : '0',
                        style: TextStyle(
                          color: const Color(0xFF146AFF),
                          fontSize: 26,
                          fontFamily: 'Pretendard-Bold',
                          letterSpacing: -1.12,
                        ),
                      ),
                      Text(
                        '원',
                        style: TextStyle(
                          color: const Color(0xFF202020),
                          fontSize: 18,
                          fontFamily: 'Pretendard-Bold',
                          letterSpacing: -0.72,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: const BoxDecoration(color: Colors.white),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 계좌 정보가 있을 때: 포인트 충전/내역보기 버튼
                  if (_hasAccountInfo)
                    SizedBox(
                      width: double.infinity,
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ParentChargeScreen(),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF5FF),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '포인트 충전',
                                          style: TextStyle(
                                            color: const Color(0xFF001F55),
                                            fontSize: 13, // 12 -> 10 (2px 감소)
                                            fontFamily: 'Pretendard-Bold',
                                            letterSpacing: -0.32,
                                          ),
                                        ),
                                        Image.asset(
                                          'assets/icons/parent/들어가기.png',
                                          width: 16,
                                          height: 16,
                                          fit: BoxFit.contain,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '미리 금액을 충전하고 바로 이용해봐요',
                                      style: TextStyle(
                                        color: const Color(0xFF666666),
                                        fontSize: 10, // 10 -> 8 (2px 감소)
                                        fontFamily: 'Pretendard-Light',
                                        letterSpacing: -0.24,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ParentAccountBalanceScreen(),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF5FF),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '내역 보기',
                                          style: TextStyle(
                                            color: const Color(0xFF001F55),
                                            fontSize: 13, // 12 -> 10 (2px 감소)
                                            fontFamily: 'Pretendard-Bold',
                                            letterSpacing: -0.32,
                                          ),
                                        ),
                                        Image.asset(
                                          'assets/icons/parent/들어가기.png',
                                          width: 16,
                                          height: 16,
                                          fit: BoxFit.contain,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '최근 입출금 내역을\n쉽게 꺼내봐요',
                                      style: TextStyle(
                                        color: const Color(0xFF666666),
                                        fontSize: 10,
                                        fontFamily: 'Pretendard-Light',
                                        letterSpacing: -0.24,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // 계좌 정보가 없을 때: 계좌 연결 안내
                  if (!_hasAccountInfo)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: ShapeDecoration(
                        color: const Color(0xFFE4ECF8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '계좌 연결',
                                  style: TextStyle(
                                    color: const Color(0xFF001F55),
                                    fontSize: 12, // 14 -> 12 (2px 감소)
                                    fontFamily: 'Pretendard-Bold',
                                    letterSpacing: -0.28,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  '충전 계좌를 연결하면 간편하게 이용할 수 있어요',
                                  style: TextStyle(
                                    color: const Color(0xFF8490A3),
                                    fontSize: 10, // 12 -> 10 (2px 감소)
                                    fontFamily: 'Pretendard-Light',
                                    height: 1.50,
                                    letterSpacing: -0.24,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Image.asset(
                            'assets/icons/parent/들어가기.png',
                            width: 16,
                            height: 16,
                            fit: BoxFit.contain,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: ShapeDecoration(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 진행 중인 미션이 있을 때만 보상 텍스트 표시
                      if (_inProgressMissions.isNotEmpty)
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: '미션 완료 후 ',
                                style: TextStyle(
                                  color: const Color(0xFF001F55),
                                  fontSize: 11, // 13 -> 11 (2px 감소)
                                  fontFamily: 'Pretendard-Light',
                                  letterSpacing: -0.32,
                                ),
                              ),
                              TextSpan(
                                text:
                                    _pendingReward > 0
                                        ? '총 ${_pendingReward.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}원'
                                        : '총 0원',
                                style: TextStyle(
                                  color: const Color(0xFF001F55),
                                  fontSize: 11, // 13 -> 11 (2px 감소)
                                  fontFamily: 'Pretendard-Bold',
                                  letterSpacing: -0.32,
                                ),
                              ),
                              TextSpan(
                                text: '을 보상할 거예요!',
                                style: TextStyle(
                                  color: const Color(0xFF001F55),
                                  fontSize: 11, // 13 -> 11 (2px 감소)
                                  fontFamily: 'Pretendard-Light',
                                  letterSpacing: -0.32,
                                ),
                              ),
                            ],
                          ),
                        ),
                      // 진행 중인 미션이 있을 때만 시간 표시
                      if (_inProgressMissions.isNotEmpty)
                        Text(
                          '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')} 기준',
                          style: TextStyle(
                            color: const Color(0xFFCCCCCC),
                            fontSize: 9, // 11 -> 9 (2px 감소)
                            fontFamily: 'Pretendard-Light',
                            letterSpacing: -0.22,
                          ),
                        ),
                    ],
                  ),
                  if (_isExpanded) ...[
                    const SizedBox(height: 8), // 16 -> 8로 줄여서 더 위로 올림
                    // 미션이 없을 때 메인 텍스트 표시 (회색 배경 없음)
                    if (_inProgressMissions.isEmpty ||
                        widget.selectedChild == null) ...[
                      Text(
                        '아이가 진행 중인 미션이 없어요',
                        style: TextStyle(
                          color: const Color(0xFF001F55),
                          fontSize: 14,
                          fontFamily: 'Pretendard-Light',
                          letterSpacing: -0.32,
                        ),
                      ),
                      const SizedBox(height: 8), // 12 -> 8로 줄임
                      // 이미지와 버튼만 회색 배경에 표시
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          vertical: 4,
                        ), // 8 -> 4로 줄임
                        decoration: ShapeDecoration(
                          color: const Color(0xFFE4ECF8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(height: 6), // 8 -> 6으로 줄임
                            Container(
                              width: 36,
                              height: 40,
                              child: Image.asset(
                                'assets/icons/parent/none_mission.png',
                                width: 36,
                                height: 40,
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (context, error, stackTrace) => Container(
                                      width: 36,
                                      height: 40,
                                      color: Colors.grey[300],
                                      child: Icon(
                                        Icons.assignment,
                                        size: 20,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                              ),
                            ),
                            SizedBox(height: 6), // 8 -> 6으로 줄임
                            Text(
                              '아직 참여 중인 미션이 없어요',
                              style: TextStyle(
                                color: const Color(0xFF999999),
                                fontSize: 9,
                                fontFamily: 'Pretendard',
                                fontWeight: FontWeight.w300,
                                letterSpacing: -0.22,
                              ),
                            ),
                            SizedBox(height: 6), // 8 -> 6으로 줄임
                            Center(
                              child: GestureDetector(
                                onTap: () {
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    builder: (BuildContext context) {
                                      return const MissionCreationModal();
                                    },
                                  );
                                },
                                child: Container(
                                  width: 125,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 6,
                                  ), // 8 -> 6으로 줄임
                                  decoration: ShapeDecoration(
                                    color: const Color(0xFF3A88F4),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '미션 생성하기',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontFamily: 'Pretendard-Light',
                                        letterSpacing: -0.24,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 6), // 8 -> 6으로 줄임
                          ],
                        ),
                      ),
                    ],

                    // 미션이 있을 때만 미션 목록 표시
                    if (_inProgressMissions.isNotEmpty &&
                        widget.selectedChild != null)
                      Container(
                        width: double.infinity,
                        decoration: ShapeDecoration(
                          color: const Color(0xFFF5F6F8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Column(children: _buildMissionList()),
                      ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 미션 목록 아이템 행 위젯 (구분자 없는 버전)
  Widget _buildMissionListItemRow(
    String missionType,
    String title,
    String amount,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 왼쪽: 미션 타입 뱃지
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: ShapeDecoration(
              color: const Color(0xFF5D9EFF),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            child: Text(
              missionType,
              style: TextStyle(
                color: Colors.white,
                fontSize: 9, // 11 -> 9 (2px 감소)
                fontFamily: 'Pretendard-Medium',
                letterSpacing: -0.22,
              ),
            ),
          ),

          // 중간: 미션 제목 (Flexible로 감싸서 오버플로우 방지)
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              title,
              style: TextStyle(
                color: const Color(0xFF353535),
                fontSize: 11, // 13 -> 11 (2px 감소)
                fontFamily: 'Pretendard-Medium',
                letterSpacing: -0.26,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // 오른쪽: 금액
          const SizedBox(width: 16),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                amount,
                style: TextStyle(
                  color: const Color(0xFF146AFF),
                  fontSize: 13, // 15 -> 13 (2px 감소)
                  fontFamily: 'Pretendard-Bold',
                  letterSpacing: -0.30,
                ),
              ),
              Text(
                '원',
                style: TextStyle(
                  color: const Color(0xFF202020),
                  fontSize: 10, // 12 -> 10 (2px 감소)
                  fontFamily: 'Pretendard-Bold',
                  letterSpacing: -0.24,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 미션 목록 아이템 위젯 (기존 함수 유지)
  Widget _buildMissionListItem(
    String missionType,
    String title,
    String amount,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: ShapeDecoration(
        color: const Color(0xFFF5F6F8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 왼쪽: 미션 타입 뱃지
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: ShapeDecoration(
              color: const Color(0xFF5D9EFF),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              missionType,
              style: TextStyle(
                color: Colors.white,
                fontSize: 8, // 10 -> 8 (2px 감소)
                fontFamily: 'Pretendard-Light',
                fontWeight: FontWeight.w300,
                letterSpacing: -0.2,
              ),
            ),
          ),

          // 중간: 미션 제목 (오버플로우 방지)
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: const Color(0xFF353535),
                fontSize: 9, // 11 -> 9 (2px 감소)
                fontFamily: 'Pretendard-Medium',
                fontWeight: FontWeight.w500,
                letterSpacing: -0.22,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // 오른쪽: 금액
          const SizedBox(width: 12),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                amount,
                style: TextStyle(
                  color: const Color(0xFF146AFF),
                  fontSize: 12, // 14 -> 12 (2px 감소)
                  fontFamily: 'Pretendard-Bold',
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.28,
                ),
              ),
              Text(
                '원',
                style: TextStyle(
                  color: const Color(0xFF202020),
                  fontSize: 8, // 10 -> 8 (2px 감소)
                  fontFamily: 'Pretendard-Bold',
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildMissionList() {
    // 로딩 중일 때
    if (_isLoadingMissions) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    color: Color(0xFF5D9EFF),
                    strokeWidth: 2,
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  '미션 데이터를 불러오는 중...',
                  style: TextStyle(
                    color: const Color(0xFF999999),
                    fontSize: 10, // 12 -> 10 (2px 감소)
                    fontFamily: 'Pretendard-Light',
                    letterSpacing: -0.24,
                  ),
                ),
              ],
            ),
          ),
        ),
      ];
    }

    // 오류가 발생했을 때
    if (_missionError != null) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Center(
            child: Column(
              children: [
                Text(
                  _missionError!,
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 10, // 12 -> 10 (2px 감소)
                    fontFamily: 'Pretendard-Light',
                    letterSpacing: -0.24,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                GestureDetector(
                  onTap: _loadMissionData,
                  child: Text(
                    '다시 시도',
                    style: TextStyle(
                      color: Color(0xFF5D9EFF),
                      fontSize: 10, // 12 -> 10 (2px 감소)
                      fontFamily: 'Pretendard-Medium',
                      letterSpacing: -0.24,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ];
    }

    // 선택된 자녀가 없거나 진행 중인 미션이 없을 때는 빈 리스트 반환 (상위에서 UI 처리함)
    if (widget.selectedChild == null || _inProgressMissions.isEmpty) {
      return [];
    }

    // 실제 진행 중인 미션 목록 표시
    List<Widget> missionWidgets = [];

    for (int i = 0; i < _inProgressMissions.length; i++) {
      final mission = _inProgressMissions[i];

      // 미션 타입에 따른 표시 텍스트
      String missionTypeText = MissionService.getTypeDisplayName(mission.type);

      // 미션 제목 (과목 정보 제외)
      String missionTitle = mission.title;

      // 보상금을 쉼표로 구분하여 표시
      String rewardText = mission.reward.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      );

      missionWidgets.add(
        _buildMissionListItemRow(missionTypeText, missionTitle, rewardText),
      );
    }

    return missionWidgets;
  }
}
