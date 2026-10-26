import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:general_calendar/general_calendar.dart';
import 'package:general_calendar_example/main.dart';
import 'package:general_datetime/delegates.dart';

void main() {
  testWidgets(
      'switches all four calendar delegates with matching localizations',
      (tester) async {
    await tester.pumpWidget(CalendarExample(now: () => DateTime(2024, 3, 20)));
    final delegates = <String, Type>{
      'persian': PersianCalendarDelegate,
      'hijri': HijriCalendarDelegate,
      'hebrew': HebrewCalendarDelegate,
      'gregorian': GregorianCalendarDelegate,
    };
    for (final entry in delegates.entries) {
      await tester.tap(find.byKey(const ValueKey('calendar-system')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(entry.key).last);
      await tester.pumpAndSettle();
      expect(
          tester
              .widget<GeneralCalendar>(find.byType(GeneralCalendar))
              .calendarDelegate
              .runtimeType,
          entry.value);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('selection survives parent rebuilds after month navigation',
      (tester) async {
    await tester.pumpWidget(CalendarExample(now: () => DateTime(2024, 3, 20)));
    await tester.tap(find.byKey(const ValueKey('general-calendar-next')));
    await tester.pump();
    await tester.ensureVisible(
        find.byKey(const ValueKey('general-calendar-day-2024-4-1')));
    await tester
        .tap(find.byKey(const ValueKey('general-calendar-day-2024-4-1')));
    await tester.pump();
    expect(find.text('April 2024'), findsOneWidget);
    expect(find.text('2024/4/1'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a phone-size example switches to range selection',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(CalendarExample(now: () => DateTime(2024, 3, 20)));
    await tester.tap(find.byKey(const ValueKey('calendar-selection-mode')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('range').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(
        find.byKey(const ValueKey('general-calendar-day-2024-3-18')));
    await tester.pumpAndSettle();
    await tester
        .tap(find.byKey(const ValueKey('general-calendar-day-2024-3-18')));
    await tester.pump();
    await tester.ensureVisible(
        find.byKey(const ValueKey('general-calendar-day-2024-3-20')));
    await tester.pumpAndSettle();
    await tester
        .tap(find.byKey(const ValueKey('general-calendar-day-2024-3-20')));
    await tester.pump();
    expect(find.text('2024/3/18 — 2024/3/20'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('styles change in place and dark mode follows the switch',
      (tester) async {
    await tester.pumpWidget(CalendarExample(now: () => DateTime(2024, 3, 20)));
    final state = tester.state(find.byType(GeneralCalendar));
    await tester.tap(find.byKey(const ValueKey('calendar-design')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Carbon').last);
    await tester.tap(find.text('Carbon').last);
    await tester.pumpAndSettle();
    expect(tester.widget<GeneralCalendar>(find.byType(GeneralCalendar)).design,
        GeneralCalendarDesign.carbon);
    expect(tester.state(find.byType(GeneralCalendar)), same(state));
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
        ThemeMode.dark);
    expect(tester.takeException(), isNull);
  });

  testWidgets('comparison gallery displays all twelve designs', (tester) async {
    await tester.pumpWidget(CalendarExample(now: () => DateTime(2024, 3, 20)));
    await tester.tap(find.text('Compare styles'));
    await tester.pumpAndSettle();
    expect(find.text('12 calendar styles'), findsOneWidget);
    expect(find.byType(GeneralCalendar), findsNWidgets(12));
    expect(tester.takeException(), isNull);
  });

  testWidgets('inline time picker updates the example selection',
      (tester) async {
    await tester.pumpWidget(CalendarExample(now: () => DateTime(2024, 3, 20)));
    final hour = find.byKey(const ValueKey('general-time-hour'));
    await tester.scrollUntilVisible(hour, 300,
        scrollable: find.byType(Scrollable).first);
    await tester.enterText(hour, '16');
    await tester.pump();
    expect(find.text('16:30'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('example opens and confirms a combined date-time dialog',
      (tester) async {
    await tester.pumpWidget(CalendarExample(now: () => DateTime(2024, 3, 20)));
    await tester.scrollUntilVisible(find.text('Open date & time picker'), 300,
        scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open date & time picker'));
    await tester.pumpAndSettle();
    final date = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byKey(const ValueKey('general-calendar-day-2024-3-21')));
    await tester.ensureVisible(date);
    await tester.tap(date);
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('general-time-confirm')));
    await tester.pumpAndSettle();
    expect(find.text('2024/3/21 14:30'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
