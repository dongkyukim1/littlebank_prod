import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../services/feed_service.dart';
import '../../../services/auth_service.dart';
import '../create_post_screen.dart';
import '../feed/feed_detail_screen.dart';

class PostHistoryScreen extends StatefulWidget {
  const PostHistoryScreen({super.key});

  @override
  State<PostHistoryScreen> createState() => _PostHistoryScreenState();
}

class _PostHistoryScreenState extends State<PostHistoryScreen> {
  // 데이터 로딩 상태
  bool _isLoading = true;
  String? _errorMessage;

  // 작성글 데이터
  List<Map<String, dynamic>> _postList = [];

  // 사용자 프로필 이미지 URL
  String? _userProfileImageUrl;

  // 정렬 옵션
  String _selectedSort = '최근순';
  final List<String> _sortOptions = ['최근순', '댓글이 많은 순', '도움이 된 순'];

  // 페이징 정보
  int _currentPage = 0;
  final int _pageSize = 10;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadPostHistory();
    _loadUserProfileImage(); // 사용자 프로필 이미지 로드

    // 상태 표시줄 색상 설정
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
  }

  // 작성글 내역 데이터 로드
  Future<void> _loadPostHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // FeedService를 통해 내가 쓴 피드 조회 (로그인한 사용자의 토큰 사용)
      final result = await FeedService.getMyFeeds(
        page: _currentPage,
        size: _pageSize,
      );

      if (result != null && result.containsKey('content')) {
        final List<dynamic> content = result['content'] as List;

        // 내용이 없는 경우 빈 배열 설정 후 로딩 완료 처리
        if (content.isEmpty) {
          setState(() {
            if (_currentPage == 0) {
              _postList = [];
            }
            _isLoading = false;
            _hasMore = false;
          });
          return;
        }

        print('API 응답 원본 데이터: ${content.first}'); // 디버그 로그 추가

        // 댓글 관련 필드 확인 로그
        if (content.isNotEmpty) {
          print('댓글 관련 필드 확인:');
          print('commentCount: ${content.first['commentCount']}');
          print('parentCommentCount: ${content.first['parentCommentCount']}');
          print('pureCommentCount: ${content.first['pureCommentCount']}');
        }

        // API 결과를 앱에서 사용하기 쉬운 형태로 매핑
        final List<Map<String, dynamic>> posts =
            content.map((item) {
              // 이미지 URL 처리
              String imageUrl = 'https://placehold.co/64x64';

              // imageUrls 배열이 있는 경우 첫 번째 항목 사용
              if (item['imageUrls'] != null &&
                  item['imageUrls'] is List &&
                  (item['imageUrls'] as List).isNotEmpty) {
                imageUrl = (item['imageUrls'] as List).first.toString();
                print('이미지 URL 처리: imageUrls 배열에서 첫 번째 이미지 사용 - $imageUrl');
              }
              // 단일 imageUrl이 있는 경우
              else if (item['imageUrl'] != null &&
                  item['imageUrl'].toString().isNotEmpty) {
                imageUrl = item['imageUrl'].toString();
                print('이미지 URL 처리: 단일 imageUrl 사용 - $imageUrl');
              }

              // 상대 경로인 경우 전체 URL로 변환
              if (imageUrl.isNotEmpty && !imageUrl.startsWith('http')) {
                imageUrl =
                    'https://littlebank-dev.s3.ap-northeast-2.amazonaws.com/$imageUrl';
                print('이미지 URL 처리: 전체 URL로 변환 - $imageUrl');
              }

              // 댓글 수 처리 - 대댓글 제외한 순수 댓글 수만 사용
              int commentCount = 0;
              if (item['commentCount'] != null) {
                if (item['parentCommentCount'] != null) {
                  // 전체 댓글 수에서 대댓글 수를 빼서 순수 댓글 수 계산
                  commentCount =
                      item['commentCount'] - item['parentCommentCount'];
                } else {
                  // API에서 순수 댓글 수만 제공하는 경우
                  commentCount =
                      item['pureCommentCount'] ?? item['commentCount'];
                }
              }

              return {
                'id': item['feedId'],
                'title': item['title'] ?? '제목 없음',
                'content': item['content'] ?? '내용 없음',
                'createdAt':
                    item['createdDate'] ??
                    item['createdAt'] ??
                    DateTime.now().toIso8601String(),
                'commentCount': commentCount,
                'likeCount': item['likeCount'] ?? 0,
                'imageUrl': imageUrl,
              };
            }).toList();

        // 페이징 정보 업데이트
        final bool isLastPage = result['last'] == true;

        setState(() {
          if (_currentPage == 0) {
            _postList = posts;
          } else {
            _postList.addAll(posts);
          }
          _hasMore = !isLastPage;
          _isLoading = false;
        });
      } else {
        // 응답에 문제가 있는 경우
        setState(() {
          if (_currentPage == 0) {
            _postList = [];
          }
          _isLoading = false;
          _hasMore = false;
        });
      }
    } catch (e) {
      // 오류 처리
      setState(() {
        _errorMessage = '데이터를 로드하는 중 오류가 발생했습니다: $e';
        _isLoading = false;
      });
      print('게시물 로드 오류: $e');
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

  // 다음 페이지 로드
  Future<void> _loadMorePosts() async {
    if (!_hasMore || _isLoading) return;

    _currentPage++;
    await _loadPostHistory();
  }

  // 새로고침
  Future<void> _refreshPosts() async {
    _currentPage = 0;
    await _loadPostHistory();
  }

  // 정렬 옵션에 따라 게시물 정렬
  List<Map<String, dynamic>> _getSortedPosts() {
    final List<Map<String, dynamic>> sortedPosts = List.from(_postList);

    try {
      if (_selectedSort == '최근순') {
        sortedPosts.sort((a, b) {
          try {
            return DateTime.parse(
              b['createdAt'],
            ).compareTo(DateTime.parse(a['createdAt']));
          } catch (e) {
            print('날짜 정렬 오류: $e');
            return 0; // 오류 발생 시 순서 유지
          }
        });
      } else if (_selectedSort == '댓글이 많은 순') {
        sortedPosts.sort(
          (a, b) => (b['commentCount'] ?? 0).compareTo(a['commentCount'] ?? 0),
        );
      } else if (_selectedSort == '도움이 된 순') {
        sortedPosts.sort(
          (a, b) => (b['likeCount'] ?? 0).compareTo(a['likeCount'] ?? 0),
        );
      }
    } catch (e) {
      print('게시물 정렬 오류: $e');
      // 오류 발생 시 정렬 없이 원래 목록 반환
    }

    return sortedPosts;
  }

  @override
  Widget build(BuildContext context) {
    // 피드가 없는 경우 간소화된 UI 표시
    if (!_isLoading && _postList.isEmpty && _errorMessage == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            '작성글 내역',
            style: TextStyle(
              color: Color(0xFF353535),
              fontSize: 16,
              fontFamily: 'Pretendard-SemiBold',
            ),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: Image.asset(
              'assets/icons/my/뒤로가기.png',
              width: 20,
              height: 20,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: Colors.white,
            statusBarIconBrightness: Brightness.dark,
          ),
        ),
        body: Column(
          children: [
            // 안내 메시지 섹션 다시 추가
            Container(
              width: double.infinity,
              color: const Color(0xFFF5F7FB),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      '작성글 위반으로 신고 당한 피드는 작성글 내역에 노출되지 않습니다.작성글 운영 정책을 확인해 주세요.',
                      style: TextStyle(
                        color: const Color(0xFF4A4A4A),
                        fontSize: 10,
                        fontFamily: 'Pretendard-Light',
                        letterSpacing: -0.24,
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      _showPolicyGuideModal();
                    },
                    child: Image.asset(
                      'assets/icons/Icon/feed/inform.png',
                      width: 18,
                      height: 18,
                      errorBuilder:
                          (context, error, stackTrace) => Icon(
                            Icons.info_outline,
                            size: 18,
                            color: const Color(0xFFB6B6B6),
                          ),
                    ),
                  ),
                ],
              ),
            ),

            // 가로 구분선 추가
            Container(
              width: double.infinity,
              height: 6,
              decoration: ShapeDecoration(
                color: const Color(0xFFE7ECF6),
                shape: RoundedRectangleBorder(
                  side: BorderSide(width: 0.10, color: const Color(0xFF8490A3)),
                ),
              ),
            ),

            // 빈 피드 화면
            Expanded(child: _buildEmptyPostView()),
          ],
        ),
      );
    }

    // 기존 UI 유지 (피드가 있거나 로딩 중 또는 오류 있는 경우)
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          '작성글 내역',
          style: TextStyle(
            color: Color(0xFF353535),
            fontSize: 16,
            fontFamily: 'Pretendard-SemiBold',
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Image.asset('assets/icons/my/뒤로가기.png', width: 20, height: 20),
          onPressed: () => Navigator.pop(context),
        ),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.white,
          statusBarIconBrightness: Brightness.dark,
        ),
      ),
      body: Column(
        children: [
          // 안내 메시지 섹션
          Container(
            width: double.infinity,
            color: const Color(0xFFF5F7FB),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    '작성글 위반으로 신고 당한 피드는 작성글 내역에 노출되지 않습니다.작성글 운영 정책을 확인해 주세요.',
                    style: TextStyle(
                      color: const Color(0xFF4A4A4A),
                      fontSize: 10,
                      fontFamily: 'Pretendard-Light',
                      letterSpacing: -0.24,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    _showPolicyGuideModal();
                  },
                  child: Image.asset(
                    'assets/icons/Icon/feed/inform.png',
                    width: 18,
                    height: 18,
                    errorBuilder:
                        (context, error, stackTrace) => Icon(
                          Icons.info_outline,
                          size: 18,
                          color: const Color(0xFFB6B6B6),
                        ),
                  ),
                ),
              ],
            ),
          ),

          // 가로 구분선 추가
          Container(
            width: double.infinity,
            height: 6,
            decoration: ShapeDecoration(
              color: const Color(0xFFE7ECF6),
              shape: RoundedRectangleBorder(
                side: BorderSide(width: 0.10, color: const Color(0xFF8490A3)),
              ),
            ),
          ),

          // 내가 작성한 글 개수 표시
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 16.0),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey[200],
                  ),
                  child:
                      _userProfileImageUrl != null
                          ? ClipOval(
                            child: Image.network(
                              _userProfileImageUrl!,
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (context, error, stackTrace) => Icon(
                                    Icons.person,
                                    color: Colors.grey[400],
                                  ),
                            ),
                          )
                          : Icon(Icons.person, color: Colors.grey[400]),
                ),
                SizedBox(width: 12),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '내가 작성한 글은 ',
                        style: TextStyle(
                          color: const Color(0xFF202020),
                          fontSize: 14,
                          fontFamily: 'Pretendard-Bold',
                          letterSpacing: -0.28,
                        ),
                      ),
                      TextSpan(
                        text: ' 총 ${_postList.length}개',
                        style: TextStyle(
                          color: const Color(0xFF5D9EFF),
                          fontSize: 16,
                          fontFamily: 'Pretendard-Bold',
                          letterSpacing: -0.28,
                        ),
                      ),
                    ],
                  ),
                ),
                Spacer(),
                GestureDetector(
                  onTap: () {
                    // 글쓰기 기능 구현
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CreatePostScreen(),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 9,
                    ),
                    decoration: ShapeDecoration(
                      color: const Color(0xFF5D9EFF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(27),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/icons/Icon/feed/글쓰기.png',
                          width: 15,
                          height: 15,
                          errorBuilder:
                              (context, error, stackTrace) => Icon(
                                Icons.edit,
                                color: Colors.white,
                                size: 15,
                              ),
                        ),
                        SizedBox(width: 6),
                        Text(
                          '글쓰기',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontFamily: 'Pretendard-Light',
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

          // 정렬 옵션 섹션
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            margin: const EdgeInsets.only(top: 0),
            decoration: BoxDecoration(color: Colors.white),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _buildSortOptions(),
            ),
          ),

          // 게시물 목록
          Expanded(
            child:
                _isLoading && _currentPage == 0
                    ? const Center(child: CircularProgressIndicator())
                    : _errorMessage != null && _currentPage == 0
                    ? _buildErrorView()
                    : _buildPostList(),
          ),
        ],
      ),
    );
  }

  // 정렬 옵션 버튼 생성
  List<Widget> _buildSortOptions() {
    List<Widget> options = [];

    for (int i = 0; i < _sortOptions.length; i++) {
      final String option = _sortOptions[i];
      final bool isSelected = _selectedSort == option;

      // 원형 표시기와 텍스트 추가
      options.add(
        Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.only(top: 3),
          decoration: ShapeDecoration(
            color:
                isSelected ? const Color(0xFF5D9EFF) : const Color(0xFFB6B6B6),
            shape: OvalBorder(),
          ),
        ),
      );

      options.add(SizedBox(width: 8));

      options.add(
        GestureDetector(
          onTap: () {
            setState(() {
              _selectedSort = option;
            });
          },
          child: Text(
            option,
            style: TextStyle(
              color:
                  isSelected
                      ? const Color(0xFF001F55)
                      : const Color(0xFFB6B6B6),
              fontSize: 12,
              fontFamily:
                  isSelected ? 'Pretendard-Light' : 'Pretendard-ExtraLight',
              letterSpacing: -0.28,
            ),
          ),
        ),
      );

      // 마지막 항목이 아니라면 간격 추가
      if (i < _sortOptions.length - 1) {
        options.add(SizedBox(width: 12));
      }
    }

    return options;
  }

  // 오류 화면
  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
          const SizedBox(height: 16),
          Text(
            '데이터를 불러오는 중 오류가 발생했습니다',
            style: TextStyle(
              fontSize: 16,
              fontFamily: 'Pretendard-Medium',
              color: Colors.red.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage ?? '알 수 없는 오류',
            style: TextStyle(
              fontSize: 14,
              fontFamily: 'Pretendard-Light',
              color: Colors.grey.shade700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _refreshPosts,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5D9DFF),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text(
              '다시 시도',
              style: TextStyle(fontFamily: 'Pretendard-Medium'),
            ),
          ),
        ],
      ),
    );
  }

  // 게시물 목록 화면
  Widget _buildPostList() {
    try {
      final sortedPosts = _getSortedPosts();

      if (_postList.isEmpty || sortedPosts.isEmpty) {
        // 빈 화면은 build 메서드에서 전체 UI를 대체하므로 여기서는 빈 컨테이너 반환
        return Container();
      }

      return RefreshIndicator(
        onRefresh: _refreshPosts,
        color: const Color(0xFF5D9DFF),
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: sortedPosts.length + (_hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            // 마지막 항목이고 더 있는 경우 로딩 인디케이터 표시
            if (index == sortedPosts.length) {
              _loadMorePosts();
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            final post = sortedPosts[index];
            return Column(
              children: [
                _buildPostItem(post),
                Container(
                  width: double.infinity,
                  height: 6,
                  decoration: ShapeDecoration(
                    color: const Color(0xFFE7ECF6),
                    shape: RoundedRectangleBorder(
                      side: BorderSide(
                        width: 0.10,
                        color: const Color(0xFF8490A3),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );
    } catch (e) {
      print('피드 목록 표시 오류: $e');
      return _buildEmptyPostView();
    }
  }

  // 게시물 아이템
  Widget _buildPostItem(Map<String, dynamic> post) {
    // 날짜 포맷팅
    String formattedDate = '날짜 정보 없음';
    if (post['createdAt'] != null) {
      try {
        final DateTime dateTime = DateTime.parse(post['createdAt']);
        formattedDate = DateFormat('yyyy. MM. dd').format(dateTime);
      } catch (e) {
        formattedDate = '날짜 형식 오류';
      }
    }

    return GestureDetector(
      onTap: () {
        // 피드 상세 페이지로 이동
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FeedDetailScreen(feedId: post['id']),
          ),
        );
      },
      child: Container(
        width: MediaQuery.of(context).size.width - 16, // 화면 너비에 맞춤
        height: 194,
        child: Stack(
          children: [
            Positioned(
              left: 0,
              top: 0,
              child: Container(
                width: MediaQuery.of(context).size.width - 16,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // 작성일 표시
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                '작성일',
                                style: TextStyle(
                                  color: const Color(0xFF999999),
                                  fontSize: 12,
                                  fontFamily: 'Pretendard-Light',
                                  letterSpacing: -0.24,
                                ),
                              ),
                              SizedBox(width: 4),
                              Text(
                                formattedDate,
                                style: TextStyle(
                                  color: const Color(0xFF4A4A4A),
                                  fontSize: 12,
                                  fontFamily: 'Pretendard-Light',
                                  letterSpacing: -0.24,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // 가로 구분선 추가
                    Container(
                      width: double.infinity,
                      height: 1,
                      color: const Color(0xFFEEEEEE),
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                    ),

                    // 게시물 내용
                    Container(
                      padding: const EdgeInsets.only(
                        bottom: 12,
                        left: 16,
                        right: 16,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            clipBehavior: Clip.antiAlias,
                            decoration: BoxDecoration(),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 제목 영역
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width:
                                          MediaQuery.of(context).size.width -
                                          80,
                                      child: Text(
                                        post['title'] ?? '제목 없음',
                                        style: TextStyle(
                                          color: const Color(0xFF202020),
                                          fontSize: 16,
                                          fontFamily: 'Pretendard-Bold',
                                          letterSpacing: -0.32,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Icon(
                                      Icons.more_vert,
                                      color: Colors.grey,
                                      size: 20,
                                    ),
                                  ],
                                ),
                                SizedBox(height: 12),
                                // 이미지와 내용
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    // 이미지가 없는 경우 기본 이미지 표시
                                    Container(
                                      width: 64,
                                      height: 64,
                                      decoration: ShapeDecoration(
                                        color: const Color(
                                          0xFFEEEEEE,
                                        ), // 배경색 추가
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child:
                                            post['imageUrl'] != null &&
                                                    post['imageUrl']
                                                        .toString()
                                                        .isNotEmpty
                                                ? Image.network(
                                                  post['imageUrl'],
                                                  width: 64,
                                                  height: 64,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (
                                                    context,
                                                    error,
                                                    stackTrace,
                                                  ) {
                                                    print(
                                                      '이미지 로드 오류: $error, URL: ${post['imageUrl']}',
                                                    );
                                                    return Container(
                                                      width: 64,
                                                      height: 64,
                                                      color: const Color(
                                                        0xFFEEEEEE,
                                                      ),
                                                      child: Icon(
                                                        Icons.image,
                                                        size: 30,
                                                        color: Colors.grey[400],
                                                      ),
                                                    );
                                                  },
                                                )
                                                : Container(
                                                  width: 64,
                                                  height: 64,
                                                  color: const Color(
                                                    0xFFEEEEEE,
                                                  ),
                                                  child: Icon(
                                                    Icons.image,
                                                    size: 30,
                                                    color: Colors.grey[400],
                                                  ),
                                                ),
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    SizedBox(
                                      width:
                                          MediaQuery.of(context).size.width -
                                          124,
                                      child: Text(
                                        post['content'] ?? '내용 없음',
                                        style: TextStyle(
                                          color: const Color(0xFF4A4A4A),
                                          fontSize: 12,
                                          fontFamily: 'Pretendard-Light',
                                          height: 1.50,
                                          letterSpacing: -0.24,
                                        ),
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 16), // 간격 증가
                          // 댓글 수와 좋아요 수
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8), // 추가 패딩
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Container(
                                  width: 58,
                                  height: 24,
                                  child: Stack(
                                    children: [
                                      Positioned(
                                        left: 5.0, // 오른쪽으로 이동
                                        top: -5, // 위로 위치 조정
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 4,
                                          ),
                                          decoration: ShapeDecoration(
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(24),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              Image.asset(
                                                'assets/icons/Icon/feed/댓글.png',
                                                width: 16,
                                                height: 16,
                                                errorBuilder:
                                                    (
                                                      context,
                                                      error,
                                                      stackTrace,
                                                    ) => Icon(
                                                      Icons.chat_bubble_outline,
                                                      size: 16,
                                                      color: const Color(
                                                        0xFFFFA63D,
                                                      ),
                                                    ),
                                              ),
                                              SizedBox(width: 8),
                                              Text(
                                                '${post['commentCount'] ?? 0}',
                                                style: TextStyle(
                                                  color: const Color(
                                                    0xFFFFA63D,
                                                  ),
                                                  fontSize: 12,
                                                  fontFamily:
                                                      'Pretendard-Medium',
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
                                SizedBox(width: 8),
                                // 좋아요 수
                                Container(
                                  width: 54,
                                  height: 24,
                                  child: Stack(
                                    children: [
                                      Positioned(
                                        left: 0,
                                        top: -5, // 위로 위치 조정
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 4,
                                          ),
                                          decoration: ShapeDecoration(
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(24),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              Image.asset(
                                                'assets/icons/Icon/feed/좋아요.png',
                                                width: 16,
                                                height: 16,
                                                errorBuilder:
                                                    (
                                                      context,
                                                      error,
                                                      stackTrace,
                                                    ) => Icon(
                                                      Icons
                                                          .thumb_up_alt_outlined,
                                                      size: 16,
                                                      color: const Color(
                                                        0xFFFFA63D,
                                                      ),
                                                    ),
                                              ),
                                              SizedBox(width: 8),
                                              Text(
                                                '${post['likeCount'] ?? 0}',
                                                textAlign: TextAlign.right,
                                                style: TextStyle(
                                                  color: const Color(
                                                    0xFFFFA63D,
                                                  ),
                                                  fontSize: 12,
                                                  fontFamily:
                                                      'Pretendard-Medium',
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
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 빈 피드 화면 위젯
  Widget _buildEmptyPostView() {
    return Center(
      child: Container(
        width: MediaQuery.of(context).size.width,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 상단 여백 추가
            SizedBox(height: 100),

            // 이미지 - 에러 처리 추가
            Container(
              width: 136,
              height: 123,
              child: Image.asset(
                'assets/icons/Icon/feed/no_feed.png',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  print('이미지 로드 오류: $error');
                  // 이미지 로드 실패 시 기본 아이콘 표시
                  return Icon(
                    Icons.article_outlined,
                    size: 80,
                    color: Color(0xFFBBBBBB),
                  );
                },
              ),
            ),
            SizedBox(height: 24),

            // 텍스트 섹션
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    '아직 작성한 피드가 없어요!',
                    style: TextStyle(
                      color: const Color(0xFF202020),
                      fontSize: 18,
                      fontFamily: 'Pretendard-Bold',
                      height: 1.50,
                      letterSpacing: -0.72,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    '내가 자랑하고 싶은 순간을 공유해 봐요',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: const Color(0xFF999999),
                      fontSize: 14,
                      fontFamily: 'Pretendard-Light',
                      letterSpacing: -0.28,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 28),

            // 버튼
            GestureDetector(
              onTap: () {
                // 글쓰기 기능 구현
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreatePostScreen(),
                  ),
                ).then((value) {
                  // 화면으로 돌아왔을 때 데이터 다시 로드
                  if (value == true) {
                    _refreshPosts();
                  }
                });
              },
              child: Container(
                width: MediaQuery.of(context).size.width - 32, // 양쪽 16px 마진
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 16,
                ),
                decoration: ShapeDecoration(
                  color: const Color(0xFF146AFF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      '피드 작성하기',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontFamily: 'Pretendard-Medium',
                        letterSpacing: -0.28,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // _showPolicyGuideModal 메서드 추가
  void _showPolicyGuideModal() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // 화면 크기 가져오기
        final size = MediaQuery.of(context).size;
        final maxWidth = size.width * 0.9; // 화면 너비의 90%로 제한

        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: SingleChildScrollView(
            child: Container(
              width: maxWidth,
              decoration: ShapeDecoration(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 상단 헤더 부분
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                '피드 작성글 운영 정책',
                                style: TextStyle(
                                  color: const Color(0xFF202020),
                                  fontSize: 16,
                                  fontFamily: 'Pretendard-Bold',
                                  letterSpacing: -0.64,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.of(context).pop();
                              },
                              child: Container(
                                width: 18,
                                height: 18,
                                child: Icon(
                                  Icons.close,
                                  size: 18,
                                  color: const Color(0xFF8490A3),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 6),
                        Text(
                          '아래 기준에 해당되거나, 신고받은 글은 작성글 내역에서 노출되지 않을 수 있습니다.',
                          style: TextStyle(
                            color: const Color(0xFF999999),
                            fontSize: 12,
                            fontFamily: 'Pretendard-Light',
                            height: 1.40,
                            letterSpacing: -0.24,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 콘텐츠 부분
                  Padding(
                    padding: const EdgeInsets.only(
                      top: 6,
                      left: 16,
                      right: 16,
                      bottom: 20,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '리틀뱅크의 커뮤니티는 서로의 학습 방법을 공유하고, 응원할 수 있는 동기부여를 위한 공간입니다. 아래 기준을 꼭 지켜주세요.',
                          style: TextStyle(
                            color: const Color(0xFF4A4A4A),
                            fontSize: 12,
                            fontFamily: 'Pretendard-Light',
                            height: 1.40,
                            letterSpacing: -0.24,
                          ),
                        ),
                        SizedBox(height: 20),

                        // 정책 항목 1
                        _buildPolicyItem(
                          '1',
                          '모두가 존중받는 공간임을 기억해 주세요',
                          '욕설, 비하, 혐오, 특정인을 향한 비방은 금지됩니다. 또한, 불쾌감을 주거나 공격적인 내용은 삭제될 수 있어요.',
                        ),
                        SizedBox(height: 16),

                        // 정책 항목 2
                        _buildPolicyItem(
                          '2',
                          '허위 정보, 광고성 글은 자제해 주세요',
                          '다른 사용자들에게 혼란을 줄 수 있는 허위 정보, 상업적 목적의 글, 학습 정보와 관계없는 홍보성 글은 제제될 수 있어요.',
                        ),
                        SizedBox(height: 16),

                        // 정책 항목 3 - 긴 제목의 텍스트 래핑 처리
                        _buildPolicyItem(
                          '3',
                          '운영자 및 다른 사용자에 의한 신고 시, 운영 방침에 따라 사전 안내 없이 글이 삭제될 수 있어요',
                          '다른 사용자들에게 혼란을 줄 수 있는 허위 정보, 상업적 목적의 글, 학습 정보와 관계없는 홍보성 글은 제제될 수 있어요.',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // 정책 항목 위젯 - 개선
  Widget _buildPolicyItem(String number, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 번호 표시 원형 컨테이너
        Container(
          width: 18,
          height: 18,
          decoration: ShapeDecoration(
            color: const Color(0xFFFFD27F),
            shape: OvalBorder(),
          ),
          child: Center(
            child: Text(
              number,
              style: TextStyle(
                color: const Color(0xFF001F55),
                fontSize: 9,
                fontFamily: 'Pretendard-Bold',
              ),
            ),
          ),
        ),
        SizedBox(width: 10),

        // 텍스트 섹션
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: const Color(0xFF4A4A4A),
                  fontSize: 12,
                  fontFamily: 'Pretendard-Medium',
                  letterSpacing: -0.24,
                ),
                softWrap: true,
              ),
              SizedBox(height: 6),
              Text(
                description,
                style: TextStyle(
                  color: const Color(0xFF999999),
                  fontSize: 10,
                  fontFamily: 'Pretendard-Light',
                  height: 1.40,
                  letterSpacing: -0.20,
                ),
                softWrap: true,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
