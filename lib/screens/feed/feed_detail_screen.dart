import 'package:flutter/material.dart';
import '../../models/feed_data.dart';
import '../../services/feed_service.dart';
import '../../widgets/feed/components/feed_comment_bottom_sheet.dart';
import '../../widgets/feed/components/feed_action_sheet.dart';
import '../feed/edit_feed_screen.dart';

class FeedDetailScreen extends StatefulWidget {
  final int feedId;

  const FeedDetailScreen({Key? key, required this.feedId}) : super(key: key);

  @override
  State<FeedDetailScreen> createState() => _FeedDetailScreenState();
}

class _FeedDetailScreenState extends State<FeedDetailScreen> {
  bool _isLoading = true;
  late FeedItem _feedItem;
  String _errorMessage = '';
  // 현재 이미지 슬라이드 인덱스를 추적하기 위한 상태 변수
  int _currentImageIndex = 0;
  // 이미지 슬라이더 페이지 컨트롤러
  late PageController _imagePageController;
  
  // 이전 글과 다음 글 정보를 저장하는 변수
  FeedItem? _prevFeed;
  FeedItem? _nextFeed;
  
  // 댓글 관련 상태
  bool _isLoadingComments = true;
  String _commentsErrorMessage = '';
  List<Map<String, dynamic>> _comments = [];
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmittingComment = false;
  int _commentCount = 0; // 댓글 수 (대댓글 제외)
  
  // 댓글 확장 상태를 저장하는 맵 (commentId -> 확장 여부)
  final Map<int, bool> _expandedComments = {};

  // 작성자 다른 글과 인기글 관련 상태
  bool _isLoadingAuthorFeeds = true;
  bool _isLoadingPopularFeeds = true;
  List<Map<String, dynamic>> _authorFeeds = [];
  List<Map<String, dynamic>> _popularFeeds = [];

  @override
  void initState() {
    super.initState();
    _loadFeedDetail();
    _loadPrevNextFeeds();
    _loadComments();
    
    // 이미지 슬라이더를 위한 PageController 초기화
    _imagePageController = PageController();
  }

  @override
  void dispose() {
    // PageController 해제
    _imagePageController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadFeedDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final feedData = await FeedService.getFeedDetail(widget.feedId);

      if (feedData != null) {
        setState(() {
          _feedItem = FeedItem.fromJson(feedData);
          _commentCount = _feedItem.commentCount ?? 0; // 댓글 수 초기화
          _isLoading = false;
          _loadAuthorFeeds(); // 작성자의 다른 글 로드
        });
      } else {
        setState(() {
          _errorMessage = '피드 정보를 불러올 수 없습니다.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '오류가 발생했습니다: $e';
        _isLoading = false;
      });
    }
  }
  
  // 댓글 목록 로드
  Future<void> _loadComments() async {
    setState(() {
      _isLoadingComments = true;
      _commentsErrorMessage = '';
    });

    try {
      final result = await FeedService.getComments(widget.feedId);
      
      if (result != null) {
        final List<dynamic> content = result['content'] ?? [];
        setState(() {
          _comments = List<Map<String, dynamic>>.from(content);
          _commentCount = _comments.length; // 댓글 수만 포함 (대댓글은 별도로 계산)
          _isLoadingComments = false;
        });
      } else {
        setState(() {
          _commentsErrorMessage = '댓글을 불러올 수 없습니다.';
          _isLoadingComments = false;
        });
      }
    } catch (e) {
      setState(() {
        _commentsErrorMessage = '댓글 로딩 중 오류가 발생했습니다: $e';
        _isLoadingComments = false;
      });
    }
  }
  
  // 댓글 등록
  Future<void> _submitComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    setState(() {
      _isSubmittingComment = true;
    });

    try {
      final result = await FeedService.createComment(widget.feedId, content);
      
      if (result != null) {
        // 댓글 등록 성공
        _commentController.clear();
        
        // 새 댓글을 목록에 추가하고 댓글 수 업데이트
        setState(() {
          _comments.insert(0, {
            'commentId': result['commentId'],
            'feedId': result['feedId'],
            'writerName': result['writerName'] ?? '나',
            'writerProfileUrl': result['writerProfileUrl'],
            'content': content,
            'createdAt': DateTime.now().toIso8601String(),
            'replyCount': 0, // 새 댓글의 대댓글 수는 0으로 초기화
          });
          _commentCount++; // 댓글 수만 증가
          _isSubmittingComment = false;
        });
      } else {
        // 댓글 등록 실패
        setState(() {
          _isSubmittingComment = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('댓글 등록에 실패했습니다.')),
        );
      }
    } catch (e) {
      setState(() {
        _isSubmittingComment = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류가 발생했습니다: $e')),
      );
    }
  }
  
  // 이전 글과 다음 글 정보를 가져오는 함수
  Future<void> _loadPrevNextFeeds() async {
    try {
      // 피드 목록을 가져옴 (최신순 정렬)
      final feedListData = await FeedService.getFeedList(
        page: 0,
        size: 100, // 충분한 수의 피드를 가져옴
        sort: ['createdAt,desc'],
      );
      
      if (feedListData != null && feedListData['content'] is List) {
        final List<dynamic> feedContents = feedListData['content'];
        final List<FeedItem> feedItems = feedContents
            .map((item) => FeedItem.fromJson(item))
            .toList();
        
        // 현재 피드의 인덱스를 찾음
        final currentIndex = feedItems.indexWhere((feed) => feed.feedId == widget.feedId);
        
        if (currentIndex != -1) {
          setState(() {
            // 다음 글 (현재보다 최신 글, 리스트에서는
            // 인덱스가 작은 항목)
            if (currentIndex > 0) {
              _nextFeed = feedItems[currentIndex - 1];
            }
            
            // 이전 글 (현재보다 오래된 글, 리스트에서는 인덱스가 큰 항목)
            if (currentIndex < feedItems.length - 1) {
              _prevFeed = feedItems[currentIndex + 1];
            }
          });
        }
      }
    } catch (e) {
      print('이전/다음 피드 로딩 중 오류 발생: $e');
    }
  }

