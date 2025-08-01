import 'package:flutter/material.dart';
import '../../models/feed_data.dart';
import '../../widgets/feed/components/feed_filter.dart';
import '../../widgets/feed/components/feed_list.dart' as feed_components;
import './feed/feed_ranking_list.dart';
import './feed/today_feed_screen.dart';
import 'create_post_screen.dart';
import 'home_screen.dart';
import 'chat_list_screen.dart';
import 'mission_screen.dart';
import 'my_page_screen.dart';
import '../notice_kid/notice_kid.dart';
import '../notice_kid/child_screen_wrapper.dart';

class FeedScreen extends StatefulWidget {
  final int initialTab; // 초기 탭 인덱스 (0: 피드, 1: 오늘의 피드, 2: 랭킹)

  const FeedScreen({super.key, this.initialTab = 0});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final FeedData _feedData = FeedData();

  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';
  bool _isSearchFocused = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _feedData.selectedTabIndex = widget.initialTab; // 초기 탭 설정

    // 데이터 로드 완료 콜백 설정 - UI 갱신
    _feedData.onDataLoaded = () {
      if (mounted) {
        setState(() {
          // 데이터 로드 완료 시 화면 갱신
          _isLoading = false;
        });
      }
    };

    _loadInitialData();

    // 스크롤 컨트롤러에 리스너 추가 (무한 스크롤용)
    _scrollController.addListener(_onScroll);
    
