import 'package:flutter/material.dart';
import '../../../../services/auth_service.dart';
import '../../chat_detail_screen.dart';
import '../chat_start_screen.dart';

class FriendItem extends StatelessWidget {
  final Map<String, dynamic> friend;
  final Function(Map<String, dynamic>)? onFriendUpdated;
  final bool isInviteMode;
  final bool isSelected;
  final bool isDisabled;
  final VoidCallback? onTap;

  const FriendItem({
    super.key,
    required this.friend,
    this.onFriendUpdated,
    this.isInviteMode = false,
    this.isSelected = false,
    this.isDisabled = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // 새로운 API 응답 구조에 맞게 데이터 추출
    final userInfo = friend['userInfo'] ?? {};
    final friendInfo = friend['friendInfo'] ?? {};

    // 친구 이름은 커스텀 이름이 있으면 우선하고, 없으면 실제 이름 사용
    final String name = friend['customName'] ?? userInfo['realName'] ?? '이름 없음';
    final String profileImagePath = userInfo['profileImagePath'] ?? '';
    // 이미 완전한 URL인 경우 그대로 사용, 아니면 S3 URL로 변환
    final String profileImageUrl = profileImagePath.startsWith('http') 
        ? profileImagePath 
        : AuthService.getFullProfileImageUrl(profileImagePath);
    final bool isBlocked =
        friend['isBlocked'] ?? friendInfo['isBlocked'] ?? false;
    final bool isBestFriend =
        friend['isBestFriend'] ?? friendInfo['isBestFriend'] ?? false;
    final int friendId = friend['friendId'] ?? friendInfo['friendId'] ?? 0;
    final int userId = userInfo['userId'] ?? 0;

    // 가족 멤버 여부 확인
    final bool isFamilyMember = friend['isFamilyMember'] ?? false;
    final String role = friend['role'] ?? userInfo['role'] ?? '';
    final bool isParent = role == 'PARENT';

    final String statusMessage = userInfo['statusMessage'] ?? '';

    return GestureDetector(
      onTap: isInviteMode
          ? (isDisabled ? null : onTap)
          : () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => ChatStartScreen(
                        userName: name,
                        userDescription: isBlocked ? '차단됨' : statusMessage,
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
                                  name.isNotEmpty ? name.substring(0, 1) : '?',
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
                          name.isNotEmpty ? name.substring(0, 1) : '?',
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

                      // 가족 멤버 표시 (부모님)
                      if (isParent)
                        Container(
                          margin: const EdgeInsets.only(left: 6),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFE9E9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            '부모님',
                            style: TextStyle(
                              color: Color(0xFFFF4D6A),
                              fontSize: 10,
                              fontFamily: 'Pretendard-Regular',
                            ),
                          ),
                        ),

                      // 가족 멤버 표시 (자녀)
                      if (isFamilyMember && !isParent)
                        Container(
                          margin: const EdgeInsets.only(left: 6),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE6F1FF),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            '가족',
                            style: TextStyle(
                              color: Color(0xFF3A88F4),
                              fontSize: 10,
                              fontFamily: 'Pretendard-Regular',
                            ),
                          ),
                        ),


                    ],
                  ),
                  if (statusMessage.isNotEmpty && !isBlocked) ...[
                    const SizedBox(height: 2),
                    Text(
                      statusMessage,
                      style: TextStyle(
                        color: Color(0xFF8490A3),
                        fontSize: 13,
                        fontFamily: 'Pretendard-Light',
                        letterSpacing: -0.28,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                  if (isBlocked) ...[
                    const SizedBox(height: 2),
                    Text(
                      '차단됨',
                      style: TextStyle(
                        color: Colors.red[300],
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

            // 채팅 버튼 또는 체크박스
            if (isInviteMode)
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isDisabled
                        ? Colors.grey[300]!
                        : (isSelected ? Color(0xFF5D9EFF) : Color(0xFFCCCCCC)),
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(4),
                  color: isSelected ? Color(0xFF5D9EFF) : Colors.transparent,
                ),
                child: isSelected
                    ? Icon(
                        Icons.check,
                        size: 16,
                        color: Colors.white,
                      )
                    : null,
              )
            else
              GestureDetector(
                onTap: () {
                  // 채팅 버튼 클릭 처리
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder:
                          (context) => ChatDetailScreen(
                            userName: name,
                            avatar: name.isNotEmpty ? name.substring(0, 1) : '?',
                            roomId: friend['roomId'] ?? 0,
                            userId: userId,
                          ),
                    ),
                  );
                },
                child: Image.asset(
                  'assets/icons/chat_floating.png',
                  width: 24,
                  height: 24,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// 채팅방 화면 위젯
class ChatRoomScreen extends StatelessWidget {
  final int friendId;
  final int userId;
  final String friendName;
  final String profileImageUrl;

  const ChatRoomScreen({
    super.key,
    required this.friendId,
    required this.userId,
    required this.friendName,
    required this.profileImageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(friendName)),
      body: Center(child: Text('채팅방 화면 - $friendName과의 대화')),
    );
  }
}
