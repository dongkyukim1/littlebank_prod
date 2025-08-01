import 'package:flutter/material.dart';
import '../../../services/mission_service.dart';

class ParticipatingMissionsListScreen extends StatefulWidget {
  const ParticipatingMissionsListScreen({super.key});

  @override
  State<ParticipatingMissionsListScreen> createState() => _ParticipatingMissionsListScreenState();
}

class _ParticipatingMissionsListScreenState extends State<ParticipatingMissionsListScreen> {
  String selectedFilter = '전체';
  String selectedSort = '보상금이 높은 순';
  
  // API에서 가져온 미션 데이터
  List<MissionResponse> _allMissions = [];
  List<MissionResponse> missions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadParticipatingMissions();
  }

  Future<void> _loadParticipatingMissions() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final result = await MissionService.getChildMissions(page: 0);
      
      if (result != null) {
        final List<dynamic> missionData = result['data'] ?? [];
        
        // 참여중인 미션들 필터링 (ACCEPT 상태만 - 승인된 미션만 표시)
        final List<MissionResponse> acceptedMissions = missionData
            .map((json) => MissionResponse.fromJson(json))
            .where((mission) => mission.status == MissionStatus.ACCEPT)
            .toList();

        setState(() {
          _allMissions = acceptedMissions;
          missions = List.from(_allMissions);
          _isLoading = false;
        });
        
        // 초기 필터 및 정렬 적용
        _filterMissions();
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('참여중인 미션 로딩 중 오류: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // D-Day 계산
  int _calculateDDay(DateTime endDate) {
    final now = DateTime.now();
    final difference = endDate.difference(now).inDays;
    return difference < 0 ? 0 : difference;
  }

  // 미션 시작일로부터 경과일 계산
  int _calculateElapsedDays(DateTime startDate) {
    final now = DateTime.now();
    final difference = now.difference(startDate).inDays;
    return difference < 0 ? 0 : difference + 1; // 시작일도 포함하므로 +1
  }

  // 진행률 계산
  double _calculateProgress(DateTime startDate, DateTime endDate) {
    final now = DateTime.now();
    final totalDays = endDate.difference(startDate).inDays;
    final elapsedDays = now.difference(startDate).inDays;
    
    if (totalDays <= 0) return 0.0;
    if (elapsedDays <= 0) return 0.0;
    if (elapsedDays >= totalDays) return 1.0;
    
    return elapsedDays / totalDays;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF0F2F7),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          '참여 중인 미션',
          style: TextStyle(
            color: Colors.black,
            fontSize: 14,
            fontFamily: 'Pretendard-Bold',
            letterSpacing: -0.32,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 탭 필터 (전체, 가족 미션, 학원 미션)
                  Container(
                    width: screenWidth,
                    color: const Color(0xFFF0F2F7),
                    child: Row(
                      children: [
                        _buildFilterTab('전체', screenWidth / 3),
                        _buildFilterTab('가족 미션', screenWidth / 3),
                        _buildFilterTab('학원 미션', screenWidth / 3),
                      ],
                    ),
                  ),

                  // 탭과 정렬 옵션 사이 간격 추가
                  const SizedBox(height: 10),

                  // 정렬 옵션 (보상금이 높은 순, 최신순, 종료일이 가까운)
                  Container(
                    width: screenWidth,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        _buildSortOption('보상금이 높은 순'),
                        const SizedBox(width: 24),
                        _buildSortOption('최신순'),
                        const SizedBox(width: 24),
                        _buildSortOption('종료일이 가까운'),
                      ],
                    ),
                  ),

                  // 참여 중인 미션 수 표시
                  Container(
                    width: screenWidth,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        const Text(
                          '지금 내가 참여 중인 미션은',
                          style: TextStyle(
                            color: Color(0xFF202020),
                            fontSize: 16,
                            fontFamily: 'Pretendard-Bold',
                            height: 1.5,
                            letterSpacing: -0.72,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '총 ${missions.length}개',
                          style: const TextStyle(
                            color: Color(0xFF5D9EFF),
                            fontSize: 16,
                            fontFamily: 'Pretendard-Bold',
                            height: 1.5,
                            letterSpacing: -0.72,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 미션 카드 리스트
                  if (missions.isEmpty)
                    Container(
                      width: screenWidth,
                      padding: const EdgeInsets.all(48),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.assignment_outlined,
                            size: 64,
                            color: Color(0xFFCCCCCC),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            '참여 중인 미션이 없습니다',
                            style: TextStyle(
                              color: Color(0xFF666666),
                              fontSize: 16,
                              fontFamily: 'Pretendard-Regular',
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: ListView.separated(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: missions.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 30),
                        itemBuilder: (context, index) {
                          final mission = missions[index];
                          final dDay = _calculateDDay(mission.endDate);
                          final elapsedDays = _calculateElapsedDays(mission.startDate);
                          final progress = _calculateProgress(mission.startDate, mission.endDate);
                          
                          return Container(
                            width: screenWidth - 32,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.1),
                                  spreadRadius: 1,
                                  blurRadius: 5,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  MissionService.getTypeDisplayName(mission.type),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF999999),
                                    fontFamily: 'Pretendard-Regular',
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  mission.title,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Color(0xFF202020),
                                    fontFamily: 'Pretendard-Bold',
                                  ),
                                ),
                                const SizedBox(height: 12),
                                LinearProgressIndicator(
                                  value: progress,
                                  backgroundColor: const Color(0xFFE0E0E0),
                                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF5D9EFF)),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${elapsedDays}일째',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF666666),
                                        fontFamily: 'Pretendard-Regular',
                                      ),
                                    ),
                                    Text(
                                      'D-$dDay',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF666666),
                                        fontFamily: 'Pretendard-Regular',
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${mission.reward.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}원',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF5D9EFF),
                                    fontFamily: 'Pretendard-Bold',
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 28),
                ],
              ),
            ),
    );
  }

  Widget _buildFilterTab(String title, double width) {
    final isSelected = selectedFilter == title;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedFilter = title;
          _filterMissions();
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
          color: const Color(0xFFF0F2F7),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSelected ? const Color(0xFF202020) : const Color(0xFF999999),
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

  Widget _buildSortOption(String title) {
    final isSelected = selectedSort == title;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedSort = title;
          _sortMissions();
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
                color: isSelected ? const Color(0xFF5D9EFF) : const Color(0xFFB6B6B6),
                shape: const OvalBorder(),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            title,
            style: TextStyle(
              color: isSelected ? const Color(0xFF001F55) : const Color(0xFFB6B6B6),
              fontSize: 12,
              fontFamily: isSelected ? 'Pretendard-Medium' : 'Pretendard-Light',
              letterSpacing: -0.28,
            ),
          ),
        ],
      ),
    );
  }

  void _sortMissions() {
    if (selectedSort == '보상금이 높은 순') {
      missions.sort((a, b) => b.reward.compareTo(a.reward));
    } else if (selectedSort == '최신순') {
      missions.sort((a, b) => b.startDate.compareTo(a.startDate));
    } else if (selectedSort == '종료일이 가까운') {
      missions.sort((a, b) => a.endDate.compareTo(b.endDate));
    }
  }

  void _filterMissions() {
    setState(() {
      // 선택된 필터에 따라 미션 필터링
      if (selectedFilter == '전체') {
        missions = List.from(_allMissions);
      } else if (selectedFilter == '가족 미션') {
        missions = _allMissions.where((mission) => mission.type == MissionType.FAMILY).toList();
      } else if (selectedFilter == '학원 미션') {
        missions = _allMissions.where((mission) => mission.type == MissionType.ACADEMY).toList();
      }
      
      // 필터링 후 정렬 적용
      _sortMissions();
    });
  }
} 