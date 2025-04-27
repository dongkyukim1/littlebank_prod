import 'package:flutter/material.dart';
import '../../../theme/agreement/agreement_styles.dart';

class TermsContent extends StatelessWidget {
  final String content;

  const TermsContent({super.key, required this.content});

  @override
  Widget build(BuildContext context) {
    // 약관 내용을 섹션별로 처리
    final sections = content.split('\n\n');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...sections.map((section) {
          // 제목 섹션 (제1조, 제2조 등)
          if (section.contains('제') && section.contains('조:')) {
            final parts = section.split(':');
            return Container(
              margin: const EdgeInsets.only(bottom: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8.0,
                      horizontal: 12.0,
                    ),
                    decoration: AgreementStyles.highlightDecoration,
                    child: Text(
                      parts[0].trim(),
                      style: AgreementStyles.contentHeadingStyle,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    parts.length > 1 ? parts[1].trim() : '',
                    style: AgreementStyles.contentTextStyle,
                  ),
                ],
              ),
            );
          }
          // 번호 붙은 목록 (1. 2. 등)
          else if (section.contains('1.')) {
            // 번호로 시작하는 경우 리스트 항목으로 처리
            final listItems = section.split('\n');
            return Container(
              margin: const EdgeInsets.only(bottom: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children:
                    listItems
                        .map(
                          (item) => Container(
                            margin: const EdgeInsets.only(bottom: 8.0),
                            child: Text(
                              item.trim(),
                              style: AgreementStyles.contentTextStyle,
                            ),
                          ),
                        )
                        .toList(),
              ),
            );
          }
          // 제목 (개인정보 수집 및 이용 동의 등)
          else if (section.contains('동의') ||
              section.contains('안내') ||
              section.contains('약관')) {
            return Container(
              margin: const EdgeInsets.only(bottom: 20.0),
              child: Text(
                section.trim(),
                style: AgreementStyles.sectionTitleStyle,
              ),
            );
          }
          // 일반 텍스트
          else {
            return Container(
              margin: const EdgeInsets.only(bottom: 16.0),
              child: Text(
                section.trim(),
                style: AgreementStyles.contentTextStyle,
              ),
            );
          }
        }),
      ],
    );
  }
}

class TermsBottomSheet extends StatefulWidget {
  final String title;
  final String content;
  final Function(bool) onAgreed;

  const TermsBottomSheet({
    super.key,
    required this.title,
    required this.content,
    required this.onAgreed,
  });

  @override
  _TermsBottomSheetState createState() => _TermsBottomSheetState();
}

class _TermsBottomSheetState extends State<TermsBottomSheet> {
  final bool _isAgreed = false;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      expand: false,
      builder:
          (context, scrollController) => Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x5B000000),
                  blurRadius: 8,
                  offset: Offset(0, -4),
                  spreadRadius: 0,
                )
              ],
            ),
            child: Column(
              children: [
                // 상단 드래그 핸들
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: AgreementStyles.handleDecoration,
                ),
                // 헤더 영역
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 20,
                  ),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          widget.title,
                          style: AgreementStyles.sectionTitleStyle,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: AgreementStyles.closeButtonDecoration,
                          child: const Icon(Icons.close, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(height: 1, color: const Color(0xFFEEEEEE)),
                // 약관 내용 영역
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 20,
                    ),
                    child: TermsContent(content: widget.content),
                  ),
                ),
                // 하단 동의 버튼
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onAgreed(true);
                      Navigator.pop(context);
                    },
                    style: AgreementStyles.primaryButtonStyle,
                    child: const Text(
                      '동의',
                      style: AgreementStyles.buttonTextStyle,
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }
}
