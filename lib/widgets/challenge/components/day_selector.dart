import 'package:flutter/material.dart';
import '../../../models/challenge/challenge_data.dart';
import '../../../theme/challenge/challenge_styles.dart';

class DaySelector extends StatelessWidget {
  final ChallengeData challengeData;
  final Function(DateTime) onDateSelected;
  final Function(int) onMonthChanged;

  const DaySelector({
    super.key,
    required this.challengeData,
    required this.onDateSelected,
    required this.onMonthChanged,
  });

  @override
  Widget build(BuildContext context) {
    // 종료 날짜 계산
    final DateTime endDate = challengeData.calculateEndDate();

    // 선택한 월의 첫 번째 날
    final firstDayOfMonth = DateTime(
      challengeData.currentYear,
      challengeData.currentMonth,
      1,
    );

    // 선택한 월의 마지막 날
    final lastDayOfMonth = DateTime(
      challengeData.currentYear,
      challengeData.currentMonth + 1,
      0,
    );

    // 첫 번째 날이 무슨 요일인지 (0: 월요일, 1: 화요일, ..., 6: 일요일)
    int firstWeekday = firstDayOfMonth.weekday - 1;
    if (firstWeekday < 0) firstWeekday = 6; // 일요일인 경우

    // 해당 월의 총 일수
    final daysInMonth = lastDayOfMonth.day;

    // 달력에 표시할 총 셀 수 (최대 6주 = 42칸)
    final totalCells = ((firstWeekday + daysInMonth) / 7).ceil() * 7;

    return Column(
      children: [
        // 선택된 날짜 정보 표시
        _buildSelectedDateInfo(endDate),

        const SizedBox(height: 12),

        // 달력 헤더 (월 선택 기능 포함)
        _buildCalendarHeader(),

        // 요일 헤더
        _buildDayLabels(),

        // 날짜 그리드
        _buildCalendarGrid(firstWeekday, daysInMonth, totalCells.toInt()),
      ],
    );
  }

  // 선택된 날짜 및 챌린지 기간 정보
  Widget _buildSelectedDateInfo(DateTime endDate) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: ChallengeStyles.selectedDateBoxDecoration,
      child: Column(
        children: [
          // 선택된 날짜 표시
          Row(
            children: [
              Icon(Icons.calendar_today, color: Colors.amber[700], size: 16),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  '${challengeData.selectedDate.year}년 ${challengeData.selectedDate.month}월 ${challengeData.selectedDate.day}일 (${challengeData.selectedDay})',
                  style: ChallengeStyles.selectedDateTextStyle,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // 챌린지 기간 표시
          Row(
            children: [
              Icon(Icons.date_range, color: Colors.blue[700], size: 14),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  '챌린지 기간: ${challengeData.selectedDate.month}월 ${challengeData.selectedDate.day}일 ~ ${endDate.month}월 ${endDate.day}일',
                  style: ChallengeStyles.dateRangeTextStyle,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 달력 헤더 (월/년 선택)
  Widget _buildCalendarHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: ChallengeStyles.calendarHeaderDecoration,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 이전 달 버튼
          InkWell(
            onTap: () => onMonthChanged(-1),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: ChallengeStyles.monthButtonDecoration,
              child: Icon(
                Icons.chevron_left,
                color: Colors.blue[700],
                size: 20,
              ),
            ),
          ),
          // 현재 월 표시
          Text(
            '${challengeData.currentYear}년 ${challengeData.currentMonth}월',
            style: ChallengeStyles.monthTextStyle,
          ),
          // 다음 달 버튼
          InkWell(
            onTap: () => onMonthChanged(1),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: ChallengeStyles.monthButtonDecoration,
              child: Icon(
                Icons.chevron_right,
                color: Colors.blue[700],
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 요일 헤더
  Widget _buildDayLabels() {
    return Container(
      decoration: ChallengeStyles.dayRowDecoration,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(7, (index) {
          return Container(
            width: 40,
            padding: const EdgeInsets.symmetric(vertical: 10),
            alignment: Alignment.center,
            child: Text(
              challengeData.days[index],
              style: ChallengeStyles.dayHeaderTextStyle,
            ),
          );
        }),
      ),
    );
  }

  // 날짜 그리드
  Widget _buildCalendarGrid(int firstWeekday, int daysInMonth, int totalCells) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          childAspectRatio: 1.0,
        ),
        itemCount: totalCells,
        itemBuilder: (context, index) {
          // 날짜 계산
          final int day = index - firstWeekday + 1;

          // 현재 월에 속하는 날짜인지 확인
          final bool isCurrentMonth = day > 0 && day <= daysInMonth;

          // 현재 월에 속하지 않는 경우 빈 셀 표시
          if (!isCurrentMonth) {
            return Container();
          }

          // 해당 날짜의 DateTime 객체 생성
          final date = DateTime(
            challengeData.currentYear,
            challengeData.currentMonth,
            day,
          );

          // 선택된 날짜와 동일한지 확인
          final bool isSelected =
              date.year == challengeData.selectedDate.year &&
              date.month == challengeData.selectedDate.month &&
              date.day == challengeData.selectedDate.day;

          // 오늘 날짜인지 확인
          final bool isToday =
              date.year == today.year &&
              date.month == today.month &&
              date.day == today.day;

          // 선택 가능한 날짜인지 확인 (오늘 이후의 날짜만 선택 가능)
          final bool isSelectable = date.isAfter(
            now.subtract(const Duration(days: 1)),
          );

          return GestureDetector(
            onTap: isSelectable ? () => onDateSelected(date) : null,
            child: Container(
              margin: const EdgeInsets.all(4),
              decoration: ChallengeStyles.calendarCellDecoration(
                isSelected: isSelected,
                isToday: isToday,
              ),
              child: Center(
                child: Text(
                  day.toString(),
                  style: ChallengeStyles.calendarCellTextStyle(
                    isSelected: isSelected,
                    isCurrentMonth: isCurrentMonth,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
