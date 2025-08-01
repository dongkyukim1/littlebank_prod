import 'dart:io';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'analysis_service.dart';
import 'mission_service.dart';
import 'challenge_service.dart';
import 'goal_service.dart';
import 'auth_service.dart';
import 'family_service.dart';

class PdfService {
  // PDF 생성 및 공유
  static Future<void> saveAndSharePdf({
    required Map<String, dynamic> analysisData,
    required Map<String, dynamic> familyMemberData,
    required int selectedPeriod,
    required BuildContext context,
  }) async {
    print('📚 전문 학습 성적 보고서 생성 시작!');
    
    try {
      // 1. 자녀 정보 추출
      final childId = familyMemberData['userId'] ?? familyMemberData['familyMemberId'];
      final childName = familyMemberData['nickname'] ?? familyMemberData['realName'] ?? '자녀';
      
      print('👨‍🎓 학생: $childName (ID: $childId)');
      
      if (childId == null) {
        throw Exception('학생 ID를 찾을 수 없습니다');
      }

      // 2. 종합 학습 데이터 수집
      print('📊 종합 학습 데이터 분석 중...');
      final academicData = await _collectAcademicData(childId);
      
      // 2.5. 실제 분석 API 데이터 수집
      print('📈 실제 분석 API 데이터 수집 중...');
      final realAnalysisData = await _collectRealAnalysisData(familyMemberData, selectedPeriod);
      
      // 3. 전문 분석 실행 (실제 API 데이터 포함)
      final professionalAnalysis = _generateProfessionalAnalysis(academicData, analysisData, selectedPeriod, realAnalysisData);
      
      // 4. 전문 학습 보고서 PDF 생성
      final pdf = pw.Document();
      await _buildProfessionalAcademicReport(
        pdf, 
        childName, 
        selectedPeriod, 
        academicData, 
        professionalAnalysis,
        analysisData,
        realAnalysisData
      );

      // 5. PDF 저장 및 공유
      final bytes = await pdf.save();
      final fileName = '${childName}_학습성적보고서_${DateFormat('yyyy년MM월dd일').format(DateTime.now())}.pdf';
      
      await _savePdfAndShare(bytes, fileName);
      
    } catch (e) {
      print('❌ 학습 보고서 생성 실패: $e');
      rethrow;
    }
  }

  // 종합 학습 데이터 수집
  static Future<Map<String, dynamic>> _collectAcademicData(int childId) async {
    print('🔍 학습 데이터 종합 분석 중...');
    
    Map<String, dynamic> data = {
      'missions': <Map<String, dynamic>>[],
      'challenges': <Map<String, dynamic>>[],
      'weeklyGoals': <Map<String, dynamic>>[],
      'allGoals': <Map<String, dynamic>>[],
      'performance': <String, dynamic>{},
    };

    try {
      // 미션 데이터
      print('📝 미션 학습 기록 수집...');
      final missionsData = await MissionService.getParentChildMissions(
        childId: childId,
        page: 0,
      );
      
      if (missionsData != null && missionsData['data'] != null) {
        final missions = List<Map<String, dynamic>>.from(missionsData['data']);
        data['missions'] = missions;
        print('✅ 미션 기록: ${missions.length}개');
      }

      // 챌린지 데이터
      print('🏆 챌린지 참여 기록 수집...');
      final familyInfo = await FamilyService.getFamilyInfo();
      if (familyInfo != null) {
        final familyId = familyInfo['familyId'];
        final challengeResponse = await ChallengeService.getChildChallenges(
          familyId,
          childId,
          page: 0,
        );
        
        final challenges = challengeResponse.data.map((c) => {
          'participationId': c.participationId,
          'title': c.title,
          'challengeStatus': c.challengeStatus,
          'startDate': c.startDate,
          'endDate': c.endDate,
          'reward': c.reward,
          'totalStudyTime': c.totalStudyTime,
          'isRewarded': c.isRewarded,
          'subject': c.subject,
        }).toList();
        
        data['challenges'] = challenges;
        print('✅ 챌린지 기록: ${challenges.length}개');
      }

      // 목표 설정 기록
      print('🎯 목표 설정 기록 수집...');
      if (familyInfo != null) {
        final familyId = familyInfo['familyId'];
        
        final weeklyGoals = await GoalService.getParentWeeklyGoals(familyId);
        if (weeklyGoals != null) {
          data['weeklyGoals'] = weeklyGoals;
          print('✅ 주간 목표: ${weeklyGoals.length}개');
        }
        
        final allGoals = await GoalService.getParentAllGoals(familyId);
        if (allGoals != null) {
          data['allGoals'] = allGoals;
          print('✅ 전체 목표: ${allGoals.length}개');
        }
      }

    } catch (e) {
      print('❌ 학습 데이터 수집 오류: $e');
    }

    return data;
  }

