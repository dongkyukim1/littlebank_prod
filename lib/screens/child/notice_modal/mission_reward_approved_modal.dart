import 'package:flutter/material.dart';

class MissionRewardApprovedModal extends StatelessWidget {
  final VoidCallback? onConfirm; // 현재 디자인에는 버튼이 없으므로 사용되지 않을 수 있음
  final VoidCallback? onCancel;
  final String missionName;

  const MissionRewardApprovedModal({
    super.key,
    this.onConfirm,
    this.onCancel,
    this.missionName = "강아지 산책 담당", // 기본 미션 이름
  });

  static Future<bool?> show(BuildContext context, {String missionName = "강아지 산책 담당"}) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false, // 배경 터치로 닫기 방지
      builder: (BuildContext context) {
        return MissionRewardApprovedModal(
          missionName: missionName,
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

    final modalWidth = isTablet
        ? (screenWidth * 0.65).clamp(350.0, 450.0)
        : (screenWidth * 0.9).clamp(300.0, 380.0);
    // 내용에 따라 높이 자동 조절, 최대 높이 제한
    final modalMaxHeight = isTablet 
        ? (screenHeight * 0.6).clamp(380.0, 480.0)
        : (screenHeight * 0.55).clamp(350.0, 420.0);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 24,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: modalMaxHeight, 
        ),
        child: Container(
          width: modalWidth,
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
            mainAxisSize: MainAxisSize.min, // 내용에 맞게 높이 조절
            children: [
              _buildHeader(context, isTablet),
              _buildImageSection(context, modalWidth, modalMaxHeight * 0.7), // 이미지 영역 높이 비율 조정
              _buildBottomButton(context, isTablet), // 확인 버튼 추가
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isTablet) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 20, left: 20, right: 20, bottom: 12), // 하단 패딩 조정
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
                  '미션 보상금 전달이 완료되었어요!',
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
            '이번 주 $missionName 미션의 보상금이 도착했어요!', // 동적 미션 이름 적용
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

  Widget _buildImageSection(BuildContext context, double modalWidth, double imageSectionMaxHeight) {
    // 이미지 크기는 부모의 제약 내에서 최대한 크게
    return Flexible(
      child: GestureDetector(
        onTap: onConfirm, // 이미지를 탭했을 때 onConfirm (선택적)
        child: Container(
          width: double.infinity,
          // 이미지 컨테이너의 하단 라운딩을 위해 패딩 방식 변경
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 0), // 하단 패딩 제거
          decoration: const BoxDecoration(
             color: Colors.white,
             borderRadius: BorderRadius.only( // 이미지 컨테이너의 하단은 아직 둥글지 않음
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
             )
          ),
          child: ClipRRect( // 이미지가 부모의 둥근 모서리를 따르도록 ClipRRect 사용
            borderRadius: const BorderRadius.only(
                // bottomLeft: Radius.circular(24), // 이미지가 꽉 차지 않으면 필요 없음
                // bottomRight: Radius.circular(24),
            ),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10), // 실제 이미지 하단에 패딩 추가
              child: ConstrainedBox( // 이미지 크기를 명확히 제어하기 위해 ConstrainedBox 추가
                constraints: BoxConstraints(
                  maxHeight: imageSectionMaxHeight * 0.66, // 높이를 기존의 2/3 수준으로 설정
                  // maxWidth도 필요하다면 설정할 수 있습니다.
                  // maxWidth: modalWidth * 0.6, 
                ),
                child: Image.asset(
                  'assets/icons/notice/reward.png',
                  fit: BoxFit.contain, // 또는 BoxFit.cover 등 디자인에 맞게
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F2F7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.card_giftcard, // 보상 관련 아이콘
                        size: 80,
                        color: const Color(0xFF999999),
                      ),
                    );
                  },
                ),
              ),
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
              '미션 화면으로 가기',
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