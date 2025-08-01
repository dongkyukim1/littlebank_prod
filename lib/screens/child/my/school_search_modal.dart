import 'package:flutter/material.dart';
import '../../../services/school_service.dart';
import '../../../services/auth_service.dart';

class SchoolSearchModal extends StatefulWidget {
  final Function(Map<String, dynamic>) onSchoolSelected;
  final Map<String, dynamic>? userInfo;

  const SchoolSearchModal({
    super.key,
    required this.onSchoolSelected,
    this.userInfo,
  });

  @override
  State<SchoolSearchModal> createState() => _SchoolSearchModalState();
}

class _SchoolSearchModalState extends State<SchoolSearchModal> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  bool _showOnlyMySchoolType = false; // 나에게 해당하는 정보만 보기

  // 선택된 학교들을 관리하는 Set
  Set<String> _selectedSchools = <String>{};

  // 사용자 정보 저장
  Map<String, dynamic>? _currentUserInfo;

  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // 사용자 정보 로드
    _loadUserInfo();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  // 사용자 정보 로드
  Future<void> _loadUserInfo() async {
    try {
      final userInfo = await AuthService.getUserInfo();
      setState(() {
        _currentUserInfo = userInfo;
      });
      print('📍 사용자 정보 로드 완료: ${userInfo['birthDate']}');
    } catch (e) {
      print('📍 사용자 정보 로드 실패: $e');
      // 전달받은 userInfo 사용
      _currentUserInfo = widget.userInfo;
    }
  }

  // 주소를 도, 시, 번길까지만 포맷팅하는 함수
  String _formatAddress(String? address) {
    return SchoolService.formatAddress(address);
  }

  // 생년월일을 기반으로 현재 나이 계산 (YYMMDD 형태 지원)
  int _calculateAge(String? birthDate) {
    if (birthDate == null || birthDate.isEmpty) return 0;

    try {
      DateTime birth;

      // YYMMDD 형태인 경우 (6자리)
      if (birthDate.length == 6) {
        final yearStr = birthDate.substring(0, 2);
        final monthStr = birthDate.substring(2, 4);
        final dayStr = birthDate.substring(4, 6);

        // 앞 2자리를 연도로 변환 (00-30은 2000년대, 31-99는 1900년대로 가정)
        int year = int.parse(yearStr);
        if (year <= 30) {
          year += 2000;
        } else {
          year += 1900;
        }

        final month = int.parse(monthStr);
        final day = int.parse(dayStr);

        birth = DateTime(year, month, day);
        print('📍 YYMMDD 형태 파싱: $birthDate → $year-$month-$day');
      }
      // 기존 ISO 형태인 경우
      else {
        birth = DateTime.parse(birthDate);
      }

      final today = DateTime.now();
      int age = today.year - birth.year;

      // 생일이 지나지 않았으면 나이에서 1을 뺌
      if (today.month < birth.month ||
          (today.month == birth.month && today.day < birth.day)) {
        age--;
      }

      print('📍 나이 계산 결과: 생년월일=${birth.toString().substring(0, 10)}, 만나이=$age');
      return age;
    } catch (e) {
      print('생년월일 파싱 오류: $e');
      return 0;
    }
  }

  // 나이에 따른 적절한 학교 유형 반환 (2025년 기준)
  String? _getSchoolTypeByAge(int age) {
    // 2025년 기준 학교 분류
    if (age >= 6 && age <= 11) {
      return '초등학교'; // 초등학교: 만 6-11세
    } else if (age >= 12 && age <= 14) {
      return '중학교'; // 중학교: 만 12-14세
    } else if (age >= 15 && age <= 17) {
      return '고등학교'; // 고등학교: 만 15-17세
    }
    return null; // 나이가 학교 범위에 맞지 않음
  }

  // 학교 검색 함수
  Future<void> _searchSchools() async {
    final searchKeyword = _searchController.text.trim();
    
    print('📍 _searchSchools 호출됨: "$searchKeyword" (길이: ${searchKeyword.length})');
    
    if (searchKeyword.length < 2) {
      print('📍 검색어가 2글자 미만이라 검색 중단');
      setState(() {
        _searchResults = [];
        _isLoading = false;
        _errorMessage = null;
      });
      return;
    }

    print('📍 검색 조건 통과, API 호출 시작');
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print('📍 SchoolService.searchSchools 호출 전');
      // 새로운 API로 학교 검색
      final result = await SchoolService.searchSchools(
        schoolName: searchKeyword,
      );
      print('📍 SchoolService.searchSchools 호출 완료: $result');

      List<Map<String, dynamic>> schools = [];
      
      if (result['success']) {
        schools = result['schools'] as List<Map<String, dynamic>>;
        print('📍 검색 결과: ${schools.length}개 학교 발견');

        // 나이 기반 필터링 적용
        if (_showOnlyMySchoolType && _currentUserInfo != null) {
          final birthDate = _currentUserInfo!['birthDate'] ?? _currentUserInfo!['rrn'];
          final age = _calculateAge(birthDate);
          final ageBasedSchoolType = _getSchoolTypeByAge(age);

          if (ageBasedSchoolType != null) {
            final originalCount = schools.length;
            schools = schools.where((school) {
              final schoolName = school['schoolName']?.toString() ?? '';
              
              bool matches = false;
              switch (ageBasedSchoolType) {
                case '초등학교':
                  matches = schoolName.contains('초등학교');
                  break;
                case '중학교':
                  matches = schoolName.contains('중학교');
                  break;
                case '고등학교':
                  matches = schoolName.contains('고등학교');
                  break;
                default:
                  matches = true;
              }

              if (matches) {
                print('📍 필터 통과: ${school['schoolName']}');
              }

              return matches;
            }).toList();
            print('📍 나이 기반 필터링 후: $originalCount개 → ${schools.length}개 학교');
          }
        }
      } else {
        _errorMessage = result['error'] ?? '학교 검색에 실패했습니다.';
        print('📍 검색 실패: $_errorMessage');
      }

      if (mounted) {
        setState(() {
          _searchResults = schools;
          _isLoading = false;
        });
      }
      print('📍 UI 업데이트 완료: ${schools.length}개 학교');
    } catch (e) {
      print('📍 검색 오류: $e');
      if (mounted) {
        setState(() {
          _errorMessage = '학교 검색 중 오류가 발생했습니다.';
          _isLoading = false;
          _searchResults = [];
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom; // 키보드 높이
    final hasSearchResults = _searchController.text.trim().isNotEmpty;

    // 바텀시트 높이를 항상 최대 높이로 고정
    double bottomSheetHeight;

    // 최대 높이 계산 (키보드가 올라온 경우 고려)
    final maxHeight = keyboardHeight > 0
        ? screenHeight - keyboardHeight - 100 // 키보드가 있을 때는 여유 공간 더 많이
        : screenHeight * 0.70; // 기본 최대 높이

    // 항상 최대 높이로 설정
    bottomSheetHeight = maxHeight;

    return Padding(
      padding: EdgeInsets.only(bottom: keyboardHeight), // 키보드 높이만큼 패딩 추가
      child: Container(
        height: bottomSheetHeight,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 헤더 섹션
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
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
                  // 제목과 닫기 버튼
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '내가 다니는 학교 이름을 검색해 주세요',
                          style: TextStyle(
                            color: const Color(0xFF202020),
                            fontSize: 16,
                            fontFamily: 'Pretendard-Bold',
                            letterSpacing: -0.72,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          width: 24,
                          height: 24,
                          child: const Icon(
                            Icons.close,
                            size: 20,
                            color: Color(0xFF999999),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // 서브 제목
                  Text(
                    '키워드 입력 시, 해당하는 학교 리스트를 제공해 드릴게요',
                    style: TextStyle(
                      color: const Color(0xFF999999),
                      fontSize: 12,
                      fontFamily: 'Pretendard-Light',
                      letterSpacing: -0.28,
                    ),
                  ),
                ],
              ),
            ),

            // 검색 입력창 섹션
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: const BoxDecoration(color: Colors.white),
              child: Container(
                width: double.infinity,
                height: 40,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: ShapeDecoration(
                  color: hasSearchResults ? Colors.white : const Color(0xFFF0F0F0),
                  shape: RoundedRectangleBorder(
                    side: BorderSide(
                      width: hasSearchResults ? 1.40 : 0.80,
                      color: hasSearchResults
                          ? const Color(0xFF3A88F4)
                          : const Color(0xFFDADADA),
                    ),
                    borderRadius: BorderRadius.circular(32),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 검색 아이콘
                    Container(
                      width: 20,
                      height: 20,
                      child: Image.asset(
                        'assets/icons/my/검색.png',
                        width: 18,
                        height: 18,
                        color: Color(0xFF999999),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // 검색 입력창
                    Expanded(
                      child: Container(
                        height: 28,
                        alignment: Alignment.center,
                        child: TextField(
                          controller: _searchController,
                          focusNode: _searchFocusNode,
                          textAlignVertical: TextAlignVertical.center,
                          onChanged: (value) {
                            print('📍 TextField onChanged: "$value" (길이: ${value.length}, 트림 길이: ${value.trim().length})');
                            setState(() {}); // UI 업데이트를 위해
                            if (value.trim().length >= 2 || value.trim().isEmpty) {
                              print('📍 검색 조건 만족, _searchSchools() 호출');
                              _searchSchools();
                            } else {
                              print('📍 검색 조건 불만족 (2글자 미만)');
                            }
                          },
                          style: const TextStyle(
                            color: Color(0xFF353535),
                            fontSize: 12,
                            fontFamily: 'Pretendard-Light',
                            letterSpacing: -0.24,
                            height: 1.0,
                          ),
                          decoration: InputDecoration(
                            hintText: '찾고싶은 학교를 검색해 주세요',
                            hintStyle: const TextStyle(
                              color: Color(0xFF999999),
                              fontSize: 12,
                              fontFamily: 'Pretendard-Light',
                              letterSpacing: -0.24,
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                            fillColor: hasSearchResults
                                ? Colors.white
                                : const Color(0xFFF0F0F0),
                            filled: true,
                            isDense: true,
                          ),
                        ),
                      ),
                    ),
                    // 지우기 버튼
                    if (_searchController.text.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          setState(() {});
                          _searchSchools();
                        },
                        child: Container(
                          width: 20,
                          height: 20,
                          child: Image.asset(
                            'assets/icons/my/삭제.png',
                            width: 18,
                            height: 18,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // 검색 결과가 있을 때만 나이 기반 필터 표시
            if (hasSearchResults && !_isLoading) ...[
              // 나에게 해당하는 정보만 보기 체크박스
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: const BoxDecoration(color: Colors.white),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _showOnlyMySchoolType = !_showOnlyMySchoolType;
                    });
                    _searchSchools();
                  },
                  child: Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        child: Image.asset(
                          _showOnlyMySchoolType
                              ? 'assets/icons/my/check_blue.png'
                              : 'assets/icons/my/check_subs.png',
                          width: 20,
                          height: 20,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '나에게 해당하는 정보만 보기',
                        style: TextStyle(
                          color: const Color(0xFF4A4A4A),
                          fontSize: 12,
                          fontFamily: 'Pretendard-Light',
                          letterSpacing: -0.28,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // 컨텐츠 영역
            Expanded(
              child: Container(
                color: Colors.white,
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF3A88F4),
                        ),
                      )
                    : _errorMessage != null
                        ? Center(
                            child: Text(
                              '오류가 발생했습니다: $_errorMessage',
                              style: const TextStyle(
                                color: Color(0xFF999999),
                                fontSize: 14,
                                fontFamily: 'Pretendard-Regular',
                              ),
                            ),
                          )
                        : hasSearchResults
                            ? _buildSearchResults()
                            : Container(), // 검색 전에는 빈 공간
              ),
            ),

            // 등록하기 버튼 (항상 표시)
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Container(
                width: double.infinity,
                height: 45,
                decoration: ShapeDecoration(
                  color: _selectedSchools.isNotEmpty
                      ? const Color(0xFF146AFF)
                      : const Color(0xFFCCCCCC),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: GestureDetector(
                  onTap: _selectedSchools.isNotEmpty
                      ? () async {
                          // 선택된 학교들을 등록 처리
                          final firstSelectedSchool = _searchResults.firstWhere(
                            (school) {
                              final schoolKey =
                                  '${school['schoolName']}_${school['address']}';
                              return _selectedSchools.contains(schoolKey);
                            },
                            orElse: () => _searchResults.isNotEmpty
                                ? _searchResults.first
                                : {},
                          );

                          if (firstSelectedSchool.isNotEmpty) {
                            try {
                              // 로딩 표시
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (context) => const Center(
                                  child: CircularProgressIndicator(
                                    color: Color(0xFF3A88F4),
                                  ),
                                ),
                              );

                              // 학교 정보 저장 API 호출
                              final schoolName = firstSelectedSchool['schoolName']?.toString() ?? '';
                              final address = firstSelectedSchool['address']?.toString() ?? '';
                              
                              // 학교 타입 변환
                              final schoolType = SchoolService.convertSchoolTypeToApi(schoolName);
                              
                              // 지역 코드 변환
                              final region = SchoolService.convertRegionToCode(address);

                              final result = await SchoolService.saveSchoolInfo(
                                schoolName: schoolName,
                                schoolType: schoolType,
                                region: region,
                                address: address,
                              );

                              // 로딩 닫기
                              Navigator.of(context).pop();

                              // 성공 처리 - 학교 정보 전달하되 이미 저장되었다는 플래그 추가
                              final schoolWithFlag = Map<String, dynamic>.from(firstSelectedSchool);
                              schoolWithFlag['_alreadySaved'] = true; // 이미 저장되었다는 플래그
                              
                              widget.onSchoolSelected(schoolWithFlag);
                              Navigator.of(context).pop();

                              // 성공 메시지 표시
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('학교 정보가 성공적으로 저장되었습니다.'),
                                    backgroundColor: Color(0xFF3A88F4),
                                  ),
                                );
                              }
                            } catch (e) {
                              // 로딩 닫기
                              Navigator.of(context).pop();
                              
                              // 에러 처리
                              print('학교 정보 저장 실패: $e');
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('학교 정보 저장에 실패했습니다: ${e.toString().replaceAll('Exception: ', '')}'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          }
                        }
                      : null,
                  child: Center(
                    child: Text(
                      '등록하기',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.24,
                      ),
                      textAlign: TextAlign.center,
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

  // 검색 결과 빌드 메서드
  Widget _buildSearchResults() {
    if (_searchResults.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Text(
            '검색 결과가 없습니다.',
            style: TextStyle(
              color: const Color(0xFF999999),
              fontSize: 14,
              fontFamily: 'Pretendard-Regular',
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        // 결과 개수 표시
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 14,
          ),
          decoration: const BoxDecoration(color: Colors.white),
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '총 ${_searchResults.length}개',
                  style: TextStyle(
                    color: const Color(0xFF3A88F4),
                    fontSize: 18,
                    fontFamily: 'Pretendard-Bold',
                    letterSpacing: -0.72,
                  ),
                ),
                TextSpan(
                  text: '의 결과가 있어요',
                  style: TextStyle(
                    color: const Color(0xFF202020),
                    fontSize: 18,
                    fontFamily: 'Pretendard-Bold',
                    letterSpacing: -0.72,
                  ),
                ),
              ],
            ),
          ),
        ),

        // 학교 목록
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            itemCount: _searchResults.length,
            itemBuilder: (context, index) {
              final school = _searchResults[index];
              return _buildSchoolCard(school);
            },
          ),
        ),
      ],
    );
  }

  // 학교 카드 위젯
  Widget _buildSchoolCard(Map<String, dynamic> school) {
    final schoolKey = '${school['schoolName']}_${school['address']}';
    final isSelected = _selectedSchools.contains(schoolKey);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 0,
        vertical: 6,
      ),
      decoration: const BoxDecoration(color: Colors.white),
      child: Container(
        height: 54,
        child: Stack(
          children: [
            // 메인 컨텐츠 (학교명 + 위치 정보)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                // 학교명
                Padding(
                  padding: const EdgeInsets.only(right: 40), // 버튼 공간 확보
                  child: Text(
                    school['schoolName']?.toString() ?? '학교명 없음',
                    style: TextStyle(
                      color: const Color(0xFF202020),
                      fontSize: 18,
                      fontFamily: 'Pretendard-Bold',
                      letterSpacing: -0.72,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                const SizedBox(height: 4),
                // 위치 정보
                Row(
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      child: Image.asset(
                        'assets/icons/my/location.png',
                        width: 16,
                        height: 16,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '위치',
                      style: TextStyle(
                        color: const Color(0xFF8490A3),
                        fontSize: 12,
                        fontFamily: 'Pretendard-Light',
                        letterSpacing: -0.24,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _formatAddress(school['address']?.toString()) ?? '주소 정보 없음',
                        style: TextStyle(
                          color: const Color(0xFF4A4A4A),
                          fontSize: 12,
                          fontFamily: 'Pretendard-Light',
                          letterSpacing: -0.24,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // 체크박스 아이콘
            Positioned(
              top: 12,
              right: 0,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedSchools.remove(schoolKey);
                    } else {
                      _selectedSchools.add(schoolKey);
                    }
                  });
                },
                child: Container(
                  width: 24,
                  height: 24,
                  child: Image.asset(
                    isSelected
                        ? 'assets/icons/my/등록하기_fill.png'
                        : 'assets/icons/my/등록하기_sub.png',
                    width: 24,
                    height: 24,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
