import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'auth_service.dart';
import '../models/challenge_join_request.dart';
import 'dart:math' as math;

class Challenge {
  final int id;
  final String title;
  final String description;
  final String category;
  final String? subject;
  final String startDate;
  final String endDate;
  final int totalStudyTime;
  final int currentParticipants;
  final int totalParticipants;
  final int viewCount;
  final int? reward;
  final String? challengeStatus;

  Challenge({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    this.subject,
    required this.startDate,
    required this.endDate,
    required this.totalStudyTime,
    required this.currentParticipants,
    required this.totalParticipants,
    required this.viewCount,
    this.reward,
    this.challengeStatus,
  });

  factory Challenge.fromJson(Map<String, dynamic> json) {
    return Challenge(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      subject: json['subject'],
      startDate: json['startDate'] ?? '',
      endDate: json['endDate'] ?? '',
      totalStudyTime: json['totalStudyTime'] ?? 0,
      currentParticipants: json['currentParticipants'] ?? 0,
      totalParticipants: json['totalParticipants'] ?? 0,
      viewCount: json['viewCount'] ?? 0,
      reward: json['reward'],
      challengeStatus: json['challengeStatus'],
    );
  }
}

class ChallengeResponse {
  final List<Challenge> data;
  final int totalPage;
  final int totalElement;
  final int pageNumber;

  ChallengeResponse({
    required this.data,
    required this.totalPage,
    required this.totalElement,
    required this.pageNumber,
  });

  factory ChallengeResponse.fromJson(Map<String, dynamic> json) {
    List<Challenge> challenges = [];

    if (json.containsKey('data') && json['data'] is List) {
      challenges =
          (json['data'] as List)
              .map((item) => Challenge.fromJson(item))
              .toList();
    }

    return ChallengeResponse(
      data: challenges,
      totalPage: json['totalPage'] ?? 0,
      totalElement: json['totalElement'] ?? 0,
      pageNumber: json['pageNumber'] ?? 0,
    );
  }
}

class ChallengeParticipation {
  final int participationId;
  final int challengeId;
  final String startDate;
  final String endDate;
  final String title;
  final String? subject;
  final String challengeStatus;
  final String startTime;
  final int totalStudyTime;
  final int reward;
  final bool isAccepted;
  final bool isRewarded;
  final int? finishScore;

  // 하위 호환성을 위한 getter
  bool get accepted => isAccepted;

  ChallengeParticipation({
    required this.participationId,
    required this.challengeId,
    required this.startDate,
    required this.endDate,
    required this.title,
    this.subject,
    required this.challengeStatus,
    required this.startTime,
    required this.totalStudyTime,
    required this.reward,
    required this.isAccepted,
    required this.isRewarded,
    this.finishScore,
  });

  factory ChallengeParticipation.fromJson(Map<String, dynamic> json) {
    // startTime이 객체 형태인 경우 처리
    String formattedStartTime;
    if (json['startTime'] != null) {
      if (json['startTime'] is Map) {
        final timeObj = json['startTime'] as Map<String, dynamic>;
        final hour = timeObj['hour'] ?? 0;
        final minute = timeObj['minute'] ?? 0;
        formattedStartTime =
            '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}:00';
      } else {
        formattedStartTime = json['startTime']?.toString() ?? '';
      }
    } else {
      formattedStartTime = '';
    }

    return ChallengeParticipation(
      participationId: json['participationId'] ?? 0,
      challengeId: json['challengeId'] ?? 0,
      startDate: json['startDate'] ?? '',
      endDate: json['endDate'] ?? '',
      title: json['title'] ?? '',
      subject: json['subject'],
      challengeStatus: json['challengeStatus'] ?? 'REQUESTED',
      startTime: formattedStartTime,
      totalStudyTime: json['totalStudyTime'] ?? 0,
      reward: json['reward'] ?? 0,
      isAccepted: json['isAccepted'] ?? json['accepted'] ?? false, // 하위 호환성
      isRewarded: json['isRewarded'] ?? false,
      finishScore: json['finishScore'],
    );
  }

