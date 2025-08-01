import 'package:flutter/material.dart';
import '../../../models/feed_data.dart';
import '../../../theme/feed_styles.dart';
import 'feed_item.dart';

class FeedList extends StatefulWidget {
  final FeedData feedData;
  final Function(int) onToggleDescription;
  final Function(int) onToggleLike;
  final Function(int)? onFeedDeleted;
  final Function(int)? onFeedUpdated;

  const FeedList({
    super.key,
    required this.feedData,
    required this.onToggleDescription,
    required this.onToggleLike,
    this.onFeedDeleted,
    this.onFeedUpdated,
  });

  @override
  State<FeedList> createState() => _FeedListState();
}

class _FeedListState extends State<FeedList> {
  @override
  Widget build(BuildContext context) {
    // 필터링된 피드 목록
    final filteredFeeds = widget.feedData.getFilteredFeeds();

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
                fontFamily: 'Pretendard-Medium',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '다른 필터를 선택해보세요',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
                fontFamily: 'Pretendard-Light',
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      itemCount: filteredFeeds.length,
      separatorBuilder: (context, index) => const SizedBox(height: 24), // 피드들 간의 간격을 24px로 설정
      itemBuilder: (context, index) {
        final feed = filteredFeeds[index];
        final originalIndex = widget.feedData.feeds.indexOf(feed);
        return FeedItemWidget(
          feed: feed,
          index: originalIndex,
          isDescriptionExpanded:
              widget.feedData.expandedDescriptions[originalIndex] ?? false,
          onToggleDescription: widget.onToggleDescription,
          onToggleLike: widget.onToggleLike,
          onCommentAdded: _handleCommentAdded,
          onCommentEdited: _handleCommentEdited,
          onCommentDeleted: _handleCommentDeleted,
          onFeedDeleted: widget.onFeedDeleted != null
              ? (deletedIndex) => widget.onFeedDeleted!(index)
              : null,
          onFeedUpdated: widget.onFeedUpdated != null
              ? (updatedIndex) => widget.onFeedUpdated!(index)
              : null,
        );
      },
    );
  }
  
  // 각 아이템의 댓글 수 업데이트
  void _updateCommentCount(int feedId, int change) {
    for (int i = 0; i < widget.feedData.feeds.length; i++) {
      if (widget.feedData.feeds[i].feedId == feedId) {
        setState(() {
          widget.feedData.feeds[i].commentCount = 
              (widget.feedData.feeds[i].commentCount ?? 0) + change;
        });
        break;
      }
    }
  }

  // 댓글 추가 처리
  void _handleCommentAdded(int feedId, Map<String, dynamic> newComment) {
    _updateCommentCount(feedId, 1); // 댓글 추가 시 +1
  }

  // 댓글 수정 처리
  void _handleCommentEdited(int feedId, int commentId, String content) {
    // 댓글 수정은 수에 변화가 없으므로 처리하지 않음
  }

  // 댓글 삭제 처리
  void _handleCommentDeleted(int feedId, int commentId) {
    _updateCommentCount(feedId, -1); // 댓글 삭제 시 -1
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
    // 화면 너비를 받아 반응형으로 만듦
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      width: null, // 고정 너비 제거하여 Flexible이 작동하도록 함
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: const BoxDecoration(
        color: Color(0xFFF0F2F7), // 배경색을 #F0F2F7로 설정
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min, // 필요한 공간만 사용
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start, // 상단 정렬로 변경
        children: [
          GestureDetector(
            onTap: () => onSortTypeChanged(0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start, // 점도 상단 정렬로 변경
              children: [
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(top: 3), // 약간의 여백 추가
                  decoration: ShapeDecoration(
                    color:
                        sortType == 0
                            ? const Color(0xFF5D9EFF)
                            : const Color(0xFFB6B6B6),
                    shape: const OvalBorder(),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '최신순',
                  style: TextStyle(
                    color:
                        sortType == 0
                            ? const Color(0xFF001F55)
                            : const Color(0xFFB6B6B6),
                    fontSize: 12,
                    fontFamily:
                        sortType == 0
                            ? 'Pretendard-Light'
                            : 'Pretendard-ExtraLight',
                    letterSpacing: -0.28,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => onSortTypeChanged(1),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start, // 점도 상단 정렬로 변경
              children: [
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(top: 3), // 약간의 여백 추가
                  decoration: ShapeDecoration(
                    color:
                        sortType == 1
                            ? const Color(0xFF5D9EFF)
                            : const Color(0xFFB6B6B6),
                    shape: const OvalBorder(),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '도움이 된 순',
                  style: TextStyle(
                    color:
                        sortType == 1
                            ? const Color(0xFF001F55)
                            : const Color(0xFFB6B6B6),
                    fontSize: 12,
                    fontFamily:
                        sortType == 1
                            ? 'Pretendard-Light'
                            : 'Pretendard-ExtraLight',
                    letterSpacing: -0.28,
                  ),
                ),
              ],
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
            const Spacer(),
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
class SearchWidget extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onSearch;

  const SearchWidget({
    super.key,
    required this.controller,
    required this.onSearch,
  });

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
          style: const TextStyle(
            fontSize: 14,
            fontFamily: 'Pretendard-Regular',
          ),
          decoration: FeedStyles.searchInputDecoration,
          onSubmitted: onSearch,
        ),
      ),
    );
  }
}
