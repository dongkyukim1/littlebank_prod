import 'package:flutter/material.dart';
import '../../../theme/agreement/agreement_styles.dart';

class AgreementAlert extends StatelessWidget {
  final VoidCallback onConfirm;

  const AgreementAlert({super.key, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 경고 아이콘
            Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(
                color: Color(0xFFFFEBEE),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                color: Color(0xFFE53935),
                size: 32,
              ),
            ),
            const SizedBox(height: 20),

            // 알림 메시지
            Column(
              children: [
                Text(
                  '필수 약관에 모두 동의해주세요',
                  style: AgreementStyles.titleStyle.copyWith(
                    fontSize: 18,
                    color: const Color(0xFFE53935),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  '서비스 이용을 위해 필수 약관에\n모두 동의해 주셔야 합니다.',
                  style: AgreementStyles.termDescriptionStyle,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 확인 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onConfirm();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AgreementStyles.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('확인', style: AgreementStyles.buttonTextStyle),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
