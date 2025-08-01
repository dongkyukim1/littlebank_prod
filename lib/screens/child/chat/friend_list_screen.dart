import 'package:flutter/material.dart';
import '../../../services/relationship_service.dart';
import '../../../services/chat_service.dart';
import '../../../services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'components/friend_item.dart';

import 'components/search_chip.dart';
import 'components/frequent_friend_item.dart';

import '../chat_detail_screen.dart';
import 'chat_start_screen.dart';
import 'same_school_students_screen.dart';

class FriendListScreen extends StatefulWidget {
  final bool isInviteMode;
  final int? roomId;
  final List<int>? existingParticipantIds;

  const FriendListScreen({
    super.key,
    this.isInviteMode = false,
    this.roomId,
    this.existingParticipantIds,
  });

  @override
  State<FriendListScreen> createState() => _FriendListScreenState();
}

class _FriendListScreenState extends State<FriendListScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _recentSearches = [];
  List<String> _filteredSearches = [];
  String _searchQuery = '';
  bool _showRecentSearch = false;
  bool _isSearching = false;
  final FocusNode _searchFocus = FocusNode();

  // 초성 필터 관련
  String _selectedInitial = '';
  final List<String> _koreanInitials = [
    'ㄱ',
    'ㄴ',
    'ㄷ',
    'ㄹ',
    'ㅁ',
    'ㅂ',
    'ㅅ',
    'ㅇ',
    'ㅈ',
    'ㅎ',
  ];

  // 서버에서 받아온 친구 목록 데이터 관리
  List<dynamic> _friendData = [];
  List<Map<String, dynamic>> _filteredProfiles = [];
  bool _isLoading = false;
  bool _hasError = false;
  int _currentPage = 0;
  bool _hasMoreData = true;
  final ScrollController _scrollController = ScrollController();

  // 같은 학교 학생들 데이터 관리
  List<Map<String, dynamic>> _sameSchoolStudents = [];
  bool _isLoadingSameSchool = false;
  int _sameSchoolTotalCount = 0;

  // 자주 대화한 친구들 데이터
  List<Map<String, dynamic>> _frequentChatFriends = [];
  bool _isLoadingFrequentFriends = false;

  // 초대 모드 관련 변수들
  List<int> _selectedFriendIds = [];
  bool _isInviting = false;

  // 친구 데이터와 가족 멤버를 합친 목록
  List<dynamic> get _mergedFriendList {
    // 가족 멤버 관련 코드 삭제하고 친구 목록만 반환
    return _friendData;
  }

  // 친구 데이터를 분리
  List<dynamic> get _bestFriends =>
      _mergedFriendList
          .where((friend) => friend['isBestFriend'] == true)
          .toList();
  List<dynamic> get _normalFriends =>
      _mergedFriendList
          .where((friend) => friend['isBestFriend'] != true)
          .toList();

  // 초성으로 필터링된 친구 목록
  List<dynamic> get _filteredBestFriends {
    if (_selectedInitial.isEmpty) return _bestFriends;
    return _bestFriends.where((friend) {
      final userInfo = friend['userInfo'] ?? {};
      final name = friend['customName'] ?? userInfo['userName'] ?? '이름 없음';
      final initial = _getKoreanInitial(name);
      return initial == _selectedInitial;
    }).toList();
  }

  List<dynamic> get _filteredNormalFriends {
    if (_selectedInitial.isEmpty) return _normalFriends;
    return _normalFriends.where((friend) {
      final userInfo = friend['userInfo'] ?? {};
      final name = friend['customName'] ?? userInfo['userName'] ?? '이름 없음';
      final initial = _getKoreanInitial(name);
      return initial == _selectedInitial;
    }).toList();
  }

  // 검색어로 필터링된 친구 목록
  List<dynamic> get _filteredFriends {
    if (_searchQuery.isEmpty) {
      return [];
    }

    // 서버 데이터를 기반으로 필터링
    return _mergedFriendList.where((friendData) {
      final userInfo = friendData['userInfo'] ?? {};
      final name = friendData['customName'] ?? userInfo['userName'] ?? '이름 없음';
      return name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();

    // 앱 시작 시 친구 목록 로드
    _initializeData();

    // 포커스 변경 리스너 추가
    _searchFocus.addListener(() {
      if (!_searchFocus.hasFocus) {
        // 포커스를 잃으면 최근 검색 숨김
        setState(() {
          _showRecentSearch = false;
        });
      } else {
        // 포커스를 얻으면 최근 검색 표시
        setState(() {
          _showRecentSearch = true;
        });
      }
    });

    // 스크롤 리스너로 페이지네이션 처리
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !_isLoading &&
          _hasMoreData) {
        _fetchFriendList();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // 검색어 저장 (shared_preferences에)
  Future<void> _saveSearchesToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('recentSearches', _recentSearches);
      print('검색어 저장됨: $_recentSearches');
    } catch (e) {
      print('검색어 저장 실패: $e');
    }
  }

  // 검색어 불러오기
  Future<void> _loadRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _recentSearches = prefs.getStringList('recentSearches') ?? [];
      });
      print('검색어 불러옴: $_recentSearches');
    } catch (e) {
      print('검색어 로드 실패: $e');
      setState(() {
        _recentSearches = [];
      });
    }
  }

  // 검색어 저장하기
  Future<void> _saveSearch(String query) async {
    if (query.isEmpty) return;

    setState(() {
      // 중복 검색어 제거
      _recentSearches.removeWhere((item) => item == query);

      // 최근 검색어 목록 맨 앞에 추가
      _recentSearches.insert(0, query);

      // 검색어 개수 제한 (최대 20개)
      if (_recentSearches.length > 20) {
        _recentSearches = _recentSearches.sublist(0, 20);
      }
    });

    // 검색어 저장
    _saveSearchesToPrefs();
  }

  // 검색어 삭제
  Future<void> _removeSearch(String query) async {
    setState(() {
      _recentSearches.removeWhere((item) => item == query);
    });

    // 검색어 저장
    _saveSearchesToPrefs();
  }

  // 모든 검색어 삭제
  Future<void> _clearAllSearches() async {
    setState(() {
      _recentSearches.clear();
    });

    // 검색어 저장
    _saveSearchesToPrefs();
  }

  // 한글 완성 여부 확인 함수
  bool _isKoreanComplete(String char) {
    if (char.isEmpty) return false;
    int code = char.codeUnitAt(0);
    // 완성된 한글 범위: AC00(가) ~ D7A3(힣)
    return code >= 0xAC00 && code <= 0xD7A3;
  }

  // 한글 초성 추출 함수
  String _getKoreanInitial(String name) {
    if (name.isEmpty) return '';

    const initials = [
      'ㄱ',
      'ㄲ',
      'ㄴ',
      'ㄷ',
      'ㄸ',
      'ㄹ',
      'ㅁ',
      'ㅂ',
      'ㅃ',
      'ㅅ',
      'ㅆ',
      'ㅇ',
      'ㅈ',
      'ㅉ',
      'ㅊ',
      'ㅋ',
      'ㅌ',
      'ㅍ',
      'ㅎ',
    ];

    int code = name.codeUnitAt(0);
    if (code >= 0xAC00 && code <= 0xD7A3) {
      int initialIndex = ((code - 0xAC00) / 588).floor();
      return initials[initialIndex];
    }

    return name[0].toUpperCase();
  }

  // 검색어 필터링
  void _filterSearches(String query) {
    print('검색어 입력: $query');
    setState(() {
      _searchQuery = query;

      if (query.isEmpty) {
        _filteredSearches = [];
        _filteredProfiles = [];
        _isSearching = false;
        return;
      }

      // 3글자 완성 시 자동으로 검색어 저장하고 최근 검색 UI 제거
      if (query.length == 3 && _isKoreanComplete(query[2])) {
        _saveSearch(query);
        _showRecentSearch = false;
        _isSearching = true;
      } else {
        _isSearching = true;
      }

      // 대소문자 구분 없이 검색어 기록 필터링
      _filteredSearches =
          _recentSearches
              .where((item) => item.toLowerCase().contains(query.toLowerCase()))
              .toList();

      // 친구 목록에서 검색
      _filteredProfiles =
          _mergedFriendList
              .map((friend) {
                final userInfo = friend['userInfo'] ?? {};
                final friendInfo = friend['friendInfo'] ?? {};
                final name =
                    friend['customName'] ??
                    friendInfo['customName'] ??
                    userInfo['realName'] ??
                    userInfo['userName'] ??
                    '이름 없음';
                final profileImagePath = userInfo['profileImagePath'] ?? '';
                final isBlocked =
                    friend['isBlocked'] ?? friendInfo['isBlocked'] ?? false;
                final isBestFriend =
                    friend['isBestFriend'] ??
                    friendInfo['isBestFriend'] ??
                    false;
                final friendId =
                    friend['friendId'] ?? friendInfo['friendId'] ?? 0;
                final userId = userInfo['userId'] ?? 0;
                final statusMessage = userInfo['statusMessage'] ?? '';

                // 프로필 이미지 URL 변환
                String profileImageUrl = '';
                if (profileImagePath != null &&
                    profileImagePath.toString().isNotEmpty) {
                  if (profileImagePath.toString().startsWith('http')) {
                    // 이미 완전한 URL(카카오 등)인 경우 그대로 사용
                    profileImageUrl = profileImagePath.toString();
                  } else if (profileImagePath.toString().startsWith(
                    'images/',
                  )) {
                    // 서버 이미지 경로인 경우 S3 URL로 변환
                    profileImageUrl =
                        'https://littlebank-dev.s3.ap-northeast-2.amazonaws.com/$profileImagePath';
                  }
                }

                return {
                  'name': name,
                  'description':
                      isBlocked
                          ? '차단됨'
                          : (statusMessage != null && statusMessage.isNotEmpty
                              ? statusMessage
                              : (isBestFriend ? '친한 친구' : '')),
                  'friendId': friendId,
                  'userId': userId,
                  'profileImageUrl': profileImageUrl, // 수정: 완전한 URL로 변환
                  'isBlocked': isBlocked,
                  'isBestFriend': isBestFriend,
                };
              })
              .where(
                (profile) => profile['name'].toString().toLowerCase().contains(
                  query.toLowerCase(),
                ),
              )
              .toList();

      print('검색 결과: $_filteredSearches');
      print('검색된 친구: ${_filteredProfiles.map((p) => p['name']).toList()}');
    });
  }

  // 서버에서 친구 목록 조회
  Future<void> _fetchFriendList({bool refresh = false}) async {
    if (_isLoading || (!_hasMoreData && !refresh)) return;

    setState(() {
      _isLoading = true;
      if (refresh) {
        _currentPage = 0;
        _friendData = [];
        _hasMoreData = true;
      }
    });

    try {
      // 친구 목록 불러오기
      final result = await RelationshipService.getFriendList();

      if (result != null) {
        setState(() {
          final List<dynamic> newFriends = result;

          // 데이터 로깅 - 서버 응답 구조 확인
          print('===== 친구 목록 데이터 구조 확인 =====');
          print('응답 데이터: $result');
          for (var friend in newFriends) {
            print('친구 데이터: $friend');
            print('friendId: ${friend['friendId']}');
            print('userInfo: ${friend['userInfo']}');
            if (friend['userInfo'] != null) {
              print('userId: ${friend['userInfo']['userId']}');
            }
            print('-----------------------');
          }

          if (refresh) {
            _friendData = newFriends;
          } else {
            _friendData.addAll(newFriends);
          }

          // 전체 조회이므로 더 불러올 데이터 없음
          _hasMoreData = false;

          _isLoading = false;
          _hasError = false;
        });

        print('친구 목록 로드 완료: ${_friendData.length}개');
      } else {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    } catch (e) {
      print('친구 목록 로딩 중 오류 발생: $e');
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  // 데이터 초기화 함수
  Future<void> _initializeData() async {
    try {
      // 친구 목록 로드
      await _fetchFriendList(refresh: true);
      
      // 같은 학교 학생들 로드
      await _fetchSameSchoolStudents();

      // 자주 대화한 친구들 로드 (채팅 API 기반)
      await _fetchFrequentChatFriends();
    } catch (e) {
      print('데이터 초기화 중 오류 발생: $e');
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  // 같은 학교 학생들 조회
  Future<void> _fetchSameSchoolStudents() async {
    if (_isLoadingSameSchool) return;

    setState(() {
      _isLoadingSameSchool = true;
    });

    try {
      print('🏫 같은 학교 학생들 조회 시작');
      
      // 실제 API 사용
      final students = await AuthService.getSameSchoolStudents();
      
      if (mounted) {
        setState(() {
          _sameSchoolStudents = students;
          _sameSchoolTotalCount = students.length;
          _isLoadingSameSchool = false;
        });
        
        print('🏫 같은 학교 학생들 조회 완료: ${students.length}명');
      }
    } catch (e) {
      print('🏫 같은 학교 학생들 조회 실패: $e');
      if (mounted) {
        setState(() {
          _isLoadingSameSchool = false;
          _sameSchoolStudents = [];
          _sameSchoolTotalCount = 0;
        });
      }
    }
  }

  // 자주 대화한 친구들 조회 (채팅 서비스 기반)
  Future<void> _fetchFrequentChatFriends() async {
    if (_isLoadingFrequentFriends) return;

    setState(() {
      _isLoadingFrequentFriends = true;
    });

    try {
      print('💬 자주 대화한 친구들 조회 시작');
      
      // 최근 채팅방 목록을 조회해서 자주 대화한 친구 추출
      final chatRooms = await ChatService.getChatRoomList();
      
      if (chatRooms != null) {
        final List<dynamic> rooms = chatRooms;
        
        // 최근 활동이 많은 상위 3개 채팅방의 친구들을 자주 대화한 친구로 설정
        final frequentFriends = <Map<String, dynamic>>[];
        
        for (var room in rooms.take(3)) {
          final participants = room['participants'] as List<dynamic>? ?? [];
          
          // 나를 제외한 참가자들 중에서 친구인 사용자들 찾기
          for (var participant in participants) {
            final userId = participant['userId'];
            final realName = participant['realName'] ?? '알 수 없음';
            final profileImagePath = participant['profileImagePath'];
            
            // 친구 목록에서 해당 사용자가 친구인지 확인
            dynamic friendData;
            try {
              friendData = _friendData.firstWhere(
                (friend) => friend['userInfo']?['userId'] == userId,
              );
            } catch (e) {
              friendData = null;
            }
            
            if (friendData != null) {
              final friendInfo = friendData['friendInfo'] ?? {};
              
              frequentFriends.add({
                'name': realName,
                'description': friendData['userInfo']?['statusMessage'] ?? '',
                'profileImageUrl': profileImagePath != null && profileImagePath.isNotEmpty
                    ? (profileImagePath.startsWith('http') 
                        ? profileImagePath 
                        : 'https://littlebank-dev.s3.ap-northeast-2.amazonaws.com/$profileImagePath')
                    : '',
                'userId': userId,
                'friendId': friendInfo['friendId'],
                'isBlocked': friendInfo['isBlocked'] ?? false,
                'isBestFriend': friendInfo['isBestFriend'] ?? false,
                'statusMessage': friendData['userInfo']?['statusMessage'] ?? '',
              });
            }
          }
        }
        
        // 중복 제거 (userId 기준)
        final uniqueFriends = <int, Map<String, dynamic>>{};
        for (var friend in frequentFriends) {
          final userId = friend['userId'];
          if (!uniqueFriends.containsKey(userId)) {
            uniqueFriends[userId] = friend;
          }
        }
        
        setState(() {
          _frequentChatFriends = uniqueFriends.values.take(3).toList();
          _isLoadingFrequentFriends = false;
        });
        
        print('💬 자주 대화한 친구들 조회 완료: ${_frequentChatFriends.length}명');
      }
    } catch (e) {
      print('💬 자주 대화한 친구들 조회 실패: $e');
      if (mounted) {
        setState(() {
          _isLoadingFrequentFriends = false;
          _frequentChatFriends = [];
        });
      }
    }
  }

  // 친구 초대 처리
  Future<void> _inviteSelectedFriends() async {
    if (_selectedFriendIds.isEmpty || widget.roomId == null) return;

    setState(() {
      _isInviting = true;
    });

    try {
      print('=== 🎉 친구 초대 시작 ===');
      print('채팅방 ID: ${widget.roomId}');
      print('초대할 친구 ID 목록: $_selectedFriendIds');

      final success = await ChatService.inviteToRoom(
        roomId: widget.roomId!,
        targetUserIds: _selectedFriendIds,
      );

      if (success) {
        print('✅ 친구 초대 성공');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${_selectedFriendIds.length}명의 친구를 초대했습니다.'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, {
            'action': 'invite_friends',
            'invitedIds': _selectedFriendIds,
            'success': true,
          });
        }
      } else {
        print('❌ 친구 초대 실패');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('친구 초대에 실패했습니다.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('❌ 친구 초대 중 오류: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('친구 초대 중 오류가 발생했습니다.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isInviting = false;
        });
      }
    }
  }

  // 친구 선택/해제 토글
  void _toggleFriendSelection(int userId) {
    if (widget.existingParticipantIds?.contains(userId) == true) {
      // 이미 채팅방에 있는 친구는 선택 불가
      return;
    }

    setState(() {
      if (_selectedFriendIds.contains(userId)) {
        _selectedFriendIds.remove(userId);
      } else {
        _selectedFriendIds.add(userId);
      }
    });
  }

  // 친구가 선택되었는지 확인
  bool _isFriendSelected(int userId) {
    return _selectedFriendIds.contains(userId);
  }

  // 친구가 이미 채팅방에 있는지 확인
  bool _isFriendAlreadyInRoom(int userId) {
    return widget.existingParticipantIds?.contains(userId) == true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_hasError || _friendData.isEmpty) {
          return true;
        }
        Navigator.of(context).pop({'friendListUpdated': true});
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        floatingActionButton:
            widget.isInviteMode && _selectedFriendIds.isNotEmpty
                ? Padding(
                  padding: const EdgeInsets.only(bottom: 40),
                  child: GestureDetector(
                    onTap: _isInviting ? null : _inviteSelectedFriends,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                      decoration: ShapeDecoration(
                        color:
                            _isInviting
                                ? const Color(0xFFCCCCCC)
                                : const Color(0xFF5D9EFF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (_isInviting)
                            const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          else
                            const Icon(
                              Icons.person_add,
                              color: Colors.white,
                              size: 18,
                            ),
                          const SizedBox(width: 10),
                          Text(
                            _isInviting
                                ? '초대 중...'
                                : '${_selectedFriendIds.length}명 초대하기',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontFamily: 'Pretendard-Medium',
                              letterSpacing: -0.56,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
                : !widget.isInviteMode
                ? Padding(
                  padding: const EdgeInsets.only(bottom: 40),
                  child: GestureDetector(
                    onTap: () {
                      // 채팅 관련 기능 - 예를 들어 새 채팅 시작하기
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => ChatDetailScreen(
                                userName: '새 채팅',
                                avatar: '💬',
                                roomId: 0,
                                userId: 0,
                              ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                      decoration: ShapeDecoration(
                        color: const Color(0xFF5D9EFF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/icons/chat_floating.png',
                            width: 18,
                            height: 18,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '채팅하기',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontFamily: 'Pretendard-Light',
                              letterSpacing: -0.56,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
                : null,
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  // 상단 헤더 - 내 친구 목록 또는 친구 초대 (검색 중이 아닐 때만 표시)
                  if (!_isSearching && !_showRecentSearch)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      color: Colors.white,
                      child: Stack(
                        children: [
                          // 뒤로가기 버튼 (왼쪽)
                          Positioned(
                            left: 0,
                            top: 0,
                            bottom: 0,
                            child: GestureDetector(
                              onTap: () {
                                if (widget.isInviteMode) {
                                  Navigator.of(context).pop();
                                } else {
                                  Navigator.of(
                                    context,
                                  ).pop({'friendListUpdated': true});
                                }
                              },
                              child: Container(
                                width: 24,
                                height: 24,
                                child: Image.asset(
                                  'assets/icons/Icon/뒤로 가기/Regular.png',
                                  width: 24,
                                  height: 24,
                                ),
                              ),
                            ),
                          ),
                          // 제목 (가운데)
                          Center(
                            child: Text(
                              widget.isInviteMode ? '친구 초대' : '내 친구 목록',
                              style: TextStyle(
                                color: Color(0xFF202020),
                                fontSize: 16,
                                fontFamily: 'Pretendard-Bold',
                                letterSpacing: -0.64,
                              ),
                            ),
                          ),
                          // 홈 버튼 (일반 모드) 또는 초대 버튼 (초대 모드)
                          Positioned(
                            right: 0,
                            top: 0,
                            bottom: 0,
                            child:
                                widget.isInviteMode
                                    ? GestureDetector(
                                      onTap:
                                          _selectedFriendIds.isEmpty ||
                                                  _isInviting
                                              ? null
                                              : _inviteSelectedFriends,
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color:
                                              _selectedFriendIds.isEmpty ||
                                                      _isInviting
                                                  ? Color(0xFFCCCCCC)
                                                  : Color(0xFF5D9EFF),
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        child:
                                            _isInviting
                                                ? SizedBox(
                                                  width: 16,
                                                  height: 16,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    valueColor:
                                                        AlwaysStoppedAnimation<
                                                          Color
                                                        >(Colors.white),
                                                  ),
                                                )
                                                : Text(
                                                  '초대',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 12,
                                                    fontFamily:
                                                        'Pretendard-Medium',
                                                  ),
                                                ),
                                      ),
                                    )
                                    : GestureDetector(
                                      onTap: () {
                                        Navigator.pop(context);
                                      },
                                      child: Container(
                                        width: 24,
                                        height: 24,
                                        child: Image.asset(
                                          'assets/icons/home.png',
                                          width: 24,
                                          height: 24,
                                        ),
                                      ),
                                    ),
                          ),
                        ],
                      ),
                    ),

                  // 검색 바 (검색 중일 때는 헤더 자리로 이동)
                  Container(
                    padding: EdgeInsets.all(16),
                    color: Colors.white,
                    child: Row(
                      children: [
                        // 검색 중일 때 뒤로가기 버튼
                        if (_isSearching || _showRecentSearch) ...[
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _searchController.clear();
                                _searchQuery = '';
                                _isSearching = false;
                                _showRecentSearch = false;
                                _filteredSearches = [];
                                _searchFocus.unfocus();
                              });
                            },
                            child: Container(
                              width: 24,
                              height: 24,
                              child: Image.asset(
                                'assets/icons/Icon/뒤로 가기/Regular.png',
                                width: 24,
                                height: 24,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                        ],
                        // 검색창
                        Expanded(
                          child: Container(
                            height: 44,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: ShapeDecoration(
                              color: const Color(0xFFE7ECF6),
                              shape: RoundedRectangleBorder(
                                side: BorderSide(
                                  width: 0.60,
                                  color:
                                      _searchQuery.isNotEmpty
                                          ? const Color(
                                            0xFF146AFF,
                                          ) // rgba(20, 106, 255, 1)
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
                                  child: TextField(
                                    controller: _searchController,
                                    focusNode: _searchFocus,
                                    onChanged: _filterSearches,
                                    textAlign: TextAlign.left,
                                    textAlignVertical: TextAlignVertical.center,
                                    style: const TextStyle(
                                      color: Color(0xFF202020),
                                      fontSize: 12,
                                      fontFamily: 'Pretendard-Light',
                                      letterSpacing: -0.48,
                                    ),
                                    decoration: const InputDecoration(
                                      hintText: '찿고싶은 채팅 상대를 검색해 주세요',
                                      hintStyle: TextStyle(
                                        color: Color(0xFF999999),
                                        fontSize: 12,
                                        fontFamily: 'Pretendard-Light',
                                        letterSpacing: -0.48,
                                      ),
                                      filled: true,
                                      fillColor: Color(0xFFE7ECF6),
                                      isCollapsed: true,
                                      contentPadding: EdgeInsets.zero,
                                      border: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                    ),
                                    onSubmitted: (value) {
                                      if (value.isNotEmpty) {
                                        _saveSearch(value);
                                        setState(() {
                                          _isSearching = false;
                                        });
                                      }
                                    },
                                    onTap: () {
                                      setState(() {
                                        _showRecentSearch = true;
                                        _isSearching = false;
                                      });
                                    },
                                  ),
                                ),
                                if (_searchController.text.isNotEmpty)
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _searchController.clear();
                                        _searchQuery = '';
                                        _isSearching = false;
                                        _filteredSearches = [];
                                      });
                                    },
                                    child: Container(
                                      width: 24,
                                      height: 24,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Color(0xFFCCCCCC),
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        size: 18,
                                        color: Colors.white,
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

                  // 검색 바를 탭했을 때 필터 옵션 표시
                  if (_showRecentSearch && !_isSearching)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      color: Colors.white,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '최근 검색했어요',
                            style: TextStyle(
                              color: Color(0xFF202020),
                              fontSize: 16,
                              fontFamily: 'Pretendard-Bold',
                              letterSpacing: -0.72,
                            ),
                          ),
                          TextButton(
                            onPressed: () => _clearAllSearches(),
                            child: const Text(
                              '전체 삭제',
                              style: TextStyle(
                                color: Color(0xFF8490A3),
                                fontSize: 12,
                                fontFamily: 'Pretendard-Light',
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // 검색 바를 탭했을 때 최근 검색어와 자주 대화한 친구 표시
                  if (_showRecentSearch && !_isSearching)
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),

                            // 최근 검색어 목록
                            if (_recentSearches.isNotEmpty) ...[
                              // '최근 검색어' 제목 섹션은 상단에 이미 표시됨

                              // 검색어 칩 목록 (최근 검색 기록)
                              Container(
                                width: double.infinity,
                                alignment: Alignment.centerLeft,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: Wrap(
                                  alignment: WrapAlignment.start,
                                  crossAxisAlignment: WrapCrossAlignment.start,
                                  spacing: 4,
                                  runSpacing: 4,
                                  children:
                                      _recentSearches
                                          .take(10)
                                          .map(
                                            (search) => SearchChip(
                                              label: search,
                                              onTap: () {
                                                _searchController.text = search;
                                                _saveSearch(search);
                                                _filterSearches(search);
                                                setState(() {
                                                  _isSearching = true;
                                                });
                                              },
                                              onRemove:
                                                  () => _removeSearch(search),
                                            ),
                                          )
                                          .toList(),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                  // 검색 결과가 없고 검색 모드일 때 (검색 바 탭 상태가 아닐 때)
                  if (!_isSearching && !_showRecentSearch)
                    Expanded(
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 최근 검색 헤더 (검색어가 있는 경우만 표시)
                            if (_recentSearches.isNotEmpty && _showRecentSearch)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  0,
                                  16,
                                  8,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      '최근 검색',
                                      style: TextStyle(
                                        color: Color(0xFF202020),
                                        fontSize: 18,
                                        fontFamily: 'Pretendard-Bold',
                                        letterSpacing: -0.72,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () => _clearAllSearches(),
                                      child: const Text(
                                        '전체 삭제',
                                        style: TextStyle(
                                          color: Color(0xFFCCCCCC),
                                          fontSize: 10,
                                          fontFamily: 'Pretendard-Light',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            // 검색어 칩 목록 (검색어가 있는 경우만 표시)
                            if (_recentSearches.isNotEmpty && _showRecentSearch)
                              Container(
                                width: double.infinity,
                                alignment: Alignment.centerLeft,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: Wrap(
                                  alignment: WrapAlignment.start,
                                  crossAxisAlignment: WrapCrossAlignment.start,
                                  spacing: 4,
                                  runSpacing: 4,
                                  children:
                                      _recentSearches
                                          .take(10)
                                          .map(
                                            (search) => SearchChip(
                                              label: search,
                                              onTap: () {
                                                _searchController.text = search;
                                                _saveSearch(search);
                                                _filterSearches(search);
                                                setState(() {
                                                  _isSearching = true;
                                                });
                                              },
                                              onRemove:
                                                  () => _removeSearch(search),
                                            ),
                                          )
                                          .toList(),
                                ),
                              ),

                            if (_recentSearches.isNotEmpty && _showRecentSearch)
                              const SizedBox(height: 16),

                            // 친한 친구 헤더와 목록 (친한 친구가 있는 경우만 표시)
                            if (_filteredBestFriends.isNotEmpty) ...[
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          const Text(
                                            '친한 친구',
                                            style: TextStyle(
                                              color: Color(0xFF202020),
                                              fontSize: 16,
                                              fontFamily: 'Pretendard-Bold',
                                              letterSpacing: -0.64,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            '${_filteredBestFriends.length}',
                                            style: const TextStyle(
                                              color: Color(0xFF3A88F4),
                                              fontSize: 16,
                                              fontFamily: 'Pretendard-Bold',
                                              letterSpacing: -0.64,
                                            ),
                                          ),
                                          if (widget.isInviteMode &&
                                              _selectedFriendIds
                                                  .isNotEmpty) ...[
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Color(0xFF5D9EFF),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                '${_selectedFriendIds.length}명 선택',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                  fontFamily:
                                                      'Pretendard-Medium',
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 8),

                              // 친한 친구 목록 컨테이너
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: Column(
                                  children: [
                                    ...List.generate(
                                      _filteredBestFriends.length,
                                      (index) {
                                        final friend =
                                            _filteredBestFriends[index];
                                        final userId =
                                            friend['userInfo']?['userId'] ?? 0;

                                        return FriendItem(
                                          friend: friend,
                                          onFriendUpdated: (result) {
                                            _fetchFriendList(refresh: true);
                                          },
                                          isInviteMode: widget.isInviteMode,
                                          isSelected: _isFriendSelected(userId),
                                          isDisabled: _isFriendAlreadyInRoom(
                                            userId,
                                          ),
                                          onTap:
                                              () => _toggleFriendSelection(
                                                userId,
                                              ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 24),
                            ],

                            // 모든 친구 헤더
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                child: Row(
                                  children: [
                                    const Text(
                                      '모든 친구',
                                      style: TextStyle(
                                        color: Color(0xFF202020),
                                        fontSize: 16,
                                        fontFamily: 'Pretendard-Bold',
                                        letterSpacing: -0.64,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${_filteredNormalFriends.length}',
                                      style: const TextStyle(
                                        color: Color(0xFF3A88F4),
                                        fontSize: 16,
                                        fontFamily: 'Pretendard-Bold',
                                        letterSpacing: -0.64,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 8),

                            if (_isLoading && _friendData.isEmpty)
                              const Center(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 100),
                                  child: CircularProgressIndicator(
                                    color: Color(0xFF3A88F4),
                                  ),
                                ),
                              )
                            else if (_hasError && _friendData.isEmpty)
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 100,
                                  ),
                                  child: Column(
                                    children: [
                                      const Icon(
                                        Icons.error_outline,
                                        color: Colors.red,
                                        size: 48,
                                      ),
                                      const SizedBox(height: 16),
                                      const Text(
                                        '친구 목록을 불러오는 중 오류가 발생했습니다',
                                        style: TextStyle(
                                          color: Color(0xFF666666),
                                          fontSize: 14,
                                          fontFamily: 'Pretendard-Regular',
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      ElevatedButton(
                                        onPressed:
                                            () =>
                                                _fetchFriendList(refresh: true),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(
                                            0xFF3A88F4,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                        ),
                                        child: const Text('다시 시도'),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else if (_friendData.isEmpty)
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 100,
                                  ),
                                  child: Column(
                                    children: [
                                      const Icon(
                                        Icons.person_outline,
                                        color: Color(0xFFCCCCCC),
                                        size: 48,
                                      ),
                                      const SizedBox(height: 16),
                                      const Text(
                                        '아직 친구가 없습니다',
                                        style: TextStyle(
                                          color: Color(0xFF666666),
                                          fontSize: 14,
                                          fontFamily: 'Pretendard-Regular',
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      const Text(
                                        '우측 하단의 + 버튼을 눌러 친구를 추가해보세요',
                                        style: TextStyle(
                                          color: Color(0xFF999999),
                                          fontSize: 12,
                                          fontFamily: 'Pretendard-Light',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else
                              // 일반 친구 목록 컨테이너
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: Column(
                                  children: [
                                    ...List.generate(
                                      _filteredNormalFriends.length,
                                      (index) {
                                        final friend =
                                            _filteredNormalFriends[index];
                                        final userId =
                                            friend['userInfo']?['userId'] ?? 0;

                                        return FriendItem(
                                          friend: friend,
                                          onFriendUpdated: (result) {
                                            _fetchFriendList(refresh: true);
                                          },
                                          isInviteMode: widget.isInviteMode,
                                          isSelected: _isFriendSelected(userId),
                                          isDisabled: _isFriendAlreadyInRoom(
                                            userId,
                                          ),
                                          onTap:
                                              () => _toggleFriendSelection(
                                                userId,
                                              ),
                                        );
                                      },
                                    ),
                                    // 로딩 인디케이터 표시
                                    if (_isLoading && _hasMoreData)
                                      const Padding(
                                        padding: EdgeInsets.all(8.0),
                                        child: Center(
                                          child: SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              color: Color(0xFF3A88F4),
                                              strokeWidth: 2,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),

                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),

                  // 검색 중일 때 최근 검색어 + 검색 결과 표시
                  if (_isSearching)
                    Expanded(
                      child:
                          _filteredProfiles.isEmpty && _searchQuery.length >= 3
                              ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 193,
                                      height: 108,
                                      decoration: BoxDecoration(
                                        image: DecorationImage(
                                          image: AssetImage(
                                            "assets/icons/search_none.png",
                                          ),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                      ),
                                      child: Column(
                                        children: [
                                          Text(
                                            _searchQuery.isNotEmpty
                                                ? '\'$_searchQuery\'이라는 검색 결과가 없습니다!'
                                                : '검색 결과가 없습니다!',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: const Color(0xFF202020),
                                              fontSize: 18,
                                              fontFamily: 'Pretendard-Bold',
                                              height: 1.50,
                                              letterSpacing: -0.72,
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            '입력하신 단어의 철자가 맞는지 확인해 주세요',
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
                                  ],
                                ),
                              )
                              : SingleChildScrollView(
                                child: Column(
                                  children: [
                                    // 최근 검색어 표시 (3글자 완성되지 않았을 때만)
                                    if (_recentSearches.isNotEmpty &&
                                        !(_searchQuery.length >= 3 &&
                                            _isKoreanComplete(
                                              _searchQuery[2],
                                            ))) ...[
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                        color: Colors.white,
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text(
                                              '최근 검색했어요',
                                              style: TextStyle(
                                                color: Color(0xFF202020),
                                                fontSize: 16,
                                                fontFamily: 'Pretendard-Bold',
                                                letterSpacing: -0.72,
                                              ),
                                            ),
                                            TextButton(
                                              onPressed:
                                                  () => _clearAllSearches(),
                                              child: const Text(
                                                '전체 삭제',
                                                style: TextStyle(
                                                  color: Color(0xFF8490A3),
                                                  fontSize: 12,
                                                  fontFamily:
                                                      'Pretendard-Light',
                                                  fontWeight: FontWeight.w300,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        width: double.infinity,
                                        alignment: Alignment.centerLeft,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                        ),
                                        child: Wrap(
                                          alignment: WrapAlignment.start,
                                          crossAxisAlignment:
                                              WrapCrossAlignment.start,
                                          spacing: 4,
                                          runSpacing: 4,
                                          children:
                                              _recentSearches
                                                  .take(10)
                                                  .map(
                                                    (search) => SearchChip(
                                                      label: search,
                                                      onTap: () {
                                                        _searchController.text =
                                                            search;
                                                        _saveSearch(search);
                                                        _filterSearches(search);
                                                      },
                                                      onRemove:
                                                          () => _removeSearch(
                                                            search,
                                                          ),
                                                    ),
                                                  )
                                                  .toList(),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                    ],

                                    // 구분선
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

                                    // 검색 결과 섹션
                                    if (_filteredProfiles.isNotEmpty) ...[
                                      // 내 친구들 섹션
                                      Container(
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                        ),
                                        child: Column(
                                          children: [
                                            Container(
                                              width: double.infinity,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                    vertical: 12,
                                                  ),
                                              child: Row(
                                                children: [
                                                  Text(
                                                    '내 친구들',
                                                    style: TextStyle(
                                                      color: const Color(
                                                        0xFF202020,
                                                      ),
                                                      fontSize: 18,
                                                      fontFamily:
                                                          'Pretendard-Bold',
                                                      letterSpacing: -0.72,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    '${_filteredProfiles.length}',
                                                    style: TextStyle(
                                                      color: const Color(
                                                        0xFF3A88F4,
                                                      ),
                                                      fontSize: 18,
                                                      fontFamily:
                                                          'Pretendard-Bold',
                                                      letterSpacing: -0.72,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Container(
                                              width: double.infinity,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                    vertical: 12,
                                                  ),
                                              child: SingleChildScrollView(
                                                scrollDirection:
                                                    Axis.horizontal,
                                                child: Row(
                                                  children: [
                                                    ..._filteredProfiles
                                                        .take(5)
                                                        .map(
                                                          (profile) => GestureDetector(
                                                            onTap: () {
                                                              // 프로필 화면으로 이동
                                                              Navigator.push(
                                                                context,
                                                                MaterialPageRoute(
                                                                  builder: (context) => ChatStartScreen(
                                                                    userId: profile['userId'] ?? 0,
                                                                    userName: profile['name'] ?? '알 수 없음',
                                                                    userDescription: profile['description'] ?? '',
                                                                    friendId: profile['friendId'],
                                                                    isBlocked: profile['isBlocked'] ?? false,
                                                                    isBestFriend: profile['isBestFriend'] ?? false,
                                                                    initialProfileImageUrl: profile['profileImageUrl'],
                                                                  ),
                                                                ),
                                                              );
                                                            },
                                                            child: Padding(
                                                              padding:
                                                                  const EdgeInsets.only(
                                                                    right: 18,
                                                                  ),
                                                              child: Column(
                                                                mainAxisSize:
                                                                    MainAxisSize
                                                                        .min,
                                                                children: [
                                                                  Container(
                                                                    width: 40,
                                                                    height: 40,
                                                                    decoration: ShapeDecoration(
                                                                      image:
                                                                          profile['profileImageUrl'] !=
                                                                                      null &&
                                                                                  profile['profileImageUrl'].toString().isNotEmpty
                                                                              ? DecorationImage(
                                                                                image: NetworkImage(
                                                                                  profile['profileImageUrl'],
                                                                                ),
                                                                                fit:
                                                                                    BoxFit.cover,
                                                                              )
                                                                              : null,
                                                                      shape: OvalBorder(
                                                                        side: BorderSide(
                                                                          width:
                                                                              0.80,
                                                                          color: const Color(
                                                                            0xFF146AFF,
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    child:
                                                                        profile['profileImageUrl'] ==
                                                                                    null ||
                                                                                profile['profileImageUrl'].toString().isEmpty
                                                                            ? Center(
                                                                              child: Text(
                                                                                profile['name'].toString().isNotEmpty
                                                                                    ? profile['name'].toString().substring(
                                                                                      0,
                                                                                      1,
                                                                                    )
                                                                                    : '?',
                                                                                style: const TextStyle(
                                                                                  fontSize:
                                                                                      16,
                                                                                  fontFamily: 'Pretendard-Bold',
                                                                                  color: Color(0xFF3A88F4),
                                                                                ),
                                                                              ),
                                                                            )
                                                                            : null,
                                                                  ),
                                                                  const SizedBox(
                                                                    height: 8,
                                                                  ),
                                                                  Text(
                                                                    profile['name'],
                                                                    style: TextStyle(
                                                                      color: const Color(
                                                                        0xFF353535,
                                                                      ),
                                                                      fontSize:
                                                                          11,
                                                                      fontFamily:
                                                                          'Pretendard-Light',
                                                                      letterSpacing:
                                                                          -0.22,
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ),
                                                        )
                                                        .toList(),
                                                    if (_filteredProfiles
                                                            .length >
                                                        5)
                                                      GestureDetector(
                                                        onTap: () {
                                                          // 전체 친구 목록 보기 - 새로운 화면으로 이동
                                                          Navigator.push(
                                                            context,
                                                            MaterialPageRoute(
                                                              builder: (context) => SameSchoolStudentsScreen(
                                                                students: _filteredProfiles,
                                                                schoolName: '검색 결과',
                                                              ),
                                                            ),
                                                          );
                                                        },
                                                        child: Column(
                                                          mainAxisSize: MainAxisSize.min,
                                                          mainAxisAlignment: MainAxisAlignment.center,
                                                          crossAxisAlignment: CrossAxisAlignment.center,
                                                          children: [
                                                            Container(
                                                              width: 40,
                                                              height: 40,
                                                              decoration: const ShapeDecoration(
                                                                color: Color(0xFFFFD27F),
                                                                shape: OvalBorder(),
                                                              ),
                                                              child: Center(
                                                                child: Text(
                                                                  '+${_filteredProfiles.length - 5}',
                                                                  style: const TextStyle(
                                                                    color: Color(0xFF001F55),
                                                                    fontSize: 12,
                                                                    fontFamily: 'Pretendard',
                                                                    fontWeight: FontWeight.w500,
                                                                    letterSpacing: -0.24,
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                            const SizedBox(height: 8),
                                                            const Text(
                                                              '전체보기',
                                                              style: TextStyle(
                                                                color: Color(0xFF353535),
                                                                fontSize: 11,
                                                                fontFamily: 'Pretendard',
                                                                fontWeight: FontWeight.w300,
                                                                letterSpacing: -0.22,
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

                                      // 구분선
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

                                                                    // 프로필 더보기 섹션 (같은 학교 학생들)
                                      Container(
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                        ),
                                        child: Column(
                                          children: [
                                            Container(
                                              width: double.infinity,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                    vertical: 12,
                                                  ),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  const SizedBox(height: 8),
                                                  Row(
                                                    children: [
                                                      Text(
                                                        '프로필 더보기',
                                                        style: TextStyle(
                                                          color: const Color(
                                                            0xFF202020,
                                                          ),
                                                          fontSize: 18,
                                                          fontFamily:
                                                              'Pretendard-Bold',
                                                          letterSpacing: -0.72,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                '${_sameSchoolTotalCount}',
                                                        style: TextStyle(
                                                          color: const Color(
                                                            0xFF3A88F4,
                                                          ),
                                                          fontSize: 18,
                                                          fontFamily:
                                                              'Pretendard-Bold',
                                                          letterSpacing: -0.72,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    '내가 등록한 학교의 친구들만 노출돼요',
                                                    style: TextStyle(
                                                      color: const Color(
                                                        0xFF999999,
                                                      ),
                                                      fontSize: 14,
                                                      fontFamily:
                                                          'Pretendard-Light',
                                                      letterSpacing: -0.28,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Container(
                                              width: double.infinity,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                    vertical: 12,
                                                  ),
                                      child: _isLoadingSameSchool
                                          ? const Center(
                                              child: CircularProgressIndicator(
                                                color: Color(0xFF3A88F4),
                                              ),
                                            )
                                          : _sameSchoolStudents.isEmpty
                                              ? const Center(
                                                  child: Padding(
                                                    padding: EdgeInsets.all(20),
                                                    child: Text(
                                                      '같은 학교 학생이 없습니다',
                                                      style: TextStyle(
                                                        color: Color(0xFF999999),
                                                        fontSize: 14,
                                                        fontFamily: 'Pretendard-Light',
                                                      ),
                                                    ),
                                                  ),
                                                )
                                              : SingleChildScrollView(
                                                scrollDirection:
                                                    Axis.horizontal,
                                                child: Row(
                                                  children: [
                                                      // 같은 학교 학생들 표시 (최대 5명)
                                                      ..._sameSchoolStudents
                                                          .take(5)
                                                          .map((student) {
                                                        final name = student['realName'] ?? student['name'] ?? '이름 없음';
                                                        final profileImagePath = student['profileImagePath'] ?? '';
                                                        final userId = student['userId'] ?? 0;
                                                        
                                                        // 프로필 이미지 URL 생성
                                                        String profileImageUrl = '';
                                                        if (profileImagePath.isNotEmpty) {
                                                          if (profileImagePath.startsWith('http')) {
                                                            profileImageUrl = profileImagePath;
                                                          } else {
                                                            profileImageUrl = AuthService.getFullProfileImageUrl(profileImagePath);
                                                          }
                                                        }
                                                        
                                                        return GestureDetector(
                                                          onTap: () {
                                                            // 학생 프로필 화면으로 이동
                                                            Navigator.push(
                                                              context,
                                                              MaterialPageRoute(
                                                                builder: (context) => ChatStartScreen(
                                                                  userId: userId,
                                                                  userName: name,
                                                                  userDescription: '같은 학교 학생',
                                                                  friendId: null,
                                                                  isBlocked: false,
                                                                  isBestFriend: false,
                                                                  initialProfileImageUrl: profileImageUrl,
                                                                ),
                                                              ),
                                                            );
                                                          },
                                                          child: Padding(
                                                            padding: const EdgeInsets.only(right: 18),
                                                        child: Column(
                                                              mainAxisSize: MainAxisSize.min,
                                                          children: [
                                                            Container(
                                                              width: 40,
                                                              height: 40,
                                                              decoration: ShapeDecoration(
                                                                    image: profileImageUrl.isNotEmpty
                                                                        ? DecorationImage(
                                                                            image: NetworkImage(profileImageUrl),
                                                                            fit: BoxFit.cover,
                                                                          )
                                                                        : null,
                                                                shape: OvalBorder(
                                                                  side: BorderSide(
                                                                    width: 0.80,
                                                                        color: const Color(0xFF146AFF),
                                                                    ),
                                                                  ),
                                                                ),
                                                                  child: profileImageUrl.isEmpty
                                                                      ? Center(
                                                                          child: Text(
                                                                            name.isNotEmpty ? name.substring(0, 1) : '?',
                                                                            style: const TextStyle(
                                                                              fontSize: 16,
                                                                              fontFamily: 'Pretendard-Bold',
                                                                              color: Color(0xFF3A88F4),
                                                                            ),
                                                                          ),
                                                                        )
                                                                      : null,
                                                                ),
                                                                const SizedBox(height: 8),
                                                            Text(
                                                                  name,
                                                                  style: const TextStyle(
                                                                    color: Color(0xFF353535),
                                                                    fontSize: 11,
                                                                    fontFamily: 'Pretendard-Light',
                                                                    letterSpacing: -0.22,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        );
                                                      }).toList(),
                                                      
                                                      // 전체보기 버튼 (5명 이상일 때만 표시)
                                                      if (_sameSchoolStudents.length > 5)
                                                        GestureDetector(
                                                          onTap: () {
                                                            // 전체 같은 학교 학생 목록 보기
                                                            Navigator.push(
                                                              context,
                                                              MaterialPageRoute(
                                                                builder: (context) => SameSchoolStudentsScreen(
                                                                  students: _sameSchoolStudents,
                                                                  schoolName: '리틀뱅크 고등학교',
                                                                ),
                                                              ),
                                                            );
                                                          },
                                                          child: Column(
                                                            mainAxisSize: MainAxisSize.min,
                                                            mainAxisAlignment: MainAxisAlignment.center,
                                                            crossAxisAlignment: CrossAxisAlignment.center,
                                                            children: [
                                                              Container(
                                                                width: 40,
                                                                height: 40,
                                                                decoration: const ShapeDecoration(
                                                                  color: Color(0xFFFFD27F),
                                                                  shape: OvalBorder(),
                                                                ),
                                                                child: Center(
                                                                  child: Text(
                                                                    '+${_sameSchoolStudents.length - 5}',
                                                                    style: const TextStyle(
                                                                      color: Color(0xFF001F55),
                                                                      fontSize: 12,
                                                                      fontFamily: 'Pretendard',
                                                                      fontWeight: FontWeight.w500,
                                                                      letterSpacing: -0.24,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                              const SizedBox(height: 8),
                                                              const Text(
                                                                '전체보기',
                                                                style: TextStyle(
                                                                  color: Color(0xFF353535),
                                                                  fontSize: 11,
                                                                  fontFamily: 'Pretendard',
                                                                  fontWeight: FontWeight.w300,
                                                                  letterSpacing: -0.22,
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
                                    ],
                                  ],
                                ),
                              ),
                    ),
                ],
              ),

              // 초성 필터 (오른쪽에 플로팅)
              if (!_isSearching && !_showRecentSearch)
                Positioned(
                  right: 16,
                  top: 160,
                  child: Container(
                    width: 16,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children:
                          _koreanInitials.map((initial) {
                            bool isSelected = _selectedInitial == initial;
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedInitial = isSelected ? '' : initial;
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: SizedBox(
                                  width: 16,
                                  height: 20,
                                  child: Center(
                                    child: Text(
                                      initial,
                                      style: TextStyle(
                                        color:
                                            isSelected
                                                ? const Color(0xFF001F55)
                                                : const Color(0xFF8490A3),
                                        fontSize: 14,
                                        fontFamily:
                                            isSelected
                                                ? 'Pretendard-Bold'
                                                : 'Pretendard-Light',
                                        letterSpacing: -0.28,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }


}

