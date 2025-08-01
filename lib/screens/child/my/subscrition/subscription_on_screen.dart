import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../services/subscription_service.dart';
import '../../../../services/auth_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../../services/relationship_service.dart';
import '../../../../services/kakao_share_service.dart';
import 'dart:math';

class SubscriptionOnScreen extends StatefulWidget {
  const SubscriptionOnScreen({super.key});

  @override
  State<SubscriptionOnScreen> createState() => _SubscriptionOnScreenState();
}

class _SubscriptionOnScreenState extends State<SubscriptionOnScreen> {
  // 선택된 구독권 (기본값: 5인 구독권)
  String _selectedSubscription = '5인 구독권';

  // 구독권 정보 상태
  bool _isLoading = true;
  Map<String, dynamic>? _currentSubscription;
  List<Map<String, dynamic>>? _allSubscriptions;
  List<Map<String, dynamic>> _memberProfiles = [];
  Map<String, dynamic>? _inviteCodesInfo;
  Map<String, dynamic>? _userInfo;

  @override
  void initState() {
    super.initState();
    _loadSubscriptionData();
  }

  // 구독권 데이터 로드
  Future<void> _loadSubscriptionData() async {
    try {
      print('🔍 [자녀구독권관리] 데이터 로드 시작');
      
      // 기존 상태 초기화 (캐시 클리어)
      setState(() {
        _currentSubscription = null;
        _allSubscriptions = null;
        _memberProfiles = [];
        _inviteCodesInfo = null;
      });
      
      // 현재 활성 구독권 조회 (유료/무료 통합)
      print('🔍 [자녀구독권관리] getCurrentActiveSubscription 호출...');
      final activeSubscription = await SubscriptionService.getCurrentActiveSubscription();
      print('🔍 [자녀구독권관리] getCurrentActiveSubscription 결과: $activeSubscription');
      
      final allSubs = await SubscriptionService.getMySubscriptions();
      print('🔍 [자녀구독권관리] 모든 구독권 조회 결과: $allSubs');

      Map<String, dynamic>? currentSub;
      
      if (activeSubscription != null) {
        final subscriptionData = activeSubscription['data'] as Map<String, dynamic>;
        final subscriptionType = activeSubscription['type'] as String;
        print('🔍 [자녀구독권관리] 구독권 타입: $subscriptionType, 데이터: $subscriptionData');
        
        if (subscriptionType == 'paid') {
          // 유료 구독권인 경우
          print('✅ [자녀구독권관리] 유료 구독권 발견');
          currentSub = subscriptionData;
        } else if (subscriptionType == 'free') {
          // 무료 구독권인 경우 - 유료 구독권 형태로 변환
          print('✅ [자녀구독권관리] 무료 구독권 발견 - 변환 중...');
          currentSub = {
            'subscriptionId': subscriptionData['trialId'],
            'seat': 1, // 무료 구독권은 1인용으로 설정
            'left': 0, // 무료 구독권은 추가 멤버 없음
            'endDate': subscriptionData['endDate'],
            'startDate': subscriptionData['startDate'],
            'members': [], // 무료 구독권은 멤버 없음
            'inviteCodes': {}, // 무료 구독권은 쿠폰코드 없음
            'isFree': true, // 무료 구독권 표시
            'used': subscriptionData['used'],
          };
          print('✅ [자녀구독권관리] 무료 구독권 변환 완료: $currentSub');
        }
      } else {
        print('❌ [자녀구독권관리] activeSubscription이 null - 구독권 없음');
      }

      // 구독권이 없는 경우 명시적으로 null 설정
      if (currentSub == null) {
        print('🔄 [자녀구독권관리] 활성 구독권이 없어서 화면 상태 초기화');
        setState(() {
          _currentSubscription = null;
          _allSubscriptions = allSubs;
          _memberProfiles = [];
          _inviteCodesInfo = null;
          _isLoading = false;
          _selectedSubscription = '5인 구독권'; // 기본값으로 리셋
        });
        return;
      }

      // 멤버 프로필 정보 로드
      await _loadMemberProfiles(currentSub);

      // 쿠폰코드 정보 로드 (3인용, 5인용 구독권만)
      await _loadInviteCodes(currentSub);

      // 사용자 정보 로드
      await _loadUserInfo();

      setState(() {
        _currentSubscription = currentSub;
        _allSubscriptions = allSubs;
        _isLoading = false;

        // 현재 구독권에 따라 선택된 구독권 설정
        if (currentSub != null) {
          final isFree = currentSub['isFree'] == true;
          final seat = currentSub['seat'] as int? ?? 1;
          _selectedSubscription = isFree ? '무료 구독권' : '${seat}인 구독권';
        }
      });
    } catch (e) {
      print('구독권 데이터 로드 오류: $e');
      setState(() {
        _currentSubscription = null; // 에러 시에도 명시적으로 null 설정
        _allSubscriptions = null;
        _memberProfiles = [];
        _inviteCodesInfo = null;
        _isLoading = false;
      });
    }
  }