  // 작성자의 다른 글 로드
  Future<void> _loadAuthorFeeds() async {
    if (_feedItem.writerName == null) return;
    
    setState(() {
      _isLoadingAuthorFeeds = true;
    });
    
    try {
      // 작성자의 다른 피드를 가져오는 API 호출
      // 현재는 모든 피드를 가져온 후 필터링하는 방식 사용
      final result = await FeedService.getFeedList(
        page: 0,
        size: 50,
      );
      
      if (result != null && result['content'] is List) {
        final List<dynamic> allFeeds = result['content'];
        
        // 현재 피드의 작성자와 동일한 작성자의 피드만 필터링
        final List<Map<String, dynamic>> authorFeeds = allFeeds
            .where((feed) => 
                feed['writerName'] == _feedItem.writerName && 
                feed['feedId'] != _feedItem.feedId) // 현재 피드 제외
            .cast<Map<String, dynamic>>()
            .take(3) // 최대 3개만 표시
            .toList();
        
        setState(() {
          _authorFeeds = authorFeeds;
          _isLoadingAuthorFeeds = false;
        });
        
        // 인기 피드 로드 (작성자의 다른 피드 로드 후)
        _loadPopularFeeds();
      } else {
        setState(() {
          _isLoadingAuthorFeeds = false;
        });
      }
    } catch (e) {
      print('작성자의 다른 피드 로딩 중 오류 발생: $e');
      setState(() {
        _isLoadingAuthorFeeds = false;
      });
    }
  }
  
