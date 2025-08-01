import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../common/login_screen.dart';
import 'splash/splash_manager.dart';

class LogoutModal extends StatefulWidget {
  final Function? onLogoutSuccess;

  const LogoutModal({super.key, this.onLogoutSuccess});

  @override
  State<LogoutModal> createState() => _LogoutModalState();

  // 모달 표시 메서드
  static void show(BuildContext context, {Function? onLogoutSuccess}) {
    showDialog(
      context: context,
      builder: (context) => LogoutModal(onLogoutSuccess: onLogoutSuccess),
    );
  }
}

class _LogoutModalState extends State<LogoutModal> {
  String? userEmail;
  String? socialType;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  // 사용자 정보 로드
  Future<void> _loadUserInfo() async {
    try {
      // 먼저 저장된 이메일과 소셜 타입을 가져옴
      final email = await AuthService.getEmail();
      final type = await AuthService.getSocialType();
      
      // 만약 저장된 정보가 없다면 사용자 정보 API 호출
      if (email == null || email.isEmpty) {
        try {
          final userInfo = await AuthService.getUserInfo();
          setState(() {
            userEmail = userInfo['email'] ?? '사용자 이메일';
            socialType = type ?? 'NORMAL'; // 기본값을 NORMAL로 설정
            isLoading = false;
          });
          return;
        } catch (e) {
          print('사용자 정보 API 호출 실패: $e');
        }
      }
      
      setState(() {
        userEmail = email ?? '사용자 이메일';
        socialType = type ?? 'NORMAL'; // 기본값을 NORMAL로 설정
        isLoading = false;
      });
    } catch (e) {
      print('사용자 정보 로드 오류: $e');
      setState(() {
        userEmail = '사용자 이메일';
        socialType = 'NORMAL';
        isLoading = false;
      });
    }
  }

  // 가입 방법에 따른 아이콘 경로 반환
  String _getProfileIconPath() {
    if (socialType == 'NAVER') {
      return 'assets/images/naverid.png';
    } else if (socialType == 'KAKAO') {
      return 'assets/images/kakaoid.png';
    } else {
      return 'assets/images/normalid.png';
    }
  }

  // 로그아웃 처리 메서드
  Future<void> _handleLogout(BuildContext context) async {
    try {
      // 로딩 인디케이터 표시
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: Color(0xFF5D9EFF)),
        ),
      );

      // 로그아웃 API 호출
      final result = await AuthService.logout();

      // 로그아웃 시에는 스플래시 상태를 초기화하지 않음
      // await SplashManager.resetAllStatus();

      // 로딩 인디케이터 닫기
      if (context.mounted) {
        Navigator.pop(context);
      }

      // 로그아웃 결과 처리
      if (result['success'] == true) {
        // 서버 오류가 있었지만 로컬에서는 로그아웃 된 경우 알림 표시
        if (result.containsKey('serverError') && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? '로컬에서 로그아웃되었습니다.'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 3),
            ),
          );
        }

        // 성공 콜백 호출
        if (widget.onLogoutSuccess != null) {
          widget.onLogoutSuccess!();
        }

        // 마이페이지 닫기
        if (context.mounted) {
          Navigator.pop(context);
        }

        // 로그인 화면으로 이동
        if (context.mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
          );
        }
      } else {
        // 로그아웃 실패 처리 (실제로는 success가 항상 true이므로 이 코드는 실행되지 않을 가능성이 높음)
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? '로그아웃 중 오류가 발생했습니다.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // 로딩 인디케이터 닫기
      if (context.mounted) {
        Navigator.pop(context);
      }

      // 에러 메시지 표시
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('로그아웃 중 오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: _buildDialogContent(context),
    );
  }

  // 모달 내용 구성
  Widget _buildDialogContent(BuildContext context) {
    // 화면 크기에 따른 반응형 크기 계산
    final screenWidth = MediaQuery.of(context).size.width;
    final modalWidth = screenWidth - 32; // 양쪽 16px씩 빼고 나머지 전체 사용

    if (isLoading) {
      return Container(
        width: modalWidth,
        height: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: Color(0xFF5D9EFF)),
        ),
      );
    }

    return Container(
      width: modalWidth,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8, // 화면 높이의 80%로 제한
        minHeight: 200,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 상단 헤더 섹션
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 제목
                const Text(
                  '정말 로그아웃 하시겠습니까?',
                  style: TextStyle(
                    color: Color(0xFF202020),
                    fontSize: 16, // 18에서 16으로 줄임
                    fontFamily: 'Pretendard-Bold',
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.72,
                  ),
                ),
                const SizedBox(height: 8),
                // 설명 텍스트
                const Text(
                  '다시 로그인 시, 아래 계정으로 로그인 하실 수 있어요!',
                  style: TextStyle(
                    color: Color(0xFF999999),
                    fontSize: 12, // 14에서 12로 줄임
                    fontFamily: 'Pretendard-Light',
                    fontWeight: FontWeight.w300,
                    letterSpacing: -0.28,
                  ),
                ),
              ],
            ),
          ),
          
          // 사용자 정보 섹션
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: const BoxDecoration(color: Colors.white),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: ShapeDecoration(
                color: const Color(0xFFE7ECF6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  // 프로필 아이콘 (원형 제거)
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage(_getProfileIconPath()),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // 이메일
                  Expanded(
                    child: Text(
                      userEmail ?? '사용자 이메일',
                      style: const TextStyle(
                        color: Color(0xFF666666),
                        fontSize: 12, // 14에서 12로 줄임
                        fontFamily: 'Pretendard-Regular',
                        fontWeight: FontWeight.w400,
                        letterSpacing: -0.28,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // 버튼 섹션
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            decoration: const ShapeDecoration(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
            ),
            child: Row(
              children: [
                // 취소 버튼
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0xFFDADADA),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      '취소',
                      style: TextStyle(
                        color: Color(0xFFB6B6B6),
                        fontSize: 12, // 14에서 12로 줄임
                        fontFamily: 'Pretendard-Regular',
                        fontWeight: FontWeight.w400,
                        letterSpacing: -0.28,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // 로그아웃 버튼
                Expanded(
                  child: TextButton(
                    onPressed: () => _handleLogout(context),
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0xFF5D9EFF),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      '로그아웃',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12, // 14에서 12로 줄임
                        fontFamily: 'Pretendard-Regular',
                        fontWeight: FontWeight.w400,
                        letterSpacing: -0.28,
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
}
