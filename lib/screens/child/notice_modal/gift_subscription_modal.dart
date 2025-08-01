import 'package:flutter/material.dart';

class GiftSubscriptionModal extends StatelessWidget {
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  const GiftSubscriptionModal({
    super.key,
    this.onConfirm,
    this.onCancel,
  });

  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false, // 배경 터치로 닫기 방지
      builder: (BuildContext context) {
        return GiftSubscriptionModal(
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

    // 화면 크기에 맞춘 모달 크기 계산
    final modalWidth = isTablet
        ? (screenWidth * 0.65).clamp(350.0, 450.0) 
        : (screenWidth * 0.9).clamp(300.0, 380.0);
    // NoneGoalModal과 유사한 비율로 modalHeight 정의
    final modalHeight = isTablet 
        ? (screenHeight * 0.52).clamp(330.0, 420.0) // 기존 modalMinHeight 대신 modalHeight 사용
        : (screenHeight * 0.48).clamp(310.0, 370.0);


    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 24, // 상하 여백 조정
      ),
      child: Container(
        width: modalWidth,
        height: modalHeight, // 모달 전체 높이 적용
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
            // 상단 헤더
            _buildHeader(context, isTablet),
            // 이미지 영역
            _buildImageSection(context, modalWidth, modalHeight), // modalMinHeight 대신 modalHeight 전달
            // 하단 버튼 영역
            _buildBottomButton(context, isTablet),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isTablet) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 20, left: 20, right: 20, bottom: 10),
      decoration: const ShapeDecoration(
        color: Colors.white, // 배경색은 이미 Dialog Container에 설정됨
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
                  '구독권 선물이 도착했어요!',
                  style: TextStyle(
                    color: const Color(0xFF202020),
                    fontSize: isTablet ? 20 : 18,
                    fontFamily: 'Pretendard-Bold', // fontWeight: FontWeight.w700
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
                  width: 24, // 아이콘 크기 약간 키움
                  height: 24,
                  child: const Icon(
                    Icons.close,
                    size: 20, // 아이콘 사이즈 명시
                    color: Color(0xFF999999),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '선물받은 구독권을 등록하고 바로 시작해 보세요',
            style: TextStyle(
              color: const Color(0xFF999999),
              fontSize: isTablet ? 14 : 13,
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

  Widget _buildImageSection(BuildContext context, double modalWidth, double modalHeight) {
    // 이미지 크기 동적 조절
    final imageMaxHeight = modalHeight * 0.42; // modalHeight 기준으로 비율 재조정
    final imageMaxWidth = modalWidth * 0.75; // 너비 비율도 약간 조정


    return Flexible( 
      flex: 2, // flex 값 추가 (NoneGoalModal은 3, 여기선 2 또는 2.5 시도)
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        color: Colors.white, // 배경색 통일
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: imageMaxWidth,
              maxHeight: imageMaxHeight,
            ),
            child: Image.asset(
              'assets/icons/notice/gift_subs.png',
              fit: BoxFit.contain, // 원본 비율 유지하며 채우기
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F2F7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.card_giftcard, // 선물 관련 아이콘
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
      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20, top: 10),
      decoration: const ShapeDecoration(
        color: Colors.white, // 배경색은 이미 Dialog Container에 설정됨
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
          width: double.infinity, // 버튼 너비 최대화
          height: isTablet ? 52 : 48,
          decoration: ShapeDecoration(
            color: const Color(0xFF146AFF),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            shadows: [ // 버튼에 약간의 입체감 추가 (선택 사항)
              BoxShadow(
                color: const Color(0xFF146AFF).withOpacity(0.3),
                blurRadius: 5,
                offset: const Offset(0, 2),
              )
            ]
          ),
          child: Center(
            child: Text(
              '구독권 등록하기',
              style: TextStyle(
                color: Colors.white,
                fontSize: isTablet ? 15 : 13,
                fontFamily: 'Pretendard-Light', 
                letterSpacing: -0.28,
              ),
            ),
          ),
        ),
      ),
    );
  }
} 