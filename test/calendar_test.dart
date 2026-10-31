import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:general_calendar/general_calendar.dart';
import 'package:general_datetime/delegates.dart';
import 'package:general_datetime/default_localizations.dart';
import 'package:general_datetime/general_datetime.dart';

Finder day(int number, {int year = 2024, int month = 3}) =>
    find.byKey(ValueKey('general-calendar-day-$year-$month-$number'));

Future<void> pumpCalendar(
  WidgetTester tester, {
  DateTime? firstDate,
  DateTime? lastDate,
  DateTime? initialDate,
  DateTime? initialDisplayedDate,
  CalendarDateAttributesBuilder? attributes,
  SelectableDayPredicate? predicate,
  CalendarSelectionMode mode = CalendarSelectionMode.single,
  GeneralCalendarView view = GeneralCalendarView.month,
  ValueChanged<DateTime>? onDateChanged,
  ValueChanged<CalendarSelection>? onSelectionChanged,
  CalendarDayBuilder? builder,
  bool readOnly = false,
  bool allowDisabledDatesInRange = false,
  int? maxSelectedDates,
  int? firstDayOfWeek,
  TextDirection direction = TextDirection.ltr,
}) =>
    tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Directionality(
            textDirection: direction,
            child: SizedBox(
              width: 400,
              child: GeneralCalendar(
                firstDate: firstDate ?? DateTime(2024, 3, 1),
                lastDate: lastDate ?? DateTime(2024, 4, 30),
                initialDate: initialDate,
                initialDisplayedDate: initialDisplayedDate,
                currentDate: DateTime(2024, 3, 20),
                selectionMode: mode,
                initialView: view,
                onDateChanged: onDateChanged,
                onSelectionChanged: onSelectionChanged,
                dateAttributes: attributes,
                selectableDayPredicate: predicate,
                dayBuilder: builder,
                readOnly: readOnly,
                allowDisabledDatesInRange: allowDisabledDatesInRange,
                maxSelectedDates: maxSelectedDates,
                firstDayOfWeek: firstDayOfWeek,
              ),
            ),
          ),
        ),
      ),
    );

