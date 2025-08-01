// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mission_notification.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$MissionNotificationImpl _$$MissionNotificationImplFromJson(
  Map<String, dynamic> json,
) => _$MissionNotificationImpl(
  missionId: (json['missionId'] as num).toInt(),
  title: json['title'] as String,
  description: json['description'] as String,
  createdAt: json['createdAt'] as String,
  status: json['status'] as String,
);

Map<String, dynamic> _$$MissionNotificationImplToJson(
  _$MissionNotificationImpl instance,
) => <String, dynamic>{
  'missionId': instance.missionId,
  'title': instance.title,
  'description': instance.description,
  'createdAt': instance.createdAt,
  'status': instance.status,
};
