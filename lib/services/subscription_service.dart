import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'auth_service.dart';

class SubscriptionService {
  static const String baseUrl = 'http://3.34.52.239:8080';

  // ========== 현재 구현된 API들 ==========

  // 구독권 생성 (대표자)
  static Future<Map<String, dynamic>?> createSubscription(int seat) async {
    try {
      print('===== 구독권 생성 API 호출 시작 =====');
      print('구독권 좌석 수: $seat');

      final authToken = await AuthService.getAccessToken();
      if (authToken == null) {
        print('인증 토큰이 없습니다.');
        return null;
      }

      final url = Uri.parse('$baseUrl/api-user/subscription/create');
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
      };

      final body = jsonEncode({'seat': seat});

      print('API URL: $url');
      print('Headers: $headers');
      print('Body: $body');

      final response = await http.post(url, headers: headers, body: body);

      print('응답 상태 코드: ${response.statusCode}');
      print('응답 본문: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        print('구독권 생성 성공: $responseData');
        return responseData;
      } else {
        print('구독권 생성 실패: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('구독권 생성 중 오류 발생: $e');
      return null;
    }
  }

  // 구독권 생성 (새로운 API 스펙) - purchaseToken 포함
  static Future<Map<String, dynamic>?> createSubscriptionWithPurchase({
    required int seat,
    required String purchaseToken,
    bool includeOwner = true,
  }) async {
    try {
      print('===== 구독권 생성 API 호출 시작 (purchaseToken 포함) =====');
      print('구독권 좌석 수: $seat');
      print('purchaseToken: $purchaseToken');
      print('includeOwner: $includeOwner');

      final authToken = await AuthService.getAccessToken();
      if (authToken == null) {
        print('❌ 인증 토큰이 없습니다.');
        return null;
      }

      final url = Uri.parse('$baseUrl/api-user/subscription/create');
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
      };

      final now = DateTime.now();
      final endDate = now.add(Duration(days: 30)); // 1개월 후

      final body = jsonEncode({
        'seat': seat,
        'includeOwner': includeOwner,
        'startDate': now.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'purchaseToken': purchaseToken,
      });

      print('📡 API URL: $url');
      print('📡 Headers: $headers');
      print('📡 Body: $body');

      final response = await http.post(url, headers: headers, body: body);

      print('📡 응답 상태 코드: ${response.statusCode}');
      print('📡 응답 본문: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        print('✅ 구독권 생성 성공: $responseData');
        return responseData;
      } else {
        print('❌ 구독권 생성 실패: ${response.statusCode}');

        // 에러 메시지 반환
        try {
          final errorData = jsonDecode(response.body) as Map<String, dynamic>;
          return {
            'error': true,
            'message': errorData['message'] ?? '구독권 생성에 실패했습니다.',
            'statusCode': response.statusCode,
          };
        } catch (e) {
          return {
            'error': true,
            'message': '구독권 생성에 실패했습니다.',
            'statusCode': response.statusCode,
          };
        }
      }
    } catch (e) {
      print('❌ 구독권 생성 중 오류 발생: $e');
      return {'error': true, 'message': '네트워크 오류가 발생했습니다.'};
    }
  }

