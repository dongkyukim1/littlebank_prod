import 'package:flutter/material.dart';
import 'dart:math' as math;

class BalanceGameCard extends StatefulWidget {
  final Map<String, dynamic> gameData;
  final String choiceType;
  final Function(int gameId, String choice) onVote;
  final bool autoFlip;

  const BalanceGameCard({
    super.key,
    required this.gameData,
    required this.choiceType,
    required this.onVote,
    this.autoFlip = false,
  });

  @override
  State<BalanceGameCard> createState() => _BalanceGameCardState();
}

class _BalanceGameCardState extends State<BalanceGameCard> {
  double _angle = 0;
  bool _hasAutoFlipped = false;

  @override
  void initState() {
    super.initState();
    // 초기화: 투표 완료된 게임은 뒷면, 아니면 앞면에서 시작
    final voted = widget.gameData['voted'] ?? false;
    if (voted) {
      _angle = math.pi; // 투표 완료면 뒷면
      _hasAutoFlipped = true;
    } else {
      _angle = 0; // 투표 안했으면 앞면에서 시작
      _hasAutoFlipped = false;
      // autoFlip은 didUpdateWidget에서만 처리 (영역 진입 시에만)
    }
  }

    @override
  void didUpdateWidget(BalanceGameCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // autoFlip 상태가 false에서 true로 변경되었을 때
    if (!oldWidget.autoFlip && widget.autoFlip && !_hasAutoFlipped) {
      print('🎮 autoFlip 활성화됨 - 자동 뒤집기 시작!');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startAutoFlip();
      });
    }
    
    // 게임 데이터가 변경되었을 때
    if (widget.gameData != oldWidget.gameData) {
      final voted = widget.gameData['voted'] ?? false;
      
      if (voted) {
        // 투표 완료된 새 게임이면 뒷면
        setState(() {
          _angle = math.pi;
          _hasAutoFlipped = true;
        });
      } else {
        // 새로운 투표 안한 게임이면 앞면으로 리셋
        setState(() {
          _angle = 0;
          _hasAutoFlipped = false;
        });
        
        // autoFlip이 활성화되어 있으면 새로운 게임에 대해 자동 뒤집기 시작
        if (widget.autoFlip) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _startAutoFlip();
          });
        }
      }
    }
  }

  // 외부에서 호출할 수 있는 자동 뒤집기 시작 메서드
  void startAutoFlip() {
    _startAutoFlip();
  }

  void _startAutoFlip() {
    if (_hasAutoFlipped) return; // 이미 뒤집혔으면 중단
    
    final voted = widget.gameData['voted'] ?? false;
    if (voted) return; // 투표 완료된 게임은 자동 뒤집기 안함
    
    print('🎮 밸런스게임 영역 진입 - 자동 뒤집기 시작: ${widget.choiceType}');
    
    // A는 1초, B는 1.2초 후 뒤집기 (순차적으로 멋있게!)
    final delay = widget.choiceType == 'A' ? 1000 : 1200;
    
    Future.delayed(Duration(milliseconds: delay), () {
      if (mounted && !_hasAutoFlipped && _angle == 0) {
        print('🔄 자동 카드 뒤집기 실행: ${widget.choiceType} (${delay}ms 후)');
        setState(() {
          _angle = math.pi;
          _hasAutoFlipped = true;
        });
      }
    });
  }

  void _flipCard() {
    final voted = widget.gameData['voted'] ?? false;
    if (!voted && _angle == 0) {
      setState(() {
        _angle = math.pi;
        _hasAutoFlipped = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final String optionText = widget.choiceType == 'A' 
        ? widget.gameData['optionA'] 
        : widget.gameData['optionB'];
    final int voteCount = widget.choiceType == 'A' 
        ? widget.gameData['voteCountA'] 
        : widget.gameData['voteCountB'];
    final double percentage = widget.choiceType == 'A' 
        ? widget.gameData['percentageA'] 
        : widget.gameData['percentageB'];
    final bool voted = widget.gameData['voted'] ?? false;
    final String? myChoice = widget.gameData['myChoice'];
    final bool isMyChoice = voted && myChoice == widget.choiceType;

    // 반응형 크기 계산
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final cardWidth = isTablet ? 200.0 : (screenWidth - 64) / 2;
    final cardHeight = isTablet ? 300.0 : cardWidth * 1.53;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 카드 애니메이션
        GestureDetector(
          onTap: _flipCard,
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: _angle),
            duration: Duration(milliseconds: 800),
            builder: (context, value, child) {
              final isBack = value >= (math.pi / 2);
              return Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateY(value),
                child: Container(
                  width: cardWidth,
                  height: cardHeight,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: isMyChoice 
                        ? Border.all(color: Color(0xFF146AFF), width: 3) 
                        : null,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: isBack 
                        ? Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.identity()..rotateY(math.pi),
                            child: _buildCardBack(
                              optionText, 
                              voted, 
                              percentage, 
                              cardWidth, 
                              cardHeight,
                              isTablet,
                            ),
                          )
                        : _buildCardFront(cardWidth, cardHeight, isTablet),
                  ),
                ),
              );
            },
          ),
        ),
        
        SizedBox(height: isTablet ? 20 : 16),
        
        // 퍼센티지 배지 (투표 완료 시에만 표시)
        if (voted) _buildPercentageBadge(percentage, isMyChoice, cardWidth, isTablet),
        
        SizedBox(height: isTablet ? 20 : 16),
        
        // 하단 버튼
        _buildBottomButton(
          voted, 
          _angle >= (math.pi / 2), 
          isMyChoice, 
          cardWidth, 
          isTablet,
        ),
      ],
    );
  }

  // 카드 앞면
  Widget _buildCardFront(double cardWidth, double cardHeight, bool isTablet) {
    return Container(
      width: cardWidth,
      height: cardHeight,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/icons/Icon/home/card_front.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withOpacity(0.3),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.help_outline,
                color: Colors.white,
                size: isTablet ? 38 : 28,
              ),
              SizedBox(height: isTablet ? 12 : 8),
              Text(
                '터치해서 확인',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isTablet ? 16 : 12,
                  fontFamily: 'Pretendard-Bold',
                  letterSpacing: -0.28,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 카드 뒷면
  Widget _buildCardBack(
    String optionText, 
    bool voted, 
    double percentage, 
    double cardWidth, 
    double cardHeight,
    bool isTablet,
  ) {
    return Container(
      width: cardWidth,
      height: cardHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF146AFF), // RGB(20, 106, 255)
            Color(0xFF146AFF).withOpacity(0.8),
            Color(0xFF146AFF).withOpacity(0.9),
          ],
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 12 : 8),
        child: Column(
          children: [
            // 상단 여는 따옴표 - 더 가까이 배치
            Align(
              alignment: Alignment.topLeft,
              child: Transform.translate(
                                  offset: Offset(isTablet ? 30 : 20, isTablet ? 55 : 50),
                child: Text(
                  '"',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isTablet ? 32 : 24,
                    fontFamily: 'Pretendard-Bold',
                    height: 0.8,
                  ),
                ),
              ),
            ),
            
            // 중앙 텍스트 영역
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 텍스트를 두 줄로 분리하여 처리
                    _buildTextWithLines(optionText, cardWidth, isTablet),
                  ],
                ),
              ),
            ),
            
            // 하단 닫는 따옴표 - 더 가까이 배치
            Align(
              alignment: Alignment.bottomRight,
              child: Transform.translate(
                                  offset: Offset(isTablet ? -30 : -20, isTablet ? -45 : -40),
                child: Text(
                  '"',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isTablet ? 32 : 24,
                    fontFamily: 'Pretendard-Bold',
                    height: 0.8,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 퍼센티지 배지
  Widget _buildPercentageBadge(double percentage, bool isMyChoice, double cardWidth, bool isTablet) {
    final bgColor = percentage > 50 ? Color(0xFFFFD27F) : Color(0xFFDCDCDC);
    final badgeWidth = cardWidth * 0.85;
    
    return Container(
      width: badgeWidth,
      constraints: BoxConstraints(minWidth: 120, maxWidth: 180),
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 16 : 8,
        vertical: isTablet ? 10 : 8,
      ),
      decoration: ShapeDecoration(
        color: bgColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '${percentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: const Color(0xFF001F55),
                      fontSize: isTablet ? 12 : 9,
                      fontFamily: 'Pretendard-Bold',
                      letterSpacing: -0.28,
                    ),
                  ),
                  TextSpan(
                    text: '의 리틀인이 선택!',
                    style: TextStyle(
                      color: const Color(0xFF001F55),
                      fontSize: isTablet ? 12 : 9,
                      fontFamily: 'Pretendard-Light',
                      letterSpacing: -0.28,
                    ),
                  ),
                ],
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  // 하단 버튼
  Widget _buildBottomButton(bool voted, bool isFlipped, bool isMyChoice, double cardWidth, bool isTablet) {
    if (voted) {
      // 투표 완료 상태 - 결과 표시
      return Container(
        width: cardWidth,
        padding: EdgeInsets.all(isTablet ? 18 : 16),
        decoration: ShapeDecoration(
          color: isMyChoice ? Color(0xFF146AFF) : Color(0xFFC4C4C4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isMyChoice ? '선택완료' : '선택하기',
              style: TextStyle(
                color: Colors.white,
                fontSize: isTablet ? 16 : 12,
                fontFamily: 'Pretendard-Light',
                letterSpacing: -0.28,
              ),
            ),
          ],
        ),
      );
    } else if (isFlipped || _angle >= (math.pi / 2)) {
      // 투표하지 않았지만 카드가 뒤집힌 상태 - 선택하기 버튼
      return GestureDetector(
        onTap: () {
          print('🗳️ 투표 실행: ${widget.choiceType}');
          widget.onVote(widget.gameData['gameId'], widget.choiceType);
        },
        child: Container(
          width: cardWidth,
          padding: EdgeInsets.all(isTablet ? 18 : 16),
          decoration: ShapeDecoration(
            color: const Color(0xFF5D9EFF),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '선택하기',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isTablet ? 16 : 13,
                  fontFamily: 'Pretendard-Medium',
                  letterSpacing: -0.28,
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      // 아직 뒤집히지 않은 상태 - 터치 안내
      return Container(
        width: cardWidth,
        padding: EdgeInsets.all(isTablet ? 18 : 16),
        decoration: ShapeDecoration(
          color: Colors.grey[300],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                '카드를 터치해주세요',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: isTablet ? 14 : 11,
                  fontFamily: 'Pretendard-Light',
                  letterSpacing: -0.28,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      );
    }
  }

  // 텍스트를 두 줄로 분리하여 처리하는 함수
  Widget _buildTextWithLines(String text, double cardWidth, bool isTablet) {
    // 텍스트를 단어 단위로 분리
    final words = text.split(' ');
    final firstLine = words.take((words.length / 2).ceil()).join(' ');
    final secondLine = words.skip((words.length / 2).ceil()).join(' ');
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 첫 번째 줄
        Text(
          firstLine,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white,
            fontSize: isTablet ? 16 : 14,
            fontFamily: 'Pretendard-Medium',
            height: 1.4,
            letterSpacing: -0.32,
          ),
        ),
        
        // 첫 번째 가로줄
        SizedBox(height: isTablet ? 8 : 6),
        Container(
          width: cardWidth * 0.7,
          height: 1.5,
          color: Colors.white,
        ),
        
        SizedBox(height: isTablet ? 12 : 10),
        
        // 두 번째 줄 (있을 경우만)
        if (secondLine.isNotEmpty) ...[
          Text(
            secondLine,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white,
              fontSize: isTablet ? 16 : 14,
              fontFamily: 'Pretendard-Medium',
              height: 1.4,
              letterSpacing: -0.32,
            ),
          ),
          
          // 두 번째 가로줄
          SizedBox(height: isTablet ? 8 : 6),
          Container(
            width: cardWidth * 0.5,
            height: 1.5,
            color: Colors.white,
          ),
        ],
      ],
    );
  }
} 