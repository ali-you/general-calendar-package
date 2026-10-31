import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:general_calendar/general_calendar.dart';
import 'package:general_datetime/default_localizations.dart';
import 'package:general_datetime/delegates.dart';
import 'package:general_datetime/general_datetime.dart';

Finder get hour => find.byKey(const ValueKey('general-time-hour'));
Finder get minute => find.byKey(const ValueKey('general-time-minute'));
Finder day(int value, {int year = 2024, int month = 3}) =>
    find.byKey(ValueKey('general-calendar-day-$year-$month-$value'));

Widget host(Widget child,
        {double width = 400,
        bool darkRtl = false,
        List<LocalizationsDelegate<dynamic>> delegates = const []}) =>
    MaterialApp(
      localizationsDelegates: delegates,
      theme:
          ThemeData(brightness: darkRtl ? Brightness.dark : Brightness.light),
      home: Scaffold(
          body: Builder(
              builder: (context) => SingleChildScrollView(
                    child: Align(
                        alignment: Alignment.topLeft,
                        child: SizedBox(
                          width: width,
                          child: MediaQuery(
                              data: MediaQuery.of(context).copyWith(
                                  textScaler:
                                      TextScaler.linear(darkRtl ? 2 : 1)),
                              child: Directionality(
                                  textDirection: darkRtl
                                      ? TextDirection.rtl
                                      : TextDirection.ltr,
                                  child: child)),
                        )),
                  ))),
    );

