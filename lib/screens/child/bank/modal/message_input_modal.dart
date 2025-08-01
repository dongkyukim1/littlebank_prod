import 'package:flutter/material.dart';

class MessageInputModal extends StatefulWidget {
  const MessageInputModal({super.key});

  @override
  State<MessageInputModal> createState() => _MessageInputModalState();
}

class _MessageInputModalState extends State<MessageInputModal> {
  final TextEditingController _messageController = TextEditingController();
  final int _maxLength = 50;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 제목
            const Text(
              '메시지 남기기',
              style: TextStyle(
                color: Color(0xFF333333),
                fontSize: 18,
                fontFamily: 'Pretendard-SemiBold',
                letterSpacing: -0.36,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // 메시지 입력 필드
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE9ECEF), width: 1),
              ),
              child: TextField(
                controller: _messageController,
                maxLength: _maxLength,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: '메시지를 입력해 주세요 (선택사항)',
                  hintStyle: TextStyle(
                    color: Color(0xFF999999),
                    fontSize: 14,
                    fontFamily: 'Pretendard-Regular',
                    letterSpacing: -0.28,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(16),
                  counterStyle: TextStyle(
                    color: Color(0xFF999999),
                    fontSize: 12,
                    fontFamily: 'Pretendard-Regular',
                  ),
                ),
                style: const TextStyle(
                  color: Color(0xFF333333),
                  fontSize: 14,
                  fontFamily: 'Pretendard-Regular',
                  letterSpacing: -0.28,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 버튼들
            Row(
              children: [
                // 취소 버튼
                Expanded(
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFFE9ECEF),
                        width: 1,
                      ),
                    ),
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        '취소',
                        style: TextStyle(
                          color: Color(0xFF666666),
                          fontSize: 16,
                          fontFamily: 'Pretendard-Medium',
                          letterSpacing: -0.32,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // 확인 버튼
                Expanded(
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4285F4),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextButton(
                      onPressed: () {
                        final message = _messageController.text.trim();
                        Navigator.of(context).pop(message);
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        '확인',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontFamily: 'Pretendard-Medium',
                          letterSpacing: -0.32,
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
    );
  }
}
