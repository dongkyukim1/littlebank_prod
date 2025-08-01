import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../services/chat_service.dart';
import '../../../../services/auth_service.dart';
import '../friend_list_screen.dart';

class ChatRoomMenuScreen extends StatefulWidget {
  final String userName;
  final String avatar;
  final int roomId;
  final int userId;

  const ChatRoomMenuScreen({
    super.key,
    required this.userName,
    required this.avatar,
    required this.roomId,
    required this.userId,
  });

  @override
  State<ChatRoomMenuScreen> createState() => _ChatRoomMenuScreenState();
}

class _ChatRoomMenuScreenState extends State<ChatRoomMenuScreen> {
  bool _isLoading = false;
  bool _isGroupChat = false;
  String _roomName = '';
  int _currentUserId = 0;
  int _participantCount = 0;
  List<Map<String, dynamic>> _participants = [];
  bool _isNotificationEnabled = true;
  late TextEditingController _roomNameController; // 채팅방 이름 편집용 컨트롤러

  @override
  void initState() {
    super.initState();
    _roomNameController = TextEditingController();
    _loadRoomInfo();
  }

  @override
  void dispose() {
    _roomNameController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(ChatRoomMenuScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.roomId != widget.roomId) {
      _loadRoomInfo();
    }
  }

  // 새로고침 기능
  Future<void> _refreshRoomInfo() async {
    print('🔄 채팅방 정보 새로고침 시작');
    await _loadRoomInfo();
  }

