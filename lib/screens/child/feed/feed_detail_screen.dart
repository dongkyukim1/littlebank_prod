import 'package:flutter/material.dart';
import '../../../models/feed_data.dart';
import '../../../services/feed_service.dart';
import '../../../services/auth_service.dart'; // AuthService 추가
import '../../../widgets/feed/components/feed_comment_bottom_sheet.dart';
import '../../../widgets/feed/components/feed_action_sheet.dart';
import 'edit_feed_screen.dart';
import 'feed_share_screen.dart';
import 'dart:math' as Math;

class FeedDetailScreen extends StatefulWidget {
  final int feedId;

  const FeedDetailScreen({super.key, required this.feedId});

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

  // 댓글 정렬 상태 변수 추가
  String _commentSortType = 'latest'; // 'latest' 또는 'helpful'

  // 댓글 확장 상태를 저장하는 맵 (commentId -> 확장 여부)
  final Map<int, bool> _expandedComments = {};

  // 작성자 다른 글과 인기글 관련 상태
  bool _isLoadingAuthorFeeds = true;
  bool _isLoadingPopularFeeds = true;
  List<Map<String, dynamic>> _authorFeeds = [];
  List<Map<String, dynamic>> _popularFeeds = [];

  // 현재 로그인한 사용자 정보 추가
  String? _currentUserId;
  String? _currentUserName;
  String? _currentUserProfileUrl;

