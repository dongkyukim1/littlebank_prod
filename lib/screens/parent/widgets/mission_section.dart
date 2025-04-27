import 'package:flutter/material.dart';
import '../mission_creation_screen.dart';

class WeeklyGoalSection extends StatelessWidget {
  final Function showMissionCreationModal;

  const WeeklyGoalSection({super.key, required this.showMissionCreationModal});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: const Color(0x35000000),
            blurRadius: 8,
            offset: const Offset(3, 4),
            spreadRadius: 0,
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '이번 주 우리 아이의 목표',
                            style: TextStyle(
                              color: const Color(0xFF202020),
                              fontSize: 18,
                              fontFamily: 'Pretendard',
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.72,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '목표 달성을 위해 격려 메시지를 보내보세요',
                            style: TextStyle(
                              color: const Color(0xFF999999),
                              fontSize: 12,
                              fontFamily: 'Pretendard',
                              fontWeight: FontWeight.w300,
                              letterSpacing: -0.24,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 4), // 상단 여백 감소
                        GestureDetector(
                          onTap: () {
                            // 칭찬하기 기능
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            width: 80, // 너비 감소
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF2F6),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center( // 텍스트 중앙 정렬
                              child: Text(
                                '칭찬하기',
                                style: TextStyle(
                                  color: const Color(0xFF001F55),
                                  fontSize: 12,
                                  fontFamily: 'Pretendard',
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: -0.24,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: () {
                            showMissionCreationModal();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            width: 80, // 너비 감소
                            decoration: BoxDecoration(
                              color: const Color(0xFF10CB86),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center, // 중앙 정렬
                              children: [
                                Text(
                                  '미션 생성',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontFamily: 'Pretendard',
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: -0.24,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  '+',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontFamily: 'Pretendard',
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: const ShapeDecoration(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: ShapeDecoration(
                        color: const Color(0xFFFFD27F),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(
                        '습관 형성',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontFamily: 'Pretendard',
                          fontWeight: FontWeight.w300,
                          letterSpacing: -0.24,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '이번 주 저녁 설거지 담당',
                      style: TextStyle(
                        color: const Color(0xFF353535),
                        fontSize: 16,
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.32,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: Text(
                        '이번 주 저녁 먹고 바로 설거지를 시작하는 습관을 들여보...',
                        style: TextStyle(
                          color: const Color(0xFF666666),
                          fontSize: 14,
                          fontFamily: 'Pretendard',
                          fontWeight: FontWeight.w300,
                          letterSpacing: -0.28,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MissionCreationModal extends StatefulWidget {
  const MissionCreationModal({super.key});

  @override
  State<MissionCreationModal> createState() => _MissionCreationModalState();
}

class _MissionCreationModalState extends State<MissionCreationModal> {
  // 선택된 미션 타입을 추적하는 변수 (null은 아무것도 선택되지 않음)
  String? _selectedMissionType;
  // 현재 단계 추적 (0: 미션 유형 선택, 1: 대상자 선택)
  int _currentStep = 0;
  // 선택된 아이들의 이름을 저장하는 Set
  final Set<String> _selectedChildren = {};

  // 완료 버튼 클릭 시 다음 단계로 이동
  void _proceedToNextStep() {
    if (_selectedMissionType != null) {
      setState(() {
        _currentStep = 1;
      });
    } else {
      // 선택된 미션이 없는 경우 알림 표시
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('미션 유형을 선택해주세요')),
      );
    }
  }

  // 대상자 선택 화면에서 뒤로가기
  void _goBack() {
    setState(() {
      _currentStep = _currentStep - 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 화면 너비를 기준으로 비율 적용
    double screenWidth = MediaQuery.of(context).size.width;
    
    return Container(
      // 화면 너비 대비 높이 비율 유지 (346/390 비율)
      height: screenWidth * 0.88,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: _currentStep == 0
          ? _buildMissionTypeSelection(context)
          : _buildMissionTargetSelection(),
    );
  }

  // 미션 유형 선택 화면
  Widget _buildMissionTypeSelection(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 상단 제목 영역
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '어떤 미션을 만들어 볼까요? ',
                        style: TextStyle(
                          color: const Color(0xFF202020),
                          fontSize: 18,
                          fontFamily: 'Pretendard',
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.72,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Icon(
                        Icons.close,
                        color: Colors.grey,
                        size: 24,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '인원 수에 따라 미션 전송 유형을 선택할 수 있어요',
                  style: TextStyle(
                    color: const Color(0xFF999999),
                    fontSize: 13,
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w300,
                    letterSpacing: -0.28,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          
          // 미션 선택 영역
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 개인 미션 선택 버튼
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedMissionType = '개인';
                        });
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                        decoration: BoxDecoration(
                          color: _selectedMissionType == '개인' 
                                ? const Color(0xFFFFD27F) : const Color(0xFFF7F7F7),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            width: 0.70,
                            color: _selectedMissionType == '개인'
                                  ? const Color(0xFFFFA63D) : const Color(0xFFDADADA),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // 텍스트 영역
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '개인 미션',
                                    style: TextStyle(
                                      color: const Color(0xFF202020),
                                      fontSize: 15,
                                      fontFamily: 'Pretendard',
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.32,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    '상대와 나의 개인 채팅창을 통해 미션을 전송할 수 있어요!',
                                    style: TextStyle(
                                      color: const Color(0xFF666666),
                                      fontSize: 11,
                                      fontFamily: 'Pretendard',
                                      fontWeight: FontWeight.w300,
                                      letterSpacing: -0.24,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            
                            SizedBox(width: 8),
                            
                            // 선택 원형 아이콘
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: _selectedMissionType == '개인'
                                    ? const Color(0xFFFFD27F) : Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  width: 0.75,
                                  color: _selectedMissionType == '개인'
                                      ? const Color(0xFFFFA63D) : const Color(0xFFDADADA),
                                ),
                              ),
                              child: _selectedMissionType == '개인'
                                  ? Center(
                                      child: Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFFA63D),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    SizedBox(height: 12),
                    
                    // 그룹 미션 선택 버튼
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedMissionType = '그룹';
                        });
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                        decoration: BoxDecoration(
                          color: _selectedMissionType == '그룹' 
                                ? const Color(0xFFFFD27F) : const Color(0xFFF7F7F7),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            width: 0.70,
                            color: _selectedMissionType == '그룹'
                                  ? const Color(0xFFFFA63D) : const Color(0xFFDADADA),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // 텍스트 영역
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '그룹 미션',
                                    style: TextStyle(
                                      color: const Color(0xFF202020),
                                      fontSize: 15,
                                      fontFamily: 'Pretendard',
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.32,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    '여러 명에게 한 번에 빠르게 미션을 전송할 수 있어요!',
                                    style: TextStyle(
                                      color: const Color(0xFF999999),
                                      fontSize: 11,
                                      fontFamily: 'Pretendard',
                                      fontWeight: FontWeight.w300,
                                      letterSpacing: -0.24,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            
                            SizedBox(width: 8),
                            
                            // 선택 원형 아이콘
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: _selectedMissionType == '그룹'
                                    ? const Color(0xFFFFD27F) : Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  width: 0.75,
                                  color: _selectedMissionType == '그룹'
                                      ? const Color(0xFFFFA63D) : const Color(0xFFDADADA),
                                ),
                              ),
                              child: _selectedMissionType == '그룹'
                                  ? Center(
                                      child: Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFFA63D),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // 하단 버튼 영역 - 고정 위치
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // 다음에 하기 버튼
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      margin: EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDDDDDD),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '다음에 하기',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontFamily: 'Pretendard',
                            fontWeight: FontWeight.w300,
                            letterSpacing: -0.28,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                
                // 완료 버튼
                Expanded(
                  child: GestureDetector(
                    onTap: _proceedToNextStep,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF5D9EFF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '완료',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontFamily: 'Pretendard',
                            fontWeight: FontWeight.w300,
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
        ],
      ),
    );
  }

  // 대상자 선택 화면
  Widget _buildMissionTargetSelection() {
    return SizedBox(
      width: double.infinity,
      // 스크롤 가능한 레이아웃으로 변경
      child: SingleChildScrollView(
        physics: ClampingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 상단 제목 영역
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              width: double.infinity,
              decoration: ShapeDecoration(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '누구에게 미션을 전송할까요?',
                        style: TextStyle(
                          color: const Color(0xFF202020),
                          fontSize: 17, // 텍스트 크기 키움
                          fontFamily: 'Pretendard',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4), // 간격 키움
                      Text(
                        '가족 멤버로 추가된 아이들이예요',
                        style: TextStyle(
                          color: const Color(0xFF999999),
                          fontSize: 12, // 텍스트 크기 키움
                          fontFamily: 'Pretendard',
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: _goBack,
                    child: Icon(
                      Icons.close,
                      color: Colors.grey,
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),

            // 프로필 영역
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16), // 패딩 키움
              child: Row(
                children: [
                  _buildChildProfile('강뱅뱅', _selectedChildren.contains('강뱅뱅')),
                  const SizedBox(width: 24), // 간격 키움
                  _buildChildProfile('강리뱅', _selectedChildren.contains('강리뱅')),
                ],
              ),
            ),

            // 하단 버튼 영역 - 간격 키움
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20), // 패딩 키움
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        margin: EdgeInsets.only(right: 10), // 간격 키움
                        padding: const EdgeInsets.symmetric(vertical: 12), // 패딩 키움
                        decoration: BoxDecoration(
                          color: const Color(0xFFDDDDDD),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            '다음에 하기',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13, // 폰트 크기 키움
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        if (_selectedChildren.isNotEmpty) {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MissionCreationScreen(
                                selectedChildren: _selectedChildren.toList(),
                                missionType: _selectedMissionType ?? '개인',
                              ),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('미션 대상자를 선택해주세요')),
                          );
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12), // 패딩 키움
                        decoration: BoxDecoration(
                          color: const Color(0xFF5D9EFF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            '완료',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13, // 폰트 크기 키움
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // 추가 여백으로 안전하게 처리
            SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  // 자녀 프로필 위젯 - 크기 여유롭게 조정
  Widget _buildChildProfile(String name, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          if (_selectedChildren.contains(name)) {
            _selectedChildren.remove(name);
          } else {
            _selectedChildren.add(name);
          }
        });
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 프로필 이미지
          Container(
            width: 54, // 
            height: 54, // 
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 2,
                  offset: Offset(0, 1),
                ),
              ],
              image: DecorationImage(
                image: AssetImage('assets/images/kid.png'),
                fit: BoxFit.cover,
              ),
            ),
            child: isSelected ? 
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Container(
                    width: 20, // 체크표시 크기 키움
                    height: 20, // 체크표시 크기 키움
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 14, // 아이콘 크기 키움
                    ),
                  ),
                ),
              ) : null,
          ),
          
          // 간격
          const SizedBox(height: 6), // 간격 키움
          
          // 이름
          Text(
            name,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black,
              fontSize: 12, // 폰트 크기 키움
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
} 