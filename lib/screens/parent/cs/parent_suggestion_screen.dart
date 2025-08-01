import 'package:flutter/material.dart';
import '../../../widgets/parent/bottom_navigation_bar.dart';

class ParentSuggestionScreen extends StatefulWidget {
  const ParentSuggestionScreen({super.key});

  @override
  State<ParentSuggestionScreen> createState() => _ParentSuggestionScreenState();
}

class _ParentSuggestionScreenState extends State<ParentSuggestionScreen> {
  // 선택된 의견 유형
  String? _selectedType;
  
  // 텍스트 컨트롤러
  final TextEditingController _contentController = TextEditingController();
  
  // 의견 유형 목록
  final List<String> _suggestionTypes = [
    '기존 서비스 개선',
    '신규 서비스 제안',
    '서비스 관련 불편사항',
    '기타'
  ];

  // 하단 시트를 표시하는 메소드
  void _showTypeSelectionBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.only(bottom: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 상단 헤더
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: const ShapeDecoration(
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
                  children: [
                    Text(
                      '의견 유형을 선택해 주세요',
                      style: TextStyle(
                        color: const Color(0xFF202020),
                        fontSize: 18,
                        fontFamily: 'Pretendard-Bold',
                        letterSpacing: -0.72,
                      ),
                    ),
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      child: Icon(
                        Icons.close,
                        color: const Color(0xFF666666),
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),
              
              // 옵션 목록
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(color: Colors.white),
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: _suggestionTypes.length,
                  itemBuilder: (context, index) {
                    final type = _suggestionTypes[index];
                    return InkWell(
                      onTap: () {
                        setState(() {
                          _selectedType = type;
                        });
                        Navigator.pop(context);
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: index < _suggestionTypes.length - 1 ? BorderSide(
                              width: 1,
                              color: const Color(0xFFF5F5F5),
                            ) : BorderSide.none,
                          ),
                        ),
                        child: Text(
                          type,
                          style: TextStyle(
                            color: const Color(0xFF666666),
                            fontSize: 14,
                            fontFamily: 'Pretendard-Light',
                            letterSpacing: -0.28,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          '의견과 제안',
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontFamily: 'Pretendard-Bold',
            letterSpacing: -0.32,
          ),
        ),
        leading: IconButton(
          icon: Image.asset(
            'assets/icons/parent/my/point/back.png',
            width: 20,
            height: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Image.asset(
              'assets/images/home.png', 
              width: 24, 
              height: 24,
            ),
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20.0, 12.0, 20.0, 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 안내 텍스트
              Text(
                '리틀뱅크에 제안하고 싶은 의견이 있다면 자유롭게 얘기해 주세요. 고객님이 주신 소중한 의견을 바탕으로, 더욱 도움되는 리틀뱅크 서비스를 만들어 가겠습니다.',
                style: TextStyle(
                  color: const Color(0xFF202020),
                  fontSize: 13,
                  fontFamily: 'Pretendard-ExtraLight',
                  height: 1.50,
                  letterSpacing: -0.56,
                ),
              ),
              
              const SizedBox(height: 24),
              
              // 스텝 1: 의견 유형 선택
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: ShapeDecoration(
                      color: const Color(0xFFFFD27F),
                      shape: OvalBorder(),
                    ),
                    child: Center(
                      child: Text(
                        '1',
                        style: TextStyle(
                          color: const Color(0xFF212124),
                          fontSize: 14,
                          fontFamily: 'Pretendard-Bold',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '제안하고 싶은 의견 유형을 선택해 주세요.',
                    style: TextStyle(
                      color: const Color(0xFF202020),
                      fontSize: 16,
                      fontFamily: 'Pretendard-Bold',
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // 유형 선택 필드
              GestureDetector(
                onTap: _showTypeSelectionBottomSheet,
                child: Container(
                  width: double.infinity,
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: ShapeDecoration(
                    shape: RoundedRectangleBorder(
                      side: BorderSide(
                        width: 1,
                        color: const Color(0xFF999999),
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedType ?? '유형을 선택해 주세요',
                        style: TextStyle(
                          color: _selectedType != null 
                              ? const Color(0xFF202020) 
                              : const Color(0xFF999999),
                          fontSize: 14,
                          fontFamily: 'Pretendard-Light',
                          letterSpacing: -0.28,
                        ),
                      ),
                      Icon(
                        Icons.keyboard_arrow_down,
                        color: const Color(0xFFCCCCCC),
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // 스텝 2: 내용 입력
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: ShapeDecoration(
                      color: const Color(0xFFFFD27F),
                      shape: OvalBorder(),
                    ),
                    child: Center(
                      child: Text(
                        '2',
                        style: TextStyle(
                          color: const Color(0xFF212124),
                          fontSize: 14,
                          fontFamily: 'Pretendard-Bold',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '내용을 입력해 주세요.',
                        style: TextStyle(
                          color: const Color(0xFF202020),
                          fontSize: 16,
                          fontFamily: 'Pretendard-Bold',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '소중한 의견을 통해 더욱 발전해 나가겠습니다.',
                        style: TextStyle(
                          color: const Color(0xFF888888),
                          fontSize: 13,
                          fontFamily: 'Pretendard-Regular',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // 텍스트 입력 필드
              Container(
                width: double.infinity,
                height: 80,
                clipBehavior: Clip.antiAlias,
                decoration: ShapeDecoration(
                  color: const Color(0xFFF5F5F5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: TextField(
                  controller: _contentController,
                  maxLines: 3,
                  style: TextStyle(
                    color: const Color(0xFF202020),
                    fontSize: 14,
                    fontFamily: 'Pretendard-Regular',
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    filled: true,
                    fillColor: const Color(0xFFF5F5F5),
                    contentPadding: const EdgeInsets.all(16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    errorBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    hintText: '내용을 입력해 주세요. (최소 10자 이상)',
                    hintStyle: TextStyle(
                      color: const Color(0xFF999999),
                      fontSize: 14,
                      fontFamily: 'Pretendard-Light',
                      letterSpacing: -0.24,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // 입력 완료 버튼
              GestureDetector(
                onTap: () {
                  // 입력 완료 처리 로직
                  if (_selectedType == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('의견 유형을 선택해주세요')),
                    );
                    return;
                  }
                  
                  if (_contentController.text.length < 10) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('내용을 10자 이상 입력해주세요')),
                    );
                    return;
                  }
                  
                  // 성공적으로 제출되면 안내 메시지 표시
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('소중한 의견 감사합니다')),
                  );
                  
                  // 입력 필드 초기화
                  setState(() {
                    _selectedType = null;
                    _contentController.clear();
                  });
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: ShapeDecoration(
                    color: const Color(0xFF146AFF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '입력 완료',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontFamily: 'Pretendard-Medium',
                        letterSpacing: -0.28,
                      ),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // 안내 메시지 박스
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: ShapeDecoration(
                  color: const Color(0xFFF2F3F6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '별도의 답변이 제공되지 않습니다.',
                          style: TextStyle(
                            color: const Color(0xFF666666),
                            fontSize: 12,
                            fontFamily: 'Pretendard-Medium',
                            letterSpacing: -0.24,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '주신 제안에 대해서는 답변이 필요한 문의사항은 이용 문의, 결제 문의를 이용해 주세요.',
                      style: TextStyle(
                        color: const Color(0xFF999999),
                        fontSize: 11,
                        fontFamily: 'Pretendard-Light',
                        height: 1.45,
                        letterSpacing: -0.22,
                      ),
                    ),
                  ],
                ),
              ),
              
              // 화면 하단 여백 추가
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const ParentBottomNavigationBar(selectedIndex: 4),
    );
  }
} 