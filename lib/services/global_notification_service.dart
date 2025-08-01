import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/child/notice_modal/gift_subscription_modal.dart';
import '../screens/child/notice_modal/analysis_report_modal.dart';
import '../screens/child/notice_modal/mission_complete_modal.dart';
import '../screens/child/notice_modal/mission_reward_approved_modal.dart';
import '../screens/child/mission_screen.dart';
import '../screens/child/feed_screen.dart';
import '../screens/child/my_page_screen.dart';
import '../screens/child/my/activity_history_screen.dart';
import 'subscription_service.dart';
import 'mission_service.dart';
import 'auth_service.dart';
import 'payment_service.dart';

class GlobalNotificationService {
  static final GlobalNotificationService _instance = GlobalNotificationService._internal();
  factory GlobalNotificationService() => _instance;
  GlobalNotificationService._internal();

  // 싱글톤 인스턴스 접근
  static GlobalNotificationService get instance => _instance;

  // 현재 체크 중인지 확인하는 플래그
  bool _isChecking = false;
  
  // 마지막 체크 시간을 저장하여 너무 자주 체크하지 않도록 함
  DateTime? _lastCheckTime;

  /// 모든 알림을 순차적으로 확인하고 표시
  Future<void> checkAndShowAllNotifications(BuildContext context) async {
    // 이미 체크 중이거나 최근에 체크했다면 스킵
    if (_isChecking) return;
    
    final now = DateTime.now();
    if (_lastCheckTime != null && 
        now.difference(_lastCheckTime!).inMinutes < 5) {
      return; // 5분 이내에는 재체크하지 않음
    }

    _isChecking = true;
    _lastCheckTime = now;

    try {
      // UI가 완전히 로드된 후 알림 확인
      await Future.delayed(const Duration(milliseconds: 800));
      
      if (!context.mounted) return;

      // 1. 미션 보상금 승인 알림 확인
      await _checkNewMissionRewards(context);
      
      if (!context.mounted) return;
      
      // 2. 미션 완료 알림 확인
      await _checkMissionCompletion(context);
      
      if (!context.mounted) return;
      
      // 3. 구독권 선물 알림 확인  
      await _checkGiftSubscriptions(context);
      
      if (!context.mounted) return;
      
      // 4. 분석 리포트 알림 확인
      await _checkNewAnalysisReport(context);
      
    } catch (e) {
      print('글로벌 알림 확인 중 오류 발생: $e');
    } finally {
      _isChecking = false;
    }
  }

