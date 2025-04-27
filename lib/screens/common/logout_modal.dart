import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../common/login_screen.dart';

class LogoutModal extends StatelessWidget {
  final Function? onLogoutSuccess;

  const LogoutModal({
    super.key,
    this.onLogoutSuccess,
  });

  // 로그아웃 처리 메서드
  Future<void> _handleLogout(BuildContext context) async {
    try {
      // 로딩 인디케이터 표시
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF5D9EFF),
          ),
        ),
      );

      // 로그아웃 API 호출
      final result = await AuthService.logout();

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
        if (onLogoutSuccess != null) {
          onLogoutSuccess!();
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

  // 모달 표시 메서드
  static void show(BuildContext context, {Function? onLogoutSuccess}) {
    showDialog(
      context: context,
      builder: (context) => LogoutModal(
        onLogoutSuccess: onLogoutSuccess,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: _buildDialogContent(context),
    );
  }

  // 모달 내용 구성
  Widget _buildDialogContent(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          // 제목
          const Text(
            '로그아웃',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 16),
          
          // 내용
          const Text(
            '정말 로그아웃 하시겠습니까?',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF666666),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          
          // 버튼 영역
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // 취소 버튼
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFFEEEEEE),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    '취소',
                    style: TextStyle(
                      color: Color(0xFF666666),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              
              // 로그아웃 버튼
              Expanded(
                child: TextButton(
                  onPressed: () => _handleLogout(context),
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFF5D9EFF),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    '로그아웃',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
} 