  // 쿠폰코드 정보 로드
  Future<void> _loadInviteCodes(Map<String, dynamic>? subscription) async {
    if (subscription == null) return;

    try {
      final seat = subscription['seat'] as int? ?? 1;
      final isFreeSubscription = subscription['isFree'] == true;

      // 3인용, 5인용 구독권 또는 무료 구독권인 경우 정보 표시
      if (seat > 1 || isFreeSubscription) {
        final inviteInfo = await SubscriptionService.getInviteCodes();
        setState(() {
          _inviteCodesInfo = inviteInfo;
        });
        print('자녀용 구독권 정보 로드 완료: $inviteInfo');

        // 새로운 API로 상세 초대코드 정보 조회 및 터미널 출력 (자녀용)
        await _logDetailedInviteCodeInfo();
      }
    } catch (e) {
      print('쿠폰코드 정보 로드 오류: $e');
    }
  }

  // 상세 초대코드 정보를 터미널에 출력 (자녀용)
  Future<void> _logDetailedInviteCodeInfo() async {
    try {
      print('');
      print('📋 ===== [자녀용] 상세 초대코드 정보 조회 시작 =====');
      
      // 1. 전체 초대코드 목록 조회
      final allCodesList = await SubscriptionService.getInviteCodesList();
      print('🎫 [자녀용] 전체 초대코드 목록: $allCodesList');
      
      if (allCodesList != null && allCodesList.isNotEmpty) {
        print('');
        print('📊 [자녀용] 초대코드 상태별 분석:');
        
        int totalCodes = allCodesList.length;
        int usedCodes = 0;
        int availableCodes = 0;
        
        for (var codeInfo in allCodesList) {
          final code = codeInfo['code'] as String;
          final used = codeInfo['used'] as bool? ?? false;
          final redeemedByName = codeInfo['redeemedByName'] as String?;
          
          if (used) {
            usedCodes++;
            print('   ✅ $code - 사용됨 (${redeemedByName ?? "사용자 정보 없음"})');
          } else {
            availableCodes++;
            print('   🎟️  $code - 사용 가능');
          }
        }
        
        print('');
        print('📈 [자녀용] 초대코드 통계:');
        print('   💯 총 초대코드: $totalCodes개');
        print('   ✅ 사용된 코드: $usedCodes개');
        print('   🎟️  남은 코드: $availableCodes개');
      }
      
      // 2. 사용 가능한 초대코드만 조회
      final availableCodesList = await SubscriptionService.getAvailableInviteCodes();
      print('');
      print('🎟️  [자녀용] 사용 가능한 초대코드만 필터링: $availableCodesList');
      
      // 3. 매칭 정보 조회 (서버 + 클라이언트 전송 기록)
      final matchingInfo = await SubscriptionService.getInviteCodeMatching();
      print('');
      print('🔄 [자녀용] 초대코드 매칭 정보 (서버 + 클라이언트):');
      print('   $matchingInfo');
      
      if (matchingInfo != null) {
        final matchingDetails = matchingInfo['matchingInfo'] as Map<String, dynamic>? ?? {};
        final availableCodesFromMatching = matchingInfo['availableCodes'] as List<dynamic>? ?? [];
        
        print('');
        print('🎯 [자녀용] 매칭 상태별 상세 정보:');
        
        matchingDetails.forEach((code, info) {
          final status = info['status'] as String;
          final details = info['details'] as Map<String, dynamic>? ?? {};
          
          switch (status) {
            case 'used':
              final redeemedByName = details['redeemedByName'] as String?;
              print('   ✅ $code - 사용완료 (${redeemedByName ?? "사용자 정보 없음"})');
              break;
            case 'sent':
              final recipientName = details['recipientName'] as String?;
              final sentAt = details['sentAt'] as String?;
              print('   📤 $code - 전송됨 (받는이: ${recipientName ?? "정보없음"}, 전송시간: ${sentAt ?? "정보없음"})');
              break;
            case 'available':
              print('   🎟️  $code - 전송 가능');
              break;
          }
        });
        
        print('');
        print('🚀 [자녀용] 현재 전송 가능한 초대코드: ${availableCodesFromMatching.length}개');
        if (availableCodesFromMatching.isNotEmpty) {
          print('   코드 목록: ${availableCodesFromMatching.map((c) => c['code']).join(', ')}');
        }
      }
      
      print('📋 ===== [자녀용] 상세 초대코드 정보 조회 완료 =====');
      print('');
      
    } catch (e) {
      print('❌ [자녀용] 상세 초대코드 정보 조회 중 오류: $e');
    }
  }

