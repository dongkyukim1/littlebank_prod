import 'package:flutter/material.dart';
import '../../models/chat_message.dart';
import '../../services/auth_service.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ChatMessageItem extends StatelessWidget {
  final ChatMessage message;
  final bool isMyMessage;

  const ChatMessageItem({
    super.key,
    required this.message,
    required this.isMyMessage,
  });

  String _getImageUrl(String? url) {
    if (url == null || url.isEmpty) {
      print('ChatMessageItem - 프로필 이미지 URL이 비어있음');
      return '';
    }

    print('ChatMessageItem - 원본 프로필 이미지 URL: $url');

    // 이미 완전한 URL인 경우
    if (url.startsWith('http')) {
      print('ChatMessageItem - HTTP로 시작하는 URL 사용');
      return url;
    }

    // API 서버 URL 사용 (이미지 경로가 images/로 시작하는 경우)
    if (url.startsWith('images/')) {
      final fullUrl = 'http://3.34.52.239:8080/$url';
      print('ChatMessageItem - API 서버 URL 구성: $fullUrl');
      return fullUrl;
    }

    print('ChatMessageItem - 기본 이미지 URL 사용');
    // 기본값으로 API 서버 URL 사용
    return 'http://3.34.52.239:8080/images/origin/defailt/%E1%84%80%E1%85%B5%E1%84%87%E1%85%A9%E1%86%AB%E1%84%8B%E1%85%B5%E1%84%86%E1%85%B5%E1%84%8C%E1%85%B5.png';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            isMyMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMyMessage) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFE6E6E6),
              ),
              child: ClipOval(
                child:
                    message.senderProfileImageUrl != null &&
                            message.senderProfileImageUrl!.isNotEmpty
                        ? CachedNetworkImage(
                          imageUrl: _getImageUrl(message.senderProfileImageUrl),
                          fit: BoxFit.cover,
                          placeholder:
                              (context, url) => const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF4A80F0),
                                ),
                              ),
                          errorWidget: (context, url, error) {
                            print('프로필 이미지 로드 오류: $error, URL: $url');
                            print('원본 URL: ${message.senderProfileImageUrl}');
                            return const Icon(
                              Icons.person,
                              color: Color(0xFF999999),
                              size: 20,
                            );
                          },
                        )
                        : const Icon(
                          Icons.person,
                          color: Color(0xFF999999),
                          size: 20,
                        ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMyMessage
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
              children: [
                if (!isMyMessage)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      message.senderName,
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'Pretendard-Medium',
                        color: Color(0xFF666666),
                      ),
                    ),
                  ),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.7,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isMyMessage ? const Color(0xFF4A80F0) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border:
                          !isMyMessage
                              ? Border.all(color: const Color(0xFFE6E6E6))
                              : null,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(child: _buildMessageContent(context)),
                        const SizedBox(height: 4),
                        Text(
                          message.time,
                          style: TextStyle(
                            fontSize: 10,
                            fontFamily: 'Pretendard-Regular',
                            color:
                                isMyMessage
                                    ? Colors.white70
                                    : const Color(0xFF999999),
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
    );
  }

  Widget _buildMessageContent(BuildContext context) {
    switch (message.messageType) {
      case MessageType.text:
        return Text(
          message.content,
          style: TextStyle(
            color: isMyMessage ? Colors.white : const Color(0xFF202020),
            fontSize: 14,
            fontFamily: 'Pretendard-Regular',
          ),
        );
      case MessageType.image:
        return FutureBuilder<Map<String, String>>(
          future: AuthService.getImageHeaders(),
          builder: (context, snapshot) {
            return ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
                maxHeight: MediaQuery.of(context).size.width * 0.7,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: _getImageUrl(message.content),
                  httpHeaders: snapshot.data ?? {},
                  fit: BoxFit.cover,
                  placeholder:
                      (context, url) => Container(
                        color: const Color(0xFFF5F5F5),
                        child: const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF4A80F0),
                          ),
                        ),
                      ),
                  errorWidget: (context, error, stackTrace) {
                    print('이미지 로드 오류: $error');
                    return Container(
                      color: const Color(0xFFF5F5F5),
                      child: const Icon(
                        Icons.error_outline,
                        color: Color(0xFF999999),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        );
      case MessageType.video:
        return FutureBuilder<Map<String, String>>(
          future: AuthService.getImageHeaders(),
          builder: (context, snapshot) {
            return ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
                maxHeight: MediaQuery.of(context).size.width * 0.7,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (message.thumbnailPath != null)
                      CachedNetworkImage(
                        imageUrl: _getImageUrl(message.thumbnailPath!),
                        httpHeaders: snapshot.data ?? {},
                        fit: BoxFit.cover,
                        placeholder:
                            (context, url) => Container(
                              color: const Color(0xFFF5F5F5),
                              child: const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF4A80F0),
                                ),
                              ),
                            ),
                        errorWidget: (context, error, stackTrace) {
                          return Container(
                            color: const Color(0xFFF5F5F5),
                            child: const Icon(
                              Icons.video_library,
                              color: Color(0xFF999999),
                            ),
                          );
                        },
                      )
                    else
                      Container(
                        color: const Color(0xFFF5F5F5),
                        child: const Icon(
                          Icons.video_library,
                          color: Color(0xFF999999),
                        ),
                      ),
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.play_arrow,
                        size: 32,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      case MessageType.missionCard:
        return _buildMissionCard(context);
      default:
        return Text(
          message.content,
          style: TextStyle(
            color: isMyMessage ? Colors.white : const Color(0xFF202020),
            fontSize: 14,
            fontFamily: 'Pretendard-Regular',
          ),
        );
    }
  }

  Widget _buildMissionCard(BuildContext context) {
    if (message.missionData == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE6E6E6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message.missionData!['type'] ?? '',
            style: const TextStyle(
              fontSize: 14,
              fontFamily: 'Pretendard-Medium',
              color: Color(0xFF666666),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message.missionData!['title'] ?? '',
            style: const TextStyle(
              fontSize: 16,
              fontFamily: 'Pretendard-Bold',
              color: Color(0xFF202020),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '리워드',
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: 'Pretendard-Regular',
                      color: Color(0xFF666666),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message.missionData!['reward'] ?? '',
                    style: const TextStyle(
                      fontSize: 14,
                      fontFamily: 'Pretendard-Bold',
                      color: Color(0xFF202020),
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '기간',
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: 'Pretendard-Regular',
                      color: Color(0xFF666666),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message.missionData!['period'] ?? '',
                    style: const TextStyle(
                      fontSize: 14,
                      fontFamily: 'Pretendard-Bold',
                      color: Color(0xFF202020),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value:
                (double.tryParse(
                      (message.missionData!['progress'] ?? '0%').replaceAll(
                        '%',
                        '',
                      ),
                    ) ??
                    0) /
                100,
            backgroundColor: const Color(0xFFE6E6E6),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4A80F0)),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                message.missionData!['progress'] ?? '0%',
                style: const TextStyle(
                  fontSize: 12,
                  fontFamily: 'Pretendard-Medium',
                  color: Color(0xFF4A80F0),
                ),
              ),
              Text(
                message.missionData!['timeRecorded'] ?? '',
                style: const TextStyle(
                  fontSize: 12,
                  fontFamily: 'Pretendard-Regular',
                  color: Color(0xFF999999),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