  // 나의 구독 정보 조회 (현재 + 과거)
  static Future<List<Map<String, dynamic>>?> getMySubscriptions() async {
    try {
      print('===== 나의 구독 정보 조회 API 호출 시작 =====');

      final authToken = await AuthService.getAccessToken();
      if (authToken == null) {
        print('인증 토큰이 없습니다.');
        return null;
      }

      final url = Uri.parse('$baseUrl/api-user/subscription/my');
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
      };

      print('API URL: $url');
      print('Headers: $headers');

      final response = await http.get(url, headers: headers);

      print('응답 상태 코드: ${response.statusCode}');
      print('응답 본문: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as List<dynamic>;
        final subscriptions =
            responseData
                .map((item) => Map<String, dynamic>.from(item))
                .toList();
        print('구독권 정보 조회 성공: $subscriptions');
        return subscriptions;
      } else {
        print('구독권 정보 조회 실패: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('구독권 정보 조회 중 오류 발생: $e');
      return null;
    }
  }

  // 현재 활성 구독권 조회
  static Future<Map<String, dynamic>?> getCurrentSubscription() async {
    try {
      final subscriptions = await getMySubscriptions();
      if (subscriptions == null || subscriptions.isEmpty) {
        return null;
      }

      final now = DateTime.now();

      // 현재 시간이 구독 기간 내에 있는 구독권 찾기
      for (final subscription in subscriptions) {
        final endDateStr = subscription['endDate'] as String?;
        if (endDateStr != null) {
          final endDate = DateTime.parse(endDateStr);
          if (endDate.isAfter(now)) {
            print('현재 활성 구독권 발견: $subscription');
            return subscription;
          }
        }
      }

      print('현재 활성 구독권이 없습니다.');
      return null;
    } catch (e) {
      print('현재 활성 구독권 조회 중 오류 발생: $e');
      return null;
    }
  }

  // 구독권 삭제
  static Future<bool> deleteSubscription() async {
    try {
      print('===== 구독권 삭제 API 호출 시작 =====');

      final authToken = await AuthService.getAccessToken();
      if (authToken == null) {
        print('인증 토큰이 없습니다.');
        return false;
      }

      final url = Uri.parse('$baseUrl/api-user/subscription/delete');
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
      };

      print('API URL: $url');
      print('Headers: $headers');

      final response = await http.delete(url, headers: headers);

      print('응답 상태 코드: ${response.statusCode}');
      print('응답 본문: ${response.body}');

      if (response.statusCode == 200) {
        print('구독권 삭제 성공');
        return true;
      } else {
        print('구독권 삭제 실패: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('구독권 삭제 중 오류 발생: $e');
      return false;
    }
  }

  // 쿠폰코드로 구독권 참여
  static Future<Map<String, dynamic>?> redeemInviteCode(
    String inviteCode,
  ) async {
    try {
      print('===== 쿠폰코드 구독 등록 API 호출 시작 =====');
      print('쿠폰코드: $inviteCode');

      final authToken = await AuthService.getAccessToken();
      if (authToken == null) {
        print('인증 토큰이 없습니다.');
        return null;
      }

      // query parameter로 code 전송
      final url = Uri.parse(
        '$baseUrl/api-user/subscription/redeem?code=$inviteCode',
      );
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
      };

      print('API URL: $url');
      print('Headers: $headers');

      final response = await http.post(
        url,
        headers: headers,
        // body 제거 - query parameter로 전송
      );

      print('응답 상태 코드: ${response.statusCode}');
      print('응답 본문: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        print('쿠폰코드 구독 등록 성공: $responseData');
        return responseData;
      } else {
        print('쿠폰코드 구독 등록 실패: ${response.statusCode}');

        // 에러 메시지 반환
        try {
          final errorData = jsonDecode(response.body) as Map<String, dynamic>;
          return {
            'error': true,
            'message': errorData['message'] ?? '구독 등록에 실패했습니다.',
            'statusCode': response.statusCode,
          };
        } catch (e) {
          return {
            'error': true,
            'message': '구독 등록에 실패했습니다.',
            'statusCode': response.statusCode,
          };
        }
      }
    } catch (e) {
      print('쿠폰코드 구독 등록 중 오류 발생: $e');
      return {'error': true, 'message': '네트워크 오류가 발생했습니다.'};
    }
  }

  // 구독권 쿠폰코드 조회 (카톡 공유용) - 일반 구독권 + 무료 구독권 통합
  static Future<Map<String, dynamic>?> getInviteCodes() async {
    try {
      print('===== 구독권 쿠폰코드 조회 API 호출 시작 =====');

      // 먼저 일반 구독권 확인
      print('🔍 일반 구독권 조회 시작...');
      final currentSub = await getCurrentSubscription();
      print('🔍 일반 구독권 조회 결과: $currentSub');
      
      if (currentSub != null) {
        print('✅ 일반 구독권 발견: $currentSub');
        
        // 구독권 정보에서 쿠폰코드 추출
        final inviteCodes = currentSub['inviteCodes'] as Map<String, dynamic>?;
        print('🔍 일반 구독권 쿠폰코드: $inviteCodes');
        
        if (inviteCodes != null && inviteCodes.isNotEmpty) {
          print('✅ 일반 구독권 쿠폰코드 조회 성공: $inviteCodes');
          return {
            'type': 'paid',
            'subscriptionId': currentSub['subscriptionId'],
            'seat': currentSub['seat'],
            'left': currentSub['left'],
            'inviteCodes': inviteCodes,
          };
        } else {
          print('⚠️ 일반 구독권은 있지만 쿠폰코드가 없음');
        }
      } else {
        print('❌ 일반 구독권이 없음');
      }

      // 일반 구독권이 없거나 쿠폰코드가 없으면 무료 구독권 확인
      print('🔍 무료 구독권 조회 시작...');
      final freeSubscription = await getFreeSubscription();
      print('🔍 무료 구독권 API 응답: $freeSubscription');

      if (freeSubscription != null) {
        final trialId = freeSubscription['trialId'];
        print('🔍 무료 구독권 trialId: $trialId');
        
        if (trialId != null) {
          // 무료 구독권이 활성 상태인지 확인
          final endDateStr = freeSubscription['endDate'] as String?;
          print('🔍 무료 구독권 endDate: $endDateStr');
          
          if (endDateStr != null) {
            final endDate = DateTime.parse(endDateStr);
            final now = DateTime.now();
            final isActive = endDate.isAfter(now);
            print('🔍 무료 구독권 활성 상태 확인: endDate=$endDate, now=$now, isActive=$isActive');
            
            if (isActive) {
              print('✅ 활성 무료 구독권 발견: $freeSubscription');
              
              // 무료 구독권 정보 반환 (쿠폰코드는 없지만 구독권 정보 제공)
              final result = {
                'type': 'free',
                'trialId': trialId,
                'startDate': freeSubscription['startDate'],
                'endDate': freeSubscription['endDate'],
                'used': freeSubscription['used'] ?? true,
                'seat': 1, // 무료 구독권은 보통 1인용
                'left': 0, // 무료 구독권은 초대 불가
                'inviteCodes': <String, dynamic>{}, // 빈 쿠폰코드 맵
                'isFreeSubscription': true,
              };
              print('✅ 무료 구독권 정보 반환: $result');
              return result;
            } else {
              print('❌ 무료 구독권이 만료됨 (endDate: $endDate, now: $now)');
            }
          } else {
            print('❌ 무료 구독권 endDate가 null');
          }
        } else {
          print('❌ trialId가 null이므로 무료 구독권이 등록되지 않은 상태');
        }
      } else {
        print('❌ 무료 구독권 API 응답이 null');
      }

      print('❌ 현재 활성 구독권이나 무료 구독권이 없습니다.');
      return null;
    } catch (e) {
      print('❌ 쿠폰코드 조회 중 오류 발생: $e');
      return null;
    }
  }

  // 카톡으로 쿠폰코드 공유하기 (실제 카카오톡 API 연동)
  static Future<bool> shareInviteCodeToKakao(
    String inviteCode,
    int seat,
  ) async {
    try {
      print('===== 카톡 쿠폰코드 공유 시작 =====');
      print('쿠폰코드: $inviteCode, 구독권: ${seat}인용');

      if (inviteCode.isEmpty) {
        print('❌ 쿠폰코드가 비어있습니다.');
        return false;
      }

      // 카카오톡 설치 여부 먼저 확인
      bool isKakaoTalkSharingAvailable =
          await ShareClient.instance.isKakaoTalkSharingAvailable();
      print('📱 카카오톡 설치 여부: $isKakaoTalkSharingAvailable');

      if (!isKakaoTalkSharingAvailable) {
        print('❌ 카카오톡이 설치되어 있지 않습니다.');
        // 웹 공유로 fallback
        return await _shareViaWeb(inviteCode, seat);
      }

      // 카카오톡 메시지 템플릿 생성
      final TextTemplate template = TextTemplate(
        text: '''🎉 리틀뱅크 ${seat}인용 구독권에 초대합니다!

👨‍👩‍👧‍👦 함께 목표를 달성해보세요
💰 가족 할인 혜택으로 더 저렴하게
📱 쿠폰코드: $inviteCode

지금 바로 앱에서 쿠폰코드를 입력하고
리틀뱅크를 시작해보세요!''',
        link: Link(
          webUrl: Uri.parse(
            'https://play.google.com/store/apps/details?id=com.worldcoin.pocketmoneymanagementz',
          ),
          mobileWebUrl: Uri.parse(
            'https://play.google.com/store/apps/details?id=com.worldcoin.pocketmoneymanagementz',
          ),
        ),
        buttons: [
          Button(
            title: '앱에서 쿠폰코드 입력하기',
            link: Link(
              webUrl: Uri.parse(
                'https://your-app-link.com/invite?code=$inviteCode',
              ),
              mobileWebUrl: Uri.parse(
                'https://your-app-link.com/invite?code=$inviteCode',
              ),
            ),
          ),
        ],
      );

      print('📱 카톡 메시지 템플릿 생성 완료');

      try {
        // 카카오톡으로 직접 공유 (사람 선택 화면이 나타남)
        final uri = await ShareClient.instance.shareDefault(template: template);

        if (uri != null) {
          print('✅ 카톡 공유 URI 생성 성공: $uri');

          // URI로 카카오톡 앱 실행
          if (await canLaunchUrl(uri)) {
            await launchUrl(
              uri,
              mode: LaunchMode.externalApplication, // 외부 앱으로 실행
            );
            print('✅ 카카오톡 앱 실행 성공');
            return true;
          } else {
            print('❌ 카카오톡 URI 실행 실패');
            return await _shareViaWeb(inviteCode, seat);
          }
        } else {
          print('❌ 카톡 공유 URI 생성 실패');
          return await _shareViaWeb(inviteCode, seat);
        }
      } catch (kakaoError) {
        print('❌ 카카오톡 앱 공유 실패: $kakaoError');
        // 웹 공유로 fallback
        return await _shareViaWeb(inviteCode, seat);
      }
    } catch (e) {
      print('❌ 카톡 쿠폰코드 공유 중 오류 발생: $e');
      return await _shareViaWeb(inviteCode, seat);
    }
  }

  // 웹브라우저를 통한 카카오톡 공유 (간단한 대안)
  static Future<bool> _shareViaWeb(String inviteCode, int seat) async {
    try {
      print('🌐 웹브라우저를 통한 카카오톡 공유 시작');
      print('쿠폰코드: $inviteCode, 구독권: ${seat}인용');

      // 카카오톡 웹 공유가 도메인 등록 문제로 실패하므로,
      // 웹브라우저에서 카카오링크 직접 생성 시도
      try {
        // 기본 텍스트 템플릿으로 간단하게 시도
        final TextTemplate template = TextTemplate(
          text: '''🎉 리틀뱅크 ${seat}인용 구독권에 초대합니다!

👨‍👩‍👧‍👦 함께 목표를 달성해보세요
💰 가족 할인 혜택으로 더 저렴하게
📱 쿠폰코드: $inviteCode

지금 바로 앱에서 쿠폰코드를 입력하고
리틀뱅크를 시작해보세요!''',
          link: Link(
            webUrl: Uri.parse(
              'https://play.google.com/store/apps/details?id=com.worldcoin.pocketmoneymanagementz',
            ),
            mobileWebUrl: Uri.parse(
              'https://play.google.com/store/apps/details?id=com.worldcoin.pocketmoneymanagementz',
            ),
          ),
        );

        final uri = await ShareClient.instance.shareDefault(template: template);

        if (uri != null) {
          print('📱 기본 템플릿으로 웹 공유 시도: $uri');

          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
            print('✅ 웹 카카오톡 공유 성공');
            return true;
          }
        }
      } catch (templateError) {
        print('❌ 카카오톡 템플릿 공유 실패: $templateError');
      }

      print('❌ 웹 카카오톡 공유 실패, 일반 공유로 fallback');
      // 마지막 fallback: 일반 공유
      return await shareInviteCodeGeneral(inviteCode, seat);
    } catch (e) {
      print('❌ 웹 카카오톡 공유 중 오류: $e');
      // 마지막 fallback: 일반 공유
      return await shareInviteCodeGeneral(inviteCode, seat);
    }
  }

