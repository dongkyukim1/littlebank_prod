import '../services/feed_service.dart';
import '../services/auth_service.dart';

class FeedData {
  // 탭 인덱스
  int selectedTabIndex = 0; // 0: 피드, 1: 오늘의 피드, 2: 랭킹

  // 데이터 로드 완료 콜백 함수 (UI 갱신용)
  Function? onDataLoaded;

  // 검색어 저장 변수 추가
  String searchQuery = '';

  // 랭킹 기준 인덱스
  int selectedRankingCriterion = 0;

  // 선택된 학년 필터 (ALL, ELEMENTARY, MIDDLE, HIGH)
  String selectedGradeFilter = 'ALL';

  // 선택된 과목 필터 (ALL, KOREAN, MATH, ENGLISH, SOCIAL, SCIENCE...)
  String selectedSubjectFilter = 'ALL';

  // 선택된 태그 필터 (ALL, INFORMATION, HABIT, STUDY...)
  String selectedTagFilter = 'ALL';

  // 학년군 필터가 확장되었는지 여부
  bool isGradeFilterExpanded = false;

  // 랭킹 기준 목록
  final List<String> rankingCriteria = ['미션 수', '성공 횟수', '총 공부시간', '연속 달성'];

  // 세부 필터 항목
  final List<List<String>> filterOptions = [
    ['초등학생', '중학생', '고등학생'], // 학년군 필터
    ['국어', '수학', '영어', '사회', '과학', '기타'], // 과목별 필터
    ['학습', '생활습관', '운동', '기타'], // 미션 종류 필터
  ];

  // 필터 카테고리 이름
  final List<String> filterCategories = ['학년군', '과목별', '미션 종류'];

  // 각 필터별 선택된 항목 인덱스
  final List<int> selectedOptionIndex = [0, 0, 0];

  // 각 필터별 드롭다운 열림 상태
  final List<bool> isFilterExpanded = [false, false, false];

  // 정렬 방식 (0: 최신순, 1: 추천순)
  int sortType = 0;

  // 피드 아이템별 확장 상태 관리
  final Map<int, bool> expandedDescriptions = {};

  // 피드 목록 저장
  List<FeedItem> feeds = [];

  // 피드 로딩 상태
  bool isLoading = false;

  // 현재 페이지 및 페이지 정보
  int currentPage = 0;
  int totalPages = 0;
  int totalElements = 0;
  bool hasMore = true;

  // 피드 데이터를 서버로부터 가져오기
  Future<void> fetchFeeds({bool refresh = false}) async {
    if (isLoading) return;

    isLoading = true;

    // 데이터 로딩 시작 시 콜백 호출 (UI에 로딩 상태 알림)
    if (onDataLoaded != null) {
      onDataLoaded!();
    }

    try {
      // 새로고침시 첫 페이지부터 다시 로드
      if (refresh) {
        currentPage = 0;
        feeds.clear();
        hasMore = true;
      }

      // 더 가져올 페이지가 없으면 중단
      if (!hasMore) {
        isLoading = false;
        if (onDataLoaded != null) {
          onDataLoaded!();
        }
        return;
      }

      // 정렬 옵션 구성
      List<String>? sortOptions;
      if (sortType == 0) {
        // 최신순
        sortOptions = ['createdDate,desc']; // createdAt -> createdDate로 수정
      } else if (sortType == 1) {
        // 좋아요순 정렬은 다른 API 사용
        sortOptions = null;
      }

      // API 호출
      Map<String, dynamic>? result;

      if (sortType == 1) {
        // 좋아요 순일 때는 전용 API 호출
        result = await FeedService.getFeedListByLikes(
          gradeCategory: selectedGradeFilter,
          subjectCategory: selectedSubjectFilter,
          tagCategory: selectedTagFilter,
          page: currentPage,
          size: 10,
        );
      } else {
        // 기본(최신순) API 호출
        result = await FeedService.getFeedList(
          gradeCategory: selectedGradeFilter,
          subjectCategory: selectedSubjectFilter,
          tagCategory: selectedTagFilter,
          page: currentPage,
          size: 10,
          sort: sortOptions,
        );
      }

      if (result != null) {
        // 페이지 정보 업데이트
        totalPages = result['totalPages'] ?? 0;
        totalElements = result['totalElements'] ?? 0;
        hasMore = !(result['last'] ?? true);

        // 피드 데이터 파싱
        final List<dynamic> content = result['content'] ?? [];

        // FeedItem 객체로 변환하여 목록에 추가
        for (var item in content) {
          feeds.add(FeedItem.fromJson(item));
        }

        // 다음 페이지 준비
        currentPage++;
        print('피드 데이터 로드 완료! 항목 수: ${feeds.length}');
      }
    } catch (e) {
      print('데이터 로딩 중 예외 발생: $e');
    } finally {
      isLoading = false;

      // 데이터 로드 완료 콜백 호출 (UI 갱신)
      if (onDataLoaded != null) {
        onDataLoaded!();
        print('데이터 로드 완료 콜백 호출됨');
      }
    }
  }

