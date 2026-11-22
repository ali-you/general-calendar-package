import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:general_calendar/general_calendar.dart';
import 'package:general_datetime/delegates.dart';
import 'package:general_datetime/general_datetime.dart';

void main() {
  testWidgets('selects a civil day in the leap month with repeated tithi',
      (tester) async {
    const delegate = AmantaCalendarDelegate();
    final leap = AmantaDate.fromLunarMonth(2080, 5, isLeapMonth: true);
    final initial = AmantaDateTime.fromCivilDate(leap.addMonths(-1));
    DateTime? selected;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: GeneralCalendar(
          calendarDelegate: delegate,
          firstDate: delegate.getMonth(2080, 1),
          lastDate: delegate.getMonth(2081, 1),
          currentDate: initial,
          initialDate: initial,
          onDateChanged: (value) => selected = value,
        ),
      ),
    ));

    await tester.tap(find.byKey(const ValueKey('general-calendar-next')));
    await tester.pumpAndSettle();
    expect(find.text('Adhika Shravana 2080'), findsOneWidget);
    await tester
        .tap(find.byKey(ValueKey('general-calendar-day-2080-${leap.month}-5')));
    expect((selected as AmantaDateTime).civilDate, leap.addDays(4));
    expect((selected as AmantaDateTime).civilDate.isRepeatedTithi, isTrue);
    final combined = CalendarDateTimeUtils.combine(
        selected!, const TimeOfDay(hour: 8, minute: 15));
    expect((combined as AmantaDateTime).civilDate, leap.addDays(4));
    expect(combined.hour, 8);
    expect(combined.minute, 15);
    expect(tester.takeException(), isNull);
  });

  testWidgets('range selection crosses the boundary into the regular month',
      (tester) async {
    const delegate = AmantaCalendarDelegate();
    final leap = AmantaDate.fromLunarMonth(2080, 5, isLeapMonth: true);
    final regular = leap.addMonths(1);
    final start = leap.addDays(leap.monthLength - 1);
    CalendarSelection? selection;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: GeneralCalendar(
          calendarDelegate: delegate,
          selectionMode: CalendarSelectionMode.range,
          firstDate: delegate.getMonth(2080, 1),
          lastDate: delegate.getMonth(2081, 1),
          currentDate: AmantaDateTime.fromCivilDate(leap),
          onSelectionChanged: (value) => selection = value,
        ),
      ),
    ));

    await tester.tap(find.byKey(
        ValueKey('general-calendar-day-2080-${start.month}-${start.day}')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('general-calendar-next')));
    await tester.pumpAndSettle();
    await tester.tap(
        find.byKey(ValueKey('general-calendar-day-2080-${regular.month}-1')));
    await tester.pumpAndSettle();
    expect((selection!.rangeStart as AmantaDateTime).civilDate, start);
    expect((selection!.rangeEnd as AmantaDateTime).civilDate, regular);
    expect(tester.takeException(), isNull);
  });
}
