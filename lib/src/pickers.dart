import 'package:flutter/material.dart';

import 'calendar_attributes.dart';
import 'calendar_design.dart';
import 'calendar_selection.dart';
import 'calendar_theme.dart';
import 'general_calendar.dart';

/// Shows a calendar dialog with the same delegate and date rules as the inline
/// calendar. Cancel and barrier dismissal return null. Unlike Flutter's
/// showDatePicker, this dialog currently provides calendar input only.
Future<DateTime?> showGeneralDatePicker({
  required BuildContext context,
  required DateTime firstDate,
  required DateTime lastDate,
  DateTime? initialDate,
  DateTime? currentDate,
  CalendarDelegate<DateTime> calendarDelegate =
      const GregorianCalendarDelegate(),
  SelectableDayPredicate? selectableDayPredicate,
  CalendarDateAttributesBuilder? dateAttributes,
  CalendarDayBuilder? dayBuilder,
  GeneralCalendarThemeData? theme,
  GeneralCalendarDesign design = GeneralCalendarDesign.material,
  int? visibleMonths,
  GeneralCalendarLabels labels = const GeneralCalendarLabels(),
  GeneralCalendarView initialView = GeneralCalendarView.month,
  int? firstDayOfWeek,
  Set<int> weekendDays = const {DateTime.saturday, DateTime.sunday},
  String? helpText,
  String? cancelText,
  String? confirmText,
  Locale? locale,
  TransitionBuilder? builder,
  bool barrierDismissible = true,
  bool useRootNavigator = true,
  RouteSettings? routeSettings,
}) {
  theme = GeneralCalendarTheme.of(context).merge(theme);
  GeneralCalendar calendar(ValueChanged<CalendarSelection> onChanged,
          {DateTime? seed}) =>
      GeneralCalendar(
        firstDate: firstDate,
        lastDate: lastDate,
        initialDate: seed,
        currentDate: currentDate,
        calendarDelegate: calendarDelegate,
        selectableDayPredicate: selectableDayPredicate,
        dateAttributes: dateAttributes,
        dayBuilder: dayBuilder,
        theme: theme,
        design: design,
        visibleMonths: visibleMonths,
        labels: labels,
        initialView: initialView,
        firstDayOfWeek: firstDayOfWeek,
        weekendDays: weekendDays,
        onSelectionChanged: onChanged,
      );
  // Validate before pushing a route, as Flutter's Material pickers do.
  final configuration = calendar((_) {}, seed: initialDate);
  return _showPicker<DateTime>(
    context: context,
    initialValue: configuration.initialDate,
    width: (visibleMonths ?? design.preferredVisibleMonths) == 2 ? 800 : 360,
    calendar: (onChanged) => calendar(onChanged,
        seed: configuration.initialDate != null &&
                configuration.isDateSelectable(configuration.initialDate!)
            ? configuration.initialDate
            : null),
    isSelectable: configuration.isDateSelectable,
    valueOf: (selection) => selection.date,
    helpText: helpText,
    cancelText: cancelText,
    confirmText: confirmText,
    locale: locale,
    builder: builder,
    barrierDismissible: barrierDismissible,
    useRootNavigator: useRootNavigator,
    routeSettings: routeSettings,
  );
}

