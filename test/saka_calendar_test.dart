import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:general_calendar/general_calendar.dart';
import 'package:general_datetime/default_localizations.dart';
import 'package:general_datetime/delegates.dart';
import 'package:general_datetime/general_datetime.dart';

void main() {
  testWidgets('selects a range from Phalguna into Chaitra', (tester) async {
    const delegate = SakaCalendarDelegate();
    CalendarSelection? selection;
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: const [
        DefaultSakaCalendarMaterialLocalizations.delegate,
      ],
      home: Scaffold(
        body: GeneralCalendar(
          calendarDelegate: delegate,
          selectionMode: CalendarSelectionMode.range,
          firstDate: SakaDateTime(1947, 12),
          lastDate: SakaDateTime(1948, 2, 31),
          currentDate: SakaDateTime(1947, 12, 30),
          onSelectionChanged: (value) => selection = value,
        ),
      ),
    ));

    expect(find.text('Phalguna 1947'), findsOneWidget);
    await tester
        .tap(find.byKey(const ValueKey('general-calendar-day-1947-12-30')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('general-calendar-next')));
    await tester.pumpAndSettle();
    expect(find.text('Chaitra 1948'), findsOneWidget);
    await tester
        .tap(find.byKey(const ValueKey('general-calendar-day-1948-1-1')));
    await tester.pumpAndSettle();
    expect(selection?.rangeStart, SakaDateTime(1947, 12, 30));
    expect(selection?.rangeEnd, SakaDateTime(1948, 1, 1));
    expect(selection?.rangeEnd, isA<SakaDateTime>());
    expect(tester.takeException(), isNull);
  });
}
