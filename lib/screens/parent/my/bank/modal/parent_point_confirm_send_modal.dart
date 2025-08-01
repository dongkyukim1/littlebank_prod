import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../parent_point_transfer_complete_screen.dart';
import '../../../../../services/payment_service.dart';
import '../../../../../services/auth_service.dart';
import '../../../../../services/relationship_service.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ParentPointConfirmSendModal extends StatefulWidget {
  final String selectedBank;
  final String phoneNumber;
  final String receiverName;
  final String senderName;
  final String amount;
  final int? receiverId; // 수신자 ID 추가
  final Function() onPrevious;
  final Function() onConfirm;

  const ParentPointConfirmSendModal({
    super.key,
    required this.selectedBank,
    required this.phoneNumber,
    required this.receiverName,
    required this.senderName,
    required this.amount,
    this.receiverId, // 옵셔널로 추가
    required this.onPrevious,
    required this.onConfirm,
  });

  @override
  State<ParentPointConfirmSendModal> createState() =>
      _ParentPointConfirmSendModalState();
}

class _ParentPointConfirmSendModalState
    extends State<ParentPointConfirmSendModal> {
  String enteredPIN = '';
  bool _isTransferring = false; // 전송 중 상태

  // 사용자 정보
  Map<String, dynamic>? _currentUserInfo;
  Map<String, dynamic>? _receiverUserInfo;
  bool _isLoadingUserInfo = true;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  // 사용자 정보 로딩
  Future<void> _loadUserInfo() async {
    try {
      // 현재 로그인된 사용자 정보 가져오기
      final currentUser = await AuthService.getUserInfo();

      // 받는 사람 정보 가져오기 (receiverId가 있을 경우)
      Map<String, dynamic>? receiverInfo;
      if (widget.receiverId != null) {
        try {
          receiverInfo = await RelationshipService.getUserInfo(
            widget.receiverId!,
          );
          print('수신자 정보 로드 성공: $receiverInfo');
        } catch (e) {
          print('받는 사람 정보 로딩 실패: $e');
        }
      } else {
        print('receiverId가 null이어서 수신자 정보를 가져올 수 없습니다.');
      }

      if (mounted) {
        setState(() {
          _currentUserInfo = currentUser;
          _receiverUserInfo = receiverInfo;
          _isLoadingUserInfo = false;
        });
      }
    } catch (e) {
      print('사용자 정보 로딩 오류: $e');
      if (mounted) {
        setState(() {
          _isLoadingUserInfo = false;
        });
      }
    }
  }

  void _addDigit(String digit) {
    if (enteredPIN.length < 6) {
      HapticFeedback.lightImpact(); // 햅틱 피드백
      setState(() {
        enteredPIN += digit;
      });

      // PIN이 6자리가 되면 자동으로 다음 단계로 이동
      if (enteredPIN.length == 6) {
        _processPointTransfer();
      }
    }
  }

  void _deleteDigit() {
    if (enteredPIN.isNotEmpty) {
      HapticFeedback.lightImpact(); // 햅틱 피드백
      setState(() {
        enteredPIN = enteredPIN.substring(0, enteredPIN.length - 1);
      });
    }
  }

  // 프로필 이미지 위젯 생성
  Widget _buildProfileImage(
    Map<String, dynamic>? userInfo, {
    double size = 42,
  }) {
    final String baseUrl = "http://3.34.52.239:8080/";
    final String s3BaseUrl =
        "https://littlebank-dev.s3.ap-northeast-2.amazonaws.com/";

    if (userInfo?['profileImagePath'] != null &&
        userInfo!['profileImagePath'].toString().isNotEmpty) {
      final String imagePath = userInfo['profileImagePath'].toString();

      // S3 URL인 경우
      if (imagePath.startsWith('images/')) {
        final s3Url = s3BaseUrl + imagePath;
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                spreadRadius: .5,
                blurRadius: 1,
              ),
            ],
          ),
          child: ClipOval(
            child: Image.network(
              s3Url,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[300],
                  child: Icon(
                    Icons.person,
                    color: Colors.grey[600],
                    size: size * 0.6,
                  ),
                );
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  color: Colors.grey[300],
                  child: Icon(
                    Icons.person,
                    color: Colors.grey[600],
                    size: size * 0.6,
                  ),
                );
              },
            ),
          ),
        );
      }
      // 완전한 URL인 경우
      else if (imagePath.startsWith('http')) {
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                spreadRadius: .5,
                blurRadius: 1,
              ),
            ],
          ),
          child: ClipOval(
            child: FutureBuilder<Map<String, String>>(
              future: AuthService.getImageHeaders(),
              builder: (context, snapshot) {
                return CachedNetworkImage(
                  imageUrl: imagePath,
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                  httpHeaders: snapshot.data ?? {},
                  placeholder:
                      (context, url) => Container(
                        color: Colors.grey[300],
                        child: Icon(
                          Icons.person,
                          color: Colors.grey[600],
                          size: size * 0.6,
                        ),
                      ),
                  errorWidget: (context, url, error) {
                    return Container(
                      color: Colors.grey[300],
                      child: Icon(
                        Icons.person,
                        color: Colors.grey[600],
                        size: size * 0.6,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        );
      }
    }

    // 기본 아이콘
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: .5,
            blurRadius: 1,
          ),
        ],
      ),
      child: ClipOval(
        child: Container(
          color: Colors.grey[300],
          child: Icon(Icons.person, color: Colors.grey[600], size: size * 0.6),
        ),
      ),
    );
  }

  // 실제 포인트 전송 처리
  Future<void> _processPointTransfer() async {
    if (_isTransferring) return; // 중복 호출 방지

    setState(() {
      _isTransferring = true;
    });

    try {
      // 1단계: PIN 검증
      print('[ParentPointConfirmSendModal] PIN 검증 시작: $enteredPIN');

      final verifyResult = await AuthService.verifyPin(pin: enteredPIN);
      print('[ParentPointConfirmSendModal] PIN 검증 응답: $verifyResult');

      // PIN 검증 실패 시 예외 발생
      if (verifyResult['success'] != true) {
        throw Exception(verifyResult['message'] ?? 'PIN 번호가 올바르지 않습니다');
      }

      print('[ParentPointConfirmSendModal] PIN 검증 성공!');

      // 2단계: 포인트 전송 진행
      print('=== 포인트 전송 프로세스 시작 ===');
      print('수신자 ID: ${widget.receiverId}');
      print('수신자 이름: ${widget.receiverName}');
      print('전송 금액 (문자열): ${widget.amount}');

      // 금액 파싱 (콤마 제거)
      final String cleanAmount = widget.amount.replaceAll(',', '');
      final int pointAmount = int.parse(cleanAmount);
      print('파싱된 전송 금액 (정수): $pointAmount');

      if (widget.receiverId == null) {
        print('❌ 오류: 수신자 ID가 null입니다');
        throw Exception('수신자 정보가 없습니다');
      }

      print('✅ PaymentService.transferPointsGeneral 호출 시작');

      // 실제 포인트 전송 API 호출
      final response = await PaymentService.transferPointsGeneral(
        receiverId: widget.receiverId!,
        pointAmount: pointAmount,
        message: '${widget.receiverName}님에게 포인트 전송',
      );

      print('✅ 포인트 전송 API 응답 받음: $response');

      // 전송 성공시 완료 화면으로 이동
      if (mounted) {
        print('✅ 화면이 마운트됨, 포인트 새로고침 시작');

        // 현재 포인트 새로고침
        final userInfo = await AuthService.getUserInfo();
        final currentPoints = userInfo['point'] is int 
            ? userInfo['point'] 
            : int.tryParse(userInfo['point'].toString()) ?? 0;
        print('✅ 새로고침된 현재 포인트: $currentPoints');

        Navigator.pop(context); // 현재 모달 닫기

        // 포인트 전송 완료 화면으로 이동
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => ParentPointTransferCompleteScreen(
                  receiverName: widget.receiverName,
                  receiverPhone:
                      _receiverUserInfo?['phone'] ??
                      widget.phoneNumber, // 실제 수신자 전화번호 사용
                  amount: widget.amount,
                  remainingPoints: currentPoints, // 실제 잔여 포인트
                ),
          ),
        );

        print('✅ 포인트 전송 완료 화면으로 이동 완료');
      }
    } catch (e) {
      print('❌ 포인트 전송 실패: $e');
      print('❌ 오류 스택 트레이스: ${e.toString()}');

      if (mounted) {
        setState(() {
          _isTransferring = false;
          enteredPIN = ''; // PIN 초기화
        });

        // 오류 메시지 표시
        String errorMessage = '포인트 전송에 실패했습니다';
        if (e.toString().contains('부족')) {
          errorMessage = '보유 포인트가 부족합니다';
        } else if (e.toString().contains('PIN') ||
            e.toString().contains('비밀번호')) {
          errorMessage = '결제 비밀번호가 틀립니다';
        }

        // 에러 모달 표시
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              title: Text(
                '알림',
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'Pretendard-Bold',
                  color: Colors.black,
                ),
              ),
              content: Text(
                errorMessage,
                style: TextStyle(
                  fontSize: 14,
                  fontFamily: 'Pretendard-Light',
                  color: Colors.black,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    '확인',
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: 'Pretendard-Medium',
                      color: Color(0xFF3A88F4),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 화면 크기 가져오기
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // 현재 사용자 이름 (로그인된 사용자)
    final currentUserName = _currentUserInfo?['name'] ?? '사용자';

    return Container(
      height: screenHeight * 0.65, // 전체 화면의 약 2/3 높이
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 상단 타이틀
          Container(
            width: screenWidth,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: ShapeDecoration(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '보내기 전에 한 번 더 확인해 주세요',
                  style: TextStyle(
                    color: const Color(0xFF202020),
                    fontSize: 15,
                    fontFamily: 'Pretendard-Bold',
                    letterSpacing: -0.5,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(Icons.close, size: 18, color: Colors.grey),
                ),
              ],
            ),
          ),

          // 포인트 전송 정보 섹션
          Container(
            width: screenWidth,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: Colors.white),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 8),
                // 포인트 전송 텍스트
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: widget.receiverName,
                        style: TextStyle(
                          color: const Color(0xFF3A88F4),
                          fontSize: 16,
                          fontFamily: 'Pretendard-Bold',
                          letterSpacing: -0.5,
                        ),
                      ),
                      TextSpan(
                        text: '님에게 ',
                        style: TextStyle(
                          color: const Color(0xFF202020),
                          fontSize: 16,
                          fontFamily: 'Pretendard-Bold',
                          letterSpacing: -0.5,
                        ),
                      ),
                      TextSpan(
                        text: widget.amount,
                        style: TextStyle(
                          color: const Color(0xFF3A88F4),
                          fontSize: 16,
                          fontFamily: 'Pretendard-Bold',
                          letterSpacing: -0.5,
                        ),
                      ),
                      TextSpan(
                        text: '원을 보낼까요?',
                        style: TextStyle(
                          color: const Color(0xFF202020),
                          fontSize: 16,
                          fontFamily: 'Pretendard-Bold',
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),

                // 송금 계정 정보 (보내는 사람, 받는 사람)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 보내는 사람 정보 (현재 로그인된 사용자)
                    Padding(
                      padding: EdgeInsets.only(right: 26),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _isLoadingUserInfo
                              ? Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.grey[300],
                                ),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                              : _buildProfileImage(_currentUserInfo, size: 42),
                          SizedBox(height: 8),
                          Text(
                            currentUserName,
                            style: TextStyle(
                              color: const Color(0xFF4A4A4A),
                              fontSize: 13,
                              fontFamily: 'Pretendard-Medium',
                              letterSpacing: -0.28,
                            ),
                          ),
                          Text(
                            '리틀뱅크 포인트',
                            style: TextStyle(
                              color: const Color(0xFF999999),
                              fontSize: 11,
                              fontFamily: 'Pretendard-Light',
                              letterSpacing: -0.24,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 화살표 아이콘
                    Container(
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.arrow_forward,
                        color: const Color(0xFF8490A3),
                        size: 24,
                      ),
                    ),

                    // 받는 사람 정보
                    Padding(
                      padding: EdgeInsets.only(left: 26),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _isLoadingUserInfo
                              ? Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.grey[300],
                                ),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                              : _buildProfileImage(_receiverUserInfo, size: 42),
                          SizedBox(height: 8),
                          Text(
                            widget.receiverName,
                            style: TextStyle(
                              color: const Color(0xFF4A4A4A),
                              fontSize: 13,
                              fontFamily: 'Pretendard-Medium',
                              letterSpacing: -0.28,
                            ),
                          ),
                          Text(
                            _receiverUserInfo?['phone'] ??
                                widget.phoneNumber, // 실제 수신자 전화번호 사용
                            style: TextStyle(
                              color: const Color(0xFF999999),
                              fontSize: 11,
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
          ),

          SizedBox(height: 10),

          // PIN 입력용 숫자 키패드
          Expanded(
            child: Container(
              width: screenWidth,
              decoration: BoxDecoration(color: Colors.white),
              child: Column(
                children: [
                  // PIN 표시 (동그라미 6개)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        6,
                        (index) => Container(
                          width: 12,
                          height: 12,
                          margin: EdgeInsets.symmetric(horizontal: 6),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color:
                                index < enteredPIN.length
                                    ? const Color(0xFF3A88F4)
                                    : const Color(0xFFEEEEEE),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // 숫자 키패드
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildNumberKey('1'),
                            _buildNumberKey('2'),
                            _buildNumberKey('3'),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildNumberKey('4'),
                            _buildNumberKey('5'),
                            _buildNumberKey('6'),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildNumberKey('7'),
                            _buildNumberKey('8'),
                            _buildNumberKey('9'),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Expanded(child: Container()),
                            _buildNumberKey('0'),
                            Expanded(
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: _deleteDigit,
                                  borderRadius: BorderRadius.circular(25),
                                  splashColor: const Color(0xFFE0E0E0),
                                  highlightColor: const Color(0xFFEEEEEE),
                                  child: Container(
                                    height: 50,
                                    alignment: Alignment.center,
                                    child: Icon(
                                      Icons.backspace_outlined,
                                      color: const Color(0xFFCCCCCC),
                                      size: 22,
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
                ],
              ),
            ),
          ),

          // 하단 버튼 - 이전, 이대로 보내기
          Container(
            width: screenWidth,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: widget.onPrevious,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: ShapeDecoration(
                        color: const Color(0xFFE1E1E1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '이전',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontFamily: 'Pretendard-Light',
                          letterSpacing: -0.28,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: GestureDetector(
                    onTap:
                        _isTransferring
                            ? null
                            : () {
                              // PIN 체크 없이 바로 포인트 전송 (테스트용)
                              print('🔴 이대로 보내기 버튼 클릭됨');
                              _processPointTransfer();
                            },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: ShapeDecoration(
                        color:
                            _isTransferring
                                ? const Color(0xFFCCCCCC)
                                : const Color(0xFF3A88F4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      alignment: Alignment.center,
                      child:
                          _isTransferring
                              ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                              : Text(
                                '이대로 보내기',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontFamily: 'Pretendard-Light',
                                  letterSpacing: -0.28,
                                ),
                              ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 숫자 키 위젯 생성 함수
  Widget _buildNumberKey(String digit) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _addDigit(digit),
          borderRadius: BorderRadius.circular(25),
          splashColor: const Color(0xFFE0E0E0),
          highlightColor: const Color(0xFFEEEEEE),
          child: Container(
            height: 50,
            alignment: Alignment.center,
            child: Text(
              digit,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: const Color(0xFFCCCCCC),
                fontSize: 22,
                fontFamily: 'Pretendard-Light',
                letterSpacing: -0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
