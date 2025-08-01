class ChallengeJoinRequest {
  final String? subject;
  final String startDate;
  final String endDate;
  final Map<String, int> startTime; // LocalTime 객체로 변경
  final int totalStudyTime;
  final int reward;

  ChallengeJoinRequest({
    this.subject,
    required this.startDate,
    required this.endDate,
    required this.startTime,
    required this.totalStudyTime,
    required this.reward,
  });

  // JSON 형식으로 변환
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {
      'startDate': startDate,
      'endDate': endDate,
      'startTime': startTime, // LocalTime 객체
      'totalStudyTime': totalStudyTime,
      'reward': reward,
      // challengeStatus 제거 - 서버가 자동으로 REQUESTED로 설정
    };
    
    // subject가 null이 아니고 유효한 문자열일 때만 JSON에 포함
    if (subject != null && subject!.isNotEmpty && subject != 'null') {
      json['subject'] = subject!;
    }
    
    return json;
  }

  @override
  String toString() {
    final subjectStr = (subject == null || subject!.isEmpty || subject == 'null') ? 'null' : subject!;
    return 'ChallengeJoinRequest(subject: $subjectStr, startDate: $startDate, endDate: $endDate, startTime: $startTime, totalStudyTime: $totalStudyTime, reward: $reward)';
  }
} 