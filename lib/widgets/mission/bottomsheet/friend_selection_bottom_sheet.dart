import 'package:flutter/material.dart';

/// 친구 선택 바텀시트
class FriendSelectionBottomSheet extends StatefulWidget {
  final Function(Map<String, dynamic>)? onFriendSelected;

  const FriendSelectionBottomSheet({
    super.key,
    this.onFriendSelected,
  });

  @override
  State<FriendSelectionBottomSheet> createState() =>
      _FriendSelectionBottomSheetState();
}

class _FriendSelectionBottomSheetState
    extends State<FriendSelectionBottomSheet> {
  Map<String, dynamic>? _selectedFriend;
  final TextEditingController _searchController = TextEditingController();

  // 목업 친구 데이터
  final List<Map<String, dynamic>> _mockFriends = [
    {
      'id': '1',
      'name': '진리뱅',
      'phone': '010-1234-5678',
      'profileImageUrl': 'https://placehold.co/48x48',
      'targetAmount': 300000,
      'entireCompleted': 15,
      'totalMissions': 30,
    },
    {
      'id': '2',
      'name': '진뱅뱅',
      'phone': '010-1234-5678',
      'profileImageUrl': 'https://placehold.co/48x48',
      'targetAmount': 280000,
      'entireCompleted': 12,
      'totalMissions': 30,
    },
    {
      'id': '3',
      'name': '진리틀',
      'phone': '010-1234-5678',
      'profileImageUrl': 'https://placehold.co/48x48',
      'targetAmount': 320000,
      'entireCompleted': 18,
      'totalMissions': 30,
    },
    {
      'id': '4',
      'name': '진뱅뱅',
      'phone': '010-1234-5678',
      'profileImageUrl': 'https://placehold.co/48x48',
      'targetAmount': 290000,
      'entireCompleted': 10,
      'totalMissions': 30,
    },
  ];

  List<Map<String, dynamic>> _filteredFriends = [];

  @override
  void initState() {
    super.initState();
    _filteredFriends = _mockFriends;
    _searchController.addListener(_filterFriends);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterFriends() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredFriends = _mockFriends;
      } else {
        _filteredFriends = _mockFriends
            .where((friend) =>
                friend['name'].toLowerCase().contains(query) ||
                friend['phone'].contains(query))
            .toList();
      }
    });
  }

  void _selectFriend(Map<String, dynamic> friend) {
    setState(() {
      _selectedFriend = friend;
    });
  }

  void _onComplete() {
    if (_selectedFriend != null && widget.onFriendSelected != null) {
      widget.onFriendSelected!(_selectedFriend!);
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    
    // 반응형 너비 계산
    double containerWidth;
    if (screenWidth <= 600) {
      containerWidth = screenWidth;
    } else if (screenWidth <= 1024) {
      containerWidth = 600;
    } else {
      containerWidth = 800;
    }

    return AnimatedPadding(
      padding: EdgeInsets.only(bottom: keyboardHeight + 83), // 83은 바텀 네비게이션 높이
      duration: const Duration(milliseconds: 100),
      child: Container(
        width: containerWidth,
        constraints: BoxConstraints(
          maxHeight: screenHeight * 0.6, // 화면 높이의 50%로 제한
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
                    // 헤더 섹션
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '누구와 경쟁할까요?',
                      style: TextStyle(
                        color: const Color(0xFF202020),
                        fontSize: screenWidth > 600 ? 20 : 18,
                        fontFamily: 'Pretendard-Bold',
                        letterSpacing: -0.72,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: Image.asset(
                        'assets/icons/my/close.png',
                        width: 24,
                        height: 24,
                        color: const Color(0xFF202020),
                      ),
                    ),
                  ],
                ),
                Text(
                  '나와 비슷한 목표의 친구들만 보여드릴게요',
                  style: TextStyle(
                    color: const Color(0xFF999999),
                    fontSize: screenWidth > 600 ? 16 : 14,
                    fontFamily: 'Pretendard-Light',
                    letterSpacing: -0.28,
                  ),
                ),
              ],
            ),
          ),
          
          // 검색 섹션
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            color: Colors.white,
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: ShapeDecoration(
                color: const Color(0xFFE7ECF6),
                shape: RoundedRectangleBorder(
                  side: const BorderSide(
                    width: 0.60,
                    color: Color(0xFF5D6A7F),
                  ),
                  borderRadius: BorderRadius.circular(32),
                ),
              ),
              child: Row(
                children: [
                  Image.asset(
                    'assets/icons/my/검색.png',
                    width: 20,
                    height: 20,
                    color: const Color(0xFF999999),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: '찾고싶은 상대를 검색해 주세요',
                        hintStyle: TextStyle(
                          color: const Color(0xFF999999),
                          fontSize: screenWidth > 600 ? 14 : 12,
                          fontFamily: 'Pretendard-Light',
                          letterSpacing: -0.24,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        fillColor: Colors.transparent,
                        filled: true,
                      ),
                      style: TextStyle(
                        color: const Color(0xFF202020),
                        fontSize: screenWidth > 600 ? 14 : 12,
                        fontFamily: 'Pretendard-Regular',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // 친구 목록
          Flexible(
            child: Container(
              width: double.infinity,
              color: Colors.white,
                             child: ListView.builder(
                 shrinkWrap: true,
                 padding: const EdgeInsets.only(top: 4),
                 itemCount: _filteredFriends.length,
                itemBuilder: (context, index) {
                  final friend = _filteredFriends[index];
                  final isSelected = _selectedFriend?['id'] == friend['id'];
                  
                                     return Container(
                     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                     child: GestureDetector(
                       onTap: () => _selectFriend(friend),
                       child: Container(
                         padding: const EdgeInsets.all(4),
                         child: Row(
                           children: [
                             // 프로필 이미지
                             Container(
                               width: 48,
                               height: 48,
                               decoration: ShapeDecoration(
                                 image: DecorationImage(
                                   image: NetworkImage(friend['profileImageUrl']),
                                   fit: BoxFit.cover,
                                 ),
                                 shape: const OvalBorder(),
                               ),
                             ),
                             const SizedBox(width: 12),
                             
                             // 친구 정보
                             Expanded(
                               child: Column(
                                 crossAxisAlignment: CrossAxisAlignment.start,
                                 children: [
                                   Text(
                                     friend['name'],
                                     style: TextStyle(
                                       color: const Color(0xFF202020),
                                       fontSize: screenWidth > 600 ? 18 : 16,
                                       fontFamily: 'Pretendard-Bold',
                                       letterSpacing: -0.32,
                                     ),
                                   ),
                                   const SizedBox(height: 2),
                                   Text(
                                     friend['phone'],
                                     style: TextStyle(
                                       color: const Color(0xFF666666),
                                       fontSize: screenWidth > 600 ? 14 : 12,
                                       fontFamily: 'Pretendard-Light',
                                       letterSpacing: -0.24,
                                     ),
                                   ),
                                 ],
                               ),
                             ),
                             
                             // 선택 아이콘
                             Container(
                               width: 24,
                               height: 24,
                               decoration: BoxDecoration(
                                 shape: BoxShape.circle,
                                 color: isSelected 
                                     ? const Color(0xFF10CB86)
                                     : Colors.white,
                                 border: isSelected
                                     ? null
                                     : Border.all(
                                         color: const Color(0xFF202020),
                                         width: 1.0,
                                       ),
                               ),
                               child: isSelected
                                   ? const Icon(
                                       Icons.check,
                                       color: Colors.white,
                                       size: 16,
                                     )
                                   : null,
                             ),
                           ],
                         ),
                       ),
                     ),
                   );
                },
              ),
            ),
          ),
          
          // 선택 완료 버튼
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            color: Colors.white,
            child: InkWell(
              onTap: _selectedFriend != null ? _onComplete : null,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: ShapeDecoration(
                  color: _selectedFriend != null
                      ? const Color(0xFF3A88F4)
                      : const Color(0xFFCCCCCC),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Center(
                  child: Text(
                    '선택 완료',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: screenWidth > 600 ? 16 : 14,
                      fontFamily: 'Pretendard-Light',
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
       ),
     );
   }
 }

/// 친구 선택 바텀시트를 표시하는 함수
void showFriendSelectionBottomSheet(
  BuildContext context, {
  Function(Map<String, dynamic>)? onFriendSelected,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    enableDrag: true,
    isDismissible: true,
    useSafeArea: false,
    builder: (context) => FriendSelectionBottomSheet(
      onFriendSelected: onFriendSelected,
    ),
  );
} 