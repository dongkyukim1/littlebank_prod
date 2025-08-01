import 'package:dio/dio.dart';
import 'auth_service.dart';
import '../services/navigation_service.dart';

class AuthInterceptor extends Interceptor {
  final Dio dio;
  bool _isRefreshing = false;
  // 재시도 중인 요청 큐
  final _pendingRequests = <RequestOptions>[];

  AuthInterceptor(this.dio);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // 액세스 토큰이 필요한 요청에 토큰 추가
    if (!options.path.contains('public')) {
      final token = await AuthService.getAccessToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }

    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401 &&
        (err.response?.data is Map && err.response?.data['code'] == 'C007')) {
      // 원래 요청 저장
      final originalRequest = err.requestOptions;

      // 이미 토큰 갱신 중이라면 대기열에 추가
      if (_isRefreshing) {
        _pendingRequests.add(originalRequest);
        return;
      }

      _isRefreshing = true;

      try {
        // 리프레시 토큰 확인
        final refreshToken = await AuthService.getRefreshToken();

        if (refreshToken == null || refreshToken.isEmpty) {
          _cancelPendingRequests('리프레시 토큰 없음');
          _redirectToLogin();
          return handler.next(err);
        }

        // 액세스 토큰 재발급 시도
        final newToken = await AuthService.reissueAccessToken();

        if (newToken != null) {
          // 원래 요청 재시도
          final response = await _retryRequest(originalRequest, newToken);

          // 대기 중인 모든 요청 처리
          final pendingCount = _pendingRequests.length;
          if (pendingCount > 0) {
            _processPendingRequests(newToken);
          }

          return handler.resolve(response);
        } else {
          // 대기 중인 모든 요청 실패 처리
          _cancelPendingRequests('액세스 토큰 재발급 실패');

          // 로그인 페이지로 리디렉션
          _redirectToLogin();

          return handler.next(err);
        }
      } catch (e) {
        _cancelPendingRequests('토큰 재발급 중 오류: $e');
        _redirectToLogin();
        return handler.next(err);
      } finally {
        _isRefreshing = false;
      }
    }

    // 다른 오류는 그냥 전달
    return handler.next(err);
  }

  // 요청 재시도
  Future<Response> _retryRequest(
    RequestOptions requestOptions,
    String newToken,
  ) async {
    final options = Options(
      method: requestOptions.method,
      headers: {...requestOptions.headers, 'Authorization': 'Bearer $newToken'},
    );

    return dio.request<dynamic>(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: options,
    );
  }

  // 대기 중인 요청 처리
  void _processPendingRequests(String newToken) {
    for (final request in _pendingRequests) {
      dio.fetch<dynamic>(_requestWithNewToken(request, newToken));
    }
    _pendingRequests.clear();
  }

  // 새 토큰으로 요청 업데이트
  RequestOptions _requestWithNewToken(RequestOptions options, String newToken) {
    options.headers['Authorization'] = 'Bearer $newToken';
    return options;
  }

  // 대기 중인 요청 취소
  void _cancelPendingRequests(String reason) {
    _pendingRequests.clear();
  }

  // 로그인 화면으로 리디렉션
  void _redirectToLogin() {
    // 모든 인증 데이터 삭제
    AuthService.clearAllAuthData();

    // 전역 네비게이션 서비스를 사용하여 로그인 화면으로 이동
    // 이 부분은 비동기적으로 실행되어야 하므로 Future를 사용
    Future.microtask(() {
      try {
        NavigationService.navigateToLogin();
      } catch (e) {
        // 로그인 화면 이동 실패
      }
    });
  }
}

// Dio 클라이언트 설정 (앱 시작 시 초기화)
class DioClient {
  static Dio? _instance;

  static Dio get instance {
    _instance ??= _createDio();
    return _instance!;
  }

  static Dio _createDio() {
    final dio = Dio();

    // 기본 설정
    dio.options.baseUrl = AuthService.baseUrl;
    dio.options.connectTimeout = Duration(seconds: 15);
    dio.options.receiveTimeout = Duration(seconds: 15);
    dio.options.contentType = 'application/json; charset=utf-8';

    // 인터셉터 추가
    dio.interceptors.add(AuthInterceptor(dio));

    // 로깅 인터셉터 (디버그 모드에서만)
    dio.interceptors.add(
      LogInterceptor(
        requestHeader: true,
        requestBody: true,
        responseHeader: true,
        responseBody: true,
      ),
    );

    return dio;
  }
}
