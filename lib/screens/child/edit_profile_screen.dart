import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/auth_service.dart';
import '../../services/email_verification_service.dart';
import '../../services/relationship_service.dart';
import '../../services/mission_service.dart';
import '../../services/feed_service.dart';
import '../../theme/app_colors.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import '../common/logout_modal.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userInfo;

  const EditProfileScreen({super.key, required this.userInfo});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _bankNameController;
  late TextEditingController _bankAccountController;
  late TextEditingController _bankCodeController;
  late TextEditingController _phoneController;
  late TextEditingController _birthDateController;
  File? _profileImage;
  String? _profileImagePath;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isEmailVerificationLoading = false;
  bool _isEmailVerified = false;
  
  // 통계 데이터 변수들
  int _postCount = 0;
  int _missionCount = 0;
  int _friendCount = 0;
  bool _isStatsLoading = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.userInfo['name'] ?? '');
    _emailController = TextEditingController(text: widget.userInfo['email'] ?? '');
    _bankNameController = TextEditingController(text: widget.userInfo['bankName'] ?? '');
    _bankAccountController = TextEditingController(text: widget.userInfo['bankAccount'] ?? '');
    _bankCodeController = TextEditingController(text: widget.userInfo['bankCode'] ?? '');
    
    // 생년월일과 전화번호 초기화
    String? birthDate = widget.userInfo['birthDate'] ?? widget.userInfo['rrn'];
    if (birthDate != null && birthDate.length >= 6) {
      // 주민등록번호 앞자리에서 생년월일 추출
      String year = birthDate.substring(0, 2);
      String month = birthDate.substring(2, 4);
      String day = birthDate.substring(4, 6);
      
      // 년도 변환 (90년대면 19xx, 00년대면 20xx)
      int yearInt = int.parse(year);
      String fullYear = yearInt >= 50 ? '19$year' : '20$year';
      
      _birthDateController = TextEditingController(text: '$fullYear.$month.$day');
    } else {
      _birthDateController = TextEditingController();
    }
    
    String? phone = widget.userInfo['phone'];
    if (phone != null && phone.length >= 10) {
      // 전화번호 포맷팅 (010-1234-5678)
      String formattedPhone = phone.replaceAll('-', '');
      if (formattedPhone.length == 11) {
        formattedPhone = '${formattedPhone.substring(0, 3)}-${formattedPhone.substring(3, 7)}-${formattedPhone.substring(7)}';
      } else if (formattedPhone.length == 10) {
        formattedPhone = '${formattedPhone.substring(0, 3)}-${formattedPhone.substring(3, 6)}-${formattedPhone.substring(6)}';
      }
      _phoneController = TextEditingController(text: formattedPhone);
    } else {
      _phoneController = TextEditingController();
    }
    
    _profileImagePath = widget.userInfo['profileImagePath'];
    _loadStatisticsData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _bankNameController.dispose();
    _bankAccountController.dispose();
    _bankCodeController.dispose();
    _phoneController.dispose();
    _birthDateController.dispose();
    super.dispose();
  }

  // 이메일 확인 메일 발송
  Future<void> _sendVerificationEmail() async {
    if (kDebugMode) {
      print('이메일 확인 버튼 클릭됨 - 이메일: ${_emailController.text}');
    }
    
    setState(() {
      _isEmailVerificationLoading = true;
    });
    
    try {
      final emailService = EmailVerificationService();
      if (kDebugMode) {
        print('이메일 서비스 인스턴스 생성 완료, API 호출 시작');
      }
      
      final result = await emailService.sendVerificationEmail(_emailController.text);
      
      if (kDebugMode) {
        print('이메일 인증 API 호출 결과: $result');
      }
      
      setState(() {
        _isEmailVerificationLoading = false;
        _isEmailVerified = result['success'] == true;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? '이메일 확인 메일이 발송되었습니다. 메일을 확인해주세요.')),
      );
    } catch (e) {
      if (kDebugMode) {
        print('이메일 인증 에러 발생: $e');
      }
      
      setState(() {
        _isEmailVerificationLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('이메일 확인 메일 발송 실패: $e')),
      );
    }
  }

  // 프로필 이미지 선택
  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedImage = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedImage != null) {
        setState(() {
          _profileImage = File(pickedImage.path);
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '이미지를 불러오는 중 오류가 발생했습니다: $e';
      });
      print('이미지 선택 오류: $e');
    }
  }

  // 프로필 수정 저장
  Future<void> _saveProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 프로필 이미지 업로드
      String? imagePath = _profileImagePath;
      if (_profileImage != null) {
        imagePath = await AuthService.uploadProfileImage(_profileImage!);
        print('업로드된 이미지 경로: $imagePath');

        // 프로필 이미지 업데이트
        await AuthService.updateUserProfile(imagePath);
      }

      // 이메일이 변경되었고 확인이 안되었으면 에러
      if (_emailController.text != widget.userInfo['email'] && !_isEmailVerified) {
        throw Exception('이메일이 변경되었습니다. 이메일 확인 버튼을 눌러 인증을 완료해주세요.');
      }

      // 사용자 정보 업데이트
      final updatedInfo = await AuthService.updateUserInfo(
        name: _nameController.text,
        email: _emailController.text,
        bankName: _bankNameController.text,
        bankAccount: _bankAccountController.text,
        bankCode: _bankCodeController.text,
      );

      // 수정된 정보를 합침
      final result = Map<String, dynamic>.from(widget.userInfo);
      result.addAll(updatedInfo);
      result['profileImagePath'] = imagePath;
      result['phone'] = _phoneController.text;
      result['birthDate'] = _birthDateController.text;

      // 수정 완료 - 이전 화면으로 결과 반환
      Navigator.pop(context, result);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '프로필 수정 중 오류가 발생했습니다: $e';
      });
      print('프로필 수정 오류: $e');
    }
  }

  // 통계 데이터 로드
  Future<void> _loadStatisticsData() async {
    try {
      setState(() {
        _isStatsLoading = true;
      });

      // 병렬로 데이터 로드
      final results = await Future.wait([
        _loadFriendCount(),
        _loadMissionCount(),
        _loadPostCount(),
      ]);

      setState(() {
        _friendCount = results[0] as int;
        _missionCount = results[1] as int;
        _postCount = results[2] as int;
        _isStatsLoading = false;
      });

      print('통계 데이터 로드 완료 - 친구: $_friendCount, 미션: $_missionCount, 작성글: $_postCount');
    } catch (e) {
      print('통계 데이터 로드 오류: $e');
      setState(() {
        _isStatsLoading = false;
      });
    }
  }

  // 친구 수 로드
  Future<int> _loadFriendCount() async {
    try {
      final friends = await RelationshipService.getFriendList();
      return friends?.length ?? 0;
    } catch (e) {
      print('친구 수 로드 오류: $e');
      return 0;
    }
  }

  // 미션 수 로드
  Future<int> _loadMissionCount() async {
    try {
      final missionData = await MissionService.getChildMissions(page: 0);
      return missionData?['totalElement'] ?? 0;
    } catch (e) {
      print('미션 수 로드 오류: $e');
      return 0;
    }
  }

  // 작성글 수 로드
  Future<int> _loadPostCount() async {
    try {
      final feedData = await FeedService.getMyFeeds(page: 0, size: 1);
      return feedData?['totalElements'] ?? 0;
    } catch (e) {
      print('작성글 수 로드 오류: $e');
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    
    return Scaffold(
      body: Container(
        width: screenWidth,
        height: screenHeight,
        clipBehavior: Clip.antiAlias,
        decoration: const BoxDecoration(color: Color(0xFFE7ECF6)),
        child: Stack(
          children: [
            // Status Bar
            Positioned(
              left: 0,
              top: 0,
              child: Container(
                width: screenWidth,
                height: 44,
                clipBehavior: Clip.antiAlias,
                decoration: const BoxDecoration(),
                child: Stack(
                  children: [
                    Positioned(
                      left: 19,
                      top: 17,
                      child: Container(
                        width: 54,
                        height: 20,
                        decoration: ShapeDecoration(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              left: 0,
                              top: 1,
                              child: SizedBox(
                                width: 54,
                                height: 20,
                                child: Text(
                                  '9:41',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 15,
                                    fontFamily: _getFontFamily(FontWeight.w600),
                                    fontWeight: FontWeight.w600,
                                    height: 1.33,
                                    letterSpacing: -0.50,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // 상단 파란색 배경
            Positioned(
              left: 0,
              top: 0,
              child: Container(
                width: screenWidth,
                height: screenHeight * 0.43,
                decoration: ShapeDecoration(
                  color: const Color(0xFF5D9EFF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(32),
                      bottomRight: Radius.circular(32),
                    ),
                  ),
                ),
              ),
            ),

            // 앱바
            Positioned(
              left: 0,
              top: 44,
              child: Container(
                width: screenWidth,
                height: 56,
                child: Stack(
                  children: [
                    Positioned(
                      left: 16,
                      top: 16,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 24,
                          height: 24,
                          child: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: screenWidth / 2 - 40,
                      top: 18.5,
                      child: Text(
                        '프로필 수정',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontFamily: _getFontFamily(FontWeight.w700),
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.32,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 16,
                      top: 16,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // 로그아웃 아이콘
                          Padding(
                            padding: const EdgeInsets.only(right: 16),
                            child: GestureDetector(
                              onTap: () {
                                LogoutModal.show(context);
                              },
                              child: Image.asset(
                                'assets/images/logout.png',
                                width: 24,
                                height: 24,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          // 설정 아이콘
                          GestureDetector(
                            onTap: () {
                              // 설정 화면으로 이동
                              print('설정 버튼 클릭됨');
                            },
                            child: Image.asset(
                              'assets/icons/setting.png',
                              width: 24,
                              height: 24,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 프로필 이미지
            Positioned(
              left: screenWidth / 2 - 50,
              top: 120,
              child: GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.white,
                  backgroundImage: _profileImage != null
                      ? FileImage(_profileImage!) as ImageProvider
                      : (_profileImagePath != null && _profileImagePath!.isNotEmpty)
                          ? NetworkImage(
                              AuthService.getFullProfileImageUrl(_profileImagePath!),
                            )
                          : null,
                  child: (_profileImage == null &&
                          (_profileImagePath == null || _profileImagePath!.isEmpty))
                      ? const Icon(
                          Icons.person,
                          size: 50,
                          color: Color(0xFF5D9EFF),
                        )
                      : null,
                ),
              ),
            ),

            // 통계 카드
            _buildStatsCard(),

            // 프로필 정보 섹션
            Positioned(
              left: 17,
              top: screenHeight * 0.44,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: screenWidth - 34,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    decoration: ShapeDecoration(
                      gradient: LinearGradient(
                        begin: const Alignment(0.03, 0.00),
                        end: const Alignment(1.00, 1.00),
                        colors: [
                          Colors.white.withValues(alpha: 0.60),
                          Colors.white.withValues(alpha: 0.30)
                        ],
                      ),
                      shape: RoundedRectangleBorder(
                        side: const BorderSide(width: 0.40, color: Colors.white),
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildProfileRow('이름', _nameController.text, () {
                          _showEditDialog('이름', _nameController);
                        }),
                        const SizedBox(height: 16),
                        _buildProfileRow('생년월일', _birthDateController.text, () {
                          _showEditDialog('생년월일', _birthDateController);
                        }),
                        const SizedBox(height: 16),
                        _buildProfileRow('전화번호', _phoneController.text, () {
                          _showEditDialog('전화번호', _phoneController);
                        }),
                        const SizedBox(height: 16),
                        _buildEmailProfileRow('이메일', _emailController.text, () {
                          _showEmailEditDialog();
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 저장 버튼
            Positioned(
              left: 16,
              bottom: MediaQuery.of(context).padding.bottom + 150,
              child: GestureDetector(
                onTap: _isLoading ? null : _saveProfile,
                child: Container(
                  width: screenWidth - 32,
                  padding: const EdgeInsets.all(16),
                  decoration: ShapeDecoration(
                    color: const Color(0xFF3A88F4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (_isLoading)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      else
                        Text(
                          '저장하기',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontFamily: _getFontFamily(FontWeight.w300),
                            fontWeight: FontWeight.w300,
                            letterSpacing: -0.28,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // 에러 메시지
            if (_errorMessage != null)
              Positioned(
                left: 16,
                bottom: MediaQuery.of(context).padding.bottom + 200,
                child: Container(
                  width: screenWidth - 32,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red.shade800),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Positioned(
      left: (screenWidth - 286) / 2,
      top: screenHeight * 0.28,
      child: Container(
        width: 286,
        padding: const EdgeInsets.all(12),
        decoration: ShapeDecoration(
          color: Colors.white.withValues(alpha: 0.30),
          shape: RoundedRectangleBorder(
            side: const BorderSide(width: 0.80, color: Colors.white),
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: _isStatsLoading
            ? Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      _buildStatItem('작성글 수', '$_postCount'),
                      _buildStatItem('미션 수', '$_missionCount'),
                      _buildStatItem('친구 수', '$_friendCount'),
                    ],
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Expanded(
      child: Container(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontFamily: _getFontFamily(FontWeight.w300),
                fontWeight: FontWeight.w300,
                letterSpacing: -0.28,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: const Color(0xFF001F55),
                fontSize: 22,
                fontFamily: _getFontFamily(FontWeight.w700),
                fontWeight: FontWeight.w700,
                letterSpacing: -0.96,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileRow(String label, String value, VoidCallback onTap, {bool showDivider = true}) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 33,
          child: Stack(
            children: [
              Positioned(
                left: 0,
                top: 8,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 72,
                      child: Text(
                        label,
                        style: TextStyle(
                          color: const Color(0xFF666666),
                          fontSize: 14,
                          fontFamily: _getFontFamily(FontWeight.w300),
                          fontWeight: FontWeight.w300,
                          letterSpacing: -0.28,
                        ),
                      ),
                    ),
                    Text(
                      value,
                      style: TextStyle(
                        color: const Color(0xFF4A4A4A),
                        fontSize: 14,
                        fontFamily: _getFontFamily(FontWeight.w300),
                        fontWeight: FontWeight.w300,
                        letterSpacing: -0.28,
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                right: 0,
                top: 0,
                child: GestureDetector(
                  onTap: onTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: ShapeDecoration(
                      color: const Color(0xFFE7ECF6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(
                      '변경하기',
                      style: TextStyle(
                        color: const Color(0xFF001F55),
                        fontSize: 11,
                        fontFamily: _getFontFamily(FontWeight.w300),
                        fontWeight: FontWeight.w300,
                        letterSpacing: -0.22,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showDivider) ...[
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            height: 1,
            color: const Color.fromRGBO(188, 195, 207, 1),
          ),
        ],
      ],
    );
  }

  Widget _buildEmailProfileRow(String label, String value, VoidCallback onTap, {bool showDivider = false}) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 33,
          child: Stack(
            children: [
              Positioned(
                left: 0,
                top: 8,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 72,
                      child: Text(
                        label,
                        style: TextStyle(
                          color: const Color(0xFF666666),
                          fontSize: 14,
                          fontFamily: _getFontFamily(FontWeight.w300),
                          fontWeight: FontWeight.w300,
                          letterSpacing: -0.28,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: MediaQuery.of(context).size.width - 220,
                      child: Text(
                        value,
                        style: TextStyle(
                          color: const Color(0xFF4A4A4A),
                          fontSize: 14,
                          fontFamily: _getFontFamily(FontWeight.w300),
                          fontWeight: FontWeight.w300,
                          letterSpacing: -0.28,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                right: 0,
                top: 0,
                child: GestureDetector(
                  onTap: onTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: ShapeDecoration(
                      color: _isEmailVerified ? Colors.green : const Color(0xFFE7ECF6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(
                      _isEmailVerified ? '확인완료' : '변경하기',
                      style: TextStyle(
                        color: _isEmailVerified ? Colors.white : const Color(0xFF001F55),
                        fontSize: 11,
                        fontFamily: _getFontFamily(FontWeight.w300),
                        fontWeight: FontWeight.w300,
                        letterSpacing: -0.22,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showDivider) ...[
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            height: 1,
            color: const Color.fromRGBO(133, 144, 163, 1),
          ),
        ],
      ],
    );
  }

  void _showEditDialog(String title, TextEditingController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$title 수정'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: title,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              setState(() {});
              Navigator.pop(context);
            },
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }

  void _showEmailEditDialog() {
    final tempController = TextEditingController(text: _emailController.text);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('이메일 수정'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: tempController,
              decoration: const InputDecoration(
                labelText: '이메일',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isEmailVerificationLoading
                        ? null
                        : () async {
                            if (tempController.text.isNotEmpty) {
                              _emailController.text = tempController.text;
                              await _sendVerificationEmail();
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isEmailVerified ? Colors.green : const Color(0xFF4F78FF),
                    ),
                    child: _isEmailVerificationLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            _isEmailVerified ? '확인완료' : '이메일 확인',
                            style: const TextStyle(color: Colors.white),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              _emailController.text = tempController.text;
              setState(() {});
              Navigator.pop(context);
            },
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }

  String _getFontFamily(FontWeight fontWeight) {
    switch (fontWeight) {
      case FontWeight.w100:
        return 'Pretendard-Thin';
      case FontWeight.w200:
        return 'Pretendard-ExtraLight';
      case FontWeight.w300:
        return 'Pretendard-Light';
      case FontWeight.w400:
        return 'Pretendard-Regular';
      case FontWeight.w500:
        return 'Pretendard-Medium';
      case FontWeight.w600:
        return 'Pretendard-SemiBold';
      case FontWeight.w700:
        return 'Pretendard-Bold';
      case FontWeight.w800:
        return 'Pretendard-ExtraBold';
      case FontWeight.w900:
        return 'Pretendard-Black';
      default:
        return 'Pretendard-Regular';
    }
  }
}
