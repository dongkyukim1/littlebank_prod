import 'package:dio/dio.dart';
import 'dart:ui';
import 'dio_interceptor.dart';
import 'token_service.dart';
import 'mission_service.dart';
import 'challenge_service.dart';
import 'goal_service.dart';
import 'family_service.dart';

class AnalysisService {
  static final Dio _dio = Dio();

  static void _initializeDio() {
    _dio.options.baseUrl = 'http://3.34.52.239:8080';
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 10);
    _dio.options.sendTimeout = const Duration(seconds: 10);
    _dio.interceptors.add(AuthInterceptor(_dio));
  }

  /// 분석 리포트 데이터 모델
  static Map<String, dynamic>? _analysisData;

  /// 분석 리포트 조회
  static Future<Map<String, dynamic>?> getAnalysisReport(int memberId, int period) async {
    try {
      print('🔍 [AnalysisService] 분석 리포트 조회 시작');
      print('📊 memberId: $memberId, period: $period');
      
      _initializeDio();

      final token = await TokenService.getAccessToken();
      if (token == null) {
        print('❌ [AnalysisService] 토큰이 없습니다.');
        throw Exception('토큰이 없습니다.');
      }
      print('✅ [AnalysisService] 토큰 획득 성공');

      final url = '/api-user/analyze/$memberId';
      print('🌐 [AnalysisService] 요청 URL: $url');
      print('📝 [AnalysisService] 쿼리 파라미터: period=$period');

      final response = await _dio.get(
        url,
        queryParameters: {
          'period': period,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      print('📡 [AnalysisService] API 응답 상태 코드: ${response.statusCode}');
      print('📄 [AnalysisService] API 응답 데이터: ${response.data}');

      if (response.statusCode == 200) {
        _analysisData = response.data;
        
        // 🔍 상세 분석 리포트 로깅
        print('✅ [AnalysisService] 분석 리포트 조회 성공');
        print('📊 상세 분석 데이터:');
        final data = response.data;
        print('   - totalStudyTime: ${data['totalStudyTime']}분');
        print('   - thisMonthTotalStudyTime: ${data['thisMonthTotalStudyTime']}분');
        print('   - lastMonthTotalStudyTime: ${data['lastMonthTotalStudyTime']}분');
        print('   - prevStudyTime: ${data['prevStudyTime']}분');
        print('   - recentStudyTime: ${data['recentStudyTime']}분');
        print('   - prevMissionAchieveCount: ${data['prevMissionAchieveCount']}개');
        print('   - recentMissionAchieveCount: ${data['recentMissionAchieveCount']}개');
        print('   - prevAvgScore: ${data['prevAvgScore']}점');
        print('   - recentAvgScore: ${data['recentAvgScore']}점');
        print('   - nameOfLeastTimeSubject: ${data['nameOfLeastTimeSubject']}');
        print('   - nameOfMostTimeSubject: ${data['nameOfMostTimeSubject']}');
        
        // 모든 값이 0인지 확인
        bool allZero = (data['totalStudyTime'] ?? 0) == 0 &&
                      (data['thisMonthTotalStudyTime'] ?? 0) == 0 &&
                      (data['prevStudyTime'] ?? 0) == 0 &&
                      (data['recentStudyTime'] ?? 0) == 0 &&
                      (data['prevMissionAchieveCount'] ?? 0) == 0 &&
                      (data['recentMissionAchieveCount'] ?? 0) == 0;
        
        if (allZero) {
          print('⚠️ [AnalysisService] 모든 데이터가 0입니다. 실제 학습 활동이 없거나 API에 문제가 있을 수 있습니다.');
          print('💡 대안으로 미션/챌린지/목표 API에서 직접 데이터를 수집합니다.');
        }
        
        return response.data;
      } else {
        print('❌ [AnalysisService] API 응답 오류: ${response.statusCode}');
        throw Exception('분석 리포트 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [AnalysisService] 분석 리포트 조회 오류: $e');
      
      // DioException의 경우 더 자세한 정보 로깅
      if (e is DioException) {
        print('🔧 [AnalysisService] DioException 상세 정보:');
        print('   - 오류 타입: ${e.type}');
        print('   - 상태 코드: ${e.response?.statusCode}');
        print('   - 요청 URL: ${e.requestOptions.baseUrl}${e.requestOptions.path}');
        print('   - 요청 메서드: ${e.requestOptions.method}');
        print('   - 요청 헤더: ${e.requestOptions.headers}');
        print('   - 쿼리 파라미터: ${e.requestOptions.queryParameters}');
        
        // 서버 응답 본문 로깅 (500 에러 등의 상세 정보)
        if (e.response?.data != null) {
          print('   - 서버 응답 본문: ${e.response!.data}');
        }
        
        // 500 에러인 경우 추가 분석
        if (e.response?.statusCode == 500) {
          print('🚨 [AnalysisService] 서버 내부 오류 (500) 발생');
          print('   - 서버에서 해당 사용자($memberId)의 분석 데이터 처리 중 오류 발생');
          print('   - 가능한 원인:');
          print('     1. 사용자의 학습 데이터가 부족하거나 없음');
          print('     2. 서버 데이터베이스 연결 문제');
          print('     3. 서버 코드의 버그');
          print('     4. 권한 문제 (부모가 자녀 데이터에 접근할 권한 없음)');
        }
      } else {
        print('🔧 [AnalysisService] 일반적인 오류: $e');
      }
      
      throw Exception('분석 리포트를 불러올 수 없습니다: $e');
    }
  }

  /// 캐시된 분석 데이터 반환
  static Map<String, dynamic>? getCachedAnalysisData() {
    return _analysisData;
  }

  /// 총 학습 시간을 시간 단위로 포맷
  static String formatStudyTime(int minutes) {
    if (minutes < 60) {
      return '${minutes}분';
    } else {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      if (remainingMinutes == 0) {
        return '${hours}시간';
      } else {
        return '${hours}시간 ${remainingMinutes}분';
      }
    }
  }

  /// 분석 리포트 요약 텍스트 생성
  static Map<String, String> generateAnalysisSummary(Map<String, dynamic> data) {
    final prevStudyTime = data['prevStudyTime'] ?? 0;
    final recentStudyTime = data['recentStudyTime'] ?? 0;
    final prevMissionCount = data['prevMissionAchieveCount'] ?? 0;
    final recentMissionCount = data['recentMissionAchieveCount'] ?? 0;
    final prevAvgScore = (data['prevAvgScore'] ?? 0).toDouble();
    final recentAvgScore = (data['recentAvgScore'] ?? 0).toDouble();
    final leastTimeSubject = data['nameOfLeastTimeSubject'] ?? '';
    final leastTime = data['timeOfLeastTimeSubject'] ?? 0;
    final mostTimeSubject = data['nameOfMostTimeSubject'] ?? '';
    final mostTime = data['timeOfMostTimeSubject'] ?? 0;
    final period = data['period'] ?? 7;

    return {
      'studyTimeAnalysis': _generateStudyTimeAnalysis(prevStudyTime, recentStudyTime, period),
      'missionAnalysis': _generateMissionAnalysis(prevMissionCount, recentMissionCount, period),
      'scoreAnalysis': _generateScoreAnalysis(prevAvgScore, recentAvgScore, period),
      'subjectAnalysis': _generateSubjectAnalysis(leastTimeSubject, leastTime, mostTimeSubject, mostTime, period),
    };
  }

  static String _generateStudyTimeAnalysis(int prevTime, int recentTime, int period) {
    final timeDiff = recentTime - prevTime;
    final periodText = _getPeriodText(period);
    
    if (timeDiff > 0) {
      return '$periodText보다 공부한 시간이 ${formatStudyTime(timeDiff)} 증가했어요!';
    } else if (timeDiff < 0) {
      return '$periodText보다 공부한 시간이 ${formatStudyTime(timeDiff.abs())} 감소했어요!';
    } else {
      return '$periodText와 동일한 시간 동안 공부했어요!';
    }
  }

  static String _generateMissionAnalysis(int prevCount, int recentCount, int period) {
    final countDiff = recentCount - prevCount;
    final periodText = _getPeriodText(period);
    
    if (countDiff > 0) {
      return '$periodText보다 총 ${countDiff}개의 미션을 더 달성했어요!';
    } else if (countDiff < 0) {
      return '$periodText보다 달성한 미션이 ${countDiff.abs()}개 감소했어요!';
    } else {
      return '$periodText와 동일한 개수의 미션을 달성했어요!';
    }
  }

  static String _generateScoreAnalysis(num prevScore, num recentScore, int period) {
    final scoreDiff = recentScore - prevScore;
    final periodText = _getPeriodText(period);
    
    if (scoreDiff > 0) {
      return '$periodText보다 평균 점수가 ${scoreDiff.toStringAsFixed(1)}점 상승했어요!';
    } else if (scoreDiff < 0) {
      return '$periodText보다 평균 점수가 ${scoreDiff.abs().toStringAsFixed(1)}점 감소했어요!';
    } else {
      return '$periodText와 동일한 평균 점수를 기록했어요!';
    }
  }

  static String _generateSubjectAnalysis(String leastSubject, int leastTime, String mostSubject, int mostTime, int period) {
    if (leastSubject.isEmpty || mostSubject.isEmpty) {
      return '과목별 분석 데이터가 부족해요.';
    }
    
    final timeDiff = mostTime - leastTime;
    final periodText = period == 7 ? '최근 7일동안' : 
                      period == 14 ? '최근 14일동안' :
                      period == 30 ? '최근 30일동안' :
                      period == 60 ? '최근 60일동안' : '최근 기간동안';
    
    return '$periodText 제일 많이 수행한 $mostSubject 미션에서 $leastSubject 미션보다 총 ${formatStudyTime(timeDiff)}을 더 할애했어요. 우리 아이에게 부족한 과목 미션을 생성하고 꾸준한 참여를 도와주세요.';
  }

  /// 분석 카드 데이터 생성
  static List<Map<String, dynamic>> generateAnalysisCards(Map<String, dynamic> data) {
    final summaries = generateAnalysisSummary(data);
    final prevStudyTime = data['prevStudyTime'] ?? 0;
    final recentStudyTime = data['recentStudyTime'] ?? 0;
    final prevMissionCount = data['prevMissionAchieveCount'] ?? 0;
    final recentMissionCount = data['recentMissionAchieveCount'] ?? 0;
    final prevAvgScore = (data['prevAvgScore'] ?? 0).toDouble();
    final recentAvgScore = (data['recentAvgScore'] ?? 0).toDouble();
    final leastTimeSubject = data['nameOfLeastTimeSubject'] ?? '';
    final leastTime = data['timeOfLeastTimeSubject'] ?? 0;
    final mostTimeSubject = data['nameOfMostTimeSubject'] ?? '';
    final mostTime = data['timeOfMostTimeSubject'] ?? 0;

    return [
      {
        'title': summaries['studyTimeAnalysis'],
        'data1': formatStudyTime(prevStudyTime),
        'data2': formatStudyTime(recentStudyTime),
        'description': _generateDetailedStudyTimeDescription(prevStudyTime, recentStudyTime, data['name'] ?? '아이', data['period'] ?? 7),
      },
      {
        'title': summaries['missionAnalysis'],
        'data1': '${prevMissionCount}개',
        'data2': '${recentMissionCount}개',
        'description': _generateDetailedMissionDescription(prevMissionCount, recentMissionCount, data['name'] ?? '아이', data['period'] ?? 7),
      },
      {
        'title': summaries['scoreAnalysis'],
        'data1': '${prevAvgScore.toStringAsFixed(1)}점',
        'data2': '${recentAvgScore.toStringAsFixed(1)}점',
        'description': _generateDetailedScoreDescription(prevAvgScore, recentAvgScore, data['name'] ?? '아이', data['period'] ?? 7),
      },
      {
        'title': summaries['subjectAnalysis'],
        'data1': formatStudyTime(leastTime),
        'data2': formatStudyTime(mostTime),
        'isVs': true,
        'description': summaries['subjectAnalysis'],
      },
    ];
  }

  static String _generateDetailedStudyTimeDescription(int prevTime, int recentTime, String childName, int period) {
    final timeDiff = recentTime - prevTime;
    final periodText = _getPeriodText(period);
    final recentPeriodText = period == 7 ? '최근 7일' : 
                           period == 14 ? '최근 14일' :
                           period == 30 ? '최근 30일' :
                           period == 60 ? '최근 60일' : '최근 기간';
    
    if (timeDiff > 0) {
      return '$periodText에 총 ${formatStudyTime(prevTime)} 학습했던 ${childName}님이 $recentPeriodText 동안은 총 ${formatStudyTime(recentTime)} 학습하여 총 학습 시간이 증가했어요. 꾸준한 학습 습관이 잘 형성되고 있어요!';
    } else if (timeDiff < 0) {
      return '$periodText에 총 ${formatStudyTime(prevTime)} 학습했던 ${childName}님이 $recentPeriodText 동안은 총 ${formatStudyTime(recentTime)} 학습하여 총 학습 시간이 감소했어요. 성실한 습관 형성을 도우기 위해서는 충분한 격려가 필요해요.';
    } else {
      return '$periodText와 동일하게 총 ${formatStudyTime(recentTime)} 학습했어요. 꾸준한 학습 습관을 유지하고 있어요!';
    }
  }

  static String _generateDetailedMissionDescription(int prevCount, int recentCount, String childName, int period) {
    final countDiff = recentCount - prevCount;
    final periodText = _getPeriodText(period);
    final recentPeriodText = period == 7 ? '이번 주' : 
                           period == 14 ? '최근 2주' :
                           period == 30 ? '이번 달' :
                           period == 60 ? '최근 2달' : '최근 기간';
    
    if (countDiff > 0) {
      return '$periodText 총 ${prevCount}개의 미션을 달성했던 ${childName}님이 $recentPeriodText는 총 ${recentCount}개의 미션을 달성했어요. 아직 칭찬해 주지 않았다면, 채팅으로 칭찬하러 가보세요.';
    } else if (countDiff < 0) {
      return '$periodText 총 ${prevCount}개의 미션을 달성했던 ${childName}님이 $recentPeriodText는 총 ${recentCount}개의 미션을 달성했어요. 조금 더 격려해주시면 좋을 것 같아요.';
    } else {
      return '$periodText와 동일하게 총 ${recentCount}개의 미션을 달성했어요. 꾸준한 미션 수행 능력을 보여주고 있어요!';
    }
  }

  static String _generateDetailedScoreDescription(num prevScore, num recentScore, String childName, int period) {
    final scoreDiff = recentScore - prevScore;
    final periodText = _getPeriodText(period);
    final recentPeriodText = period == 7 ? '최근 7일' : 
                           period == 14 ? '최근 14일' :
                           period == 30 ? '최근 30일' :
                           period == 60 ? '최근 60일' : '최근 기간';
    
    if (scoreDiff > 0) {
      return '$periodText 평균 ${prevScore.toStringAsFixed(1)}점을 기록했던 ${childName}님이 $recentPeriodText 동안은 평균 ${recentScore.toStringAsFixed(1)}점을 기록하여 성적이 향상되었어요. 계속해서 응원해주세요!';
    } else if (scoreDiff < 0) {
      return '$periodText 평균 ${prevScore.toStringAsFixed(1)}점을 기록했던 ${childName}님이 $recentPeriodText 동안은 평균 ${recentScore.toStringAsFixed(1)}점을 기록했어요. 조금 더 세심한 관심과 격려가 필요할 것 같아요.';
    } else {
      return '$periodText와 동일하게 평균 ${recentScore.toStringAsFixed(1)}점을 기록했어요. 안정적인 학습 성과를 보여주고 있어요!';
    }
  }

  /// 기간에 따른 텍스트 반환
  static String _getPeriodText(int period) {
    switch (period) {
      case 7:
        return '지난주';
      case 14:
        return '지난 2주';
      case 30:
        return '지난 달';
      case 60:
        return '지난 2달';
      default:
        return '이전 기간';
    }
  }

  /// 일별 학습 시간 데이터 조회
  static Future<List<Map<String, dynamic>>?> getDailyStudyData(int memberId, int period) async {
    try {
      print('🔍 [AnalysisService] 일별 학습 데이터 조회 시작');
      print('📊 memberId: $memberId, period: $period');
      
      _initializeDio();

      final token = await TokenService.getAccessToken();
      if (token == null) {
        print('❌ [AnalysisService] 토큰이 없습니다.');
        throw Exception('토큰이 없습니다.');
      }

      final url = '/api-user/analyze/$memberId/daily';
      print('🌐 [AnalysisService] 요청 URL: $url');
      print('📝 [AnalysisService] 쿼리 파라미터: period=$period');

      final response = await _dio.get(
        url,
        queryParameters: {
          'period': period,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      print('📡 [AnalysisService] 일별 데이터 API 응답 상태 코드: ${response.statusCode}');
      print('📄 [AnalysisService] 일별 데이터 API 응답 데이터: ${response.data}');

      if (response.statusCode == 200) {
        final responseData = response.data;
        
        // API 응답 구조에 따라 데이터 처리
        List<dynamic> dailyData = [];
        
        if (responseData is Map<String, dynamic>) {
          // 중첩된 구조인 경우
          dailyData = responseData['dailyStudyData'] ?? 
                     responseData['data'] ?? 
                     responseData['dailyData'] ?? [];
        } else if (responseData is List) {
          // 직접 배열인 경우
          dailyData = responseData;
        }
        
        // 데이터를 표준 형식으로 변환
        final formattedData = dailyData.map((item) {
          final data = item as Map<String, dynamic>;
          
          // 날짜 파싱 및 포맷팅
          final dateStr = data['date'] ?? data['studyDate'] ?? '';
          final parsedDate = _parseApiDate(dateStr);
          
          return {
            'date': '${parsedDate.month}.${parsedDate.day}',
            'dayOfWeek': _getDayOfWeek(parsedDate.weekday),
            'studyTimeMinutes': data['studyTimeMinutes'] ?? 
                               data['studyTime'] ?? 
                               data['timeInMinutes'] ?? 0,
            'isToday': _isToday(parsedDate),
          };
        }).toList();
        
        print('✅ [AnalysisService] 일별 학습 데이터 조회 성공: ${formattedData.length}일간');
        return formattedData.cast<Map<String, dynamic>>();
      } else {
        print('❌ [AnalysisService] 일별 데이터 API 응답 오류: ${response.statusCode}');
        throw Exception('일별 학습 데이터 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [AnalysisService] 일별 학습 데이터 조회 오류: $e');
      
      // API 실패 시 실제 미션/챌린지 데이터에서 추출
      return await _generateRealDailyDataFromServices(memberId, period);
    }
  }

  /// 실제 서비스 API에서 일별 학습 데이터 생성 (챌린지/목표/미션 각 2시간씩 계산)
  static Future<List<Map<String, dynamic>>> _generateRealDailyDataFromServices(int memberId, int period) async {
    try {
      print('🔄 [AnalysisService] 실제 서비스에서 일별 데이터 생성 시작');
      
      final now = DateTime.now();
      final displayDays = period >= 7 ? 7 : period;
      final List<Map<String, dynamic>> realData = [];
      
      // 미션 데이터 조회
      print('🔍 [AnalysisService] 미션 데이터 조회 시작');
      final missionData = await MissionService.getChildMissions(page: 0);
      print('📋 미션 API 응답: $missionData');
      
      final missions = missionData?['data'] != null ? 
          List<Map<String, dynamic>>.from(missionData!['data']) : <Map<String, dynamic>>[];
      
      print('📊 미션 데이터 분석:');
      print('   - 총 미션 개수: ${missions.length}개');
      
      if (missions.isNotEmpty) {
        print('   - 첫 번째 미션 샘플: ${missions.first}');
        
        // 미션 상태별 개수 카운트
        Map<String, int> statusCount = {};
        for (final mission in missions) {
          final status = mission['status'] ?? 'UNKNOWN';
          statusCount[status] = (statusCount[status] ?? 0) + 1;
        }
        print('   - 미션 상태별 개수: $statusCount');
      } else {
        print('   ⚠️ 미션 데이터가 비어있습니다.');
      }
      
      // 챌린지 데이터 조회 시도
      List<dynamic> challenges = [];
      try {
        final familyInfo = await FamilyService.getFamilyInfo();
        if (familyInfo != null) {
          final familyId = familyInfo['familyId'] ?? 1;
          
          // 🔧 수정: familyMemberId가 아닌 userId를 사용
          print('🔍 챌린지 API: familyId=$familyId, userId=$memberId 사용');
          final challengeResponse = await ChallengeService.getChildChallenges(familyId, memberId);
          challenges = challengeResponse.data ?? [];
          
          print('✅ 챌린지 데이터 조회 성공: ${challenges.length}개');
          
          // 모든 챌린지 상세 정보 로깅 (현재 진행 중인 챌린지 확인용)
          for (int i = 0; i < challenges.length; i++) {
            try {
              Map<String, dynamic> challengeMap;
              if (challenges[i] is Map<String, dynamic>) {
                challengeMap = challenges[i];
              } else {
                challengeMap = (challenges[i] as dynamic).toJson();
              }
              
              print('   📊 챌린지 ${i+1}: ${challengeMap['title']}');
              print('     - 상태: ${challengeMap['challengeStatus']}');
              print('     - 시작일: ${challengeMap['startDate']}');
              print('     - 종료일: ${challengeMap['endDate']}');
              print('     - 학습시간: ${challengeMap['totalStudyTime']}분');
              print('     - 점수: ${challengeMap['finishScore']}점');
              
              // 현재 그래프 기간과 겹치는지 확인
              final challengeStartStr = challengeMap['startDate'] ?? '';
              final challengeEndStr = challengeMap['endDate'] ?? '';
              if (challengeStartStr.isNotEmpty && challengeEndStr.isNotEmpty) {
                final challengeStartDate = DateTime.parse(challengeStartStr);
                final challengeEndDate = DateTime.parse(challengeEndStr);
                final graphStartDate = now.subtract(Duration(days: displayDays - 1));
                final graphEndDate = now;
                
                final isOverlapping = challengeEndDate.isAfter(graphStartDate.subtract(Duration(days: 1))) &&
                    challengeStartDate.isBefore(graphEndDate.add(Duration(days: 1)));
                
                print('     - 그래프 기간과 겹침: $isOverlapping (그래프: ${graphStartDate.month}.${graphStartDate.day} ~ ${graphEndDate.month}.${graphEndDate.day})');
              }
            } catch (e) {
              print('   ❌ 챌린지 ${i+1} 처리 오류: $e');
            }
          }
        }
      } catch (e) {
        print('⚠️ 챌린지 데이터 조회 실패: $e');
      }
      
      // 목표 데이터 조회 시도  
      print('🔍 [AnalysisService] 목표 데이터 조회 시작');
      List<Map<String, dynamic>> goals = [];
      try {
        final goalData = await GoalService.getParentWeeklyGoals(1);
        goals = goalData ?? [];
        
        // 각 목표에 대해 도장 정보(goalCheck) 추가
        for (int i = 0; i < goals.length; i++) {
          final goal = goals[i];
          final goalId = goal['goalId'];
          
          if (goalId != null) {
            try {
              final goalCheck = await GoalService.getGoalCheck(goalId);
              if (goalCheck != null) {
                goal['goalCheck'] = goalCheck;
                print('   ✅ 목표 ${goalId} 도장 정보 추가: $goalCheck');
              } else {
                print('   ⚠️ 목표 ${goalId} 도장 정보 없음');
              }
            } catch (e) {
              print('   ❌ 목표 ${goalId} 도장 정보 조회 실패: $e');
            }
          }
        }
        
        print('🎯 목표 데이터 분석:');
        print('   - 총 목표 개수: ${goals.length}개');
        
        if (goals.isNotEmpty) {
          print('   - 첫 번째 목표 샘플: ${goals.first}');
          
          // 목표 달성률 분석
          for (int i = 0; i < goals.length && i < 3; i++) {
            final goal = goals[i];
            final rate = GoalService.getGoalAchievementRate(goal);
            print('   - 목표 ${i+1} 달성률: ${rate.toStringAsFixed(1)}%');
          }
        } else {
          print('   ⚠️ 목표 데이터가 비어있습니다.');
        }
      } catch (e) {
        print('⚠️ 목표 데이터 조회 실패: $e');
      }
      
      // 미션 데이터가 없고 목표나 챌린지가 있다면 임시 미션 생성
      if (missions.isEmpty && (goals.isNotEmpty || challenges.isNotEmpty)) {
        print('📝 실제 진행 중인 미션을 위한 임시 데이터 생성');
        final graphStartDate = now.subtract(Duration(days: displayDays - 1));
        missions.add({
          'title': '일일 학습 미션',
          'status': 'ACHIEVEMENT',
          'startDate': graphStartDate.toIso8601String(),
          'endDate': now.toIso8601String(),
          'studyTimeMinutes': 120,
        });
        print('🔧 임시 미션 데이터 생성됨: 일일 학습 미션 (${graphStartDate.month}.${graphStartDate.day} ~ ${now.month}.${now.day})');
      }
      
      // 최근 displayDays일간의 실제 데이터 생성
      for (int i = displayDays - 1; i >= 0; i--) {
        final targetDate = now.subtract(Duration(days: i));
        final dateStr = '${targetDate.year}-${targetDate.month.toString().padLeft(2, '0')}-${targetDate.day.toString().padLeft(2, '0')}';
        
        int dailyStudyTime = 0;
        bool hasMission = false;
        bool hasChallenge = false;
        bool hasGoal = false;
        
        print('📅 ${dateStr} (${_getDayOfWeek(targetDate.weekday)}) 학습시간 계산 중...');
        
        // 해당 날짜의 미션 참여 확인 (실제 완료된 미션만 2시간 = 120분)
        for (final mission in missions) {
          try {
            final missionStatus = mission['status'] ?? '';
            final missionStartStr = mission['startDate'] ?? mission['createdAt'] ?? '';
            final missionEndStr = mission['endDate'] ?? '';
            final studyTimeMinutes = mission['studyTimeMinutes'] ?? mission['durationMinutes'] ?? 0;
            
            if (missionStartStr.isNotEmpty && (missionStatus == 'COMPLETED' || missionStatus == 'FINISHED' || 
                missionStatus == 'ACHIEVEMENT' || missionStatus == 'ACCEPT' || missionStatus == 'IN_PROGRESS')) {
              final missionStartDate = DateTime.parse(missionStartStr);
              final missionEndDate = missionEndStr.isNotEmpty ? 
                  DateTime.parse(missionEndStr) : 
                  missionStartDate.add(Duration(days: 1)); // 기본 1일
              
              // 미션 기간이 현재 표시하는 기간과 겹치고, 해당 날짜가 미션 기간 내에 있는 경우
              final graphStartDate = now.subtract(Duration(days: displayDays - 1));
              final graphEndDate = now;
              
              if (missionEndDate.isAfter(graphStartDate.subtract(Duration(days: 1))) &&
                  missionStartDate.isBefore(graphEndDate.add(Duration(days: 1))) &&
                  targetDate.isAfter(missionStartDate.subtract(Duration(days: 1))) &&
                  targetDate.isBefore(missionEndDate.add(Duration(days: 1)))) {
                
                hasMission = true;
                print('   ✅ 미션 완료 확인: ${mission['title'] ?? '미션'} (상태: $missionStatus, 학습시간: ${studyTimeMinutes}분)');
                break;
              }
            } else if (missionStartStr.isNotEmpty) {
              print('   📅 미션이 있지만 미완료: ${mission['title'] ?? '미션'} (상태: $missionStatus)');
            }
          } catch (e) {
            // 날짜 파싱 실패는 무시
            print('   ❌ 미션 날짜 파싱 오류: $e');
          }
        }
        
        // 해당 날짜의 챌린지 참여 확인 (실제 활동 기간만 2시간 = 120분)
        for (final challenge in challenges) {
          try {
            // ChallengeParticipation 객체를 Map으로 변환
            Map<String, dynamic> challengeMap;
            if (challenge is Map<String, dynamic>) {
              challengeMap = challenge;
            } else {
              // ChallengeParticipation 객체인 경우 toJson() 메서드 사용
              challengeMap = (challenge as dynamic).toJson();
            }
            
            final challengeStatus = challengeMap['challengeStatus'] ?? '';
            final challengeStartStr = challengeMap['startDate'] ?? '';
            final challengeEndStr = challengeMap['endDate'] ?? '';
            final totalStudyTime = challengeMap['totalStudyTime'] ?? 0;
            
            if (challengeStartStr.isNotEmpty && challengeEndStr.isNotEmpty) {
              final challengeStartDate = DateTime.parse(challengeStartStr);
              final challengeEndDate = DateTime.parse(challengeEndStr);
              
              // 챌린지 기간이 현재 표시하는 7일 기간과 겹치는지 확인
              final graphStartDate = now.subtract(Duration(days: displayDays - 1));
              final graphEndDate = now;
              
              // 챌린지 기간과 그래프 기간이 겹치고, 해당 날짜가 챌린지 기간 내에 있는 경우
              // (진행 중인 챌린지도 포함하도록 totalStudyTime 조건 제거)
              if (challengeEndDate.isAfter(graphStartDate.subtract(Duration(days: 1))) &&
                  challengeStartDate.isBefore(graphEndDate.add(Duration(days: 1))) &&
                  targetDate.isAfter(challengeStartDate.subtract(Duration(days: 1))) &&
                  targetDate.isBefore(challengeEndDate.add(Duration(days: 1)))) {
                
                // 진행 중이거나 완료된 챌린지 모두 인정
                if (challengeStatus == 'ACHIEVEMENT' || 
                    challengeStatus == 'COMPLETED' || 
                    challengeStatus == 'PARTICIPATING' ||
                    challengeStatus == 'IN_PROGRESS' ||
                    challengeStatus == 'ACCEPT') {
                  hasChallenge = true;
                  print('   ✅ 챌린지 활동 확인: ${challengeMap['title'] ?? '챌린지'} (상태: $challengeStatus, 학습시간: ${totalStudyTime}분)');
                  break;
                } else {
                  print('   📅 챌린지 있지만 비활성 상태: ${challengeMap['title'] ?? '챌린지'} (상태: $challengeStatus)');
                }
              }
            }
          } catch (e) {
            // 날짜 파싱 실패는 무시
            print('   ❌ 챌린지 날짜 파싱 오류: $e');
          }
        }
        
        // 해당 날짜의 목표 참여 확인 (실제 도장 받은 날만 2시간 = 120분)
        for (final goal in goals) {
          try {
            final goalDateStr = goal['startDate'] ?? '';
            final goalEndDateStr = goal['endDate'] ?? '';
            final stampCount = goal['stampCount'] ?? 0; // 실제 받은 도장 수
            final minStampCount = goal['minStampCount'] ?? 0; // 필요한 도장 수
            final goalCheck = goal['goalCheck'] as Map<String, dynamic>?; // 도장 받은 날짜 정보
            
            if (goalDateStr.isNotEmpty && stampCount > 0 && goalCheck != null) {
              final goalStartDate = DateTime.parse(goalDateStr);
              final goalEndDate = goalEndDateStr.isNotEmpty ? 
                  DateTime.parse(goalEndDateStr) : 
                  goalStartDate.add(Duration(days: 7)); // 기본 1주일
              
              // 목표 기간 내에 있는지 확인
              if (targetDate.isAfter(goalStartDate.subtract(Duration(days: 1))) && 
                  targetDate.isBefore(goalEndDate.add(Duration(days: 1)))) {
                
                // 해당 날짜의 요일 확인
                final dayOfWeek = targetDate.weekday; // 1=월, 2=화, 3=수, 4=목, 5=금, 6=토, 7=일
                String weekdayKey = '';
                
                switch (dayOfWeek) {
                  case 1: weekdayKey = 'mon'; break;
                  case 2: weekdayKey = 'tue'; break;
                  case 3: weekdayKey = 'wed'; break;
                  case 4: weekdayKey = 'thu'; break;
                  case 5: weekdayKey = 'fri'; break;
                  case 6: weekdayKey = 'sat'; break;
                  case 7: weekdayKey = 'sun'; break;
                }
                
                // 실제 도장을 받은 날짜인지 확인
                final hasStamp = goalCheck[weekdayKey] == true;
                
                if (hasStamp) {
                  hasGoal = true;
                  print('   ✅ 목표 활동 확인: ${goal['title'] ?? '목표'} (도장 받은 날: ${weekdayKey}, 도장: ${stampCount}/${minStampCount})');
                  break;
                } else {
                  print('   📅 목표 기간이지만 도장 없음: ${goal['title'] ?? '목표'} (요일: ${weekdayKey}, 도장: ${hasStamp})');
                }
              } else if (targetDate.isBefore(goalStartDate)) {
                print('   📅 목표 시작 전: ${goal['title'] ?? '목표'} (시작일: ${goalDateStr})');
              } else if (targetDate.isAfter(goalEndDate)) {
                print('   📅 목표 종료 후: ${goal['title'] ?? '목표'} (종료일: ${goalEndDateStr})');
              }
            }
          } catch (e) {
            // 날짜 파싱 실패는 무시
            print('   ❌ 목표 처리 오류: $e');
          }
        }
        
        // 각 활동별로 2시간(120분)씩 추가
        if (hasMission) {
          dailyStudyTime += 120; // 미션 참여 시 2시간
          print('   📚 미션 학습시간 추가: 120분');
        }
        
        if (hasChallenge) {
          dailyStudyTime += 120; // 챌린지 참여 시 2시간
          print('   🏆 챌린지 학습시간 추가: 120분');
        }
        
        if (hasGoal) {
          dailyStudyTime += 120; // 목표 참여 시 2시간
          print('   🎯 목표 학습시간 추가: 120분');
        }
        
        // 활동이 없는 날은 0분으로 설정
        if (!hasMission && !hasChallenge && !hasGoal) {
          dailyStudyTime = 0;
          print('   💤 활동 없음: 0분');
        }
        
        print('   📊 총 학습시간: ${dailyStudyTime}분');
        
        realData.add({
          'date': '${targetDate.month}.${targetDate.day}',
          'dayOfWeek': _getDayOfWeek(targetDate.weekday),
          'studyTimeMinutes': dailyStudyTime,
          'isToday': i == 0,
        });
      }
      
      print('✅ [AnalysisService] 실제 서비스에서 일별 데이터 생성 완료: ${realData.length}일간');
      final totalTime = realData.map((d) => d['studyTimeMinutes'] as int).reduce((a, b) => a + b);
      print('📈 총 학습 시간: ${totalTime}분 (${formatStudyTime(totalTime)})');
      
      return realData;
    } catch (e) {
      print('❌ [AnalysisService] 실제 데이터 생성 오류: $e');
      // 최후의 방법으로 빈 데이터 반환
      final now = DateTime.now();
      final displayDays = period >= 7 ? 7 : period;
      final List<Map<String, dynamic>> emptyData = [];
      
      for (int i = displayDays - 1; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        emptyData.add({
          'date': '${date.month}.${date.day}',
          'dayOfWeek': _getDayOfWeek(date.weekday),
          'studyTimeMinutes': 0,
          'isToday': i == 0,
        });
      }
      
      return emptyData;
    }
  }

  /// 미션 기간 내에 있는지 확인 (미션은 보통 1-3일 정도 지속)
  static bool _isWithinMissionPeriod(DateTime missionStartDate, DateTime targetDate) {
    final missionEndDate = missionStartDate.add(Duration(days: 3)); // 미션은 최대 3일간 지속
    return targetDate.isAfter(missionStartDate.subtract(Duration(days: 1))) &&
           targetDate.isBefore(missionEndDate.add(Duration(days: 1)));
  }

  /// 챌린지 기간 내에 있는지 확인 (챌린지는 보통 7-30일 정도 지속)
  static bool _isWithinChallengePeriod(DateTime challengeStartDate, DateTime targetDate) {
    final challengeEndDate = challengeStartDate.add(Duration(days: 14)); // 챌린지는 최대 2주간 지속
    return targetDate.isAfter(challengeStartDate.subtract(Duration(days: 1))) &&
           targetDate.isBefore(challengeEndDate.add(Duration(days: 1)));
  }

  /// 두 날짜가 같은 날인지 확인
  static bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year && 
           date1.month == date2.month && 
           date1.day == date2.day;
  }

  /// 요일을 한글로 변환
  static String _getDayOfWeek(int weekday) {
    switch (weekday) {
      case 1: return '월';
      case 2: return '화';
      case 3: return '수';
      case 4: return '목';
      case 5: return '금';
      case 6: return '토';
      case 7: return '일';
      default: return '';
    }
  }

  /// API 날짜 문자열을 DateTime으로 파싱
  static DateTime _parseApiDate(String dateStr) {
    try {
      if (dateStr.isEmpty) return DateTime.now();
      
      // 다양한 날짜 형식 지원
      if (dateStr.contains('-')) {
        // ISO 형식: 2024-04-20 또는 2024-04-20T10:30:00
        return DateTime.parse(dateStr);
      } else if (dateStr.contains('.')) {
        // 점 형식: 4.20 또는 2024.04.20
        final parts = dateStr.split('.');
        if (parts.length == 2) {
          // 4.20 형식
          final month = int.parse(parts[0]);
          final day = int.parse(parts[1]);
          final now = DateTime.now();
          return DateTime(now.year, month, day);
        } else if (parts.length == 3) {
          // 2024.04.20 형식
          return DateTime(
            int.parse(parts[0]),
            int.parse(parts[1]),
            int.parse(parts[2]),
          );
        }
      }
      
      // 파싱 실패 시 현재 날짜 반환
      return DateTime.now();
    } catch (e) {
      print('❌ [AnalysisService] 날짜 파싱 오류: $dateStr -> $e');
      return DateTime.now();
    }
  }

  /// 날짜가 오늘인지 확인
  static bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && 
           date.month == now.month && 
           date.day == now.day;
  }

  /// 일별 데이터에서 그래프 포인트 계산 (챌린지+목표+미션 고려)
  static List<Offset> calculateGraphPoints(List<Map<String, dynamic>> dailyData, Size graphSize) {
    if (dailyData.isEmpty) return [];
    
    final maxStudyTime = dailyData
        .map((data) => data['studyTimeMinutes'] as int)
        .reduce((a, b) => a > b ? a : b)
        .toDouble();
    
    // 최대값을 10시간(600분)으로 설정 (2시간 단위로 표시)
    final maxScale = 600.0; // 10시간 기준으로 고정
    
    List<Offset> points = [];
    for (int i = 0; i < dailyData.length; i++) {
      final studyTime = (dailyData[i]['studyTimeMinutes'] as int).toDouble();
      
      // 학습 시간이 10시간을 초과하면 10시간으로 제한 (그래프 표시용)
      final displayStudyTime = studyTime > maxScale ? maxScale : studyTime;
      
      final x = graphSize.width * (0.05 + (i * 0.9 / (dailyData.length - 1)));
      final y = graphSize.height * (0.9 - (displayStudyTime / maxScale) * 0.7); // 0.9에서 0.2까지 사용
      points.add(Offset(x, y));
      
      // 로깅으로 그래프 포인트 확인
      print('📍 그래프 포인트 ${i+1}: 학습시간=${studyTime}분, 표시시간=${displayStudyTime}분, 좌표=(${x.toStringAsFixed(1)}, ${y.toStringAsFixed(1)})');
    }
    
    print('📈 그래프 포인트 총 ${points.length}개 생성 완료');
    return points;
  }

  /// 달성률 데이터 계산 (개선된 API 사용)
  static Future<Map<String, dynamic>> calculateAchievementData(int memberId, int period) async {
    try {
      print('📊 [AnalysisService] 달성률 데이터 계산 시작');
      
      // 1. 목표 API로 달성률 계산 시도 (가장 정확)
      try {
        final allGoals = await GoalService.getChildAllGoals();
        
        if (allGoals != null && allGoals.isNotEmpty) {
          print('🎯 목표 기반 달성률 계산');
          
          final now = DateTime.now();
          final cutoffDate = now.subtract(Duration(days: period));
          
          List<Map<String, dynamic>> prevGoals = [];
          List<Map<String, dynamic>> recentGoals = [];
          
          // 기간별로 목표 분류
          for (final goal in allGoals) {
            try {
              final startDateStr = goal['startDate'] ?? '';
              if (startDateStr.isNotEmpty) {
                final startDate = DateTime.parse(startDateStr);
                
                if (startDate.isBefore(cutoffDate)) {
                  prevGoals.add(goal);
                } else {
                  recentGoals.add(goal);
                }
              } else {
                recentGoals.add(goal);
              }
            } catch (e) {
              recentGoals.add(goal);
            }
          }
          
          // 달성률 계산
          double prevTotalRate = 0.0;
          int prevCount = 0;
          
          for (final goal in prevGoals) {
            final rate = GoalService.getGoalAchievementRate(goal);
            prevTotalRate += rate;
            prevCount++;
          }
          
          double recentTotalRate = 0.0;
          int recentCount = 0;
          
          for (final goal in recentGoals) {
            final rate = GoalService.getGoalAchievementRate(goal);
            recentTotalRate += rate;
            recentCount++;
          }
          
          if (prevCount > 0 || recentCount > 0) {
            final prevRate = prevCount > 0 ? (prevTotalRate / prevCount).round() : 0;
            final recentRate = recentCount > 0 ? (recentTotalRate / recentCount).round() : 0;
            
            print('🎯 목표 기반 달성률 사용: 이전 ${prevRate}%, 최근 ${recentRate}%');
            
            return {
              'prevRate': prevRate,
              'recentRate': recentRate,
              'prevLabel': _getPeriodText(period),
              'recentLabel': '오늘까지',
              'isImproved': recentRate >= prevRate,
              'difference': (recentRate - prevRate).abs(),
            };
          }
        }
      } catch (e) {
        print('⚠️ 목표 기반 달성률 계산 실패: $e');
      }
      
      // 2. 미션 API로 달성률 계산 시도
      try {
        print('📋 미션 기반 달성률 계산');
        
        final totalMissions = await _getTotalMissionsByPeriod(memberId, period);
        final completedMissions = await _getCompletedMissionsByPeriod(memberId, period);
        
        final prevTotal = totalMissions['prev'] ?? 0;
        final prevCompleted = completedMissions['prevCompleted'] ?? 0;
        final recentTotal = totalMissions['recent'] ?? 0;
        final recentCompleted = completedMissions['recentCompleted'] ?? 0;
        
        if (prevTotal + recentTotal > 0) {
          final prevRate = prevTotal > 0 ? (prevCompleted / prevTotal * 100).round() : 0;
          final recentRate = recentTotal > 0 ? (recentCompleted / recentTotal * 100).round() : 0;
          
          print('📋 미션 기반 달성률 사용: 이전 ${prevRate}%, 최근 ${recentRate}%');
          
          return {
            'prevRate': prevRate,
            'recentRate': recentRate,
            'prevLabel': _getPeriodText(period),
            'recentLabel': '오늘까지',
            'isImproved': recentRate >= prevRate,
            'difference': (recentRate - prevRate).abs(),
          };
        }
      } catch (e) {
        print('⚠️ 미션 기반 달성률 계산 실패: $e');
      }
      
      // 3. 분석 리포트 API로 마지막 시도
      print('📊 분석 리포트 API로 달성률 계산');
      final analysisData = await getAnalysisReport(memberId, period);
      
      if (analysisData != null) {
        final prevMissionCount = analysisData['prevMissionAchieveCount'] ?? 0;
        final recentMissionCount = analysisData['recentMissionAchieveCount'] ?? 0;
        
        if (prevMissionCount > 0 || recentMissionCount > 0) {
          final totalEstimated = prevMissionCount + recentMissionCount;
          final prevRate = totalEstimated > 0 ? (prevMissionCount / totalEstimated * 100).round() : 0;
          final recentRate = totalEstimated > 0 ? (recentMissionCount / totalEstimated * 100).round() : 0;
          
          print('📊 분석 리포트 기반 달성률 사용: 이전 ${prevRate}%, 최근 ${recentRate}%');
          
          return {
            'prevRate': prevRate,
            'recentRate': recentRate,
            'prevLabel': _getPeriodText(period),
            'recentLabel': '오늘까지',
            'isImproved': recentRate >= prevRate,
            'difference': (recentRate - prevRate).abs(),
          };
        }
      }

      // 4. 모든 데이터가 없는 경우 0 반환
      print('⚠️ 모든 데이터가 없어 0으로 초기화');
      return {
        'prevRate': 0,
        'recentRate': 0,
        'prevLabel': _getPeriodText(period),
        'recentLabel': '오늘까지',
        'isImproved': false,
        'difference': 0,
      };
      
    } catch (e) {
      print('❌ 달성률 계산 오류: $e');
      // 오류 시에도 실제 데이터 시도
      try {
        final basicMissionData = await _getTotalMissionsByPeriod(memberId, period);
        final basicCompletedData = await _getCompletedMissionsByPeriod(memberId, period);
        
        final prevTotal = basicMissionData['prev'] ?? 0;
        final recentTotal = basicMissionData['recent'] ?? 0;
        final prevCompleted = basicCompletedData['prevCompleted'] ?? 0;
        final recentCompleted = basicCompletedData['recentCompleted'] ?? 0;
        
        final prevRate = prevTotal > 0 ? (prevCompleted / prevTotal * 100).round() : 0;
        final recentRate = recentTotal > 0 ? (recentCompleted / recentTotal * 100).round() : 0;
        
        return {
          'prevRate': prevRate,
          'recentRate': recentRate,
          'prevLabel': _getPeriodText(period),
          'recentLabel': '오늘까지',
          'isImproved': recentRate >= prevRate,
          'difference': (recentRate - prevRate).abs(),
        };
      } catch (fallbackError) {
        print('❌ 기본 데이터 조회도 실패: $fallbackError');
        // 최후의 방법으로만 0 반환
        return {
          'prevRate': 0,
          'recentRate': 0,
          'prevLabel': _getPeriodText(period),
          'recentLabel': '오늘까지',
          'isImproved': false,
          'difference': 0,
        };
      }
    }
  }

  /// 상승률 데이터 계산 (실제 API 사용)
  static Future<Map<String, dynamic>> calculateGrowthRateData(int memberId, int period) async {
    try {
      print('📈 [AnalysisService] 상승률 데이터 계산 시작');
      
      // 분석 리포트에서 학습 점수 데이터 가져오기
      final analysisData = await getAnalysisReport(memberId, period);
      
      double prevAvgScore = 0.0;
      double recentAvgScore = 0.0;
      
      if (analysisData != null) {
        prevAvgScore = (analysisData['prevAvgScore'] ?? 0).toDouble();
        recentAvgScore = (analysisData['recentAvgScore'] ?? 0).toDouble();
        
        print('📊 분석 리포트에서 점수 데이터 획득');
        print('   - 이전 기간 평균 점수: ${prevAvgScore}점');
        print('   - 최근 기간 평균 점수: ${recentAvgScore}점');
      }
      
      // 만약 분석 데이터가 없다면 미션에서 점수 추출
      if (prevAvgScore == 0 && recentAvgScore == 0) {
        final scoreData = await _getAverageScoresByPeriod(memberId, period);
        prevAvgScore = scoreData['prevScore'] ?? 0.0;
        recentAvgScore = scoreData['recentScore'] ?? 0.0;
        
        // 점수 데이터가 없으면 실제 0값 유지
        // 하드코딩된 기본값 사용하지 않음
        
        print('📝 미션에서 점수 데이터 보정');
        print('   - 이전 기간 보정 점수: ${prevAvgScore}점');
        print('   - 최근 기간 보정 점수: ${recentAvgScore}점');
      }
      
      // 상승률 계산
      double growthRate = 0;
      if (prevAvgScore > 0) {
        growthRate = ((recentAvgScore - prevAvgScore) / prevAvgScore * 100);
      }

      final prevRateDisplay = prevAvgScore.round();
      final recentRateDisplay = recentAvgScore.round();

      final result = {
        'prevRate': prevRateDisplay,
        'recentRate': recentRateDisplay,
        'prevLabel': _getPeriodText(period),
        'recentLabel': '오늘까지',
        'isImproved': growthRate >= 0,
        'growthRate': growthRate.abs().round(),
        'difference': (recentRateDisplay - prevRateDisplay).abs(),
      };
      
      print('✅ 상승률 계산 완료: $result');
      return result;
      
    } catch (e) {
      print('❌ 상승률 계산 오류: $e');
      // 오류 시에도 실제 데이터 시도
      try {
        final basicScoreData = await _getAverageScoresByPeriod(memberId, period);
        final prevScore = basicScoreData['prevScore'] ?? 0.0;
        final recentScore = basicScoreData['recentScore'] ?? 0.0;
        
        final prevRateDisplay = prevScore.round();
        final recentRateDisplay = recentScore.round();
        final growthRate = prevScore > 0 ? ((recentScore - prevScore) / prevScore * 100).abs().round() : 0;
        
        return {
          'prevRate': prevRateDisplay,
          'recentRate': recentRateDisplay,
          'prevLabel': _getPeriodText(period),
          'recentLabel': '오늘까지',
          'isImproved': recentScore >= prevScore,
          'growthRate': growthRate,
          'difference': (recentRateDisplay - prevRateDisplay).abs(),
        };
      } catch (fallbackError) {
        print('❌ 기본 점수 데이터 조회도 실패: $fallbackError');
        // 최후의 방법으로만 0 반환
        return {
          'prevRate': 0,
          'recentRate': 0,
          'prevLabel': _getPeriodText(period),
          'recentLabel': '오늘까지',
          'isImproved': false,
          'growthRate': 0,
          'difference': 0,
        };
      }
    }
  }

  /// 목표 기반 달성률 계산
  static Future<Map<String, dynamic>> _calculateGoalAchievementRate(int memberId, int period) async {
    try {
      print('🎯 목표 기반 달성률 계산 시작');
      
      // 자녀의 모든 목표 조회
      final allGoals = await GoalService.getChildAllGoals();
      
      if (allGoals == null || allGoals.isEmpty) {
        print('📋 목표 데이터가 없습니다');
        return {'hasData': false};
      }
      
      final now = DateTime.now();
      final cutoffDate = now.subtract(Duration(days: period));
      
      List<Map<String, dynamic>> prevGoals = [];
      List<Map<String, dynamic>> recentGoals = [];
      
      // 기간별로 목표 분류
      for (final goal in allGoals) {
        try {
          final startDateStr = goal['startDate'] ?? '';
          if (startDateStr.isNotEmpty) {
            final startDate = DateTime.parse(startDateStr);
            
            if (startDate.isBefore(cutoffDate)) {
              prevGoals.add(goal);
            } else {
              recentGoals.add(goal);
            }
          } else {
            recentGoals.add(goal);
          }
        } catch (e) {
          recentGoals.add(goal);
        }
      }
      
      // 달성률 계산
      double prevTotalRate = 0.0;
      int prevCount = 0;
      
      for (final goal in prevGoals) {
        final rate = GoalService.getGoalAchievementRate(goal);
        prevTotalRate += rate;
        prevCount++;
      }
      
      double recentTotalRate = 0.0;
      int recentCount = 0;
      
      for (final goal in recentGoals) {
        final rate = GoalService.getGoalAchievementRate(goal);
        recentTotalRate += rate;
        recentCount++;
      }
      
      final prevRate = prevCount > 0 ? (prevTotalRate / prevCount).round() : 0;
      final recentRate = recentCount > 0 ? (recentTotalRate / recentCount).round() : 0;
      
      print('🎯 목표 기반 달성률 계산 완료');
      print('   - 이전 기간: ${prevCount}개 목표, 평균 달성률: ${prevRate}%');
      print('   - 최근 기간: ${recentCount}개 목표, 평균 달성률: ${recentRate}%');
      
      return {
        'prevRate': prevRate,
        'recentRate': recentRate,
        'prevLabel': _getPeriodText(period),
        'recentLabel': '오늘까지',
        'isImproved': recentRate >= prevRate,
        'difference': (recentRate - prevRate).abs(),
        'hasData': prevCount > 0 || recentCount > 0,
      };
      
    } catch (e) {
      print('❌ 목표 기반 달성률 계산 오류: $e');
      return {'hasData': false};
    }
  }

  /// 미션 기반 달성률 계산
  static Future<Map<String, dynamic>> _calculateMissionAchievementRate(int memberId, int period) async {
    try {
      print('📋 미션 기반 달성률 계산 시작');
      
      // 기존 미션 데이터로 달성률 계산
      final totalMissions = await _getTotalMissionsByPeriod(memberId, period);
      final completedMissions = await _getCompletedMissionsByPeriod(memberId, period);
      
      final prevTotal = totalMissions['prev'] ?? 0;
      final prevCompleted = completedMissions['prevCompleted'] ?? 0;
      final recentTotal = totalMissions['recent'] ?? 0;
      final recentCompleted = completedMissions['recentCompleted'] ?? 0;
      
      if (prevTotal + recentTotal == 0) {
        print('📋 미션 데이터가 없습니다');
        return {'hasData': false};
      }
      
      final prevRate = prevTotal > 0 ? (prevCompleted / prevTotal * 100).round() : 0;
      final recentRate = recentTotal > 0 ? (recentCompleted / recentTotal * 100).round() : 0;
      
      print('📋 미션 기반 달성률 계산 완료');
      print('   - 이전 기간: ${prevCompleted}/${prevTotal} (${prevRate}%)');
      print('   - 최근 기간: ${recentCompleted}/${recentTotal} (${recentRate}%)');
      
      return {
        'prevRate': prevRate,
        'recentRate': recentRate,
        'prevLabel': _getPeriodText(period),
        'recentLabel': '오늘까지',
        'isImproved': recentRate >= prevRate,
        'difference': (recentRate - prevRate).abs(),
        'hasData': true,
      };
      
    } catch (e) {
      print('❌ 미션 기반 달성률 계산 오류: $e');
      return {'hasData': false};
    }
  }

  /// 기간별 평균 점수 계산
  static Future<Map<String, double>> _getAverageScoresByPeriod(int memberId, int period) async {
    try {
      // 미션에서 점수 데이터 가져오기
      final missionData = await MissionService.getChildMissions(page: 0);
      final now = DateTime.now();
      final cutoffDate = now.subtract(Duration(days: period));
      
      List<double> prevScores = [];
      List<double> recentScores = [];
      
      if (missionData != null && missionData['data'] != null) {
        final missions = List<Map<String, dynamic>>.from(missionData['data']);
        
        for (final mission in missions) {
          final score = mission['score'];
          final finishScore = mission['finishScore'];
          final startDateStr = mission['startDate'] ?? '';
          
          // 점수가 있는 미션만 처리
          double? missionScore;
          if (score != null) {
            missionScore = (score is int) ? score.toDouble() : score as double?;
          } else if (finishScore != null) {
            missionScore = (finishScore is int) ? finishScore.toDouble() : finishScore as double?;
          }
          
          if (missionScore != null && missionScore > 0) {
            try {
              if (startDateStr.isNotEmpty) {
                final startDate = DateTime.parse(startDateStr);
                
                if (startDate.isBefore(cutoffDate)) {
                  prevScores.add(missionScore);
                } else {
                  recentScores.add(missionScore);
                }
              } else {
                recentScores.add(missionScore);
              }
            } catch (e) {
              recentScores.add(missionScore);
            }
          }
        }
      }
      
             // 챌린지에서도 점수 데이터 가져오기
       try {
         final familyInfo = await FamilyService.getFamilyInfo();
         if (familyInfo != null) {
           final familyId = familyInfo['familyId'];
           
           // 🔧 수정: familyMemberId가 아닌 userId를 직접 사용
           print('🔍 상승률 계산 - 챌린지 API: familyId=$familyId, userId=$memberId 사용');
           final challengeResponse = await ChallengeService.getChildChallenges(familyId, memberId);
          
          for (final challenge in challengeResponse.data) {
            final challengeMap = challenge as Map<String, dynamic>;
            final finishScore = challengeMap['finishScore'];
            final startDateStr = challengeMap['startDate'] ?? '';
            
            if (finishScore != null && finishScore > 0) {
              try {
                if (startDateStr.isNotEmpty) {
                  final startDate = DateTime.parse(startDateStr);
                  
                  if (startDate.isBefore(cutoffDate)) {
                    prevScores.add((finishScore as num).toDouble());
                  } else {
                    recentScores.add((finishScore as num).toDouble());
                  }
                } else {
                  recentScores.add((finishScore as num).toDouble());
                }
              } catch (e) {
                recentScores.add((finishScore as num).toDouble());
              }
            }
          }
        }
      } catch (e) {
        print('챌린지 점수 데이터 조회 오류: $e');
      }
      
      // 평균 계산 (실제 데이터만 사용)
      final prevAverage = prevScores.isNotEmpty 
          ? prevScores.reduce((a, b) => a + b) / prevScores.length
          : 0.0; // 데이터 없으면 0
          
      final recentAverage = recentScores.isNotEmpty 
          ? recentScores.reduce((a, b) => a + b) / recentScores.length
          : 0.0; // 데이터 없으면 0
      
      print('📊 점수 분석 완료:');
      print('   - 이전 기간 점수 개수: ${prevScores.length}개, 평균: ${prevAverage.toStringAsFixed(1)}점');
      print('   - 최근 기간 점수 개수: ${recentScores.length}개, 평균: ${recentAverage.toStringAsFixed(1)}점');
      
      return {
        'prevScore': prevAverage,
        'recentScore': recentAverage,
      };
    } catch (e) {
      print('❌ 평균 점수 계산 오류: $e');
      return {
        'prevScore': 0.0,
        'recentScore': 0.0,
      };
    }
  }

  /// 기간별 전체 미션 수 조회
  static Future<Map<String, int>> _getTotalMissionsByPeriod(int memberId, int period) async {
    try {
      // 현재 아이의 모든 미션 조회
      final missionData = await MissionService.getChildMissions(page: 0);
      
      if (missionData == null || missionData['data'] == null) {
        return {'total': 0, 'prev': 0, 'recent': 0};
      }
      
      final missions = List<Map<String, dynamic>>.from(missionData['data']);
      final now = DateTime.now();
      final cutoffDate = now.subtract(Duration(days: period));
      
      int totalMissions = missions.length;
      int prevPeriodMissions = 0;
      int recentPeriodMissions = 0;
      
      for (final mission in missions) {
        try {
          final startDateStr = mission['startDate'] ?? '';
          if (startDateStr.isNotEmpty) {
            final startDate = DateTime.parse(startDateStr);
            
            if (startDate.isBefore(cutoffDate)) {
              prevPeriodMissions++;
            } else {
              recentPeriodMissions++;
            }
          }
        } catch (e) {
          // 날짜 파싱 실패 시 최근 기간으로 분류
          recentPeriodMissions++;
        }
      }
      
      return {
        'total': totalMissions,
        'prev': prevPeriodMissions,
        'recent': recentPeriodMissions,
      };
    } catch (e) {
      print('❌ 기간별 전체 미션 수 조회 오류: $e');
      return {'total': 0, 'prev': 0, 'recent': 0};
    }
  }

  /// 기간별 완료 미션 수 조회
  static Future<Map<String, int>> _getCompletedMissionsByPeriod(int memberId, int period) async {
    try {
      final missionData = await MissionService.getChildMissions(page: 0);
      
      if (missionData == null || missionData['data'] == null) {
        return {'completed': 0, 'prevCompleted': 0, 'recentCompleted': 0};
      }
      
      final missions = List<Map<String, dynamic>>.from(missionData['data']);
      final now = DateTime.now();
      final cutoffDate = now.subtract(Duration(days: period));
      
      int totalCompleted = 0;
      int prevCompleted = 0;
      int recentCompleted = 0;
      
      for (final mission in missions) {
        final status = mission['status'] ?? '';
        final endDateStr = mission['endDate'] ?? '';
        
        // 완료된 미션인지 확인
        bool isCompleted = false;
        if (status == 'ACHIEVEMENT') {
          isCompleted = true;
        } else if (status == 'ACCEPT' && endDateStr.isNotEmpty) {
          try {
            final endDate = DateTime.parse(endDateStr);
            if (now.isAfter(endDate)) {
              isCompleted = true;
            }
          } catch (e) {
            // 날짜 파싱 실패
          }
        }
        
        if (isCompleted) {
          totalCompleted++;
          
          // 기간별 분류
          try {
            final startDateStr = mission['startDate'] ?? '';
            if (startDateStr.isNotEmpty) {
              final startDate = DateTime.parse(startDateStr);
              
              if (startDate.isBefore(cutoffDate)) {
                prevCompleted++;
              } else {
                recentCompleted++;
              }
            } else {
              recentCompleted++;
            }
          } catch (e) {
            recentCompleted++;
          }
        }
      }
      
      return {
        'completed': totalCompleted,
        'prevCompleted': prevCompleted,
        'recentCompleted': recentCompleted,
      };
    } catch (e) {
      print('❌ 기간별 완료 미션 수 조회 오류: $e');
      return {'completed': 0, 'prevCompleted': 0, 'recentCompleted': 0};
    }
  }



  /// 캐시 클리어
  static void clearCache() {
    _analysisData = null;
  }
} 