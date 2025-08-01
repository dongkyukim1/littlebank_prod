import 'package:flutter/material.dart';
import '../../../services/auth_service.dart';
import '../../../services/relationship_service.dart';
import '../../../services/family_service.dart';
import 'package:cached_network_image/cached_network_image.dart';

class FamilyManagementScreen extends StatefulWidget {
  const FamilyManagementScreen({super.key});

  @override
  State<FamilyManagementScreen> createState() => _FamilyManagementScreenState();
}

class _FamilyManagementScreenState extends State<FamilyManagementScreen> {
  // 사용자 정보 및 로딩 상태
  Map<String, dynamic>? _userInfo;
  List<dynamic>? _familyMembers;
  List<dynamic>? _pendingInvites; // 초대 요청 중인 멤버 목록
  bool _isLoading = true;
  String? _errorMessage;
  int? _familyId; // 현재 가족 ID

  // 현재 로그인한 사용자를 제외한 가족 구성원 목록
  List<dynamic> get filteredFamilyMembers {
    final int? currentUserId = _userInfo?['userId'];
    return _familyMembers?.where((member) {
          return member['userId'] != currentUserId;
        }).toList() ??
        [];
  }

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _loadFamilyMembers();
  }

  // 사용자 정보 불러오기
  Future<void> _loadUserInfo() async {
    try {
      if (mounted) {
        setState(() {
          _isLoading = true;
          _errorMessage = null;
        });
      }

      final userInfo = await AuthService.getUserInfo();

      if (mounted) {
        setState(() {
          _userInfo = userInfo;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
      print('사용자 정보 로딩 오류: $e');
    }
  }

  // 가족 구성원 목록 불러오기
  Future<void> _loadFamilyMembers() async {
    try {
      if (mounted) {
        setState(() {
          _isLoading = true;
          _errorMessage = null;
        });
      }

      print('가족 구성원 목록 로드 시작');

      // RelationshipService 대신 FamilyService 사용
      final familyInfo = await FamilyService.getFamilyInfo();

      if (familyInfo != null) {
        final List<dynamic> memberList = familyInfo['memberInfoList'] ?? [];
        final int? familyId = familyInfo['familyId'];
        print('가족 정보 로드 성공: 멤버 ${memberList.length}명, 가족 ID: $familyId');

        // 가족 ID가 있을 경우, 초대 요청 중인 멤버 목록도 로드
        if (familyId != null) {
          _familyId = familyId;
          await _loadPendingInvites(familyId);
        }

        if (mounted) {
          setState(() {
            _familyMembers = memberList;
            _isLoading = false;
          });
        }
      } else {
        // 가족 정보 조회 실패 (API 오류)
        print('가족 정보 조회 실패 또는 가족 정보 없음');

        if (mounted) {
          setState(() {
            _familyMembers = [];
            _pendingInvites = [];
            _isLoading = false;
            _errorMessage = '가족 정보를 불러올 수 없습니다. 잠시 후 다시 시도해주세요.';
          });
        }

        // 재시도 로직 - 3초 후 자동 재시도 (최대 1회)
        await Future.delayed(Duration(seconds: 3));
        if (mounted) {
          try {
            final secondAttempt = await FamilyService.getFamilyInfo();
            if (secondAttempt != null) {
              final List<dynamic> members =
                  secondAttempt['memberInfoList'] ?? [];
              final int? familyId = secondAttempt['familyId'];
              print('두 번째 시도 성공: 멤버 ${members.length}명, 가족 ID: $familyId');

              // 가족 ID가 있을 경우, 초대 요청 중인 멤버 목록도 로드
              if (familyId != null) {
                _familyId = familyId;
                await _loadPendingInvites(familyId);
              }

              if (mounted) {
                setState(() {
                  _familyMembers = members;
                  _isLoading = false;
                  _errorMessage = null;
                });
              }
            }
          } catch (retryError) {
            print('재시도 중 오류: $retryError');
          }
        }
      }
    } catch (e) {
      print('가족 구성원 목록 로드 중 예외 발생: $e');

      if (mounted) {
        setState(() {
          _errorMessage = '오류가 발생했습니다: $e';
          _isLoading = false;
          _familyMembers = [];
          _pendingInvites = [];
        });
      }
    }
  }

  // 초대 요청 중인 멤버 목록 불러오기
  Future<void> _loadPendingInvites(int familyId) async {
    try {
      print('초대 요청 중인 멤버 목록 로드 시작');

      final pendingInvites = await FamilyService.getSentInvites(familyId);

      if (pendingInvites != null) {
        print('초대 요청 중인 멤버 로드 성공: ${pendingInvites.length}명');

        if (mounted) {
          setState(() {
            _pendingInvites = pendingInvites;
          });
        }
      } else {
        print('초대 요청 중인 멤버 목록 로드 실패 또는 없음');
        if (mounted) {
          setState(() {
            _pendingInvites = [];
          });
        }
      }
    } catch (e) {
      print('초대 요청 중인 멤버 목록 로드 중 예외 발생: $e');
      if (mounted) {
        setState(() {
          _pendingInvites = [];
        });
      }
    }
  }

  // 가족 구성원 추가 함수
  Future<bool> _addFamilyMember(int targetUserId) async {
    try {
      print('가족 멤버 추가 시작 - targetUserId: $targetUserId');

      // RelationshipService 대신 FamilyService 사용
      final result = await FamilyService.addFamilyMember(targetUserId);

      if (result != null) {
        print('가족 멤버 추가 결과: $result');

        // 오류 코드 확인
        if (result.containsKey('error') && result['error'] == true) {
          // 이미 초대를 보낸 유저인 경우
          if (result['errorCode'] == 'F001' || result['errorCode'] == 'FM002') {
            _showAlreadyInvitedWarningDialog(context);
            return false;
          }
          // 이미 가족 멤버로 소속되어 있는 경우
          else if (result['errorCode'] == 'F002') {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('이미 가족 멤버로 소속되어 있는 사용자입니다'),
                backgroundColor: Colors.orange,
              ),
            );
            return false;
          }
          // 기타 오류
          else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result['message'] ?? '가족 멤버 추가 중 오류가 발생했습니다'),
                backgroundColor: Colors.red,
              ),
            );
            return false;
          }
        }

        // 초대가 성공적으로 전송됨
        _showInvitationSentDialog(context);

        // 가족 목록 새로고침
        await _loadFamilyMembers();
        return true;
      } else {
        print('가족 멤버 추가 실패: 응답이 null');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('가족 멤버 추가에 실패했습니다'),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }
    } catch (e) {
      print('가족 멤버 추가 중 오류 발생: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류가 발생했습니다: $e'), backgroundColor: Colors.red),
      );
      return false;
    }
  }

  // 이미 초대한 사용자에게 초대를 보낼 때 경고 대화상자
  void _showAlreadyInvitedWarningDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            '이미 초대를 보냈습니다',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              fontFamily: 'Pretendard',
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '해당 사용자에게 이미 가족 초대를 보냈습니다. 상대방이 초대를 수락하면 가족 구성원으로 추가됩니다.',
                style: TextStyle(fontSize: 15, fontFamily: 'Pretendard'),
              ),
              SizedBox(height: 12),
              Text(
                '초대 수락 대기 중입니다.',
                style: TextStyle(
                  fontSize: 14,
                  fontFamily: 'Pretendard',
                  color: Colors.blue,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text(
                '확인',
                style: TextStyle(
                  color: Color(0xFF3A88F4),
                  fontSize: 16,
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // 초대 전송 완료 대화상자
  void _showInvitationSentDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            '초대 전송 완료',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              fontFamily: 'Pretendard',
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '가족 초대를 성공적으로 전송했습니다.',
                style: TextStyle(fontSize: 15, fontFamily: 'Pretendard'),
              ),
              SizedBox(height: 12),
              Text(
                '⚠️ 중요: 초대 대상자가 이미 다른 가족 그룹에 속해 있는 경우, 이 초대를 수락하면 기존 가족 그룹에서 자동으로 나가게 됩니다.',
                style: TextStyle(
                  fontSize: 14,
                  fontFamily: 'Pretendard',
                  color: Colors.orange,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text(
                '확인',
                style: TextStyle(
                  color: Color(0xFF3A88F4),
                  fontSize: 16,
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // 가족 추가 모달 창 표시
  void _showAddFamilyModal(BuildContext context) {
    final TextEditingController phoneController = TextEditingController();
    String phoneNumber = '';
    bool isSearching = false;
    Map<String, dynamic>? searchResult;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        return StatefulBuilder(
          builder: (builderContext, setState) {
            // 전화번호가 완성되었는지 확인
            bool isPhoneComplete = phoneNumber.length >= 10;

            // 말풍선이 표시될 때 높이 조정 (높이를 늘림)
            double sheetHeight =
                MediaQuery.of(builderContext).size.height * 0.52;
            if (isPhoneComplete &&
                (searchResult != null ||
                    isSearching ||
                    (!isSearching && searchResult == null))) {
              sheetHeight = MediaQuery.of(builderContext).size.height * 0.56;
            }

            return Container(
              height: sheetHeight,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              clipBehavior: Clip.hardEdge,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 헤더 부분
                  Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(color: Colors.white),
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 20,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            '초대하고 싶은 가족 멤버를 검색해 주세요',
                            style: TextStyle(
                              fontFamily: 'Pretendard-Bold',
                              fontSize: 16,
                              letterSpacing: -0.72,
                              color: Color(0xFF202020),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(bottomSheetContext),
                          child: Icon(
                            Icons.close,
                            size: 20,
                            color: Color(0xFF999999),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 전화번호 입력 필드 부분
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                phoneNumber.isEmpty
                                    ? '전화번호를 입력해 주세요'
                                    : phoneNumber,
                                style: TextStyle(
                                  fontFamily:
                                      phoneNumber.isEmpty
                                          ? 'Pretendard-Light'
                                          : 'Pretendard-Bold',
                                  fontSize: phoneNumber.isEmpty ? 16 : 18,
                                  letterSpacing:
                                      phoneNumber.isEmpty ? -0.72 : -1.12,
                                  color:
                                      phoneNumber.isEmpty
                                          ? Color(0xFFD5D5D5)
                                          : Color(0xFF202020),
                                ),
                              ),
                              Container(
                                width: double.infinity,
                                height: 0.8,
                                margin: EdgeInsets.only(top: 4),
                                color:
                                    searchResult != null
                                        ? Color(0xFF5D9EFF)
                                        : Color(0xFFD5D5D5),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 12),

                        // 전화번호 입력 완료 시 유저 정보 표시 (가운데 정렬, 말풍선 형태)
                        if (isPhoneComplete)
                          Center(
                            child: Column(
                              children: [
                                if (isSearching)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF5F5F5),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '사용자를 검색 중입니다...',
                                      style: const TextStyle(
                                        color: Color(0xFF666666),
                                        fontSize: 11,
                                        fontFamily: 'Pretendard-Light',
                                        letterSpacing: -0.22,
                                      ),
                                    ),
                                  )
                                else if (searchResult != null)
                                  Container(
                                    constraints: BoxConstraints(minWidth: 180),
                                    child: Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        // 말풍선 꼬리 (위쪽)
                                        Positioned(
                                          top: -6,
                                          left: 0,
                                          right: 0,
                                          child: Transform.translate(
                                            offset: Offset(
                                              -35,
                                              0,
                                            ), // 중앙에서 약간 왼쪽으로
                                            child: Center(
                                              child: CustomPaint(
                                                size: Size(12, 6),
                                                painter: _BubbleTailPainter(),
                                              ),
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 10,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF5D9EFF),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Text(
                                            '${searchResult!['name'] ?? searchResult!['realName'] ?? '사용자'}님을 찾았습니다!',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontFamily: 'Pretendard-Light',
                                              letterSpacing: -0.22,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                else if (!isSearching &&
                                    searchResult == null &&
                                    isPhoneComplete)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFEBEE),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '사용자를 찾을 수 없습니다',
                                      style: const TextStyle(
                                        color: Color(0xFFE57373),
                                        fontSize: 11,
                                        fontFamily: 'Pretendard-Light',
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

                  // 키패드 부분
                  Expanded(
                    child: Transform.translate(
                      offset: Offset(0, -12),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Row(
                              children: [
                                _buildKeypadButton('1', () async {
                                  setState(() {
                                    phoneNumber += '1';
                                    // 전화번호 변경 시 검색 결과 초기화
                                    searchResult = null;
                                    isSearching = false;
                                  });
                                  // 실시간 검색
                                  if (phoneNumber.length >= 10) {
                                    setState(() {
                                      isSearching = true;
                                    });
                                    try {
                                      final result = await _searchUser(
                                        phoneNumber,
                                      );
                                      setState(() {
                                        searchResult = result;
                                        isSearching = false;
                                      });
                                    } catch (e) {
                                      setState(() {
                                        searchResult = null;
                                        isSearching = false;
                                      });
                                    }
                                  }
                                }),
                                _buildKeypadButton('2', () async {
                                  setState(() {
                                    phoneNumber += '2';
                                    searchResult = null;
                                    isSearching = false;
                                  });
                                  if (phoneNumber.length >= 10) {
                                    setState(() {
                                      isSearching = true;
                                    });
                                    try {
                                      final result = await _searchUser(
                                        phoneNumber,
                                      );
                                      setState(() {
                                        searchResult = result;
                                        isSearching = false;
                                      });
                                    } catch (e) {
                                      setState(() {
                                        searchResult = null;
                                        isSearching = false;
                                      });
                                    }
                                  }
                                }),
                                _buildKeypadButton('3', () async {
                                  setState(() {
                                    phoneNumber += '3';
                                    searchResult = null;
                                    isSearching = false;
                                  });
                                  if (phoneNumber.length >= 10) {
                                    setState(() {
                                      isSearching = true;
                                    });
                                    try {
                                      final result = await _searchUser(
                                        phoneNumber,
                                      );
                                      setState(() {
                                        searchResult = result;
                                        isSearching = false;
                                      });
                                    } catch (e) {
                                      setState(() {
                                        searchResult = null;
                                        isSearching = false;
                                      });
                                    }
                                  }
                                }),
                              ],
                            ),
                            Row(
                              children: [
                                _buildKeypadButton('4', () async {
                                  setState(() {
                                    phoneNumber += '4';
                                    searchResult = null;
                                    isSearching = false;
                                  });
                                  if (phoneNumber.length >= 10) {
                                    setState(() {
                                      isSearching = true;
                                    });
                                    try {
                                      final result = await _searchUser(
                                        phoneNumber,
                                      );
                                      setState(() {
                                        searchResult = result;
                                        isSearching = false;
                                      });
                                    } catch (e) {
                                      setState(() {
                                        searchResult = null;
                                        isSearching = false;
                                      });
                                    }
                                  }
                                }),
                                _buildKeypadButton('5', () async {
                                  setState(() {
                                    phoneNumber += '5';
                                    searchResult = null;
                                    isSearching = false;
                                  });
                                  if (phoneNumber.length >= 10) {
                                    setState(() {
                                      isSearching = true;
                                    });
                                    try {
                                      final result = await _searchUser(
                                        phoneNumber,
                                      );
                                      setState(() {
                                        searchResult = result;
                                        isSearching = false;
                                      });
                                    } catch (e) {
                                      setState(() {
                                        searchResult = null;
                                        isSearching = false;
                                      });
                                    }
                                  }
                                }),
                                _buildKeypadButton('6', () async {
                                  setState(() {
                                    phoneNumber += '6';
                                    searchResult = null;
                                    isSearching = false;
                                  });
                                  if (phoneNumber.length >= 10) {
                                    setState(() {
                                      isSearching = true;
                                    });
                                    try {
                                      final result = await _searchUser(
                                        phoneNumber,
                                      );
                                      setState(() {
                                        searchResult = result;
                                        isSearching = false;
                                      });
                                    } catch (e) {
                                      setState(() {
                                        searchResult = null;
                                        isSearching = false;
                                      });
                                    }
                                  }
                                }),
                              ],
                            ),
                            Row(
                              children: [
                                _buildKeypadButton('7', () async {
                                  setState(() {
                                    phoneNumber += '7';
                                    searchResult = null;
                                    isSearching = false;
                                  });
                                  if (phoneNumber.length >= 10) {
                                    setState(() {
                                      isSearching = true;
                                    });
                                    try {
                                      final result = await _searchUser(
                                        phoneNumber,
                                      );
                                      setState(() {
                                        searchResult = result;
                                        isSearching = false;
                                      });
                                    } catch (e) {
                                      setState(() {
                                        searchResult = null;
                                        isSearching = false;
                                      });
                                    }
                                  }
                                }),
                                _buildKeypadButton('8', () async {
                                  setState(() {
                                    phoneNumber += '8';
                                    searchResult = null;
                                    isSearching = false;
                                  });
                                  if (phoneNumber.length >= 10) {
                                    setState(() {
                                      isSearching = true;
                                    });
                                    try {
                                      final result = await _searchUser(
                                        phoneNumber,
                                      );
                                      setState(() {
                                        searchResult = result;
                                        isSearching = false;
                                      });
                                    } catch (e) {
                                      setState(() {
                                        searchResult = null;
                                        isSearching = false;
                                      });
                                    }
                                  }
                                }),
                                _buildKeypadButton('9', () async {
                                  setState(() {
                                    phoneNumber += '9';
                                    searchResult = null;
                                    isSearching = false;
                                  });
                                  if (phoneNumber.length >= 10) {
                                    setState(() {
                                      isSearching = true;
                                    });
                                    try {
                                      final result = await _searchUser(
                                        phoneNumber,
                                      );
                                      setState(() {
                                        searchResult = result;
                                        isSearching = false;
                                      });
                                    } catch (e) {
                                      setState(() {
                                        searchResult = null;
                                        isSearching = false;
                                      });
                                    }
                                  }
                                }),
                              ],
                            ),
                            Row(
                              children: [
                                Spacer(),
                                _buildKeypadButton('0', () async {
                                  setState(() {
                                    phoneNumber += '0';
                                    searchResult = null;
                                    isSearching = false;
                                  });
                                  if (phoneNumber.length >= 10) {
                                    setState(() {
                                      isSearching = true;
                                    });
                                    try {
                                      final result = await _searchUser(
                                        phoneNumber,
                                      );
                                      setState(() {
                                        searchResult = result;
                                        isSearching = false;
                                      });
                                    } catch (e) {
                                      setState(() {
                                        searchResult = null;
                                        isSearching = false;
                                      });
                                    }
                                  }
                                }),
                                _buildDeleteButton(() async {
                                  setState(() {
                                    if (phoneNumber.isNotEmpty) {
                                      phoneNumber = phoneNumber.substring(
                                        0,
                                        phoneNumber.length - 1,
                                      );
                                      // 전화번호가 완성되지 않으면 검색 결과 초기화
                                      if (phoneNumber.length < 10) {
                                        searchResult = null;
                                        isSearching = false;
                                      }
                                    }
                                  });
                                  // 여전히 10자리 이상이면 다시 검색
                                  if (phoneNumber.length >= 10) {
                                    setState(() {
                                      isSearching = true;
                                    });
                                    try {
                                      final result = await _searchUser(
                                        phoneNumber,
                                      );
                                      setState(() {
                                        searchResult = result;
                                        isSearching = false;
                                      });
                                    } catch (e) {
                                      setState(() {
                                        searchResult = null;
                                        isSearching = false;
                                      });
                                    }
                                  }
                                }),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // 하단 버튼 부분
                  Transform.translate(
                    offset: Offset(0, -8),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 48,
                              margin: EdgeInsets.symmetric(horizontal: 4),
                              child: TextButton(
                                onPressed:
                                    () => Navigator.pop(bottomSheetContext),
                                style: TextButton.styleFrom(
                                  backgroundColor: Color(0xFFDCDCDC),
                                  padding: EdgeInsets.all(16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text(
                                  '다음에 하기',
                                  style: TextStyle(
                                    fontFamily: 'Pretendard-Light',
                                    fontSize: 12,
                                    letterSpacing: -0.28,
                                    color: Color(0xFFB6B6B6),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              height: 48,
                              margin: EdgeInsets.symmetric(horizontal: 4),
                              child: TextButton(
                                onPressed:
                                    phoneNumber.length >= 10 &&
                                            searchResult != null &&
                                            !isSearching
                                        ? () async {
                                          if (searchResult != null) {
                                            // 바텀시트 닫기
                                            Navigator.pop(bottomSheetContext);

                                            // 검색 결과가 있으면 확인 모달 표시
                                            _showFamilyMemberConfirmModal(
                                              context,
                                              searchResult!['name'] ??
                                                  searchResult!['realName'] ??
                                                  '알 수 없음',
                                              searchResult!['userId'] ??
                                                  searchResult!['searchUserId'],
                                            );
                                          }
                                        }
                                        : null,
                                style: TextButton.styleFrom(
                                  backgroundColor:
                                      (phoneNumber.length >= 10 &&
                                              searchResult != null)
                                          ? Color(0xFF5D9EFF)
                                          : Color(0xFFDCDCDC),
                                  padding: EdgeInsets.all(16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child:
                                    isSearching
                                        ? SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                        : Text(
                                          '초대하기',
                                          style: TextStyle(
                                            fontFamily: 'Pretendard-Light',
                                            fontSize: 12,
                                            letterSpacing: -0.28,
                                            color:
                                                (phoneNumber.length >= 10 &&
                                                        searchResult != null)
                                                    ? Colors.white
                                                    : Color(0xFFB6B6B6),
                                          ),
                                        ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // 키패드 버튼 위젯
  Widget _buildKeypadButton(String text, dynamic onPressed) {
    return Expanded(
      child: Container(
        height: 44,
        margin: EdgeInsets.all(4.0),
        child: TextButton(
          onPressed: onPressed,
          child: Text(
            text,
            style: TextStyle(
              fontFamily: 'Pretendard-Light',
              fontSize: 20,
              color: Color(0xFFC4C4C4),
              letterSpacing: -1.12,
            ),
          ),
        ),
      ),
    );
  }

  // 삭제 버튼 위젯
  Widget _buildDeleteButton(dynamic onPressed) {
    return Expanded(
      child: Container(
        height: 44,
        margin: EdgeInsets.all(4.0),
        child: TextButton(
          onPressed: onPressed,
          child: Container(
            width: 44,
            height: 44,
            child: Center(
              child: SizedBox(
                width: 40,
                height: 40,
                child: Image.asset(
                  'assets/images/지우기.png',
                  width: 40,
                  height: 40,
                  color: Color(0xFFC4C4C4),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 사용자 검색 함수
  Future<Map<String, dynamic>?> _searchUser(String phone) async {
    final user = await RelationshipService.searchUserByPhone(phone);
    return user;
  }

  // 가족 설정 확인 모달 대화상자
  void _showFamilyMemberConfirmModal(
    BuildContext context,
    String memberName,
    int userId,
  ) {
    // 바로 일반 확인 모달 표시
    _showNormalFamilyConfirmModal(context, memberName, userId);
  }

  // 일반 가족 초대 확인 모달
  void _showNormalFamilyConfirmModal(
    BuildContext context,
    String memberName,
    int userId,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: EdgeInsets.symmetric(horizontal: 21),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.95,
            padding: EdgeInsets.zero,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 메인 헤더 부분
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
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
                      Text(
                        '$memberName님을 가족 멤버로 초대하시겠어요?',
                        style: TextStyle(
                          color: const Color(0xFF202020),
                          fontSize: 15.5,
                          fontFamily: 'Pretendard-Bold',
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '가족 멤버 사이에는 용돈 주고받기가 가능해져요',
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
                // 이미지 부분
                Column(
                  children: [
                    // 이미지 위에 빈 공간 추가
                    const SizedBox(height: 15),

                    // 이미지 컨테이너
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.only(bottom: 12),
                      color: Colors.white,
                      child: Center(
                        child: Image.asset(
                          'assets/icons/my/가족멤버.png',
                          width: 160,
                          height: 160,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ],
                ),

                // 버튼 부분
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  decoration: const ShapeDecoration(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(24),
                        bottomRight: Radius.circular(24),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      // 취소 버튼
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            height: 48,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: ShapeDecoration(
                              color: const Color(0xFFDDDDDD),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '다음에 하기',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontFamily: 'Pretendard-ExtraLight',
                                  letterSpacing: -0.28,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // 확인 버튼
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            Navigator.pop(context);
                            // 실제 가족 구성원 추가 API 호출
                            await _addFamilyMember(userId);
                          },
                          child: Container(
                            height: 48,
                            margin: const EdgeInsets.only(left: 8),
                            decoration: ShapeDecoration(
                              color: const Color(0xFF5D9EFF),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '초대하기',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontFamily: 'Pretendard-ExtraLight',
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
          ),
        );
      },
    );
  }

  // 안내 카드 위젯
  Widget _buildInfoCard(String title, String description) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: ShapeDecoration(
        color: const Color(0xFFF5F6F8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 제목 행
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 2),
                child: Image.asset(
                  'assets/icons/my/Fill_inform.png',
                  width: 14,
                  height: 14,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: const Color(0xFF666666),
                    fontSize: 11,
                    fontFamily: 'Pretendard-Medium',
                    letterSpacing: -0.22,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 4),

          // 설명 텍스트
          Padding(
            padding: const EdgeInsets.only(left: 22),
            child: Text(
              description,
              style: TextStyle(
                color: const Color(0xFF999999),
                fontSize: 10,
                fontFamily: 'Pretendard-Light',
                height: 1.3,
                letterSpacing: -0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 가족 카드 위젯
  Widget _buildFamilyCard(String name, String role, String? profileImagePath) {
    final Color badgeColor =
        (role == 'CHILD') ? const Color(0xFF89DA8D) : const Color(0xFF146AFF);
    final String badgeText = (role == 'CHILD') ? '자녀' : '부모';

    // 이름이 비어있거나 null인 경우 처리
    final displayName = (name.isNotEmpty) ? name : '이름 없음';

    // 가족 멤버 ID 찾기
    int? familyMemberId;
    for (var member in _familyMembers!) {
      if (member['nickname'] == name || member['realName'] == name) {
        familyMemberId = member['familyMemberId'];
        break;
      }
    }

    return GestureDetector(
      onTap: () {
        _showFamilyMemberModal(context, displayName, familyMemberId);
      },
      child: Stack(
        children: [
          // 배경 이미지 (카드)
          Image.asset(
            'assets/icons/my/sub_card.png',
            width: 180,
            height: 180,
            fit: BoxFit.fill,
          ),

          // 수정하기 아이콘 (오른쪽 상단)
          Positioned(
            top: 10,
            right: 10,
            child: GestureDetector(
              onTap: () {
                _showManageOptionsBottomSheet(
                  context,
                  displayName,
                  familyMemberId,
                );
              },
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Image.asset(
                  'assets/icons/my/edit.png',
                  width: 24,
                  height: 24,
                ),
              ),
            ),
          ),

          // 프로필 정보 카드 (하단)
          Positioned(
            bottom: 8,
            left: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Color(0xFF146AFF), width: 1),
                    ),
                    child: ClipOval(
                      child:
                          profileImagePath != null &&
                                  profileImagePath.isNotEmpty
                              ? CachedNetworkImage(
                                imageUrl: AuthService.getFullProfileImageUrl(
                                  profileImagePath,
                                ),
                                fit: BoxFit.cover,
                                placeholder:
                                    (context, url) => Center(
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                      ),
                                    ),
                                errorWidget:
                                    (context, url, error) => Image.asset(
                                      'assets/images/kid.png',
                                      fit: BoxFit.cover,
                                    ),
                              )
                              : Image.asset(
                                'assets/images/kid.png',
                                fit: BoxFit.cover,
                              ),
                    ),
                  ),
                  SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: badgeColor, width: 0.5),
                          ),
                          child: Text(
                            badgeText,
                            style: TextStyle(
                              color: badgeColor,
                              fontSize: 9,
                              fontFamily: 'Pretendard-Light',
                            ),
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          displayName,
                          style: TextStyle(
                            color: Color(0xFF202020),
                            fontSize: 12,
                            fontFamily: 'Pretendard-Bold',
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 가족 멤버 관리 옵션 바텀시트
  void _showManageOptionsBottomSheet(
    BuildContext context,
    String displayName,
    int? familyMemberId,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return Container(
          width: MediaQuery.of(context).size.width,
          height: 142,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: const ShapeDecoration(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                ),
                child: Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    Text(
                      '가족 멤버를 쉽게 관리할 수 있어요',
                      style: TextStyle(
                        color: const Color(0xFF202020),
                        fontSize: 18,
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.72,
                      ),
                    ),
                    Positioned(
                      right: 0,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Image.asset(
                          'assets/icons/my/close.png',
                          width: 24,
                          height: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(
                  top: 12,
                  left: 20,
                  right: 20,
                  bottom: 20,
                ),
                decoration: BoxDecoration(color: Colors.white),
                child: GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    if (familyMemberId != null) {
                      _showNicknameChangeDialog(
                        context,
                        displayName,
                        familyMemberId,
                      );
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      '가족 멤버 별명 설정하기',
                      style: TextStyle(
                        color: const Color(0xFF666666),
                        fontSize: 14,
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w300,
                        letterSpacing: -0.28,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 초대 중인 멤버 카드 위젯
  Widget _buildPendingInviteCard(Map<String, dynamic> invite) {
    final String inviteeName = invite['inviteeName'] ?? '이름 없음';
    final String invitedDate = invite['invitedDate'] ?? '';
    final int? familyMemberId = invite['familyMemberId'];

    // 초대 날짜 포맷팅
    String displayDate = '최근에 초대됨';
    if (invitedDate.isNotEmpty) {
      try {
        final utcDateTime = DateTime.parse(invitedDate);
        final koreanDateTime = utcDateTime.add(Duration(hours: 9));
        final now = DateTime.now();
        final difference = now.difference(koreanDateTime);

        if (difference.isNegative) {
          displayDate = '방금 초대됨';
        } else if (difference.inMinutes < 1) {
          displayDate = '방금 초대됨';
        } else if (difference.inHours < 1) {
          displayDate = '${difference.inMinutes}분 전 초대';
        } else if (difference.inHours < 24) {
          displayDate = '${difference.inHours}시간 전 초대';
        } else {
          displayDate = '${difference.inDays}일 전 초대';
        }
      } catch (e) {
        print('날짜 파싱 오류: $e');
        displayDate = '최근에 초대됨';
      }
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: ShapeDecoration(
        color: const Color(0xFFF5F6F8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 상단 정보 (프로필 아이콘, 초대중 뱃지)
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 초대 아이콘
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE7F3FF),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      Icons.mail_outline,
                      color: const Color(0xFF3A88F4),
                      size: 22,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 10),
              // 텍스트 정보 (뱃지 및 이름)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 초대중 뱃지
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: ShapeDecoration(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          side: BorderSide(
                            width: 0.35,
                            color: const Color(0xFFFFA500),
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: Text(
                        '초대중',
                        style: TextStyle(
                          color: const Color(0xFFFFA500),
                          fontSize: 10,
                          fontFamily: 'Pretendard-Light',
                          letterSpacing: -0.24,
                        ),
                      ),
                    ),

                    const SizedBox(height: 6),
                    // 이름과 초대 시간을 한 줄에 표시
                    Row(
                      children: [
                        // 사용자 이름
                        Expanded(
                          child: Text(
                            inviteeName,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: const Color(0xFF202020),
                              fontSize: 14,
                              fontFamily: 'Pretendard-Bold',
                              letterSpacing: -0.28,
                            ),
                          ),
                        ),

                        // 초대 시간 (이름 오른쪽에 배치)
                        Text(
                          displayDate,
                          style: TextStyle(
                            color: const Color(0xFF999999),
                            fontSize: 8,
                            fontFamily: 'Pretendard-Light',
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),
                    // 취소 버튼 (이름 바로 아래에 배치)
                    if (familyMemberId != null)
                      GestureDetector(
                        onTap: () {
                          _showCancelInvitationDialog(
                            context,
                            inviteeName,
                            familyMemberId,
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 2,
                          ),
                          decoration: ShapeDecoration(
                            color: Colors.white,
                            shape: RoundedRectangleBorder(
                              side: BorderSide(
                                width: 0.35,
                                color: const Color(0xFFFF6B6B),
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          child: Text(
                            '취소',
                            style: TextStyle(
                              color: const Color(0xFFFF6B6B),
                              fontSize: 10,
                              fontFamily: 'Pretendard-Medium',
                              letterSpacing: -0.24,
                            ),
                          ),
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

  // 초대 취소 확인 대화상자
  void _showCancelInvitationDialog(
    BuildContext context,
    String inviteeName,
    int familyMemberId,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            '초대 취소',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              fontFamily: 'Pretendard-Bold',
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$inviteeName님에게 보낸 초대를 취소하시겠습니까?',
                style: TextStyle(
                  fontSize: 15,
                  fontFamily: 'Pretendard-Regular',
                ),
              ),
              SizedBox(height: 8),
              Text(
                '취소 후에는 다시 초대할 수 있습니다.',
                style: TextStyle(
                  fontSize: 13,
                  fontFamily: 'Pretendard-Light',
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text(
                '아니오',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                  fontFamily: 'Pretendard-Medium',
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(
                '예, 취소합니다',
                style: TextStyle(
                  color: Color(0xFF3A88F4),
                  fontSize: 14,
                  fontFamily: 'Pretendard-Bold',
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _cancelInvitation(familyMemberId);
              },
            ),
          ],
        );
      },
    );
  }

  // 초대 취소 메서드
  Future<void> _cancelInvitation(int familyMemberId) async {
    try {
      setState(() {
        _isLoading = true;
      });

      final result = await FamilyService.cancelInvitation(familyMemberId);

      if (result) {
        // 초대 취소 성공
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('초대가 취소되었습니다'), backgroundColor: Colors.green),
        );

        // 가족 멤버 목록 새로고침
        await _loadFamilyMembers();
      } else {
        // 초대 취소 실패
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('초대 취소에 실패했습니다'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류가 발생했습니다: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
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
        centerTitle: true,
        title: const Text(
          '가족 멤버 관리',
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontFamily: 'Pretendard-Bold',
            letterSpacing: -0.32,
          ),
        ),
        leading: IconButton(
          icon: Image.asset('assets/icons/my/뒤로가기.png', width: 20, height: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadUserInfo();
          await _loadFamilyMembers();
        },
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 내 계정 섹션
              _buildMyAccountSection(),

              const SizedBox(height: 40),

              // 함께 이용하는 가족 섹션
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 헤더 섹션 (제목과 설명)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '가족 멤버와 같이 이용할 수있어요.',
                          style: TextStyle(
                            color: const Color(0xFF202020),
                            fontSize: 15,
                            fontFamily: 'Pretendard-Bold',
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '멤버 추가하기를 통해 가족멤버로 추가해보세요',
                          style: TextStyle(
                            color: const Color(0xFF999999),
                            fontSize: 11,
                            fontFamily: 'Pretendard-Light',
                            letterSpacing: -0.28,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 실제 가족 멤버 표시
                  if (filteredFamilyMembers.isNotEmpty)
                    SizedBox(
                      height: 160,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: BouncingScrollPhysics(),
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filteredFamilyMembers.length,
                        itemBuilder: (context, index) {
                          final member = filteredFamilyMembers[index];
                          final String realName = member['realName'] ?? '';
                          final String nickname = member['nickname'] ?? '';
                          final String name =
                              nickname.isNotEmpty
                                  ? nickname
                                  : (realName.isNotEmpty ? realName : '이름 없음');
                          final String role = member['role'] ?? 'PARENT';
                          final String? profileImg = member['profileImagePath'];

                          double screenWidth =
                              MediaQuery.of(context).size.width;
                          double cardWidth = (screenWidth - (32 + 12)) / 2;

                          return Container(
                            width: cardWidth,
                            margin: EdgeInsets.only(
                              right:
                                  index != filteredFamilyMembers.length - 1
                                      ? 16
                                      : 0,
                            ),
                            child: _buildFamilyCard(name, role, profileImg),
                          );
                        },
                      ),
                    ),

                  // 초대 중인 멤버 표시
                  if (_pendingInvites != null &&
                      _pendingInvites!.isNotEmpty) ...[
                    SizedBox(height: 16),
                    SizedBox(
                      height: 160,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: BouncingScrollPhysics(),
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _pendingInvites!.length,
                        itemBuilder: (context, index) {
                          final invite = _pendingInvites![index];

                          double screenWidth =
                              MediaQuery.of(context).size.width;
                          double cardWidth = (screenWidth - (32 + 12)) / 2;

                          return Container(
                            width: cardWidth,
                            margin: EdgeInsets.only(
                              right:
                                  index != _pendingInvites!.length - 1 ? 16 : 0,
                            ),
                            child: _buildPendingInviteCard(invite),
                          );
                        },
                      ),
                    ),
                  ],

                  const SizedBox(height: 40), // 멤버 카드와 버튼 사이 간격 증가
                  // 가족 멤버로 추가하기 버튼
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GestureDetector(
                      onTap: () {
                        _showAddFamilyModal(context);
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: ShapeDecoration(
                          color: const Color(0xFF3A88F4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '연락처로 초대하기',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontFamily: 'Pretendard-Light',
                              letterSpacing: -0.28,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 안내 카드들
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        _buildInfoCard(
                          '가족 멤버로 추가 시, 미션을 전달할 수 있어요.',
                          '리틀뱅크에서는 선생님뿐만 아니라 부모님에게도 미션을 제공받을 수 있어요. 더 많은 미션을 전달받고 성장할 수 있습니다.',
                        ),
                        const SizedBox(height: 10),
                        _buildInfoCard(
                          '아직 리틀뱅크를 이용 전인 가족이 있다면 초대해 보세요.',
                          '연락처로 초대하기를 통해 아직 이용 전인 가족에게 카카오톡으로 초대 링크를 전송할 수 있습니다.',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 70),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 내 계정 섹션
  Widget _buildMyAccountSection() {
    // 사용자 정보에서 필요한 데이터 추출
    final userName = _userInfo?['name'] ?? '사용자';
    final userRole = _userInfo?['role'] ?? 'CHILD';

    // 사용자 권한에 따라 다른 색상과 텍스트 표시
    final Color badgeColor =
        (userRole == 'CHILD')
            ? const Color(0xFF89DA8D)
            : const Color(0xFF146AFF);
    final String badgeText = (userRole == 'CHILD') ? '자녀' : '부모';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 내 계정 헤더
        Padding(
          padding: const EdgeInsets.only(left: 16, top: 14, bottom: 6),
          child: Text(
            '내 계정',
            style: TextStyle(
              color: const Color(0xFF202020),
              fontSize: 16,
              fontFamily: 'Pretendard-Bold',
              letterSpacing: -0.4,
            ),
          ),
        ),

        // 내 계정 카드
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          width: 358,
          height: 76,
          decoration: ShapeDecoration(
            color: const Color(0xFF10CB86),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Stack(
            children: [
              // 사용자 정보
              Positioned(
                left: 12,
                top: 0,
                bottom: 0,
                child: Row(
                  children: [
                    // 프로필 이미지
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child:
                            _userInfo?['profileImagePath'] != null &&
                                    _userInfo!['profileImagePath']!.isNotEmpty
                                ? CachedNetworkImage(
                                  imageUrl: AuthService.getFullProfileImageUrl(
                                    _userInfo!['profileImagePath'],
                                  ),
                                  fit: BoxFit.cover,
                                  placeholder:
                                      (context, url) => const Center(
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                        ),
                                      ),
                                  errorWidget:
                                      (context, url, error) => Image.asset(
                                        'assets/images/kid.png',
                                        fit: BoxFit.cover,
                                      ),
                                )
                                : Image.asset(
                                  'assets/images/kid.png',
                                  fit: BoxFit.cover,
                                ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // 사용자 정보
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // 역할 뱃지
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: ShapeDecoration(
                            color: Colors.white,
                            shape: RoundedRectangleBorder(
                              side: BorderSide(width: 0.35, color: badgeColor),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          child: Text(
                            badgeText,
                            style: TextStyle(
                              color: badgeColor,
                              fontSize: 10,
                              fontFamily: 'Pretendard-Light',
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),

                        // 사용자 이름
                        Text(
                          userName,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontFamily: 'Pretendard-Medium',
                            letterSpacing: -0.28,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 로고 이미지 (오른쪽 아래)
              Positioned(
                right: 10,
                bottom: -5,
                child: Image.asset(
                  'assets/icons/my/my_logo.png',
                  width: 84,
                  height: 84,
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 가족 설정 모달 대화상자
  void _showFamilyMemberModal(
    BuildContext context,
    String displayName,
    int? familyMemberId,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return Container(
          width: MediaQuery.of(context).size.width,
          height: 142,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: const ShapeDecoration(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                ),
                child: Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    Text(
                      '가족 멤버를 쉽게 관리할 수 있어요',
                      style: TextStyle(
                        color: const Color(0xFF202020),
                        fontSize: 18,
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.72,
                      ),
                    ),
                    Positioned(
                      right: 0,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Image.asset(
                          'assets/icons/my/close.png',
                          width: 24,
                          height: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(
                  top: 12,
                  left: 20,
                  right: 20,
                  bottom: 20,
                ),
                decoration: BoxDecoration(color: Colors.white),
                child: GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    if (familyMemberId != null) {
                      _showNicknameChangeDialog(
                        context,
                        displayName,
                        familyMemberId,
                      );
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      '가족 멤버 별명 설정하기',
                      style: TextStyle(
                        color: const Color(0xFF666666),
                        fontSize: 14,
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w300,
                        letterSpacing: -0.28,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 내 계정인지 확인하는 메서드
  bool _isMyAccount(int? familyMemberId) {
    if (familyMemberId == null || _familyMembers == null) return false;

    // 내 계정에 해당하는 가족 멤버 ID 찾기
    int? myFamilyMemberId;
    for (var member in _familyMembers!) {
      // _userInfo와 member의 정보 비교 (userId 등으로 비교)
      if (_userInfo != null && member['userId'] == _userInfo!['userId']) {
        myFamilyMemberId = member['familyMemberId'];
        break;
      }
    }

    return familyMemberId == myFamilyMemberId;
  }

  // 가족 그룹 나가기 확인 대화상자
  void _showLeaveFamilyConfirmDialog(
    BuildContext context,
    String memberName,
    int familyMemberId,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            '가족 그룹에서 나가기',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              fontFamily: 'Pretendard-Bold',
              color: Color(0xFFFF6B6B),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '정말 이 가족 그룹에서 나가시겠습니까?',
                style: TextStyle(
                  fontSize: 15,
                  fontFamily: 'Pretendard-Regular',
                ),
              ),
              SizedBox(height: 12),
              Text(
                '⚠️ 주의: 가족 그룹에서 나가면 더 이상 이 가족과 관련된 기능을 사용할 수 없게 됩니다.',
                style: TextStyle(
                  fontSize: 13,
                  fontFamily: 'Pretendard-Light',
                  color: Color(0xFFFF6B6B),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text(
                '취소',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                  fontFamily: 'Pretendard-Medium',
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(
                '나가기',
                style: TextStyle(
                  color: Color(0xFFFF6B6B),
                  fontSize: 14,
                  fontFamily: 'Pretendard-Bold',
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _leaveFamily(familyMemberId);
              },
            ),
          ],
        );
      },
    );
  }

  // 가족 그룹 나가기 메서드
  Future<void> _leaveFamily(int familyMemberId) async {
    try {
      setState(() {
        _isLoading = true;
      });

      final result = await FamilyService.leaveFamily(familyMemberId);

      if (result['success']) {
        // 나가기 성공
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('가족 그룹에서 나가기가 완료되었습니다'),
            backgroundColor: Colors.green,
          ),
        );

        // 가족 멤버 목록 새로고침
        await _loadFamilyMembers();
      } else {
        // 나가기 실패
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? '가족 그룹에서 나가기에 실패했습니다'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류가 발생했습니다: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // 닉네임 변경 바텀시트
  void _showNicknameChangeDialog(
    BuildContext context,
    String displayName,
    int familyMemberId,
  ) {
    final TextEditingController nicknameController = TextEditingController();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return Container(
          width: MediaQuery.of(context).size.width,
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 헤더
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: const ShapeDecoration(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                ),
                child: Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    Text(
                      '별명 설정하기',
                      style: TextStyle(
                        color: const Color(0xFF202020),
                        fontSize: 18,
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.72,
                      ),
                    ),
                    Positioned(
                      right: 0,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Image.asset(
                          'assets/icons/my/close.png',
                          width: 24,
                          height: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 입력 영역
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                color: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '새로운 별명',
                      style: TextStyle(
                        fontSize: 14,
                        fontFamily: 'Pretendard-Medium',
                        color: Color(0xFF404040),
                      ),
                    ),
                    SizedBox(height: 8),
                    TextField(
                      controller: nicknameController,
                      decoration: InputDecoration(
                        hintText: displayName,
                        hintStyle: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Color(0xFFDDDDDD)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Color(0xFFDDDDDD)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Color(0xFF3A88F4)),
                        ),
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      '* 변경된 별명은 가족 구성원 모두에게 표시됩니다',
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'Pretendard-Light',
                        color: Color(0xFF999999),
                      ),
                    ),
                    SizedBox(height: 20),
                    // 변경하기 버튼
                    GestureDetector(
                      onTap: () async {
                        if (nicknameController.text.isEmpty) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text('별명을 입력해주세요')));
                          return;
                        }

                        Navigator.pop(context);
                        setState(() {
                          _isLoading = true;
                        });

                        final result = await FamilyService.updateMyNickname(
                          nicknameController.text,
                          familyMemberId: familyMemberId,
                        );

                        if (result != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('별명이 변경되었습니다'),
                              backgroundColor: Colors.green,
                            ),
                          );
                          await _loadFamilyMembers();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('별명 변경에 실패했습니다'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }

                        setState(() {
                          _isLoading = false;
                        });
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: ShapeDecoration(
                          color: const Color(0xFF3A88F4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '변경하기',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontFamily: 'Pretendard-Medium',
                              letterSpacing: -0.28,
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
      },
      isScrollControlled: true,
    );
  }

  // 구독권 변경 모달 대화상자
  void _showSubscriptionChangeModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        // 선택된 구독권 추적 변수
        bool isThreePersonSelected = true;
        bool isFivePersonSelected = false;

        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              insetPadding: EdgeInsets.symmetric(horizontal: 21),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.95,
                padding: EdgeInsets.zero,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: 452),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 메인 헤더 부분
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
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
                            Text(
                              '구독권 변경을 예약할까요?',
                              style: TextStyle(
                                color: const Color(0xFF202020),
                                fontSize: 15.5,
                                fontFamily: 'Pretendard-Bold',
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text('가족 추가는 구독권을 먼저 변경해야 해요!'),
                          ],
                        ),
                      ),

                      // 구독권 옵션 부분
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                        color: Colors.white,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // 3인 구독권
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  isThreePersonSelected = true;
                                  isFivePersonSelected = false;
                                });
                              },
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                margin: const EdgeInsets.only(bottom: 10),
                                decoration: ShapeDecoration(
                                  color: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    side: BorderSide(
                                      width: 1.0,
                                      color: const Color(0xFF146AFF),
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '3인 구독권',
                                            style: TextStyle(
                                              color: const Color(0xFF353535),
                                              fontSize: 12,
                                              fontFamily: 'Pretendard-Light',
                                              letterSpacing: -0.24,
                                            ),
                                          ),
                                          SizedBox(height: 6),
                                          Text.rich(
                                            TextSpan(
                                              children: [
                                                TextSpan(
                                                  text: '₩7,500원',
                                                  style: TextStyle(
                                                    color: const Color(
                                                      0xFF202020,
                                                    ),
                                                    fontSize: 16,
                                                    fontFamily:
                                                        'Pretendard-Bold',
                                                    letterSpacing: -0.64,
                                                  ),
                                                ),
                                                TextSpan(
                                                  text: ' / 월간',
                                                  style: TextStyle(
                                                    color: const Color(
                                                      0xFF666666,
                                                    ),
                                                    fontSize: 13,
                                                    fontFamily:
                                                        'Pretendard-Medium',
                                                    letterSpacing: -0.26,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // 체크 아이콘
                                    if (isThreePersonSelected)
                                      SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: Image.asset(
                                          'assets/icons/check_subs.png',
                                          width: 20,
                                          height: 20,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),

                            // 5인 구독권
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  isThreePersonSelected = false;
                                  isFivePersonSelected = true;
                                });
                              },
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                margin: const EdgeInsets.only(bottom: 10),
                                decoration: ShapeDecoration(
                                  color: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    side: BorderSide(
                                      width: 1.0,
                                      color: const Color(0xFF146AFF),
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '5인 구독권',
                                            style: TextStyle(
                                              color: const Color(0xFF353535),
                                              fontSize: 12,
                                              fontFamily: 'Pretendard-Light',
                                              letterSpacing: -0.24,
                                            ),
                                          ),
                                          SizedBox(height: 6),
                                          Text.rich(
                                            TextSpan(
                                              children: [
                                                TextSpan(
                                                  text: '₩9,500원',
                                                  style: TextStyle(
                                                    color: const Color(
                                                      0xFF202020,
                                                    ),
                                                    fontSize: 16,
                                                    fontFamily:
                                                        'Pretendard-Bold',
                                                    letterSpacing: -0.64,
                                                  ),
                                                ),
                                                TextSpan(
                                                  text: ' / 월간',
                                                  style: TextStyle(
                                                    color: const Color(
                                                      0xFF666666,
                                                    ),
                                                    fontSize: 13,
                                                    fontFamily:
                                                        'Pretendard-Medium',
                                                    letterSpacing: -0.26,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // 체크 아이콘
                                    if (isFivePersonSelected)
                                      SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: Image.asset(
                                          'assets/icons/check_subs.png',
                                          width: 20,
                                          height: 20,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // 구독권 변경 완료 모달 대화상자
  void _showSubscriptionCompleteModal(
    BuildContext context,
    String selectedPlan,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: EdgeInsets.symmetric(horizontal: 21),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.95,
            padding: EdgeInsets.zero,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: 452),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 메인 헤더 부분
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
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
                        Text(
                          '구독권 변경 예약이 완료되었어요!',
                          style: TextStyle(
                            color: const Color(0xFF202020),
                            fontSize: 16,
                            fontFamily: 'Pretendard-Bold',
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text('다음 결제일부터 해당 구독권으로 이용할 수 있어요'),
                      ],
                    ),
                  ),

                  // 구독권 옵션 부분 (이미지로 대체)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    color: Colors.white,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 이미지 컨테이너 - 3인 구독권과 5인 구독권의 자리를 대체
                        SizedBox(
                          width: double.infinity,
                          height: 172, // 두 구독권 선택 박스와 정확히 동일한, 패딩과 마진을 포함한 높이
                          child: Center(
                            child: Image.asset(
                              'assets/icons/my/알람.png',
                              width: 180,
                              height: 180,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 버튼 부분
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: const ShapeDecoration(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(24),
                          bottomRight: Radius.circular(24),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                              // 알림 관련 로직 추가
                            },
                            child: Container(
                              height: 48,
                              decoration: ShapeDecoration(
                                color: const Color(0xFF5D9EFF),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  '잊지않게 알림 받기',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontFamily: 'Pretendard-Medium',
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
            ),
          ),
        );
      },
    );
  }

  // 초대 링크 공유 메서드
  void _shareInvitation() async {
    // 초대 링크 생성 로직 (일반적으로 서버에서 고유 링크를 생성하지만, 여기서는 간단하게 처리)
    final invitationLink = 'http://3.34.52.239:8080/join?invite=family';
    final message = '리틀뱅크에서 함께 이용해요! 가입하려면 링크를 클릭하세요: $invitationLink';

    // 공유 다이얼로그 표시
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: EdgeInsets.symmetric(horizontal: 21),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.95,
            padding: EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '가족 초대하기',
                  style: TextStyle(
                    fontSize: 18,
                    fontFamily: 'Pretendard-Bold',
                    color: const Color(0xFF202020),
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  '아래 방법 중 하나를 선택하여 가족을 초대하세요.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: 'Pretendard-Medium',
                    color: const Color(0xFF666666),
                  ),
                ),
                SizedBox(height: 24),

                // 카카오톡으로 공유 버튼
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    // 여기서 실제로는 카카오톡 SDK를 사용하지만, 지금은 간단히 처리
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('카카오톡으로 초대 링크 공유 기능이 실행됩니다.')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFEE500),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    minimumSize: Size(double.infinity, 48),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/kakao_icon.png',
                        width: 20,
                        height: 20,
                        errorBuilder:
                            (context, error, stackTrace) => Icon(
                              Icons.message,
                              color: Colors.black,
                              size: 20,
                            ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        '카카오톡으로 공유하기',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 14,
                          fontFamily: 'Pretendard-Medium',
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 12),

                // 링크 복사 버튼
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    // 클립보드에 링크 복사
                    // 실제 구현시 clipboard 패키지 사용
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('초대 링크가 클립보드에 복사되었습니다.')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3A88F4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    minimumSize: Size(double.infinity, 48),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.copy, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text(
                        '링크 복사하기',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontFamily: 'Pretendard-Medium',
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 12),

                // 취소 버튼
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    '취소',
                    style: TextStyle(
                      color: const Color(0xFF999999),
                      fontSize: 14,
                      fontFamily: 'Pretendard-Medium',
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// 말풍선 꼬리를 그리는 CustomPainter (위쪽을 향함)
class _BubbleTailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = const Color(0xFF5D9EFF)
          ..style = PaintingStyle.fill;

    final path =
        Path()
          ..moveTo(size.width / 2 - 6, size.height)
          ..lineTo(size.width / 2, 0)
          ..lineTo(size.width / 2 + 6, size.height)
          ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
