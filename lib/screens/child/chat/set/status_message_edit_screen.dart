import 'package:flutter/material.dart';
import '../../../../services/relationship_service.dart';

class StatusMessageEditScreen extends StatefulWidget {
  final String? initialStatusMessage;

  const StatusMessageEditScreen({super.key, this.initialStatusMessage});

  @override
  State<StatusMessageEditScreen> createState() =>
      _StatusMessageEditScreenState();
}

class _StatusMessageEditScreenState extends State<StatusMessageEditScreen> {
  final TextEditingController _statusMessageController =
      TextEditingController();
  final FocusNode _statusMessageFocus = FocusNode();
  bool _isLoading = false;
  String? _errorMessage;
  final int _maxLength = 50; // 상태 메시지 최대 길이

  @override
  void initState() {
    super.initState();
    _statusMessageController.text = widget.initialStatusMessage ?? '';

    // 포커스 자동 지정
    Future.delayed(Duration.zero, () {
      FocusScope.of(context).requestFocus(_statusMessageFocus);
    });
  }

  @override
  void dispose() {
    _statusMessageController.dispose();
    _statusMessageFocus.dispose();
    super.dispose();
  }

  // 상태 메시지 저장
  Future<void> _saveStatusMessage() async {
    // 입력값 검증
    final statusMessage = _statusMessageController.text.trim();
    if (statusMessage.isEmpty) {
      setState(() {
        _errorMessage = '상태 메시지를 입력해주세요.';
      });
      return;
    }

    // 초기값과 같으면 변경 없이 돌아가기
    if (statusMessage == widget.initialStatusMessage) {
      Navigator.pop(context);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // API 호출
      final result = await RelationshipService.updateStatusMessage(
        statusMessage,
      );

      if (result != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('상태 메시지가 변경되었습니다.'),
              backgroundColor: Color(0xFF3A88F4),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );

          // 성공 시 결과 반환하고 화면 닫기
          Navigator.pop(context, result);
        }
      } else {
        setState(() {
          _errorMessage = '상태 메시지 변경에 실패했습니다. 다시 시도해주세요.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '오류가 발생했습니다: $e';
        _isLoading = false;
      });
      print('상태 메시지 저장 중 오류: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // 화면 탭해서 키보드 닫기
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: Text(
            '상태 메시지 설정',
            style: TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontFamily: 'Pretendard-Bold',
              fontWeight: FontWeight.w700,
            ),
          ),
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            // 저장 버튼
            TextButton(
              onPressed: _isLoading ? null : _saveStatusMessage,
              style: TextButton.styleFrom(foregroundColor: Color(0xFF3A88F4)),
              child:
                  _isLoading
                      ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Color(0xFF3A88F4),
                          strokeWidth: 2,
                        ),
                      )
                      : Text(
                        '저장',
                        style: TextStyle(
                          color: Color(0xFF3A88F4),
                          fontSize: 16,
                          fontFamily: 'Pretendard-Medium',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 안내 텍스트
              Text(
                '나를 표현하는 상태 메시지를 입력해주세요',
                style: TextStyle(
                  color: Color(0xFF666666),
                  fontSize: 14,
                  fontFamily: 'Pretendard-Regular',
                  letterSpacing: -0.3,
                ),
              ),
              SizedBox(height: 16),

              // 입력 필드
              TextField(
                controller: _statusMessageController,
                focusNode: _statusMessageFocus,
                style: TextStyle(
                  color: Color(0xFF202020),
                  fontSize: 16,
                  fontFamily: 'Pretendard-Regular',
                ),
                decoration: InputDecoration(
                  hintText: '상태 메시지를 입력하세요',
                  hintStyle: TextStyle(
                    color: Color(0xFFCCCCCC),
                    fontSize: 16,
                    fontFamily: 'Pretendard-Regular',
                  ),
                  filled: true,
                  fillColor: Color(0xFFF5F5F5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  counterText:
                      '${_statusMessageController.text.length}/$_maxLength',
                  counterStyle: TextStyle(
                    color: Color(0xFF8490A3),
                    fontSize: 12,
                    fontFamily: 'Pretendard-Regular',
                  ),
                ),
                maxLength: _maxLength,
                maxLines: 3,
                minLines: 1,
                textInputAction: TextInputAction.done,
                onChanged: (value) {
                  // 글자 수 카운트를 위한 상태 업데이트
                  setState(() {});
                },
                onSubmitted: (_) => _saveStatusMessage(),
              ),

              // 오류 메시지 표시
              if (_errorMessage != null) ...[
                SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                    fontFamily: 'Pretendard-Regular',
                  ),
                ),
              ],

              SizedBox(height: 16),

              // 도움말
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Color(0xFF3A88F4),
                      size: 16,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '상태 메시지는 친구 목록에서 표시되며 언제든지 변경할 수 있습니다.',
                        style: TextStyle(
                          color: Color(0xFF3A88F4),
                          fontSize: 12,
                          fontFamily: 'Pretendard-Regular',
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
    );
  }
}
