import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:general_calendar/general_calendar.dart';
import 'package:general_calendar_example/appointment_example.dart';
import 'package:general_calendar_example/main.dart';
import 'package:general_datetime/general_datetime.dart';

Future<void> _show(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, Finder target) async {
  await _show(tester, target);
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Finder _day(int day) =>
    // A modal can leave the underlying calendar mounted; target the top one.
    find.byKey(ValueKey('general-calendar-day-2024-3-$day')).last;

Future<void> _selectMenu(WidgetTester tester, String key, String option) async {
  await _tap(tester, find.byKey(ValueKey(key)));
  await _tap(tester, find.text(option).last);
}

Future<void> _pumpExample(WidgetTester tester,
    {DateTime? now, Size size = const Size(1024, 900)}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester
      .pumpWidget(CalendarExample(now: () => now ?? DateTime(2024, 3, 20)));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('calendar and time drafts survive scrolling between sections',
      (tester) async {
    await _pumpExample(tester, size: const Size(360, 800));
    await _tap(tester, _day(20));
    final hour = find.byKey(const ValueKey('general-time-hour'));
    await _show(tester, hour);
    await tester.enterText(hour, '16');
    await tester.pumpAndSettle();
    await _tap(tester, _day(21));
    expect(
        tester.widget<Text>(find.byKey(const ValueKey('calendar-result'))).data,
        '2024/3/21');
    await _show(tester, hour);
    expect(tester.widget<TextField>(hour).controller!.text, '16');
    expect(tester.widget<Text>(find.byKey(const ValueKey('time-result'))).data,
        '16:30');
    expect(tester.takeException(), isNull);
  });

  testWidgets('multiple selection enforces its cap, toggles and resets',
      (tester) async {
    await _pumpExample(tester);
    await _selectMenu(tester, 'calendar-selection-mode', 'multiple');
    for (final day in [18, 19, 20, 21, 23, 24]) {
      await _tap(tester, _day(day));
    }
    final result = find.byKey(const ValueKey('calendar-result'));
    expect(tester.widget<Text>(result).data,
        '2024/3/18, 2024/3/19, 2024/3/20, 2024/3/21, 2024/3/23');
    await _tap(tester, _day(18));
    await _tap(tester, _day(24));
    expect(tester.widget<Text>(result).data,
        '2024/3/19, 2024/3/20, 2024/3/21, 2024/3/23, 2024/3/24');
    await _tap(tester, find.byKey(const ValueKey('reset-calendar')));
    expect(tester.widget<Text>(result).data, 'Choose a date');
    expect(find.byKey(const ValueKey('selected-date-details')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'range dialog requires two endpoints and cancellation keeps result',
      (tester) async {
    await _pumpExample(tester);
    await _tap(tester, find.text('Open range picker'));
    final confirm = find.widgetWithText(TextButton, 'OK');
    expect(tester.widget<TextButton>(confirm).onPressed, isNull);
    await _tap(tester, _day(18));
    expect(tester.widget<TextButton>(confirm).onPressed, isNull);
    await _tap(tester, _day(20));
    await _tap(tester, confirm);
    final result = find.byKey(const ValueKey('dialog-result'));
    expect(tester.widget<Text>(result).data, '2024/3/18 — 2024/3/20');
    await _tap(tester, find.text('Open range picker'));
    await _tap(tester, _day(25));
    await _tap(tester, find.text('Cancel'));
    expect(tester.widget<Text>(result).data, '2024/3/18 — 2024/3/20');
    expect(tester.takeException(), isNull);
  });

  testWidgets('range rules can allow disabled interiors but not endpoints',
      (tester) async {
    await _pumpExample(tester);
    await _selectMenu(tester, 'calendar-selection-mode', 'range');
    final result = find.byKey(const ValueKey('calendar-result'));
    await _tap(tester, _day(21));
    await _tap(tester, _day(23));
    expect(tester.widget<Text>(result).data, '2024/3/21 — Choose end');
    await _tap(tester, find.text('Calendar options'));
    await _tap(tester, find.text('Allow disabled days inside ranges'));
    await _tap(tester, find.text('Calendar options'));
    await _tap(tester, _day(21));
    await _tap(tester, _day(22)); // Friday is still an unavailable endpoint.
    expect(tester.widget<Text>(result).data, '2024/3/21 — Choose end');
    await _tap(tester, _day(23));
    expect(tester.widget<Text>(result).data, '2024/3/21 — 2024/3/23');
    expect(tester.takeException(), isNull);
  });

  testWidgets('read-only keeps selection and permits navigation',
      (tester) async {
    await _pumpExample(tester);
    await _tap(tester, _day(20));
    await _tap(tester, find.text('Calendar options'));
    await _tap(tester, find.text('Read only'));
    await _tap(tester, find.text('Calendar options'));
    await _tap(tester, _day(21));
    expect(
        tester.widget<Text>(find.byKey(const ValueKey('calendar-result'))).data,
        '2024/3/20');
    await _tap(tester, find.byKey(const ValueKey('general-calendar-next')));
    expect(find.text('April 2024'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('custom cells, theme and RTL work at phone width',
      (tester) async {
    await _pumpExample(tester, size: const Size(360, 800));
    await _tap(tester, find.text('Calendar options'));
    await _tap(tester, find.text('Show availability in custom day cells'));
    await _tap(tester, find.text('Purple theme overrides'));
    await _tap(tester, find.text('Preview right-to-left layout'));
    await _tap(tester, find.text('Calendar options'));
    await _tap(tester, _day(20));
    expect(find.descendant(of: _day(20), matching: find.text('0 left')),
        findsOneWidget);
    expect(Directionality.of(tester.element(_day(20))), TextDirection.rtl);
    expect(GeneralCalendarTheme.of(tester.element(_day(20))).selectedDayColor,
        Colors.deepPurple);
    expect(
        tester.widget<Text>(find.byKey(const ValueKey('calendar-result'))).data,
        '2024/3/20'); // Zero places are metadata, not a disabled-date rule.
    expect(tester.takeException(), isNull);
  });

  testWidgets('inline and dialog time inputs share availability rules',
      (tester) async {
    await _pumpExample(tester);
    final hour = find.byKey(const ValueKey('general-time-hour'));
    await _show(tester, hour);
    await tester.enterText(hour, '12');
    await tester.pumpAndSettle();
    expect(tester.widget<Text>(find.byKey(const ValueKey('time-result'))).data,
        'Choose an available time');
    await _tap(tester, find.text('Open time picker'));
    final dialogHour = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byKey(const ValueKey('general-time-hour')));
    await tester.enterText(dialogHour, '12');
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<TextButton>(
                find.byKey(const ValueKey('general-time-confirm')))
            .onPressed,
        isNull);
    await tester.enterText(dialogHour, '16');
    await tester.pumpAndSettle();
    await _tap(tester, find.byKey(const ValueKey('general-time-confirm')));
    expect(
        tester.widget<Text>(find.byKey(const ValueKey('dialog-result'))).data,
        '16:30');
    expect(tester.widget<Text>(find.byKey(const ValueKey('time-result'))).data,
        'Choose an available time');
    expect(tester.takeException(), isNull);
  });

  testWidgets('appointment invalidation clears a previously confirmed draft',
      (tester) async {
    await _pumpExample(tester);
    await _tap(tester, find.text('Open appointment example'));
    await _selectMenu(tester, 'appointment-time-view', 'input');
    final confirm = find.byKey(const ValueKey('appointment-confirm'));
    await _tap(tester, confirm);
    expect(find.byKey(const ValueKey('appointment-result')), findsOneWidget);
    final hour = find.byKey(const ValueKey('general-time-hour'));
    await _show(tester, hour);
    await tester.enterText(hour, '12');
    await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(confirm).onPressed, isNull);
    expect(find.byKey(const ValueKey('appointment-result')), findsNothing);
    await tester.enterText(hour, '09'); // Earlier than today's exact minimum.
    await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(confirm).onPressed, isNull);
    await tester.enterText(hour, '16');
    await tester.pumpAndSettle();
    await _tap(tester, confirm);
    expect(
        tester
            .widget<SelectableText>(
                find.byKey(const ValueKey('appointment-result')))
            .data,
        contains('2024/3/20 16:30'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('appointment preserves Persian dates and skips a closed Friday',
      (tester) async {
    await _pumpExample(tester, now: DateTime(2024, 3, 22));
    await _selectMenu(tester, 'calendar-system', 'persian');
    await _tap(tester, find.text('Open appointment example'));
    final page =
        tester.widget<AppointmentExample>(find.byType(AppointmentExample));
    final picker = tester
        .widget<GeneralDateTimePicker>(find.byType(GeneralDateTimePicker));
    final initial = picker.initialDateTime!;
    expect(initial, isA<PersianDateTime>());
    expect(initial.weekday, DateTime.saturday);
    expect(
        page.calendarDelegate.isSameDay(
            initial, PersianDateTime.fromDateTime(DateTime(2024, 3, 23))),
        isTrue);
    await _tap(tester, find.byKey(const ValueKey('appointment-confirm')));
    expect(
        tester
            .widget<SelectableText>(
                find.byKey(const ValueKey('appointment-result')))
            .data,
        contains('Calendar type: PersianDateTime'));
    expect(tester.takeException(), isNull);
  });
}