  // 필터링된 피드 목록을 반환
  List<FeedItem> getFilteredFeeds() {
    if (searchQuery.isEmpty) {
      return feeds; // 검색어가 없으면 전체 피드 반환
    }

    // 검색어가 있으면 제목 또는 내용에 검색어가 포함된 피드만 필터링
    return feeds.where((feed) {
      final title = feed.title.toLowerCase();
      final content = feed.content?.toLowerCase() ?? '';
      final query = searchQuery.toLowerCase();

      return title.contains(query) || content.contains(query);
    }).toList();
  }

  // 탭 변경
  void changeTab(int index) {
    selectedTabIndex = index;
  }

  // 정렬 방식 변경
  void changeSortType(int type) {
    if (sortType != type) {
      sortType = type;
      // 정렬 변경 시 데이터 새로고침
      feeds.clear(); // 기존 피드 데이터 명시적으로 비우기
      hasMore = true; // 데이터 더 있음으로 초기화
      currentPage = 0; // 페이지 초기화

      // 콜백이 있으면 미리 한번 호출 (UI에 빈 상태 반영)
      if (onDataLoaded != null) {
        onDataLoaded!();
      }

      fetchFeeds(refresh: true);
    }
  }

  // 학년군 필터 변경
  void changeGradeFilter(String grade) {
    if (selectedGradeFilter != grade) {
      selectedGradeFilter = grade;
      fetchFeeds(refresh: true);
    }
  }

  // 과목별 필터 변경
  void changeSubjectFilter(String subject) {
    if (selectedSubjectFilter != subject) {
      selectedSubjectFilter = subject;
      fetchFeeds(refresh: true);
    }
  }

  // 태그별 필터 변경
  void changeTagFilter(String tag) {
    if (selectedTagFilter != tag) {
      selectedTagFilter = tag;
      fetchFeeds(refresh: true);
    }
  }

  // 필터 토글
  void toggleGradeFilter(int grade) {
    final gradeValues = ['ELEMENTARY', 'MIDDLE', 'HIGH', 'ALL'];
    if (grade >= 0 && grade < gradeValues.length) {
      String gradeFilter = gradeValues[grade];
      if (selectedGradeFilter == gradeFilter && isGradeFilterExpanded) {
        selectedGradeFilter = 'ALL';
        isGradeFilterExpanded = false;
      } else {
        selectedGradeFilter = gradeFilter;
        isGradeFilterExpanded = true;
      }
      fetchFeeds(refresh: true);
    }
  }

  // 필터 토글
  void toggleFilter(int filterIndex, int optionIndex) {
    if (selectedOptionIndex[filterIndex] == optionIndex &&
        isFilterExpanded[filterIndex]) {
      isFilterExpanded[filterIndex] = false;
    } else {
      selectedOptionIndex[filterIndex] = optionIndex;
      isFilterExpanded[filterIndex] = true;
    }

    // filterIndex에 따라 적절한 필터 적용
    if (filterIndex == 0) {
      // 학년군
      final gradeValues = ['ELEMENTARY', 'MIDDLE', 'HIGH'];
      if (optionIndex < gradeValues.length) {
        selectedGradeFilter = gradeValues[optionIndex];
      } else {
        selectedGradeFilter = 'ALL';
      }
    } else if (filterIndex == 1) {
      // 과목별
      final subjectValues = [
        'KOREAN',
        'MATH',
        'ENGLISH',
        'SOCIETY',
        'SCIENCE',
        'ETC',
      ];
      if (optionIndex < subjectValues.length) {
        selectedSubjectFilter = subjectValues[optionIndex];
      } else {
        selectedSubjectFilter = 'ALL';
      }
    } else if (filterIndex == 2) {
      // 태그별
      final tagValues = [
        'STUDY_CERTIFICATION',
        'HABIT_BUILDING',
        'INFORMATION',
      ];
      if (optionIndex < tagValues.length) {
        selectedTagFilter = tagValues[optionIndex];
      } else {
        selectedTagFilter = 'ALL';
      }
    }

    fetchFeeds(refresh: true);
  }

  // 설명 확장 상태 토글
  void toggleDescriptionExpanded(int index) {
    expandedDescriptions[index] = !(expandedDescriptions[index] ?? false);
  }

