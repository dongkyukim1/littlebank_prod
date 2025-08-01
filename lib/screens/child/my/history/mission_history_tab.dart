import 'package:flutter/material.dart';
import '../../../../services/mission_service.dart';
import '../../chat_list_screen.dart';

class MissionHistoryTab extends StatefulWidget {
  final Function(bool isEmpty)? onEmptyStateChanged;
  
  const MissionHistoryTab({
    Key? key,
    this.onEmptyStateChanged,
  }) : super(key: key);

  @override
  State<MissionHistoryTab> createState() => _MissionHistoryTabState();
}

class _MissionHistoryTabState extends State<MissionHistoryTab> {
  bool _isMissionInProgress = true;
  
  // 미션 데이터 관련 상태
  List<MissionResponse> _missionList = [];
  List<MissionResponse> _allMissions = [];
  bool _isMissionLoading = false;
  String? _missionError;

  @override
  void initState() {
    super.initState();
    _loadMissionData();
  }

  // 미션 데이터 로드
  Future<void> _loadMissionData() async {
    setState(() {
      _isMissionLoading = true;
      _missionError = null;
      _missionList.clear();
      _allMissions.clear();
    });

    try {
      final response = await MissionService.getChildMissions(page: 0);
      
      if (response != null && response['data'] != null) {
        final List<dynamic> missionDataList = response['data'] as List<dynamic>;
        final missions = missionDataList
            .map((json) => MissionResponse.fromJson(json))
            .toList();
        
        // 현재 날짜
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        
        // 기간에 따라 필터링
        List<MissionResponse> filteredMissions;
        if (_isMissionInProgress) {
          // 진행 중: 현재 날짜가 미션 기간 내에 있는 미션들
          filteredMissions = missions.where((mission) {
            final startDate = DateTime(mission.startDate.year, mission.startDate.month, mission.startDate.day);
            final endDate = DateTime(mission.endDate.year, mission.endDate.month, mission.endDate.day);
            
            return (today.isAfter(startDate) || today.isAtSameMomentAs(startDate)) &&
                   (today.isBefore(endDate) || today.isAtSameMomentAs(endDate));
          }).toList();
        } else {
          // 완료한: 현재 날짜가 미션 종료일을 넘긴 미션들
          filteredMissions = missions.where((mission) {
            final endDate = DateTime(mission.endDate.year, mission.endDate.month, mission.endDate.day);
            return today.isAfter(endDate);
          }).toList();
        }
        
        setState(() {
          _missionList = List.from(filteredMissions);
          _allMissions = List.from(missions);
          _isMissionLoading = false;
        });
        
        // 빈 상태 변경을 부모에게 알림
        widget.onEmptyStateChanged?.call(_allMissions.isEmpty);
      } else {
        setState(() {
          _missionList = [];
          _allMissions = [];
          _isMissionLoading = false;
        });
        
        // 빈 상태 변경을 부모에게 알림
        widget.onEmptyStateChanged?.call(true);
      }
    } catch (e) {
      setState(() {
        _missionError = e.toString();
        _isMissionLoading = false;
      });
      
      // 에러 상태에서도 빈 상태로 처리
      widget.onEmptyStateChanged?.call(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 전체 데이터가 없는 경우 빈 상태 화면만 표시
    if (_allMissions.isEmpty && !_isMissionLoading && _missionError == null) {
      return SingleChildScrollView(
        padding: EdgeInsets.zero,
        child: _buildEmptyMissionState(),
      );
    }
    
    // 데이터가 있거나 로딩 중이거나 에러가 있을 때는 전체 레이아웃 표시
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
          _buildFilterSection(),
          
          const SizedBox(height: 6),
          
          // 미션 목록 섹션
          _buildMissionListSection(),
        ],
      ),
    );
  }

  // 완료한 미션 알림 섹션
  Widget _buildCompletedMissionSection() {
    final hasCompletedMission = !_isMissionInProgress && _missionList.isNotEmpty;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF3A88F4), Color(0xFF11CB86)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '최근에 완료한 미션을 피드에 자랑해 볼까요?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontFamily: 'Pretendard-Bold',
              height: 1.3,
            ),
          ),
          
          const SizedBox(height: 12),
          
          // 미션 카드
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: ShapeDecoration(
              gradient: LinearGradient(
                begin: Alignment(0.03, 0.00),
                end: Alignment(1.00, 1.00),
                colors: [
                  Colors.white.withOpacity(0.6),
                  Colors.white.withOpacity(0.3),
                ],
              ),
              shape: RoundedRectangleBorder(
                side: BorderSide(width: 0.40, color: Colors.white),
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 태그 영역
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: ShapeDecoration(
                        color: const Color(0xFFFFD27F),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(
                        '미션',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontFamily: 'Pretendard-Light',
                          letterSpacing: -0.24,
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: ShapeDecoration(
                        color: const Color(0xFF5D9EFF),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(
                        '가족 미션',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontFamily: 'Pretendard-Light',
                          letterSpacing: -0.24,
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: ShapeDecoration(
                        color: const Color(0xFF5D9EFF),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(
                        '25. 03. 25 - 03. 28',
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
                
                const SizedBox(height: 12),
                
                // 제목과 피드 작성 버튼
                SizedBox(
                  width: double.infinity,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          '이번 주 저녁 정소 담당',
                          style: TextStyle(
                            color: const Color(0xFF353535),
                            fontSize: 14,
                            fontFamily: 'Pretendard-Bold',
                            letterSpacing: -0.32,
                          ),
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '피드 작성하기',
                            style: TextStyle(
                              color: const Color(0xFF666666),
                              fontSize: 10,
                              fontFamily: 'Pretendard-Light',
                              letterSpacing: -0.24,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(
                            Icons.edit_outlined,
                            size: 16,
                            color: const Color(0xFF666666),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Divider(
                    height: 1,
                    thickness: 0.5,
                    color: Color.fromRGBO(160, 160, 160, 0.9),
                  ),
                ),
                
                // 보상금 정보
                SizedBox(
                  width: double.infinity,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        '신청한 보상금',
                        style: TextStyle(
                          color: const Color(0xFF4A4A4A),
                          fontSize: 12,
                          fontFamily: 'Pretendard-Light',
                          letterSpacing: -0.28,
                        ),
                      ),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: '25,000',
                              style: TextStyle(
                                color: const Color(0xFF146AFF),
                                fontSize: 14,
                                fontFamily: 'Pretendard-Bold',
                                letterSpacing: -0.32,
                              ),
                            ),
                            TextSpan(
                              text: '원',
                              style: TextStyle(
                                color: const Color(0xFF000000),
                                fontSize: 14,
                                fontFamily: 'Pretendard-Medium',
                                letterSpacing: -0.32,
                              ),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.end,
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

  // 필터 섹션
  Widget _buildFilterSection() {
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
            onTap: () {
              setState(() {
                _isMissionInProgress = true;
              });
              _loadMissionData();
            },
            child: Container(
              height: 36,
              width: 70,
              decoration: BoxDecoration(
                color: _isMissionInProgress ? const Color(0xFF3A88F4) : const Color(0xFFDEDEDE),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(_isMissionInProgress ? 0.15 : 0.1),
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
                  color: _isMissionInProgress ? Colors.white : const Color(0xFF999999),
                  fontSize: 12,
                  fontFamily: _isMissionInProgress ? 'Pretendard-Light' : 'Pretendard-ExtraLight',
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // 완료한 버튼
          GestureDetector(
            onTap: () {
              setState(() {
                _isMissionInProgress = false;
              });
              _loadMissionData();
            },
            child: Container(
              height: 36,
              width: 70,
              decoration: BoxDecoration(
                color: !_isMissionInProgress ? const Color(0xFF3A88F4) : const Color(0xFFDEDEDE),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(!_isMissionInProgress ? 0.15 : 0.1),
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
                  color: !_isMissionInProgress ? Colors.white : const Color(0xFF999999),
                  fontSize: 12,
                  fontFamily: !_isMissionInProgress ? 'Pretendard-Light' : 'Pretendard-ExtraLight',
                ),
              ),
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
          child: CircularProgressIndicator(
            color: Color(0xFF3A88F4),
          ),
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

    // 현재 필터에 해당하는 데이터가 없는 경우 간단한 메시지 표시
    if (_missionList.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 16),
        child: Center(
          child: Text(
            _isMissionInProgress ? '진행중인 미션이 없습니다.' : '완료한 미션이 없습니다.',
            style: TextStyle(
              color: const Color(0xFF999999),
              fontSize: 16,
              fontFamily: 'Pretendard-Medium',
              letterSpacing: -0.32,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // 실제 미션 목록 표시
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...List.generate(_missionList.length, (index) {
            final mission = _missionList[index];
            
            return Column(
              children: [
                _buildMissionItem(mission),
                if (index < _missionList.length - 1)
                  const SizedBox(height: 24),
              ],
            );
          }),
        ],
      ),
    );
  }

  // 미션이 없을 때 안내 화면
  Widget _buildEmptyMissionState() {
    return Container(
      width: double.infinity,
      height: MediaQuery.of(context).size.height - 150, // 상단 탭 높이 고려
      child: Center(
        child: Container(
          width: 390,
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width - 32, // 좌우 여백 16씩
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 이미지
              Container(
                width: 159,
                height: 108,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage("assets/icons/my/empty_mission.png"),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // 텍스트 영역
              Container(
                width: double.infinity,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 텍스트 컨테이너
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            '조회할 수 있는 미션 내역이 없습니다!',
                            style: TextStyle(
                              color: const Color(0xFF202020),
                              fontSize: 18,
                              fontFamily: 'Pretendard-Bold',
                              height: 1.50,
                              letterSpacing: -0.72,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          
                          const SizedBox(height: 12),
                          
                          Text(
                            '미션을 시작하고 보상을 받아보세요!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: const Color(0xFF999999),
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
              ),
              
              const SizedBox(height: 28),
              
              // 버튼 영역
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatListScreen(),
                    ),
                  );
                },
                child: Container(
                  width: 358,
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width - 32, // 좌우 여백 고려
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  decoration: ShapeDecoration(
                    color: const Color(0xFF146AFF),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        '채팅으로 미션 쪼르러 가기',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontFamily: 'Pretendard-Medium',
                          letterSpacing: -0.28,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 미션 아이템 위젯 (실제 API 데이터 사용)
  Widget _buildMissionItem(MissionResponse mission) {
    final String typeDisplayName = MissionService.getTypeDisplayName(mission.type);
    final String period = _formatMissionPeriod(mission);
    final String dDay = MissionService.calculateMissionDDay(mission);
    final String progressTime = _calculateMissionProgressTime(mission);
    
    return Container(
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
          // 태그 영역
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: ShapeDecoration(
                  color: const Color(0xFFFFD27F),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(
                  '미션',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontFamily: 'Pretendard-Light',
                    letterSpacing: -0.24,
                  ),
                ),
              ),
              SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: ShapeDecoration(
                  color: const Color(0xFF5D9EFF),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(
                  typeDisplayName,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontFamily: 'Pretendard-Light',
                    letterSpacing: -0.24,
                  ),
                ),
              ),
              SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: ShapeDecoration(
                  color: const Color(0xFF5D9EFF),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(
                  period,
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
          
          SizedBox(height: 12),
          
          // 제목
          Text(
            mission.title,
            style: TextStyle(
              color: const Color(0xFF353535),
              fontSize: 14,
              fontFamily: 'Pretendard-Bold',
              letterSpacing: -0.32,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          
          SizedBox(height: 12),
          
          // 정보 영역
          Row(
            children: [
              Expanded(
                child: Column(
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
                    Text(
                      dDay,
                      style: TextStyle(
                        color: const Color(0xFF5D9EFF),
                        fontSize: 14,
                        fontFamily: 'Pretendard-Bold',
                        letterSpacing: -0.32,
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
                      '진행 시간',
                      style: TextStyle(
                        color: const Color(0xFF666666),
                        fontSize: 12,
                        fontFamily: 'Pretendard-Light',
                        letterSpacing: -0.28,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      progressTime,
                      style: TextStyle(
                        color: const Color(0xFF5D9EFF),
                        fontSize: 14,
                        fontFamily: 'Pretendard-Bold',
                        letterSpacing: -0.32,
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
                      '보상금',
                      style: TextStyle(
                        color: const Color(0xFF666666),
                        fontSize: 12,
                        fontFamily: 'Pretendard-Light',
                        letterSpacing: -0.28,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      '${_formatNumber(mission.reward)}원',
                      style: TextStyle(
                        color: const Color(0xFF5D9EFF),
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
        ],
      ),
    );
  }

  // 헬퍼 메서드들
  String _formatMissionPeriod(MissionResponse mission) {
    final startYear = mission.startDate.year.toString().substring(2);
    final startMonth = mission.startDate.month.toString().padLeft(2, '0');
    final startDay = mission.startDate.day.toString().padLeft(2, '0');
    
    final endMonth = mission.endDate.month.toString().padLeft(2, '0');
    final endDay = mission.endDate.day.toString().padLeft(2, '0');
    
    if (mission.startDate.year == mission.endDate.year) {
      return '$startYear.$startMonth.$startDay - $endMonth.$endDay';
    } else {
      final endYear = mission.endDate.year.toString().substring(2);
      return '$startYear.$startMonth.$startDay - $endYear.$endMonth.$endDay';
    }
  }

  String _calculateMissionProgressTime(MissionResponse mission) {
    final now = DateTime.now();
    final startDate = mission.startDate;
    
    if (now.isAfter(startDate)) {
      final elapsedDays = now.difference(startDate).inDays + 1;
      final estimatedHours = elapsedDays * 2; // 하루 평균 2시간 가정
      final hours = estimatedHours;
      final minutes = (estimatedHours % 1 * 60).round();
      
      if (hours > 0) {
        return '${hours}시간 ${minutes}분';
      } else {
        return '${minutes}분';
      }
    } else {
      return '0시간 0분';
    }
  }

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }
} 