import 'package:flutter/material.dart';
import '../../../models/feed_data.dart';
import '../../../theme/feed_styles.dart';

class FeedItemWidget extends StatelessWidget {
  final FeedItem feed;
  final int index;
  final bool isDescriptionExpanded;
  final Function(int) onToggleDescription;
  final Function(int) onToggleLike;

  const FeedItemWidget({
    super.key,
    required this.feed,
    required this.index,
    required this.isDescriptionExpanded,
    required this.onToggleDescription,
    required this.onToggleLike,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: FeedStyles.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 사용자 정보 + 더보기 버튼
          _buildHeader(),

          // 피드 본문
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Text(feed.content, style: FeedStyles.contentStyle),
          ),

          const SizedBox(height: 12),

          // 피드 이미지
          _buildImageSection(),

          // 좋아요, 댓글 정보
          _buildEngagementSection(),

          // 태그
          _buildTagsSection(),

          // 상세 설명 (접기/펼치기 가능)
          _buildDescriptionSection(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        children: [
          // 사용자 프로필 이미지
          CircleAvatar(
            radius: 16,
            backgroundColor: FeedStyles.primaryLightColor,
            child: Text(
              feed.username.substring(0, 1),
              style: const TextStyle(color: FeedStyles.primaryColor),
            ),
          ),
          const SizedBox(width: 8),
          // 이름 및 시간 정보
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(feed.username, style: FeedStyles.usernameStyle),
              const SizedBox(height: 2),
              Row(
                children: [
                  Text(feed.time, style: FeedStyles.metaStyle),
                  Text(' · ${feed.views}', style: FeedStyles.metaStyle),
                ],
              ),
            ],
          ),
          const Spacer(),
          // 더보기 버튼
          GestureDetector(
            onTap: () {
              // 더보기 버튼 기능
            },
            child: Icon(Icons.more_horiz, color: Colors.grey[600], size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSection() {
    if (feed.images <= 0) return const SizedBox.shrink();

    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: feed.images,
        itemBuilder: (context, index) {
          return Container(
            width:
                index == 0
                    ? MediaQuery.of(context).size.width
                    : MediaQuery.of(context).size.width * 0.8,
            margin: EdgeInsets.only(
              left: index == 0 ? 0 : 4,
              right: index == feed.images - 1 ? 0 : 4,
            ),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/images/feed_placeholder.png',
                fit: BoxFit.cover,
                errorBuilder:
                    (context, error, stackTrace) => const Center(
                      child: Icon(
                        Icons.image_not_supported,
                        color: Colors.grey,
                      ),
                    ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEngagementSection() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        children: [
          // 좋아요 버튼
          GestureDetector(
            onTap: () => onToggleLike(index),
            child: Row(
              children: [
                Icon(
                  feed.isLiked ? Icons.favorite : Icons.favorite_border,
                  color: feed.isLiked ? Colors.red : Colors.grey,
                  size: 20,
                ),
                const SizedBox(width: 4),
                Text('${feed.likes}', style: FeedStyles.metaStyle),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // 댓글 버튼
          Row(
            children: [
              const Icon(
                Icons.chat_bubble_outline,
                color: Colors.grey,
                size: 20,
              ),
              const SizedBox(width: 4),
              Text('${feed.comments}', style: FeedStyles.metaStyle),
            ],
          ),
          const Spacer(),
          // 공유 버튼
          const Icon(Icons.share, color: Colors.grey, size: 20),
        ],
      ),
    );
  }

  Widget _buildTagsSection() {
    if (feed.tags.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children:
            feed.tags.map((tag) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: FeedStyles.tagDecoration,
                child: Text('#$tag', style: FeedStyles.tagTextStyle),
              );
            }).toList(),
      ),
    );
  }

  Widget _buildDescriptionSection() {
    return GestureDetector(
      onTap: () {
        // 설명 영역 클릭 시 펼치기/접기
        if (isDescriptionExpanded) {
          onToggleDescription(index);
        }
      },
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              feed.description,
              style: FeedStyles.descriptionStyle,
              maxLines: isDescriptionExpanded ? null : 2,
              overflow:
                  isDescriptionExpanded
                      ? TextOverflow.visible
                      : TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            if (!isDescriptionExpanded &&
                (feed.description.split('\n').length > 2 ||
                    feed.description.length > 100))
              GestureDetector(
                onTap: () => onToggleDescription(index),
                child: Text(
                  '더보기',
                  style: TextStyle(
                    color: Colors.orange[800],
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