  // JSON 인코딩을 위한 toJson 메서드 추가
  Map<String, dynamic> toJson() {
    return {
      'participationId': participationId,
      'challengeId': challengeId,
      'startDate': startDate,
      'endDate': endDate,
      'title': title,
      'subject': subject,
      'challengeStatus': challengeStatus,
      'startTime': startTime,
      'totalStudyTime': totalStudyTime,
      'reward': reward,
      'isAccepted': isAccepted,
      'isRewarded': isRewarded,
      'finishScore': finishScore,
      'accepted': isAccepted, // 하위 호환성
    };
  }
}

class ChallengeParticipationResponse {
  final List<ChallengeParticipation> data;
  final int totalPage;
  final int totalElement;
  final int pageNumber;

  ChallengeParticipationResponse({
    required this.data,
    required this.totalPage,
    required this.totalElement,
    required this.pageNumber,
  });

  factory ChallengeParticipationResponse.fromJson(Map<String, dynamic> json) {
    List<ChallengeParticipation> participations = [];

    if (json.containsKey('data') && json['data'] is List) {
      participations =
          (json['data'] as List)
              .map((item) => ChallengeParticipation.fromJson(item))
              .toList();
    }

    return ChallengeParticipationResponse(
      data: participations,
      totalPage: json['totalPage'] ?? 0,
      totalElement: json['totalElement'] ?? 0,
      pageNumber: json['pageNumber'] ?? 0,
    );
  }

  // JSON 인코딩을 위한 toJson 메서드 추가
  Map<String, dynamic> toJson() {
    return {
      'data': data.map((item) => item.toJson()).toList(),
      'totalPage': totalPage,
      'totalElement': totalElement,
      'pageNumber': pageNumber,
    };
  }
}

enum ChallengeCategory { ALL, WEEK, SUBJECT }

extension ChallengeCategoryExtension on ChallengeCategory {
  String get value {
    switch (this) {
      case ChallengeCategory.ALL:
        return 'ALL';
      case ChallengeCategory.WEEK:
        return 'WEEK';
      case ChallengeCategory.SUBJECT:
        return 'SUBJECT';
    }
  }

  String get displayName {
    switch (this) {
      case ChallengeCategory.ALL:
        return '전체';
      case ChallengeCategory.WEEK:
        return '요일별';
      case ChallengeCategory.SUBJECT:
        return '과목별';
    }
  }
}

enum ChallengeStatus { ONGOING, COMPLETED }

extension ChallengeStatusExtension on ChallengeStatus {
  String get value {
    switch (this) {
      case ChallengeStatus.ONGOING:
        return 'ONGOING';
      case ChallengeStatus.COMPLETED:
        return 'COMPLETED';
    }
  }

  String get displayName {
    switch (this) {
      case ChallengeStatus.ONGOING:
        return '진행중';
      case ChallengeStatus.COMPLETED:
        return '완료됨';
    }
  }
}

class ChallengeService {
  static String get baseUrl => dotenv.env['API_BASE_URL'] ?? '';
  static const storage = FlutterSecureStorage();

  // 챌린지 전체 조회
  static Future<ChallengeResponse> getChallenges({
    ChallengeCategory? category,
    int page = 0,
  }) async {
    if (baseUrl.isEmpty) {
      throw Exception('API_BASE_URL가 설정되지 않았습니다. .env 파일을 확인하세요.');
    }

    String? accessToken = await AuthService.getAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('인증이 필요합니다. 로그인을 다시 시도해주세요.');
    }

    Map<String, String> queryParams = {'page': page.toString()};

    if (category != null && category != ChallengeCategory.ALL) {
      queryParams['challengeCategory'] = category.value;
    }

    final uri = Uri.parse(
      '$baseUrl/api-user/challenge',
    ).replace(queryParameters: queryParams);

