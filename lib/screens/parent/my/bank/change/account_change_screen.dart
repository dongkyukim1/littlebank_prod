import 'package:flutter/material.dart';
import '../../../../../services/auth_service.dart';
import 'bank_selection_bottom_sheet.dart';
import 'account_input_bottom_sheet.dart';
import 'pin_setup_bottom_sheet.dart';

class AccountChangeScreen extends StatefulWidget {
  const AccountChangeScreen({super.key});

  @override
  State<AccountChangeScreen> createState() => _AccountChangeScreenState();
}

class _AccountChangeScreenState extends State<AccountChangeScreen> {
  // 사용자 정보 관련 변수
  Map<String, dynamic>? _userInfo;
  bool _isLoading = true;
  String? _errorMessage;

  // 계좌 정보 변수
  String _bankName = '';
  String _bankAccount = '';
  String _accountHolder = '';
  String _linkedDate = '';

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  // 사용자 정보 로드
  Future<void> _loadUserInfo() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final userInfo = await AuthService.getUserInfo();
      
      setState(() {
        _userInfo = userInfo;
        _bankName = userInfo['bankName'] ?? '';
        _bankAccount = userInfo['bankAccount'] ?? '';
        _accountHolder = userInfo['name'] ?? '';
        
        // 연동 날짜 설정 (현재 날짜로 임시 설정 - 실제로는 서버에서 제공하는 날짜 사용)
        final now = DateTime.now();
        _linkedDate = '${now.year}. ${now.month.toString().padLeft(2, '0')}. ${now.day.toString().padLeft(2, '0')}';
        
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  // 계좌 변경 버튼 클릭 핸들러
  void _onAccountChangePressed() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: true,
      builder: (context) {
        return BankSelectionBottomSheet(
          onBankSelected: (bankName, bankCode) {
            Navigator.pop(context); // 은행 선택 바텀시트 닫기
            _showAccountInputBottomSheet(bankName, bankCode);
          },
        );
      },
    );
  }

