import 'package:flutter/material.dart';
import 'package:general_calendar/general_calendar.dart';

import 'demo_data.dart';
import 'demo_dropdown.dart';

/// A complete form: preserve the calendar type, invalidate unavailable drafts,
/// and enable the application action only when the picker returns a valid value.
class AppointmentExample extends StatefulWidget {
  const AppointmentExample({
    super.key,
    required this.firstDate,
    required this.lastDate,
    required this.currentDate,
    required this.calendarDelegate,
    required this.design,
  });

  final DateTime firstDate;
  final DateTime lastDate;
  final DateTime currentDate;
  final CalendarDelegate<DateTime> calendarDelegate;
  final GeneralCalendarDesign design;

  @override
  State<AppointmentExample> createState() => _AppointmentExampleState();
}

class _AppointmentExampleState extends State<AppointmentExample> {
  late final DateTime _firstBookableDate = _findFirstDate();
  late final DateTime _initialDateTime =
      CalendarDateTimeUtils.combine(_firstBookableDate, DemoData.initialTime);
  late DateTime? _draft = _initialDateTime;
  DateTime? _confirmed;
  GeneralTimePickerView _view = GeneralTimePickerView.slots;

  DateTime _findFirstDate() {
    var date = widget.currentDate;
    while (date.weekday == DateTime.friday) {
      date = widget.calendarDelegate.addDaysToDate(date, 1);
    }
    return date;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Appointment example')),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Book a consultation',
                      style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  const Text(
                    'Choose a date and a 15-minute appointment between 09:00 and '
                    '17:00. Fridays and lunch (12:00–12:59) are unavailable. '
                    'On day 15, appointments begin at 13:00. '
                    'Bookings start today at 14:30; earlier times today are blocked. '
                    'This form is a local demo.',
                  ),
                  const SizedBox(height: 16),
                  DemoDropdown<GeneralTimePickerView>(
                    key: const ValueKey('appointment-time-view'),
                    label: 'Time view',
                    value: _view,
                    items: [
                      for (final view in GeneralTimePickerView.values)
                        DropdownMenuItem(value: view, child: Text(view.name)),
                    ],
                    onChanged: (value) => setState(() => _view = value!),
                  ),
                  const SizedBox(height: 16),
                  GeneralDateTimePicker(
                    firstDate: widget.firstDate,
                    lastDate: widget.lastDate,
                    currentDate: widget.currentDate,
                    calendarDelegate: widget.calendarDelegate,
                    initialDateTime: _initialDateTime,
                    minimumDateTime: CalendarDateTimeUtils.combine(
                        widget.currentDate, DemoData.initialTime),
                    selectableDayPredicate: (date) =>
                        !date.isBefore(widget.currentDate),
                    dateAttributes: DemoData.attributes,
                    timeView: _view,
                    design: widget.design,
                    minuteInterval: 15,
                    use24HourFormat: true,
                    minimumTime: DemoData.openingTime,
                    maximumTime: DemoData.closingTime,
                    selectableDateTimePredicate: DemoData.isAppointmentTime,
                    onSelectionChanged: (value) => setState(() {
                      _draft = value;
                      _confirmed = null;
                    }),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _draft == null
                        ? 'Choose an available date and time to continue.'
                        : 'Draft: ${DemoData.dateTimeLabel(_draft!)}',
                    key: const ValueKey('appointment-draft'),
                  ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    key: const ValueKey('appointment-confirm'),
                    onPressed: _draft == null
                        ? null
                        : () => setState(() => _confirmed = _draft),
                    icon: const Icon(Icons.check),
                    label: const Text('Confirm demo appointment'),
                  ),
                  if (_confirmed != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: SelectableText(
                        'Demo appointment: ${DemoData.dateTimeLabel(_confirmed!)}\n'
                        'Calendar type: ${_confirmed.runtimeType}\n'
                        'UTC instant: ${DateTime.fromMicrosecondsSinceEpoch(_confirmed!.microsecondsSinceEpoch, isUtc: true).toIso8601String()}',
                        key: const ValueKey('appointment-result'),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
}