void main() {
  test('attributes snapshot collections', () {
    final tags = [const CalendarTag(label: 'Meeting')];
    final metadata = <String, Object?>{'count': 1};
    final attributes = CalendarDateAttributes(tags: tags, metadata: metadata);
    tags.clear();
    metadata.clear();
    expect(attributes.tags.single.label, 'Meeting');
    expect(attributes.metadata['count'], 1);
    expect(() => attributes.tags.clear(), throwsUnsupportedError);
    expect(() => attributes.metadata.clear(), throwsUnsupportedError);
  });

  test('rejects invalid configuration and initial selection', () {
    GeneralCalendar make({
      DateTime? first,
      DateTime? last,
      DateTime? initial,
      int? firstDay,
    }) =>
        GeneralCalendar(
          firstDate: first ?? DateTime(2024, 3),
          lastDate: last ?? DateTime(2024, 3, 31),
          initialDate: initial,
          firstDayOfWeek: firstDay,
          dateAttributes: (date) =>
              CalendarDateAttributes(isDisabled: date.day == 5),
        );
    expect(() => make(last: DateTime(2024, 2)), throwsArgumentError);
    expect(() => make(firstDay: 0), throwsArgumentError);
    expect(() => make(initial: DateTime(2024, 3, 5)), throwsArgumentError);
    expect(() => make(initial: DateTime(2025)), throwsArgumentError);
  });

  test(
    'normalizes time and validates initial ranges through disabled days',
    () {
      final calendar = GeneralCalendar(
        firstDate: DateTime(2024, 3, 1, 12),
        lastDate: DateTime(2024, 3, 31, 12),
        initialDate: DateTime(2024, 3, 2, 23),
      );
      expect(calendar.initialDate, DateTime(2024, 3, 2));
      expect(calendar.firstDate.hour, 0);
      expect(
        () => GeneralCalendar(
          firstDate: DateTime(2024, 3),
          lastDate: DateTime(2024, 3, 31),
          selectionMode: CalendarSelectionMode.range,
          initialDateRange: DateTimeRange(
            start: DateTime(2024, 3, 4),
            end: DateTime(2024, 3, 6),
          ),
          selectableDayPredicate: (date) => date.day != 5,
        ),
        throwsArgumentError,
      );
    },
  );

  testWidgets('combines disabled attributes and predicates', (tester) async {
    final selected = <DateTime>[];
    await pumpCalendar(
      tester,
      attributes: (date) => CalendarDateAttributes(isDisabled: date.day == 5),
      predicate: (date) => date.day != 6,
      onDateChanged: selected.add,
    );
    await tester.tap(day(5));
    await tester.tap(day(6));
    expect(selected, isEmpty);
    await tester.tap(day(7));
    expect(selected, [DateTime(2024, 3, 7)]);
  });

  testWidgets('holidays and vacations remain selectable and expose tags', (
    tester,
  ) async {
    DateTime? selected;
    final details = <int, CalendarDayDetails>{};
    await pumpCalendar(
      tester,
      attributes: (date) => CalendarDateAttributes(
        isHoliday: date.day == 4,
        isVacation: date.day == 5,
        tags: date.day == 4 ? [const CalendarTag(label: 'Launch')] : [],
        metadata: {'eventCount': 2},
      ),
      builder: (context, value) {
        details[value.date.day] = value;
        return null;
      },
      onDateChanged: (date) => selected = date,
    );
    await tester.tap(day(4));
    expect(selected?.day, 4);
    await tester.tap(day(5));
    await tester.pump();
    expect(selected?.day, 5);
    expect(details[4]!.attributes.tags.single.label, 'Launch');
    expect(details[5]!.isSelected, isTrue);
    expect(details[20]!.isToday, isTrue);
    expect(details[2]!.isWeekend, isTrue);
    expect(find.byTooltip('Launch'), findsOneWidget);
  });

  testWidgets('custom content cannot enable a disabled date', (tester) async {
    var changed = false;
    await pumpCalendar(
      tester,
      attributes: (date) => CalendarDateAttributes(isDisabled: true),
      builder: (context, details) => Text('Custom ${details.date.day}'),
      onDateChanged: (_) => changed = true,
    );
    await tester.tap(day(8));
    expect(changed, isFalse);
  });

  testWidgets('multiple selection toggles, sorts and limits dates', (
    tester,
  ) async {
    CalendarSelection? selection;
    await pumpCalendar(
      tester,
      mode: CalendarSelectionMode.multiple,
      maxSelectedDates: 2,
      onSelectionChanged: (value) => selection = value,
    );
    await tester.tap(day(8));
    await tester.tap(day(3));
    await tester.tap(day(9));
    expect(selection!.dates.map((d) => d.day), [3, 8]);
    expect(() => selection!.dates.clear(), throwsUnsupportedError);
    await tester.tap(day(3));
    expect(selection!.dates.single.day, 8);
  });

  testWidgets('ranges reject disabled interiors and sort reverse endpoints', (
    tester,
  ) async {
    CalendarSelection? selection;
    var changes = 0;
    await pumpCalendar(
      tester,
      mode: CalendarSelectionMode.range,
      attributes: (date) => CalendarDateAttributes(isDisabled: date.day == 5),
      onSelectionChanged: (value) {
        selection = value;
        changes++;
      },
    );
    await tester.tap(day(8));
    expect(selection!.range, isNull);
    await tester.tap(day(3));
    expect(changes, 1);
    await tester.tap(day(6));
    expect(selection!.range!.start.day, 6);
    expect(selection!.range!.end.day, 8);
    await tester.tap(day(10));
    expect(selection!.rangeStart!.day, 10);
    expect(selection!.rangeEnd, isNull);
  });

  testWidgets('range policy permits disabled interiors but never endpoints', (
    tester,
  ) async {
    CalendarSelection? selection;
    await pumpCalendar(
      tester,
      mode: CalendarSelectionMode.range,
      allowDisabledDatesInRange: true,
      attributes: (date) => CalendarDateAttributes(isDisabled: date.day == 5),
      onSelectionChanged: (value) => selection = value,
    );
    await tester.tap(day(3));
    await tester.tap(day(5));
    expect(selection!.range, isNull);
    await tester.tap(day(8));
    expect(selection!.range!.end.day, 8);
  });

  testWidgets('read-only calendars navigate without changing selection', (
    tester,
  ) async {
    var changes = 0;
    await pumpCalendar(tester, readOnly: true, onDateChanged: (_) => changes++);
    await tester.tap(day(7));
    expect(changes, 0);
    await tester.tap(find.byKey(const ValueKey('general-calendar-next')));
    await tester.pumpAndSettle();
    expect(find.text('April 2024'), findsOneWidget);
  });

  testWidgets('month navigation stops at bounds and disables partial days', (
    tester,
  ) async {
    DateTime? selected;
    await pumpCalendar(
      tester,
      firstDate: DateTime(2024, 3, 10),
      lastDate: DateTime(2024, 3, 20),
      onDateChanged: (value) => selected = value,
    );
    final previous = tester.widget<IconButton>(
      find.byKey(const ValueKey('general-calendar-previous')),
    );
    final next = tester.widget<IconButton>(
      find.byKey(const ValueKey('general-calendar-next')),
    );
    expect(previous.onPressed, isNull);
    expect(next.onPressed, isNull);
    await tester.tap(day(9));
    expect(selected, isNull);
    await tester.tap(day(10));
    expect(selected?.day, 10);
  });

  testWidgets('week view respects week starts and navigates across months', (
    tester,
  ) async {
    await pumpCalendar(
      tester,
      view: GeneralCalendarView.week,
      initialDisplayedDate: DateTime(2024, 3, 31),
      firstDayOfWeek: DateTime.monday,
    );
    expect(day(25), findsOneWidget);
    expect(day(31), findsOneWidget);
    expect(day(24), findsNothing);
    await tester.tap(find.byKey(const ValueKey('general-calendar-next')));
    await tester.pump();
    expect(day(1, month: 4), findsOneWidget);
    expect(day(7, month: 4), findsOneWidget);
  });

  testWidgets('year view drills into a month', (tester) async {
    await pumpCalendar(tester, view: GeneralCalendarView.year);
    await tester.tap(find.text('April 2024'));
    await tester.pump();
    expect(day(5, month: 4), findsOneWidget);
  });

  testWidgets('RTL mirrors weekday cells and navigation works', (tester) async {
    await pumpCalendar(tester, direction: TextDirection.rtl);
    expect(
      tester.getCenter(day(3)).dx,
      greaterThan(tester.getCenter(day(4)).dx),
    );
    await tester.tap(find.byKey(const ValueKey('general-calendar-next')));
    await tester.pumpAndSettle();
    expect(day(1, month: 4), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('day controls support keyboard activation', (tester) async {
    DateTime? selected;
    await pumpCalendar(tester, onDateChanged: (value) => selected = value);
    final target = find
        .descendant(
          of: day(7),
          matching: find.byType(GestureDetector),
        )
        .first;
    final focus = Focus.of(tester.element(target));
    focus.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(selected, DateTime(2024, 3, 7));
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();
    expect(selected, DateTime(2024, 3, 8));
  });

  testWidgets('date semantics include disabled state and attribute labels', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpCalendar(
      tester,
      attributes: (date) => CalendarDateAttributes(
        isDisabled: date.day == 5,
        isHoliday: date.day == 5,
        semanticLabel: date.day == 5 ? 'Office closed' : null,
      ),
    );
    expect(tester.getSemantics(day(5)).label, contains('Office closed'));
    expect(tester.getSemantics(day(5)).label, contains('Holiday'));
    expect(
      tester
          .getSemantics(day(5))
          .getSemanticsData()
          .hasAction(SemanticsAction.tap),
      isFalse,
    );
    semantics.dispose();
  });

  testWidgets('rule updates clear stale selections', (tester) async {
    CalendarDayDetails? captured;
    Widget? builder(BuildContext context, CalendarDayDetails details) {
      if (details.date.day == 7) captured = details;
      return null;
    }

    await pumpCalendar(tester, builder: builder);
    await tester.tap(day(7));
    await tester.pump();
    expect(captured!.isSelected, isTrue);
    await pumpCalendar(
      tester,
      builder: builder,
      attributes: (date) => CalendarDateAttributes(isDisabled: date.day == 7),
    );
    expect(captured!.isSelected, isFalse);
  });

  testWidgets('Persian delegate preserves runtime type and month rollover', (
    tester,
  ) async {
    DateTime? selected;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          DefaultPersianCalendarMaterialLocalizations.delegate,
        ],
        home: Scaffold(
          body: GeneralCalendar(
            firstDate: PersianDateTime(1402, 12, 1),
            lastDate: PersianDateTime(1403, 1, 31),
            initialDate: PersianDateTime(1402, 12, 29),
            currentDate: PersianDateTime(1402, 12, 29),
            calendarDelegate: const PersianCalendarDelegate(),
            onDateChanged: (date) => selected = date,
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('general-calendar-next')));
    await tester.pumpAndSettle();
    await tester.tap(day(1, year: 1403, month: 1));
    expect(selected, isA<PersianDateTime>());
    expect(selected!.year, 1403);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Hebrew year includes Adar I only in leap years', (tester) async {
    Future<void> show(int year) => tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: const [
              DefaultHebrewCalendarMaterialLocalizations.delegate,
            ],
            home: Scaffold(
              body: GeneralCalendar(
                key: ValueKey(year),
                firstDate: HebrewDateTime(year, 1, 1),
                lastDate: HebrewDateTime(year, 13, 29),
                currentDate: HebrewDateTime(year, 1, 1),
                calendarDelegate: const HebrewCalendarDelegate(),
                initialView: GeneralCalendarView.year,
              ),
            ),
          ),
        );
    await show(5784);
    expect(find.byType(TextButton), findsNWidgets(13));
    await show(5785);
    expect(find.byType(TextButton), findsNWidgets(12));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Hijri finite bounds never construct unsupported adjacent days', (
    tester,
  ) async {
    for (final value in [
      HijriDateTime(1300, 1, 1),
      HijriDateTime(1600, 12, 30),
    ]) {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            DefaultHijriCalendarMaterialLocalizations.delegate,
          ],
          home: Scaffold(
            body: GeneralCalendar(
              key: ValueKey(value.year),
              firstDate: HijriDateTime(1300, 1, 1),
              lastDate: HijriDateTime(1600, 12, 30),
              initialDate: value,
              currentDate: value,
              calendarDelegate: const HijriCalendarDelegate(),
              showAdjacentMonthDays: true,
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('changing delegates resets selection with new date types', (
    tester,
  ) async {
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: GeneralCalendar(
      firstDate: DateTime(2024, 3),
      lastDate: DateTime(2024, 4),
      initialDate: DateTime(2024, 3, 20),
    ))));
    final originalState = tester.state(find.byType(GeneralCalendar));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GeneralCalendar(
            firstDate: PersianDateTime(1403, 1),
            lastDate: PersianDateTime(1403, 2),
            initialDate: PersianDateTime(1403, 1, 2),
            currentDate: PersianDateTime(1403, 1, 2),
            calendarDelegate: const PersianCalendarDelegate(),
          ),
        ),
      ),
    );
    expect(day(2, year: 1403, month: 1), findsOneWidget);
    expect(tester.state(find.byType(GeneralCalendar)), same(originalState));
    expect(tester.takeException(), isNull);
  });

  testWidgets('single dialog confirms a date and cancellation returns null', (
    tester,
  ) async {
    DateTime? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await showGeneralDatePicker(
                context: context,
                firstDate: DateTime(2024, 3),
                lastDate: DateTime(2024, 3, 31),
                currentDate: DateTime(2024, 3, 20),
              );
            },
            child: const Text('Open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextButton>(find.widgetWithText(TextButton, 'OK'))
          .onPressed,
      isNull,
    );
    await tester.tap(day(8));
    await tester.pump();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(result, DateTime(2024, 3, 8));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(result, isNull);
  });

  testWidgets('range dialog requires both endpoints before confirming', (
    tester,
  ) async {
    DateTimeRange<DateTime>? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await showGeneralDateRangePicker(
                context: context,
                firstDate: DateTime(2024, 3),
                lastDate: DateTime(2024, 3, 31),
                currentDate: DateTime(2024, 3, 20),
              );
            },
            child: const Text('Open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(day(10));
    await tester.pump();
    expect(
      tester
          .widget<TextButton>(find.widgetWithText(TextButton, 'OK'))
          .onPressed,
      isNull,
    );
    await tester.tap(day(12));
    await tester.pump();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(result!.start, DateTime(2024, 3, 10));
    expect(result!.end, DateTime(2024, 3, 12));
  });
}
