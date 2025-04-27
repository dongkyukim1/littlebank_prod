import 'package:flutter/material.dart';
import '../../models/agreement/terms_data.dart';
import '../../theme/agreement/agreement_styles.dart';
import '../../widgets/agreement/components/agreement_alert.dart';
import '../../widgets/agreement/components/terms_content.dart';
import '../../widgets/agreement/components/terms_item_card.dart';
import 'final_screen.dart';

class AgreementScreen extends StatefulWidget {
  final String userId; // 이메일
  final String jumin; // 주민번호 앞자리
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
        if (_termsData.termsList[i].isRequired && !(_termsData.agreements[i] ?? false)) {
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
    // 필수 항목이 모두 체크되어 있는지 확인
    if (_termsData.agreements[0] != true || _termsData.agreements[1] != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('필수 약관에 모두 동의해 주세요.')),
      );
      return;
    }
    
    try {
      setState(() {
        _isLoading = true; // 로딩 시작
      });
      
      // 약관 동의 상태 확인
      print('약관 동의 상태:');
      for (int i = 0; i < _termsData.termsList.length; i++) {
        print('${_termsData.termsList[i].title}: ${_termsData.agreements[i] ?? false}');
      }
      
      // 마케팅 수신 동의 여부
      final bool marketingAgree = _termsData.agreements[2] ?? false;
      print('마케팅 수신 동의 여부: $marketingAgree');
      
      // API 호출하지 않고 다음 화면으로 이동
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => FinalScreen(
            userId: widget.userId,
            jumin: widget.jumin,
            marketingAgreed: marketingAgree,
            password: widget.password,
            name: widget.name,
            phone: widget.phone,
          ),
        ),
      );
      
      // 개발자 알림 - 콘솔에만 표시
      print('주의: FinalScreen에서 회원가입 API를 구현해야 합니다.');
      print('전달할 데이터: password=${widget.password}, name=${widget.name}, phone=${widget.phone}');
    } catch (error) {
      print('약관 동의 처리 오류: $error');
      print('오류 상세 정보: ${error.toString()}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('처리 중 오류가 발생했습니다: $error')),
      );
    } finally {
      setState(() {
        _isLoading = false; // 로딩 종료
      });
    }
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('약관 동의', style: AgreementStyles.titleStyle),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 스크롤 가능한 약관 동의 목록
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AgreementStyles.defaultPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '안전한 서비스 이용을 위해\n약관에 동의해 주세요',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 전체 동의 체크박스
                    _buildAllAgreeCheckbox(),

                    const SizedBox(height: 24),

                    // 개별 약관 항목들
                    ...List.generate(
                      _termsData.termsList.length,
                      (index) => TermsItemCard(
                        item: _termsData.termsList[index],
                        isAgreed: _termsData.agreements[index] ?? false,
                        onAgreementChanged: (agreed) {
                          setState(() {
                            _termsData.updateAgreement(index, agreed);
                            _checkAllAgreed(); // 전체 동의 상태 체크
                          });
                        },
                        onViewDetail: () {
                          _showTermsDetail(_termsData.termsList[index].title);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 하단 버튼
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AgreementStyles.defaultPadding),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 6,
                    spreadRadius: 1.5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _isLoading ? null : _completeSignup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isLoading 
                    ? Colors.grey 
                    : (_isAllAgreed ? const Color(0xFF146AFF) : Colors.grey),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey[400],
                  disabledForegroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                child: _isLoading
                  ? SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.0,
                      ),
                    )
                  : const Text(
                      '동의하고 계속',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllAgreeCheckbox() {
    return GestureDetector(
      onTap: () {
        _toggleAllAgreements(!_isAllAgreed);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:
              _isAllAgreed
                  ? AgreementStyles.primaryColor.withOpacity(0.1)
                  : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color:
                _isAllAgreed
                    ? AgreementStyles.primaryColor
                    : Colors.grey[300]!,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: AgreementStyles.checkboxDecoration(
                isChecked: _isAllAgreed,
              ),
              child:
                  _isAllAgreed
                      ? const Icon(Icons.check, color: Colors.white, size: 18)
                      : null,
            ),
            const SizedBox(width: 12),
            Text(
              '전체 동의',
              style: AgreementStyles.checkboxLabelStyle(
                isChecked: _isAllAgreed,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
