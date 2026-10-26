// Render actual Flutter widgets, not HTML approximations. The font is loaded
// locally for legible screenshots and is never copied into this repository.
// flutter test tool/render_design_previews.dart --dart-define=CALENDAR_PREVIEW_FONT=C:/Windows/Fonts/segoeui.ttf
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:general_calendar/general_calendar.dart';

void main() {
  const fontPath = String.fromEnvironment('CALENDAR_PREVIEW_FONT');
  testWidgets('render calendar design previews', (tester) async {
    await tester.runAsync(() async {
      final loader = FontLoader('PreviewSans')
        ..addFont(File(fontPath).readAsBytes().then(ByteData.sublistView));
      await loader.load();
      await (FontLoader('MaterialIcons')
            ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
          .load();
    });
    final originalShadows = debugDisableShadows;
    debugDisableShadows = false;
    final previews = <Brightness, Map<GeneralCalendarDesign, Uint8List>>{};
    const captureKey = ValueKey('preview-capture');
    Future<Uint8List> capture(String path) async =>
        (await tester.runAsync(() async {
          final boundary = tester
              .renderObject<RenderRepaintBoundary>(find.byKey(captureKey));
          final image = await boundary.toImage(pixelRatio: 1);
          final data =
              (await image.toByteData(format: ui.ImageByteFormat.png))!;
          final bytes = data.buffer.asUint8List();
          image.dispose();
          final file = File(path);
          await file.parent.create(recursive: true);
          await file.writeAsBytes(bytes);
          return bytes;
        }))!;
    for (final brightness in Brightness.values) {
      final samples = <GeneralCalendarDesign, Uint8List>{};
      previews[brightness] = samples;
      final theme = ThemeData(
          brightness: brightness,
          fontFamily: 'PreviewSans',
          colorSchemeSeed: const Color(0xFF6750A4));
      for (final design in GeneralCalendarDesign.values) {
        final width = design == GeneralCalendarDesign.booking ? 840.0 : 400.0;
        await tester.binding.setSurfaceSize(Size(width + 32, 1100));
        await tester.pumpWidget(MaterialApp(
            theme: theme,
            home: Scaffold(
              body: Align(
                  alignment: Alignment.topLeft,
                  child: RepaintBoundary(
                    key: captureKey,
                    child: ColoredBox(
                      color: theme.scaffoldBackgroundColor,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: SizedBox(
                            width: width,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                GeneralCalendar(
                                  key: ValueKey(
                                      '${design.name}-${brightness.name}'),
                                  design: design,
                                  firstDate: DateTime(2024, 1),
                                  lastDate: DateTime(2024, 12, 31),
                                  currentDate: DateTime(2024, 3, 20),
                                  initialDisplayedDate: DateTime(2024, 3),
                                  selectionMode: CalendarSelectionMode.range,
                                  initialDateRange: DateTimeRange(
                                      start: DateTime(2024, 3, 10),
                                      end: DateTime(2024, 3, 14)),
                                  dateAttributes: (date) =>
                                      CalendarDateAttributes(
                                    isDisabled: date.day == 8,
                                    isHoliday: date.day == 21,
                                    isVacation:
                                        date.day == 25 || date.day == 26,
                                    tags: date.day == 18
                                        ? const [
                                            CalendarTag(
                                                label: 'Planning',
                                                color: Color(0xFF1D4ED8)),
                                            CalendarTag(
                                                label: 'Release',
                                                color: Color(0xFF7E22CE)),
                                            CalendarTag(label: 'Review'),
                                          ]
                                        : const [],
                                  ),
                                ),
                              ],
                            )),
                      ),
                    ),
                  )),
            )));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        samples[design] =
            await capture('docs/images/${design.name}-${brightness.name}.png');
      }
      await tester.binding.setSurfaceSize(const Size(1280, 2400));
      await tester.pumpWidget(MaterialApp(
          theme: theme,
          home: Scaffold(
            body: Align(
                alignment: Alignment.topLeft,
                child: RepaintBoundary(
                  key: captureKey,
                  child: Container(
                    width: 1280,
                    padding: const EdgeInsets.all(24),
                    color: theme.scaffoldBackgroundColor,
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('General Calendar · ${brightness.name}',
                              style: theme.textTheme.headlineMedium),
                          const SizedBox(height: 8),
                          Text(
                              '10 design systems + booking range and event grid',
                              style: theme.textTheme.titleMedium),
                          const SizedBox(height: 24),
                          Wrap(spacing: 16, runSpacing: 16, children: [
                            for (final entry in samples.entries)
                              SizedBox(
                                  width: 400,
                                  height: 460,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(entry.key.label,
                                          style: theme.textTheme.titleMedium),
                                      const SizedBox(height: 8),
                                      Expanded(
                                          child: Align(
                                              alignment: Alignment.topLeft,
                                              child: Image.memory(entry.value,
                                                  fit: BoxFit.contain))),
                                    ],
                                  )),
                          ]),
                        ]),
                  ),
                )),
          )));
      await tester.pumpAndSettle();
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pump();
      await capture('docs/images/calendar-designs-${brightness.name}.png');
    }
    await tester.binding.setSurfaceSize(null);
    debugDisableShadows = originalShadows;
  }, skip: fontPath.isEmpty);
}
