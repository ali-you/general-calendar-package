import 'package:flutter/material.dart';

/// Optional overrides; unspecified values follow the ambient Material theme.
@immutable
class GeneralCalendarThemeData {
  const GeneralCalendarThemeData({
    this.selectedDayColor,
    this.selectedDayForegroundColor,
    this.todayColor,
    this.holidayColor,
    this.vacationColor,
    this.weekendColor,
    this.rangeColor,
    this.dayTextStyle,
    this.weekdayTextStyle,
    this.dayHeight = 48,
  }) : assert(dayHeight >= 48);

  final Color? selectedDayColor;
  final Color? selectedDayForegroundColor;
  final Color? todayColor;
  final Color? holidayColor;
  final Color? vacationColor;
  final Color? weekendColor;
  final Color? rangeColor;
  final TextStyle? dayTextStyle;
  final TextStyle? weekdayTextStyle;
  final double dayHeight;
}

class GeneralCalendarTheme extends InheritedWidget {
  const GeneralCalendarTheme({
    super.key,
    required this.data,
    required super.child,
  });

  final GeneralCalendarThemeData data;

  static GeneralCalendarThemeData of(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<GeneralCalendarTheme>()
          ?.data ??
      const GeneralCalendarThemeData();

  @override
  bool updateShouldNotify(GeneralCalendarTheme oldWidget) =>
      data != oldWidget.data;
}
