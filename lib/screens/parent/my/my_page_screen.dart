import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../widgets/parent/bottom_navigation_bar.dart'; // 총 적립 내역 화면 import
import 'point/parent_allowance_history_screen.dart'; // 부모님 용돈 지급 내역 화면 import
import 'balance/parent_account_balance_screen.dart'; // 부모님 포인트 잔액 화면 import
import 'family_management_screen.dart'; // 가족 멤버 관리 화면 import
import 'my_children_report_screen.dart'; // 총 분석 리포트 화면 import
import 'management/parent_member_management_screen.dart'; // 부모님 멤버 관리 화면 import
import '../analysis/parent_activity_history_screen.dart'; // 부모님 활동내역 화면 import
import '../cs/parent_notice_screen.dart'; // 부모님 공지사항 화면 import
import '../cs/parent_customer_service_screen.dart'; // 부모님 고객센터 화면 import
import 'charge/parent_charge_screen.dart'; // 부모님 충전 화면 import
import 'recommend/share_with_friend_screen.dart'; // 친구에게 공유하기 화면 import
import '../../../services/auth_service.dart';
import '../../../services/family_service.dart'; // 가족 서비스 import
import '../../../services/payment_service.dart'; // 결제 서비스 import
import '../../../screens/common/logout_modal.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../edit_profile_screen.dart';
import 'settings_screen.dart'; // 부모님 설정 화면 import
import 'bank/parent_bank_withdrawal_screen.dart'; // 부모님 포인트 출금 화면 import
import 'bank/parent_bank_transfer_screen.dart'; // 부모님 자녀 포인트 전송 화면 import
import 'bank/parent_account_link_screen.dart'; // 부모단 계좌 연동 화면 import 추가
import 'benefit/little_bank_benefits_screen.dart'; // 리틀뱅크혜택 화면 import
import 'subscription/subscription_on_screen.dart';
import '../../../services/subscription_service.dart'; // 구독 서비스 import

class ParentMyPageScreen extends StatefulWidget {
  const ParentMyPageScreen({super.key});

  @override
  State<ParentMyPageScreen> createState() => _ParentMyPageScreenState();
}

class _ParentMyPageScreenState extends State<ParentMyPageScreen> {
  // 마이 탭 선택
  final int _selectedIndex = 4;

  // 적립금 카드 확장 여부
  bool _isPointCardExpanded = false;

  // 각 메뉴 섹션의 확장 상태 (기본값은 true - 펼쳐진 상태)
  final Map<String, bool> _expandedSections = {
    '용돈 내역': true,
    '활동내역': true,
    '관리지원': true,
    '고객 지원': true,
  };

