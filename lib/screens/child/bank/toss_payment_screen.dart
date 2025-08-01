import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:tosspayments_widget_sdk_flutter/model/payment_info.dart';
import 'package:tosspayments_widget_sdk_flutter/model/payment_widget_options.dart';
import 'package:tosspayments_widget_sdk_flutter/payment_widget.dart';
import 'package:tosspayments_widget_sdk_flutter/widgets/agreement.dart';
import 'package:tosspayments_widget_sdk_flutter/widgets/payment_method.dart';
import 'dart:math' as math;
import '../../../services/toss_payment_service.dart';
import '../../../services/auth_service.dart';
import 'toss_payment_success_screen.dart';
import 'toss_payment_failure_screen.dart';

class TossPaymentScreen extends StatefulWidget {
  final int amount;
  final String customerName;
  final String customerEmail;
  final String? customerMobilePhone;

  const TossPaymentScreen({
    super.key,
    required this.amount,
    required this.customerName,
    required this.customerEmail,
    this.customerMobilePhone,
  });

  @override
  State<TossPaymentScreen> createState() => _TossPaymentScreenState();
}

class _TossPaymentScreenState extends State<TossPaymentScreen> {
  PaymentWidget? _paymentWidget;
  late String _orderId;
  late String _customerKey;
  late String _orderName; // orderName을 별도로 저장
  
  PaymentMethodWidgetControl? _paymentMethodWidgetControl;
  AgreementWidgetControl? _agreementWidgetControl;
  
  bool _isLoading = false;
  String _debugMessage = '결제 정보 초기화 중...';
  bool _paymentMethodsRendered = false;
  bool _agreementRendered = false;
  Map<String, dynamic>? _savedPaymentData; // 임시저장된 데이터
  Map<String, bool> _agreements = {}; // 커스텀 약관 동의 상태

  @override
  void initState() {
    super.initState();
    _orderId = TossPaymentService.generateOrderId();
    _customerKey = _generateCustomerKey();
    _orderName = '포인트 충전'; // orderName 초기화
    _initializePayment();
  }

