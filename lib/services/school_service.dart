import 'dart:convert';
import 'package:dio/dio.dart';
import 'auth_service.dart';

class SchoolService {
  static final Dio _dio = Dio();
  static const String _baseUrl = 'http://3.34.52.239:8080';

  static final SchoolService _instance = SchoolService._internal();
  factory SchoolService() => _instance;

  SchoolService._internal() {
    // 기본 설정
    _dio.options.connectTimeout = Duration(seconds: 15);
    _dio.options.receiveTimeout = Duration(seconds: 15);
    _dio.options.contentType = 'application/json; charset=utf-8';
  }

  /// 학교 검색 (새로운 API)
  static Future<Map<String, dynamic>> searchSchools({
    required String schoolName,
  }) async {
    try {
      print('🏫 학교 검색 요청 시작: $schoolName');
      
      final token = await AuthService.getAccessToken();
      print('🔑 토큰 확인: ${token != null ? "토큰 있음 (${token.length}자)" : "토큰 없음"}');
      
      // 첫 번째 시도: 토큰과 함께
      Response? response;
      try {
        response = await _dio.get(
          '$_baseUrl/api-user/school/get-schoolList',
          queryParameters: {
            'schoolName': schoolName,
          },
          options: Options(
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          ),
        );
        print('🏫 토큰 포함 요청 성공: ${response.statusCode}');
      } catch (e) {
        if (e is DioException && e.response?.statusCode == 401) {
          print('🔑 토큰 인증 실패, 토큰 없이 재시도...');
          
          // 두 번째 시도: 토큰 없이 (public API일 가능성)
          try {
            response = await _dio.get(
              '$_baseUrl/api-user/school/get-schoolList',
              queryParameters: {
                'schoolName': schoolName,
              },
              options: Options(
                headers: {
                  'Content-Type': 'application/json',
                },
              ),
            );
            print('🏫 토큰 없는 요청 성공: ${response.statusCode}');
          } catch (publicError) {
            print('🏫 토큰 없는 요청도 실패: $publicError');
            rethrow; // 원래 401 에러를 다시 던짐
          }
        } else {
          rethrow; // 401이 아닌 다른 에러는 그대로 전달
        }
      }

      print('🏫 학교 검색 API 응답 상태: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = response.data;
        
        print('🏫 서버 응답 전체 데이터: $data');
        print('🏫 응답 데이터 타입: ${data.runtimeType}');
        
        // API 응답 구조에 맞게 파싱
        final totalCount = data['totalCount'] ?? 0;
        final results = (data['results'] as List<dynamic>? ?? [])
            .map((item) => {
                  'schoolName': item['schoolName'] ?? '',
                  'address': item['address'] ?? '',
                })
            .toList();

        print('🏫 파싱된 totalCount: $totalCount');
        print('🏫 파싱된 results: $results');
        print('🏫 학교 검색 결과: $totalCount개 학교 발견');
        
        return {
          'success': true,
          'totalCount': totalCount,
          'schools': results,
        };
      } else {
        print('🏫 학교 검색 API 오류 응답: ${response.statusCode}');
        return {
          'success': false,
          'error': '학교 검색에 실패했습니다.',
          'schools': <Map<String, dynamic>>[],
        };
      }
    } on DioException catch (e) {
      print('🏫 학교 검색 API DioException: ${e.message}');
      print('🏫 응답 상태 코드: ${e.response?.statusCode}');
      print('🏫 응답 데이터: ${e.response?.data}');
      
      String errorMessage = '학교 검색에 실패했습니다.';
      
      // 401 오류인 경우 특별 처리
      if (e.response?.statusCode == 401) {
        print('🔑 401 인증 오류 발생 - 토큰 문제');
        errorMessage = '인증이 만료되었습니다. 앱을 다시 시작해주세요.';
      } else if (e.response?.data != null) {
        errorMessage = e.response!.data['message'] ?? errorMessage;
      }
      
      return {
        'success': false,
        'error': errorMessage,
        'schools': <Map<String, dynamic>>[],
      };
    } catch (e) {
      print('🏫 학교 검색 일반 오류: $e');
      return {
        'success': false,
        'error': '학교 검색 중 오류가 발생했습니다.',
        'schools': <Map<String, dynamic>>[],
      };
    }
  }

  /// 간단한 학교 검색 (기존 코드와의 호환성 유지)
  static Future<List<Map<String, dynamic>>> simpleSearch({
    required String keyword,
  }) async {
    if (keyword.trim().isEmpty) {
      return [];
    }

    try {
      final result = await searchSchools(schoolName: keyword);
      return result['schools'] as List<Map<String, dynamic>>;
    } catch (e) {
      print('간단한 학교 검색 오류: $e');
      return [];
    }
  }

  /// 주소 포맷팅 (기존 코드와의 호환성 유지)
  static String formatAddress(String? address) {
    if (address == null || address.isEmpty) {
      return '주소 정보 없음';
    }

    // 정규식을 사용해서 도, 시, 번길까지만 추출
    RegExp regExp = RegExp(r'([가-힣]+도)\s*([가-힣]+시)\s*([가-힣\d\s]+번길\s*\d*)');
    Match? match = regExp.firstMatch(address);

    if (match != null) {
      String province = match.group(1) ?? '';
      String city = match.group(2) ?? '';
      String street = match.group(3) ?? '';

      return '$province $city $street'.trim();
    }

    // 정규식으로 매칭되지 않으면 공백으로 분리해서 처리
    List<String> parts = address.split(' ');
    List<String> result = [];

    for (String part in parts) {
      result.add(part);
      // 번길이 포함된 부분까지만 포함
      if (part.contains('번길')) {
        break;
      }
      // 최대 3개 부분까지만 (도, 시, 구/동)
      if (result.length >= 3) {
        break;
      }
    }

    return result.join(' ');
  }

