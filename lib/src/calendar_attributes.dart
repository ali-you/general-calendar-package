import 'package:flutter/material.dart';

/// Labels added by this package. Flutter supplies date and dialog translations;
/// provide these labels for the application's locale.
@immutable
class GeneralCalendarLabels {
  const GeneralCalendarLabels({
    this.month = 'Month',
    this.week = 'Week',
    this.year = 'Year',
    this.holiday = 'Holiday',
    this.vacation = 'Vacation',
    this.chooseView = 'Choose calendar view',
  });

  final String month;
  final String week;
  final String year;
  final String holiday;
  final String vacation;
  final String chooseView;
}

/// A label displayed as a colored marker below a day number.
@immutable
class CalendarTag {
  const CalendarTag({required this.label, this.color});

  final String label;
  final Color? color;
}

/// Application-owned information about one calendar day.
///
/// Holidays, vacations, and weekends are descriptive; only [isDisabled] blocks
/// selection. Use [semanticLabel] to describe application-specific information
/// to assistive technologies. Collections are copied into immutable snapshots.
@immutable
class CalendarDateAttributes {
  CalendarDateAttributes({
    this.isDisabled = false,
    this.isHoliday = false,
    this.isVacation = false,
    this.tooltip,
    this.semanticLabel,
    this.backgroundColor,
    this.foregroundColor,
    List<CalendarTag> tags = const [],
    Map<String, Object?> metadata = const {},
  })  : tags = List.unmodifiable(tags),
        metadata = Map.unmodifiable(metadata);

  final bool isDisabled;
  final bool isHoliday;
  final bool isVacation;
  final String? tooltip;
  final String? semanticLabel;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final List<CalendarTag> tags;

  /// Extra data for builders, such as event counts, availability, or prices.
  /// Nested values remain application-owned and should themselves be immutable.
  final Map<String, Object?> metadata;
}

/// Resolves recurring rules or date-specific information synchronously.
///
/// Dates have the runtime type supplied by the calendar delegate. Fetch remote
/// information outside this callback, then rebuild when the data changes.
typedef CalendarDateAttributesBuilder = CalendarDateAttributes Function(
    DateTime date);

/// The complete rendering state passed to a custom day builder.
@immutable
class CalendarDayDetails {
  const CalendarDayDetails({
    required this.date,
    required this.attributes,
    required this.isToday,
    required this.isSelected,
    required this.isDisabled,
    required this.isOutsideMonth,
    required this.isWeekend,
    required this.isRangeStart,
    required this.isRangeEnd,
    required this.isInRange,
  });

  final DateTime date;
  final CalendarDateAttributes attributes;
  final bool isToday;
  final bool isSelected;
  final bool isDisabled;
  final bool isOutsideMonth;
  final bool isWeekend;
  final bool isRangeStart;
  final bool isRangeEnd;
  final bool isInRange;
}

/// Return null to use the default day content. Interaction and semantics are
/// supplied by the calendar, including for custom content.
typedef CalendarDayBuilder = Widget? Function(
    BuildContext context, CalendarDayDetails day);
