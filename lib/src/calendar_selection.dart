import 'package:flutter/material.dart';

enum GeneralCalendarView { month, week, year }

enum CalendarSelectionMode { single, multiple, range }

/// Immutable selection emitted after user interaction.
///
/// In range mode [rangeStart] can be non-null while [rangeEnd] is null. [range]
/// is only available after the user chooses both endpoints. [dates] contains
/// selected dates in single/multiple mode and is empty in range mode.
@immutable
class CalendarSelection {
  CalendarSelection({
    required this.mode,
    List<DateTime> dates = const [],
    this.rangeStart,
    this.rangeEnd,
  }) : dates = List.unmodifiable(dates);

  final CalendarSelectionMode mode;
  final List<DateTime> dates;
  final DateTime? rangeStart;
  final DateTime? rangeEnd;

  DateTime? get date => dates.isEmpty ? null : dates.first;

  DateTimeRange<DateTime>? get range => rangeStart == null || rangeEnd == null
      ? null
      : DateTimeRange(start: rangeStart!, end: rangeEnd!);
}
