import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:general_calendar/general_calendar.dart';
import 'package:general_datetime/default_localizations.dart';
import 'package:general_datetime/delegates.dart';
import 'package:general_datetime/general_datetime.dart';

Finder day(int month, int value) =>
    find.byKey(ValueKey('general-calendar-day-2025-$month-$value'));
Widget host(Widget child, {bool rtl = false}) => MaterialApp(
      localizationsDelegates: const [
        DefaultChineseCalendarMaterialLocalizations.delegate
      ],
      home: Scaffold(
          body: Directionality(
              textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
              child: child)),
    );

void main() {
  test(
      'combining wall times preserves Chinese identity, fractions policy, mode, and endpoints',
      () {
    for (final date in [
      ChineseDateTime.utc(2025, 7, 29, 23, 59, 59, 999, 999),
      ChineseDateTime(2025, 7, 1, 14, 33, 59, 123, 987),
      ChineseDateTime.utc(1901),
      ChineseDateTime.utc(2099, 13, 30),
      ChineseDateTime.fromDateTime(
          DateTime.fromMicrosecondsSinceEpoch(-1, isUtc: true))
    ]) {
      for (final time in [
        const TimeOfDay(hour: 0, minute: 0),
        const TimeOfDay(hour: 12, minute: 34),
        const TimeOfDay(hour: 23, minute: 59)
      ]) {
        final result = CalendarDateTimeUtils.combine(date, time);
        final native = date.toDateTime();
        final expected = date.isUtc
            ? DateTime.utc(
                native.year, native.month, native.day, time.hour, time.minute)
            : DateTime(
                native.year, native.month, native.day, time.hour, time.minute);
        expect(result, isA<ChineseDateTime>());
        expect(result, expected);
        expect((result as ChineseDateTime).monthCode, date.monthCode);
        expect(result.isUtc, date.isUtc);
        expect(
            [result.second, result.millisecond, result.microsecond], [0, 0, 0]);
      }
    }
  });

  for (final rtl in [false, true]) {
    testWidgets('two-month booking range preserves the repeated month RTL=$rtl',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      DateTimeRange? selected;
      await tester.pumpWidget(host(
          SizedBox(
              width: 900,
              child: GeneralCalendar(
                design: GeneralCalendarDesign.booking,
                visibleMonths: 2,
                calendarDelegate: const ChineseCalendarDelegate(),
                firstDate: ChineseDateTime(2025, 6),
                lastDate: ChineseDateTime(2025, 8, 29),
                currentDate: ChineseDateTime(2025, 6),
                selectionMode: CalendarSelectionMode.range,
                onDateRangeChanged: (value) => selected = value,
              )),
          rtl: rtl));
      expect(day(6, 30), findsOneWidget);
      expect(day(7, 1), findsOneWidget);
      await tester.tap(day(6, 30));
      await tester.pump();
      await tester.tap(day(7, 2));
      await tester.pump();
      expect(selected?.start, ChineseDateTime(2025, 6, 30));
      expect(selected?.end, ChineseDateTime(2025, 7, 2));
      expect((selected!.end as ChineseDateTime).isLeapMonth, isTrue);
      await tester.tap(find.byKey(const ValueKey('general-calendar-next')));
      await tester.pumpAndSettle();
      expect(day(7, 1), findsOneWidget);
      expect(day(8, 1), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
      'disabled interior of a leap-month range follows the requested selection policy',
      (tester) async {
    for (final allowDisabled in [false, true]) {
      DateTimeRange? selected;
      await tester.pumpWidget(host(GeneralCalendar(
        key: ValueKey(allowDisabled),
        calendarDelegate: const ChineseCalendarDelegate(),
        firstDate: ChineseDateTime(2025, 7),
        lastDate: ChineseDateTime(2025, 7, 29),
        currentDate: ChineseDateTime(2025, 7),
        selectionMode: CalendarSelectionMode.range,
        selectableDayPredicate: (date) => date.day != 2,
        allowDisabledDatesInRange: allowDisabled,
        onDateRangeChanged: (value) => selected = value,
      )));
      await tester.tap(day(7, 1));
      await tester.pump();
      await tester.tap(day(7, 3));
      await tester.pump();
      if (allowDisabled) {
        expect(
            selected,
            DateTimeRange<DateTime>(
                start: ChineseDateTime(2025, 7),
                end: ChineseDateTime(2025, 7, 3)));
      } else {
        expect(selected, isNull);
      }
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets(
      'keyboard activation returns a leap-month date with matching semantics',
      (tester) async {
    DateTime? selected;
    await tester.pumpWidget(host(GeneralCalendar(
      calendarDelegate: const ChineseCalendarDelegate(),
      firstDate: ChineseDateTime(2025, 7),
      lastDate: ChineseDateTime(2025, 7, 29),
      currentDate: ChineseDateTime(2025, 7),
      onDateChanged: (date) => selected = date,
    )));
    final target = find
        .descendant(of: day(7, 10), matching: find.byType(GestureDetector))
        .first;
    Focus.of(tester.element(target)).requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(selected, ChineseDateTime(2025, 7, 10));
    final semantics = tester.widget<Semantics>(day(7, 10));
    expect(semantics.properties.label, contains('Leap Month 6'));
    expect(tester.takeException(), isNull);
  });
}
