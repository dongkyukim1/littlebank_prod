import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/auth_service.dart';
import 'set/status_message_edit_screen.dart';
import 'set/chat_background_settings_screen.dart';
import 'blocked_friends_screen.dart';

class ChatSettingsScreen extends StatefulWidget {
  const ChatSettingsScreen({super.key});

  @override
  State<ChatSettingsScreen> createState() => _ChatSettingsScreenState();
}

class _ChatSettingsScreenState extends State<ChatSettingsScreen> {
  // 스위치 상태 변수들
  bool _isProfilePublic = true;
  bool _isMessageNotificationEnabled = false;
  bool _isMissionNotificationEnabled = false;
  bool _isDoNotDisturbEnabled = true;
  bool _isReadReceiptEnabled = false;

  // 사용자 정보
  Map<String, dynamic>? _userInfo;
  bool _isLoading = true;
  String? _errorMessage;
  
  // 배경 선택 상태
  String? _selectedBackground;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  // 사용자 정보 로드
  Future<void> _loadUserInfo() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userInfo = await AuthService.getUserInfo();

      setState(() {
        _userInfo = userInfo;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '사용자 정보를 불러오는 데 실패했습니다';
        _isLoading = false;
      });
      print('사용자 정보 로딩 오류: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          '채팅 설정',
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontFamily: 'Pretendard-Bold',
          ),
        ),
        leading: IconButton(
          icon: Image.asset('assets/images/뒤로가기.png', width: 24, height: 24),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body:
          _isLoading
              ? Center(
                child: CircularProgressIndicator(color: Color(0xFF3A88F4)),
              )
              : _errorMessage != null
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _errorMessage!,
                      style: TextStyle(
                        color: Color(0xFF666666),
                        fontSize: 16,
                        fontFamily: 'Pretendard-Regular',
                      ),
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadUserInfo,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF3A88F4),
                      ),
                      child: Text('다시 시도'),
                    ),
                  ],
                ),
              )
              : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 8),

                    // 프로필 설정 섹션
                    _buildSectionTitle('프로필 설정'),
                    _buildSectionContainer([
                      _buildProfileSettingItem(),
                      _buildThinDivider(),
                      _buildProfilePublicItem(),
                    ]),

                    _buildSectionDivider(),

                    // 알림 설정 섹션
                    _buildSectionTitle('알림 설정'),
                    _buildSectionContainer([
                      _buildNotificationItem(
                        '메시지 알림',
                        '메시지가 올 때마다 알려드릴게요',
                        _isMessageNotificationEnabled,
                        (value) => setState(
                          () => _isMessageNotificationEnabled = value,
                        ),
                      ),
                      _buildThinDivider(),
                      _buildNotificationItem(
                        '미션 알림',
                        '미션이 올 때마다 알려드릴게요',
                        _isMissionNotificationEnabled,
                        (value) => setState(
                          () => _isMissionNotificationEnabled = value,
                        ),
                      ),
                      _buildNotificationItem(
                        '방해 금지 모드',
                        '모든 알림을 차단합니다',
                        _isDoNotDisturbEnabled,
                        (value) =>
                            setState(() => _isDoNotDisturbEnabled = value),
                      ),
                    ]),

                    _buildSectionDivider(),

                    // 친구관리 섹션
                    _buildSectionTitle('친구관리'),
                    _buildSectionContainer([
                      _buildBlockedFriendManagementItem(),
                    ]),

                    _buildSectionDivider(),

                    // 채팅 설정 섹션
                    _buildSectionTitle('채팅 설정'),
                    _buildSectionContainer([
                      _buildChatBackgroundItem(),
                      _buildThinDivider(),
                      _buildReadReceiptItem(),
                    ]),

                    _buildSectionDivider(),

                    SizedBox(height: 150),
                  ],
                ),
              ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(28, 12, 16, 12),
          child: Text(
            title,
            style: TextStyle(
              color: const Color(0xFF202020),
              fontSize: 18,
              fontFamily: 'Pretendard-Bold',
              letterSpacing: -0.72,
            ),
          ),
        ),
        Container(
          width: double.infinity,
          height: 1,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(color: const Color(0xFF8590A3)),
        ),
        SizedBox(height: 8),
      ],
    );
  }

  Widget _buildSectionContainer(List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildSectionDivider() {
    return Container(
      width: double.infinity,
      height: 12,
      decoration: ShapeDecoration(
        color: const Color(0xFFE7ECF6),
        shape: RoundedRectangleBorder(
          side: BorderSide(width: 0.10, color: const Color(0xFF8490A3)),
        ),
      ),
    );
  }

  Widget _buildThinDivider() {
    return Container(
      width: double.infinity,
      height: 0.5,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: const Color(0xFF8590A3),
    );
  }

  Widget _buildProfileSettingItem() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '상태 메시지 설정',
                  style: TextStyle(
                    color: const Color(0xFF202020),
                    fontSize: 16,
                    fontFamily: 'Pretendard-Bold',
                    letterSpacing: -0.32,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '현재 내 상태를 메시지로 표현할 수 있어요',
                  style: TextStyle(
                    color: const Color(0xFF666666),
                    fontSize: 12,
                    fontFamily: 'Pretendard-Light',
                    letterSpacing: -0.24,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          SizedBox(width: 12),
          GestureDetector(
            onTap: () {
              _showStatusMessageBottomSheet(context);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: ShapeDecoration(
                color: const Color(0xFFE7ECF6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(
                '설정하기',
                style: TextStyle(
                  color: const Color(0xFF8490A3),
                  fontSize: 11,
                  fontFamily: 'Pretendard-Light',
                  letterSpacing: -0.22,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfilePublicItem() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '프로필 공개',
                  style: TextStyle(
                    color: const Color(0xFF202020),
                    fontSize: 16,
                    fontFamily: 'Pretendard-Bold',
                    letterSpacing: -0.32,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '프로필 공개 여부를 선택해 주세요',
                  style: TextStyle(
                    color: const Color(0xFF666666),
                    fontSize: 12,
                    fontFamily: 'Pretendard-Light',
                    letterSpacing: -0.24,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          SizedBox(width: 12),
          _buildCustomSwitch(_isProfilePublic, (value) {
            setState(() => _isProfilePublic = value);
          }),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: const Color(0xFF202020),
                    fontSize: 16,
                    fontFamily: 'Pretendard-Bold',
                    letterSpacing: -0.32,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: const Color(0xFF666666),
                    fontSize: 12,
                    fontFamily: 'Pretendard-Light',
                    letterSpacing: -0.24,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          SizedBox(width: 12),
          _buildCustomSwitch(value, onChanged),
        ],
      ),
    );
  }

  Widget _buildChatBackgroundItem() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '채팅방 배경 설정',
                  style: TextStyle(
                    color: const Color(0xFF202020),
                    fontSize: 16,
                    fontFamily: 'Pretendard-Bold',
                    letterSpacing: -0.32,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '다양한 배경 설정이 가능해요',
                  style: TextStyle(
                    color: const Color(0xFF666666),
                    fontSize: 12,
                    fontFamily: 'Pretendard-Light',
                    letterSpacing: -0.24,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          SizedBox(width: 12),
          GestureDetector(
            onTap: () {
              _showChatBackgroundBottomSheet(context);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: ShapeDecoration(
                color: const Color(0xFFE7ECF6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(
                '설정하기',
                style: TextStyle(
                  color: const Color(0xFF8490A3),
                  fontSize: 11,
                  fontFamily: 'Pretendard-Light',
                  letterSpacing: -0.22,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadReceiptItem() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '읽음 표시',
                  style: TextStyle(
                    color: const Color(0xFF202020),
                    fontSize: 16,
                    fontFamily: 'Pretendard-Bold',
                    letterSpacing: -0.32,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '메시지 읽음 표시를 노출할지 선택해 주세요',
                  style: TextStyle(
                    color: const Color(0xFF666666),
                    fontSize: 12,
                    fontFamily: 'Pretendard-Light',
                    letterSpacing: -0.24,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          SizedBox(width: 12),
          _buildCustomSwitch(_isReadReceiptEnabled, (value) {
            setState(() => _isReadReceiptEnabled = value);
          }),
        ],
      ),
    );
  }

  Widget _buildBlockedFriendManagementItem() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BlockedFriendsScreen(),
            ),
          );
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '차단한 친구 관리',
                    style: TextStyle(
                      color: const Color(0xFF202020),
                      fontSize: 16,
                      fontFamily: 'Pretendard-Bold',
                      letterSpacing: -0.32,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '차단한 친구 목록을 확인하고 차단을 해제할 수 있어요',
                    style: TextStyle(
                      color: const Color(0xFF666666),
                      fontSize: 12,
                      fontFamily: 'Pretendard-Light',
                      letterSpacing: -0.24,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            SizedBox(width: 12),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Color(0xFF8490A3),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomSwitch(bool value, Function(bool) onChanged) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        width: 60,
        height: 32,
        child: Stack(
          children: [
            Positioned(
              left: 0,
              top: 0,
              child: Container(
                width: 60,
                height: 32,
                decoration: ShapeDecoration(
                  color:
                      value ? const Color(0xFF10CB86) : const Color(0xFFB6B6B6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            Positioned(
              left: value ? 30 : 2,
              top: 2,
              child: Container(
                width: 28,
                height: 28,
                decoration: ShapeDecoration(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  shadows: [
                    BoxShadow(
                      color: Color(0x38000000),
                      blurRadius: 3,
                      offset: Offset(3, 3),
                      spreadRadius: 0,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showChatBackgroundBottomSheet(BuildContext context) {
    setState(() {
      _selectedBackground = null;
    });
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          return _buildChatBackgroundBottomSheet(setModalState);
        },
      ),
    );
  }

  Widget _buildChatBackgroundBottomSheet(StateSetter setModalState) {
    return Container(
      width: double.infinity,
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 상단 헤더
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '채팅방 배경을 설정해 주세요',
                    style: TextStyle(
                      color: const Color(0xFF202020),
                      fontSize: 18,
                      fontFamily: 'Pretendard-Bold',
                      letterSpacing: -0.72,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 24,
                      height: 24,
                      child: Image.asset(
                        'assets/icons/background_chat/close.png',
                        width: 24,
                        height: 24,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.close,
                            color: Color(0xFF999999),
                            size: 20,
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // 배경 선택 영역
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  // 기본 배경 (앨범)
                  GestureDetector(
                    onTap: () {
                      setModalState(() {
                        _selectedBackground = 'default';
                      });
                    },
                    child: Opacity(
                      opacity: _selectedBackground == null || _selectedBackground == 'default' ? 1.0 : 0.4,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: ShapeDecoration(
                              color: const Color(0xFFE7ECF6),
                              shape: OvalBorder(
                                side: _selectedBackground == 'default' 
                                  ? BorderSide(color: Color(0xFF5D9EFF), width: 3)
                                  : BorderSide.none,
                              ),
                            ),
                            child: Center(
                              child: Image.asset(
                                'assets/icons/background_chat/album.png',
                                width: 24,
                                height: 24,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(
                                    Icons.photo_library,
                                    color: Color(0xFF8490A3),
                                    size: 24,
                                  );
                                },
                              ),
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            '기본',
                            style: TextStyle(
                              color: _selectedBackground == 'default' 
                                ? Color(0xFF5D9EFF)
                                : Color(0xFF8490A3),
                              fontSize: 12,
                              fontFamily: 'Pretendard-Light',
                              letterSpacing: -0.24,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  SizedBox(width: 24),
                  
                  // 배경 1
                  GestureDetector(
                    onTap: () {
                      setModalState(() {
                        _selectedBackground = 'background_1';
                      });
                    },
                    child: Opacity(
                      opacity: _selectedBackground == null || _selectedBackground == 'background_1' ? 1.0 : 0.4,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: ShapeDecoration(
                              image: DecorationImage(
                                image: AssetImage('assets/icons/background_chat/background_1.png'),
                                fit: BoxFit.cover,
                              ),
                              shape: OvalBorder(
                                side: _selectedBackground == 'background_1' 
                                  ? BorderSide(color: Color(0xFF5D9EFF), width: 3)
                                  : BorderSide.none,
                              ),
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            '배경1',
                            style: TextStyle(
                              color: _selectedBackground == 'background_1' 
                                ? Color(0xFF5D9EFF)
                                : Color(0xFF8490A3),
                              fontSize: 12,
                              fontFamily: 'Pretendard-Light',
                              letterSpacing: -0.24,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  SizedBox(width: 24),
                  
                  // 배경 2  
                  GestureDetector(
                    onTap: () {
                      setModalState(() {
                        _selectedBackground = 'background_2';
                      });
                    },
                    child: Opacity(
                      opacity: _selectedBackground == null || _selectedBackground == 'background_2' ? 1.0 : 0.4,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: ShapeDecoration(
                              image: DecorationImage(
                                image: AssetImage('assets/icons/background_chat/background_2.png'),
                                fit: BoxFit.cover,
                              ),
                              shape: OvalBorder(
                                side: _selectedBackground == 'background_2' 
                                  ? BorderSide(color: Color(0xFF5D9EFF), width: 3)
                                  : BorderSide.none,
                              ),
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            '배경2',
                            style: TextStyle(
                              color: _selectedBackground == 'background_2' 
                                ? Color(0xFF5D9EFF)
                                : Color(0xFF8490A3),
                              fontSize: 12,
                              fontFamily: 'Pretendard-Light',
                              letterSpacing: -0.24,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // 하단 저장 버튼
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: GestureDetector(
                onTap: _selectedBackground != null ? () => _saveBackgroundAndClose(_selectedBackground!) : null,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: ShapeDecoration(
                    color: _selectedBackground != null ? const Color(0xFF5D9EFF) : const Color(0xFFE7ECF6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(
                    _selectedBackground != null ? '저장하기' : '위에서 배경을 선택해 주세요',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _selectedBackground != null ? Colors.white : const Color(0xFF8490A3),
                      fontSize: 14,
                      fontFamily: 'Pretendard-Light',
                      letterSpacing: -0.28,
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

  Future<void> _saveBackgroundAndClose(String backgroundId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('chat_background', backgroundId);
      
      setState(() {
        _selectedBackground = null;
      });
      
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '채팅방 배경이 변경되었습니다.',
            style: TextStyle(
              fontFamily: 'Pretendard-Regular',
              color: Colors.white,
            ),
          ),
          backgroundColor: Color(0xFF146AFF),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('배경 설정 저장 중 오류: $e');
      setState(() {
        _selectedBackground = null;
      });
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '배경 설정 저장에 실패했습니다.',
            style: TextStyle(
              fontFamily: 'Pretendard-Regular',
              color: Colors.white,
            ),
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _showStatusMessageBottomSheet(BuildContext context) {
    final TextEditingController controller = TextEditingController(
      text: _userInfo?['statusMessage'] ?? '',
    );
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          return _buildStatusMessageBottomSheet(controller, setModalState);
        },
      ),
    );
  }

  Widget _buildStatusMessageBottomSheet(TextEditingController controller, StateSetter setModalState) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final keyboardHeight = mediaQuery.viewInsets.bottom;
    
    // 반응형 크기 계산 - 저장하기 버튼이 보이도록 충분한 높이
    final double bottomSheetHeight = keyboardHeight > 0 
        ? 280.0 + keyboardHeight // 키보드가 올라왔을 때 충분한 높이
        : 280.0; // 저장하기 버튼이 보이는 충분한 고정 높이
    
    return Container(
      width: screenWidth,
      height: bottomSheetHeight,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            child: Container(
              width: screenWidth,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: ShapeDecoration(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(24),
                          topRight: Radius.circular(24),
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            '상태 메시지를 설정해 주세요',
                            style: TextStyle(
                              color: const Color(0xFF202020),
                              fontSize: 18,
                              fontFamily: 'Pretendard-Bold',
                              letterSpacing: -0.72,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 24,
                            height: 24,
                            child: Icon(
                              Icons.close,
                              color: Color(0xFF999999),
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: screenWidth,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(color: Colors.white),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '현재 기분과 상태를 메시지를 통해 표현해 보세요',
                          style: TextStyle(
                            color: const Color(0xFF999999),
                            fontSize: 14,
                            fontFamily: 'Pretendard-Light',
                            letterSpacing: -0.28,
                          ),
                        ),
                        SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          child: TextField(
                            controller: controller,
                            maxLength: 30,
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: '상태 메시지를 입력하세요',
                              hintStyle: TextStyle(
                                color: const Color(0xFFC4C4C4),
                                fontSize: 18,
                                fontFamily: 'Pretendard-Light',
                                letterSpacing: -0.72,
                              ),
                              counterText: '',
                              suffixIcon: controller.text.isNotEmpty
                                  ? GestureDetector(
                                      onTap: () {
                                        controller.clear();
                                        setModalState(() {});
                                      },
                                      child: Container(
                                        width: 32,
                                        height: 32,
                                        alignment: Alignment.center,
                                        padding: EdgeInsets.only(right: 8, top: 4),
                                        child: Image.asset(
                                          'assets/icons/Icon/chat/삭제하기.png',
                                          width: 24,
                                          height: 24,
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                            style: TextStyle(
                              color: const Color(0xFF202020),
                              fontSize: 18,
                              fontFamily: 'Pretendard-Bold',
                              letterSpacing: -0.72,
                            ),
                            onChanged: (value) {
                              setModalState(() {});
                            },
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '${controller.text.length}/30',
                            style: TextStyle(
                              color: const Color(0xFFC4C4C4),
                              fontSize: 11,
                              fontFamily: 'Pretendard-Light',
                              letterSpacing: -0.22,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(color: Colors.white),
                    child: GestureDetector(
                      onTap: () => _saveStatusMessage(controller.text.trim()),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: ShapeDecoration(
                          color: const Color(0xFF5D9EFF),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Center(
                          child: Text(
                            '저장하기',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
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
        ],
      ),
    );
  }

  Future<void> _saveStatusMessage(String statusMessage) async {
    try {
      // AuthService API 호출
      final result = await AuthService.updateStatusMessage(
        statusMessage: statusMessage,
      );
      
      if (result != null) {
        // 성공 시 로컬 사용자 정보 업데이트
        setState(() {
          if (_userInfo != null) {
            _userInfo!['statusMessage'] = statusMessage;
          }
        });
        
        Navigator.pop(context);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '상태 메시지가 저장되었습니다.',
              style: TextStyle(
                fontFamily: 'Pretendard-Regular',
                color: Colors.white,
              ),
            ),
            backgroundColor: Color(0xFF146AFF),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: EdgeInsets.all(16),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('상태 메시지 저장 중 오류: $e');
      
      // 에러 메시지 표시
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().contains('Exception:') 
                ? e.toString().replaceAll('Exception: ', '')
                : '상태 메시지 저장 중 오류가 발생했습니다.',
            style: TextStyle(
              fontFamily: 'Pretendard-Regular',
              color: Colors.white,
            ),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: EdgeInsets.all(16),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }
}
