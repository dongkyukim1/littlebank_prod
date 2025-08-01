import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';
import '../../services/feed_service.dart';
import 'feed_detail_screen.dart'; // 피드 상세 화면 import 추가

class TodayFeedScreen extends StatefulWidget {
  const TodayFeedScreen({Key? key}) : super(key: key);

  @override
  State<TodayFeedScreen> createState() => _TodayFeedScreenState();
}

class _TodayFeedScreenState extends State<TodayFeedScreen> {
  // 검색 컨트롤러 추가
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearchFocused = false;
  
  // 현재 시간을 가져와서 시간 표시
  String get currentTimeFormatted {
    final now = DateTime.now();
    return '${now.hour}시 기준';
  }

  // 사용자 학년 정보
  String _userGradeCategory = 'ALL'; // 기본값은 ALL
  bool _isLoadingUserInfo = true;
  
  // 학년 목록 - 학년 변경 기능에 사용
  final List<String> _grades = ['초등학생', '중학생', '고등학생', '전체'];
  final List<String> _gradeCategories = ['ELEMENTARY', 'MIDDLE', 'HIGH', 'ALL'];
  
  // 과목 목록 - 과목 변경 기능에 사용
  final List<String> _subjects = ['수학', '국어', '영어', '과학', '사회'];
  final List<String> _subjectCategories = ['MATH', 'KOREAN', 'ENGLISH', 'SCIENCE', 'SOCIETY'];
  
  // 현재 선택된 학년 인덱스
  int _selectedGradeIndex = 3; // 기본값: 전체
  
  // 현재 선택된 과목 인덱스
  int _selectedSubjectIndex = 0; // 기본값: 수학
  
  // 현재 선택된 태그 카테고리 인덱스
  int _selectedTagIndex = 0; // 기본값: 학습인증

  // 인기 피드 데이터
  List<dynamic> _popularFeeds = [];
  bool _isLoadingPopularFeeds = true;
  String _popularFeedsError = '';

  // 현재 선택된 과목의 인기글 인덱스
  int _currentCategoryIndex = 0;
  
  // 카테고리별 인기 피드 데이터
  List<dynamic> _categoryFeeds = [];
  bool _isLoadingCategoryFeeds = true;
  String _categoryFeedsError = '';

  // 카테고리 피드 페이지 컨트롤러 추가
  late PageController _categoryPageController;
  
  // 태그 카테고리 목록
  final List<String> _tagCategories = ['학습인증', '습관형성', '정보공유'];
  final List<String> _tagCategoryValues = ['STUDY_CERTIFICATION', 'HABIT_BUILDING', 'INFORMATION'];
  
  // 태그 카테고리 피드 데이터
  List<dynamic> _tagCategoryFeeds = [];
  bool _isLoadingTagCategoryFeeds = true;
  String _tagCategoryFeedsError = '';
  int _currentTagCategoryIndex = 0;
  late PageController _tagCategoryPageController;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _loadPopularFeeds();
    _loadCategoryFeeds();
    _loadTagCategoryFeeds();
    
    // 페이지 컨트롤러 초기화
    _categoryPageController = PageController(initialPage: 0);
    _tagCategoryPageController = PageController(initialPage: 0);
    
