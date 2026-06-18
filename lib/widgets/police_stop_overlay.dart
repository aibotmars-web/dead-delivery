import 'package:flutter/material.dart';

import '../config/constants.dart';
import '../game/systems/police_system.dart';

class PoliceStopOverlay extends StatelessWidget {
  final PoliceEncounter encounter;
  final VoidCallback onDismiss;

  const PoliceStopOverlay({
    super.key,
    required this.encounter,
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
            border: Border.all(color: Color(AppColors.coralRed), width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🚨', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 8),
              const Text(
                '警察臨檢！',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                encounter.message,
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
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '罰款',
                          style: TextStyle(color: Color(AppColors.uiGray), fontSize: 14),
                        ),
                        Text(
                          '-\$${encounter.fine}',
                          style: TextStyle(
                            color: Color(AppColors.coralRed),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '耽誤時間',
                          style: TextStyle(color: Color(AppColors.uiGray), fontSize: 14),
                        ),
                        Text(
                          '+${encounter.timePenalty}秒',
                          style: TextStyle(
                            color: Color(AppColors.coralRed),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
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
                    '認罰繳款',
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
