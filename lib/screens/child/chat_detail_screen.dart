import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import 'dart:async';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class ChatDetailScreen extends StatefulWidget {
  final String userName;
  final String avatar;

  const ChatDetailScreen({
    super.key,
    required this.userName,
    required this.avatar,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  bool _showQuickReplies = false;
  String _selectedQuickReply = ""; // 기본 선택 효과 제거
  
  // 이미지 선택 관련
  final ImagePicker _picker = ImagePicker();
  
  // 비디오 플레이어 관련
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  
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
    
    _timerText = '수락까지 ${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    
    // missionData의 timeRecorded 값도 함께 업데이트
    for (var message in _messages) {
      if (message.messageType == MessageType.missionCard && message.missionData != null) {
        message.missionData!['timeRecorded'] = _timerText;
      }
    }
  }

  void _addSampleMessages() {
    _messages.add(
      ChatMessage(
        text: "안녕하세요, ${widget.userName}님!",
        isMe: false,
        time: "09:30",
        messageType: MessageType.text,
      ),
    );

    _messages.add(
      ChatMessage(
        text: "이번 주 미션을 보내드립니다",
        isMe: false,
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
        text: "이번 주 수학은 꼭 마스터해야 합니다",
        isMe: false,
        time: "12:30",
        messageType: MessageType.text,
      ),
    );

    _messages.add(
      ChatMessage(
        text: "열심히 해볼게요!",
        isMe: true,
        time: "12:30",
        messageType: MessageType.text,
      ),
    );

    _messages.add(
      ChatMessage(
        text: "이번 주 숙제는 꼭 미리지 않길 바란다~",
        isMe: false,
        time: "12:30",
        messageType: MessageType.text,
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
                    color: AppColors.accentColor,
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
                  icon: Image.asset(
                    'assets/icons/Icon/채팅보내기/Regular.png',
                    width: 24,
                    height: 24,
                    color: AppColors.accentColor,
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
            color: isSelected ? const Color(0xFF3A88F4) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: !isSelected
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
                color: isSelected ? Colors.white : const Color(0xFF3A88F4),
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
                widget.userName, // "엄마" 또는 다른 발신자 이름
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
                  color: message.isMe ? const Color(0xFF89DA8D) : Colors.white,
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

                      // 수학까지 시간 버튼
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

                      // 조건을 바꿔주세요 버튼
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          "조건을 바꿔주세요",
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
                    _buildQuickReplyButton("열심히 해볼게요!", Colors.white),
                    _buildQuickReplyButton("응원이 필요해요!", Colors.white),
                    _buildQuickReplyButton("감사합니다!", Colors.white),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // 미디어 옵션 표시하는 메서드 추가
  void _showMediaOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              width: double.infinity,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.3,
              ),
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "미디어 첨부",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Pretendard',
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 사진 옵션
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                            _pickImage();
                          },
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE9F1FF),
                                  borderRadius: BorderRadius.circular(50),
                                ),
                                child: const Icon(
                                  Icons.photo,
                                  color: Color(0xFF3A88F4),
                                  size: 30,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                "사진",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontFamily: 'Pretendard',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      // 동영상 옵션
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                            _pickVideo();
                          },
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE9F1FF),
                                  borderRadius: BorderRadius.circular(50),
                                ),
                                child: const Icon(
                                  Icons.videocam,
                                  color: Color(0xFF3A88F4),
                                  size: 30,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                "동영상",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontFamily: 'Pretendard',
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
          ),
        );
      },
    );
  }

  // 갤러리에서 이미지 선택하기
  Future<void> _pickImage() async {
    try {
      final XFile? pickedImage = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      
      if (pickedImage != null) {
        setState(() {
          _messages.add(
            ChatMessage(
              text: "이미지",
              isMe: true,
              time: _getCurrentTime(),
              messageType: MessageType.image,
              filePath: pickedImage.path,
            ),
          );
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('이미지 선택 중 오류가 발생했습니다: $e')),
      );
    }
  }

  // 갤러리에서 비디오 선택하기
  Future<void> _pickVideo() async {
    try {
      final XFile? pickedVideo = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 5),
      );
      
      if (pickedVideo != null) {
        // 비디오 썸네일 생성
        final thumbnailPath = await _generateVideoThumbnail(pickedVideo.path);
        
        setState(() {
          _messages.add(
            ChatMessage(
              text: "비디오",
              isMe: true,
              time: _getCurrentTime(),
              messageType: MessageType.video,
              filePath: pickedVideo.path,
              thumbnailPath: thumbnailPath,
            ),
          );
        });
        
        // 성공 메시지 표시
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('비디오가 성공적으로 첨부되었습니다'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // 오류 상세 메시지 표시
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('비디오 선택 중 오류가 발생했습니다: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      print('비디오 선택 오류: $e'); // 콘솔에 상세 오류 출력
    }
  }
  
  // 비디오 썸네일 생성
  Future<String?> _generateVideoThumbnail(String videoPath) async {
    try {
      final thumbnailPath = await VideoThumbnail.thumbnailFile(
        video: videoPath,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 300,
        quality: 75,
      );
      return thumbnailPath;
    } catch (e) {
      print('썸네일 생성 오류: $e');
      return null;
    }
  }
  
  // 비디오 플레이어 초기화
  Future<void> _initializeVideoPlayer(String videoPath) async {
    _videoController = VideoPlayerController.file(File(videoPath));
    try {
      await _videoController!.initialize();
      setState(() {
        _isVideoInitialized = true;
      });
    } catch (e) {
      print('비디오 플레이어 초기화 오류: $e');
    }
  }
  
  // 비디오 재생/일시정지 토글
  void _toggleVideoPlayback() {
    if (_videoController != null) {
      if (_videoController!.value.isPlaying) {
        _videoController!.pause();
      } else {
        _videoController!.play();
      }
      setState(() {});
    }
  }

  // 이미지 메시지 빌더
  Widget _buildImageMessage(ChatMessage message) {
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
                widget.userName,
                style: const TextStyle(
                  fontSize: 16,
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF202020),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

          // 이미지와 시간
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            textDirection: message.isMe ? TextDirection.rtl : TextDirection.ltr,
            children: [
              // 이미지 컨테이너
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.65,
                  maxHeight: 200,
                ),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(message.isMe ? 16 : 0),
                      bottomRight: Radius.circular(message.isMe ? 0 : 16),
                    ),
                    color: message.isMe ? const Color(0xFF89DA8D) : Colors.white,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: message.filePath != null 
                    ? Image.file(
                        File(message.filePath!),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const SizedBox(
                            width: 150,
                            height: 150,
                            child: Center(
                              child: Icon(Icons.broken_image, size: 50, color: Colors.grey),
                            ),
                          );
                        },
                      )
                    : message.mediaUrl != null 
                      ? Image.asset(
                          message.mediaUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const SizedBox(
                              width: 150,
                              height: 150,
                              child: Center(
                                child: Icon(Icons.broken_image, size: 50, color: Colors.grey),
                              ),
                            );
                          },
                        )
                      : Container(
                          width: 150,
                          height: 150,
                          color: Colors.grey.shade200,
                        ),
                ),
              ),
              // 시간 표시 (이미지 옆)
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

  // 비디오 메시지 빌더
  Widget _buildVideoMessage(ChatMessage message) {
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
                widget.userName,
                style: const TextStyle(
                  fontSize: 16,
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF202020),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

          // 비디오 썸네일과 시간
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            textDirection: message.isMe ? TextDirection.rtl : TextDirection.ltr,
            children: [
              // 비디오 컨테이너
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.65,
                  maxHeight: 200,
                ),
                child: GestureDetector(
                  onTap: () {
                    // 비디오 전체 화면 재생
                    if (message.filePath != null) {
                      _showVideoFullScreen(message.filePath!);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('비디오 재생에 실패했습니다'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(message.isMe ? 16 : 0),
                        bottomRight: Radius.circular(message.isMe ? 0 : 16),
                      ),
                      color: message.isMe ? const Color(0xFF89DA8D) : Colors.white,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // 비디오 썸네일
                        message.thumbnailPath != null && File(message.thumbnailPath!).existsSync() 
                          ? Image.file(
                              File(message.thumbnailPath!),
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: 150,
                              errorBuilder: (context, error, stackTrace) {
                                print('썸네일 로드 오류: $error');
                                return Container(
                                  width: 150,
                                  height: 150,
                                  color: Colors.grey.shade200,
                                  child: Center(
                                    child: Icon(Icons.movie, size: 50, color: Colors.grey),
                                  ),
                                );
                              },
                            )
                          : message.filePath != null 
                            ? Container(
                                width: 150,
                                height: 150,
                                color: Colors.grey.shade200,
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.movie, size: 40, color: Colors.grey.shade600),
                                      const SizedBox(height: 4),
                                      const Text(
                                        '비디오',
                                        style: TextStyle(color: Colors.grey, fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : Container(
                                width: 150,
                                height: 150,
                                color: Colors.grey.shade200,
                              ),
                        
                        // 재생 아이콘
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.play_arrow,
                            size: 30,
                            color: Colors.white,
                          ),
                        ),
                        
                        // 비디오 표시기
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.videocam, color: Colors.white, size: 14),
                                SizedBox(width: 4),
                                Text(
                                  '비디오',
                                  style: TextStyle(color: Colors.white, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // 시간 표시 (비디오 옆)
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
  
  // 비디오 전체 화면 표시
  void _showVideoFullScreen(String videoPath) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => VideoPlayerScreen(videoPath: videoPath),
      ),
    );
  }
}

// 비디오 플레이어 화면
class VideoPlayerScreen extends StatefulWidget {
  final String videoPath;
  
  const VideoPlayerScreen({super.key, required this.videoPath});
  
  @override
  _VideoPlayerScreenState createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  
  @override
  void initState() {
    super.initState();
    _initVideoPlayer();
  }
  
  Future<void> _initVideoPlayer() async {
    _controller = VideoPlayerController.file(File(widget.videoPath));
    try {
      await _controller.initialize();
      _controller.play();
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      print('비디오 플레이어 초기화 오류: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('비디오를 재생할 수 없습니다: $e')),
      );
    }
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: _isInitialized
            ? AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // 비디오 플레이어
                    VideoPlayer(_controller),
                    
                    // 재생/일시정지 컨트롤
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          if (_controller.value.isPlaying) {
                            _controller.pause();
                          } else {
                            _controller.play();
                          }
                        });
                      },
                      child: Container(
                        color: Colors.transparent,
                        child: Center(
                          child: Icon(
                            _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                            size: 60.0,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : const CircularProgressIndicator(),
      ),
    );
  }
}

// 메시지 타입 정의
enum MessageType { text, missionCard, challengeCard, image, video }

class ChatMessage {
  final String text;
  final bool isMe;
  final String time;
  final MessageType messageType;
  final Map<String, String>? missionData;
  final String? mediaUrl;  // 이미지나 비디오 URL 저장 (예시 이미지용)
  final String? filePath;  // 디바이스에서 선택한 파일 경로
  final String? thumbnailPath; // 비디오 썸네일 경로

  ChatMessage({
    required this.text,
    required this.isMe,
    required this.time,
    required this.messageType,
    this.missionData,
    this.mediaUrl,
    this.filePath,
    this.thumbnailPath,
  });
}
