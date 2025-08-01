import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../widgets/parent/bottom_navigation_bar.dart';
import 'widgets/allowance_card.dart';
import 'widgets/weekly_info_card.dart';
import 'widgets/goal_selection_modal.dart';

import 'widgets/mission_section.dart';
import 'alert/notification_screen.dart';
import 'analysis/analysis_screen.dart';
import '../../services/family_service.dart';
import '../../services/auth_service.dart';
import '../../services/goal_service.dart';
import '../../services/challenge_service.dart';
import '../../services/mission_service.dart';
import '../../services/notification_service.dart';
import '../../services/analysis_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'my/my_page_screen.dart'; // ChildSelectionModal import
import 'mission/goal/parent_goal_check_widget.dart';
import 'mission/complete_modal/parent_mission_complete_modal.dart';
import 'mission/mission_evaluation_screen.dart';
import 'challenge/parent_challenge_complete_modal.dart';
import 'challenge/parent_challenge_score_modal.dart';
import 'mission/goal/parent_goal_reward_screen.dart'; // 목표 보상 화면 import 추가

// 선 그래프 그리기 위한 CustomPainter
class LineChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 데이터 포인트 (7개 일자의 공부 시간, 위치를 적절히 조정해야 함)
    final points = [
      Offset(size.width * 0.05, size.height * 0.8), // 4.14 - 시작점
      Offset(size.width * 0.18, size.height * 0.4), // 4.15 - 높은점
      Offset(size.width * 0.35, size.height * 0.6), // 4.16 - 중간점
      Offset(size.width * 0.5, size.height * 0.7), // 4.17 - 낮은점
      Offset(size.width * 0.65, size.height * 0.5), // 4.18 - 중간점
      Offset(size.width * 0.82, size.height * 0.3), // 4.19 - 5시간 달성 최고점
      Offset(size.width * 0.95, size.height * 0.6), // 4.20 - 끝점
    ];

    // 수평 보조선 그리기
    final gridPaint =
        Paint()
          ..color = Colors.grey.withOpacity(0.2)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8;

    // 보조선 두 개만 그리기 - 2번째 사진과 같은 위치로 조정
    final gridPositions = [0.08, 0.75];
    final graphStartX = size.width * 0.05; // 그래프 시작점 x 좌표
    final graphEndX = size.width * 0.95; // 그래프 끝점 x 좌표
    for (final position in gridPositions) {
      final y = size.height * position;
      canvas.drawLine(Offset(graphStartX, y), Offset(graphEndX, y), gridPaint);
    }

    // 선을 위한 페인트 정의 - 더 굵고 진한 색상으로 변경
    final linePaint =
        Paint()
          ..color = const Color(0xFF146AFF).withOpacity(0.8) // 불투명도 증가
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.5; // 더 굵게

    // 아래 영역 채우기를 위한 페인트 - 그라데이션 강화
    final fillPaint =
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF146AFF).withOpacity(0.7), // 더 진하게
              const Color(0xFF146AFF).withOpacity(0.4), // 중간 투명도
              const Color(0xFF146AFF).withOpacity(0.1), // 약간 투명
            ],
          ).createShader(Rect.fromLTRB(0, 0, size.width, size.height))
          ..style = PaintingStyle.fill;

    // 부드러운 곡선을 위한 경로 생성
    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);

    // 부드러운 곡선으로 점들을 연결
    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final controlPoint1 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p0.dy);
      final controlPoint2 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p1.dy);

      path.cubicTo(
        controlPoint1.dx,
        controlPoint1.dy,
        controlPoint2.dx,
        controlPoint2.dy,
        p1.dx,
        p1.dy,
      );
    }

    // 아래 영역 채우기를 위한 경로 생성
    final fillPath = Path.from(path);
    fillPath.lineTo(points.last.dx, size.height);
    fillPath.lineTo(points.first.dx, size.height);
    fillPath.close();

    // 아래 영역 채우기
    canvas.drawPath(fillPath, fillPaint);

    // 선으로 된 곡선 그리기
    canvas.drawPath(path, linePaint);

    // 데이터 포인트에 점 표시 (5시간 달성 지점에만 특별한 점 표시)
    for (int i = 0; i < points.length; i++) {
      if (i == 5) {
        // 5시간 달성 지점 (4.19)
        // 중앙 점
        final dotPaint =
            Paint()
              ..color = Colors.white
              ..style = PaintingStyle.fill;

        // 테두리
        final outlinePaint =
            Paint()
              ..color = const Color(0xFF146AFF)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.5;

        canvas.drawCircle(points[i], 6, dotPaint); // 점 크기 키움
        canvas.drawCircle(points[i], 6, outlinePaint);
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class ParentHomeScreen extends StatefulWidget {
  final String initialRole;

  const ParentHomeScreen({super.key, this.initialRole = 'PARENT'});

  @override
  State<ParentHomeScreen> createState() => _ParentHomeScreenState();
}

class _ParentHomeScreenState extends State<ParentHomeScreen> {
  final int _selectedIndex = 0; // 홈 탭 선택
  bool _showNotificationCard = true; // 알림 카드 표시 여부

  // 가족 정보 관련 변수들 추가
  List<dynamic>? _familyMembers;
  bool _isLoadingFamily = true;
  String? _familyError;

  // 사용자 정보 관련 변수들 추가
  Map<String, dynamic>? _userInfo;
  bool _isLoadingUser = true;
  String? _userError;

  // 선택된 자녀 정보 추가
  Map<String, dynamic>? _selectedChild;

  // 공부 시간 관련 변수들 추가
  int _totalStudyHours = 0;
  int _totalStudyMinutes = 0;
  bool _isLoadingStudyTime = true;

  // 스크롤 관련 변수들 추가
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;

  // 점수 입력 완료된 항목들을 기억하는 Set 추가
  // 서버 DB 상태로 관리 - 로컬 상태는 목표만 유지
  final Set<String> _completedGoalEvaluations = <String>{};

  // 알림 관련 변수들
  int _unreadNotificationCount = 0;
  bool _isLoadingNotifications = false;

  @override
  void initState() {
    super.initState();

    // 하단 네비게이션 바 숨기기 설정
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [SystemUiOverlay.top],
    );

    // 스크롤 리스너 추가
    _scrollController.addListener(_scrollListener);

    _loadUserInfo();
    _loadFamilyMembers();
    _loadStudyTimeData();
    _loadUnreadNotificationCount();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // 하단 네비게이션 바 숨기기 설정 재적용
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [SystemUiOverlay.top],
    );

    // 화면이 다시 포커스될 때마다 알림 카드 상태 확인
    _checkNotificationCardVisibility();
  }

  // 스크롤 리스너
  void _scrollListener() {
    if (_scrollController.offset > 50) {
      if (!_isScrolled) {
        setState(() {
          _isScrolled = true;
        });
      }
    } else {
      if (_isScrolled) {
        setState(() {
          _isScrolled = false;
        });
      }
    }
  }

  // 안읽은 알림 개수 로드
  Future<void> _loadUnreadNotificationCount() async {
    if (!mounted) return;
    
    setState(() {
      _isLoadingNotifications = true;
    });

    try {
      final count = await NotificationService.getUnreadNotificationCount();
      if (mounted) {
        setState(() {
          _unreadNotificationCount = count;
          _isLoadingNotifications = false;
        });
      }
    } catch (e) {
      print('안읽은 알림 개수 로드 중 오류: $e');
      if (mounted) {
        setState(() {
          _unreadNotificationCount = 0;
          _isLoadingNotifications = false;
        });
      }
    }
  }

  // 사용자 정보 불러오기
  Future<void> _loadUserInfo() async {
    try {
      if (mounted) {
        setState(() {
          _isLoadingUser = true;
          _userError = null;
        });
      }

      print('부모 홈화면: 사용자 정보 로드 시작');

      final userInfo = await AuthService.getUserInfo();

      if (mounted) {
        setState(() {
          _userInfo = userInfo;
          _isLoadingUser = false;
        });

        print('부모 홈화면: 사용자 정보 로드 성공 - ${userInfo['name']}');
      }
    } catch (e) {
      print('부모 홈화면: 사용자 정보 로드 중 예외 발생: $e');

      if (mounted) {
        setState(() {
          _userError = '사용자 정보를 불러올 수 없습니다';
          _isLoadingUser = false;
        });
      }
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

      print('부모 홈화면: 가족 구성원 목록 로드 시작');

      final familyInfo = await FamilyService.getFamilyInfo();

      if (familyInfo != null) {
        final List<dynamic> memberList = familyInfo['memberInfoList'] ?? [];
        print('부모 홈화면: 가족 정보 로드 성공 - 멤버 ${memberList.length}명');

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

          // 가족 정보 로드 후 알림 카드 상태 확인 및 공부 시간 데이터 로드
          _checkNotificationCardVisibility();
          _loadStudyTimeData();

          // 미션 완료 상태 확인
          print('🚀 _checkMissionCompletion 호출 시작');
          print(
            '🚀 선택된 자녀: ${_selectedChild?['nickname']} (ID: ${_selectedChild?['userId']})',
          );
          print('🚀 자녀 정보: $_selectedChild');
          await _checkMissionCompletion();

          // 챌린지 완료 상태 확인
          print('🏆 _checkChallengeCompletion 호출 시작');
          _checkChallengeCompletion();

          // 목표 완료 상태 확인
          print('📚 _checkGoalCompletion 호출 시작');
          _checkGoalCompletion();

          // 홈화면 진입 시 목표 도장 찍기 모달 자동 표시
          print('🎯 홈화면 진입 시 목표 도장 찍기 모달 자동 표시');
          _showGoalCheckModalOnInit();
        }
      } else {
        print('부모 홈화면: 가족 정보 조회 실패 또는 가족 정보 없음');

        if (mounted) {
          setState(() {
            _familyMembers = [];
            _selectedChild = null;
            _isLoadingFamily = false;
          });
        }
      }
    } catch (e) {
      print('부모 홈화면: 가족 구성원 목록 로드 중 예외 발생: $e');

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

  // 공부 시간 데이터 로드 (동적 API 기반)
  Future<void> _loadStudyTimeData() async {
    if (_selectedChild == null) {
      setState(() {
        _isLoadingStudyTime = false;
      });
      return;
    }

    try {
      setState(() {
        _isLoadingStudyTime = true;
      });

      print(
        '🕐 공부 시간 데이터 로드 시작 - 자녀: ${_selectedChild!['nickname'] ?? _selectedChild!['realName']}',
      );

      final childId = _selectedChild!['userId'] ?? _selectedChild!['familyMemberId'];
      
      if (childId == null) {
        print('❌ 자녀 ID를 찾을 수 없습니다.');
        if (mounted) {
          setState(() {
            _totalStudyHours = 0;
            _totalStudyMinutes = 0;
            _isLoadingStudyTime = false;
          });
        }
        return;
      }

      int totalMinutes = 0;

      // 1. 분석 API에서 이번 주 학습 시간 가져오기
      try {
        print('📊 분석 API에서 이번 주 학습 시간 조회 중...');
        final analysisData = await AnalysisService.getAnalysisReport(childId, 7); // 7일(이번 주) 기준
        
        if (analysisData != null) {
          final recentStudyTime = analysisData['recentStudyTime'] ?? 0;
          final totalStudyTime = analysisData['totalStudyTime'] ?? 0;
          
          print('📊 분석 API 데이터 (이번 주):');
          print('   - recentStudyTime: ${recentStudyTime}분');
          print('   - totalStudyTime: ${totalStudyTime}분');
          
          // 이번 주 학습 시간 사용
          if (recentStudyTime > 0) {
            totalMinutes = recentStudyTime as int;
            print('✅ 분석 API 이번 주 학습 시간 사용: ${totalMinutes}분');
          } else if (totalStudyTime > 0) {
            totalMinutes = totalStudyTime as int;
            print('✅ 분석 API 총 학습 시간 사용: ${totalMinutes}분');
          }
        }
      } catch (e) {
        print('❌ 분석 API 조회 오류: $e');
      }

      // 2. 분석 API 데이터가 없으면 이번 주 활동 데이터로 계산
      if (totalMinutes == 0) {
        print('📊 분석 API 데이터가 없어서 이번 주 활동 데이터로 계산합니다.');
        
        // 이번 주 날짜 범위 계산
        final now = DateTime.now();
        final thisWeekStart = now.subtract(Duration(days: now.weekday - 1)); // 월요일
        final thisWeekEnd = thisWeekStart.add(Duration(days: 6)); // 일요일
        
        print('📅 이번 주 범위: ${thisWeekStart.toString().substring(0, 10)} ~ ${thisWeekEnd.toString().substring(0, 10)}');
        
        // 미션에서 이번 주 학습 시간 계산
        try {
          final missionsData = await MissionService.getParentChildMissions(
            childId: childId,
            page: 0,
          );

          if (missionsData != null && missionsData['data'] != null) {
            final List<dynamic> missionList = missionsData['data'];
            
            for (final mission in missionList) {
              final status = mission['status'];
              final finishScore = mission['finishScore'] ?? 0;
              final startDateStr = mission['startDate'];
              final endDateStr = mission['endDate'];
              
              // 이번 주에 해당하는 미션인지 확인
              bool isThisWeekMission = false;
              if (startDateStr != null) {
                try {
                  final startDate = DateTime.parse(startDateStr);
                  isThisWeekMission = startDate.isAfter(thisWeekStart.subtract(Duration(days: 1))) && 
                                     startDate.isBefore(thisWeekEnd.add(Duration(days: 1)));
                } catch (e) {
                  print('미션 날짜 파싱 오류: $e');
                }
              }
              
              if (!isThisWeekMission) {
                print('🎯 미션 제외 (이번 주 아님): ${mission['title']}');
                continue;
              }
              
              // 완료된 미션 또는 진행 중인 미션의 추정 시간
              if (status == 'ACHIEVEMENT') {
                // 점수 기반 시간 추정 (점수가 높을수록 더 많은 시간)
                int estimatedTime = finishScore > 0 ? finishScore : 60; // 최소 60분
                totalMinutes += estimatedTime;
                print('🎯 이번 주 완료된 미션: ${mission['title']} - ${estimatedTime}분');
              } else if (status == 'ACCEPT') {
                // 진행 중인 미션은 기본 60분
                totalMinutes += 60;
                print('🎯 이번 주 진행중인 미션: ${mission['title']} - 60분');
              }
            }
          }
        } catch (e) {
          print('❌ 미션 데이터 계산 오류: $e');
        }

                          // 챌린지에서 이번 주 학습 시간 계산
         try {
           final familyInfo = await FamilyService.getFamilyInfo();
           if (familyInfo != null) {
             final familyId = familyInfo['familyId'];
             final childFamilyId = _selectedChild!['familyMemberId'];
             
             final challengeResponse = await ChallengeService.getChildChallenges(
               familyId,
               childFamilyId,
               page: 0,
             );

             for (final challenge in challengeResponse.data) {
               final challengeMap = challenge.toJson();
               final finishScore = challengeMap['finishScore'] ?? 0;
               final startDateStr = challengeMap['startDate'];
               final challengeStatus = challengeMap['challengeStatus'];
               
               // 이번 주에 해당하는 챌린지인지 확인
               bool isThisWeekChallenge = false;
               if (startDateStr != null) {
                 try {
                   final startDate = DateTime.parse(startDateStr);
                   isThisWeekChallenge = startDate.isAfter(thisWeekStart.subtract(Duration(days: 1))) && 
                                        startDate.isBefore(thisWeekEnd.add(Duration(days: 1)));
                 } catch (e) {
                   print('챌린지 날짜 파싱 오류: $e');
                 }
               }
               
               if (!isThisWeekChallenge) {
                 print('🏆 챌린지 제외 (이번 주 아님): ${challengeMap['title']}');
                 continue;
               }
               
               if (challengeStatus == 'ACHIEVEMENT') {
                 // 완료된 챌린지: 점수 기반 추정
                 int estimatedTime = finishScore > 0 ? finishScore : 90;
                 totalMinutes += estimatedTime;
                 print('🏆 이번 주 완료된 챌린지: ${challengeMap['title']} - ${estimatedTime}분');
               } else if (challengeStatus == 'ONGOING') {
                 // 진행 중인 챌린지: 기본 90분
                 totalMinutes += 90;
                 print('🏆 이번 주 진행중인 챌린지: ${challengeMap['title']} - 90분');
               }
             }
           }
         } catch (e) {
           print('❌ 챌린지 데이터 계산 오류: $e');
         }

                 // 이번 주 목표에서 학습 시간 계산
         try {
           final familyInfo = await FamilyService.getFamilyInfo();
           if (familyInfo != null) {
             final familyId = familyInfo['familyId'];
             final weeklyGoals = await GoalService.getParentWeeklyGoals(familyId);

             if (weeklyGoals != null) {
               final selectedChildId = _selectedChild!['familyMemberId'];
               final childGoals = weeklyGoals
                   .where((goal) =>
                       goal['familyMemberId'] == selectedChildId &&
                       goal['status'] == 'ACCEPT')
                   .toList();

               print('📚 이번 주 목표 ${childGoals.length}개 발견');

               for (final goal in childGoals) {
                 final goalId = goal['goalId'];
                 if (goalId != null) {
                   try {
                     final checkData = await GoalService.getGoalCheck(goalId);
                     if (checkData != null) {
                       // 이번 주 도장 찍은 일수에 따른 시간 계산
                       int checkedDays = 0;
                       for (int day = 1; day <= 7; day++) {
                         if (GoalService.isDayChecked(checkData, day)) {
                           checkedDays++;
                         }
                       }
                       int goalMinutes = checkedDays * 30; // 하루 30분씩
                       totalMinutes += goalMinutes;
                       print('📚 이번 주 목표: ${goal['title']} - ${checkedDays}일 × 30분 = ${goalMinutes}분');
                     }
                   } catch (e) {
                     print('목표 ${goal['title']} 도장 확인 오류: $e');
                   }
                 }
               }
             }
           }
         } catch (e) {
           print('❌ 목표 데이터 계산 오류: $e');
         }
      }

      // 시간과 분으로 변환
      final hours = totalMinutes ~/ 60;
      final minutes = totalMinutes % 60;

      if (mounted) {
        setState(() {
          _totalStudyHours = hours;
          _totalStudyMinutes = minutes;
          _isLoadingStudyTime = false;
        });
      }

      print('🕐 이번 주 총 공부 시간 계산 완료: ${hours}시간 ${minutes}분 (총 ${totalMinutes}분)');
      if (totalMinutes > 0) {
        print('✅ 이번 주 동적 데이터 기반 계산 성공');
      } else {
        print('⚠️ 이번 주 학습 활동 데이터가 없어 0분으로 설정');
      }
    } catch (e) {
      print('공부 시간 데이터 로드 중 오류: $e');

      if (mounted) {
        setState(() {
          _totalStudyHours = 0;
          _totalStudyMinutes = 0;
          _isLoadingStudyTime = false;
        });
      }
    }
  }

  // 미션 완료 상태 확인 및 알림 모달 표시
  Future<void> _checkMissionCompletion() async {
    print('========================================');
    print('🎯 _checkMissionCompletion 메서드 시작!!!');
    print('🎯 현재 시간: ${DateTime.now()}');
    print('🎯 현재 스택 트레이스: ${StackTrace.current}');
    print('========================================');

    if (_selectedChild == null) {
      print('🎯 선택된 자녀가 없어서 미션 완료 확인을 건너뜁니다.');
      return;
    }

    try {
      print(
        '🎯 미션 완료 상태 확인 시작 - 자녀: ${_selectedChild!['nickname'] ?? _selectedChild!['realName']}',
      );

      final childId =
          _selectedChild!['userId'] ?? _selectedChild!['familyMemberId'];

      if (childId == null) {
        print('🎯 자녀 ID를 찾을 수 없습니다.');
        return;
      }

      print('🎯 미션 API 호출 시작 - childId: $childId');

      final missionsData = await MissionService.getParentChildMissions(
        childId: childId,
        page: 0,
      );

      print('🎯 미션 API 호출 완료 - 응답 데이터: ${missionsData != null ? "있음" : "없음"}');

      if (missionsData != null && missionsData['data'] != null) {
        final List<dynamic> allMissionList = missionsData['data'];
        print('🎯 전체 미션 개수: ${allMissionList.length}');

        // 최신순으로 정렬 (startDate 기준)
        allMissionList.sort((a, b) {
          final aStartDate = a['startDate'] ?? '';
          final bStartDate = b['startDate'] ?? '';
          return bStartDate.compareTo(aStartDate);
        });

        // 최신순으로 3개만 선택
        final List<dynamic> missionList = allMissionList.take(3).toList();
        print('🎯 최신순 3개 미션으로 제한: ${missionList.length}개');

        // 완료되었지만 보상이 지급되지 않은 미션 찾기 (API 기반)
        final completedMissions =
            missionList.where((mission) {
              final missionId = mission['missionId'];
              final title = mission['title'];
              final status = mission['status'];
              final isRewarded = mission['isRewarded'] ?? false;
              final finishScore = mission['finishScore'];
              final endDateStr = mission['endDate'];

              print('🎯 미션 분석: $title');
              print('   - missionId: $missionId');
              print('   - status: $status');
              print('   - isRewarded: $isRewarded');
              print('   - finishScore: $finishScore');
              print('   - endDate: $endDateStr');

              // 이미 보상이 지급된 미션은 제외
              if (isRewarded) {
                print('   - 제외 이유: 이미 보상 지급됨');
                return false;
              }

              // 완료된 미션 조건 확인
              final now = DateTime.now();

              if (status == 'ACHIEVEMENT') {
                print('   - 포함 이유: ACHIEVEMENT 상태');
                return true;
              }

              if (status == 'ACCEPT' && endDateStr != null) {
                try {
                  final endDate = DateTime.parse(endDateStr);
                  final isExpired = now.isAfter(endDate);
                  print('   - ACCEPT 상태, 기간만료=$isExpired');
                  return isExpired;
                } catch (e) {
                  print('   - 날짜 파싱 오류: $e');
                }
              }

              print('   - 제외 이유: 조건 불만족');
              return false;
            }).toList();

        print('🎯 보상 대기 중인 미션 개수: ${completedMissions.length}');

        if (completedMissions.isNotEmpty) {
          final completedMission = completedMissions.first;
          final childName =
              _selectedChild!['nickname'] ??
              _selectedChild!['realName'] ??
              '자녀';

          print('🎯 미션 완료 모달 표시 준비:');
          print('   - 완료된 미션: ${completedMission['title']}');
          print('   - 미션 ID: ${completedMission['missionId']}');
          print('   - 자녀 이름: $childName');
          print('   - 완료된 미션 전체 데이터: $completedMission');

          if (mounted) {
            await Future.delayed(Duration(milliseconds: 500));

            if (mounted) {
              print('========================================');
              print('🎯 미션 완료 모달 표시!!!');
              print('🎯 모달 표시 시간: ${DateTime.now()}');
              print('🎯 모달 호출 스택 트레이스: ${StackTrace.current}');
              print('========================================');
              final result = await ParentMissionCompleteModal.show(
                context,
                mission: completedMission,
                childName: childName,
              );

              if (result == true) {
                print('🎯 활동 평가 화면으로 이동');
                _navigateToMissionEvaluation(completedMission);
              }
            }
          }
        } else {
          print('🎯 보상 대기 중인 완료된 미션이 없습니다.');
        }
      } else {
        print('🎯 미션 API 응답이 null이거나 data 필드가 없습니다.');
        print('🎯 missionsData: $missionsData');
      }
    } catch (e) {
      print('🎯 미션 완료 상태 확인 중 오류: $e');
      print('🎯 스택 트레이스: ${e.toString()}');
    }

    print('🎯 _checkMissionCompletion 메서드 종료');
  }

  // 미션 평가 화면으로 이동
  void _navigateToMissionEvaluation(Map<String, dynamic> mission) async {
    print('🎯 미션 평가 화면으로 이동: ${mission['title']}');

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => MissionEvaluationScreen(
              mission: mission,
              childInfo: _selectedChild,
            ),
      ),
    );

    print('🎯 미션 평가 화면에서 돌아옴: result = $result');

    // 평가가 완료되면 데이터 새로고침
    if (result != null) {
      final missionId = mission['missionId'] ?? mission['id'];
      print('🎯 미션 $missionId 평가 완료');

      // result가 Map<String, dynamic>인 경우 (업데이트된 미션 정보)
      if (result is Map<String, dynamic>) {
        final isRewarded = result['isRewarded'] ?? false;
        final finishScore = result['finishScore'];
        print(
          '🎯 업데이트된 미션 정보: isRewarded=$isRewarded, finishScore=$finishScore',
        );

        if (isRewarded) {
          print('🎯 보상이 완료되었으므로 더 이상 모달을 표시하지 않습니다.');
        }
      }

      // 점수 입력 후 모든 데이터 새로고침 (재확인은 하지 않음)
      print('🎯 미션 평가 완료 후 전체 데이터 새로고침');
      _loadStudyTimeData();
      _loadFamilyMembers();
    }
  }

  // 챌린지 완료 상태 확인 및 알림 모달 표시
  Future<void> _checkChallengeCompletion() async {
    print('🏆 _checkChallengeCompletion 메서드 시작');

    if (_selectedChild == null) {
      print('🏆 선택된 자녀가 없어서 챌린지 완료 확인을 건너뜁니다.');
      return;
    }

    try {
      final familyInfo = await FamilyService.getFamilyInfo();
      if (familyInfo == null) {
        print('🏆 가족 정보를 가져올 수 없습니다.');
        return;
      }

      final familyId = familyInfo['familyId'];
      final childId = _selectedChild!['familyMemberId'];

      print(
        '🏆 챌린지 완료 상태 확인 시작 - 자녀: ${_selectedChild!['nickname'] ?? _selectedChild!['realName']}',
      );
      print('🏆 familyId: $familyId, childId: $childId');

      if (childId == null) {
        print('🏆 자녀 ID를 찾을 수 없습니다.');
        return;
      }

      // 자녀의 챌린지 참여 목록 조회
      final challengeResponse = await ChallengeService.getChildChallenges(
        familyId,
        childId,
        page: 0,
      );

      print('🏆 챌린지 응답: ${challengeResponse.data.length}개');

      // 보상 대기 중인 완료된 챌린지 찾기 (API 기반)
      final challengesToEvaluate =
          challengeResponse.data.where((challenge) {
            final challengeData = challenge.toJson(); // Map으로 변환
            final participationId = challenge.participationId;
            final title = challenge.title;
            final challengeStatus = challenge.challengeStatus;
            final isRewarded = challenge.isRewarded;
            final finishScore = challenge.finishScore;
            final endDate = challenge.endDate;

            print('🏆 챌린지 분석: $title');
            print('   - participationId: $participationId');
            print('   - challengeStatus: $challengeStatus');
            print('   - isRewarded: $isRewarded');
            print('   - finishScore: $finishScore');
            print('   - endDate: $endDate');

            // 이미 보상이 지급된 챌린지는 제외
            if (isRewarded) {
              print('   - 제외 이유: 이미 보상 지급됨');
              return false;
            }

            // ChallengeService의 헬퍼 메서드 사용
            final shouldShow = ChallengeService.shouldShowRewardModal(
              challengeData,
            );

            if (shouldShow) {
              print('   - 포함 이유: 보상 모달 표시 조건 만족');
            } else {
              print('   - 제외 이유: 보상 모달 표시 조건 불만족');
            }

            return shouldShow;
          }).toList();

      print('🏆 보상 대기 중인 챌린지 개수: ${challengesToEvaluate.length}');

      if (challengesToEvaluate.isNotEmpty) {
        // 첫 번째 평가 필요한 챌린지에 대해 모달 표시
        final challengeToEvaluate = challengesToEvaluate.first;
        final childName =
            _selectedChild!['nickname'] ?? _selectedChild!['realName'] ?? '자녀';

        print('🏆 평가할 챌린지: ${challengeToEvaluate.title}');

        if (mounted) {
          // 약간의 지연 후 모달 표시 (홈화면 로딩 완료 후)
          await Future.delayed(Duration(milliseconds: 800));

          if (mounted) {
            print('🏆 챌린지 완료 모달 표시 시작');
            final result = await ParentChallengeCompleteModal.show(
              context,
              challenge: challengeToEvaluate.toJson(),
              childName: childName,
              childInfo: _selectedChild, // 자녀 정보 추가
            );

            if (result == true) {
              // '점수 평가하러 가기' 버튼을 눌렀을 때
              print('🏆 점수 입력 모달 표시');
              _showChallengeScoreModal(challengeToEvaluate);
            }
          }
        }
      } else {
        print('🏆 평가할 챌린지가 없습니다.');
      }
    } catch (e) {
      print('🏆 챌린지 완료 상태 확인 중 오류: $e');
    }

    print('🏆 _checkChallengeCompletion 메서드 종료');
  }

  // 목표 완료 상태 확인 및 알림 모달 표시
  Future<void> _checkGoalCompletion() async {
    print('📚 _checkGoalCompletion 메서드 시작');

    if (_selectedChild == null) {
      print('📚 선택된 자녀가 없어서 목표 완료 확인을 건너뜁니다.');
      return;
    }

    try {
      print(
        '📚 목표 완료 상태 확인 시작 - 자녀: ${_selectedChild!['nickname'] ?? _selectedChild!['realName']}',
      );

      final familyInfo = await FamilyService.getFamilyInfo();
      if (familyInfo == null) {
        print('📚 가족 정보를 가져올 수 없습니다.');
        return;
      }

      final familyId = familyInfo['familyId'];
      final selectedChildId = _selectedChild!['familyMemberId'];

      print('📚 familyId: $familyId, childId: $selectedChildId');

      if (selectedChildId == null) {
        print('📚 자녀 ID를 찾을 수 없습니다.');
        return;
      }

      // 이번 주 목표 조회
      final weeklyGoals = await GoalService.getParentWeeklyGoals(familyId);

      if (weeklyGoals == null || weeklyGoals.isEmpty) {
        print('📚 이번 주 목표가 없습니다.');
        return;
      }

      // 선택된 자녀의 ACCEPT 상태 목표만 필터링
      final childGoals =
          weeklyGoals
              .where(
                (goal) =>
                    goal['familyMemberId'] == selectedChildId &&
                    goal['status'] == 'ACCEPT',
              )
              .toList();

      print('📚 자녀의 진행 중인 목표 개수: ${childGoals.length}');

      // 완료된 목표 찾기 (7일 모두 도장을 찍은 목표)
      List<Map<String, dynamic>> completedGoals = [];

      for (final goal in childGoals) {
        final goalId = goal['goalId'];
        if (goalId == null) continue;

        // 이미 평가한 목표는 건너뛰기
        if (_completedGoalEvaluations.contains('$goalId')) {
          print('📚 목표 ${goal['title']}: 이미평가됨');
          continue;
        }

        try {
          final checkData = await GoalService.getGoalCheck(goalId);
          if (checkData != null) {
            // 7일 모두 도장이 찍혔는지 확인
            bool allDaysChecked = true;
            for (int day = 1; day <= 7; day++) {
              if (!GoalService.isDayChecked(checkData, day)) {
                allDaysChecked = false;
                break;
              }
            }

            print('📚 목표 ${goal['title']}: 7일완료=${allDaysChecked}');

            if (allDaysChecked) {
              completedGoals.add(goal);
            }
          }
        } catch (e) {
          print('📚 목표 ${goal['title']} 도장 확인 중 오류: $e');
        }
      }

      print('📚 완료된 목표 개수: ${completedGoals.length}');

      if (completedGoals.isNotEmpty) {
        // 첫 번째 완료된 목표에 대해 모달 표시
        final completedGoal = completedGoals.first;
        final childName =
            _selectedChild!['nickname'] ?? _selectedChild!['realName'] ?? '자녀';

        print('📚 완료된 목표: ${completedGoal['title']}');

        if (mounted) {
          // 약간의 지연 후 모달 표시 (다른 모달 이후)
          await Future.delayed(Duration(milliseconds: 1200));

          if (mounted) {
            print('📚 목표 완료 모달 표시');
            final result = await _showGoalCompleteModal(
              completedGoal,
              childName,
            );

            if (result == true) {
              // 목표 완료 처리
              final goalId = completedGoal['goalId'];
              if (goalId != null) {
                setState(() {
                  _completedGoalEvaluations.add('$goalId');
                });
                print('📚 목표 $goalId 평가 완료 - 목록에 추가됨');
              }
            }
          }
        }
      } else {
        print('📚 완료된 목표가 없습니다.');
      }
    } catch (e) {
      print('📚 목표 완료 상태 확인 중 오류: $e');
    }

    print('📚 _checkGoalCompletion 메서드 종료');
  }

  // 목표 완료 모달 표시
  Future<bool?> _showGoalCompleteModal(
    Map<String, dynamic> goal,
    String childName,
  ) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('🎉', style: TextStyle(fontSize: 48)),
                SizedBox(height: 16),
                Text(
                  '목표 완료!',
                  style: TextStyle(
                    fontSize: 20,
                    fontFamily: 'Pretendard-Bold',
                    color: Color(0xFF202020),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '${childName}님이 이번 주 목표를 완료했어요!',
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: 'Pretendard-Medium',
                    color: Color(0xFF666666),
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 4),
                Text(
                  '「${goal['title']}」',
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'Pretendard-Bold',
                    color: Color(0xFF5D9EFF),
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: Text(
                          '나중에',
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: 'Pretendard-Medium',
                            color: Color(0xFF999999),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF5D9EFF),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          '보상하기',
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: 'Pretendard-Medium',
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 챌린지 점수 입력 모달 표시
  void _showChallengeScoreModal(ChallengeParticipation challenge) async {
    if (mounted) {
      final childName =
          _selectedChild!['nickname'] ?? _selectedChild!['realName'] ?? '자녀';

      final result = await ParentChallengeScoreModal.show(
        context,
        challenge: challenge.toJson(),
        childName: childName,
        childInfo: _selectedChild, // 자녀 정보 추가
      );

      if (result != null) {
        // 모달에서 평가가 완료되었으므로 데이터 새로고침만 수행
        _loadStudyTimeData();
        _loadFamilyMembers();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '챌린지 평가가 완료되었습니다',
                style: TextStyle(fontFamily: 'Pretendard-Medium'),
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    }
  }

  // 알림 카드 표시 여부 확인
  Future<void> _checkNotificationCardVisibility() async {
    if (_selectedChild == null || _isLoadingFamily) {
      // 자녀가 없거나 로딩 중인 경우 알림 카드 숨김
      setState(() {
        _showNotificationCard = false;
      });
      print('🔔 자녀가 없거나 로딩 중 - 알림 카드 숨김');
      return;
    }

    try {
      print('🔔 알림 카드 표시 여부 확인 시작');

      // 선택된 자녀의 이번 주 목표 조회
      final familyInfo = await FamilyService.getFamilyInfo();
      if (familyInfo == null) {
        print('🔔 가족 정보 없음 - 알림 카드 숨김');
        setState(() {
          _showNotificationCard = false;
        });
        return;
      }

      final familyId = familyInfo['familyId'];
      final weeklyGoals = await GoalService.getParentWeeklyGoals(familyId);

      if (weeklyGoals == null || weeklyGoals.isEmpty) {
        print('🔔 이번 주 목표 없음 - 목표 생성 알림 카드 표시');
        setState(() {
          _showNotificationCard = true;
        });
        return;
      }

      // 선택된 자녀의 ACCEPT 상태 목표만 필터링
      final selectedChildId = _selectedChild!['familyMemberId'];
      final childGoals =
          weeklyGoals
              .where(
                (goal) =>
                    goal['familyMemberId'] == selectedChildId &&
                    goal['status'] == 'ACCEPT',
              )
              .toList();

      if (childGoals.isEmpty) {
        print('🔔 진행 중인 목표 없음 - 목표 생성 알림 카드 표시');
        setState(() {
          _showNotificationCard = true;
        });
        return;
      }

      print('🔔 진행 중인 목표 ${childGoals.length}개 발견');

      // 각 목표의 오늘 도장 상태 확인
      final currentDayNumber = GoalService.getCurrentDayNumber();
      bool allGoalsCheckedToday = true;

      for (final goal in childGoals) {
        final goalId = goal['goalId'];
        if (goalId != null) {
          try {
            final checkData = await GoalService.getGoalCheck(goalId);
            if (checkData != null) {
              final isTodayChecked = GoalService.isDayChecked(
                checkData,
                currentDayNumber,
              );
              print(
                '🔔 목표 ${goal['title']}: 오늘 도장 ${isTodayChecked ? '찍음' : '안찍음'}',
              );

              if (!isTodayChecked) {
                allGoalsCheckedToday = false;
                break;
              }
            } else {
              print('🔔 목표 ${goal['title']}: 도장 데이터 없음 - 안찍음으로 처리');
              allGoalsCheckedToday = false;
              break;
            }
          } catch (e) {
            print('🔔 목표 ${goal['title']} 도장 확인 중 오류: $e');
            allGoalsCheckedToday = false;
            break;
          }
        }
      }

      print('🔔 모든 목표 오늘 도장 확인: $allGoalsCheckedToday');

      // 모든 목표에 오늘 도장을 찍었으면 알림 카드 숨김
      if (mounted) {
        setState(() {
          _showNotificationCard = !allGoalsCheckedToday;
        });
      }

      print('🔔 알림 카드 표시: ${!allGoalsCheckedToday}');
    } catch (e) {
      print('🔔 알림 카드 표시 여부 확인 중 오류: $e');
      // 오류 발생 시 알림 카드 표시 (안전한 기본값)
      if (mounted) {
        setState(() {
          _showNotificationCard = true;
        });
      }
    }
  }

  // 알림 카드 타입 확인 (도장 찍기 vs 목표 생성)
  Future<bool> _isGoalCreationCard() async {
    if (_selectedChild == null) return false;

    try {
      final familyInfo = await FamilyService.getFamilyInfo();
      if (familyInfo == null) return false;

      final familyId = familyInfo['familyId'];
      final weeklyGoals = await GoalService.getParentWeeklyGoals(familyId);

      if (weeklyGoals == null || weeklyGoals.isEmpty) {
        return true; // 전체 목표가 없으면 목표 생성 카드
      }

      // 선택된 자녀의 ACCEPT 상태 목표만 필터링
      final selectedChildId = _selectedChild!['familyMemberId'];
      final childGoals =
          weeklyGoals
              .where(
                (goal) =>
                    goal['familyMemberId'] == selectedChildId &&
                    goal['status'] == 'ACCEPT',
              )
              .toList();

      return childGoals.isEmpty; // 자녀의 진행 중인 목표가 없으면 목표 생성 카드
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE7ECF6),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 24),
                      if (_showNotificationCard) _buildNotificationCard(),
                      if (_showNotificationCard) const SizedBox(height: 32),
                      AllowanceCard(selectedChild: _selectedChild),
                      const SizedBox(height: 24),
                      WeeklyInfoCard(selectedChild: _selectedChild),
                      const SizedBox(height: 24),
                      // 공부 하이라이트 프리뷰 카드
                      _buildStudyHighlightPreviewCard(),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: AnimatedContainer(
        duration: Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
        padding:
            _isScrolled
                ? EdgeInsets.zero
                : const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: GestureDetector(
          onTap: _showMissionCreationModal,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(_isScrolled ? 28 : 24),
            child: AnimatedContainer(
              duration: Duration(milliseconds: 500),
              curve: Curves.easeInOutCubic,
              width: _isScrolled ? 56 : 140,
              height: _isScrolled ? 56 : 48,
              padding:
                  _isScrolled
                      ? EdgeInsets.zero
                      : const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
              decoration: ShapeDecoration(
                color: const Color(0xFF5D9EFF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(_isScrolled ? 28 : 24),
                ),
                shadows: [
                  BoxShadow(
                    color: const Color(0xFF5D9EFF).withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: AnimatedSwitcher(
                duration: Duration(milliseconds: 400),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(scale: animation, child: child),
                  );
                },
                child:
                    _isScrolled
                        ? Container(
                          key: ValueKey('icon'),
                          width: 24,
                          height: 24,
                          child: Image.asset(
                            'assets/icons/parent/mission/mission_create.png',
                            width: 24,
                            height: 24,
                            color: Colors.white,
                            errorBuilder:
                                (context, error, stackTrace) => Icon(
                                  Icons.add,
                                  color: Colors.white,
                                  size: 24,
                                ),
                          ),
                        )
                        : Row(
                          key: ValueKey('text'),
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 18,
                              height: 18,
                              margin: const EdgeInsets.only(right: 8),
                              child: Image.asset(
                                'assets/icons/parent/mission/생성.png',
                                width: 18,
                                height: 18,
                                color: Colors.white,
                                errorBuilder:
                                    (context, error, stackTrace) => Icon(
                                      Icons.add,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                              ),
                            ),
                            Flexible(
                              child: Text(
                                '미션 생성',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontFamily: 'Pretendard-Medium',
                                  letterSpacing: -0.56,
                                ),
                                overflow: TextOverflow.clip,
                              ),
                            ),
                          ],
                        ),
              ),
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: ParentBottomNavigationBar(selectedIndex: 0),
    );
  }

  // 앱바 위젯 구현
  Widget _buildAppBar() {
    return Container(
      width: double.infinity,
      height: 60, // 높이 증가
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 8,
      ), // 상하 패딩 감소
      color: const Color(0xFFE7ECF6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 왼쪽 로고
          Image.asset(
            'assets/logos/parent_logo.png',
            width: 28,
            height: 28,
            fit: BoxFit.contain,
          ),

          // 오른쪽 아이콘들 (자녀 프로필, 부모 프로필, 알림)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 자녀 프로필과 변경 버튼
              Container(
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

              const SizedBox(width: 12),

              // 부모 프로필 아이콘 - 실제 사용자 프로필 이미지로 변경
              Container(
                width: 32,
                height: 32,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child:
                      _isLoadingUser
                          ? Container(
                            color: const Color(0xFFFDC963),
                            child: const Center(
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                          )
                          : _userInfo?['profileImagePath'] != null &&
                              _userInfo!['profileImagePath']!.isNotEmpty
                          ? CachedNetworkImage(
                            imageUrl: AuthService.getFullProfileImageUrl(
                              _userInfo!['profileImagePath'],
                            ),
                            fit: BoxFit.cover,
                            placeholder:
                                (context, url) => Container(
                                  color: const Color(0xFFFDC963),
                                  child: const Center(
                                    child: Text(
                                      '부',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontFamily: 'Pretendard-Bold',
                                      ),
                                    ),
                                  ),
                                ),
                            errorWidget:
                                (context, url, error) => Container(
                                  color: const Color(0xFFFDC963),
                                  child: const Center(
                                    child: Text(
                                      '부',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontFamily: 'Pretendard-Bold',
                                      ),
                                    ),
                                  ),
                                ),
                          )
                          : Container(
                            color: const Color(0xFFFDC963),
                            child: const Center(
                              child: Text(
                                '부',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontFamily: 'Pretendard-Bold',
                                ),
                              ),
                            ),
                          ),
                ),
              ),

              // 알림 아이콘 - 지정된 이미지 파일로 변경
              GestureDetector(
                onTap: () {
                  // 알림 화면으로 이동
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ParentNotificationScreen(),
                    ),
                  );
                },
                child: Container(
                  width: 32,
                  height: 32,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Center(
                        child: Image.asset(
                          'assets/icons/parent/noti/alert.png',
                          width: 20,
                          height: 20,
                          color: Colors.black,
                          errorBuilder:
                              (context, error, stackTrace) => const Icon(
                                Icons.notifications_none_rounded,
                                color: Colors.black,
                                size: 20,
                              ),
                        ),
                      ),
                      // 알림 배지
                      if (_unreadNotificationCount > 0)
                        Positioned(
                          right: 1,
                          top: -3,
                          child: Container(
                            width: 22,
                            height: 15,
                            decoration: BoxDecoration(
                              color: Color(0xFF11CB86),
                              borderRadius: BorderRadius.all(Radius.elliptical(7, 4)),
                            ),
                            child: Center(
                              child: Text(
                                NotificationService.formatUnreadCount(_unreadNotificationCount),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontFamily: 'Pretendard-Bold',
                                  height: 1.0,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 알림 카드 위젯
  Widget _buildNotificationCard() {
    return FutureBuilder<bool>(
      future: _isGoalCreationCard(),
      builder: (context, snapshot) {
        final isGoalCreation = snapshot.data ?? false;

        return GestureDetector(
          onTap: () {
            if (!isGoalCreation) {
              // 도장 찍기 모달만 표시 (목표 생성 카드는 클릭 불가)
              _showGoalCheckModal();
            }
          },
          child: Container(
            width: double.infinity,
            decoration: ShapeDecoration(
              color: const Color(0xFF535B67),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Text(
                              isGoalCreation ? '📝' : '🚨',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontFamily: 'Pretendard-Bold',
                                letterSpacing: -0.32,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                isGoalCreation
                                    ? '${_selectedChild?['nickname'] ?? _selectedChild?['realName'] ?? '자녀'}님의 이번 주 목표가 없어요!'
                                    : '${_selectedChild?['nickname'] ?? _selectedChild?['realName'] ?? '자녀'}님이 오늘 목표를 달성했어요!',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontFamily: 'Pretendard-Bold',
                                  letterSpacing: -0.32,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          // 닫기 기능 추가
                          setState(() {
                            _showNotificationCard = false;
                          });
                        },
                        child: Container(
                          width: 20,
                          height: 20,
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        isGoalCreation
                            ? '목표를 아이에게 세우라고 요청하세요'
                            : '아직 칭찬 스탬프를 찍어주지 않았어요',
                        style: TextStyle(
                          color: const Color(0xFFC4C4C4),
                          fontSize: 12,
                          fontFamily: 'Pretendard-Light',
                          letterSpacing: -0.28,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Image.asset(
                        'assets/icons/parent/들어가기.png',
                        width: 16,
                        height: 16,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // 공부 하이라이트 프리뷰 카드 위젯
  Widget _buildStudyHighlightPreviewCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Color(0x35000000),
            blurRadius: 8,
            offset: Offset(3, 4),
            spreadRadius: 0,
          ),
        ],
        borderRadius: BorderRadius.circular(24),
      ),
      child: Container(
        width: double.infinity,
        decoration: ShapeDecoration(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: ShapeDecoration(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
              ),
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
                          height: 24,
                          child: Text(
                            '우리 아이 현재 총 공부 시간',
                            style: TextStyle(
                              color: const Color(0xFF202020),
                              fontSize: 16,
                              fontFamily: 'Pretendard-Bold',
                              letterSpacing: -0.32,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        _isLoadingStudyTime
                            ? Container(
                              height: 24,
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      color: Color(0xFF146AFF),
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    '계산 중...',
                                    style: TextStyle(
                                      color: const Color(0xFF146AFF),
                                      fontSize: 14,
                                      fontFamily: 'Pretendard-Light',
                                      letterSpacing: -0.56,
                                    ),
                                  ),
                                ],
                              ),
                            )
                            : Text(
                              _totalStudyMinutes > 0
                                  ? '${_totalStudyHours}시간 ${_totalStudyMinutes}분'
                                  : '${_totalStudyHours}시간',
                              style: TextStyle(
                                color: const Color(0xFF146AFF),
                                fontSize: 20,
                                fontFamily: 'Pretendard-Bold',
                                letterSpacing: -0.80,
                              ),
                            ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.white),
              child: Center(
                child: Container(
                  width: 180,
                  height: 180,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // 시계 이미지 - 조건부 표시
                      Image.asset(
                        (_totalStudyHours == 0 && _totalStudyMinutes == 0)
                            ? 'assets/icons/parent/none_time.png'
                            : 'assets/icons/parent/시계.png',
                        width: 180,
                        height: 180,
                        fit: BoxFit.contain,
                        errorBuilder:
                            (context, error, stackTrace) => Container(
                              width: 180,
                              height: 180,
                              color: Colors.grey[200],
                              child: Icon(
                                Icons.access_time,
                                size: 80,
                                color: Colors.grey[400],
                              ),
                            ),
                      ),
                      // 텍스트 오버레이 - 0시간이 아닐 때만 표시
                      if (!(_totalStudyHours == 0 && _totalStudyMinutes == 0))
                        Positioned(
                          top: 30, // 이미지 위쪽으로 이동
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // 이번 주 총 공부 시간 텍스트
                              Text(
                                '이번 주 총 공부 시간',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontFamily: 'Pretendard-Light',
                                  letterSpacing: -0.16,
                                ),
                              ),
                              const SizedBox(height: 1),
                              // 동적 시간 표시
                              _isLoadingStudyTime
                                  ? Container(
                                    height: 22,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          '계산 중...',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontFamily: 'Pretendard-Bold',
                                            letterSpacing: -0.56,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                  : Text(
                                    _totalStudyMinutes > 0
                                        ? '${_totalStudyHours}시간 ${_totalStudyMinutes}분'
                                        : '${_totalStudyHours}시간',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontFamily: 'Pretendard-Bold',
                                      letterSpacing: -0.64,
                                    ),
                                  ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              decoration: ShapeDecoration(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
              ),
              child: Container(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // 분석 화면으로 이동
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ParentAnalysisScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF146AFF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 12,
                    ),
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: Text(
                    '분석 보러가기',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontFamily: 'Pretendard-Medium',
                      letterSpacing: -0.28,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
            // 자녀 변경 시 알림 카드 상태 확인 및 공부 시간 데이터 다시 로드
            _checkNotificationCardVisibility();
            _loadStudyTimeData();

            // 자녀 변경 시 미션 완료 상태도 확인
            print('🚀 자녀 변경 후 _checkMissionCompletion 호출');
            _checkMissionCompletion();

            // 자녀 변경 시 챌린지 완료 상태도 확인
            print('🏆 자녀 변경 후 _checkChallengeCompletion 호출');
            _checkChallengeCompletion();

            // 자녀 변경 시 목표 완료 상태도 확인
            print('📚 자녀 변경 후 _checkGoalCompletion 호출');
            _checkGoalCompletion();
          },
        );
      },
    );
  }

  void _showMissionCreationModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return const MissionCreationModal();
      },
    );
  }

  // 목표 도장 찍기 모달 표시
  void _showGoalCheckModal() async {
    if (_selectedChild == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '선택된 자녀가 없습니다',
            style: TextStyle(fontFamily: 'Pretendard-Medium'),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // 선택된 자녀의 이번 주 목표 조회
      final familyInfo = await FamilyService.getFamilyInfo();
      if (familyInfo == null) {
        throw Exception('가족 정보를 가져올 수 없습니다');
      }

      final familyId = familyInfo['familyId'];
      final weeklyGoals = await GoalService.getParentWeeklyGoals(familyId);

      if (weeklyGoals == null || weeklyGoals.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${_selectedChild!['nickname'] ?? _selectedChild!['realName']}님의 이번 주 목표가 없습니다',
              style: TextStyle(fontFamily: 'Pretendard-Medium'),
            ),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // 선택된 자녀의 목표만 필터링 (ACCEPT 상태인 목표만)
      final selectedChildId = _selectedChild!['familyMemberId'];
      final childGoals =
          weeklyGoals
              .where(
                (goal) =>
                    goal['familyMemberId'] == selectedChildId &&
                    goal['status'] == 'ACCEPT',
              )
              .toList();

      if (childGoals.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${_selectedChild!['nickname'] ?? _selectedChild!['realName']}님의 진행 중인 목표가 없습니다',
              style: TextStyle(fontFamily: 'Pretendard-Medium'),
            ),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // 각 목표의 오늘 도장 상태 확인
      final currentDayNumber = GoalService.getCurrentDayNumber();
      bool allGoalsCheckedToday = true;

      for (final goal in childGoals) {
        final goalId = goal['goalId'];
        if (goalId != null) {
          try {
            final checkData = await GoalService.getGoalCheck(goalId);
            if (checkData != null) {
              final isTodayChecked = GoalService.isDayChecked(
                checkData,
                currentDayNumber,
              );

              if (!isTodayChecked) {
                allGoalsCheckedToday = false;
                break;
              }
            } else {
              allGoalsCheckedToday = false;
              break;
            }
          } catch (e) {
            print('목표 ${goal['title']} 도장 확인 중 오류: $e');
            allGoalsCheckedToday = false;
            break;
          }
        }
      }

      // 모든 목표에 오늘 도장을 찍었으면 알림 메시지 표시
      if (allGoalsCheckedToday) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${_selectedChild!['nickname'] ?? _selectedChild!['realName']}님은 오늘 모든 목표에 도장을 찍었습니다! 👏',
              style: TextStyle(fontFamily: 'Pretendard-Medium'),
            ),
            backgroundColor: Colors.green,
          ),
        );
        return;
      }

      // 목표가 여러 개인 경우 선택 모달 표시, 하나인 경우 바로 도장 찍기
      if (childGoals.length > 1) {
        _showGoalSelectionModal(childGoals);
      } else {
        _showGoalCheckWidget(childGoals.first);
      }
    } catch (e) {
      print('목표 도장 찍기 모달 표시 중 오류: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '목표 정보를 불러오는 중 오류가 발생했습니다',
            style: TextStyle(fontFamily: 'Pretendard-Medium'),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // 홈화면 진입 시 자동으로 목표 도장 찍기 모달 표시
  Future<void> _showGoalCheckModalOnInit() async {
    if (_selectedChild == null) {
      print('🎯 선택된 자녀가 없어서 목표 도장 찍기 모달을 건너뜁니다.');
      return;
    }

    try {
      print('🎯 홈화면 진입 시 목표 도장 찍기 모달 자동 표시 시작');

      // 다른 모달들과 겹치지 않게 지연 시간 추가
      await Future.delayed(Duration(milliseconds: 1500));

      if (!mounted) return;

      // 선택된 자녀의 이번 주 목표 조회
      final familyInfo = await FamilyService.getFamilyInfo();
      if (familyInfo == null) {
        print('🎯 가족 정보를 가져올 수 없습니다.');
        return;
      }

      final familyId = familyInfo['familyId'];
      final weeklyGoals = await GoalService.getParentWeeklyGoals(familyId);

      if (weeklyGoals == null || weeklyGoals.isEmpty) {
        print('🎯 이번 주 목표가 없습니다.');
        return;
      }

      // 선택된 자녀의 목표만 필터링 (ACCEPT 상태인 목표만)
      final selectedChildId = _selectedChild!['familyMemberId'];
      final childGoals =
          weeklyGoals
              .where(
                (goal) =>
                    goal['familyMemberId'] == selectedChildId &&
                    goal['status'] == 'ACCEPT',
              )
              .toList();

      if (childGoals.isEmpty) {
        print('🎯 진행 중인 목표가 없습니다.');
        return;
      }

      print('🎯 진행 중인 목표 ${childGoals.length}개 발견');

      // 각 목표의 오늘 도장 상태 확인
      final currentDayNumber = GoalService.getCurrentDayNumber();
      bool allGoalsCheckedToday = true;

      for (final goal in childGoals) {
        final goalId = goal['goalId'];
        if (goalId != null) {
          try {
            final checkData = await GoalService.getGoalCheck(goalId);
            if (checkData != null) {
              final isTodayChecked = GoalService.isDayChecked(
                checkData,
                currentDayNumber,
              );
              print(
                '🎯 목표 ${goal['title']}: 오늘 도장 ${isTodayChecked ? '찍음' : '안찍음'}',
              );

              if (!isTodayChecked) {
                allGoalsCheckedToday = false;
                break;
              }
            } else {
              print('🎯 목표 ${goal['title']}: 도장 데이터 없음 - 안찍음으로 처리');
              allGoalsCheckedToday = false;
              break;
            }
          } catch (e) {
            print('🎯 목표 ${goal['title']} 도장 확인 중 오류: $e');
            allGoalsCheckedToday = false;
            break;
          }
        }
      }

      print('🎯 모든 목표 오늘 도장 확인: $allGoalsCheckedToday');

      // 모든 목표에 오늘 도장을 찍었으면 모달 표시하지 않음
      if (allGoalsCheckedToday) {
        print('🎯 모든 목표에 오늘 도장을 찍었으므로 모달을 표시하지 않습니다.');
        return;
      }

      if (mounted) {
        // 첫 번째 목표로 바로 도장 찍기 모달 표시
        print('🎯 일부 목표에 오늘 도장을 찍지 않았으므로 모달을 표시합니다.');
        showDialog(
          context: context,
          barrierDismissible: true,
          builder: (BuildContext context) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 24),
              child: ParentGoalCheckWidget(
                goal: childGoals.first,
                onCheckUpdated: () {
                  _checkNotificationCardVisibility();
                },
              ),
            );
          },
        );
      }
    } catch (e) {
      print('🎯 홈화면 진입 시 목표 도장 찍기 모달 표시 중 오류: $e');
    }
  }

  // 목표 선택 모달 표시 (여러 목표가 있을 때)
  void _showGoalSelectionModal(List<Map<String, dynamic>> goals) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => GoalSelectionModal(
              goals: goals,
              onCheckUpdated: () {
                // 도장 찍기 완료 후 알림 카드 상태 재확인
                _checkNotificationCardVisibility();
              },
            ),
      ),
    );
  }

  // 목표 도장 찍기 위젯 표시
  void _showGoalCheckWidget(Map<String, dynamic> goal) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 24),
          child: ParentGoalCheckWidget(
            goal: goal,
            onCheckUpdated: () {
              // 도장 찍기 완료 후 알림 카드 상태 재확인
              _checkNotificationCardVisibility();
            },
          ),
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