  // 실제 분석 API 데이터 수집
  static Future<Map<String, dynamic>> _collectRealAnalysisData(
    Map<String, dynamic> familyMemberData,
    int selectedPeriod,
  ) async {
    print('📊 실제 분석 API 호출 중...');
    
    try {
      final memberId = familyMemberData['familyMemberId'] ?? familyMemberData['memberId'] ?? familyMemberData['id'];
      
      if (memberId != null) {
        print('🔍 AnalysisService.getAnalysisReport 호출 - memberId: $memberId, period: $selectedPeriod');
        final analysisResult = await AnalysisService.getAnalysisReport(memberId, selectedPeriod);
        
        if (analysisResult != null) {
          print('✅ 실제 분석 데이터 수집 성공!');
          print('📈 데이터 내용: ${analysisResult.keys.join(', ')}');
          return analysisResult;
        }
      }
      
      print('⚠️ 실제 분석 데이터가 없음 - 기본값 반환');
      return {};
    } catch (e) {
      print('❌ 실제 분석 데이터 수집 실패: $e');
      return {};
    }
  }

  // 전문가 분석 생성 (실제 API 데이터 통합)
  static Map<String, dynamic> _generateProfessionalAnalysis(
    Map<String, dynamic> academicData,
    Map<String, dynamic> analysisData,
    int period,
    Map<String, dynamic> realAnalysisData,
  ) {
    print('🧠 전문가 학습 분석 실행...');
    print('📊 실제 API 데이터 활용: ${realAnalysisData.isNotEmpty ? "있음" : "없음"}');

    // 기본 통계
    final missions = academicData['missions'] as List<dynamic>;
    final challenges = academicData['challenges'] as List<dynamic>;
    final allGoals = academicData['allGoals'] as List<dynamic>;

    // 완료율 계산
    final completedMissions = missions.where((m) => m['status'] == 'ACHIEVEMENT').length;
    final completedChallenges = challenges.where((c) => c['challengeStatus'] == 'ACHIEVEMENT').length;
    final completedGoals = allGoals.where((g) => g['status'] == 'ACHIEVEMENT').length;

    final missionCompletionRate = missions.isEmpty ? 0.0 : (completedMissions / missions.length * 100);
    final challengeCompletionRate = challenges.isEmpty ? 0.0 : (completedChallenges / challenges.length * 100);
    final goalCompletionRate = allGoals.isEmpty ? 0.0 : (completedGoals / allGoals.length * 100);

    // 실제 API 데이터에서 학습 시간 및 성과 추출
    int totalStudyMinutes = 0;
    int prevStudyTime = 0;
    int recentStudyTime = 0;
    int prevMissionCount = 0;
    int recentMissionCount = 0;
    double prevAvgScore = 0.0;
    double recentAvgScore = 0.0;
    String leastTimeSubject = '';
    int leastTime = 0;
    String mostTimeSubject = '';
    int mostTime = 0;

    if (realAnalysisData.isNotEmpty) {
      // 실제 API 데이터 활용
      prevStudyTime = realAnalysisData['prevStudyTime'] ?? 0;
      recentStudyTime = realAnalysisData['recentStudyTime'] ?? 0;
      prevMissionCount = realAnalysisData['prevMissionAchieveCount'] ?? 0;
      recentMissionCount = realAnalysisData['recentMissionAchieveCount'] ?? 0;
      prevAvgScore = (realAnalysisData['prevAvgScore'] ?? 0).toDouble();
      recentAvgScore = (realAnalysisData['recentAvgScore'] ?? 0).toDouble();
      leastTimeSubject = realAnalysisData['nameOfLeastTimeSubject'] ?? '';
      leastTime = realAnalysisData['timeOfLeastTimeSubject'] ?? 0;
      mostTimeSubject = realAnalysisData['nameOfMostTimeSubject'] ?? '';
      mostTime = realAnalysisData['timeOfMostTimeSubject'] ?? 0;
      
      totalStudyMinutes = recentStudyTime;
      print('✅ 실제 API 데이터 활용: 최근 학습시간 ${recentStudyTime}분, 미션 달성 ${recentMissionCount}개');
    } else {
      // 기본 계산 방식 (fallback)
      for (var mission in missions) {
        if (mission['status'] == 'ACCEPT' || mission['status'] == 'ACHIEVEMENT') {
          totalStudyMinutes += 60; // 미션당 1시간
        }
      }
      for (var challenge in challenges) {
        final studyTime = challenge['totalStudyTime'] ?? 0;
        if (studyTime is num) {
          totalStudyMinutes += (studyTime.toDouble() * 60).toInt();
        }
      }
      recentStudyTime = totalStudyMinutes;
      print('⚠️ 기본 계산 방식 사용: 총 학습시간 ${totalStudyMinutes}분');
    }

    // 과목별 분석 (실제 API 데이터 우선)
    Map<String, int> subjectDistribution = {};
    if (leastTimeSubject.isNotEmpty && mostTimeSubject.isNotEmpty) {
      subjectDistribution[leastTimeSubject] = leastTime;
      subjectDistribution[mostTimeSubject] = mostTime;
    } else {
      // fallback: 챌린지 데이터에서 추출
      for (var challenge in challenges) {
        final subject = challenge['subject'] ?? '기타';
        subjectDistribution[subject] = (subjectDistribution[subject] ?? 0) + 1;
      }
    }

    // 성취 수준 평가 (실제 API 데이터 기반)
    String achievementLevel;
    String levelComment;
    double comprehensiveScore = 0.0;
    
    if (realAnalysisData.isNotEmpty) {
      // 실제 API 데이터 기반 종합 평가
      final studyTimeImprovement = recentStudyTime > prevStudyTime ? 1.0 : 0.0;
      final missionImprovement = recentMissionCount >= prevMissionCount ? 1.0 : 0.0;
      final scoreImprovement = recentAvgScore >= prevAvgScore ? 1.0 : 0.0;
      final subjectBalance = (mostTime > 0 && leastTime > 0) ? (leastTime / mostTime) : 0.5;
      
      comprehensiveScore = (studyTimeImprovement * 30 + missionImprovement * 30 + scoreImprovement * 25 + subjectBalance * 15);
      
      print('📊 종합 평가 점수: ${comprehensiveScore.toStringAsFixed(1)}점');
      print('   - 학습시간 개선: ${studyTimeImprovement * 30}점');
      print('   - 미션 달성 개선: ${missionImprovement * 30}점');
      print('   - 점수 개선: ${scoreImprovement * 25}점');
      print('   - 과목 균형: ${subjectBalance * 15}점');
      
      if (comprehensiveScore >= 80) {
        achievementLevel = '최우수 (A+)';
        levelComment = '모든 영역에서 뛰어난 성장을 보이고 있습니다! 지난 기간 대비 학습시간 ${AnalysisService.formatStudyTime(recentStudyTime - prevStudyTime)} 증가, 미션 달성 ${recentMissionCount - prevMissionCount}개 증가, 평균 점수 ${(recentAvgScore - prevAvgScore).toStringAsFixed(1)}점 향상을 이루어냈습니다.';
             } else if (comprehensiveScore >= 65) {
         achievementLevel = '우수 (A)';
         levelComment = '대부분의 영역에서 안정적인 성장세를 보이고 있습니다. 학습시간, 미션달성, 성적향상 모든 면에서 고른 발전을 이루고 있습니다.';
       } else if (comprehensiveScore >= 50) {
         achievementLevel = '양호 (B)';
         levelComment = '꾸준한 학습 노력이 보입니다. 학습 시간 관리와 미션 달성률을 조금 더 향상시키면 더 좋은 결과를 얻을 수 있을 것입니다.';
       } else {
         achievementLevel = '개선 필요 (C)';
         levelComment = '학습 패턴 개선이 필요합니다. 작은 목표부터 차근차근 달성해나가며 학습 습관을 길러보세요. 특히 꾸준한 학습 시간 확보에 우선 집중해보시기 바랍니다.';
       }
    } else {
      // fallback: 기존 방식
      final avgCompletionRate = (missionCompletionRate + challengeCompletionRate + goalCompletionRate) / 3;
      comprehensiveScore = avgCompletionRate;
      
      if (avgCompletionRate >= 80) {
        achievementLevel = '우수 (A)';
        levelComment = '매우 뛰어난 학습 성취도를 보이고 있습니다. 계획한 학습 활동을 꾸준히 완수하며 자기주도 학습 능력이 탁월합니다.';
      } else if (avgCompletionRate >= 60) {
        achievementLevel = '양호 (B)';
        levelComment = '안정적인 학습 패턴을 유지하고 있습니다. 목표 달성을 위해 꾸준히 노력하는 모습이 보이며, 조금 더 집중한다면 더 좋은 결과를 얻을 수 있을 것입니다.';
      } else if (avgCompletionRate >= 40) {
        achievementLevel = '보통 (C)';
        levelComment = '학습 활동에 참여하고 있으나 완료율이 아쉽습니다. 목표를 더 구체적으로 설정하고 꾸준한 학습 습관을 기르는 것이 필요합니다.';
      } else {
        achievementLevel = '개선 필요 (D)';
        levelComment = '학습 활동 참여도가 낮습니다. 작은 목표부터 시작하여 성취감을 느끼며 점진적으로 학습 습관을 만들어 나가는 것을 권장합니다.';
      }
    }

    return {
      'period': period,
      'totalActivities': missions.length + challenges.length + allGoals.length,
      'missionStats': {
        'total': missions.length,
        'completed': completedMissions,
        'completionRate': missionCompletionRate,
      },
      'challengeStats': {
        'total': challenges.length,
        'completed': completedChallenges,
        'completionRate': challengeCompletionRate,
      },
      'goalStats': {
        'total': allGoals.length,
        'completed': completedGoals,
        'completionRate': goalCompletionRate,
      },
      'studyTime': {
        'totalMinutes': totalStudyMinutes,
        'totalHours': (totalStudyMinutes / 60).round(),
        'dailyAverage': (totalStudyMinutes / period).round(),
      },
      'subjectDistribution': subjectDistribution,
      'achievement': {
        'level': achievementLevel,
        'comment': levelComment,
        'avgCompletionRate': comprehensiveScore,
      },
      'recommendations': _generateRecommendations(missionCompletionRate, challengeCompletionRate, goalCompletionRate),
      'realAnalysisData': realAnalysisData,
      'prevStudyTime': prevStudyTime,
      'recentStudyTime': recentStudyTime,
      'prevMissionCount': prevMissionCount,
      'recentMissionCount': recentMissionCount,
      'prevAvgScore': prevAvgScore,
      'recentAvgScore': recentAvgScore,
      'leastTimeSubject': leastTimeSubject,
      'mostTimeSubject': mostTimeSubject,
      'leastTime': leastTime,
      'mostTime': mostTime,
    };
  }

