import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../services/feed_service.dart';
import '../../services/auth_service.dart';
import '../child/feed_screen.dart';
import '../../models/feed_data.dart';

class EditFeedScreen extends StatefulWidget {
  final int feedId;
  final String title;
  final String? content;
  final String gradeCategory;
  final String subjectCategory;
  final String tagCategory;
  final List<String> imageUrls;

  const EditFeedScreen({
    Key? key,
    required this.feedId,
    required this.title,
    required this.content,
    required this.gradeCategory,
    required this.subjectCategory,
    required this.tagCategory,
    required this.imageUrls,
  }) : super(key: key);

  @override
  _EditFeedScreenState createState() => _EditFeedScreenState();
}

class _EditFeedScreenState extends State<EditFeedScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // 텍스트 컨트롤러 추가
  late TextEditingController _titleController;
  late TextEditingController _contentController;

  int _selectedGradeIndex = 0;
  int _selectedSubjectIndex = 0;
  int _selectedTagIndex = 0;

  final List<String> _grades = ['초등학생', '중등학생', '고등학생', '전체'];
  final List<String> _subjects = ['국어', '수학', '영어', '사회', '과학', '전체'];
  final List<String> _tags = ['학습인증', '습관형성', '정보공유', '전체'];

  final ImagePicker _picker = ImagePicker();
  final List<File> _selectedImages = [];
  List<String> _existingImageUrls = [];
  final int _maxImages = 3;

  // 로딩 상태 변수 추가
  bool _isLoading = false;

  // 글로벌 색상 변수
  final Color _primaryColor = const Color(0xFF0047AB);
  final Color _lightBlueColor = const Color(0xFFE9F1FF);
  final Color _borderColor = const Color(0xFF5D9EFF);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.index = 0;

    // 기존 데이터로 초기화
    _titleController = TextEditingController(text: widget.title);
    _contentController = TextEditingController(text: widget.content ?? '');
    _existingImageUrls = List.from(widget.imageUrls);
    
    // 카테고리 인덱스 초기화
    _initCategories();

    // 탭 변경 리스너 추가
    _tabController.addListener(() {
      if (_tabController.index == 1) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const FeedScreen(initialTab: 1),
          ),
        );
      }
    });
  }

  // 카테고리 인덱스 초기화
  void _initCategories() {
    // 학년 카테고리
    switch (widget.gradeCategory) {
      case 'ELEMENTARY':
        _selectedGradeIndex = 0;
        break;
      case 'MIDDLE':
        _selectedGradeIndex = 1;
        break;
      case 'HIGH':
        _selectedGradeIndex = 2;
        break;
      default:
        _selectedGradeIndex = 3; // ALL
        break;
    }

    // 과목 카테고리
    switch (widget.subjectCategory) {
      case 'KOREAN':
        _selectedSubjectIndex = 0;
        break;
      case 'MATH':
        _selectedSubjectIndex = 1;
        break;
      case 'ENGLISH':
        _selectedSubjectIndex = 2;
        break;
      case 'SOCIETY':
        _selectedSubjectIndex = 3;
        break;
      case 'SCIENCE':
        _selectedSubjectIndex = 4;
        break;
      default:
        _selectedSubjectIndex = 5; // ALL
        break;
    }

    // 태그 카테고리
    switch (widget.tagCategory) {
      case 'STUDY_CERTIFICATION':
        _selectedTagIndex = 0;
        break;
      case 'HABIT_BUILDING':
        _selectedTagIndex = 1;
        break;
      case 'INFORMATION':
        _selectedTagIndex = 2;
        break;
      default:
        _selectedTagIndex = 3; // ALL
        break;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  // 카테고리 매핑 함수
  String _mapGradeCategory(int index) {
    switch (index) {
      case 0: return 'ELEMENTARY';
      case 1: return 'MIDDLE';
      case 2: return 'HIGH';
      default: return 'ALL';
    }
  }

  String _mapSubjectCategory(int index) {
    switch (index) {
      case 0: return 'KOREAN';
      case 1: return 'MATH';
      case 2: return 'ENGLISH';
      case 3: return 'SOCIETY';
      case 4: return 'SCIENCE';
      default: return 'ALL';
    }
  }

  String _mapTagCategory(int index) {
    switch (index) {
      case 0: return 'STUDY_CERTIFICATION';
      case 1: return 'HABIT_BUILDING';
      case 2: return 'INFORMATION';
      default: return 'ALL';
    }
  }

  // 피드 수정 함수
  Future<void> _updateFeed() async {
    // 제목 유효성 검사
    if (_titleController.text.trim().isEmpty) {
      _showSnackBar('제목을 입력해 주세요');
      return;
    }

    // 내용 유효성 검사 (10자 이상)
    if (_contentController.text.trim().length < 10) {
      _showSnackBar('내용은 최소 10자 이상 입력해 주세요');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 이미지 처리 - 기존 이미지와 새로 추가한 이미지 통합
      final List<Map<String, String>> imageUrls = [];
      
      // 기존 이미지 URL 추가
      for (final url in _existingImageUrls) {
        imageUrls.add({'url': url});
      }
      
      // 새로 추가한 이미지 업로드 및 URL 추가
      if (_selectedImages.isNotEmpty) {
        for (final file in _selectedImages) {
          final imagePath = await AuthService.uploadProfileImage(file);
          imageUrls.add({'url': AuthService.getFullProfileImageUrl(imagePath)});
        }
      }

      // 피드 수정 API 호출
      final result = await FeedService.updateFeed(
        feedId: widget.feedId,
        title: _titleController.text.trim(),
        gradeCategory: _mapGradeCategory(_selectedGradeIndex),
        subjectCategory: _mapSubjectCategory(_selectedSubjectIndex),
        tagCategory: _mapTagCategory(_selectedTagIndex),
        content: _contentController.text.trim(),
        images: imageUrls,
      );

      setState(() {
        _isLoading = false;
      });

      if (result != null) {
        _showSnackBar('피드가 성공적으로 수정되었습니다');
        Navigator.pop(context, true); // 성공 결과를 전달하며 이전 화면으로 이동
      } else {
        _showSnackBar('피드 수정에 실패했습니다');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('오류가 발생했습니다: $e');
    }
  }

  // 스낵바 표시 함수
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontFamily: 'Pretendard'),
        ),
        backgroundColor: _primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Future<void> _showImageSourceDialog() async {
    if (_existingImageUrls.length + _selectedImages.length >= _maxImages) {
      _showSnackBar('최대 $_maxImages장까지 업로드할 수 있습니다.');
      return;
    }
    
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: Colors.white,
          title: Text(
            '사진 업로드',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Pretendard',
            ),
          ),
          children: [
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context);
                _getImage(ImageSource.camera);
              },
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  Icon(Icons.camera_alt, color: _primaryColor, size: 20),
                  const SizedBox(width: 16),
                  Text(
                    '카메라로 찍기',
                    style: TextStyle(
                      fontSize: 15,
                      fontFamily: 'Pretendard',
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context);
                _getImage(ImageSource.gallery);
              },
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  Icon(Icons.photo_library, color: _primaryColor, size: 20),
                  const SizedBox(width: 16),
                  Text(
                    '갤러리에서 선택',
                    style: TextStyle(
                      fontSize: 15,
                      fontFamily: 'Pretendard',
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _getImage(ImageSource source) async {
    if (_existingImageUrls.length + _selectedImages.length >= _maxImages) {
      _showSnackBar('최대 $_maxImages장까지 업로드할 수 있습니다.');
      return;
    }

    final XFile? pickedFile = await _picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _selectedImages.add(File(pickedFile.path));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(110),
        child: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          title: const Text(
            '글 수정하기',
            style: TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Pretendard',
            ),
          ),
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios,
              color: Colors.black,
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: Colors.white,
                child: ClipOval(
                  child: Image.asset(
                    'assets/logos/search-sm.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.notifications_none_outlined,
                color: Colors.black,
              ),
              onPressed: () {},
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Column(
              children: [
                const SizedBox(height: 8),
                TabBar(
                  controller: _tabController,
                  labelColor: _primaryColor,
                  unselectedLabelColor: Colors.grey[400],
                  indicatorColor: _primaryColor,
                  indicatorWeight: 2,
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Pretendard',
                    fontSize: 15,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 15,
                  ),
                  tabs: const [Tab(text: '피드'), Tab(text: '랭킹')],
                ),
                Divider(height: 1, color: Colors.grey[200]),
              ],
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),

                  // 제목 입력
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                    child: Material(
                      elevation: 2,
                      shadowColor: Colors.grey.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _borderColor.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: TextField(
                          controller: _titleController,
                          decoration: InputDecoration(
                            hintText: '제목을 입력해 주세요',
                            hintStyle: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 15,
                              fontFamily: 'Pretendard',
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            isDense: true,
                          ),
                          style: const TextStyle(
                            fontSize: 15,
                            fontFamily: 'Pretendard',
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 글카테고리 선택
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      '글카테고리를 선택해 주세요',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        fontFamily: 'Pretendard',
                        color: _primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: List.generate(
                        _grades.length,
                        (index) => Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedGradeIndex = index;
                              });
                            },
                            child: _buildCategoryChip(
                              _grades[index],
                              _selectedGradeIndex == index,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 과목 카테고리 선택
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      '과목 카테고리를 선택해 주세요',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        fontFamily: 'Pretendard',
                        color: _primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: List.generate(
                        _subjects.length,
                        (index) => Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedSubjectIndex = index;
                              });
                            },
                            child: _buildCategoryChip(
                              _subjects[index],
                              _selectedSubjectIndex == index,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 태그 카테고리 선택 추가
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      '태그 카테고리를 선택해 주세요',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        fontFamily: 'Pretendard',
                        color: _primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: List.generate(
                        _tags.length,
                        (index) => Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedTagIndex = index;
                              });
                            },
                            child: _buildCategoryChip(
                              _tags[index],
                              _selectedTagIndex == index,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 본문 입력
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                    child: Material(
                      elevation: 2,
                      shadowColor: Colors.grey.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _borderColor.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: TextField(
                          controller: _contentController,
                          maxLines: 10,
                          minLines: 10,
                          decoration: InputDecoration(
                            hintText: '최소 10자 이상 입력해 주세요',
                            hintStyle: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 15,
                              fontFamily: 'Pretendard',
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            isDense: true,
                          ),
                          style: const TextStyle(
                            fontSize: 15,
                            fontFamily: 'Pretendard',
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 이미지 첨부
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                    child: Row(
                      children: [
                        Material(
                          elevation: 2,
                          shadowColor: Colors.grey.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                          child: InkWell(
                            onTap: _showImageSourceDialog,
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              width: 64,
                              height: 64,
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: _borderColor.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.camera_alt_outlined,
                                    color: _primaryColor,
                                    size: 24,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${_existingImageUrls.length + _selectedImages.length}/$_maxImages',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: _primaryColor,
                                      fontFamily: 'Pretendard',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        
                        // 이미지 목록 표시
                        Expanded(
                          child: SizedBox(
                            height: 64,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              children: [
                                // 기존 이미지 표시
                                ..._existingImageUrls.asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final url = entry.value;
                                  
                                  return Padding(
                                    padding: const EdgeInsets.only(left: 12.0),
                                    child: Stack(
                                      children: [
                                        Material(
                                          elevation: 2,
                                          shadowColor: Colors.grey.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(10),
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(10),
                                              border: Border.all(
                                                color: _borderColor.withOpacity(0.3),
                                                width: 1,
                                              ),
                                            ),
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(9),
                                              child: Image.network(
                                                url,
                                                height: 64,
                                                width: 64,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          right: -5,
                                          top: -5,
                                          child: InkWell(
                                            onTap: () {
                                              setState(() {
                                                _existingImageUrls.removeAt(index);
                                              });
                                            },
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: _primaryColor,
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: Colors.white,
                                                  width: 1.5,
                                                ),
                                              ),
                                              padding: const EdgeInsets.all(4),
                                              child: const Icon(
                                                Icons.close,
                                                size: 10,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                
                                // 새로 추가한 이미지 표시
                                ..._selectedImages.asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final file = entry.value;
                                  
                                  return Padding(
                                    padding: const EdgeInsets.only(left: 12.0),
                                    child: Stack(
                                      children: [
                                        Material(
                                          elevation: 2,
                                          shadowColor: Colors.grey.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(10),
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(10),
                                              border: Border.all(
                                                color: _borderColor.withOpacity(0.3),
                                                width: 1,
                                              ),
                                            ),
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(9),
                                              child: Image.file(
                                                file,
                                                height: 64,
                                                width: 64,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          right: -5,
                                          top: -5,
                                          child: InkWell(
                                            onTap: () {
                                              setState(() {
                                                _selectedImages.removeAt(index);
                                              });
                                            },
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: _primaryColor,
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: Colors.white,
                                                  width: 1.5,
                                                ),
                                              ),
                                              padding: const EdgeInsets.all(4),
                                              child: const Icon(
                                                Icons.close,
                                                size: 10,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // 수정 완료 버튼
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                    child: Material(
                      elevation: 3,
                      shadowColor: _primaryColor.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _updateFeed,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF146AFF),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            disabledBackgroundColor: Colors.grey[400],
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  '수정 완료',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Pretendard',
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label, bool isSelected) {
    return Material(
      elevation: isSelected ? 2 : 0.5,
      shadowColor: Colors.grey.withOpacity(0.2),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.grey[50],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? _primaryColor : Colors.grey[300]!,
            width: isSelected ? 1.5 : 0.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? _primaryColor : Colors.grey[700],
            fontSize: 14,
            fontFamily: 'Pretendard',
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
} 