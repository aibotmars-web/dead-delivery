import 'package:flutter/material.dart';

import '../config/constants.dart';

class ParkingTicketOverlay extends StatelessWidget {
  final int fine;
  final VoidCallback onDismiss;

  const ParkingTicketOverlay({
    super.key,
    required this.fine,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withAlpha(200),
      child: Center(
        child: Container(
          width: 300,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Color(AppColors.bgDark),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Color(AppColors.neonRed), width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🅿️', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 8),
              const Text(
                '違規停車罰單！',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '你的機車停在紅線上\n被開了一張罰單',
                style: TextStyle(
                  color: Color(AppColors.uiGray),
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Color(AppColors.bgLight),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '罰款金額',
                      style: TextStyle(color: Color(AppColors.uiGray), fontSize: 14),
                    ),
                    Text(
                      '-\$$fine',
                      style: TextStyle(
                        color: Color(AppColors.coralRed),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    width: 16,
                    height: 4,
                    color: Colors.red,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '紅線 = 禁止停車',
                    style: TextStyle(color: Color(AppColors.uiGray), fontSize: 11),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 16,
                    height: 4,
                    color: Colors.yellow,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '黃線 = 臨停',
                    style: TextStyle(color: Color(AppColors.uiGray), fontSize: 11),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    width: 16,
                    height: 4,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '白線 = 可停車',
                    style: TextStyle(color: Color(AppColors.uiGray), fontSize: 11),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: onDismiss,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(AppColors.coralRed),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    '繳納罰款',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