  /// 새로 승인된 미션/챌린지 보상금 확인 (받은 포인트 내역 기반)
  Future<void> _checkNewMissionRewards(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final shownRewardHistoryIds = prefs.getStringList('shown_reward_history_ids') ?? [];
      
      print('🔔 미션/챌린지 보상금 확인 시작');
      
      // 받은 포인트 내역 조회 (최근 내역부터)
      final receivedHistory = await PaymentService.getReceivedPointHistory(pageNumber: 0);
      
      if (receivedHistory != null && receivedHistory['data'] != null) {
        final List<dynamic> historyList = receivedHistory['data'];
        print('🔔 받은 포인트 내역 개수: ${historyList.length}');
        
        // 미션 또는 챌린지 보상인 새로운 내역 찾기
        for (final history in historyList) {
          if (history is Map<String, dynamic>) {
            final historyId = history['historyId']?.toString() ?? '';
            final rewardType = history['rewardType'] ?? '';
            final message = history['message'] ?? '';
            
            print('🔔 내역 확인: ID=$historyId, 타입=$rewardType, 메시지=$message');
            
            // 이미 표시한 내역인지 확인
            if (shownRewardHistoryIds.contains(historyId)) {
              print('🔔 이미 표시한 내역: $historyId');
              continue;
            }
            
            // 미션 또는 챌린지 보상인지 확인
            if (rewardType == 'MISSION' || rewardType == 'CHALLENGE') {
              print('🔔 새로운 보상 발견: $rewardType - $message');
              
              // 미션 이름 추출 (메시지에서)
              String rewardName = _extractRewardNameFromMessage(message, rewardType);
              
              if (context.mounted) {
                // 보상금 승인 모달 표시
                final result = await MissionRewardApprovedModal.show(
                  context,
                  missionName: rewardName,
                );
                
                if (result == true && context.mounted) {
                  print('✅ 보상 모달에서 미션 화면으로 이동 선택됨');
                  // 미션 화면으로 이동
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const MissionScreen()),
                  );
                }
                
                // 표시된 내역 ID 저장
                shownRewardHistoryIds.add(historyId);
                await prefs.setStringList('shown_reward_history_ids', shownRewardHistoryIds);
                
                print('🔔 보상금 승인 알림 표시 완료: $rewardName');
                
                // 한 번에 하나씩만 표시
                break;
              }
            }
          }
        }
      }
      
      print('🔔 미션/챌린지 보상금 확인 완료');
    } catch (e) {
      print('🔔 미션 보상금 알림 확인 오류: $e');
    }
  }
  
  /// 메시지에서 보상 이름 추출
  String _extractRewardNameFromMessage(String message, String rewardType) {
    try {
      if (rewardType == 'MISSION') {
        // "OO 미션 완료 보상" 형태에서 미션명 추출
        final missionMatch = RegExp(r'(.+?)\s*미션\s*완료\s*보상').firstMatch(message);
        if (missionMatch != null) {
          return missionMatch.group(1)?.trim() ?? '미션';
        }
      } else if (rewardType == 'CHALLENGE') {
        // "OO 챌린지 챌린지 완료 보상" 형태에서 챌린지명 추출
        final challengeMatch = RegExp(r'(.+?)\s*챌린지\s*챌린지\s*완료\s*보상').firstMatch(message);
        if (challengeMatch != null) {
          return challengeMatch.group(1)?.trim() ?? '챌린지';
        }
        // "OO 챌린지 완료 보상" 형태도 시도
        final challengeMatch2 = RegExp(r'(.+?)\s*챌린지\s*완료\s*보상').firstMatch(message);
        if (challengeMatch2 != null) {
          return challengeMatch2.group(1)?.trim() ?? '챌린지';
        }
      }
      
      // 추출 실패 시 기본값
      return rewardType == 'MISSION' ? '미션' : '챌린지';
    } catch (e) {
      print('보상 이름 추출 오류: $e');
      return rewardType == 'MISSION' ? '미션' : '챌린지';
    }
  }

  /// 미션 완료 알림 확인
  Future<void> _checkMissionCompletion(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final shownCompletions = prefs.getStringList('shown_mission_completions') ?? [];
      
      // 현재 사용자의 미션 정보 가져오기
      final missionsData = await MissionService.getChildMissions(page: 0);
      
      if (missionsData != null && missionsData['data'] != null) {
        final List<dynamic> missionList = missionsData['data'];
        
        // 미션 응답 객체로 변환
        final List<MissionResponse> allMissions = missionList
            .map((missionJson) => MissionResponse.fromJson(missionJson))
            .toList();
        
                 // 오늘 완료된 미션 중 아직 알림을 표시하지 않은 것 찾기
         final today = DateTime.now();
         final completedMissions = allMissions.where((mission) {
           final isCompleted = mission.status == MissionStatus.ACHIEVEMENT;
           final isToday = mission.endDate.year == today.year &&
                          mission.endDate.month == today.month &&
                          mission.endDate.day == today.day;
           final notShown = !shownCompletions.contains(mission.missionId.toString());
           
           return isCompleted && isToday && notShown;
         }).toList();
        
        if (completedMissions.isNotEmpty && context.mounted) {
          // 미션 완료 모달 표시
          final result = await MissionCompleteModal.show(context);
          
          if (result == true && context.mounted) {
            print('피드에 자랑하러 가기 선택됨');
            // 활동 내역 화면으로 이동
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const ActivityHistoryScreen()),
            );
          }
          
          // 표시된 미션들 저장
          for (final mission in completedMissions) {
            shownCompletions.add(mission.missionId.toString());
          }
          await prefs.setStringList('shown_mission_completions', shownCompletions);
          
          print('미션 완료 알림 표시: ${completedMissions.length}개 미션');
        }
      }
    } catch (e) {
      print('미션 완료 알림 확인 오류: $e');
    }
  }

  /// 구독권 선물 확인
  Future<void> _checkGiftSubscriptions(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSubscriptionId = prefs.getString('last_subscription_id') ?? '';
      
      // 현재 활성 구독권 확인
      final currentSubscription = await SubscriptionService.getCurrentActiveSubscription();
      
      if (currentSubscription != null) {
        final subscriptionData = currentSubscription['data'] as Map<String, dynamic>;
        final currentSubscriptionId = subscriptionData['subscriptionId']?.toString() ?? 
                                     subscriptionData['trialId']?.toString() ?? '';
        
        // 새로운 구독권이 생겼고, 무료 구독권이거나 선물받은 구독권인 경우
        if (currentSubscriptionId.isNotEmpty && 
            currentSubscriptionId != lastSubscriptionId &&
            (currentSubscription['subscriptionType'] == 'free_subscription' ||
             subscriptionData['isGift'] == true)) {
          
          if (context.mounted) {
            await Future.delayed(const Duration(milliseconds: 300));
            
            final result = await GiftSubscriptionModal.show(context);
            
            if (result == true && context.mounted) {
              print('구독권 등록하기 선택됨');
              // 구독권 관련 화면으로 이동 (마이페이지의 구독 관리)
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const MyPageScreen()),
              );
            }
            
            // 현재 구독권 ID 저장
            await prefs.setString('last_subscription_id', currentSubscriptionId);
            
            print('구독권 선물 알림 표시: $currentSubscriptionId');
          }
        } else if (currentSubscriptionId.isNotEmpty && currentSubscriptionId != lastSubscriptionId) {
          // 새로운 구독권이지만 선물이 아닌 경우, ID만 업데이트
          await prefs.setString('last_subscription_id', currentSubscriptionId);
        }
      }
    } catch (e) {
      print('구독권 선물 알림 확인 오류: $e');
    }
  }

  /// 새로운 분석 리포트 확인
  Future<void> _checkNewAnalysisReport(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastReportWeek = prefs.getInt('last_analysis_report_week') ?? 0;
      
      // 현재 주차 계산 (년의 시작부터)
      final now = DateTime.now();
      final yearStart = DateTime(now.year, 1, 1);
      final currentWeek = now.difference(yearStart).inDays ~/ 7;
      
      // 사용자 정보 가져오기
      final userInfo = await AuthService.getUserInfo();
      final userName = userInfo['name'] ?? '사용자';
      
      // 사용자의 활동량 확인 (간단한 조건으로 설정)
      final hasSignificantActivity = await _checkUserActivity();
      
      // 새로운 주차이고 활동이 있으며 월요일인 경우 리포트 생성
      final isMonday = now.weekday == DateTime.monday;
      final hasNewReport = currentWeek > lastReportWeek && 
                          hasSignificantActivity && 
                          isMonday &&
                          currentWeek % 2 == 0; // 격주로
      
      if (hasNewReport && context.mounted) {
        await Future.delayed(const Duration(milliseconds: 300));
        
        final result = await AnalysisReportModal.show(
          context,
          userName: userName,
        );
        
        if (result == true && context.mounted) {
          print('분석 리포트 보러가기 선택됨');
          // 분석 리포트 화면으로 이동 (마이페이지의 활동 내역)
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const ActivityHistoryScreen()),
          );
        }
        
        // 마지막 리포트 주차 저장
        await prefs.setInt('last_analysis_report_week', currentWeek);
        
        print('분석 리포트 알림 표시 - 주차: $currentWeek, 활동: $hasSignificantActivity');
      }
    } catch (e) {
      print('분석 리포트 알림 확인 오류: $e');
    }
  }

  /// 사용자 활동량 확인 (간단한 버전)
  Future<bool> _checkUserActivity() async {
    try {
      // 최근 미션 활동 확인
      final missionsData = await MissionService.getChildMissions(page: 0);
      if (missionsData != null && missionsData['data'] != null) {
        final missions = missionsData['data'] as List<dynamic>;
        return missions.isNotEmpty;
      }
      return false;
    } catch (e) {
      print('사용자 활동량 확인 오류: $e');
      return false;
    }
  }

  /// 테스트용 - 모든 알림을 강제로 리셋
  Future<void> resetAllNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('shown_mission_rewards');
    await prefs.remove('shown_mission_completions');
    await prefs.remove('last_subscription_id');
    await prefs.remove('last_analysis_report_week');
    _lastCheckTime = null;
    print('모든 알림 상태가 리셋되었습니다.');
  }


} 