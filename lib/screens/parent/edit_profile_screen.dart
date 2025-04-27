import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userInfo;

  const EditProfileScreen({super.key, required this.userInfo});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _bankNameController;
  late TextEditingController _bankAccountController;
  late TextEditingController _bankCodeController;
  File? _profileImage;
  String? _profileImagePath;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // 초기 값 설정
    _nameController = TextEditingController(
      text: widget.userInfo['name'] ?? '',
    );
    _emailController = TextEditingController(
      text: widget.userInfo['email'] ?? '',
    );
    _bankNameController = TextEditingController(
      text: widget.userInfo['bankName'] ?? '',
    );
    _bankAccountController = TextEditingController(
      text: widget.userInfo['bankAccount'] ?? '',
    );
    _bankCodeController = TextEditingController(
      text: widget.userInfo['bankCode'] ?? '',
    );
    _profileImagePath = widget.userInfo['profileImagePath'];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _bankNameController.dispose();
    _bankAccountController.dispose();
    _bankCodeController.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('프로필 수정'), centerTitle: true),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(8.0),
                        margin: const EdgeInsets.only(bottom: 16.0),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red.shade800),
                        ),
                      ),

                    // 프로필 이미지 섹션
                    Center(
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: _pickImage,
                            child: CircleAvatar(
                              radius: 50,
                              backgroundColor: const Color(0xFF146AFF),
                              backgroundImage:
                                  _profileImage != null
                                      ? FileImage(_profileImage!)
                                          as ImageProvider
                                      : (_profileImagePath != null &&
                                          _profileImagePath!.isNotEmpty)
                                      ? NetworkImage(
                                        AuthService.getFullProfileImageUrl(
                                          _profileImagePath,
                                        ),
                                      )
                                      : null,
                              child:
                                  (_profileImage == null &&
                                          (_profileImagePath == null ||
                                              _profileImagePath!.isEmpty))
                                      ? const Icon(
                                        Icons.person,
                                        size: 50,
                                        color: Colors.white,
                                      )
                                      : null,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: _pickImage,
                            child: const Text('이미지 수정'),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 사용자 정보 폼
                    Form(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 이름 필드
                          const Text('이름'),
                          const SizedBox(height: 4),
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              hintText: '이름을 입력하세요',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // 이메일 필드
                          const Text('이메일'),
                          const SizedBox(height: 4),
                          TextFormField(
                            controller: _emailController,
                            decoration: const InputDecoration(
                              hintText: '이메일을 입력하세요',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 16),

                          // 은행명 필드
                          const Text('은행명'),
                          const SizedBox(height: 4),
                          TextFormField(
                            controller: _bankNameController,
                            decoration: const InputDecoration(
                              hintText: '은행명을 입력하세요',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // 계좌번호 필드
                          const Text('계좌번호'),
                          const SizedBox(height: 4),
                          TextFormField(
                            controller: _bankAccountController,
                            decoration: const InputDecoration(
                              hintText: '계좌번호를 입력하세요',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 16),

                          // 은행 코드 필드
                          const Text('은행 코드'),
                          const SizedBox(height: 4),
                          TextFormField(
                            controller: _bankCodeController,
                            decoration: const InputDecoration(
                              hintText: '은행 코드를 입력하세요',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 24),

                          // 저장 버튼
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _saveProfile,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                  horizontal: 20,
                                ),
                                backgroundColor: const Color(0xFF146AFF),
                              ),
                              child: const Text(
                                '저장하기',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
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