  // 인기 피드 로드
  Future<void> _loadPopularFeeds() async {
    setState(() {
      _isLoadingPopularFeeds = true;
    });
    
    try {
      // 좋아요 많은 순으로 정렬된 피드 로드 (현재 피드와 같은 태그 카테고리)
      final result = await FeedService.getFeedListByLikes(
        tagCategory: _feedItem.tagCategory,
        size: 3,
      );
      
      if (result != null && result['content'] is List) {
        final List<dynamic> popularFeeds = result['content'];
        setState(() {
          _popularFeeds = List<Map<String, dynamic>>.from(popularFeeds);
          _isLoadingPopularFeeds = false;
        });
      } else {
        setState(() {
          _isLoadingPopularFeeds = false;
        });
      }
    } catch (e) {
      print('인기 피드 로딩 중 오류 발생: $e');
      setState(() {
        _isLoadingPopularFeeds = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Image.asset('assets/icons/my/뒤로가기.png', width: 24, height: 24),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          // 프로필 이미지
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: CircleAvatar(
              radius: 16,
              backgroundImage:
                  _isLoading
                      ? null
                      : (_feedItem.writerProfileImageUrl != null
                          ? NetworkImage(_feedItem.writerProfileImageUrl!)
                          : null),
              backgroundColor: Colors.grey[300],
              child:
                  _isLoading || _feedItem.writerProfileImageUrl == null
                      ? Icon(Icons.person, size: 16, color: Colors.white)
                      : null,
            ),
          ),
          // 홈 버튼
          IconButton(
            icon: Image.asset('assets/icons/home.png', width: 24, height: 24),
            onPressed: () {
              // 홈으로 이동
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
          // 알림 버튼
          IconButton(
            icon: Image.asset(
              'assets/icons/Icon/알림/Regular.png',
              width: 24,
              height: 24,
            ),
            onPressed: () {
              // 알림 화면으로 이동
            },
          ),
        ],
      ),
      body:
          _isLoading
              ? _buildLoadingWidget()
              : _errorMessage.isNotEmpty
              ? _buildErrorWidget()
              : _buildFeedDetailWidget(),
    );
  }

  Widget _buildLoadingWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: const Color(0xFF3A88F4)),
          SizedBox(height: 16),
          Text(
            '피드 정보를 불러오는 중입니다',
            style: TextStyle(
              color: const Color(0xFF999999),
              fontSize: 14,
              fontFamily: 'Pretendard-Light',
              fontWeight: FontWeight.w300,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: Colors.red, size: 48),
          SizedBox(height: 16),
          Text(_errorMessage, style: TextStyle(color: Colors.red)),
          SizedBox(height: 16),
          ElevatedButton(onPressed: _loadFeedDetail, child: Text('다시 시도')),
        ],
      ),
    );
  }

  Widget _buildFeedDetailWidget() {
    return SingleChildScrollView(
      child: LayoutBuilder(
        builder: (context, constraints) {
          // 화면 너비를 기준으로 위젯을 구성
          final maxWidth = constraints.maxWidth;

          return Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAuthorInfoSection(maxWidth),
              _buildContentSection(maxWidth),
              _buildDivider(),
              _buildNavigationSection(),
              _buildDivider(),
              _buildCommentsSection(),
              _buildAdditionalSections(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAuthorInfoSection(double maxWidth) {
    // 작성자 정보 및 프로필 섹션
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: Colors.white),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 왼쪽: 프로필 이미지와 작성자 정보
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 프로필 이미지
                    CircleAvatar(
                      radius: 25,
                      backgroundImage:
                          _feedItem.writerProfileImageUrl != null
                              ? NetworkImage(_feedItem.writerProfileImageUrl!)
                              : null,
                      backgroundColor: Colors.grey[300],
                      child:
                          _feedItem.writerProfileImageUrl == null
                              ? Icon(
                                Icons.person,
                                size: 30,
                                color: Colors.white,
                              )
                              : null,
                    ),
                    SizedBox(width: 12),

                    // 작성자 정보 (Expanded로 감싸 남은 공간 차지)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 함께 한 지 N일째
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6, // 8의 3/4
                              vertical: 3, // 4의 3/4
                            ),
                            decoration: ShapeDecoration(
                              color: const Color(0xFFFFD27F),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  6,
                                ), // 8의 3/4
                              ),
                            ),
                            child: Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: '함께 한 지 ',
                                    style: TextStyle(
                                      color: const Color(0xFF001F55),
                                      fontSize: 9, // 12의 3/4
                                      fontFamily: 'Pretendard-Light',
                                      letterSpacing: -0.18, // -0.24의 3/4
                                    ),
                                  ),
                                  TextSpan(
                                    text: '283일째',
                                    style: TextStyle(
                                      color: const Color(0xFF001F55),
                                      fontSize: 9, // 12의 3/4
                                      fontFamily: 'Pretendard-Medium',
                                      letterSpacing: -0.18, // -0.24의 3/4
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          SizedBox(height: 8),

                          // 작성자 이름 및 시간
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _feedItem.writerName ?? '작성자',
                                style: TextStyle(
                                  color: const Color(0xFF202020),
                                  fontSize: 16,
                                  fontFamily: 'Pretendard-Bold',
                                  letterSpacing: -0.32,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 8),
                              Row(
                                children: [
                                  Text(
                                    _feedItem.getTimeAgo(),
                                    style: TextStyle(
                                      color: const Color(0xFF999999),
                                      fontSize: 11,
                                      fontFamily: 'Pretendard-Light',
                                      letterSpacing: -0.22,
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  Container(
                                    width: 2,
                                    height: 2,
                                    decoration: ShapeDecoration(
                                      color: const Color(0xFFC4C4C4),
                                      shape: OvalBorder(),
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    '조회 ${_feedItem.viewCount ?? 0}명',
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
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 오른쪽: 세로 메뉴와 친한 친구 버튼
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // 세로점 메뉴
                  GestureDetector(
                    onTap: () {
                      // 피드 작성자가 현재 로그인한 사용자인지 확인
                      _checkIfMyFeedAndShowOptions();
                    },
                    child: Icon(
                      Icons.more_vert,
                      size: 24,
                      color: Colors.grey[600],
                    ),
                  ),
                  
                  SizedBox(height: 8),
                  
                  // 친한 친구 버튼 (세로점 바로 아래)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: ShapeDecoration(
                  color: const Color(0xFF5D9EFF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/icons/my/check.png',
                      width: 16,
                      height: 16,
                      color: Colors.white,
                    ),
                    SizedBox(width: 8),
                    Text(
                      '친한 친구',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontFamily: 'Pretendard-Medium',
                        letterSpacing: -0.24,
                      ),
                    ),
                  ],
                ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 내 피드인지 확인하고 옵션을 보여주는 메서드 추가
  // 피드가 내 피드인지 확인하고 적절한 옵션 시트를 표시하는 메서드
  Future<void> _checkIfMyFeedAndShowOptions() async {
    try {
      // 내 피드 목록 조회 API 호출
      final myFeedsResult = await FeedService.getMyFeeds(page: 0, size: 50);
      
      if (myFeedsResult == null) {
        throw Exception('내 피드 목록을 불러올 수 없습니다.');
      }
      
      // 응답에서 내 피드 목록 추출
      final List<dynamic> myFeeds = myFeedsResult['content'] ?? [];
      
      // 현재 피드가 내 피드 목록에 있는지 확인
      bool isMyFeed = false;
      for (var myFeed in myFeeds) {
        if (myFeed['feedId'] == _feedItem.feedId) {
          isMyFeed = true;
          break;
        }
      }
      
      // 내 피드 여부에 따라 다른 액션 시트 표시
      FeedActionSheet.show(
        context: context,
        isMyFeed: isMyFeed,
        onEdit: isMyFeed ? () {
          // 수정 기능 구현
          print('피드 수정: ${_feedItem.feedId}');
          // 수정 페이지로 이동
          _navigateToEditFeed();
        } : null,
        onDelete: isMyFeed ? () {
          // 삭제 기능 구현
          _deleteFeed();
        } : null,
        onReport: !isMyFeed ? () {
          // 신고 기능 구현
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('신고가 접수되었습니다.')),
          );
        } : null,
      );
    } catch (e) {
      // 오류 처리
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류가 발생했습니다: $e')),
      );
    }
  }

  // 수정 페이지로 이동하는 함수 추가
  void _navigateToEditFeed() async {
    // 현재 피드의 정보를 가지고 수정 화면으로 이동
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditFeedScreen(
          feedId: _feedItem.feedId!,
          title: _feedItem.title,
          content: _feedItem.content,
          gradeCategory: _feedItem.gradeCategory ?? 'ALL',
          subjectCategory: _feedItem.subjectCategory ?? 'ALL',
          tagCategory: _feedItem.tagCategory ?? 'ALL',
          imageUrls: _feedItem.imageUrls,
        ),
      ),
    );
    
    // 피드 수정 후 결과에 따라 화면 갱신
    if (result == true) {
      // 피드를 다시 로드하여 수정된 내용 반영
      _loadFeedDetail();
    }
  }

  // 피드 삭제 기능 추가
  Future<void> _deleteFeed() async {
    try {
      // 삭제 확인 대화상자
      final bool confirmed = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('피드 삭제'),
          content: Text('정말로 이 피드를 삭제하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('취소'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('삭제', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ) ?? false;
      
      if (!confirmed) return;
      
      // 로딩 인디케이터 표시
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: CircularProgressIndicator(color: const Color(0xFF5D9EFF)),
        ),
      );
      
      // 피드 삭제 API 호출
      final success = await FeedService.deleteFeed(_feedItem.feedId!);
      
      // 로딩 인디케이터 닫기
      Navigator.of(context).pop();
      
      if (success) {
        // 삭제 성공 시 메시지 표시 후 이전 화면으로 이동
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('피드가 삭제되었습니다')),
        );
        
        Navigator.of(context).pop(true); // 성공 결과와 함께 이전 화면으로 이동
      } else {
        // 삭제 실패 시 메시지 표시
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('피드 삭제에 실패했습니다')),
        );
      }
    } catch (e) {
      // 에러 처리
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류가 발생했습니다: $e')),
      );
    }
  }

  Widget _buildContentSection(double maxWidth) {
    // 피드 내용 섹션
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 12, left: 16, right: 16, bottom: 16),
      decoration: BoxDecoration(color: Colors.white),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 피드 내용 컨테이너
          Container(
            width: double.infinity,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 피드 제목과 내용
                Container(
                  width: double.infinity,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 제목
                      Text(
                        _feedItem.title,
                        style: TextStyle(
                          color: const Color(0xFF202020),
                          fontSize: 18,
                          fontFamily: 'Pretendard-Bold',
                          letterSpacing: -0.72,
                        ),
                        overflow: TextOverflow.visible,
                      ),
                      SizedBox(height: 20),

                      // 새로운 디자인 적용 (피그마 코드 기반)
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 메인 이미지와 인디케이터 (새로운 메서드로 대체)
                          if (_feedItem.imageUrls.isNotEmpty) ... [
                            _buildImageSlider(),
                            SizedBox(height: 12),
                          ],

                          // 작은 이미지 프리뷰
                          if (_feedItem.imageUrls.length > 1)
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children:
                                    _feedItem.imageUrls
                                        .skip(1)
                                        .toList()
                                        .asMap()
                                        .entries
                                        .map((entry) {
                                          final int index =
                                              entry.key +
                                              1; // 실제 인덱스 (첫 번째 이미지를 건너뛰었으므로 +1)
                                          final String imageUrl = entry.value;
                                          return GestureDetector(
                                            onTap: () {
                                              // 작은 이미지 클릭 시 해당 이미지로 이동
                                              _imagePageController
                                                  .animateToPage(
                                                    index,
                                                    duration: Duration(
                                                      milliseconds: 300,
                                                    ),
                                                    curve: Curves.easeInOut,
                                                  );
                                            },
                                            child: Container(
                                              width: 48, 
                                              height: 48, 
                                              margin: EdgeInsets.only(
                                                right: 12,
                                              ), 
                                              decoration:
                                                  index == _currentImageIndex
                                                      ? BoxDecoration(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              4,
                                                            ),
                                                        image: DecorationImage(
                                                          image: NetworkImage(
                                                            imageUrl,
                                                          ),
                                                          fit: BoxFit.cover,
                                                        ),
                                                        border: Border.all(
                                                          color: const Color(
                                                            0xFF5D9EFF,
                                                          ),
                                                          width: 2,
                                                        ),
                                                      )
                                                      : ShapeDecoration(
                                                        image: DecorationImage(
                                                          image: NetworkImage(
                                                            imageUrl,
                                                          ),
                                                          fit: BoxFit.cover,
                                                        ),
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                4,
                                                              ),
                                                        ),
                                                      ),
                                            ),
                                          );
                                        })
                                        .toList(),
                              ),
                            ),
                          
                          // 이미지가 있을 때만 간격 추가
                          if (_feedItem.imageUrls.isNotEmpty)
                            SizedBox(height: 12),

                          // 피드 내용 텍스트
                          Container(
                            width: double.infinity,
                            child: Text(
                              _feedItem.content ?? '',
                              style: TextStyle(
                                color: const Color(0xFF4A4A4A),
                                fontSize: 14,
                                fontFamily: 'Pretendard-Light',
                                height: 1.50,
                                letterSpacing: -0.28,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),

                      // 카테고리 태그 (Wrap으로 변경)
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          // 태그 카테고리 (습관 형성)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: ShapeDecoration(
                              color: const Color(0xFFFFD27F),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              _feedItem.getTagText(),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontFamily: 'Pretendard-Light',
                                letterSpacing: -0.24,
                              ),
                            ),
                          ),

                          // 학년 카테고리 (중학생)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: ShapeDecoration(
                              color: const Color(0xFFEFF2F6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              _feedItem.getGradeText(),
                              style: TextStyle(
                                color: const Color(0xFF5D9EFF),
                                fontSize: 12,
                                fontFamily: 'Pretendard-Light',
                                letterSpacing: -0.24,
                              ),
                            ),
                          ),

                          // 과목 카테고리 (수학)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: ShapeDecoration(
                              color: const Color(0xFFEFF2F6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              _feedItem.getSubjectText(),
                              style: TextStyle(
                                color: const Color(0xFF5D9EFF),
                                fontSize: 12,
                                fontFamily: 'Pretendard-Light',
                                letterSpacing: -0.24,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),

                // 좋아요, 댓글, 공유 버튼
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // 좋아요 버튼
                    GestureDetector(
                      onTap: () async {
                        // 좋아요 토글 API 호출
                        final success = await FeedService.toggleLike(
                          _feedItem.feedId!,
                          _feedItem.liked,
                        );

                        if (success) {
                          setState(() {
                            _feedItem.liked = !_feedItem.liked;
                            if (_feedItem.liked) {
                              _feedItem.likeCount =
                                  (_feedItem.likeCount ?? 0) + 1;
                            } else {
                              _feedItem.likeCount =
                                  (_feedItem.likeCount ?? 0) - 1;
                            }
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: ShapeDecoration(
                          shape: RoundedRectangleBorder(
                            side: BorderSide(
                              width: 0.65,
                              color: const Color(0xFFFFD27F),
                            ),
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(
                              'assets/icons/my/좋아요.png',
                              width: 16,
                              height: 16,
                              color:
                                  _feedItem.liked
                                      ? const Color(0xFFFFA63D)
                                      : const Color(0xFFFFA63D),
                            ),
                            SizedBox(width: 8),
                            Text(
                              '${_feedItem.likeCount ?? 0}',
                              style: TextStyle(
                                color: const Color(0xFFFFA63D),
                                fontSize: 12,
                                fontFamily: 'Pretendard-Medium',
                                letterSpacing: -0.24,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // 공유 버튼 (오른쪽 정렬)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: ShapeDecoration(
                        color: const Color(0xFFFFD27F),
                        shape: RoundedRectangleBorder(
                          side: BorderSide(
                            width: 0.55,
                            color: const Color(0xFFFFA63D),
                          ),
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            clipBehavior: Clip.antiAlias,
                            decoration: BoxDecoration(),
                            child: Icon(
                              Icons.share,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            '공유하기',
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
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: double.infinity,
      height: 12,
      decoration: ShapeDecoration(
        color: const Color(0xFFEFF2F6),
        shape: RoundedRectangleBorder(
          side: BorderSide(width: 0.10, color: const Color(0xFF8490A3)),
        ),
      ),
    );
  }

  Widget _buildNavigationSection() {
    // 이전글/다음글 네비게이션 섹션
    return Container(
      width: double.infinity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 다음 글
          GestureDetector(
            onTap: _nextFeed != null ? () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => FeedDetailScreen(feedId: _nextFeed!.feedId!),
                ),
              );
            } : null,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: ShapeDecoration(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  side: BorderSide(width: 0.80, color: const Color(0xFFD5D5D5)),
                ),
              ),
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
                        Text(
                          '다음 글',
                          style: TextStyle(
                            color: const Color(0xFFC4C4C4),
                            fontSize: 12,
                            fontFamily: 'Pretendard-Light',
                            letterSpacing: -0.24,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _nextFeed?.title ?? '다음 글이 없습니다',
                            style: TextStyle(
                              color: _nextFeed != null ? const Color(0xFF999999) : const Color(0xFFD5D5D5),
                              fontSize: 12,
                              fontFamily: 'Pretendard-Light',
                              letterSpacing: -0.24,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 이전 글
          GestureDetector(
            onTap: _prevFeed != null ? () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => FeedDetailScreen(feedId: _prevFeed!.feedId!),
                ),
              );
            } : null,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                        Text(
                          '이전 글',
                          style: TextStyle(
                            color: const Color(0xFFC4C4C4),
                            fontSize: 12,
                            fontFamily: 'Pretendard-Light',
                            letterSpacing: -0.24,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _prevFeed?.title ?? '이전 글이 없습니다',
                            style: TextStyle(
                              color: _prevFeed != null ? const Color(0xFF999999) : const Color(0xFFD5D5D5),
                              fontSize: 12,
                              fontFamily: 'Pretendard-Light',
                              letterSpacing: -0.24,
                            ),
                            overflow: TextOverflow.ellipsis,
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
    );
  }

  Widget _buildCommentsSection() {
    // 댓글 섹션
    return Container(
      width: double.infinity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 댓글 헤더
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(color: Colors.white),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // 댓글 제목과 개수 (대댓글 제외)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '댓글',
                          style: TextStyle(
                            color: const Color(0xFF353535),
                            fontSize: 18,
                            fontFamily: 'Pretendard-Bold',
                            letterSpacing: -0.72,
                          ),
                        ),
                        SizedBox(width: 4),
                        Text(
                          '$_commentCount',
                          style: TextStyle(
                            color: const Color(0xFF3A88F4),
                            fontSize: 20,
                            fontFamily: 'Pretendard-Bold',
                            letterSpacing: -0.80,
                          ),
                        ),
                      ],
                    ),

                    // 정렬 옵션
                    ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: 150),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '최신순',
                            style: TextStyle(
                              color: const Color(0xFF001F55),
                              fontSize: 12,
                              fontFamily: 'Pretendard-Light',
                              letterSpacing: -0.24,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(width: 12),
                          Text(
                            '도움이 된 순',
                            style: TextStyle(
                              color: const Color(0xFFB6B6B6),
                              fontSize: 12,
                              fontFamily: 'Pretendard-Light',
                              fontWeight: FontWeight.w300,
                              letterSpacing: -0.24,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // 댓글 로딩 중이거나 오류가 있는 경우
          if (_isLoadingComments)
            Container(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: CircularProgressIndicator(color: const Color(0xFF3A88F4)),
              ),
            )
          else if (_commentsErrorMessage.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Text(
                  _commentsErrorMessage,
                  style: TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else if (_comments.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white, // 배경색을 흰색으로 설정
                borderRadius: BorderRadius.circular(12), // 선택적: 더 예쁘게 보이도록 모서리 둥글게 설정
              ),
              child: Center(
                child: Text(
                  '아직 댓글이 없습니다.\n첫 댓글을 작성해보세요!',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                    fontFamily: 'Pretendard-Light',
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            // 댓글 목록 표시
            Column(
              children: _comments.map((comment) => _buildCommentItem(
                comment['writerName'] ?? '익명',
                _formatRelativeTime(comment['createdAt']),
                _feedItem.title, // 피드 타이틀 전달
                comment['content'] ?? '',
                0, // 좋아요 수
                comment['replyCount'] ?? 0, // 대댓글 수
                false, // 더보기 필요 여부
                comment['writerProfileUrl'], // 프로필 이미지 URL 전달
                comment['commentId'], // 댓글 ID 전달
              )).toList(),
            ),

          // 댓글 입력창을 "댓글 전체보기" 버튼으로 교체
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
            ),
            child: Container(
              width: 358,
              decoration: ShapeDecoration(
                color: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () {
                      // 댓글 바텀시트 열기
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => FeedCommentBottomSheet(
                          feedId: widget.feedId,
                          feedTitle: _feedItem.title,
                          showFeedTitle: true,
                          onCommentAdded: (comment) {
                            setState(() {
                              _comments.insert(0, comment);
                              _commentCount++; // 댓글 수만 증가
                            });
                          },
                          onCommentEdited: (commentId, content) {
                            setState(() {
                              final index = _comments.indexWhere(
                                (c) => c['commentId'] == commentId
                              );
                              if (index != -1) {
                                _comments[index]['content'] = content;
                              }
                            });
                          },
                          onCommentDeleted: (commentId) {
                            setState(() {
                              final deletedComment = _comments.firstWhere(
                                (c) => c['commentId'] == commentId,
                                orElse: () => {},
                              );
                              _comments.removeWhere((c) => c['commentId'] == commentId);
                              _commentCount--; // 댓글 수만 감소
                            });
                          },
                          onReplyAdded: (commentId, incrementCount) {
                            // 대댓글이 추가되면 해당 댓글의 대댓글 수만 증가
                            setState(() {
                              final index = _comments.indexWhere(
                                (c) => c['commentId'] == commentId
                              );
                              if (index != -1) {
                                _comments[index]['replyCount'] = (_comments[index]['replyCount'] ?? 0) + incrementCount;
                              }
                            });
                          },
                        ),
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: ShapeDecoration(
                        shape: RoundedRectangleBorder(
                          side: BorderSide(
                            width: 1,
                            color: const Color(0xFF8490A3),
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
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
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    '댓글 전체보기 ',
                                    style: TextStyle(
                                      color: const Color(0xFF8490A3),
                                      fontSize: 14,
                                      fontFamily: 'Pretendard-Light',
                                      letterSpacing: -0.28,
                                    ),
                                  ),
                                  Text(
                                    '$_commentCount',
                                    style: TextStyle(
                                      color: const Color(0xFF8490A3),
                                      fontSize: 14,
                                      fontFamily: 'Pretendard-Medium',
                                      letterSpacing: -0.28,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(width: 8),
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: const Color(0xFF8490A3),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 추가 섹션 (작성자의 다른 글, 인기 글)
  Widget _buildAdditionalSections() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 12), // 댓글 섹션과의 간격
        _buildAuthorOtherFeedsSection(),
        SizedBox(height: 12),
        _buildPopularFeedsSection(),
      ],
    );
  }
  
  // 작성자의 다른 글 섹션
  Widget _buildAuthorOtherFeedsSection() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: Colors.white),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 섹션 헤더
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      '작성자의 다른 피드 글',
                      style: TextStyle(
                        color: const Color(0xFF353535),
                        fontSize: 18,
                        fontFamily: 'Pretendard-Bold',
                        letterSpacing: -0.72,
                      ),
                    ),
                    SizedBox(width: 4),
                    Text(
                      '${_authorFeeds.length}',
                      style: TextStyle(
                        color: const Color(0xFF3A88F4),
                        fontSize: 20,
                        fontFamily: 'Pretendard-Bold',
                        letterSpacing: -0.80,
                      ),
                    ),
                  ],
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: const Color(0xFF8490A3),
                ),
              ],
            ),
          ),
          
          // 로딩 중이거나 데이터 없음
          if (_isLoadingAuthorFeeds)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: CircularProgressIndicator(
                  color: const Color(0xFF3A88F4),
                  strokeWidth: 2,
                ),
              ),
            )
          else if (_authorFeeds.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24),
              alignment: Alignment.center,
              child: Text(
                '작성자의 다른 피드 글이 없습니다',
                style: TextStyle(
                  color: const Color(0xFF999999),
                  fontSize: 14,
                  fontFamily: 'Pretendard-Light',
                  letterSpacing: -0.28,
                ),
              ),
            )
          else
            // 작성자의 다른 피드 가로 스크롤 목록
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 12, left: 16, bottom: 12),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _authorFeeds.map((feed) => _buildFeedCard(feed)).toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  // 인기 글 섹션
  Widget _buildPopularFeedsSection() {
    // 태그 카테고리에 따른 타이틀 생성
    String categoryTitle = '습관 형성';
    Color categoryColor = const Color(0xFF5D9EFF); // RGB(93, 158, 255)로 모든 필터 색상 통일
    if (_feedItem.tagCategory == 'CERTIFICATION') {
      categoryTitle = '학습 인증';
    } else if (_feedItem.tagCategory == 'INFORMATION') {
      categoryTitle = '정보 공유';
    }
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: Colors.white),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 섹션 헤더
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '다른 ',
                            style: TextStyle(
                              color: const Color(0xFF353535),
                              fontSize: 18,
                              fontFamily: 'Pretendard-Bold',
                              letterSpacing: -0.72,
                            ),
                          ),
                          TextSpan(
                            text: categoryTitle,
                            style: TextStyle(
                              color: categoryColor,
                              fontSize: 18,
                              fontFamily: 'Pretendard-Bold',
                              letterSpacing: -0.72,
                            ),
                          ),
                          TextSpan(
                            text: ' 인기 글',
                            style: TextStyle(
                              color: const Color(0xFF353535),
                              fontSize: 18,
                              fontFamily: 'Pretendard-Bold',
                              letterSpacing: -0.72,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: const Color(0xFF8490A3),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  '이번 주 가장 인기있었던 피드예요',
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
          
          // 로딩 중이거나 데이터 없음
          if (_isLoadingPopularFeeds)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: CircularProgressIndicator(
                  color: const Color(0xFF3A88F4),
                  strokeWidth: 2,
                ),
              ),
            )
          else if (_popularFeeds.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24),
              alignment: Alignment.center,
              child: Text(
                '해당 카테고리 인기 글이 없습니다',
                style: TextStyle(
                  color: const Color(0xFF999999),
                  fontSize: 14,
                  fontFamily: 'Pretendard-Light',
                  letterSpacing: -0.28,
                ),
              ),
            )
          else
            // 인기 피드 가로 스크롤 목록
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 12, left: 16, bottom: 12),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _popularFeeds.map((feed) => _buildFeedCard(feed)).toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  // 피드 카드 위젯 (이미지 카드 형태)
  Widget _buildFeedCard(Map<String, dynamic> feed) {
    // 이미지 존재 여부 확인
    final bool hasImage = feed['imageUrls'] != null && 
                         (feed['imageUrls'] as List).isNotEmpty;
    
    return GestureDetector(
      onTap: () {
        // 피드 상세 페이지로 이동
        if (feed['feedId'] != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FeedDetailScreen(feedId: feed['feedId']),
            ),
          );
        }
      },
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 피드 썸네일 이미지 또는 그라데이션 박스
            Container(
              width: 140,
              height: 140,
              decoration: hasImage 
                ? ShapeDecoration(
                    image: DecorationImage(
                      image: NetworkImage(feed['imageUrls'][0]),
                      fit: BoxFit.cover,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  )
                : ShapeDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color.fromRGBO(93, 158, 255, 0.14),
                        Color.fromRGBO(93, 158, 255, 0.45),
                        Color.fromRGBO(93, 158, 255, 0.57),
                      ],
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
            ),
            SizedBox(height: 8),
            
            // 피드 제목
            SizedBox(
              width: 140,
              child: Text(
                feed['title'] ?? '제목 없음',
                style: TextStyle(
                  color: const Color(0xFF353535),
                  fontSize: 14,
                  fontFamily: 'Pretendard-Bold',
                  letterSpacing: -0.28,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(height: 4),
            
            // 피드 날짜
            SizedBox(
              width: 140,
              child: Text(
                _formatCardDate(feed['createdDate']),
                style: TextStyle(
                  color: const Color(0xFF999999),
                  fontSize: 12,
                  fontFamily: 'Pretendard-Light',
                  letterSpacing: -0.24,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // 카드에 표시할 날짜 포맷팅
  String _formatCardDate(String? dateTimeStr) {
    if (dateTimeStr == null) return '날짜 없음';
    
    try {
      final date = DateTime.parse(dateTimeStr);
      return '${date.year}. ${date.month.toString().padLeft(2, '0')}. ${date.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return '날짜 오류';
    }
  }
  
  // 기존 피드 미리보기 아이템은 이제 사용하지 않음
  Widget _buildFeedItemPreview(Map<String, dynamic> feed) {
    return GestureDetector(
      onTap: () {
        // 피드 상세 페이지로 이동
        if (feed['feedId'] != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FeedDetailScreen(feedId: feed['feedId']),
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: const Color(0xFFEFF2F6), width: 1)),
        ),
        child: Text(
          feed['title'] ?? '제목 없음',
          style: TextStyle(
            color: const Color(0xFF202020),
            fontSize: 14,
            fontFamily: 'Pretendard-Light',
            overflow: TextOverflow.ellipsis,
          ),
          maxLines: 1,
        ),
      ),
    );
  }

  // 날짜 포맷팅 헬퍼 함수
  String _formatRelativeTime(String? dateTimeStr) {
    if (dateTimeStr == null) return '방금 전';
    
    try {
      // 서버 시간(UTC) 파싱
      final serverUtcTime = DateTime.parse(dateTimeStr);
      
      // 서버 시간(UTC)을 한국 시간(UTC+9)으로 변환
      final koreanTime = serverUtcTime.add(Duration(hours: 9));
      
      // 현재 시간
      final now = DateTime.now();
      print('댓글 - 현재 시간(로컬): $now');
      print('댓글 - 서버 시간(UTC): $serverUtcTime');
      print('댓글 - 변환된 시간(UTC+9): $koreanTime');
      
      // 변환된 시간으로 차이 계산
      final difference = now.difference(koreanTime);
      print('댓글 - 시간 차이(초): ${difference.inSeconds}');
      
      // 시간 차이가 음수인 경우 (미래의 날짜)
      if (difference.inSeconds < 0) {
        return '방금 전';
      }
      
      // 시간 차이에 따른 표시 형식 선택
      if (difference.inDays > 30) {
        final months = (difference.inDays / 30).floor();
        return '$months달 전';
      } else if (difference.inDays > 0) {
        return '${difference.inDays}일 전';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}시간 전';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}분 전';
      } else {
        return '방금 전';
      }
    } catch (e) {
      print('댓글 시간 파싱 오류: $e');
      return '방금 전';
    }
  }

  // 댓글 아이템 위젯 (아이콘 클릭 시 대댓글 보기 기능 추가)
  Widget _buildCommentItem(
    String authorName,
    String timeAgo,
    String feedTitle,
    String content,
    int likeCount,
    int replyCount,
    bool hasMoreContent,
    String? profileImageUrl,
    int? commentId,
  ) {
    // 각 댓글 아이템별로 확장/축소 상태를 관리하기 위한 유니크 키
    final String commentKey = 'comment_${commentId ?? DateTime.now().millisecondsSinceEpoch}';
    
    return StatefulBuilder(
      builder: (context, setState) {
        // 초기 상태 설정 (처음엔 접힌 상태)
        _expandedComments[commentId ?? 0] ??= false;
        bool isExpanded = _expandedComments[commentId ?? 0]!;
        
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(color: Colors.white),
          clipBehavior: Clip.none, // 오버플로우 클리핑 방지
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 작성자 정보
              Stack(
                clipBehavior: Clip.none, // 오버플로우 클리핑 방지
                children: [
                  // 작성자 정보 (왼쪽)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // 프로필 이미지 - 실제 데이터를 가져오도록 수정 필요
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.grey[300],
                        // 댓글 작성자의 프로필 이미지가 있을 경우 표시
                        backgroundImage: profileImageUrl != null && profileImageUrl.isNotEmpty 
                            ? NetworkImage(profileImageUrl) 
                            : null,
                        child: profileImageUrl == null || profileImageUrl.isEmpty
                            ? Text(
                                authorName.isNotEmpty ? authorName[0] : '?',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              )
                            : null,
                      ),
                      SizedBox(width: 12),

                      // 작성자 이름 및 시간
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            authorName,
                            style: TextStyle(
                              color: const Color(0xFF202020),
                              fontSize: 16,
                              fontFamily: 'Pretendard-Bold',
                              letterSpacing: -0.32,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 4),
                          Text(
                            timeAgo,
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
                  
                  // 더보기 버튼 (세로 점으로 변경 및 팝업 메뉴 추가) - 오른쪽 상단에 위치
                  Positioned(
                    right: -18,
                    top: 0,
                    child: PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert, size: 20, color: const Color(0xFF8490A3)),
                      padding: EdgeInsets.zero,
                      offset: Offset(0, 20),
                      onSelected: (value) async {
                        if (value == 'edit') {
                          // 댓글 수정 기능
                          _showEditCommentDialog(commentId, content);
                        } else if (value == 'delete') {
                          // 댓글 삭제 기능
                          _showDeleteCommentDialog(commentId);
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 14),
                              SizedBox(width: 8),
                              Text('수정', style: TextStyle(fontSize: 13)),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 14, color: Colors.red),
                              SizedBox(width: 8),
                              Text('삭제', style: TextStyle(fontSize: 13, color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              
              // 피드 타이틀 표시 (추가)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: SizedBox(
                  width: 358,
                  child: Text(
                    feedTitle,
                    style: TextStyle(
                      color: const Color(0xFF202020),
                      fontSize: 16,
                      fontFamily: 'Pretendard-Bold',
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.32,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 8),

              // 댓글 내용
              Container(
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      content,
                      style: TextStyle(
                        color: const Color(0xFF4A4A4A),
                        fontSize: 14,
                        fontFamily: 'Pretendard-Light',
                        height: 1.50,
                        letterSpacing: -0.28,
                      ),
                      maxLines: isExpanded ? null : 3,
                      overflow: isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                    ),
                    
                    // "더보기" 버튼 - 내용이 길 경우에만 표시
                    if (content.length > 80)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0), // 패딩 증가: 6 -> 8
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _expandedComments[commentId ?? 0] = !isExpanded;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 2.0),
                            child: Text(
                              isExpanded ? '접기' : '더보기',
                              style: TextStyle(
                                color: const Color(0xFFC4C4C4),
                                fontSize: 11,
                                fontFamily: 'Pretendard-Light',
                                letterSpacing: -0.22,
                              ),
                            ),
                          ),
                        ),
                      ),
                    
                    SizedBox(height: 16),
                    
                    // 댓글 아이콘과 좋아요 아이콘 (위치 변경)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 댓글 버튼 (먼저 표시) - 대댓글이 없어도 클릭 가능하도록 수정
                        GestureDetector(
                          onTap: () {
                            if (commentId != null) {
                              // 댓글 아이콘 클릭 시 해당 댓글의 대댓글 보기 (대댓글 수 조건 제거)
                              _showRepliesBottomSheet(commentId, authorName);
                            }
                          },
                          child: Container(
                          width: 62, // 너비 증가: 58 -> 62
                          height: 24,
                          child: Stack(
                            children: [
                              Positioned(
                                left: 0,
                                top: 0,
                                child: Container(
                                  width: 62, // 너비 증가: 58 -> 62
                                  height: 24,
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                                  decoration: ShapeDecoration(
                                    shape: RoundedRectangleBorder(
                                      side: BorderSide(
                                        width: 0.65,
                                        color: const Color(0xFFFFD27F),
                                      ),
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Image.asset(
                                        'assets/icons/my/댓글.png',
                                        width: 16,
                                        height: 16,
                                        color: const Color(0xFFFFA63D),
                                      ),
                                      SizedBox(width: 6),
                                      Text(
                                          '$replyCount',
                                        style: TextStyle(
                                          color: const Color(0xFFFFA63D),
                                          fontSize: 12,
                                          fontFamily: 'Pretendard-Medium',
                                          fontWeight: FontWeight.w500,
                                          letterSpacing: -0.24,
                                          height: 1.0, // 높이 조절
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        ),
                        
                        // 아이콘 사이 간격 추가
                        SizedBox(width: 16),
                        
                        // 좋아요 버튼 (나중에 표시)
                        Container(
                          width: 62, // 너비 증가: 58 -> 62
                          height: 24,
                          child: Stack(
                            children: [
                              Positioned(
                                left: 0,
                                top: 0,
                                child: Container(
                                  width: 62, // 너비 증가: 58 -> 62
                                  height: 24,
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                                  decoration: ShapeDecoration(
                                    shape: RoundedRectangleBorder(
                                      side: BorderSide(
                                        width: 0.65,
                                        color: const Color(0xFFFFD27F),
                                      ),
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Image.asset(
                                        'assets/icons/my/좋아요.png',
                                        width: 16,
                                        height: 16,
                                        color: const Color(0xFFFFA63D),
                                      ),
                                      SizedBox(width: 6),
                                      Text(
                                        '$likeCount',
                                        style: TextStyle(
                                          color: const Color(0xFFFFA63D),
                                          fontSize: 12,
                                          fontFamily: 'Pretendard-Medium',
                                          fontWeight: FontWeight.w500,
                                          letterSpacing: -0.24,
                                          height: 1.0, // 높이 조절
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
                  ],
                ),
              ),
            ],
          ),
        );
      }
    );
  }

  // 대댓글 보기 바텀시트 표시 메서드 추가
  void _showRepliesBottomSheet(int commentId, String authorName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FeedCommentBottomSheet(
        feedId: widget.feedId,
        feedTitle: _feedItem.title,
        showFeedTitle: true,
        // 특정 댓글의 ID와 작성자 이름 전달하여 대댓글 모드로 열기
        initialCommentId: commentId,
        initialAuthorName: authorName,
        onCommentAdded: (comment) {
          setState(() {
            _comments.insert(0, comment);
            _commentCount++; // 댓글 수만 증가
          });
        },
        onCommentEdited: (commentId, content) {
          setState(() {
            final index = _comments.indexWhere(
              (c) => c['commentId'] == commentId
            );
            if (index != -1) {
              _comments[index]['content'] = content;
            }
          });
        },
        onCommentDeleted: (commentId) {
          setState(() {
            final deletedComment = _comments.firstWhere(
              (c) => c['commentId'] == commentId,
              orElse: () => {},
            );
            _comments.removeWhere((c) => c['commentId'] == commentId);
            _commentCount--; // 댓글 수만 감소
          });
        },
        onReplyAdded: (commentId, incrementCount) {
          // 대댓글이 추가되면 해당 댓글의 대댓글 수만 증가
          setState(() {
            final index = _comments.indexWhere(
              (c) => c['commentId'] == commentId
            );
            if (index != -1) {
              _comments[index]['replyCount'] = (_comments[index]['replyCount'] ?? 0) + incrementCount;
            }
          });
        },
      ),
    );
  }

  void _showEditCommentDialog(int? commentId, String content) {
    // 댓글 수정 로직을 구현해야 합니다.
    // 현재는 간단한 팝업을 보여주는 것으로 대체합니다.
    final TextEditingController editController = TextEditingController(text: content);
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('댓글 수정'),
          content: TextField(
            controller: editController,
            decoration: InputDecoration(
              hintText: '댓글 내용을 입력하세요',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('취소'),
            ),
            TextButton(
              onPressed: () async {
                if (commentId != null && editController.text.trim().isNotEmpty) {
                  // 댓글 수정 API 호출
                  try {
                    final result = await FeedService.updateComment(commentId, editController.text.trim());
                    
                    if (result != null) {
                      // UI 업데이트
                      setState(() {
                        final index = _comments.indexWhere((c) => c['commentId'] == commentId);
                        if (index != -1) {
                          _comments[index]['content'] = editController.text.trim();
                        }
                      });
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('댓글이 수정되었습니다.')),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('오류가 발생했습니다: $e')),
                    );
                  }
                }
                Navigator.of(context).pop();
              },
              child: Text('저장'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteCommentDialog(int? commentId) {
    // 댓글이 없으면 작업 취소
    if (commentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('삭제할 댓글을 찾을 수 없습니다.')),
      );
      return;
    }
    
    // 확인 다이얼로그 표시
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('댓글 삭제'),
          content: Text('정말로 이 댓글을 삭제하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('취소'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                
                // 댓글 삭제 API 호출 및 UI 업데이트
                try {
                  // 로딩 상태 표시
                  setState(() {
                    _isLoadingComments = true;
                  });
                  
                  // 댓글 삭제 API 호출
                    final success = await FeedService.deleteComment(commentId);
                    
                    if (success) {
                    // 성공적으로 삭제된 경우 UI 업데이트
                      setState(() {
                        _comments.removeWhere((c) => c['commentId'] == commentId);
                        _commentCount = _comments.length;
                      _isLoadingComments = false;
                      });
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('댓글이 삭제되었습니다.')),
                      );
                  } else {
                    // 삭제 실패 시 메시지 표시
                    setState(() {
                      _isLoadingComments = false;
                    });
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('댓글 삭제에 실패했습니다.')),
                    );
                    }
                  } catch (e) {
                  // 예외 발생
                  setState(() {
                    _isLoadingComments = false;
                  });
                  
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('오류가 발생했습니다: $e')),
                    );
                  }
              },
              child: Text('삭제', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  // 작성자의 다른 글 로딩 위젯
  Widget _buildLoadingSectionWidget(String title) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 섹션 헤더
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(color: Colors.white),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: const Color(0xFF353535),
                  fontSize: 18,
                  fontFamily: 'Pretendard-Bold',
                  letterSpacing: -0.72,
                ),
              ),
            ],
          ),
        ),
        
        // 로딩 인디케이터
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(color: Colors.white),
          child: Center(
            child: CircularProgressIndicator(
              color: const Color(0xFF3A88F4),
              strokeWidth: 2,
            ),
          ),
        ),
      ],
    );
  }
  
  // 메인 이미지와 슬라이더 부분을 수정
  Widget _buildImageSlider() {
    if (_feedItem.imageUrls.isEmpty) {
      return SizedBox(); // 빈 컨테이너 반환
    } else if (_feedItem.imageUrls.length == 1) {
      // 이미지가 한 개인 경우 (슬라이더 필요 없음)
      return Container(
        width: double.infinity,
        height: 120, // 160의 3/4 크기
        decoration: ShapeDecoration(
          image: DecorationImage(
            image: NetworkImage(_feedItem.imageUrls[0]),
            fit: BoxFit.cover,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
      );
    } else {
      // 이미지가 여러 개인 경우 (슬라이더 사용)
      return Stack(
        children: [
          // 이미지 슬라이더
          Container(
            width: double.infinity,
            height: 120, // 160의 3/4 크기
            child: PageView.builder(
              controller: _imagePageController,
              itemCount: _feedItem.imageUrls.length,
              onPageChanged: (index) {
                setState(() {
                  _currentImageIndex = index;
                });
              },
              itemBuilder: (context, index) {
                return Container(
                  decoration: ShapeDecoration(
                    image: DecorationImage(
                      image: NetworkImage(_feedItem.imageUrls[index]),
                      fit: BoxFit.cover,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                );
              },
            ),
          ),

          // 인디케이터
          Positioned(
            left: 0,
            right: 0,
            bottom: 8,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_feedItem.imageUrls.length, (index) {
                return GestureDetector(
                  onTap: () {
                    // 인디케이터 탭 시 해당 페이지로 이동
                    _imagePageController.animateToPage(
                      index,
                      duration: Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: Container(
                    width: 6, // 3/4 크기
                    height: 6, // 3/4 크기
                    margin: EdgeInsets.symmetric(horizontal: 2),
                    decoration: ShapeDecoration(
                      color:
                          index == _currentImageIndex
                              ? const Color(0xFF5D9EFF)
                              : const Color(0xFFB6B6B6),
                      shape: OvalBorder(),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      );
    }
  }
}