void main() {
  test('time rules validate configuration and inclusive steps', () {
    expect(
        () => GeneralTimePickerRules(minuteInterval: 7), throwsArgumentError);
    expect(
        () => GeneralTimePickerRules(
            minimumTime: const TimeOfDay(hour: 22, minute: 0),
            maximumTime: const TimeOfDay(hour: 2, minute: 0)),
        throwsArgumentError);
    final rules = GeneralTimePickerRules(
      minimumTime: const TimeOfDay(hour: 9, minute: 15),
      maximumTime: const TimeOfDay(hour: 10, minute: 0),
      minuteInterval: 15,
      selectableTimePredicate: (time) => time.minute != 45,
    );
    expect(rules.times, hasLength(4));
    expect(rules.isSelectable(const TimeOfDay(hour: 9, minute: 15)), isTrue);
    expect(rules.isSelectable(const TimeOfDay(hour: 10, minute: 0)), isTrue);
    expect(rules.isSelectable(const TimeOfDay(hour: 9, minute: 45)), isFalse);
    expect(rules.isSelectable(const TimeOfDay(hour: 9, minute: 16)), isFalse);
    expect(() => rules.times.clear(), throwsUnsupportedError);
  });

  test(
      'composition preserves four calendar types, date fields and UTC precision',
      () {
    final dates = <DateTime>[
      DateTime.utc(2024, 3, 20, 1, 2, 3, 4, 5),
      PersianDateTime.utc(1403, 1, 1, 1, 2, 3, 4, 5),
      HijriDateTime.utc(1445, 9, 10, 1, 2, 3, 4, 5),
      HebrewDateTime.utc(5784, 7, 10, 1, 2, 3, 4, 5),
    ];
    for (final date in dates) {
      final result = CalendarDateTimeUtils.combine(
          date, const TimeOfDay(hour: 14, minute: 30));
      expect(result.runtimeType, date.runtimeType);
      expect([result.year, result.month, result.day],
          [date.year, date.month, date.day]);
      expect(result.isUtc, isTrue);
      expect(result.microsecondsSinceEpoch,
          DateTime.utc(2024, 3, 20, 14, 30).microsecondsSinceEpoch);
    }
    final local = CalendarDateTimeUtils.combine(
        DateTime(2024, 3, 20, 23, 59), const TimeOfDay(hour: 0, minute: 0));
    expect(local, DateTime(2024, 3, 20));
    expect(local.isUtc, isFalse);
  });

  test('combined rules intersect date attributes, time rules and exact bounds',
      () {
    final picker = GeneralDateTimePicker(
      firstDate: DateTime(2024, 3),
      lastDate: DateTime(2024, 3, 31),
      minimumDateTime: DateTime(2024, 3, 20, 9, 30),
      maximumDateTime: DateTime(2024, 3, 21, 16),
      minuteInterval: 15,
      dateAttributes: (date) =>
          CalendarDateAttributes(isDisabled: date.day == 22),
      selectableDateTimePredicate: (date, time) =>
          date.day != 21 || time.hour >= 12,
    );
    expect(
        picker.isTimeSelectable(
            DateTime(2024, 3, 20), const TimeOfDay(hour: 9, minute: 15)),
        isFalse);
    expect(
        picker.isTimeSelectable(
            DateTime(2024, 3, 20), const TimeOfDay(hour: 9, minute: 30)),
        isTrue);
    expect(
        picker.isTimeSelectable(
            DateTime(2024, 3, 21), const TimeOfDay(hour: 11, minute: 30)),
        isFalse);
    expect(
        picker.isTimeSelectable(
            DateTime(2024, 3, 21), const TimeOfDay(hour: 16, minute: 0)),
        isTrue);
    expect(
        picker.isTimeSelectable(
            DateTime(2024, 3, 22), const TimeOfDay(hour: 12, minute: 0)),
        isFalse);
    expect(
        picker.isTimeSelectable(
            DateTime(2024, 3, 20), const TimeOfDay(hour: 10, minute: 1)),
        isFalse);
  });

  test('composition does not round late-day large epochs into tomorrow', () {
    final late = DateTime.utc(9999, 12, 31, 23, 59, 59, 999, 999);
    expect(
        CalendarDateTimeUtils.combine(
            late, const TimeOfDay(hour: 14, minute: 30)),
        DateTime.utc(9999, 12, 31, 14, 30));
    final negative = DateTime.fromMicrosecondsSinceEpoch(-1, isUtc: true);
    expect(
        CalendarDateTimeUtils.combine(
            negative, const TimeOfDay(hour: 0, minute: 0)),
        DateTime.utc(1969, 12, 31));
  });

  testWidgets('confirmation rechecks availability changed after the last edit',
      (tester) async {
    var available = true;
    TimeOfDay? result;
    await tester.pumpWidget(host(Builder(
        builder: (context) => TextButton(
            onPressed: () async {
              result = await showGeneralTimePicker(
                  context: context,
                  initialTime: const TimeOfDay(hour: 14, minute: 30),
                  selectableTimePredicate: (_) => available);
            },
            child: const Text('Open')))));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    available = false;
    await tester.tap(find.byKey(const ValueKey('general-time-confirm')));
    await tester.pump();
    expect(result, isNull);
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(
        tester
            .widget<TextButton>(
                find.byKey(const ValueKey('general-time-confirm')))
            .onPressed,
        isNull);
  });

  testWidgets(
      'numeric input reports valid times and clears malformed/unavailable selection',
      (tester) async {
    TimeOfDay? selected;
    await tester.pumpWidget(host(GeneralTimePicker(
      initialTime: const TimeOfDay(hour: 14, minute: 30),
      use24HourFormat: true,
      minuteInterval: 15,
      selectableTimePredicate: (time) => time.hour != 13,
      onSelectionChanged: (value) => selected = value,
    )));
    await tester.enterText(hour, '15');
    expect(selected, const TimeOfDay(hour: 15, minute: 30));
    await tester.enterText(hour, '13');
    await tester.pump();
    expect(selected, isNull);
    expect(find.text('This time is unavailable'), findsOneWidget);
    await tester.enterText(hour, 'xx');
    await tester.pump();
    expect(find.text('Enter a valid time'), findsOneWidget);
    await tester.enterText(hour, '24');
    expect(selected, isNull);
    await tester.enterText(hour, '00');
    await tester.enterText(minute, '00');
    expect(selected, const TimeOfDay(hour: 0, minute: 0));
  });

  testWidgets('12-hour input distinguishes midnight and noon', (tester) async {
    TimeOfDay? selected;
    await tester.pumpWidget(host(GeneralTimePicker(
      initialTime: const TimeOfDay(hour: 0, minute: 0),
      use24HourFormat: false,
      onTimeChanged: (time) => selected = time,
    )));
    expect(tester.widget<TextField>(hour).controller!.text, '12');
    await tester.tap(find.byKey(const ValueKey('general-time-pm')));
    expect(selected, const TimeOfDay(hour: 12, minute: 0));
    await tester.tap(find.byKey(const ValueKey('general-time-am')));
    expect(selected, const TimeOfDay(hour: 0, minute: 0));
  });

  testWidgets('numeric input accepts Persian and Arabic digits',
      (tester) async {
    TimeOfDay? selected;
    await tester.pumpWidget(host(GeneralTimePicker(
      use24HourFormat: true,
      onTimeChanged: (time) => selected = time,
    )));
    await tester.enterText(hour, '۱۴');
    await tester.enterText(minute, '٣٠');
    expect(selected, const TimeOfDay(hour: 14, minute: 30));
  });

  testWidgets('numeric fields stay on one row at phone dialog widths',
      (tester) async {
    await tester.pumpWidget(host(
        GeneralTimePicker(
            initialTime: const TimeOfDay(hour: 14, minute: 30),
            use24HourFormat: true),
        width: 256));
    expect(tester.getTopLeft(hour).dy, tester.getTopLeft(minute).dy);
    expect(tester.takeException(), isNull);
  });

  testWidgets('dial chooses 24-hour ring values and blocks unavailable minutes',
      (tester) async {
    TimeOfDay? selected;
    await tester.pumpWidget(host(GeneralTimePicker(
      initialTime: const TimeOfDay(hour: 14, minute: 30),
      use24HourFormat: true,
      view: GeneralTimePickerView.dial,
      minuteInterval: 15,
      onTimeChanged: (time) => selected = time,
    )));
    await tester.tap(find.byKey(const ValueKey('general-time-dial-hour-15')));
    await tester.pump();
    expect(selected, const TimeOfDay(hour: 15, minute: 30));
    expect(
        tester
            .widget<TextButton>(
                find.byKey(const ValueKey('general-time-dial-minute-5')))
            .onPressed,
        isNull);
    await tester.tap(find.byKey(const ValueKey('general-time-dial-minute-45')));
    expect(selected, const TimeOfDay(hour: 15, minute: 45));
  });

  testWidgets('hour dragging stays in hour mode throughout the gesture',
      (tester) async {
    final selected = <TimeOfDay>[];
    await tester.pumpWidget(host(GeneralTimePicker(
      initialTime: const TimeOfDay(hour: 2, minute: 30),
      use24HourFormat: false,
      view: GeneralTimePickerView.dial,
      onTimeChanged: selected.add,
    )));
    final center =
        tester.getCenter(find.byKey(const ValueKey('general-time-dial')));
    final gesture = await tester.startGesture(center + const Offset(90, 0));
    await gesture.moveBy(const Offset(0, 40));
    await tester.pump();
    await gesture.moveBy(const Offset(-40, 40));
    await tester.pump();
    await gesture.up();
    expect(selected, isNotEmpty);
    expect(selected.every((time) => time.minute == 30), isTrue);
  });

  testWidgets('dial keyboard toggle supports exact non-label minute values',
      (tester) async {
    TimeOfDay? selected;
    await tester.pumpWidget(host(GeneralTimePicker(
      initialTime: const TimeOfDay(hour: 14, minute: 0),
      use24HourFormat: true,
      view: GeneralTimePickerView.dial,
      minuteInterval: 6,
      onTimeChanged: (value) => selected = value,
    )));
    await tester.tap(find.byKey(const ValueKey('general-time-toggle-entry')));
    await tester.pump();
    await tester.enterText(minute, '06');
    expect(selected, const TimeOfDay(hour: 14, minute: 6));
    await tester.tap(find.byKey(const ValueKey('general-time-toggle-entry')));
    await tester.pump();
    expect(find.byKey(const ValueKey('general-time-dial')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('dropdown selects enabled interval entries', (tester) async {
    TimeOfDay? selected;
    await tester.pumpWidget(host(GeneralTimePicker(
      initialTime: const TimeOfDay(hour: 14, minute: 0),
      use24HourFormat: true,
      view: GeneralTimePickerView.dropdown,
      minuteInterval: 30,
      minimumTime: const TimeOfDay(hour: 14, minute: 0),
      maximumTime: const TimeOfDay(hour: 15, minute: 0),
      selectableTimePredicate: (time) => time.hour != 15,
      onTimeChanged: (time) => selected = time,
    )));
    await tester.tap(find.byType(DropdownButton<TimeOfDay>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('14:30').last);
    await tester.pumpAndSettle();
    expect(selected, const TimeOfDay(hour: 14, minute: 30));
  });

  testWidgets('appointment slots enforce bounds and disabled predicates',
      (tester) async {
    TimeOfDay? selected;
    await tester.pumpWidget(host(GeneralTimePicker(
      view: GeneralTimePickerView.slots,
      minuteInterval: 30,
      minimumTime: const TimeOfDay(hour: 9, minute: 0),
      maximumTime: const TimeOfDay(hour: 11, minute: 0),
      selectableTimePredicate: (time) => time.hour != 10,
      onTimeChanged: (time) => selected = time,
    )));
    final blocked = find.byKey(const ValueKey('general-time-slot-10-0'));
    expect(tester.widget<OutlinedButton>(blocked).onPressed, isNull);
    await tester.tap(find.byKey(const ValueKey('general-time-slot-9-30')));
    expect(selected, const TimeOfDay(hour: 9, minute: 30));
  });

  testWidgets('wheels survive controller updates and emit valid increments',
      (tester) async {
    TimeOfDay? selected;
    Widget picker(int step, bool is24) => host(GeneralTimePicker(
          view: GeneralTimePickerView.wheels,
          minuteInterval: step,
          use24HourFormat: is24,
          initialTime: const TimeOfDay(hour: 14, minute: 30),
          onTimeChanged: (time) => selected = time,
        ));
    await tester.pumpWidget(picker(15, true));
    final wheels = tester
        .widgetList<CupertinoPicker>(find.byType(CupertinoPicker))
        .toList();
    wheels.last.scrollController!.jumpToItem(3);
    await tester.pumpAndSettle();
    expect(selected, const TimeOfDay(hour: 14, minute: 45));
    await tester.pumpWidget(picker(5, false));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  for (final view in GeneralTimePickerView.values) {
    testWidgets('${view.name} supports dark RTL and enlarged text',
        (tester) async {
      await tester.pumpWidget(host(
          GeneralTimePicker(
            view: view,
            initialTime: const TimeOfDay(hour: 14, minute: 30),
            minuteInterval: 15,
            use24HourFormat: false,
          ),
          width: 300,
          darkRtl: true));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('all twelve designs can theme time input without losing draft',
      (tester) async {
    await tester.pumpWidget(host(GeneralTimePicker(
        initialTime: const TimeOfDay(hour: 14, minute: 30),
        use24HourFormat: true)));
    await tester.enterText(hour, '15');
    for (final design in GeneralCalendarDesign.values) {
      await tester.pumpWidget(host(GeneralTimePicker(
        design: design,
        initialTime: const TimeOfDay(hour: 14, minute: 30),
        use24HourFormat: true,
      )));
      await tester.pump();
      expect(tester.widget<TextField>(hour).controller!.text, '15');
    }
  });

  testWidgets('wheels show an off-step draft without silently rounding it',
      (tester) async {
    TimeOfDay? selected;
    await tester.pumpWidget(host(GeneralTimePicker(
      view: GeneralTimePickerView.wheels,
      use24HourFormat: true,
      minuteInterval: 15,
      initialTime: const TimeOfDay(hour: 14, minute: 17),
      onSelectionChanged: (time) => selected = time,
    )));
    final picker =
        tester.widgetList<CupertinoPicker>(find.byType(CupertinoPicker)).last;
    expect(picker.scrollController!.selectedItem, 2); // 00, 15, 17, 30, 45.
    expect(find.text('This time is unavailable'), findsOneWidget);
    picker.scrollController!.jumpToItem(3);
    await tester.pumpAndSettle();
    expect(selected, const TimeOfDay(hour: 14, minute: 30));
  });

  testWidgets('read-only time input disables edits and picker actions',
      (tester) async {
    var changes = 0;
    await tester.pumpWidget(host(GeneralTimePicker(
      readOnly: true,
      initialTime: const TimeOfDay(hour: 14, minute: 30),
      onTimeChanged: (_) => changes++,
      use24HourFormat: true,
    )));
    expect(tester.widget<TextField>(hour).readOnly, isTrue);
    await tester.pumpWidget(host(GeneralTimePicker(
      readOnly: true,
      initialTime: const TimeOfDay(hour: 14, minute: 30),
      view: GeneralTimePickerView.slots,
      minuteInterval: 30,
      minimumTime: const TimeOfDay(hour: 14, minute: 0),
      maximumTime: const TimeOfDay(hour: 15, minute: 0),
      onTimeChanged: (_) => changes++,
    )));
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<OutlinedButton>(
                find.byKey(const ValueKey('general-time-slot-14-30')))
            .onPressed,
        isNull);
    expect(changes, 0);
  });

  testWidgets(
      'unavailable initial time disables dialog confirmation and cancellation returns null',
      (tester) async {
    TimeOfDay? result = const TimeOfDay(hour: 1, minute: 0);
    await tester.pumpWidget(host(Builder(
        builder: (context) => TextButton(
            onPressed: () async {
              result = await showGeneralTimePicker(
                  context: context,
                  initialTime: const TimeOfDay(hour: 14, minute: 30),
                  selectableTimePredicate: (_) => false,
                  view: GeneralTimePickerView.slots);
            },
            child: const Text('Open')))));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('No available times'), findsOneWidget);
    expect(
        tester
            .widget<TextButton>(
                find.byKey(const ValueKey('general-time-confirm')))
            .onPressed,
        isNull);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(result, isNull);
  });

  testWidgets(
      'combined dialog works on a phone and requires both date and time',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    DateTime? result;
    await tester.pumpWidget(host(Builder(
        builder: (context) => TextButton(
            onPressed: () async {
              result = await showGeneralDateTimePicker(
                  context: context,
                  firstDate: DateTime(2024, 3),
                  lastDate: DateTime(2024, 3, 31),
                  currentDate: DateTime(2024, 3, 20),
                  use24HourFormat: true);
            },
            child: const Text('Open')))));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    final confirm = find.byKey(const ValueKey('general-time-confirm'));
    expect(tester.widget<TextButton>(confirm).onPressed, isNull);
    await tester.ensureVisible(day(20));
    await tester.tap(day(20));
    await tester.ensureVisible(hour);
    await tester.enterText(hour, '14');
    await tester.enterText(minute, '30');
    await tester.pump();
    await tester.tap(confirm);
    await tester.pumpAndSettle();
    expect(result, DateTime(2024, 3, 20, 14, 30));
    expect(tester.takeException(), isNull);
  });

  test('custom builders cannot return a different calendar or wall time', () {
    final picker = GeneralDateTimePicker(
      firstDate: DateTime(2024, 3),
      lastDate: DateTime(2024, 3, 31),
      dateTimeBuilder: (date, time) =>
          DateTime(date.year, date.month, date.day, time.hour + 1),
    );
    expect(
        () => picker.selectionFor(
            DateTime(2024, 3, 20), const TimeOfDay(hour: 14, minute: 0)),
        throwsStateError);
    final gap = GeneralDateTimePicker(
      firstDate: DateTime(2024, 3),
      lastDate: DateTime(2024, 3, 31),
      dateTimeBuilder: (_, __) =>
          throw const FormatException('Nonexistent local time'),
    );
    expect(
        gap.selectionFor(
            DateTime(2024, 3, 20), const TimeOfDay(hour: 14, minute: 0)),
        isNull);
  });

  testWidgets('time dialog clears confirmation for an invalid edited draft',
      (tester) async {
    TimeOfDay? result;
    await tester.pumpWidget(host(Builder(
        builder: (context) => TextButton(
            onPressed: () async {
              result = await showGeneralTimePicker(
                  context: context,
                  initialTime: const TimeOfDay(hour: 14, minute: 30),
                  use24HourFormat: true);
            },
            child: const Text('Open')))));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    final confirm = find.byKey(const ValueKey('general-time-confirm'));
    await tester.enterText(hour, '99');
    await tester.pump();
    expect(tester.widget<TextButton>(confirm).onPressed, isNull);
    await tester.enterText(hour, '15');
    await tester.pump();
    await tester.tap(confirm);
    await tester.pumpAndSettle();
    expect(result, const TimeOfDay(hour: 15, minute: 30));
  });

  testWidgets('combined picker reevaluates a retained time after date changes',
      (tester) async {
    DateTime? selected = DateTime(2024, 3, 20, 14, 30);
    await tester.pumpWidget(host(GeneralDateTimePicker(
      firstDate: DateTime(2024, 3),
      lastDate: DateTime(2024, 3, 31),
      initialDateTime: selected,
      use24HourFormat: true,
      selectableDateTimePredicate: (date, time) =>
          date.day != 21 || time.hour >= 15,
      onSelectionChanged: (value) => selected = value,
    )));
    await tester.tap(day(21));
    await tester.pump();
    expect(selected, isNull);
    await tester.tap(day(20));
    await tester.pump();
    expect(selected, DateTime(2024, 3, 20, 14, 30));
    await tester.tap(day(21));
    await tester.pump();
    await tester.ensureVisible(hour);
    await tester.enterText(hour, '15');
    expect(selected, DateTime(2024, 3, 21, 15, 30));
  });

  testWidgets(
      'combined picker emits Persian, Hijri, Hebrew and Chinese date types',
      (tester) async {
    final cases = <(
      DateTime,
      CalendarDelegate<DateTime>,
      LocalizationsDelegate<dynamic>
    )>[
      (
        PersianDateTime(1403, 1, 1, 14, 30),
        const PersianCalendarDelegate(),
        DefaultPersianCalendarMaterialLocalizations.delegate
      ),
      (
        HijriDateTime(1445, 9, 10, 14, 30),
        const HijriCalendarDelegate(),
        DefaultHijriCalendarMaterialLocalizations.delegate
      ),
      (
        HebrewDateTime(5784, 7, 10, 14, 30),
        const HebrewCalendarDelegate(),
        DefaultHebrewCalendarMaterialLocalizations.delegate
      ),
      (
        ChineseDateTime(2025, 7, 10, 14, 30),
        const ChineseCalendarDelegate(),
        DefaultChineseCalendarMaterialLocalizations.delegate
      ),
    ];
    for (final (date, delegate, localization) in cases) {
      DateTime? selected;
      await tester.pumpWidget(host(
          GeneralDateTimePicker(
            key: ValueKey(date.runtimeType),
            calendarDelegate: delegate,
            firstDate: delegate.getMonth(date.year, date.month),
            lastDate: delegate.getDay(date.year, date.month,
                delegate.getDaysInMonth(date.year, date.month)),
            initialDateTime: date,
            currentDate: date,
            use24HourFormat: true,
            onDateTimeChanged: (value) => selected = value,
          ),
          delegates: [localization]));
      await tester.ensureVisible(minute);
      await tester.enterText(minute, '45');
      expect(selected.runtimeType, date.runtimeType);
      final result = selected!;
      expect([result.year, result.month, result.day],
          [date.year, date.month, date.day]);
      expect(result.hour, 14);
      expect(result.minute, 45);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets(
      'combined dialog returns a minute-precision date and supports cancellation',
      (tester) async {
    DateTime? result;
    await tester.pumpWidget(host(Builder(
        builder: (context) => TextButton(
            onPressed: () async {
              result = await showGeneralDateTimePicker(
                  context: context,
                  firstDate: DateTime(2024, 3),
                  lastDate: DateTime(2024, 3, 31),
                  initialDateTime: DateTime(2024, 3, 20, 14, 30, 15, 5),
                  use24HourFormat: true);
            },
            child: const Text('Open')))));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('general-time-confirm')));
    await tester.pumpAndSettle();
    expect(result, DateTime(2024, 3, 20, 14, 30));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(result, isNull);
  });
}
