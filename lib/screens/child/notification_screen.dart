import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../widgets/common/bottom_navigation_bar.dart';
import 'home_screen.dart';
import '../../services/relationship_service.dart';
import '../../services/family_service.dart';
import '../../services/feed_service.dart';
import '../../services/mission_service.dart';
import 'chat/chat_start_screen.dart';
import 'my/family_management_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../models/mission_notification.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final bool _isMissionCardExpanded = false;
  int _selectedTabIndex = 0;
  bool _isLoading = true;
  bool _showUnreadOnly = false; // 안 읽은 알림만 보기 위한 상태 추가
  List<Map<String, dynamic>> _relationshipRequests = [];
  List<Map<String, dynamic>> _familyInvites = [];
  List<Map<String, dynamic>> _friendsWhoAddedMe = [];
  int _currentFriendsPage = 0;
  bool _hasMoreFriends = true;

  // 피드 알림 관련 변수 추가
  List<Map<String, dynamic>> _feedNotifications = [];
  int _currentNotificationsPage = 0;
  bool _hasMoreNotifications = true;
  bool _isLoadingNotifications = false;

  // 미션 알림 관련 변수 추가
  List<MissionNotification> _missionNotifications = [];
  bool _isLoadingMissions = false;

  // 필터 탭 목록
  final List<String> _tabs = ['전체', '초대·요청', '활동 내역', '리워드'];

  // 샘플 알림 데이터(목업 데이터 제거)
  final List<Map<String, dynamic>> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadAllFriendRelationships();
    _loadFamilyInvites();
    _loadFeedNotifications(refresh: true); // 피드 알림 로드 추가
    _loadMissionNotifications(); // 미션 알림 로드 추가
  }

  // 탭별 알림 필터링 메서드
  List<Widget> _getFilteredNotifications() {
    List<Widget> notifications = [];

    switch (_selectedTabIndex) {
      case 0: // 전체
        notifications.addAll(_getAllNotifications());
        break;
      case 1: // 초대·요청
        notifications.addAll(_getInviteRequestNotifications());
        break;
      case 2: // 활동 내역
        notifications.addAll(_getActivityNotifications());
        break;
      case 3: // 리워드
        notifications.addAll(_getRewardNotifications());
        break;
    }

    return notifications;
  }

  // 전체 알림 가져오기
  List<Widget> _getAllNotifications() {
    List<Widget> notifications = [];

    // 가족 초대
    if (_familyInvites.isNotEmpty) {
      notifications.addAll(
        _familyInvites.map((invite) => _buildFamilyInviteItem(invite)),
      );
    }

    // 미션 알림 (미션 챌린지, 목표 승인 요청)
    if (_missionNotifications.isNotEmpty) {
      notifications.addAll(
        _missionNotifications.map(
          (mission) => _buildMissionNotificationItem(mission),
        ),
      );
    }

    // 친구 요청
    if (_relationshipRequests.isNotEmpty) {
      notifications.addAll(
        _relationshipRequests.map(
          (request) => _buildFriendRequestItem(request),
        ),
      );
    }

    // 피드 알림 (댓글, 답글, 활동 완료 등)
    notifications.addAll(
      _feedNotifications
          .where((notification) => !_showUnreadOnly || !notification['read'])
          .map((notification) => _buildFeedNotificationItem(notification)),
    );

    return notifications;
  }

  // 초대·요청 알림 가져오기
  List<Widget> _getInviteRequestNotifications() {
    List<Widget> notifications = [];

    // 1. 초대 (가족 초대)
    if (_familyInvites.isNotEmpty) {
      notifications.addAll(
        _familyInvites.map((invite) => _buildFamilyInviteItem(invite)),
      );
    }

    // 2. 친구 추가 요청
    if (_relationshipRequests.isNotEmpty) {
      final friendRequests =
          _relationshipRequests.where((request) {
            // 친구 요청만 필터링 (필요시 더 세부적으로 분류)
            return true; // 현재는 모든 관계 요청이 친구 요청
          }).toList();
      notifications.addAll(
        friendRequests.map((request) => _buildFriendRequestItem(request)),
      );
    }

    // 3. 미션 챌린지, 목표 승인 요청
    if (_missionNotifications.isNotEmpty) {
      notifications.addAll(
        _missionNotifications.map(
          (mission) => _buildMissionNotificationItem(mission),
        ),
      );
    }

    // 4. 미션 승인 요청 (피드 알림에서)
    final missionProposalNotifications =
        _feedNotifications
            .where((notification) {
              final type = notification['type'] ?? '';
              return type == 'MISSION_PROPOSAL';
            })
            .where((notification) => !_showUnreadOnly || !notification['read'])
            .toList();

    notifications.addAll(
      missionProposalNotifications.map(
        (notification) => _buildFeedNotificationItem(notification),
      ),
    );

    // 5. 친구 추가 요청 (피드 알림에서)
    final friendRequestNotifications =
        _feedNotifications
            .where((notification) {
              final type = notification['type'] ?? '';
              return type == 'ADD_FRIEND';
            })
            .where((notification) => !_showUnreadOnly || !notification['read'])
            .toList();

    notifications.addAll(
      friendRequestNotifications.map(
        (notification) => _buildFeedNotificationItem(notification),
      ),
    );

    return notifications;
  }

  // 활동 내역 알림 가져오기
  List<Widget> _getActivityNotifications() {
    List<Widget> notifications = [];

    // 1. 보상금 승인 완료 (지급하지 않은 경우만)
    final rewardApprovalNotifications =
        _feedNotifications
            .where((notification) {
              final type = notification['type'] ?? '';
              final message = notification['message'] ?? '';
              return type == 'POINT_TRANSFER' && message.contains('지급하지 않았어요');
            })
            .where((notification) => !_showUnreadOnly || !notification['read'])
            .toList();

    notifications.addAll(
      rewardApprovalNotifications.map(
        (notification) => _buildFeedNotificationItem(notification),
      ),
    );

    // 2. 피드 내 작성글에 대한 댓글, 답글
    final feedInteractionNotifications =
        _feedNotifications
            .where((notification) {
              final type = notification['type'] ?? '';
              return type == 'FEED_COMMENT' ||
                  type == 'COMMENT_REPLY' ||
                  type == 'COMMENT_LIKE' ||
                  type == 'FEED_LIKE';
            })
            .where((notification) => !_showUnreadOnly || !notification['read'])
            .toList();

    notifications.addAll(
      feedInteractionNotifications.map(
        (notification) => _buildFeedNotificationItem(notification),
      ),
    );

    // 3. 활동(미션/챌린지/목표) 완료 및 승인
    final activityCompletionNotifications =
        _feedNotifications
            .where((notification) {
              final type = notification['type'] ?? '';
              return type == 'MISSION_ACHIEVEMENT' ||
                  type == 'CHALLENGE_ACCEPT' ||
                  type == 'CHALLENGE_COMPLETE' ||
                  type == 'GOAL_COMPLETE' ||
                  type == 'PERMIT_GOAL' ||
                  type == 'MISSION_COMPLETE';
            })
            .where((notification) => !_showUnreadOnly || !notification['read'])
            .toList();

    notifications.addAll(
      activityCompletionNotifications.map(
        (notification) => _buildFeedNotificationItem(notification),
      ),
    );

    return notifications;
  }

  // 리워드 알림 가져오기
  List<Widget> _getRewardNotifications() {
    List<Widget> notifications = [];

    // 1. 구독권 선물
    final subscriptionGiftNotifications =
        _feedNotifications
            .where((notification) {
              final message = notification['message'] ?? '';
              final type = notification['type'] ?? '';
              return message.contains('구독권') ||
                  message.contains('선물') ||
                  type == 'SUBSCRIPTION_GIFT';
            })
            .where((notification) => !_showUnreadOnly || !notification['read'])
            .toList();

    notifications.addAll(
      subscriptionGiftNotifications.map(
        (notification) => _buildFeedNotificationItem(notification),
      ),
    );

    // 2. 보상금 이체 확인 (POINT_TRANSFER 중 실제 이체 성공 메시지만)
    final rewardTransferNotifications =
        _feedNotifications
            .where((notification) {
              final message = notification['message'] ?? '';
              final type = notification['type'] ?? '';
              // 보상금이 지급되지 않은 메시지는 제외하고, 실제 이체 성공 메시지만 포함
              return (type == 'POINT_TRANSFER' &&
                      !message.contains('지급하지 않았어요') &&
                      (message.contains('이체') || message.contains('지급됐어요'))) ||
                  type == 'REWARD_TRANSFER';
            })
            .where((notification) => !_showUnreadOnly || !notification['read'])
            .toList();

    notifications.addAll(
      rewardTransferNotifications.map(
        (notification) => _buildFeedNotificationItem(notification),
      ),
    );

    // 3. 포인트 적립 관련
    final pointEarnNotifications =
        _feedNotifications
            .where((notification) {
              final message = notification['message'] ?? '';
              final type = notification['type'] ?? '';
              return type == 'POINT_EARN' ||
                  message.contains('포인트') ||
                  message.contains('적립');
            })
            .where((notification) => !_showUnreadOnly || !notification['read'])
            .toList();

    notifications.addAll(
      pointEarnNotifications.map(
        (notification) => _buildFeedNotificationItem(notification),
      ),
    );

    return notifications;
  }

  // 현재 탭에 알림이 있는지 확인
  bool _hasNotificationsForCurrentTab() {
    return _getFilteredNotifications().isNotEmpty;
  }

  // 현재 탭에 맞는 빈 메시지 반환
  String _getEmptyMessageForCurrentTab() {
    if (_showUnreadOnly) {
      // 안읽음 필터가 활성화된 경우
      switch (_selectedTabIndex) {
        case 0:
          return '읽지 않은 알림이 없습니다';
        case 1:
          return '읽지 않은 초대·요청이 없습니다';
        case 2:
          return '읽지 않은 활동 내역이 없습니다';
        case 3:
          return '읽지 않은 리워드가 없습니다';
        default:
          return '읽지 않은 알림이 없습니다';
      }
    } else {
      // 전체 필터가 활성화된 경우
      switch (_selectedTabIndex) {
        case 0:
          return '새로운 알림이 없습니다';
        case 1:
          return '새로운 초대·요청이 없습니다';
        case 2:
          return '새로운 활동 내역이 없습니다';
        case 3:
          return '새로운 리워드가 없습니다';
        default:
          return '새로운 알림이 없습니다';
      }
    }
  }

  // 안읽은 알림 개수 계산
  int _getUnreadNotificationCount() {
    int count = 0;

    // 가족 초대 안읽은 개수
    count +=
        _familyInvites.where((invite) => !(invite['read'] ?? false)).length;

    // 미션 알림 안읽은 개수 (현재 모든 미션 알림을 안읽은 것으로 처리)
    count += _missionNotifications.length;

    // 친구 요청 안읽은 개수
    count +=
        _relationshipRequests
            .where((request) => !(request['read'] ?? false))
            .length;

    // 피드 알림 안읽은 개수
    count +=
        _feedNotifications
            .where((notification) => !(notification['read'] ?? false))
            .length;

    return count;
  }

  // 피드 알림 로드 메서드
  Future<void> _loadFeedNotifications({bool refresh = false}) async {
    try {
      setState(() {
        _isLoadingNotifications = true;
      });

      print('===== 피드 알림 로드 시작 =====');

      if (refresh) {
        setState(() {
          _currentNotificationsPage = 0;
          _feedNotifications = [];
          _hasMoreNotifications = true;
        });
      }

      if (!_hasMoreNotifications) {
        print('더 불러올 알림이 없어서 API 호출 중단');
        setState(() {
          _isLoadingNotifications = false;
        });
        return;
      }

      print('API 호출 전 - 페이지: $_currentNotificationsPage');

      final result = await FeedService.getFeedNotifications(
        page: _currentNotificationsPage,
        size: 20,
      );

      if (result != null) {
        final List<dynamic> content =
            (result['content'] as List<dynamic>?) ?? [];
        final List<Map<String, dynamic>> newNotifications =
            content
                .map(
                  (item) =>
                      Map<String, dynamic>.from(item as Map<String, dynamic>),
                )
                .toList();

        print('데이터 개수: ${newNotifications.length}');
        print('전체 페이지: ${result['totalPages'] as int? ?? 0}');
        print('전체 항목 수: ${result['totalElements'] as int? ?? 0}');
        print('현재 페이지: ${result['number'] as int? ?? 0}');

        setState(() {
          _feedNotifications.addAll(newNotifications);
          _hasMoreNotifications =
              _currentNotificationsPage <
              ((result['totalPages'] as int?) ?? 0) - 1;
          if (_hasMoreNotifications) {
            _currentNotificationsPage++;
          }
          _isLoadingNotifications = false;
        });

        print('현재 표시 중인 알림 개수: ${_feedNotifications.length}');
        print('더 불러올 알림 있음: $_hasMoreNotifications');
      } else {
        print('API 응답이 null입니다 - 네트워크 오류 또는 서버 문제일 수 있습니다');
        setState(() {
          _isLoadingNotifications = false;
        });
      }
    } catch (e) {
      print('피드 알림 로딩 중 오류: $e');
      print('오류 스택 트레이스: ${e.toString()}');
      setState(() {
        _isLoadingNotifications = false;
      });
    }
  }

  // 알림 읽음 처리 메서드 수정
  Future<void> _markNotificationAsRead(int notificationId) async {
    try {
      // API 호출 성공 여부와 관계없이 UI 상태 업데이트
      setState(() {
        for (int i = 0; i < _feedNotifications.length; i++) {
          if (_feedNotifications[i]['id'] == notificationId) {
            _feedNotifications[i]['read'] = true;
            break;
          }
        }
      });

      // API 호출은 백그라운드에서 시도
      try {
        await FeedService.markNotificationAsRead(notificationId);
        print('알림 읽음 처리 성공: $notificationId');
      } catch (apiError) {
        print('알림 읽음 처리 API 실패 (ID: $notificationId): $apiError');
        // 500 에러 등 서버 문제는 무시하고 UI 상태만 유지
        if (apiError.toString().contains('500')) {
          print('서버 내부 오류 - UI 상태는 유지합니다');
        }
      }
    } catch (e) {
      print('알림 읽음 처리 중 일반 오류: $e');
      // API 실패해도 UI는 이미 업데이트된 상태 유지
    }
  }

  // 알림 시간 포맷팅
  String _formatNotificationTime(String createdDate) {
    try {
      final DateTime createdDateTime = DateTime.parse(createdDate);
      final DateTime now = DateTime.now();
      final Duration difference = now.difference(createdDateTime);

      if (difference.inMinutes < 1) {
        return '방금 전';
      } else if (difference.inHours < 1) {
        return '${difference.inMinutes}분 전';
      } else if (difference.inDays < 1) {
        return '${difference.inHours}시간 전';
      } else if (difference.inDays < 7) {
        // 날짜 포맷 (예: 5월 12일)
        return '${createdDateTime.month}월 ${createdDateTime.day}일';
      } else {
        // 날짜 포맷 (예: 5월 12일)
        return '${createdDateTime.month}월 ${createdDateTime.day}일';
      }
    } catch (e) {
      print('날짜 포맷팅 오류: $e');
      return '알 수 없음';
    }
  }

  // 알림 타입에 따른 아이콘 가져오기 메소드 변경
  String _getNotificationIconPath(String type) {
    switch (type) {
      case 'FEED_LIKE':
      case 'FEED_COMMENT':
      case 'COMMENT_REPLY':
      case 'COMMENT_LIKE':
        return 'assets/icons/Icon/noti/활동 내역.png';
      case 'ADD_FRIEND':
      case 'MISSION_PROPOSAL':
        return 'assets/icons/Icon/noti/초대·요청.png';
      case 'CHALLENGE':
      case 'CHALLENGE_ACCEPT':
      case 'GOAL':
      case 'PERMIT_GOAL':
      case 'MISSION':
      case 'MISSION_ACHIEVEMENT':
        return 'assets/icons/Icon/noti/미션.png';
      case 'POINT_TRANSFER':
      case 'SUBSCRIPTION_GIFT':
        return 'assets/icons/Icon/noti/리워드.png';
      default:
        return 'assets/icons/Icon/noti/활동 내역.png';
    }
  }

  // 알림 타입에 따른 아이콘 가져오기
  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'FEED_LIKE':
        return Icons.favorite;
      case 'FEED_COMMENT':
        return Icons.comment;
      case 'COMMENT_REPLY':
        return Icons.forum;
      case 'COMMENT_LIKE':
        return Icons.thumb_up;
      default:
        return Icons.notifications;
    }
  }

  // 알림 타입에 따른 색상 가져오기
  Color _getNotificationColor(String type) {
    switch (type) {
      case 'FEED_LIKE':
        return Colors.red;
      case 'FEED_COMMENT':
        return Colors.blue;
      case 'COMMENT_REPLY':
        return Colors.green;
      case 'COMMENT_LIKE':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  // 알림 타입에 따른 라벨 가져오기
  String _getNotificationLabel(String type) {
    switch (type) {
      case 'FEED_LIKE':
      case 'FEED_COMMENT':
      case 'COMMENT_REPLY':
      case 'COMMENT_LIKE':
        return '활동 내역';
      case 'ADD_FRIEND':
      case 'MISSION_PROPOSAL':
        return '초대·요청';
      case 'CHALLENGE':
      case 'CHALLENGE_ACCEPT':
        return '챌린지';
      case 'GOAL':
      case 'PERMIT_GOAL':
        return '목표';
      case 'MISSION':
      case 'MISSION_ACHIEVEMENT':
        return '미션';
      case 'POINT_TRANSFER':
        return '보상금';
      case 'SUBSCRIPTION_GIFT':
        return '선물';
      default:
        return '알림';
    }
  }

  // 가족 초대 목록 로드
  Future<void> _loadFamilyInvites() async {
    try {
      print('===== 가족 초대 목록 로드 시작 =====');

      final invites = await FamilyService.getReceivedInvites();

      if (invites != null) {
        setState(() {
          _familyInvites = List<Map<String, dynamic>>.from(
            invites
                .map(
                  (item) =>
                      Map<String, dynamic>.from(item as Map<String, dynamic>),
                )
                .toList(),
          );
        });

        print('가족 초대 목록 개수: ${invites.length}');
        if (invites.isNotEmpty) {
          print('첫 번째 초대 정보: ${invites[0]}');
        }
      } else {
        print('가족 초대 목록 조회 실패 또는 초대 없음');
      }

      print('===== 가족 초대 목록 로드 완료 =====');
    } catch (e) {
      print('가족 초대 목록 로드 중 오류 발생: $e');
    }
  }

  // 가족 초대 처리
  Future<void> _processFamilyInvite(int familyMemberId) async {
    try {
      setState(() {
        _isLoading = true;
      });

      print('가족 초대 처리 시작 - familyMemberId: $familyMemberId');

      // 가족 초대 처리 로직 호출
      final result = await FamilyService.processInvitation(familyMemberId);

      if (result['success']) {
        // 초대 처리 성공
        if (result['needWarning']) {
          // 경고창 표시 필요
          _showFamilyJoinWarningDialog(familyMemberId);
        } else {
          // 바로 성공 처리
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );

          // 초대 목록 다시 로드
          await _loadFamilyInvites();

          // 가족 관리 화면으로 이동
          _navigateToFamilyManagement();
        }
      } else {
        // 처리 실패
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('가족 초대 처리 중 오류: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('초대 처리 중 오류가 발생했습니다: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );

      setState(() {
        _isLoading = false;
      });
    }
  }

  // 가족 가입 경고 다이얼로그 표시
  void _showFamilyJoinWarningDialog(int familyMemberId) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('가족 가입 확인'),
            content: const Text(
              '이미 다른 가족 그룹에 소속되어 있습니다.\n초대를 수락하면 기존 가족에서 자동으로 나가게 됩니다.\n계속 진행하시겠습니까?',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _processAfterWarning(familyMemberId, false);
                },
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _processAfterWarning(familyMemberId, true);
                },
                child: const Text('확인', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
  }

  // 경고창 표시 후 초대 처리
  Future<void> _processAfterWarning(
    int familyMemberId,
    bool userAccepted,
  ) async {
    try {
      setState(() {
        _isLoading = true;
      });

      final result = await FamilyService.processInvitationAfterWarning(
        familyMemberId,
        userAccepted,
      );

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );

        // 사용자가 수락한 경우 가족 관리 화면으로 이동 추가
        if (userAccepted) {
          _navigateToFamilyManagement();
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      // 초대 목록 다시 로드
      await _loadFamilyInvites();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('경고창 후 초대 처리 중 오류: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('초대 처리 중 오류가 발생했습니다: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );

      setState(() {
        _isLoading = false;
      });
    }
  }

  // 나를 친구로 추가한 유저 및 관계 데이터 로드 (통합 메서드)
  Future<void> _loadAllFriendRelationships() async {
    setState(() {
      _isLoading = true;
    });

    print('===== 모든 친구 관계 로딩 시작 =====');

    // 친구 요청 먼저 로드
    print('1. 친구 요청 내역 로드 시작');
    final requests = await RelationshipService.getRelationshipInbox();
    if (requests != null) {
      setState(() {
        _relationshipRequests = requests;
      });
    }

    // 나를 친구로 추가한 유저 로드
    print('2. 나를 친구로 추가한 유저 목록 로드 시작');
    final result = await RelationshipService.getFriendsWhoAddedMe();
    if (result != null) {
      setState(() {
        _friendsWhoAddedMe =
            result
                .map(
                  (item) =>
                      Map<String, dynamic>.from(item as Map<String, dynamic>),
                )
                .toList();
      });
    }

    setState(() {
      _isLoading = false;
    });

    print('===== 관계 로딩 완료 =====');
    print('친구 요청 수: ${_relationshipRequests.length}');
    print('나를 추가한 유저 수: ${_friendsWhoAddedMe.length}');
  }

  // 나를 친구로 추가한 유저 목록 로드 (원래 API 복구)
  Future<void> _loadFriendsWhoAddedMe({bool refresh = false}) async {
    try {
      print('===== 나를 친구로 추가한 유저 목록 로드 함수 호출됨 =====');
      print('API 문서: GET /api-user/friend/added-me - 다른 유저가 나를 친구로 추가한 내역을 조회');

      if (refresh) {
        setState(() {
          _currentFriendsPage = 0;
          _friendsWhoAddedMe = [];
          _hasMoreFriends = true;
        });
      }

      if (!_hasMoreFriends) {
        print('더 불러올 데이터가 없어서 API 호출 중단');
        return;
      }

      print('API 호출 전 - 페이지: $_currentFriendsPage');
      // 원래 API 호출 - 나를 친구로 추가한 유저 조회
      final result = await RelationshipService.getFriendsWhoAddedMe();

      print('===== 나를 친구로 추가한 유저 목록 상세 로그 =====');
      print('응답 전체: $result');

      if (result != null) {
        print('데이터 배열: $result');
        print('데이터 개수: ${result.length}');

        // 첫 번째 항목 상세 정보 (있는 경우)
        if (result.isNotEmpty) {
          print('첫 번째 친구 상세: ${result[0]}');
        } else {
          print('API 응답에 친구 데이터가 없습니다. 이는 정상적인 상황일 수 있습니다.');
          print('- 다른 유저가 나를 친구로 추가하지 않았거나');
          print('- 친구가 나를 차단했을 수 있습니다.');
        }

        setState(() {
          _friendsWhoAddedMe.clear(); // 전체 조회이므로 기존 데이터 클리어
          _friendsWhoAddedMe.addAll(
            result
                .map(
                  (item) =>
                      Map<String, dynamic>.from(item as Map<String, dynamic>),
                )
                .toList(),
          );

          // 전체 조회이므로 더 불러올 데이터 없음
          _hasMoreFriends = false;
        });

        print('현재 표시 중인 친구 목록 개수: ${_friendsWhoAddedMe.length}');
      } else {
        print('API 응답이 null입니다 - 네트워크 오류 또는 서버 문제일 수 있습니다');
      }
    } catch (e) {
      print('나를 친구로 추가한 유저 목록 로딩 중 오류: $e');
      print('오류 스택 트레이스: ${e.toString()}');
    }
  }

  // 친구 요청 내역 조회
  Future<void> _loadRelationshipRequests() async {
    try {
      final requests = await RelationshipService.getRelationshipInbox();
      print('친구 요청 조회 결과: $requests');

      if (requests != null) {
        setState(() {
          _relationshipRequests = requests;
        });

        // 요청 상세 정보 출력
        if (requests.isNotEmpty) {
          print('첫 번째 요청 상세: ${requests[0]}');
        } else {
          print('친구 요청이 없습니다.');
        }
      }
    } catch (e) {
      print('친구 요청 내역 로딩 중 오류: $e');
    }
  }

  // 알림 메시지에서 targetUserId 추출
  int? _extractTargetUserIdFromNotification(Map<String, dynamic> notification) {
    try {
      // 메시지 형식: "김동규님이 친구 요청을 보냈어요!"
      final String message = notification['message'] ?? '';
      final String? targetUserId = notification['targetUserId'];

      print('알림 메시지: $message');
      print('알림 데이터: $notification');

      // targetUserId가 있으면 그대로 사용
      if (targetUserId != null) {
        return int.tryParse(targetUserId.toString());
      }

      // 메시지에서 requesterId 추출 시도
      final requesterId = notification['requesterId'];
      if (requesterId != null) {
        return int.tryParse(requesterId.toString());
      }

      return null;
    } catch (e) {
      print('targetUserId 추출 중 오류: $e');
      return null;
    }
  }

  // 친구 요청 처리
  Future<void> _processFriendRequest(
    int notificationId,
    bool accept, {
    String? message,
  }) async {
    try {
      setState(() {
        _isLoading = true;
      });

      print('친구 요청 처리 시작');
      print('알림 ID: $notificationId');
      print('수락 여부: $accept');
      print('알림 메시지: $message');

      if (accept) {
        // 알림 메시지에서 사용자 이름 추출 (개선된 로직)
        String? senderName;
        if (message != null && message.isNotEmpty) {
          // "김동규님이 친구 요청을 보냈어요!" 형식에서 이름 추출
          final RegExp nameRegExp = RegExp(r'^(.+?)님이\s+친구\s+요청을\s+보냈어요');
          final Match? match = nameRegExp.firstMatch(message);
          if (match != null) {
            senderName = match.group(1);
            print('정규식으로 추출된 사용자 이름: $senderName');
          } else if (message.contains('님이')) {
            // 정규식 실패 시 간단한 방식으로 시도
            senderName = message.split('님이')[0];
            print('간단 분할로 추출된 사용자 이름: $senderName');
          } else {
            // 메시지가 단순히 사용자명만 있는 경우 (예: "feed2")
            senderName = message.trim();
            print('단순 사용자명으로 처리: $senderName');
          }
        }

        if (senderName == null || senderName.isEmpty) {
          print('알림 메시지에서 사용자 이름을 추출할 수 없습니다.');
          print('메시지: "$message"');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('친구 요청 처리 중 오류가 발생했습니다. 메시지 형식을 확인해주세요.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
          return;
        }

        // 먼저 나를 친구로 추가한 유저 목록을 조회
        final result = await RelationshipService.getFriendsWhoAddedMe();
        if (result == null) {
          print('친구 목록을 가져오는데 실패했습니다.');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('요청을 처리할 수 없습니다.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
          return;
        }

        final List<dynamic> friends = result;
        print('친구 목록: $friends');

        // 친구 정보 찾기 - 추출된 사용자 이름으로 검색
        final friend = friends.firstWhere((friend) {
          final userInfo = friend['userInfo'] as Map<String, dynamic>?;
          final realName = userInfo?['realName'] as String?;
          print('비교: $realName vs $senderName');
          return realName == senderName;
        }, orElse: () => null);

        if (friend == null) {
          print('해당 유저를 찾을 수 없습니다: $senderName');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('요청을 처리할 수 없습니다.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
          return;
        }

        final userInfo = friend['userInfo'] as Map<String, dynamic>;
        final userId = userInfo['userId'] as int;
        print('찾은 유저 ID: $userId');

        // 친구 추가 API 호출
        final addResult = await RelationshipService.addFriend(userId);
        if (addResult != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${senderName}님의 친구 요청을 수락했습니다.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );

          // 알림 목록 새로고침
          await _loadAllFriendRelationships();
          await _loadFeedNotifications(refresh: true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('요청 처리 중 오류가 발생했습니다.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        // 거절 처리는 임시로 성공으로 처리
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('친구 요청을 거절했습니다.'),
            backgroundColor: Colors.grey,
            duration: Duration(seconds: 2),
          ),
        );
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('친구 요청 처리 중 오류: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('오류가 발생했습니다: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );

      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 읽지 않은 알림 개수 계산
    int unreadCount = _getUnreadNotificationCount();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        automaticallyImplyLeading: false,
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 24,
                height: 24,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: Image.asset(
                    'assets/icons/Icon/뒤로 가기/Regular.png',
                    width: 20,
                    height: 20,
                    errorBuilder:
                        (context, error, stackTrace) => const Icon(
                          Icons.arrow_back_ios,
                          color: Colors.black,
                          size: 20,
                        ),
                  ),
                  onPressed:
                      () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HomeScreen(),
                        ),
                      ),
                ),
              ),
              const Text(
                '알림',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                  fontFamily: 'Pretendard-Bold',
                  letterSpacing: -0.32,
                ),
              ),
              Container(
                width: 24,
                height: 24,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: Image.asset(
                    'assets/icons/Icon/noti/설정.png',
                    width: 20,
                    height: 20,
                    errorBuilder:
                        (context, error, stackTrace) =>
                            const Icon(Icons.settings_outlined, size: 20),
                  ),
                  onPressed: () {
                    // 알림 설정 화면 이동
                  },
                ),
              ),
            ],
          ),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(40),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.only(
              top: 2,
              left: 12,
              right: 12,
              bottom: 6,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(child: _buildNewTab(0, '전체')),
                Expanded(child: _buildNewTab(1, '초대·요청')),
                Expanded(child: _buildNewTab(2, '활동 내역')),
                Expanded(child: _buildNewTab(3, '리워드')),
              ],
            ),
          ),
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  // 필터링 UI 추가
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
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
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _showUnreadOnly = false;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: ShapeDecoration(
                                    color:
                                        !_showUnreadOnly
                                            ? const Color(0xFF5C697E)
                                            : const Color(0xFFE7ECF6),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: Text(
                                    '전체',
                                    style: TextStyle(
                                      color:
                                          !_showUnreadOnly
                                              ? Colors.white
                                              : const Color(0xFF8490A3),
                                      fontSize: 12,
                                      fontFamily: 'Pretendard',
                                      fontWeight:
                                          !_showUnreadOnly
                                              ? FontWeight.w500
                                              : FontWeight.w300,
                                      letterSpacing: -0.28,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 20),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _showUnreadOnly = true;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: ShapeDecoration(
                                    color:
                                        _showUnreadOnly
                                            ? const Color(0xFF5C697E)
                                            : const Color(0xFFE7ECF6),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Text(
                                        '안 읽음',
                                        style: TextStyle(
                                          color:
                                              _showUnreadOnly
                                                  ? Colors.white
                                                  : const Color(0xFF8490A3),
                                          fontSize: 12,
                                          fontFamily: 'Pretendard',
                                          fontWeight:
                                              _showUnreadOnly
                                                  ? FontWeight.w500
                                                  : FontWeight.w300,
                                          letterSpacing: -0.28,
                                        ),
                                      ),
                                      // 안읽은 알림이 있을 때만 개수 표시
                                      if (unreadCount > 0) ...[
                                        const SizedBox(width: 6),
                                        Text(
                                          '$unreadCount',
                                          style: const TextStyle(
                                            color: Color(0xFF5D9EFF),
                                            fontSize: 14,
                                            fontFamily: 'Pretendard',
                                            fontWeight: FontWeight.w500,
                                            letterSpacing: -0.28,
                                          ),
                                        ),
                                      ],
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

                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () async {
                        await _loadAllFriendRelationships();
                        await _loadFamilyInvites();
                        await _loadFeedNotifications(refresh: true);
                        await _loadMissionNotifications();
                      },
                      child: ListView(
                        padding: EdgeInsets.zero,
                        children: [
                          // 필터링된 알림 표시
                          ..._getFilteredNotifications(),

                          // 더 보기 버튼 (피드 알림의 경우)
                          if (_hasMoreNotifications &&
                              _feedNotifications.isNotEmpty &&
                              (_selectedTabIndex == 0 ||
                                  _selectedTabIndex == 2)) // 전체 또는 활동내역 탭
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Center(
                                child:
                                    _isLoadingNotifications
                                        ? const CircularProgressIndicator()
                                        : ElevatedButton(
                                          onPressed:
                                              () => _loadFeedNotifications(),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(
                                              0xFF3A88F4,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 24,
                                              vertical: 12,
                                            ),
                                          ),
                                          child: const Text('알림 더 보기'),
                                        ),
                              ),
                            ),

                          // 알림이 없을 때 표시할 섹션 (현재 탭에 알림이 없을 때만 표시)
                          if (!_hasNotificationsForCurrentTab() &&
                              !_isLoading) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(24),
                              color: Colors.white,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.notifications_none,
                                    size: 48,
                                    color: Color(0xFFCCCCCC),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _getEmptyMessageForCurrentTab(),
                                    style: const TextStyle(
                                      color: Color(0xFF666666),
                                      fontSize: 14,
                                      fontFamily: 'Pretendard-Regular',
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton.icon(
                                    onPressed: () async {
                                      await _loadAllFriendRelationships();
                                      await _loadFamilyInvites();
                                      await _loadFeedNotifications(
                                        refresh: true,
                                      );
                                      await _loadMissionNotifications();
                                    },
                                    icon: const Icon(Icons.refresh),
                                    label: const Text('새로고침'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF3A88F4),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      bottomNavigationBar: const CommonBottomNavigationBar(selectedIndex: 0),
    );
  }

  Widget _buildFeedNotificationItem(Map<String, dynamic> notification) {
    final int id = notification['id'] ?? 0;
    final String rawMessage = notification['message'] ?? '';
    final String type = notification['type'] ?? 'UNKNOWN';
    final String createdDate = notification['createdDate'] ?? '';
    bool isRead = notification['read'] ?? false;

    // 메시지 보정 로직 (백엔드 수정 전 임시 해결책)
    String message = rawMessage;
    if (type == 'ADD_FRIEND' && !rawMessage.contains('친구 요청')) {
      // 단순 사용자명만 온 경우 메시지 형태로 변환
      message = '${rawMessage}님이 친구 요청을 보냈어요!';
      print('친구 요청 메시지 보정: "$rawMessage" → "$message"');
    } else if (type == 'MISSION_PROPOSAL' && !rawMessage.contains('미션 승인')) {
      // 미션 제안도 마찬가지로 보정
      message = '${rawMessage}님이 미션 승인을 요청했어요!';
      print('미션 제안 메시지 보정: "$rawMessage" → "$message"');
    }

    final String formattedTime = _formatNotificationTime(createdDate);
    final String iconPath = _getNotificationIconPath(type);
    final String label = _getNotificationLabel(type);

    return StatefulBuilder(
      builder: (context, setState) {
        return GestureDetector(
          onTap: () async {
            print('알림 탭됨!');
            print('알림 타입: $type');
            print('알림 메시지: $message');
            print('전체 알림 데이터: $notification');

            // 알림을 읽음 상태로 변경 (로컬 상태 먼저 업데이트)
            if (!isRead) {
              setState(() {
                isRead = true;
                notification['read'] = true;
              });
              _markNotificationAsRead(id);
            }

            if (type == 'ADD_FRIEND') {
              _showFriendRequestModal(message, id, notification);
            } else if (type == 'MISSION_PROPOSAL') {
              _showMissionProposalModal(message, id, notification);
            } else if (type == 'FEED_LIKE' ||
                type == 'FEED_COMMENT' ||
                type == 'COMMENT_REPLY' ||
                type == 'COMMENT_LIKE') {
              // 피드 관련 알림만 상세 페이지로 이동
              int? feedId = _extractFeedIdFromNotification(message, type);
              if (feedId != null) {
                _navigateToFeedDetail(feedId, type);
              }
            } else {
              // 포인트나 기타 알림은 단순히 읽음 처리만 (상세 페이지 이동 없음)
              print('기타 알림 처리 완료: $type');
            }
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: ShapeDecoration(
              color: isRead ? const Color(0xFFE5E7ED) : Colors.white,
              shape: RoundedRectangleBorder(
                side: BorderSide(width: 0.40, color: const Color(0xFFC4C4C4)),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
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
                                  Container(
                                    width: 24,
                                    height: 24,
                                    clipBehavior: Clip.antiAlias,
                                    decoration: BoxDecoration(),
                                    child: Image.asset(
                                      iconPath,
                                      width: 20,
                                      height: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),

                                  Expanded(
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: ShapeDecoration(
                                            color: const Color(0xFFFFD27F),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              Text(
                                                label,
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 9,
                                                  fontFamily:
                                                      'Pretendard-ExtraLight',
                                                  letterSpacing: -0.22,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),

                                        Expanded(
                                          child: Text(
                                            message,
                                            style: TextStyle(
                                              color: const Color(0xFF202020),
                                              fontSize: 13,
                                              fontFamily: 'Pretendard-Medium',
                                              letterSpacing: -0.32,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 8),
                            const SizedBox(
                              width: 144,
                              child: Text(
                                '알림을 눌러 확인해 보세요!',
                                style: TextStyle(
                                  color: Color(0xFF4A4A4A),
                                  fontSize: 12,
                                  fontFamily: 'Pretendard-Light',
                                  letterSpacing: -0.28,
                                ),
                              ),
                            ),

                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  formattedTime,
                                  style: TextStyle(
                                    color: const Color(0xFF999999),
                                    fontSize: 11,
                                    fontFamily: 'Pretendard-Light',
                                    letterSpacing: -0.22,
                                  ),
                                ),

                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 12,
                                      height: 12,
                                      margin: const EdgeInsets.only(right: 4),
                                      child: Transform.scale(
                                        scaleX: -1,
                                        child: Image.asset(
                                          'assets/icons/Icon/noti/체크.png',
                                          color:
                                              isRead
                                                  ? const Color(0xFF5D9EFF)
                                                  : const Color(0xFFB6B6B6),
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '확인했어요',
                                      style: TextStyle(
                                        color:
                                            isRead
                                                ? const Color(0xFF5D9EFF)
                                                : const Color(0xFFB6B6B6),
                                        fontSize: 10,
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
              ],
            ),
          ),
        );
      },
    );
  }

  int? _extractFeedIdFromNotification(String message, String type) {
    try {
      final RegExp regExp = RegExp(r'피드\s(\d+)|게시물\s(\d+)');
      final Match? match = regExp.firstMatch(message);

      if (match != null) {
        final String? matchedId = match.group(1) ?? match.group(2);
        if (matchedId != null) {
          return int.parse(matchedId);
        }
      }

      final RegExp numRegExp = RegExp(r'\d+');
      final Match? numMatch = numRegExp.firstMatch(message);
      if (numMatch != null) {
        return int.parse(numMatch.group(0)!);
      }

      return null;
    } catch (e) {
      print('피드 ID 추출 오류: $e');
      return null;
    }
  }

  void _navigateToFeedDetail(int feedId, String type) {
    print('피드 상세로 이동: 피드 ID=$feedId, 알림 유형=$type');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('피드 $feedId 상세 화면으로 이동합니다 (유형: $type)'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // 새로운 탭 위젯 생성 (부모단과 동일)
  Widget _buildNewTab(int index, String title) {
    bool isSelected = _selectedTabIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTabIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? Colors.black : const Color(0xFFC4C4C4),
              width: isSelected ? 2.0 : 1.0,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 4,
              height: 4,
              margin: const EdgeInsets.only(right: 4, top: 2),
              decoration: ShapeDecoration(
                color: const Color(0xFF146AFF),
                shape: OvalBorder(),
              ),
            ),
            Flexible(
              child: Text(
                title,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color:
                      isSelected
                          ? const Color(0xFF202020)
                          : const Color(0xFF999999),
                  fontSize: 13,
                  fontFamily:
                      isSelected ? 'Pretendard-Bold' : 'Pretendard-Light',
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w300,
                  letterSpacing: -0.26,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationItem({
    required String category,
    required String title,
    required String content,
    required String time,
    required bool isRead,
    Color categoryColor = const Color(0xFFFFD27F),
    IconData? iconData,
    bool hasNewBadge = false,
    bool hasGrayBackground = false,
  }) {
    String badgeText = '';
    String iconPath = '';

    if (category == '미션' || category == '학습') {
      badgeText = '활동 내역';
      iconPath = 'assets/icons/Icon/noti/활동 내역.png';
    } else if (category == '리워드') {
      badgeText = '리워드';
      iconPath = 'assets/icons/Icon/noti/리워드.png';
    } else if (category == '용돈') {
      badgeText = '선물함';
      iconPath = 'assets/icons/Icon/noti/선물함.png';
    } else {
      badgeText = category;
      iconPath = 'assets/icons/Icon/noti/활동 내역.png';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: ShapeDecoration(
        color: hasGrayBackground ? const Color(0xFFF5F5F5) : Colors.white,
        shape: RoundedRectangleBorder(
          side: BorderSide(width: 0.40, color: const Color(0xFFC4C4C4)),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
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
                            Container(
                              width: 24,
                              height: 24,
                              clipBehavior: Clip.antiAlias,
                              decoration: BoxDecoration(),
                              child: Image.asset(
                                iconPath,
                                width: 20,
                                height: 20,
                              ),
                            ),
                            const SizedBox(width: 12),

                            Expanded(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
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
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Text(
                                          badgeText,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 9,
                                            fontFamily: 'Pretendard-ExtraLight',
                                            letterSpacing: -0.22,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),

                                  Expanded(
                                    child: Text(
                                      title,
                                      style: TextStyle(
                                        color: const Color(0xFF202020),
                                        fontSize: 13,
                                        fontFamily: 'Pretendard-Medium',
                                        letterSpacing: -0.32,
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

                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        child: Text(
                          content,
                          style: TextStyle(
                            color: const Color(0xFF4A4A4A),
                            fontSize: 13,
                            fontFamily: 'Pretendard-Light',
                            letterSpacing: -0.28,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
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
    );
  }

  Widget _buildFamilyInviteItem(Map<String, dynamic> invite) {
    final int familyMemberId = invite['familyMemberId'] ?? 0;
    final int familyId = invite['familyId'] ?? 0;
    final int inviterId = invite['inviterId'] ?? 0;

    final String inviterNameRaw = invite['inviterName'] ?? '';
    final String inviterName =
        inviterNameRaw.isNotEmpty ? inviterNameRaw : '알 수 없음';

    final String invitedDate =
        invite.containsKey('invitedDate')
            ? _formatNotificationTime(invite['invitedDate'])
            : '방금 전';

    bool isRead = invite['read'] ?? false;

    return StatefulBuilder(
      builder: (context, setState) {
        return GestureDetector(
          onTap: () {
            setState(() {
              isRead = true;
              invite['read'] = true;
            });
            _showFamilyInviteModal(context, inviterName, familyMemberId);
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: ShapeDecoration(
              color: isRead ? const Color(0xFFE5E7ED) : Colors.white,
              shape: RoundedRectangleBorder(
                side: BorderSide(width: 0.40, color: const Color(0xFFC4C4C4)),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
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
                                  Container(
                                    width: 24,
                                    height: 24,
                                    clipBehavior: Clip.antiAlias,
                                    decoration: BoxDecoration(),
                                    child: Image.asset(
                                      'assets/icons/Icon/noti/초대·요청.png',
                                      width: 20,
                                      height: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),

                                  Expanded(
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: ShapeDecoration(
                                            color: const Color(0xFFFFD27F),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              Text(
                                                '초대·요청',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 9,
                                                  fontFamily:
                                                      'Pretendard-ExtraLight',
                                                  letterSpacing: -0.22,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),

                                        Expanded(
                                          child: Text(
                                            '$inviterName님이 가족 멤버로 초대했어요!',
                                            style: const TextStyle(
                                              color: Color(0xFF202020),
                                              fontSize: 13,
                                              fontFamily: 'Pretendard-Medium',
                                              letterSpacing: -0.32,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 8),
                            const SizedBox(
                              width: 144,
                              child: Text(
                                '알림을 눌러 확인해 보세요!',
                                style: TextStyle(
                                  color: Color(0xFF4A4A4A),
                                  fontSize: 12,
                                  fontFamily: 'Pretendard-Light',
                                  letterSpacing: -0.28,
                                ),
                              ),
                            ),

                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  invitedDate,
                                  style: TextStyle(
                                    color: const Color(0xFF999999),
                                    fontSize: 11,
                                    fontFamily: 'Pretendard-Light',
                                    letterSpacing: -0.22,
                                  ),
                                ),

                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 12,
                                      height: 12,
                                      margin: const EdgeInsets.only(right: 4),
                                      child: Transform.scale(
                                        scaleX: -1,
                                        child: Image.asset(
                                          'assets/icons/Icon/noti/체크.png',
                                          color:
                                              isRead
                                                  ? const Color(0xFF5D9EFF)
                                                  : const Color(0xFFB6B6B6),
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '확인했어요',
                                      style: TextStyle(
                                        color:
                                            isRead
                                                ? const Color(0xFF5D9EFF)
                                                : const Color(0xFFB6B6B6),
                                        fontSize: 10,
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
              ],
            ),
          ),
        );
      },
    );
  }

  void _showFamilyInviteModal(
    BuildContext context,
    String inviterName,
    int familyMemberId,
  ) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (BuildContext context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final modalWidth = screenWidth * 0.9 > 358 ? 358.0 : screenWidth * 0.9;

        return Center(
          child: Material(
            type: MaterialType.transparency,
            child: Container(
              width: modalWidth,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '$inviterName님이 가족 멤버로 초대했어요!',
                                style: const TextStyle(
                                  color: Color(0xFF202020),
                                  fontSize: 14,
                                  fontFamily: 'Pretendard-Bold',
                                  letterSpacing: -0.72,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: const Icon(
                                Icons.close,
                                color: Color(0xFF999999),
                                size: 18,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '수락하면 함께 가족 활동을 할 수 있어요',
                          style: TextStyle(
                            color: Color(0xFF999999),
                            fontSize: 12,
                            fontFamily: 'Pretendard-Light',
                            letterSpacing: -0.28,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(24),
                        bottomRight: Radius.circular(24),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                              _rejectFamilyInvite(familyMemberId);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDADADA),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: const Text(
                                '초대 거절',
                                style: TextStyle(
                                  color: Color(0xFFB6B6B6),
                                  fontSize: 12,
                                  fontFamily: 'Pretendard-Light',
                                  letterSpacing: -0.28,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                              _processFamilyInvite(familyMemberId);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF5D9EFF),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: const Text(
                                '초대 수락',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontFamily: 'Pretendard-Light',
                                  letterSpacing: -0.28,
                                ),
                              ),
                            ),
                          ),
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

  Future<void> _rejectFamilyInvite(int familyMemberId) async {
    try {
      setState(() {
        _isLoading = true;
      });

      print('가족 초대 거절 시작 - familyMemberId: $familyMemberId');
      final result = await FamilyService.rejectFamilyInvite(familyMemberId);

      if (result) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('가족 초대를 거절했습니다'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        await _loadFamilyInvites();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('초대 거절 처리에 실패했습니다. 잠시 후 다시 시도해주세요.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('가족 초대 거절 중 오류: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('초대 거절 중 오류가 발생했습니다: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );

      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatInviteTime(String invitedDate) {
    try {
      final utcDateTime = DateTime.parse(invitedDate);

      final koreanDateTime = utcDateTime.add(Duration(hours: 9));

      final now = DateTime.now();
      final difference = now.difference(koreanDateTime);

      if (difference.isNegative) {
        return '방금 전';
      } else if (difference.inMinutes < 1) {
        return '방금 전';
      } else if (difference.inHours < 1) {
        return '${difference.inMinutes}분 전';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}시간 전';
      } else {
        return '${difference.inDays}일 전';
      }
    } catch (e) {
      print('초대 시간 파싱 오류: $e');
      return '최근에';
    }
  }

  void _navigateToFamilyManagement() {
    Future.delayed(Duration(milliseconds: 500), () {
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const FamilyManagementScreen(),
          ),
        );
      }
    });
  }

  Widget _buildFriendRequestItem(Map<String, dynamic> request) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          print('친구 요청 아이템 탭됨');
          // 친구 요청 알림도 읽음 상태로 변경
          if (request['id'] != null) {
            _markNotificationAsRead(request['id']);
          }
          _showFriendRequestModal(
            request['inviterName'],
            request['id'],
            request,
          );
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: const Color(0xFFC4C4C4), width: 0.5),
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.grey[300],
                child: Icon(Icons.person, color: Colors.grey[600], size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
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
                          child: const Text(
                            '친구 요청',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontFamily: 'Pretendard-Medium',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '친구 요청이 도착했어요!',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 14,
                        fontFamily: 'Pretendard-Regular',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 미션 알림 로드
  Future<void> _loadMissionNotifications() async {
    try {
      setState(() {
        _isLoadingMissions = true;
      });

      final result = await MissionService.getMissionNotifications();

      if (result != null) {
        setState(() {
          _missionNotifications = result;
        });
      }
    } catch (e) {
      print('미션 알림 로드 중 오류: $e');
    } finally {
      setState(() {
        _isLoadingMissions = false;
      });
    }
  }

  // 미션 알림 아이템 위젯
  Widget _buildMissionNotificationItem(MissionNotification mission) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6E6E6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            mission.title,
            style: const TextStyle(
              color: Color(0xFF202020),
              fontSize: 16,
              fontFamily: 'Pretendard-Bold',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            mission.description,
            style: const TextStyle(
              color: Color(0xFF666666),
              fontSize: 14,
              fontFamily: 'Pretendard-Regular',
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatNotificationTime(mission.createdAt),
                style: const TextStyle(
                  color: Color(0xFF999999),
                  fontSize: 12,
                  fontFamily: 'Pretendard-Regular',
                ),
              ),
              Row(
                children: [
                  TextButton(
                    onPressed: () => _handleMissionAction(mission, false),
                    child: const Text(
                      '거절',
                      style: TextStyle(
                        color: Color(0xFF999999),
                        fontFamily: 'Pretendard-Medium',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _handleMissionAction(mission, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4A80F0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      '수락',
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Pretendard-Medium',
                      ),
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

  // 현재 날짜 범위 반환 (이번 주)
  String _getCurrentDateRange() {
    final DateTime now = DateTime.now();
    final int weekday = now.weekday;

    // 이번 주 월요일 계산
    final DateTime monday = now.subtract(Duration(days: weekday - 1));
    final DateTime friday = monday.add(Duration(days: 4));

    return '${monday.month.toString().padLeft(2, '0')}.${monday.day.toString().padLeft(2, '0')} - ${friday.month.toString().padLeft(2, '0')}.${friday.day.toString().padLeft(2, '0')}';
  }

  // 메시지에서 미션 제목 추출
  String _extractMissionTitle(String message) {
    // 기본 미션 제목 반환 (실제로는 API에서 미션 정보를 가져와야 함)
    if (message.contains('부모님') && message.contains('미션')) {
      return '이번 주 가족 미션 담당';
    }
    return '새로운 미션';
  }

  // 미션 제안 처리 (알림에서)
  Future<void> _processMissionProposal(
    int notificationId,
    bool accept, {
    String? message,
    Map<String, dynamic>? missionData,
  }) async {
    try {
      setState(() {
        _isLoading = true;
      });

      print('미션 제안 처리 시작');
      print('알림 ID: $notificationId');
      print('승인 여부: $accept');
      print('알림 메시지: $message');

      // 미션 데이터가 없으면 조회
      Map<String, dynamic>? actualMissionData = missionData;
      if (actualMissionData == null) {
        try {
          final response = await MissionService.getChildMissions(page: 0);
          if (response != null && response['data'] != null) {
            final List<dynamic> missions = response['data'];
            // 승인 대기 중인 미션 중 가장 최근 것 찾기
            for (var missionJson in missions) {
              final mission = MissionResponse.fromJson(missionJson);
              if (mission.status == MissionStatus.REQUESTED) {
                actualMissionData = missionJson;
                break;
              }
            }
          }
        } catch (e) {
          print('미션 데이터 조회 실패: $e');
        }
      }

      if (actualMissionData != null && accept) {
        // 실제 미션 수락 API 호출
        final missionId = actualMissionData['missionId'];
        final missionTitle = actualMissionData['title'] ?? '미션';
        print('미션 수락 API 호출: missionId = $missionId, title = $missionTitle');

        try {
          final acceptedMission = await MissionService.acceptMission(missionId);
          if (acceptedMission != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('미션 "$missionTitle"을(를) 수락했습니다! 열심히 수행해보세요 🎉'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 3),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('미션 수락에 실패했습니다. 다시 시도해주세요.'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 3),
              ),
            );
          }
        } catch (e) {
          print('미션 수락 API 오류: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('미션 수락 중 오류가 발생했습니다: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else if (!accept) {
        // 거절 처리 (거절 API가 없다면 UI만 업데이트)
        final missionTitle = actualMissionData?['title'] ?? '미션';
        print('미션 거절: $missionTitle');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('미션 "$missionTitle"을(를) 거절했습니다'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('미션 정보를 찾을 수 없습니다'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }

      // 알림 목록 새로고침
      await _loadFeedNotifications(refresh: true);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('미션 제안 처리 중 오류: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('오류가 발생했습니다: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );

      setState(() {
        _isLoading = false;
      });
    }
  }

  // 미션 수락/거절 처리
  Future<void> _handleMissionAction(
    MissionNotification mission,
    bool accept,
  ) async {
    try {
      final success = await MissionService.processMission(
        mission.missionId,
        accept,
      );

      if (success) {
        setState(() {
          _missionNotifications.removeWhere(
            (m) => m.missionId == mission.missionId,
          );
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('미션을 ${accept ? '수락' : '거절'}했습니다'),
            backgroundColor: accept ? Colors.green : Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('미션 ${accept ? '수락' : '거절'} 중 오류 발생: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('처리 중 오류가 발생했습니다'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _showMissionProposalModal(
    String message,
    int notificationId,
    Map<String, dynamic> notification,
  ) async {
    // 모달을 열 때 알림을 읽음 상태로 변경
    _markNotificationAsRead(notificationId);

    // 메시지에서 요청자 이름 추출
    String requesterName = '부모님';
    if (message.contains('님이 미션 승인을 요청했어요!')) {
      // 보정된 메시지에서 이름 추출
      String rawName = message.split('님이 미션 승인을 요청했어요!')[0];
      // 괄호가 있으면 제거 (예: "우리 부모님(adult)" -> "우리 부모님")
      if (rawName.contains('(')) {
        requesterName = rawName.split('(')[0].trim();
      } else {
        requesterName = rawName;
      }
    } else {
      // 기존 복잡한 형식도 지원
      final RegExp nameRegExp = RegExp(r'(.+?)\((.+?)\)이\s+미션\s+승인을\s+요청했어요');
      final Match? match = nameRegExp.firstMatch(message);
      if (match != null) {
        // 괄호 앞의 실제 이름을 사용
        requesterName = match.group(1)?.trim() ?? '부모님';
      }
    }
    
    print('추출된 요청자 이름: "$requesterName" (원본 메시지: "$message")');

    // 미션 데이터 조회 - REQUESTED 상태뿐만 아니라 최근 미션들도 확인
    Map<String, dynamic>? missionData;
    String missionTitle = '새로운 미션';
    int missionReward = 0;
    String missionCategory = 'HABIT';
    String? missionSubject;
    String startDate = DateTime.now().toString();
    String endDate = DateTime.now().add(Duration(days: 7)).toString();
    
    try {
      print('===== 미션 제안 모달용 미션 데이터 조회 시작 =====');
      final response = await MissionService.getChildMissions(page: 0);
      if (response != null && response['data'] != null) {
        final List<dynamic> missions = response['data'];
        print('조회된 미션 개수: ${missions.length}');
        
        // 1순위: REQUESTED 상태의 미션
        for (var missionJson in missions) {
          final mission = MissionResponse.fromJson(missionJson);
          print('미션 ${mission.missionId}: "${mission.title}" - 상태: ${mission.status}, 카테고리: ${mission.category}, 보상: ${mission.reward}원');
          if (mission.status == MissionStatus.REQUESTED) {
            missionData = missionJson;
            print('✅ REQUESTED 상태 미션 발견: "${mission.title}" (ID: ${mission.missionId})');
            break;
          }
        }
        
        // 2순위: REQUESTED가 없으면 가장 최근에 생성된 미션 사용
        if (missionData == null && missions.isNotEmpty) {
          missionData = missions[0]; // 첫 번째가 가장 최신
          final latestMission = MissionResponse.fromJson(missionData!);
          print('⚠️ REQUESTED 미션이 없어서 최신 미션 사용: "${latestMission.title}" (ID: ${latestMission.missionId}, 상태: ${latestMission.status})');
        }
        
        // 미션 데이터가 있으면 정보 추출
        if (missionData != null) {
          missionTitle = missionData!['title'] ?? '새로운 미션';
          missionReward = missionData!['reward'] ?? 0;
          missionCategory = missionData!['category'] ?? 'HABIT';
          missionSubject = missionData!['subject'];
          startDate = missionData!['startDate'] ?? DateTime.now().toString();
          endDate = missionData!['endDate'] ?? DateTime.now().add(Duration(days: 7)).toString();
          
          print('미션 정보 추출 완료:');
          print('- 제목: $missionTitle');
          print('- 보상: $missionReward원');
          print('- 카테고리: $missionCategory');
          print('- 과목: $missionSubject');
        }
      } else {
        print('미션 조회 응답이 null이거나 data가 없음');
      }
    } catch (e) {
      print('미션 데이터 조회 실패: $e');
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (BuildContext context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final modalWidth = screenWidth * 0.9 > 358 ? 358.0 : screenWidth * 0.9;

        return Center(
          child: Material(
            type: MaterialType.transparency,
            child: Container(
              width: modalWidth,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 상단 헤더
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '$requesterName이 미션 승인을 요청했어요!',
                                style: const TextStyle(
                                  color: Color(0xFF202020),
                                  fontSize: 15,
                                  fontFamily: 'Pretendard-Bold',
                                  letterSpacing: -0.32,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                width: 24,
                                height: 24,
                                child: const Icon(
                                  Icons.close,
                                  color: Color(0xFF999999),
                                  size: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // 미션 카드
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.fromLTRB(12, 16, 16, 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 미션 배지들
                        Wrap(
                          spacing: 6,
                          runSpacing: 8,
                          children: [
                            // 미션 배지
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFD27F),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                '미션',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontFamily: 'Pretendard-Medium',
                                  letterSpacing: -0.24,
                                ),
                              ),
                            ),

                            // 미션 과목 배지 (학습인증인 경우에만)
                            if (missionCategory == 'LEARNING' && missionSubject != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF4A90E2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                                                  child: Text(
                                    _getSubjectDisplayName(missionSubject!),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontFamily: 'Pretendard-Medium',
                                      letterSpacing: -0.24,
                                    ),
                                  ),
                              ),

                            // 날짜 배지
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF5D9EFF),
                                borderRadius: BorderRadius.circular(8),
                              ),
                                                              child: Text(
                                  _formatMissionDateRange(startDate, endDate),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontFamily: 'Pretendard-Medium',
                                    letterSpacing: -0.24,
                                  ),
                                ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // 미션 제목
                        Text(
                          missionTitle,
                          style: const TextStyle(
                            color: Color(0xFF202020),
                            fontSize: 16,
                            fontFamily: 'Pretendard-Bold',
                            letterSpacing: -0.36,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // 보상금 정보
                        Row(
                          children: [
                            const Text(
                              '신청한 보상금',
                              style: TextStyle(
                                color: Color(0xFF666666),
                                fontSize: 12,
                                fontFamily: 'Pretendard-Regular',
                                letterSpacing: -0.28,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              '${NumberFormat('#,###').format(missionReward)}원',
                              style: const TextStyle(
                                color: Color(0xFF5D9EFF),
                                fontSize: 14,
                                fontFamily: 'Pretendard-Bold',
                                letterSpacing: -0.32,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // 하단 버튼
                  Container(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                              _processMissionProposal(
                                notificationId,
                                false,
                                message: message,
                                missionData: missionData,
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDADADA),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: const Text(
                                '거절하기',
                                style: TextStyle(
                                  color: Color(0xFFB6B6B6),
                                  fontSize: 14,
                                  fontFamily: 'Pretendard-Medium',
                                  letterSpacing: -0.32,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                              _processMissionProposal(
                                notificationId,
                                true,
                                message: message,
                                missionData: missionData,
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: const Color(0xFF5D9EFF),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: const Text(
                                '수락하기',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontFamily: 'Pretendard-Medium',
                                  letterSpacing: -0.32,
                                ),
                              ),
                            ),
                          ),
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

  void _showFriendRequestModal(
    String message,
    int notificationId,
    Map<String, dynamic> notification,
  ) {
    // 모달을 열 때 알림을 읽음 상태로 변경
    _markNotificationAsRead(notificationId);

    // 메시지에서 사용자명 추출
    String userName = message;
    if (message.contains('님이 친구 요청을 보냈어요!')) {
      userName = message.split('님이 친구 요청을 보냈어요!')[0];
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            width: 358,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 358,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  decoration: const ShapeDecoration(
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              userName,
                              style: const TextStyle(
                                color: Color(0xFF202020),
                                fontSize: 18,
                                fontFamily: 'Pretendard-Bold',
                                letterSpacing: -0.72,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: const Icon(
                              Icons.close,
                              size: 20,
                              color: Color(0xFF999999),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '친구를 맺고 함께 소통을 시작해 보세요',
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
                Container(
                  width: 358,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 24,
                  ),
                  decoration: const ShapeDecoration(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(24),
                        bottomRight: Radius.circular(24),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                                                      onTap: () {
                              Navigator.pop(context);
                              _processFriendRequest(
                                notificationId,
                                false,
                                message: message, // 보정된 메시지 사용
                              );
                            },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 16,
                            ),
                            decoration: ShapeDecoration(
                              color: const Color(0xFFDADADA),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Center(
                              child: Text(
                                '친구 거절',
                                style: TextStyle(
                                  color: Color(0xFFB6B6B6),
                                  fontSize: 14,
                                  fontFamily: 'Pretendard-Light',
                                  letterSpacing: -0.28,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: GestureDetector(
                                                      onTap: () {
                              Navigator.pop(context);
                              _processFriendRequest(
                                notificationId,
                                true,
                                message: message, // 보정된 메시지 사용
                              );
                            },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 16,
                            ),
                            decoration: ShapeDecoration(
                              color: const Color(0xFF5D9EFF),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Center(
                              child: Text(
                                '친구 수락',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontFamily: 'Pretendard-Light',
                                  letterSpacing: -0.28,
                                ),
                              ),
                            ),
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
      },
    );
  }

  // 과목명을 한국어로 변환하는 헬퍼 메서드
  String _getSubjectDisplayName(String subject) {
    switch (subject) {
      case 'KOREAN':
        return '국어';
      case 'ENGLISH':
        return '영어';
      case 'MATH':
        return '수학';
      case 'SOCIAL':
        return '사회';
      case 'SCIENCE':
        return '과학';
      default:
        return subject;
    }
  }

  // 미션 날짜 범위를 포맷팅하는 헬퍼 메서드
  String _formatMissionDateRange(String startDate, String endDate) {
    try {
      final start = DateTime.parse(startDate);
      final end = DateTime.parse(endDate);

      // YY.MM.DD 형식으로 포맷팅
      final startFormatted =
          '${start.year.toString().substring(2)}.${start.month.toString().padLeft(2, '0')}.${start.day.toString().padLeft(2, '0')}';
      final endFormatted =
          '${end.month.toString().padLeft(2, '0')}.${end.day.toString().padLeft(2, '0')}';

      return '$startFormatted - $endFormatted';
    } catch (e) {
      print('날짜 포맷팅 오류: $e');
      return '날짜 확인 불가';
    }
  }
}
