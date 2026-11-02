import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:general_calendar/general_calendar.dart';

const _captureKey = ValueKey('range-capture');
const _selected = Color(0xFFFF0000);
const _range = Color(0xFF0000FF);
const _attribute = Color(0xFF00FF00);
final _selection = DateTimeRange(
  start: DateTime(2024, 3, 10),
  end: DateTime(2024, 3, 14),
);
Finder _day(int day, {int month = 3}) =>
    find.byKey(ValueKey('general-calendar-day-2024-$month-$day'));

Widget _host({
  double width = 400,
  double dayHeight = 48,
  bool seeded = true,
  bool attributes = false,
  int visibleMonths = 1,
  int? firstDayOfWeek,
  Brightness brightness = Brightness.light,
  GeneralCalendarThemeData? theme,
  GeneralCalendar? calendar,
  TextDirection direction = TextDirection.ltr,
  GeneralCalendarDesign design = GeneralCalendarDesign.booking,
}) =>
    MaterialApp(
      theme: ThemeData(brightness: brightness),
      home: Scaffold(
        body: SingleChildScrollView(
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: width,
              child: Directionality(
                textDirection: direction,
                child: RepaintBoundary(
                  key: _captureKey,
                  child: calendar ??
                      GeneralCalendar(
                        firstDate: DateTime(2024, 3),
                        lastDate: DateTime(2024, 5, 31),
                        currentDate: DateTime(2024, 3, 20),
                        initialDisplayedDate: DateTime(2024, 3),
                        initialDateRange: seeded ? _selection : null,
                        selectionMode: CalendarSelectionMode.range,
                        design: design,
                        visibleMonths: visibleMonths,
                        firstDayOfWeek: firstDayOfWeek,
                        theme: GeneralCalendarThemeData(
                          surfaceColor: Colors.white,
                          selectedDayColor: _selected,
                          rangeColor: _range,
                          dayHeight: dayHeight,
                          dayInset: 3,
                          todayIndicator: CalendarTodayIndicator.outline,
                        ).merge(theme),
                        dateAttributes: attributes
                            ? (date) => CalendarDateAttributes(
                                  backgroundColor:
                                      date.day == 12 ? _attribute : null,
                                  isVacation: date.day == 13,
                                )
                            : null,
                      ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

class _Pixels {
  _Pixels(this.bytes, this.width, this.origin, this.pixelRatio);
  final List<int> bytes;
  final int width;
  final Offset origin;
  final double pixelRatio;

  Color at(Offset point) {
    final local = (point - origin) * pixelRatio;
    final index = (local.dy.floor() * width + local.dx.floor()) * 4;
    return Color.fromARGB(
        bytes[index + 3], bytes[index], bytes[index + 1], bytes[index + 2]);
  }
}

Future<_Pixels> _capture(WidgetTester tester, String name,
    {double pixelRatio = 1}) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_captureKey),
  );
  final origin = boundary.localToGlobal(Offset.zero);
  return (await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: pixelRatio);
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    const reviewDir = String.fromEnvironment('RANGE_REVIEW_DIR');
    if (reviewDir.isNotEmpty) {
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File('$reviewDir/$name.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(png!.buffer.asUint8List());
    }
    final pixels =
        _Pixels(data!.buffer.asUint8List(), image.width, origin, pixelRatio);
    image.dispose();
    return pixels;
  }))!;
}

class _ReloadableMaterialLocalizations
    extends LocalizationsDelegate<MaterialLocalizations> {
  const _ReloadableMaterialLocalizations(this.revision);
  final int revision;

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'en';

  @override
  Future<MaterialLocalizations> load(Locale locale) =>
      SynchronousFuture<MaterialLocalizations>(DefaultMaterialLocalizations());

  @override
  bool shouldReload(_ReloadableMaterialLocalizations old) =>
      old.revision != revision;
}

void main() {
  testWidgets('range band stays seamless with translucent theme colors',
      (tester) async {
    for (final dark in [false, true]) {
      for (final width in [281.0, 320.0, 375.0, 400.0, 777.0]) {
        await tester.pumpWidget(_host(
          width: width,
          brightness: dark ? Brightness.dark : Brightness.light,
          theme: GeneralCalendarThemeData(
            surfaceColor: dark ? Colors.black : Colors.white,
            rangeColor: const Color(0x400000FF),
          ),
        ));
        for (final ratio in [1.0, 1.25, 1.5, 2.0, 3.0]) {
          final pixels = await _capture(
              tester, 'translucent-$dark-$width-$ratio',
              pixelRatio: ratio);
          final cell = tester.getRect(_day(11));
          final y = cell.center.dy - (cell.shortestSide - 6) / 2 + 2;
          final expected = pixels.at(Offset(cell.center.dx, y));
          for (var x = (cell.left * ratio).ceil() + 1;
              x < (tester.getRect(_day(13)).right * ratio).floor() - 1;
              x++) {
            expect(pixels.at(Offset((x + 0.01) / ratio, y)), expected,
                reason: 'range seam at width $width, ratio $ratio, x=$x');
          }
        }
      }
    }
  });

  testWidgets(
      'rule changes clear range paint and disabled interiors stay connected',
      (tester) async {
    var disabled = false;
    var allowDisabled = false;
    var readOnly = false;
    var callbacks = 0;
    Widget calendar() => _host(
            calendar: GeneralCalendar(
          firstDate: DateTime(2024, 3),
          lastDate: DateTime(2024, 3, 31),
          currentDate: DateTime(2024, 3, 20),
          initialDisplayedDate: DateTime(2024, 3),
          selectionMode: CalendarSelectionMode.range,
          allowDisabledDatesInRange: allowDisabled,
          readOnly: readOnly,
          selectableDayPredicate: (date) => !disabled || date.day != 12,
          onSelectionChanged: (_) => callbacks++,
          theme: const GeneralCalendarThemeData(
            surfaceColor: Colors.white,
            selectedDayColor: _selected,
            rangeColor: _range,
          ),
        ));
    await tester.pumpWidget(calendar());
    await tester.tap(_day(10));
    await tester.pumpAndSettle();
    await tester.tap(_day(14));
    await tester.pumpAndSettle();
    expect(callbacks, 2);
    disabled = true;
    await tester.pumpWidget(calendar());
    await tester.pumpAndSettle();
    final cleared = await _capture(tester, 'disabled-range-cleared');
    expect(tester.widget<Semantics>(_day(10)).properties.selected, isFalse);
    expect(cleared.at(tester.getCenter(_day(10)) + const Offset(6, 12)),
        Colors.white);
    expect(cleared.at(tester.getCenter(_day(11)) + const Offset(0, 12)),
        Colors.white);
    expect(callbacks, 2);
    allowDisabled = true;
    await tester.pumpWidget(calendar());
    await tester.tap(_day(10));
    await tester.pumpAndSettle();
    await tester.tap(_day(14));
    await tester.pumpAndSettle();
    final inclusive = await _capture(tester, 'disabled-interior-connected');
    expect(
        inclusive.at(tester.getCenter(_day(12)) + const Offset(0, 12)), _range);
    expect(tester.widget<Semantics>(_day(12)).properties.enabled, isFalse);
    expect(tester.widget<Semantics>(_day(12)).properties.selected, isTrue);
    readOnly = true;
    await tester.pumpWidget(calendar());
    await tester.tap(_day(18));
    await tester.pumpAndSettle();
    expect(tester.widget<Semantics>(_day(10)).properties.selected, isTrue);
    expect(callbacks, 4);
    expect(tester.takeException(), isNull);
  });

  testWidgets('range survives resize, week remapping and event-label changes',
      (tester) async {
    await tester.pumpWidget(_host(seeded: false));
    final state = tester.state(find.byType(GeneralCalendar));
    await tester.tap(_day(10));
    await tester.pumpAndSettle();
    await tester.tap(_day(14));
    await tester.pumpAndSettle();
    for (final events in [true, false, true, false]) {
      for (final width in [320.0, 400.0]) {
        await tester.pumpWidget(_host(
          seeded: false,
          width: width,
          firstDayOfWeek: events ? DateTime.monday : DateTime.sunday,
          brightness: events ? Brightness.dark : Brightness.light,
          theme: GeneralCalendarThemeData(
            surfaceColor: events ? Colors.black : Colors.white,
            showEventLabels: events,
          ),
        ));
        await tester.pumpAndSettle();
        expect(tester.state(find.byType(GeneralCalendar)), same(state));
        final pixels = await _capture(tester, 'remap-$events-$width');
        expect(pixels.at(tester.getCenter(_day(10)) + const Offset(4, 10)),
            _selected);
        expect(pixels.at(tester.getCenter(_day(14)) + const Offset(-4, 10)),
            _selected);
        expect(tester.takeException(), isNull);
      }
    }
  });

  testWidgets(
      'invalidated dialog ranges stay cleared when availability returns',
      (tester) async {
    var available = true;
    var revision = 0;
    late StateSetter refresh;
    await tester.pumpWidget(MaterialApp(
      home: Builder(
          builder: (context) => TextButton(
                onPressed: () => showGeneralDateRangePicker(
                  context: context,
                  firstDate: DateTime(2024, 3),
                  lastDate: DateTime(2024, 3, 31),
                  initialDateRange: _selection,
                  selectableDayPredicate: (_) => available,
                  builder: (context, child) => StatefulBuilder(
                    builder: (context, setState) {
                      refresh = setState;
                      return Localizations.override(
                        context: context,
                        delegates: [_ReloadableMaterialLocalizations(revision)],
                        child: child,
                      );
                    },
                  ),
                ),
                child: const Text('Open'),
              )),
    ));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    final confirm = find.widgetWithText(TextButton, 'OK');
    expect(tester.widget<Semantics>(_day(10)).properties.selected, isTrue);
    refresh(() {
      available = false;
      revision++;
    });
    await tester.pumpAndSettle();
    expect(tester.widget<Semantics>(_day(10)).properties.selected, isFalse);
    expect(tester.widget<TextButton>(confirm).onPressed, isNull);
    refresh(() {
      available = true;
      revision++;
    });
    await tester.pumpAndSettle();
    expect(tester.widget<Semantics>(_day(10)).properties.selected, isFalse);
    expect(tester.widget<TextButton>(confirm).onPressed, isNull,
        reason: 'a visually cleared range must not become confirmable again');
    await tester.tap(_day(10));
    await tester.pumpAndSettle();
    await tester.tap(_day(14));
    await tester.pumpAndSettle();
    expect(tester.widget<TextButton>(confirm).onPressed, isNotNull);
  });

  for (final design in GeneralCalendarDesign.values) {
    for (final direction in TextDirection.values) {
      testWidgets('${design.name} retains range endpoint fills, $direction',
          (tester) async {
        await tester.pumpWidget(_host(
          seeded: false,
          direction: direction,
          design: design,
        ));
        final forward = direction == TextDirection.ltr ? 1.0 : -1.0;
        for (final (first, second) in [(10, 14), (11, 9), (22, 22)]) {
          await tester.tap(_day(first));
          await tester.pumpAndSettle();
          await tester.tap(_day(second));
          await tester.pumpAndSettle();
          final pixels = await _capture(tester,
              'clicked-${design.name}-${direction.name}-$first-$second');
          final start = tester.getCenter(_day(first < second ? first : second));
          final end = tester.getCenter(_day(first > second ? first : second));
          expect(pixels.at(start + Offset(6 * forward, 12)), _selected);
          expect(pixels.at(end + Offset(-6 * forward, 12)), _selected);
          if (first == second) {
            for (final outside in [10, 21, 23]) {
              expect(
                  pixels.at(
                      tester.getCenter(_day(outside)) + const Offset(0, 12)),
                  Colors.white,
                  reason: 'old range and one-day tails cleared');
            }
          }
        }
      });
    }
  }

  for (final direction in TextDirection.values) {
    testWidgets('phone range dialog retains both endpoint fills, $direction',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      DateTimeRange<DateTime>? result;
      await tester.pumpWidget(MaterialApp(
        builder: (context, child) => Directionality(
          textDirection: direction,
          child: child!,
        ),
        home: Scaffold(body: Builder(builder: (context) {
          return TextButton(
            onPressed: () async {
              result = await showGeneralDateRangePicker(
                context: context,
                firstDate: DateTime(2024, 3),
                lastDate: DateTime(2024, 3, 31),
                currentDate: DateTime(2024, 3, 20),
                design: GeneralCalendarDesign.booking,
                theme: const GeneralCalendarThemeData(
                  selectedDayColor: _selected,
                  rangeColor: _range,
                ),
                builder: (context, child) => RepaintBoundary(
                  key: _captureKey,
                  child: child,
                ),
              );
            },
            child: const Text('Open'),
          );
        })),
      ));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(_day(10));
      await tester.pumpAndSettle();
      await tester.tap(_day(14));
      await tester.pumpAndSettle();
      final pixels = await _capture(tester, 'dialog-${direction.name}');
      final forward = direction == TextDirection.ltr ? 1.0 : -1.0;
      expect(pixels.at(tester.getCenter(_day(10)) + Offset(4 * forward, 10)),
          _selected);
      expect(pixels.at(tester.getCenter(_day(14)) + Offset(-4 * forward, 10)),
          _selected);
      await tester.tap(find.widgetWithText(TextButton, 'OK'));
      await tester.pumpAndSettle();
      expect(result, _selection);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'range endpoints paint correctly across two month panels, $direction',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(_host(
        width: 900,
        seeded: false,
        visibleMonths: 2,
        direction: direction,
      ));
      await tester.tap(_day(28));
      await tester.pumpAndSettle();
      await tester.tap(_day(3, month: 4));
      await tester.pumpAndSettle();
      final pixels = await _capture(tester, 'two-month-${direction.name}');
      final start = tester.getCenter(_day(28));
      final end = tester.getCenter(_day(3, month: 4));
      final forward = direction == TextDirection.ltr ? 1.0 : -1.0;
      expect(pixels.at(start + Offset(6 * forward, 12)), _selected);
      expect(pixels.at(end + Offset(-6 * forward, 12)), _selected);

      await tester.tap(find.byKey(const ValueKey('general-calendar-next')));
      await tester.pumpAndSettle();
      final paged = await _capture(tester, 'paged-${direction.name}');
      expect(
          paged.at(
              tester.getCenter(_day(3, month: 4)) + Offset(-6 * forward, 12)),
          _selected);
      expect(tester.takeException(), isNull);
    });

    for (final (width, height) in [(320.0, 48.0), (400.0, 80.0)]) {
      testWidgets(
          'range band matches endpoint height at $width/$height, $direction',
          (tester) async {
        await tester.pumpWidget(_host(
          width: width,
          dayHeight: height,
          direction: direction,
        ));
        final pixels =
            await _capture(tester, 'geometry-$width-$height-${direction.name}');
        final cell = tester.getRect(_day(11));
        final markerHeight = cell.shortestSide - 6;
        final bandTop = cell.center.dy - markerHeight / 2;
        // The connecting band must not protrude above or below the markers.
        expect(pixels.at(Offset(cell.center.dx, bandTop - 1)), Colors.white);
        expect(pixels.at(Offset(cell.center.dx, bandTop + 1)), _range);
        expect(
            pixels.at(
                Offset(cell.center.dx, cell.center.dy + markerHeight / 2 + 1)),
            Colors.white);
      });
    }
  }

  testWidgets('attribute backgrounds do not interrupt the selected range',
      (tester) async {
    await tester.pumpWidget(_host(attributes: true));
    final pixels = await _capture(tester, 'attributes');
    for (final day in [11, 12, 13]) {
      expect(
          pixels.at(tester.getCenter(_day(day)) + const Offset(0, 12)), _range,
          reason: 'day $day');
    }
    await tester.tap(_day(18));
    await tester.pumpAndSettle();
    final pending = await _capture(tester, 'attribute-restored');
    expect(pending.at(tester.getCenter(_day(12)) + const Offset(0, 12)),
        _attribute,
        reason: 'clearing the range restores date styling');
  });
}
