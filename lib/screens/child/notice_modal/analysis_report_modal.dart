import 'package:flutter/material.dart';

class AnalysisReportModal extends StatelessWidget {
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final String userName; // 사용자 이름을 받도록 추가

  const AnalysisReportModal({
    super.key,
    this.onConfirm,
    this.onCancel,
    this.userName = "김리틀", // 기본값 설정
  });

  static Future<bool?> show(BuildContext context, {String userName = "김리틀"}) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false, // 배경 터치로 닫기 방지
      builder: (BuildContext context) {
        return AnalysisReportModal(
          userName: userName,
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
    final modalHeight = isTablet
        ? (screenHeight * 0.52).clamp(340.0, 430.0) 
        : (screenHeight * 0.48).clamp(320.0, 380.0);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 24,
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
            _buildHeader(context, isTablet),
            _buildImageSection(context, modalWidth, modalHeight),
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
                  '분석 리포트가 업데이트 되었어요!',
                  style: TextStyle(
                    color: const Color(0xFF202020),
                    fontSize: isTablet ? 18 : 16,
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
          const SizedBox(height: 6), // 디자인 명세에는 spacing: 8 이나, 다른 모달과 통일성을 위해 6 또는 4로 조정 가능
          Text(
            '$userName님의 분석 리포트가 업데이트 되는 날이예요',
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

  Widget _buildImageSection(BuildContext context, double modalWidth, double modalHeight) {
    final imageMaxHeight = modalHeight * 0.45; 
    final imageMaxWidth = modalWidth * 0.5; // 이미지가 세로로 길기 때문에 너비를 줄임

    return Flexible(
      flex: 5, // 이미지 영역이 더 많은 공간을 차지하도록 flex값 증가
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
              'assets/icons/notice/upload_report.png',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F2F7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.assessment_outlined, // 분석 관련 아이콘
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
      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20, top: 15), // 버튼과 이미지 간격 확보
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
              )
            ],
          ),
          child: Center(
            child: Text(
              '분석 리포트 보러가기',
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