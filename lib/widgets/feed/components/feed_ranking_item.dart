import 'package:flutter/material.dart';
import '../../../theme/feed_styles.dart';

class RankingItem extends StatelessWidget {
  final int rank;
  final String username;
  final int completedMissions;
  final int totalMissions;

  const RankingItem({
    super.key,
    required this.rank,
    required this.username,
    required this.completedMissions,
    required this.totalMissions,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: FeedStyles.cardDecoration,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: FeedStyles.primaryLightColor,
          child: Text(
            '$rank',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: FeedStyles.primaryColor,
              fontSize: 16,
            ),
          ),
        ),
        title: Text(
          username,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            '미션 완료 $completedMissions / $totalMissions',
            style: const TextStyle(
              fontSize: 14,
              color: FeedStyles.textMediumColor,
            ),
          ),
        ),
        trailing:
            rank <= 3
                ? Icon(
                  Icons.emoji_events,
                  size: 28,
                  color:
                      rank == 1
                          ? Colors.amber
                          : rank == 2
                          ? Colors.grey[400]
                          : Colors.brown[300],
                )
                : null,
      ),
    );
  }
}
