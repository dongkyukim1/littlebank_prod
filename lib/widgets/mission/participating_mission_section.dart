import 'package:flutter/material.dart';

class ParticipatingMissionSection extends StatelessWidget {
  const ParticipatingMissionSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더 영역
          Row(
            children: [
              Text(
                '내가 참여 중인 미션 ',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                '3',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          SizedBox(height: 16),

          // 필터 옵션 버튼
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildMissionFilterButton('3월 셋째주 학원 미션', true),
                SizedBox(width: 8),
                _buildMissionFilterButton('D-3', false),
                SizedBox(width: 8),
                _buildMissionFilterButton('관련성', false),
              ],
            ),
          ),

          SizedBox(height: 16),

          // 미션 제목
          Text(
            '수학 이차방정식 88p까지 풀어오기',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),

          SizedBox(height: 12),

          // 보상 금액 표시 (프로그레스 바 위쪽으로 이동)
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 240, 103, 94),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '30,000원',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          SizedBox(height: 4),

          // 진행 상황 표시 바
          Stack(
            clipBehavior: Clip.none,
            children: [
              // 배경 바
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(3),
                ),
              ),

              // 진행 바
              Container(
                height: 6,
                width: MediaQuery.of(context).size.width * 0.22,
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),

              // 포인트 마커들 - 0%
              Positioned(
                left: 0,
                top: -3,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),

              // 포인트 마커들 - 25%
              Positioned(
                left: MediaQuery.of(context).size.width * 0.22,
                top: -3,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),

              // 포인트 마커들 - 50%
              Positioned(
                left: MediaQuery.of(context).size.width * 0.4,
                top: -3,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),

              // 포인트 마커들 - 75%
              Positioned(
                left: MediaQuery.of(context).size.width * 0.6,
                top: -3,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),

              // 포인트 마커들 - 100%
              Positioned(
                left: MediaQuery.of(context).size.width * 0.8,
                top: -3,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 16),

          // 퍼센트 텍스트
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '0%',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              Text(
                '25%',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              Text(
                '50%',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              Text(
                '75%',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              Text(
                '100%',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMissionFilterButton(String text, bool isSelected) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? Colors.pink : Colors.grey[300]!,
          width: 1.5,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: isSelected ? Colors.pink : Colors.grey[700],
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
