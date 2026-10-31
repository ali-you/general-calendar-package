import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:general_calendar/general_calendar.dart';
import 'package:general_datetime/default_localizations.dart';
import 'package:general_datetime/delegates.dart';
import 'package:general_datetime/general_datetime.dart';

final pager = find.byKey(const ValueKey('general-calendar-month-pager'));
final next = find.byKey(const ValueKey('general-calendar-next'));
final previous = find.byKey(const ValueKey('general-calendar-previous'));

Finder day(int month, int day) =>
    find.byKey(ValueKey('general-calendar-day-2024-$month-$day'));

Widget host(
  GeneralCalendar calendar, {
  TextDirection direction = TextDirection.ltr,
  bool reducedMotion = false,
  double width = 400,
}) =>
    MaterialApp(
      localizationsDelegates: [
        if (calendar.calendarDelegate is ChineseCalendarDelegate)
          DefaultChineseCalendarMaterialLocalizations.delegate,
      ],
      home: Scaffold(
        body: SingleChildScrollView(
          child: SizedBox(
            width: width,
            child: MediaQuery(
              data: MediaQueryData(disableAnimations: reducedMotion),
              child: Directionality(
                textDirection: direction,
                child: calendar,
              ),
            ),
          ),
        ),
      ),
    );

GeneralCalendar calendar({
  ValueChanged<DateTime>? onMonthChanged,
  ValueChanged<DateTime>? onDateChanged,
  bool enableSwipeNavigation = true,
  Duration animationDuration = const Duration(milliseconds: 250),
  int? visibleMonths,
  DateTime? lastDate,
}) =>
    GeneralCalendar(
      firstDate: DateTime(2024, 3, 10),
      lastDate: lastDate ?? DateTime(2024, 6, 20),
      currentDate: DateTime(2024, 3, 20),
      initialDate: DateTime(2024, 3, 20),
      onDisplayedMonthChanged: onMonthChanged,
      onDateChanged: onDateChanged,
      enableSwipeNavigation: enableSwipeNavigation,
      animationDuration: animationDuration,
      visibleMonths: visibleMonths,
    );

double pageOf(WidgetTester tester) =>
    tester.widget<PageView>(pager).controller!.page!;

