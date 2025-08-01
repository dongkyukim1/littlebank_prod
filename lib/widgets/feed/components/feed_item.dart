import 'package:flutter/material.dart';
import '../../../models/feed_data.dart';
import '../../../screens/child/feed/feed_detail_screen.dart';
import '../../../widgets/feed/components/feed_comment_bottom_sheet.dart';
import '../../../services/feed_service.dart';
import '../../../screens/child/feed/edit_feed_screen.dart';
import '../../../widgets/feed/components/feed_action_sheet.dart';

class FeedItemWidget extends StatelessWidget {
  final FeedItem feed;
  final int index;
  final bool isDescriptionExpanded;
  final Function(int) onToggleDescription;
  final Function(int) onToggleLike;
  final Function(int, Map<String, dynamic>)? onCommentAdded;
  final Function(int, int, String)? onCommentEdited;
  final Function(int, int)? onCommentDeleted;
  // 피드 삭제 콜백 추가
  final Function(int)? onFeedDeleted;
  final Function(int)? onFeedUpdated;

  const FeedItemWidget({
    super.key,
    required this.feed,
    required this.index,
    required this.isDescriptionExpanded,
    required this.onToggleDescription,
    required this.onToggleLike,
    this.onCommentAdded,
    this.onCommentEdited,
    this.onCommentDeleted,
    this.onFeedDeleted,
    this.onFeedUpdated,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // 피드 아이템 클릭 시 상세 화면으로 이동
        if (feed.feedId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FeedDetailScreen(feedId: feed.feedId!),
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.fromLTRB(14, 8, 10, 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 카테고리 배지와 더보기 버튼
            Padding(
              padding: const EdgeInsets.only(top: 6), // 상단 패딩을 6px로 증가
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 카테고리 태그 그룹
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (feed.getTagText().isNotEmpty)
                        _buildCategoryTag(
                          feed.getTagText(),
                          const Color(0xFFFFD27F),
                          Colors.white,
                        ),
                      const SizedBox(width: 16),
                      if (feed.getGradeText().isNotEmpty)
                        _buildCategoryTag(
                          feed.getGradeText(),
                          const Color(0xFFEFF2F6),
                          const Color(0xFF5D9EFF),
                        ),
                      const SizedBox(width: 16),
                      if (feed.getSubjectText().isNotEmpty)
                        _buildCategoryTag(
                          feed.getSubjectText(),
                          const Color(0xFFEFF2F6),
                          const Color(0xFF5D9EFF),
                        ),
                    ],
                  ),

                  // 모든 피드에 ... 메뉴 표시 (내 피드가 아닐 수도 있음)
                  if (feed.feedId != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 4), // 오른쪽 여백 추가
                      child: GestureDetector(
                        onTap: () => _checkAndShowOptions(context),
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: Image.asset(
                            'assets/icons/Icon/feed/세로점.png',
                            width: 20,
                            height: 20,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 6),

            // 프로필 정보 영역
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 프로필 이미지
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.grey[200],
                  backgroundImage:
                      feed.fullProfileImageUrl != null
                          ? NetworkImage(feed.fullProfileImageUrl!)
                          : null,
                  child:
                      feed.writerProfileImageUrl == null ||
                              feed.writerProfileImageUrl!.isEmpty
                          ? Text(
                            feed.writerName != null &&
                                    feed.writerName!.isNotEmpty
                                ? feed.writerName![0]
                                : '?',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                          : null,
                ),
                const SizedBox(width: 12),

                // 작성자 정보
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      feed.writerName ?? '작성자 없음',
                      style: const TextStyle(
                        color: Color(0xFF202020),
                        fontSize: 16,
                        fontFamily: 'Pretendard-Bold',
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.32,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          feed.getTimeAgo(),
                          style: const TextStyle(
                            color: Color(0xFF999999),
                            fontSize: 11,
                            fontFamily: 'Pretendard-Light',
                            fontWeight: FontWeight.w300,
                            letterSpacing: -0.22,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          width: 2,
                          height: 2,
                          decoration: const ShapeDecoration(
                            color: Color(0xFFC4C4C4),
                            shape: OvalBorder(),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '조회 ${feed.viewCount ?? 0}명',
                          style: const TextStyle(
                            color: Color(0xFF999999),
                            fontSize: 11,
                            fontFamily: 'Pretendard-Light',
                            fontWeight: FontWeight.w300,
                            letterSpacing: -0.22,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 14),

            // 피드 제목과 내용을 함께 감싸는 컨테이너
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 피드 제목
                Text(
                  feed.title ?? '',
                  style: const TextStyle(
                    color: Color(0xFF202020),
                    fontSize: 16,
                    fontFamily: 'Pretendard-Bold',
                    letterSpacing: -0.32,
                  ),
                ),

                const SizedBox(height: 8),

                // 피드 콘텐츠 (이미지 + 텍스트)
                if (feed.imageUrls.isNotEmpty)
                  // 이미지가 있는 경우 - 이미지와 텍스트 함께 표시
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 이미지
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          image: DecorationImage(
                            image: NetworkImage(feed.imageUrls.first),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // 텍스트 내용
                      Expanded(
                        child:
                            feed.content != null && feed.content!.isNotEmpty
                                ? Text(
                                  feed.content!,
                                  style: const TextStyle(
                                    color: Color(0xFF4A4A4A),
                                    fontSize: 12,
                                    fontFamily: 'Pretendard-Light',
                                    height: 1.5,
                                    letterSpacing: -0.24,
                                  ),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                )
                                : const SizedBox(),
                      ),
                    ],
                  )
                else
                  // 이미지가 없는 경우 - 텍스트만 표시
                  feed.content != null && feed.content!.isNotEmpty
                      ? Text(
                        feed.content!,
                        style: const TextStyle(
                          color: Color(0xFF4A4A4A),
                          fontSize: 12,
                          fontFamily: 'Pretendard-Light',
                          height: 1.5,
                          letterSpacing: -0.24,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      )
                      : const SizedBox(),
              ],
            ),

            const SizedBox(height: 14),

            // 하단 버튼 영역
            Row(
              children: [
                // 댓글 버튼
                GestureDetector(
                  onTap: () {
                    // 댓글 바텀시트 열기
                    if (feed.feedId != null) {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder:
                            (context) => FeedCommentBottomSheet(
                              feedId: feed.feedId!,
                              onCommentAdded: (comment) {
                                // 댓글이 추가되면 콜백 함수 호출
                                if (onCommentAdded != null &&
                                    feed.feedId != null) {
                                  onCommentAdded!(feed.feedId!, comment);
                                }
                              },
                              onCommentEdited: (commentId, content) {
                                // 댓글이 수정되면 콜백 함수 호출
                                if (onCommentEdited != null &&
                                    feed.feedId != null) {
                                  onCommentEdited!(
                                    feed.feedId!,
                                    commentId,
                                    content,
                                  );
                                }
                              },
                              onCommentDeleted: (commentId) {
                                // 댓글이 삭제되면 콜백 함수 호출
                                if (onCommentDeleted != null &&
                                    feed.feedId != null) {
                                  onCommentDeleted!(feed.feedId!, commentId);
                                }
                              },
                            ),
                      );
                    }
                  },
                  child: Container(
                    height: 24,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 0,
                    ),
                    margin: const EdgeInsets.only(right: 20),
                    decoration: ShapeDecoration(
                      shape: RoundedRectangleBorder(
                        side: const BorderSide(
                          width: 0.65,
                          color: Color(0xFFFFD27F),
                        ),
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          height: 14,
                          child: Image.asset(
                            'assets/icons/my/댓글.png',
                            width: 14,
                            height: 14,
                            color: const Color(0xFFFFA63D),
                          ),
                        ),
                        const SizedBox(width: 6),
                        SizedBox(
                          height: 14,
                          child: Text(
                            '${feed.commentCount ?? 0}',
                            style: const TextStyle(
                              color: Color(0xFFFFA63D),
                              fontSize: 12,
                              fontFamily: 'Pretendard-Medium',
                              fontWeight: FontWeight.w500,
                              height: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 좋아요 버튼
                GestureDetector(
                  onTap: () => onToggleLike(index),
                  child: Container(
                    height: 24,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 0,
                    ),
                    decoration: ShapeDecoration(
                      shape: RoundedRectangleBorder(
                        side: const BorderSide(
                          width: 0.65,
                          color: Color(0xFFFFD27F),
                        ),
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          height: 14,
                          child: Image.asset(
                            'assets/icons/my/좋아요.png',
                            width: 14,
                            height: 14,
                            color: const Color(0xFFFFA63D),
                          ),
                        ),
                        const SizedBox(width: 6),
                        SizedBox(
                          height: 14,
                          child: Text(
                            '${feed.likeCount ?? 0}',
                            style: const TextStyle(
                              color: Color(0xFFFFA63D),
                              fontSize: 12,
                              fontFamily: 'Pretendard-Medium',
                              fontWeight: FontWeight.w500,
                              height: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 내 피드인지 확인 후 메뉴 표시
  void _checkAndShowOptions(BuildContext context) async {
    if (feed.feedId == null) return;

    try {
      // 로딩 표시
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('확인 중...'),
          duration: Duration(seconds: 1),
          backgroundColor: Color(0xFF3A88F4),
        ),
      );

      // 이미 내 피드로 확인된 경우 바로 메뉴 표시
      if (feed.isMyFeed) {
        _showActionSheet(context, true);
        return;
      }

      // 내 피드 목록 조회 API 호출
      final myFeedsResult = await FeedService.getMyFeeds(page: 0, size: 50);
      if (myFeedsResult == null) {
        throw Exception('내 피드 목록을 불러올 수 없습니다.');
      }

      // 응답에서 내 피드 목록 추출
      final List<dynamic> myFeeds = myFeedsResult['content'] ?? [];

      // 현재 피드가 내 피드 목록에 있는지 확인
      bool isMyFeed = false;
      for (var myFeed in myFeeds) {
        if (myFeed['feedId'] == feed.feedId) {
          isMyFeed = true;
          break;
        }
      }

      // 내 피드 여부에 따라 다른 액션 시트 표시
      _showActionSheet(context, isMyFeed);
    } catch (e) {
      // 오류 처리
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류가 발생했습니다: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // 액션 시트 표시
  void _showActionSheet(BuildContext context, bool isMyFeed) {
    FeedActionSheet.show(
      context: context,
      isMyFeed: isMyFeed,
      onEdit: isMyFeed ? () => _handleMenuOption(context, 'edit') : null,
      onDelete: isMyFeed ? () => _handleMenuOption(context, 'delete') : null,
      onReport:
          !isMyFeed
              ? () async {
                // 신고 기능 구현
                await _reportFeed(context);
              }
              : null,
    );
  }

  // 피드 신고 기능 추가
  Future<void> _reportFeed(BuildContext context) async {
    try {
      print('피드 신고 시작: feedId=${feed.feedId}');

      // 신고 전 확인 다이얼로그 표시
      final bool confirmed =
          await showDialog(
            context: context,
            builder:
                (context) => AlertDialog(
                  title: Text('피드 신고'),
                  content: Text('이 피드를 신고하시겠습니까?\n신고 후에는 취소할 수 없습니다.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text('취소'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: Text('신고하기', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
          ) ??
          false;

      if (!confirmed) {
        print('사용자가 신고를 취소했습니다.');
        return;
      }

      // 로딩 인디케이터 표시
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => Center(
              child: CircularProgressIndicator(color: const Color(0xFF5D9EFF)),
            ),
      );

      print('피드 신고 API 호출 시작...');
      // 피드 신고 API 호출
      final result = await FeedService.reportFeed(feed.feedId!);
      print('피드 신고 API 호출 결과: $result');

      // 로딩 인디케이터 닫기
      Navigator.of(context).pop();

      if (result != null) {
        print('신고 성공');
        // 신고 성공 시 메시지 표시
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('신고가 접수되었습니다.'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        print('신고 실패: 결과가 null입니다.');
        // 신고 실패 시 메시지 표시
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('신고 접수에 실패했습니다. 다시 시도해주세요.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e, stackTrace) {
      print('피드 신고 중 예외 발생: $e');
      print('스택 트레이스: $stackTrace');

      // 로딩 인디케이터가 아직 표시되어 있는지 확인하고 닫기 (오류가 발생한 경우에도)
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      // 에러 처리
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('오류가 발생했습니다: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
    }
  }

  // 메뉴 옵션 처리
  void _handleMenuOption(BuildContext context, String value) async {
    if (feed.feedId == null) return;

    if (value == 'edit') {
      // 피드 수정 화면으로 이동
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => EditFeedScreen(
                feedId: feed.feedId!,
                title: feed.title,
                content: feed.content,
                gradeCategory: feed.gradeCategory ?? 'ALL',
                subjectCategory: feed.subjectCategory ?? 'ALL',
                tagCategory: feed.tagCategory ?? 'ALL',
                imageUrls: feed.imageUrls,
              ),
        ),
      );

      // 수정 결과에 따라 콜백 호출 (피드 목록 갱신)
      if (result == true && onFeedUpdated != null) {
        onFeedUpdated!(index);
      }
    } else if (value == 'delete') {
      // 삭제 확인 다이얼로그 표시
      final result = await showDialog<bool>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text(
                '피드 삭제',
                style: TextStyle(fontFamily: 'Pretendard-Bold', fontSize: 16),
              ),
              content: const Text(
                '정말 이 피드를 삭제하시겠습니까?',
                style: TextStyle(
                  fontFamily: 'Pretendard-Regular',
                  fontSize: 14,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text(
                    '취소',
                    style: TextStyle(
                      fontFamily: 'Pretendard-Regular',
                      color: Color(0xFF8590A3),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text(
                    '삭제',
                    style: TextStyle(
                      fontFamily: 'Pretendard-Bold',
                      color: Colors.red,
                    ),
                  ),
                ),
              ],
            ),
      );

      // 사용자가 삭제 확인을 했다면 삭제 API 호출
      if (result == true) {
        // 삭제 로직 구현
        final success = await FeedService.deleteFeed(feed.feedId!);

        if (success) {
          // 삭제 성공 시 콜백 호출
          if (onFeedDeleted != null) {
            onFeedDeleted!(index);
          }

          // 스낵바로 성공 메시지 표시
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('피드가 삭제되었습니다.'),
              backgroundColor: Color(0xFF3A88F4),
            ),
          );
        } else {
          // 실패 시 오류 메시지 표시
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('피드 삭제에 실패했습니다.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // 카테고리 태그 위젯
  Widget _buildCategoryTag(
    String text,
    Color backgroundColor,
    Color textColor,
  ) {
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.center,
      decoration: ShapeDecoration(
        color: backgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontFamily: 'Pretendard-Light',
          letterSpacing: -0.24,
          height: 1,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
