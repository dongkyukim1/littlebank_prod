import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';

class ProfileImageUploadDialog extends StatefulWidget {
  final Function onCompleted;

  const ProfileImageUploadDialog({super.key, required this.onCompleted});

  @override
  State<ProfileImageUploadDialog> createState() =>
      _ProfileImageUploadDialogState();
}

class _ProfileImageUploadDialogState extends State<ProfileImageUploadDialog> {
  File? _selectedImage;
  bool _isUploading = false;
  String? _errorMessage;

  // 이미지 선택 메서드
  Future<void> _selectImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedImage = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedImage != null) {
        setState(() {
          _selectedImage = File(pickedImage.path);
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '이미지를 선택하는 중 오류가 발생했습니다: $e';
      });
      print('이미지 선택 오류: $e');
    }
  }

  // 이미지 소스 선택 옵션 표시
  void _showImageSourceOptions() {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_camera),
                  title: const Text('카메라로 촬영하기'),
                  onTap: () {
                    Navigator.pop(context);
                    _selectImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('갤러리에서 선택하기'),
                  onTap: () {
                    Navigator.pop(context);
                    _selectImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
    );
  }

  // 이미지 업로드 처리
  Future<void> _uploadImage() async {
    if (_selectedImage == null) {
      setState(() {
        _errorMessage = '이미지를 먼저 선택해주세요';
      });
      return;
    }

    setState(() {
      _isUploading = true;
      _errorMessage = null;
    });

    try {
      // 이미지 업로드 API 호출
      final imagePath = await AuthService.uploadProfileImage(_selectedImage!);

      // 서버에 프로필 이미지 경로 업데이트
      await AuthService.updateUserProfile(imagePath);

      // 첫 로그인 상태 변경
      await AuthService.setFirstLoginCompleted();

      if (mounted) {
        // 업로드 성공 시 다이얼로그 닫기
        Navigator.of(context).pop();
        widget.onCompleted();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _errorMessage = '업로드 중 오류가 발생했습니다: $e';
        });
      }
      print('이미지 업로드 오류: $e');
    }
  }

  // 프로필 설정 건너뛰기
  void _skipProfileSetup() async {
    setState(() {
      _isUploading = true;
    });

    try {
      // 첫 로그인 상태만 변경
      await AuthService.setFirstLoginCompleted();

      if (mounted) {
        // 다이얼로그 닫기
        Navigator.of(context).pop();
        widget.onCompleted();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _errorMessage = '오류가 발생했습니다: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '프로필 사진 설정',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                '리틀뱅크에서 사용할 프로필 사진을 설정해주세요.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
              const SizedBox(height: 24),

              // 이미지 표시 영역
              GestureDetector(
                onTap: _isUploading ? null : _showImageSourceOptions,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primaryColor, width: 2),
                    image:
                        _selectedImage != null
                            ? DecorationImage(
                              image: FileImage(_selectedImage!),
                              fit: BoxFit.cover,
                            )
                            : null,
                  ),
                  child:
                      _selectedImage == null
                          ? const Icon(
                            Icons.add_a_photo,
                            color: AppColors.primaryColor,
                            size: 40,
                          )
                          : null,
                ),
              ),
              const SizedBox(height: 16),

              // 안내 텍스트
              Text(
                _selectedImage == null ? '탭하여 사진을 선택하세요' : '탭하여 사진을 변경하세요',
                style: const TextStyle(fontSize: 14, color: Colors.black54),
              ),

              // 에러 메시지 표시
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],

              const SizedBox(height: 24),

              // 버튼 영역
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // 건너뛰기 버튼
                  TextButton(
                    onPressed: _isUploading ? null : _skipProfileSetup,
                    child: const Text(
                      '건너뛰기',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),

                  // 업로드 버튼
                  ElevatedButton(
                    onPressed: _isUploading ? null : _uploadImage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 10,
                      ),
                    ),
                    child:
                        _isUploading
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                            : const Text('설정 완료'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