/// Shows an inclusive range picker. By default a range cannot cross disabled
/// dates. A second tap before the first endpoint sorts the endpoints.
Future<DateTimeRange<DateTime>?> showGeneralDateRangePicker({
  required BuildContext context,
  required DateTime firstDate,
  required DateTime lastDate,
  DateTimeRange<DateTime>? initialDateRange,
  DateTime? currentDate,
  CalendarDelegate<DateTime> calendarDelegate =
      const GregorianCalendarDelegate(),
  SelectableDayPredicate? selectableDayPredicate,
  CalendarDateAttributesBuilder? dateAttributes,
  CalendarDayBuilder? dayBuilder,
  GeneralCalendarThemeData? theme,
  GeneralCalendarDesign design = GeneralCalendarDesign.material,
  int? visibleMonths,
  GeneralCalendarLabels labels = const GeneralCalendarLabels(),
  GeneralCalendarView initialView = GeneralCalendarView.month,
  int? firstDayOfWeek,
  Set<int> weekendDays = const {DateTime.saturday, DateTime.sunday},
  bool allowDisabledDatesInRange = false,
  String? helpText,
  String? cancelText,
  String? confirmText,
  Locale? locale,
  TransitionBuilder? builder,
  bool barrierDismissible = true,
  bool useRootNavigator = true,
  RouteSettings? routeSettings,
}) {
  theme = GeneralCalendarTheme.of(context).merge(theme);
  GeneralCalendar calendar(ValueChanged<CalendarSelection> onChanged,
          {DateTimeRange<DateTime>? seed}) =>
      GeneralCalendar(
        firstDate: firstDate,
        lastDate: lastDate,
        initialDateRange: seed,
        currentDate: currentDate,
        calendarDelegate: calendarDelegate,
        selectionMode: CalendarSelectionMode.range,
        selectableDayPredicate: selectableDayPredicate,
        dateAttributes: dateAttributes,
        dayBuilder: dayBuilder,
        theme: theme,
        design: design,
        visibleMonths: visibleMonths,
        labels: labels,
        initialView: initialView,
        firstDayOfWeek: firstDayOfWeek,
        weekendDays: weekendDays,
        allowDisabledDatesInRange: allowDisabledDatesInRange,
        onSelectionChanged: onChanged,
      );
  final configuration = calendar((_) {}, seed: initialDateRange);
  return _showPicker<DateTimeRange<DateTime>>(
    context: context,
    initialValue: configuration.initialDateRange,
    width: (visibleMonths ?? design.preferredVisibleMonths) == 2 ? 800 : 360,
    calendar: (onChanged) => calendar(onChanged,
        seed: configuration.initialDateRange != null &&
                configuration.isRangeSelectable(configuration.initialDateRange!)
            ? configuration.initialDateRange
            : null),
    isSelectable: configuration.isRangeSelectable,
    valueOf: (selection) => selection.range,
    helpText: helpText,
    cancelText: cancelText,
    confirmText: confirmText,
    locale: locale,
    builder: builder,
    barrierDismissible: barrierDismissible,
    useRootNavigator: useRootNavigator,
    routeSettings: routeSettings,
  );
}

Future<T?> _showPicker<T>({
  required BuildContext context,
  required T? initialValue,
  required bool Function(T) isSelectable,
  required double width,
  required GeneralCalendar Function(ValueChanged<CalendarSelection>) calendar,
  required T? Function(CalendarSelection) valueOf,
  required String? helpText,
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
      builder: (dialogContext) {
        Widget dialog = _CalendarPickerDialog<T>(
          initialValue: initialValue,
          isSelectable: isSelectable,
          width: width,
          calendar: calendar,
          valueOf: valueOf,
          helpText: helpText,
          cancelText: cancelText,
          confirmText: confirmText,
        );
        if (locale != null) {
          dialog = Localizations.override(
            context: dialogContext,
            locale: locale,
            child: dialog,
          );
        }
        return builder?.call(dialogContext, dialog) ?? dialog;
      },
    );

class _CalendarPickerDialog<T> extends StatefulWidget {
  const _CalendarPickerDialog({
    required this.initialValue,
    required this.isSelectable,
    required this.width,
    required this.calendar,
    required this.valueOf,
    required this.helpText,
    required this.cancelText,
    required this.confirmText,
  });

  final T? initialValue;
  final bool Function(T) isSelectable;
  final double width;
  final GeneralCalendar Function(ValueChanged<CalendarSelection>) calendar;
  final T? Function(CalendarSelection) valueOf;
  final String? helpText;
  final String? cancelText;
  final String? confirmText;

  @override
  State<_CalendarPickerDialog<T>> createState() =>
      _CalendarPickerDialogState<T>();
}

class _CalendarPickerDialogState<T> extends State<_CalendarPickerDialog<T>> {
  late T? _value = widget.initialValue;

  @override
  Widget build(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);
    return AlertDialog(
      title: Text(widget.helpText ?? localizations.datePickerHelpText),
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      content: SizedBox(
        width: widget.width,
        child: SingleChildScrollView(
          child: widget.calendar((selection) {
            setState(() => _value = widget.valueOf(selection));
          }),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(widget.cancelText ?? localizations.cancelButtonLabel),
        ),
        TextButton(
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
          child: Text(widget.confirmText ?? localizations.okButtonLabel),
        ),
      ],
    );
  }
}
