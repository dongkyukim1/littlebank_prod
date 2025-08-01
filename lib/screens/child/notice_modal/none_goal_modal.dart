import 'package:flutter/material.dart';

class NoneGoalModal extends StatelessWidget {
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  const NoneGoalModal({
    super.key,
    this.onConfirm,
    this.onCancel,
  });

  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false, // 배경 터치로 닫기 방지
      builder: (BuildContext context) {
        return NoneGoalModal(
          onConfirm: () => Navigator.of(context).pop(true),
          onCancel: () => Navigator.of(context).pop(false),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isTablet = screenWidth > 600;
    
    // 화면 크기에 맞춘 모달 크기 계산 (더 안전한 크기)
    final modalWidth = isTablet 
        ? (screenWidth * 0.65).clamp(300.0, 400.0) 
        : (screenWidth * 0.85).clamp(280.0, 350.0);
    final modalHeight = isTablet 
        ? (screenHeight * 0.5).clamp(280.0, 380.0) 
        : (screenHeight * 0.45).clamp(250.0, 320.0);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 50,
      ),
      child: Container(
        width: modalWidth,
        height: modalHeight,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 상단 헤더
            Container(
              width: double.infinity,
              padding: EdgeInsets.only(
                left: 16, 
                right: 16,
                top: 12,
                bottom: 6, // 헤더 하단 패딩 축소
              ),
              decoration: const ShapeDecoration(
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '아직 목표를 설정하지 않으셨어요!',
                          style: TextStyle(
                            color: const Color(0xFF202020),
                            fontSize: isTablet ? 18 : 16,
                            fontFamily: 'Pretendard-Bold',
                            letterSpacing: -0.72,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: onCancel,
                        child: Container(
                          width: 20,
                          height: 20,
                          child: const Icon(
                            Icons.close,
                            size: 18,
                            color: Color(0xFF999999),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '매주 월요일마다 새로운 목표를 설정해 봐요',
                    style: TextStyle(
                      color: const Color(0xFF999999),
                      fontSize: isTablet ? 14 : 12,
                      fontFamily: 'Pretendard-Light',
                      letterSpacing: -0.28,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            
            // 이미지 영역 (Flexible로 감싸서 오버플로우 방지)
            Flexible(
              flex: 3,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12), // 이미지 영역 상하 패딩 최소화
                decoration: const BoxDecoration(color: Colors.white),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: modalWidth * 0.9,
                      maxHeight: modalHeight * 0.55,
                    ),
                    child: Image.asset(
                      'assets/icons/notice/none_goal.png',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F2F7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.flag_outlined,
                            size: 60,
                            color: const Color(0xFF999999),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            
            // 하단 버튼 영역
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(
                left: 16, 
                right: 16, 
                bottom: 16, 
                top: 8, // 버튼 상단 패딩 축소
              ),
              decoration: const ShapeDecoration(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
              ),
              child: GestureDetector(
                onTap: onConfirm,
                child: Container(
                  width: double.infinity,
                  height: 48,
                  decoration: ShapeDecoration(
                    color: const Color(0xFF146AFF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '목표 세우러 가기',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isTablet ? 15 : 14,
                        fontFamily: 'Pretendard-Medium',
                        letterSpacing: -0.28,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 