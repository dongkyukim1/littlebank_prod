import 'package:flutter/material.dart';
import '../../../models/challenge/challenge_data.dart';
import '../../../theme/challenge/challenge_styles.dart';

class TimeSelector extends StatelessWidget {
  final ChallengeData challengeData;
  final Function(int, int) onTimeSelected;

  const TimeSelector({
    super.key,
    required this.challengeData,
    required this.onTimeSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: ChallengeStyles.timePickerBoxDecoration,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 현재 선택된 시간 표시
          Text(
            _formatTime(
              challengeData.selectedHour,
              challengeData.selectedMinute,
            ),
            style: ChallengeStyles.subTitleStyle,
          ),

          // 시간 선택 버튼
          ElevatedButton(
            onPressed: () => _showTimePicker(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: ChallengeStyles.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('시간 선택'),
          ),
        ],
      ),
    );
  }

  // 시간 포맷팅 (오전/오후 표시)
  String _formatTime(int hour, int minute) {
    final period = hour < 12 ? '오전' : '오후';
    final displayHour = hour <= 12 ? hour : hour - 12;
    final displayHour12 = displayHour == 0 ? 12 : displayHour;
    return '$period ${displayHour12.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  // 시간 선택 다이얼로그 표시
  Future<void> _showTimePicker(BuildContext context) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: challengeData.selectedHour,
        minute: challengeData.selectedMinute,
      ),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: ChallengeStyles.primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: ChallengeStyles.textDarkColor,
            ), dialogTheme: DialogThemeData(backgroundColor: Colors.white),
          ),
          child: child!,
        );
      },
    );

    if (pickedTime != null) {
      // 선택된 시간 업데이트
      onTimeSelected(pickedTime.hour, pickedTime.minute);
    }
  }
}

class DurationSelector extends StatelessWidget {
  final ChallengeData challengeData;
  final Function(String) onDurationSelected;

  const DurationSelector({
    super.key,
    required this.challengeData,
    required this.onDurationSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children:
          challengeData.durations.map((duration) {
            final bool isSelected = challengeData.selectedDuration == duration;
            return GestureDetector(
              onTap: () => onDurationSelected(duration),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: ChallengeStyles.durationChipDecoration(
                  isSelected: isSelected,
                ),
                child: Text(
                  duration,
                  style: ChallengeStyles.durationChipTextStyle(
                    isSelected: isSelected,
                  ),
                ),
              ),
            );
          }).toList(),
    );
  }
}

class AmountInput extends StatelessWidget {
  final ChallengeData challengeData;
  final Function(String) onAmountChanged;

  const AmountInput({
    super.key,
    required this.challengeData,
    required this.onAmountChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: ChallengeStyles.inputBoxDecoration,
      child: TextField(
        controller: TextEditingController(text: challengeData.totalAmount),
        keyboardType: TextInputType.number,
        style: ChallengeStyles.subTitleStyle,
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 12),
          suffix: Text('원'),
        ),
        onChanged: onAmountChanged,
      ),
    );
  }
}

class SaveButton extends StatelessWidget {
  final ChallengeData challengeData;
  final VoidCallback onSave;

  const SaveButton({
    super.key,
    required this.challengeData,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: challengeData.saveButtonEnabled ? onSave : null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: ChallengeStyles.saveButtonDecoration(
          isEnabled: challengeData.saveButtonEnabled,
        ),
        alignment: Alignment.center,
        child: const Text('신청하기', style: ChallengeStyles.saveButtonTextStyle),
      ),
    );
  }
}
