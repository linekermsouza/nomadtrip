import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/itinerary_provider.dart';

class DaySelector extends ConsumerWidget {
  const DaySelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final daysAsync = ref.watch(itineraryProvider);
    final selectedDay = ref.watch(selectedDayNumberProvider);

    return daysAsync.when(
      data: (days) {
        return SizedBox(
          height: 72,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            scrollDirection: Axis.horizontal,
            itemCount: days.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final day = days[index];
              final isSelected = day.dayNumber == selectedDay;

              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    ref
                        .read(selectedDayNumberProvider.notifier)
                        .selectDay(day.dayNumber);
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF0F766E)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF0F766E)
                            : const Color(0xFFE2E8F0),
                        width: 1.5,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: const Color(
                                  0xFF0F766E,
                                ).withValues(alpha: 0.25),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ]
                          : [],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          day.dayNumber == 0
                              ? 'No Day'
                              : 'Day ${day.dayNumber}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          day.dayNumber == 0
                              ? 'Unscheduled'
                              : '${day.displayDate} (${day.weekday.substring(0, day.weekday.length < 3 ? day.weekday.length : 3)})',
                          style: TextStyle(
                            fontSize: 11,
                            color: isSelected
                                ? Colors.white70
                                : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
      loading: () => const SizedBox(height: 72),
      error: (err, stack) => const SizedBox.shrink(),
    );
  }
}