  // 고유 customerKey 생성 (UUID 형태)
  String _generateCustomerKey() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = math.Random().nextInt(100000);
    return 'customer_${timestamp}_$random';
  }

  // 결제 초기화
  Future<void> _initializePayment() async {
    try {
      setState(() {
        _isLoading = true;
        _debugMessage = '결제 위젯 초기화 중...';
      });

      print('=== 토스페이먼츠 결제 초기화 시작 ===');
      print('orderId: $_orderId');
      print('customerKey: $_customerKey');
      print('amount: ${widget.amount}');
      print('customerName: ${widget.customerName}');
      print('customerEmail: ${widget.customerEmail}');

      // PaymentWidget 초기화 (임시 저장은 결제 버튼 클릭 시 수행)
      _paymentWidget = PaymentWidget(
        clientKey: TossPaymentService.clientKey,
        customerKey: _customerKey,
      );

      print('PaymentWidget 생성 완료');

      // UI가 완전히 렌더링된 후 토스페이먼츠 렌더링 메서드 호출
      setState(() {
        _isLoading = false;
        _debugMessage = '결제 위젯 준비 중...';
      });

      // 커스텀 약관 UI를 사용하므로 약관 렌더링 상태를 즉시 true로 설정
      setState(() {
        _agreementRendered = true;
      });

      // 위젯이 UI에 배치된 후 결제수단 렌더링만 수행
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await _renderPaymentWidgets();
      });

      print('✅ 토스페이먼츠 결제 초기화 완료');

    } catch (e) {
      print('💥 결제 초기화 오류: $e');
      setState(() {
        _isLoading = false;
        _debugMessage = '결제 초기화 실패: $e';
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('결제 초기화 중 오류가 발생했습니다: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // UI 렌더링 후 토스페이먼츠 결제수단 위젯 렌더링
  Future<void> _renderPaymentWidgets() async {
    try {
      setState(() {
        _debugMessage = '결제수단 렌더링 중...';
      });

      // 결제수단 렌더링
      await _renderPaymentMethods();

      setState(() {
        _debugMessage = '결제 준비 완료';
      });

    } catch (e) {
      print('💥 결제 위젯 렌더링 오류: $e');
      setState(() {
        _debugMessage = '결제 위젯 렌더링 실패: $e';
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('결제 위젯 렌더링 중 오류가 발생했습니다: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // 결제수단 렌더링
  Future<void> _renderPaymentMethods() async {
    try {
      if (_paymentWidget == null) {
        throw Exception('PaymentWidget이 초기화되지 않았습니다.');
      }
      
      print('결제수단 렌더링 시작');
      
      final control = await _paymentWidget!.renderPaymentMethods(
        selector: 'payment-methods',
        amount: Amount(
          value: widget.amount,
          currency: Currency.KRW,
          country: "KR",
        ),
        options: RenderPaymentMethodsOptions(variantKey: "DEFAULT"),
      );

      setState(() {
        _paymentMethodWidgetControl = control;
        _paymentMethodsRendered = true;
      });

      print('✅ 결제수단 렌더링 완료');
    } catch (e) {
      print('💥 결제수단 렌더링 오류: $e');
      throw e;
    }
  }

  // 약관 렌더링 (커스텀 UI 사용으로 불필요)
  Future<void> _renderAgreement() async {
    // 커스텀 약관 UI를 사용하므로 토스페이먼츠 약관 렌더링 생략
    setState(() {
      _agreementRendered = true;
    });
  }

  // 결제 요청
  Future<void> _requestPayment() async {
    try {
      print('🚨🚨🚨 [중요] _requestPayment 메서드 시작 🚨🚨🚨');
      print('   - 호출 시간: ${DateTime.now()}');
      print('   - orderId: $_orderId');
      print('   - amount: ${widget.amount}');
      
      setState(() {
        _isLoading = true;
        _debugMessage = '결제 처리 중...';
      });

      print('=== 토스페이먼츠 결제 요청 시작 ===');

      // 1. 커스텀 약관 동의 확인
      bool allRequiredAgreed = (_agreements['required1'] ?? false) &&
                              (_agreements['required2'] ?? false) &&
                              (_agreements['required3'] ?? false);
      
      if (!allRequiredAgreed) {
        setState(() {
          _isLoading = false;
          _debugMessage = '필수 약관에 동의해주세요';
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('결제를 위해 필수 약관에 동의해주세요.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // 2. 선택된 결제수단 확인
      final selectedPaymentMethod = await _paymentMethodWidgetControl?.getSelectedPaymentMethod();
      print('선택된 결제수단: ${selectedPaymentMethod?.method} ${selectedPaymentMethod?.easyPay?.provider ?? ''}');

      // 🔥 토스페이먼츠 공식 타이밍에 맞춰서 순서 변경
      
      // 3. 임시저장 → 검증 → 결제 요청 → 결제 승인 순서로 진행
      print('🔥 [토스페이먼츠 공식 타이밍] 1단계: 임시저장 시작');
      await _performTemporarySave();
      
      print('🔥 [토스페이먼츠 공식 타이밍] 2단계: 임시저장 검증 시작');
      await _performTemporaryVerification();
      
      print('🔥 [토스페이먼츠 공식 타이밍] 3단계: 결제 요청 시작');
      await _performPaymentRequest();
      
    } catch (e) {
      print('💥 결제 요청 예외: $e');
      setState(() {
        _isLoading = false;
        _debugMessage = '결제 요청 실패: $e';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('결제 요청 중 오류가 발생했습니다: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // 1단계: 임시저장 (토스페이먼츠 공식 타이밍)
  Future<void> _performTemporarySave() async {
    setState(() {
      _debugMessage = '1단계: 결제 정보 임시 저장 중...';
    });

    print('🚨🚨🚨 [중요] 1단계: 임시저장 시작 🚨🚨🚨');
    print('📝 결제 정보 임시 저장 시작');
    print('   - orderId: $_orderId');
    print('   - amount: ${widget.amount}');
    print('   - 현재 시간: ${DateTime.now()}');

    final tempResult = await TossPaymentService.saveTemporaryPayment(
      orderId: _orderId,
      amount: widget.amount,
      orderName: _orderName,
    );

    print('🚨🚨🚨 [중요] 1단계: 임시저장 완료 🚨🚨🚨');
    print('📝 임시 저장 API 호출 완료');
    print('   - 결과: $tempResult');
    print('   - 성공 여부: ${tempResult['success']}');

    if (!tempResult['success']) {
      print('❌ 1단계 실패: 임시저장 실패');
      throw Exception('임시저장 실패: ${tempResult['error']}');
    }

    // 임시저장 성공 시 데이터 저장
    if (tempResult['data'] != null) {
      _savedPaymentData = tempResult['data'] as Map<String, dynamic>;
      print('💾 임시저장 데이터 저장됨: ${_savedPaymentData?.keys.toList()}');
    }
    
    print('✅ 1단계 성공: 임시저장 완료');
  }

  // 2단계: 임시저장 검증 (토스페이먼츠 공식 타이밍)
  Future<void> _performTemporaryVerification() async {
    setState(() {
      _debugMessage = '2단계: 결제 정보 검증 중...';
    });

    print('🚨🚨🚨 [중요] 2단계: 임시저장 검증 시작 🚨🚨🚨');
    print('🔍 결제 정보 검증 시작');
    print('   - orderId: $_orderId');
    print('   - amount: ${widget.amount}');

    final verifyResult = await TossPaymentService.verifyTemporaryPayment(
      orderId: _orderId,
      amount: widget.amount,
    );

    print('🚨🚨🚨 [중요] 2단계: 검증 완료 🚨🚨🚨');
    print('🔍 검증 결과: ${verifyResult['success']}');
    print('   - 에러: ${verifyResult['error']}');

    if (!verifyResult['success']) {
      print('❌ 2단계 실패: 검증 실패');
      throw Exception('검증 실패: ${verifyResult['error']}');
    }
    
    print('✅ 2단계 성공: 검증 완료');
  }

  // 3단계: 결제 요청 (토스페이먼츠 공식 타이밍)
  Future<void> _performPaymentRequest() async {
    setState(() {
      _debugMessage = '3단계: 결제 요청 중...';
    });

    print('🚨🚨🚨 [중요] 3단계: 결제 요청 시작 🚨🚨🚨');

    if (_paymentWidget == null) {
      throw Exception('PaymentWidget이 초기화되지 않았습니다.');
    }

    final paymentResult = await _paymentWidget!.requestPayment(
      paymentInfo: PaymentInfo(
        orderId: _orderId,
        orderName: _orderName,
      ),
    );

    print('🚨🚨🚨 [중요] 3단계: 결제 요청 완료 🚨🚨🚨');
    print('결제 요청 결과: $paymentResult');

    if (paymentResult.success != null) {
      // 결제 성공 → 4단계: 결제 승인
      final success = paymentResult.success!;
      print('✅ 3단계 성공: 토스페이먼츠 결제 성공!');
      print('paymentKey: ${success.paymentKey}');
      print('orderId: ${success.orderId}');
      print('amount: ${success.amount}');

      await _handlePaymentSuccess(
        paymentKey: success.paymentKey,
        orderId: success.orderId,
        amount: success.amount.toInt(),
      );
    } else if (paymentResult.fail != null) {
      // 결제 실패
      final fail = paymentResult.fail!;
      print('❌ 3단계 실패: 토스페이먼츠 결제 실패!');
      print('fail 객체: $fail');
      print('fail 타입: ${fail.runtimeType}');
       
      await _handlePaymentFailure(
        code: 'PAYMENT_FAILED',
        message: fail.toString(),
      );
    }
  }

  // 결제 성공 처리 (4단계: 결제 승인)
  Future<void> _handlePaymentSuccess({
    required String paymentKey,
    required String orderId,
    required int amount,
  }) async {
    try {
      setState(() {
        _debugMessage = '4단계: 결제 승인 처리 중...';
      });

      print('🚨🚨🚨 [중요] 4단계: 결제 승인 시작 🚨🚨🚨');
      print('🎯 결제 정보 요약:');
      print('   - paymentKey: $paymentKey');
      print('   - orderId: $orderId');
      print('   - amount: $amount');
      print('   - 예상 orderId: $_orderId');
      print('   - orderId 일치: ${orderId == _orderId}');
      print('🔥 1~3단계 완료: 임시저장 → 검증 → 결제 요청 성공');
      print('🔥 4단계 시작: 최종 결제 승인 처리');

      // 결제 승인 처리 (검증은 이미 2단계에서 완료됨)
      final confirmResult = await TossPaymentService.confirmPayment(
        paymentKey: paymentKey,
        orderId: orderId,
        amount: amount,
      );

      print('🚨🚨🚨 [중요] 4단계: 결제 승인 완료 🚨🚨🚨');
      print('결제 승인 결과: $confirmResult');

      if (confirmResult['success']) {
        print('✅ 4단계 성공: 결제 승인 성공');
        print('🎉 전체 결제 과정 완료!');
        print('   📋 1단계: 임시저장 ✅');
        print('   📋 2단계: 검증 ✅');  
        print('   📋 3단계: 결제 요청 ✅');
        print('   📋 4단계: 결제 승인 ✅');
        print('🎉 최종 결제 완료 정보:');
        print('   - 결제 상태: 성공');
        print('   - 결제 금액: ${amount}원');
        print('   - 결제 키: $paymentKey');
        print('   - 주문 번호: $orderId');
        
        // 결제 성공 화면으로 이동
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => TossPaymentSuccessScreen(
              amount: amount,
              paymentKey: paymentKey,
              orderId: orderId,
            ),
          ),
        );
      } else {
        print('❌ 4단계 실패: 결제 승인 실패');
        print('💥 결제 승인 실패 상세:');
        print('   - 에러 메시지: ${confirmResult['error']}');
        print('   - 결제 금액: ${amount}원');
        print('   - 결제 키: $paymentKey');
        print('   - 주문 번호: $orderId');
        
        // 승인 실패 시 실패 화면으로 이동
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => TossPaymentFailureScreen(
              errorMessage: confirmResult['error'] ?? '결제 승인에 실패했습니다.',
              orderId: orderId,
            ),
          ),
        );
      }
    } catch (e) {
      print('💥 4단계 예외: 결제 승인 처리 중 오류');
      print('   - 예외 내용: $e');
      
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => TossPaymentFailureScreen(
            errorMessage: '결제 처리 중 오류가 발생했습니다: $e',
            orderId: orderId,
          ),
        ),
      );
    }
  }

  // 결제 실패 처리
  Future<void> _handlePaymentFailure({
    required String code,
    required String message,
  }) async {
    print('결제 실패 처리: code=$code, message=$message');
    
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => TossPaymentFailureScreen(
          errorMessage: '$message (코드: $code)',
          orderId: _orderId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Color(0xFF3A88F4),
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(
              Icons.close,
              color: Colors.white,
              size: 24,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: Stack(
        children: [
          // 메인 컨텐츠
          Column(
            children: [
              // 결제 정보 헤더 (반응형)
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(color: Color(0xFF3A88F4)),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            '충전하는 금액',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontFamily: 'Pretendard-Light',
                              letterSpacing: -0.72,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            '${TossPaymentService.formatAmount(widget.amount)}원',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontFamily: 'Pretendard-Bold',
                              letterSpacing: -1.12,
                            ),
                          ),
                          SizedBox(height: 8),
                                                      Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  '주문번호',
                                  style: TextStyle(
                                    color: Color(0xFFC4C4C4),
                                    fontSize: 12,
                                    fontFamily: 'Pretendard-Light',
                                    letterSpacing: -0.24,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    '$_orderId',
                                    style: TextStyle(
                                      color: Color(0xFFC4C4C4),
                                      fontSize: 12,
                                      fontFamily: 'Pretendard-Light',
                                      letterSpacing: -0.24,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 나머지 컨텐츠
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                // 결제수단 섹션
                Text(
                  '결제 방법 선택',
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'Pretendard-Bold',
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 12),

                // 결제수단 위젯
                Container(
                  child: _paymentWidget != null
                      ? PaymentMethodWidget(
                          paymentWidget: _paymentWidget!,
                          selector: 'payment-methods',
                        )
                      : Container(
                          height: 120,
                          decoration: BoxDecoration(
                            color: Color(0xFFF8F9FA),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5D9EFF)),
                                ),
                                SizedBox(height: 12),
                                Text(
                                  '결제수단 로딩 중...',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontFamily: 'Pretendard-Medium',
                                    color: Color(0xFF6C757D),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                ),

                SizedBox(height: 24),

                // 약관 동의 섹션
                Text(
                  '약관 동의',
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'Pretendard-Bold',
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 12),

                // 커스텀 약관 동의 UI
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildNewAgreementItem(
                              title: '[필수] 전자금융거래 기본 약관',
                              isChecked: _agreements['required1'] ?? false,
                              onChanged: (value) {
                                setState(() {
                                  _agreements['required1'] = value;
                                });
                              },
                            ),
                            SizedBox(height: 20),
                            _buildNewAgreementItem(
                              title: '[필수] 개인정보 수집 및 이용 동의',
                              isChecked: _agreements['required2'] ?? false,
                              onChanged: (value) {
                                setState(() {
                                  _agreements['required2'] = value;
                                });
                              },
                            ),
                            SizedBox(height: 20),
                            _buildNewAgreementItem(
                              title: '[필수] 결제 서비스 필수 약관',
                              isChecked: _agreements['required3'] ?? false,
                              onChanged: (value) {
                                setState(() {
                                  _agreements['required3'] = value;
                                });
                              },
                            ),
                            SizedBox(height: 20),
                            _buildNewAgreementItem(
                              title: '[선택] 개인정보 제3자 제공 동의',
                              isChecked: _agreements['optional1'] ?? false,
                              onChanged: (value) {
                                setState(() {
                                  _agreements['optional1'] = value;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // 숨겨진 토스페이먼츠 약관 위젯 (결제 프로세스 연동용)
                Visibility(
                  visible: false,
                  child: Container(
                    height: 0,
                    child: _paymentWidget != null
                        ? AgreementWidget(
                            paymentWidget: _paymentWidget!,
                            selector: 'agreement',
                          )
                        : Container(),
                  ),
                ),

                SizedBox(height: 24),

                      // 디버그 정보 (개발 중에만 표시)
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Color(0xFFF0F0F0),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _debugMessage,
                          style: TextStyle(
                            fontSize: 12,
                            fontFamily: 'Pretendard-Light',
                            color: Color(0xFF666666),
                          ),
                        ),
                      ),

                      SizedBox(height: 100), // 하단 버튼 공간 확보
                    ],
                  ),
                ),
              ),
            ],
          ),

          // 로딩 오버레이
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5D9EFF)),
                      ),
                      SizedBox(height: 16),
                      Text(
                        _debugMessage,
                        style: TextStyle(
                          fontSize: 14,
                          fontFamily: 'Pretendard-Medium',
                          color: Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // 하단 결제 버튼
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.only(
                top: 24,
                left: 16,
                right: 16,
                bottom: 16,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x5B000000),
                    blurRadius: 8,
                    offset: Offset(0, -4),
                    spreadRadius: 0,
                  )
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: (_isLoading || !_paymentMethodsRendered || !_isAllRequiredAgreementsChecked()) 
                        ? null 
                        : _requestPayment,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: ShapeDecoration(
                        color: (_isLoading || !_paymentMethodsRendered || !_isAllRequiredAgreementsChecked())
                            ? Color(0xFF3A88F4).withOpacity(0.5)
                            : Color(0xFF3A88F4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text: '${TossPaymentService.formatAmount(widget.amount)}원',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontFamily: 'Pretendard-Medium',
                                        letterSpacing: -0.32,
                                      ),
                                    ),
                                    TextSpan(
                                      text: ' 충전하기',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontFamily: 'Pretendard-Light',
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

  // 모든 필수 약관이 체크되었는지 확인
  bool _isAllRequiredAgreementsChecked() {
    return (_agreements['required1'] ?? false) &&
           (_agreements['required2'] ?? false) &&
           (_agreements['required3'] ?? false);
  }

  // 새로운 스타일 약관 동의 아이템 위젯 빌더
  Widget _buildNewAgreementItem({
    required String title,
    required bool isChecked,
    required Function(bool) onChanged,
  }) {
    return Container(
      width: double.infinity,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () => onChanged(!isChecked),
            child: Container(
              width: 24,
              height: 24,
              child: Image.asset(
                isChecked 
                    ? 'assets/icons/my/check_blue.png'
                    : 'assets/icons/my/check_subs.png',
                width: 24,
                height: 24,
                fit: BoxFit.contain,
              ),
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 24,
              child: Stack(
                children: [
                  Positioned(
                    left: 0,
                    top: 2.5,
                    child: Text(
                      title,
                      style: TextStyle(
                        color: Color(0xFF666666),
                        fontSize: 14,
                        fontFamily: 'Pretendard-Light',
                        letterSpacing: -0.28,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 24,
                      height: 24,
                      child: Image.asset(
                        'assets/icons/parent/들어가기.png',
                        width: 24,
                        height: 24,
                        fit: BoxFit.contain,
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

  @override
  void dispose() {
    super.dispose();
  }
} 