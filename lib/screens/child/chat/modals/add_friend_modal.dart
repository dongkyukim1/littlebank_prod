import 'package:flutter/material.dart';
import '../../../../services/relationship_service.dart';

class AddFriendModalContent extends StatefulWidget {
  final VoidCallback onFriendAdded; // 친구 추가 성공 시 호출할 콜백 추가

  const AddFriendModalContent({super.key, required this.onFriendAdded});

  @override
  State<AddFriendModalContent> createState() => _AddFriendModalContentState();
}

class _AddFriendModalContentState extends State<AddFriendModalContent> {
  final TextEditingController phoneController = TextEditingController();
  String? errorText;
  Map<String, dynamic>? searchResult;
  bool isSearching = false;
  bool hasSearched = false;

  // 이미 친구인지 또는 요청 중인지 상태 추가
  bool _isAlreadyFriend = false;
  bool _isPendingRequest = false;
  String _relationshipStatus = '';

  @override
  void dispose() {
    phoneController.dispose();
    super.dispose();
  }

  // 핸드폰 번호 형식 검증
  void validatePhoneNumber(String value) {
    // 숫자와 하이픈만 허용
    final RegExp phoneRegex = RegExp(r'^[0-9\-]+$');

    if (value.isEmpty) {
      setState(() {
        errorText = '핸드폰 번호를 입력해주세요';
      });
    } else if (!phoneRegex.hasMatch(value)) {
      setState(() {
        errorText = '올바른 번호 형식이 아닙니다';
      });
    } else if (value.replaceAll('-', '').length != 11) {
      setState(() {
        errorText = '핸드폰 번호는 11자리여야 합니다';
      });
    } else {
      setState(() {
        errorText = null;
      });
    }
  }

  // 사용자 검색
  Future<void> searchUser() async {
    if (errorText != null || phoneController.text.isEmpty) {
      return;
    }

    setState(() {
      isSearching = true;
      hasSearched = false;
      searchResult = null;
      _isAlreadyFriend = false;
      _isPendingRequest = false;
      _relationshipStatus = '';
    });

    final result = await RelationshipService.searchUserByPhone(
      phoneController.text,
    );

    if (!mounted) return; // 위젯이 여전히 마운트되어 있는지 확인

    setState(() {
      isSearching = false;
      hasSearched = true;
      searchResult = result;

      // 관계 상태 확인
      _checkRelationshipStatus();
    });
  }

  // 관계 상태 확인
  void _checkRelationshipStatus() {
    if (searchResult == null) return;

    print('===== 관계 상태 확인 시작 =====');
    print('검색 결과: $searchResult');

    // API 응답에서 직접적인 친구 정보 확인
    final friendInfo = searchResult!['friendInfo'];
    if (friendInfo != null) {
      // friendInfo가 유효한 객체인지 확인 (null이 아닌 빈 맵일 수도 있음)
      if (friendInfo is Map &&
          friendInfo.isNotEmpty &&
          friendInfo['friendId'] != null) {
        _isAlreadyFriend = true;
        print('유효한 친구 정보가 있습니다 - 이미 친구인 사용자');
        print('친구 ID: ${friendInfo['friendId']}');

        // 차단 여부 확인
        if (friendInfo['isBlocked'] == true) {
          print('차단된 사용자입니다.');
        }

        // 친한 친구 여부 확인
        if (friendInfo['isBestFriend'] == true) {
          print('친한 친구로 설정된 사용자입니다.');
        }

        return;
      } else {
        print('friendInfo가 있지만 비어 있거나 유효하지 않음: $friendInfo');
      }
    } else {
      print('직접적인 친구 정보(friendInfo)가 없습니다');
    }

    // 이전 버전과의 호환성을 위해 relationships 필드도 체크
    final relationships = searchResult!['relationships'] as List<dynamic>?;
    if (relationships != null && relationships.isNotEmpty) {
      print('relationship 정보 확인: $relationships');

      for (final relationship in relationships) {
        final type = relationship['relationshipType'] as String;
        final status = relationship['relationshipStatus'] as String;

        print('관계 유형: $type, 상태: $status');

        if (type == 'FRIEND') {
          _relationshipStatus = status;

          // 이미 친구인 경우 또는 친구 요청 중인 경우
          if (status == 'CONNECTED') {
            _isAlreadyFriend = true;
            print('이미 친구인 사용자입니다 (relationship 정보 기반)');
          } else if (status == 'REQUESTED') {
            _isPendingRequest = true;
            print('이미 친구 요청을 보낸 사용자입니다.');
          } else if (status == 'REQUESTED_BY_OTHER') {
            print('상대방이 친구 요청을 보낸 상태입니다.');
          }

          break;
        } else if (type == 'FAMILY') {
          print('가족 멤버 관계가 있습니다.');
          // 가족 멤버 관계를 여기서 처리
        }
      }
    } else {
      print('relationships 정보가 없거나 비어 있습니다');
    }

    // "이미 친구" 메시지가 있지만 실제 정보는 없는 경우 확인
    if (searchResult!.containsKey('message') &&
        searchResult!['message'].toString().contains('이미 친구')) {
      print('서버 메시지에 "이미 친구"가 포함되어 있지만 실제 친구 정보는 없습니다');
    }

    print('===== 관계 상태 확인 완료 =====');
  }

