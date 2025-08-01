// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'chat_message.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

ChatMessage _$ChatMessageFromJson(Map<String, dynamic> json) {
  return _ChatMessage.fromJson(json);
}

/// @nodoc
mixin _$ChatMessage {
  int? get messageId => throw _privateConstructorUsedError;
  int? get roomId => throw _privateConstructorUsedError;
  String get content => throw _privateConstructorUsedError;
  int? get senderUserId => throw _privateConstructorUsedError;
  String get senderName => throw _privateConstructorUsedError;
  String? get senderProfileImageUrl => throw _privateConstructorUsedError;
  @JsonKey(name: 'timestamp')
  String get time => throw _privateConstructorUsedError;
  MessageType get messageType => throw _privateConstructorUsedError;
  bool get isRead => throw _privateConstructorUsedError;
  String? get filePath => throw _privateConstructorUsedError;
  String? get thumbnailPath => throw _privateConstructorUsedError;
  String? get mediaUrl => throw _privateConstructorUsedError;
  String? get createdAt => throw _privateConstructorUsedError;
  Map<String, dynamic>? get missionData =>
      throw _privateConstructorUsedError; // 새로운 친구 관련 필드들
  String? get displayIdx => throw _privateConstructorUsedError;
  bool? get isFriend => throw _privateConstructorUsedError;
  String? get customName => throw _privateConstructorUsedError;
  bool? get isBestFriend => throw _privateConstructorUsedError;
  bool? get isBlocked =>
      throw _privateConstructorUsedError; // 새로운 API 명세에 따른 필드
  int get readCount => throw _privateConstructorUsedError;

  /// Serializes this ChatMessage to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ChatMessage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ChatMessageCopyWith<ChatMessage> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ChatMessageCopyWith<$Res> {
  factory $ChatMessageCopyWith(
    ChatMessage value,
    $Res Function(ChatMessage) then,
  ) = _$ChatMessageCopyWithImpl<$Res, ChatMessage>;
  @useResult
  $Res call({
    int? messageId,
    int? roomId,
    String content,
    int? senderUserId,
    String senderName,
    String? senderProfileImageUrl,
    @JsonKey(name: 'timestamp') String time,
    MessageType messageType,
    bool isRead,
    String? filePath,
    String? thumbnailPath,
    String? mediaUrl,
    String? createdAt,
    Map<String, dynamic>? missionData,
    String? displayIdx,
    bool? isFriend,
    String? customName,
    bool? isBestFriend,
    bool? isBlocked,
    int readCount,
  });
}

