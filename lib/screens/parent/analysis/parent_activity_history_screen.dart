import 'package:flutter/material.dart';
import 'dart:math';
import '../../../services/challenge_service.dart';
import '../../../widgets/parent/bottom_navigation_bar.dart';
import '../../../services/family_service.dart';
import '../../../services/auth_service.dart';
import '../../../services/goal_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../services/mission_service.dart';

class ParentActivityHistoryScreen extends StatefulWidget {
  final int initialTabIndex;

  const ParentActivityHistoryScreen({
    Key? key,
    this.initialTabIndex = 0, // 기본값 설정
  }) : super(key: key);

  @override
  State<ParentActivityHistoryScreen> createState() =>
      _ParentActivityHistoryScreenState();
}

class _ParentActivityHistoryScreenState
    extends State<ParentActivityHistoryScreen>
    with SingleTickerProviderStateMixin {
  // late TabController _tabController;
  TabController? _tabController;
  int _selectedIndex = 0;
  bool _isMissionInProgress = true;
  bool _isChallengeInProgress = true;
  bool _isGoalInProgress = true;

  // 챌린지 데이터 관련 상태
  List<ChallengeParticipation> _challengeList = [];
  bool _isChallengeLoading = false;
  String? _challengeError;

  // 추천 챌린지 관련 상태
  Challenge? _recommendedChallenge;
  bool _isRecommendedChallengeLoading = false;
  String? _recommendedChallengeError;

  // 가족 정보 관련 변수들 추가
  List<dynamic>? _familyMembers;
  bool _isLoadingFamily = true;
  String? _familyError;

  // 선택된 자녀 정보 추가
  Map<String, dynamic>? _selectedChild;

  // 목표 데이터 관련 상태
  List<Map<String, dynamic>> _goalList = [];
  bool _isGoalLoading = false;
  String? _goalError;

  // 미션 데이터 관련 상태 추가
  List<MissionResponse> _missionList = [];
  bool _isMissionLoading = false;
  String? _missionError;

  String _selectedChallengeFilter = '전체';
  String _selectedChallengeSort = '보상금이 높은 순';
  List<Map<String, dynamic>> _filteredParticipatingMissions = [];

  @override
  void initState() {
    super.initState();
    // 안전하게 초기화
    _initTabController();

    // 추천 챌린지 데이터 로드
    _loadRecommendedChallenge();

    // 가족 구성원 목록 불러오기 (완료 후 챌린지, 목표, 미션 데이터 로드)
    _loadFamilyMembers();

    // 디버깅: 초기 데이터 확인
    print('활동 내역 화면 - initState');
  }

  // 챌린지 데이터 로드
  Future<void> _loadChallengeData() async {
    setState(() {
      _isChallengeLoading = true;
      _challengeError = null;
    });

    try {
      print('===== 챌린지 데이터 로드 시작 =====');

      // 선택된 자녀 정보 확인
      if (_selectedChild == null) {
        throw Exception('선택된 자녀가 없습니다');
      }

      print('선택된 자녀 정보: $_selectedChild');

      // API 문서에 따르면 childId는 "자식 유저 고유 id"이므로 userId를 사용
      final childId = _selectedChild!['userId'];
      final familyMemberId = _selectedChild!['familyMemberId'];

      print('자녀 userId: $childId');
      print('자녀 familyMemberId: $familyMemberId');

      if (childId == null) {
        throw Exception('자녀 userId를 찾을 수 없습니다');
      }

      // 가족 정보 가져오기 (재시도 로직 추가)
      Map<String, dynamic>? familyInfo;

      try {
        familyInfo = await FamilyService.getFamilyInfo();
        print('가족 정보 1차 조회 성공: $familyInfo');
      } catch (e) {
        print('가족 정보 1차 조회 실패: $e');
        // 잠시 대기 후 재시도
        await Future.delayed(Duration(milliseconds: 500));
        try {
          familyInfo = await FamilyService.getFamilyInfo();
          print('가족 정보 2차 조회 성공: $familyInfo');
        } catch (e2) {
          print('가족 정보 2차 조회 실패: $e2');
        }
      }

      if (familyInfo == null) {
        // 가족 정보를 못 가져왔지만, 기본값으로 시도
        print('⚠️ 가족 정보 조회 실패 - 기본 familyId(1)로 시도');
        final familyId = 1; // 기본값

        await _attemptChallengeLoad(familyId, childId);
        return;
      }

      final familyId = familyInfo['familyId'];
      print('가족 ID: $familyId');

      if (familyId == null) {
        throw Exception('가족 ID를 찾을 수 없습니다');
      }

      await _attemptChallengeLoad(familyId, childId);
    } catch (e) {
      setState(() {
        _challengeError = e.toString();
        _isChallengeLoading = false;
      });
      print('챌린지 데이터 로드 오류: $e');
    }
  }

  // 챌린지 로드 시도 (재시도 로직 포함)
  Future<void> _attemptChallengeLoad(int familyId, int childId) async {
    print('챌린지 조회: familyId=$familyId, childId=$childId');

    // 첫 번째 시도
    try {
      final response = await ChallengeService.getChildChallenges(
        familyId,
        childId,
      );
      await _processChallengeResponse(response);
      return;
    } catch (e) {
      print('챌린지 1차 조회 실패: $e');

      // 500 오류이거나 서버 오류인 경우 재시도
      if (e.toString().contains('500') || e.toString().contains('서버')) {
        print('서버 오류 감지 - 재시도 중...');

        // 잠시 대기 후 재시도
        await Future.delayed(Duration(seconds: 1));

        try {
          final response = await ChallengeService.getChildChallenges(
            familyId,
            childId,
          );
          await _processChallengeResponse(response);
          return;
        } catch (e2) {
          print('챌린지 2차 조회 실패: $e2');

          // 마지막 재시도
          await Future.delayed(Duration(seconds: 2));

          try {
            final response = await ChallengeService.getChildChallenges(
              familyId,
              childId,
            );
            await _processChallengeResponse(response);
            return;
          } catch (e3) {
            print('챌린지 3차 조회 실패: $e3');
            // 모든 재시도 실패 시 빈 데이터로 처리
            _handleChallengeLoadFailure('서버 연결에 문제가 있습니다. 나중에 다시 시도해주세요.');
          }
        }
      } else {
        // 다른 오류는 바로 실패 처리
        _handleChallengeLoadFailure(e.toString());
      }
    }
  }

  // 챌린지 응답 처리
  Future<void> _processChallengeResponse(
    ChallengeParticipationResponse? response,
  ) async {
    if (response != null) {
      print('=== 챌린지 필터링 시작 ===');
      print('현재 시간: ${DateTime.now()}');
      print('필터 모드: ${_isChallengeInProgress ? "진행중" : "완료한"}');
      print('전체 챌린지 개수: ${response.data.length}');

      // 진행 상태에 따라 필터링
      List<ChallengeParticipation> filteredChallenges;

      if (_isChallengeInProgress) {
        // 진행 중인 챌린지: 종료날짜가 지나지 않은 챌린지들
        filteredChallenges =
            response.data.where((challenge) {
              // ONGOING은 무조건 진행중
              if (challenge.challengeStatus == 'ONGOING') {
                print('진행중 체크 - 챌린지: ${challenge.title} (ONGOING)');
                print('  상태: ONGOING -> 진행중');
                return true;
              }

              // ACCEPT, REQUESTED 상태는 종료날짜 확인
              if (challenge.challengeStatus == 'ACCEPT' ||
                  challenge.challengeStatus == 'REQUESTED') {
                try {
                  final endDate = DateTime.parse(challenge.endDate);
                  final now = DateTime.now();
                  final isInProgress =
                      now.isBefore(endDate) || now.isAtSameMomentAs(endDate);

                  print(
                    '진행중 체크 - 챌린지: ${challenge.title} (${challenge.challengeStatus})',
                  );
                  print('  현재 시간: $now');
                  print('  종료 시간: $endDate');
                  print('  진행중 여부: $isInProgress');

                  return isInProgress;
                } catch (e) {
                  print('챌린지 ${challenge.title} 종료날짜 파싱 오류: $e');
                  return true; // 파싱 오류 시 진행중으로 간주
                }
              }

              return false;
            }).toList();
      } else {
        // 완료된 챌린지: ACHIEVEMENT 또는 종료날짜가 지난 챌린지들
        filteredChallenges =
            response.data.where((challenge) {
              // ACHIEVEMENT는 무조건 완료
              if (challenge.challengeStatus == 'ACHIEVEMENT') {
                print('완료 체크 - 챌린지: ${challenge.title} (ACHIEVEMENT)');
                print('  상태: ACHIEVEMENT -> 완료');
                return true;
              }

              // ACCEPT, REQUESTED 상태는 종료날짜 확인
              if (challenge.challengeStatus == 'ACCEPT' ||
                  challenge.challengeStatus == 'REQUESTED') {
                try {
                  final endDate = DateTime.parse(challenge.endDate);
                  final now = DateTime.now();
                  final isCompleted = now.isAfter(endDate);

                  print(
                    '완료 체크 - 챌린지: ${challenge.title} (${challenge.challengeStatus})',
                  );
                  print('  현재 시간: $now');
                  print('  종료 시간: $endDate');
                  print('  완료 여부: $isCompleted');

                  return isCompleted;
                } catch (e) {
                  print('챌린지 ${challenge.title} 종료날짜 파싱 오류: $e');
                  return false; // 파싱 오류 시 완료로 간주하지 않음
                }
              }

              return false;
            }).toList();
      }

      setState(() {
        _challengeList = filteredChallenges;
        _isChallengeLoading = false;
      });

      print(
        '${_selectedChild!['nickname'] ?? _selectedChild!['realName']}의 챌린지 데이터 (${_isChallengeInProgress ? "진행중" : "완료한"}) 로드 완료: ${_challengeList.length}개',
      );

      // 각 챌린지의 상태와 날짜 디버깅
      for (var challenge in filteredChallenges) {
        print(
          '챌린지: ${challenge.title}, 상태: ${challenge.challengeStatus}, 종료일: ${challenge.endDate}',
        );
      }
    } else {
      setState(() {
        _challengeList = [];
        _isChallengeLoading = false;
      });
      print('챌린지 데이터가 없습니다');
    }
  }

  // 챌린지 로드 실패 처리
  void _handleChallengeLoadFailure(String errorMessage) {
    setState(() {
      _challengeList = [];
      _challengeError = errorMessage;
      _isChallengeLoading = false;
    });
    print('최종 챌린지 로드 실패: $errorMessage');
  }

  // 미션 데이터 로드 추가
  Future<void> _loadMissionData() async {
    setState(() {
      _isMissionLoading = true;
      _missionError = null;
    });

    try {
      // 선택된 자녀 정보 확인
      if (_selectedChild == null) {
        throw Exception('선택된 자녀가 없습니다');
      }

      // userId를 우선적으로 사용하고, 없으면 familyMemberId를 사용
      final childId =
          _selectedChild!['userId'] ?? _selectedChild!['familyMemberId'];
      if (childId == null) {
        print('⚠️ 자녀 ID(userId, familyMemberId) 모두 없음 - 빈 미션 목록으로 처리');
        setState(() {
          _missionList = [];
          _isMissionLoading = false;
        });
        return;
      }

      print('미션 조회: childId=$childId (userId 우선)');

      // 선택된 자녀의 미션 조회
      final response = await MissionService.getParentChildMissions(
        childId: childId,
      );

      if (response != null && response['data'] != null) {
        final List<dynamic> missionData = response['data'];

        // MissionResponse 객체로 변환
        List<MissionResponse> missions =
            missionData.map((json) => MissionResponse.fromJson(json)).toList();

        // 진행 상태에 따라 필터링
        List<MissionResponse> filteredMissions;

        if (_isMissionInProgress) {
          // 진행 중인 미션: 진행 대기, 진행중, 승인 대기 상태
          filteredMissions =
              missions.where((mission) {
                final status = MissionService.getMissionProgressStatus(mission);
                return status == '승인 대기' ||
                    status == '진행 대기' ||
                    status == '진행중';
              }).toList();
        } else {
          // 완료한 미션: 완료한, 달성 상태
          filteredMissions =
              missions.where((mission) {
                final status = MissionService.getMissionProgressStatus(mission);
                return status == '완료한' || status == '달성';
              }).toList();
        }

        setState(() {
          _missionList = filteredMissions;
          _isMissionLoading = false;
        });

        print(
          '${_selectedChild!['nickname'] ?? _selectedChild!['realName']}의 미션 데이터 로드 완료: ${_missionList.length}개',
        );
      } else {
        setState(() {
          _missionList = [];
          _isMissionLoading = false;
        });
        print('미션 데이터가 없습니다');
      }
    } catch (e) {
      setState(() {
        _missionError = e.toString();
        _isMissionLoading = false;
      });
      print('미션 데이터 로드 오류: $e');
    }
  }

  // 추천 챌린지 데이터 로드
  Future<void> _loadRecommendedChallenge() async {
    setState(() {
      _isRecommendedChallengeLoading = true;
      _recommendedChallengeError = null;
    });

    try {
      // 전체 챌린지 목록 가져오기
      final response = await ChallengeService.getChallenges(
        category: ChallengeCategory.ALL,
        page: 0,
      );

      if (response.data.isNotEmpty) {
        // 랜덤으로 하나 선택
        final random = Random();
        final randomIndex = random.nextInt(response.data.length);
        setState(() {
          _recommendedChallenge = response.data[randomIndex];
          _isRecommendedChallengeLoading = false;
        });

        print('추천 챌린지 로드 완료: ${_recommendedChallenge?.title}');
      } else {
        setState(() {
          _recommendedChallengeError = '추천할 챌린지가 없습니다.';
          _isRecommendedChallengeLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _recommendedChallengeError = e.toString();
        _isRecommendedChallengeLoading = false;
      });
      print('추천 챌린지 로드 오류: $e');
    }
  }

  // 목표 데이터 로드
  Future<void> _loadGoalData() async {
    setState(() {
      _isGoalLoading = true;
      _goalError = null;
    });

    try {
      // 선택된 자녀 정보 확인
      if (_selectedChild == null) {
        throw Exception('선택된 자녀가 없습니다');
      }

      final selectedChildId = _selectedChild!['familyMemberId'];
      if (selectedChildId == null) {
        throw Exception('자녀의 familyMemberId를 찾을 수 없습니다');
      }

      // 가족 정보 가져오기 (재시도 로직 추가)
      Map<String, dynamic>? familyInfo;

      try {
        familyInfo = await FamilyService.getFamilyInfo();
      } catch (e) {
        print('목표 - 가족 정보 1차 조회 실패: $e');
        // 잠시 대기 후 재시도
        await Future.delayed(Duration(milliseconds: 500));
        try {
          familyInfo = await FamilyService.getFamilyInfo();
        } catch (e2) {
          print('목표 - 가족 정보 2차 조회 실패: $e2');
        }
      }

      if (familyInfo == null) {
        // 가족 정보를 못 가져왔지만, 기본값으로 시도
        print('⚠️ 목표 - 가족 정보 조회 실패 - 기본 familyId(1)로 시도');
        final familyId = 1; // 기본값

        print(
          '목표 조회: familyId=$familyId (기본값), selectedChildId=$selectedChildId (familyMemberId 기준)',
        );

        // 목표 상태에 따라 다른 API 호출
        List<Map<String, dynamic>>? allGoals;

        if (_isGoalInProgress) {
          // 진행 중인 목표: 이번 주 목표에서 ACCEPT 상태만 필터링
          try {
            final weeklyGoals = await GoalService.getParentWeeklyGoals(
              familyId,
            );
            if (weeklyGoals != null) {
              allGoals =
                  weeklyGoals
                      .where((goal) => goal['status'] == 'ACCEPT')
                      .toList();
            }
          } catch (e) {
            print('진행 중인 목표 조회 실패: $e');
            allGoals = [];
          }
        } else {
          // 완료한 목표: 모든 목표에서 ACHIEVEMENT 상태만 필터링
          try {
            final allGoalsResponse = await GoalService.getParentAllGoals(
              familyId,
            );
            if (allGoalsResponse != null) {
              allGoals =
                  allGoalsResponse
                      .where((goal) => goal['status'] == 'ACHIEVEMENT')
                      .toList();
            }
          } catch (e) {
            print('완료한 목표 조회 실패: $e');
            allGoals = [];
          }
        }

        // 선택된 자녀의 목표만 필터링
        List<Map<String, dynamic>> filteredGoals = [];
        if (allGoals != null) {
          filteredGoals =
              allGoals.where((goal) {
                final goalFamilyMemberId = goal['familyMemberId'];
                return goalFamilyMemberId == selectedChildId;
              }).toList();

          // 각 목표에 대해 도장 정보도 함께 가져오기
          for (var goal in filteredGoals) {
            final goalId = goal['goalId'];
            if (goalId != null) {
              try {
                final checkData = await GoalService.getGoalCheck(goalId);
                if (checkData != null) {
                  goal['goalCheck'] = checkData;
                  print('목표 ${goal['title']}의 도장 데이터 로드: $checkData');
                }
              } catch (e) {
                print('목표 $goalId의 도장 데이터 로드 실패: $e');
              }
            }
          }
        }

        setState(() {
          _goalList = filteredGoals;
          _isGoalLoading = false;
        });

        print(
          '${_selectedChild!['nickname'] ?? _selectedChild!['realName']}의 목표 데이터 로드 완료: ${_goalList.length}개',
        );
        return;
      }

      final familyId = familyInfo['familyId'];
      print(
        '목표 조회: familyId=$familyId, selectedChildId=$selectedChildId (familyMemberId 기준)',
      );

      // 목표 상태에 따라 다른 API 호출
      List<Map<String, dynamic>>? allGoals;

      if (_isGoalInProgress) {
        // 진행 중인 목표: 이번 주 목표에서 ACCEPT 상태만 필터링
        final weeklyGoals = await GoalService.getParentWeeklyGoals(familyId);
        if (weeklyGoals != null) {
          allGoals =
              weeklyGoals.where((goal) => goal['status'] == 'ACCEPT').toList();
        }
      } else {
        // 완료한 목표: 모든 목표에서 ACHIEVEMENT 상태만 필터링
        final allGoalsResponse = await GoalService.getParentAllGoals(familyId);
        if (allGoalsResponse != null) {
          allGoals =
              allGoalsResponse
                  .where((goal) => goal['status'] == 'ACHIEVEMENT')
                  .toList();
        }
      }

      // 선택된 자녀의 목표만 필터링
      List<Map<String, dynamic>> filteredGoals = [];
      if (allGoals != null) {
        filteredGoals =
            allGoals.where((goal) {
              final goalFamilyMemberId = goal['familyMemberId'];
              return goalFamilyMemberId == selectedChildId;
            }).toList();

        // 각 목표에 대해 도장 정보도 함께 가져오기
        for (var goal in filteredGoals) {
          final goalId = goal['goalId'];
          if (goalId != null) {
            try {
              final checkData = await GoalService.getGoalCheck(goalId);
              if (checkData != null) {
                goal['goalCheck'] = checkData;
                print('목표 ${goal['title']}의 도장 데이터 로드: $checkData');
              }
            } catch (e) {
              print('목표 $goalId의 도장 데이터 로드 실패: $e');
            }
          }
        }
      }

      setState(() {
        _goalList = filteredGoals;
        _isGoalLoading = false;
      });

      print(
        '${_selectedChild!['nickname'] ?? _selectedChild!['realName']}의 목표 데이터 로드 완료: ${_goalList.length}개',
      );
    } catch (e) {
      setState(() {
        _goalError = e.toString();
        _isGoalLoading = false;
      });
      print('목표 데이터 로드 오류: $e');
    }
  }

  // 가족 구성원 목록 불러오기
  Future<void> _loadFamilyMembers() async {
    try {
      if (mounted) {
        setState(() {
          _isLoadingFamily = true;
          _familyError = null;
        });
      }

      print('활동 내역 화면: 가족 구성원 목록 로드 시작');

      final familyInfo = await FamilyService.getFamilyInfo();

      if (familyInfo != null) {
        final List<dynamic> memberList = familyInfo['memberInfoList'] ?? [];
        print('활동 내역 화면: 가족 정보 로드 성공 - 멤버 ${memberList.length}명');

        // 자녀만 필터링
        final children =
            memberList.where((member) => member['role'] != 'PARENT').toList();

        if (mounted) {
          setState(() {
            _familyMembers = children;
            _selectedChild =
                children.isNotEmpty ? children[0] : null; // 첫 번째 자녀를 기본 선택
            _isLoadingFamily = false;
          });
        }

        // 가족 정보 로드 완료 후 챌린지와 목표, 미션 데이터 로드
        if (_selectedChild != null) {
          print(
            '선택된 자녀: ${_selectedChild!['nickname'] ?? _selectedChild!['realName']}',
          );
          await _loadChallengeData();
          await _loadGoalData();
          await _loadMissionData(); // 미션 데이터 로드 추가
        }
      } else {
        print('활동 내역 화면: 가족 정보 조회 실패 또는 가족 정보 없음');

        if (mounted) {
          setState(() {
            _familyMembers = [];
            _selectedChild = null;
            _isLoadingFamily = false;
          });
        }
      }
    } catch (e) {
      print('활동 내역 화면: 가족 구성원 목록 로드 중 예외 발생: $e');

      if (mounted) {
        setState(() {
          _familyError = '가족 정보를 불러올 수 없습니다';
          _isLoadingFamily = false;
          _familyMembers = [];
          _selectedChild = null;
        });
      }
    }
  }

  void _initTabController() {
    try {
      _tabController = TabController(
        length: 3,
        vsync: this,
        initialIndex: widget.initialTabIndex,
      );
      _selectedIndex = widget.initialTabIndex;

      _tabController?.addListener(() {
        if (_tabController!.indexIsChanging) {
          setState(() {
            _selectedIndex = _tabController!.index;
          });
        }
      });
    } catch (e) {
      print('TabController 초기화 오류: $e');
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // TabController가 null인 경우를 대비한 안전 확인
    if (_tabController == null) {
      _initTabController();
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          '활동내역',
          style: TextStyle(
            color: Color(0xFF202020),
            fontSize: 14,
            fontFamily: 'Pretendard-Bold',
            letterSpacing: -0.32,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: Image.asset(
            'assets/icons/parent/my/point/back.png',
            width: 20,
            height: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          // 자녀 선택 버튼
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                          _isLoadingFamily
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
                              : _selectedChild?['profileImagePath'] != null &&
                                  _selectedChild!['profileImagePath']!
                                      .isNotEmpty
                              ? CachedNetworkImage(
                                imageUrl: AuthService.getFullProfileImageUrl(
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
                                    (context, url, error) => Container(
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
          ),

          // 홈 아이콘
          IconButton(
            icon: Image.asset('assets/images/home.png', width: 24, height: 24),
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ],
        bottom: null,
      ),
      body: Column(
        children: [
          // TabBar 직접 구현
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(color: Colors.white),
            child: TabBar(
              controller: _tabController,
              dividerColor: Colors.transparent, // 탭바 하단 구분선 제거
              indicator: UnderlineTabIndicator(
                borderSide: BorderSide(width: 3.0, color: Colors.black),
                insets: EdgeInsets.zero, // 인디케이터 여백 제거
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Color(0xFF000000),
              unselectedLabelColor: Colors.grey,
              labelPadding: EdgeInsets.zero, // 라벨 패딩 제거
              tabAlignment: TabAlignment.fill, // 탭을 화면 너비에 맞게 균등하게 배치
              labelStyle: const TextStyle(
                fontFamily: 'Pretendard-Black',
                fontSize: 13,
              ),
              unselectedLabelStyle: const TextStyle(
                fontFamily: 'Pretendard-Regular',
                fontSize: 13,
              ),
              tabs: const [
                Tab(text: '미션', height: 28),
                Tab(text: '챌린지', height: 28),
                Tab(text: '목표', height: 28),
              ],
            ),
          ),
          // 나머지 화면 내용
          Expanded(
            child:
                _tabController == null
                    ? const Center(child: CircularProgressIndicator())
                    : Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        // 모든 테두리 제거
                      ),
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildMissionTab(),
                          _buildChallengeTab(),
                          _buildGoalTab(),
                        ],
                      ),
                    ),
          ),
          _selectedIndex == 0 ? _buildAnalyticsReportButton() : SizedBox(),
        ],
      ),
      bottomNavigationBar: const ParentBottomNavigationBar(selectedIndex: 4),
    );
  }

  // 분석 리포트 버튼
  Widget _buildAnalyticsReportButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 24, left: 16, right: 16, bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x5B000000),
            blurRadius: 8,
            offset: Offset(0, -4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
            decoration: ShapeDecoration(
              color: const Color(0xFF3A88F4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  '분석 리포트 보러가기',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontFamily: 'Pretendard-Light',
                    letterSpacing: -0.28,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 미션 탭 내용
  Widget _buildMissionTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 완료한 미션 알림 섹션
          _buildCompletedMissionSection(),

          const SizedBox(height: 0),

          // 미션 필터 섹션
          _buildFilterSection(_isMissionInProgress, (value) {
            setState(() {
              _isMissionInProgress = value;
            });
            // 필터 변경 시 미션 데이터 다시 로드
            _loadMissionData();
          }),

          const SizedBox(height: 24),

          // 미션 목록 섹션
          _buildMissionListSection(),
        ],
      ),
    );
  }

  // 챌린지 탭 내용
  Widget _buildChallengeTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 완료한 챌린지 알림 섹션
          _buildCompletedChallengeSection(),

          const SizedBox(height: 0),

          // 챌린지 필터 섹션
          _buildFilterSection(_isChallengeInProgress, (value) {
            setState(() {
              _isChallengeInProgress = value;
            });
            // 필터 변경 시 챌린지 데이터 다시 로드
            _loadChallengeData();
          }),

          const SizedBox(height: 24),

          // 챌린지 목록 섹션
          _buildChallengeListSection(),
        ],
      ),
    );
  }

  // 챌린지 목록 섹션
  Widget _buildChallengeListSection() {
    // 로딩 중일 때
    if (_isChallengeLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFF3A88F4)),
        ),
      );
    }

    // 에러가 발생했을 때
    if (_challengeError != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.error_outline, color: Color(0xFFFF6B6B), size: 48),
              SizedBox(height: 16),
              Text(
                _challengeError!.contains('서버')
                    ? '서버 연결에 문제가 있어요\n잠시 후 다시 시도해주세요'
                    : '챌린지 정보를 불러올 수 없어요',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF666666),
                  fontSize: 14,
                  fontFamily: 'Pretendard-Regular',
                  height: 1.4,
                ),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 다시 시도 버튼
                  ElevatedButton.icon(
                    onPressed: _loadChallengeData,
                    icon: Icon(Icons.refresh, size: 16),
                    label: Text(
                      '다시 시도',
                      style: TextStyle(
                        fontFamily: 'Pretendard-Medium',
                        fontSize: 12,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF3A88F4),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  // 건너뛰기 버튼
                  OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _challengeError = null;
                        _challengeList = [];
                      });
                    },
                    child: Text(
                      '건너뛰기',
                      style: TextStyle(
                        fontFamily: 'Pretendard-Light',
                        fontSize: 12,
                        color: Color(0xFF666666),
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      side: BorderSide(color: Color(0xFFDDDDDD)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 카드 사이에 간격을 추가하기 위해 List.generate 사용
          ...List.generate(_challengeList.length, (index) {
            final challenge = _challengeList[index];

            // 챌린지 데이터를 카드에 맞는 형태로 변환
            final String title = challenge.title;
            final String participants =
                '참여중'; // ChallengeParticipation에는 참여자 수 정보가 없음
            final String period =
                '${challenge.startDate} - ${challenge.endDate}';

            // 실제 총 공부시간 계산 (일일 목표 시간 × 기간)
            final int calculatedTotalStudyTime = _calculateTotalStudyTime(
              challenge,
            );

            // 챌린지 카테고리에 따른 태그 설정 (ChallengeParticipation에는 category가 없으므로 subject로 판단)
            final List<String> tags = [
              '챌린지',
              period,
              challenge.subject != null ? '과목별' : '요일별',
            ];

            // 각 카드와 하단 간격(마지막 카드 제외)
            return Column(
              children: [
                _buildChallengeItem(
                  challenge, // ChallengeParticipation 객체 전체 전달
                ),
                // 마지막 항목이 아닐 경우 간격 추가
                if (index < _challengeList.length - 1)
                  const SizedBox(height: 24),
              ],
            );
          }),

          // 데이터가 없는 경우 안내 메시지 표시
          if (_challengeList.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Text(
                  _isChallengeInProgress
                      ? '참여 중인 챌린지가 없습니다.'
                      : '완료한 챌린지가 없습니다.',
                  style: TextStyle(
                    color: Color(0xFF999999),
                    fontSize: 14,
                    fontFamily: 'Pretendard-Light',
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // 챌린지 카테고리 표시명 변환
  String _getCategoryDisplayName(String category) {
    switch (category.toUpperCase()) {
      case 'WEEK':
        return '요일별';
      case 'SUBJECT':
        return '과목별';
      default:
        return '일반';
    }
  }

  Widget _buildChallengeFilterTab(String title, double width) {
    final isSelected = _selectedChallengeFilter == title;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedChallengeFilter = title;
          _filterChallenges();
        });
      },
      child: Container(
        width: width,
        height: 36,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              width: isSelected ? 2.0 : 1.0,
              color: isSelected ? Colors.black : const Color(0xFFEDEDED),
            ),
          ),
          color: Colors.white,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color:
                    isSelected
                        ? const Color(0xFF202020)
                        : const Color(0xFF999999),
                fontSize: 14,
                fontFamily: isSelected ? 'Pretendard-Bold' : 'Pretendard-Light',
                letterSpacing: -0.32,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChallengeSortOption(String title) {
    final isSelected = _selectedChallengeSort == title;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedChallengeSort = title;
          _sortChallenges();
        });
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Container(
              width: 6,
              height: 6,
              decoration: ShapeDecoration(
                color:
                    isSelected
                        ? const Color(0xFF5D9EFF)
                        : const Color(0xFFB6B6B6),
                shape: const OvalBorder(),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            title,
            style: TextStyle(
              color:
                  isSelected
                      ? const Color(0xFF001F55)
                      : const Color(0xFFB6B6B6),
              fontSize: 12,
              fontFamily: isSelected ? 'Pretendard-Medium' : 'Pretendard-Light',
              letterSpacing: -0.28,
            ),
          ),
        ],
      ),
    );
  }

  // 미션 목록 섹션
  Widget _buildMissionListSection() {
    // 로딩 중일 때
    if (_isMissionLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFF3A88F4)),
        ),
      );
    }

    // 에러가 발생했을 때
    if (_missionError != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
        child: Center(
          child: Column(
            children: [
              Text(
                '미션을 불러오는 중 오류가 발생했습니다.',
                style: TextStyle(
                  color: Color(0xFF999999),
                  fontSize: 14,
                  fontFamily: 'Pretendard-Light',
                ),
              ),
              SizedBox(height: 8),
              ElevatedButton(
                onPressed: _loadMissionData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF3A88F4),
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  '다시 시도',
                  style: TextStyle(
                    fontFamily: 'Pretendard-Light',
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 카드 사이에 간격을 추가하기 위해 List.generate 사용
          ...List.generate(_missionList.length, (index) {
            final mission = _missionList[index];

            // 미션 데이터를 카드에 맞는 형태로 변환
            final String title = mission.title;
            final String type =
                mission.type == MissionType.FAMILY ? '가족 미션' : '학원 미션';

            // 날짜 포맷팅
            String period = '';
            try {
              final startDate = mission.startDate;
              final endDate = mission.endDate;
              period =
                  '${startDate.month.toString().padLeft(2, '0')}.${startDate.day.toString().padLeft(2, '0')} - ${endDate.month.toString().padLeft(2, '0')}.${endDate.day.toString().padLeft(2, '0')}';
            } catch (e) {
              period = '기간 정보 없음';
            }

            // 보상금 포맷팅
            final String reward =
                '${mission.reward.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}원';

            // D-Day 계산
            final String dDay = MissionService.calculateMissionDDay(mission);

            // 미션 타입에 따른 태그 설정
            final List<String> tags = ['미션', type, period];

            // 각 카드와 하단 간격(마지막 카드 제외)
            return Column(
              children: [
                _buildMissionItem(title, period, dDay, reward, tags),
                // 마지막 항목이 아닐 경우 간격 추가
                if (index < _missionList.length - 1) const SizedBox(height: 24),
              ],
            );
          }),

          // 데이터가 없는 경우 안내 메시지 표시
          if (_missionList.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Text(
                  _isMissionInProgress ? '참여 중인 미션이 없습니다.' : '완료한 미션이 없습니다.',
                  style: TextStyle(
                    color: Color(0xFF999999),
                    fontSize: 14,
                    fontFamily: 'Pretendard-Light',
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // 챌린지 총 공부시간 계산 (일일 목표 시간 × 기간)
  int _calculateTotalStudyTime(ChallengeParticipation challenge) {
    try {
      // 날짜 파싱
      final startDate = DateTime.parse(challenge.startDate);
      final endDate = DateTime.parse(challenge.endDate);

      // 기간 계산 (일수)
      final duration = endDate.difference(startDate).inDays + 1; // +1은 시작일 포함

      // 총 공부시간 = 일일 목표 시간 × 기간
      return challenge.totalStudyTime * duration;
    } catch (e) {
      print('총 공부시간 계산 오류: $e');
      // 오류 발생 시 원래 값 반환
      return challenge.totalStudyTime;
    }
  }

  // 챌린지 진행 시간 계산 (임시 계산 로직)
  String _calculateProgressTime(ChallengeParticipation challenge) {
    try {
      final startDate = DateTime.parse(challenge.startDate);
      final now = DateTime.now();
      final elapsedDays = now.difference(startDate).inDays + 1;

      // 시작 날짜가 아직 오지 않은 경우
      if (elapsedDays <= 0) {
        return '진행 예정';
      }

      // 임시로 하루 2시간 진행으로 계산
      final progressHours = elapsedDays * 2;
      final hours = progressHours ~/ 1;
      final minutes = (progressHours % 1 * 60).toInt();

      return '${hours}시간 ${minutes}분';
    } catch (e) {
      print('진행 시간 계산 오류: $e');
      return '0시간 0분';
    }
  }

  // 챌린지 D-Day 계산
  String _calculateChallengeDDay(ChallengeParticipation challenge) {
    try {
      final endDate = DateTime.parse(challenge.endDate);
      final now = DateTime.now();
      final difference = endDate.difference(now).inDays;

      if (difference > 0) {
        return 'D-$difference';
      } else if (difference == 0) {
        return 'D-Day';
      } else {
        return '완료';
      }
    } catch (e) {
      print('D-Day 계산 오류: $e');
      return 'D-?';
    }
  }

  // 챌린지 아이템 위젯
  Widget _buildChallengeItem(ChallengeParticipation challenge) {
    // tags 리스트에서 필요한 정보 추출 (디자인에 맞게)
    final String tagChallenge = '챌린지';
    final String tagCategory =
        challenge.subject != null && challenge.subject!.isNotEmpty
            ? '과목별'
            : '요일별'; // challenge.category를 직접 사용하거나, subject 유무로 판단
    final String tagPeriod = _formatDatePeriod(
      challenge.startDate,
      challenge.endDate,
    );

    // D-Day, 진행시간, 보상금은 ChallengeParticipation 객체에서 직접 가져옴
    final String dDay = _calculateChallengeDDay(challenge);
    final String progressTime = _calculateProgressTime(challenge);
    final String reward =
        challenge.reward != null
            ? '${_formatNumber(challenge.reward!)}원'
            : '미정';

    // 챌린지 제목 (항상 challenge.title을 사용하도록 수정)
    final String displayTitle = challenge.title;

    return Container(
      padding: const EdgeInsets.all(16), // 전체적인 패딩 조정
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16), // 모서리 둥글기 값 조정
        ),
        shadows: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 태그 영역
          Row(
            children: [
              _buildTag(tagChallenge, const Color(0xFFFFD27F)), // 주황색 계열
              const SizedBox(width: 8),
              _buildTag(tagCategory, const Color(0xFF5D9EFF)), // 파란색 계열
              const SizedBox(width: 8),
              _buildTag(tagPeriod, const Color(0xFF5D9EFF)), // 파란색 계열
            ],
          ),
          const SizedBox(height: 12),
          // 제목
          Text(
            displayTitle, // 수정된 제목 변수 사용
            style: TextStyle(
              color: const Color(0xFF202020),
              fontSize: 16, // 제목 폰트 크기 조정
              fontFamily: 'Pretendard-Bold',
              letterSpacing: -0.32,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          // 정보 영역
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildInfoColumn('보상 지급까지', dDay),
              _buildVerticalDivider(),
              _buildInfoColumn('진행 시간', progressTime),
              _buildVerticalDivider(),
              _buildInfoColumn('보상금', reward, isBlueText: true),
            ],
          ),
        ],
      ),
    );
  }

  // 태그 위젯 빌더
  Widget _buildTag(String text, Color backgroundColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: ShapeDecoration(
        color: backgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontFamily: 'Pretendard-Light',
          letterSpacing: -0.24,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  // 정보 컬럼 위젯 빌더
  Widget _buildInfoColumn(
    String label,
    String value, {
    bool isBlueText = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center, // 가운데 정렬
      children: [
        Text(
          label,
          style: TextStyle(
            color: const Color(0xFF666666),
            fontSize: 12,
            fontFamily: 'Pretendard-Light',
            letterSpacing: -0.28,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            color:
                isBlueText
                    ? const Color(0xFF5D9EFF)
                    : const Color(0xFF353535), // 값 텍스트 색상
            fontSize: 14, // 값 폰트 크기 조정
            fontFamily: 'Pretendard-Bold',
            letterSpacing: -0.32,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  // 수직 구분선 위젯 빌더
  Widget _buildVerticalDivider() {
    return Container(
      width: 1,
      height: 30, // 구분선 높이 조정
      color: Color(0xFFE0E0E0), // 구분선 색상
    );
  }

  // 챌린지 필터링
  void _filterChallenges() {
    // 실제 API 데이터를 사용하므로 필터링 로직 제거
    // 필터링은 이미 API 조회 시 처리됨
  }

  // 챌린지 정렬
  void _sortChallenges() {
    // 실제 API 데이터를 사용하므로 정렬 로직 제거
    // 정렬은 필요시 API 레벨에서 처리
  }

  // 목표 탭 내용
  Widget _buildGoalTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 완료한 목표 알림 섹션
          _buildCompletedGoalSection(),

          const SizedBox(height: 0),

          // 목표 필터 섹션
          _buildFilterSection(_isGoalInProgress, (value) {
            setState(() {
              _isGoalInProgress = value;
            });
            // 필터 변경 시 목표 데이터 다시 로드
            _loadGoalData();
          }),

          const SizedBox(height: 24),

          // 목표 목록 섹션
          _buildGoalListSection(),
        ],
      ),
    );
  }

  // 완료한 미션 알림 섹션
  Widget _buildCompletedMissionSection() {
    final childName =
        _selectedChild?['nickname'] ?? _selectedChild?['realName'] ?? '자녀';
    final missionCount = _missionList.length;
    final statusText = _isMissionInProgress ? '진행 중' : '완료한';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: const Color(0xFFE7ECF6)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                constraints: BoxConstraints(minHeight: 85),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: ShapeDecoration(
                  gradient: LinearGradient(
                    begin: Alignment(0.03, 0.00),
                    end: Alignment(1.00, 1.00),
                    colors: [
                      Color.fromRGBO(245, 247, 251, 1),
                      Color.fromRGBO(238, 242, 249, 1),
                    ],
                  ),
                  shape: RoundedRectangleBorder(
                    side: BorderSide(width: 0.40, color: Colors.white),
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 제목 영역
                    Container(
                      width: double.infinity,
                      child: Text(
                        '$childName님이 총 ${missionCount}개의 미션을 $statusText이예요',
                        style: TextStyle(
                          color: const Color(0xFF202020),
                          fontSize: 16,
                          fontFamily: 'Pretendard',
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.72,
                        ),
                      ),
                    ),
                    SizedBox(height: 8),
                    // 구분선
                    Container(
                      width: double.infinity,
                      height: 1,
                      color: Color.fromRGBO(133, 144, 163, 1),
                    ),
                    SizedBox(height: 8),
                    // 하단 정보 영역
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          decoration: ShapeDecoration(
                            color: const Color(0xFFE7ECF6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 10,
                                height: 4,
                                decoration: ShapeDecoration(
                                  color: const Color(0xFF5D9EFF),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                              SizedBox(width: 4),
                              Text(
                                missionCount.toString(),
                                style: TextStyle(
                                  color: const Color(0xFF3A88F4),
                                  fontSize: 11,
                                  fontFamily: 'Pretendard',
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: -0.22,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            missionCount > 0
                                ? '꾸준히 미션을 수행하고 있어요!'
                                : '아직 참여한 미션이 없어요',
                            style: TextStyle(
                              color: const Color(0xFF4A4A4A),
                              fontSize: 12,
                              fontFamily: 'Pretendard-Light',
                              letterSpacing: -0.28,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 완료한 챌린지 알림 섹션
  Widget _buildCompletedChallengeSection() {
    final childName =
        _selectedChild?['nickname'] ?? _selectedChild?['realName'] ?? '자녀';
    final challengeCount = _challengeList.length;
    final statusText = _isChallengeInProgress ? '진행 중' : '완료한';

    // TODO: 지난 주 챌린지 데이터 비교 로직 추가 필요
    final int previousWeekDifference = -2; // 임시 목업 데이터
    final String comparisonText =
        previousWeekDifference == 0
            ? '지난주와 동일한 수의 챌린지를'
            : '지난주보다 ${previousWeekDifference.abs()}개 ${previousWeekDifference > 0 ? "많은" : "적은"} 챌린지 수로';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: const Color(0xFFE7ECF6)), // 배경색 변경
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            constraints: BoxConstraints(minHeight: 80), // 최소 높이 조정
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 16,
            ), // 패딩 조정
            decoration: ShapeDecoration(
              color: Colors.white, // 내부 컨테이너 배경 흰색
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16), // 모서리 둥글게
              ),
              shadows: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  // '$childName님이 총 ${challengeCount}개의 챌린지를 $statusText이예요',
                  '총 ${challengeCount}개의 챌린지를 $statusText이예요', // 자녀 이름 임시 제거 (디자인 참고)
                  style: TextStyle(
                    color: const Color(0xFF202020),
                    fontSize: 16,
                    fontFamily: 'Pretendard-Bold',
                    letterSpacing: -0.72,
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      previousWeekDifference <= 0
                          ? Icons.arrow_drop_down
                          : Icons.arrow_drop_up,
                      color:
                          previousWeekDifference <= 0
                              ? Colors.blue
                              : Colors.red,
                      size: 20,
                    ),
                    SizedBox(width: 4),
                    Text(
                      challengeCount > 0
                          ? '$comparisonText $statusText 중이예요'
                          : '아직 참여한 챌린지가 없어요',
                      style: TextStyle(
                        color: const Color(0xFF666666), // 텍스트 색상 변경
                        fontSize: 12,
                        fontFamily: 'Pretendard-Regular',
                        letterSpacing: -0.28,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 챌린지 제목 표시 헬퍼 메서드
  String _getDisplayTitle(bool hasCompletedChallenge) {
    if (hasCompletedChallenge && _challengeList.isNotEmpty) {
      return _challengeList.first.title;
    } else if (!hasCompletedChallenge && _recommendedChallenge != null) {
      return _recommendedChallenge!.title;
    } else {
      return '추천 챌린지 로딩 중...';
    }
  }

  // 챌린지 정보 표시 헬퍼 메서드
  String _getDisplayInfo(bool hasCompletedChallenge) {
    if (hasCompletedChallenge && _challengeList.isNotEmpty) {
      return '${_challengeList.first.startDate} - ${_challengeList.first.endDate}';
    } else if (!hasCompletedChallenge && _recommendedChallenge != null) {
      return '${_recommendedChallenge!.currentParticipants}/${_recommendedChallenge!.totalParticipants}';
    } else {
      return '로딩 중...';
    }
  }

  // 완료한 목표 알림 섹션
  Widget _buildCompletedGoalSection() {
    final childName =
        _selectedChild?['nickname'] ?? _selectedChild?['realName'] ?? '자녀';
    final goalCount = _goalList.length;
    final statusText = _isGoalInProgress ? '진행 중' : '완료한';

    // 목표 카테고리 분석
    final learningGoals =
        _goalList.where((goal) => goal['category'] == 'LEARNING').length;
    final habitGoals =
        _goalList.where((goal) => goal['category'] == 'HABIT').length;

    String categoryText = '';
    if (learningGoals > 0 && habitGoals > 0) {
      categoryText = '습관 형성, 학습 인증 둘 다 진행 중이예요';
    } else if (learningGoals > 0) {
      categoryText = '학습 인증을 중심으로 진행하고 있어요';
    } else if (habitGoals > 0) {
      categoryText = '습관 형성을 중심으로 진행하고 있어요';
    } else {
      categoryText = '아직 설정된 목표가 없어요';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: const Color(0xFFE7ECF6)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                constraints: BoxConstraints(minHeight: 85),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: ShapeDecoration(
                  gradient: LinearGradient(
                    begin: Alignment(0.03, 0.00),
                    end: Alignment(1.00, 1.00),
                    colors: [
                      Color.fromRGBO(245, 247, 251, 1),
                      Color.fromRGBO(238, 242, 249, 1),
                    ],
                  ),
                  shape: RoundedRectangleBorder(
                    side: BorderSide(width: 0.40, color: Colors.white),
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 제목 영역
                    Container(
                      width: double.infinity,
                      child: Text(
                        '$childName님이 총 ${goalCount}개의 목표를 $statusText이예요',
                        style: TextStyle(
                          color: const Color(0xFF202020),
                          fontSize: 16,
                          fontFamily: 'Pretendard',
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.72,
                        ),
                      ),
                    ),
                    SizedBox(height: 8),
                    // 구분선
                    Container(
                      width: double.infinity,
                      height: 1,
                      color: Color.fromRGBO(133, 144, 163, 1),
                    ),
                    SizedBox(height: 8),
                    // 하단 정보 영역
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          decoration: ShapeDecoration(
                            color: const Color(0xFFE7ECF6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 10,
                                height: 4,
                                decoration: ShapeDecoration(
                                  color: const Color(0xFF5D9EFF),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                              SizedBox(width: 4),
                              Text(
                                goalCount.toString(),
                                style: TextStyle(
                                  color: const Color(0xFF3A88F4),
                                  fontSize: 11,
                                  fontFamily: 'Pretendard',
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: -0.22,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            goalCount > 0
                                ? '꾸준히 목표를 달성하고 있어요!'
                                : '아직 참여한 목표가 없어요',
                            style: TextStyle(
                              color: const Color(0xFF4A4A4A),
                              fontSize: 12,
                              fontFamily: 'Pretendard-Light',
                              letterSpacing: -0.28,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 목표 목록 섹션
  Widget _buildGoalListSection() {
    // 로딩 중일 때
    if (_isGoalLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFF3A88F4)),
        ),
      );
    }

    // 에러가 발생했을 때
    if (_goalError != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
        child: Center(
          child: Column(
            children: [
              Text(
                '목표를 불러오는 중 오류가 발생했습니다.',
                style: TextStyle(
                  color: Color(0xFF999999),
                  fontSize: 14,
                  fontFamily: 'Pretendard-Light',
                ),
              ),
              SizedBox(height: 8),
              ElevatedButton(
                onPressed: _loadGoalData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF3A88F4),
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  '다시 시도',
                  style: TextStyle(
                    fontFamily: 'Pretendard-Light',
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...List.generate(_goalList.length, (index) {
            final goal = _goalList[index];
            final String title = goal['title'] ?? '목표 없음';
            final String category = GoalService.getCategoryText(
              goal['category'] ?? 'LEARNING',
            );

            // 날짜 포맷팅
            String period = '기간 정보 없음';
            try {
              final startDate = DateTime.parse(goal['startDate'] ?? '');
              final endDate = DateTime.parse(goal['endDate'] ?? '');
              period =
                  '${startDate.month}.${startDate.day.toString().padLeft(2, '0')} - ${endDate.month}.${endDate.day.toString().padLeft(2, '0')}';
            } catch (e) {
              print('날짜 파싱 오류: $e');
            }

            final String reward =
                '${goal['reward']?.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}원';

            // 달성률 계산 (도장 확인 데이터 기반)
            final String achievementRate = _calculateGoalAchievementRate(goal);
            final int achievement =
                int.tryParse(achievementRate.replaceAll('%', '')) ?? 0;

            return Column(
              children: [
                _buildGoalItem(title, period, reward, achievement, category),
                if (index < _goalList.length - 1) const SizedBox(height: 24),
              ],
            );
          }),

          // 데이터가 없는 경우 안내 메시지
          if (_goalList.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Text(
                  _isGoalInProgress ? '진행 중인 목표가 없습니다.' : '완료한 목표가 없습니다.',
                  style: TextStyle(
                    color: Color(0xFF999999),
                    fontSize: 14,
                    fontFamily: 'Pretendard-Light',
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // 미션 아이템 위젯
  Widget _buildMissionItem(
    String title,
    String period,
    String progress,
    String reward,
    List<String> tags,
  ) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        shadows: [
          BoxShadow(
            color: Color(0x1C146AFF),
            blurRadius: 12,
            offset: Offset(-3, -4),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Color(0x1C146AFF),
            blurRadius: 12,
            offset: Offset(3, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 태그 영역
              Container(
                width: double.infinity,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 첫 번째 태그 (미션)
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
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            tags.isNotEmpty ? tags[0] : '미션',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontFamily: 'Pretendard',
                              fontWeight: FontWeight.w300,
                              letterSpacing: -0.24,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 12),
                    // 두 번째 태그 (미션 타입)
                    if (tags.length > 1)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: ShapeDecoration(
                          color: const Color(0xFF5D9EFF),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              tags[1],
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontFamily: 'Pretendard',
                                fontWeight: FontWeight.w300,
                                letterSpacing: -0.24,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (tags.length > 1) SizedBox(width: 12),
                    // 세 번째 태그 (기간)
                    if (tags.length > 2)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: ShapeDecoration(
                          color: const Color(0xFF5D9EFF),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              tags[2],
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontFamily: 'Pretendard',
                                fontWeight: FontWeight.w300,
                                letterSpacing: -0.24,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(height: 12),
              // 제목
              Container(
                width: double.infinity,
                child: Text(
                  title,
                  style: TextStyle(
                    color: const Color(0xFF353535),
                    fontSize: 14,
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.32,
                  ),
                ),
              ),
              SizedBox(height: 12),
              // 정보 영역
              Container(
                width: double.infinity,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 보상 지급까지
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
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  '보상 지급까지',
                                  style: TextStyle(
                                    color: const Color(0xFF666666),
                                    fontSize: 12,
                                    fontFamily: 'Pretendard-Light',
                                    letterSpacing: -0.28,
                                  ),
                                ),
                                SizedBox(height: 6),
                                Container(
                                  height: 20,
                                  child: Center(
                                    child: Text(
                                      progress,
                                      style: TextStyle(
                                        color: const Color(0xFF5D9EFF),
                                        fontSize: 14,
                                        fontFamily: 'Pretendard',
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: -0.32,
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
                    SizedBox(width: 12),
                    // 구분선
                    Container(
                      width: 1,
                      height: 40,
                      color: Color.fromRGBO(231, 236, 246, 1),
                    ),
                    SizedBox(width: 12),
                    // 진행 시간
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
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  '진행률',
                                  style: TextStyle(
                                    color: const Color(0xFF666666),
                                    fontSize: 12,
                                    fontFamily: 'Pretendard-Light',
                                    letterSpacing: -0.28,
                                  ),
                                ),
                                SizedBox(height: 6),
                                Container(
                                  height: 20,
                                  child: Center(
                                    child: Text(
                                      '진행 중',
                                      style: TextStyle(
                                        color: const Color(0xFF5D9EFF),
                                        fontSize: 14,
                                        fontFamily: 'Pretendard',
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: -0.32,
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
                    SizedBox(width: 12),
                    // 구분선
                    Container(
                      width: 1,
                      height: 40,
                      color: Color.fromRGBO(231, 236, 246, 1),
                    ),
                    SizedBox(width: 12),
                    // 보상금
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
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  '보상금',
                                  style: TextStyle(
                                    color: const Color(0xFF666666),
                                    fontSize: 12,
                                    fontFamily: 'Pretendard-Light',
                                    letterSpacing: -0.28,
                                  ),
                                ),
                                SizedBox(height: 6),
                                Container(
                                  height: 20,
                                  child: Center(
                                    child: Text(
                                      reward,
                                      style: TextStyle(
                                        color: const Color(0xFF5D9EFF),
                                        fontSize: 14,
                                        fontFamily: 'Pretendard',
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: -0.32,
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
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 목표 아이템 위젯
  Widget _buildGoalItem(
    String title,
    String period,
    String reward,
    int achievement,
    String category,
  ) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        shadows: [
          BoxShadow(
            color: Color(0x1C146AFF),
            blurRadius: 12,
            offset: Offset(-3, -4),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Color(0x1C146AFF),
            blurRadius: 12,
            offset: Offset(3, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 태그 영역
              Container(
                width: double.infinity,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            '목표',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontFamily: 'Pretendard',
                              fontWeight: FontWeight.w300,
                              letterSpacing: -0.24,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: ShapeDecoration(
                        color:
                            category == '학습 인증'
                                ? const Color(0xFF5D9EFF)
                                : const Color(0xFF4CAF50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            category,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontFamily: 'Pretendard',
                              fontWeight: FontWeight.w300,
                              letterSpacing: -0.24,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: ShapeDecoration(
                        color: const Color(0xFF5D9EFF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            period,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontFamily: 'Pretendard',
                              fontWeight: FontWeight.w300,
                              letterSpacing: -0.24,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12),
              // 제목
              Container(
                width: double.infinity,
                child: Text(
                  title,
                  style: TextStyle(
                    color: const Color(0xFF353535),
                    fontSize: 14,
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.32,
                  ),
                ),
              ),
              SizedBox(height: 12),
              // 정보 영역
              Container(
                width: double.infinity,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 보상 지급까지
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
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  '보상 지급까지',
                                  style: TextStyle(
                                    color: const Color(0xFF666666),
                                    fontSize: 12,
                                    fontFamily: 'Pretendard-Light',
                                    letterSpacing: -0.28,
                                  ),
                                ),
                                SizedBox(height: 6),
                                Container(
                                  height: 20,
                                  child: Center(
                                    child: Text(
                                      'D-3',
                                      style: TextStyle(
                                        color: const Color(0xFF5D9EFF),
                                        fontSize: 14,
                                        fontFamily: 'Pretendard',
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: -0.32,
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
                    SizedBox(width: 12),
                    // 구분선
                    Container(
                      width: 1,
                      height: 40,
                      color: Color.fromRGBO(231, 236, 246, 1),
                    ),
                    SizedBox(width: 12),
                    // 달성률
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
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  '달성률',
                                  style: TextStyle(
                                    color: const Color(0xFF666666),
                                    fontSize: 12,
                                    fontFamily: 'Pretendard-Light',
                                    letterSpacing: -0.28,
                                  ),
                                ),
                                SizedBox(height: 6),
                                Container(
                                  height: 20,
                                  child: Center(
                                    child: Text(
                                      '${achievement}%',
                                      style: TextStyle(
                                        color: const Color(0xFF5D9EFF),
                                        fontSize: 14,
                                        fontFamily: 'Pretendard',
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: -0.32,
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
                    SizedBox(width: 12),
                    // 구분선
                    Container(
                      width: 1,
                      height: 40,
                      color: Color.fromRGBO(231, 236, 246, 1),
                    ),
                    SizedBox(width: 12),
                    // 보상금
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
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  '보상금',
                                  style: TextStyle(
                                    color: const Color(0xFF666666),
                                    fontSize: 12,
                                    fontFamily: 'Pretendard-Light',
                                    letterSpacing: -0.28,
                                  ),
                                ),
                                SizedBox(height: 6),
                                Container(
                                  height: 20,
                                  child: Center(
                                    child: Text(
                                      reward,
                                      style: TextStyle(
                                        color: const Color(0xFF5D9EFF),
                                        fontSize: 14,
                                        fontFamily: 'Pretendard',
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: -0.32,
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
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 공통 필터 섹션 - 적립금 내역 디자인으로 변경
  Widget _buildFilterSection(bool isInProgress, Function(bool) onChanged) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            offset: Offset(0, 4),
            blurRadius: 10,
            spreadRadius: 0,
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // 진행중 버튼
          GestureDetector(
            onTap: () => onChanged(true),
            child: Container(
              height: 36,
              width: 70,
              decoration: BoxDecoration(
                color:
                    isInProgress
                        ? const Color(0xFF3A88F4)
                        : const Color(0xFFDEDEDE),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isInProgress ? 0.15 : 0.1),
                    offset: Offset(0, 2),
                    blurRadius: 4,
                    spreadRadius: 0,
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                '진행중',
                style: TextStyle(
                  color: isInProgress ? Colors.white : const Color(0xFF999999),
                  fontSize: 12,
                  fontFamily:
                      isInProgress
                          ? 'Pretendard-Light'
                          : 'Pretendard-ExtraLight',
                ),
              ),
            ),
          ),

          const SizedBox(width: 12), // 버튼 간 간격
          // 완료한 버튼
          GestureDetector(
            onTap: () => onChanged(false),
            child: Container(
              height: 36,
              width: 70,
              decoration: BoxDecoration(
                color:
                    !isInProgress
                        ? const Color(0xFF3A88F4)
                        : const Color(0xFFDEDEDE),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(!isInProgress ? 0.15 : 0.1),
                    offset: Offset(0, 2),
                    blurRadius: 4,
                    spreadRadius: 0,
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                '완료한',
                style: TextStyle(
                  color: !isInProgress ? Colors.white : const Color(0xFF999999),
                  fontSize: 12,
                  fontFamily:
                      !isInProgress
                          ? 'Pretendard-Light'
                          : 'Pretendard-ExtraLight',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 목표 달성률 계산
  String _calculateGoalAchievementRate(Map<String, dynamic> goal) {
    try {
      print('===== 목표 달성률 계산 (부모 화면) =====');
      print('목표 제목: ${goal['title']}');
      print('목표 전체 데이터: $goal');

      // 도장 확인 데이터가 있는 경우
      if (goal.containsKey('goalCheck') && goal['goalCheck'] != null) {
        final checkData = goal['goalCheck'];
        print('도장 데이터: $checkData');

        int checkedDays = 0;

        // 각 요일별로 확인 (무조건 7일 기준)
        final dayFields = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
        for (String day in dayFields) {
          print('$day 요일: ${checkData[day]}');
          if (checkData.containsKey(day) && checkData[day] == true) {
            checkedDays++;
          }
        }

        print('도장 찍힌 일수: $checkedDays');

        // 7일 중 몇 일 달성했는지 계산 (소수점 버림)
        final achievementRate = (checkedDays / 7 * 100).floor();
        print('계산된 달성률: $achievementRate%');
        return '$achievementRate%';
      }

      print('goalCheck 데이터가 없음');

      // ACHIEVEMENT 상태인 경우 100%
      if (goal['status'] == 'ACHIEVEMENT') {
        return '100%';
      }

      // 그 외의 경우 0%
      return '0%';
    } catch (e) {
      print('달성률 계산 오류: $e');
      return '0%';
    }
  }

  // 자녀 변경 모달 표시
  void _showChildSelectionModal() {
    // 자녀(CHILD 역할)만 필터링
    final filteredChildren =
        _familyMembers?.where((child) {
          return child['role'] == 'CHILD';
        }).toList() ??
        [];

    if (filteredChildren.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('선택할 수 있는 자녀가 없습니다')));
      return;
    }

    // 현재 선택된 자녀의 인덱스 찾기
    int selectedIndex = 0;
    if (_selectedChild != null) {
      for (int i = 0; i < filteredChildren.length; i++) {
        final childName =
            filteredChildren[i]['nickname'] ??
            filteredChildren[i]['realName'] ??
            '';
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
          children: filteredChildren,
          initialSelectedIndex: selectedIndex,
          onChildSelected: (selectedChild, selectedIndex) {
            setState(() {
              _selectedChild = selectedChild;
            });

            // 자녀가 변경되면 챌린지, 목표, 미션 데이터 다시 로드
            _loadChallengeData();
            _loadGoalData();
            _loadMissionData();
          },
        );
      },
    );
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

// 날짜 포맷 변환 함수 (2025-06-01 -> 25.06.01)
String _formatDate(String dateString) {
  try {
    final date = DateTime.parse(dateString);
    final year = date.year.toString().substring(2); // 2025 -> 25
    final month = date.month.toString().padLeft(2, '0'); // 6 -> 06
    final day = date.day.toString().padLeft(2, '0'); // 1 -> 01
    return '$year.$month.$day';
  } catch (e) {
    print('날짜 포맷 변환 오류: $e');
    return dateString; // 오류 발생 시 원본 반환
  }
}

// 숫자 포맷팅 함수 (1000 -> 1,000)
String _formatNumber(int number) {
  return number.toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (Match m) => '${m[1]},',
  );
}

// 날짜 기간 포맷 함수 (시작일과 끝일을 받아서 "25.06.01 - 06.30" 형식으로 변환)
String _formatDatePeriod(String startDate, String endDate) {
  try {
    final start = DateTime.parse(startDate);
    final end = DateTime.parse(endDate);

    final startYear = start.year.toString().substring(2);
    final startMonth = start.month.toString().padLeft(2, '0');
    final startDay = start.day.toString().padLeft(2, '0');

    final endMonth = end.month.toString().padLeft(2, '0');
    final endDay = end.day.toString().padLeft(2, '0');

    // 같은 연도면 끝날짜에서 연도 생략
    if (start.year == end.year) {
      return '$startYear.$startMonth.$startDay - $endMonth.$endDay';
    } else {
      final endYear = end.year.toString().substring(2);
      return '$startYear.$startMonth.$startDay - $endYear.$endMonth.$endDay';
    }
  } catch (e) {
    print('날짜 기간 포맷 변환 오류: $e');
    return '$startDate - $endDate'; // 오류 발생 시 원본 반환
  }
}
