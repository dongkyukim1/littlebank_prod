import 'package:flutter/material.dart';
import 'terms_of_service.dart';
import 'privacy_collection.dart';
import 'minor_guardian.dart';
import 'electronic_finance.dart';
import 'reward_guardian.dart';
import 'third_party_sharing.dart';
import 'data_processing_delegation.dart';
import 'marketing.dart';

class TermsDetailModal extends StatelessWidget {
  final String termsType;
  final String title;
  final VoidCallback? onAgreed;

  const TermsDetailModal({
    super.key,
    required this.termsType,
    required this.title,
    this.onAgreed,
  });

  String _getTermsContent() {
    switch (termsType) {
      case 'termsOfService':
        return termsOfServiceContent;
      case 'privacyCollection':
        return privacyCollectionContent;
      case 'minorGuardian':
        return minorGuardianContent;
      case 'electronicFinance':
        return electronicFinanceContent;
      case 'rewardGuardian':
        return rewardGuardianContent;
      case 'thirdPartySharing':
        return thirdPartySharingContent;
      case 'dataProcessingDelegation':
        return dataProcessingDelegationContent;
      case 'marketing':
        return marketingContent;
      default:
        return '약관 내용을 불러올 수 없습니다.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      width: screenWidth,
      height: screenHeight * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // 상단 헤더
          Container(
            width: screenWidth,
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFFF8F9FA),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF353535),
                      fontSize: 18,
                      fontFamily: 'Pretendard-Bold',
                      letterSpacing: -0.36,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Color(0xFF8490A3),
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 약관 내용
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Text(
                _getTermsContent(),
                style: const TextStyle(
                  color: Color(0xFF353535),
                  fontSize: 14,
                  fontFamily: 'Pretendard-Regular',
                  height: 1.6,
                  letterSpacing: -0.28,
                ),
              ),
            ),
          ),

          // 하단 버튼
          Container(
            width: screenWidth,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: GestureDetector(
              onTap: () {
                // 약관에 동의했음을 알리는 콜백 호출
                onAgreed?.call();
                Navigator.of(context).pop();
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: ShapeDecoration(
                  color: const Color(0xFF146AFF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Center(
                  child: Text(
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
          ),
        ],
      ),
    );
  }
} 