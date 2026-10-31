import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:general_calendar/general_calendar.dart';
import 'package:general_datetime/default_localizations.dart';
import 'package:general_datetime/delegates.dart';
import 'package:general_datetime/general_datetime.dart';

Widget host(Widget child) => MaterialApp(
      localizationsDelegates: const [
        DefaultChineseCalendarMaterialLocalizations.delegate
      ],
      home: Scaffold(body: child),
    );

void main() {
  testWidgets('year overview includes the repeated month only in leap years',
      (tester) async {
    for (final year in [2025, 2024]) {
      final lastMonth = ChineseDateTime.monthsInYear(year);
      await tester.pumpWidget(host(GeneralCalendar(
        key: ValueKey(year),
        calendarDelegate: const ChineseCalendarDelegate(),
        firstDate: ChineseDateTime(year),
        lastDate: ChineseDateTime(
            year, lastMonth, ChineseDateTime.daysInMonth(year, lastMonth)),
        currentDate: ChineseDateTime(year),
        initialView: GeneralCalendarView.year,
      )));
      expect(find.byType(TextButton), findsNWidgets(lastMonth));
      expect(find.text('Leap Month 6 2025'),
          year == 2025 ? findsOneWidget : findsNothing);
      expect(tester.takeException(), isNull);
    }
  });
  testWidgets('month navigation and selection retain the leap month type',
      (tester) async {
    DateTime? selected;
    await tester.pumpWidget(host(GeneralCalendar(
      calendarDelegate: const ChineseCalendarDelegate(),
      firstDate: ChineseDateTime(2025),
      lastDate: ChineseDateTime(2025, 13, 29),
      initialDate: ChineseDateTime(2025, 6),
      currentDate: ChineseDateTime(2025, 6),
      onDateChanged: (date) => selected = date,
    )));
    await tester.tap(find.byKey(const ValueKey('general-calendar-next')));
    await tester.pumpAndSettle();
    expect(find.text('Leap Month 6 2025'), findsOneWidget);
    await tester
        .tap(find.byKey(const ValueKey('general-calendar-day-2025-7-10')));
    expect(selected, isA<ChineseDateTime>());
    expect((selected as ChineseDateTime).monthCode, 'M06L');
    expect(tester.takeException(), isNull);
  });
  testWidgets('finite endpoint grids clip unsupported adjacent days',
      (tester) async {
    for (final date in [ChineseDateTime(1901), ChineseDateTime(2099, 13, 30)]) {
      await tester.pumpWidget(host(GeneralCalendar(
        key: ValueKey(date),
        calendarDelegate: const ChineseCalendarDelegate(),
        firstDate: ChineseDateTime(1901),
        lastDate: ChineseDateTime(2099, 13, 30),
        initialDate: date,
        currentDate: date,
        showAdjacentMonthDays: true,
      )));
      expect(tester.takeException(), isNull);
    }
  });
}
