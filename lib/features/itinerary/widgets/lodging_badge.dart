import 'package:flutter/material.dart';
import '../../../core/models/trip_day.dart';

class LodgingBadge extends StatelessWidget {
  final TripDay day;

  const LodgingBadge({super.key, required this.day});

  @override
  Widget build(BuildContext context) {
    final hasDifferentWakeup =
        day.wakeupCity.isNotEmpty &&
        day.wakeupCity.toLowerCase() != day.lodgingCity.toLowerCase();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4), // Subtle mint green
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.hotel_rounded,
                size: 18,
                color: Color(0xFF15803D),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Lodging tonight: ${day.lodgingCity}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF15803D),
                  ),
                ),
              ),
              if (hasDifferentWakeup)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF86EFAC)),
                  ),
                  child: Text(
                    'Waking up: ${day.wakeupCity}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF166534),
                    ),
                  ),
                ),
            ],
          ),
          if (day.title.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              day.title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1E293B),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
