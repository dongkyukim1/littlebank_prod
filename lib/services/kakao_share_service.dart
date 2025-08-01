import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'deep_link_service.dart';
import 'subscription_service.dart';

class KakaoShareService {
  static final KakaoShareService _instance = KakaoShareService._internal();
  factory KakaoShareService() => _instance;
  KakaoShareService._internal();

  // 카카오톡 설치 여부 확인
  static Future<bool> isKakaoTalkInstalled() async {
    return await ShareClient.instance.isKakaoTalkSharingAvailable();
  }

  // 개별 쿠폰 코드를 특정 사람에게 보내기 (1:1 매칭)
  static Future<bool> shareIndividualInviteCode({
    required String inviteCode,
    required String recipientName,
    required BuildContext context,
    int? totalSeats,
    int? currentIndex,
    int? totalCount,
  }) async {
    try {
      print('===== 개별 쿠폰 코드 전송 시작 =====');
      print('🎯 수신자: $recipientName');
      print('🎫 쿠폰 코드: $inviteCode');
      print('👥 총 좌석: $totalSeats');
      if (currentIndex != null && totalCount != null) {
        print('📊 진행률: ${currentIndex}/${totalCount}');
      }

      // 서버 웹 딥링크 URL
      const String webDeepLinkUrl = 'http://3.34.52.239:8080/deeplink/invite';
      final String webDeepLinkUrlWithCode = '$webDeepLinkUrl?code=$inviteCode';

      // 연속 전송 시 더 명확한 메시지 구성
      String progressText = '';
      if (currentIndex != null && totalCount != null) {
        progressText = '\n\n📊 이것은 ${totalCount}개 코드 중 ${currentIndex}번째 코드입니다.';
      }

      // 개별 맞춤형 카카오톡 템플릿 구성
      final TextTemplate template = TextTemplate(
        text: '''
🎉 $recipientName님, 리틀뱅크 초대장이 도착했어요!

안녕하세요 $recipientName님! 👋
리틀뱅크 가족 구독권에 초대드립니다.

🏦 함께 경제 공부하고 성장해요!
📈 미션 완료하고 용돈도 받아보세요
👨‍👩‍👧‍👦 가족과 함께 더 재미있게!

🎫 $recipientName님 전용 초대코드
📝 코드: $inviteCode$progressText

💡 초대코드를 입력하면 바로 시작할 수 있어요!
함께 리틀뱅크에서 경제 습관을 만들어봐요! 💙

#리틀뱅크 #가족구독권 #경제교육 #용돈관리
        ''',
        link: Link(
          webUrl: Uri.parse(webDeepLinkUrlWithCode),
          mobileWebUrl: Uri.parse(webDeepLinkUrlWithCode),
        ),
        buttons: [
          Button(
            title: '🏦 리틀뱅크 시작하기',
            link: Link(
              webUrl: Uri.parse(webDeepLinkUrlWithCode),
              mobileWebUrl: Uri.parse(webDeepLinkUrlWithCode),
            ),
          ),
        ],
      );

      // 카카오톡 공유 시도
      print('📱 카카오톡 공유 시도 중...');
      
      bool isKakaoTalkSharingAvailable = await ShareClient.instance.isKakaoTalkSharingAvailable();
      
      if (isKakaoTalkSharingAvailable) {
        print('✅ 카카오톡 앱이 설치되어 있음 - 개별 쿠폰 전송');
        
        Uri uri = await ShareClient.instance.shareDefault(template: template);
        await ShareClient.instance.launchKakaoTalk(uri);
        
        // 전송 기록 저장
        SubscriptionService.recordIndividualCouponSent(inviteCode, recipientName);
        
        print('✅ 개별 쿠폰 카카오톡 공유 완료');
        print('📝 전송 기록 저장: $inviteCode -> $recipientName');
        
        // 연속 전송 시에는 스낵바를 표시하지 않음 (중복 방지)
        if (currentIndex == null && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$recipientName님에게 초대코드를 전송했습니다! 🎉'),
              backgroundColor: Colors.blue,
            ),
          );
        }
        
        return true;
      } else {
        print('❌ 카카오톡 앱이 설치되어 있지 않음 - 시스템 공유로 대체');
        return await _shareIndividualViaSystem(context, inviteCode, recipientName, totalSeats);
      }
    } catch (error) {
      print('❌ 개별 쿠폰 카카오톡 공유 실패: $error');
      
      // 카카오톡 공유 실패 시 시스템 공유로 대체
      return await _shareIndividualViaSystem(context, inviteCode, recipientName, totalSeats);
    }
  }

  // 개별 쿠폰 시스템 공유 (대체 방법)
  static Future<bool> _shareIndividualViaSystem(
    BuildContext context,
    String inviteCode,
    String recipientName,
    int? totalSeats,
  ) async {
    try {
      print('🌐 개별 쿠폰 시스템 공유 시작');
      print('🎯 수신자: $recipientName');
      print('🎫 쿠폰 코드: $inviteCode');
      
      // 서버 웹 딥링크
      const String webDeepLinkUrl = 'http://3.34.52.239:8080/deeplink/invite';
      final String webDeepLinkUrlWithCode = '$webDeepLinkUrl?code=$inviteCode';
      
      final String message = '''
🎉 $recipientName님, 리틀뱅크 초대장이 도착했어요!

안녕하세요 $recipientName님! 👋
리틀뱅크 가족 구독권에 초대드립니다.

🏦 함께 경제 공부하고 성장해요!
📈 미션 완료하고 용돈도 받아보세요
👨‍👩‍👧‍👦 가족과 함께 더 재미있게!

🎫 $recipientName님 전용 초대코드
📝 코드: $inviteCode

🌐 시작하기: $webDeepLinkUrlWithCode

💡 초대코드를 입력하면 바로 시작할 수 있어요!
함께 리틀뱅크에서 경제 습관을 만들어봐요! 💙

#리틀뱅크 #가족구독권 #경제교육 #용돈관리
      ''';

      // share_plus 패키지를 사용한 시스템 공유
      await Share.share(message, subject: '🏦 리틀뱅크 $recipientName님 전용 초대장');
      
      // 전송 기록 저장
      SubscriptionService.recordIndividualCouponSent(inviteCode, recipientName);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$recipientName님에게 초대코드를 전송했습니다! 🎉'),
            backgroundColor: Colors.blue,
          ),
        );
      }
      
      return true;
    } catch (e) {
      print('❌ 개별 쿠폰 시스템 공유 오류: $e');
      return false;
    }
  }

  // 남은 쿠폰 코드들을 추가로 보내기
  static Future<bool> shareRemainingInviteCodes({
    required BuildContext context,
  }) async {
    try {
      print('===== 남은 쿠폰 코드 추가 전송 시작 =====');

      // 현재 매칭 정보 조회
      final matchingInfo = await SubscriptionService.getInviteCodeMatching();
      if (matchingInfo == null) {
        print('❌ 쿠폰 매칭 정보 조회 실패');
        return false;
      }

      final matchingDetails = matchingInfo['matchingInfo'] as Map<String, dynamic>;
      
      // 사용 가능한 (보내지 않은) 쿠폰 코드들 추출
      final availableCodes = <String>[];
      matchingDetails.forEach((code, info) {
        final status = info['status'] as String;
        if (status == 'available') {
          availableCodes.add(code);
        }
      });

      if (availableCodes.isEmpty) {
        print('❌ 보낼 수 있는 쿠폰 코드가 없습니다.');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('보낼 수 있는 쿠폰 코드가 없습니다.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return false;
      }

      print('✅ 보낼 수 있는 쿠폰 코드 ${availableCodes.length}개 발견');
      print('📋 쿠폰 코드들: $availableCodes');

      // 모든 남은 쿠폰 코드를 하나의 메시지로 공유
      return await _shareMultipleRemainingCodes(context, availableCodes, matchingInfo);
    } catch (e) {
      print('❌ 남은 쿠폰 코드 추가 전송 중 오류 발생: $e');
      return false;
    }
  }

  // 여러 개의 남은 쿠폰 코드를 하나의 메시지로 공유
  static Future<bool> _shareMultipleRemainingCodes(
    BuildContext context,
    List<String> codes,
    Map<String, dynamic> matchingInfo,
  ) async {
    try {
      print('===== 여러 쿠폰 코드 통합 전송 시작 =====');
      print('📦 쿠폰 코드 수: ${codes.length}');

      final totalSeats = matchingInfo['totalSeats'] as int? ?? 0;
      final usedCodes = matchingInfo['usedCodes'] as int? ?? 0;
      
      // 서버 웹 딥링크 URL (첫 번째 코드로 설정)
      const String webDeepLinkUrl = 'http://3.34.52.239:8080/deeplink/invite';
      final String webDeepLinkUrlWithCode = '$webDeepLinkUrl?code=${codes.first}';

      // 여러 쿠폰 코드 목록 생성
      String codesList = '';
      for (int i = 0; i < codes.length; i++) {
        codesList += '${i + 1}. ${codes[i]}\n';
      }

      // 카카오톡 템플릿 구성
      final TextTemplate template = TextTemplate(
        text: '''
🎉 리틀뱅크 추가 초대코드가 있어요!

현재 ${totalSeats}인 구독권에서 $usedCodes명이 참여하고 있어요.
아직 ${codes.length}개의 초대코드가 남아있습니다! 🎫

💝 추가 초대 가능한 코드들:
$codesList

🏦 가족, 친구들과 함께 리틀뱅크를 시작해보세요!
📈 미션 완료하고 용돈도 받고
👨‍👩‍👧‍👦 함께하면 더 재미있어요!

💡 원하는 코드를 선택해서 초대해보세요!

#리틀뱅크 #가족구독권 #경제교육 #용돈관리
        ''',
        link: Link(
          webUrl: Uri.parse(webDeepLinkUrlWithCode),
          mobileWebUrl: Uri.parse(webDeepLinkUrlWithCode),
        ),
        buttons: [
          Button(
            title: '🏦 리틀뱅크 시작하기',
            link: Link(
              webUrl: Uri.parse(webDeepLinkUrlWithCode),
              mobileWebUrl: Uri.parse(webDeepLinkUrlWithCode),
            ),
          ),
        ],
      );

      // 카카오톡 공유 시도
      print('📱 여러 쿠폰 코드 카카오톡 공유 시도 중...');
      
      bool isKakaoTalkSharingAvailable = await ShareClient.instance.isKakaoTalkSharingAvailable();
      
      if (isKakaoTalkSharingAvailable) {
        print('✅ 카카오톡 앱이 설치되어 있음 - 여러 쿠폰 전송');
        
        Uri uri = await ShareClient.instance.shareDefault(template: template);
        await ShareClient.instance.launchKakaoTalk(uri);
        
        print('✅ 여러 쿠폰 코드 카카오톡 공유 완료');
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${codes.length}개의 추가 초대코드를 전송했습니다! 🎉'),
              backgroundColor: Colors.blue,
            ),
          );
        }
        
        return true;
      } else {
        print('❌ 카카오톡 앱이 설치되어 있지 않음 - 시스템 공유로 대체');
        return await _shareMultipleRemainingCodesViaSystem(context, codes, matchingInfo);
      }
    } catch (error) {
      print('❌ 여러 쿠폰 코드 카카오톡 공유 실패: $error');
      
      // 카카오톡 공유 실패 시 시스템 공유로 대체
      return await _shareMultipleRemainingCodesViaSystem(context, codes, matchingInfo);
    }
  }

  // 여러 쿠폰 코드 시스템 공유
  static Future<bool> _shareMultipleRemainingCodesViaSystem(
    BuildContext context,
    List<String> codes,
    Map<String, dynamic> matchingInfo,
  ) async {
    try {
      print('🌐 여러 쿠폰 코드 시스템 공유 시작');
      
      final totalSeats = matchingInfo['totalSeats'] as int? ?? 0;
      final usedCodes = matchingInfo['usedCodes'] as int? ?? 0;
      
      // 서버 웹 딥링크
      const String webDeepLinkUrl = 'http://3.34.52.239:8080/deeplink/invite';
      final String webDeepLinkUrlWithCode = '$webDeepLinkUrl?code=${codes.first}';
      
      // 여러 쿠폰 코드 목록 생성
      String codesList = '';
      for (int i = 0; i < codes.length; i++) {
        codesList += '${i + 1}. ${codes[i]}\n';
      }
      
      final String message = '''
🎉 리틀뱅크 추가 초대코드가 있어요!

현재 ${totalSeats}인 구독권에서 $usedCodes명이 참여하고 있어요.
아직 ${codes.length}개의 초대코드가 남아있습니다! 🎫

💝 추가 초대 가능한 코드들:
$codesList

🏦 가족, 친구들과 함께 리틀뱅크를 시작해보세요!
📈 미션 완료하고 용돈도 받고
👨‍👩‍👧‍👦 함께하면 더 재미있어요!

🌐 시작하기: $webDeepLinkUrlWithCode

💡 원하는 코드를 선택해서 초대해보세요!

#리틀뱅크 #가족구독권 #경제교육 #용돈관리
      ''';

      // share_plus 패키지를 사용한 시스템 공유
      await Share.share(message, subject: '🏦 리틀뱅크 추가 초대코드 ${codes.length}개');
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${codes.length}개의 추가 초대코드를 전송했습니다! 🎉'),
            backgroundColor: Colors.blue,
          ),
        );
      }
      
      return true;
    } catch (e) {
      print('❌ 여러 쿠폰 코드 시스템 공유 오류: $e');
      return false;
    }
  }

  // 쿠폰 코드 전송 상태 확인
  static Future<Map<String, dynamic>?> getInviteCodeSendingStatus() async {
    try {
      print('===== 쿠폰 코드 전송 상태 확인 시작 =====');

      final matchingInfo = await SubscriptionService.getInviteCodeMatching();
      if (matchingInfo == null) {
        print('❌ 쿠폰 매칭 정보 조회 실패');
        return null;
      }

      final matchingDetails = matchingInfo['matchingInfo'] as Map<String, dynamic>;
      
      Map<String, dynamic> statusSummary = {
        'totalCodes': matchingDetails.length,
        'availableCount': 0,
        'sentCount': 0,
        'redeemedCount': 0,
        'availableCodes': <String>[],
        'sentCodes': <Map<String, dynamic>>[],
        'redeemedCodes': <Map<String, dynamic>>[],
      };

      matchingDetails.forEach((code, info) {
        final status = info['status'] as String;
        
        switch (status) {
          case 'available':
            statusSummary['availableCount']++;
            (statusSummary['availableCodes'] as List<String>).add(code);
            break;
          case 'sent':
            statusSummary['sentCount']++;
            (statusSummary['sentCodes'] as List<Map<String, dynamic>>).add({
              'code': code,
              'sentTo': info['clientSentTo'],
            });
            break;
          case 'redeemed':
            statusSummary['redeemedCount']++;
            (statusSummary['redeemedCodes'] as List<Map<String, dynamic>>).add({
              'code': code,
              'redeemedById': info['redeemedById'],
              'redeemedByName': info['redeemedByName'],
            });
            break;
        }
      });

      print('✅ 쿠폰 코드 전송 상태 확인 완료');
      print('📊 상태 요약: $statusSummary');

      return statusSummary;
    } catch (e) {
      print('❌ 쿠폰 코드 전송 상태 확인 중 오류 발생: $e');
      return null;
    }
  }

  // 친구 초대 메시지 공유 (littlebank 전용 템플릿)
  static Future<void> shareLittleBankInvite({
    required String inviteCode,
    required BuildContext context,
  }) async {
    try {
      // 서버 웹 딥링크 URL (서버에서 JavaScript로 앱 딥링크 처리)
      const String webDeepLinkUrl = 'http://3.34.52.239:8080/deeplink/invite';
      final String webDeepLinkUrlWithCode = '$webDeepLinkUrl?code=$inviteCode';
      
      // 디버깅을 위한 URL 출력
      print('🔗 서버 웹 딥링크: $webDeepLinkUrlWithCode');

      // 카카오톡 템플릿 구성 - 리틀뱅크 전용
      final TextTemplate template = TextTemplate(
        text: '''
🏦✨ 리틀뱅크에서 함께 경제 공부해요! ✨

친구야, 나와 함께 용돈 관리하고 
경제 상식도 늘려보자! 📈

🎯 미션 완료하고 용돈 받기
📊 랭킹에서 친구들과 경쟁하기  
📝 피드에서 학습 기록 공유하기

🔑 초대 코드: $inviteCode

#리틀뱅크 #경제교육 #용돈관리 #친구초대
        ''',
        link: Link(
          // 서버 웹 딥링크 (서버에서 앱 딥링크 처리)
          webUrl: Uri.parse(webDeepLinkUrlWithCode),
          mobileWebUrl: Uri.parse(webDeepLinkUrlWithCode),
        ),
        buttonTitle: '🏦 리틀뱅크 시작하기',
        buttons: [
          Button(
            title: '🏦 리틀뱅크 시작하기',
            link: Link(
              // 서버 웹 딥링크 (서버에서 앱 딥링크 처리)
              webUrl: Uri.parse(webDeepLinkUrlWithCode),
              mobileWebUrl: Uri.parse(webDeepLinkUrlWithCode),
            ),
          ),
        ],
      );

      // 카카오톡 공유 시도
      print('📱 카카오톡 공유 시도 중...');
      
      bool isKakaoTalkSharingAvailable = await ShareClient.instance.isKakaoTalkSharingAvailable();
      
      if (isKakaoTalkSharingAvailable) {
        print('✅ 카카오톡 앱이 설치되어 있음 - 카카오톡으로 공유');
        
        Uri uri = await ShareClient.instance.shareDefault(template: template);
        await ShareClient.instance.launchKakaoTalk(uri);
        
        print('✅ 카카오톡 공유 완료');
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('리틀뱅크 초대 메시지를 카카오톡으로 전송했습니다! 🎉'),
              backgroundColor: Colors.blue,
            ),
          );
        }
      } else {
        print('❌ 카카오톡 앱이 설치되어 있지 않음 - 시스템 공유로 대체');
        await _shareViaSystemLittleBank(context, inviteCode);
      }
    } catch (error) {
      print('❌ 카카오톡 공유 실패: $error');
      
      // 카카오톡 공유 실패 시 시스템 공유로 대체
      await _shareViaSystemLittleBank(context, inviteCode);
    }
  }

  // 기존 친구 초대 메시지 공유 (호환성 유지)
  static Future<void> shareInviteMessage({
    required String inviteCode,
    required BuildContext context,
  }) async {
    try {
      // 서버 웹 딥링크 URL (서버에서 JavaScript로 앱 딥링크 처리)
      const String webDeepLinkUrl = 'http://3.34.52.239:8080/deeplink/invite';
      final String webDeepLinkUrlWithCode = '$webDeepLinkUrl?code=$inviteCode';
      
      // 디버깅을 위한 URL 출력
      print('🔗 서버 웹 딥링크: $webDeepLinkUrlWithCode');

      // 카카오톡 템플릿 구성 - 텍스트 중심으로 간단하게
      final TextTemplate template = TextTemplate(
        text: '''
🏦 리틀뱅크에서 함께 경제 공부해요!

친구와 함께 미션을 완료하고 용돈도 받아보세요!

🔑 초대 코드: $inviteCode

📱 아래 버튼을 눌러 시작하세요!

#리틀뱅크 #경제교육 #용돈관리
        ''',
        link: Link(
          // 서버 웹 딥링크 (서버에서 앱 딥링크 처리)
          webUrl: Uri.parse(webDeepLinkUrlWithCode),
          mobileWebUrl: Uri.parse(webDeepLinkUrlWithCode),
        ),
        buttons: [
          Button(
            title: '리틀뱅크 시작하기',
            link: Link(
              // 서버 웹 딥링크 (서버에서 앱 딥링크 처리)
              webUrl: Uri.parse(webDeepLinkUrlWithCode),
              mobileWebUrl: Uri.parse(webDeepLinkUrlWithCode),
            ),
          ),
        ],
      );

      // 카카오톡 설치 여부에 따른 분기 처리
      if (await isKakaoTalkInstalled()) {
        // 카카오톡으로 공유 (모바일에서만 작동)
        Uri uri = await ShareClient.instance.shareDefault(template: template);
        await ShareClient.instance.launchKakaoTalk(uri);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('카카오톡으로 초대 메시지를 보냈습니다!\n(모바일 카카오톡에서 확인해 주세요)'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 4),
            ),
          );
        }
      } else {
        // 카카오톡이 설치되지 않은 경우 시스템 공유로 대체
        await _shareViaSystem(context, inviteCode);
      }
    } catch (error) {
      print('❌ 카카오톡 공유 오류: $error');
      
      if (context.mounted) {
        // 카카오톡 공유 실패 시 시스템 공유로 대체
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('카카오톡 공유에 실패했습니다. 다른 방식으로 공유합니다.'),
            backgroundColor: Colors.orange,
          ),
        );
        await _shareViaSystem(context, inviteCode);
      }
    }
  }

  // 대체 공유 방식 제안
  static Future<void> _showShareAlternatives(
    BuildContext context,
    String inviteCode,
  ) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            '공유 방식 선택',
            style: TextStyle(
              fontFamily: 'Pretendard-Bold',
              fontSize: 18,
            ),
          ),
          content: const Text(
            '카카오톡 공유에 실패했습니다.\n다른 방식으로 친구를 초대하시겠어요?',
            style: TextStyle(
              fontFamily: 'Pretendard-Regular',
              fontSize: 14,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                '취소',
                style: TextStyle(
                  fontFamily: 'Pretendard-Medium',
                  color: Colors.grey,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _shareViaSystem(context, inviteCode);
              },
              child: const Text(
                '다른 앱으로 공유',
                style: TextStyle(
                  fontFamily: 'Pretendard-Medium',
                  color: Colors.blue,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _openPlayStore();
              },
              child: const Text(
                '플레이스토어 열기',
                style: TextStyle(
                  fontFamily: 'Pretendard-Medium',
                  color: Colors.green,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // 리틀뱅크 전용 시스템 공유
  static Future<void> _shareViaSystemLittleBank(
    BuildContext context,
    String inviteCode,
  ) async {
    try {
      // 서버 웹 딥링크
      const String webDeepLinkUrl = 'http://3.34.52.239:8080/deeplink/invite';
      final String webDeepLinkUrlWithCode = '$webDeepLinkUrl?code=$inviteCode';
      
      final String message = '''
🏦✨ 리틀뱅크에서 함께 경제 공부해요! ✨

친구야, 나와 함께 용돈 관리하고 
경제 상식도 늘려보자! 📈

🎯 미션 완료하고 용돈 받기
📊 랭킹에서 친구들과 경쟁하기  
📝 피드에서 학습 기록 공유하기

🌐 시작하기: $webDeepLinkUrlWithCode
🔑 초대 코드: $inviteCode

#리틀뱅크 #경제교육 #용돈관리 #친구초대
      ''';

      // share_plus 패키지를 사용한 시스템 공유
      await Share.share(message, subject: '🏦 리틀뱅크 친구 초대');
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('리틀뱅크 초대 메시지를 공유했습니다! 🎉'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      print('리틀뱅크 시스템 공유 오류: $e');
    }
  }

  // 기존 시스템 공유 사용
  static Future<void> _shareViaSystem(
    BuildContext context,
    String inviteCode,
  ) async {
    try {
      // 서버 웹 딥링크
      const String webDeepLinkUrl = 'http://3.34.52.239:8080/deeplink/invite';
      final String webDeepLinkUrlWithCode = '$webDeepLinkUrl?code=$inviteCode';
      
      final String message = '''
🏦 리틀뱅크에서 함께 경제 공부해요!

친구와 함께 미션을 완료하고 용돈도 받아보세요!

🌐 시작하기: $webDeepLinkUrlWithCode
🔑 초대 코드: $inviteCode

#리틀뱅크 #경제교육 #용돈관리
      ''';

             // share_plus 패키지를 사용한 시스템 공유
       await Share.share(message, subject: '리틀뱅크 친구 초대');
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('시스템 공유를 통해 메시지를 공유했습니다!'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      print('시스템 공유 오류: $e');
    }
  }

  // 플레이스토어 직접 열기
  static Future<void> _openPlayStore() async {
    await DeepLinkService.redirectToPlayStore();
  }

  // 커스텀 템플릿 생성 (필요시 사용)
  static FeedTemplate createCustomTemplate({
    required String inviteCode,
    String? title,
    String? description,
    String? imageUrl,
  }) {
    // 서버 웹 딥링크 URL (서버에서 JavaScript로 앱 딥링크 처리)
    const String webDeepLinkUrl = 'http://3.34.52.239:8080/deeplink/invite';
    final String webDeepLinkUrlWithCode = '$webDeepLinkUrl?code=$inviteCode';
    
    return FeedTemplate(
      content: Content(
        title: title ?? '🏦 리틀뱅크에서 함께 경제 공부해요!',
        description: description ?? '친구와 함께 미션을 완료하고 용돈도 받아보세요!\n초대 코드: $inviteCode',
        imageUrl: Uri.parse(imageUrl ?? 'https://play-lh.googleusercontent.com/DKdXXE8-4rJCxOLASVJ3mKZYFfLVGT5I8z7QCXlLMlL7tL7L_1I'),
        link: Link(
          // 서버 웹 딥링크 (서버에서 앱 딥링크 처리)
          webUrl: Uri.parse(webDeepLinkUrlWithCode),
          mobileWebUrl: Uri.parse(webDeepLinkUrlWithCode),
        ),
      ),
      buttons: [
        Button(
          title: '리틀뱅크 시작하기',
          link: Link(
            // 서버 웹 딥링크 (서버에서 앱 딥링크 처리)
            webUrl: Uri.parse(webDeepLinkUrlWithCode),
            mobileWebUrl: Uri.parse(webDeepLinkUrlWithCode),
          ),
        ),
      ],
    );
  }

  // 여러 개의 개별 쿠폰 코드를 연속으로 공유 (새로운 메서드)
  static Future<bool> shareMultipleIndividualCodes({
    required List<String> codes,
    required BuildContext context,
    int? totalSeats,
  }) async {
    try {
      print('===== 여러 개별 쿠폰 코드 연속 전송 시작 =====');
      print('📦 쿠폰 코드 수: ${codes.length}');

      if (codes.isEmpty) {
        print('❌ 전송할 코드가 없습니다.');
        return false;
      }

      // 사용자에게 안내 메시지 표시
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '🔄 ${codes.length}개의 코드를 연속으로 카카오톡에 공유합니다.\n각 코드마다 공유 대상을 선택해주세요!',
            ),
            backgroundColor: Colors.blue,
            duration: const Duration(seconds: 4),
          ),
        );
      }

      int successCount = 0;
      
      // 각 코드를 개별적으로 연속 공유
      for (int i = 0; i < codes.length; i++) {
        final code = codes[i];
        final recipientName = '가족 ${i + 1}';
        
        print('📤 [연속공유] ${i+1}/${codes.length}: $code -> $recipientName');
        
        try {
          // 각 코드마다 개별 공유 실행 (사용자가 매번 대상 선택)
          final success = await shareIndividualInviteCode(
            inviteCode: code,
            recipientName: recipientName,
            context: context,
            totalSeats: totalSeats,
            currentIndex: i + 1,
            totalCount: codes.length,
          );
          
          if (success) {
            successCount++;
            print('✅ [연속공유] ${i+1}/${codes.length}: $code 전송 성공');
          } else {
            print('❌ [연속공유] ${i+1}/${codes.length}: $code 전송 실패');
          }
          
          // 다음 공유 전 잠깐 대기 (사용자가 대상을 선택할 시간 제공)
          if (i < codes.length - 1) {
            await Future.delayed(const Duration(milliseconds: 2000));
          }
        } catch (e) {
          print('❌ [연속공유] ${i+1}/${codes.length}: $code 전송 중 오류 - $e');
        }
      }

      // 최종 결과 표시
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              successCount == codes.length
                ? '🎉 ${codes.length}개의 쿠폰 코드를 모두 카카오톡으로 전송했습니다!'
                : '⚠️ ${successCount}개의 쿠폰 코드를 전송했습니다. (총 ${codes.length}개 중)',
            ),
            backgroundColor: successCount == codes.length ? Colors.green : Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      
      print('🏁 [연속공유] 전송 완료: $successCount/${codes.length} 성공');
      return successCount > 0;
      
    } catch (e) {
      print('❌ [연속공유] 오류: $e');
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('연속 전송 중 오류가 발생했습니다.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      
      return false;
    }
  }

  // 모든 남은 코드를 하나의 메시지로 공유
  static Future<bool> shareAllCodesInOneMessage({
    required List<String> codes,
    required BuildContext context,
    int? totalSeats,
  }) async {
    try {
      print('===== 모든 코드 통합 메시지 전송 시작 =====');
      print('📦 전송할 코드들: $codes');
      print('📊 코드 수: ${codes.length}');

      if (codes.isEmpty) {
        print('❌ 전송할 코드가 없습니다.');
        return false;
      }

      // 서버 웹 딥링크 URL (첫 번째 코드로 설정)
      const String webDeepLinkUrl = 'http://3.34.52.239:8080/deeplink/invite';
      final String webDeepLinkUrlWithCode = '$webDeepLinkUrl?code=${codes.first}';

      // 코드 목록 생성
      String codesList = '';
      for (int i = 0; i < codes.length; i++) {
        codesList += '${i + 1}. ${codes[i]}\n';
      }

      // 카카오톡 템플릿 구성
      final TextTemplate template = TextTemplate(
        text: '''
🎉 리틀뱅크 가족 구독권 초대코드가 도착했어요!

안녕하세요! 👋
리틀뱅크 가족 구독권에 초대드립니다.

🎫 사용 가능한 초대코드들:
$codesList
💡 위 코드 중 하나를 선택해서 사용하세요!
   (한 사람당 하나의 코드만 사용 가능)

🏦 함께 경제 공부하고 성장해요!
📈 미션 완료하고 용돈도 받아보세요
👨‍👩‍👧‍👦 가족과 함께 더 재미있게!

💙 함께 리틀뱅크에서 경제 습관을 만들어봐요!

#리틀뱅크 #가족구독권 #경제교육 #용돈관리
        ''',
        link: Link(
          webUrl: Uri.parse(webDeepLinkUrlWithCode),
          mobileWebUrl: Uri.parse(webDeepLinkUrlWithCode),
        ),
        buttons: [
          Button(
            title: '🏦 리틀뱅크 시작하기',
            link: Link(
              webUrl: Uri.parse(webDeepLinkUrlWithCode),
              mobileWebUrl: Uri.parse(webDeepLinkUrlWithCode),
            ),
          ),
        ],
      );

      // 카카오톡 공유 시도
      print('📱 카카오톡 공유 시도 중...');
      
      bool isKakaoTalkSharingAvailable = await ShareClient.instance.isKakaoTalkSharingAvailable();
      
      if (isKakaoTalkSharingAvailable) {
        print('✅ 카카오톡 앱이 설치되어 있음 - 모든 코드 통합 전송');
        
        Uri uri = await ShareClient.instance.shareDefault(template: template);
        await ShareClient.instance.launchKakaoTalk(uri);
        
        print('✅ 모든 코드 카카오톡 공유 완료');
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${codes.length}개의 초대코드를 카카오톡으로 전송했습니다! 🎉\n각자 원하는 코드를 선택해서 사용할 수 있어요.'),
              backgroundColor: Colors.blue,
              duration: const Duration(seconds: 4),
            ),
          );
        }
        
        return true;
      } else {
        print('❌ 카카오톡 앱이 설치되어 있지 않음 - 시스템 공유로 대체');
        return await _shareAllCodesViaSystem(context, codes, totalSeats);
      }
    } catch (error) {
      print('❌ 모든 코드 카카오톡 공유 실패: $error');
      
      // 카카오톡 공유 실패 시 시스템 공유로 대체
      return await _shareAllCodesViaSystem(context, codes, totalSeats);
    }
  }

  // 모든 코드 시스템 공유 (대체 방법)
  static Future<bool> _shareAllCodesViaSystem(
    BuildContext context,
    List<String> codes,
    int? totalSeats,
  ) async {
    try {
      print('🌐 모든 코드 시스템 공유 시작');
      print('📦 코드들: $codes');
      
      // 서버 웹 딥링크
      const String webDeepLinkUrl = 'http://3.34.52.239:8080/deeplink/invite';
      final String webDeepLinkUrlWithCode = '$webDeepLinkUrl?code=${codes.first}';
      
      // 코드 목록 생성
      String codesList = '';
      for (int i = 0; i < codes.length; i++) {
        codesList += '${i + 1}. ${codes[i]}\n';
      }
      
      final String message = '''
🎉 리틀뱅크 가족 구독권 초대코드가 도착했어요!

안녕하세요! 👋
리틀뱅크 가족 구독권에 초대드립니다.

🎫 사용 가능한 초대코드들:
$codesList
💡 위 코드 중 하나를 선택해서 사용하세요!
   (한 사람당 하나의 코드만 사용 가능)

🏦 함께 경제 공부하고 성장해요!
📈 미션 완료하고 용돈도 받아보세요
👨‍👩‍👧‍👦 가족과 함께 더 재미있게!

🌐 시작하기: $webDeepLinkUrlWithCode

💙 함께 리틀뱅크에서 경제 습관을 만들어봐요!

#리틀뱅크 #가족구독권 #경제교육 #용돈관리
      ''';

      // share_plus 패키지를 사용한 시스템 공유
      await Share.share(message, subject: '🏦 리틀뱅크 가족 구독권 초대코드 ${codes.length}개');
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${codes.length}개의 초대코드를 전송했습니다! 🎉\n각자 원하는 코드를 선택해서 사용할 수 있어요.'),
            backgroundColor: Colors.blue,
            duration: const Duration(seconds: 4),
          ),
        );
      }
      
      return true;
    } catch (e) {
      print('❌ 모든 코드 시스템 공유 오류: $e');
      return false;
    }
  }

  // 피드 스크린샷 공유 기능
  static Future<bool> shareFeedScreenshot({
    required GlobalKey repaintBoundaryKey,
    required String feedTitle,
    required String feedUrl,
    required BuildContext context,
  }) async {
    try {
      print('===== 피드 스크린샷 공유 시작 =====');
      print('🖼️ 피드 제목: $feedTitle');
      print('🔗 피드 URL: $feedUrl');

      // 1. 스크린샷 캡처
      final imageFile = await _captureScreenshot(repaintBoundaryKey);
      if (imageFile == null) {
        print('❌ 스크린샷 캡처 실패');
        return false;
      }

      print('✅ 스크린샷 캡처 완료: ${imageFile.path}');

      // 2. 카카오톡 이미지 템플릿 생성 (로컬 파일 사용)
      final template = TextTemplate(
        text: '''
🎉 리틀뱅크 피드를 공유합니다!

📝 제목: $feedTitle

리틀뱅크에서 공유된 피드예요!
아래 링크를 클릭해서 확인해보세요 📱

#리틀뱅크 #피드공유
        ''',
        link: Link(
          webUrl: Uri.parse(feedUrl),
          mobileWebUrl: Uri.parse(feedUrl),
        ),
        buttons: [
          Button(
            title: '🏦 피드 보러가기',
            link: Link(
              webUrl: Uri.parse(feedUrl),
              mobileWebUrl: Uri.parse(feedUrl),
            ),
          ),
        ],
      );

      // 3. 이미지와 함께 시스템 공유 우선 사용
      print('📱 피드 스크린샷 시스템 공유 시도 중...');
      
      // 이미지 파일과 함께 시스템 공유 시도
      bool systemShareSuccess = await _shareFeedScreenshotViaSystem(context, imageFile, feedTitle, feedUrl);
      
      if (systemShareSuccess) {
        print('✅ 피드 스크린샷 시스템 공유 완료');
        return true;
      } else {
        print('❌ 시스템 공유 실패 - 카카오톡 텍스트 공유로 대체');
        
        // 시스템 공유 실패 시 카카오톡 텍스트 공유
        bool isKakaoTalkSharingAvailable = await ShareClient.instance.isKakaoTalkSharingAvailable();
        
        if (isKakaoTalkSharingAvailable) {
          print('✅ 카카오톡 앱이 설치되어 있음 - 텍스트 공유');
          
          Uri uri = await ShareClient.instance.shareDefault(template: template);
          await ShareClient.instance.launchKakaoTalk(uri);
          
          print('✅ 피드 스크린샷 카카오톡 텍스트 공유 완료');
          
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('피드 링크를 카카오톡으로 공유했습니다! 📱'),
                backgroundColor: Colors.blue,
              ),
            );
          }
          
          return true;
        } else {
          print('❌ 카카오톡도 사용 불가');
          return false;
        }
      }
    } catch (error) {
      print('❌ 피드 스크린샷 카카오톡 공유 실패: $error');
      
      // 카카오톡 공유 실패 시 시스템 공유로 대체
      return await _shareFeedScreenshotViaSystem(context, null, feedTitle, feedUrl);
    }
  }

  // 스크린샷 캡처 함수
  static Future<File?> _captureScreenshot(GlobalKey repaintBoundaryKey) async {
    try {
      // RepaintBoundary에서 이미지 캡처
      RenderRepaintBoundary boundary = repaintBoundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      
      // 높은 해상도로 이미지 캡처
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      
      // 이미지를 Uint8List로 변환
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        print('❌ 이미지 데이터 변환 실패');
        return null;
      }
      
      Uint8List pngBytes = byteData.buffer.asUint8List();
      
      // 임시 디렉토리에 파일 저장
      Directory tempDir = await getTemporaryDirectory();
      String fileName = 'feed_screenshot_${DateTime.now().millisecondsSinceEpoch}.png';
      File file = File('${tempDir.path}/$fileName');
      
      await file.writeAsBytes(pngBytes);
      
      print('✅ 스크린샷 저장 완료: ${file.path}');
      return file;
    } catch (e) {
      print('❌ 스크린샷 캡처 오류: $e');
      return null;
    }
  }

  // 피드 스크린샷 시스템 공유 (대체 방법)
  static Future<bool> _shareFeedScreenshotViaSystem(
    BuildContext context,
    File? imageFile,
    String feedTitle,
    String feedUrl,
  ) async {
    try {
      print('🌐 피드 스크린샷 시스템 공유 시작');
      
      final String message = '''
🎉 리틀뱅크 피드를 공유합니다!

📝 제목: $feedTitle

🌐 피드 보러가기: $feedUrl

#리틀뱅크 #피드공유
      ''';

      if (imageFile != null && await imageFile.exists()) {
        // 이미지 파일이 있으면 이미지와 함께 공유
        await Share.shareXFiles(
          [XFile(imageFile.path)],
          text: message,
          subject: '🏦 리틀뱅크 피드 공유',
        );
      } else {
        // 이미지가 없으면 텍스트만 공유
        await Share.share(message, subject: '🏦 리틀뱅크 피드 공유');
      }
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('피드를 공유했습니다! 📱'),
            backgroundColor: Colors.blue,
          ),
        );
      }
      
      return true;
    } catch (e) {
      print('❌ 피드 스크린샷 시스템 공유 오류: $e');
      return false;
    }
  }
} 