import 'package:flutter/material.dart';
import '../../../services/feed_service.dart';
import '../../../services/auth_service.dart';

class FeedCommentBottomSheet extends StatefulWidget {
  final int feedId;
  final String? feedTitle;
  final bool showFeedTitle;
  final Function(Map<String, dynamic>)? onCommentAdded;
  final Function(int, String)? onCommentEdited;
  final Function(int)? onCommentDeleted;
  final Function(int, int)? onReplyAdded;
  final int? initialCommentId;
  final String? initialAuthorName;

  const FeedCommentBottomSheet({
    super.key,
    required this.feedId,
    this.feedTitle,
    this.showFeedTitle = false,
    this.onCommentAdded,
    this.onCommentEdited,
    this.onCommentDeleted,
    this.onReplyAdded,
    this.initialCommentId,
    this.initialAuthorName,
  });

  @override
  State<FeedCommentBottomSheet> createState() => _FeedCommentBottomSheetState();
}

class _FeedCommentBottomSheetState extends State<FeedCommentBottomSheet> {
  final TextEditingController _commentController = TextEditingController();
  bool _isLoading = true;
  bool _isSubmitting = false;
  String _errorMessage = '';
  List<Map<String, dynamic>> _comments = [];

  // 텍스트 입력 감지용 상태
  bool _hasText = false;

  // 페이징 관련 상태
  int _currentPage = 0;
  int _totalPages = 0;
  bool _hasMoreComments = false;
  bool _isLoadingMore = false;

  // 댓글 수정 관련 상태
  int? _editingCommentId;
  final TextEditingController _editCommentController = TextEditingController();

  // 답글 펼침 상태 관리
  final Map<int, bool> _expandedReplies = {};

  // 답글 로딩 상태 관리
  final Map<int, bool> _loadingReplies = {};

  // 댓글별 답글 저장
  final Map<int, List<Map<String, dynamic>>> _repliesMap = {};

  // 대댓글 입력 상태 관리
  int? _replyToCommentId;
  String? _replyToUserName;
  final TextEditingController _replyController = TextEditingController();
  bool _isSubmittingReply = false;
  bool _hasReplyText = false;

  // 대댓글 모드 상태
  bool _isRepliesMode = false;
  int? _initialCommentId;
  Map<String, dynamic>? _initialComment;

  // 현재 로그인한 사용자 정보
  String? _currentUserId;
  String? _currentUserName;

  @override
  void initState() {
    super.initState();

    // 현재 로그인한 사용자 정보 로드
    _loadCurrentUserInfo();

    // 특정 댓글의 대댓글 모드로 열린 경우
    if (widget.initialCommentId != null) {
      _isRepliesMode = true;
      _initialCommentId = widget.initialCommentId;
      _loadInitialComment();
    } else {
      _loadComments();
    }

    // 텍스트 입력 감지 리스너 추가
    _commentController.addListener(_checkText);
    _replyController.addListener(_checkReplyText);
  }

  @override
  void dispose() {
    _commentController.removeListener(_checkText);
    _replyController.removeListener(_checkReplyText);
    _commentController.dispose();
    _editCommentController.dispose();
    _replyController.dispose();
    super.dispose();
  }