  // 일반 공유하기 (다른 앱으로 공유)
  static Future<bool> shareInviteCodeGeneral(
    String inviteCode,
    int seat,
  ) async {
    try {
      print('===== 일반 공유 시작 =====');
      print('쿠폰코드: $inviteCode, 구독권: ${seat}인용');

      if (inviteCode.isEmpty) {
        print('❌ 쿠폰코드가 비어있습니다.');
        return false;
      }

      final shareText = '''🎉 리틀뱅크 ${seat}인용 구독권에 초대합니다!

👨‍👩‍👧‍👦 함께 목표를 달성해보세요
💰 가족 할인 혜택으로 더 저렴하게
📱 쿠폰코드: $inviteCode

지금 바로 앱에서 쿠폰코드를 입력하고
리틀뱅크를 시작해보세요!

앱 다운로드: https://play.google.com/store/apps/details?id=com.worldcoin.pocketmoneymanagementz''';

      await Share.share(shareText, subject: '리틀뱅크 구독권 초대');

      print('✅ 일반 공유 성공');
      return true;
    } catch (e) {
      print('❌ 일반 공유 중 오류 발생: $e');
      return false;
    }
  }

  // SMS로 쿠폰코드 공유하기
  static Future<bool> shareInviteCodeSMS(String inviteCode, int seat) async {
    try {
      print('===== SMS 공유 시작 =====');
      print('쿠폰코드: $inviteCode, 구독권: ${seat}인용');

      if (inviteCode.isEmpty) {
        print('❌ 쿠폰코드가 비어있습니다.');
        return false;
      }

      final smsText = '''💌 리틀뱅크 초대장이 도착했어요!

👨‍👩‍👧‍👦 ${seat}인용 가족 구독권에 초대합니다
🎯 함께 목표를 달성하고 성장해요
💰 가족 할인 혜택까지 받을 수 있어요!

✨ 쿠폰코드: $inviteCode

📱 앱을 다운로드하고 쿠폰코드를 입력하면
바로 우리 가족이 될 수 있어요!

👇 지금 바로 시작하기
https://play.google.com/store/apps/details?id=com.worldcoin.pocketmoneymanagementz

💙 함께 성장하는 리틀뱅크에서 만나요!''';

      final smsUri = Uri(scheme: 'sms', queryParameters: {'body': smsText});

      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
        print('✅ SMS 공유 성공');
        return true;
      } else {
        print('❌ SMS 앱을 열 수 없습니다.');
        return false;
      }
    } catch (e) {
      print('❌ SMS 공유 중 오류 발생: $e');
      return false;
    }
  }

  // 구독권 쿠폰코드 생성/갱신 (필요시)
  static Future<Map<String, dynamic>?> generateInviteCode() async {
    try {
      print('===== 구독권 쿠폰코드 생성 API 호출 시작 =====');

      final authToken = await AuthService.getAccessToken();
      if (authToken == null) {
        print('인증 토큰이 없습니다.');
        return null;
      }

      final url = Uri.parse('$baseUrl/api-user/subscription/invite-code');
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
      };

      print('API URL: $url');
      print('Headers: $headers');

      final response = await http.post(url, headers: headers);

      print('응답 상태 코드: ${response.statusCode}');
      print('응답 본문: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        print('쿠폰코드 생성 성공: $responseData');
        return responseData;
      } else {
        print('쿠폰코드 생성 실패: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('쿠폰코드 생성 중 오류 발생: $e');
      return null;
    }
  }

  // 웹브라우저를 통한 카카오톡 공유 (공개 메소드)
  static Future<bool> shareInviteCodeToKakaoWeb(
    String inviteCode,
    int seat,
  ) async {
    return await _shareViaWeb(inviteCode, seat);
  }

  // 무료 구독 시작
  static Future<Map<String, dynamic>?> startFreeTrial(String code) async {
    try {
      print('===== 무료 구독 시작 API 호출 시작 =====');
      print('🚀 무료 구독 코드: $code');

      final authToken = await AuthService.getAccessToken();
      if (authToken == null) {
        print('❌ 인증 토큰이 없습니다.');
        return null;
      }

      final url = Uri.parse('$baseUrl/api-user/subscription/start/free');
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
      };

      final body = jsonEncode({'code': code});

      print('📡 API URL: $url');
      print('📡 Headers: $headers');
      print('📡 Body: $body');

      final response = await http.post(url, headers: headers, body: body);

      print('📡 응답 상태 코드: ${response.statusCode}');
      print('📡 응답 본문: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        print('✅ 무료 구독 시작 성공: $responseData');
        
        // 등록 후 바로 무료 구독권 조회해서 확인
        print('🔍 등록 후 무료 구독권 확인 중...');
        await Future.delayed(Duration(milliseconds: 500)); // 서버 처리 대기
        final freeSubCheck = await getFreeSubscription();
        print('🔍 등록 후 무료 구독권 조회 결과: $freeSubCheck');
        
        return responseData;
      } else {
        print('❌ 무료 구독 시작 실패: ${response.statusCode}');

        // 에러 메시지 반환
        try {
          final errorData = jsonDecode(response.body) as Map<String, dynamic>;
          return {
            'error': true,
            'message': errorData['message'] ?? '무료 구독 시작에 실패했습니다.',
            'statusCode': response.statusCode,
          };
        } catch (e) {
          return {
            'error': true,
            'message': '무료 구독 시작에 실패했습니다.',
            'statusCode': response.statusCode,
          };
        }
      }
    } catch (e) {
      print('❌ 무료 구독 시작 중 오류 발생: $e');
      return {'error': true, 'message': '네트워크 오류가 발생했습니다.'};
    }
  }

  // 무료 체험 정보 조회
  static Future<Map<String, dynamic>?> getFreeTrialInfo() async {
    try {
      print('===== 무료 체험 정보 조회 API 호출 시작 =====');

      final authToken = await AuthService.getAccessToken();
      if (authToken == null) {
        print('인증 토큰이 없습니다.');
        return null;
      }

      final url = Uri.parse('$baseUrl/api-user/subscription/free-trial');
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
      };

      print('API URL: $url');
      print('Headers: $headers');

      final response = await http.get(url, headers: headers);

      print('응답 상태 코드: ${response.statusCode}');
      print('응답 본문: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        print('무료 체험 정보 조회 성공: $responseData');
        return responseData;
      } else {
        print('무료 체험 정보 조회 실패: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('무료 체험 정보 조회 중 오류 발생: $e');
      return null;
    }
  }

  // 무료 구독권 정보 조회 (새로운 API)
  static Future<Map<String, dynamic>?> getFreeSubscription() async {
    try {
      print('===== 무료 구독권 정보 조회 API 호출 시작 =====');

      final authToken = await AuthService.getAccessToken();
      if (authToken == null) {
        print('인증 토큰이 없습니다.');
        return null;
      }

      final url = Uri.parse('$baseUrl/api-user/subscription/free');
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
      };

      print('API URL: $url');
      print('Headers: $headers');

      final response = await http.get(url, headers: headers);

      print('응답 상태 코드: ${response.statusCode}');
      print('응답 본문: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        print('무료 구독권 정보 조회 성공: $responseData');
        return responseData;
      } else {
        print('무료 구독권 정보 조회 실패: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('무료 구독권 정보 조회 중 오류 발생: $e');
      return null;
    }
  }

  // 현재 활성 구독권 또는 무료 체험 정보 조회 (통합)
  static Future<Map<String, dynamic>?> getCurrentSubscriptionOrTrial() async {
    try {
      print('===== 현재 구독권/무료체험 정보 조회 시작 =====');

      // 먼저 일반 구독권 확인
      final currentSubscription = await getCurrentSubscription();
      if (currentSubscription != null) {
        print('일반 구독권 발견: $currentSubscription');
        return {'type': 'subscription', 'data': currentSubscription};
      }

      // 일반 구독권이 없으면 무료 구독권 확인
      final freeSubscription = await getFreeSubscription();
      if (freeSubscription != null) {
        print('무료 구독권 API 응답: $freeSubscription');

        // trialId가 null인 경우는 무료 구독권이 등록되지 않은 상태
        final trialId = freeSubscription['trialId'];
        if (trialId != null) {
          // trialId가 있는 경우에만 유효한 무료 구독권으로 처리
          final endDateStr = freeSubscription['endDate'] as String?;
          if (endDateStr != null) {
            final endDate = DateTime.parse(endDateStr);
            final now = DateTime.now();
            if (endDate.isAfter(now)) {
              print('활성 무료 구독권 발견: $freeSubscription');
              return {'type': 'free_subscription', 'data': freeSubscription};
            } else {
              print('무료 구독권이 만료됨');
            }
          } else {
            print('무료 구독권 endDate가 null');
          }
        } else {
          print('trialId가 null이므로 무료 구독권이 등록되지 않은 상태');
        }
      }

      // 무료 구독권도 없으면 무료 체험 확인
      final freeTrialInfo = await getFreeTrialInfo();
      if (freeTrialInfo != null) {
        print('무료 체험 발견: $freeTrialInfo');
        return {'type': 'free_trial', 'data': freeTrialInfo};
      }

      print('현재 활성 구독권 또는 무료 체험이 없습니다.');
      return null;
    } catch (e) {
      print('현재 구독권/무료체험 정보 조회 중 오류 발생: $e');
      return null;
    }
  }

  // 현재 사용 중인 구독권 정보 조회 (유료/무료 통합)
  static Future<Map<String, dynamic>?> getCurrentActiveSubscription() async {
    try {
      print('===== 현재 활성 구독권 조회 시작 =====');

      // 먼저 일반 구독권 확인
      final currentSubscription = await getCurrentSubscription();
      
      // 무료 구독권도 조회 (중복 구독 체크용)
      final freeSubscription = await getFreeSubscription();
      
      // 중복 구독권 상황 체크
      bool hasPaidSubscription = currentSubscription != null;
      bool hasFreeSubscription = false;
      
      if (freeSubscription != null) {
        final trialId = freeSubscription['trialId'];
        if (trialId != null) {
          final endDateStr = freeSubscription['endDate'] as String?;
          if (endDateStr != null) {
            final endDate = DateTime.parse(endDateStr);
            final now = DateTime.now();
            hasFreeSubscription = endDate.isAfter(now);
          }
        }
      }
      
      // 중복 구독권 상황 로깅
      if (hasPaidSubscription && hasFreeSubscription) {
        print('⚠️  중복 구독권 발견: 유료 구독권과 무료 구독권이 모두 활성 상태입니다.');
        print('📊 유료 구독권: $currentSubscription');
        print('📊 무료 구독권: $freeSubscription');
        print('🎯 우선순위에 따라 유료 구독권을 사용합니다.');
      }

      if (currentSubscription != null) {
        print('일반 구독권 발견: $currentSubscription');
        return {
          'type': 'paid',
          'subscriptionType': 'subscription',
          'data': currentSubscription,
          'isActive': true,
          'hasDuplicateSubscription': hasFreeSubscription, // 중복 구독 정보 추가
          'freeSubscriptionData': hasFreeSubscription ? freeSubscription : null,
        };
      }

      // 일반 구독권이 없으면 무료 구독권 확인
      if (freeSubscription != null) {
        print('무료 구독권 API 응답: $freeSubscription');

        // trialId가 null인 경우는 무료 구독권이 등록되지 않은 상태
        final trialId = freeSubscription['trialId'];
        if (trialId == null) {
          print('trialId가 null이므로 무료 구독권이 등록되지 않은 상태');
          print('현재 활성 구독권이 없습니다.');
          return null;
        }

        // trialId가 있는 경우에만 활성 상태 확인
        final endDateStr = freeSubscription['endDate'] as String?;
        bool isActive = false;

        if (endDateStr != null) {
          final endDate = DateTime.parse(endDateStr);
          final now = DateTime.now();
          isActive = endDate.isAfter(now);
          print('무료 구독권 활성 상태 확인: endDate=$endDateStr, isActive=$isActive');
        } else {
          print('무료 구독권 endDate가 null이므로 비활성 상태');
        }

        if (isActive) {
          print('활성 무료 구독권 발견: $freeSubscription');
          return {
            'type': 'free',
            'subscriptionType': 'free_subscription',
            'data': freeSubscription,
            'isActive': isActive,
            'hasDuplicateSubscription': false,
            'freeSubscriptionData': null,
          };
        } else {
          print('무료 구독권이 만료되었거나 비활성 상태');
        }
      }

      print('현재 활성 구독권이 없습니다.');
      return null;
    } catch (e) {
      print('현재 활성 구독권 조회 중 오류 발생: $e');
      return null;
    }
  }

  // 구글 인앱결제 구매 검증 API
  static Future<Map<String, dynamic>?> validateGooglePlayPurchase({
    required String packageName,
    required String productId,
    required String purchaseToken,
    bool? includeOwner,
  }) async {
    try {
      print('===== 구글 인앱결제 구매 검증 API 호출 시작 =====');
      print('packageName: $packageName');
      print('productId: $productId');
      print('purchaseToken: $purchaseToken');
      print('includeOwner: $includeOwner');
      
      // 현재 구독권 상태 확인
      try {
        final currentSub = await getCurrentSubscription();
        if (currentSub != null && currentSub.isNotEmpty) {
          print('⚠️  이미 활성 구독권이 있는 상태에서 새 구독권 구매 시도');
          print('🔍 기존 구독권: $currentSub');
          print('💡 서버에서 중복 구독 방지로 차단했을 가능성');
        } else {
          print('✅ 현재 활성 구독권 없음 - 새 구독권 구매 가능');
        }
      } catch (e) {
        print('🔍 현재 구독권 확인 실패: $e');
      }

      final authToken = await AuthService.getAccessToken();
      if (authToken == null) {
        print('❌ 인증 토큰이 없습니다.');
        return null;
      }

      final url = Uri.parse('$baseUrl/api-user/subscription/purchase/inapp');
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
      };

      // includeOwner 처리: 1인 구독권은 null, 3인/5인 구독권은 사용자 선택값
      final Map<String, dynamic> requestBody = {
        'packageName': packageName,
        'productId': productId,
        'purchaseToken': purchaseToken,
      };

      // 1인 구독권이 아닌 경우에만 includeOwner 추가
      if (includeOwner != null) {
        requestBody['includeOwner'] = includeOwner;
        print('📋 includeOwner 파라미터 추가: $includeOwner');
      } else {
        print('📋 includeOwner 파라미터 제외 (1인 구독권)');
      }

      // 상품 ID별 로그 추가
      print('🔍 상품 분석:');
      print('   - productId: $productId');
      if (productId == 'one_month_ly') {
        print('   - 타입: 1인 정기결제 구독권');
      } else if (productId == 'three_month_ly') {
        print('   - 타입: 3인 정기결제 구독권');
      } else if (productId == 'five_month_ly') {
        print('   - 타입: 5인 정기결제 구독권');
      } else {
        print('   - 타입: 알 수 없는 상품 (서버에 등록되지 않았을 수 있음)');
      }

      final body = jsonEncode(requestBody);

      print('📡 API URL: $url');
      print('📡 Headers: $headers');
      print('📡 Body: $body');

      // 재시도 로직 추가 (최대 3회)
      for (int retry = 0; retry < 3; retry++) {
        if (retry > 0) {
          print('🔄 재시도 ${retry + 1}/3 - ${retry * 2}초 대기 후 시도');
          await Future.delayed(Duration(seconds: retry * 2));
        }

        final response = await http.post(url, headers: headers, body: body);

        print('📡 응답 상태 코드: ${response.statusCode} (시도 ${retry + 1}/3)');
        print('📡 응답 본문: ${response.body}');

        if (response.statusCode == 200) {
          final responseData = jsonDecode(response.body) as Map<String, dynamic>;
          print('✅ 구글 인앱결제 구매 검증 성공: $responseData');
          return responseData;
        } else {
          print('❌ 구글 인앱결제 구매 검증 실패: ${response.statusCode}');
          print('❌ 에러 응답 본문: ${response.body}');
          
          try {
            final errorData = jsonDecode(response.body) as Map<String, dynamic>;
            final errorMessage = errorData['message'] ?? '알 수 없는 오류';
            final errorCode = errorData['code'] ?? '';
            final status = errorData['status'] ?? response.statusCode;
            
            print('❌ 에러 상세 정보:');
            print('   - 메시지: $errorMessage');
            print('   - 코드: $errorCode');
            print('   - 상태: $status');
            
            // SS009 에러인 경우 즉시 fallback 처리 (재시도 없이)
            if (errorCode == 'SS009') {
              print('💡 SS009 에러 - 가능한 원인:');
              print('   1. 내부 테스트 환경에서의 가짜 구매');
              print('   2. 이미 처리된 purchaseToken');
              print('   3. Google Play Developer API 설정 문제');
              print('   4. 네트워크 타이밍 문제');
              
              // SS009 에러 시 즉시 fallback 처리
              print('🔄 SS009 에러 감지 - 기존 API로 즉시 fallback 시도');
              try {
                final fallbackResult = await _tryFallbackSubscriptionCreation(
                  productId: productId,
                  purchaseToken: purchaseToken,
                  includeOwner: includeOwner,
                );
                
                if (fallbackResult != null) {
                  print('✅ Fallback API로 구독권 생성 성공');
                  return fallbackResult;
                } else {
                  print('❌ Fallback API도 실패');
                }
              } catch (fallbackError) {
                print('❌ Fallback API 시도 중 오류: $fallbackError');
              }
              
              // fallback도 실패한 경우 에러 반환
              return {
                'error': true,
                'message': 'SS009 에러: 내부 테스트 환경이거나 이미 처리된 구매일 수 있습니다.',
                'statusCode': status,
                'code': errorCode,
                'originalMessage': errorMessage,
              };
            }
            
            // SS009이 아닌 경우 마지막 시도가 아니면 재시도
            if (retry < 2) {
              print('🔄 ${retry + 1}번째 시도 실패, 재시도 예정...');
              continue;
            }
            
            // 마지막 시도 실패 시 에러 반환
            String detailedMessage = errorMessage;
            return {
              'error': true,
              'message': detailedMessage,
              'statusCode': status,
              'code': errorCode,
              'originalMessage': errorMessage,
            };
          } catch (e) {
            print('❌ 에러 응답 파싱 실패: $e');
            if (retry < 2) {
              continue;
            }
            return {
              'error': true,
              'message': '구매 검증에 실패했습니다. (HTTP ${response.statusCode})',
              'statusCode': response.statusCode,
            };
          }
        }
      }

      // 모든 재시도 실패
      return {
        'error': true,
        'message': '구매 검증에 실패했습니다. (모든 재시도 실패)',
        'statusCode': 500,
      };
    } catch (e) {
      print('❌ 구글 인앱결제 구매 검증 중 오류 발생: $e');
      return {'error': true, 'message': '네트워크 오류가 발생했습니다.'};
    }
  }

  // SS009 에러 발생 시 fallback 처리를 위한 헬퍼 함수
  static Future<Map<String, dynamic>?> _tryFallbackSubscriptionCreation({
    required String productId,
    required String purchaseToken,
    bool? includeOwner,
  }) async {
    print('🔄 Fallback 구독권 생성 시도 시작');
    
    // 상품 ID에 따른 인원 수 결정
    int persons = 1;
    if (productId == 'three_month_ly') {
      persons = 3;
    } else if (productId == 'five_month_ly') {
      persons = 5;
    }
    
    print('🔍 Fallback 파라미터: persons=$persons, includeOwner=$includeOwner');
    
    // 기존 API 사용
    final result = await createSubscriptionWithPurchase(
      seat: persons,
      purchaseToken: purchaseToken,
      includeOwner: includeOwner ?? (persons == 1), // 1인 구독권은 true, 다인 구독권은 사용자 선택값
    );
    
    if (result != null) {
      print('✅ Fallback API 성공: $result');
      return {
        'success': true,
        'data': result,
        'fallback': true, // fallback으로 처리되었음을 표시
      };
    } else {
      print('❌ Fallback API 실패');
      return null;
    }
  }

  // 구독 상태 조회 API
  static Future<Map<String, dynamic>?> getSubscriptionStatus() async {
    try {
      print('===== 구독 상태 조회 API 호출 시작 =====');

      final authToken = await AuthService.getAccessToken();
      if (authToken == null) {
        print('❌ 인증 토큰이 없습니다.');
        return null;
      }

      final url = Uri.parse('$baseUrl/api-user/subscription/status');
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
      };

      print('📡 API URL: $url');
      print('📡 Headers: $headers');

      final response = await http.get(url, headers: headers);

      print('📡 응답 상태 코드: ${response.statusCode}');
      print('📡 응답 본문: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        print('✅ 구독 상태 조회 성공: $responseData');
        return responseData;
      } else {
        print('❌ 구독 상태 조회 실패: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ 구독 상태 조회 중 오류 발생: $e');
      return null;
    }
  }

  // 구독 취소 API
  static Future<bool> cancelSubscription() async {
    try {
      print('===== 구독 취소 API 호출 시작 =====');

      final authToken = await AuthService.getAccessToken();
      if (authToken == null) {
        print('❌ 인증 토큰이 없습니다.');
        return false;
      }

      final url = Uri.parse('$baseUrl/api-user/subscription/cancel');
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
      };

      print('📡 API URL: $url');
      print('📡 Headers: $headers');

      final response = await http.post(url, headers: headers);

      print('📡 응답 상태 코드: ${response.statusCode}');
      print('📡 응답 본문: ${response.body}');

      if (response.statusCode == 200) {
        print('✅ 구독 취소 성공');
        return true;
      } else {
        print('❌ 구독 취소 실패: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ 구독 취소 중 오류 발생: $e');
      return false;
    }
  }

  // 구독 상태 동기화 API
  static Future<bool> syncSubscriptionStatus() async {
    try {
      print('===== 구독 상태 동기화 API 호출 시작 =====');

      final authToken = await AuthService.getAccessToken();
      if (authToken == null) {
        print('❌ 인증 토큰이 없습니다.');
        return false;
      }

      final url = Uri.parse('$baseUrl/api-user/subscription/sync');
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
      };

      print('📡 API URL: $url');
      print('📡 Headers: $headers');

      final response = await http.post(url, headers: headers);

      print('📡 응답 상태 코드: ${response.statusCode}');
      print('📡 응답 본문: ${response.body}');

      if (response.statusCode == 200) {
        print('✅ 구독 상태 동기화 성공');
        return true;
      } else {
        print('❌ 구독 상태 동기화 실패: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ 구독 상태 동기화 중 오류 발생: $e');
      return false;
    }
  }

  // 구독 초대코드 조회 API (새로운 엔드포인트)
  static Future<List<Map<String, dynamic>>?> getInviteCodesList() async {
    try {
      print('===== 구독 초대코드 조회 API 호출 시작 =====');

      final authToken = await AuthService.getAccessToken();
      if (authToken == null) {
        print('❌ 인증 토큰이 없습니다.');
        return null;
      }

      final url = Uri.parse('$baseUrl/api-user/subscription/get/invidecode');
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
      };

      print('📡 API URL: $url');
      print('📡 Headers: $headers');

      final response = await http.get(url, headers: headers);

      print('📡 응답 상태 코드: ${response.statusCode}');
      print('📡 응답 본문: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as List<dynamic>;
        final inviteCodes = responseData
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
        print('✅ 구독 초대코드 조회 성공: $inviteCodes');
        return inviteCodes;
      } else {
        print('❌ 구독 초대코드 조회 실패: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ 구독 초대코드 조회 중 오류 발생: $e');
      return null;
    }
  }

  // 사용 가능한 (미사용) 초대코드 목록 조회
  static Future<List<Map<String, dynamic>>?> getAvailableInviteCodes() async {
    try {
      print('===== 사용 가능한 초대코드 조회 시작 =====');

      final allCodes = await getInviteCodesList();
      if (allCodes == null) {
        print('❌ 초대코드 조회 실패');
        return null;
      }

      // 사용되지 않은 코드만 필터링
      final availableCodes = allCodes.where((code) {
        final isUsed = code['used'] as bool? ?? false;
        return !isUsed;
      }).toList();

      print('✅ 사용 가능한 초대코드 ${availableCodes.length}개 발견');
      print('📋 사용 가능한 코드들: $availableCodes');

      return availableCodes;
    } catch (e) {
      print('❌ 사용 가능한 초대코드 조회 중 오류 발생: $e');
      return null;
    }
  }

  // 특정 초대코드의 사용 상태 확인
  static Future<Map<String, dynamic>?> getInviteCodeStatus(String code) async {
    try {
      print('===== 초대코드 상태 확인: $code =====');

      final allCodes = await getInviteCodesList();
      if (allCodes == null) {
        print('❌ 초대코드 조회 실패');
        return null;
      }

      // 해당 코드 찾기
      final codeInfo = allCodes.firstWhere(
        (item) => item['code'] == code,
        orElse: () => <String, dynamic>{},
      );

      if (codeInfo.isEmpty) {
        print('❌ 초대코드 $code를 찾을 수 없습니다.');
        return null;
      }

      print('✅ 초대코드 $code 상태: $codeInfo');
      return codeInfo;
    } catch (e) {
      print('❌ 초대코드 상태 확인 중 오류 발생: $e');
      return null;
    }
  }

  // 개별 쿠폰 코드 전송 기록 (클라이언트 측 관리)
  static Map<String, String> _individualCouponSentRecord = {};

  // 개별 쿠폰 코드 전송 기록 저장
  static void recordIndividualCouponSent(String code, String recipientName) {
    _individualCouponSentRecord[code] = recipientName;
    print('📝 개별 쿠폰 전송 기록 저장: $code -> $recipientName');
  }

  // 개별 쿠폰 코드 전송 기록 조회
  static Map<String, String> getIndividualCouponSentRecord() {
    return Map.from(_individualCouponSentRecord);
  }

  // 개별 쿠폰 코드 전송 기록 삭제
  static void clearIndividualCouponSentRecord() {
    _individualCouponSentRecord.clear();
    print('🗑️ 개별 쿠폰 전송 기록 삭제됨');
  }

  // 특정 코드의 전송 기록 삭제
  static void removeIndividualCouponSentRecord(String code) {
    _individualCouponSentRecord.remove(code);
    print('🗑️ 개별 쿠폰 전송 기록 삭제: $code');
  }

  // 개별 초대코드와 수신자 매칭 정보 조회
  static Future<Map<String, dynamic>?> getInviteCodeMatching() async {
    try {
      print('===== 개별 초대코드 매칭 정보 조회 시작 =====');

      // 서버에서 전체 초대코드 조회
      final allCodes = await getInviteCodesList();
      if (allCodes == null) {
        print('❌ 초대코드 조회 실패');
        return null;
      }

      // 현재 구독권 정보 조회
      final currentSub = await getCurrentSubscription();
      if (currentSub == null) {
        print('❌ 현재 구독권 정보 없음');
        return null;
      }

      final seat = currentSub['seat'] as int? ?? 0;
      final used = allCodes.where((code) => code['used'] == true).length;
      final available = allCodes.where((code) => code['used'] == false).length;

      // 클라이언트 측 전송 기록과 병합
      final sentRecord = getIndividualCouponSentRecord();

      final result = {
        'totalSeats': seat,
        'totalCodes': allCodes.length,
        'usedCodes': used,
        'availableCodes': available,
        'serverCodes': allCodes,
        'clientSentRecord': sentRecord,
        'matchingInfo': <String, dynamic>{},
      };

      // 매칭 정보 생성
      Map<String, dynamic> matchingInfo = {};
      for (final code in allCodes) {
        final codeString = code['code'] as String;
        final isUsed = code['used'] as bool? ?? false;
        final redeemedById = code['redeemedById'] as int?;
        final redeemedByName = code['redeemedByName'] as String?;

        matchingInfo[codeString] = {
          'serverUsed': isUsed,
          'redeemedById': redeemedById,
          'redeemedByName': redeemedByName,
          'clientSentTo': sentRecord[codeString],
          'status': isUsed ? 'redeemed' : (sentRecord.containsKey(codeString) ? 'sent' : 'available'),
        };
      }

      result['matchingInfo'] = matchingInfo;

      print('✅ 개별 초대코드 매칭 정보 조회 완료');
      print('📊 총 좌석: $seat, 사용됨: $used, 사용 가능: $available');
      print('📋 매칭 정보: $matchingInfo');

      return result;
    } catch (e) {
      print('❌ 개별 초대코드 매칭 정보 조회 중 오류 발생: $e');
      return null;
    }
  }
}