  @override
  void initState() {
    super.initState();
    _loadFeedDetail();
    _loadPrevNextFeeds();
    _loadComments();
    _loadCurrentUserInfo(); // 사용자 정보 로드 추가

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
      // 정렬 타입에 따라 정렬 기준 설정
      List<String>? sortList;
      if (_commentSortType == 'latest') {
        sortList = [
          'createdDate,desc',
        ]; // 서버에 최신순 요청 (createdAt -> createdDate로 수정)
      } else {
        sortList = [
          'likeCount,desc',
          'createdDate,desc',
        ]; // 좋아요 내림차순, 같으면 최신순 (createdAt -> createdDate로 수정)
      }

      final result = await FeedService.getComments(
        widget.feedId,
        sort: sortList,
      );

      if (result != null) {
        final List<dynamic> content = result['content'] ?? [];

        // 첫 번째 댓글의 구조 확인 (로깅)
        if (content.isNotEmpty) {
          final firstComment = content[0];
          print('첫 번째 댓글 구조:');
          firstComment.forEach((key, value) {
            print('  $key: $value');
          });

          // liked 필드가 없으면 각 댓글에 liked: false 추가
          for (var comment in content) {
            if (!comment.containsKey('liked')) {
              if (comment.containsKey('isliked')) {
                // isliked 필드가 있으면 이를 liked로 사용
                comment['liked'] = comment['isliked'];
              } else {
                comment['liked'] = false;
              }
            }
            if (!comment.containsKey('likeCount')) {
              comment['likeCount'] = 0;
            }
          }
        }

        // 서버에서 반환된 정렬 순서 확인을 위해 생성 날짜 출력
        if (content.isNotEmpty) {
          print('정렬 확인: _commentSortType = $_commentSortType');
          for (int i = 0; i < Math.min(content.length, 5); i++) {
            final date =
                content[i]['createdDate']; // createdAt -> createdDate로 수정
            print('댓글 #$i 생성 날짜: $date');
          }
        }

        setState(() {
          // 대댓글(답글)은 제외하고 순수 댓글만 필터링
          _comments =
              List<Map<String, dynamic>>.from(content).where((comment) {
                // parentId가 없거나 0이면 순수 댓글, 있으면 대댓글
                return comment['parentId'] == null || comment['parentId'] == 0;
              }).toList();

          // 클라이언트 측에서 정렬 처리 - 최신순
          if (_commentSortType == 'latest') {
            // createdDate 기준으로 내림차순 정렬 (null 안전 처리 추가)
            _comments.sort((a, b) {
              final String aDateStr = a['createdDate'] ?? '';
              final String bDateStr = b['createdDate'] ?? '';

              // 둘 다 날짜가 없으면 동등하게 취급
              if (aDateStr.isEmpty && bDateStr.isEmpty) return 0;
              // a만 날짜가 없으면 b가 앞으로
              if (aDateStr.isEmpty) return 1;
              // b만 날짜가 없으면 a가 앞으로
              if (bDateStr.isEmpty) return -1;

              try {
                final DateTime aDate = DateTime.parse(aDateStr);
                final DateTime bDate = DateTime.parse(bDateStr);
                return bDate.compareTo(aDate); // 최신 댓글이 위에 오도록 정렬
              } catch (e) {
                print('날짜 파싱 오류: $e, aDateStr: $aDateStr, bDateStr: $bDateStr');
                return 0; // 오류 시 순서 유지
              }
            });
          }
          // 도움이 된 순 정렬은 서버에서 처리

          _commentCount = _comments.length; // 대댓글을 제외한 순수 댓글 수만 저장
          _isLoadingComments = false;
        });
      } else {
        setState(() {
          _commentsErrorMessage = '댓글을 불러올 수 없습니다.';
          _isLoadingComments = false;
        });
      }
    } catch (e) {
      print('댓글 로딩 중 오류 발생: $e');
      setState(() {
        _commentsErrorMessage = '댓글을 불러오는 중 오류가 발생했습니다.';
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
          // 새 댓글 데이터 생성 (parentId가 없는 순수 댓글)
          final newComment = {
            'commentId': result['commentId'],
            'feedId': result['feedId'],
            'writerName': result['writerName'] ?? '나',
            'writerProfileUrl': result['writerProfileUrl'],
            'content': content,
            'createdDate': DateTime.now().toIso8601String(),
            'replyCount': 0,
            'parentId': null, // 순수 댓글이므로 parentId는 null
          };

          _comments.insert(0, newComment);
          _commentCount++; // 순수 댓글이므로 댓글 수 증가
          _isSubmittingComment = false;
        });
      } else {
        // 댓글 등록 실패
        setState(() {
          _isSubmittingComment = false;
        });

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('댓글 등록에 실패했습니다.')));
      }
    } catch (e) {
      setState(() {
        _isSubmittingComment = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('오류가 발생했습니다: $e')));
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
        final List<FeedItem> feedItems =
            feedContents.map((item) => FeedItem.fromJson(item)).toList();

        // 현재 피드의 인덱스를 찾음
        final currentIndex = feedItems.indexWhere(
          (feed) => feed.feedId == widget.feedId,
        );

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
    // 작성자 ID가 필요하므로 우선 작성자 정보에서 ID를 찾아야 함
    // 현재 API 구조상 작성자 ID를 직접 얻기 어려우므로 기존 방식 유지하되 더 효율적으로 개선
    // TODO: 동명이인 문제 해결을 위해 작성자 이메일 정보도 함께 비교 필요
    if (_feedItem.writerName == null) return;

    setState(() {
      _isLoadingAuthorFeeds = true;
    });

    try {
      // 작성자의 다른 피드를 가져오는 API 호출
      // TODO: 향후 작성자 ID를 직접 얻을 수 있게 되면 FeedService.getUserFeeds() 사용
      final result = await FeedService.getFeedList(
        page: 0,
        size: 20,
      ); // 50에서 20으로 줄임

      if (result != null && result['content'] is List) {
        final List<dynamic> allFeeds = result['content'];

        // 현재 피드의 작성자와 동일한 작성자의 피드만 필터링
        // 주의: 현재는 이름만으로 필터링하므로 동명이인 문제가 있을 수 있음
        final List<Map<String, dynamic>> authorFeeds =
            allFeeds
                .where(
                  (feed) =>
                      feed['writerName'] == _feedItem.writerName &&
                      feed['feedId'] != _feedItem.feedId,
                ) // 현재 피드 제외
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
      // 현재 피드의 태그 카테고리 확인
      print('현재 피드의 태그 카테고리: ${_feedItem.tagCategory}');

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

  // 현재 로그인한 사용자 정보 로드 메서드
  Future<void> _loadCurrentUserInfo() async {
    try {
      // SharedPreferences에서 로컬 사용자 정보를 가져오는 대신 서버에서 최신 정보 조회
      try {
        final serverUserInfo = await AuthService.getUserInfo();
        print('서버에서 조회한 사용자 정보: $serverUserInfo');

        // 사용자 ID와 이름 가져오기
        final userId = serverUserInfo['id']?.toString();
        final userName = serverUserInfo['name']?.toString();

        // 프로필 이미지 경로 - 가능한 필드명들 모두 시도
        String? profileImageUrl;
        if (serverUserInfo.containsKey('profileImageUrl')) {
          profileImageUrl = serverUserInfo['profileImageUrl'];
        } else if (serverUserInfo.containsKey('profileImagePath')) {
          profileImageUrl = serverUserInfo['profileImagePath'];
        } else if (serverUserInfo.containsKey('profileUrl')) {
          profileImageUrl = serverUserInfo['profileUrl'];
        } else if (serverUserInfo.containsKey('profileImage')) {
          profileImageUrl = serverUserInfo['profileImage'];
        }

        print('추출한 프로필 이미지 경로: $profileImageUrl');

        if (mounted) {
          setState(() {
            _currentUserId = userId;
            _currentUserName = userName;
            _currentUserProfileUrl = profileImageUrl;
          });
        }

        return;
      } catch (serverError) {
        print('서버에서 사용자 정보 조회 실패, 로컬 정보 사용: $serverError');
      }

      // 서버 조회에 실패한 경우 로컬 정보 사용
      final userId = await AuthService.getCurrentUserId();
      final userName = await AuthService.getCurrentUserName();
      final userInfo = await AuthService.getLocalUserInfo();

      print('로컬에서 가져온 사용자 정보: $userInfo');

      // 프로필 이미지 URL 찾기 (여러 가능한 필드명 시도)
      String? profileImageUrl;
      if (userInfo != null) {
        if (userInfo.containsKey('profileImageUrl')) {
          profileImageUrl = userInfo['profileImageUrl'];
        } else if (userInfo.containsKey('profileImagePath')) {
          profileImageUrl = userInfo['profileImagePath'];
        } else if (userInfo.containsKey('profileUrl')) {
          profileImageUrl = userInfo['profileUrl'];
        } else if (userInfo.containsKey('profileImage')) {
          profileImageUrl = userInfo['profileImage'];
        }
      }

      // 프로필 이미지 경로가 없으면 저장된 경로 사용
      if (profileImageUrl == null || profileImageUrl.isEmpty) {
        profileImageUrl = await AuthService.getProfileImagePath();
      }

      print('최종 사용할 프로필 이미지 URL: $profileImageUrl');

      if (mounted) {
        setState(() {
          _currentUserId = userId;
          _currentUserName = userName;
          _currentUserProfileUrl = profileImageUrl;
        });
      }
    } catch (e) {
      print('현재 사용자 정보 로드 중 오류: $e');
    }
  }

  // 사용자가 댓글 작성자인지 확인하는 메서드
  bool _isCommentOwner(String? writerName) {
    // 작성자 이름으로 비교
    if (writerName != null && _currentUserName != null) {
      return writerName == _currentUserName;
    }

    // 작성자 이름으로 비교했을 때 일치하지 않으면 false 반환
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F7),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(80),
        child: Container(
          width: double.infinity,
          height: 80,
          decoration: BoxDecoration(color: Colors.white),
          child: Stack(
            children: [
              // 전체 컨텐츠를 담는 박스 - 더 아래로 위치
              Positioned(
                left: 0,
                right: 0,
                top: 36,
                child: Container(
                  width: double.infinity,
                  height: 24,
                  child: Stack(
                    children: [
                      // 뒤로가기 버튼
                      Positioned(
                        left: 16,
                        top: 4,
                        child: Container(
                          height: 24,
                          alignment: Alignment.center,
                          child: GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
                            child: Container(
                              width: 24,
                              height: 24,
                              clipBehavior: Clip.antiAlias,
                              decoration: BoxDecoration(),
                              child: Image.asset(
                                'assets/icons/my/뒤로가기.png',
                                width: 24,
                                height: 24,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // 중앙 타이틀
                      Positioned(
                        left: 0,
                        right: 0,
                        top: 0,
                        child: Container(
                          height: 24,
                          alignment: Alignment.center,
                          child: Text(
                            '피드 상세',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                              fontFamily: 'Pretendard-Bold',
                              letterSpacing: -0.32,
                            ),
                          ),
                        ),
                      ),
                      // 세로 점선 3개 (오른쪽)
                      Positioned(
                        right: 16,
                        top: 0,
                        child: Container(
                          height: 24,
                          alignment: Alignment.center,
                          child: GestureDetector(
                            onTap: () {
                              // 피드 작성자가 현재 로그인한 사용자인지 확인
                              _checkIfMyFeedAndShowOptions();
                            },
                            child: Container(
                              width: 24,
                              height: 24,
                              clipBehavior: Clip.antiAlias,
                              decoration: BoxDecoration(),
                              child: Icon(
                                Icons.more_vert,
                                size: 24,
                                color: Colors.black,
                              ),
                            ),
                          ),
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
                          _feedItem.fullProfileImageUrl != null
                              ? NetworkImage(_feedItem.fullProfileImageUrl!)
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

              // 오른쪽: 친한 친구 버튼
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // 친한 친구 버튼
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
                          'assets/icons/Icon/feed/check.png',
                          width: 20,
                          height: 20,
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
        onEdit:
            isMyFeed
                ? () {
                  // 수정 기능 구현
                  print('피드 수정: ${_feedItem.feedId}');
                  // 수정 페이지로 이동
                  _navigateToEditFeed();
                }
                : null,
        onDelete:
            isMyFeed
                ? () {
                  // 삭제 기능 구현
                  _deleteFeed();
                }
                : null,
        onReport:
            !isMyFeed
                ? () {
                  // 신고 기능 구현
                  _reportFeed();
                }
                : null,
      );
    } catch (e) {
      // 오류 처리
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('오류가 발생했습니다: $e')));
    }
  }

  // 피드 신고 기능 추가
  Future<void> _reportFeed() async {
    try {
      print('피드 신고 시작: feedId=${_feedItem.feedId}');

      // 신고 전 확인 다이얼로그 표시
      final bool confirmed =
          await showDialog(
            context: context,
            builder:
                (context) => AlertDialog(
                  title: Text('피드 신고'),
                  content: Text('이 피드를 신고하시겠습니까?\n신고 후에는 취소할 수 없습니다.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text('취소'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: Text('신고하기', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
          ) ??
          false;

      if (!confirmed) {
        print('사용자가 신고를 취소했습니다.');
        return;
      }

      // 로딩 인디케이터 표시
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => Center(
              child: CircularProgressIndicator(color: const Color(0xFF5D9EFF)),
            ),
      );

      print('피드 신고 API 호출 시작...');
      // 피드 신고 API 호출
      final result = await FeedService.reportFeed(_feedItem.feedId!);
      print('피드 신고 API 호출 결과: $result');

      // 로딩 인디케이터 닫기
      Navigator.of(context).pop();

      if (result != null) {
        print('신고 성공');
        // 신고 성공 시 메시지 표시
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('신고가 접수되었습니다.'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        print('신고 실패: 결과가 null입니다.');
        // 신고 실패 시 메시지 표시
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('신고 접수에 실패했습니다. 다시 시도해주세요.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e, stackTrace) {
      print('피드 신고 중 예외 발생: $e');
      print('스택 트레이스: $stackTrace');

      // 로딩 인디케이터가 아직 표시되어 있는지 확인하고 닫기 (오류가 발생한 경우에도)
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      // 에러 처리
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('오류가 발생했습니다: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
    }
  }

  // 수정 페이지로 이동하는 함수 추가
  void _navigateToEditFeed() async {
    // 현재 피드의 정보를 가지고 수정 화면으로 이동
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => EditFeedScreen(
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
      final bool confirmed =
          await showDialog(
            context: context,
            builder:
                (context) => AlertDialog(
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
          ) ??
          false;

      if (!confirmed) return;

      // 로딩 인디케이터 표시
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => Center(
              child: CircularProgressIndicator(color: const Color(0xFF5D9EFF)),
            ),
      );

      // 피드 삭제 API 호출
      final success = await FeedService.deleteFeed(_feedItem.feedId!);

      // 로딩 인디케이터 닫기
      Navigator.of(context).pop();

      if (success) {
        // 삭제 성공 시 메시지 표시 후 이전 화면으로 이동
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('피드가 삭제되었습니다')));

        Navigator.of(context).pop(true); // 성공 결과와 함께 이전 화면으로 이동
      } else {
        // 삭제 실패 시 메시지 표시
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('피드 삭제에 실패했습니다')));
      }
    } catch (e) {
      // 에러 처리
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('오류가 발생했습니다: $e')));
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
          SizedBox(
            width: double.infinity,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 피드 제목과 내용
                SizedBox(
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
                          if (_feedItem.imageUrls.isNotEmpty) ...[
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
                          SizedBox(
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
                    GestureDetector(
                      onTap: () {
                        // 공유하기 화면으로 이동
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) =>
                                    FeedShareScreen(feedItem: _feedItem),
                          ),
                        );
                      },
                      child: Container(
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
    return SizedBox(
      width: double.infinity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 다음 글
          GestureDetector(
            onTap:
                _nextFeed != null
                    ? () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) =>
                                  FeedDetailScreen(feedId: _nextFeed!.feedId!),
                        ),
                      );
                    }
                    : null,
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
                  SizedBox(
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
                              color:
                                  _nextFeed != null
                                      ? const Color(0xFF999999)
                                      : const Color(0xFFD5D5D5),
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
            onTap:
                _prevFeed != null
                    ? () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) =>
                                  FeedDetailScreen(feedId: _prevFeed!.feedId!),
                        ),
                      );
                    }
                    : null,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(color: Colors.white),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
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
                              color:
                                  _prevFeed != null
                                      ? const Color(0xFF999999)
                                      : const Color(0xFFD5D5D5),
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
    return SizedBox(
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
                          GestureDetector(
                            onTap: () {
                              if (_commentSortType != 'latest') {
                                setState(() {
                                  _commentSortType = 'latest';
                                  _loadComments(); // 정렬 방식이 변경되면 댓글 다시 로드
                                });
                              }
                            },
                            child: Text(
                              '최신순',
                              style: TextStyle(
                                color:
                                    _commentSortType == 'latest'
                                        ? const Color(0xFF001F55)
                                        : const Color(0xFFB6B6B6),
                                fontSize: 12,
                                fontFamily:
                                    _commentSortType == 'latest'
                                        ? 'Pretendard-Medium'
                                        : 'Pretendard-Light',
                                letterSpacing: -0.24,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(width: 12),
                          GestureDetector(
                            onTap: () {
                              if (_commentSortType != 'helpful') {
                                setState(() {
                                  _commentSortType = 'helpful';
                                  _loadComments(); // 정렬 방식이 변경되면 댓글 다시 로드
                                });
                              }
                            },
                            child: Text(
                              '도움이 된 순',
                              style: TextStyle(
                                color:
                                    _commentSortType == 'helpful'
                                        ? const Color(0xFF001F55)
                                        : const Color(0xFFB6B6B6),
                                fontSize: 12,
                                fontFamily:
                                    _commentSortType == 'helpful'
                                        ? 'Pretendard-Medium'
                                        : 'Pretendard-Light',
                                fontWeight: FontWeight.w300,
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
              ],
            ),
          ),

          // 댓글 로딩 중이거나 오류가 있는 경우
          if (_isLoadingComments)
            Container(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: CircularProgressIndicator(
                  color: const Color(0xFF3A88F4),
                ),
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
                borderRadius: BorderRadius.circular(
                  12,
                ), // 선택적: 더 예쁘게 보이도록 모서리 둥글게 설정
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
              children:
                  (_comments.isNotEmpty
                          ? (_commentSortType == 'latest'
                              ? List.from(_comments) // 최신순일 때는 원래 순서 유지
                              : List.from(_comments)) // 좋아요순일 때도 원래 순서 유지
                          : [])
                      .map(
                        (comment) => _buildCommentItem(
                          comment['writerName'] ?? '익명',
                          _formatRelativeTime(
                            comment['createdDate'],
                          ), // createdAt -> createdDate로 수정
                          _feedItem.title, // 피드 타이틀 전달
                          comment['content'] ?? '',
                          comment['likeCount'] ?? 0, // 좋아요 수
                          comment['replyCount'] ?? 0, // 대댓글 수
                          false, // 더보기 필요 여부
                          comment['writerProfileUrl'], // 프로필 이미지 URL 전달
                          comment['commentId'], // 댓글 ID 전달
                          comment['liked'] ?? false, // 좋아요 여부
                        ),
                      )
                      .toList(),
            ),

          // 댓글 입력창을 "댓글 전체보기" 버튼으로 교체
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 48,
            ), // 12에서 24로 2배 증가
            decoration: BoxDecoration(color: Colors.white),
            child: Container(
              width: 358,
              decoration: ShapeDecoration(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
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
                        builder:
                            (context) => FeedCommentBottomSheet(
                              feedId: widget.feedId,
                              feedTitle: _feedItem.title,
                              showFeedTitle: true,
                              onCommentAdded: (comment) {
                                setState(() {
                                  // 순수 댓글인 경우에만 추가하고 카운트 증가
                                  if (comment['parentId'] == null ||
                                      comment['parentId'] == 0) {
                                    _comments.insert(0, comment);
                                    _commentCount++; // 댓글 수만 증가
                                  }
                                });
                              },
                              onCommentEdited: (commentId, content) {
                                setState(() {
                                  final index = _comments.indexWhere(
                                    (c) => c['commentId'] == commentId,
                                  );
                                  if (index != -1) {
                                    _comments[index]['content'] = content;
                                  }
                                });
                              },
                              onCommentDeleted: (commentId) {
                                setState(() {
                                  // 삭제된 댓글 찾기
                                  final deletedComment = _comments.firstWhere(
                                    (c) => c['commentId'] == commentId,
                                    orElse: () => <String, dynamic>{},
                                  );

                                  // 댓글 목록에서 제거
                                  _comments.removeWhere(
                                    (c) => c['commentId'] == commentId,
                                  );

                                  // 순수 댓글인 경우에만 카운트 감소
                                  final bool isParentComment =
                                      deletedComment.isNotEmpty &&
                                      (deletedComment['parentId'] == null ||
                                          deletedComment['parentId'] == 0);

                                  if (isParentComment) {
                                    _commentCount--; // 댓글 수만 감소
                                  }
                                });
                              },
                              onReplyAdded: (commentId, incrementCount) {
                                // 대댓글이 추가되면 해당 댓글의 대댓글 수만 증가
                                setState(() {
                                  final index = _comments.indexWhere(
                                    (c) => c['commentId'] == commentId,
                                  );
                                  if (index != -1) {
                                    _comments[index]['replyCount'] =
                                        (_comments[index]['replyCount'] ?? 0) +
                                        incrementCount;
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
                  children:
                      _authorFeeds.map((feed) => _buildFeedCard(feed)).toList(),
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
    Color categoryColor = const Color(
      0xFF5D9EFF,
    ); // RGB(93, 158, 255)로 모든 필터 색상 통일

    if (_feedItem.tagCategory == 'STUDY_CERTIFICATION') {
      categoryTitle = '학습 인증';
    } else if (_feedItem.tagCategory == 'INFORMATION') {
      categoryTitle = '정보 공유';
    } else if (_feedItem.tagCategory == 'HABIT_BUILDING') {
      categoryTitle = '습관 형성';
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
                              fontSize: 20,
                              fontFamily: 'Pretendard-Bold',
                              letterSpacing: -0.72,
                            ),
                          ),
                          TextSpan(
                            text: categoryTitle,
                            style: TextStyle(
                              color: categoryColor,
                              fontSize: 20,
                              fontFamily: 'Pretendard-Bold',
                              letterSpacing: -0.72,
                            ),
                          ),
                          TextSpan(
                            text: ' 인기 글',
                            style: TextStyle(
                              color: const Color(0xFF353535),
                              fontSize: 20,
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
                  children:
                      _popularFeeds
                          .map((feed) => _buildFeedCard(feed))
                          .toList(),
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
    final bool hasImage =
        feed['imageUrls'] != null && (feed['imageUrls'] as List).isNotEmpty;

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
            // 피드 썸네일 이미지 또는 대체 이미지
            Container(
              width: 140,
              height: 140,
              decoration:
                  hasImage
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
                        image: DecorationImage(
                          image: AssetImage('assets/icons/Icon/feed/empty.png'),
                          fit: BoxFit.cover,
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
          border: Border(
            bottom: BorderSide(color: const Color(0xFFEFF2F6), width: 1),
          ),
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
    if (dateTimeStr == null || dateTimeStr.isEmpty) return '방금 전';

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
      print('댓글 시간 파싱 오류: $e, 날짜 문자열: $dateTimeStr');
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
    bool liked,
  ) {
    // 각 댓글 아이템별로 확장/축소 상태를 관리하기 위한 유니크 키
    final String commentKey =
        'comment_${commentId ?? DateTime.now().millisecondsSinceEpoch}';

    // 현재 사용자가 댓글 작성자인지 확인
    final bool isOwner = _isCommentOwner(authorName);

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
                        backgroundImage:
                            profileImageUrl != null &&
                                    profileImageUrl.isNotEmpty
                                ? NetworkImage(
                                  AuthService.getFullProfileImageUrl(
                                    profileImageUrl,
                                  ),
                                )
                                : null,
                        child:
                            profileImageUrl == null || profileImageUrl.isEmpty
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
                    child:
                        isOwner
                            ? PopupMenuButton<String>(
                              icon: Icon(
                                Icons.more_vert,
                                size: 20,
                                color: const Color(0xFF8490A3),
                              ),
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
                              itemBuilder:
                                  (context) => [
                                    PopupMenuItem(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit, size: 14),
                                          SizedBox(width: 8),
                                          Text(
                                            '수정',
                                            style: TextStyle(fontSize: 13),
                                          ),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.delete,
                                            size: 14,
                                            color: Colors.red,
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            '삭제',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.red,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                            )
                            : SizedBox(), // 작성자가 아니면 빈 위젯 표시
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
              SizedBox(
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
                      overflow:
                          isExpanded
                              ? TextOverflow.visible
                              : TextOverflow.ellipsis,
                    ),

                    // "더보기" 버튼 - 내용이 길 경우에만 표시
                    if (content.length > 80)
                      Padding(
                        padding: const EdgeInsets.only(
                          top: 8.0,
                        ), // 패딩 증가: 6 -> 8
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
                          child: SizedBox(
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
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
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
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
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
                        GestureDetector(
                          onTap: () async {
                            if (commentId != null) {
                              // 기존 좋아요 상태 확인 (댓글 데이터에서 가져오기)
                              final comment = _comments.firstWhere(
                                (c) => c['commentId'] == commentId,
                                orElse: () => {},
                              );

                              final bool currentLikeStatus =
                                  comment['liked'] ?? false;

                              // 댓글 좋아요 API 호출
                              final success =
                                  await FeedService.toggleCommentLike(
                                    commentId,
                                    currentLikeStatus,
                                  );

                              if (success) {
                                setState(() {
                                  // 좋아요 상태 토글
                                  comment['liked'] = !currentLikeStatus;

                                  // 좋아요 수 업데이트
                                  if (comment['liked']) {
                                    comment['likeCount'] =
                                        (comment['likeCount'] ?? 0) + 1;
                                  } else {
                                    comment['likeCount'] =
                                        (comment['likeCount'] ?? 0) - 1;
                                    if (comment['likeCount'] < 0) {
                                      comment['likeCount'] = 0;
                                    }
                                  }
                                });
                              }
                            }
                          },
                          child: SizedBox(
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
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
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
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Image.asset(
                                          'assets/icons/my/좋아요.png',
                                          width: 16,
                                          height: 16,
                                          color:
                                              liked
                                                  ? const Color(
                                                    0xFFFF5C00,
                                                  ) // 좋아요 눌렀을 때 더 진한 색상
                                                  : const Color(0xFFFFA63D),
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
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 대댓글 보기 바텀시트 표시 메서드 추가
  void _showRepliesBottomSheet(int commentId, String authorName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => FeedCommentBottomSheet(
            feedId: widget.feedId,
            feedTitle: _feedItem.title,
            showFeedTitle: true,
            // 특정 댓글의 ID와 작성자 이름 전달하여 대댓글 모드로 열기
            initialCommentId: commentId,
            initialAuthorName: authorName,
            onCommentAdded: (comment) {
              setState(() {
                // 순수 댓글인 경우에만 추가하고 카운트 증가
                if (comment['parentId'] == null || comment['parentId'] == 0) {
                  _comments.insert(0, comment);
                  _commentCount++; // 댓글 수만 증가
                }
              });
            },
            onCommentEdited: (commentId, content) {
              setState(() {
                final index = _comments.indexWhere(
                  (c) => c['commentId'] == commentId,
                );
                if (index != -1) {
                  _comments[index]['content'] = content;
                }
              });
            },
            onCommentDeleted: (commentId) {
              setState(() {
                // 삭제된 댓글 찾기
                final deletedComment = _comments.firstWhere(
                  (c) => c['commentId'] == commentId,
                  orElse: () => <String, dynamic>{},
                );

                // 댓글 목록에서 제거
                _comments.removeWhere((c) => c['commentId'] == commentId);

                // 순수 댓글인 경우에만 카운트 감소
                final bool isParentComment =
                    deletedComment.isNotEmpty &&
                    (deletedComment['parentId'] == null ||
                        deletedComment['parentId'] == 0);

                if (isParentComment) {
                  _commentCount--; // 댓글 수만 감소
                }
              });
            },
            onReplyAdded: (commentId, incrementCount) {
              // 대댓글이 추가되면 해당 댓글의 대댓글 수만 증가
              setState(() {
                final index = _comments.indexWhere(
                  (c) => c['commentId'] == commentId,
                );
                if (index != -1) {
                  _comments[index]['replyCount'] =
                      (_comments[index]['replyCount'] ?? 0) + incrementCount;
                }
              });
            },
          ),
    );
  }

  void _showEditCommentDialog(int? commentId, String content) {
    // 댓글 수정 로직을 구현해야 합니다.
    // 현재는 간단한 팝업을 보여주는 것으로 대체합니다.
    final TextEditingController editController = TextEditingController(
      text: content,
    );

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
                if (commentId != null &&
                    editController.text.trim().isNotEmpty) {
                  // 댓글 수정 API 호출
                  try {
                    final result = await FeedService.updateComment(
                      commentId,
                      editController.text.trim(),
                    );

                    if (result != null) {
                      // UI 업데이트
                      setState(() {
                        final index = _comments.indexWhere(
                          (c) => c['commentId'] == commentId,
                        );
                        if (index != -1) {
                          _comments[index]['content'] =
                              editController.text.trim();
                        }
                      });

                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('댓글이 수정되었습니다.')));
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('오류가 발생했습니다: $e')));
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('삭제할 댓글을 찾을 수 없습니다.')));
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

                  // 삭제하려는 댓글 찾기
                  final commentToDelete = _comments.firstWhere(
                    (c) => c['commentId'] == commentId,
                    orElse: () => <String, dynamic>{},
                  );

                  // 댓글 삭제 API 호출
                  final success = await FeedService.deleteComment(commentId);

                  if (success) {
                    // 성공적으로 삭제된 경우 UI 업데이트
                    setState(() {
                      // 댓글 목록에서 제거
                      _comments.removeWhere((c) => c['commentId'] == commentId);

                      // 삭제한 댓글이 순수 댓글인 경우만 카운트 감소
                      final bool isParentComment =
                          commentToDelete.isNotEmpty &&
                          (commentToDelete['parentId'] == null ||
                              commentToDelete['parentId'] == 0);

                      if (isParentComment) {
                        _commentCount--;
                      }

                      _isLoadingComments = false;
                    });

                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('댓글이 삭제되었습니다.')));
                  } else {
                    // 삭제 실패 시 메시지 표시
                    setState(() {
                      _isLoadingComments = false;
                    });

                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('댓글 삭제에 실패했습니다.')));
                  }
                } catch (e) {
                  // 예외 발생
                  setState(() {
                    _isLoadingComments = false;
                  });

                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('오류가 발생했습니다: $e')));
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
          SizedBox(
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
