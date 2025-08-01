import 'package:flutter/material.dart';
import '../../../../../services/auth_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../modal/pin_input_bottom_sheet.dart';

class ConfirmSendBottomSheet extends StatefulWidget {
  final String senderName;
  final String senderPhone;
  final String receiverName;
  final String receiverPhone;
  final String amount;
  final String userProfileImage;
  final int? receiverId;
  final VoidCallback? onConfirm;
  final VoidCallback? onClose;
  final Function(String pin)? onPinConfirmed;
  // 출금 관련 정보 추가
  final String? selectedBank;
  final String? accountNumber;
  final int? fee;
  final int? netAmount;

  const ConfirmSendBottomSheet({
    Key? key,
    this.senderName = '',
    this.senderPhone = '',
    this.receiverName = '',
    this.receiverPhone = '',
    this.amount = '30,000',
    this.userProfileImage = '',
    this.receiverId,
    this.onConfirm,
    this.onClose,
    this.onPinConfirmed,
    this.selectedBank,
    this.accountNumber,
    this.fee,
    this.netAmount,
  }) : super(key: key);

  @override
  State<ConfirmSendBottomSheet> createState() => _ConfirmSendBottomSheetState();
}

class _ConfirmSendBottomSheetState extends State<ConfirmSendBottomSheet> {
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

