import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/material.dart' as material;
import 'family_service.dart';
import 'auth_service.dart';

class GoalService {
  // API 기본 URL
  static String get baseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'http://3.34.52.239:8080';
  static const storage = FlutterSecureStorage();
  static const String accessTokenKey = 'access_token';

  // 액세스 토큰 가져오기
  static Future<String?> getAccessToken() async {
    return await storage.read(key: accessTokenKey);
  }

  // 목표 신청 API (아이) - 엔드포인트 업데이트
  static Future<Map<String, dynamic>> applyGoal({
    required String title,
    required String category, // "LEARNING" 또는 "HABIT"
    required int reward,
    required DateTime startDate,
    required DateTime endDate,
    required int familyId,
  }) async {
    try {
      String? accessToken = await getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        throw Exception('인증이 필요합니다. 로그인을 다시 시도해주세요.');
      }

      // 현재 요일 구하기 (1: 월요일, 2: 화요일, ..., 7: 일요일)
      final today = DateTime.now();
      final currentDayOfWeek = today.weekday;

      final url = Uri.parse('$baseUrl/api-user/goal/child/apply');
      final Map<String, dynamic> body = {
        'title': title,
        'category': category,
        'reward': reward,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'familyId': familyId,
        // 요일별 체크 정보 - 모두 false로 초기화
        'mon': false,
        'tue': false,
        'wed': false,
        'thu': false,
        'fri': false,
        'sat': false,
        'sun': false,
      };

      print('[GoalService.applyGoal] Request Body: ${jsonEncode(body)}');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(body),
      );

      print(
        '[GoalService.applyGoal] Response Status Code: ${response.statusCode}',
      ); // 응답 상태 코드 로깅
      print(
        '[GoalService.applyGoal] Response Body: ${response.body}',
      ); // 응답 바디 로깅

      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        // 목표 신청 성공 시 부모에게 푸시 알림 전송
        try {
          final int? goalId = responseData['goalId'];
          if (goalId != null) {
            // 현재 사용자 정보 가져오기
            String childName = '자녀'; // 기본값
            try {
              final userInfo = await AuthService.getUserInfo();
              childName = userInfo['name'] ?? '자녀';
              print('현재 사용자 이름: $childName');
            } catch (e) {
              print('사용자 정보 가져오기 실패, 기본값 사용: $e');
            }

            // 부모 정보는 familyId를 통해 가져오거나, 서버에서 자동으로 처리
            await notifyParentOfGoalApplication(
              goalId: goalId,
              goalTitle: title,
              childName: childName, // 실제 사용자 이름 사용
              parentFamilyMemberId: familyId, // 임시로 familyId 사용
            );
          }
        } catch (e) {
          print('푸시 알림 전송 중 오류 (목표 신청은 성공): $e');
        }

