import 'package:flutter/material.dart';
import '../../../../services/auth_service.dart';
import '../chat_start_screen.dart';

class FrequentFriendItem extends StatelessWidget {
  final Map<String, dynamic> friend;
  final Function(Map<String, dynamic>)? onFriendUpdated;

  const FrequentFriendItem({
    super.key,
    required this.friend,
    this.onFriendUpdated,
  });

  @override
  Widget build(BuildContext context) {
    // 친구 정보에서 필요한 데이터 추출
    final userInfo = friend['userInfo'] ?? {};
    final friendInfo = friend['friendInfo'] ?? {};

    final String name =
        friendInfo['customName'] ??
        userInfo['realName'] ??
        friend['name'] ??
        '이름 없음';
    final String statusMessage =
        userInfo['statusMessage'] ?? friend['description'] ?? '';
    final String profileImagePath =
        userInfo['profileImagePath'] ?? friend['profileImageUrl'] ?? '';
    // 이미 완전한 URL인 경우 그대로 사용, 아니면 S3 URL로 변환
    final String profileImageUrl = profileImagePath.startsWith('http') 
        ? profileImagePath 
        : AuthService.getFullProfileImageUrl(profileImagePath);
    final bool isBlocked =
        friendInfo['isBlocked'] ?? friend['isBlocked'] ?? false;
    final bool isBestFriend =
        friendInfo['isBestFriend'] ?? friend['isBestFriend'] ?? false;
    final int friendId = friendInfo['friendId'] ?? friend['friendId'] ?? 0;
    final int userId = userInfo['userId'] ?? friend['userId'] ?? 0;

    return Container(
      width: double.infinity,
      height: 78,
      margin: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => ChatStartScreen(
                    userName: name,
                    userDescription: statusMessage,
                    userId: userId,
                    initialProfileImageUrl: profileImageUrl,
                    friendId: friendId,
                    isBlocked: isBlocked,
                    isBestFriend: isBestFriend,
                  ),
            ),
          ).then((result) {
            if (result != null &&
                result is Map<String, dynamic> &&
                onFriendUpdated != null) {
              onFriendUpdated!(result);
            }
          });
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 프로필 이미지
            Container(
              width: 48,
              height: 48,
              decoration: ShapeDecoration(
                image: profileImageUrl.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(profileImageUrl),
                        fit: BoxFit.cover,
                      )
                    : null,
                color: const Color(0xFFF0F6FF),
                shape: OvalBorder(),
              ),
              child: profileImageUrl.isEmpty
                  ? Center(
                      child: Text(
                        name.isNotEmpty ? name.substring(0, 1) : '?',
                        style: const TextStyle(
                          fontSize: 16,
                          fontFamily: 'Pretendard-Bold',
                          color: Color(0xFF3A88F4),
                        ),
                      ),
                    )
                  : null,
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
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                            color: Color(0xFF202020),
                            fontSize: 15,
                            fontFamily: 'Pretendard-Bold',
                            letterSpacing: -0.32,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),

                    ],
                  ),
                  if (statusMessage.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      statusMessage,
                      style: const TextStyle(
                        color: Color(0xFF8490A3),
                        fontSize: 13,
                        fontFamily: 'Pretendard-Light',
                        letterSpacing: -0.28,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
