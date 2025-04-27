import 'package:flutter/material.dart';
import '../../../theme/feed_styles.dart';

class FeedTabBar extends StatelessWidget {
  final int selectedTabIndex;
  final Function(int) onTabChanged;

  const FeedTabBar({
    super.key,
    required this.selectedTabIndex,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[300]!, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => onTabChanged(0),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: FeedStyles.tabDecoration(
                  isSelected: selectedTabIndex == 0,
                ),
                child: Text(
                  '피드',
                  textAlign: TextAlign.center,
                  style: FeedStyles.tabTextStyle(
                    isSelected: selectedTabIndex == 0,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () => onTabChanged(1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: FeedStyles.tabDecoration(
                  isSelected: selectedTabIndex == 1,
                ),
                child: Text(
                  '랭킹',
                  textAlign: TextAlign.center,
                  style: FeedStyles.tabTextStyle(
                    isSelected: selectedTabIndex == 1,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
