import 'package:flutter/material.dart';

import 'calendar_attributes.dart';
import 'calendar_design.dart';
import 'calendar_theme.dart';
import 'general_date_time_picker.dart';
import 'general_time_picker.dart';
import 'time_rules.dart';

Future<TimeOfDay?> showGeneralTimePicker({
  required BuildContext context,
  required TimeOfDay initialTime,
  GeneralTimePickerView view = GeneralTimePickerView.input,
  bool? use24HourFormat,
  TimeOfDay minimumTime = const TimeOfDay(hour: 0, minute: 0),
  TimeOfDay maximumTime = const TimeOfDay(hour: 23, minute: 59),
  int minuteInterval = 1,
  SelectableTimePredicate? selectableTimePredicate,
  bool showUnavailableTimes = true,
  GeneralCalendarDesign design = GeneralCalendarDesign.material,
  GeneralCalendarThemeData? theme,
  GeneralTimePickerLabels labels = const GeneralTimePickerLabels(),
  String? helpText,
  String? cancelText,
  String? confirmText,
  Locale? locale,
  TransitionBuilder? builder,
  bool barrierDismissible = true,
  bool useRootNavigator = true,
  RouteSettings? routeSettings,
}) {
  final capturedTheme = GeneralCalendarTheme.of(context).merge(theme);
  final rules = GeneralTimePickerRules(
      minimumTime: minimumTime,
      maximumTime: maximumTime,
      minuteInterval: minuteInterval,
      selectableTimePredicate: selectableTimePredicate);
  GeneralTimePickerRules.minutesOfDay(initialTime);
  return _showDialog<TimeOfDay>(
    context: context,
    width: view == GeneralTimePickerView.slots ? 480 : 400,
    initialValue: rules.isSelectable(initialTime) ? initialTime : null,
    isSelectable: rules.isSelectable,
    title: helpText,
    content: (onChanged) => GeneralTimePicker(
        initialTime: initialTime,
        onSelectionChanged: onChanged,
        view: view,
        use24HourFormat: use24HourFormat,
        minimumTime: minimumTime,
        maximumTime: maximumTime,
        minuteInterval: minuteInterval,
        selectableTimePredicate: selectableTimePredicate,
        showUnavailableTimes: showUnavailableTimes,
        design: design,
        theme: capturedTheme,
        labels: labels),
    cancelText: cancelText,
    confirmText: confirmText,
    locale: locale,
    builder: builder,
    barrierDismissible: barrierDismissible,
    useRootNavigator: useRootNavigator,
    routeSettings: routeSettings,
  );
}

