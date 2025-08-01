import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';

class RelationshipService {
  // 서버 기본 URL
  static const String baseUrl = 'http://3.34.52.239:8080';

  // 전화번호로 사용자 검색
  static Future<Map<String, dynamic>?> searchUserByPhone(String phone) async {
    try {
      // 전화번호에서 하이픈 제거 및 형식 처리
      String cleanPhone = phone.replaceAll('-', '');
      cleanPhone = cleanPhone.replaceAll(' ', ''); // 공백도 제거

      // 전화번호 길이 확인 (10자리 또는 11자리)
      if (cleanPhone.length != 10 && cleanPhone.length != 11) {
        print('잘못된 전화번호 형식: 10자리 또는 11자리가 아닙니다 (${cleanPhone.length}자리)');
        return null;
      }

      // 숫자만 포함되어 있는지 확인
      final RegExp numericRegex = RegExp(r'^[0-9]+$');
      if (!numericRegex.hasMatch(cleanPhone)) {
        print('잘못된 전화번호 형식: 숫자만 포함되어야 합니다');
        return null;
      }

      // 토큰 가져오기
      final accessToken = await AuthService.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        print('액세스 토큰이 없습니다.');
        return null;
      }

      // API URL 구성
      final url = Uri.parse('$baseUrl/api-user/user/search?phone=$cleanPhone');
      print('사용자 검색 API 호출: $url');

      // 헤더 설정 - 토큰 포함
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
        'Accept': 'application/json; charset=utf-8', // UTF-8 명시적 지정
      };
      print(
        '요청 헤더: Content-Type: application/json, Authorization: Bearer ${accessToken.substring(0, min(10, accessToken.length))}...',
      );

      // API 호출
      final response = await http.get(url, headers: headers);
      print('사용자 검색 응답 상태: ${response.statusCode}');

