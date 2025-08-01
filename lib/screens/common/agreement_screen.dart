import 'package:flutter/material.dart';
import '../../models/agreement/terms_data.dart';
import '../../theme/agreement/agreement_styles.dart';
import '../../widgets/agreement/components/agreement_alert.dart';
import '../../widgets/agreement/components/terms_content.dart';
import '../../widgets/agreement/components/terms_item_card.dart';
import 'final_screen.dart';
import 'agreement_law/terms_detail_modal.dart';

class AgreementScreen extends StatefulWidget {
  final String userId; // 이메일
  final String jumin; // 생년월일 6자리
  // 필요한 추가 정보
  final String password;
  final String name;
  final String phone;

  const AgreementScreen({
    super.key,
    required this.userId,
    required this.jumin,
    required this.password,
    required this.name,
    required this.phone,
  });

  @override
  _AgreementScreenState createState() => _AgreementScreenState();
}

class _AgreementScreenState extends State<AgreementScreen> {
  late TermsData _termsData;
  bool _isAllAgreed = false;
  bool _isServiceTermsAgreed = false;
  bool _isPrivacyPolicyAgreed = false;
  bool _isMarketingAgreed = false;
  bool _isLoading = false; // 로딩 상태 추가

  @override
  void initState() {
    super.initState();
    _termsData = TermsData(userId: widget.userId, jumin: widget.jumin);
  }

  void _checkAllAgreed() {
    setState(() {
      // 모든 필수 항목이 체크되었는지 확인
      bool allRequired = true;
      for (int i = 0; i < _termsData.termsList.length; i++) {
        if (_termsData.termsList[i].isRequired &&
            !(_termsData.agreements[i] ?? false)) {
          allRequired = false;
          break;
        }
      }

      // 모든 항목이 체크되었는지 확인 (필수 + 선택)
      bool allItems = true;
      for (int i = 0; i < _termsData.termsList.length; i++) {
        if (!(_termsData.agreements[i] ?? false)) {
          allItems = false;
          break;
        }
      }

      _isAllAgreed = allItems;
      _isServiceTermsAgreed = _termsData.agreements[0] ?? false;
      _isPrivacyPolicyAgreed = _termsData.agreements[1] ?? false;
      _isMarketingAgreed = _termsData.agreements[2] ?? false;
    });
  }

  void _toggleAllAgreements(bool? value) {
    if (value == null) return;
    setState(() {
      _isAllAgreed = value;
      _isServiceTermsAgreed = value;
      _isPrivacyPolicyAgreed = value;
      _isMarketingAgreed = value;

      // 전체 동의/해제 시 모든 약관에 적용
      for (int i = 0; i < _termsData.termsList.length; i++) {
        _termsData.updateAgreement(i, value);
      }
    });
  }