  // 금액 포맷팅 (천 단위 콤마)
  String _formatCurrency(dynamic amount) {
    final int value =
        amount is int ? amount : int.tryParse(amount.toString()) ?? 0;
    return value.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  // 사용자 정보를 저장할 변수 추가
  Map<String, dynamic>? _userInfo;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isAccountLinked = false; // 계좌 연동 여부 추가

  // 포인트 정보를 저장할 변수 추가
  int _currentPoints = 0;
  int _totalPoints = 0;

  // 가족 정보 관련 변수들 추가
  List<dynamic>? _familyMembers;
  bool _isLoadingFamily = true;
  String? _familyError;

  // 선택된 자녀 정보 추가
  Map<String, dynamic>? _selectedChild;
  int _selectedChildIndex = 0; // 선택된 자녀의 인덱스

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    // _loadFamilyMembers(); // 사용자 정보 로드 후에 호출하도록 변경

    // 상태바 스타일만 설정 (main.dart의 시스템 UI 설정 유지)
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent, // 상태 표시줄 배경을 투명하게
        statusBarIconBrightness: Brightness.dark, // 상태 표시줄 아이콘 색상을 어둡게
      ),
    );

    // 화면이 완전히 로드된 후 포인트 새로고침 (포인트 전송 후 돌아온 경우 대비)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshPointsInfo(withDelay: true);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 화면이 다시 활성화될 때마다 포인트 정보 새로고침
    print('🔄 마이페이지 didChangeDependencies 호출 - 포인트 새로고침');
    _refreshPointsInfo(withDelay: false);
  }

  @override
  void dispose() {
    // 화면 종료시 main.dart의 원래 시스템 UI 설정으로 복원
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
    );
    super.dispose();
  }

  // 사용자 정보 불러오기
  Future<void> _loadUserInfo() async {
    try {
      if (mounted) {
        setState(() {
          _isLoading = true;
          _errorMessage = null;
        });
      }

      final userInfo = await AuthService.getUserInfo();

      // 계좌 연동 상태 확인 (서버 데이터 기반)
      final isLinked =
          userInfo['bankName'] != null &&
          userInfo['bankName'].toString().trim().isNotEmpty &&
          userInfo['bankAccount'] != null &&
          userInfo['bankAccount'].toString().trim().isNotEmpty &&
          userInfo['bankCode'] != null &&
          userInfo['bankCode'].toString().trim().isNotEmpty;

      // 현재 보유 포인트를 사용자 정보에서 직접 가져오기
      final currentPoints = userInfo['point'] ?? 0;
      print('사용자 정보에서 가져온 현재 포인트: $currentPoints');

      // 사용자 정보 상세 로깅
      print('사용자 정보 로드 성공: $userInfo');
      print('계좌 연동 상태: $isLinked');
      userInfo.forEach((key, value) {
        print('사용자 정보 키: $key, 값: $value');
      });

      // 역할 정보 확인
      if (userInfo.containsKey('role')) {
        print('사용자 역할(role): ${userInfo['role']}');
      }
      if (userInfo.containsKey('authority')) {
        print('사용자 권한(authority): ${userInfo['authority']}');
      }

      if (mounted) {
        setState(() {
          _userInfo = userInfo;
          _isAccountLinked = isLinked;
          _currentPoints = currentPoints; // 포인트도 여기서 설정
          _isLoading = false;
        });

        // 사용자 정보 로드 완료 후 가족 정보 로드
        _loadFamilyMembers();

        // 총 누적 포인트만 별도로 계산
        _loadTotalPoints();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
      print('사용자 정보 로딩 오류: $e');
    }
  }

  // 포인트 정보 불러오기
  Future<void> _loadPointsInfo() async {
    try {
      print('===== 포인트 정보 로딩 시작 =====');

      // 현재 보유 포인트 조회 (강제 새로고침)
      final userInfo = await AuthService.getUserInfo();
      final currentPoints =
          userInfo['point'] is int
              ? userInfo['point']
              : int.tryParse(userInfo['point'].toString()) ?? 0;
      print('현재 보유 포인트 조회 완료: $currentPoints');

      // 총 누적 포인트 조회 - 포인트 충전 내역 화면과 동일한 방식
      print('총 누적 포인트 계산 시작 (충전 내역 화면 방식)...');
      int totalAccumulated = 0;

      try {
        // 충전 내역 API 호출 (포인트 충전 내역 화면과 동일)
        final historyResponse = await PaymentService.getChargeHistory(
          pageNumber: 0,
        );
        print('충전 내역 API 응답: $historyResponse');

        if (historyResponse.containsKey('data') &&
            historyResponse['data'] is List) {
          final List<dynamic> chargeList = historyResponse['data'];
          print('충전 내역 개수: ${chargeList.length}');

          // 각 충전 내역의 chargePoint를 누적 (충전 내역 화면과 동일한 필드명)
          for (final charge in chargeList) {
            if (charge.containsKey('chargePoint')) {
              // pointAmount 대신 chargePoint 사용
              final chargePoint = charge['chargePoint'] ?? 0;
              totalAccumulated += chargePoint as int;
              print(
                '충전 금액 (chargePoint): $chargePoint, 누적 합계: $totalAccumulated',
              );
            }
          }

          print('페이지 0 누적 결과: $totalAccumulated');

          // 추가 페이지가 있으면 더 조회
          final totalPage = historyResponse['totalPage'] ?? 1;
          print('전체 페이지 수: $totalPage');

          if (totalPage > 1) {
            for (int page = 1; page < totalPage; page++) {
              try {
                print('추가 페이지 $page 조회 중...');
                final additionalResponse =
                    await PaymentService.getChargeHistory(pageNumber: page);

                if (additionalResponse.containsKey('data') &&
                    additionalResponse['data'] is List) {
                  final List<dynamic> additionalChargeList =
                      additionalResponse['data'];
                  print('페이지 $page 충전 내역 개수: ${additionalChargeList.length}');

                  for (final charge in additionalChargeList) {
                    if (charge.containsKey('chargePoint')) {
                      final chargePoint = charge['chargePoint'] ?? 0;
                      totalAccumulated += chargePoint as int;
                      print(
                        '추가 충전 금액 (chargePoint): $chargePoint, 누적 합계: $totalAccumulated',
                      );
                    }
                  }
                }
              } catch (e) {
                print('페이지 $page 조회 중 오류: $e');
                break;
              }
            }
          }
        } else {
          print('충전 내역 데이터가 없거나 형식이 올바르지 않습니다.');
        }

        print('충전 내역에서 계산 완료. 총 누적 포인트: $totalAccumulated');
      } catch (e) {
        print('충전 내역 조회 오류: $e');
        // 오류 시에도 0으로 설정
        totalAccumulated = 0;
      }

      print('최종 계산된 총 누적 포인트: $totalAccumulated');

      if (mounted) {
        setState(() {
          _currentPoints = currentPoints;
          _totalPoints = totalAccumulated; // 직접 계산한 값 사용
        });
      }

      print('===== 포인트 정보 로딩 완료 =====');
      print('UI 업데이트 - 현재 보유 포인트: $_currentPoints');
      print('UI 업데이트 - 총 누적 포인트: $_totalPoints');
    } catch (e) {
      print('포인트 정보 로딩 오류: $e');
      // 오류 발생 시 기본값 유지
    }
  }

  // 총 누적 포인트만 계산하기 (충전 내역 기반)
  Future<void> _loadTotalPoints() async {
    try {
      print('총 누적 포인트 계산 시작...');
      int totalAccumulated = 0;

      try {
        // 충전 내역 API 호출
        final historyResponse = await PaymentService.getChargeHistory(
          pageNumber: 0,
        );

        if (historyResponse.containsKey('data') &&
            historyResponse['data'] is List) {
          final List<dynamic> chargeList = historyResponse['data'];

          // 각 충전 내역의 chargePoint를 누적
          for (final charge in chargeList) {
            if (charge.containsKey('chargePoint')) {
              final chargePoint = charge['chargePoint'] ?? 0;
              totalAccumulated += chargePoint as int;
            }
          }

          // 추가 페이지가 있으면 더 조회
          final totalPage = historyResponse['totalPage'] ?? 1;
          if (totalPage > 1) {
            for (int page = 1; page < totalPage; page++) {
              try {
                final additionalResponse =
                    await PaymentService.getChargeHistory(pageNumber: page);

                if (additionalResponse.containsKey('data') &&
                    additionalResponse['data'] is List) {
                  final List<dynamic> additionalChargeList =
                      additionalResponse['data'];

                  for (final charge in additionalChargeList) {
                    if (charge.containsKey('chargePoint')) {
                      final chargePoint = charge['chargePoint'] ?? 0;
                      totalAccumulated += chargePoint as int;
                    }
                  }
                }
              } catch (e) {
                print('페이지 $page 조회 중 오류: $e');
                break;
              }
            }
          }
        }

        print('충전 내역에서 계산 완료. 총 누적 포인트: $totalAccumulated');
      } catch (e) {
        print('충전 내역 조회 오류: $e');
        totalAccumulated = 0;
      }

      if (mounted) {
        setState(() {
          _totalPoints = totalAccumulated;
        });
      }

      print('총 누적 포인트 업데이트 완료: $_totalPoints');
    } catch (e) {
      print('총 누적 포인트 계산 오류: $e');
    }
  }

  // 포인트 정보 새로고침 (지연 후 재시도 포함)
  Future<void> _refreshPointsInfo({bool withDelay = false}) async {
    try {
      print('포인트 정보 새로고침 시작 (지연: $withDelay)');

      if (withDelay) {
        // 충전 완료 후 서버 업데이트 시간을 고려한 지연
        await Future.delayed(Duration(milliseconds: 1000));
      }

      // 사용자 정보를 다시 가져와서 최신 포인트 업데이트
      final userInfo = await AuthService.getUserInfo();
      final currentPoints = userInfo['point'] ?? 0;

      if (mounted) {
        setState(() {
          _userInfo = userInfo;
          _currentPoints = currentPoints;
        });
      }

      print('사용자 정보에서 새로고침된 현재 포인트: $currentPoints');

      // 총 누적 포인트도 새로고침
      await _loadTotalPoints();

      print('포인트 정보 새로고침 완료');
    } catch (e) {
      print('포인트 정보 새로고침 오류: $e');
    }
  }

  // 가족 구성원 목록 불러오기
  Future<void> _loadFamilyMembers() async {
    try {
      if (mounted) {
        setState(() {
          _isLoadingFamily = true;
          _familyError = null;
        });
      }

      print('마이페이지: 가족 구성원 목록 로드 시작');

      final familyInfo = await FamilyService.getFamilyInfo();

      print('마이페이지: FamilyService.getFamilyInfo() 결과: $familyInfo');

      if (familyInfo != null) {
        final List<dynamic> memberList = familyInfo['memberInfoList'] ?? [];
        print('마이페이지: 가족 정보 로드 성공 - 멤버 ${memberList.length}명');

        // 멤버 리스트 상세 출력
        for (int i = 0; i < memberList.length; i++) {
          final member = memberList[i];
          print(
            '마이페이지: 멤버 $i - ID: ${member['id']}, 이름: ${member['nickname'] ?? member['realName']}, 역할: ${member['role']}',
          );
        }

        // 자녀만 필터링
        final children =
            memberList.where((member) => member['role'] != 'PARENT').toList();
        print('마이페이지: 필터링된 자녀 수: ${children.length}');

        if (mounted) {
          setState(() {
            _familyMembers = children;
            _selectedChild =
                children.isNotEmpty ? children[0] : null; // 첫 번째 자녀를 기본 선택
            _selectedChildIndex = 0; // 첫 번째 자녀의 인덱스
            _isLoadingFamily = false;
          });

          print(
            '마이페이지: 상태 업데이트 완료 - 자녀 수: ${children.length}, 선택된 자녀: ${_selectedChild?['nickname'] ?? _selectedChild?['realName']}',
          );
        }
      } else {
        print('마이페이지: 가족 정보 조회 실패 또는 가족 정보 없음');

        if (mounted) {
          setState(() {
            _familyMembers = [];
            _selectedChild = null;
            _isLoadingFamily = false;
          });
        }
      }
    } catch (e) {
      print('마이페이지: 가족 구성원 목록 로드 중 예외 발생: $e');
      print('마이페이지: 스택 트레이스: ${e.toString()}');

      if (mounted) {
        setState(() {
          _familyError = '가족 정보를 불러올 수 없습니다';
          _isLoadingFamily = false;
          _familyMembers = [];
          _selectedChild = null;
        });
      }
    }
  }

  // 자녀 변경 모달 표시
  void _showChildSelectionModal() {
    // 자녀(CHILD 역할)만 필터링
    final filteredChildren =
        _familyMembers?.where((child) {
          return child['role'] == 'CHILD';
        }).toList() ??
        [];

    if (filteredChildren.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('선택할 수 있는 자녀가 없습니다')));
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return ChildSelectionModal(
          children: filteredChildren,
          initialSelectedIndex: _selectedChildIndex,
          onChildSelected: (selectedChild, selectedIndex) {
            setState(() {
              _selectedChild = selectedChild;
              _selectedChildIndex = selectedIndex;
            });
          },
        );
      },
    );
  }

  // 프로필 이미지 업로드 처리
  Future<void> _updateProfileImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedImage = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedImage != null) {
        // 로딩 상태 설정
        if (mounted) {
          setState(() {
            _isLoading = true;
          });
        }

        // 이미지 업로드 처리
        final imagePath = await AuthService.uploadProfileImage(
          File(pickedImage.path),
        );

        print('업로드된 이미지 경로: $imagePath');

        // 프로필 업데이트 API 호출 (profileImagePath만 업데이트)
        await AuthService.updateUserProfile(imagePath);

        // 사용자 정보 다시 로드 (mounted 체크 추가)
        if (mounted) {
          await _loadUserInfo();
        }
      }
    } catch (e) {
      // 오류 처리 (mounted 체크 추가)
      if (mounted) {
        setState(() {
          _errorMessage = '프로필 이미지 업데이트 중 오류가 발생했습니다: $e';
          _isLoading = false;
        });
      }
      print('프로필 이미지 업데이트 오류: $e');
    }
  }

  // 프로필 이미지 변경 옵션을 보여주는 바텀 시트
  void _showProfileImageOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxHeight:
            MediaQuery.of(context).size.height * 0.66, // 전체 화면 높이의 2/3로 제한
      ),
      builder: (BuildContext context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height;

        return Container(
          width: screenWidth,
          decoration: BoxDecoration(
            color: Color(0xFFFFFFFF),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 안내 텍스트 추가
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 사용자 이름 및 메인 타이틀
                  Text(
                    '${_userInfo?['name'] ?? '회원'}님 프로필 이미지를 변경해보세요',
                    style: TextStyle(
                      fontSize: screenWidth * 0.045, // 반응형 폰트 크기
                      fontFamily: 'Pretendard-Bold',
                      color: Color(0xFF202020),
                    ),
                    textAlign: TextAlign.left,
                  ),
                  SizedBox(height: 4),
                  // 서브 타이틀
                  Text(
                    '아이콘을 선택하거나, 직접 촬영할 수 있어요',
                    style: TextStyle(
                      fontSize: screenWidth * 0.035, // 반응형 폰트 크기
                      fontFamily: 'Pretendard-Light',
                      color: Color(0xFF999999),
                    ),
                    textAlign: TextAlign.left,
                  ),
                ],
              ),

              // 현재 프로필 이미지 추가
              SizedBox(height: 16),
              Center(
                child: Container(
                  width: screenWidth * 0.2, // 화면 너비의 20%로 조정
                  height: screenWidth * 0.2, // 정사각형 유지
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Color(0xFFE0E5F2), width: 2),
                  ),
                  child: ClipOval(child: _buildProfileImageContent()),
                ),
              ),

              // 옵션 버튼들
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // 카메라 옵션
                  _buildProfileOptionButton(
                    icon: Icons.camera_alt_rounded,
                    label: '카메라',
                    size: screenWidth * 0.13, // 화면 너비에 비례하여 조정
                    fontSize: screenWidth * 0.03,
                    onTap: () {
                      Navigator.pop(context);
                      _updateProfileImage(ImageSource.camera);
                    },
                  ),

                  // 갤러리 옵션
                  _buildProfileOptionButton(
                    icon: Icons.photo_library_rounded,
                    label: '갤러리',
                    size: screenWidth * 0.13,
                    fontSize: screenWidth * 0.03,
                    onTap: () {
                      Navigator.pop(context);
                      _updateProfileImage(ImageSource.gallery);
                    },
                  ),

                  // 저장하기 버튼
                  _buildProfileOptionButton(
                    icon: Icons.check_circle_rounded,
                    label: '저장하기',
                    size: screenWidth * 0.13,
                    fontSize: screenWidth * 0.03,
                    isHighlighted: true,
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('프로필 사진이 저장되었습니다')),
                      );
                    },
                  ),
                ],
              ),

              // 하단의 파란색 확인 버튼 추가
              SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: screenHeight * 0.055, // 화면 높이에 비례
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF146AFF),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.zero,
                  ),
                  child: Text(
                    '저장하기',
                    style: TextStyle(
                      fontFamily: 'Pretendard-Light',
                      fontSize: screenWidth * 0.04,
                    ),
                  ),
                ),
              ),

              // 하단 여백
              SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  // 프로필 변경 옵션 버튼
  Widget _buildProfileOptionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    double size = 58.0,
    double fontSize = 12.0,
    bool isHighlighted = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 아이콘 원형 버튼
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isHighlighted ? Color(0xFF146AFF) : Color(0xFFF0F2F7),
            ),
            child: Icon(
              icon,
              color: isHighlighted ? Colors.white : Color(0xFF999999),
              size: size * 0.4,
            ),
          ),
          SizedBox(height: 4),
          // 라벨
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Pretendard-Light',
              fontSize: fontSize,
              color: isHighlighted ? Color(0xFF146AFF) : Color(0xFF999999),
            ),
          ),
        ],
      ),
    );
  }

  // 메뉴 섹션 토글 기능
  void _toggleSection(String title) {
    setState(() {
      _expandedSections[title] = !(_expandedSections[title] ?? true);
    });
  }

  @override
  Widget build(BuildContext context) {
    // 화면 크기 가져오기
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // 상태 표시줄 투명화 설정
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFE7ECF6), // 배경색 변경
        extendBodyBehindAppBar: true,
        body:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '오류가 발생했습니다',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                          fontFamily: 'Pretendard-Bold',
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        _errorMessage!,
                        style: TextStyle(
                          fontSize: 14,
                          fontFamily: 'Pretendard-Regular',
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadUserInfo,
                        child: Text('다시 시도'),
                      ),
                    ],
                  ),
                )
                : SingleChildScrollView(
                  child: Column(
                    children: [
                      // 상단 파란색 영역
                      Container(
                        decoration: ShapeDecoration(
                          color: Color(0xFFE6EBF5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(40),
                              bottomRight: Radius.circular(40),
                            ),
                          ),
                        ),
                        child: SafeArea(
                          child: Column(
                            children: [
                              // 상단 아이콘 부분
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  20,
                                  20,
                                  10,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    // 왼쪽 로고
                                    Image.asset(
                                      'assets/icons/sub_logo.png',
                                      width: 32,
                                      height: 32,
                                    ),

                                    // 오른쪽 아이콘들 (자녀 프로필, 로그아웃, 설정)
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // 자녀 프로필과 변경 버튼
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: ShapeDecoration(
                                            color: const Color(0xFF5D9EFF),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(24),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              // 자녀 프로필 이미지
                                              Container(
                                                width: 24,
                                                height: 24,
                                                decoration: ShapeDecoration(
                                                  shape: OvalBorder(
                                                    side: BorderSide(
                                                      width: 0.80,
                                                      color: const Color(
                                                        0xFF146AFF,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                child: ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  child:
                                                      _isLoadingFamily
                                                          ? Container(
                                                            color:
                                                                Colors
                                                                    .grey[300],
                                                            child: Center(
                                                              child: SizedBox(
                                                                width: 12,
                                                                height: 12,
                                                                child: CircularProgressIndicator(
                                                                  color:
                                                                      Colors
                                                                          .grey[600],
                                                                  strokeWidth:
                                                                      1,
                                                                ),
                                                              ),
                                                            ),
                                                          )
                                                          : _selectedChild?['profileImagePath'] !=
                                                                  null &&
                                                              _selectedChild!['profileImagePath']!
                                                                  .isNotEmpty
                                                          ? CachedNetworkImage(
                                                            imageUrl:
                                                                AuthService.getFullProfileImageUrl(
                                                                  _selectedChild!['profileImagePath'],
                                                                ),
                                                            fit: BoxFit.cover,
                                                            placeholder:
                                                                (
                                                                  context,
                                                                  url,
                                                                ) => Container(
                                                                  color:
                                                                      Colors
                                                                          .grey[300],
                                                                  child: Icon(
                                                                    Icons
                                                                        .person,
                                                                    color:
                                                                        Colors
                                                                            .grey[600],
                                                                    size: 12,
                                                                  ),
                                                                ),
                                                            errorWidget:
                                                                (
                                                                  context,
                                                                  url,
                                                                  error,
                                                                ) => Container(
                                                                  color:
                                                                      Colors
                                                                          .grey[300],
                                                                  child: Icon(
                                                                    Icons
                                                                        .person,
                                                                    color:
                                                                        Colors
                                                                            .grey[600],
                                                                    size: 12,
                                                                  ),
                                                                ),
                                                          )
                                                          : Container(
                                                            color:
                                                                Colors
                                                                    .grey[300],
                                                            child: Icon(
                                                              Icons.person,
                                                              color:
                                                                  Colors
                                                                      .grey[600],
                                                              size: 12,
                                                            ),
                                                          ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),

                                              // 변경 버튼
                                              GestureDetector(
                                                onTap: _showChildSelectionModal,
                                                child: Container(
                                                  width: 24,
                                                  height: 24,
                                                  child: Image.asset(
                                                    'assets/icons/parent/아이변경.png',
                                                    width: 24,
                                                    height: 24,
                                                    color: Colors.white,
                                                    errorBuilder:
                                                        (
                                                          context,
                                                          error,
                                                          stackTrace,
                                                        ) => Icon(
                                                          Icons.swap_horiz,
                                                          color: Colors.white,
                                                          size: 16,
                                                        ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                        const SizedBox(width: 12),

                                        // 로그아웃 버튼
                                        GestureDetector(
                                          onTap: () {
                                            // 로그아웃 모달 표시
                                            LogoutModal.show(context);
                                          },
                                          child: Container(
                                            width: 28,
                                            height: 28,
                                            margin: EdgeInsets.only(right: 16),
                                            // 배경색 없음(투명)
                                            child: Image.asset(
                                              'assets/icons/parent/my/logout.png',
                                              width: 28,
                                              height: 28,
                                              color: Color(
                                                0xFF5D6A7F,
                                              ), // 설정 버튼과 동일한 색상으로 변경
                                              errorBuilder:
                                                  (
                                                    context,
                                                    error,
                                                    stackTrace,
                                                  ) => Icon(
                                                    Icons.logout_rounded,
                                                    color: Color(
                                                      0xFF5D6A7F,
                                                    ), // 설정 버튼과 동일한 색상으로 변경
                                                    size: 28,
                                                  ),
                                            ),
                                          ),
                                        ),

                                        // 설정 아이콘
                                        GestureDetector(
                                          onTap: () {
                                            // 설정 화면으로 이동
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder:
                                                    (context) =>
                                                        const ParentSettingsScreen(),
                                              ),
                                            );
                                          },
                                          child: Container(
                                            width: 28,
                                            height: 28,
                                            // 배경색 없음(투명)
                                            child: Image.asset(
                                              'assets/icons/parent/my/settings.png',
                                              width: 28,
                                              height: 28,
                                              color: Color(
                                                0xFF5D6A7F,
                                              ), // 아이콘 색상 변경
                                              errorBuilder:
                                                  (
                                                    context,
                                                    error,
                                                    stackTrace,
                                                  ) => Icon(
                                                    Icons.settings,
                                                    color: Color(
                                                      0xFF5D6A7F,
                                                    ), // 아이콘 색상 변경
                                                    size: 28,
                                                  ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 18),
                              // 프로필 카드
                              _buildProfileCard(),

                              const SizedBox(height: 24),

                              // 적립금 정보 카드
                              _buildPointsCard(),

                              const SizedBox(height: 30),
                            ],
                          ),
                        ),
                      ),

                      // 메뉴 리스트
                      const SizedBox(height: 12),
                      _buildMenuList(),

                      // 하단 여백 추가
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
        bottomNavigationBar: const ParentBottomNavigationBar(selectedIndex: 4),
      ),
    );
  }

  // 프로필 카드 (프로필부터 충전하기까지)
  Widget _buildProfileCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF5D9EFF),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 8,
            offset: Offset(3, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          // 프로필 정보 부분 (기존 코드 유지)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 프로필 이미지
              Container(
                padding: EdgeInsets.only(top: 4),
                child: Stack(
                  children: [
                    GestureDetector(
                      onTap: _showProfileImageOptions,
                      child: Container(
                        width: 68,
                        height: 68,
                        margin: EdgeInsets.only(left: 4, right: 4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              Color.fromRGBO(156, 193, 255, 1),
                              Color.fromRGBO(54, 162, 235, 0.4),
                            ],
                          ),
                        ),
                        child: ClipOval(child: _buildProfileImageContent()),
                      ),
                    ),
                    // 편집 아이콘
                    Positioned(
                      right: -9,
                      bottom: -10,
                      child: GestureDetector(
                        onTap: _showProfileImageOptions,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.transparent,
                          ),
                          child: Image.asset(
                            'assets/icons/parent/my/pen.png',
                            width: 40,
                            height: 40,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // 사용자 정보 및 수정하기 버튼 행
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: ShapeDecoration(
                            color: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            '부모',
                            style: TextStyle(
                              color: Color(0xFF89DA8D),
                              fontSize: 11,
                              fontFamily: 'Pretendard-Light',
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) =>
                                        EditProfileScreen(userInfo: _userInfo!),
                              ),
                            );
                            if (result != null && mounted) {
                              setState(() {
                                _userInfo = result;
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            margin: EdgeInsets.only(right: 4),
                            decoration: BoxDecoration(
                              color: Color(0xFFE7ECF6),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              '수정하기',
                              style: TextStyle(
                                color: Color(0xFF999999),
                                fontSize: 11,
                                fontFamily: 'Pretendard-ExtraLight',
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _userInfo?['name'] ?? '이름',
                      style: const TextStyle(
                        fontSize: 16,
                        fontFamily: 'Pretendard-Bold',
                        color: Colors.black,
                        letterSpacing: -0.32,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      _userInfo?['email'] ?? '이메일',
                      style: TextStyle(
                        fontSize: 11,
                        fontFamily: 'Pretendard-Light',
                        color: Colors.white,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // 버튼 영역 (새로운 디자인)
          _isAccountLinked
              ? Column(
                children: [
                  // 포인트 꺼내기와 충전하기 버튼 (나란히)
                  Row(
                    children: [
                      // 포인트 꺼내기 버튼
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) =>
                                        const ParentBankWithdrawalScreen(),
                              ),
                            );
                            if (mounted) {
                              _refreshPointsInfo();
                            }
                          },
                          child: Container(
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFF3A88F4),
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(8),
                                bottomLeft: Radius.circular(8),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '포인트 꺼내기',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontFamily: 'Pretendard-Light',
                                  letterSpacing: -0.28,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // 세로 구분선
                      Container(width: 3, height: 44, color: Color(0xFF5D9EFF)),
                      // 충전하기 버튼
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => const ParentChargeScreen(),
                              ),
                            );
                            if (mounted) {
                              _refreshPointsInfo(withDelay: true);
                            }
                          },
                          child: Container(
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFF3A88F4),
                              borderRadius: BorderRadius.only(
                                topRight: Radius.circular(8),
                                bottomRight: Radius.circular(8),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '충전하기',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontFamily: 'Pretendard-Light',
                                  letterSpacing: -0.28,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // 자녀에게 포인트보내기 버튼
                  GestureDetector(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => const ParentBankTransferScreen(),
                        ),
                      );
                      if (mounted) {
                        _refreshPointsInfo();
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE7ECF6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '자녀에게 포인트 보내기',
                          style: TextStyle(
                            color: const Color(0xFF001F55),
                            fontSize: 12,
                            fontFamily: 'Pretendard-Light',
                            letterSpacing: -0.28,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              )
              : GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ParentAccountLinkScreen(),
                    ),
                  ).then((_) {
                    _loadUserInfo();
                    _refreshPointsInfo(withDelay: true);
                  });
                },
                child: Container(
                  width: double.infinity,
                  height: 44,
                  decoration: ShapeDecoration(
                    color: const Color(0xFF3A88F4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '계좌 연동하기',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontFamily: 'Pretendard-Light',
                        letterSpacing: -0.28,
                      ),
                    ),
                  ),
                ),
              ),
        ],
      ),
    );
  }

  // 프로필 이미지 위젯을 생성하는 헬퍼 메서드
  Widget _buildProfileImageWidget(String imageUrl, String fallbackText) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      width: 60,
      height: 60,
      placeholder:
          (context, url) => const Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
          ),
      errorWidget: (context, url, error) {
        print('이미지 로드 오류: $error');
        return Center(
          child: Text(
            fallbackText,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Pretendard-Bold',
            ),
          ),
        );
      },
    );
  }

  // 포인트 정보 카드 (별도 박스)
  Widget _buildPointsCard() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 포인트 카드 (상단과 확장 영역 통합)
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Color.fromRGBO(143, 187, 255, 1),
                Color.fromRGBO(112, 169, 255, 1),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Color(0x35000000),
                blurRadius: 8,
                offset: Offset(3, 4),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Column(
            children: [
              // 상단 부분 (항상 표시)
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _isPointCardExpanded = !_isPointCardExpanded;
                    });
                    // 카드를 펼칠 때 포인트 정보 새로고침 (지연 포함)
                    if (!_isPointCardExpanded) {
                      _refreshPointsInfo(withDelay: true);
                    }
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // 왼쪽 텍스트
                        Text(
                          _userInfo?['name']?.isNotEmpty == true
                              ? '${_userInfo!['name']}님의 보유 포인트'
                              : '리뱅님의 보유 포인트',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontFamily: 'Pretendard-ExtraBold',
                            letterSpacing: -0.32,
                          ),
                        ),

                        // 금액 표시 부분
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _formatCurrency(_currentPoints),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontFamily: 'Pretendard-ExtraBold',
                                letterSpacing: -0.80,
                              ),
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '원',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontFamily: 'Pretendard-ExtraBold',
                                letterSpacing: -0.32,
                              ),
                            ),
                            const SizedBox(width: 4),
                            AnimatedRotation(
                              turns: _isPointCardExpanded ? 0.5 : 0.0,
                              duration: const Duration(milliseconds: 200),
                              child: Icon(
                                Icons.keyboard_arrow_down,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // 확장 영역 (펼쳤을 때만 표시)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: _isPointCardExpanded ? 70 : 0,
                width: double.infinity,
                child:
                    _isPointCardExpanded
                        ? Row(
                          children: [
                            // 현재 보유 포인트
                            Expanded(
                              child: Align(
                                alignment: Alignment.center,
                                child: Text.rich(
                                  TextSpan(
                                    children: [
                                      TextSpan(
                                        text: '현재 보유 포인트\n',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontFamily: 'Pretendard-Regular',
                                        ),
                                      ),
                                      TextSpan(
                                        text:
                                            '${_formatCurrency(_currentPoints)}원',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontFamily: 'Pretendard-Bold',
                                        ),
                                      ),
                                    ],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),

                            // 세로 구분선
                            Container(
                              height: 30,
                              width: 1,
                              color: Colors.white.withOpacity(0.3),
                            ),

                            // 총 누적 포인트
                            Expanded(
                              child: Align(
                                alignment: Alignment.center,
                                child: Text.rich(
                                  TextSpan(
                                    children: [
                                      TextSpan(
                                        text: '총 누적 포인트\n',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontFamily: 'Pretendard-Regular',
                                        ),
                                      ),
                                      TextSpan(
                                        text:
                                            '${_formatCurrency(_totalPoints)}원',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontFamily: 'Pretendard-Bold',
                                        ),
                                      ),
                                    ],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ],
                        )
                        : null,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 메뉴 리스트
  Widget _buildMenuList() {
    return Column(
      children: [
        // 첫 번째 섹션 (용돈 내역)
        _buildMenuSection(title: '용돈 내역', items: ['총 포인트 내역', '용돈 지급 내역']),

        const SizedBox(height: 14),

        // 두 번째 섹션 (활동내역)
        _buildMenuSection(title: '활동내역', items: ['활동내역', '총 분석 리포트']),

        const SizedBox(height: 14),

        // 세 번째 섹션 (관리지원)
        _buildMenuSection(
          title: '관리지원',
          items: ['멤버 관리', '가족 멤버 관리', '구독권 관리'],
        ),

        const SizedBox(height: 14),

        // 네 번째 섹션 (고객 지원)
        _buildMenuSection(
          title: '고객 지원',
          items: ['공지사항', '친구 초대하기', '리틀뱅크혜택', '고객센터'],
        ),
      ],
    );
  }

  // 메뉴 섹션 위젯
  Widget _buildMenuSection({
    required String title,
    required List<String> items,
  }) {
    // 현재 섹션의 확장 상태 확인 (기본값은 true - 펼쳐진 상태)
    final bool isExpanded = _expandedSections[title] ?? true;

    // 색상은 모두 동일하게 유지
    const Color titleColor = Color(0xFF8590A3); // 색상 변경
    const Color backgroundColor = Colors.white;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 358,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: backgroundColor,
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
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // 타이틀 부분 - 클릭시 토글 (아이콘 제거)
          GestureDetector(
            onTap: () => _toggleSection(title),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 방식2로 직접 폰트 패밀리 지정
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13.0,
                      fontFamily: 'Pretendard-Light',
                      color: titleColor,
                    ),
                  ),
                  // 화살표 아이콘 변경 (위/아래)
                  AnimatedRotation(
                    turns: isExpanded ? 0.0 : 0.5,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: Color(0xFF999999),
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 구분선
          Container(
            height: 1,
            width: double.infinity,
            margin: EdgeInsets.symmetric(horizontal: 12),
            color: Color(0xFFEEEEEE),
          ),

          // 아이템 리스트 - 확장 상태일 때만 표시
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: SizedBox(
              height: isExpanded ? null : 0, // null이면 자식의 크기에 맞춤, 0이면 숨김
              child:
                  isExpanded
                      ? Column(
                        children:
                            items.asMap().entries.map((entry) {
                              final int index = entry.key;
                              final String item = entry.value;
                              final bool isLast = index == items.length - 1;

                              return Column(
                                children: [
                                  // 메뉴 아이템
                                  _buildMenuItemRow(item, isLast: isLast),

                                  // 다음 아이템이 있으면 구분선 추가
                                  if (!isLast)
                                    Container(
                                      height: 1,
                                      width: double.infinity,
                                      margin: EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ),
                                      color: Color(0xFFEEEEEE),
                                    ),
                                ],
                              );
                            }).toList(),
                      )
                      : SizedBox(),
            ),
          ),

          // 마지막에 약간의 패딩 추가하여 둥근 모서리가 잘 보이도록 함
          if (isExpanded) const SizedBox(height: 8),
        ],
      ),
    );
  }

  // 메뉴 아이템 행
  Widget _buildMenuItemRow(String title, {bool isLast = false}) {
    // 메뉴 제목에 따른 아이콘 경로 결정
    String getIconPath(String menuTitle) {
      switch (menuTitle) {
        case '총 포인트 내역':
          return 'assets/icons/parent/my/point_balance.png';
        case '용돈 지급 내역':
          return 'assets/icons/parent/my/point_history.png';
        case '활동내역':
          return 'assets/icons/parent/my/activity_history.png';
        case '총 분석 리포트':
          return 'assets/icons/parent/my/analyis_report.png';
        case '멤버 관리':
          return 'assets/icons/parent/my/member_management.png';
        case '가족 멤버 관리':
          return 'assets/icons/parent/my/family_management.png';
        case '구독권 관리':
          return 'assets/icons/parent/my/subscrition_management.png';
        case '고객센터':
          return 'assets/icons/parent/my/customer_service.png';
        case '공지사항':
          return 'assets/icons/parent/my/notice.png';
        case '친구 초대하기':
          return 'assets/icons/parent/my/invite.png';
        case '리틀뱅크혜택':
          return 'assets/icons/parent/my/subscrition_management.png'; // 구독권 관리 아이콘과 동일한 것을 사용
        default:
          return 'assets/icons/parent/my/notice.png';
      }
    }

    return InkWell(
      onTap: () async {
        // 메뉴 항목에 따라 다른 화면으로 이동
        if (title == '총 포인트 내역') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ParentAccountBalanceScreen(),
            ),
          );
        }
        // 용돈 지급 내역 메뉴 처리
        else if (title == '용돈 지급 내역') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ParentAllowanceHistoryScreen(),
            ),
          );
        }
        // 가족멤버관리 메뉴 처리
        else if (title == '가족 멤버 관리') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ParentFamilyManagementScreen(),
            ),
          );
        }
        // 총 분석 리포트 메뉴 처리
        else if (title == '총 분석 리포트') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const MyChildrenReportScreen(),
            ),
          );
        }
        // 멤버 관리 메뉴 처리
        else if (title == '멤버 관리') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ParentMemberManagementScreen(),
            ),
          );
        }
        // 구독권 관리 메뉴 처리
        else if (title == '구독권 관리') {
          print('🔍 [마이페이지] 구독권 관리 메뉴 클릭됨');

          // 현재 활성 구독 상태 확인 (일반 구독권 + 무료 구독권)
          print('🔍 [마이페이지] getCurrentActiveSubscription 호출...');
          final activeSubscription =
              await SubscriptionService.getCurrentActiveSubscription();
          print('🔍 [마이페이지] activeSubscription 결과: $activeSubscription');

          if (activeSubscription != null) {
            // 구독 중인 경우 (일반 구독권 또는 무료 구독권) 구독권 관리 화면으로 이동
            print('✅ [마이페이지] 활성 구독권 발견 - 구독권 관리 화면으로 이동');
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ParentSubscriptionOnScreen(),
              ),
            );
          } else {
            // 구독 중이 아닌 경우 혜택 화면으로 이동
            print('❌ [마이페이지] 활성 구독권 없음 - 리틀뱅크혜택 화면으로 이동');
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ParentLittleBankBenefitsScreen(),
              ),
            );
          }
        }
        // 활동내역 메뉴 처리
        else if (title == '활동내역') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ParentActivityHistoryScreen(),
            ),
          );
        }
        // 고객센터 메뉴 처리
        else if (title == '고객센터') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ParentCustomerServiceScreen(),
            ),
          );
        }
        // 공지사항 메뉴 처리
        else if (title == '공지사항') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ParentNoticeScreen()),
          );
        }
        // 친구 초대하기 메뉴 처리
        else if (title == '친구 초대하기') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ShareWithFriendScreen(),
            ),
          );
        }
        // 리틀뱅크혜택 메뉴 처리
        else if (title == '리틀뱅크혜택') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ParentLittleBankBenefitsScreen(),
            ),
          );
        }
      },
      child: Container(
        padding: EdgeInsets.fromLTRB(20, 16, 20, isLast ? 20 : 16),
        color: Colors.white,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  // 메뉴 아이콘
                  Image.asset(
                    getIconPath(title),
                    width: 20,
                    height: 20,
                    errorBuilder:
                        (context, error, stackTrace) => Icon(
                          Icons.circle,
                          size: 20,
                          color: const Color(0xFF999999),
                        ),
                  ),
                  SizedBox(width: 12),
                  // 메뉴 제목
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        color: const Color(0xFF353535),
                        fontSize: 13,
                        fontFamily: 'Pretendard-ExtraLight',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Image.asset(
              'assets/icons/go.png',
              width: 20,
              height: 20,
              errorBuilder: (context, error, stackTrace) => Icon(
                Icons.chevron_right,
                color: const Color(0xFFCCCCCC),
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 프로필 이미지 콘텐츠를 구성하는 메서드
  Widget _buildProfileImageContent() {
    final String baseUrl = "http://3.34.52.239:8080/"; // 서버 기본 URL
    final String s3BaseUrl =
        "https://littlebank-dev.s3.ap-northeast-2.amazonaws.com/"; // S3 기본 URL

    if (_userInfo?['profileImagePath'] != null &&
        _userInfo!['profileImagePath'].toString().isNotEmpty) {
      final String imagePath = _userInfo!['profileImagePath'].toString();

      // 이미 http로 시작하는 완전한 URL인 경우
      if (imagePath.startsWith('http')) {
        return FutureBuilder<Map<String, String>>(
          future: AuthService.getImageHeaders(),
          builder: (context, snapshot) {
            return CachedNetworkImage(
              imageUrl: imagePath,
              fit: BoxFit.cover,
              httpHeaders: snapshot.data ?? {},
              placeholder:
                  (context, url) =>
                      CircularProgressIndicator(color: Colors.white),
              errorWidget: (context, url, error) {
                print('이미지 로드 오류 (완전 URL): $error');
                return Icon(Icons.person, color: Colors.white);
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
            return Icon(Icons.person, color: Colors.white);
          },
        );
      }
      // 실제 로컬 파일인 경우 (/ 또는 절대 경로로 시작하는 경우만)
      else if (imagePath.startsWith('/') && File(imagePath).existsSync()) {
        return Image.file(
          File(imagePath),
          fit: BoxFit.cover,
          errorBuilder:
              (context, error, stackTrace) =>
                  Icon(Icons.person, color: Colors.white),
        );
      }
    }

    // 이미지가 없거나 모든 시도가 실패한 경우
    final userName = _userInfo?['name'] ?? '?';
    final firstLetter = userName.isNotEmpty ? userName.substring(0, 1) : '?';
    return Center(
      child: Text(
        firstLetter,
        style: TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.bold,
          fontFamily: 'Pretendard-Bold',
        ),
      ),
    );
  }
}

// 자녀 선택 모달 위젯
class ChildSelectionModal extends StatefulWidget {
  final List<dynamic> children;
  final int initialSelectedIndex;
  final Function(Map<String, dynamic>, int) onChildSelected;

  const ChildSelectionModal({
    Key? key,
    required this.children,
    required this.initialSelectedIndex,
    required this.onChildSelected,
  }) : super(key: key);

  @override
  State<ChildSelectionModal> createState() => _ChildSelectionModalState();
}

class _ChildSelectionModalState extends State<ChildSelectionModal> {
  late int selectedIndex;

  @override
  void initState() {
    super.initState();
    selectedIndex = widget.initialSelectedIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 20),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 420, minWidth: 420),
        child: Container(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 상단 헤더
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                decoration: ShapeDecoration(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '변경할 자녀를 선택해 주세요',
                            style: TextStyle(
                              color: const Color(0xFF202020),
                              fontSize: 16,
                              fontFamily: 'Pretendard-Bold',
                              letterSpacing: -0.64,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Icon(
                            Icons.close,
                            color: Colors.grey,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      '선택한 프로필에 따라 자녀의 정보를 조회할 수 있어요',
                      style: TextStyle(
                        color: const Color(0xFF999999),
                        fontSize: 10,
                        fontFamily: 'Pretendard-Light',
                        letterSpacing: -0.20,
                      ),
                    ),
                  ],
                ),
              ),

              // 자녀 프로필 그리드
              Container(
                width: 420,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                decoration: BoxDecoration(color: Colors.white),
                child: _buildChildrenGrid(),
              ),

              // 하단 버튼
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 24,
                ),
                decoration: ShapeDecoration(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                  ),
                ),
                child: GestureDetector(
                  onTap: () {
                    widget.onChildSelected(
                      widget.children[selectedIndex],
                      selectedIndex,
                    );
                    Navigator.pop(context);
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: ShapeDecoration(
                      color: const Color(0xFF5D9EFF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      '변경하기',
                      textAlign: TextAlign.center,
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChildrenGrid() {
    List<Widget> rows = [];

    for (int i = 0; i < widget.children.length; i += 3) {
      List<Widget> rowChildren = [];
      int childrenInThisRow =
          (i + 3 <= widget.children.length) ? 3 : widget.children.length - i;

      for (int j = i; j < i + 3 && j < widget.children.length; j++) {
        final child = widget.children[j];
        final isSelected = selectedIndex == j;
        final profileImagePath = child['profileImagePath'];

        rowChildren.add(
          GestureDetector(
            onTap: () {
              setState(() {
                selectedIndex = j;
              });
            },
            child: Container(
              width: 80,
              height: 80,
              decoration: ShapeDecoration(
                shape: OvalBorder(
                  side: BorderSide(
                    width: isSelected ? 3.0 : 0.80,
                    color:
                        isSelected
                            ? const Color(0xFF5D9EFF)
                            : const Color(0xFF146AFF),
                  ),
                ),
              ),
              child: Stack(
                children: [
                  // 프로필 이미지
                  ClipRRect(
                    borderRadius: BorderRadius.circular(40),
                    child:
                        profileImagePath != null && profileImagePath.isNotEmpty
                            ? CachedNetworkImage(
                              imageUrl: AuthService.getFullProfileImageUrl(
                                profileImagePath,
                              ),
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                              placeholder:
                                  (context, url) => Container(
                                    color: Colors.grey[300],
                                    child: Icon(
                                      Icons.person,
                                      color: Colors.grey[600],
                                      size: 40,
                                    ),
                                  ),
                              errorWidget:
                                  (context, url, error) => Container(
                                    color: Colors.grey[300],
                                    child: Icon(
                                      Icons.person,
                                      color: Colors.grey[600],
                                      size: 40,
                                    ),
                                  ),
                            )
                            : Container(
                              width: 80,
                              height: 80,
                              color: Colors.grey[300],
                              child: Icon(
                                Icons.person,
                                color: Colors.grey[600],
                                size: 40,
                              ),
                            ),
                  ),

                  // 선택되지 않은 경우 RGB(93, 100, 101) 오버레이
                  if (!isSelected)
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Color.fromRGBO(93, 100, 101, 0.6),
                        shape: BoxShape.circle,
                      ),
                    ),

                  // 선택된 경우 체크 아이콘
                  if (isSelected)
                    Positioned(
                      right: 4,
                      bottom: 4,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: const Color(0xFF5D9EFF),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Icon(Icons.check, color: Colors.white, size: 14),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      }

      // 행별로 다른 정렬 방식 적용
      Widget rowWidget;
      if (childrenInThisRow == 3) {
        // 3명인 경우: spaceEvenly로 넓게 배치
        rowWidget = Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: rowChildren,
        );
      } else {
        // 2명 이하인 경우: 가운데 정렬하고 좁은 간격으로 배치
        rowWidget = Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (int k = 0; k < rowChildren.length; k++) ...[
              rowChildren[k],
              if (k < rowChildren.length - 1) SizedBox(width: 24), // 더 좁은 간격
            ],
          ],
        );
      }

      rows.add(rowWidget);

      if (i + 3 < widget.children.length) {
        rows.add(SizedBox(height: 24));
      }
    }

    return Column(mainAxisSize: MainAxisSize.min, children: rows);
  }
}
