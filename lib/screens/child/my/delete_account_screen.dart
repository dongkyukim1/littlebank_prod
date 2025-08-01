import 'package:flutter/material.dart';
import '../../../services/auth_service.dart';
import '../../../widgets/common/bottom_navigation_bar.dart';
import '../../common/splash/splash_manager.dart';
import '../../common/login_screen.dart';
import '../my_page_screen.dart';
import 'cs/usage_inquiry_screen.dart';
import 'cs/suggestion_screen.dart';
import 'cs/customer_service_screen.dart';
import '../benefit/little_bank_benefits_screen.dart';

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen>
    with TickerProviderStateMixin {
  bool _isConfirmed = false;
  bool _isLoading = false;
  String? _errorMessage;
  String? _selectedReason;
  String _reasonText = '';
  String _userName = '리틀'; // 기본값
  bool _isLoadingUserInfo = true;
  final TextEditingController _reasonController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _reasonSectionKey = GlobalKey();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final List<Map<String, String>> _reasons = [
    {
      'text': '서비스 사용을 잘 안하게 돼요',
      'icon': 'assets/icons/Icon/delete/feedback.png',
    },
    {
      'text': '미션, 챌린지 등 서비스 이용이 어려워요',
      'icon': 'assets/icons/Icon/delete/report.png',
    },
    {
      'text': '원하는 기능이나 정보가 없어요',
      'icon': 'assets/icons/Icon/delete/feedback.png',
    },
    {'text': '앱이 느리거나 오류가 잦아요', 'icon': 'assets/icons/Icon/delete/report.png'},
    {
      'text': '비슷한 다른 서비스를 이용 중이예요',
      'icon': 'assets/icons/Icon/delete/money.png',
    },
    {'text': '기타', 'icon': 'assets/icons/Icon/delete/feedback.png'},
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _loadUserInfo();
    _animationController.forward();
  }

  // 사용자 정보 불러오기
  Future<void> _loadUserInfo() async {
    try {
      final userInfo = await AuthService.getUserInfo();
      if (mounted) {
        setState(() {
          _userName = userInfo['name'] ?? '리틀';
          _isLoadingUserInfo = false;
        });
      }
    } catch (e) {
      print('사용자 정보 로딩 오류: $e');
      if (mounted) {
        setState(() {
          _userName = '리틀'; // 기본값 유지
          _isLoadingUserInfo = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _reasonController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isTablet = screenWidth > 600;

    return Scaffold(
      backgroundColor: Colors.white,
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF146AFF)),
              )
              : FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: isTablet ? 600 : double.infinity,
                      ),
                      margin:
                          isTablet
                              ? EdgeInsets.symmetric(
                                horizontal: (screenWidth - 600) / 2,
                              )
                              : EdgeInsets.zero,
                      child: Column(
                        children: [
                          // 헤더 (뒤로가기 버튼)
                          Container(
                            width: double.infinity,
                            height: 56,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.arrow_back_ios,
                                    color: Colors.black,
                                    size: 18,
                                  ),
                                  onPressed: () => Navigator.of(context).pop(),
                                ),
                              ],
                            ),
                          ),

                          // 상단 이미지와 말풍선
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Column(
                              children: [
                                // 말풍선
                                Container(
                                  width: 130,
                                  height: 42,
                                  child: Stack(
                                    children: [
                                      // 말풍선 박스
                                      Positioned(
                                        left: 0,
                                        top: 0,
                                        child: Container(
                                          width: 130,
                                          height: 32,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                          decoration: ShapeDecoration(
                                            color: const Color(0xFF5D9EFF),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                          child: Center(
                                            child: Text(
                                              '정말 탈퇴하시겠어요?',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 11,
                                                fontFamily: 'Pretendard-Light',
                                                height: 1.45,
                                                letterSpacing: -0.22,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      // 말풍선 꼬리 (삼각형)
                                      Positioned(
                                        left: 65 - 5,
                                        top: 32,
                                        child: CustomPaint(
                                          size: Size(10, 8),
                                          painter: _TrianglePainter(),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // 이미지
                                Container(
                                  width: screenWidth * 0.4,
                                  height: screenWidth * 0.34,
                                  child: Image.asset(
                                    'assets/icons/Icon/delete/logo.png',
                                    width: screenWidth * 0.3,
                                    height: screenWidth * 0.3,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 32),

                          // 메인 콘텐츠
                          Column(
                            children: [
                              // 탈퇴하기 전 확인 섹션
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      '탈퇴하기 전 꼭 읽어주세요',
                                      style: TextStyle(
                                        color: Color(0xFF202020),
                                        fontSize: 18,
                                        fontFamily: 'Pretendard-Bold',
                                        height: 1.50,
                                        letterSpacing: -0.72,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _isLoadingUserInfo
                                          ? '이대로 탈퇴한다면 사용자님이 활약했던 기록들과 함께 활동했던 소중한 순간들이 사라져요.'
                                          : '이대로 탈퇴한다면 ${_userName}님이 활약했던 기록들과 함께 활동했던 소중한 순간들이 사라져요.',
                                      style: const TextStyle(
                                        color: Color(0xFF999999),
                                        fontSize: 12,
                                        fontFamily: 'Pretendard-Light',
                                        height: 1.50,
                                        letterSpacing: -0.28,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // 서비스 기능 소개 카드
                              Container(
                                width: double.infinity,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE7ECF6),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  children: [
                                    _buildFeatureItem(
                                      '성취에 따라 보상받을 수 있던 미션',
                                      '부모님에게 미션을 받고 자녀는 보상금과 격려를 통해 성장할 수 있어요.',
                                      'assets/icons/Icon/delete/mission.png',
                                    ),
                                    const SizedBox(height: 20),
                                    _buildFeatureItem(
                                      '각자의 자리에서 따로 또 함께 달렸던 챌린지',
                                      '직접 원하는 챌린지를 신청하여 멀리서도 다른 친구들과 함께 경쟁하고 보상받을 수 있어요.',
                                      'assets/icons/Icon/delete/challenge.png',
                                    ),
                                    const SizedBox(height: 20),
                                    _buildFeatureItem(
                                      '혼자서도 성장을 위해 노력할 수 있던 목표',
                                      '꾸준한 습관 형성을 위해 매주 최대 두개의 목표를 설정하고 추가적인 보상도 받을 수 있어요.',
                                      'assets/icons/Icon/delete/goal.png',
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 32),

                              // 구분선
                              Container(
                                width: double.infinity,
                                height: 12,
                                color: const Color(0xFFE7ECF6),
                              ),

                              const SizedBox(height: 32),

                              // 탈퇴 이유 섹션
                              Container(
                                key: _reasonSectionKey,
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      '리틀뱅크를 떠나시는 이유가 있나요?',
                                      style: TextStyle(
                                        color: Color(0xFF202020),
                                        fontSize: 16,
                                        fontFamily: 'Pretendard-Bold',
                                        letterSpacing: -0.72,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      '고객님이 주신 소중한 의견을 바탕으로, 더욱 노력하는 리틀뱅크가 되겠습니다.',
                                      style: TextStyle(
                                        color: Color(0xFF999999),
                                        fontSize: 12,
                                        fontFamily: 'Pretendard-Light',
                                        height: 1.5,
                                        letterSpacing: -0.56,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // 탈퇴 이유 목록
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                child: Column(
                                  children: [
                                    // 각 탈퇴 이유별로 개별 처리
                                    ..._reasons.asMap().entries.map((entry) {
                                      int index = entry.key;
                                      String reason = entry.value['text']!;
                                      return Column(
                                        children: [
                                          _buildReasonItem(reason, index),
                                          // 각 이유별 추가 섹션
                                          if (_selectedReason == reason) ...[
                                            const SizedBox(height: 16),
                                            _buildReasonSpecificSection(reason),
                                            const SizedBox(height: 24),
                                          ],
                                        ],
                                      );
                                    }).toList(),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 32),

                              // 구분선
                              Container(
                                width: double.infinity,
                                height: 12,
                                color: const Color(0xFFE7ECF6),
                              ),

                              const SizedBox(height: 32),

                              // 마지막 확인 섹션
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      '마지막으로 탈퇴하기 전 한 번 더 확인해 주세요',
                                      style: TextStyle(
                                        color: Color(0xFF202020),
                                        fontSize: 16,
                                        fontFamily: 'Pretendard-Bold',
                                        letterSpacing: -0.72,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      '이용 중인 서비스와 활동했던 기록은 사용자님이 직접 해지 및 삭제해주셔야 합니다.',
                                      style: TextStyle(
                                        color: Color(0xFF999999),
                                        fontSize: 12,
                                        fontFamily: 'Pretendard-Light',
                                        height: 1.5,
                                        letterSpacing: -0.56,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // 확인 사항들
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                child: Column(
                                  children: [
                                    _buildCheckItem(
                                      '남은 포인트가 있다면 다른 계좌로 미리 보내주세요',
                                      '남은 포인트는 자동으로 등록된 계좌로 환불되지 않아요. 다른 계좌로 미리 잔액을 보내주세요.',
                                    ),
                                    const SizedBox(height: 12),
                                    _buildCheckItem(
                                      '이용 중인 구독권이 있다면 해지해 주세요',
                                      '이용 중인 구독권이 있다면 탈퇴 시 자동적으로 삭제되지 않아요. 탈퇴하기 전 꼭 해지해 주세요.',
                                    ),
                                    const SizedBox(height: 12),
                                    _buildCheckItem(
                                      '등록된 피드는 개별적으로 삭제가 필요해요',
                                      '등록된 피드는 탈퇴 시 자동적으로 삭제되지 않아요. 탈퇴하기 전 꼭 개별적으로 삭제해 주세요',
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 32),

                              // 구분선
                              Container(
                                width: double.infinity,
                                height: 12,
                                color: const Color(0xFFE7ECF6),
                              ),

                              // 에러 메시지
                              if (_errorMessage != null)
                                Container(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 16,
                                  ),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF0F0),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: const Color(0xFFFFCCCC),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Icon(
                                        Icons.error_outline,
                                        color: Color(0xFFFF5252),
                                        size: 16,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _errorMessage!,
                                          style: const TextStyle(
                                            color: Color(0xFFFF5252),
                                            fontSize: 10,
                                            fontFamily: 'Pretendard-Regular',
                                            letterSpacing: -0.24,
                                            height: 1.3,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                              SizedBox(
                                height:
                                    MediaQuery.of(context).padding.bottom + 120,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

      // 하단 고정 버튼
      bottomNavigationBar: Container(
        width: double.infinity,
        padding: const EdgeInsets.only(top: 16),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 11,
              offset: Offset(0, -4),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 동의 체크박스
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  InkWell(
                    onTap: () {
                      // 탈퇴 이유가 선택되지 않은 경우 탈퇴 이유 섹션으로 스크롤
                      if (_selectedReason == null && !_isConfirmed) {
                        _scrollToReasonSection();
                        return;
                      }
                      setState(() {
                        _isConfirmed = !_isConfirmed;
                      });
                    },
                    child: Row(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          child: Image.asset(
                            _isConfirmed
                                ? 'assets/icons/Icon/delete/fill_check.png'
                                : 'assets/icons/Icon/delete/empty_check.png',
                            width: 20,
                            height: 20,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color:
                                        _isConfirmed
                                            ? const Color(0xFF146AFF)
                                            : const Color(0xFF999999),
                                    width: 1.5,
                                  ),
                                  color:
                                      _isConfirmed
                                          ? const Color(0xFF146AFF)
                                          : Colors.white,
                                ),
                                child:
                                    _isConfirmed
                                        ? const Icon(
                                          Icons.check,
                                          color: Colors.white,
                                          size: 14,
                                        )
                                        : null,
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          '안내사항을 모두 확인했고 탈퇴에 동의합니다',
                          style: TextStyle(
                            color: Color(0xFF999999),
                            fontSize: 12,
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
            const SizedBox(height: 12),
            // 탈퇴하기 버튼
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color:
                    _isConfirmed
                        ? const Color(0xFF146AFF)
                        : const Color(0xFFDADADA),
              ),
              child: InkWell(
                onTap: _isConfirmed ? _onDeleteAccountPressed : null,
                child: const Text(
                  '탈퇴하기',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontFamily: 'Pretendard-Bold',
                    letterSpacing: -0.72,
                  ),
                ),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  // 탈퇴 이유 섹션으로 스크롤 이동
  void _scrollToReasonSection() {
    if (_reasonSectionKey.currentContext != null) {
      Scrollable.ensureVisible(
        _reasonSectionKey.currentContext!,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        alignment: 0.1, // 화면 상단에서 10% 위치에 표시
      );

      // 스크롤 후 약간의 시각적 효과 추가
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('먼저 탈퇴 이유를 선택해주세요'),
              duration: Duration(seconds: 2),
              backgroundColor: Color(0xFF146AFF),
            ),
          );
        }
      });
    }
  }

  Widget _buildFeatureItem(String title, String description, String iconPath) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Image.asset(
          iconPath,
          width: 48,
          height: 48,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFF0F0F0),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.star_outline,
                color: Color(0xFF001F55),
                size: 24,
              ),
            );
          },
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF001F55),
                  fontSize: 14,
                  fontFamily: 'Pretendard-Bold',
                  letterSpacing: -0.28,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                  color: Color(0xFF8490A3),
                  fontSize: 12,
                  fontFamily: 'Pretendard-Light',
                  height: 1.5,
                  letterSpacing: -0.24,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReasonItem(String text, int index) {
    final isSelected = _selectedReason == text;

    return AnimatedContainer(
      duration: Duration(milliseconds: 200 + (index * 30)),
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedReason = isSelected ? null : text;
          });
        },
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              child: Image.asset(
                isSelected
                    ? 'assets/icons/Icon/delete/fill_check.png'
                    : 'assets/icons/Icon/delete/empty_check.png',
                width: 20,
                height: 20,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color:
                            isSelected
                                ? const Color(0xFF146AFF)
                                : const Color(0xFF999999),
                        width: 1.5,
                      ),
                      color:
                          isSelected ? const Color(0xFF146AFF) : Colors.white,
                    ),
                    child:
                        isSelected
                            ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 14,
                            )
                            : null,
                  );
                },
              ),
            ),
            const SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(
                color:
                    isSelected
                        ? const Color(0xFF146AFF)
                        : const Color(0xFF999999),
                fontSize: 12,
                fontFamily:
                    isSelected ? 'Pretendard-Medium' : 'Pretendard-Light',
                letterSpacing: -0.28,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReasonSpecificSection(String reason) {
    if (reason == '기타') {
      // 기타는 입력 필드만
      return Container(
        width: double.infinity,
        height: 80,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFE7ECF6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: TextField(
          controller: _reasonController,
          maxLines: 2,
          onChanged: (value) {
            setState(() {
              _reasonText = value;
            });
          },
          decoration: const InputDecoration(
            hintText:
                '선택하신 이유에 대해 자세하게 알려주세요. 고객님의 소중한 의견을 바탕으로 더 나은 서비스를 만들어 가겠습니다.',
            hintStyle: TextStyle(
              color: Color(0xFF8490A3),
              fontSize: 11,
              fontFamily: 'Pretendard-Light',
              height: 1.50,
              letterSpacing: -0.24,
            ),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            disabledBorder: InputBorder.none,
            errorBorder: InputBorder.none,
            focusedErrorBorder: InputBorder.none,
            contentPadding: EdgeInsets.zero,
            counterText: '',
            fillColor: Colors.transparent,
            filled: false,
          ),
          style: const TextStyle(
            color: Color(0xFF202020),
            fontSize: 11,
            fontFamily: 'Pretendard-Regular',
            letterSpacing: -0.28,
          ),
        ),
      );
    } else {
      // 1~5번은 제안 섹션만
      return _buildSuggestionSection();
    }
  }

  Widget _buildSuggestionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '이렇게 해보면 어떨까요?',
          style: TextStyle(
            color: Color(0xFFFFA63D),
            fontSize: 12,
            fontFamily: 'Pretendard-Bold',
            letterSpacing: -0.28,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          '고객센터에서 사용자님의 소중한 의견을 바탕으로 더 나은 서비스를 만들어 가고자 합니다. 피드백 보내기에서 기능 관련 제안과 불편했던 점을 작성해 주시면\n귀기울여 듣겠습니다.',
          style: TextStyle(
            color: Color(0xFF666666),
            fontSize: 10,
            fontFamily: 'Pretendard-Light',
            height: 1.5,
            letterSpacing: -0.24,
          ),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: () => _navigateToReasonScreen(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFE7ECF6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '고객센터 바로가기',
                  style: TextStyle(
                    color: Color(0xFF001F55),
                    fontSize: 9,
                    fontFamily: 'Pretendard-Light',
                    letterSpacing: -0.22,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 10,
                  color: Color(0xFF001F55),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // 탈퇴 이유에 따른 화면 이동
  void _navigateToReasonScreen() {
    switch (_selectedReason) {
      case '서비스 사용을 잘 안하게 돼요':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MyPageScreen()),
        );
        break;
      case '미션, 챌린지 등 서비스 이용이 어려워요':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const UsageInquiryScreen()),
        );
        break;
      case '원하는 기능이나 정보가 없어요':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SuggestionScreen()),
        );
        break;
      case '앱이 느리거나 오류가 잦아요':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const CustomerServiceScreen(),
          ),
        );
        break;
      case '비슷한 다른 서비스를 이용 중이예요':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const LittleBankBenefitsScreen(),
          ),
        );
        break;
      default:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const CustomerServiceScreen(),
          ),
        );
        break;
    }
  }

  Widget _buildCheckItem(String title, String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF202020),
            fontSize: 14,
            fontFamily: 'Pretendard-Bold',
            letterSpacing: -0.32,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          description,
          style: const TextStyle(
            color: Color(0xFF8490A3),
            fontSize: 12,
            fontFamily: 'Pretendard-Light',
            height: 1.5,
            letterSpacing: -0.28,
          ),
        ),
      ],
    );
  }

  // 회원탈퇴 버튼 클릭 핸들러
  Future<void> _onDeleteAccountPressed() async {
    // 최종 확인 모달 표시
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.5,
      ),
      builder:
          (context) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 32,
                    height: 3,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(1.5),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Color(0xFFFF5252),
                    size: 40,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '정말 탈퇴하시겠어요?',
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'Pretendard-Bold',
                      color: Color(0xFF202020),
                      letterSpacing: -0.36,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    '탈퇴 후에는 모든 데이터가 삭제되며\n복구할 수 없습니다.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontFamily: 'Pretendard-Regular',
                      color: Color(0xFF6B7280),
                      height: 1.4,
                      letterSpacing: -0.26,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 로고 이미지
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Image.asset(
                      'assets/icons/Icon/delete/logo.png',
                      width: 80,
                      height: 80,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: const Color(0xFF146AFF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.account_balance_wallet,
                            size: 40,
                            color: Colors.white,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context, false),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFE5E7EB)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text(
                            '취소',
                            style: TextStyle(
                              fontSize: 12,
                              fontFamily: 'Pretendard-Medium',
                              color: Color(0xFF6B7280),
                              letterSpacing: -0.28,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF5252),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            elevation: 0,
                          ),
                          child: const Text(
                            '탈퇴하기',
                            style: TextStyle(
                              fontSize: 12,
                              fontFamily: 'Pretendard-Bold',
                              color: Colors.white,
                              letterSpacing: -0.28,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    );

    if (confirmed != true) return;

    // 로딩 상태 시작
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 탈퇴 사유 구성 - 상세 입력이 있으면 우선, 없으면 선택된 사유
      String? deleteReason;
      if (_reasonText.trim().isNotEmpty) {
        deleteReason = _reasonText.trim();
      } else if (_selectedReason != null) {
        deleteReason = _selectedReason!;
      }

      print('[DeleteAccountScreen] 탈퇴 사유: $deleteReason');

      // 회원탈퇴 API 호출
      final success = await AuthService.deleteAccount(reason: deleteReason);

      if (success) {
        // 스플래시 상태 초기화 (회원탈퇴 시 다음 가입 때 스플래시 다시 보여주기)
        await SplashManager.resetAllStatus();

        if (mounted) {
          // 탈퇴 성공 시 로그인 화면으로 이동 (모든 스택 삭제)
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
          );

          // 성공 메시지 표시
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('회원탈퇴가 완료되었습니다.'),
              backgroundColor: Color(0xFF10B981),
            ),
          );
        }
      }
    } catch (e) {
      // 오류 발생 시 에러 메시지 표시
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }
}

class _TrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = const Color(0xFF5D9EFF)
          ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(size.width / 2, size.height); // 아래 중앙 점
    path.lineTo(0, 0); // 왼쪽 위 점
    path.lineTo(size.width, 0); // 오른쪽 위 점
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
