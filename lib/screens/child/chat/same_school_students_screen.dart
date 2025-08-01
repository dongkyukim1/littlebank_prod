import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../services/auth_service.dart';
import 'chat_start_screen.dart';

class SameSchoolStudentsScreen extends StatefulWidget {
  final List<Map<String, dynamic>> students;
  final String schoolName;

  const SameSchoolStudentsScreen({
    super.key,
    required this.students,
    required this.schoolName,
  });

  @override
  State<SameSchoolStudentsScreen> createState() => _SameSchoolStudentsScreenState();
}

class _SameSchoolStudentsScreenState extends State<SameSchoolStudentsScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _filteredStudents = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _filteredStudents = widget.students;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterStudents(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredStudents = widget.students;
      } else {
        _filteredStudents = widget.students.where((student) {
          final name = student['realName'] ?? student['name'] ?? '';
          return name.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Image.asset(
              'assets/icons/Icon/뒤로 가기/Regular.png',
              width: 24,
              height: 24,
            ),
          ),
        ),
        title: Text(
          '같은 학교 학생들',
          style: TextStyle(
            color: Color(0xFF202020),
            fontSize: 16,
            fontFamily: 'Pretendard-Bold',
            letterSpacing: -0.64,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 학교 정보 헤더
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: const Color(0xFFF8F9FA),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.schoolName,
                  style: TextStyle(
                    color: Color(0xFF202020),
                    fontSize: 18,
                    fontFamily: 'Pretendard-Bold',
                    letterSpacing: -0.72,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '총 ${widget.students.length}명의 학생',
                  style: TextStyle(
                    color: Color(0xFF999999),
                    fontSize: 14,
                    fontFamily: 'Pretendard-Light',
                    letterSpacing: -0.28,
                  ),
                ),
              ],
            ),
          ),
          
          // 검색 바
          Container(
            padding: const EdgeInsets.all(16),
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: ShapeDecoration(
                color: const Color(0xFFE7ECF6),
                shape: RoundedRectangleBorder(
                  side: BorderSide(
                    width: 0.60,
                    color: _searchQuery.isNotEmpty
                        ? const Color(0xFF146AFF)
                        : const Color(0xFF5D6A7F),
                  ),
                  borderRadius: BorderRadius.circular(32),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    child: Image.asset(
                      'assets/icons/Icon/검색/Regular.png',
                      width: 24,
                      height: 24,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      alignment: Alignment.centerLeft,
                      child: TextField(
                        controller: _searchController,
                        onChanged: _filterStudents,
                        textAlignVertical: TextAlignVertical.center,
                        style: const TextStyle(
                          color: Color(0xFF202020),
                          fontSize: 14,
                          fontFamily: 'Pretendard-Regular',
                          letterSpacing: -0.28,
                        ),
                        decoration: const InputDecoration(
                          hintText: '이름으로 검색',
                          hintStyle: TextStyle(
                            color: Color(0xFF999999),
                            fontSize: 14,
                            fontFamily: 'Pretendard-Light',
                            letterSpacing: -0.28,
                          ),
                          filled: true,
                          fillColor: Color(0xFFE7ECF6),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 7),
                        ),
                      ),
                    ),
                  ),
                  if (_searchController.text.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _searchController.clear();
                        _filterStudents('');
                      },
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFFCCCCCC),
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          
          // 학생 목록
          Expanded(
            child: _filteredStudents.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 48,
                          color: Color(0xFFCCCCCC),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty
                              ? '학생이 없습니다'
                              : '검색 결과가 없습니다',
                          style: TextStyle(
                            color: Color(0xFF999999),
                            fontSize: 16,
                            fontFamily: 'Pretendard-Regular',
                            letterSpacing: -0.32,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredStudents.length,
                    itemBuilder: (context, index) {
                      final student = _filteredStudents[index];
                      final name = student['realName'] ?? student['name'] ?? '이름 없음';
                      final profileImagePath = student['profileImagePath'] ?? '';
                      final userId = student['userId'] ?? 0;
                      final statusMessage = student['statusMessage'] ?? '';
                      
                      // 프로필 이미지 URL 생성
                      String profileImageUrl = '';
                      if (profileImagePath.isNotEmpty) {
                        if (profileImagePath.startsWith('http')) {
                          profileImageUrl = profileImagePath;
                        } else {
                          profileImageUrl = AuthService.getFullProfileImageUrl(profileImagePath);
                        }
                      }
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: ShapeDecoration(
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            side: BorderSide(
                              width: 0.5,
                              color: const Color(0xFFE7ECF6),
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          children: [
                            // 프로필 이미지
                            Container(
                              width: 48,
                              height: 48,
                              decoration: ShapeDecoration(
                                image: profileImageUrl.isNotEmpty
                                    ? DecorationImage(
                                        image: CachedNetworkImageProvider(profileImageUrl),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                                shape: OvalBorder(
                                  side: BorderSide(
                                    width: 1,
                                    color: const Color(0xFF146AFF),
                                  ),
                                ),
                              ),
                              child: profileImageUrl.isEmpty
                                  ? Center(
                                      child: Text(
                                        name.isNotEmpty ? name.substring(0, 1) : '?',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontFamily: 'Pretendard-Bold',
                                          color: Color(0xFF3A88F4),
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 16),
                            // 사용자 정보
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: TextStyle(
                                      color: Color(0xFF202020),
                                      fontSize: 16,
                                      fontFamily: 'Pretendard-Medium',
                                      letterSpacing: -0.32,
                                    ),
                                  ),
                                  if (statusMessage.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      statusMessage,
                                      style: TextStyle(
                                        color: Color(0xFF999999),
                                        fontSize: 12,
                                        fontFamily: 'Pretendard-Light',
                                        letterSpacing: -0.24,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            // 채팅 버튼
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ChatStartScreen(
                                      userId: userId,
                                      userName: name,
                                      userDescription: statusMessage.isNotEmpty ? statusMessage : '같은 학교 학생',
                                      friendId: null,
                                      isBlocked: false,
                                      isBestFriend: false,
                                      initialProfileImageUrl: profileImageUrl,
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: ShapeDecoration(
                                  color: const Color(0xFF5D9EFF),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                child: Text(
                                  '채팅',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontFamily: 'Pretendard-Medium',
                                    letterSpacing: -0.24,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
} 