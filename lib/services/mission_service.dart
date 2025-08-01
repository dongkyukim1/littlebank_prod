import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'auth_service.dart';
import 'package:flutter/material.dart';
import '../models/mission_notification.dart';

// 미션 카테고리 Enum
enum MissionCategory { LEARNING, HABIT }

// 미션 타입 Enum
enum MissionType { FAMILY, ACADEMY }

// 미션 상태 Enum
enum MissionStatus { REQUESTED, ACCEPT, ACHIEVEMENT }

// 미션 과목 Enum
enum MissionSubject { KOREAN, ENGLISH, MATH, SOCIAL, SCIENCE }

// 미션 생성 요청 모델
class CreateMissionRequest {
  final String title;
  final String? subject;
  final MissionCategory category;
  final MissionType type;
  final int reward;
  final DateTime startDate;
  final DateTime endDate;
  final List<int> childs;

  CreateMissionRequest({
    required this.title,
    this.subject,
    required this.category,
    required this.type,
    required this.reward,
    required this.startDate,
    required this.endDate,
    required this.childs,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {
      'title': title,
      'category': category.name,
      'type': type.name,
      'reward': reward,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'childs': childs,
    };

    // 학습인증인 경우에만 subject 추가
    if (category == MissionCategory.LEARNING && subject != null) {
      json['subject'] = subject;
    }

    return json;
  }
}

// 미션 응답 모델
class MissionResponse {
  final int missionId;
  final String title;
  final MissionType type;
  final MissionCategory category;
  final String? subject;
  final MissionStatus status;
  final int reward;
  final DateTime startDate;
  final DateTime endDate;
  final int createdBy;
  final int childId;
  final bool isRewarded;
  final int? finishScore;
  final bool isDeleted;

  MissionResponse({
    required this.missionId,
    required this.title,
    required this.type,
    required this.category,
    this.subject,
    required this.status,
    required this.reward,
    required this.startDate,
    required this.endDate,
    required this.createdBy,
    required this.childId,
    required this.isRewarded,
    this.finishScore,
    required this.isDeleted,
  });

  factory MissionResponse.fromJson(Map<String, dynamic> json) {
    return MissionResponse(
      missionId: json['missionId'] ?? 0,
      title: json['title'] ?? '',
      type: MissionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => MissionType.FAMILY,
      ),
      category: MissionCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => MissionCategory.LEARNING,
      ),
      subject: json['subject'],
      status: MissionStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => MissionStatus.REQUESTED,
      ),
      reward: json['reward'] ?? 0,
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      createdBy: json['createdBy'] ?? 0,
      childId: json['childId'] ?? 0,
      isRewarded: json['isRewarded'] ?? false,
      finishScore: json['finishScore'],
      isDeleted: json['isDeleted'] ?? false,
    );
  }
}

class MissionService {
  // API 기본 URL
  static String get baseUrl => dotenv.env['API_BASE_URL'] ?? '';

  // 미션 생성 API
  static Future<List<MissionResponse>> createMission({
    required CreateMissionRequest request,
  }) async {
    print('===== 미션 생성 API 호출 시작 =====');

    if (baseUrl.isEmpty) {
      throw Exception('API_BASE_URL가 설정되지 않았습니다. .env 파일을 확인하세요.');
    }

    // 액세스 토큰 가져오기
    String? accessToken = await AuthService.getAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('인증이 필요합니다. 로그인을 다시 시도해주세요.');
    }

    print('액세스 토큰 확인 완료');

    final url = Uri.parse('$baseUrl/api-user/mission/create');
    print('요청 URL: $url');

    try {
      final requestBody = request.toJson();
      print('요청 바디: ${jsonEncode(requestBody)}');

      // POST 요청 보내기
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(requestBody),
      );

