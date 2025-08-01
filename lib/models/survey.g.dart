// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'survey.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SurveyImpl _$$SurveyImplFromJson(Map<String, dynamic> json) => _$SurveyImpl(
  surveyId: (json['surveyId'] as num).toInt(),
  choice: json['choice'] as String?,
  question: json['question'] as String,
  optionA: json['optionA'] as String,
  optionB: json['optionB'] as String,
  optionC: json['optionC'] as String,
  voteA: (json['voteA'] as num).toInt(),
  voteB: (json['voteB'] as num).toInt(),
  voteC: (json['voteC'] as num).toInt(),
  percentA: (json['percentA'] as num).toInt(),
  percentB: (json['percentB'] as num).toInt(),
  percentC: (json['percentC'] as num).toInt(),
);

Map<String, dynamic> _$$SurveyImplToJson(_$SurveyImpl instance) =>
    <String, dynamic>{
      'surveyId': instance.surveyId,
      'choice': instance.choice,
      'question': instance.question,
      'optionA': instance.optionA,
      'optionB': instance.optionB,
      'optionC': instance.optionC,
      'voteA': instance.voteA,
      'voteB': instance.voteB,
      'voteC': instance.voteC,
      'percentA': instance.percentA,
      'percentB': instance.percentB,
      'percentC': instance.percentC,
    };

_$SurveyJoinRequestImpl _$$SurveyJoinRequestImplFromJson(
  Map<String, dynamic> json,
) => _$SurveyJoinRequestImpl(choice: json['choice'] as String);

Map<String, dynamic> _$$SurveyJoinRequestImplToJson(
  _$SurveyJoinRequestImpl instance,
) => <String, dynamic>{'choice': instance.choice};
