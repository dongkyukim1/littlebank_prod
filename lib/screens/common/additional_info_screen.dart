import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/sns_service.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../parent/home_screen.dart';
import '../child/home_screen.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AdditionalInfoScreen extends StatefulWidget {
  const AdditionalInfoScreen({super.key});

  @override
  State<AdditionalInfoScreen> createState() => _AdditionalInfoScreenState();
}

class _AdditionalInfoScreenState extends State<AdditionalInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _birthdateController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _bankNameController = TextEditingController();
  final TextEditingController _bankAccountController = TextEditingController();
  final TextEditingController _bankCodeController = TextEditingController();

  String _selectedRole = 'PARENT';
  bool _isLoading = false;
  String? _errorMessage;
  String? _birthdateError;
  String _socialType = 'UNKNOWN';
  bool? _isAdult; // null: 아직 판단 못함, true: 성인, false: 미성년자

  @override
  void initState() {
    super.initState();
    _initSocialTypeInfo();
  }

  @override
  void dispose() {
    _birthdateController.dispose();
    _phoneController.dispose();
    _bankNameController.dispose();
    _bankAccountController.dispose();
    _bankCodeController.dispose();
    super.dispose();
  }

  Future<void> _initSocialTypeInfo() async {
    final socialType = await AuthService.getSocialType();
    print('소셜 로그인 타입: $socialType');
    if (mounted) {
      setState(() {
        _socialType = socialType ?? 'UNKNOWN';
      });
    }
  }

  // 생년월일로 성인 여부 판단
  void _checkAdultStatus(String birthdate) {
    if (birthdate.length != 6) {
      setState(() {
        _isAdult = null;
      });
      return;
    }

    try {
      // 생년월일 파싱
      int year = int.parse(birthdate.substring(0, 2));
      int month = int.parse(birthdate.substring(2, 4));
      int day = int.parse(birthdate.substring(4, 6));
      
      // 00~23년은 2000년대, 24~99년은 1900년대
      if (year >= 0 && year <= 23) {
        year += 2000;
      } else {
        year += 1900;
      }
      
      // 현재 날짜
      final now = DateTime.now();
      final currentYear = now.year;
      final currentMonth = now.month;
      final currentDay = now.day;
      
      // 나이 계산
      int age = currentYear - year;
      if (currentMonth < month || (currentMonth == month && currentDay < day)) {
        age--;
      }
      
      // 성인 여부 판단 (만 19세 이상)
      setState(() {
        _isAdult = age >= 19;
        
        // 성인 여부에 따라 역할 자동 설정
        if (_isAdult == true) {
          if (_selectedRole == 'CHILD') {
            _selectedRole = 'PARENT';
          }
        } else {
          _selectedRole = 'CHILD';
        }
      });
      
      print('생년월일: $birthdate, 만 나이: $age, 성인 여부: $_isAdult');
    } catch (e) {
      setState(() {
        _isAdult = null;
      });
      print('생년월일 파싱 오류: $e');
    }
  }

  Future<void> _saveAdditionalInfo() async {
    if (_birthdateController.text.length != 6) {
      setState(() {
        _birthdateError = '생년월일은 6자리로 입력해주세요';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 전화번호가 비어있으면 기본값 설정
      String phone = _phoneController.text.trim();
      if (phone.isEmpty) {
        phone = "01000000000";
      }
      
      Map<String, dynamic> result;
      
      if (_socialType == 'KAKAO') {
        result = await SNSService.updateSocialAdditionalInfo(
          birthdate: _birthdateController.text,
          role: _selectedRole,
          phone: phone
        );
      } else if (_socialType == 'NAVER') {
        final naverAccountId = await AuthService.getNaverAccountId();
        final email = await AuthService.getEmail();
        final name = await AuthService.getName();
        
        result = await SNSService.setNaverUserInfo(
          birthdate: _birthdateController.text,
          role: _selectedRole,
          phone: phone,
          naverAccountId: naverAccountId,
          email: email,
          name: name,
          bankName: _bankNameController.text.isEmpty ? null : _bankNameController.text,
          bankAccount: _bankAccountController.text.isEmpty ? null : _bankAccountController.text,
          bankCode: _bankCodeController.text.isEmpty ? null : _bankCodeController.text,
        );
      } else {
        result = await SNSService.updateSocialAdditionalInfo(
          birthdate: _birthdateController.text,
          role: _selectedRole,
          phone: phone
        );
      }
      
      if (!mounted) return;
      
      // 역할에 따라 적절한 화면으로 이동
      Widget homeScreen = _selectedRole == 'PARENT' 
          ? const ParentHomeScreen() 
          : const HomeScreen();
          
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => homeScreen),
        (route) => false,
      );
      
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('오류가 발생했습니다: $_errorMessage'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _selectRole(String role) {
    setState(() {
      _selectedRole = role;
    });
  }

  String _getSocialLoginMessage() {
    switch (_socialType) {
      case 'KAKAO':
        return '카카오 로그인이 완료되었습니다.\n서비스 이용을 위해 추가 정보를 입력해주세요.';
      case 'NAVER':
        return '네이버 로그인이 완료되었습니다.\n서비스 이용을 위해 추가 정보를 입력해주세요.';
      default:
        return '소셜 로그인이 완료되었습니다.\n서비스 이용을 위해 추가 정보를 입력해주세요.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE7ECF6),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(50.0),
        child: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            '추가 정보 입력',
            style: TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'Pretendard',
            ),
          ),
          centerTitle: true,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 안내 텍스트 카드
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          spreadRadius: 0,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getSocialLoginMessage(),
                          style: const TextStyle(
                            fontSize: 15,
                            height: 1.5,
                            fontFamily: 'Pretendard',
                            color: Color(0xFF4A4A4A),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 오류 메시지 표시
                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red.shade800, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(
                                color: Colors.red.shade800,
                                fontSize: 14,
                                fontFamily: 'Pretendard',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // 입력 폼 섹션
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          spreadRadius: 0,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 생년월일 입력
                        _buildSectionTitle('생년월일'),
                        _buildTextField(
                          controller: _birthdateController,
                          hintText: 'YYMMDD 형식으로 입력하세요',
                          errorText: _birthdateError,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          icon: Icons.calendar_today,
                          onChanged: (value) {
                            setState(() {
                              _birthdateError = value.length != 6 ? '생년월일은 6자리로 입력해주세요' : null;
                              _checkAdultStatus(value);
                            });
                          },
                        ),

                        const SizedBox(height: 20),

                        // 전화번호 입력
                        _buildSectionTitle('전화번호'),
                        _buildTextField(
                          controller: _phoneController,
                          hintText: '전화번호를 입력하세요 (예: 01012345678)',
                          keyboardType: TextInputType.phone,
                          icon: Icons.phone,
                        ),

                        const SizedBox(height: 20),

                        // 은행 정보
                        _buildSectionTitle('은행 정보 (선택사항)'),
                        
                        // 은행명
                        _buildTextField(
                          controller: _bankNameController,
                          hintText: '은행명 (예: 카카오뱅크)',
                          icon: Icons.account_balance,
                          margin: const EdgeInsets.only(bottom: 16),
                        ),

                        // 계좌번호
                        _buildTextField(
                          controller: _bankAccountController,
                          hintText: '계좌번호 (예: 1234567890123)',
                          keyboardType: TextInputType.number,
                          icon: Icons.credit_card,
                          margin: const EdgeInsets.only(bottom: 16),
                        ),

                        // 은행 코드
                        _buildTextField(
                          controller: _bankCodeController,
                          hintText: '은행 코드 (예: 090)',
                          keyboardType: TextInputType.number,
                          maxLength: 3,
                          icon: Icons.code,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 사용자 유형 안내 메시지
                  if (_isAdult != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F2F7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _isAdult == true ? Icons.info_outline : Icons.face,
                            color: const Color(0xFF5D9EFF),
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _isAdult == true 
                                ? '성인 사용자는 부모님 또는 선생님으로 가입할 수 있습니다.'
                                : '청소년 사용자는 자녀로 가입됩니다.',
                              style: const TextStyle(
                                color: Color(0xFF4A4A4A),
                                fontSize: 14,
                                fontFamily: 'Pretendard',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // 역할 선택 섹션
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          spreadRadius: 0,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('사용자 유형'),
                        const SizedBox(height: 12),
                        if (_isAdult == null || _isAdult == true)
                          _buildRoleOption('PARENT', '부모님', Icons.person),
                        if ((_isAdult == null || _isAdult == true) && _isAdult != false)
                          const Divider(height: 1),
                        if (_isAdult == null || _isAdult == false)
                          _buildRoleOption('CHILD', '자녀', Icons.child_care),
                        if ((_isAdult == null || _isAdult == true) && _isAdult != false)
                          const Divider(height: 1),
                        if (_isAdult == null || _isAdult == true)
                          _buildRoleOption('TEACHER', '선생님', Icons.school),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // 저장 버튼
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveAdditionalInfo,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5D9EFF),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                        shadowColor: const Color(0xFF5D9EFF).withOpacity(0.3),
                        disabledBackgroundColor: const Color(0xFF5D9EFF).withOpacity(0.5),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              '정보 저장하기',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Pretendard',
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w700, 
          fontSize: 16,
          fontFamily: 'Pretendard',
          color: Color(0xFF353535),
        ),
      ),
    );
  }
  
  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    IconData? icon,
    String? errorText,
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
    Function(String)? onChanged,
    EdgeInsets margin = EdgeInsets.zero,
  }) {
    return Container(
      margin: margin,
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: Colors.grey[500],
            fontFamily: 'Pretendard',
            fontSize: 14,
          ),
          errorText: errorText,
          errorStyle: const TextStyle(
            color: Colors.red,
            fontFamily: 'Pretendard',
            fontSize: 12,
          ),
          prefixIcon: icon != null ? Icon(icon, size: 20, color: const Color(0xFF5D9EFF)) : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF5D9EFF), width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.red.shade300, width: 1),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          counterText: '', // maxLength 카운터 숨기기
        ),
        style: const TextStyle(
          fontSize: 15,
          fontFamily: 'Pretendard',
          color: Color(0xFF353535),
        ),
        keyboardType: keyboardType,
        inputFormatters: [
          if (keyboardType == TextInputType.number) FilteringTextInputFormatter.digitsOnly,
          if (maxLength != null) LengthLimitingTextInputFormatter(maxLength),
        ],
        onChanged: onChanged,
      ),
    );
  }
  
  Widget _buildRoleOption(String value, String label, IconData icon) {
    final isSelected = _selectedRole == value;
    
    return Material(
      color: isSelected ? const Color(0xFFEFF5FF) : Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: () => _selectRole(value),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF5D9EFF) : const Color(0xFFF0F2F7),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: isSelected ? Colors.white : const Color(0xFF5D9EFF),
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                  color: isSelected ? const Color(0xFF353535) : const Color(0xFF4A4A4A),
                  fontFamily: 'Pretendard',
                ),
              ),
              const Spacer(),
              if (isSelected)
                Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    color: Color(0xFF5D9EFF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
