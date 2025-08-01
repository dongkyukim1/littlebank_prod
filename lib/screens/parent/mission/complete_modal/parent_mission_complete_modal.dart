import 'package:flutter/material.dart';

class ParentMissionCompleteModal extends StatelessWidget {
  final Map<String, dynamic>? mission;
  final String? childName;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  const ParentMissionCompleteModal({
    super.key,
    this.mission,
    this.childName,
    this.onConfirm,
    this.onCancel,
  });

  static Future<bool?> show(
    BuildContext context, {
    Map<String, dynamic>? mission,
    String? childName,
  }) {
    // 미션이 이미 보상이 지급된 상태인지 확인
    if (mission != null) {
      // 새 필드명과 기존 필드명 모두 지원
      final isRewarded = mission['isRewarded'] ?? mission['rewarded'] ?? false;
      print('🎯 모달 표시 여부 확인:');
      print('   - missionId: ${mission['missionId']}');
      print('   - isRewarded: ${mission['isRewarded']}');
      print('   - rewarded: ${mission['rewarded']}');
      print('   - 최종 isRewarded: $isRewarded');

      if (isRewarded) {
        print('🎯 이미 보상이 지급된 미션이므로 모달을 표시하지 않습니다: ${mission['missionId']}');
        // 이미 보상이 지급된 미션이므로 모달을 표시하지 않고 false 반환
        return Future.value(false);
      }
    }

    return showDialog<bool>(
      context: context,
      barrierDismissible: false, // 배경 터치로 닫기 방지
      builder: (BuildContext context) {
        return ParentMissionCompleteModal(
          mission: mission,
          childName: childName,
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

    final modalWidth =
        isTablet
            ? (screenWidth * 0.65).clamp(350.0, 450.0)
            : (screenWidth * 0.9).clamp(300.0, 380.0);
    // 다른 모달들과 유사한 높이 비율 사용
    final modalHeight =
        isTablet
            ? (screenHeight * 0.52).clamp(340.0, 430.0)
            : (screenHeight * 0.48).clamp(320.0, 380.0);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
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
            _buildHeader(context, isTablet),
            _buildImageSection(context, modalWidth, modalHeight),
            _buildBottomButton(context, isTablet),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isTablet) {
    final displayChildName = childName ?? '자녀';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 20, left: 20, right: 20, bottom: 10),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  '${displayChildName}님이 미션을 완료했어요! 🎉',
                  style: TextStyle(
                    color: const Color(0xFF202020),
                    fontSize: isTablet ? 18 : 16, // 폰트 크기 조정
                    fontFamily:
                        'Pretendard-Bold', // fontWeight: FontWeight.w700
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
                  width: 24,
                  height: 24,
                  child: Image.asset(
                    'assets/icons/my/close.png',
                    width: 20,
                    height: 20,
                    fit: BoxFit.contain,
                    errorBuilder:
                        (context, error, stackTrace) => const Icon(
                          Icons.close,
                          size: 20,
                          color: Color(0xFF999999),
                        ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '활동을 평가하고 보상을 전해주세요!',
            style: TextStyle(
              color: const Color(0xFF999999),
              fontSize: isTablet ? 13 : 11, // 폰트 크기 조정
              fontFamily: 'Pretendard-Light', // fontWeight: FontWeight.w300
              letterSpacing: -0.28,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildImageSection(
    BuildContext context,
    double modalWidth,
    double modalHeight,
  ) {
    // 이미지 크기 동적 조절 (세로로 긴 이미지를 고려)
    final imageMaxHeight = modalHeight * 0.48;
    final imageMaxWidth = modalWidth * 0.4; // 너비는 다른 모달 이미지보다 약간 좁게

    return Flexible(
      flex: 5, // 이미지 영역이 더 많은 공간을 차지하도록 flex값 유지 또는 증가
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        color: Colors.white,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: imageMaxWidth,
              maxHeight: imageMaxHeight,
            ),
            child: Image.asset(
              'assets/icons/notice/complete.png',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F2F7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.check_circle_outline, // 완료 관련 아이콘
                    size: 60,
                    color: const Color(0xFF999999),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomButton(BuildContext context, bool isTablet) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20, top: 15),
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
          height: isTablet ? 52 : 48,
          decoration: ShapeDecoration(
            color: const Color(0xFF146AFF),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            shadows: [
              BoxShadow(
                color: const Color(0xFF146AFF).withOpacity(0.3),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              '활동 평가하러 가기',
              style: TextStyle(
                color: Colors.white,
                fontSize: isTablet ? 14 : 12, // 폰트 크기 조정
                fontFamily: 'Pretendard-Medium', // fontWeight: FontWeight.w500
                letterSpacing: -0.28,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
