import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:general_calendar/general_calendar.dart';

const _capture = ValueKey('calendar-capture');
final _pager = find.byKey(const ValueKey('general-calendar-month-pager'));
Finder _day(int month, int day) =>
    find.byKey(ValueKey('general-calendar-day-2024-$month-$day'));

Widget _host(Widget child,
        {double width = 400,
        double scale = 1,
        TextDirection direction = TextDirection.ltr}) =>
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: width,
              child: MediaQuery(
                data: MediaQueryData(textScaler: TextScaler.linear(scale)),
                child: Directionality(
                  textDirection: direction,
                  child: RepaintBoundary(key: _capture, child: child),
                ),
              ),
            ),
          ),
        ),
      ),
    );

void main() {
  testWidgets('day ink stays inside the month viewport while paging',
      (tester) async {
    await tester.pumpWidget(_host(GeneralCalendar(
      firstDate: DateTime(2024, 3),
      lastDate: DateTime(2024, 5, 31),
      currentDate: DateTime(2024, 3, 20),
      theme: const GeneralCalendarThemeData(
        surfaceColor: Colors.white,
        dayInset: 0,
        dayRadius: 0,
      ),
      dateAttributes: (_) =>
          CalendarDateAttributes(backgroundColor: Colors.red),
    )));
    await tester.tap(find.byKey(const ValueKey('general-calendar-next')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    final rect = tester.getRect(_pager);
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(_capture),
    );
    final bytes = await tester.runAsync(() async {
      final image = await boundary.toImage();
      final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      image.dispose();
      return data!;
    });
    // These pixels belong to the surface padding, outside the PageView clip.
    for (final x in [rect.left - 2, rect.right + 2]) {
      final offset = ((rect.top + 56).floor() * 400 + x.floor()) * 4;
      expect(bytes!.buffer.asUint8List().sublist(offset, offset + 4),
          [255, 255, 255, 255]);
    }
    await tester.pumpAndSettle();
  });

  for (final direction in TextDirection.values) {
    testWidgets('two-month headings align with their panels, $direction',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(_host(
        GeneralCalendar(
          firstDate: DateTime(2024, 3),
          lastDate: DateTime(2024, 5, 31),
          currentDate: DateTime(2024, 3, 20),
          design: GeneralCalendarDesign.booking,
        ),
        width: 900,
        direction: direction,
      ));
      for (final (month, title) in [(3, 'March 2024'), (4, 'April 2024')]) {
        // March 6 and April 3 are the middle weekday column.
        final centerDay = month == 3 ? 6 : 3;
        expect(tester.getCenter(find.text(title)).dx,
            closeTo(tester.getCenter(_day(month, centerDay)).dx, 1));
      }
    });
  }

  testWidgets('event labels fit with custom line heights and text scaling',
      (tester) async {
    for (final scale in [1.0, 1.2, 1.5, 2.0, 2.5]) {
      await tester.pumpWidget(_host(
        GeneralCalendar(
          firstDate: DateTime(2024, 3),
          lastDate: DateTime(2024, 3, 31),
          currentDate: DateTime(2024, 3, 20),
          design: GeneralCalendarDesign.eventGrid,
          theme: const GeneralCalendarThemeData(
            dayHeight: 64,
            dayTextStyle: TextStyle(fontSize: 14, height: 2),
          ),
          dateAttributes: (date) => CalendarDateAttributes(
            tags: date.day == 4
                ? const [
                    CalendarTag(label: 'Planning'),
                    CalendarTag(label: 'Release'),
                    CalendarTag(label: 'Review'),
                  ]
                : const [],
          ),
        ),
        scale: scale,
      ));
      expect(tester.takeException(), isNull, reason: 'text scale $scale');
    }
  });

  testWidgets('event cells reserve space to report hidden labels',
      (tester) async {
    await tester.pumpWidget(_host(GeneralCalendar(
      firstDate: DateTime(2024, 3),
      lastDate: DateTime(2024, 3, 31),
      currentDate: DateTime(2024, 3, 20),
      design: GeneralCalendarDesign.eventGrid,
      theme: const GeneralCalendarThemeData(dayHeight: 64),
      dateAttributes: (date) => CalendarDateAttributes(
        tags: date.day == 4
            ? const [
                CalendarTag(label: 'Planning'),
                CalendarTag(label: 'Release'),
                CalendarTag(label: 'Review'),
              ]
            : const [],
      ),
    )));
    expect(find.text('+3'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final range in [false, true]) {
    testWidgets('dialog rechecks availability on confirmation, range=$range',
        (tester) async {
      var available = true;
      Object? result;
      await tester.pumpWidget(_host(Builder(builder: (context) {
        return TextButton(
          onPressed: () async {
            if (range) {
              result = await showGeneralDateRangePicker(
                context: context,
                firstDate: DateTime(2024, 3),
                lastDate: DateTime(2024, 3, 31),
                initialDateRange: DateTimeRange(
                  start: DateTime(2024, 3, 4),
                  end: DateTime(2024, 3, 6),
                ),
                selectableDayPredicate: (date) => available || date.day != 5,
              );
            } else {
              result = await showGeneralDatePicker(
                context: context,
                firstDate: DateTime(2024, 3),
                lastDate: DateTime(2024, 3, 31),
                initialDate: DateTime(2024, 3, 4),
                selectableDayPredicate: (_) => available,
              );
            }
          },
          child: const Text('Open'),
        );
      })));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      available = false;
      await tester.tap(find.widgetWithText(TextButton, 'OK'));
      await tester.pumpAndSettle();
      expect(result, isNull);
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(
        tester
            .widget<TextButton>(find.widgetWithText(TextButton, 'OK'))
            .onPressed,
        isNull,
      );
    });
  }
}
