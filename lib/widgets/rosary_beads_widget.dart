import 'package:flutter/material.dart';

class RosaryBeadsWidget extends StatelessWidget {
  final int current;
  final int total;

  const RosaryBeadsWidget({
    super.key,
    required this.current,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 4,
          runSpacing: 8,
          children: List.generate(total, (index) {
            final isCompleted = index <= current;
            return Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted ? const Color(0xFFFBBF24) : Colors.grey.shade200,
                border: Border.all(
                  color: isCompleted ? const Color(0xFFF59E0B) : Colors.grey.shade300,
                  width: 2,
                ),
                boxShadow: isCompleted
                    ? [
                        BoxShadow(
                          color: const Color(0xFFFBBF24).withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
            );
          }),
        ),
      ),
    );
  }
}