import 'package:flutter/material.dart';

import 'calendar_attributes.dart';
import 'calendar_selection.dart';
import 'calendar_theme.dart';

/// A Material calendar using Flutter's own arithmetic/localization delegates.
///
/// Like [CalendarDatePicker], initial values seed internal state. Change the
/// widget's key to replace them. Replacing [calendarDelegate] or [selectionMode]
/// resets the state with the new initial values. All dates must belong to the
/// supplied delegate; conversion and localization are the application's job.
class GeneralCalendar extends StatefulWidget {
  GeneralCalendar({
    super.key,
    required DateTime firstDate,
    required DateTime lastDate,
    DateTime? initialDate,
    DateTime? currentDate,
    DateTime? initialDisplayedDate,
    List<DateTime> initialSelectedDates = const [],
    DateTimeRange<DateTime>? initialDateRange,
    this.calendarDelegate = const GregorianCalendarDelegate(),
    this.initialView = GeneralCalendarView.month,
    this.selectionMode = CalendarSelectionMode.single,
    this.onDateChanged,
    this.onDatesChanged,
    this.onDateRangeChanged,
    this.onSelectionChanged,
    this.onDisplayedMonthChanged,
    this.onViewChanged,
    this.selectableDayPredicate,
    this.dateAttributes,
    this.dayBuilder,
    this.theme,
    this.labels = const GeneralCalendarLabels(),
    this.firstDayOfWeek,
    Set<int> weekendDays = const {DateTime.saturday, DateTime.sunday},
    this.showAdjacentMonthDays = false,
    this.showViewSwitcher = true,
    this.readOnly = false,
    this.allowDisabledDatesInRange = false,
    this.maxSelectedDates,
  })  : firstDate = calendarDelegate.dateOnly(firstDate),
        lastDate = calendarDelegate.dateOnly(lastDate),
        initialDate =
            initialDate == null ? null : calendarDelegate.dateOnly(initialDate),
        currentDate = calendarDelegate.dateOnly(
          currentDate ?? calendarDelegate.now(),
        ),
        initialDisplayedDate = initialDisplayedDate == null
            ? null
            : calendarDelegate.dateOnly(initialDisplayedDate),
        initialSelectedDates = List.unmodifiable(
          initialSelectedDates.map(calendarDelegate.dateOnly),
        ),
        initialDateRange = initialDateRange == null
            ? null
            : calendarDelegate.datesOnly(initialDateRange),
        weekendDays = Set.unmodifiable(weekendDays) {
    if (this.lastDate.isBefore(this.firstDate)) {
      throw ArgumentError('lastDate must be on or after firstDate.');
    }
    if (firstDayOfWeek != null &&
        (firstDayOfWeek! < 1 || firstDayOfWeek! > 7)) {
      throw ArgumentError.value(firstDayOfWeek, 'firstDayOfWeek', 'Use 1–7.');
    }
    if (weekendDays.any((day) => day < 1 || day > 7)) {
      throw ArgumentError.value(weekendDays, 'weekendDays', 'Use 1–7.');
    }
    if (maxSelectedDates != null && maxSelectedDates! < 1) {
      throw ArgumentError.value(maxSelectedDates, 'maxSelectedDates');
    }
    if ((selectionMode != CalendarSelectionMode.single &&
            initialDate != null) ||
        (selectionMode != CalendarSelectionMode.multiple &&
            initialSelectedDates.isNotEmpty) ||
        (selectionMode != CalendarSelectionMode.range &&
            initialDateRange != null)) {
      throw ArgumentError('Initial selection must match selectionMode.');
    }
    for (final date in [
      if (this.initialDate != null) this.initialDate!,
      ...this.initialSelectedDates,
    ]) {
      if (!isDateSelectable(date)) {
        throw ArgumentError.value(date, 'initial selection', 'Not selectable.');
      }
    }
    final uniqueCount = <String>{
      for (final date in this.initialSelectedDates)
        '${date.year}/${date.month}/${date.day}',
    }.length;
    if (maxSelectedDates != null && uniqueCount > maxSelectedDates!) {
      throw ArgumentError('Initial selection exceeds maxSelectedDates.');
    }
    if (this.initialDateRange != null &&
        !isRangeSelectable(this.initialDateRange!)) {
      throw ArgumentError.value(initialDateRange, 'initialDateRange');
    }
    if (this.initialDisplayedDate != null &&
        !_isWithinBounds(this.initialDisplayedDate!)) {
      throw ArgumentError.value(initialDisplayedDate, 'initialDisplayedDate');
    }
  }

