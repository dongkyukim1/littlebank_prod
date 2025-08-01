import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/foundation.dart';
import 'auth_service.dart';

class TossPaymentService {
  static final CookieJar _cookieJar = CookieJar();
  static final Dio _dio = Dio()
    ..interceptors.add(CookieManager(_cookieJar))
    ..options.connectTimeout = Duration(seconds: 15)
    ..options.receiveTimeout = Duration(seconds: 15)
    ..options.contentType = 'application/json; charset=utf-8';

  static const String _baseUrl = 'http://3.34.52.239:8080';

  // 토스페이먼츠 테스트 키 (환경에 따라 변경 필요)
  static const String _clientKey = 'test_gck_6BYq7GWPVvv7wqNkzbnlVNE5vbo1';
  static const String _secretKey = 'test_gsk_docs_OaPz8L5KdmQXkzRz3y47BMw6'; // 실제 시크릿 키로 변경 필요

  static final TossPaymentService _instance = TossPaymentService._internal();
  factory TossPaymentService() => _instance;

  TossPaymentService._internal() {
    print('🍪 쿠키 관리 활성화됨 - 세션 자동 유지');
    print('🚨 중요: 임시저장과 검증 시 같은 JSESSIONID 사용됨');
  }

  /// 현재 저장된 쿠키 확인 (디버깅용)
  static Future<void> _logCurrentCookies() async {
    try {
      final uri = Uri.parse('$_baseUrl/api-user/point/temp/save-amount');
      final cookies = await _cookieJar.loadForRequest(uri);
      
      print('🍪 현재 저장된 쿠키:');
      for (final cookie in cookies) {
        print('   - ${cookie.name}=${cookie.value}');
        if (cookie.name == 'JSESSIONID') {
          print('   ✅ JSESSIONID 찾음: ${cookie.value}');
        }
      }
      
      if (cookies.isEmpty) {
        print('   ⚠️ 저장된 쿠키가 없습니다.');
      }
    } catch (e) {
      print('🍪 쿠키 확인 중 오류: $e');
    }
  }

  /// 토스페이먼츠 클라이언트 키 반환
  static String get clientKey => _clientKey;

  /// 결제 주문 정보 생성
  static Map<String, dynamic> createPaymentData({
    required String orderId,
    required int amount,
    required String orderName,
    required String customerEmail,
    required String customerName,
    String? customerMobilePhone,
  }) {
    return {
      'orderId': orderId,
      'amount': amount,
      'orderName': orderName,
      'customerEmail': customerEmail,
      'customerName': customerName,
      'customerMobilePhone': customerMobilePhone,
    };
  }

