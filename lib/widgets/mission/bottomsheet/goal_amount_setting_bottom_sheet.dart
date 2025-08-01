import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class GoalAmountSettingBottomSheet extends StatefulWidget {
  const GoalAmountSettingBottomSheet({super.key});

  @override
  State<GoalAmountSettingBottomSheet> createState() => _GoalAmountSettingBottomSheetState();
}

class _GoalAmountSettingBottomSheetState extends State<GoalAmountSettingBottomSheet> {
  final TextEditingController _amountController = TextEditingController();
  bool _isAmountValid = false;

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_validateAmount);
  }

  @override
  void dispose() {
    _amountController.removeListener(_validateAmount);
    _amountController.dispose();
    super.dispose();
  }

  void _validateAmount() {
    final text = _amountController.text.trim();
    final amount = int.tryParse(text);
    
    setState(() {
      _isAmountValid = amount != null && amount > 0;
    });
  }

  void _onFindFriends() {
    if (_isAmountValid) {
      final amount = int.parse(_amountController.text.trim());
      Navigator.of(context).pop(amount);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isTablet = screenWidth > 600;
    final isSmallScreen = screenWidth < 360;
    final maxWidth = isTablet ? 600.0 : screenWidth;
    
    // 반응형 패딩 계산
    final horizontalPadding = isTablet ? 24.0 : (isSmallScreen ? 12.0 : 16.0);
    final verticalPadding = isTablet ? 20.0 : 16.0;
    
    // 반응형 폰트 크기
    final titleFontSize = isTablet ? 18.0 : (isSmallScreen ? 16.0 : 18.0);
    final subtitleFontSize = isTablet ? 14.0 : (isSmallScreen ? 11.0 : 12.0);

    return Container(
      width: maxWidth,
      constraints: BoxConstraints(
        maxHeight: screenHeight * 0.7,
        minHeight: 200,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 헤더 섹션
          Container(
            width: maxWidth,
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: verticalPadding,
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
                // 제목과 닫기 버튼
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '목표 금액대를 알려주세요',
                        style: TextStyle(
                          color: const Color(0xFF202020),
                          fontSize: titleFontSize,
                          fontFamily: 'Pretendard-Bold',
                          letterSpacing: -0.72,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 24,
                        height: 24,
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.close,
                          size: 20,
                          color: Color(0xFF999999),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isSmallScreen ? 6 : 8),
                // 설명 텍스트
                Text(
                  '설정한 금액대에 따라 함께 경쟁할 친구를 찾아드릴게요',
                  style: TextStyle(
                    color: const Color(0xFF999999),
                    fontSize: subtitleFontSize,
                    fontFamily: 'Pretendard-Light',
                    letterSpacing: -0.28,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // 입력 필드 섹션
          Container(
            width: maxWidth,
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: isSmallScreen ? 8 : 12,
            ),
            color: Colors.white,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final fieldWidth = constraints.maxWidth;
                final inputFontSize = isTablet ? 14.0 : (isSmallScreen ? 12.0 : 14.0);
                final hintFontSize = isTablet ? 14.0 : (isSmallScreen ? 11.0 : 14.0);
                final borderRadius = isSmallScreen ? 12.0 : 16.0;
                
                return SizedBox(
                  width: fieldWidth,
                  height: isSmallScreen ? 48 : 52,
                  child: TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.left,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10), // 최대 10자리
                    ],
                    style: TextStyle(
                      color: const Color(0xFF202020),
                      fontSize: inputFontSize,
                      fontFamily: 'Pretendard-Regular',
                      letterSpacing: -0.28,
                    ),
                    decoration: InputDecoration(
                      hintText: '숫자만 입력해 주세요',
                      hintStyle: TextStyle(
                        color: const Color(0xFF999999),
                        fontSize: hintFontSize,
                        fontFamily: 'Pretendard-Light',
                        letterSpacing: -0.28,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 12 : 16,
                        vertical: isSmallScreen ? 12 : 14,
                      ),
                      suffixText: _amountController.text.isNotEmpty ? '원' : null,
                      suffixStyle: TextStyle(
                        color: const Color(0xFF666666),
                        fontSize: inputFontSize,
                        fontFamily: 'Pretendard-Regular',
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(borderRadius),
                        borderSide: BorderSide(
                          width: 0.8,
                          color: _amountController.text.isNotEmpty
                              ? const Color(0xFF146AFF)
                              : const Color(0xFFDADADA),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(borderRadius),
                        borderSide: const BorderSide(
                          width: 1.5,
                          color: Color(0xFF146AFF),
                        ),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(borderRadius),
                        borderSide: const BorderSide(
                          width: 0.8,
                          color: Color(0xFFDADADA),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // 버튼 섹션
          Container(
            width: maxWidth,
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: isSmallScreen ? 16 : 24,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isAmountValid ? _onFindFriends : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isAmountValid 
                        ? const Color(0xFF146AFF) 
                        : const Color(0xFFE0E0E0),
                    padding: EdgeInsets.symmetric(
                      vertical: isSmallScreen ? 12 : 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                    minimumSize: Size(double.infinity, isSmallScreen ? 44 : 48),
                  ),
                  child: Text(
                    '친구 찾으러 가기',
                    style: TextStyle(
                      color: _isAmountValid ? Colors.white : const Color(0xFF999999),
                      fontSize: isTablet ? 14 : (isSmallScreen ? 13 : 14),
                      fontFamily: 'Pretendard-Light',
                      letterSpacing: -0.28,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// 목표 금액대 설정 바텀 시트를 보여주는 함수
Future<int?> showGoalAmountSettingBottomSheet(BuildContext context) {
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const GoalAmountSettingBottomSheet(),
  );
} 