  // 친구 추가 요청 보내기
  Future<void> sendRequest() async {
    // 변경된 API 응답 구조에 맞게 searchUserId 필드 사용
    if (searchResult == null || searchResult!['searchUserId'] == null) {
      print('유효한 사용자 정보가 없어 친구 요청을 보낼 수 없습니다.');
      return;
    }

    // 이미 친구거나 요청 중인 경우 처리
    if (_isAlreadyFriend) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${searchResult!['name']}님과 이미 친구입니다.'),
          backgroundColor: const Color(0xFF3A88F4),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      Navigator.pop(context);
      return;
    }

    if (_isPendingRequest) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${searchResult!['name']}님에게 이미 친구 요청을 보냈습니다.'),
          backgroundColor: const Color(0xFF3A88F4),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      Navigator.pop(context);
      return;
    }

    print(
      '친구 요청 시작 - 사용자명: ${searchResult!['name']}, ID: ${searchResult!['searchUserId']}',
    );

    setState(() {
      isSearching = true;
    });

    final result = await RelationshipService.sendRelationshipRequest(
      searchResult!['searchUserId'] as int,
      'FRIEND', // 친구 관계 요청
    );

    if (!mounted) return; // 위젯이 여전히 마운트되어 있는지 확인

    setState(() {
      isSearching = false;
    });

    // 결과 처리 - 오류가 있는지 확인
    if (result != null) {
      if (result.containsKey('error') && result['error'] == true) {
        // 이미 친구이거나 관계가 있는 경우에 대한 처리
        print('친구 요청 오류: ${result['message']}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? '이미 친구이거나 관계가 있는 사용자입니다.'),
            backgroundColor: const Color(0xFF3A88F4),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        Navigator.pop(context);

        // 친구 목록 업데이트 콜백 호출 (이미 친구인 경우 UI 리프레시)
        widget.onFriendAdded();
        return;
      }

      print('친구 요청 UI 처리: 성공 - 스낵바 표시');
      Navigator.pop(context);

      // 친구 목록 업데이트 콜백 호출
      widget.onFriendAdded();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${searchResult!['name']}님에게 친구 요청을 보냈습니다'),
          backgroundColor: const Color(0xFF3A88F4),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } else {
      print('친구 요청 UI 처리: 실패 - 오류 스낵바 표시');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('친구 요청을 보내는데 실패했습니다. 다시 시도해주세요.'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  // 검색 결과 위젯
  Widget buildSearchResult() {
    if (!hasSearched) {
      return Container(); // 검색 전에는 아무것도 표시하지 않음
    }

    if (searchResult == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text(
            '해당 번호로 등록된 사용자를 찾을 수 없습니다',
            style: TextStyle(
              color: Color(0xFF666666),
              fontSize: 14,
              fontFamily: 'Pretendard-Regular',
            ),
          ),
        ),
      );
    }

    // 변경된 API 응답 구조에 맞게 수정
    final String userName = searchResult!['name'] as String;
    final String userRole = searchResult!['role'] as String;
    final String? statusMessage = searchResult!['statusMessage'] as String?;
    final String relationshipStatus;

    // friendInfo가 있고 friendId가 존재해야 실제 친구 관계
    final friendInfo = searchResult!['friendInfo'];
    if (friendInfo != null && friendInfo['friendId'] != null) {
      final bool isBlocked = friendInfo['isBlocked'] == true;
      final bool isBestFriend = friendInfo['isBestFriend'] == true;

      if (isBlocked) {
        relationshipStatus = '상태: 차단됨';
      } else if (isBestFriend) {
        relationshipStatus = '상태: 친한 친구';
      } else {
        relationshipStatus = '상태: 친구';
      }
    } else if (_isPendingRequest) {
      relationshipStatus = '상태: 요청 중';
    } else {
      relationshipStatus = '';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // 프로필 이미지
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F6FF),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE6EFFE), width: 1),
            ),
            child:
                searchResult!['profileImagePath'] != null &&
                        searchResult!['profileImagePath'].toString().isNotEmpty
                    ? ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.network(
                        searchResult!['profileImagePath'] as String,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (_, __, ___) => Center(
                              child: Text(
                                userName.substring(0, 1),
                                style: const TextStyle(fontSize: 20),
                              ),
                            ),
                      ),
                    )
                    : Center(
                      child: Text(
                        userName.substring(0, 1),
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
          ),
          const SizedBox(width: 16),

          // 사용자 정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName,
                  style: const TextStyle(
                    color: Color(0xFF262626),
                    fontSize: 16,
                    fontFamily: 'Pretendard-Bold',
                  ),
                ),
                if (statusMessage != null && statusMessage.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    statusMessage,
                    style: const TextStyle(
                      color: Color(0xFF666666),
                      fontSize: 12,
                      fontFamily: 'Pretendard-Regular',
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  '역할: ${userRole == 'PARENT' ? '부모' : '자녀'}',
                  style: const TextStyle(
                    color: Color(0xFF666666),
                    fontSize: 12,
                    fontFamily: 'Pretendard-Regular',
                  ),
                ),
                if (relationshipStatus.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    relationshipStatus,
                    style: TextStyle(
                      color:
                          _isAlreadyFriend
                              ? const Color(0xFF4CAF50) // 이미 친구면 초록색
                              : _isPendingRequest
                              ? const Color(0xFFFFA000) // 요청 중이면 노란색
                              : const Color(0xFF3A88F4), // 그 외에는 파란색
                      fontSize: 12,
                      fontFamily: 'Pretendard-Medium',
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 버튼 활성화 여부 결정
    bool canSendRequest =
        searchResult != null &&
        !isSearching &&
        !_isAlreadyFriend &&
        !_isPendingRequest;

    // 버튼 텍스트 결정
    String buttonText = '친구 요청';
    if (_isAlreadyFriend) {
      buttonText = '이미 친구입니다';
    } else if (_isPendingRequest) {
      buttonText = '요청 중';
    }

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 모달 타이틀
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '친구 추가',
                style: TextStyle(
                  fontSize: 18,
                  fontFamily: 'Pretendard-Bold',
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF202020),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 24),
                onPressed: () => Navigator.pop(context),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // 설명 텍스트
          const Text(
            '친구의 핸드폰 번호로 검색하여 추가할 수 있어요',
            style: TextStyle(
              fontSize: 13,
              fontFamily: 'Pretendard-Regular',
              fontWeight: FontWeight.w400,
              color: Color(0xFF666666),
            ),
          ),

          const SizedBox(height: 24),

          // 핸드폰 번호 입력 필드와 검색 버튼
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 전화번호 입력 필드
              Expanded(
                child: TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  onChanged: validatePhoneNumber,
                  decoration: InputDecoration(
                    hintText: '010-0000-0000',
                    hintStyle: const TextStyle(
                      color: Color(0xFF999999),
                      fontSize: 14,
                      fontFamily: 'Pretendard-Regular',
                      fontWeight: FontWeight.w400,
                    ),
                    prefixIcon: const Icon(
                      Icons.phone_android,
                      color: Color(0xFF3A88F4),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF5F5F5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    errorText: errorText,
                    errorStyle: const TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                      fontFamily: 'Pretendard-Regular',
                    ),
                  ),
                ),
              ),

              // 검색 버튼
              const SizedBox(width: 12),
              Container(
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF3A88F4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: isSearching ? null : searchUser,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Center(
                        child:
                            isSearching
                                ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                                : const Icon(Icons.search, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // 검색 결과 영역
          buildSearchResult(),

          // 버튼 영역
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF3A88F4),
                    side: const BorderSide(color: Color(0xFF3A88F4)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    '취소',
                    style: TextStyle(
                      fontFamily: 'Pretendard-Medium',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: canSendRequest ? sendRequest : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3A88F4),
                    disabledBackgroundColor: const Color(0xFFCCCCCC),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child:
                      isSearching
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                          : Text(
                            buttonText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontFamily: 'Pretendard-Medium',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
