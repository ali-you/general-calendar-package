// Historical visual proposals. Actual public widgets: render_time_picker_previews.dart.
// flutter test tool/render_time_picker_options.dart --dart-define=CALENDAR_PREVIEW_FONT=C:/Windows/Fonts/segoeui.ttf
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:general_calendar/general_calendar.dart';

void main() {
  const fontPath = String.fromEnvironment('CALENDAR_PREVIEW_FONT');
  testWidgets('render time picker choices', (tester) async {
    await tester.runAsync(() async {
      await (FontLoader('PreviewSans')
            ..addFont(File(fontPath).readAsBytes().then(ByteData.sublistView)))
          .load();
      await (FontLoader('MaterialIcons')
            ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
          .load();
    });
    final previousShadows = debugDisableShadows;
    debugDisableShadows = false;
    try {
      await tester.binding.setSurfaceSize(const Size(1288, 2600));
      for (final brightness in Brightness.values) {
        await tester.pumpWidget(MaterialApp(
          theme: ThemeData(
              brightness: brightness,
              useMaterial3: true,
              fontFamily: 'PreviewSans',
              colorSchemeSeed: const Color(0xFF4F46E5)),
          home: Scaffold(
              body: SingleChildScrollView(
                  child: RepaintBoundary(
            key: const ValueKey('time-options-board'),
            child: Builder(
                builder: (context) => _OptionsBoard(brightness: brightness)),
          ))),
        ));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.runAsync(() async {
          for (final name in ['board', 'A', 'B', 'C', 'D', 'E', 'F']) {
            final key =
                name == 'board' ? 'time-options-board' : 'time-option-$name';
            final boundary = tester
                .renderObject<RenderRepaintBoundary>(find.byKey(ValueKey(key)));
            final image = await boundary.toImage(pixelRatio: 1);
            final data =
                (await image.toByteData(format: ui.ImageByteFormat.png))!;
            image.dispose();
            final filename = name == 'board'
                ? 'time-picker-options'
                : 'time-picker-option-$name';
            final file = File('docs/images/$filename-${brightness.name}.png');
            await file.parent.create(recursive: true);
            await file.writeAsBytes(data.buffer.asUint8List());
          }
        });
      }
    } finally {
      debugDisableShadows = previousShadows;
      await tester.binding.setSurfaceSize(null);
    }
  }, skip: fontPath.isEmpty);
}

class _OptionsBoard extends StatelessWidget {
  const _OptionsBoard({required this.brightness});
  final Brightness brightness;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      width: 1288,
      padding: const EdgeInsets.all(32),
      color: brightness == Brightness.light
          ? const Color(0xFFF3F5FA)
          : const Color(0xFF101218),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('GENERAL CALENDAR / DESIGN CHOICES',
            style: TextStyle(
                fontSize: 13,
                letterSpacing: 1.8,
                fontWeight: FontWeight.w600,
                color: colors.primary)),
        const SizedBox(height: 10),
        Text('Which time picker fits your package?',
            style: theme.textTheme.headlineLarge
                ?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text(
            'Six visual proposals. The same time is shown as 14:30 or 2:30 PM.',
            style: theme.textTheme.bodyLarge
                ?.copyWith(color: colors.onSurfaceVariant)),
        const SizedBox(height: 12),
        Text(
            'Suggested starting point: B for precise entry + F for date-and-time selection.',
            style: theme.textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 28),
        Wrap(spacing: 24, runSpacing: 24, children: [
          _card(
              context,
              'A',
              'Material dial',
              'Touch-first • 12-hour clock',
              _nativePicker(context, TimePickerEntryMode.dial, false),
              'Familiar on Android. Include a keyboard-entry alternative.'),
          _card(
              context,
              'B',
              'Numeric input',
              'Suggested default • precise 24-hour entry',
              _nativePicker(context, TimePickerEntryMode.input, true),
              'Fast for desktop, keyboard users, and exact appointment times.'),
          _card(
              context,
              'C',
              'iOS wheels',
              'Scroll hour and minute columns',
              _wheels(context),
              'A platform-oriented option for touch interfaces.'),
          _card(
              context,
              'D',
              'Dropdown list',
              'Compact form field • 15-minute steps',
              _dropdown(context),
              'Good for forms with a limited set of valid times.'),
          _card(
              context,
              'E',
              'Appointment slots',
              'Availability-first • 30-minute slots',
              _slots(context),
              'Users choose an available slot; blocked times stay visible.'),
          _card(
              context,
              'F',
              'Combined date + time',
              'Compose calendar and time • stack on phones',
              _combined(context),
              'Use for meetings, reminders, bookings, and delivery dates.'),
        ]),
        const SizedBox(height: 24),
        Text(
            'Design exploration — current time-picker APIs and screenshots are in docs/time-pickers.md.',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: colors.onSurfaceVariant)),
      ]),
    );
  }

  Widget _card(BuildContext context, String id, String title, String subtitle,
      Widget child, String note) {
    final colors = Theme.of(context).colorScheme;
    return RepaintBoundary(
        key: ValueKey('time-option-$id'),
        child: Container(
          width: 600,
          height: 640,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colors.outlineVariant)),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      color: colors.primaryContainer,
                      borderRadius: BorderRadius.circular(10)),
                  child: Text(id,
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: colors.onPrimaryContainer))),
              const SizedBox(width: 12),
              Text(title,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w600)),
            ]),
            const SizedBox(height: 8),
            Text(subtitle,
                style: TextStyle(fontSize: 14, color: colors.onSurfaceVariant)),
            const SizedBox(height: 12),
            Expanded(child: Center(child: child)),
            Divider(color: colors.outlineVariant),
            Text(note,
                style: TextStyle(
                    fontSize: 13, height: 1.4, color: colors.onSurfaceVariant)),
          ]),
        ));
  }

  Widget _nativePicker(
          BuildContext context, TimePickerEntryMode mode, bool is24Hour) =>
      MediaQuery(
          data: MediaQuery.of(context).copyWith(
              size: const Size(390, 844), alwaysUse24HourFormat: is24Hour),
          child: TimePickerDialog(
            initialTime: const TimeOfDay(hour: 14, minute: 30),
            initialEntryMode: mode,
            orientation: Orientation.portrait,
          ));

  Widget _wheels(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SizedBox(
        width: 420,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Select time', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 20),
          CupertinoTheme(
              data: CupertinoThemeData(
                  brightness: brightness,
                  primaryColor: colors.primary,
                  textTheme: CupertinoTextThemeData(
                      dateTimePickerTextStyle: TextStyle(
                          fontFamily: 'PreviewSans',
                          fontSize: 25,
                          color: colors.onSurface))),
              child: SizedBox(
                  height: 220,
                  child: CupertinoDatePicker(
                    initialDateTime: DateTime(2024, 3, 20, 14, 30),
                    mode: CupertinoDatePickerMode.time,
                    use24hFormat: true,
                    minuteInterval: 5,
                    onDateTimeChanged: (_) {},
                  ))),
          const SizedBox(height: 20),
          Text('14:30 · local time',
              style: TextStyle(fontSize: 16, color: colors.onSurfaceVariant)),
          const SizedBox(height: 20),
          FilledButton(onPressed: () {}, child: const Text('Done')),
        ]));
  }

  Widget _dropdown(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SizedBox(
        width: 360,
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Start time',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                      border: Border.all(color: colors.primary, width: 2),
                      borderRadius: BorderRadius.circular(8)),
                  child: const Row(children: [
                    Icon(Icons.schedule, size: 20),
                    SizedBox(width: 10),
                    Text('14:30', style: TextStyle(fontSize: 17)),
                    Spacer(),
                    Icon(Icons.expand_more)
                  ])),
              const SizedBox(height: 8),
              Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                      color: colors.surface,
                      border: Border.all(color: colors.outlineVariant),
                      borderRadius: BorderRadius.circular(10)),
                  child: Column(children: [
                    for (final time in [
                      '14:00',
                      '14:15',
                      '14:30',
                      '14:45',
                      '15:00'
                    ])
                      Container(
                          height: 48,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                              color: time == '14:30'
                                  ? colors.primaryContainer
                                  : null,
                              borderRadius: BorderRadius.circular(6)),
                          child: Row(children: [
                            Text(time,
                                style: TextStyle(
                                    fontSize: 16,
                                    color: time == '14:45'
                                        ? colors.onSurface
                                            .withValues(alpha: 0.38)
                                        : colors.onSurface)),
                            const Spacer(),
                            if (time == '14:30')
                              Icon(Icons.check,
                                  size: 18, color: colors.primary),
                            if (time == '14:45')
                              Text('Unavailable',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: colors.onSurfaceVariant)),
                          ])),
                  ])),
            ]));
  }

  Widget _slots(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    Widget section(String title, List<String> times) =>
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colors.onSurfaceVariant)),
          const SizedBox(height: 10),
          Wrap(spacing: 10, runSpacing: 10, children: [
            for (final time in times)
              SizedBox(
                  width: 140,
                  height: 48,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                        backgroundColor:
                            time == '14:30' ? colors.primary : null,
                        foregroundColor: time == '14:30'
                            ? colors.onPrimary
                            : colors.onSurface,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8))),
                    onPressed:
                        time == '10:00' || time == '15:00' ? null : () {},
                    child: Text(time, style: const TextStyle(fontSize: 16)),
                  )),
          ]),
        ]);
    return SizedBox(
        width: 440,
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Wednesday, 20 March',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              Text('30-minute appointments · local time',
                  style: TextStyle(color: colors.onSurfaceVariant)),
              const SizedBox(height: 24),
              section('Morning',
                  ['09:00', '09:30', '10:00', '10:30', '11:00', '11:30']),
              const SizedBox(height: 24),
              section('Afternoon',
                  ['13:00', '13:30', '14:00', '14:30', '15:00', '15:30']),
              const SizedBox(height: 20),
              Text('Selected: 14:30–15:00',
                  style: TextStyle(
                      color: colors.primary, fontWeight: FontWeight.w600)),
            ]));
  }

  Widget _combined(BuildContext context) =>
      Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        SizedBox(
            width: 340,
            child: GeneralCalendar(
              design: GeneralCalendarDesign.shadcn,
              firstDate: DateTime(2024, 3),
              lastDate: DateTime(2024, 3, 31),
              currentDate: DateTime(2024, 3, 20),
              initialDate: DateTime(2024, 3, 20),
              showViewSwitcher: false,
            )),
        const SizedBox(width: 16),
        Expanded(
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
              Text('20 March 2024',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 20),
              const Text('Time'),
              const SizedBox(height: 8),
              TextField(
                  readOnly: true,
                  controller: TextEditingController(text: '14:30'),
                  decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.schedule))),
              const SizedBox(height: 8),
              const Text('Local time', style: TextStyle(fontSize: 12)),
              const SizedBox(height: 24),
              FilledButton(onPressed: () {}, child: const Text('Confirm')),
            ])),
      ]);
}
