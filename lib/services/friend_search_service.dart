import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';

class FriendSearchService {
  // 서버 기본 URL
  static const String baseUrl = 'http://3.34.52.239:8080';

  // 친구 검색 API (GET /api-user/friend/search)
  static Future<List<Map<String, dynamic>>> searchFriends(
    String keyword,
  ) async {
    try {
      print('===== 친구 검색 시작 =====');
      print('검색 키워드: "$keyword"');
      print('요청 시간: ${DateTime.now()}');

      // 키워드가 비어있으면 빈 배열 반환
      if (keyword.trim().isEmpty) {
        print('키워드가 비어있습니다. 빈 결과 반환.');
        return [];
      }

      // 토큰 가져오기
      final accessToken = await AuthService.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        print('액세스 토큰이 없습니다.');
        return [];
      }

      // API URL 구성
      final url = Uri.parse(
        '$baseUrl/api-user/friend/search?keyword=${Uri.encodeComponent(keyword)}',
      );
      print('친구 검색 API 호출: $url');

      // 헤더 설정
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
        'Accept': 'application/json; charset=utf-8',
      };
      print(
        '요청 헤더: Content-Type: application/json, Authorization: Bearer ${accessToken.substring(0, min(10, accessToken.length))}...',
      );

      // API 호출
      final response = await http.get(url, headers: headers);
      print('친구 검색 응답 상태: ${response.statusCode}');

