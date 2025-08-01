import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';

class FamilyService {
  // 서버 기본 URL
  static const String baseUrl = 'http://3.34.52.239:8080';

  // 가족 멤버 추가 API
  static Future<Map<String, dynamic>?> addFamilyMember(int targetUserId) async {
    try {
      print('===== 가족 멤버 추가 시작 =====');
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
      print('가족 멤버 추가 API 호출: $url');

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
      print('가족 멤버 추가 응답 상태: ${response.statusCode}');

      // 응답 처리
      if (response.statusCode == 200 || response.statusCode == 201) {
        // UTF-8로 명시적으로 디코딩
        final jsonBody = utf8.decode(response.bodyBytes);
        final Map<String, dynamic> data = json.decode(jsonBody);
        print('가족 멤버 추가 결과: $data');
        print('===== 가족 멤버 추가 완료 =====');
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

            // 이미 초대를 보낸 유저인 경우 또는 이미 가족 멤버로 소속되어 있는 경우
            if (errorData['code'] == 'F001' || errorData['code'] == 'F002') {
              return {
                'error': true,
                'errorCode': errorData['code'],
                'message':
                    errorData['message'] ?? '이미 초대되었거나 가족 멤버로 소속되어 있습니다.',
              };
            }
          } else {
            print('응답 본문이 비어 있습니다.');
          }
        } catch (e) {
          print('오류 응답을 파싱할 수 없습니다: $e');
          final decodedBody =
              response.bodyBytes.isNotEmpty
                  ? utf8.decode(response.bodyBytes)
                  : '응답 내용 없음';
          print('응답 본문: $decodedBody');
        }

        print('===== 가족 멤버 추가 실패 =====');
        return null;
      }
    } catch (e) {
      print('가족 멤버 추가 중 예외 발생: $e');
      print('===== 가족 멤버 추가 실패 (예외) =====');
      return null;
    }
  }

  // 초대 받은 목록 조회 API
  static Future<List<dynamic>?> getReceivedInvites() async {
    try {
      print('===== 초대 받은 목록 조회 시작 =====');
      print('요청 시간: ${DateTime.now()}');

      // 토큰 가져오기
      final accessToken = await AuthService.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        print('액세스 토큰이 없습니다.');
        return null;
      }

      // API URL 구성
      final url = Uri.parse('$baseUrl/api-user/family/invite/received');
      print('초대 받은 목록 조회 API 호출: $url');

      // 헤더 설정 - 토큰 포함
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      };

      // API 호출
      final response = await http.get(url, headers: headers);
      print('초대 받은 목록 조회 응답 상태: ${response.statusCode}');

      // 응답 처리
      if (response.statusCode == 200) {
        // UTF-8로 명시적으로 디코딩
        try {
          final jsonBody = utf8.decode(response.bodyBytes);
          print('UTF-8 디코딩된 응답 본문: $jsonBody');

          final List<dynamic> data = json.decode(jsonBody);
          print('초대 받은 목록 조회 결과: $data');

          if (data.isNotEmpty) {
            print('받은 초대 수: ${data.length}');
            for (var invite in data) {
              print('- 가족 멤버 ID: ${invite['familyMemberId']}');
              print('- 가족 ID: ${invite['familyId']}');
              print('- 초대자 ID: ${invite['inviterId']}');
              print('- 초대자 이름: ${invite['inviterName']}');
              print('- 초대 날짜: ${invite['invitedDate']}');
            }
          } else {
            print('받은 초대가 없습니다.');
          }

          print('===== 초대 받은 목록 조회 완료 =====');
          return data;
        } catch (e) {
          print('JSON 파싱 오류: $e');
          final decodedBody =
              response.bodyBytes.isNotEmpty
                  ? utf8.decode(response.bodyBytes)
                  : '응답 내용 없음';
          print('파싱 실패한 응답 본문: $decodedBody');
          return null;
        }
      } else {
        print('API 오류: ${response.statusCode}');
        final decodedBody =
            response.bodyBytes.isNotEmpty
                ? utf8.decode(response.bodyBytes)
                : '응답 내용 없음';
        print('응답 본문: $decodedBody');

        print('===== 초대 받은 목록 조회 실패 =====');
        return null;
      }
    } catch (e) {
      print('초대 받은 목록 조회 중 예외 발생: $e');
      print('===== 초대 받은 목록 조회 실패 (예외) =====');
      return null;
    }
  }

  // 가족 그룹 소속 여부 확인 API
  static Future<Map<String, dynamic>?> checkJoinedFamily() async {
    try {
      print('===== 가족 그룹 소속 여부 확인 시작 =====');
      print('요청 시간: ${DateTime.now()}');

      // 토큰 가져오기
      final accessToken = await AuthService.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        print('액세스 토큰이 없습니다.');
        return null;
      }

      // API URL 구성
      final url = Uri.parse('$baseUrl/api-user/family/check-joined');
      print('가족 그룹 소속 여부 확인 API 호출: $url');

      // 헤더 설정 - 토큰 포함
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      };

      // API 호출
      final response = await http.get(url, headers: headers);
      print('가족 그룹 소속 여부 확인 응답 상태: ${response.statusCode}');

      // 응답 처리
      if (response.statusCode == 200) {
        // UTF-8로 명시적으로 디코딩
        final jsonBody = utf8.decode(response.bodyBytes);
        final Map<String, dynamic> data = json.decode(jsonBody);
        print('가족 그룹 소속 여부 확인 결과: $data');
        print('가족 그룹 소속 여부: ${data['isJoined']}');
        print('===== 가족 그룹 소속 여부 확인 완료 =====');
        return data;
      } else {
        print('API 오류: ${response.statusCode}');
        final decodedBody =
            response.bodyBytes.isNotEmpty
                ? utf8.decode(response.bodyBytes)
                : '응답 내용 없음';
        print('응답 본문: $decodedBody');

        print('===== 가족 그룹 소속 여부 확인 실패 =====');
        return null;
      }
    } catch (e) {
      print('가족 그룹 소속 여부 확인 중 예외 발생: $e');
      print('===== 가족 그룹 소속 여부 확인 실패 (예외) =====');
      return null;
    }
  }

  // 멤버 초대 수락 API
  static Future<Map<String, dynamic>?> acceptFamilyInvite(
    int familyMemberId,
  ) async {
    try {
      print('===== 멤버 초대 수락 시작 =====');
      print('가족 멤버 ID: $familyMemberId');
      print('요청 시간: ${DateTime.now()}');

      // 토큰 가져오기
      final accessToken = await AuthService.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        print('액세스 토큰이 없습니다.');
        return null;
      }

      // API URL 구성
      final url = Uri.parse(
        '$baseUrl/api-user/family/invite/accept/$familyMemberId',
      );
      print('멤버 초대 수락 API 호출: $url');

      // 헤더 설정 - 토큰 포함
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      };

      // API 호출 (PATCH 메서드 사용)
      final response = await http.patch(url, headers: headers);
      print('멤버 초대 수락 응답 상태: ${response.statusCode}');

      // 응답 처리
      if (response.statusCode == 200) {
        // UTF-8로 명시적으로 디코딩
        final jsonBody = utf8.decode(response.bodyBytes);
        final Map<String, dynamic> data = json.decode(jsonBody);
        print('멤버 초대 수락 결과: $data');
        print('===== 멤버 초대 수락 완료 =====');
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

            // 부모님이 이미 두 분이 존재하는 경우 처리
            if (errorData['code'] == 'F003') {
              return {
                'error': true,
                'errorCode': 'F003',
                'message': '부모님이 이미 두 분이 존재합니다.',
              };
            }
          } else {
            print('응답 본문이 비어 있습니다.');
          }
        } catch (e) {
          print('오류 응답을 파싱할 수 없습니다: $e');
          final decodedBody =
              response.bodyBytes.isNotEmpty
                  ? utf8.decode(response.bodyBytes)
                  : '응답 내용 없음';
          print('응답 본문: $decodedBody');
        }

        print('===== 멤버 초대 수락 실패 =====');
        return null;
      }
    } catch (e) {
      print('멤버 초대 수락 중 예외 발생: $e');
      print('===== 멤버 초대 수락 실패 (예외) =====');
      return null;
    }
  }

  // 내 가족 정보 조회 API
  static Future<Map<String, dynamic>?> getFamilyInfo() async {
    try {
      print('===== 내 가족 정보 조회 시작 =====');
      print('요청 시간: ${DateTime.now()}');

      // 토큰 가져오기
      final accessToken = await AuthService.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        print('액세스 토큰이 없습니다.');
        return null;
      }

      // API URL 구성
      final url = Uri.parse('$baseUrl/api-user/family');
      print('내 가족 정보 조회 API 호출: $url');

      // 헤더 설정 - 토큰 포함
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      };

      print('요청 헤더: $headers');

      // API 호출 (GET 메서드 사용)
      final response = await http.get(url, headers: headers);

      print('내 가족 정보 조회 응답 상태: ${response.statusCode}');
      print('응답 헤더: ${response.headers}');

      // 디버깅을 위해 응답 전체 내용 출력 - UTF-8 디코딩 적용
      final decodedBody =
          response.bodyBytes.isNotEmpty
              ? utf8.decode(response.bodyBytes)
              : '응답 내용 없음';
      print('응답 본문 전체: $decodedBody');

      // 응답 처리
      if (response.statusCode == 200) {
        // 응답 본문이 비어있지 않은지 확인
        if (response.body.isEmpty) {
          print('응답 본문이 비어 있습니다.');
          return null;
        }

        // JSON 파싱 - UTF-8로 명시적 디코딩 추가
        try {
          // 이미 위에서 디코딩한 본문 재사용
          print('UTF-8 디코딩된 응답 본문: $decodedBody');

          final Map<String, dynamic> data = json.decode(decodedBody);
          print('파싱된 가족 정보: $data');

          // 멤버 리스트 정보 확인
          if (data.containsKey('memberInfoList')) {
            final memberList = data['memberInfoList'] as List;
            print('가족 멤버 수: ${memberList.length}');

            // 멤버 정보 디버깅 출력 - 모든 필드 출력
            for (var i = 0; i < memberList.length; i++) {
              final member = memberList[i];
              print('멤버 $i 전체 데이터: $member');
              print('멤버 $i - 구조: ${member.runtimeType}');
              print('멤버 $i - 모든 키: ${member.keys}');

              // 각 필드 개별 출력
              member.forEach((key, value) {
                print('멤버 $i - $key: $value');
              });

              print(
                '멤버 $i - 닉네임: ${member['nickname']}, 실제 이름: ${member['realName']}',
              );
              print(
                '멤버 $i - 역할: ${member['role']}, 프로필 이미지: ${member['profileImagePath']}',
              );
              print(
                '멤버 $i - familyMemberId: ${member['familyMemberId']}, userId: ${member['userId']}',
              );
            }
          } else {
            print('가족 멤버 정보 없음');
          }

          return data;
        } catch (e) {
          print('JSON 파싱 오류: $e');
          // 파싱 실패 로그에도 디코딩 적용
          print('파싱 실패한 응답 본문: $decodedBody');
          return null;
        }
      } else if (response.statusCode == 204) {
        // 콘텐츠 없음 (가족 정보가 없는 경우)
        print('가족 정보가 없습니다 (204 No Content)');
        return {'familyId': null, 'memberInfoList': []};
      } else {
        // 오류 처리
        print('API 오류: ${response.statusCode}');
        // 오류 응답도 디코딩 적용
        print('응답 본문: $decodedBody');

        try {
          final errorData = json.decode(decodedBody);
          print('오류 메시지: ${errorData['message']}');
          print('오류 코드: ${errorData['code']}');

          // FA001 오류 코드는 "가족이 존재하지 않음"을 의미하므로 정상적인 상황으로 처리
          if (errorData['code'] == 'FA001') {
            print('가족이 존재하지 않습니다 (FA001). 빈 가족 목록 반환');
            return {'familyId': null, 'memberInfoList': []};
          }
        } catch (e) {
          print('오류 응답 파싱 실패: $e');
        }

        // 다른 오류는 그대로 null 반환
        return null;
      }
    } catch (e) {
      print('내 가족 정보 조회 중 예외 발생: $e');
      print('스택 트레이스: ${e.toString()}');
      return null;
    } finally {
      print('===== 내 가족 정보 조회 종료 =====');
    }
  }

  // 내 별명 설정 API
  static Future<Map<String, dynamic>?> updateMyNickname(
    String nickname, {
    int? familyMemberId,
  }) async {
    try {
      print('===== 내 별명 설정 시작 =====');
      print('새 별명: $nickname');
      if (familyMemberId != null) {
        print('가족 멤버 ID: $familyMemberId');
      }
      print('요청 시간: ${DateTime.now()}');

      // 토큰 가져오기
      final accessToken = await AuthService.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        print('액세스 토큰이 없습니다.');
        return null;
      }

      // API URL 구성
      final url = Uri.parse('$baseUrl/api-user/family/me/nickname');
      print('내 별명 설정 API 호출: $url');

      // 요청 본문 구성 - familyMemberId가 제공되면 포함
      final Map<String, dynamic> requestBody = {"nickname": nickname};
      if (familyMemberId != null) {
        requestBody["familyMemberId"] = familyMemberId;
      }

      final body = json.encode(requestBody);
      print('요청 본문: $body');

      // 헤더 설정 - 토큰 포함
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      };

      // API 호출 (PATCH 메서드 사용)
      final response = await http.patch(url, headers: headers, body: body);
      print('내 별명 설정 응답 상태: ${response.statusCode}');

      // 응답 처리
      if (response.statusCode == 200) {
        // UTF-8로 명시적으로 디코딩
        final jsonBody = utf8.decode(response.bodyBytes);
        final Map<String, dynamic> data = json.decode(jsonBody);
        print('내 별명 설정 결과: $data');
        print('===== 내 별명 설정 완료 =====');
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
          final decodedBody =
              response.bodyBytes.isNotEmpty
                  ? utf8.decode(response.bodyBytes)
                  : '응답 내용 없음';
          print('응답 본문: $decodedBody');
        }

        print('===== 내 별명 설정 실패 =====');
        return null;
      }
    } catch (e) {
      print('내 별명 설정 중 예외 발생: $e');
      print('===== 내 별명 설정 실패 (예외) =====');
      return null;
    }
  }

  // 멤버 초대 거절 API
  static Future<bool> rejectFamilyInvite(int familyMemberId) async {
    try {
      print('===== 멤버 초대 거절 시작 =====');
      print('가족 멤버 ID: $familyMemberId');
      print('요청 시간: ${DateTime.now()}');

      // 토큰 가져오기
      final accessToken = await AuthService.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        print('액세스 토큰이 없습니다.');
        return false;
      }

      // API URL 구성
      final url = Uri.parse(
        '$baseUrl/api-user/family/invite/refuse/$familyMemberId',
      );
      print('멤버 초대 거절 API 호출: $url');

      // 헤더 설정 - 토큰 포함
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      };

      // API 호출 (DELETE 메서드 사용)
      final response = await http.delete(url, headers: headers);
      print('멤버 초대 거절 응답 상태: ${response.statusCode}');

      // 응답 처리 - 200(OK)과 204(No Content) 모두 성공으로 처리
      if (response.statusCode == 200 || response.statusCode == 204) {
        print('멤버 초대 거절 성공 (응답 코드: ${response.statusCode})');
        print('===== 멤버 초대 거절 완료 =====');
        return true;
      } else {
        print('API 오류: ${response.statusCode}');
        final decodedBody =
            response.bodyBytes.isNotEmpty
                ? utf8.decode(response.bodyBytes)
                : '응답 내용 없음';
        print('응답 본문: $decodedBody');
        print('===== 멤버 초대 거절 실패 =====');
        return false;
      }
    } catch (e) {
      print('멤버 초대 거절 중 예외 발생: $e');
      print('===== 멤버 초대 거절 실패 (예외) =====');
      return false;
    }
  }

  // 가족 초대 처리 로직
  static Future<Map<String, dynamic>> processInvitation(
    int familyMemberId,
  ) async {
    print('===== 가족 초대 처리 시작 =====');
    print('가족 멤버 ID: $familyMemberId');

    try {
      // 1. 가족 그룹 소속 여부 확인
      final checkResult = await checkJoinedFamily();

      if (checkResult == null) {
        print('가족 그룹 소속 여부 확인 실패');
        return {
          'success': false,
          'needWarning': false,
          'message': '가족 그룹 소속 여부 확인에 실패했습니다.',
        };
      }

      final bool isJoined = checkResult['isJoined'] ?? false;
      print('가족 그룹 소속 여부: $isJoined');

      // 2. 소속 여부에 따른 처리
      if (isJoined) {
        // 이미 가족에 소속된 경우 - 경고 필요
        print('이미 다른 가족에 소속되어 있습니다. 경고 표시 필요');
        return {
          'success': true,
          'needWarning': true,
          'message': '이미 다른 가족 그룹에 소속되어 있습니다. 초대를 수락하면 기존 가족에서 자동으로 나가집니다.',
        };
      } else {
        // 가족에 소속되지 않은 경우 - 바로 수락 처리
        print('가족에 소속되어 있지 않습니다. 바로 수락 처리');
        final acceptResult = await acceptFamilyInvite(familyMemberId);

        if (acceptResult == null) {
          print('초대 수락 실패');
          return {
            'success': false,
            'needWarning': false,
            'message': '초대 수락에 실패했습니다.',
          };
        }

        // 오류 코드가 있는지 확인
        if (acceptResult.containsKey('error') &&
            acceptResult['error'] == true) {
          print('초대 수락 오류: ${acceptResult['message']}');
          return {
            'success': false,
            'needWarning': false,
            'message': acceptResult['message'] ?? '초대 수락 중 오류가 발생했습니다.',
          };
        }

        print('초대 수락 성공');
        return {
          'success': true,
          'needWarning': false,
          'message': '가족 초대를 수락했습니다.',
          'data': acceptResult,
        };
      }
    } catch (e) {
      print('가족 초대 처리 중 예외 발생: $e');
      return {
        'success': false,
        'needWarning': false,
        'message': '처리 중 오류가 발생했습니다: $e',
      };
    } finally {
      print('===== 가족 초대 처리 종료 =====');
    }
  }

  // 사용자 선택 후 초대 처리 (경고창 표시 후 호출)
  static Future<Map<String, dynamic>> processInvitationAfterWarning(
    int familyMemberId,
    bool userAccepted,
  ) async {
    print('===== 경고 확인 후 초대 처리 시작 =====');
    print('가족 멤버 ID: $familyMemberId');
    print('사용자 수락 여부: $userAccepted');

    try {
      if (userAccepted) {
        // 사용자가 수락을 선택한 경우
        final acceptResult = await acceptFamilyInvite(familyMemberId);

        if (acceptResult == null) {
          print('초대 수락 실패');
          return {'success': false, 'message': '초대 수락에 실패했습니다.'};
        }

        // 오류 코드가 있는지 확인
        if (acceptResult.containsKey('error') &&
            acceptResult['error'] == true) {
          print('초대 수락 오류: ${acceptResult['message']}');
          return {
            'success': false,
            'message': acceptResult['message'] ?? '초대 수락 중 오류가 발생했습니다.',
          };
        }

        print('초대 수락 성공');
        return {
          'success': true,
          'message': '가족 초대를 수락했습니다.',
          'data': acceptResult,
        };
      } else {
        // 사용자가 거절을 선택한 경우 - DELETE API 사용
        final rejectResult = await rejectFamilyInvite(familyMemberId);

        if (!rejectResult) {
          print('초대 거절 실패');
          return {'success': false, 'message': '초대 거절에 실패했습니다.'};
        }

        print('초대 거절 성공');
        return {'success': true, 'message': '가족 초대를 거절했습니다.'};
      }
    } catch (e) {
      print('경고 확인 후 초대 처리 중 예외 발생: $e');
      return {'success': false, 'message': '처리 중 오류가 발생했습니다: $e'};
    } finally {
      print('===== 경고 확인 후 초대 처리 종료 =====');
    }
  }

  // 타겟 사용자의 가족 그룹 소속 여부 확인 API
  static Future<Map<String, dynamic>?> checkTargetFamilyStatus(
    int targetUserId,
  ) async {
    try {
      print('===== 타겟 사용자 가족 그룹 소속 여부 확인 시작 =====');
      print('타겟 사용자 ID: $targetUserId');
      print('요청 시간: ${DateTime.now()}');

      // 토큰 가져오기
      final accessToken = await AuthService.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        print('액세스 토큰이 없습니다.');
        return null;
      }

      // API URL 구성 - 타겟 유저의 ID를 쿼리 파라미터로 추가
      final url = Uri.parse(
        '$baseUrl/api-user/family/check-joined?targetUserId=$targetUserId',
      );
      print('타겟 사용자 가족 그룹 소속 여부 확인 API 호출: $url');

      // 헤더 설정 - 토큰 포함
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      };

      // API 호출
      final response = await http.get(url, headers: headers);
      print('타겟 사용자 가족 그룹 소속 여부 확인 응답 상태: ${response.statusCode}');

      // 응답 처리
      if (response.statusCode == 200) {
        // UTF-8로 명시적으로 디코딩
        final jsonBody = utf8.decode(response.bodyBytes);
        final Map<String, dynamic> data = json.decode(jsonBody);
        print('타겟 사용자 가족 그룹 소속 여부 확인 결과: $data');
        print('타겟 사용자 가족 그룹 소속 여부: ${data['isJoined']}');
        print('===== 타겟 사용자 가족 그룹 소속 여부 확인 완료 =====');
        return data;
      } else {
        print('API 오류: ${response.statusCode}');
        print('응답 본문: ${response.body}');

        print('===== 타겟 사용자 가족 그룹 소속 여부 확인 실패 =====');
        return null;
      }
    } catch (e) {
      print('타겟 사용자 가족 그룹 소속 여부 확인 중 예외 발생: $e');
      print('===== 타겟 사용자 가족 그룹 소속 여부 확인 실패 (예외) =====');
      return null;
    }
  }

  // 초대 요청 중인 멤버 목록 조회 API
  static Future<List<dynamic>?> getSentInvites(int familyId) async {
    try {
      print('===== 초대 요청 중인 멤버 목록 조회 시작 =====');
      print('가족 ID: $familyId');
      print('요청 시간: ${DateTime.now()}');

      // 토큰 가져오기
      final accessToken = await AuthService.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        print('액세스 토큰이 없습니다.');
        return null;
      }

      // API URL 구성
      final url = Uri.parse('$baseUrl/api-user/family/invite/sent/$familyId');
      print('초대 요청 중인 멤버 목록 조회 API 호출: $url');

      // 헤더 설정 - 토큰 포함
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      };

      // API 호출
      final response = await http.get(url, headers: headers);
      print('초대 요청 중인 멤버 목록 조회 응답 상태: ${response.statusCode}');

      // 응답 처리
      if (response.statusCode == 200) {
        // UTF-8로 명시적으로 디코딩
        try {
          final jsonBody = utf8.decode(response.bodyBytes);
          print('UTF-8 디코딩된 응답 본문: $jsonBody');

          final List<dynamic> data = json.decode(jsonBody);
          print('초대 요청 중인 멤버 목록 조회 결과: $data');

          if (data.isNotEmpty) {
            print('초대 요청 중인 멤버 수: ${data.length}');
            for (var invite in data) {
              print('- 가족 멤버 ID: ${invite['familyMemberId']}');
              print('- 초대한 대상 ID: ${invite['inviteeId']}');
              print('- 초대한 대상 이름: ${invite['inviteeName']}');
              print('- 초대자 이름: ${invite['inviterName']}');
              print('- 초대 날짜: ${invite['invitedDate']}');
            }
          } else {
            print('초대 요청 중인 멤버가 없습니다.');
          }

          print('===== 초대 요청 중인 멤버 목록 조회 완료 =====');
          return data;
        } catch (e) {
          print('JSON 파싱 오류: $e');
          final decodedBody =
              response.bodyBytes.isNotEmpty
                  ? utf8.decode(response.bodyBytes)
                  : '응답 내용 없음';
          print('파싱 실패한 응답 본문: $decodedBody');
          return null;
        }
      } else {
        print('API 오류: ${response.statusCode}');
        final decodedBody =
            response.bodyBytes.isNotEmpty
                ? utf8.decode(response.bodyBytes)
                : '응답 내용 없음';
        print('응답 본문: $decodedBody');

        print('===== 초대 요청 중인 멤버 목록 조회 실패 =====');
        return null;
      }
    } catch (e) {
      print('초대 요청 중인 멤버 목록 조회 중 예외 발생: $e');
      print('===== 초대 요청 중인 멤버 목록 조회 실패 (예외) =====');
      return null;
    }
  }

  // 초대 취소 API
  static Future<bool> cancelInvitation(int familyMemberId) async {
    try {
      print('===== 초대 취소 시작 =====');
      print('가족 멤버 ID: $familyMemberId');
      print('요청 시간: ${DateTime.now()}');

      // 토큰 가져오기
      final accessToken = await AuthService.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        print('액세스 토큰이 없습니다.');
        return false;
      }

      // API URL 구성
      final url = Uri.parse(
        '$baseUrl/api-user/family/invite/cancel/$familyMemberId',
      );
      print('초대 취소 API 호출: $url');

      // 헤더 설정 - 토큰 포함
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      };

      // API 호출 (DELETE 메서드 사용)
      final response = await http.delete(url, headers: headers);
      print('초대 취소 응답 상태: ${response.statusCode}');

      // 응답 처리 - 200(OK)과 204(No Content) 모두 성공으로 처리
      if (response.statusCode == 200 || response.statusCode == 204) {
        print('초대 취소 성공 (응답 코드: ${response.statusCode})');
        print('===== 초대 취소 완료 =====');
        return true;
      } else {
        print('API 오류: ${response.statusCode}');
        final decodedBody =
            response.bodyBytes.isNotEmpty
                ? utf8.decode(response.bodyBytes)
                : '응답 내용 없음';
        print('응답 본문: $decodedBody');
        print('===== 초대 취소 실패 =====');
        return false;
      }
    } catch (e) {
      print('초대 취소 중 예외 발생: $e');
      print('===== 초대 취소 실패 (예외) =====');
      return false;
    }
  }

  // 가족 멤버 추방 API
  static Future<Map<String, dynamic>> forceOutFamilyMember(
    int familyMemberId,
  ) async {
    try {
      print('===== 가족 멤버 추방 시작 =====');
      print('추방할 가족 멤버 ID: $familyMemberId');
      print('요청 시간: ${DateTime.now()}');

      // 토큰 가져오기
      final accessToken = await AuthService.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        print('액세스 토큰이 없습니다.');
        return {'success': false, 'message': '인증 정보가 없습니다'};
      }

      // API URL 구성
      final url = Uri.parse(
        '$baseUrl/api-user/family/force-out/$familyMemberId',
      );
      print('가족 멤버 추방 API 호출: $url');

      // 헤더 설정 - 토큰 포함
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      };

      // API 호출 (DELETE 메서드 사용)
      final response = await http.delete(url, headers: headers);
      print('가족 멤버 추방 응답 상태: ${response.statusCode}');

      // 응답 처리
      if (response.statusCode == 200 || response.statusCode == 204) {
        print('가족 멤버 추방 성공 (응답 코드: ${response.statusCode})');
        print('===== 가족 멤버 추방 완료 =====');
        return {'success': true, 'message': '가족 멤버 추방이 완료되었습니다'};
      } else {
        print('API 오류: ${response.statusCode}');

        try {
          if (response.body.isNotEmpty) {
            final jsonBody = utf8.decode(response.bodyBytes);
            final errorData = json.decode(jsonBody);
            print('응답 본문: $jsonBody');
            print('오류 메시지: ${errorData['message'] ?? '알 수 없음'}');
            print('오류 코드: ${errorData['code'] ?? '알 수 없음'}');

            // 권한 관련 오류 처리
            if (errorData['code'] == 'F004') {
              return {
                'success': false,
                'message': '추방 권한이 없습니다. 부모님만 가족 멤버를 추방할 수 있습니다.',
                'errorCode': 'F004',
              };
            }

            return {
              'success': false,
              'message': errorData['message'] ?? '가족 멤버 추방 중 오류가 발생했습니다',
              'errorCode': errorData['code'],
            };
          }
        } catch (e) {
          print('오류 응답을 파싱할 수 없습니다: $e');
        }

        final decodedBody =
            response.bodyBytes.isNotEmpty
                ? utf8.decode(response.bodyBytes)
                : '응답 내용 없음';
        print('응답 본문: $decodedBody');
        print('===== 가족 멤버 추방 실패 =====');
        return {'success': false, 'message': '가족 멤버 추방에 실패했습니다'};
      }
    } catch (e) {
      print('가족 멤버 추방 중 예외 발생: $e');
      print('===== 가족 멤버 추방 실패 (예외) =====');
      return {'success': false, 'message': '처리 중 오류가 발생했습니다: $e'};
    }
  }

  // 가족 그룹 나가기 API
  static Future<Map<String, dynamic>> leaveFamily(int familyMemberId) async {
    try {
      print('===== 가족 그룹 나가기 시작 =====');
      print('나갈 가족 멤버 ID: $familyMemberId');
      print('요청 시간: ${DateTime.now()}');

      // 토큰 가져오기
      final accessToken = await AuthService.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        print('액세스 토큰이 없습니다.');
        return {'success': false, 'message': '인증 정보가 없습니다'};
      }

      // API URL 구성
      final url = Uri.parse('$baseUrl/api-user/family/leave/$familyMemberId');
      print('가족 그룹 나가기 API 호출: $url');

      // 헤더 설정 - 토큰 포함
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      };

      // API 호출 (DELETE 메서드 사용)
      final response = await http.delete(url, headers: headers);
      print('가족 그룹 나가기 응답 상태: ${response.statusCode}');

      // 응답 처리
      if (response.statusCode == 200 || response.statusCode == 204) {
        print('가족 그룹 나가기 성공 (응답 코드: ${response.statusCode})');
        print('===== 가족 그룹 나가기 완료 =====');
        return {'success': true, 'message': '가족 그룹에서 나가기가 완료되었습니다'};
      } else {
        print('API 오류: ${response.statusCode}');

        try {
          if (response.body.isNotEmpty) {
            final jsonBody = utf8.decode(response.bodyBytes);
            final errorData = json.decode(jsonBody);
            print('응답 본문: $jsonBody');
            print('오류 메시지: ${errorData['message'] ?? '알 수 없음'}');
            print('오류 코드: ${errorData['code'] ?? '알 수 없음'}');

            return {
              'success': false,
              'message': errorData['message'] ?? '가족 그룹에서 나가기 중 오류가 발생했습니다',
              'errorCode': errorData['code'],
            };
          }
        } catch (e) {
          print('오류 응답을 파싱할 수 없습니다: $e');
        }

        final decodedBody =
            response.bodyBytes.isNotEmpty
                ? utf8.decode(response.bodyBytes)
                : '응답 내용 없음';
        print('응답 본문: $decodedBody');
        print('===== 가족 그룹 나가기 실패 =====');
        return {'success': false, 'message': '가족 그룹에서 나가기에 실패했습니다'};
      }
    } catch (e) {
      print('가족 그룹 나가기 중 예외 발생: $e');
      print('===== 가족 그룹 나가기 실패 (예외) =====');
      return {'success': false, 'message': '처리 중 오류가 발생했습니다: $e'};
    }
  }

  // 가족 멤버 삭제
  static Future<Map<String, dynamic>> deleteFamilyMember(
    int familyMemberId,
  ) async {
    try {
      final response = await http.delete(
        Uri.parse('${baseUrl}/api/v1/family/members/$familyMemberId'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return {'success': true};
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? '가족 멤버 삭제에 실패했습니다',
        };
      }
    } catch (e) {
      return {'success': false, 'message': '오류가 발생했습니다: $e'};
    }
  }

  // API 요청 헤더 생성
  static Future<Map<String, String>> _getHeaders() async {
    final token = await AuthService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }
}
