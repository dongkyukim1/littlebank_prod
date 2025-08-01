import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:in_app_purchase_storekit/store_kit_wrappers.dart';
import 'auth_service.dart';
import 'subscription_service.dart';
import 'kakao_share_service.dart';

/// Google Play Billing을 관리하는 서비스 클래스
class BillingService {
  static final BillingService _instance = BillingService._internal();
  factory BillingService() => _instance;
  BillingService._internal();

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;

  // 구독권 상품 ID들 (Google Play Console에서 설정한 ID와 일치해야 함)
  // 모든 구독권이 정기결제로 변경됨
  static const String kOnePersonSubscription = 'one_month_ly';
  static const String kThreePersonSubscription = 'three_month_ly';
  static const String kFivePersonSubscription = 'five_month_ly';

  // 상품 ID 목록
  static const Set<String> _kIds = <String>{
    kOnePersonSubscription,
    kThreePersonSubscription,
    kFivePersonSubscription,
  };

  List<ProductDetails> _products = [];
  List<PurchaseDetails> _purchases = [];
  bool _isAvailable = false;
  bool _purchasePending = false;
  bool _loading = true;
  String? _queryProductError;

  // 최근 구매 정보 저장용
  String? _lastPurchaseToken;
  String? _lastProductId;

  // Getters
  List<ProductDetails> get products => _products;
  List<PurchaseDetails> get purchases => _purchases;
  bool get isAvailable => _isAvailable;
  bool get purchasePending => _purchasePending;
  bool get loading => _loading;
  String? get queryProductError => _queryProductError;
  
  // 최근 구매 정보 Getters
  String? get lastPurchaseToken => _lastPurchaseToken;
  String? get lastProductId => _lastProductId;

  /// 빌링 서비스 초기화
  Future<void> initialize() async {
    try {
      print('🔄 BillingService 초기화 시작');

      // 스토어 연결 확인
      final bool available = await _inAppPurchase.isAvailable();
      print('📱 스토어 사용 가능: $available');

      if (!available) {
        _isAvailable = false;
        _loading = false;
        print('❌ 스토어를 사용할 수 없습니다');
        return;
      }

      // 플랫폼별 설정
      if (Platform.isIOS) {
        final InAppPurchaseStoreKitPlatformAddition iosPlatformAddition =
            _inAppPurchase
                .getPlatformAddition<InAppPurchaseStoreKitPlatformAddition>();
        await iosPlatformAddition.setDelegate(ExamplePaymentQueueDelegate());
      }

      // 구매 상태 변경 리스너 등록
      _subscription = _inAppPurchase.purchaseStream.listen(
        _onPurchaseUpdate,
        onDone: () => _subscription.cancel(),
        onError: (error) => print('❌ 구매 스트림 오류: $error'),
      );

      _isAvailable = available;

      // 상품 정보 로드
      await _loadProducts();

      // 미완료 구매 복원
      await _restorePurchases();

      print('✅ BillingService 초기화 완료');
    } catch (e) {
      print('❌ BillingService 초기화 실패: $e');
      _isAvailable = false;
    } finally {
      _loading = false;
    }
  }

  /// 상품 정보 로드
  Future<void> _loadProducts() async {
    try {
      print('🛒 상품 정보 로드 중...');

      final ProductDetailsResponse response = await _inAppPurchase
          .queryProductDetails(_kIds);

      if (response.notFoundIDs.isNotEmpty) {
        print('⚠️ 찾을 수 없는 상품 ID: ${response.notFoundIDs}');
      }

      if (response.error != null) {
        _queryProductError = response.error!.message;
        print('❌ 상품 쿼리 오류: ${response.error!.message}');
        return;
      }

      _products = response.productDetails;
      print('✅ 로드된 상품 수: ${_products.length}');

      for (final product in _products) {
        print(
          '📦 상품: ${product.id}, 가격: ${product.price}, 제목: ${product.title}',
        );
        print('   - 설명: ${product.description}');
      }

      // 요청한 상품 ID와 실제 로드된 상품 비교
      print('📋 요청한 상품 ID: $_kIds');
      print('📋 로드된 상품 ID: ${_products.map((p) => p.id).toList()}');
      
      // 누락된 상품 ID 확인
      final loadedIds = _products.map((p) => p.id).toSet();
      final missingIds = _kIds.where((id) => !loadedIds.contains(id)).toList();
      if (missingIds.isNotEmpty) {
        print('⚠️ 누락된 상품 ID: $missingIds');
        print('💡 Google Play Console에서 해당 상품들이 활성화되어 있는지 확인하세요');
      }
    } catch (e) {
      print('❌ 상품 로드 실패: $e');
      _queryProductError = e.toString();
    }
  }

