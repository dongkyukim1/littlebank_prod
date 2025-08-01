import 'package:flutter/material.dart';
import '../../../widgets/parent/bottom_navigation_bar.dart';
import '../../../services/family_service.dart';
import '../../../services/goal_service.dart';
import '../../../services/challenge_service.dart';
import '../../../services/relationship_service.dart';
import '../../../services/auth_service.dart';
import '../home_screen.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';

class ParentNotificationScreen extends StatefulWidget {
  const ParentNotificationScreen({super.key});

  @override
  State<ParentNotificationScreen> createState() =>
      _ParentNotificationScreenState();
}

class _ParentNotificationScreenState extends State<ParentNotificationScreen> {
  final bool _isMissionCardExpanded = false;
  int _selectedTabIndex = 0;
  bool _isLoading = true;
  List<dynamic> _familyInvites = []; // 가족 초대 목록
  List<Map<String, dynamic>> _goalApplications = []; // 목표 신청 목록
  List<Map<String, dynamic>> _challengeApplications = []; // 챌린지 신청 목록
  List<Map<String, dynamic>> _weeklyGoals = []; // 이번 주 아이들의 목표 목록
  int? _familyId; // 가족 ID

  // 완료 알림 목록들
  List<Map<String, dynamic>> _goalCompletions = []; // 목표 완료 알림
  List<Map<String, dynamic>> _challengeCompletions = []; // 챌린지 완료 알림
  List<Map<String, dynamic>> _missionCompletions = []; // 미션 완료 알림

  // 필터 탭 목록
  final List<String> _tabs = ['전체', '초대·요청', '활동 내역', '리워드'];

  // 자녀 선택 관련 변수들 추가
  List<dynamic>? _children; // 자녀 목록
  Map<String, dynamic>? _selectedChild; // 선택된 자녀
  bool _isLoadingChildren = true; // 자녀 목록 로딩 상태

  // 읽음 상태 필터 관련 변수들 추가
  bool _showOnlyUnread = false; // false: 전체, true: 안읽음만

  @override
  void initState() {
    super.initState();
    // 진입 시 자동 새로고침 - 모든 로딩이 완료될 때까지 로딩 상태 유지
    _initializeData();
  }

