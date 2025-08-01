import 'package:freezed_annotation/freezed_annotation.dart';

part 'survey.freezed.dart';
part 'survey.g.dart';

@freezed
class Survey with _$Survey {
  const factory Survey({
    required int surveyId,
    String? choice, // 사용자가 선택한 옵션 (A, B, C)
    required String question,
    required String optionA,
    required String optionB,
    required String optionC,
    required int voteA,
    required int voteB,
    required int voteC,
    required int percentA,
    required int percentB,
    required int percentC,
  }) = _Survey;

  factory Survey.fromJson(Map<String, dynamic> json) => _$SurveyFromJson(json);
}

@freezed
class SurveyJoinRequest with _$SurveyJoinRequest {
  const factory SurveyJoinRequest({
    required String choice,
  }) = _SurveyJoinRequest;

  factory SurveyJoinRequest.fromJson(Map<String, dynamic> json) => 
      _$SurveyJoinRequestFromJson(json);
} 