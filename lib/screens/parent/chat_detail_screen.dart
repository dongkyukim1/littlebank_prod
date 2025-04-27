import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

class ParentChatDetailScreen extends StatefulWidget {
  final String userName;
  final String avatar;

  const ParentChatDetailScreen({
    super.key,
    required this.userName,
    required this.avatar,
  });

  @override
  State<ParentChatDetailScreen> createState() => _ParentChatDetailScreenState();
}

class _ParentChatDetailScreenState extends State<ParentChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  bool _showQuickReplies = false;
  String _selectedQuickReply = ""; // 기본 선택 효과 제거

  // 이미지 선택 관련
  final ImagePicker _picker = ImagePicker();

  // 비디오 플레이어 관련
  VideoPlayerController? _videoController;
  final bool _isVideoInitialized = false;

  // 타이머 관련 변수
  Timer? _timer;
  Duration _timeRemaining = const Duration(hours: 7, minutes: 9, seconds: 39);
  String _timerText = '수락까지 07:09:39';

  @override
  void initState() {
    super.initState();
    // 초기 메시지 샘플 추가
    _addSampleMessages();
    // 타이머 시작
    _startTimer();
  }

  @override
  void dispose() {
    // 타이머 정리
    _timer?.cancel();
    super.dispose();
  }

  // 타이머 시작 메서드
  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_timeRemaining.inSeconds > 0) {
          _timeRemaining = _timeRemaining - const Duration(seconds: 1);
          _updateTimerText();
        } else {
          _timer?.cancel();
        }
      });
    });
  }

  // 타이머 텍스트 업데이트
  void _updateTimerText() {
    final hours = _timeRemaining.inHours;
    final minutes = _timeRemaining.inMinutes.remainder(60);
    final seconds = _timeRemaining.inSeconds.remainder(60);

    _timerText =
        '수락까지 ${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    // missionData의 timeRecorded 값도 함께 업데이트
    for (var message in _messages) {
      if (message.messageType == MessageType.missionCard &&
          message.missionData != null) {
        message.missionData!['timeRecorded'] = _timerText;
      }
    }
  }

  void _addSampleMessages() {
    // 부모님 앱에 맞는 메시지 샘플로 변경
    _messages.add(
      ChatMessage(
        text: "안녕하세요, ${widget.userName}님과의 대화입니다",
        isMe: false,
        time: "09:30",
        messageType: MessageType.text,
      ),
    );

    _messages.add(
      ChatMessage(
        text: "이번 주 수학 숙제를 잘 하고 있는지 확인하고 싶어요.",
        isMe: true,
        time: "12:30",
        messageType: MessageType.text,
      ),
    );

    // 미션 카드 메시지 추가
    _messages.add(
      ChatMessage(
        text: "",
        isMe: false,
        time: "12:30",
        messageType: MessageType.missionCard,
        missionData: {
          'type': '3월 셋째주 미션',
          'title': '수학 5단원까지 풀어오기',
          'reward': '30,000원',
          'period': '3.20 - 3.27',
          'progress': '70%',
          'timeRecorded': _timerText,
        },
      ),
    );

    _messages.add(
      ChatMessage(
        text: "작성해주신 미션을 보내드립니다",
        isMe: false,
        time: "12:30",
        messageType: MessageType.text,
      ),
    );

    _messages.add(
      ChatMessage(
        text: "네, 박뱅뱅이 열심히 할 수 있도록 독려해주세요!",
        isMe: true,
        time: "12:30",
        messageType: MessageType.text,
      ),
    );

    _messages.add(
      ChatMessage(
        text: "현재 진도는 58%까지 완료되었습니다.",
        isMe: false,
        time: "12:30",
        messageType: MessageType.text,
      ),
    );

    // 미션 완료 메시지 추가
    _messages.add(
      ChatMessage(
        text: "",
        isMe: false,
        time: "14:15",
        messageType: MessageType.missionComplete,
        missionData: {'type': '3월 셋째주 미션', 'reward': '30,000원'},
      ),
    );

    // 최신 메시지가 상대방이고 텍스트 메시지면 자동 응답 표시
    if (_messages.isNotEmpty && !_messages.last.isMe) {
      setState(() {
        _showQuickReplies = true;
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
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.blue.shade100,
              child: Text(widget.avatar, style: const TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: 10),
            Text(
              widget.userName,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // 채팅 메시지 영역
          Expanded(
            child: ListView.separated(
              reverse: true,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
              itemCount: _messages.length,
              // separatorBuilder를 사용하여 아이템 사이에 구분자 삽입
              separatorBuilder: (context, index) {
                // 실제 인덱스 계산 (reverse 때문에)
                final currentIndex = _messages.length - 1 - index;
                final nextIndex = _messages.length - 2 - index;

                // 마지막 아이템이거나 리스트에 메시지가 하나뿐인 경우
                if (nextIndex < 0 || _messages.isEmpty) {
                  return const SizedBox(height: 0);
                }

                // 현재 메시지와 다음 메시지의 발신자가 다른지 확인
                final currentMessage = _messages[currentIndex];
                final nextMessage = _messages[nextIndex];
                final isDifferentSender =
                    currentMessage.isMe != nextMessage.isMe;

                // 발신자가 다르면 24px, 같으면 12px 간격 적용
                return SizedBox(height: isDifferentSender ? 24.0 : 12.0);
              },
              itemBuilder: (context, index) {
                final reversedIndex = _messages.length - 1 - index;
                final message = _messages[reversedIndex];
                return _buildMessage(message);
              },
            ),
          ),

          // 구분선
          const Divider(height: 1),

          // 메시지 입력창
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.add_circle_outline,
                    color: const Color(0xFF146AFF), // 부모 앱 테마 색상으로 변경
                  ),
                  onPressed: () {
                    _showMediaOptions();
                  },
                ),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 0,
                    ),
                    height: 40, // 고정 높이 설정
                    decoration: ShapeDecoration(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        side: const BorderSide(
                          width: 1,
                          color: Color(0xFFCCCCCC),
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Center(
                      child: TextField(
                        controller: _messageController,
                        decoration: const InputDecoration(
                          hintText: '메시지를 입력해 주세요',
                          hintStyle: TextStyle(
                            color: Color(0xFF999999),
                            fontSize: 14,
                            fontFamily: 'Pretendard',
                            fontWeight: FontWeight.w300,
                            letterSpacing: -0.22,
                          ),
                          isDense: true,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        minLines: 1,
                        maxLines: 1,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.send,
                    color: const Color(0xFF146AFF), // 부모 앱 테마 색상으로 변경
                  ),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 빠른 응답 버튼 생성
  Widget _buildQuickReplyButton(String text, Color color) {
    final bool isSelected = _selectedQuickReply == text;

    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedQuickReply = text;
          });

          // 잠시 딜레이 후 메시지 전송 (시각적 피드백을 위해)
          Future.delayed(const Duration(milliseconds: 300), () {
            setState(() {
              _showQuickReplies = false;
              _messages.add(
                ChatMessage(
                  text: text,
                  isMe: true,
                  time: _getCurrentTime(),
                  messageType: MessageType.text,
                ),
              );
            });
          });
        },
        child: Container(
          width: 140,
          height: 45,
          decoration: BoxDecoration(
            color:
                isSelected
                    ? const Color(0xFF146AFF)
                    : Colors.white, // 부모 앱 테마 색상으로 변경
            borderRadius: BorderRadius.circular(8),
            border:
                !isSelected
                    ? Border.all(color: const Color(0xFFDDDDDD), width: 0.7)
                    : null,
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 15,
                fontFamily: 'Pretendard',
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                color:
                    isSelected
                        ? Colors.white
                        : const Color(0xFF146AFF), // 부모 앱 테마 색상으로 변경
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    setState(() {
      _messages.add(
        ChatMessage(
          text: _messageController.text,
          isMe: true,
          time: _getCurrentTime(),
          messageType: MessageType.text,
        ),
      );
      _showQuickReplies = false;
    });

    _messageController.clear();
  }

  String _getCurrentTime() {
    final now = DateTime.now();
    return "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
  }

  Widget _buildMessage(ChatMessage message) {
    if (message.messageType == MessageType.missionCard) {
      return _buildMissionCard(message);
    } else if (message.messageType == MessageType.image) {
      return _buildImageMessage(message);
    } else if (message.messageType == MessageType.video) {
      return _buildVideoMessage(message);
    } else if (message.messageType == MessageType.missionComplete) {
      return _buildMissionCompleteMessage(message);
    }

    return Align(
      alignment: message.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment:
            message.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // 발신자 이름 (상대방 메시지일 때만 표시)
          if (!message.isMe)
            Padding(
              padding: const EdgeInsets.only(left: 15, bottom: 2),
              child: Text(
                widget.userName, // 상대방 이름
                style: const TextStyle(
                  fontSize: 16,
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF202020),
                ),
              ),
            ),

          // 메시지와 시간
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            textDirection: message.isMe ? TextDirection.rtl : TextDirection.ltr,
            children: [
              // 메시지 박스
              Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.7,
                  minWidth: 80,
                ),
                margin: const EdgeInsets.symmetric(horizontal: 10),
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 20,
                ),
                decoration: BoxDecoration(
                  color:
                      message.isMe
                          ? const Color(0xFF146AFF)
                          : Colors.white, // 부모 앱 테마 색상으로 변경
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(message.isMe ? 16 : 0),
                    bottomRight: const Radius.circular(16),
                  ),
                ),
                child: Text(
                  message.text,
                  style: TextStyle(
                    color:
                        message.isMe ? Colors.white : const Color(0xFF666666),
                    fontSize: 14,
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w400,
                    height: 1.2,
                  ),
                ),
              ),
              // 시간 표시 (메시지 박스 옆)
              Padding(
                padding: const EdgeInsets.only(right: 8, left: 8),
                child: Text(
                  message.time,
                  style: const TextStyle(color: Colors.grey, fontSize: 10),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 미션 카드 위젯
  Widget _buildMissionCard(ChatMessage message) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 15, right: 15, bottom: 5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 발신자 이름
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                widget.userName,
                style: const TextStyle(
                  fontSize: 16,
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF202020),
                ),
              ),
            ),

            // 미션 카드와 시간
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // 미션 카드
                Container(
                  width: 236,
                  height: 325,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                      bottomLeft: Radius.circular(0),
                      bottomRight: Radius.circular(16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0x40000000),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.fromLTRB(28, 20, 28, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 상단 헤더
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF5D9EFF),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                message.missionData!['type']!,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF9E5D),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              "학원 미션",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),

                      // 미션 제목
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          message.missionData!['title']!,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),

                      // 보상금
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              "보상금",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                message.missionData!['reward']!,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF146AFF),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // 기간
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              "기간",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                message.missionData!['period']!,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // 목표 달성률
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              "목표 달성률",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                message.missionData!['progress']!,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Spacer
                      const Spacer(),

                      // 수락까지 시간 버튼
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4B8EFF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          message.missionData!['timeRecorded']!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontFamily: 'Pretendard',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // 미션 수정 버튼
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          "미션 수정하기",
                          style: TextStyle(
                            color: Color(0xFF001F55),
                            fontSize: 12,
                            fontFamily: 'Pretendard',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 시간 표시
                Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Text(
                    message.time,
                    style: const TextStyle(color: Colors.grey, fontSize: 10),
                  ),
                ),
              ],
            ),

            // 자동 응답 버튼 - 미션 카드 바로 아래에 위치
            if (_showQuickReplies &&
                message.messageType == MessageType.missionCard)
              Container(
                height: 55, // 높이 증가
                margin: const EdgeInsets.only(top: 15, right: 15), // 마진 증가
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildQuickReplyButton("좋은 미션이네요!", Colors.white),
                    _buildQuickReplyButton("미션을 수정할게요", Colors.white),
                    _buildQuickReplyButton("미션 완료되었나요?", Colors.white),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // 이미지 메시지 위젯 (간단하게 구현)
  Widget _buildImageMessage(ChatMessage message) {
    return Align(
      alignment: message.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 15, right: 15, bottom: 5),
        child: Column(
          crossAxisAlignment:
              message.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // 발신자 이름 (상대방 메시지일 때만 표시)
            if (!message.isMe)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  widget.userName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF202020),
                  ),
                ),
              ),

            // 이미지와 시간
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              textDirection:
                  message.isMe ? TextDirection.rtl : TextDirection.ltr,
              children: [
                // 이미지 컨테이너
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.6,
                  ),
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(message.mediaPath!),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

                // 시간 표시
                Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Text(
                    message.time,
                    style: const TextStyle(color: Colors.grey, fontSize: 10),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 비디오 메시지 위젯 (간단하게 구현)
  Widget _buildVideoMessage(ChatMessage message) {
    return Align(
      alignment: message.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 15, right: 15, bottom: 5),
        child: Column(
          crossAxisAlignment:
              message.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // 발신자 이름 (상대방 메시지일 때만 표시)
            if (!message.isMe)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  widget.userName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF202020),
                  ),
                ),
              ),

            // 비디오 썸네일과 시간
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              textDirection:
                  message.isMe ? TextDirection.rtl : TextDirection.ltr,
              children: [
                // 비디오 썸네일 컨테이너
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.6,
                  ),
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // 썸네일 이미지
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child:
                            message.thumbnailPath != null
                                ? Image.file(
                                  File(message.thumbnailPath!),
                                  fit: BoxFit.cover,
                                )
                                : Container(
                                  width: 200,
                                  height: 150,
                                  color: Colors.grey[300],
                                ),
                      ),
                      // 재생 아이콘
                      Icon(
                        Icons.play_circle_fill,
                        color: Colors.white.withOpacity(0.8),
                        size: 50,
                      ),
                    ],
                  ),
                ),

                // 시간 표시
                Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Text(
                    message.time,
                    style: const TextStyle(color: Colors.grey, fontSize: 10),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 미션 완료 메시지 위젯 추가
  Widget _buildMissionCompleteMessage(ChatMessage message) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 15, right: 15, bottom: 5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 발신자 이름
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                widget.userName,
                style: const TextStyle(
                  fontSize: 16,
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF202020),
                ),
              ),
            ),

            // 미션 완료 카드와 시간
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // 미션 완료 카드
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 20,
                  ),
                  margin: const EdgeInsets.only(right: 10),
                  decoration: ShapeDecoration(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                        bottomLeft: Radius.circular(0),
                        bottomRight: Radius.circular(24),
                      ),
                    ),
                    shadows: [
                      BoxShadow(
                        color: Color(0x3F000000),
                        blurRadius: 4,
                        offset: Offset(0, 4),
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: SizedBox(
                    width: 180,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: ShapeDecoration(
                                  color: const Color(0xFF5D9EFF),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text(
                                  message.missionData!['type']!,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontFamily: 'Pretendard',
                                    fontWeight: FontWeight.w300,
                                    letterSpacing: -0.24,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: 180,
                                child: Text.rich(
                                  TextSpan(
                                    children: [
                                      TextSpan(
                                        text: message.missionData!['reward']!,
                                        style: TextStyle(
                                          color: const Color(0xFF146AFF),
                                          fontSize: 18,
                                          fontFamily: 'Pretendard',
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: -0.72,
                                        ),
                                      ),
                                      TextSpan(
                                        text: ' 송금 완료',
                                        style: TextStyle(
                                          color: const Color(0xFF353535),
                                          fontSize: 18,
                                          fontFamily: 'Pretendard',
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: -0.72,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          width: 180,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 12,
                          ),
                          decoration: ShapeDecoration(
                            color: const Color(0xFF3A88F4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '용돈 봉투 확인하러 가기',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontFamily: 'Pretendard',
                                fontWeight: FontWeight.w500,
                                letterSpacing: -0.24,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 시간 표시
                Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Text(
                    message.time,
                    style: const TextStyle(color: Colors.grey, fontSize: 10),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 미디어 옵션 표시하는 메서드
  void _showMediaOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.photo_library,
                    color: Color(0xFF146AFF), // 부모 앱 테마 색상으로 변경
                  ),
                  title: const Text('사진 선택하기'),
                  onTap: () {
                    Navigator.pop(context);
                    // _pickImage(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.camera_alt,
                    color: Color(0xFF146AFF), // 부모 앱 테마 색상으로 변경
                  ),
                  title: const Text('사진 촬영하기'),
                  onTap: () {
                    Navigator.pop(context);
                    // _pickImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.videocam,
                    color: Color(0xFF146AFF), // 부모 앱 테마 색상으로 변경
                  ),
                  title: const Text('동영상 선택하기'),
                  onTap: () {
                    Navigator.pop(context);
                    // _pickVideo(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class ChatMessage {
  final String text;
  final bool isMe;
  final String time;
  final MessageType messageType;
  final Map<String, String>? missionData;
  final String? mediaPath;
  final String? thumbnailPath;

  ChatMessage({
    required this.text,
    required this.isMe,
    required this.time,
    required this.messageType,
    this.missionData,
    this.mediaPath,
    this.thumbnailPath,
  });
}

enum MessageType { text, image, video, missionCard, missionComplete }
