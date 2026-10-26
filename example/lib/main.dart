import 'package:flutter/material.dart';
import 'package:general_calendar/general_calendar.dart';
import 'package:general_datetime/default_localizations.dart';
import 'package:general_datetime/delegates.dart';
import 'package:general_datetime/general_datetime.dart';

import 'appointment_example.dart';
import 'demo_data.dart';
import 'demo_dropdown.dart';
import 'design_gallery.dart';

void main() => runApp(const CalendarExample());

enum _Calendar { gregorian, persian, hijri, hebrew }

class CalendarExample extends StatefulWidget {
  const CalendarExample({super.key, this.now});

  /// Injectable clock keeps the example and its tests reproducible.
  final DateTime Function()? now;

  @override
  State<CalendarExample> createState() => _CalendarExampleState();
}

class _CalendarExampleState extends State<CalendarExample> {
  late final DateTime _instant = widget.now?.call() ?? DateTime.now();
  _Calendar _calendar = _Calendar.gregorian;
  CalendarSelectionMode _mode = CalendarSelectionMode.single;
  GeneralCalendarDesign _design = GeneralCalendarDesign.material;
  GeneralCalendarView _initialView = GeneralCalendarView.month;
  bool _darkMode = false;
  bool _rtl = false;
  bool _readOnly = false;
  bool _adjacentDays = false;
  bool _blockFridays = true;
  bool _futureOnly = false;
  bool _allowDisabledInRange = false;
  bool _customDays = false;
  bool _customTheme = false;
  bool _twoMonths = false;
  bool _fridayWeekend = false;
  int? _firstDayOfWeek;
  int _maxDates = 5;
  int _revision = 0;
  GeneralTimePickerView _timeView = GeneralTimePickerView.input;
  bool _use24Hours = true;
  bool _showUnavailable = true;
  TimeOfDay? _time = DemoData.initialTime;
  String _selection = 'Choose a date';
  String _dialogSelection = 'No dialog result yet';
  DateTime? _inspectedDate;
  final List<String> _events = [];

  CalendarDelegate<DateTime> get _delegate => switch (_calendar) {
        _Calendar.gregorian => const GregorianCalendarDelegate(),
        _Calendar.persian => const PersianCalendarDelegate(),
        _Calendar.hijri => const HijriCalendarDelegate(),
        _Calendar.hebrew => const HebrewCalendarDelegate(),
      };

  // Convert the instant explicitly before passing any dates to a new delegate.
  // Never reconstruct a custom calendar date with DateTime(year, month, day).
  DateTime get _today => _delegate.dateOnly(switch (_calendar) {
        _Calendar.gregorian => _instant,
        _Calendar.persian => PersianDateTime.fromDateTime(_instant),
        _Calendar.hijri => HijriDateTime.fromDateTime(_instant),
        _Calendar.hebrew => HebrewDateTime.fromDateTime(_instant),
      });

  CalendarDateAttributes _attributes(DateTime date) =>
      DemoData.attributes(date, blockFridays: _blockFridays);

  bool _selectableDay(DateTime date) => !_futureOnly || !date.isBefore(_today);

  Set<int> get _weekends => _fridayWeekend
      ? const {DateTime.friday}
      : const {DateTime.saturday, DateTime.sunday};

  GeneralCalendarThemeData? get _theme => _customTheme
      ? const GeneralCalendarThemeData(
          selectedDayColor: Colors.deepPurple,
          selectedDayForegroundColor: Colors.white,
          todayColor: Colors.deepPurple,
          dayRadius: 8,
          showBorder: true,
        )
      : null;

  void _record(String event) {
    _events.insert(0, event);
    if (_events.length > 8) _events.removeLast();
  }

  // Initial values seed widget state. Changing its key intentionally clears
  // selection and returns to the configured starting view/current month.
  void _resetCalendar() {
    _revision++;
    _selection = 'Choose a date';
    _inspectedDate = null;
  }

  void _changeRules(VoidCallback change) => setState(() {
        change();
        _resetCalendar();
        _record('Rules changed; calendar selection reset');
      });

