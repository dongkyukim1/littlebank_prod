import 'package:flutter/material.dart';
import '../../../theme/challenge/challenge_styles.dart';

class ChallengeSummary extends StatelessWidget {
  final String type;
  final String title;
  final String participants;
  final String period;
  final String time;

  const ChallengeSummary({
    super.key,
    required this.type,
    required this.title,
    required this.participants,
    required this.period,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: ChallengeStyles.summaryBoxDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(type, style: ChallengeStyles.tagStyle),
              ),
              const Spacer(),
              Text('참여인원: $participants', style: ChallengeStyles.metaTextStyle),
            ],
          ),
          const SizedBox(height: 12),
          Text(title, style: ChallengeStyles.titleStyle),
          const SizedBox(height: 8),
          Text('기간: $period', style: ChallengeStyles.descriptionStyle),
          Text('기본 시간: $time', style: ChallengeStyles.descriptionStyle),
        ],
      ),
    );
  }
}
