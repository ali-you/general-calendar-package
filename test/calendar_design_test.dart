import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:general_calendar/general_calendar.dart';
import 'package:general_datetime/default_localizations.dart';
import 'package:general_datetime/delegates.dart';
import 'package:general_datetime/general_datetime.dart';

Finder day(int day, {int month = 3, int year = 2024}) =>
    find.byKey(ValueKey('general-calendar-day-$year-$month-$day'));

Widget host(
  GeneralCalendar calendar, {
  double width = 400,
  Brightness brightness = Brightness.light,
  TextDirection direction = TextDirection.ltr,
  double scale = 1,
}) =>
    MaterialApp(
      theme: ThemeData(brightness: brightness),
      home: Scaffold(
          body: Builder(
              builder: (context) => SingleChildScrollView(
                    child: Align(
                        alignment: Alignment.topLeft,
                        child: SizedBox(
                          width: width,
                          child: MediaQuery(
                              data: MediaQuery.of(context).copyWith(
                                  textScaler: TextScaler.linear(scale)),
                              child: Directionality(
                                  textDirection: direction, child: calendar)),
                        )),
                  ))),
    );

GeneralCalendar calendar(
  GeneralCalendarDesign design, {
  ValueChanged<DateTime>? onDateChanged,
  ValueChanged<CalendarSelection>? onSelectionChanged,
  CalendarSelectionMode mode = CalendarSelectionMode.single,
  GeneralCalendarView view = GeneralCalendarView.month,
  GeneralCalendarThemeData? theme,
  CalendarDayBuilder? dayBuilder,
  int? visibleMonths,
}) =>
    GeneralCalendar(
      firstDate: DateTime(2024, 3),
      lastDate: DateTime(2024, 5, 31),
      currentDate: DateTime(2024, 3, 20),
      initialDisplayedDate: DateTime(2024, 3),
      design: design,
      selectionMode: mode,
      initialView: view,
      theme: theme,
      visibleMonths: visibleMonths,
      onDateChanged: onDateChanged,
      onSelectionChanged: onSelectionChanged,
      dateAttributes: (date) => CalendarDateAttributes(
        isDisabled: date.day == 5,
        isHoliday: date.day == 1,
        isVacation: date.day == 10,
        tags: date.day == 4
            ? const [
                CalendarTag(label: 'Team planning'),
                CalendarTag(label: 'Release'),
                CalendarTag(label: 'Holiday event'),
                CalendarTag(label: 'Fourth event'),
              ]
            : const [],
      ),
      dayBuilder: dayBuilder,
    );

