import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/auth_service.dart';

class ProfileImage extends StatelessWidget {
  final String? imagePath;
  final double size;
  final Color backgroundColor;
  final BoxFit fit;
  final double borderRadius;

  const ProfileImage({
    super.key,
    this.imagePath,
    this.size = 60,
    this.backgroundColor = Colors.grey,
    this.fit = BoxFit.cover,
    this.borderRadius = 30,
  });

  @override
  Widget build(BuildContext context) {
    if (imagePath == null || imagePath!.isEmpty) {
      return _buildDefaultImage();
    }

    final imageUrl = AuthService.getFullProfileImageUrl(imagePath);

    // URL이 S3인지 API 서버인지 확인
    final isS3Url = AuthService.isS3Url(imageUrl);

    print('이미지 URL 로딩: $imageUrl (S3: $isS3Url)');

    return FutureBuilder<Map<String, String>>(
      // API URL에만 인증 헤더를 적용
      future: isS3Url ? Future.value({}) : AuthService.getImageHeaders(),
      builder: (context, headersSnapshot) {
        final headers = headersSnapshot.data ?? {};

        if (isS3Url) {
          print('S3 이미지 로드 - 인증 헤더 없음');
        } else {
          print('API 이미지 로드 - 인증 헤더 적용: $headers');
        }

        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              httpHeaders: headers,
              fit: fit,
              placeholder: (context, url) => _buildLoadingPlaceholder(),
              errorWidget: (context, url, error) {
                print('이미지 로딩 오류: $error, URL: $url');
                return _buildErrorImage();
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingPlaceholder() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      ),
    );
  }

  Widget _buildDefaultImage() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Icon(Icons.person, color: Colors.white, size: size * 0.6),
    );
  }

  Widget _buildErrorImage() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Icon(Icons.error_outline, color: Colors.white, size: size * 0.6),
    );
  }
}
