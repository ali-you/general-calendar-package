import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'calendar_design.dart';
import 'calendar_theme.dart';
import 'time_rules.dart';

/// Time-only input. Initial values seed internal state; change the key to reset.
/// An unavailable initial time remains visible but cannot be confirmed. This
/// permits date-specific availability rules to change without losing the draft.
class GeneralTimePicker extends StatefulWidget {
  GeneralTimePicker({
    super.key,
    this.initialTime,
    this.onTimeChanged,
    this.onSelectionChanged,
    this.onDraftChanged,
    this.view = GeneralTimePickerView.input,
    this.use24HourFormat,
    this.readOnly = false,
    this.showUnavailableTimes = true,
    TimeOfDay minimumTime = const TimeOfDay(hour: 0, minute: 0),
    TimeOfDay maximumTime = const TimeOfDay(hour: 23, minute: 59),
    int minuteInterval = 1,
    SelectableTimePredicate? selectableTimePredicate,
    this.design = GeneralCalendarDesign.material,
    this.theme,
    this.labels = const GeneralTimePickerLabels(),
  }) : rules = GeneralTimePickerRules(
            minimumTime: minimumTime,
            maximumTime: maximumTime,
            minuteInterval: minuteInterval,
            selectableTimePredicate: selectableTimePredicate) {
    if (initialTime != null) GeneralTimePickerRules.minutesOfDay(initialTime!);
  }

  final TimeOfDay? initialTime;
  final ValueChanged<TimeOfDay>? onTimeChanged;

  /// Emits null for incomplete, malformed, or unavailable drafts. Use this
  /// callback to gate confirmation instead of retaining a stale valid time.
  final ValueChanged<TimeOfDay?>? onSelectionChanged;

  /// Reports parsed drafts, including times rejected by availability rules.
  /// Incomplete or malformed numeric input reports null.
  final ValueChanged<TimeOfDay?>? onDraftChanged;
  final GeneralTimePickerView view;
  final bool? use24HourFormat;
  final bool readOnly;
  final bool showUnavailableTimes;
  final GeneralTimePickerRules rules;
  final GeneralCalendarDesign design;
  final GeneralCalendarThemeData? theme;
  final GeneralTimePickerLabels labels;

  @override
  State<GeneralTimePicker> createState() => _GeneralTimePickerState();
}

class _GeneralTimePickerState extends State<GeneralTimePicker> {
  late final TextEditingController _hour;
  late final TextEditingController _minute;
  TimeOfDay? _draft;
  bool _pm = false;
  bool _minutesMode = false;
  bool _dragMinutes = false;
  bool _dialInput = false;
  bool _touched = false;
  bool? _lastFormat;
  FixedExtentScrollController? _hourWheel;
  FixedExtentScrollController? _minuteWheel;
  List<int>? _wheelMinutes;
  final ScrollController _slotsController = ScrollController();
  bool _scrollSlotsToDraft = true;

  bool get _is24 =>
      widget.use24HourFormat ?? MediaQuery.alwaysUse24HourFormatOf(context);
  bool get _valid => _draft != null && widget.rules.isSelectable(_draft!);

  @override
  void initState() {
    super.initState();
    _draft = widget.initialTime;
    _pm = (_draft?.hour ?? 0) >= 12;
    _hour = TextEditingController();
    _minute = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncFormat();
  }

  @override
  void didUpdateWidget(GeneralTimePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncFormat();
    if (oldWidget.view != widget.view ||
        oldWidget.rules.minuteInterval != widget.rules.minuteInterval) {
      _writeFields();
      _disposeWheels();
      _scrollSlotsToDraft = true;
    }
  }

  void _syncFormat() {
    if (_lastFormat != _is24) {
      _lastFormat = _is24;
      _writeFields();
      _disposeWheels();
    }
  }

  void _writeFields() {
    final time = _draft;
    String number(int value) {
      final localizations = MaterialLocalizations.of(context);
      return '${value < 10 ? localizations.formatDecimal(0) : ''}${localizations.formatDecimal(value)}';
    }

    _hour.text = time == null
        ? ''
        : number(_is24
            ? time.hour
            : time.hourOfPeriod == 0
                ? 12
                : time.hourOfPeriod);
    _minute.text = time == null ? '' : number(time.minute);
  }

