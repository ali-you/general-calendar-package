import 'package:flutter/material.dart';
import 'package:general_calendar/general_calendar.dart';
import 'package:general_datetime/default_localizations.dart';
import 'package:general_datetime/delegates.dart';
import 'package:general_datetime/general_datetime.dart';

void main() => runApp(const CalendarExample());

enum _Calendar { gregorian, persian, hijri, hebrew }

class CalendarExample extends StatefulWidget {
  const CalendarExample({super.key});

  @override
  State<CalendarExample> createState() => _CalendarExampleState();
}

class _CalendarExampleState extends State<CalendarExample> {
  final DateTime _instant = DateTime.now();
  _Calendar _calendar = _Calendar.gregorian;
  CalendarSelectionMode _mode = CalendarSelectionMode.single;
  String _selection = 'Choose a date';

  CalendarDelegate<DateTime> get _delegate => switch (_calendar) {
        _Calendar.gregorian => const GregorianCalendarDelegate(),
        _Calendar.persian => const PersianCalendarDelegate(),
        _Calendar.hijri => const HijriCalendarDelegate(),
        _Calendar.hebrew => const HebrewCalendarDelegate(),
      };

  DateTime get _today => switch (_calendar) {
        _Calendar.gregorian => _instant,
        _Calendar.persian => PersianDateTime.fromDateTime(_instant),
        _Calendar.hijri => HijriDateTime.fromDateTime(_instant),
        _Calendar.hebrew => HebrewDateTime.fromDateTime(_instant),
      };

  CalendarDateAttributes _attributes(DateTime date) => CalendarDateAttributes(
        isDisabled: date.weekday == DateTime.friday,
        isHoliday: date.day == 1,
        isVacation: date.day >= 10 && date.day <= 12,
        tags: date.day == 15
            ? const [CalendarTag(label: 'Team meeting', color: Colors.orange)]
            : const [],
        tooltip: date.weekday == DateTime.friday ? 'Closed on Fridays' : null,
        metadata: {'availablePlaces': date.day % 5},
      );

  String _dateLabel(DateTime date) => '${date.year}/${date.month}/${date.day}';

  @override
  Widget build(BuildContext context) {
    final delegate = _delegate;
    final today = delegate.dateOnly(_today);
    final first = delegate.getMonth(today.year - 1, 1);
    final last = delegate.addDaysToDate(
      delegate.getMonth(today.year + 2, 1),
      -1,
    );
    return MaterialApp(
      title: 'General Calendar',
      theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
      // These chronology localizations provide English labels. Applications can
      // use general_date_format's matching adapters for multilingual labels.
      localizationsDelegates: [
        if (_calendar == _Calendar.persian)
          DefaultPersianCalendarMaterialLocalizations.delegate,
        if (_calendar == _Calendar.hijri)
          DefaultHijriCalendarMaterialLocalizations.delegate,
        if (_calendar == _Calendar.hebrew)
          DefaultHebrewCalendarMaterialLocalizations.delegate,
      ],
      home: Scaffold(
        appBar: AppBar(title: const Text('General Calendar')),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                DropdownButton<_Calendar>(
                  value: _calendar,
                  hint: const Text('Calendar'),
                  items: [
                    for (final value in _Calendar.values)
                      DropdownMenuItem(value: value, child: Text(value.name)),
                  ],
                  onChanged: (value) => setState(() {
                    _calendar = value!;
                    _selection = 'Choose a date';
                  }),
                ),
                const SizedBox(height: 12),
                DropdownButton<CalendarSelectionMode>(
                  value: _mode,
                  hint: const Text('Selection'),
                  items: [
                    for (final value in CalendarSelectionMode.values)
                      DropdownMenuItem(value: value, child: Text(value.name)),
                  ],
                  onChanged: (value) => setState(() => _mode = value!),
                ),
                const SizedBox(height: 12),
                GeneralCalendar(
                  key: ValueKey('$_calendar-$_mode'),
                  firstDate: first,
                  lastDate: last,
                  currentDate: today,
                  initialDisplayedDate: today,
                  calendarDelegate: delegate,
                  selectionMode: _mode,
                  dateAttributes: _attributes,
                  onSelectionChanged: (selection) => setState(() {
                    _selection = selection.mode == CalendarSelectionMode.range
                        ? '${_dateLabel(selection.rangeStart!)} — '
                            '${selection.rangeEnd == null ? 'Choose end' : _dateLabel(selection.rangeEnd!)}'
                        : selection.dates.map(_dateLabel).join(', ');
                  }),
                ),
                const Divider(),
                Text(_selection),
                const SizedBox(height: 8),
                const Text(
                  'Fridays are disabled. Day 1 is a holiday; days 10–12 are '
                  'vacation. Day 15 has a meeting tag. These are demo rules.',
                ),
                const SizedBox(height: 16),
                Builder(
                  builder: (context) => FilledButton(
                    onPressed: () async {
                      final result = await showGeneralDatePicker(
                        context: context,
                        firstDate: first,
                        lastDate: last,
                        currentDate: today,
                        calendarDelegate: delegate,
                        dateAttributes: _attributes,
                      );
                      if (result != null && mounted) {
                        setState(() => _selection = _dateLabel(result));
                      }
                    },
                    child: const Text('Open date picker'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
