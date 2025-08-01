import 'package:flutter/material.dart';
import '../profile_selection_screen.dart';
import '../../../services/auth_service.dart';

class PinSetupModal extends StatefulWidget {
  final Map<String, dynamic> institution;
  final String accountNumber;
  final String holderName;
  final String userId;
  final String jumin;
  final String? password;
  final String? name;
  final String? phone;
  final bool? marketingAgreed;
  final VoidCallback? onComplete;
  final bool isAccountLink;
  final String? userType; // 'parent' or 'child'
  final bool isSignup; // 회원가입 중인지 여부
  final bool? agreedTermsOfService;
  final bool? agreedPrivacyCollection;
  final bool? agreedMinorGuardian;
  final bool? agreedElectronicFinance;
  final bool? agreedRewardGuardian;
  final bool? agreedThirdPartySharing;
  final bool? agreedDataProcessingDelegation;
  const PinSetupModal({
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
    this.onComplete,
    this.isAccountLink = false,
    this.userType,
    this.isSignup = false,
    this.agreedTermsOfService,
    this.agreedPrivacyCollection,
    this.agreedMinorGuardian,
    this.agreedElectronicFinance,
    this.agreedRewardGuardian,
    this.agreedThirdPartySharing,
    this.agreedDataProcessingDelegation,
  });

  @override
  State<PinSetupModal> createState() => _PinSetupModalState();
}

class _PinSetupModalState extends State<PinSetupModal> {
  String enteredPin = '';
  final List<String> numbers = [
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    '0',
  ];

  String _getBankCode(String bankName) {
    final Map<String, String> bankCodes = {
      'KB국민': '004',
      '신한': '088',
      '농협': '011',
      '하나': '081',
      '우리': '020',
      '카카오뱅크': '090',
      '부산': '032',
      '토스뱅크': '092',
      'IBK기업': '003',
      '경남': '039',
      '전북': '037',
      '수협': '007',
      '제주': '035',
      '대구': '031',
      '광주': '034',
      'SC제일': '023',
      '씨티은행': '027',
      '케이뱅크': '089',
      '신협': '048',
      '우체국': '071',
      '축협': '012',
    };
    return bankCodes[bankName] ?? '004';
  }

