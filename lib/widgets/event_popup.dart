import 'package:flutter/material.dart';

import '../config/constants.dart';
import '../models/city_event.dart';

/// Event choice popup overlay
class EventPopup extends StatelessWidget {
  final CityEvent? event;
  final void Function(EventChoice choice) onChoiceSelected;

  const EventPopup({
    super.key,
    this.event,
    required this.onChoiceSelected,
  });

  @override
  Widget build(BuildContext context) {
    final displayEvent = event ?? CityEvent.allEvents.first; // fallback

    return Container(
      color: Colors.black.withAlpha(180),
      child: Center(
        child: Container(
          width: 300,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Color(AppColors.bgDark),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Color(AppColors.neonGold), width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              const Text('⚠️', style: TextStyle(fontSize: 40)),
              const SizedBox(height: 12),

              // Title
              Text(
                displayEvent.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // Description
              Text(
                displayEvent.description,
                style: TextStyle(
                  color: Color(AppColors.uiGray),
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // Choices
              ...displayEvent.choices.map((choice) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => onChoiceSelected(choice),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(AppColors.bgLight),
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          choice.text,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (choice.description.isNotEmpty)
                          Text(
                            choice.description,
                            style: TextStyle(
                              color: Color(AppColors.uiGray),
                              fontSize: 11,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }
}