  /// 고유 주문 ID 생성
  static String generateOrderId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(1000);
    return 'ORDER_${timestamp}_$random';
  }

  /// 결제 정보 임시 저장
  static Future<Map<String, dynamic>> saveTemporaryPayment({
    required String orderId,
    required int amount,
    String? orderName,
  }) async {
    try {
      final token = await AuthService.getAccessToken();
      
      // API 문서에 따라 orderId, amount만 보내기
      final requestData = {
        'orderId': orderId,
        'amount': amount,
        // orderName은 서버에서 생성해서 응답으로 주는 데이터
      };
      
      print('=== 결제 정보 임시 저장 요청 ===');
      print('URL: $_baseUrl/api-user/point/temp/save-amount');
      print('Request Data: $requestData');
      print('🔍 API 문서 준수: orderId, amount만 전송');
      print('🔍 orderName은 서버 응답 데이터');
      print('Token: ${token?.substring(0, 20)}...');
      
      // 현재 쿠키 상태 확인
      await _logCurrentCookies();
      
      final response = await _dio.post(
        '$_baseUrl/api-user/point/temp/save-amount',
        data: requestData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      print('=== 결제 정보 임시 저장 응답 ===');
      print('Status Code: ${response.statusCode}');
      print('Response Data: ${response.data}');
      print('Response Headers: ${response.headers}');
      print('Response Type: ${response.data.runtimeType}');

      if (response.statusCode == 200) {
        print('✅ 임시 저장 HTTP 성공 (200)');
        
        // 응답 데이터 구조 확인
        if (response.data != null) {
          print('📋 응답 데이터 상세 분석:');
          if (response.data is Map) {
            final data = response.data as Map;
            print('   - 응답 타입: Map');
            print('   - 키들: ${data.keys.toList()}');
            if (data.containsKey('orderId')) {
              print('   - orderId: ${data['orderId']}');
            }
            if (data.containsKey('amount')) {
              print('   - amount: ${data['amount']}');
            }
          } else {
            print('   - 응답 타입: ${response.data.runtimeType}');
            print('   - 응답 내용: ${response.data}');
          }
        } else {
          print('⚠️ 응답 데이터가 null입니다');
        }
        
        return {
          'success': true,
          'data': response.data,
          'message': '결제 정보가 임시 저장되었습니다.',
          'orderId': orderId,
          'amount': amount,
        };
      } else {
        print('❌ 임시 저장 실패: 상태코드 ${response.statusCode}');
        print('   - 응답 데이터: ${response.data}');
        return {
          'success': false,
          'error': response.data?['message'] ?? '결제 정보 저장에 실패했습니다.',
          'statusCode': response.statusCode,
        };
      }
    } on DioException catch (e) {
      print('=== 결제 정보 임시 저장 DioException ===');
      print('Error Message: ${e.message}');
      print('Status Code: ${e.response?.statusCode}');
      print('Response Data: ${e.response?.data}');
      print('Request Data: ${e.requestOptions.data}');
      
      String errorMessage = '결제 정보 저장에 실패했습니다.';
      if (e.response?.data != null) {
        final data = e.response!.data;
        if (data is Map && data.containsKey('message')) {
          errorMessage = data['message'] ?? errorMessage;
        } else if (data is String) {
          errorMessage = data;
        }
      }
      
      return {
        'success': false,
        'error': errorMessage,
      };
    } catch (e) {
      print('=== 결제 정보 임시 저장 일반 오류 ===');
      print('Error: $e');
      return {
        'success': false,
        'error': '결제 정보 저장 중 오류가 발생했습니다.',
      };
    }
  }

  /// 임시 저장한 결제 정보 검증 (개선된 버전)
  static Future<Map<String, dynamic>> verifyTemporaryPayment({
    required String orderId,
    required int amount,
    String? orderName,
    String? customerEmail,
    String? customerName,
  }) async {
    try {
      final token = await AuthService.getAccessToken();
      
      // API 문서에 따라 orderId와 amount만 보내기
      final requestData = {
        'orderId': orderId,
        'amount': amount,
        // orderName, customerEmail, customerName은 서버 응답 데이터이므로 요청에서 제외
      };
      
      print('=== 결제 정보 검증 요청 ===');
      print('URL: $_baseUrl/api-user/point/temp/verify-amount');
      print('Request Data: $requestData');
      print('📋 API 문서에 따라 orderId, amount만 전송');
      print('Token: ${token?.substring(0, 20)}...');
      
      final response = await _dio.post(
        '$_baseUrl/api-user/point/temp/verify-amount',
        data: requestData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      print('=== 결제 정보 검증 응답 ===');
      print('Status Code: ${response.statusCode}');
      print('Response Data: ${response.data}');
      print('Response Headers: ${response.headers}');
      print('Response Type: ${response.data.runtimeType}');

      if (response.statusCode == 200) {
        final data = response.data;
        print('✅ 검증 HTTP 성공 (200)');
        print('📋 검증 응답 데이터 분석:');
        
        if (data is Map) {
          print('   - 응답 타입: Map');
          print('   - 키들: ${data.keys.toList()}');
          if (data.containsKey('code')) {
            print('   - code: ${data['code']}');
          }
          if (data.containsKey('message')) {
            print('   - message: ${data['message']}');
          }
          
          if (data['code'] == 200) {
            print('✅ 결제 정보 검증 성공 (code: 200)');
            return {
              'success': true,
              'message': data['message'] ?? '결제 정보가 일치합니다.',
            };
          } else {
            print('❌ 검증 실패 (code: ${data['code']})');
            print('   - 검증 실패 사유: ${data['message']}');
            return {
              'success': false,
              'error': data['message'] ?? '결제 정보 검증 응답이 올바르지 않습니다.',
              'code': data['code'],
              'canRetry': true, // 재시도 가능
            };
          }
        } else {
          print('⚠️ 검증 응답 구조 이상: $data');
          return {
            'success': false,
            'error': '검증 응답 형식이 올바르지 않습니다.',
            'rawResponse': data,
            'canRetry': true,
          };
        }
      } else {
        print('❌ 결제 정보 검증 실패: 상태코드 ${response.statusCode}');
        print('   - 응답 데이터: ${response.data}');
        return {
          'success': false,
          'error': response.data?['message'] ?? '결제 정보 검증에 실패했습니다.',
          'statusCode': response.statusCode,
          'canRetry': true,
        };
      }
    } on DioException catch (e) {
      print('=== 결제 정보 검증 DioException ===');
      print('Error Type: ${e.type}');
      print('Error Message: ${e.message}');
      print('Status Code: ${e.response?.statusCode}');
      print('Response Data: ${e.response?.data}');
      print('Response Headers: ${e.response?.headers}');
      print('Request Data: ${e.requestOptions.data}');
      print('Request URL: ${e.requestOptions.uri}');
      
      String errorMessage = '결제 정보 검증에 실패했습니다.';
      bool canRetry = false;
      bool canProceed = false;
      
      if (e.response?.data != null) {
        final data = e.response!.data;
        print('🔍 에러 응답 데이터 분석:');
        
        if (data is Map) {
          print('   - 에러 응답 타입: Map');
          print('   - 에러 응답 키들: ${data.keys.toList()}');
          
          if (data.containsKey('code') && data['code'] == 400) {
            errorMessage = data['message'] ?? '결제 정보가 일치하지 않습니다.';
            print('🔍 검증 실패 원인: 임시 저장된 데이터와 불일치');
            print('   - 서버 메시지: ${data['message']}');
            print('   - 요청한 orderId: $orderId');
            print('   - 요청한 amount: $amount');
            print('   - API 문서 준수: orderId, amount만 전송');
            
            // 400 에러는 일반적으로 재시도 가능
            canRetry = true;
            canProceed = false; // 검증 실패 시 결제 진행 불가
          } else if (data.containsKey('message')) {
            errorMessage = data['message'] ?? errorMessage;
            print('   - 기타 에러 메시지: ${data['message']}');
            canRetry = true;
            canProceed = false;
          }
        } else {
          print('   - 에러 응답 타입: ${data.runtimeType}');
          print('   - 에러 응답 내용: $data');
          canRetry = true;
          canProceed = false;
        }
      } else {
        print('🔍 에러 응답 데이터가 null입니다');
        // 네트워크 오류 등의 경우 재시도 가능하고 결제 진행도 가능
        canRetry = true;
        canProceed = true;
      }
      
      return {
        'success': false,
        'error': errorMessage,
        'canRetry': canRetry,
        'canProceed': canProceed,
        'statusCode': e.response?.statusCode,
      };
    } catch (e) {
      print('=== 결제 정보 검증 일반 오류 ===');
      print('Error Type: ${e.runtimeType}');
      print('Error: $e');
      return {
        'success': false,
        'error': '결제 정보 검증 중 오류가 발생했습니다.',
        'canProceed': true, // 검증 실패해도 결제 승인 진행 가능
        'canRetry': true, // 일반 오류는 재시도 가능
      };
    }
  }

  /// 결제 승인 요청 (새로운 API)
  static Future<Map<String, dynamic>> confirmPayment({
    required String paymentKey,
    required String orderId,
    required int amount,
  }) async {
    try {
      final token = await AuthService.getAccessToken();
      
      final requestData = {
        'paymentKey': paymentKey,
        'orderId': orderId,
        'amount': amount,
      };
      
      print('=== 결제 승인 요청 ===');
      print('URL: $_baseUrl/api-user/point/payment/confirm');
      print('Request Data: $requestData');
      print('Token: ${token?.substring(0, 20)}...');
      
      final response = await _dio.post(
        '$_baseUrl/api-user/point/payment/confirm',
        data: requestData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      print('=== 결제 승인 응답 ===');
      print('Status Code: ${response.statusCode}');
      print('Response Data: ${response.data}');

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': response.data,
          'message': '결제가 성공적으로 완료되었습니다.',
        };
      } else {
        return {
          'success': false,
          'error': response.data?['message'] ?? '결제 승인에 실패했습니다.',
        };
      }
    } on DioException catch (e) {
      print('=== 결제 승인 DioException ===');
      print('Error Message: ${e.message}');
      print('Status Code: ${e.response?.statusCode}');
      print('Response Data: ${e.response?.data}');
      print('Request Data: ${e.requestOptions.data}');
      
      String errorMessage = '결제 승인에 실패했습니다.';
      if (e.response?.data != null) {
        final data = e.response!.data;
        if (data is Map && data.containsKey('message')) {
          errorMessage = data['message'] ?? errorMessage;
        } else if (data is String) {
          errorMessage = data;
        }
      }
      
      return {
        'success': false,
        'error': errorMessage,
      };
    } catch (e) {
      print('=== 결제 승인 일반 오류 ===');
      print('Error: $e');
      return {
        'success': false,
        'error': '결제 승인 중 오류가 발생했습니다.',
      };
    }
  }

  /// 결제 취소 요청
  static Future<Map<String, dynamic>> cancelPayment({
    required String paymentKey,
    required String cancelReason,
    int? cancelAmount,
  }) async {
    try {
      final token = await AuthService.getAccessToken();
      
      final response = await _dio.post(
        '$_baseUrl/api/payments/toss/cancel',
        data: {
          'paymentKey': paymentKey,
          'cancelReason': cancelReason,
          if (cancelAmount != null) 'cancelAmount': cancelAmount,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': response.data,
          'message': '결제가 성공적으로 취소되었습니다.',
        };
      } else {
        return {
          'success': false,
          'error': response.data?['message'] ?? '결제 취소에 실패했습니다.',
        };
      }
    } on DioException catch (e) {
      print('토스페이먼츠 결제 취소 실패: ${e.message}');
      
      String errorMessage = '결제 취소에 실패했습니다.';
      if (e.response?.data != null) {
        errorMessage = e.response!.data['message'] ?? errorMessage;
      }
      
      return {
        'success': false,
        'error': errorMessage,
      };
    } catch (e) {
      print('토스페이먼츠 결제 취소 오류: $e');
      return {
        'success': false,
        'error': '결제 취소 중 오류가 발생했습니다.',
      };
    }
  }

  /// 결제 상태 조회
  static Future<Map<String, dynamic>> getPaymentStatus({
    required String paymentKey,
  }) async {
    try {
      final token = await AuthService.getAccessToken();
      
      final response = await _dio.get(
        '$_baseUrl/api/payments/toss/status/$paymentKey',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': response.data,
        };
      } else {
        return {
          'success': false,
          'error': response.data?['message'] ?? '결제 상태 조회에 실패했습니다.',
        };
      }
    } on DioException catch (e) {
      print('토스페이먼츠 결제 상태 조회 실패: ${e.message}');
      
      String errorMessage = '결제 상태 조회에 실패했습니다.';
      if (e.response?.data != null) {
        errorMessage = e.response!.data['message'] ?? errorMessage;
      }
      
      return {
        'success': false,
        'error': errorMessage,
      };
    } catch (e) {
      print('토스페이먼츠 결제 상태 조회 오류: $e');
      return {
        'success': false,
        'error': '결제 상태 조회 중 오류가 발생했습니다.',
      };
    }
  }

  /// 포인트 충전 기록 저장
  static Future<Map<String, dynamic>> savePointCharge({
    required String paymentKey,
    required String orderId,
    required int amount,
    required String paymentMethod,
  }) async {
    try {
      final token = await AuthService.getAccessToken();
      
      final response = await _dio.post(
        '$_baseUrl/api/payments/toss/charge',
        data: {
          'paymentKey': paymentKey,
          'orderId': orderId,
          'amount': amount,
          'paymentMethod': paymentMethod,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': response.data,
          'message': '포인트 충전이 완료되었습니다.',
        };
      } else {
        return {
          'success': false,
          'error': response.data?['message'] ?? '포인트 충전에 실패했습니다.',
        };
      }
    } on DioException catch (e) {
      print('포인트 충전 저장 실패: ${e.message}');
      
      String errorMessage = '포인트 충전에 실패했습니다.';
      if (e.response?.data != null) {
        errorMessage = e.response!.data['message'] ?? errorMessage;
      }
      
      return {
        'success': false,
        'error': errorMessage,
      };
    } catch (e) {
      print('포인트 충전 저장 오류: $e');
      return {
        'success': false,
        'error': '포인트 충전 중 오류가 발생했습니다.',
      };
    }
  }

  /// 결제 방법 표시명 반환
  static String getPaymentMethodDisplayName(String? method) {
    switch (method) {
      case 'CARD':
        return '카드';
      case 'VIRTUAL_ACCOUNT':
        return '가상계좌';
      case 'TRANSFER':
        return '계좌이체';
      case 'MOBILE_PHONE':
        return '휴대폰';
      case 'CULTURE_GIFT_CERTIFICATE':
        return '문화상품권';
      case 'BOOK_GIFT_CERTIFICATE':
        return '도서문화상품권';
      case 'GAME_GIFT_CERTIFICATE':
        return '게임문화상품권';
      default:
        return '알 수 없음';
    }
  }

  /// 금액 포맷팅 (천 단위 콤마)
  static String formatAmount(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  /// 결제 상태 표시명 반환
  static String getPaymentStatusDisplayName(String? status) {
    switch (status) {
      case 'READY':
        return '준비';
      case 'IN_PROGRESS':
        return '진행중';
      case 'WAITING_FOR_DEPOSIT':
        return '입금대기';
      case 'DONE':
        return '완료';
      case 'CANCELED':
        return '취소';
      case 'PARTIAL_CANCELED':
        return '부분취소';
      case 'ABORTED':
        return '중단';
      case 'EXPIRED':
        return '만료';
      default:
        return '알 수 없음';
    }
  }
} 