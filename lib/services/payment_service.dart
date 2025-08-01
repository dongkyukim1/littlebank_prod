import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'auth_service.dart';

class PaymentService {
  // API 기본 URL
  static String get baseUrl => dotenv.env['API_BASE_URL'] ?? '';

  // 결제 정보 저장 API 호출
  static Future<Map<String, dynamic>> savePayment(String impUid) async {
    if (baseUrl.isEmpty) {
      throw Exception('API_BASE_URL가 설정되지 않았습니다. .env 파일을 확인하세요.');
    }

    // 액세스 토큰 가져오기 (인증 필요한 API)
    String? accessToken = await AuthService.getAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('인증이 필요합니다. 로그인 후 다시 시도해주세요.');
    }

    final url = Uri.parse('$baseUrl/api-user/point/charge/payment/info');

    // 요청 바디 생성
    final Map<String, dynamic> body = {'impUid': impUid};

    print('결제 정보 저장 API 요청: $body');

    try {
      // POST 요청 보내기
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(body),
      );

      print('결제 정보 저장 API 응답 상태: ${response.statusCode}');
      print('결제 정보 저장 API 응답 본문: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        // 응답 본문 디코딩
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        // 포인트 업데이트를 위해 getUserPoints 호출 (여러 번 시도)
        await Future.delayed(Duration(milliseconds: 500)); // 서버 업데이트 대기
        await getUserPoints(forceRefresh: true);

        // 추가 재시도 (확실한 업데이트를 위해)
        await Future.delayed(Duration(milliseconds: 500));
        await getUserPoints(forceRefresh: true);

        return responseData;
      } else {
        // 오류 처리
        final errorBody = jsonDecode(response.body);
        final errorMessage = errorBody['message'] ?? '결제 정보 저장에 실패했습니다.';
        throw Exception('결제 정보 저장 실패: $errorMessage');
      }
    } catch (e) {
      print('결제 정보 저장 API 호출 예외: $e');
      throw Exception('결제 처리 중 오류가 발생했습니다: $e');
    }
  }

  // 사용자 포인트 조회 API 호출
  static Future<int> getUserPoints({bool forceRefresh = false}) async {
    if (baseUrl.isEmpty) {
      print('API_BASE_URL가 설정되지 않았습니다.');
      return 0;
    }

    // 액세스 토큰 가져오기 (인증 필요한 API)
    String? accessToken = await AuthService.getAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      print('인증 토큰이 없습니다.');
      return 0;
    }

    try {
      // forceRefresh가 true인 경우 여러 번 시도하여 최신 포인트 정보 확보
      int maxRetries = forceRefresh ? 3 : 1;
      int retryDelay = 500; // 0.5초 간격으로 재시도

      for (int attempt = 0; attempt < maxRetries; attempt++) {
        print('포인트 조회 시도 ${attempt + 1}/$maxRetries');

        // 재시도 시 잠깐 대기 (서버 업데이트 시간 고려)
        if (attempt > 0) {
          await Future.delayed(Duration(milliseconds: retryDelay));
        }

        // 1. 먼저 들어온 포인트 내역 API를 통해 최신 포인트 정보 조회
        print('들어온 포인트 내역에서 포인트 정보 조회 시도...');
        final receivedHistoryUrl = Uri.parse(
          '$baseUrl/api-user/point/transfer/receive/history?pageNumber=0',
        );

        final receivedResponse = await http.get(
          receivedHistoryUrl,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $accessToken',
            'Cache-Control': 'no-cache, no-store, must-revalidate',
            'Pragma': 'no-cache',
            'Expires': '0',
          },
        );

        print('들어온 포인트 내역 API 응답 상태: ${receivedResponse.statusCode}');
        print('들어온 포인트 내역 API 응답 본문: ${receivedResponse.body}');

        if (receivedResponse.statusCode == 200) {
          final receivedData = jsonDecode(receivedResponse.body);
          if (receivedData.containsKey('data') &&
              receivedData['data'] is List &&
              receivedData['data'].isNotEmpty) {
            // 가장 최근 들어온 포인트 내역의 remainingPoint 사용
            final latestReceived = receivedData['data'][0];
            print('최근 들어온 포인트 내역 데이터: $latestReceived');
            if (latestReceived.containsKey('remainingPoint')) {
              final remainingPoint = latestReceived['remainingPoint'] ?? 0;
              print(
                '들어온 포인트 내역에서 가져온 잔여 포인트: $remainingPoint (시도 ${attempt + 1})',
              );
              if (remainingPoint > 0) {
                return remainingPoint;
              }
            }
          }
        }

        // 2. 나간 포인트 내역 API를 통해 최신 포인트 정보 조회
        print('나간 포인트 내역에서 포인트 정보 조회 시도...');
        final sentHistoryUrl = Uri.parse(
          '$baseUrl/api-user/point/transfer/sent/history?pageNumber=0',
        );

        final sentResponse = await http.get(
          sentHistoryUrl,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $accessToken',
            'Cache-Control': 'no-cache, no-store, must-revalidate',
            'Pragma': 'no-cache',
            'Expires': '0',
          },
        );

        print('나간 포인트 내역 API 응답 상태: ${sentResponse.statusCode}');
        print('나간 포인트 내역 API 응답 본문: ${sentResponse.body}');

        if (sentResponse.statusCode == 200) {
          final sentData = jsonDecode(sentResponse.body);
          if (sentData.containsKey('data') &&
              sentData['data'] is List &&
              sentData['data'].isNotEmpty) {
            // 가장 최근 이체 내역의 remainingPoint 사용
            final latestSent = sentData['data'][0];
            print('최근 나간 포인트 내역 데이터: $latestSent');
            if (latestSent.containsKey('remainingPoint')) {
              final remainingPoint = latestSent['remainingPoint'] ?? 0;
              print(
                '나간 포인트 내역에서 가져온 잔여 포인트: $remainingPoint (시도 ${attempt + 1})',
              );
              if (remainingPoint > 0) {
                return remainingPoint;
              }
            }
          }
        }

        // 3. 충전 내역 API를 통해 최신 포인트 정보 조회
        print('충전 내역에서 포인트 정보 조회 시도...');
        final chargeHistoryUrl = Uri.parse(
          '$baseUrl/api-user/point/charge/payment/history?pageNumber=0',
        );

        final chargeResponse = await http.get(
          chargeHistoryUrl,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $accessToken',
            'Cache-Control': 'no-cache, no-store, must-revalidate',
            'Pragma': 'no-cache',
            'Expires': '0',
          },
        );

        print('충전 내역 API 응답 상태: ${chargeResponse.statusCode}');
        print('충전 내역 API 응답 본문: ${chargeResponse.body}');

        if (chargeResponse.statusCode == 200) {
          final chargeData = jsonDecode(chargeResponse.body);
          if (chargeData.containsKey('data') &&
              chargeData['data'] is List &&
              chargeData['data'].isNotEmpty) {
            // 가장 최근 충전 내역의 remainingPoint 사용
            final latestCharge = chargeData['data'][0];
            print('최근 충전 내역 데이터: $latestCharge');
            if (latestCharge.containsKey('remainingPoint')) {
              final remainingPoint = latestCharge['remainingPoint'] ?? 0;
              print('충전 내역에서 가져온 잔여 포인트: $remainingPoint (시도 ${attempt + 1})');
              if (remainingPoint > 0) {
                return remainingPoint;
              }
            }
          }
        }

        // 4. 유저 정보 API 호출
        print('유저 정보 API 호출 시도...');
        final url = Uri.parse('$baseUrl/api-user/me');

        final response = await http.get(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $accessToken',
            'Cache-Control': 'no-cache, no-store, must-revalidate',
            'Pragma': 'no-cache',
            'Expires': '0',
          },
        );

        print('유저 정보 API 응답 상태: ${response.statusCode}');
        print('유저 정보 API 응답 본문: ${response.body}');

        if (response.statusCode == 200) {
          final responseData = jsonDecode(response.body);
          print('유저 정보 전체 데이터: $responseData');

          // 다양한 포인트 필드명 시도
          final List<String> pointFields = [
            'point',
            'points',
            'currentPoint',
            'currentPoints',
            'balance',
            'amount',
            'remainingPoint',
          ];

          for (String field in pointFields) {
            if (responseData.containsKey(field)) {
              final points = responseData[field] ?? 0;
              print('유저 정보에서 $field 필드로 가져온 포인트: $points (시도 ${attempt + 1})');
              if (points is int && points > 0) {
                return points;
              } else if (points is String) {
                final parsedPoints = int.tryParse(points) ?? 0;
                if (parsedPoints > 0) {
                  return parsedPoints;
                }
              }
            }
          }
        }

        // 5. 포인트 전용 API 호출 시도
        print('포인트 전용 API 호출 시도...');
        final pointUrl = Uri.parse('$baseUrl/api-user/point/balance');
        final pointResponse = await http.get(
          pointUrl,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $accessToken',
            'Cache-Control': 'no-cache, no-store, must-revalidate',
            'Pragma': 'no-cache',
            'Expires': '0',
          },
        );

        print('포인트 API 응답 상태: ${pointResponse.statusCode}');
        print('포인트 API 응답 본문: ${pointResponse.body}');

        if (pointResponse.statusCode == 200) {
          final pointData = jsonDecode(pointResponse.body);
          print('포인트 전용 API 전체 데이터: $pointData');

          // 다양한 포인트 필드명 시도
          final List<String> pointFields = [
            'point',
            'points',
            'balance',
            'amount',
            'currentBalance',
            'currentPoint',
          ];

          for (String field in pointFields) {
            if (pointData.containsKey(field)) {
              final points = pointData[field] ?? 0;
              print(
                '포인트 전용 API에서 $field 필드로 가져온 포인트: $points (시도 ${attempt + 1})',
              );
              if (points is int && points > 0) {
                return points;
              } else if (points is String) {
                final parsedPoints = int.tryParse(points) ?? 0;
                if (parsedPoints > 0) {
                  return parsedPoints;
                }
              }
            }
          }
        }

        print('시도 ${attempt + 1} 실패, ${maxRetries - attempt - 1}번 더 시도 가능');
      }

      print('모든 포인트 조회 시도가 실패했습니다. 기본값 0 반환');
      return 0;
    } catch (e) {
      print('포인트 조회 오류: $e');
      return 0;
    }
  }

  // 총 누적 포인트 조회 API 호출 (충전한 포인트 + 받은 포인트)
  static Future<int> getTotalPoints() async {
    try {
      // 액세스 토큰 가져오기
      String? accessToken = await AuthService.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        return 0;
      }

      // 1. 먼저 누적 포인트 API 호출 시도
      final url = Uri.parse('$baseUrl/api-user/point/total');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final totalPoint = responseData['totalPoint'] ?? 0;
        if (totalPoint > 0) {
          print('누적 포인트 API에서 가져온 총 누적 포인트: $totalPoint');
          return totalPoint;
        }
      }

      // 2. API 실패 시 충전한 포인트 + 받은 포인트로 계산
      print('누적 포인트 API 실패, 충전한 포인트 + 받은 포인트로 계산...');
      final totalCharged = await getTotalChargedPoints();
      final totalReceived = await getTotalReceivedPoints();
      final totalAccumulated = totalCharged + totalReceived;

      print(
        '충전한 포인트: $totalCharged, 받은 포인트: $totalReceived, 총 누적 포인트: $totalAccumulated',
      );
      return totalAccumulated;
    } catch (e) {
      print('총 누적 포인트 조회 오류: $e');
      return 0;
    }
  }

  // 충전한 포인트 총합 조회
  static Future<int> getTotalChargedPoints() async {
    try {
      // 액세스 토큰 가져오기
      String? accessToken = await AuthService.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        return 0;
      }

      // 충전 내역 조회 (여러 페이지에 걸쳐 모든 데이터 가져오기)
      int totalCharged = 0;
      int currentPage = 0;
      bool hasMoreData = true;

      while (hasMoreData) {
        try {
          final chargeHistoryUrl = Uri.parse(
            '$baseUrl/api-user/point/charge/payment/history?pageNumber=$currentPage',
          );

          print('충전 내역 API 호출: $chargeHistoryUrl');

          final chargeResponse = await http.get(
            chargeHistoryUrl,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $accessToken',
            },
          );

          print('충전 내역 API 응답 상태: ${chargeResponse.statusCode}');
          print('충전 내역 API 응답 본문: ${chargeResponse.body}');

          if (chargeResponse.statusCode == 200) {
            final chargeData = jsonDecode(chargeResponse.body);

            if (chargeData.containsKey('data') && chargeData['data'] is List) {
              final List<dynamic> chargeList = chargeData['data'];

              if (chargeList.isEmpty) {
                hasMoreData = false;
                break;
              }

              // 각 충전 내역의 chargePoint를 누적 (pointAmount 대신 chargePoint 사용)
              for (final charge in chargeList) {
                if (charge.containsKey('chargePoint')) {
                  final chargePoint = charge['chargePoint'] ?? 0;
                  totalCharged += chargePoint as int;
                  print('충전 내역 추가: ${chargePoint}원, 누적: ${totalCharged}원');
                }
              }

              // 다음 페이지가 있는지 확인
              final totalPage = chargeData['totalPage'] ?? 1;
              if (currentPage >= totalPage - 1) {
                hasMoreData = false;
              } else {
                currentPage++;
              }
            } else {
              hasMoreData = false;
            }
          } else {
            print('충전 내역 API 호출 실패: ${chargeResponse.statusCode}');
            hasMoreData = false;
          }
        } catch (e) {
          print('충전 내역 조회 중 오류 (페이지 $currentPage): $e');
          hasMoreData = false;
        }
      }

      print('충전한 포인트 총합: $totalCharged');
      return totalCharged;
    } catch (e) {
      print('충전한 포인트 조회 오류: $e');
      return 0;
    }
  }

  // 받은 포인트 총합 조회 (실제 다른 사람에게서 받은 포인트만)
  static Future<int> getTotalReceivedPoints() async {
    try {
      // 액세스 토큰 가져오기
      String? accessToken = await AuthService.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        return 0;
      }

      // 받은 포인트 내역 조회 (여러 페이지에 걸쳐 모든 데이터 가져오기)
      int totalReceived = 0;
      int currentPage = 0;
      bool hasMoreData = true;

      while (hasMoreData) {
        try {
          final receivedHistoryUrl = Uri.parse(
            '$baseUrl/api-user/point/transfer/receive/history?pageNumber=$currentPage',
          );

          final receivedResponse = await http.get(
            receivedHistoryUrl,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $accessToken',
            },
          );

          if (receivedResponse.statusCode == 200) {
            final receivedData = jsonDecode(receivedResponse.body);
            print(
              '받은 포인트 내역 API 응답 (페이지 $currentPage): ${receivedResponse.body}',
            );

            if (receivedData.containsKey('data') &&
                receivedData['data'] is List) {
              final List<dynamic> receivedList = receivedData['data'];

              if (receivedList.isEmpty) {
                hasMoreData = false;
                break;
              }

              // 각 받은 포인트 내역 중 실제 받은 것만 누적 (충전 제외)
              for (final received in receivedList) {
                if (received.containsKey('pointAmount') &&
                    received.containsKey('type')) {
                  final type = received['type'] ?? '';
                  final senderName = received['senderName'] ?? '';

                  // PAYMENT 타입이거나 senderName이 kakaopay인 경우는 충전이므로 제외
                  if (type != 'PAYMENT' && senderName != 'kakaopay') {
                    final pointAmount = received['pointAmount'] ?? 0;
                    totalReceived += pointAmount as int;
                  }
                }
              }

              // 다음 페이지가 있는지 확인
              final totalPage = receivedData['totalPage'] ?? 1;
              if (currentPage >= totalPage - 1) {
                hasMoreData = false;
              } else {
                currentPage++;
              }
            } else {
              hasMoreData = false;
            }
          } else {
            hasMoreData = false;
          }
        } catch (e) {
          print('받은 포인트 내역 조회 중 오류 (페이지 $currentPage): $e');
          hasMoreData = false;
        }
      }

      print('받은 포인트 총합 (충전 제외): $totalReceived');
      return totalReceived;
    } catch (e) {
      print('받은 포인트 조회 오류: $e');
      return 0;
    }
  }

  // 충전한 포인트와 받은 포인트 정보를 함께 반환
  static Future<Map<String, int>> getTotalPointsBreakdown() async {
    try {
      final totalCharged = await getTotalChargedPoints();
      final totalReceived = await getTotalReceivedPoints();
      final totalAccumulated = totalCharged + totalReceived;

      return {
        'totalCharged': totalCharged,
        'totalReceived': totalReceived,
        'totalAccumulated': totalAccumulated,
      };
    } catch (e) {
      print('포인트 분석 데이터 조회 오류: $e');
      return {'totalCharged': 0, 'totalReceived': 0, 'totalAccumulated': 0};
    }
  }

  // 포인트 충전 내역 조회 API 호출
  static Future<Map<String, dynamic>> getChargeHistory({
    int pageNumber = 0,
    String? startDate,
    String? endDate,
  }) async {
    if (baseUrl.isEmpty) {
      throw Exception('API_BASE_URL가 설정되지 않았습니다. .env 파일을 확인하세요.');
    }

    // 액세스 토큰 가져오기 (인증 필요한 API)
    String? accessToken = await AuthService.getAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('인증이 필요합니다. 로그인 후 다시 시도해주세요.');
    }

    try {
      // URL 파라미터 구성
      final queryParams = {
        'pageNumber': pageNumber.toString(),
        if (startDate != null) 'startDate': startDate,
        if (endDate != null) 'endDate': endDate,
      };

      // 충전 내역 API 호출
      final url = Uri.parse(
        '$baseUrl/api-user/point/charge/payment/history',
      ).replace(queryParameters: queryParams);

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      print('충전 내역 API 응답 상태: ${response.statusCode}');
      print('충전 내역 API 응답 본문: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return responseData;
      } else {
        // 오류 처리
        final errorBody = jsonDecode(response.body);
        final errorMessage = errorBody['message'] ?? '충전 내역 조회에 실패했습니다.';
        throw Exception('충전 내역 조회 실패: $errorMessage');
      }
    } catch (e) {
      print('충전 내역 조회 오류: $e');
      throw Exception('충전 내역 조회 중 오류가 발생했습니다: $e');
    }
  }

  // 일반 포인트 보내기 API 호출 (기존 transferPoints에서 명칭 변경)
  static Future<Map<String, dynamic>> transferPointsGeneral({
    required int receiverId,
    required int pointAmount,
    String? message,
  }) async {
    if (baseUrl.isEmpty) {
      throw Exception('API_BASE_URL가 설정되지 않았습니다. .env 파일을 확인하세요.');
    }

    String? accessToken = await AuthService.getAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('인증이 필요합니다. 로그인 후 다시 시도해주세요.');
    }

    final url = Uri.parse('$baseUrl/api-user/point/transfer/general');
    // message가 null이면 반드시 공백으로 전송
    final Map<String, dynamic> body = {
      'receiverId': receiverId,
      'pointAmount': pointAmount,
      'message': message ?? '',
    };

    print('일반 포인트 보내기 API 요청: $body');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(body),
      );

      print('일반 포인트 보내기 API 응답 상태: [32m[1m[4m${response.statusCode}[0m');
      print('일반 포인트 보내기 API 응답 본문: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        // responseData에는 isRewarded(boolean)가 반드시 포함됨
        // 예시: {historyId, pointAmount, message, remainingPoint, receiverId, rewardType, rewardId, isRewarded}
        await Future.delayed(Duration(milliseconds: 500));
        await getUserPoints(forceRefresh: true);
        await Future.delayed(Duration(milliseconds: 500));
        await getUserPoints(forceRefresh: true);

        return responseData;
      } else {
        final errorBody = jsonDecode(response.body);
        final errorMessage = errorBody['message'] ?? '일반 포인트 보내기에 실패했습니다.';

        if (response.statusCode == 400) {
          if (errorMessage.contains('포인트') ||
              errorMessage.contains('잔액') ||
              errorMessage.contains('부족')) {
            throw Exception('보유 포인트가 부족합니다.');
          }
        }

        throw Exception('일반 포인트 보내기 실패: $errorMessage');
      }
    } catch (e) {
      print('일반 포인트 보내기 API 호출 예외: $e');

      if (e is Exception) {
        rethrow;
      }

      throw Exception('일반 포인트 보내기 중 오류가 발생했습니다: $e');
    }
  }

  // 미션 보상 포인트 보내기 API 호출
  static Future<Map<String, dynamic>> transferPointsMission({
    required int receiverId,
    required int pointAmount,
    String? message,
    required int missionId, // API 스펙에 따라 missionId 사용
    bool isRefused = false, // 부모단에서 거절하기 버튼 클릭 유무 추가
  }) async {
    if (baseUrl.isEmpty) {
      throw Exception('API_BASE_URL가 설정되지 않았습니다. .env 파일을 확인하세요.');
    }

    String? accessToken = await AuthService.getAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('인증이 필요합니다. 로그인 후 다시 시도해주세요.');
    }

    final url = Uri.parse('$baseUrl/api-user/point/transfer/mission');
    // message가 null이면 반드시 공백으로 전송
    final Map<String, dynamic> body = {
      'receiverId': receiverId,
      'pointAmount': pointAmount,
      'message': message ?? '',
      'missionId': missionId, // API 스펙에 맞게 missionId로 전송
      'isRefused': isRefused, // 거절 여부 추가
    };

    print('미션 보상 포인트 보내기 API 요청: $body');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(body),
      );

      print('미션 보상 포인트 보내기 API 응답 상태: ${response.statusCode}');
      print('미션 보상 포인트 보상기 API 응답 본문: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        // responseData에는 isRewarded(boolean)가 반드시 포함됨
        // 예시: {historyId, pointAmount, message, remainingPoint, receiverId, rewardType, rewardId, isRewarded}
        await Future.delayed(Duration(milliseconds: 500));
        await getUserPoints(forceRefresh: true);
        await Future.delayed(Duration(milliseconds: 500));
        await getUserPoints(forceRefresh: true);

        return responseData;
      } else {
        final errorBody = jsonDecode(response.body);
        final errorMessage = errorBody['message'] ?? '미션 보상 포인트 보내기에 실패했습니다.';

        if (response.statusCode == 400) {
          if (errorMessage.contains('포인트') ||
              errorMessage.contains('잔액') ||
              errorMessage.contains('부족')) {
            throw Exception('보유 포인트가 부족합니다.');
          }
        }

        throw Exception('미션 보상 포인트 보내기 실패: $errorMessage');
      }
    } catch (e) {
      print('미션 보상 포인트 보내기 API 호출 예외: $e');

      if (e is Exception) {
        rethrow;
      }

      throw Exception('미션 보상 포인트 보내기 중 오류가 발생했습니다: $e');
    }
  }

  // 챌린지 보상 포인트 보내기 API 호출
  static Future<Map<String, dynamic>> transferPointsChallenge({
    required int receiverId,
    required int pointAmount,
    String? message,
    required int participationId, // API 스펙에 따라 participationId 사용
    bool isRefused = false, // 부모단에서 거절하기 버튼 클릭 유무 추가
  }) async {
    if (baseUrl.isEmpty) {
      throw Exception('API_BASE_URL가 설정되지 않았습니다. .env 파일을 확인하세요.');
    }

    String? accessToken = await AuthService.getAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('인증이 필요합니다. 로그인 후 다시 시도해주세요.');
    }

    final url = Uri.parse('$baseUrl/api-user/point/transfer/challenge');
    // message가 null이면 반드시 공백으로 전송
    final Map<String, dynamic> body = {
      'receiverId': receiverId,
      'pointAmount': pointAmount,
      'message': message ?? '',
      'participationId': participationId, // API 스펙에 맞게 participationId로 전송
      'isRefused': isRefused, // 거절 여부 추가
    };

    print('챌린지 보상 포인트 보내기 API 요청: $body');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(body),
      );

      print('챌린지 보상 포인트 보내기 API 응답 상태: ${response.statusCode}');
      print('챌린지 보상 포인트 보내기 API 응답 본문: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        // responseData에는 isRewarded(boolean)가 반드시 포함됨
        // 예시: {historyId, pointAmount, message, remainingPoint, receiverId, rewardType, rewardId, isRewarded}
        await Future.delayed(Duration(milliseconds: 500));
        await getUserPoints(forceRefresh: true);
        await Future.delayed(Duration(milliseconds: 500));
        await getUserPoints(forceRefresh: true);

        return responseData;
      } else {
        final errorBody = jsonDecode(response.body);
        final errorMessage = errorBody['message'] ?? '챌린지 보상 포인트 보내기에 실패했습니다.';

        if (response.statusCode == 400) {
          if (errorMessage.contains('포인트') ||
              errorMessage.contains('잔액') ||
              errorMessage.contains('부족')) {
            throw Exception('보유 포인트가 부족합니다.');
          }
        }

        throw Exception('챌린지 보상 포인트 보내기 실패: $errorMessage');
      }
    } catch (e) {
      print('챌린지 보상 포인트 보내기 API 호출 예외: $e');

      if (e is Exception) {
        rethrow;
      }

      throw Exception('챌린지 보상 포인트 보내기 중 오류가 발생했습니다: $e');
    }
  }

  // 목표 보상 포인트 보내기 API 호출
  static Future<Map<String, dynamic>> transferPointsGoal({
    required int receiverId,
    required int pointAmount,
    String? message,
    required int goalId,
  }) async {
    if (baseUrl.isEmpty) {
      throw Exception('API_BASE_URL가 설정되지 않았습니다. .env 파일을 확인하세요.');
    }

    String? accessToken = await AuthService.getAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('인증이 필요합니다. 로그인 후 다시 시도해주세요.');
    }

    final url = Uri.parse('$baseUrl/api-user/point/transfer/goal');
    // message가 null이면 반드시 공백으로 전송
    final Map<String, dynamic> body = {
      'receiverId': receiverId,
      'pointAmount': pointAmount,
      'message': message ?? '',
      'goalId': goalId,
    };

    print('목표 보상 포인트 보내기 API 요청: $body');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(body),
      );

      print('목표 보상 포인트 보내기 API 응답 상태: ${response.statusCode}');
      print('목표 보상 포인트 보내기 API 응답 본문: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        // responseData에는 isRewarded(boolean)가 반드시 포함됨
        // 예시: {historyId, pointAmount, message, remainingPoint, receiverId, rewardType, rewardId, isRewarded}
        await Future.delayed(Duration(milliseconds: 500));
        await getUserPoints(forceRefresh: true);
        await Future.delayed(Duration(milliseconds: 500));
        await getUserPoints(forceRefresh: true);

        return responseData;
      } else {
        final errorBody = jsonDecode(response.body);
        final errorMessage = errorBody['message'] ?? '목표 보상 포인트 보내기에 실패했습니다.';

        if (response.statusCode == 400) {
          if (errorMessage.contains('포인트') ||
              errorMessage.contains('잔액') ||
              errorMessage.contains('부족')) {
            throw Exception('보유 포인트가 부족합니다.');
          }
        }

        throw Exception('목표 보상 포인트 보내기 실패: $errorMessage');
      }
    } catch (e) {
      print('목표 보상 포인트 보내기 API 호출 예외: $e');

      if (e is Exception) {
        rethrow;
      }

      throw Exception('목표 보상 포인트 보내기 중 오류가 발생했습니다: $e');
    }
  }

  // 보낸 포인트 내역 조회 API 호출
  static Future<Map<String, dynamic>> getSentPointHistory({
    int pageNumber = 0,
    String? startDate,
    String? endDate,
  }) async {
    if (baseUrl.isEmpty) {
      throw Exception('API_BASE_URL가 설정되지 않았습니다. .env 파일을 확인하세요.');
    }

    // 액세스 토큰 가져오기 (인증 필요한 API)
    String? accessToken = await AuthService.getAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('인증이 필요합니다. 로그인 후 다시 시도해주세요.');
    }

    try {
      // URL 파라미터 구성
      final queryParams = {
        'pageNumber': pageNumber.toString(),
        if (startDate != null) 'startDate': startDate,
        if (endDate != null) 'endDate': endDate,
      };

      // 보낸 포인트 내역 API 호출
      final url = Uri.parse(
        '$baseUrl/api-user/point/transfer/sent/history',
      ).replace(queryParameters: queryParams);

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      print('보낸 포인트 내역 API 응답 상태: ${response.statusCode}');
      print('보낸 포인트 내역 API 응답 본문: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return responseData;
      } else {
        // 오류 처리
        final errorBody = jsonDecode(response.body);
        final errorMessage = errorBody['message'] ?? '보낸 포인트 내역 조회에 실패했습니다.';
        throw Exception('보낸 포인트 내역 조회 실패: $errorMessage');
      }
    } catch (e) {
      print('보낸 포인트 내역 조회 오류: $e');
      throw Exception('보낸 포인트 내역 조회 중 오류가 발생했습니다: $e');
    }
  }

  // 최근 포인트를 보낸 계좌 조회 API 호출
  static Future<Map<String, dynamic>> getLatestTransferAccounts({
    int pageNumber = 0,
  }) async {
    if (baseUrl.isEmpty) {
      throw Exception('API_BASE_URL가 설정되지 않았습니다. .env 파일을 확인하세요.');
    }

    // 액세스 토큰 가져오기 (인증 필요한 API)
    String? accessToken = await AuthService.getAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('인증이 필요합니다. 로그인 후 다시 시도해주세요.');
    }

    try {
      // 최근 포인트를 보낸 계좌 조회 API 호출
      final url = Uri.parse(
        '$baseUrl/api-user/point/transfer/latest/account?pageNumber=$pageNumber',
      );

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      print('최근 포인트를 보낸 계좌 API 응답 상태: ${response.statusCode}');
      print('최근 포인트를 보낸 계좌 API 응답 본문: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return responseData;
      } else {
        // 오류 처리
        final errorBody = jsonDecode(response.body);
        final errorMessage = errorBody['message'] ?? '최근 계좌 조회에 실패했습니다.';
        throw Exception('최근 계좌 조회 실패: $errorMessage');
      }
    } catch (e) {
      print('최근 계좌 조회 오류: $e');
      throw Exception('최근 계좌 조회 중 오류가 발생했습니다: $e');
    }
  }

  // 아이용 포인트 꺼내기 API 호출
  static Future<Map<String, dynamic>> refundPointsChild({
    required int depositTargetUserId,
    required int exchangeAmount,
  }) async {
    if (baseUrl.isEmpty) {
      throw Exception('API_BASE_URL가 설정되지 않았습니다. .env 파일을 확인하세요.');
    }

    // 액세스 토큰 가져오기 (인증 필요한 API)
    String? accessToken = await AuthService.getAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('인증이 필요합니다. 로그인 후 다시 시도해주세요.');
    }

    final url = Uri.parse('$baseUrl/api-user/point/child/refund');

    // 요청 바디 생성
    final Map<String, dynamic> body = {
      'depositTargetUserId': depositTargetUserId,
      'exchangeAmount': exchangeAmount,
    };

    print('아이용 포인트 꺼내기 API 요청: $body');

    try {
      // POST 요청 보내기
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(body),
      );

      print('아이용 포인트 꺼내기 API 응답 상태: ${response.statusCode}');
      print('아이용 포인트 꺼내기 API 응답 본문: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        // 응답 본문 디코딩
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        // 포인트 업데이트를 위해 getUserPoints 호출 (여러 번 시도)
        await Future.delayed(Duration(milliseconds: 500)); // 서버 업데이트 대기
        await getUserPoints(forceRefresh: true);

        // 추가 재시도 (확실한 업데이트를 위해)
        await Future.delayed(Duration(milliseconds: 500));
        await getUserPoints(forceRefresh: true);

        return responseData;
      } else {
        // 오류 처리
        final errorBody = jsonDecode(response.body);
        final errorMessage = errorBody['message'] ?? '포인트 꺼내기에 실패했습니다.';

        // 잔여 포인트 부족 등의 특정 오류 메시지 처리
        if (response.statusCode == 400) {
          if (errorMessage.contains('포인트') ||
              errorMessage.contains('잔액') ||
              errorMessage.contains('부족')) {
            throw Exception('보유 포인트가 부족합니다.');
          }
        }

        throw Exception('아이용 포인트 꺼내기 실패: $errorMessage');
      }
    } catch (e) {
      print('아이용 포인트 꺼내기 API 호출 예외: $e');

      // 이미 Exception인 경우 그대로 재던지기
      if (e is Exception) {
        rethrow;
      }

      throw Exception('아이용 포인트 꺼내기 중 오류가 발생했습니다: $e');
    }
  }

  // 부모용 포인트 꺼내기 API 호출
  static Future<Map<String, dynamic>> refundPointsParent({
    required int exchangeAmount,
    required int depositTargetUserId,
  }) async {
    if (baseUrl.isEmpty) {
      throw Exception('API_BASE_URL가 설정되지 않았습니다. .env 파일을 확인하세요.');
    }

    // 액세스 토큰 가져오기 (인증 필요한 API)
    String? accessToken = await AuthService.getAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('인증이 필요합니다. 로그인 후 다시 시도해주세요.');
    }

    final url = Uri.parse('$baseUrl/api-user/point/parent/refund');

    // 요청 바디 생성
    final Map<String, dynamic> body = {
      'exchangeAmount': exchangeAmount,
      'depositTargetUserId': depositTargetUserId,
    };

    print('부모용 포인트 꺼내기 API 요청: $body');

    try {
      // POST 요청 보내기
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(body),
      );

      print('부모용 포인트 꺼내기 API 응답 상태: ${response.statusCode}');
      print('부모용 포인트 꺼내기 API 응답 본문: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        // 응답 본문 디코딩
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        // 포인트 업데이트는 클라이언트에서 처리하므로 여기서는 제거

        return responseData;
      } else {
        // 오류 처리
        final errorBody = jsonDecode(response.body);
        final errorMessage = errorBody['message'] ?? '포인트 꺼내기에 실패했습니다.';

        // 잔여 포인트 부족 등의 특정 오류 메시지 처리
        if (response.statusCode == 400) {
          if (errorMessage.contains('포인트') ||
              errorMessage.contains('잔액') ||
              errorMessage.contains('부족')) {
            throw Exception('보유 포인트가 부족합니다.');
          }
        }

        throw Exception('부모용 포인트 꺼내기 실패: $errorMessage');
      }
    } catch (e) {
      print('부모용 포인트 꺼내기 API 호출 예외: $e');

      // 이미 Exception인 경우 그대로 재던지기
      if (e is Exception) {
        rethrow;
      }

      throw Exception('부모용 포인트 꺼내기 중 오류가 발생했습니다: $e');
    }
  }

  // 들어온 포인트 내역 조회 API 호출
  static Future<Map<String, dynamic>> getReceivedPointHistory({
    int pageNumber = 0,
    String? startDate,
    String? endDate,
  }) async {
    if (baseUrl.isEmpty) {
      throw Exception('API_BASE_URL가 설정되지 않았습니다. .env 파일을 확인하세요.');
    }

    // 액세스 토큰 가져오기 (인증 필요한 API)
    String? accessToken = await AuthService.getAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('인증이 필요합니다. 로그인 후 다시 시도해주세요.');
    }

    try {
      // 들어온 포인트 내역 API 호출 (날짜 필터 추가)
      Map<String, String> queryParams = {'pageNumber': pageNumber.toString()};

      // 날짜 필터가 있는 경우 추가
      if (startDate != null) {
        queryParams['startDate'] = startDate;
      }
      if (endDate != null) {
        queryParams['endDate'] = endDate;
      }

      final url = Uri.parse(
        '$baseUrl/api-user/point/transfer/receive/history',
      ).replace(queryParameters: queryParams);

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      print('들어온 포인트 내역 API 응답 상태: ${response.statusCode}');
      print('들어온 포인트 내역 API 응답 본문: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return responseData;
      } else {
        // 오류 처리
        final errorBody = jsonDecode(response.body);
        final errorMessage = errorBody['message'] ?? '들어온 포인트 내역 조회에 실패했습니다.';
        throw Exception('들어온 포인트 내역 조회 실패: $errorMessage');
      }
    } catch (e) {
      print('들어온 포인트 내역 조회 오류: $e');
      throw Exception('들어온 포인트 내역 조회 중 오류가 발생했습니다: $e');
    }
  }

  // 꺼낸 포인트 내역 조회 API 호출
  static Future<Map<String, dynamic>> getRefundHistory({
    int pageNumber = 0,
    String? startDate,
    String? endDate,
  }) async {
    if (baseUrl.isEmpty) {
      throw Exception('API_BASE_URL가 설정되지 않았습니다. .env 파일을 확인하세요.');
    }

    // 액세스 토큰 가져오기 (인증 필요한 API)
    String? accessToken = await AuthService.getAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('인증이 필요합니다. 로그인 후 다시 시도해주세요.');
    }

    try {
      // URL 파라미터 구성
      final queryParams = {
        'pageNumber': pageNumber.toString(),
        if (startDate != null) 'startDate': startDate,
        if (endDate != null) 'endDate': endDate,
      };

      // 꺼낸 포인트 내역 API 호출
      final url = Uri.parse(
        '$baseUrl/api-user/point/refund/history',
      ).replace(queryParameters: queryParams);

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      print('꺼낸 포인트 내역 API 응답 상태: ${response.statusCode}');
      print('꺼낸 포인트 내역 API 응답 본문: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return responseData;
      } else {
        // 오류 처리
        final errorBody = jsonDecode(response.body);
        final errorMessage = errorBody['message'] ?? '꺼낸 포인트 내역 조회에 실패했습니다.';
        throw Exception('꺼낸 포인트 내역 조회 실패: $errorMessage');
      }
    } catch (e) {
      print('꺼낸 포인트 내역 조회 오류: $e');
      throw Exception('꺼낸 포인트 내역 조회 중 오류가 발생했습니다: $e');
    }
  }

  // 최근 포인트를 꺼낸 대상 조회 API 호출 (새로운 전용 API 사용)
  static Future<List<Map<String, dynamic>>> getLatestRefundTargets() async {
    if (baseUrl.isEmpty) {
      throw Exception('API_BASE_URL가 설정되지 않았습니다. .env 파일을 확인하세요.');
    }

    // 액세스 토큰 가져오기 (인증 필요한 API)
    String? accessToken = await AuthService.getAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('인증이 필요합니다. 로그인 후 다시 시도해주세요.');
    }

    try {
      // 새로운 최근 포인트를 꺼낸 대상 조회 API 사용
      final url = Uri.parse(
        '$baseUrl/api-user/point/refund/latest/deposit-target',
      );

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
          'Cache-Control': 'no-cache, no-store, must-revalidate',
          'Pragma': 'no-cache',
          'Expires': '0',
        },
      );

      print('최근 포인트를 꺼낸 대상 조회 API 응답 상태: ${response.statusCode}');
      print('최근 포인트를 꺼낸 대상 조회 API 응답 본문: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData is List) {
          List<Map<String, dynamic>> targets = [];

          for (var item in responseData) {
            if (item is Map<String, dynamic>) {
              final target = {
                'refundId': item['refundId'],
                'userId': item['userId'],
                'userName': item['userName'],
                'bankName': item['bankName'] ?? '',
                'bankAccount': item['bankAccount'] ?? '',
                'requestedDate': item['requestedDate'],
              };

              // 각 대상의 프로필 이미지 정보 추가
              try {
                final userProfile = await getUserProfile(target['userId']);
                if (userProfile != null &&
                    userProfile['profileImagePath'] != null) {
                  target['profileImagePath'] = userProfile['profileImagePath'];
                  target['profileImageUrl'] =
                      AuthService.getFullProfileImageUrl(
                        userProfile['profileImagePath'],
                      );
                }
              } catch (e) {
                print('사용자 프로필 조회 실패 (${target['userId']}): $e');
              }

              targets.add(target);
            }
          }

          print('최근 포인트를 꺼낸 대상 조회 성공: $targets');
          return targets;
        } else {
          print('예상하지 못한 응답 형태: $responseData');
          return [];
        }
      } else {
        // 오류 처리
        final errorBody = jsonDecode(response.body);
        final errorMessage =
            errorBody['message'] ?? '최근 포인트를 꺼낸 대상 조회에 실패했습니다.';
        throw Exception('최근 포인트를 꺼낸 대상 조회 실패: $errorMessage');
      }
    } catch (e) {
      print('최근 포인트를 꺼낸 대상 조회 오류: $e');
      return []; // 실패 시 빈 리스트 반환
    }
  }

  // 사용자 프로필 정보 조회 API (userId 기반)
  static Future<Map<String, dynamic>?> getUserProfile(int userId) async {
    if (baseUrl.isEmpty) {
      throw Exception('API_BASE_URL가 설정되지 않았습니다. .env 파일을 확인하세요.');
    }

    String? accessToken = await AuthService.getAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('인증이 필요합니다. 로그인 후 다시 시도해주세요.');
    }

    try {
      // 여러 가능한 사용자 프로필 API 엔드포인트 시도
      final possibleUrls = [
        '$baseUrl/api-user/user/$userId',
        '$baseUrl/api-user/users/$userId',
        '$baseUrl/api-user/profile/$userId',
        '$baseUrl/api-user/member/$userId',
      ];

      for (String urlString in possibleUrls) {
        try {
          final url = Uri.parse(urlString);

          final response = await http.get(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $accessToken',
            },
          );

          print('사용자 프로필 조회 API ($urlString) 응답 상태: ${response.statusCode}');

          if (response.statusCode == 200) {
            final responseData = jsonDecode(response.body);
            print('사용자 프로필 조회 성공 ($userId): $responseData');
            return Map<String, dynamic>.from(responseData);
          }
        } catch (e) {
          print('사용자 프로필 조회 시도 실패 ($urlString): $e');
          continue;
        }
      }

      print('모든 사용자 프로필 조회 API 시도 실패 ($userId)');
      return null;
    } catch (e) {
      print('사용자 프로필 조회 API 호출 오류 ($userId): $e');
      return null;
    }
  }
}
