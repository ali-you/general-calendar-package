import 'package:flutter/material.dart';

enum GeneralTimePickerView { input, dial, wheels, dropdown, slots }

typedef SelectableTimePredicate = bool Function(TimeOfDay time);
typedef SelectableDateTimePredicate = bool Function(
    DateTime date, TimeOfDay time);

/// Shared validation for every time input view. Bounds are inclusive and apply
/// within one day; use a predicate for overnight schedules.
@immutable
class GeneralTimePickerRules {
  GeneralTimePickerRules({
    this.minimumTime = const TimeOfDay(hour: 0, minute: 0),
    this.maximumTime = const TimeOfDay(hour: 23, minute: 59),
    this.minuteInterval = 1,
    this.selectableTimePredicate,
  }) {
    minutesOfDay(minimumTime);
    minutesOfDay(maximumTime);
    if (minuteInterval < 1 || minuteInterval > 60 || 60 % minuteInterval != 0) {
      throw ArgumentError.value(
          minuteInterval, 'minuteInterval', 'Must divide 60.');
    }
    if (minutesOfDay(minimumTime) > minutesOfDay(maximumTime)) {
      throw ArgumentError('maximumTime must be on or after minimumTime.');
    }
  }

  final TimeOfDay minimumTime;
  final TimeOfDay maximumTime;
  final int minuteInterval;
  final SelectableTimePredicate? selectableTimePredicate;

  static int minutesOfDay(TimeOfDay time) {
    if (time.hour < 0 ||
        time.hour > 23 ||
        time.minute < 0 ||
        time.minute > 59) {
      throw ArgumentError.value(time, 'time', 'Invalid hour or minute.');
    }
    return time.hour * 60 + time.minute;
  }

  bool isSelectable(TimeOfDay time) {
    final value = minutesOfDay(time);
    return value >= minutesOfDay(minimumTime) &&
        value <= minutesOfDay(maximumTime) &&
        time.minute % minuteInterval == 0 &&
        (selectableTimePredicate?.call(time) ?? true);
  }

  /// Includes unavailable entries so lists/slots can explain their disabled
  /// state. Numeric bounds and minute increments are always respected.
  List<TimeOfDay> get times => List.unmodifiable([
        for (var value = 0; value < 1440; value += minuteInterval)
          if (value >= minutesOfDay(minimumTime) &&
              value <= minutesOfDay(maximumTime))
            TimeOfDay(hour: value ~/ 60, minute: value % 60),
      ]);
}

/// Optional translations for labels not covered by MaterialLocalizations.
@immutable
class GeneralTimePickerLabels {
  const GeneralTimePickerLabels({
    this.unavailableTime = 'This time is unavailable',
    this.noAvailableTimes = 'No available times',
    this.time = 'Time',
    this.dateAndTime = 'Select date and time',
    this.selectDateFirst = 'Select a date to check available times',
  });

  final String unavailableTime;
  final String noAvailableTimes;
  final String time;
  final String dateAndTime;
  final String selectDateFirst;
}

/// Combine calendar date fields and a wall-clock time. Custom implementations
/// can support calendar subclasses whose add() method returns native DateTime.
typedef CalendarDateTimeBuilder = DateTime Function(
    DateTime date, TimeOfDay time);

abstract final class CalendarDateTimeUtils {
  /// Preserves the date's calendar type and UTC/local mode, clearing seconds
  /// and fractions. Native Gregorian fields are obtained from the epoch, never
  /// from a custom calendar's exposed year/month/day.
  ///
  /// Local DST gaps throw FormatException instead of silently changing the
  /// requested time. Folds use Dart's native constructor policy. Named zones
  /// and ambiguous-time resolution remain application responsibilities.
  static DateTime combine(DateTime date, TimeOfDay time) {
    GeneralTimePickerRules.minutesOfDay(time);
    // Split epoch parts avoid rounding a late-day value into tomorrow when
    // large microsecond timestamps exceed JavaScript's exact integer range.
    final native = DateTime.fromMillisecondsSinceEpoch(
            date.millisecondsSinceEpoch,
            isUtc: date.isUtc)
        .add(Duration(microseconds: date.microsecond));
    final wall = date.isUtc
        ? DateTime.utc(
            native.year, native.month, native.day, time.hour, time.minute)
        : DateTime(
            native.year, native.month, native.day, time.hour, time.minute);
    if (wall.year != native.year ||
        wall.month != native.month ||
        wall.day != native.day ||
        wall.hour != time.hour ||
        wall.minute != time.minute) {
      throw const FormatException('The requested local time does not exist.');
    }
    final result = date.add(wall.difference(native));
    if (result.runtimeType != date.runtimeType) {
      throw UnsupportedError('The calendar must preserve its type in add(). '
          'Supply a calendar-specific dateTimeBuilder.');
    }
    return result;
  }
}