    try {
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return ChallengeResponse.fromJson(responseData);
      } else {
        throw Exception('챌린지 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      if (e.toString().toLowerCase().contains('connection') ||
          e.toString().toLowerCase().contains('network') ||
          e.toString().toLowerCase().contains('socket')) {
        throw Exception('네트워크 연결을 확인해주세요.');
      }
      throw Exception('챌린지 API 요청 중 오류: $e');
    }
  }

  // 챌린지 참여하기
  static Future<ChallengeParticipation> joinChallenge({
    required int challengeId,
    required String startDate,
    required String endDate,
    required String startTime,
    required int totalStudyTime,
    required int reward,
  }) async {
    if (baseUrl.isEmpty) {
      throw Exception('API_BASE_URL가 설정되지 않았습니다. .env 파일을 확인하세요.');
    }

    String? accessToken = await AuthService.getAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('인증이 필요합니다. 로그인을 다시 시도해주세요.');
    }

    final uri = Uri.parse('$baseUrl/api-user/challenge/join/$challengeId');

    // ISO DateTime 형식으로 변환
    String formattedStartDate =
        startDate.contains('T') ? startDate : "${startDate}T09:00:00.000Z";
    String formattedEndDate =
        endDate.contains('T') ? endDate : "${endDate}T23:59:59.000Z";
    String formattedStartTime =
        startTime.contains('T')
            ? startTime
            : "${startDate.split('T')[0]}T${startTime}.000Z";

    final requestBody = {
      'startDate': formattedStartDate,
      'endDate': formattedEndDate,
      'startTime': formattedStartTime,
      'totalStudyTime': totalStudyTime,
      'reward': reward,
    };

    try {
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return ChallengeParticipation.fromJson(responseData);
      } else {
        final errorBody = jsonDecode(response.body);
        throw Exception(errorBody['message'] ?? '챌린지 참여에 실패했습니다.');
      }
    } catch (e) {
      if (e.toString().toLowerCase().contains('connection') ||
          e.toString().toLowerCase().contains('network') ||
          e.toString().toLowerCase().contains('socket')) {
        throw Exception('네트워크 연결을 확인해주세요.');
      }
      throw Exception('챌린지 참여 API 요청 중 오류: $e');
    }
  }

  // 내가 참여한 챌린지 조회
  static Future<ChallengeParticipationResponse> getMyChallenges({
    required ChallengeStatus challengeStatus,
    int page = 0,
  }) async {
    if (baseUrl.isEmpty) {
      throw Exception('API_BASE_URL가 설정되지 않았습니다. .env 파일을 확인하세요.');
    }

    String? accessToken = await AuthService.getAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('인증이 필요합니다. 로그인을 다시 시도해주세요.');
    }

    Map<String, String> queryParams = {
      'type': challengeStatus.value,
      'page': page.toString(),
    };

    final uri = Uri.parse(
      '$baseUrl/api-user/challenge/my',
    ).replace(queryParameters: queryParams);

    try {
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return ChallengeParticipationResponse.fromJson(responseData);
      } else {
        throw Exception('내가 참여한 챌린지 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      if (e.toString().toLowerCase().contains('connection') ||
          e.toString().toLowerCase().contains('network') ||
          e.toString().toLowerCase().contains('socket')) {
        throw Exception('네트워크 연결을 확인해주세요.');
      }
      throw Exception('내가 참여한 챌린지 조회 API 요청 중 오류: $e');
    }
  }

  // 자녀가 참여 중인 챌린지 조회 (부모용)
  static Future<ChallengeParticipationResponse> getChildChallenges(
    int familyId,
    int childId, {
    int page = 0,
  }) async {
    print('===== 자녀 챌린지 조회 시작 =====');
    print('familyId: $familyId');
    print('childId: $childId');
    print('page: $page');
    print('baseUrl: $baseUrl');

    if (baseUrl.isEmpty) {
      throw Exception('API_BASE_URL가 설정되지 않았습니다. .env 파일을 확인하세요.');
    }

    String? accessToken = await AuthService.getAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('인증이 필요합니다. 로그인을 다시 시도해주세요.');
    }

    Map<String, String> queryParams = {'page': page.toString()};

    final uri = Uri.parse(
      '$baseUrl/api-user/challenge/parent/$familyId/$childId',
    ).replace(queryParameters: queryParams);

    print('요청 URL: $uri');
    print(
      '액세스 토큰 앞 10자리: ${accessToken.substring(0, math.min(10, accessToken.length))}...',
    );

    try {
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      print('응답 상태 코드: ${response.statusCode}');
      print('응답 헤더: ${response.headers}');

      // 응답 본문 로깅 (UTF-8 디코딩)
      final responseBody =
          response.bodyBytes.isNotEmpty
              ? utf8.decode(response.bodyBytes)
              : '응답 본문 없음';
      print('응답 본문: $responseBody');

      if (response.statusCode == 200) {
        try {
          final Map<String, dynamic> responseData = jsonDecode(responseBody);
          print('JSON 파싱 성공: ${responseData.keys}');
          print('data 필드 길이: ${responseData['data']?.length ?? 0}');
          return ChallengeParticipationResponse.fromJson(responseData);
        } catch (parseError) {
          print('JSON 파싱 오류: $parseError');
          throw Exception('응답 JSON 파싱 실패: $parseError');
        }
      } else {
        // 오류 응답 상세 분석
        print('=== 오류 응답 상세 분석 ===');
        try {
          final errorData = jsonDecode(responseBody);
          print('서버 오류 메시지: ${errorData['message'] ?? '메시지 없음'}');
          print('서버 오류 코드: ${errorData['code'] ?? '코드 없음'}');
          print('서버 오류 상세: $errorData');
          throw Exception(
            '자녀 챌린지 조회 실패: ${response.statusCode} - ${errorData['message'] ?? '서버 오류'}',
          );
        } catch (parseError) {
          print('오류 응답 JSON 파싱 실패: $parseError');
          throw Exception(
            '자녀 챌린지 조회 실패: ${response.statusCode} - 응답: $responseBody',
          );
        }
      }
    } catch (e) {
      print('요청 중 예외 발생: $e');
      if (e.toString().toLowerCase().contains('connection') ||
          e.toString().toLowerCase().contains('network') ||
          e.toString().toLowerCase().contains('socket')) {
        throw Exception('네트워크 연결을 확인해주세요.');
      }
      throw Exception('자녀 챌린지 조회 API 요청 중 오류: $e');
    } finally {
      print('===== 자녀 챌린지 조회 종료 =====');
    }
  }

  // 신청한 챌린지 1개 조회 (부모용)
  static Future<ChallengeParticipation> getRequestedChallenge(
    int participationId,
  ) async {
    if (baseUrl.isEmpty) {
      throw Exception('API_BASE_URL가 설정되지 않았습니다. .env 파일을 확인하세요.');
    }

    String? accessToken = await AuthService.getAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('인증이 필요합니다. 로그인을 다시 시도해주세요.');
    }

    final uri = Uri.parse(
      '$baseUrl/api-user/challenge/parent/requested/$participationId',
    );

    try {
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return ChallengeParticipation.fromJson(responseData);
      } else if (response.statusCode == 400) {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? '이미 챌린지를 승낙하셨습니다');
      } else {
        throw Exception('신청한 챌린지 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      if (e.toString().toLowerCase().contains('connection') ||
          e.toString().toLowerCase().contains('network') ||
          e.toString().toLowerCase().contains('socket')) {
        throw Exception('네트워크 연결을 확인해주세요.');
      }
      throw Exception('신청한 챌린지 조회 API 요청 중 오류: $e');
    }
  }

  // 챌린지 신청 수락 (부모용)
  static Future<ChallengeParticipation> acceptChallengeApplication(
    int participationId,
  ) async {
    if (baseUrl.isEmpty) {
      throw Exception('API_BASE_URL가 설정되지 않았습니다. .env 파일을 확인하세요.');
    }

    String? accessToken = await AuthService.getAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('인증이 필요합니다. 로그인을 다시 시도해주세요.');
    }

    final uri = Uri.parse(
      '$baseUrl/api-user/challenge/parent/apply/accept/$participationId',
    );

    try {
      final response = await http.patch(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return ChallengeParticipation.fromJson(responseData);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? '챌린지 수락에 실패했습니다.');
      }
    } catch (e) {
      if (e.toString().toLowerCase().contains('connection') ||
          e.toString().toLowerCase().contains('network') ||
          e.toString().toLowerCase().contains('socket')) {
        throw Exception('네트워크 연결을 확인해주세요.');
      }
      throw Exception('챌린지 수락 API 요청 중 오류: $e');
    }
  }

  // 챌린지 신청 거절 (부모용)
  static Future<ChallengeParticipation> rejectChallengeApplication(
    int participationId,
  ) async {
    if (baseUrl.isEmpty) {
      throw Exception('API_BASE_URL가 설정되지 않았습니다. .env 파일을 확인하세요.');
    }

    String? accessToken = await AuthService.getAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('인증이 필요합니다. 로그인을 다시 시도해주세요.');
    }

    final uri = Uri.parse(
      '$baseUrl/api-user/challenge/parent/apply/reject/$participationId',
    );

    try {
      final response = await http.patch(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return ChallengeParticipation.fromJson(responseData);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? '챌린지 거절에 실패했습니다.');
      }
    } catch (e) {
      if (e.toString().toLowerCase().contains('connection') ||
          e.toString().toLowerCase().contains('network') ||
          e.toString().toLowerCase().contains('socket')) {
        throw Exception('네트워크 연결을 확인해주세요.');
      }
      throw Exception('챌린지 거절 API 요청 중 오류: $e');
    }
  }

  // 챌린지 점수 입력 (부모용)
  static Future<Map<String, dynamic>> submitChallengeScore(
    int participationId,
    int score,
  ) async {
    if (baseUrl.isEmpty) {
      throw Exception('API_BASE_URL가 설정되지 않았습니다. .env 파일을 확인하세요.');
    }

    String? accessToken = await AuthService.getAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('인증이 필요합니다. 로그인을 다시 시도해주세요.');
    }

    final uri = Uri.parse(
      '$baseUrl/api-user/challenge/parent/finish/score/$participationId',
    );

    final requestBody = {'score': score};

    try {
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return responseData;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? '챌린지 점수 입력에 실패했습니다.');
      }
    } catch (e) {
      if (e.toString().toLowerCase().contains('connection') ||
          e.toString().toLowerCase().contains('network') ||
          e.toString().toLowerCase().contains('socket')) {
        throw Exception('네트워크 연결을 확인해주세요.');
      }
      throw Exception('챌린지 점수 입력 API 요청 중 오류: $e');
    }
  }

  // === 유틸리티 메서드들 ===

  // 챌린지 상태 텍스트 반환
  static String getChallengeStatusText(String status) {
    switch (status) {
      case 'REQUESTED':
        return '승인 대기';
      case 'ACCEPT':
        return '승인됨';
      case 'REJECTED':
        return '거절됨';
      case 'COMPLETED':
        return '완료';
      case 'ACHIEVEMENT':
        return '달성';
      default:
        return status;
    }
  }

  // 챌린지 상태 색상 반환
  static Color getChallengeStatusColor(String status) {
    switch (status) {
      case 'REQUESTED':
        return const Color(0xFFFFD27F);
      case 'ACCEPT':
        return const Color(0xFF89DA8D);
      case 'REJECTED':
        return const Color(0xFFFF6B6B);
      case 'COMPLETED':
        return const Color(0xFF5D9EFF);
      case 'ACHIEVEMENT':
        return const Color(0xFF5D9EFF);
      default:
        return const Color(0xFF999999);
    }
  }

  // 날짜 포맷팅
  static String formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';

    try {
      final date = DateTime.parse(dateStr);
      return '${date.month.toString().padLeft(2, '0')}. ${date.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return '';
    }
  }

  // 날짜 범위 포맷팅
  static String formatDateRange(String? startDate, String? endDate) {
    final start = formatDate(startDate);
    final end = formatDate(endDate);

    if (start.isNotEmpty && end.isNotEmpty) {
      return '$start - $end';
    }

    return '';
  }

  // 시간 포맷팅
  static String formatTime(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return '';

    try {
      if (timeStr.contains('T')) {
        final dateTime = DateTime.parse(timeStr);
        return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
      } else if (timeStr.contains(':')) {
        return timeStr.substring(0, 5); // HH:MM 형태로 반환
      }
      return timeStr;
    } catch (e) {
      return '';
    }
  }

  // 챌린지 진행 상태 확인 (부모용)
  static String getProgressStatus(String challengeStatus, String? endDate) {
    if (challengeStatus == 'REQUESTED') {
      return '승인 대기';
    } else if (challengeStatus == 'ACCEPT') {
      if (endDate != null) {
        try {
          final end = DateTime.parse(endDate);
          final now = DateTime.now();
          if (now.isBefore(end)) {
            return '진행중';
          } else {
            return '완료한';
          }
        } catch (e) {
          return '진행중';
        }
      }
      return '진행중';
    } else if (challengeStatus == 'ACHIEVEMENT') {
      return '달성';
    }
    return challengeStatus;
  }

  // 챌린지 보상 모달 표시 여부 확인 (부모용)
  static bool shouldShowRewardModal(Map<String, dynamic> challenge) {
    // 새 필드명과 기존 필드명 모두 지원 (하위 호환성)
    final isRewarded =
        challenge['isRewarded'] ?? challenge['rewarded'] ?? false;
    final challengeStatus = challenge['challengeStatus'] ?? '';
    final endDate = challenge['endDate'];

    print('🏆 shouldShowRewardModal 분석:');
    print('   - isRewarded: $isRewarded');
    print('   - challengeStatus: $challengeStatus');
    print('   - endDate: $endDate');

    // 이미 보상이 지급된 경우 모달 표시하지 않음
    if (isRewarded) {
      print('   - 결과: false (이미 보상 지급됨)');
      return false;
    }

    // ACHIEVEMENT 상태인 경우 (완료됨)
    if (challengeStatus == 'ACHIEVEMENT') {
      print('   - 결과: true (ACHIEVEMENT 상태)');
      return true;
    }

    // ACCEPT 상태이면서 기간이 만료된 경우
    if (challengeStatus == 'ACCEPT' && endDate != null) {
      try {
        final end = DateTime.parse(endDate);
        final now = DateTime.now();
        final isExpired = now.isAfter(end);
        print('   - ACCEPT 상태, 기간만료: $isExpired');
        print('   - 결과: $isExpired');
        return isExpired;
      } catch (e) {
        print('   - 날짜 파싱 오류: $e');
        print('   - 결과: false');
        return false;
      }
    }

    print('   - 결과: false (조건 불만족)');
    return false;
  }

  // 챌린지 점수 입력 필요 여부 확인 (부모용)
  static bool needsScoreInput(Map<String, dynamic> challenge) {
    // 새 필드명과 기존 필드명 모두 지원 (하위 호환성)
    final finishScore = challenge['finishScore'] ?? challenge['score'];
    final isRewarded =
        challenge['isRewarded'] ?? challenge['rewarded'] ?? false;

    print('🏆 needsScoreInput 분석:');
    print('   - finishScore: $finishScore');
    print('   - isRewarded: $isRewarded');

    // 이미 보상이 지급된 경우 점수 입력 불필요
    if (isRewarded) {
      print('   - 결과: false (이미 보상 지급됨)');
      return false;
    }

    // 점수가 없는 경우 입력 필요
    final result = finishScore == null;
    print('   - 결과: $result');
    return result;
  }

  // 챌린지 평가 상태 텍스트 반환 (부모용)
  static String getChallengeEvaluationStatusText(
    Map<String, dynamic> challenge,
  ) {
    // 새 필드명과 기존 필드명 모두 지원 (하위 호환성)
    final isRewarded =
        challenge['isRewarded'] ?? challenge['rewarded'] ?? false;
    final finishScore = challenge['finishScore'] ?? challenge['score'];

    if (isRewarded) {
      return '보상 완료';
    } else if (finishScore != null) {
      return '점수 입력됨';
    } else {
      return '평가 대기';
    }
  }
}
