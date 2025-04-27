import 'package:flutter/material.dart';
import '../../../models/agreement/terms_data.dart';
import '../../../theme/agreement/agreement_styles.dart';

class TermsItemCard extends StatelessWidget {
  final TermsItem item;
  final bool isAgreed;
  final Function(bool) onAgreementChanged;
  final VoidCallback onViewDetail;

  const TermsItemCard({
    super.key,
    required this.item,
    required this.isAgreed,
    required this.onAgreementChanged,
    required this.onViewDetail,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: AgreementStyles.termItemDecoration,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // 항목 아이콘
                Container(
                  width: 40,
                  height: 40,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AgreementStyles.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Image.asset(
                    item.iconPath,
                    width: 24,
                    height: 24,
                    color: AgreementStyles.primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                // 약관 제목 및 설명
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.title, style: AgreementStyles.termTitleStyle),
                      const SizedBox(height: 4),
                      Text(
                        item.description,
                        style: AgreementStyles.termDescriptionStyle,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // 체크박스
                GestureDetector(
                  onTap: () => onAgreementChanged(!isAgreed),
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: AgreementStyles.checkboxDecoration(
                      isChecked: isAgreed,
                    ),
                    child:
                        isAgreed
                            ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 18,
                            )
                            : null,
                  ),
                ),
              ],
            ),
          ),
          // 약관 상세 보기 버튼
          InkWell(
            onTap: onViewDetail,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
              ),
              alignment: Alignment.center,
              child: Text(
                '약관 보기',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AgreementStyles.primaryColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
