import 'package:flutter/material.dart';

import 'calendar_attributes.dart';
import 'calendar_design.dart';
import 'calendar_theme.dart';
import 'general_calendar.dart';
import 'general_time_picker.dart';
import 'time_rules.dart';

/// Composes date and time input. Date bounds are inclusive whole days; optional
/// date-time bounds additionally restrict exact results. Results have minute
/// precision and retain the selected date's calendar type.
class GeneralDateTimePicker extends StatefulWidget {
  GeneralDateTimePicker({
    super.key,
    required DateTime firstDate,
    required DateTime lastDate,
    this.initialDateTime,
    this.initialTime,
    DateTime? currentDate,
    this.minimumDateTime,
    this.maximumDateTime,
    this.calendarDelegate = const GregorianCalendarDelegate(),
    this.onDateTimeChanged,
    this.onSelectionChanged,
    this.timeView = GeneralTimePickerView.input,
    this.use24HourFormat,
    this.readOnly = false,
    TimeOfDay minimumTime = const TimeOfDay(hour: 0, minute: 0),
    TimeOfDay maximumTime = const TimeOfDay(hour: 23, minute: 59),
    int minuteInterval = 1,
    this.selectableDateTimePredicate,
    this.selectableDayPredicate,
    this.dateAttributes,
    this.dayBuilder,
    this.firstDayOfWeek,
    this.design = GeneralCalendarDesign.material,
    this.theme,
    this.labels = const GeneralCalendarLabels(),
    this.timeLabels = const GeneralTimePickerLabels(),
    this.dateTimeBuilder = CalendarDateTimeUtils.combine,
  })  : firstDate = calendarDelegate.dateOnly(firstDate),
        lastDate = calendarDelegate.dateOnly(lastDate),
        currentDate =
            calendarDelegate.dateOnly(currentDate ?? calendarDelegate.now()),
        initialDate = initialDateTime == null
            ? null
            : calendarDelegate.dateOnly(initialDateTime),
        timeRules = GeneralTimePickerRules(
            minimumTime: minimumTime,
            maximumTime: maximumTime,
            minuteInterval: minuteInterval) {
    if (initialDateTime != null && initialTime != null) {
      throw ArgumentError('Supply initialDateTime or initialTime, not both.');
    }
    if (initialTime != null) GeneralTimePickerRules.minutesOfDay(initialTime!);
    if (minimumDateTime != null) calendarDelegate.dateOnly(minimumDateTime!);
    if (maximumDateTime != null) calendarDelegate.dateOnly(maximumDateTime!);
    if (minimumDateTime != null &&
        maximumDateTime != null &&
        maximumDateTime!.isBefore(minimumDateTime!)) {
      throw ArgumentError(
          'maximumDateTime must be on or after minimumDateTime.');
    }
    _calendar = GeneralCalendar(
      firstDate: this.firstDate,
      lastDate: this.lastDate,
      initialDate: initialDate,
      currentDate: this.currentDate,
      calendarDelegate: calendarDelegate,
      dateAttributes: dateAttributes,
      selectableDayPredicate: selectableDayPredicate,
      firstDayOfWeek: firstDayOfWeek,
    );
  }

  final DateTime firstDate;
  final DateTime lastDate;
  final DateTime? initialDateTime;
  final DateTime? initialDate;
  final TimeOfDay? initialTime;
  final DateTime currentDate;
  final DateTime? minimumDateTime;
  final DateTime? maximumDateTime;
  final CalendarDelegate<DateTime> calendarDelegate;
  final ValueChanged<DateTime>? onDateTimeChanged;
  final ValueChanged<DateTime?>? onSelectionChanged;
  final GeneralTimePickerView timeView;
  final bool? use24HourFormat;
  final bool readOnly;
  final GeneralTimePickerRules timeRules;
  final SelectableDateTimePredicate? selectableDateTimePredicate;
  final SelectableDayPredicate? selectableDayPredicate;
  final CalendarDateAttributesBuilder? dateAttributes;
  final CalendarDayBuilder? dayBuilder;
  final int? firstDayOfWeek;
  final GeneralCalendarDesign design;
  final GeneralCalendarThemeData? theme;
  final GeneralCalendarLabels labels;
  final GeneralTimePickerLabels timeLabels;
  final CalendarDateTimeBuilder dateTimeBuilder;
  late final GeneralCalendar _calendar;

  bool isDateSelectable(DateTime date) => _calendar.isDateSelectable(date);