  // 멤버 프로필 정보 로드
  Future<void> _loadMemberProfiles(Map<String, dynamic>? subscription) async {
    if (subscription == null) return;

    try {
      final members = subscription['members'] as List<dynamic>? ?? [];
      final seat = subscription['seat'] as int? ?? 1;

      // 현재 사용자 정보 가져오기
      final currentUserId = await AuthService.getCurrentUserId();
      final currentUserInfo = await AuthService.getUserInfo();

      print('🔍 [자녀-프로필로드] 현재 사용자 ID: $currentUserId');
      print('🔍 [자녀-프로필로드] 멤버 리스트: $members');
      print('🔍 [자녀-프로필로드] 총 좌석: $seat');

      List<Map<String, dynamic>> profiles = [];

      // 구독권 소유자 (나) 추가
      if (currentUserInfo != null) {
        profiles.add({
          'userId': currentUserId,
          'name': currentUserInfo['realName'] ?? '나',
          'profileImage': currentUserInfo['profileImage'],
          'isOwner': true,
        });
      }

      // 실제 멤버들 정보 가져오기
      for (int i = 0; i < members.length; i++) {
        final memberId = members[i];
        
        // 현재 사용자가 아닌 경우에만 추가
        if (memberId != currentUserId) {
          try {
            // 실제 멤버 정보 API 호출
            final memberInfo = await _getMemberInfo(memberId);
            profiles.add({
              'userId': memberId,
              'name': (memberInfo?['realName']?.toString().isNotEmpty == true)
                  ? memberInfo!['realName']
                  : (memberInfo?['name']?.toString().isNotEmpty == true
                      ? memberInfo!['name']
                      : 'ID:$memberId'),
              'profileImage': memberInfo?['profileImagePath'],
              'isOwner': false,
            });
          } catch (e) {
            print('멤버 $memberId 정보 로드 실패: $e');
            profiles.add({
              'userId': memberId,
              'name': 'ID:$memberId',
              'profileImage': null,
              'isOwner': false,
            });
          }
        }
      }

      // 빈 자리 추가
      final currentMemberCount = profiles.length;
      for (int i = currentMemberCount; i < seat; i++) {
        profiles.add({
          'userId': null,
          'name': null,
          'profileImage': null,
          'isOwner': false,
          'isEmpty': true,
        });
      }

      setState(() {
        _memberProfiles = profiles;
      });
    } catch (e) {
      print('멤버 프로필 로드 오류: $e');
    }
  }

  // 멤버 정보 가져오기 API
  Future<Map<String, dynamic>?> _getMemberInfo(int userId) async {
    // RelationshipService를 통해 userId로 유저 상세 정보 조회
    return await RelationshipService.getUserInfo(userId);
  }

  // 사용자 정보 로드
  Future<void> _loadUserInfo() async {
    try {
      final userInfo = await AuthService.getUserInfo();
      setState(() {
        _userInfo = userInfo;
      });
    } catch (e) {
      print('사용자 정보 로드 오류: $e');
    }
  }

  // 구독 종료일 포맷팅
  String _getFormattedEndDate() {
    print('🔍 [날짜포맷팅] _currentSubscription: $_currentSubscription');
    
    if (_currentSubscription == null) {
      print('🔍 [날짜포맷팅] _currentSubscription이 null이므로 "정보 없음" 반환');
      return '정보 없음';
    }

    try {
      final endDateStr = _currentSubscription!['endDate'] as String?;
      print('🔍 [날짜포맷팅] endDateStr: $endDateStr');
      
      if (endDateStr != null) {
        final endDate = DateTime.parse(endDateStr);
        final formattedDate = '${endDate.year % 100}.${endDate.month}.${endDate.day}일까지 이용';
        print('🔍 [날짜포맷팅] 원본 날짜: $endDate, 포맷된 날짜: $formattedDate');
        return formattedDate;
      }
    } catch (e) {
      print('날짜 포맷팅 오류: $e');
    }
    
    print('🔍 [날짜포맷팅] endDateStr이 null이므로 "정보 없음" 반환');
    return '정보 없음';
  }