  // 좋아요 토글
  Future<void> toggleLike(int index) async {
    if (index >= 0 && index < feeds.length) {
      final FeedItem feed = feeds[index];
      final int? feedId = feed.feedId;

      if (feedId == null) return;

      // 현재 좋아요 상태를 함께 전달하여 API 호출
      final success = await FeedService.toggleLike(feedId, feed.liked);

      if (success) {
        // API 호출 성공 시에만 UI 업데이트
        feeds[index].liked = !feed.liked;
        if (feeds[index].liked) {
          feeds[index].likeCount = (feed.likeCount ?? 0) + 1;
        } else {
          feeds[index].likeCount = (feed.likeCount ?? 0) - 1;
        }
      }
    }
  }

  // 피드 삭제
  void removeFeed(int index) {
    if (index >= 0 && index < feeds.length) {
      feeds.removeAt(index);

      // 콜백이 있으면 호출 (UI 갱신)
      if (onDataLoaded != null) {
        onDataLoaded!();
      }
    }
  }

  // 피드 수정 후 새로운 피드로 업데이트
  void updateFeed(int index, FeedItem updatedFeed) {
    if (index >= 0 && index < feeds.length) {
      feeds[index] = updatedFeed;

      // 콜백이 있으면 호출 (UI 갱신)
      if (onDataLoaded != null) {
        onDataLoaded!();
      }
    }
  }

  // 모든 피드 아이템에 일괄적으로 내 피드 여부를 표시
  static Future<void> markMyFeeds(List<FeedItem> feeds) async {
    try {
      final myName = await AuthService.getName();
      if (myName == null || myName.isEmpty) return;

      for (int i = 0; i < feeds.length; i++) {
        if (feeds[i].writerName == myName) {
          // 테스트 목적으로 모든 피드를 '내 피드'로 표시
          print('피드 ID: ${feeds[i].feedId}가 내 피드로 표시됩니다.');

          // 로직만 출력하고 실제로는 변경하지 않음 (isMyFeed가 final이므로)
          // 실제 구현에서는 더 좋은 방법을 고려해야 함
        }
      }
    } catch (e) {
      print('내 피드 표시 중 오류: $e');
    }
  }

  // 검색어 변경 메서드 추가
  void changeSearchQuery(String query) {
    searchQuery = query.trim();
    // 검색어 변경 시 데이터 초기화 필요 없이 UI에서 피드 목록 필터링 사용
  }
}

class FeedItem {
  final int? feedId;
  final String title;
  final List<String> imageUrls;
  final String? content;
  final String? tagCategory;
  final String? subjectCategory;
  final String? gradeCategory;
  final String? writerName;
  final String? writerProfileImageUrl;
  final int? viewCount;
  int? likeCount;
  int? commentCount;
  bool liked;
  final DateTime? createdDate;
  final DateTime? lastModifiedDate;

  // isMyFeed를 final이 아닌 변수로 변경
  bool isMyFeed;

  FeedItem({
    required this.feedId,
    required this.title,
    required this.imageUrls,
    this.content,
    required this.tagCategory,
    required this.subjectCategory,
    required this.gradeCategory,
    required this.writerName,
    this.writerProfileImageUrl,
    required this.viewCount,
    required this.likeCount,
    required this.commentCount,
    required this.liked,
    this.createdDate,
    this.lastModifiedDate,
    required this.isMyFeed,
  });

  // 피드를 '내 피드'로 표시하는 메서드
  void markAsMyFeed() {
    isMyFeed = true;
    print('피드 ID: $feedId가 내 피드로 표시됩니다.');
  }

  // 프로필 이미지 전체 URL 반환
  String? get fullProfileImageUrl {
    if (writerProfileImageUrl == null || writerProfileImageUrl!.isEmpty) {
      return null;
    }
    return AuthService.getFullProfileImageUrl(writerProfileImageUrl!);
  }

