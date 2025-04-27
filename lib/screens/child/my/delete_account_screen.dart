import 'package:flutter/material.dart';
import '../../../services/auth_service.dart';
import '../../../widgets/common/bottom_navigation_bar.dart';

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  bool _isConfirmed = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE7ECF6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          '회원탈퇴',
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            spreadRadius: 0,
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '회원탈퇴 전 확인하세요',
                            style: TextStyle(
                              color: Color(0xFF202020),
                              fontSize: 18,
                              fontFamily: 'Pretendard',
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.36,
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildWarningItem(
                            '탈퇴 시 모든 회원 정보와 데이터가 삭제됩니다.',
                          ),
                          _buildWarningItem(
                            '삭제된 정보는 복구할 수 없습니다.',
                          ),
                          _buildWarningItem(
                            '진행 중인 거래가 있는 경우 탈퇴가 제한될 수 있습니다.',
                          ),
                          _buildWarningItem(
                            '구독권은 환불을 받을 수 없습니다.',
                            isHighlighted: true,
                          ),
                          _buildWarningItem(
                            '탈퇴 후 동일 계정으로 재가입이 가능하지만, 이전 정보는 복원되지 않습니다.',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    
                    // 약관 동의 체크박스
                    Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      child: CheckboxListTile(
                        value: _isConfirmed,
                        onChanged: (value) {
                          setState(() {
                            _isConfirmed = value ?? false;
                          });
                        },
                        title: const Text(
                          '위 내용을 모두 확인했으며, 회원탈퇴에 동의합니다.',
                          style: TextStyle(
                            color: Color(0xFF353535),
                            fontSize: 14,
                            fontFamily: 'Pretendard',
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        activeColor: const Color(0xFF146AFF),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        controlAffinity: ListTileControlAffinity.leading,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    
                    // 에러 메시지
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF0F0),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFFFFCCCC),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: Color(0xFFFF5252),
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(
                                    color: Color(0xFFFF5252),
                                    fontSize: 14,
                                    fontFamily: 'Pretendard',
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    
                    const SizedBox(height: 36),
                    
                    // 회원탈퇴 버튼
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isConfirmed ? _onDeleteAccountPressed : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF5252),
                          disabledBackgroundColor: const Color(0xFFDDDDDD),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          '회원탈퇴',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontFamily: 'Pretendard',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // 취소 버튼
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: Color(0xFFCCCCCC),
                            width: 1,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          '취소',
                          style: TextStyle(
                            color: Color(0xFF666666),
                            fontSize: 16,
                            fontFamily: 'Pretendard',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: const CommonBottomNavigationBar(selectedIndex: 4),
    );
  }

  // 경고 항목 위젯
  Widget _buildWarningItem(String text, {bool isHighlighted = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: isHighlighted ? const Color(0xFFFF3B30) : const Color(0xFFFF5252),
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: isHighlighted ? const Color(0xFFFF3B30) : const Color(0xFF353535),
                fontSize: 14,
                fontFamily: 'Pretendard',
                fontWeight: isHighlighted ? FontWeight.w500 : FontWeight.w400,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 회원탈퇴 버튼 클릭 핸들러
  Future<void> _onDeleteAccountPressed() async {
    // 로딩 상태 시작
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 회원탈퇴 API 호출
      final success = await AuthService.deleteAccount();
      
      if (success) {
        if (mounted) {
          // 탈퇴 성공 시 로그인 화면으로 이동 (모든 스택 삭제)
          Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
          
          // 성공 메시지 표시
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('회원탈퇴가 완료되었습니다.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      // 오류 발생 시 에러 메시지 표시
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }
} 