  DateTime _combine(DateTime date, TimeOfDay time) {
    final result = dateTimeBuilder(date, time);
    calendarDelegate.dateOnly(result);
    if (result.runtimeType != date.runtimeType ||
        !calendarDelegate.isSameDay(result, date) ||
        result.hour != time.hour ||
        result.minute != time.minute ||
        result.second != 0 ||
        result.millisecond != 0 ||
        result.microsecond != 0 ||
        result.isUtc != date.isUtc) {
      throw StateError(
          'dateTimeBuilder must preserve the calendar date/type and '
          'UTC/local mode, set the requested time, and clear seconds/fractions.');
    }
    return result;
  }

  bool isTimeSelectable(DateTime date, TimeOfDay time) =>
      selectionFor(date, time) != null;

  /// Returns null for unavailable drafts, chronology limits, or nonexistent
  /// local wall times. Programming errors in a custom builder are propagated.
  DateTime? selectionFor(DateTime? date, TimeOfDay? time) {
    if (date == null ||
        time == null ||
        !isDateSelectable(date) ||
        !timeRules.isSelectable(time) ||
        !(selectableDateTimePredicate?.call(date, time) ?? true)) {
      return null;
    }
    try {
      final result = _combine(date, time);
      if (minimumDateTime != null && result.isBefore(minimumDateTime!)) {
        return null;
      }
      if (maximumDateTime != null && result.isAfter(maximumDateTime!)) {
        return null;
      }
      return result;
    } on FormatException {
      return null;
    } on RangeError {
      return null;
    }
  }

  @override
  State<GeneralDateTimePicker> createState() => _GeneralDateTimePickerState();
}

class _GeneralDateTimePickerState extends State<GeneralDateTimePicker> {
  late DateTime? _date = widget.initialDate;
  late TimeOfDay? _time = widget.initialDateTime == null
      ? widget.initialTime
      : TimeOfDay.fromDateTime(widget.initialDateTime!);

  @override
  void didUpdateWidget(GeneralDateTimePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.calendarDelegate != widget.calendarDelegate) {
      _date = widget.initialDate;
      _time = widget.initialDateTime == null
          ? widget.initialTime
          : TimeOfDay.fromDateTime(widget.initialDateTime!);
    } else if (_date != null && !widget.isDateSelectable(_date!)) {
      _date = null;
    }
  }

  void _notify() {
    final result = widget.selectionFor(_date, _time);
    if (result != null) widget.onDateTimeChanged?.call(result);
    widget.onSelectionChanged?.call(result);
  }

  @override
  Widget build(BuildContext context) {
    final calendar = GeneralCalendar(
      firstDate: widget.firstDate,
      lastDate: widget.lastDate,
      initialDate: widget.initialDate,
      currentDate: widget.currentDate,
      calendarDelegate: widget.calendarDelegate,
      design: widget.design,
      theme: widget.theme,
      dateAttributes: widget.dateAttributes,
      selectableDayPredicate: widget.selectableDayPredicate,
      dayBuilder: widget.dayBuilder,
      firstDayOfWeek: widget.firstDayOfWeek,
      labels: widget.labels,
      readOnly: widget.readOnly,
      visibleMonths: 1,
      onDateChanged: (date) {
        setState(() => _date = date);
        _notify();
      },
    );
    final time = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(widget.timeLabels.time,
                style: Theme.of(context).textTheme.titleMedium)),
        if (_date == null)
          Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(widget.timeLabels.selectDateFirst)),
        GeneralTimePicker(
          key: ObjectKey(widget.calendarDelegate),
          initialTime: _time,
          view: widget.timeView,
          use24HourFormat: widget.use24HourFormat,
          minimumTime: widget.timeRules.minimumTime,
          maximumTime: widget.timeRules.maximumTime,
          minuteInterval: widget.timeRules.minuteInterval,
          selectableTimePredicate: (value) =>
              _date != null && widget.isTimeSelectable(_date!, value),
          design: widget.design,
          theme: widget.theme,
          labels: widget.timeLabels,
          readOnly: widget.readOnly,
          onDraftChanged: (value) {
            setState(() => _time = value);
            _notify();
          },
        ),
      ],
    );
    return LayoutBuilder(
        builder: (context, constraints) => constraints.maxWidth >= 760
            ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: calendar),
                const SizedBox(width: 24),
                SizedBox(width: 320, child: time)
              ])
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [calendar, const SizedBox(height: 16), time]));
  }
}
