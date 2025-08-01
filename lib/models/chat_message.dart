import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_message.freezed.dart';
part 'chat_message.g.dart';

enum MessageType {
  @JsonValue('TEXT')
  text,
  @JsonValue('IMAGE')
  image,
  @JsonValue('VIDEO')
  video,
  @JsonValue('MISSION_CARD')
  missionCard,
  @JsonValue('SYSTEM')
  system,
}

@freezed
class ChatMessage with _$ChatMessage {
  const factory ChatMessage({
    int? messageId,
    int? roomId,
    @Default('') String content,
    required int? senderUserId,
    @Default('') String senderName,
    String? senderProfileImageUrl,
    @Default('') @JsonKey(name: 'timestamp') String time,
    @Default(MessageType.text) MessageType messageType,
    @Default(false) bool isRead,
    String? filePath,
    String? thumbnailPath,
    String? mediaUrl,
    String? createdAt,
    Map<String, dynamic>? missionData,
    // 새로운 친구 관련 필드들
    String? displayIdx,
    bool? isFriend,
    String? customName,
    bool? isBestFriend,
    bool? isBlocked,
    // 새로운 API 명세에 따른 필드
    @Default(0) int readCount, // 메시지를 읽지 않은 사람 수
  }) = _ChatMessage;

  factory ChatMessage.fromJson(Map<String, dynamic> json) =>
      _$ChatMessageFromJson(json);
}