  final DateTime firstDate;
  final DateTime lastDate;
  final DateTime? initialDate;
  final DateTime currentDate;
  final DateTime? initialDisplayedDate;
  final List<DateTime> initialSelectedDates;
  final DateTimeRange<DateTime>? initialDateRange;
  final CalendarDelegate<DateTime> calendarDelegate;
  final GeneralCalendarView initialView;
  final CalendarSelectionMode selectionMode;
  final ValueChanged<DateTime>? onDateChanged;
  final ValueChanged<List<DateTime>>? onDatesChanged;

  /// Called only for complete ranges. Use [onSelectionChanged] for pending ones.
  final ValueChanged<DateTimeRange<DateTime>>? onDateRangeChanged;
  final ValueChanged<CalendarSelection>? onSelectionChanged;
  final ValueChanged<DateTime>? onDisplayedMonthChanged;
  final ValueChanged<GeneralCalendarView>? onViewChanged;
  final SelectableDayPredicate? selectableDayPredicate;
  final CalendarDateAttributesBuilder? dateAttributes;
  final CalendarDayBuilder? dayBuilder;
  final GeneralCalendarThemeData? theme;
  final GeneralCalendarLabels labels;

  /// Dart weekday, Monday=1 through Sunday=7. Null follows the locale.
  final int? firstDayOfWeek;
  final Set<int> weekendDays;
  final bool showAdjacentMonthDays;
  final bool showViewSwitcher;

  /// Prevents selection while allowing navigation and inspecting attributes.
  final bool readOnly;

  /// Endpoints must always be selectable, even when this is true.
  final bool allowDisabledDatesInRange;
  final int? maxSelectedDates;

  bool _isWithinBounds(DateTime date) =>
      !date.isBefore(firstDate) && !date.isAfter(lastDate);

  /// Checks bounds, the attribute flag, and the optional predicate together.
  bool isDateSelectable(DateTime date) {
    date = calendarDelegate.dateOnly(date);
    return _isWithinBounds(date) &&
        !(dateAttributes?.call(date).isDisabled ?? false) &&
        (selectableDayPredicate?.call(date) ?? true);
  }

  /// Uses delegate day arithmetic, including across daylight-saving changes.
  bool isRangeSelectable(DateTimeRange<DateTime> range) {
    final normalized = calendarDelegate.datesOnly(range);
    if (!isDateSelectable(normalized.start) ||
        !isDateSelectable(normalized.end)) {
      return false;
    }
    if (allowDisabledDatesInRange) return true;
    var date = normalized.start;
    while (date.isBefore(normalized.end)) {
      date = calendarDelegate.addDaysToDate(date, 1);
      if (!isDateSelectable(date)) return false;
    }
    return true;
  }

  @override
  State<GeneralCalendar> createState() => _GeneralCalendarState();
}

class _GeneralCalendarState extends State<GeneralCalendar> {
  late DateTime _displayed;
  late GeneralCalendarView _view;
  final List<DateTime> _dates = [];
  DateTime? _rangeStart;
  DateTime? _rangeEnd;

  CalendarDelegate<DateTime> get _delegate => widget.calendarDelegate;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset() {
    _view = widget.initialView;
    _dates.clear();
    for (final date in [
      if (widget.initialDate != null) widget.initialDate!,
      ...widget.initialSelectedDates,
    ]) {
      if (!_dates.any((other) => _delegate.isSameDay(date, other))) {
        _dates.add(date);
      }
    }
    _dates.sort();
    _rangeStart = widget.initialDateRange?.start;
    _rangeEnd = widget.initialDateRange?.end;
    _displayed = _clamp(
      widget.initialDisplayedDate ??
          (_dates.isEmpty ? null : _dates.first) ??
          _rangeStart ??
          widget.currentDate,
    );
  }

