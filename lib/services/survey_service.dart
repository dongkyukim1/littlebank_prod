import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/survey.dart';
import 'auth_service.dart';

// Survey 서비스 클래스
class SurveyService {
  // API 기본 URL
  static String get baseUrl => 'http://3.34.52.239:8080';
  
  // 현재 진행 중인 설문 조회
  static Future<Survey> getCurrentSurvey() async {
    final url = Uri.parse('$baseUrl/api-user/survey/main');
    
    try {
      // 액세스 토큰 가져오기
      String? accessToken = await AuthService.getAccessToken();
      
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };
      
      // 토큰이 있으면 헤더에 추가
      if (accessToken != null && accessToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $accessToken';
      }
      
      final response = await http.get(
        url,
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return Survey.fromJson(responseData);
      } else {
        throw Exception('설문 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('설문 조회 중 오류 발생: $e');
    }
  }
  
  // 설문에 참여하기
  static Future<Survey> joinSurvey({
    required int surveyId,
    required String choice,
  }) async {
    final url = Uri.parse('$baseUrl/api-user/survey/join/$surveyId');
    
    try {
      // 액세스 토큰 가져오기
      String? accessToken = await AuthService.getAccessToken();
      
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };
      
      // 토큰이 있으면 헤더에 추가
      if (accessToken != null && accessToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $accessToken';
      }
      
      final body = jsonEncode({
        'choice': choice,
      });
      
      final response = await http.post(
        url,
        headers: headers,
        body: body,
      );
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return Survey.fromJson(responseData);
      } else {
        throw Exception('설문 참여 실패: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('설문 참여 중 오류 발생: $e');
    }
  }
}

// 현재 설문 Provider
final currentSurveyProvider = FutureProvider.autoDispose<Survey>((ref) async {
  return await SurveyService.getCurrentSurvey();
});

// 설문 참여 Provider
final joinSurveyProvider = FutureProvider.autoDispose.family<Survey, ({int surveyId, String choice})>((ref, params) async {
  final result = await SurveyService.joinSurvey(
    surveyId: params.surveyId,
    choice: params.choice,
  );
  
  // 설문 참여 후 현재 설문 정보 새로고침
  ref.invalidate(currentSurveyProvider);
  
  return result;
});

// 설문 상태 관리를 위한 StateNotifier
class SurveyNotifier extends StateNotifier<AsyncValue<Survey?>> {
  SurveyNotifier() : super(const AsyncValue.loading());
  
  // 현재 설문 조회
  Future<void> loadCurrentSurvey() async {
    state = const AsyncValue.loading();
    try {
      final survey = await SurveyService.getCurrentSurvey();
      state = AsyncValue.data(survey);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
  
  // 설문 참여
  Future<void> joinSurvey(int surveyId, String choice) async {
    try {
      state = const AsyncValue.loading();
      final survey = await SurveyService.joinSurvey(
        surveyId: surveyId,
        choice: choice,
      );
      state = AsyncValue.data(survey);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
}

// Survey StateNotifier Provider
final surveyNotifierProvider = StateNotifierProvider.autoDispose<SurveyNotifier, AsyncValue<Survey?>>((ref) {
  return SurveyNotifier();
}); 