  void _goToProfileSelection(String pin) async {
    Navigator.pop(context);

    if (widget.isAccountLink) {
      // 계좌 연동인 경우 PIN 설정과 계좌 정보를 함께 저장
      try {
        // 기존 사용자 정보 먼저 가져오기
        final userInfo = await AuthService.getUserInfo();
        
        // PIN과 계좌 정보를 함께 업데이트
        await AuthService.updateUserInfo(
          name: userInfo['name'], // 기존 이름
          email: userInfo['email'], // 기존 이메일
          bankName: widget.institution['name'],
          bankCode: widget.institution['code'] ?? _getBankCode(widget.institution['name']),
          bankAccount: widget.accountNumber.replaceAll('-', ''),
          accountPin: pin,
        );
        
        print('계좌 정보 및 PIN 설정 완료');
        
        if (widget.onComplete != null) {
          widget.onComplete!();
        }
      } catch (e) {
        print('계좌 정보 및 PIN 설정 실패: $e');
        // 실패 시에도 완료 처리 (사용자 경험을 위해)
        if (widget.onComplete != null) {
          widget.onComplete!();
        }
      }
    } else if (widget.isSignup) {
      // 회원가입 중인 경우 - 프로필 선택 화면으로 이동
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => ProfileSelectionScreen(
                userId: widget.userId,
                jumin: widget.jumin,
                password: widget.password,
                name: widget.name,
                phone: widget.phone,
                marketingAgreed: widget.marketingAgreed,
                bankName: widget.institution['name'],
                bankCode: _getBankCode(widget.institution['name']),
                bankAccount: widget.accountNumber.replaceAll('-', ''),
                accountPin: pin.isNotEmpty ? pin : null,
                agreedTermsOfService: widget.agreedTermsOfService,
                agreedPrivacyCollection: widget.agreedPrivacyCollection,
                agreedMinorGuardian: widget.agreedMinorGuardian,
                agreedElectronicFinance: widget.agreedElectronicFinance,
                agreedRewardGuardian: widget.agreedRewardGuardian,
                agreedThirdPartySharing: widget.agreedThirdPartySharing,
                agreedDataProcessingDelegation: widget.agreedDataProcessingDelegation,
              ),
        ),
      );
    } else {
      // 기존 로직 (회원가입이 아닌 일반적인 경우)
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => ProfileSelectionScreen(
                userId: widget.userId,
                jumin: widget.jumin,
                password: widget.password,
                name: widget.name,
                phone: widget.phone,
                marketingAgreed: widget.marketingAgreed,
                bankName: widget.institution['name'],
                bankCode: _getBankCode(widget.institution['name']),
                bankAccount: widget.accountNumber.replaceAll('-', ''),
                accountPin: pin.isNotEmpty ? pin : null,
                agreedTermsOfService: widget.agreedTermsOfService,
                agreedPrivacyCollection: widget.agreedPrivacyCollection,
                agreedMinorGuardian: widget.agreedMinorGuardian,
                agreedElectronicFinance: widget.agreedElectronicFinance,
                agreedRewardGuardian: widget.agreedRewardGuardian,
                agreedThirdPartySharing: widget.agreedThirdPartySharing,
                agreedDataProcessingDelegation: widget.agreedDataProcessingDelegation,
              ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 390,
                padding: const EdgeInsets.all(16),
                decoration: ShapeDecoration(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: double.infinity,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 358,
                                  child: Text(
                                    '결제 비밀번호를 설정해 주세요',
                                    style: TextStyle(
                                      color: const Color(0xFF353535),
                                      fontSize: 16,
                                      fontFamily: 'Pretendard-Bold',
                                      letterSpacing: -0.72,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: 358,
                                  child: Text(
                                    '잊지말고 꼭 기억해주세요!',
                                    style: TextStyle(
                                      color: const Color(0xFF999999),
                                      fontSize: 12,
                                      fontFamily: 'Pretendard-Light',
                                      letterSpacing: -0.28,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 390,
              padding: const EdgeInsets.symmetric(vertical: 36),
              decoration: BoxDecoration(color: Colors.white),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      for (int i = 0; i < 6; i++) ...[
                        Container(
                          width: 24,
                          height: 24,
                          decoration: ShapeDecoration(
                            color:
                                i < enteredPin.length
                                    ? const Color(0xFF146AFF)
                                    : const Color(0xFFDCDCDC),
                            shape: OvalBorder(),
                          ),
                        ),
                        if (i < 5) const SizedBox(width: 24),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Container(
              width: 390,
              decoration: BoxDecoration(color: Colors.white),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 첫 번째 줄: 1, 3, 7, 6
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: const Color(0xFF5D6A7F)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(child: Center(child: _buildNumberButton('1'))),
                        Expanded(child: Center(child: _buildNumberButton('3'))),
                        Expanded(child: Center(child: _buildNumberButton('7'))),
                        Expanded(child: Center(child: _buildNumberButton('6'))),
                      ],
                    ),
                  ),
                  // 두 번째 줄: 0, 2, 4, 9
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: const Color(0xFF5D6A7F)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(child: Center(child: _buildNumberButton('0'))),
                        Expanded(child: Center(child: _buildNumberButton('2'))),
                        Expanded(child: Center(child: _buildNumberButton('4'))),
                        Expanded(child: Center(child: _buildNumberButton('9'))),
                      ],
                    ),
                  ),
                  // 세 번째 줄: 5, 8, 백스페이스
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(color: const Color(0xFF5D6A7F)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(child: Center(child: _buildNumberButton('5'))),
                        Expanded(child: Center(child: _buildNumberButton('8'))),
                        Expanded(
                          child: Center(
                            child: GestureDetector(
                              onTap: () {
                                if (enteredPin.isNotEmpty) {
                                  setState(() {
                                    enteredPin = enteredPin.substring(
                                      0,
                                      enteredPin.length - 1,
                                    );
                                  });
                                }
                              },
                              child: Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: Colors.transparent,
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.arrow_back,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(child: Container()), // 빈 공간
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 390,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              decoration: BoxDecoration(color: const Color(0xFF5D6A7F)),
              child: Container(
                width: double.infinity,
                height: 49,
                child: ElevatedButton(
                  onPressed:
                      enteredPin.length == 6
                          ? () {
                            _goToProfileSelection(enteredPin);
                          }
                          : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF146AFF),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    '선택 완료',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontFamily: 'Pretendard-Medium',
                      letterSpacing: -0.24,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNumberButton(String number) {
    return GestureDetector(
      onTap: () {
        if (enteredPin.length < 6) {
          setState(() {
            enteredPin += number;
          });
        }
      },
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Center(
          child: Text(
            number,
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontFamily: 'Pretendard-Light',
              letterSpacing: -0.96,
            ),
          ),
        ),
      ),
    );
  }
}