      // 받는 사람 정보 가져오기 (userProfileImage에서 프로필 이미지 정보 사용)
      Map<String, dynamic>? receiverInfo;
      if (widget.userProfileImage.isNotEmpty) {
        // userProfileImage가 있으면 받는 사람의 프로필 이미지 정보로 사용
        receiverInfo = {
          'profileImagePath': widget.userProfileImage,
          'name': widget.receiverName,
          'phone': widget.receiverPhone,
        };
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

  // 프로필 이미지 위젯 생성
  Widget _buildProfileImage(
    Map<String, dynamic>? userInfo, {
    double size = 44,
    String? fallbackImage,
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

    // fallback 이미지가 있는 경우
    if (fallbackImage != null && fallbackImage.isNotEmpty) {
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
        child: ClipOval(child: _buildFallbackImage(fallbackImage, size)),
      );
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

  // PIN 입력 바텀시트 표시
  void _showPinInputBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => PinInputBottomSheet(
            title: '결제 비밀번호를 입력해 주세요',
            selectedBank: widget.selectedBank,
            accountNumber: widget.accountNumber,
            amount: widget.amount,
            fee: widget.fee,
            netAmount: widget.netAmount,
            receiverName: widget.receiverName,
            receiverPhone: widget.receiverPhone,
            senderName: widget.senderName,
            receiverId: widget.receiverId,
            onPinConfirm: (pin) {
              // PIN 검증 성공 시 실행
              Navigator.pop(context); // PIN 바텀시트 닫기
              Navigator.pop(context); // 확인 바텀시트 닫기

              // PIN 확인 콜백 호출
              if (widget.onPinConfirmed != null) {
                widget.onPinConfirmed!(pin);
              } else if (widget.onConfirm != null) {
                widget.onConfirm!();
              }
            },
            onCancel: () {
              // 취소 시 PIN 바텀시트만 닫기
              print('PIN 입력 취소됨');
            },
          ),
    );
  }

  // fallback 이미지 처리 (네트워크 URL 또는 asset)
  Widget _buildFallbackImage(String imagePath, double size) {
    final String s3BaseUrl =
        "https://littlebank-dev.s3.ap-northeast-2.amazonaws.com/";

    // S3 URL인 경우
    if (imagePath.startsWith('images/')) {
      final s3Url = s3BaseUrl + imagePath;
      return Image.network(
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
      );
    }
    // 완전한 HTTP URL인 경우
    else if (imagePath.startsWith('http')) {
      return FutureBuilder<Map<String, String>>(
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
      );
    }
    // Asset 이미지인 경우
    else {
      return Image.asset(
        imagePath,
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
      );
    }
  }

  // 전화번호 포맷팅 함수 (하이픈 추가)
  String _formatPhoneNumber(String phone) {
    // 빈 문자열인 경우 빈 문자열 반환
    if (phone.isEmpty) return '';

    // 숫자만 추출
    String cleanedPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');

    if (cleanedPhone.length == 11) {
      // 010-1234-5678 형식
      return '${cleanedPhone.substring(0, 3)}-${cleanedPhone.substring(3, 7)}-${cleanedPhone.substring(7)}';
    } else if (cleanedPhone.length == 10) {
      // 02-1234-5678 또는 031-123-4567 형식
      if (cleanedPhone.startsWith('02')) {
        return '${cleanedPhone.substring(0, 2)}-${cleanedPhone.substring(2, 6)}-${cleanedPhone.substring(6)}';
      } else {
        return '${cleanedPhone.substring(0, 3)}-${cleanedPhone.substring(3, 6)}-${cleanedPhone.substring(6)}';
      }
    }

    // 포맷팅할 수 없는 경우 원본 반환
    return phone;
  }

  @override
  Widget build(BuildContext context) {
    final currentUserName = _currentUserInfo?['name'] ?? widget.senderName;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 헤더
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '보내기 전에 한 번 더 확인해 주세요',
                  style: TextStyle(
                    fontFamily: 'Pretendard-Bold',
                    fontSize: 18,
                    letterSpacing: -0.72,
                    color: Color(0xFF202020),
                  ),
                ),
                GestureDetector(
                  onTap: widget.onClose ?? () => Navigator.pop(context),
                  child: Icon(Icons.close, size: 20, color: Color(0xFF999999)),
                ),
              ],
            ),
          ),

          // 내용
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
            child: Column(
              children: [
                // 확인 메시지
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: widget.receiverName,
                        style: TextStyle(
                          color: const Color(0xFF3A88F4),
                          fontSize: 18,
                          fontFamily: 'Pretendard-Bold',
                          letterSpacing: -0.72,
                        ),
                      ),
                      TextSpan(
                        text: '님에게 ',
                        style: TextStyle(
                          color: const Color(0xFF202020),
                          fontSize: 18,
                          fontFamily: 'Pretendard-Bold',
                          letterSpacing: -0.72,
                        ),
                      ),
                      TextSpan(
                        text: '${widget.amount}원',
                        style: TextStyle(
                          color: const Color(0xFF3A88F4),
                          fontSize: 18,
                          fontFamily: 'Pretendard-Bold',
                          letterSpacing: -0.72,
                        ),
                      ),
                      TextSpan(
                        text: '을 보낼까요?',
                        style: TextStyle(
                          color: const Color(0xFF202020),
                          fontSize: 18,
                          fontFamily: 'Pretendard-Bold',
                          letterSpacing: -0.72,
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // 사용자 정보
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // 보내는 사람
                      Expanded(
                        child: _buildUserInfo(
                          name: currentUserName,
                          phone:
                              _currentUserInfo?['phone'] ?? widget.senderPhone,
                          userInfo: _currentUserInfo,
                          fallbackImage: 'assets/icons/my/default_profile.png',
                          isLeft: true,
                        ),
                      ),

                      // 화살표
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Image.asset(
                          'assets/icons/parent/bank/arrow.png',
                          width: 20,
                          height: 20,
                        ),
                      ),

                      // 받는 사람
                      Expanded(
                        child: _buildUserInfo(
                          name: widget.receiverName,
                          phone: widget.receiverPhone,
                          userInfo: _receiverUserInfo,
                          fallbackImage:
                              widget.userProfileImage.isNotEmpty
                                  ? widget.userProfileImage
                                  : 'assets/icons/my/default_profile.png',
                          isLeft: false,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 하단 버튼
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _showPinInputBottomSheet,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF3A88F4),
                  padding: EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  '이대로 보내기',
                  style: TextStyle(
                    fontFamily: 'Pretendard-Light',
                    fontSize: 14,
                    letterSpacing: -0.28,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfo({
    required String name,
    required String phone,
    Map<String, dynamic>? userInfo,
    String? fallbackImage,
    required bool isLeft,
  }) {
    return Container(
      padding: EdgeInsets.all(8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _isLoadingUserInfo
              ? Container(
                width: isLeft ? 48 : 44,
                height: isLeft ? 48 : 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey[300],
                ),
                child: CircularProgressIndicator(strokeWidth: 2),
              )
              : _buildProfileImage(
                userInfo,
                size: isLeft ? 48 : 44,
                fallbackImage: fallbackImage,
              ),
          const SizedBox(height: 8),
          Text(
            name,
            style: TextStyle(
              fontFamily: 'Pretendard-Medium',
              fontSize: 14,
              letterSpacing: -0.28,
              color: Color(0xFF4A4A4A),
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
          if (phone.isNotEmpty)
            Text(
              _formatPhoneNumber(phone),
              style: TextStyle(
                fontFamily: 'Pretendard-Light',
                fontSize: 12,
                letterSpacing: -0.24,
                color: Color(0xFF999999),
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }
}