  /// 미완료 구매 복원
  Future<void> _restorePurchases() async {
    try {
      print('🔄 구매 내역 복원 중...');
      await _inAppPurchase.restorePurchases();
      print('✅ 구매 내역 복원 완료');
    } catch (e) {
      print('❌ 구매 복원 실패: $e');
    }
  }

  /// 구매 처리
  Future<bool> purchaseSubscription(String productId) async {
    if (!_isAvailable) {
      print('❌ 스토어를 사용할 수 없습니다');
      return false;
    }

    final ProductDetails? productDetails = _products
        .cast<ProductDetails?>()
        .firstWhere((product) => product?.id == productId, orElse: () => null);

    if (productDetails == null) {
      print('❌ 상품을 찾을 수 없습니다: $productId');
      return false;
    }

    try {
      print('🛒 구매 시작: ${productDetails.id}');
      _purchasePending = true;

      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: productDetails,
        applicationUserName: null, // 필요시 사용자 식별자 추가
      );

      // 모든 구독권이 정기결제로 변경됨
      print('🔄 정기 구독 처리: $productId');
      final bool success = await _inAppPurchase.buyNonConsumable(
        purchaseParam: purchaseParam,
      );

      if (!success) {
        print('❌ 구매 시작 실패');
        _purchasePending = false;
        return false;
      }

      print('🔄 구매 진행 중...');
      return true;
    } catch (e) {
      print('❌ 구매 오류: $e');
      _purchasePending = false;
      return false;
    }
  }

  /// 구매 상태 업데이트 처리
  void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) {
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      print(
        '📦 구매 상태 업데이트: ${purchaseDetails.productID}, 상태: ${purchaseDetails.status}',
      );

      if (purchaseDetails.status == PurchaseStatus.pending) {
        _showPendingUI();
      } else {
        if (purchaseDetails.status == PurchaseStatus.error) {
          _handleError(purchaseDetails.error!);
        } else if (purchaseDetails.status == PurchaseStatus.purchased ||
            purchaseDetails.status == PurchaseStatus.restored) {
          _handleSuccessfulPurchase(purchaseDetails);
        }

        if (purchaseDetails.pendingCompletePurchase) {
          _inAppPurchase.completePurchase(purchaseDetails);
        }
      }
    }
  }

  /// 구매 대기 중 UI 표시
  void _showPendingUI() {
    print('🔄 구매 대기 중...');
    _purchasePending = true;
  }

  /// 구매 성공 처리
  Future<void> _handleSuccessfulPurchase(PurchaseDetails purchaseDetails) async {
    print('✅ 구매 성공: ${purchaseDetails.productID}');
    _purchasePending = false;

    // 구매 내역에 추가
    if (!_purchases.any(
      (purchase) => purchase.productID == purchaseDetails.productID,
    )) {
      _purchases.add(purchaseDetails);
    }

    // 최근 구매 정보 저장 (purchaseToken 추출)
    _lastProductId = purchaseDetails.productID;
    
    // Android의 경우 JSON에서 purchaseToken 추출
    if (Platform.isAndroid) {
      try {
        final jsonData = jsonDecode(
          purchaseDetails.verificationData.localVerificationData,
        );
        _lastPurchaseToken = jsonData['purchaseToken'];
        
        // 구매 날짜 정보 추출 및 로깅
        final purchaseTime = jsonData['purchaseTime'];
        final orderId = jsonData['orderId'];
        
        print('📱 추출된 purchaseToken: $_lastPurchaseToken');
        print('📅 Google Play 구매 시간: $purchaseTime');
        print('🆔 주문 ID: $orderId');
        
        // purchaseTime을 실제 날짜로 변환하여 확인
        if (purchaseTime != null) {
          try {
            final purchaseDateTime = DateTime.fromMillisecondsSinceEpoch(
              int.parse(purchaseTime.toString()),
            );
            print('📅 변환된 구매 날짜: $purchaseDateTime');
            print('📅 한국 시간: ${purchaseDateTime.toLocal()}');
          } catch (e) {
            print('📅 구매 날짜 변환 실패: $e');
          }
        }
        
        // 전체 구매 데이터 로깅
        print('📋 전체 구매 데이터: $jsonData');
      } catch (e) {
        print('❌ purchaseToken 추출 실패: $e');
        _lastPurchaseToken = null;
      }
    } else {
      // iOS의 경우 transactionIdentifier 사용
      _lastPurchaseToken = purchaseDetails.purchaseID;
      print('📱 iOS purchaseID: $_lastPurchaseToken');
      print('📅 iOS 거래 날짜: ${purchaseDetails.transactionDate}');
    }

    // 서버에 구매 정보 전송 (활성화)
    try {
      await _sendPurchaseToServer(purchaseDetails);
      print('✅ 서버 검증 완료');
      
      // 3인 이상 구독권 구매 완료 시 쿠폰 코드 관리 처리
      await _handleMultiPersonSubscriptionPurchase(purchaseDetails);
    } catch (e) {
      print('❌ 서버 검증 실패: $e');
      // 서버 검증 실패 시에도 로컬 처리는 유지
      print('🔄 로컬 구매 처리 완료 - 서버 검증 실패하여 로컬만 처리');
    }
  }

  /// 3인 이상 구독권 구매 완료 시 쿠폰 코드 관리 처리
  Future<void> _handleMultiPersonSubscriptionPurchase(PurchaseDetails purchaseDetails) async {
    try {
      final productId = purchaseDetails.productID;
      final persons = getPersonsByProductId(productId);
      
      print('🔍 구독권 인원 확인: $productId -> ${persons}인');
      
      // 3인 이상 구독권인 경우에만 처리
      if (persons >= 3) {
        print('🎉 3인 이상 구독권 구매 완료 - 쿠폰 코드 관리 시작');
        
        // 약간의 지연 후 서버에서 쿠폰 코드 생성 완료를 기다림
        await Future.delayed(const Duration(seconds: 2));
        
        // 쿠폰 코드 정보 조회
        final matchingInfo = await SubscriptionService.getInviteCodeMatching();
        if (matchingInfo != null) {
          final availableCodes = matchingInfo['availableCodes'] as int? ?? 0;
          final totalSeats = matchingInfo['totalSeats'] as int? ?? persons;
          
          print('✅ 쿠폰 코드 매칭 정보 로드 완료');
          print('📊 총 좌석: $totalSeats, 사용 가능한 코드: $availableCodes');
          
          // 사용 가능한 코드가 있으면 자동으로 쿠폰 코드 공유 알림 저장
          if (availableCodes > 0) {
            // 클라이언트 측에서 3인 이상 구독권 구매 완료 플래그 설정
            _setMultiPersonSubscriptionPurchaseCompleted(productId, totalSeats, availableCodes);
            print('🎯 3인 이상 구독권 구매 완료 플래그 설정 - UI에서 쿠폰 공유 안내 표시 가능');
          }
        } else {
          print('❌ 쿠폰 코드 매칭 정보 로드 실패');
        }
        
        // 개별 쿠폰 전송 기록 초기화 (새 구독권이므로)
        SubscriptionService.clearIndividualCouponSentRecord();
        print('🗑️ 이전 쿠폰 전송 기록 초기화 완료');
      } else {
        print('ℹ️ 1인 구독권이므로 쿠폰 코드 관리 불필요');
      }
    } catch (e) {
      print('❌ 3인 이상 구독권 쿠폰 코드 관리 처리 중 오류: $e');
    }
  }

  // 3인 이상 구독권 구매 완료 상태 관리
  static String? _completedMultiPersonProductId;
  static int? _completedMultiPersonSeats;
  static int? _completedMultiPersonAvailableCodes;
  static DateTime? _completedMultiPersonTimestamp;

  /// 3인 이상 구독권 구매 완료 플래그 설정
  void _setMultiPersonSubscriptionPurchaseCompleted(String productId, int seats, int availableCodes) {
    _completedMultiPersonProductId = productId;
    _completedMultiPersonSeats = seats;
    _completedMultiPersonAvailableCodes = availableCodes;
    _completedMultiPersonTimestamp = DateTime.now();
    
    print('📝 3인 이상 구독권 구매 완료 상태 저장: $productId (${seats}인, $availableCodes개 코드)');
  }

  /// 3인 이상 구독권 구매 완료 상태 확인
  static bool hasCompletedMultiPersonSubscriptionPurchase() {
    if (_completedMultiPersonProductId == null || _completedMultiPersonTimestamp == null) {
      return false;
    }
    
    // 10분 이내의 구매 완료만 유효하다고 간주
    final now = DateTime.now();
    final timeDifference = now.difference(_completedMultiPersonTimestamp!);
    final isRecent = timeDifference.inMinutes <= 10;
    
    print('🔍 3인 이상 구독권 구매 완료 상태 확인: ${_completedMultiPersonProductId != null && isRecent}');
    print('   - 상품 ID: $_completedMultiPersonProductId');
    print('   - 시간 경과: ${timeDifference.inMinutes}분');
    
    return _completedMultiPersonProductId != null && isRecent;
  }

  /// 3인 이상 구독권 구매 완료 정보 가져오기
  static Map<String, dynamic>? getCompletedMultiPersonSubscriptionInfo() {
    if (!hasCompletedMultiPersonSubscriptionPurchase()) {
      return null;
    }
    
    return {
      'productId': _completedMultiPersonProductId,
      'seats': _completedMultiPersonSeats,
      'availableCodes': _completedMultiPersonAvailableCodes,
      'timestamp': _completedMultiPersonTimestamp,
      'persons': getPersonsByProductId(_completedMultiPersonProductId!),
    };
  }

  /// 3인 이상 구독권 구매 완료 상태 클리어
  static void clearCompletedMultiPersonSubscriptionPurchase() {
    _completedMultiPersonProductId = null;
    _completedMultiPersonSeats = null;
    _completedMultiPersonAvailableCodes = null;
    _completedMultiPersonTimestamp = null;
    
    print('🗑️ 3인 이상 구독권 구매 완료 상태 클리어');
  }

  /// 구매 오류 처리
  void _handleError(IAPError error) {
    print('❌ 구매 오류: ${error.message} (코드: ${error.code})');
    _purchasePending = false;
  }

  /// 서버에 구매 정보 전송
  Future<void> _sendPurchaseToServer(PurchaseDetails purchaseDetails) async {
    try {
      print('📡 서버에 구매 정보 전송: ${purchaseDetails.productID}');

      // 사용자 토큰 가져오기
      final accessToken = await AuthService.getAccessToken();
      if (accessToken == null) {
        throw Exception('인증 토큰이 없습니다');
      }

      // 모든 구독권이 정기결제로 변경됨
      final isMonthlySubscription = true;

      // 플랫폼별 구매 정보 수집
      Map<String, dynamic> purchaseData = {
        'platform': Platform.isAndroid ? 'android' : 'ios',
        'productId': purchaseDetails.productID,
        'purchaseId': purchaseDetails.purchaseID,
        'verificationData':
            purchaseDetails.verificationData.serverVerificationData,
        'localVerificationData':
            purchaseDetails.verificationData.localVerificationData,
        'transactionDate': purchaseDetails.transactionDate,
        'status': purchaseDetails.status.toString(),
        'isSubscription': isMonthlySubscription,
        'subscriptionType': 'monthly',
      };

      // Android의 경우 JSON 파싱해서 필요한 정보 추출
      if (Platform.isAndroid) {
        try {
          final jsonData = jsonDecode(
            purchaseDetails.verificationData.localVerificationData,
          );
          purchaseData.addAll({
            'orderId': jsonData['orderId'],
            'packageName': jsonData['packageName'],
            'purchaseTime': jsonData['purchaseTime'],
            'purchaseState': jsonData['purchaseState'],
            'purchaseToken': jsonData['purchaseToken'],
          });
        } catch (e) {
          print('Android 구매 정보 파싱 실패: $e');
        }
      }

      print('전송할 구매 데이터: ${jsonEncode(purchaseData)}');

      // 서버로 검증 요청 - 실제 존재하는 엔드포인트 사용
      final url = Uri.parse(
        'http://3.34.52.239:8080/api-user/subscription/purchase/inapp',
      );
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(purchaseData),
      );

      print('구매 검증 API 응답 상태: ${response.statusCode}');
      print('구매 검증 API 응답 본문: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        // 모든 구독권이 정기결제로 변경됨 - 서버에서 자동으로 구독권을 활성화
        print('✅ ${purchaseDetails.productID} 정기결제 서버 검증 완료 - 구독권 자동 활성화됨');

        // 응답에 success 필드가 있다면 확인
        if (responseData.containsKey('success')) {
          if (responseData['success'] == true) {
            print('✅ 서버 검증 완료');
          } else {
            print('❌ 서버 검증 실패: ${responseData['message']}');
            throw Exception('구매 검증에 실패했습니다: ${responseData['message']}');
          }
        } else {
          // success 필드가 없으면 200 응답을 성공으로 간주
          print('✅ 서버 검증 완료 (응답 코드 200)');
        }
      } else {
        try {
          final errorData = jsonDecode(response.body);
          final errorMessage = errorData['message'] ?? '구매 검증에 실패했습니다';
          throw Exception('구매 검증 실패: $errorMessage');
        } catch (e) {
          throw Exception('구매 검증 실패 (HTTP ${response.statusCode})');
        }
      }
    } catch (e) {
      print('❌ 서버 전송 실패: $e');
      // 정기결제의 경우 서버 검증 실패가 치명적이므로 재시도 필요
      rethrow;
    }
  }

  /// 서버에서 구독 상태 확인 (임시로 로컬 처리)
  Future<bool> isSubscribedFromServer() async {
    try {
      print('🔄 로컬에서 구독 상태 확인 중...');

      // 임시로 로컬 구매 상태만 확인
      final hasActivePurchase = _purchases.any(
        (purchase) =>
            purchase.status == PurchaseStatus.purchased ||
            purchase.status == PurchaseStatus.restored,
      );

      if (hasActivePurchase) {
        print('✅ 로컬 구매 내역에서 활성 구독 발견');
        return true;
      }

      // 서버 API가 완성되면 아래 코드 사용
      /*
      final accessToken = await AuthService.getAccessToken();
      if (accessToken == null) {
        print('❌ 인증 토큰이 없습니다');
        return false;
      }

      // 1. 먼저 현재 구독권 상태 확인
      final currentSubUrl = Uri.parse('http://3.34.52.239:8080/api-user/subscription/my');
      final currentSubResponse = await http.get(
        currentSubUrl,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      print('현재 구독권 조회 API 응답 상태: ${currentSubResponse.statusCode}');
      print('현재 구독권 조회 API 응답 본문: ${currentSubResponse.body}');

      if (currentSubResponse.statusCode == 200) {
        final subscriptions = jsonDecode(currentSubResponse.body) as List<dynamic>;
        
        if (subscriptions.isNotEmpty) {
          // 현재 시간이 구독 기간 내에 있는 구독권 찾기
          final now = DateTime.now();
          for (final subscription in subscriptions) {
            final endDateStr = subscription['endDate'] as String?;
            if (endDateStr != null) {
              final endDate = DateTime.parse(endDateStr);
              if (endDate.isAfter(now)) {
                print('✅ 활성 구독권 발견: ${subscription['subscriptionId']}');
                return true;
              }
            }
          }
        }
      }

      // 2. 무료 구독권도 확인
      final freeSubUrl = Uri.parse('http://3.34.52.239:8080/api-user/subscription/free');
      final freeSubResponse = await http.get(
        freeSubUrl,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      print('무료 구독권 조회 API 응답 상태: ${freeSubResponse.statusCode}');
      
      if (freeSubResponse.statusCode == 200) {
        final freeSubscription = jsonDecode(freeSubResponse.body) as Map<String, dynamic>;
        final endDateStr = freeSubscription['endDate'] as String?;
        
        if (endDateStr != null) {
          final endDate = DateTime.parse(endDateStr);
          final now = DateTime.now();
          if (endDate.isAfter(now)) {
            print('✅ 활성 무료 구독권 발견');
            return true;
          }
        }
      }
      */

      print('❌ 활성 구독권을 찾을 수 없습니다');
      return false;
    } catch (e) {
      print('❌ 구독 상태 확인 실패: $e');
      return false;
    }
  }

  /// 구독 상태 확인
  bool isSubscribed(String productId) {
    final activePurchase = _purchases.cast<PurchaseDetails?>().firstWhere(
      (purchase) =>
          purchase?.productID == productId &&
          (purchase?.status == PurchaseStatus.purchased ||
              purchase?.status == PurchaseStatus.restored),
      orElse: () => null,
    );

    if (activePurchase == null) return false;

    // 1인 구독권(정기 구독)의 경우 추가 검증
    if (productId == kOnePersonSubscription) {
      // 구매 날짜로부터 한 달이 지났는지 확인
      if (activePurchase.transactionDate != null) {
        final purchaseDate = DateTime.fromMillisecondsSinceEpoch(
          int.parse(activePurchase.transactionDate!),
        );
        final now = DateTime.now();
        final difference = now.difference(purchaseDate).inDays;

        // 한 달(30일) 이내라면 구독 중
        return difference <= 30;
      }
    }

    return true;
  }

  /// 상품 ID로 가격 가져오기
  String? getPrice(String productId) {
    final product = _products.cast<ProductDetails?>().firstWhere(
      (p) => p?.id == productId,
      orElse: () => null,
    );
    return product?.price;
  }

  /// 상품 ID로 제품 정보 가져오기
  ProductDetails? getProduct(String productId) {
    return _products.cast<ProductDetails?>().firstWhere(
      (p) => p?.id == productId,
      orElse: () => null,
    );
  }

  /// 인원 수에 따른 상품 ID 반환
  static String getProductIdByPersons(int persons) {
    switch (persons) {
      case 1:
        return kOnePersonSubscription;
      case 3:
        return kThreePersonSubscription;
      case 5:
        return kFivePersonSubscription;
      default:
        return kOnePersonSubscription;
    }
  }

  /// 1인 구독권 정기 결제 테스트 (디버그용)
  Future<void> testMonthlySubscription() async {
    print('🧪 === 1인 구독권 정기 결제 테스트 ===');

    // 1인 구독권 상품 확인
    final product = getProduct(kOnePersonSubscription);
    if (product != null) {
      print('✅ 1인 구독권 상품 발견: ${product.title}');
      print('💰 가격: ${product.price}');
      print('🆔 상품 ID: ${product.id}');

      // 구독 상태 확인
      final isCurrentlySubscribed = isSubscribed(kOnePersonSubscription);
      print('📋 현재 구독 상태: ${isCurrentlySubscribed ? "구독 중" : "구독 안함"}');

      // 서버 구독 상태 확인
      final serverStatus = await isSubscribedFromServer();
      print('🌐 서버 구독 상태: ${serverStatus ? "활성" : "비활성"}');
    } else {
      print('❌ 1인 구독권 상품을 찾을 수 없음');
      print('📦 사용 가능한 상품들:');
      for (final p in _products) {
        print('  - ${p.id}: ${p.title} (${p.price})');
      }
    }
  }

  /// 상품 ID로 인원 수 반환
  static int getPersonsByProductId(String productId) {
    switch (productId) {
      case kOnePersonSubscription:
        return 1;
      case kThreePersonSubscription:
        return 3;
      case kFivePersonSubscription:
        return 5;
      default:
        return 1;
    }
  }

  /// 리소스 정리
  void dispose() {
    if (Platform.isIOS) {
      final InAppPurchaseStoreKitPlatformAddition iosPlatformAddition =
          _inAppPurchase
              .getPlatformAddition<InAppPurchaseStoreKitPlatformAddition>();
      iosPlatformAddition.setDelegate(null);
    }
    _subscription.cancel();
  }
}