    // 검색바 포커스 리스너 추가
    _searchFocusNode.addListener(() {
      setState(() {
        _isSearchFocused = _searchFocusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  // 초기 데이터 로드
  Future<void> _loadInitialData() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });
    }

    try {
      await _feedData.fetchFeeds(refresh: true);
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = '피드를 불러오는 중 오류가 발생했습니다: $e';
        });
      }
    }
  }

  // 스크롤 이벤트 처리 (무한 스크롤)
  void _onScroll() {
    // 스크롤이 끝에 도달했고, 로딩 중이 아니고, 더 불러올 데이터가 있을 때
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        _feedData.hasMore) {
      _loadMoreData();
    }
  }

  // 추가 데이터 로드
  Future<void> _loadMoreData() async {
    if (_isLoading) return;

    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      await _feedData.fetchFeeds();
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          // 추가 로드 실패는 토스트 메시지나 스낵바로 표시할 수 있음
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChildScreenWrapper(
      child: Scaffold(
        backgroundColor: const Color(0xFFF0F2F7),
        body: SafeArea(
          child: Column(
            children: [
              // 피드/오늘의 피드/랭킹 탭 UI
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    // 로고 이미지
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage("assets/images/app_logo.png"),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    // 탭 메뉴들 - Expanded로 반응형 처리
                    Expanded(
                      child: Stack(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              // 피드 탭
                              GestureDetector(
                                onTap: () => _handleTabChange(0),
                                child: Container(
                                  width: 60,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          left: 12,
                                        ),
                                        child: Text(
                                          '피드',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color:
                                                _feedData.selectedTabIndex == 0
                                                    ? const Color(0xFF202020)
                                                    : const Color(0xFF999999),
                                            fontSize: 14,
                                            fontFamily:
                                                _feedData.selectedTabIndex == 0
                                                    ? 'Pretendard-Bold'
                                                    : 'Pretendard-Light',
                                            letterSpacing: -0.32,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      // 탭 하단 선
                                      Container(
                                        height: 2,
                                        width: 60,
                                        color:
                                            _feedData.selectedTabIndex == 0
                                                ? const Color(0xFF202020)
                                                : Colors.transparent,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              // 오늘의 피드 탭
                              GestureDetector(
                                onTap: () => _handleTabChange(1),
                                child: Container(
                                  width: 100,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          left: 14,
                                        ),
                                        child: Text(
                                          '오늘의 피드',
                                          textAlign: TextAlign.center,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color:
                                                _feedData.selectedTabIndex == 1
                                                    ? const Color(0xFF202020)
                                                    : const Color(0xFF999999),
                                            fontSize: 14,
                                            fontFamily:
                                                _feedData.selectedTabIndex == 1
                                                    ? 'Pretendard-Bold'
                                                    : 'Pretendard-Light',
                                            letterSpacing: -0.32,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      // 탭 하단 선
                                      Container(
                                        height: 2,
                                        width: 100,
                                        color:
                                            _feedData.selectedTabIndex == 1
                                                ? const Color(0xFF202020)
                                                : Colors.transparent,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              // 랭킹 탭
                              GestureDetector(
                                onTap: () => _handleTabChange(2),
                                child: Container(
                                  width: 60,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          left: 12,
                                        ),
                                        child: Text(
                                          '랭킹',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color:
                                                _feedData.selectedTabIndex == 2
                                                    ? const Color(0xFF202020)
                                                    : const Color(0xFF999999),
                                            fontSize: 14,
                                            fontFamily:
                                                _feedData.selectedTabIndex == 2
                                                    ? 'Pretendard-Bold'
                                                    : 'Pretendard-Light',
                                            letterSpacing: -0.32,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      // 탭 하단 선
                                      Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          Container(
                                            height: 2,
                                            width: 60,
                                            color: Colors.transparent,
                                          ),
                                          if (_feedData.selectedTabIndex == 2)
                                            Positioned(
                                              left: 0,
                                              child: Container(
                                                height: 2,
                                                width: 100, // 오른쪽으로 40px 더 확장
                                                color: const Color(0xFF202020),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
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
              ),

              // 탭에 따른 컨텐츠 영역
              Expanded(
                child:
                    _feedData.selectedTabIndex == 0
                        ? RefreshIndicator(
                          onRefresh: _loadInitialData,
                          child: SingleChildScrollView(
                            controller: _scrollController,
                            child: Column(
                              children: [
                                // 검색바
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    decoration: ShapeDecoration(
                                      color: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        side: BorderSide(
                                          width: (_isSearchFocused || _searchController.text.isNotEmpty) ? 1.5 : 0.60,
                                          color: (_isSearchFocused || _searchController.text.isNotEmpty) ? const Color(0xFF5D9EFF) : const Color(0xFF8490A3),
                                        ),
                                        borderRadius: BorderRadius.circular(32),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Container(
                                          width: 24,
                                          height: 24,
                                          clipBehavior: Clip.antiAlias,
                                          decoration: const BoxDecoration(),
                                          child: Image.asset(
                                            'assets/icons/my/검색.png',
                                            width: 20,
                                            height: 20,
                                            fit: BoxFit.contain,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: TextField(
                                            controller: _searchController,
                                            focusNode: _searchFocusNode,
                                            onSubmitted: _handleSearch,
                                            onChanged: _handleSearch,
                                            decoration: const InputDecoration(
                                              hintText: '찾고싶은 내용을 검색해 주세요',
                                              hintStyle: TextStyle(
                                                color: Color(0xFF999999),
                                                fontSize: 12,
                                                fontFamily: 'Pretendard-Light',
                                                letterSpacing: -0.24,
                                              ),
                                              border: InputBorder.none,
                                              enabledBorder: InputBorder.none,
                                              focusedBorder: InputBorder.none,
                                              disabledBorder: InputBorder.none,
                                              errorBorder: InputBorder.none,
                                              focusedErrorBorder:
                                                  InputBorder.none,
                                              isDense: true,
                                              contentPadding: EdgeInsets.zero,
                                              fillColor: Colors.white,
                                              filled: true,
                                            ),
                                            style: const TextStyle(
                                              color: Color(0xFF202020),
                                              fontSize: 12,
                                              fontFamily: 'Pretendard-Regular',
                                              letterSpacing: -0.24,
                                            ),
                                          ),
                                        ),
                                        if (_searchController.text.isNotEmpty)
                                          GestureDetector(
                                            onTap: () {
                                              _searchController.clear();
                                              _handleSearch('');
                                            },
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8.0,
                                                  ),
                                              child: Icon(
                                                Icons.close,
                                                color: const Color(0xFF999999),
                                                size: 20,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),

                                // 필터 버튼
                                FeedFilter(
                                  feedData: _feedData,
                                  onFilterChange: _handleFilterChange,
                                  onGradeFilterChange: _handleGradeFilterChange,
                                ),

                                // 정렬 타입 선택 (최신순/추천순)
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    0,
                                    16,
                                    0,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      // 최신순/도움이 된 순 선택기
                                      Flexible(
                                        child: feed_components.SortTypeSelector(
                                          sortType: _feedData.sortType,
                                          onSortTypeChanged:
                                              _handleSortTypeChange,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // 에러 표시
                                if (_hasError)
                                  Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.error_outline,
                                            size: 48,
                                            color: Colors.grey[400],
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            _errorMessage,
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[600],
                                              fontFamily: 'Pretendard-Medium',
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                          const SizedBox(height: 16),
                                          ElevatedButton(
                                            onPressed: _loadInitialData,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(
                                                0xFF3A88F4,
                                              ),
                                              foregroundColor: Colors.white,
                                            ),
                                            child: const Text('다시 시도'),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                // 초기 로딩 표시
                                if (_isLoading && _feedData.feeds.isEmpty)
                                  const Padding(
                                    padding: EdgeInsets.all(32.0),
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        color: Color(0xFF3A88F4),
                                      ),
                                    ),
                                  ),

                                // 피드 목록 - 높이 제한 제거하여 전체 스크롤 가능하게 함
                                if (!_isLoading || _feedData.feeds.isNotEmpty)
                                  feed_components.FeedList(
                                    feedData: _feedData,
                                    onToggleDescription:
                                        _handleToggleDescription,
                                    onToggleLike: _handleToggleLike,
                                    onFeedDeleted: _handleFeedDeleted,
                                    onFeedUpdated: _handleFeedUpdated,
                                  ),

                                // 추가 로딩 인디케이터
                                if (_isLoading && _feedData.feeds.isNotEmpty)
                                  const Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        color: Color(0xFF3A88F4),
                                      ),
                                    ),
                                  ),

                                // 하단 여백 추가
                                const SizedBox(height: 16),
                              ],
                            ),
                          ),
                        )
                        : _feedData.selectedTabIndex == 1
                        ? const TodayFeedScreen()
                        : Container(
                          // 랭킹 화면용 컨테이너: 간격 문제를 해결하기 위해 패딩 제거 및 전체 영역 활용
                          color: Colors.transparent, // 파란색 배경 대신 투명하게 변경
                          margin: EdgeInsets.zero,
                          padding: EdgeInsets.zero,
                          // Transform을 사용하여 상단으로 올리기
                          transform: Matrix4.translationValues(0, -4, 0),
                          child: RankingList(hideFloatingButton: true),
                        ),
              ),
            ],
          ),
        ),
        // 플로팅 액션 버튼 (글쓰기 버튼) - 오늘의 피드 탭 또는 랭킹 탭일 때는 표시하지 않음
        floatingActionButton:
            (_feedData.selectedTabIndex != 1 && _feedData.selectedTabIndex != 2)
                ? Padding(
                  padding: const EdgeInsets.only(
                    bottom: 30,
                  ), // 패딩 값을 줄여 적절한 높이로 조정
                  child: InkWell(
                    onTap: _navigateToCreatePost,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      decoration: ShapeDecoration(
                        color: const Color(0xFF5D9EFF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(27),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/icons/my/글쓰기.png',
                            width: 18,
                            height: 18,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            '글쓰기',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontFamily: 'Pretendard-Light',
                              letterSpacing: -0.54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
                : null,
        // 하단 네비게이션 바
        bottomNavigationBar: Container(
          color: const Color(0xFF1E1E1E), // 어두운 회색 배경
          height: 80,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem('홈', false),
              _buildNavItem('채팅', false),
              _buildNavItem('미션', false),
              _buildNavItem('피드', true),
              _buildNavItem('마이', false),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(String label, bool isSelected) {
    String iconName;
    if (label == '홈') {
      iconName = 'home';
    } else if (label == '채팅') {
      iconName = 'chat';
    } else if (label == '미션') {
      iconName = 'mission';
    } else if (label == '피드') {
      iconName = 'feed';
    } else {
      // 마이
      iconName = 'my';
    }

    String iconPath = 'assets/icons/$iconName.png';
    if (isSelected) {
      iconPath = 'assets/icons/fill_$iconName.png';
    }

    return InkWell(
      onTap: () {
        if (label == '홈') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        } else if (label == '채팅') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const ChatListScreen()),
          );
        } else if (label == '미션') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MissionScreen()),
          );
        } else if (label == '마이') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MyPageScreen()),
          );
        }
      },
      child: SizedBox(
        width: 68,
        height: 80,
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            // 배경 및 그라데이션
            if (isSelected)
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment(0.50, -0.00),
                      end: Alignment(0.50, 1.00),
                      colors: [Color(0x1910CB86), Color(0x0011CB86)],
                    ),
                  ),
                ),
              ),

            // 인디케이터 (선택된 경우만)
            if (isSelected)
              Positioned(
                top: 0,
                child: Container(
                  width: 60,
                  height: 3,
                  decoration: const BoxDecoration(
                    color: Color(0xFF11CB86),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(2),
                      bottomRight: Radius.circular(2),
                    ),
                  ),
                ),
              ),

            // 아이콘과 텍스트
            Positioned(
              top: 15, // 상단 여백 조정
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Image.asset(
                      iconPath,
                      width: 24,
                      height: 24,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: 60, // 텍스트 너비 축소
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color:
                            isSelected ? const Color(0xFF10CB86) : Colors.white,
                        fontSize: 11,
                        fontFamily: 'Pretendard-Medium',
                        letterSpacing: -0.22,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 이벤트 핸들러 메서드들
  void _handleTabChange(int index) {
    setState(() {
      _feedData.changeTab(index);

      // 피드 탭으로 변경 시 데이터 로드
      if (index == 0 && _feedData.feeds.isEmpty) {
        _loadInitialData();
      }
    });
  }

  void _handleSortTypeChange(int type) {
    if (_feedData.sortType == type) return; // 같은 타입이면 무시

    setState(() {
      _isLoading = true; // 로딩 상태 활성화
      _feedData.feeds.clear(); // 기존 피드 목록 비우기
    });

    // 별도 메서드로 정렬 타입 변경 및 데이터 로드
    _feedData.sortType = type; // 직접 sortType 설정

    // 데이터 로드 직접 실행 (changeSortType 대신)
    _loadInitialData();
  }

  void _handleGradeFilterChange(int grade) {
    setState(() {
      if (grade == -1) {
        _feedData.isGradeFilterExpanded = false;
      } else {
        // 학년 필터 값 매핑
        final Map<int, String> gradeValues = {
          0: 'ELEMENTARY',
          1: 'MIDDLE',
          2: 'HIGH',
          3: 'ALL',
        };

        if (gradeValues.containsKey(grade)) {
          _feedData.selectedGradeFilter = gradeValues[grade]!;
          _feedData.isGradeFilterExpanded = true;
        }
      }
    });

    // setState 완료 후 데이터 로드
    Future.microtask(() => _loadInitialData());
  }

  void _handleFilterChange(int filterIndex, int optionIndex) {
    setState(() {
      if (optionIndex == -1) {
        _feedData.isFilterExpanded[filterIndex] = false;
      } else {
        if (filterIndex == 1) {
          // 과목별 필터
          final List<String> subjectValues = [
            'KOREAN',
            'MATH',
            'ENGLISH',
            'SOCIETY',
            'SCIENCE',
            'ALL',
          ];

          if (optionIndex < subjectValues.length) {
            _feedData.selectedSubjectFilter = subjectValues[optionIndex];
            _feedData.isFilterExpanded[filterIndex] = true;
            _feedData.selectedOptionIndex[filterIndex] = optionIndex;
          }
        } else if (filterIndex == 2) {
          // 태그별 필터
          final List<String> tagValues = [
            'STUDY_CERTIFICATION',
            'HABIT_BUILDING',
            'ALL',
          ];

          if (optionIndex < tagValues.length) {
            _feedData.selectedTagFilter = tagValues[optionIndex];
            _feedData.isFilterExpanded[filterIndex] = true;
            _feedData.selectedOptionIndex[filterIndex] = optionIndex;
          }
        }
      }
    });

    // 필터 변경 시 데이터 새로고침 (setState 밖으로 이동)
    Future.microtask(() => _loadInitialData());
  }

  void _handleToggleDescription(int index) {
    setState(() {
      _feedData.toggleDescriptionExpanded(index);
    });
  }

  // 좋아요 토글 처리 메서드를 비동기로 변경
  Future<void> _handleToggleLike(int index) async {
    // 좋아요 버튼 클릭 시 API 호출 후 UI 업데이트
    await _feedData.toggleLike(index);

    // UI 반영을 위한 상태 업데이트
    if (mounted) {
      setState(() {
        // toggleLike 메서드 내에서 이미 데이터를 업데이트했으므로
        // 여기서는 화면 갱신만 처리
      });
    }
  }

  // 피드 삭제 처리 메서드
  void _handleFeedDeleted(int index) {
    // 피드 데이터에서 삭제된 피드 제거
    _feedData.removeFeed(index);

    // UI 업데이트
    setState(() {
      // 화면 갱신
    });
  }

  // 피드 수정 처리 메서드
  void _handleFeedUpdated(int index) {
    // 데이터 새로고침 (피드가 수정되었으므로 서버에서 최신 데이터 가져오기)
    _loadInitialData();
  }

  void _handleSearch(String query) {
    // 검색 기능 구현 (예: 피드 내용 필터링)
    print('검색어: $query');
    // 여기에 검색 API 호출 구현 가능
    setState(() {
      _feedData.changeSearchQuery(query);
    });
  }

  void _navigateToCreatePost() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreatePostScreen()),
    ).then((result) {
      // 글 작성 후 돌아왔을 때 데이터 새로고침
      if (result == true) {
        _loadInitialData();
      }
    });
  }
}
