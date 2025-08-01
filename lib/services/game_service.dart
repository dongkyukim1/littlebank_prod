import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'auth_service.dart'; // AuthService에서 토큰 가져오기

class GameService {
  static String get baseUrl => dotenv.env['API_BASE_URL'] ?? 'http://3.34.52.239:8080';

  // 밸런스 게임 조회 API
  static Future<List<Map<String, dynamic>>> getGames() async {
    try {
      print('===== 밸런스 게임 조회 API 호출 시작 =====');
      final accessToken = await AuthService.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        throw Exception('인증 토큰이 없습니다.');
      }

      final url = Uri.parse('$baseUrl/api-user/game/main');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      print('밸런스 게임 조회 응답 코드: ${response.statusCode}');
      print('밸런스 게임 조회 응답 바디: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> responseData = jsonDecode(utf8.decode(response.bodyBytes));
        // API 응답의 필드 이름을 프론트엔드에서 사용하기 좋은 형태로 변환
        return responseData.map((game) {
          return {
            'gameId': game['gameId'],
            'question': game['question'],
            'optionA': game['option_a'], // option_a -> optionA
            'optionB': game['option_b'], // option_b -> optionB
            'voted': game['voted'] ?? false,
            'myChoice': game['myChoice'],
            'voteCountA': game['voteCountA'] ?? 0,
            'voteCountB': game['voteCountB'] ?? 0,
            'percentageA': game['percentA']?.toDouble() ?? 0.0, // percentA -> percentageA
            'percentageB': game['percentB']?.toDouble() ?? 0.0, // percentB -> percentageB
          };
        }).toList();
      } else {
        throw Exception('밸런스 게임 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('밸런스 게임 조회 중 오류: $e');
      rethrow;
    }
  }

  // 밸런스 게임 투표 API
  static Future<Map<String, dynamic>> voteGame(int gameId, String choice) async {
    try {
      print('===== 밸런스 게임 투표 API 호출 시작 (gameId: $gameId, choice: $choice) =====');
      final accessToken = await AuthService.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        throw Exception('인증 토큰이 없습니다.');
      }

      final url = Uri.parse('$baseUrl/api-user/game/join/$gameId');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({'choice': choice}),
      );

      print('밸런스 게임 투표 응답 코드: ${response.statusCode}');
      print('밸런스 게임 투표 응답 바디: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(utf8.decode(response.bodyBytes));
        // API 응답의 필드 이름을 프론트엔드에서 사용하기 좋은 형태로 변환
        return {
          'gameId': responseData['gameId'],
          'choice': responseData['choice'],
          'voteCountA': responseData['voteCountA'] ?? 0,
          'voteCountB': responseData['voteCountB'] ?? 0,
          'percentageA': responseData['percentageA']?.toDouble() ?? 0.0,
          'percentageB': responseData['percentageB']?.toDouble() ?? 0.0,
        };
      } else if (response.statusCode == 400) {
        // 이미 투표한 경우 등의 에러 처리
        final errorData = jsonDecode(utf8.decode(response.bodyBytes));
        throw Exception(errorData['message'] ?? '이미 투표했거나 잘못된 요청입니다.');
      }
      else {
        throw Exception('밸런스 게임 투표 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('밸런스 게임 투표 중 오류: $e');
      rethrow;
    }
  }
} 