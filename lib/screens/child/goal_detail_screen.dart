import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import '../../theme/app_theme.dart';
import 'package:intl/intl.dart';

class GoalDetailScreen extends StatefulWidget {
  final Map<String, dynamic> goal;

  const GoalDetailScreen({super.key, required this.goal});

  @override
  State<GoalDetailScreen> createState() => _GoalDetailScreenState();
}

class _GoalDetailScreenState extends State<GoalDetailScreen> {
  late final TextEditingController _amountController;
  double _sliderValue = 1000;
  final double _minAmount = 1000;
  final double _maxAmount = 10000;
  final double _step = 1000;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: _sliderValue.toInt().toString(),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final goal = widget.goal;
    final double progress = goal['currentAmount'] / goal['targetAmount'];
    final int daysRemaining =
        goal['targetDate'].difference(DateTime.now()).inDays;
    final DateFormat dateFormat = DateFormat('yyyy년 MM월 dd일');
    final String targetDateFormatted = dateFormat.format(goal['targetDate']);

    return Scaffold(
      appBar: AppBar(
        title: const Text('목표 상세'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // 목표 수정 기능 구현
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 목표 카드
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 진행률 원형 표시
                    CircularPercentIndicator(
                      radius: 70.0,
                      lineWidth: 10.0,
                      percent: progress,
                      center: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${(progress * 100).toInt()}%',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 24,
                            ),
                          ),
                          Text(
                            '$daysRemaining일 남음',
                            style: TextStyle(
                              color:
                                  daysRemaining < 7 ? Colors.red : Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      progressColor: AppTheme.primaryColor,
                      backgroundColor: Colors.grey.shade200,
                      circularStrokeCap: CircularStrokeCap.round,
                    ),

                    const SizedBox(height: 20),

                    // 목표 제목
                    Text(
                      goal['title'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 8),

                    // 금액 정보
                    Text(
                      '${goal['currentAmount']}원 / ${goal['targetAmount']}원',
                      style: const TextStyle(color: Colors.grey, fontSize: 16),
                    ),

                    const SizedBox(height: 16),

                    // 선형 진행률 표시
                    LinearPercentIndicator(
                      lineHeight: 14.0,
                      percent: progress,
                      backgroundColor: Colors.grey.shade200,
                      progressColor: AppTheme.primaryColor,
                      barRadius: const Radius.circular(7),
                      padding: EdgeInsets.zero,
                    ),

                    const SizedBox(height: 16),

                    // 목표 날짜
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('목표 날짜'),
                        Text(
                          targetDateFormatted,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 용돈 추가 섹션
            const Text(
              '용돈 적립하기',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 16),

            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('적립할 금액'),

                    const SizedBox(height: 8),

                    // 금액 입력 필드
                    TextField(
                      controller: _amountController,
                      decoration: const InputDecoration(
                        suffixText: '원',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        if (value.isNotEmpty) {
                          final amount = double.tryParse(value);
                          if (amount != null) {
                            setState(() {
                              _sliderValue = amount.clamp(
                                _minAmount,
                                _maxAmount,
                              );
                            });
                          }
                        }
                      },
                    ),

                    const SizedBox(height: 16),

                    // 금액 슬라이더
                    Slider(
                      value: _sliderValue,
                      min: _minAmount,
                      max: _maxAmount,
                      divisions: (_maxAmount - _minAmount) ~/ _step,
                      label: '${_sliderValue.toInt()}원',
                      onChanged: (value) {
                        setState(() {
                          _sliderValue = value;
                          _amountController.text = value.toInt().toString();
                        });
                      },
                    ),

                    // 금액 퀵 버튼
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          [1000, 2000, 5000, 10000].map((amount) {
                            return ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _sliderValue = amount.toDouble().clamp(
                                    _minAmount,
                                    _maxAmount,
                                  );
                                  _amountController.text = amount.toString();
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey.shade200,
                                foregroundColor: Colors.black,
                              ),
                              child: Text('$amount원'),
                            );
                          }).toList(),
                    ),

                    const SizedBox(height: 16),

                    // 적립하기 버튼
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          _addAllowanceToGoal();
                        },
                        child: const Text('적립하기'),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 적립 내역
            const Text(
              '적립 내역',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            // 적립 내역 리스트
            Card(
              elevation: 1,
              child: ListView(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildHistoryItem('2000원 적립', '2일 전'),
                  const Divider(height: 1),
                  _buildHistoryItem('3000원 적립', '5일 전'),
                  const Divider(height: 1),
                  _buildHistoryItem('첫 적립 - 시작', '7일 전'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryItem(String title, String date) {
    return ListTile(
      title: Text(title),
      trailing: Text(
        date,
        style: const TextStyle(color: Colors.grey, fontSize: 14),
      ),
    );
  }

  void _addAllowanceToGoal() {
    try {
      final int amount = int.parse(_amountController.text);
      if (amount <= 0) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('유효한 금액을 입력해주세요')));
        return;
      }

      // 실제 앱에서는 서버와 통신하여 목표에 적립 처리
      final int remainingAmount =
          widget.goal['targetAmount'] - widget.goal['currentAmount'];
      final int newCurrentAmount = widget.goal['currentAmount'] + amount;

      if (amount > remainingAmount) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('목표액을 초과했습니다. 최대 $remainingAmount원까지 적립할 수 있습니다'),
          ),
        );
        return;
      }

      // 실제 앱에서는 상태 관리를 통해 목표 정보 업데이트
      setState(() {
        widget.goal['currentAmount'] = newCurrentAmount;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$amount원이 적립되었습니다!')));

      // 목표 달성 시 축하 메시지
      if (newCurrentAmount >= widget.goal['targetAmount']) {
        _showCongratulationsDialog();
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('유효한 금액을 입력해주세요')));
    }
  }

  void _showCongratulationsDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('🎉 목표 달성!'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.stars, color: Colors.amber, size: 64),
                const SizedBox(height: 16),
                Text(
                  '${widget.goal['title']} 목표를 달성했습니다!\n정말 대단해요!',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('확인'),
              ),
            ],
          ),
    );
  }
}
