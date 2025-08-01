import 'package:flutter/material.dart';
import '../my/bank/parent_bank_transfer_screen.dart';
import 'parent_challenge_score_modal.dart';

class ParentChallengeCompleteModal extends StatelessWidget {
  final Map<String, dynamic>? challenge;
  final String? childName;
  final Map<String, dynamic>? childInfo;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  const ParentChallengeCompleteModal({
    super.key,
    this.challenge,
    this.childName,
    this.childInfo,
    this.onConfirm,
    this.onCancel,
  });

  static Future<bool?> show(
    BuildContext context, {
    Map<String, dynamic>? challenge,
    String? childName,
    Map<String, dynamic>? childInfo,
  }) {
    // 챌린지가 이미 보상이 지급된 상태인지 확인
    if (challenge != null) {
      // 새 필드명과 기존 필드명 모두 지원
      final isRewarded =
          challenge['isRewarded'] ?? challenge['rewarded'] ?? false;
      print('🏆 챌린지 모달 표시 여부 확인:');
      print('   - participationId: ${challenge['participationId']}');
      print('   - isRewarded: ${challenge['isRewarded']}');
      print('   - rewarded: ${challenge['rewarded']}');
      print('   - finishScore: ${challenge['finishScore']}');

      if (isRewarded) {
        print(
          '🏆 이미 보상이 지급된 챌린지이므로 모달을 표시하지 않습니다: ${challenge['participationId']}',
        );
        // 이미 보상이 지급된 챌린지이므로 모달을 표시하지 않고 false 반환
        return Future.value(false);
      }
    }

    return showDialog<bool>(
      context: context,
      barrierDismissible: false, // 배경 터치로 닫기 방지
      builder: (BuildContext context) {
        return ParentChallengeCompleteModal(
          challenge: challenge,
          childName: childName,
          childInfo: childInfo,
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
                  '${displayChildName}님이 챌린지를 완료했어요! 🏆',
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
                  width: 24,
                  height: 24,
                  child: const Icon(
                    Icons.close,
                    size: 20,
                    color: Color(0xFF999999),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '챌린지 성과를 평가하고 보상을 전해주세요!',
            style: TextStyle(
              color: const Color(0xFF999999),
              fontSize: isTablet ? 13 : 11,
              fontFamily: 'Pretendard-Light',
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
    final imageMaxHeight = modalHeight * 0.48;
    final imageMaxWidth = modalWidth * 0.4;

    return Flexible(
      flex: 5,
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
                    Icons.emoji_events_outlined,
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
        onTap: () async {
          // 모달 닫기
          Navigator.of(context).pop(false);

          // 챌린지 점수 평가 화면으로 이동
          final result = await ParentChallengeScoreModal.show(
            context,
            challenge: challenge,
            childName: childName,
            childInfo: childInfo,
          );

          // 결과가 있으면 해당 결과를 반환
          if (result != null) {
            // 챌린지 평가 완료
          }
        },
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
              '점수 평가하러 가기',
              style: TextStyle(
                color: Colors.white,
                fontSize: isTablet ? 14 : 12,
                fontFamily: 'Pretendard-Medium',
                letterSpacing: -0.28,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
