import 'package:flutter/material.dart';

class MissionRewardNotification extends StatefulWidget {
  final String message;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;

  const MissionRewardNotification({
    super.key,
    this.message = '이번 주 미션의 보상금을 받았어요!',
    this.onTap,
    this.onDismiss,
  });

  @override
  State<MissionRewardNotification> createState() => _MissionRewardNotificationState();
}

class _MissionRewardNotificationState extends State<MissionRewardNotification>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    // 애니메이션 시작
    _animationController.forward();

    // 5초 후 자동 숨김
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        _dismiss();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _dismiss() {
    _animationController.reverse().then((_) {
      if (widget.onDismiss != null) {
        widget.onDismiss!();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: ShapeDecoration(
          color: const Color(0xCC5D6A7F),
          shape: RoundedRectangleBorder(
            side: BorderSide(
              width: 1,
              color: const Color(0xFF146AFF),
            ),
            borderRadius: BorderRadius.circular(48),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 미션 보상 아이콘
            Container(
              width: 20,
              height: 20,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(),
              child: Image.asset(
                'assets/icons/notice/money.png',
                width: 20,
                height: 20,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Icon(
                      Icons.monetization_on,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            // 텍스트 영역 (확장 가능)
            Expanded(
              child: Text(
                widget.message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontFamily: 'Pretendard-Light',
                  fontWeight: FontWeight.w300,
                  letterSpacing: -0.24,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 12),
            // 확인하기 버튼 (고정 크기)
            GestureDetector(
              onTap: () {
                if (widget.onTap != null) {
                  widget.onTap!();
                }
                _dismiss();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: ShapeDecoration(
                  color: const Color(0xFF5D6A7F),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      '확인하기',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFFC4C4C4),
                        fontSize: 11,
                        fontFamily: 'Pretendard-Light',
                        fontWeight: FontWeight.w300,
                        letterSpacing: -0.18,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 14,
                      height: 14,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(),
                      child: Icon(
                        Icons.arrow_forward_ios,
                        size: 10,
                        color: const Color(0xFFC4C4C4),
                      ),
                    ),
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