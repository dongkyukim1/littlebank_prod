import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';
import 'dart:math' as Math;
import '../services/push_notification_service.dart';
import '../screens/notice_kid/notification_service.dart';

class FeedService {
  // 서버 기본 URL
  static const String baseUrl = 'http://3.34.52.239:8080';

  // 피드 생성 API
  static Future<Map<String, dynamic>?> createFeed({
    required String title,
    required String gradeCategory,
    required String subjectCategory,
    required String tagCategory,
    String? content,
    List<Map<String, String>>? images,
  }) async {
    try {
      print('===== 피드 생성 시작 =====');

      // 토큰 가져오기
      final accessToken = await AuthService.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        print('액세스 토큰이 없습니다.');
        return null;
      }

      // API URL 구성
      final url = Uri.parse('$baseUrl/api-user/feed/create');
      print('피드 생성 API 호출: $url');

      // 요청 본문 구성
      final Map<String, dynamic> requestBody = {
        'title': title,
        'gradeCategory': gradeCategory,
        'subjectCategory': subjectCategory,
        'tagCategory': tagCategory,
      };

      // content가 null이 아닌 경우에만 추가
      if (content != null) {
        requestBody['content'] = content;
      }

      // images가 null이 아닌 경우에만 추가
      if (images != null && images.isNotEmpty) {
        requestBody['images'] = images;
      }

      print('요청 본문: ${jsonEncode(requestBody)}');

      // 헤더 설정 - 토큰 포함
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      };

