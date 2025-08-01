import 'package:flutter/material.dart';
import '../../../services/auth_service.dart';
import 'account_verified_modal.dart';

class AccountInputModal extends StatefulWidget {
  final Map<String, dynamic> institution;
  final Function(String) getBankCode;
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

  const AccountInputModal({
    super.key,
    required this.institution,
    required this.getBankCode,
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

  @override
  State<AccountInputModal> createState() => _AccountInputModalState();
}

class _AccountInputModalState extends State<AccountInputModal> {
  final accountController = TextEditingController();
  final holderController = TextEditingController();
  bool isVerifying = false;
  bool isVerified = false; // 인증 완료 상태

  @override
  void dispose() {
    accountController.dispose();
    holderController.dispose();
    super.dispose();
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
                  '선택하신 은행의 정보를 둘 다 입력해 주세요',
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
                // 계좌번호 입력
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
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: ShapeDecoration(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      side: BorderSide(
                        width: 0.80,
                        color: const Color(0xFFDADADA),
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: TextField(
                    controller: accountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: '숫자만 입력해 주세요',
                      hintStyle: TextStyle(
                        color: const Color(0xFF999999),
                        fontSize: 12,
                        fontFamily: 'Pretendard-Light',
                        letterSpacing: -0.28,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      focusedErrorBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 예금주명 입력
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
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: ShapeDecoration(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      side: BorderSide(
                        width: 0.80,
                        color: const Color(0xFFDADADA),
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: TextField(
                    controller: holderController,
                    decoration: InputDecoration(
                      hintText: '이름을 입력해 주세요',
                      hintStyle: TextStyle(
                        color: const Color(0xFF999999),
                        fontSize: 12,
                        fontFamily: 'Pretendard-Light',
                        letterSpacing: -0.28,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      focusedErrorBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
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
                // 계좌 인증하기 버튼
                Container(
                  width: 358,
                  height: 50,
                  child: ElevatedButton(
                    onPressed:
                        isVerifying
                            ? null
                            : () async {
                              if (accountController.text.isEmpty ||
                                  holderController.text.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('계좌번호와 예금주명을 모두 입력해주세요'),
                                  ),
                                );
                                return;
                              }

                              setState(() {
                                isVerifying = true;
                              });

                              try {
                                // 계좌 검증 API 호출
                                final result =
                                    await AuthService.verifyAccountHolder(
                                      bankCode: widget.getBankCode(
                                        widget.institution['name'],
                                      ),
                                      bankNumber: accountController.text
                                          .replaceAll('-', ''),
                                      holderName: holderController.text,
                                    );

                                setState(() {
                                  isVerifying = false;
                                });

                                if (result['success'] == true) {
                                  // 검증 성공 - 다음 버튼 활성화
                                  setState(() {
                                    isVerified = true;
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('계좌 인증이 완료되었습니다!'),
                                    ),
                                  );
                                } else {
                                  // 검증 실패
                                  setState(() {
                                    isVerified = false;
                                  });
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: Text(
                                          '계좌 인증 실패',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontFamily: 'Pretendard-Bold',
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        content: Text(
                                          result['message'] ?? '인증에 실패했습니다',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontFamily: 'Pretendard-Light',
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        actions: [
                                          Container(
                                            width: double.infinity,
                                            margin: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                            ),
                                            child: ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(
                                                  0xFF146AFF,
                                                ),
                                                foregroundColor: Colors.white,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 12,
                                                    ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                              ),
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                              },
                                              child: Text(
                                                '확인',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontFamily:
                                                      'Pretendard-Medium',
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        contentPadding:
                                            const EdgeInsets.fromLTRB(
                                              24,
                                              20,
                                              24,
                                              0,
                                            ),
                                        actionsPadding:
                                            const EdgeInsets.symmetric(
                                              vertical: 16,
                                              horizontal: 8,
                                            ),
                                      );
                                    },
                                  );
                                }
                              } catch (e) {
                                setState(() {
                                  isVerifying = false;
                                  isVerified = false;
                                });
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: Text(
                                        '오류 발생',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontFamily: 'Pretendard-Bold',
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      content: Text(
                                        '계좌 인증 중 오류가 발생했습니다',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontFamily: 'Pretendard-Light',
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      actions: [
                                        Container(
                                          width: double.infinity,
                                          margin: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                          ),
                                          child: ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(
                                                0xFF146AFF,
                                              ),
                                              foregroundColor: Colors.white,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 12,
                                                  ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                            ),
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                            },
                                            child: Text(
                                              '확인',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontFamily: 'Pretendard-Medium',
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      contentPadding: const EdgeInsets.fromLTRB(
                                        24,
                                        20,
                                        24,
                                        0,
                                      ),
                                      actionsPadding:
                                          const EdgeInsets.symmetric(
                                            vertical: 16,
                                            horizontal: 8,
                                          ),
                                    );
                                  },
                                );
                              }
                            },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE4ECF8),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child:
                        isVerifying
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFF001F55),
                                ),
                              ),
                            )
                            : Text(
                              '계좌 인증하기',
                              style: TextStyle(
                                color: const Color(0xFF001F55),
                                fontSize: 12,
                                fontFamily: 'Pretendard-Medium',
                                letterSpacing: -0.24,
                              ),
                            ),
                  ),
                ),
                const SizedBox(height: 12),

                // 다음 버튼
                Container(
                  width: 358,
                  height: 52,
                  child: ElevatedButton(
                    onPressed:
                        isVerified
                            ? () {
                              Navigator.pop(context);
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder:
                                    (context) => AccountVerifiedModal(
                                      institution: widget.institution,
                                      accountNumber: accountController.text,
                                      holderName: holderController.text,
                                      userId: widget.userId,
                                      jumin: widget.jumin,
                                      password: widget.password,
                                      name: widget.name,
                                      phone: widget.phone,
                                      marketingAgreed: widget.marketingAgreed,
                                      agreedTermsOfService: widget.agreedTermsOfService,
                                      agreedPrivacyCollection: widget.agreedPrivacyCollection,
                                      agreedMinorGuardian: widget.agreedMinorGuardian,
                                      agreedElectronicFinance: widget.agreedElectronicFinance,
                                      agreedRewardGuardian: widget.agreedRewardGuardian,
                                      agreedThirdPartySharing: widget.agreedThirdPartySharing,
                                      agreedDataProcessingDelegation: widget.agreedDataProcessingDelegation,
                                    ),
                              );
                            }
                            : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isVerified
                              ? const Color(0xFF146AFF)
                              : const Color(0xFFDCDCDC),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      '다음',
                      style: TextStyle(
                        color:
                            isVerified ? Colors.white : const Color(0xFFB6B6B6),
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
