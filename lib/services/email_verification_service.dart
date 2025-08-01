import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class EmailVerificationService {
  final String baseUrl;

  EmailVerificationService({String? baseUrl})
    : baseUrl =
          baseUrl ?? dotenv.env['API_BASE_URL'] ?? 'https://api.example.com';

  /// 이메일 인증 코드 전송 요청
  Future<Map<String, dynamic>> sendVerificationEmail(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api-user/mail/public/email/send'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'toEmail': email}),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': responseData['message'] ?? '인증 이메일이 발송되었습니다.',
          'data': responseData['data'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? '이메일 인증 요청에 실패했습니다.',
          'errorCode': responseData['errorCode'],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': '서버 연결에 실패했습니다. 잠시 후 다시 시도해주세요.',
        'error': e.toString(),
      };
    }
  }

  /// 이메일 인증 코드 확인 요청
  Future<Map<String, dynamic>> verifyEmailCode(
    String email,
    String code,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api-user/mail/public/email/verify'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'code': code}),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': responseData['message'] ?? '이메일 인증이 완료되었습니다.',
          'verified': true,
          'data': responseData['data'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? '인증 코드가 올바르지 않습니다.',
          'verified': false,
          'errorCode': responseData['errorCode'],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': '서버 연결에 실패했습니다. 잠시 후 다시 시도해주세요.',
        'verified': false,
        'error': e.toString(),
      };
    }
  }

  /// 이메일 인증 상태 확인
  Future<Map<String, dynamic>> checkEmailVerificationStatus(
    String email,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api-user/mail/public/email/status?email=$email'),
        headers: {'Content-Type': 'application/json'},
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'verified': responseData['data']['verified'] ?? false,
          'message': responseData['message'] ?? '이메일 인증 상태를 확인했습니다.',
          'data': responseData['data'],
        };
      } else {
        return {
          'success': false,
          'verified': false,
          'message': responseData['message'] ?? '이메일 인증 상태 확인에 실패했습니다.',
          'errorCode': responseData['errorCode'],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'verified': false,
        'message': '서버 연결에 실패했습니다. 잠시 후 다시 시도해주세요.',
        'error': e.toString(),
      };
    }
  }
}