void main() {
  test('catalog exposes ten design systems and two additional patterns', () {
    expect(GeneralCalendarDesign.values.where((d) => d.isDesignSystem),
        hasLength(10));
    expect(GeneralCalendarDesign.values, hasLength(12));
    for (final design in GeneralCalendarDesign.values) {
      expect(Uri.parse(design.referenceUrl).scheme, 'https');
    }
  });

  test('partial theme overrides preserve preset geometry and height', () {
    final base = GeneralCalendarDesign.eventGrid.resolve(ThemeData());
    final merged = base
        .merge(const GeneralCalendarThemeData(selectedDayColor: Colors.purple));
    expect(merged.dayHeight, 112);
    expect(merged.showGridLines, isTrue);
    expect(merged.selectedDayColor, Colors.purple);
    expect(base.merge(const GeneralCalendarThemeData(dayHeight: 48)).dayHeight,
        48);
    expect(GeneralCalendarDesign.carbon.resolve(ThemeData()).dayRadius, 0);
    expect(GeneralCalendarDesign.material.resolve(ThemeData()).dayRadius, 100);
  });

  for (final design in GeneralCalendarDesign.values) {
    testWidgets('${design.label} shares date rules and selection callbacks',
        (tester) async {
      DateTime? selected;
      await tester.pumpWidget(
          host(calendar(design, onDateChanged: (date) => selected = date)));
      await tester.ensureVisible(day(5));
      await tester.tap(day(5));
      expect(selected, isNull);
      await tester.tap(day(4));
      await tester.pump();
      expect(selected, DateTime(2024, 3, 4));
      final cell = tester.widget<Semantics>(day(4));
      expect(cell.properties.selected, isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('${design.label} handles dark RTL layout and large text',
        (tester) async {
      await tester.pumpWidget(host(calendar(design),
          width: 320,
          brightness: Brightness.dark,
          direction: TextDirection.rtl,
          scale: 2.5));
      expect(tester.getCenter(day(3)).dx,
          greaterThan(tester.getCenter(day(4)).dx));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('switching designs preserves selected dates and displayed month',
      (tester) async {
    final details = <String, CalendarDayDetails>{};
    Widget? builder(BuildContext context, CalendarDayDetails day) {
      details['${day.date.month}/${day.date.day}'] = day;
      return null;
    }

    await tester.pumpWidget(
        host(calendar(GeneralCalendarDesign.material, dayBuilder: builder)));
    final state = tester.state(find.byType(GeneralCalendar));
    await tester.tap(find.byKey(const ValueKey('general-calendar-next')));
    await tester.pump();
    await tester.tap(day(4, month: 4));
    await tester.pump();
    for (final design in GeneralCalendarDesign.values) {
      await tester.pumpWidget(host(calendar(design, dayBuilder: builder)));
      expect(tester.state(find.byType(GeneralCalendar)), same(state));
      expect(find.text('April 2024'), findsOneWidget);
      expect(details['4/4']!.isSelected, isTrue);
    }
  });

  testWidgets('two-month booking selection shares range state and rules',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1000, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    CalendarSelection? selection;
    CalendarDayDetails? april;
    await tester.pumpWidget(host(
        calendar(GeneralCalendarDesign.booking,
            mode: CalendarSelectionMode.range,
            onSelectionChanged: (value) => selection = value,
            dayBuilder: (context, details) {
              if (details.date.month == 4 && details.date.day == 1) {
                april = details;
              }
              return null;
            }),
        width: 900));
    expect(day(1), findsOneWidget);
    expect(day(1, month: 4), findsOneWidget);
    expect(april!.isOutsideMonth, isFalse);
    await tester.tap(day(28));
    await tester.tap(day(6, month: 4)); // April 5 blocks the interior.
    expect(selection!.rangeEnd, isNull);
    await tester.tap(day(3, month: 4));
    await tester.pump();
    expect(selection!.range!.start, DateTime(2024, 3, 28));
    expect(selection!.range!.end, DateTime(2024, 4, 3));
    expect(
        tester.widget<Semantics>(day(1, month: 4)).properties.selected, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('booking collapses on phones and at the last allowed month',
      (tester) async {
    await tester
        .pumpWidget(host(calendar(GeneralCalendarDesign.booking), width: 360));
    expect(day(1, month: 4), findsNothing);
    await tester.binding.setSurfaceSize(const Size(1000, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(host(
        GeneralCalendar(
          key: const ValueKey('last-month'),
          design: GeneralCalendarDesign.booking,
          firstDate: DateTime(2024, 3),
          lastDate: DateTime(2024, 3, 31),
          currentDate: DateTime(2024, 3, 20),
        ),
        width: 900));
    expect(day(1, month: 4), findsNothing);
    expect(
        tester
            .widget<IconButton>(
                find.byKey(const ValueKey('general-calendar-next')))
            .onPressed,
        isNull);
  });

  testWidgets('two-month panels follow Hebrew common-year month slots',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1000, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: const [
        DefaultHebrewCalendarMaterialLocalizations.delegate
      ],
      home: Scaffold(
          body: SizedBox(
              width: 900,
              child: GeneralCalendar(
                design: GeneralCalendarDesign.booking,
                calendarDelegate: const HebrewCalendarDelegate(),
                firstDate: HebrewDateTime(5785, 5),
                lastDate: HebrewDateTime(5785, 7, 29),
                currentDate: HebrewDateTime(5785, 5, 1),
              ))),
    ));
    expect(day(1, year: 5785, month: 5), findsOneWidget);
    expect(day(1, year: 5785, month: 6), findsNothing);
    expect(day(1, year: 5785, month: 7), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('event grid renders labels and retains complete tag semantics',
      (tester) async {
    await tester.pumpWidget(host(calendar(GeneralCalendarDesign.eventGrid)));
    expect(find.text('Team planning'), findsOneWidget);
    expect(find.text('Release'), findsOneWidget);
    expect(find.text('+2'), findsOneWidget);
    expect(tester.widget<Semantics>(day(4)).properties.label,
        contains('Fourth event'));
    expect(find.text('Today'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('preset layouts remain available in week and year views',
      (tester) async {
    for (final design in GeneralCalendarDesign.values) {
      for (final view in [GeneralCalendarView.week, GeneralCalendarView.year]) {
        await tester.pumpWidget(host(GeneralCalendar(
          key: ValueKey('${design.name}-${view.name}'),
          firstDate: DateTime(2024, 3),
          lastDate: DateTime(2024, 5, 31),
          currentDate: DateTime(2024, 3, 20),
          initialView: view,
          design: design,
        )));
        if (view == GeneralCalendarView.week) {
          expect(day(20), findsOneWidget);
        } else {
          expect(find.text('April 2024'), findsOneWidget);
        }
        expect(tester.takeException(), isNull,
            reason: '${design.name}/${view.name}');
      }
    }
  });

  testWidgets('dialogs accept presets and capture inherited theme overrides',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: GeneralCalendarTheme(
      data: const GeneralCalendarThemeData(selectedDayColor: Colors.purple),
      child: Builder(
          builder: (context) => TextButton(
              onPressed: () => showGeneralDatePicker(
                    context: context,
                    firstDate: DateTime(2024, 3),
                    lastDate: DateTime(2024, 3, 31),
                    initialDate: DateTime(2024, 3, 20),
                    design: GeneralCalendarDesign.carbon,
                  ),
              child: const Text('Open'))),
    )));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    final picker = tester.widget<GeneralCalendar>(find.byType(GeneralCalendar));
    expect(picker.design, GeneralCalendarDesign.carbon);
    expect(picker.theme!.selectedDayColor, Colors.purple);
    expect(tester.takeException(), isNull);
  });
}
