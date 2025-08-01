import 'package:flutter/material.dart';
import 'pin_setup_modal.dart';

class AccountVerifiedModal extends StatelessWidget {
  final Map<String, dynamic> institution;
  final String accountNumber;
  final String holderName;
  final String userId;
  final String jumin;
  final String? password;
  final String? name;
  final String? phone;
  final bool? marketingAgreed;
  final bool? agreedTermsOfService;
  final bool? agreedPrivacyCollection;
  final bool? agreedMinorGuardian;
  final bool? agreedElectronicFinance;
  final bool? agreedRewardGuardian;
  final bool? agreedThirdPartySharing;
  final bool? agreedDataProcessingDelegation;

  const AccountVerifiedModal({
    super.key,
    required this.institution,
    required this.accountNumber,
    required this.holderName,
    required this.userId,
    required this.jumin,
    this.password,
    this.name,
    this.phone,
    this.marketingAgreed,
    this.agreedTermsOfService,
    this.agreedPrivacyCollection,
    this.agreedMinorGuardian,
    this.agreedElectronicFinance,
    this.agreedRewardGuardian,
    this.agreedThirdPartySharing,
    this.agreedDataProcessingDelegation,
  });

  String _formatAccountNumber(String accountNumber) {
    if (accountNumber.length <= 4) return accountNumber;

    final middle =
        accountNumber.length > 6
            ? accountNumber.substring(4, 6)
            : accountNumber.substring(4);

    final last = accountNumber.length > 6 ? accountNumber.substring(6) : '';

    return '${accountNumber.substring(0, 4)}-$middle${last.isNotEmpty ? '-$last' : ''}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 390,
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
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
          // 상단 제목 영역
          Container(
            width: 390,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '계좌번호를 입력해 주세요',
                  style: TextStyle(
                    color: const Color(0xFF353535),
                    fontSize: 16,
                    fontFamily: 'Pretendard-Bold',
                    letterSpacing: -0.72,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '선택하신 ${institution['name']}의 정보를 둘 다 입력해 주세요',
                  style: TextStyle(
                    color: const Color(0xFF999999),
                    fontSize: 12,
                    fontFamily: 'Pretendard-Light',
                    letterSpacing: -0.28,
                  ),
                ),
              ],
            ),
          ),

          // 입력 필드 영역
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 계좌번호 표시
                Text(
                  '계좌번호',
                  style: TextStyle(
                    color: const Color(0xFFC4C4C4),
                    fontSize: 12,
                    fontFamily: 'Pretendard-Light',
                    letterSpacing: -0.28,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 358,
                  height: 48,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: ShapeDecoration(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      side: BorderSide(
                        width: 0.80,
                        color: const Color(0xFF5D9EFF),
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    _formatAccountNumber(accountNumber),
                    style: TextStyle(
                      color: const Color(0xFF353535),
                      fontSize: 12,
                      fontFamily: 'Pretendard-Light',
                      letterSpacing: -0.28,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 예금주명 표시
                Text(
                  '예금주명',
                  style: TextStyle(
                    color: const Color(0xFFC4C4C4),
                    fontSize: 12,
                    fontFamily: 'Pretendard-Light',
                    letterSpacing: -0.28,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 358,
                  height: 48,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: ShapeDecoration(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      side: BorderSide(
                        width: 0.80,
                        color: const Color(0xFF5D9EFF),
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    holderName,
                    style: TextStyle(
                      color: const Color(0xFF353535),
                      fontSize: 12,
                      fontFamily: 'Pretendard-Light',
                      letterSpacing: -0.28,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '본인 명의의 계좌만 입력해주세요',
                  style: TextStyle(
                    color: const Color(0xFF8490A3),
                    fontSize: 12,
                    fontFamily: 'Pretendard-Light',
                    letterSpacing: -0.24,
                  ),
                ),
              ],
            ),
          ),

          // 버튼 영역
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
            child: Column(
              children: [
                // 인증 완료 박스
                Container(
                  width: 358,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCDCDC),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: const BoxDecoration(
                          color: Color(0xFF5D9EFF),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '인증이 완료되었어요!',
                        style: TextStyle(
                          color: const Color(0xFF8490A3),
                          fontSize: 12,
                          fontFamily: 'Pretendard-Medium',
                          letterSpacing: -0.24,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // 다음 버튼
                Container(
                  width: 358,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder:
                            (context) => PinSetupModal(
                              institution: institution,
                              accountNumber: accountNumber,
                              holderName: holderName,
                              userId: userId,
                              jumin: jumin,
                              password: password,
                              name: name,
                              phone: phone,
                              marketingAgreed: marketingAgreed,
                              agreedTermsOfService: agreedTermsOfService,
                              agreedPrivacyCollection: agreedPrivacyCollection,
                              agreedMinorGuardian: agreedMinorGuardian,
                              agreedElectronicFinance: agreedElectronicFinance,
                              agreedRewardGuardian: agreedRewardGuardian,
                              agreedThirdPartySharing: agreedThirdPartySharing,
                              agreedDataProcessingDelegation: agreedDataProcessingDelegation,
                              isSignup: true,
                            ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF146AFF),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      '다음',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontFamily: 'Pretendard-Medium',
                        letterSpacing: -0.24,
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