  // 계좌 입력 바텀시트 표시
  void _showAccountInputBottomSheet(String bankName, String bankCode) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: false,
      builder: (context) {
        return AccountInputBottomSheet(
          selectedBank: bankName,
          selectedBankCode: bankCode,
          onPrevious: () {
            Navigator.pop(context); // 계좌 입력 바텀시트 닫기
            _onAccountChangePressed(); // 은행 선택 바텀시트 다시 열기
          },
          onNext: (accountNumber, accountHolder) {
            Navigator.pop(context); // 계좌 입력 바텀시트 닫기
            _showPinSetupBottomSheet(bankName, bankCode, accountNumber, accountHolder);
          },
        );
      },
    );
  }

  // 핀 설정 바텀시트 표시
  void _showPinSetupBottomSheet(String bankName, String bankCode, String accountNumber, String accountHolder) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: false,
      builder: (context) {
        return PinSetupBottomSheet(
          selectedBank: bankName,
          selectedBankCode: bankCode,
          accountNumber: accountNumber,
          accountHolder: accountHolder,
          onPrevious: () {
            Navigator.pop(context); // 핀 설정 바텀시트 닫기
            _showAccountInputBottomSheet(bankName, bankCode); // 계좌 입력 바텀시트 다시 열기
          },
          onComplete: () {
            Navigator.pop(context); // 핀 설정 바텀시트 닫기
            _handleAccountChangeComplete();
          },
        );
      },
    );
  }

  // 계좌 변경 완료 처리
  void _handleAccountChangeComplete() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('계좌 변경이 완료되었습니다.'),
        backgroundColor: Color(0xFF5D9EFF),
        duration: Duration(seconds: 2),
      ),
    );

    // 사용자 정보 다시 로드하여 UI 업데이트
    _loadUserInfo();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '계좌 변경',
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontFamily: 'Pretendard-Bold',
            letterSpacing: -0.32,
          ),
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5D9EFF)),
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        '계좌 정보를 불러올 수 없습니다',
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: 'Pretendard-Medium',
                          color: Colors.grey[700],
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        _errorMessage!,
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'Pretendard-Light',
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _loadUserInfo,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF5D9EFF),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          '다시 시도',
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'Pretendard-Medium',
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      // 현재 연동된 계좌 정보 섹션
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment(-0.01, 0.02),
                            end: Alignment(1.00, 1.03),
                            colors: [Color(0xFF3A88F4), Color(0xFF10CB86)],
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '현재 연동된 내 계좌',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontFamily: 'Pretendard-Bold',
                                height: 1.50,
                                letterSpacing: -0.72,
                              ),
                            ),
                            SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              decoration: ShapeDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment(0.03, 0.00),
                                  end: Alignment(1.00, 1.00),
                                  colors: [
                                    Colors.white.withOpacity(0.60),
                                    Colors.white.withOpacity(0.30)
                                  ],
                                ),
                                shape: RoundedRectangleBorder(
                                  side: BorderSide(width: 0.40, color: Colors.white),
                                  borderRadius: BorderRadius.circular(24),
                                ),
                              ),
                              child: Column(
                                children: [
                                  // 계좌 정보 상단
                                  Row(
                                    children: [
                                      // 은행 로고
                                      Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.white,
                                        ),
                                        child: ClipOval(
                                          child: _getBankLogo(_bankName),
                                        ),
                                      ),
                                      SizedBox(width: 16),
                                      // 은행명과 계좌번호
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _bankName.isNotEmpty ? _bankName : '연동된 계좌 없음',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontFamily: 'Pretendard-Medium',
                                                letterSpacing: -0.32,
                                              ),
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              _bankAccount.isNotEmpty 
                                                  ? _formatAccountNumber(_bankAccount)
                                                  : '계좌 정보 없음',
                                              style: TextStyle(
                                                color: Color(0xFF8490A3),
                                                fontSize: 12,
                                                fontFamily: 'Pretendard-Light',
                                                letterSpacing: -0.24,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // 연동 완료 태그
                                      if (_bankName.isNotEmpty)
                                        Container(
                                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                          decoration: ShapeDecoration(
                                            color: Color(0xFF353535),
                                            shape: RoundedRectangleBorder(
                                              side: BorderSide(
                                                width: 1,
                                                color: Color(0xFF89DA8D),
                                              ),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Image.asset(
                                                'assets/icons/parent/bank/check.png',
                                                width: 12,
                                                height: 12,
                                                color: Color(0xFF89DA8D),
                                              ),
                                              SizedBox(width: 4),
                                              Text(
                                                '연동 완료',
                                                style: TextStyle(
                                                  color: Color(0xFF89DA8D),
                                                  fontSize: 11,
                                                  fontFamily: 'Pretendard-Light',
                                                  letterSpacing: -0.22,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                  
                                  if (_bankName.isNotEmpty) ...[
                                    SizedBox(height: 12),
                                    // 예금주 및 연동 날짜 정보
                                    Column(
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              '예금주',
                                              style: TextStyle(
                                                color: Color(0xFF666666),
                                                fontSize: 14,
                                                fontFamily: 'Pretendard-Light',
                                                letterSpacing: -0.28,
                                              ),
                                            ),
                                            Text(
                                              _accountHolder,
                                              style: TextStyle(
                                                color: Color(0xFF4A4A4A),
                                                fontSize: 14,
                                                fontFamily: 'Pretendard-Medium',
                                                letterSpacing: -0.28,
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              '연동한 날짜',
                                              style: TextStyle(
                                                color: Color(0xFF666666),
                                                fontSize: 14,
                                                fontFamily: 'Pretendard-Light',
                                                letterSpacing: -0.28,
                                              ),
                                            ),
                                            Text(
                                              _linkedDate,
                                              style: TextStyle(
                                                color: Color(0xFF4A4A4A),
                                                fontSize: 14,
                                                fontFamily: 'Pretendard-Medium',
                                                letterSpacing: -0.28,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 20),

                      // 계좌 변경하기 버튼
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _onAccountChangePressed,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF3A88F4),
                              padding: EdgeInsets.all(16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(
                                  'assets/icons/parent/bank/change.png',
                                  width: 16,
                                  height: 16,
                                  color: Colors.white,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  '계좌 변경하기',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontFamily: 'Pretendard-Light',
                                    letterSpacing: -0.28,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 40),

                      // 계좌 변경 시 유의사항
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '계좌 변경 시 유의사항',
                              style: TextStyle(
                                color: Color(0xFF202020),
                                fontSize: 16,
                                fontFamily: 'Pretendard-Bold',
                                letterSpacing: -0.32,
                              ),
                            ),
                            SizedBox(height: 20),
                            
                            // 유의사항 항목들
                            _buildNoticeItem(
                              '계좌 연결 안내',
                              '한 번에 하나의 계좌만 연결 가능해요. 현재 연동된 계좌를 삭제하고 싶으신 경우, 계좌 변경을 통해 원하는 변경 완료 후, 자동으로 현재 연동된 계좌는 삭제됩니다.',
                            ),
                            SizedBox(height: 20),
                            _buildNoticeItem(
                              '계좌 연결 과정에서 오류 발생 시',
                              '계좌 변경 과정에서 오류 발생 시, 기존 계좌로 유지돼요.',
                            ),
                            SizedBox(height: 20),
                            _buildNoticeItem(
                              '계좌 연결 후 연동 서비스 안내',
                              '기존 계좌에 연결된 서비스는 새 계좌로 자동으로 이전돼요.',
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 40),
                    ],
                  ),
                ),
    );
  }

  // 유의사항 항목 위젯
  Widget _buildNoticeItem(String title, String content) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: ShapeDecoration(
        color: Color(0xFFF0F0F0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Image.asset(
                'assets/icons/parent/bank/Fill_inform.png',
                width: 16,
                height: 16,
              ),
              SizedBox(width: 4),
              Text(
                title,
                style: TextStyle(
                  color: Color(0xFF202020),
                  fontSize: 12,
                  fontFamily: 'Pretendard-Bold',
                  letterSpacing: -0.24,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            content,
            style: TextStyle(
              color: Color(0xFF4A4A4A),
              fontSize: 11,
              fontFamily: 'Pretendard-Light',
              height: 1.45,
              letterSpacing: -0.22,
            ),
          ),
        ],
      ),
    );
  }

  // 은행 로고 가져오기
  Widget _getBankLogo(String bankName) {
    if (bankName.isEmpty) {
      return Container(
        color: Colors.grey[300],
        child: Icon(Icons.account_balance, color: Colors.grey[600]),
      );
    }

    String logoPath = _getBankLogoPath(bankName);

    return Image.asset(
      logoPath,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: Colors.grey[300],
          child: Icon(Icons.account_balance, color: Colors.grey[600]),
        );
      },
    );
  }

  // 은행명에 따른 로고 경로 반환
  String _getBankLogoPath(String bankName) {
    // 은행명을 소문자로 변환하여 비교
    String lowerBankName = bankName.toLowerCase();
    
    // 은행별 로고 매핑
    if (lowerBankName.contains('카카오')) {
      return 'assets/logos/bankName=카카오뱅크_new.png';
    } else if (lowerBankName.contains('신한')) {
      return 'assets/logos/shinhan_bank.png';
    } else if (lowerBankName.contains('하나')) {
      return 'assets/logos/hana_bank.png';
    } else if (lowerBankName.contains('우리')) {
      return 'assets/logos/woori_bank.png';
    } else if (lowerBankName.contains('국민') || lowerBankName.contains('kb')) {
      return 'assets/logos/kb_bank.png';
    } else if (lowerBankName.contains('기업') || lowerBankName.contains('ibk')) {
      return 'assets/logos/ibk_bank.png';
    } else if (lowerBankName.contains('농협') || lowerBankName.contains('nh')) {
      return 'assets/logos/nh_bank.png';
    } else if (lowerBankName.contains('씨티') || lowerBankName.contains('citi')) {
      return 'assets/logos/citi_bank.png';
    } else if (lowerBankName.contains('sc제일') || lowerBankName.contains('sc')) {
      return 'assets/logos/sc_bank.png';
    } else if (lowerBankName.contains('케이뱅크') || lowerBankName.contains('k뱅크')) {
      return 'assets/logos/kbank.png';
    } else if (lowerBankName.contains('토스')) {
      return 'assets/logos/toss.png';
    } else if (lowerBankName.contains('부산')) {
      return 'assets/logos/busan_bank.png';
    } else if (lowerBankName.contains('대구')) {
      return 'assets/logos/daegu_bank.png';
    } else if (lowerBankName.contains('광주')) {
      return 'assets/logos/gwangju_bank.png';
    } else if (lowerBankName.contains('전북')) {
      return 'assets/logos/jeonbuk_bank.png';
    } else if (lowerBankName.contains('경남')) {
      return 'assets/logos/kyongnam_bank.png';
    } else if (lowerBankName.contains('제주')) {
      return 'assets/logos/bankName=제주.png';
    } else if (lowerBankName.contains('수협')) {
      return 'assets/logos/suhyup_bank.png';
    } else if (lowerBankName.contains('새마을')) {
      return 'assets/logos/saemaul.png';
    } else if (lowerBankName.contains('신협')) {
      return 'assets/logos/shinhyup.png';
    } else if (lowerBankName.contains('우체국')) {
      return 'assets/logos/우체국_bank.png';
    } else if (lowerBankName.contains('축협')) {
      return 'assets/logos/축협_bank.png';
    }
    
    // 기본값: bankName= 형식으로 시도
    return 'assets/logos/bankName=$bankName.png';
  }

  // 계좌번호 포맷팅
  String _formatAccountNumber(String accountNumber) {
    if (accountNumber.isEmpty) return '';
    
    // 숫자만 추출
    String numbersOnly = accountNumber.replaceAll(RegExp(r'[^0-9]'), '');
    
    if (numbersOnly.length >= 7) {
      // 4-2-나머지 형태로 포맷팅
      return '${numbersOnly.substring(0, 4)}-${numbersOnly.substring(4, 6)}-${numbersOnly.substring(6)}';
    }
    
    return accountNumber;
  }

} 