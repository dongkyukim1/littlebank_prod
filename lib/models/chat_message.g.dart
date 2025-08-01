// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ChatMessageImpl _$$ChatMessageImplFromJson(Map<String, dynamic> json) =>
    _$ChatMessageImpl(
      messageId: (json['messageId'] as num?)?.toInt(),
      roomId: (json['roomId'] as num?)?.toInt(),
      content: json['content'] as String? ?? '',
      senderUserId: (json['senderUserId'] as num?)?.toInt(),
      senderName: json['senderName'] as String? ?? '',
      senderProfileImageUrl: json['senderProfileImageUrl'] as String?,
      time: json['timestamp'] as String? ?? '',
      messageType:
          $enumDecodeNullable(_$MessageTypeEnumMap, json['messageType']) ??
          MessageType.text,
      isRead: json['isRead'] as bool? ?? false,
      filePath: json['filePath'] as String?,
      thumbnailPath: json['thumbnailPath'] as String?,
      mediaUrl: json['mediaUrl'] as String?,
      createdAt: json['createdAt'] as String?,
      missionData: json['missionData'] as Map<String, dynamic>?,
      displayIdx: json['displayIdx'] as String?,
      isFriend: json['isFriend'] as bool?,
      customName: json['customName'] as String?,
      isBestFriend: json['isBestFriend'] as bool?,
      isBlocked: json['isBlocked'] as bool?,
      readCount: (json['readCount'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$$ChatMessageImplToJson(_$ChatMessageImpl instance) =>
    <String, dynamic>{
      'messageId': instance.messageId,
      'roomId': instance.roomId,
      'content': instance.content,
      'senderUserId': instance.senderUserId,
      'senderName': instance.senderName,
      'senderProfileImageUrl': instance.senderProfileImageUrl,
      'timestamp': instance.time,
      'messageType': _$MessageTypeEnumMap[instance.messageType]!,
      'isRead': instance.isRead,
      'filePath': instance.filePath,
      'thumbnailPath': instance.thumbnailPath,
      'mediaUrl': instance.mediaUrl,
      'createdAt': instance.createdAt,
      'missionData': instance.missionData,
      'displayIdx': instance.displayIdx,
      'isFriend': instance.isFriend,
      'customName': instance.customName,
      'isBestFriend': instance.isBestFriend,
      'isBlocked': instance.isBlocked,
      'readCount': instance.readCount,
    };

const _$MessageTypeEnumMap = {
  MessageType.text: 'TEXT',
  MessageType.image: 'IMAGE',
  MessageType.video: 'VIDEO',
  MessageType.missionCard: 'MISSION_CARD',
};