  /// 학교 정보 저장 (AuthService를 통해)
  static Future<Map<String, dynamic>> saveSchoolInfo({
    required String schoolName,
    required String schoolType,
    required int region,
    required String address,
  }) async {
    try {
      return await AuthService.saveSchoolInfo(
        schoolName: schoolName,
        schoolType: schoolType,
        region: region,
        address: address,
      );
    } catch (e) {
      print('🏫 학교 정보 저장 오류: $e');
      rethrow;
    }
  }

  /// 학교 타입을 API 형식으로 변환
  static String convertSchoolTypeToApi(String schoolName) {
    if (schoolName.contains('초등학교')) {
      return 'ELEMENTARY';
    } else if (schoolName.contains('중학교')) {
      return 'MIDDLE';
    } else if (schoolName.contains('고등학교')) {
      return 'HIGH';
    } else {
      return 'HIGH'; // 기본값
    }
  }

  /// 지역을 숫자 코드로 변환 (예시 - 실제 API 스펙에 맞춰 수정 필요)
  static int convertRegionToCode(String address) {
    if (address.contains('서울')) return 1;
    if (address.contains('경기')) return 2;
    if (address.contains('인천')) return 3;
    if (address.contains('부산')) return 4;
    if (address.contains('대구')) return 5;
    if (address.contains('광주')) return 6;
    if (address.contains('대전')) return 7;
    if (address.contains('울산')) return 8;
    if (address.contains('세종')) return 9;
    if (address.contains('강원')) return 10;
    if (address.contains('충북')) return 11;
    if (address.contains('충남')) return 12;
    if (address.contains('전북')) return 13;
    if (address.contains('전남')) return 14;
    if (address.contains('경북')) return 15;
    if (address.contains('경남')) return 16;
    if (address.contains('제주')) return 17;
    return 0; // 기본값
  }

  // 기존 코드와의 호환성을 위한 더미 메서드들
  static Future<List<Map<String, dynamic>>> searchSchoolsAdvanced({
    String? searchKeyword,
    // 다른 매개변수들은 무시됨
    dynamic schoolType,
    String? regionCode,
    String? schoolTypeCode,
    String? estTypeCode,
  }) async {
    if (searchKeyword == null || searchKeyword.trim().isEmpty) {
      return [];
    }
    return await simpleSearch(keyword: searchKeyword);
  }

  static Future<Map<String, dynamic>> searchSchoolsWithPaging({
    String? searchKeyword,
    int thisPage = 1,
    int perPage = 50,
    // 다른 매개변수들은 무시됨
    dynamic schoolType,
    String? regionCode,
    String? schoolTypeCode,
    String? estTypeCode,
  }) async {
    if (searchKeyword == null || searchKeyword.trim().isEmpty) {
      return {
        'schools': <Map<String, dynamic>>[],
        'totalCount': 0,
        'currentPage': thisPage,
        'totalPages': 0,
        'hasNextPage': false,
      };
    }

    try {
      final result = await searchSchools(schoolName: searchKeyword);
      final schools = result['schools'] as List<Map<String, dynamic>>;
      final totalCount = result['totalCount'] as int;

      // 페이징 처리 (클라이언트 사이드)
      final startIndex = (thisPage - 1) * perPage;
      final endIndex = startIndex + perPage;
      final paginatedSchools = schools.sublist(
        startIndex,
        endIndex > schools.length ? schools.length : endIndex,
      );

      final totalPages = (totalCount / perPage).ceil();

      return {
        'schools': paginatedSchools,
        'totalCount': totalCount,
        'currentPage': thisPage,
        'totalPages': totalPages,
        'hasNextPage': thisPage < totalPages,
      };
    } catch (e) {
      return {
        'schools': <Map<String, dynamic>>[],
        'totalCount': 0,
        'currentPage': thisPage,
        'totalPages': 0,
        'hasNextPage': false,
      };
    }
  }
}

// 기존 호환성을 위한 더미 클래스들
enum SchoolType {
  elementary('elem_list', '초등학교'),
  middle('midd_list', '중학교'),
  high('high_list', '고등학교');

  const SchoolType(this.code, this.displayName);
  final String code;
  final String displayName;
}

class RegionCode {
  static const Map<String, String> regions = {
    '100260': '서울특별시',
    '100267': '부산광역시',
    '100269': '인천광역시',
    '100271': '대전광역시',
    '100272': '대구광역시',
    '100273': '울산광역시',
    '100275': '광주광역시',
    '100276': '경기도',
    '100278': '강원도',
    '100280': '충청북도',
    '100281': '충청남도',
    '100282': '전북특별자치도',
    '100283': '전라남도',
    '100285': '경상북도',
    '100291': '경상남도',
    '100292': '제주도',
  };

  static List<MapEntry<String, String>> get regionEntries =>
      regions.entries.toList();
}

class HighSchoolType {
  static const Map<String, String> types = {
    '100362': '일반고',
    '100363': '특성화고',
    '100364': '특수목적고',
    '100365': '자율고',
    '100366': '기타',
  };

  static List<MapEntry<String, String>> get typeEntries =>
      types.entries.toList();
}

class EstablishmentType {
  static const Map<String, String> types = {
    '100334': '국립',
    '100335': '사립',
    '100336': '공립',
  };

  static List<MapEntry<String, String>> get typeEntries =>
      types.entries.toList();
}