      // 응답 처리
      if (response.statusCode == 200) {
        // UTF-8로 명시적으로 디코딩
        final jsonBody = utf8.decode(response.bodyBytes);
        final Map<String, dynamic> data = json.decode(jsonBody);

        // 새로운 API 응답 구조 로깅
        print('===== 사용자 검색 결과 상세 =====');
        print('검색된 사용자 ID: ${data['searchUserId']}');
        print('이메일: ${data['email']}');
        print('이름: ${data['name']}');
        print('주민등록번호: ${data['rrn'] ?? '없음'}');
        print('상태 메시지: ${data['statusMessage'] ?? '없음'}');
        print('프로필 이미지: ${data['profileImagePath'] ?? '없음'}');
        print('역할: ${data['role']}');

        // friendInfo 객체가 있는 경우 확인 (friendId가 있어야 실제 친구)
        final friendInfo = data['friendInfo'];
        if (friendInfo != null && friendInfo['friendId'] != null) {
          print('친구 정보 있음 (이미 친구인 사용자):');
          print('- 친구 ID: ${friendInfo['friendId']}');
          print('- 커스텀 이름: ${friendInfo['customName']}');
          print('- 차단 여부: ${friendInfo['isBlocked']}');
          print('- 친한 친구 여부: ${friendInfo['isBestFriend']}');

          // 클라이언트 호환성을 위해 이전 응답 형식으로 데이터 변환
          data['friendId'] = friendInfo['friendId'];
          data['customName'] = friendInfo['customName'];
          data['isBlocked'] = friendInfo['isBlocked'];
          data['isBestFriend'] = friendInfo['isBestFriend'];
        } else {
          print('친구 정보 없음 (아직 친구가 아닌 사용자)');
          if (friendInfo != null) {
            print('friendInfo 객체는 존재하지만 friendId가 null임: $friendInfo');
          }
        }

        // userId 필드 호환성 유지
        data['userId'] = data['searchUserId'];

        print('===== 사용자 검색 완료 =====');
        return data;
      } else if (response.statusCode == 404) {
        print('사용자를 찾을 수 없습니다.');
        return null;
      } else {
        print('API 오류: ${response.statusCode}');
        print('응답 헤더: ${response.headers}');
        print('응답 본문: ${utf8.decode(response.bodyBytes)}');

        // 상세 오류 로그 추가
        if (response.statusCode == 500) {
          try {
            final errorData = json.decode(utf8.decode(response.bodyBytes));
            print('서버 내부 오류가 발생했습니다. 잠시 후 다시 시도해주세요.');
            print('요청 URL: $url');
            print(
              '요청 헤더: Content-Type: application/json, Authorization: Bearer ${accessToken.substring(0, min(10, accessToken.length))}...',
            );
            print('오류 상세: $errorData');
          } catch (e) {
            print('오류 응답을 파싱할 수 없습니다: $e');
          }
        }

        return null;
      }
    } catch (e) {
      print('사용자 검색 중 예외 발생: $e');
      return null;
    }
  }

  // 친구 추가 요청
  static Future<Map<String, dynamic>?> sendRelationshipRequest(
    int targetUserId,
    String relationshipType,
  ) async {
    try {
      print('===== 친구 요청 시작 =====');
      print('요청 시간: ${DateTime.now()}');
      print('대상 사용자 ID: $targetUserId');
      print('관계 유형: $relationshipType');

      // 친구 목록 조회해서 이미 친구인지 먼저 확인
      final friends = await getFriendList();
      if (friends != null) {
        print('현재 친구 목록 개수: ${friends.length}');

        if (friends.isEmpty) {
          print('친구 목록이 비어 있습니다 - 이 사용자는 기존 친구가 아닙니다');
        }

        // 친구 목록을 로깅하여 디버깅
        int index = 0;
        for (final friend in friends) {
          final friendId = friend['friendId'];
          final userInfo = friend['userInfo'] ?? {};
          final userId = userInfo['userId'];

          print('친구[$index] - friendId: $friendId, userId: $userId');

          // 이미 친구인 경우 오류 반환
          if ((friendId != null && friendId == targetUserId) ||
              (userId != null && userId == targetUserId)) {
            print('===== 이미 친구인 사용자입니다 =====');
            print('기존 친구 정보: $friend');
            return {
              'error': true,
              'errorCode': 'ALREADY_FRIEND',
              'message': '이미 친구 목록에 있는 사용자입니다.',
            };
          }

          index++;
        }
      } else {
        print('친구 목록을 가져오는데 실패했습니다. 친구 중복 체크를 건너뜁니다.');
      }

      // 토큰 가져오기
      final accessToken = await AuthService.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        print('액세스 토큰이 없습니다.');
        return null;
      }

      // API URL 구성 - 친구 추가 엔드포인트로 변경
      final url = Uri.parse('$baseUrl/api-user/friend');
      print('친구 추가 API 호출: $url');

      // 요청 본문 구성
      final body = json.encode({
        'targetUserId': targetUserId,
        'relationshipType': relationshipType,
      });
      print('요청 본문: $body');

      // 헤더 설정 - 토큰 포함
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      };

      print('요청 시작 시간: ${DateTime.now()}');
      // API 호출
      final response = await http.post(url, headers: headers, body: body);
      print('응답 수신 시간: ${DateTime.now()}');
      print('친구 추가 응답 상태: ${response.statusCode}');

      // 응답 처리
      if (response.statusCode == 200 || response.statusCode == 201) {
        // UTF-8로 명시적으로 디코딩
        final jsonBody = utf8.decode(response.bodyBytes);
        final Map<String, dynamic> data = json.decode(jsonBody);
        print('친구 추가 결과: $data');

        // 친구 요청 상태 정보 상세 로깅
        if (data.containsKey('relationshipStatus')) {
          print('요청 상태: ${data['relationshipStatus']}');
          print('관계 ID: ${data['id'] ?? '정보 없음'}');
          print('생성 시간: ${data['createdAt'] ?? '정보 없음'}');
          print('요청자 ID: ${data['requesterId'] ?? '정보 없음'}');
          print('수신자 ID: ${data['targetId'] ?? '정보 없음'}');
        }

        print('===== 친구 요청 완료 =====');
        return data;
      } else {
        print('API 오류: ${response.statusCode}');

        try {
          // UTF-8로 명시적으로 디코딩
          final jsonBody = utf8.decode(response.bodyBytes);
          final errorData = json.decode(jsonBody);
          print('응답 본문: $jsonBody');
          print('오류 메시지: ${errorData['message'] ?? '알 수 없음'}');
          print('오류 코드: ${errorData['code'] ?? '알 수 없음'}');

          // 이미 관계가 있는 경우에 대한 처리
          if (errorData['code'] == 'R001' ||
              errorData['message']?.toString().contains('이미 관계가 있습니다') ==
                  true) {
            print('===== 이미 관계가 있는 사용자입니다 =====');
            print('오류 상세: ${errorData['message']}');

            // 관계는 있지만 친구가 아닌 경우 (가족 멤버만 있는 경우)
            // 이 경우 이미 존재하는 관계를 반환하여 클라이언트가 처리할 수 있게 함
            return {
              'error': true,
              'errorCode': 'ALREADY_RELATIONSHIP',
              'message': '이미 관계가 있는 사용자입니다.',
              'details': errorData['message'],
            };
          }

          if (errorData.containsKey('errors')) {
            print('상세 오류: ${errorData['errors']}');
          }
        } catch (e) {
          print('오류 응답을 파싱할 수 없습니다: $e');
          print('응답 본문: ${response.body}');
        }

        print('===== 친구 요청 실패 =====');
        return null;
      }
    } catch (e) {
      print('친구 추가 중 예외 발생: $e');
      print('===== 친구 요청 실패 (예외) =====');
      return null;
    }
  }

  // 친구 목록 조회 API (GET /api-user/friend/list)
  static Future<List<dynamic>?> getFriendList() async {
    try {
      print('===== 친구 목록 조회 시작 =====');
      print('요청 시간: ${DateTime.now()}');

      // 토큰 가져오기
      final accessToken = await AuthService.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        print('액세스 토큰이 없습니다.');
        return null;
      }

      // API URL 구성
      final url = Uri.parse('$baseUrl/api-user/friend/list');
      print('친구 목록 조회 API 호출: $url');

      // 헤더 설정 - 토큰 포함
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
        'Accept': 'application/json; charset=utf-8', // UTF-8 명시적 지정
      };
      print(
        '요청 헤더: Content-Type: application/json, Authorization: Bearer ${accessToken.substring(0, min(10, accessToken.length))}...',
      );

      // API 호출
      final response = await http.get(url, headers: headers);
      print('친구 목록 조회 응답 상태: ${response.statusCode}');

      // 응답 처리
      if (response.statusCode == 200) {
        // UTF-8로 명시적으로 디코딩
        final jsonBody = utf8.decode(response.bodyBytes);
        final List<dynamic> friends = json.decode(jsonBody);
        print('친구 목록 조회 결과: ${friends.length}개의 친구');

        // 친구 정보 세부 로깅 (새로운 API 응답 구조에 맞게 수정)
        int index = 0;
        for (var friend in friends) {
          final userInfo = friend['userInfo'] ?? {};
          final friendInfo = friend['friendInfo'] ?? {};

          print('친구[$index] 사용자 정보:');
          print('- 사용자 ID: ${userInfo['userId'] ?? '정보 없음'}');
          print('- 실제 이름: ${userInfo['realName'] ?? '정보 없음'}');
          print('- 주민등록번호: ${userInfo['rrn'] ?? '정보 없음'}');
          print('- 전화번호: ${userInfo['phone'] ?? '정보 없음'}');
          print('- 상태 메시지: ${userInfo['statusMessage'] ?? '상태 메시지 없음'}');
          print('- 은행명: ${userInfo['backName'] ?? '은행 정보 없음'}');
          print('- 은행 코드: ${userInfo['backCode'] ?? '은행 코드 없음'}');
          print('- 계좌번호: ${userInfo['backAccount'] ?? '계좌 정보 없음'}');
          print('- 프로필 이미지: ${userInfo['profileImagePath'] ?? '정보 없음'}');
          print('- 목표 금액: ${userInfo['targetAmount'] ?? 0}');
          print('- 학교명: ${userInfo['schoolName'] ?? '학교 정보 없음'}');
          print('- 학교 유형: ${userInfo['schoolType'] ?? '학교 유형 없음'}');
          print('- 지역: ${userInfo['region'] ?? '지역 정보 없음'}');
          print('- 주소: ${userInfo['address'] ?? '주소 정보 없음'}');
          print('- 역할: ${userInfo['role'] ?? '정보 없음'}');

          print('친구[$index] 친구 정보:');
          print('- 친구 여부: ${friendInfo['isFriend'] ?? false}');
          print('- 친구 ID: ${friendInfo['friendId'] ?? '정보 없음'}');
          print('- 커스텀 이름: ${friendInfo['customName'] ?? '정보 없음'}');
          print('- 차단 여부: ${friendInfo['isBlocked'] ?? false}');
          print('- 친한 친구 여부: ${friendInfo['isBestFriend'] ?? false}');

          // friendId가 null인 경우 경고 로그 출력
          if (friendInfo['friendId'] == null) {
            print('⚠️ 경고: 친구 목록에 friendId가 null인 항목이 있습니다: $friendInfo');
          }

          print('---');

          // 클라이언트 호환성을 위해 이전 응답 형식으로 데이터 변환
          friend['isFriend'] = friendInfo['isFriend'];
          friend['friendId'] = friendInfo['friendId'];
          friend['customName'] = friendInfo['customName'];
          friend['isBlocked'] = friendInfo['isBlocked'];
          friend['isBestFriend'] = friendInfo['isBestFriend'];

          index++;
        }

        print('===== 친구 목록 조회 완료 =====');
        return friends;
      } else {
        print('API 오류: ${response.statusCode}');
        print('응답 헤더: ${response.headers}');
        print('응답 본문: ${utf8.decode(response.bodyBytes)}');

        try {
          final errorData = json.decode(utf8.decode(response.bodyBytes));
          print('오류 메시지: ${errorData['message'] ?? '알 수 없음'}');
          print('오류 코드: ${errorData['code'] ?? '알 수 없음'}');
        } catch (e) {
          print('오류 응답을 파싱할 수 없습니다: $e');
        }

        // 상세 오류 로그 추가
        if (response.statusCode == 500) {
          print('서버 내부 오류가 발생했습니다. 잠시 후 다시 시도해주세요.');
          print('요청 URL: $url');
          print(
            '요청 헤더: Content-Type: application/json, Authorization: Bearer ${accessToken.substring(0, min(10, accessToken.length))}...',
          );
        }

        print('===== 친구 목록 조회 실패 =====');
        return null;
      }
    } catch (e) {
      print('친구 목록 조회 중 예외 발생: $e');
      print('===== 친구 목록 조회 실패 (예외) =====');
      return null;
    }
  }

  // 나를 친구로 추가한 유저 목록 조회 API (GET /api-user/friend/added-me)
  static Future<List<dynamic>?> getFriendsAddedMe() async {
    try {
      print('===== 나를 친구로 추가한 유저 목록 조회 시작 =====');
      print('요청 시간: ${DateTime.now()}');

      // 토큰 가져오기
      final accessToken = await AuthService.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        print('액세스 토큰이 없습니다.');
        return null;
      }

      // API URL 구성
      final url = Uri.parse('$baseUrl/api-user/friend/added-me');
      print('나를 친구로 추가한 유저 목록 조회 API 호출: $url');

      // 헤더 설정 - 토큰 포함
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
        'Accept': 'application/json; charset=utf-8', // UTF-8 명시적 지정
      };
      print(
        '요청 헤더: Content-Type: application/json, Authorization: Bearer ${accessToken.substring(0, min(10, accessToken.length))}...',
      );

      // API 호출
      final response = await http.get(url, headers: headers);
      print('나를 친구로 추가한 유저 목록 조회 응답 상태: ${response.statusCode}');

      // 응답 처리
      if (response.statusCode == 200) {
        // UTF-8로 명시적으로 디코딩
        final jsonBody = utf8.decode(response.bodyBytes);
        final List<dynamic> addedMeUsers = json.decode(jsonBody);
        print('나를 친구로 추가한 유저 목록 조회 결과: ${addedMeUsers.length}개의 유저');

        // 유저 정보 세부 로깅 (새로운 API 응답 구조에 맞게 수정)
        int index = 0;
        for (var addedMeUser in addedMeUsers) {
          final userInfo = addedMeUser['userInfo'] ?? {};
          final friendInfo = addedMeUser['friendInfo'] ?? {};

          print('나를 추가한 유저[$index] 사용자 정보:');
          print('- 사용자 ID: ${userInfo['userId'] ?? '정보 없음'}');
          print('- 실제 이름: ${userInfo['realName'] ?? '정보 없음'}');
          print('- 주민등록번호: ${userInfo['rrn'] ?? '정보 없음'}');
          print('- 전화번호: ${userInfo['phone'] ?? '정보 없음'}');
          print('- 상태 메시지: ${userInfo['statusMessage'] ?? '상태 메시지 없음'}');
          print('- 은행명: ${userInfo['backName'] ?? '은행 정보 없음'}');
          print('- 은행 코드: ${userInfo['backCode'] ?? '은행 코드 없음'}');
          print('- 계좌번호: ${userInfo['backAccount'] ?? '계좌 정보 없음'}');
          print('- 프로필 이미지: ${userInfo['profileImagePath'] ?? '정보 없음'}');
          print('- 목표 금액: ${userInfo['targetAmount'] ?? 0}');
          print('- 학교명: ${userInfo['schoolName'] ?? '학교 정보 없음'}');
          print('- 학교 유형: ${userInfo['schoolType'] ?? '학교 유형 없음'}');
          print('- 지역: ${userInfo['region'] ?? '지역 정보 없음'}');
          print('- 주소: ${userInfo['address'] ?? '주소 정보 없음'}');
          print('- 역할: ${userInfo['role'] ?? '정보 없음'}');

          print('나를 추가한 유저[$index] 친구 정보:');
          print('- 친구 여부: ${friendInfo['isFriend'] ?? false}');
          print('- 친구 ID: ${friendInfo['friendId'] ?? '정보 없음'}');
          print('- 커스텀 이름: ${friendInfo['customName'] ?? '정보 없음'}');
          print('- 차단 여부: ${friendInfo['isBlocked'] ?? false}');
          print('- 친한 친구 여부: ${friendInfo['isBestFriend'] ?? false}');

          // friendId가 null인 경우 경고 로그 출력
          if (friendInfo['friendId'] == null) {
            print('⚠️ 경고: 나를 추가한 유저 목록에 friendId가 null인 항목이 있습니다: $friendInfo');
          }

          print('---');

          // 클라이언트 호환성을 위해 이전 응답 형식으로 데이터 변환
          addedMeUser['isFriend'] = friendInfo['isFriend'];
          addedMeUser['friendId'] = friendInfo['friendId'];
          addedMeUser['customName'] = friendInfo['customName'];
          addedMeUser['isBlocked'] = friendInfo['isBlocked'];
          addedMeUser['isBestFriend'] = friendInfo['isBestFriend'];

          index++;
        }

        print('===== 나를 친구로 추가한 유저 목록 조회 완료 =====');
        return addedMeUsers;
      } else {
        print('API 오류: ${response.statusCode}');
        print('응답 헤더: ${response.headers}');
        print('응답 본문: ${utf8.decode(response.bodyBytes)}');

        try {
          final errorData = json.decode(utf8.decode(response.bodyBytes));
          print('오류 메시지: ${errorData['message'] ?? '알 수 없음'}');
          print('오류 코드: ${errorData['code'] ?? '알 수 없음'}');
        } catch (e) {
          print('오류 응답을 파싱할 수 없습니다: $e');
        }

        // 상세 오류 로그 추가
        if (response.statusCode == 500) {
          print('서버 내부 오류가 발생했습니다. 잠시 후 다시 시도해주세요.');
          print('요청 URL: $url');
          print(
            '요청 헤더: Content-Type: application/json, Authorization: Bearer ${accessToken.substring(0, min(10, accessToken.length))}...',
          );
        }

        print('===== 나를 친구로 추가한 유저 목록 조회 실패 =====');
        return null;
      }
    } catch (e) {
      print('나를 친구로 추가한 유저 목록 조회 중 예외 발생: $e');
      print('===== 나를 친구로 추가한 유저 목록 조회 실패 (예외) =====');
      return null;
    }
  }

  // 관계 상태 문자열 변환 (UI 표시용)
  static String getRelationshipStatusText(String status) {
    switch (status) {
      case 'REQUESTED':
        return '요청됨';
      case 'REQUESTED_BY_OTHER':
        return '요청 받음';
      case 'CONNECTED':
        return '연결됨';
      case 'BLOCKED':
        return '차단됨';
      case 'BLOCKED_BY_OTHER':
        return '차단당함';
      default:
        return '알 수 없음';
    }
  }

  // 관계 타입 문자열 변환 (UI 표시용)
  static String getRelationshipTypeText(String type) {
    switch (type) {
      case 'FAMILY':
        return '가족';
      case 'FRIEND':
        return '친구';
      case 'MENTOR_MENTEE':
        return '선생님/학생';
      default:
        return '알 수 없음';
    }
  }

  // 요청 온 관계 내역 조회
  static Future<List<Map<String, dynamic>>?> getRelationshipInbox() async {
    try {
      print('관계 요청 내역 조회 API 호출: ${baseUrl}/api-user/relationship/inbox');

      final response = await http.get(
        Uri.parse('${baseUrl}/api-user/relationship/inbox'),
        headers: await AuthService.getHeaders(),
      );

      print('관계 요청 내역 응답 상태: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        return data.cast<Map<String, dynamic>>();
      } else if (response.statusCode == 401) {
        print('인증 오류: 토큰이 만료되었거나 유효하지 않습니다.');
        return [];
      } else if (response.statusCode == 500) {
        print('서버 오류: ${response.body}');
        return [];
      } else {
        print('API 오류: ${response.statusCode}');
        print('응답 본문: ${response.body}');
        return [];
      }
    } catch (e) {
      print('친구 요청 내역 로딩 중 오류: $e');
      return [];
    }
  }

  // 관계 요청 처리 (수락/거절)
  static Future<bool> processRelationshipRequest(
    int relationshipId,
    bool accept,
  ) async {
    try {
      // 토큰 가져오기
      final accessToken = await AuthService.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        print('액세스 토큰이 없습니다.');
        return false;
      }

      // API URL 구성
      final url = Uri.parse(
        '$baseUrl/api-user/relationship/$relationshipId/${accept ? 'accept' : 'reject'}',
      );
      print('관계 요청 처리 API 호출: $url');

      // 헤더 설정 - 토큰 포함
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      };

      // API 호출 (PATCH 메서드 사용)
      final response = await http.patch(url, headers: headers);
      print('관계 요청 처리 응답 상태: ${response.statusCode}');

      // 응답 처리
      if (response.statusCode == 200) {
        print('관계 요청 ${accept ? '수락' : '거절'} 성공');
        return true;
      } else {
        print('API 오류: ${response.statusCode}');
        print('응답 본문: ${response.body}');
        return false;
      }
    } catch (e) {
      print('관계 요청 처리 중 예외 발생: $e');
      return false;
    }
  }

  // 친구 요청 수락
  static Future<Map<String, dynamic>?> acceptRelationshipRequest(
    int relationshipId,
  ) async {
    try {
      print('===== 친구 요청 수락 시작 =====');
      print('수락할 관계 ID: $relationshipId');
      print('요청 시간: ${DateTime.now()}');

      // processRelationshipRequest 메서드를 사용하여 요청 수락
      final success = await processRelationshipRequest(relationshipId, true);

      if (success) {
        print('===== 친구 요청 수락 성공 =====');
        return {
          'success': true,
          'message': '친구 요청을 성공적으로 수락했습니다.',
          'relationshipId': relationshipId,
        };
      } else {
        print('===== 친구 요청 수락 실패 =====');
        return {
          'success': false,
          'message': '친구 요청 수락에 실패했습니다.',
          'relationshipId': relationshipId,
        };
      }
    } catch (e) {
      print('친구 요청 수락 중 예외 발생: $e');
      print('===== 친구 요청 수락 실패 (예외) =====');
      return {
        'success': false,
        'message': '오류가 발생했습니다: $e',
        'relationshipId': relationshipId,
      };
    }
  }

  // 사용자 상세 정보 조회 API (GET /api-user/user/info/details/{userId})
  static Future<Map<String, dynamic>?> getUserInfo(int userId) async {
    try {
      print('===== 사용자 상세 정보 조회 시작 =====');
      print('대상 사용자 ID: $userId');
      print('요청 시간: ${DateTime.now()}');

      // 토큰 가져오기
      final accessToken = await AuthService.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        print('액세스 토큰이 없습니다.');
        return null;
      }

      // API URL 구성
      final url = Uri.parse('$baseUrl/api-user/user/info/details/$userId');
      print('사용자 상세 정보 조회 API 호출: $url');

      // 헤더 설정 - 토큰 포함
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
        'Accept': 'application/json; charset=utf-8', // UTF-8 명시적 지정
      };
      print(
        '요청 헤더: Content-Type: application/json, Authorization: Bearer ${accessToken.substring(0, min(10, accessToken.length))}...',
      );

      // API 호출
      final response = await http.get(url, headers: headers);
      print('사용자 상세 정보 조회 응답 상태: ${response.statusCode}');

      // 응답 처리
      if (response.statusCode == 200) {
        // UTF-8로 명시적으로 디코딩
        final jsonBody = utf8.decode(response.bodyBytes);
        final Map<String, dynamic> data = json.decode(jsonBody);
        print('===== 사용자 상세 정보 조회 결과 =====');

        // 새로운 API 응답 구조 로깅
        print('사용자 ID: ${data['userId']}');
        print('이메일: ${data['email'] ?? '이메일 없음'}');
        print('실제 이름: ${data['realName']}');
        print('상태 메시지: ${data['statusMessage'] ?? '상태 메시지 없음'}');
        print('전화번호: ${data['phone'] ?? '전화번호 없음'}');
        print('주민등록번호: ${data['rrn'] ?? '주민등록번호 없음'}');
        print('은행명: ${data['bankName'] ?? '은행 정보 없음'}');
        print('은행 코드: ${data['bankCode'] ?? '은행 코드 없음'}');
        print('계좌번호: ${data['bankAccount'] ?? '계좌 정보 없음'}');
        print('프로필 이미지: ${data['profileImagePath'] ?? '이미지 없음'}');
        print('목표 금액: ${data['targetAmount'] ?? 0}');
        print('학교명: ${data['schoolName'] ?? '학교 정보 없음'}');
        print('학교 유형: ${data['schoolType'] ?? '학교 유형 없음'}');
        print('지역: ${data['region'] ?? '지역 정보 없음'}');
        print('주소: ${data['address'] ?? '주소 정보 없음'}');
        print('역할: ${data['role'] ?? '역할 정보 없음'}');
        print('친구 수: ${data['friendCount'] ?? 0}');
        print('미션 수: ${data['missionCount'] ?? 0}');
        print('챌린지 수: ${data['challengeCount'] ?? 0}');

        // 은행 정보 로깅
        print('은행명: ${data['bankName'] ?? '은행명 없음'}');
        print('은행 코드: ${data['bankCode'] ?? '은행 코드 없음'}');
        print('계좌번호: ${data['bankAccount'] ?? '계좌번호 없음'}');

        // 새로운 API 응답 구조: friendInfo 객체 처리
        final friendInfo = data['friendInfo'];
        if (friendInfo != null) {
          print('친구 정보 객체 발견:');
          print('- isFriend: ${friendInfo['isFriend']}');
          print('- friendId: ${friendInfo['friendId']}');
          print('- customName: ${friendInfo['customName']}');
          print('- isBlocked: ${friendInfo['isBlocked']}');
          print('- isBestFriend: ${friendInfo['isBestFriend']}');

          // friendId가 있고 isFriend가 true인 경우에만 실제 친구 관계로 처리
          if (friendInfo['isFriend'] == true &&
              friendInfo['friendId'] != null) {
            print('✅ 확인된 친구 관계 - friendId: ${friendInfo['friendId']}');

            // 클라이언트 호환성을 위해 루트 레벨에 친구 정보 복사
            data['friendId'] = friendInfo['friendId'];
            data['customName'] = friendInfo['customName'] ?? data['realName'];
            data['isBlocked'] = friendInfo['isBlocked'] ?? false;
            data['isBestFriend'] = friendInfo['isBestFriend'] ?? false;
          } else {
            print(
              '❌ 친구 관계 아님 - isFriend: ${friendInfo['isFriend']}, friendId: ${friendInfo['friendId']}',
            );
            // 친구가 아닌 경우 기본값 설정
            data['friendId'] = null;
            data['customName'] = data['realName'];
            data['isBlocked'] = false;
            data['isBestFriend'] = false;
          }
        } else {
          print('❌ friendInfo 객체 없음 - 친구 관계 아님');
          // friendInfo가 없는 경우 기본값 설정
          data['friendId'] = null;
          data['customName'] = data['realName'];
          data['isBlocked'] = false;
          data['isBestFriend'] = false;
        }

        // 이전 버전과의 호환성을 위해 빈 relation 배열 유지
        if (!data.containsKey('relation')) {
          data['relation'] = [];
        }

        print('===== 사용자 상세 정보 조회 완료 =====');
        return data;
      } else {
        print('API 오류: ${response.statusCode}');

        try {
          // UTF-8로 명시적으로 디코딩하여 인코딩 문제 해결
          final jsonBody = utf8.decode(response.bodyBytes);
          final errorData = json.decode(jsonBody);
          print('응답 본문: $jsonBody');
          print('오류 메시지: ${errorData['message'] ?? '알 수 없음'}');
          print('오류 코드: ${errorData['code'] ?? '알 수 없음'}');

          // 특정 오류 코드 처리
          if (errorData['code'] == 'U001' || errorData['code'] == 'C004') {
            print('해당 ID의 사용자가 존재하지 않거나 서버 오류입니다: $userId');

            // 사용자가 없는 경우에 기본 정보 반환 (UI에서 표시할 수 있도록)
            print('기본 사용자 정보를 반환합니다.');
            return {
              'userId': userId,
              'email': '',
              'realName': '알 수 없는 사용자',
              'customName': '알 수 없는 사용자',
              'statusMessage': '',
              'profileImagePath': '',
              'role': '',
              'friendInfo': null,
              'friendId': null,
              'isBlocked': false,
              'isBestFriend': false,
              'relation': [],
              'notFound': true, // 사용자를 찾지 못했음을 표시
            };
          }
        } catch (e) {
          print('오류 응답을 파싱할 수 없습니다: $e');
          print('응답 본문: ${response.body}');
        }

        print('===== 사용자 상세 정보 조회 실패 =====');
        return null;
      }
    } catch (e) {
      print('사용자 상세 정보 조회 중 예외 발생: $e');
      print('===== 사용자 상세 정보 조회 실패 (예외) =====');
      return null;
    }
  }

  // 친구 삭제
  static Future<bool> deleteFriend(int friendId) async {
    try {
      print('===== 친구 삭제 시작 =====');
      print('삭제할 친구 ID: $friendId');
      print('요청 시간: ${DateTime.now()}');

      // 토큰 가져오기
      final accessToken = await AuthService.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        print('액세스 토큰이 없습니다.');
        return false;
      }

      // API URL 구성
      final url = Uri.parse('$baseUrl/api-user/friend/$friendId');
      print('친구 삭제 API 호출: $url');

      // 헤더 설정 - 토큰 포함
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      };

      // API 호출 (DELETE 메서드 사용)
      final response = await http.delete(url, headers: headers);
      print('친구 삭제 응답 상태: ${response.statusCode}');

      // 응답 처리
      if (response.statusCode == 200 || response.statusCode == 204) {
        // 204는 No Content, 성공이지만 응답 본문이 없음
        print('친구 삭제 성공 (상태 코드: ${response.statusCode})');
        print('===== 친구 삭제 완료 =====');
        return true;
      } else {
        print('API 오류: ${response.statusCode}');

        try {
          // 응답 본문이 있는 경우에만 파싱 시도
          if (response.body.isNotEmpty) {
            // UTF-8로 명시적으로 디코딩
            final jsonBody = utf8.decode(response.bodyBytes);
            final errorData = json.decode(jsonBody);
            print('응답 본문: $jsonBody');
            print('오류 메시지: ${errorData['message'] ?? '알 수 없음'}');
            print('오류 코드: ${errorData['code'] ?? '알 수 없음'}');
          } else {
            print('응답 본문이 비어 있습니다.');
          }
        } catch (e) {
          print('오류 응답을 파싱할 수 없습니다: $e');
          print('응답 본문: ${response.body}');
        }

        print('===== 친구 삭제 실패 =====');
        return false;
      }
    } catch (e) {
      print('친구 삭제 중 예외 발생: $e');
      print('===== 친구 삭제 실패 (예외) =====');
      return false;
    }
  }

  // 친구 차단
  static Future<Map<String, dynamic>?> blockFriend(int friendId) async {
    try {
      print('===== 친구 차단 시작 =====');
      print('차단할 친구 ID: $friendId');
      print('요청 시간: ${DateTime.now()}');

      // 사용자 상세 정보 가져오기
      final userInfo = await getUserInfoByFriendId(friendId);
      if (userInfo == null) {
        print('💡 차단 대상 사용자 정보를 찾을 수 없습니다.');
        return null;
      }

      // 사용자 ID 추출
      final targetUserId = userInfo['userId'];
      if (targetUserId == null) {
        print('💡 차단 대상 사용자 ID를 찾을 수 없습니다.');
        return null;
      }

      print('차단 대상 사용자 ID: $targetUserId, 친구 관계 ID: $friendId');

      // 토큰 가져오기
      final accessToken = await AuthService.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        print('액세스 토큰이 없습니다.');
        return null;
      }

      // API URL 구성 - 스펙 변경: path variable 제거
      final url = Uri.parse('$baseUrl/api-user/friend/block');
      print('친구 차단 API 호출: $url');
      print('API 스펙 변경: path variable 제거, 요청 본문에 targetUserId 추가');

      // 요청 본문 구성 - targetUserId 필드 사용 (API 요구사항)
      final body = json.encode({
        'targetUserId': targetUserId, // 차단할 사용자 ID
      });
      print('요청 본문: $body');

      // 헤더 설정 - 토큰 포함
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      };

      // API 호출 (PATCH 메서드 사용) - 요청 본문 추가
      final response = await http.patch(url, headers: headers, body: body);
      print('친구 차단 응답 상태: ${response.statusCode}');

      // 응답 처리
      if (response.statusCode == 200) {
        // UTF-8로 명시적으로 디코딩
        final jsonBody = utf8.decode(response.bodyBytes);
        final Map<String, dynamic> data = json.decode(jsonBody);
        print('친구 차단 결과: $data');
        print('===== 친구 차단 완료 =====');
        return data;
      } else {
        print('API 오류: ${response.statusCode}');

        try {
          if (response.body.isNotEmpty) {
            final jsonBody = utf8.decode(response.bodyBytes);
            final errorData = json.decode(jsonBody);
            print('응답 본문: $jsonBody');
            print('오류 메시지: ${errorData['message'] ?? '알 수 없음'}');
            print('오류 코드: ${errorData['code'] ?? '알 수 없음'}');
          } else {
            print('응답 본문이 비어 있습니다.');
          }
        } catch (e) {
          print('오류 응답을 파싱할 수 없습니다: $e');
          print('응답 본문: ${response.body}');
        }

        print('===== 친구 차단 실패 =====');
        return null;
      }
    } catch (e) {
      print('친구 차단 중 예외 발생: $e');
      print('===== 친구 차단 실패 (예외) =====');
      return null;
    }
  }

  // friendId로 사용자 정보 조회
  static Future<Map<String, dynamic>?> getUserInfoByFriendId(
    int friendId,
  ) async {
    try {
      print('===== friendId로 사용자 정보 조회 시작 =====');
      print('friendId: $friendId');

      // 친구 목록 조회
      final friends = await getFriendList();
      if (friends == null) {
        print('친구 목록을 가져올 수 없습니다.');
        return null;
      }

      for (final friend in friends) {
        final friendInfo = friend['friendInfo'] ?? {};
        final currentFriendId = friendInfo['friendId'];

        // 찾는 friendId와 일치하는 정보 찾기
        if (currentFriendId == friendId) {
          final userInfo = friend['userInfo'] ?? {};
          print('찾은 사용자 정보: $userInfo');
          print('사용자 ID: ${userInfo['userId']}');
          return userInfo;
        }
      }

      print('해당 friendId($friendId)를 가진 사용자 정보를 찾을 수 없습니다.');
      return null;
    } catch (e) {
      print('friendId로 사용자 정보 조회 중 예외 발생: $e');
      return null;
    } finally {
      print('===== friendId로 사용자 정보 조회 종료 =====');
    }
  }

  // 친구 차단 해제
  static Future<Map<String, dynamic>?> unblockFriend(int friendId) async {
    try {
      print('===== 친구 차단 해제 시작 =====');
      print('차단 해제할 친구 ID: $friendId');
      print('요청 시간: ${DateTime.now()}');

      // 토큰 가져오기
      final accessToken = await AuthService.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        print('액세스 토큰이 없습니다.');
        return null;
      }

      // API URL 구성 - 스펙 변경: path variable 제거
      final url = Uri.parse('$baseUrl/api-user/friend/unblock');
      print('친구 차단 해제 API 호출: $url');
      print('API 스펙 변경: path variable 제거, 요청 본문에 friendId 추가');

      // 요청 본문 구성 - friendId 필드 사용
      final body = json.encode({'friendId': friendId});
      print('요청 본문: $body');

      // 헤더 설정 - 토큰 포함
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      };

      // API 호출 (PATCH 메서드 사용) - 요청 본문 추가
      final response = await http.patch(url, headers: headers, body: body);
      print('친구 차단 해제 응답 상태: ${response.statusCode}');

      // 응답 처리
      if (response.statusCode == 200) {
        // UTF-8로 명시적으로 디코딩
        final jsonBody = utf8.decode(response.bodyBytes);
        final Map<String, dynamic> data = json.decode(jsonBody);
        print('친구 차단 해제 결과: $data');
        print('===== 친구 차단 해제 완료 =====');
        return data;
      } else {
        print('API 오류: ${response.statusCode}');

        try {
          if (response.body.isNotEmpty) {
            final jsonBody = utf8.decode(response.bodyBytes);
            final errorData = json.decode(jsonBody);
            print('응답 본문: $jsonBody');
            print('오류 메시지: ${errorData['message'] ?? '알 수 없음'}');
            print('오류 코드: ${errorData['code'] ?? '알 수 없음'}');
          } else {
            print('응답 본문이 비어 있습니다.');
          }
        } catch (e) {
          print('오류 응답을 파싱할 수 없습니다: $e');
          print('응답 본문: ${response.body}');
        }

        print('===== 친구 차단 해제 실패 =====');
        return null;
      }
    } catch (e) {
      print('친구 차단 해제 중 예외 발생: $e');
      print('===== 친구 차단 해제 실패 (예외) =====');
      return null;
    }
  }

  // 친한 친구 등록
  static Future<Map<String, dynamic>?> markAsBestFriend(int friendId) async {
    try {
      print('===== 친한 친구 등록 시작 =====');
      print('친한 친구로 등록할 ID: $friendId');
      print('요청 시간: ${DateTime.now()}');

      // 토큰 가져오기
      final accessToken = await AuthService.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        print('액세스 토큰이 없습니다.');
        return null;
      }

      // API URL 구성
      final url = Uri.parse('$baseUrl/api-user/friend/mark-best/$friendId');
      print('친한 친구 등록 API 호출: $url');

      // 헤더 설정 - 토큰 포함
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      };

      // API 호출 (PATCH 메서드 사용)
      final response = await http.patch(url, headers: headers);
      print('친한 친구 등록 응답 상태: ${response.statusCode}');

      // 응답 처리
      if (response.statusCode == 200) {
        // UTF-8로 명시적으로 디코딩
        final jsonBody = utf8.decode(response.bodyBytes);
        final Map<String, dynamic> data = json.decode(jsonBody);
        print('친한 친구 등록 결과: $data');
        print('===== 친한 친구 등록 완료 =====');
        return data;
      } else {
        print('API 오류: ${response.statusCode}');

        try {
          if (response.body.isNotEmpty) {
            final jsonBody = utf8.decode(response.bodyBytes);
            final errorData = json.decode(jsonBody);
            print('응답 본문: $jsonBody');
            print('오류 메시지: ${errorData['message'] ?? '알 수 없음'}');
            print('오류 코드: ${errorData['code'] ?? '알 수 없음'}');
          } else {
            print('응답 본문이 비어 있습니다.');
          }
        } catch (e) {
          print('오류 응답을 파싱할 수 없습니다: $e');
          print('응답 본문: ${response.body}');
        }

        print('===== 친한 친구 등록 실패 =====');
        return null;
      }
    } catch (e) {
      print('친한 친구 등록 중 예외 발생: $e');
      print('===== 친한 친구 등록 실패 (예외) =====');
      return null;
    }
  }

  // 친한 친구 등록 취소
  static Future<Map<String, dynamic>?> unmarkAsBestFriend(int friendId) async {
    try {
      print('===== 친한 친구 등록 취소 시작 =====');
      print('친한 친구 등록 취소할 ID: $friendId');
      print('요청 시간: ${DateTime.now()}');

      // 토큰 가져오기
      final accessToken = await AuthService.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        print('액세스 토큰이 없습니다.');
        return null;
      }

      // API URL 구성
      final url = Uri.parse('$baseUrl/api-user/friend/unmark-best/$friendId');
      print('친한 친구 등록 취소 API 호출: $url');

      // 헤더 설정 - 토큰 포함
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      };

      // API 호출 (PATCH 메서드 사용)
      final response = await http.patch(url, headers: headers);
      print('친한 친구 등록 취소 응답 상태: ${response.statusCode}');

      // 응답 처리
      if (response.statusCode == 200) {
        // UTF-8로 명시적으로 디코딩
        final jsonBody = utf8.decode(response.bodyBytes);
        final Map<String, dynamic> data = json.decode(jsonBody);
        print('친한 친구 등록 취소 결과: $data');
        print('===== 친한 친구 등록 취소 완료 =====');
        return data;
      } else {
        print('API 오류: ${response.statusCode}');

        try {
          if (response.body.isNotEmpty) {
            final jsonBody = utf8.decode(response.bodyBytes);
            final errorData = json.decode(jsonBody);
            print('응답 본문: $jsonBody');
            print('오류 메시지: ${errorData['message'] ?? '알 수 없음'}');
            print('오류 코드: ${errorData['code'] ?? '알 수 없음'}');
          } else {
            print('응답 본문이 비어 있습니다.');
          }
        } catch (e) {
          print('오류 응답을 파싱할 수 없습니다: $e');
          print('응답 본문: ${response.body}');
        }

        print('===== 친한 친구 등록 취소 실패 =====');
        return null;
      }
    } catch (e) {
      print('친한 친구 등록 취소 중 예외 발생: $e');
      print('===== 친한 친구 등록 취소 실패 (예외) =====');
      return null;
    }
  }

  // 친구 이름 수정
  static Future<Map<String, dynamic>?> renameFriend(
    int friendId,
    String newName,
  ) async {
    try {
      print('===== 친구 이름 수정 시작 =====');
      print('친구 ID: $friendId');
      print('새 이름: $newName');
      print('요청 시간: ${DateTime.now()}');

      // 토큰 가져오기
      final accessToken = await AuthService.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        print('액세스 토큰이 없습니다.');
        return null;
      }

      // API URL 구성
      final url = Uri.parse('$baseUrl/api-user/friend/rename');
      print('친구 이름 수정 API 호출: $url');

      // 요청 본문 구성
      final body = json.encode({
        'targetFriendId': friendId,
        'changeName': newName,
      });
      print('요청 본문: $body');

      // 헤더 설정 - 토큰 포함
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      };

      // API 호출 (PATCH 메서드 사용)
      final response = await http.patch(url, headers: headers, body: body);
      print('친구 이름 수정 응답 상태: ${response.statusCode}');

      // 응답 처리
      if (response.statusCode == 200) {
        // UTF-8로 명시적으로 디코딩
        final jsonBody = utf8.decode(response.bodyBytes);
        final Map<String, dynamic> data = json.decode(jsonBody);
        print('친구 이름 수정 결과: $data');
        print('===== 친구 이름 수정 완료 =====');
        return data;
      } else {
        print('API 오류: ${response.statusCode}');

        try {
          if (response.body.isNotEmpty) {
            final jsonBody = utf8.decode(response.bodyBytes);
            final errorData = json.decode(jsonBody);
            print('응답 본문: $jsonBody');
            print('오류 메시지: ${errorData['message'] ?? '알 수 없음'}');
            print('오류 코드: ${errorData['code'] ?? '알 수 없음'}');
          } else {
            print('응답 본문이 비어 있습니다.');
          }
        } catch (e) {
          print('오류 응답을 파싱할 수 없습니다: $e');
          print('응답 본문: ${response.body}');
        }

        print('===== 친구 이름 수정 실패 =====');
        return null;
      }
    } catch (e) {
      print('친구 이름 수정 중 예외 발생: $e');
      print('===== 친구 이름 수정 실패 (예외) =====');
      return null;
    }
  }

  // 나를 친구로 추가한 유저 목록 조회 (전체 조회로 변경)
  static Future<List<dynamic>?> getFriendsWhoAddedMe() async {
    try {
      print('===== 나를 친구로 추가한 유저 목록 조회 시작 =====');

      final accessToken = await AuthService.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        print('액세스 토큰이 없습니다.');
        return null;
      }

      final url = Uri.parse('$baseUrl/api-user/friend/added-me');
      print('나를 친구로 추가한 유저 목록 조회 API 호출: $url');

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      };

      final response = await http.get(url, headers: headers);
      print('나를 친구로 추가한 유저 목록 조회 응답 상태: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonBody = utf8.decode(response.bodyBytes);
        final List<dynamic> friends = json.decode(jsonBody);
        print('나를 친구로 추가한 유저 목록 조회 결과: $friends');
        print('친구 수: ${friends.length}');

        // 새로운 API 응답 구조에 맞게 데이터 처리
        for (var friend in friends) {
          final userInfo = friend['userInfo'] ?? {};
          final friendInfo = friend['friendInfo'] ?? {};

          print('사용자 정보:');
          print('- 사용자 ID: ${userInfo['userId'] ?? '정보 없음'}');
          print('- 실제 이름: ${userInfo['realName'] ?? '정보 없음'}');

          print('친구 정보:');
          print('- 친구 여부: ${friendInfo['isFriend'] ?? false}');
          print('- 친구 ID: ${friendInfo['friendId'] ?? '정보 없음'}');
          print('- 커스텀 이름: ${friendInfo['customName'] ?? '정보 없음'}');

          // 클라이언트 호환성을 위해 루트 레벨에 친구 정보 복사
          friend['isFriend'] = friendInfo['isFriend'];
          friend['friendId'] = friendInfo['friendId'];
          friend['customName'] = friendInfo['customName'];
          friend['isBlocked'] = friendInfo['isBlocked'];
          friend['isBestFriend'] = friendInfo['isBestFriend'];
        }

        return friends;
      } else {
        print('API 오류: ${response.statusCode}');
        print('응답 본문: ${response.body}');
        return null;
      }
    } catch (e) {
      print('나를 친구로 추가한 유저 목록 조회 중 예외 발생: $e');
      return null;
    }
  }

  // 상태 메시지 수정 API
  static Future<Map<String, dynamic>?> updateStatusMessage(
    String statusMessage,
  ) async {
    try {
      print('===== 상태 메시지 수정 시작 =====');
      print('새 상태 메시지: $statusMessage');
      print('요청 시간: ${DateTime.now()}');

      // 토큰 가져오기
      final accessToken = await AuthService.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        print('액세스 토큰이 없습니다.');
        return null;
      }

      // API URL 구성
      final url = Uri.parse('$baseUrl/api-user/user/status-message');
      print('상태 메시지 수정 API 호출: $url');

      // 요청 본문 구성
      final body = json.encode({'statusMessage': statusMessage});
      print('요청 본문: $body');

      // 헤더 설정 - 토큰 포함
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      };

      // API 호출 (PATCH 메서드 사용)
      final response = await http.patch(url, headers: headers, body: body);
      print('상태 메시지 수정 응답 상태: ${response.statusCode}');

      // 응답 처리
      if (response.statusCode == 200) {
        // UTF-8로 명시적으로 디코딩
        final jsonBody = utf8.decode(response.bodyBytes);
        final Map<String, dynamic> data = json.decode(jsonBody);
        print('상태 메시지 수정 결과: $data');
        print('===== 상태 메시지 수정 완료 =====');
        return data;
      } else {
        print('API 오류: ${response.statusCode}');

        try {
          if (response.body.isNotEmpty) {
            final jsonBody = utf8.decode(response.bodyBytes);
            final errorData = json.decode(jsonBody);
            print('응답 본문: $jsonBody');
            print('오류 메시지: ${errorData['message'] ?? '알 수 없음'}');
            print('오류 코드: ${errorData['code'] ?? '알 수 없음'}');
          } else {
            print('응답 본문이 비어 있습니다.');
          }
        } catch (e) {
          print('오류 응답을 파싱할 수 없습니다: $e');
          print('응답 본문: ${response.body}');
        }

        print('===== 상태 메시지 수정 실패 =====');
        return null;
      }
    } catch (e) {
      print('상태 메시지 수정 중 예외 발생: $e');
      print('===== 상태 메시지 수정 실패 (예외) =====');
      return null;
    }
  }

  // 가족 구성원 추가 API
  static Future<Map<String, dynamic>?> addFamilyMember(int targetUserId) async {
    try {
      print('===== 가족 구성원 추가 시작 =====');
      print('대상 사용자 ID: $targetUserId');
      print('요청 시간: ${DateTime.now()}');

      // 토큰 가져오기
      final accessToken = await AuthService.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        print('액세스 토큰이 없습니다.');
        return null;
      }

      // API URL 구성
      final url = Uri.parse('$baseUrl/api-user/family');
      print('가족 구성원 추가 API 호출: $url');

      // 요청 본문 구성
      final body = json.encode({'targetUserId': targetUserId});
      print('요청 본문: $body');

      // 헤더 설정 - 토큰 포함
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      };

      // API 호출
      final response = await http.post(url, headers: headers, body: body);
      print('가족 구성원 추가 응답 상태: ${response.statusCode}');

      // 응답 처리 - 201 상태 코드도 성공으로 처리
      if (response.statusCode == 200 || response.statusCode == 201) {
        // UTF-8로 명시적으로 디코딩
        final jsonBody = utf8.decode(response.bodyBytes);
        final Map<String, dynamic> data = json.decode(jsonBody);
        print('가족 구성원 추가 결과: $data');
        print('===== 가족 구성원 추가 완료 =====');
        return data;
      } else {
        print('API 오류: ${response.statusCode}');

        try {
          if (response.body.isNotEmpty) {
            final jsonBody = utf8.decode(response.bodyBytes);
            final errorData = json.decode(jsonBody);
            print('응답 본문: $jsonBody');
            print('오류 메시지: ${errorData['message'] ?? '알 수 없음'}');
            print('오류 코드: ${errorData['code'] ?? '알 수 없음'}');
          } else {
            print('응답 본문이 비어 있습니다.');
          }
        } catch (e) {
          print('오류 응답을 파싱할 수 없습니다: $e');
          print('응답 본문: ${response.body}');
        }

        print('===== 가족 구성원 추가 실패 =====');
        return null;
      }
    } catch (e) {
      print('가족 구성원 추가 중 예외 발생: $e');
      print('===== 가족 구성원 추가 실패 (예외) =====');
      return null;
    }
  }

  // 가족 구성원 목록 조회 API
  static Future<List<dynamic>?> getFamilyMembers() async {
    try {
      print('===== 가족 구성원 목록 조회 시작 =====');
      print('요청 시간: ${DateTime.now()}');

      // 토큰 가져오기
      final accessToken = await AuthService.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        print('액세스 토큰이 없습니다.');
        return null;
      }

      // API URL 구성
      final url = Uri.parse('$baseUrl/api-user/family/list');
      print('가족 구성원 목록 조회 API 호출: $url');

      // 헤더 설정 - 토큰 포함
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      };

      // API 호출
      final response = await http.get(url, headers: headers);
      print('가족 구성원 목록 조회 응답 상태: ${response.statusCode}');

      // 응답 처리
      if (response.statusCode == 200) {
        // UTF-8로 명시적으로 디코딩
        final jsonBody = utf8.decode(response.bodyBytes);
        final List<dynamic> data = json.decode(jsonBody);
        print('가족 구성원 목록 조회 결과: $data');
        print('===== 가족 구성원 목록 조회 완료 =====');
        return data;
      } else {
        print('API 오류: ${response.statusCode}');

        try {
          if (response.body.isNotEmpty) {
            final jsonBody = utf8.decode(response.bodyBytes);
            print('응답 본문: $jsonBody');
            try {
              final errorData = json.decode(jsonBody);
              print('오류 메시지: ${errorData['message'] ?? '알 수 없음'}');
              print('오류 코드: ${errorData['code'] ?? '알 수 없음'}');
            } catch (e) {
              print('JSON 형식이 아닌 오류 응답입니다.');
            }
          } else {
            print('응답 본문이 비어 있습니다.');
          }
        } catch (e) {
          print('오류 응답을 파싱할 수 없습니다: $e');
          print('응답 본문: ${response.body}');
        }

        print('===== 가족 구성원 목록 조회 실패 =====');
        return null;
      }
    } catch (e) {
      print('가족 구성원 목록 조회 중 예외 발생: $e');
      print('===== 가족 구성원 목록 조회 실패 (예외) =====');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> addFriend(int targetUserId) async {
    try {
      print('===== 친구 추가 API 호출 시작 =====');
      print('API: POST /api-user/friend');
      print('대상 사용자 ID: $targetUserId');

      final response = await http.post(
        Uri.parse('${baseUrl}/api-user/friend'),
        headers: await AuthService.getHeaders(),
        body: json.encode({'targetUserId': targetUserId}),
      );

      print('응답 상태 코드: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> data = json.decode(response.body);
        print('친구 추가 성공 - 응답: $data');
        return data;
      } else {
        print('친구 추가 실패 - 상태 코드: ${response.statusCode}');
        print('응답 본문: ${response.body}');
        return null;
      }
    } catch (e) {
      print('친구 추가 중 오류: $e');
      return null;
    }
  }

  // 친구 검색 API (사용하지 않지만 추가)
  static Future<List<dynamic>?> searchFriends(String keyword) async {
    try {
      print('===== 친구 검색 시작 =====');
      print('검색 키워드: $keyword');

      final accessToken = await AuthService.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        print('액세스 토큰이 없습니다.');
        return null;
      }

      final url = Uri.parse('$baseUrl/api-user/friend/search?keyword=$keyword');
      print('친구 검색 API 호출: $url');

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      };

      final response = await http.get(url, headers: headers);
      print('친구 검색 응답 상태: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonBody = utf8.decode(response.bodyBytes);
        final List<dynamic> results = json.decode(jsonBody);
        print('친구 검색 결과: ${results.length}개');
        return results;
      } else {
        print('API 오류: ${response.statusCode}');
        print('응답 본문: ${response.body}');
        return null;
      }
    } catch (e) {
      print('친구 검색 중 예외 발생: $e');
      return null;
    }
  }

  // 친구 검색 기록 저장 API
  static Future<Map<String, dynamic>?> saveSearchHistory(int friendId) async {
    try {
      print('===== 친구 검색 기록 저장 시작 =====');
      print('친구 ID: $friendId');

      final accessToken = await AuthService.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        print('액세스 토큰이 없습니다.');
        return null;
      }

      final url = Uri.parse('$baseUrl/api-user/friend/search/history');
      print('친구 검색 기록 저장 API 호출: $url');

      final body = json.encode({'friendId': friendId});
      print('요청 본문: $body');

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      };

      final response = await http.post(url, headers: headers, body: body);
      print('친구 검색 기록 저장 응답 상태: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonBody = utf8.decode(response.bodyBytes);
        final Map<String, dynamic> data = json.decode(jsonBody);
        print('친구 검색 기록 저장 결과: $data');
        return data;
      } else {
        print('API 오류: ${response.statusCode}');
        print('응답 본문: ${response.body}');
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

      final accessToken = await AuthService.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        print('액세스 토큰이 없습니다.');
        return false;
      }

      final url = Uri.parse('$baseUrl/api-user/friend/search/history');
      print('친구 검색 기록 삭제 API 호출: $url');

      final body = json.encode({'searchHistoryIds': searchHistoryIds});
      print('요청 본문: $body');

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      };

      final response = await http.delete(url, headers: headers, body: body);
      print('친구 검색 기록 삭제 응답 상태: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('친구 검색 기록 삭제 성공');
        return true;
      } else {
        print('API 오류: ${response.statusCode}');
        print('응답 본문: ${response.body}');
        return false;
      }
    } catch (e) {
      print('친구 검색 기록 삭제 중 예외 발생: $e');
      return false;
    }
  }

  // 친구 최근 검색어 조회 API
  static Future<List<dynamic>?> getRecentSearchHistory() async {
    try {
      print('===== 친구 최근 검색어 조회 시작 =====');

      final accessToken = await AuthService.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        print('액세스 토큰이 없습니다.');
        return null;
      }

      final url = Uri.parse('$baseUrl/api-user/friend/search/history');
      print('친구 최근 검색어 조회 API 호출: $url');

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      };

      final response = await http.get(url, headers: headers);
      print('친구 최근 검색어 조회 응답 상태: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonBody = utf8.decode(response.bodyBytes);
        final List<dynamic> data = json.decode(jsonBody);
        print('친구 최근 검색어 조회 결과: ${data.length}개');
        return data;
      } else {
        print('API 오류: ${response.statusCode}');
        print('응답 본문: ${response.body}');
        return null;
      }
    } catch (e) {
      print('친구 최근 검색어 조회 중 예외 발생: $e');
      return null;
    }
  }
}