/// iOS 결제 큐 델리게이트
class ExamplePaymentQueueDelegate implements SKPaymentQueueDelegateWrapper {
  @override
  bool shouldContinueTransaction(
    SKPaymentTransactionWrapper transaction,
    SKStorefrontWrapper storefront,
  ) {
    return true;
  }

  @override
  bool shouldShowPriceConsent() {
    return false;
  }
}

/// 구매 결과 콜백
typedef PurchaseCallback = void Function(bool success, String? error);

/// 구매 결과 콜백 (purchaseToken 포함)
typedef PurchaseCallbackWithToken = void Function(
  bool success, 
  String? error, 
  String? purchaseToken,
);

/// 빌링 서비스 확장 메서드
extension BillingServiceExtension on BillingService {
  /// 비동기 구매 with 콜백
  Future<void> purchaseWithCallback(
    String productId,
    PurchaseCallback callback,
  ) async {
    print('🔄 purchaseWithCallback 시작: $productId');
    final success = await purchaseSubscription(productId);

    if (success) {
      print('🔄 구매 시작 성공, 완료 대기 중...');
      // 구매 완료까지 대기 (최대 60초로 증가)
      int attempts = 0;
      while (attempts < 60 && purchasePending) {
        await Future.delayed(const Duration(seconds: 1));
        attempts++;
        if (attempts % 10 == 0) {
          print('🔄 구매 대기 중... ${attempts}초 경과');
        }
      }

      print('🔍 구매 대기 완료 - purchasePending: $purchasePending, isSubscribed: ${isSubscribed(productId)}');

      // 구매 완료 여부 확인 (더 관대한 조건)
      if (isSubscribed(productId) || !purchasePending) {
        // 구매 내역에서 해당 상품 확인
        final purchaseDetails = _purchases.cast<PurchaseDetails?>().firstWhere(
          (purchase) => purchase?.productID == productId,
          orElse: () => null,
        );
        
        if (purchaseDetails != null) {
          print('✅ 구매 완료 확인: ${purchaseDetails.productID}, 상태: ${purchaseDetails.status}');
          callback(true, null);
        } else {
          print('❌ 구매 내역에서 상품을 찾을 수 없음');
          callback(false, '구매 내역을 확인할 수 없습니다.');
        }
      } else {
        print('❌ 구매 완료되지 않음 - attempts: $attempts, purchasePending: $purchasePending');
        callback(false, '구매가 완료되지 않았습니다. (시간 초과: ${attempts}초)');
      }
    } else {
      print('❌ 구매 시작 실패');
      callback(false, '구매를 시작할 수 없습니다.');
    }
  }

