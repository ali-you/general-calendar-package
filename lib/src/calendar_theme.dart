import 'package:flutter/material.dart';

enum CalendarHeaderLayout { leading, centered, split, stacked }

enum CalendarTodayIndicator { outline, dot, underline, fill }

enum CalendarNavigationStyle { plain, outlined, filled }

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
    double? dayHeight,
    this.surfaceColor,
    this.foregroundColor,
    this.mutedForegroundColor,
    this.borderColor,
    this.hoverColor,
    this.focusColor,
    this.surfaceRadius,
    this.dayRadius,
    this.dayInset,
    this.contentPadding,
    this.headerTextStyle,
    this.headerBackgroundColor,
    this.headerLayout,
    this.todayIndicator,
    this.navigationStyle,
    this.showBorder,
    this.showHeaderDivider,
    this.showGridLines,
    this.showEventLabels,
    this.weekendBackgroundColor,
    this.elevation,
  })  : _dayHeight = dayHeight,
        assert(dayHeight == null || dayHeight >= 48),
        assert(surfaceRadius == null || surfaceRadius >= 0),
        assert(dayRadius == null || dayRadius >= 0),
        assert(dayInset == null || dayInset >= 0),
        assert(elevation == null || elevation >= 0);

  final Color? selectedDayColor;
  final Color? selectedDayForegroundColor;
  final Color? todayColor;
  final Color? holidayColor;
  final Color? vacationColor;
  final Color? weekendColor;
  final Color? rangeColor;
  final TextStyle? dayTextStyle;
  final TextStyle? weekdayTextStyle;
  final double? _dayHeight;
  double get dayHeight => _dayHeight ?? 48;
  final Color? surfaceColor;
  final Color? foregroundColor;
  final Color? mutedForegroundColor;
  final Color? borderColor;
  final Color? hoverColor;
  final Color? focusColor;
  final double? surfaceRadius;
  final double? dayRadius;
  final double? dayInset;
  final EdgeInsetsGeometry? contentPadding;
  final TextStyle? headerTextStyle;
  final Color? headerBackgroundColor;
  final CalendarHeaderLayout? headerLayout;
  final CalendarTodayIndicator? todayIndicator;
  final CalendarNavigationStyle? navigationStyle;
  final bool? showBorder;
  final bool? showHeaderDivider;
  final bool? showGridLines;

  /// Show date tags as event labels rather than dots. Custom day builders still
  /// take priority. Prefer a dayHeight of at least 104 for this layout.
  final bool? showEventLabels;
  final Color? weekendBackgroundColor;
  final double? elevation;

  /// Layers explicit overrides on top of a preset, preserving unspecified values.
  GeneralCalendarThemeData merge(GeneralCalendarThemeData? other) {
    if (other == null) return this;
    return GeneralCalendarThemeData(
      selectedDayColor: other.selectedDayColor ?? selectedDayColor,
      selectedDayForegroundColor:
          other.selectedDayForegroundColor ?? selectedDayForegroundColor,
      todayColor: other.todayColor ?? todayColor,
      holidayColor: other.holidayColor ?? holidayColor,
      vacationColor: other.vacationColor ?? vacationColor,
      weekendColor: other.weekendColor ?? weekendColor,
      rangeColor: other.rangeColor ?? rangeColor,
      dayTextStyle: other.dayTextStyle ?? dayTextStyle,
      weekdayTextStyle: other.weekdayTextStyle ?? weekdayTextStyle,
      dayHeight: other._dayHeight ?? _dayHeight,
      surfaceColor: other.surfaceColor ?? surfaceColor,
      foregroundColor: other.foregroundColor ?? foregroundColor,
      mutedForegroundColor: other.mutedForegroundColor ?? mutedForegroundColor,
      borderColor: other.borderColor ?? borderColor,
      hoverColor: other.hoverColor ?? hoverColor,
      focusColor: other.focusColor ?? focusColor,
      surfaceRadius: other.surfaceRadius ?? surfaceRadius,
      dayRadius: other.dayRadius ?? dayRadius,
      dayInset: other.dayInset ?? dayInset,
      contentPadding: other.contentPadding ?? contentPadding,
      headerTextStyle: other.headerTextStyle ?? headerTextStyle,
      headerBackgroundColor:
          other.headerBackgroundColor ?? headerBackgroundColor,
      headerLayout: other.headerLayout ?? headerLayout,
      todayIndicator: other.todayIndicator ?? todayIndicator,
      navigationStyle: other.navigationStyle ?? navigationStyle,
      showBorder: other.showBorder ?? showBorder,
      showHeaderDivider: other.showHeaderDivider ?? showHeaderDivider,
      showGridLines: other.showGridLines ?? showGridLines,
      showEventLabels: other.showEventLabels ?? showEventLabels,
      weekendBackgroundColor:
          other.weekendBackgroundColor ?? weekendBackgroundColor,
      elevation: other.elevation ?? elevation,
    );
  }
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
