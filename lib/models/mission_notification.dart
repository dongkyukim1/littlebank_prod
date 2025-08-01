import 'package:freezed_annotation/freezed_annotation.dart';

part 'mission_notification.freezed.dart';
part 'mission_notification.g.dart';

@freezed
class MissionNotification with _$MissionNotification {
  const factory MissionNotification({
    required int missionId,
    required String title,
    required String description,
    required String createdAt,
    required String status,
  }) = _MissionNotification;

  factory MissionNotification.fromJson(Map<String, dynamic> json) =>
      _$MissionNotificationFromJson(json);
}
