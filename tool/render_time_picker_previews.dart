// Actual public API screenshots; no mock time controls.
// flutter test tool/render_time_picker_previews.dart --dart-define=CALENDAR_PREVIEW_FONT=C:/Windows/Fonts/segoeui.ttf
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:general_calendar/general_calendar.dart';

void main() {
  const fontPath = String.fromEnvironment('CALENDAR_PREVIEW_FONT');
  testWidgets('render implemented time pickers', (tester) async {
    await tester.runAsync(() async {
      await (FontLoader('PreviewSans')
            ..addFont(File(fontPath).readAsBytes().then(ByteData.sublistView)))
          .load();
      await (FontLoader('MaterialIcons')
            ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
          .load();
    });
    const key = ValueKey('time-preview');
    final shadows = debugDisableShadows;
    Future<Uint8List> capture(String path) async =>
        (await tester.runAsync(() async {
          final boundary =
              tester.renderObject<RenderRepaintBoundary>(find.byKey(key));
          final image = await boundary.toImage(pixelRatio: 1);
          final data =
              (await image.toByteData(format: ui.ImageByteFormat.png))!;
          image.dispose();
          final bytes = data.buffer.asUint8List();
          await File(path).parent.create(recursive: true);
          await File(path).writeAsBytes(bytes);
          return bytes;
        }))!;
    debugDisableShadows = false;
    try {
      for (final brightness in Brightness.values) {
        final theme = ThemeData(
            brightness: brightness,
            fontFamily: 'PreviewSans',
            colorSchemeSeed: const Color(0xFF6750A4));
        final samples = <String, Uint8List>{};
        for (final name in [
          ...GeneralTimePickerView.values.map((v) => v.name),
          'combined'
        ]) {
          final combined = name == 'combined';
          final width = combined ? 840.0 : 400.0;
          await tester.binding.setSurfaceSize(Size(width + 32, 1000));
          await tester.pumpWidget(MaterialApp(
              theme: theme,
              home: Scaffold(
                body: Align(
                    alignment: Alignment.topLeft,
                    child: RepaintBoundary(
                      key: key,
                      child: ColoredBox(
                        color: theme.scaffoldBackgroundColor,
                        child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: SizedBox(
                              width: width,
                              child: combined
                                  ? GeneralDateTimePicker(
                                      key: ValueKey(
                                          'combined-${brightness.name}'),
                                      firstDate: DateTime(2024, 3),
                                      lastDate: DateTime(2024, 3, 31),
                                      initialDateTime:
                                          DateTime(2024, 3, 20, 14, 30),
                                      currentDate: DateTime(2024, 3, 20),
                                      design: GeneralCalendarDesign.shadcn,
                                      use24HourFormat: true,
                                      minuteInterval: 15,
                                    )
                                  : GeneralTimePicker(
                                      key: ValueKey('$name-${brightness.name}'),
                                      initialTime:
                                          const TimeOfDay(hour: 14, minute: 30),
                                      view: GeneralTimePickerView.values
                                          .firstWhere((v) => v.name == name),
                                      use24HourFormat: name != 'dial',
                                      minimumTime: TimeOfDay(
                                          hour: name == 'slots' ? 13 : 9,
                                          minute: 0),
                                      maximumTime:
                                          const TimeOfDay(hour: 17, minute: 0),
                                      minuteInterval: name == 'slots' ? 30 : 15,
                                      selectableTimePredicate: (time) =>
                                          time.hour != 15,
                                    ),
                            )),
                      ),
                    )),
              )));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          samples[name] =
              await capture('docs/images/time-$name-${brightness.name}.png');
        }
        final labels = [
          'Numeric input',
          'Clock dial',
          'Wheels',
          'Dropdown',
          'Appointment slots',
          'Date + time'
        ];
        await tester.binding.setSurfaceSize(const Size(1280, 1300));
        await tester.pumpWidget(MaterialApp(
            theme: theme,
            home: Scaffold(
              body: Align(
                  alignment: Alignment.topLeft,
                  child: RepaintBoundary(
                    key: key,
                    child: Container(
                      width: 1280,
                      padding: const EdgeInsets.all(24),
                      color: theme.scaffoldBackgroundColor,
                      child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                'General Calendar · time pickers · ${brightness.name}',
                                style: theme.textTheme.headlineMedium),
                            const SizedBox(height: 8),
                            Text(
                                'Implemented Flutter widgets — shared rules, styles, and calendar-safe date-time selection',
                                style: theme.textTheme.titleMedium),
                            const SizedBox(height: 24),
                            Wrap(spacing: 16, runSpacing: 24, children: [
                              for (var i = 0; i < samples.length; i++)
                                SizedBox(
                                    width: 400,
                                    height: 420,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(labels[i],
                                            style: theme.textTheme.titleMedium),
                                        const SizedBox(height: 12),
                                        Expanded(
                                            child: Align(
                                                alignment: Alignment.topLeft,
                                                child: Image.memory(
                                                    samples.values.elementAt(i),
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
        await capture('docs/images/time-pickers-${brightness.name}.png');
      }
    } finally {
      debugDisableShadows = shadows;
      await tester.binding.setSurfaceSize(null);
    }
  }, skip: fontPath.isEmpty);
}