      // API 호출
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(requestBody),
      );

      print('피드 생성 응답 상태: ${response.statusCode}');

      // 응답 처리
      if (response.statusCode == 200 || response.statusCode == 201) {
        // UTF-8로 명시적으로 디코딩
        final String responseBody = utf8.decode(response.bodyBytes);
        print('응답 원본: $responseBody');

        // 서버가 "업로드 완료"와 같은 텍스트 응답을 주는 경우 처리
        if (responseBody.contains("업로드 완료") || !responseBody.startsWith("{")) {
          print('피드 생성 완료 (텍스트 응답: $responseBody)');
          return {
            'success': true,
            'message': '피드가 성공적으로 생성되었습니다.',
            'serverMessage': responseBody,
          };
        }

        // 응답이 JSON 형식인 경우 파싱 시도
        try {
          final Map<String, dynamic> data = json.decode(responseBody);
          print('피드 생성 결과: $data');
          print('===== 피드 생성 완료 =====');
          return data;
        } catch (e) {
          print('JSON 파싱 오류가 발생했지만, 요청은 성공했습니다: $e');
          return {
            'success': true,
            'message': '피드가 성공적으로 생성되었습니다.',
            'serverMessage': responseBody,
          };
        }
      } else {
        print('API 오류: ${response.statusCode}');

        try {
          // UTF-8로 명시적으로 디코딩
          final jsonBody = utf8.decode(response.bodyBytes);
          print('오류 응답 원본: $jsonBody');

          // JSON 형식인 경우에만 파싱 시도
          if (jsonBody.trim().startsWith('{')) {
            final errorData = json.decode(jsonBody);
            print('오류 메시지: ${errorData['message'] ?? '알 수 없음'}');
            print('오류 코드: ${errorData['code'] ?? '알 수 없음'}');

            if (errorData.containsKey('errors')) {
              print('상세 오류: ${errorData['errors']}');
            }
          } else {
            print('JSON 형식이 아닌 오류 응답: $jsonBody');
          }
        } catch (e) {
          print('오류 응답을 파싱할 수 없습니다: $e');
          print('응답 본문: ${response.body}');
        }

        print('===== 피드 생성 실패 =====');
        return null;
      }
    } catch (e) {
      print('피드 생성 중 예외 발생: $e');
      print('===== 피드 생성 실패 (예외) =====');
      return null;
    }
  }

  // 피드 목록 조회 API
  static Future<Map<String, dynamic>?> getFeedList({
    String? gradeCategory,
    String? subjectCategory,
    String? tagCategory,
    int page = 0,
    int size = 10,
    List<String>? sort,
  }) async {
    try {
      print('===== 피드 목록 조회 시작 =====');

      // 토큰 가져오기
      final accessToken = await AuthService.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        print('액세스 토큰이 없습니다.');
        return null;
      }

      // 쿼리 파라미터 구성
      final queryParams = <String, String>{};

      // 필터 파라미터 추가
      if (gradeCategory != null && gradeCategory != 'ALL') {
        queryParams['gradeCategory'] = gradeCategory;
      }
      if (subjectCategory != null && subjectCategory != 'ALL') {
        queryParams['subjectCategory'] = subjectCategory;
      }
      if (tagCategory != null && tagCategory != 'ALL') {
        queryParams['tagCategory'] = tagCategory;
      }

      // 페이징 정보 추가 (스웨거 스펙에 맞게 수정)
      queryParams['page'] = page.toString();
      queryParams['size'] = size.toString();

      // 정렬 정보 추가
      if (sort != null && sort.isNotEmpty) {
        for (int i = 0; i < sort.length; i++) {
          queryParams['sort[$i]'] = sort[i];
        }
      } else {
        // 기본 정렬 (최신순)
        queryParams['sort'] = 'createdDate,desc';
      }

      print('쿼리 파라미터: $queryParams');

      // API URL 구성
      final uri = Uri.parse(
        '$baseUrl/api-user/feed',
      ).replace(queryParameters: queryParams);
      print('피드 목록 조회 API 호출: $uri');

      // 헤더 설정 - 토큰 포함 및 추가 헤더
      final headers = {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      print('요청 헤더: $headers');

      // API 호출
      final response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 15));

      print('피드 목록 조회 응답 상태: ${response.statusCode}');
      print('응답 헤더: ${response.headers}');

      // 응답 처리
      if (response.statusCode == 200) {
        // UTF-8로 명시적으로 디코딩
        final String responseBody = utf8.decode(response.bodyBytes);
        print('응답 원본: $responseBody');

        try {
          final Map<String, dynamic> data = json.decode(responseBody);

          // 상세 로깅 추가
          if (data.containsKey('content') && data['content'] is List) {
            final List<dynamic> content = data['content'];
            print('피드 목록 개수: ${content.length}');

            // 첫 번째 항목의 필드 구조 확인
            if (content.isNotEmpty) {
              final firstItem = content[0];
              print('첫 번째 피드 항목 구조:');
              firstItem.forEach((key, value) {
                print('  $key: $value (${value?.runtimeType})');

                // createdDate 필드에 대한 상세 로깅
                if (key == 'createdDate') {
                  print('  -> 발견된 createdDate: $value (${value?.runtimeType})');
                  if (value != null) {
                    try {
                      final parsedDate = DateTime.parse(value.toString());
                      print('  -> 파싱된 createdDate: $parsedDate');
                    } catch (e) {
                      print('  -> createdDate 파싱 오류: $e');
                    }
                  }
                }
              });

              // 모든 아이템의 createdDate 필드 확인
              print('=== 모든 아이템의 createdDate 필드 상세 조회 ===');
              for (int i = 0; i < content.length; i++) {
                final item = content[i];
                final feedId = item['feedId'];
                final title = item['title'];
                final createdDate = item['createdDate'];
                print('피드 $feedId ($title) - createdDate: $createdDate');

                // createdDate 파싱 시도
                if (createdDate != null) {
                  try {
                    final parsedDate = DateTime.parse(createdDate.toString());
                    print('  -> 파싱된 시간: $parsedDate (UTC)');
                    print('  -> 한국 시간: ${parsedDate.add(Duration(hours: 9))}');
                  } catch (e) {
                    print('  -> 시간 파싱 실패: $e');
                  }
                }
              }
            }
          } else {
            print('content 필드가 없거나 List가 아닙니다.');
          }

          print('피드 목록 조회 결과: ${data['content']?.length ?? 0}개 항목');
          print('총 페이지: ${data['totalPages']}');
          print('===== 피드 목록 조회 완료 =====');
          return data;
        } catch (e) {
          print('JSON 파싱 오류가 발생했습니다: $e');
          return null;
        }
      } else {
        print('API 오류: ${response.statusCode}');

        try {
          // UTF-8로 명시적으로 디코딩
          final jsonBody = utf8.decode(response.bodyBytes);
          print('오류 응답 원본: $jsonBody');

          // JSON 형식인 경우에만 파싱 시도
          if (jsonBody.trim().startsWith('{')) {
            final errorData = json.decode(jsonBody);
            print('오류 메시지: ${errorData['message'] ?? '알 수 없음'}');
            print('오류 코드: ${errorData['code'] ?? '알 수 없음'}');

            if (errorData.containsKey('errors')) {
              print('상세 오류: ${errorData['errors']}');
            }
          } else {
            print('JSON 형식이 아닌 오류 응답: $jsonBody');
          }
        } catch (e) {
          print('오류 응답을 파싱할 수 없습니다: $e');
          print('응답 본문: ${response.body}');
        }

        print('===== 피드 목록 조회 실패 =====');
        return null;
      }
    } catch (e) {
      print('피드 목록 조회 중 예외 발생: $e');
      print('===== 피드 목록 조회 실패 (예외) =====');
      return null;
    }
  }

  // 피드 좋아요 순 목록 조회 API
  static Future<Map<String, dynamic>?> getFeedListByLikes({
    String? gradeCategory,
    String? subjectCategory,
    String? tagCategory,
    int page = 0,
    int size = 10,
    List<String>? sort,
  }) async {
    try {
      print('===== 좋아요 순 피드 목록 조회 시작 =====');

      // 토큰 가져오기
      final accessToken = await AuthService.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        print('액세스 토큰이 없습니다.');
        return null;
      }

      // 쿼리 파라미터 구성
      final queryParams = <String, String>{};

      // 필터 파라미터 추가
      if (gradeCategory != null && gradeCategory != 'ALL') {
        queryParams['gradeCategory'] = gradeCategory;
      }
      if (subjectCategory != null && subjectCategory != 'ALL') {
        queryParams['subjectCategory'] = subjectCategory;
      }
      if (tagCategory != null && tagCategory != 'ALL') {
        queryParams['tagCategory'] = tagCategory;
      }

      // 페이징 정보 추가 (스웨거 스펙에 맞게 수정)
      queryParams['page'] = page.toString();
      queryParams['size'] = size.toString();

      // 정렬 정보 추가
      if (sort != null && sort.isNotEmpty) {
        for (int i = 0; i < sort.length; i++) {
          queryParams['sort[$i]'] = sort[i];
        }
      }

      print('쿼리 파라미터: $queryParams');

      // API URL 구성 (좋아요 순 엔드포인트 사용)
      final uri = Uri.parse(
        '$baseUrl/api-user/feed/likes',
      ).replace(queryParameters: queryParams);
      print('좋아요 순 피드 목록 조회 API 호출: $uri');

      // 헤더 설정 - 토큰 포함 및 추가 헤더
      final headers = {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      print('요청 헤더: $headers');

      // API 호출
      final response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 15));

      print('좋아요 순 피드 목록 조회 응답 상태: ${response.statusCode}');
      print('응답 헤더: ${response.headers}');

      // 응답 처리
      if (response.statusCode == 200) {
        // UTF-8로 명시적으로 디코딩
        final String responseBody = utf8.decode(response.bodyBytes);
        print('응답 원본: $responseBody');

        try {
          final Map<String, dynamic> data = json.decode(responseBody);

          // 상세 로깅 추가
          if (data.containsKey('content') && data['content'] is List) {
            final List<dynamic> content = data['content'];
            print('좋아요 순 피드 목록 개수: ${content.length}');

            // 첫 번째 항목의 필드 구조 확인
            if (content.isNotEmpty) {
              final firstItem = content[0];
              print('첫 번째 피드 항목 구조:');
              firstItem.forEach((key, value) {
                print('  $key: $value (${value?.runtimeType})');

                // createdDate 필드에 대한 상세 로깅
                if (key == 'createdDate') {
                  print('  -> 발견된 createdDate: $value (${value?.runtimeType})');
                  if (value != null) {
                    try {
                      final parsedDate = DateTime.parse(value.toString());
                      print('  -> 파싱된 createdDate: $parsedDate');
                    } catch (e) {
                      print('  -> createdDate 파싱 오류: $e');
                    }
                  }
                }
              });

              // 모든 아이템의 createdDate 필드 확인
              print('=== 모든 아이템의 createdDate 필드 상세 조회 ===');
              for (int i = 0; i < content.length; i++) {
                final item = content[i];
                final feedId = item['feedId'];
                final title = item['title'];
                final createdDate = item['createdDate'];
                print('피드 $feedId ($title) - createdDate: $createdDate');

                // createdDate 파싱 시도
                if (createdDate != null) {
                  try {
                    final parsedDate = DateTime.parse(createdDate.toString());
                    print('  -> 파싱된 시간: $parsedDate (UTC)');
                    print('  -> 한국 시간: ${parsedDate.add(Duration(hours: 9))}');
                  } catch (e) {
                    print('  -> 시간 파싱 실패: $e');
                  }
                }
              }
            }
          } else {
            print('content 필드가 없거나 List가 아닙니다.');
          }

          print('좋아요 순 피드 목록 조회 결과: ${data['content']?.length ?? 0}개 항목');
          print('총 페이지: ${data['totalPages']}');
          print('===== 좋아요 순 피드 목록 조회 완료 =====');
          return data;
        } catch (e) {
          print('JSON 파싱 오류가 발생했습니다: $e');
          return null;
        }
      } else {
        print('API 오류: ${response.statusCode}');

        try {
          // UTF-8로 명시적으로 디코딩
          final jsonBody = utf8.decode(response.bodyBytes);
          print('오류 응답 원본: $jsonBody');

          // JSON 형식인 경우에만 파싱 시도
          if (jsonBody.trim().startsWith('{')) {
            final errorData = json.decode(jsonBody);
            print('오류 메시지: ${errorData['message'] ?? '알 수 없음'}');
            print('오류 코드: ${errorData['code'] ?? '알 수 없음'}');

            if (errorData.containsKey('errors')) {
              print('상세 오류: ${errorData['errors']}');
            }
          } else {
            print('JSON 형식이 아닌 오류 응답: $jsonBody');
          }
        } catch (e) {
          print('오류 응답을 파싱할 수 없습니다: $e');
          print('응답 본문: ${response.body}');
        }

        print('===== 좋아요 순 피드 목록 조회 실패 =====');
        return null;
      }
    } catch (e) {
      print('좋아요 순 피드 목록 조회 중 예외 발생: $e');
      print('===== 좋아요 순 피드 목록 조회 실패 (예외) =====');
      return null;
    }
  }

  // 피드 상세 조회 API
  static Future<Map<String, dynamic>?> getFeedDetail(int feedId) async {
    try {
      print('===== 피드 상세 조회 시작 =====');

      // 토큰 가져오기
      final accessToken = await AuthService.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        print('액세스 토큰이 없습니다.');
        return null;
      }

      // API URL 구성
      final url = Uri.parse('$baseUrl/api-user/feed/$feedId');
      print('피드 상세 조회 API 호출: $url');

      // 헤더 설정 - 토큰 포함
      final headers = {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      print('요청 헤더: $headers');

      // API 호출
      final response = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 15));

      print('피드 상세 조회 응답 상태: ${response.statusCode}');
      print('응답 헤더: ${response.headers}');

      // 응답 처리
      if (response.statusCode == 200) {
        // UTF-8로 명시적으로 디코딩
        final String responseBody = utf8.decode(response.bodyBytes);
        print('응답 원본: $responseBody');

        try {
          final Map<String, dynamic> data = json.decode(responseBody);
          print('피드 상세 조회 결과: $data');
          print('===== 피드 상세 조회 완료 =====');
          return data;
        } catch (e) {
          print('JSON 파싱 오류가 발생했습니다: $e');
          return null;
        }
      } else {
        print('API 오류: ${response.statusCode}');

        try {
          // UTF-8로 명시적으로 디코딩
          final jsonBody = utf8.decode(response.bodyBytes);
          print('오류 응답 원본: $jsonBody');

          // JSON 형식인 경우에만 파싱 시도
          if (jsonBody.trim().startsWith('{')) {
            final errorData = json.decode(jsonBody);
            print('오류 메시지: ${errorData['message'] ?? '알 수 없음'}');
            print('오류 코드: ${errorData['code'] ?? '알 수 없음'}');

            if (errorData.containsKey('errors')) {
              print('상세 오류: ${errorData['errors']}');
            }
          } else {
            print('JSON 형식이 아닌 오류 응답: $jsonBody');
          }
        } catch (e) {
          print('오류 응답을 파싱할 수 없습니다: $e');
          print('응답 본문: ${response.body}');
        }

        print('===== 피드 상세 조회 실패 =====');
        return null;
      }
    } catch (e) {
      print('피드 상세 조회 중 예외 발생: $e');
      print('===== 피드 상세 조회 실패 (예외) =====');
      return null;
    }
  }

  // 피드 수정 API
  static Future<Map<String, dynamic>?> updateFeed({
    required int feedId,
    required String title,
    required String gradeCategory,
    required String subjectCategory,
    required String tagCategory,
    required String content,
    required List<Map<String, String>> images,
  }) async {
    try {
      print('===== 피드 수정 시작 =====');

      // 토큰 가져오기
      final accessToken = await AuthService.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        print('액세스 토큰이 없습니다.');
        return null;
      }

      // API URL 구성
      final url = Uri.parse('$baseUrl/api-user/feed/update/$feedId');
      print('피드 수정 API 호출: $url');

      // 요청 데이터 구성
      final Map<String, dynamic> requestData = {
        'title': title,
        'gradeCategory': gradeCategory,
        'subjectCategory': subjectCategory,
        'tagCategory': tagCategory,
        'content': content,
        'images': images,
      };

      // 헤더 설정 - 토큰 포함
      final headers = {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      };

      // API 호출 (PUT 메서드 사용)
      final response = await http.put(
        url,
        headers: headers,
        body: jsonEncode(requestData),
      );

      print('피드 수정 응답 상태: ${response.statusCode}');
      print('피드 수정 응답 내용: ${response.body}');

      // 응답 처리
      if (response.statusCode == 200) {
        // UTF-8로 명시적으로 디코딩
        final String responseBody = utf8.decode(response.bodyBytes);

        if (responseBody.isNotEmpty) {
          final result = jsonDecode(responseBody);
          if (result != null) {
            return result is Map<String, dynamic> ? result : {'success': true};
          }
        }

        // 빈 응답이거나 디코딩 불가능한 경우 성공 플래그만 반환
        return {'success': true};
      } else {
        // 오류 처리
        final errorResponse = utf8.decode(response.bodyBytes);
        print('피드 수정 실패: $errorResponse');
        return null;
      }
    } catch (e) {
      // 예외 처리
      print('피드 수정 중 오류 발생: $e');
      return null;
    }
  }

  // 피드 좋아요 API
  static Future<bool> toggleLike(int feedId, bool currentLikeStatus) async {
    try {
      print('===== 피드 좋아요 상태 변경 시작 =====');
      print('현재 좋아요 상태: ${currentLikeStatus ? "좋아요 됨" : "좋아요 안됨"}');

      // 현재 좋아요 상태에 따라 적절한 메서드 호출
      if (currentLikeStatus) {
        // 이미 좋아요 한 상태면 좋아요 취소 API 호출
        return await unlikeFeed(feedId);
      } else {
        // 좋아요 하지 않은 상태면 좋아요 API 호출
        return await likeFeed(feedId);
      }
    } catch (e) {
      print('피드 좋아요 상태 변경 중 예외 발생: $e');
      print('===== 피드 좋아요 상태 변경 실패 (예외) =====');
      return false;
    }
  }

  // 피드 좋아요 추가 API
  static Future<bool> likeFeed(int feedId) async {
    try {
      print('===== 피드 좋아요 추가 시작 =====');

      // 토큰 가져오기
      final accessToken = await AuthService.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        print('액세스 토큰이 없습니다.');
        return false;
      }

      // FCM 토큰 가져오기
      final fcmToken = await _getFcmToken();

      // API URL 구성
      final url = Uri.parse('$baseUrl/api-user/feed/$feedId/like');
      print('피드 좋아요 API 호출: $url');

      // 헤더 설정 - 토큰 포함
      final headers = {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      };

      // 요청 본문 구성 - FCM 토큰 포함
      final Map<String, dynamic> body = {'fcmToken': fcmToken};

      // API 호출 (POST 메서드 사용)
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(body),
      );

      print('피드 좋아요 응답 상태: ${response.statusCode}');

      // 응답 처리
      if (response.statusCode == 200) {
        // UTF-8로 명시적으로 디코딩
        final String responseBody = utf8.decode(response.bodyBytes);
        print('응답 원본: $responseBody');
        print('===== 피드 좋아요 추가 완료 =====');

        // 🔔 좋아요 성공 시 알림 표시
        try {
          final notificationService = NotificationService();
          notificationService.showFeedCommentNotification(
            message: '좋아요를 눌렀어요! ❤️',
            feedId: feedId.toString(),
            commentAuthor: '나',
            onTap: () {
              print('❤️ 좋아요 알림 탭: 피드 상세 화면으로 이동');
              // 여기에 피드 상세 화면으로 이동하는 네비게이션 로직 추가 가능
            },
          );
          print('🔔 좋아요 알림 표시 완료');
        } catch (e) {
          print('⚠️ 좋아요 알림 표시 중 오류: $e');
          // 알림 표시 실패해도 좋아요 자체는 성공으로 처리
        }

        return true;
      } else {
        print('API 오류: ${response.statusCode}');

        try {
          // UTF-8로 명시적으로 디코딩
          final jsonBody = utf8.decode(response.bodyBytes);
          print('오류 응답 원본: $jsonBody');

          // JSON 형식인 경우에만 파싱 시도
          if (jsonBody.trim().startsWith('{')) {
            final errorData = json.decode(jsonBody);
            print('오류 메시지: ${errorData['message'] ?? '알 수 없음'}');
            print('오류 코드: ${errorData['code'] ?? '알 수 없음'}');

            if (errorData.containsKey('errors')) {
              print('상세 오류: ${errorData['errors']}');
            }
          } else {
            print('JSON 형식이 아닌 오류 응답: $jsonBody');
          }
        } catch (e) {
          print('오류 응답을 파싱할 수 없습니다: $e');
          print('응답 본문: ${response.body}');
        }

        print('===== 피드 좋아요 추가 실패 =====');
        return false;
      }
    } catch (e) {
      print('피드 좋아요 추가 중 예외 발생: $e');
      print('===== 피드 좋아요 추가 실패 (예외) =====');
      return false;
    }
  }

  // FCM 토큰 가져오기 헬퍼 함수
  static Future<String> _getFcmToken() async {
    try {
      // PushNotificationService에서 토큰 가져오기 시도
      final pushService = PushNotificationService();
      await pushService.init(); // 초기화되지 않았을 경우를 대비

      // 토큰이 없으면 빈 문자열 반환
      return pushService.token ?? '';
    } catch (e) {
      print('FCM 토큰 가져오기 실패: $e');
      return '';
    }
  }

  // 피드 좋아요 취소 API
  static Future<bool> unlikeFeed(int feedId) async {
    try {
      print('===== 피드 좋아요 취소 시작 =====');

      // 토큰 가져오기
      final accessToken = await AuthService.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        print('액세스 토큰이 없습니다.');
        return false;
      }

      // API URL 구성
      final url = Uri.parse('$baseUrl/api-user/feed/$feedId/like');
      print('피드 좋아요 취소 API 호출: $url');

      // 헤더 설정 - 토큰 포함
      final headers = {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      };

      // API 호출 (DELETE 메서드 사용)
      final response = await http.delete(url, headers: headers);

      print('피드 좋아요 취소 응답 상태: ${response.statusCode}');

      // 응답 처리
      if (response.statusCode == 200) {
        // UTF-8로 명시적으로 디코딩
        final String responseBody = utf8.decode(response.bodyBytes);
        print('응답 원본: $responseBody');
        print('===== 피드 좋아요 취소 완료 =====');
        return true;
      } else {
        print('API 오류: ${response.statusCode}');

        try {
          // UTF-8로 명시적으로 디코딩
          final jsonBody = utf8.decode(response.bodyBytes);
          print('오류 응답 원본: $jsonBody');

          // JSON 형식인 경우에만 파싱 시도
          if (jsonBody.trim().startsWith('{')) {
            final errorData = json.decode(jsonBody);
            print('오류 메시지: ${errorData['message'] ?? '알 수 없음'}');
            print('오류 코드: ${errorData['code'] ?? '알 수 없음'}');

            if (errorData.containsKey('errors')) {
              print('상세 오류: ${errorData['errors']}');
            }
          } else {
            print('JSON 형식이 아닌 오류 응답: $jsonBody');
          }
        } catch (e) {
          print('오류 응답을 파싱할 수 없습니다: $e');
          print('응답 본문: ${response.body}');
        }

        print('===== 피드 좋아요 취소 실패 =====');
        return false;
      }
    } catch (e) {
      print('피드 좋아요 취소 중 예외 발생: $e');
      print('===== 피드 좋아요 취소 실패 (예외) =====');
      return false;
    }
  }

  // 댓글 등록 API
  static Future<Map<String, dynamic>?> createComment(
    int feedId,
    String content,
  ) async {
    try {
      print('===== 댓글 등록 시작 =====');

      // 토큰 가져오기
      final accessToken = await AuthService.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        print('액세스 토큰이 없습니다.');
        return null;
      }

      // API URL 구성
      final url = Uri.parse('$baseUrl/api-user/feed/$feedId/comment');
      print('댓글 등록 API 호출: $url');

      // 요청 본문 구성
      final Map<String, dynamic> requestBody = {'content': content};

      print('요청 본문: ${jsonEncode(requestBody)}');

      // 헤더 설정 - 토큰 포함
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      };

      // API 호출
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(requestBody),
      );

      print('댓글 등록 응답 상태: ${response.statusCode}');

      // 응답 처리
      if (response.statusCode == 200) {
        // UTF-8로 명시적으로 디코딩
        final String responseBody = utf8.decode(response.bodyBytes);
        print('응답 원본: $responseBody');

        try {
          final Map<String, dynamic> data = json.decode(responseBody);
          print('댓글 등록 결과: $data');
          print('===== 댓글 등록 완료 =====');

          // 🔔 댓글 등록 성공 시 알림 표시
          try {
            final notificationService = NotificationService();
            notificationService.showFeedCommentNotification(
              message: '새로운 댓글이 달렸어요!',
              feedId: feedId.toString(),
              commentAuthor: '사용자', // 실제로는 댓글 작성자 이름을 서버에서 받아와야 함
              onTap: () {
                print('💬 피드 댓글 알림 탭: 피드 상세 화면으로 이동');
                // 여기에 피드 상세 화면으로 이동하는 네비게이션 로직 추가 가능
              },
            );
            print('🔔 피드 댓글 알림 표시 완료');
          } catch (e) {
            print('⚠️ 댓글 알림 표시 중 오류: $e');
            // 알림 표시 실패해도 댓글 등록 자체는 성공으로 처리
          }

          return data;
        } catch (e) {
          print('JSON 파싱 오류가 발생했습니다: $e');
          return null;
        }
      } else {
        print('API 오류: ${response.statusCode}');

        try {
          // UTF-8로 명시적으로 디코딩
          final jsonBody = utf8.decode(response.bodyBytes);
          print('오류 응답 원본: $jsonBody');

          // JSON 형식인 경우에만 파싱 시도
          if (jsonBody.trim().startsWith('{')) {
            final errorData = json.decode(jsonBody);
            print('오류 메시지: ${errorData['message'] ?? '알 수 없음'}');
            print('오류 코드: ${errorData['code'] ?? '알 수 없음'}');

            if (errorData.containsKey('errors')) {
              print('상세 오류: ${errorData['errors']}');
            }
          } else {
            print('JSON 형식이 아닌 오류 응답: $jsonBody');
          }
        } catch (e) {
          print('오류 응답을 파싱할 수 없습니다: $e');
          print('응답 본문: ${response.body}');
        }

        print('===== 댓글 등록 실패 =====');
        return null;
      }
    } catch (e) {
      print('댓글 등록 중 예외 발생: $e');
      print('===== 댓글 등록 실패 (예외) =====');
      return null;
    }
  }

  // 댓글 목록 조회 API
  static Future<Map<String, dynamic>?> getComments(
    int feedId, {
    int page = 0,
    int size = 10,
    List<String>? sort,
  }) async {
    try {
      print('===== 댓글 목록 조회 시작 =====');

      // 토큰 가져오기
      final accessToken = await AuthService.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        print('액세스 토큰이 없습니다.');
        return null;
      }

      // API URL 구성 (페이징 파라미터 추가)
      final queryParams = {'page': page.toString(), 'size': size.toString()};

      // 정렬 파라미터 추가
      if (sort != null && sort.isNotEmpty) {
        // Spring 서버 sort 파라미터 형식에 맞게 설정
        for (int i = 0; i < sort.length; i++) {
          queryParams['sort[$i]'] = sort[i];
        }
        print('정렬 기준: $sort');
      }

      final url = Uri.parse(
        '$baseUrl/api-user/feed/$feedId/comments',
      ).replace(queryParameters: queryParams);
      print('댓글 목록 조회 API 호출: $url');

      // 헤더 설정 - 토큰 포함
      final headers = {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      // API 호출
      final response = await http.get(url, headers: headers);

      print('댓글 목록 조회 응답 상태: ${response.statusCode}');

      // 응답 처리
      if (response.statusCode == 200) {
        // UTF-8로 명시적으로 디코딩
        final String responseBody = utf8.decode(response.bodyBytes);
        print('응답 원본: $responseBody');

        try {
          final Map<String, dynamic> data = json.decode(responseBody);
          print('댓글 목록 조회 결과: ${data['content']?.length ?? 0}개 항목');

          // 로그에 정렬 순서 확인을 위해 생성 날짜 출력
          if (data['content'] is List && (data['content'] as List).isNotEmpty) {
            final contentList = data['content'] as List;
            print('서버에서 반환된 댓글 정렬 순서 확인:');
            for (int i = 0; i < Math.min(contentList.length, 5); i++) {
              final date =
                  contentList[i]['createdDate']; // createdAt -> createdDate로 수정
              print('서버 댓글 #$i 생성 날짜: $date');
            }
          }

          print('===== 댓글 목록 조회 완료 =====');
          return data;
        } catch (e) {
          print('JSON 파싱 오류가 발생했습니다: $e');
          return null;
        }
      } else {
        print('API 오류: ${response.statusCode}');

        try {
          // UTF-8로 명시적으로 디코딩
          final jsonBody = utf8.decode(response.bodyBytes);
          print('오류 응답 원본: $jsonBody');

          // JSON 형식인 경우에만 파싱 시도
          if (jsonBody.trim().startsWith('{')) {
            final errorData = json.decode(jsonBody);
            print('오류 메시지: ${errorData['message'] ?? '알 수 없음'}');
            print('오류 코드: ${errorData['code'] ?? '알 수 없음'}');

            if (errorData.containsKey('errors')) {
              print('상세 오류: ${errorData['errors']}');
            }
          } else {
            print('JSON 형식이 아닌 오류 응답: $jsonBody');
          }
        } catch (e) {
          print('오류 응답을 파싱할 수 없습니다: $e');
          print('응답 본문: ${response.body}');
        }

        print('===== 댓글 목록 조회 실패 =====');
        return null;
      }
    } catch (e) {
      print('댓글 목록 조회 중 예외 발생: $e');
      print('===== 댓글 목록 조회 실패 (예외) =====');
      return null;
    }
  }

  // 댓글 삭제 API
  static Future<bool> deleteComment(int commentId) async {
    try {
      print('===== 댓글 삭제 시작 =====');

      // 토큰 가져오기
      final accessToken = await AuthService.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        print('액세스 토큰이 없습니다.');
        return false;
      }

      // API URL 구성
      final url = Uri.parse('$baseUrl/api-user/feed/comment/$commentId');
      print('댓글 삭제 API 호출: $url');

      // 헤더 설정 - 토큰 포함
      final headers = {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      };

      // API 호출 (DELETE 메서드 사용)
      final response = await http.delete(url, headers: headers);

      print('댓글 삭제 응답 상태: ${response.statusCode}');

      // 응답 처리
      if (response.statusCode == 200) {
        // UTF-8로 명시적으로 디코딩
        final String responseBody = utf8.decode(response.bodyBytes);
        print('응답 원본: $responseBody');
        print('===== 댓글 삭제 완료 =====');
        return true;
      } else {
        print('API 오류: ${response.statusCode}');

        try {
          // UTF-8로 명시적으로 디코딩
          final jsonBody = utf8.decode(response.bodyBytes);
          print('오류 응답 원본: $jsonBody');

          // JSON 형식인 경우에만 파싱 시도
          if (jsonBody.trim().startsWith('{')) {
            final errorData = json.decode(jsonBody);
            print('오류 메시지: ${errorData['message'] ?? '알 수 없음'}');
            print('오류 코드: ${errorData['code'] ?? '알 수 없음'}');

            if (errorData.containsKey('errors')) {
              print('상세 오류: ${errorData['errors']}');
            }
          } else {
            print('JSON 형식이 아닌 오류 응답: $jsonBody');
          }
        } catch (e) {
          print('오류 응답을 파싱할 수 없습니다: $e');
          print('응답 본문: ${response.body}');
        }

        print('===== 댓글 삭제 실패 =====');
        return false;
      }
    } catch (e) {
      print('댓글 삭제 중 예외 발생: $e');
      print('===== 댓글 삭제 실패 (예외) =====');
      return false;
    }
  }

  // 댓글 수정 API
  static Future<Map<String, dynamic>?> updateComment(
    int commentId,
    String content,
  ) async {
    try {
      print('===== 댓글 수정 시작 =====');

      // 토큰 가져오기
      final accessToken = await AuthService.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        print('액세스 토큰이 없습니다.');
        return null;
      }

      // API URL 구성
      final url = Uri.parse('$baseUrl/api-user/feed/comment/$commentId');
      print('댓글 수정 API 호출: $url');

      // 요청 본문 구성
      final Map<String, dynamic> requestBody = {'content': content};

      print('요청 본문: ${jsonEncode(requestBody)}');

      // 헤더 설정 - 토큰 포함
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      };

      // API 호출 (PUT 메서드 사용)
      final response = await http.put(
        url,
        headers: headers,
        body: jsonEncode(requestBody),
      );

      print('댓글 수정 응답 상태: ${response.statusCode}');

      // 응답 처리
      if (response.statusCode == 200) {
        // UTF-8로 명시적으로 디코딩
        final String responseBody = utf8.decode(response.bodyBytes);
        print('응답 원본: $responseBody');

        try {
          final Map<String, dynamic> data = json.decode(responseBody);
          print('댓글 수정 결과: $data');
          print('===== 댓글 수정 완료 =====');
          return data;
        } catch (e) {
          print('JSON 파싱 오류가 발생했습니다: $e');
          return null;
        }
      } else {
        print('API 오류: ${response.statusCode}');

        try {
          // UTF-8로 명시적으로 디코딩
          final jsonBody = utf8.decode(response.bodyBytes);
          print('오류 응답 원본: $jsonBody');

          // JSON 형식인 경우에만 파싱 시도
          if (jsonBody.trim().startsWith('{')) {
            final errorData = json.decode(jsonBody);
            print('오류 메시지: ${errorData['message'] ?? '알 수 없음'}');
            print('오류 코드: ${errorData['code'] ?? '알 수 없음'}');

            if (errorData.containsKey('errors')) {
              print('상세 오류: ${errorData['errors']}');
            }
          } else {
            print('JSON 형식이 아닌 오류 응답: $jsonBody');
          }
        } catch (e) {
          print('오류 응답을 파싱할 수 없습니다: $e');
          print('응답 본문: ${response.body}');
        }

        print('===== 댓글 수정 실패 =====');
        return null;
      }
    } catch (e) {
      print('댓글 수정 중 예외 발생: $e');
      print('===== 댓글 수정 실패 (예외) =====');
      return null;
    }
  }

  // 내가 쓴 피드 조회 API
  static Future<Map<String, dynamic>?> getMyFeeds({
    int page = 0,
    int size = 10,
    List<String>? sort,
  }) async {
    try {
      print('===== 내가 쓴 피드 조회 시작 =====');

      // 토큰 가져오기
      final accessToken = await AuthService.getAccessToken();

      if (accessToken == null || accessToken.isEmpty) {
        print('액세스 토큰이 없습니다.');
        return null;
      }

      // 토큰 정보 로깅 (중요 부분은 일부만 표시)
      if (accessToken.length > 30) {
        print('사용 중인 액세스 토큰 (앞부분): ${accessToken.substring(0, 15)}...');
        print(
          '사용 중인 액세스 토큰 (뒷부분): ...${accessToken.substring(accessToken.length - 15)}',
        );
      } else {
        print('사용 중인 액세스 토큰이 너무 짧습니다: $accessToken');
      }

      // 리프레시 토큰 가져오기 (가능한 경우)
      String? refreshToken;
      try {
        refreshToken = await AuthService.getRefreshToken();
        if (refreshToken != null && refreshToken.isNotEmpty) {
          print('리프레시 토큰이 성공적으로 로드되었습니다.');
        }
      } catch (e) {
        print('리프레시 토큰을 가져오는 중 오류 발생: $e');
      }

      // 정확한 URL 구성
      final String url = '$baseUrl/api-user/feed/my';
      final Map<String, String> queryParams = {
        'page': page.toString(),
        'size': size.toString(),
      };

      // 정렬 추가
      if (sort != null && sort.isNotEmpty) {
        queryParams['sort'] = sort.first;
      } else {
        queryParams['sort'] = 'createdDate,desc';
      }

      // URL 생성
      final uri = Uri.parse(url).replace(queryParameters: queryParams);
      print('내가 쓴 피드 조회 API 호출: $uri');

      // 헤더 설정
      final headers = {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      // 리프레시 토큰이 있다면 쿠키 헤더 추가
      if (refreshToken != null && refreshToken.isNotEmpty) {
        headers['Cookie'] = 'refresh_token=$refreshToken';
        print('쿠키 헤더 추가됨: refresh_token=***');
      }

      print('요청 헤더: $headers');

      // API 호출
      final response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 15));

      print('내가 쓴 피드 조회 응답 상태: ${response.statusCode}');

      // 응답 처리
      if (response.statusCode == 200) {
        // UTF-8로 명시적으로 디코딩
        final String responseBody = utf8.decode(response.bodyBytes);
        print('응답 원본: $responseBody');

        try {
          final Map<String, dynamic> data = json.decode(responseBody);

          // 각 피드 항목에 "내 피드"임을 표시하는 플래그 추가
          if (data.containsKey('content') && data['content'] is List) {
            final List<dynamic> content = data['content'];
            print('내가 쓴 피드 개수: ${content.length}');

            // 각 피드 항목에 fromMyFeed = true 필드 추가
            for (int i = 0; i < content.length; i++) {
              if (content[i] is Map) {
                (content[i] as Map)['fromMyFeed'] = true;
                (content[i] as Map)['isMyFeed'] = true;
              }
            }
          }

          print('내가 쓴 피드 조회 결과: ${data['content']?.length ?? 0}개 항목');
          print('===== 내가 쓴 피드 조회 완료 =====');
          return data;
        } catch (e) {
          print('JSON 파싱 오류가 발생했습니다: $e');
          return null;
        }
      } else {
        print('API 오류: ${response.statusCode}');

        try {
          // UTF-8로 명시적으로 디코딩
          final jsonBody = utf8.decode(response.bodyBytes);
          print('오류 응답 원본: $jsonBody');

          // JSON 형식인 경우에만 파싱 시도
          if (jsonBody.trim().startsWith('{')) {
            final errorData = json.decode(jsonBody);
            print('오류 메시지: ${errorData['message'] ?? '알 수 없음'}');
            print('오류 코드: ${errorData['code'] ?? '알 수 없음'}');

            if (errorData.containsKey('errors')) {
              print('상세 오류: ${errorData['errors']}');
            }
          } else {
            print('JSON 형식이 아닌 오류 응답: $jsonBody');
          }
        } catch (e) {
          print('오류 응답을 파싱할 수 없습니다: $e');
          print('응답 본문: ${response.body}');
        }

        // 401 오류인 경우 토큰 갱신 시도 필요 알림
        if (response.statusCode == 401) {
          print('인증 오류: 토큰이 만료되었거나 유효하지 않습니다. 로그인이 필요합니다.');
        }

        print('===== 내가 쓴 피드 조회 실패 =====');
        return null;
      }
    } catch (e) {
      print('내가 쓴 피드 조회 중 예외 발생: $e');
      print('===== 내가 쓴 피드 조회 실패 (예외) =====');
      return null;
    }
  }

  // 대댓글 등록 API
  static Future<Map<String, dynamic>?> createReply(
    int feedId,
    int parentId,
    String content,
  ) async {
    try {
      print('===== 대댓글 등록 시작 =====');

      // 토큰 가져오기
      final accessToken = await AuthService.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        print('액세스 토큰이 없습니다.');
        return null;
      }

      // API URL 구성
      final url = Uri.parse('$baseUrl/api-user/feed/$feedId/comment/reply');
      print('대댓글 등록 API 호출: $url');

      // 요청 본문 구성
      final Map<String, dynamic> requestBody = {
        'content': content,
        'parentId': parentId,
      };

      print('요청 본문: ${jsonEncode(requestBody)}');

      // 헤더 설정 - 토큰 포함
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      };

      // API 호출
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(requestBody),
      );

      print('대댓글 등록 응답 상태: ${response.statusCode}');

      // 응답 처리
      if (response.statusCode == 200) {
        // UTF-8로 명시적으로 디코딩
        final String responseBody = utf8.decode(response.bodyBytes);
        print('응답 원본: $responseBody');

        try {
          final Map<String, dynamic> data = json.decode(responseBody);
          print('대댓글 등록 결과: $data');
          print('===== 대댓글 등록 완료 =====');

          // 🔔 대댓글 등록 성공 시 알림 표시
          try {
            final notificationService = NotificationService();
            notificationService.showFeedCommentNotification(
              message: '내 댓글에 답글이 달렸어요!',
              feedId: feedId.toString(),
              commentAuthor: '사용자', // 실제로는 대댓글 작성자 이름을 서버에서 받아와야 함
              onTap: () {
                print('💬 대댓글 알림 탭: 피드 상세 화면으로 이동');
                // 여기에 피드 상세 화면으로 이동하는 네비게이션 로직 추가 가능
              },
            );
            print('🔔 대댓글 알림 표시 완료');
          } catch (e) {
            print('⚠️ 대댓글 알림 표시 중 오류: $e');
            // 알림 표시 실패해도 대댓글 등록 자체는 성공으로 처리
          }

          return data;
        } catch (e) {
          print('JSON 파싱 오류가 발생했습니다: $e');
          return null;
        }
      } else {
        print('API 오류: ${response.statusCode}');

        try {
          // UTF-8로 명시적으로 디코딩
          final jsonBody = utf8.decode(response.bodyBytes);
          print('오류 응답 원본: $jsonBody');

          // JSON 형식인 경우에만 파싱 시도
          if (jsonBody.trim().startsWith('{')) {
            final errorData = json.decode(jsonBody);
            print('오류 메시지: ${errorData['message'] ?? '알 수 없음'}');
            print('오류 코드: ${errorData['code'] ?? '알 수 없음'}');

            if (errorData.containsKey('errors')) {
              print('상세 오류: ${errorData['errors']}');
            }
          } else {
            print('JSON 형식이 아닌 오류 응답: $jsonBody');
          }
        } catch (e) {
          print('오류 응답을 파싱할 수 없습니다: $e');
          print('응답 본문: ${response.body}');
        }

        print('===== 대댓글 목록 조회 실패 =====');
        return null;
      }
    } catch (e) {
      print('대댓글 목록 조회 중 예외 발생: $e');
      print('===== 대댓글 목록 조회 실패 (예외) =====');
      return null;
    }
  }

  // 댓글 좋아요 토글 API
  static Future<bool> toggleCommentLike(
    int commentId,
    bool currentLikeStatus,
  ) async {
    try {
      print('===== 댓글 좋아요 상태 변경 시작 =====');
      print('현재 좋아요 상태: ${currentLikeStatus ? "좋아요 됨" : "좋아요 안됨"}');

      // 현재 좋아요 상태에 따라 적절한 메서드 호출
      if (currentLikeStatus) {
        // 이미 좋아요 한 상태면 좋아요 취소 API 호출
        return await unlikeComment(commentId);
      } else {
        // 좋아요 하지 않은 상태면 좋아요 API 호출
        return await likeComment(commentId);
      }
    } catch (e) {
      print('댓글 좋아요 상태 변경 중 예외 발생: $e');
      print('===== 댓글 좋아요 상태 변경 실패 (예외) =====');
      return false;
    }
  }

  // 댓글 좋아요 추가 API
  static Future<bool> likeComment(int commentId) async {
    try {
      print('===== 댓글 좋아요 추가 시작 =====');

      // 토큰 가져오기
      final accessToken = await AuthService.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        print('액세스 토큰이 없습니다.');
        return false;
      }

      // API URL 구성
      final url = Uri.parse('$baseUrl/api-user/feed/comment/$commentId/like');
      print('댓글 좋아요 API 호출: $url');

      // 헤더 설정 - 토큰 포함
      final headers = {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      };

      // API 호출 (POST 메서드 사용)
      final response = await http.post(url, headers: headers);

      print('댓글 좋아요 응답 상태: ${response.statusCode}');

      // 응답 처리
      if (response.statusCode == 200) {
        // UTF-8로 명시적으로 디코딩
        final String responseBody = utf8.decode(response.bodyBytes);
        print('응답 원본: $responseBody');
        print('===== 댓글 좋아요 추가 완료 =====');
        return true;
      } else {
        print('API 오류: ${response.statusCode}');
        print('===== 댓글 좋아요 추가 실패 =====');
        return false;
      }
    } catch (e) {
      print('댓글 좋아요 추가 중 예외 발생: $e');
      print('===== 댓글 좋아요 추가 실패 (예외) =====');
      return false;
    }
  }

  // 댓글 좋아요 취소 API
  static Future<bool> unlikeComment(int commentId) async {
    try {
      print('===== 댓글 좋아요 취소 시작 =====');

      // 토큰 가져오기
      final accessToken = await AuthService.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        print('액세스 토큰이 없습니다.');
        return false;
      }

      // API URL 구성
      final url = Uri.parse('$baseUrl/api-user/feed/comment/$commentId/like');
      print('댓글 좋아요 취소 API 호출: $url');

      // 헤더 설정 - 토큰 포함
      final headers = {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      };

      // API 호출 (DELETE 메서드 사용)
      final response = await http.delete(url, headers: headers);

      print('댓글 좋아요 취소 응답 상태: ${response.statusCode}');

      // 응답 처리
      if (response.statusCode == 200) {
        // UTF-8로 명시적으로 디코딩
        final String responseBody = utf8.decode(response.bodyBytes);
        print('응답 원본: $responseBody');
        print('===== 댓글 좋아요 취소 완료 =====');
        return true;
      } else {
        print('API 오류: ${response.statusCode}');
        print('===== 댓글 좋아요 취소 실패 =====');
        return false;
      }
    } catch (e) {
      print('댓글 좋아요 취소 중 예외 발생: $e');
      print('===== 댓글 좋아요 취소 실패 (예외) =====');
      return false;
    }
  }

  // 피드 알림 조회 API
  static Future<Map<String, dynamic>?> getFeedNotifications({
    int page = 0,
    int size = 10,
    List<String>? sort,
  }) async {
    try {
      print('===== 피드 알림 조회 시작 =====');

      // 토큰 가져오기
      final accessToken = await AuthService.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        print('액세스 토큰이 없습니다.');
        return null;
      }

      // 쿼리 파라미터 구성
      final queryParams = <String, String>{
        'page': page.toString(),
        'size': size.toString(),
      };

      // 정렬 정보 추가
      if (sort != null && sort.isNotEmpty) {
        for (int i = 0; i < sort.length; i++) {
          queryParams['sort[$i]'] = sort[i];
        }
      } else {
        // 기본 정렬 (최신순)
        queryParams['sort'] = 'createdDate,desc';
      }

      print('쿼리 파라미터: $queryParams');

      // API URL 구성
      final uri = Uri.parse(
        '$baseUrl/api-user/feed/notification',
      ).replace(queryParameters: queryParams);
      print('피드 알림 조회 API 호출: $uri');

      // 헤더 설정 - 토큰 포함 및 추가 헤더
      final headers = {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      print('요청 헤더: $headers');

      // API 호출
      final response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 15));

      print('피드 알림 조회 응답 상태: ${response.statusCode}');
      print('응답 헤더: ${response.headers}');

      // 응답 처리
      if (response.statusCode == 200) {
        // UTF-8로 명시적으로 디코딩
        final String responseBody = utf8.decode(response.bodyBytes);
        print('응답 원본: $responseBody');

        try {
          final Map<String, dynamic> data = json.decode(responseBody);

          // 상세 로깅 추가
          if (data.containsKey('content') && data['content'] is List) {
            final List<dynamic> content = data['content'];
            print('피드 알림 개수: ${content.length}');

            // 첫 번째 항목의 필드 구조 확인
            if (content.isNotEmpty) {
              final firstItem = content[0];
              print('첫 번째 알림 항목 구조:');
              firstItem.forEach((key, value) {
                print('  $key: $value (${value?.runtimeType})');
              });

              // 모든 아이템의 주요 필드 확인
              print('=== 알림 데이터 상세 조회 ===');
              for (int i = 0; i < content.length; i++) {
                final item = content[i];
                final id = item['id'];
                final message = item['message'];
                final type = item['type'];
                final createdDate = item['createdDate'];
                final read = item['read'];
                print('알림 $id - 타입: $type, 메시지: $message, 읽음여부: $read');

                // 시간 정보 파싱 시도
                if (createdDate != null) {
                  try {
                    final parsedDate = DateTime.parse(createdDate.toString());
                    print('  -> 시간: $parsedDate (UTC)');
                    print('  -> 한국 시간: ${parsedDate.add(Duration(hours: 9))}');
                  } catch (e) {
                    print('  -> 시간 파싱 실패: $e');
                  }
                }
              }
            }
          } else {
            print('content 필드가 없거나 List가 아닙니다.');
          }

          print('피드 알림 조회 결과: ${data['content']?.length ?? 0}개 항목');
          print('총 페이지: ${data['totalPages']}');
          print('===== 피드 알림 조회 완료 =====');
          return data;
        } catch (e) {
          print('JSON 파싱 오류가 발생했습니다: $e');
          return null;
        }
      } else {
        print('API 오류: ${response.statusCode}');

        try {
          // UTF-8로 명시적으로 디코딩
          final jsonBody = utf8.decode(response.bodyBytes);
          print('오류 응답 원본: $jsonBody');

          // JSON 형식인 경우에만 파싱 시도
          if (jsonBody.trim().startsWith('{')) {
            final errorData = json.decode(jsonBody);
            print('오류 메시지: ${errorData['message'] ?? '알 수 없음'}');
            print('오류 코드: ${errorData['code'] ?? '알 수 없음'}');

            if (errorData.containsKey('errors')) {
              print('상세 오류: ${errorData['errors']}');
            }
          } else {
            print('JSON 형식이 아닌 오류 응답: $jsonBody');
          }
        } catch (e) {
          print('오류 응답을 파싱할 수 없습니다: $e');
          print('응답 본문: ${response.body}');
        }

        print('===== 피드 알림 조회 실패 =====');
        return null;
      }
    } catch (e) {
      print('피드 알림 조회 중 예외 발생: $e');
      print('===== 피드 알림 조회 실패 (예외) =====');
      return null;
    }
  }

  // 알림 읽음 처리 API
  static Future<bool> markNotificationAsRead(int notificationId) async {
    try {
      print('===== 알림 읽음 처리 시작 =====');

      // 토큰 가져오기
      final accessToken = await AuthService.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        print('액세스 토큰이 없습니다.');
        return false;
      }

      // API URL 구성
      final url = Uri.parse(
        '$baseUrl/api-user/feed/notification/$notificationId/read',
      );
      print('알림 읽음 처리 API 호출: $url');

      // 헤더 설정 - 토큰 포함
      final headers = {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      };

      // API 호출 (PUT 메서드 사용)
      final response = await http.put(url, headers: headers);

      print('알림 읽음 처리 응답 상태: ${response.statusCode}');

      // 응답 처리
      if (response.statusCode == 200) {
        print('===== 알림 읽음 처리 완료 =====');
        return true;
      } else {
        print('API 오류: ${response.statusCode}');
        print('===== 알림 읽음 처리 실패 =====');
        return false;
      }
    } catch (e) {
      print('알림 읽음 처리 중 예외 발생: $e');
      print('===== 알림 읽음 처리 실패 (예외) =====');
      return false;
    }
  }

  // 대댓글 목록 조회 API
  static Future<Map<String, dynamic>?> getReplies(
    int parentId, {
    int page = 0,
    int size = 10,
  }) async {
    try {
      print('===== 대댓글 목록 조회 시작 =====');

      // 토큰 가져오기
      final accessToken = await AuthService.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        print('액세스 토큰이 없습니다.');
        return null;
      }

      // API URL 구성 (페이징 파라미터 추가)
      final queryParams = {'page': page.toString(), 'size': size.toString()};

      final url = Uri.parse(
        '$baseUrl/api-user/feed/comment/$parentId/replies',
      ).replace(queryParameters: queryParams);
      print('대댓글 목록 조회 API 호출: $url');

      // 헤더 설정 - 토큰 포함
      final headers = {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      // API 호출
      final response = await http.get(url, headers: headers);

      print('대댓글 목록 조회 응답 상태: ${response.statusCode}');

      // 응답 처리
      if (response.statusCode == 200) {
        // UTF-8로 명시적으로 디코딩
        final String responseBody = utf8.decode(response.bodyBytes);
        print('응답 원본: $responseBody');

        try {
          final Map<String, dynamic> data = json.decode(responseBody);
          print('대댓글 목록 조회 결과: ${data['content']?.length ?? 0}개 항목');
          print('===== 대댓글 목록 조회 완료 =====');
          return data;
        } catch (e) {
          print('JSON 파싱 오류가 발생했습니다: $e');
          return null;
        }
      } else {
        print('API 오류: ${response.statusCode}');

        try {
          // UTF-8로 명시적으로 디코딩
          final jsonBody = utf8.decode(response.bodyBytes);
          print('오류 응답 원본: $jsonBody');

          // JSON 형식인 경우에만 파싱 시도
          if (jsonBody.trim().startsWith('{')) {
            final errorData = json.decode(jsonBody);
            print('오류 메시지: ${errorData['message'] ?? '알 수 없음'}');
            print('오류 코드: ${errorData['code'] ?? '알 수 없음'}');

            if (errorData.containsKey('errors')) {
              print('상세 오류: ${errorData['errors']}');
            }
          } else {
            print('JSON 형식이 아닌 오류 응답: $jsonBody');
          }
        } catch (e) {
          print('오류 응답을 파싱할 수 없습니다: $e');
          print('응답 본문: ${response.body}');
        }

        print('===== 대댓글 목록 조회 실패 =====');
        return null;
      }
    } catch (e) {
      print('대댓글 목록 조회 중 예외 발생: $e');
      print('===== 대댓글 목록 조회 실패 (예외) =====');
      return null;
    }
  }

  // 피드 삭제 API
  static Future<bool> deleteFeed(int feedId) async {
    try {
      print('===== 피드 삭제 시작 =====');

      // 토큰 가져오기
      final accessToken = await AuthService.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        print('액세스 토큰이 없습니다.');
        return false;
      }

      // API URL 구성
      final url = Uri.parse('$baseUrl/api-user/feed/$feedId');
      print('피드 삭제 API 호출: $url');

      // 헤더 설정 - 토큰 포함
      final headers = {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      };

      // API 호출 (DELETE 메서드 사용)
      final response = await http.delete(url, headers: headers);

      print('피드 삭제 응답 상태: ${response.statusCode}');

      // 응답 처리
      if (response.statusCode == 200) {
        // UTF-8로 명시적으로 디코딩
        final String responseBody = utf8.decode(response.bodyBytes);
        print('응답 원본: $responseBody');
        print('===== 피드 삭제 완료 =====');
        return true;
      } else {
        print('API 오류: ${response.statusCode}');

        try {
          // UTF-8로 명시적으로 디코딩
          final jsonBody = utf8.decode(response.bodyBytes);
          print('오류 응답 원본: $jsonBody');

          // JSON 형식인 경우에만 파싱 시도
          if (jsonBody.trim().startsWith('{')) {
            final errorData = json.decode(jsonBody);
            print('오류 메시지: ${errorData['message'] ?? '알 수 없음'}');
            print('오류 코드: ${errorData['code'] ?? '알 수 없음'}');

            if (errorData.containsKey('errors')) {
              print('상세 오류: ${errorData['errors']}');
            }
          } else {
            print('JSON 형식이 아닌 오류 응답: $jsonBody');
          }
        } catch (e) {
          print('오류 응답을 파싱할 수 없습니다: $e');
          print('응답 본문: ${response.body}');
        }

        print('===== 피드 삭제 실패 =====');
        return false;
      }
    } catch (e) {
      print('피드 삭제 중 예외 발생: $e');
      print('===== 피드 삭제 실패 (예외) =====');
      return false;
    }
  }

  // 사용자 ID로 피드 개수 조회 (정확한 사용자 식별 - writerId 사용)
  static Future<int> getUserFeedCountById(int userId) async {
    try {
      print('===== 사용자 피드 개수 조회 시작 (writerId 기반) =====');
      print('조회할 사용자 ID: $userId');

      // 기존 getFeedList API 사용 (충분한 양의 피드를 가져와서 필터링)
      final result = await getFeedList(
        page: 0,
        size: 100, // 충분한 양의 피드를 가져옴
      );

      if (result != null && result['content'] is List) {
        final List<dynamic> allFeeds = result['content'];

        // 해당 작성자의 피드만 필터링 (writerId로 정확한 매칭)
        final userFeeds =
            allFeeds.where((feed) {
              final feedWriterId = feed['writerId'];
              final idMatch = feedWriterId == userId;

              if (idMatch) {
                print(
                  '✅ 매칭된 피드: ID=${feed['feedId']}, 제목="${feed['title']}", 작성자ID=$feedWriterId',
                );
              }

              return idMatch;
            }).toList();

        final count = userFeeds.length;
        print('사용자 ID $userId의 피드 개수: $count개 (writerId 정확 매칭)');
        print('===== 사용자 피드 개수 조회 완료 =====');
        return count;
      } else {
        print('피드 목록을 가져올 수 없습니다.');
        print('===== 사용자 피드 개수 조회 실패 =====');
        return 0;
      }
    } catch (e) {
      print('사용자 피드 개수 조회 중 예외 발생: $e');
      print('===== 사용자 피드 개수 조회 실패 (예외) =====');
      return 0;
    }
  }

  // 사용자 이름과 이메일로 피드 개수 조회 (이전 버전 호환성 - 권장하지 않음)
  static Future<int> getUserFeedCountByNameAndEmail(
    String writerName,
    String writerEmail,
  ) async {
    try {
      print('===== 사용자 피드 개수 조회 시작 (이름+이메일 기반) =====');
      print('⚠️ 경고: writerId를 사용하는 getUserFeedCountById() 메서드 사용을 권장합니다.');
      print('조회할 작성자 이름: $writerName');
      print('조회할 작성자 이메일: $writerEmail');

      // 기존 getFeedList API 사용 (충분한 양의 피드를 가져와서 필터링)
      final result = await getFeedList(
        page: 0,
        size: 100, // 충분한 양의 피드를 가져옴
      );

      if (result != null && result['content'] is List) {
        final List<dynamic> allFeeds = result['content'];

        // 해당 작성자의 피드만 필터링 (이름으로 매칭 - 동명이인 가능성 있음)
        final userFeeds =
            allFeeds.where((feed) {
              final feedWriterName =
                  feed['writerName']?.toString().trim() ?? '';

              // 공백을 제거한 이름으로 매칭 (피드에 "김 동규"와 "김동규" 혼재 문제 해결)
              final normalizedFeedName = feedWriterName.replaceAll(' ', '');
              final normalizedUserName = writerName.trim().replaceAll(' ', '');
              final nameMatch = normalizedFeedName == normalizedUserName;

              print(
                '피드 작성자: "$feedWriterName" (정규화: "$normalizedFeedName") - 대상: "$normalizedUserName" - 매칭: $nameMatch',
              );

              return nameMatch;
            }).toList();

        final count = userFeeds.length;
        print('작성자 "$writerName"의 피드 개수: $count개 (이름 기반 매칭 - 동명이인 가능성 있음)');
        print('===== 사용자 피드 개수 조회 완료 =====');
        return count;
      } else {
        print('피드 목록을 가져올 수 없습니다.');
        print('===== 사용자 피드 개수 조회 실패 =====');
        return 0;
      }
    } catch (e) {
      print('사용자 피드 개수 조회 중 예외 발생: $e');
      print('===== 사용자 피드 개수 조회 실패 (예외) =====');
      return 0;
    }
  }

  // 사용자 이름으로만 피드 개수 조회 (하위 호환성용)
  static Future<int> getUserFeedCountByName(String writerName) async {
    print('경고: 동명이인 문제로 인해 getUserFeedCountByNameAndEmail() 사용을 권장합니다.');

    try {
      print('===== 사용자 피드 개수 조회 시작 (이름만 기반) =====');
      print('조회할 작성자 이름: $writerName');

      // 기존 getFeedList API 사용 (충분한 양의 피드를 가져와서 필터링)
      final result = await getFeedList(
        page: 0,
        size: 100, // 충분한 양의 피드를 가져옴
      );

      if (result != null && result['content'] is List) {
        final List<dynamic> allFeeds = result['content'];

        // 해당 작성자의 피드만 필터링
        final userFeeds =
            allFeeds.where((feed) => feed['writerName'] == writerName).toList();

        final count = userFeeds.length;
        print('작성자 "$writerName"의 피드 개수: $count개 (동명이인 가능성 있음)');
        print('===== 사용자 피드 개수 조회 완료 =====');
        return count;
      } else {
        print('피드 목록을 가져올 수 없습니다.');
        print('===== 사용자 피드 개수 조회 실패 =====');
        return 0;
      }
    } catch (e) {
      print('사용자 피드 개수 조회 중 예외 발생: $e');
      print('===== 사용자 피드 개수 조회 실패 (예외) =====');
      return 0;
    }
  }

  // 하위 호환성을 위한 기존 메서드 (사용자 ID 기반) - 이제 writerId 사용
  static Future<int> getUserFeedCount(int userId) async {
    print('getUserFeedCount 호출 - getUserFeedCountById로 리다이렉트');
    return await getUserFeedCountById(userId);
  }

  // 피드 신고 API
  static Future<Map<String, dynamic>?> reportFeed(int feedId) async {
    try {
      print('===== 피드 신고 시작 (feedId: $feedId) =====');

      // 토큰 가져오기
      final accessToken = await AuthService.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        print('액세스 토큰이 없습니다.');
        return null;
      }

      // API URL 구성
      final url = Uri.parse('$baseUrl/api-user/report');
      print('피드 신고 API 호출: $url');

      // 요청 본문 구성
      final Map<String, dynamic> requestBody = {
        'type': 'FEED',
        'targetId': feedId,
      };

      print('요청 본문: ${jsonEncode(requestBody)}');

      // 헤더 설정 - 토큰 포함
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      };

      print('요청 헤더: $headers');

      // API 호출
      print('신고 API 호출 시작: ${DateTime.now()}');
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(requestBody),
      );
      print('신고 API 호출 완료: ${DateTime.now()}, 상태 코드: ${response.statusCode}');

      print('피드 신고 응답 상태: ${response.statusCode}');
      print('피드 신고 응답 헤더: ${response.headers}');

      // 응답 내용 로깅 (길이도 함께 표시)
      final bodyBytes = response.bodyBytes;
      print('피드 신고 응답 바디 길이: ${bodyBytes.length} 바이트');

      // 응답 처리
      if (response.statusCode == 200) {
        // UTF-8로 명시적으로 디코딩
        final String responseBody = utf8.decode(bodyBytes);
        print('응답 원본: $responseBody');

        try {
          final Map<String, dynamic> data = json.decode(responseBody);
          print('피드 신고 결과: $data');
          print('===== 피드 신고 완료 =====');
          return data;
        } catch (e) {
          print('JSON 파싱 오류가 발생했습니다: $e');
          // 응답이 빈 문자열이거나 JSON이 아닐 경우에도 성공으로 처리
          if (responseBody.isEmpty || !responseBody.trim().startsWith('{')) {
            print('빈 응답이거나, JSON이 아니지만 요청은 성공 처리합니다.');
            return {'success': true, 'message': '신고가 완료되었습니다.'};
          }
          return {'success': true, 'message': '신고가 완료되었습니다.'};
        }
      } else {
        print('API 오류: ${response.statusCode}');

        try {
          // UTF-8로 명시적으로 디코딩
          final jsonBody = utf8.decode(bodyBytes);
          print('오류 응답 원본: $jsonBody');

          // JSON 형식인 경우에만 파싱 시도
          if (jsonBody.trim().startsWith('{')) {
            final errorData = json.decode(jsonBody);
            print('오류 메시지: ${errorData['message'] ?? '알 수 없음'}');
            print('오류 코드: ${errorData['code'] ?? '알 수 없음'}');

            if (errorData.containsKey('errors')) {
              print('상세 오류: ${errorData['errors']}');
            }
          } else {
            print('JSON 형식이 아닌 오류 응답: $jsonBody');
          }
        } catch (e) {
          print('오류 응답을 파싱할 수 없습니다: $e');
          print('응답 본문: ${response.body}');
        }

        print('===== 피드 신고 실패 =====');
        return null;
      }
    } catch (e) {
      print('피드 신고 중 예외 발생: $e');
      print('예외 스택 트레이스: ${e is Error ? e.stackTrace : "N/A"}');
      print('===== 피드 신고 실패 (예외) =====');
      return null;
    }
  }
}