void main() {
  for (final rtl in [false, true]) {
    testWidgets('swipes page in both directions with bounds, RTL=$rtl',
        (tester) async {
      final changes = <DateTime>[];
      var selections = 0;
      await tester.pumpWidget(host(
        calendar(
          onMonthChanged: changes.add,
          onDateChanged: (_) => selections++,
        ),
        direction: rtl ? TextDirection.rtl : TextDirection.ltr,
      ));
      final forward = Offset(rtl ? 320 : -320, 0);
      await tester.drag(pager, -forward); // First-month boundary.
      await tester.pumpAndSettle();
      expect(pageOf(tester), 0);
      expect(changes, isEmpty);
      await tester.drag(pager, forward);
      await tester.pumpAndSettle();
      expect(find.text('April 2024'), findsOneWidget);
      expect(changes, [DateTime(2024, 4)]);
      expect(selections, 0);
      await tester.drag(pager, -forward);
      await tester.pumpAndSettle();
      expect(changes, [DateTime(2024, 4), DateTime(2024, 3)]);
      expect(tester.widget<Semantics>(day(3, 20)).properties.selected, isTrue);
      for (var i = 0; i < 4; i++) {
        await tester.drag(pager, forward);
        await tester.pumpAndSettle();
      }
      expect(pageOf(tester), 3);
      expect(changes.map((date) => date.month), [4, 3, 4, 5, 6]);
      expect(tester.widget<IconButton>(next).onPressed, isNull);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('arrow navigation animates position and calendar height',
      (tester) async {
    final changes = <DateTime>[];
    await tester.pumpWidget(host(calendar(onMonthChanged: changes.add)));
    final marchHeight = tester.getSize(pager).height;
    await tester.tap(next);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    expect(pageOf(tester), greaterThan(0));
    expect(pageOf(tester), lessThan(1));
    expect(tester.getSize(pager).height, lessThan(marchHeight));
    expect(tester.getSize(pager).height, greaterThan(marchHeight - 48));
    await tester.pumpAndSettle();
    expect(pageOf(tester), 1);
    expect(tester.getSize(pager).height, marchHeight - 48);
    expect(changes, [DateTime(2024, 4)]);
    await tester.tap(day(4, 12));
    await tester.pump();
    expect(tester.widget<Semantics>(day(4, 12)).properties.selected, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('drag follows the pointer without snapping at the halfway mark',
      (tester) async {
    await tester.pumpWidget(host(calendar()));
    final gesture = await tester.startGesture(tester.getCenter(pager));
    await gesture.moveBy(const Offset(-30, 0));
    await gesture.moveBy(const Offset(-220, 0));
    await tester.pump();
    final position = pageOf(tester);
    expect(position, greaterThan(0.5));
    await tester.pump(const Duration(milliseconds: 350));
    expect(pageOf(tester), closeTo(position, 0.001));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(pageOf(tester), 1);
  });

  testWidgets('mouse drags page while vertical drags scroll the parent',
      (tester) async {
    await tester.pumpWidget(host(calendar()));
    await tester.drag(pager, const Offset(-320, 0),
        kind: PointerDeviceKind.mouse);
    await tester.pumpAndSettle();
    expect(pageOf(tester), 1);
    await tester.drag(pager, const Offset(0, -80));
    await tester.pumpAndSettle();
    expect(pageOf(tester), 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('rapid and reversed arrow presses keep header and page in sync',
      (tester) async {
    final changes = <DateTime>[];
    await tester.pumpWidget(host(calendar(onMonthChanged: changes.add)));
    await tester.tap(next);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 40));
    await tester.tap(next);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 40));
    await tester.tap(previous);
    await tester.pumpAndSettle();
    expect(pageOf(tester), 1);
    expect(find.text('April 2024'), findsOneWidget);
    expect(changes.map((date) => date.month), [4, 5, 4]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('swiping can be disabled independently of arrow navigation',
      (tester) async {
    await tester.pumpWidget(host(calendar(enableSwipeNavigation: false)));
    await tester.drag(pager, const Offset(-320, 0));
    await tester.pumpAndSettle();
    expect(pageOf(tester), 0);
    await tester.tap(next);
    await tester.pumpAndSettle();
    expect(pageOf(tester), 1);
  });

  testWidgets(
      'a drag can interrupt arrow animation and return to the first month',
      (tester) async {
    final changes = <DateTime>[];
    await tester.pumpWidget(host(calendar(onMonthChanged: changes.add)));
    await tester.tap(next);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    await tester.drag(pager, const Offset(350, 0));
    await tester.pumpAndSettle();
    expect(pageOf(tester), 0);
    expect(find.text('March 2024'), findsOneWidget);
    expect(changes.map((date) => date.month), [4, 3]);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'narrowing bounds replaces the viewport without navigation callbacks',
      (tester) async {
    final changes = <DateTime>[];
    await tester.pumpWidget(host(calendar(onMonthChanged: changes.add)));
    await tester.drag(pager, const Offset(-320, 0));
    await tester.pumpAndSettle();
    changes.clear();
    await tester.pumpWidget(host(calendar(
      lastDate: DateTime(2024, 3, 31),
      onMonthChanged: changes.add,
    )));
    expect(pageOf(tester), 0);
    expect(find.text('March 2024'), findsOneWidget);
    expect(changes, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Today jumps across months with a single navigation callback',
      (tester) async {
    final changes = <DateTime>[];
    await tester.pumpWidget(host(GeneralCalendar(
      firstDate: DateTime(2024),
      lastDate: DateTime(2024, 12, 31),
      initialDisplayedDate: DateTime(2024, 1),
      currentDate: DateTime(2024, 10, 20),
      design: GeneralCalendarDesign.eventGrid,
      theme: const GeneralCalendarThemeData(dayHeight: 48),
      onDisplayedMonthChanged: changes.add,
    )));
    await tester.tap(find.text('Today'));
    await tester.pumpAndSettle();
    expect(find.text('October 2024'), findsOneWidget);
    expect(pageOf(tester), 9);
    expect(changes, [DateTime(2024, 10)]);
    expect(tester.takeException(), isNull);
  });

  for (final reducedMotion in [false, true]) {
    testWidgets('immediate navigation with reducedMotion=$reducedMotion',
        (tester) async {
      await tester.pumpWidget(host(
        calendar(
          animationDuration:
              reducedMotion ? const Duration(milliseconds: 250) : Duration.zero,
        ),
        reducedMotion: reducedMotion,
      ));
      await tester.tap(next);
      await tester.pump();
      expect(pageOf(tester), 1);
      expect(day(4, 1), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('two-month paging collapses at bounds and survives resize',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1000, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final widget = calendar(visibleMonths: 2, lastDate: DateTime(2024, 5, 20));
    await tester.pumpWidget(host(widget, width: 900));
    expect(day(3, 10), findsOneWidget);
    expect(day(4, 1), findsOneWidget);
    await tester.drag(pager, const Offset(-700, 0));
    await tester.pumpAndSettle();
    expect(find.text('April 2024'), findsOneWidget);
    expect(find.text('May 2024'), findsOneWidget);
    await tester.pumpWidget(host(widget, width: 360));
    await tester.pumpAndSettle();
    expect(day(4, 1), findsOneWidget);
    expect(day(5, 1), findsNothing);
    await tester.drag(pager, const Offset(-300, 0));
    await tester.pumpAndSettle();
    await tester.pumpWidget(host(widget, width: 900));
    await tester.pumpAndSettle();
    expect(day(5, 1), findsOneWidget);
    expect(tester.widget<IconButton>(next).onPressed, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Chinese swipe enters and leaves a leap month through the delegate',
      (tester) async {
    final changes = <DateTime>[];
    await tester.pumpWidget(host(GeneralCalendar(
      calendarDelegate: const ChineseCalendarDelegate(),
      firstDate: ChineseDateTime(2025, 6),
      lastDate: ChineseDateTime(2025, 8, 29),
      currentDate: ChineseDateTime(2025, 6),
      onDisplayedMonthChanged: changes.add,
    )));
    await tester.drag(pager, const Offset(-320, 0));
    await tester.pumpAndSettle();
    expect(find.text('Leap Month 6 2025'), findsOneWidget);
    expect(changes.single, isA<ChineseDateTime>());
    expect((changes.single as ChineseDateTime).isLeapMonth, isTrue);
    await tester.drag(pager, const Offset(-320, 0));
    await tester.pumpAndSettle();
    expect((changes.last as ChineseDateTime).monthCode, 'M07');
    expect(tester.takeException(), isNull);
  });
}
