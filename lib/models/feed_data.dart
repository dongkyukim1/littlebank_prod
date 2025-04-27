class FeedData {
  // 탭 인덱스
  int selectedTabIndex = 0; // 0: 피드, 1: 랭킹

  // 랭킹 기준 인덱스
  int selectedRankingCriterion = 0;

  // 선택된 학년 필터 (0: 초등학생, 1: 중학생, 2: 고등학생)
  int selectedGradeFilter = 0;

  // 학년별 필터가 확장되었는지 여부
  bool isGradeFilterExpanded = false;

  // 랭킹 기준 목록
  final List<String> rankingCriteria = ['미션 수', '성공 횟수', '총 공부시간', '연속 달성'];

  // 세부 필터 항목
  final List<List<String>> filterOptions = [
    ['초등학생', '중학생', '고등학생'], // 학년별 필터
    ['국어', '수학', '영어', '사회', '과학', '기타'], // 과목별 필터
    ['학습', '생활습관', '운동', '기타'], // 미션 종류 필터
  ];

  // 필터 카테고리 이름
  final List<String> filterCategories = ['학년별', '과목별', '미션 종류'];

  // 각 필터별 선택된 항목 인덱스
  final List<int> selectedOptionIndex = [0, 0, 0];

  // 각 필터별 드롭다운 열림 상태
  final List<bool> isFilterExpanded = [false, false, false];

  // 정렬 방식 (0: 최신순, 1: 추천순)
  int sortType = 0;

  // 피드 아이템별 확장 상태 관리
  final Map<int, bool> expandedDescriptions = {};

  // 가상의 피드 데이터
  final List<FeedItem> feeds = [
    FeedItem(
      username: '박리뱅',
      time: '7분 전',
      views: '조회 110',
      content: '일찍 일어나는 새가 먹이를 먹듯이, 아침 일찍 공부하니 성적이 쑥쑥 올라요!',
      description:
          '아버지 저녁도 푹자고 일어나서 공부하니 성적이 오르네요. 나도 아침형 인간으로 변신 중이에요. 화이팅! 오늘도 열심히 해볼게요.',
      images: 3,
      likes: 200,
      comments: 193,
      tags: ['습관 형성', '아침 일찍'],
      isLiked: false,
      grade: 0, // 0: 초등학생
      subject: 5, // 5: 기타
      missionType: 1, // 1: 생활습관
    ),
    FeedItem(
      username: '김수학',
      time: '25분 전',
      views: '조회 85',
      content: '수학 문제 풀이 인증합니다! 오늘도 열심히~',
      description:
          '오늘은 미적분 문제를 30개 풀었어요. 처음엔 어려웠는데 반복하니까 조금씩 실력이 늘어요. 내일은 더 어려운 문제에 도전해볼 예정입니다.',
      images: 2,
      likes: 195,
      comments: 143,
      tags: ['학습', '수학'],
      isLiked: true,
      grade: 2, // 2: 고등학생
      subject: 1, // 1: 수학
      missionType: 0, // 0: 학습
    ),
    FeedItem(
      username: '영어왕',
      time: '1시간 전',
      views: '조회 217',
      content: '영어 단어 100개 외우기 성공했어요!',
      description:
          '매일 아침 영어 단어 100개씩 외우기 도전 중입니다. 벌써 2주차! 지금까지 1400개 외웠네요. 목표는 3000개입니다. 꾸준히 하는 게 중요한 것 같아요.',
      images: 1,
      likes: 312,
      comments: 87,
      tags: ['영어', '학습', '단어'],
      isLiked: false,
      grade: 1, // 1: 중학생
      subject: 2, // 2: 영어
      missionType: 0, // 0: 학습
    ),
    FeedItem(
      username: '과학실험',
      time: '3시간 전',
      views: '조회 356',
      content: '오늘 과학 실험 결과 공유합니다!',
      description:
          '오늘은 집에서 할 수 있는 간단한 화학 실험을 해봤어요. 베이킹소다와 식초를 섞으면 이산화탄소가 발생하는데, 이걸 이용해서 풍선을 불어보았습니다. 생각보다 많이 부풀더라고요!',
      images: 4,
      likes: 423,
      comments: 156,
      tags: ['과학', '화학', '실험'],
      isLiked: true,
      grade: 1, // 1: 중학생
      subject: 4, // 4: 과학
      missionType: 0, // 0: 학습
    ),
    FeedItem(
      username: '운동매니아',
      time: '어제',
      views: '조회 502',
      content: '아침 러닝 5km 완주! 상쾌한 하루 시작해요',
      description:
          '오늘부터 아침 러닝 습관 들이기 시작했어요. 처음이라 힘들었지만 끝나고 나니 너무 상쾌하네요. 목표는 매일 5km씩, 한 달 동안 150km 달성하는 거예요!',
      images: 2,
      likes: 678,
      comments: 231,
      tags: ['운동', '러닝', '습관 형성'],
      isLiked: false,
      grade: 2, // 2: 고등학생
      subject: 5, // 5: 기타
      missionType: 2, // 2: 운동
    ),
    FeedItem(
      username: '독서광',
      time: '어제',
      views: '조회 198',
      content: '이번 주 독서 목표 3권 달성했습니다!',
      description:
          '이번 주에 읽은 책은 『사피엔스』, 『총균쇠』, 『코스모스』입니다. 세 권 모두 정말 좋았어요. 특히 사피엔스는 인류의 역사를 새롭게 볼 수 있게 해주었습니다. 다음 주 목표도 3권입니다!',
      images: 1,
      likes: 245,
      comments: 89,
      tags: ['독서', '학습', '습관 형성'],
      isLiked: true,
      grade: 2, // 2: 고등학생
      subject: 0, // 0: 국어
      missionType: 0, // 0: 학습
    ),
    FeedItem(
      username: '기타마스터',
      time: '3일 전',
      views: '조회 427',
      content: '1일 1곡 기타 연습 30일 차 인증합니다',
      description:
          '30일 동안 매일 한 곡씩 기타 연습한 결과물입니다. 처음에는 손가락이 아파서 힘들었는데, 이제는 코드 전환도 자연스럽게 되고 손도 안 아파요. 꾸준히 하니 실력이 많이 늘었네요!',
      images: 1,
      likes: 512,
      comments: 178,
      tags: ['취미', '기타', '음악'],
      isLiked: true,
      grade: 0, // 0: 초등학생
      subject: 5, // 5: 기타
      missionType: 3, // 3: 기타
    ),
    FeedItem(
      username: '방깨비',
      time: '5일 전',
      views: '조회 632',
      content: '일주일에 책상 정리 3번하기 도전 인증!',
      description:
          '방 청소와 책상 정리를 습관화하기 위해 일주일에 3번씩 하기로 했어요. 오늘이 이번 주 세 번째! 책상이 깨끗하니 공부할 때 집중이 더 잘되는 것 같아요.',
      images: 3,
      likes: 289,
      comments: 103,
      tags: ['생활습관', '정리정돈'],
      isLiked: false,
      grade: 1, // 1: 중학생
      subject: 5, // 5: 기타
      missionType: 1, // 1: 생활습관
    ),
  ];

  // 필터링된 피드 목록을 반환
  List<FeedItem> getFilteredFeeds() {
    List<FeedItem> filteredFeeds = List.from(feeds);

    // 학년별 필터 적용
    if (isGradeFilterExpanded) {
      filteredFeeds =
          filteredFeeds
              .where((feed) => feed.grade == selectedGradeFilter)
              .toList();
    }

    // 과목별 필터 적용
    if (isFilterExpanded[1]) {
      filteredFeeds =
          filteredFeeds
              .where((feed) => feed.subject == selectedOptionIndex[1])
              .toList();
    }

    // 미션 종류 필터 적용
    if (isFilterExpanded[2]) {
      filteredFeeds =
          filteredFeeds
              .where((feed) => feed.missionType == selectedOptionIndex[2])
              .toList();
    }

    // 정렬 적용 (최신순/추천순)
    if (sortType == 1) {
      // 추천순
      filteredFeeds.sort((a, b) => b.likes.compareTo(a.likes));
    }

    return filteredFeeds;
  }

  // 탭 변경
  void changeTab(int index) {
    selectedTabIndex = index;
  }

  // 정렬 방식 변경
  void changeSortType(int type) {
    sortType = type;
  }

  // 필터 토글
  void toggleGradeFilter(int grade) {
    if (selectedGradeFilter == grade && isGradeFilterExpanded) {
      isGradeFilterExpanded = false;
    } else {
      selectedGradeFilter = grade;
      isGradeFilterExpanded = true;
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
  }

  // 설명 확장 상태 토글
  void toggleDescriptionExpanded(int index) {
    expandedDescriptions[index] = !(expandedDescriptions[index] ?? false);
  }

  // 좋아요 토글
  void toggleLike(int index) {
    feeds[index].isLiked = !feeds[index].isLiked;
    if (feeds[index].isLiked) {
      feeds[index].likes++;
    } else {
      feeds[index].likes--;
    }
  }
}

class FeedItem {
  final String username;
  final String time;
  final String views;
  final String content;
  final String description;
  final int images;
  int likes;
  final int comments;
  final List<String> tags;
  bool isLiked;
  final int grade; // 0: 초등학생, 1: 중학생, 2: 고등학생
  final int subject; // 0: 국어, 1: 수학, 2: 영어, 3: 사회, 4: 과학, 5: 기타
  final int missionType; // 0: 학습, 1: 생활습관, 2: 운동, 3: 기타

  FeedItem({
    required this.username,
    required this.time,
    required this.views,
    required this.content,
    required this.description,
    required this.images,
    required this.likes,
    required this.comments,
    required this.tags,
    required this.isLiked,
    required this.grade,
    required this.subject,
    required this.missionType,
  });
}