  factory FeedItem.fromJson(Map<String, dynamic> json) {
    // createdDate 파싱
    DateTime? createdDate;
    DateTime? lastModifiedDate;

    // 디버깅용 로깅
    print('피드 ID: ${json['feedId']}, 제목: ${json['title']}');
    print('작성자: ${json['writerName']}');
    print('서버 createdDate: ${json['createdDate']}');
    print('서버 lastModifiedDate: ${json['lastModifiedDate']}');

    // createdDate 파싱
    if (json['createdDate'] != null) {
      try {
        createdDate = DateTime.parse(json['createdDate']);
        print('파싱된 createdDate: $createdDate');
      } catch (e) {
        print('createdDate 파싱 오류: $e');
        // 파싱 실패 시 현재 시간 사용
        createdDate = DateTime.now();
      }
    } else {
      print('createdDate 필드가 null입니다');
      // createdDate가 null인 경우 현재 시간 사용
      createdDate = DateTime.now();
    }

    // lastModifiedDate 파싱
    if (json['lastModifiedDate'] != null) {
      try {
        lastModifiedDate = DateTime.parse(json['lastModifiedDate']);
        print('파싱된 lastModifiedDate: $lastModifiedDate');
      } catch (e) {
        print('lastModifiedDate 파싱 오류: $e');
        lastModifiedDate = null;
      }
    }

    // 내가 작성한 피드인지 확인 - 기본적인 방법으로 판단
    bool isMyFeed = false;

    // 1. 서버에서 명시적으로 isMyFeed 필드를 제공하는 경우
    if (json.containsKey('isMyFeed')) {
      isMyFeed = json['isMyFeed'] as bool? ?? false;
      print('서버에서 제공한 isMyFeed: $isMyFeed');
    }

    // 2. 서버에서 isMyFeed를 제공하지 않지만 내 피드 조회 API를 통해 받은 경우
    if (json.containsKey('fromMyFeed') && json['fromMyFeed'] == true) {
      isMyFeed = true;
      print('fromMyFeed 플래그로 내 피드 확인됨');
    }

    // 3. 명시적으로 testMode가 true인 경우 (테스트 목적)
    if (json.containsKey('testMode') && json['testMode'] == true) {
      isMyFeed = true;
      print('테스트 모드로 내 피드 확인됨');
    }

    print('최종 판단: 이 피드는 내가 작성한 피드인가? $isMyFeed');

    return FeedItem(
      feedId: json['feedId'] as int?,
      title: json['title'] as String? ?? '',
      imageUrls: List<String>.from(json['imageUrls'] ?? []),
      content: json['content'] as String?,
      tagCategory: json['tagCategory'] as String?,
      subjectCategory: json['subjectCategory'] as String?,
      gradeCategory: json['gradeCategory'] as String?,
      writerName: json['writerName'] as String? ?? '작성자 없음',
      writerProfileImageUrl: json['writerProfileImageUrl'] as String?,
      viewCount: json['viewCount'] as int? ?? 0,
      likeCount: json['likeCount'] as int? ?? 0,
      commentCount: json['commentCount'] as int? ?? 0,
      liked: json['liked'] as bool? ?? false,
      createdDate: createdDate,
      lastModifiedDate: lastModifiedDate,
      isMyFeed: isMyFeed,
    );
  }

  // 상대적 시간 문자열 반환 (방금 전, 3분 전, 1시간 전 등)
  String getTimeAgo() {
    if (createdDate == null) return '방금 전';

    // 서버 시간(UTC)을 한국 시간(UTC+9)으로 변환
    final koreanCreatedDate = createdDate!.add(Duration(hours: 9));

    // 현재 시간과 변환된 서버 시간 로그
    final now = DateTime.now();
    print('현재 시간(로컬): $now');
    print('서버 시간(UTC): $createdDate');
    print('변환된 시간(UTC+9): $koreanCreatedDate');

    // 변환된 시간으로 차이 계산
    final difference = now.difference(koreanCreatedDate);
    print('시간 차이(초): ${difference.inSeconds}');

    // 시간 차이가 음수인 경우 (미래의 날짜)
    if (difference.inSeconds < 0) {
      return '방금 전';
    }

    // 시간 차이에 따른 표시 형식 선택
    if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months달 전';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}일 전';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}시간 전';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}분 전';
    } else {
      return '방금 전';
    }
  }

  // 학년 텍스트 반환
  String getGradeText() {
    if (gradeCategory == null) return '';

    switch (gradeCategory) {
      case 'ELEMENTARY':
        return '초등학생';
      case 'MIDDLE':
        return '중학생';
      case 'HIGH':
        return '고등학생';
      default:
        return '';
    }
  }

  // 과목 텍스트 반환
  String getSubjectText() {
    if (subjectCategory == null) return '';

    switch (subjectCategory) {
      case 'KOREAN':
        return '국어';
      case 'MATH':
        return '수학';
      case 'ENGLISH':
        return '영어';
      case 'SOCIETY':
        return '사회';
      case 'SCIENCE':
        return '과학';
      default:
        return '';
    }
  }

  // 태그 텍스트 반환
  String getTagText() {
    if (tagCategory == null) return '';

    switch (tagCategory) {
      case 'STUDY_CERTIFICATION':
        return '학습인증';
      case 'HABIT_BUILDING':
        return '습관형성';
      case 'INFORMATION':
        return '정보';
      default:
        return '';
    }
  }
}