  // 맞춤형 추천사항 생성
  static List<String> _generateRecommendations(double missionRate, double challengeRate, double goalRate) {
    List<String> recommendations = [];

    if (missionRate < 60) {
      recommendations.add('일일 미션을 완료하는 습관을 기르세요. 작은 목표부터 시작하여 성취감을 느껴보세요.');
    } else if (missionRate >= 80) {
      recommendations.add('미션 완료율이 우수합니다! 더 도전적인 미션에 참여해보세요.');
    }

    if (challengeRate < 60) {
      recommendations.add('챌린지 참여를 늘려보세요. 친구들과 함께 하면 더 재미있게 학습할 수 있습니다.');
    } else if (challengeRate >= 80) {
      recommendations.add('챌린지 달성률이 훌륭합니다! 다양한 과목의 챌린지에 도전해보세요.');
    }

    if (goalRate < 60) {
      recommendations.add('목표를 더 구체적이고 달성 가능하게 설정해보세요. SMART 목표 설정법을 활용해보세요.');
    } else if (goalRate >= 80) {
      recommendations.add('목표 달성 능력이 뛰어납니다! 더 장기적이고 도전적인 목표를 세워보세요.');
    }

    // 기본 추천사항
    if (recommendations.isEmpty) {
      recommendations.add('꾸준한 학습 습관을 유지하며 점진적으로 학습량을 늘려나가세요.');
    }

    recommendations.add('부모님과 함께 학습 계획을 점검하고 피드백을 나누는 시간을 가져보세요.');
    
    return recommendations.take(4).toList(); // 최대 4개까지
  }

