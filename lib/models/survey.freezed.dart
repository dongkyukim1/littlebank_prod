// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'survey.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Survey _$SurveyFromJson(Map<String, dynamic> json) {
  return _Survey.fromJson(json);
}

/// @nodoc
mixin _$Survey {
  int get surveyId => throw _privateConstructorUsedError;
  String? get choice =>
      throw _privateConstructorUsedError; // 사용자가 선택한 옵션 (A, B, C)
  String get question => throw _privateConstructorUsedError;
  String get optionA => throw _privateConstructorUsedError;
  String get optionB => throw _privateConstructorUsedError;
  String get optionC => throw _privateConstructorUsedError;
  int get voteA => throw _privateConstructorUsedError;
  int get voteB => throw _privateConstructorUsedError;
  int get voteC => throw _privateConstructorUsedError;
  int get percentA => throw _privateConstructorUsedError;
  int get percentB => throw _privateConstructorUsedError;
  int get percentC => throw _privateConstructorUsedError;

  /// Serializes this Survey to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Survey
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SurveyCopyWith<Survey> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SurveyCopyWith<$Res> {
  factory $SurveyCopyWith(Survey value, $Res Function(Survey) then) =
      _$SurveyCopyWithImpl<$Res, Survey>;
  @useResult
  $Res call({
    int surveyId,
    String? choice,
    String question,
    String optionA,
    String optionB,
    String optionC,
    int voteA,
    int voteB,
    int voteC,
    int percentA,
    int percentB,
    int percentC,
  });
}

/// @nodoc
class _$SurveyCopyWithImpl<$Res, $Val extends Survey>
    implements $SurveyCopyWith<$Res> {
  _$SurveyCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Survey
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? surveyId = null,
    Object? choice = freezed,
    Object? question = null,
    Object? optionA = null,
    Object? optionB = null,
    Object? optionC = null,
    Object? voteA = null,
    Object? voteB = null,
    Object? voteC = null,
    Object? percentA = null,
    Object? percentB = null,
    Object? percentC = null,
  }) {
    return _then(
      _value.copyWith(
            surveyId:
                null == surveyId
                    ? _value.surveyId
                    : surveyId // ignore: cast_nullable_to_non_nullable
                        as int,
            choice:
                freezed == choice
                    ? _value.choice
                    : choice // ignore: cast_nullable_to_non_nullable
                        as String?,
            question:
                null == question
                    ? _value.question
                    : question // ignore: cast_nullable_to_non_nullable
                        as String,
            optionA:
                null == optionA
                    ? _value.optionA
                    : optionA // ignore: cast_nullable_to_non_nullable
                        as String,
            optionB:
                null == optionB
                    ? _value.optionB
                    : optionB // ignore: cast_nullable_to_non_nullable
                        as String,
            optionC:
                null == optionC
                    ? _value.optionC
                    : optionC // ignore: cast_nullable_to_non_nullable
                        as String,
            voteA:
                null == voteA
                    ? _value.voteA
                    : voteA // ignore: cast_nullable_to_non_nullable
                        as int,
            voteB:
                null == voteB
                    ? _value.voteB
                    : voteB // ignore: cast_nullable_to_non_nullable
                        as int,
            voteC:
                null == voteC
                    ? _value.voteC
                    : voteC // ignore: cast_nullable_to_non_nullable
                        as int,
            percentA:
                null == percentA
                    ? _value.percentA
                    : percentA // ignore: cast_nullable_to_non_nullable
                        as int,
            percentB:
                null == percentB
                    ? _value.percentB
                    : percentB // ignore: cast_nullable_to_non_nullable
                        as int,
            percentC:
                null == percentC
                    ? _value.percentC
                    : percentC // ignore: cast_nullable_to_non_nullable
                        as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$SurveyImplCopyWith<$Res> implements $SurveyCopyWith<$Res> {
  factory _$$SurveyImplCopyWith(
    _$SurveyImpl value,
    $Res Function(_$SurveyImpl) then,
  ) = __$$SurveyImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int surveyId,
    String? choice,
    String question,
    String optionA,
    String optionB,
    String optionC,
    int voteA,
    int voteB,
    int voteC,
    int percentA,
    int percentB,
    int percentC,
  });
}

/// @nodoc
class __$$SurveyImplCopyWithImpl<$Res>
    extends _$SurveyCopyWithImpl<$Res, _$SurveyImpl>
    implements _$$SurveyImplCopyWith<$Res> {
  __$$SurveyImplCopyWithImpl(
    _$SurveyImpl _value,
    $Res Function(_$SurveyImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Survey
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? surveyId = null,
    Object? choice = freezed,
    Object? question = null,
    Object? optionA = null,
    Object? optionB = null,
    Object? optionC = null,
    Object? voteA = null,
    Object? voteB = null,
    Object? voteC = null,
    Object? percentA = null,
    Object? percentB = null,
    Object? percentC = null,
  }) {
    return _then(
      _$SurveyImpl(
        surveyId:
            null == surveyId
                ? _value.surveyId
                : surveyId // ignore: cast_nullable_to_non_nullable
                    as int,
        choice:
            freezed == choice
                ? _value.choice
                : choice // ignore: cast_nullable_to_non_nullable
                    as String?,
        question:
            null == question
                ? _value.question
                : question // ignore: cast_nullable_to_non_nullable
                    as String,
        optionA:
            null == optionA
                ? _value.optionA
                : optionA // ignore: cast_nullable_to_non_nullable
                    as String,
        optionB:
            null == optionB
                ? _value.optionB
                : optionB // ignore: cast_nullable_to_non_nullable
                    as String,
        optionC:
            null == optionC
                ? _value.optionC
                : optionC // ignore: cast_nullable_to_non_nullable
                    as String,
        voteA:
            null == voteA
                ? _value.voteA
                : voteA // ignore: cast_nullable_to_non_nullable
                    as int,
        voteB:
            null == voteB
                ? _value.voteB
                : voteB // ignore: cast_nullable_to_non_nullable
                    as int,
        voteC:
            null == voteC
                ? _value.voteC
                : voteC // ignore: cast_nullable_to_non_nullable
                    as int,
        percentA:
            null == percentA
                ? _value.percentA
                : percentA // ignore: cast_nullable_to_non_nullable
                    as int,
        percentB:
            null == percentB
                ? _value.percentB
                : percentB // ignore: cast_nullable_to_non_nullable
                    as int,
        percentC:
            null == percentC
                ? _value.percentC
                : percentC // ignore: cast_nullable_to_non_nullable
                    as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$SurveyImpl implements _Survey {
  const _$SurveyImpl({
    required this.surveyId,
    this.choice,
    required this.question,
    required this.optionA,
    required this.optionB,
    required this.optionC,
    required this.voteA,
    required this.voteB,
    required this.voteC,
    required this.percentA,
    required this.percentB,
    required this.percentC,
  });

  factory _$SurveyImpl.fromJson(Map<String, dynamic> json) =>
      _$$SurveyImplFromJson(json);

  @override
  final int surveyId;
  @override
  final String? choice;
  // 사용자가 선택한 옵션 (A, B, C)
  @override
  final String question;
  @override
  final String optionA;
  @override
  final String optionB;
  @override
  final String optionC;
  @override
  final int voteA;
  @override
  final int voteB;
  @override
  final int voteC;
  @override
  final int percentA;
  @override
  final int percentB;
  @override
  final int percentC;

  @override
  String toString() {
    return 'Survey(surveyId: $surveyId, choice: $choice, question: $question, optionA: $optionA, optionB: $optionB, optionC: $optionC, voteA: $voteA, voteB: $voteB, voteC: $voteC, percentA: $percentA, percentB: $percentB, percentC: $percentC)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SurveyImpl &&
            (identical(other.surveyId, surveyId) ||
                other.surveyId == surveyId) &&
            (identical(other.choice, choice) || other.choice == choice) &&
            (identical(other.question, question) ||
                other.question == question) &&
            (identical(other.optionA, optionA) || other.optionA == optionA) &&
            (identical(other.optionB, optionB) || other.optionB == optionB) &&
            (identical(other.optionC, optionC) || other.optionC == optionC) &&
            (identical(other.voteA, voteA) || other.voteA == voteA) &&
            (identical(other.voteB, voteB) || other.voteB == voteB) &&
            (identical(other.voteC, voteC) || other.voteC == voteC) &&
            (identical(other.percentA, percentA) ||
                other.percentA == percentA) &&
            (identical(other.percentB, percentB) ||
                other.percentB == percentB) &&
            (identical(other.percentC, percentC) ||
                other.percentC == percentC));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    surveyId,
    choice,
    question,
    optionA,
    optionB,
    optionC,
    voteA,
    voteB,
    voteC,
    percentA,
    percentB,
    percentC,
  );

  /// Create a copy of Survey
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SurveyImplCopyWith<_$SurveyImpl> get copyWith =>
      __$$SurveyImplCopyWithImpl<_$SurveyImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SurveyImplToJson(this);
  }
}

abstract class _Survey implements Survey {
  const factory _Survey({
    required final int surveyId,
    final String? choice,
    required final String question,
    required final String optionA,
    required final String optionB,
    required final String optionC,
    required final int voteA,
    required final int voteB,
    required final int voteC,
    required final int percentA,
    required final int percentB,
    required final int percentC,
  }) = _$SurveyImpl;

  factory _Survey.fromJson(Map<String, dynamic> json) = _$SurveyImpl.fromJson;

  @override
  int get surveyId;
  @override
  String? get choice; // 사용자가 선택한 옵션 (A, B, C)
  @override
  String get question;
  @override
  String get optionA;
  @override
  String get optionB;
  @override
  String get optionC;
  @override
  int get voteA;
  @override
  int get voteB;
  @override
  int get voteC;
  @override
  int get percentA;
  @override
  int get percentB;
  @override
  int get percentC;

  /// Create a copy of Survey
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SurveyImplCopyWith<_$SurveyImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

SurveyJoinRequest _$SurveyJoinRequestFromJson(Map<String, dynamic> json) {
  return _SurveyJoinRequest.fromJson(json);
}

/// @nodoc
mixin _$SurveyJoinRequest {
  String get choice => throw _privateConstructorUsedError;

  /// Serializes this SurveyJoinRequest to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SurveyJoinRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SurveyJoinRequestCopyWith<SurveyJoinRequest> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SurveyJoinRequestCopyWith<$Res> {
  factory $SurveyJoinRequestCopyWith(
    SurveyJoinRequest value,
    $Res Function(SurveyJoinRequest) then,
  ) = _$SurveyJoinRequestCopyWithImpl<$Res, SurveyJoinRequest>;
  @useResult
  $Res call({String choice});
}

/// @nodoc
class _$SurveyJoinRequestCopyWithImpl<$Res, $Val extends SurveyJoinRequest>
    implements $SurveyJoinRequestCopyWith<$Res> {
  _$SurveyJoinRequestCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SurveyJoinRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? choice = null}) {
    return _then(
      _value.copyWith(
            choice:
                null == choice
                    ? _value.choice
                    : choice // ignore: cast_nullable_to_non_nullable
                        as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$SurveyJoinRequestImplCopyWith<$Res>
    implements $SurveyJoinRequestCopyWith<$Res> {
  factory _$$SurveyJoinRequestImplCopyWith(
    _$SurveyJoinRequestImpl value,
    $Res Function(_$SurveyJoinRequestImpl) then,
  ) = __$$SurveyJoinRequestImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String choice});
}

/// @nodoc
class __$$SurveyJoinRequestImplCopyWithImpl<$Res>
    extends _$SurveyJoinRequestCopyWithImpl<$Res, _$SurveyJoinRequestImpl>
    implements _$$SurveyJoinRequestImplCopyWith<$Res> {
  __$$SurveyJoinRequestImplCopyWithImpl(
    _$SurveyJoinRequestImpl _value,
    $Res Function(_$SurveyJoinRequestImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SurveyJoinRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? choice = null}) {
    return _then(
      _$SurveyJoinRequestImpl(
        choice:
            null == choice
                ? _value.choice
                : choice // ignore: cast_nullable_to_non_nullable
                    as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$SurveyJoinRequestImpl implements _SurveyJoinRequest {
  const _$SurveyJoinRequestImpl({required this.choice});

  factory _$SurveyJoinRequestImpl.fromJson(Map<String, dynamic> json) =>
      _$$SurveyJoinRequestImplFromJson(json);

  @override
  final String choice;

  @override
  String toString() {
    return 'SurveyJoinRequest(choice: $choice)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SurveyJoinRequestImpl &&
            (identical(other.choice, choice) || other.choice == choice));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, choice);

  /// Create a copy of SurveyJoinRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SurveyJoinRequestImplCopyWith<_$SurveyJoinRequestImpl> get copyWith =>
      __$$SurveyJoinRequestImplCopyWithImpl<_$SurveyJoinRequestImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$SurveyJoinRequestImplToJson(this);
  }
}

abstract class _SurveyJoinRequest implements SurveyJoinRequest {
  const factory _SurveyJoinRequest({required final String choice}) =
      _$SurveyJoinRequestImpl;

  factory _SurveyJoinRequest.fromJson(Map<String, dynamic> json) =
      _$SurveyJoinRequestImpl.fromJson;

  @override
  String get choice;

  /// Create a copy of SurveyJoinRequest
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SurveyJoinRequestImplCopyWith<_$SurveyJoinRequestImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