    // 검색바 포커스 리스너 추가
    _searchFocusNode.addListener(() {
      setState(() {
        _isSearchFocused = _searchFocusNode.hasFocus;
      });
    });
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _categoryPageController.dispose();
    _tagCategoryPageController.dispose();
    super.dispose();
  }

  // 사용자 정보 로드 (학년 정보 포함)
  Future<void> _loadUserInfo() async {
    setState(() {
      _isLoadingUserInfo = true;
    });

    try {
      // 사용자 정보 가져오기
      final userInfo = await AuthService.getUserInfo();
      
      if (userInfo != null && userInfo.containsKey('gradeCategory')) {
        final String userGrade = userInfo['gradeCategory'] ?? 'ALL';
        setState(() {
          _userGradeCategory = userGrade;
          // 사용자 학년에 맞는 인덱스 설정
          final int index = _gradeCategories.indexOf(userGrade);
          if (index != -1) {
            _selectedGradeIndex = index;
          }
        });
      }
    } catch (e) {
      print('사용자 정보 로드 실패: $e');
    } finally {
      setState(() {
        _isLoadingUserInfo = false;
      });
    }
  }

  // 학년 카테고리에 따른 텍스트 반환
  String getGradeText() {
    return _grades[_selectedGradeIndex];
  }
  
  // 학년에 따라 다른 형식으로 피드 타이틀 생성
  String getFeedTitleText() {
    // 모든 학년에 대해 동일한 포맷 사용
    return '에게 가장 인기있는 피드';
  }
  
  // 인기 피드 로드 (좋아요 순)
  Future<void> _loadPopularFeeds() async {
    setState(() {
      _isLoadingPopularFeeds = true;
      _popularFeedsError = '';
    });

    try {
      // 좋아요 순 API 호출 (새로운 API 엔드포인트 사용)
      final result = await FeedService.getFeedListByLikes(
        gradeCategory: _gradeCategories[_selectedGradeIndex],
        size: 10,
      );
      
      if (result != null && result.containsKey('content')) {
        setState(() {
          _popularFeeds = result['content'] as List<dynamic>;
          _isLoadingPopularFeeds = false;
        });
      } else {
        setState(() {
          _popularFeeds = [];
          _isLoadingPopularFeeds = false;
          _popularFeedsError = '데이터를 불러올 수 없습니다.';
        });
      }
    } catch (e) {
      setState(() {
        _popularFeeds = [];
        _isLoadingPopularFeeds = false;
        _popularFeedsError = '오류가 발생했습니다: $e';
      });
      print('인기 피드 로드 오류: $e');
    }
  }
  
  // 카테고리별 인기 피드 로드
  Future<void> _loadCategoryFeeds() async {
    setState(() {
      _isLoadingCategoryFeeds = true;
      _categoryFeedsError = '';
    });

    try {
      // 좋아요 순 API 호출 (새로운 API 엔드포인트 사용)
      final result = await FeedService.getFeedListByLikes(
        subjectCategory: _subjectCategories[_selectedSubjectIndex],
        size: 3, // 3개만 가져오도록 변경 (1,2,3등)
      );
      
      if (result != null && result.containsKey('content')) {
        setState(() {
          _categoryFeeds = result['content'] as List<dynamic>;
          _isLoadingCategoryFeeds = false;
          // 첫 번째 피드를 표시하기 위해 인덱스 초기화
          _currentCategoryIndex = _categoryFeeds.isNotEmpty ? 0 : -1;
          // 페이지 컨트롤러 초기 페이지 설정
          _categoryPageController = PageController(initialPage: 0);
        });
      } else {
        setState(() {
          _categoryFeeds = [];
          _isLoadingCategoryFeeds = false;
          _categoryFeedsError = '데이터를 불러올 수 없습니다.';
        });
      }
    } catch (e) {
      setState(() {
        _categoryFeeds = [];
        _isLoadingCategoryFeeds = false;
        _categoryFeedsError = '오류가 발생했습니다: $e';
      });
      print('카테고리별 피드 로드 오류: $e');
    }
  }
  
  // 학년 변경 시 피드 새로고침
  void _handleGradeChange(int index) {
    setState(() {
      _selectedGradeIndex = index;
    });
    _loadPopularFeeds();
  }
  
  // 과목 변경 시 피드 새로고침
  void _handleSubjectChange(int index) {
    setState(() {
      _selectedSubjectIndex = index;
      _currentCategoryIndex = 0; // 과목 변경 시 첫 번째 순위부터 보여주기
    });
    _loadCategoryFeeds();
  }
  
  // 카테고리 피드 페이지 변경 처리
  void _handleCategoryPageChanged(int index) {
    setState(() {
      _currentCategoryIndex = index;
    });
  }
  
  // 태그 카테고리 변경 시 피드 새로고침
  void _handleTagCategoryChange(int index) {
    setState(() {
      _selectedTagIndex = index;
      _currentTagCategoryIndex = 0; // 카테고리 변경 시 첫 번째 순위부터 보여주기
    });
    _loadTagCategoryFeeds();
  }
  
  // 태그 카테고리 피드 페이지 변경 처리
  void _handleTagCategoryPageChanged(int index) {
    setState(() {
      _currentTagCategoryIndex = index;
    });
  }
  
  // 태그 카테고리 인기 피드 로드
  Future<void> _loadTagCategoryFeeds() async {
    setState(() {
      _isLoadingTagCategoryFeeds = true;
      _tagCategoryFeedsError = '';
    });

    try {
      final result = await FeedService.getFeedListByLikes(
        tagCategory: _tagCategoryValues[_selectedTagIndex], // 선택된 태그 카테고리
        size: 3, // 3개만 가져오도록 설정
      );
      
      if (result != null && result.containsKey('content')) {
        setState(() {
          _tagCategoryFeeds = result['content'] as List<dynamic>;
          _isLoadingTagCategoryFeeds = false;
          _currentTagCategoryIndex = _tagCategoryFeeds.isNotEmpty ? 0 : -1;
          _tagCategoryPageController = PageController(initialPage: 0);
        });
      } else {
        setState(() {
          _tagCategoryFeeds = [];
          _isLoadingTagCategoryFeeds = false;
          _tagCategoryFeedsError = '데이터를 불러올 수 없습니다.';
        });
      }
    } catch (e) {
      setState(() {
        _tagCategoryFeeds = [];
        _isLoadingTagCategoryFeeds = false;
        _tagCategoryFeedsError = '오류가 발생했습니다: $e';
      });
      print('태그 카테고리 피드 로드 오류: $e');
    }
  }
  
  // 학년 선택 다이얼로그 표시
  void _showGradeSelector(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 24, bottom: 10),
                  child: Text(
                    '학년 선택',
                    style: TextStyle(
                      fontSize: 18, 
                      fontFamily: 'Pretendard-Bold',
                      color: Color(0xFF202020),
                    ),
                  ),
                ),
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: Color(0xFFEEEEEE),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    alignment: WrapAlignment.center,
                    children: List.generate(_grades.length, (index) {
                      final bool isSelected = _selectedGradeIndex == index;
                      return GestureDetector(
                        onTap: () {
                          _handleGradeChange(index);
                          Navigator.pop(context);
                        },
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: isSelected 
                              ? const Color.fromRGBO(255, 166, 61, 0.1)
                              : Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: isSelected 
                                ? const Color.fromRGBO(255, 166, 61, 1)
                                : const Color(0xFFEEEEEE),
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _grades[index],
                                style: TextStyle(
                                  fontSize: 18,
                                  fontFamily: isSelected 
                                    ? 'Pretendard-Bold' 
                                    : 'Pretendard-Medium',
                                  color: isSelected 
                                    ? const Color.fromRGBO(255, 166, 61, 1)
                                    : const Color(0xFF202020),
                                ),
                              ),
                              if (isSelected)
                                const SizedBox(height: 8),
                              if (isSelected)
                                Container(
                                  width: 24,
                                  height: 2,
                                  decoration: const BoxDecoration(
                                    color: Color.fromRGBO(255, 166, 61, 1),
                                    borderRadius: BorderRadius.all(Radius.circular(1)),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 10),
                InkWell(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: double.infinity,
                    height: 50,
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: Color(0xFFEEEEEE),
                          width: 1,
                        ),
                      ),
                    ),
                    child: const Center(
                      child: Text(
                        '닫기',
                        style: TextStyle(
                          color: Color(0xFF8590A3),
                          fontSize: 16,
                          fontFamily: 'Pretendard-Medium',
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  // 검색 처리
  void _handleSearch(String query) {
    print('검색어: $query');
    // 검색 로직 구현
  }
   
  // 과목 선택 다이얼로그 표시
  void _showSubjectSelector(BuildContext context) {
    // 임시 선택 인덱스 (현재 선택된 과목으로 초기화)
    int tempSelectedIndex = _selectedSubjectIndex;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        double screenWidth = MediaQuery.of(context).size.width;
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              width: screenWidth,
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Color(0x5B000000),
                    blurRadius: 8,
                    offset: Offset(0, -4),
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
                    width: screenWidth,
                    padding: const EdgeInsets.all(16),
                    decoration: ShapeDecoration(
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
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          height: 40, // 높이 증가
                          alignment: Alignment.centerLeft, // 왼쪽 정렬 및 중앙 배치
                          padding: EdgeInsets.only(top: 4, bottom: 4), // 패딩 감소
                          child: Text(
                            '과목을 선택할게요',
                            style: TextStyle(
                              color: const Color(0xFF202020),
                              fontSize: 18,
                              fontFamily: 'Pretendard-Bold',
                              letterSpacing: -0.72,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: screenWidth,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: screenWidth,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(color: Colors.white),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: double.infinity,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    // 국어 버튼
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          tempSelectedIndex = 1; // 국어
                                        });
                                      },
      child: Container(
                                        width: 89,
                                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                        decoration: ShapeDecoration(
                                          color: tempSelectedIndex == 1 
                                              ? const Color(0xFFFFD27F) 
                                              : const Color(0xFFEFF2F6),
                                          shape: RoundedRectangleBorder(
                                            side: tempSelectedIndex == 1
                                                ? BorderSide(
                                                    width: 1.40,
                                                    color: const Color(0xFFFFA63D),
                                                  )
                                                : BorderSide.none,
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                            Text(
                                              '국어',
                                              style: TextStyle(
                                                color: tempSelectedIndex == 1
                                                    ? const Color(0xFF001F55)
                                                    : const Color(0xFF5D9EFF),
                                                fontSize: 12,
                                                fontFamily: tempSelectedIndex == 1
                                                    ? 'Pretendard-Medium'
                                                    : 'Pretendard-Light',
                                                letterSpacing: -0.24,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 20),
                                    // 수학 버튼
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          tempSelectedIndex = 0; // 수학
                                        });
                                      },
                                      child: Container(
                                        width: 89,
                                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                        decoration: ShapeDecoration(
                                          color: tempSelectedIndex == 0 
                                              ? const Color(0xFFFFD27F) 
                                              : const Color(0xFFEFF2F6),
                                          shape: RoundedRectangleBorder(
                                            side: tempSelectedIndex == 0
                                                ? BorderSide(
                                                    width: 1.40,
                                                    color: const Color(0xFFFFA63D),
                                                  )
                                                : BorderSide.none,
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                            Text(
                                              '수학',
                                              style: TextStyle(
                                                color: tempSelectedIndex == 0
                                                    ? const Color(0xFF001F55)
                                                    : const Color(0xFF5D9EFF),
                                                fontSize: 12,
                                                fontFamily: tempSelectedIndex == 0
                                                    ? 'Pretendard-Medium'
                                                    : 'Pretendard-Light',
                                                letterSpacing: -0.24,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 20),
                                    // 영어 버튼
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          tempSelectedIndex = 2; // 영어
                                        });
                                      },
                                      child: Container(
                                        width: 89,
                                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                        decoration: ShapeDecoration(
                                          color: tempSelectedIndex == 2 
                                              ? const Color(0xFFFFD27F) 
                                              : const Color(0xFFEFF2F6),
                                          shape: RoundedRectangleBorder(
                                            side: tempSelectedIndex == 2
                                                ? BorderSide(
                                                    width: 1.40,
                                                    color: const Color(0xFFFFA63D),
                                                  )
                                                : BorderSide.none,
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                            Text(
                                              '영어',
                                              style: TextStyle(
                                                color: tempSelectedIndex == 2
                                                    ? const Color(0xFF001F55)
                                                    : const Color(0xFF5D9EFF),
                                                fontSize: 12,
                                                fontFamily: tempSelectedIndex == 2
                                                    ? 'Pretendard-Medium'
                                                    : 'Pretendard-Light',
                                                letterSpacing: -0.24,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: screenWidth,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(color: Colors.white),
        child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
          children: [
                              Container(
                                width: double.infinity,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    // 사회 버튼
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          tempSelectedIndex = 4; // 사회
                                        });
                                      },
                                      child: Container(
                                        width: 89,
                                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                        decoration: ShapeDecoration(
                                          color: tempSelectedIndex == 4 
                                              ? const Color(0xFFFFD27F) 
                                              : const Color(0xFFEFF2F6),
                                          shape: RoundedRectangleBorder(
                                            side: tempSelectedIndex == 4
                                                ? BorderSide(
                                                    width: 1.40,
                                                    color: const Color(0xFFFFA63D),
                                                  )
                                                : BorderSide.none,
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                            Text(
                                              '사회',
                                              style: TextStyle(
                                                color: tempSelectedIndex == 4
                                                    ? const Color(0xFF001F55)
                                                    : const Color(0xFF5D9EFF),
                                                fontSize: 12,
                                                fontFamily: tempSelectedIndex == 4
                                                    ? 'Pretendard-Medium'
                                                    : 'Pretendard-Light',
                                                letterSpacing: -0.24,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 20),
                                    // 과학 버튼
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          tempSelectedIndex = 3; // 과학
                                        });
                                      },
              child: Container(
                                        width: 89,
                                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                        decoration: ShapeDecoration(
                                          color: tempSelectedIndex == 3 
                                              ? const Color(0xFFFFD27F) 
                                              : const Color(0xFFEFF2F6),
                                          shape: RoundedRectangleBorder(
                                            side: tempSelectedIndex == 3
                                                ? BorderSide(
                                                    width: 1.40,
                                                    color: const Color(0xFFFFA63D),
                                                  )
                                                : BorderSide.none,
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                            Text(
                                              '과학',
                                              style: TextStyle(
                                                color: tempSelectedIndex == 3
                                                    ? const Color(0xFF001F55)
                                                    : const Color(0xFF5D9EFF),
                                                fontSize: 12,
                                                fontFamily: tempSelectedIndex == 3
                                                    ? 'Pretendard-Medium'
                                                    : 'Pretendard-Light',
                                                letterSpacing: -0.24,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: screenWidth,
                    padding: const EdgeInsets.only(
                      top: 16,
                      left: 16,
                      right: 16,
                      bottom: 24,
                    ),
                    decoration: BoxDecoration(color: Colors.white),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                width: double.infinity,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  GestureDetector(
                                    onTap: () => Navigator.pop(context),
                                    child: Container(
                                      width: (screenWidth - 56) / 2,
                                      padding: const EdgeInsets.all(16),
                                      decoration: ShapeDecoration(
                                        color: const Color(0xFFF1F1F1),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            mainAxisAlignment: MainAxisAlignment.start,
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [
                                              Text(
                                                '이전',
                                                style: TextStyle(
                                                  color: const Color(0xFFB6B6B6),
                                                  fontSize: 14,
                                                  fontFamily: 'Pretendard-Light',
                                                  letterSpacing: -0.28,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(width: 24),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      _handleSubjectChange(tempSelectedIndex);
                                      Navigator.pop(context);
                                    },
                                    child: Container(
                                      width: (screenWidth - 56) / 2,
                                      padding: const EdgeInsets.all(16),
                                      decoration: ShapeDecoration(
                                        color: const Color(0xFF5D9EFF),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            mainAxisAlignment: MainAxisAlignment.start,
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [
                                              Text(
                                                '완료',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 14,
                                                  fontFamily: 'Pretendard-Light',
                                                  letterSpacing: -0.28,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }
        );
      },
    );
  }

  // 태그 카테고리 선택 다이얼로그 표시
  void _showTagCategorySelector(BuildContext context) {
    // 임시 선택 인덱스 (현재 선택된 태그로 초기화)
    int tempSelectedIndex = _selectedTagIndex;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        double screenWidth = MediaQuery.of(context).size.width;
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              width: screenWidth,
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Color(0x5B000000),
                    blurRadius: 8,
                    offset: Offset(0, -4),
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
                    width: screenWidth,
                    padding: const EdgeInsets.all(16),
                    decoration: ShapeDecoration(
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
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          height: 40,
                          alignment: Alignment.centerLeft,
                          padding: EdgeInsets.only(top: 4, bottom: 4),
                          child: Text(
                            '유형을 선택할게요',
                            style: TextStyle(
                              color: const Color(0xFF202020),
                              fontSize: 18,
                              fontFamily: 'Pretendard-Bold',
                              letterSpacing: -0.72,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: screenWidth,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 첫 번째 줄: 학습 인증, 습관 형성
                        Container(
                          width: screenWidth,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(color: Colors.white),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: double.infinity,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    // 학습 인증 버튼
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          tempSelectedIndex = 0; // 학습 인증
                                        });
                                      },
                                      child: Container(
                                        width: (screenWidth - 52) / 2,
                                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                        decoration: ShapeDecoration(
                                          color: tempSelectedIndex == 0
                                              ? const Color(0xFFFFD27F)
                                              : const Color(0xFFEFF2F6),
                                          shape: RoundedRectangleBorder(
                                            side: tempSelectedIndex == 0
                                                ? BorderSide(
                                                    width: 1.40,
                                                    color: const Color(0xFFFFA63D),
                                                  )
                                                : BorderSide.none,
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                            Text(
                                              '학습 인증',
                                              style: TextStyle(
                                                color: tempSelectedIndex == 0
                                                    ? const Color(0xFF001F55)
                                                    : const Color(0xFF5D9EFF),
                                                fontSize: 12,
                                                fontFamily: tempSelectedIndex == 0
                                                    ? 'Pretendard-Medium'
                                                    : 'Pretendard-Light',
                                                letterSpacing: -0.24,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 20),
                                    // 습관 형성 버튼
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          tempSelectedIndex = 1; // 습관 형성
                                        });
                                      },
                                      child: Container(
                                        width: (screenWidth - 52) / 2,
                                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                        decoration: ShapeDecoration(
                                          color: tempSelectedIndex == 1
                                              ? const Color(0xFFFFD27F)
                                              : const Color(0xFFEFF2F6),
                                          shape: RoundedRectangleBorder(
                                            side: tempSelectedIndex == 1
                                                ? BorderSide(
                                                    width: 1.40,
                                                    color: const Color(0xFFFFA63D),
                                                  )
                                                : BorderSide.none,
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                            Text(
                                              '습관 형성',
                                              style: TextStyle(
                                                color: tempSelectedIndex == 1
                                                    ? const Color(0xFF001F55)
                                                    : const Color(0xFF5D9EFF),
                                                fontSize: 12,
                                                fontFamily: tempSelectedIndex == 1
                                                    ? 'Pretendard-Medium'
                                                    : 'Pretendard-Light',
                                                letterSpacing: -0.24,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        // 두 번째 줄: 정보 공유
                        Container(
                          width: screenWidth,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(color: Colors.white),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: double.infinity,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    // 정보 공유 버튼
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          tempSelectedIndex = 2; // 정보 공유
                                        });
                                      },
                                      child: Container(
                                        width: (screenWidth - 52) / 2,
                                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                        decoration: ShapeDecoration(
                                          color: tempSelectedIndex == 2
                                              ? const Color(0xFFFFD27F)
                                              : const Color(0xFFEFF2F6),
                                          shape: RoundedRectangleBorder(
                                            side: tempSelectedIndex == 2
                                                ? BorderSide(
                                                    width: 1.40,
                                                    color: const Color(0xFFFFA63D),
                                                  )
                                                : BorderSide.none,
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                            Text(
                                              '정보 공유',
                                              style: TextStyle(
                                                color: tempSelectedIndex == 2
                                                    ? const Color(0xFF001F55)
                                                    : const Color(0xFF5D9EFF),
                                                fontSize: 12,
                                                fontFamily: tempSelectedIndex == 2
                                                    ? 'Pretendard-Medium'
                                                    : 'Pretendard-Light',
                                                letterSpacing: -0.24,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: screenWidth,
                    padding: const EdgeInsets.only(
                      top: 16,
                      left: 16,
                      right: 16,
                      bottom: 24,
                    ),
                    decoration: BoxDecoration(color: Colors.white),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // 이전 버튼
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  GestureDetector(
                                    onTap: () => Navigator.pop(context),
                                    child: Container(
                                      width: (screenWidth - 56) / 2,
                                      padding: const EdgeInsets.all(16),
                                      decoration: ShapeDecoration(
                                        color: const Color(0xFFF1F1F1),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            mainAxisAlignment: MainAxisAlignment.start,
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [
                                              Text(
                                                '이전',
                                                style: TextStyle(
                                                  color: const Color(0xFFB6B6B6),
                                                  fontSize: 14,
                                                  fontFamily: 'Pretendard-Light',
                                                  letterSpacing: -0.28,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(width: 24),
                              // 완료 버튼
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      _handleTagCategoryChange(tempSelectedIndex);
                                      Navigator.pop(context);
                                    },
                                    child: Container(
                                      width: (screenWidth - 56) / 2,
                                      padding: const EdgeInsets.all(16),
                                      decoration: ShapeDecoration(
                                        color: const Color(0xFF5D9EFF),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            mainAxisAlignment: MainAxisAlignment.start,
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [
                                              Text(
                                                '완료',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 14,
                                                  fontFamily: 'Pretendard-Light',
                                                  letterSpacing: -0.28,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(color: Color(0xFFEFF2F6)),
      child: Column(
        children: [
          // 검색바
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: ShapeDecoration(
                  color: const Color(0xFFEFF2F6),
                  shape: RoundedRectangleBorder(
                    side: BorderSide(
                      width: (_isSearchFocused || _searchController.text.isNotEmpty) ? 1.5 : 0.60,
                      color: (_isSearchFocused || _searchController.text.isNotEmpty) ? const Color(0xFF5D9EFF) : const Color(0xFF8490A3),
                    ),
                    borderRadius: BorderRadius.circular(32),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      clipBehavior: Clip.antiAlias,
                      decoration: const BoxDecoration(),
                      child: Image.asset(
                        'assets/icons/my/검색.png',
                      width: 24,
                      height: 24,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        onSubmitted: _handleSearch,
                        decoration: const InputDecoration(
                          hintText: '찾고싶은 내용을 검색해 주세요',
                          hintStyle: TextStyle(
                            color: Color(0xFF999999),
                            fontSize: 12,
                            fontFamily: 'Pretendard-Light',
                            letterSpacing: -0.24,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          focusedErrorBorder: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          fillColor: Color(0xFFEFF2F6),
                          filled: true,
                        ),
                        style: const TextStyle(
                          color: Color(0xFF202020),
                          fontSize: 12,
                          fontFamily: 'Pretendard-Regular',
                          letterSpacing: -0.24,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          // 검색바와 섹션 사이 간격 추가
          const SizedBox(height: 12),
          
          // 피드 컨텐츠를 위한 Expanded 추가
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
            _buildPopularFeedsSection(),
                  // 인기글과 수학 섹션 사이 간격 추가 (36px)
                  const SizedBox(height: 36),
                  _buildSubjectFeedsSection(),
                  // 수학과 학습인증 섹션 사이 간격 추가 (36px)
                  const SizedBox(height: 36),
            _buildTagCategoryFeedsSection(),
          ],
        ),
            ),
          ),
        ],
      ),
    );
  }

  // 인기 피드 섹션 (전체 리틀인의 인기글 훔쳐보기)
  Widget _buildPopularFeedsSection() {
    return Container(
      width: double.infinity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 섹션 제목
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 타이틀
                    Text(
                  '전체 리틀인의 인기글 훔쳐보기',
                      style: TextStyle(
                        color: const Color(0xFF202020),
                    fontSize: 18,
                        fontFamily: 'Pretendard-Bold',
                        height: 1.50,
                        letterSpacing: -0.80,
                      ),
                    ),
                // 시간을 더 오른쪽으로 이동
                const SizedBox(width: 16),
                Text(
                  currentTimeFormatted,
                  style: TextStyle(
                    color: const Color(0xFF999999),
                    fontSize: 12,
                    fontFamily: 'Pretendard-Light',
                    letterSpacing: -0.24,
                  ),
                ),
              ],
            ),
          ),
          
          // 섹션 제목과 카드 사이에 공간 추가
          const SizedBox(height: 12),
          
          // 로딩 중이거나 오류가 있는 경우 처리
                if (_isLoadingPopularFeeds)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (_popularFeedsError.isNotEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text(
                        _popularFeedsError,
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 14,
                          fontFamily: 'Pretendard-Medium',
                        ),
                      ),
                    ),
                  )
                else if (_popularFeeds.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Text(
                        '인기 피드가 없습니다',
                        style: TextStyle(
                          color: Color(0xFF999999),
                          fontSize: 14,
                          fontFamily: 'Pretendard-Medium',
                        ),
                      ),
                    ),
                  )
          else
            // 피드 카드 리스트 (가로 스크롤 적용)
            Container(
              width: double.infinity,
              height: 250, // 카드 높이에 맞게 조정
              padding: const EdgeInsets.only(left: 16),
              child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                itemCount: _popularFeeds.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 24),
                    child: _buildUpdatedPopularFeedCard(_popularFeeds[index]),
                  );
                },
            ),
          ),
        ],
      ),
    );
  }

  // 업데이트된 인기 피드 카드
  Widget _buildUpdatedPopularFeedCard(dynamic feed) {
    final String title = feed['title'] ?? '';
    final String content = feed['content'] ?? '';
    final String author = feed['writerName'] ?? '';
    final String profileImageUrl = feed['writerProfileImageUrl'] ?? '';
    final List<dynamic> imageUrls = feed['imageUrls'] ?? [];
    final int views = feed['viewCount'] ?? 0;
    final int? feedId = feed['feedId']; 
    
    // 태그 정보 가져오기
    final String tagCategory = feed['tagCategory'] ?? 'STUDY_CERTIFICATION';
    final String gradeCategory = feed['gradeCategory'] ?? 'MIDDLE';
    final String subjectCategory = feed['subjectCategory'] ?? 'MATH';
    
    // 태그 이름 찾기
    String tagName = '학습인증';
    if (tagCategory == 'HABIT_BUILDING') {
      tagName = '습관형성';
    } else if (tagCategory == 'INFORMATION') {
      tagName = '정보공유';
    }
    
    // 학년 이름 찾기
    String gradeName = '중학생';
    if (gradeCategory == 'ELEMENTARY') {
      gradeName = '초등학생';
    } else if (gradeCategory == 'HIGH') {
      gradeName = '고등학생';
    } else if (gradeCategory == 'ALL') {
      gradeName = '전체';
    }
    
    // 과목 이름 찾기
    String subjectName = '수학';
    if (subjectCategory == 'KOREAN') {
      subjectName = '국어';
    } else if (subjectCategory == 'ENGLISH') {
      subjectName = '영어';
    } else if (subjectCategory == 'SCIENCE') {
      subjectName = '과학';
    } else if (subjectCategory == 'SOCIETY') {
      subjectName = '사회';
    }
    
    // 시간 계산
    String timeAgo = '방금 전';
    if (feed['createdDate'] != null) {
      try {
        final DateTime createdDate = DateTime.parse(feed['createdDate']);
        final Duration difference = DateTime.now().difference(createdDate);
        
        if (difference.inDays > 0) {
          timeAgo = '${difference.inDays}일 전';
        } else if (difference.inHours > 0) {
          timeAgo = '${difference.inHours}시간 전';
        } else if (difference.inMinutes > 0) {
          timeAgo = '${difference.inMinutes}분 전';
        }
      } catch (e) {
        print('날짜 파싱 오류: $e');
      }
    }

    // 화면 너비 계산
    double screenWidth = MediaQuery.of(context).size.width;
    double textAreaWidth = screenWidth - 120; // 이미지(64) + 좌우 패딩(16+16) + 간격(24)
    double contentAreaWidth = screenWidth - 140; // 내용 부분은 더 짧게 설정

    return GestureDetector(
      onTap: feedId != null ? () {
        // 피드 상세 화면으로 이동
        Navigator.push(
          context, 
          MaterialPageRoute(
            builder: (context) => FeedDetailScreen(feedId: feedId),
          ),
        );
      } : null,
      child: Container(
        width: 240,
        height: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Color(0x35000000),
              blurRadius: 8,
              offset: Offset(3, 4),
              spreadRadius: 0,
            )
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 태그 섹션
            Container(
              height: 24,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  // 태그 카테고리
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    alignment: Alignment.center, // 컨텐츠 중앙 정렬
                    decoration: ShapeDecoration(
                      color: const Color(0xFFFFD27F),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(
                      tagName,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontFamily: 'Pretendard-Light',
                        letterSpacing: -0.22,
                        height: 1.0, // 줄 간격 조정으로 수직 중앙 정렬 지원
                      ),
                      textAlign: TextAlign.center, // 텍스트 중앙 정렬
                    ),
                  ),
                  const SizedBox(width: 10),
                  // 학년
                    Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    alignment: Alignment.center, // 컨텐츠 중앙 정렬
                    decoration: ShapeDecoration(
                      color: const Color(0xFFEFF2F6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(
                      gradeName,
                      style: TextStyle(
                        color: const Color(0xFF5D9EFF),
                        fontSize: 12,
                        fontFamily: 'Pretendard-Light',
                        letterSpacing: -0.22,
                        height: 1.0, // 줄 간격 조정으로 수직 중앙 정렬 지원
                      ),
                      textAlign: TextAlign.center, // 텍스트 중앙 정렬
                    ),
                  ),
                  const SizedBox(width: 10),
                  // 과목
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    alignment: Alignment.center, // 컨텐츠 중앙 정렬
                    decoration: ShapeDecoration(
                      color: const Color(0xFFEFF2F6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(
                      subjectName,
                      style: TextStyle(
                        color: const Color(0xFF5D9EFF),
                        fontSize: 12,
                        fontFamily: 'Pretendard-Light',
                        letterSpacing: -0.22,
                        height: 1.0, // 줄 간격 조정으로 수직 중앙 정렬 지원
                      ),
                      textAlign: TextAlign.center, // 텍스트 중앙 정렬
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            
            // 제목과 내용
            Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  // 제목
                  Container(
                    width: textAreaWidth - 30,
                      child: Text(
                        title,
                        style: TextStyle(
                        color: const Color(0xFF202020),
                        fontSize: 14,
                          fontFamily: 'Pretendard-Bold',
                        letterSpacing: -0.32,
                        ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 8),
                  // 내용
                  Container(
                    width: contentAreaWidth,
                      child: Text(
                        content,
                        style: TextStyle(
                        color: const Color(0xFF4A4A4A),
                        fontSize: 12,
                          fontFamily: 'Pretendard-Light',
                          height: 1.50,
                          letterSpacing: -0.24,
                        ),
                      maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  
                  // 이미지 섹션
                  if (imageUrls.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 12),
                      height: 44,
                      child: Row(
                        children: [
                          for (int i = 0; i < (imageUrls.length > 2 ? 2 : imageUrls.length); i++)
                            Container(
                              width: 44,
                              height: 44,
                              margin: EdgeInsets.only(right: i < 1 ? 8 : 0),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                image: DecorationImage(
                                  image: NetworkImage(imageUrls[i]),
                                  fit: BoxFit.cover,
                                ),
                      ),
                    ),
                  ],
                ),
              ),
                ],
              ),
            ),
            
            const SizedBox(height: 8),
            
            // 작성자 정보 (하단으로 이동)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                // 왼쪽: 프로필 이미지와 작성자 정보
                Row(
                  children: [
                    // 프로필 이미지 (원형)
                  Container(
                    width: 32,
                    height: 32,
                      margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                        color: const Color(0xFFEEEEEE),
                      image: profileImageUrl.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(profileImageUrl),
                            fit: BoxFit.cover,
                          )
                        : null,
                    ),
                  ),
                    // 작성자 이름과 시간
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                    children: [
                        // 작성자 이름
                      Text(
                        author,
                        style: TextStyle(
                            color: const Color(0xFF202020),
                            fontSize: 14,
                          fontFamily: 'Pretendard-Bold',
                          letterSpacing: -0.24,
                        ),
                      ),
                        // 시간
                      Row(
                        children: [
                          Text(
                            timeAgo,
                            style: TextStyle(
                              color: const Color(0xFF999999),
                                fontSize: 11,
                              fontFamily: 'Pretendard-Light',
                              letterSpacing: -0.18,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            width: 2,
                            height: 2,
                            decoration: const ShapeDecoration(
                              color: Color(0xFFC4C4C4),
                              shape: OvalBorder(),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '조회 $views명',
                            style: TextStyle(
                              color: const Color(0xFF999999),
                                fontSize: 11,
                              fontFamily: 'Pretendard-Light',
                              letterSpacing: -0.18,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
                
                // 오른쪽: 더보기 버튼 (오른쪽 하단에 위치)
                Image.asset(
                  'assets/icons/Icon/feed/세로점.png',
                  width: 25,
                  height: 25,
                  color: const Color(0xFF999999),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 각 과목별 인기 피드 섹션
  Widget _buildSubjectFeedsSection() {
    return Container(
      width: double.infinity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 섹션 제목
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  children: [
                    // 아이콘 추가
                    Container(
                      width: 24,
                      height: 24,
                      child: Image.asset(
                        'assets/images/닫기_노란색.png',
                        width: 24,
                        height: 24,
                        color: const Color(0xFFFFA63D),
                      ),
                    ),
                    const SizedBox(width: 4),
                    // 카테고리 (클릭 가능)
                    GestureDetector(
                      onTap: () => _showSubjectSelector(context),
                      child: Text(
                        _subjects[_selectedSubjectIndex],
                        style: TextStyle(
                          color: const Color(0xFFFFA63D),
                          fontSize: 18,
                          fontFamily: 'Pretendard-Bold',
                          decoration: TextDecoration.underline,
                          decorationColor: const Color(0xFFFFA63D),
                          height: 1.50,
                          letterSpacing: -0.80,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    // 제목 - 밑줄 제거
                    Text(
                      '에서 가장 인기있는 피드',
                      style: TextStyle(
                        color: const Color(0xFF202020),
                        fontSize: 18,
                        fontFamily: 'Pretendard-Bold',
                        height: 1.50,
                        letterSpacing: -0.80,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // 섹션 제목과 카드 사이에 간격 추가 (12px)
          const SizedBox(height: 12),
          
          // 로딩 중이거나 오류가 있는 경우 처리
                if (_isLoadingCategoryFeeds)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (_categoryFeedsError.isNotEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text(
                        _categoryFeedsError,
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 14,
                          fontFamily: 'Pretendard-Medium',
                        ),
                      ),
                    ),
                  )
                else if (_categoryFeeds.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Text(
                        '인기 피드가 없습니다',
                        style: TextStyle(
                          color: Color(0xFF999999),
                          fontSize: 14,
                          fontFamily: 'Pretendard-Medium',
                        ),
                      ),
                    ),
                  )
                else
            // 피드 카드 리스트 (가로 스크롤 적용)
                  Container(
                    width: double.infinity,
              height: 240, // 카드 높이에 맞게 조정
              padding: const EdgeInsets.only(left: 16),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _categoryFeeds.length,
                            itemBuilder: (context, index) {
                              return Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: _buildGradientFeedCard(_categoryFeeds[index]),
                  );
                },
            ),
          ),
        ],
      ),
    );
  }
  
  // 그라데이션 피드 카드 (수학 섹션)
  Widget _buildGradientFeedCard(dynamic feed) {
    final String title = feed['title'] ?? '';
    final String content = feed['content'] ?? '';
    final String author = feed['writerName'] ?? '';
    final String profileImageUrl = feed['writerProfileImageUrl'] ?? '';
    final int views = feed['viewCount'] ?? 0;
    final int? feedId = feed['feedId']; 
    final List<dynamic> imageUrls = feed['imageUrls'] ?? [];
    final bool hasImage = imageUrls.isNotEmpty;
    
    // 시간 계산
    String timeAgo = '방금 전';
    if (feed['createdDate'] != null) {
      try {
        final DateTime createdDate = DateTime.parse(feed['createdDate']);
        final Duration difference = DateTime.now().difference(createdDate);
        
        if (difference.inDays > 0) {
          timeAgo = '${difference.inDays}일 전';
        } else if (difference.inHours > 0) {
          timeAgo = '${difference.inHours}시간 전';
        } else if (difference.inMinutes > 0) {
          timeAgo = '${difference.inMinutes}분 전';
        }
      } catch (e) {
        print('날짜 파싱 오류: $e');
      }
    }

    // 화면 너비 계산
    double screenWidth = MediaQuery.of(context).size.width;
    double textAreaWidth = screenWidth - 120; // 이미지(64) + 좌우 패딩(16+16) + 간격(24)
    double contentAreaWidth = screenWidth - 140; // 내용 부분은 더 짧게 설정

    return GestureDetector(
      onTap: feedId != null ? () {
        // 피드 상세 화면으로 이동
        Navigator.push(
          context, 
          MaterialPageRoute(
            builder: (context) => FeedDetailScreen(feedId: feedId),
          ),
        );
      } : null,
      child: Container(
        width: 166,
        height: 230,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Color(0x35000000),
              blurRadius: 8,
              offset: Offset(3, 4),
              spreadRadius: 0,
            )
          ],
          image: hasImage 
            ? DecorationImage(
                image: NetworkImage(imageUrls[0]),
                fit: BoxFit.cover,
              )
            : null,
        ),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: ShapeDecoration(
            gradient: LinearGradient(
              begin: Alignment(0.04, 0.01),
              end: Alignment(1.00, 1.00),
              colors: [const Color(0x23146AFF), const Color(0x66146AFF)],
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 제목과 내용
              Container(
                width: 142,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 제목
                    SizedBox(
                      width: 142,
                      child: Text(
                        title,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontFamily: 'Pretendard-Bold',
                          letterSpacing: -0.28,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // 내용
                    SizedBox(
                      width: 142,
                      child: Text(
                        content,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontFamily: 'Pretendard-Light',
                          height: 1.50,
                          letterSpacing: -0.24,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              
              const Spacer(),
              
              // 작성자 정보
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 프로필 이미지
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFEEEEEE),
                      image: profileImageUrl.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(profileImageUrl),
                            fit: BoxFit.cover,
                          )
                        : null,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // 작성자 이름
                  Text(
                    author,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontFamily: 'Pretendard-Bold',
                      letterSpacing: -0.24,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // 시간, 조회수
                  Row(
                    children: [
                      Text(
                        timeAgo,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontFamily: 'Pretendard-Light',
                          letterSpacing: -0.22,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        width: 2,
                        height: 2,
                        decoration: const ShapeDecoration(
                          color: Colors.white,
                          shape: OvalBorder(),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '조회 $views명',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontFamily: 'Pretendard-Light',
                          letterSpacing: -0.22,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  // 태그 카테고리 인기 피드 섹션
  Widget _buildTagCategoryFeedsSection() {
    return Container(
      width: double.infinity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 섹션 제목
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  children: [
                    // 아이콘 추가
                    Container(
                      width: 24,
                      height: 24,
                      child: Image.asset(
                        'assets/images/닫기_노란색.png',
                        width: 24,
                        height: 24,
                        color: const Color(0xFFFFA63D),
                      ),
                    ),
                    const SizedBox(width: 4),
                    // 카테고리 (클릭 가능)
                    GestureDetector(
                      onTap: () => _showTagCategorySelector(context),
                      child: Text(
                        _tagCategories[_selectedTagIndex],
                        style: TextStyle(
                          color: const Color(0xFFFFA63D),
                          fontSize: 18,
                          fontFamily: 'Pretendard-Bold',
                          decoration: TextDecoration.underline,
                          decorationColor: const Color(0xFFFFA63D),
                          height: 1.50,
                          letterSpacing: -0.80,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    // 제목 - 밑줄 제거
                    Text(
                      '에서 가장 인기있는 피드',
                      style: TextStyle(
                        color: const Color(0xFF202020),
                        fontSize: 18,
                        fontFamily: 'Pretendard-Bold',
                        height: 1.50,
                        letterSpacing: -0.80,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // 섹션 제목과 카드 사이에 간격 추가 (24px)
          const SizedBox(height: 24),
          
          // 로딩 중이거나 오류가 있는 경우 처리
                if (_isLoadingTagCategoryFeeds)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (_tagCategoryFeedsError.isNotEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text(
                        _tagCategoryFeedsError,
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 14,
                          fontFamily: 'Pretendard-Medium',
                        ),
                      ),
                    ),
                  )
                else if (_tagCategoryFeeds.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Text(
                        '인기 피드가 없습니다',
                        style: TextStyle(
                          color: Color(0xFF999999),
                          fontSize: 14,
                          fontFamily: 'Pretendard-Medium',
                        ),
                      ),
                    ),
                  )
                else
            // 피드 카드 리스트 (세로 나열)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                  ..._tagCategoryFeeds.map((feed) {
                              return Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: _buildHorizontalFeedCard(feed),
                    );
                  }).toList(),
                  
                  // 마지막 카드 아래 빈 공간 추가 (200x150)
                              Container(
                    width: 200,
                    height: 100,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalFeedCard(dynamic feed) {
    final String title = feed['title'] ?? '';
    final String content = feed['content'] ?? '';
    final String author = feed['writerName'] ?? '';
    final String profileImageUrl = feed['writerProfileImageUrl'] ?? '';
    final List<dynamic> imageUrls = feed['imageUrls'] ?? [];
    final int helpfulCount = feed['likeCount'] ?? 0;
    final int commentCount = feed['commentCount'] ?? 0;
    final int? feedId = feed['feedId']; 
    
    // 태그 정보 가져오기
    final String tagCategory = feed['tagCategory'] ?? 'STUDY_CERTIFICATION';
    final String gradeCategory = feed['gradeCategory'] ?? 'MIDDLE';
    final String subjectCategory = feed['subjectCategory'] ?? 'MATH';
    
    // 태그 이름 찾기
    String tagName = '학습인증';
    if (tagCategory == 'HABIT_BUILDING') {
      tagName = '습관형성';
    } else if (tagCategory == 'INFORMATION') {
      tagName = '정보공유';
    }
    
    // 학년 이름 찾기
    String gradeName = '중학생';
    if (gradeCategory == 'ELEMENTARY') {
      gradeName = '초등학생';
    } else if (gradeCategory == 'HIGH') {
      gradeName = '고등학생';
    } else if (gradeCategory == 'ALL') {
      gradeName = '전체';
    }
    
    // 과목 이름 찾기
    String subjectName = '수학';
    if (subjectCategory == 'KOREAN') {
      subjectName = '국어';
    } else if (subjectCategory == 'ENGLISH') {
      subjectName = '영어';
    } else if (subjectCategory == 'SCIENCE') {
      subjectName = '과학';
    } else if (subjectCategory == 'SOCIETY') {
      subjectName = '사회';
    }
    
    // 시간 계산
    String timeAgo = '방금 전';
    if (feed['createdDate'] != null) {
      try {
        final DateTime createdDate = DateTime.parse(feed['createdDate']);
        final Duration difference = DateTime.now().difference(createdDate);
        
        if (difference.inDays > 0) {
          timeAgo = '${difference.inDays}일 전';
        } else if (difference.inHours > 0) {
          timeAgo = '${difference.inHours}시간 전';
        } else if (difference.inMinutes > 0) {
          timeAgo = '${difference.inMinutes}분 전';
        }
      } catch (e) {
        print('날짜 파싱 오류: $e');
      }
    }

    // 화면 너비 계산
    double screenWidth = MediaQuery.of(context).size.width;
    double textAreaWidth = screenWidth - 120; // 이미지(64) + 좌우 패딩(16+16) + 간격(24)
    double contentAreaWidth = screenWidth - 160; // 내용 부분은 더 짧게 설정

    return GestureDetector(
      onTap: feedId != null ? () {
        // 피드 상세 화면으로 이동
        Navigator.push(
          context, 
          MaterialPageRoute(
            builder: (context) => FeedDetailScreen(feedId: feedId),
          ),
        );
      } : null,
      child: Container(
        width: double.infinity,
        height: 170, // 높이 증가
        decoration: ShapeDecoration(
          color: Colors.white,
          shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Stack(
                      children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                  // 태그 섹션
                  SizedBox(
                    height: 28,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        // 태그 카테고리
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          alignment: Alignment.center, // 컨텐츠 중앙 정렬
                          decoration: ShapeDecoration(
                            color: const Color(0xFFFFD27F),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Text(
                            tagName,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              fontFamily: 'Pretendard-Light',
                              letterSpacing: -0.22,
                              height: 1.0, // 줄 간격 조정으로 수직 중앙 정렬 지원
                            ),
                            textAlign: TextAlign.center, // 텍스트 중앙 정렬
                          ),
                        ),
                        const SizedBox(width: 10),
                        // 학년
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          alignment: Alignment.center, // 컨텐츠 중앙 정렬
                          decoration: ShapeDecoration(
                            color: const Color(0xFFEFF2F6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Text(
                            gradeName,
                                  style: TextStyle(
                              color: const Color(0xFF5D9EFF),
                              fontSize: 12,
                                    fontFamily: 'Pretendard-Light',
                              letterSpacing: -0.22,
                              height: 1.0, // 줄 간격 조정으로 수직 중앙 정렬 지원
                                  ),
                            textAlign: TextAlign.center, // 텍스트 중앙 정렬
                                ),
                        ),
                        const SizedBox(width: 10),
                        // 과목
                                Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          alignment: Alignment.center, // 컨텐츠 중앙 정렬
                          decoration: ShapeDecoration(
                            color: const Color(0xFFEFF2F6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Text(
                            subjectName,
                                  style: TextStyle(
                              color: const Color(0xFF5D9EFF),
                              fontSize: 12,
                                    fontFamily: 'Pretendard-Light',
                              letterSpacing: -0.22,
                              height: 1.0, // 줄 간격 조정으로 수직 중앙 정렬 지원
                                  ),
                            textAlign: TextAlign.center, // 텍스트 중앙 정렬
                                ),
                            ),
                          ],
                        ),
                    ),
                  const SizedBox(height: 12),
            
                  // 제목 - 너비 제한
            Container(
                    width: textAreaWidth - 30,
                    child: Text(
                      title,
                      style: TextStyle(
                        color: const Color(0xFF202020),
                        fontSize: 14,
                        fontFamily: 'Pretendard-Bold',
                        letterSpacing: -0.32,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // 내용 - 너비 제한
                  Container(
                    width: contentAreaWidth,
                    child: Text(
                      content,
                      style: TextStyle(
                        color: const Color(0xFF4A4A4A),
                        fontSize: 12,
                        fontFamily: 'Pretendard-Light',
                        height: 1.50,
                        letterSpacing: -0.24,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  
                  // 공간을 활용하기 위한 빈 공간
                  const Spacer(),
                  
                  // 하단 정보 (시간, 좋아요, 댓글)
                  Row(
              children: [
                      // 시간
                      Text(
                        timeAgo,
                    style: TextStyle(
                          color: const Color(0xFF999999),
                          fontSize: 11,
                          fontFamily: 'Pretendard-Light',
                          letterSpacing: -0.22,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        width: 2,
                        height: 2,
                        decoration: const ShapeDecoration(
                          color: Color(0xFFC4C4C4),
                          shape: OvalBorder(),
                        ),
                      ),
                      const SizedBox(width: 4),
                      // 도움이 됐어요
                              Text(
                        '도움이 됐어요 $helpfulCount명',
                                style: TextStyle(
                          color: const Color(0xFF999999),
                          fontSize: 11,
                          fontFamily: 'Pretendard-Light',
                          letterSpacing: -0.22,
                        ),
                      ),
                      const SizedBox(width: 4),
                                Container(
                        width: 2,
                                  height: 2,
                        decoration: const ShapeDecoration(
                          color: Color(0xFFC4C4C4),
                          shape: OvalBorder(),
                        ),
                      ),
                      const SizedBox(width: 4),
                      // 댓글 수
                      Text(
                        '댓글 $commentCount명',
                        style: TextStyle(
                          color: const Color(0xFF999999),
                          fontSize: 11,
                          fontFamily: 'Pretendard-Light',
                          letterSpacing: -0.22,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // 더보기 버튼 (오른쪽 상단)
            Positioned(
              right: 16,
              top: 16,
              child: Image.asset(
                'assets/icons/Icon/feed/세로점.png',
                width: 20,
                height: 20,
                color: const Color(0xFF999999),
              ),
            ),
            
            // 이미지 (오른쪽 하단)
            Positioned(
              right: 16,
              bottom: 16, // 하단에 맞춤
              child: imageUrls.isNotEmpty
                ? Container(
                    width: 64,
                    height: 64,
            decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(
                        image: NetworkImage(imageUrls[0]),
                        fit: BoxFit.cover,
                      ),
                    ),
                  )
                : Container(
                    width: 64,
                    height: 64,
                          decoration: BoxDecoration(
                      color: const Color(0xFFD9D9D9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
    );
  }
} 