import 'package:flutter/material.dart';
import '../../../models/feed_data.dart';
import '../../../theme/feed_styles.dart';
import 'feed_item.dart';

class FeedList extends StatelessWidget {
  final FeedData feedData;
  final Function(int) onToggleDescription;
  final Function(int) onToggleLike;

  const FeedList({
    super.key,
    required this.feedData,
    required this.onToggleDescription,
    required this.onToggleLike,
  });

  @override
  Widget build(BuildContext context) {
    // 필터링된 피드 목록
    final filteredFeeds = feedData.getFilteredFeeds();

    if (filteredFeeds.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              '검색 결과가 없습니다',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '다른 필터를 선택해보세요',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: filteredFeeds.length,
      itemBuilder: (context, index) {
        final feed = filteredFeeds[index];
        final originalIndex = feedData.feeds.indexOf(feed);
        return FeedItemWidget(
          feed: feed,
          index: originalIndex,
          isDescriptionExpanded:
              feedData.expandedDescriptions[originalIndex] ?? false,
          onToggleDescription: onToggleDescription,
          onToggleLike: onToggleLike,
        );
      },
    );
  }
}

// 정렬 타입 선택 위젯
class SortTypeSelector extends StatelessWidget {
  final int sortType;
  final Function(int) onSortTypeChanged;

  const SortTypeSelector({
    super.key,
    required this.sortType,
    required this.onSortTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(
        left: 12.0,
        top: 8.0,
        right: 12.0,
        bottom: 8.0,
      ),
      color: Colors.white,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => onSortTypeChanged(0),
            child: Text(
              '• 최신순',
              style: TextStyle(
                color: sortType == 0 ? Colors.red : Colors.grey[400],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 12),
          InkWell(
            onTap: () => onSortTypeChanged(1),
            child: Text(
              '• 추천순',
              style: TextStyle(
                color: sortType == 1 ? Colors.red : Colors.grey[400],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// 글쓰기 영역 위젯
class WritePostSection extends StatelessWidget {
  final VoidCallback onWriteButtonPressed;

  const WritePostSection({super.key, required this.onWriteButtonPressed});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(15.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '학습 정보를 인증하고 공유하고',
                    style: TextStyle(color: Colors.grey[800], fontSize: 12),
                  ),
                  Text(
                    'XXXXXXXX',
                    style: TextStyle(color: Colors.grey[800], fontSize: 12),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: onWriteButtonPressed,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF3A88F4),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Text('글쓰기', style: FeedStyles.buttonTextStyle),
                    const SizedBox(width: 5),
                    const Icon(Icons.edit, color: Colors.white, size: 14),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 검색바 위젯
class SearchBar extends StatelessWidget {
  final TextEditingController? controller;
  final Function(String)? onSearch;

  const SearchBar({super.key, this.controller, this.onSearch});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 10.0),
      child: Container(
        height: 40,
        alignment: Alignment.center,
        decoration: FeedStyles.searchBarDecoration,
        child: TextField(
          controller: controller,
          textAlignVertical: TextAlignVertical.center,
          style: const TextStyle(fontSize: 14),
          decoration: FeedStyles.searchInputDecoration,
          onSubmitted: onSearch,
        ),
      ),
    );
  }
}