// ========== 정기결제를 위해 추가로 필요한 서버 API들 ==========
// 아래 API들이 서버에 구현되어야 정기결제 서비스가 완전히 동작합니다.

/*
  // 1. Google Play 영수증 검증 및 구독 활성화 API (가장 중요!)
  static Future<Map<String, dynamic>?> validateGooglePlayPurchase(
    Map<String, dynamic> purchaseData,
  ) async {
    // POST /api-user/subscription/purchase/inapp
    // Body: {
    //   "platform": "android",
    //   "productId": "one_month_ly",
    //   "purchaseToken": "...",
    //   "orderId": "...", 
    //   "verificationData": "...",
    //   "isSubscription": true,
    //   "subscriptionType": "monthly"
    // }
    // 
    // 기능:
    // - Google Play 영수증 검증
    // - 정기결제 상품이면 자동으로 구독권 생성/갱신
    // - 1인 구독권의 경우 즉시 활성화
    // - 다인 구독권의 경우 쿠폰코드 생성
  }

  // 2. 실시간 구독 상태 확인 API
  static Future<Map<String, dynamic>?> getSubscriptionStatus() async {
    // GET /api-user/subscription/status
    // 응답: {
    //   "isActive": true,
    //   "type": "monthly" | "onetime" | "free",
    //   "productId": "one_month_ly",
    //   "startDate": "2024-01-01T00:00:00Z",
    //   "endDate": "2024-02-01T00:00:00Z",
    //   "autoRenew": true,
    //   "subscriptionId": "sub_123"
    // }
  }

  // 3. 정기결제 취소 API
  static Future<bool> cancelSubscription() async {
    // POST /api-user/subscription/cancel
    // Google Play 구독 취소 요청
    // 구독권은 만료일까지 유효하게 유지
  }

  // 4. 정기결제 일시정지/재개 API
  static Future<bool> pauseSubscription() async {
    // POST /api-user/subscription/pause
  }
  
  static Future<bool> resumeSubscription() async {
    // POST /api-user/subscription/resume  
  }

  // 5. 결제 내역 조회 API
  static Future<List<Map<String, dynamic>>?> getBillingHistory() async {
    // GET /api-user/subscription/billing-history
    // 모든 결제 내역 (정기결제, 일회성 구매) 조회
  }

  // 6. 구독권과 결제 연결 API
  static Future<Map<String, dynamic>?> linkPurchaseToSubscription(
    String purchaseToken,
    String subscriptionId,
  ) async {
    // POST /api-user/subscription/link-purchase
    // Google Play 결제와 구독권을 연결
  }

  // 7. Google Play Webhook 처리 (서버에서만 사용)
  // POST /api/webhook/google-play
  // - 자동 갱신 알림 처리
  // - 취소 알림 처리  
  // - 만료 알림 처리
  // - 환불 알림 처리

  // 8. 구독권 자동 갱신 처리 (서버에서만 사용)  
  // - 정기결제 성공 시 구독권 자동 연장
  // - 1인 구독권의 경우 즉시 처리
  // - 다인 구독권의 경우 새로운 쿠폰코드 생성

  // 9. 구독 상태 동기화 API
  static Future<bool> syncSubscriptionStatus() async {
    // POST /api-user/subscription/sync
    // Google Play 구독 상태와 서버 구독권 상태 동기화
  }

  // 10. 정기결제 유예 기간 처리 API
  static Future<Map<String, dynamic>?> getGracePeriodInfo() async {
    // GET /api-user/subscription/grace-period
    // 결제 실패 시 유예 기간 정보 조회
  }
*/
