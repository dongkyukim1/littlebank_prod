import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';

class ProfileImageUploadDialog extends StatefulWidget {
  final Function(File?)? onImageSelected;

  const ProfileImageUploadDialog({super.key, this.onImageSelected});

  static Future<File?> show(BuildContext context) {
    return showDialog<File?>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return ProfileImageUploadDialog(
          onImageSelected: (File? image) {
            Navigator.of(context).pop(image);
          },
        );
      },
    );
  }

  @override
  State<ProfileImageUploadDialog> createState() =>
      _ProfileImageUploadDialogState();
}

class _ProfileImageUploadDialogState extends State<ProfileImageUploadDialog> {
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  bool _isUploading = false;
  String? _errorMessage;
  int? _selectedOption; // 0: 카메라, 1: 갤러리, 2: 기본 프로필

  Future<void> _selectImage(ImageSource source) async {
    try {
      setState(() {
        _isUploading = true;
        _errorMessage = null;
      });

      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '이미지를 선택할 수 없습니다. 다시 시도해 주세요.';
      });
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  void _uploadImage() {
    if (_selectedImage != null) {
      // 선택한 이미지 사용
      widget.onImageSelected?.call(_selectedImage);
    } else if (_selectedOption == 2) {
      // 기본 프로필 선택
      widget.onImageSelected?.call(null);
    } else {
      setState(() {
        _errorMessage = '프로필 옵션을 선택해 주세요.';
      });
    }
  }

  void _skipProfileSetup() {
    widget.onImageSelected?.call(null);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isTablet = screenWidth > 600;

    // 화면 크기에 맞춘 모달 크기 계산 (none_goal_modal과 동일)
    final modalWidth =
        isTablet
            ? (screenWidth * 0.65).clamp(300.0, 400.0)
            : (screenWidth * 0.85).clamp(280.0, 350.0);
    final modalHeight =
        isTablet
            ? (screenHeight * 0.5).clamp(280.0, 380.0)
            : (screenHeight * 0.45).clamp(250.0, 320.0);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 50),
      child: Container(
        width: modalWidth,
        height: modalHeight,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 상단 헤더
            Container(
              width: double.infinity,
              padding: EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 6),
              decoration: const ShapeDecoration(
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '프로필을 설정해 볼까요?',
                    style: TextStyle(
                      color: const Color(0xFF202020),
                      fontSize: isTablet ? 18 : 16,
                      fontFamily: 'Pretendard-Bold',
                      letterSpacing: -0.64,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '나만의 개성이 담긴 사진을 설정하고 시작해 보세요!',
                    style: TextStyle(
                      color: const Color(0xFF999999),
                      fontSize: isTablet ? 14 : 12,
                      fontFamily: 'Pretendard-Light',
                      letterSpacing: -0.24,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // 프로필 옵션 영역
            Flexible(
              flex: 3,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: const BoxDecoration(color: Colors.white),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // 카메라 옵션
                      GestureDetector(
                        onTap:
                            _isUploading
                                ? null
                                : () {
                                  setState(() {
                                    _selectedOption = 0;
                                  });
                                  _selectImage(ImageSource.camera);
                                },
                        child: Container(
                          width: 70,
                          height: 70,
                          decoration: ShapeDecoration(
                            color: const Color(0xFFE7ECF6),
                            shape: OvalBorder(),
                          ),
                          child: Center(
                            child: Image.asset(
                              'assets/icons/my/camera.png',
                              width: 30,
                              height: 30,
                            ),
                          ),
                        ),
                      ),

                      // 갤러리 옵션
                      GestureDetector(
                        onTap:
                            _isUploading
                                ? null
                                : () {
                                  setState(() {
                                    _selectedOption = 1;
                                  });
                                  _selectImage(ImageSource.gallery);
                                },
                        child: Container(
                          width: 70,
                          height: 70,
                          decoration: ShapeDecoration(
                            color: const Color(0xFFE7ECF6),
                            shape: OvalBorder(),
                          ),
                          child: Center(
                            child: Image.asset(
                              'assets/icons/my/gallery.png',
                              width: 30,
                              height: 30,
                            ),
                          ),
                        ),
                      ),

                      // 기본 프로필 옵션 (미리보기 겸용)
                      GestureDetector(
                        onTap:
                            _isUploading
                                ? null
                                : () {
                                  setState(() {
                                    _selectedOption = 2;
                                    _selectedImage = null;
                                    _errorMessage = null;
                                  });
                                },
                        child: Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color:
                                  ((_selectedOption == 2 &&
                                              _selectedImage == null) ||
                                          (_selectedImage != null))
                                      ? const Color(0xFF3A88F4)
                                      : Colors.transparent,
                              width: 3,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(35),
                            child:
                                _selectedImage != null
                                    ? Image.file(
                                      _selectedImage!,
                                      width: 64,
                                      height: 64,
                                      fit: BoxFit.cover,
                                    )
                                    : Image.asset(
                                      'assets/icons/my/default_profile.png',
                                      width: 60,
                                      height: 60,
                                    ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 에러 메시지 영역
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                    fontFamily: 'Pretendard-Light',
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

            // 하단 버튼 영역
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: 16,
                top: 8,
              ),
              decoration: const ShapeDecoration(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
              ),
              child: Row(
                children: [
                  // 다음에 하기 버튼
                  Expanded(
                    child: GestureDetector(
                      onTap: _isUploading ? null : _skipProfileSetup,
                      child: Container(
                        height: 48,
                        decoration: ShapeDecoration(
                          color: const Color(0xFFB6B6B6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '다음에 하기',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isTablet ? 15 : 14,
                              fontFamily: 'Pretendard-Medium',
                              letterSpacing: -0.28,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // 설정 완료 버튼
                  Expanded(
                    child: GestureDetector(
                      onTap: _isUploading ? null : _uploadImage,
                      child: Container(
                        height: 48,
                        decoration: ShapeDecoration(
                          color: const Color(0xFF3A88F4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Center(
                          child:
                              _isUploading
                                  ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : Text(
                                    '설정 완료',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: isTablet ? 15 : 14,
                                      fontFamily: 'Pretendard-Medium',
                                      letterSpacing: -0.28,
                                    ),
                                  ),
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