        return {'success': true, 'data': responseData};
      } else {
        // 에러 응답 처리
        try {
          final errorBody = jsonDecode(response.body);
          String errorMessage = errorBody['message'] ?? '목표 신청에 실패했습니다.';

          // 이번주에 이미 신청한 목표 유형인 경우 처리
          if (response.statusCode == 400 &&
              errorMessage.contains('이미 신청한 목표')) {
            throw Exception('이번 주에 이미 신청한 목표 유형입니다.');
          }

          throw Exception(errorMessage);
        } catch (e) {
          if (e.toString().contains('이미 신청한 목표')) {
            rethrow;
          }
          throw Exception('목표 신청 실패: ${response.statusCode}');
        }
      }
    } catch (e) {
      if (e.toString().contains('이미 신청한 목표')) {
        rethrow;
      }
      // 네트워크 오류 확인
      if (e.toString().toLowerCase().contains('connection') ||
          e.toString().toLowerCase().contains('network') ||
          e.toString().toLowerCase().contains('socket')) {
        throw Exception('네트워크 연결을 확인해주세요.');
      }

      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // 목표 유형을 API 형식으로 변환
  static String convertGoalTypeToCategory(String goalType) {
    switch (goalType) {
      case '학습 인증':
        return 'LEARNING';
      case '습관 형성':
        return 'HABIT';
      default:
        return 'LEARNING'; // 기본값
    }
  }

  // 요일을 숫자로 변환 (월요일=1, 화요일=2, ..., 일요일=7)
  static int convertDayToNumber(String day) {
    switch (day) {
      case '월':
      case '월요일':
        return 1;
      case '화':
      case '화요일':
        return 2;
      case '수':
      case '수요일':
        return 3;
      case '목':
      case '목요일':
        return 4;
      case '금':
      case '금요일':
        return 5;
      case '토':
      case '토요일':
        return 6;
      case '일':
      case '일요일':
        return 7;
      default:
        return 1; // 기본값: 월요일
    }
  }

  // 숫자를 요일로 변환 (1=월요일, 2=화요일, ..., 7=일요일)
  static String convertNumberToDay(int dayNumber) {
    switch (dayNumber) {
      case 1:
        return '월';
      case 2:
        return '화';
      case 3:
        return '수';
      case 4:
        return '목';
      case 5:
        return '금';
      case 6:
        return '토';
      case 7:
        return '일';
      default:
        return '월'; // 기본값
    }
  }

  // 현재 요일을 숫자로 반환 (월요일=1, 화요일=2, ..., 일요일=7)
  static int getCurrentDayNumber() {
    final now = DateTime.now();
    // DateTime.weekday는 월요일=1, 일요일=7로 반환하므로 그대로 사용
    return now.weekday;
  }

  // 도장 확인 데이터에서 특정 요일의 상태 확인
  static bool isDayChecked(Map<String, dynamic> checkData, int dayNumber) {
    switch (dayNumber) {
      case 1:
        return checkData['mon'] ?? false;
      case 2:
        return checkData['tue'] ?? false;
      case 3:
        return checkData['wed'] ?? false;
      case 4:
        return checkData['thu'] ?? false;
      case 5:
        return checkData['fri'] ?? false;
      case 6:
        return checkData['sat'] ?? false;
      case 7:
        return checkData['sun'] ?? false;
      default:
        return false;
    }
  }

  // 보상금 문자열을 숫자로 변환 (예: "30,000원" -> 30000)
  static int parseRewardAmount(String rewardText) {
    // 숫자가 아닌 문자 제거
    String numbersOnly = rewardText.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(numbersOnly) ?? 0;
  }

  // 선택된 날짜들을 기반으로 시작일과 종료일 계산
  static Map<String, DateTime> calculateDateRange(List<String> selectedDates) {
    if (selectedDates.isEmpty) {
      // 기본값: 오늘부터 일주일
      final now = DateTime.now();
      return {'startDate': now, 'endDate': now.add(const Duration(days: 7))};
    }

    // 선택된 날짜들을 정수로 변환하고 정렬
    final dates =
        selectedDates
            .map((date) => int.tryParse(date))
            .where((date) => date != null)
            .cast<int>()
            .toList()
          ..sort();

    if (dates.isEmpty) {
      final now = DateTime.now();
      return {'startDate': now, 'endDate': now.add(const Duration(days: 7))};
    }

    final now = DateTime.now();
    final currentYear = now.year;
    final currentMonth = now.month;

    // 시작일과 종료일 계산
    final startDate = DateTime(currentYear, currentMonth, dates.first);
    final endDate = DateTime(currentYear, currentMonth, dates.last, 23, 59, 59);

    return {'startDate': startDate, 'endDate': endDate};
  }

  // 목표 신청 수락 API (부모) - 엔드포인트 수정
  static Future<Map<String, dynamic>> acceptGoalApplication(int goalId) async {
    try {
      // 액세스 토큰 가져오기
      String? accessToken = await getAccessToken();

      if (accessToken == null || accessToken.isEmpty) {
        throw Exception('인증이 필요합니다. 로그인을 다시 시도해주세요.');
      }

      final url = Uri.parse(
        '$baseUrl/api-user/goal/parent/apply/accept/$goalId',
      );

      // PATCH 요청 보내기 (바디 없이)
      final response = await http.patch(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      print('목표 수락 요청 - goalId: $goalId');
      print('응답 상태 코드: ${response.statusCode}');
      print('응답 바디: ${response.body}');

      // 응답 확인
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'message': '목표 신청을 수락했습니다.',
          'data': responseData,
        };
      } else {
        // 에러 응답 처리
        try {
          final errorBody = jsonDecode(response.body);
          String errorMessage = errorBody['message'] ?? '목표 수락에 실패했습니다.';

          // 종료 날짜가 지난 경우 특별 처리
          if (response.statusCode == 400 &&
              (errorMessage.contains('종료') ||
                  errorMessage.contains('날짜') ||
                  errorMessage.contains('지났'))) {
            throw Exception('미션 수행 날짜가 지났습니다. 새로운 목표를 신청해주세요.');
          }

          throw Exception(errorMessage);
        } catch (e) {
          if (e.toString().contains('미션 수행 날짜가 지났습니다')) {
            rethrow;
          }
          throw Exception('목표 수락 실패: ${response.statusCode}');
        }
      }
    } catch (e) {
      if (e.toString().contains('미션 수행 날짜가 지났습니다')) {
        rethrow;
      }
      // 네트워크 오류 확인
      if (e.toString().toLowerCase().contains('connection') ||
          e.toString().toLowerCase().contains('network') ||
          e.toString().toLowerCase().contains('socket')) {
        throw Exception('네트워크 연결을 확인해주세요.');
      }

      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // 목표 신청 거절 API (부모)
  static Future<Map<String, dynamic>> rejectGoalApplication(int goalId) async {
    try {
      // 액세스 토큰 가져오기
      String? accessToken = await getAccessToken();

      if (accessToken == null || accessToken.isEmpty) {
        throw Exception('인증이 필요합니다. 로그인을 다시 시도해주세요.');
      }

      final url = Uri.parse(
        '$baseUrl/api-user/goal/parent/apply/reject/$goalId',
      );

      // PATCH 요청 보내기
      final response = await http.patch(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      print('목표 거절 요청 - goalId: $goalId');
      print('응답 상태 코드: ${response.statusCode}');
      print('응답 바디: ${response.body}');

      // 응답 확인
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'message': '목표 신청을 거절했습니다.',
          'data': responseData,
        };
      } else {
        // 에러 응답 처리
        try {
          final errorBody = jsonDecode(response.body);
          String errorMessage = errorBody['message'] ?? '목표 거절에 실패했습니다.';
          throw Exception(errorMessage);
        } catch (e) {
          throw Exception('목표 거절 실패: ${response.statusCode}');
        }
      }
    } catch (e) {
      // 네트워크 오류 확인
      if (e.toString().toLowerCase().contains('connection') ||
          e.toString().toLowerCase().contains('network') ||
          e.toString().toLowerCase().contains('socket')) {
        throw Exception('네트워크 연결을 확인해주세요.');
      }

      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // 목표 신청 알림 목록 가져오기 API (부모)
  static Future<List<Map<String, dynamic>>?>
  getGoalApplicationNotifications() async {
    try {
      print('===== 목표 신청 알림 목록 API 호출 시작 =====');

      // 가족 정보 먼저 가져오기
      final familyInfo = await FamilyService.getFamilyInfo();
      if (familyInfo == null) {
        print('가족 정보를 가져올 수 없습니다.');
        return [];
      }

      final int familyId = familyInfo['familyId'];
      print('familyId: $familyId로 목표 신청 알림 조회');

      // 1차: 이번 주 + 다음 주 목표에서 REQUESTED 상태 조회
      print('이번 주 + 다음 주 목표에서 REQUESTED 상태 목표 조회...');
      final weeklyRequested = await _getRequestedGoalsFromWeekly(familyId);

      if (weeklyRequested != null && weeklyRequested.isNotEmpty) {
        print('주간 목표에서 ${weeklyRequested.length}개 REQUESTED 목표 발견');
        return weeklyRequested;
      }

      // 2차: 전체 목표에서 REQUESTED 상태 조회 (백업 방법)
      print('전체 목표에서 REQUESTED 상태 목표 조회...');
      final allRequested = await _getAllRequestedGoals();

      if (allRequested != null && allRequested.isNotEmpty) {
        print('전체 목표에서 ${allRequested.length}개 REQUESTED 목표 발견');
        return allRequested;
      }

      print('REQUESTED 상태 목표를 찾지 못했습니다.');
      return [];
    } catch (e) {
      print('목표 신청 알림 목록 조회 중 오류: $e');
      print('===== 목표 신청 알림 목록 API 호출 실패 =====');

      // 네트워크 오류인 경우 null 반환
      if (e.toString().toLowerCase().contains('connection') ||
          e.toString().toLowerCase().contains('network') ||
          e.toString().toLowerCase().contains('socket')) {
        print('네트워크 연결 오류');
        return null;
      }

      // 인증 오류인 경우 예외 재발생
      if (e.toString().contains('인증') || e.toString().contains('로그인')) {
        rethrow;
      }

      // 기타 오류의 경우 빈 배열 반환
      return [];
    }
  }

  // 모든 REQUESTED 상태 목표를 조회하는 새로운 메서드
  static Future<List<Map<String, dynamic>>?> _getAllRequestedGoals() async {
    try {
      print('===== 모든 REQUESTED 상태 목표 조회 시작 =====');

      // 액세스 토큰 가져오기
      String? accessToken = await getAccessToken();

      if (accessToken == null || accessToken.isEmpty) {
        print('액세스 토큰이 없습니다.');
        throw Exception('인증이 필요합니다. 로그인을 다시 시도해주세요.');
      }

      // 먼저 가족 정보를 가져와서 familyId 확보
      final familyInfo = await FamilyService.getFamilyInfo();
      if (familyInfo == null) {
        print('가족 정보를 가져올 수 없습니다.');
        return [];
      }

      final int familyId = familyInfo['familyId'];
      print('가족 ID: $familyId');

      // 여러 방법으로 REQUESTED 상태 목표 찾기
      List<Map<String, dynamic>> allRequestedGoals = [];

      // 1. 이번 주 목표에서 REQUESTED 상태 찾기
      try {
        final weeklyGoals = await getParentWeeklyGoals(familyId);
        if (weeklyGoals != null) {
          final weeklyRequested =
              weeklyGoals
                  .where((goal) => goal['status'] == 'REQUESTED')
                  .toList();
          print('이번 주 REQUESTED 목표: ${weeklyRequested.length}개');
          allRequestedGoals.addAll(weeklyRequested);
        }
      } catch (e) {
        print('이번 주 목표 조회 중 오류: $e');
      }

      // 1-1. 다른 주차 목표도 시도해보기 (지난주, 다음주)
      try {
        print('다른 주차 목표 조회 시도...');
        final otherWeekEndpoints = [
          '/api-user/goal/parent/weekly/$familyId?week=last',
          '/api-user/goal/parent/weekly/$familyId?week=next',
          '/api-user/goal/parent/weekly/$familyId?week=all',
          '/api-user/goal/parent/recent/$familyId',
          '/api-user/goal/parent/latest/$familyId',
        ];

        for (String endpoint in otherWeekEndpoints) {
          try {
            print('다른 주차 조회 시도: $endpoint');
            final url = Uri.parse('$baseUrl$endpoint');

            final response = await http.get(
              url,
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $accessToken',
              },
            );

            if (response.statusCode == 200) {
              final responseData = jsonDecode(response.body);
              if (responseData is List) {
                final otherGoals = responseData.cast<Map<String, dynamic>>();
                final requestedFromOther =
                    otherGoals
                        .where((goal) => goal['status'] == 'REQUESTED')
                        .toList();
                print('다른 주차에서 REQUESTED: ${requestedFromOther.length}개');

                for (var goal in requestedFromOther) {
                  if (!allRequestedGoals.any(
                    (existing) => existing['goalId'] == goal['goalId'],
                  )) {
                    allRequestedGoals.add(goal);
                  }
                }
              }
            }
          } catch (e) {
            print('$endpoint 조회 실패: $e');
            continue;
          }
        }
      } catch (e) {
        print('다른 주차 목표 조회 중 오류: $e');
      }

      // 2. 전체 목표 조회 API 시도 (다양한 엔드포인트 시도)
      final possibleEndpoints = [
        '/api-user/goal/parent/all/$familyId',
        '/api-user/goal/parent/list/$familyId',
        '/api-user/goal/parent/$familyId',
        '/api-user/goal/all/$familyId',
      ];

      for (String endpoint in possibleEndpoints) {
        try {
          print('전체 목표 조회 시도: $endpoint');
          final url = Uri.parse('$baseUrl$endpoint');

          final response = await http.get(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $accessToken',
            },
          );

          print('응답 상태: ${response.statusCode}');

          if (response.statusCode == 200) {
            final responseData = jsonDecode(response.body);
            print('전체 목표 조회 성공: $endpoint');
            print('응답 데이터: $responseData');

            if (responseData is List) {
              final allGoals = responseData.cast<Map<String, dynamic>>();
              final requestedFromAll =
                  allGoals
                      .where((goal) => goal['status'] == 'REQUESTED')
                      .toList();
              print('전체 목표 중 REQUESTED: ${requestedFromAll.length}개');

              // 중복 제거하면서 추가
              for (var goal in requestedFromAll) {
                if (!allRequestedGoals.any(
                  (existing) => existing['goalId'] == goal['goalId'],
                )) {
                  allRequestedGoals.add(goal);
                }
              }
              break; // 성공하면 다른 엔드포인트 시도 중단
            }
          }
        } catch (e) {
          print('$endpoint 조회 실패: $e');
          continue; // 다음 엔드포인트 시도
        }
      }

      print('총 발견된 REQUESTED 목표: ${allRequestedGoals.length}개');

      // 목표 신청 알림 형태로 변환
      final notifications =
          allRequestedGoals.map((goal) {
            return {
              'goalId': goal['goalId'],
              'title': goal['title'],
              'category': goal['category'],
              'childName': goal['childNickname'] ?? goal['childName'] ?? '자녀',
              'familyMemberId': goal['familyMemberId'],
              'createdAt':
                  goal['startDate'] ??
                  goal['createdAt'] ??
                  DateTime.now().toIso8601String(),
              'read': false,
            };
          }).toList();

      print('목표 신청 알림 형태로 변환 완료: ${notifications.length}개');
      return notifications;
    } catch (e) {
      print('모든 REQUESTED 목표 조회 중 오류: $e');
      return [];
    }
  }

  // 이번 주 목표에서 REQUESTED 상태인 목표들을 추출하는 메서드
  static Future<List<Map<String, dynamic>>?> _getRequestedGoalsFromWeekly(
    int familyId,
  ) async {
    try {
      print('===== 이번 주 + 다음 주 목표에서 REQUESTED 상태 추출 시작 =====');
      print('전달받은 가족 ID: $familyId');

      List<Map<String, dynamic>> allRequestedGoals = [];

      // 1. 이번 주 목표 조회
      final weeklyGoals = await getParentWeeklyGoals(familyId);
      if (weeklyGoals != null) {
        print('이번 주 목표 ${weeklyGoals.length}개 조회됨');
        final requestedGoals =
            weeklyGoals.where((goal) => goal['status'] == 'REQUESTED').toList();
        print('이번 주 REQUESTED 상태인 목표 ${requestedGoals.length}개 발견');
        allRequestedGoals.addAll(requestedGoals);
      }

      // 2. 다음 주 목표도 조회 (6월 2일자 목표를 위해)
      try {
        print('다음 주 목표 조회 시도...');
        String? accessToken = await getAccessToken();
        if (accessToken != null) {
          // 다음 주 목표 조회를 위한 다양한 엔드포인트 시도
          final nextWeekEndpoints = [
            '/api-user/goal/parent/weekly/$familyId?week=next',
            '/api-user/goal/parent/weekly/$familyId?offset=1',
            '/api-user/goal/parent/all/$familyId',
          ];

          for (String endpoint in nextWeekEndpoints) {
            try {
              print('다음 주 목표 조회 시도: $endpoint');
              final url = Uri.parse('$baseUrl$endpoint');

              final response = await http.get(
                url,
                headers: {
                  'Content-Type': 'application/json',
                  'Authorization': 'Bearer $accessToken',
                },
              );

              if (response.statusCode == 200) {
                final responseData = jsonDecode(response.body);
                if (responseData is List) {
                  final nextWeekGoals =
                      responseData.cast<Map<String, dynamic>>();
                  final nextWeekRequested =
                      nextWeekGoals
                          .where((goal) => goal['status'] == 'REQUESTED')
                          .toList();
                  print('다음 주에서 REQUESTED: ${nextWeekRequested.length}개');

                  // 중복 제거하면서 추가
                  for (var goal in nextWeekRequested) {
                    if (!allRequestedGoals.any(
                      (existing) => existing['goalId'] == goal['goalId'],
                    )) {
                      allRequestedGoals.add(goal);
                    }
                  }

                  if (nextWeekRequested.isNotEmpty) {
                    break; // 성공하면 다른 엔드포인트 시도 중단
                  }
                }
              }
            } catch (e) {
              print('$endpoint 조회 실패: $e');
              continue;
            }
          }
        }
      } catch (e) {
        print('다음 주 목표 조회 중 오류: $e');
      }

      print('총 발견된 REQUESTED 목표: ${allRequestedGoals.length}개');

      // REQUESTED 상태 목표가 없으면 빈 배열 반환
      if (allRequestedGoals.isEmpty) {
        print('⚠️ 서버 API에서 REQUESTED 목표를 찾지 못함');
        return [];
      }

      // 목표 신청 알림 형태로 변환
      final notifications =
          allRequestedGoals.map((goal) {
            return {
              'goalId': goal['goalId'],
              'title': goal['title'],
              'category': goal['category'],
              'childName': goal['childNickname'] ?? goal['childName'] ?? '자녀',
              'familyMemberId': goal['familyMemberId'],
              'createdAt':
                  goal['startDate'] ??
                  goal['createdAt'] ??
                  DateTime.now().toIso8601String(),
              'read': false,
              'reward': goal['reward'] ?? 30000, // 실제 보상금 추가
              'startDate': goal['startDate'], // 시작일 추가
              'endDate': goal['endDate'], // 종료일 추가
            };
          }).toList();

      print('목표 신청 알림 형태로 변환 완료: ${notifications.length}개');
      return notifications;
    } catch (e) {
      print('REQUESTED 목표 추출 중 오류: $e');
      return [];
    }
  }

  // 부모용 이번 주 아이들의 목표 조회 API
  static Future<List<Map<String, dynamic>>?> getParentWeeklyGoals(
    int familyId,
  ) async {
    try {
      print('===== 부모용 이번 주 아이들 목표 조회 API 호출 시작 =====');

      // 액세스 토큰 가져오기
      String? accessToken = await getAccessToken();

      if (accessToken == null || accessToken.isEmpty) {
        print('액세스 토큰이 없습니다.');
        throw Exception('인증이 필요합니다. 로그인을 다시 시도해주세요.');
      }

      print('액세스 토큰 확인 완료');

      final url = Uri.parse('$baseUrl/api-user/goal/parent/weekly/$familyId');
      print('요청 URL: $url');
      print('familyId: $familyId로 이번 주 목표 조회 중...');

      // GET 요청 보내기
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      print('부모용 이번 주 목표 조회 요청');
      print('응답 상태 코드: ${response.statusCode}');
      print('응답 바디: ${response.body}');

      // 디버깅: 다른 API도 시도해보기
      if (response.statusCode == 200 && jsonDecode(response.body).isEmpty) {
        print('===== 다른 API 엔드포인트들 시도 =====');

        // 1. 특정 goalId로 직접 조회 시도
        try {
          final directGoalUrl = Uri.parse(
            '$baseUrl/api-user/goal/3',
          ); // goalId=3 직접 조회
          final directGoalResponse = await http.get(
            directGoalUrl,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $accessToken',
            },
          );
          print(
            '🔍 직접 목표 조회 (goalId=3): ${directGoalResponse.statusCode} - ${directGoalResponse.body}',
          );
        } catch (e) {
          print('직접 목표 조회 실패: $e');
        }

        // 2. 부모의 모든 목표 조회 (페이징 없이)
        try {
          final parentAllUrl = Uri.parse(
            '$baseUrl/api-user/goal/parent/$familyId',
          );
          final parentAllResponse = await http.get(
            parentAllUrl,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $accessToken',
            },
          );
          print(
            '🔍 부모 전체 목표 조회: ${parentAllResponse.statusCode} - ${parentAllResponse.body}',
          );

          if (parentAllResponse.statusCode == 200) {
            final parentData = jsonDecode(parentAllResponse.body);
            if (parentData is List && parentData.isNotEmpty) {
              print('✅ 부모 전체 목표에서 데이터 발견! 사용');
              return parentData.cast<Map<String, dynamic>>();
            }
          }
        } catch (e) {
          print('부모 전체 목표 조회 실패: $e');
        }

        // 3. 시간대 문제를 고려한 다른 주차 API들 시도
        final now = DateTime.now();
        final utcNow = now.toUtc();
        final kstDateStr = now.toIso8601String().substring(0, 10); // 2025-05-26
        final utcDateStr = utcNow.toIso8601String().substring(0, 10);

        print('🕐 시간대 디버깅:');
        print('   KST 현재: $now');
        print('   UTC 현재: $utcNow');
        print('   KST 날짜: $kstDateStr');
        print('   UTC 날짜: $utcDateStr');

        final weeklyVariations = [
          'weekly/$familyId?timezone=KST',
          'weekly/$familyId?timezone=UTC',
          'weekly/$familyId?date=$kstDateStr',
          'weekly/$familyId?date=$utcDateStr',
          'weekly/$familyId?week=current',
          'weekly/$familyId?offset=0',
          'weekly/$familyId?start=2025-05-26',
          'weekly/$familyId?end=2025-06-01',
          'weekly/$familyId?start=${kstDateStr}T00:00:00',
          'weekly/$familyId?start=${utcDateStr}T00:00:00',
        ];

        for (String variation in weeklyVariations) {
          try {
            final varUrl = Uri.parse(
              '$baseUrl/api-user/goal/parent/$variation',
            );
            final varResponse = await http.get(
              varUrl,
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $accessToken',
              },
            );
            print(
              '🔍 주차 변형 시도 ($variation): ${varResponse.statusCode} - ${varResponse.body}',
            );

            if (varResponse.statusCode == 200) {
              final varData = jsonDecode(varResponse.body);
              if (varData is List && varData.isNotEmpty) {
                print('✅ 주차 변형에서 목표 발견! 사용');
                return varData.cast<Map<String, dynamic>>();
              }
            }
          } catch (e) {
            print('주차 변형 시도 실패 ($variation): $e');
          }
        }

        // 4. 아이 계정 API로 시도 (우회 방법)
        final childWeeklyUrl = Uri.parse('$baseUrl/api-user/goal/child/weekly');
        final childWeeklyResponse = await http.get(
          childWeeklyUrl,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $accessToken',
          },
        );
        print(
          '🔍 아이 주간 목표 조회 (/child/weekly): ${childWeeklyResponse.statusCode} - ${childWeeklyResponse.body}',
        );

        // 만약 아이 API에서 데이터가 나오면 그것을 사용
        if (childWeeklyResponse.statusCode == 200) {
          final childData = jsonDecode(childWeeklyResponse.body);
          if (childData is List && childData.isNotEmpty) {
            print('✅ 아이 API에서 목표 발견! 부모 API 대신 사용');
            return childData.cast<Map<String, dynamic>>();
          }
        }

        // 5. 전체 목표 조회 시도
        final allGoalsUrl = Uri.parse(
          '$baseUrl/api-user/goal/parent/all/$familyId',
        );
        final allGoalsResponse = await http.get(
          allGoalsUrl,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $accessToken',
          },
        );
        print(
          '🔍 전체 목표 조회 (/all): ${allGoalsResponse.statusCode} - ${allGoalsResponse.body}',
        );

        print('===== 다른 API 엔드포인트 시도 완료 =====');
      }

      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final weekEnd = weekStart.add(Duration(days: 6));
      print('현재 날짜: $now');
      print('이번 주 시작: $weekStart');
      print('이번 주 끝: $weekEnd');

      // 응답 확인
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData is List) {
          print('이번 주 아이들 목표 ${responseData.length}개 조회 성공');
          return responseData.cast<Map<String, dynamic>>();
        } else {
          print('응답 데이터가 List 형태가 아닙니다: ${responseData.runtimeType}');
          return [];
        }
      } else if (response.statusCode == 500) {
        print('서버 내부 오류 발생 - 서버 개발팀에 문의 필요');
        return [];
      } else if (response.statusCode == 404) {
        print('API 엔드포인트를 찾을 수 없습니다 - URL 확인 필요');
        return [];
      } else if (response.statusCode == 401) {
        print('인증 실패 - 토큰 만료 또는 잘못된 토큰');
        throw Exception('인증이 만료되었습니다. 다시 로그인해주세요.');
      } else if (response.statusCode == 403) {
        print('권한 없음 - 부모 계정이 아니거나 권한 부족');
        return [];
      } else {
        print('이번 주 아이들 목표 조회 실패: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('이번 주 아이들 목표 조회 중 오류: $e');
      print('===== 부모용 이번 주 아이들 목표 조회 API 호출 실패 =====');

      // 네트워크 오류인 경우 null 반환
      if (e.toString().toLowerCase().contains('connection') ||
          e.toString().toLowerCase().contains('network') ||
          e.toString().toLowerCase().contains('socket')) {
        print('네트워크 연결 오류');
        return null;
      }

      // 인증 오류인 경우 예외 재발생
      if (e.toString().contains('인증') || e.toString().contains('로그인')) {
        rethrow;
      }

      // 기타 오류의 경우 빈 배열 반환
      return [];
    }
  }

  // 아이용 이번 주 목표 조회 API
  static Future<List<Map<String, dynamic>>?> getChildWeeklyGoals() async {
    try {
      print('===== 아이용 이번 주 목표 조회 API 호출 시작 =====');

      // 액세스 토큰 가져오기
      String? accessToken = await getAccessToken();

      if (accessToken == null || accessToken.isEmpty) {
        print('액세스 토큰이 없습니다.');
        throw Exception('인증이 필요합니다. 로그인을 다시 시도해주세요.');
      }

      print('액세스 토큰 확인 완료');

      final url = Uri.parse('$baseUrl/api-user/goal/child/weekly');
      print('요청 URL: $url');

      // GET 요청 보내기
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      print('아이용 이번 주 목표 조회 요청');
      print('응답 상태 코드: ${response.statusCode}');
      print('응답 바디: ${response.body}');

      // 응답 확인
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData is List) {
          print('이번 주 목표 ${responseData.length}개 조회 성공');
          return responseData.cast<Map<String, dynamic>>();
        } else {
          print('응답 데이터가 List 형태가 아닙니다: ${responseData.runtimeType}');
          return [];
        }
      } else if (response.statusCode == 500) {
        print('서버 내부 오류 발생 - 서버 개발팀에 문의 필요');
        return [];
      } else if (response.statusCode == 404) {
        print('API 엔드포인트를 찾을 수 없습니다 - URL 확인 필요');
        return [];
      } else if (response.statusCode == 401) {
        print('인증 실패 - 토큰 만료 또는 잘못된 토큰');
        throw Exception('인증이 만료되었습니다. 다시 로그인해주세요.');
      } else if (response.statusCode == 403) {
        print('권한 없음 - 아이 계정이 아니거나 권한 부족');
        return [];
      } else {
        print('이번 주 목표 조회 실패: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('이번 주 목표 조회 중 오류: $e');
      print('===== 아이용 이번 주 목표 조회 API 호출 실패 =====');

      // 네트워크 오류인 경우 null 반환
      if (e.toString().toLowerCase().contains('connection') ||
          e.toString().toLowerCase().contains('network') ||
          e.toString().toLowerCase().contains('socket')) {
        print('네트워크 연결 오류');
        return null;
      }

      // 인증 오류인 경우 예외 재발생
      if (e.toString().contains('인증') || e.toString().contains('로그인')) {
        rethrow;
      }

      // 기타 오류의 경우 빈 배열 반환
      return [];
    }
  }

  // 아이용 모든 목표 조회 API - 새로 추가
  static Future<List<Map<String, dynamic>>?> getChildAllGoals() async {
    try {
      print('===== 아이용 모든 목표 조회 API 호출 시작 =====');

      // 액세스 토큰 가져오기
      String? accessToken = await getAccessToken();

      if (accessToken == null || accessToken.isEmpty) {
        print('액세스 토큰이 없습니다.');
        throw Exception('인증이 필요합니다. 로그인을 다시 시도해주세요.');
      }

      print('액세스 토큰 확인 완료');

      final url = Uri.parse('$baseUrl/api-user/goal/child/all');
      print('요청 URL: $url');

      // GET 요청 보내기
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      print('아이용 모든 목표 조회 요청');
      print('응답 상태 코드: ${response.statusCode}');
      print('응답 바디: ${response.body}');

      // 응답 확인
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData is List) {
          print('모든 목표 ${responseData.length}개 조회 성공');
          return responseData.cast<Map<String, dynamic>>();
        } else {
          print('응답 데이터가 List 형태가 아닙니다: ${responseData.runtimeType}');
          return [];
        }
      } else if (response.statusCode == 500) {
        print('서버 내부 오류 발생 - 서버 개발팀에 문의 필요');
        return [];
      } else if (response.statusCode == 404) {
        print('API 엔드포인트를 찾을 수 없습니다 - URL 확인 필요');
        return [];
      } else if (response.statusCode == 401) {
        print('인증 실패 - 토큰 만료 또는 잘못된 토큰');
        throw Exception('인증이 만료되었습니다. 다시 로그인해주세요.');
      } else if (response.statusCode == 403) {
        print('권한 없음 - 아이 계정이 아니거나 권한 부족');
        return [];
      } else {
        print('모든 목표 조회 실패: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('아이들의 모든 목표 조회 중 오류: $e');
      print('===== 아이용 모든 목표 조회 API 호출 실패 =====');

      // 네트워크 오류인 경우 null 반환
      if (e.toString().toLowerCase().contains('connection') ||
          e.toString().toLowerCase().contains('network') ||
          e.toString().toLowerCase().contains('socket')) {
        print('네트워크 연결 오류');
        return null;
      }

      // 인증 오류인 경우 예외 재발생
      if (e.toString().contains('인증') || e.toString().contains('로그인')) {
        rethrow;
      }

      // 기타 오류의 경우 빈 배열 반환
      return [];
    }
  }

  // 목표 상태에 따른 진행 상태 텍스트 반환 (새 필드 반영)
  static String getGoalStatusText(Map<String, dynamic> goal) {
    final String status = goal['status'] ?? '';

    switch (status) {
      case 'REQUESTED':
        return '요청 상태';
      case 'ACCEPT':
        // 시작날짜와 종료날짜를 확인하여 진행 상태 결정
        try {
          final String? startDateStr = goal['startDate'];
          final String? endDateStr = goal['endDate'];

          if (startDateStr != null && endDateStr != null) {
            final DateTime startDate = DateTime.parse(startDateStr);
            final DateTime endDate = DateTime.parse(endDateStr);
            final DateTime now = DateTime.now();

            if (now.isBefore(startDate)) {
              return '진행 대기';
            } else if (now.isAfter(endDate)) {
              // 기간이 만료된 경우 달성 여부에 따라 구분
              final bool isAchieved = isGoalAchieved(goal);
              if (isAchieved) {
                final bool isRewarded = isGoalRewarded(goal);
                return isRewarded ? '달성 완료' : '보상 대기중';
              } else {
                return '기간 만료';
              }
            } else {
              // 진행 중인 경우 달성률 표시
              final String progressText = getGoalProgressText(goal);
              // 0/0인 경우 진행률 표시 생략
              if (progressText == '0/0') {
                return '진행 중';
              }
              return '진행 중 ($progressText)';
            }
          }
          return '수락됨';
        } catch (e) {
          print('날짜 파싱 오류: $e');
          return '수락됨';
        }
      case 'ACHIEVEMENT':
        // ACHIEVEMENT 상태에서도 보상 지급 여부 확인
        final bool isRewarded = isGoalRewarded(goal);
        return isRewarded ? '달성 완료' : '보상 대기중';
      default:
        return '알 수 없음';
    }
  }

  // 목표 카테고리를 한국어로 변환
  static String getCategoryText(String category) {
    switch (category) {
      case 'LEARNING':
        return '학습 인증';
      case 'HABIT':
        return '습관 형성';
      default:
        return category;
    }
  }

  // 목표 상태에 따른 색상 반환 (새 필드 반영)
  static material.Color getGoalStatusColor(Map<String, dynamic> goal) {
    final String status = goal['status'] ?? '';
    final String statusText = getGoalStatusText(goal);

    switch (status) {
      case 'REQUESTED':
        return const material.Color(0xFFFFD27F); // 주황색 (요청 상태)
      case 'ACCEPT':
        // 상세 상태에 따라 색상 결정
        if (statusText == '진행 대기') {
          return const material.Color(0xFF5D9EFF); // 파란색 (진행 대기)
        } else if (statusText.contains('진행 중')) {
          // 달성률에 따른 초록색 농도 조절
          final double achievementRate = getGoalAchievementRate(goal);
          if (achievementRate >= 80) {
            return const material.Color(0xFF2E7D32); // 진한 초록색 (80% 이상)
          } else if (achievementRate >= 50) {
            return const material.Color(0xFF4CAF50); // 초록색 (50-80%)
          } else {
            return const material.Color(0xFF81C784); // 연한 초록색 (50% 미만)
          }
        } else if (statusText == '보상 대기중') {
          return const material.Color(0xFFFF9800); // 주황색 (보상 대기)
        } else if (statusText == '달성 완료') {
          return const material.Color(0xFF9C27B0); // 보라색 (달성 완료)
        } else {
          return const material.Color(0xFF999999); // 회색 (기간 만료)
        }
      case 'ACHIEVEMENT':
        // 보상 지급 여부에 따라 색상 구분
        final bool isRewarded = isGoalRewarded(goal);
        if (isRewarded) {
          return const material.Color(0xFF9C27B0); // 보라색 (달성 완료)
        } else {
          return const material.Color(0xFFFF9800); // 주황색 (보상 대기)
        }
      default:
        return const material.Color(0xFF999999); // 회색 (알 수 없음)
    }
  }

  // 달성률에 따른 프로그레스 바 색상 반환
  static material.Color getProgressBarColor(Map<String, dynamic> goal) {
    final double achievementRate = getGoalAchievementRate(goal);

    if (achievementRate >= 100) {
      return const material.Color(0xFF4CAF50); // 초록색 (100% 달성)
    } else if (achievementRate >= 80) {
      return const material.Color(0xFF8BC34A); // 연한 초록색 (80% 이상)
    } else if (achievementRate >= 50) {
      return const material.Color(0xFFFFEB3B); // 노란색 (50-80%)
    } else if (achievementRate >= 25) {
      return const material.Color(0xFFFF9800); // 주황색 (25-50%)
    } else {
      return const material.Color(0xFFF44336); // 빨간색 (25% 미만)
    }
  }

  // FCM 토큰을 서버에 등록 (PushNotificationService와 연동)
  static Future<bool> registerFCMToken() async {
    try {
      // PushNotificationService에서 이미 토큰 등록을 처리하므로
      // 여기서는 토큰이 제대로 등록되었는지만 확인
      String? fcmToken = await storage.read(key: 'fcmToken');

      if (fcmToken != null && fcmToken.isNotEmpty) {
        print('FCM 토큰이 이미 등록되어 있습니다: ${fcmToken.substring(0, 20)}...');
        return true;
      } else {
        print('FCM 토큰이 등록되지 않았습니다.');
        return false;
      }
    } catch (e) {
      print('FCM 토큰 확인 중 오류: $e');
      return false;
    }
  }

  // 목표 신청 시 부모에게 푸시 알림 전송 요청 (서버에서 처리)
  static Future<void> notifyParentOfGoalApplication({
    required int goalId,
    required String goalTitle,
    required String childName,
    required int parentFamilyMemberId,
  }) async {
    try {
      print('===== 목표 신청 푸시 알림 요청 시작 =====');

      String? accessToken = await getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        print('액세스 토큰이 없어 푸시 알림 요청을 건너뜁니다.');
        return;
      }

      final url = Uri.parse('$baseUrl/api-user/notifications/goal-application');

      final Map<String, dynamic> body = {
        'goalId': goalId,
        'goalTitle': goalTitle,
        'childName': childName,
        'parentFamilyMemberId': parentFamilyMemberId,
        'type': 'GOAL_APPLICATION',
      };

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(body),
      );

      print('푸시 알림 요청 응답: ${response.statusCode}');
      print('푸시 알림 요청 바디: ${response.body}');

      if (response.statusCode == 200) {
        print('✅ 부모에게 목표 신청 푸시 알림 전송 요청 성공');
      } else {
        print('⚠️ 푸시 알림 전송 요청 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('푸시 알림 전송 요청 중 오류: $e');
      // 푸시 알림 실패는 목표 신청 자체를 실패시키지 않음
    }
  }

  // 도장 확인 API (공통) - 새로 추가
  static Future<Map<String, dynamic>?> getGoalCheck(int goalId) async {
    try {
      print('===== 도장 확인 API 호출 시작 =====');

      // 액세스 토큰 가져오기
      String? accessToken = await getAccessToken();

      if (accessToken == null || accessToken.isEmpty) {
        throw Exception('인증이 필요합니다. 로그인을 다시 시도해주세요.');
      }

      final url = Uri.parse('$baseUrl/api-user/goal/check/$goalId');
      print('요청 URL: $url');

      // GET 요청 보내기
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      print('도장 확인 요청 - goalId: $goalId');
      print('응답 상태 코드: ${response.statusCode}');
      print('응답 바디: ${response.body}');

      // 응답 확인
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('도장 확인 조회 성공');
        return responseData;
      } else {
        print('도장 확인 조회 실패: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('도장 확인 조회 중 오류: $e');

      // 네트워크 오류인 경우 null 반환
      if (e.toString().toLowerCase().contains('connection') ||
          e.toString().toLowerCase().contains('network') ||
          e.toString().toLowerCase().contains('socket')) {
        print('네트워크 연결 오류');
        return null;
      }

      // 인증 오류인 경우 예외 재발생
      if (e.toString().contains('인증') || e.toString().contains('로그인')) {
        rethrow;
      }

      return null;
    }
  }

  // 확인 도장 찍기 API (부모) - 새로 추가
  static Future<Map<String, dynamic>> stampGoalCheck(
    int goalId,
    int day,
  ) async {
    try {
      print('===== 확인 도장 찍기 API 호출 시작 =====');

      // 액세스 토큰 가져오기
      String? accessToken = await getAccessToken();

      if (accessToken == null || accessToken.isEmpty) {
        throw Exception('인증이 필요합니다. 로그인을 다시 시도해주세요.');
      }

      // 현재 요일 확인 (1: 월요일, 2: 화요일, ..., 7: 일요일)
      final today = DateTime.now();
      final currentDayOfWeek = today.weekday;

      // 과거 날짜의 도장은 찍을 수 없음
      if (day < currentDayOfWeek) {
        throw Exception('이전 요일의 도장은 찍을 수 없습니다.');
      }

      final url = Uri.parse(
        '$baseUrl/api-user/goal/parent/check/$goalId?day=$day',
      );
      print('요청 URL: $url');
      print('goalId: $goalId, day: $day');

      // PATCH 요청 보내기
      final response = await http.patch(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      print('확인 도장 찍기 요청');
      print('응답 상태 코드: ${response.statusCode}');
      print('응답 바디: ${response.body}');

      // 응답 확인
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'message': '확인 도장을 찍었습니다.',
          'data': responseData,
        };
      } else {
        // 에러 응답 처리
        try {
          final errorBody = jsonDecode(response.body);
          String errorMessage = errorBody['message'] ?? '확인 도장 찍기에 실패했습니다.';

          // 특정 에러 상황에 대한 처리
          if (response.statusCode == 400) {
            if (errorMessage.contains('이전 요일')) {
              throw Exception('이전 요일의 도장은 찍을 수 없습니다.');
            } else if (errorMessage.contains('미래 요일')) {
              throw Exception('미래 요일의 도장은 미리 찍을 수 없습니다.');
            }
          }

          throw Exception(errorMessage);
        } catch (e) {
          if (e.toString().contains('이전 요일') ||
              e.toString().contains('미래 요일')) {
            rethrow;
          }
          throw Exception('확인 도장 찍기 실패: ${response.statusCode}');
        }
      }
    } catch (e) {
      // 특정 에러 메시지 재전달
      if (e.toString().contains('이전 요일') || e.toString().contains('미래 요일')) {
        rethrow;
      }

      // 네트워크 오류 확인
      if (e.toString().toLowerCase().contains('connection') ||
          e.toString().toLowerCase().contains('network') ||
          e.toString().toLowerCase().contains('socket')) {
        throw Exception('네트워크 연결을 확인해주세요.');
      }

      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // 아이들의 모든 목표 조회 API (부모) - 새로 추가
  static Future<List<Map<String, dynamic>>?> getParentAllGoals(
    int familyId,
  ) async {
    try {
      print('===== 부모용 아이들의 모든 목표 조회 API 호출 시작 =====');

      // 액세스 토큰 가져오기
      String? accessToken = await getAccessToken();

      if (accessToken == null || accessToken.isEmpty) {
        print('액세스 토큰이 없습니다.');
        throw Exception('인증이 필요합니다. 로그인을 다시 시도해주세요.');
      }

      print('액세스 토큰 확인 완료');

      final url = Uri.parse('$baseUrl/api-user/goal/parent/all/$familyId');
      print('요청 URL: $url');
      print('familyId: $familyId로 모든 목표 조회 중...');

      // GET 요청 보내기
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      print('부모용 모든 목표 조회 요청');
      print('응답 상태 코드: ${response.statusCode}');
      print('응답 바디: ${response.body}');

      // 응답 확인
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData is List) {
          print('아이들의 모든 목표 ${responseData.length}개 조회 성공');
          return responseData.cast<Map<String, dynamic>>();
        } else {
          print('응답 데이터가 List 형태가 아닙니다: ${responseData.runtimeType}');
          return [];
        }
      } else if (response.statusCode == 500) {
        print('서버 내부 오류 발생 - 서버 개발팀에 문의 필요');
        return [];
      } else if (response.statusCode == 404) {
        print('API 엔드포인트를 찾을 수 없습니다 - URL 확인 필요');
        return [];
      } else if (response.statusCode == 401) {
        print('인증 실패 - 토큰 만료 또는 잘못된 토큰');
        throw Exception('인증이 만료되었습니다. 다시 로그인해주세요.');
      } else if (response.statusCode == 403) {
        print('권한 없음 - 부모 계정이 아니거나 권한 부족');
        return [];
      } else {
        print('아이들의 모든 목표 조회 실패: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('아이들의 모든 목표 조회 중 오류: $e');
      print('===== 부모용 아이들의 모든 목표 조회 API 호출 실패 =====');

      // 네트워크 오류인 경우 null 반환
      if (e.toString().toLowerCase().contains('connection') ||
          e.toString().toLowerCase().contains('network') ||
          e.toString().toLowerCase().contains('socket')) {
        print('네트워크 연결 오류');
        return null;
      }

      // 인증 오류인 경우 예외 재발생
      if (e.toString().contains('인증') || e.toString().contains('로그인')) {
        rethrow;
      }

      // 기타 오류의 경우 빈 배열 반환
      return [];
    }
  }

  // 목표 수정 API (아이) - 새로 추가
  static Future<Map<String, dynamic>> updateGoal({
    required int goalId,
    required String title,
    required String category, // "LEARNING" 또는 "HABIT"
    required int reward,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      String? accessToken = await getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        throw Exception('인증이 필요합니다. 로그인을 다시 시도해주세요.');
      }

      final url = Uri.parse('$baseUrl/api-user/goal/child/update');
      final Map<String, dynamic> body = {
        'goalId': goalId,
        'title': title,
        'category': category,
        'reward': reward,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
      };

      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        // 성공 시 부모에게 알림 등 추가 로직 필요 시 여기에 구현
        return {
          'success': true,
          'data': responseData,
          'message': responseData['message'] ?? '목표가 성공적으로 수정되었습니다.',
        };
      } else {
        final errorBody = jsonDecode(response.body);
        String errorMessage = errorBody['message'] ?? '목표 수정에 실패했습니다.';
        if (response.statusCode == 400) {
          if (errorMessage.contains('신청 상태가 아닌 목표')) {
            throw Exception('신청 상태의 목표만 수정할 수 있습니다.');
          } else if (errorMessage.contains('동일한 유형의 목표')) {
            throw Exception('선택한 주간에 이미 동일한 유형의 목표가 존재합니다.');
          }
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (e.toString().contains('신청 상태의 목표만 수정') ||
          e.toString().contains('동일한 유형의 목표')) {
        rethrow;
      }
      if (e.toString().toLowerCase().contains('connection') ||
          e.toString().toLowerCase().contains('network') ||
          e.toString().toLowerCase().contains('socket')) {
        throw Exception('네트워크 연결을 확인해주세요.');
      }
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // 완료된 목표 필터링 (endDate 기준)
  static List<Map<String, dynamic>> getCompletedGoals(
    List<Map<String, dynamic>> goals,
  ) {
    final now = DateTime.now();
    return goals.where((goal) {
      try {
        final String? endDateStr = goal['endDate'];
        if (endDateStr != null) {
          final DateTime endDate = DateTime.parse(endDateStr);
          return now.isAfter(endDate);
        }
        return false;
      } catch (e) {
        print('완료된 목표 필터링 중 날짜 파싱 오류: $e');
        return false;
      }
    }).toList();
  }

  // 진행 중인 목표 필터링 (endDate 기준)
  static List<Map<String, dynamic>> getActiveGoals(
    List<Map<String, dynamic>> goals,
  ) {
    final now = DateTime.now();
    return goals.where((goal) {
      try {
        final String? endDateStr = goal['endDate'];
        final String? startDateStr = goal['startDate'];
        if (endDateStr != null && startDateStr != null) {
          final DateTime endDate = DateTime.parse(endDateStr);
          final DateTime startDate = DateTime.parse(startDateStr);
          return now.isAfter(startDate) && now.isBefore(endDate);
        }
        return false;
      } catch (e) {
        print('진행 중인 목표 필터링 중 날짜 파싱 오류: $e');
        return false;
      }
    }).toList();
  }

  // 목표 달성 여부 확인 (stampCount >= minStampCount)
  static bool isGoalAchieved(Map<String, dynamic> goal) {
    final int stampCount = goal['stampCount'] ?? 0;
    final int minStampCount = goal['minStampCount'] ?? 0;
    return stampCount >= minStampCount;
  }

  // 목표 달성률 계산 (stampCount / minStampCount * 100)
  static double getGoalAchievementRate(Map<String, dynamic> goal) {
    final int stampCount = goal['stampCount'] ?? 0;
    final int minStampCount = goal['minStampCount'] ?? 1; // 0으로 나누기 방지
    return (stampCount / minStampCount * 100).clamp(0.0, 100.0);
  }

  // 목표 달성률 텍스트 반환 (예: "5/7")
  static String getGoalProgressText(Map<String, dynamic> goal) {
    final int stampCount = goal['stampCount'] ?? 0;
    final int minStampCount = goal['minStampCount'] ?? 0;
    return '$stampCount/$minStampCount';
  }

  // 보상 지급 여부 확인
  static bool isGoalRewarded(Map<String, dynamic> goal) {
    return goal['isRewarded'] ?? false;
  }

  // 보상 지급 상태 텍스트 반환
  static String getRewardStatusText(Map<String, dynamic> goal) {
    final bool isRewarded = isGoalRewarded(goal);
    final bool isAchieved = isGoalAchieved(goal);

    if (isRewarded) {
      return '보상 지급됨';
    } else if (isAchieved) {
      return '보상 대기중';
    } else {
      return '미달성';
    }
  }

  // 목표 상세 상태 정보 반환 (종합)
  static Map<String, dynamic> getGoalDetailedStatus(Map<String, dynamic> goal) {
    final bool isAchieved = isGoalAchieved(goal);
    final bool isRewarded = isGoalRewarded(goal);
    final double achievementRate = getGoalAchievementRate(goal);
    final String progressText = getGoalProgressText(goal);
    final String rewardStatusText = getRewardStatusText(goal);
    final String statusText = getGoalStatusText(goal);

    return {
      'isAchieved': isAchieved,
      'isRewarded': isRewarded,
      'achievementRate': achievementRate,
      'progressText': progressText,
      'rewardStatusText': rewardStatusText,
      'statusText': statusText,
      'stampCount': goal['stampCount'] ?? 0,
      'minStampCount': goal['minStampCount'] ?? 0,
      'reward': goal['reward'] ?? 0,
    };
  }

  // 달성된 목표들만 필터링
  static List<Map<String, dynamic>> getAchievedGoals(
    List<Map<String, dynamic>> goals,
  ) {
    return goals.where((goal) => isGoalAchieved(goal)).toList();
  }

  // 보상받지 못한 달성 목표들 필터링
  static List<Map<String, dynamic>> getUnrewardedAchievedGoals(
    List<Map<String, dynamic>> goals,
  ) {
    return goals
        .where((goal) => isGoalAchieved(goal) && !isGoalRewarded(goal))
        .toList();
  }

  // 전체 보상금 계산 (달성한 목표들의 보상금 합계)
  static int getTotalRewardAmount(List<Map<String, dynamic>> goals) {
    return getAchievedGoals(
      goals,
    ).fold(0, (sum, goal) => sum + (goal['reward'] as int? ?? 0));
  }

  // 지급된 보상금 계산
  static int getTotalPaidRewardAmount(List<Map<String, dynamic>> goals) {
    return goals
        .where((goal) => isGoalRewarded(goal))
        .fold(0, (sum, goal) => sum + (goal['reward'] as int? ?? 0));
  }

  // 대기중인 보상금 계산
  static int getTotalPendingRewardAmount(List<Map<String, dynamic>> goals) {
    return getUnrewardedAchievedGoals(
      goals,
    ).fold(0, (sum, goal) => sum + (goal['reward'] as int? ?? 0));
  }

  // 목표 삭제 API (아이) - 새로 추가
  static Future<Map<String, dynamic>> deleteGoal(int goalId) async {
    try {
      print('===== 목표 삭제 API 호출 시작 =====');

      String? accessToken = await getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        throw Exception('인증이 필요합니다. 로그인을 다시 시도해주세요.');
      }

      final url = Uri.parse('$baseUrl/api-user/goal/child/$goalId');
      print('요청 URL: $url');
      print('삭제할 목표 ID: $goalId');

      final response = await http.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      print('목표 삭제 요청');
      print('응답 상태 코드: ${response.statusCode}');
      print('응답 바디: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        // 응답 바디가 있으면 파싱, 없으면 기본 응답 생성
        Map<String, dynamic> responseData = {};
        if (response.body.isNotEmpty) {
          try {
            responseData = jsonDecode(response.body);
          } catch (e) {
            print('응답 바디 파싱 실패 (정상, 204는 바디가 없을 수 있음): $e');
          }
        }

        return {
          'success': true,
          'message': '목표가 성공적으로 삭제되었습니다.',
          'data': responseData,
        };
      } else {
        // 에러 응답 처리
        try {
          final errorBody = jsonDecode(response.body);
          String errorMessage = errorBody['message'] ?? '목표 삭제에 실패했습니다.';

          if (response.statusCode == 400) {
            if (errorMessage.contains('신청 상태가 아닌 목표')) {
              throw Exception('신청 상태의 목표만 삭제할 수 있습니다.');
            }
          }

          throw Exception(errorMessage);
        } catch (e) {
          if (e.toString().contains('신청 상태의 목표만 삭제')) {
            rethrow;
          }
          throw Exception('목표 삭제 실패: ${response.statusCode}');
        }
      }
    } catch (e) {
      print('목표 삭제 중 오류: $e');

      if (e.toString().contains('신청 상태의 목표만 삭제')) {
        rethrow;
      }

      // 네트워크 오류 확인
      if (e.toString().toLowerCase().contains('connection') ||
          e.toString().toLowerCase().contains('network') ||
          e.toString().toLowerCase().contains('socket')) {
        throw Exception('네트워크 연결을 확인해주세요.');
      }

      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }
}
