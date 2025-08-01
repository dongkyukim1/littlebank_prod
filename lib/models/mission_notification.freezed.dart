// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'mission_notification.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

MissionNotification _$MissionNotificationFromJson(Map<String, dynamic> json) {
  return _MissionNotification.fromJson(json);
}

/// @nodoc
mixin _$MissionNotification {
  int get missionId => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  String get createdAt => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;

  /// Serializes this MissionNotification to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MissionNotification
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MissionNotificationCopyWith<MissionNotification> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MissionNotificationCopyWith<$Res> {
  factory $MissionNotificationCopyWith(
    MissionNotification value,
    $Res Function(MissionNotification) then,
  ) = _$MissionNotificationCopyWithImpl<$Res, MissionNotification>;
  @useResult
  $Res call({
    int missionId,
    String title,
    String description,
    String createdAt,
    String status,
  });
}

/// @nodoc
class _$MissionNotificationCopyWithImpl<$Res, $Val extends MissionNotification>
    implements $MissionNotificationCopyWith<$Res> {
  _$MissionNotificationCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MissionNotification
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? missionId = null,
    Object? title = null,
    Object? description = null,
    Object? createdAt = null,
    Object? status = null,
  }) {
    return _then(
      _value.copyWith(
            missionId:
                null == missionId
                    ? _value.missionId
                    : missionId // ignore: cast_nullable_to_non_nullable
                        as int,
            title:
                null == title
                    ? _value.title
                    : title // ignore: cast_nullable_to_non_nullable
                        as String,
            description:
                null == description
                    ? _value.description
                    : description // ignore: cast_nullable_to_non_nullable
                        as String,
            createdAt:
                null == createdAt
                    ? _value.createdAt
                    : createdAt // ignore: cast_nullable_to_non_nullable
                        as String,
            status:
                null == status
                    ? _value.status
                    : status // ignore: cast_nullable_to_non_nullable
                        as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$MissionNotificationImplCopyWith<$Res>
    implements $MissionNotificationCopyWith<$Res> {
  factory _$$MissionNotificationImplCopyWith(
    _$MissionNotificationImpl value,
    $Res Function(_$MissionNotificationImpl) then,
  ) = __$$MissionNotificationImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int missionId,
    String title,
    String description,
    String createdAt,
    String status,
  });
}

/// @nodoc
class __$$MissionNotificationImplCopyWithImpl<$Res>
    extends _$MissionNotificationCopyWithImpl<$Res, _$MissionNotificationImpl>
    implements _$$MissionNotificationImplCopyWith<$Res> {
  __$$MissionNotificationImplCopyWithImpl(
    _$MissionNotificationImpl _value,
    $Res Function(_$MissionNotificationImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MissionNotification
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? missionId = null,
    Object? title = null,
    Object? description = null,
    Object? createdAt = null,
    Object? status = null,
  }) {
    return _then(
      _$MissionNotificationImpl(
        missionId:
            null == missionId
                ? _value.missionId
                : missionId // ignore: cast_nullable_to_non_nullable
                    as int,
        title:
            null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                    as String,
        description:
            null == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                    as String,
        createdAt:
            null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                    as String,
        status:
            null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                    as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$MissionNotificationImpl implements _MissionNotification {
  const _$MissionNotificationImpl({
    required this.missionId,
    required this.title,
    required this.description,
    required this.createdAt,
    required this.status,
  });

  factory _$MissionNotificationImpl.fromJson(Map<String, dynamic> json) =>
      _$$MissionNotificationImplFromJson(json);

  @override
  final int missionId;
  @override
  final String title;
  @override
  final String description;
  @override
  final String createdAt;
  @override
  final String status;

  @override
  String toString() {
    return 'MissionNotification(missionId: $missionId, title: $title, description: $description, createdAt: $createdAt, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MissionNotificationImpl &&
            (identical(other.missionId, missionId) ||
                other.missionId == missionId) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.status, status) || other.status == status));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    missionId,
    title,
    description,
    createdAt,
    status,
  );

  /// Create a copy of MissionNotification
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MissionNotificationImplCopyWith<_$MissionNotificationImpl> get copyWith =>
      __$$MissionNotificationImplCopyWithImpl<_$MissionNotificationImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$MissionNotificationImplToJson(this);
  }
}

abstract class _MissionNotification implements MissionNotification {
  const factory _MissionNotification({
    required final int missionId,
    required final String title,
    required final String description,
    required final String createdAt,
    required final String status,
  }) = _$MissionNotificationImpl;

  factory _MissionNotification.fromJson(Map<String, dynamic> json) =
      _$MissionNotificationImpl.fromJson;

  @override
  int get missionId;
  @override
  String get title;
  @override
  String get description;
  @override
  String get createdAt;
  @override
  String get status;

  /// Create a copy of MissionNotification
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MissionNotificationImplCopyWith<_$MissionNotificationImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
