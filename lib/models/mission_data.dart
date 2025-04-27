import 'package:flutter/material.dart';
import '../widgets/shared_goal_data.dart';

/// 미션 화면에서 사용하는 모든 데이터를 관리하는 클래스
class MissionData extends ChangeNotifier {
  // 친구 선택 관련
  bool _isFriendSelected = false;
  bool get isFriendSelected => _isFriendSelected;
  set isFriendSelected(bool value) {
    _isFriendSelected = value;
    notifyListeners();
  }

  String _selectedFriendName = '김민수';
  String get selectedFriendName => _selectedFriendName;
  set selectedFriendName(String value) {
    _selectedFriendName = value;
    notifyListeners();
  }

  bool _isComparisonCollapsed = false;
  bool get isComparisonCollapsed => _isComparisonCollapsed;
  set isComparisonCollapsed(bool value) {
    _isComparisonCollapsed = value;
    notifyListeners();
  }

  bool _isComparisonExpanded = false;
  bool get isComparisonExpanded => _isComparisonExpanded;
  set isComparisonExpanded(bool value) {
    _isComparisonExpanded = value;
    notifyListeners();
  }

  bool _showComparisonPanel = false;
  bool get showComparisonPanel => _showComparisonPanel;
  set showComparisonPanel(bool value) {
    _showComparisonPanel = value;
    notifyListeners();
  }

  String _selectedProfile = "";
  String get selectedProfile => _selectedProfile;
  set selectedProfile(String value) {
    _selectedProfile = value;
    notifyListeners();
  }

  bool _detailedComparisonView = false;
  bool get detailedComparisonView => _detailedComparisonView;
  set detailedComparisonView(bool value) {
    _detailedComparisonView = value;
    notifyListeners();
  }

  // 미션 비교 섹션의 GlobalKey
  final GlobalKey missionComparisonKey = GlobalKey();

  // 친구 목록
  List<Map<String, dynamic>> friends = [
    {'name': '김동규', 'missions': 15, 'totalMissions': 20},
    {'name': '장태현', 'missions': 8, 'totalMissions': 20},
    {'name': '김도연', 'missions': 16, 'totalMissions': 20},
    {'name': '김은서', 'missions': 12, 'totalMissions': 20},
  ];

  // 내 미션 정보
  Map<String, dynamic> myInfo = {
    'name': '김동규',
    'missions': 12,
    'totalMissions': 20,
  };

  // 친구들의 평균 미션 수행 계산
  double get friendsAverageMissions {
    double total = 0;
    for (var friend in friends) {
      total += friend['missions'] as int;
    }
    return total / friends.length;
  }

  // 주간 목표 데이터
  Map<String, dynamic>? weeklyGoal;

  // 챌린지 관련 변수
  int refreshCount = 0;

  // 전체 챌린지 목록
  final List<Map<String, dynamic>> allChallenges = [
    {
      'periodType': '주별',
      'title': '일주일동안 매일 수학 3시간',
      'participants': '30/40',
      'period': '3.20-3.27',
      'time': '매일 3시간',
    },
    {
      'periodType': '월별',
      'title': '한달동안 영어 문장 50개 외우기',
      'participants': '25/50',
      'period': '3.1 - 3.31',
      'time': '매일 30분',
    },
    {
      'periodType': '주별',
      'title': '아침 6시 기상하기',
      'participants': '45/60',
      'period': '3.15 - 3.22',
      'time': '매일 오전 6시',
    },
    {
      'periodType': '월별',
      'title': '하루 30분 독서하기',
      'participants': '28/35',
      'period': '3.1 - 3.31',
      'time': '매일 30분',
    },
    {
      'periodType': '주별',
      'title': '주 3회 조깅하기',
      'participants': '20/30',
      'period': '3.18 - 3.25',
      'time': '주 3회',
    },
    {
      'periodType': '월별',
      'title': '하루 물 2리터 마시기',
      'participants': '15/30',
      'period': '3.1 - 3.31',
      'time': '매일',
    },
  ];

  // 현재 표시할 챌린지 (랜덤하게 2개 선택)
  List<Map<String, dynamic>> currentChallenges = [];

  // 초기화 함수
  void init() {
    // 랜덤하게 챌린지 2개 선택
    refreshChallenges();

    // 기존 목표 데이터가 있으면 로드
    if (SharedGoalData.weeklyGoal != null) {
      weeklyGoal = SharedGoalData.weeklyGoal;
    }
  }

  // 새로운 챌린지를 랜덤하게 선택하는 메서드
  void refreshChallenges() {
    // allChallenges를 복사하고 섞어서 랜덤한 순서로 만듦
    final List<Map<String, dynamic>> shuffled = List.from(allChallenges)
      ..shuffle();

    // 첫 2개 아이템 선택
    currentChallenges = shuffled.take(2).toList();
    if (refreshCount < 3) {
      refreshCount++;
    }
  }

  // 날짜 포맷 메서드
  static String formatDate(DateTime date) {
    return '${date.year}/${date.month}/${date.day}';
  }
}