      print('응답 상태 코드: ${response.statusCode}');
      print('응답 바디: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final List<dynamic> responseData = jsonDecode(response.body);
        final missions =
            responseData.map((json) => MissionResponse.fromJson(json)).toList();

        print('미션 생성 성공: ${missions.length}개의 미션이 생성되었습니다');
        print('===== 미션 생성 API 호출 종료 =====');

        return missions;
      } else if (response.statusCode == 401) {
        throw Exception('인증이 만료되었습니다. 다시 로그인해주세요.');
      } else if (response.statusCode == 400) {
        try {
          final errorBody = jsonDecode(response.body);
          final errorMessage = errorBody['message'] ?? '잘못된 요청입니다.';
          throw Exception(errorMessage);
        } catch (e) {
          throw Exception('잘못된 요청입니다.');
        }
      } else {
        try {
          final errorBody = jsonDecode(response.body);
          final errorMessage = errorBody['message'] ?? '미션 생성에 실패했습니다.';
          throw Exception(errorMessage);
        } catch (e) {
          throw Exception('미션 생성에 실패했습니다. (${response.statusCode})');
        }
      }
    } catch (e) {
      print('미션 생성 중 오류: $e');
      print('===== 미션 생성 API 호출 종료 (오류) =====');

      if (e.toString().toLowerCase().contains('connection') ||
          e.toString().toLowerCase().contains('network') ||
          e.toString().toLowerCase().contains('socket')) {
        throw Exception('네트워크 연결을 확인해주세요.');
      }

      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // 과목명을 한국어로 변환
  static String getSubjectDisplayName(MissionSubject subject) {
    switch (subject) {
      case MissionSubject.KOREAN:
        return '국어';
      case MissionSubject.ENGLISH:
        return '영어';
      case MissionSubject.MATH:
        return '수학';
      case MissionSubject.SOCIAL:
        return '사회';
      case MissionSubject.SCIENCE:
        return '과학';
    }
  }

  // 카테고리명을 한국어로 변환
  static String getCategoryDisplayName(MissionCategory category) {
    switch (category) {
      case MissionCategory.LEARNING:
        return '학습인증';
      case MissionCategory.HABIT:
        return '습관형성';
    }
  }

  // 타입명을 한국어로 변환
  static String getTypeDisplayName(MissionType type) {
    switch (type) {
      case MissionType.FAMILY:
        return '가족미션';
      case MissionType.ACADEMY:
        return '학원미션';
    }
  }

  // 상태명을 한국어로 변환
  static String getStatusDisplayName(MissionStatus status) {
    switch (status) {
      case MissionStatus.REQUESTED:
        return '승인 대기중';
      case MissionStatus.ACCEPT:
        return '진행중';
      case MissionStatus.ACHIEVEMENT:
        return '완료';
    }
  }

  // 아이의 모든 미션 조회 API
  static Future<Map<String, dynamic>?> getChildMissions({int page = 0}) async {
    print('===== 아이의 모든 미션 조회 API 호출 시작 =====');

    if (baseUrl.isEmpty) {
      throw Exception('API_BASE_URL가 설정되지 않았습니다. .env 파일을 확인하세요.');
    }

    // 액세스 토큰 가져오기
    String? accessToken = await AuthService.getAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('인증이 필요합니다. 로그인을 다시 시도해주세요.');
    }

    print('액세스 토큰 확인 완료');

    final url = Uri.parse('$baseUrl/api-user/mission/child/all?page=$page');
    print('요청 URL: $url');

    try {
      // GET 요청 보내기
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      print('응답 상태 코드: ${response.statusCode}');
      print('응답 바디: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        print('미션 조회 성공: ${responseData['totalElement']}개의 미션');
        print('===== 아이의 모든 미션 조회 API 호출 종료 =====');

        return responseData;
      } else if (response.statusCode == 401) {
        throw Exception('인증이 만료되었습니다. 다시 로그인해주세요.');
      } else {
        try {
          final errorBody = jsonDecode(response.body);
          final errorMessage = errorBody['message'] ?? '미션 조회에 실패했습니다.';
          throw Exception(errorMessage);
        } catch (e) {
          throw Exception('미션 조회에 실패했습니다. (${response.statusCode})');
        }
      }
    } catch (e) {
      print('미션 조회 중 오류: $e');
      print('===== 아이의 모든 미션 조회 API 호출 종료 (오류) =====');

      if (e.toString().toLowerCase().contains('connection') ||
          e.toString().toLowerCase().contains('network') ||
          e.toString().toLowerCase().contains('socket')) {
        throw Exception('네트워크 연결을 확인해주세요.');
      }

      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // 미션 수락 API
  static Future<MissionResponse?> acceptMission(int missionId) async {
    print('===== 미션 수락 API 호출 시작 =====');
    print('미션 ID: $missionId');

    if (baseUrl.isEmpty) {
      throw Exception('API_BASE_URL가 설정되지 않았습니다. .env 파일을 확인하세요.');
    }

    // 액세스 토큰 가져오기
    String? accessToken = await AuthService.getAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('인증이 필요합니다. 로그인을 다시 시도해주세요.');
    }

    print('액세스 토큰 확인 완료');

    final url = Uri.parse(
      '$baseUrl/api-user/mission/child/apply/accept/$missionId',
    );
    print('요청 URL: $url');

    try {
      // PATCH 요청 보내기
      final response = await http.patch(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      print('응답 상태 코드: ${response.statusCode}');
      print('응답 바디: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final mission = MissionResponse.fromJson(responseData);

        print('미션 수락 성공: ${mission.title}');
        print('===== 미션 수락 API 호출 종료 =====');

        return mission;
      } else if (response.statusCode == 401) {
        throw Exception('인증이 만료되었습니다. 다시 로그인해주세요.');
      } else if (response.statusCode == 400) {
        try {
          final errorBody = jsonDecode(response.body);
          final errorMessage = errorBody['message'] ?? '잘못된 요청입니다.';
          throw Exception(errorMessage);
        } catch (e) {
          throw Exception('잘못된 요청입니다.');
        }
      } else if (response.statusCode == 404) {
        throw Exception('해당 미션을 찾을 수 없습니다.');
      } else {
        try {
          final errorBody = jsonDecode(response.body);
          final errorMessage = errorBody['message'] ?? '미션 수락에 실패했습니다.';
          throw Exception(errorMessage);
        } catch (e) {
          throw Exception('미션 수락에 실패했습니다. (${response.statusCode})');
        }
      }
    } catch (e) {
      print('미션 수락 중 오류: $e');
      print('===== 미션 수락 API 호출 종료 (오류) =====');

      if (e.toString().toLowerCase().contains('connection') ||
          e.toString().toLowerCase().contains('network') ||
          e.toString().toLowerCase().contains('socket')) {
        throw Exception('네트워크 연결을 확인해주세요.');
      }

      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // 미션 상태에 따른 표시 텍스트 (활동 내역용)
  static String getMissionStatusForActivity(MissionResponse mission) {
    final now = DateTime.now();

    if (mission.status == MissionStatus.REQUESTED) {
      return '승인 대기';
    } else if (mission.status == MissionStatus.ACCEPT) {
      if (now.isBefore(mission.startDate)) {
        return '진행 대기';
      } else if (now.isBefore(mission.endDate.add(Duration(days: 1)))) {
        return '진행중';
      } else {
        return '완료한';
      }
    } else if (mission.status == MissionStatus.ACHIEVEMENT) {
      return '완료한';
    }

    return '알 수 없음';
  }

  // 칭찬 메시지 표시
  static void showPraiseSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(fontFamily: 'Pretendard-Medium'),
        ),
        backgroundColor: Color(0xFF5D9EFF),
        duration: Duration(seconds: 3),
      ),
    );
  }

  // 최근 보상 내역 조회 (부모용)
  static Future<Map<String, dynamic>?> getRecentReward({
    required int childId,
    required String category, // LEARNING, HABIT
    String? subject, // KOREAN, ENGLISH, MATH, SOCIAL, SCIENCE (습관형성시 null)
  }) async {
    print('===== 최근 보상 내역 조회 API 호출 시작 =====');
    print('childId: $childId, category: $category, subject: $subject');

    if (baseUrl.isEmpty) {
      throw Exception('API_BASE_URL가 설정되지 않았습니다. .env 파일을 확인하세요.');
    }

    // 액세스 토큰 가져오기
    String? accessToken = await AuthService.getAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('인증이 필요합니다. 로그인을 다시 시도해주세요.');
    }

    print('액세스 토큰 확인 완료');

    // URL 파라미터 구성
    final Map<String, String> queryParams = {
      'childId': childId.toString(),
      'category': category,
    };

    // 학습인증인 경우에만 subject 추가
    if (subject != null && subject.isNotEmpty) {
      queryParams['subject'] = subject;
    }

    final url = Uri.parse(
      '$baseUrl/api-user/mission/recent/reward',
    ).replace(queryParameters: queryParams);
    print('요청 URL: $url');

    try {
      // GET 요청 보내기
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      print('응답 상태 코드: ${response.statusCode}');
      print('응답 바디: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        print('최근 보상 내역 조회 성공');
        print('파싱된 응답 데이터: $responseData');
        print('type: ${responseData['type']}');
        print('category: ${responseData['category']}');
        print('subject: ${responseData['subject']}');
        print('recentReward: ${responseData['recentReward']} (타입: ${responseData['recentReward'].runtimeType})');
        
        // API 문서에 따른 예상 응답 구조 확인
        if (responseData.containsKey('recentReward')) {
          final rewardValue = responseData['recentReward'];
          if (rewardValue == null) {
            print('⚠️ recentReward가 null입니다');
          } else if (rewardValue == 0) {
            print('⚠️ recentReward가 0입니다 - 최근 보상 내역이 없을 수 있습니다');
          } else {
            print('✅ recentReward 값: $rewardValue원');
          }
        } else {
          print('❌ recentReward 필드가 응답에 없습니다');
        }
        
        print('===== 최근 보상 내역 조회 API 호출 종료 =====');

        return responseData;
      } else if (response.statusCode == 401) {
        throw Exception('인증이 만료되었습니다. 다시 로그인해주세요.');
      } else {
        try {
          final errorBody = jsonDecode(response.body);
          final errorMessage = errorBody['message'] ?? '최근 보상 내역 조회에 실패했습니다.';
          throw Exception(errorMessage);
        } catch (e) {
          throw Exception('최근 보상 내역 조회에 실패했습니다. (${response.statusCode})');
        }
      }
    } catch (e) {
      print('최근 보상 내역 조회 중 오류: $e');
      print('===== 최근 보상 내역 조회 API 호출 종료 (오류) =====');

      if (e.toString().toLowerCase().contains('connection') ||
          e.toString().toLowerCase().contains('network') ||
          e.toString().toLowerCase().contains('socket')) {
        throw Exception('네트워크 연결을 확인해주세요.');
      }

      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // 부모가 자녀의 미션 전체 조회 API
  static Future<Map<String, dynamic>?> getParentChildMissions({
    required int childId,
    int page = 0,
  }) async {
    print('===== 부모 - 자녀 미션 전체 조회 API 호출 시작 =====');
    print('childId: $childId, page: $page');

    if (baseUrl.isEmpty) {
      throw Exception('API_BASE_URL가 설정되지 않았습니다. .env 파일을 확인하세요.');
    }

    // 액세스 토큰 가져오기
    String? accessToken = await AuthService.getAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('인증이 필요합니다. 로그인을 다시 시도해주세요.');
    }

    print('액세스 토큰 확인 완료');

    final url = Uri.parse(
      '$baseUrl/api-user/mission/parent/all/$childId?page=$page',
    );
    print('요청 URL: $url');

    try {
      // GET 요청 보내기
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      print('응답 상태 코드: ${response.statusCode}');
      print('응답 바디: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        print('미션 조회 성공: ${responseData['totalElement']}개의 미션');
        print('===== 부모 - 자녀 미션 전체 조회 API 호출 종료 =====');

        return responseData;
      } else if (response.statusCode == 401) {
        throw Exception('인증이 만료되었습니다. 다시 로그인해주세요.');
      } else {
        try {
          final errorBody = jsonDecode(response.body);
          final errorMessage = errorBody['message'] ?? '미션 조회에 실패했습니다.';
          throw Exception(errorMessage);
        } catch (e) {
          throw Exception('미션 조회에 실패했습니다. (${response.statusCode})');
        }
      }
    } catch (e) {
      print('미션 조회 중 오류: $e');
      print('===== 부모 - 자녀 미션 전체 조회 API 호출 종료 (오류) =====');

      if (e.toString().toLowerCase().contains('connection') ||
          e.toString().toLowerCase().contains('network') ||
          e.toString().toLowerCase().contains('socket')) {
        throw Exception('네트워크 연결을 확인해주세요.');
      }

      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // 미션 진행 상태 판단 헬퍼 메서드 (부모 활동 내역용)
  static String getMissionProgressStatus(MissionResponse mission) {
    final now = DateTime.now();

    if (mission.status == MissionStatus.REQUESTED) {
      return '승인 대기';
    } else if (mission.status == MissionStatus.ACCEPT) {
      if (now.isBefore(mission.startDate)) {
        return '진행 대기';
      } else if (now.isBefore(mission.endDate.add(Duration(days: 1)))) {
        return '진행중';
      } else {
        return '완료한';
      }
    } else if (mission.status == MissionStatus.ACHIEVEMENT) {
      return '완료한';
    }

    return '알 수 없음';
  }

  // 미션 D-Day 계산 (부모 활동 내역용)
  static String calculateMissionDDay(MissionResponse mission) {
    final now = DateTime.now();

    // 승인 대기 중인 경우
    if (mission.status == MissionStatus.REQUESTED) {
      return '승인 대기';
    }

    // 시작 전인 경우
    if (now.isBefore(mission.startDate)) {
      final difference = mission.startDate.difference(now).inDays;
      return '시작 D-${difference}';
    }

    // 진행 중인 경우 종료일까지 남은 일수 계산
    if (now.isBefore(mission.endDate.add(Duration(days: 1)))) {
      final difference = mission.endDate.difference(now).inDays;
      if (difference > 0) {
        return 'D-$difference';
      } else if (difference == 0) {
        return 'D-Day';
      }
    }

    // 완료된 경우
    return '완료';
  }

  // 미션 랭킹 조회 API (아이들만 대상)
  static Future<Map<String, dynamic>?> getRanking({
    int pageNumber = 0,
    String range = 'WEEK',
  }) async {
    print('===== 미션 랭킹 조회 API 호출 시작 (아이들만) =====');
    print('pageNumber: $pageNumber, range: $range');
    print('🎯 API 엔드포인트: /api-user/mission/child/ranking (부모 제외)');

    if (baseUrl.isEmpty) {
      throw Exception('API_BASE_URL가 설정되지 않았습니다. .env 파일을 확인하세요.');
    }

    // 액세스 토큰 가져오기
    String? accessToken = await AuthService.getAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('인증이 필요합니다. 로그인을 다시 시도해주세요.');
    }

    print('액세스 토큰 확인 완료');

    final url = Uri.parse(
      '$baseUrl/api-user/mission/child/ranking?pageNumber=$pageNumber&range=$range',
    );
    print('요청 URL: $url');

    try {
      // GET 요청 보내기
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      print('응답 상태 코드: ${response.statusCode}');
      print('응답 바디: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        // 🔍 서버 응답 데이터 상세 분석
        print('🔍 서버 응답 데이터 분석:');
        for (String key in responseData.keys) {
          if (responseData[key] is List) {
            final List<dynamic> userList = responseData[key];
            print('  - 기간 "$key": ${userList.length}명');
            
            for (int i = 0; i < userList.length && i < 5; i++) { // 처음 5명만 로깅
              final userData = userList[i];
              final userName = userData['friendName'] ?? '이름없음';
              final userId = userData['friendUserId'] ?? '알수없음';
              final userRole = userData['userRole'] ?? userData['role'] ?? '역할없음';
              print('    [$i] $userName (ID: $userId, 역할: $userRole)');
            }
            
            if (userList.length > 5) {
              print('    ... 총 ${userList.length}명 중 5명만 표시');
            }
          }
        }

        print('✅ 랭킹 조회 성공 - 서버에서 받은 데이터에 부모 역할 사용자가 포함되어 있는지 확인됨');
        print('===== 미션 랭킹 조회 API 호출 종료 =====');

        return responseData;
      } else if (response.statusCode == 401) {
        throw Exception('인증이 만료되었습니다. 다시 로그인해주세요.');
      } else {
        try {
          final errorBody = jsonDecode(response.body);
          final errorMessage = errorBody['message'] ?? '랭킹 조회에 실패했습니다.';
          throw Exception(errorMessage);
        } catch (e) {
          throw Exception('랭킹 조회에 실패했습니다. (${response.statusCode})');
        }
      }
    } catch (e) {
      print('랭킹 조회 중 오류: $e');
      print('===== 미션 랭킹 조회 API 호출 종료 (오류) =====');

      if (e.toString().toLowerCase().contains('connection') ||
          e.toString().toLowerCase().contains('network') ||
          e.toString().toLowerCase().contains('socket')) {
        throw Exception('네트워크 연결을 확인해주세요.');
      }

      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // 미션 점수 입력 API (부모용)
  static Future<Map<String, dynamic>?> submitMissionScore({
    required int missionId,
    required int score,
  }) async {
    print('===== 미션 점수 입력 API 호출 시작 =====');
    print('missionId: $missionId, score: $score');

    if (baseUrl.isEmpty) {
      throw Exception('API_BASE_URL가 설정되지 않았습니다. .env 파일을 확인하세요.');
    }

    // 액세스 토큰 가져오기
    String? accessToken = await AuthService.getAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('인증이 필요합니다. 로그인을 다시 시도해주세요.');
    }

    print('액세스 토큰 확인 완료');

    final url = Uri.parse(
      '$baseUrl/api-user/mission/parent/finish/score/$missionId',
    );
    print('요청 URL: $url');

    final requestBody = {'score': score};

    try {
      // POST 요청 보내기
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(requestBody),
      );

      print('응답 상태 코드: ${response.statusCode}');
      print('응답 바디: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        print('미션 점수 입력 성공');
        print('===== 미션 점수 입력 API 호출 종료 =====');

        return responseData;
      } else if (response.statusCode == 401) {
        throw Exception('인증이 만료되었습니다. 다시 로그인해주세요.');
      } else {
        try {
          final errorBody = jsonDecode(response.body);
          final errorMessage = errorBody['message'] ?? '미션 점수 입력에 실패했습니다.';
          throw Exception(errorMessage);
        } catch (e) {
          throw Exception('미션 점수 입력에 실패했습니다. (${response.statusCode})');
        }
      }
    } catch (e) {
      print('미션 점수 입력 중 오류: $e');
      print('===== 미션 점수 입력 API 호출 종료 (오류) =====');

      if (e.toString().toLowerCase().contains('connection') ||
          e.toString().toLowerCase().contains('network') ||
          e.toString().toLowerCase().contains('socket')) {
        throw Exception('네트워크 연결을 확인해주세요.');
      }

      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // 미션 알림 목록 조회
  static Future<List<MissionNotification>?> getMissionNotifications() async {
    try {
      final accessToken = await AuthService.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        print('액세스 토큰이 없습니다.');
        return null;
      }

      final url = Uri.parse('$baseUrl/api-user/mission/notifications');
      print('미션 알림 목록 조회 API 호출: $url');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      print('미션 알림 목록 조회 응답 상태: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        return data.map((json) => MissionNotification.fromJson(json)).toList();
      } else {
        print('API 오류: ${response.statusCode}');
        print('응답 본문: ${response.body}');
        return null;
      }
    } catch (e) {
      print('미션 알림 목록 조회 중 오류: $e');
      return null;
    }
  }

  // 미션 수락/거절 처리
  static Future<bool> processMission(int missionId, bool accept) async {
    try {
      final accessToken = await AuthService.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        print('액세스 토큰이 없습니다.');
        return false;
      }

      final url = Uri.parse(
        '$baseUrl/api-user/mission/parent/accept/$missionId',
      );
      print('미션 ${accept ? '수락' : '거절'} API 호출: $url');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      print('미션 처리 응답 상태: ${response.statusCode}');

      if (response.statusCode == 200) {
        return true;
      } else {
        print('API 오류: ${response.statusCode}');
        print('응답 본문: ${response.body}');
        return false;
      }
    } catch (e) {
      print('미션 처리 중 오류: $e');
      return false;
    }
  }

  // 미션이 점수 입력 완료되었는지 확인하는 메서드
  static bool isMissionScoreCompleted(MissionResponse mission) {
    // ACHIEVEMENT 상태이면서 score가 있으면 완료된 것으로 판단
    // 실제 API 응답에 score 필드가 있는지 확인 필요
    return mission.status == MissionStatus.ACHIEVEMENT;
  }

  // 완료된 미션 중 점수 입력이 필요한 미션만 필터링
  static List<MissionResponse> getCompletedMissionsNeedingScore(
    List<dynamic> missionList,
  ) {
    return missionList
        .map((mission) => MissionResponse.fromJson(mission))
        .where(
          (mission) =>
              mission.status == MissionStatus.ACHIEVEMENT &&
              // 추가 조건: 서버에서 점수가 이미 입력되었는지 확인하는 필드가 있다면 추가
              true, // 임시로 true로 설정
        )
        .toList();
  }

  // 미션이 완료되었지만 아직 보상이 지급되지 않은 미션인지 확인
  static bool isCompletedMissionNeedingReward(MissionResponse mission) {
    final now = DateTime.now();
    // ACHIEVEMENT 상태이거나, 기간이 끝났지만 아직 보상이 지급되지 않은 경우
    return (mission.status == MissionStatus.ACHIEVEMENT ||
            (mission.status == MissionStatus.ACCEPT &&
                now.isAfter(mission.endDate))) &&
        !mission.isRewarded;
  }

  // 완료된 미션 중 보상이 필요한 미션만 필터링
  static List<MissionResponse> getCompletedMissionsNeedingReward(
    List<dynamic> missionList,
  ) {
    return missionList
        .map((mission) => MissionResponse.fromJson(mission))
        .where((mission) => isCompletedMissionNeedingReward(mission))
        .toList();
  }

  // 미션이 이미 보상이 지급된 완료 미션인지 확인
  static bool isRewardedCompletedMission(MissionResponse mission) {
    final now = DateTime.now();
    return (mission.status == MissionStatus.ACHIEVEMENT ||
            (mission.status == MissionStatus.ACCEPT &&
                now.isAfter(mission.endDate))) &&
        mission.isRewarded;
  }

  // Map<String, dynamic> 형태의 미션 데이터에서 보상이 필요한지 확인
  static bool shouldShowRewardModal(Map<String, dynamic> missionData) {
    // 새 필드명과 기존 필드명 모두 지원
    final isRewarded =
        missionData['isRewarded'] ?? missionData['rewarded'] ?? false;
    final status = missionData['status'] ?? '';
    final endDateStr = missionData['endDate'] ?? '';

    print('🎯 shouldShowRewardModal 확인:');
    print('   - isRewarded: ${missionData['isRewarded']}');
    print('   - rewarded: ${missionData['rewarded']}');
    print('   - 최종 isRewarded: $isRewarded');
    print('   - status: $status');
    print('   - endDate: $endDateStr');

    // 이미 보상이 지급된 경우 모달을 표시하지 않음
    if (isRewarded) {
      print('   - 결과: false (이미 보상 지급됨)');
      return false;
    }

    // 완료된 미션인지 확인
    final now = DateTime.now();
    if (status == 'ACHIEVEMENT') {
      print('   - 결과: true (ACHIEVEMENT 상태)');
      return true;
    }

    // 기간이 끝났는지 확인
    if (status == 'ACCEPT' && endDateStr.isNotEmpty) {
      try {
        final endDate = DateTime.parse(endDateStr);
        final isExpired = now.isAfter(endDate);
        print('   - 결과: $isExpired (기간 만료 여부)');
        return isExpired;
      } catch (e) {
        print('날짜 파싱 오류: $e');
        return false;
      }
    }

    print('   - 결과: false (기본값)');
    return false;
  }

  // 미션 목록에서 보상 모달을 표시해야 하는 미션들만 필터링
  static List<Map<String, dynamic>> getMissionsNeedingRewardModal(
    List<dynamic> missionList,
  ) {
    return missionList
        .where((mission) => mission is Map<String, dynamic>)
        .cast<Map<String, dynamic>>()
        .where((mission) => shouldShowRewardModal(mission))
        .toList();
  }

  // 목표 금액대 설정/수정 API
  static Future<Map<String, dynamic>?> setTargetAmount({
    required int targetAmount,
  }) async {
    print('===== 목표 금액대 설정 API 호출 시작 =====');
    print('targetAmount: $targetAmount');

    if (baseUrl.isEmpty) {
      throw Exception('API_BASE_URL가 설정되지 않았습니다. .env 파일을 확인하세요.');
    }

    // 액세스 토큰 가져오기
    String? accessToken = await AuthService.getAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('인증이 필요합니다. 로그인을 다시 시도해주세요.');
    }

    print('액세스 토큰 확인 완료');

    final url = Uri.parse('$baseUrl/api-user/ranking/amount');
    print('요청 URL: $url');

    final requestBody = {'targetAmount': targetAmount};

    try {
      // POST 요청 보내기
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(requestBody),
      );

      print('응답 상태 코드: ${response.statusCode}');
      print('응답 바디: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        print('목표 금액대 설정 성공');
        print('===== 목표 금액대 설정 API 호출 종료 =====');

        return responseData;
      } else if (response.statusCode == 401) {
        throw Exception('인증이 만료되었습니다. 다시 로그인해주세요.');
      } else {
        try {
          final errorBody = jsonDecode(response.body);
          final errorMessage = errorBody['message'] ?? '목표 금액대 설정에 실패했습니다.';
          throw Exception(errorMessage);
        } catch (e) {
          throw Exception('목표 금액대 설정에 실패했습니다. (${response.statusCode})');
        }
      }
    } catch (e) {
      print('목표 금액대 설정 중 오류: $e');
      print('===== 목표 금액대 설정 API 호출 종료 (오류) =====');

      if (e.toString().toLowerCase().contains('connection') ||
          e.toString().toLowerCase().contains('network') ||
          e.toString().toLowerCase().contains('socket')) {
        throw Exception('네트워크 연결을 확인해주세요.');
      }

      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // 목표 금액대 기준 친구 비교 랭킹 조회 API
  static Future<Map<String, dynamic>?> getFriendsRanking({
    required int targetId,
    String? month, // yyyy-MM 형식
  }) async {
    print('===== 친구 비교 랭킹 조회 API 호출 시작 =====');
    print('targetId: $targetId, month: $month');

    if (baseUrl.isEmpty) {
      throw Exception('API_BASE_URL가 설정되지 않았습니다. .env 파일을 확인하세요.');
    }

    // 액세스 토큰 가져오기
    String? accessToken = await AuthService.getAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('인증이 필요합니다. 로그인을 다시 시도해주세요.');
    }

    print('액세스 토큰 확인 완료');

    // URL 파라미터 구성
    final Map<String, String> queryParams = {};
    if (month != null && month.isNotEmpty) {
      queryParams['month'] = month;
    }

    final url = Uri.parse('$baseUrl/api-user/ranking/goal/friends/$targetId')
        .replace(queryParameters: queryParams);
    print('요청 URL: $url');

    try {
      // GET 요청 보내기
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      print('응답 상태 코드: ${response.statusCode}');
      print('응답 바디: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        print('친구 비교 랭킹 조회 성공');
        print('===== 친구 비교 랭킹 조회 API 호출 종료 =====');

        return responseData;
      } else if (response.statusCode == 401) {
        throw Exception('인증이 만료되었습니다. 다시 로그인해주세요.');
      } else {
        try {
          final errorBody = jsonDecode(response.body);
          final errorMessage = errorBody['message'] ?? '친구 비교 랭킹 조회에 실패했습니다.';
          throw Exception(errorMessage);
        } catch (e) {
          throw Exception('친구 비교 랭킹 조회에 실패했습니다. (${response.statusCode})');
        }
      }
    } catch (e) {
      print('친구 비교 랭킹 조회 중 오류: $e');
      print('===== 친구 비교 랭킹 조회 API 호출 종료 (오류) =====');

      if (e.toString().toLowerCase().contains('connection') ||
          e.toString().toLowerCase().contains('network') ||
          e.toString().toLowerCase().contains('socket')) {
        throw Exception('네트워크 연결을 확인해주세요.');
      }

      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // 미션이 점수 입력이 필요한지 확인하는 메서드
  static bool needsScoreInput(Map<String, dynamic> missionData) {
    // 새 필드명과 기존 필드명 모두 지원
    final isRewarded =
        missionData['isRewarded'] ?? missionData['rewarded'] ?? false;
    final finishScore = missionData['finishScore'] ?? missionData['score'];
    final status = missionData['status'] ?? '';
    final endDateStr = missionData['endDate'] ?? '';

    // 이미 보상이 지급된 경우 점수 입력 불필요
    if (isRewarded) {
      return false;
    }

    // 점수가 이미 입력된 경우 (수정 가능)
    if (finishScore != null) {
      return true;
    }

    // 완료된 미션인지 확인
    final now = DateTime.now();
    if (status == 'ACHIEVEMENT') {
      return true;
    }

    // 기간이 끝났는지 확인
    if (status == 'ACCEPT' && endDateStr.isNotEmpty) {
      try {
        final endDate = DateTime.parse(endDateStr);
        return now.isAfter(endDate);
      } catch (e) {
        print('날짜 파싱 오류: $e');
        return false;
      }
    }

    return false;
  }

  // 미션 상태 텍스트 반환 (보상 지급 여부 포함)
  static String getMissionStatusText(Map<String, dynamic> missionData) {
    // 새 필드명과 기존 필드명 모두 지원
    final isRewarded =
        missionData['isRewarded'] ?? missionData['rewarded'] ?? false;
    final status = missionData['status'] ?? '';
    final endDateStr = missionData['endDate'] ?? '';
    final now = DateTime.now();

    if (status == 'REQUESTED') {
      return '승인 대기';
    } else if (status == 'ACCEPT') {
      if (endDateStr.isNotEmpty) {
        try {
          final endDate = DateTime.parse(endDateStr);
          if (now.isBefore(endDate)) {
            return '진행중';
          } else {
            return isRewarded ? '보상 완료' : '완료 (평가 대기)';
          }
        } catch (e) {
          return '진행중';
        }
      }
      return '진행중';
    } else if (status == 'ACHIEVEMENT') {
      return isRewarded ? '보상 완료' : '완료 (평가 대기)';
    }

    return '알 수 없음';
  }

  // 완료된 미션 개수 계산 (아이용)
  static Future<int> getCompletedMissionCount() async {
    try {
      // 모든 미션 데이터 가져오기
      final missionData = await getChildMissions(page: 0);
      if (missionData == null || !missionData.containsKey('data')) {
        return 0;
      }

      final List<dynamic> missions = missionData['data'] ?? [];
      int completedCount = 0;
      final now = DateTime.now();

      for (final missionJson in missions) {
        if (missionJson is Map<String, dynamic>) {
          final status = missionJson['status'] ?? '';
          final endDateStr = missionJson['endDate'] ?? '';

          // ACHIEVEMENT 상태는 완료로 카운트
          if (status == 'ACHIEVEMENT') {
            completedCount++;
          } 
          // ACCEPT 상태이지만 기간이 끝난 경우도 완료로 카운트
          else if (status == 'ACCEPT' && endDateStr.isNotEmpty) {
            try {
              final endDate = DateTime.parse(endDateStr);
              if (now.isAfter(endDate)) {
                completedCount++;
              }
            } catch (e) {
              // 날짜 파싱 실패 시 무시
            }
          }
        }
      }

      print('완료된 미션 개수: $completedCount');
      return completedCount;
    } catch (e) {
      print('완료된 미션 개수 조회 오류: $e');
      return 0;
    }
  }

  // 전체 미션 개수 계산 (아이용)
  static Future<int> getTotalMissionCount() async {
    try {
      final missionData = await getChildMissions(page: 0);
      if (missionData == null) {
        return 0;
      }

      final totalElement = missionData['totalElement'] ?? 0;
      print('전체 미션 개수: $totalElement');
      return totalElement is int ? totalElement : 0;
    } catch (e) {
      print('전체 미션 개수 조회 오류: $e');
      return 0;
    }
  }
}