  Future<void> _loadRoomInfo() async {
    setState(() => _isLoading = true);

    try {
      // 현재 사용자 정보 가져오기
      final userInfo = await AuthService.getUserInfo();
      if (userInfo != null && userInfo['userId'] != null) {
        _currentUserId = userInfo['userId'];
        print('🔍 현재 사용자 ID: $_currentUserId');
      }

      // 채팅방 상세 정보 가져오기
      final roomDetails = await ChatService.getChatRoomDetails(widget.roomId);
      print('🔍 채팅방 상세 정보: $roomDetails');
      
      if (roomDetails != null && mounted) {
        final roomRange = roomDetails['roomRange'];
        final participantCount = roomDetails['participantCount'] ?? 0;
        final participantNameList = roomDetails['participantNameList'] as List<dynamic>? ?? [];
        final participants = roomDetails['participants'] as List<dynamic>? ?? [];

        print('🔍 roomRange: $roomRange');
        print('🔍 participantCount: $participantCount');
        print('🔍 participantNameList: $participantNameList');
        print('🔍 participants raw: $participants');

        // 참여자 정보를 더 안전하게 파싱
        List<Map<String, dynamic>> parsedParticipants = [];
        
        if (participants.isNotEmpty) {
          for (var participant in participants) {
            try {
              if (participant is Map<String, dynamic>) {
                parsedParticipants.add(participant);
              } else if (participant is Map) {
                parsedParticipants.add(Map<String, dynamic>.from(participant));
              }
            } catch (e) {
              print('❌ 참여자 파싱 오류: $e, 참여자: $participant');
            }
          }
        } else {
          // participants가 비어있을 경우 participantNameList에서 기본 정보 생성
          print('⚠️ participants 리스트가 비어있음, participantNameList에서 기본 정보 생성');
          for (int i = 0; i < participantNameList.length; i++) {
            final name = participantNameList[i];
            parsedParticipants.add({
              'userId': i + 1, // 임시 ID
              'userName': name,
              'name': name,
              'profileImage': '',
              'avatar': '',
            });
          }
        }

        // 현재 사용자가 참여자 목록에 없으면 추가
        final hasCurrentUser = parsedParticipants.any((p) => p['userId'] == _currentUserId);
        if (!hasCurrentUser && _currentUserId > 0) {
          print('⚠️ 현재 사용자가 참여자 목록에 없음 - 추가');
          parsedParticipants.add({
            'userId': _currentUserId,
            'userName': userInfo?['userName'] ?? '나',
            'name': userInfo?['name'] ?? '나',
            'profileImage': userInfo?['profileImage'] ?? '',
            'avatar': userInfo?['avatar'] ?? '',
          });
        }

        print('🔍 파싱된 참여자 목록: $parsedParticipants');

        setState(() {
          _isGroupChat = roomRange == 'GROUP' || participantCount >= 3 || participantNameList.length >= 3;
          _roomName = roomDetails['roomName'] ?? widget.userName;
          _participantCount = parsedParticipants.length; // 실제 파싱된 참여자 수로 업데이트
          _participants = parsedParticipants;
          _roomNameController.text = _roomName; // 컨트롤러에 현재 이름 설정
        });

        print('✅ 채팅방 정보 로드 완료');
        print('✅ 그룹 채팅 여부: $_isGroupChat');
        print('✅ 참여자 수: $_participantCount');
        print('✅ 참여자 목록: ${_participants.map((p) => '${p['userName']} (ID: ${p['userId']})').toList()}');
      }
    } catch (e) {
      print('❌ 채팅방 정보 로드 실패: $e');
      
      // 오류 발생 시 기본값 설정
      if (mounted) {
        setState(() {
          _participantCount = 0;
          _participants = [];
          _roomNameController.text = _roomName; // 컨트롤러에도 기본값 설정
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // 채팅방 나가기 다이얼로그
  void _showLeaveDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Container(
          width: 358,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 358,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '이 채팅방에서 나가시겠어요?',
                            style: TextStyle(
                              color: const Color(0xFF202020),
                              fontSize: 18,
                              fontFamily: 'Pretendard',
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.72,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            child: Text(
                              '나간 후에는 이전 대화 내용은 볼 수 없어요',
                              style: TextStyle(
                                color: const Color(0xFF999999),
                                fontSize: 14,
                                fontFamily: 'Pretendard',
                                fontWeight: FontWeight.w300,
                                letterSpacing: -0.28,
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
                width: 358,
                height: 184,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.white),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 116,
                      height: 160,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage('assets/icons/Icon/chat/exit_room.png'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 358,
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: ShapeDecoration(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 147,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: ShapeDecoration(
                          color: const Color(0xFFDADADA),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              '취소',
                              style: TextStyle(
                                color: const Color(0xFFB6B6B6),
                                fontSize: 14,
                                fontFamily: 'Pretendard',
                                fontWeight: FontWeight.w300,
                                letterSpacing: -0.28,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    GestureDetector(
                      onTap: () async {
                        if (mounted && Navigator.canPop(context)) {
                          Navigator.pop(context);
                        }

                        final navigator = Navigator.of(context);

                        try {
                          // 즉시 화면 닫기
                          navigator.pop({
                            'action': 'leave_room',
                            'roomId': widget.roomId,
                            'success': true,
                          });
                          navigator.pop({
                            'action': 'leave_room',
                            'roomId': widget.roomId,
                            'success': true,
                          });

                          // 백그라운드에서 나가기 처리
                          ChatService.leaveGroupChat(widget.roomId, forceHttpApi: false)
                              .then((success) {
                                print('✅ 아이단 백그라운드 나가기 완료: $success');
                              })
                              .catchError((e) {
                                print('⚠️ 아이단 백그라운드 나가기 오류 (무시): $e');
                              });
                        } catch (e) {
                          print('❌ 채팅방 나가기 중 오류: $e');
                          SchedulerBinding.instance.addPostFrameCallback((_) {
                            try {
                              navigator.pop({
                                'action': 'leave_room',
                                'roomId': widget.roomId,
                                'success': false,
                                'error': e.toString(),
                              });
                              navigator.pop({
                                'action': 'leave_room',
                                'roomId': widget.roomId,
                                'success': false,
                                'error': e.toString(),
                              });
                            } catch (popError) {
                              print('❌ 예외 시 Navigator.pop 오류: $popError');
                            }
                          });
                        }
                      },
                      child: Container(
                        width: 147,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: ShapeDecoration(
                          color: const Color(0xFF5D9EFF),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              '나가기',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontFamily: 'Pretendard',
                                fontWeight: FontWeight.w300,
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
            ],
          ),
        ),
      ),
    );
  }

  // 친구 초대 화면으로 이동
  void _showInviteDialog() async {
    if (!_isGroupChat) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('1:1 채팅방에서는 친구를 초대할 수 없습니다.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    List<int> existingParticipantIds = _participants
        .map<int>((participant) => participant['userId'] as int? ?? 0)
        .where((id) => id > 0)
        .toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FriendListScreen(
          isInviteMode: true,
          roomId: widget.roomId,
          existingParticipantIds: existingParticipantIds,
        ),
      ),
    ).then((result) async {
      if (result != null && result is Map<String, dynamic>) {
        final action = result['action'];
        if (action == 'invite_friends' && result['success'] == true) {
          final List<int> invitedIds = List<int>.from(result['invitedIds'] ?? []);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${invitedIds.length}명의 친구를 초대했습니다.'),
              backgroundColor: Colors.green,
            ),
          );
          // 초대 후 참여자 목록 새로고침
          print('🎉 초대 완료 후 참여자 목록 새로고침');
          await _refreshRoomInfo();
        }
      }
    });
  }

    // 채팅방 이름 업데이트
  Future<void> _updateRoomName() async {
    final newName = _roomNameController.text.trim();
    
    if (newName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('채팅방 이름을 입력해 주세요.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (newName == _roomName) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('기존 이름과 동일합니다.'),
          backgroundColor: Colors.grey,
        ),
      );
      return;
    }

    try {
      // 로딩 표시
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Text('채팅방 이름을 변경하는 중...'),
            ],
          ),
          backgroundColor: const Color(0xFF3A88F4),
          duration: Duration(seconds: 3),
        ),
      );

      // API 호출
      final result = await ChatService.updateRoomName(
        roomId: widget.roomId,
        name: newName,
      );

      if (result != null && result['success'] == true) {
        // 성공 시 화면 업데이트
        setState(() {
          _roomName = newName;
        });

        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('채팅방 이름이 변경되었습니다.'),
            backgroundColor: Colors.green,
          ),
        );

        // 채팅 목록 새로고침을 위해 결과 전달
        Navigator.pop(context, {
          'action': 'update_room_name',
          'roomId': widget.roomId,
          'newName': newName,
          'success': true,
        });
      } else {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('채팅방 이름 변경에 실패했습니다.'),
            backgroundColor: Colors.red,
          ),
        );
        