  void _completeSignup() async {
    try {
      setState(() {
        _isLoading = true; // 로딩 시작
      });

      // 동의체크 모달 바로 표시
      _showAgreementModal();
    } catch (error) {
      print('모달 표시 오류: $error');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('처리 중 오류가 발생했습니다: $error')));
    } finally {
      setState(() {
        _isLoading = false; // 로딩 종료
      });
    }
  }

  void _showAgreementModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder:
          (context) => AgreementModal(
            userId: widget.userId,
            jumin: widget.jumin,
            password: widget.password,
            name: widget.name,
            phone: widget.phone,
          ),
    );
  }

  void _showTermsDetail(String title) {
    final content = _termsData.getTermsContent(title);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      elevation: 4.0,
      builder:
          (context) => TermsBottomSheet(
            title: title,
            content: content,
            onAgreed: (agreed) {
              // 해당 약관에 동의 처리
              int index = _termsData.termsList.indexWhere(
                (item) => item.title == title,
              );
              if (index != -1) {
                setState(() {
                  _termsData.updateAgreement(index, agreed);
                  _checkAllAgreed(); // 전체 동의 상태 체크
                });
              }
            },
          ),
    );
  }

  void _showAgreementBottomSheet() {
    showDialog(
      context: context,
      builder:
          (context) => AgreementAlert(
            onConfirm: () {
              // 동의 안된 필수 약관 중 첫 번째 약관을 표시
              for (int i = 0; i < _termsData.termsList.length; i++) {
                if (_termsData.termsList[i].isRequired &&
                    !(_termsData.agreements[i] ?? false)) {
                  _showTermsDetail(_termsData.termsList[i].title);
                  break;
                }
              }
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: SafeArea(
        child: Column(
          children: [
            // 상단 앱바
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                width: double.infinity,
                height: 56,
                child: Stack(
                  children: [
                    Positioned(
                      left: 0,
                      top: 16,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 24,
                          height: 24,
                          child: Image.asset(
                            'assets/icons/my/뒤로가기.png',
                            width: 24,
                            height: 24,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 19,
                      child: Center(
                        child: Text(
                          '이용약관동의',
                          style: TextStyle(
                            color: const Color(0xFF202020),
                            fontSize: 16,
                            fontFamily: 'Pretendard-Bold',
                            letterSpacing: -0.32,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 스크롤 가능한 콘텐츠
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // 스텝 인디케이터
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: ShapeDecoration(
                              color: const Color(0xFF3A88F4),
                              shape: OvalBorder(),
                            ),
                            child: Center(
                              child: Text(
                                '1',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontFamily: 'Pretendard-Bold',
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            width: 12,
                            height: 2,
                            color: const Color(0xFFE4ECF8),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            width: 28,
                            height: 28,
                            decoration: ShapeDecoration(
                              color: const Color(0xFF3A88F4),
                              shape: OvalBorder(),
                            ),
                            child: Center(
                              child: Text(
                                '2',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontFamily: 'Pretendard-Bold',
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            width: 12,
                            height: 2,
                            color: const Color(0xFFE4ECF8),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            width: 28,
                            height: 28,
                            decoration: ShapeDecoration(
                              color: const Color(0xFF3A88F4),
                              shape: OvalBorder(),
                            ),
                            child: Center(
                              child: Text(
                                '3',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontFamily: 'Pretendard-Bold',
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            width: 12,
                            height: 2,
                            color: const Color(0xFFE4ECF8),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            width: 28,
                            height: 28,
                            decoration: ShapeDecoration(
                              color: const Color(0xFFE4ECF8),
                              shape: OvalBorder(),
                            ),
                            child: Center(
                              child: Text(
                                '4',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontFamily: 'Pretendard-Bold',
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            width: 12,
                            height: 2,
                            color: const Color(0xFFE4ECF8),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            width: 28,
                            height: 28,
                            decoration: ShapeDecoration(
                              color: const Color(0xFFE4ECF8),
                              shape: OvalBorder(),
                            ),
                            child: Center(
                              child: Text(
                                '5',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontFamily: 'Pretendard-Bold',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // 제목과 설명
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: Text(
                              '이용약관동의',
                              style: TextStyle(
                                color: const Color(0xFF202020),
                                fontSize: 20,
                                fontFamily: 'Pretendard-Bold',
                                letterSpacing: -0.88,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '리틀뱅크는 부모와 자녀가 함께 이용하는 앱이예요.\n서비스의 더 나은 이용을 위해 이용동의를 해주세요',
                            style: TextStyle(
                              color: const Color(0xFF8490A3),
                              fontSize: 12,
                              fontFamily: 'Pretendard-Light',
                              height: 1.50,
                              letterSpacing: -0.28,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 48),

                      // 약관 항목들
                      Column(
                        children: [
                          _buildTermsItem(
                            icon: Container(
                              width: 56,
                              height: 56,
                              child: Image.asset(
                                'assets/icons/AGREEMENT1.png',
                                width: 56,
                                height: 56,
                                fit: BoxFit.contain,
                              ),
                            ),
                            title: '만 14세 미만의 자녀는 부모님과 함께\n가입해주세요.',
                            description:
                                '다양한 활동 참여와 학습 기록 분석을 위해서\n 보호자 (법정 대리인)의 동의는 필수로 받고있어요.',
                          ),
                          const SizedBox(height: 28),
                          _buildTermsItem(
                            icon: Container(
                              width: 56,
                              height: 56,
                              child: Image.asset(
                                'assets/icons/AGREENMENT3.png',
                                width: 56,
                                height: 56,
                                fit: BoxFit.contain,
                              ),
                            ),
                            title: '자녀가 참여하는 모든 활동은 부모님의 \n사전확인이 동반돼요',
                            description:
                                '자녀에게 제시되거나, 자녀가 제시한 모든 활동은\n보호자의 사전 확인과 승인을 필요로 해요.',
                          ),
                          const SizedBox(height: 28),
                          _buildTermsItem(
                            icon: Container(
                              width: 56,
                              height: 56,
                              child: Image.asset(
                                'assets/icons/AGREENMENT2.png',
                                width: 56,
                                height: 56,
                                fit: BoxFit.contain,
                              ),
                            ),
                            title: '보상금은 활동 내역 및 결과에 따라\n부모님이 직접 승인할 수 있어요',
                            description:
                                '자녀에게 제시되거나, 자녀가 제시한 모든 활동의 보상금은 부모님이 확인 후 승인 및 조절 가능합니다.',
                          ),
                          const SizedBox(height: 28),
                          _buildTermsItem(
                            icon: Container(
                              width: 56,
                              height: 56,
                              child: Image.asset(
                                'assets/icons/agree.png',
                                width: 56,
                                height: 56,
                                fit: BoxFit.contain,
                              ),
                            ),
                            title: '안전한 보상 지급과 신속한 처리에 대해\n확실하게 약속 드릴게요',
                            description:
                                '보상 지급은 보호자의 동의 및 승인을 거쳐 진행되며, 지급되는 포인트 또는 현금은 회사가 지정한 수단을 통해 처리돼요.\n\n전자금융거래와 관련하여 오류가 발생한 경우, 이용자는 회사에 정정 요구를 할 수 있으며, 회사는 법령에 따라 신속히 처리할 거예요.\n\n회사는 전자금융거래의 안정성과 신뢰성을 확보하기 위하여 필요한 보안 조치를 이행하며, 이용자의 개인정보와 거래 내역 보호에 최선을 다하고 있어요.',
                          ),
                        ],
                      ),

                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ),

            // 하단 버튼 영역
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 16,
                ),
                decoration: ShapeDecoration(
                  color: const Color(0xFF146AFF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: GestureDetector(
                  onTap: _completeSignup,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _isLoading
                          ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.0,
                            ),
                          )
                          : Text(
                            '다음',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontFamily: 'Pretendard-Medium',
                              letterSpacing: -0.28,
                            ),
                          ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTermsItem({
    required Widget icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        icon,
        const SizedBox(width: 24),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: const Color(0xFF202020),
                  fontSize: 14,
                  fontFamily: 'Pretendard-Bold',
                  height: 1.50,
                  letterSpacing: -0.32,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: TextStyle(
                  color: const Color(0xFF8490A3),
                  fontSize: 12,
                  fontFamily: 'Pretendard-Light',
                  height: 1.50,
                  letterSpacing: -0.28,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class AgreementModal extends StatefulWidget {
  final String userId;
  final String jumin;
  final String password;
  final String name;
  final String phone;

  const AgreementModal({
    super.key,
    required this.userId,
    required this.jumin,
    required this.password,
    required this.name,
    required this.phone,
  });

  @override
  State<AgreementModal> createState() => _AgreementModalState();
}

class _AgreementModalState extends State<AgreementModal> {
  bool _allAgreed = false;
  bool _termsOfService = false;
  bool _privacyPolicy = false;
  bool _parentalConsent = false;
  bool _electronicFinance = false;
  bool _rewardApproval = false;
  bool _thirdPartyInfo = false;
  bool _dataProcessing = false;
  bool _marketing = false;

  // 19세 이상인지 체크하는 함수 추가
  bool get _isAdult {
    if (widget.jumin.isNotEmpty && widget.jumin.length >= 6) {
      int birthYear = int.tryParse(widget.jumin.substring(0, 2)) ?? 0;
      int currentYear = DateTime.now().year % 100;

      // 00~23년생은 2000년대, 24~99년생은 1900년대로 판단
      if (birthYear > currentYear) {
        birthYear += 1900;
      } else {
        birthYear += 2000;
      }

      int age = DateTime.now().year - birthYear;
      return age >= 19; // 19세 이상이면 성인
    }
    return false;
  }

  void _toggleAllAgreements(bool? value) {
    setState(() {
      _allAgreed = value ?? false;
      _termsOfService = _allAgreed;
      _privacyPolicy = _allAgreed;
      _electronicFinance = _allAgreed;
      
      // 19세 미만인 경우에만 부모님 관련 약관 체크
      if (!_isAdult) {
        _parentalConsent = _allAgreed;
        _rewardApproval = _allAgreed;
      }
      
      _thirdPartyInfo = _allAgreed;
      _dataProcessing = _allAgreed;
      _marketing = _allAgreed;
    });
  }

  void _updateAllAgreedStatus() {
    setState(() {
      if (_isAdult) {
        // 19세 이상: 필수 3개만 체크하면 전체 동의
        _allAgreed =
            _termsOfService &&
            _privacyPolicy &&
            _electronicFinance &&
            _thirdPartyInfo &&
            _dataProcessing &&
            _marketing;
      } else {
        // 19세 미만: 필수 5개 모두 체크해야 전체 동의
        _allAgreed =
            _termsOfService &&
            _privacyPolicy &&
            _parentalConsent &&
            _electronicFinance &&
            _rewardApproval &&
            _thirdPartyInfo &&
            _dataProcessing &&
            _marketing;
      }
    });
  }

  bool get _isRequiredAgreed {
    if (_isAdult) {
      // 19세 이상: 필수 3개만 체크하면 됨
      return _termsOfService &&
          _privacyPolicy &&
          _electronicFinance;
    } else {
      // 19세 미만: 필수 5개 모두 체크해야 함
      return _termsOfService &&
          _privacyPolicy &&
          _parentalConsent &&
          _electronicFinance &&
          _rewardApproval;
    }
  }

  void _completeAgreement() {
    if (!_isRequiredAgreed) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('필수 약관에 모두 동의해 주세요.')));
      return;
    }

    Navigator.of(context).pop(); // 모달 닫기
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder:
            (context) => FinalScreen(
              userId: widget.userId,
              jumin: widget.jumin,
              marketingAgreed: _marketing,
              password: widget.password,
              name: widget.name,
              phone: widget.phone,
              agreedTermsOfService: _termsOfService,
              agreedPrivacyCollection: _privacyPolicy,
              agreedMinorGuardian: _parentalConsent,
              agreedElectronicFinance: _electronicFinance,
              agreedRewardGuardian: _rewardApproval,
              agreedThirdPartySharing: _thirdPartyInfo,
              agreedDataProcessingDelegation: _dataProcessing,
            ),
      ),
    );
  }

  // 약관 상세내용 모달 표시 함수
  void _showTermsDetail(String termsType, String title) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TermsDetailModal(
        termsType: termsType,
        title: title,
        onAgreed: () {
          // 약관 타입에 따라 해당 체크박스 체크
          setState(() {
            switch (termsType) {
              case 'termsOfService':
                _termsOfService = true;
                break;
              case 'privacyCollection':
                _privacyPolicy = true;
                break;
              case 'minorGuardian':
                _parentalConsent = true;
                break;
              case 'electronicFinance':
                _electronicFinance = true;
                break;
              case 'rewardGuardian':
                _rewardApproval = true;
                break;
              case 'thirdPartySharing':
                _thirdPartyInfo = true;
                break;
              case 'dataProcessingDelegation':
                _dataProcessing = true;
                break;
              case 'marketing':
                _marketing = true;
                break;
            }
            _updateAllAgreedStatus(); // 전체 동의 상태 업데이트
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    
    // 약관 수에 따른 동적 높이 계산
    final termsCount = _isAdult ? 6 : 8; // 19세 이상: 6개, 미만: 8개
    final baseHeight = 220; // 헤더 + 버튼 + 여백
    final itemHeight = 60; // 각 약관 항목당 높이
    final dynamicHeight = baseHeight + (termsCount * itemHeight);
    final maxHeight = _isAdult ? screenHeight * 0.65 : screenHeight * 0.75; // 19세 이상인 경우 더 작게
    final minHeight = _isAdult ? screenHeight * 0.45 : screenHeight * 0.5;

    return Container(
      width: screenWidth,
      constraints: BoxConstraints(
        maxHeight: maxHeight.clamp(dynamicHeight.toDouble(), screenHeight * 0.8),
        minHeight: minHeight,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 상단 헤더
          Container(
            width: screenWidth,
            padding: const EdgeInsets.all(16),
            decoration: ShapeDecoration(
              color: const Color(0xFFE7ECF6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '서비스의 이용을 위해서는 반드시 확인해야 해요',
                  style: TextStyle(
                    color: const Color(0xFF353535),
                    fontSize: 16,
                    fontFamily: 'Pretendard-Bold',
                    letterSpacing: -0.72,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '다양한 활동 참여를 위해서는 약관 동의가 필요해요!',
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

          // 스크롤 가능한 약관 리스트
          Expanded(
            child: Container(
              width: screenWidth,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '활동 참여를 위한 약관에 동의해 주세요',
                      style: TextStyle(
                        color: const Color(0xFF353535),
                        fontSize: 16,
                        fontFamily: 'Pretendard-Bold',
                        letterSpacing: -0.72,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // 전체 동의 체크박스
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => _toggleAllAgreements(!_allAgreed),
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color:
                                  _allAgreed
                                      ? const Color(0xFF3A88F4)
                                      : Colors.grey[300],
                              shape: BoxShape.circle,
                            ),
                            child:
                                _allAgreed
                                    ? Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 14,
                                    )
                                    : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '전체 동의하고 빠르게 시작하기',
                          style: TextStyle(
                            color: const Color(0xFF4A4A4A),
                            fontSize: 14,
                            fontFamily: 'Pretendard-Light',
                            letterSpacing: -0.28,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // 구분선
                    Center(
                      child: Container(
                        width: double.infinity,
                        height: 1,
                        color: Colors.grey[300],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // 개별 약관 항목들
                    _buildAgreementItem(
                      isChecked: _termsOfService,
                      onChanged: (value) {
                        setState(() {
                          _termsOfService = value ?? false;
                          _updateAllAgreedStatus();
                        });
                      },
                      title: '[필수] 서비스 이용약관 동의',
                      termsType: 'termsOfService',
                    ),
                    _buildAgreementItem(
                      isChecked: _privacyPolicy,
                      onChanged: (value) {
                        setState(() {
                          _privacyPolicy = value ?? false;
                          _updateAllAgreedStatus();
                        });
                      },
                      title: '[필수] 개인정보 수집 및 이용 동의',
                      termsType: 'privacyCollection',
                    ),
                    // 19세 미만인 경우에만 표시
                    if (!_isAdult) ...[
                      _buildAgreementItem(
                        isChecked: _parentalConsent,
                        onChanged: (value) {
                          setState(() {
                            _parentalConsent = value ?? false;
                            _updateAllAgreedStatus();
                          });
                        },
                        title: '[필수] 만 14세 미만 이용자의 보호자 동의 안내',
                        termsType: 'minorGuardian',
                      ),
                    ],
                    _buildAgreementItem(
                      isChecked: _electronicFinance,
                      onChanged: (value) {
                        setState(() {
                          _electronicFinance = value ?? false;
                          _updateAllAgreedStatus();
                        });
                      },
                      title: '[필수] 전자금융거래에 관한 동의',
                      termsType: 'electronicFinance',
                    ),
                    // 19세 미만인 경우에만 표시
                    if (!_isAdult) ...[
                      _buildAgreementItem(
                        isChecked: _rewardApproval,
                        onChanged: (value) {
                          setState(() {
                            _rewardApproval = value ?? false;
                            _updateAllAgreedStatus();
                          });
                        },
                        title: '[필수] 보상 지급 관련 보호자 승인 및 책임 안내',
                        termsType: 'rewardGuardian',
                      ),
                    ],
                    _buildAgreementItem(
                      isChecked: _thirdPartyInfo,
                      onChanged: (value) {
                        setState(() {
                          _thirdPartyInfo = value ?? false;
                          _updateAllAgreedStatus();
                        });
                      },
                      title: '[선택] 개인정보 제3자 제공 동의',
                      termsType: 'thirdPartySharing',
                    ),
                    _buildAgreementItem(
                      isChecked: _dataProcessing,
                      onChanged: (value) {
                        setState(() {
                          _dataProcessing = value ?? false;
                          _updateAllAgreedStatus();
                        });
                      },
                      title: '[선택] 개인정보 처리 위탁 동의',
                      termsType: 'dataProcessingDelegation',
                    ),
                    _buildAgreementItem(
                      isChecked: _marketing,
                      onChanged: (value) {
                        setState(() {
                          _marketing = value ?? false;
                          _updateAllAgreedStatus();
                        });
                      },
                      title: '[선택] 마케팅 정보 수신 동의',
                      termsType: 'marketing',
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 하단 버튼
          Container(
            width: screenWidth,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            decoration: BoxDecoration(color: Colors.white),
            child: GestureDetector(
              onTap: _completeAgreement,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 16,
                ),
                decoration: ShapeDecoration(
                  color:
                      _isRequiredAgreed
                          ? const Color(0xFF146AFF)
                          : Colors.grey[400],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Center(
                  child: Text(
                    '동의하고 시작하기',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontFamily: 'Pretendard-Light',
                      letterSpacing: -0.28,
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

  Widget _buildAgreementItem({
    required bool isChecked,
    required Function(bool?) onChanged,
    required String title,
    required String termsType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Container(
        width: double.infinity,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () => onChanged(!isChecked),
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isChecked ? const Color(0xFF3A88F4) : Colors.grey[300],
                  shape: BoxShape.circle,
                ),
                child:
                    isChecked
                        ? Icon(Icons.check, color: Colors.white, size: 16)
                        : null,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        color: const Color(0xFF666666),
                        fontSize: 13,
                        fontFamily: 'Pretendard-Light',
                        letterSpacing: -0.32,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _showTermsDetail(termsType, title),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.grey[400],
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
