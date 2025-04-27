import 'package:flutter/material.dart';

/// 미션 비교 섹션에서 사용하는 친구 프로필 아이템 위젯
class FriendProfileItem extends StatelessWidget {
  final Map<String, dynamic> friend;
  final VoidCallback onTap;

  const FriendProfileItem({super.key, required this.friend, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white,
            child: ClipOval(
              child: Image.asset(
                'assets/logos/search-sm.png',
                width: 50,
                height: 50,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 65,
            child: Text(
              friend['name'],
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