  // 남은 일수 계산
  int _getDaysLeft() {
    if (_currentSubscription == null) return 0;

    try {
      final endDateStr = _currentSubscription!['endDate'] as String?;
      if (endDateStr != null) {
        final endDate = DateTime.parse(endDateStr);
        final now = DateTime.now();
        final difference = endDate.difference(now);
        return difference.inDays;
      }
    } catch (e) {
      print('남은 일수 계산 오류: $e');
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    // 화면 크기 정보 가져오기
    final screenSize = MediaQuery.of(context).size;
    final horizontalPadding = screenSize.width * 0.04; // 4% of screen width

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF5D9EFF)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          '구독권 관리',
          style: TextStyle(
            color: Colors.black,
            fontSize: 14,
            fontFamily: 'Pretendard-Bold',
            fontWeight: FontWeight.w700,
            letterSpacing: -0.32,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Image.asset(
              'assets/icons/parent/my/home.png',
              width: 24,
              height: 24,
            ),
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 24), // 상단 여백 추가
            // 상단 구독권 정보 섹션
            Container(
              width: screenSize.width,
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              decoration: const BoxDecoration(color: Colors.white),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: ShapeDecoration(
                      color: const Color(0xFF5D9EFF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // 로고 이미지
                        Image.asset(
                          'assets/icons/sub_logo.png',
                          width: screenSize.width * 0.2, // 20% of screen width
                          height: screenSize.width * 0.2,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 16),
                        // 구독권 정보
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              _currentSubscription?['isFree'] == true
                                  ? '현재 이용 중인 무료 구독권은'
                                  : '현재 이용 중인 ${_currentSubscription?['seat']}인 구독권은',
                              style: const TextStyle(
                                color: Color(0xFF202020),
                                fontSize: 16,
                                fontFamily: 'Pretendard-Bold',
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.72,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  _getFormattedEndDate(),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontFamily: 'Pretendard-Light',
                                    fontWeight: FontWeight.w300,
                                    letterSpacing: -0.28,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  width: 2,
                                  height: 2,
                                  decoration: const ShapeDecoration(
                                    color: Colors.white,
                                    shape: OvalBorder(),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 2,
                                  ),
                                  decoration: ShapeDecoration(
                                    color: const Color(0xFF146AFF),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                  ),
                                  child: Text(
                                    'D-${_getDaysLeft()}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontFamily: 'Pretendard-Light',
                                      fontWeight: FontWeight.w300,
                                      letterSpacing: -0.22,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            // 남은 자리 메시지 또는 무료 구독권 안내
                            if (_currentSubscription != null &&
                                _currentSubscription!['isFree'] == true)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: ShapeDecoration(
                                  color: const Color(0xFF10CB86),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text(
                                  '무료 체험 중이에요! 유료 구독으로 업그레이드하여 더 많은 혜택을 누려보세요',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontFamily: 'Pretendard-Light',
                                    fontWeight: FontWeight.w300,
                                    letterSpacing: -0.22,
                                  ),
                                ),
                              )
                            else if (_currentSubscription != null &&
                                _currentSubscription!['seat'] > 1 &&
                                _currentSubscription!['left'] > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: ShapeDecoration(
                                  color: const Color(0xFF5D6A7F),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text.rich(
                                  TextSpan(
                                    children: [
                                      const TextSpan(
                                        text: '아직 ',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontFamily: 'Pretendard-Light',
                                          fontWeight: FontWeight.w300,
                                          letterSpacing: -0.22,
                                        ),
                                      ),
                                      TextSpan(
                                        text:
                                            '${_currentSubscription!['left']}자리',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontFamily: 'Pretendard-Medium',
                                          fontWeight: FontWeight.w500,
                                          letterSpacing: -0.22,
                                        ),
                                      ),
                                      const TextSpan(
                                        text: '가 남아있어요!',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontFamily: 'Pretendard-Light',
                                          fontWeight: FontWeight.w300,
                                          letterSpacing: -0.22,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // 멤버 섹션 (1인 구독권이 아니고 무료 구독권이 아닌 경우에만 표시)
            if (_currentSubscription != null &&
                _currentSubscription!['seat'] > 1 &&
                _currentSubscription!['isFree'] != true)
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                '추가한 멤버와 같이 이용할 수 있어요',
                                style: TextStyle(
                                  color: Color(0xFF202020),
                                  fontSize: 16,
                                  fontFamily: 'Pretendard-Bold',
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.24,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '초대하기를 통해 가족 멤버로 추가해 보세요!',
                            style: TextStyle(
                              color: Color(0xFF999999),
                              fontSize: 14,
                              fontFamily: 'Pretendard-Light',
                              fontWeight: FontWeight.w300,
                              letterSpacing: -0.24,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 멤버 프로필 그리드
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(children: _buildMemberCards()),
                      ),
                    ),
                  ],
                ),
              ),

            if (_currentSubscription != null &&
                _currentSubscription!['seat'] > 1)
              const SizedBox(height: 20),

            // 구독권 변경 섹션
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          '다른 구독권을 둘러볼까요?',
                          style: TextStyle(
                            color: Color(0xFF202020),
                            fontSize: 16,
                            fontFamily: 'Pretendard-Bold',
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.72,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '다른 구독권의 가격을 알려드릴게요!',
                          style: TextStyle(
                            color: Color(0xFF999999),
                            fontSize: 12,
                            fontFamily: 'Pretendard-Light',
                            fontWeight: FontWeight.w300,
                            letterSpacing: -0.28,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // 구독권 옵션들
                  Column(
                    children: [
                      _buildSubscriptionOption(
                        title: '1인 구독권',
                        price: '3,500',
                        isSelected: false,
                      ),
                      const SizedBox(height: 32),
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          _buildSubscriptionOption(
                            title: '5인 구독권',
                            price: '9,500',
                            isSelected: false,
                          ),
                          Positioned(
                            top: -20,
                            left: 10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: ShapeDecoration(
                                color: const Color(0xFFFFA63D),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                '52% 할인!',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontFamily: 'Pretendard-Bold',
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.24,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // 함께 이용하면 더 커지는 혜택 섹션 (1인 구독권인 경우나 무료 구독권인 경우에만 표시)
            if (_currentSubscription != null &&
                (_currentSubscription!['seat'] == 1 || _currentSubscription!['isFree'] == true))
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '함께 이용하면 더 커지는 혜택',
                      style: TextStyle(
                        color: Color(0xFF202020),
                        fontSize: 14,
                        fontFamily: 'Pretendard-Bold',
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.72,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '다른 구독권의 장점을 알려드릴게요!',
                      style: TextStyle(
                        color: Color(0xFF999999),
                        fontSize: 10,
                        fontFamily: 'Pretendard-Light',
                        fontWeight: FontWeight.w300,
                        letterSpacing: -0.28,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 혜택 정보 카드
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: ShapeDecoration(
                        color: const Color(0xFFF8F9FA),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Image.asset(
                                'assets/icons/parent/my/inform.png',
                                width: 16,
                                height: 16,
                                fit: BoxFit.contain,
                              ),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  '구독권 업그레이드 시, 가족들과 함께 이용할 수 있어요',
                                  style: TextStyle(
                                    color: Color(0xFF202020),
                                    fontSize: 11,
                                    fontFamily: 'Pretendard-Medium',
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: -0.28,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            '가족들과 함께 구독하고 리틀뱅크에서 많은 활동에 참여해 보세요.',
                            style: TextStyle(
                              color: Color(0xFF666666),
                              fontSize: 10,
                              fontFamily: 'Pretendard-Light',
                              fontWeight: FontWeight.w300,
                              letterSpacing: -0.24,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // 혜택 리스트
                          Column(
                            children: [
                              _buildBenefitItem(
                                '• 참여하고 싶은 챌린지를 직접 탐색하고, 스스로 목표를 설정하여 부모님께 원하는 보상금을 요청해 보세요',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // 초대하기 버튼 (3인, 5인 구독권에서 자리가 남았을 때, 무료 구독권은 제외)
            if (_currentSubscription != null &&
                _currentSubscription!['seat'] > 1 &&
                _currentSubscription!['isFree'] != true &&
                _hasAvailableSeats())
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    // 연락처로 초대하기 버튼
                    GestureDetector(
                      onTap: _inviteNewMember,
                      child: Container(
                        width: 359,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 16,
                        ),
                        decoration: ShapeDecoration(
                          color: const Color(0xFF3A88F4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: const [
                            Text(
                              '연락처로 초대하기',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontFamily: 'Pretendard-Medium',
                                fontWeight: FontWeight.w500,
                                letterSpacing: -0.28,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // 개별 쿠폰 코드 전송 버튼
                    GestureDetector(
                      onTap: _showIndividualInviteDialog,
                      child: Container(
                        width: 359,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 16,
                        ),
                        decoration: ShapeDecoration(
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            side: const BorderSide(
                              width: 1,
                              color: Color(0xFF3A88F4),
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: const [
                            Text(
                              '개별 쿠폰 코드로 초대하기',
                              style: TextStyle(
                                color: Color(0xFF3A88F4),
                                fontSize: 14,
                                fontFamily: 'Pretendard-Medium',
                                fontWeight: FontWeight.w500,
                                letterSpacing: -0.28,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // 안내문 (유료 구독권이고 다인용인 경우에만 표시)
            if (_currentSubscription != null &&
                _currentSubscription!['seat'] > 1 &&
                _currentSubscription!['isFree'] != true)
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    // 첫 번째 안내문
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: ShapeDecoration(
                        color: const Color(0xFFE7ECF6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Image.asset(
                                'assets/icons/my/Fill_inform.png',
                                width: 16,
                                height: 16,
                                fit: BoxFit.contain,
                              ),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  '현재 화면에서 함께 구독 중인 멤버들을 볼 수 있습니다.',
                                  style: TextStyle(
                                    color: Color(0xFF666666),
                                    fontSize: 11,
                                    fontFamily: 'Pretendard-Medium',
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: -0.24,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const SizedBox(
                            width: double.infinity,
                            child: Text(
                              '추가는 구독권 관리 화면에서 가능하며, 현재 멤버 삭제 기능은 제공 중이지 않습니다. 해당 멤버를 삭제하고 싶을 시, 구독권 해지를 통해 가능합니다.',
                              style: TextStyle(
                                color: Color(0xFF999999),
                                fontSize: 11,
                                fontFamily: 'Pretendard-Light',
                                fontWeight: FontWeight.w300,
                                height: 1.45,
                                letterSpacing: -0.22,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // 두 번째 안내문
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: ShapeDecoration(
                        color: const Color(0xFFE7ECF6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Image.asset(
                                'assets/icons/my/Fill_inform.png',
                                width: 16,
                                height: 16,
                                fit: BoxFit.contain,
                              ),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  '새 멤버 추가는 구독권 변경 후에 가능합니다.',
                                  style: TextStyle(
                                    color: Color(0xFF666666),
                                    fontSize: 11,
                                    fontFamily: 'Pretendard-Medium',
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: -0.24,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const SizedBox(
                            width: double.infinity,
                            child: Text(
                              '기존 멤버 외 추가하고 싶은 멤버가 있다면, 멤버 추가하기 버튼 선택 후 구독권 관리에서 멤버를 추가할 수 있습니다.',
                              style: TextStyle(
                                color: Color(0xFF999999),
                                fontSize: 11,
                                fontFamily: 'Pretendard-Light',
                                fontWeight: FontWeight.w300,
                                height: 1.45,
                                letterSpacing: -0.22,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // 여유 공간 추가
            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildMemberCards() {
    final cards =
        _memberProfiles
            .where((profile) {
              // 자신의 계정(isOwner가 true)인 경우 제외
              return profile['isOwner'] != true;
            })
            .map((profile) {
              final bool isEmpty = profile['isEmpty'] == true;
              final String name = profile['name'] ?? '';
              final bool isOwner = profile['isOwner'] == true;

              return Container(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Image.asset(
                      'assets/icons/my/sub_card.png',
                      width: 140,
                      filterQuality: FilterQuality.high,
                      isAntiAlias: true,
                      fit: BoxFit.contain,
                    ),
                    Positioned(
                      bottom: 5,
                      child: Container(
                        width: 120,
                        padding: const EdgeInsets.all(8),
                        decoration: ShapeDecoration(
                          color: Colors.white.withOpacity(0.6),
                          shape: RoundedRectangleBorder(
                            side: const BorderSide(
                              width: 0.40,
                              color: Colors.white,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: ShapeDecoration(
                                shape: OvalBorder(
                                  side: const BorderSide(
                                    width: 0.80,
                                    color: Color(0xFF146AFF),
                                  ),
                                ),
                              ),
                              child: ClipOval(
                                child: _buildProfileImageContent(profile),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: ShapeDecoration(
                                    color: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      side: const BorderSide(
                                        width: 0.35,
                                        color: Color(0xFF89DA8D),
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text(
                                    '자녀',
                                    style: TextStyle(
                                      color: Color(0xFF89DA8D),
                                      fontSize: 9,
                                      fontFamily: 'Pretendard-Light',
                                      fontWeight: FontWeight.w300,
                                      letterSpacing: -0.22,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  isEmpty ? '빈 자리' : (name.isNotEmpty ? name : '멤버'),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontFamily: 'Pretendard-Bold',
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.24,
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
            })
            .toList();

    // 카드들 사이에 간격 추가
    List<Widget> cardsWithSpacing = [];
    for (int i = 0; i < cards.length; i++) {
      cardsWithSpacing.add(cards[i]);
      if (i < cards.length - 1) {
        cardsWithSpacing.add(const SizedBox(width: 16));
      }
    }

    return cardsWithSpacing;
  }

  Widget _buildSubscriptionOption({
    required String title,
    required String price,
    required bool isSelected,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: ShapeDecoration(
        color: const Color(0x66EFF2F6),
        shape: RoundedRectangleBorder(
          side: const BorderSide(width: 1.40, color: Color(0xFF146AFF)),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF353535),
              fontSize: 14,
              fontFamily: 'Pretendard-Light',
              fontWeight: FontWeight.w300,
              letterSpacing: -0.28,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '₩ ${price}원',
                style: const TextStyle(
                  color: Color(0xFF202020),
                  fontSize: 20,
                  fontFamily: 'Pretendard-Bold',
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.80,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                '/ 월간',
                style: TextStyle(
                  color: Color(0xFF666666),
                  fontSize: 16,
                  fontFamily: 'Pretendard-Light',
                  fontWeight: FontWeight.w300,
                  letterSpacing: -0.32,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 혜택 아이템 위젯
  Widget _buildBenefitItem(String text) {
    return Container(
      width: double.infinity,
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF666666),
          fontSize: 10,
          fontFamily: 'Pretendard-Light',
          fontWeight: FontWeight.w300,
          letterSpacing: -0.24,
          height: 1.5,
        ),
      ),
    );
  }

  // 자리가 남았는지 확인하는 메서드
  bool _hasAvailableSeats() {
    if (_currentSubscription == null) return false;

    // 서버에서 받은 left 값을 사용 (남은 자리 수)
    final int leftSeats = _currentSubscription!['left'] ?? 0;
    final int totalSeats = _currentSubscription!['seat'] ?? 0;
    final List<dynamic> members = _currentSubscription!['members'] ?? [];
    
    // 상세 정보 터미널 출력 (자녀용)
    print('');
    print('🪑 ===== [자녀용] 구독권 자리 현황 확인 =====');
    print('   📊 총 자리 수: $totalSeats');
    print('   👥 현재 멤버 수: ${members.length}');
    print('   🎫 남은 자리 수: $leftSeats');
    print('   💼 멤버 ID 목록: $members');
    
    if (leftSeats > 0) {
      print('   ✅ 추가 초대 가능: $leftSeats자리 남음');
      // 남은 자리가 있을 때만 상세 초대코드 정보를 다시 한번 조회
      _logDetailedInviteCodeInfo();
    } else {
      print('   ❌ 추가 초대 불가: 모든 자리가 사용됨');
    }
    print('🪑 ===== [자녀용] 구독권 자리 현황 확인 완료 =====');
    print('');

    return leftSeats > 0;
  }

  // 새 멤버 초대하기 메서드
  Future<void> _inviteNewMember() async {
    try {
      if (_currentSubscription == null) return;

      // 구독권의 초대코드 정보 가져오기
      final inviteCodesMap = _currentSubscription!['inviteCodes'] as Map<String, dynamic>?;

      if (inviteCodesMap == null || inviteCodesMap.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('초대 가능한 코드가 없습니다.')),
        );
        return;
      }

      // 미사용(등록되지 않은) 코드만 추출 (value == null)
      final unusedCodes = inviteCodesMap.entries
          .where((e) => e.value == null)
          .map((e) => e.key)
          .toList();

      if (unusedCodes.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('모든 초대코드가 이미 사용되었습니다.')),
        );
        return;
      }

      // 첫 번째 미사용 코드만 보냄
      final inviteCode = unusedCodes.first;
      final int seat = _currentSubscription!['seat'] ?? 3;

      final bool success = await SubscriptionService.shareInviteCodeToKakao(
        inviteCode,
        seat,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? '초대 코드를 카카오톡으로 전송했습니다!' : '초대 코드 전송에 실패했습니다.',
            ),
          ),
        );
      }
    } catch (e) {
      print('초대 코드 전송 오류: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('초대 코드 전송에 실패했습니다.')));
      }
    }
  }

  // 프로필 이미지 콘텐츠를 구성하는 메서드 추가
  Widget _buildProfileImageContent(Map<String, dynamic> profile) {
    final String baseUrl = "http://3.34.52.239:8080/"; // 서버 기본 URL
    final String s3BaseUrl =
        "https://littlebank-dev.s3.ap-northeast-2.amazonaws.com/"; // S3 기본 URL

    // 빈 자리인 경우
    if (profile['isEmpty'] == true) {
      return Icon(Icons.add, color: Colors.white, size: 16);
    }

    final String? profileImagePath = profile['profileImage'] ?? profile['profileImagePath'];
    
    if (profileImagePath != null && profileImagePath.isNotEmpty) {
      final String imagePath = profileImagePath;

      // 로컬 asset 이미지인 경우 (assets/로 시작)
      if (imagePath.startsWith('assets/')) {
        return Image.asset(
          imagePath,
          width: 24,
          height: 24,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            print('Asset 이미지 로드 오류: $error');
            return Icon(Icons.person, color: Colors.white, size: 16);
          },
        );
      }
      // 기본 이미지인 경우 특별 처리 (한글명 또는 URL 인코딩된 형태)
      else if (imagePath.contains('기본이미지.png') ||
          imagePath.contains('defailt') ||
          imagePath.contains(
            '%E1%84%80%E1%85%B5%E1%84%87%E1%85%A9%E1%86%AB%E1%84%8B%E1%85%B5%E1%84%86%E1%85%B5%E1%84%8C%E1%85%B5.png',
          )) {
        final s3Url = s3BaseUrl + imagePath;
        print('기본 이미지 S3 URL: $s3Url');

        return Image.network(
          s3Url,
          width: 24,
          height: 24,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return CircularProgressIndicator(
              color: Colors.white,
              value:
                  loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
            );
          },
          errorBuilder: (context, error, stackTrace) {
            print('기본 이미지 로드 오류: $error');
            return Icon(Icons.person, color: Colors.white, size: 16);
          },
        );
      }
      // 이미 http로 시작하는 완전한 URL인 경우
      else if (imagePath.startsWith('http')) {
        return FutureBuilder<Map<String, String>>(
          future: AuthService.getImageHeaders(),
          builder: (context, snapshot) {
            return CachedNetworkImage(
              imageUrl: imagePath,
              width: 24,
              height: 24,
              fit: BoxFit.cover,
              httpHeaders: snapshot.data ?? {},
              placeholder:
                  (context, url) =>
                      CircularProgressIndicator(color: Colors.white),
              errorWidget: (context, url, error) {
                print('이미지 로드 오류 (완전 URL): $error');
                return Icon(Icons.person, color: Colors.white, size: 16);
              },
            );
          },
        );
      }
      // 서버의 상대 경로인 경우 (images/로 시작)
      else if (imagePath.startsWith('images/')) {
        // 직접 S3에서 이미지 가져오기 (서버 우회)
        final s3Url = s3BaseUrl + imagePath;
        print('S3 직접 이미지 URL: $s3Url');

        return Image.network(
          s3Url,
          width: 24,
          height: 24,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return CircularProgressIndicator(
              color: Colors.white,
              value:
                  loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
            );
          },
          errorBuilder: (context, error, stackTrace) {
            print('S3 이미지 로드 오류: $error');
            return Icon(Icons.person, color: Colors.white, size: 16);
          },
        );
      }
    }

    // 이미지가 없거나 모든 시도가 실패한 경우
    return Icon(Icons.person, color: Colors.white, size: 16);
  }

  // 개별 쿠폰 코드 연속 전송
  Future<void> _showIndividualInviteDialog() async {
    try {
      // 현재 매칭 정보 가져오기
      final matchingInfo = await SubscriptionService.getInviteCodeMatching();
      
      if (matchingInfo == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('쿠폰 코드 정보를 가져올 수 없습니다.')),
          );
        }
        return;
      }

      // 현재 구독권 정보 확인
      final totalSeats = matchingInfo['totalSeats'] as int? ?? 0;
      final usedCodes = matchingInfo['usedCodes'] as int? ?? 0;
      final availableSlots = totalSeats - usedCodes - 1; // -1은 현재 사용자(구독권 소유자) 제외
      
      // 사용 가능한 쿠폰 코드 확인
      final serverCodes = matchingInfo['serverCodes'] as List<dynamic>? ?? [];
      final availableCodes = serverCodes.where((code) => 
        code['used'] == false
      ).toList();

      print('🔍 [자녀개별초대] 총 좌석: $totalSeats, 사용된 코드: $usedCodes, 남은 자리: $availableSlots');
      print('🔍 [자녀개별초대] 사용 가능한 코드: ${availableCodes.length}개');

      if (availableCodes.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('전송 가능한 쿠폰 코드가 없습니다.')),
          );
        }
        return;
      }

      if (availableSlots <= 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('더 이상 초대할 수 있는 자리가 없습니다.')),
          );
        }
        return;
      }

      // 실제 초대 가능한 수는 남은 자리와 사용 가능한 코드 수 중 작은 값
      final maxInvites = min(availableSlots, availableCodes.length);
      
      print('🚀 [자녀개별초대] ${maxInvites}개의 코드를 연속으로 카카오톡 공유 시작');
      
      // 로딩 다이얼로그 표시
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              content: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(width: 16),
                  Text('${maxInvites}명에게 쿠폰 코드를 전송하는 중...'),
                ],
              ),
            );
          },
        );
      }

      // 로딩 다이얼로그 닫기
      if (mounted) {
        Navigator.of(context).pop();
      }

      // 모든 남은 코드를 하나의 메시지로 카카오톡 공유
      final codes = availableCodes.take(maxInvites).map((codeInfo) => codeInfo['code'] as String).toList();
      
      final success = await KakaoShareService.shareAllCodesInOneMessage(
        codes: codes,
        context: context,
        totalSeats: totalSeats,
      );
      
      print('🏁 [자녀개별초대] 모든 코드 전송 완료: ${success ? '성공' : '실패'}');
      
    } catch (e) {
      print('❌ [자녀개별초대] 연속 전송 오류: $e');
      
      // 로딩 다이얼로그가 열려있다면 닫기
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('오류가 발생했습니다.')),
        );
      }
    }
  }



}
