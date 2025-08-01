import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatBackgroundSettingsScreen extends StatefulWidget {
  const ChatBackgroundSettingsScreen({super.key});

  @override
  State<ChatBackgroundSettingsScreen> createState() => _ChatBackgroundSettingsScreenState();
}

class _ChatBackgroundSettingsScreenState extends State<ChatBackgroundSettingsScreen> {
  String? _selectedBackground;
  bool _isLoading = true;

  final List<Map<String, String>> _backgrounds = [
    {
      'id': 'default',
      'name': '기본 배경',
      'path': '', // 기본 배경은 빈 문자열
      'preview': 'assets/icons/background_chat/background_1.png', // 미리보기용
    },
    {
      'id': 'background_1',
      'name': '배경 1',
      'path': 'assets/icons/background_chat/background_1.png',
      'preview': 'assets/icons/background_chat/background_1.png',
    },
    {
      'id': 'background_2',
      'name': '배경 2',
      'path': 'assets/icons/background_chat/background_2.png',
      'preview': 'assets/icons/background_chat/background_2.png',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadCurrentBackground();
  }

  Future<void> _loadCurrentBackground() async {
    setState(() => _isLoading = true);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedBackground = prefs.getString('chat_background') ?? 'default';
      
      setState(() {
        _selectedBackground = savedBackground;
        _isLoading = false;
      });
    } catch (e) {
      print('배경 설정 로드 중 오류: $e');
      setState(() {
        _selectedBackground = 'default';
        _isLoading = false;
      });
    }
  }

  Future<void> _saveBackground(String backgroundId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('chat_background', backgroundId);
      
      setState(() {
        _selectedBackground = backgroundId;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '채팅방 배경이 변경되었습니다.',
            style: TextStyle(
              fontFamily: 'Pretendard-Regular',
              color: Colors.white,
            ),
          ),
          backgroundColor: Color(0xFF3A88F4),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('배경 설정 저장 중 오류: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '배경 설정 저장에 실패했습니다.',
            style: TextStyle(
              fontFamily: 'Pretendard-Regular',
              color: Colors.white,
            ),
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _showBackgroundPreview(Map<String, String> background) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: double.infinity,
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                // 배경 이미지
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: background['id'] == 'default' 
                        ? Color(0xFFE7ECF6) 
                        : Colors.transparent,
                  ),
                  child: background['id'] != 'default' 
                      ? Image.asset(
                          background['preview']!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Color(0xFFE7ECF6),
                              child: Center(
                                child: Icon(
                                  Icons.error_outline,
                                  color: Colors.grey,
                                  size: 48,
                                ),
                              ),
                            );
                          },
                        )
                      : null,
                ),
                
                // 상단 타이틀과 닫기 버튼
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          background['name']!,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontFamily: 'Pretendard-Bold',
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // 하단 적용 버튼
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Container(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _saveBackground(background['id']!);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF3A88F4),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                      child: Text(
                        '이 배경 적용하기',
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: 'Pretendard-Bold',
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          '채팅방 배경 설정',
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontFamily: 'Pretendard-Bold',
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: Color(0xFF3A88F4),
              ),
            )
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 설명 텍스트
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Color(0xFFE5E5E5),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '채팅방 배경 변경',
                          style: TextStyle(
                            fontSize: 16,
                            fontFamily: 'Pretendard-Bold',
                            color: Color(0xFF202020),
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '원하는 배경을 선택하여 채팅방을 꾸며보세요.\n1대1 채팅과 그룹 채팅 모두에 적용됩니다.',
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: 'Pretendard-Regular',
                            color: Color(0xFF666666),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 24),
                  
                  // 배경 선택 그리드
                  Text(
                    '배경 선택',
                    style: TextStyle(
                      fontSize: 18,
                      fontFamily: 'Pretendard-Bold',
                      color: Color(0xFF202020),
                    ),
                  ),
                  
                  SizedBox(height: 16),
                  
                  GridView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.8,
                    ),
                    itemCount: _backgrounds.length,
                    itemBuilder: (context, index) {
                      final background = _backgrounds[index];
                      final isSelected = _selectedBackground == background['id'];
                      
                      return GestureDetector(
                        onTap: () => _showBackgroundPreview(background),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? Color(0xFF3A88F4) : Color(0xFFE5E5E5),
                              width: isSelected ? 3 : 1,
                            ),
                            boxShadow: isSelected ? [
                              BoxShadow(
                                color: Color(0xFF3A88F4).withOpacity(0.3),
                                blurRadius: 8,
                                offset: Offset(0, 4),
                              ),
                            ] : null,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Stack(
                              children: [
                                // 배경 미리보기
                                Container(
                                  width: double.infinity,
                                  height: double.infinity,
                                  decoration: BoxDecoration(
                                    color: background['id'] == 'default' 
                                        ? Color(0xFFE7ECF6) 
                                        : Colors.transparent,
                                  ),
                                  child: background['id'] != 'default' 
                                      ? Image.asset(
                                          background['preview']!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Container(
                                              color: Color(0xFFE7ECF6),
                                              child: Center(
                                                child: Icon(
                                                  Icons.error_outline,
                                                  color: Colors.grey,
                                                  size: 32,
                                                ),
                                              ),
                                            );
                                          },
                                        )
                                      : Center(
                                          child: Text(
                                            '기본\n배경',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontFamily: 'Pretendard-Medium',
                                              color: Color(0xFF666666),
                                            ),
                                          ),
                                        ),
                                ),
                                
                                // 선택 표시
                                if (isSelected)
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: Container(
                                      padding: EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Color(0xFF3A88F4),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                
                                // 하단 제목
                                Positioned(
                                  bottom: 0,
                                  left: 0,
                                  right: 0,
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.7),
                                      borderRadius: BorderRadius.only(
                                        bottomLeft: Radius.circular(12),
                                        bottomRight: Radius.circular(12),
                                      ),
                                    ),
                                    child: Text(
                                      background['name']!,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontFamily: 'Pretendard-Medium',
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  
                  SizedBox(height: 24),
                  
                  // 현재 선택된 배경 정보
                  if (_selectedBackground != null)
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Color(0xFF3A88F4).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Color(0xFF3A88F4).withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Color(0xFF3A88F4),
                            size: 20,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '현재 선택: ${_backgrounds.firstWhere((bg) => bg['id'] == _selectedBackground)['name']}',
                              style: TextStyle(
                                fontSize: 14,
                                fontFamily: 'Pretendard-Medium',
                                color: Color(0xFF3A88F4),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
    );
  }
} 