  // 전문 학습 보고서 PDF 생성
  static Future<void> _buildProfessionalAcademicReport(
    pw.Document pdf,
    String studentName,
    int period,
    Map<String, dynamic> academicData,
    Map<String, dynamic> analysis,
    Map<String, dynamic> analysisData,
    Map<String, dynamic> realAnalysisData,
  ) async {
    print('📄 전문 학습 보고서 작성 중...');

    final font = await PdfGoogleFonts.notoSansKRRegular();
    final boldFont = await PdfGoogleFonts.notoSansKRBold();

    // 1페이지: 표지 및 종합 평가
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // 헤더 (표지)
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(25),
                decoration: pw.BoxDecoration(
                  gradient: const pw.LinearGradient(
                    colors: [PdfColors.blue800, PdfColors.blue600],
                    begin: pw.Alignment.topLeft,
                    end: pw.Alignment.bottomRight,
                  ),
                  borderRadius: pw.BorderRadius.circular(15),
                ),
                child: pw.Column(
                  children: [
                    pw.Text(
                      '학습 성적 보고서',
                      style: pw.TextStyle(
                        font: boldFont,
                        fontSize: 28,
                        color: PdfColors.white,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                    pw.SizedBox(height: 15),
                    pw.Text(
                      '$studentName 학생',
                      style: pw.TextStyle(
                        font: boldFont,
                        fontSize: 22,
                        color: PdfColors.white,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                    pw.SizedBox(height: 10),
                    pw.Text(
                      '분석 기간: $period일 | 작성일: ${DateFormat('yyyy년 MM월 dd일').format(DateTime.now())}',
                      style: pw.TextStyle(
                        font: font,
                        fontSize: 14,
                        color: PdfColors.white,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                  ],
                ),
              ),
              
              pw.SizedBox(height: 30),

              // 종합 성취도
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(12),
                  border: pw.Border.all(color: PdfColors.blue300, width: 2),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      '■ 종합 성취도 평가',
                      style: pw.TextStyle(font: boldFont, fontSize: 18, color: PdfColors.blue800),
                    ),
                    pw.SizedBox(height: 15),
                    
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          '학습 성취 등급:',
                          style: pw.TextStyle(font: font, fontSize: 14),
                        ),
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                          decoration: pw.BoxDecoration(
                            color: _getGradeColor(analysis['achievement']['level']),
                            borderRadius: pw.BorderRadius.circular(20),
                          ),
                          child: pw.Text(
                            analysis['achievement']['level'],
                            style: pw.TextStyle(font: boldFont, fontSize: 16, color: PdfColors.white),
                          ),
                        ),
                      ],
                    ),
                    
                    pw.SizedBox(height: 15),
                    pw.Text(
                      analysis['achievement']['comment'],
                      style: pw.TextStyle(font: font, fontSize: 12, height: 1.5),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 25),

              // 핵심 학습 지표
              pw.Text(
                '■ 핵심 학습 지표',
                style: pw.TextStyle(font: boldFont, fontSize: 18, color: PdfColors.blue800),
              ),
              pw.SizedBox(height: 15),

              pw.Row(
                children: [
                  pw.Expanded(
                    child: _buildMetricCard(
                      '총 학습시간',
                      '${analysis['studyTime']['totalHours']}시간',
                      '일평균 ${analysis['studyTime']['dailyAverage']}분',
                      font,
                      boldFont,
                      PdfColors.green,
                    ),
                  ),
                  pw.SizedBox(width: 15),
                  pw.Expanded(
                    child: _buildMetricCard(
                      '참여 활동',
                      '${analysis['totalActivities']}개',
                      '미션+챌린지+목표',
                      font,
                      boldFont,
                      PdfColors.blue,
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 15),

              pw.Row(
                children: [
                  pw.Expanded(
                    child: _buildMetricCard(
                      '미션 완료율',
                      '${analysis['missionStats']['completionRate'].toStringAsFixed(1)}%',
                      '${analysis['missionStats']['completed']}/${analysis['missionStats']['total']}개 완료',
                      font,
                      boldFont,
                      PdfColors.orange,
                    ),
                  ),
                  pw.SizedBox(width: 15),
                  pw.Expanded(
                    child: _buildMetricCard(
                      '챌린지 완료율',
                      '${analysis['challengeStats']['completionRate'].toStringAsFixed(1)}%',
                      '${analysis['challengeStats']['completed']}/${analysis['challengeStats']['total']}개 완료',
                      font,
                      boldFont,
                      PdfColors.purple,
                    ),
                  ),
                ],
              ),

              pw.Spacer(),

              // 전문가 코멘트 미리보기
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(15),
                decoration: pw.BoxDecoration(
                  color: PdfColors.blue50,
                  borderRadius: pw.BorderRadius.circular(10),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      '■ 학습 매니저 종합 의견',
                      style: pw.TextStyle(font: boldFont, fontSize: 14, color: PdfColors.blue800),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      '$studentName 학생은 ${period}일 동안 ${analysis['totalActivities']}개의 학습 활동에 참여하였습니다.\n상세 분석과 맞춤형 개선 방안은 다음 페이지에서 확인하실 수 있습니다.',
                      style: pw.TextStyle(font: font, fontSize: 12, height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    // 2페이지: 상세 분석 및 그래프
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                '■ 상세 학습 분석',
                style: pw.TextStyle(font: boldFont, fontSize: 20, color: PdfColors.blue800),
              ),
              pw.SizedBox(height: 20),

              // 완료율 그래프
              pw.Text(
                '활동별 완료율 분석',
                style: pw.TextStyle(font: boldFont, fontSize: 16),
              ),
              pw.SizedBox(height: 15),

              _buildCompletionRateChart(analysis, font, boldFont),

              pw.SizedBox(height: 25),

              // 학습 활동 분포
              pw.Text(
                '■ 학습 활동 분포',
                style: pw.TextStyle(font: boldFont, fontSize: 16),
              ),
              pw.SizedBox(height: 15),

              _buildActivityDistributionChart(analysis, font, boldFont),

              pw.SizedBox(height: 25),

              // 전문가 상세 분석
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(18),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey50,
                  borderRadius: pw.BorderRadius.circular(12),
                  border: pw.Border.all(color: PdfColors.grey300),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      '■ 전문 학습 매니저 분석',
                      style: pw.TextStyle(font: boldFont, fontSize: 16, color: PdfColors.blue800),
                    ),
                    pw.SizedBox(height: 12),
                    
                    ..._buildRealAnalysisContent(analysis, realAnalysisData, font, boldFont, period),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    // 3페이지: 맞춤형 개선 방안
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                '■ 맞춤형 학습 개선 방안',
                style: pw.TextStyle(font: boldFont, fontSize: 20, color: PdfColors.blue800),
              ),
              pw.SizedBox(height: 20),

              // 추천사항
              pw.Text(
                '■ 전문가 추천사항',
                style: pw.TextStyle(font: boldFont, fontSize: 16),
              ),
              pw.SizedBox(height: 15),

              ...analysis['recommendations'].asMap().entries.map<pw.Widget>((entry) {
                int index = entry.key;
                String recommendation = entry.value;
                return pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 12),
                  padding: const pw.EdgeInsets.all(15),
                  decoration: pw.BoxDecoration(
                    color: index % 2 == 0 ? PdfColors.blue50 : PdfColors.green50,
                    borderRadius: pw.BorderRadius.circular(10),
                    border: pw.Border.all(
                      color: index % 2 == 0 ? PdfColors.blue200 : PdfColors.green200,
                      width: 1,
                    ),
                  ),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Container(
                        width: 25,
                        height: 25,
                        decoration: pw.BoxDecoration(
                          color: index % 2 == 0 ? PdfColors.blue : PdfColors.green,
                          shape: pw.BoxShape.circle,
                        ),
                        child: pw.Center(
                          child: pw.Text(
                            '${index + 1}',
                            style: pw.TextStyle(
                              font: boldFont,
                              fontSize: 12,
                              color: PdfColors.white,
                            ),
                          ),
                        ),
                      ),
                      pw.SizedBox(width: 12),
                      pw.Expanded(
                        child: pw.Text(
                          recommendation,
                          style: pw.TextStyle(font: font, fontSize: 12, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),

              pw.SizedBox(height: 25),

              // 다음 주 학습 계획
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  gradient: const pw.LinearGradient(
                    colors: [PdfColors.green100, PdfColors.blue100],
                    begin: pw.Alignment.topLeft,
                    end: pw.Alignment.bottomRight,
                  ),
                  borderRadius: pw.BorderRadius.circular(15),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      '■ 다음 주 학습 계획 제안',
                      style: pw.TextStyle(font: boldFont, fontSize: 16, color: PdfColors.blue800),
                    ),
                    pw.SizedBox(height: 15),
                    
                    pw.Text(
                      '- 일일 학습 목표: ${(analysis['studyTime']['dailyAverage'] * 1.2).toInt()}분 (현재보다 20% 증가)',
                      style: pw.TextStyle(font: font, fontSize: 12, height: 1.5),
                    ),
                    pw.Text(
                      '- 새로운 챌린지 참여: 주당 1-2개 추가 도전',
                      style: pw.TextStyle(font: font, fontSize: 12, height: 1.5),
                    ),
                    pw.Text(
                      '- 목표 설정: 구체적이고 측정 가능한 주간 목표 1-2개',
                      style: pw.TextStyle(font: font, fontSize: 12, height: 1.5),
                    ),
                    pw.Text(
                      '- 부모와의 학습 점검 시간: 주 2회, 각 15분씩',
                      style: pw.TextStyle(font: font, fontSize: 12, height: 1.5),
                    ),
                  ],
                ),
              ),

              pw.Spacer(),

              // 보고서 마무리
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(15),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(10),
                ),
                child: pw.Column(
                  children: [
                    pw.Text(
                      '■ 학습 상담 문의',
                      style: pw.TextStyle(font: boldFont, fontSize: 14, color: PdfColors.blue800),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      '더 자세한 학습 상담이나 개별 맞춤 지도가 필요하시면 언제든 문의해주세요.\n리틀뱅크 학습 매니저가 도움을 드리겠습니다.',
                      style: pw.TextStyle(font: font, fontSize: 11),
                      textAlign: pw.TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    print('✅ 전문 학습 보고서 작성 완료!');
  }

  // 등급별 색상 반환
  static PdfColor _getGradeColor(String grade) {
    if (grade.contains('A')) return PdfColors.green600;
    if (grade.contains('B')) return PdfColors.blue600;
    if (grade.contains('C')) return PdfColors.orange600;
    return PdfColors.red600;
  }

  // 지표 카드 생성 (개선된 버전)
  static pw.Widget _buildMetricCard(
    String title,
    String value,
    String subtitle,
    pw.Font font,
    pw.Font boldFont,
    PdfColor accentColor,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(12),
        border: pw.Border.all(color: accentColor, width: 2),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(font: boldFont, fontSize: 11, color: accentColor),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            value,
            style: pw.TextStyle(font: boldFont, fontSize: 18, color: accentColor),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            subtitle,
            style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.grey600),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );
  }

  // 완료율 차트 생성
  static pw.Widget _buildCompletionRateChart(
    Map<String, dynamic> analysis,
    pw.Font font,
    pw.Font boldFont,
  ) {
    final missionRate = analysis['missionStats']['completionRate'];
    final challengeRate = analysis['challengeStats']['completionRate'];
    final goalRate = analysis['goalStats']['completionRate'];

    return pw.Container(
      height: 150,
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
        children: [
          _buildBarChart('미션', missionRate, PdfColors.blue, font, boldFont),
          _buildBarChart('챌린지', challengeRate, PdfColors.green, font, boldFont),
          _buildBarChart('목표', goalRate, PdfColors.orange, font, boldFont),
        ],
      ),
    );
  }