  // 텍스트 입력 확인
  void _checkText() {
    final hasText = _commentController.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() {
        _hasText = hasText;
      });
    }
  }

  // 대댓글 텍스트 입력 확인
  void _checkReplyText() {
    final hasText = _replyController.text.trim().isNotEmpty;
    if (hasText != _hasReplyText) {
      setState(() {
        _hasReplyText = hasText;
      });
    }
  }

  Future<void> _loadComments({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _currentPage = 0;
        _isLoading = true;
        _errorMessage = '';
      });
    } else {
      setState(() {
        _isLoadingMore = true;
      });
    }

    try {
      final result = await FeedService.getComments(
        widget.feedId,
        page: _currentPage,
        size: 10,
      );

      if (result != null) {
        final List<dynamic> content = result['content'] ?? [];
        final int totalPages = result['totalPages'] ?? 0;
        final bool isLast = result['last'] ?? true;

        setState(() {
          if (refresh) {
            _comments = List<Map<String, dynamic>>.from(content);
          } else {
            _comments.addAll(List<Map<String, dynamic>>.from(content));
          }
          _totalPages = totalPages;
          _hasMoreComments = !isLast;
          _isLoading = false;
          _isLoadingMore = false;
        });
      } else {
        setState(() {
          _errorMessage = '댓글을 불러올 수 없습니다.';
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '오류가 발생했습니다: $e';
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _loadMoreComments() async {
    if (_hasMoreComments && !_isLoadingMore) {
      _currentPage++;
      await _loadComments();
    }
  }

  // 댓글 시간 형식화 메서드 개선
  String _formatTimeAgo(String? dateTimeStr) {
    if (dateTimeStr == null) return '방금 전';

    try {
      // 서버 시간(UTC) 파싱
      final DateTime serverUtcTime = DateTime.parse(dateTimeStr);

      // 서버 시간을 한국 시간(UTC+9)으로 변환
      final DateTime koreanTime = serverUtcTime.add(Duration(hours: 9));

      // 현재 시간
      final DateTime now = DateTime.now();

      // 시간 차이 계산
      final Duration difference = now.difference(koreanTime);

      // 시간 차이가 음수인 경우 (미래의 날짜)
      if (difference.inSeconds < 0) {
        return '방금 전';
      }

      // 시간 차이에 따른 표시 형식 선택
      if (difference.inDays > 30) {
        final int months = (difference.inDays / 30).floor();
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
      print('시간 파싱 오류: $e');
      return '방금 전';
    }
  }

  // 특정 댓글의 답글 로드 - 중복 방지 로직 강화
  Future<void> _loadReplies(int commentId) async {
    setState(() {
      _loadingReplies[commentId] = true;
    });

    try {
      final result = await FeedService.getReplies(
        commentId,
        page: 0,
        size: 100, // 대댓글은 한번에 더 많이 로드
      );

      if (result != null) {
        final List<dynamic> content = result['content'] ?? [];

        // 로그 추가: 서버에서 반환된 데이터 확인
        print('대댓글 API 응답 - commentId: $commentId, 응답 항목 수: ${content.length}');

        // parentId 기준으로 필터링된 목록 생성 및 로그 출력
        final filteredList =
            List<Map<String, dynamic>>.from(content).where((reply) {
              final bool isValidReply = reply['parentId'] == commentId;
              print(
                '대댓글 필터링 - ID: ${reply['commentId']}, parentId: ${reply['parentId']}, 유효: $isValidReply',
              );
              return isValidReply;
            }).toList();

        print('필터링 후 대댓글 수: ${filteredList.length}');

        setState(() {
          _repliesMap[commentId] = filteredList;
          _loadingReplies[commentId] = false;
        });
      } else {
        setState(() {
          _repliesMap[commentId] = [];
          _loadingReplies[commentId] = false;
        });
      }
    } catch (e) {
      print('대댓글 로드 중 오류 발생: $e');
      setState(() {
        _loadingReplies[commentId] = false;
      });
    }
  }

  Future<void> _submitComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('댓글 내용을 입력해주세요')));
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final result = await FeedService.createComment(widget.feedId, content);

      if (result != null) {
        // 댓글 등록 성공
        _commentController.clear();

        // 새 댓글 데이터
        final newComment = {
          'commentId': result['commentId'],
          'feedId': result['feedId'],
          'writerName': result['writerName'] ?? '나',
          'writerProfileUrl': result['writerProfileUrl'],
          'content': content,
          'createdDate': DateTime.now().toIso8601String(),
          'lastModifiedDate': DateTime.now().toIso8601String(),
          'likeCount': 0,
          'isliked': false,
          'replyCount': 0,
        };

        // 새 댓글을 목록에 추가
        setState(() {
          _comments.insert(0, newComment);
          _isSubmitting = false;
        });

        // 콜백 호출
        if (widget.onCommentAdded != null) {
          widget.onCommentAdded!(newComment);
        }
      } else {
        // 댓글 등록 실패
        setState(() {
          _isSubmitting = false;
        });

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('댓글 등록에 실패했습니다.')));
      }
    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('오류가 발생했습니다: $e')));
    }
  }

  // 댓글 삭제
  Future<void> _deleteComment(int commentId) async {
    // 확인 다이얼로그 표시
    final shouldDelete =
        await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: Text('댓글 삭제'),
                content: Text('정말 이 댓글을 삭제하시겠습니까?'),
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

    if (!shouldDelete) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await FeedService.deleteComment(commentId);

      if (success) {
        // 댓글 삭제 성공
        setState(() {
          // 댓글이 대댓글 모드에서 삭제된 경우 바텀시트 닫기
          if (_isRepliesMode && _initialCommentId == commentId) {
            Navigator.of(context).pop();
            return;
          }

          // 일반 댓글 모드에서 삭제된 경우 목록에서 제거
          _comments.removeWhere((comment) => comment['commentId'] == commentId);
          _isLoading = false;
        });

        // 콜백 호출
        if (widget.onCommentDeleted != null) {
          widget.onCommentDeleted!(commentId);
        }

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('댓글이 삭제되었습니다.')));
      } else {
        // 댓글 삭제 실패
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('댓글 삭제에 실패했습니다.')));
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('오류가 발생했습니다: $e')));
    }
  }

  // 답글 토글
  void _toggleReplies(int commentId) {
    // 이미 펼쳐진 상태면 접기, 아니면 펼치기
    setState(() {
      if (_expandedReplies[commentId] == true) {
        _expandedReplies[commentId] = false;
      } else {
        _expandedReplies[commentId] = true;

        // 아직 답글을 로드하지 않았다면 로드
        if (!_repliesMap.containsKey(commentId)) {
          _loadReplies(commentId);
        }
      }
    });
  }

  // 댓글 수정 모드 시작
  void _startEditComment(Map<String, dynamic> comment) {
    setState(() {
      _editingCommentId = comment['commentId'];
      _editCommentController.text = comment['content'] ?? '';
    });
  }

  // 댓글 수정 취소
  void _cancelEditComment() {
    setState(() {
      _editingCommentId = null;
      _editCommentController.clear();
    });
  }

  // 댓글 수정 제출
  Future<void> _submitEditComment() async {
    if (_editingCommentId == null) return;

    final content = _editCommentController.text.trim();
    if (content.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await FeedService.updateComment(
        _editingCommentId!,
        content,
      );

      if (result != null) {
        // 댓글 수정 성공
        final index = _comments.indexWhere(
          (comment) => comment['commentId'] == _editingCommentId,
        );

        if (index != -1) {
          setState(() {
            _comments[index]['content'] = content;
            _comments[index]['lastModifiedDate'] =
                DateTime.now().toIso8601String();
            _editingCommentId = null;
            _editCommentController.clear();
            _isLoading = false;
          });

          // 콜백 호출
          if (widget.onCommentEdited != null) {
            widget.onCommentEdited!(_editingCommentId!, content);
          }
        }

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('댓글이 수정되었습니다.')));
      } else {
        // 댓글 수정 실패
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('댓글 수정에 실패했습니다.')));
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('오류가 발생했습니다: $e')));
    }
  }

  // 대댓글 입력 모드 시작
  void _startReplyMode(int commentId, String writerName) {
    setState(() {
      _replyToCommentId = commentId;
      _replyToUserName = writerName;
      _replyController.clear();
    });
  }

  // 대댓글 입력 모드 취소
  void _cancelReplyMode() {
    setState(() {
      _replyToCommentId = null;
      _replyToUserName = null;
      _replyController.clear();
    });
  }

  // 대댓글 제출
  Future<void> _submitReply() async {
    if (_replyToCommentId == null) return;

    final content = _replyController.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('답글 내용을 입력해주세요')));
      return;
    }

    setState(() {
      _isSubmittingReply = true;
    });

    try {
      final result = await FeedService.createReply(
        widget.feedId,
        _replyToCommentId!,
        content,
      );

      if (result != null) {
        // 대댓글 등록 성공
        _replyController.clear();

        // 이미 펼쳐져 있는 경우 대댓글 목록에 추가
        if (_expandedReplies[_replyToCommentId!] == true) {
          if (!_repliesMap.containsKey(_replyToCommentId)) {
            _repliesMap[_replyToCommentId!] = [];
          }

          setState(() {
            _repliesMap[_replyToCommentId!]!.add(result);
            _isSubmittingReply = false;
          });
        } else {
          // 대댓글이 있음을 표시하기 위해 댓글 데이터 업데이트
          final index = _comments.indexWhere(
            (comment) => comment['commentId'] == _replyToCommentId,
          );
          if (index != -1) {
            setState(() {
              _comments[index]['replyCount'] =
                  (_comments[index]['replyCount'] ?? 0) + 1;
              _isSubmittingReply = false;
            });
          }
        }

        // 대댓글 입력 모드 종료
        _cancelReplyMode();

        // 상위 화면에 대댓글 추가 알림
        if (widget.onReplyAdded != null) {
          widget.onReplyAdded!(_replyToCommentId!, 1);
        }

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('답글이 등록되었습니다.')));
      } else {
        // 대댓글 등록 실패
        setState(() {
          _isSubmittingReply = false;
        });

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('답글 등록에 실패했습니다.')));
      }
    } catch (e) {
      setState(() {
        _isSubmittingReply = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('오류가 발생했습니다: $e')));
    }
  }

  // 특정 댓글을 로드하고 해당 대댓글 표시 (대댓글 모드)
  Future<void> _loadInitialComment() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // 먼저 해당 댓글 정보 가져오기
      final comments = await FeedService.getComments(
        widget.feedId,
        page: 0,
        size: 100, // 충분히 많은 댓글을 가져와서 찾기
      );

      if (comments != null && comments['content'] is List) {
        final commentsList = List<Map<String, dynamic>>.from(
          comments['content'],
        );

        // 해당 ID의 댓글 찾기
        final targetComment = commentsList.firstWhere(
          (comment) => comment['commentId'] == _initialCommentId,
          orElse: () => {},
        );

        if (targetComment.isNotEmpty) {
          // 댓글을 찾았으면 저장하고 대댓글 로드
          setState(() {
            _initialComment = targetComment;
            _expandedReplies[_initialCommentId!] = true;
          });

          // 대댓글 로드
          await _loadReplies(_initialCommentId!);

          // 미리 대댓글 입력 모드 시작
          if (widget.initialAuthorName != null) {
            _startReplyMode(_initialCommentId!, widget.initialAuthorName!);
          }
        } else {
          // 댓글을 찾지 못한 경우 일반 댓글 모드로 전환
          setState(() {
            _isRepliesMode = false;
            _initialCommentId = null;
          });
          _loadComments();
        }
      } else {
        // 댓글 목록을 가져오지 못한 경우
        setState(() {
          _isRepliesMode = false;
          _initialCommentId = null;
          _isLoading = false;
          _errorMessage = '댓글을 찾을 수 없습니다.';
        });
        _loadComments();
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '오류가 발생했습니다: $e';
        _isRepliesMode = false;
        _initialCommentId = null;
      });
      _loadComments();
    }
  }

  // 로그인한 사용자 정보를 로드하는 메서드
  Future<void> _loadCurrentUserInfo() async {
    try {
      // 서버에서 최신 사용자 정보 조회 시도
      try {
        final serverUserInfo = await AuthService.getUserInfo();
        print('서버에서 가져온 사용자 정보: $serverUserInfo');

        // 사용자 ID와 이름 가져오기
        final userId = serverUserInfo['id']?.toString();
        final userName = serverUserInfo['name']?.toString();

        if (mounted) {
          setState(() {
            _currentUserId = userId;
            _currentUserName = userName;
          });

          print('서버에서 가져온 현재 사용자 정보: ID=$_currentUserId, 이름=$_currentUserName');
        }
        return;
      } catch (serverError) {
        print('서버에서 사용자 정보 조회 실패, 로컬 정보 사용: $serverError');
      }

      // 서버 조회에 실패한 경우 로컬 정보 사용
      final userId = await AuthService.getCurrentUserId();
      final userName = await AuthService.getCurrentUserName();
      print('로컬에서 가져온 현재 사용자 정보: ID=$userId, 이름=$userName');

      if (mounted) {
        setState(() {
          _currentUserId = userId;
          _currentUserName = userName;
        });
      }
    } catch (e) {
      print('현재 사용자 정보 로드 중 오류: $e');
    }
  }

  // 현재 로그인한 사용자가 댓글 작성자인지 확인
  bool _isCommentOwner(Map<String, dynamic> comment) {
    // 디버그 로그 추가
    print('댓글 작성자 확인: 현재 사용자 ID=$_currentUserId, 이름=$_currentUserName');
    print('댓글 정보: $comment');

    // 로그인한 사용자나 댓글 정보가 없는 경우
    if ((_currentUserId == null && _currentUserName == null) ||
        comment.isEmpty) {
      return false;
    }

    // writerId 필드로 비교
    if (comment.containsKey('writerId') && _currentUserId != null) {
      final String commentWriterId = comment['writerId'].toString();
      final String currentUserId = _currentUserId.toString();
      final bool isMatch = commentWriterId == currentUserId;
      print('writerId 비교: $commentWriterId vs $currentUserId = $isMatch');
      if (isMatch) return true;
    }

    // writerName 필드로 비교
    if (comment.containsKey('writerName') && _currentUserName != null) {
      final String commentWriterName = comment['writerName'].toString();
      final String currentUserName = _currentUserName.toString();
      final bool isMatch = commentWriterName == currentUserName;
      print('writerName 비교: $commentWriterName vs $currentUserName = $isMatch');
      if (isMatch) return true;
    }

    // userId 필드로 비교 (대체 필드명)
    if (comment.containsKey('userId') && _currentUserId != null) {
      final String commentUserId = comment['userId'].toString();
      final String currentUserId = _currentUserId.toString();
      final bool isMatch = commentUserId == currentUserId;
      print('userId 비교: $commentUserId vs $currentUserId = $isMatch');
      if (isMatch) return true;
    }

    // writerId 필드가 문자열이 아닌 숫자로 저장된 경우
    if (comment.containsKey('writerId') && _currentUserId != null) {
      try {
        final int commentWriterId = int.parse(comment['writerId'].toString());
        final int currentUserId = int.parse(_currentUserId.toString());
        final bool isMatch = commentWriterId == currentUserId;
        print('writerId 숫자 비교: $commentWriterId vs $currentUserId = $isMatch');
        if (isMatch) return true;
      } catch (e) {
        print('writerId 숫자 변환 오류: $e');
      }
    }

    return false;
  }

  // 대댓글 수정 시작 메서드
  void _startEditReply(Map<String, dynamic> reply) {
    setState(() {
      _editingCommentId = reply['commentId'];
      _editCommentController.text = reply['content'] ?? '';
    });
  }

  // 대댓글 수정 제출 메서드
  Future<void> _submitEditReply() async {
    if (_editingCommentId == null) return;

    final content = _editCommentController.text.trim();
    if (content.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // 부모 ID를 포함하여 수정 API 호출
      final result = await FeedService.updateComment(
        _editingCommentId!,
        content,
      );

      if (result != null) {
        // 대댓글 수정 성공
        // 모든 대댓글 맵을 순회하며 수정된 대댓글 찾기
        bool found = false;
        for (final parentId in _repliesMap.keys) {
          final replyIndex = _repliesMap[parentId]!.indexWhere(
            (reply) => reply['commentId'] == _editingCommentId,
          );

          if (replyIndex != -1) {
            setState(() {
              _repliesMap[parentId]![replyIndex]['content'] = content;
              _repliesMap[parentId]![replyIndex]['lastModifiedDate'] =
                  DateTime.now().toIso8601String();
              found = true;
            });
            break;
          }
        }

        setState(() {
          _editingCommentId = null;
          _editCommentController.clear();
          _isLoading = false;
        });

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('답글이 수정되었습니다.')));
      } else {
        // 대댓글 수정 실패
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('답글 수정에 실패했습니다.')));
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('오류가 발생했습니다: $e')));
    }
  }

  // 대댓글(답글) 삭제 메서드 추가
  Future<void> _deleteReply(Map<String, dynamic> reply) async {
    final int commentId = reply['commentId'];
    final int parentId = reply['parentId'] ?? 0;

    // 확인 다이얼로그 표시
    final shouldDelete =
        await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: Text('답글 삭제'),
                content: Text('정말 이 답글을 삭제하시겠습니까?'),
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

    if (!shouldDelete) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await FeedService.deleteComment(commentId);

      if (success) {
        setState(() {
          // 삭제된 답글을 목록에서 제거
          if (_repliesMap.containsKey(parentId)) {
            _repliesMap[parentId]!.removeWhere(
              (r) => r['commentId'] == commentId,
            );

            // 원본 댓글의 답글 수 감소
            final commentIndex = _comments.indexWhere(
              (c) => c['commentId'] == parentId,
            );
            if (commentIndex != -1 &&
                _comments[commentIndex]['replyCount'] != null) {
              _comments[commentIndex]['replyCount'] =
                  (_comments[commentIndex]['replyCount'] - 1)
                      .clamp(0, double.infinity)
                      .toInt();
            }
          }
          _isLoading = false;
        });

        // 콜백 호출 (부모 댓글의 대댓글 수 업데이트를 위해)
        if (widget.onReplyAdded != null) {
          widget.onReplyAdded!(parentId, -1); // -1을 전달하여 감소 표시
        }

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('답글이 삭제되었습니다.')));
      } else {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('답글 삭제에 실패했습니다.')));
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('오류가 발생했습니다: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    // 키보드 높이를 고려하여 바텀시트 높이 조정
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Color(0x5B000000),
            blurRadius: 8,
            offset: Offset(0, -4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Padding(
        // 키보드 높이만큼 패딩 추가
        padding: EdgeInsets.only(bottom: bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상단 헤더 영역
            Container(
              width: double.infinity,
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
                  SizedBox(
                    height: 32,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              _isRepliesMode ? '답글' : '댓글',
                              style: TextStyle(
                                color: const Color(0xFF202020),
                                fontSize: 18,
                                fontFamily: 'Pretendard-Bold',
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.72,
                              ),
                            ),
                            SizedBox(width: 8),
                            if (!_isRepliesMode)
                              Text(
                                '${_comments.length}',
                                style: TextStyle(
                                  color: const Color(0xFF5D9EFF),
                                  fontSize: 18,
                                  fontFamily: 'Pretendard-Bold',
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.72,
                                ),
                              ),
                            if (_isRepliesMode && _initialComment != null)
                              Text(
                                '${_repliesMap[_initialCommentId]?.length ?? 0}',
                                style: TextStyle(
                                  color: const Color(0xFF5D9EFF),
                                  fontSize: 18,
                                  fontFamily: 'Pretendard-Bold',
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.72,
                                ),
                              ),
                          ],
                        ),

                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: Icon(
                              Icons.close,
                              size: 22,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 댓글/대댓글 목록 영역
            Flexible(
              child: Container(
                // 키보드가 올라오면 화면을 차지하는 공간이 줄어들므로,
                // 댓글 목록 영역의 높이를 고정하지 않고 유연하게 설정
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.45,
                  minHeight: 100, // 최소 높이 설정
                ),
                color: Colors.white,
                child:
                    _isLoading
                        ? Center(
                          child: CircularProgressIndicator(
                            color: const Color(0xFF5D9EFF),
                          ),
                        )
                        : _errorMessage.isNotEmpty
                        ? Center(
                          child: Text(
                            _errorMessage,
                            style: TextStyle(color: Colors.red),
                          ),
                        )
                        : _isRepliesMode
                        ? _buildRepliesMode()
                        : _buildCommentsMode(),
              ),
            ),

            // 댓글 입력창
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 대댓글 입력 모드인 경우 표시되는 정보
                  if (_replyToCommentId != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '$_replyToUserName님에게 답글 작성 중',
                            style: TextStyle(
                              color: const Color(0xFF5D9EFF),
                              fontSize: 12,
                              fontFamily: 'Pretendard-Medium',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          GestureDetector(
                            onTap: _cancelReplyMode,
                            child: Text(
                              '취소',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 12,
                                fontFamily: 'Pretendard-Medium',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // 댓글/대댓글 입력 필드
                  Container(
                    width: double.infinity,
                    height: 40,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: ShapeDecoration(
                      color: const Color.fromRGBO(240, 242, 247, 1),
                      shape: RoundedRectangleBorder(
                        side: BorderSide(
                          width: 0.80,
                          color: const Color(0xFF8096BA),
                        ),
                        borderRadius: BorderRadius.circular(32),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: TextField(
                            controller:
                                _replyToCommentId != null
                                    ? _replyController
                                    : _commentController,
                            decoration: InputDecoration(
                              hintText:
                                  _replyToCommentId != null
                                      ? '답글을 입력해 주세요'
                                      : '댓글을 입력해 주세요',
                              hintStyle: TextStyle(
                                color: const Color(0xFF999999),
                                fontSize: 14,
                                fontFamily: 'Pretendard',
                                fontWeight: FontWeight.w300,
                                letterSpacing: -0.28,
                              ),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                              isDense: true,
                              filled: true,
                              fillColor: const Color.fromRGBO(240, 242, 247, 1),
                            ),
                            style: TextStyle(
                              color: const Color(0xFF202020),
                              fontSize: 14,
                              fontFamily: 'Pretendard-Regular',
                            ),
                            textAlignVertical: TextAlignVertical.center,
                            onSubmitted: (_) {
                              if (_replyToCommentId != null) {
                                _submitReply();
                              } else {
                                _submitComment();
                              }
                            },
                          ),
                        ),
                        _replyToCommentId != null && _isSubmittingReply ||
                                _replyToCommentId == null && _isSubmitting
                            ? SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: const Color(0xFF5D9EFF),
                              ),
                            )
                            : GestureDetector(
                              onTap: () {
                                if (_replyToCommentId != null) {
                                  _submitReply();
                                } else {
                                  _submitComment();
                                }
                              },
                              child: Image.asset(
                                'assets/images/댓글작성.png',
                                width: 24,
                                height: 24,
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
    );
  }

  // 대댓글 모드 UI 개선 - 구분선 제거하고 댓글 아래에 대댓글 붙이기
  Widget _buildRepliesMode() {
    if (_initialComment == null) {
      return Center(
        child: Text(
          '해당 댓글을 찾을 수 없습니다.',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
            fontFamily: 'Pretendard-Light',
          ),
        ),
      );
    }

    final List<Map<String, dynamic>> replies =
        _repliesMap[_initialCommentId!] ?? [];
    final bool hasReplies = replies.isNotEmpty;
    final bool isExpanded = _expandedReplies[_initialCommentId!] ?? false;

    return ListView(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      children: [
        // 원본 댓글 표시
        _buildCommentItem(_initialComment!),

        // 대댓글 영역
        if (_loadingReplies[_initialCommentId!] == true)
          Padding(
            padding: const EdgeInsets.only(left: 56.0, top: 16.0),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: const Color(0xFF5D9EFF),
                ),
              ),
            ),
          )
        else if (!hasReplies)
          Padding(
            padding: const EdgeInsets.only(left: 56.0, top: 16.0),
            child: Text(
              '아직 답글이 없습니다.\n첫 답글을 작성해보세요!',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
                fontFamily: 'Pretendard-Light',
              ),
              textAlign: TextAlign.start,
            ),
          )
        else if (isExpanded)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...replies.map((reply) {
                // 대댓글 여부 다시 확인
                if (reply['parentId'] != null &&
                    reply['parentId'] == _initialCommentId) {
                  return Padding(
                    padding: const EdgeInsets.only(left: 56.0, top: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildReplyItem(reply),
                        // 마지막 답글인 경우에만 "답글 숨기기" 버튼 추가
                        if (reply == replies.last)
                          Padding(
                            padding: const EdgeInsets.only(
                              top: 8.0,
                              left: 50.0,
                            ),
                            child: GestureDetector(
                              onTap: () => _toggleReplies(_initialCommentId!),
                              child: Text(
                                '답글 숨기기',
                                style: TextStyle(
                                  color: const Color(0xFFC4C4C4),
                                  fontSize: 11,
                                  fontFamily: 'Pretendard',
                                  fontWeight: FontWeight.w300,
                                  letterSpacing: -0.22,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                } else {
                  return SizedBox.shrink();
                }
              }),
            ],
          )
        else
          // "답글 보기" 버튼
          Padding(
            padding: const EdgeInsets.only(left: 56.0, top: 8.0),
            child: GestureDetector(
              onTap: () => _toggleReplies(_initialCommentId!),
              child: Text(
                '${replies.length}개의 답글 보기',
                style: TextStyle(
                  color: const Color(0xFFC4C4C4),
                  fontSize: 11,
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w300,
                  letterSpacing: -0.22,
                ),
              ),
            ),
          ),
      ],
    );
  }

  // 일반 댓글 모드 UI
  Widget _buildCommentsMode() {
    return _comments.isEmpty
        ? Center(
          child: Text(
            '아직 댓글이 없습니다.\n첫 댓글을 작성해보세요!',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
              fontFamily: 'Pretendard-Light',
            ),
            textAlign: TextAlign.center,
          ),
        )
        : ListView.builder(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          itemCount: _comments.length + (_isLoadingMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == _comments.length) {
              _loadMoreComments();
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: const Color(0xFF5D9EFF),
                  ),
                ),
              );
            }

            final comment = _comments[index];
            final int commentId = comment['commentId'];
            final bool isExpanded = _expandedReplies[commentId] ?? false;
            final bool hasReplies = (comment['replyCount'] ?? 0) > 0;
            final List<Map<String, dynamic>> replies =
                _repliesMap[commentId] ?? [];

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 댓글
                _buildCommentItem(comment),

                // "답글 보기" 버튼
                if (hasReplies && !isExpanded)
                  Padding(
                    padding: const EdgeInsets.only(left: 56.0, top: 8.0),
                    child: GestureDetector(
                      onTap: () => _toggleReplies(commentId),
                      child: Text(
                        '${comment['replyCount']}개의 답글 보기',
                        style: TextStyle(
                          color: const Color(0xFFC4C4C4),
                          fontSize: 11,
                          fontFamily: 'Pretendard',
                          fontWeight: FontWeight.w300,
                          letterSpacing: -0.22,
                        ),
                      ),
                    ),
                  ),

                // 대댓글 영역
                if (isExpanded)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 대댓글 목록
                      if (_loadingReplies[commentId] == true)
                        Padding(
                          padding: const EdgeInsets.only(left: 56.0, top: 16.0),
                          child: Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: const Color(0xFF5D9EFF),
                              ),
                            ),
                          ),
                        )
                      else if (replies.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(left: 56.0, top: 16.0),
                          child: Text(
                            '아직 답글이 없습니다.',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                              fontFamily: 'Pretendard-Light',
                            ),
                          ),
                        )
                      else
                        ...replies.map((reply) {
                          if (reply['parentId'] != null &&
                              reply['parentId'] == commentId) {
                            return Padding(
                              padding: const EdgeInsets.only(
                                left: 56.0,
                                top: 16.0,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildReplyItem(reply),

                                  // 마지막 답글인 경우에만 "답글 숨기기" 버튼 추가
                                  if (reply == replies.last)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        top: 8.0,
                                        left: 50.0,
                                      ),
                                      child: GestureDetector(
                                        onTap: () => _toggleReplies(commentId),
                                        child: Text(
                                          '답글 숨기기',
                                          style: TextStyle(
                                            color: const Color(0xFFC4C4C4),
                                            fontSize: 11,
                                            fontFamily: 'Pretendard',
                                            fontWeight: FontWeight.w300,
                                            letterSpacing: -0.22,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          } else {
                            return SizedBox.shrink();
                          }
                        }),
                    ],
                  ),

                if (index < _comments.length - 1) SizedBox(height: 24),
              ],
            );
          },
        );
  }

  // 댓글 아이템 위젯 수정
  Widget _buildCommentItem(Map<String, dynamic> comment) {
    final bool isEditing = _editingCommentId == comment['commentId'];
    final int commentId = comment['commentId'];
    final int replyCount = comment['replyCount'] ?? 0;
    final bool isExpanded = _expandedReplies[commentId] ?? false;
    final bool isLoadingReplies = _loadingReplies[commentId] ?? false;
    final bool hasReplies = replyCount > 0;

    // 현재 로그인한 사용자가 댓글 작성자인지 확인
    final bool isOwner = _isCommentOwner(comment);
    print('댓글 작성자 여부: $isOwner (댓글 ID: $commentId)');

    // 날짜 포맷팅 - createdDate 필드 사용
    String formattedDate = '방금 전';
    if (comment['createdDate'] != null) {
      formattedDate = _formatTimeAgo(comment['createdDate']);
    }

    return SizedBox(
      width: double.infinity,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 프로필 이미지
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.grey[300],
            backgroundImage:
                comment['writerProfileUrl'] != null &&
                        comment['writerProfileUrl'].toString().isNotEmpty
                    ? NetworkImage(
                      AuthService.getFullProfileImageUrl(
                        comment['writerProfileUrl'],
                      ),
                    )
                    : null,
            child:
                comment['writerProfileUrl'] == null ||
                        comment['writerProfileUrl'].toString().isEmpty
                    ? Text(
                      comment['writerName']?.toString().isNotEmpty == true
                          ? comment['writerName'][0]
                          : '?',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    )
                    : null,
          ),
          SizedBox(width: 16),

          // 댓글 내용 영역
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 작성자 및 시간
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          comment['writerName'] ?? '김뱅뱅',
                          style: TextStyle(
                            color: const Color(0xFF202020),
                            fontSize: 14,
                            fontFamily: 'Pretendard-Bold',
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.28,
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          formattedDate,
                          style: TextStyle(
                            color: const Color(0xFF999999),
                            fontSize: 11,
                            fontFamily: 'Pretendard-Light',
                            fontWeight: FontWeight.w300,
                            letterSpacing: -0.22,
                          ),
                        ),
                      ],
                    ),

                    // 메뉴 버튼 (이미지로 변경) - 작성자만 활성화됨
                    GestureDetector(
                      onTap:
                          isOwner
                              ? () {
                                // 더 보기 메뉴 표시
                                showModalBottomSheet(
                                  context: context,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(16),
                                    ),
                                  ),
                                  builder:
                                      (context) => Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          SizedBox(height: 8),
                                          Container(
                                            width: 40,
                                            height: 4,
                                            decoration: BoxDecoration(
                                              color: Colors.grey[300],
                                              borderRadius:
                                                  BorderRadius.circular(2),
                                            ),
                                          ),
                                          SizedBox(height: 16),
                                          ListTile(
                                            leading: Icon(
                                              Icons.edit,
                                              color: Colors.blue,
                                            ),
                                            title: Text(
                                              '수정하기',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontFamily: 'Pretendard-Medium',
                                              ),
                                            ),
                                            onTap: () {
                                              Navigator.pop(context);
                                              _startEditComment(comment);
                                            },
                                          ),
                                          ListTile(
                                            leading: Icon(
                                              Icons.delete,
                                              color: Colors.red,
                                            ),
                                            title: Text(
                                              '삭제하기',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontFamily: 'Pretendard-Medium',
                                                color: Colors.red,
                                              ),
                                            ),
                                            onTap: () {
                                              Navigator.pop(context);
                                              _deleteComment(commentId);
                                            },
                                          ),
                                          SizedBox(height: 16),
                                        ],
                                      ),
                                );
                              }
                              : null,
                      child: Image.asset(
                        'assets/images/더보기.png',
                        width: 16,
                        height: 16,
                        color: isOwner ? Colors.grey[600] : Colors.grey[300],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),

                // 댓글 내용
                if (isEditing)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _editCommentController,
                        decoration: InputDecoration(
                          hintText: '댓글을 입력하세요',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(4),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        style: TextStyle(
                          color: const Color(0xFF4A4A4A),
                          fontSize: 13,
                          fontFamily: 'Pretendard-Light',
                          height: 1.4,
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: _cancelEditComment,
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.grey[600],
                              minimumSize: Size(0, 28),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              padding: EdgeInsets.symmetric(horizontal: 12),
                            ),
                            child: Text('취소', style: TextStyle(fontSize: 13)),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _submitEditComment,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF5D9EFF),
                              foregroundColor: Colors.white,
                              minimumSize: Size(0, 28),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              elevation: 0,
                              padding: EdgeInsets.symmetric(horizontal: 12),
                            ),
                            child: Text(
                              '수정 완료',
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ],
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: Text(
                      comment['content'] ?? '',
                      style: TextStyle(
                        color: const Color(0xFF4A4A4A),
                        fontSize: 12,
                        fontFamily: 'Pretendard-Light',
                        fontWeight: FontWeight.w300,
                        height: 1.50,
                        letterSpacing: -0.24,
                      ),
                    ),
                  ),
                SizedBox(height: 12),

                // 댓글 달기/좋아요 버튼 - 한 줄에 나란히 배치
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    // 댓글 달기 버튼
                    GestureDetector(
                      onTap: () {
                        // 대댓글 입력 모드 시작
                        _startReplyMode(
                          commentId,
                          comment['writerName'] ?? '김뱅뱅',
                        );
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            'assets/icons/my/댓글.png',
                            width: 16,
                            height: 16,
                            color: const Color(0xFFFFA63D),
                          ),
                          SizedBox(width: 4),
                          Text(
                            '댓글 달기',
                            style: TextStyle(
                              color: const Color(0xFFFFA63D),
                              fontSize: 12,
                              fontFamily: 'Pretendard-Light',
                              fontWeight: FontWeight.w300,
                              letterSpacing: -0.24,
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(width: 16),

                    // 좋아요 버튼
                    GestureDetector(
                      onTap: () async {
                        // 댓글 좋아요 토글
                        final bool currentLikeStatus =
                            comment['isliked'] ?? false;
                        final success = await FeedService.toggleCommentLike(
                          commentId,
                          currentLikeStatus,
                        );

                        if (success) {
                          setState(() {
                            // 좋아요 상태 토글
                            comment['isliked'] = !currentLikeStatus;

                            // 좋아요 수 업데이트
                            if (comment['isliked']) {
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
                      },
                      child: Container(
                        height: 24,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: ShapeDecoration(
                          shape: RoundedRectangleBorder(
                            side: BorderSide(
                              width: 0.65,
                              color:
                                  (comment['isliked'] ?? false)
                                      ? const Color(0xFFFFA63D)
                                      : const Color(0xFFFFD27F),
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
                              width: 14,
                              height: 14,
                              color:
                                  (comment['isliked'] ?? false)
                                      ? const Color(0xFFFFA63D)
                                      : const Color(0xFFFFD27F),
                            ),
                            SizedBox(width: 4),
                            Text(
                              '${comment['likeCount'] ?? 0}',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color:
                                    (comment['isliked'] ?? false)
                                        ? const Color(0xFFFFA63D)
                                        : const Color(0xFFFFD27F),
                                fontSize: 12,
                                fontFamily: 'Pretendard-Medium',
                                fontWeight: FontWeight.w500,
                                height: 0.9,
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

  // 답글 아이템 위젯 수정
  Widget _buildReplyItem(Map<String, dynamic> reply) {
    // 날짜 포맷팅 - createdDate 필드 사용
    String formattedDate = '방금 전';
    if (reply['createdDate'] != null) {
      formattedDate = _formatTimeAgo(reply['createdDate']);
    }

    // 대댓글 수정 중인지 확인
    final bool isEditing = _editingCommentId == reply['commentId'];

    // 현재 로그인한 사용자가 답글 작성자인지 확인
    final bool isOwner = _isCommentOwner(reply);
    print('답글 작성자 여부: $isOwner (답글 ID: ${reply['commentId']})');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 프로필 이미지
            CircleAvatar(
              radius: 14,
              backgroundColor: Colors.grey[300],
              backgroundImage:
                  reply['writerProfileUrl'] != null &&
                          reply['writerProfileUrl'].toString().isNotEmpty
                      ? NetworkImage(
                        AuthService.getFullProfileImageUrl(
                          reply['writerProfileUrl'],
                        ),
                      )
                      : null,
              child:
                  reply['writerProfileUrl'] == null ||
                          reply['writerProfileUrl'].toString().isEmpty
                      ? Text(
                        reply['writerName']?.toString().isNotEmpty == true
                            ? reply['writerName'][0]
                            : '?',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      )
                      : null,
            ),
            SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 작성자 및 시간
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            reply['writerName'] ?? '김뱅뱅',
                            style: TextStyle(
                              color: const Color(0xFF202020),
                              fontSize: 13,
                              fontFamily: 'Pretendard-Bold',
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.28,
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            formattedDate,
                            style: TextStyle(
                              color: const Color(0xFF999999),
                              fontSize: 11,
                              fontFamily: 'Pretendard-Light',
                              fontWeight: FontWeight.w300,
                              letterSpacing: -0.22,
                            ),
                          ),
                        ],
                      ),

                      // 메뉴 버튼 (이미지로 변경) - 작성자만 활성화됨
                      GestureDetector(
                        onTap:
                            isOwner
                                ? () {
                                  // 더 보기 메뉴 표시
                                  showModalBottomSheet(
                                    context: context,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.vertical(
                                        top: Radius.circular(16),
                                      ),
                                    ),
                                    builder:
                                        (context) => Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            SizedBox(height: 8),
                                            Container(
                                              width: 40,
                                              height: 4,
                                              decoration: BoxDecoration(
                                                color: Colors.grey[300],
                                                borderRadius:
                                                    BorderRadius.circular(2),
                                              ),
                                            ),
                                            SizedBox(height: 16),
                                            ListTile(
                                              leading: Icon(
                                                Icons.edit,
                                                color: Colors.blue,
                                              ),
                                              title: Text(
                                                '수정하기',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontFamily:
                                                      'Pretendard-Medium',
                                                ),
                                              ),
                                              onTap: () {
                                                Navigator.pop(context);
                                                _startEditReply(reply);
                                              },
                                            ),
                                            ListTile(
                                              leading: Icon(
                                                Icons.delete,
                                                color: Colors.red,
                                              ),
                                              title: Text(
                                                '삭제하기',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontFamily:
                                                      'Pretendard-Medium',
                                                  color: Colors.red,
                                                ),
                                              ),
                                              onTap: () {
                                                Navigator.pop(context);
                                                _deleteReply(reply);
                                              },
                                            ),
                                            SizedBox(height: 16),
                                          ],
                                        ),
                                  );
                                }
                                : null,
                        child: Image.asset(
                          'assets/images/더보기.png',
                          width: 16,
                          height: 16,
                          color: isOwner ? Colors.grey[600] : Colors.grey[300],
                        ),
                      ),
                    ],
                  ),

                  // 대댓글 내용 (수정 모드일 때는 텍스트 필드 표시)
                  if (isEditing)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _editCommentController,
                          decoration: InputDecoration(
                            hintText: '답글을 입력하세요',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          style: TextStyle(
                            color: const Color(0xFF4A4A4A),
                            fontSize: 12,
                            fontFamily: 'Pretendard-Light',
                            height: 1.4,
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: _cancelEditComment,
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.grey[600],
                                minimumSize: Size(0, 28),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                padding: EdgeInsets.symmetric(horizontal: 12),
                              ),
                              child: Text('취소', style: TextStyle(fontSize: 13)),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: _submitEditReply,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF5D9EFF),
                                foregroundColor: Colors.white,
                                minimumSize: Size(0, 28),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                elevation: 0,
                                padding: EdgeInsets.symmetric(horizontal: 12),
                              ),
                              child: Text(
                                '수정 완료',
                                style: TextStyle(fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      child: Text(
                        reply['content'] ?? '',
                        style: TextStyle(
                          color: const Color(0xFF4A4A4A),
                          fontSize: 12,
                          fontFamily: 'Pretendard-Light',
                          fontWeight: FontWeight.w300,
                          height: 1.50,
                          letterSpacing: -0.24,
                        ),
                      ),
                    ),

                  if (!isEditing) SizedBox(height: 12),

                  // 댓글 달기/좋아요 버튼 (수정 모드가 아닐 때만 표시)
                  if (!isEditing)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        // 대댓글의 댓글 달기 버튼
                        GestureDetector(
                          onTap: () {
                            // 대댓글에 댓글 달기 기능
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Image.asset(
                                'assets/icons/my/댓글.png',
                                width: 14,
                                height: 14,
                                color: const Color(0xFFFFA63D),
                              ),
                              SizedBox(width: 4),
                              Text(
                                '댓글 달기',
                                style: TextStyle(
                                  color: const Color(0xFFFFA63D),
                                  fontSize: 11,
                                  fontFamily: 'Pretendard-Light',
                                  fontWeight: FontWeight.w300,
                                  letterSpacing: -0.24,
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(width: 16),

                        // 좋아요 버튼
                        GestureDetector(
                          onTap: () async {
                            // 답글 좋아요 토글
                            final bool currentLikeStatus =
                                reply['isliked'] ?? false;
                            final success = await FeedService.toggleCommentLike(
                              reply['commentId'],
                              currentLikeStatus,
                            );

                            if (success) {
                              setState(() {
                                // 좋아요 상태 토글
                                reply['isliked'] = !currentLikeStatus;

                                // 좋아요 수 업데이트
                                if (reply['isliked']) {
                                  reply['likeCount'] =
                                      (reply['likeCount'] ?? 0) + 1;
                                } else {
                                  reply['likeCount'] =
                                      (reply['likeCount'] ?? 0) - 1;
                                  if (reply['likeCount'] < 0) {
                                    reply['likeCount'] = 0;
                                  }
                                }
                              });
                            }
                          },
                          child: Container(
                            height: 20,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: ShapeDecoration(
                              shape: RoundedRectangleBorder(
                                side: BorderSide(
                                  width: 0.65,
                                  color:
                                      (reply['isliked'] ?? false)
                                          ? const Color(0xFFFFA63D)
                                          : const Color(0xFFFFD27F),
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
                                  width: 12,
                                  height: 12,
                                  color:
                                      (reply['isliked'] ?? false)
                                          ? const Color(0xFFFFA63D)
                                          : const Color(0xFFFFD27F),
                                ),
                                SizedBox(width: 2),
                                Text(
                                  '${reply['likeCount'] ?? 0}',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color:
                                        (reply['isliked'] ?? false)
                                            ? const Color(0xFFFFA63D)
                                            : const Color(0xFFFFD27F),
                                    fontSize: 11,
                                    fontFamily: 'Pretendard-Medium',
                                    fontWeight: FontWeight.w500,
                                    height: 0.9,
                                    letterSpacing: -0.22,
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
      ],
    );
  }
}