  void _disposeWheels() {
    _hourWheel?.dispose();
    _minuteWheel?.dispose();
    _hourWheel = null;
    _minuteWheel = null;
    _wheelMinutes = null;
  }

  @override
  void dispose() {
    _hour.dispose();
    _minute.dispose();
    _disposeWheels();
    _slotsController.dispose();
    super.dispose();
  }

  int? _number(String text) {
    final localizations = MaterialLocalizations.of(context);
    for (var digit = 0; digit < 10; digit++) {
      text = text.replaceAll(localizations.formatDecimal(digit), '$digit');
    }
    // Accept ASCII, Arabic-Indic, and Persian digits; display follows locale.
    final normalized = text.trim().split('').map((char) {
      final code = char.codeUnitAt(0);
      if (code >= 0x0660 && code <= 0x0669) return '${code - 0x0660}';
      if (code >= 0x06F0 && code <= 0x06F9) return '${code - 0x06F0}';
      return char;
    }).join();
    return RegExp(r'^\d{1,2}$').hasMatch(normalized)
        ? int.tryParse(normalized)
        : null;
  }

  void _readFields() {
    final hour = _number(_hour.text);
    final minute = _number(_minute.text);
    TimeOfDay? time;
    if (hour != null &&
        minute != null &&
        minute >= 0 &&
        minute < 60 &&
        (_is24 ? hour >= 0 && hour < 24 : hour >= 1 && hour <= 12)) {
      time = TimeOfDay(
          hour: _is24 ? hour : hour % 12 + (_pm ? 12 : 0), minute: minute);
    }
    _commit(time, syncFields: false);
  }

  void _commit(TimeOfDay? time, {bool syncFields = true}) {
    if (widget.readOnly) return;
    setState(() {
      _draft = time;
      _touched = true;
      if (time != null) _pm = time.hour >= 12;
      if (syncFields) _writeFields();
    });
    final value = _valid ? _draft : null;
    widget.onDraftChanged?.call(_draft);
    if (value != null) widget.onTimeChanged?.call(value);
    widget.onSelectionChanged?.call(value);
  }

  String _format(TimeOfDay time) => MaterialLocalizations.of(context)
      .formatTimeOfDay(time, alwaysUse24HourFormat: _is24);

  GeneralCalendarThemeData get _theme => widget.design
      .resolve(Theme.of(context))
      .merge(GeneralCalendarTheme.of(context))
      .merge(widget.theme);

