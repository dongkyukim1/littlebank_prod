import 'package:flutter/material.dart';
import '../../../../services/auth_service.dart';
import '../chat_start_screen.dart';

class ProfileItem extends StatelessWidget {
  final Map<String, dynamic> profile;
  final Function(Map<String, dynamic>)? onProfileUpdated;
  final bool showChatIcon;

  const ProfileItem({
    super.key,
    required this.profile,
    this.onProfileUpdated,
    this.showChatIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    // 프로필 이미지 URL 처리
    final String profileImagePath = profile['profileImageUrl'] ?? '';
    // 이미 완전한 URL인 경우 그대로 사용, 아니면 S3 URL로 변환
    final String profileImageUrl = profileImagePath.startsWith('http') 
        ? profileImagePath 
        : AuthService.getFullProfileImageUrl(profileImagePath);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => ChatStartScreen(
                  userName: profile['name'],
                  userDescription: profile['description'],
                  userId: profile['userId'],
                  initialProfileImageUrl: profileImageUrl,
                  friendId: profile['friendId'],
                  isBlocked: profile['isBlocked'],
                  isBestFriend: profile['isBestFriend'],
                ),
          ),
        ).then((result) {
          if (result != null &&
              result is Map<String, dynamic> &&
              onProfileUpdated != null) {
            onProfileUpdated!(result);
          }
        });
      },
      child: Container(
        width: double.infinity,
        height: 78,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: ShapeDecoration(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 프로필 이미지
            Container(
              width: 48,
              height: 48,
              decoration: ShapeDecoration(
                color: const Color(0xFFF0F6FF),
                shape: const OvalBorder(),
              ),
              child:
                  profileImageUrl.isNotEmpty
                      ? ClipOval(
                        child: Image.network(
                          profileImageUrl,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                                strokeWidth: 2.0,
                                color: const Color(0xFF3A88F4),
                              ),
                            );
                          },
                          errorBuilder:
                              (_, __, ___) => Center(
                                child: Text(
                                  profile['name'].toString().substring(0, 1),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontFamily: 'Pretendard-Bold',
                                    color: Color(0xFF3A88F4),
                                  ),
                                ),
                              ),
                        ),
                      )
                      : Center(
                        child: Text(
                          profile['name'].toString().substring(0, 1),
                          style: const TextStyle(
                            fontSize: 16,
                            fontFamily: 'Pretendard-Bold',
                            color: Color(0xFF3A88F4),
                          ),
                        ),
                      ),
            ),
            const SizedBox(width: 20),

            // 이름 및 상태 메시지
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(
                        profile['name'],
                        style: const TextStyle(
                          color: Color(0xFF202020),
                          fontSize: 15,
                          fontFamily: 'Pretendard-Bold',
                          letterSpacing: -0.32,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),

                    ],
                  ),
                  if (profile['description'] != null &&
                      profile['description'].isNotEmpty)
                    const SizedBox(height: 2),
                  if (profile['description'] != null &&
                      profile['description'].isNotEmpty)
                    Text(
                      profile['description'],
                      style: TextStyle(
                        color:
                            profile['isBlocked'] == true
                                ? Colors.red[300]
                                : const Color(0xFF999999),
                        fontSize: 13,
                        fontFamily: 'Pretendard-Light',
                        letterSpacing: -0.28,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                ],
              ),
            ),

            // 채팅 버튼 (showChatIcon이 true일 때만 표시)
            if (showChatIcon)
              Image.asset('assets/icons/chat_floating.png', width: 24, height: 24),
          ],
        ),
      ),
    );
  }
}
