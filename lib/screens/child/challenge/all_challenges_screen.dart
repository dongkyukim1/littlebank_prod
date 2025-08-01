import 'package:flutter/material.dart';
import 'challenge_detail_screen.dart';
import '../../../widgets/common/bottom_navigation_bar.dart';
import '../../../services/challenge_service.dart';

class AllChallengesScreen extends StatefulWidget {
  const AllChallengesScreen({super.key});

  @override
  State<AllChallengesScreen> createState() => _AllChallengesScreenState();
}

class _AllChallengesScreenState extends State<AllChallengesScreen> {
  String _selectedFilter = '전체';
  final List<String> _filters = ['전체', '과목별', '요일별'];
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';
  String _selectedSort = '참여자가 많은 순';
  bool _isSearchFocused = false;

  // 챌린지 관련 변수
  List<Map<String, dynamic>> _allChallenges = [];
  bool _isLoadingChallenges = true;
  String? _challengeError;

  @override
  void initState() {
    super.initState();
    _loadChallenges();
    
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
    super.dispose();
  }

  // API로부터 챌린지 데이터 불러오기
  Future<void> _loadChallenges() async {
    try {
      if (mounted) {
        setState(() {
          _isLoadingChallenges = true;
          _challengeError = null;
        });
      }

      final challengeResponse = await ChallengeService.getChallenges();
      final challenges = challengeResponse.data;
      
      if (challenges.isEmpty) {
        if (mounted) {
          setState(() {
            _isLoadingChallenges = false;
            _allChallenges = [];
          });
        }
        return;
      }

      // API 응답을 프론트엔드 형식으로 변환
      final formattedChallenges = challenges.map((challenge) {
        // 카테고리를 한글로 변환
        String periodType = '전체';
        if (challenge.category == 'WEEK') {
          periodType = '요일별';
        } else if (challenge.category == 'SUBJECT') {
          periodType = '과목별';
        }

        // 시작 날짜와 종료 날짜를 형식화 - 3.20 - 3.27 형식
        // ISO 8601 형식에서 날짜 부분만 추출 (T 이전 부분)
        String startDateOnly = challenge.startDate.split('T')[0];
        String endDateOnly = challenge.endDate.split('T')[0];
        
        String startMonth = startDateOnly.split('-')[1].replaceFirst(RegExp('^0'), '');
        String startDay = startDateOnly.split('-')[2].replaceFirst(RegExp('^0'), '');
        String endMonth = endDateOnly.split('-')[1].replaceFirst(RegExp('^0'), '');
        String endDay = endDateOnly.split('-')[2].replaceFirst(RegExp('^0'), '');
        String period = '$startMonth.$startDay - $endMonth.$endDay';

        // 전체 데이터 형식화
        return {
          'id': challenge.id,
          'periodType': periodType,
          'title': challenge.title,
          'participants': '${challenge.currentParticipants}/${challenge.totalParticipants}',
          'period': period,
          'time': challenge.totalStudyTime > 0 ? '매일 ${challenge.totalStudyTime}시간' : '설정 가능',
          'description': challenge.description,
          'startDate': challenge.startDate,
          'endDate': challenge.endDate,
          'startTime': '09:00:00', // 기본값 (사용자가 입력할 예정)
          'totalStudyTime': challenge.totalStudyTime,
          'reward': challenge.reward ?? 0,
        };
      }).toList();

      if (mounted) {
        setState(() {
          _allChallenges = formattedChallenges;
          _isLoadingChallenges = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingChallenges = false;
          _challengeError = '챌린지 데이터를 불러오는 중 오류가 발생했습니다.';
          print('챌린지 데이터 로딩 오류: $e');
        });
      }
    }
  }