Future<DateTime?> showGeneralDateTimePicker({
  required BuildContext context,
  required DateTime firstDate,
  required DateTime lastDate,
  DateTime? initialDateTime,
  TimeOfDay? initialTime,
  DateTime? currentDate,
  DateTime? minimumDateTime,
  DateTime? maximumDateTime,
  CalendarDelegate<DateTime> calendarDelegate =
      const GregorianCalendarDelegate(),
  GeneralTimePickerView timeView = GeneralTimePickerView.input,
  bool? use24HourFormat,
  TimeOfDay minimumTime = const TimeOfDay(hour: 0, minute: 0),
  TimeOfDay maximumTime = const TimeOfDay(hour: 23, minute: 59),
  int minuteInterval = 1,
  SelectableDateTimePredicate? selectableDateTimePredicate,
  SelectableDayPredicate? selectableDayPredicate,
  CalendarDateAttributesBuilder? dateAttributes,
  CalendarDayBuilder? dayBuilder,
  int? firstDayOfWeek,
  GeneralCalendarDesign design = GeneralCalendarDesign.material,
  GeneralCalendarThemeData? theme,
  GeneralCalendarLabels labels = const GeneralCalendarLabels(),
  GeneralTimePickerLabels timeLabels = const GeneralTimePickerLabels(),
  CalendarDateTimeBuilder dateTimeBuilder = CalendarDateTimeUtils.combine,
  String? helpText,
  String? cancelText,
  String? confirmText,
  Locale? locale,
  TransitionBuilder? builder,
  bool barrierDismissible = true,
  bool useRootNavigator = true,
  RouteSettings? routeSettings,
}) {
  final capturedTheme = GeneralCalendarTheme.of(context).merge(theme);
  GeneralDateTimePicker picker(ValueChanged<DateTime?> onChanged) =>
      GeneralDateTimePicker(
        firstDate: firstDate,
        lastDate: lastDate,
        initialDateTime: initialDateTime,
        initialTime: initialTime,
        currentDate: currentDate,
        calendarDelegate: calendarDelegate,
        minimumDateTime: minimumDateTime,
        maximumDateTime: maximumDateTime,
        timeView: timeView,
        use24HourFormat: use24HourFormat,
        minimumTime: minimumTime,
        maximumTime: maximumTime,
        minuteInterval: minuteInterval,
        selectableDateTimePredicate: selectableDateTimePredicate,
        selectableDayPredicate: selectableDayPredicate,
        dateAttributes: dateAttributes,
        dayBuilder: dayBuilder,
        firstDayOfWeek: firstDayOfWeek,
        design: design,
        theme: capturedTheme,
        labels: labels,
        timeLabels: timeLabels,
        dateTimeBuilder: dateTimeBuilder,
        onSelectionChanged: onChanged,
      );
  final configuration = picker((_) {});
  return _showDialog<DateTime>(
    context: context,
    width: 860,
    initialValue: configuration.selectionFor(
        configuration.initialDate,
        initialDateTime == null
            ? initialTime
            : TimeOfDay.fromDateTime(initialDateTime)),
    title: helpText ?? timeLabels.dateAndTime,
    isSelectable: (value) =>
        configuration.selectionFor(
            calendarDelegate.dateOnly(value), TimeOfDay.fromDateTime(value)) !=
        null,
    content: picker,
    cancelText: cancelText,
    confirmText: confirmText,
    locale: locale,
    builder: builder,
    barrierDismissible: barrierDismissible,
    useRootNavigator: useRootNavigator,
    routeSettings: routeSettings,
  );
}

Future<T?> _showDialog<T>({
  required BuildContext context,
  required double width,
  required T? initialValue,
  required bool Function(T) isSelectable,
  required String? title,
  required Widget Function(ValueChanged<T?>) content,
  required String? cancelText,
  required String? confirmText,
  required Locale? locale,
  required TransitionBuilder? builder,
  required bool barrierDismissible,
  required bool useRootNavigator,
  required RouteSettings? routeSettings,
}) =>
    showDialog<T>(
        context: context,
        barrierDismissible: barrierDismissible,
        useRootNavigator: useRootNavigator,
        routeSettings: routeSettings,
        builder: (context) {
          Widget dialog = _TimeDialog<T>(
              width: width,
              initialValue: initialValue,
              isSelectable: isSelectable,
              title: title,
              content: content,
              cancelText: cancelText,
              confirmText: confirmText);
          if (locale != null) {
            dialog = Localizations.override(
                context: context, locale: locale, child: dialog);
          }
          return builder?.call(context, dialog) ?? dialog;
        });

class _TimeDialog<T> extends StatefulWidget {
  const _TimeDialog(
      {required this.width,
      required this.initialValue,
      required this.isSelectable,
      required this.title,
      required this.content,
      required this.cancelText,
      required this.confirmText});
  final double width;
  final T? initialValue;
  final bool Function(T) isSelectable;
  final String? title;
  final Widget Function(ValueChanged<T?>) content;
  final String? cancelText;
  final String? confirmText;

  @override
  State<_TimeDialog<T>> createState() => _TimeDialogState<T>();
}

class _TimeDialogState<T> extends State<_TimeDialog<T>> {
  late T? _value = widget.initialValue;

  @override
  Widget build(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);
    return AlertDialog(
      title: Text(widget.title ?? localizations.timePickerDialHelpText),
      contentPadding: const EdgeInsets.all(12),
      content: SizedBox(
          width: widget.width,
          child: SingleChildScrollView(
              child:
                  widget.content((value) => setState(() => _value = value)))),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(widget.cancelText ?? localizations.cancelButtonLabel)),
        TextButton(
            key: const ValueKey('general-time-confirm'),
            onPressed: _value == null || !widget.isSelectable(_value as T)
                ? null
                : () {
                    final value = _value as T;
                    if (widget.isSelectable(value)) {
                      Navigator.of(context).pop<T>(value);
                    } else {
                      setState(() => _value = null);
                    }
                  },
            child: Text(widget.confirmText ?? localizations.okButtonLabel)),
      ],
    );
  }
}
