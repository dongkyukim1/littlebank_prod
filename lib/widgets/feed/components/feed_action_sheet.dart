import 'package:flutter/material.dart';

class FeedActionSheet extends StatelessWidget {
  final Function()? onEdit;
  final Function()? onDelete;
  final Function()? onReport;
  final bool isMyFeed; // 내 피드인지 여부

  const FeedActionSheet({
    super.key,
    this.onEdit,
    this.onDelete,
    this.onReport,
    this.isMyFeed = true, // 기본값은 내 피드
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      width: screenWidth,
      constraints: BoxConstraints(maxHeight: screenHeight * 0.8),
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Color(0x5B000000),
            blurRadius: 8,
            offset: Offset(0, -4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: screenWidth,
              padding: const EdgeInsets.all(16),
              decoration: ShapeDecoration(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isMyFeed ? '이 피드를 다시 고치거나 지울 수 있어요' : '이 피드를 신고하시겠습니까?',
                    style: TextStyle(
                      color: const Color(0xFF202020),
                      fontSize: 18,
                      fontFamily: 'Pretendard-Bold',
                      letterSpacing: -0.72,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    isMyFeed
                        ? '삭제하면 친구들의 피드에서 이 글을 볼 수 없어요.'
                        : '관리자에게 메일을 통해 신고하실 수 있으며, \n되돌릴 수 없습니다.',
                    style: TextStyle(
                      color: const Color(0xFF999999),
                      fontSize: 14,
                      fontFamily: 'Pretendard-Light',
                      fontWeight: FontWeight.w300,
                      letterSpacing: -0.28,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: screenWidth,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              decoration: BoxDecoration(color: Colors.white),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 8),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 내 피드인 경우에만 수정/삭제 버튼 표시
                      if (isMyFeed) ...[
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).pop();
                            if (onEdit != null) onEdit!();
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: ShapeDecoration(
                              color: const Color(0xFF5D9EFF),
                              shape: RoundedRectangleBorder(
                                side: BorderSide(
                                  width: 0.80,
                                  color: const Color(0xFF5D9EFF),
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '피드 수정하기',
                                style: TextStyle(
                                  color: const Color(0xFFEFF2F6),
                                  fontSize: 14,
                                  fontFamily: 'Pretendard-Light',
                                  letterSpacing: -0.28,
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 16),
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).pop();
                            if (onDelete != null) onDelete!();
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: ShapeDecoration(
                              color: const Color(0xFFF1F1F1),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '피드 삭제하기',
                                style: TextStyle(
                                  color: const Color(0xFFFF8383),
                                  fontSize: 14,
                                  fontFamily: 'Pretendard-Light',
                                  letterSpacing: -0.28, 
                                ),
                              ),
                            ),
                          ),
                        ),
                      ]
                      // 다른 사람의 피드인 경우 신고하기 버튼 표시
                      else ...[
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).pop();
                            if (onReport != null) onReport!();
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: ShapeDecoration(
                              color: const Color(0xFFF1F1F1),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '피드 신고하기',
                                style: TextStyle(
                                  color: const Color(0xFFFF8383),
                                  fontSize: 14,
                                  fontFamily: 'Pretendard-Light',
                                  letterSpacing: -0.28,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                      SizedBox(height: 24),
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: ShapeDecoration(
                            color: const Color(0xFFDADADA),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '취소하기',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontFamily: 'Pretendard-Light',
                                letterSpacing: -0.28,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 모달 바텀시트로 액션 시트를 표시합니다.
  static Future<void> show({
    required BuildContext context,
    Function()? onEdit,
    Function()? onDelete,
    Function()? onReport,
    bool isMyFeed = true, // 기본값은 내 피드
  }) async {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => FeedActionSheet(
            onEdit: onEdit,
            onDelete: onDelete,
            onReport: onReport,
            isMyFeed: isMyFeed,
          ),
    );
  }
}
