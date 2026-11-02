import 'package:flutter/material.dart';
import '../../../core/models/trip_day.dart';
import 'day_edit_dialog.dart';

class LodgingBadge extends StatelessWidget {
  final TripDay day;

  const LodgingBadge({super.key, required this.day});

  @override
  Widget build(BuildContext context) {
    if (day.dayNumber == 0) return const SizedBox.shrink();

    final hasDifferentWakeup =
        day.wakeupCity.isNotEmpty &&
        day.wakeupCity.toLowerCase() != day.lodgingCity.toLowerCase();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
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
                  day.lodgingCity.isNotEmpty
                      ? 'Dormir em: ${day.lodgingCity}'
                      : 'Hospedagem não definida',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF15803D),
                  ),
                ),
              ),
              if (hasDifferentWakeup) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFF86EFAC)),
                  ),
                  child: Text(
                    'Acorda em: ${day.wakeupCity}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF166534),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
              ],
              IconButton(
                icon: const Icon(
                  Icons.edit_outlined,
                  size: 16,
                  color: Color(0xFF15803D),
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: 'Editar Dia',
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => DayEditDialog(day: day),
                  );
                },
              ),
            ],
          ),
          if (day.title.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              day.title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