  // 모든 데이터를 초기화하고 로딩 상태를 관리하는 메서드
  Future<void> _initializeData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 모든 데이터 로딩을 병렬로 실행
      await Future.wait([
        _loadFamilyInfo(),
        _loadChildrenList(),
        _loadFamilyInvites(),
        _loadGoalApplications(),
        _loadChallengeApplications(),
      ]);
    } catch (e) {
      print('데이터 초기화 중 오류 발생: $e');
    } finally {
      // 모든 로딩이 완료되면 로딩 상태 해제
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 모든 데이터를 새로고침하는 메서드 추가
  Future<void> _refreshAllData() async {
    await _initializeData();
  }

  // 가족 정보 로드
  Future<void> _loadFamilyInfo() async {
    try {
      print('===== 가족 정보 로드 시작 =====');

      final familyInfo = await FamilyService.getFamilyInfo();

      if (familyInfo != null) {
        setState(() {
          _familyId = familyInfo['familyId'];
        });

        print('가족 ID: $_familyId');
        print('가족 정보 전체: $familyInfo');

        // 가족 ID를 얻었으면 이번 주 목표 조회
        if (_familyId != null) {
          await _loadWeeklyGoals();
        }
      } else {
        print('가족 정보 조회 실패');
      }

      print('===== 가족 정보 로드 완료 =====');
    } catch (e) {
      print('가족 정보 로드 중 오류 발생: $e');
    }
  }

  // 자녀 목록 로드
  Future<void> _loadChildrenList() async {
    try {
      setState(() {
        _isLoadingChildren = true;
      });

      print('===== 자녀 목록 로드 시작 =====');

      final familyInfo = await FamilyService.getFamilyInfo();

      if (familyInfo != null) {
        final List<dynamic> memberList = familyInfo['memberInfoList'] ?? [];
        print('가족 정보 로드 성공 - 멤버 ${memberList.length}명');

        // 자녀만 필터링
        final children =
            memberList.where((member) => member['role'] == 'CHILD').toList();

        setState(() {
          _children = children;
          _selectedChild =
              children.isNotEmpty ? children[0] : null; // 첫 번째 자녀를 기본 선택
          _isLoadingChildren = false;
        });

        print('자녀 ${children.length}명 로드 완료');
        if (_selectedChild != null) {
          print(
            '기본 선택된 자녀: ${_selectedChild!['nickname'] ?? _selectedChild!['realName']}',
          );
        }
      } else {
        print('가족 정보 조회 실패 또는 가족 정보 없음');
        setState(() {
          _children = [];
          _selectedChild = null;
          _isLoadingChildren = false;
        });
      }

      print('===== 자녀 목록 로드 완료 =====');
    } catch (e) {
      print('자녀 목록 로드 중 오류 발생: $e');
      setState(() {
        _children = [];
        _selectedChild = null;
        _isLoadingChildren = false;
      });
    }
  }

  // 이번 주 아이들의 목표 조회
  Future<void> _loadWeeklyGoals() async {
    try {
      print('===== 이번 주 아이들 목표 조회 시작 =====');

      if (_familyId == null) {
        print('가족 ID가 없어서 목표 조회를 건너뜁니다.');
        return;
      }

      final weeklyGoals = await GoalService.getParentWeeklyGoals(_familyId!);

      if (weeklyGoals != null) {
        // 완료된 목표들을 별도로 필터링
        final completedGoals =
            weeklyGoals.where((goal) {
              final status = goal['status'];
              final endDateStr = goal['endDate'];
              final isRewarded = goal['isRewarded'] ?? false;

              // 이미 보상 받은 경우는 제외
              if (isRewarded) return false;

              // COMPLETED 상태인 경우
              if (status == 'COMPLETED' || status == 'FINISHED') {
                return true;
              }

              // endDate가 끝났고 ACCEPT 상태인 경우
              if (status == 'ACCEPT' && endDateStr != null) {
                try {
                  final endDate = DateTime.parse(endDateStr);
                  final now = DateTime.now();
                  return now.isAfter(endDate);
                } catch (e) {
                  return false;
                }
              }

              return false;
            }).toList();

        // 완료 알림으로 변환
        final completionNotifications =
            completedGoals.map((goal) {
              return {
                'goalId': goal['goalId'],
                'title': goal['title'],
                'category': goal['category'],
                'childName': goal['childNickname'] ?? '자녀',
                'familyMemberId': goal['familyMemberId'],
                'completedAt': goal['endDate'] ?? goal['updatedAt'],
                'reward': goal['reward'] ?? 0,
                'type': 'goal_completion',
                'read': false,
              };
            }).toList();

        setState(() {
          _weeklyGoals = weeklyGoals;
          _goalCompletions = completionNotifications;
        });

        print('이번 주 아이들 목표 ${weeklyGoals.length}개 조회 성공');
        print('목표 완료 알림 ${completionNotifications.length}개 생성');
        if (weeklyGoals.isNotEmpty) {
          print('첫 번째 목표 정보: ${weeklyGoals[0]}');
        }
        print('서버에서 받은 이번 주 목표: $_weeklyGoals');
      } else {
        print('이번 주 아이들 목표 조회 실패 또는 목표 없음');
        setState(() {
          _weeklyGoals = [];
          _goalCompletions = [];
        });
      }

      print('===== 이번 주 아이들 목표 조회 완료 =====');
    } catch (e) {
      print('이번 주 아이들 목표 조회 중 오류 발생: $e');
      setState(() {
        _weeklyGoals = [];
      });
    }
  }

  // 가족 초대 목록 로드
  Future<void> _loadFamilyInvites() async {
    try {
      print('===== 가족 초대 목록 로드 시작 =====');

      final invites = await FamilyService.getReceivedInvites();

      if (invites != null) {
        setState(() {
          _familyInvites = invites;
        });

        print('가족 초대 목록 개수: ${invites.length}');
        if (invites.isNotEmpty) {
          print('첫 번째 초대 정보: ${invites[0]}');
        }
      } else {
        print('가족 초대 목록 조회 실패 또는 초대 없음');
      }

      print('===== 가족 초대 목록 로드 완료 =====');
    } catch (e) {
      print('가족 초대 목록 로드 중 오류 발생: $e');
    }
  }

  // 목표 신청 알림 목록 로드
  Future<void> _loadGoalApplications() async {
    try {
      print('===== 목표 신청 알림 목록 로드 시작 =====');
      print('현재 날짜: ${DateTime.now()}');
      print('6월 2일자 목표 신청 알림 확인 중...');

      final goalApps = await GoalService.getGoalApplicationNotifications();

      if (goalApps != null) {
        setState(() {
          _goalApplications = goalApps;
        });

        print('목표 신청 알림 목록 개수: ${goalApps.length}');
        if (goalApps.isNotEmpty) {
          print('첫 번째 목표 신청 정보: ${goalApps[0]}');

          // 모든 목표 신청 정보 출력
          for (int i = 0; i < goalApps.length; i++) {
            final goalApp = goalApps[i];
            print(
              '목표 신청 $i: ${goalApp['title']} - ${goalApp['childName']} - 시작일: ${goalApp['createdAt']}',
            );
          }
        } else {
          print('⚠️ 목표 신청 알림이 없습니다. 6월 2일자 목표가 REQUESTED 상태인지 확인 필요');
        }
      } else {
        print('목표 신청 알림 목록 조회 실패 또는 신청 없음');
        setState(() {
          _goalApplications = [];
        });

        // 500 에러는 서버 내부 오류이므로 네트워크 오류 메시지 표시하지 않음
        print('목표 신청 알림 조회 실패 - 서버에서 처리 중일 수 있습니다');
      }

      print('===== 목표 신청 알림 목록 로드 완료 =====');
    } catch (e) {
      print('목표 신청 알림 목록 로드 중 오류 발생: $e');
      setState(() {
        _goalApplications = [];
      });

      // 인증 오류인 경우 특별 처리
      if (e.toString().contains('인증') || e.toString().contains('로그인')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('로그인이 만료되었습니다. 다시 로그인해주세요.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        // 기타 오류는 조용히 처리 (서버 500 에러 등)
        print('목표 신청 알림 로드 실패 - 서버 오류일 가능성');

        // 대안으로 이번 주 목표에서 REQUESTED 상태 찾기
        if (_familyId != null) {
          print('대안 방법으로 REQUESTED 상태 목표 찾기 시도...');
          final weeklyGoals = await GoalService.getParentWeeklyGoals(
            _familyId!,
          );
          if (weeklyGoals != null) {
            final requestedGoals =
                weeklyGoals
                    .where((goal) => goal['status'] == 'REQUESTED')
                    .toList();
            if (requestedGoals.isNotEmpty) {
              print('REQUESTED 상태 목표 ${requestedGoals.length}개 발견');
              // 목표 신청 알림 형태로 변환
              final notifications =
                  requestedGoals.map((goal) {
                    return {
                      'goalId': goal['goalId'],
                      'title': goal['title'],
                      'category': goal['category'],
                      'childName': goal['childNickname'],
                      'familyMemberId': goal['familyMemberId'],
                      'createdAt': goal['startDate'],
                      'read': false,
                    };
                  }).toList();

              setState(() {
                _goalApplications = notifications;
              });
            }
          }
        }
      }
    }
  }

  // 챌린지 신청 알림 목록 로드
  Future<void> _loadChallengeApplications() async {
    try {
      print('===== 챌린지 신청 알림 목록 로드 시작 =====');
      print('현재 날짜: ${DateTime.now()}');
      print('챌린지 신청 알림 확인 중...');

      // 가족 정보가 없으면 먼저 로드
      if (_familyId == null) {
        await _loadFamilyInfo();
      }

      // 가족 ID가 있을 때만 진행
      if (_familyId != null) {
        print('가족 ID $_familyId로 챌린지 신청 알림 조회');

        try {
          // FamilyService.getFamilyInfo()를 사용해서 가족 구성원 정보 가져오기
          final familyInfo = await FamilyService.getFamilyInfo();

          if (familyInfo != null && familyInfo['memberInfoList'] != null) {
            final List<dynamic> memberList = familyInfo['memberInfoList'];
            print('가족 구성원 ${memberList.length}명 조회 성공');

            List<Map<String, dynamic>> allChallengeApps = [];

            // 자녀들의 챌린지 조회
            for (var member in memberList) {
              final memberRole = member['role'];
              final memberId = member['userId'];
              final memberName =
                  member['nickname'] ?? member['realName'] ?? '가족구성원';

              // 자녀인 경우에만 챌린지 조회
              if (memberRole == 'CHILD' && memberId != null) {
                print('자녀 $memberName (ID: $memberId)의 챌린지 조회 중...');

                try {
                  final childChallenges =
                      await ChallengeService.getChildChallenges(
                        _familyId!,
                        memberId,
                      );

                  print('=== $memberName (ID: $memberId) 챌린지 API 완전 분석 ===');
                  print(
                    'API 호출 URL: /api-user/challenge/parent/$_familyId/$memberId',
                  );

                  if (childChallenges != null) {
                    print('✅ API 응답 성공');

                    // 이제 toJson 메서드가 있으므로 JSON 인코딩 시도
                    try {
                      print(
                        '📄 API 응답 전체 JSON: ${jsonEncode(childChallenges.toJson())}',
                      );
                    } catch (e) {
                      print('📄 JSON 인코딩 실패: $e');
                    }

                    print('API 응답 구조:');
                    print('  - totalElement: ${childChallenges.totalElement}');
                    print(
                      '  - data 배열 길이: ${childChallenges.data?.length ?? 0}',
                    );
                    print('  - totalPage: ${childChallenges.totalPage}');
                    print('  - pageNumber: ${childChallenges.pageNumber}');

                    // JSON 인코딩 대신 수동으로 구조 출력
                    try {
                      print('  - 응답 객체 타입: ${childChallenges.runtimeType}');
                      print(
                        '  - data 배열 타입: ${childChallenges.data.runtimeType}',
                      );
                      if (childChallenges.data.isNotEmpty) {
                        print(
                          '  - 첫 번째 데이터 타입: ${childChallenges.data[0].runtimeType}',
                        );
                      }
                    } catch (e) {
                      print('  - 객체 구조 분석 실패: $e');
                    }

                    if (childChallenges.data.isNotEmpty) {
                      print('📝 모든 챌린지 데이터 분석:');
                      for (var i = 0; i < childChallenges.data.length; i++) {
                        final challenge = childChallenges.data[i];
                        print(
                          '  [$i] participationId: ${challenge.participationId}',
                        );
                        print('      challengeId: ${challenge.challengeId}');
                        print('      title: "${challenge.title}"');
                        print(
                          '      challengeStatus: "${challenge.challengeStatus}" ${challenge.challengeStatus == 'REQUESTED' ? '🎯 [타겟!]' : ''}',
                        );
                        print('      subject: "${challenge.subject}"');
                        print('      accepted: ${challenge.accepted}');
                        print('      startDate: "${challenge.startDate}"');
                        print('      endDate: "${challenge.endDate}"');
                        print('      reward: ${challenge.reward}');
                        print('      전체 원시 데이터: $challenge');
                        print('  ---');
                      }

                      // REQUESTED 상태 필터링 테스트
                      final requestedList =
                          childChallenges.data
                              .where((c) => c.challengeStatus == 'REQUESTED')
                              .toList();
                      print('🎯 REQUESTED 필터링 결과: ${requestedList.length}개');

                      if (requestedList.isNotEmpty) {
                        print('🔥 REQUESTED 챌린지 발견!');
                        for (var req in requestedList) {
                          print(
                            '  - participationId: ${req.participationId}, title: "${req.title}"',
                          );
                        }

                        // REQUESTED 상태인 챌린지들을 알림으로 변환
                        final notifications =
                            requestedList.map((challenge) {
                              print(
                                '  → REQUESTED 챌린지: ${challenge.title} (participationId: ${challenge.participationId})',
                              );

                              // 🔧 가족 구성원 정보에서 올바른 familyMemberId 찾기
                              final memberInfo = memberList.firstWhere(
                                (m) => m['userId'] == memberId,
                                orElse: () => <String, dynamic>{},
                              );
                              final correctFamilyMemberId =
                                  memberInfo.isNotEmpty
                                      ? memberInfo['familyMemberId']
                                      : memberId;

                              print(
                                '  🔧 userId $memberId → familyMemberId $correctFamilyMemberId',
                              );
                              return {
                                'participationId': challenge.participationId,
                                'challengeId': challenge.challengeId,
                                'title': challenge.title,
                                'subject': challenge.subject,
                                'childName': memberName,
                                'familyMemberId': memberId,
                                'startDate': challenge.startDate,
                                'endDate': challenge.endDate,
                                'startTime': challenge.startTime ?? '09:00',
                                'totalStudyTime': challenge.totalStudyTime,
                                'reward': challenge.reward ?? 0,
                                'challengeStatus':
                                    challenge.challengeStatus ?? 'REQUESTED',
                                'createdAt': challenge.startDate,
                                'read': false,
                              };
                            }).toList();

                        allChallengeApps.addAll(notifications);
                        print(
                          '$memberName의 REQUESTED 챌린지 신청 ${notifications.length}개 추가',
                        );
                      } else {
                        print('❌ REQUESTED 상태 챌린지 없음');
                        print('🔍 모든 상태 목록:');
                        final statuses =
                            childChallenges.data
                                .map((c) => c.challengeStatus)
                                .toSet()
                                .toList();
                        for (var status in statuses) {
                          final count =
                              childChallenges.data
                                  .where((c) => c.challengeStatus == status)
                                  .length;
                          print('   - "$status": ${count}개');
                        }
                      }
                    } else {
                      print('❌ data 배열이 비어있음');
                    }
                  } else {
                    print('❌ API 응답이 null');
                  }
                } catch (e) {
                  print('❌ 가족구성원 $memberName (ID: $memberId) 챌린지 조회 실패: $e');

                  // 서버 에러 타입별 처리
                  if (e.toString().contains(
                        'IncorrectResultSizeDataAccessException',
                      ) ||
                      e.toString().contains('unique result') ||
                      e.toString().contains('2 results were returned')) {
                    print('🔧 서버 중복 데이터 에러 감지 - participationId 기준 조회 필요');
                    print('   → DB에 같은 사용자의 동일 상태 챌린지가 2개 이상 존재');
                    print('   → 서버 쿼리를 findByUserIdAndChallengeStatus에서');
                    print('   → findByUserIdOrderByParticipationIdDesc로 수정 필요');

                    // 임시 해결책: 알려진 participationId로 개별 조회 시도
                    if (memberId == 1) {
                      print(
                        '🔧 userId 1에 대한 대안 조회 시도 - 알려진 participationId 사용',
                      );

                      // DB에서 확인된 participationId들로 개별 조회
                      final knownParticipationIds = [3, 4]; // DB에서 확인된 ID
                      List<Map<String, dynamic>> fallbackChallenges = [];

                      for (final participationId in knownParticipationIds) {
                        try {
                          print(
                            '  → participationId $participationId 개별 조회 시도',
                          );
                          final singleChallenge =
                              await ChallengeService.getRequestedChallenge(
                                participationId,
                              );

                          if (singleChallenge.challengeStatus == 'REQUESTED') {
                            print(
                              '  ✅ participationId $participationId: REQUESTED 상태 확인',
                            );
                            final challengeNotification = {
                              'participationId':
                                  singleChallenge.participationId,
                              'challengeId': singleChallenge.challengeId,
                              'title': singleChallenge.title,
                              'subject': singleChallenge.subject,
                              'childName': memberName,
                              'familyMemberId': memberId,
                              'startDate': singleChallenge.startDate,
                              'endDate': singleChallenge.endDate,
                              'startTime': singleChallenge.startTime,
                              'totalStudyTime': singleChallenge.totalStudyTime,
                              'reward': singleChallenge.reward,
                              'challengeStatus':
                                  singleChallenge.challengeStatus,
                              'createdAt': singleChallenge.startDate,
                              'read': false,
                            };
                            fallbackChallenges.add(challengeNotification);
                            print('  ✅ 대안 조회 성공: ${singleChallenge.title}');
                          } else {
                            print(
                              '  ⚠️ participationId $participationId: ${singleChallenge.challengeStatus} 상태 (REQUESTED 아님)',
                            );
                          }
                        } catch (participationError) {
                          print(
                            '  ❌ participationId $participationId 조회 실패: $participationError',
                          );
                        }
                      }

                      if (fallbackChallenges.isNotEmpty) {
                        allChallengeApps.addAll(fallbackChallenges);
                        print(
                          '🎯 대안 방법으로 REQUESTED 챌린지 ${fallbackChallenges.length}개 추가 성공!',
                        );
                      } else {
                        print('🔧 대안 방법으로도 REQUESTED 챌린지를 찾지 못함');
                      }
                    }
                  } else if (e.toString().contains('500')) {
                    print('🔧 서버 내부 오류 (500) - 일시적 문제일 가능성');

                    // userId 1에 대한 500 에러는 중복 데이터 문제일 가능성이 높음
                    if (memberId == 1) {
                      print(
                        '🔧 userId 1에서 500 에러 발생 - 중복 데이터 문제로 추정하여 대안 조회 시도',
                      );

                      // DB에서 확인된 participationId들로 개별 조회
                      final knownParticipationIds = [3, 4]; // DB에서 확인된 ID
                      List<Map<String, dynamic>> fallbackChallenges = [];

                      for (final participationId in knownParticipationIds) {
                        try {
                          print(
                            '  → participationId $participationId 개별 조회 시도',
                          );
                          final singleChallenge =
                              await ChallengeService.getRequestedChallenge(
                                participationId,
                              );

                          if (singleChallenge.challengeStatus == 'REQUESTED') {
                            print(
                              '  ✅ participationId $participationId: REQUESTED 상태 확인',
                            );
                            final challengeNotification = {
                              'participationId':
                                  singleChallenge.participationId,
                              'challengeId': singleChallenge.challengeId,
                              'title': singleChallenge.title,
                              'subject': singleChallenge.subject,
                              'childName': memberName,
                              'familyMemberId': memberId,
                              'startDate': singleChallenge.startDate,
                              'endDate': singleChallenge.endDate,
                              'startTime': singleChallenge.startTime,
                              'totalStudyTime': singleChallenge.totalStudyTime,
                              'reward': singleChallenge.reward,
                              'challengeStatus':
                                  singleChallenge.challengeStatus,
                              'createdAt': singleChallenge.startDate,
                              'read': false,
                            };
                            fallbackChallenges.add(challengeNotification);
                            print(
                              '  ✅ 500 에러 대안 조회 성공: ${singleChallenge.title}',
                            );
                          } else {
                            print(
                              '  ⚠️ participationId $participationId: ${singleChallenge.challengeStatus} 상태 (REQUESTED 아님)',
                            );
                          }
                        } catch (participationError) {
                          print(
                            '  ❌ participationId $participationId 조회 실패: $participationError',
                          );
                        }
                      }

                      if (fallbackChallenges.isNotEmpty) {
                        allChallengeApps.addAll(fallbackChallenges);
                        print(
                          '🎯 500 에러 대안 방법으로 REQUESTED 챌린지 ${fallbackChallenges.length}개 추가 성공!',
                        );
                      } else {
                        print('🔧 500 에러 대안 방법으로도 REQUESTED 챌린지를 찾지 못함');
                      }
                    }
                  }

                  // 개별 자녀 조회 실패해도 다른 자녀는 계속 처리
                  continue;
                }
              }
            }

            // 만약 개별 조회로 찾지 못했다면 대안 방법 시도
            if (allChallengeApps.isEmpty) {
              print('개별 자녀 조회로 REQUESTED 챌린지를 찾지 못함. 대안 방법 시도...');

              try {
                // 내가 참여한 챌린지에서 REQUESTED 상태 찾기
                final myChallenges = await ChallengeService.getMyChallenges(
                  challengeStatus: ChallengeStatus.ONGOING,
                  page: 0,
                );

                if (myChallenges.data.isNotEmpty) {
                  print('내 챌린지 ${myChallenges.data.length}개 조회됨');

                  // REQUESTED 상태 필터링
                  final requestedFromMy =
                      myChallenges.data
                          .where(
                            (challenge) =>
                                challenge.challengeStatus == 'REQUESTED',
                          )
                          .toList();

                  print('내 챌린지 중 REQUESTED 상태 ${requestedFromMy.length}개 발견');

                  if (requestedFromMy.isNotEmpty) {
                    final notifications =
                        requestedFromMy.map((challenge) {
                          return {
                            'participationId':
                                challenge.participationId ??
                                challenge.challengeId,
                            'challengeId': challenge.challengeId,
                            'title': challenge.title,
                            'subject': challenge.subject,
                            'childName': '자녀',
                            'startDate': challenge.startDate,
                            'endDate': challenge.endDate,
                            'startTime': challenge.startTime ?? '09:00',
                            'totalStudyTime': challenge.totalStudyTime,
                            'reward': challenge.reward ?? 0,
                            'challengeStatus':
                                challenge.challengeStatus ?? 'REQUESTED',
                            'createdAt': challenge.startDate,
                            'read': false,
                          };
                        }).toList();

                    allChallengeApps.addAll(notifications);
                    print('대안 방법으로 챌린지 신청 ${notifications.length}개 추가');
                  }
                }
              } catch (e) {
                print('대안 방법도 실패: $e');
              }
            }

            // 완료된 챌린지도 함께 조회
            await _loadCompletedChallenges(memberList);

            setState(() {
              _challengeApplications = allChallengeApps;
            });

            print('총 챌린지 신청 알림 ${allChallengeApps.length}개 생성');
            if (allChallengeApps.isNotEmpty) {
              print(
                '첫 번째 챌린지 신청: ${allChallengeApps[0]['title']} - ${allChallengeApps[0]['childName']}',
              );
            } else {
              print('⚠️ REQUESTED 상태의 챌린지 신청이 없습니다.');
            }
            print('===== 챌린지 신청 알림 목록 로드 완료 =====');
            return;
          } else {
            print('가족 구성원 정보를 가져올 수 없음');
          }
        } catch (e) {
          print('가족 구성원 조회 실패: $e');
        }
      }

      // 실패한 경우 빈 목록으로 설정
      print('⚠️ 챌린지 신청 알림을 찾을 수 없습니다.');
      setState(() {
        _challengeApplications = [];
      });

      print('===== 챌린지 신청 알림 목록 로드 완료 (알림 없음) =====');
    } catch (e) {
      print('챌린지 신청 알림 목록 로드 중 오류 발생: $e');
      setState(() {
        _challengeApplications = [];
      });

      // 인증 오류인 경우 특별 처리
      if (e.toString().contains('인증') || e.toString().contains('로그인')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('로그인이 만료되었습니다. 다시 로그인해주세요.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        // 기타 오류는 조용히 처리 (서버 500 에러 등)
        print('챌린지 신청 알림 로드 실패 - 서버 오류일 가능성');
      }
    }
  }

  // 완료된 챌린지 로드
  Future<void> _loadCompletedChallenges(List<dynamic> memberList) async {
    try {
      print('===== 완료된 챌린지 조회 시작 =====');

      List<Map<String, dynamic>> allCompletions = [];

      // 각 자녀별로 완료된 챌린지 조회
      for (var member in memberList) {
        final memberRole = member['role'];
        final memberId = member['userId'];
        final memberName = member['nickname'] ?? member['realName'] ?? '가족구성원';

        // 자녀인 경우에만 챌린지 조회
        if (memberRole == 'CHILD' && memberId != null) {
          print('자녀 $memberName (ID: $memberId)의 완료된 챌린지 조회 중...');

          try {
            final childChallenges = await ChallengeService.getChildChallenges(
              _familyId!,
              memberId,
            );

            if (childChallenges != null && childChallenges.data.isNotEmpty) {
              // 완료된 챌린지들 필터링
              final completedChallenges =
                  childChallenges.data.where((challenge) {
                    final status = challenge.challengeStatus;
                    final isRewarded = challenge.isRewarded;

                    print(
                      '🔍 챌린지 "${challenge.title}" 상태 확인: status=$status, isRewarded=$isRewarded',
                    );

                    // 이미 보상 받은 경우는 제외
                    if (isRewarded) {
                      print('  → ❌ 제외: 이미 보상 받음');
                      return false;
                    }

                    // ACHIEVEMENT 상태는 완료
                    if (status == 'ACHIEVEMENT') {
                      print('  → ✅ 완료: ACHIEVEMENT 상태');
                      return true;
                    }

                    // ACCEPT 상태이면서 기간이 만료된 경우도 완료
                    if (status == 'ACCEPT' && challenge.endDate.isNotEmpty) {
                      try {
                        final endDate = DateTime.parse(challenge.endDate);
                        final now = DateTime.now();
                        final isExpired = now.isAfter(endDate);
                        print(
                          '  → ${isExpired ? "✅ 완료" : "⏳ 진행중"}: ACCEPT 상태, 기간만료=$isExpired (endDate: ${challenge.endDate})',
                        );
                        return isExpired;
                      } catch (e) {
                        print('  → ❌ 제외: 날짜 파싱 오류 $e');
                        return false;
                      }
                    }

                    print('  → ❌ 제외: 조건 불만족');
                    return false;
                  }).toList();

              print('$memberName의 완료된 챌린지 ${completedChallenges.length}개 발견');

              // 완료 알림으로 변환
              for (var challenge in completedChallenges) {
                final completion = {
                  'participationId': challenge.participationId,
                  'challengeId': challenge.challengeId,
                  'title': challenge.title,
                  'subject': challenge.subject ?? '',
                  'childName': memberName,
                  'familyMemberId': memberId,
                  'completedAt': challenge.endDate,
                  'reward': challenge.reward,
                  'challengeStatus': challenge.challengeStatus,
                  'finishScore': challenge.finishScore,
                  'type': 'challenge_completion',
                  'read': false,
                };
                allCompletions.add(completion);
                print('🎉 완료 알림 생성: ${challenge.title} - $memberName');
              }
            } else {
              print('$memberName의 챌린지 데이터가 비어있습니다.');
            }
          } catch (e) {
            print('❌ $memberName의 챌린지 조회 중 오류: $e');
            continue;
          }
        }
      }

      setState(() {
        _challengeCompletions = allCompletions;
      });

      print('🎯 총 챌린지 완료 알림 ${allCompletions.length}개 생성');
      print('===== 완료된 챌린지 조회 완료 =====');
    } catch (e) {
      print('❌ 완료된 챌린지 조회 중 오류: $e');
      setState(() {
        _challengeCompletions = [];
      });
    }
  }

  // 목표 신청 수락 처리
  Future<void> _acceptGoalApplication(int goalId) async {
    try {
      setState(() {
        _isLoading = true;
      });

      print('목표 신청 수락 처리 시작 - goalId: $goalId');

      // 먼저 해당 목표의 종료 날짜 확인
      final goal = _findGoalById(goalId);
      if (goal != null) {
        final String? endDateStr = goal['endDate'];
        if (endDateStr != null) {
          try {
            final DateTime endDate = DateTime.parse(endDateStr);
            final DateTime now = DateTime.now();

            if (now.isAfter(endDate)) {
              // 종료 날짜가 지난 경우 바로 에러 표시
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('미션 수행 날짜가 지났습니다. 새로운 목표를 신청해주세요.'),
                  backgroundColor: Colors.orange,
                  duration: Duration(seconds: 3),
                ),
              );

              setState(() {
                _isLoading = false;
              });
              return;
            }
          } catch (e) {
            print('날짜 파싱 오류: $e');
          }
        }
      }

      final result = await GoalService.acceptGoalApplication(goalId);

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );

        // 목표 신청 목록 다시 로드
        await _loadGoalApplications();
        // 이번 주 목표 목록도 다시 로드
        if (_familyId != null) {
          await _loadWeeklyGoals();
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('목표 신청 수락 처리 중 오류: $e');

      // 날짜 관련 에러인지 확인
      String errorMessage = e.toString().replaceAll('Exception: ', '');
      Color backgroundColor = Colors.red;

      if (errorMessage.contains('미션 수행 날짜가 지났습니다')) {
        backgroundColor = Colors.orange;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: backgroundColor,
          duration: const Duration(seconds: 3),
        ),
      );

      setState(() {
        _isLoading = false;
      });
    }
  }

  // 목표 신청 거절 처리
  Future<void> _rejectGoalApplication(int goalId) async {
    try {
      setState(() {
        _isLoading = true;
      });

      print('목표 신청 거절 처리 시작 - goalId: $goalId');

      final result = await GoalService.rejectGoalApplication(goalId);

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );

        // 목표 신청 목록 다시 로드
        await _loadGoalApplications();
        // 이번 주 목표 목록도 다시 로드
        if (_familyId != null) {
          await _loadWeeklyGoals();
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('목표 신청 거절 처리 중 오류: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('목표 거절 중 오류가 발생했습니다: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );

      setState(() {
        _isLoading = false;
      });
    }
  }

  // 가족 초대 처리
  Future<void> _processFamilyInvite(int familyMemberId) async {
    try {
      setState(() {
        _isLoading = true;
      });

      print('가족 초대 처리 시작 - familyMemberId: $familyMemberId');

      // 가족 초대 처리 로직 호출
      final result = await FamilyService.processInvitation(familyMemberId);

      if (result['success']) {
        // 초대 처리 성공
        if (result['needWarning']) {
          // 경고창 표시 필요
          _showFamilyJoinWarningDialog(familyMemberId);
        } else {
          // 바로 성공 처리
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );

          // 초대 목록 다시 로드
          await _loadFamilyInvites();
        }
      } else {
        // 처리 실패
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('가족 초대 처리 중 오류: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('초대 처리 중 오류가 발생했습니다: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );

      setState(() {
        _isLoading = false;
      });
    }
  }

  // 가족 가입 경고 다이얼로그 표시
  void _showFamilyJoinWarningDialog(int familyMemberId) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              '⚠️ 가족 그룹 전환 경고',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                fontFamily: 'Pretendard-Bold',
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '이미 다른 가족 그룹에 소속되어 있습니다.',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Pretendard-Bold',
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  '초대를 수락하면 기존의 가족 그룹에서 자동으로 탈퇴되고, 새로운 가족 그룹으로 이동합니다.',
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: 'Pretendard-Regular',
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '기존 가족과의 관계 설정, 미션 내역 등이 삭제될 수 있으니 주의하세요.',
                    style: TextStyle(
                      fontSize: 13,
                      fontFamily: 'Pretendard-Medium',
                      color: Colors.deepOrange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  '정말 가족 그룹을 변경하시겠습니까?',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Pretendard-Bold',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _processAfterWarning(familyMemberId, false);
                },
                child: const Text(
                  '취소',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 15,
                    fontFamily: 'Pretendard-Bold',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _processAfterWarning(familyMemberId, true);
                },
                child: const Text(
                  '수락하기',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 15,
                    fontFamily: 'Pretendard-Bold',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  // 경고창 표시 후 초대 처리
  Future<void> _processAfterWarning(
    int familyMemberId,
    bool userAccepted,
  ) async {
    try {
      setState(() {
        _isLoading = true;
      });

      final result = await FamilyService.processInvitationAfterWarning(
        familyMemberId,
        userAccepted,
      );

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      // 초대 목록 다시 로드
      await _loadFamilyInvites();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('경고창 후 초대 처리 중 오류: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('초대 처리 중 오류가 발생했습니다: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );

      setState(() {
        _isLoading = false;
      });
    }
  }

  // 가족 초대 거절
  Future<void> _rejectFamilyInvite(int familyMemberId) async {
    try {
      setState(() {
        _isLoading = true;
      });

      final result = await FamilyService.rejectFamilyInvite(familyMemberId);

      if (result) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('가족 초대를 거절했습니다'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // 초대 목록 다시 로드
        await _loadFamilyInvites();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('초대 거절 처리에 실패했습니다'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('가족 초대 거절 중 오류: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('초대 거절 중 오류가 발생했습니다: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );

      setState(() {
        _isLoading = false;
      });
    }
  }

  // 챌린지 신청 수락 처리
  Future<void> _acceptChallengeApplication(int participationId) async {
    try {
      setState(() {
        _isLoading = true;
      });

      print('챌린지 신청 수락 처리 시작 - participationId: $participationId');

      final result = await ChallengeService.acceptChallengeApplication(
        participationId,
      );

      // 성공적으로 수락되면 result가 ChallengeParticipation 객체로 반환됨
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('챌린지 신청이 수락되었습니다.'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );

      // 챌린지 신청 목록 다시 로드
      await _loadChallengeApplications();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('챌린지 신청 수락 처리 중 오류: $e');

      String errorMessage = e.toString().replaceAll('Exception: ', '');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );

      setState(() {
        _isLoading = false;
      });
    }
  }

  // 챌린지 신청 거절 처리
  Future<void> _rejectChallengeApplication(int participationId) async {
    try {
      setState(() {
        _isLoading = true;
      });

      print('챌린지 신청 거절 처리 시작 - participationId: $participationId');

      final result = await ChallengeService.rejectChallengeApplication(
        participationId,
      );

      // 성공적으로 거절되면 result가 ChallengeParticipation 객체로 반환됨
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('챌린지 신청이 거절되었습니다.'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );

      // 챌린지 신청 목록 다시 로드
      await _loadChallengeApplications();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('챌린지 신청 거절 처리 중 오류: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('챌린지 거절 중 오류가 발생했습니다: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );

      setState(() {
        _isLoading = false;
      });
    }
  }

  // 초대 시간 포맷팅
  String _formatInviteTime(String invitedDate) {
    try {
      final inviteTime = DateTime.parse(invitedDate);
      final now = DateTime.now();
      final difference = now.difference(inviteTime);

      if (difference.inDays > 0) {
        return '${difference.inDays}일 전';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}시간 전';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}분 전';
      } else {
        return '방금 전';
      }
    } catch (e) {
      return invitedDate;
    }
  }

  // goalId로 목표 찾기
  Map<String, dynamic>? _findGoalById(int goalId) {
    // 이번 주 목표에서 찾기
    for (var goal in _weeklyGoals) {
      if (goal['goalId'] == goalId) {
        return goal;
      }
    }

    // 목표 신청 알림에서 찾기
    for (var goalApp in _goalApplications) {
      if (goalApp['goalId'] == goalId) {
        return goalApp;
      }
    }

    return null;
  }

  // 날짜를 MM. dd 형식으로 포맷팅
  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';

    try {
      final date = DateTime.parse(dateStr);
      return '${date.month.toString().padLeft(2, '0')}. ${date.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return '';
    }
  }

  // 목표의 시작일과 종료일을 가져와서 포맷팅
  String _getGoalDateRange(int goalId) {
    // 먼저 goalApplications에서 찾기 (여기엔 날짜 정보가 없을 수 있음)
    final goalApp = _goalApplications.firstWhere(
      (app) => app['goalId'] == goalId,
      orElse: () => {},
    );

    // goalApp에서 날짜 정보가 없으면 weeklyGoals에서 찾기
    if (goalApp.isNotEmpty) {
      // weeklyGoals에서 같은 goalId 찾기
      final weeklyGoal = _weeklyGoals.firstWhere(
        (goal) => goal['goalId'] == goalId,
        orElse: () => {},
      );

      if (weeklyGoal.isNotEmpty) {
        final startDate = _formatDate(weeklyGoal['startDate']);
        final endDate = _formatDate(weeklyGoal['endDate']);

        if (startDate.isNotEmpty && endDate.isNotEmpty) {
          return '$startDate - $endDate';
        }
      }

      // weeklyGoals에서도 못 찾으면 createdAt 사용
      final startDate = _formatDate(
        goalApp['startDate'] ?? goalApp['createdAt'],
      );
      if (startDate.isNotEmpty) {
        // endDate가 없으면 startDate + 7일로 계산
        try {
          final start = DateTime.parse(
            goalApp['startDate'] ?? goalApp['createdAt'],
          );
          final end = start.add(const Duration(days: 6));
          final endDate = _formatDate(end.toIso8601String());
          return '$startDate - $endDate';
        } catch (e) {
          return '';
        }
      }
    }

    return '';
  }

  // 탭 위젯 생성 (기존)
  Widget _buildTab(int index, String title) {
    bool isSelected = _selectedTabIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTabIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 0),
        decoration: BoxDecoration(
          border:
              isSelected && index != 0
                  ? Border(bottom: BorderSide(color: Colors.black, width: 2.0))
                  : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                Container(
                  width: 12,
                  height: 22,
                  margin: const EdgeInsets.only(right: 3),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFF146AFF),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),

            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.black : Color(0xFF999999),
                fontSize: 13,
                fontFamily:
                    isSelected ? 'Pretendard-Medium' : 'Pretendard-Regular',
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 새로운 탭 위젯 생성
  Widget _buildNewTab(int index, String title) {
    bool isSelected = _selectedTabIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTabIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? Colors.black : const Color(0xFFC4C4C4),
              width: isSelected ? 2.0 : 1.0,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 4,
              height: 4,
              margin: const EdgeInsets.only(right: 4, top: 2),
              decoration: ShapeDecoration(
                color: const Color(0xFF146AFF),
                shape: OvalBorder(),
              ),
            ),
            Flexible(
              child: Text(
                title,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color:
                      isSelected
                          ? const Color(0xFF202020)
                          : const Color(0xFF999999),
                  fontSize: 13,
                  fontFamily:
                      isSelected ? 'Pretendard-Bold' : 'Pretendard-Light',
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w300,
                  letterSpacing: -0.26,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        automaticallyImplyLeading: false,
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Stack(
            children: [
              // 절대 중앙 타이틀 (약간 아래로 조정)
              Positioned.fill(
                child: Align(
                  alignment: Alignment(0, 0.2), // 0은 가로 중앙, 0.2는 세로 약간 아래
                  child: Text(
                    '알림함',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                      fontFamily: 'Pretendard-Bold',
                      letterSpacing: -0.32,
                    ),
                  ),
                ),
              ),
              // 왼쪽과 오른쪽 요소들
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 왼쪽 뒤로가기 버튼
                  Container(
                    width: 24,
                    height: 24,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: Image.asset(
                        'assets/icons/parent/noti/뒤로가기.png',
                        width: 20,
                        height: 20,
                        errorBuilder:
                            (context, error, stackTrace) => const Icon(
                              Icons.arrow_back_ios,
                              color: Colors.black,
                              size: 20,
                            ),
                      ),
                      onPressed:
                          () => Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ParentHomeScreen(),
                            ),
                          ),
                    ),
                  ),
                  // 오른쪽 영역
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 자녀 프로필과 변경 버튼
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: ShapeDecoration(
                          color: const Color(0xFF5D9EFF),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // 자녀 프로필 이미지
                            Container(
                              width: 24,
                              height: 24,
                              decoration: ShapeDecoration(
                                shape: OvalBorder(
                                  side: BorderSide(
                                    width: 0.80,
                                    color: const Color(0xFF146AFF),
                                  ),
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child:
                                    _isLoadingChildren
                                        ? Container(
                                          color: Colors.grey[300],
                                          child: Center(
                                            child: SizedBox(
                                              width: 12,
                                              height: 12,
                                              child: CircularProgressIndicator(
                                                color: Colors.grey[600],
                                                strokeWidth: 1,
                                              ),
                                            ),
                                          ),
                                        )
                                        : _selectedChild?['profileImagePath'] !=
                                                null &&
                                            _selectedChild!['profileImagePath']!
                                                .isNotEmpty
                                        ? CachedNetworkImage(
                                          imageUrl:
                                              AuthService.getFullProfileImageUrl(
                                                _selectedChild!['profileImagePath'],
                                              ),
                                          fit: BoxFit.cover,
                                          placeholder:
                                              (context, url) => Container(
                                                color: Colors.grey[300],
                                                child: Icon(
                                                  Icons.person,
                                                  color: Colors.grey[600],
                                                  size: 12,
                                                ),
                                              ),
                                          errorWidget:
                                              (context, url, error) =>
                                                  Container(
                                                    color: Colors.grey[300],
                                                    child: Icon(
                                                      Icons.person,
                                                      color: Colors.grey[600],
                                                      size: 12,
                                                    ),
                                                  ),
                                        )
                                        : Container(
                                          color: Colors.grey[300],
                                          child: Icon(
                                            Icons.person,
                                            color: Colors.grey[600],
                                            size: 12,
                                          ),
                                        ),
                              ),
                            ),

                            const SizedBox(width: 8),

                            // 변경 버튼
                            GestureDetector(
                              onTap: _showChildSelectionModal,
                              child: Container(
                                width: 24,
                                height: 24,
                                child: Image.asset(
                                  'assets/icons/parent/아이변경.png',
                                  width: 24,
                                  height: 24,
                                  color: Colors.white,
                                  errorBuilder:
                                      (context, error, stackTrace) => Icon(
                                        Icons.swap_horiz,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 12),

                      // 설정 버튼
                      Container(
                        width: 24,
                        height: 24,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: Image.asset(
                            'assets/icons/parent/noti/설정.png',
                            width: 20,
                            height: 20,
                            errorBuilder:
                                (context, error, stackTrace) => const Icon(
                                  Icons.settings_outlined,
                                  size: 20,
                                ),
                          ),
                          onPressed: () {
                            // 알림 설정 화면 이동
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(60),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.only(
              top: 8,
              left: 12,
              right: 12,
              bottom: 8,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(child: _buildNewTab(0, '전체')),
                Expanded(child: _buildNewTab(1, '초대/요청')),
                Expanded(child: _buildNewTab(2, '활동 내역')),
                Expanded(child: _buildNewTab(3, '리워드')),
              ],
            ),
          ),
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  // 필터 버튼 (전체/안 읽음) 추가
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _showOnlyUnread = false;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 9,
                                  ),
                                  decoration: ShapeDecoration(
                                    color:
                                        !_showOnlyUnread
                                            ? const Color(0xFF5C697E)
                                            : const Color(0xFFE7ECF6),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Text(
                                            '전체',
                                            style: TextStyle(
                                              color:
                                                  !_showOnlyUnread
                                                      ? Colors.white
                                                      : const Color(0xFF8490A3),
                                              fontSize: 11,
                                              fontFamily:
                                                  !_showOnlyUnread
                                                      ? 'Pretendard-Medium'
                                                      : 'Pretendard-Light',
                                              fontWeight:
                                                  !_showOnlyUnread
                                                      ? FontWeight.w500
                                                      : FontWeight.w300,
                                              letterSpacing: -0.22,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 15),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _showOnlyUnread = true;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 9,
                                  ),
                                  decoration: ShapeDecoration(
                                    color:
                                        _showOnlyUnread
                                            ? const Color(0xFF5C697E)
                                            : const Color(0xFFE7ECF6),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        '안 읽음',
                                        style: TextStyle(
                                          color:
                                              _showOnlyUnread
                                                  ? Colors.white
                                                  : const Color(0xFF8490A3),
                                          fontSize: 11,
                                          fontFamily:
                                              _showOnlyUnread
                                                  ? 'Pretendard-Medium'
                                                  : 'Pretendard-Light',
                                          fontWeight:
                                              _showOnlyUnread
                                                  ? FontWeight.w500
                                                  : FontWeight.w300,
                                          letterSpacing: -0.22,
                                        ),
                                      ),
                                      // 안읽은 알림 개수 배지
                                      if (_getUnreadNotificationCount() >
                                          0) ...[
                                        const SizedBox(width: 6),
                                        Text(
                                          '${_getUnreadNotificationCount()}',
                                          style: const TextStyle(
                                            color: Color(0xFF5D9EFF),
                                            fontSize: 12,
                                            fontFamily: 'Pretendard',
                                            fontWeight: FontWeight.w500,
                                            letterSpacing: -0.28,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 알림 목록
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _refreshAllData,
                      child: ListView(
                        padding: EdgeInsets.zero,
                        children: [
                          // 필터링된 알림 표시
                          ..._getFilteredNotifications(),

                          // 알림이 없을 때 표시할 섹션 (현재 탭에 알림이 없을 때만 표시)
                          if (!_hasNotificationsForCurrentTab() &&
                              !_isLoading) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(24),
                              color: Colors.white,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.notifications_none,
                                    size: 48,
                                    color: Color(0xFFCCCCCC),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _getEmptyMessageForCurrentTab(),
                                    style: const TextStyle(
                                      color: Color(0xFF666666),
                                      fontSize: 14,
                                      fontFamily: 'Pretendard-Regular',
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton.icon(
                                    onPressed: _refreshAllData,
                                    icon: const Icon(Icons.refresh),
                                    label: const Text('새로고침'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF3A88F4),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      bottomNavigationBar: ParentBottomNavigationBar(selectedIndex: 4),
    );
  }

  // 현재 탭에 맞는 빈 메시지 반환
  String _getEmptyMessageForCurrentTab() {
    if (_showOnlyUnread) {
      // 안읽음 필터가 활성화된 경우
      switch (_selectedTabIndex) {
        case 0:
          return '읽지 않은 알림이 없습니다';
        case 1:
          return '읽지 않은 초대·요청이 없습니다';
        case 2:
          return '읽지 않은 활동 내역이 없습니다';
        case 3:
          return '읽지 않은 리워드가 없습니다';
        default:
          return '읽지 않은 알림이 없습니다';
      }
    } else {
      // 전체 필터가 활성화된 경우
      switch (_selectedTabIndex) {
        case 0:
          return '새로운 알림이 없습니다';
        case 1:
          return '새로운 초대·요청이 없습니다';
        case 2:
          return '새로운 활동 내역이 없습니다';
        case 3:
          return '새로운 리워드가 없습니다';
        default:
          return '새로운 알림이 없습니다';
      }
    }
  }

  // 탭별 알림 필터링 메서드 추가
  List<Widget> _getFilteredNotifications() {
    List<Widget> notifications = [];

    switch (_selectedTabIndex) {
      case 0: // 전체
        notifications.addAll(_getAllNotifications());
        break;
      case 1: // 초대·요청
        notifications.addAll(_getInviteRequestNotifications());
        break;
      case 2: // 활동 내역
        notifications.addAll(_getActivityNotifications());
        break;
      case 3: // 리워드
        notifications.addAll(_getRewardNotifications());
        break;
    }

    return notifications;
  }

  // 전체 알림 가져오기
  List<Widget> _getAllNotifications() {
    List<Widget> notifications = [];

    // 가족 초대
    final filteredFamilyInvites =
        _showOnlyUnread
            ? _familyInvites
                .where((invite) => !(invite['read'] ?? false))
                .toList()
            : _familyInvites;
    if (filteredFamilyInvites.isNotEmpty) {
      notifications.addAll(
        filteredFamilyInvites.map((invite) => _buildFamilyInviteItem(invite)),
      );
    }

    // 목표 신청
    final filteredGoalApps = _filterBySelectedChild(
      _goalApplications,
      'GoalApplications',
    );
    final unreadGoalApps =
        _showOnlyUnread
            ? filteredGoalApps
                .where((goalApp) => !(goalApp['read'] ?? false))
                .toList()
            : filteredGoalApps;
    if (unreadGoalApps.isNotEmpty) {
      notifications.addAll(
        unreadGoalApps.map((goalApp) => _buildGoalApplicationItem(goalApp)),
      );
    }

    // 챌린지 신청
    final filteredChallengeApps = _filterBySelectedChild(
      _challengeApplications,
      'ChallengeApplications',
    );
    final unreadChallengeApps =
        _showOnlyUnread
            ? filteredChallengeApps
                .where((challengeApp) => !(challengeApp['read'] ?? false))
                .toList()
            : filteredChallengeApps;
    if (unreadChallengeApps.isNotEmpty) {
      notifications.addAll(
        unreadChallengeApps.map(
          (challengeApp) => _buildChallengeApplicationItem(challengeApp),
        ),
      );
    }

    // 목표 완료
    final filteredGoalCompletions = _filterBySelectedChild(
      _goalCompletions,
      'GoalCompletions',
    );
    final unreadGoalCompletions =
        _showOnlyUnread
            ? filteredGoalCompletions
                .where((goalCompletion) => !(goalCompletion['read'] ?? false))
                .toList()
            : filteredGoalCompletions;
    if (unreadGoalCompletions.isNotEmpty) {
      notifications.addAll(
        unreadGoalCompletions.map(
          (goalCompletion) => _buildGoalCompletionItem(goalCompletion),
        ),
      );
    }

    // 챌린지 완료
    final filteredChallengeCompletions = _filterBySelectedChild(
      _challengeCompletions,
      'ChallengeCompletions',
    );
    final unreadChallengeCompletions =
        _showOnlyUnread
            ? filteredChallengeCompletions
                .where(
                  (challengeCompletion) =>
                      !(challengeCompletion['read'] ?? false),
                )
                .toList()
            : filteredChallengeCompletions;
    if (unreadChallengeCompletions.isNotEmpty) {
      notifications.addAll(
        unreadChallengeCompletions.map(
          (challengeCompletion) =>
              _buildChallengeCompletionItem(challengeCompletion),
        ),
      );
    }

    // 이번 주 목표 (리워드 관련)
    final filteredWeeklyGoals = _filterBySelectedChild(
      _weeklyGoals,
      'WeeklyGoals',
    );
    final unreadWeeklyGoals =
        _showOnlyUnread
            ? filteredWeeklyGoals
                .where((goal) => !(goal['read'] ?? false))
                .toList()
            : filteredWeeklyGoals;
    if (unreadWeeklyGoals.isNotEmpty) {
      notifications.addAll(
        unreadWeeklyGoals.map((goal) => _buildWeeklyGoalItem(goal)),
      );
    }

    return notifications;
  }

  // 초대·요청 알림 가져오기
  List<Widget> _getInviteRequestNotifications() {
    List<Widget> notifications = [];

    // 1. 초대/친구 추가 요청
    final filteredFamilyInvites =
        _showOnlyUnread
            ? _familyInvites
                .where((invite) => !(invite['read'] ?? false))
                .toList()
            : _familyInvites;
    if (filteredFamilyInvites.isNotEmpty) {
      notifications.addAll(
        filteredFamilyInvites.map((invite) => _buildFamilyInviteItem(invite)),
      );
    }

    // 2. 미션 챌린지 목표 승인 요청
    final filteredGoalApps = _filterBySelectedChild(
      _goalApplications,
      'GoalApplications',
    );
    final unreadGoalApps =
        _showOnlyUnread
            ? filteredGoalApps
                .where((goalApp) => !(goalApp['read'] ?? false))
                .toList()
            : filteredGoalApps;
    if (unreadGoalApps.isNotEmpty) {
      notifications.addAll(
        unreadGoalApps.map((goalApp) => _buildGoalApplicationItem(goalApp)),
      );
    }

    final filteredChallengeApps = _filterBySelectedChild(
      _challengeApplications,
      'ChallengeApplications',
    );
    final unreadChallengeApps =
        _showOnlyUnread
            ? filteredChallengeApps
                .where((challengeApp) => !(challengeApp['read'] ?? false))
                .toList()
            : filteredChallengeApps;
    if (unreadChallengeApps.isNotEmpty) {
      notifications.addAll(
        unreadChallengeApps.map(
          (challengeApp) => _buildChallengeApplicationItem(challengeApp),
        ),
      );
    }

    // 3. 목표 스탬프 찍기 요청 (추후 구현 예정)
    // TODO: 목표 스탬프 찍기 요청 알림 추가

    return notifications;
  }

  // 활동 내역 알림 가져오기
  List<Widget> _getActivityNotifications() {
    List<Widget> notifications = [];

    // 1. 미션/챌린지/목표 완료 평가
    final filteredGoalCompletions = _filterBySelectedChild(
      _goalCompletions,
      'GoalCompletions',
    );
    final unreadGoalCompletions =
        _showOnlyUnread
            ? filteredGoalCompletions
                .where((goalCompletion) => !(goalCompletion['read'] ?? false))
                .toList()
            : filteredGoalCompletions;
    if (unreadGoalCompletions.isNotEmpty) {
      notifications.addAll(
        unreadGoalCompletions.map(
          (goalCompletion) => _buildGoalCompletionItem(goalCompletion),
        ),
      );
    }

    final filteredChallengeCompletions = _filterBySelectedChild(
      _challengeCompletions,
      'ChallengeCompletions',
    );
    final unreadChallengeCompletions =
        _showOnlyUnread
            ? filteredChallengeCompletions
                .where(
                  (challengeCompletion) =>
                      !(challengeCompletion['read'] ?? false),
                )
                .toList()
            : filteredChallengeCompletions;
    if (unreadChallengeCompletions.isNotEmpty) {
      notifications.addAll(
        unreadChallengeCompletions.map(
          (challengeCompletion) =>
              _buildChallengeCompletionItem(challengeCompletion),
        ),
      );
    }

    final filteredMissionCompletions = _filterBySelectedChild(
      _missionCompletions,
      'MissionCompletions',
    );
    final unreadMissionCompletions =
        _showOnlyUnread
            ? filteredMissionCompletions
                .where(
                  (missionCompletion) => !(missionCompletion['read'] ?? false),
                )
                .toList()
            : filteredMissionCompletions;
    if (unreadMissionCompletions.isNotEmpty) {
      notifications.addAll(
        unreadMissionCompletions.map(
          (missionCompletion) => _buildMissionCompletionItem(missionCompletion),
        ),
      );
    }

    // 2. 보상금 승인완료 (추후 구현 예정)
    // TODO: 보상금 승인완료 알림 추가

    // 3. 미션/챌린지/목표 완료 (추후 구현 예정)
    // TODO: 완료 알림과 평가 알림 분리 필요

    return notifications;
  }

  // 리워드 알림 가져오기
  List<Widget> _getRewardNotifications() {
    List<Widget> notifications = [];

    // 1. 구독권 선물
    final filteredWeeklyGoals = _filterBySelectedChild(
      _weeklyGoals,
      'WeeklyGoals',
    );
    final unreadWeeklyGoals =
        _showOnlyUnread
            ? filteredWeeklyGoals
                .where((goal) => !(goal['read'] ?? false))
                .toList()
            : filteredWeeklyGoals;
    if (unreadWeeklyGoals.isNotEmpty) {
      notifications.addAll(
        unreadWeeklyGoals.map((goal) => _buildWeeklyGoalItem(goal)),
      );
    }

    // TODO: 추가 리워드 알림 구현 예정

    return notifications;
  }

  // 현재 탭에 알림이 있는지 확인
  bool _hasNotificationsForCurrentTab() {
    return _getFilteredNotifications().isNotEmpty;
  }

  // 안읽은 알림 개수 계산
  int _getUnreadNotificationCount() {
    int count = 0;

    // 가족 초대 안읽은 개수
    count +=
        _familyInvites.where((invite) => !(invite['read'] ?? false)).length;

    // 목표 신청 안읽은 개수 (자녀 필터링 적용)
    final filteredGoalApps = _filterBySelectedChild(
      _goalApplications,
      'GoalApplications',
    );
    count +=
        filteredGoalApps.where((goalApp) => !(goalApp['read'] ?? false)).length;

    // 챌린지 신청 안읽은 개수 (자녀 필터링 적용)
    final filteredChallengeApps = _filterBySelectedChild(
      _challengeApplications,
      'ChallengeApplications',
    );
    count +=
        filteredChallengeApps
            .where((challengeApp) => !(challengeApp['read'] ?? false))
            .length;

    // 목표 완료 안읽은 개수 (자녀 필터링 적용)
    final filteredGoalCompletions = _filterBySelectedChild(
      _goalCompletions,
      'GoalCompletions',
    );
    count +=
        filteredGoalCompletions
            .where((goalCompletion) => !(goalCompletion['read'] ?? false))
            .length;

    // 챌린지 완료 안읽은 개수 (자녀 필터링 적용)
    final filteredChallengeCompletions = _filterBySelectedChild(
      _challengeCompletions,
      'ChallengeCompletions',
    );
    count +=
        filteredChallengeCompletions
            .where(
              (challengeCompletion) => !(challengeCompletion['read'] ?? false),
            )
            .length;

    // 미션 완료 안읽은 개수 (자녀 필터링 적용)
    final filteredMissionCompletions = _filterBySelectedChild(
      _missionCompletions,
      'MissionCompletions',
    );
    count +=
        filteredMissionCompletions
            .where((missionCompletion) => !(missionCompletion['read'] ?? false))
            .length;

    // 이번 주 목표(리워드) 안읽은 개수 (자녀 필터링 적용)
    final filteredWeeklyGoals = _filterBySelectedChild(
      _weeklyGoals,
      'WeeklyGoals',
    );
    count +=
        filteredWeeklyGoals.where((goal) => !(goal['read'] ?? false)).length;

    return count;
  }

  Widget _buildFamilyInviteItem(Map<String, dynamic> invite) {
    final String senderName = invite['senderName'] ?? '알 수 없음';
    final int familyMemberId = invite['familyMemberId'] ?? 0;
    final String invitedTime = _formatInviteTime(invite['createdAt'] ?? '');
    bool isRead = invite['read'] ?? false;

    return StatefulBuilder(
      builder: (context, setState) {
        return GestureDetector(
          onTap: () {
            setState(() {
              isRead = true;
              invite['read'] = true;
            });
            _showFamilyInviteModal(context, senderName, familyMemberId);
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: ShapeDecoration(
              color: isRead ? const Color(0xFFE5E7ED) : Colors.white,
              shape: RoundedRectangleBorder(
                side: BorderSide(width: 0.40, color: const Color(0xFFC4C4C4)),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: double.infinity,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 24,
                                    height: 24,
                                    clipBehavior: Clip.antiAlias,
                                    decoration: BoxDecoration(),
                                    child: Image.asset(
                                      'assets/icons/parent/noti/초대·요청.png',
                                      width: 20,
                                      height: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),

                                  Expanded(
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: ShapeDecoration(
                                            color: const Color(0xFFFFD27F),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              Text(
                                                '초대·요청',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 9,
                                                  fontFamily:
                                                      'Pretendard-ExtraLight',
                                                  letterSpacing: -0.22,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),

                                        Expanded(
                                          child: Text(
                                            '$senderName님이 가족 멤버로 초대했어요!',
                                            style: const TextStyle(
                                              color: Color(0xFF202020),
                                              fontSize: 13,
                                              fontFamily: 'Pretendard-Medium',
                                              letterSpacing: -0.32,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 8),
                            const SizedBox(
                              width: 144,
                              child: Text(
                                '알림을 눌러 확인해 보세요!',
                                style: TextStyle(
                                  color: Color(0xFF4A4A4A),
                                  fontSize: 12,
                                  fontFamily: 'Pretendard-Light',
                                  letterSpacing: -0.28,
                                ),
                              ),
                            ),

                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  invitedTime,
                                  style: TextStyle(
                                    color: const Color(0xFF999999),
                                    fontSize: 11,
                                    fontFamily: 'Pretendard-Light',
                                    letterSpacing: -0.22,
                                  ),
                                ),

                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 12,
                                      height: 12,
                                      margin: const EdgeInsets.only(right: 4),
                                      child: Transform.scale(
                                        scaleX: -1,
                                        child: Icon(
                                          Icons.check,
                                          size: 12,
                                          color:
                                              isRead
                                                  ? const Color(0xFF5D9EFF)
                                                  : const Color(0xFFB6B6B6),
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '확인했어요',
                                      style: TextStyle(
                                        color:
                                            isRead
                                                ? const Color(0xFF5D9EFF)
                                                : const Color(0xFFB6B6B6),
                                        fontSize: 10,
                                        fontFamily: 'Pretendard-Light',
                                        letterSpacing: -0.22,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showFamilyInviteModal(
    BuildContext context,
    String inviterName,
    int familyMemberId,
  ) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (BuildContext context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final modalWidth = screenWidth * 0.9 > 358 ? 358.0 : screenWidth * 0.9;

        return Center(
          child: Material(
            type: MaterialType.transparency,
            child: Container(
              width: modalWidth,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '$inviterName님이 가족 멤버로 초대했어요!',
                                style: const TextStyle(
                                  color: Color(0xFF202020),
                                  fontSize: 14,
                                  fontFamily: 'Pretendard-Bold',
                                  letterSpacing: -0.72,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: const Icon(
                                Icons.close,
                                color: Color(0xFF999999),
                                size: 18,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '수락하면 함께 가족 활동을 할 수 있어요',
                          style: TextStyle(
                            color: Color(0xFF999999),
                            fontSize: 12,
                            fontFamily: 'Pretendard-Light',
                            letterSpacing: -0.28,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(24),
                        bottomRight: Radius.circular(24),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                              _rejectFamilyInvite(familyMemberId);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDADADA),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: const Text(
                                '초대 거절',
                                style: TextStyle(
                                  color: Color(0xFFB6B6B6),
                                  fontSize: 12,
                                  fontFamily: 'Pretendard-Light',
                                  letterSpacing: -0.28,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                              _processFamilyInvite(familyMemberId);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF5D9EFF),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: const Text(
                                '초대 수락',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontFamily: 'Pretendard-Light',
                                  letterSpacing: -0.28,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // 목표 신청 알림 아이템 위젯
  Widget _buildGoalApplicationItem(Map<String, dynamic> goalApp) {
    final String title = goalApp['title'] ?? '목표 없음';
    final String category = goalApp['category'] ?? 'LEARNING';
    final int goalId = goalApp['goalId'] ?? 0;
    final String childName = goalApp['childName'] ?? '자녀';
    final String createdTime = _formatInviteTime(goalApp['createdAt'] ?? '');
    bool isRead = goalApp['read'] ?? false;

    return StatefulBuilder(
      builder: (context, setState) {
        return GestureDetector(
          onTap: () {
            setState(() {
              isRead = true;
              goalApp['read'] = true;
            });
            _showGoalApplicationModal(
              context,
              title,
              category,
              goalId,
              childName,
              goalApp['reward'],
            );
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: ShapeDecoration(
              color: isRead ? const Color(0xFFE5E7ED) : Colors.white,
              shape: RoundedRectangleBorder(
                side: BorderSide(width: 0.40, color: const Color(0xFFC4C4C4)),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: double.infinity,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 24,
                                    height: 24,
                                    clipBehavior: Clip.antiAlias,
                                    decoration: BoxDecoration(),
                                    child: Image.asset(
                                      'assets/icons/parent/noti/초대·요청.png',
                                      width: 20,
                                      height: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),

                                  Expanded(
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: ShapeDecoration(
                                            color: const Color(0xFFFFD27F),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              Text(
                                                '초대·요청',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 9,
                                                  fontFamily:
                                                      'Pretendard-ExtraLight',
                                                  letterSpacing: -0.22,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),

                                        Expanded(
                                          child: Text(
                                            '$childName님이 목표 승인을 요청했어요!',
                                            style: const TextStyle(
                                              color: Color(0xFF202020),
                                              fontSize: 13,
                                              fontFamily: 'Pretendard-Medium',
                                              letterSpacing: -0.32,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 8),
                            const SizedBox(
                              width: 144,
                              child: Text(
                                '알림을 눌러 확인해 보세요!',
                                style: TextStyle(
                                  color: Color(0xFF4A4A4A),
                                  fontSize: 12,
                                  fontFamily: 'Pretendard-Light',
                                  letterSpacing: -0.28,
                                ),
                              ),
                            ),

                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  createdTime,
                                  style: TextStyle(
                                    color: const Color(0xFF999999),
                                    fontSize: 11,
                                    fontFamily: 'Pretendard-Light',
                                    letterSpacing: -0.22,
                                  ),
                                ),

                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 12,
                                      height: 12,
                                      margin: const EdgeInsets.only(right: 4),
                                      child: Transform.scale(
                                        scaleX: -1,
                                        child: Icon(
                                          Icons.check,
                                          size: 12,
                                          color:
                                              isRead
                                                  ? const Color(0xFF5D9EFF)
                                                  : const Color(0xFFB6B6B6),
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '확인했어요',
                                      style: TextStyle(
                                        color:
                                            isRead
                                                ? const Color(0xFF5D9EFF)
                                                : const Color(0xFFB6B6B6),
                                        fontSize: 10,
                                        fontFamily: 'Pretendard-Light',
                                        letterSpacing: -0.22,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 목표 신청 모달 표시
  void _showGoalApplicationModal(
    BuildContext context,
    String title,
    String category,
    int goalId,
    String childName, [
    int? reward,
  ]) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (BuildContext context) {
        String categoryText = category == 'LEARNING' ? '학습 인증' : '습관 형성';

        return LayoutBuilder(
          builder: (context, constraints) {
            // 화면 크기에 따른 모달 크기 계산
            final screenWidth = constraints.maxWidth;
            final screenHeight = constraints.maxHeight;

            // 모달 너비: 화면 너비의 90%, 최대 380px, 최소 280px
            final modalWidth = (screenWidth * 0.9).clamp(280.0, 380.0);

            return Center(
              child: Material(
                type: MaterialType.transparency,
                child: Container(
                  width: modalWidth,
                  constraints: BoxConstraints(
                    maxHeight: screenHeight * 0.7, // 화면 높이의 70% 이하로 줄임
                    minHeight: 220, // 최소 높이도 줄임
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 헤더 섹션
                      Container(
                        width: modalWidth,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ), // 패딩 줄임
                        decoration: const ShapeDecoration(
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(24),
                              topRight: Radius.circular(24),
                            ),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '$childName님이 목표 승인을 요청했어요!',
                                    style: const TextStyle(
                                      color: Color(0xFF202020),
                                      fontSize: 16, // 18 -> 16
                                      fontFamily: 'Pretendard-Bold',
                                      letterSpacing: -0.64, // 조정
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => Navigator.pop(context),
                                  child: Container(
                                    width: 18,
                                    height: 18,
                                    child: const Icon(
                                      Icons.close,
                                      color: Color(0xFF999999),
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6), // 8 -> 6
                            const Text(
                              '수락하고 아이의 달성을 응원해 보세요',
                              style: TextStyle(
                                color: Color(0xFF999999),
                                fontSize: 12, // 14 -> 12
                                fontFamily: 'Pretendard-Light',
                                letterSpacing: -0.24, // 조정
                              ),
                            ),
                          ],
                        ),
                      ),

                      // 내용 섹션
                      Container(
                        width: modalWidth,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 10,
                        ), // 패딩 줄임
                        decoration: const BoxDecoration(color: Colors.white),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 8, // 뱃지 간 간격
                              runSpacing: 6, // 줄바꿈 시 간격
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 3,
                                  ),
                                  decoration: ShapeDecoration(
                                    color: const Color(0xFFFFD27F),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                  child: const Text(
                                    '목표',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontFamily: 'Pretendard-Light',
                                      letterSpacing: -0.20,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 3,
                                  ),
                                  decoration: ShapeDecoration(
                                    color: const Color(0xFFFFD27F),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                  child: Text(
                                    categoryText,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontFamily: 'Pretendard-Light',
                                      letterSpacing: -0.20,
                                    ),
                                  ),
                                ),
                                // 날짜 뱃지 추가
                                if (_getGoalDateRange(goalId).isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 3,
                                    ),
                                    decoration: ShapeDecoration(
                                      color: const Color(0xFF5D9EFF),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                    child: Text(
                                      _getGoalDateRange(goalId),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontFamily: 'Pretendard-Light',
                                        letterSpacing: -0.20,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 6), // 8 -> 6
                            Text(
                              title,
                              style: const TextStyle(
                                color: Color(0xFF202020),
                                fontSize: 16, // 18 -> 16
                                fontFamily: 'Pretendard-Bold',
                                letterSpacing: -0.64, // 조정
                              ),
                            ),
                            const SizedBox(height: 6), // 8 -> 6
                            Row(
                              children: [
                                const Text(
                                  '신청한 보상금',
                                  style: TextStyle(
                                    color: Color(0xFF666666),
                                    fontSize: 12, // 14 -> 12
                                    fontFamily: 'Pretendard-Light',
                                    letterSpacing: -0.24, // 조정
                                  ),
                                ),
                                const SizedBox(width: 8), // 12 -> 8
                                Text(
                                  '${reward?.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}원',
                                  style: const TextStyle(
                                    color: Color(0xFF3A88F4),
                                    fontSize: 14, // 16 -> 14
                                    fontFamily: 'Pretendard-Bold',
                                    letterSpacing: -0.28, // 조정
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // 버튼 섹션
                      Container(
                        width: modalWidth,
                        padding: const EdgeInsets.symmetric(
                          vertical: 18,
                          horizontal: 18,
                        ), // 패딩 줄임
                        decoration: const ShapeDecoration(
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(24),
                              bottomRight: Radius.circular(24),
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.pop(context);
                                  _rejectGoalApplication(goalId);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ), // 16 -> 12
                                  decoration: ShapeDecoration(
                                    color: const Color(0xFFDADADA),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      '거절',
                                      style: TextStyle(
                                        color: Color(0xFFB6B6B6),
                                        fontSize: 12, // 14 -> 12
                                        fontFamily: 'Pretendard-Light',
                                        letterSpacing: -0.24, // 조정
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16), // 24 -> 16
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.pop(context);
                                  _acceptGoalApplication(goalId);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ), // 16 -> 12
                                  decoration: ShapeDecoration(
                                    color: const Color(0xFF5D9EFF),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      '수락',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12, // 14 -> 12
                                        fontFamily: 'Pretendard-Light',
                                        letterSpacing: -0.24, // 조정
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // 이번 주 목표 아이템 위젯
  Widget _buildWeeklyGoalItem(Map<String, dynamic> goal) {
    final String title = goal['title'] ?? '목표 없음';
    final String category = goal['category'] ?? 'LEARNING';
    final String status = goal['status'] ?? '';
    final int goalId = goal['goalId'] ?? 0;
    final String childNickname = goal['childNickname'] ?? '자녀';
    final int familyMemberId = goal['familyMemberId'] ?? 0;

    // GoalService의 유틸리티 메서드 사용
    final String statusText = GoalService.getGoalStatusText(goal);
    final String categoryText = GoalService.getCategoryText(category);
    final Color statusColor = GoalService.getGoalStatusColor(goal);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          side: BorderSide(width: 0.40, color: const Color(0xFFC4C4C4)),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              clipBehavior: Clip.antiAlias,
                              decoration: BoxDecoration(),
                              child: Image.asset(
                                'assets/icons/parent/noti/리워드.png',
                                width: 20,
                                height: 20,
                              ),
                            ),
                            const SizedBox(width: 12),

                            Expanded(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: ShapeDecoration(
                                      color: const Color(0xFFFFD27F),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Text(
                                          '리워드',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 9,
                                            fontFamily: 'Pretendard-ExtraLight',
                                            letterSpacing: -0.22,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),

                                  Expanded(
                                    child: Text(
                                      '$childNickname님이 구독권을 선물했어요!',
                                      style: const TextStyle(
                                        color: Color(0xFF202020),
                                        fontSize: 13,
                                        fontFamily: 'Pretendard-Medium',
                                        letterSpacing: -0.32,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 8),
                      Text(
                        '$childNickname님이 구독권을 선물했어요!',
                        style: const TextStyle(
                          color: Color(0xFF4A4A4A),
                          fontSize: 12,
                          fontFamily: 'Pretendard-Light',
                          letterSpacing: -0.28,
                        ),
                      ),

                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '2일 전',
                            style: TextStyle(
                              color: const Color(0xFF999999),
                              fontSize: 11,
                              fontFamily: 'Pretendard-Light',
                              letterSpacing: -0.22,
                            ),
                          ),

                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                margin: const EdgeInsets.only(right: 4),
                                child: Transform.scale(
                                  scaleX: -1,
                                  child: Icon(
                                    Icons.check,
                                    size: 12,
                                    color: const Color(0xFF5D9EFF),
                                  ),
                                ),
                              ),
                              Text(
                                '확인했어요',
                                style: TextStyle(
                                  color: const Color(0xFF5D9EFF),
                                  fontSize: 10,
                                  fontFamily: 'Pretendard-Light',
                                  letterSpacing: -0.22,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 챌린지 신청 알림 아이템 위젯
  Widget _buildChallengeApplicationItem(Map<String, dynamic> challengeApp) {
    final String title = challengeApp['title'] ?? '챌린지 없음';
    final String subject = challengeApp['subject'] ?? '';
    final int participationId = challengeApp['participationId'] ?? 0;
    final String childName = challengeApp['childName'] ?? '자녀';
    final String createdTime = _formatInviteTime(
      challengeApp['createdAt'] ?? '',
    );
    bool isRead = challengeApp['read'] ?? false;

    return StatefulBuilder(
      builder: (context, setState) {
        return GestureDetector(
          onTap: () {
            setState(() {
              isRead = true;
              challengeApp['read'] = true;
            });
            _showChallengeApplicationModal(
              context,
              title,
              subject,
              participationId,
              childName,
              challengeApp['reward'],
            );
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: ShapeDecoration(
              color: isRead ? const Color(0xFFE5E7ED) : Colors.white,
              shape: RoundedRectangleBorder(
                side: BorderSide(width: 0.40, color: const Color(0xFFC4C4C4)),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: double.infinity,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 24,
                                    height: 24,
                                    clipBehavior: Clip.antiAlias,
                                    decoration: BoxDecoration(),
                                    child: Image.asset(
                                      'assets/icons/parent/noti/초대·요청.png',
                                      width: 20,
                                      height: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),

                                  Expanded(
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: ShapeDecoration(
                                            color: const Color(0xFFFFD27F),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              Text(
                                                '초대·요청',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 9,
                                                  fontFamily:
                                                      'Pretendard-ExtraLight',
                                                  letterSpacing: -0.22,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),

                                        Expanded(
                                          child: Text(
                                            '$childName님이 챌린지 승인을 요청했어요!',
                                            style: const TextStyle(
                                              color: Color(0xFF202020),
                                              fontSize: 13,
                                              fontFamily: 'Pretendard-Medium',
                                              letterSpacing: -0.32,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 8),
                            const SizedBox(
                              width: 144,
                              child: Text(
                                '알림을 눌러 확인해 보세요!',
                                style: TextStyle(
                                  color: Color(0xFF4A4A4A),
                                  fontSize: 12,
                                  fontFamily: 'Pretendard-Light',
                                  letterSpacing: -0.28,
                                ),
                              ),
                            ),

                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  createdTime,
                                  style: TextStyle(
                                    color: const Color(0xFF999999),
                                    fontSize: 11,
                                    fontFamily: 'Pretendard-Light',
                                    letterSpacing: -0.22,
                                  ),
                                ),

                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 12,
                                      height: 12,
                                      margin: const EdgeInsets.only(right: 4),
                                      child: Transform.scale(
                                        scaleX: -1,
                                        child: Icon(
                                          Icons.check,
                                          size: 12,
                                          color:
                                              isRead
                                                  ? const Color(0xFF5D9EFF)
                                                  : const Color(0xFFB6B6B6),
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '확인했어요',
                                      style: TextStyle(
                                        color:
                                            isRead
                                                ? const Color(0xFF5D9EFF)
                                                : const Color(0xFFB6B6B6),
                                        fontSize: 10,
                                        fontFamily: 'Pretendard-Light',
                                        letterSpacing: -0.22,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 챌린지 신청 모달 표시
  void _showChallengeApplicationModal(
    BuildContext context,
    String title,
    String subject,
    int participationId,
    String childName, [
    int? reward,
  ]) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (BuildContext context) {
        String categoryText = subject.isNotEmpty ? subject : '챌린지';
        String challengeStatus = 'REQUESTED'; // 실제 상태 가져오도록 수정 필요
        final challengeApp = _challengeApplications.firstWhere(
          (app) => app['participationId'] == participationId,
          orElse: () => {},
        );
        if (challengeApp.isNotEmpty &&
            challengeApp['challengeStatus'] != null) {
          challengeStatus = challengeApp['challengeStatus'];
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            final screenHeight = constraints.maxHeight;
            final modalWidth = (screenWidth * 0.9).clamp(280.0, 380.0);

            return Center(
              child: Material(
                type: MaterialType.transparency,
                child: Container(
                  width: modalWidth,
                  constraints: BoxConstraints(
                    maxHeight: screenHeight * 0.7,
                    minHeight: 220,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 헤더 섹션
                      Container(
                        width: modalWidth,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                        decoration: const ShapeDecoration(
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(24),
                              topRight: Radius.circular(24),
                            ),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '$childName님이 챌린지 승인을 요청했어요!',
                                    style: const TextStyle(
                                      color: Color(0xFF202020),
                                      fontSize: 16,
                                      fontFamily: 'Pretendard-Bold',
                                      letterSpacing: -0.64,
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => Navigator.pop(context),
                                  child: Container(
                                    width: 18,
                                    height: 18,
                                    child: const Icon(
                                      Icons.close,
                                      color: Color(0xFF999999),
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              '수락하고 아이의 달성을 응원해 보세요',
                              style: TextStyle(
                                color: Color(0xFF999999),
                                fontSize: 12,
                                fontFamily: 'Pretendard-Light',
                                letterSpacing: -0.24,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // 내용 섹션
                      Container(
                        width: modalWidth,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 10,
                        ),
                        decoration: const BoxDecoration(color: Colors.white),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 3,
                                  ),
                                  decoration: ShapeDecoration(
                                    color: const Color(0xFFFFD27F),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                  child: const Text(
                                    '챌린지',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontFamily: 'Pretendard-Light',
                                      letterSpacing: -0.20,
                                    ),
                                  ),
                                ),
                                if (subject.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 3,
                                    ),
                                    decoration: ShapeDecoration(
                                      color: const Color(0xFFFFD27F),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                    child: Text(
                                      categoryText,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontFamily: 'Pretendard-Light',
                                        letterSpacing: -0.20,
                                      ),
                                    ),
                                  ),
                                if (_getChallengeApplicationDateRange(
                                  participationId,
                                ).isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 3,
                                    ),
                                    decoration: ShapeDecoration(
                                      color: const Color(0xFF5D9EFF),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                    child: Text(
                                      _getChallengeApplicationDateRange(
                                        participationId,
                                      ),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontFamily: 'Pretendard-Light',
                                        letterSpacing: -0.20,
                                      ),
                                    ),
                                  ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 3,
                                  ),
                                  decoration: ShapeDecoration(
                                    color:
                                        ChallengeService.getChallengeStatusColor(
                                          challengeStatus,
                                        ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                  child: Text(
                                    ChallengeService.getChallengeStatusText(
                                      challengeStatus,
                                    ),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontFamily: 'Pretendard-Light',
                                      letterSpacing: -0.20,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              title,
                              style: const TextStyle(
                                color: Color(0xFF202020),
                                fontSize: 16,
                                fontFamily: 'Pretendard-Bold',
                                letterSpacing: -0.64,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Text(
                                  '신청한 보상금',
                                  style: TextStyle(
                                    color: Color(0xFF666666),
                                    fontSize: 12,
                                    fontFamily: 'Pretendard-Light',
                                    letterSpacing: -0.24,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${reward?.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}원',
                                  style: const TextStyle(
                                    color: Color(0xFF3A88F4),
                                    fontSize: 14,
                                    fontFamily: 'Pretendard-Bold',
                                    letterSpacing: -0.28,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Text(
                                  '신청자',
                                  style: TextStyle(
                                    color: Color(0xFF666666),
                                    fontSize: 12,
                                    fontFamily: 'Pretendard-Light',
                                    letterSpacing: -0.24,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  childName,
                                  style: const TextStyle(
                                    color: Color(0xFF202020),
                                    fontSize: 12,
                                    fontFamily: 'Pretendard-Medium',
                                    letterSpacing: -0.24,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // 버튼 섹션
                      Container(
                        width: modalWidth,
                        padding: const EdgeInsets.symmetric(
                          vertical: 18,
                          horizontal: 18,
                        ),
                        decoration: const ShapeDecoration(
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(24),
                              bottomRight: Radius.circular(24),
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () async {
                                  Navigator.pop(context);
                                  await _rejectChallengeApplication(
                                    participationId,
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  decoration: ShapeDecoration(
                                    color: const Color(0xFFDADADA),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      '거절',
                                      style: TextStyle(
                                        color: Color(0xFFB6B6B6),
                                        fontSize: 12,
                                        fontFamily: 'Pretendard-Light',
                                        letterSpacing: -0.24,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: GestureDetector(
                                onTap: () async {
                                  Navigator.pop(context);
                                  await _acceptChallengeApplication(
                                    participationId,
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  decoration: ShapeDecoration(
                                    color: const Color(0xFF5D9EFF),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      '수락',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontFamily: 'Pretendard-Light',
                                        letterSpacing: -0.24,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // 챌린지 신청의 시작일과 종료일을 가져와서 포맷팅
  String _getChallengeApplicationDateRange(int participationId) {
    try {
      final challengeApp = _challengeApplications.firstWhere(
        (app) => app['participationId'] == participationId,
        orElse: () => <String, dynamic>{}, // 찾지 못하면 빈 Map 반환
      );

      if (challengeApp.isNotEmpty) {
        // isEmpty로 빈 Map 체크
        final startDate = ChallengeService.formatDate(
          challengeApp['startDate'],
        );
        final endDate = ChallengeService.formatDate(challengeApp['endDate']);

        if (startDate.isNotEmpty && endDate.isNotEmpty) {
          return '$startDate - $endDate';
        }
      }
    } catch (e) {
      print('챌린지 기간 조회 오류 ($participationId): $e');
      return '';
    }

    return '';
  }

  // 자녀 선택 모달 표시
  void _showChildSelectionModal() {
    if (_children == null || _children!.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('선택할 수 있는 자녀가 없습니다')));
      return;
    }

    // 현재 선택된 자녀의 인덱스 찾기
    int selectedIndex = 0;
    if (_selectedChild != null) {
      for (int i = 0; i < _children!.length; i++) {
        final childName =
            _children![i]['nickname'] ?? _children![i]['realName'] ?? '';
        final selectedChildName =
            _selectedChild?['nickname'] ?? _selectedChild?['realName'] ?? '';
        if (childName == selectedChildName && childName.isNotEmpty) {
          selectedIndex = i;
          break;
        }
      }
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return ChildSelectionModal(
          children: _children!,
          initialSelectedIndex: selectedIndex,
          onChildSelected: (selectedChild, selectedIndex) {
            setState(() {
              _selectedChild = selectedChild;
            });
            // 자녀 변경 시 알림 목록 다시 로드
            _loadGoalApplications();
            _loadChallengeApplications();
            _loadWeeklyGoals();
          },
        );
      },
    );
  }

  // 목표 완료 알림 아이템 위젯
  Widget _buildGoalCompletionItem(Map<String, dynamic> goalCompletion) {
    final String title = goalCompletion['title'] ?? '목표 없음';
    final String category = goalCompletion['category'] ?? 'LEARNING';
    final String childName = goalCompletion['childName'] ?? '자녀';
    final String completedTime = _formatInviteTime(
      goalCompletion['completedAt'] ?? '',
    );
    bool isRead = goalCompletion['read'] ?? false;

    return StatefulBuilder(
      builder: (context, setState) {
        return GestureDetector(
          onTap: () {
            setState(() {
              isRead = true;
              goalCompletion['read'] = true;
            });
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: ShapeDecoration(
              color: isRead ? const Color(0xFFE5E7ED) : Colors.white,
              shape: RoundedRectangleBorder(
                side: BorderSide(width: 0.40, color: const Color(0xFFC4C4C4)),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: double.infinity,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 24,
                                    height: 24,
                                    clipBehavior: Clip.antiAlias,
                                    decoration: BoxDecoration(),
                                    child: Image.asset(
                                      'assets/icons/notice/complete.png',
                                      width: 20,
                                      height: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: ShapeDecoration(
                                            color: const Color(0xFF89DA8D),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              Text(
                                                '완료',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 9,
                                                  fontFamily:
                                                      'Pretendard-ExtraLight',
                                                  letterSpacing: -0.22,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            '$childName님이 목표를 완료했어요!',
                                            style: const TextStyle(
                                              color: Color(0xFF202020),
                                              fontSize: 13,
                                              fontFamily: 'Pretendard-Medium',
                                              letterSpacing: -0.32,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '"$title" 목표를 성공적으로 완료했습니다!',
                              style: const TextStyle(
                                color: Color(0xFF4A4A4A),
                                fontSize: 12,
                                fontFamily: 'Pretendard-Light',
                                letterSpacing: -0.28,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  completedTime,
                                  style: TextStyle(
                                    color: const Color(0xFF999999),
                                    fontSize: 11,
                                    fontFamily: 'Pretendard-Light',
                                    letterSpacing: -0.22,
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 12,
                                      height: 12,
                                      margin: const EdgeInsets.only(right: 4),
                                      child: Transform.scale(
                                        scaleX: -1,
                                        child: Icon(
                                          Icons.check,
                                          size: 12,
                                          color:
                                              isRead
                                                  ? const Color(0xFF5D9EFF)
                                                  : const Color(0xFFB6B6B6),
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '확인했어요',
                                      style: TextStyle(
                                        color:
                                            isRead
                                                ? const Color(0xFF5D9EFF)
                                                : const Color(0xFFB6B6B6),
                                        fontSize: 10,
                                        fontFamily: 'Pretendard-Light',
                                        letterSpacing: -0.22,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 챌린지 완료 알림 아이템 위젯
  Widget _buildChallengeCompletionItem(
    Map<String, dynamic> challengeCompletion,
  ) {
    final String title = challengeCompletion['title'] ?? '챌린지 없음';
    final String subject = challengeCompletion['subject'] ?? '';
    final String childName = challengeCompletion['childName'] ?? '자녀';
    final String completedTime = _formatInviteTime(
      challengeCompletion['completedAt'] ?? '',
    );
    bool isRead = challengeCompletion['read'] ?? false;

    return StatefulBuilder(
      builder: (context, setState) {
        return GestureDetector(
          onTap: () {
            setState(() {
              isRead = true;
              challengeCompletion['read'] = true;
            });
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: ShapeDecoration(
              color: isRead ? const Color(0xFFE5E7ED) : Colors.white,
              shape: RoundedRectangleBorder(
                side: BorderSide(width: 0.40, color: const Color(0xFFC4C4C4)),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: double.infinity,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 24,
                                    height: 24,
                                    clipBehavior: Clip.antiAlias,
                                    decoration: BoxDecoration(),
                                    child: Image.asset(
                                      'assets/icons/notice/complete.png',
                                      width: 20,
                                      height: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: ShapeDecoration(
                                            color: const Color(0xFF89DA8D),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              Text(
                                                '완료',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 9,
                                                  fontFamily:
                                                      'Pretendard-ExtraLight',
                                                  letterSpacing: -0.22,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            '$childName님이 챌린지를 완료했어요!',
                                            style: const TextStyle(
                                              color: Color(0xFF202020),
                                              fontSize: 13,
                                              fontFamily: 'Pretendard-Medium',
                                              letterSpacing: -0.32,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '"$title" 챌린지를 성공적으로 완료했습니다!',
                              style: const TextStyle(
                                color: Color(0xFF4A4A4A),
                                fontSize: 12,
                                fontFamily: 'Pretendard-Light',
                                letterSpacing: -0.28,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  completedTime,
                                  style: TextStyle(
                                    color: const Color(0xFF999999),
                                    fontSize: 11,
                                    fontFamily: 'Pretendard-Light',
                                    letterSpacing: -0.22,
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 12,
                                      height: 12,
                                      margin: const EdgeInsets.only(right: 4),
                                      child: Transform.scale(
                                        scaleX: -1,
                                        child: Icon(
                                          Icons.check,
                                          size: 12,
                                          color:
                                              isRead
                                                  ? const Color(0xFF5D9EFF)
                                                  : const Color(0xFFB6B6B6),
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '확인했어요',
                                      style: TextStyle(
                                        color:
                                            isRead
                                                ? const Color(0xFF5D9EFF)
                                                : const Color(0xFFB6B6B6),
                                        fontSize: 10,
                                        fontFamily: 'Pretendard-Light',
                                        letterSpacing: -0.22,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 미션 완료 알림 아이템 위젯
  Widget _buildMissionCompletionItem(Map<String, dynamic> missionCompletion) {
    final String title = missionCompletion['title'] ?? '미션 없음';
    final String category = missionCompletion['category'] ?? 'LEARNING';
    final String childName = missionCompletion['childName'] ?? '자녀';
    final String completedTime = _formatInviteTime(
      missionCompletion['completedAt'] ?? '',
    );
    bool isRead = missionCompletion['read'] ?? false;

    return StatefulBuilder(
      builder: (context, setState) {
        return GestureDetector(
          onTap: () {
            setState(() {
              isRead = true;
              missionCompletion['read'] = true;
            });
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: ShapeDecoration(
              color: isRead ? const Color(0xFFE5E7ED) : Colors.white,
              shape: RoundedRectangleBorder(
                side: BorderSide(width: 0.40, color: const Color(0xFFC4C4C4)),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: double.infinity,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 24,
                                    height: 24,
                                    clipBehavior: Clip.antiAlias,
                                    decoration: BoxDecoration(),
                                    child: Image.asset(
                                      'assets/icons/notice/complete.png',
                                      width: 20,
                                      height: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: ShapeDecoration(
                                            color: const Color(0xFF89DA8D),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              Text(
                                                '완료',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 9,
                                                  fontFamily:
                                                      'Pretendard-ExtraLight',
                                                  letterSpacing: -0.22,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            '$childName님이 미션을 완료했어요!',
                                            style: const TextStyle(
                                              color: Color(0xFF202020),
                                              fontSize: 13,
                                              fontFamily: 'Pretendard-Medium',
                                              letterSpacing: -0.32,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '"$title" 미션을 성공적으로 완료했습니다!',
                              style: const TextStyle(
                                color: Color(0xFF4A4A4A),
                                fontSize: 12,
                                fontFamily: 'Pretendard-Light',
                                letterSpacing: -0.28,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  completedTime,
                                  style: TextStyle(
                                    color: const Color(0xFF999999),
                                    fontSize: 11,
                                    fontFamily: 'Pretendard-Light',
                                    letterSpacing: -0.22,
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 12,
                                      height: 12,
                                      margin: const EdgeInsets.only(right: 4),
                                      child: Transform.scale(
                                        scaleX: -1,
                                        child: Icon(
                                          Icons.check,
                                          size: 12,
                                          color:
                                              isRead
                                                  ? const Color(0xFF5D9EFF)
                                                  : const Color(0xFFB6B6B6),
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '확인했어요',
                                      style: TextStyle(
                                        color:
                                            isRead
                                                ? const Color(0xFF5D9EFF)
                                                : const Color(0xFFB6B6B6),
                                        fontSize: 10,
                                        fontFamily: 'Pretendard-Light',
                                        letterSpacing: -0.22,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 선택된 자녀에 따라 알림 필터링
  List<Map<String, dynamic>> _filterBySelectedChild(
    List<Map<String, dynamic>> items,
    String type,
  ) {
    if (_selectedChild == null) {
      return items;
    }

    final selectedChildUserId = _selectedChild!['userId'];
    final selectedChildFamilyMemberId = _selectedChild!['familyMemberId'];

    print(
      '🔍 선택된 자녀 필터링: ${_selectedChild!['nickname']} (userId: $selectedChildUserId, familyMemberId: $selectedChildFamilyMemberId)',
    );
    print('🔍 필터링 전 $type 개수: ${items.length}');

    final filteredItems =
        items.where((item) {
          // familyMemberId 또는 userId로 비교
          final itemFamilyMemberId = item['familyMemberId'];
          final itemUserId = item['userId'];
          final itemChildName = item['childName'] ?? item['childNickname'];

          bool matches = false;

          // 🔧 특별 케이스: 챌린지 데이터에서 familyMemberId가 실제로는 userId인 경우 (우선순위)
          if (itemFamilyMemberId != null && selectedChildUserId != null) {
            matches = itemFamilyMemberId == selectedChildUserId;
          }
          // familyMemberId로 비교
          else if (itemFamilyMemberId != null &&
              selectedChildFamilyMemberId != null) {
            matches = itemFamilyMemberId == selectedChildFamilyMemberId;
          }
          // userId로 비교
          else if (itemUserId != null && selectedChildUserId != null) {
            matches = itemUserId == selectedChildUserId;
          }
          // 이름으로 비교 (최후)
          else if (itemChildName != null) {
            final selectedChildName =
                _selectedChild!['nickname'] ?? _selectedChild!['realName'];
            matches = itemChildName == selectedChildName;
          }

          if (matches) {
            print('✅ $type 매칭: ${item['title'] ?? 'Unknown'} - $itemChildName');
          } else {
            print(
              '❌ $type 제외: ${item['title'] ?? 'Unknown'} - $itemChildName (familyMemberId: $itemFamilyMemberId, userId: $itemUserId)',
            );
          }

          return matches;
        }).toList();

    print('🔍 필터링 후 $type 개수: ${filteredItems.length}');
    return filteredItems;
  }
}

// 자녀 선택 모달 위젯
class ChildSelectionModal extends StatefulWidget {
  final List<dynamic> children;
  final int initialSelectedIndex;
  final Function(Map<String, dynamic>, int) onChildSelected;

  const ChildSelectionModal({
    Key? key,
    required this.children,
    required this.initialSelectedIndex,
    required this.onChildSelected,
  }) : super(key: key);

  @override
  State<ChildSelectionModal> createState() => _ChildSelectionModalState();
}

class _ChildSelectionModalState extends State<ChildSelectionModal> {
  late int selectedIndex;

  @override
  void initState() {
    super.initState();
    selectedIndex = widget.initialSelectedIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 20),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 420, minWidth: 420),
        child: Container(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 상단 헤더
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                decoration: ShapeDecoration(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '변경할 자녀를 선택해 주세요',
                            style: TextStyle(
                              color: const Color(0xFF202020),
                              fontSize: 16,
                              fontFamily: 'Pretendard-Bold',
                              letterSpacing: -0.64,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Icon(
                            Icons.close,
                            color: Colors.grey,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      '선택한 프로필에 따라 자녀의 정보를 조회할 수 있어요',
                      style: TextStyle(
                        color: const Color(0xFF999999),
                        fontSize: 10,
                        fontFamily: 'Pretendard-Light',
                        letterSpacing: -0.20,
                      ),
                    ),
                  ],
                ),
              ),

              // 자녀 프로필 그리드
              Container(
                width: 420,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                decoration: BoxDecoration(color: Colors.white),
                child: _buildChildrenGrid(),
              ),

              // 하단 버튼
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 24,
                ),
                decoration: ShapeDecoration(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                  ),
                ),
                child: GestureDetector(
                  onTap: () {
                    widget.onChildSelected(
                      widget.children[selectedIndex],
                      selectedIndex,
                    );
                    Navigator.pop(context);
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: ShapeDecoration(
                      color: const Color(0xFF5D9EFF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      '변경하기',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontFamily: 'Pretendard-Light',
                        letterSpacing: -0.24,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChildrenGrid() {
    List<Widget> rows = [];

    for (int i = 0; i < widget.children.length; i += 3) {
      List<Widget> rowChildren = [];
      int childrenInThisRow =
          (i + 3 <= widget.children.length) ? 3 : widget.children.length - i;

      for (int j = i; j < i + 3 && j < widget.children.length; j++) {
        final child = widget.children[j];
        final isSelected = selectedIndex == j;
        final profileImagePath = child['profileImagePath'];

        rowChildren.add(
          GestureDetector(
            onTap: () {
              setState(() {
                selectedIndex = j;
              });
            },
            child: Container(
              width: 80,
              height: 80,
              decoration: ShapeDecoration(
                shape: OvalBorder(
                  side: BorderSide(
                    width: isSelected ? 3.0 : 0.80,
                    color:
                        isSelected
                            ? const Color(0xFF5D9EFF)
                            : const Color(0xFF146AFF),
                  ),
                ),
              ),
              child: Stack(
                children: [
                  // 프로필 이미지
                  ClipRRect(
                    borderRadius: BorderRadius.circular(40),
                    child:
                        profileImagePath != null && profileImagePath.isNotEmpty
                            ? CachedNetworkImage(
                              imageUrl: AuthService.getFullProfileImageUrl(
                                profileImagePath,
                              ),
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                              placeholder:
                                  (context, url) => Container(
                                    color: Colors.grey[300],
                                    child: Icon(
                                      Icons.person,
                                      color: Colors.grey[600],
                                      size: 40,
                                    ),
                                  ),
                              errorWidget:
                                  (context, url, error) => Container(
                                    color: Colors.grey[300],
                                    child: Icon(
                                      Icons.person,
                                      color: Colors.grey[600],
                                      size: 40,
                                    ),
                                  ),
                            )
                            : Container(
                              width: 80,
                              height: 80,
                              color: Colors.grey[300],
                              child: Icon(
                                Icons.person,
                                color: Colors.grey[600],
                                size: 40,
                              ),
                            ),
                  ),

                  // 선택되지 않은 경우 RGB(93, 100, 101) 오버레이
                  if (!isSelected)
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Color.fromRGBO(93, 100, 101, 0.6),
                        shape: BoxShape.circle,
                      ),
                    ),

                  // 선택된 경우 체크 아이콘
                  if (isSelected)
                    Positioned(
                      right: 4,
                      bottom: 4,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: const Color(0xFF5D9EFF),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Icon(Icons.check, color: Colors.white, size: 14),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      }

      // 행별로 다른 정렬 방식 적용
      Widget rowWidget;
      if (childrenInThisRow == 3) {
        // 3명인 경우: spaceEvenly로 넓게 배치
        rowWidget = Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: rowChildren,
        );
      } else {
        // 2명 이하인 경우: 가운데 정렬하고 좁은 간격으로 배치
        rowWidget = Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (int k = 0; k < rowChildren.length; k++) ...[
              rowChildren[k],
              if (k < rowChildren.length - 1) SizedBox(width: 24), // 더 좁은 간격
            ],
          ],
        );
      }

      rows.add(rowWidget);

      if (i + 3 < widget.children.length) {
        rows.add(SizedBox(height: 24));
      }
    }

    return Column(mainAxisSize: MainAxisSize.min, children: rows);
  }
}