  // 카테고리별 필터링
  Future<void> _filterChallengesByCategory(String category) async {
    try {
      setState(() {
        _isLoadingChallenges = true;
        _challengeError = null;
      });

      ChallengeCategory? selectedCategory;
      
      if (category == '요일별') {
        selectedCategory = ChallengeCategory.WEEK;
      } else if (category == '과목별') {
        selectedCategory = ChallengeCategory.SUBJECT;
      }

      final challengeResponse = selectedCategory == null
          ? await ChallengeService.getChallenges()
          : await ChallengeService.getChallenges(category: selectedCategory);
      
      final challenges = challengeResponse.data;
      
      if (challenges.isEmpty) {
        setState(() {
          _isLoadingChallenges = false;
          _allChallenges = [];
        });
        return;
      }

      // API 응답을 프론트엔드 형식으로 변환
      final formattedChallenges = challenges.map((challenge) {
        // 카테고리를 한글로 변환
        String periodType = '전체';
        if (challenge.category == 'WEEK') {
          periodType = '요일별';
        } else if (challenge.category == 'SUBJECT') {
          periodType = '과목별';
        }

        // 시작 날짜와 종료 날짜를 형식화 - 3.20 - 3.27 형식
        // ISO 8601 형식에서 날짜 부분만 추출 (T 이전 부분)
        String startDateOnly = challenge.startDate.split('T')[0];
        String endDateOnly = challenge.endDate.split('T')[0];
        
        String startMonth = startDateOnly.split('-')[1].replaceFirst(RegExp('^0'), '');
        String startDay = startDateOnly.split('-')[2].replaceFirst(RegExp('^0'), '');
        String endMonth = endDateOnly.split('-')[1].replaceFirst(RegExp('^0'), '');
        String endDay = endDateOnly.split('-')[2].replaceFirst(RegExp('^0'), '');
        String period = '$startMonth.$startDay - $endMonth.$endDay';

        // 전체 데이터 형식화
        return {
          'id': challenge.id,
          'periodType': periodType,
          'title': challenge.title,
          'participants': '${challenge.currentParticipants}/${challenge.totalParticipants}',
          'period': period,
          'time': challenge.totalStudyTime > 0 ? '매일 ${challenge.totalStudyTime}시간' : '설정 가능',
          'description': challenge.description,
          'startDate': challenge.startDate,
          'endDate': challenge.endDate,
          'startTime': '09:00:00', // 기본값 (사용자가 입력할 예정)
          'totalStudyTime': challenge.totalStudyTime,
          'reward': challenge.reward ?? 0,
        };
      }).toList();

      setState(() {
        _allChallenges = formattedChallenges;
        _isLoadingChallenges = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingChallenges = false;
        _challengeError = '챌린지 데이터를 불러오는 중 오류가 발생했습니다.';
        print('챌린지 데이터 로딩 오류: $e');
      });
    }
  }