        // 실패 시 원래 이름으로 되돌리기
        setState(() {
          _roomNameController.text = _roomName;
        });
      }
    } catch (e) {
      print('❌ 채팅방 이름 변경 오류: $e');
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('채팅방 이름 변경 중 오류가 발생했습니다.'),
          backgroundColor: Colors.red,
        ),
      );
      
      // 오류 시 원래 이름으로 되돌리기
      setState(() {
        _roomNameController.text = _roomName;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refreshRoomInfo,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                children: [


                  // 상단 헤더
                  Container(
                    width: 390,
                    height: 80,
                    child: Stack(
                      children: [
                        Positioned(
                          left: 155,
                          top: 30,
                          child: Text(
                            _roomName.isNotEmpty ? _roomName : widget.userName,
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                              fontFamily: 'Pretendard-Bold',
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.32,
                            ),
                          ),
                        ),
                        Positioned(
                          left: 16,
                          top: 30,
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              width: 34,
                              height: 34,
                              child: Image.asset(
                                'assets/icons/Icon/chat/뒤로가기.png',
                                width: 24,
                                height: 24,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) => Icon(
                                  Icons.arrow_back_ios,
                                  color: Colors.black,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  // 채팅방 이름 섹션
                  Container(
                    width: double.infinity,
                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          height: 54,
                          child: Stack(
                            children: [
                              Positioned(
                                left: 16,
                                top: 18,
                                child: Row(
                                  children: [
                                    Text(
                                      '채팅방 이름',
                                      style: TextStyle(
                                        color: const Color(0xFF202020),
                                        fontSize: 16,
                                        fontFamily: 'Pretendard-Bold',
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: -0.32,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      '7/20',
                                      style: TextStyle(
                                        color: const Color(0xFFC4C4C4),
                                        fontSize: 12,
                                        fontFamily: 'Pretendard-Light',
                                        fontWeight: FontWeight.w300,
                                        letterSpacing: -0.24,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Positioned(
                                right: 16,
                                top: 12,
                                child: GestureDetector(
                                  onTap: _updateRoomName,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: ShapeDecoration(
                                      color: const Color(0xFFE7ECF6),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    child: Text(
                                      '편집하기',
                                      style: TextStyle(
                                        color: const Color(0xFF001F55),
                                        fontSize: 12,
                                        fontFamily: 'Pretendard-Medium',
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: -0.24,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: _roomNameController,
                                          maxLength: 20,
                                          onChanged: (value) {
                                            setState(() {}); // 글자 수 카운터 업데이트
                                          },
                                          style: TextStyle(
                                            color: const Color(0xFF202020),
                                            fontSize: 18,
                                            fontFamily: 'Pretendard-Bold',
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: -0.72,
                                          ),
                                          decoration: InputDecoration(
                                            border: InputBorder.none,
                                            enabledBorder: InputBorder.none,
                                            focusedBorder: InputBorder.none,
                                            counterText: '',
                                            contentPadding: EdgeInsets.zero,
                                            isDense: true,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        '${_roomNameController.text.length}/20',
                                        style: TextStyle(
                                          color: const Color(0xFFC4C4C4),
                                          fontSize: 11,
                                          fontFamily: 'Pretendard-Light',
                                          fontWeight: FontWeight.w300,
                                          letterSpacing: -0.22,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    width: double.infinity,
                                    height: 2,
                                    color: const Color(0xFF3A88F4),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '채팅방의 목적에 맞는 제목을 설정해 주세요',
                                    style: TextStyle(
                                      color: const Color(0xFFC4C4C4),
                                      fontSize: 11,
                                      fontFamily: 'Pretendard-Light',
                                      fontWeight: FontWeight.w300,
                                      letterSpacing: -0.22,
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

                  // 구분선
                  Container(
                    width: 390,
                    height: 6,
                    color: const Color(0xFFF5F5F5),
                  ),

                  // 참여 중인 멤버 섹션
                  Container(
                    width: double.infinity,
                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          height: 54,
                          child: Stack(
                            children: [
                              Positioned(
                                left: 16,
                                top: 16,
                                child: Row(
                                  children: [
                                    Text(
                                      '참여 중인 멤버',
                                      style: TextStyle(
                                        color: const Color(0xFF202020),
                                        fontSize: 16,
                                        fontFamily: 'Pretendard-Bold',
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: -0.32,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '$_participantCount',
                                      style: TextStyle(
                                        color: const Color(0xFF3A88F4),
                                        fontSize: 18,
                                        fontFamily: 'Pretendard-Bold',
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: -0.72,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (_isGroupChat)
                                Positioned(
                                  right: 16,
                                  top: 12,
                                  child: GestureDetector(
                                    onTap: _showInviteDialog,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      decoration: ShapeDecoration(
                                        color: const Color(0xFFE7ECF6),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      child: Text(
                                        '멤버 초대하기',
                                        style: TextStyle(
                                          color: const Color(0xFF001F55),
                                          fontSize: 12,
                                          fontFamily: 'Pretendard-Medium',
                                          fontWeight: FontWeight.w500,
                                          letterSpacing: -0.24,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: _buildParticipantList(),
                        ),
                      ],
                    ),
                  ),

                  // 구분선
                  Container(
                    width: 390,
                    height: 6,
                    color: const Color(0xFFF5F5F5),
                  ),

                  // 설정 섹션
                  Container(
                    width: double.infinity,
                    child: Column(
                      children: [
                        // 알림 설정
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              Container(
                                width: 16,
                                height: 16,
                                child: Image.asset(
                                  'assets/icons/Icon/chat/알림.png',
                                  width: 16,
                                  height: 16,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(
                                      Icons.notifications,
                                      color: const Color(0xFF999999),
                                      size: 16,
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '이 채팅방의 소리 알림 설정',
                                style: TextStyle(
                                  color: const Color(0xFF999999),
                                  fontSize: 12,
                                  fontFamily: 'Pretendard-Light',
                                  fontWeight: FontWeight.w300,
                                  letterSpacing: -0.24,
                                ),
                              ),
                              const Spacer(),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _isNotificationEnabled = !_isNotificationEnabled;
                                  });
                                },
                                child: Container(
                                  width: 52,
                                  height: 24,
                                  child: Stack(
                                    children: [
                                      Positioned(
                                        left: 2,
                                        top: 0,
                                        child: Container(
                                          width: 50,
                                          height: 24,
                                          decoration: ShapeDecoration(
                                            color: _isNotificationEnabled 
                                                ? const Color(0xFF10CB86)
                                                : const Color(0xFFE0E0E0),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                          ),
                                        ),
                                      ),
                                      AnimatedPositioned(
                                        duration: const Duration(milliseconds: 200),
                                        curve: Curves.easeInOut,
                                        left: _isNotificationEnabled ? 30 : 4,
                                        top: 2,
                                        child: Container(
                                          width: 20,
                                          height: 20,
                                          decoration: ShapeDecoration(
                                            color: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                            shadows: [
                                              BoxShadow(
                                                color: Color(0x38000000),
                                                blurRadius: 3,
                                                offset: Offset(3, 3),
                                                spreadRadius: 0,
                                              )
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
                        ),
                        // 나가기 버튼
                        Container(
                          width: double.infinity,
                          height: 48,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: GestureDetector(
                            onTap: _showLeaveDialog,
                            child: Row(
                              children: [
                                Container(
                                  width: 16,
                                  height: 16,
                                  child: Image.asset(
                                    'assets/icons/Icon/chat/채팅방에서_나가기.png',
                                    width: 16,
                                    height: 16,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Icon(
                                        Icons.exit_to_app,
                                        color: const Color(0xFF999999),
                                        size: 16,
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '이 채팅방에서 나가기',
                                  style: TextStyle(
                                    color: const Color(0xFF999999),
                                    fontSize: 12,
                                    fontFamily: 'Pretendard-Light',
                                    fontWeight: FontWeight.w300,
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
          ),
    );
  }

  Widget _buildParticipantList() {
    if (_participants.isEmpty) {
      return Container(
        height: 80,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isLoading) ...[
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(height: 8),
                Text(
                  '참여자 정보를 불러오는 중...',
                  style: TextStyle(
                    color: const Color(0xFF999999),
                    fontSize: 12,
                    fontFamily: 'Pretendard-Light',
                  ),
                ),
              ] else ...[
                Text(
                  '참여자 정보를 불러올 수 없습니다',
                  style: TextStyle(
                    color: const Color(0xFF999999),
                    fontSize: 12,
                    fontFamily: 'Pretendard-Light',
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _refreshRoomInfo,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE7ECF6),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '새로고침',
                      style: TextStyle(
                        color: const Color(0xFF001F55),
                        fontSize: 11,
                        fontFamily: 'Pretendard-Medium',
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _participants.map((participant) {
        final isMe = participant['userId'] == _currentUserId;
        final userName = participant['userName'] ?? participant['name'] ?? '알 수 없음';
        final profileImage = participant['profileImageUrl'] ?? participant['profileImage'] ?? participant['avatar'] ?? '';
        
        return Container(
          width: 50,
          child: Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: ShapeDecoration(
                  image: profileImage.isNotEmpty
                      ? DecorationImage(
                          image: CachedNetworkImageProvider(
                            profileImage.startsWith('http') 
                                ? profileImage 
                                : 'https://littlebank-dev.s3.ap-northeast-2.amazonaws.com/$profileImage',
                          ),
                          fit: BoxFit.cover,
                        )
                      : DecorationImage(
                          image: AssetImage('assets/icons/my/default_profile.png'),
                          fit: BoxFit.cover,
                        ),
                  shape: OvalBorder(),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isMe) ...[
                    Container(
                      width: 14,
                      height: 14,
                      decoration: ShapeDecoration(
                        color: const Color(0xFFFFD27F),
                        shape: OvalBorder(),
                      ),
                      child: Center(
                        child: Text(
                          '나',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontFamily: 'Pretendard-Light',
                            fontWeight: FontWeight.w300,
                            letterSpacing: -0.16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                  Flexible(
                    child: Text(
                      userName.length > 6 ? '${userName.substring(0, 6)}...' : userName,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: const Color(0xFF202020),
                        fontSize: 11,
                        fontFamily: 'Pretendard-Light',
                        fontWeight: FontWeight.w300,
                        letterSpacing: -0.22,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
} 