  // 바 차트 개별 요소
  static pw.Widget _buildBarChart(
    String label,
    double percentage,
    PdfColor color,
    pw.Font font,
    pw.Font boldFont,
  ) {
    final barHeight = (percentage / 100 * 100).clamp(0.0, 100.0);
    
    return pw.Column(
      children: [
        pw.Container(
          width: 50,
          height: 100,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey400),
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Container(
                width: 50,
                height: barHeight,
                decoration: pw.BoxDecoration(
                  color: color,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          label,
          style: pw.TextStyle(font: boldFont, fontSize: 10),
        ),
        pw.Text(
          '${percentage.toStringAsFixed(1)}%',
          style: pw.TextStyle(font: font, fontSize: 9, color: color),
        ),
      ],
    );
  }

  // 활동 분포 차트
  static pw.Widget _buildActivityDistributionChart(
    Map<String, dynamic> analysis,
    pw.Font font,
    pw.Font boldFont,
  ) {
    final missionCount = analysis['missionStats']['total'];
    final challengeCount = analysis['challengeStats']['total'];
    final goalCount = analysis['goalStats']['total'];
    final total = missionCount + challengeCount + goalCount;

    if (total == 0) {
      return pw.Container(
        height: 100,
        child: pw.Center(
          child: pw.Text(
            '학습 활동 데이터가 없습니다.',
            style: pw.TextStyle(font: font, fontSize: 12, color: PdfColors.grey600),
          ),
        ),
      );
    }

    return pw.Row(
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildLegendItem('미션', missionCount, total, PdfColors.blue, font, boldFont),
              pw.SizedBox(height: 8),
              _buildLegendItem('챌린지', challengeCount, total, PdfColors.green, font, boldFont),
              pw.SizedBox(height: 8),
              _buildLegendItem('목표', goalCount, total, PdfColors.orange, font, boldFont),
            ],
          ),
        ),
        pw.SizedBox(width: 20),
        pw.Container(
          width: 100,
          height: 100,
          child: pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  _buildPieSlice(0, 0, PdfColors.blue),
                  pw.SizedBox(width: 5),
                  _buildPieSlice(0, 0, PdfColors.green),
                ],
              ),
              pw.SizedBox(height: 5),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  _buildPieSlice(0, 0, PdfColors.orange),
                  pw.SizedBox(width: 5),
                  pw.Container(width: 20, height: 20), // 빈 공간
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 범례 아이템
  static pw.Widget _buildLegendItem(
    String label,
    int count,
    int total,
    PdfColor color,
    pw.Font font,
    pw.Font boldFont,
  ) {
    final percentage = total > 0 ? (count / total * 100) : 0.0;
    
    return pw.Row(
      children: [
        pw.Container(
          width: 15,
          height: 15,
          decoration: pw.BoxDecoration(
            color: color,
            shape: pw.BoxShape.circle,
          ),
        ),
        pw.SizedBox(width: 8),
        pw.Text(
          '$label: ${count}개 (${percentage.toStringAsFixed(1)}%)',
          style: pw.TextStyle(font: font, fontSize: 11),
        ),
      ],
    );
  }

  // 파이 차트 조각 (간단한 색상 박스로 대체)
  static pw.Widget _buildPieSlice(double startAngle, double sweepAngle, PdfColor color) {
    return pw.Container(
      width: 20,
      height: 20,
      decoration: pw.BoxDecoration(
        color: color,
        shape: pw.BoxShape.circle,
      ),
    );
  }

  // 실제 분석 API 데이터 기반 상세 분석 콘텐츠
  static List<pw.Widget> _buildRealAnalysisContent(
    Map<String, dynamic> analysis, 
    Map<String, dynamic> realAnalysisData, 
    pw.Font font, 
    pw.Font boldFont, 
    int period
  ) {
    List<pw.Widget> widgets = [];
    
    if (realAnalysisData.isNotEmpty) {
      // 실제 API 데이터 기반 분석
      final prevStudyTime = realAnalysisData['prevStudyTime'] ?? 0;
      final recentStudyTime = realAnalysisData['recentStudyTime'] ?? 0;
      final prevMissionCount = realAnalysisData['prevMissionAchieveCount'] ?? 0;
      final recentMissionCount = realAnalysisData['recentMissionAchieveCount'] ?? 0;
      final prevAvgScore = (realAnalysisData['prevAvgScore'] ?? 0).toDouble();
      final recentAvgScore = (realAnalysisData['recentAvgScore'] ?? 0).toDouble();
      final leastTimeSubject = realAnalysisData['nameOfLeastTimeSubject'] ?? '';
      final mostTimeSubject = realAnalysisData['nameOfMostTimeSubject'] ?? '';
      final leastTime = realAnalysisData['timeOfLeastTimeSubject'] ?? 0;
      final mostTime = realAnalysisData['timeOfMostTimeSubject'] ?? 0;
      
             // 학습 시간 변화 분석
       widgets.add(
         pw.Text(
           '■ 학습 시간 변화 분석:',
           style: pw.TextStyle(font: boldFont, fontSize: 13, color: PdfColors.blue700),
         ),
       );
      widgets.add(pw.SizedBox(height: 5));
      
      final timeDiff = recentStudyTime - prevStudyTime;
      final timeChangeText = timeDiff > 0 
          ? '이전 기간 대비 ${AnalysisService.formatStudyTime(timeDiff)} 증가하여 학습 의욕이 높아지고 있습니다.'
          : timeDiff < 0 
              ? '이전 기간 대비 ${AnalysisService.formatStudyTime(timeDiff.abs())} 감소했지만, 꾸준한 격려로 회복 가능합니다.'
              : '안정적인 학습 시간을 유지하고 있어 일정한 학습 패턴을 보입니다.';
      
      widgets.add(
        pw.Text(
          '${AnalysisService.formatStudyTime(prevStudyTime)} → ${AnalysisService.formatStudyTime(recentStudyTime)} ($timeChangeText)',
          style: pw.TextStyle(font: font, fontSize: 11, height: 1.4),
        ),
      );
      
      widgets.add(pw.SizedBox(height: 12));
      
             // 미션 달성률 분석
       widgets.add(
         pw.Text(
           '■ 미션 달성 현황 분석:',
           style: pw.TextStyle(font: boldFont, fontSize: 13, color: PdfColors.green700),
         ),
       );
      widgets.add(pw.SizedBox(height: 5));
      
      final missionDiff = recentMissionCount - prevMissionCount;
      final missionChangeText = missionDiff > 0 
          ? '${missionDiff}개 증가하여 목표 달성 능력이 향상되고 있습니다.'
          : missionDiff < 0 
              ? '${missionDiff.abs()}개 감소했지만, 적절한 난이도 조정으로 개선 가능합니다.'
              : '일정한 달성률을 유지하고 있어 안정적인 수행 능력을 보입니다.';
      
      widgets.add(
        pw.Text(
          '${prevMissionCount}개 → ${recentMissionCount}개 ($missionChangeText)',
          style: pw.TextStyle(font: font, fontSize: 11, height: 1.4),
        ),
      );
      
      widgets.add(pw.SizedBox(height: 12));
      
             // 성적 변화 분석
       widgets.add(
         pw.Text(
           '■ 성적 변화 분석:',
           style: pw.TextStyle(font: boldFont, fontSize: 13, color: PdfColors.purple700),
         ),
       );
      widgets.add(pw.SizedBox(height: 5));
      
      final scoreDiff = recentAvgScore - prevAvgScore;
      final scoreChangeText = scoreDiff > 0 
          ? '${scoreDiff.toStringAsFixed(1)}점 상승하여 학습 효과가 나타나고 있습니다.'
          : scoreDiff < 0 
              ? '${scoreDiff.abs().toStringAsFixed(1)}점 하락했지만, 학습 방법 개선으로 회복 가능합니다.'
              : '안정적인 성적을 유지하고 있어 꾸준한 실력을 보이고 있습니다.';
      
      widgets.add(
        pw.Text(
          '${prevAvgScore.toStringAsFixed(1)}점 → ${recentAvgScore.toStringAsFixed(1)}점 ($scoreChangeText)',
          style: pw.TextStyle(font: font, fontSize: 11, height: 1.4),
        ),
      );
      
      // 과목별 분석 (데이터가 있는 경우)
      if (leastTimeSubject.isNotEmpty && mostTimeSubject.isNotEmpty) {
        widgets.add(pw.SizedBox(height: 12));
                 widgets.add(
           pw.Text(
             '■ 과목별 학습 패턴:',
             style: pw.TextStyle(font: boldFont, fontSize: 13, color: PdfColors.orange700),
           ),
         );
        widgets.add(pw.SizedBox(height: 5));
        
        widgets.add(
          pw.Text(
            '가장 많이 학습한 과목: $mostTimeSubject (${AnalysisService.formatStudyTime(mostTime)})\n'
            '상대적으로 적게 학습한 과목: $leastTimeSubject (${AnalysisService.formatStudyTime(leastTime)})\n'
            '→ 균형잡힌 학습을 위해 $leastTimeSubject 과목 학습 시간을 늘려보는 것을 권장합니다.',
            style: pw.TextStyle(font: font, fontSize: 11, height: 1.4),
          ),
        );
      }
      
    } else {
      // fallback: 기본 분석
      widgets.add(
        pw.Text(
          '강점 분석:',
          style: pw.TextStyle(font: boldFont, fontSize: 13, color: PdfColors.green700),
        ),
      );
      widgets.add(pw.SizedBox(height: 5));
      widgets.add(
        pw.Text(
          _generateStrengthAnalysis(analysis),
          style: pw.TextStyle(font: font, fontSize: 11, height: 1.4),
        ),
      );
      
      widgets.add(pw.SizedBox(height: 12));
      
      widgets.add(
        pw.Text(
          '개선 포인트:',
          style: pw.TextStyle(font: boldFont, fontSize: 13, color: PdfColors.orange700),
        ),
      );
      widgets.add(pw.SizedBox(height: 5));
      widgets.add(
        pw.Text(
          _generateImprovementAnalysis(analysis),
          style: pw.TextStyle(font: font, fontSize: 11, height: 1.4),
        ),
      );
    }
    
    return widgets;
  }

  // 강점 분석 생성
  static String _generateStrengthAnalysis(Map<String, dynamic> analysis) {
    List<String> strengths = [];
    
    if (analysis['missionStats']['completionRate'] >= 70) {
      strengths.add('미션 완료율이 우수하여 꾸준한 학습 습관을 보유하고 있습니다');
    }
    
    if (analysis['challengeStats']['completionRate'] >= 70) {
      strengths.add('챌린지 달성률이 높아 도전 정신과 목표 달성 의지가 강합니다');
    }
    
    if (analysis['studyTime']['totalHours'] >= 10) {
      strengths.add('충분한 학습 시간을 확보하여 집중력과 지속력이 뛰어납니다');
    }
    
    if (analysis['totalActivities'] >= 5) {
      strengths.add('다양한 학습 활동에 적극적으로 참여하는 능동적인 학습 태도를 보입니다');
    }
    
    if (strengths.isEmpty) {
      return '학습에 대한 기본적인 관심과 참여 의지를 보이고 있으며, 앞으로 더 발전할 수 있는 잠재력을 가지고 있습니다.';
    }
    
    return strengths.join('. ') + '.';
  }

  // 개선점 분석 생성
  static String _generateImprovementAnalysis(Map<String, dynamic> analysis) {
    List<String> improvements = [];
    
    if (analysis['missionStats']['completionRate'] < 60) {
      improvements.add('미션 완료율을 높이기 위해 일일 학습 계획을 더 구체적으로 수립해보세요');
    }
    
    if (analysis['challengeStats']['completionRate'] < 60) {
      improvements.add('챌린지 성공률 향상을 위해 적절한 난이도의 챌린지부터 시작하여 자신감을 키워보세요');
    }
    
    if (analysis['studyTime']['dailyAverage'] < 30) {
      improvements.add('일일 학습 시간을 점진적으로 늘려 꾸준한 학습 리듬을 만들어보세요');
    }
    
    if (analysis['totalActivities'] < 3) {
      improvements.add('더 다양한 학습 활동에 참여하여 학습의 재미를 발견해보세요');
    }
    
    if (improvements.isEmpty) {
      return '현재 학습 패턴을 유지하면서 점진적으로 학습량과 난이도를 늘려나가는 것을 권장합니다.';
    }
    
    return improvements.join('. ') + '.';
  }

  // PDF 저장 및 공유
  static Future<void> _savePdfAndShare(Uint8List bytes, String fileName) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(bytes);

      print('✅ 학습 보고서 저장 완료: ${file.path}');

      // 공유
      await Share.shareXFiles(
        [XFile(file.path)],
        text: '$fileName',
        subject: '학습 성적 보고서',
      );
    } catch (e) {
      print('❌ 보고서 저장/공유 실패: $e');
      rethrow;
    }
  }
}  