  /// 비동기 구매 with 콜백 (purchaseToken 포함)
  Future<void> purchaseWithTokenCallback(
    String productId,
    PurchaseCallbackWithToken callback,
  ) async {
    final success = await purchaseSubscription(productId);

    if (success) {
      // 구매 완료까지 대기 (최대 30초)
      int attempts = 0;
      while (attempts < 30 && purchasePending) {
        await Future.delayed(const Duration(seconds: 1));
        attempts++;
      }

      if (isSubscribed(productId)) {
        // 성공한 구매에서 purchaseToken 추출
        final purchaseToken = getPurchaseTokenForProduct(productId);
        print('✅ 구매 성공, purchaseToken: $purchaseToken');
        callback(true, null, purchaseToken);
      } else {
        callback(false, '구매가 완료되지 않았습니다.', null);
      }
    } else {
      callback(false, '구매를 시작할 수 없습니다.', null);
    }
  }

  /// 특정 상품의 purchaseToken 가져오기
  String? getPurchaseTokenForProduct(String productId) {
    try {
      final activePurchase = purchases.cast<PurchaseDetails?>().firstWhere(
        (purchase) =>
            purchase?.productID == productId &&
            (purchase?.status == PurchaseStatus.purchased ||
                purchase?.status == PurchaseStatus.restored),
        orElse: () => null,
      );

      if (activePurchase != null) {
        // Android의 경우 localVerificationData에서 purchaseToken 추출
        if (Platform.isAndroid) {
          try {
            final jsonData = jsonDecode(
              activePurchase.verificationData.localVerificationData,
            );
            final purchaseToken = jsonData['purchaseToken'] as String?;
            print('🔍 Android purchaseToken 추출: $purchaseToken');
            return purchaseToken;
          } catch (e) {
            print('❌ Android purchaseToken 추출 실패: $e');
          }
        }
        
        // iOS의 경우 transactionIdentifier 사용
        if (Platform.isIOS) {
          final purchaseToken = activePurchase.purchaseID;
          print('🔍 iOS purchaseToken 추출: $purchaseToken');
          return purchaseToken;
        }
      }

      print('❌ $productId에 대한 purchaseToken을 찾을 수 없습니다.');
      return null;
    } catch (e) {
      print('❌ purchaseToken 추출 중 오류: $e');
      return null;
    }
  }
}