  void _selectionChanged(CalendarSelection selection) => setState(() {
        if (selection.mode == CalendarSelectionMode.range) {
          final start = selection.rangeStart;
          _selection = start == null
              ? 'Choose a date'
              : '${DemoData.dateLabel(start)} — '
                  '${selection.rangeEnd == null ? 'Choose end' : DemoData.dateLabel(selection.rangeEnd!)}';
          _inspectedDate = selection.rangeEnd ?? start;
        } else {
          _selection = selection.dates.isEmpty
              ? 'Choose a date'
              : selection.dates.map(DemoData.dateLabel).join(', ');
          _inspectedDate =
              selection.dates.isEmpty ? null : selection.dates.last;
        }
        _record('onSelectionChanged: $_selection');
      });

  Widget _toggle(String title, bool value, ValueChanged<bool> onChanged,
          {String? subtitle, Key? key}) =>
      SwitchListTile(
        key: key,
        contentPadding: EdgeInsets.zero,
        title: Text(title),
        subtitle: subtitle == null ? null : Text(subtitle),
        value: value,
        onChanged: onChanged,
      );

  Widget _calendarOptions() => ExpansionTile(
        key: const ValueKey('calendar-options'),
        tilePadding: EdgeInsets.zero,
        title: const Text('Calendar options'),
        subtitle: const Text('Views, rules, custom cells, and week layout'),
        children: [
          DemoDropdown<GeneralCalendarView>(
            label: 'Starting view',
            value: _initialView,
            items: [
              for (final view in GeneralCalendarView.values)
                DropdownMenuItem(value: view, child: Text(view.name)),
            ],
            onChanged: (value) => _changeRules(() => _initialView = value!),
          ),
          const SizedBox(height: 12),
          DemoDropdown<int>(
            label: 'First day of week',
            value: _firstDayOfWeek ?? 0,
            items: const [
              DropdownMenuItem(value: 0, child: Text('Follow locale')),
              DropdownMenuItem(value: DateTime.monday, child: Text('Monday')),
              DropdownMenuItem(
                  value: DateTime.saturday, child: Text('Saturday')),
              DropdownMenuItem(value: DateTime.sunday, child: Text('Sunday')),
            ],
            onChanged: (value) =>
                setState(() => _firstDayOfWeek = value == 0 ? null : value),
          ),
          const SizedBox(height: 12),
          DemoDropdown<int>(
            label: 'Maximum dates in multiple selection',
            value: _maxDates,
            items: [
              for (final count in [3, 5, 10])
                DropdownMenuItem(value: count, child: Text('$count dates')),
            ],
            onChanged: (value) => _changeRules(() => _maxDates = value!),
          ),
          _toggle('Disable Fridays', _blockFridays,
              (value) => _changeRules(() => _blockFridays = value)),
          _toggle('Only today and later', _futureOnly,
              (value) => _changeRules(() => _futureOnly = value),
              subtitle: 'An additional selectableDayPredicate rule.'),
          _toggle('Allow disabled days inside ranges', _allowDisabledInRange,
              (value) => _changeRules(() => _allowDisabledInRange = value),
              subtitle: 'Range endpoints must still be available.'),
          _toggle('Read only', _readOnly,
              (value) => setState(() => _readOnly = value),
              key: const ValueKey('read-only'),
              subtitle: 'Keep navigation available; prevent selection.'),
          _toggle('Show adjacent month days', _adjacentDays,
              (value) => setState(() => _adjacentDays = value)),
          _toggle('Friday weekend', _fridayWeekend,
              (value) => setState(() => _fridayWeekend = value),
              subtitle: 'Weekend styling is independent of disabled dates.'),
          _toggle('Two month panels', _twoMonths,
              (value) => setState(() => _twoMonths = value),
              subtitle: 'Automatically collapses to one on narrow screens.'),
          _toggle('Show availability in custom day cells', _customDays,
              (value) => setState(() => _customDays = value),
              key: const ValueKey('custom-day-cells')),
          _toggle('Purple theme overrides', _customTheme,
              (value) => setState(() => _customTheme = value)),
          _toggle('Preview right-to-left layout', _rtl,
              (value) => setState(() => _rtl = value),
              subtitle:
                  'Layout preview with English labels, not a translation.'),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final delegate = _delegate;
    final today = _today;
    final first = delegate.getMonth(today.year - 1, 1);
    final last = delegate.addDaysToDate(
      delegate.getMonth(today.year + 2, 1),
      -1,
    );
    return MaterialApp(
      title: 'General Calendar',
      theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
      darkTheme: ThemeData(
          colorSchemeSeed: Colors.teal,
          brightness: Brightness.dark,
          useMaterial3: true),
      themeMode: _darkMode ? ThemeMode.dark : ThemeMode.light,
      // Install exactly one matching chronology localization. These adapters
      // supply English calendar labels. See README for multilingual adapters.
      localizationsDelegates: [
        if (_calendar == _Calendar.persian)
          DefaultPersianCalendarMaterialLocalizations.delegate,
        if (_calendar == _Calendar.hijri)
          DefaultHijriCalendarMaterialLocalizations.delegate,
        if (_calendar == _Calendar.hebrew)
          DefaultHebrewCalendarMaterialLocalizations.delegate,
      ],
      builder: (context, child) => Directionality(
        textDirection: _rtl ? TextDirection.rtl : TextDirection.ltr,
        child: child!,
      ),
      home: Scaffold(
        appBar: AppBar(title: const Text('General Calendar')),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Explore calendars, selection, availability, and time input. '
                    'All rules below are sample application data.',
                  ),
                  const SizedBox(height: 12),
                  DropdownButton<_Calendar>(
                    key: const ValueKey('calendar-system'),
                    value: _calendar,
                    isExpanded: true,
                    hint: const Text('Calendar'),
                    items: [
                      for (final value in _Calendar.values)
                        DropdownMenuItem(value: value, child: Text(value.name)),
                    ],
                    onChanged: (value) => setState(() {
                      _calendar = value!;
                      _resetCalendar();
                      _dialogSelection = 'No dialog result yet';
                      _events.clear();
                    }),
                  ),
                  DropdownButton<CalendarSelectionMode>(
                    key: const ValueKey('calendar-selection-mode'),
                    value: _mode,
                    isExpanded: true,
                    hint: const Text('Selection'),
                    items: [
                      for (final value in CalendarSelectionMode.values)
                        DropdownMenuItem(value: value, child: Text(value.name)),
                    ],
                    onChanged: (value) => setState(() {
                      _mode = value!;
                      _resetCalendar();
                    }),
                  ),
                  DropdownButton<GeneralCalendarDesign>(
                    key: const ValueKey('calendar-design'),
                    isExpanded: true,
                    value: _design,
                    items: [
                      for (final design in GeneralCalendarDesign.values)
                        DropdownMenuItem(
                            value: design, child: Text(design.label)),
                    ],
                    onChanged: (value) => setState(() => _design = value!),
                  ),
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    children: [
                      Row(mainAxisSize: MainAxisSize.min, children: [
                        const Text('Dark mode'),
                        Switch(
                            value: _darkMode,
                            onChanged: (value) =>
                                setState(() => _darkMode = value)),
                      ]),
                      Builder(
                        builder: (context) => TextButton(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (context) => CalendarDesignGallery(
                                firstDate: first,
                                lastDate: last,
                                currentDate: today,
                                calendarDelegate: delegate,
                                dateAttributes: _attributes,
                              ),
                            ),
                          ),
                          child: const Text('Compare styles'),
                        ),
                      ),
                    ],
                  ),
                  _calendarOptions(),
                  GeneralCalendarTheme(
                    // Inherited overrides compose with the selected design.
                    data: _theme ?? const GeneralCalendarThemeData(),
                    child: GeneralCalendar(
                      key: ValueKey('$_calendar-$_mode-$_revision'),
                      design: _design,
                      firstDate: first,
                      lastDate: last,
                      currentDate: today,
                      initialDisplayedDate: today,
                      initialView: _initialView,
                      calendarDelegate: delegate,
                      selectionMode: _mode,
                      maxSelectedDates: _maxDates,
                      dateAttributes: _attributes,
                      selectableDayPredicate: _selectableDay,
                      firstDayOfWeek: _firstDayOfWeek,
                      weekendDays: _weekends,
                      readOnly: _readOnly,
                      showAdjacentMonthDays: _adjacentDays,
                      allowDisabledDatesInRange: _allowDisabledInRange,
                      visibleMonths: _twoMonths ? 2 : 1,
                      dayBuilder: _customDays
                          ? (context, day) => DemoData.availabilityDay(
                              context, day,
                              theme: _design
                                  .resolve(Theme.of(context))
                                  .merge(_theme))
                          : null,
                      // Widget-level overrides layer over the inherited theme.
                      theme: _customDays
                          ? const GeneralCalendarThemeData(dayHeight: 72)
                          : null,
                      onSelectionChanged: _selectionChanged,
                      onDisplayedMonthChanged: (date) => setState(() => _record(
                          'onDisplayedMonthChanged: ${DemoData.dateLabel(date)}')),
                      onViewChanged: (view) => setState(
                          () => _record('onViewChanged: ${view.name}')),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(_selection, key: const ValueKey('calendar-result')),
                  if (_inspectedDate != null)
                    Text(
                      'Type: ${_inspectedDate.runtimeType} · '
                      'Places: ${_attributes(_inspectedDate!).metadata['availablePlaces']} · '
                      'Demo price: USD ${_attributes(_inspectedDate!).metadata['price']}',
                      key: const ValueKey('selected-date-details'),
                    ),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton.icon(
                      key: const ValueKey('reset-calendar'),
                      onPressed: () => setState(() {
                        _resetCalendar();
                        _record('Calendar reset');
                      }),
                      icon: const Icon(Icons.restart_alt),
                      label: const Text('Reset calendar'),
                    ),
                  ),
                  const Text(
                    'Day 1 is a holiday; days 10–12 are vacation. Day 15 has a '
                    'meeting tag; multiples of 7 have a workshop. Holidays, '
                    'vacation, and zero places are descriptive; only the '
                    'configured rules disable selection. Multiple selection '
                    'toggles dates; ranges include both endpoints.',
                  ),
                  const SizedBox(height: 24),
                  Builder(
                      builder: (context) => _dialogButtons(
                          context, delegate, today, first, last)),
                  const SizedBox(height: 12),
                  Text(_dialogSelection, key: const ValueKey('dialog-result')),
                  const Divider(height: 40),
                  Builder(builder: (context) => _timeExample(context)),
                  const SizedBox(height: 24),
                  Builder(
                    builder: (context) => OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (context) => AppointmentExample(
                            firstDate: first,
                            lastDate: last,
                            currentDate: today,
                            calendarDelegate: delegate,
                            design: _design,
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.event_available),
                      label: const Text('Open appointment example'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ExpansionTile(
                    key: const ValueKey('callback-log'),
                    tilePadding: EdgeInsets.zero,
                    title: const Text('Callback log'),
                    subtitle: const Text('Most recent eight calendar events'),
                    children: [
                      if (_events.isEmpty)
                        const ListTile(
                            title: Text(
                                'Interact with the calendar to see events.')),
                      for (final event in _events)
                        ListTile(dense: true, title: Text(event)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _dialogButtons(
      BuildContext context,
      CalendarDelegate<DateTime> delegate,
      DateTime today,
      DateTime first,
      DateTime last) {
    Widget dialogBuilder(BuildContext context, Widget? child) =>
        GeneralCalendarTheme(
          data: _theme ?? const GeneralCalendarThemeData(),
          child: Directionality(
            textDirection: _rtl ? TextDirection.rtl : TextDirection.ltr,
            child: child!,
          ),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Picker dialogs', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        const Text('Dialogs share the active calendar, style, and date rules. '
            'Cancel leaves the last confirmed result unchanged.'),
        const SizedBox(height: 12),
        Wrap(spacing: 12, runSpacing: 8, children: [
          FilledButton(
            onPressed: () async {
              final result = await showGeneralDatePicker(
                context: context,
                firstDate: first,
                lastDate: last,
                currentDate: today,
                calendarDelegate: delegate,
                design: _design,
                dateAttributes: _attributes,
                selectableDayPredicate: _selectableDay,
                firstDayOfWeek: _firstDayOfWeek,
                weekendDays: _weekends,
                visibleMonths: _twoMonths ? 2 : 1,
                builder: dialogBuilder,
              );
              if (result != null && mounted) {
                setState(() => _dialogSelection = DemoData.dateLabel(result));
              }
            },
            child: const Text('Open date picker'),
          ),
          OutlinedButton(
            onPressed: () async {
              final result = await showGeneralDateRangePicker(
                context: context,
                firstDate: first,
                lastDate: last,
                currentDate: today,
                calendarDelegate: delegate,
                design: _design,
                dateAttributes: _attributes,
                selectableDayPredicate: _selectableDay,
                firstDayOfWeek: _firstDayOfWeek,
                weekendDays: _weekends,
                allowDisabledDatesInRange: _allowDisabledInRange,
                visibleMonths: _twoMonths ? 2 : 1,
                helpText: 'Choose an inclusive date range',
                builder: dialogBuilder,
              );
              if (result != null && mounted) {
                setState(() => _dialogSelection =
                    '${DemoData.dateLabel(result.start)} — ${DemoData.dateLabel(result.end)}');
              }
            },
            child: const Text('Open range picker'),
          ),
          FilledButton(
            onPressed: () async {
              final result = await showGeneralDateTimePicker(
                context: context,
                firstDate: first,
                lastDate: last,
                currentDate: today,
                initialTime: _time ?? DemoData.initialTime,
                calendarDelegate: delegate,
                dateAttributes: _attributes,
                selectableDayPredicate: _selectableDay,
                firstDayOfWeek: _firstDayOfWeek,
                design: _design,
                timeView: _timeView,
                minuteInterval: 15,
                minimumTime: DemoData.openingTime,
                maximumTime: DemoData.closingTime,
                selectableDateTimePredicate: DemoData.isAppointmentTime,
                use24HourFormat: _use24Hours,
                builder: dialogBuilder,
              );
              if (result != null && mounted) {
                setState(
                    () => _dialogSelection = DemoData.dateTimeLabel(result));
              }
            },
            child: const Text('Open date & time picker'),
          ),
        ]),
      ],
    );
  }

  Widget _timeExample(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Time pickers', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          const Text('09:00–17:00 in 15-minute steps; lunch at 12:00–12:59 '
              'is unavailable. Try 12:30 or an incomplete input to see validation.'),
          DropdownButton<GeneralTimePickerView>(
            key: const ValueKey('time-picker-view'),
            value: _timeView,
            isExpanded: true,
            items: [
              for (final view in GeneralTimePickerView.values)
                DropdownMenuItem(value: view, child: Text(view.name)),
            ],
            onChanged: (value) => setState(() => _timeView = value!),
          ),
          ExpansionTile(
            key: const ValueKey('time-options'),
            tilePadding: EdgeInsets.zero,
            title: const Text('Time options'),
            children: [
              _toggle('24-hour clock', _use24Hours,
                  (value) => setState(() => _use24Hours = value)),
              _toggle('Show unavailable slots', _showUnavailable,
                  (value) => setState(() => _showUnavailable = value)),
            ],
          ),
          GeneralTimePicker(
            initialTime: DemoData.initialTime,
            view: _timeView,
            design: _design,
            theme: _theme,
            minuteInterval: 15,
            use24HourFormat: _use24Hours,
            showUnavailableTimes: _showUnavailable,
            minimumTime: DemoData.openingTime,
            maximumTime: DemoData.closingTime,
            selectableTimePredicate: DemoData.isOfficeTime,
            onSelectionChanged: (value) => setState(() => _time = value),
          ),
          const SizedBox(height: 8),
          Text(
            _time == null
                ? 'Choose an available time'
                : DemoData.timeLabel(_time!),
            key: const ValueKey('time-result'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () async {
              final result = await showGeneralTimePicker(
                context: context,
                initialTime: _time ?? DemoData.initialTime,
                view: _timeView,
                design: _design,
                theme: _theme,
                minuteInterval: 15,
                use24HourFormat: _use24Hours,
                showUnavailableTimes: _showUnavailable,
                minimumTime: DemoData.openingTime,
                maximumTime: DemoData.closingTime,
                selectableTimePredicate: DemoData.isOfficeTime,
              );
              if (result != null && mounted) {
                // The inline input owns its draft; dialog confirmation has its
                // own output so it does not falsely update the inline fields.
                setState(() => _dialogSelection = DemoData.timeLabel(result));
              }
            },
            child: const Text('Open time picker'),
          ),
        ],
      );
}