/// @nodoc
class _$ChatMessageCopyWithImpl<$Res, $Val extends ChatMessage>
    implements $ChatMessageCopyWith<$Res> {
  _$ChatMessageCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ChatMessage
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? messageId = freezed,
    Object? roomId = freezed,
    Object? content = null,
    Object? senderUserId = freezed,
    Object? senderName = null,
    Object? senderProfileImageUrl = freezed,
    Object? time = null,
    Object? messageType = null,
    Object? isRead = null,
    Object? filePath = freezed,
    Object? thumbnailPath = freezed,
    Object? mediaUrl = freezed,
    Object? createdAt = freezed,
    Object? missionData = freezed,
    Object? displayIdx = freezed,
    Object? isFriend = freezed,
    Object? customName = freezed,
    Object? isBestFriend = freezed,
    Object? isBlocked = freezed,
    Object? readCount = null,
  }) {
    return _then(
      _value.copyWith(
            messageId:
                freezed == messageId
                    ? _value.messageId
                    : messageId // ignore: cast_nullable_to_non_nullable
                        as int?,
            roomId:
                freezed == roomId
                    ? _value.roomId
                    : roomId // ignore: cast_nullable_to_non_nullable
                        as int?,
            content:
                null == content
                    ? _value.content
                    : content // ignore: cast_nullable_to_non_nullable
                        as String,
            senderUserId:
                freezed == senderUserId
                    ? _value.senderUserId
                    : senderUserId // ignore: cast_nullable_to_non_nullable
                        as int?,
            senderName:
                null == senderName
                    ? _value.senderName
                    : senderName // ignore: cast_nullable_to_non_nullable
                        as String,
            senderProfileImageUrl:
                freezed == senderProfileImageUrl
                    ? _value.senderProfileImageUrl
                    : senderProfileImageUrl // ignore: cast_nullable_to_non_nullable
                        as String?,
            time:
                null == time
                    ? _value.time
                    : time // ignore: cast_nullable_to_non_nullable
                        as String,
            messageType:
                null == messageType
                    ? _value.messageType
                    : messageType // ignore: cast_nullable_to_non_nullable
                        as MessageType,
            isRead:
                null == isRead
                    ? _value.isRead
                    : isRead // ignore: cast_nullable_to_non_nullable
                        as bool,
            filePath:
                freezed == filePath
                    ? _value.filePath
                    : filePath // ignore: cast_nullable_to_non_nullable
                        as String?,
            thumbnailPath:
                freezed == thumbnailPath
                    ? _value.thumbnailPath
                    : thumbnailPath // ignore: cast_nullable_to_non_nullable
                        as String?,
            mediaUrl:
                freezed == mediaUrl
                    ? _value.mediaUrl
                    : mediaUrl // ignore: cast_nullable_to_non_nullable
                        as String?,
            createdAt:
                freezed == createdAt
                    ? _value.createdAt
                    : createdAt // ignore: cast_nullable_to_non_nullable
                        as String?,
            missionData:
                freezed == missionData
                    ? _value.missionData
                    : missionData // ignore: cast_nullable_to_non_nullable
                        as Map<String, dynamic>?,
            displayIdx:
                freezed == displayIdx
                    ? _value.displayIdx
                    : displayIdx // ignore: cast_nullable_to_non_nullable
                        as String?,
            isFriend:
                freezed == isFriend
                    ? _value.isFriend
                    : isFriend // ignore: cast_nullable_to_non_nullable
                        as bool?,
            customName:
                freezed == customName
                    ? _value.customName
                    : customName // ignore: cast_nullable_to_non_nullable
                        as String?,
            isBestFriend:
                freezed == isBestFriend
                    ? _value.isBestFriend
                    : isBestFriend // ignore: cast_nullable_to_non_nullable
                        as bool?,
            isBlocked:
                freezed == isBlocked
                    ? _value.isBlocked
                    : isBlocked // ignore: cast_nullable_to_non_nullable
                        as bool?,
            readCount:
                null == readCount
                    ? _value.readCount
                    : readCount // ignore: cast_nullable_to_non_nullable
                        as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ChatMessageImplCopyWith<$Res>
    implements $ChatMessageCopyWith<$Res> {
  factory _$$ChatMessageImplCopyWith(
    _$ChatMessageImpl value,
    $Res Function(_$ChatMessageImpl) then,
  ) = __$$ChatMessageImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int? messageId,
    int? roomId,
    String content,
    int? senderUserId,
    String senderName,
    String? senderProfileImageUrl,
    @JsonKey(name: 'timestamp') String time,
    MessageType messageType,
    bool isRead,
    String? filePath,
    String? thumbnailPath,
    String? mediaUrl,
    String? createdAt,
    Map<String, dynamic>? missionData,
    String? displayIdx,
    bool? isFriend,
    String? customName,
    bool? isBestFriend,
    bool? isBlocked,
    int readCount,
  });
}

/// @nodoc
class __$$ChatMessageImplCopyWithImpl<$Res>
    extends _$ChatMessageCopyWithImpl<$Res, _$ChatMessageImpl>
    implements _$$ChatMessageImplCopyWith<$Res> {
  __$$ChatMessageImplCopyWithImpl(
    _$ChatMessageImpl _value,
    $Res Function(_$ChatMessageImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ChatMessage
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? messageId = freezed,
    Object? roomId = freezed,
    Object? content = null,
    Object? senderUserId = freezed,
    Object? senderName = null,
    Object? senderProfileImageUrl = freezed,
    Object? time = null,
    Object? messageType = null,
    Object? isRead = null,
    Object? filePath = freezed,
    Object? thumbnailPath = freezed,
    Object? mediaUrl = freezed,
    Object? createdAt = freezed,
    Object? missionData = freezed,
    Object? displayIdx = freezed,
    Object? isFriend = freezed,
    Object? customName = freezed,
    Object? isBestFriend = freezed,
    Object? isBlocked = freezed,
    Object? readCount = null,
  }) {
    return _then(
      _$ChatMessageImpl(
        messageId:
            freezed == messageId
                ? _value.messageId
                : messageId // ignore: cast_nullable_to_non_nullable
                    as int?,
        roomId:
            freezed == roomId
                ? _value.roomId
                : roomId // ignore: cast_nullable_to_non_nullable
                    as int?,
        content:
            null == content
                ? _value.content
                : content // ignore: cast_nullable_to_non_nullable
                    as String,
        senderUserId:
            freezed == senderUserId
                ? _value.senderUserId
                : senderUserId // ignore: cast_nullable_to_non_nullable
                    as int?,
        senderName:
            null == senderName
                ? _value.senderName
                : senderName // ignore: cast_nullable_to_non_nullable
                    as String,
        senderProfileImageUrl:
            freezed == senderProfileImageUrl
                ? _value.senderProfileImageUrl
                : senderProfileImageUrl // ignore: cast_nullable_to_non_nullable
                    as String?,
        time:
            null == time
                ? _value.time
                : time // ignore: cast_nullable_to_non_nullable
                    as String,
        messageType:
            null == messageType
                ? _value.messageType
                : messageType // ignore: cast_nullable_to_non_nullable
                    as MessageType,
        isRead:
            null == isRead
                ? _value.isRead
                : isRead // ignore: cast_nullable_to_non_nullable
                    as bool,
        filePath:
            freezed == filePath
                ? _value.filePath
                : filePath // ignore: cast_nullable_to_non_nullable
                    as String?,
        thumbnailPath:
            freezed == thumbnailPath
                ? _value.thumbnailPath
                : thumbnailPath // ignore: cast_nullable_to_non_nullable
                    as String?,
        mediaUrl:
            freezed == mediaUrl
                ? _value.mediaUrl
                : mediaUrl // ignore: cast_nullable_to_non_nullable
                    as String?,
        createdAt:
            freezed == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                    as String?,
        missionData:
            freezed == missionData
                ? _value._missionData
                : missionData // ignore: cast_nullable_to_non_nullable
                    as Map<String, dynamic>?,
        displayIdx:
            freezed == displayIdx
                ? _value.displayIdx
                : displayIdx // ignore: cast_nullable_to_non_nullable
                    as String?,
        isFriend:
            freezed == isFriend
                ? _value.isFriend
                : isFriend // ignore: cast_nullable_to_non_nullable
                    as bool?,
        customName:
            freezed == customName
                ? _value.customName
                : customName // ignore: cast_nullable_to_non_nullable
                    as String?,
        isBestFriend:
            freezed == isBestFriend
                ? _value.isBestFriend
                : isBestFriend // ignore: cast_nullable_to_non_nullable
                    as bool?,
        isBlocked:
            freezed == isBlocked
                ? _value.isBlocked
                : isBlocked // ignore: cast_nullable_to_non_nullable
                    as bool?,
        readCount:
            null == readCount
                ? _value.readCount
                : readCount // ignore: cast_nullable_to_non_nullable
                    as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ChatMessageImpl implements _ChatMessage {
  const _$ChatMessageImpl({
    this.messageId,
    this.roomId,
    this.content = '',
    required this.senderUserId,
    this.senderName = '',
    this.senderProfileImageUrl,
    @JsonKey(name: 'timestamp') this.time = '',
    this.messageType = MessageType.text,
    this.isRead = false,
    this.filePath,
    this.thumbnailPath,
    this.mediaUrl,
    this.createdAt,
    final Map<String, dynamic>? missionData,
    this.displayIdx,
    this.isFriend,
    this.customName,
    this.isBestFriend,
    this.isBlocked,
    this.readCount = 0,
  }) : _missionData = missionData;

  factory _$ChatMessageImpl.fromJson(Map<String, dynamic> json) =>
      _$$ChatMessageImplFromJson(json);

  @override
  final int? messageId;
  @override
  final int? roomId;
  @override
  @JsonKey()
  final String content;
  @override
  final int? senderUserId;
  @override
  @JsonKey()
  final String senderName;
  @override
  final String? senderProfileImageUrl;
  @override
  @JsonKey(name: 'timestamp')
  final String time;
  @override
  @JsonKey()
  final MessageType messageType;
  @override
  @JsonKey()
  final bool isRead;
  @override
  final String? filePath;
  @override
  final String? thumbnailPath;
  @override
  final String? mediaUrl;
  @override
  final String? createdAt;
  final Map<String, dynamic>? _missionData;
  @override
  Map<String, dynamic>? get missionData {
    final value = _missionData;
    if (value == null) return null;
    if (_missionData is EqualUnmodifiableMapView) return _missionData;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  // 새로운 친구 관련 필드들
  @override
  final String? displayIdx;
  @override
  final bool? isFriend;
  @override
  final String? customName;
  @override
  final bool? isBestFriend;
  @override
  final bool? isBlocked;
  // 새로운 API 명세에 따른 필드
  @override
  @JsonKey()
  final int readCount;

  @override
  String toString() {
    return 'ChatMessage(messageId: $messageId, roomId: $roomId, content: $content, senderUserId: $senderUserId, senderName: $senderName, senderProfileImageUrl: $senderProfileImageUrl, time: $time, messageType: $messageType, isRead: $isRead, filePath: $filePath, thumbnailPath: $thumbnailPath, mediaUrl: $mediaUrl, createdAt: $createdAt, missionData: $missionData, displayIdx: $displayIdx, isFriend: $isFriend, customName: $customName, isBestFriend: $isBestFriend, isBlocked: $isBlocked, readCount: $readCount)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ChatMessageImpl &&
            (identical(other.messageId, messageId) ||
                other.messageId == messageId) &&
            (identical(other.roomId, roomId) || other.roomId == roomId) &&
            (identical(other.content, content) || other.content == content) &&
            (identical(other.senderUserId, senderUserId) ||
                other.senderUserId == senderUserId) &&
            (identical(other.senderName, senderName) ||
                other.senderName == senderName) &&
            (identical(other.senderProfileImageUrl, senderProfileImageUrl) ||
                other.senderProfileImageUrl == senderProfileImageUrl) &&
            (identical(other.time, time) || other.time == time) &&
            (identical(other.messageType, messageType) ||
                other.messageType == messageType) &&
            (identical(other.isRead, isRead) || other.isRead == isRead) &&
            (identical(other.filePath, filePath) ||
                other.filePath == filePath) &&
            (identical(other.thumbnailPath, thumbnailPath) ||
                other.thumbnailPath == thumbnailPath) &&
            (identical(other.mediaUrl, mediaUrl) ||
                other.mediaUrl == mediaUrl) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            const DeepCollectionEquality().equals(
              other._missionData,
              _missionData,
            ) &&
            (identical(other.displayIdx, displayIdx) ||
                other.displayIdx == displayIdx) &&
            (identical(other.isFriend, isFriend) ||
                other.isFriend == isFriend) &&
            (identical(other.customName, customName) ||
                other.customName == customName) &&
            (identical(other.isBestFriend, isBestFriend) ||
                other.isBestFriend == isBestFriend) &&
            (identical(other.isBlocked, isBlocked) ||
                other.isBlocked == isBlocked) &&
            (identical(other.readCount, readCount) ||
                other.readCount == readCount));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
    runtimeType,
    messageId,
    roomId,
    content,
    senderUserId,
    senderName,
    senderProfileImageUrl,
    time,
    messageType,
    isRead,
    filePath,
    thumbnailPath,
    mediaUrl,
    createdAt,
    const DeepCollectionEquality().hash(_missionData),
    displayIdx,
    isFriend,
    customName,
    isBestFriend,
    isBlocked,
    readCount,
  ]);

  /// Create a copy of ChatMessage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ChatMessageImplCopyWith<_$ChatMessageImpl> get copyWith =>
      __$$ChatMessageImplCopyWithImpl<_$ChatMessageImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ChatMessageImplToJson(this);
  }
}

abstract class _ChatMessage implements ChatMessage {
  const factory _ChatMessage({
    final int? messageId,
    final int? roomId,
    final String content,
    required final int? senderUserId,
    final String senderName,
    final String? senderProfileImageUrl,
    @JsonKey(name: 'timestamp') final String time,
    final MessageType messageType,
    final bool isRead,
    final String? filePath,
    final String? thumbnailPath,
    final String? mediaUrl,
    final String? createdAt,
    final Map<String, dynamic>? missionData,
    final String? displayIdx,
    final bool? isFriend,
    final String? customName,
    final bool? isBestFriend,
    final bool? isBlocked,
    final int readCount,
  }) = _$ChatMessageImpl;

  factory _ChatMessage.fromJson(Map<String, dynamic> json) =
      _$ChatMessageImpl.fromJson;

  @override
  int? get messageId;
  @override
  int? get roomId;
  @override
  String get content;
  @override
  int? get senderUserId;
  @override
  String get senderName;
  @override
  String? get senderProfileImageUrl;
  @override
  @JsonKey(name: 'timestamp')
  String get time;
  @override
  MessageType get messageType;
  @override
  bool get isRead;
  @override
  String? get filePath;
  @override
  String? get thumbnailPath;
  @override
  String? get mediaUrl;
  @override
  String? get createdAt;
  @override
  Map<String, dynamic>? get missionData; // 새로운 친구 관련 필드들
  @override
  String? get displayIdx;
  @override
  bool? get isFriend;
  @override
  String? get customName;
  @override
  bool? get isBestFriend;
  @override
  bool? get isBlocked; // 새로운 API 명세에 따른 필드
  @override
  int get readCount;

  /// Create a copy of ChatMessage
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ChatMessageImplCopyWith<_$ChatMessageImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