      if (response.statusCode == 200) {
        // UTF-8로 명시적으로 디코딩
        final jsonBody = utf8.decode(response.bodyBytes);
        final List<dynamic> data = json.decode(jsonBody);

        print('검색 결과 개수: ${data.length}');

        // 응답 데이터를 Map<String, dynamic> 형태로 변환
        final List<Map<String, dynamic>> searchResults = [];

        int index = 0;
        for (final item in data) {
          final Map<String, dynamic> result = {
            'userInfo': item['userInfo'] ?? {},
            'friendInfo': item['friendInfo'] ?? {},
          };

          // 사용자 정보 로깅
          final userInfo = result['userInfo'];
          final friendInfo = result['friendInfo'];

          print('검색된 사용자[$index]:');
          print('- 사용자 ID: ${userInfo['userId']}');
          print('- 실제 이름: ${userInfo['realName']}');
          print('- 주민등록번호: ${userInfo['rrn'] ?? '정보 없음'}');
          print('- 전화번호: ${userInfo['phone'] ?? '정보 없음'}');
          print('- 상태 메시지: ${userInfo['statusMessage'] ?? '상태 메시지 없음'}');
          print('- 은행명: ${userInfo['backName'] ?? '은행 정보 없음'}');
          print('- 은행 코드: ${userInfo['backCode'] ?? '은행 코드 없음'}');
          print('- 계좌번호: ${userInfo['backAccount'] ?? '계좌 정보 없음'}');
          print('- 프로필 이미지: ${userInfo['profileImagePath'] ?? '이미지 없음'}');
          print('- 목표 금액: ${userInfo['targetAmount'] ?? 0}');
          print('- 학교명: ${userInfo['schoolName'] ?? '학교 정보 없음'}');
          print('- 학교 유형: ${userInfo['schoolType'] ?? '학교 유형 없음'}');
          print('- 지역: ${userInfo['region'] ?? '지역 정보 없음'}');
          print('- 주소: ${userInfo['address'] ?? '주소 정보 없음'}');
          print('- 역할: ${userInfo['role'] ?? '역할 정보 없음'}');

          print('친구 정보:');
          print('- 친구 여부: ${friendInfo['isFriend'] ?? false}');
          print('- 친구 ID: ${friendInfo['friendId'] ?? '정보 없음'}');
          print('- 커스텀 이름: ${friendInfo['customName'] ?? '정보 없음'}');
          print('- 차단 여부: ${friendInfo['isBlocked'] ?? false}');
          print('- 친한 친구 여부: ${friendInfo['isBestFriend'] ?? false}');

          // 클라이언트 호환성을 위해 최상위 레벨에도 친구 정보 추가
          result['isFriend'] = friendInfo['isFriend'];
          result['friendId'] = friendInfo['friendId'];
          result['customName'] = friendInfo['customName'];
          result['isBlocked'] = friendInfo['isBlocked'];
          result['isBestFriend'] = friendInfo['isBestFriend'];

          print('---');

          searchResults.add(result);
          index++;
        }

        print('===== 친구 검색 완료 =====');
        return searchResults;
      } else {
        print('API 오류: ${response.statusCode}');
        print('응답 헤더: ${response.headers}');
        print('응답 본문: ${utf8.decode(response.bodyBytes)}');

        // 상세 오류 로그 추가
        if (response.statusCode == 500) {
          print('서버 내부 오류가 발생했습니다. 잠시 후 다시 시도해주세요.');
          print('요청 URL: $url');
          print(
            '요청 헤더: Content-Type: application/json, Authorization: Bearer ${accessToken.substring(0, min(10, accessToken.length))}...',
          );
        }

        return [];
      }
    } catch (e) {
      print('친구 검색 중 예외 발생: $e');
      return [];
    }
  }

  // 친구 검색 기록 저장 API
  static Future<Map<String, dynamic>?> saveSearchHistory(int friendId) async {
    try {
      print('===== 친구 검색 기록 저장 시작 =====');
      print('친구 ID: $friendId');
      print('요청 시간: ${DateTime.now()}');

      // 토큰 가져오기
      final accessToken = await AuthService.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        print('액세스 토큰이 없습니다.');
        return null;
      }

      // API URL 구성
      final url = Uri.parse('$baseUrl/api-user/friend/search/history');
      print('친구 검색 기록 저장 API 호출: $url');

      // 요청 본문 구성
      final body = json.encode({'friendId': friendId});
      print('요청 본문: $body');

      // 헤더 설정
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
        'Accept': 'application/json; charset=utf-8',
      };

      // API 호출
      final response = await http.post(url, headers: headers, body: body);
      print('친구 검색 기록 저장 응답 상태: ${response.statusCode}');

      if (response.statusCode == 200) {
        // UTF-8로 명시적으로 디코딩
        final jsonBody = utf8.decode(response.bodyBytes);
        final Map<String, dynamic> data = json.decode(jsonBody);

        print('저장된 검색 기록 ID: ${data['friendSearchHistoryId']}');
        print('===== 친구 검색 기록 저장 완료 =====');
        return data;
      } else {
        print('API 오류: ${response.statusCode}');
        print('응답 본문: ${utf8.decode(response.bodyBytes)}');
        return null;
      }
    } catch (e) {
      print('친구 검색 기록 저장 중 예외 발생: $e');
      return null;
    }
  }

  // 친구 검색 기록 삭제 API
  static Future<bool> deleteSearchHistory(List<int> searchHistoryIds) async {
    try {
      print('===== 친구 검색 기록 삭제 시작 =====');
      print('삭제할 검색 기록 IDs: $searchHistoryIds');
      print('요청 시간: ${DateTime.now()}');

      if (searchHistoryIds.isEmpty) {
        print('삭제할 검색 기록 ID가 없습니다.');
        return false;
      }

      // 토큰 가져오기
      final accessToken = await AuthService.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        print('액세스 토큰이 없습니다.');
        return false;
      }

      // API URL 구성
      final url = Uri.parse('$baseUrl/api-user/friend/search/history');
      print('친구 검색 기록 삭제 API 호출: $url');

      // 요청 본문 구성
      final body = json.encode({'searchHistoryIds': searchHistoryIds});
      print('요청 본문: $body');

      // 헤더 설정
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
        'Accept': 'application/json; charset=utf-8',
      };

      // API 호출
      final response = await http.delete(url, headers: headers, body: body);
      print('친구 검색 기록 삭제 응답 상태: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        print('===== 친구 검색 기록 삭제 완료 =====');
        return true;
      } else {
        print('API 오류: ${response.statusCode}');
        print('응답 본문: ${utf8.decode(response.bodyBytes)}');
        return false;
      }
    } catch (e) {
      print('친구 검색 기록 삭제 중 예외 발생: $e');
      return false;
    }
  }

  // 친구 최근 검색어 조회 API
  static Future<List<Map<String, dynamic>>> getSearchHistory() async {
    try {
      print('===== 친구 최근 검색어 조회 시작 =====');
      print('요청 시간: ${DateTime.now()}');

      // 토큰 가져오기
      final accessToken = await AuthService.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        print('액세스 토큰이 없습니다.');
        return [];
      }

      // API URL 구성
      final url = Uri.parse('$baseUrl/api-user/friend/search/history');
      print('친구 최근 검색어 조회 API 호출: $url');

      // 헤더 설정
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
        'Accept': 'application/json; charset=utf-8',
      };

      // API 호출
      final response = await http.get(url, headers: headers);
      print('친구 최근 검색어 조회 응답 상태: ${response.statusCode}');

      if (response.statusCode == 200) {
        // UTF-8로 명시적으로 디코딩
        final jsonBody = utf8.decode(response.bodyBytes);
        final List<dynamic> data = json.decode(jsonBody);

        print('최근 검색어 개수: ${data.length}');

        // 응답 데이터를 Map<String, dynamic> 형태로 변환
        final List<Map<String, dynamic>> searchHistory = [];

        for (final item in data) {
          final Map<String, dynamic> history = {
            'searchHistoryId': item['searchHistoryId'],
            'keyword': item['keyword'],
            'friendId': item['friendId'],
            'searchAt': item['searchAt'],
          };

          print('검색 기록:');
          print('- 검색 기록 ID: ${history['searchHistoryId']}');
          print('- 키워드: ${history['keyword']}');
          print('- 친구 ID: ${history['friendId']}');
          print('- 검색 시간: ${history['searchAt']}');

          searchHistory.add(history);
        }

        print('===== 친구 최근 검색어 조회 완료 =====');
        return searchHistory;
      } else {
        print('API 오류: ${response.statusCode}');
        print('응답 본문: ${utf8.decode(response.bodyBytes)}');
        return [];
      }
    } catch (e) {
      print('친구 최근 검색어 조회 중 예외 발생: $e');
      return [];
    }
  }

  // 전체 검색 기록 삭제 (편의 메서드)
  static Future<bool> clearAllSearchHistory() async {
    try {
      // 먼저 모든 검색 기록 조회
      final searchHistory = await getSearchHistory();

      if (searchHistory.isEmpty) {
        print('삭제할 검색 기록이 없습니다.');
        return true;
      }

      // 모든 검색 기록 ID 추출
      final List<int> allIds =
          searchHistory.map((item) => item['searchHistoryId'] as int).toList();

      // 모든 검색 기록 삭제
      return await deleteSearchHistory(allIds);
    } catch (e) {
      print('전체 검색 기록 삭제 중 예외 발생: $e');
      return false;
    }
  }
}
