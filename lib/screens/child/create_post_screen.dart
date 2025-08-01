import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../services/feed_service.dart';
import '../../services/auth_service.dart';
import 'feed_screen.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  _CreatePostScreenState createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _userProfileImageUrl;

  // 텍스트 컨트롤러 추가
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  int _selectedGradeIndex = 0;
  int _selectedSubjectIndex = 1;
  int _selectedTagIndex = 0; // 태그 카테고리 인덱스 추가

  final List<String> _grades = ['초등학생', '중등학생', '고등학생', '전체'];
  final List<String> _subjects = ['국어', '수학', '영어', '사회', '과학', '전체'];
  final List<String> _tags = ['학습인증', '습관형성', '전체']; // 태그 카테고리 추가

  final ImagePicker _picker = ImagePicker();
  final List<File> _selectedImages = [];
  final int _maxImages = 3;

  // 로딩 상태 변수 추가
  bool _isLoading = false;

  // 글로벌 색상 변수
  final Color _primaryColor = const Color(0xFF0047AB); // 주 색상으로 파란색 사용
  final Color _lightBlueColor = const Color(0xFFE9F1FF);
  final Color _borderColor = const Color(0xFF5D9EFF);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.index = 0;

    // 사용자 프로필 이미지 가져오기
    _loadUserProfileImage();

    // 탭 변경 리스너 추가
    _tabController.addListener(() {
      // 랭킹 탭이 선택되었을 때 (탭 인덱스 1)
      if (_tabController.index == 1) {
        // 랭킹 탭으로 이동 (FeedScreen의 랭킹 탭)
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const FeedScreen(initialTab: 1),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  // 카테고리 매핑 함수 추가
  String _mapGradeCategory(int index) {
    switch (index) {
      case 0:
        return 'ELEMENTARY';
      case 1:
        return 'MIDDLE';
      case 2:
        return 'HIGH';
      case 3:
        return 'ALL';
      default:
        return 'ALL';
    }
  }

  String _mapSubjectCategory(int index) {
    switch (index) {
      case 0:
        return 'KOREAN';
      case 1:
        return 'MATH';
      case 2:
        return 'ENGLISH';
      case 3:
        return 'SOCIETY';
      case 4:
        return 'SCIENCE';
      case 5:
        return 'ALL';
      default:
        return 'ALL';
    }
  }

  String _mapTagCategory(int index) {
    switch (index) {
      case 0:
        return 'STUDY_CERTIFICATION';
      case 1:
        return 'HABIT_BUILDING';
      default:
        return 'ALL';
    }
  }

  // 피드 제출 함수 추가
  Future<void> _submitFeed() async {
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
      // 이미지 업로드 처리 (여기서는 간단하게 이미지 URL 배열만 생성)
      final List<Map<String, String>> imageUrls = [];
      if (_selectedImages.isNotEmpty) {
        for (final file in _selectedImages) {
          // 실제 구현에서는 이미지 업로드 후 URL을 받아 추가해야 함
          // 예시로 임시 URL 사용
          final imagePath = await AuthService.uploadProfileImage(file);
          imageUrls.add({'url': AuthService.getFullProfileImageUrl(imagePath)});
        }
      }

      // 피드 생성 API 호출
      final result = await FeedService.createFeed(
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
        _showSnackBar('피드가 성공적으로 생성되었습니다');
        // 피드 화면으로 이동 (피드 탭 선택)
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const FeedScreen(initialTab: 0),
          ),
        );
      } else {
        _showSnackBar('피드 생성에 실패했습니다');
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
              fontSize: 14,
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
                      fontSize: 11,
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
                      fontSize: 11,
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
    if (_selectedImages.length >= _maxImages) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '최대 $_maxImages장까지 업로드할 수 있습니다.',
            style: const TextStyle(fontFamily: 'Pretendard'),
          ),
          backgroundColor: _primaryColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }

    final XFile? pickedFile = await _picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _selectedImages.add(File(pickedFile.path));
      });
    }
  }

  // 사용자 프로필 이미지 로드 함수
  Future<void> _loadUserProfileImage() async {
    try {
      final userInfo = await AuthService.getUserInfo();
      if (userInfo['profileImagePath'] != null) {
        setState(() {
          _userProfileImageUrl = AuthService.getFullProfileImageUrl(
            userInfo['profileImagePath'],
          );
        });
      }
    } catch (e) {
      print('프로필 이미지 로딩 오류: $e');
    }
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
          '피드 작성',
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontFamily: 'Pretendard-Bold',
          ),
        ),
        leading: IconButton(
          icon: Image.asset(
            'assets/icons/Icon/feed/뒤로가기.png',
            width: 24,
            height: 24,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              child: SizedBox(
                width: MediaQuery.of(context).size.width,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '사진으로 자랑하고 싶은 순간을 공유해 보세요',
                      style: TextStyle(
                        color: const Color(0xFF202020),
                        fontSize: 14,
                        fontFamily: 'Pretendard-Bold',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '나만의 공부 방법과 꿀팁을 사진으로 기록할 수 있어요!',
                            style: TextStyle(
                              color: const Color(0xFF999999),
                              fontSize: 11,
                              fontFamily: 'Pretendard-Light',
                            ),
                          ),
                        ),
                        Text(
                          '(선택사항)',
                          style: TextStyle(
                            color: const Color(0xFFC4C4C4),
                            fontSize: 9,
                            fontFamily: 'Pretendard-Light',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 이미지 첨부 버튼들
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          // 촬영 버튼
                          GestureDetector(
                            onTap: _showImageSourceDialog,
                            child: Container(
                              width: 68,
                              height: 70, // 높이 명시
                              padding: const EdgeInsets.all(8), // 패딩 줄임
                              margin: const EdgeInsets.only(right: 16),
                              decoration: ShapeDecoration(
                                color: const Color(0xFFEFF2F6),
                                shape: RoundedRectangleBorder(
                                  side: BorderSide(
                                    width: 1,
                                    color: const Color(0xFF3A88F4),
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Center(
                                // 가운데 정렬을 위해 Center 추가
                                child: Column(
                                  mainAxisSize: MainAxisSize.min, // 최소 크기로 설정
                                  mainAxisAlignment:
                                      MainAxisAlignment.center, // 가운데 정렬
                                  crossAxisAlignment:
                                      CrossAxisAlignment.center, // 가운데 정렬
                                  children: [
                                    Container(
                                      width: 28,
                                      height: 28,
                                      clipBehavior: Clip.antiAlias,
                                      decoration: BoxDecoration(),
                                      child: Image.asset(
                                        'assets/icons/Icon/feed/촬영.png',
                                        fit: BoxFit.contain, // 이미지 맞춤
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text.rich(
                                      TextSpan(
                                        children: [
                                          TextSpan(
                                            text: '${_selectedImages.length}/',
                                            style: TextStyle(
                                              color: const Color(0xFF666666),
                                              fontSize: 9,
                                              fontFamily: 'Pretendard-Light',
                                              letterSpacing: -0.24,
                                            ),
                                          ),
                                          TextSpan(
                                            text: '$_maxImages',
                                            style: TextStyle(
                                              color: const Color(0xFF666666),
                                              fontSize: 9,
                                              fontFamily: 'Pretendard-Medium',
                                              letterSpacing: -0.24,
                                            ),
                                          ),
                                        ],
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // 갤러리 버튼 (사진이 없을 때만 표시)
                          if (_selectedImages.isEmpty)
                            GestureDetector(
                              onTap: () {
                                _getImage(ImageSource.gallery);
                              },
                              child: Container(
                                width: 68,
                                height: 70,
                                padding: const EdgeInsets.all(8),
                                decoration: ShapeDecoration(
                                  color: const Color(0xFFEFF2F6),
                                  shape: RoundedRectangleBorder(
                                    side: BorderSide(
                                      width: 1,
                                      color: const Color(0xFF3A88F4),
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 28,
                                        height: 28,
                                        clipBehavior: Clip.antiAlias,
                                        decoration: BoxDecoration(),
                                        child: Image.asset(
                                          'assets/icons/Icon/feed/앨범.png',
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text.rich(
                                        TextSpan(
                                          children: [
                                            TextSpan(
                                              text:
                                                  '${_selectedImages.length}/',
                                              style: TextStyle(
                                                color: const Color(0xFF666666),
                                                fontSize: 9,
                                                fontFamily: 'Pretendard-Light',
                                                letterSpacing: -0.24,
                                              ),
                                            ),
                                            TextSpan(
                                              text: '$_maxImages',
                                              style: TextStyle(
                                                color: const Color(0xFF666666),
                                                fontSize: 9,
                                                fontFamily: 'Pretendard-Medium',
                                                letterSpacing: -0.24,
                                              ),
                                            ),
                                          ],
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                          // 선택된 이미지들 표시
                          ...List.generate(
                            _selectedImages.length,
                            (index) => GestureDetector(
                              onTap: () {
                                // 이미지 미리보기 또는 수정 기능 추가 가능
                              },
                              child: Stack(
                                children: [
                                  Container(
                                    width: 68,
                                    height: 70,
                                    margin: const EdgeInsets.only(right: 16),
                                    decoration: ShapeDecoration(
                                      color: const Color(0xFFEFF2F6),
                                      shape: RoundedRectangleBorder(
                                        side: BorderSide(
                                          width: 1,
                                          color: const Color(0xFF3A88F4),
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(11),
                                      child: Image.file(
                                        _selectedImages[index],
                                        fit: BoxFit.cover, // 이미지가 컨테이너에 꽉 차게
                                        width: 68,
                                        height: 70,
                                      ),
                                    ),
                                  ),
                                  // 삭제 버튼
                                  Positioned(
                                    top: 0,
                                    right: 16,
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _selectedImages.removeAt(index);
                                        });
                                      },
                                      child: Image.asset(
                                        'assets/icons/Icon/feed/삭제_버튼형.png',
                                        width: 20,
                                        height: 20,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // 추가 버튼 (이미지가 최대 개수보다 적을 때만 표시)
                          if (_selectedImages.isNotEmpty &&
                              _selectedImages.length < _maxImages)
                            GestureDetector(
                              onTap: () {
                                _getImage(ImageSource.gallery);
                              },
                              child: Container(
                                width: 68,
                                height: 70,
                                padding: const EdgeInsets.all(8),
                                decoration: ShapeDecoration(
                                  color: const Color(0xFFEFF2F6),
                                  shape: RoundedRectangleBorder(
                                    side: BorderSide(
                                      width: 1,
                                      color: const Color(0xFF3A88F4),
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 28,
                                        height: 28,
                                        child: Icon(
                                          Icons.add_circle_outline,
                                          color: const Color(0xFF666666),
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text.rich(
                                        TextSpan(
                                          children: [
                                            TextSpan(
                                              text:
                                                  '${_selectedImages.length}/',
                                              style: TextStyle(
                                                color: const Color(0xFF666666),
                                                fontSize: 9,
                                                fontFamily: 'Pretendard-Light',
                                                letterSpacing: -0.24,
                                              ),
                                            ),
                                            TextSpan(
                                              text: '$_maxImages',
                                              style: TextStyle(
                                                color: const Color(0xFF666666),
                                                fontSize: 9,
                                                fontFamily: 'Pretendard-Medium',
                                                letterSpacing: -0.24,
                                              ),
                                            ),
                                          ],
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // 2. 피드 제목을 입력해 주세요
                    Text(
                      '피드 제목을 입력해 주세요',
                      style: TextStyle(
                        color: const Color(0xFF202020),
                        fontSize: 14,
                        fontFamily: 'Pretendard-Bold',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '친구에게 알려주고 싶은',
                      style: TextStyle(
                        color: const Color(0xFF999999),
                        fontSize: 11,
                        fontFamily: 'Pretendard-Light',
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 제목 입력 필드
                    Container(
                      width: double.infinity,
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: ShapeDecoration(
                        color: const Color(0xFFF0F2F7),
                        shape: RoundedRectangleBorder(
                          side: BorderSide(
                            width: 1.20,
                            color: const Color(0xFF3A88F4),
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _titleController,
                              textAlignVertical: TextAlignVertical.center,
                              decoration: InputDecoration(
                                hintText: '피드의 제목을 작성해주세요',
                                hintStyle: TextStyle(
                                  color: const Color(0xFF666666),
                                  fontSize: 12,
                                  fontFamily: 'Pretendard-Light',
                                ),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                disabledBorder: InputBorder.none,
                                errorBorder: InputBorder.none,
                                focusedErrorBorder: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                                isDense: true,
                                fillColor: const Color(0xFFF0F2F7),
                                filled: true,
                              ),
                              style: TextStyle(
                                color: const Color(0xFF666666),
                                fontSize: 11,
                                fontFamily: 'Pretendard-Light',
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              // 제목 텍스트 지우기
                              _titleController.clear();
                            },
                            child: Image.asset(
                              'assets/icons/Icon/feed/삭제_버튼형.png',
                              width: 24,
                              height: 24,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // 3. 이 피드를 누구에게 보여줄까요?
                    Text(
                      '이 피드를 누구에게 보여줄까요?',
                      style: TextStyle(
                        color: const Color(0xFF202020),
                        fontSize: 14,
                        fontFamily: 'Pretendard-Bold',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '공유할 학년군을 선택해 주세요!',
                      style: TextStyle(
                        color: const Color(0xFF999999),
                        fontSize: 11,
                        fontFamily: 'Pretendard-Light',
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 학년 선택 버튼들
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: List.generate(
                          _grades.length,
                          (index) => Padding(
                            padding: EdgeInsets.only(
                              right: index < _grades.length - 1 ? 16 : 0,
                            ),
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedGradeIndex = index;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                decoration: ShapeDecoration(
                                  color:
                                      _selectedGradeIndex == index
                                          ? const Color(0xFF3A88F4)
                                          : const Color(0xFFEFF2F6),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                child: Text(
                                  _grades[index],
                                  style: TextStyle(
                                    color:
                                        _selectedGradeIndex == index
                                            ? Colors.white
                                            : const Color(0xFF5D9EFF),
                                    fontSize: 11,
                                    fontFamily:
                                        _selectedGradeIndex == index
                                            ? 'Pretendard-Medium'
                                            : 'Pretendard-Light',
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // 4. 어떤 과목을 공부하는 친구들에게 보여줄까요?
                    Text(
                      '어떤 과목을 공부하는 친구들에게 보여줄까요?',
                      style: TextStyle(
                        color: const Color(0xFF202020),
                        fontSize: 14,
                        fontFamily: 'Pretendard-Bold',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '같은 과목을 고민 중인 친구들에게 보여줄게요!',
                            style: TextStyle(
                              color: const Color(0xFF999999),
                              fontSize: 11,
                              fontFamily: 'Pretendard-Light',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 과목 선택 버튼들 (첫 번째 행)
                    Row(
                      children: [
                        for (int i = 0; i < 3; i++)
                          Padding(
                            padding: EdgeInsets.only(right: i < 2 ? 16 : 0),
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedSubjectIndex = i;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                decoration: ShapeDecoration(
                                  color:
                                      _selectedSubjectIndex == i
                                          ? const Color(0xFF5D9EFF)
                                          : const Color(0xFFEFF2F6),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                child: Text(
                                  _subjects[i],
                                  style: TextStyle(
                                    color:
                                        _selectedSubjectIndex == i
                                            ? Colors.white
                                            : const Color(0xFF5D9EFF),
                                    fontSize: 11,
                                    fontFamily:
                                        _selectedSubjectIndex == i
                                            ? 'Pretendard-Medium'
                                            : 'Pretendard-Light',
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // 과목 선택 버튼들 (두 번째 행)
                    Row(
                      children: [
                        for (int i = 3; i < 5; i++)
                          Padding(
                            padding: EdgeInsets.only(right: i < 4 ? 16 : 0),
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedSubjectIndex = i;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                decoration: ShapeDecoration(
                                  color:
                                      _selectedSubjectIndex == i
                                          ? const Color(0xFF5D9EFF)
                                          : const Color(0xFFEFF2F6),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                child: Text(
                                  _subjects[i],
                                  style: TextStyle(
                                    color:
                                        _selectedSubjectIndex == i
                                            ? Colors.white
                                            : const Color(0xFF5D9EFF),
                                    fontSize: 11,
                                    fontFamily:
                                        _selectedSubjectIndex == i
                                            ? 'Pretendard-Medium'
                                            : 'Pretendard-Light',
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 28),

                    // 5. 이 피드는 어떤 이유로 작성하고 있나요?
                    Text(
                      '이 피드는 어떤 이유로 작성하고 있나요?',
                      style: TextStyle(
                        color: const Color(0xFF202020),
                        fontSize: 14,
                        fontFamily: 'Pretendard-Bold',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '피드의 목적을 선택해 주세요!',
                      style: TextStyle(
                        color: const Color(0xFF999999),
                        fontSize: 11,
                        fontFamily: 'Pretendard-Light',
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 태그 선택 버튼들
                    Row(
                      children: [
                        for (int i = 0; i < 2; i++)
                          Padding(
                            padding: const EdgeInsets.only(right: 16),
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedTagIndex = i;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                decoration: ShapeDecoration(
                                  color:
                                      _selectedTagIndex == i
                                          ? const Color(0xFF5D9EFF)
                                          : const Color(0xFFEFF2F6),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                child: Text(
                                  _tags[i],
                                  style: TextStyle(
                                    color:
                                        _selectedTagIndex == i
                                            ? Colors.white
                                            : const Color(0xFF5D9EFF),
                                    fontSize: 11,
                                    fontFamily:
                                        _selectedTagIndex == i
                                            ? 'Pretendard-Medium'
                                            : 'Pretendard-Light',
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // 6. 내용을 자세하게 작성해 주세요
                    Text(
                      '내용을 자세하게 작성해 주세요',
                      style: TextStyle(
                        color: const Color(0xFF202020),
                        fontSize: 14,
                        fontFamily: 'Pretendard-Bold',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '친구에게 알려주고 싶은 꿀팁이 있다면 여기에 작성해 봐요',
                      style: TextStyle(
                        color: const Color(0xFF999999),
                        fontSize: 11,
                        fontFamily: 'Pretendard-Light',
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 내용 입력 필드
                    Container(
                      width: double.infinity,
                      height: 280,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: ShapeDecoration(
                        color: const Color(0xFFF0F2F7),
                        shape: RoundedRectangleBorder(
                          side: BorderSide(
                            width: 0.80,
                            color: const Color(0xFFDADADA),
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: TextField(
                        controller: _contentController,
                        maxLines: 10,
                        textAlignVertical: TextAlignVertical.top,
                        decoration: InputDecoration(
                          hintText:
                              '피드에 올릴 내용을 최소 10자 이상 입력해 주세요.\n(유해한 어쩌고는 게시 중단이 될 수 있어요.)',
                          hintStyle: TextStyle(
                            color: const Color(0xFF999999),
                            fontSize: 12,
                            fontFamily: 'Pretendard-ExtraLight',
                            height: 1.50,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          focusedErrorBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          isDense: true,
                          fillColor: const Color(0xFFF0F2F7),
                          filled: true,
                        ),
                        style: TextStyle(
                          color: const Color(0xFF666666),
                          fontSize: 11,
                          fontFamily: 'Pretendard-Light',
                          height: 1.50,
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // 하단 안내 메시지와 작성 완료 버튼
                    // 첫 번째 안내 메시지
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: ShapeDecoration(
                        color: const Color(0xFFEFF2F6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: const Color(0xFF666666),
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  '작성 완료를 누르기 전, 한 번만 더 생각해 봐요!',
                                  style: TextStyle(
                                    color: const Color(0xFF666666),
                                    fontSize: 9,
                                    fontFamily: 'Pretendard-Medium',
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '자극적인 이미지나, 유해한 내용, 욕설이나 비하 표현은 누군가에게 상처가 될 수 있어요. 내가 올린 글이 누군가를 불편하게 하지 않을지 한 번만 더 생각해 주세요.',
                            style: TextStyle(
                              color: const Color(0xFF999999),
                              fontSize: 8,
                              fontFamily: 'Pretendard-Light',
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // 두 번째 안내 메시지
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: ShapeDecoration(
                        color: const Color(0xFFEFF2F6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.share,
                                color: const Color(0xFF666666),
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  'SNS 공유 기능 안내',
                                  style: TextStyle(
                                    color: const Color(0xFF666666),
                                    fontSize: 9,
                                    fontFamily: 'Pretendard-Medium',
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'XXXXXXXX',
                            style: TextStyle(
                              color: const Color(0xFF999999),
                              fontSize: 8,
                              fontFamily: 'Pretendard-Light',
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // 작성 완료 버튼
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submitFeed,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF146AFF),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child:
                            _isLoading
                                ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                                : const Text(
                                  '작성 완료',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontFamily: 'Pretendard-Medium',
                                  ),
                                ),
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
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
            fontSize: 11,
            fontFamily: isSelected ? 'Pretendard-Bold' : 'Pretendard-Normal',
          ),
        ),
      ),
    );
  }
}