  @override
  void didUpdateWidget(GeneralCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.calendarDelegate != oldWidget.calendarDelegate ||
        widget.selectionMode != oldWidget.selectionMode) {
      _reset();
      return;
    }
    _displayed = _clamp(_displayed);
    // Rule changes immediately remove stale selections, without user callbacks.
    _dates.removeWhere((date) => !widget.isDateSelectable(date));
    final limit = widget.maxSelectedDates;
    if (limit != null && _dates.length > limit) {
      _dates.removeRange(limit, _dates.length);
    }
    if ((_rangeStart != null && !widget.isDateSelectable(_rangeStart!)) ||
        (_rangeEnd != null &&
            !widget.isRangeSelectable(
              DateTimeRange(start: _rangeStart!, end: _rangeEnd!),
            ))) {
      _rangeStart = null;
      _rangeEnd = null;
    }
  }

  DateTime _clamp(DateTime date) => date.isBefore(widget.firstDate)
      ? widget.firstDate
      : date.isAfter(widget.lastDate)
          ? widget.lastDate
          : date;

  void _select(DateTime date) {
    if (widget.readOnly || !widget.isDateSelectable(date)) return;
    switch (widget.selectionMode) {
      case CalendarSelectionMode.single:
        setState(() {
          _dates
            ..clear()
            ..add(date);
        });
        widget.onDateChanged?.call(date);
      case CalendarSelectionMode.multiple:
        final index = _dates.indexWhere((d) => _delegate.isSameDay(d, date));
        if (index < 0 &&
            widget.maxSelectedDates != null &&
            _dates.length >= widget.maxSelectedDates!) {
          return;
        }
        setState(() {
          if (index >= 0) {
            _dates.removeAt(index);
          } else {
            _dates.add(date);
            _dates.sort();
          }
        });
        widget.onDatesChanged?.call(List.unmodifiable(_dates));
      case CalendarSelectionMode.range:
        if (_rangeStart == null || _rangeEnd != null) {
          setState(() {
            _rangeStart = date;
            _rangeEnd = null;
          });
        } else {
          final range = DateTimeRange(
            start: date.isBefore(_rangeStart!) ? date : _rangeStart!,
            end: date.isBefore(_rangeStart!) ? _rangeStart! : date,
          );
          if (!widget.isRangeSelectable(range)) return;
          setState(() {
            _rangeStart = range.start;
            _rangeEnd = range.end;
          });
          widget.onDateRangeChanged?.call(range);
        }
    }
    widget.onSelectionChanged?.call(
      CalendarSelection(
        mode: widget.selectionMode,
        dates: _dates,
        rangeStart: _rangeStart,
        rangeEnd: _rangeEnd,
      ),
    );
  }

  int _weekOffset(DateTime date, MaterialLocalizations localizations) =>
      (date.weekday % 7 -
          (widget.firstDayOfWeek == null
              ? localizations.firstDayOfWeekIndex
              : widget.firstDayOfWeek! % 7)) %
      7;

  // Leading/trailing cells may lie outside a finite calendar's supported span.
  DateTime? _tryAddDays(DateTime date, int days) {
    try {
      return _delegate.addDaysToDate(date, days);
    } on RangeError {
      return null;
    }
  }

  bool _canNavigate(int direction, MaterialLocalizations localizations) {
    final bound = direction < 0 ? widget.firstDate : widget.lastDate;
    return switch (_view) {
      GeneralCalendarView.month =>
        direction * _delegate.monthDelta(_displayed, bound) > 0,
      GeneralCalendarView.year =>
        direction * (bound.year - _displayed.year) > 0,
      GeneralCalendarView.week => direction < 0
          ? _displayed.isAfter(bound) &&
              (_tryAddDays(
                    _displayed,
                    -_weekOffset(_displayed, localizations),
                  )?.isAfter(bound) ??
                  false)
          : _displayed.isBefore(bound) &&
              (_tryAddDays(
                    _displayed,
                    6 - _weekOffset(_displayed, localizations),
                  )?.isBefore(bound) ??
                  false),
    };
  }

  void _navigate(int direction, MaterialLocalizations localizations) {
    if (!_canNavigate(direction, localizations)) return;
    DateTime? next;
    switch (_view) {
      case GeneralCalendarView.month:
        next = _delegate.addMonthsToMonthDate(_displayed, direction);
      case GeneralCalendarView.year:
        next = _delegate.getMonth(
          _displayed.year + direction,
          _displayed.month,
        );
      case GeneralCalendarView.week:
        final offset = _weekOffset(_displayed, localizations);
        next = _tryAddDays(
          _displayed,
          direction < 0 ? -offset - 1 : 7 - offset,
        );
    }
    _setDisplayed(
      _clamp(next ?? (direction < 0 ? widget.firstDate : widget.lastDate)),
    );
  }

  void _setDisplayed(DateTime date) {
    final changedMonth = !_delegate.isSameMonth(_displayed, date);
    setState(() => _displayed = date);
    if (changedMonth) {
      widget.onDisplayedMonthChanged?.call(
        _delegate.getMonth(date.year, date.month),
      );
    }
  }

  void _setView(GeneralCalendarView view) {
    if (_view == view) return;
    setState(() => _view = view);
    widget.onViewChanged?.call(view);
  }

  @override
  Widget build(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);
    final theme = widget.theme ?? GeneralCalendarTheme.of(context);
    return Material(
      type: MaterialType.transparency,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Semantics(
                  liveRegion: true,
                  child: Padding(
                    padding: const EdgeInsetsDirectional.only(start: 16),
                    child: Text(
                      _view == GeneralCalendarView.year
                          ? _delegate.formatYear(_displayed.year, localizations)
                          : _delegate.formatMonthYear(
                              _displayed,
                              localizations,
                            ),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ),
              ),
              if (widget.showViewSwitcher)
                PopupMenuButton<GeneralCalendarView>(
                  key: const ValueKey('general-calendar-view'),
                  tooltip: widget.labels.chooseView,
                  icon: const Icon(Icons.calendar_view_month),
                  onSelected: _setView,
                  itemBuilder: (context) => [
                    for (final view in GeneralCalendarView.values)
                      PopupMenuItem(value: view, child: Text(_viewLabel(view))),
                  ],
                ),
              IconButton(
                key: const ValueKey('general-calendar-previous'),
                tooltip: localizations.previousPageTooltip,
                onPressed: _canNavigate(-1, localizations)
                    ? () => _navigate(-1, localizations)
                    : null,
                icon: const Icon(Icons.chevron_left),
              ),
              IconButton(
                key: const ValueKey('general-calendar-next'),
                tooltip: localizations.nextPageTooltip,
                onPressed: _canNavigate(1, localizations)
                    ? () => _navigate(1, localizations)
                    : null,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          if (_view == GeneralCalendarView.year)
            _buildYear(context, localizations)
          else ...[
            _buildWeekdays(localizations, theme),
            ..._buildDays(context, localizations, theme),
          ],
        ],
      ),
    );
  }

  String _viewLabel(GeneralCalendarView view) => switch (view) {
        GeneralCalendarView.month => widget.labels.month,
        GeneralCalendarView.week => widget.labels.week,
        GeneralCalendarView.year => widget.labels.year,
      };

  Widget _buildWeekdays(
    MaterialLocalizations localizations,
    GeneralCalendarThemeData theme,
  ) {
    final first = widget.firstDayOfWeek == null
        ? localizations.firstDayOfWeekIndex
        : widget.firstDayOfWeek! % 7;
    return Row(
      children: [
        for (var i = 0; i < 7; i++)
          Expanded(
            child: ExcludeSemantics(
              child: SizedBox(
                height: 32,
                child: Center(
                  child: Text(
                    localizations.narrowWeekdays[(first + i) % 7],
                    style: theme.weekdayTextStyle,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  List<Widget> _buildDays(
    BuildContext context,
    MaterialLocalizations localizations,
    GeneralCalendarThemeData theme,
  ) {
    final month = _delegate.getMonth(_displayed.year, _displayed.month);
    final week = _view == GeneralCalendarView.week;
    final offset = week
        ? _weekOffset(_displayed, localizations)
        : widget.firstDayOfWeek == null
            ? _delegate.firstDayOffset(month.year, month.month, localizations)
            : _weekOffset(month, localizations);
    final length = _delegate.getDaysInMonth(month.year, month.month);
    final rows = week ? 1 : ((offset + length + 6) ~/ 7);
    return [
      for (var row = 0; row < rows; row++)
        Row(
          children: [
            for (var column = 0; column < 7; column++)
              Expanded(
                child: SizedBox(
                  height: theme.dayHeight,
                  child: Builder(
                    builder: (context) {
                      final index = row * 7 + column - offset;
                      if (!week &&
                          !widget.showAdjacentMonthDays &&
                          (index < 0 || index >= length)) {
                        return const SizedBox.shrink();
                      }
                      final date = week
                          ? _tryAddDays(_displayed, index)
                          : index >= 0 && index < length
                              ? _delegate.getDay(
                                  month.year, month.month, index + 1)
                              : _tryAddDays(month, index);
                      return date == null
                          ? const SizedBox.shrink()
                          : _buildDay(context, date, localizations, theme);
                    },
                  ),
                ),
              ),
          ],
        ),
    ];
  }

  Widget _buildYear(BuildContext context, MaterialLocalizations localizations) {
    final months = <DateTime>[];
    var month = _delegate.getMonth(_displayed.year, 1);
    while (month.year == _displayed.year) {
      if (_delegate.monthDelta(month, widget.firstDate) <= 0 &&
          _delegate.monthDelta(month, widget.lastDate) >= 0) {
        months.add(month);
      }
      if (_delegate.isSameMonth(month, widget.lastDate)) break;
      try {
        month = _delegate.addMonthsToMonthDate(month, 1);
      } on RangeError {
        break;
      }
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var row = 0; row < (months.length + 2) ~/ 3; row++)
          Row(
            children: [
              for (var column = 0; column < 3; column++)
                Expanded(
                  child: row * 3 + column >= months.length
                      ? const SizedBox.shrink()
                      : TextButton(
                          onPressed: () {
                            _setDisplayed(_clamp(months[row * 3 + column]));
                            _setView(GeneralCalendarView.month);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Text(
                              _delegate.formatMonthYear(
                                months[row * 3 + column],
                                localizations,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                ),
            ],
          ),
      ],
    );
  }

  Widget _buildDay(
    BuildContext context,
    DateTime date,
    MaterialLocalizations localizations,
    GeneralCalendarThemeData theme,
  ) {
    final attributes =
        widget.dateAttributes?.call(date) ?? CalendarDateAttributes();
    final disabled = !widget._isWithinBounds(date) ||
        attributes.isDisabled ||
        !(widget.selectableDayPredicate?.call(date) ?? true);
    final start = _delegate.isSameDay(date, _rangeStart);
    final end = _delegate.isSameDay(date, _rangeEnd);
    final inRange = _rangeStart != null &&
        _rangeEnd != null &&
        !date.isBefore(_rangeStart!) &&
        !date.isAfter(_rangeEnd!);
    final selected =
        start || end || _dates.any((other) => _delegate.isSameDay(date, other));
    final details = CalendarDayDetails(
      date: date,
      attributes: attributes,
      isToday: _delegate.isSameDay(date, widget.currentDate),
      isSelected: selected,
      isDisabled: disabled,
      isOutsideMonth: !_delegate.isSameMonth(date, _displayed),
      isWeekend: widget.weekendDays.contains(date.weekday),
      isRangeStart: start,
      isRangeEnd: end,
      isInRange: inRange,
    );
    final colors = Theme.of(context).colorScheme;
    final foreground = disabled
        ? colors.onSurface.withValues(alpha: 0.38)
        : selected
            ? theme.selectedDayForegroundColor ?? colors.onPrimary
            : attributes.foregroundColor ??
                (attributes.isHoliday
                    ? theme.holidayColor ?? colors.error
                    : details.isWeekend
                        ? theme.weekendColor ?? colors.onSurface
                        : colors.onSurface);
    final background = selected
        ? theme.selectedDayColor ?? colors.primary
        : attributes.backgroundColor ??
            (inRange
                ? theme.rangeColor ?? colors.primaryContainer
                : attributes.isVacation
                    ? theme.vacationColor ?? colors.tertiaryContainer
                    : null);
    final labels = [
      _delegate.formatFullDate(date, localizations),
      if (attributes.semanticLabel != null) attributes.semanticLabel!,
      if (attributes.isHoliday) widget.labels.holiday,
      if (attributes.isVacation) widget.labels.vacation,
      ...attributes.tags.map((tag) => tag.label),
    ].join(', ');
    Widget content = Semantics(
      key: ValueKey(
        'general-calendar-day-${date.year}-${date.month}-${date.day}',
      ),
      label: labels,
      button: true,
      selected: selected || inRange,
      enabled: !disabled && !widget.readOnly,
      onTap: disabled || widget.readOnly ? null : () => _select(date),
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: Ink(
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(12),
              border: details.isToday
                  ? Border.all(color: theme.todayColor ?? colors.primary)
                  : null,
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: disabled || widget.readOnly ? null : () => _select(date),
              child: Center(
                child: widget.dayBuilder?.call(context, details) ??
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          localizations.formatDecimal(date.day),
                          style: (theme.dayTextStyle ??
                                  Theme.of(context).textTheme.bodyMedium!)
                              .copyWith(color: foreground),
                        ),
                        if (attributes.tags.isNotEmpty)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              for (final tag in attributes.tags.take(3))
                                Container(
                                  width: 4,
                                  height: 4,
                                  margin: const EdgeInsets.all(1),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: tag.color ?? foreground,
                                  ),
                                ),
                            ],
                          ),
                      ],
                    ),
              ),
            ),
          ),
        ),
      ),
    );
    final tooltip = attributes.tooltip ??
        (attributes.tags.isEmpty
            ? null
            : attributes.tags.map((tag) => tag.label).join(', '));
    if (tooltip != null) content = Tooltip(message: tooltip, child: content);
    return content;
  }
}