  // 필터링된 챌린지 목록
  List<Map<String, dynamic>> get _filteredChallenges {
    // 이미 API 호출로 필터링된 데이터를 사용
    List<Map<String, dynamic>> filtered = List.from(_allChallenges);
    
    // 검색어로 필터링
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where(
            (challenge) =>
                challenge['title'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
                challenge['periodType'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
                challenge['time'].toLowerCase().contains(_searchQuery.toLowerCase()),
          )
          .toList();
    }
    
    // 정렬 기준에 따라 정렬
    if (_selectedSort == '참여자가 많은 순') {
      filtered.sort((a, b) {
        int aParticipants = int.parse(a['participants'].split('/')[0]);
        int bParticipants = int.parse(b['participants'].split('/')[0]);
        return bParticipants.compareTo(aParticipants); // 내림차순
      });
    } else if (_selectedSort == '최신순') {
      // 임의로 현재 리스트 순서를 reverse하여 최신순으로 가정
      // 실제 구현에서는 날짜 데이터가 필요함
      filtered = filtered.reversed.toList();
    } else if (_selectedSort == '종료일이 가까운') {
      // 기한을 기준으로 정렬
      filtered.sort((a, b) {
        // '3.20 - 3.27' 형식에서 종료일을 추출
        String aEnd = a['period'].split(' - ')[1];
        String bEnd = b['period'].split(' - ')[1];
        // 단순 문자열 비교로 정렬 (실제 구현에서는 날짜 변환 필요)
        return aEnd.compareTo(bEnd); // 오름차순
      });
    }
    
    return filtered;
  }

  // 챌린지 참여하기 처리
  Future<void> _joinChallenge(Map<String, dynamic> challenge) async {
    try {
      // ChallengeDetailScreen으로 네비게이션
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChallengeDetailScreen(
            id: challenge['id'] ?? 0,
            type: challenge['periodType'] ?? '',
            title: challenge['title'] ?? '',
            participants: challenge['participants'] ?? '0/0',
            period: challenge['period'] ?? '',
            time: challenge['time'] ?? '',
            startDate: challenge['startDate'] ?? '',
            endDate: challenge['endDate'] ?? '',
            startTime: challenge['startTime'] ?? '',
            totalStudyTime: challenge['totalStudyTime'] ?? 0,
            reward: challenge['reward'] ?? 0,
          ),
        ),
      );
      
      // 챌린지 상세 화면에서 돌아왔을 때 성공적으로 신청했다면 목록 새로고침
      if (result == true) {
        // 챌린지 목록 새로고침
        if (_selectedFilter == '전체') {
          _loadChallenges();
        } else {
          _filterChallengesByCategory(_selectedFilter);
        }
      }
      
    } catch (e) {
      print('챌린지 상세 화면 이동 오류: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('챌린지 상세 화면으로 이동할 수 없습니다: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Image.asset(
            'assets/images/뒤로가기.png',
            width: 24,
            height: 24,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '챌린지 전체보기',
          style: TextStyle(
            color: Colors.black,
            fontSize: 14,
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w700,
            letterSpacing: -0.32,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 탭바 (전체, 과목별, 요일별) - 가로선으로 변경
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: Color(0xFFE0E0E0),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedFilter = '전체';
                      });
                      _loadChallenges();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: _selectedFilter == '전체' 
                                ? const Color(0xFF202020) 
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                      child: Text(
                        '전체',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _selectedFilter == '전체' 
                              ? const Color(0xFF202020) 
                              : const Color(0xFF999999),
                          fontSize: 14,
                          fontFamily: _selectedFilter == '전체' 
                              ? 'Pretendard-Bold' 
                              : 'Pretendard-Light',
                          letterSpacing: -0.32,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedFilter = '과목별';
                      });
                      _filterChallengesByCategory('과목별');
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: _selectedFilter == '과목별' 
                                ? const Color(0xFF202020) 
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                      child: Text(
                        '과목별',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _selectedFilter == '과목별' 
                              ? const Color(0xFF202020) 
                              : const Color(0xFF999999),
                          fontSize: 14,
                          fontFamily: _selectedFilter == '과목별' 
                              ? 'Pretendard-Bold' 
                              : 'Pretendard-Light',
                          letterSpacing: -0.32,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedFilter = '요일별';
                      });
                      _filterChallengesByCategory('요일별');
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: _selectedFilter == '요일별' 
                                ? const Color(0xFF202020) 
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                      child: Text(
                        '요일별',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _selectedFilter == '요일별' 
                              ? const Color(0xFF202020) 
                              : const Color(0xFF999999),
                          fontSize: 14,
                          fontFamily: _selectedFilter == '요일별' 
                              ? 'Pretendard-Bold' 
                              : 'Pretendard-Light',
                          letterSpacing: -0.32,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // 탭과 서치바 사이 간격 추가
          const SizedBox(height: 12),

          // 검색창
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Container(
              width: double.infinity,
              height: 40, 
              decoration: ShapeDecoration(
                color: const Color(0xFFE7ECF6),
                shape: RoundedRectangleBorder(
                  side: BorderSide(
                    width: (_isSearchFocused || _searchQuery.isNotEmpty) ? 1.5 : 0.60, 
                    color: (_isSearchFocused || _searchQuery.isNotEmpty) ? const Color(0xFF5D9EFF) : const Color(0xFF5D6A7F)
                  ),
                  borderRadius: BorderRadius.circular(32),
                ),
              ),
              child: Stack(
                children: [
                  // 검색 아이콘과 텍스트필드
                  Positioned(
                    left: 16,
                    top: 0,
                    bottom: 0,
                    right: 40, // X 버튼 공간 확보
                    child: Center(
                      child: Row(
                        children: [
                          Image.asset(
                            'assets/images/search.png',
                            width: 24,
                            height: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              focusNode: _searchFocusNode,
                              style: const TextStyle(
                                color: Color(0xFF353535),
                                fontSize: 12,
                                fontFamily: 'Pretendard-Light',
                                letterSpacing: -0.24,
                              ),
                              decoration: const InputDecoration(
                                hintText: '찾고싶은 챌린지를 검색해 주세요',
                                hintStyle: TextStyle(
                                  color: Color(0xFF999999),
                                  fontSize: 12,
                                  fontFamily: 'Pretendard-Light',
                                  letterSpacing: -0.24,
                                ),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                                isDense: true,
                                filled: false,
                              ),
                              onChanged: (value) {
                                setState(() {
                                  _searchQuery = value;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // X 버튼을 오른쪽 끝에 위치
                  if (_searchQuery.isNotEmpty)
                    Positioned(
                      right: 8,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: GestureDetector(
                          onTap: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                          child: const Icon(
                            Icons.clear, 
                            color: Colors.grey, 
                            size: 20
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // 필터 옵션
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedSort = '참여자가 많은 순';
                    });
                  },
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.only(top: 2),
                        decoration: ShapeDecoration(
                          color: _selectedSort == '참여자가 많은 순' 
                              ? const Color(0xFF5D9EFF) 
                              : const Color(0xFFB6B6B6),
                          shape: const OvalBorder(),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '참여자가 많은 순',
                        style: TextStyle(
                          color: _selectedSort == '참여자가 많은 순' 
                              ? const Color(0xFF001F55) 
                              : const Color(0xFFB6B6B6),
                          fontSize: 11,
                          fontFamily: _selectedSort == '참여자가 많은 순' 
                              ? 'Pretendard-Medium' 
                              : 'Pretendard-Light',
                          letterSpacing: -0.24,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedSort = '최신순';
                    });
                  },
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.only(top: 2),
                        decoration: ShapeDecoration(
                          color: _selectedSort == '최신순' 
                              ? const Color(0xFF5D9EFF) 
                              : const Color(0xFFB6B6B6),
                          shape: const OvalBorder(),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '최신순',
                        style: TextStyle(
                          color: _selectedSort == '최신순' 
                              ? const Color(0xFF001F55) 
                              : const Color(0xFFB6B6B6),
                          fontSize: 11,
                          fontFamily: _selectedSort == '최신순' 
                              ? 'Pretendard-Medium' 
                              : 'Pretendard-Light',
                          letterSpacing: -0.24,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedSort = '종료일이 가까운';
                    });
                  },
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.only(top: 2),
                        decoration: ShapeDecoration(
                          color: _selectedSort == '종료일이 가까운' 
                              ? const Color(0xFF5D9EFF) 
                              : const Color(0xFFB6B6B6),
                          shape: const OvalBorder(),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '종료일이 가까운',
                        style: TextStyle(
                          color: _selectedSort == '종료일이 가까운' 
                              ? const Color(0xFF001F55) 
                              : const Color(0xFFB6B6B6),
                          fontSize: 11,
                          fontFamily: _selectedSort == '종료일이 가까운' 
                              ? 'Pretendard-Medium' 
                              : 'Pretendard-Light',
                          letterSpacing: -0.24,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 챌린지 카드 그리드
          Expanded(
            child: _isLoadingChallenges 
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF5D9EFF),
                    ),
                  )
                : _challengeError != null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline, 
                          color: Color(0xFF999999), 
                          size: 48
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _challengeError!,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF999999),
                            fontFamily: 'Pretendard-Medium',
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () {
                            if (_selectedFilter == '전체') {
                              _loadChallenges();
                            } else {
                              _filterChallengesByCategory(_selectedFilter);
                            }
                          },
                          child: const Text(
                            '다시 시도',
                            style: TextStyle(
                              color: Color(0xFF5D9EFF),
                              fontSize: 14,
                              fontFamily: 'Pretendard-Medium',
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : _filteredChallenges.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _searchQuery.isNotEmpty ? Icons.search_off : Icons.event_busy,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isNotEmpty 
                              ? '검색 결과가 없습니다' 
                              : '현재 진행 중인 챌린지가 없습니다',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                            fontFamily: 'Pretendard',
                          ),
                        ),
                        if (_searchQuery.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              '다른 검색어로 시도해보세요',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                                fontFamily: 'Pretendard-Light',
                              ),
                            ),
                          ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                    itemCount: _filteredChallenges.length,
                    itemBuilder: (context, index) {
                      final challenge = _filteredChallenges[index];
                      
                      return Container(
                        width: double.infinity, // 카드를 전체 너비로 설정
                        margin: EdgeInsets.only(
                          top: index == 0 ? 8 : 0, // 첫 번째 카드 상단 간격 추가
                          bottom: index < _filteredChallenges.length - 1 ? 20 : 8, // 카드 간 간격 및 마지막 카드 하단 간격
                        ),
                        child: _buildChallengeCard(challenge, challenge['time']),
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: const CommonBottomNavigationBar(selectedIndex: 2),
    );
  }

  Widget _buildChallengeCard(Map<String, dynamic> challenge, String timeValue) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(16),
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 상단 부분 (태그 + 참여하기 버튼)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                             // 태그 영역
               Expanded(
                 child: Wrap(
                   spacing: 8,
                   runSpacing: 8,
                   children: [
                     Container(
                       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                       decoration: ShapeDecoration(
                         color: const Color(0xFFFFD27F),
                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                       ),
                       child: Text(
                         '챌린지',
                         style: TextStyle(
                           color: Colors.white,
                           fontSize: 10,
                           fontFamily: 'Pretendard-Light',
                           letterSpacing: -0.24,
                         ),
                       ),
                     ),
                     Container(
                       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                       decoration: ShapeDecoration(
                         color: const Color(0xFF5D9EFF),
                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                       ),
                       child: Text(
                         challenge['periodType'],
                         style: TextStyle(
                           color: Colors.white,
                           fontSize: 10,
                           fontFamily: 'Pretendard-Light',
                           letterSpacing: -0.24,
                         ),
                       ),
                     ),
                   ],
                 ),
               ),
              
                             // 참여하기 버튼
               GestureDetector(
                 onTap: () => _joinChallenge(challenge),
                 child: Container(
                   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                   decoration: BoxDecoration(
                     color: const Color(0xFF146AFF),
                     borderRadius: BorderRadius.circular(8),
                     boxShadow: const [
                       BoxShadow(
                         color: Color(0x0F000000),
                         blurRadius: 2,
                         offset: Offset(0, 1),
                       )
                     ],
                   ),
                   child: const Text(
                     '참여하기',
                     style: TextStyle(
                       color: Colors.white,
                       fontSize: 11,
                       fontFamily: 'Pretendard-Light',
                       letterSpacing: -0.24,
                     ),
                   ),
                 ),
               ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // 제목
          Text(
            challenge['title'],
            style: TextStyle(
              color: const Color(0xFF353535),
              fontSize: 14,
              fontFamily: 'Pretendard-Bold',
              letterSpacing: -0.32,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          
          const SizedBox(height: 12),
          
          // 정보 영역 (참여인원, 기한, 시간)
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '참여 인원',
                      style: TextStyle(
                        color: const Color(0xFF666666),
                        fontSize: 12,
                        fontFamily: 'Pretendard-Light',
                        letterSpacing: -0.28,
                      ),
                    ),
                    SizedBox(height: 6),
                     Text.rich(
                       TextSpan(
                         children: [
                           TextSpan(
                             text: '${challenge['participants'].split('/')[0]}/',
                             style: const TextStyle(
                               color: Color(0xFF5D9EFF),
                               fontSize: 14,
                               fontFamily: 'Pretendard-Bold',
                               letterSpacing: -0.32,
                             ),
                           ),
                           TextSpan(
                             text: challenge['participants'].split('/')[1],
                             style: const TextStyle(
                               color: Color(0xFF4A4A4A),
                               fontSize: 14,
                               fontFamily: 'Pretendard-Bold',
                               letterSpacing: -0.32,
                             ),
                           ),
                         ],
                       ),
                     ),
                  ],
                ),
              ),
              Container(width: 1, height: 40, color: Color.fromRGBO(231, 236, 246, 1)),
                             Expanded(
                 child: Column(
                   children: [
                     Text(
                       '기한',
                       style: TextStyle(
                         color: const Color(0xFF666666),
                         fontSize: 12,
                         fontFamily: 'Pretendard-Light',
                         letterSpacing: -0.28,
                       ),
                     ),
                     SizedBox(height: 6),
                     Text(
                       timeValue.isNotEmpty ? timeValue : challenge['period'],
                       style: TextStyle(
                         color: const Color(0xFF4A4A4A),
                         fontSize: 14,
                         fontFamily: 'Pretendard-Light',
                         letterSpacing: -0.32,
                       ),
                       textAlign: TextAlign.center,
                     ),
                   ],
                 ),
               ),
                             Container(width: 1, height: 40, color: Color.fromRGBO(231, 236, 246, 1)),
               Expanded(
                 child: Column(
                   children: [
                     Text(
                       '시간',
                       style: TextStyle(
                         color: const Color(0xFF666666),
                         fontSize: 12,
                         fontFamily: 'Pretendard-Light',
                         letterSpacing: -0.28,
                       ),
                     ),
                     SizedBox(height: 6),
                     Text(
                       timeValue.isNotEmpty ? timeValue : '설정 가능',
                       style: TextStyle(
                         color: const Color(0xFF4A4A4A),
                         fontSize: 14,
                         fontFamily: 'Pretendard-Light',
                         letterSpacing: -0.32,
                       ),
                       textAlign: TextAlign.center,
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

  // 숫자 포맷팅 헬퍼 메서드 추가
  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }
}
