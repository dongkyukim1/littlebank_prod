import 'package:flutter/material.dart';
import '../mission/mission_creation_screen.dart';
import '../../../services/family_service.dart';
import '../../../services/auth_service.dart';
import 'package:cached_network_image/cached_network_image.dart';

class WeeklyGoalSection extends StatelessWidget {
  final Function() showMissionCreationModal;

  const WeeklyGoalSection({super.key, required this.showMissionCreationModal});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더 (제목 + 더보기 버튼)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '이번 주 미션',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF202020),
                ),
              ),
              GestureDetector(
                onTap: () {
                  // 더보기 액션
                },
                child: Row(
                  children: [
                    Text(
                      '더보기',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 12,
                      color: Colors.grey[600],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 미션 생성 버튼
          GestureDetector(
            onTap: showMissionCreationModal,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF146AFF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text(
                  '미션 생성하기',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 미션 진행 상황 표시
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFE7ECF6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '자녀의 성장을 위한 미션을 만들어 보세요!',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF202020),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '아직 자녀에게 부여된 미션이 없습니다.',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MissionCreationModal extends StatefulWidget {
  const MissionCreationModal({super.key});

  @override
  State<MissionCreationModal> createState() => _MissionCreationModalState();
}

class _MissionCreationModalState extends State<MissionCreationModal> {
  String? _selectedMissionType;
  int _currentStep = 0;
  final Set<Map<String, dynamic>> _selectedChildrenData = {};
  List<dynamic> _familyChildren = [];
  bool _isLoadingChildren = false;
  String? _selectedMissionCategory;
  String? _selectedSubject;

  @override
  void initState() {
    super.initState();
    if (_currentStep == 1) {
      _loadFamilyChildren();
    }
  }

  Future<void> _loadFamilyChildren() async {
    setState(() {
      _isLoadingChildren = true;
    });
    try {
      final familyInfo = await FamilyService.getFamilyInfo();
      if (familyInfo != null && familyInfo['memberInfoList'] != null) {
        setState(() {
          _familyChildren =
              (familyInfo['memberInfoList'] as List)
                  .where((member) => member['role'] == 'CHILD')
                  .toList();
          _isLoadingChildren = false;
        });
      } else {
        setState(() {
          _familyChildren = [];
          _isLoadingChildren = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('가족 정보를 불러오지 못했습니다.')));
      }
    } catch (e) {
      setState(() {
        _familyChildren = [];
        _isLoadingChildren = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('가족 정보 로드 중 오류: $e')));
    }
  }

  void _proceedToNextStep() {
    if (_currentStep == 0) {
      if (_selectedMissionType != null) {
        setState(() {
          _currentStep = 1;
          _loadFamilyChildren();
        });
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('미션 유형을 선택해주세요')));
      }
    } else if (_currentStep == 1) {
      if (_selectedChildrenData.isNotEmpty) {
        setState(() {
          _currentStep = 2;
        });
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('미션 대상자를 선택해주세요')));
      }
    } else if (_currentStep == 2) {
      if (_selectedMissionCategory != null) {
        if (_selectedMissionCategory == 'LEARNING') {
          setState(() {
            _currentStep = 3;
          });
        } else {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => MissionCreationScreen(
                    selectedChildrenData: _selectedChildrenData.toList(),
                    missionType: _selectedMissionType!,
                    missionCategory: _selectedMissionCategory,
                  ),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('미션 카테고리를 선택해주세요.')));
      }
    } else if (_currentStep == 3) {
      if (_selectedSubject != null) {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => MissionCreationScreen(
                  selectedChildrenData: _selectedChildrenData.toList(),
                  missionType: _selectedMissionType!,
                  missionCategory: _selectedMissionCategory,
                  missionSubject: _selectedSubject,
                ),
          ),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('미션 과목을 선택해주세요.')));
      }
    }
  }

  void _goBack() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    // 단계별로 다른 높이 적용
    double modalHeight;
    if (_currentStep == 1) {
      // 자녀 선택 - 더 작게
      modalHeight = screenWidth * 0.75;
    } else if (_currentStep == 2) {
      // 카테고리 선택 - 더 크게
      modalHeight = screenWidth * 0.88;
    } else if (_currentStep == 3) {
      // 과목 선택 - 적당한 크기
      modalHeight = screenWidth * 0.8;
    } else {
      // 미션 타입 선택 - 기본 크기
      modalHeight = screenWidth * 0.85;
    }

    return Container(
      height: modalHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child:
          _currentStep == 0
              ? _buildMissionTypeSelection(context)
              : _currentStep == 1
              ? _buildMissionTargetSelection()
              : _currentStep == 2
              ? _buildMissionCategorySelection()
              : _buildMissionSubjectSelection(),
    );
  }

  Widget _buildMissionTypeSelection(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '어떤 미션을 만들어 볼까요? ',
                        style: TextStyle(
                          color: const Color(0xFF202020),
                          fontSize: 18,
                          fontFamily: 'Pretendard',
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.72,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Icon(Icons.close, color: Colors.grey, size: 24),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '인원 수에 따라 미션 전송 유형을 선택할 수 있어요',
                  style: TextStyle(
                    color: const Color(0xFF999999),
                    fontSize: 13,
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w300,
                    letterSpacing: -0.28,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedMissionType = '개인';
                        });
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color:
                              _selectedMissionType == '개인'
                                  ? const Color(0xFFFFD27F)
                                  : const Color(0xFFE4EDF8),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            width: 0.70,
                            color:
                                _selectedMissionType == '개인'
                                    ? const Color(0xFFFFA63D)
                                    : const Color(0xFFDADADA),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '개인 미션',
                                    style: TextStyle(
                                      color: const Color(0xFF202020),
                                      fontSize: 15,
                                      fontFamily: 'Pretendard',
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.32,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    '상대와 나의 개인 채팅창을 통해 미션을 전송할 수 있어요!',
                                    style: TextStyle(
                                      color: const Color(0xFF666666),
                                      fontSize: 11,
                                      fontFamily: 'Pretendard',
                                      fontWeight: FontWeight.w300,
                                      letterSpacing: -0.24,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(width: 8),

                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color:
                                    _selectedMissionType == '개인'
                                        ? const Color(0xFFFFD27F)
                                        : Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  width: 0.75,
                                  color:
                                      _selectedMissionType == '개인'
                                          ? const Color(0xFFFFA63D)
                                          : const Color(0xFFDADADA),
                                ),
                              ),
                              child:
                                  _selectedMissionType == '개인'
                                      ? Center(
                                        child: Container(
                                          width: 12,
                                          height: 12,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFFA63D),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      )
                                      : null,
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 12),

                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedMissionType = '그룹';
                        });
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color:
                              _selectedMissionType == '그룹'
                                  ? const Color(0xFFFFD27F)
                                  : const Color(0xFFE4EDF8),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            width: 0.70,
                            color:
                                _selectedMissionType == '그룹'
                                    ? const Color(0xFFFFA63D)
                                    : const Color(0xFFDADADA),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '그룹 미션',
                                    style: TextStyle(
                                      color: const Color(0xFF202020),
                                      fontSize: 15,
                                      fontFamily: 'Pretendard',
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.32,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    '여러 명에게 한 번에 빠르게 미션을 전송할 수 있어요!',
                                    style: TextStyle(
                                      color: const Color(0xFF999999),
                                      fontSize: 11,
                                      fontFamily: 'Pretendard',
                                      fontWeight: FontWeight.w300,
                                      letterSpacing: -0.24,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(width: 8),

                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color:
                                    _selectedMissionType == '그룹'
                                        ? const Color(0xFFFFD27F)
                                        : Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  width: 0.75,
                                  color:
                                      _selectedMissionType == '그룹'
                                          ? const Color(0xFFFFA63D)
                                          : const Color(0xFFDADADA),
                                ),
                              ),
                              child:
                                  _selectedMissionType == '그룹'
                                      ? Center(
                                        child: Container(
                                          width: 12,
                                          height: 12,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFFA63D),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      )
                                      : null,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      margin: EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDDDDDD),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '다음에 하기',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontFamily: 'Pretendard',
                            fontWeight: FontWeight.w300,
                            letterSpacing: -0.28,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                Expanded(
                  child: GestureDetector(
                    onTap: _proceedToNextStep,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF5D9EFF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '완료',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontFamily: 'Pretendard',
                            fontWeight: FontWeight.w300,
                            letterSpacing: -0.28,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissionTargetSelection() {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            width: double.infinity,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '누구에게 미션을 전송할까요?',
                        style: TextStyle(
                          color: const Color(0xFF202020),
                          fontSize: 17,
                          fontFamily: 'Pretendard-Bold',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '가족 멤버로 추가된 아이들이예요',
                        style: TextStyle(
                          color: const Color(0xFF999999),
                          fontSize: 12,
                          fontFamily: 'Pretendard-Light',
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: _goBack,
                  child: Icon(Icons.close, color: Colors.grey, size: 22),
                ),
              ],
            ),
          ),
          Flexible(
            child:
                _isLoadingChildren
                    ? Center(child: CircularProgressIndicator())
                    : _familyChildren.isEmpty
                    ? Center(child: Text('표시할 자녀가 없습니다.'))
                    : SingleChildScrollView(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 4,
                        ),
                        child: GridView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 4,
                                crossAxisSpacing: 2,
                                mainAxisSpacing: 2,
                                childAspectRatio: 0.85,
                              ),
                          itemCount: _familyChildren.length,
                          itemBuilder: (context, index) {
                            final child = _familyChildren[index];
                            return _buildChildProfile(
                              child,
                              _selectedChildrenData.any(
                                (selected) =>
                                    selected['familyMemberId'] ==
                                    child['familyMemberId'],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      margin: EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDDDDDD),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '다음에 하기',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontFamily: 'Pretendard-Regular',
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: _proceedToNextStep,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF5D9EFF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '완료',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontFamily: 'Pretendard-Regular',
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChildProfile(Map<String, dynamic> childData, bool isSelected) {
    final String name = childData['nickname'] ?? childData['realName'] ?? '자녀';
    final String? profileImagePath = childData['profileImagePath'];

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedChildrenData.removeWhere(
              (selected) =>
                  selected['familyMemberId'] == childData['familyMemberId'],
            );
          } else {
            if (_selectedMissionType == '개인' &&
                _selectedChildrenData.isNotEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('개인 미션은 한 명의 대상자만 선택할 수 있습니다.')),
              );
              return;
            }
            _selectedChildrenData.add(childData);
          }
        });
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 2,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: Stack(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey[300],
                  ),
                  child: ClipOval(
                    child:
                        profileImagePath != null && profileImagePath.isNotEmpty
                            ? CachedNetworkImage(
                              imageUrl: AuthService.getFullProfileImageUrl(
                                profileImagePath,
                              ),
                              width: 54,
                              height: 54,
                              fit: BoxFit.cover,
                              placeholder:
                                  (context, url) => Container(
                                    width: 54,
                                    height: 54,
                                    color: Colors.grey[300],
                                    child: Icon(
                                      Icons.person,
                                      size: 30,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                              errorWidget:
                                  (context, url, error) => Container(
                                    width: 54,
                                    height: 54,
                                    color: Colors.grey[300],
                                    child: Icon(
                                      Icons.person,
                                      size: 30,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                            )
                            : Container(
                              width: 54,
                              height: 54,
                              color: Colors.grey[300],
                              child: Icon(
                                Icons.person,
                                size: 30,
                                color: Colors.grey[500],
                              ),
                            ),
                  ),
                ),
                if (!isSelected)
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withOpacity(0.4),
                    ),
                  ),
                if (isSelected)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                      child: Image.asset(
                        'assets/icons/parent/mission/check.png',
                        width: 20,
                        height: 20,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 54, // 프로필 사진과 동일한 너비
            child: Text(
              name,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black,
                fontSize: 12,
                fontFamily: 'Pretendard-Regular',
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissionCategorySelection() {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            width: double.infinity,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedMissionType == '개인'
                            ? '개인 미션 - 카테고리 선택'
                            : '그룹 미션 - 카테고리 선택',
                        style: TextStyle(
                          color: const Color(0xFF202020),
                          fontSize: 17,
                          fontFamily: 'Pretendard-Bold',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '어떤 종류의 미션을 만들어 볼까요?',
                        style: TextStyle(
                          color: const Color(0xFF999999),
                          fontSize: 12,
                          fontFamily: 'Pretendard-Light',
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: _goBack,
                  child: Icon(Icons.close, color: Colors.grey, size: 22),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                children: [
                  _buildCategoryCard(
                    title: '학습 인증 미션',
                    subtitle: '학습 관련 미션을 통해 학습 동기부여를 제공할 수 있어요!',
                    categoryValue: 'LEARNING',
                  ),
                  const SizedBox(height: 16),
                  _buildCategoryCard(
                    title: '습관 형성 미션',
                    subtitle: '일상 생활 습관을 기르는 미션을 만들 수 있어요!',
                    categoryValue: 'HABIT',
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _goBack,
                    child: Container(
                      margin: EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDDDDDD),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '이전',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontFamily: 'Pretendard-Regular',
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      if (_selectedMissionCategory != null) {
                        _proceedToNextStep();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('미션 카테고리를 선택해주세요.')),
                        );
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF5D9EFF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          _selectedMissionCategory == 'LEARNING'
                              ? '과목 선택하기'
                              : '완료',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontFamily: 'Pretendard-Regular',
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard({
    required String title,
    required String subtitle,
    required String categoryValue,
  }) {
    bool isSelected = _selectedMissionCategory == categoryValue;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMissionCategory = categoryValue;
        });
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFD27F) : const Color(0xFFE4EDF8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            width: 0.70,
            color:
                isSelected ? const Color(0xFFFFA63D) : const Color(0xFFDADADA),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: const Color(0xFF202020),
                      fontSize: 15,
                      fontFamily: 'Pretendard-Bold',
                      letterSpacing: -0.32,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color:
                          isSelected
                              ? const Color(0xFF202020)
                              : const Color(0xFF666666),
                      fontSize: 11,
                      fontFamily: 'Pretendard-Light',
                      letterSpacing: -0.24,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            SizedBox(width: 8),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFFFD27F) : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  width: 0.75,
                  color:
                      isSelected
                          ? const Color(0xFFFFA63D)
                          : const Color(0xFFDADADA),
                ),
              ),
              child:
                  isSelected
                      ? Center(
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFA63D),
                            shape: BoxShape.circle,
                          ),
                        ),
                      )
                      : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMissionSubjectSelection() {
    final List<String> subjectsLine1 = ['국어', '수학', '영어'];
    final List<String> subjectsLine2 = ['사회', '과학'];
    final double buttonWidth =
        (MediaQuery.of(context).size.width - 40 - 20) / 3;

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            width: double.infinity,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '미션 과목을 선택해 주세요',
                        style: TextStyle(
                          color: const Color(0xFF202020),
                          fontSize: 17,
                          fontFamily: 'Pretendard-Bold',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '아이가 학습할 과목을 선택해 주세요',
                        style: TextStyle(
                          color: const Color(0xFF999999),
                          fontSize: 12,
                          fontFamily: 'Pretendard-Light',
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: _goBack,
                  child: Icon(Icons.close, color: Colors.grey, size: 22),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 첫 번째 줄: 국어, 수학, 영어
                  Align(
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width * 0.85,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                      // 국어 버튼
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedSubject = '국어';
                            });
                          },
                          child: Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
                              decoration: ShapeDecoration(
                                color: _selectedSubject == '국어' 
                                  ? const Color(0xFFFFD27F)
                                  : const Color(0xFFF0F0F0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(36),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  '국어',
                                  style: TextStyle(
                                    color: _selectedSubject == '국어' 
                                        ? const Color(0xFFFFA63D)
                                        : const Color(0xFF999999),
                                    fontSize: 12,
                                    fontFamily: 'Pretendard-Light',
                                    letterSpacing: -0.24,
                                  ),
                                ),
                                if (_selectedSubject == '국어') ...[
                                  SizedBox(width: 4),
                                  Image.asset(
                                    'assets/icons/parent/mission/check_Fill.png',
                                    width: 16,
                                    height: 16,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      // 수학 버튼
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedSubject = '수학';
                            });
                          },
                                                     child: Container(
                             padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
                             decoration: ShapeDecoration(
                               color: _selectedSubject == '수학' 
                                   ? const Color(0xFFFFD27F)
                                   : const Color(0xFFF0F0F0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(36),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  '수학',
                                  style: TextStyle(
                                    color: _selectedSubject == '수학' 
                                        ? const Color(0xFFFFA63D)
                                        : const Color(0xFF999999),
                                    fontSize: 12,
                                    fontFamily: 'Pretendard-Light',
                                    letterSpacing: -0.24,
                                  ),
                                ),
                                if (_selectedSubject == '수학') ...[
                                  SizedBox(width: 4),
                                  Image.asset(
                                    'assets/icons/parent/mission/check_Fill.png',
                                    width: 16,
                                    height: 16,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      // 영어 버튼
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedSubject = '영어';
                            });
                          },
                                                     child: Container(
                             padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
                             decoration: ShapeDecoration(
                               color: _selectedSubject == '영어' 
                                   ? const Color(0xFFFFD27F)
                                   : const Color(0xFFF0F0F0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(36),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  '영어',
                                  style: TextStyle(
                                    color: _selectedSubject == '영어' 
                                        ? const Color(0xFFFFA63D)
                                        : const Color(0xFF999999),
                                    fontSize: 12,
                                    fontFamily: 'Pretendard-Light',
                                    letterSpacing: -0.24,
                                  ),
                                ),
                                if (_selectedSubject == '영어') ...[
                                  SizedBox(width: 4),
                                  Image.asset(
                                    'assets/icons/parent/mission/check_Fill.png',
                                    width: 16,
                                    height: 16,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  // 두 번째 줄: 사회, 과학
                  Align(
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width * 0.85,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                      // 사회 버튼
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedSubject = '사회';
                            });
                          },
                                                     child: Container(
                             padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
                             decoration: ShapeDecoration(
                               color: _selectedSubject == '사회' 
                                   ? const Color(0xFFFFD27F)
                                   : const Color(0xFFF0F0F0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(36),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  '사회',
                                  style: TextStyle(
                                    color: _selectedSubject == '사회' 
                                        ? const Color(0xFFFFA63D)
                                        : const Color(0xFF999999),
                                    fontSize: 12,
                                    fontFamily: 'Pretendard-Light',
                                    letterSpacing: -0.24,
                                  ),
                                ),
                                if (_selectedSubject == '사회') ...[
                                  SizedBox(width: 4),
                                  Image.asset(
                                    'assets/icons/parent/mission/check_Fill.png',
                                    width: 16,
                                    height: 16,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      // 과학 버튼
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedSubject = '과학';
                            });
                          },
                                                     child: Container(
                             padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
                             decoration: ShapeDecoration(
                               color: _selectedSubject == '과학' 
                                   ? const Color(0xFFFFD27F)
                                   : const Color(0xFFF0F0F0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(36),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  '과학',
                                  style: TextStyle(
                                    color: _selectedSubject == '과학' 
                                        ? const Color(0xFFFFA63D)
                                        : const Color(0xFF999999),
                                    fontSize: 12,
                                    fontFamily: 'Pretendard-Light',
                                    letterSpacing: -0.24,
                                  ),
                                ),
                                if (_selectedSubject == '과학') ...[
                                  SizedBox(width: 4),
                                  Image.asset(
                                    'assets/icons/parent/mission/check_Fill.png',
                                    width: 16,
                                    height: 16,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                                             // 빈 공간 추가 (2줄째는 2개만 있어서 균형 맞춤)
                       Expanded(child: SizedBox()),
                     ],
                      ),
                    ),
                   ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _goBack,
                    child: Container(
                      margin: EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDDDDDD),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '이전',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontFamily: 'Pretendard-Regular',
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      if (_selectedMissionCategory == 'LEARNING') {
                        if (_selectedSubject != null) {
                          _proceedToNextStep();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('미션 과목을 선택해주세요.')),
                          );
                        }
                      } else {
                        _proceedToNextStep();
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF5D9EFF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '완료',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontFamily: 'Pretendard-Regular',
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