  @override
  Widget build(BuildContext context) {
    final theme = _theme;
    final localizations = MaterialLocalizations.of(context);
    final error = !_valid && (_touched || _draft != null)
        ? _draft == null
            ? localizations.invalidTimeLabel
            : widget.labels.unavailableTime
        : null;
    final content = Material(
      key: const ValueKey('general-time-picker'),
      color: theme.surfaceColor,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(theme.surfaceRadius ?? 12),
          side: theme.showBorder == true
              ? BorderSide(color: theme.borderColor!)
              : BorderSide.none),
      child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              switch (widget.view) {
                GeneralTimePickerView.input => _input(theme),
                GeneralTimePickerView.dial =>
                  Column(mainAxisSize: MainAxisSize.min, children: [
                    _dialInput ? _input(theme) : _dial(theme),
                    Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: IconButton(
                          key: const ValueKey('general-time-toggle-entry'),
                          tooltip: _dialInput
                              ? localizations.timePickerDialHelpText
                              : localizations.timePickerInputHelpText,
                          icon: Icon(
                              _dialInput ? Icons.access_time : Icons.keyboard),
                          onPressed: widget.readOnly
                              ? null
                              : () => setState(() {
                                    _dialInput = !_dialInput;
                                    _writeFields();
                                  }),
                        )),
                  ]),
                GeneralTimePickerView.wheels => _wheels(theme),
                GeneralTimePickerView.dropdown => _dropdown(),
                GeneralTimePickerView.slots => _slots(theme),
              },
              if (error != null)
                Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Semantics(
                        liveRegion: true,
                        child: Text(error,
                            key: const ValueKey('general-time-error'),
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.error)))),
            ],
          )),
    );
    final ambient = Theme.of(context);
    final accent = theme.todayColor ?? ambient.colorScheme.primary;
    final styled = Theme(
        data: ambient.copyWith(
            colorScheme: ambient.colorScheme.copyWith(
          primary: accent,
          onPrimary:
              ThemeData.estimateBrightnessForColor(accent) == Brightness.dark
                  ? Colors.white
                  : Colors.black,
          primaryContainer: theme.rangeColor,
          onPrimaryContainer: theme.foregroundColor,
          surface: theme.surfaceColor,
          onSurface: theme.foregroundColor,
        )),
        child: content);
    return Semantics(
        enabled: !widget.readOnly,
        readOnly: widget.readOnly,
        label: widget.readOnly && _draft != null ? _format(_draft!) : null,
        child: ExcludeSemantics(excluding: widget.readOnly, child: styled));
  }

  Widget _input(GeneralCalendarThemeData theme) {
    return LayoutBuilder(builder: (context, constraints) {
      final localizations = MaterialLocalizations.of(context);
      final width = ((constraints.maxWidth -
                  32 -
                  MediaQuery.textScalerOf(context).scale(28)) /
              2)
          .clamp(72, 104)
          .toDouble();
      Widget field(
              TextEditingController controller, String label, String key) =>
          SizedBox(
            width: width,
            child: TextField(
              key: ValueKey(key),
              controller: controller,
              readOnly: widget.readOnly,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              textInputAction: key == 'general-time-hour'
                  ? TextInputAction.next
                  : TextInputAction.done,
              inputFormatters: [LengthLimitingTextInputFormatter(2)],
              style: TextStyle(fontSize: 28, color: theme.foregroundColor),
              decoration: InputDecoration(
                  labelText: label,
                  border: const OutlineInputBorder(),
                  floatingLabelBehavior: FloatingLabelBehavior.always),
              onChanged: (_) => _readFields(),
            ),
          );
      return Wrap(
          spacing: 12,
          runSpacing: 16,
          crossAxisAlignment: WrapCrossAlignment.center,
          alignment: WrapAlignment.center,
          children: [
            field(
                _hour, localizations.timePickerHourLabel, 'general-time-hour'),
            const Text(':', style: TextStyle(fontSize: 28)),
            field(_minute, localizations.timePickerMinuteLabel,
                'general-time-minute'),
            if (!_is24) _period(),
          ]);
    });
  }

  Widget _period() {
    final localizations = MaterialLocalizations.of(context);
    return Wrap(spacing: 4, children: [
      for (final pm in [false, true])
        ChoiceChip(
          key: ValueKey(pm ? 'general-time-pm' : 'general-time-am'),
          label: Text(pm
              ? localizations.postMeridiemAbbreviation
              : localizations.anteMeridiemAbbreviation),
          selected: _pm == pm,
          onSelected: widget.readOnly
              ? null
              : (_) {
                  setState(() => _pm = pm);
                  if (widget.view == GeneralTimePickerView.input ||
                      widget.view == GeneralTimePickerView.dial && _dialInput) {
                    _readFields();
                  } else {
                    final current =
                        _draft ?? const TimeOfDay(hour: 0, minute: 0);
                    _commit(TimeOfDay(
                        hour: current.hourOfPeriod + (pm ? 12 : 0),
                        minute: current.minute));
                  }
                },
        ),
    ]);
  }

  Widget _dropdown() {
    final times = widget.rules.times
        .where((time) =>
            widget.showUnavailableTimes || widget.rules.isSelectable(time))
        .toList();
    if (times.isEmpty || !times.any(widget.rules.isSelectable)) {
      return Text(widget.labels.noAvailableTimes);
    }
    return InputDecorator(
        decoration: InputDecoration(
            labelText: widget.labels.time, border: const OutlineInputBorder()),
        child: DropdownButtonHideUnderline(
            child: DropdownButton<TimeOfDay>(
          // The key resets the form field when another view changes its draft.
          key: ValueKey(
              'general-time-dropdown-${_draft?.hour}-${_draft?.minute}'),
          value: times.contains(_draft) ? _draft : null,
          hint: _draft == null ? null : Text(_format(_draft!)),
          isExpanded: true,
          items: [
            for (final time in times)
              DropdownMenuItem(
                value: time,
                enabled: widget.rules.isSelectable(time),
                child: Text(_format(time),
                    style: TextStyle(
                        color: widget.rules.isSelectable(time)
                            ? _theme.foregroundColor
                            : _theme.mutedForegroundColor
                                ?.withValues(alpha: 0.5))),
              )
          ],
          onChanged: widget.readOnly ? null : _commit,
        )));
  }

  Widget _slots(GeneralCalendarThemeData theme) {
    final times = widget.rules.times
        .where((time) =>
            widget.showUnavailableTimes || widget.rules.isSelectable(time))
        .toList();
    if (times.isEmpty || !times.any(widget.rules.isSelectable)) {
      return Text(widget.labels.noAvailableTimes);
    }
    return SizedBox(
        height: 288,
        child: LayoutBuilder(builder: (context, constraints) {
          final columns = (constraints.maxWidth / 112).floor().clamp(1, 6);
          final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
          final extent = 48.0 * textScale.clamp(1, 3);
          if (_scrollSlotsToDraft) {
            _scrollSlotsToDraft = false;
            final selectedIndex = times.indexOf(_draft ?? times.first);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted &&
                  _slotsController.hasClients &&
                  selectedIndex >= 0) {
                _slotsController.jumpTo(
                    ((selectedIndex ~/ columns) * (extent + 8))
                        .clamp(0, _slotsController.position.maxScrollExtent)
                        .toDouble());
              }
            });
          }
          return GridView.builder(
            key: const ValueKey('general-time-slots'),
            controller: _slotsController,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                mainAxisExtent: extent,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8),
            itemCount: times.length,
            itemBuilder: (context, index) {
              final time = times[index];
              final selected = time == _draft;
              final enabled =
                  !widget.readOnly && widget.rules.isSelectable(time);
              return Semantics(
                  selected: selected,
                  child: OutlinedButton(
                    key: ValueKey(
                        'general-time-slot-${time.hour}-${time.minute}'),
                    onPressed: enabled ? () => _commit(time) : null,
                    style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        backgroundColor:
                            selected ? theme.selectedDayColor : null,
                        foregroundColor: selected
                            ? theme.selectedDayForegroundColor
                            : theme.foregroundColor,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                (theme.dayRadius ?? 6).clamp(0, 16)))),
                    child: FittedBox(
                        fit: BoxFit.scaleDown, child: Text(_format(time))),
                  ));
            },
          );
        }));
  }

  Widget _wheels(GeneralCalendarThemeData theme) {
    final current = _draft ?? const TimeOfDay(hour: 0, minute: 0);
    final hours = List.generate(_is24 ? 24 : 12, (i) => _is24 ? i : i + 1);
    _wheelMinutes ??= [
      for (var value = 0; value < 60; value += widget.rules.minuteInterval)
        value,
      if (current.minute % widget.rules.minuteInterval != 0) current.minute,
    ]..sort();
    final minutes = _wheelMinutes!;
    final hourIndex = _is24
        ? current.hour
        : (current.hourOfPeriod == 0 ? 11 : current.hourOfPeriod - 1);
    _hourWheel ??= FixedExtentScrollController(initialItem: hourIndex);
    _minuteWheel ??= FixedExtentScrollController(
        initialItem: minutes.indexOf(current.minute));
    Widget wheel(String key, FixedExtentScrollController controller,
            List<int> values, ValueChanged<int> onChanged) =>
        Expanded(
          child: CupertinoPicker(
            key: ValueKey('$key-$_is24-${widget.rules.minuteInterval}'),
            scrollController: controller,
            itemExtent: 44 *
                (MediaQuery.textScalerOf(context).scale(18) / 18).clamp(1, 2),
            onSelectedItemChanged: onChanged,
            children: [
              for (final value in values)
                Center(
                    child: Text(
                        MaterialLocalizations.of(context)
                            .formatDecimal(value)
                            .padLeft(2, '0'),
                        style: TextStyle(
                            fontFamily: theme.dayTextStyle?.fontFamily,
                            color: widget.rules.isSelectable(TimeOfDay(
                                    hour: key == 'general-time-hour-wheel'
                                        ? _is24
                                            ? value
                                            : value % 12 + (_pm ? 12 : 0)
                                        : current.hour,
                                    minute: key == 'general-time-hour-wheel'
                                        ? current.minute
                                        : value))
                                ? theme.foregroundColor
                                : theme.mutedForegroundColor
                                    ?.withValues(alpha: 0.5),
                            fontSize: 22)))
            ],
          ),
        );
    return Column(mainAxisSize: MainAxisSize.min, children: [
      IgnorePointer(
          ignoring: widget.readOnly,
          child: SizedBox(
              height: 220,
              child: Row(children: [
                wheel(
                    'general-time-hour-wheel',
                    _hourWheel!,
                    hours,
                    (index) => _commit(TimeOfDay(
                        hour: _is24
                            ? hours[index]
                            : hours[index] % 12 + (_pm ? 12 : 0),
                        minute: _draft?.minute ?? 0))),
                const Text(':'),
                wheel(
                    'general-time-minute-wheel',
                    _minuteWheel!,
                    minutes,
                    (index) => _commit(TimeOfDay(
                        hour: _draft?.hour ?? 0, minute: minutes[index]))),
              ]))),
      if (!_is24) _period(),
    ]);
  }

  void _chooseHour(int hour, {bool advance = true}) {
    final minute = _draft?.minute ?? 0;
    var next = TimeOfDay(hour: hour, minute: minute);
    if (!widget.rules.isSelectable(next)) {
      final candidates = widget.rules.times.where(
          (time) => time.hour == hour && widget.rules.isSelectable(time));
      if (candidates.isEmpty) return;
      next = candidates.first;
    }
    _commit(next);
    if (advance) setState(() => _minutesMode = true);
  }

  Widget _dial(GeneralCalendarThemeData theme) {
    final time = _draft ?? const TimeOfDay(hour: 0, minute: 0);
    final localizations = MaterialLocalizations.of(context);
    final accent = theme.selectedDayColor!;
    final times = widget.rules.times;
    Widget modeButton(bool minutes) => TextButton(
          key: ValueKey(
              minutes ? 'general-time-minute-mode' : 'general-time-hour-mode'),
          onPressed: widget.readOnly
              ? null
              : () => setState(() => _minutesMode = minutes),
          style: TextButton.styleFrom(
              backgroundColor:
                  _minutesMode == minutes ? theme.rangeColor : null),
          child: Text(
              minutes
                  ? time.minute.toString().padLeft(2, '0')
                  : (_is24
                          ? time.hour
                          : time.hourOfPeriod == 0
                              ? 12
                              : time.hourOfPeriod)
                      .toString()
                      .padLeft(2, '0'),
              style: TextStyle(fontSize: 32, color: theme.foregroundColor)),
        );
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Wrap(
          spacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            modeButton(false),
            const Text(':', style: TextStyle(fontSize: 28)),
            modeButton(true),
            if (!_is24) _period(),
          ]),
      const SizedBox(height: 12),
      Semantics(
          label: _minutesMode
              ? localizations.timePickerMinuteModeAnnouncement
              : localizations.timePickerHourModeAnnouncement,
          child: SizedBox(
              width: 280,
              child: AspectRatio(
                  aspectRatio: 1,
                  child: LayoutBuilder(builder: (context, constraints) {
                    final size =
                        math.min(constraints.maxWidth, constraints.maxHeight);
                    final center = Offset(size / 2, size / 2);
                    final radius = size / 2 - 24;
                    void handle(Offset position,
                        {bool? minuteMode, bool advance = true}) {
                      if (widget.readOnly) return;
                      final delta = position - center;
                      final turns =
                          (math.atan2(delta.dx, -delta.dy) + math.pi * 2) %
                              (math.pi * 2) /
                              (math.pi * 2);
                      if (minuteMode ?? _minutesMode) {
                        final minute =
                            ((turns * 60 / widget.rules.minuteInterval)
                                        .round() *
                                    widget.rules.minuteInterval) %
                                60;
                        final next = TimeOfDay(hour: time.hour, minute: minute);
                        if (widget.rules.isSelectable(next)) _commit(next);
                      } else {
                        final hour = (turns * 12).round() % 12;
                        _chooseHour(
                            _is24
                                ? hour +
                                    (delta.distance < radius * 0.75 ? 12 : 0)
                                : hour + (_pm ? 12 : 0),
                            advance: advance);
                      }
                    }

                    final selected =
                        _minutesMode ? time.minute / 5 : time.hour % 12;
                    final handRadius = !_minutesMode && _is24 && time.hour >= 12
                        ? radius * 0.57
                        : radius;
                    return GestureDetector(
                      key: const ValueKey('general-time-dial'),
                      onTapUp: widget.readOnly
                          ? null
                          : (event) => handle(event.localPosition),
                      onPanUpdate: widget.readOnly
                          ? null
                          : (event) => handle(event.localPosition,
                              minuteMode: _dragMinutes, advance: false),
                      onPanStart: widget.readOnly
                          ? null
                          : (_) => _dragMinutes = _minutesMode,
                      onPanEnd: widget.readOnly
                          ? null
                          : (_) {
                              if (!_dragMinutes) {
                                setState(() => _minutesMode = true);
                              }
                            },
                      child: CustomPaint(
                        painter: _TimeDialPainter(
                            background: theme.rangeColor!,
                            accent: accent,
                            selected: selected.toDouble(),
                            radius: handRadius),
                        child: Stack(children: [
                          for (var ring = 0;
                              ring < (!_minutesMode && _is24 ? 2 : 1);
                              ring++)
                            for (var index = 0; index < 12; index++)
                              Builder(builder: (context) {
                                final value = _minutesMode
                                    ? index * 5
                                    : _is24
                                        ? index + ring * 12
                                        : index == 0
                                            ? 12
                                            : index;
                                final currentRadius =
                                    ring == 0 ? radius : radius * 0.57;
                                final angle = index * math.pi / 6;
                                final active = _minutesMode
                                    ? value == time.minute
                                    : _is24
                                        ? value == time.hour
                                        : value % 12 == time.hourOfPeriod;
                                final hour =
                                    _is24 ? value : value % 12 + (_pm ? 12 : 0);
                                final enabled = _minutesMode
                                    ? widget.rules.isSelectable(TimeOfDay(
                                        hour: time.hour, minute: value))
                                    : times.any((t) =>
                                        t.hour == hour &&
                                        widget.rules.isSelectable(t));
                                return Positioned(
                                  left: center.dx +
                                      math.sin(angle) * currentRadius -
                                      20,
                                  top: center.dy -
                                      math.cos(angle) * currentRadius -
                                      20,
                                  width: 40,
                                  height: 40,
                                  child: Semantics(
                                      selected: active,
                                      child: TextButton(
                                        key: ValueKey(
                                            'general-time-dial-${_minutesMode ? 'minute' : 'hour'}-$value'),
                                        onPressed: widget.readOnly || !enabled
                                            ? null
                                            : () {
                                                if (_minutesMode) {
                                                  _commit(TimeOfDay(
                                                      hour: time.hour,
                                                      minute: value));
                                                } else {
                                                  _chooseHour(hour);
                                                }
                                              },
                                        style: TextButton.styleFrom(
                                            padding: EdgeInsets.zero,
                                            foregroundColor: active
                                                ? theme
                                                    .selectedDayForegroundColor
                                                : theme.foregroundColor,
                                            disabledForegroundColor: theme
                                                .mutedForegroundColor
                                                ?.withValues(alpha: 0.38)),
                                        child: FittedBox(
                                            child: Text(
                                                localizations
                                                    .formatDecimal(value),
                                                style: const TextStyle(
                                                    fontSize: 16))),
                                      )),
                                );
                              }),
                        ]),
                      ),
                    );
                  })))),
    ]);
  }
}

class _TimeDialPainter extends CustomPainter {
  const _TimeDialPainter(
      {required this.background,
      required this.accent,
      required this.selected,
      required this.radius});
  final Color background;
  final Color accent;
  final double selected;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final angle = selected * math.pi / 6;
    final point = center + Offset(math.sin(angle), -math.cos(angle)) * radius;
    canvas.drawCircle(center, math.min(size.width, size.height) / 2,
        Paint()..color = background);
    canvas.drawLine(
        center,
        point,
        Paint()
          ..color = accent
          ..strokeWidth = 2);
    canvas.drawCircle(center, 4, Paint()..color = accent);
    canvas.drawCircle(point, 20, Paint()..color = accent);
  }

  @override
  bool shouldRepaint(_TimeDialPainter oldDelegate) =>
      background != oldDelegate.background ||
      accent != oldDelegate.accent ||
      selected != oldDelegate.selected ||
      radius != oldDelegate.radius;
}
